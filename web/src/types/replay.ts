export interface TrackPoint {
  t: number; lat: number; lon: number; err: number; m: string;
  crs: number | null; spd?: number | null; ts: string; cause: string | null; note: string | null;
}
export interface Member { id: string; type: string; }
export interface Entity {
  id: string; label: string; side: 'IJN' | 'USN'; sub: string; track: TrackPoint[];
  kind?: 'formation' | 'ship'; type?: string | null; ships?: Member[];
}
export interface Wreck { t: number; lat: number; lon: number; name: string; h: string; ent: string; }
/** Bâtiment hors de combat : `burn` = incendie (bombes), sinon désemparé (torpilles seules). */
export interface Fire { ent: string; t0: number; t1: number; burn?: boolean; }
export interface Combat { t0: number; t1: number; ent: string; k?: 'attack' | 'hit' | 'collision'; s: string; }
export interface Spot { t: number; ent: string; s: string; }
export interface Raid {
  mid: string; seq: number; side: 'IJN' | 'USN'; t0: number; t1: number;
  a: [number, number]; b: [number, number]; n0: number; lost: number;
  ta: number | null; tl: number | null; par: number; alt?: number | null;
}
/** Observation météo : vent d'où il souffle (°), force (nds), nébulosité (0-1). */
export interface WeatherObs { t: number; lat: number; lon: number; wd: number; ws: number; cc: number | null; vis: number | null; }
export interface Mission {
  type: string; target: string; origin: string;
  aircraft: { n: number; type: string }[]; committed: number; lost: number;
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
  spots: Spot[]; raids: Raid[]; missions: Record<string, Mission>;
  events: GameEvent[]; contacts: Contact[]; roster: RosterShip[];
  weather?: WeatherObs[];
  tmin: number; tmax: number; build: Build;
}
