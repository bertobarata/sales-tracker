import { useState } from 'react';
import { getSettings, saveSettings } from '../utils/settings';
import Sheet from './Sheet';
import { IconClose } from './Icons';

const SETTING_FIELDS = [
  { key: 'goalPrimeirasReunioesRealizadas', label: '1as Reuniões (objetivo semanal)', min: 1 },
  { key: 'goalSegundasReunioesRealizadas', label: '2as Reuniões (objetivo semanal)', min: 1 },
  { key: 'goalMensalValor', label: 'Valor fechos mensal (€)', min: 100, step: 100 },
];

export default function Settings({ onClose }) {
  const [values, setValues] = useState(() => getSettings());
  const [saved, setSaved] = useState(false);

  function adjust(key, delta, step = 1) {
    const min = SETTING_FIELDS.find(f => f.key === key)?.min ?? 0;
    setValues(v => ({ ...v, [key]: Math.max(min, (v[key] || 0) + delta * step) }));
  }

  function handleSave() {
    saveSettings(values);
    setSaved(true);
    setTimeout(() => {
      setSaved(false);
      onClose();
    }, 800);
  }

  return (
    <Sheet title="Configurações" onClose={onClose}>
      <button
        type="button"
        className="sheet-close"
        aria-label="Fechar configurações"
        onClick={onClose}
      >
        <IconClose />
      </button>

      <p className="section-label">Objetivos</p>
        <div className="stepper-list">
          {SETTING_FIELDS.map(f => {
            const step = f.step || 1;
            return (
              <div key={f.key} className="stepper-row">
                <span className="stepper-label" id={`set-${f.key}`}>{f.label}</span>
                <div className="stepper-control">
                  <button
                    type="button"
                    className="stepper-btn"
                    aria-label={`Diminuir ${f.label}`}
                    onClick={() => adjust(f.key, -1, step)}
                  ><span aria-hidden="true">−</span></button>
                  <output className="stepper-value stepper-readonly">
                    {values[f.key]}
                  </output>
                  <button
                    type="button"
                    className="stepper-btn"
                    aria-label={`Aumentar ${f.label}`}
                    onClick={() => adjust(f.key, 1, step)}
                  ><span aria-hidden="true">+</span></button>
                </div>
              </div>
            );
          })}
        </div>

        <p className="section-label" style={{ marginTop: 16 }}>Lembretes</p>
        <div className="stepper-list">
          <div className="stepper-row">
            <label className="stepper-label" htmlFor="reminder-time">Hora do lembrete</label>
            <input
              id="reminder-time"
              type="time"
              className="time-input"
              value={values.reminderTime || '18:30'}
              onChange={e => setValues(v => ({ ...v, reminderTime: e.target.value }))}
            />
          </div>
        </div>

      <button type="button" className="btn-primary sheet-action" onClick={handleSave}>
        {saved ? 'Guardado' : 'Guardar'}
      </button>
      <p className="visually-hidden" role="status">{saved ? 'Configurações guardadas' : ''}</p>
    </Sheet>
  );
}
