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
│   │   ├── DailyInput.jsx      # Daily data entry (9 metrics) with day selector
│   │   ├── Dashboard.jsx       # Weekly overview with goal progress bars
│   │   ├── Icons.jsx           # The whole icon vocabulary, inline SVG
│   │   ├── NumPad.jsx          # Custom numeric keypad for coarse pointers
│   │   ├── Settings.jsx        # Editable goals and reminder time
│   │   ├── Sheet.jsx           # The one overlay pattern: accessible bottom sheet
│   │   ├── Trends.jsx          # Recharts trends over the last 8 weeks
│   │   └── WeeklyReport.jsx    # Weekly totals, WhatsApp report, Excel export
│   ├── utils/
│   │   ├── storage.js          # localStorage read/write and date helpers
│   │   ├── sync.js             # Firestore read/write functions
│   │   ├── settings.js         # User-configurable goals and reminder time
│   │   ├── report.js           # WhatsApp message formatter and Excel export
│   │   └── useCoarsePointer.js # Touch vs mouse, via matchMedia
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
npm test             # Run the Vitest suite
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
- **`DESIGN.md` at the repo root is the source of truth for the visual system**, and
  `PRODUCT.md` for who this is for and what it must never look like. Read both before
  changing anything visual.
- Colors are OKLCH and every value in `DESIGN.md` was verified by calculation for contrast
  and sRGB gamut. Do not eyeball a new one: compute it, in both themes.
- Use the custom properties — no inline styles, no new style files. Key ones: `--primary`,
  `--bg`, `--surface`, `--raised`, `--border`, `--text`, `--text-muted`, `--radius`,
  `--safe-x`, `--chart-1`..`--chart-6`.
- Dark mode redefines the variables under `@media (prefers-color-scheme: dark)`. Check both
  themes for anything you touch — `--primary` inverts between them, so a surface painted
  with the accent looks completely different in each.
- Surfaces are flat: separation is tonal (`--bg` → `--surface` → `--raised`) plus 1px rules.
  Shadow is only for what genuinely floats. **No card inside a card.**
- Text never goes below `0.75rem`, and never on top of `--border`.
- The nav bar renders at the **bottom** on coarse pointers and the **top** otherwise.

### Components
- Components are functional React with hooks only — no class components.
- `DailyInput` shows all nine metrics at once as a stepper list, with a week strip to pick
  the day. It was a one-question-per-screen wizard once; it is not any more.
- `NumPad` renders only for coarse pointers; mouse users get a native `<input type="number">`.
  Ask `useCoarsePointer()` (`src/utils/useCoarsePointer.js`), which wraps
  `matchMedia('(pointer: coarse)')` and reacts to changes. Never sniff the user agent.
- `Sheet` is the only overlay pattern. It handles the dialog role, focus trap, Escape,
  focus restore and scroll lock. Anything that floats over the page goes through it.
- Every interactive element needs an accessible name, a visible `:focus-visible` ring and a
  44px touch target. Icons are inline SVG from `Icons.jsx` — never emoji.
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

Goals are **user-configurable at runtime**, not hardcoded. They live in localStorage and are
read through `src/utils/settings.js`; the user edits them in the Settings sheet
(`src/components/Settings.jsx`). Defaults are the fallbacks in `settings.js`.

Anything that needs a goal calls `getSettings()` — never a local constant. `Trends.jsx` used
to hardcode its own monthly target and drew a goal line that ignored what the user had set.

---

## Tests

Vitest, run with `npm test`. Three suites, 41 tests, all pure logic — week arithmetic and
date keys (`storage.test.js`), the WhatsApp report format (`report.test.js`), and settings
defaults (`settings.test.js`). No component or DOM tests.

The report format test compares the full output string on purpose: whoever changes the
wording breaks it deliberately, not by accident.

---

## Deployment

The app is deployed on **Vercel** connected to the `main` branch. Use `npm run deploy` to push and trigger a production deployment. The deploy script runs:

```bash
git push origin main && vercel --prod
```

Firebase config (API key, project ID, etc.) is hardcoded in `src/firebase.js`. This is acceptable for a public Firebase project where Firestore rules enforce per-user access. Do not move the config to environment variables unless asked.
