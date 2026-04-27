import {
  doc, setDoc, collection, onSnapshot
} from 'firebase/firestore';
import { db } from '../firebase';

function userPath(uid) {
  return `users/${uid}`;
}

// Guarda entrada diária no Firestore
export async function syncDailyEntry(uid, entry) {
  const ref = doc(db, userPath(uid), 'daily', entry.date);
  await setDoc(ref, entry);
}

// Guarda resumo semanal no Firestore
export async function syncWeeklySummary(uid, summary) {
  const ref = doc(db, userPath(uid), 'weekly', summary.weekStart);
  await setDoc(ref, summary);
}

// Subscreve a atualizações em tempo real das entradas diárias
export function subscribeDailyEntries(uid, callback) {
  const ref = collection(db, userPath(uid), 'daily');
  return onSnapshot(ref, (snap) => {
    const entries = snap.docs.map(d => d.data());
    callback(entries);
  });
}

// Subscreve a atualizações em tempo real dos resumos semanais
export function subscribeWeeklySummaries(uid, callback) {
  const ref = collection(db, userPath(uid), 'weekly');
  return onSnapshot(ref, (snap) => {
    const summaries = snap.docs.map(d => d.data());
    callback(summaries);
  });
}
