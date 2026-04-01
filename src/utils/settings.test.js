import { beforeEach, describe, expect, it } from 'vitest';
import { getSettings, saveSettings } from './settings';

beforeEach(() => {
  localStorage.clear();
});

const DEFAULTS = {
  goalPrimeirasReunioesRealizadas: 10,
  goalSegundasReunioesRealizadas: 8,
  goalMensalValor: 5000,
  reminderTime: '18:30',
};

describe('getSettings', () => {
  it('returns all defaults when nothing is stored', () => {
    expect(getSettings()).toEqual(DEFAULTS);
  });

  it('overrides defaults with stored values', () => {
    localStorage.setItem(
      'salestracker_settings',
      JSON.stringify({ goalPrimeirasReunioesRealizadas: 15, reminderTime: '17:00' }),
    );
    const settings = getSettings();
    expect(settings.goalPrimeirasReunioesRealizadas).toBe(15);
    expect(settings.reminderTime).toBe('17:00');
    // Untouched defaults are preserved
    expect(settings.goalSegundasReunioesRealizadas).toBe(8);
    expect(settings.goalMensalValor).toBe(5000);
  });

  it('returns defaults when stored JSON is corrupt', () => {
    localStorage.setItem('salestracker_settings', 'not-json');
    expect(getSettings()).toEqual(DEFAULTS);
  });

  it('returns defaults when stored value is empty object', () => {
    localStorage.setItem('salestracker_settings', '{}');
    expect(getSettings()).toEqual(DEFAULTS);
  });
});

describe('saveSettings', () => {
  it('persists settings to localStorage', () => {
    const custom = { ...DEFAULTS, goalMensalValor: 8000, reminderTime: '09:00' };
    saveSettings(custom);
    const stored = JSON.parse(localStorage.getItem('salestracker_settings'));
    expect(stored).toEqual(custom);
  });

  it('round-trips correctly through getSettings', () => {
    const custom = {
      goalPrimeirasReunioesRealizadas: 12,
      goalSegundasReunioesRealizadas: 9,
      goalMensalValor: 6000,
      reminderTime: '08:00',
    };
    saveSettings(custom);
    expect(getSettings()).toEqual(custom);
  });
});
