import { useState, useEffect } from 'react';
import { saveDailyEntry, loadRemoteEntries, getWeekDates } from '../utils/storage';
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

const DAY_LABELS = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

// Retorna os 7 dias da semana (seg–dom) como strings YYYY-MM-DD
function getWeekDayStrings(weekStart) {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(weekStart + 'T00:00:00');
    d.setDate(d.getDate() + i);
    const y = d.getFullYear();
    const mo = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${mo}-${day}`;
  });
}

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

// Formata Date como YYYY-MM-DD em hora local
function localDateStr(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export default function DailyInput({ uid }) {
  const today = localDateStr(new Date());

  const [weekOffset, setWeekOffset] = useState(0); // 0 = semana atual
  const [selectedDate, setSelectedDate] = useState(today);
  const [values, setValues] = useState(EMPTY);
  const [done, setDone] = useState(false);
  const [alreadySaved, setAlreadySaved] = useState(false);
  const [activeField, setActiveField] = useState(null);
  const [numpadInput, setNumpadInput] = useState('');

  // Calcula os dias da semana visível
  const offsetDate = new Date();
  offsetDate.setDate(offsetDate.getDate() - weekOffset * 7);
  const { start: weekStart } = getWeekDates(offsetDate);
  const weekDays = getWeekDayStrings(weekStart);
  const isCurrentWeek = weekOffset === 0;

  // Quando a semana muda, reposiciona selectedDate:
  // se a semana atual, volta a hoje; caso contrário, vai para a segunda
  useEffect(() => {
    setSelectedDate(isCurrentWeek ? today : weekStart);
    setDone(false);
    setAlreadySaved(false);
  }, [weekOffset]);

  // Quando selectedDate muda, carrega os dados desse dia (se existirem)
  useEffect(() => {
    const unsub = subscribeDailyEntries(uid, (remoteEntries) => {
      loadRemoteEntries(remoteEntries);
      const existing = remoteEntries.find(e => e.date === selectedDate);
      if (existing) {
        setValues(existing);
        setDone(true);
        setAlreadySaved(true);
      } else {
        setValues(EMPTY);
        setDone(false);
        setAlreadySaved(false);
      }
    });
    return unsub;
  }, [uid, selectedDate]);

  function handleDaySelect(date) {
    setSelectedDate(date);
    setDone(false);
    setAlreadySaved(false);
  }

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
    const entry = { date: selectedDate, ...values };
    saveDailyEntry(entry, uid);
    setDone(true);
  }

  function handleEdit() {
    setDone(false);
    setAlreadySaved(false);
  }

  const fmt = (d) => d.split('-').reverse().join('/');
  const isToday = selectedDate === today;

  // Bloco de nav de semana + seletor de dia (reutilizado em ambas as vistas)
  const weekNavBlock = (
    <>
      <div className="week-nav">
        <button className="week-nav-btn" onClick={() => setWeekOffset(o => o + 1)}>‹</button>
        <div className="week-nav-label">
          <span className="week-range">{isCurrentWeek ? 'Esta semana' : fmt(weekStart)}</span>
        </div>
        <button
          className="week-nav-btn"
          onClick={() => setWeekOffset(o => o - 1)}
          disabled={isCurrentWeek}
          style={{ opacity: isCurrentWeek ? 0.2 : 1 }}
        >›</button>
      </div>
      {!isCurrentWeek && (
        <button className="btn-hoje" onClick={() => setWeekOffset(0)}>
          Hoje →
        </button>
      )}
      <div className="day-selector">
        {weekDays.map((d, i) => {
          const isFuture = d > today;
          return (
            <button
              key={d}
              className={`day-sel-btn${d === selectedDate ? ' active' : ''}${d === today ? ' today' : ''}${isFuture ? ' future' : ''}`}
              onClick={() => !isFuture && handleDaySelect(d)}
              disabled={isFuture}
              title={fmt(d)}
            >
              {DAY_LABELS[i]}
              <span className="day-sel-num">{d.split('-')[2]}</span>
            </button>
          );
        })}
      </div>
    </>
  );

  if (done) {
    return (
      <div className="card">
        {weekNavBlock}
        <h2>{fmt(selectedDate)}{isToday ? ' — Hoje' : ''}</h2>
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
      {!done && isToday && isPastReminderTime() && (
        <div className="reminder-banner">
          Não te esqueças de registar o teu dia! ⏰
        </div>
      )}
      <div className="card daily-card">
        {weekNavBlock}

        <h2>{fmt(selectedDate)}{isToday ? ' — Hoje' : ''}</h2>
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
