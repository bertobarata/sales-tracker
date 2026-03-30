import { useState } from 'react';
import { getSettings, saveSettings } from '../utils/settings';

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
    <div className="settings-overlay" onClick={e => { if (e.target === e.currentTarget) onClose(); }}>
      <div className="settings-sheet">
        <div className="settings-header">
          <h2>Configurações</h2>
          <button className="settings-close" onClick={onClose}>✕</button>
        </div>

        <p className="section-label">Objetivos</p>
        <div className="stepper-list">
          {SETTING_FIELDS.map(f => {
            const step = f.step || 1;
            return (
              <div key={f.key} className="stepper-row">
                <span className="stepper-label">{f.label}</span>
                <div className="stepper-control">
                  <button
                    type="button"
                    className="stepper-btn"
                    onClick={() => adjust(f.key, -1, step)}
                  >−</button>
                  <span className="stepper-value" style={{ cursor: 'default' }}>
                    {values[f.key]}
                  </span>
                  <button
                    type="button"
                    className="stepper-btn"
                    onClick={() => adjust(f.key, 1, step)}
                  >+</button>
                </div>
              </div>
            );
          })}
        </div>

        <p className="section-label" style={{ marginTop: 16 }}>Lembretes</p>
        <div className="stepper-list">
          <div className="stepper-row">
            <span className="stepper-label">Hora do lembrete</span>
            <input
              type="time"
              className="time-input"
              value={values.reminderTime || '18:30'}
              onChange={e => setValues(v => ({ ...v, reminderTime: e.target.value }))}
            />
          </div>
        </div>

        <button className="btn-primary" style={{ marginTop: 20 }} onClick={handleSave}>
          {saved ? 'Guardado!' : 'Guardar'}
        </button>
      </div>
    </div>
  );
}
