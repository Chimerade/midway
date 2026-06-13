import { describe, it, expect } from 'vitest';
import { fmtJour } from './Chronologie';

describe('fmtJour', () => {
  it('convertit les minutes depuis epoch en jour/heure', () => {
    // epoch = 3 juin 1942 00:00 ; 1710 min = 1j 4h30 -> 4 juin 04:30
    expect(fmtJour(1710)).toBe('4 juin — 04:30');
  });
});
