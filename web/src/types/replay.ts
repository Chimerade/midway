export interface TrackPoint {
  t: number; lat: number; lon: number; err: number; m: string;
  crs: number | null; ts: string; cause: string | null; note: string | null;
}
export interface Entity { id: string; label: string; side: 'IJN' | 'USN'; sub: string; track: TrackPoint[]; }
export interface Wreck { t: number; lat: number; lon: number; name: string; h: string; ent: string; }
export interface Fire { ent: string; t0: number; t1: number; }
export interface Combat { t0: number; t1: number; ent: string; s: string; }
export interface Spot { t: number; ent: string; s: string; }
export interface Raid {
  mid: string; seq: number; side: 'IJN' | 'USN'; t0: number; t1: number;
  a: [number, number]; b: [number, number]; n0: number; lost: number;
  ta: number | null; tl: number | null; par: number;
}
export interface GameEvent { t: number; type: string; side: string; s: string; u: number; }
export interface Contact { t: number; lat: number; lon: number; s: string; }
export interface Build { gen: string; db_hash: string; n_ev: number; n_pos: number; n_inf: number; }
export interface RosterShip {
  id: string; name: string; side: 'IJN' | 'USN'; type: string; cls: string | null;
  fate: string; photo: string; sunk: number | null; fires: [number, number][]; hits: number[];
}
export interface ReplayData {
  entities: Entity[]; wrecks: Wreck[]; fires: Fire[]; combats: Combat[];
  spots: Spot[]; raids: Raid[]; events: GameEvent[]; contacts: Contact[]; roster: RosterShip[];
  tmin: number; tmax: number; build: Build;
}
