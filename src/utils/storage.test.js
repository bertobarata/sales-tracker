import { beforeEach, describe, expect, it, vi } from 'vitest';
import {
  getDailyEntries,
  getDailyEntry,
  saveDailyEntry,
  getWeeklySummaries,
  saveWeeklySummary,
  loadRemoteEntries,
  loadRemoteWeeklySummaries,
  getMonthlyValorTotal,
  getWeekDates,
  getEntriesForWeek,
  sumWeekEntries,
} from './storage';

vi.mock('./sync', () => ({
  syncDailyEntry: vi.fn().mockResolvedValue(undefined),
  syncWeeklySummary: vi.fn().mockResolvedValue(undefined),
}));

beforeEach(() => {
  localStorage.clear();
});

// ---------------------------------------------------------------------------
// getDailyEntries / saveDailyEntry / getDailyEntry
// ---------------------------------------------------------------------------

describe('getDailyEntries', () => {
  it('returns empty array when nothing is stored', () => {
    expect(getDailyEntries()).toEqual([]);
  });

  it('returns parsed entries from localStorage', () => {
    const entries = [{ date: '2024-03-11', contactos: 5 }];
    localStorage.setItem('salestracker_daily', JSON.stringify(entries));
    expect(getDailyEntries()).toEqual(entries);
  });
});

describe('saveDailyEntry', () => {
  it('adds a new entry when none exists for that date', () => {
    const entry = { date: '2024-03-11', contactos: 3 };
    saveDailyEntry(entry);
    expect(getDailyEntries()).toEqual([entry]);
  });

  it('updates an existing entry with the same date', () => {
    const original = { date: '2024-03-11', contactos: 3 };
    const updated = { date: '2024-03-11', contactos: 7 };
    saveDailyEntry(original);
    saveDailyEntry(updated);
    const entries = getDailyEntries();
    expect(entries).toHaveLength(1);
    expect(entries[0].contactos).toBe(7);
  });

  it('preserves other entries when updating one', () => {
    saveDailyEntry({ date: '2024-03-11', contactos: 3 });
    saveDailyEntry({ date: '2024-03-12', contactos: 5 });
    saveDailyEntry({ date: '2024-03-11', contactos: 10 });
    expect(getDailyEntries()).toHaveLength(2);
  });

  it('calls syncDailyEntry when uid is provided', async () => {
    const { syncDailyEntry } = await import('./sync');
    const entry = { date: '2024-03-11', contactos: 4 };
    saveDailyEntry(entry, 'user-123');
    expect(syncDailyEntry).toHaveBeenCalledWith('user-123', entry);
  });

  it('does not call syncDailyEntry when uid is null', async () => {
    const { syncDailyEntry } = await import('./sync');
    saveDailyEntry({ date: '2024-03-11', contactos: 4 });
    expect(syncDailyEntry).not.toHaveBeenCalled();
  });
});

describe('getDailyEntry', () => {
  it('returns null when no entry for that date', () => {
    expect(getDailyEntry('2024-03-11')).toBeNull();
  });

  it('returns the matching entry', () => {
    const entry = { date: '2024-03-11', contactos: 5 };
    saveDailyEntry(entry);
    expect(getDailyEntry('2024-03-11')).toEqual(entry);
  });
});

// ---------------------------------------------------------------------------
// getWeeklySummaries / saveWeeklySummary
// ---------------------------------------------------------------------------

describe('getWeeklySummaries', () => {
  it('returns empty array when nothing is stored', () => {
    expect(getWeeklySummaries()).toEqual([]);
  });

  it('returns parsed summaries from localStorage', () => {
    const summaries = [{ weekStart: '2024-03-11', weekEnd: '2024-03-15' }];
    localStorage.setItem('salestracker_weekly', JSON.stringify(summaries));
    expect(getWeeklySummaries()).toEqual(summaries);
  });
});

describe('saveWeeklySummary', () => {
  it('adds a new summary', () => {
    const summary = { weekStart: '2024-03-11', weekEnd: '2024-03-15', totals: {} };
    saveWeeklySummary(summary);
    expect(getWeeklySummaries()).toEqual([summary]);
  });

  it('updates an existing summary with the same weekStart', () => {
    const original = { weekStart: '2024-03-11', totals: { contactos: 10 } };
    const updated = { weekStart: '2024-03-11', totals: { contactos: 25 } };
    saveWeeklySummary(original);
    saveWeeklySummary(updated);
    const summaries = getWeeklySummaries();
    expect(summaries).toHaveLength(1);
    expect(summaries[0].totals.contactos).toBe(25);
  });

  it('calls syncWeeklySummary when uid is provided', async () => {
    const { syncWeeklySummary } = await import('./sync');
    const summary = { weekStart: '2024-03-11', totals: {} };
    saveWeeklySummary(summary, 'user-123');
    expect(syncWeeklySummary).toHaveBeenCalledWith('user-123', summary);
  });
});

// ---------------------------------------------------------------------------
// loadRemoteEntries / loadRemoteWeeklySummaries
// ---------------------------------------------------------------------------

describe('loadRemoteEntries', () => {
  it('overwrites localStorage with the provided entries', () => {
    saveDailyEntry({ date: '2024-03-11', contactos: 1 });
    const remote = [{ date: '2024-03-12', contactos: 9 }];
    loadRemoteEntries(remote);
    expect(getDailyEntries()).toEqual(remote);
  });
});

describe('loadRemoteWeeklySummaries', () => {
  it('overwrites localStorage with the provided summaries', () => {
    saveWeeklySummary({ weekStart: '2024-03-11', totals: {} });
    const remote = [{ weekStart: '2024-03-18', totals: {} }];
    loadRemoteWeeklySummaries(remote);
    expect(getWeeklySummaries()).toEqual(remote);
  });
});

// ---------------------------------------------------------------------------
// getMonthlyValorTotal
// ---------------------------------------------------------------------------

describe('getMonthlyValorTotal', () => {
  it('returns 0 when there are no summaries', () => {
    expect(getMonthlyValorTotal(2024, 3)).toBe(0);
  });

  it('sums valorTotalFechos for weeks starting in the given month', () => {
    saveWeeklySummary({ weekStart: '2024-03-04', extra: { valorTotalFechos: 1000 } });
    saveWeeklySummary({ weekStart: '2024-03-11', extra: { valorTotalFechos: 2500 } });
    expect(getMonthlyValorTotal(2024, 3)).toBe(3500);
  });

  it('excludes weeks from other months', () => {
    saveWeeklySummary({ weekStart: '2024-03-11', extra: { valorTotalFechos: 1000 } });
    saveWeeklySummary({ weekStart: '2024-04-01', extra: { valorTotalFechos: 999 } });
    expect(getMonthlyValorTotal(2024, 3)).toBe(1000);
  });

  it('handles missing extra or valorTotalFechos gracefully', () => {
    saveWeeklySummary({ weekStart: '2024-03-11' });
    saveWeeklySummary({ weekStart: '2024-03-18', extra: {} });
    expect(getMonthlyValorTotal(2024, 3)).toBe(0);
  });

  it('pads single-digit months correctly', () => {
    saveWeeklySummary({ weekStart: '2024-01-08', extra: { valorTotalFechos: 500 } });
    expect(getMonthlyValorTotal(2024, 1)).toBe(500);
  });
});

// ---------------------------------------------------------------------------
// getWeekDates
// ---------------------------------------------------------------------------

describe('getWeekDates', () => {
  it('returns Monday and Friday for a date mid-week (Wednesday)', () => {
    const { start, end } = getWeekDates(new Date('2024-03-13')); // Wednesday
    expect(start).toBe('2024-03-11');
    expect(end).toBe('2024-03-15');
  });

  it('returns the same Monday when given a Monday', () => {
    const { start, end } = getWeekDates(new Date('2024-03-11')); // Monday
    expect(start).toBe('2024-03-11');
    expect(end).toBe('2024-03-15');
  });

  it('returns the previous Monday when given a Sunday', () => {
    const { start, end } = getWeekDates(new Date('2024-03-17')); // Sunday
    expect(start).toBe('2024-03-11');
    expect(end).toBe('2024-03-15');
  });

  it('returns correct week across a month boundary', () => {
    const { start, end } = getWeekDates(new Date('2024-04-01')); // Monday
    expect(start).toBe('2024-04-01');
    expect(end).toBe('2024-04-05');
  });
});

// ---------------------------------------------------------------------------
// getEntriesForWeek
// ---------------------------------------------------------------------------

describe('getEntriesForWeek', () => {
  beforeEach(() => {
    saveDailyEntry({ date: '2024-03-10', contactos: 1 }); // Sunday before
    saveDailyEntry({ date: '2024-03-11', contactos: 2 }); // Monday (in range)
    saveDailyEntry({ date: '2024-03-14', contactos: 3 }); // Thursday (in range)
    saveDailyEntry({ date: '2024-03-15', contactos: 4 }); // Friday (in range)
    saveDailyEntry({ date: '2024-03-16', contactos: 5 }); // Saturday after
  });

  it('returns only entries within the inclusive date range', () => {
    const result = getEntriesForWeek('2024-03-11', '2024-03-15');
    expect(result).toHaveLength(3);
    expect(result.map(e => e.date)).toEqual(['2024-03-11', '2024-03-14', '2024-03-15']);
  });

  it('returns empty array when no entries fall in range', () => {
    expect(getEntriesForWeek('2024-04-01', '2024-04-05')).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// sumWeekEntries
// ---------------------------------------------------------------------------

describe('sumWeekEntries', () => {
  it('returns all-zero totals for an empty array', () => {
    const totals = sumWeekEntries([]);
    const keys = [
      'contactos', 'primeirasReunioesMarcadas', 'segundasReunioesMarcadas',
      'terceirasReunioesMarcadas', 'primeirasReunioesRealizadas',
      'segundasReunioesRealizadas', 'terceirasReunioesRealizadas',
      'pesquisas', 'referencias',
    ];
    keys.forEach(k => expect(totals[k]).toBe(0));
  });

  it('sums all 9 metric fields across entries', () => {
    const entries = [
      { contactos: 5, primeirasReunioesMarcadas: 3, segundasReunioesMarcadas: 2,
        terceirasReunioesMarcadas: 1, primeirasReunioesRealizadas: 2,
        segundasReunioesRealizadas: 1, terceirasReunioesRealizadas: 0,
        pesquisas: 4, referencias: 1 },
      { contactos: 8, primeirasReunioesMarcadas: 2, segundasReunioesMarcadas: 1,
        terceirasReunioesMarcadas: 0, primeirasReunioesRealizadas: 1,
        segundasReunioesRealizadas: 0, terceirasReunioesRealizadas: 1,
        pesquisas: 3, referencias: 2 },
    ];
    const totals = sumWeekEntries(entries);
    expect(totals.contactos).toBe(13);
    expect(totals.primeirasReunioesMarcadas).toBe(5);
    expect(totals.segundasReunioesMarcadas).toBe(3);
    expect(totals.primeirasReunioesRealizadas).toBe(3);
    expect(totals.pesquisas).toBe(7);
    expect(totals.referencias).toBe(3);
  });

  it('treats missing or non-numeric fields as 0', () => {
    const entries = [{ contactos: 'abc' }, { contactos: undefined }, { contactos: 5 }];
    expect(sumWeekEntries(entries).contactos).toBe(5);
  });
});
