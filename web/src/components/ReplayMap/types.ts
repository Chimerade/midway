import type { ReplayData } from '../../types/replay';

export interface RenderState {
  T: number;           // instant courant (minutes depuis epoch)
  scale: number;       // zoom
  panX: number; panY: number;
  theme: 'light' | 'dark';
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  selWp: { pt: any; trk: any[]; idx: number } | null;
}

export interface Clickable { x: number; y: number; ent: string; pt: any; trk: any[]; idx: number; }

export type DrawResult = { clickables: Clickable[] };
export type DrawFn = (ctx: CanvasRenderingContext2D, cv: HTMLCanvasElement, data: ReplayData, st: RenderState) => DrawResult;
