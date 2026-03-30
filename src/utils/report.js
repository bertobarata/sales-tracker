import * as XLSX from 'xlsx';

export function generateWhatsAppText(totals, extra, weekStart, weekEnd) {
  const fmt = (d) => d.split('-').reverse().join('/');
  return (
    `*${fmt(weekStart)} - ${fmt(weekEnd)}*\n\n` +
    `1.ªR ${totals.primeirasReunioesRealizadas}\n` +
    `2.ªR ${totals.segundasReunioesRealizadas}\n` +
    `3.ªR ${totals.terceirasReunioesRealizadas}\n` +
    `Contratos ${extra.contratosFechados}\n` +
    `Valor ${Math.ceil(extra.valorTotalFechos)}€\n` +
    `Referências ${totals.referencias}\n` +
    `Pessoas seguras ${extra.pessoasSeguras ?? 0}\n\n` +
    `P. Semana\n` +
    `1.ª- ${extra.reunioes1aProxSemana ?? 0}\n` +
    `2.ª- ${extra.reunioes2aProxSemana ?? 0}\n` +
    `3.ª- ${extra.reunioes3aProxSemana ?? 0}`
  );
}

export function exportToExcel(weeklySummaries) {
  const rows = weeklySummaries.map(s => ({
    'Semana (início)': s.weekStart,
    'Semana (fim)': s.weekEnd,
    'Contactos': s.totals.contactos,
    '1as Marcadas': s.totals.primeirasReunioesMarcadas,
    '2as Marcadas': s.totals.segundasReunioesMarcadas,
    '3as Marcadas': s.totals.terceirasReunioesMarcadas,
    '1as Realizadas': s.totals.primeirasReunioesRealizadas,
    '2as Realizadas': s.totals.segundasReunioesRealizadas,
    '3as Realizadas': s.totals.terceirasReunioesRealizadas,
    'Pesquisas': s.totals.pesquisas,
    'Referências': s.totals.referencias,
    'Contratos Fechados': s.extra?.contratosFechados || 0,
    'Valor Fechos (€)': s.extra?.valorTotalFechos || 0,
    'Pessoas Seguras': s.extra?.pessoasSeguras || 0,
    '1ª Próxima Semana': s.extra?.reunioes1aProxSemana || 0,
    '2ª Próxima Semana': s.extra?.reunioes2aProxSemana || 0,
    '3ª Próxima Semana': s.extra?.reunioes3aProxSemana || 0,
  }));

  const ws = XLSX.utils.json_to_sheet(rows);
  const wb = XLSX.utils.book_new();
  XLSX.utils.book_append_sheet(wb, ws, 'Histórico');

  // Column widths
  ws['!cols'] = [
    { wch: 15 }, { wch: 15 }, { wch: 12 }, { wch: 13 }, { wch: 13 },
    { wch: 13 }, { wch: 14 }, { wch: 14 }, { wch: 14 }, { wch: 12 },
    { wch: 13 }, { wch: 18 }, { wch: 17 }, { wch: 16 }, { wch: 18 }, { wch: 18 }, { wch: 18 },
  ];

  XLSX.writeFile(wb, 'historico_vendas.xlsx');
}
