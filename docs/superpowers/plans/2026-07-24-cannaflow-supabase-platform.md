# Cannaflow Supabase Data Platform Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the synthetic-only offer source with a secure, testable Supabase read platform and a fixture-proven Cannaflow importer while keeping live publication disabled until partner permission and the 48-hour acceptance gate are complete.

**Architecture:** A scheduled Supabase Edge Function reads the approved Cannaflow list endpoints, stores immutable source pages in a private ingestion schema, normalizes accepted records into a private catalog schema, and atomically refreshes denormalized tables in the exposed `api` schema. The React PWA keeps its `OffersRepository` boundary, selects either the synthetic or Supabase implementation at build time, resolves German postal codes locally, and uses a read-only PostGIS function for pickup distance. No browser code can access partner credentials, canonical tables, raw payloads, or administrative writes.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Playwright 1.61.1, Supabase CLI 2.109.1, `@supabase/supabase-js` 2.110.8, Supabase Postgres/PostGIS/Edge Functions/Cron/Vault, Deno 2.8.1

## Global Constraints

- Implement the approved design in `docs/superpowers/specs/2026-07-24-cannaflow-supabase-data-platform-design.md`; scope changes require a design update before code changes.
- Cannaflow access is limited to approved read-only pharmacy, product, and explicitly permitted metadata endpoints. Never call prescription, checkout, payment, favorite, or webhook endpoints.
- Keep `CANNAFLOW_API_KEY`, `SUPABASE_SERVICE_ROLE_KEY`, and the cron invocation secret out of browser bundles, Git history, fixtures, test output, and logs.
- Supabase is the only new hosted background service. Local Docker/Deno tooling is development infrastructure, not another production service.
- Expose only the `api` schema through the Supabase Data API. The `ingest` and `catalog` schemas receive no `anon` or `authenticated` privileges.
- Enable RLS on every exposed table. The `anon` role receives only the exact `SELECT` and function-execution grants required by the PWA.
- Public lookup functions use invoker rights. The administrative publication function may use definer rights only with an empty `search_path`, fully qualified object names, revoked default execution, and an explicit `service_role` grant.
- An offer is current only while `now - sourceCheckedAt < 24 hours`. Exactly 24 hours is stale and excluded from the price ranking.
- Never replace the partner timestamp with the import time. A failed fetch must not make existing data appear newer.
- A price change greater than 30 percent in either direction, compared with the last accepted snapshot for the same pharmacy, product, and unit, opens a review case and blocks that new offer version.
- Never estimate a missing price, quantity, unit, shipping amount, distance, stock state, or product match.
- Shipping offers without a computable standard-shipping amount may be displayed with “Versandkosten nicht verfügbar”, but they cannot receive a total price or enter total-price ranking.
- Pickup, standard shipping, express shipping, and same-day delivery remain distinct. The standard shipping ranking never silently chooses express or same-day service.
- Do not store user postal codes, exact addresses, search history, favorites, or age confirmation in Supabase. Postal-code-to-centroid resolution happens in the PWA.
- Favorites and age confirmation remain local to the device.
- CI uses immutable Cannaflow fixtures and never contacts the partner API.
- Production publication starts disabled. It can be enabled only after written partner/data-use approval, secret configuration, eight consecutive acceptable imports spanning at least 48 hours, and a documented sample comparison.
- Preserve the visible iPhone status bar blended into the existing dark background.
- A request containing only `Prüfen` or `Überprüfen` authorizes read-only verification, not edits.

---

## Target File Structure

### Supabase and import platform

- `supabase/config.toml`: local project configuration; only `api` is an exposed application schema.
- `supabase/seed.sql`: deterministic local source, catalog, and public-read fixtures.
- `supabase/migrations/*_cannaflow_data_platform.sql`: CLI-generated migration containing schemas, tables, constraints, functions, RLS, grants, and indexes.
- `supabase/tests/database/01_schema_and_quality.test.sql`: pgTAP constraints, idempotency, and publication tests.
- `supabase/tests/database/02_public_access.test.sql`: pgTAP public-read and negative privilege tests.
- `supabase/deno.json`: pinned Edge Function imports and Deno tasks.
- `supabase/functions/_shared/cannaflow/contracts.ts`: exact source transport types and runtime parsers.
- `supabase/functions/_shared/cannaflow/client.ts`: API-key transport, pagination, timeout, and one bounded retry.
- `supabase/functions/_shared/cannaflow/normalize.ts`: pure pharmacy, product, offer, and delivery normalization.
- `supabase/functions/_shared/cannaflow/quality.ts`: versioned publication rules and review-case decisions.
- `supabase/functions/_shared/cannaflow/import-runner.ts`: run lifecycle, persistence ports, and per-pharmacy isolation.
- `supabase/functions/_shared/cannaflow/supabase-store.ts`: service-role implementation of the persistence port.
- `supabase/functions/import-cannaflow/index.ts`: protected scheduled Edge Function entry point.
- `supabase/functions/tests/cannaflow/`: Deno unit and integration tests.
- `supabase/functions/tests/fixtures/cannaflow/`: immutable pharmacy and product pages; all names clearly marked as test data.

### Postal-code reference

- `scripts/build-postal-centroids.mjs`: deterministic GeoNames download, validation, normalization, and JSON generation.
- `data/geonames/README.md`: CC BY 4.0 attribution, source URL, retrieval date, source checksum, transformation rules, and update command.
- `data/geonames/DE.zip.sha256`: accepted source-archive checksum.
- `public/data/de-postal-centroids.v1.json`: normalized German postal code to centroid map loaded by the PWA.
- `src/data/postal-centroids.ts`: local lookup and validation wrapper.
- `src/data/postal-centroids.test.ts`: lookup, invalid-input, and no-persistence tests.

### PWA integration

- `.env.example`: public-only Vite settings; no partner or service-role secret names with values.
- `src/config/runtime-config.ts`: strict `synthetic` versus `supabase` build configuration.
- `src/config/runtime-config.test.ts`: invalid/missing configuration behavior.
- `src/data/supabase/database.types.ts`: generated public API types.
- `src/data/supabase/supabase-client.ts`: anonymous browser client.
- `src/data/supabase/shipping.ts`: deterministic standard-shipping rule evaluation.
- `src/data/supabase/supabase-offers-repository.ts`: public-table and pickup-RPC adapter.
- `src/data/supabase/supabase-offers-repository.test.ts`: repository mapping, filtering, ranking, and failure tests.
- `src/components/DataSourceBanner.tsx`: visible synthetic/live/read-error source state.
- Existing domain and UI files: nullable shipping totals, postal-code pickup control, source freshness, stale separation, and errors.

### Operations and CI

- `docs/operations/cannaflow-activation.md`: permission, secret, scheduling, observation, comparison, rollback, and public-enable runbook.
- `docs/operations/cannaflow-import-evidence.md`: append-only acceptance table for the eight observed runs and sample audit.
- `.github/workflows/verify.yml`: PWA, Edge Function, database, build, and secret-leak gates without live partner calls.
- `README.md`: local Supabase workflow, data modes, privacy boundary, GeoNames attribution, and activation state.

---

### Task 1: Pin the Supabase Toolchain and Create a Reproducible Local Shell

**Files:**
- Modify: `package.json`
- Modify: `pnpm-lock.yaml`
- Modify: `.gitignore`
- Create: `.env.example`
- Create: `supabase/config.toml`
- Create: `supabase/seed.sql`
- Create: `supabase/deno.json`
- Modify: `README.md`

**Interfaces:**
- Produces scripts: `supabase:start`, `supabase:stop`, `test:functions`, `test:db`, `check:data`, `types:db`.
- Produces public Vite variables: `VITE_DATA_MODE`, `VITE_SUPABASE_URL`, `VITE_SUPABASE_PUBLISHABLE_KEY`.
- Produces server-only secret names: `CANNAFLOW_API_KEY`, `CANNAFLOW_BASE_URL`, `IMPORT_CRON_SECRET`, `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`.

- [ ] **Step 1: Recheck current Supabase conventions before changing files**

Read the current Supabase changelog and the official pages for local development, schema exposure, Edge Function dependency management, function testing, scheduled functions, Vault, RLS, and PostGIS. Run:

```sh
pnpm dlx supabase@2.109.1 --help
pnpm dlx supabase@2.109.1 init --help
pnpm dlx supabase@2.109.1 test db --help
pnpm dlx supabase@2.109.1 gen types --help
```

Expected: all four commands exit successfully. If current official guidance conflicts with this plan, pause implementation and amend the approved design and this plan before coding.

- [ ] **Step 2: Add the pinned client and CLI**

Run:

```sh
pnpm add @supabase/supabase-js@2.110.8
pnpm add -D supabase@2.109.1
```

Add these scripts:

```json
{
  "scripts": {
    "supabase:start": "supabase start",
    "supabase:stop": "supabase stop",
    "test:functions": "deno task --config supabase/deno.json test",
    "test:db": "supabase test db",
    "check:data": "pnpm test:functions && pnpm test:db",
    "types:db": "supabase gen types typescript --local --schema api > src/data/supabase/database.types.ts"
  }
}
```

Keep the existing `test`, `build`, `test:e2e`, and `check` scripts.

- [ ] **Step 3: Initialize the local Supabase project through the CLI**

Run:

```sh
pnpm exec supabase init
```

Do not hand-invent generated project identifiers or migration timestamps. Configure the generated `supabase/config.toml` so the local Data API exposes `api` plus the required built-in GraphQL schema, not `ingest` or `catalog`. Keep the import function locally protected; do not make it a public browser endpoint.

Create `supabase/deno.json` with Deno 2-compatible settings, pinned imports for Supabase JS `2.110.8` and the Deno standard assertion/testing packages, and:

```json
{
  "tasks": {
    "test": "deno test functions/tests --allow-env --allow-net=127.0.0.1"
  }
}
```

- [ ] **Step 4: Define safe environment boundaries**

Create `.env.example` containing only:

```dotenv
VITE_DATA_MODE=synthetic
VITE_SUPABASE_URL=
VITE_SUPABASE_PUBLISHABLE_KEY=
```

Add local Supabase environment files, downloaded partner archives, and generated temporary files to `.gitignore`. Do not add `SUPABASE_SERVICE_ROLE_KEY`, `CANNAFLOW_API_KEY`, or `IMPORT_CRON_SECRET` to `.env.example`; document their Supabase Secrets names in `README.md` without values.

- [ ] **Step 5: Verify the empty local stack and commit**

Run:

```sh
pnpm install --frozen-lockfile
pnpm exec supabase start
pnpm exec supabase status
pnpm build
pnpm exec supabase stop
git diff --check
```

Expected: the local stack reports healthy services, the existing PWA build succeeds, and no ignored secret file is staged.

```sh
git add package.json pnpm-lock.yaml .gitignore .env.example supabase/config.toml supabase/seed.sql supabase/deno.json README.md
git commit -m "chore: initialize pinned Supabase toolchain"
```

### Task 2: Build the Private Schemas, Public Read Model, and Access Boundary

**Files:**
- Create via CLI: `supabase/migrations/*_cannaflow_data_platform.sql`
- Create: `supabase/tests/database/01_schema_and_quality.test.sql`
- Create: `supabase/tests/database/02_public_access.test.sql`
- Modify: `supabase/seed.sql`

**Interfaces:**
- Private schemas: `ingest`, `catalog`.
- Exposed schema: `api`.
- Public tables: `api.published_offers`, `api.published_pharmacies`.
- Public function: `api.search_pickup_offers(origin_lat, origin_lng, max_distance_m, query_text, product_form, min_thc_percent, result_limit)`.
- Administrative function: `api.publish_import(import_run_id uuid)`, executable only by `service_role`.

- [ ] **Step 1: Create the migration filename through the CLI**

Run:

```sh
pnpm exec supabase migration new cannaflow_data_platform
```

Use the generated `*_cannaflow_data_platform.sql` path for all SQL in this task. Do not rename it to an invented timestamp.

- [ ] **Step 2: Write failing pgTAP schema and security tests**

In `01_schema_and_quality.test.sql`, assert:

- `ingest`, `catalog`, and `api` exist.
- `postgis` is installed in the extensions schema.
- all required tables, primary keys, foreign keys, unique keys, check constraints, and freshness/spatial indexes exist;
- a duplicate raw page checksum for the same run/endpoint/page is rejected;
- a duplicate canonical source pharmacy, source product alias, offer, or snapshot is rejected;
- negative prices, non-positive quantities, invalid coordinates, and invalid run transitions are rejected;
- `api.publish_import` replaces both public tables in one transaction and repeating it for the same successful run leaves identical rows.

In `02_public_access.test.sql`, switch to the `anon` and `authenticated` roles and assert:

- `anon` can select only the intended columns from both public tables;
- `anon` can execute only `api.search_pickup_offers`;
- `anon` cannot insert, update, truncate, or delete public rows;
- neither public role can resolve or select any `ingest` or `catalog` table;
- neither public role can execute `api.publish_import`;
- public lookup functions are `SECURITY INVOKER`;
- every exposed table has RLS enabled.

Run:

```sh
pnpm exec supabase start
pnpm test:db
```

Expected: FAIL because the schemas and objects do not exist.

- [ ] **Step 3: Implement exact private ingestion objects**

Create:

- `ingest.data_sources`: UUID primary key, unique stable key, source kind, base URL, `enabled`, `usage_approved_at`, approval reference, `publication_enabled`, 360-minute interval, last-success timestamp, timestamps.
- `ingest.import_runs`: source, prior-success link, `running|succeeded|succeeded_with_review|failed`, start/end, fetched/accepted/rejected/published counts, safe error class/message, aggregate content checksum.
- `ingest.raw_payloads`: run, endpoint, page key, fetched timestamp, immutable JSON payload, SHA-256; unique by run/endpoint/page and by run/checksum.
- `ingest.review_cases`: source, run, entity kind/key, rule code, `warning|blocking`, `open|approved|rejected|resolved`, previous/current safe JSON fragments, decision timestamp, reason.

Use database checks to prevent negative counts and completed states without `finished_at`. Do not put secret values or headers in any column.

- [ ] **Step 4: Implement exact private catalog objects**

Create:

- `catalog.pharmacies`: source and source pharmacy ID, public name/domain/URL, active/publishable flags.
- `catalog.pharmacy_locations`: pharmacy, public address fields, location kind, `extensions.geography(Point,4326)`.
- `catalog.products`: canonical product name, manufacturer, `flower|extract`, THC/CBD values, `g|ml`.
- `catalog.product_aliases`: source, source product ID/name, canonical product, `automatic|manual`, `pending|approved|rejected`.
- `catalog.offers`: stable source offer key, pharmacy, product, source product ID, integer price cents, positive source quantity, unit, normalized unit price cents, availability, source timestamp, fetch timestamp, quality status, accepted run.
- `catalog.delivery_rules`: pharmacy, `standard|express|pickup|same_day`, nullable base price, ordered threshold-price JSON rules, optional documented radius/postal restriction, source timestamp, accepted run.
- `catalog.offer_snapshots`: offer, integer price, availability, source timestamp, content checksum, accepted run.

Use exact unique keys for `(data_source_id, source_pharmacy_id)`, `(data_source_id, source_product_id)`, `(data_source_id, source_offer_key)`, and `(offer_id, source_checked_at, content_checksum)`. Add indexes on all foreign keys, source timestamps, publication predicates, and spatial columns.

- [ ] **Step 5: Implement the denormalized public objects**

`api.published_pharmacies` contains only the public pharmacy ID/name/URL/address, fulfillment flags, location point, source label, source timestamp, and publication timestamp.

`api.published_offers` contains:

```text
offer_id, product_id, product_name, manufacturer, product_form,
thc_percent, cbd_percent, pharmacy_id, pharmacy_name, pharmacy_url,
price_unit, unit_price_cents, available,
standard_shipping_rules, shipping_available, pickup_available,
express_available, same_day_available,
source_label, source_url, source_checked_at, published_at
```

Use integer cents and JSON shipping rules with a database constraint that accepts only ordered objects of the form `{thresholdCents, priceCents}` with non-negative integers. Do not publish raw payloads, internal IDs unrelated to stable offer identity, review content, exact credentials, or import errors.

Enable RLS and add a `TO anon USING (true)` select policy on the two public tables. Revoke all default privileges first, then grant only schema usage and table select.

- [ ] **Step 6: Implement public pickup search and atomic publication**

Create `api.search_pickup_offers` as `LANGUAGE sql STABLE SECURITY INVOKER`. It validates latitude `-90..90`, longitude `-180..180`, distance `1..200000`, and result limit `1..200`; filters published, available, pickup-enabled offers; applies optional search/form/THC filters; computes `ST_DWithin` and `ST_Distance`; and returns the public offer columns plus `distance_m`, ordered by distance then stable offer ID.

Create `api.publish_import` as the single administrative exception:

- `SECURITY DEFINER SET search_path = ''`;
- fully qualified identifiers only;
- accepts only a completed `succeeded` or `succeeded_with_review` run;
- locks publication to prevent overlapping swaps;
- deletes and reinserts both public tables inside one database transaction from accepted canonical rows;
- includes unchanged last accepted rows for an isolated failing pharmacy without changing their source timestamps;
- omits blocked rows and never changes freshness timestamps;
- updates the run’s published count;
- revokes execution from `PUBLIC`, `anon`, and `authenticated`, then grants it only to `service_role`.

- [ ] **Step 7: Seed deterministic local rows and make tests green**

Seed one approved source with publication enabled only in the local seed, two clearly synthetic pharmacies, flower and extract products, one pickup point, one fully priced shipping rule, one shipping rule with missing cost, one stale snapshot, and one open review case. All names and domains must contain `Testdaten` or `.invalid`.

Run:

```sh
pnpm exec supabase db reset
pnpm test:db
pnpm exec supabase db lint --level error
git diff --check
```

Expected: all pgTAP tests pass and database lint reports no errors.

```sh
git add supabase/migrations supabase/tests/database supabase/seed.sql
git commit -m "feat: add protected comparison data model"
```

### Task 3: Create the Licensed Local Postal-Code Centroid Dataset

**Files:**
- Create: `scripts/build-postal-centroids.mjs`
- Create: `scripts/build-postal-centroids.test.mjs`
- Create: `data/geonames/README.md`
- Create: `data/geonames/DE.zip.sha256`
- Create: `public/data/de-postal-centroids.v1.json`
- Create: `src/data/postal-centroids.ts`
- Create: `src/data/postal-centroids.test.ts`
- Modify: `package.json`
- Modify: `README.md`

**Interfaces:**
- `loadPostalCentroids(fetcher?): Promise<PostalCentroidIndex>`
- `resolvePostalCentroid(index, postalCode): { latitude: number; longitude: number } | null`
- Script: `pnpm data:postal-codes`.

- [ ] **Step 1: Write failing parser and browser-lookup tests**

Test a small inline GeoNames row set for:

- trimming and accepting exactly five ASCII digits;
- rejecting malformed, duplicate-with-conflicting-coordinate, out-of-Germany, and out-of-range rows;
- deterministic key ordering and fixed numeric precision;
- returning `null` for an unknown PLZ;
- not calling `localStorage`, Supabase, analytics, or any persistence API.

Run:

```sh
node --test scripts/build-postal-centroids.test.mjs
pnpm vitest run src/data/postal-centroids.test.ts
```

Expected: FAIL because the builder and browser lookup do not exist.

- [ ] **Step 2: Implement the deterministic GeoNames builder**

Download only `https://download.geonames.org/export/zip/DE.zip`. Parse the documented tab-separated fields, keep country code `DE`, group by postal code, and calculate one deterministic centroid per PLZ from the supplied coordinates. Sort by postal code and emit compact JSON:

```json
{"version":1,"license":"CC-BY-4.0","source":"GeoNames","postalCodes":{"10115":[52.532,13.384]}}
```

The generated metadata must contain source URL, retrieval date, and SHA-256. The script compares the archive against `data/geonames/DE.zip.sha256` and refuses an unreviewed upstream change. An intentional refresh updates the checksum, generated JSON, tests, and attribution in one commit.

- [ ] **Step 3: Implement local lazy loading**

`loadPostalCentroids` fetches `${import.meta.env.BASE_URL}data/de-postal-centroids.v1.json` once per page session and caches only the immutable reference map in memory. `resolvePostalCentroid` validates the five-digit PLZ and returns only the centroid. It never retains the submitted PLZ or writes browser storage.

- [ ] **Step 4: Generate, inspect, verify, and commit**

Add:

```json
{
  "scripts": {
    "data:postal-codes": "node scripts/build-postal-centroids.mjs",
    "test:postal-codes": "node --test scripts/build-postal-centroids.test.mjs && vitest run src/data/postal-centroids.test.ts"
  }
}
```

Run:

```sh
pnpm data:postal-codes
pnpm test:postal-codes
node -e "const d=require('./public/data/de-postal-centroids.v1.json'); if (!d.postalCodes['10115']) process.exit(1); console.log(Object.keys(d.postalCodes).length)"
git diff --check
```

Expected: tests pass, a non-zero count is printed, and the generated file contains no names, addresses, or user data.

```sh
git add scripts data/geonames public/data src/data/postal-centroids.ts src/data/postal-centroids.test.ts package.json README.md
git commit -m "feat: add licensed local postal centroids"
```

### Task 4: Define and Test the Cannaflow Transport Contract

**Files:**
- Create: `supabase/functions/_shared/cannaflow/contracts.ts`
- Create: `supabase/functions/_shared/cannaflow/client.ts`
- Create: `supabase/functions/tests/fixtures/cannaflow/pharmacies-page-1.json`
- Create: `supabase/functions/tests/fixtures/cannaflow/products-page-1.json`
- Create: `supabase/functions/tests/fixtures/cannaflow/products-page-2.json`
- Create: `supabase/functions/tests/cannaflow/contracts.test.ts`
- Create: `supabase/functions/tests/cannaflow/client.test.ts`

**Interfaces:**

```ts
type SourcePage<T> = {
  data: T[]
  pagination: { page: number; pageSize: number; totalPages: number; totalItems: number }
}

interface CannaflowClient {
  fetchPharmacies(): Promise<SourcePage<SourcePharmacy>[]>
  fetchProducts(pharmacyIds?: string[]): Promise<SourcePage<SourceProduct>[]>
}
```

- [ ] **Step 1: Capture immutable, synthetic contract fixtures**

Model only documented fields needed by this phase:

- pharmacy ID, official/display name, domain, public address, latitude/longitude, and shipping options;
- product ID, name/base name, optional PZN, category, cultivar, manufacturer, THC/CBD, integer-cent price, currency, pharmacy identity, availability, quantity increment, minimum quantity, and optional available quantity;
- shipping option ID, integer-cent price when supplied, `standard|express|selfPickUp|sameDay`, threshold discounts, and documented pickup/restriction metadata.

Use structurally realistic but fictional records and `.invalid` domains. Store no captured production response or key.

- [ ] **Step 2: Write failing runtime-contract tests**

Test valid pages plus:

- missing `data` or pagination fields;
- non-integer cents;
- unknown category, availability, or shipping type;
- invalid coordinates;
- a page number outside `1..totalPages`;
- an extra field is tolerated, while a changed required field is rejected with a safe path-only message.

Run:

```sh
deno test --config supabase/deno.json supabase/functions/tests/cannaflow/contracts.test.ts
```

Expected: FAIL because the parser does not exist.

- [ ] **Step 3: Implement explicit source types and runtime parsing**

Implement small parser functions that return typed transport objects without normalizing them. Error messages may name the endpoint, page, and invalid JSON path but must never include headers or the complete payload.

- [ ] **Step 4: Write failing pagination, timeout, and retry tests**

Inject `fetch`, a clock, and a sleep function. Assert:

- base URL is exactly the configured production or sandbox Cannaflow API origin;
- the API key is sent only to that origin;
- all pages are fetched once in ascending order;
- pharmacy filters are encoded without string concatenation;
- duplicate page or entity IDs fail safely;
- a timeout/429/5xx is retried exactly once after a bounded delay;
- schema/4xx/auth failures are not retried;
- partial pagination never returns a successful result.

- [ ] **Step 5: Implement the least-privilege client**

Use a 10-second `AbortSignal.timeout`, one retry with a maximum two-second wait, and a fixed user agent identifying this comparison importer. Redact authorization headers and payloads from errors. The client returns complete page arrays only and contains no database or ranking logic.

- [ ] **Step 6: Verify no network access and commit**

Run:

```sh
deno task --config supabase/deno.json test
rg -n "api[_-]?key|authorization|service_role" supabase/functions/tests/fixtures -i
git diff --check
```

Expected: all tests pass; the fixture scan returns no credential-like fixture field or value.

```sh
git add supabase/functions/_shared/cannaflow supabase/functions/tests
git commit -m "feat: add fixture-proven Cannaflow client"
```

### Task 5: Normalize Offers and Enforce Publication Quality Rules

**Files:**
- Create: `supabase/functions/_shared/cannaflow/normalize.ts`
- Create: `supabase/functions/_shared/cannaflow/quality.ts`
- Create: `supabase/functions/tests/cannaflow/normalize.test.ts`
- Create: `supabase/functions/tests/cannaflow/quality.test.ts`
- Add fixtures under: `supabase/functions/tests/fixtures/cannaflow/quality/`

**Interfaces:**

```ts
type NormalizationResult<T> =
  | { status: 'accepted'; value: T }
  | { status: 'review'; case: ReviewCaseDraft }

const PRICE_JUMP_LIMIT = 0.30

function normalizePharmacy(source: SourcePharmacy): NormalizationResult<NormalizedPharmacy>
function normalizeProduct(source: SourceProduct, aliases: ProductAliasIndex): NormalizationResult<NormalizedOffer>
function normalizeDeliveryRules(source: SourcePharmacy): NormalizationResult<NormalizedDeliveryRule[]>
function evaluateOfferQuality(candidate: NormalizedOffer, previous?: AcceptedSnapshot): QualityDecision
```

- [ ] **Step 1: Write failing normalization tests**

Cover:

- `flower` to `g` and `extract` to `ml`;
- rejecting unsupported `capsule` and `shot` until the PWA domain explicitly supports them;
- positive integer-cent price and positive quantity conversion to normalized unit cents without floating-point money arithmetic;
- approved source-product alias required before publication;
- known availability mapping and unknown state rejection;
- source timestamp preserved independently from fetch timestamp;
- stable offer key from source, pharmacy, source product, and unit;
- public pharmacy URL restricted to the documented pharmacy domain with HTTPS.

Run the focused test and confirm it fails before implementation.

- [ ] **Step 2: Implement pure normalizers**

Return accepted values or structured review drafts; never throw for one bad pharmacy/product record. Preserve the raw payload separately and keep normalization output free of credentials and unrelated source fields.

- [ ] **Step 3: Write failing fulfillment tests**

Cover:

- standard base price and threshold discounts ordered by threshold;
- free standard shipping only when the source explicitly supplies zero;
- missing standard price remains `null`;
- express and same-day flags never change the standard total;
- self-pickup address/ETA never becomes a shipping cost;
- malformed or conflicting thresholds create a blocking review case;
- restrictions without enough information are retained internally but not presented as universally available.

- [ ] **Step 4: Write failing quality-rule tests**

Use table-driven tests for:

- exactly 30 percent change accepted;
- more than 30 percent up or down blocked;
- comparison limited to the same pharmacy, canonical product, and unit;
- no previous snapshot accepted when every other rule passes;
- zero/negative price, missing quantity/unit, unknown alias, changed unit, and future source time blocked;
- fully empty product result after a previously non-empty source blocks publication;
- one bad pharmacy does not reject valid pharmacies;
- two consecutive failed runs produce one open internal review case without duplicates.

- [ ] **Step 5: Implement versioned quality decisions**

Keep `PRICE_JUMP_LIMIT = 0.30` exported and tested. Emit stable rule codes such as `price_jump_gt_30_percent`, `unknown_product_alias`, `missing_shipping_price`, `empty_source`, and `schema_changed`. Treat missing shipping price as blocking only for total-price eligibility, not for basic offer publication.

- [ ] **Step 6: Verify and commit**

Run:

```sh
deno task --config supabase/deno.json test
git diff --check
```

Expected: normalization and quality tests pass with no live HTTP request.

```sh
git add supabase/functions/_shared/cannaflow supabase/functions/tests
git commit -m "feat: normalize and quality-gate source offers"
```

### Task 6: Implement Idempotent Import Persistence and Atomic Publication

**Files:**
- Create: `supabase/functions/_shared/cannaflow/import-runner.ts`
- Create: `supabase/functions/_shared/cannaflow/supabase-store.ts`
- Create: `supabase/functions/tests/cannaflow/import-runner.test.ts`
- Create: `supabase/functions/tests/cannaflow/supabase-store.integration.test.ts`
- Modify: `supabase/seed.sql`

**Interfaces:**

```ts
interface ImportStore {
  startRun(sourceKey: string): Promise<ImportRun>
  saveRawPage(runId: string, page: RawPage): Promise<void>
  loadApprovedAliases(sourceProductIds: string[]): Promise<ProductAliasIndex>
  loadPreviousSnapshots(keys: string[]): Promise<AcceptedSnapshotIndex>
  persistAcceptedBatch(runId: string, batch: AcceptedBatch): Promise<void>
  persistReviewCases(runId: string, cases: ReviewCaseDraft[]): Promise<void>
  completeRun(runId: string, result: RunResult): Promise<void>
  publishRun(runId: string): Promise<void>
  failRun(runId: string, error: SafeImportError): Promise<void>
}

function runCannaflowImport(deps: ImportDependencies): Promise<RunSummary>
```

- [ ] **Step 1: Write failing orchestration tests with in-memory ports**

Assert the exact sequence:

1. start run;
2. fetch and store all pharmacy pages;
3. fetch and store all product pages;
4. parse and group by pharmacy;
5. load aliases and previous snapshots;
6. normalize and quality-check each group independently;
7. persist accepted batches and review cases;
8. mark the run complete;
9. call atomic publication once.

Also assert:

- retrying identical content produces no duplicate canonical rows or snapshots;
- a failed fetch calls `failRun` and never `publishRun`;
- an incomplete page sequence never persists normalized rows;
- an invalid pharmacy group creates cases while another group publishes;
- unchanged prior accepted rows keep their old source timestamp;
- source-disabled, permission-not-approved, or overlapping runs stop before HTTP;
- safe summaries contain counts and rule codes, not payloads or headers.

- [ ] **Step 2: Implement the pure runner**

Use a database advisory lock per data source to prevent overlapping runs. Compute SHA-256 over canonicalized raw pages for idempotency. A repeated successful content hash records a completed no-change run and reuses accepted canonical rows without duplicating snapshots.

- [ ] **Step 3: Write failing local Supabase integration tests**

With the local stack running and the service role only inside the test process, assert:

- raw JSON round-trips unchanged;
- unique constraints make repeated persistence idempotent;
- accepted rows and review cases match run counts;
- a simulated failure between staging and publication leaves the old public tables unchanged;
- `api.publish_import` swaps a completed run atomically;
- public rows never expose review JSON or raw payload content.

- [ ] **Step 4: Implement `SupabaseImportStore`**

Use the service-role client only in the Edge Function runtime. Keep all table names explicit. Translate database errors to stable safe error classes. Call `api.publish_import` only after `completeRun` has persisted a valid terminal status and counts.

- [ ] **Step 5: Verify unit, integration, and database behavior**

Run:

```sh
pnpm exec supabase start
deno task --config supabase/deno.json test
pnpm test:db
pnpm exec supabase db lint --level error
pnpm exec supabase stop
git diff --check
```

Expected: all import and pgTAP tests pass; the public tables retain their previous checksum after the forced failure test.

```sh
git add supabase/functions supabase/seed.sql
git commit -m "feat: add idempotent Cannaflow import pipeline"
```

### Task 7: Protect the Edge Function and Define Six-Hour Scheduling

**Files:**
- Create: `supabase/functions/import-cannaflow/index.ts`
- Create: `supabase/functions/import-cannaflow/deno.json`
- Create: `supabase/functions/tests/import-cannaflow/index.test.ts`
- Create: `docs/operations/cannaflow-activation.md`
- Create: `docs/operations/cannaflow-import-evidence.md`
- Modify: `supabase/config.toml`

**Interfaces:**
- `POST /functions/v1/import-cannaflow`
- Required header: `x-import-cron-secret`.
- Success response: safe JSON summary with run ID, status, counts, duration, and review count.
- Schedule: `0 */6 * * *` in UTC.

- [ ] **Step 1: Write failing request-boundary tests**

Test:

- non-POST returns 405;
- missing/wrong cron secret returns 401 before source or database calls;
- disabled or unapproved source returns 409 without source calls;
- valid request runs once and returns only safe counters;
- thrown transport/database errors return a stable error class and run ID, never secret/header/payload content;
- overlapping invocation returns 409;
- response headers disable caching.

- [ ] **Step 2: Implement the protected handler**

Read `CANNAFLOW_API_KEY`, `CANNAFLOW_BASE_URL`, `IMPORT_CRON_SECRET`, `SUPABASE_URL`, and `SUPABASE_SERVICE_ROLE_KEY` only through `Deno.env`. Compare the invocation secret without logging it. Construct the client and store, call the runner, and redact unexpected errors.

Set the function’s gateway configuration according to the current Supabase scheduled-function guidance. The application-level cron secret check is mandatory even if the gateway also validates a JWT.

- [ ] **Step 3: Write the exact activation and rollback runbook**

The runbook must include:

1. attach written Cannaflow/data-use approval reference to `ingest.data_sources`;
2. set the five Supabase secrets without echoing their values;
3. deploy migrations and the function to a non-public Supabase environment;
4. invoke one sandbox/fixture-backed smoke run;
5. create the UTC schedule `0 */6 * * *` using Supabase Cron and Vault-supported secret handling;
6. verify eight consecutive acceptable run IDs whose first/last starts span at least 48 hours;
7. compare a documented sample of product, pharmacy, price, availability, and fulfillment fields with Cannaflow;
8. confirm no unresolved blocking review cases and no critical security/performance advisor findings;
9. set `publication_enabled = true`;
10. configure GitHub Pages public Supabase variables and deploy;
11. rollback by disabling source/publication and removing the schedule, while leaving audit records intact.

`docs/operations/cannaflow-import-evidence.md` contains an eight-row table with run ID, start/end, status, counts, review result, reviewer, and evidence timestamp, followed by the sample-audit and approval references. It begins with no fabricated live entries.

- [ ] **Step 4: Verify handler tests and secret hygiene**

Run:

```sh
deno task --config supabase/deno.json test
git grep -nE "(CANNAFLOW_API_KEY|SUPABASE_SERVICE_ROLE_KEY|IMPORT_CRON_SECRET)\\s*=" -- ':!docs/**' ':!.env.example'
git diff --check
```

Expected: handler tests pass and the secret-assignment scan returns no tracked value assignment.

```sh
git add supabase/functions supabase/config.toml docs/operations
git commit -m "feat: secure and schedule Cannaflow imports"
```

### Task 8: Make the PWA Pricing Domain Honest About Missing Costs and Stale Data

**Files:**
- Modify: `src/domain/offer.ts`
- Modify: `src/domain/pricing.ts`
- Modify: `src/domain/pricing.test.ts`
- Modify: `src/data/in-memory-offers-repository.ts`
- Modify: `src/data/in-memory-offers-repository.test.ts`
- Modify: `src/data/synthetic-offers.ts`
- Modify: `src/components/ResultsList.tsx`
- Create: `src/components/ResultsList.test.tsx`
- Modify: `src/components/OfferCard.tsx`
- Create: `src/components/OfferCard.test.tsx`
- Modify: `src/components/FavoritesView.tsx`
- Modify: `src/components/FavoritesView.test.tsx`

**Interfaces:**

```ts
interface Offer {
  // existing fields
  shippingCents: number | null
  sourceLabel: string
}

interface RankedOffer {
  offer: Offer
  totalPriceCents: number | null
  current: boolean
  rankingEligible: boolean
}

function totalPriceCents(offer: Offer, query: PricingContext): number | null
```

- [ ] **Step 1: Write failing pricing tests**

Assert:

- standard shipping with a known amount returns the expected total;
- missing shipping cost returns `null`, never zero;
- pickup total excludes shipping;
- exactly 24-hour-old rows are stale;
- current rows with complete totals rank by total;
- current rows without totals appear after ranked current rows;
- stale rows are ordered only by newest `checkedAt` then stable ID, never by price.

Run:

```sh
pnpm vitest run src/domain/pricing.test.ts
```

Expected: FAIL because shipping and totals are not nullable and no eligibility flag exists.

- [ ] **Step 2: Implement the domain change and update synthetic fixtures**

Keep the current `OffersRepository` method signatures. Compute `rankingEligible` as current, available, fulfillment-compatible, and complete-total. Preserve stale results for the separate “Zuletzt gesehen” section, but never mix them into the price-ranked section.

- [ ] **Step 3: Write failing component tests**

Assert:

- missing shipping price renders “Versandkosten nicht verfügbar” and no numeric total;
- current ranked, current unranked, and stale results have separate headings;
- stale cards say “Zuletzt gesehen”;
- source label and actual source check time are visible;
- favorites preserve a missing total instead of converting it to zero.

- [ ] **Step 4: Implement accessible presentation**

`ResultsList` renders:

1. “Preisvergleich” for ranking-eligible current rows;
2. “Weitere aktuelle Angebote” for current rows without a total;
3. “Zuletzt gesehen” for stale rows.

Keep the offer card link safe with `noopener noreferrer`. Do not render a total when `totalPriceCents` is `null`.

- [ ] **Step 5: Verify and commit**

Run:

```sh
pnpm test
pnpm build
git diff --check
```

Expected: all existing and new PWA tests pass and TypeScript accepts nullable totals.

```sh
git add src/domain src/data/in-memory-offers-repository* src/data/synthetic-offers.ts src/components
git commit -m "feat: exclude incomplete and stale totals from ranking"
```

### Task 9: Add the Anonymous Supabase Repository and Local Pickup Search

**Files:**
- Create: `src/data/supabase/database.types.ts`
- Create: `src/data/supabase/supabase-client.ts`
- Create: `src/data/supabase/shipping.ts`
- Create: `src/data/supabase/shipping.test.ts`
- Create: `src/data/supabase/supabase-offers-repository.ts`
- Create: `src/data/supabase/supabase-offers-repository.test.ts`
- Modify: `src/data/offers-repository.ts`
- Modify: `src/vite-env.d.ts`

**Interfaces:**

```ts
function createAnonymousSupabaseClient(url: string, publishableKey: string): SupabaseClient<Database>
function shippingCentsForSubtotal(rules: ShippingRule[], subtotalCents: number): number | null
function createSupabaseOffersRepository(client: PublicReadClient, centroids: PostalCentroidLoader): OffersRepository
```

- [ ] **Step 1: Generate public API types**

With the local stack reset:

```sh
pnpm exec supabase start
pnpm exec supabase db reset
pnpm types:db
```

Inspect the generated file and confirm it contains only `api` objects. If `ingest` or `catalog` appears, correct schema exposure and generation arguments before continuing.

- [ ] **Step 2: Write failing shipping-rule tests**

Assert:

- base price applies below the first threshold;
- the highest satisfied threshold wins;
- an explicit zero remains free shipping;
- empty, malformed, overlapping, or missing-price rules return `null`;
- cents remain integers.

- [ ] **Step 3: Write failing repository tests with a fake public client**

For shipping:

- query only `api.published_offers`;
- map every public field and use `source_checked_at`;
- apply text/form/THC filters;
- calculate standard shipping against the requested item subtotal;
- return `null` total and no ranking eligibility for missing cost;
- reject malformed public rows as a repository error rather than guessing.

For pickup:

- require a syntactically valid five-digit PLZ;
- resolve it through the local centroid loader;
- call `api.search_pickup_offers` with latitude/longitude and bounded distance, never the PLZ;
- map returned `distance_m`;
- never write the PLZ to storage or include it in a logged error.

For favorites:

- fetch only requested stable IDs;
- preserve request order and return explicit `not-found` entries;
- reject a network/API error without synthetic fallback.

- [ ] **Step 4: Implement the anonymous client**

Create the browser client with only the public URL and publishable key. Disable auth session persistence/refresh/detection because this PWA has no Supabase users. No service-role type, import, or environment variable may be referenced from `src/`.

- [ ] **Step 5: Implement the repository**

Keep query mapping in small functions with runtime validation. Set a bounded result limit of 200 for this phase. Use current domain ranking after mapping. If pickup PLZ is absent or unknown, return a typed user-correctable repository error that `SearchExperience` can present without leaking coordinates or internal responses.

- [ ] **Step 6: Verify repository and generated boundary**

Run:

```sh
pnpm vitest run src/data/supabase
pnpm test
pnpm build
rg -n "service_role|CANNAFLOW|IMPORT_CRON_SECRET" src public
git diff --check
```

Expected: tests/build pass and the browser-source secret scan returns no matches.

```sh
git add src/data/supabase src/data/offers-repository.ts src/vite-env.d.ts
git commit -m "feat: read public offers through Supabase"
```

### Task 10: Select Data Mode Explicitly and Complete the iPhone Experience

**Files:**
- Create: `src/config/runtime-config.ts`
- Create: `src/config/runtime-config.test.ts`
- Create: `src/components/DataSourceBanner.tsx`
- Create: `src/components/DataSourceBanner.test.tsx`
- Modify: `src/main.tsx`
- Modify: `src/app/App.tsx`
- Modify: `src/app/App.test.tsx`
- Modify: `src/components/SearchControls.tsx`
- Modify: `src/components/SearchExperience.tsx`
- Modify: `src/components/SearchExperience.test.tsx`
- Modify: `src/components/InfoView.tsx`
- Modify: `src/styles/app.css`
- Modify: `tests/e2e/iphone-flow.spec.ts`

**Interfaces:**

```ts
type RuntimeSelection =
  | { mode: 'synthetic'; reason: 'configured' | 'missing-live-config'; repository: OffersRepository }
  | { mode: 'supabase'; repository: OffersRepository }

function resolveRuntimeSelection(env: ImportMetaEnv): RuntimeSelection
```

- [ ] **Step 1: Write failing configuration tests**

Assert:

- absent or explicit `synthetic` mode selects synthetic data and the test banner;
- `supabase` mode without a valid HTTPS URL or publishable key fails closed to clearly labeled synthetic mode;
- valid `supabase` mode constructs only the anonymous repository;
- an API failure after valid live selection shows an error and never falls back to synthetic offers;
- secret-like service-role keys are rejected as browser configuration.

- [ ] **Step 2: Implement runtime selection and source banner**

Move repository creation from the `App` default into `main.tsx`; continue allowing test injection into `App`. The banner states exactly one of:

- “Ausschließlich synthetische Testdaten”;
- “Testdatenmodus: Live-Konfiguration fehlt”;
- “Live-Vergleich · Quelle Cannaflow · Stand …”.

The live timestamp comes from returned offer source data, not the device build time.

- [ ] **Step 3: Write failing pickup-form tests**

Assert:

- the PLZ field appears only in pickup mode;
- it uses `inputMode="numeric"`, `autoComplete="postal-code"`, pattern `[0-9]{5}`, and an accessible label;
- submit is blocked with a German validation message for missing/invalid pickup PLZ;
- switching back to shipping removes the PLZ from the submitted query;
- no exact-location permission is requested.

- [ ] **Step 4: Implement pickup controls and actionable errors**

Replace the synthetic-distance hint with a concise explanation that the PLZ is converted locally to an approximate center and not saved. Distinguish unknown PLZ from a temporary comparison-service failure. Keep the existing loading and latest-request-wins behavior.

- [ ] **Step 5: Update the information view and visual states**

Explain neutral ranking, 24-hour freshness, missing shipping totals, Cannaflow as the data source only when live, GeoNames attribution, no storage of search/health data, and no medical advice. Preserve the existing dark status-bar treatment and add accessible styles for live, test, stale, incomplete-price, and error states.

- [ ] **Step 6: Extend the iPhone WebKit journey**

Run the application against deterministic local Supabase seed data and cover:

1. adult confirmation;
2. shipping search with a fully priced ranked result;
3. an offer excluded from price ranking because shipping cost is missing;
4. pickup switch and five-digit PLZ entry;
5. distance result;
6. favorite save and revisit;
7. visible source/freshness;
8. no horizontal overflow at iPhone 14 viewport;
9. API failure state with no synthetic substitution.

Keep the existing synthetic journey as a separate deterministic test.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test
pnpm build
pnpm exec playwright install webkit
pnpm test:e2e
git diff --check
```

Expected: unit/build and both synthetic/local-Supabase iPhone flows pass.

```sh
git add src tests/e2e
git commit -m "feat: add explicit live comparison experience"
```

### Task 11: Add CI, Security Gates, and Operator Documentation

**Files:**
- Modify: `.github/workflows/verify.yml`
- Modify: `README.md`
- Modify: `docs/operations/cannaflow-activation.md`
- Modify: `docs/operations/cannaflow-import-evidence.md`

**Interfaces:**
- CI jobs: `pwa`, `edge-functions`, `database`.
- No CI secret or network dependency on Cannaflow.

- [ ] **Step 1: Split CI into deterministic jobs**

Configure:

- `pwa`: Node 24, pnpm 11.9.0, frozen install, `pnpm test`, `pnpm build`;
- `edge-functions`: Deno 2.8.1 via `denoland/setup-deno@v2`, `deno task --config supabase/deno.json test`;
- `database`: Docker-capable runner, pinned Supabase CLI from the lockfile, local stack start, reset, pgTAP, DB lint, and generated-type drift check.

Do not configure `CANNAFLOW_API_KEY`, do not allow fixtures to choose the production base URL, and do not invoke a deployed function.

- [ ] **Step 2: Add negative secret and live-network gates**

Add a repository scan that fails on tracked assignments or values for partner, cron, or service-role secrets. Add a test fetch implementation that fails any non-local network request during Edge tests. Keep package registry access limited to dependency installation.

- [ ] **Step 3: Document the complete operator workflow**

README must state:

- prerequisites including Docker and Deno;
- local start/reset/test/type-generation commands;
- the two PWA data modes and fail-closed behavior;
- why production remains synthetic until the activation gate;
- exact private/public data boundary;
- absence of accounts, prescriptions, diagnoses, payments, address storage, and search tracking;
- GeoNames CC BY 4.0 attribution and source link;
- where to record partner approval and eight-run evidence.

- [ ] **Step 4: Run local equivalents and commit**

Run:

```sh
pnpm install --frozen-lockfile
pnpm exec supabase start
pnpm exec supabase db reset
pnpm test
deno task --config supabase/deno.json test
pnpm test:db
pnpm exec supabase db lint --level error
pnpm types:db
git diff --exit-code -- src/data/supabase/database.types.ts
pnpm build
pnpm exec supabase stop
git diff --check
```

Expected: every command succeeds and generated types are committed without drift.

```sh
git add .github/workflows/verify.yml README.md docs/operations
git commit -m "ci: verify Supabase data platform"
```

### Task 12: Perform Final Security Review and Prepare the Disabled Live Gate

**Files:**
- Review: all files changed by Tasks 1–11
- Modify only if verification finds a defect: affected tests, implementation, or documentation

**Interfaces:**
- Final implementation remains `publication_enabled = false` outside local seed data.
- No deployment or production schedule is authorized by this plan alone.

- [ ] **Step 1: Run the full clean verification from a reset local stack**

Use the `superpowers:verification-before-completion` skill. Run:

```sh
pnpm install --frozen-lockfile
pnpm exec supabase start
pnpm exec supabase db reset
pnpm test
deno task --config supabase/deno.json test
pnpm test:db
pnpm exec supabase db lint --level error
pnpm types:db
git diff --exit-code -- src/data/supabase/database.types.ts
pnpm build
pnpm test:e2e
pnpm exec supabase stop
git diff --check
git status --short
```

Expected: all tests and builds pass, type generation has no drift, and only intentional uncommitted evidence changes are present.

- [ ] **Step 2: Run explicit privilege and privacy checks**

Verify with negative tests and repository search:

- `anon` cannot read/write private schemas or call publication;
- `authenticated` gains no extra access;
- public SQL lookup is invoker-rights;
- administrative publication is service-role-only with hardened `search_path`;
- no service-role/partner/cron secret appears in `dist/`, Git history, fixtures, source maps, logs, or tracked environment files;
- no PLZ/search query is persisted;
- stale source timestamps remain unchanged after failure;
- missing shipping cost never becomes zero;
- exact 24-hour records never enter ranking.

Run Supabase Security and Performance Advisors against the non-public target project before any live activation. Record every critical finding as resolved or as an explicit activation blocker.

- [ ] **Step 3: Review acceptance criteria against the approved design**

Check every item in Sections 14 and 15 of the approved design. The implementation branch may be declared code-complete with fixtures while these external activation gates remain closed:

- Cannaflow partner credential;
- written data-use approval;
- eight acceptable runs spanning at least 48 hours;
- source sample audit;
- production project advisor review;
- explicit user approval to enable public live data.

Do not fabricate evidence or mark these gates complete from local fixture tests.

- [ ] **Step 4: Commit verification fixes and hand off without deploying**

If verification required changes, rerun the affected focused test and the full suite, then:

```sh
git status --short
git add --patch
git commit -m "fix: close data platform verification gaps"
```

Review every patch selected by `git add --patch`; stage only files changed to correct a verified defect. If no fixes were required, create no empty commit. Report the exact passing checks and the still-closed external activation gates. Do not push, deploy, add production secrets, enable Cron, or switch GitHub Pages to Supabase unless the user separately authorizes those actions.

---

## Definition of Done

- The Cannaflow client is proven entirely with immutable fixtures and cannot leak its key to another origin or to logs.
- Import runs are complete, idempotent, per-pharmacy isolated, quality-gated, and atomically published.
- Price jumps greater than 30 percent and every other blocking ambiguity create review cases instead of public guesses.
- Public tables contain only approved comparison fields; `anon` has read-only access and no path to private schemas or administrative publication.
- Pickup converts PLZ locally, sends only a centroid to the invoker-rights PostGIS lookup, and stores no search input.
- Standard shipping totals are computed only from unambiguous rules; incomplete totals never enter ranking.
- Stale data at or beyond 24 hours is separated from the price ranking and labeled with the actual source timestamp.
- Synthetic and Supabase modes are explicit; a live API failure never silently substitutes test offers.
- Unit, Edge, database, build, and iPhone WebKit checks pass locally and in CI without a Cannaflow request.
- Production live publication remains disabled until the documented permission, 48-hour observation, audit, advisor, and user-approval gates are complete.

## Primary References

- Approved design: `docs/superpowers/specs/2026-07-24-cannaflow-supabase-data-platform-design.md`
- Cannaflow API overview: https://cannaflow.readme.io/reference/version
- Cannaflow products: https://cannaflow.readme.io/reference/products-list
- Cannaflow pharmacies: https://cannaflow.readme.io/reference/pharmacies-list
- Supabase RLS: https://supabase.com/docs/guides/database/postgres/row-level-security
- Supabase Edge Function tests: https://supabase.com/docs/guides/functions/unit-test
- Supabase scheduled functions: https://supabase.com/docs/guides/functions/schedule-functions
- Supabase PostGIS: https://supabase.com/docs/guides/database/extensions/postgis
- GeoNames postal-code export and license: https://download.geonames.org/export/zip/ and https://www.geonames.org/export/
