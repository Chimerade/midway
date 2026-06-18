import type { Mission } from '../../types/replay';
import { useLang } from '../../i18n/LanguageContext';
import type { StringKey } from '../../i18n/strings';
import { raidPhaseKey, PHASE_LABEL } from './phase';

// Encart affiché au clic sur une flotte aérienne (raid) : nom, type, provenance,
// avions engagés (par modèle) et objectif. Re-clic sur le raid ou la croix = ferme.
export default function RaidCard({ mid, mission, side, T, ta, onClose }: {
  mid: string; mission: Mission; side: 'IJN' | 'USN';
  T: number; ta: number | null; onClose: () => void;
}) {
  const { t, lang } = useLang();
  const typeLabel = mission.type ? t(`mt_${mission.type}` as StringKey) : '';
  const title = [mission.origin, typeLabel].filter(Boolean).join(' — ') || mid;

  // État à l'instant T : avant l'attaque tout l'effectif vole ; après, les survivants.
  const attacked = ta != null && T >= ta;
  const inFlight = attacked ? Math.max(0, mission.committed - mission.lost) : mission.committed;
  const phase = PHASE_LABEL[lang][raidPhaseKey(ta, T)];

  return (
    <div id="raidcard">
      <div className="rc-h">
        <span className="rc-title">{title}</span>
        <button className="rc-x" title={t('raid_close_title')} onClick={onClose}>×</button>
      </div>
      <div className="rc-sub">{mid} · {side}</div>

      {mission.origin && (
        <div className="rc-row"><span className="rc-k">{t('raid_origin')} :</span> {mission.origin}</div>
      )}

      <div className="rc-row"><span className="rc-k">{t('raid_phase')} :</span> {phase}</div>

      {mission.committed > 0 && (
        <div className="rc-row"><span className="rc-k">{t('raid_inflight')} :</span> {inFlight} {t('raid_planes')}</div>
      )}

      {mission.aircraft.length > 0 && (
        <div className="rc-row">
          <span className="rc-k">{t('raid_aircraft')} :</span>
          {mission.aircraft.map((a, i) => (
            <div className="rc-ac" key={i}>{a.n}× {a.type}</div>
          ))}
        </div>
      )}

      {mission.target && (
        <div className="rc-row"><span className="rc-k">{t('raid_target')} :</span> {mission.target}</div>
      )}

      {attacked && mission.lost > 0 && (
        <div className="rc-row"><span className="rc-k">{t('raid_losses')} :</span> {mission.lost} {t('raid_planes')}</div>
      )}
    </div>
  );
}
