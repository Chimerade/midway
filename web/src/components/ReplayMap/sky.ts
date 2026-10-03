// Soleil et lumière du jour à l'instant simulé. Les minutes du replay partent du
// 3 juin 1942 00:00 en zone +12 (GMT−12), soit le 3 juin 12:00 UTC.
import { smoothstep } from './noise';

export type RGB = [number, number, number];

const EPOCH_UTC = Date.UTC(1942, 5, 3, 12, 0, 0);
const RAD = Math.PI / 180;

/** Hauteur et azimut du soleil (degrés), formules abrégées de l'Astronomical Almanac (~0,01°). */
export function sunPosition(tMin: number, lat: number, lon: number): { elev: number; az: number } {
  const n = (EPOCH_UTC + tMin * 60000) / 86400000 + 2440587.5 - 2451545.0;
  const L = 280.460 + 0.9856474 * n;
  const g = (357.528 + 0.9856003 * n) * RAD;
  const lam = (L + 1.915 * Math.sin(g) + 0.020 * Math.sin(2 * g)) * RAD;
  const eps = (23.439 - 0.0000004 * n) * RAD;
  const ra = Math.atan2(Math.cos(eps) * Math.sin(lam), Math.cos(lam));
  const dec = Math.asin(Math.sin(eps) * Math.sin(lam));
  const gmst = 18.697374558 + 24.06570982441908 * n;          // heures
  const H = (gmst * 15 + lon) * RAD - ra;                       // angle horaire
  const phi = lat * RAD;
  const elev = Math.asin(Math.sin(phi) * Math.sin(dec) + Math.cos(phi) * Math.cos(dec) * Math.cos(H));
  const az = Math.atan2(-Math.sin(H), Math.tan(dec) * Math.cos(phi) - Math.sin(phi) * Math.cos(H));
  return { elev: elev / RAD, az: ((az / RAD) % 360 + 360) % 360 };
}

export interface Sky {
  elev: number; az: number;
  light: number;      // 0 nuit noire → 1 plein jour
  warm: number;       // lumière rasante de l'aube et du crépuscule
  deep: RGB; shallow: RGB;   // océan : bords / centre de l'écran
  tint: RGB | null;   // teinte multiplicative du monde (null en plein jour)
  shadow: number;     // allongement des ombres portées (0 = soleil couché)
  cloudLit: RGB; cloudBase: RGB;
}

const mix = (a: RGB, b: RGB, t: number): RGB => [a[0] + (b[0] - a[0]) * t, a[1] + (b[1] - a[1]) * t, a[2] + (b[2] - a[2]) * t];

// Paliers de lumière : nuit, crépuscule civil, heure dorée, jour
const OCEAN = {
  night: { deep: [2, 6, 13] as RGB, shallow: [6, 13, 26] as RGB },
  dusk: { deep: [9, 17, 36] as RGB, shallow: [26, 34, 62] as RGB },
  gold: { deep: [14, 34, 58] as RGB, shallow: [52, 68, 88] as RGB },
  day: { deep: [5, 42, 72] as RGB, shallow: [12, 78, 116] as RGB },
};
const TINT = { night: [58, 76, 118] as RGB, dusk: [128, 122, 158] as RGB, gold: [255, 214, 176] as RGB, day: [255, 255, 255] as RGB };
const CLOUD = {
  night: { lit: [46, 56, 76] as RGB, base: [24, 30, 44] as RGB },
  dusk: { lit: [168, 160, 184] as RGB, base: [70, 72, 98] as RGB },
  gold: { lit: [252, 232, 220] as RGB, base: [146, 146, 166] as RGB },
  day: { lit: [250, 252, 255] as RGB, base: [184, 196, 210] as RGB },
};

function ramp<T>(e: number, f: (a: keyof typeof OCEAN, b: keyof typeof OCEAN, t: number) => T): T {
  if (e < -4) return f('night', 'dusk', smoothstep(-12, -4, e));
  if (e < 2) return f('dusk', 'gold', smoothstep(-4, 2, e));
  return f('gold', 'day', smoothstep(2, 16, e));
}

/** Lumière à l'instant t au point (lat, lon) — l'écran entier partage ce ciel. */
export function skyAt(tMin: number, lat: number, lon: number): Sky {
  const { elev, az } = sunPosition(tMin, lat, lon);
  const ocean = ramp(elev, (a, b, t) => ({ deep: mix(OCEAN[a].deep, OCEAN[b].deep, t), shallow: mix(OCEAN[a].shallow, OCEAN[b].shallow, t) }));
  const tint = ramp(elev, (a, b, t) => mix(TINT[a], TINT[b], t));
  const cloud = ramp(elev, (a, b, t) => ({ lit: mix(CLOUD[a].lit, CLOUD[b].lit, t), base: mix(CLOUD[a].base, CLOUD[b].base, t) }));
  const white = tint[0] > 252 && tint[1] > 252 && tint[2] > 252;
  return {
    elev, az,
    light: smoothstep(-10, 10, elev),
    warm: smoothstep(-5, 2, elev) * (1 - smoothstep(5, 18, elev)),
    deep: ocean.deep, shallow: ocean.shallow,
    tint: white ? null : tint,
    shadow: elev > 0 ? Math.min(1, 0.35 / Math.tan(Math.max(elev, 8) * RAD)) : 0,
    cloudLit: cloud.lit, cloudBase: cloud.base,
  };
}

export const rgb = (c: RGB, a = 1) => `rgba(${c[0] | 0},${c[1] | 0},${c[2] | 0},${a})`;
