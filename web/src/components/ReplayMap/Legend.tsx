import { useState } from 'react';
import { useLang } from '../../i18n/LanguageContext';

// Map legend — collapsed by default (a button expands it) so it doesn't cover
// the screen. Content branches on language (rich markup, kept inline).
export default function Legend() {
  const { lang, t } = useLang();
  const [open, setOpen] = useState(false);

  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        title={t('legend_show_title')}
        style={{
          position: 'absolute', bottom: 10, left: 10, zIndex: 6,
          background: 'var(--bg)', color: 'var(--txt)', border: '1px solid var(--bord)',
          borderRadius: 4, padding: '3px 10px', cursor: 'pointer', fontSize: 11,
        }}
      >
        {t('legend_show')}
      </button>
    );
  }

  const close = (
    <span
      onClick={() => setOpen(false)}
      style={{ float: 'right', cursor: 'pointer', fontWeight: 'bold', padding: '0 4px' }}
      title={t('legend_close_title')}
    >
      ✕
    </span>
  );

  if (lang === 'en') {
    return (
      <div id="legend">
        {close}
        <span className="sw" style={{ background: '#1f6fce' }} />US Navy &nbsp;
        <span className="sw" style={{ background: '#d23b3b' }} />Imperial Navy<br />
        <b>Task Force (TF)</b> = US operational group built around carriers;<br />
        <b>Kidō Butai</b> = Japanese carrier strike force (composition under the name)<br />
        ▲ ship/group under way (tip = heading) · 🔥 on fire/stopped · ✕ sunk<br />
        ◉ orange pulse = combat in progress · 👁 yellow pulse = unit spotted by the enemy<br />
        ✛ raid in flight (strength shown when zoomed; <b>1 dot = 1 aircraft</b> at zoom ≥ ×2.2)<br />
        losses applied at the point of attack (approx.: includes ditchings on the way back)<br />
        ◆ waypoint — <b>click</b>: rationale for the heading<br />
        ◌ halo = position error (nm); it <b>grows</b> as the track goes stale (+5 nm/h)<br />
        Zoom: wheel or slider · Rings 100/200/300 nm · dashed = antimeridian
      </div>
    );
  }

  return (
    <div id="legend">
      {close}
      <span className="sw" style={{ background: '#1f6fce' }} />US Navy &nbsp;
      <span className="sw" style={{ background: '#d23b3b' }} />Marine impériale<br />
      <b>Task Force (TF)</b> = groupe opérationnel US autour de porte-avions;<br />
      <b>Kidō Butai</b> = force de frappe des PA japonais (composition sous le nom)<br />
      ▲ navire/groupe en route (pointe = direction) · 🔥 en feu/stoppé · ✕ coulé<br />
      ◉ pulsation orange = combat en cours · 👁 pulsation jaune = unité repérée par l'ennemi<br />
      ✛ raid en vol (effectif affiché au zoom; <b>1 point = 1 avion</b> au zoom ≥ ×2,2)<br />
      pertes appliquées au point d'attaque (approx.: inclut les amerrissages au retour)<br />
      ◆ waypoint — <b>cliquer</b> : justification du cap<br />
      ◌ halo = erreur de position (nm); il <b>grossit</b> quand la piste est périmée (+5 nm/h)<br />
      Zoom: molette ou curseur · Anneaux 100/200/300 nm · pointillé = antiméridien
    </div>
  );
}
