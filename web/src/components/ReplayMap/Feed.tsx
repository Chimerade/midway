import { useEffect, useRef } from 'react';
import type { GameEvent } from '../../types/replay';
import { useLang } from '../../i18n/LanguageContext';
import { fmtFeed } from '../../i18n/dates';

// Optional event feed on the map: clicking an event seeks to that moment.
// Mirrors the old #feed (current event highlighted, auto-scrolled).
export default function Feed({ events, T, onSeek }: {
  events: GameEvent[]; T: number; onSeek: (t: number) => void;
}) {
  const { lang, t } = useLang();

  // current event = last event already passed (or very close)
  let cur = -1;
  for (let i = 0; i < events.length; i++) {
    if (events[i].t <= T + 1) cur = i; else break;
  }

  const curRef = useRef<HTMLDivElement>(null);
  const lastCur = useRef(-1);
  useEffect(() => {
    if (cur !== lastCur.current) {
      lastCur.current = cur;
      curRef.current?.scrollIntoView({ block: 'center', behavior: 'smooth' });
    }
  }, [cur]);

  return (
    <div id="feed">
      {events.map((e, i) => {
        const isCur = i === cur || Math.abs(e.t - T) <= 15;
        const isPast = e.t < T - 60 && i !== cur;
        const cls = `ev ${e.side}${isCur ? ' cur' : ''}${isPast ? ' past' : ''}`;
        return (
          <div
            key={i}
            ref={i === cur ? curRef : undefined}
            className={cls}
            title={t('feed_click_title')}
            onClick={() => onSeek(e.t)}
          >
            <span className="t">{fmtFeed(e.t, lang)}</span>
            {e.u ? ` ±${e.u}'` : ''} — {e.s}
          </div>
        );
      })}
    </div>
  );
}
