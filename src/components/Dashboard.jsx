import { useEffect, useState } from 'react';
import { getWeekDates, getEntriesForWeek, sumWeekEntries, loadRemoteEntries, getMonthlyValorTotal, formatWeekLabel } from '../utils/storage';
import { subscribeDailyEntries } from '../utils/sync';
import { getSettings } from '../utils/settings';

const DAY_LABELS = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];

function getWeekDays(start) {
  return Array.from({ length: 7 }, (_, i) => {
    const d = new Date(start + 'T00:00:00');
    d.setDate(d.getDate() + i);
    const y = d.getFullYear();
    const m = String(d.getMonth() + 1).padStart(2, '0');
    const day = String(d.getDate()).padStart(2, '0');
    return `${y}-${m}-${day}`;
  });
}

function GoalBar({ label, value, goal }) {
  const pct = Math.min(100, Math.round((value / goal) * 100));
  const done = value >= goal;
  return (
    <div className="goal-item">
      <div className="goal-header">
        <span className="goal-label">{label}</span>
        <span className={`goal-count ${done ? 'goal-done' : ''}`}>{value} / {goal}</span>
      </div>
      <div className="goal-bar">
        <div className="goal-fill" style={{ width: `${pct}%`, background: done ? 'var(--success)' : 'var(--primary)' }} />
      </div>
    </div>
  );
}

export default function Dashboard({ uid }) {
  const [_tick, setTick] = useState(0);
  const [weekOffset, setWeekOffset] = useState(0); // 0 = current week, 1 = last week, etc.

  useEffect(() => {
    const unsub = subscribeDailyEntries(uid, (remote) => {
      loadRemoteEntries(remote);
      setTick(t => t + 1);
    });
    return unsub;
  }, [uid]);

  const settings = getSettings();
  const GOALS = {
    primeirasReunioesRealizadas: settings.goalPrimeirasReunioesRealizadas,
    segundasReunioesRealizadas: settings.goalSegundasReunioesRealizadas,
  };
  const MONTHLY_VALOR_GOAL = settings.goalMensalValor;

  const offsetDate = new Date();
  offsetDate.setDate(offsetDate.getDate() - weekOffset * 7);
  const { start, end } = getWeekDates(offsetDate);
  const weekDays = getWeekDays(start);

  const entries = getEntriesForWeek(start, end);
  const totals = sumWeekEntries(entries);

  const now = new Date();
  const monthlyValor = getMonthlyValorTotal(now.getFullYear(), now.getMonth() + 1);
  const monthlyValorLeft = Math.max(0, MONTHLY_VALOR_GOAL - monthlyValor);

  const entryByDate = {};
  entries.forEach(e => { entryByDate[e.date] = e; });

  const fmt = (d) => d.split('-').reverse().slice(0, 2).join('/');
  const today = new Date().toISOString().split('T')[0];
  const isCurrentWeek = weekOffset === 0;

  return (
    <div>
      {/* Semana + dias */}
      <div className="card">
        <div className="dashboard-week">
          <div className="week-nav">
            <button className="week-nav-btn" onClick={() => setWeekOffset(o => o + 1)}>‹</button>
            <div className="week-nav-label">
              {isCurrentWeek ? <h2>Esta Semana</h2> : <h2>{fmt(start)} — {fmt(end)}</h2>}
              <span className="week-range">{formatWeekLabel(start, end)}</span>
            </div>
            <button
              className="week-nav-btn"
              onClick={() => setWeekOffset(o => o - 1)}
              disabled={isCurrentWeek}
              style={{ opacity: isCurrentWeek ? 0.2 : 1 }}
            >›</button>
          </div>
          {!isCurrentWeek && (
            <button className="btn-week-current" onClick={() => setWeekOffset(0)}>
              Esta semana →
            </button>
          )}
        </div>
        <div className="day-strip">
          {weekDays.map((d, i) => (
            <div key={d} className={`day-dot ${entryByDate[d] ? 'filled' : ''} ${d === today ? 'day-today' : ''}`}>
              {DAY_LABELS[i]}
              <span className="day-num">{entryByDate[d] ? entryByDate[d].contactos ?? '✓' : '—'}</span>
            </div>
          ))}
        </div>
      </div>

      {/* Objetivos semanais */}
      <p className="section-label">Objetivos</p>
      <div className="card">
        <GoalBar
          label="1as Reuniões"
          value={totals.primeirasReunioesRealizadas}
          goal={GOALS.primeirasReunioesRealizadas}
        />
        <GoalBar
          label="2as Reuniões"
          value={totals.segundasReunioesRealizadas}
          goal={GOALS.segundasReunioesRealizadas}
        />
      </div>

      {/* Objetivo mensal */}
      <p className="section-label">Objetivo Mensal</p>
      <div className="card">
        <GoalBar
          label="Valor fechos"
          value={Math.ceil(monthlyValor)}
          goal={MONTHLY_VALOR_GOAL}
        />
        {monthlyValorLeft > 0 ? (
          <p className="goal-remaining">Faltam <strong>{Math.ceil(monthlyValorLeft).toLocaleString('pt-PT')}€</strong> para o objetivo</p>
        ) : (
          <p className="goal-remaining goal-reached">Objetivo mensal atingido!</p>
        )}
      </div>

      {/* Reuniões */}
      <p className="section-label">Reuniões realizadas</p>
      <div className="card">
        <div className="metrics-grid">
          <div className="metric-card">
            <div className="metric-label">1as</div>
            <div className="metric-value">{totals.primeirasReunioesRealizadas}</div>
            <div className="metric-sub">{totals.primeirasReunioesMarcadas} marcadas</div>
          </div>
          <div className="metric-card">
            <div className="metric-label">2as</div>
            <div className="metric-value">{totals.segundasReunioesRealizadas}</div>
            <div className="metric-sub">{totals.segundasReunioesMarcadas} marcadas</div>
          </div>
          <div className="metric-card">
            <div className="metric-label">3as</div>
            <div className="metric-value">{totals.terceirasReunioesRealizadas}</div>
            <div className="metric-sub">{totals.terceirasReunioesMarcadas} marcadas</div>
          </div>
          <div className="metric-card">
            <div className="metric-label">Contactos</div>
            <div className="metric-value">{totals.contactos}</div>
          </div>
        </div>
      </div>

      {/* Prospeção */}
      <p className="section-label">Prospeção</p>
      <div className="card">
        <div className="metrics-grid">
          <div className="metric-card">
            <div className="metric-label">Pesquisas</div>
            <div className="metric-value">{totals.pesquisas}</div>
          </div>
          <div className="metric-card">
            <div className="metric-label">Referências</div>
            <div className="metric-value">{totals.referencias}</div>
          </div>
        </div>
      </div>
    </div>
  );
}
