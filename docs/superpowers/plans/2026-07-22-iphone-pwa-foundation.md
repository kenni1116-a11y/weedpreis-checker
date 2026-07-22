# Weedpreis Checker iPhone PWA Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a complete, installable iPhone PWA user journey backed by a typed in-memory repository of explicitly synthetic offers, ready to be replaced by the separately planned Supabase repository.

**Architecture:** A React/TypeScript PWA separates domain calculations, repository access, local device preferences, and presentation components. All screens consume an `OffersRepository` interface so the synthetic repository can later be replaced without changing UI behavior. Vite produces the GitHub Pages build; Vitest covers behavior and Playwright verifies the iPhone journey.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Testing Library 16.3.2, vite-plugin-pwa 1.3.0, Playwright 1.61.1

## Global Constraints

- The app compares prescription medical cannabis neutrally; it never recommends treatment, effects, or products.
- There is no user account, prescription upload, diagnosis, checkout, payment, personalized analytics, price alert, or sponsored ranking.
- The age confirmation and favorites are stored only on the device.
- Shipping and pickup are equal modes; the default ranking uses the relevant total price.
- Every displayed price includes its source type and last checked time.
- Offers newer than 24 hours are current; older offers are excluded from current ranking and labeled `Zuletzt gesehen`.
- The background color is `#07110f`; the iPhone status bar remains visible and blends into that color.
- The checked-in synthetic dataset must be visibly labeled as test data and must never contain real pharmacy names or claims.
- A request containing only `Prüfen` or `Überprüfen` authorizes read-only verification, not file edits.

---

## File Structure

- `src/domain/offer.ts`: canonical offer, pharmacy, product, query, and result types.
- `src/domain/pricing.ts`: total-price and freshness calculations plus deterministic ranking.
- `src/data/offers-repository.ts`: repository interface consumed by the UI.
- `src/data/synthetic-offers.ts`: clearly synthetic development records.
- `src/data/in-memory-offers-repository.ts`: search/filter implementation over synthetic records.
- `src/storage/device-preferences.ts`: age confirmation and favorite IDs in local storage.
- `src/components/`: focused React components for age gate, search controls, filters, results, and navigation.
- `src/app/App.tsx`: route-free state orchestration for the three-tab MVP.
- `src/styles/app.css`: tokens and mobile layout.
- `tests/e2e/iphone-flow.spec.ts`: installed-app-sized user journey.
- `.github/workflows/verify.yml`: test and build gate.
- `.github/workflows/pages.yml`: GitHub Pages publication.

### Task 1: Reproducible React/PWA Test Shell

**Files:**
- Create: `package.json`
- Create: `tsconfig.json`
- Create: `tsconfig.app.json`
- Create: `vite.config.ts`
- Create: `vitest.setup.ts`
- Create: `index.html`
- Create: `public/logo.svg`
- Create: `src/main.tsx`
- Create: `src/app/App.tsx`
- Create: `src/styles/app.css`
- Create: `src/app/App.test.tsx`

**Interfaces:**
- Consumes: none.
- Produces: `App(): JSX.Element`, Vite `build`, Vitest `test`, and PWA manifest configuration.

- [ ] **Step 1: Add the failing smoke test**

```tsx
// src/app/App.test.tsx
import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { App } from './App'

describe('App', () => {
  it('identifies itself as a neutral pharmacy comparison', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Weedpreis' })).toBeInTheDocument()
    expect(screen.getByText('Neutraler Apothekenvergleich')).toBeInTheDocument()
  })
})
```

- [ ] **Step 2: Add pinned tooling and run the test red**

```json
{
  "name": "weedpreis-checker",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "packageManager": "pnpm@11.9.0",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:e2e": "playwright test",
    "check": "pnpm test && pnpm build"
  },
  "dependencies": {
    "react": "19.2.8",
    "react-dom": "19.2.8"
  },
  "devDependencies": {
    "@playwright/test": "1.61.1",
    "@testing-library/jest-dom": "7.0.0",
    "@testing-library/react": "16.3.2",
    "@testing-library/user-event": "14.6.1",
    "@types/node": "26.1.1",
    "@types/react": "19.2.17",
    "@types/react-dom": "19.2.3",
    "@vitejs/plugin-react": "6.0.4",
    "jsdom": "29.1.1",
    "typescript": "7.0.2",
    "vite": "8.1.5",
    "vite-plugin-pwa": "1.3.0",
    "vitest": "4.1.10"
  }
}
```

Run: `pnpm install && pnpm test`

Expected: FAIL because `src/app/App.tsx` does not exist.

- [ ] **Step 3: Add TypeScript, Vite, document, and minimal app files**

```ts
// vite.config.ts
import react from '@vitejs/plugin-react'
import { defineConfig, loadEnv } from 'vite'
import { VitePWA } from 'vite-plugin-pwa'

export default defineConfig(({ mode }) => {
  const env = loadEnv(mode, process.cwd(), '')
  return {
    base: env.VITE_BASE_PATH || '/',
    plugins: [
      react(),
      VitePWA({
        registerType: 'autoUpdate',
        manifest: {
          name: 'Weedpreis – Neutraler Apothekenvergleich',
          short_name: 'Weedpreis',
          description: 'Neutraler Preis- und Verfügbarkeitsvergleich für Medizinalcannabis.',
          theme_color: '#07110f',
          background_color: '#07110f',
          display: 'standalone',
          start_url: '.',
          icons: [{ src: 'logo.svg', sizes: 'any', type: 'image/svg+xml', purpose: 'any maskable' }]
        }
      })
    ],
    test: { environment: 'jsdom', setupFiles: './vitest.setup.ts' }
  }
})
```

```tsx
// src/app/App.tsx
export function App() {
  return (
    <main className="app-shell">
      <header><h1>Weedpreis</h1><p>Neutraler Apothekenvergleich</p></header>
    </main>
  )
}
```

```tsx
// src/main.tsx
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { registerSW } from 'virtual:pwa-register'
import { App } from './app/App'
import './styles/app.css'

registerSW({ immediate: true })
createRoot(document.getElementById('root')!).render(<StrictMode><App /></StrictMode>)
```

```json
// tsconfig.json
{ "files": [], "references": [{ "path": "./tsconfig.app.json" }] }
```

```json
// tsconfig.app.json
{ "compilerOptions": { "target": "ES2023", "useDefineForClassFields": true, "lib": ["ES2023", "DOM", "DOM.Iterable"], "module": "ESNext", "skipLibCheck": true, "moduleResolution": "Bundler", "allowImportingTsExtensions": false, "isolatedModules": true, "moduleDetection": "force", "noEmit": true, "jsx": "react-jsx", "strict": true, "noUnusedLocals": true, "noUnusedParameters": true }, "include": ["src", "vite.config.ts", "vitest.setup.ts"] }
```

```html
<!-- index.html -->
<!doctype html><html lang="de"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover"><meta name="theme-color" content="#07110f"><meta name="apple-mobile-web-app-capable" content="yes"><meta name="apple-mobile-web-app-status-bar-style" content="black-translucent"><title>Weedpreis</title></head><body><div id="root"></div><script type="module" src="/src/main.tsx"></script></body></html>
```

Create `vitest.setup.ts` with the single line `import '@testing-library/jest-dom/vitest'`. Create `public/logo.svg` with a `512 × 512` dark rounded-square background, a white price-tag outline, and green center dot; keep all geometry inside a 48px safe margin so the same asset works as `any maskable`.

```css
/* src/styles/app.css */
:root { font-family: Inter, ui-sans-serif, system-ui, sans-serif; color: #f3f7f5; background: #07110f; }
* { box-sizing: border-box; }
body { margin: 0; min-width: 320px; min-height: 100vh; background: #07110f; }
button, input, select { font: inherit; }
.app-shell { width: min(100%, 520px); min-height: 100vh; margin: 0 auto; padding: max(18px, env(safe-area-inset-top)) 18px max(24px, env(safe-area-inset-bottom)); }
```

- [ ] **Step 4: Verify green and commit**

Run: `pnpm test && pnpm build`

Expected: one passing test and a successful `dist/` build.

```bash
git add package.json pnpm-lock.yaml tsconfig*.json vite.config.ts vitest.setup.ts index.html public src
git commit -m "feat: scaffold installable pwa shell"
```

### Task 2: Offer Domain, Freshness, and Total-Price Ranking

**Files:**
- Create: `src/domain/offer.ts`
- Create: `src/domain/pricing.ts`
- Create: `src/domain/pricing.test.ts`

**Interfaces:**
- Consumes: none.
- Produces: `Offer`, `OfferQuery`, `RankedOffer`, `rankOffers(offers, query, now)` and `isCurrent(checkedAt, now)`.

- [ ] **Step 1: Write failing calculation tests**

```ts
import { describe, expect, it } from 'vitest'
import { isCurrent, rankOffers } from './pricing'
import type { Offer } from './offer'

const base: Offer = {
  id: 'offer-a', productId: 'product-a', productName: 'Testblüte Alpha 22/1', manufacturer: 'Testlabor Nord',
  form: 'flower', thcPercent: 22, cbdPercent: 1,
  pharmacyId: 'pharmacy-a', pharmacyName: 'Muster-Apotheke A – Testdaten', sourceType: 'feed',
  sourceUrl: 'https://example.invalid/a', unitPriceCents: 650, shippingCents: 499,
  pickup: false, shipping: true, available: true, checkedAt: '2026-07-22T12:00:00.000Z'
}

describe('pricing', () => {
  it('treats exactly 24 hours as stale', () => {
    expect(isCurrent(base.checkedAt, new Date('2026-07-23T11:59:59.000Z'))).toBe(true)
    expect(isCurrent(base.checkedAt, new Date('2026-07-23T12:00:00.000Z'))).toBe(false)
  })

  it('ranks current shipping offers by total price for requested grams', () => {
    const freeShipping = { ...base, id: 'offer-b', unitPriceCents: 675, shippingCents: 0 }
    const ranked = rankOffers([base, freeShipping], { mode: 'shipping', grams: 10 }, new Date('2026-07-22T18:00:00.000Z'))
    expect(ranked.map(({ offer, totalPriceCents }) => [offer.id, totalPriceCents])).toEqual([
      ['offer-b', 6750], ['offer-a', 6999]
    ])
  })
})
```

- [ ] **Step 2: Run red**

Run: `pnpm vitest run src/domain/pricing.test.ts`

Expected: FAIL because domain modules do not exist.

- [ ] **Step 3: Implement exact domain contracts**

```ts
// src/domain/offer.ts
export type FulfillmentMode = 'shipping' | 'pickup'
export type SourceType = 'feed' | 'public-source' | 'manual-review'
export type ProductForm = 'flower' | 'extract'

export interface Offer {
  id: string; productId: string; productName: string; manufacturer: string
  form: ProductForm; thcPercent: number; cbdPercent: number
  pharmacyId: string; pharmacyName: string; sourceType: SourceType; sourceUrl: string
  unitPriceCents: number; shippingCents: number; pickup: boolean; shipping: boolean
  available: boolean; checkedAt: string; distanceMeters?: number
}

export interface OfferQuery { mode: FulfillmentMode; grams: number; text?: string; postalCode?: string; form?: ProductForm; minThcPercent?: number }
export interface RankedOffer { offer: Offer; totalPriceCents: number; current: boolean }
```

```ts
// src/domain/pricing.ts
import type { Offer, OfferQuery, RankedOffer } from './offer'

export const CURRENT_WINDOW_MS = 24 * 60 * 60 * 1000
export function isCurrent(checkedAt: string, now: Date): boolean {
  return now.getTime() - new Date(checkedAt).getTime() < CURRENT_WINDOW_MS
}
export function totalPriceCents(offer: Offer, query: OfferQuery): number {
  return offer.unitPriceCents * query.grams + (query.mode === 'shipping' ? offer.shippingCents : 0)
}
export function rankOffers(offers: Offer[], query: OfferQuery, now: Date): RankedOffer[] {
  return offers
    .filter((offer) => offer.available && (query.mode === 'shipping' ? offer.shipping : offer.pickup))
    .map((offer) => ({ offer, totalPriceCents: totalPriceCents(offer, query), current: isCurrent(offer.checkedAt, now) }))
    .sort((a, b) => Number(b.current) - Number(a.current) || a.totalPriceCents - b.totalPriceCents || a.offer.id.localeCompare(b.offer.id))
}
```

- [ ] **Step 4: Verify and commit**

Run: `pnpm vitest run src/domain/pricing.test.ts && pnpm build`

Expected: two passing tests and successful typecheck.

```bash
git add src/domain
git commit -m "feat: add deterministic offer pricing"
```

### Task 3: Synthetic Repository and Search Contract

**Files:**
- Create: `src/data/offers-repository.ts`
- Create: `src/data/synthetic-offers.ts`
- Create: `src/data/in-memory-offers-repository.ts`
- Create: `src/data/in-memory-offers-repository.test.ts`

**Interfaces:**
- Consumes: `Offer`, `OfferQuery`, `RankedOffer`, `rankOffers` from Task 2.
- Produces: `OffersRepository.search(query, now): Promise<RankedOffer[]>` and `inMemoryOffersRepository`.

- [ ] **Step 1: Write failing repository tests**

```ts
import { describe, expect, it } from 'vitest'
import { createInMemoryOffersRepository } from './in-memory-offers-repository'
import { syntheticOffers } from './synthetic-offers'

describe('in-memory repository', () => {
  it('matches product and manufacturer case-insensitively', async () => {
    const repository = createInMemoryOffersRepository(syntheticOffers)
    const result = await repository.search({ mode: 'shipping', grams: 10, text: 'testlabor nord' }, new Date('2026-07-22T18:00:00Z'))
    expect(result.length).toBeGreaterThan(0)
    expect(result.every(({ offer }) => offer.manufacturer === 'Testlabor Nord')).toBe(true)
  })
  it('filters the neutral catalog by form and factual THC value', async () => {
    const repository = createInMemoryOffersRepository(syntheticOffers)
    const result = await repository.search({ mode: 'shipping', grams: 10, form: 'flower', minThcPercent: 20 })
    expect(result.every(({ offer }) => offer.form === 'flower' && offer.thcPercent >= 20)).toBe(true)
  })
})
```

- [ ] **Step 2: Run red**

Run: `pnpm vitest run src/data/in-memory-offers-repository.test.ts`

Expected: FAIL because repository files do not exist.

- [ ] **Step 3: Implement repository and three synthetic offers**

```ts
// src/data/offers-repository.ts
import type { OfferQuery, RankedOffer } from '../domain/offer'
export interface OffersRepository { search(query: OfferQuery, now?: Date): Promise<RankedOffer[]> }
```

```ts
// src/data/in-memory-offers-repository.ts
import type { Offer } from '../domain/offer'
import { rankOffers } from '../domain/pricing'
import type { OffersRepository } from './offers-repository'

export function createInMemoryOffersRepository(offers: Offer[]): OffersRepository {
  return { async search(query, now = new Date()) {
    const needle = query.text?.trim().toLocaleLowerCase('de-DE')
    const matches = offers.filter((offer) => (!needle || `${offer.productName} ${offer.manufacturer}`.toLocaleLowerCase('de-DE').includes(needle)) && (!query.form || offer.form === query.form) && (query.minThcPercent === undefined || offer.thcPercent >= query.minThcPercent))
    return rankOffers(matches, query, now)
  } }
}
```

```ts
// src/data/synthetic-offers.ts
import type { Offer } from '../domain/offer'
import { createInMemoryOffersRepository } from './in-memory-offers-repository'

const hoursAgo = (hours: number) => new Date(Date.now() - hours * 3_600_000).toISOString()
export const syntheticOffers: Offer[] = [
  { id: 'offer-a', productId: 'alpha', productName: 'Testblüte Alpha 22/1', manufacturer: 'Testlabor Nord', form: 'flower', thcPercent: 22, cbdPercent: 1, pharmacyId: 'test-a', pharmacyName: 'Muster-Apotheke A – Testdaten', sourceType: 'feed', sourceUrl: 'https://example.invalid/a', unitPriceCents: 649, shippingCents: 499, pickup: true, shipping: true, available: true, checkedAt: hoursAgo(1), distanceMeters: 2400 },
  { id: 'offer-b', productId: 'alpha', productName: 'Testblüte Alpha 22/1', manufacturer: 'Testlabor Nord', form: 'flower', thcPercent: 22, cbdPercent: 1, pharmacyId: 'test-b', pharmacyName: 'Muster-Apotheke B – Testdaten', sourceType: 'manual-review', sourceUrl: 'https://example.invalid/b', unitPriceCents: 675, shippingCents: 0, pickup: false, shipping: true, available: true, checkedAt: hoursAgo(3) },
  { id: 'offer-c', productId: 'beta', productName: 'Testextrakt Beta 10/10', manufacturer: 'Testlabor Süd', form: 'extract', thcPercent: 10, cbdPercent: 10, pharmacyId: 'test-c', pharmacyName: 'Muster-Apotheke C – Testdaten', sourceType: 'public-source', sourceUrl: 'https://example.invalid/c', unitPriceCents: 710, shippingCents: 499, pickup: true, shipping: true, available: true, checkedAt: hoursAgo(30), distanceMeters: 5100 }
]
export const inMemoryOffersRepository = createInMemoryOffersRepository(syntheticOffers)
```

- [ ] **Step 4: Verify and commit**

Run: `pnpm vitest run src/data && pnpm build`

Expected: repository test passes and the build succeeds.

```bash
git add src/data
git commit -m "feat: add synthetic offer repository"
```

### Task 4: Device-Only Age Confirmation and Favorites

**Files:**
- Create: `src/storage/device-preferences.ts`
- Create: `src/storage/device-preferences.test.ts`
- Create: `src/components/AgeGate.tsx`
- Create: `src/components/AgeGate.test.tsx`

**Interfaces:**
- Consumes: offer IDs as strings.
- Produces: `devicePreferences` with `isAdultConfirmed`, `confirmAdult`, `getFavoriteIds`, and `toggleFavorite`; `AgeGate({ onConfirm })`.

- [ ] **Step 1: Write failing storage and UI tests**

```ts
import { beforeEach, describe, expect, it } from 'vitest'
import { devicePreferences } from './device-preferences'

describe('device preferences', () => {
  beforeEach(() => localStorage.clear())
  it('stores only an adult boolean and favorite IDs', () => {
    devicePreferences.confirmAdult(); devicePreferences.toggleFavorite('offer-a')
    expect(Object.keys(localStorage).sort()).toEqual(['weedpreis.adult', 'weedpreis.favorites'])
    expect(devicePreferences.getFavoriteIds()).toEqual(['offer-a'])
  })
})
```

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { AgeGate } from './AgeGate'

it('requires explicit adult confirmation', async () => {
  const onConfirm = vi.fn(); render(<AgeGate onConfirm={onConfirm} />)
  await userEvent.click(screen.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }))
  expect(onConfirm).toHaveBeenCalledOnce()
})
```

- [ ] **Step 2: Run red**

Run: `pnpm vitest run src/storage src/components/AgeGate.test.tsx`

Expected: FAIL because storage and component do not exist.

- [ ] **Step 3: Implement storage and gate**

```ts
// src/storage/device-preferences.ts
const ADULT_KEY = 'weedpreis.adult'; const FAVORITES_KEY = 'weedpreis.favorites'
export const devicePreferences = {
  isAdultConfirmed: () => localStorage.getItem(ADULT_KEY) === 'true',
  confirmAdult: () => localStorage.setItem(ADULT_KEY, 'true'),
  getFavoriteIds: (): string[] => JSON.parse(localStorage.getItem(FAVORITES_KEY) ?? '[]'),
  toggleFavorite(id: string): string[] {
    const ids = new Set(this.getFavoriteIds()); ids.has(id) ? ids.delete(id) : ids.add(id)
    const result = [...ids]; localStorage.setItem(FAVORITES_KEY, JSON.stringify(result)); return result
  }
}
```

```tsx
// src/components/AgeGate.tsx
export function AgeGate({ onConfirm }: { onConfirm: () => void }) {
  return <section className="age-gate" aria-labelledby="age-title"><h1 id="age-title">Nur für Erwachsene</h1><p>Diese App vergleicht verschreibungspflichtiges Medizinalcannabis. Sie ersetzt keine medizinische Beratung.</p><button onClick={onConfirm}>Ich bin mindestens 18 Jahre alt</button></section>
}
```

- [ ] **Step 4: Verify and commit**

Run: `pnpm vitest run src/storage src/components/AgeGate.test.tsx`

Expected: both tests pass.

```bash
git add src/storage src/components/AgeGate*
git commit -m "feat: add device-only age gate and favorites"
```

### Task 5: Search, Mode Selection, and Results UI

**Files:**
- Create: `src/components/SearchControls.tsx`
- Create: `src/components/OfferCard.tsx`
- Create: `src/components/ResultsList.tsx`
- Create: `src/components/SearchExperience.tsx`
- Create: `src/components/SearchExperience.test.tsx`
- Modify: `src/app/App.tsx`
- Modify: `src/app/App.test.tsx`
- Modify: `src/styles/app.css`

**Interfaces:**
- Consumes: `OffersRepository.search`, `RankedOffer`, `devicePreferences`.
- Produces: a complete shipping/pickup search flow with explicit synthetic-data banner, current/stale grouping, and external pharmacy links.

- [ ] **Step 1: Write the failing journey test**

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, it } from 'vitest'
import { App } from '../app/App'

beforeEach(() => localStorage.setItem('weedpreis.adult', 'true'))
it('searches test offers and shows transparent totals', async () => {
  render(<App />)
  expect(screen.getByText('Ausschließlich synthetische Testdaten')).toBeInTheDocument()
  await userEvent.type(screen.getByRole('searchbox'), 'Alpha')
  await userEvent.click(screen.getByRole('button', { name: 'Suchen' }))
  expect((await screen.findAllByText(/Gesamtpreis für 10 g/)).length).toBeGreaterThan(0)
  expect(screen.getAllByText(/zuletzt geprüft/).length).toBeGreaterThan(0)
})
```

- [ ] **Step 2: Run red**

Run: `pnpm vitest run src/components/SearchExperience.test.tsx`

Expected: FAIL because the search experience is absent.

- [ ] **Step 3: Implement focused components**

```tsx
// src/components/SearchControls.tsx
import { useState } from 'react'
import type { FulfillmentMode, OfferQuery, ProductForm } from '../domain/offer'
export function SearchControls({ onSearch }: { onSearch: (query: OfferQuery) => void }) {
  const [text, setText] = useState(''); const [grams, setGrams] = useState(10)
  const [mode, setMode] = useState<FulfillmentMode>('shipping'); const [postalCode, setPostalCode] = useState('')
  const [form, setForm] = useState<ProductForm | ''>(''); const [minThcPercent, setMinThcPercent] = useState('')
  return <form onSubmit={(event) => { event.preventDefault(); onSearch({ text, grams, mode, postalCode: mode === 'pickup' ? postalCode : undefined, form: form || undefined, minThcPercent: minThcPercent === '' ? undefined : Number(minThcPercent) }) }}>
    <fieldset><legend>Bezugsart</legend><button type="button" aria-pressed={mode === 'shipping'} onClick={() => setMode('shipping')}>Versand</button><button type="button" aria-pressed={mode === 'pickup'} onClick={() => setMode('pickup')}>Abholung</button></fieldset>
    <label>Präparat oder Hersteller<input type="search" value={text} onChange={(event) => setText(event.target.value)} /></label>
    <label>Menge in Gramm<input type="number" min="1" max="100" value={grams} onChange={(event) => setGrams(Number(event.target.value))} /></label>
    <label>Darreichungsform<select value={form} onChange={(event) => setForm(event.target.value as ProductForm | '')}><option value="">Alle Formen</option><option value="flower">Blüten</option><option value="extract">Extrakte</option></select></label>
    <label>THC mindestens in Prozent<input type="number" min="0" max="100" step="0.1" value={minThcPercent} onChange={(event) => setMinThcPercent(event.target.value)} /></label>
    {mode === 'pickup' && <label>Postleitzahl<input inputMode="numeric" pattern="[0-9]{5}" value={postalCode} onChange={(event) => setPostalCode(event.target.value)} /></label>}
    <button type="submit">Suchen</button>
  </form>
}
```

```tsx
// src/components/OfferCard.tsx
import { useState } from 'react'
import type { RankedOffer } from '../domain/offer'
import { devicePreferences } from '../storage/device-preferences'
const euros = (cents: number) => new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)
export function OfferCard({ result, grams }: { result: RankedOffer; grams: number }) {
  const { offer, totalPriceCents, current } = result
  const [favorite, setFavorite] = useState(devicePreferences.getFavoriteIds().includes(offer.id))
  return <article className={current ? 'offer-card' : 'offer-card stale'}><p>{current ? 'Aktuelles Angebot' : 'Zuletzt gesehen'}</p><h3>{offer.pharmacyName}</h3><p>{offer.productName} · {offer.manufacturer}</p><p>THC {offer.thcPercent}% · CBD {offer.cbdPercent}% · {offer.form === 'flower' ? 'Blüte' : 'Extrakt'}</p><strong>{euros(offer.unitPriceCents)} / g</strong><p>Gesamtpreis für {grams} g: {euros(totalPriceCents)}</p><p>{offer.available ? 'verfügbar' : 'nicht verfügbar'} · {offer.sourceType} · zuletzt geprüft {new Date(offer.checkedAt).toLocaleString('de-DE')}</p><button aria-pressed={favorite} onClick={() => { setFavorite(devicePreferences.toggleFavorite(offer.id).includes(offer.id)) }}>{favorite ? 'Favorit entfernen' : 'Als Favorit speichern'}</button><a href={offer.sourceUrl} target="_blank" rel="noopener noreferrer">Zur Apotheke</a></article>
}
```

```tsx
// src/components/ResultsList.tsx
import type { RankedOffer } from '../domain/offer'
import { OfferCard } from './OfferCard'
export function ResultsList({ results, grams }: { results: RankedOffer[]; grams: number }) {
  const current = results.filter((result) => result.current); const stale = results.filter((result) => !result.current)
  if (!results.length) return <p>Keine passenden Angebote gefunden.</p>
  return <section aria-live="polite"><h2>{current.length} aktuelle Angebote</h2>{current.map((result) => <OfferCard key={result.offer.id} result={result} grams={grams} />)}{stale.length > 0 && <><h2>Zuletzt gesehen</h2>{stale.map((result) => <OfferCard key={result.offer.id} result={result} grams={grams} />)}</>}</section>
}
```

```tsx
// src/components/SearchExperience.tsx
import { useState } from 'react'
import type { OfferQuery, RankedOffer } from '../domain/offer'
import type { OffersRepository } from '../data/offers-repository'
import { ResultsList } from './ResultsList'
import { SearchControls } from './SearchControls'
export function SearchExperience({ repository }: { repository: OffersRepository }) {
  const [results, setResults] = useState<RankedOffer[] | null>(null); const [grams, setGrams] = useState(10)
  const [status, setStatus] = useState<'idle' | 'loading' | 'error'>('idle')
  async function search(query: OfferQuery) { setStatus('loading'); setResults(null); setGrams(query.grams); try { setResults(await repository.search(query)); setStatus('idle') } catch { setStatus('error') } }
  return <><SearchControls onSearch={search} />{status === 'loading' && <p role="status">Angebote werden geladen …</p>}{status === 'error' && <p role="alert">Angebote konnten nicht geladen werden. Es wird keine Verfügbarkeit angenommen.</p>}{results && <ResultsList results={results} grams={grams} />}</>
}
```

```tsx
// src/app/App.tsx
import { useState } from 'react'
import { AgeGate } from '../components/AgeGate'
import { SearchExperience } from '../components/SearchExperience'
import { inMemoryOffersRepository } from '../data/synthetic-offers'
import { devicePreferences } from '../storage/device-preferences'

export function App() {
  const [adult, setAdult] = useState(devicePreferences.isAdultConfirmed())
  if (!adult) return <main className="app-shell"><AgeGate onConfirm={() => { devicePreferences.confirmAdult(); setAdult(true) }} /></main>
  return <main className="app-shell"><header><h1>Weedpreis</h1><p>Neutraler Apothekenvergleich</p></header><div role="status" className="test-data-banner">Ausschließlich synthetische Testdaten</div><SearchExperience repository={inMemoryOffersRepository} /></main>
}
```

Add `beforeEach(() => localStorage.setItem('weedpreis.adult', 'true'))` to `src/app/App.test.tsx` so its original identity assertions continue to test the post-gate application shell.

```css
button, input { min-height: 44px; border-radius: 12px; }
button { border: 0; background: #5fd4a7; color: #092018; font-weight: 750; padding: 10px 14px; }
button[aria-pressed="false"] { background: #14221d; color: #d9e4df; }
input { width: 100%; margin-top: 6px; padding: 10px 12px; background: #f3f7f5; color: #18231f; border: 1px solid #284039; }
label, fieldset { display: block; margin: 14px 0; }
:focus-visible { outline: 3px solid #8fe7c7; outline-offset: 3px; }
.test-data-banner { margin: 16px 0; padding: 10px; border: 1px solid #866d2b; border-radius: 12px; color: #f1d684; }
.offer-card { margin: 12px 0; padding: 16px; border: 1px solid #2f6857; border-radius: 16px; background: #111f1a; }
.offer-card.stale { opacity: .72; border-color: #3c4758; }
.offer-card a { display: inline-block; margin-left: 10px; color: #8fe7c7; }
```

Do not add effect, strain, symptom, or treatment copy.

- [ ] **Step 4: Verify UI behavior and commit**

Run: `pnpm vitest run src/components src/app && pnpm build`

Expected: all component tests pass and build succeeds.

```bash
git add src/app src/components src/styles/app.css
git commit -m "feat: add neutral offer search experience"
```

### Task 6: Tabs, Favorites, Information, and Failure States

**Files:**
- Create: `src/components/AppNavigation.tsx`
- Create: `src/components/FavoritesView.tsx`
- Create: `src/components/InfoView.tsx`
- Create: `src/components/AppNavigation.test.tsx`
- Modify: `src/app/App.tsx`

**Interfaces:**
- Consumes: local favorite IDs and synthetic repository records.
- Produces: three tabs `Suche`, `Favoriten`, `Info`; factual prescription notice and privacy summary.

- [ ] **Step 1: Write failing navigation test**

```tsx
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { AppNavigation } from './AppNavigation'

it('exposes all three primary destinations', async () => {
  const onSelect = vi.fn(); render(<AppNavigation active="search" onSelect={onSelect} />)
  expect(screen.getAllByRole('button').map((button) => button.textContent)).toEqual(['Suche', 'Favoriten', 'Info'])
  await userEvent.click(screen.getByRole('button', { name: 'Info' }))
  expect(onSelect).toHaveBeenCalledWith('info')
})
```

- [ ] **Step 2: Run red, then implement navigation and views**

Run: `pnpm vitest run src/components/AppNavigation.test.tsx`

Expected: FAIL because `AppNavigation` does not exist.

```tsx
// src/components/AppNavigation.tsx
export type AppTab = 'search' | 'favorites' | 'info'
export function AppNavigation({ active, onSelect }: { active: AppTab; onSelect: (tab: AppTab) => void }) {
  return <nav aria-label="Hauptnavigation">{([['search', 'Suche'], ['favorites', 'Favoriten'], ['info', 'Info']] as const).map(([tab, label]) => <button key={tab} aria-current={active === tab ? 'page' : undefined} onClick={() => onSelect(tab)}>{label}</button>)}</nav>
}
```

```tsx
// src/components/InfoView.tsx
export function InfoView() {
  return <section><h2>Informationen</h2><p>Medizinalcannabis ist verschreibungspflichtig.</p><p>Die Abgabe erfolgt ausschließlich durch Apotheken gegen ärztliche Verschreibung.</p><p>Diese App bietet keine medizinische Beratung.</p><p>Altersbestätigung und Favoriten bleiben auf diesem Gerät.</p></section>
}
```

Implement `FavoritesView` by filtering the already loaded `RankedOffer[]` against `new Set(devicePreferences.getFavoriteIds())`; render the same `ResultsList` component so totals, freshness, and source labels cannot diverge. Wire `AppTab` state in `App` without adding a routing dependency.

- [ ] **Step 3: Verify and commit**

Run: `pnpm vitest run && pnpm build`

Expected: complete suite passes and all three tabs typecheck.

```bash
git add src/app src/components
git commit -m "feat: add favorites and information tabs"
```

### Task 7: iPhone E2E, Offline Shell, and GitHub Verification

**Files:**
- Create: `playwright.config.ts`
- Create: `tests/e2e/iphone-flow.spec.ts`
- Create: `.github/workflows/verify.yml`
- Create: `.github/workflows/pages.yml`
- Modify: `vite.config.ts`
- Modify: `README.md`

**Interfaces:**
- Consumes: completed PWA.
- Produces: iPhone 14 browser test, cached app shell, clean CI gate, and Pages artifact.

- [ ] **Step 1: Add failing iPhone journey**

```ts
import { expect, test } from '@playwright/test'

test('adult user compares a 10 g shipping offer', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }).click()
  await page.getByRole('searchbox').fill('Alpha')
  await page.getByRole('button', { name: 'Suchen' }).click()
  await expect(page.getByText('Ausschließlich synthetische Testdaten')).toBeVisible()
  await expect(page.getByText(/Gesamtpreis für 10 g/).first()).toBeVisible()
  await expect(page.locator('meta[name="theme-color"]')).toHaveAttribute('content', '#07110f')
})
```

```ts
// playwright.config.ts
import { defineConfig, devices } from '@playwright/test'
export default defineConfig({ testDir: './tests/e2e', use: { baseURL: 'http://127.0.0.1:4173', ...devices['iPhone 14'] }, webServer: { command: 'pnpm build && pnpm vite preview --host 127.0.0.1', port: 4173, reuseExistingServer: !process.env.CI } })
```

Run: `pnpm exec playwright install webkit && pnpm test:e2e`.

Expected: first run fails if any accessible labels or results are missing; fix only the failing behavior, then rerun until PASS.

- [ ] **Step 2: Add GitHub verification and Pages workflows**

```yaml
# .github/workflows/verify.yml
name: Verify
on: [push, pull_request]
jobs:
  verify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: pnpm/action-setup@v6
        with: { version: 11.9.0 }
      - uses: actions/setup-node@v6
        with: { node-version: 24, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm test
      - run: pnpm build
```

```yaml
# .github/workflows/pages.yml
name: Deploy Pages
on: { push: { branches: [main] } }
permissions: { contents: read, pages: write, id-token: write }
concurrency: { group: pages, cancel-in-progress: true }
jobs:
  deploy:
    environment: { name: github-pages, url: "${{ steps.deployment.outputs.page_url }}" }
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: pnpm/action-setup@v6
        with: { version: 11.9.0 }
      - uses: actions/setup-node@v6
        with: { node-version: 24, cache: pnpm }
      - run: pnpm install --frozen-lockfile
      - run: pnpm build
        env: { VITE_BASE_PATH: "/${{ github.event.repository.name }}/" }
      - uses: actions/upload-pages-artifact@v3
        with: { path: dist }
      - id: deployment
        uses: actions/deploy-pages@v4
```

In `README.md`, document local commands, the synthetic-data limitation, device-only storage, the read-only meaning of `Überprüfen`, and the fact that live Supabase data and real pharmacy adapters belong to later roadmap stages.

- [ ] **Step 3: Run the complete release gate**

Run: `pnpm test && pnpm build && pnpm test:e2e && git diff --check`

Expected: all unit/component tests pass, production build succeeds, WebKit iPhone test passes, and `git diff --check` prints nothing.

- [ ] **Step 4: Commit the verified foundation**

```bash
git add playwright.config.ts tests .github vite.config.ts README.md
git commit -m "ci: verify and publish pwa foundation"
```

## Completion Gate

The foundation is complete only when the clean-check command passes, the Git working tree contains no accidental generated files, the UI visibly says all records are synthetic test data, and no Supabase key, real pharmacy name, health datum, or location history exists in the repository. After this gate, write the separate Supabase data-platform implementation plan from the roadmap; do not add real pharmacy adapters until each source and its usage permission are documented.
