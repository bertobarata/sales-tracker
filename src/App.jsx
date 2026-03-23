import { useState } from 'react';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import AuthGate from './components/AuthGate';
import DailyInput from './components/DailyInput';
import Dashboard from './components/Dashboard';
import WeeklyReport from './components/WeeklyReport';
import './App.css';

const TABS = [
  { id: 'hoje', label: 'Hoje', icon: '✏️' },
  { id: 'semana', label: 'Semana', icon: '📊' },
  { id: 'relatorio', label: 'Relatório', icon: '📋' },
];

const isMobile = /iPhone|iPad|iPod|Android/i.test(navigator.userAgent);

export default function App() {
  const [tab, setTab] = useState('hoje');

  return (
    <AuthGate>
      {(user) => (
        <div className="app">
          <header className="app-header">
            <span className="app-user">{user.displayName}</span>
            <h1>Sales Tracker</h1>
            <button className="btn-logout" onClick={() => signOut(auth)}>Sair</button>
          </header>

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
