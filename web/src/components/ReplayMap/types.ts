import type { ReplayData, TrackPoint } from '../../types/replay';
import type { Lang } from '../../i18n/strings';

export interface RenderState {
  T: number;           // instant courant (minutes depuis epoch)
  scale: number;       // zoom
  panX: number; panY: number;
  theme: 'light' | 'dark';
  lang: Lang;
  showHalo: boolean; showTrail: boolean; showRaid: boolean; showPercu: boolean;
  showClouds?: boolean;  // couche nuageuse (nébulosité observée)
  reduced?: boolean;     // préférence système « réduire les animations »
  selWp: { pt: TrackPoint; trk: TrackPoint[]; idx: number } | null;
}

export interface Clickable { x: number; y: number; ent: string; pt: TrackPoint | null; trk: TrackPoint[]; idx: number; mid?: string; }

export type DrawResult = { clickables: Clickable[] };
export type DrawFn = (ctx: CanvasRenderingContext2D, cv: HTMLCanvasElement, data: ReplayData, st: RenderState) => DrawResult;
