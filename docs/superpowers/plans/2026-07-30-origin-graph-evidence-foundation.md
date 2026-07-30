# Weedypedia Origin Graph and Evidence Foundation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Extend the existing reviewed source pipeline into a versioned, evidence-bearing knowledge graph that keeps documented lineage, genetic sample similarity, and medical-product mapping technically separate.

**Architecture:** Version 2 of the closed source-adapter contract adds exact assertion locators, extraction methods, four entity kinds, typed knowledge claims, documented lineage relations, and sample-only genetic relations. Existing immutable source records remain valid, but only version-2 assertions are eligible for the new graph. A separate reviewer capability assigns one of the six approved evidence states. A security-definer publisher validates type compatibility and writes an immutable private snapshot plus an atomic authenticated read-only projection. The browser consumes one strict JSON graph contract through a repository; this package does not add the public profile, filters, live sources, AI extraction, or the deferred 3D tree.

**Tech Stack:** Node.js 24, pnpm 11.9.0, React 19.2.8, TypeScript 7.0.2, Vite 8.1.5, Vitest 4.1.10, Supabase CLI 2.109.1, Supabase Postgres 17, pgTAP, Supabase Edge Functions, Deno 2.8.1, `@supabase/supabase-js` 2.110.8

## Global Constraints

- Implement package 1 of `docs/superpowers/specs/2026-07-30-origin-rich-pilot-catalog-design.md`.
- Preserve all existing account, inventory, community-value, catalog-search, AAL2, RLS, explicit-grant, and `SECURITY DEFINER SET search_path = ''` boundaries.
- Keep `catalog` and `private` outside the exposed Data API. Browser code reads only authenticated, read-only `api.published_*` projections or an explicitly granted `api` RPC.
- Keep the existing `source_ingestor` and `source_reviewer` roles `NOINHERIT`. The ingestor must never review or publish; the reviewer must never import.
- Do not put a service-role key, database password, reviewer credential, or source-import secret in browser code.
- Keep all existing immutable source records and assertions. The migration must not update or delete historical evidence.
- Every new adapter batch declares `contractVersion: 2`. Every version-2 assertion carries an exact `sourceLocator` and an `extractionMethod`.
- Names are display data, never technical identity keys. Canonical relationships use reviewed UUID mappings from `catalog.entities`.
- Support exactly four graph node kinds: `origin_population`, `cultivar`, `genetic_sample`, and `product`.
- Keep documented lineage and genetic evidence in different edge layers. A genetic relationship may connect only two `genetic_sample` nodes and must never be converted into a cultivar parent relation.
- Keep medical products separate from cultivars. A product may map to a cultivar, but product measurements must not become cultivar properties.
- Store all six evidence states exactly: `confirmed`, `single_source`, `disputed`, `historical`, `unknown`, and `retracted`.
- Do not add automatic publication policy in this package. All graph assertions used by the synthetic proof are manually reviewed.
- Do not connect CannSeek, Kannapedia, Phylos, breeders, laboratories, manufacturers, pharmacies, image services, scraping, OCR, or AI services in this package.
- Do not add real strain names or real source records. Fixtures remain unmistakably synthetic.
- Do not add images. The later public UI must use a neutral placeholder until rights are explicitly approved.
- Do not implement the deferred 3D graph. The contract must be sufficient for a later renderer without encoding layout coordinates as evidence.
- Keep the current `CatalogRepository` and inventory search response backward compatible. The new graph uses a separate `KnowledgeRepository`.
- Run focused tests after each change. Before completion run the complete TypeScript, Deno, pgTAP, build, and SQL-lint gates.

---

## Delivery Order and Dependency

This plan is the first independently testable implementation package for the approved pilot:

1. **This plan:** graph node kinds, evidence-bearing assertions, separated edge layers, immutable graph snapshots, authenticated read model, and browser contract.
2. **Source-rights package:** approve each concrete source, permitted fields, access method, attribution, text rights, image rights, and rollback owner. Encode the approved cadence of daily medical-product checks, weekly active breeder/strain checks, monthly historical/scientific checks, plus a targeted manual refresh.
3. **Publication-policy package:** implement the deterministic rule of one approved primary source or two independent approved secondary sources, with no open conflict, an exact locator, and completed structural validation. An AI confidence score never substitutes for those conditions. Images, licenses, conflicts, unusual values, and any attempted similarity-to-parentage conversion remain manual-review cases. Add pre-pilot full audit, a monthly 20-percent sample of newly auto-published assertions, rollback controls, and automatic source pause after a critical identity or parentage error.
4. **Source-adapter package:** add one adapter per approved source and an unpublished 50–75-entry pilot import containing 20–25 origin or historical entries, 25–35 documented crosses or influential descendants, and 10–15 entries linked to German medical flower products. Groups may overlap. Include at least ten deliberate conflict fixtures.
5. **Pilot-release package:** complete the full manual audit, then add public search, profile, source resolution, and combinable filters for Sativa/Indica/Hybrid, origin region, era, relation type, evidence status, strain/group, German medical products, documented lineage, and genetic similarity. “Alle anzeigen” resets only display filters. Finish iPhone and Android acceptance before controlled publication.

The source-rights package may start only after the graph vocabulary here is stable. No live adapter may start before its individual rights decision. The public UI may use the synthetic graph during development but must not present it as real data.

## Target File Structure

### Adapter contract

- Modify: `supabase/functions/_shared/source-adapters/types.ts`
- Modify: `supabase/functions/_shared/source-adapters/validate.ts`
- Modify: `supabase/functions/_shared/source-adapters/validate.test.ts`
- Modify: `supabase/functions/tests/fixtures/source-adapter-valid.json`
- Modify: `supabase/functions/tests/fixtures/source-adapter-invalid-flower-value.json`
- Create: `supabase/functions/tests/fixtures/source-adapter-knowledge-graph-valid.json`
- Modify: `supabase/functions/source-import/source-import.test.ts`

### Database graph and publication boundary

- Create: `supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql`
- Modify: `supabase/tests/database/03_source_foundation_schema.test.sql`
- Modify: `supabase/tests/database/04_source_foundation_access.test.sql`
- Modify: `supabase/tests/database/05_source_publication.test.sql`
- Create: `supabase/tests/database/06_knowledge_graph_publication.test.sql`
- Modify: `supabase/seed.sql`

### Browser contract

- Create: `src/knowledge/knowledge-graph.ts`
- Create: `src/knowledge/knowledge-graph.test.ts`
- Create: `src/knowledge/knowledge-repository.ts`
- Create: `src/knowledge/supabase-knowledge-repository.ts`
- Create: `src/knowledge/supabase-knowledge-repository.test.ts`

### Operations and verification

- Modify: `docs/operations/weedypedia-source-onboarding.md`
- Modify: `README.md`

---

### Task 1: Version the Adapter Contract and Require Assertion Traceability

**Files:**
- Modify: `supabase/functions/_shared/source-adapters/types.ts`
- Modify: `supabase/functions/_shared/source-adapters/validate.ts`
- Modify: `supabase/functions/_shared/source-adapters/validate.test.ts`
- Modify: `supabase/functions/tests/fixtures/source-adapter-valid.json`
- Modify: `supabase/functions/tests/fixtures/source-adapter-invalid-flower-value.json`
- Modify: `supabase/functions/source-import/source-import.test.ts`

**Interfaces:**

Add these closed shared types:

```ts
export type EntityKind =
  | 'origin_population'
  | 'cultivar'
  | 'genetic_sample'
  | 'product'

export type ExtractionMethod =
  | 'structured'
  | 'manual'
  | 'ai_assisted'

export type AssertionTrace = {
  sourceLocator: string
  extractionMethod: ExtractionMethod
}

export type EvidenceStatus =
  | 'confirmed'
  | 'single_source'
  | 'disputed'
  | 'historical'
  | 'unknown'
  | 'retracted'
```

Replace the current assertion union with a version-2 union. Keep `SourceEvidence`, `AdapterRecord`, `AdapterError`, and `ValidatedAdapterBatch`, but add `contractVersion: 2` to `AdapterBatch`.

```ts
type TracedAssertion = {
  trace: AssertionTrace
}

export type NormalizedAssertion =
  | (TracedAssertion & {
      kind: 'entity_kind'
      subjectExternalKey: string
      entityKind: EntityKind
    })
  | (TracedAssertion & {
      kind: 'name'
      subjectExternalKey: string
      name: string
      language: string | null
    })
  | (TracedAssertion & {
      kind: 'alias'
      subjectExternalKey: string
      name: string
      language: string | null
      aliasType: 'spelling' | 'breeder' | 'market' | 'historical' | 'other'
      market: string | null
    })
  | (TracedAssertion & {
      kind: 'traditional_classification'
      subjectExternalKey: string
      classification: 'sativa' | 'indica' | 'hybrid'
    })
  | (TracedAssertion & {
      kind: 'origin_region'
      subjectExternalKey: string
      regionName: string
      regionCode: string | null
    })
  | (TracedAssertion & {
      kind: 'era'
      subjectExternalKey: string
      startYear: number | null
      endYear: number | null
      label: string | null
    })
  | (TracedAssertion & {
      kind: 'sample_reference'
      subjectExternalKey: string
      sampleIdentifier: string
      datasetName: string
      datasetVersion: string | null
      submitter: string | null
      laboratory: string | null
      sampledAt: string | null
    })
  | (TracedAssertion & {
      kind: 'lineage'
      subjectExternalKey: string
      relatedExternalKey: string | null
      relationship:
        | 'reported_parent'
        | 'cross'
        | 'backcross'
        | 'selection_from'
        | 'historical_origin'
        | 'population_membership'
        | 'unknown_parent'
      position: 1 | 2 | null
    })
  | (TracedAssertion & {
      kind: 'genetic_relation'
      subjectExternalKey: string
      relatedExternalKey: string
      relationship: 'genetic_similarity' | 'sample_match'
      method: string
      datasetName: string
      datasetVersion: string | null
      metricName: string
      value: number | null
      unit: string | null
    })
  | (TracedAssertion & {
      kind: 'product_cultivar'
      subjectExternalKey: string
      cultivarExternalKey: string
      productForm: 'flower' | 'extract' | 'oil' | 'other'
    })
  | (TracedAssertion & {
      kind: 'product_market'
      subjectExternalKey: string
      countryCode: string
      medical: true
    })
  | (TracedAssertion & {
      kind: 'measurement'
      subjectExternalKey: string
      analyte: 'thc' | 'cbd'
      value: number
      unit: 'percent'
      productForm: 'flower' | 'extract' | 'oil' | 'other'
      batchIdentifier: string | null
      measuredAt: string | null
    })

export type AdapterBatch = {
  contractVersion: 2
  sourceId: string
  startedAt: string
  completedAt: string
  cursor: string | null
  records: AdapterRecord[]
  errors: AdapterError[]
}
```

- [ ] **Step 1: Add failing tests for the versioned trace contract**

Add tests that:

- reject a missing or non-numeric `contractVersion`;
- reject every version except `2`;
- reject missing, empty, untrimmed, or over-1000-character `sourceLocator`;
- reject any extraction method outside the three values;
- preserve the exact locator rather than converting it into a URL;
- continue to keep a flower value over 70 as review-only evidence;
- continue to reject unknown batch, record, trace, and assertion fields.

Use a JSON-path locator in the valid fixture:

```json
{
  "trace": {
    "sourceLocator": "$.records[0].name",
    "extractionMethod": "structured"
  }
}
```

- [ ] **Step 2: Run the focused contract test and verify failure**

Run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/_shared/source-adapters/validate.test.ts
```

Expected: FAIL because `contractVersion` and `trace` are not recognized.

- [ ] **Step 3: Implement exact validation for version and trace**

Add:

```ts
function assertionTrace(value: unknown, path: string): AssertionTrace {
  const input = recordAt(value, path)
  exactKeys(input, ['sourceLocator', 'extractionMethod'], path)
  return {
    sourceLocator: text(input.sourceLocator, `${path}.sourceLocator`, 1000),
    extractionMethod: oneOf(
      input.extractionMethod,
      ['structured', 'manual', 'ai_assisted'] as const,
      `${path}.extractionMethod`,
    ),
  }
}
```

Validate `contractVersion` before records, and add `trace` to the exact-key list of every assertion. Do not coerce version strings, dates, metric values, or years.

- [ ] **Step 4: Upgrade existing synthetic fixtures**

Add `"contractVersion": 2` to both current fixture batches. Add a distinct exact locator to each assertion. Give aliases explicit `aliasType` and `market`.

Use only synthetic locator strings and URLs under `example.invalid`.

- [ ] **Step 5: Run contract and source-import tests**

Run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/_shared/source-adapters/validate.test.ts \
  supabase/functions/source-import/source-import.test.ts
```

Expected: PASS.

- [ ] **Step 6: Commit the contract version**

```sh
git add \
  supabase/functions/_shared/source-adapters/types.ts \
  supabase/functions/_shared/source-adapters/validate.ts \
  supabase/functions/_shared/source-adapters/validate.test.ts \
  supabase/functions/tests/fixtures/source-adapter-valid.json \
  supabase/functions/tests/fixtures/source-adapter-invalid-flower-value.json \
  supabase/functions/source-import/source-import.test.ts
git commit -m "feat: version source assertion evidence"
```

---

### Task 2: Add and Validate the Knowledge Assertion Vocabulary

**Files:**
- Modify: `supabase/functions/_shared/source-adapters/validate.ts`
- Modify: `supabase/functions/_shared/source-adapters/validate.test.ts`
- Create: `supabase/functions/tests/fixtures/source-adapter-knowledge-graph-valid.json`

- [ ] **Step 1: Add failing tests for all four nodes and both edge layers**

The new fixture must contain these synthetic records:

| External key | Entity kind | Purpose |
|---|---|---|
| `synthetic-origin-001` | `origin_population` | historical origin node |
| `synthetic-parent-001` | `cultivar` | documented parent |
| `synthetic-child-001` | `cultivar` | documented child |
| `synthetic-sample-001` | `genetic_sample` | first measured sample |
| `synthetic-sample-002` | `genetic_sample` | second measured sample |
| `synthetic-product-001` | `product` | medical flower product |

Include:

- an `entity_kind` and `name` assertion for every record;
- one alias with alias type and market;
- traditional classification, region, and era claims;
- one sample reference for each sample;
- `reported_parent`, `population_membership`, and `unknown_parent` lineage assertions;
- one sample-to-sample `genetic_similarity`;
- one product-to-cultivar mapping;
- one German medical-product market claim;
- one product measurement.

Assert that validation returns the fixture byte-for-structure without inferred relationships or normalized names.

- [ ] **Step 2: Add failing domain-validation cases**

Test these invalid inputs:

- `unknown_parent` with a non-null `relatedExternalKey`;
- any other lineage relationship with a null `relatedExternalKey`;
- lineage position `3`;
- era with both years present and `endYear < startYear`;
- a year outside `-10000..2100`;
- a genetic relation with the same subject and related key;
- a genetic relation with a non-finite value;
- `sample_match` with a numeric value or unit;
- `genetic_similarity` with only one of `value` and `unit`;
- a product-market country code other than two uppercase ASCII letters;
- `medical` set to anything except the literal `true`;
- empty method, dataset, metric, sample identifier, region, or alias type.

- [ ] **Step 3: Run the focused test and verify failure**

Run:

```sh
pnpm exec deno test \
  --config supabase/deno.json \
  supabase/functions/_shared/source-adapters/validate.test.ts
```

Expected: FAIL on the first unimplemented knowledge assertion kind.

- [ ] **Step 4: Implement the closed assertion validators**

Use these cross-field rules:

```ts
const hasPair =
  (input.value === null && input.unit === null)
  || (typeof input.value === 'number' && input.unit !== null)

if (kind === 'genetic_relation' && !hasPair) {
  invalid(path, 'value and unit must both be present or both be null')
}

if (
  kind === 'genetic_relation'
  && input.relationship === 'sample_match'
  && (input.value !== null || input.unit !== null)
) {
  invalid(path, 'sample_match does not carry a numeric score')
}
```

For `era`, accept negative years for historical representation, but only integer values in `-10000..2100`.

Do not type-check canonical entity compatibility here. The adapter knows external keys, not reviewed canonical UUID mappings. Enforce node compatibility at the reviewer boundary in Task 4.

- [ ] **Step 5: Run the complete Deno suite**

Run:

```sh
pnpm test:functions
```

Expected: PASS.

- [ ] **Step 6: Commit the knowledge vocabulary**

```sh
git add \
  supabase/functions/_shared/source-adapters/validate.ts \
  supabase/functions/_shared/source-adapters/validate.test.ts \
  supabase/functions/tests/fixtures/source-adapter-knowledge-graph-valid.json
git commit -m "feat: define knowledge graph assertions"
```

---

### Task 3: Extend the Immutable Database Schema Without Rewriting History

**Files:**
- Create: `supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql`
- Modify: `supabase/tests/database/03_source_foundation_schema.test.sql`
- Modify: `supabase/tests/database/04_source_foundation_access.test.sql`
- Modify: `supabase/tests/database/05_source_publication.test.sql`
- Modify: `supabase/seed.sql`

**Schema additions:**

The migration must:

1. replace only the `catalog.entities.kind` check constraint so it accepts the four graph kinds;
2. expand `catalog.normalized_assertions.assertion_kind` with the new assertion kinds;
3. record the adapter contract version on every new import run;
4. link every new version-2 source record to its import run while preserving null only for immutable legacy rows;
5. preserve the old assertion payload validator for already stored version-1 rows;
6. require trace data for every version-2 import in `private.record_source_import(jsonb)`;
7. add evidence status to accepted reviews;
8. leave source records, normalized assertions, and completed snapshot content immutable.

Add the import-version link:

```sql
alter table catalog.import_runs
  add column contract_version smallint not null default 1
    check (contract_version in (1, 2));

alter table catalog.source_records
  add column import_run_id uuid
    references catalog.import_runs(id) on delete restrict;

create index source_records_import_run_idx
  on catalog.source_records(import_run_id)
  where import_run_id is not null;
```

Existing immutable rows retain `import_run_id is null` and
`catalog.import_runs.contract_version = 1`. Every future version-2 insert made
by `private.record_source_import` writes the generated import-run UUID into
each source record.

Add evidence status:

```sql
alter table catalog.assertion_reviews
  add column evidence_status text;

update catalog.assertion_reviews
set evidence_status = 'single_source'
where decision = 'accepted';

alter table catalog.assertion_reviews
  add constraint assertion_reviews_evidence_status_check
  check (
    (
      decision = 'accepted'
      and evidence_status in (
        'confirmed',
        'single_source',
        'disputed',
        'historical',
        'unknown',
        'retracted'
      )
    )
    or (
      decision = 'rejected'
      and evidence_status is null
    )
  );
```

In the same migration, replace the body of the existing five-argument
`private.review_source_assertion` without changing its signature or grants.
Accepted legacy reviews write `single_source`; rejected legacy reviews write
`null`. This keeps all existing catalog-search tests valid before the new
graph-specific reviewer is added.

Add immutable snapshot tables in the private `catalog` schema:

```sql
create table catalog.knowledge_publication_snapshots (
  id uuid primary key default gen_random_uuid(),
  previous_snapshot_id uuid
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  published_by text not null check (char_length(published_by) between 1 and 240),
  published_at timestamptz not null default now(),
  assertion_count integer not null check (assertion_count >= 0)
);

create table catalog.knowledge_current_snapshot (
  singleton boolean primary key default true check (singleton),
  snapshot_id uuid not null unique
    references catalog.knowledge_publication_snapshots(id) on delete restrict
);

create table catalog.knowledge_snapshot_nodes (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  entity_id uuid not null references catalog.entities(id) on delete restrict,
  kind text not null check (
    kind in ('origin_population', 'cultivar', 'genetic_sample', 'product')
  ),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160),
  primary key (snapshot_id, entity_id)
);

create table catalog.knowledge_snapshot_claims (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  assertion_id uuid not null
    references catalog.normalized_assertions(id) on delete restrict,
  entity_id uuid not null references catalog.entities(id) on delete restrict,
  claim_kind text not null check (
    claim_kind in (
      'entity_kind',
      'name',
      'alias',
      'traditional_classification',
      'origin_region',
      'era',
      'sample_reference',
      'product_market',
      'measurement'
    )
  ),
  value jsonb not null,
  evidence_status text not null,
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object'),
  primary key (snapshot_id, assertion_id)
);

create table catalog.knowledge_snapshot_edges (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  assertion_id uuid not null
    references catalog.normalized_assertions(id) on delete restrict,
  from_entity_id uuid not null
    references catalog.entities(id) on delete restrict,
  to_entity_id uuid references catalog.entities(id) on delete restrict,
  layer text not null check (
    layer in ('documented_lineage', 'genetic_similarity', 'product_mapping')
  ),
  relationship text not null check (
    relationship in (
      'reported_parent',
      'cross',
      'backcross',
      'selection_from',
      'historical_origin',
      'population_membership',
      'unknown_parent',
      'genetic_similarity',
      'sample_match',
      'product_cultivar'
    )
  ),
  position smallint check (position in (1, 2)),
  evidence_status text not null,
  details jsonb not null check (jsonb_typeof(details) = 'object'),
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object'),
  primary key (snapshot_id, assertion_id)
);
```

- [ ] **Step 1: Add failing schema tests**

Add pgTAP assertions that:

- all four entity kinds insert successfully;
- a fifth kind fails with SQLSTATE `23514`;
- all new assertion kinds are accepted only with structurally valid payloads;
- a version-2 batch without trace fails;
- a version-2 batch with unknown trace keys fails;
- existing synthetic version-1 source rows remain queryable and immutable;
- every version-2 source record points to an import run with contract version 2;
- accepted reviews require one of the six evidence states;
- rejected reviews require a null evidence state;
- completed snapshot metadata, node, claim, and edge rows cannot be updated or deleted;
- only the single-row `catalog.knowledge_current_snapshot` pointer may move to a newer immutable snapshot.

- [ ] **Step 2: Run the database suite and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the four node kinds and snapshot tables do not exist.

- [ ] **Step 3: Implement compatibility-aware payload validation**

Add `private.source_assertion_trace_valid(jsonb)` and extend `private.source_assertion_payload_valid(text, jsonb)` with the version-2 exact shapes.

The table check may continue accepting the exact old payload shapes because immutable history already contains them. The replaced `private.record_source_import(jsonb)` accepts only `contractVersion: 2` for every future call:

- a missing version raises SQLSTATE `22023`;
- versions other than `2` raise SQLSTATE `22023`;
- version `2` requires trace on every assertion;
- a retry of the same version-2 record remains idempotent.

Do not update the old rows to fabricate locators.
Update lineage conflict detection to compare
`payload ->> 'relatedExternalKey'`. The compatibility branch that reads
already stored version-1 assertions may use
`coalesce(payload ->> 'relatedExternalKey', payload ->> 'parentExternalKey')`.

- [ ] **Step 4: Protect snapshot history**

Attach the existing immutable-mutation pattern to the snapshot metadata, node, claim, and edge tables. Do not attach it to the single-row current-snapshot pointer. Use a dedicated error message:

```sql
raise exception using
  errcode = '55000',
  message = 'knowledge publication snapshots are immutable';
```

Revoke all direct table privileges, including access to the current-snapshot pointer, from `public`, `anon`, `authenticated`, `service_role`, `source_ingestor`, and `source_reviewer`.

- [ ] **Step 5: Upgrade synthetic seed batches to contract version 2**

Add `contractVersion`, trace fields, alias metadata, batch identifiers, and the new lineage key shape to every import batch in:

- `supabase/seed.sql`;
- `supabase/tests/database/03_source_foundation_schema.test.sql`;
- `supabase/tests/database/04_source_foundation_access.test.sql`;
- `supabase/tests/database/05_source_publication.test.sql`.

Keep every seed entity and assertion explicitly labeled as test data.

Do not add real cultivar, origin, sample, or product data.

- [ ] **Step 6: Run schema and regression tests**

Run:

```sh
pnpm test:db
```

Expected: PASS, including existing database tests 01–05.

- [ ] **Step 7: Commit the schema foundation**

```sh
git add \
  supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql \
  supabase/tests/database/03_source_foundation_schema.test.sql \
  supabase/seed.sql
git commit -m "feat: store versioned knowledge evidence"
```

---

### Task 4: Enforce Canonical Node Compatibility at the Reviewer Boundary

**Files:**
- Modify: `supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql`
- Modify: `supabase/tests/database/04_source_foundation_access.test.sql`
- Create: `supabase/tests/database/06_knowledge_graph_publication.test.sql`

**Reviewer interface:**

Create a separate graph-aware review function:

```sql
private.review_knowledge_assertion(
  p_assertion_id uuid,
  p_decision text,
  p_entity_id uuid,
  p_related_entity_id uuid,
  p_evidence_status text,
  p_note text
) returns void
```

The current five-argument `private.review_source_assertion` remains for backward-compatible catalog review and writes `single_source` for accepted legacy assertions. New graph assertions use only `private.review_knowledge_assertion`.

- [ ] **Step 1: Add failing access and compatibility tests**

Verify:

- only `source_reviewer` can execute the new review function;
- `source_ingestor`, `anon`, `authenticated`, and `service_role` cannot execute it;
- it is `SECURITY DEFINER` with an empty search path;
- rejected assertions require null entity IDs and null evidence status;
- accepted assertions require a valid evidence status and canonical entity;
- `entity_kind` must match `catalog.entities.kind`;
- `reported_parent`, `cross`, and `backcross` connect cultivar to cultivar;
- `selection_from` connects a cultivar to a cultivar or origin population;
- `population_membership` connects cultivar or genetic sample to an origin population;
- `unknown_parent` connects a cultivar to no related entity;
- `genetic_relation` connects only two different genetic samples;
- `product_cultivar` connects product to cultivar;
- non-relation claims reject a related entity ID;
- a source status of `blocked` cannot be reviewed as accepted.

- [ ] **Step 2: Run focused database tests and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because `private.review_knowledge_assertion` does not exist.

- [ ] **Step 3: Implement the graph-aware reviewer**

Lock the assertion and its source record with `FOR UPDATE`. Read canonical kinds by UUID. Reject cross-layer mappings before writing `catalog.assertion_reviews`.

For `genetic_relation`, explicitly reject any canonical entity kind other than `genetic_sample`; do not infer or create cultivar relationships.

Use an upsert only for the review row of the same assertion. Preserve the immutable source assertion and write reviewer, time, decision, canonical mappings, status, and note.

- [ ] **Step 4: Preserve capability separation**

Use explicit grants:

```sql
revoke all on function private.review_knowledge_assertion(
  uuid, text, uuid, uuid, text, text
) from public, anon, authenticated, service_role, source_ingestor;

grant execute on function private.review_knowledge_assertion(
  uuid, text, uuid, uuid, text, text
) to source_reviewer;
```

- [ ] **Step 5: Run access and graph tests**

Run:

```sh
pnpm test:db
```

Expected: PASS.

- [ ] **Step 6: Commit the reviewer gate**

```sh
git add \
  supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql \
  supabase/tests/database/04_source_foundation_access.test.sql \
  supabase/tests/database/06_knowledge_graph_publication.test.sql
git commit -m "feat: review typed knowledge relationships"
```

---

### Task 5: Publish an Immutable Snapshot and Atomic Authenticated Read Model

**Files:**
- Modify: `supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql`
- Modify: `supabase/tests/database/06_knowledge_graph_publication.test.sql`

**Public projection:**

Create:

```sql
create table api.published_knowledge_snapshot (
  singleton boolean primary key default true check (singleton),
  snapshot_id uuid not null unique,
  published_at timestamptz not null
);

create table api.published_knowledge_nodes (
  snapshot_id uuid not null,
  id uuid primary key,
  kind text not null check (
    kind in ('origin_population', 'cultivar', 'genetic_sample', 'product')
  ),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160)
);

create table api.published_knowledge_claims (
  snapshot_id uuid not null,
  assertion_id uuid primary key,
  node_id uuid not null
    references api.published_knowledge_nodes(id) on delete cascade,
  claim_kind text not null check (
    claim_kind in (
      'entity_kind',
      'name',
      'alias',
      'traditional_classification',
      'origin_region',
      'era',
      'sample_reference',
      'product_market',
      'measurement'
    )
  ),
  value jsonb not null,
  evidence_status text not null,
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object')
);

create table api.published_knowledge_edges (
  snapshot_id uuid not null,
  assertion_id uuid primary key,
  from_node_id uuid not null
    references api.published_knowledge_nodes(id) on delete cascade,
  to_node_id uuid
    references api.published_knowledge_nodes(id) on delete cascade,
  layer text not null check (
    layer in ('documented_lineage', 'genetic_similarity', 'product_mapping')
  ),
  relationship text not null check (
    relationship in (
      'reported_parent',
      'cross',
      'backcross',
      'selection_from',
      'historical_origin',
      'population_membership',
      'unknown_parent',
      'genetic_similarity',
      'sample_match',
      'product_cultivar'
    )
  ),
  position smallint check (position in (1, 2)),
  evidence_status text not null,
  details jsonb not null check (jsonb_typeof(details) = 'object'),
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object')
);
```

Create:

```sql
private.publish_reviewed_knowledge_graph() returns uuid
```

and:

```sql
api.get_published_knowledge_graph() returns jsonb
```

The RPC result has this exact top-level shape:

```json
{
  "snapshotId": "61000000-0000-4000-8000-000000000001",
  "publishedAt": "2026-07-30T12:00:00+00:00",
  "nodes": [],
  "claims": [],
  "edges": []
}
```

- [ ] **Step 1: Add failing publication tests**

Use only synthetic records and manually reviewed mappings. Prove:

- import alone publishes zero graph rows;
- reviewed `entity_kind` and `name` create each of the four node kinds;
- every published claim includes source name, source version, retrieval time, safe HTTPS citation URL or null, exact source locator, extraction method, and attribution;
- the six evidence states survive unchanged;
- lineage edges use `documented_lineage`;
- genetic relations use `genetic_similarity`;
- product mappings use `product_mapping`;
- an unknown parent has `to_node_id is null`;
- an unreviewed, rejected, forbidden-license, deleted, expired, or blocked-source assertion is absent;
- unsafe non-HTTPS citations become null without losing attribution and locator;
- malformed graph data aborts publication and leaves the preceding snapshot unchanged;
- a second successful publication creates a new immutable private snapshot and atomically replaces the public snapshot;
- the existing inventory catalog projection still passes its regression tests.

- [ ] **Step 2: Run the focused database suite and verify failure**

Run:

```sh
pnpm test:db
```

Expected: FAIL because the graph publisher and public tables do not exist.

- [ ] **Step 3: Implement snapshot construction**

Inside one transaction:

1. acquire a dedicated advisory transaction lock;
2. select accepted assertions whose source record joins an import run with contract version 2, whose payload is traced, and whose source is present, approved, and non-blocked;
3. validate canonical names, entity kinds, edge endpoints, no self-relations, and layer compatibility;
4. insert one new private snapshot and its node, claim, and edge rows;
5. move `catalog.knowledge_current_snapshot` to the new immutable snapshot;
6. replace the four `api` current-projection tables;
7. return the new snapshot UUID.

Use the reviewed canonical entity IDs, never external keys, for public endpoints.
For claims, build the closed `value` object from the domain fields listed in
Task 6. Do not copy `kind`, `subjectExternalKey`, related external keys, or
`trace` into `value`. For edges, use an empty details object for documented
lineage, the method/dataset/metric fields for genetic relations, and only
`productForm` for product mappings.

Build one evidence object per assertion:

```sql
jsonb_build_object(
  'sourceName', source.display_name,
  'sourceVersion', source_record.source_version,
  'retrievedAt', source_record.retrieved_at,
  'citationUrl', case
    when source_record.retrieval_reference ~ '^https://'
      then source_record.retrieval_reference
    else null
  end,
  'sourceLocator', assertion.payload #>> '{trace,sourceLocator}',
  'extractionMethod', assertion.payload #>> '{trace,extractionMethod}',
  'attribution', source_record.attribution_snapshot
)
```

- [ ] **Step 4: Implement the read-only graph RPC**

Make `api.get_published_knowledge_graph()`:

- `language sql`;
- `stable`;
- `security invoker`;
- `set search_path = ''`;
- deterministic in array ordering;
- empty-safe when no snapshot exists;
- executable by `authenticated` only.

Revoke execute from `public`, `anon`, and `service_role`. Grant no insert, update, or delete privileges on the public graph tables.

- [ ] **Step 5: Add RLS and explicit read grants**

Enable RLS on all four public graph tables. Add authenticated select policies. Explicitly revoke all from `anon`; grant `select` to `authenticated`.

The authenticated role must still be unable to resolve `catalog` or `private`.

- [ ] **Step 6: Run publication and access tests**

Run:

```sh
pnpm test:db
pnpm exec supabase db lint \
  --schema api,catalog,private,public \
  --level error \
  --fail-on error
```

Expected: PASS.

- [ ] **Step 7: Commit the atomic graph projection**

```sh
git add \
  supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql \
  supabase/tests/database/06_knowledge_graph_publication.test.sql
git commit -m "feat: publish immutable knowledge snapshots"
```

---

### Task 6: Add a Strict Browser Knowledge-Graph Contract

**Files:**
- Create: `src/knowledge/knowledge-graph.ts`
- Create: `src/knowledge/knowledge-graph.test.ts`

**Browser types:**

```ts
export type KnowledgeEvidence = {
  sourceName: string
  sourceVersion: string | null
  retrievedAt: string
  citationUrl: string | null
  sourceLocator: string
  extractionMethod: 'structured' | 'manual' | 'ai_assisted'
  attribution: string
}

export type EvidenceStatus =
  | 'confirmed'
  | 'single_source'
  | 'disputed'
  | 'historical'
  | 'unknown'
  | 'retracted'

export type KnowledgeNode = {
  id: string
  kind: 'origin_population' | 'cultivar' | 'genetic_sample' | 'product'
  canonicalName: string
}

type ClaimBase = {
  assertionId: string
  nodeId: string
  evidenceStatus: EvidenceStatus
  evidence: KnowledgeEvidence
}

export type KnowledgeClaim =
  | (ClaimBase & {
      kind: 'entity_kind'
      value: { entityKind: KnowledgeNode['kind'] }
    })
  | (ClaimBase & {
      kind: 'name'
      value: { name: string; language: string | null }
    })
  | (ClaimBase & {
      kind: 'alias'
      value: {
        name: string
        language: string | null
        aliasType: 'spelling' | 'breeder' | 'market' | 'historical' | 'other'
        market: string | null
      }
    })
  | (ClaimBase & {
      kind: 'traditional_classification'
      value: { classification: 'sativa' | 'indica' | 'hybrid' }
    })
  | (ClaimBase & {
      kind: 'origin_region'
      value: { regionName: string; regionCode: string | null }
    })
  | (ClaimBase & {
      kind: 'era'
      value: {
        startYear: number | null
        endYear: number | null
        label: string | null
      }
    })
  | (ClaimBase & {
      kind: 'sample_reference'
      value: {
        sampleIdentifier: string
        datasetName: string
        datasetVersion: string | null
        submitter: string | null
        laboratory: string | null
        sampledAt: string | null
      }
    })
  | (ClaimBase & {
      kind: 'product_market'
      value: { countryCode: string; medical: true }
    })
  | (ClaimBase & {
      kind: 'measurement'
      value: {
        analyte: 'thc' | 'cbd'
        value: number
        unit: 'percent'
        productForm: 'flower' | 'extract' | 'oil' | 'other'
        batchIdentifier: string | null
        measuredAt: string | null
      }
    })

type EdgeBase = {
  assertionId: string
  fromNodeId: string
  evidenceStatus: EvidenceStatus
  evidence: KnowledgeEvidence
}

export type KnowledgeEdge =
  | (EdgeBase & {
      toNodeId: string | null
      layer: 'documented_lineage'
      relationship:
        | 'reported_parent'
        | 'cross'
        | 'backcross'
        | 'selection_from'
        | 'historical_origin'
        | 'population_membership'
        | 'unknown_parent'
      position: 1 | 2 | null
      details: Record<string, never>
    })
  | (EdgeBase & {
      toNodeId: string
      layer: 'genetic_similarity'
      relationship: 'genetic_similarity' | 'sample_match'
      position: null
      details: {
        method: string
        datasetName: string
        datasetVersion: string | null
        metricName: string
        value: number | null
        unit: string | null
      }
    })
  | (EdgeBase & {
      toNodeId: string
      layer: 'product_mapping'
      relationship: 'product_cultivar'
      position: null
      details: {
        productForm: 'flower' | 'extract' | 'oil' | 'other'
      }
    })

export type KnowledgeGraph = {
  snapshotId: string
  publishedAt: string
  nodes: readonly KnowledgeNode[]
  claims: readonly KnowledgeClaim[]
  edges: readonly KnowledgeEdge[]
}

export function mapKnowledgeGraph(value: unknown): KnowledgeGraph
```

- [ ] **Step 1: Write failing parser and invariant tests**

Cover:

- the complete valid synthetic RPC response;
- all four node kinds and all three edge layers;
- all six evidence states;
- invalid UUIDs, dates, URLs, arrays, JSON values, and unknown fields;
- duplicate node or assertion IDs;
- claims that reference missing nodes;
- edges that reference missing nodes;
- `unknown_parent` with a target;
- any other edge without a target;
- pedigree edges between non-compatible node kinds;
- genetic edges between anything except two distinct genetic samples;
- product mappings other than product-to-cultivar;
- a genetic relationship mislabeled as documented lineage;
- a pedigree relationship mislabeled as genetic similarity;
- non-HTTPS citation URLs;
- no interpretation of spatial position or visual distance.

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```sh
pnpm test -- src/knowledge/knowledge-graph.test.ts
```

Expected: FAIL because the module does not exist.

- [ ] **Step 3: Implement strict row mapping**

Use explicit parsers like the existing `src/catalog/catalog-search.ts`; do not use `as KnowledgeGraph` on the RPC response.

Validate every reference after mapping all nodes:

```ts
const nodesById = new Map(graph.nodes.map((node) => [node.id, node]))

for (const edge of graph.edges) {
  const from = nodesById.get(edge.fromNodeId)
  const to = edge.toNodeId === null
    ? null
    : nodesById.get(edge.toNodeId)
  if (!from || (edge.toNodeId !== null && !to)) {
    throw new Error('Invalid knowledge graph edge reference')
  }
}
```

Keep evidence status as metadata. Do not discard `disputed`, `historical`, `unknown`, or `retracted` claims in the mapper.

- [ ] **Step 4: Run focused and full unit tests**

Run:

```sh
pnpm test -- src/knowledge/knowledge-graph.test.ts
pnpm test
```

Expected: PASS.

- [ ] **Step 5: Commit the browser graph model**

```sh
git add \
  src/knowledge/knowledge-graph.ts \
  src/knowledge/knowledge-graph.test.ts
git commit -m "feat: validate published knowledge graphs"
```

---

### Task 7: Add the Abortable Supabase Knowledge Repository

**Files:**
- Create: `src/knowledge/knowledge-repository.ts`
- Create: `src/knowledge/supabase-knowledge-repository.ts`
- Create: `src/knowledge/supabase-knowledge-repository.test.ts`

**Repository interface:**

```ts
import type { KnowledgeGraph } from './knowledge-graph'

export type KnowledgeRepository = {
  loadGraph(signal?: AbortSignal): Promise<KnowledgeGraph | null>
}
```

The Supabase port mirrors the existing catalog port:

```ts
type RpcResult = {
  data: unknown
  error: { code?: string; message: string } | null
}

type RpcQueryPort = PromiseLike<RpcResult> & {
  abortSignal(signal: AbortSignal): RpcQueryPort
}

export type SupabaseKnowledgeClientPort = {
  rpc(name: string): RpcQueryPort
}
```

- [ ] **Step 1: Write failing repository tests**

Verify:

- it calls `get_published_knowledge_graph` with no browser-supplied source or reviewer values;
- it returns `null` for a null RPC payload before the first publication;
- it maps a valid graph through `mapKnowledgeGraph`;
- it fails closed on malformed responses;
- it returns the German availability message on Supabase errors;
- it checks abort before the RPC;
- it forwards the signal through `.abortSignal(signal)`;
- it checks abort again after the RPC resolves.

- [ ] **Step 2: Run the focused test and verify failure**

Run:

```sh
pnpm test -- src/knowledge/supabase-knowledge-repository.test.ts
```

Expected: FAIL because the repository modules do not exist.

- [ ] **Step 3: Implement the repository**

Use the existing abort semantics from `src/catalog/supabase-catalog-repository.ts`.

The only user-facing repository error is:

```ts
throw new Error('Der Weedypedia-Datenstand ist derzeit nicht verfügbar.')
```

Do not add retries, background polling, caching, local mutation, or source refresh controls in this package.

- [ ] **Step 4: Run repository and regression tests**

Run:

```sh
pnpm test -- \
  src/knowledge/supabase-knowledge-repository.test.ts \
  src/catalog/supabase-catalog-repository.test.ts
pnpm test
```

Expected: PASS.

- [ ] **Step 5: Commit the repository**

```sh
git add \
  src/knowledge/knowledge-repository.ts \
  src/knowledge/supabase-knowledge-repository.ts \
  src/knowledge/supabase-knowledge-repository.test.ts
git commit -m "feat: load published knowledge snapshots"
```

---

### Task 8: Prove the Separated Layers End to End

**Files:**
- Modify: `supabase/tests/database/06_knowledge_graph_publication.test.sql`
- Modify: `supabase/seed.sql`

- [ ] **Step 1: Add one complete synthetic publication scenario**

The database test must:

1. register an approved synthetic source;
2. import the version-2 knowledge fixture;
3. create canonical UUIDs for all four node kinds;
4. manually review every assertion with explicit evidence status;
5. publish the graph;
6. call `api.get_published_knowledge_graph()`;
7. prove the JSON contains the intended nodes, claims, and edges.

Use fixed UUIDs in the `62000000-0000-4000-8000-*` range so assertions stay readable and deterministic.

- [ ] **Step 2: Add a deliberate false-parentage defense**

Create a second synthetic assertion claiming genetic similarity between two samples. Attempt to review it against two cultivar UUIDs and assert SQLSTATE `22023`.

Then review it correctly against the sample UUIDs and prove:

- it appears only in `api.published_knowledge_edges.layer = 'genetic_similarity'`;
- no `documented_lineage` row is created;
- no preferred-parent field in `api.catalog_references` changes.

- [ ] **Step 3: Add a deliberate lineage conflict fixture**

Import two traced `reported_parent` assertions for the same child and position but different parent external keys.

Prove:

- both immutable assertions remain stored;
- a `conflicting_lineage` review case exists;
- neither enters the graph before manual review;
- if both are manually accepted as `disputed`, both remain separately visible with that status.

This is one structural conflict proof. The required ten real pilot conflict fixtures belong to the later unpublished-pilot package.

- [ ] **Step 4: Add snapshot-failure preservation**

After one valid publication, accept a second canonical `name` assertion for the same entity through the reviewer boundary. The individual mapping is valid, but the resulting snapshot has two canonical names for one node. Assert publication fails and the RPC still returns the previous snapshot UUID and row counts.

- [ ] **Step 5: Run the complete platform gate**

Run:

```sh
pnpm check:platform
```

Expected: PASS.

- [ ] **Step 6: Commit the end-to-end proof**

```sh
git add \
  supabase/tests/database/06_knowledge_graph_publication.test.sql \
  supabase/seed.sql
git commit -m "test: prove separated knowledge graph layers"
```

---

### Task 9: Document the Boundary and Run Final Verification

**Files:**
- Modify: `docs/operations/weedypedia-source-onboarding.md`
- Modify: `README.md`

- [ ] **Step 1: Document contract version 2**

Add:

- the four node kinds;
- every assertion kind;
- the required trace object;
- the six evidence states;
- reviewer type-compatibility rules;
- the separate lineage, genetic, and product layers;
- the rule that genetic similarity is never parentage;
- the rule that a source candidate remains inactive until the later rights package approves it;
- the exact focused test commands.

- [ ] **Step 2: Document current package exclusions**

State explicitly:

- no live sources are connected;
- no real strains are seeded;
- no AI output is automatically published;
- no source-specific cadence is scheduled;
- no image is published;
- no 3D visualization exists;
- no public pilot has been released.

- [ ] **Step 3: Run the complete verification suite**

Run:

```sh
pnpm test
pnpm build
pnpm test:functions
pnpm test:db
pnpm exec supabase db lint \
  --schema api,catalog,private,public \
  --level error \
  --fail-on error
git diff --check
```

Expected:

- all Vitest tests pass;
- TypeScript and Vite build pass;
- all Deno tests pass;
- all pgTAP tests pass;
- SQL lint reports no error-level issue;
- `git diff --check` prints nothing.

- [ ] **Step 4: Inspect the final diff for scope**

Run:

```sh
git status --short
git diff --stat HEAD
git diff -- \
  supabase/functions/_shared/source-adapters \
  supabase/migrations/20260730120000_origin_graph_evidence_foundation.sql \
  supabase/tests/database \
  src/knowledge \
  docs/operations/weedypedia-source-onboarding.md \
  README.md
```

Confirm:

- there is no source URL except synthetic `example.invalid` data and existing documentation;
- there is no service-role key or database credential;
- no existing inventory/community feature was removed;
- no browser write path reaches the graph;
- no UI or 3D code entered this package;
- all new public claims carry status and evidence.

- [ ] **Step 5: Commit documentation**

```sh
git add \
  docs/operations/weedypedia-source-onboarding.md \
  README.md
git commit -m "docs: explain knowledge graph evidence boundary"
```

- [ ] **Step 6: Record the handoff**

In the completion note, report:

- the final commit range;
- exact test counts and commands;
- whether local Supabase and SQL lint were available;
- the number of synthetic node kinds, claim kinds, and edge layers covered;
- confirmation that no live source or real strain data was added;
- the next dependency: one-by-one source-rights decisions.

Do not claim the 50–75-entry pilot, automatic publication policy, public UI, mobile acceptance, or 3D graph is complete.

---

## Acceptance Checklist

- [ ] Every new adapter batch uses `contractVersion: 2`.
- [ ] Every version-2 assertion has an exact source locator and extraction method.
- [ ] All four node kinds are represented and type-checked.
- [ ] All six evidence states survive into the public graph.
- [ ] Documented lineage, genetic similarity, and product mapping are separate layers.
- [ ] Genetic relations can connect only two genetic samples.
- [ ] Products and product measurements remain separate from cultivar properties.
- [ ] Source import cannot review or publish.
- [ ] Source review cannot import.
- [ ] Browser roles cannot read `catalog` or `private`.
- [ ] Authenticated browser code has read-only access to the `api` graph projection.
- [ ] Graph publication creates immutable private snapshots and atomically changes the public current snapshot.
- [ ] A failed publication leaves the preceding public snapshot intact.
- [ ] Legacy immutable evidence remains unchanged.
- [ ] Existing inventory search and community-value tests still pass.
- [ ] All fixtures are synthetic and no live source is active.
- [ ] No image, automatic AI publication, public profile/filter UI, or 3D renderer was added.
- [ ] Full unit, build, Deno, pgTAP, SQL-lint, and whitespace checks pass.
