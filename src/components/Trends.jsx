import { useState, useEffect, useMemo } from 'react';
import {
  BarChart, Bar, LineChart, Line, AreaChart, Area,
  XAxis, YAxis, CartesianGrid, Tooltip, Legend, ResponsiveContainer, ReferenceLine,
} from 'recharts';
import {
  getDailyEntries, getWeeklySummaries, getWeekDates, sumWeekEntries,
  loadRemoteWeeklySummaries, loadRemoteEntries,
} from '../utils/storage';
import { subscribeDailyEntries, subscribeWeeklySummaries } from '../utils/sync';
import { getSettings } from '../utils/settings';

const WEEKS_TO_SHOW = 8;

// Build last N weeks of aggregated data
function buildWeeklyData(n) {
  const dailyEntries = getDailyEntries();
  const weeklySummaries = getWeeklySummaries();
  const summaryByStart = Object.fromEntries(weeklySummaries.map(s => [s.weekStart, s]));

  const weeks = [];
  for (let i = n - 1; i >= 0; i--) {
    const d = new Date();
    d.setDate(d.getDate() - i * 7);
    const { start, end } = getWeekDates(d);
    const entries = dailyEntries.filter(e => e.date >= start && e.date <= end);
    const totals = sumWeekEntries(entries);
    const summary = summaryByStart[start];
    const label = start.split('-').reverse().slice(0, 2).join('/');
    weeks.push({
      label,
      weekStart: start,
      primeiras: totals.primeirasReunioesRealizadas,
      segundas: totals.segundasReunioesRealizadas,
      terceiras: totals.terceirasReunioesRealizadas,
      contactos: totals.contactos,
      valorFechos: summary?.extra?.valorTotalFechos || 0,
      conversao: totals.contactos > 0
        ? Math.round((totals.primeirasReunioesRealizadas / totals.contactos) * 100)
        : 0,
    });
  }
  return weeks;
}

// Serie categorica definida em App.css, uma so vez para os dois temas.
const COLORS = {
  primeiras: 'var(--chart-1)',
  segundas: 'var(--chart-6)',
  terceiras: 'var(--chart-2)',
  contactos: 'var(--chart-4)',
  valor: 'var(--chart-3)',
  conversao: 'var(--chart-5)',
};

// Sem background explicito o tooltip do recharts fica branco sobre fundo escuro.
const tooltipStyle = {
  borderRadius: 10,
  fontSize: '0.8rem',
  background: 'var(--surface)',
  border: '1px solid var(--border)',
  color: 'var(--text)',
};
const tooltipItemStyle = { color: 'var(--text)' };
const tooltipLabelStyle = { color: 'var(--text-muted)' };

export default function Trends({ uid }) {
  // Sobe a cada snapshot do Firestore. E a unica coisa que invalida os dados,
  // por isso e a unica dependencia dos memos abaixo.
  const [version, setVersion] = useState(0);

  useEffect(() => {
    const unsubDaily = subscribeDailyEntries(uid, (remote) => {
      loadRemoteEntries(remote);
      setVersion(v => v + 1);
    });
    const unsubWeekly = subscribeWeeklySummaries(uid, (remote) => {
      loadRemoteWeeklySummaries(remote);
      setVersion(v => v + 1);
    });
    return () => { unsubDaily(); unsubWeekly(); };
  }, [uid]);

  // Sem isto, cada render le e faz JSON.parse do localStorage duas vezes e
  // reconstroi as oito semanas — inclusive quando so mudou o hover de um grafico.
  // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` e a chave de invalidacao do localStorage, nao um valor lido aqui dentro
  const monthlyValorGoal = useMemo(() => getSettings().goalMensalValor, [version]);
  // eslint-disable-next-line react-hooks/exhaustive-deps -- `version` e a chave de invalidacao do localStorage, nao um valor lido aqui dentro
  const data = useMemo(() => buildWeeklyData(WEEKS_TO_SHOW), [version]);
  const hasData = useMemo(
    () => data.some(w => w.contactos > 0 || w.primeiras > 0 || w.valorFechos > 0),
    [data],
  );

  if (!hasData) {
    return (
      <div className="card trends-empty">
        <p>Ainda não há dados suficientes para mostrar tendências.</p>
        <p className="subtitle">Começa a registar o teu dia a dia para ver os gráficos aqui.</p>
      </div>
    );
  }

  return (
    <div>
      {/* Reuniões realizadas */}
      <p className="section-label">Reuniões realizadas</p>
      <div className="card">
        <ResponsiveContainer width="100%" height={200}>
          <BarChart data={data} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
            <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
            <YAxis tick={{ fontSize: 11, fill: 'var(--text-muted)' }} allowDecimals={false} />
            <Tooltip contentStyle={tooltipStyle} itemStyle={tooltipItemStyle} labelStyle={tooltipLabelStyle} />
            <Legend iconSize={10} wrapperStyle={{ fontSize: '0.75rem' }} />
            <Bar dataKey="primeiras" name="1as" fill={COLORS.primeiras} radius={[4, 4, 0, 0]} />
            <Bar dataKey="segundas" name="2as" fill={COLORS.segundas} radius={[4, 4, 0, 0]} />
            <Bar dataKey="terceiras" name="3as" fill={COLORS.terceiras} radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Contactos */}
      <p className="section-label">Contactos por semana</p>
      <div className="card">
        <ResponsiveContainer width="100%" height={180}>
          <BarChart data={data} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
            <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
            <YAxis tick={{ fontSize: 11, fill: 'var(--text-muted)' }} allowDecimals={false} />
            <Tooltip contentStyle={tooltipStyle} itemStyle={tooltipItemStyle} labelStyle={tooltipLabelStyle} />
            <Bar dataKey="contactos" name="Contactos" fill={COLORS.contactos} radius={[4, 4, 0, 0]} />
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Valor fechos */}
      <p className="section-label">Valor fechos (€)</p>
      <div className="card">
        <ResponsiveContainer width="100%" height={180}>
          <AreaChart data={data} margin={{ top: 4, right: 4, left: -10, bottom: 0 }}>
            <defs>
              <linearGradient id="valorGrad" x1="0" y1="0" x2="0" y2="1">
                <stop offset="5%" stopColor={COLORS.valor} stopOpacity={0.25} />
                <stop offset="95%" stopColor={COLORS.valor} stopOpacity={0} />
              </linearGradient>
            </defs>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
            <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
            <YAxis tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
            <Tooltip contentStyle={tooltipStyle} itemStyle={tooltipItemStyle} labelStyle={tooltipLabelStyle} formatter={v => `${v.toLocaleString('pt-PT')}€`} />
            <ReferenceLine
              y={monthlyValorGoal}
              stroke={COLORS.valor}
              strokeDasharray="4 3"
              label={{ value: 'Objetivo', position: 'insideTopRight', fontSize: 10, fill: COLORS.valor }}
            />
            <Area
              type="monotone"
              dataKey="valorFechos"
              name="Valor (€)"
              stroke={COLORS.valor}
              fill="url(#valorGrad)"
              strokeWidth={2}
            />
          </AreaChart>
        </ResponsiveContainer>
      </div>

      {/* Taxa de conversão */}
      <p className="section-label">Taxa de conversão (%)</p>
      <div className="card">
        <p className="subtitle" style={{ marginBottom: 8 }}>Contactos → 1ª reunião realizada</p>
        <ResponsiveContainer width="100%" height={160}>
          <LineChart data={data} margin={{ top: 4, right: 4, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="var(--border)" />
            <XAxis dataKey="label" tick={{ fontSize: 11, fill: 'var(--text-muted)' }} />
            <YAxis tick={{ fontSize: 11, fill: 'var(--text-muted)' }} unit="%" domain={[0, 100]} />
            <Tooltip contentStyle={tooltipStyle} itemStyle={tooltipItemStyle} labelStyle={tooltipLabelStyle} formatter={v => `${v}%`} />
            <Line
              type="monotone"
              dataKey="conversao"
              name="Conversão"
              stroke={COLORS.conversao}
              strokeWidth={2}
              dot={{ r: 4, fill: COLORS.conversao }}
              activeDot={{ r: 6 }}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
