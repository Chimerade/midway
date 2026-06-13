import { describe, it, expect, vi, beforeEach } from 'vitest';
import { renderHook, waitFor } from '@testing-library/react';
import { useReplayData } from './useReplayData';

const sample = {
  entities: [{ id: 'KB', label: 'Kido', side: 'IJN', sub: '', track: [{ t: 0, lat: 30, lon: -179, err: 25, m: 'est', crs: 135, ts: '06-04T04:30', cause: null, note: null }] }],
  wrecks: [], fires: [], combats: [], spots: [], raids: [], events: [], contacts: [],
  tmin: 0, tmax: 100, build: { gen: 'x', db_hash: 'abcd1234', n_ev: 0, n_pos: 0, n_inf: 0 },
};

beforeEach(() => {
  vi.stubGlobal('fetch', vi.fn(() => Promise.resolve({ ok: true, json: () => Promise.resolve(sample) } as Response)));
});

describe('useReplayData', () => {
  it('charge et expose les données', async () => {
    const { result } = renderHook(() => useReplayData());
    await waitFor(() => expect(result.current.data).not.toBeNull());
    expect(result.current.data!.entities[0].label).toBe('Kido');
    expect(result.current.error).toBeNull();
  });
});
