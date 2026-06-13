import { useChronologie } from '../data/useChronologie';

export function fmtJour(t: number): string {
  const d = 3 + Math.floor(t / 1440);
  const mins = ((t % 1440) + 1440) % 1440;
  const h = Math.floor(mins / 60), m = mins % 60;
  const pad = (n: number) => String(n).padStart(2, '0');
  return `${d} juin — ${pad(h)}:${pad(m)}`;
}

export default function Chronologie() {
  const events = useChronologie();
  if (!events) return <div className="page">Chargement…</div>;
  return (
    <div className="page">
      <h1>Chronologie</h1>
      <ul style={{ listStyle: 'none', padding: 0 }}>
        {events.map((e, i) => (
          <li key={i} style={{ borderLeft: `3px solid ${e.side === 'IJN' ? '#d23b3b' : e.side === 'USN' ? '#1f6fce' : 'var(--bord)'}`, padding: '4px 8px', marginBottom: 4 }}>
            <span style={{ color: 'var(--accent)', fontFamily: 'monospace' }}>{fmtJour(e.t)}</span>
            {e.u ? ` ±${e.u}'` : ''} — {e.s}
          </li>
        ))}
      </ul>
    </div>
  );
}
