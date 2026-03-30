const SETTINGS_KEY = 'salestracker_settings';

const DEFAULTS = {
  goalPrimeirasReunioesRealizadas: 10,
  goalSegundasReunioesRealizadas: 8,
  goalMensalValor: 5000,
  reminderTime: '18:30',
};

export function getSettings() {
  try {
    const stored = JSON.parse(localStorage.getItem(SETTINGS_KEY) || '{}');
    return { ...DEFAULTS, ...stored };
  } catch {
    return { ...DEFAULTS };
  }
}

export function saveSettings(settings) {
  localStorage.setItem(SETTINGS_KEY, JSON.stringify(settings));
}
