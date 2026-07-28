# Weedypedia Source Adapter Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an immutable, review-gated source-ingestion foundation that can accept synthetic adapter output now and later connect individually approved external sources without coupling source-specific fields to Weedypedia UI or public catalog tables.

**Architecture:** A shared Deno contract normalizes every adapter result into versioned records and typed assertions. A least-privileged `source_ingestor` database capability stores import runs, immutable source records, assertions, and review cases idempotently inside the non-exposed `catalog` schema. It cannot review or publish. A separate `source_reviewer` capability is required before an atomic publisher updates the authenticated read models and catalog-search RPC. The import function receives neither the Supabase service-role key nor the reviewer capability. This plan deliberately activates no live external source.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Supabase CLI 2.109.1, Supabase Postgres 17, Supavisor transaction pooler, pgTAP, Supabase Edge Functions, Deno 2.8.1, `@supabase/supabase-js` 2.110.8, `postgres` 3.4.9 for the narrow direct-database function connection

## Global Constraints

- Implement sections 6 and 7.4 of `docs/superpowers/specs/2026-07-28-inventory-lineage-community-data-design.md` and preserve the source/evidence rules in `docs/superpowers/specs/2026-07-25-weedypedia-design.md`.
- Keep `private` and `catalog` outside the Data API's exposed schemas. Browser roles receive no table or function privileges in either schema.
- Every stored source record is immutable and addressable by `(source_id, external_record_key, content_hash)`.
- Store a raw payload only when the source register explicitly permits storage. Otherwise store a SHA-256 digest and retrieval reference, never an invented reconstruction.
- A source adapter may record imports and review cases only. It cannot write `api.catalog_references`, search projections, public profiles, or community aggregates.
- Do not give the source-import Edge Function a Supabase service-role key. Use a separate direct-database login that can assume only the `source_ingestor` NOINHERIT role and execute only `private.record_source_import(jsonb)`.
- Keep review/publication under a distinct `source_reviewer` NOINHERIT capability. The ingestor login must not belong to it.
- Every public catalog fact must resolve through an accepted review decision to one immutable assertion and one immutable source record.
- Unknown aliases, ambiguous entity mappings, conflicting lineage, deleted upstream records, and suspicious measurements create review cases.
- A THC or CBD percentage greater than 70 for flower creates a review case and is excluded from publication.
- Source-specific JSON keys remain inside the adapter and immutable source record; UI and public projections consume only normalized fields.
- Imports are idempotent. Retrying an identical record creates neither a duplicate source version nor duplicate assertions.
- One adapter failure does not delete or change the last published catalog state and does not prevent another adapter from completing.
- No Wikidata, Crossref, Europe PMC, BfArM, PharmNet, breeder, manufacturer, laboratory, commercial, image, scraping, or OCR connection is activated by this plan.
- A live source requires a later source-specific design decision covering owner, access method, rate, storage, license, attribution, image rights, confidence, reviewer, and rollback.
- Preserve the existing `SECURITY DEFINER SET search_path = ''`, explicit revoke/grant, RLS, AAL2, and browser publishable-key boundaries.

---

## Delivery Order and Dependency

This is package 1 of the approved 28 July design:

1. **This plan:** source register, immutable source versions, normalized assertions, review gate, and catalog-search projection
2. `docs/superpowers/plans/2026-07-28-inventory-lineage-community-values.md`: personal search, editable origins, and private community flower values
3. A later cultivar-profile plan consumes the same published projection for the full gesture-driven profile and subtle community line

Package 2 depends on the `CatalogSearchMatch` shape and `api.search_catalog_references(text)` created here. This package remains independently testable with synthetic fixtures.

## Target File Structure

### Adapter contract and synthetic fixtures

- `supabase/functions/_shared/source-adapters/types.ts`: closed normalized adapter types.
- `supabase/functions/_shared/source-adapters/validate.ts`: structural and domain validation.
- `supabase/functions/_shared/source-adapters/validate.test.ts`: contract, boundary, and malformed-record tests.
- `supabase/functions/tests/fixtures/source-adapter-valid.json`: synthetic valid batch.
- `supabase/functions/tests/fixtures/source-adapter-invalid-flower-value.json`: synthetic review-triggering batch.

### Source ingestion

- `supabase/migrations/*_source_adapter_foundation.sql`: source register, immutable records, assertions, review decisions/cases, projections, grants, and RPCs.
- `supabase/tests/database/03_source_foundation_schema.test.sql`: constraints and immutability.
- `supabase/tests/database/04_source_foundation_access.test.sql`: browser denial and ingestor/reviewer capability separation.
- `supabase/tests/database/05_source_publication.test.sql`: idempotency, review gating, projection, and failed-import preservation.
- `supabase/functions/source-import/index.ts`: internal-token ingestion endpoint backed by the narrow ingestor database login.
- `supabase/functions/source-import/source-import.test.ts`: authorization, validation, RPC, and failure-isolation tests.
- `supabase/config.toml`: custom-token-protected `source-import` function registration.
- `supabase/deno.json`: fixture-read permission for function tests.

### Public catalog contract and operations

- `src/catalog/catalog-search.ts`: browser-facing `CatalogSearchMatch` type and normalization-free display helpers.
- `src/catalog/catalog-search.test.ts`: mapping and display tests.
- `docs/operations/weedypedia-source-onboarding.md`: source approval, activation, review, rollback, and incident runbook.
- `README.md`: local source-contract and database checks.
- `.github/workflows/verify.yml`: retain source contract and pgTAP gates in CI.

---

### Task 1: Freeze the Normalized Adapter Contract

**Files:**
- Create: `supabase/functions/_shared/source-adapters/types.ts`
- Create: `supabase/functions/_shared/source-adapters/validate.ts`
- Create: `supabase/functions/_shared/source-adapters/validate.test.ts`
- Create: `supabase/functions/tests/fixtures/source-adapter-valid.json`
- Create: `supabase/functions/tests/fixtures/source-adapter-invalid-flower-value.json`

**Interfaces:**

```ts
export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue }

export type SourceEvidence =
  | {
      kind: 'raw'
      mediaType: 'application/json' | 'application/xml' | 'text/csv'
      payload: JsonValue
    }
  | {
      kind: 'checksum'
      algorithm: 'sha256'
      digest: string
      retrievalReference: string
    }

export type NormalizedAssertion =
  | {
      kind: 'name' | 'alias'
      subjectExternalKey: string
      name: string
      language: string | null
    }
  | {
      kind: 'lineage'
      subjectExternalKey: string
      parentExternalKey: string
      relationship: 'reported_parent' | 'historical_origin'
      position: 1 | 2 | null
    }
  | {
      kind: 'product_cultivar'
      subjectExternalKey: string
      cultivarExternalKey: string
      productForm: 'flower' | 'extract' | 'oil' | 'other'
    }
  | {
      kind: 'measurement'
      subjectExternalKey: string
      analyte: 'thc' | 'cbd'
      value: number
      unit: 'percent'
      productForm: 'flower' | 'extract' | 'oil' | 'other'
      measuredAt: string | null
    }

export type AdapterRecord = {
  externalRecordKey: string
  upstreamState: 'present' | 'deleted'
  retrievedAt: string
  sourceVersion: string | null
  evidence: SourceEvidence
  validFrom: string | null
  validTo: string | null
  assertions: NormalizedAssertion[]
}

export type AdapterBatch = {
  sourceId: string
  startedAt: string
  completedAt: string
  cursor: string | null
  records: AdapterRecord[]
  errors: Array<{
    externalRecordKey: string | null
    code: 'timeout' | 'schema_changed' | 'rate_limited' | 'invalid_record'
    message: string
  }>
}
```

- [ ] **Step 1: Write contract tests before implementation**

Cover:

- a raw JSON record and a checksum-only record;
- ISO timestamps and non-empty source/external keys;
- a lowercase 64-character SHA-256 digest;
- only the closed assertion kinds, forms, analytes, and units above;
- `position` limited to `1`, `2`, or `null`;
- source measurement precision preserved as received;
- a flower measurement above 70 returned as a valid record plus
  `reviewReasons: ['flower_value_above_70']`, not discarded by the adapter
  validator;
- malformed or source-specific top-level keys rejected.

The exported validator result is:

```ts
export type ValidatedAdapterBatch = {
  batch: AdapterBatch
  reviewReasonsByRecord: Record<string, string[]>
}

export function validateAdapterBatch(input: unknown): ValidatedAdapterBatch
```

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```sh
pnpm test:functions --filter source-adapters
```

If Deno's task runner does not forward `--filter`, run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/_shared/source-adapters/validate.test.ts
```

Expected: FAIL because the contract modules do not exist.

- [ ] **Step 3: Implement strict validation**

Implement explicit type guards; do not add a permissive index signature to
`AdapterBatch`, `AdapterRecord`, or assertions. Normalize no names and infer no
relationships in this layer. Reject non-finite numbers and invalid timestamps.
Return the original validated record values and only append review reasons.

- [ ] **Step 4: Add synthetic fixtures**

Use unmistakably synthetic names and IDs:

```json
{
  "sourceId": "synthetic-contract-source",
  "externalRecordKey": "synthetic-cultivar-001",
  "sourceVersion": "fixture-1"
}
```

No fixture may contain a real cultivar, real product, real laboratory result,
or copied external payload.

- [ ] **Step 5: Verify and commit**

Run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/_shared/source-adapters/validate.test.ts
git diff --check
```

Expected: all contract tests PASS.

```sh
git add supabase/functions/_shared/source-adapters \
  supabase/functions/tests/fixtures
git commit -m "feat: define source adapter contract"
```

---

### Task 2: Create the Immutable Source and Review Store

**Files:**
- Create via CLI: `supabase/migrations/*_source_adapter_foundation.sql`
- Create: `supabase/tests/database/03_source_foundation_schema.test.sql`
- Create: `supabase/tests/database/04_source_foundation_access.test.sql`

**Database interfaces:**

- `catalog.sources`
- `catalog.import_runs`
- `catalog.source_records`
- `catalog.normalized_assertions`
- `catalog.review_cases`
- `catalog.assertion_reviews`
- `private.record_source_import(p_batch jsonb)`
- `private.review_source_assertion(p_assertion_id uuid, p_decision text, p_entity_id uuid, p_related_entity_id uuid, p_note text)`

- [ ] **Step 1: Create the migration filename**

Run:

```sh
pnpm exec supabase migration new source_adapter_foundation
```

Use the generated timestamped filename unchanged.

- [ ] **Step 2: Write failing schema and access tests**

Schema tests must prove:

- all six internal tables exist only in `catalog`;
- source IDs and external record keys are non-empty and length-bounded;
- source status is one of `inactive`, `pilot`, `active`, `blocked`;
- license status is one of `unknown`, `review_required`, `approved`, `forbidden`;
- image rights are recorded independently from structured-data rights;
- `(source_id, external_record_key, content_hash)` is unique;
- record evidence is exactly one of raw payload or checksum/retrieval reference;
- assertion type and typed payload pass server-side checks;
- source records and assertions reject `UPDATE` and `DELETE`;
- a review decision cannot point to an assertion from another source record;
- accepted entity mappings reference `catalog.entities`;
- an assertion has at most one current review decision.

Access tests must switch between `anon`, `authenticated`, `source_ingestor`,
`source_reviewer`, and the database owner and prove:

- browser roles cannot resolve or select `catalog` tables;
- browser roles cannot execute either source-management function;
- `source_ingestor` can execute only record import and cannot review or
  publish;
- `source_reviewer` can review and publish but cannot insert arbitrary source
  records or mutate immutable tables;
- neither custom role has direct table mutation privileges;
- functions have `prosecdef = true` and an empty configured search path;
- `PUBLIC`, `anon`, and `authenticated` have no inherited execute grant;
- errors never return raw evidence from a different record.

- [ ] **Step 3: Run pgTAP and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the source foundation has not been migrated.

- [ ] **Step 4: Implement the source register**

The register records at least:

```sql
create table catalog.sources (
  id text primary key check (char_length(id) between 3 and 80),
  display_name text not null check (char_length(display_name) between 1 and 160),
  owner_name text not null,
  access_method text not null,
  permitted_frequency text not null,
  license_status text not null
    check (license_status in ('unknown', 'review_required', 'approved', 'forbidden')),
  license_reference text,
  raw_storage_allowed boolean not null default false,
  attribution_rules text not null,
  image_rights_status text not null,
  confidence_class text not null
    check (confidence_class in ('discovery', 'supporting', 'authoritative')),
  responsible_reviewer text not null,
  status text not null
    check (status in ('inactive', 'pilot', 'active', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
```

Seed only `synthetic-contract-source` with status `inactive`. Do not seed a live
external source.

- [ ] **Step 5: Implement immutable versions and assertions**

Use `bytea` or checked lowercase hex for SHA-256 consistently. The record must
store the register's license/storage decision as a snapshot, so later register
changes do not rewrite the historical permission basis.

Use a `BEFORE UPDATE OR DELETE` trigger that raises SQLSTATE `55000` on
`catalog.source_records` and `catalog.normalized_assertions`. Review decisions
live in `catalog.assertion_reviews`; never mutate the assertion to record a
decision.

- [ ] **Step 6: Implement separated ingestion and review capabilities**

Create `source_ingestor` and `source_reviewer` as NOLOGIN, NOINHERIT roles in
the migration. Production operations provision separate login roles and grant
each login exactly one of those capabilities; passwords and connection strings
never enter Git.

`private.record_source_import(jsonb)` must:

1. be executable only by `source_ingestor`;
2. require a registered source not marked `blocked` or `forbidden`;
3. reject raw evidence when `raw_storage_allowed = false`;
4. create one import run;
5. insert source records with
   `ON CONFLICT (source_id, external_record_key, content_hash) DO NOTHING`;
6. insert assertions only for newly stored versions;
7. create review cases for unknown mapping, conflicting lineage, upstream
   deletion, and flower THC/CBD above 70;
8. return only counts and record IDs created by this call.

`private.review_source_assertion(
p_assertion_id,
p_decision,
p_entity_id,
p_related_entity_id,
p_note
)` must:

1. be executable only by `source_reviewer`;
2. accept only `accepted` or `rejected`;
3. require a canonical entity for accepted name/alias/measurement assertions;
4. require both canonical entities for accepted lineage/product links;
5. record reviewer and timestamp without altering the assertion;
6. close related review cases only after a decision exists.

Revoke all function rights first, then grant import execute only to
`source_ingestor` and review execute only to `source_reviewer`. Do not grant
either function to `PUBLIC`, Supabase browser roles, `service_role`, or the
other custom capability.

- [ ] **Step 7: Verify and commit**

Run:

```sh
pnpm test:db
git diff --check
```

Expected: schema and access tests PASS.

```sh
git add supabase/migrations supabase/tests/database
git commit -m "feat: store immutable source assertions"
```

---

### Task 3: Add the Service-Only Import Boundary

**Files:**
- Create: `supabase/functions/source-import/index.ts`
- Create: `supabase/functions/source-import/source-import.test.ts`
- Modify: `supabase/config.toml`
- Modify: `supabase/deno.json`

**HTTP interface:**

```ts
type ImportResponse =
  | {
      ok: true
      runId: string
      insertedRecords: number
      insertedAssertions: number
      reviewCases: number
    }
  | {
      ok: false
      code: 'unauthorized' | 'invalid_batch' | 'source_blocked' | 'unavailable'
    }
```

- [ ] **Step 1: Write failing function tests**

Inject a fake Supabase RPC port and prove:

- missing, too-short, malformed, and incorrect trigger tokens return 401 or
  403 without invoking the database function;
- a request with the correct constant-time internal trigger token validates
  the batch before calling `private.record_source_import`;
- malformed batches return `invalid_batch` without echoing the payload;
- an identical retry sends the same normalized batch and maps database
  idempotency counts;
- database and timeout failures return `unavailable` and log only source ID,
  run correlation ID, and error code;
- raw payloads, names, measurement values, trigger tokens, connection URLs,
  and database response
  bodies never enter logs.

- [ ] **Step 2: Run the function test and verify failure**

Run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/source-import/source-import.test.ts
```

Expected: FAIL because `source-import` does not exist.

- [ ] **Step 3: Implement dependency-injected request handling**

Export:

```ts
export type SourceImportDependencies = {
  authorizeTriggerToken(request: Request): Promise<boolean>
  recordBatch(batch: AdapterBatch): Promise<{
    run_id: string
    inserted_records: number
    inserted_assertions: number
    review_cases: number
  }>
  log(event: {
    correlationId: string
    sourceId: string | null
    code: string
  }): void
}

export function createSourceImportHandler(
  dependencies: SourceImportDependencies,
): (request: Request) => Promise<Response>
```

Pin `"postgres": "npm:postgres@3.4.9"` in `supabase/deno.json` and refresh
`supabase/deno.lock`. Configure the production client with parameterized
queries, TLS verification, a short connection timeout, a pool size of one per
Edge isolate, and `prepare: false`, because Supavisor transaction mode does not
support prepared statements.

The production handler compares `X-Weedypedia-Import-Token` to the
server-only `SOURCE_IMPORT_TRIGGER_TOKEN` in constant time. It connects through
`SOURCE_INGESTOR_POOLER_URL`, whose login can assume only
`source_ingestor`, and executes the private import function in a parameterized
query. It does not receive or use `SUPABASE_SECRET_KEY`, a service-role bearer,
or reviewer credentials. Neither server secret appears in Vite variables,
logs, or response metadata.

- [ ] **Step 4: Register the function**

This is a service-to-service endpoint authenticated by the high-entropy
internal trigger token rather than a user JWT. Disable the gateway JWT check so
the request reaches the constant-time token verifier:

```toml
[functions.source-import]
verify_jwt = false
```

Accept only `POST`, return 405 for every other method, and do not enable CORS.
No cron or live external fetch is configured in this task.

- [ ] **Step 5: Verify and commit**

Run:

```sh
pnpm test:functions
git diff --check
```

Expected: all Edge Function tests PASS.

```sh
git add supabase/functions/source-import supabase/config.toml supabase/deno.json
git commit -m "feat: add protected source import boundary"
```

---

### Task 4: Publish Review-Gated Catalog Search Projections

**Files:**
- Modify: the migration from Task 2 before it has shipped; otherwise create via CLI: `supabase/migrations/*_catalog_search_projection.sql`
- Create: `supabase/tests/database/05_source_publication.test.sql`
- Modify: `supabase/seed.sql`
- Create: `src/catalog/catalog-search.ts`
- Create: `src/catalog/catalog-search.test.ts`

**Public interfaces:**

```ts
export type CatalogSearchMatch = {
  id: string
  kind: 'cultivar' | 'product'
  canonicalName: string
  matchedName: string
  matchReason: 'canonical' | 'alias' | 'product'
  canonicalCultivarId: string | null
  isFlower: boolean
  preferredParents: readonly [string | null, string | null]
  hasAdditionalLineage: boolean
  sourcedThcLabel: string | null
  sourcedCbdLabel: string | null
  sourcedValueEvidence: ReadonlyArray<{
    sourceName: string
    sourceVersion: string | null
    retrievedAt: string
    citationUrl: string | null
    attribution: string
  }>
}
```

Database RPC:

```sql
api.search_catalog_references(p_query text)
```

It returns at most eight rows with exactly the snake_case equivalent of
`CatalogSearchMatch`.

- [ ] **Step 1: Write failing publication tests**

Use synthetic assertions and prove:

- unreviewed and rejected assertions never enter a public projection;
- an adapter import alone cannot publish;
- an accepted canonical name creates or updates one `api.catalog_references`
  row;
- accepted aliases match with reason `alias` while retaining canonical name;
- an accepted flower product maps to one canonical cultivar;
- only one reviewed lineage relation per child/position is marked preferred;
- additional accepted lineage assertions set
  `has_additional_lineage = true`;
- accepted, comparable THC/CBD source facts produce sourced labels separately
  from community values;
- every sourced label carries at least one public citation entry containing
  source name, version when available, retrieval date, attribution, and a safe
  citation URL when the register permits it;
- a flower value above 70 remains a review case and is never published;
- retrying publication is idempotent;
- publication is atomic: a deliberately invalid snapshot leaves the previous
  rows unchanged;
- anonymous access is denied and authenticated read access returns no source
  raw payload, reviewer, internal confidence, or review note.

- [ ] **Step 2: Run focused tests and verify failure**

Run:

```sh
pnpm test:db
pnpm test -- src/catalog/catalog-search.test.ts
```

Expected: FAIL because the projection and TypeScript mapper do not exist.

- [ ] **Step 3: Extend the public reference projection**

Extend the existing `api.catalog_references` rather than creating a competing
catalog table:

```sql
alter table api.catalog_references
  add column canonical_cultivar_id uuid,
  add column is_flower boolean not null default false,
  add column preferred_parent_one_name text,
  add column preferred_parent_two_name text,
  add column has_additional_lineage boolean not null default false,
  add column sourced_thc_label text,
  add column sourced_cbd_label text,
  add column sourced_value_evidence jsonb not null default '[]'::jsonb,
  add column published_at timestamptz not null default now();
```

Create an internal published-search-term table keyed by reference, term,
language, and match reason. Browser roles receive no direct grant on this
table.

- [ ] **Step 4: Implement the review-gated publisher**

Create `private.publish_reviewed_catalog()` as a `source_reviewer`-only,
`SECURITY DEFINER SET search_path = ''` function. It must build a complete
temporary snapshot from accepted reviews, validate foreign mappings and the
70-percent flower cap, then replace the public reference and term projections
inside one transaction.

The publisher must never read community contributions or inventory rows.
Failure raises and leaves the prior committed projection visible.
It copies only public citation metadata into `sourced_value_evidence`, never
raw payloads, internal review notes, checksums, or private retrieval headers.

- [ ] **Step 5: Implement authenticated search**

`api.search_catalog_references(text)`:

- is `STABLE`, uses no dynamic SQL, and has a fixed search path;
- trims the query, rejects empty or over-160-character input, and returns no
  more than eight matches;
- ranks exact canonical, canonical prefix, exact alias/product, then substring;
- returns the matched spelling and explicit match reason;
- returns no community average;
- returns public sourced-value citations with the selected reference so the
  inventory can show evidence without another privileged lookup;
- is executable only by `authenticated`;
- exposes no source-internal table or identifier.

- [ ] **Step 6: Implement the TypeScript contract mapper**

Export a row mapper that rejects malformed kinds, reasons, missing cultivar
mapping for a flower product, and parent arrays longer than two. The UI must
display `matchedName` as the explanation and must not silently overwrite the
user's typed input with `canonicalName`.

- [ ] **Step 7: Refresh synthetic seed data**

Keep the existing clearly synthetic catalog entries. Add synthetic aliases,
two preferred parents, one additional lineage assertion, and one flower
product mapping through the same review/publication path. Do not seed a
community contribution or real external claim.

- [ ] **Step 8: Verify and commit**

Run:

```sh
pnpm test -- src/catalog/catalog-search.test.ts
pnpm test:db
pnpm build
git diff --check
```

Expected: mapping, publication, search, database, and build checks PASS.

```sh
git add supabase/migrations supabase/tests/database supabase/seed.sql \
  src/catalog
git commit -m "feat: publish reviewed catalog search"
```

---

### Task 5: Document Source Approval and Add Final Gates

**Files:**
- Create: `docs/operations/weedypedia-source-onboarding.md`
- Modify: `README.md`
- Modify: `.github/workflows/verify.yml`

- [ ] **Step 1: Write the operational acceptance checklist**

The runbook must require, before a source status can become `pilot` or
`active`:

1. owner and access method;
2. documented allowed frequency;
3. license reference and structured-data storage permission;
4. attribution requirements;
5. image rights reviewed separately;
6. confidence class;
7. named responsible reviewer;
8. synthetic contract and timeout tests;
9. staging import with zero automatic publications;
10. review-queue inspection;
11. rollback by blocking the source while preserving the last published state.

Document that the first candidate source-specific plans are:

- Wikidata: external IDs, base names, aliases; never sole lineage evidence.
- Crossref or Europe PMC: DOI/publication metadata; never automatic cultivar
  truth.
- BfArM/PharmNet: only after access and reuse-right review.

- [ ] **Step 2: Extend CI without activating a source**

Ensure the existing jobs run:

```sh
pnpm test:functions
pnpm test:db
pnpm test
pnpm build
```

Do not add external network calls, external API keys, scheduled imports, or
real payload fixtures to CI.

- [ ] **Step 3: Run the complete acceptance suite**

Run:

```sh
pnpm test:functions
pnpm test:db
pnpm test
pnpm build
git diff --check
git status --short
```

Expected:

- all source-contract, function, pgTAP, unit, and build checks PASS;
- no live source is active;
- no browser bundle contains a service secret;
- only intended files are modified.

- [ ] **Step 4: Commit the runbook and gates**

```sh
git add docs/operations/weedypedia-source-onboarding.md README.md \
  .github/workflows/verify.yml
git commit -m "docs: define source onboarding gate"
```

---

## Package Acceptance

Before starting the inventory/community plan, independently verify:

- an adapter cannot publish;
- the import runtime has no service-role key or reviewer capability;
- browser roles cannot access source internals or source-management functions;
- identical imports and publications are idempotent;
- source records and assertions are immutable;
- rejected, unreviewed, conflicting, or greater-than-70 flower facts remain
  out of public projections;
- the catalog search contract returns canonical, alias, and flower-product
  matches with an explicit reason;
- a failed import or publication preserves the last published state;
- no real external connector, payload, secret, or schedule has been activated.
