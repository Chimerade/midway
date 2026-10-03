// Caméra « suivre l'action » : centre de gravité de ce qui se passe à l'instant T,
// les combats pesant plus que les raids en vol.
import type { ReplayData } from '../../types/replay';
import { unwrap } from './view';

type Pos = { lat: number; lon: number };

export function actionCenter(data: ReplayData, T: number, posOf: (ent: string, t: number) => Pos | null): Pos | null {
  let sw = 0, la = 0, lo = 0;
  const add = (p: Pos | null, w: number) => { if (!p) return; sw += w; la += p.lat * w; lo += unwrap(p.lon) * w; };
  data.combats.forEach((cb) => { if (T >= cb.t0 && T <= cb.t1) add(posOf(cb.ent, T), 5); });
  data.raids.forEach((r) => {
    if (T < r.t0 || T > r.t1) return;
    const f = (T - r.t0) / Math.max(1, r.t1 - r.t0);
    add({ lat: r.a[0] + f * (r.b[0] - r.a[0]), lon: unwrap(r.a[1]) + f * (unwrap(r.b[1]) - unwrap(r.a[1])) }, (r.par || 1) > 1 ? 0.3 : 1);
  });
  return sw ? { lat: la / sw, lon: lo / sw } : null;
}
