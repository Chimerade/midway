// Silhouettes vues du ciel (proue vers le haut, centrées sur l'origine) et
// sprites lumineux mis en cache. Couleurs d'époque : ponts des porte-avions US
// teints en bleu-gris (Deck Stain 21), ponts japonais en bois clair avec
// hinomaru à la proue et bandes blanches à la poupe.

const PORT_ISLAND = new Set(['SH-AKAGI', 'SH-HIRYU']);   // îlot à bâbord

export interface ShipLook { side: 'IJN' | 'USN'; burning: number; light: number; }

const shade = (c: [number, number, number], l: number) => `rgb(${c[0] * l | 0},${c[1] * l | 0},${c[2] * l | 0})`;

/** Porte-avions : coque, pont d'envol, marques, îlot. */
export function drawCarrier(ctx: CanvasRenderingContext2D, len: number, id: string, look: ShipLook) {
  // largeur exagérée (~1/5 de la longueur) pour rester lisible à petite échelle
  const w = len * 0.2, l = 0.55 + 0.45 * look.light, ijn = look.side === 'IJN';
  const hull = new Path2D();
  hull.moveTo(0, -len / 2);
  hull.bezierCurveTo(w * 0.62, -len * 0.36, w * 0.6, len * 0.36, w * 0.48, len / 2);
  hull.lineTo(-w * 0.48, len / 2);
  hull.bezierCurveTo(-w * 0.6, len * 0.36, -w * 0.62, -len * 0.36, 0, -len / 2);
  ctx.fillStyle = shade([58, 64, 70], l); ctx.fill(hull);
  ctx.strokeStyle = 'rgba(0,6,14,0.55)'; ctx.lineWidth = 1; ctx.stroke(hull);
  // pont d'envol (dépasse légèrement la coque)
  const dw = w * 1.08, dt = -len * 0.44, db = len * 0.47;
  const deck: [number, number, number] = ijn ? [150, 128, 88] : [74, 88, 102];
  ctx.fillStyle = shade(deck, l * (1 - 0.55 * look.burning));
  ctx.beginPath(); ctx.moveTo(-dw * 0.28, dt); ctx.lineTo(dw * 0.28, dt); ctx.lineTo(dw / 2, dt + len * 0.08);
  ctx.lineTo(dw / 2, db); ctx.lineTo(-dw / 2, db); ctx.lineTo(-dw / 2, dt + len * 0.08); ctx.closePath(); ctx.fill();
  if (len >= 18) {
    ctx.strokeStyle = `rgba(235,235,225,${0.55 * l})`; ctx.lineWidth = Math.max(0.6, len * 0.012);
    if (ijn) {
      for (const y of [db - len * 0.06, db - len * 0.1]) { ctx.beginPath(); ctx.moveTo(-dw / 2, y); ctx.lineTo(dw / 2, y); ctx.stroke(); }
      ctx.fillStyle = shade([176, 44, 38], l);
      ctx.beginPath(); ctx.arc(0, dt + len * 0.13, w * 0.3, 0, Math.PI * 2); ctx.fill();
    } else {
      ctx.setLineDash([len * 0.05, len * 0.04]);
      ctx.beginPath(); ctx.moveTo(0, dt + len * 0.08); ctx.lineTo(0, db - len * 0.04); ctx.stroke();
      ctx.setLineDash([]);
    }
  }
  // îlot
  const ix = (PORT_ISLAND.has(id) ? -1 : 1) * dw * 0.5;
  ctx.fillStyle = shade([40, 44, 50], l);
  ctx.fillRect(ix - (ix > 0 ? w * 0.34 : 0), -len * 0.1, w * 0.34, len * 0.17);
}

const ESCORT_LEN: Record<string, number> = { BB: 0.82, CA: 0.66, CL: 0.58, DD: 0.42, AO: 0.5, AP: 0.5 };

/** Bâtiment d'escorte : coque effilée et superstructures. */
export function drawWarship(ctx: CanvasRenderingContext2D, len: number, type: string, look: ShipLook) {
  const w = len * (type === 'DD' ? 0.17 : type === 'BB' ? 0.23 : 0.19), l = 0.55 + 0.45 * look.light;
  ctx.fillStyle = shade(look.side === 'IJN' ? [118, 122, 124] : [104, 118, 132], l);
  ctx.beginPath(); ctx.moveTo(0, -len / 2);
  ctx.bezierCurveTo(w * 0.7, -len * 0.25, w * 0.6, len * 0.4, w * 0.4, len / 2);
  ctx.lineTo(-w * 0.4, len / 2);
  ctx.bezierCurveTo(-w * 0.6, len * 0.4, -w * 0.7, -len * 0.25, 0, -len / 2);
  ctx.fill();
  ctx.strokeStyle = 'rgba(0,6,14,0.5)'; ctx.lineWidth = 0.8; ctx.stroke();
  ctx.fillStyle = shade([52, 56, 62], l);
  ctx.fillRect(-w * 0.28, -len * 0.18, w * 0.56, len * 0.3);
  if (type === 'BB' || type === 'CA') {
    ctx.beginPath(); ctx.arc(0, -len * 0.3, w * 0.22, 0, Math.PI * 2); ctx.arc(0, len * 0.28, w * 0.22, 0, Math.PI * 2); ctx.fill();
  }
}
export const escortLen = (type: string) => ESCORT_LEN[type] ?? 0.5;

export type PlaneKind = 'single' | 'twin' | 'four' | 'boat';

/** Classe d'appareil d'après la désignation (B-17 quadrimoteur, B-26 bimoteur, PBY hydravion). */
export function planeKind(designation: string | undefined): PlaneKind {
  if (!designation) return 'single';
  if (/B-17|Fortress/i.test(designation)) return 'four';
  if (/PBY|Catalina/i.test(designation)) return 'boat';
  if (/B-26|Marauder/i.test(designation)) return 'twin';
  return 'single';
}

/** Avion vu de dessus (nez vers le haut), taille = envergure en px. */
export function drawPlane(ctx: CanvasRenderingContext2D, size: number, kind: PlaneKind, color: string, outline = false) {
  const s = size;
  if (outline) {          // liseré sombre : l'avion se détache sur les nuages blancs
    ctx.save(); ctx.scale(1.18, 1.18); drawPlane(ctx, size, kind, 'rgba(4,10,20,0.55)'); ctx.restore();
  }
  ctx.fillStyle = color;
  ctx.beginPath();
  // fuselage
  ctx.ellipse(0, 0, s * (kind === 'single' ? 0.08 : 0.07), s * (kind === 'boat' ? 0.42 : 0.48), 0, 0, Math.PI * 2);
  ctx.fill();
  // voilure
  const wy = kind === 'single' ? -s * 0.06 : -s * 0.1, ch = s * (kind === 'single' ? 0.16 : 0.13);
  ctx.beginPath(); ctx.moveTo(-s / 2, wy + ch * 0.25); ctx.lineTo(-s * 0.06, wy - ch * 0.5);
  ctx.lineTo(s * 0.06, wy - ch * 0.5); ctx.lineTo(s / 2, wy + ch * 0.25); ctx.lineTo(s / 2, wy + ch * 0.6);
  ctx.lineTo(-s / 2, wy + ch * 0.6); ctx.closePath(); ctx.fill();
  // empennage
  const ty = s * (kind === 'boat' ? 0.36 : 0.4);
  ctx.beginPath(); ctx.moveTo(-s * 0.18, ty); ctx.lineTo(s * 0.18, ty); ctx.lineTo(s * 0.12, ty + s * 0.07); ctx.lineTo(-s * 0.12, ty + s * 0.07); ctx.closePath(); ctx.fill();
  // moteurs
  if (kind !== 'single') {
    const xs = kind === 'four' ? [-0.34, -0.17, 0.17, 0.34] : [-0.2, 0.2];
    for (const x of xs) { ctx.beginPath(); ctx.ellipse(x * s, wy - ch * 0.15, s * 0.035, s * 0.09, 0, 0, Math.PI * 2); ctx.fill(); }
  }
}

// --- sprites lumineux (dégradés radiaux) mis en cache par couleur ------------
const glowCache = new Map<string, HTMLCanvasElement>();
/** Halo radial doux de 128 px, à dessiner mis à l'échelle (mode « lighter » pour la lumière). */
export function glow(stops: [number, string][]): HTMLCanvasElement {
  const key = JSON.stringify(stops);
  let cv = glowCache.get(key);
  if (!cv) {
    cv = document.createElement('canvas'); cv.width = cv.height = 128;
    const c = cv.getContext('2d')!, g = c.createRadialGradient(64, 64, 0, 64, 64, 64);
    stops.forEach(([o, col]) => g.addColorStop(o, col));
    c.fillStyle = g; c.fillRect(0, 0, 128, 128);
    glowCache.set(key, cv);
  }
  return cv;
}

export const FIRE_GLOW = () => glow([[0, 'rgba(255,236,170,0.95)'], [0.25, 'rgba(255,150,50,0.55)'], [0.6, 'rgba(220,70,20,0.18)'], [1, 'rgba(160,30,10,0)']]);
export const FLASH_GLOW = () => glow([[0, 'rgba(255,255,240,1)'], [0.2, 'rgba(255,220,140,0.85)'], [0.55, 'rgba(255,120,40,0.3)'], [1, 'rgba(255,80,20,0)']]);
export const SMOKE_PUFF = () => glow([[0, 'rgba(22,20,20,0.85)'], [0.5, 'rgba(30,28,28,0.45)'], [1, 'rgba(40,38,38,0)']]);
export const FLAK_PUFF = () => glow([[0, 'rgba(26,26,28,0.9)'], [0.55, 'rgba(34,34,36,0.5)'], [1, 'rgba(40,40,44,0)']]);
export const SPLASH = () => glow([[0, 'rgba(255,255,255,0.95)'], [0.45, 'rgba(225,240,250,0.55)'], [1, 'rgba(200,225,240,0)']]);
export const SHADOW_BLOB = () => glow([[0, 'rgba(0,6,14,0.55)'], [0.6, 'rgba(0,6,14,0.25)'], [1, 'rgba(0,6,14,0)']]);

export function blit(ctx: CanvasRenderingContext2D, sprite: HTMLCanvasElement, x: number, y: number, r: number, alpha = 1) {
  if (r <= 0.3 || alpha <= 0.01) return;
  ctx.globalAlpha = Math.min(1, alpha);
  ctx.drawImage(sprite, x - r, y - r, r * 2, r * 2);
  ctx.globalAlpha = 1;
}
