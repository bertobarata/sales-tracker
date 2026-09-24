import { useEffect, useState, useMemo } from 'react';
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
  const pct = goal > 0 ? Math.min(100, Math.round((value / goal) * 100)) : 0;
  const done = value >= goal;
  return (
    <div className="goal-item">
      <div className="goal-header">
        <span className="goal-label">{label}</span>
        {/* O estado de "atingido" nao pode viver so na cor: vai tambem no texto. */}
        <span className={`goal-count ${done ? 'goal-done' : ''}`}>
          {value} / {goal}{done ? ' ✓' : ''}
        </span>
      </div>
      <div
        className={`goal-bar ${done ? 'goal-bar-done' : ''}`}
        role="progressbar"
        aria-valuenow={value}
        aria-valuemin={0}
        aria-valuemax={goal}
        aria-label={`${label}: ${value} de ${goal}`}
      >
        <div className="goal-fill" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default function Dashboard({ uid }) {
  // Sobe a cada snapshot do Firestore: e o que invalida tudo o que se le do localStorage.
  const [version, setVersion] = useState(0);
  const [weekOffset, setWeekOffset] = useState(0); // 0 = semana atual, 1 = anterior, etc.

  useEffect(() => {
    const unsub = subscribeDailyEntries(uid, (remote) => {
      loadRemoteEntries(remote);
      setVersion(v => v + 1);
    });
    return unsub;
  }, [uid]);

  // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` e a chave de invalidacao do localStorage, nao um valor lido aqui dentro
  const settings = useMemo(() => getSettings(), [version]);
  const GOALS = {
    primeirasReunioesRealizadas: settings.goalPrimeirasReunioesRealizadas,
    segundasReunioesRealizadas: settings.goalSegundasReunioesRealizadas,
  };
  const MONTHLY_VALOR_GOAL = settings.goalMensalValor;

  const { start, end } = useMemo(() => {
    const offsetDate = new Date();
    offsetDate.setDate(offsetDate.getDate() - weekOffset * 7);
    return getWeekDates(offsetDate);
  }, [weekOffset]);

  const weekDays = useMemo(() => getWeekDays(start), [start]);

  // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` e a chave de invalidacao do localStorage, nao um valor lido aqui dentro
  const entries = useMemo(() => getEntriesForWeek(start, end), [start, end, version]);
  const totals = useMemo(() => sumWeekEntries(entries), [entries]);

  const monthlyValor = useMemo(() => {
    const now = new Date();
    return getMonthlyValorTotal(now.getFullYear(), now.getMonth() + 1);
  // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` e a chave de invalidacao do localStorage, nao um valor lido aqui dentro
  }, [version]);
  const monthlyValorLeft = Math.max(0, MONTHLY_VALOR_GOAL - monthlyValor);

  const entryByDate = useMemo(() => {
    const byDate = {};
    entries.forEach(e => { byDate[e.date] = e; });
    return byDate;
  }, [entries]);

  const fmt = (d) => d.split('-').reverse().slice(0, 2).join('/');
  const today = new Date().toISOString().split('T')[0];
  const isCurrentWeek = weekOffset === 0;

  return (
    <div>
      {/* Semana + dias */}
      <div className="card">
        <div className="dashboard-week">
          <div className="week-nav">
            <button
              type="button"
              className="week-nav-btn"
              aria-label="Semana anterior"
              onClick={() => setWeekOffset(o => o + 1)}
            ><span aria-hidden="true">‹</span></button>
            <div className="week-nav-label">
              {isCurrentWeek ? <h2>Esta Semana</h2> : <h2>{fmt(start)} — {fmt(end)}</h2>}
              <span className="week-range">{formatWeekLabel(start, end)}</span>
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
            <button type="button" className="btn-week-current" onClick={() => setWeekOffset(0)}>
              Esta semana →
            </button>
          )}
        </div>
        <ul className="day-strip">
          {weekDays.map((d, i) => {
            const entry = entryByDate[d];
            const contactos = entry ? entry.contactos ?? 0 : null;
            return (
              <li
                key={d}
                className={`day-dot ${entry ? 'filled' : ''} ${d === today ? 'day-today' : ''}`}
                aria-current={d === today ? 'date' : undefined}
              >
                <span aria-hidden="true">{DAY_LABELS[i]}</span>
                <span className="day-num" aria-hidden="true">{entry ? contactos : '—'}</span>
                <span className="visually-hidden">
                  {DAY_LABELS[i]}: {entry ? `${contactos} contactos` : 'por registar'}
                </span>
              </li>
            );
          })}
        </ul>
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
