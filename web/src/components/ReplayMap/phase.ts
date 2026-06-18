import type { Lang } from '../../i18n/strings';

// Phase de vol d'une flotte aérienne à l'instant T, déduite de l'heure d'attaque
// (ta). Avant l'attaque la formation cherche/rejoint sa cible ; au moment de
// l'attaque (fenêtre ~10 min) elle frappe ; ensuite elle rentre. Les missions
// sans attaque (recherches, patrouilles : ta == null) restent en « recherche ».
export type PhaseKey = 'search' | 'attack' | 'return';

export function raidPhaseKey(ta: number | null, T: number): PhaseKey {
  if (ta == null || T < ta) return 'search';
  if (T < ta + 10) return 'attack';
  return 'return';
}

// Libellé unique partagé par l'encart (RaidCard) et la carte (render).
export const PHASE_LABEL: Record<Lang, Record<PhaseKey, string>> = {
  en: { search: 'Searching', attack: 'Attacking', return: 'Returning' },
  fr: { search: 'Recherche', attack: 'Attaque', return: 'Retour' },
};
