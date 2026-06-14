// UI string dictionary (interface chrome only). Historical data (events, unit
// labels, notes) stays in French as it comes from the source database.
export type Lang = 'en' | 'fr';

export const STRINGS = {
  en: {
    nav_home: 'Home',
    nav_map: 'Map',
    nav_chronology: 'Chronology',
    nav_methodology: 'Methodology',
    theme_to_dark: '🌙 dark',
    theme_to_light: '☀ light',

    home_title: 'Battle of Midway — 3–7 June 1942',
    home_intro:
      'Chronological and cartographic reconstruction of the battle, built from a database of sources, inferred positions and modeled processes.',
    home_map: 'Map / Animated replay',
    home_map_desc: 'replay the battle through time',
    home_chrono: 'Chronology',
    home_chrono_desc: 'the list of events',
    home_method: 'Methodology',
    home_method_desc: 'how the model is built',

    loading: 'Loading…',
    load_error: 'Loading error',
    play: '▶ Play',
    pause: '⏸ Pause',
    speed: 'speed',
    zoom: 'zoom',
    cb_halos: 'halos',
    cb_trails: 'trails',
    cb_raids: 'raids',
    cb_perceived: 'perceived world',
    cb_chronology: 'chronology',

    legend_show: 'ℹ legend',
    legend_show_title: 'show legend',
    legend_close_title: 'close',

    feed_click_title: 'click: jump to this moment',
    chrono_title: 'Chronology',
    method_unavailable: 'Content unavailable.',
  },
  fr: {
    nav_home: 'Accueil',
    nav_map: 'Carte',
    nav_chronology: 'Chronologie',
    nav_methodology: 'Méthodologie',
    theme_to_dark: '🌙 sombre',
    theme_to_light: '☀ clair',

    home_title: 'Bataille de Midway — 3 au 7 juin 1942',
    home_intro:
      "Reconstitution chronologique et cartographique de la bataille à partir d'une base de données de sources, positions inférées et processus modélisés.",
    home_map: 'Carte / Replay animé',
    home_map_desc: 'rejouer la bataille dans le temps',
    home_chrono: 'Chronologie',
    home_chrono_desc: 'la liste des événements',
    home_method: 'Méthodologie',
    home_method_desc: 'comment le modèle est construit',

    loading: 'Chargement…',
    load_error: 'Erreur de chargement',
    play: '▶ Lecture',
    pause: '⏸ Pause',
    speed: 'vitesse',
    zoom: 'zoom',
    cb_halos: 'halos',
    cb_trails: 'traînées',
    cb_raids: 'raids',
    cb_perceived: 'monde perçu',
    cb_chronology: 'chronologie',

    legend_show: 'ℹ légende',
    legend_show_title: 'afficher la légende',
    legend_close_title: 'fermer',

    feed_click_title: 'cliquer: aller à cet instant',
    chrono_title: 'Chronologie',
    method_unavailable: 'Contenu indisponible.',
  },
} as const;

export type StringKey = keyof (typeof STRINGS)['en'];
