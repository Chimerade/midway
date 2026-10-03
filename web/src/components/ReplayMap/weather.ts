// Vent et nuages tirés des observations météo de la base : direction et force
// du vent (dérive des fumées et des nuages), nébulosité par zone (6-8/10 sur la
// Kidō Butai le matin du 4, 2-3/10 sur les Task Forces, front le 5).
import type { WeatherObs } from '../../types/replay';
import { vnoise, smoothstep } from './noise';
import type { Sky } from './sky';
import type { View } from './view';

export interface Wind { from: number; spd: number; ux: number; uy: number; cover: number; }

// Fond climatologique (alizé de secteur est, cumulus épars) : il reprend la main loin
// de toute observation, pour qu'un relevé n'étende pas sa nébulosité à tout l'océan.
const BACKGROUND: WeatherObs = { t: 0, lat: 0, lon: 0, wd: 110, ws: 8, cc: 0.3, vis: 30 };
const W_BG = 0.15, R_NM = 90, T_MIN = 900;
const unwrap = (lon: number) => (lon > 0 ? lon - 360 : lon);

/** Poids gaussiens en espace (90 nm) et en temps (15 h) ; le dernier poids est celui du fond. */
function weights(obs: WeatherObs[], t: number, lat: number, lon: number) {
  const w = obs.map((o) => {
    const dy = (o.lat - lat) * 60, dx = (unwrap(o.lon) - unwrap(lon)) * 60 * Math.cos(lat * Math.PI / 180);
    const dt = (o.t - t) / T_MIN;
    return Math.exp(-(dx * dx + dy * dy) / (R_NM * R_NM)) * Math.exp(-dt * dt);
  });
  return [...w, W_BG];
}

/** Vent et nébulosité interpolés autour des observations. ux, uy : sens de la dérive, est/nord. */
export function weatherAt(list: WeatherObs[] | undefined, t: number, lat: number, lon: number): Wind {
  const obs = [...(list ?? []), BACKGROUND];
  const w = weights(list ?? [], t, lat, lon);
  let u = 0, v = 0, c = 0, sw = 0, cw = 0;
  obs.forEach((o, i) => {
    const to = (o.wd + 180) * Math.PI / 180;
    u += w[i] * o.ws * Math.sin(to); v += w[i] * o.ws * Math.cos(to); sw += w[i];
    if (o.cc != null) { c += w[i] * o.cc; cw += w[i]; }
  });
  u /= sw; v /= sw;
  const spd = Math.hypot(u, v) || 1;
  return { from: ((Math.atan2(-u, -v) * 180 / Math.PI) + 360) % 360, spd, ux: u / spd, uy: v / spd, cover: cw ? c / cw : 0.3 };
}

// ---------------------------------------------------------------------------
// Couche nuageuse : champ fBm calculé en basse résolution dans le repère du monde
// (les nuages restent accrochés à la mer quand on zoome ou qu'on déplace la carte),
// seuillé par la nébulosité locale, puis agrandi avec lissage. Deux tampons : les
// nuages et leur ombre portée sur la mer.
// ---------------------------------------------------------------------------
const OCTAVES = [26, 13, 6.5, 3.2, 1.6, 0.8];   // longueurs d'onde (nm) : amas puis cumulus
const STEP = 5;                               // pas d'échantillonnage (px CSS)

export interface CloudFrame { cloud: HTMLCanvasElement; shade: HTMLCanvasElement; gw: number; gh: number; step: number; }

let cloudCv: HTMLCanvasElement | null = null, shadeCv: HTMLCanvasElement | null = null;
let cloudImg: ImageData | null = null, shadeImg: ImageData | null = null;
let lastKey = '';

export function renderClouds(view: View, T: number, sky: Sky, list: WeatherObs[] | undefined, centerWind: Wind): CloudFrame {
  const gw = Math.ceil(view.W / STEP) + 2, gh = Math.ceil(view.H / STEP) + 2;
  if (!cloudCv || !shadeCv || !cloudImg || !shadeImg || cloudCv.width !== gw || cloudCv.height !== gh) {
    cloudCv = document.createElement('canvas'); shadeCv = document.createElement('canvas');
    cloudCv.width = shadeCv.width = gw; cloudCv.height = shadeCv.height = gh;
    cloudImg = new ImageData(gw, gh); shadeImg = new ImageData(gw, gh);
    lastKey = '';
  }
  const frame = { cloud: cloudCv, shade: shadeCv, gw, gh, step: STEP };
  const key = `${T.toFixed(2)}|${view.panX.toFixed(3)}|${view.panY.toFixed(3)}|${view.k.toFixed(4)}|${gw}x${gh}|${sky.elev.toFixed(1)}`;
  if (key === lastKey) return frame;
  lastKey = key;

  const obs = [...(list ?? []), BACKGROUND];
  // nébulosité sur une grille grossière (1 point sur 4), interpolée ensuite
  const cg = 4, cwN = Math.ceil(gw / cg) + 1, chN = Math.ceil(gh / cg) + 1;
  const cov = new Float32Array(cwN * chN);
  for (let j = 0; j < chN; j++) for (let i = 0; i < cwN; i++) {
    const ll = view.toLatLon((i * cg - 1) * STEP, (j * cg - 1) * STEP);
    const w = weights(list ?? [], T, ll.lat, ll.lon);
    let c = 0, s = 0;
    obs.forEach((o, n) => { if (o.cc != null) { c += w[n] * o.cc; s += w[n]; } });
    cov[j * cwN + i] = s ? c / s : 0.3;
  }

  // dérive avec le vent (nm), les petites échelles un peu plus vite : les cumulus « bouillonnent »
  const hours = T / 60;
  const dx = centerWind.ux * centerWind.spd * hours, dy = centerWind.uy * centerWind.spd * hours;
  const amp = OCTAVES.map((lam) => smoothstep(1.6, 3.2, lam * view.k / STEP) / (lam > 30 ? 1.2 : 1));
  let ampSum = 0; OCTAVES.forEach((_, o) => { ampSum += amp[o] * Math.pow(0.55, o); });
  ampSum = ampSum || 1;
  const lit = sky.cloudLit, base = sky.cloudBase;
  // translucides, et plus encore quand on zoome : la caméra « passe sous » la couche
  const aMax = (0.46 + 0.14 * sky.light) * (1 - 0.45 * smoothstep(3, 12, view.scale)) * (0.72 + 0.28 * smoothstep(1.5, 4.5, view.scale));
  const cd = cloudImg.data, sd = shadeImg.data;

  for (let j = 0; j < gh; j++) {
    const sy = (j - 1) * STEP;
    for (let i = 0; i < gw; i++) {
      const sx = (i - 1) * STEP;
      const wx = view.toNmX(sx), wy = view.toNmY(sy);
      let n = 0;
      for (let o = 0; o < OCTAVES.length; o++) {
        if (amp[o] <= 0.001) continue;
        const lam = OCTAVES[o], drift = 1 + o * 0.08;
        n += amp[o] * Math.pow(0.55, o) * vnoise((wx - dx * drift) / lam + o * 17.3, (wy - dy * drift) / lam - o * 9.1);
      }
      n /= ampSum;
      const ci = Math.min(cwN - 1, (i / cg) | 0), cj = Math.min(chN - 1, (j / cg) | 0);
      const fx = i / cg - ci, fy = j / cg - cj;
      const c00 = cov[cj * cwN + ci], c10 = cov[cj * cwN + Math.min(cwN - 1, ci + 1)];
      const c01 = cov[Math.min(chN - 1, cj + 1) * cwN + ci], c11 = cov[Math.min(chN - 1, cj + 1) * cwN + Math.min(cwN - 1, ci + 1)];
      const cover = (c00 * (1 - fx) + c10 * fx) * (1 - fy) + (c01 * (1 - fx) + c11 * fx) * fy;
      const th = 0.71 - 0.37 * cover;                 // seuil calé pour que la fraction couverte ≈ nébulosité
      const a = smoothstep(th, th + 0.12, n);
      const core = smoothstep(th + 0.03, th + 0.3, n);
      const p = (j * gw + i) * 4;
      cd[p] = base[0] + (lit[0] - base[0]) * core;
      cd[p + 1] = base[1] + (lit[1] - base[1]) * core;
      cd[p + 2] = base[2] + (lit[2] - base[2]) * core;
      cd[p + 3] = a * aMax * 255;
      sd[p] = 2; sd[p + 1] = 8; sd[p + 2] = 16;
      sd[p + 3] = a * 0.34 * sky.light * 255;
    }
  }
  cloudCv.getContext('2d')!.putImageData(cloudImg, 0, 0);
  shadeCv.getContext('2d')!.putImageData(shadeImg, 0, 0);
  return frame;
}
