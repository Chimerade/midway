import { useEffect, useRef, type RefObject } from 'react';
import type { ReplayData } from '../../types/replay';
import type { Lang } from '../../i18n/strings';
import type { RenderState, Clickable } from './types';
import { draw, pxnm, cameraTarget, LAT0, LON0, RAD, unwrap } from './render';

export interface ReplayControls {
  playing: boolean; speedExp: number; scale: number;
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  showFeed: boolean; showRoster: boolean;
  showClouds: boolean; follow: boolean;
  theme: 'light' | 'dark'; lang: Lang;
}

export default function ReplayMap({ data, controls, seekRef, onClock, onScaleChange, onSelectRaid, onFollowChange }: {
  data: ReplayData; controls: ReplayControls;
  seekRef?: RefObject<((t: number) => void) | null>;
  onClock: (t: number) => void; onScaleChange: (update: (prev: number) => number) => void;
  onSelectRaid: (mid: string | null) => void;
  onFollowChange?: (follow: boolean) => void;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const selRaidRef = useRef<string | null>(null);
  const stRef = useRef<RenderState>({
    T: data.tmin, scale: controls.scale, panX: 0, panY: -120, theme: controls.theme, lang: controls.lang,
    showHalo: true, showTrail: true, showRaid: true, showPercu: false, selWp: null,
  });
  const ctrlRef = useRef(controls);
  const clickRef = useRef<Clickable[]>([]);
  const dragRef = useRef(false);

  // Sync latest controls into the ref + expose an imperative seek for the parent's
  // time slider. Done after each render (effect) rather than during render.
  useEffect(() => {
    ctrlRef.current = controls;
    if (seekRef) seekRef.current = (t: number) => { stRef.current.T = t; };
  });

  // Boucle d'animation — un seul effet, jamais recréé (cf. generer_carte.py:539-547)
  useEffect(() => {
    const cv = canvasRef.current!, ctx = cv.getContext('2d')!;
    const motion = window.matchMedia('(prefers-reduced-motion: reduce)');
    let raf = 0, last = performance.now();
    const tick = () => {
      const now = performance.now(), dt = Math.min(0.1, (now - last) / 1000); last = now;
      const st = stRef.current, c = ctrlRef.current;
      st.scale = c.scale; st.theme = c.theme; st.lang = c.lang;
      st.showHalo = c.showHalo; st.showTrail = c.showTrail; st.showRaid = c.showRaid; st.showPercu = c.showPercu;
      st.showClouds = c.showClouds; st.reduced = motion.matches;
      if (c.playing) st.T = Math.min(data.tmax, st.T + Math.pow(10, c.speedExp) * dt / 60);
      // caméra : glisse vers le centre de l'action (amorti exponentiel, ~0,9 s)
      if (c.follow && !dragRef.current) {
        const p = cameraTarget(data, st.T);
        if (p) {
          const tx = -(unwrap(p.lon) - LON0) * 60 * Math.cos(LAT0 * RAD), ty = -(p.lat - LAT0) * 60;
          const a = motion.matches ? 1 : 1 - Math.exp(-dt / 0.9);
          st.panX += (tx - st.panX) * a; st.panY += (ty - st.panY) * a;
        }
      }
      clickRef.current = draw(ctx, cv, data, st).clickables;
      onClock(st.T);
      raf = requestAnimationFrame(tick);
    };
    raf = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(raf);
  }, [data, onClock]);

  // Zoom molette (cf. generer_carte.py:569-570)
  useEffect(() => {
    const cv = canvasRef.current!;
    const onWheel = (e: WheelEvent) => {
      e.preventDefault();
      // Facteur proportionnel à l'amplitude du geste : fluide au trackpad (petits deltaY),
      // franc à la molette (gros deltaY). On passe par l'état React (updater) plutôt que
      // par stRef, que la boucle d'animation réécrit chaque frame — sinon le zoom se fige.
      const factor = Math.pow(1.0015, -e.deltaY);
      onScaleChange((prev) => Math.max(0.4, Math.min(30, prev * factor)));
    };
    cv.addEventListener('wheel', onWheel, { passive: false });
    return () => cv.removeEventListener('wheel', onWheel);
  }, [onScaleChange]);

  // Pan par drag (cf. generer_carte.py:571-606) — reprendre la main coupe le suivi de l'action
  useEffect(() => {
    const cv = canvasRef.current!;
    let drag: [number, number] | null = null, dist = 0;
    const down = (e: MouseEvent) => { drag = [e.clientX, e.clientY]; dist = 0; };
    const move = (e: MouseEvent) => {
      if (!drag) return;
      dist += Math.abs(e.clientX - drag[0]) + Math.abs(e.clientY - drag[1]);
      if (dist >= 5 && !dragRef.current) {
        dragRef.current = true;
        if (ctrlRef.current.follow) onFollowChange?.(false);
      }
      const st = stRef.current, k = st.scale * pxnm(cv);  // pixels CSS par nm
      st.panX += (e.clientX - drag[0]) / k;
      st.panY -= (e.clientY - drag[1]) / k;
      drag = [e.clientX, e.clientY];
    };
    const up = (e: MouseEvent) => {
      if (drag && dist < 5) {
        const r = cv.getBoundingClientRect(), mx = e.clientX - r.left, my = e.clientY - r.top;
        const found: Clickable[] = []; let bd = 14;
        clickRef.current.forEach((cl) => { const d = Math.hypot(cl.x - mx, cl.y - my); if (d < bd) { bd = d; found[0] = cl; } });
        const b = found[0] ?? null;
        if (b && b.mid) { // clic sur un raid → encart mission (re-clic = ferme)
          const next = selRaidRef.current === b.mid ? null : b.mid;
          selRaidRef.current = next; onSelectRaid(next);
          stRef.current.selWp = null;
        } else { // clic sur un waypoint, ou ailleurs
          const cur = stRef.current.selWp;
          const same = b && cur && cur.trk === b.trk && cur.idx === b.idx; // re-clic = désélection
          stRef.current.selWp = b && b.pt && !same ? { pt: b.pt, trk: b.trk, idx: b.idx } : null;
          if (selRaidRef.current) { selRaidRef.current = null; onSelectRaid(null); }
        }
      }
      drag = null; dragRef.current = false;
    };
    cv.addEventListener('mousedown', down); window.addEventListener('mousemove', move); window.addEventListener('mouseup', up);
    return () => { cv.removeEventListener('mousedown', down); window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
  }, [onSelectRaid, onFollowChange]);

  return <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%', cursor: 'grab' }} />;
}
