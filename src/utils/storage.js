import { syncDailyEntry, syncWeeklySummary } from './sync';

const DAILY_KEY = 'salestracker_daily';
const WEEKLY_KEY = 'salestracker_weekly';

export function getDailyEntries() {
  return JSON.parse(localStorage.getItem(DAILY_KEY) || '[]');
}

export function saveDailyEntry(entry, uid = null) {
  const entries = getDailyEntries();
  const idx = entries.findIndex(e => e.date === entry.date);
  if (idx >= 0) entries[idx] = entry;
  else entries.push(entry);
  localStorage.setItem(DAILY_KEY, JSON.stringify(entries));
  if (uid) syncDailyEntry(uid, entry).catch(console.error);
}

export function getDailyEntry(date) {
  return getDailyEntries().find(e => e.date === date) || null;
}

export function getWeeklySummaries() {
  return JSON.parse(localStorage.getItem(WEEKLY_KEY) || '[]');
}

export function saveWeeklySummary(summary, uid = null) {
  const summaries = getWeeklySummaries();
  const idx = summaries.findIndex(s => s.weekStart === summary.weekStart);
  if (idx >= 0) summaries[idx] = summary;
  else summaries.push(summary);
  localStorage.setItem(WEEKLY_KEY, JSON.stringify(summaries));
  if (uid) syncWeeklySummary(uid, summary).catch(console.error);
}

export function loadRemoteEntries(entries) {
  localStorage.setItem(DAILY_KEY, JSON.stringify(entries));
}

export function loadRemoteWeeklySummaries(summaries) {
  localStorage.setItem(WEEKLY_KEY, JSON.stringify(summaries));
}

export function getMonthlyValorTotal(year, month) {
  // month is 1-based (1=Jan)
  const prefix = `${year}-${String(month).padStart(2, '0')}`;
  return getWeeklySummaries()
    .filter(s => s.weekStart && s.weekStart.startsWith(prefix))
    .reduce((acc, s) => acc + (Number(s.extra?.valorTotalFechos) || 0), 0);
}

// ISO 8601: semana começa na segunda, âncora na quinta-feira da semana
export function getISOWeekNumber(date) {
  const d = new Date(Date.UTC(date.getFullYear(), date.getMonth(), date.getDate()));
  const dayNum = d.getUTCDay() || 7; // domingo (0) passa a 7
  d.setUTCDate(d.getUTCDate() + 4 - dayNum); // avança para a quinta da mesma semana
  const yearStart = new Date(Date.UTC(d.getUTCFullYear(), 0, 1));
  return Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
}

const PT_MONTHS = ['jan','fev','mar','abr','mai','jun','jul','ago','set','out','nov','dez'];

// Retorna "Semana 17 · 20–26 abr"
export function formatWeekLabel(weekStart, weekEnd) {
  const s = new Date(weekStart + 'T00:00:00');
  const e = new Date(weekEnd + 'T00:00:00');
  const weekNum = getISOWeekNumber(s);
  return `Semana ${weekNum} · ${s.getDate()}–${e.getDate()} ${PT_MONTHS[e.getMonth()]}`;
}

// Formata Date como "YYYY-MM-DD" usando hora local (evita desfasamento UTC)
function localDateStr(d) {
  const y = d.getFullYear();
  const m = String(d.getMonth() + 1).padStart(2, '0');
  const day = String(d.getDate()).padStart(2, '0');
  return `${y}-${m}-${day}`;
}

export function getWeekDates(date = new Date()) {
  const d = new Date(date);
  const day = d.getDay();
  d.setDate(d.getDate() - day + (day === 0 ? -6 : 1)); // recua para segunda
  d.setHours(0, 0, 0, 0);
  const monday = new Date(d);
  const sunday = new Date(monday);
  sunday.setDate(monday.getDate() + 6); // seg + 6 = dom (ISO 8601)
  return {
    start: localDateStr(monday),
    end: localDateStr(sunday),
  };
}

export function getEntriesForWeek(weekStart, weekEnd) {
  return getDailyEntries().filter(e => e.date >= weekStart && e.date <= weekEnd);
}

export function sumWeekEntries(entries) {
  const keys = [
    'contactos', 'primeirasReunioesMarcadas', 'segundasReunioesMarcadas',
    'terceirasReunioesMarcadas', 'primeirasReunioesRealizadas',
    'segundasReunioesRealizadas', 'terceirasReunioesRealizadas',
    'pesquisas', 'referencias',
  ];
  const totals = {};
  keys.forEach(k => {
    totals[k] = entries.reduce((acc, e) => acc + (Number(e[k]) || 0), 0);
  });
  return totals;
}
