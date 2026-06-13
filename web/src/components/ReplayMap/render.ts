import type { ReplayData } from '../../types/replay';
import type { RenderState, Clickable, DrawResult, DrawFn } from './types';

export const LAT0 = 28.21, LON0 = -177.37, RAD = Math.PI / 180;

const colors: Record<string, string> = { USN: '#1f6fce', IJN: '#d23b3b' };

const THEMES = {
  light: {
    bg: '#ffffff', grid: '#e6ecf2', gridLbl: '#9aa7b5', ring: '#d7e1ea', idl: '#b8c6d8',
    label: '#16212e', sub: '#5a6b80', wreck: '#7d8893', midway: '#b07900', contact: '#b07900', stale: .5
  },
  dark: {
    bg: '#0b1220', grid: '#16243d', gridLbl: '#2c4060', ring: '#27406b', idl: '#31496e',
    label: '#f0f4f8', sub: '#8fa3bd', wreck: '#888', midway: '#ffd479', contact: '#ffd479', stale: .5
  }
} as const;

export function unwrap(lon: number) { return lon > 0 ? lon - 360 : lon; }

function pxnm(cv: HTMLCanvasElement) { return Math.min(cv.width, cv.height) / 900; }

export function proj(lat: number, lon: number, cv: HTMLCanvasElement, st: RenderState): [number, number] {
  const x = (unwrap(lon) - LON0) * 60 * Math.cos(LAT0 * RAD), y = (lat - LAT0) * 60;
  return [cv.width / 2 + (x + st.panX) * st.scale * pxnm(cv), cv.height / 2 - (y + st.panY) * st.scale * pxnm(cv)];
}

export function fmt(t: number) {
  t = Math.floor(t);
  const d = 3 + Math.floor(t / 1440), mins = ((t % 1440) + 1440) % 1440, h = Math.floor(mins / 60), m = mins % 60;
  return `${d} juin 1942 — ${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')} (GMT−12)`;
}

export function cardinal(b: number) { return ['N', 'NE', 'E', 'SE', 'S', 'SO', 'O', 'NO'][Math.round(((b % 360) + 360) % 360 / 45) % 8]; }

export function routeTo(a: any, b: any) {
  const dlat = (b.lat - a.lat) * 60, dlon = (unwrap(b.lon) - unwrap(a.lon)) * 60 * Math.cos(LAT0 * RAD);
  return (Math.atan2(dlon, dlat) * 180 / Math.PI + 360) % 360;
}

export function distNm(a: any, b: any) {
  const dlat = (b.lat - a.lat) * 60, dlon = (unwrap(b.lon) - unwrap(a.lon)) * 60 * Math.cos(LAT0 * RAD);
  return Math.hypot(dlat, dlon);
}

export function interp(track: any[], t: number): any {
  if (t < track[0].t) return null;
  for (let i = 0; i < track.length - 1; i++) {
    const a = track[i], b = track[i + 1];
    if (t >= a.t && t <= b.t) {
      const f = (t - a.t) / Math.max(1, b.t - a.t);
      return {
        lat: a.lat + f * (b.lat - a.lat), lon: unwrap(a.lon) + f * (unwrap(b.lon) - unwrap(a.lon)),
        err: a.err + f * (b.err - a.err), route: routeTo(a, b)
      };
    }
  }
  const last = track[track.length - 1];
  if (t - last.t < 360) {
    const prev = track.length > 1 ? track[track.length - 2] : null;
    // piste périmée: l'incertitude CROÎT avec le temps écoulé (~5 nm/h, plafond 90)
    const grown = Math.min(90, last.err + (t - last.t) / 60 * 5);
    return {
      lat: last.lat, lon: unwrap(last.lon), err: grown, stale: true,
      route: prev ? routeTo(prev, last) : null
    };
  }
  return null;
}

function posOf(entId: string, t: number, data: ReplayData, entById: Record<string, any>): any {
  // position d'une entité (piste, Midway, ou épave)
  if (entId === 'SH-MIDWAY') return { lat: 28.21, lon: -177.37 };
  if (entById[entId]) return interp(entById[entId].track, t);
  const w = data.wrecks.find(w => w.ent === entId); return w ? { lat: w.lat, lon: w.lon } : null;
}

function isSunk(entId: string, t: number, data: ReplayData): boolean {
  const w = data.wrecks.find(w => w.ent === entId); return !!(w && t >= w.t);
}

export const draw: DrawFn = (ctx, cv, data, st): DrawResult => {
  const D = data;
  const clickables: Clickable[] = [];
  const entById: Record<string, any> = {}; D.entities.forEach(e => entById[e.id] = e);
  const P = THEMES[st.theme];
  cv.width = (cv.parentElement as HTMLElement).clientWidth; cv.height = (cv.parentElement as HTMLElement).clientHeight;
  ctx.fillStyle = P.bg; ctx.fillRect(0, 0, cv.width, cv.height);
  // grille
  // grille dynamique — couvre le viewport (parallèles 1°, méridiens 2°, antiméridien en pointillé)
  ctx.lineWidth = 1; ctx.font = '9px Verdana';
  const _il = (sy: number) => LAT0 + ((cv.height / 2 - sy) / (st.scale * pxnm(cv)) - st.panY) / 60;
  const _io = (sx: number) => LON0 + ((sx - cv.width / 2) / (st.scale * pxnm(cv)) - st.panX) / (60 * Math.cos(LAT0 * RAD));
  const la0 = Math.max(-10, Math.floor(_il(cv.height)) - 1), la1 = Math.min(80, Math.ceil(_il(0)) + 1);
  const lo0 = Math.floor(_io(0)) - 1, lo1 = Math.ceil(_io(cv.width)) + 1;
  ctx.strokeStyle = P.grid; ctx.fillStyle = P.gridLbl;
  for (let la = la0; la <= la1; la++) {
    const [x1, y1] = proj(la, lo0, cv, st), [x2, y2] = proj(la, lo1, cv, st);
    ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke(); ctx.fillText(la + '°N', 8, y1 - 3);
  }
  for (let lo = lo0; lo <= lo1; lo++) {
    if (lo % 2 !== 0) continue;
    const [x1, y1] = proj(la0, lo, cv, st), [x2, y2] = proj(la1, lo, cv, st);
    ctx.beginPath(); ctx.moveTo(x1, y1); ctx.lineTo(x2, y2); ctx.stroke();
    const lbl = lo < -180 ? (360 + lo) + '°E' : (lo === -180 ? '180° (date)' : (-lo) + '°W'); ctx.fillStyle = P.gridLbl; ctx.fillText(lbl, x1 + 3, cv.height - 8);
  }
  ctx.strokeStyle = P.grid;
  // Midway + anneaux
  const [mx, my] = proj(LAT0, LON0, cv, st);
  ctx.strokeStyle = P.ring;
  [100, 200, 300].forEach(r => { ctx.beginPath(); ctx.arc(mx, my, r * st.scale * pxnm(cv), 0, 7); ctx.stroke(); });
  ctx.fillStyle = P.midway; ctx.beginPath(); ctx.arc(mx, my, 4, 0, 7); ctx.fill();
  ctx.fillText('MIDWAY', mx + 7, my + 4);
  // épaves
  ctx.font = '12px Verdana';
  D.wrecks.forEach(w => {
    if (st.T >= w.t) {
      const [x, y] = proj(w.lat, w.lon, cv, st);
      ctx.fillStyle = P.wreck; ctx.fillText('✕', x - 4, y + 4); ctx.font = '9px Verdana';
      ctx.fillText(`${w.name} — coulé ${w.h.split(' ')[2]}`, x + 8, y + 3); ctx.font = '12px Verdana';
    }
  });
  // pistes
  D.entities.forEach(e => {
    const c = colors[e.side];
    if (st.showTrail) {
      ctx.strokeStyle = c; ctx.globalAlpha = .3; ctx.lineWidth = 1.5; ctx.beginPath(); let started = false;
      for (const p of e.track) {
        if (p.t > st.T) break; const [x, y] = proj(p.lat, p.lon, cv, st);
        started ? ctx.lineTo(x, y) : ctx.moveTo(x, y); started = true;
      }
      const cur = interp(e.track, st.T);
      if (cur && started) { const [x, y] = proj(cur.lat, cur.lon, cv, st); ctx.lineTo(x, y); }
      ctx.stroke(); ctx.globalAlpha = 1;
    }
    e.track.forEach((pt, pi) => {
      if (pt.t <= st.T) {
        const [wx, wy] = proj(pt.lat, pt.lon, cv, st);
        ctx.fillStyle = pt.cause ? c : '#999';
        ctx.save(); ctx.translate(wx, wy); ctx.rotate(Math.PI / 4); ctx.fillRect(-3, -3, 6, 6); ctx.restore();
        clickables.push({ x: wx, y: wy, ent: e.label, pt: pt, trk: e.track, idx: pi });
      }
    });
    if (isSunk(e.id, st.T, D)) return;            // coulé: seul le ✕ subsiste
    const p = interp(e.track, st.T); if (!p) return;
    const [x, y] = proj(p.lat, p.lon, cv, st);
    if (st.showHalo) {
      const hr = p.err * st.scale * pxnm(cv);
      ctx.fillStyle = c; ctx.globalAlpha = .07;
      ctx.beginPath(); ctx.arc(x, y, hr, 0, 7); ctx.fill(); ctx.globalAlpha = .35;
      ctx.strokeStyle = c; ctx.setLineDash([5, 5]);
      ctx.beginPath(); ctx.arc(x, y, hr, 0, 7); ctx.stroke();
      ctx.setLineDash([]); ctx.globalAlpha = 1;
      if (st.scale >= 1.8) { // étiquette de l'incertitude sur le bord du halo
        ctx.fillStyle = P.sub; ctx.font = '9px Verdana';
        ctx.fillText(`±${Math.round(p.err)} nm${p.stale ? ' (périmée)' : ''}`, x + hr * 0.71 + 3, y - hr * 0.71 - 3);
        ctx.font = '12px Verdana';
      }
    }
    const fire = D.fires.find(f => f.ent === e.id && st.T >= f.t0 && st.T < f.t1);
    if (fire) { // en feu: flamme vacillante, pas de flèche (stoppé/dérive)
      const fl = .6 + .4 * Math.sin(Date.now() / 110 + x);
      ctx.globalAlpha = fl; ctx.font = '14px Verdana'; ctx.fillText('🔥', x - 7, y + 5); ctx.globalAlpha = 1;
    } else if (p.route != null) { // en route: flèche orientée
      ctx.fillStyle = c; ctx.save(); ctx.translate(x, y); ctx.rotate(p.route * RAD);
      ctx.beginPath(); ctx.moveTo(0, -9); ctx.lineTo(5.5, 7); ctx.lineTo(0, 3.5); ctx.lineTo(-5.5, 7);
      ctx.closePath(); ctx.fill(); ctx.restore();
      if (p.stale) { ctx.strokeStyle = c; ctx.beginPath(); ctx.arc(x, y, 11, 0, 7); ctx.stroke(); }
    } else { ctx.fillStyle = c; ctx.beginPath(); ctx.arc(x, y, 5, 0, 7); ctx.fill(); }
    ctx.fillStyle = P.label; ctx.font = 'bold 11px Verdana';
    ctx.fillText(e.label + (fire ? ' (en feu)' : ''), x + 10, y + 1);
    if (e.sub) { ctx.fillStyle = P.sub; ctx.font = '9px Verdana'; ctx.fillText(e.sub, x + 10, y + 13); }
    ctx.font = '12px Verdana';
  });
  // waypoint sélectionné: surligner ses segments entrant/sortant
  if (st.selWp) {
    const selWp = st.selWp;
    const [sx, sy] = proj(selWp.pt.lat, selWp.pt.lon, cv, st);
    ctx.strokeStyle = '#ff7a00'; ctx.lineWidth = 2;
    ctx.beginPath(); ctx.arc(sx, sy, 9, 0, 7); ctx.stroke();
    if (selWp.idx > 0) { // segment entrant (fin, pointillé)
      const a = selWp.trk[selWp.idx - 1], [ax, ay] = proj(a.lat, a.lon, cv, st);
      ctx.setLineDash([4, 4]); ctx.lineWidth = 1.5;
      ctx.beginPath(); ctx.moveTo(ax, ay); ctx.lineTo(sx, sy); ctx.stroke(); ctx.setLineDash([]);
    }
    if (selWp.idx < selWp.trk.length - 1) { // segment sortant (épais + flèche)
      const b = selWp.trk[selWp.idx + 1], [bx2, by2] = proj(b.lat, b.lon, cv, st);
      ctx.lineWidth = 3;
      ctx.beginPath(); ctx.moveTo(sx, sy); ctx.lineTo(bx2, by2); ctx.stroke();
      const ang = Math.atan2(by2 - sy, bx2 - sx), mxp = (sx + bx2) / 2, myp = (sy + by2) / 2;
      ctx.fillStyle = '#ff7a00';
      ctx.save(); ctx.translate(mxp, myp); ctx.rotate(ang);
      ctx.beginPath(); ctx.moveTo(8, 0); ctx.lineTo(-5, -5); ctx.lineTo(-5, 5); ctx.closePath(); ctx.fill(); ctx.restore();
    }
    ctx.lineWidth = 1;
  }
  // repérages: "qui voit qui" — œil pulsant sur l'entité repérée
  D.spots.forEach(sp => {
    if (st.T >= sp.t - 2 && st.T <= sp.t + 12) {
      const p = posOf(sp.ent, st.T, D, entById); if (!p) return; const [x, y] = proj(p.lat, p.lon, cv, st);
      const ph = (Date.now() / 500) % 1;
      ctx.strokeStyle = '#e6a700'; ctx.globalAlpha = (1 - ph) * .8; ctx.lineWidth = 2;
      ctx.beginPath(); ctx.arc(x, y, 6 + ph * 18, 0, 7); ctx.stroke();
      ctx.globalAlpha = 1; ctx.lineWidth = 1;
      ctx.font = '12px Verdana'; ctx.fillText('👁', x - 6, y - 14);
      if (st.scale >= 1.3) {
        ctx.fillStyle = '#b07900'; ctx.font = '9px Verdana';
        ctx.fillText('repéré: ' + sp.s + '…', x + 14, y - 16); ctx.font = '12px Verdana';
      }
    }
  });
  // combats: pulsations sur la cible
  D.combats.forEach(cb => {
    if (st.T >= cb.t0 && st.T <= cb.t1) {
      const p = posOf(cb.ent, st.T, D, entById); if (!p) return; const [x, y] = proj(p.lat, p.lon, cv, st);
      const ph = (Date.now() / 650) % 1;
      [ph, (ph + 0.5) % 1].forEach(q => {
        ctx.strokeStyle = '#ff7a00'; ctx.globalAlpha = (1 - q) * .85; ctx.lineWidth = 2.5;
        ctx.beginPath(); ctx.arc(x, y, 7 + q * 26, 0, 7); ctx.stroke();
      });
      ctx.globalAlpha = 1; ctx.lineWidth = 1;
      ctx.fillStyle = '#ff7a00'; ctx.font = 'bold 12px Verdana'; ctx.fillText('✸', x - 5, y - 12);
      ctx.font = '12px Verdana';
    }
  });
  // raids — dénombrables au zoom: 1 point = 1 avion, attrition au point d'attaque
  if (st.showRaid) {
    D.raids.forEach(r => {
      const launching = r.tl != null && st.T >= r.tl && st.T < r.t0;
      if (launching || (st.T >= r.t0 && st.T <= r.t1)) {
        const f = launching ? 0 : (st.T - r.t0) / (r.t1 - r.t0);
        const lat = r.a[0] + f * (r.b[0] - r.a[0]), lon = unwrap(r.a[1]) + f * (unwrap(r.b[1]) - unwrap(r.a[1]));
        const [x, y] = proj(lat, lon, cv, st); const c = colors[r.side];
        ctx.strokeStyle = c; ctx.globalAlpha = .4;
        const [xa, ya] = proj(r.a[0], r.a[1], cv, st); ctx.setLineDash([2, 3]);
        ctx.beginPath(); ctx.moveTo(xa, ya); ctx.lineTo(x, y); ctx.stroke(); ctx.setLineDash([]); ctx.globalAlpha = 1;
        const after = r.ta != null && st.T >= r.ta;
        let n = after ? Math.max(0, r.n0 - r.lost) : r.n0;
        if (launching) n = Math.max(1, Math.round(r.n0 * (st.T - (r.tl as number)) / Math.max(1, r.t0 - (r.tl as number)))); // décollages en cours
        const par = r.par || 1;
        if (par > 1) n = Math.max(1, Math.round(n / par)); // éventail: l'effectif se répartit entre les lignes
        if (st.scale >= 2.2 && r.n0 > 0) {
          // formation en coin (V), 1 point/avion (paquets de 2 au-delà de 60)
          const pack = r.n0 > 60 ? 2 : 1, shown = Math.ceil(n / pack);
          const [xb, yb] = proj(r.b[0], r.b[1], cv, st);
          const ang = Math.atan2(yb - y, xb - x);
          ctx.save(); ctx.translate(x, y); ctx.rotate(ang + Math.PI / 2);
          ctx.fillStyle = c;
          for (let i = 0; i < shown; i++) {
            const row = Math.floor((-1 + Math.sqrt(1 + 8 * i)) / 2), k = i - row * (row + 1) / 2;
            const px = (k - row / 2) * 7, py = row * 6;
            ctx.beginPath(); ctx.arc(px, py, 2, 0, 7); ctx.fill();
          }
          // avions perdus: points gris qui s'estompent pendant 20 min après l'attaque
          if (after && r.lost > 0 && st.T <= (r.ta as number) + 20) {
            ctx.globalAlpha = Math.max(0, 1 - (st.T - (r.ta as number)) / 20) * .8; ctx.fillStyle = '#888';
            const lostShown = Math.ceil(r.lost / pack);
            for (let i = 0; i < lostShown; i++) {
              const row = Math.floor((-1 + Math.sqrt(1 + 8 * (i + shown))) / 2), k = (i + shown) - row * (row + 1) / 2;
              ctx.beginPath(); ctx.arc((k - row / 2) * 7, row * 6 + 9 + (st.T - (r.ta as number)) * 0.8, 2, 0, 7); ctx.fill();
            }
            ctx.globalAlpha = 1;
          }
          ctx.restore();
          ctx.fillStyle = P.label; ctx.font = 'bold 9px Verdana';
          ctx.fillText(`${par > 1 ? '≈' : ''}${n}${pack > 1 ? ' (1 pt = 2)' : ''} av.${par > 1 ? '/ligne' : ''}${launching ? ' — décollage…' : ''}`, x + 10, y + 4);
        } else {
          ctx.fillStyle = c; ctx.font = '13px Verdana'; ctx.fillText('✛', x - 5, y + 5);
          if (st.scale >= 1.3 && r.n0 > 0) {
            ctx.font = 'bold 9px Verdana'; ctx.fillStyle = P.label;
            ctx.fillText(`${par > 1 ? '≈' : ''}${n} av.${par > 1 ? '/ligne' : ''}${launching ? ' — décollage…' : ''}`, x + 9, y + 10);
          }
        }
        ctx.font = '9px Verdana'; ctx.fillStyle = P.sub;
        ctx.fillText(r.mid.replace(/MS-060[346]-/, ''), x + 8, y - 6);
        ctx.font = '12px Verdana';
      }
    });
  }

  // monde perçu
  if (st.showPercu) {
    D.contacts.forEach(c => {
      if (st.T >= c.t && st.T <= c.t + 180) {
        const [x, y] = proj(c.lat, c.lon, cv, st);
        ctx.strokeStyle = P.contact; ctx.setLineDash([3, 3]);
        ctx.beginPath(); ctx.arc(x, y, 12, 0, 7); ctx.stroke(); ctx.setLineDash([]);
        ctx.fillStyle = P.contact; ctx.font = '9px Verdana';
        ctx.fillText('contact rapporté: ' + c.s.slice(0, 40) + '…', x + 15, y); ctx.font = '12px Verdana';
      }
    });
  }
  // boussole
  const bx = cv.width - 52, by = 52, br = 30;
  ctx.strokeStyle = P.ring; ctx.fillStyle = P.bg;
  ctx.beginPath(); ctx.arc(bx, by, br, 0, 7); ctx.fill(); ctx.stroke();
  for (let a = 0; a < 360; a += 45) {
    const r1 = a % 90 ? br - 5 : br - 8, rad = (a - 90) * RAD;
    ctx.beginPath(); ctx.moveTo(bx + Math.cos(rad) * r1, by + Math.sin(rad) * r1);
    ctx.lineTo(bx + Math.cos(rad) * br, by + Math.sin(rad) * br); ctx.stroke();
  }
  ctx.fillStyle = '#d23b3b'; ctx.beginPath();
  ctx.moveTo(bx, by - br + 6); ctx.lineTo(bx - 5, by); ctx.lineTo(bx + 5, by); ctx.closePath(); ctx.fill();
  ctx.fillStyle = P.label; ctx.font = 'bold 10px Verdana'; ctx.textAlign = 'center';
  ctx.fillText('N', bx, by - br + 16); ctx.font = '9px Verdana';
  ctx.fillText('E', bx + br - 12, by + 3); ctx.fillText('S', bx, by + br - 8); ctx.fillText('O', bx - br + 12, by + 3);
  ctx.textAlign = 'left';

  return { clickables };
};
