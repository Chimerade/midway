// Effets : sillages, fumées, incendies, DCA, traçantes, explosions, nappes de
// mazout. Tout est déterministe (fonction du temps et d'un aléa stable) : pas
// d'état de particules à conserver, l'image est la même à chaque passage au
// même instant.
import { hash } from './noise';
import { FIRE_GLOW, FLAK_PUFF, FLASH_GLOW, SMOKE_PUFF, SPLASH, blit } from './sprites';

const TAU = Math.PI * 2;
const KELVIN = Math.tan(19.47 * Math.PI / 180);   // demi-angle du sillage de Kelvin

/**
 * Sillage derrière la poupe (repère local : proue vers le haut). Longueur ∝ vitesse ;
 * deux bras divergents à l'angle de Kelvin et une traînée d'écume au centre.
 */
export function drawWake(ctx: CanvasRenderingContext2D, len: number, speedKn: number, light: number, tReal: number) {
  if (speedKn < 1.5) return;
  const L = Math.min(len * 1.9, speedKn * len * 0.055 + len * 0.25), y0 = len * 0.48;
  const a = 0.14 + 0.24 * light;
  for (const sgn of [-1, 1]) {
    const g = ctx.createLinearGradient(0, y0, 0, y0 + L);
    g.addColorStop(0, `rgba(235,245,250,${a})`); g.addColorStop(1, 'rgba(235,245,250,0)');
    ctx.strokeStyle = g; ctx.lineWidth = Math.max(0.6, len * 0.025);
    ctx.beginPath(); ctx.moveTo(sgn * len * 0.06, y0); ctx.lineTo(sgn * L * KELVIN, y0 + L); ctx.stroke();
  }
  const g = ctx.createLinearGradient(0, y0, 0, y0 + L * 0.75);
  g.addColorStop(0, `rgba(245,250,252,${a * 1.6})`); g.addColorStop(1, 'rgba(245,250,252,0)');
  ctx.strokeStyle = g; ctx.lineWidth = Math.max(1, len * 0.075); ctx.lineCap = 'round';
  ctx.setLineDash([len * 0.22, len * 0.09]); ctx.lineDashOffset = -tReal * len * 0.6;
  ctx.beginPath(); ctx.moveTo(0, y0); ctx.lineTo(0, y0 + L * 0.75); ctx.stroke();
  ctx.setLineDash([]); ctx.lineCap = 'butt';
}

/** Panache de fumée noire poussé par le vent (ux, uy en repère écran). */
export function drawSmoke(ctx: CanvasRenderingContext2D, x: number, y: number, ux: number, uy: number,
                          lengthPx: number, intensity: number, seed: number, tReal: number, light: number) {
  const N = 18, puff = SMOKE_PUFF();
  for (let i = 0; i < N; i++) {
    const a = (tReal * 0.045 + i / N + hash(seed, i) * 0.03) % 1;
    const d = a * lengthPx, wob = Math.sin(a * 7 + seed + i) * a * lengthPx * 0.07;
    const px = x + ux * d - uy * wob, py = y + uy * d + ux * wob;
    const r = (3 + a * lengthPx * 0.2) * (0.6 + 0.4 * intensity);
    blit(ctx, puff, px, py, r, 0.62 * Math.pow(1 - a, 1.3) * intensity * (0.75 + 0.25 * light));
  }
}

/** Foyer d'incendie : lueur vacillante et flammèches (à dessiner en mode additif). */
export function drawFire(ctx: CanvasRenderingContext2D, x: number, y: number, size: number, seed: number, tReal: number, night: number) {
  const flick = 0.75 + 0.25 * Math.sin(tReal * 9 + seed) * Math.sin(tReal * 5.3 + seed * 2);
  blit(ctx, FIRE_GLOW(), x, y, size * (1.6 + 1.4 * night) * flick, 0.75 + 0.25 * night);
  for (let i = 0; i < 4; i++) {
    const fx = x + (hash(seed, i) - 0.5) * size * 0.9, fy = y + (hash(seed, i + 9) - 0.5) * size * 1.6;
    blit(ctx, FLASH_GLOW(), fx, fy, size * (0.25 + 0.2 * Math.abs(Math.sin(tReal * 11 + i * 3 + seed))), 0.9);
  }
}

/** Barrage antiaérien : éclats d'obus (bouffées sombres) autour de la cible. */
export function drawFlak(ctx: CanvasRenderingContext2D, x: number, y: number, R: number, seed: number, tReal: number) {
  const P = 1.7;
  for (let i = 0; i < 14; i++) {
    const ph = tReal / P + hash(seed, i), cyc = Math.floor(ph), a = ph - cyc;
    const ang = hash(seed + cyc, i * 3) * TAU, rr = R * (0.25 + 0.75 * Math.sqrt(hash(seed + cyc, i * 3 + 1)));
    const px = x + Math.cos(ang) * rr, py = y + Math.sin(ang) * rr;
    blit(ctx, FLAK_PUFF(), px, py, 2.5 + a * 8, 0.75 * Math.pow(1 - a, 1.2));
    if (a < 0.08) {
      ctx.globalCompositeOperation = 'lighter';
      blit(ctx, FLASH_GLOW(), px, py, 5 * (1 - a / 0.08) + 2, 0.9);
      ctx.globalCompositeOperation = 'source-over';
    }
  }
}

/** Traçantes : traits brefs partant des navires vers le ciel (mode additif). */
export function drawTracers(ctx: CanvasRenderingContext2D, x: number, y: number, R: number, seed: number, tReal: number) {
  ctx.lineCap = 'round';
  for (let i = 0; i < 12; i++) {
    const P = 0.45 + hash(seed, i) * 0.3, ph = tReal / P + hash(seed, i + 40), cyc = Math.floor(ph), a = ph - cyc;
    const ang = hash(seed + cyc * 7, i) * TAU, r0 = R * 0.12 + a * R * 0.8;
    const sx = x + Math.cos(ang) * r0, sy = y + Math.sin(ang) * r0;
    const ex = sx + Math.cos(ang) * R * 0.16, ey = sy + Math.sin(ang) * R * 0.16;
    ctx.strokeStyle = `rgba(255,${190 + (i % 3) * 20},110,${0.85 * (1 - a)})`;
    ctx.lineWidth = 1.4;
    ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(ex, ey); ctx.stroke();
  }
  ctx.lineCap = 'butt';
}

/**
 * Coups au but (explosions) ou bombes manquées (gerbes d'eau) autour de la cible.
 * `hit` : bombe qui touche ; sinon gerbe blanche et onde à la surface.
 */
export function drawStrikes(ctx: CanvasRenderingContext2D, x: number, y: number, R: number, hit: boolean, seed: number, tReal: number) {
  const P = hit ? 1.5 : 1.15;
  for (let i = 0; i < 3; i++) {
    const ph = tReal / P + i / 3 + hash(seed, i) * 0.2, cyc = Math.floor(ph), a = ph - cyc;
    const ang = hash(seed + cyc, i + 5) * TAU, rr = R * (hit ? 0.12 : 0.25 + 0.4 * hash(seed + cyc, i + 6));
    const px = x + Math.cos(ang) * rr, py = y + Math.sin(ang) * rr;
    if (hit) {
      ctx.globalCompositeOperation = 'lighter';
      blit(ctx, FLASH_GLOW(), px, py, 6 + a * R * 0.55, Math.pow(1 - a, 2));
      ctx.globalCompositeOperation = 'source-over';
      blit(ctx, SMOKE_PUFF(), px, py, 4 + a * R * 0.4, 0.7 * a * (1 - a) * 4);
    } else {
      blit(ctx, SPLASH(), px, py, 3 + a * R * 0.3, 0.85 * Math.pow(1 - a, 1.5));
    }
    ctx.strokeStyle = `rgba(240,248,255,${0.6 * Math.pow(1 - a, 2)})`; ctx.lineWidth = 1;
    ctx.beginPath(); ctx.arc(px, py, 3 + a * R * (hit ? 0.7 : 0.45), 0, TAU); ctx.stroke();
  }
}

/** Nappe de mazout sur l'épave : s'étale et dérive sous le vent avec le temps. */
export function drawOilSlick(ctx: CanvasRenderingContext2D, x: number, y: number, ux: number, uy: number,
                             ageMin: number, k: number, light: number) {
  const grow = Math.min(1, Math.sqrt(Math.max(0, ageMin) / 240));
  const len = Math.max(6, (0.6 + 2.4 * grow) * k * 2.2), wid = len * 0.45;
  const ang = Math.atan2(uy, ux);
  const cx = x + ux * len * 0.35, cy = y + uy * len * 0.35;
  ctx.save(); ctx.translate(cx, cy); ctx.rotate(ang);
  const g = ctx.createRadialGradient(0, 0, 0, 0, 0, len / 2);
  g.addColorStop(0, `rgba(6,8,12,${0.5 * (0.6 + 0.4 * light)})`);
  g.addColorStop(0.7, `rgba(30,40,60,${0.22})`);
  g.addColorStop(0.9, `rgba(90,70,120,${0.12 * light})`);
  g.addColorStop(1, 'rgba(20,30,50,0)');
  ctx.fillStyle = g;
  ctx.beginPath(); ctx.ellipse(0, 0, len / 2, wid / 2, 0, 0, TAU); ctx.fill();
  ctx.restore();
}

/** Appareil abattu : spirale de fumée, flamme en tête puis gerbe à l'impact. */
export function drawShotDown(ctx: CanvasRenderingContext2D, x: number, y: number, age: number, seed: number, size: number) {
  const fall = Math.min(1, age / 8);                        // 8 minutes simulées de chute
  const turns = 1.1 + hash(seed) * 0.8, r0 = size * (1.6 + hash(seed, 2) * 1.1);
  ctx.strokeStyle = `rgba(40,38,38,${0.42 * (1 - Math.min(1, Math.max(0, age - 6) / 8))})`;
  ctx.lineWidth = Math.max(0.8, size * 0.16); ctx.beginPath();
  for (let s = 0; s <= 24; s++) {
    const f = (s / 24) * fall, ang = f * turns * TAU + seed, rr = r0 * (1 - f * 0.85);
    const px = x + Math.cos(ang) * rr + f * size * 3, py = y + Math.sin(ang) * rr + f * size * 4;
    if (s === 0) ctx.moveTo(px, py); else ctx.lineTo(px, py);
  }
  ctx.stroke();
  const ang = fall * turns * TAU + seed, rr = r0 * (1 - fall * 0.85);
  const hx = x + Math.cos(ang) * rr + fall * size * 3, hy = y + Math.sin(ang) * rr + fall * size * 4;
  if (fall < 1) {
    ctx.globalCompositeOperation = 'lighter';
    blit(ctx, FIRE_GLOW(), hx, hy, size * 1.2, 0.9);
    ctx.globalCompositeOperation = 'source-over';
  } else if (age < 14) {
    const a = (age - 8) / 6;
    blit(ctx, SPLASH(), hx, hy, size * (0.8 + a * 1.6), 0.8 * (1 - a));
  }
}
