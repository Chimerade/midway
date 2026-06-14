import { useCallback, useRef, useState } from 'react';
import { useReplayData } from '../data/useReplayData';
import { useTheme } from '../theme/ThemeContext';
import { useLang } from '../i18n/LanguageContext';
import { fmtFull } from '../i18n/dates';
import ReplayMap, { type ReplayControls } from '../components/ReplayMap/ReplayMap';
import Controls from '../components/ReplayMap/Controls';
import Legend from '../components/ReplayMap/Legend';
import Feed from '../components/ReplayMap/Feed';
import Roster from '../components/ReplayMap/Roster';

export default function Carte() {
  const { data, error } = useReplayData();
  const { theme } = useTheme();
  const { lang, t } = useLang();
  const [c, setC] = useState<ReplayControls>({ playing: false, speedExp: 2.778, scale: 1, showHalo: true, showTrail: true, showRaid: true, showPercu: false, showFeed: false, showRoster: false, theme });
  const [T, setT] = useState(0);
  const seekRef = useRef<((t: number) => void) | null>(null);
  const set = (p: Partial<ReplayControls>) => setC((s) => ({ ...s, ...p }));
  const onScaleChange = useCallback((s: number) => setC((prev) => ({ ...prev, scale: s })), []);
  const onSeek = useCallback((t: number) => { seekRef.current?.(t); setT(t); }, []);

  if (error) return <div className="page">{t('load_error')} : {error}</div>;
  if (!data) return <div className="page">{t('loading')}</div>;

  const controls: ReplayControls = { ...c, theme };
  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 46px)' }}>
      <Controls c={controls} set={set} clock={fmtFull(T, lang)} T={T} tmin={data.tmin} tmax={data.tmax} onSeek={onSeek} />
      <div style={{ flex: 1, display: 'flex', minHeight: 0 }}>
        <div style={{ flex: 1, position: 'relative' }}>
          <ReplayMap data={data} controls={controls} seekRef={seekRef} onClock={setT} onScaleChange={onScaleChange} />
          <Legend />
        </div>
        {controls.showFeed && <Feed events={data.events} T={T} onSeek={onSeek} />}
        {controls.showRoster && <Roster roster={data.roster} T={T} onSeek={onSeek} />}
      </div>
    </div>
  );
}
