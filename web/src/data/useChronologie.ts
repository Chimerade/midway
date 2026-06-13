import { useEffect, useState } from 'react';
import type { GameEvent } from '../types/replay';

export function useChronologie() {
  const [events, setEvents] = useState<GameEvent[] | null>(null);
  useEffect(() => {
    fetch(`${import.meta.env.BASE_URL}data/chronologie.json`)
      .then((r) => r.json()).then(setEvents).catch(() => setEvents([]));
  }, []);
  return events;
}
