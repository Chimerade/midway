import { useCallback, useRef, useState } from 'react';
import { useReplayData } from '../data/useReplayData';
import { useTheme } from '../theme/ThemeContext';
import ReplayMap, { type ReplayControls } from '../components/ReplayMap/ReplayMap';
import Controls from '../components/ReplayMap/Controls';

function fmt(t: number) {
  t = Math.floor(t);
  const d = 3 + Math.floor(t / 1440), mins = ((t % 1440) + 1440) % 1440;
  const h = Math.floor(mins / 60), m = mins % 60, p = (n: number) => String(n).padStart(2, '0');
  return `${d} juin 1942 — ${p(h)}:${p(m)} (GMT−12)`;
}

export default function Carte() {
  const { data, error } = useReplayData();
  const { theme } = useTheme();
  const [c, setC] = useState<ReplayControls>({ playing: false, speedExp: 2.778, scale: 1, showHalo: true, showTrail: true, showRaid: true, showPercu: false, theme });
  const [T, setT] = useState(0);
  const seekRef = useRef<((t: number) => void) | null>(null);
  const set = (p: Partial<ReplayControls>) => setC((s) => ({ ...s, ...p }));
  const onScaleChange = useCallback((s: number) => setC((prev) => ({ ...prev, scale: s })), []);
  const onSeek = useCallback((t: number) => { seekRef.current?.(t); setT(t); }, []);

  if (error) return <div className="page">Erreur de chargement : {error}</div>;
  if (!data) return <div className="page">Chargement…</div>;

  const controls: ReplayControls = { ...c, theme };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 46px)' }}>
      <Controls c={controls} set={set} clock={fmt(T)} T={T || data.tmin} tmin={data.tmin} tmax={data.tmax} onSeek={onSeek} />
      <div style={{ flex: 1, position: 'relative' }}>
        <ReplayMap data={data} controls={controls} seekRef={seekRef} onClock={setT} onScaleChange={onScaleChange} />
      </div>
    </div>
  );
}
