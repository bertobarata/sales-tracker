import { useState, useEffect } from 'react';
import { saveDailyEntry, loadRemoteEntries, getWeekDates } from '../utils/storage';
import { subscribeDailyEntries } from '../utils/sync';
import { getSettings } from '../utils/settings';
import NumPad from './NumPad';
import Sheet from './Sheet';
import { useCoarsePointer } from '../utils/useCoarsePointer';
import { IconClock } from './Icons';

function isPastReminderTime() {
  const { reminderTime } = getSettings();
  const [h, m] = (reminderTime || '18:30').split(':').map(Number);
  const now = new Date();
  return now.getHours() > h || (now.getHours() === h && now.getMinutes() >= m);
}

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
  const isTouch = useCoarsePointer();
  const today = localDateStr(new Date());

  const [weekOffset, setWeekOffset] = useState(0); // 0 = semana atual
  const [prevWeekOffset, setPrevWeekOffset] = useState(0);
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

  // Quando a semana muda, reposiciona selectedDate durante o render
  // (padrão React para reset de state derivado — evita useEffect em cascata)
  if (prevWeekOffset !== weekOffset) {
    setPrevWeekOffset(weekOffset);
    setSelectedDate(isCurrentWeek ? today : weekStart);
    setDone(false);
    setAlreadySaved(false);
  }

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
        <button
          type="button"
          className="week-nav-btn"
          aria-label="Semana anterior"
          onClick={() => setWeekOffset(o => o + 1)}
        ><span aria-hidden="true">‹</span></button>
        <div className="week-nav-label">
          <span className="week-range">{isCurrentWeek ? 'Esta semana' : fmt(weekStart)}</span>
        </div>
        <button
          type="button"
          className="week-nav-btn"
          aria-label="Semana seguinte"
          onClick={() => setWeekOffset(o => o - 1)}
          disabled={isCurrentWeek}
        ><span aria-hidden="true">›</span></button>
      </div>
      {!isCurrentWeek && (
        <button type="button" className="btn-hoje" onClick={() => setWeekOffset(0)}>
          Hoje →
        </button>
      )}
      <div className="day-selector">
        {weekDays.map((d, i) => {
          const isFuture = d > today;
          return (
            <button
              key={d}
              type="button"
              className={`day-sel-btn${d === selectedDate ? ' active' : ''}${d === today ? ' today' : ''}${isFuture ? ' future' : ''}`}
              onClick={() => !isFuture && handleDaySelect(d)}
              disabled={isFuture}
              aria-current={d === selectedDate ? 'date' : undefined}
              aria-label={`${DAY_LABELS[i]}, ${fmt(d)}${isFuture ? ' (ainda não aconteceu)' : ''}`}
            >
              <span aria-hidden="true">{DAY_LABELS[i]}</span>
              <span className="day-sel-num" aria-hidden="true">{d.split('-')[2]}</span>
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
        <button type="button" className="btn-secondary" onClick={handleEdit}>Editar</button>
      </div>
    );
  }

  return (
    <>
      {!done && isToday && isPastReminderTime() && (
        <p className="reminder-banner">
          <IconClock />
          Ainda não registaste o dia de hoje.
        </p>
      )}
      <div className="card daily-card">
        {weekNavBlock}

        <h2>{fmt(selectedDate)}{isToday ? ' — Hoje' : ''}</h2>
        <p className="subtitle">Preenche os dados do dia</p>
        <div className="stepper-list">
          {FIELDS.map(f => (
            <div key={f.key} className="stepper-row">
              <span className="stepper-label" id={`lbl-${f.key}`}>{f.label}</span>
              <div className="stepper-control">
                <button
                  type="button"
                  className="stepper-btn"
                  aria-label={`Menos um: ${f.label}`}
                  onClick={() => adjust(f.key, -1)}
                ><span aria-hidden="true">−</span></button>
                {isTouch ? (
                  <button
                    type="button"
                    className="stepper-value"
                    aria-label={`${f.label}: ${values[f.key] ?? 0}. Tocar para escrever.`}
                    onClick={() => openNumpad(f.key)}
                  >
                    {values[f.key] ?? 0}
                  </button>
                ) : (
                  <input
                    type="number"
                    min="0"
                    className="stepper-value stepper-input"
                    aria-labelledby={`lbl-${f.key}`}
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
                  aria-label={`Mais um: ${f.label}`}
                  onClick={() => adjust(f.key, 1)}
                ><span aria-hidden="true">+</span></button>
              </div>
            </div>
          ))}
        </div>
        <button type="button" className="btn-primary card-action" onClick={handleSave}>Guardar</button>
      </div>

      {activeField && (
        <Sheet
          title={FIELDS.find(f => f.key === activeField)?.label}
          onClose={closeNumpad}
        >
          <NumPad
            value={numpadInput}
            onChange={setNumpadInput}
            onConfirm={confirmNumpad}
            confirmLabel="OK"
          />
        </Sheet>
      )}
    </>
  );
}
