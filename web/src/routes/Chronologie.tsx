import { useChronologie } from '../data/useChronologie';
import { useLang } from '../i18n/LanguageContext';
import { fmtDay } from '../i18n/dates';

export default function Chronologie() {
  const events = useChronologie();
  const { lang, t } = useLang();
  if (!events) return <div className="page">{t('loading')}</div>;
  return (
    <div className="page">
      <h1>{t('chrono_title')}</h1>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {events.map((e, i) => (
          <li key={i} style={{ borderLeft: `3px solid ${e.side === 'IJN' ? '#d23b3b' : e.side === 'USN' ? '#1f6fce' : 'var(--bord)'}`, padding: '4px 8px', marginBottom: 4 }}>
            <span style={{ color: 'var(--accent)', fontFamily: 'monospace' }}>{fmtDay(e.t, lang)}</span>
            {e.u ? ` ±${e.u}'` : ''} — {e.s}
          </li>
        ))}
      </ul>
    </div>
  );
}
