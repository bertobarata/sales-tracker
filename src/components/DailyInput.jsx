import { useState, useEffect, useRef } from 'react';
import { saveDailyEntry, loadRemoteEntries } from '../utils/storage';
import { subscribeDailyEntries } from '../utils/sync';
import NumPad from './NumPad';

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

const QUESTIONS = [
  { key: 'contactos', label: 'Contactos efetuados' },
  { key: 'primeirasReunioesMarcadas', label: '1as reuniões marcadas' },
  { key: 'segundasReunioesMarcadas', label: '2as reuniões marcadas' },
  { key: 'terceirasReunioesMarcadas', label: '3as reuniões marcadas' },
  { key: 'primeirasReunioesRealizadas', label: '1as reuniões realizadas' },
  { key: 'segundasReunioesRealizadas', label: '2as reuniões realizadas' },
  { key: 'terceirasReunioesRealizadas', label: '3as reuniões realizadas' },
  { key: 'pesquisas', label: 'Pesquisas efetuadas' },
  { key: 'referencias', label: 'Referências obtidas' },
];

export default function DailyInput({ uid }) {
  const today = new Date().toISOString().split('T')[0];
  const [step, setStep] = useState(0);
  const [values, setValues] = useState({});
  const [input, setInput] = useState('');
  const [done, setDone] = useState(false);
  const [alreadySaved, setAlreadySaved] = useState(false);
  const inputRef = useRef(null);

  useEffect(() => {
    const unsub = subscribeDailyEntries(uid, (remoteEntries) => {
      loadRemoteEntries(remoteEntries);
      const existing = remoteEntries.find(e => e.date === today);
      if (existing) {
        setValues(existing);
        setDone(true);
        setAlreadySaved(true);
      }
    });
    return unsub;
  }, [uid, today]);

  useEffect(() => {
    if (!isMobile && !done) inputRef.current?.focus();
  }, [step, done]);

  function handleConfirm() {
    const val = parseInt(input || '0', 10);
    const key = QUESTIONS[step].key;
    const newValues = { ...values, [key]: val };
    setValues(newValues);
    setInput('');

    if (step + 1 < QUESTIONS.length) {
      setStep(step + 1);
    } else {
      const entry = { date: today, ...newValues };
      saveDailyEntry(entry, uid);
      setDone(true);
    }
  }

  function handleEdit() {
    setDone(false);
    setAlreadySaved(false);
    setStep(0);
    setInput('');
  }

  const fmt = (d) => d.split('-').reverse().join('/');

  if (done) {
    return (
      <div className="card">
        <h2>{fmt(today)}</h2>
        <p className="subtitle">Registo {alreadySaved ? 'sincronizado' : 'guardado'}.</p>
        <div className="summary-grid">
          {QUESTIONS.map(q => (
            <div key={q.key} className="summary-item">
              <span className="summary-label">{q.label}</span>
              <span className="summary-value">{values[q.key] ?? 0}</span>
            </div>
          ))}
        </div>
        <button className="btn-secondary" onClick={handleEdit}>Editar</button>
      </div>
    );
  }

  return (
    <div className="card daily-card">
      <div className="daily-header">
        <div className="progress-bar">
          <div className="progress-fill" style={{ width: `${(step / QUESTIONS.length) * 100}%` }} />
        </div>
        <p className="progress-text">{step + 1} / {QUESTIONS.length}</p>
      </div>

      <p className="question">{QUESTIONS[step].label}</p>

      {isMobile ? (
        <NumPad
          value={input}
          onChange={setInput}
          onConfirm={handleConfirm}
          confirmLabel={step + 1 < QUESTIONS.length ? 'Seguinte' : 'Guardar'}
        />
      ) : (
        <form onSubmit={(e) => { e.preventDefault(); handleConfirm(); }} className="desktop-input-row">
          <input
            ref={inputRef}
            type="number"
            min="0"
            value={input}
            onChange={e => setInput(e.target.value)}
            placeholder="0"
            className="desktop-number-input"
          />
          <button type="submit" className="btn-primary">
            {step + 1 < QUESTIONS.length ? 'Seguinte →' : 'Guardar'}
          </button>
        </form>
      )}

      {step > 0 && (
        <button className="btn-ghost" onClick={() => {
          setStep(step - 1);
          setInput(String(values[QUESTIONS[step - 1].key] ?? ''));
        }}>
          Anterior
        </button>
      )}
    </div>
  );
}
