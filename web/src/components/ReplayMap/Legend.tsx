import { useState, type ReactNode } from 'react';
import { useLang } from '../../i18n/LanguageContext';

// Légende de la carte — repliée par défaut. Chaque pictogramme reprend le dessin
// du moteur de rendu (mêmes couleurs, mêmes formes).

const Svg = ({ children }: { children: ReactNode }) => (
  <svg width="26" height="16" viewBox="0 0 26 16" aria-hidden="true" style={{ flex: 'none' }}>{children}</svg>
);

const ICONS: Record<string, ReactNode> = {
  carriers: (
    <Svg>
      <rect x="1" y="2.5" width="11" height="4" rx="1.6" fill="#4a5866" /><rect x="9" y="1.5" width="2" height="2" fill="#2a2e34" />
      <rect x="14" y="9.5" width="11" height="4" rx="1.6" fill="#96805a" /><circle cx="22.4" cy="11.5" r="1" fill="#b02c26" />
    </Svg>
  ),
  escort: (
    <Svg>
      <circle cx="13" cy="8" r="6" fill="none" stroke="#8fa3bd" strokeDasharray="1 2.6" strokeWidth="1.6" />
      <rect x="9" y="6.5" width="8" height="3" rx="1.4" fill="#4a5866" />
    </Svg>
  ),
  wake: (
    <Svg>
      <path d="M3 8 L23 2 M3 8 L23 14" stroke="#e6f1f8" strokeWidth="1.1" opacity=".75" fill="none" />
      <path d="M3 8 H18" stroke="#f4f9fb" strokeWidth="2.2" opacity=".85" />
      <rect x="0" y="6.5" width="5" height="3" rx="1.2" fill="#4a5866" />
    </Svg>
  ),
  planes: (
    <Svg>
      {[[13, 4], [8, 11], [18, 11]].map(([x, y]) => (
        <path key={`${x}${y}`} d={`M${x} ${y - 3.5} V${y + 3.5} M${x - 3.5} ${y - 0.5} H${x + 3.5} M${x - 1.4} ${y + 3} H${x + 1.4}`} stroke="#9aaaba" strokeWidth="1.4" />
      ))}
    </Svg>
  ),
  shot: (
    <Svg>
      <path d="M4 4 C14 0 20 6 16 10 C13 13 9 10 12 8" stroke="#2b2826" strokeWidth="1.6" fill="none" />
      <circle cx="12" cy="8" r="2.2" fill="#ff9a3c" />
    </Svg>
  ),
  combat: (
    <Svg>
      <circle cx="7" cy="6" r="3" fill="#2a2a2c" opacity=".85" /><circle cx="18" cy="10" r="3.6" fill="#2a2a2c" opacity=".7" />
      <path d="M12 9 L22 3 M12 9 L4 13" stroke="#ffc46e" strokeWidth="1.3" />
      <circle cx="13" cy="5" r="1.8" fill="#fff1c8" />
    </Svg>
  ),
  hit: (
    <Svg>
      <circle cx="13" cy="8" r="6.5" fill="#ff8a2a" opacity=".35" /><circle cx="13" cy="8" r="3.4" fill="#ffd27a" />
      <circle cx="13" cy="8" r="7.3" fill="none" stroke="#f0f8ff" strokeWidth=".8" opacity=".7" />
    </Svg>
  ),
  fire: (
    <Svg>
      {[[16, 7, 2.5], [19.5, 6, 3.2], [23, 5, 3.8]].map(([x, y, r]) => <circle key={x} cx={x} cy={y} r={r} fill="#1e1c1c" opacity=".55" />)}
      <circle cx="9" cy="9" r="5" fill="#ff7a2a" opacity=".45" /><circle cx="9" cy="9" r="2.4" fill="#ffd27a" />
    </Svg>
  ),
  wreck: (
    <Svg>
      <ellipse cx="15" cy="9" rx="9" ry="4" fill="#0b0d12" opacity=".55" />
      <path d="M9 4 L15 10 M15 4 L9 10" stroke="#d6e2ee" strokeWidth="1.6" />
    </Svg>
  ),
  radar: (
    <Svg>
      <circle cx="9" cy="8" r="7" fill="none" stroke="#5ef0c4" strokeDasharray="2 2" opacity=".5" />
      <path d="M9 8 L16 8 A7 7 0 0 0 13.9 3 Z" fill="#5ef0c4" opacity=".35" /><path d="M9 8 L16 8" stroke="#5ef0c4" />
      <path d="M21 4.5 L24.5 8 L21 11.5 L17.5 8 Z" fill="none" stroke="#5ef0c4" strokeWidth="1.2" />
    </Svg>
  ),
  halo: (
    <Svg><circle cx="13" cy="8" r="6.5" fill="#62adff" fillOpacity=".12" stroke="#62adff" strokeDasharray="2.4 2.4" /></Svg>
  ),
  spot: (
    <Svg>
      <path d="M6 8 Q13 2 20 8 Q13 14 6 8 Z" fill="#06101f" stroke="#ffc54d" strokeWidth="1.3" /><circle cx="13" cy="8" r="2" fill="#ffc54d" />
    </Svg>
  ),
  waypoint: (
    <Svg><rect x="10" y="5" width="6" height="6" transform="rotate(45 13 8)" fill="#62adff" /></Svg>
  ),
  clouds: (
    <Svg>
      <path d="M5 12 C2 12 2 8 5.5 8 C6 4.5 11 4 12.5 6.5 C14.5 4.5 19 5.5 18.5 8.5 C22 8.5 22 12 19 12 Z" fill="#eef3f8" opacity=".9" />
    </Svg>
  ),
  light: (
    <Svg>
      <circle cx="7" cy="8" r="3.2" fill="#ffe08a" />
      {[0, 1, 2, 3, 4, 5, 6, 7].map((a) => {
        const r = a * Math.PI / 4;
        return <path key={a} d={`M${7 + Math.cos(r) * 4.6} ${8 + Math.sin(r) * 4.6} L${7 + Math.cos(r) * 6.2} ${8 + Math.sin(r) * 6.2}`} stroke="#ffe08a" />;
      })}
      <circle cx="19" cy="8" r="4.2" fill="#cfdcf0" /><circle cx="21" cy="6.5" r="3.6" fill="#101a2e" />
    </Svg>
  ),
};

const ROWS: { icon: string; fr: ReactNode; en: ReactNode }[] = [
  { icon: 'carriers', fr: <>Porte-avions vus du ciel : pont bleu-gris (US), pont en bois et hinomaru (Japon)</>, en: <>Carriers from above: blue-grey deck (US), wooden deck with hinomaru (Japan)</> },
  { icon: 'escort', fr: <>Escorte en cercle autour des porte-avions ; un navire détaché ou coulé quitte le cercle</>, en: <>Escorts ring the carriers; a detached or sunk ship leaves the ring</> },
  { icon: 'wake', fr: <>Sillage : sa longueur suit la vitesse consignée</>, en: <>Wake length follows the logged speed</> },
  { icon: 'planes', fr: <><b>1 silhouette = 1 avion</b> au zoom ≥ ×2,2 ; ombre portée selon l'altitude</>, en: <><b>1 silhouette = 1 aircraft</b> at zoom ≥ ×2.2; shadow offset follows altitude</> },
  { icon: 'shot', fr: <>Avion abattu : spirale de fumée puis gerbe (pertes appliquées au point d'attaque)</>, en: <>Shot down: smoke spiral then splash (losses applied at the point of attack)</> },
  { icon: 'combat', fr: <>Combat : éclats de DCA, traçantes, bombes manquées (gerbes d'eau)</>, en: <>Combat: flak bursts, tracers, near misses (water columns)</> },
  { icon: 'hit', fr: <>Coups au but : explosions sur la cible</>, en: <>Hits: explosions on the target</> },
  { icon: 'fire', fr: <>Incendie : la fumée suit le vent observé (boussole)</>, en: <>Fire: smoke drifts with the observed wind (compass)</> },
  { icon: 'wreck', fr: <>Coulé : croix et nappe de mazout qui s'étale</>, en: <>Sunk: cross and spreading oil slick</> },
  { icon: 'radar', fr: <>Radar des porte-avions US et de Midway ; un raid japonais détecté clignote. La Kidō Butai n'avait pas de radar</>, en: <>Radar of US carriers and Midway; a detected Japanese raid blinks. The Kidō Butai had no radar</> },
  { icon: 'halo', fr: <>Halo = erreur de position (nm) ; il <b>grossit</b> quand la piste est périmée (+5 nm/h)</>, en: <>Halo = position error (nm); it <b>grows</b> as the track goes stale (+5 nm/h)</> },
  { icon: 'spot', fr: <>Unité repérée par l'ennemi</>, en: <>Unit spotted by the enemy</> },
  { icon: 'waypoint', fr: <>Waypoint — <b>cliquer</b> : justification du cap</>, en: <>Waypoint — <b>click</b>: rationale for the heading</> },
  { icon: 'clouds', fr: <>Nuages : nébulosité observée (6-8/10 sur la Kidō Butai le 4 au matin)</>, en: <>Clouds: observed cover (6-8/10 over the Kidō Butai on the morning of the 4th)</> },
  { icon: 'light', fr: <>Jour et nuit : position réelle du soleil en juin 1942</>, en: <>Day and night: actual sun position in June 1942</> },
];

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

  return (
    <div id="legend">
      <button
        onClick={() => setOpen(false)}
        title={t('legend_close_title')}
        aria-label={t('legend_close_title')}
        style={{ float: 'right', cursor: 'pointer', padding: 2, border: 'none', background: 'none', color: 'inherit', lineHeight: 0 }}
      >
        <svg width="12" height="12" viewBox="0 0 12 12" aria-hidden="true"><path d="M2 2 L10 10 M10 2 L2 10" stroke="currentColor" strokeWidth="1.6" /></svg>
      </button>
      <div style={{ marginBottom: 4 }}>
        <span className="sw" style={{ background: '#62adff' }} />US Navy &nbsp;
        <span className="sw" style={{ background: '#ff6257' }} />{lang === 'en' ? 'Imperial Navy' : 'Marine impériale'}
      </div>
      {ROWS.map((r) => (
        <div key={r.icon} style={{ display: 'flex', gap: 7, alignItems: 'center', lineHeight: 1.35, margin: '2px 0' }}>
          {ICONS[r.icon]}<span>{lang === 'en' ? r.en : r.fr}</span>
        </div>
      ))}
      <div style={{ marginTop: 4, opacity: 0.75 }}>
        {lang === 'en' ? 'Zoom: wheel or slider · Rings 100/200/300 nm · dashed = antimeridian' : 'Zoom : molette ou curseur · Anneaux 100/200/300 nm · pointillé = antiméridien'}
      </div>
    </div>
  );
}
