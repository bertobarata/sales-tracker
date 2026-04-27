import { describe, it, expect, vi, beforeEach } from 'vitest';

// Mock XLSX antes de importar report.js — evita writes ao sistema de ficheiros
vi.mock('xlsx', () => ({
  default: {
    utils: {
      json_to_sheet: vi.fn(() => ({})),
      book_new: vi.fn(() => ({})),
      book_append_sheet: vi.fn(),
    },
    writeFile: vi.fn(),
  },
  utils: {
    json_to_sheet: vi.fn(() => ({})),
    book_new: vi.fn(() => ({})),
    book_append_sheet: vi.fn(),
  },
  writeFile: vi.fn(),
}));

import { generateWhatsAppText, exportToExcel } from './report';
import * as XLSX from 'xlsx';

const totals = {
  primeirasReunioesRealizadas: 5,
  segundasReunioesRealizadas: 3,
  terceirasReunioesRealizadas: 1,
  referencias: 2,
  contactos: 20,
  primeirasReunioesMarcadas: 8,
  segundasReunioesMarcadas: 4,
  terceirasReunioesMarcadas: 2,
  pesquisas: 10,
};

const extra = {
  contratosFechados: 2,
  valorTotalFechos: 1500.3,
  pessoasSeguras: 4,
  reunioes1aProxSemana: 3,
  reunioes2aProxSemana: 2,
  reunioes3aProxSemana: 1,
};

describe('generateWhatsAppText', () => {
  it('formata as datas do cabeçalho em DD/MM/YYYY', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('21/04/2026');
    expect(text).toContain('27/04/2026');
  });

  it('cabeçalho usa negrito markdown (*data - data*)', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text.startsWith('*21/04/2026 - 27/04/2026*')).toBe(true);
  });

  it('inclui totais de 1as, 2as e 3as reuniões realizadas', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('1.ªR 5');
    expect(text).toContain('2.ªR 3');
    expect(text).toContain('3.ªR 1');
  });

  it('inclui contratos e referências', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('Contratos 2');
    expect(text).toContain('Referências 2');
  });

  it('arredonda valorTotalFechos para cima (Math.ceil)', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('Valor 1501€');
  });

  it('não arredonda quando o valor já é inteiro', () => {
    const text = generateWhatsAppText(totals, { ...extra, valorTotalFechos: 2000 }, '2026-04-21', '2026-04-27');
    expect(text).toContain('Valor 2000€');
  });

  it('inclui pessoas seguras', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('Pessoas seguras 4');
  });

  it('pessoasSeguras em falta usa 0 como default', () => {
    const { pessoasSeguras: _, ...extraSemPS } = extra;
    const text = generateWhatsAppText(totals, extraSemPS, '2026-04-21', '2026-04-27');
    expect(text).toContain('Pessoas seguras 0');
  });

  it('inclui reuniões da próxima semana', () => {
    const text = generateWhatsAppText(totals, extra, '2026-04-21', '2026-04-27');
    expect(text).toContain('1.ª- 3');
    expect(text).toContain('2.ª- 2');
    expect(text).toContain('3.ª- 1');
  });

  it('reuniões próxima semana em falta usam 0 como default', () => {
    const { reunioes1aProxSemana: _1, reunioes2aProxSemana: _2, reunioes3aProxSemana: _3, ...extraSem } = extra;
    const text = generateWhatsAppText(totals, extraSem, '2026-04-21', '2026-04-27');
    expect(text).toContain('1.ª- 0');
    expect(text).toContain('2.ª- 0');
    expect(text).toContain('3.ª- 0');
  });
});

describe('exportToExcel', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  const summaries = [
    {
      weekStart: '2026-04-14',
      weekEnd: '2026-04-20',
      totals: { ...totals },
      extra: { ...extra },
    },
    {
      weekStart: '2026-04-21',
      weekEnd: '2026-04-27',
      totals: { ...totals, primeirasReunioesRealizadas: 7 },
      extra: { ...extra, contratosFechados: 3 },
    },
  ];

  it('chama XLSX.writeFile com o nome correto', () => {
    exportToExcel(summaries);
    expect(XLSX.writeFile).toHaveBeenCalledWith(expect.anything(), 'historico_vendas.xlsx');
  });

  it('cria uma linha por semana', () => {
    exportToExcel(summaries);
    const rows = XLSX.utils.json_to_sheet.mock.calls[0][0];
    expect(rows).toHaveLength(2);
  });

  it('cada linha tem a coluna "Semana (início)"', () => {
    exportToExcel(summaries);
    const rows = XLSX.utils.json_to_sheet.mock.calls[0][0];
    expect(rows[0]).toHaveProperty('Semana (início)', '2026-04-14');
  });

  it('usa 0 quando extra está em falta', () => {
    exportToExcel([{ weekStart: '2026-04-14', weekEnd: '2026-04-20', totals: { ...totals }, extra: undefined }]);
    const rows = XLSX.utils.json_to_sheet.mock.calls[0][0];
    expect(rows[0]['Contratos Fechados']).toBe(0);
    expect(rows[0]['Valor Fechos (€)']).toBe(0);
  });
});
