// Mer : couleur selon l'heure, houle et clapot texturés, reflet du soleil,
// atoll de Midway. Les textures sont accrochées au repère du monde ; leur
// échelle suit le zoom par fondu entre octaves, donc la mer reste détaillée
// à tous les niveaux de zoom sans motif répétitif visible.
import { vnoise } from './noise';
import { rgb, type Sky } from './sky';
import type { View } from './view';
import type { Wind } from './weather';

function makeTexture(size: number, sample: (u: number, v: number) => number): HTMLCanvasElement {
  const cv = document.createElement('canvas');
  cv.width = cv.height = size;
  const img = new ImageData(size, size), d = img.data;
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const g = Math.max(0, Math.min(255, sample(x / size, y / size) * 255));
    const p = (y * size + x) * 4;
    d[p] = d[p + 1] = d[p + 2] = g; d[p + 3] = 255;
  }
  cv.getContext('2d')!.putImageData(img, 0, 0);
  return cv;
}

// Les textures sont toujours AGRANDIES à l'écran (échelle 1 à 2) et leurs cellules font
// au moins 10 px : sans mipmaps, une texture réduite crée du moiré (fausses stries de pluie).
let swell: HTMLCanvasElement | null = null, chop: HTMLCanvasElement | null = null;
function textures() {
  if (!swell) swell = makeTexture(256, (u, v) =>    // longue houle douce
    0.5 + 0.6 * (vnoise(u * 5, v * 5, 5) - 0.5) + 0.3 * (vnoise(u * 10 + 3, v * 10, 10) - 0.5));
  if (!chop) chop = makeTexture(128, (u, v) => {    // clapot : crêtes à peine allongées en travers du vent
    const a = vnoise(u * 6, v * 9, 6, 9), b = vnoise(u * 12 + 5, v * 12, 12, 12);
    return 0.5 + 0.6 * (a - 0.5) + 0.35 * (b - 0.5);
  });
  return { swell, chop };
}

const patterns = new WeakMap<HTMLCanvasElement, CanvasPattern>();
function pattern(ctx: CanvasRenderingContext2D, tex: HTMLCanvasElement) {
  let p = patterns.get(tex);
  if (!p) { p = ctx.createPattern(tex, 'repeat')!; patterns.set(tex, p); }
  return p;
}

/** Remplit l'écran d'une texture accrochée au monde, taille apparente ≈ targetPx (fondu entre 2 octaves). */
function tiled(ctx: CanvasRenderingContext2D, view: View, tex: HTMLCanvasElement, targetPx: number,
               alpha: number, driftNm: [number, number], rotDeg: number) {
  const u = Math.log2(targetPx / view.k), lo = Math.floor(u), frac = u - lo;
  const ox = view.W / 2 + (view.panX + driftNm[0]) * view.k, oy = view.H / 2 - (view.panY + driftNm[1]) * view.k;
  const pat = pattern(ctx, tex);
  [[lo, 1 - frac], [lo + 1, frac]].forEach(([oct, w]) => {
    if (w < 0.02) return;
    const s = Math.pow(2, oct) * view.k / tex.width;
    pat.setTransform(new DOMMatrix().translateSelf(ox, oy).rotateSelf(rotDeg).scaleSelf(s, s));
    ctx.globalAlpha = alpha * w;
    ctx.fillStyle = pat;
    ctx.fillRect(0, 0, view.W, view.H);
  });
  ctx.globalAlpha = 1;
}

export function drawOcean(ctx: CanvasRenderingContext2D, view: View, sky: Sky, wind: Wind, tReal: number, T: number, reduced: boolean) {
  const { W, H } = view;
  // fond : plus clair au centre, assombri sur les bords
  const g = ctx.createRadialGradient(W * 0.5, H * 0.45, 0, W * 0.5, H * 0.5, Math.hypot(W, H) * 0.62);
  g.addColorStop(0, rgb(sky.shallow)); g.addColorStop(1, rgb(sky.deep));
  ctx.fillStyle = g; ctx.fillRect(0, 0, W, H);

  // houle et clapot : dérive lente avec le vent (temps simulé) + ondulation (temps réel)
  const { swell, chop } = textures();
  const live = reduced ? 0 : tReal;
  const windDeg = Math.atan2(wind.uy, wind.ux) * -180 / Math.PI;   // écran : y vers le bas
  const hrs = T / 60;
  ctx.globalCompositeOperation = 'soft-light';
  tiled(ctx, view, swell, 512, 0.5 * (0.35 + 0.65 * sky.light),
        [wind.ux * 3 * hrs + live * 0.004, wind.uy * 3 * hrs], windDeg + 25);
  tiled(ctx, view, chop, 256, 0.26 * (0.3 + 0.7 * sky.light),
        [wind.ux * wind.spd * hrs * 0.4 + live * 0.012, wind.uy * wind.spd * hrs * 0.4 + live * 0.006], windDeg + 90);
  ctx.globalCompositeOperation = 'source-over';

  // reflet du soleil : vers le soleil quand il est bas, au centre quand il est haut
  if (sky.light > 0.05 && sky.elev > -2) {
    const cot = 1 / Math.tan(Math.max(4, sky.elev) * Math.PI / 180);
    const az = sky.az * Math.PI / 180;
    const off = Math.min(1.4, cot * 0.18) * Math.max(W, H);
    const gx = W / 2 + Math.sin(az) * off, gy = H / 2 - Math.cos(az) * off;
    const r = Math.max(W, H) * (0.55 + 0.25 * sky.warm);
    const gl = ctx.createRadialGradient(gx, gy, 0, gx, gy, r);
    const hot = sky.warm > 0.2 ? [255, 196, 140] : [235, 245, 255];
    gl.addColorStop(0, `rgba(${hot[0]},${hot[1]},${hot[2]},${0.16 * sky.light + 0.1 * sky.warm})`);
    gl.addColorStop(1, `rgba(${hot[0]},${hot[1]},${hot[2]},0)`);
    ctx.globalCompositeOperation = 'screen';
    ctx.fillStyle = gl; ctx.fillRect(0, 0, W, H);
    ctx.globalCompositeOperation = 'source-over';
  }
}

/** Atoll de Midway : lagon, récif et les deux îles (Sand à l'ouest, Eastern à l'est). */
export function drawAtoll(ctx: CanvasRenderingContext2D, view: View, sky: Sky) {
  const cx = view.sx(-177.36), cy = view.sy(28.235), r = 2.4 * view.k;
  if (r < 2.5) {
    ctx.fillStyle = rgb([180, 230, 220], 0.9);
    ctx.beginPath(); ctx.arc(cx, cy, 2.5, 0, Math.PI * 2); ctx.fill();
    return;
  }
  const lag = ctx.createRadialGradient(cx, cy, 0, cx, cy, r);
  const l = 0.35 + 0.65 * sky.light;
  lag.addColorStop(0, `rgba(${46 * l | 0},${170 * l | 0},${176 * l | 0},0.95)`);
  lag.addColorStop(0.85, `rgba(${30 * l | 0},${140 * l | 0},${160 * l | 0},0.9)`);
  lag.addColorStop(1, `rgba(${20 * l | 0},${90 * l | 0},${120 * l | 0},0)`);
  ctx.fillStyle = lag;
  ctx.beginPath(); ctx.ellipse(cx, cy, r * 1.08, r * 0.92, 0, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = `rgba(235,250,250,${0.55 * l})`; ctx.lineWidth = Math.max(1, r * 0.06);
  ctx.beginPath(); ctx.ellipse(cx, cy, r * 1.02, r * 0.88, 0, 0, Math.PI * 2); ctx.stroke();
  const sand = `rgba(${226 * l | 0},${212 * l | 0},${170 * l | 0},1)`;
  ctx.fillStyle = sand;
  ctx.beginPath(); ctx.ellipse(view.sx(-177.38), view.sy(28.21), r * 0.26, r * 0.17, -0.35, 0, Math.PI * 2); ctx.fill();
  ctx.beginPath(); ctx.ellipse(view.sx(-177.325), view.sy(28.214), r * 0.17, r * 0.12, 0.2, 0, Math.PI * 2); ctx.fill();
}
