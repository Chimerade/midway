import type { Lang } from './strings';

// The battle spans 3–7 June 1942; only "June" is ever needed.
const MONTH: Record<Lang, string> = { en: 'June', fr: 'juin' };
const DAY_LETTER: Record<Lang, string> = { en: 'D', fr: 'J' };
const pad = (n: number) => String(n).padStart(2, '0');

// epoch = 3 June 1942 00:00 (GMT−12); t is minutes since epoch.
function parts(t: number) {
  t = Math.floor(t);
  const d = 3 + Math.floor(t / 1440);
  const mins = ((t % 1440) + 1440) % 1440;
  return { d, h: Math.floor(mins / 60), m: mins % 60 };
}

// Full clock label, e.g. "3 June 1942 — 04:30 (GMT−12)".
export function fmtFull(t: number, lang: Lang): string {
  const { d, h, m } = parts(t);
  return `${d} ${MONTH[lang]} 1942 — ${pad(h)}:${pad(m)} (GMT−12)`;
}

// Timeline label, e.g. "3 June — 04:30".
export function fmtDay(t: number, lang: Lang): string {
  const { d, h, m } = parts(t);
  return `${d} ${MONTH[lang]} — ${pad(h)}:${pad(m)}`;
}

// Compact feed label, e.g. "04:30 D2".
export function fmtFeed(t: number, lang: Lang): string {
  const { d, h, m } = parts(t);
  return `${pad(h)}:${pad(m)} ${DAY_LETTER[lang]}${d}`;
}
