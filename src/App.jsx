import { useState, useEffect, useCallback, lazy, Suspense } from 'react';
import { signOut } from 'firebase/auth';
import { auth } from './firebase';
import AuthGate from './components/AuthGate';
import DailyInput from './components/DailyInput';
import Dashboard from './components/Dashboard';
import WeeklyReport from './components/WeeklyReport';
import Settings from './components/Settings';
import { getDailyEntry } from './utils/storage';
import { getSettings } from './utils/settings';

// O recharts é a maior fatia do pacote e só serve este separador, que é o menos
// aberto. Carregado aqui, saía no arranque de quem só quer escrever os números do dia.
const Trends = lazy(() => import('./components/Trends'));

function TrendsSkeleton() {
  return (
    <div role="status">
      {/* As caixas cinzentas nao dizem nada a quem nao ve. A frase diz. */}
      <span className="visually-hidden">A carregar os gráficos de tendências</span>
      <div aria-hidden="true">
        {[0, 1, 2].map(i => (
          <div key={i} className="card">
            <div className="skeleton skeleton-label" />
            <div className="skeleton skeleton-chart" />
          </div>
        ))}
      </div>
    </div>
  );
}
import { useCoarsePointer } from './utils/useCoarsePointer';
import { IconToday, IconWeek, IconReport, IconTrends, IconSettings } from './components/Icons';
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
  { id: 'hoje', label: 'Hoje', Icon: IconToday },
  { id: 'semana', label: 'Semana', Icon: IconWeek },
  { id: 'relatorio', label: 'Relatório', Icon: IconReport },
  { id: 'tendencias', label: 'Tendências', Icon: IconTrends },
];

/**
 * Separadores com a semântica que um leitor de ecrã espera. Sem `role="tab"` e
 * `aria-selected`, o separador ativo distingue-se só por cor e borda — invisível
 * para quem não vê. As setas navegam entre separadores, como manda o padrão.
 */
function TabBar({ tab, setTab, className }) {
  function onKeyDown(e) {
    const i = TABS.findIndex(t => t.id === tab);
    let next = null;
    if (e.key === 'ArrowRight') next = TABS[(i + 1) % TABS.length];
    else if (e.key === 'ArrowLeft') next = TABS[(i - 1 + TABS.length) % TABS.length];
    else if (e.key === 'Home') next = TABS[0];
    else if (e.key === 'End') next = TABS[TABS.length - 1];
    if (!next) return;
    e.preventDefault();
    setTab(next.id);
    document.getElementById(`tab-${next.id}`)?.focus();
  }

  return (
    <div className={className} role="tablist" aria-label="Secções" onKeyDown={onKeyDown}>
      {TABS.map(t => {
        const active = tab === t.id;
        return (
          <button
            key={t.id}
            id={`tab-${t.id}`}
            role="tab"
            type="button"
            aria-selected={active}
            aria-controls="tabpanel"
            tabIndex={active ? 0 : -1}
            className={`tab-btn ${active ? 'active' : ''}`}
            onClick={() => setTab(t.id)}
          >
            <span className="tab-icon"><t.Icon /></span>
            {t.label}
          </button>
        );
      })}
    </div>
  );
}

export default function App() {
  const isTouch = useCoarsePointer();
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
          <a className="skip-link" href="#tabpanel">Saltar para o conteúdo</a>
          <header className="app-header">
            <span className="app-user">{user.displayName}</span>
            <h1>Sales Tracker</h1>
            <div className="app-header-actions">
              <button
                type="button"
                className="btn-icon"
                aria-label="Abrir configurações"
                onClick={() => setShowSettings(true)}
              >
                <IconSettings />
              </button>
              <button type="button" className="btn-logout" onClick={() => signOut(auth)}>Sair</button>
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

          {!isTouch && <TabBar tab={tab} setTab={setTab} className="tab-bar" />}

          {/* O painel e o marco sao elementos diferentes de proposito: um `role`
              explicito substitui o papel implicito, e `<main role="tabpanel">`
              fazia a pagina deixar de ter marco principal. */}
          <main className="app-main">
            <div
              id="tabpanel"
              role="tabpanel"
              aria-labelledby={`tab-${tab}`}
              tabIndex={-1}
            >
              {tab === 'hoje' && <DailyInput uid={user.uid} />}
              {tab === 'semana' && <Dashboard uid={user.uid} />}
              {tab === 'relatorio' && <WeeklyReport uid={user.uid} />}
              {tab === 'tendencias' && (
                <Suspense fallback={<TrendsSkeleton />}>
                  <Trends uid={user.uid} />
                </Suspense>
              )}
            </div>
          </main>

          {isTouch && <TabBar tab={tab} setTab={setTab} className="tab-bar tab-bar-bottom" />}
        </div>
      )}
    </AuthGate>
  );
}
