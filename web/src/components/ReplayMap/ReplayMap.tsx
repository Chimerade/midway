import { useEffect, useRef, type RefObject } from 'react';
import type { ReplayData } from '../../types/replay';
import type { RenderState, Clickable } from './types';
import { draw } from './render';

export interface ReplayControls {
  playing: boolean; speedExp: number; scale: number;
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  theme: 'light' | 'dark';
}

export default function ReplayMap({ data, controls, seekRef, onClock, onScaleChange }: {
  data: ReplayData; controls: ReplayControls;
  seekRef?: RefObject<((t: number) => void) | null>;
  onClock: (t: number) => void; onScaleChange: (s: number) => void;
}) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const stRef = useRef<RenderState>({
    T: data.tmin, scale: controls.scale, panX: 0, panY: -120, theme: controls.theme,
    showHalo: true, showTrail: true, showRaid: true, showPercu: false, selWp: null,
  });
  const ctrlRef = useRef(controls);
  const clickRef = useRef<Clickable[]>([]);

  // Sync latest controls into the ref + expose an imperative seek for the parent's
  // time slider. Done after each render (effect) rather than during render.
  useEffect(() => {
    ctrlRef.current = controls;
    if (seekRef) seekRef.current = (t: number) => { stRef.current.T = t; };
  });

  // Boucle d'animation — un seul effet, jamais recréé (cf. generer_carte.py:539-547)
  useEffect(() => {
    const cv = canvasRef.current!, ctx = cv.getContext('2d')!;
    let raf = 0, last = performance.now();
    const tick = () => {
      const now = performance.now(), dt = (now - last) / 1000; last = now;
      const st = stRef.current, c = ctrlRef.current;
      st.scale = c.scale; st.theme = c.theme;
      st.showHalo = c.showHalo; st.showTrail = c.showTrail; st.showRaid = c.showRaid; st.showPercu = c.showPercu;
      if (c.playing) st.T = Math.min(data.tmax, st.T + Math.pow(10, c.speedExp) * dt / 60);
      cv.width = cv.parentElement!.clientWidth; cv.height = cv.parentElement!.clientHeight;
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
      const s = Math.max(0.4, Math.min(10, stRef.current.scale * (e.deltaY < 0 ? 1.1 : 0.9)));
      stRef.current.scale = s; onScaleChange(s);
    };
    cv.addEventListener('wheel', onWheel, { passive: false });
    return () => cv.removeEventListener('wheel', onWheel);
  }, [onScaleChange]);

  // Pan par drag (cf. generer_carte.py:571-606)
  useEffect(() => {
    const cv = canvasRef.current!;
    let drag: [number, number] | null = null, dist = 0;
    const down = (e: MouseEvent) => { drag = [e.clientX, e.clientY]; dist = 0; };
    const move = (e: MouseEvent) => {
      if (!drag) return;
      dist += Math.abs(e.clientX - drag[0]) + Math.abs(e.clientY - drag[1]);
      const st = stRef.current, pxnm = Math.min(cv.width, cv.height) / 900;
      st.panX += (e.clientX - drag[0]) / (st.scale * pxnm);
      st.panY -= (e.clientY - drag[1]) / (st.scale * pxnm);
      drag = [e.clientX, e.clientY];
    };
    const up = (e: MouseEvent) => {
      if (drag && dist < 5) {
        const r = cv.getBoundingClientRect(), mx = e.clientX - r.left, my = e.clientY - r.top;
        const found: Clickable[] = []; let bd = 14;
        clickRef.current.forEach((cl) => { const d = Math.hypot(cl.x - mx, cl.y - my); if (d < bd) { bd = d; found[0] = cl; } });
        const b = found[0] ?? null; stRef.current.selWp = b ? { pt: b.pt, trk: b.trk, idx: b.idx } : null;
      }
      drag = null;
    };
    cv.addEventListener('mousedown', down); window.addEventListener('mousemove', move); window.addEventListener('mouseup', up);
    return () => { cv.removeEventListener('mousedown', down); window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
  }, []);

  return <canvas ref={canvasRef} style={{ position: 'absolute', inset: 0, width: '100%', height: '100%' }} />;
}
