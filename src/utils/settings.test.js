import { describe, it, expect, beforeEach } from 'vitest';
import { getSettings, saveSettings } from './settings';

beforeEach(() => localStorage.clear());

describe('getSettings', () => {
  it('devolve os defaults quando não há nada guardado', () => {
    const s = getSettings();
    expect(s.goalPrimeirasReunioesRealizadas).toBe(10);
    expect(s.goalSegundasReunioesRealizadas).toBe(8);
    expect(s.goalMensalValor).toBe(5000);
    expect(s.reminderTime).toBe('18:30');
  });

  it('devolve valor guardado em sobreposição ao default', () => {
    saveSettings({ goalMensalValor: 8000 });
    expect(getSettings().goalMensalValor).toBe(8000);
  });

  it('mantém os defaults para campos não sobrescritos', () => {
    saveSettings({ reminderTime: '19:00' });
    const s = getSettings();
    expect(s.goalPrimeirasReunioesRealizadas).toBe(10); // default mantido
    expect(s.reminderTime).toBe('19:00'); // sobrescrito
  });
});

describe('saveSettings', () => {
  it('persiste as settings no localStorage', () => {
    saveSettings({ goalMensalValor: 3000, reminderTime: '20:00' });
    const s = getSettings();
    expect(s.goalMensalValor).toBe(3000);
    expect(s.reminderTime).toBe('20:00');
  });
});
