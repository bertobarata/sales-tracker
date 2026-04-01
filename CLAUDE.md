# CLAUDE.md — Sales Tracker

This file provides AI assistants with the context needed to work effectively in this codebase.

## Project Overview

**Sales Tracker** is a mobile-first Progressive Web App (PWA) for daily sales activity tracking. Sales reps log daily metrics, view weekly dashboards with goal progress, generate WhatsApp-formatted reports or Excel exports, and analyze trends over time. The app is fully client-side — no custom backend — using Firebase for auth and real-time data sync.

The UI and all user-facing text are in **Portuguese**.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | React 19 |
| Build Tool | Vite 8 |
| Styling | Plain CSS (CSS variables, no Tailwind or CSS-in-JS) |
| Auth | Firebase Auth (Google OAuth) |
| Database | Firebase Firestore (real-time listeners) |
| Offline | localStorage (primary cache) |
| Export | SheetJS (xlsx) for Excel |
| Charts | Recharts 3 |
| Hosting | Vercel |
| Linting | ESLint 9 |

---

## Repository Structure

```
sales-tracker/
├── src/
│   ├── components/
│   │   ├── AuthGate.jsx        # Google login/logout, OAuth flow
│   │   ├── DailyInput.jsx      # Step-by-step daily data entry (9 metrics)
│   │   ├── Dashboard.jsx       # Weekly overview with goal progress bars
│   │   ├── NumPad.jsx          # Custom numeric keypad for mobile
│   │   ├── WeeklyReport.jsx    # Weekly totals, WhatsApp report, Excel export
│   │   ├── Trends.jsx          # Multi-chart analytics dashboard (recharts)
│   │   └── Settings.jsx        # Configurable goals and reminder time
│   ├── utils/
│   │   ├── storage.js          # localStorage read/write and date helpers
│   │   ├── sync.js             # Firestore read/write functions
│   │   ├── report.js           # WhatsApp message formatter and Excel export
│   │   └── settings.js         # Settings persistence and defaults
│   ├── App.jsx                 # Root component, tab navigation (4 tabs)
│   ├── App.css                 # All component styles and CSS variables
│   ├── index.css               # Global resets and base styles
│   ├── main.jsx                # React DOM entry point
│   └── firebase.js             # Firebase SDK init and exports (auth, db)
├── public/
│   └── manifest.json           # PWA manifest (name, icons, theme_color)
├── index.html                  # HTML shell with PWA meta tags
├── vite.config.js
├── eslint.config.js
└── package.json
```

---

## Development Commands

```bash
npm run dev          # Start dev server at http://localhost:5173
npm run dev -- --host  # Expose dev server on local network (for mobile testing)
npm run build        # Production build to /dist
npm run preview      # Preview production build locally
npm run lint         # Run ESLint
npm run deploy       # git push origin main && vercel --prod
```

**Node requirement:** 18+

---

## Tab Navigation

The app has four tabs defined in `App.jsx`:

```js
const TABS = [
  { id: 'hoje',       label: 'Hoje',       icon: '✏️' },
  { id: 'semana',     label: 'Semana',     icon: '📊' },
  { id: 'relatorio',  label: 'Relatório',  icon: '📋' },
  { id: 'tendencias', label: 'Tendências', icon: '📈' },
];
```

- Nav bar is at the **bottom** on mobile and **top** on desktop (CSS media query).
- A Settings overlay is triggered from the header (gear icon), rendered on top of the active tab.

---

## Data Model

### localStorage Keys
- `salestracker_daily` — array of daily entry objects
- `salestracker_weekly` — array of weekly summary objects
- `salestracker_settings` — user-configurable goals and reminder time
- `salestracker_notif_dismissed` — boolean flag for notification banner dismissal

### Firestore Schema
```
users/{uid}/
  daily/{YYYY-MM-DD}          # One doc per day
    date, contactos, primeirasReunioesMarcadas, segundasReunioesMarcadas,
    terceirasReunioesMarcadas, primeirasReunioesRealizadas,
    segundasReunioesRealizadas, terceirasReunioesRealizadas,
    pesquisas, referencias

  weekly/{YYYY-MM-DD}         # One doc per week (keyed by Monday's date)
    weekStart, weekEnd,
    totals: { ...same 9 fields summed },
    extra: {
      contratosFechados, valorTotalFechos, pessoasSeguras,
      reunioes1aProxSemana, reunioes2aProxSemana, reunioes3aProxSemana
    }
```

### Sync Strategy
1. All writes go to localStorage immediately (synchronous).
2. If a user is authenticated, Firestore is updated asynchronously after.
3. Firestore real-time listeners push changes back to localStorage and trigger re-renders.
4. This enables offline-first usage and multi-device sync.

### Firestore Security Rules
Each user can only read/write under `users/{their_uid}`. Rules:
```
match /users/{uid}/{document=**} {
  allow read, write: if request.auth != null && request.auth.uid == uid;
}
```

---

## Key Conventions

### Styling
- All styles live in `src/App.css` (component styles) and `src/index.css` (globals).
- Use the existing CSS custom properties — do not add inline styles or new style files unless clearly necessary.
- Key variables: `--primary`, `--primary-dark`, `--primary-light`, `--bg`, `--surface`, `--border`, `--text`, `--text-muted`, `--success`, `--radius`, `--shadow`, `--safe-x`.
- Dark mode is handled via `@media (prefers-color-scheme: dark)` — the variables are redefined there. Always check both themes when changing styles.
- The nav bar renders at the **bottom** on mobile and the **top** on desktop (controlled by CSS media query).

### Components
- Components are functional React with hooks only — no class components.
- `DailyInput` uses a step-by-step wizard pattern with a progress bar (index 0–8 for 9 questions). Mobile uses `NumPad`; desktop uses native `<input type="number">`.
- `NumPad` is rendered only on mobile (detected via user-agent). It prevents leading zeros and emits values on confirm.
- `WeeklyReport` computes weekly totals from daily entries and renders editable extra fields before export. Extra fields: `contratosFechados`, `valorTotalFechos`, `pessoasSeguras`, `reunioes1aProxSemana`, `reunioes2aProxSemana`, `reunioes3aProxSemana`.
- `Trends` renders four Recharts charts (meetings by type, contacts, revenue area, conversion rate) over an 8-week lookback window.
- `Settings` renders stepper controls for the three configurable goals and a time input for the daily reminder. Changes are saved via `src/utils/settings.js` and propagated to parent via `onClose` callback.

### Firebase
- All Firebase SDK exports (auth instance, db instance, helper functions) come from `src/firebase.js`.
- Firestore operations are in `src/utils/sync.js` — keep them there.
- Do not import from `firebase/*` directly in components; go through `firebase.js` and `sync.js`.

### Dates
- Dates are ISO strings (`YYYY-MM-DD`).
- Week boundaries (Mon–Sun) and date arithmetic are handled in `src/utils/storage.js`.
- Always use the helpers in `storage.js` for date work — do not reimplement inline.
- `getMonthlyValorTotal(year, month)` in `storage.js` aggregates weekly `valorTotalFechos` for a calendar month.

### Language
- All UI labels, button text, and messages must remain in **Portuguese**.
- Variable names and code comments may be in English.

---

## Goals & Settings Configuration

Goals are **no longer hardcoded**. They are user-configurable via the Settings component and persisted in localStorage through `src/utils/settings.js`.

### Defaults (in `src/utils/settings.js`):
```js
const DEFAULTS = {
  goalPrimeirasReunioesRealizadas: 10,  // weekly 1st meetings target
  goalSegundasReunioesRealizadas:  8,   // weekly 2nd meetings target
  goalMensalValor:                 5000, // monthly revenue target (€)
  reminderTime:                    '18:30',
};
```

`getSettings()` returns stored values merged over these defaults. `saveSettings(settings)` persists to localStorage.

### Consuming settings in components:
- `Dashboard.jsx` reads `settings.goalPrimeirasReunioesRealizadas`, `settings.goalSegundasReunioesRealizadas`, and `settings.goalMensalValor`.
- `App.jsx` reads `settings.reminderTime` to schedule the Web Notifications reminder.
- `Trends.jsx` uses the monthly valor goal as a reference line on the revenue chart.

---

## Notifications

`App.jsx` schedules a browser push notification reminder using the Web Notifications API:

- User is prompted for permission once (dismissal stored in `salestracker_notif_dismissed`).
- Reminder fires at the configured `reminderTime` (default `18:30`) via `setTimeout`.
- Mobile is detected via user-agent (`/iPhone|iPad|iPod|Android/i`).

---

## No Tests

There is no testing framework configured. Do not add test infrastructure unless explicitly requested.

---

## Deployment

The app is deployed on **Vercel** connected to the `main` branch. Use `npm run deploy` to push and trigger a production deployment. The deploy script runs:

```bash
git push origin main && vercel --prod
```

Firebase config (API key, project ID, etc.) is hardcoded in `src/firebase.js`. This is acceptable for a public Firebase project where Firestore rules enforce per-user access. Do not move the config to environment variables unless asked.
