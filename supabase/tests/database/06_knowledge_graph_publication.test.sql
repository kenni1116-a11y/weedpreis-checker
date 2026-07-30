begin;
select no_plan();

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

select * from finish();
rollback;
