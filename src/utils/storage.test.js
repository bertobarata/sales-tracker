import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock do módulo sync antes de importar storage (evita inicialização do Firebase)
vi.mock('./sync', () => ({
  syncDailyEntry: vi.fn(),
  syncWeeklySummary: vi.fn(),
}));

import {
  getISOWeekNumber, getWeekDates, formatWeekLabel,
  saveDailyEntry, getDailyEntry, getDailyEntries,
  getEntriesForWeek, sumWeekEntries,
  saveWeeklySummary, getWeeklySummaries, getMonthlyValorTotal,
  loadRemoteEntries, loadRemoteWeeklySummaries,
} from './storage';

beforeEach(() => localStorage.clear());

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

describe('formatWeekLabel', () => {
  it('inclui número da semana ISO', () => {
    // 20-26 abr 2026 = semana 17
    expect(formatWeekLabel('2026-04-20', '2026-04-26')).toContain('Semana 17');
  });

  it('inclui o mês por extenso em português', () => {
    expect(formatWeekLabel('2026-04-20', '2026-04-26')).toContain('abr');
  });

  it('inclui os dias de início e fim', () => {
    const label = formatWeekLabel('2026-04-20', '2026-04-26');
    expect(label).toContain('20');
    expect(label).toContain('26');
  });
});

describe('saveDailyEntry / getDailyEntry', () => {
  it('guarda e recupera uma entrada pelo dia', () => {
    saveDailyEntry({ date: '2026-04-21', contactos: 10 });
    expect(getDailyEntry('2026-04-21')).toMatchObject({ contactos: 10 });
  });

  it('actualiza entrada existente sem duplicar', () => {
    saveDailyEntry({ date: '2026-04-21', contactos: 5 });
    saveDailyEntry({ date: '2026-04-21', contactos: 8 });
    const all = getDailyEntries();
    expect(all.filter(e => e.date === '2026-04-21')).toHaveLength(1);
    expect(all[0].contactos).toBe(8);
  });

  it('retorna null para dia sem dados', () => {
    expect(getDailyEntry('2099-01-01')).toBeNull();
  });
});

describe('getEntriesForWeek', () => {
  beforeEach(() => {
    saveDailyEntry({ date: '2026-04-20', contactos: 3 });
    saveDailyEntry({ date: '2026-04-23', contactos: 5 });
    saveDailyEntry({ date: '2026-04-28', contactos: 7 }); // semana seguinte
  });

  it('devolve só as entradas dentro da semana', () => {
    const entries = getEntriesForWeek('2026-04-20', '2026-04-26');
    expect(entries).toHaveLength(2);
  });

  it('inclui os dias limite (início e fim)', () => {
    const entries = getEntriesForWeek('2026-04-20', '2026-04-26');
    expect(entries.map(e => e.date)).toContain('2026-04-20');
  });
});

describe('sumWeekEntries', () => {
  it('soma corretamente todos os campos', () => {
    const entries = [
      { contactos: 3, primeirasReunioesRealizadas: 2, segundasReunioesRealizadas: 1,
        terceirasReunioesRealizadas: 0, primeirasReunioesMarcadas: 4,
        segundasReunioesMarcadas: 2, terceirasReunioesMarcadas: 1,
        pesquisas: 5, referencias: 1 },
      { contactos: 7, primeirasReunioesRealizadas: 3, segundasReunioesRealizadas: 2,
        terceirasReunioesRealizadas: 1, primeirasReunioesMarcadas: 6,
        segundasReunioesMarcadas: 3, terceirasReunioesMarcadas: 2,
        pesquisas: 8, referencias: 2 },
    ];
    const totals = sumWeekEntries(entries);
    expect(totals.contactos).toBe(10);
    expect(totals.primeirasReunioesRealizadas).toBe(5);
    expect(totals.referencias).toBe(3);
  });

  it('devolve zeros para lista vazia', () => {
    const totals = sumWeekEntries([]);
    expect(totals.contactos).toBe(0);
  });

  it('trata campos em falta como 0', () => {
    const totals = sumWeekEntries([{ date: '2026-04-21' }]);
    expect(totals.contactos).toBe(0);
  });
});

describe('saveWeeklySummary / getWeeklySummaries', () => {
  it('guarda e recupera um resumo semanal', () => {
    saveWeeklySummary({ weekStart: '2026-04-20', weekEnd: '2026-04-26', totals: {} });
    const summaries = getWeeklySummaries();
    expect(summaries).toHaveLength(1);
    expect(summaries[0].weekStart).toBe('2026-04-20');
  });

  it('actualiza resumo existente sem duplicar', () => {
    saveWeeklySummary({ weekStart: '2026-04-20', weekEnd: '2026-04-26', totals: { contactos: 5 } });
    saveWeeklySummary({ weekStart: '2026-04-20', weekEnd: '2026-04-26', totals: { contactos: 9 } });
    const summaries = getWeeklySummaries();
    expect(summaries).toHaveLength(1);
    expect(summaries[0].totals.contactos).toBe(9);
  });
});

describe('getMonthlyValorTotal', () => {
  it('soma o valorTotalFechos das semanas do mês', () => {
    saveWeeklySummary({ weekStart: '2026-04-07', weekEnd: '2026-04-13', totals: {}, extra: { valorTotalFechos: 1000 } });
    saveWeeklySummary({ weekStart: '2026-04-14', weekEnd: '2026-04-20', totals: {}, extra: { valorTotalFechos: 2500 } });
    saveWeeklySummary({ weekStart: '2026-05-04', weekEnd: '2026-05-10', totals: {}, extra: { valorTotalFechos: 999 } }); // maio — não conta
    expect(getMonthlyValorTotal(2026, 4)).toBe(3500);
  });

  it('retorna 0 quando não há dados', () => {
    expect(getMonthlyValorTotal(2099, 1)).toBe(0);
  });
});

describe('loadRemoteEntries / loadRemoteWeeklySummaries', () => {
  it('substitui entradas diárias com os dados remotos', () => {
    saveDailyEntry({ date: '2026-04-21', contactos: 1 });
    loadRemoteEntries([{ date: '2026-04-22', contactos: 99 }]);
    const all = getDailyEntries();
    expect(all).toHaveLength(1);
    expect(all[0].date).toBe('2026-04-22');
  });

  it('substitui resumos semanais com os dados remotos', () => {
    loadRemoteWeeklySummaries([{ weekStart: '2026-04-20', totals: {} }]);
    expect(getWeeklySummaries()).toHaveLength(1);
  });
});
