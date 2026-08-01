begin;
select no_plan();

create temporary table task8_seed_snapshot_baseline as
select count(*)::bigint as snapshot_count
from catalog.knowledge_publication_snapshots;

update catalog.sources
set status = 'blocked'
where id = 'synthetic-knowledge-graph-seed-source';

delete from api.published_knowledge_edges;
delete from api.published_knowledge_claims;
delete from api.published_knowledge_nodes;
delete from api.published_knowledge_snapshot;
delete from catalog.knowledge_current_snapshot;

insert into catalog.sources(
  id,
  display_name,
  owner_name,
  access_method,
  permitted_frequency,
  license_status,
  license_reference,
  raw_storage_allowed,
  attribution_rules,
  image_rights_status,
  confidence_class,
  responsible_reviewer,
  status
) values
  (
    'synthetic-graph-review-source',
    'Synthetic graph review source',
    'Synthetic owner',
    'synthetic fixture',
    'manual tests only',
    'approved',
    'https://example.invalid/license',
    false,
    'Synthetic graph review attribution',
    'not included',
    'supporting',
    'graph-review-test-reviewer',
    'active'
  ),
  (
    'synthetic-blocked-review-source',
    'Synthetic blocked review source',
    'Synthetic owner',
    'synthetic fixture',
    'manual tests only',
    'approved',
    'https://example.invalid/license',
    false,
    'Synthetic blocked review attribution',
    'not included',
    'supporting',
    'graph-review-test-reviewer',
    'blocked'
  );

insert into catalog.import_runs(
  id,
  source_id,
  started_at,
  completed_at,
  cursor,
  adapter_errors,
  contract_version
) values
  (
    '63000000-0000-4000-8000-000000000001',
    'synthetic-graph-review-source',
    '2026-07-30T11:59:00Z',
    '2026-07-30T12:00:00Z',
    null,
    '[]',
    2
  ),
  (
    '63000000-0000-4000-8000-000000000002',
    'synthetic-blocked-review-source',
    '2026-07-30T11:59:00Z',
    '2026-07-30T12:00:00Z',
    null,
    '[]',
    2
  ),
  (
    '63000000-0000-4000-8000-000000000003',
    'synthetic-graph-review-source',
    '2026-07-30T11:58:00Z',
    '2026-07-30T11:59:00Z',
    null,
    '[]',
    1
  );

insert into catalog.source_records(
  id,
  source_id,
  import_run_id,
  external_record_key,
  upstream_state,
  retrieved_at,
  source_version,
  evidence_kind,
  raw_media_type,
  raw_payload,
  content_hash,
  retrieval_reference,
  valid_from,
  valid_to,
  license_status_snapshot,
  raw_storage_allowed_snapshot,
  attribution_snapshot
) values
  (
    '64000000-0000-4000-8000-000000000001',
    'synthetic-graph-review-source',
    '63000000-0000-4000-8000-000000000001',
    'synthetic-graph-review-record',
    'present',
    '2026-07-30T12:00:00Z',
    'fixture-1',
    'checksum',
    null,
    null,
    'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    'https://example.invalid/graph-review-record',
    null,
    null,
    'approved',
    false,
    'Synthetic graph review attribution'
  ),
  (
    '64000000-0000-4000-8000-000000000002',
    'synthetic-blocked-review-source',
    '63000000-0000-4000-8000-000000000002',
    'synthetic-blocked-review-record',
    'present',
    '2026-07-30T12:00:00Z',
    'fixture-1',
    'checksum',
    null,
    null,
    'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
    'https://example.invalid/blocked-review-record',
    null,
    null,
    'approved',
    false,
    'Synthetic blocked review attribution'
  ),
  (
    '64000000-0000-4000-8000-000000000003',
    'synthetic-graph-review-source',
    '63000000-0000-4000-8000-000000000003',
    'synthetic-legacy-review-record',
    'present',
    '2026-07-30T11:59:00Z',
    'legacy-fixture-1',
    'checksum',
    null,
    null,
    'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
    'https://example.invalid/legacy-review-record',
    null,
    null,
    'approved',
    false,
    'Synthetic legacy review attribution'
  );

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '65000000-0000-4000-8000-000000000001',
    'origin_population',
    'Synthetic origin population one',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000002',
    'origin_population',
    'Synthetic origin population two',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000003',
    'cultivar',
    'Synthetic cultivar one',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000004',
    'cultivar',
    'Synthetic cultivar two',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000005',
    'genetic_sample',
    'Synthetic genetic sample one',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000006',
    'genetic_sample',
    'Synthetic genetic sample two',
    false
  ),
  (
    '65000000-0000-4000-8000-000000000007',
    'product',
    'Synthetic product',
    false
  );

insert into catalog.normalized_assertions(
  id,
  source_record_id,
  assertion_index,
  assertion_kind,
  subject_external_key,
  payload
) values
  (
    '66000000-0000-4000-8000-000000000001',
    '64000000-0000-4000-8000-000000000001',
    0,
    'entity_kind',
    'synthetic-entity-kind',
    '{
      "kind":"entity_kind",
      "trace":{"sourceLocator":"$.entity.kind","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-entity-kind",
      "entityKind":"cultivar"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000002',
    '64000000-0000-4000-8000-000000000001',
    1,
    'name',
    'synthetic-name',
    '{
      "kind":"name",
      "trace":{"sourceLocator":"$.entity.name","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-name",
      "name":"Synthetic graph name",
      "language":"en"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000003',
    '64000000-0000-4000-8000-000000000001',
    2,
    'lineage',
    'synthetic-reported-child',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.reported","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-reported-child",
      "relatedExternalKey":"synthetic-reported-parent",
      "relationship":"reported_parent",
      "position":1
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000004',
    '64000000-0000-4000-8000-000000000001',
    3,
    'lineage',
    'synthetic-cross-child',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.cross","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-cross-child",
      "relatedExternalKey":"synthetic-cross-parent",
      "relationship":"cross",
      "position":1
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000005',
    '64000000-0000-4000-8000-000000000001',
    4,
    'lineage',
    'synthetic-backcross-child',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.backcross","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-backcross-child",
      "relatedExternalKey":"synthetic-backcross-parent",
      "relationship":"backcross",
      "position":2
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000006',
    '64000000-0000-4000-8000-000000000001',
    5,
    'lineage',
    'synthetic-selection',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.selection","extractionMethod":"manual"},
      "subjectExternalKey":"synthetic-selection",
      "relatedExternalKey":"synthetic-selection-source",
      "relationship":"selection_from",
      "position":null
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000007',
    '64000000-0000-4000-8000-000000000001',
    6,
    'lineage',
    'synthetic-population-member',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.population","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-population-member",
      "relatedExternalKey":"synthetic-origin-population",
      "relationship":"population_membership",
      "position":null
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000008',
    '64000000-0000-4000-8000-000000000001',
    7,
    'lineage',
    'synthetic-unknown-parent',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.unknown","extractionMethod":"manual"},
      "subjectExternalKey":"synthetic-unknown-parent",
      "relatedExternalKey":null,
      "relationship":"unknown_parent",
      "position":1
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000009',
    '64000000-0000-4000-8000-000000000001',
    8,
    'genetic_relation',
    'synthetic-sample-one',
    '{
      "kind":"genetic_relation",
      "trace":{"sourceLocator":"$.genetics.relation","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-sample-one",
      "relatedExternalKey":"synthetic-sample-two",
      "relationship":"genetic_similarity",
      "method":"Synthetic comparison",
      "datasetName":"Synthetic dataset",
      "datasetVersion":"v1",
      "metricName":"similarity",
      "value":0.75,
      "unit":"ratio"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000010',
    '64000000-0000-4000-8000-000000000001',
    9,
    'product_cultivar',
    'synthetic-product',
    '{
      "kind":"product_cultivar",
      "trace":{"sourceLocator":"$.product.cultivar","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-product",
      "cultivarExternalKey":"synthetic-product-cultivar",
      "productForm":"flower"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000011',
    '64000000-0000-4000-8000-000000000001',
    10,
    'lineage',
    'synthetic-historical-origin-cultivar',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.historicalCultivar","extractionMethod":"manual"},
      "subjectExternalKey":"synthetic-historical-origin-cultivar",
      "relatedExternalKey":"synthetic-historical-population",
      "relationship":"historical_origin",
      "position":null
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000012',
    '64000000-0000-4000-8000-000000000001',
    11,
    'lineage',
    'synthetic-historical-origin-population',
    '{
      "kind":"lineage",
      "trace":{"sourceLocator":"$.lineage.historicalPopulation","extractionMethod":"manual"},
      "subjectExternalKey":"synthetic-historical-origin-population",
      "relatedExternalKey":"synthetic-earlier-population",
      "relationship":"historical_origin",
      "position":null
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000013',
    '64000000-0000-4000-8000-000000000002',
    0,
    'entity_kind',
    'synthetic-blocked-entity-kind',
    '{
      "kind":"entity_kind",
      "trace":{"sourceLocator":"$.blocked.kind","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-blocked-entity-kind",
      "entityKind":"cultivar"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000014',
    '64000000-0000-4000-8000-000000000001',
    12,
    'measurement',
    'synthetic-product-measurement',
    '{
      "kind":"measurement",
      "trace":{"sourceLocator":"$.product.measurement","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-product-measurement",
      "analyte":"thc",
      "value":18.5,
      "unit":"percent",
      "productForm":"flower",
      "batchIdentifier":"SYNTHETIC-REVIEW-BATCH",
      "measuredAt":"2026-07-30T10:00:00Z"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000015',
    '64000000-0000-4000-8000-000000000001',
    13,
    'product_market',
    'synthetic-product-market',
    '{
      "kind":"product_market",
      "trace":{"sourceLocator":"$.product.market","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-product-market",
      "countryCode":"DE",
      "medical":true
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000016',
    '64000000-0000-4000-8000-000000000001',
    14,
    'sample_reference',
    'synthetic-sample-reference',
    '{
      "kind":"sample_reference",
      "trace":{"sourceLocator":"$.sample.reference","extractionMethod":"structured"},
      "subjectExternalKey":"synthetic-sample-reference",
      "sampleIdentifier":"SYNTHETIC-SAMPLE-REFERENCE",
      "datasetName":"Synthetic dataset",
      "datasetVersion":"v1",
      "submitter":"Synthetic submitter",
      "laboratory":"Synthetic laboratory",
      "sampledAt":"2026-07-30T10:00:00Z"
    }'
  ),
  (
    '66000000-0000-4000-8000-000000000017',
    '64000000-0000-4000-8000-000000000003',
    0,
    'name',
    'synthetic-legacy-name',
    '{
      "kind":"name",
      "subjectExternalKey":"synthetic-legacy-name",
      "name":"Synthetic legacy name",
      "language":"en"
    }'
  );

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'rejected',
      '65000000-0000-4000-8000-000000000003',
      null,
      null,
      'invalid rejected mapping'
    )$$,
  '22023',
  null,
  'a rejected knowledge assertion cannot map a canonical entity'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'rejected',
      null,
      null,
      'single_source',
      'invalid rejected evidence'
    )$$,
  '22023',
  null,
  'a rejected knowledge assertion requires a null evidence state'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'rejected',
      null,
      null,
      null,
      '  synthetic rejection  '
    )$$,
  'a rejected knowledge assertion stores no canonical mapping or evidence state'
);

select ok(
  (
    select
      decision = 'rejected'
      and entity_id is null
      and related_entity_id is null
      and evidence_status is null
      and note = 'synthetic rejection'
    from catalog.assertion_reviews
    where assertion_id = '66000000-0000-4000-8000-000000000001'
  ),
  'the rejected review row contains only its decision metadata'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      null,
      null,
      'single_source',
      'missing canonical entity'
    )$$,
  '22023',
  null,
  'an accepted knowledge assertion requires a canonical entity'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      null,
      'missing evidence state'
    )$$,
  '22023',
  null,
  'an accepted knowledge assertion requires an evidence state'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'synthetic_invalid',
      'invalid evidence state'
    )$$,
  '22023',
  null,
  'an accepted knowledge assertion rejects evidence outside the closed set'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      '65000000-0000-4000-8000-000000000099',
      null,
      'single_source',
      'unknown canonical entity'
    )$$,
  '22023',
  null,
  'an accepted knowledge assertion requires an existing canonical entity'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      null,
      'single_source',
      'wrong canonical kind'
    )$$,
  '22023',
  null,
  'an entity-kind assertion must match the canonical entity kind'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000001',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'confirmed',
      '  typed entity acceptance  '
    )$$,
  'a matching entity-kind assertion can be accepted'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000002',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'invalid related mapping'
    )$$,
  '22023',
  null,
  'a non-relation claim cannot map a related entity'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000002',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'single_source',
      'synthetic name acceptance'
    )$$,
  'a non-relation claim maps only its canonical subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000014',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'single_source',
      'invalid measurement subject'
    )$$,
  '22023',
  null,
  'measurement rejects a cultivar subject'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000014',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      null,
      'single_source',
      'synthetic product measurement'
    )$$,
  'measurement accepts a product subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000015',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'single_source',
      'invalid product-market subject'
    )$$,
  '22023',
  null,
  'product-market rejects a cultivar subject'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000015',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      null,
      'single_source',
      'synthetic product market'
    )$$,
  'product-market accepts a product subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000016',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'single_source',
      'invalid sample-reference subject'
    )$$,
  '22023',
  null,
  'sample-reference rejects a cultivar subject'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000016',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      null,
      'single_source',
      'synthetic genetic sample reference'
    )$$,
  'sample-reference accepts a genetic-sample subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000017',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'confirmed',
      'invalid graph review of legacy assertion'
    )$$,
  '22023',
  null,
  'the graph reviewer rejects an accepted version-1 assertion'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000017',
      'rejected',
      null,
      null,
      null,
      'invalid graph rejection of legacy assertion'
    )$$,
  '22023',
  null,
  'the graph reviewer rejects a rejected version-1 assertion'
);

select lives_ok(
  $$select private.review_source_assertion(
      '66000000-0000-4000-8000-000000000017',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'legacy catalog acceptance'
    )$$,
  'the legacy reviewer still accepts a version-1 catalog assertion'
);

select is(
  (
    select evidence_status
    from catalog.assertion_reviews
    where assertion_id = '66000000-0000-4000-8000-000000000017'
  ),
  'single_source',
  'the legacy reviewer keeps version-1 acceptance at single-source evidence'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000003',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'synthetic reported parent'
    )$$,
  'reported parent connects cultivar to cultivar'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000004',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'synthetic cross'
    )$$,
  'cross connects cultivar to cultivar'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000005',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'synthetic backcross'
    )$$,
  'backcross connects cultivar to cultivar'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000003',
      'accepted',
      '65000000-0000-4000-8000-000000000001',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'invalid reported child kind'
    )$$,
  '22023',
  null,
  'documented parentage rejects a non-cultivar subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000004',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000001',
      'single_source',
      'invalid cross target kind'
    )$$,
  '22023',
  null,
  'documented parentage rejects a non-cultivar target'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000006',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'historical',
      'synthetic cultivar selection'
    )$$,
  'selection-from may connect a cultivar to another cultivar'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000006',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000001',
      'historical',
      'synthetic population selection'
    )$$,
  'selection-from may connect a cultivar to an origin population'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000006',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      '65000000-0000-4000-8000-000000000001',
      'historical',
      'invalid selection subject'
    )$$,
  '22023',
  null,
  'selection-from rejects a non-cultivar subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000006',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000007',
      'historical',
      'invalid selection target'
    )$$,
  '22023',
  null,
  'selection-from rejects targets outside cultivar and origin population'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000007',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000001',
      'single_source',
      'synthetic cultivar population membership'
    )$$,
  'population membership may connect a cultivar to an origin population'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000007',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      '65000000-0000-4000-8000-000000000001',
      'confirmed',
      'synthetic sample population membership'
    )$$,
  'population membership may connect a genetic sample to an origin population'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000007',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      '65000000-0000-4000-8000-000000000001',
      'single_source',
      'invalid population member'
    )$$,
  '22023',
  null,
  'population membership rejects a product subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000007',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'invalid population target'
    )$$,
  '22023',
  null,
  'population membership requires an origin-population target'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000008',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'unknown',
      'synthetic unknown parent'
    )$$,
  'unknown parent maps a cultivar without a related entity'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000008',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      null,
      'unknown',
      'invalid unknown-parent subject'
    )$$,
  '22023',
  null,
  'unknown parent rejects a non-cultivar subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000008',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'unknown',
      'invalid unknown-parent target'
    )$$,
  '22023',
  null,
  'unknown parent rejects a related canonical entity'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000009',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      '65000000-0000-4000-8000-000000000006',
      'confirmed',
      'synthetic genetic relation'
    )$$,
  'genetic relation connects two different genetic samples'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000009',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000006',
      'confirmed',
      'invalid genetic subject'
    )$$,
  '22023',
  null,
  'genetic relation explicitly rejects a cultivar subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000009',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      '65000000-0000-4000-8000-000000000004',
      'confirmed',
      'invalid genetic target'
    )$$,
  '22023',
  null,
  'genetic relation explicitly rejects a cultivar target'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000009',
      'accepted',
      '65000000-0000-4000-8000-000000000005',
      '65000000-0000-4000-8000-000000000005',
      'confirmed',
      'invalid genetic self relation'
    )$$,
  '22023',
  null,
  'genetic relation rejects the same genetic sample at both endpoints'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000010',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      '65000000-0000-4000-8000-000000000003',
      'single_source',
      'synthetic product cultivar'
    )$$,
  'product-cultivar connects product to cultivar'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000010',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'single_source',
      'invalid product subject'
    )$$,
  '22023',
  null,
  'product-cultivar rejects a non-product subject'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000010',
      'accepted',
      '65000000-0000-4000-8000-000000000007',
      '65000000-0000-4000-8000-000000000001',
      'single_source',
      'invalid cultivar target'
    )$$,
  '22023',
  null,
  'product-cultivar rejects a non-cultivar target'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000011',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000001',
      'historical',
      'synthetic cultivar historical origin'
    )$$,
  'historical origin may connect a cultivar to an origin population'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000012',
      'accepted',
      '65000000-0000-4000-8000-000000000001',
      '65000000-0000-4000-8000-000000000002',
      'historical',
      'synthetic population historical origin'
    )$$,
  'historical origin may connect an origin population to another origin population'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000011',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      '65000000-0000-4000-8000-000000000004',
      'historical',
      'invalid historical cultivar target'
    )$$,
  '22023',
  null,
  'historical origin rejects a cultivar target'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000012',
      'accepted',
      '65000000-0000-4000-8000-000000000001',
      '65000000-0000-4000-8000-000000000001',
      'historical',
      'invalid historical self relation'
    )$$,
  '22023',
  null,
  'historical origin rejects the same origin population at both endpoints'
);

select throws_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000013',
      'accepted',
      '65000000-0000-4000-8000-000000000003',
      null,
      'confirmed',
      'invalid blocked-source acceptance'
    )$$,
  '42501',
  null,
  'an assertion from a blocked source cannot be accepted'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '66000000-0000-4000-8000-000000000013',
      'rejected',
      null,
      null,
      null,
      'blocked-source rejection'
    )$$,
  'an assertion from a blocked source can still be rejected'
);

select ok(
  (
    select
      decision = 'accepted'
      and entity_id = '65000000-0000-4000-8000-000000000003'
      and related_entity_id is null
      and evidence_status = 'confirmed'
      and reviewer_name = session_user::text
      and reviewed_at is not null
      and note = 'typed entity acceptance'
    from catalog.assertion_reviews
    where assertion_id = '66000000-0000-4000-8000-000000000001'
  ),
  'the knowledge review records canonical mapping, evidence, reviewer, time, and note'
);

select is(
  (
    select payload ->> 'entityKind'
    from catalog.normalized_assertions
    where id = '66000000-0000-4000-8000-000000000001'
  ),
  'cultivar',
  'knowledge review preserves the immutable source assertion'
);

select is(
  (
    select count(*)
    from catalog.assertion_reviews
    where assertion_id = '66000000-0000-4000-8000-000000000006'
  )::bigint,
  1::bigint,
  'reviewing the same assertion again upserts only its one review row'
);

select ok(
  (
    select
      entity_id = '65000000-0000-4000-8000-000000000003'
      and related_entity_id = '65000000-0000-4000-8000-000000000001'
      and evidence_status = 'historical'
    from catalog.assertion_reviews
    where assertion_id = '66000000-0000-4000-8000-000000000006'
  ),
  'the upsert keeps the latest valid canonical mapping and evidence state'
);

select has_table(
  'api',
  'published_knowledge_snapshot',
  'the authenticated projection has one current knowledge snapshot'
);
select has_table(
  'api',
  'published_knowledge_nodes',
  'the authenticated projection has current knowledge nodes'
);
select has_table(
  'api',
  'published_knowledge_claims',
  'the authenticated projection has current knowledge claims'
);
select has_table(
  'api',
  'published_knowledge_edges',
  'the authenticated projection has current knowledge edges'
);
select has_function(
  'private',
  'publish_reviewed_knowledge_graph',
  array[]::text[],
  'the reviewer has an atomic knowledge publication capability'
);
select has_function(
  'api',
  'get_published_knowledge_graph',
  array[]::text[],
  'authenticated clients have one atomic graph read capability'
);

select ok(
  (
    select
      function.prosecdef
      and array_to_string(function.proconfig, ',') like '%search_path=""%'
    from pg_catalog.pg_proc as function
    where function.oid =
      'private.publish_reviewed_knowledge_graph()'::regprocedure
  ),
  'the graph publisher is security definer with an empty search path'
);
select ok(
  (
    select
      not function.prosecdef
      and function.provolatile = 's'
      and language.lanname = 'sql'
      and array_to_string(function.proconfig, ',') like '%search_path=""%'
    from pg_catalog.pg_proc as function
    join pg_catalog.pg_language as language
      on language.oid = function.prolang
    where function.oid =
      'api.get_published_knowledge_graph()'::regprocedure
  ),
  'the graph read capability is stable SQL security invoker with an empty search path'
);

select ok(
  has_function_privilege(
    'source_reviewer',
    'private.publish_reviewed_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'source_ingestor',
    'private.publish_reviewed_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'anon',
    'private.publish_reviewed_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.publish_reviewed_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.publish_reviewed_knowledge_graph()',
    'execute'
  ),
  'only the source reviewer can execute the graph publisher'
);

select ok(
  has_function_privilege(
    'authenticated',
    'api.get_published_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'anon',
    'api.get_published_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'api.get_published_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'source_ingestor',
    'api.get_published_knowledge_graph()',
    'execute'
  )
  and not has_function_privilege(
    'source_reviewer',
    'api.get_published_knowledge_graph()',
    'execute'
  ),
  'only authenticated clients can execute the atomic graph read'
);

select ok(
  (
    select count(*) = 4 and bool_and(relation.relrowsecurity)
    from pg_catalog.pg_class as relation
    join pg_catalog.pg_namespace as namespace
      on namespace.oid = relation.relnamespace
    where namespace.nspname = 'api'
      and relation.relname in (
        'published_knowledge_snapshot',
        'published_knowledge_nodes',
        'published_knowledge_claims',
        'published_knowledge_edges'
      )
  ),
  'all four graph projection tables have row-level security enabled'
);

select ok(
  not exists (
    select 1
    from unnest(
      array[
        'api.published_knowledge_snapshot',
        'api.published_knowledge_nodes',
        'api.published_knowledge_claims',
        'api.published_knowledge_edges'
      ]
    ) as relation_name(name)
    cross join unnest(
      array[
        'INSERT',
        'UPDATE',
        'DELETE',
        'TRUNCATE',
        'REFERENCES',
        'TRIGGER'
      ]
    ) as privilege_name(name)
    where has_table_privilege(
      'authenticated',
      relation_name.name,
      privilege_name.name
    )
  )
  and not exists (
    select 1
    from unnest(
      array['anon', 'service_role', 'source_ingestor', 'source_reviewer']
    ) as role_name(name)
    cross join unnest(
      array[
        'api.published_knowledge_snapshot',
        'api.published_knowledge_nodes',
        'api.published_knowledge_claims',
        'api.published_knowledge_edges'
      ]
    ) as relation_name(name)
    cross join unnest(
      array[
        'SELECT',
        'INSERT',
        'UPDATE',
        'DELETE',
        'TRUNCATE',
        'REFERENCES',
        'TRIGGER'
      ]
    ) as privilege_name(name)
    where has_table_privilege(
      role_name.name,
      relation_name.name,
      privilege_name.name
    )
  )
  and (
    select bool_and(
      has_table_privilege(
        'authenticated',
        relation_name.name,
        'SELECT'
      )
    )
    from unnest(
      array[
        'api.published_knowledge_snapshot',
        'api.published_knowledge_nodes',
        'api.published_knowledge_claims',
        'api.published_knowledge_edges'
      ]
    ) as relation_name(name)
  ),
  'the graph projection grants authenticated read-only access and no broad-role access'
);

select ok(
  not has_schema_privilege('authenticated', 'catalog', 'usage')
  and not has_schema_privilege('authenticated', 'private', 'usage'),
  'authenticated graph readers still cannot resolve catalog or private'
);

select is(
  api.get_published_knowledge_graph(),
  null::jsonb,
  'the atomic graph read is empty-safe before the first publication'
);

set local role authenticated;
select api.get_published_knowledge_graph() is null
  as graph_before_publication_is_null
\gset
reset role;

select ok(
  :'graph_before_publication_is_null'::boolean,
  'an authenticated client receives null before the first publication'
);

insert into catalog.sources(
  id,
  display_name,
  owner_name,
  access_method,
  permitted_frequency,
  license_status,
  license_reference,
  raw_storage_allowed,
  attribution_rules,
  image_rights_status,
  confidence_class,
  responsible_reviewer,
  status
) values
  (
    'synthetic-publication-source',
    'Synthetic publication source',
    'Synthetic owner',
    'synthetic fixture',
    'manual tests only',
    'approved',
    'https://example.invalid/publication-license',
    false,
    'Synthetic publication attribution',
    'not included',
    'supporting',
    'publication-test-reviewer',
    'active'
  ),
  (
    'synthetic-publication-blocked-source',
    'Synthetic publication blocked source',
    'Synthetic owner',
    'synthetic fixture',
    'manual tests only',
    'approved',
    'https://example.invalid/publication-blocked-license',
    false,
    'Synthetic blocked publication attribution',
    'not included',
    'supporting',
    'publication-test-reviewer',
    'active'
  ),
  (
    'synthetic-publication-forbidden-source',
    'Synthetic publication forbidden source',
    'Synthetic owner',
    'synthetic fixture',
    'manual tests only',
    'forbidden',
    'https://example.invalid/publication-forbidden-license',
    false,
    'Synthetic forbidden publication attribution',
    'not included',
    'supporting',
    'publication-test-reviewer',
    'active'
  );

insert into catalog.import_runs(
  id,
  source_id,
  started_at,
  completed_at,
  cursor,
  adapter_errors,
  contract_version
) values
  (
    '67000000-0000-4000-8000-000000000001',
    'synthetic-publication-source',
    '2026-07-30T14:59:00Z',
    '2026-07-30T15:00:00Z',
    null,
    '[]',
    2
  ),
  (
    '67000000-0000-4000-8000-000000000002',
    'synthetic-publication-blocked-source',
    '2026-07-30T14:59:00Z',
    '2026-07-30T15:00:00Z',
    null,
    '[]',
    2
  ),
  (
    '67000000-0000-4000-8000-000000000003',
    'synthetic-publication-forbidden-source',
    '2026-07-30T14:59:00Z',
    '2026-07-30T15:00:00Z',
    null,
    '[]',
    2
  );

insert into catalog.source_records(
  id,
  source_id,
  import_run_id,
  external_record_key,
  upstream_state,
  retrieved_at,
  source_version,
  evidence_kind,
  raw_media_type,
  raw_payload,
  content_hash,
  retrieval_reference,
  valid_from,
  valid_to,
  license_status_snapshot,
  raw_storage_allowed_snapshot,
  attribution_snapshot
) values
  (
    '67100000-0000-4000-8000-000000000001',
    'synthetic-publication-source',
    '67000000-0000-4000-8000-000000000001',
    'synthetic-publication-safe-record',
    'present',
    '2026-07-30T15:00:00Z',
    'publication-v1',
    'checksum',
    null,
    null,
    'd111111111111111111111111111111111111111111111111111111111111111',
    'https://example.invalid/publication-safe-record',
    null,
    null,
    'approved',
    false,
    'Synthetic publication attribution'
  ),
  (
    '67100000-0000-4000-8000-000000000002',
    'synthetic-publication-source',
    '67000000-0000-4000-8000-000000000001',
    'synthetic-publication-unsafe-citation-record',
    'present',
    '2026-07-30T15:01:00Z',
    'publication-v2',
    'checksum',
    null,
    null,
    'd222222222222222222222222222222222222222222222222222222222222222',
    'http://example.invalid/publication-unsafe-record',
    null,
    null,
    'approved',
    false,
    'Synthetic unsafe-citation attribution'
  ),
  (
    '67100000-0000-4000-8000-000000000003',
    'synthetic-publication-source',
    '67000000-0000-4000-8000-000000000001',
    'synthetic-publication-deleted-record',
    'deleted',
    '2026-07-30T15:02:00Z',
    'publication-deleted',
    'checksum',
    null,
    null,
    'd333333333333333333333333333333333333333333333333333333333333333',
    'https://example.invalid/publication-deleted-record',
    null,
    null,
    'approved',
    false,
    'Synthetic deleted publication attribution'
  ),
  (
    '67100000-0000-4000-8000-000000000004',
    'synthetic-publication-blocked-source',
    '67000000-0000-4000-8000-000000000002',
    'synthetic-publication-blocked-record',
    'present',
    '2026-07-30T15:03:00Z',
    'publication-blocked',
    'checksum',
    null,
    null,
    'd444444444444444444444444444444444444444444444444444444444444444',
    'https://example.invalid/publication-blocked-record',
    null,
    null,
    'approved',
    false,
    'Synthetic blocked publication attribution'
  ),
  (
    '67100000-0000-4000-8000-000000000005',
    'synthetic-publication-forbidden-source',
    '67000000-0000-4000-8000-000000000003',
    'synthetic-publication-forbidden-record',
    'present',
    '2026-07-30T15:04:00Z',
    'publication-forbidden',
    'checksum',
    null,
    null,
    'd555555555555555555555555555555555555555555555555555555555555555',
    'https://example.invalid/publication-forbidden-record',
    null,
    null,
    'forbidden',
    false,
    'Synthetic forbidden publication attribution'
  );

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '67200000-0000-4000-8000-000000000001',
    'origin_population',
    'Unpublished synthetic origin',
    false
  ),
  (
    '67200000-0000-4000-8000-000000000002',
    'cultivar',
    'Unpublished synthetic child',
    false
  ),
  (
    '67200000-0000-4000-8000-000000000003',
    'genetic_sample',
    'Unpublished synthetic sample one',
    false
  ),
  (
    '67200000-0000-4000-8000-000000000004',
    'genetic_sample',
    'Unpublished synthetic sample two',
    false
  ),
  (
    '67200000-0000-4000-8000-000000000005',
    'product',
    'Unpublished synthetic product',
    false
  ),
  (
    '67200000-0000-4000-8000-000000000006',
    'cultivar',
    'Unpublished synthetic parent',
    false
  );

insert into catalog.normalized_assertions(
  id,
  source_record_id,
  assertion_index,
  assertion_kind,
  subject_external_key,
  payload,
  valid_from,
  valid_to
) values
  (
    '67300000-0000-4000-8000-000000000001',
    '67100000-0000-4000-8000-000000000001',
    0,
    'entity_kind',
    'synthetic-publication-origin',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.origin.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-origin","entityKind":"origin_population"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000002',
    '67100000-0000-4000-8000-000000000001',
    1,
    'name',
    'synthetic-publication-origin',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.origin.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-origin","name":"Synthetic published origin","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000003',
    '67100000-0000-4000-8000-000000000001',
    2,
    'entity_kind',
    'synthetic-publication-child',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.child.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-child","entityKind":"cultivar"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000004',
    '67100000-0000-4000-8000-000000000001',
    3,
    'name',
    'synthetic-publication-child',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.child.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Synthetic published child","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000005',
    '67100000-0000-4000-8000-000000000001',
    4,
    'entity_kind',
    'synthetic-publication-parent',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.parent.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-parent","entityKind":"cultivar"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000006',
    '67100000-0000-4000-8000-000000000001',
    5,
    'name',
    'synthetic-publication-parent',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.parent.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-parent","name":"Synthetic published parent","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000007',
    '67100000-0000-4000-8000-000000000001',
    6,
    'entity_kind',
    'synthetic-publication-sample-one',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.sampleOne.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-sample-one","entityKind":"genetic_sample"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000008',
    '67100000-0000-4000-8000-000000000001',
    7,
    'name',
    'synthetic-publication-sample-one',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.sampleOne.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-sample-one","name":"Synthetic published sample one","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000009',
    '67100000-0000-4000-8000-000000000001',
    8,
    'entity_kind',
    'synthetic-publication-sample-two',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.sampleTwo.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-sample-two","entityKind":"genetic_sample"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000010',
    '67100000-0000-4000-8000-000000000001',
    9,
    'name',
    'synthetic-publication-sample-two',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.sampleTwo.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-sample-two","name":"Synthetic published sample two","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000011',
    '67100000-0000-4000-8000-000000000001',
    10,
    'entity_kind',
    'synthetic-publication-product',
    '{"kind":"entity_kind","trace":{"sourceLocator":"$.nodes.product.kind","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-product","entityKind":"product"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000012',
    '67100000-0000-4000-8000-000000000001',
    11,
    'name',
    'synthetic-publication-product',
    '{"kind":"name","trace":{"sourceLocator":"$.nodes.product.name","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-product","name":"Synthetic published product","language":"en"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000013',
    '67100000-0000-4000-8000-000000000002',
    0,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.claims.child.alias","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-child","name":"Synthetic child alias","language":"en","aliasType":"market","market":"DE"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000014',
    '67100000-0000-4000-8000-000000000001',
    12,
    'traditional_classification',
    'synthetic-publication-child',
    '{"kind":"traditional_classification","trace":{"sourceLocator":"$.claims.child.classification","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","classification":"hybrid"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000015',
    '67100000-0000-4000-8000-000000000001',
    13,
    'origin_region',
    'synthetic-publication-origin',
    '{"kind":"origin_region","trace":{"sourceLocator":"$.claims.origin.region","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-origin","regionName":"Synthetic Region","regionCode":"ZZ-SYN"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000016',
    '67100000-0000-4000-8000-000000000001',
    14,
    'era',
    'synthetic-publication-child',
    '{"kind":"era","trace":{"sourceLocator":"$.claims.child.era","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","startYear":1990,"endYear":2000,"label":"Synthetic era"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000017',
    '67100000-0000-4000-8000-000000000001',
    15,
    'sample_reference',
    'synthetic-publication-sample-one',
    '{"kind":"sample_reference","trace":{"sourceLocator":"$.claims.sample.reference","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-sample-one","sampleIdentifier":"SYN-PUB-SAMPLE-1","datasetName":"Synthetic publication dataset","datasetVersion":"v1","submitter":"Synthetic submitter","laboratory":"Synthetic laboratory","sampledAt":"2026-07-30T14:00:00Z"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000018',
    '67100000-0000-4000-8000-000000000001',
    16,
    'product_market',
    'synthetic-publication-product',
    '{"kind":"product_market","trace":{"sourceLocator":"$.claims.product.market","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-product","countryCode":"DE","medical":true}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000019',
    '67100000-0000-4000-8000-000000000001',
    17,
    'measurement',
    'synthetic-publication-product',
    '{"kind":"measurement","trace":{"sourceLocator":"$.claims.product.measurement","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-product","analyte":"thc","value":19.5,"unit":"percent","productForm":"flower","batchIdentifier":"SYN-PUB-BATCH","measuredAt":"2026-07-30T14:30:00Z"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000020',
    '67100000-0000-4000-8000-000000000001',
    18,
    'lineage',
    'synthetic-publication-child',
    '{"kind":"lineage","trace":{"sourceLocator":"$.edges.lineage.parent","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","relatedExternalKey":"synthetic-publication-parent","relationship":"reported_parent","position":1}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000021',
    '67100000-0000-4000-8000-000000000001',
    19,
    'lineage',
    'synthetic-publication-child',
    '{"kind":"lineage","trace":{"sourceLocator":"$.edges.lineage.unknown","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","relatedExternalKey":null,"relationship":"unknown_parent","position":2}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000022',
    '67100000-0000-4000-8000-000000000001',
    20,
    'genetic_relation',
    'synthetic-publication-sample-one',
    '{"kind":"genetic_relation","trace":{"sourceLocator":"$.edges.genetics.similarity","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-sample-one","relatedExternalKey":"synthetic-publication-sample-two","relationship":"genetic_similarity","method":"Synthetic method","datasetName":"Synthetic publication dataset","datasetVersion":"v1","metricName":"similarity","value":0.875,"unit":"ratio"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000023',
    '67100000-0000-4000-8000-000000000001',
    21,
    'product_cultivar',
    'synthetic-publication-product',
    '{"kind":"product_cultivar","trace":{"sourceLocator":"$.edges.product.cultivar","extractionMethod":"structured"},"subjectExternalKey":"synthetic-publication-product","cultivarExternalKey":"synthetic-publication-child","productForm":"flower"}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000031',
    '67100000-0000-4000-8000-000000000001',
    22,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.unreviewed","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Unreviewed synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000032',
    '67100000-0000-4000-8000-000000000001',
    23,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.rejected","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Rejected synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000033',
    '67100000-0000-4000-8000-000000000005',
    0,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.forbidden","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Forbidden synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000034',
    '67100000-0000-4000-8000-000000000003',
    0,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.deleted","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Deleted synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000035',
    '67100000-0000-4000-8000-000000000001',
    24,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.expired","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Expired synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    '2026-07-29T00:00:00Z'
  ),
  (
    '67300000-0000-4000-8000-000000000036',
    '67100000-0000-4000-8000-000000000004',
    0,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.blocked","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Blocked synthetic alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  ),
  (
    '67300000-0000-4000-8000-000000000037',
    '67100000-0000-4000-8000-000000000001',
    26,
    'alias',
    'synthetic-publication-child',
    '{"kind":"alias","trace":{"sourceLocator":"$.excluded.legacyReviewerBypass","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Legacy reviewer bypass alias","language":"en","aliasType":"other","market":null}',
    null,
    null
  );

select private.review_knowledge_assertion(
  review.assertion_id,
  review.decision,
  review.entity_id,
  review.related_entity_id,
  review.evidence_status,
  'synthetic publication fixture'
)
from (
  values
    ('67300000-0000-4000-8000-000000000001'::uuid, 'accepted', '67200000-0000-4000-8000-000000000001'::uuid, null::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000002'::uuid, 'accepted', '67200000-0000-4000-8000-000000000001'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000003'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'disputed'),
    ('67300000-0000-4000-8000-000000000004'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'historical'),
    ('67300000-0000-4000-8000-000000000005'::uuid, 'accepted', '67200000-0000-4000-8000-000000000006'::uuid, null::uuid, 'unknown'),
    ('67300000-0000-4000-8000-000000000006'::uuid, 'accepted', '67200000-0000-4000-8000-000000000006'::uuid, null::uuid, 'retracted'),
    ('67300000-0000-4000-8000-000000000007'::uuid, 'accepted', '67200000-0000-4000-8000-000000000003'::uuid, null::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000008'::uuid, 'accepted', '67200000-0000-4000-8000-000000000003'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000009'::uuid, 'accepted', '67200000-0000-4000-8000-000000000004'::uuid, null::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000010'::uuid, 'accepted', '67200000-0000-4000-8000-000000000004'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000011'::uuid, 'accepted', '67200000-0000-4000-8000-000000000005'::uuid, null::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000012'::uuid, 'accepted', '67200000-0000-4000-8000-000000000005'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000013'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'disputed'),
    ('67300000-0000-4000-8000-000000000014'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'historical'),
    ('67300000-0000-4000-8000-000000000015'::uuid, 'accepted', '67200000-0000-4000-8000-000000000001'::uuid, null::uuid, 'unknown'),
    ('67300000-0000-4000-8000-000000000016'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'retracted'),
    ('67300000-0000-4000-8000-000000000017'::uuid, 'accepted', '67200000-0000-4000-8000-000000000003'::uuid, null::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000018'::uuid, 'accepted', '67200000-0000-4000-8000-000000000005'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000019'::uuid, 'accepted', '67200000-0000-4000-8000-000000000005'::uuid, null::uuid, 'disputed'),
    ('67300000-0000-4000-8000-000000000020'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, '67200000-0000-4000-8000-000000000006'::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000021'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'unknown'),
    ('67300000-0000-4000-8000-000000000022'::uuid, 'accepted', '67200000-0000-4000-8000-000000000003'::uuid, '67200000-0000-4000-8000-000000000004'::uuid, 'confirmed'),
    ('67300000-0000-4000-8000-000000000023'::uuid, 'accepted', '67200000-0000-4000-8000-000000000005'::uuid, '67200000-0000-4000-8000-000000000002'::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000032'::uuid, 'rejected', null::uuid, null::uuid, null::text),
    ('67300000-0000-4000-8000-000000000033'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000034'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000035'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source'),
    ('67300000-0000-4000-8000-000000000036'::uuid, 'accepted', '67200000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source')
) as review(
  assertion_id,
  decision,
  entity_id,
  related_entity_id,
  evidence_status
);

savepoint version_two_legacy_acceptance;
select throws_ok(
  $$select private.review_source_assertion(
      '67300000-0000-4000-8000-000000000037',
      'accepted',
      '67200000-0000-4000-8000-000000000002',
      null,
      'invalid version-2 legacy acceptance'
    )$$,
  '22023',
  null,
  'the legacy reviewer cannot accept a version-2 graph assertion'
);
rollback to savepoint version_two_legacy_acceptance;

savepoint version_two_legacy_rejection;
select throws_ok(
  $$select private.review_source_assertion(
      '67300000-0000-4000-8000-000000000037',
      'rejected',
      null,
      null,
      'invalid version-2 legacy rejection'
    )$$,
  '22023',
  null,
  'the legacy reviewer cannot reject a version-2 graph assertion'
);
rollback to savepoint version_two_legacy_rejection;

select is(
  (
    select count(*)
    from catalog.assertion_reviews
    where assertion_id = '67300000-0000-4000-8000-000000000037'
  )::bigint,
  0::bigint,
  'failed legacy review attempts leave the version-2 graph assertion unreviewed'
);

update catalog.sources
set status = 'blocked'
where id in (
  'synthetic-graph-review-source',
  'synthetic-publication-blocked-source'
);

select is(
  (select count(*) from api.published_knowledge_nodes)::bigint,
  0::bigint,
  'import and review alone publish zero graph nodes'
);
select is(
  (select count(*) from api.published_knowledge_claims)::bigint,
  0::bigint,
  'import and review alone publish zero graph claims'
);
select is(
  (select count(*) from api.published_knowledge_edges)::bigint,
  0::bigint,
  'import and review alone publish zero graph edges'
);

create temporary table task5_publication_state (
  first_snapshot_id uuid,
  first_node_count bigint,
  first_claim_count bigint,
  first_edge_count bigint,
  inventory_reference_count bigint
) on commit drop;

set local role source_reviewer;
select private.publish_reviewed_knowledge_graph() as first_snapshot_id
\gset
reset role;

insert into task5_publication_state(
  first_snapshot_id,
  first_node_count,
  first_claim_count,
  first_edge_count,
  inventory_reference_count
)
select
  :'first_snapshot_id'::uuid,
  (select count(*) from api.published_knowledge_nodes),
  (select count(*) from api.published_knowledge_claims),
  (select count(*) from api.published_knowledge_edges),
  (select count(*) from api.catalog_references);

select ok(
  (
    select
      snapshot.snapshot_id = :'first_snapshot_id'::uuid
      and snapshot.published_at is not null
    from api.published_knowledge_snapshot as snapshot
    where snapshot.singleton
  ),
  'the first publication atomically exposes one current snapshot'
);
select is(
  (select count(*) from api.published_knowledge_nodes)::bigint,
  6::bigint,
  'reviewed entity-kind and name assertions create six canonical nodes'
);
select is(
  (
    select count(distinct kind)
    from api.published_knowledge_nodes
  )::bigint,
  4::bigint,
  'the public snapshot contains all four node kinds'
);
select ok(
  (
    select bool_and(
      case id
        when '67200000-0000-4000-8000-000000000001' then
          kind = 'origin_population'
          and canonical_name = 'Synthetic published origin'
        when '67200000-0000-4000-8000-000000000002' then
          kind = 'cultivar'
          and canonical_name = 'Synthetic published child'
        when '67200000-0000-4000-8000-000000000003' then
          kind = 'genetic_sample'
          and canonical_name = 'Synthetic published sample one'
        when '67200000-0000-4000-8000-000000000004' then
          kind = 'genetic_sample'
          and canonical_name = 'Synthetic published sample two'
        when '67200000-0000-4000-8000-000000000005' then
          kind = 'product'
          and canonical_name = 'Synthetic published product'
        when '67200000-0000-4000-8000-000000000006' then
          kind = 'cultivar'
          and canonical_name = 'Synthetic published parent'
        else false
      end
    )
    from api.published_knowledge_nodes
  ),
  'public nodes use only reviewed canonical UUID mappings and reviewed names'
);

select is(
  (select count(*) from api.published_knowledge_claims)::bigint,
  19::bigint,
  'the first snapshot publishes every eligible closed claim'
);
select is(
  (
    select count(distinct evidence_status)
    from api.published_knowledge_claims
  )::bigint,
  6::bigint,
  'all six evidence states survive unchanged in public claims'
);
select set_eq(
  $$
    select distinct evidence_status
    from api.published_knowledge_claims
  $$,
  $$
    values
      ('confirmed'::text),
      ('single_source'::text),
      ('disputed'::text),
      ('historical'::text),
      ('unknown'::text),
      ('retracted'::text)
  $$,
  'the public claim status set is exactly the six reviewed evidence states'
);

select ok(
  not exists (
    select 1
    from api.published_knowledge_claims as claim
    where not private.jsonb_has_exact_keys(
      claim.evidence,
      array[
        'sourceName',
        'sourceVersion',
        'retrievedAt',
        'citationUrl',
        'sourceLocator',
        'extractionMethod',
        'attribution'
      ]
    )
    or claim.evidence ->> 'sourceName' is null
    or claim.evidence ->> 'retrievedAt' is null
    or claim.evidence ->> 'sourceLocator' is null
    or claim.evidence ->> 'extractionMethod'
      not in ('structured', 'manual', 'ai_assisted')
    or claim.evidence ->> 'attribution' is null
  ),
  'every public claim carries the complete sanitized evidence object'
);
select ok(
  not exists (
    select 1
    from api.published_knowledge_edges as edge
    where not private.jsonb_has_exact_keys(
      edge.evidence,
      array[
        'sourceName',
        'sourceVersion',
        'retrievedAt',
        'citationUrl',
        'sourceLocator',
        'extractionMethod',
        'attribution'
      ]
    )
    or edge.evidence ->> 'sourceName' is null
    or edge.evidence ->> 'retrievedAt' is null
    or edge.evidence ->> 'sourceLocator' is null
    or edge.evidence ->> 'extractionMethod'
      not in ('structured', 'manual', 'ai_assisted')
    or edge.evidence ->> 'attribution' is null
  ),
  'every public edge carries the complete sanitized evidence object'
);
select ok(
  (
    select
      evidence -> 'citationUrl' = 'null'::jsonb
      and evidence ->> 'sourceLocator' = '$.claims.child.alias'
      and evidence ->> 'attribution'
        = 'Synthetic unsafe-citation attribution'
      and evidence ->> 'sourceName' = 'Synthetic publication source'
      and evidence ->> 'sourceVersion' = 'publication-v2'
      and evidence ->> 'retrievedAt' = '2026-07-30T15:01:00+00:00'
    from api.published_knowledge_claims
    where assertion_id = '67300000-0000-4000-8000-000000000013'
  ),
  'an unsafe non-HTTPS citation becomes null without losing locator or attribution'
);
select ok(
  (
    select
      evidence ->> 'citationUrl'
        = 'https://example.invalid/publication-safe-record'
      and evidence ->> 'sourceLocator' = '$.claims.product.measurement'
      and evidence ->> 'extractionMethod' = 'structured'
    from api.published_knowledge_claims
    where assertion_id = '67300000-0000-4000-8000-000000000019'
  ),
  'a safe HTTPS citation and exact extraction trace survive publication'
);

select ok(
  not exists (
    select 1
    from api.published_knowledge_claims as claim
    where not (
      case claim.claim_kind
        when 'entity_kind' then private.jsonb_has_exact_keys(
          claim.value,
          array['entityKind']
        )
        when 'name' then private.jsonb_has_exact_keys(
          claim.value,
          array['name', 'language']
        )
        when 'alias' then private.jsonb_has_exact_keys(
          claim.value,
          array['name', 'language', 'aliasType', 'market']
        )
        when 'traditional_classification' then
          private.jsonb_has_exact_keys(
            claim.value,
            array['classification']
          )
        when 'origin_region' then private.jsonb_has_exact_keys(
          claim.value,
          array['regionName', 'regionCode']
        )
        when 'era' then private.jsonb_has_exact_keys(
          claim.value,
          array['startYear', 'endYear', 'label']
        )
        when 'sample_reference' then private.jsonb_has_exact_keys(
          claim.value,
          array[
            'sampleIdentifier',
            'datasetName',
            'datasetVersion',
            'submitter',
            'laboratory',
            'sampledAt'
          ]
        )
        when 'product_market' then private.jsonb_has_exact_keys(
          claim.value,
          array['countryCode', 'medical']
        )
        when 'measurement' then private.jsonb_has_exact_keys(
          claim.value,
          array[
            'analyte',
            'value',
            'unit',
            'productForm',
            'batchIdentifier',
            'measuredAt'
          ]
        )
        else false
      end
    )
  ),
  'public claim values are closed domain objects without source identity or trace fields'
);

select is(
  (select count(*) from api.published_knowledge_edges)::bigint,
  4::bigint,
  'the first snapshot publishes all four eligible synthetic relations'
);
select ok(
  (
    select
      count(*) filter (where layer = 'documented_lineage') = 2
      and count(*) filter (where layer = 'genetic_similarity') = 1
      and count(*) filter (where layer = 'product_mapping') = 1
    from api.published_knowledge_edges
  ),
  'lineage, genetic similarity, and product mapping stay in separate layers'
);
select ok(
  (
    select
      to_node_id is null
      and layer = 'documented_lineage'
      and details = '{}'::jsonb
    from api.published_knowledge_edges
    where assertion_id = '67300000-0000-4000-8000-000000000021'
      and relationship = 'unknown_parent'
  ),
  'an unknown parent remains a documented-lineage edge without a target'
);
select ok(
  (
    select
      layer = 'genetic_similarity'
      and from_node_id = '67200000-0000-4000-8000-000000000003'
      and to_node_id = '67200000-0000-4000-8000-000000000004'
      and position is null
      and private.jsonb_has_exact_keys(
        details,
        array[
          'method',
          'datasetName',
          'datasetVersion',
          'metricName',
          'value',
          'unit'
        ]
      )
    from api.published_knowledge_edges
    where assertion_id = '67300000-0000-4000-8000-000000000022'
  ),
  'genetic evidence stays between canonical sample UUIDs with genetic-only details'
);
select ok(
  (
    select
      layer = 'product_mapping'
      and from_node_id = '67200000-0000-4000-8000-000000000005'
      and to_node_id = '67200000-0000-4000-8000-000000000002'
      and details = '{"productForm":"flower"}'::jsonb
    from api.published_knowledge_edges
    where assertion_id = '67300000-0000-4000-8000-000000000023'
  ),
  'product mapping stays product-to-cultivar with only its product form'
);

select is(
  (
    select count(*)
    from api.published_knowledge_claims
    where assertion_id in (
      '67300000-0000-4000-8000-000000000031',
      '67300000-0000-4000-8000-000000000032',
      '67300000-0000-4000-8000-000000000033',
      '67300000-0000-4000-8000-000000000034',
      '67300000-0000-4000-8000-000000000035',
      '67300000-0000-4000-8000-000000000036',
      '67300000-0000-4000-8000-000000000037'
    )
  )::bigint,
  0::bigint,
  'unreviewed, rejected, forbidden, deleted, expired, blocked, and legacy-bypass assertions are absent'
);

select lives_ok(
  $$select private.review_knowledge_assertion(
      '67300000-0000-4000-8000-000000000037',
      'rejected',
      null,
      null,
      null,
      'valid graph-aware rejection'
    )$$,
  'the graph-aware reviewer still handles the version-2 assertion'
);
select ok(
  (
    select
      decision = 'rejected'
      and entity_id is null
      and related_entity_id is null
      and evidence_status is null
    from catalog.assertion_reviews
    where assertion_id = '67300000-0000-4000-8000-000000000037'
  ),
  'the graph-aware review records the version-2 decision without publication'
);

select ok(
  (
    select
      snapshot.assertion_count = 23
      and snapshot.previous_snapshot_id is null
      and snapshot.published_by <> ''
    from catalog.knowledge_publication_snapshots as snapshot
    where snapshot.id = :'first_snapshot_id'::uuid
  )
  and (
    select snapshot_id = :'first_snapshot_id'::uuid
    from catalog.knowledge_current_snapshot
    where singleton
  )
  and (
    select count(*) = 6
    from catalog.knowledge_snapshot_nodes
    where snapshot_id = :'first_snapshot_id'::uuid
  )
  and (
    select count(*) = 19
    from catalog.knowledge_snapshot_claims
    where snapshot_id = :'first_snapshot_id'::uuid
  )
  and (
    select count(*) = 4
    from catalog.knowledge_snapshot_edges
    where snapshot_id = :'first_snapshot_id'::uuid
  ),
  'the first private snapshot is complete and the current pointer moves only after construction'
);

savepoint malformed_lineage_endpoint;
update catalog.assertion_reviews
set related_entity_id = null
where assertion_id = '67300000-0000-4000-8000-000000000020';

select throws_ok(
  $$select private.publish_reviewed_knowledge_graph()$$,
  '22023',
  null,
  'publication rejects a documented lineage relation without its reviewed endpoint'
);
rollback to savepoint malformed_lineage_endpoint;

select ok(
  private.jsonb_has_exact_keys(
    api.get_published_knowledge_graph(),
    array['snapshotId', 'publishedAt', 'nodes', 'claims', 'edges']
  )
  and jsonb_typeof(api.get_published_knowledge_graph() -> 'nodes') = 'array'
  and jsonb_typeof(api.get_published_knowledge_graph() -> 'claims') = 'array'
  and jsonb_typeof(api.get_published_knowledge_graph() -> 'edges') = 'array',
  'the graph RPC returns the exact atomic top-level shape'
);
select is(
  api.get_published_knowledge_graph() #>> '{snapshotId}',
  :'first_snapshot_id',
  'the graph RPC identifies the same current snapshot as the public projection'
);
select is(
  api.get_published_knowledge_graph() #>> '{nodes,0,id}',
  '67200000-0000-4000-8000-000000000001',
  'the graph RPC orders nodes deterministically by canonical UUID'
);
select is(
  api.get_published_knowledge_graph() #>> '{claims,0,assertionId}',
  '67300000-0000-4000-8000-000000000001',
  'the graph RPC orders claims deterministically by assertion UUID'
);
select is(
  api.get_published_knowledge_graph() #>> '{edges,0,assertionId}',
  '67300000-0000-4000-8000-000000000020',
  'the graph RPC orders edges deterministically by assertion UUID'
);
select is(
  jsonb_array_length(api.get_published_knowledge_graph() -> 'nodes'),
  6,
  'the graph RPC returns every node from one snapshot'
);
select is(
  jsonb_array_length(api.get_published_knowledge_graph() -> 'claims'),
  19,
  'the graph RPC returns every claim from one snapshot'
);
select is(
  jsonb_array_length(api.get_published_knowledge_graph() -> 'edges'),
  4,
  'the graph RPC returns every edge from one snapshot'
);

set local role authenticated;
select api.get_published_knowledge_graph() as authenticated_graph
\gset
reset role;

select is(
  :'authenticated_graph'::jsonb,
  api.get_published_knowledge_graph(),
  'authenticated readers receive the complete atomic graph'
);

insert into catalog.normalized_assertions(
  id,
  source_record_id,
  assertion_index,
  assertion_kind,
  subject_external_key,
  payload
) values (
  '67300000-0000-4000-8000-000000000040',
  '67100000-0000-4000-8000-000000000001',
  25,
  'name',
  'synthetic-publication-child',
  '{"kind":"name","trace":{"sourceLocator":"$.malformed.duplicateName","extractionMethod":"manual"},"subjectExternalKey":"synthetic-publication-child","name":"Synthetic conflicting canonical name","language":"en"}'
);

select private.review_knowledge_assertion(
  '67300000-0000-4000-8000-000000000040',
  'accepted',
  '67200000-0000-4000-8000-000000000002',
  null,
  'disputed',
  'synthetic malformed duplicate canonical name'
);

select throws_ok(
  $$select private.publish_reviewed_knowledge_graph()$$,
  '22023',
  null,
  'malformed graph data aborts publication'
);
select is(
  (select count(*) from catalog.knowledge_publication_snapshots)::bigint,
  (
    select snapshot_count + 1
    from task8_seed_snapshot_baseline
  ),
  'a malformed publication does not leave private snapshot metadata behind'
);
select is(
  (
    select snapshot_id
    from catalog.knowledge_current_snapshot
    where singleton
  ),
  :'first_snapshot_id'::uuid,
  'a malformed publication leaves the private current pointer unchanged'
);
select is(
  (
    select snapshot_id
    from api.published_knowledge_snapshot
    where singleton
  ),
  :'first_snapshot_id'::uuid,
  'a malformed publication leaves the public snapshot unchanged'
);
select ok(
  (
    select
      first_node_count = (select count(*) from api.published_knowledge_nodes)
      and first_claim_count = (
        select count(*) from api.published_knowledge_claims
      )
      and first_edge_count = (
        select count(*) from api.published_knowledge_edges
      )
    from task5_publication_state
  ),
  'a malformed publication leaves every public graph row count unchanged'
);

select private.review_knowledge_assertion(
  '67300000-0000-4000-8000-000000000040',
  'rejected',
  null,
  null,
  null,
  'synthetic malformed duplicate rejected'
);

set local role source_reviewer;
select private.publish_reviewed_knowledge_graph() as second_snapshot_id
\gset
reset role;

select isnt(
  :'second_snapshot_id'::uuid,
  :'first_snapshot_id'::uuid,
  'a second successful publication creates a new snapshot UUID'
);
select is(
  (select count(*) from catalog.knowledge_publication_snapshots)::bigint,
  (
    select snapshot_count + 2
    from task8_seed_snapshot_baseline
  ),
  'a second successful publication preserves both immutable private snapshots'
);
select ok(
  (
    select
      previous_snapshot_id = :'first_snapshot_id'::uuid
      and assertion_count = 23
    from catalog.knowledge_publication_snapshots
    where id = :'second_snapshot_id'::uuid
  ),
  'the second snapshot links to the preceding immutable snapshot'
);
select ok(
  (
    select count(*) = 6
    from catalog.knowledge_snapshot_nodes
    where snapshot_id = :'first_snapshot_id'::uuid
  )
  and (
    select count(*) = 19
    from catalog.knowledge_snapshot_claims
    where snapshot_id = :'first_snapshot_id'::uuid
  )
  and (
    select count(*) = 4
    from catalog.knowledge_snapshot_edges
    where snapshot_id = :'first_snapshot_id'::uuid
  ),
  'the first private snapshot content remains immutable after republishing'
);
select ok(
  (
    select snapshot_id = :'second_snapshot_id'::uuid
    from api.published_knowledge_snapshot
    where singleton
  )
  and not exists (
    select 1
    from api.published_knowledge_nodes
    where snapshot_id <> :'second_snapshot_id'::uuid
  )
  and not exists (
    select 1
    from api.published_knowledge_claims
    where snapshot_id <> :'second_snapshot_id'::uuid
  )
  and not exists (
    select 1
    from api.published_knowledge_edges
    where snapshot_id <> :'second_snapshot_id'::uuid
  ),
  'the public projection atomically replaces every row with one new snapshot'
);
select is(
  api.get_published_knowledge_graph() #>> '{snapshotId}',
  :'second_snapshot_id',
  'the atomic RPC moves to the second successful snapshot'
);
select is(
  (select count(*) from api.catalog_references)::bigint,
  (
    select inventory_reference_count
    from task5_publication_state
  ),
  'knowledge publication preserves the existing inventory catalog projection'
);

create temporary table task8_previous_graph_state as
select
  snapshot_id,
  (select count(*) from api.published_knowledge_nodes) as node_count,
  (select count(*) from api.published_knowledge_claims) as claim_count,
  (select count(*) from api.published_knowledge_edges) as edge_count
from api.published_knowledge_snapshot
where singleton;

create temporary table task8_catalog_parentage_before as
select jsonb_agg(
  jsonb_build_object(
    'id', reference.id,
    'preferredParentOneName', reference.preferred_parent_one_name,
    'preferredParentTwoName', reference.preferred_parent_two_name
  )
  order by reference.id
) as parentage
from api.catalog_references as reference;

insert into catalog.sources(
  id,
  display_name,
  owner_name,
  access_method,
  permitted_frequency,
  license_status,
  license_reference,
  raw_storage_allowed,
  attribution_rules,
  image_rights_status,
  confidence_class,
  responsible_reviewer,
  status
) values (
  'synthetic-task8-knowledge-graph',
  'Task 8 synthetic knowledge source',
  'Task 8 synthetic owner',
  'local synthetic fixture',
  'manual tests only',
  'approved',
  'https://example.invalid/task8-license',
  true,
  'Task 8 synthetic-only attribution',
  'not included',
  'supporting',
  'task8-synthetic-reviewer',
  'active'
);

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '62000000-0000-4000-8000-000000000001',
    'origin_population',
    'Task 8 synthetic origin placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000002',
    'cultivar',
    'Task 8 synthetic parent placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000003',
    'cultivar',
    'Task 8 synthetic child placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000004',
    'genetic_sample',
    'Task 8 synthetic sample one placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000005',
    'genetic_sample',
    'Task 8 synthetic sample two placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000006',
    'product',
    'Task 8 synthetic product placeholder',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000007',
    'cultivar',
    'Task 8 synthetic alternate parent placeholder',
    false
  );

set local role source_ingestor;
select *
from private.record_source_import(
  $task8$
  {
    "contractVersion": 2,
    "sourceId": "synthetic-task8-knowledge-graph",
    "startedAt": "2026-07-30T10:00:00.000Z",
    "completedAt": "2026-07-30T10:00:07.000Z",
    "cursor": null,
    "records": [
      {
        "externalRecordKey": "synthetic-task8-origin-001",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:01.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-origin"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[0].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-origin-001",
            "entityKind": "origin_population"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[0].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-origin-001",
            "name": "Synthetic Origin Population",
            "language": "en"
          },
          {
            "kind": "traditional_classification",
            "trace": {
              "sourceLocator": "$.records[0].classification",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-origin-001",
            "classification": "sativa"
          },
          {
            "kind": "origin_region",
            "trace": {
              "sourceLocator": "$.records[0].region",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-origin-001",
            "regionName": "Synthetic Highland",
            "regionCode": null
          },
          {
            "kind": "era",
            "trace": {
              "sourceLocator": "$.records[0].era",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-origin-001",
            "startYear": -1200,
            "endYear": -800,
            "label": "Synthetic historical era"
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-parent-001",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:02.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-parent"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[1].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-parent-001",
            "entityKind": "cultivar"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[1].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-parent-001",
            "name": "Synthetic Parent",
            "language": "en"
          },
          {
            "kind": "alias",
            "trace": {
              "sourceLocator": "$.records[1].aliases[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-parent-001",
            "name": "Synthetic Parent DE",
            "language": "de",
            "aliasType": "market",
            "market": "Germany"
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-child-001",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:03.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-child"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[2].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "entityKind": "cultivar"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[2].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "name": "Synthetic Child",
            "language": "en"
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.records[2].lineage[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "relatedExternalKey": "synthetic-task8-parent-001",
            "relationship": "reported_parent",
            "position": 1
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.records[2].lineage[1]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "relatedExternalKey": "synthetic-task8-origin-001",
            "relationship": "population_membership",
            "position": null
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.records[2].lineage[2]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "relatedExternalKey": null,
            "relationship": "unknown_parent",
            "position": 2
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-sample-001",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:04.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-sample-one"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[3].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-001",
            "entityKind": "genetic_sample"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[3].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-001",
            "name": "Synthetic Sample One",
            "language": "en"
          },
          {
            "kind": "sample_reference",
            "trace": {
              "sourceLocator": "$.records[3].sample",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-001",
            "sampleIdentifier": "SYN-001",
            "datasetName": "Synthetic Dataset",
            "datasetVersion": "1.0",
            "submitter": null,
            "laboratory": "Synthetic Lab",
            "sampledAt": "2026-07-01T00:00:00.000Z"
          },
          {
            "kind": "genetic_relation",
            "trace": {
              "sourceLocator": "$.records[3].relations[0]",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-001",
            "relatedExternalKey": "synthetic-task8-sample-002",
            "relationship": "genetic_similarity",
            "method": "synthetic-method",
            "datasetName": "Synthetic Dataset",
            "datasetVersion": "1.0",
            "metricName": "synthetic-similarity",
            "value": 0.875,
            "unit": "score"
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-sample-002",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:05.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-sample-two"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[4].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-002",
            "entityKind": "genetic_sample"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[4].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-002",
            "name": "Synthetic Sample Two",
            "language": "en"
          },
          {
            "kind": "sample_reference",
            "trace": {
              "sourceLocator": "$.records[4].sample",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-sample-002",
            "sampleIdentifier": "SYN-002",
            "datasetName": "Synthetic Dataset",
            "datasetVersion": "1.0",
            "submitter": null,
            "laboratory": "Synthetic Lab",
            "sampledAt": "2026-07-02T00:00:00.000Z"
          },
          {
            "kind": "genetic_relation",
            "trace": {
              "sourceLocator": "$.records[4].relations[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-sample-002",
            "relatedExternalKey": "synthetic-task8-sample-001",
            "relationship": "genetic_similarity",
            "method": "synthetic-parentage-defense",
            "datasetName": "Synthetic Defense Dataset",
            "datasetVersion": "2.0",
            "metricName": "synthetic-distance",
            "value": 0.125,
            "unit": "distance"
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-product-001",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:06.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-product"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[5].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-product-001",
            "entityKind": "product"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[5].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-product-001",
            "name": "Synthetic Medical Flower",
            "language": "en"
          },
          {
            "kind": "product_cultivar",
            "trace": {
              "sourceLocator": "$.records[5].cultivar",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-product-001",
            "cultivarExternalKey": "synthetic-task8-child-001",
            "productForm": "flower"
          },
          {
            "kind": "product_market",
            "trace": {
              "sourceLocator": "$.records[5].market",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-product-001",
            "countryCode": "DE",
            "medical": true
          },
          {
            "kind": "measurement",
            "trace": {
              "sourceLocator": "$.records[5].measurement.thc",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-product-001",
            "analyte": "thc",
            "value": 20.5,
            "unit": "percent",
            "productForm": "flower",
            "batchIdentifier": "SYN-BATCH-001",
            "measuredAt": "2026-07-30T00:00:00.000Z"
          }
        ]
      },
      {
        "externalRecordKey": "synthetic-task8-parent-002",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:00:07.000Z",
        "sourceVersion": "task8-v1",
        "evidence": {
          "kind": "raw",
          "mediaType": "application/json",
          "payload": {"fixture": "task8-alternate-parent"}
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.records[6].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-parent-002",
            "entityKind": "cultivar"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.records[6].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "synthetic-task8-parent-002",
            "name": "Synthetic Alternate Parent",
            "language": "en"
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.records[6].lineage[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "relatedExternalKey": "synthetic-task8-parent-002",
            "relationship": "reported_parent",
            "position": 1
          }
        ]
      }
    ],
    "errors": []
  }
  $task8$::jsonb
);
reset role;

select is(
  (
    select count(*)
    from catalog.normalized_assertions as assertion
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
  )::bigint,
  29::bigint,
  'the complete task-8 version-2 fixture stores every synthetic assertion'
);

select is(
  (
    select count(*)
    from catalog.normalized_assertions as assertion
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
      and assertion.assertion_kind = 'lineage'
      and assertion.subject_external_key = 'synthetic-task8-child-001'
      and assertion.payload ->> 'relationship' = 'reported_parent'
      and assertion.payload ->> 'position' = '1'
  )::bigint,
  2::bigint,
  'both immutable conflicting reported-parent assertions are stored'
);

select ok(
  exists (
    select 1
    from catalog.review_cases as review_case
    join catalog.normalized_assertions as assertion
      on assertion.id = review_case.assertion_id
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
      and review_case.case_kind = 'conflicting_lineage'
      and review_case.detail_code = 'conflicting_parent_for_position'
  ),
  'the contradictory parent fixture creates a conflicting-lineage review case'
);

select is(
  (
    select count(*)
    from api.published_knowledge_edges
    where from_node_id = '62000000-0000-4000-8000-000000000003'
      and relationship = 'reported_parent'
  )::bigint,
  0::bigint,
  'neither conflicting parent assertion enters the graph before review'
);

select throws_ok(
  format(
    'select private.review_knowledge_assertion(%L, %L, %L, %L, %L, %L)',
    (
      select assertion.id
      from catalog.normalized_assertions as assertion
      join catalog.source_records as record
        on record.id = assertion.source_record_id
      where record.source_id = 'synthetic-task8-knowledge-graph'
        and record.external_record_key = 'synthetic-task8-sample-002'
        and assertion.assertion_index = 3
    ),
    'accepted',
    '62000000-0000-4000-8000-000000000003',
    '62000000-0000-4000-8000-000000000002',
    'confirmed',
    'invalid synthetic similarity-to-parentage conversion'
  ),
  '22023',
  null,
  'genetic similarity cannot be reviewed against two cultivar UUIDs'
);

select private.review_knowledge_assertion(
  assertion.id,
  'accepted',
  review.entity_id,
  review.related_entity_id,
  review.evidence_status,
  'Task 8 explicit synthetic review'
)
from (
  values
    ('synthetic-task8-origin-001', 0, '62000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-origin-001', 1, '62000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-origin-001', 2, '62000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'historical'),
    ('synthetic-task8-origin-001', 3, '62000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'historical'),
    ('synthetic-task8-origin-001', 4, '62000000-0000-4000-8000-000000000001'::uuid, null::uuid, 'retracted'),
    ('synthetic-task8-parent-001', 0, '62000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-parent-001', 1, '62000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-parent-001', 2, '62000000-0000-4000-8000-000000000002'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-child-001', 0, '62000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-child-001', 1, '62000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-child-001', 2, '62000000-0000-4000-8000-000000000003'::uuid, '62000000-0000-4000-8000-000000000002'::uuid, 'disputed'),
    ('synthetic-task8-child-001', 3, '62000000-0000-4000-8000-000000000003'::uuid, '62000000-0000-4000-8000-000000000001'::uuid, 'historical'),
    ('synthetic-task8-child-001', 4, '62000000-0000-4000-8000-000000000003'::uuid, null::uuid, 'unknown'),
    ('synthetic-task8-sample-001', 0, '62000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-sample-001', 1, '62000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-sample-001', 2, '62000000-0000-4000-8000-000000000004'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-sample-001', 3, '62000000-0000-4000-8000-000000000004'::uuid, '62000000-0000-4000-8000-000000000005'::uuid, 'confirmed'),
    ('synthetic-task8-sample-002', 0, '62000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-sample-002', 1, '62000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-sample-002', 2, '62000000-0000-4000-8000-000000000005'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-sample-002', 3, '62000000-0000-4000-8000-000000000005'::uuid, '62000000-0000-4000-8000-000000000004'::uuid, 'single_source'),
    ('synthetic-task8-product-001', 0, '62000000-0000-4000-8000-000000000006'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-product-001', 1, '62000000-0000-4000-8000-000000000006'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-product-001', 2, '62000000-0000-4000-8000-000000000006'::uuid, '62000000-0000-4000-8000-000000000003'::uuid, 'confirmed'),
    ('synthetic-task8-product-001', 3, '62000000-0000-4000-8000-000000000006'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-product-001', 4, '62000000-0000-4000-8000-000000000006'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-parent-002', 0, '62000000-0000-4000-8000-000000000007'::uuid, null::uuid, 'confirmed'),
    ('synthetic-task8-parent-002', 1, '62000000-0000-4000-8000-000000000007'::uuid, null::uuid, 'single_source'),
    ('synthetic-task8-parent-002', 2, '62000000-0000-4000-8000-000000000003'::uuid, '62000000-0000-4000-8000-000000000007'::uuid, 'disputed')
) as review(
  external_record_key,
  assertion_index,
  entity_id,
  related_entity_id,
  evidence_status
)
join catalog.source_records as record
  on record.source_id = 'synthetic-task8-knowledge-graph'
 and record.external_record_key = review.external_record_key
join catalog.normalized_assertions as assertion
  on assertion.source_record_id = record.id
 and assertion.assertion_index = review.assertion_index;

select is(
  (
    select count(*)
    from catalog.assertion_reviews as review
    join catalog.normalized_assertions as assertion
      on assertion.id = review.assertion_id
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
      and review.decision = 'accepted'
      and review.evidence_status is not null
  )::bigint,
  29::bigint,
  'every task-8 fixture assertion has an explicit accepted evidence status'
);

select is(
  (
    select count(*)
    from catalog.assertion_reviews as review
    join catalog.normalized_assertions as assertion
      on assertion.id = review.assertion_id
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
      and assertion.assertion_kind = 'lineage'
      and assertion.subject_external_key = 'synthetic-task8-child-001'
      and assertion.payload ->> 'relationship' = 'reported_parent'
      and assertion.payload ->> 'position' = '1'
      and review.decision = 'accepted'
      and review.evidence_status = 'disputed'
  )::bigint,
  2::bigint,
  'both conflicting parents remain separately reviewed as disputed'
);

set local role source_reviewer;
select private.publish_reviewed_knowledge_graph() as task8_snapshot_id
\gset
reset role;

create temporary table task8_valid_graph_state as
select
  :'task8_snapshot_id'::uuid as snapshot_id,
  (select count(*) from api.published_knowledge_nodes) as node_count,
  (select count(*) from api.published_knowledge_claims) as claim_count,
  (select count(*) from api.published_knowledge_edges) as edge_count;

create temporary table task8_valid_rpc as
select api.get_published_knowledge_graph() as graph;

select ok(
  (
    select
      graph #>> '{snapshotId}' = :'task8_snapshot_id'
      and jsonb_array_length(graph -> 'nodes') = (
        select node_count from task8_valid_graph_state
      )
      and jsonb_array_length(graph -> 'claims') = (
        select claim_count from task8_valid_graph_state
      )
      and jsonb_array_length(graph -> 'edges') = (
        select edge_count from task8_valid_graph_state
      )
    from task8_valid_rpc
  ),
  'the RPC returns the complete task-8 publication snapshot'
);

select ok(
  (
    select
      valid.node_count = previous.node_count + 7
      and valid.claim_count = previous.claim_count + 22
      and valid.edge_count = previous.edge_count + 7
    from task8_valid_graph_state as valid
    cross join task8_previous_graph_state as previous
  ),
  'the complete fixture adds exactly seven nodes, twenty-two claims, and seven edges'
);

select set_eq(
  $$
    select node.value
    from task8_valid_rpc as rpc
    cross join jsonb_array_elements(rpc.graph -> 'nodes') as node(value)
    where node.value ->> 'id' in (
      '62000000-0000-4000-8000-000000000001',
      '62000000-0000-4000-8000-000000000002',
      '62000000-0000-4000-8000-000000000003',
      '62000000-0000-4000-8000-000000000004',
      '62000000-0000-4000-8000-000000000005',
      '62000000-0000-4000-8000-000000000006',
      '62000000-0000-4000-8000-000000000007'
    )
  $$,
  $$
    values
      ('{"id":"62000000-0000-4000-8000-000000000001","kind":"origin_population","canonicalName":"Synthetic Origin Population"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000002","kind":"cultivar","canonicalName":"Synthetic Parent"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000003","kind":"cultivar","canonicalName":"Synthetic Child"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000004","kind":"genetic_sample","canonicalName":"Synthetic Sample One"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000005","kind":"genetic_sample","canonicalName":"Synthetic Sample Two"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000006","kind":"product","canonicalName":"Synthetic Medical Flower"}'::jsonb),
      ('{"id":"62000000-0000-4000-8000-000000000007","kind":"cultivar","canonicalName":"Synthetic Alternate Parent"}'::jsonb)
  $$,
  'the RPC contains exactly the seven intended synthetic nodes'
);

select set_eq(
  $$
    select jsonb_build_object(
      'nodeId', claim.value ->> 'nodeId',
      'kind', claim.value ->> 'kind',
      'value', claim.value -> 'value',
      'evidenceStatus', claim.value ->> 'evidenceStatus',
      'sourceLocator', claim.value #>> '{evidence,sourceLocator}',
      'extractionMethod', claim.value #>> '{evidence,extractionMethod}',
      'retrievedAt', claim.value #>> '{evidence,retrievedAt}'
    )
    from task8_valid_rpc as rpc
    cross join jsonb_array_elements(rpc.graph -> 'claims') as claim(value)
    where claim.value ->> 'nodeId' in (
      '62000000-0000-4000-8000-000000000001',
      '62000000-0000-4000-8000-000000000002',
      '62000000-0000-4000-8000-000000000003',
      '62000000-0000-4000-8000-000000000004',
      '62000000-0000-4000-8000-000000000005',
      '62000000-0000-4000-8000-000000000006',
      '62000000-0000-4000-8000-000000000007'
    )
  $$,
  $$
    select jsonb_build_object(
      'nodeId', expected.node_id,
      'kind', expected.claim_kind,
      'value', expected.claim_value,
      'evidenceStatus', expected.evidence_status,
      'sourceLocator', expected.source_locator,
      'extractionMethod', expected.extraction_method,
      'retrievedAt', expected.retrieved_at
    )
    from (
      values
        ('62000000-0000-4000-8000-000000000001', 'entity_kind', '{"entityKind":"origin_population"}'::jsonb, 'confirmed', '$.records[0].kind', 'structured', '2026-07-30T10:00:01+00:00'),
        ('62000000-0000-4000-8000-000000000001', 'name', '{"name":"Synthetic Origin Population","language":"en"}'::jsonb, 'single_source', '$.records[0].name', 'structured', '2026-07-30T10:00:01+00:00'),
        ('62000000-0000-4000-8000-000000000001', 'traditional_classification', '{"classification":"sativa"}'::jsonb, 'historical', '$.records[0].classification', 'manual', '2026-07-30T10:00:01+00:00'),
        ('62000000-0000-4000-8000-000000000001', 'origin_region', '{"regionName":"Synthetic Highland","regionCode":null}'::jsonb, 'historical', '$.records[0].region', 'manual', '2026-07-30T10:00:01+00:00'),
        ('62000000-0000-4000-8000-000000000001', 'era', '{"startYear":-1200,"endYear":-800,"label":"Synthetic historical era"}'::jsonb, 'retracted', '$.records[0].era', 'manual', '2026-07-30T10:00:01+00:00'),
        ('62000000-0000-4000-8000-000000000002', 'entity_kind', '{"entityKind":"cultivar"}'::jsonb, 'confirmed', '$.records[1].kind', 'structured', '2026-07-30T10:00:02+00:00'),
        ('62000000-0000-4000-8000-000000000002', 'name', '{"name":"Synthetic Parent","language":"en"}'::jsonb, 'single_source', '$.records[1].name', 'structured', '2026-07-30T10:00:02+00:00'),
        ('62000000-0000-4000-8000-000000000002', 'alias', '{"name":"Synthetic Parent DE","language":"de","aliasType":"market","market":"Germany"}'::jsonb, 'single_source', '$.records[1].aliases[0]', 'manual', '2026-07-30T10:00:02+00:00'),
        ('62000000-0000-4000-8000-000000000003', 'entity_kind', '{"entityKind":"cultivar"}'::jsonb, 'confirmed', '$.records[2].kind', 'structured', '2026-07-30T10:00:03+00:00'),
        ('62000000-0000-4000-8000-000000000003', 'name', '{"name":"Synthetic Child","language":"en"}'::jsonb, 'single_source', '$.records[2].name', 'structured', '2026-07-30T10:00:03+00:00'),
        ('62000000-0000-4000-8000-000000000004', 'entity_kind', '{"entityKind":"genetic_sample"}'::jsonb, 'confirmed', '$.records[3].kind', 'structured', '2026-07-30T10:00:04+00:00'),
        ('62000000-0000-4000-8000-000000000004', 'name', '{"name":"Synthetic Sample One","language":"en"}'::jsonb, 'single_source', '$.records[3].name', 'structured', '2026-07-30T10:00:04+00:00'),
        ('62000000-0000-4000-8000-000000000004', 'sample_reference', '{"sampleIdentifier":"SYN-001","datasetName":"Synthetic Dataset","datasetVersion":"1.0","submitter":null,"laboratory":"Synthetic Lab","sampledAt":"2026-07-01T00:00:00.000Z"}'::jsonb, 'confirmed', '$.records[3].sample', 'structured', '2026-07-30T10:00:04+00:00'),
        ('62000000-0000-4000-8000-000000000005', 'entity_kind', '{"entityKind":"genetic_sample"}'::jsonb, 'confirmed', '$.records[4].kind', 'structured', '2026-07-30T10:00:05+00:00'),
        ('62000000-0000-4000-8000-000000000005', 'name', '{"name":"Synthetic Sample Two","language":"en"}'::jsonb, 'single_source', '$.records[4].name', 'structured', '2026-07-30T10:00:05+00:00'),
        ('62000000-0000-4000-8000-000000000005', 'sample_reference', '{"sampleIdentifier":"SYN-002","datasetName":"Synthetic Dataset","datasetVersion":"1.0","submitter":null,"laboratory":"Synthetic Lab","sampledAt":"2026-07-02T00:00:00.000Z"}'::jsonb, 'confirmed', '$.records[4].sample', 'structured', '2026-07-30T10:00:05+00:00'),
        ('62000000-0000-4000-8000-000000000006', 'entity_kind', '{"entityKind":"product"}'::jsonb, 'confirmed', '$.records[5].kind', 'structured', '2026-07-30T10:00:06+00:00'),
        ('62000000-0000-4000-8000-000000000006', 'name', '{"name":"Synthetic Medical Flower","language":"en"}'::jsonb, 'single_source', '$.records[5].name', 'structured', '2026-07-30T10:00:06+00:00'),
        ('62000000-0000-4000-8000-000000000006', 'product_market', '{"countryCode":"DE","medical":true}'::jsonb, 'confirmed', '$.records[5].market', 'structured', '2026-07-30T10:00:06+00:00'),
        ('62000000-0000-4000-8000-000000000006', 'measurement', '{"analyte":"thc","value":20.5,"unit":"percent","productForm":"flower","batchIdentifier":"SYN-BATCH-001","measuredAt":"2026-07-30T00:00:00.000Z"}'::jsonb, 'single_source', '$.records[5].measurement.thc', 'structured', '2026-07-30T10:00:06+00:00'),
        ('62000000-0000-4000-8000-000000000007', 'entity_kind', '{"entityKind":"cultivar"}'::jsonb, 'confirmed', '$.records[6].kind', 'structured', '2026-07-30T10:00:07+00:00'),
        ('62000000-0000-4000-8000-000000000007', 'name', '{"name":"Synthetic Alternate Parent","language":"en"}'::jsonb, 'single_source', '$.records[6].name', 'structured', '2026-07-30T10:00:07+00:00')
    ) as expected(
      node_id,
      claim_kind,
      claim_value,
      evidence_status,
      source_locator,
      extraction_method,
      retrieved_at
    )
  $$,
  'the RPC contains exactly the intended synthetic claims, values, statuses, and traces'
);

select set_eq(
  $$
    select jsonb_build_object(
      'fromNodeId', edge.value ->> 'fromNodeId',
      'toNodeId', edge.value -> 'toNodeId',
      'layer', edge.value ->> 'layer',
      'relationship', edge.value ->> 'relationship',
      'position', edge.value -> 'position',
      'evidenceStatus', edge.value ->> 'evidenceStatus',
      'details', edge.value -> 'details',
      'sourceLocator', edge.value #>> '{evidence,sourceLocator}',
      'extractionMethod', edge.value #>> '{evidence,extractionMethod}'
    )
    from task8_valid_rpc as rpc
    cross join jsonb_array_elements(rpc.graph -> 'edges') as edge(value)
    where edge.value ->> 'fromNodeId' in (
      '62000000-0000-4000-8000-000000000001',
      '62000000-0000-4000-8000-000000000002',
      '62000000-0000-4000-8000-000000000003',
      '62000000-0000-4000-8000-000000000004',
      '62000000-0000-4000-8000-000000000005',
      '62000000-0000-4000-8000-000000000006',
      '62000000-0000-4000-8000-000000000007'
    )
  $$,
  $$
    values
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000003","toNodeId":"62000000-0000-4000-8000-000000000002","layer":"documented_lineage","relationship":"reported_parent","position":1,"evidenceStatus":"disputed","details":{},"sourceLocator":"$.records[2].lineage[0]","extractionMethod":"manual"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000003","toNodeId":"62000000-0000-4000-8000-000000000001","layer":"documented_lineage","relationship":"population_membership","position":null,"evidenceStatus":"historical","details":{},"sourceLocator":"$.records[2].lineage[1]","extractionMethod":"manual"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000003","toNodeId":null,"layer":"documented_lineage","relationship":"unknown_parent","position":2,"evidenceStatus":"unknown","details":{},"sourceLocator":"$.records[2].lineage[2]","extractionMethod":"manual"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000004","toNodeId":"62000000-0000-4000-8000-000000000005","layer":"genetic_similarity","relationship":"genetic_similarity","position":null,"evidenceStatus":"confirmed","details":{"method":"synthetic-method","datasetName":"Synthetic Dataset","datasetVersion":"1.0","metricName":"synthetic-similarity","value":0.875,"unit":"score"},"sourceLocator":"$.records[3].relations[0]","extractionMethod":"structured"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000005","toNodeId":"62000000-0000-4000-8000-000000000004","layer":"genetic_similarity","relationship":"genetic_similarity","position":null,"evidenceStatus":"single_source","details":{"method":"synthetic-parentage-defense","datasetName":"Synthetic Defense Dataset","datasetVersion":"2.0","metricName":"synthetic-distance","value":0.125,"unit":"distance"},"sourceLocator":"$.records[4].relations[0]","extractionMethod":"manual"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000006","toNodeId":"62000000-0000-4000-8000-000000000003","layer":"product_mapping","relationship":"product_cultivar","position":null,"evidenceStatus":"confirmed","details":{"productForm":"flower"},"sourceLocator":"$.records[5].cultivar","extractionMethod":"structured"}'::jsonb),
      ('{"fromNodeId":"62000000-0000-4000-8000-000000000003","toNodeId":"62000000-0000-4000-8000-000000000007","layer":"documented_lineage","relationship":"reported_parent","position":1,"evidenceStatus":"disputed","details":{},"sourceLocator":"$.records[6].lineage[0]","extractionMethod":"manual"}'::jsonb)
  $$,
  'the RPC keeps exact documented, genetic, and product edges in separate layers'
);

select ok(
  not exists (
    select 1
    from task8_valid_rpc as rpc
    cross join jsonb_array_elements(rpc.graph -> 'claims') as claim(value)
    where claim.value ->> 'nodeId' in (
      '62000000-0000-4000-8000-000000000001',
      '62000000-0000-4000-8000-000000000002',
      '62000000-0000-4000-8000-000000000003',
      '62000000-0000-4000-8000-000000000004',
      '62000000-0000-4000-8000-000000000005',
      '62000000-0000-4000-8000-000000000006',
      '62000000-0000-4000-8000-000000000007'
    )
      and (
        claim.value #>> '{evidence,sourceName}'
          <> 'Task 8 synthetic knowledge source'
        or claim.value #>> '{evidence,sourceVersion}' <> 'task8-v1'
        or claim.value #>> '{evidence,attribution}'
          <> 'Task 8 synthetic-only attribution'
        or claim.value #> '{evidence,citationUrl}' <> 'null'::jsonb
      )
  )
  and not exists (
    select 1
    from task8_valid_rpc as rpc
    cross join jsonb_array_elements(rpc.graph -> 'edges') as edge(value)
    where edge.value ->> 'fromNodeId' in (
      '62000000-0000-4000-8000-000000000001',
      '62000000-0000-4000-8000-000000000002',
      '62000000-0000-4000-8000-000000000003',
      '62000000-0000-4000-8000-000000000004',
      '62000000-0000-4000-8000-000000000005',
      '62000000-0000-4000-8000-000000000006',
      '62000000-0000-4000-8000-000000000007'
    )
      and (
        edge.value #>> '{evidence,sourceName}'
          <> 'Task 8 synthetic knowledge source'
        or edge.value #>> '{evidence,sourceVersion}' <> 'task8-v1'
        or edge.value #>> '{evidence,attribution}'
          <> 'Task 8 synthetic-only attribution'
        or edge.value #> '{evidence,citationUrl}' <> 'null'::jsonb
      )
  ),
  'every synthetic RPC claim and edge retains the exact source evidence envelope'
);

select ok(
  (
    select count(*) = 1
    from api.published_knowledge_edges
    where from_node_id = '62000000-0000-4000-8000-000000000005'
      and to_node_id = '62000000-0000-4000-8000-000000000004'
      and layer = 'genetic_similarity'
      and relationship = 'genetic_similarity'
  )
  and not exists (
    select 1
    from api.published_knowledge_edges
    where from_node_id = '62000000-0000-4000-8000-000000000005'
      and to_node_id = '62000000-0000-4000-8000-000000000004'
      and layer = 'documented_lineage'
  ),
  'the false-parentage fixture publishes only as sample genetic similarity'
);

select is(
  (
    select jsonb_agg(
      jsonb_build_object(
        'id', reference.id,
        'preferredParentOneName', reference.preferred_parent_one_name,
        'preferredParentTwoName', reference.preferred_parent_two_name
      )
      order by reference.id
    )
    from api.catalog_references as reference
  ),
  (select parentage from task8_catalog_parentage_before),
  'genetic review and graph publication do not change any catalog preferred parent'
);

select ok(
  (
    select count(*) = 2
    from api.published_knowledge_edges
    where from_node_id = '62000000-0000-4000-8000-000000000003'
      and layer = 'documented_lineage'
      and relationship = 'reported_parent'
      and position = 1
      and evidence_status = 'disputed'
  )
  and (
    select count(distinct to_node_id) = 2
    from api.published_knowledge_edges
    where from_node_id = '62000000-0000-4000-8000-000000000003'
      and layer = 'documented_lineage'
      and relationship = 'reported_parent'
      and position = 1
  ),
  'both disputed parent assertions remain separately visible after publication'
);

set local role source_ingestor;
select *
from private.record_source_import(
  $task8duplicate$
  {
    "contractVersion": 2,
    "sourceId": "synthetic-task8-knowledge-graph",
    "startedAt": "2026-07-30T10:01:00.000Z",
    "completedAt": "2026-07-30T10:01:01.000Z",
    "cursor": null,
    "records": [
      {
        "externalRecordKey": "synthetic-task8-duplicate-child-name",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T10:01:01.000Z",
        "sourceVersion": "task8-v2-conflict",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "8282828282828282828282828282828282828282828282828282828282828282",
          "retrievalReference": "https://example.invalid/task8-duplicate-name"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.duplicate.child.name",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "synthetic-task8-child-001",
            "name": "Synthetic Child Duplicate",
            "language": "en"
          }
        ]
      }
    ],
    "errors": []
  }
  $task8duplicate$::jsonb
);
reset role;

select private.review_knowledge_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions as assertion
    join catalog.source_records as record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-task8-knowledge-graph'
      and record.external_record_key = 'synthetic-task8-duplicate-child-name'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '62000000-0000-4000-8000-000000000003',
  null,
  'disputed',
  'Task 8 deliberate duplicate canonical name'
);

select throws_ok(
  $$select private.publish_reviewed_knowledge_graph()$$,
  '22023',
  null,
  'a second accepted canonical name aborts graph publication'
);

select ok(
  (
    select
      snapshot_id = :'task8_snapshot_id'::uuid
      and node_count = (select count(*) from api.published_knowledge_nodes)
      and claim_count = (select count(*) from api.published_knowledge_claims)
      and edge_count = (select count(*) from api.published_knowledge_edges)
    from task8_valid_graph_state
  )
  and (
    select snapshot_id = :'task8_snapshot_id'::uuid
    from catalog.knowledge_current_snapshot
    where singleton
  )
  and (
    select snapshot_id = :'task8_snapshot_id'::uuid
    from api.published_knowledge_snapshot
    where singleton
  )
  and (
    api.get_published_knowledge_graph() #>> '{snapshotId}'
      = :'task8_snapshot_id'
  ),
  'failed duplicate-name publication preserves the prior snapshot UUID and row counts'
);

select * from finish();
rollback;
