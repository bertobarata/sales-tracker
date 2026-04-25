# CLAUDE.md — Sales Tracker

This file provides AI assistants with the context needed to work effectively in this codebase.

## Project Overview

**Sales Tracker** is a mobile-first Progressive Web App (PWA) for daily sales activity tracking. Sales reps log daily metrics, view weekly dashboards with goal progress, and generate WhatsApp-formatted reports or Excel exports. The app is fully client-side — no custom backend — using Firebase for auth and real-time data sync.

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
| Hosting | Vercel |
| Linting | ESLint 9 |

---

## Repository Structure

```
sales-tracker/
├── src/
│   ├── components/
│   │   ├── AuthGate.jsx        # Google login/logout, mobile vs desktop OAuth flow
│   │   ├── DailyInput.jsx      # Step-by-step daily data entry (9 metrics)
│   │   ├── Dashboard.jsx       # Weekly overview with goal progress bars
│   │   ├── NumPad.jsx          # Custom numeric keypad for mobile
│   │   └── WeeklyReport.jsx    # Weekly totals, WhatsApp report, Excel export
│   ├── utils/
│   │   ├── storage.js          # localStorage read/write and date helpers
│   │   ├── sync.js             # Firestore read/write functions
│   │   └── report.js           # WhatsApp message formatter and Excel export
│   ├── App.jsx                 # Root component, tab navigation (Daily/Dashboard/Report)
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

## Data Model

### localStorage Keys
- `salestracker_daily` — array of daily entry objects
- `salestracker_weekly` — array of weekly summary objects

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
      contratosFechados, valorTotalFechos,
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
- Key variables: `--primary`, `--bg`, `--surface`, `--text`, `--text-muted`, `--radius`, `--shadow`, `--safe-x`.
- Dark mode is handled via `@media (prefers-color-scheme: dark)` — the variables are redefined there. Always check both themes when changing styles.
- The nav bar renders at the **bottom** on mobile and the **top** on desktop (controlled by CSS media query).

### Components
- Components are functional React with hooks only — no class components.
- `DailyInput` uses a step-by-step wizard pattern with a progress bar (index 0–8 for 9 questions).
- `NumPad` is only rendered on mobile; desktop uses native `<input type="number">`. The detection is done via a CSS media query class toggle or window width check inside the component.
- `WeeklyReport` computes weekly totals from daily entries and renders editable extra fields before export.

### Firebase
- All Firebase SDK exports (auth instance, db instance, helper functions) come from `src/firebase.js`.
- Firestore operations are in `src/utils/sync.js` — keep them there.
- Do not import from `firebase/*` directly in components; go through `firebase.js` and `sync.js`.

### Dates
- Dates are ISO strings (`YYYY-MM-DD`).
- Week boundaries (Mon–Sun) and date arithmetic are handled in `src/utils/storage.js`.
- Always use the helpers in `storage.js` for date work — do not reimplement inline.

### Language
- All UI labels, button text, and messages must remain in **Portuguese**.
- Variable names and code comments may be in English.

---

## Goals Configuration

Weekly goal thresholds are hardcoded in `src/components/Dashboard.jsx`. To change them, update the constants near the top of that file:

```js
const GOALS = {
  primeirasReunioes: 10,   // target for 1st meetings
  segundasReunioes: 8,     // target for 2nd meetings
};
```

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
