import { describe, expect, it, vi } from 'vitest';
import * as XLSX from 'xlsx';
import { generateWhatsAppText, exportToExcel } from './report';

// ---------------------------------------------------------------------------
// Mock SheetJS — we test logic, not file I/O
// ---------------------------------------------------------------------------
vi.mock('xlsx', () => ({
  utils: {
    json_to_sheet: vi.fn(() => ({})),
    book_new: vi.fn(() => ({})),
    book_append_sheet: vi.fn(),
  },
  writeFile: vi.fn(),
}));

// ---------------------------------------------------------------------------
// generateWhatsAppText
// ---------------------------------------------------------------------------

const baseTotals = {
  primeirasReunioesRealizadas: 8,
  segundasReunioesRealizadas: 5,
  terceirasReunioesRealizadas: 2,
  referencias: 3,
};

const baseExtra = {
  contratosFechados: 4,
  valorTotalFechos: 3200.7,
  pessoasSeguras: 6,
  reunioes1aProxSemana: 7,
  reunioes2aProxSemana: 3,
  reunioes3aProxSemana: 1,
};

describe('generateWhatsAppText', () => {
  it('formats the week header as DD/MM/YYYY - DD/MM/YYYY in bold', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('*11/03/2024 - 15/03/2024*');
  });

  it('includes meeting counts for all three rounds', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('1.ªR 8');
    expect(text).toContain('2.ªR 5');
    expect(text).toContain('3.ªR 2');
  });

  it('includes contracts and references', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('Contratos 4');
    expect(text).toContain('Referências 3');
  });

  it('ceils the valor to the nearest integer', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('Valor 3201€');
  });

  it('includes pessoas seguras', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('Pessoas seguras 6');
  });

  it('includes next-week meeting forecasts', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    expect(text).toContain('1.ª- 7');
    expect(text).toContain('2.ª- 3');
    expect(text).toContain('3.ª- 1');
  });

  it('defaults pessoasSeguras to 0 when undefined', () => {
    const extra = { ...baseExtra, pessoasSeguras: undefined };
    const text = generateWhatsAppText(baseTotals, extra, '2024-03-11', '2024-03-15');
    expect(text).toContain('Pessoas seguras 0');
  });

  it('defaults next-week meetings to 0 when undefined', () => {
    const extra = {
      ...baseExtra,
      reunioes1aProxSemana: undefined,
      reunioes2aProxSemana: undefined,
      reunioes3aProxSemana: undefined,
    };
    const text = generateWhatsAppText(baseTotals, extra, '2024-03-11', '2024-03-15');
    expect(text).toContain('1.ª- 0');
    expect(text).toContain('2.ª- 0');
    expect(text).toContain('3.ª- 0');
  });

  it('handles integer valor (no rounding needed)', () => {
    const extra = { ...baseExtra, valorTotalFechos: 5000 };
    const text = generateWhatsAppText(baseTotals, extra, '2024-03-11', '2024-03-15');
    expect(text).toContain('Valor 5000€');
  });

  it('produces the expected full message structure', () => {
    const text = generateWhatsAppText(baseTotals, baseExtra, '2024-03-11', '2024-03-15');
    const lines = text.split('\n');
    expect(lines[0]).toBe('*11/03/2024 - 15/03/2024*');
    expect(lines[1]).toBe('');
    // After blank line: meeting counts, contracts, valor, references, pessoas
    expect(lines[lines.length - 1]).toBe('3.ª- 1');
  });
});

// ---------------------------------------------------------------------------
// exportToExcel
// ---------------------------------------------------------------------------

const sampleSummaries = [
  {
    weekStart: '2024-03-11',
    weekEnd: '2024-03-15',
    totals: {
      contactos: 40, primeirasReunioesMarcadas: 12, segundasReunioesMarcadas: 8,
      terceirasReunioesMarcadas: 3, primeirasReunioesRealizadas: 9,
      segundasReunioesRealizadas: 6, terceirasReunioesRealizadas: 2,
      pesquisas: 15, referencias: 4,
    },
    extra: {
      contratosFechados: 3, valorTotalFechos: 4500, pessoasSeguras: 5,
      reunioes1aProxSemana: 8, reunioes2aProxSemana: 4, reunioes3aProxSemana: 1,
    },
  },
];

describe('exportToExcel', () => {
  it('calls XLSX.utils.json_to_sheet with correctly shaped rows', () => {
    exportToExcel(sampleSummaries);
    expect(XLSX.utils.json_to_sheet).toHaveBeenCalledOnce();
    const [rows] = XLSX.utils.json_to_sheet.mock.calls[0];
    expect(rows).toHaveLength(1);
    const row = rows[0];
    expect(row['Semana (início)']).toBe('2024-03-11');
    expect(row['Semana (fim)']).toBe('2024-03-15');
    expect(row['Contactos']).toBe(40);
    expect(row['1as Realizadas']).toBe(9);
    expect(row['Contratos Fechados']).toBe(3);
    expect(row['Valor Fechos (€)']).toBe(4500);
    expect(row['Pessoas Seguras']).toBe(5);
    expect(row['1ª Próxima Semana']).toBe(8);
  });

  it('calls XLSX.writeFile with the expected filename', () => {
    exportToExcel(sampleSummaries);
    expect(XLSX.writeFile).toHaveBeenCalledWith(expect.anything(), 'historico_vendas.xlsx');
  });

  it('appends the sheet with the name "Histórico"', () => {
    exportToExcel(sampleSummaries);
    expect(XLSX.utils.book_append_sheet).toHaveBeenCalledWith(
      expect.anything(),
      expect.anything(),
      'Histórico',
    );
  });

  it('falls back to 0 for missing extra fields', () => {
    const summaries = [{ ...sampleSummaries[0], extra: undefined }];
    exportToExcel(summaries);
    const [rows] = XLSX.utils.json_to_sheet.mock.calls[0];
    expect(rows[0]['Contratos Fechados']).toBe(0);
    expect(rows[0]['Pessoas Seguras']).toBe(0);
  });

  it('exports multiple summaries as multiple rows', () => {
    const two = [sampleSummaries[0], { ...sampleSummaries[0], weekStart: '2024-03-18', weekEnd: '2024-03-22' }];
    exportToExcel(two);
    const [rows] = XLSX.utils.json_to_sheet.mock.calls[0];
    expect(rows).toHaveLength(2);
  });
});
