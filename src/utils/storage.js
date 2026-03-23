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

export function getWeekDates(date = new Date()) {
  const d = new Date(date);
  const day = d.getDay();
  const diff = d.getDate() - day + (day === 0 ? -6 : 1);
  const monday = new Date(d.setDate(diff));
  monday.setHours(0, 0, 0, 0);
  const friday = new Date(monday);
  friday.setDate(monday.getDate() + 4);
  return {
    start: monday.toISOString().split('T')[0],
    end: friday.toISOString().split('T')[0],
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
