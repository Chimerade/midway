// Bruit de valeur 2D lissé et déterministe : base des textures d'océan et des
// nuages. Même graine à chaque chargement, donc la même mer et le même ciel.

const PERM = new Uint8Array(512);
const VAL = new Float32Array(256);

(function init() {
  let s = 0x2f6b9a1d;
  const rnd = () => { // mulberry32
    s = (s + 0x6d2b79f5) | 0;
    let t = Math.imul(s ^ (s >>> 15), 1 | s);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
  const p = Array.from({ length: 256 }, (_, i) => i);
  for (let i = 255; i > 0; i--) { const j = Math.floor(rnd() * (i + 1)); [p[i], p[j]] = [p[j], p[i]]; }
  for (let i = 0; i < 512; i++) PERM[i] = p[i & 255];
  for (let i = 0; i < 256; i++) VAL[i] = rnd();
})();

/** Bruit dans [0,1]. `px`, `py` rendent le motif périodique (textures raccordables). */
export function vnoise(x: number, y: number, px = 256, py = px): number {
  const xi = Math.floor(x), yi = Math.floor(y);
  const xf = x - xi, yf = y - yi;
  const x0 = ((xi % px) + px) % px, y0 = ((yi % py) + py) % py;
  const x1 = (x0 + 1) % px, y1 = (y0 + 1) % py;
  const r0 = PERM[y0 & 255], r1 = PERM[y1 & 255];
  const v00 = VAL[PERM[(x0 & 255) + r0]], v10 = VAL[PERM[(x1 & 255) + r0]];
  const v01 = VAL[PERM[(x0 & 255) + r1]], v11 = VAL[PERM[(x1 & 255) + r1]];
  const u = xf * xf * (3 - 2 * xf), v = yf * yf * (3 - 2 * yf);
  const a = v00 + (v10 - v00) * u, b = v01 + (v11 - v01) * u;
  return a + (b - a) * v;
}

/** Pseudo-aléa stable dans [0,1) pour les effets (positions d'éclats, scintillement). */
export function hash(a: number, b = 0): number {
  const s = Math.sin(a * 127.1 + b * 311.7) * 43758.5453;
  return s - Math.floor(s);
}

export const smoothstep = (e0: number, e1: number, x: number) => {
  const t = Math.min(1, Math.max(0, (x - e0) / (e1 - e0)));
  return t * t * (3 - 2 * t);
};
