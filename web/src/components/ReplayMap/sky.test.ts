import { describe, it, expect } from 'vitest';
import { sunPosition, skyAt } from './sky';

// Minutes du replay : 0 = 3 juin 1942 00:00 (GMT−12) ; le 4 juin commence à 1440.
const J4 = (h: number, m = 0) => 1440 + h * 60 + m;
const KB = { lat: 30.8, lon: -179.3 };

/** Premier instant (pas d'une minute) où le soleil franchit l'horizon apparent (−0,833°). */
function sunrise(lat: number, lon: number) {
  for (let t = J4(3); t < J4(8); t++) if (sunPosition(t, lat, lon).elev > -0.833) return t - 1440;
  return NaN;
}

describe('soleil du 4 juin 1942', () => {
  it('se lève vers 05:00 sur la Kidō Butai', () => {
    const m = sunrise(KB.lat, KB.lon);
    expect(m).toBeGreaterThan(4 * 60 + 50);
    expect(m).toBeLessThan(5 * 60 + 15);
  });

  it('culmine vers 84° à Midway et se couche après 18:30', () => {
    const noon = Math.max(...Array.from({ length: 120 }, (_, i) => sunPosition(J4(11) + i, 28.21, -177.37).elev));
    expect(noon).toBeGreaterThan(83);
    expect(noon).toBeLessThan(86);
    expect(sunPosition(J4(18, 30), 28.21, -177.37).elev).toBeGreaterThan(0);
    expect(sunPosition(J4(19, 30), 28.21, -177.37).elev).toBeLessThan(0);
  });

  it('éclaire la mer le jour et l’assombrit la nuit', () => {
    expect(skyAt(J4(12), 30, -177).light).toBeGreaterThan(0.99);
    expect(skyAt(J4(12), 30, -177).tint).toBeNull();
    expect(skyAt(J4(1), 30, -177).light).toBeLessThan(0.01);
    expect(skyAt(J4(1), 30, -177).tint).not.toBeNull();
  });
});
