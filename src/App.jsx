import { useState, useEffect, useCallback } from 'react';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import AuthGate from './components/AuthGate';
import DailyInput from './components/DailyInput';
import Dashboard from './components/Dashboard';
import WeeklyReport from './components/WeeklyReport';
import Trends from './components/Trends';
import Settings from './components/Settings';
import { getDailyEntry } from './utils/storage';
import { getSettings } from './utils/settings';
import './App.css';

const NOTIF_DISMISSED_KEY = 'salestracker_notif_dismissed';

function scheduleReminderNotification() {
  if (typeof Notification === 'undefined' || Notification.permission !== 'granted') return;
  const { reminderTime } = getSettings();
  const [h, m] = (reminderTime || '18:30').split(':').map(Number);
  const now = new Date();
  const fireAt = new Date(now);
  fireAt.setHours(h, m, 0, 0);
  const ms = fireAt - now;
  if (ms <= 0) return; // already past for today
  return setTimeout(() => {
    const today = new Date().toISOString().split('T')[0];
    if (!getDailyEntry(today)) {
      new Notification('Sales Tracker', {
        body: 'Ainda não registaste o teu dia de hoje!',
        icon: '/icons/icon-192.png',
        tag: 'daily-reminder',
      });
    }
  }, ms);
}

const TABS = [
  { id: 'hoje', label: 'Hoje', icon: '✏️' },
  { id: 'semana', label: 'Semana', icon: '📊' },
  { id: 'relatorio', label: 'Relatório', icon: '📋' },
  { id: 'tendencias', label: 'Tendências', icon: '📈' },
];

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

export default function App() {
  const [tab, setTab] = useState('hoje');
  const [showSettings, setShowSettings] = useState(false);
  const [showNotifPrompt, setShowNotifPrompt] = useState(
    typeof Notification !== 'undefined' &&
    Notification.permission === 'default' &&
    !localStorage.getItem(NOTIF_DISMISSED_KEY)
  );

  // Schedule notification whenever settings change or app mounts
  const reschedule = useCallback(() => {
    const tid = scheduleReminderNotification();
    return () => { if (tid) clearTimeout(tid); };
  }, []);

  useEffect(reschedule, [reschedule]);

  function handleEnableNotifications() {
    Notification.requestPermission().then(perm => {
      setShowNotifPrompt(false);
      if (perm === 'granted') scheduleReminderNotification();
    });
  }

  function handleDismissNotifPrompt() {
    localStorage.setItem(NOTIF_DISMISSED_KEY, '1');
    setShowNotifPrompt(false);
  }

  return (
    <AuthGate>
      {(user) => (
        <div className="app">
          <header className="app-header">
            <span className="app-user">{user.displayName}</span>
            <h1>Sales Tracker</h1>
            <div style={{ display: 'flex', gap: 12, alignItems: 'center' }}>
              <button className="btn-logout" onClick={() => setShowSettings(true)}>⚙️</button>
              <button className="btn-logout" onClick={() => signOut(auth)}>Sair</button>
            </div>
          </header>
          {showSettings && <Settings onClose={() => { setShowSettings(false); reschedule(); }} />}

          {showNotifPrompt && (
            <div className="notif-prompt">
              <span>Ativar lembretes diários?</span>
              <div className="notif-prompt-actions">
                <button className="notif-btn-yes" onClick={handleEnableNotifications}>Ativar</button>
                <button className="notif-btn-no" onClick={handleDismissNotifPrompt}>Agora não</button>
              </div>
            </div>
          )}

          {!isMobile && (
            <nav className="tab-bar">
              {TABS.map(t => (
                <button key={t.id} className={`tab-btn ${tab === t.id ? 'active' : ''}`} onClick={() => setTab(t.id)}>
                  <span className="tab-icon">{t.icon}</span>
                  {t.label}
                </button>
              ))}
            </nav>
          )}

          <main className="app-main">
            {tab === 'hoje' && <DailyInput uid={user.uid} />}
            {tab === 'semana' && <Dashboard uid={user.uid} />}
            {tab === 'relatorio' && <WeeklyReport uid={user.uid} />}
            {tab === 'tendencias' && <Trends uid={user.uid} />}
          </main>

          {isMobile && (
            <nav className="tab-bar tab-bar-bottom">
              {TABS.map(t => (
                <button key={t.id} className={`tab-btn ${tab === t.id ? 'active' : ''}`} onClick={() => setTab(t.id)}>
                  <span className="tab-icon">{t.icon}</span>
                  {t.label}
                </button>
              ))}
            </nav>
          )}
        </div>
      )}
    </AuthGate>
  );
}
