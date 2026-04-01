 import { useState } from 'react';
import { getWeekDates, getEntriesForWeek, sumWeekEntries, saveWeeklySummary, getWeeklySummaries } from '../utils/storage';
import { generateWhatsAppText, exportToExcel } from '../utils/report';
import NumPad from './NumPad';

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

const EXTRA_FIELDS = [
  { key: 'contratosFechados', label: 'Contratos fechados' },
  { key: 'valorTotalFechos', label: 'Valor total (€)' },
  { key: 'pessoasSeguras', label: 'Pessoas seguras' },
  { key: 'reunioes1aProxSemana', label: '1.ª próx. semana' },
  { key: 'reunioes2aProxSemana', label: '2.ª próx. semana' },
  { key: 'reunioes3aProxSemana', label: '3.ª próx. semana' },
];

const INITIAL_EXTRA = {
  contratosFechados: '', valorTotalFechos: '', pessoasSeguras: '',
  reunioes1aProxSemana: '', reunioes2aProxSemana: '', reunioes3aProxSemana: '',
};

export default function WeeklyReport({ uid }) {
  const { start, end } = getWeekDates();
  const entries = getEntriesForWeek(start, end);
  const totals = sumWeekEntries(entries);

  const [extra, setExtra] = useState(INITIAL_EXTRA);
  const [activeField, setActiveField] = useState(null); // mobile numpad field
  const [numpadVal, setNumpadVal] = useState('');
  const [copied, setCopied] = useState(false);
  const [saved, setSaved] = useState(false);

  const fmt = (d) => d.split('-').reverse().join('/');

  function setField(key, val) {
    setExtra(e => ({ ...e, [key]: val }));
    setCopied(false); setSaved(false);
  }

  // Mobile: open numpad for a field
  function openNumpad(key) {
    setActiveField(key);
    setNumpadVal(extra[key] || '');
  }

  function confirmNumpad() {
    setField(activeField, numpadVal);
    setActiveField(null);
  }

  function getExtraNumbers() {
    return {
      contratosFechados: parseInt(extra.contratosFechados) || 0,
      valorTotalFechos: parseFloat(extra.valorTotalFechos) || 0,
      pessoasSeguras: parseInt(extra.pessoasSeguras) || 0,
      reunioes1aProxSemana: parseInt(extra.reunioes1aProxSemana) || 0,
      reunioes2aProxSemana: parseInt(extra.reunioes2aProxSemana) || 0,
      reunioes3aProxSemana: parseInt(extra.reunioes3aProxSemana) || 0,
    };
  }

  function handleCopy() {
    const text = generateWhatsAppText(totals, getExtraNumbers(), start, end);
    navigator.clipboard.writeText(text).then(() => {
      setCopied(true); setTimeout(() => setCopied(false), 3000);
    });
  }

  function handleSave() {
    const summary = { weekStart: start, weekEnd: end, totals, extra: getExtraNumbers() };
    saveWeeklySummary(summary, uid);
    setSaved(true); setTimeout(() => setSaved(false), 3000);
  }

  const previewText = generateWhatsAppText(totals, getExtraNumbers(), start, end);

  // Mobile numpad overlay
  if (isMobile && activeField !== null) {
    const fieldLabel = EXTRA_FIELDS.find(f => f.key === activeField)?.label;
    return (
      <div className="card daily-card">
        <div className="daily-header">
          <p className="progress-text">Relatório — {fmt(start)}</p>
        </div>
        <p className="question">{fieldLabel}</p>
        <NumPad
          value={numpadVal}
          onChange={setNumpadVal}
          onConfirm={confirmNumpad}
          confirmLabel="Confirmar"
        />
        <button className="btn-ghost" onClick={() => setActiveField(null)}>Cancelar</button>
      </div>
    );
  }

  return (
    <div className="card">
      <h2>Relatório Semanal</h2>
      <p className="subtitle">{fmt(start)} — {fmt(end)}</p>

      <div className="report-totals">
        <h3>Totais da semana</h3>
        <div className="totals-grid">
          <div className="total-item"><span>1.ª R.</span><strong>{totals.primeirasReunioesRealizadas}</strong></div>
          <div className="total-item"><span>2.ª R.</span><strong>{totals.segundasReunioesRealizadas}</strong></div>
          <div className="total-item"><span>3.ª R.</span><strong>{totals.terceirasReunioesRealizadas}</strong></div>
          <div className="total-item"><span>Pesquisas</span><strong>{totals.pesquisas}</strong></div>
          <div className="total-item"><span>Refs.</span><strong>{totals.referencias}</strong></div>
        </div>
      </div>

      <div className="extra-fields">
        <h3>Esta semana</h3>
        {isMobile ? (
          <div className="field-row">
            {['contratosFechados', 'valorTotalFechos', 'pessoasSeguras'].map(key => {
              const f = EXTRA_FIELDS.find(f => f.key === key);
              return (
                <button key={key} className="field-tap" onClick={() => openNumpad(key)}>
                  <span className="field-tap-label">{f.label}</span>
                  <span className="field-tap-value">{extra[key] || '0'}</span>
                </button>
              );
            })}
          </div>
        ) : (
          <div className="field-row">
            <div className="field-group">
              <label>Contratos fechados</label>
              <input type="number" min="0" value={extra.contratosFechados} onChange={e => setField('contratosFechados', e.target.value)} placeholder="0" />
            </div>
            <div className="field-group">
              <label>Valor total (€)</label>
              <input type="number" min="0" value={extra.valorTotalFechos} onChange={e => setField('valorTotalFechos', e.target.value)} placeholder="0" />
            </div>
            <div className="field-group">
              <label>Pessoas seguras</label>
              <input type="number" min="0" value={extra.pessoasSeguras} onChange={e => setField('pessoasSeguras', e.target.value)} placeholder="0" />
            </div>
          </div>
        )}

        <h3>Próxima semana</h3>
        {isMobile ? (
          <div className="field-row three">
            {['reunioes1aProxSemana', 'reunioes2aProxSemana', 'reunioes3aProxSemana'].map((key, i) => (
              <button key={key} className="field-tap" onClick={() => openNumpad(key)}>
                <span className="field-tap-label">{i + 1}.ª</span>
                <span className="field-tap-value">{extra[key] || '0'}</span>
              </button>
            ))}
          </div>
        ) : (
          <div className="field-row three">
            {['reunioes1aProxSemana', 'reunioes2aProxSemana', 'reunioes3aProxSemana'].map((key, i) => (
              <div key={key} className="field-group">
                <label>{i + 1}.ª</label>
                <input type="number" min="0" value={extra[key]} onChange={e => setField(key, e.target.value)} placeholder="0" />
              </div>
            ))}
          </div>
        )}
      </div>

      <div className="preview-box">
        <pre>{previewText}</pre>
      </div>

      <div className="report-actions">
        <button className="btn-primary" onClick={handleCopy}>{copied ? 'Copiado!' : 'Copiar para WhatsApp'}</button>
        <button className="btn-secondary" onClick={handleSave}>{saved ? 'Guardado!' : 'Guardar semana'}</button>
        <button className="btn-ghost" onClick={handleExcel}>Exportar Excel</button>
      </div>
    </div>
  );

  function handleExcel() { exportToExcel(getWeeklySummaries()); }
}
