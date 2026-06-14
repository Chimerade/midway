import { useState } from 'react';
import type { RosterShip } from '../../types/replay';
import { useLang } from '../../i18n/LanguageContext';

// Panneau latéral optionnel: l'ordre de bataille des deux flottes avec photo
// officielle et état (coulé / en feu / touché / opérationnel) à l'instant T.
type Status = 'sunk' | 'fire' | 'hit' | 'ok';

function statusAt(s: RosterShip, T: number): Status {
  if (s.sunk != null && T >= s.sunk) return 'sunk';
  if (s.fires.some(([a, b]) => T >= a && T <= b)) return 'fire';
  if (s.hits.length && T >= s.hits[0]) return 'hit';
  return 'ok';
}

// Premier instant où l'état du navire change (pour le clic = aller-à).
function firstEvent(s: RosterShip): number | null {
  const ts = [...s.hits, ...s.fires.map((f) => f[0]), ...(s.sunk != null ? [s.sunk] : [])];
  return ts.length ? Math.min(...ts) : null;
}

const BADGE = '🩸', FIRE = '🔥', SKULL = '✖';

function ShipCard({ s, T, onSeek, label }: {
  s: RosterShip; T: number; onSeek: (t: number) => void;
  label: (st: Status) => string;
}) {
  const [noPhoto, setNoPhoto] = useState(false);
  const st = statusAt(s, T);
  const jump = firstEvent(s);
  const icon = st === 'sunk' ? SKULL : st === 'fire' ? FIRE : st === 'hit' ? BADGE : '';
  return (
    <div
      className={`ship ${s.side} st-${st}`}
      title={`${s.name}${s.cls ? ' — ' + s.cls : ''}\n${s.fate}${jump != null ? '\n(clic: aller à cet instant)' : ''}`}
      onClick={() => { if (jump != null) onSeek(jump); }}
      style={{ cursor: jump != null ? 'pointer' : 'default' }}
    >
      <div className="ship-img">
        {noPhoto
          ? <div className="silhouette">{s.type}</div>
          : <img src={`ships/${s.photo}`} alt={s.name} loading="lazy" onError={() => setNoPhoto(true)} />}
        {icon && <span className={`badge st-${st}`}>{icon} {label(st)}</span>}
      </div>
      <div className="ship-name">{s.name}</div>
      <div className="ship-sub">{s.type}{s.cls ? ` · ${s.cls}` : ''}</div>
    </div>
  );
}

export default function Roster({ roster, T, onSeek }: {
  roster: RosterShip[]; T: number; onSeek: (t: number) => void;
}) {
  const { t } = useLang();
  const label = (st: Status) =>
    st === 'sunk' ? t('roster_sunk') : st === 'fire' ? t('roster_fire')
    : st === 'hit' ? t('roster_hit') : t('roster_ok');
  const ijn = roster.filter((s) => s.side === 'IJN');
  const usn = roster.filter((s) => s.side === 'USN');
  const section = (title: string, ships: RosterShip[]) => (
    <>
      <div className="roster-head">{title}</div>
      <div className="roster-grid">
        {ships.map((s) => <ShipCard key={s.id} s={s} T={T} onSeek={onSeek} label={label} />)}
      </div>
    </>
  );
  return (
    <div id="roster">
      {section(t('roster_ijn'), ijn)}
      {section(t('roster_usn'), usn)}
      <div className="roster-credit">{t('roster_credit')}</div>
    </div>
  );
}
