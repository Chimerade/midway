import type { ReplayControls } from './ReplayMap';
import { useLang } from '../../i18n/LanguageContext';

export default function Controls({ c, set, clock, onSeek, tmin, tmax, T }: {
  c: ReplayControls; set: (p: Partial<ReplayControls>) => void;
  clock: string; onSeek: (t: number) => void; tmin: number; tmax: number; T: number;
}) {
  const { t } = useLang();
  const speed = Math.pow(10, c.speedExp);
  return (
    <div style={{ display: 'flex', gap: 12, alignItems: 'center', flexWrap: 'wrap', padding: '8px 14px', background: 'var(--panel)', borderBottom: '1px solid var(--bord)' }}>
      <button onClick={() => set({ playing: !c.playing })}>{c.playing ? t('pause') : t('play')}</button>
      <span style={{ color: 'var(--accent)', fontFamily: 'monospace', minWidth: 230 }}>{clock}</span>
      <span style={{ fontSize: 11 }}>{t('speed')}</span>
      <input type="range" min={1} max={3.56} step={0.01} value={c.speedExp} onChange={(e) => set({ speedExp: +e.target.value })} />
      <span style={{ fontFamily: 'monospace', minWidth: 50 }}>×{speed < 100 ? speed.toFixed(0) : Math.round(speed / 10) * 10}</span>
      <input style={{ flex: 1, minWidth: 160 }} type="range" min={tmin} max={tmax} step={1} value={Math.round(T)} onChange={(e) => onSeek(+e.target.value)} />
      <span style={{ fontSize: 11 }}>{t('zoom')}</span>
      <input type="range" min={0.4} max={10} step={0.1} value={c.scale} onChange={(e) => set({ scale: +e.target.value })} />
      <label><input type="checkbox" checked={c.showHalo} onChange={(e) => set({ showHalo: e.target.checked })} /> {t('cb_halos')}</label>
      <label><input type="checkbox" checked={c.showTrail} onChange={(e) => set({ showTrail: e.target.checked })} /> {t('cb_trails')}</label>
      <label><input type="checkbox" checked={c.showRaid} onChange={(e) => set({ showRaid: e.target.checked })} /> {t('cb_raids')}</label>
      <label><input type="checkbox" checked={c.showPercu} onChange={(e) => set({ showPercu: e.target.checked })} /> {t('cb_perceived')}</label>
      <label><input type="checkbox" checked={c.showFeed} onChange={(e) => set({ showFeed: e.target.checked })} /> {t('cb_chronology')}</label>
      <label><input type="checkbox" checked={c.showRoster} onChange={(e) => set({ showRoster: e.target.checked })} /> {t('cb_roster')}</label>
    </div>
  );
}
