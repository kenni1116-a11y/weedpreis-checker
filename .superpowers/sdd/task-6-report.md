# Task 6 report: Tabs, favorites, information, and failure states

## Delivered

- Added route-free `Suche`, `Favoriten`, and `Info` navigation in `App`.
- Added the required factual information copy verbatim.
- Added a local favorites view that filters ranked synthetic offers by the IDs in device-only preferences and renders the existing `ResultsList`.
- Kept the existing explicit search failure state: “Angebote konnten nicht geladen werden. Es wird keine Verfügbarkeit angenommen.”
- Forwarded favorite changes through `ResultsList` so removing an item from the favorites tab immediately removes it from that shared list.

## Data-flow decision

`App` creates one ranked, shipping-mode 10 g view of the synthetic offers using the existing `rankOffers` domain function. `FavoritesView` filters that already-ranked list with `new Set(devicePreferences.getFavoriteIds())` and passes the result to `ResultsList`. This preserves the existing total-price, freshness, source, and availability presentation without duplicating it. Search remains independent and unchanged.

## TDD evidence

- RED: `AppNavigation.test.tsx` failed because `AppNavigation` did not exist.
- RED: `FavoritesView.test.tsx` failed because `FavoritesView` did not exist.
- GREEN: navigation and favorites tests pass after implementation.

## Verification

- `pnpm vitest run` — 8 files, 11 tests passed.
- `pnpm build` — passed.
- `git diff --check` — passed.

## Self-review

No unresolved issues found. The initial direct call to `rankOffers` was corrected to supply its required current time after the full suite exposed the missing argument.

## Review Fix

### Changed files

- `src/app/App.tsx`: stores the exact last successful `RankedOffer[]` and requested grams, then supplies both unchanged to `FavoritesView`.
- `src/components/SearchExperience.tsx`: reports successful results and grams through the small optional `onResultsChange` interface.
- `src/app/App.test.tsx`: adds the pickup, 7 g integration test proving a saved favorite retains `Gesamtpreis für 7 g: 45,43 €` after switching tabs.

### RED evidence

Command:

```bash
PATH=/Users/ken/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin:$PATH pnpm vitest run src/app/App.test.tsx
```

Output: `1 failed | 1 passed`; the favorite tab rendered `Gesamtpreis für 10 g: 69,89 €` instead of the asserted pickup total for 7 g.

### GREEN verification

Commands:

```bash
PATH=/Users/ken/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin:$PATH pnpm vitest run src/app/App.test.tsx src/components/AppNavigation.test.tsx src/components/FavoritesView.test.tsx
PATH=/Users/ken/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin:$PATH pnpm vitest run
PATH=/Users/ken/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/bin:$PATH pnpm build
git diff --check
```

Outputs:

- Focused Task 6 tests: `3 passed`, `5 passed`.
- Full suite: `8 passed`, `12 passed`.
- Build: passed, including PWA generation.
- `git diff --check`: no output; passed.
