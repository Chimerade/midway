import type { ReplayData, Entity, Fire, Wreck, TrackPoint } from '../../types/replay';
import type { RenderState, Clickable, DrawResult, DrawFn } from './types';
import { raidPhaseKey, PHASE_LABEL } from './phase';
import { LAT0, LON0, RAD, unwrap, makeView, bearing, type View } from './view';
import { skyAt, type Sky } from './sky';
import { weatherAt, renderClouds, type Wind } from './weather';
import { drawOcean, drawAtoll } from './ocean';
import { drawCarrier, drawWarship, escortLen, drawPlane, planeKind, type PlaneKind, type ShipLook } from './sprites';
import { drawWake, drawSmoke, drawFire, drawFlak, drawTracers, drawStrikes, drawOilSlick, drawShotDown } from './fx';
import {
  HUD, MONO, CANVAS_STR, sideColor, hudBegin, label, drawGrid, drawRangeRings, drawRadar, drawRadarBlip, drawHalo,
  drawBrackets, drawSpotPing, drawWreckMark, drawCompass, drawDaylight,
} from './hud';
import { actionCenter } from './camera';

export { LAT0, LON0, RAD, unwrap };
export { distNm } from './view';

// Taille logique (pixels CSS) de chaque canvas, fixée par draw(). Toute la mise en
// page se calcule dans ce repère; le tampon interne est agrandi de devicePixelRatio
// pour rester net sur écran Retina.
const logicalSize = new WeakMap<HTMLCanvasElement, { w: number; h: number }>();
function viewSize(cv: HTMLCanvasElement) { return logicalSize.get(cv) ?? { w: cv.width, h: cv.height }; }

export function pxnm(cv: HTMLCanvasElement) { const { w, h } = viewSize(cv); return Math.min(w, h) / 900; }

export function proj(lat: number, lon: number, cv: HTMLCanvasElement, st: RenderState): [number, number] {
  const x = (unwrap(lon) - LON0) * 60 * Math.cos(LAT0 * RAD), y = (lat - LAT0) * 60;
  const { w, h } = viewSize(cv);
  return [w / 2 + (x + st.panX) * st.scale * pxnm(cv), h / 2 - (y + st.panY) * st.scale * pxnm(cv)];
}

export function fmt(t: number) {
  t = Math.floor(t);
  const d = 3 + Math.floor(t / 1440), mins = ((t % 1440) + 1440) % 1440, h = Math.floor(mins / 60), m = mins % 60;
  return `${d} juin 1942 — ${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')} (GMT−12)`;
}

export function cardinal(b: number) { return ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'][Math.round(((b % 360) + 360) % 360 / 45) % 8]; }

export const routeTo = bearing;

export interface TrackState {
  lat: number; lon: number; err: number; route: number | null; stale?: boolean;
  spd: number;           // vitesse dans l'eau (consignée si connue, sinon déduite du segment)
}

export function interp(track: TrackPoint[], t: number): TrackState | null {
  if (t < track[0].t) return null;
  for (let i = 0; i < track.length - 1; i++) {
    const a = track[i], b = track[i + 1];
    if (t >= a.t && t <= b.t) {
      const f = (t - a.t) / Math.max(1, b.t - a.t);
      const dlat = (b.lat - a.lat) * 60, dlon = (unwrap(b.lon) - unwrap(a.lon)) * 60 * Math.cos(LAT0 * RAD);
      const seg = Math.hypot(dlat, dlon) / Math.max(1 / 60, (b.t - a.t) / 60);
      return {
        lat: a.lat + f * (b.lat - a.lat), lon: unwrap(a.lon) + f * (unwrap(b.lon) - unwrap(a.lon)),
        err: a.err + f * (b.err - a.err), route: bearing(a, b), spd: a.spd ?? seg,
      };
    }
  }
  const last = track[track.length - 1];
  if (t - last.t < 360) {
    const prev = track.length > 1 ? track[track.length - 2] : null;
    // piste périmée: l'incertitude CROÎT avec le temps écoulé (~5 nm/h, plafond 90)
    const grown = Math.min(90, last.err + (t - last.t) / 60 * 5);
    return { lat: last.lat, lon: unwrap(last.lon), err: grown, stale: true, route: prev ? bearing(prev, last) : null, spd: 0 };
  }
  return null;
}

// --- index des données (calculé une fois par jeu de données) --------------------
interface Index {
  entById: Record<string, Entity>;
  formationOf: Map<string, string>;        // navire -> formation suivie qui le contient
  wreckOf: Map<string, Wreck>;
  firesOf: Map<string, Fire[]>;
  kindOf: Map<string, PlaneKind>;          // mission -> silhouette dominante
}
const indexes = new WeakMap<ReplayData, Index>();
function indexOf(D: ReplayData): Index {
  let ix = indexes.get(D);
  if (!ix) {
    const entById: Record<string, Entity> = {};
    const formationOf = new Map<string, string>();
    D.entities.forEach((e) => {
      entById[e.id] = e;
      (e.ships ?? []).forEach((m) => formationOf.set(m.id, e.id));
    });
    const wreckOf = new Map(D.wrecks.map((w) => [w.ent, w] as const));
    const firesOf = new Map<string, Fire[]>();
    D.fires.forEach((f) => firesOf.set(f.ent, [...(firesOf.get(f.ent) ?? []), f]));
    const kindOf = new Map(Object.entries(D.missions).map(([mid, m]) => [mid, planeKind(m.aircraft[0]?.type)] as const));
    ix = { entById, formationOf, wreckOf, firesOf, kindOf };
    indexes.set(D, ix);
  }
  return ix;
}

/** Position d'une entité à l'instant t : piste propre, épave, ou à défaut sa formation. */
export function makePosOf(D: ReplayData) {
  const ix = indexOf(D);
  const posOf = (ent: string, t: number, depth = 0): { lat: number; lon: number } | null => {
    if (ent === 'SH-MIDWAY') return { lat: 28.21, lon: -177.37 };
    const e = ix.entById[ent];
    const p = e ? interp(e.track, t) : null;
    if (p) return p;
    const w = ix.wreckOf.get(ent);
    if (w && t >= w.t) return { lat: w.lat, lon: w.lon };
    const f = ix.formationOf.get(ent);
    return f && depth < 3 ? posOf(f, t, depth + 1) : null;
  };
  return posOf;
}

export function cameraTarget(D: ReplayData, T: number) { return actionCenter(D, T, makePosOf(D)); }

const isSunk = (ix: Index, id: string, t: number) => { const w = ix.wreckOf.get(id); return !!(w && t >= w.t); };
const burningAt = (ix: Index, id: string, t: number) => (ix.firesOf.get(id) ?? []).some((f) => t >= f.t0 && t < f.t1 && f.burn !== false);
const disabledAt = (ix: Index, id: string, t: number) => (ix.firesOf.get(id) ?? []).some((f) => t >= f.t0 && t < f.t1 && f.burn === false);
const clamp = (v: number, a: number, b: number) => Math.max(a, Math.min(b, v));

interface ShipDraw { x: number; y: number; hdg: number; len: number; type: string; id: string; side: 'IJN' | 'USN'; burning: boolean; spd: number; carrier: boolean; }

/** Bâtiments d'une entité à l'instant T, en coordonnées écran (formation = porte-avions au centre, écran en cercle). */
function shipsOf(e: Entity, p: TrackState, x: number, y: number, Lc: number, view: View, ix: Index, T: number): { ships: ShipDraw[]; foot: number } {
  const hdg = (p.route ?? 0) * RAD;
  const spd = p.stale ? 0 : p.spd;
  if (e.kind !== 'formation') {
    const burning = burningAt(ix, e.id, T), stopped = burning || disabledAt(ix, e.id, T);
    return { ships: [{ x, y, hdg, len: Lc, type: e.type ?? 'CV', id: e.id, side: e.side, burning, spd: stopped ? 0 : spd, carrier: true }], foot: Lc * 0.55 };
  }
  const members = (e.ships ?? []).filter((m) => {
    if (isSunk(ix, m.id, T)) return false;
    const own = ix.entById[m.id];
    return !(own && T >= own.track[0].t);                // détaché : dessiné avec sa piste propre
  });
  const cvs = members.filter((m) => m.type === 'CV' || m.type === 'CVL');
  const esc = members.filter((m) => !(m.type === 'CV' || m.type === 'CVL')).slice(0, 14);
  const R = Math.max(Lc * (cvs.length ? 1.5 : 0.9), Math.min(2.6 * view.k, 3.4 * Lc));
  const layout: Record<number, [number, number][]> = {
    1: [[0, 0]], 2: [[-0.42, 0], [0.42, 0]], 3: [[-0.42, 0.3], [0.42, 0.3], [0, -0.45]],
    4: [[-0.42, -0.36], [0.42, -0.36], [-0.42, 0.36], [0.42, 0.36]],
  };
  const c = Math.cos(hdg), s = Math.sin(hdg);
  const at = (lx: number, ly: number) => [x + lx * c - ly * s, y + lx * s + ly * c];   // repère local -> écran
  const out: ShipDraw[] = [];
  (layout[cvs.length] ?? []).forEach(([lx, ly], i) => {
    const [sx, sy] = at(lx * Lc, ly * Lc);
    out.push({ x: sx, y: sy, hdg, len: Lc, type: cvs[i].type, id: cvs[i].id, side: e.side, burning: false, spd, carrier: true });
  });
  esc.forEach((m, i) => {
    const a = -Math.PI / 2 + (i + 0.5) * 2 * Math.PI / esc.length;
    const [sx, sy] = at(Math.cos(a) * R, Math.sin(a) * R);
    out.push({ x: sx, y: sy, hdg, len: Lc * escortLen(m.type) * 0.85, type: m.type, id: m.id, side: e.side, burning: false, spd, carrier: false });
  });
  return { ships: out, foot: esc.length ? R + Lc * 0.3 : Lc * 0.8 };
}

function shipLook(sd: ShipDraw, sky: Sky): ShipLook { return { side: sd.side, burning: sd.burning ? 1 : 0, light: sky.light }; }

const RADAR = [{ ent: 'TF-16', nm: 75 }, { ent: 'TF-17', nm: 75 }, { ent: 'SH-MIDWAY', nm: 100 }];

export const draw: DrawFn = (ctx, cv, data, st): DrawResult => {
  const D = data, ix = indexOf(D), posOf = makePosOf(D);
  const clickables: Clickable[] = [];
  // tampon interne en pixels physiques (net sur Retina), dessin en pixels CSS;
  // on ne réalloue le tampon que si la taille change (pas à chaque image)
  const parent = cv.parentElement as HTMLElement, W = parent.clientWidth, H = parent.clientHeight;
  const dpr = window.devicePixelRatio || 1, bw = Math.round(W * dpr), bh = Math.round(H * dpr);
  if (cv.width !== bw || cv.height !== bh) { cv.width = bw; cv.height = bh; }
  logicalSize.set(cv, { w: W, h: H });
  ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
  ctx.globalAlpha = 1; ctx.globalCompositeOperation = 'source-over';

  const view = makeView(W, H, st.scale, st.panX, st.panY);
  const mid = view.toLatLon(W / 2, H / 2);
  const sky = skyAt(st.T, mid.lat, mid.lon);
  const wind: Wind = weatherAt(D.weather, st.T, mid.lat, mid.lon);
  const wux = wind.ux, wuy = -wind.uy;                      // dérive en repère écran
  const tReal = performance.now() / 1000, tFx = st.reduced ? tReal * 0.3 : tReal;
  const S = CANVAS_STR[st.lang];
  const Lc = clamp(13 + 5 * Math.log2(1 + st.scale), 14, 40);
  const night = 1 - sky.light;
  hudBegin();

  // ---------------------------------------------------------------- monde
  drawOcean(ctx, view, sky, wind, tReal, st.T, !!st.reduced);
  drawAtoll(ctx, view, sky);

  // nappes de mazout des épaves
  D.wrecks.forEach((w) => {
    if (st.T >= w.t) drawOilSlick(ctx, view.sx(w.lon), view.sy(w.lat), wux, wuy, st.T - w.t, view.k, sky.light);
  });

  const clouds = st.showClouds !== false ? renderClouds(view, st.T, sky, D.weather, wind) : null;
  if (clouds && sky.light > 0.05) {      // ombres des nuages, décalées à l'opposé du soleil
    const off = 6 + 10 * sky.shadow, az = sky.az * RAD;
    ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(clouds.shade, -clouds.step - Math.sin(az) * off, -clouds.step + Math.cos(az) * off, clouds.gw * clouds.step, clouds.gh * clouds.step);
  }

  // navires : sillages puis coques
  const drawn: { e: Entity; p: TrackState; x: number; y: number; foot: number; burning: boolean; ships: ShipDraw[] }[] = [];
  D.entities.forEach((e) => {
    if (isSunk(ix, e.id, st.T)) return;
    const p = interp(e.track, st.T); if (!p) return;
    const x = view.sx(p.lon), y = view.sy(p.lat);
    const { ships, foot } = shipsOf(e, p, x, y, Lc, view, ix, st.T);
    drawn.push({ e, p, x, y, foot, burning: burningAt(ix, e.id, st.T), ships });
  });
  const sunX = Math.sin(sky.az * RAD), sunY = -Math.cos(sky.az * RAD);
  drawn.forEach(({ ships }) => ships.forEach((sd) => {
    ctx.save(); ctx.translate(sd.x, sd.y); ctx.rotate(sd.hdg);
    drawWake(ctx, sd.len, sd.spd, sky.light * (sd.carrier ? 1 : 0.55), tFx);
    ctx.restore();
    if (sky.light > 0.1) {             // ombre portée
      ctx.save(); ctx.translate(sd.x - sunX * sd.len * 0.12 * (0.4 + sky.shadow), sd.y - sunY * sd.len * 0.12 * (0.4 + sky.shadow)); ctx.rotate(sd.hdg);
      ctx.fillStyle = `rgba(0,8,18,${0.3 * sky.light})`;
      ctx.beginPath(); ctx.ellipse(0, 0, sd.len * 0.09, sd.len * 0.5, 0, 0, Math.PI * 2); ctx.fill();
      ctx.restore();
    }
  }));
  drawn.forEach(({ ships }) => ships.forEach((sd) => {
    ctx.save(); ctx.translate(sd.x, sd.y); ctx.rotate(sd.hdg);
    if (sd.carrier && (sd.type === 'CV' || sd.type === 'CVL')) drawCarrier(ctx, sd.len, sd.id, shipLook(sd, sky));
    else drawWarship(ctx, sd.len, sd.type, shipLook(sd, sky));
    ctx.restore();
  }));

  // raids : position, silhouettes, ombres (avions bas sous les nuages, hauts au-dessus)
  interface Flight { r: (typeof D.raids)[number]; x: number; y: number; ang: number; n: number; shown: number; pack: number; launching: boolean; after: boolean; kind: PlaneKind; ps: number; high: boolean; }
  const flights: Flight[] = [];
  if (st.showRaid) D.raids.forEach((r) => {
    const launching = r.tl != null && st.T >= r.tl && st.T < r.t0;
    if (!(launching || (st.T >= r.t0 && st.T <= r.t1))) return;
    const f = launching ? 0 : (st.T - r.t0) / (r.t1 - r.t0);
    const lat = r.a[0] + f * (r.b[0] - r.a[0]), lon = unwrap(r.a[1]) + f * (unwrap(r.b[1]) - unwrap(r.a[1]));
    const x = view.sx(lon), y = view.sy(lat);
    const ang = Math.atan2(view.sy(r.b[0]) - view.sy(r.a[0]), view.sx(r.b[1]) - view.sx(r.a[1]));
    const after = r.ta != null && st.T >= r.ta;
    let n = after ? Math.max(0, r.n0 - r.lost) : r.n0;
    if (launching) n = Math.max(1, Math.round(r.n0 * (st.T - (r.tl as number)) / Math.max(1, r.t0 - (r.tl as number))));
    const par = r.par || 1;
    if (par > 1) n = Math.max(1, Math.round(n / par));    // éventail: l'effectif se répartit entre les lignes
    const pack = r.n0 > 60 ? 2 : 1;
    const kind = ix.kindOf.get(r.mid) ?? 'single';
    const ps = clamp(7 + 1.9 * Math.log2(1 + st.scale), 7.5, 14) * (kind === 'four' ? 1.8 : kind === 'boat' ? 1.6 : kind === 'twin' ? 1.45 : 1);
    flights.push({ r, x, y, ang, n, shown: Math.ceil(n / pack), pack, launching, after, kind, ps, high: (r.alt ?? 3000) >= 1000 });
  });
  const detailed = st.scale >= 2.2;
  const planeAt = (fl: Flight, i: number): [number, number] => {
    if (!detailed) { const v = [[0, 0], [-1, 1], [1, 1]][i] ?? [0, 0]; return [v[0] * fl.ps * 0.9, v[1] * fl.ps * 0.8]; }
    const row = Math.floor((-1 + Math.sqrt(1 + 8 * i)) / 2), kk = i - row * (row + 1) / 2, sp = fl.ps * 1.3;
    return [(kk - row / 2) * sp, row * sp * 0.85];
  };
  const eachPlane = (fl: Flight, fn: (px: number, py: number) => void) => {
    const c = Math.cos(fl.ang + Math.PI / 2), s = Math.sin(fl.ang + Math.PI / 2);
    const count = detailed ? fl.shown : Math.min(3, fl.shown);
    for (let i = 0; i < count; i++) { const [lx, ly] = planeAt(fl, i); fn(fl.x + lx * c - ly * s, fl.y + lx * s + ly * c); }
  };
  const planeColor = (side: string) => {
    const l = 0.5 + 0.5 * sky.light;
    return side === 'IJN' ? `rgb(${212 * l | 0},${204 * l | 0},${180 * l | 0})` : `rgb(${150 * l | 0},${168 * l | 0},${186 * l | 0})`;
  };
  const drawFlights = (high: boolean) => flights.filter((fl) => fl.high === high).forEach((fl) => {
    if (sky.light > 0.1) {             // ombres sur la mer : décalage ∝ altitude
      const off = clamp((fl.r.alt ?? 3000) / 1000 * 2.4, 2, 15) * (0.5 + sky.shadow);
      const shadowCol = `rgba(0,8,18,${0.22 * sky.light})`;
      eachPlane(fl, (px, py) => {
        ctx.save(); ctx.translate(px - sunX * off, py - sunY * off); ctx.rotate(fl.ang + Math.PI / 2);
        drawPlane(ctx, fl.ps, fl.kind, shadowCol); ctx.restore();
      });
    }
    if ((fl.r.alt ?? 0) >= 4000 && !fl.launching) {     // traînées de condensation en altitude
      ctx.strokeStyle = `rgba(240,246,252,${0.16 + 0.12 * sky.light})`; ctx.lineWidth = Math.max(0.8, fl.ps * 0.12); ctx.lineCap = 'round';
      ctx.beginPath();
      eachPlane(fl, (px, py) => { ctx.moveTo(px, py); ctx.lineTo(px - Math.cos(fl.ang) * fl.ps * 3.2, py - Math.sin(fl.ang) * fl.ps * 3.2); });
      ctx.stroke(); ctx.lineCap = 'butt';
    }
    const col = planeColor(fl.r.side);
    eachPlane(fl, (px, py) => {
      ctx.save(); ctx.translate(px, py); ctx.rotate(fl.ang + Math.PI / 2);
      drawPlane(ctx, fl.ps, fl.kind, col, true); ctx.restore();
    });
    // appareils abattus : spirale de fumée pendant 20 min après l'attaque (6 au plus par groupe)
    if (fl.after && fl.r.lost > 0 && st.T <= (fl.r.ta as number) + 20 && detailed) {
      const age = st.T - (fl.r.ta as number), lostShown = Math.min(6, Math.ceil(fl.r.lost / fl.pack));
      for (let i = 0; i < lostShown; i++) {
        const [lx, ly] = planeAt(fl, fl.shown + i);
        const c = Math.cos(fl.ang + Math.PI / 2), s = Math.sin(fl.ang + Math.PI / 2);
        drawShotDown(ctx, fl.x + lx * c - ly * s, fl.y + lx * s + ly * c, age, i * 7.3 + fl.r.seq, fl.ps * 0.6);
      }
    }
  });
  drawFlights(false);

  // fumées des navires en feu (poussées par le vent observé)
  const plume = clamp(9 * view.k, 40, 260);
  drawn.forEach(({ e, ships }) => ships.forEach((sd, i) => {
    const burning = e.kind !== 'formation' && burningAt(ix, e.id, st.T);
    if (burning) drawSmoke(ctx, sd.x, sd.y, wux, wuy, plume, 1, i + e.id.length * 3.1, tFx, sky.light);
  }));

  if (clouds) {
    ctx.imageSmoothingEnabled = true; ctx.imageSmoothingQuality = 'high';
    ctx.drawImage(clouds.cloud, -clouds.step, -clouds.step, clouds.gw * clouds.step, clouds.gh * clouds.step);
  }
  drawFlights(true);

  // lumières : incendies et combats (additif, la nuit ils éclairent la mer)
  drawn.forEach(({ e, ships }) => {
    if (e.kind === 'formation' || !burningAt(ix, e.id, st.T)) return;
    ctx.globalCompositeOperation = 'lighter';
    ships.forEach((sd, i) => drawFire(ctx, sd.x, sd.y, sd.len * 0.5, i + e.id.length, tFx, night));
    ctx.globalCompositeOperation = 'source-over';
  });
  const R = clamp(3.5 * view.k, 24, 80);
  const engaged: { x: number; y: number; k: string }[] = [];
  D.combats.forEach((cb, i) => {
    if (!(st.T >= cb.t0 && st.T <= cb.t1)) return;
    const p = posOf(cb.ent, st.T); if (!p) return;
    const x = view.sx(p.lon), y = view.sy(p.lat), seed = i * 13.7 + 1;
    drawFlak(ctx, x, y, R, seed, tFx);
    ctx.globalCompositeOperation = 'lighter';
    drawTracers(ctx, x, y, R, seed, tFx);
    ctx.globalCompositeOperation = 'source-over';
    if (cb.k === 'hit' || cb.k === 'collision') drawStrikes(ctx, x, y, R, true, seed, tFx);
    else drawStrikes(ctx, x, y, R, false, seed, tFx);
    // plusieurs combats au même endroit : une seule visée, l'issue la plus grave l'emporte
    const k = cb.k ?? 'attack', rank = (s: string) => (s === 'hit' ? 2 : s === 'collision' ? 1 : 0);
    const near = engaged.find((g) => Math.hypot(g.x - x, g.y - y) < R * 0.6);
    if (!near) engaged.push({ x, y, k });
    else if (rank(k) > rank(near.k)) near.k = k;
  });

  // ---------------------------------------------------------------- couche tactique
  drawGrid(ctx, view);
  drawRangeRings(ctx, view);
  const radarSites = RADAR.map((r) => ({ ...r, p: posOf(r.ent, st.T) })).filter((r) => r.p && !(r.ent !== 'SH-MIDWAY' && isSunk(ix, r.ent, st.T)));
  radarSites.forEach((r) => drawRadar(ctx, view.sx(r.p!.lon), view.sy(r.p!.lat), r.nm * view.k, tReal, !!st.reduced));
  const mx = view.sx(LON0), my = view.sy(LAT0);
  label(ctx, 'MIDWAY', mx + Math.max(8, 2.6 * view.k), my + 4, { color: HUD.amber });

  // épaves
  D.wrecks.forEach((w) => {
    if (st.T < w.t) return;
    const x = view.sx(w.lon), y = view.sy(w.lat);
    drawWreckMark(ctx, x, y);
    label(ctx, `${w.name} — ${S.sunk} ${w.h.split(' ')[2]}`, x + 9, y + 4, { font: `10px Verdana, sans-serif`, color: HUD.text2 });
  });

  // pistes, halos, étiquettes
  D.entities.forEach((e) => {
    const c = sideColor(e.side);
    if (st.showTrail) {
      ctx.strokeStyle = c; ctx.globalAlpha = 0.4; ctx.lineWidth = 1.2; ctx.setLineDash([3, 4]); ctx.beginPath();
      let started = false;
      for (const pt of e.track) {
        if (pt.t > st.T) break;
        const x = view.sx(pt.lon), y = view.sy(pt.lat);
        if (started) ctx.lineTo(x, y); else ctx.moveTo(x, y);
        started = true;
      }
      const cur = interp(e.track, st.T);
      if (cur && started) ctx.lineTo(view.sx(cur.lon), view.sy(cur.lat));
      ctx.stroke(); ctx.setLineDash([]); ctx.globalAlpha = 1;
    }
    e.track.forEach((pt, pi) => {
      if (pt.t > st.T) return;
      const wx = view.sx(pt.lon), wy = view.sy(pt.lat);
      ctx.fillStyle = pt.cause ? c : 'rgba(200,210,220,0.6)';
      ctx.save(); ctx.translate(wx, wy); ctx.rotate(Math.PI / 4); ctx.fillRect(-2.5, -2.5, 5, 5); ctx.restore();
      clickables.push({ x: wx, y: wy, ent: e.label, pt, trk: e.track, idx: pi });
    });
  });
  drawn.forEach(({ e, p, x, y, foot, burning }) => {
    if (st.showHalo) drawHalo(ctx, x, y, p.err * view.k, e.side, p.err, !!p.stale, st.scale >= 1.8, S.stale, st.reduced ? 0 : tReal);
    if (p.stale) { ctx.strokeStyle = sideColor(e.side); ctx.lineWidth = 1; ctx.beginPath(); ctx.arc(x, y, foot + 4, 0, Math.PI * 2); ctx.stroke(); }
    const state = burning ? ` · ${S.onFire}` : disabledAt(ix, e.id, st.T) ? ` · ${S.disabled}` : '';
    const ly = label(ctx, e.label.toUpperCase() + state, x + foot + 8, y + 1, { color: sideColor(e.side) });
    if (e.sub && st.scale >= 1.1) label(ctx, e.sub, x + foot + 8, ly + 12, { font: `10px Verdana, sans-serif`, color: HUD.text2, optional: true });
  });

  // combats : coins de visée
  engaged.forEach(({ x, y, k }) => {
    drawBrackets(ctx, x, y, R * 0.55, HUD.combat, tFx);
    label(ctx, k === 'hit' ? S.hit : k === 'collision' ? S.collision : S.attack, x, y - R * 0.55 - 8,
      { font: `bold 10px ${MONO}`, color: HUD.combat, align: 'center' });
  });

  // repérages : qui voit qui
  D.spots.forEach((sp) => {
    if (!(st.T >= sp.t - 2 && st.T <= sp.t + 12)) return;
    const p = posOf(sp.ent, st.T); if (!p) return;
    const x = view.sx(p.lon), y = view.sy(p.lat);
    drawSpotPing(ctx, x, y, tFx);
    if (st.scale >= 1.3) label(ctx, `${S.spotted} : ${sp.s}…`, x + 14, y - 22, { font: `10px Verdana, sans-serif`, color: HUD.amber, optional: true });
  });

  // raids : traits de route, étiquettes, détection radar, clics
  const labelled = new Set<string>();     // un éventail (lignes parallèles) n'a qu'une étiquette
  flights.forEach((fl) => {
    const r = fl.r, c = sideColor(r.side);
    const xa = view.sx(r.a[1]), ya = view.sy(r.a[0]);
    ctx.strokeStyle = c; ctx.globalAlpha = 0.35; ctx.setLineDash([2, 4]); ctx.lineWidth = 1;
    ctx.beginPath(); ctx.moveTo(xa, ya); ctx.lineTo(fl.x, fl.y); ctx.stroke(); ctx.setLineDash([]); ctx.globalAlpha = 1;
    clickables.push({ x: fl.x, y: fl.y, ent: r.mid, pt: null, trk: [], idx: -1, mid: r.mid });
    if (r.side === 'IJN' && radarSites.some((s) => s.p && Math.hypot(view.sx(s.p.lon) - fl.x, view.sy(s.p.lat) - fl.y) < s.nm * view.k))
      drawRadarBlip(ctx, fl.x, fl.y, tReal);
    const par = r.par || 1;
    const onScreen = fl.x > 0 && fl.x < W && fl.y > 0 && fl.y < H;
    if (onScreen && st.scale >= 1.3 && r.n0 > 0 && !(par > 1 && labelled.has(r.mid))) {
      const count = `${par > 1 ? '≈' : ''}${fl.n}${fl.pack > 1 ? ` (${S.pack})` : ''} ${S.ac}${par > 1 ? S.perLine : ''}${fl.launching ? ` — ${S.takeoff}` : ''}`;
      const ly = label(ctx, `${r.mid.replace(/MS-060[346]-/, '')} · ${count}`, fl.x + 12, fl.y - 6, { font: `bold 10px Verdana, sans-serif`, color: c, optional: true });
      if (!Number.isNaN(ly)) {
        labelled.add(r.mid);
        label(ctx, PHASE_LABEL[st.lang][raidPhaseKey(r.ta, st.T)], fl.x + 12, ly + 12, { font: `10px ${MONO}`, color: HUD.text2, optional: true });
      }
    }
  });

  // monde perçu : positions rapportées
  if (st.showPercu) D.contacts.forEach((c) => {
    if (!(st.T >= c.t && st.T <= c.t + 180)) return;
    const x = view.sx(c.lon), y = view.sy(c.lat);
    ctx.strokeStyle = HUD.amber; ctx.lineWidth = 1.2; ctx.setLineDash([3, 3]);
    ctx.beginPath(); ctx.arc(x, y, 12, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
    label(ctx, `${S.reported} : ${c.s.slice(0, 40)}…`, x + 16, y + 3, { font: `10px Verdana, sans-serif`, color: HUD.amber });
  });

  // waypoint sélectionné: surligner ses segments entrant/sortant
  if (st.selWp) {
    const selWp = st.selWp;
    const sx = view.sx(selWp.pt.lon), sy = view.sy(selWp.pt.lat);
    ctx.strokeStyle = HUD.combat; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(sx, sy, 9, 0, Math.PI * 2); ctx.stroke();
    if (selWp.idx > 0) { // segment entrant (fin, pointillé)
      const a = selWp.trk[selWp.idx - 1];
      ctx.setLineDash([4, 4]); ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(view.sx(a.lon), view.sy(a.lat)); ctx.lineTo(sx, sy); ctx.stroke(); ctx.setLineDash([]);
    }
    if (selWp.idx < selWp.trk.length - 1) { // segment sortant (épais, s'arrête à la flèche)
      const b = selWp.trk[selWp.idx + 1], bx2 = view.sx(b.lon), by2 = view.sy(b.lat);
      const ang = Math.atan2(by2 - sy, bx2 - sx), mxp = (sx + bx2) / 2, myp = (sy + by2) / 2;
      ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(mxp, myp); ctx.stroke();
      ctx.fillStyle = HUD.combat;
      ctx.save(); ctx.translate(mxp, myp); ctx.rotate(ang);
      ctx.beginPath(); ctx.moveTo(8, 0); ctx.lineTo(-5, -5); ctx.lineTo(-5, 5); ctx.closePath(); ctx.fill(); ctx.restore();
    }
    ctx.lineWidth = 1;
  }

  drawCompass(ctx, W, wind, st.lang);
  drawDaylight(ctx, sky, st.lang);
  return { clickables };
};
