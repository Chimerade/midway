import { useState } from 'react';

// Légende de la carte — repliée par défaut (un bouton la déplie) pour ne pas
// empiéter sur l'écran. Reprend le contenu de l'ancien #legend.
export default function Legend() {
  const [open, setOpen] = useState(false);
  if (!open) {
    return (
      <button
        onClick={() => setOpen(true)}
        title="afficher la légende"
        style={{
          position: 'absolute', bottom: 10, left: 10, zIndex: 6,
          background: 'var(--bg)', color: 'var(--txt)', border: '1px solid var(--bord)',
          borderRadius: 4, padding: '3px 10px', cursor: 'pointer', fontSize: 11,
        }}
      >
        ℹ légende
      </button>
    );
  }
  return (
    <div id="legend">
      <span
        onClick={() => setOpen(false)}
        style={{ float: 'right', cursor: 'pointer', fontWeight: 'bold', padding: '0 4px' }}
        title="fermer"
      >
        ✕
      </span>
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
