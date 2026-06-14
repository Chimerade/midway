import { useEffect, useRef } from 'react';
import type { GameEvent } from '../../types/replay';

// Étiquette temporelle d'un événement: "HH:MM J{jour}" (GMT−12), comme l'ancien fil.
function fmtFeed(t: number): string {
  const d = 3 + Math.floor(t / 1440);
  const mins = ((t % 1440) + 1440) % 1440;
  const h = Math.floor(mins / 60), m = mins % 60;
  const p = (n: number) => String(n).padStart(2, '0');
  return `${p(h)}:${p(m)} J${d}`;
}

// Fil d'événements optionnel sur la carte: cliquer un événement saute à son instant.
// Reprend le comportement de l'ancien #feed (événement courant surligné, auto-scroll).
export default function Feed({ events, T, onSeek }: {
  events: GameEvent[]; T: number; onSeek: (t: number) => void;
}) {
  // événement courant = dernier événement passé (ou tout proche)
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
            title="cliquer: aller à cet instant"
            onClick={() => onSeek(e.t)}
          >
            <span className="t">{fmtFeed(e.t)}</span>
            {e.u ? ` ±${e.u}'` : ''} — {e.s}
          </div>
        );
      })}
    </div>
  );
}
