# Weedypedia Inventory Lineage and Community Values Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the personal inventory's fixed selector with explainable cultivar/product search and private free text, add editable personal origins, and let users voluntarily contribute one current label/laboratory THC/CBD pair per flower cultivar to a privacy-thresholded community average.

**Architecture:** The inventory keeps the user's entered name and private origin overrides while a server trigger derives any canonical cultivar and flower eligibility from the reviewed catalog projection. Community contributions live in a non-exposed private table and are accessible only through authenticated own-record RPCs that enforce current AAL, canonical flower mapping, value limits, declaration, and consent. Inventory and contribution writes are deliberately separate; an application service exposes the partial-success state and retries only the contribution. A database job atomically replaces an authenticated read-only aggregate every six hours and publishes only rounded means plus a coarse contributor band after five complete contributors.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Testing Library 16.3.2, Playwright 1.61.1, Supabase CLI 2.109.1, Supabase Postgres 17/Auth/pg_cron, pgTAP, `@supabase/supabase-js` 2.110.8

## Global Constraints

- Implement sections 2 through 5 and 7.1 through 7.3 of `docs/superpowers/specs/2026-07-28-inventory-lineage-community-data-design.md`.
- Require the catalog projection and `CatalogSearchMatch` contract from `docs/superpowers/plans/2026-07-28-source-adapter-foundation.md` before implementing search.
- The search in this plan exists only in the personal inventory. Do not expose community averages in global search results or overview cards.
- Preserve the user's entered inventory name. A canonical spelling is an explicit suggestion and never a silent replacement.
- Allow a private unmatched entry without creating or editing any public catalog, alias, relationship, review case, or community contribution.
- Prefilled and manually edited origins remain private inventory fields. They never alter published lineage, source assertions, or community knowledge.
- Community version 1 accepts only complete THC and CBD percentage pairs for a canonically mapped flower cultivar.
- Accept exact values from 0 through 70 inclusive, with comma or point and at most two decimals. Reject non-exact text such as `unter 1 %`, signs, exponents, more precision, and any value above 70.
- Show exactly: `Keine Fantasiewerte. Bitte AUSSCHLIESSLICH die Werte des Labels oder eines Laborberichts angeben.`
- Require both the per-contribution opt-in and the declaration that values come from a label or laboratory/analysis and are not estimated.
- Store one current row per `(user_id, cultivar_id)`. An upsert atomically replaces that row; do not create an application history table.
- Inventory rows and contribution rows remain separate. A contribution does not affect inventory quantity, catalog facts, rankings, recommendations, advertising, or therapy statements.
- Deleting the last matching inventory item, explicitly removing opt-in, or deleting the account removes the current contribution.
- Never give `anon` or `authenticated` direct privileges on raw contribution tables.
- RPCs derive the user ID from `auth.uid()`, use `SECURITY DEFINER SET search_path = ''`, validate flower eligibility server-side, and enforce `private.personal_data_access_allowed(auth.uid())`.
- Do not return another user's values, user ID, exact contributor count, per-user source kind, inventory link, or contribution timestamp through the public aggregate.
- Recompute public means at most once every six hours, round to one decimal, publish only at five complete contributors, and expose only `5+`, `10+`, `25+`, or `50+`.
- Show sourced values and community values as separate visual layers.
- Put a dominant `Ø` before a clean three-person pictogram; do not repeat `Ø` after THC or CBD.
- Keep community and sourced value rows compact so quantity remains visually close.
- Preserve iPhone safe areas, visible blended status bar, keyboard access, 44-pixel controls, reduced-motion support, and German UI copy.
- Do not add scanner, upload, OCR, barcode, photo, extract/oil community values, product-specific community averages, public submissions, rankings, comments, prices, consumption, diagnosis, prescription, or therapy data.

---

## Delivery Boundary

This package implements the full personal-inventory and community backend/UI.
It also creates a tested reusable `CultivarProfileCommunityLine` component with
the approved subtle presentation. The component is not mounted into the
currently nonexistent cultivar-profile route; that wiring belongs to the later
gesture-driven cultivar-profile plan. The global search and discover tabs
remain unchanged.

## Target File Structure

### Runtime and domain

- `.env.example`: active community-contribution consent version.
- `src/config/runtime-config.ts`: strict consent-version configuration.
- `src/config/runtime-config.test.ts`: missing-version failure.
- `src/catalog/catalog-repository.ts`: inventory-only search port.
- `src/catalog/supabase-catalog-repository.ts`: `search_catalog_references` RPC adapter.
- `src/catalog/in-memory-catalog-repository.ts`: deterministic UI-test search.
- `src/catalog/*.test.ts`: mapping, abort, and search behavior.
- `src/community/community-values.ts`: contribution/aggregate types and exact percent validation.
- `src/community/community-values.test.ts`: comma, precision, bounds, and band display.
- `src/community/community-repository.ts`: own contribution and published aggregate port.
- `src/community/supabase-community-repository.ts`: narrow RPC and aggregate adapter.
- `src/community/in-memory-community-repository.ts`: deterministic component-test adapter.
- `src/community/*.test.ts`: mapping, ownership-safe payload, and error mapping.

### Database

- `supabase/migrations/*_inventory_lineage_community_values.sql`: private origins, raw contributions, RPCs, aggregate, trigger, and schedule.
- `supabase/tests/database/06_inventory_lineage_schema.test.sql`: storage constraints and derivation.
- `supabase/tests/database/07_community_values_access.test.sql`: ownership, AAL, grants, and lifecycle.
- `supabase/tests/database/08_community_values_aggregation.test.sql`: threshold, bands, delayed publication, and removal.
- `supabase/seed.sql`: synthetic private-search and sourced-value demonstration data only.

### Inventory UI and orchestration

- `src/inventory/inventory.ts`: matched/free item and private-origin types.
- `src/inventory/inventory.test.ts`: matched/free validation and private field boundaries.
- `src/inventory/inventory-repository.ts`: inventory CRUD only.
- `src/inventory/supabase-inventory-repository.ts`: optional reference and derived canonical mapping.
- `src/inventory/in-memory-inventory-repository.ts`: matched/free deterministic behavior.
- `src/inventory/save-inventory-entry.ts`: two-stage save and targeted retry state.
- `src/inventory/save-inventory-entry.test.ts`: success, inventory failure, partial failure, retry, and opt-out.
- `src/components/inventory/CatalogCombobox.tsx`: accessible, abortable inventory search.
- `src/components/inventory/CatalogCombobox.test.tsx`: keyboard, alias reason, canonical suggestion, and free text.
- `src/components/inventory/CommunityAverageCompact.tsx`: compact inventory aggregate.
- `src/components/inventory/CommunityContributionFields.tsx`: opt-in, exact pair, source, and declaration.
- `src/components/inventory/InventoryForm.tsx`: ordered integrated form.
- `src/components/inventory/InventoryCard.tsx`: user-entered name and private origins.
- `src/components/inventory/InventoryView.tsx`: loading, save feedback, and retry.
- `src/components/inventory/InventoryView.test.tsx`: full personal flow.
- `src/components/cultivar/CultivarProfileCommunityLine.tsx`: subtle profile line for later profile wiring.
- `src/components/cultivar/CultivarProfileCommunityLine.test.tsx`: available and below-threshold states.
- `src/styles/app.css`: compact value rows, combobox, retry state, and touch behavior.

### Composition, privacy, and verification

- `src/app/App.tsx`: inject catalog and community repositories plus consent version.
- `src/app/App.test.tsx`: dependency completeness and unchanged global tabs.
- `src/auth/auth-service.ts`: include own contributions in account export.
- `src/auth/supabase-auth-service.ts`: call the own-export RPC after fresh proof.
- `src/auth/supabase-auth-service.test.ts`: export mapping without foreign/raw aggregate data.
- `tests/e2e/weedypedia-account-inventory.spec.ts`: iPhone matched/free/origin/contribution journey.
- `docs/operations/weedypedia-account-activation.md`: contribution consent, export, deletion, schedule, and rollback.
- `README.md`: local migration and validation workflow.

---

### Task 1: Add Exact Community Domain Rules

**Files:**
- Create: `src/community/community-values.ts`
- Create: `src/community/community-values.test.ts`
- Modify: `src/config/runtime-config.ts`
- Modify: `src/config/runtime-config.test.ts`
- Modify: `.env.example`

**Interfaces:**

```ts
export type CommunityValueSource = 'label' | 'laboratory'
export type ContributorBand = '5+' | '10+' | '25+' | '50+'

export type CommunityContributionDraft = {
  enabled: boolean
  thcPercent: string
  cbdPercent: string
  sourceKind: CommunityValueSource | ''
  declarationAccepted: boolean
}

export type ValidCommunityContribution = {
  cultivarId: string
  thcPercent: number
  cbdPercent: number
  sourceKind: CommunityValueSource
  consentVersion: string
  declarationAccepted: true
  optIn: true
}

export type OwnCommunityContribution = {
  cultivarId: string
  thcPercent: number
  cbdPercent: number
  sourceKind: CommunityValueSource
  consentVersion: string
  updatedAt: string
}

export type PublishedCommunityAverage = {
  cultivarId: string
  thcMean: number
  cbdMean: number
  contributorBand: ContributorBand
  computedAt: string
}
```

- [ ] **Step 1: Write failing exact-percent tests**

Test:

```ts
expect(parseFlowerPercent('0')).toBe(0)
expect(parseFlowerPercent('0,75')).toBe(0.75)
expect(parseFlowerPercent('21.30')).toBe(21.3)
expect(parseFlowerPercent('70,00')).toBe(70)
```

Reject:

```text
-0.1
+1
1e1
70.01
71
1.234
unter 1 %
1 %
NaN
Infinity
empty input
```

`validateCommunityContribution` must require:

- a valid UUID cultivar ID;
- both exact values;
- `label` or `laboratory`;
- `declarationAccepted === true`;
- `enabled === true`;
- a non-empty consent version.

The over-limit validation error uses the exact “Keine Fantasiewerte …” copy.

- [ ] **Step 2: Write failing aggregate-mapping tests**

Prove:

- database numeric strings map to finite one-decimal numbers;
- only the four contributor bands are accepted;
- `computedAt` must be an ISO timestamp;
- no type includes exact count, user ID, source kind, or inventory ID;
- German display uses comma decimals without adding another `Ø` after THC/CBD.

- [ ] **Step 3: Run and verify failure**

Run:

```sh
pnpm test -- src/community/community-values.test.ts \
  src/config/runtime-config.test.ts
```

Expected: FAIL because the community module and runtime field do not exist.

- [ ] **Step 4: Implement parsing without floating input shortcuts**

Validate trimmed input first with an anchored decimal regex that accepts only
digits and one comma or point with one or two decimals. Replace comma with
point only after the regex passes, then check `0 <= value <= 70`.

Export:

```ts
export const unrealisticFlowerValueMessage =
  'Keine Fantasiewerte. Bitte AUSSCHLIESSLICH die Werte des Labels oder eines Laborberichts angeben.'

export function parseFlowerPercent(input: string): number
export function communityContributionErrors(
  draft: CommunityContributionDraft,
): Partial<Record<keyof CommunityContributionDraft, string>>
export function validateCommunityContribution(input: {
  cultivarId: string
  consentVersion: string
  draft: CommunityContributionDraft
}): ValidCommunityContribution
```

- [ ] **Step 5: Add the active consent version to runtime config**

Add:

```dotenv
VITE_COMMUNITY_VALUES_CONSENT_VERSION=weedypedia-community-values-2026-07-28
```

Map it to `RuntimeConfig.communityValuesConsentVersion` and fail closed when
missing. This is a public wording version, not a secret.

- [ ] **Step 6: Verify and commit**

Run:

```sh
pnpm test -- src/community/community-values.test.ts \
  src/config/runtime-config.test.ts
pnpm build
git diff --check
```

Expected: focused tests and build PASS.

```sh
git add src/community/community-values.ts \
  src/community/community-values.test.ts \
  src/config/runtime-config.ts src/config/runtime-config.test.ts .env.example
git commit -m "feat: validate community flower values"
```

---

### Task 2: Extend Inventory for Search Matches and Private Origins

**Files:**
- Modify: `src/inventory/inventory.ts`
- Modify: `src/inventory/inventory.test.ts`
- Modify: `src/inventory/inventory-repository.ts`
- Modify: `src/inventory/in-memory-inventory-repository.ts`
- Modify: `src/inventory/supabase-inventory-repository.ts`
- Modify: `src/inventory/supabase-inventory-repository.test.ts`

**Inventory interfaces:**

```ts
export type InventoryReference = {
  id: string
  kind: 'cultivar' | 'product'
  canonicalName: string
}

export type InventoryItem = {
  id: string
  entryName: string
  reference: InventoryReference | null
  canonicalCultivarId: string | null
  isFlower: boolean
  originOneName: string | null
  originTwoName: string | null
  quantity: number
  unit: InventoryUnit
  batch: string | null
  expiresOn: string | null
  storageLocation: string | null
  note: string | null
  createdAt: string
  updatedAt: string
}

export type InventoryDraft = {
  entryName: string
  entityId: string | null
  originOneName: string
  originTwoName: string
  quantity: string
  unit: InventoryUnit
  batch: string
  expiresOn: string
  storageLocation: string
  note: string
}
```

`ValidInventoryDraft` trims and bounds text, parses quantity, and retains
`entityId: string | null`.

- [ ] **Step 1: Replace old validation tests with matched/free cases**

Prove:

- a known entry accepts a UUID plus the user's alias spelling;
- an unmatched entry accepts `entityId: null`;
- both require a 1–160 character `entryName`;
- origins are optional, trimmed, and limited to 160 characters each;
- invalid non-null UUIDs are rejected;
- free text does not acquire a canonical cultivar or flower flag in memory;
- existing quantity, unit, date, batch, storage, and note constraints remain.

- [ ] **Step 2: Run the tests and verify failure**

Run:

```sh
pnpm test -- src/inventory/inventory.test.ts \
  src/inventory/supabase-inventory-repository.test.ts
```

Expected: FAIL against the selector-only model.

- [ ] **Step 3: Implement optional-reference inventory mapping**

The Supabase adapter writes only:

```ts
{
  entity_id: input.entityId,
  entry_name: input.entryName,
  origin_one_name: input.originOneName,
  origin_two_name: input.originTwoName,
  quantity: input.quantity,
  unit: input.unit,
  batch: input.batch,
  expires_on: input.expiresOn,
  storage_location: input.storageLocation,
  note: input.note,
}
```

It never sends `user_id`, `canonical_cultivar_id`, or `is_flower`.

Change the joined select from an inner reference to an optional relation and
map the server-derived canonical fields from the inventory row. Display
`entryName`; keep `reference.canonicalName` only as a matched-catalog hint.

- [ ] **Step 4: Remove reference listing from InventoryRepository**

The repository becomes:

```ts
export type InventoryRepository = {
  list(signal?: AbortSignal): Promise<InventoryItem[]>
  create(input: ValidInventoryDraft): Promise<InventoryItem>
  update(id: string, input: ValidInventoryDraft): Promise<InventoryItem>
  remove(id: string): Promise<void>
}
```

Search belongs to `CatalogRepository`, not inventory CRUD.

- [ ] **Step 5: Verify and commit**

Run:

```sh
pnpm test -- src/inventory
pnpm build
git diff --check
```

Expected: inventory domain and adapter tests PASS.

```sh
git add src/inventory
git commit -m "refactor: support private inventory names"
```

---

### Task 3: Store Derived Canonical Mapping and Private Origins

**Files:**
- Create via CLI: `supabase/migrations/*_inventory_lineage_community_values.sql`
- Create: `supabase/tests/database/06_inventory_lineage_schema.test.sql`
- Modify: `supabase/seed.sql`

- [ ] **Step 1: Create the migration filename**

Run:

```sh
pnpm exec supabase migration new inventory_lineage_community_values
```

Use the generated timestamped filename unchanged.

- [ ] **Step 2: Write failing inventory schema tests**

Prove:

- `api.inventory_items.entity_id` is nullable;
- `entry_name` is required and limited to 160 characters;
- both private origin fields are nullable and limited to 160;
- existing matched rows are backfilled from their canonical reference before
  new constraints apply;
- a matched alias spelling remains in `entry_name`;
- a free row stores null reference/canonical mapping and cannot become flower
  eligible;
- a known cultivar derives itself as `canonical_cultivar_id`;
- a mapped flower product derives its canonical cultivar and `is_flower=true`;
- a non-flower product derives `is_flower=false`;
- clients cannot insert or update `canonical_cultivar_id`, `is_flower`, or
  `user_id`;
- changing `entry_name` or origins never alters `api.catalog_references`;
- existing RLS and AAL restrictions still protect the row.

- [ ] **Step 3: Run and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the inventory columns and trigger do not exist.

- [ ] **Step 4: Migrate existing inventory without data loss**

Add nullable columns, backfill from `api.catalog_references`, make
`entry_name` non-null, and only then drop the old `entity_id NOT NULL`
constraint.

Add:

```sql
canonical_cultivar_id uuid
  references catalog.entities(id) on delete restrict,
is_flower boolean not null default false
```

Do not grant browser write privileges for these derived columns.

- [ ] **Step 5: Derive canonical fields server-side**

Create a `BEFORE INSERT OR UPDATE OF entity_id` trigger:

- when `entity_id is null`, set canonical cultivar null and flower false;
- otherwise read only the reviewed `api.catalog_references` row;
- reject an unpublished/missing reference;
- assign its `canonical_cultivar_id` and `is_flower`;
- never change `entry_name`, origin fields, quantity, or notes.

Keep `user_id` server-derived and immutable.

- [ ] **Step 6: Update column grants**

Authenticated users may write only:

```text
entity_id
entry_name
origin_one_name
origin_two_name
quantity
unit
batch
expires_on
storage_location
note
```

Revoke all first, then re-grant the exact select/insert/update/delete
privileges required by existing RLS.

- [ ] **Step 7: Verify and commit the inventory half of the migration**

Run:

```sh
pnpm test:db
git diff --check
```

Expected: inventory schema and prior account/access tests PASS.

```sh
git add supabase/migrations supabase/tests/database/06_inventory_lineage_schema.test.sql \
  supabase/seed.sql
git commit -m "feat: store private inventory lineage"
```

---

### Task 4: Add Private Contribution RPCs and Lifecycle Deletion

**Files:**
- Modify: the Task 3 migration before it has shipped; otherwise create via CLI: `supabase/migrations/*_community_flower_contributions.sql`
- Create: `supabase/tests/database/07_community_values_access.test.sql`

**Private table:**

```sql
private.community_flower_contributions (
  user_id uuid,
  cultivar_id uuid,
  thc_percent numeric(4,2),
  cbd_percent numeric(4,2),
  source_kind text,
  consent_version text,
  created_at timestamptz,
  updated_at timestamptz,
  primary key (user_id, cultivar_id)
)
```

**Authenticated RPCs:**

```sql
api.get_my_community_flower_contribution(p_cultivar_id uuid)
api.upsert_my_community_flower_contribution(
  p_cultivar_id uuid,
  p_thc_percent numeric,
  p_cbd_percent numeric,
  p_source_kind text,
  p_consent_version text,
  p_declaration_confirmed boolean,
  p_opt_in boolean
)
api.delete_my_community_flower_contribution(p_cultivar_id uuid)
api.export_my_community_flower_contributions()
```

- [ ] **Step 1: Write failing access and lifecycle tests**

Create two confirmed accounts and synthetic published cultivar/product rows.
Prove:

- direct raw-table access fails for `PUBLIC`, `anon`, and `authenticated`;
- own get returns no `user_id`;
- user B cannot read, replace, or delete user A's row by passing any parameter;
- AAL1 cannot use own RPCs after a verified TOTP factor; AAL2 can;
- cultivar IDs must be published, canonical cultivars;
- the user must own at least one inventory row server-derived as that cultivar
  and flower;
- free entries and non-flower products are ineligible;
- both values, allowed source kind, current consent version, declaration, and
  opt-in are required;
- 0 and 70 pass; values below 0 or above 70 fail server-side;
- a second upsert keeps one row, preserves `created_at`, and changes values and
  `updated_at`;
- two inventory rows of one cultivar still yield one contribution;
- explicit delete removes the row;
- deleting a non-last inventory row keeps it;
- deleting or remapping the last matching row removes it;
- deleting the Auth account cascades it;
- export returns only the caller's current values and canonical names.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the private table and RPCs do not exist.

- [ ] **Step 3: Add the active contribution wording**

Extend the existing legal-kind check to include `community_values`, then seed:

```sql
(
  'community_values',
  'weedypedia-community-values-2026-07-28',
  true,
  '2026-07-28T00:00:00Z'
)
```

The registration trigger continues to create only privacy, terms, and adult
receipts. Contribution consent is stored on the contribution itself.

- [ ] **Step 4: Create the raw table with no browser grants**

Use foreign-key cascade to `auth.users` and restrict the cultivar foreign key.
Check both percentages from 0 through 70 and source kind in
`('label', 'laboratory')`. Add an index on `cultivar_id` for aggregation.

After all schema statements:

```sql
revoke all on private.community_flower_contributions
  from public, anon, authenticated;
```

- [ ] **Step 5: Implement own-record functions**

Each function:

- derives `auth.uid()` and rejects null;
- calls `private.personal_data_access_allowed(auth.uid())`;
- has `SECURITY DEFINER SET search_path = ''`;
- uses fully qualified names;
- validates the active `community_values` consent version;
- returns no foreign row, user ID, or exact global count.

The upsert additionally verifies an eligible current inventory row before
using
`INSERT INTO private.community_flower_contributions
(user_id, cultivar_id, thc_percent, cbd_percent, source_kind, consent_version)
VALUES (auth.uid(), p_cultivar_id, p_thc_percent, p_cbd_percent,
p_source_kind, p_consent_version)
ON CONFLICT (user_id, cultivar_id) DO UPDATE SET
thc_percent = excluded.thc_percent,
cbd_percent = excluded.cbd_percent,
source_kind = excluded.source_kind,
consent_version = excluded.consent_version,
updated_at = now()`.

Revoke function rights from all roles, then grant only the three form RPCs and
the export RPC to `authenticated`.

- [ ] **Step 6: Delete orphaned contribution state server-side**

Add an `AFTER DELETE OR UPDATE OF canonical_cultivar_id, is_flower` trigger on
inventory. For the old canonical cultivar, delete the user's contribution only
when no other current flower inventory row remains. This protects lifecycle
semantics even if the PWA closes between inventory deletion and UI cleanup.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test:db
git diff --check
```

Expected: all account, inventory, contribution, ownership, AAL, and cascade
tests PASS.

```sh
git add supabase/migrations supabase/tests/database/07_community_values_access.test.sql \
  supabase/seed.sql
git commit -m "feat: protect community flower contributions"
```

---

### Task 5: Publish Six-Hour Privacy-Thresholded Aggregates

**Files:**
- Modify: the current community migration before shipping; otherwise create via CLI: `supabase/migrations/*_community_flower_averages.sql`
- Create: `supabase/tests/database/08_community_values_aggregation.test.sql`

**Public read model:**

```sql
api.community_flower_averages (
  cultivar_id uuid primary key,
  thc_mean numeric(4,1) not null,
  cbd_mean numeric(4,1) not null,
  contributor_band text not null,
  computed_at timestamptz not null
)
```

The table intentionally has no exact count column.

- [ ] **Step 1: Write failing aggregation tests**

With synthetic users, prove:

- 0 through 4 complete contributors publish no row;
- the fifth publishes rounded arithmetic THC/CBD means and `5+`;
- 10, 25, and 50 contributors switch to `10+`, `25+`, and `50+`;
- 9, 24, and 49 remain in the previous band;
- multiple inventory rows never duplicate one account's contribution;
- changing a raw contribution does not change the public row until refresh;
- refresh replaces the public value;
- falling below five removes the public row on refresh;
- source-kind proportions and exact counts are absent from the table;
- authenticated users can select aggregates, anonymous users cannot;
- no browser role can insert, update, delete, or execute refresh;
- a deliberately failed refresh leaves the prior committed aggregate visible.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the aggregate table and refresh do not exist.

- [ ] **Step 3: Create the read model and restricted refresh**

Create:

```sql
private.refresh_community_flower_averages()
```

The function:

1. reads only current private contribution rows;
2. groups by canonical cultivar;
3. requires `count(*) >= 5`;
4. rounds `avg(thc_percent)` and `avg(cbd_percent)` to one decimal;
5. converts the count to a band only inside the query;
6. builds a validated replacement set;
7. replaces `api.community_flower_averages` within the function transaction;
8. uses one `computed_at` timestamp for the run.

Do not persist the exact grouped count in any public or logging table.

- [ ] **Step 4: Apply read-only grants**

Enable RLS, add an authenticated select policy, and grant only `SELECT` to
`authenticated`. Revoke all refresh execution from browser roles.

- [ ] **Step 5: Schedule every six hours**

Enable `pg_cron` in the supported schema and create one named job:

```sql
select cron.schedule(
  'weedypedia-community-flower-averages-six-hourly',
  '17 */6 * * *',
  $$select private.refresh_community_flower_averages()$$
);
```

The migration must unschedule an existing job with that exact name before
recreating it, so reset/reapply behavior is deterministic. The refresh remains
manually callable only by the database owner for incident recovery.

- [ ] **Step 6: Verify and commit**

Run:

```sh
pnpm test:db
git diff --check
```

Expected: all threshold, band, delayed-refresh, grant, and prior tests PASS.

```sh
git add supabase/migrations supabase/tests/database/08_community_values_aggregation.test.sql
git commit -m "feat: publish private community averages"
```

---

### Task 6: Implement Catalog Search and Community Repositories

**Files:**
- Create: `src/catalog/catalog-repository.ts`
- Create: `src/catalog/supabase-catalog-repository.ts`
- Create: `src/catalog/supabase-catalog-repository.test.ts`
- Create: `src/catalog/in-memory-catalog-repository.ts`
- Create: `src/community/community-repository.ts`
- Create: `src/community/supabase-community-repository.ts`
- Create: `src/community/supabase-community-repository.test.ts`
- Create: `src/community/in-memory-community-repository.ts`

**Repository ports:**

```ts
export type CatalogRepository = {
  search(query: string, signal?: AbortSignal): Promise<CatalogSearchMatch[]>
}

export type CommunityRepository = {
  getOwn(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<OwnCommunityContribution | null>
  getPublished(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<PublishedCommunityAverage | null>
  upsert(input: ValidCommunityContribution): Promise<OwnCommunityContribution>
  remove(cultivarId: string): Promise<void>
}
```

- [ ] **Step 1: Write failing adapter tests**

Catalog tests prove:

- trimmed queries call `search_catalog_references` with `p_query`;
- queries shorter than two visible characters return `[]` without RPC;
- only the approved fields map to `CatalogSearchMatch`;
- the user's query is never replaced by a canonical spelling in the adapter;
- abort is checked before and after RPC;
- malformed rows fail closed.

Community tests prove:

- `getOwn` invokes only `get_my_community_flower_contribution`;
- upsert sends no user ID, inventory ID, exact contributor count, or arbitrary
  consent flag;
- the declaration and opt-in booleans are always true after domain validation;
- remove invokes only the own-delete RPC;
- published select requests only
  `cultivar_id,thc_mean,cbd_mean,contributor_band,computed_at`;
- zero rows map to null;
- permission errors have a stable German message distinct from availability
  errors.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test -- src/catalog src/community
```

Expected: FAIL because repository modules do not exist.

- [ ] **Step 3: Implement minimal Supabase ports**

Extend the local test query port only with the actual operations used:
`rpc`, `select`, `eq`, `maybeSingle`, and `abortSignal`. Do not cast the full
Supabase client throughout UI code.

- [ ] **Step 4: Implement deterministic in-memory adapters**

The catalog adapter matches synthetic canonical, alias, and product terms and
returns explicit reasons. The community adapter stores at most one own row per
cultivar and keeps published aggregates separate; an upsert does not mutate an
aggregate until a test explicitly seeds a refreshed aggregate.

- [ ] **Step 5: Verify and commit**

Run:

```sh
pnpm test -- src/catalog src/community
pnpm build
git diff --check
```

Expected: repository and domain tests PASS.

```sh
git add src/catalog src/community
git commit -m "feat: add inventory search and community adapters"
```

---

### Task 7: Build the Accessible Inventory Search and Origin Prefill

**Files:**
- Create: `src/components/inventory/CatalogCombobox.tsx`
- Create: `src/components/inventory/CatalogCombobox.test.tsx`
- Modify: `src/components/inventory/InventoryForm.tsx`
- Modify: `src/components/inventory/InventoryView.test.tsx`
- Modify: `src/styles/app.css`

- [ ] **Step 1: Write failing combobox tests**

Prove:

- the control is a labelled editable textbox, not a `<select>`;
- two typed characters trigger a 200 ms debounced search;
- a later query aborts the prior request;
- canonical, alias, and product results state their reason;
- `ArrowDown`, `ArrowUp`, `Enter`, and `Escape` work;
- touch/click selection works;
- choosing alias `Synthetic Alias` keeps that text in the textbox and displays
  `Kanonischer Vorschlag: Synthetic Cultivar`;
- continuing to edit after selection clears the stale reference;
- an unmatched entered name remains valid private text;
- loading, empty, and failed search states use status/alert semantics;
- results contain no community average.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test -- src/components/inventory/CatalogCombobox.test.tsx
```

Expected: FAIL because the combobox does not exist.

- [ ] **Step 3: Implement an ARIA combobox**

Use textbox `role="combobox"`, `aria-expanded`, `aria-controls`, and
`aria-activedescendant`; render results as one `role="listbox"` with
`role="option"` children. Preserve the typed string separately from the
selected `CatalogSearchMatch`.

Do not fetch on initial empty render. Abort pending work on unmount.

- [ ] **Step 4: Replace the form selector**

`InventoryForm` receives:

```ts
catalogRepository: CatalogRepository
communityRepository: CommunityRepository
communityConsentVersion: string
```

On a known selection:

- preserve the typed `entryName`;
- set `entityId`;
- prefill `originOneName` and `originTwoName` from preferred parents;
- show “Weitere belegte Herkunftsangaben im Sortenprofil” when flagged;
- retain both origins as editable private values.

For a free entry, set `entityId = null`, start origins empty, and show:
`Nur privat gespeichert · keine Weedypedia-Zuordnung`.

Once the name is non-empty, origin fields appear as a compact two-column row
before quantity. Neither is required.

- [ ] **Step 5: Style for iPhone and reduced motion**

Keep the list within the viewport, allow vertical page scroll, maintain
44-pixel result targets, and avoid hover-only information. No search animation
is required; respect existing `prefers-reduced-motion`.

- [ ] **Step 6: Verify and commit**

Run:

```sh
pnpm test -- src/components/inventory
pnpm build
git diff --check
```

Expected: combobox, form, accessibility, and build checks PASS.

```sh
git add src/components/inventory src/styles/app.css
git commit -m "feat: search personal inventory catalog"
```

---

### Task 8: Orchestrate Inventory and Contribution Saves

**Files:**
- Create: `src/inventory/save-inventory-entry.ts`
- Create: `src/inventory/save-inventory-entry.test.ts`
- Create: `src/components/inventory/CommunityContributionFields.tsx`
- Modify: `src/components/inventory/InventoryForm.tsx`
- Modify: `src/components/inventory/InventoryView.tsx`
- Modify: `src/components/inventory/InventoryView.test.tsx`

**Application result:**

```ts
export type PendingCommunityMutation =
  | { kind: 'upsert'; input: ValidCommunityContribution }
  | { kind: 'remove'; cultivarId: string }

export type SaveInventoryOutcome =
  | {
      kind: 'saved'
      item: InventoryItem
      community: 'unchanged' | 'saved' | 'removed'
    }
  | {
      kind: 'inventory_saved_community_failed'
      item: InventoryItem
      pendingCommunityMutation: PendingCommunityMutation
    }
```

- [ ] **Step 1: Write failing orchestration tests**

Prove:

- inventory failure prevents any community mutation;
- a free or non-flower entry never calls community RPCs;
- eligible opt-in saves inventory first, then upserts one contribution;
- a successful upsert returns `saved`;
- explicit removal saves inventory first, then removes the contribution;
- community failure returns the saved inventory and a targeted pending
  mutation;
- retrying executes only that community mutation and never calls inventory
  create/update again;
- editing and switching cultivar cannot duplicate the old contribution;
- no catch block silently converts failure to success.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test -- src/inventory/save-inventory-entry.test.ts
```

Expected: FAIL because orchestration does not exist.

- [ ] **Step 3: Implement the two-stage application service**

Export separate `saveInventoryEntry(input, dependencies)` and
`retryCommunityMutation(mutation, communityRepository)` functions. Keep React
state and copy outside the service. A repository error from inventory is
thrown. Only a contribution error becomes the explicit partial-success
outcome.

- [ ] **Step 4: Build voluntary contribution fields**

Show the section only when the selected catalog match has:

```ts
canonicalCultivarId !== null && isFlower === true
```

Order at the bottom of the form:

1. voluntary opt-in;
2. THC and CBD compact row;
3. source kind: `Etikett` or `Labor/Analyse`;
4. mandatory declaration checkbox;
5. the exact “Keine Fantasiewerte …” hint.

Do not render camera, upload, scanner, barcode, `unter 1 %`, mg units, prices,
effects, or dosage.

- [ ] **Step 5: Implement success and partial failure feedback**

On success announce:

`Gespeichert. Der Community-Mittelwert wird später aktualisiert.`

On partial failure keep the saved inventory visible, keep the form from
creating another item, and announce:

`Der Bestand wurde gespeichert. Der Community-Beitrag konnte nicht übernommen werden.`

Render `Community-Beitrag erneut versuchen`; it calls only
`retryCommunityMutation`. On retry success, replace the alert with the success
status.

For a plain inventory save without community mutation, retain the existing
normal save behavior without claiming a community update.

- [ ] **Step 6: Verify and commit**

Run:

```sh
pnpm test -- src/inventory/save-inventory-entry.test.ts \
  src/components/inventory/InventoryView.test.tsx
pnpm build
git diff --check
```

Expected: orchestration and UI tests PASS.

```sh
git add src/inventory/save-inventory-entry.ts \
  src/inventory/save-inventory-entry.test.ts \
  src/components/inventory
git commit -m "feat: save voluntary community values"
```

---

### Task 9: Render Compact Sourced and Community Value Layers

**Files:**
- Create: `src/components/inventory/CommunityAverageCompact.tsx`
- Create: `src/components/inventory/CommunityAverageCompact.test.tsx`
- Create: `src/components/cultivar/CultivarProfileCommunityLine.tsx`
- Create: `src/components/cultivar/CultivarProfileCommunityLine.test.tsx`
- Modify: `src/components/inventory/InventoryForm.tsx`
- Modify: `src/components/inventory/InventoryCard.tsx`
- Modify: `src/styles/app.css`

- [ ] **Step 1: Write failing presentation tests**

Inventory compact row:

- renders sourced THC/CBD first when present;
- renders a compact `Belege` disclosure whose entries show source name,
  version when present, retrieval date, attribution, and safe citation link;
- renders the community layer separately;
- places `Ø` before a three-person SVG pictogram;
- exposes pictogram meaning as one accessible `Community` label without
  announcing three decorative people;
- renders `THC 21,3 %`, `CBD 0,7 %`, and `25+`;
- contains no `THC Ø` or `CBD Ø`;
- below threshold renders `Noch nicht genügend Community-Werte.`;
- renders no exact count.

Profile line:

- renders `Ø`, Community label, THC, CBD, and contributor band in one subtle
  line;
- renders the same below-threshold copy when no aggregate is available;
- accepts no raw contribution type.

- [ ] **Step 2: Run and verify failure**

Run:

```sh
pnpm test -- src/components/inventory/CommunityAverageCompact.test.tsx \
  src/components/cultivar/CultivarProfileCommunityLine.test.tsx
```

Expected: FAIL because the components do not exist.

- [ ] **Step 3: Implement the clean three-person pictogram**

Use an inline SVG with three simple head/body shapes. Keep the SVG
`aria-hidden="true"` and pair it with one visually available label
`Community-Mittelwert`. Do not use an external icon library or image asset.

- [ ] **Step 4: Load values only after a known selection**

When `canonicalCultivarId` changes:

- abort the prior request;
- load own contribution and published aggregate in parallel;
- populate the voluntary section with only the caller's own row;
- render sourced labels from `CatalogSearchMatch`;
- render sourced evidence from
  `CatalogSearchMatch.sourcedValueEvidence` in a native compact
  `<details>` disclosure;
- render published aggregate or the below-threshold copy;
- never merge sourced and community values.

Search results themselves remain free of aggregate calls.

- [ ] **Step 5: Apply compact visual hierarchy**

Use small labels, a flat two-value row, limited vertical padding, and a
dominant but not heading-sized `Ø`. Keep the quantity row immediately after
these read-only layers. Preserve color contrast and avoid color as the only
distinction.

- [ ] **Step 6: Update inventory cards**

Cards display:

- the user's `entryName` as heading;
- a subtle canonical hint only when it differs;
- private origins only when present;
- quantity in the existing prominent position.

Do not add community averages to list cards; they belong to the form and later
cultivar profile only.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test -- src/components/inventory src/components/cultivar
pnpm build
git diff --check
```

Expected: compact presentation, accessibility, and build checks PASS.

```sh
git add src/components/inventory src/components/cultivar src/styles/app.css
git commit -m "feat: present compact community averages"
```

---

### Task 10: Compose Dependencies and Extend Account Export

**Files:**
- Modify: `src/app/App.tsx`
- Modify: `src/app/App.test.tsx`
- Modify: `src/auth/auth-service.ts`
- Modify: `src/auth/supabase-auth-service.ts`
- Modify: `src/auth/supabase-auth-service.test.ts`

- [ ] **Step 1: Write failing composition tests**

Prove:

- browser dependencies build catalog, inventory, and community repositories
  from the same `api`-schema Supabase client;
- tests must inject all repositories together or receive the existing explicit
  dependency error;
- `communityValuesConsentVersion` reaches `InventoryView`;
- discover/search/profile behavior remains unchanged;
- community values are never requested before authentication.

- [ ] **Step 2: Write failing export tests**

After the existing fresh password/TOTP proof, export must include:

```ts
communityFlowerContributions: Array<{
  cultivarId: string
  cultivarName: string
  thcPercent: number
  cbdPercent: number
  sourceKind: CommunityValueSource
  consentVersion: string
  createdAt: string
  updatedAt: string
}>
```

Prove the export contains only the caller's values and does not contain public
aggregate counts, other accounts, internal review data, or service secrets.

- [ ] **Step 3: Run and verify failure**

Run:

```sh
pnpm test -- src/app/App.test.tsx src/auth/supabase-auth-service.test.ts
```

Expected: FAIL because dependencies and export are incomplete.

- [ ] **Step 4: Compose repositories**

Create each browser adapter once in `createBrowserDependencies`. Pass catalog,
inventory, community, and consent version through `WeedypediaShell` only to
the inventory view.

- [ ] **Step 5: Extend own-data export**

Call only `export_my_community_flower_contributions` after the existing proof
client has satisfied fresh authentication and AAL requirements. Map the result
to the user's downloaded export. Do not query the private table.

Account deletion needs no new browser call: the Auth-user foreign-key cascade
is the server-side source of truth.

- [ ] **Step 6: Verify and commit**

Run:

```sh
pnpm test -- src/app/App.test.tsx src/auth
pnpm build
git diff --check
```

Expected: composition, export, prior Auth, and build tests PASS.

```sh
git add src/app src/auth
git commit -m "feat: include community values in private account"
```

---

### Task 11: Verify the Full iPhone and Privacy Journey

**Files:**
- Modify: `tests/e2e/weedypedia-account-inventory.spec.ts`
- Modify: `docs/operations/weedypedia-account-activation.md`
- Modify: `README.md`
- Modify: `.github/workflows/verify.yml` only if current workflow omits an existing required command.

- [ ] **Step 1: Extend the iPhone E2E journey**

Using only synthetic catalog data, prove:

1. alias search explains and selects a canonical cultivar while preserving the
   entered alias;
2. both origin fields prefill and remain manually editable after reload;
3. a free unmatched entry saves and offers no community section;
4. a mapped flower product offers community input for its canonical cultivar;
5. `70,00` is accepted and `70,01` shows the exact unrealistic-value copy;
6. missing opt-in, source, or declaration stores inventory but no contribution;
7. a valid contribution shows saved feedback;
8. a second value replaces the first current value;
9. a simulated community RPC failure shows partial success and retry creates no
   duplicate inventory row;
10. deleting a non-last matching inventory row keeps the contribution;
11. deleting the last matching row removes it;
12. an AAL1 session after TOTP enrollment cannot use the RPC until the existing
    AAL2 challenge completes;
13. account export contains the current contribution;
14. account deletion removes inventory and contribution.

Use pgTAP, not browser-created real accounts, for the 5/10/25/50 aggregate
population tests.

- [ ] **Step 2: Update the operational runbook**

Document:

- approved community wording version;
- production legal/privacy review requirement;
- six-hour cron job name and last-run inspection;
- manual database-owner refresh;
- rollback by unscheduling refresh and revoking aggregate read while leaving
  private user controls available;
- export and deletion behavior;
- backup retention wording;
- incident rule: never log raw values or exact contributor counts;
- scanner remains backlog only.

- [ ] **Step 3: Run the complete verification suite**

Run:

```sh
pnpm test:functions
pnpm test:db
pnpm test
pnpm build
pnpm test:e2e
git diff --check
git status --short
```

Expected:

- function, database, unit, build, and iPhone E2E checks PASS;
- four contributors publish nothing and five publish only `5+`;
- raw contribution tables remain inaccessible to browser roles;
- no exact count or foreign contribution appears in browser responses;
- no real source, scanner, image, price, prescription, consumption, or therapy
  feature is introduced;
- only intended files are modified.

- [ ] **Step 4: Commit verification and operations**

```sh
git add tests/e2e/weedypedia-account-inventory.spec.ts \
  docs/operations/weedypedia-account-activation.md README.md \
  .github/workflows/verify.yml
git commit -m "test: verify private community values"
```

---

## Package Acceptance

Do not call this package complete until independent review confirms:

- typed search explains canonical, alias, and flower-product matches while
  preserving user input;
- unmatched names and edited origins remain private;
- no private input can mutate public Weedypedia knowledge;
- only complete exact flower THC/CBD pairs from label or laboratory are
  accepted;
- both browser and server reject values above 70;
- one account has one current contribution per cultivar regardless of
  inventory-row count;
- explicit opt-out, last-inventory deletion, and account deletion remove it;
- foreign raw values remain inaccessible under REST, RPC, RLS, and AAL tests;
- contribution save failure cannot duplicate the already saved inventory item;
- aggregation is delayed, thresholded at five, one-decimal, banded, and free of
  exact counts;
- sourced and community values remain technically and visually separate;
- the compact `Ø` plus three-person presentation meets the approved hierarchy;
- the later cultivar-profile plan can mount
  `CultivarProfileCommunityLine` without changing the aggregate contract.
