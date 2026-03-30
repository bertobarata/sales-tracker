import { useState, useEffect } from 'react';
import { saveDailyEntry, loadRemoteEntries } from '../utils/storage';
import { subscribeDailyEntries } from '../utils/sync';
import { getSettings } from '../utils/settings';
import NumPad from './NumPad';

function isPastReminderTime() {
  const { reminderTime } = getSettings();
  const [h, m] = (reminderTime || '18:30').split(':').map(Number);
  const now = new Date();
  return now.getHours() > h || (now.getHours() === h && now.getMinutes() >= m);
}

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

const FIELDS = [
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

const EMPTY = Object.fromEntries(FIELDS.map(f => [f.key, 0]));

export default function DailyInput({ uid }) {
  const today = new Date().toISOString().split('T')[0];
  const [values, setValues] = useState(EMPTY);
  const [done, setDone] = useState(false);
  const [alreadySaved, setAlreadySaved] = useState(false);
  const [activeField, setActiveField] = useState(null);
  const [numpadInput, setNumpadInput] = useState('');

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

  function adjust(key, delta) {
    setValues(v => ({ ...v, [key]: Math.max(0, (v[key] || 0) + delta) }));
  }

  function openNumpad(key) {
    setActiveField(key);
    setNumpadInput(values[key] > 0 ? String(values[key]) : '');
  }

  function confirmNumpad() {
    const val = parseInt(numpadInput || '0', 10);
    setValues(v => ({ ...v, [activeField]: isNaN(val) ? 0 : Math.max(0, val) }));
    setActiveField(null);
    setNumpadInput('');
  }

  function closeNumpad() {
    setActiveField(null);
    setNumpadInput('');
  }

  function handleSave() {
    const entry = { date: today, ...values };
    saveDailyEntry(entry, uid);
    setDone(true);
  }

  function handleEdit() {
    setDone(false);
    setAlreadySaved(false);
  }

  const fmt = (d) => d.split('-').reverse().join('/');

  if (done) {
    return (
      <div className="card">
        <h2>{fmt(today)}</h2>
        <p className="subtitle">Registo {alreadySaved ? 'sincronizado' : 'guardado'}.</p>
        <div className="summary-grid">
          {FIELDS.map(f => (
            <div key={f.key} className="summary-item">
              <span className="summary-label">{f.label}</span>
              <span className="summary-value">{values[f.key] ?? 0}</span>
            </div>
          ))}
        </div>
        <button className="btn-secondary" onClick={handleEdit}>Editar</button>
      </div>
    );
  }

  return (
    <>
      {!done && isPastReminderTime() && (
        <div className="reminder-banner">
          Não te esqueças de registar o teu dia! ⏰
        </div>
      )}
      <div className="card daily-card">
        <h2>{fmt(today)}</h2>
        <p className="subtitle">Preenche os dados do dia</p>
        <div className="stepper-list">
          {FIELDS.map(f => (
            <div key={f.key} className="stepper-row">
              <span className="stepper-label">{f.label}</span>
              <div className="stepper-control">
                <button
                  type="button"
                  className="stepper-btn"
                  onClick={() => adjust(f.key, -1)}
                >−</button>
                {isMobile ? (
                  <button
                    type="button"
                    className="stepper-value"
                    onClick={() => openNumpad(f.key)}
                  >
                    {values[f.key] ?? 0}
                  </button>
                ) : (
                  <input
                    type="number"
                    min="0"
                    className="stepper-value stepper-input"
                    value={values[f.key] ?? 0}
                    onChange={e => {
                      const val = parseInt(e.target.value, 10);
                      setValues(v => ({ ...v, [f.key]: isNaN(val) ? 0 : Math.max(0, val) }));
                    }}
                  />
                )}
                <button
                  type="button"
                  className="stepper-btn"
                  onClick={() => adjust(f.key, 1)}
                >+</button>
              </div>
            </div>
          ))}
        </div>
        <button className="btn-primary" style={{ marginTop: 8 }} onClick={handleSave}>Guardar</button>
      </div>

      {activeField && (
        <div className="numpad-overlay" onClick={e => { if (e.target === e.currentTarget) closeNumpad(); }}>
          <div className="numpad-sheet">
            <p className="numpad-sheet-label">{FIELDS.find(f => f.key === activeField)?.label}</p>
            <NumPad
              value={numpadInput}
              onChange={setNumpadInput}
              onConfirm={confirmNumpad}
              confirmLabel="OK"
            />
          </div>
        </div>
      )}
    </>
  );
}
