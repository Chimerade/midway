// Repère de la carte : projection équirectangulaire centrée sur Midway, en milles
// nautiques (x vers l'est, y vers le nord), puis en pixels CSS à l'écran.

export const LAT0 = 28.21, LON0 = -177.37, RAD = Math.PI / 180;
const COS0 = Math.cos(LAT0 * RAD);

export function unwrap(lon: number) { return lon > 0 ? lon - 360 : lon; }

export interface View {
  W: number; H: number;
  k: number;                 // pixels CSS par mille nautique
  scale: number;             // zoom de l'interface
  panX: number; panY: number;
  nmX(lon: number): number; nmY(lat: number): number;
  sx(lon: number): number; sy(lat: number): number;
  toNmX(sx: number): number; toNmY(sy: number): number;
  toLatLon(sx: number, sy: number): { lat: number; lon: number };
}

export function makeView(W: number, H: number, scale: number, panX: number, panY: number): View {
  const k = scale * Math.min(W, H) / 900;
  const nmX = (lon: number) => (unwrap(lon) - LON0) * 60 * COS0;
  const nmY = (lat: number) => (lat - LAT0) * 60;
  const toNmX = (sx: number) => (sx - W / 2) / k - panX;
  const toNmY = (sy: number) => (H / 2 - sy) / k - panY;
  return {
    W, H, k, scale, panX, panY, nmX, nmY, toNmX, toNmY,
    sx: (lon) => W / 2 + (nmX(lon) + panX) * k,
    sy: (lat) => H / 2 - (nmY(lat) + panY) * k,
    toLatLon: (sx, sy) => ({ lat: LAT0 + toNmY(sy) / 60, lon: LON0 + toNmX(sx) / (60 * COS0) }),
  };
}

/** Cap (°) d'un point à un autre, dans le repère de la carte. */
export function bearing(a: { lat: number; lon: number }, b: { lat: number; lon: number }) {
  const dlat = (b.lat - a.lat) * 60, dlon = (unwrap(b.lon) - unwrap(a.lon)) * 60 * COS0;
  return (Math.atan2(dlon, dlat) * 180 / Math.PI + 360) % 360;
}

export function distNm(a: { lat: number; lon: number }, b: { lat: number; lon: number }) {
  const dlat = (b.lat - a.lat) * 60, dlon = (unwrap(b.lon) - unwrap(a.lon)) * 60 * COS0;
  return Math.hypot(dlat, dlon);
}
