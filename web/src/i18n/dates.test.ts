import { describe, it, expect } from 'vitest';
import { fmtDay, fmtFull, fmtFeed } from './dates';

// epoch = 3 June 1942 00:00 (GMT−12); 1710 min = 1 day + 4h30 → 4 June 04:30
describe('date formatting (bilingual)', () => {
  it('fmtDay', () => {
    expect(fmtDay(1710, 'fr')).toBe('4 juin — 04:30');
    expect(fmtDay(1710, 'en')).toBe('4 June — 04:30');
  });
  it('fmtFull', () => {
    expect(fmtFull(1710, 'fr')).toBe('4 juin 1942 — 04:30 (GMT−12)');
    expect(fmtFull(1710, 'en')).toBe('4 June 1942 — 04:30 (GMT−12)');
  });
  it('fmtFeed', () => {
    expect(fmtFeed(1710, 'fr')).toBe('04:30 J4');
    expect(fmtFeed(1710, 'en')).toBe('04:30 D4');
  });
});
