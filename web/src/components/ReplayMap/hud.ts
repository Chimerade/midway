// Couche tactique dessinée par-dessus le monde : lisible de jour comme de nuit,
// jamais teintée par l'éclairage. Couleurs de camp éclaircies pour la mer sombre.
import type { Lang } from '../../i18n/strings';
import type { Sky } from './sky';
import type { View } from './view';
import { LAT0, LON0 } from './view';
import type { Wind } from './weather';

export const HUD = {
  USN: '#62adff', IJN: '#ff6257', amber: '#ffc54d', combat: '#ff8f3f', radar: '#5ef0c4',
  text: '#eef4fa', text2: 'rgba(214,226,238,0.8)', outline: 'rgba(2,8,18,0.85)',
  grid: 'rgba(196,224,255,0.09)', gridLbl: 'rgba(206,226,246,0.55)',
};
export const sideColor = (side: string) => (side === 'IJN' ? HUD.IJN : HUD.USN);

export const MONO = 'ui-monospace, "SF Mono", Menlo, Consolas, monospace';
const SANS = 'Verdana, sans-serif';

export const CANVAS_STR = {
  fr: { sunk: 'coulé', onFire: 'en feu', disabled: 'désemparé', spotted: 'repéré', reported: 'contact rapporté', ac: 'av.', perLine: '/ligne',
        takeoff: 'décollage…', stale: 'périmée', sun: 'SOLEIL', night: 'NUIT', dawn: 'AUBE', dusk: 'CRÉPUSCULE',
        wind: 'VENT', kt: 'NDS', hit: 'COUPS AU BUT', attack: 'ATTAQUE', collision: 'ABORDAGE', pack: '1 pt = 2' },
  en: { sunk: 'sunk', onFire: 'on fire', disabled: 'disabled', spotted: 'spotted', reported: 'reported contact', ac: 'ac.', perLine: '/line',
        takeoff: 'taking off…', stale: 'stale', sun: 'SUN', night: 'NIGHT', dawn: 'DAWN', dusk: 'DUSK',
        wind: 'WIND', kt: 'KT', hit: 'HITS', attack: 'ATTACK', collision: 'COLLISION', pack: '1 dot = 2' },
} satisfies Record<Lang, Record<string, string>>;

// --- étiquettes avec évitement des chevauchements ---------------------------
let placed: { x: number; y: number; w: number; h: number }[] = [];
export function hudBegin() { placed = []; }

/**
 * Texte avec liseré sombre. Évite les étiquettes déjà posées en descendant ; une
 * étiquette `optional` (secondaire) qui ne trouve pas de place n'est pas dessinée
 * plutôt que d'en chevaucher une autre. Renvoie la ligne utilisée (NaN si masquée).
 */
export function label(ctx: CanvasRenderingContext2D, text: string, x: number, y: number,
                      opt: { font?: string; color?: string; align?: CanvasTextAlign; avoid?: boolean; optional?: boolean } = {}) {
  ctx.font = opt.font ?? `bold 11px ${SANS}`;
  ctx.textAlign = opt.align ?? 'left';
  const w = ctx.measureText(text).width, h = 13;
  let ly = y;
  if (opt.avoid !== false) {
    const left = opt.align === 'center' ? x - w / 2 : opt.align === 'right' ? x - w : x;
    const collides = (yy: number) => placed.find((r) => left < r.x + r.w && left + w > r.x && yy - h + 3 < r.y + r.h && yy + 3 > r.y);
    for (let tries = 0; tries < 6; tries++) {
      const hit = collides(ly);
      if (!hit) break;
      ly = hit.y + hit.h + h - 2;
    }
    if (opt.optional && collides(ly)) { ctx.textAlign = 'left'; return NaN; }
    placed.push({ x: left, y: ly - h + 3, w, h });
  }
  ctx.lineJoin = 'round'; ctx.lineWidth = 3; ctx.strokeStyle = HUD.outline;
  ctx.strokeText(text, x, ly);
  ctx.fillStyle = opt.color ?? HUD.text;
  ctx.fillText(text, x, ly);
  ctx.textAlign = 'left';
  return ly;
}

// --- grille et anneaux ---------------------------------------------------------
export function drawGrid(ctx: CanvasRenderingContext2D, view: View) {
  const { W, H } = view;
  const la0 = Math.floor(view.toLatLon(0, H).lat) - 1, la1 = Math.ceil(view.toLatLon(0, 0).lat) + 1;
  const lo0 = Math.floor(view.toLatLon(0, 0).lon) - 1, lo1 = Math.ceil(view.toLatLon(W, 0).lon) + 1;
  ctx.lineWidth = 1; ctx.strokeStyle = HUD.grid;
  ctx.font = `10px ${MONO}`; ctx.fillStyle = HUD.gridLbl;
  for (let la = Math.max(-10, la0); la <= Math.min(80, la1); la++) {
    const y = view.sy(la);
    ctx.beginPath(); ctx.moveTo(0, y); ctx.lineTo(W, y); ctx.stroke();
    ctx.fillText(`${la}°N`, 8, y - 4);
  }
  for (let lo = lo0; lo <= lo1; lo++) {
    if (lo % 2 !== 0) continue;
    const x = view.sx(lo);
    if (lo === -180) ctx.setLineDash([6, 6]);
    ctx.beginPath(); ctx.moveTo(x, 0); ctx.lineTo(x, H); ctx.stroke();
    ctx.setLineDash([]);
    const lbl = lo < -180 ? `${360 + lo}°E` : lo === -180 ? '180°' : `${-lo}°W`;
    ctx.fillText(lbl, x + 4, H - 8);
  }
}

export function drawRangeRings(ctx: CanvasRenderingContext2D, view: View) {
  const x = view.sx(LON0), y = view.sy(LAT0);
  ctx.strokeStyle = 'rgba(255,214,120,0.16)'; ctx.lineWidth = 1; ctx.setLineDash([2, 6]);
  ctx.font = `10px ${MONO}`; ctx.fillStyle = 'rgba(255,214,120,0.45)';
  [100, 200, 300].forEach((r) => {
    ctx.beginPath(); ctx.arc(x, y, r * view.k, 0, Math.PI * 2); ctx.stroke();
    if (r * view.k > 40) ctx.fillText(`${r} nm`, x + 4, y - r * view.k - 4);
  });
  ctx.setLineDash([]);
}

// --- radar (porte-avions US, Midway) -------------------------------------------
export function drawRadar(ctx: CanvasRenderingContext2D, x: number, y: number, r: number, tReal: number, reduced: boolean) {
  if (r < 14) return;
  const th = ((reduced ? tReal * 0.15 : tReal * 1.25) % (Math.PI * 2));
  ctx.save();
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.clip();
  if (typeof ctx.createConicGradient === 'function') {
    const g = ctx.createConicGradient(th, x, y);
    g.addColorStop(0, 'rgba(94,240,196,0)'); g.addColorStop(0.78, 'rgba(94,240,196,0)'); g.addColorStop(1, 'rgba(94,240,196,0.14)');
    ctx.fillStyle = g; ctx.fillRect(x - r, y - r, r * 2, r * 2);
  }
  ctx.restore();
  ctx.strokeStyle = 'rgba(94,240,196,0.45)'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.moveTo(x, y); ctx.lineTo(x + Math.cos(th) * r, y + Math.sin(th) * r); ctx.stroke();
  ctx.strokeStyle = 'rgba(94,240,196,0.22)'; ctx.setLineDash([3, 5]);
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke(); ctx.setLineDash([]);
}

/** Losange pulsant sur un raid ennemi entré dans la couverture radar US. */
export function drawRadarBlip(ctx: CanvasRenderingContext2D, x: number, y: number, tReal: number) {
  const p = (tReal * 1.6) % 1, s = 7 + p * 6;
  ctx.strokeStyle = `rgba(94,240,196,${0.9 * (1 - p)})`; ctx.lineWidth = 1.4;
  ctx.beginPath(); ctx.moveTo(x, y - s); ctx.lineTo(x + s, y); ctx.lineTo(x, y + s); ctx.lineTo(x - s, y); ctx.closePath(); ctx.stroke();
}

// --- halo d'incertitude -----------------------------------------------------------
export function drawHalo(ctx: CanvasRenderingContext2D, x: number, y: number, r: number, side: string,
                         err: number, stale: boolean, showLabel: boolean, staleWord: string, tReal: number) {
  const c = sideColor(side);
  const g = ctx.createRadialGradient(x, y, 0, x, y, Math.max(1, r));
  g.addColorStop(0, `${c}1f`); g.addColorStop(1, `${c}08`);
  ctx.fillStyle = g; ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.fill();
  ctx.strokeStyle = `${c}99`; ctx.lineWidth = 1.2; ctx.setLineDash([5, 5]); ctx.lineDashOffset = -tReal * 4;
  ctx.beginPath(); ctx.arc(x, y, r, 0, Math.PI * 2); ctx.stroke();
  ctx.setLineDash([]); ctx.lineDashOffset = 0;
  if (showLabel) label(ctx, `±${Math.round(err)} nm${stale ? ` (${staleWord})` : ''}`, x + r * 0.71 + 4, y - r * 0.71 - 4,
    { font: `10px ${MONO}`, color: HUD.text2, optional: true });
}

/** Coins de visée animés autour d'une cible engagée. */
export function drawBrackets(ctx: CanvasRenderingContext2D, x: number, y: number, s: number, color: string, tReal: number) {
  const k = s * (1 + 0.08 * Math.sin(tReal * 6)), l = k * 0.38;
  ctx.strokeStyle = color; ctx.lineWidth = 2;
  for (const [sx, sy] of [[-1, -1], [1, -1], [1, 1], [-1, 1]]) {
    ctx.beginPath(); ctx.moveTo(x + sx * k, y + sy * (k - l)); ctx.lineTo(x + sx * k, y + sy * k); ctx.lineTo(x + sx * (k - l), y + sy * k); ctx.stroke();
  }
}

/** Repérage : onde qui s'élargit et œil stylisé. */
export function drawSpotPing(ctx: CanvasRenderingContext2D, x: number, y: number, tReal: number) {
  const p = (tReal / 1.1) % 1;
  ctx.strokeStyle = `rgba(255,197,77,${0.85 * (1 - p)})`; ctx.lineWidth = 2;
  ctx.beginPath(); ctx.arc(x, y, 8 + p * 22, 0, Math.PI * 2); ctx.stroke();
  const ex = x, ey = y - 20;
  ctx.fillStyle = HUD.outline; ctx.strokeStyle = HUD.amber; ctx.lineWidth = 1.4;
  ctx.beginPath(); ctx.moveTo(ex - 7, ey); ctx.quadraticCurveTo(ex, ey - 6, ex + 7, ey); ctx.quadraticCurveTo(ex, ey + 6, ex - 7, ey); ctx.closePath();
  ctx.fill(); ctx.stroke();
  ctx.fillStyle = HUD.amber; ctx.beginPath(); ctx.arc(ex, ey, 2.2, 0, Math.PI * 2); ctx.fill();
}

/** Marque d'épave : croix tracée et cercle. */
export function drawWreckMark(ctx: CanvasRenderingContext2D, x: number, y: number) {
  ctx.strokeStyle = HUD.outline; ctx.lineWidth = 4;
  ctx.beginPath(); ctx.moveTo(x - 5, y - 5); ctx.lineTo(x + 5, y + 5); ctx.moveTo(x + 5, y - 5); ctx.lineTo(x - 5, y + 5); ctx.stroke();
  ctx.strokeStyle = 'rgba(214,226,238,0.85)'; ctx.lineWidth = 1.6; ctx.stroke();
}

// --- boussole, vent et lumière ------------------------------------------------------
export function drawCompass(ctx: CanvasRenderingContext2D, W: number, wind: Wind, lang: Lang) {
  const S = CANVAS_STR[lang], bx = W - 54, by = 56, br = 30;
  ctx.fillStyle = 'rgba(4,12,24,0.55)'; ctx.strokeStyle = 'rgba(206,226,246,0.35)'; ctx.lineWidth = 1;
  ctx.beginPath(); ctx.arc(bx, by, br, 0, Math.PI * 2); ctx.fill(); ctx.stroke();
  for (let a = 0; a < 360; a += 30) {
    const r1 = a % 90 ? br - 4 : br - 8, rad = (a - 90) * Math.PI / 180;
    ctx.beginPath(); ctx.moveTo(bx + Math.cos(rad) * r1, by + Math.sin(rad) * r1); ctx.lineTo(bx + Math.cos(rad) * br, by + Math.sin(rad) * br); ctx.stroke();
  }
  ctx.fillStyle = HUD.IJN;
  ctx.beginPath(); ctx.moveTo(bx, by - br + 3); ctx.lineTo(bx - 4, by - br + 12); ctx.lineTo(bx + 4, by - br + 12); ctx.closePath(); ctx.fill();
  // vent : flèche dans le sens de la dérive
  const ang = Math.atan2(-wind.uy, wind.ux), L = br - 9;
  const tx = bx + Math.cos(ang) * L, ty = by + Math.sin(ang) * L;
  ctx.strokeStyle = HUD.text; ctx.lineWidth = 1.6;
  ctx.beginPath(); ctx.moveTo(bx - Math.cos(ang) * L * 0.6, by - Math.sin(ang) * L * 0.6); ctx.lineTo(tx, ty); ctx.stroke();
  ctx.fillStyle = HUD.text;
  ctx.beginPath(); ctx.moveTo(tx, ty);
  ctx.lineTo(tx - Math.cos(ang - 0.45) * 7, ty - Math.sin(ang - 0.45) * 7);
  ctx.lineTo(tx - Math.cos(ang + 0.45) * 7, ty - Math.sin(ang + 0.45) * 7); ctx.closePath(); ctx.fill();
  label(ctx, `${S.wind} ${Math.round(wind.from).toString().padStart(3, '0')}° · ${Math.round(wind.spd)} ${S.kt}`, bx, by + br + 15,
    { font: `10px ${MONO}`, color: HUD.text2, align: 'center', avoid: false });
}

export function drawDaylight(ctx: CanvasRenderingContext2D, sky: Sky, lang: Lang) {
  const S = CANVAS_STR[lang], x = 22, y = 22;
  const up = sky.elev > -0.8;
  if (up) {
    ctx.fillStyle = sky.warm > 0.3 ? '#ffb46b' : '#ffe08a';
    ctx.beginPath(); ctx.arc(x, y, 5.5, 0, Math.PI * 2); ctx.fill();
    ctx.strokeStyle = ctx.fillStyle; ctx.lineWidth = 1.4;
    for (let a = 0; a < 8; a++) {
      const r = a * Math.PI / 4;
      ctx.beginPath(); ctx.moveTo(x + Math.cos(r) * 8, y + Math.sin(r) * 8); ctx.lineTo(x + Math.cos(r) * 11, y + Math.sin(r) * 11); ctx.stroke();
    }
  } else {
    ctx.fillStyle = '#cfdcf0';
    ctx.beginPath(); ctx.arc(x, y, 7, 0, Math.PI * 2); ctx.fill();
    ctx.fillStyle = 'rgba(4,12,24,1)';
    ctx.beginPath(); ctx.arc(x + 3.5, y - 2.5, 6.2, 0, Math.PI * 2); ctx.fill();
  }
  const word = sky.elev > 6 ? `${S.sun} ${Math.round(sky.elev)}°` : sky.elev > -6 ? (sky.az < 180 ? S.dawn : S.dusk) : S.night;
  label(ctx, word, x + 17, y + 4, { font: `bold 11px ${MONO}`, color: HUD.text, avoid: false });
}
