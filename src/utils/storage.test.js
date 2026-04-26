import { describe, it, expect, vi } from 'vitest';

// Mock do módulo sync antes de importar storage (evita inicialização do Firebase)
vi.mock('./sync', () => ({
  syncDailyEntry: vi.fn(),
  syncWeeklySummary: vi.fn(),
}));

import { getISOWeekNumber, getWeekDates } from './storage';

describe('getISOWeekNumber', () => {
  it('segunda 5 jan 2026 é semana 2', () => {
    expect(getISOWeekNumber(new Date('2026-01-05'))).toBe(2);
  });

  it('domingo 1 jan 2023 ainda é semana 52 de 2022', () => {
    // Edge case: 1 jan 2023 é domingo — pertence à semana 52 de 2022
    expect(getISOWeekNumber(new Date('2023-01-01'))).toBe(52);
  });

  it('domingo 26 abr 2026 é semana 17', () => {
    expect(getISOWeekNumber(new Date('2026-04-26'))).toBe(17);
  });
});

describe('getWeekDates', () => {
  it('end cai sempre num domingo', () => {
    // new Date(year, month, day) usa hora local — sem ambiguidade de fuso
    const { end } = getWeekDates(new Date(2026, 3, 22)); // quarta-feira
    const endDay = new Date(end + 'T00:00:00').getDay();
    expect(endDay).toBe(0); // 0 = domingo
  });

  it('start cai sempre numa segunda-feira', () => {
    const { start } = getWeekDates(new Date(2026, 3, 26)); // domingo
    const startDay = new Date(start + 'T00:00:00').getDay();
    expect(startDay).toBe(1); // 1 = segunda
  });

  it('a semana tem exatamente 6 dias de diferença (seg a dom)', () => {
    const { start, end } = getWeekDates(new Date(2026, 3, 23)); // quinta-feira
    const diff = (new Date(end + 'T00:00:00') - new Date(start + 'T00:00:00')) / 86400000;
    expect(diff).toBe(6);
  });
});
