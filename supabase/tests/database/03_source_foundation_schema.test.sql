begin;
select no_plan();

select has_table('catalog', 'sources', 'source register exists internally');
select has_table('catalog', 'import_runs', 'source import runs exist internally');
select has_table('catalog', 'source_records', 'immutable source records exist internally');
select has_table('catalog', 'normalized_assertions', 'normalized assertions exist internally');
select has_table('catalog', 'review_cases', 'source review cases exist internally');
select has_table('catalog', 'assertion_reviews', 'assertion reviews exist internally');
select has_table(
  'catalog',
  'knowledge_publication_snapshots',
  'immutable knowledge publication snapshots exist internally'
);
select has_table(
  'catalog',
  'knowledge_current_snapshot',
  'the current knowledge snapshot pointer exists internally'
);
select has_table(
  'catalog',
  'knowledge_snapshot_nodes',
  'immutable knowledge snapshot nodes exist internally'
);
select has_table(
  'catalog',
  'knowledge_snapshot_claims',
  'immutable knowledge snapshot claims exist internally'
);
select has_table(
  'catalog',
  'knowledge_snapshot_edges',
  'immutable knowledge snapshot edges exist internally'
);
select has_column(
  'catalog',
  'import_runs',
  'contract_version',
  'source import runs record their adapter contract'
);
select has_column(
  'catalog',
  'source_records',
  'import_run_id',
  'source records can link to their import run'
);
select has_column(
  'catalog',
  'assertion_reviews',
  'evidence_status',
  'assertion reviews record evidence status'
);

select ok(
  exists (select 1 from pg_roles where rolname = 'source_ingestor'),
  'least-privileged source_ingestor role exists'
);
select ok(
  exists (select 1 from pg_roles where rolname = 'source_reviewer'),
  'separate source_reviewer role exists'
);
select col_is_pk('catalog', 'sources', 'id', 'source ID is the primary key');
select col_is_pk('catalog', 'source_records', 'id', 'source record ID is the primary key');
select col_is_pk('catalog', 'normalized_assertions', 'id', 'assertion ID is the primary key');
select col_is_pk(
  'catalog',
  'assertion_reviews',
  'assertion_id',
  'one current review exists per assertion'
);
select has_index(
  'catalog',
  'source_records',
  'source_records_source_external_hash_key',
  'identical source versions are unique'
);
select is(
  (
    select count(*)
    from catalog.sources
    where id = 'synthetic-contract-source'
      and status = 'inactive'
  )::bigint,
  1::bigint,
  'only the inactive synthetic contract source is seeded'
);
select is(
  (
    select count(*)
    from catalog.sources
    where status in ('pilot', 'active')
  )::bigint,
  0::bigint,
  'no live external source is activated'
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
) values (
  'synthetic-schema-source',
  'Synthetic schema source',
  'Synthetic owner',
  'synthetic fixture',
  'manual tests only',
  'approved',
  'https://example.invalid/license',
  false,
  'Synthetic attribution',
  'not included',
  'supporting',
  'schema-test-reviewer',
  'inactive'
);

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '30000000-0000-4000-8000-000000000001',
    'origin_population',
    'Synthetic origin population node',
    false
  ),
  (
    '30000000-0000-4000-8000-000000000002',
    'cultivar',
    'Synthetic cultivar node',
    false
  ),
  (
    '30000000-0000-4000-8000-000000000003',
    'genetic_sample',
    'Synthetic genetic sample node',
    false
  ),
  (
    '30000000-0000-4000-8000-000000000004',
    'product',
    'Synthetic product node',
    false
  );

select is(
  (
    select count(*)
    from catalog.entities
    where id between
      '30000000-0000-4000-8000-000000000001'::uuid
      and '30000000-0000-4000-8000-000000000004'::uuid
  )::bigint,
  4::bigint,
  'all four knowledge graph entity kinds are accepted'
);

select throws_ok(
  $$insert into catalog.entities(id, kind, canonical_name, published) values (
      '30000000-0000-4000-8000-000000000005',
      'synthetic_invalid_kind',
      'Synthetic invalid node',
      false
    )$$,
  '23514',
  null,
  'a fifth entity kind is rejected'
);

select throws_ok(
  $$insert into catalog.sources(
      id, display_name, owner_name, access_method, permitted_frequency,
      license_status, raw_storage_allowed, attribution_rules,
      image_rights_status, confidence_class, responsible_reviewer, status
    ) values (
      'synthetic-invalid-status', 'Invalid', 'Owner', 'fixture', 'never',
      'approved', false, 'Attribution', 'none', 'supporting', 'Reviewer',
      'enabled'
    )$$,
  '23514',
  null,
  'source activation status is closed'
);

insert into catalog.import_runs(
  id,
  source_id,
  started_at,
  completed_at,
  cursor,
  adapter_errors
) values (
  '30500000-0000-4000-8000-000000000001',
  'synthetic-schema-source',
  '2026-07-28T17:59:00Z',
  '2026-07-28T17:59:01Z',
  null,
  '[]'::jsonb
);

select is(
  (
    select contract_version
    from catalog.import_runs
    where id = '30500000-0000-4000-8000-000000000001'
  ),
  1::smallint,
  'legacy import runs retain contract version 1'
);

insert into catalog.source_records(
  id,
  source_id,
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
) values (
  '31000000-0000-4000-8000-000000000001',
  'synthetic-schema-source',
  'synthetic-record-001',
  'present',
  '2026-07-28T18:00:00Z',
  'fixture-1',
  'checksum',
  null,
  null,
  '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
  'https://example.invalid/synthetic-record-001',
  null,
  null,
  'approved',
  false,
  'Synthetic attribution'
);

select ok(
  exists (
    select 1
    from catalog.source_records
    where id = '31000000-0000-4000-8000-000000000001'
      and import_run_id is null
  ),
  'synthetic legacy source rows remain queryable without fabricated locators'
);

select throws_ok(
  $$insert into catalog.source_records(
      source_id, external_record_key, upstream_state, retrieved_at,
      evidence_kind, raw_media_type, raw_payload, content_hash,
      retrieval_reference, license_status_snapshot,
      raw_storage_allowed_snapshot, attribution_snapshot
    ) values (
      'synthetic-schema-source', 'mixed-evidence', 'present', now(),
      'checksum', 'application/json', '{"not":"allowed"}',
      'abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789',
      'https://example.invalid/mixed', 'approved', false, 'Synthetic'
    )$$,
  '23514',
  null,
  'source evidence is either raw or checksum metadata'
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
) values (
  '32000000-0000-4000-8000-000000000001',
  '31000000-0000-4000-8000-000000000001',
  0,
  'name',
  'synthetic-record-001',
  '{"kind":"name","subjectExternalKey":"synthetic-record-001","name":"Synthetic name","language":"en"}',
  null,
  null
);

select throws_ok(
  $$insert into catalog.normalized_assertions(
      source_record_id, assertion_index, assertion_kind,
      subject_external_key, payload
    ) values (
      '31000000-0000-4000-8000-000000000001',
      1,
      'measurement',
      'synthetic-record-001',
      '{"kind":"measurement","subjectExternalKey":"synthetic-record-001","analyte":"thc","value":"not-a-number","unit":"percent","productForm":"flower","measuredAt":null}'
    )$$,
  '23514',
  null,
  'normalized assertion payloads are typed server-side'
);

select throws_ok(
  $$update catalog.source_records
    set source_version = 'rewritten'
    where id = '31000000-0000-4000-8000-000000000001'$$,
  '55000',
  'source records are immutable',
  'source records cannot be updated'
);
select throws_ok(
  $$delete from catalog.normalized_assertions
    where id = '32000000-0000-4000-8000-000000000001'$$,
  '55000',
  'normalized assertions are immutable',
  'normalized assertions cannot be deleted'
);

select lives_ok(
  $$insert into catalog.assertion_reviews(
      assertion_id, decision, entity_id, related_entity_id,
      reviewer_name, reviewed_at, note
    ) values (
      '32000000-0000-4000-8000-000000000001',
      'rejected',
      null,
      null,
      'schema-reviewer',
      now(),
      'Synthetic rejection'
    )$$,
  'a rejected assertion needs no canonical mapping'
);

select throws_ok(
  $$update catalog.assertion_reviews
    set decision = 'accepted'
    where assertion_id = '32000000-0000-4000-8000-000000000001'$$,
  '23514',
  null,
  'an accepted review requires a canonical entity'
);

select ok(
  (
    select evidence_status is null
    from catalog.assertion_reviews
    where assertion_id = '32000000-0000-4000-8000-000000000001'
  ),
  'rejected legacy reviews retain a null evidence status'
);

select ok(
  private.source_assertion_payload_valid(
    assertion_kind,
    payload
  ),
  pg_catalog.format(
    'valid version-2 %s payload is accepted',
    assertion_kind
  )
)
from (
  values
    (
      'entity_kind',
      '{
        "kind":"entity_kind",
        "trace":{"sourceLocator":"$.synthetic.entityKind","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "entityKind":"cultivar"
      }'::jsonb
    ),
    (
      'traditional_classification',
      '{
        "kind":"traditional_classification",
        "trace":{"sourceLocator":"$.synthetic.classification","extractionMethod":"manual"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "classification":"hybrid"
      }'::jsonb
    ),
    (
      'origin_region',
      '{
        "kind":"origin_region",
        "trace":{"sourceLocator":"$.synthetic.origin","extractionMethod":"ai_assisted"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "regionName":"Synthetic Test Region",
        "regionCode":"ZZ"
      }'::jsonb
    ),
    (
      'era',
      '{
        "kind":"era",
        "trace":{"sourceLocator":"$.synthetic.era","extractionMethod":"manual"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "startYear":1900,
        "endYear":2000,
        "label":"Synthetic test era"
      }'::jsonb
    ),
    (
      'sample_reference',
      '{
        "kind":"sample_reference",
        "trace":{"sourceLocator":"$.synthetic.sample","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "sampleIdentifier":"SYNTHETIC-SAMPLE-001",
        "datasetName":"Synthetic test dataset",
        "datasetVersion":"test-v1",
        "submitter":"Synthetic submitter",
        "laboratory":"Synthetic laboratory",
        "sampledAt":"2026-07-28T18:00:00.000Z"
      }'::jsonb
    ),
    (
      'genetic_relation',
      '{
        "kind":"genetic_relation",
        "trace":{"sourceLocator":"$.synthetic.geneticRelation","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "relatedExternalKey":"synthetic-graph-record-002",
        "relationship":"genetic_similarity",
        "method":"Synthetic comparison method",
        "datasetName":"Synthetic test dataset",
        "datasetVersion":"test-v1",
        "metricName":"Synthetic similarity score",
        "value":0.75,
        "unit":"ratio"
      }'::jsonb
    ),
    (
      'product_market',
      '{
        "kind":"product_market",
        "trace":{"sourceLocator":"$.synthetic.market","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "countryCode":"ZZ",
        "medical":true
      }'::jsonb
    )
) as valid_assertion(assertion_kind, payload);

select ok(
  not private.source_assertion_payload_valid(
    assertion_kind,
    payload || '{"unexpected":"synthetic"}'::jsonb
  ),
  pg_catalog.format(
    'unknown fields invalidate version-2 %s payloads',
    assertion_kind
  )
)
from (
  values
    (
      'entity_kind',
      '{
        "kind":"entity_kind",
        "trace":{"sourceLocator":"$.synthetic.entityKind","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "entityKind":"cultivar"
      }'::jsonb
    ),
    (
      'traditional_classification',
      '{
        "kind":"traditional_classification",
        "trace":{"sourceLocator":"$.synthetic.classification","extractionMethod":"manual"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "classification":"hybrid"
      }'::jsonb
    ),
    (
      'origin_region',
      '{
        "kind":"origin_region",
        "trace":{"sourceLocator":"$.synthetic.origin","extractionMethod":"ai_assisted"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "regionName":"Synthetic Test Region",
        "regionCode":"ZZ"
      }'::jsonb
    ),
    (
      'era',
      '{
        "kind":"era",
        "trace":{"sourceLocator":"$.synthetic.era","extractionMethod":"manual"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "startYear":1900,
        "endYear":2000,
        "label":"Synthetic test era"
      }'::jsonb
    ),
    (
      'sample_reference',
      '{
        "kind":"sample_reference",
        "trace":{"sourceLocator":"$.synthetic.sample","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "sampleIdentifier":"SYNTHETIC-SAMPLE-001",
        "datasetName":"Synthetic test dataset",
        "datasetVersion":"test-v1",
        "submitter":"Synthetic submitter",
        "laboratory":"Synthetic laboratory",
        "sampledAt":"2026-07-28T18:00:00.000Z"
      }'::jsonb
    ),
    (
      'genetic_relation',
      '{
        "kind":"genetic_relation",
        "trace":{"sourceLocator":"$.synthetic.geneticRelation","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "relatedExternalKey":"synthetic-graph-record-002",
        "relationship":"genetic_similarity",
        "method":"Synthetic comparison method",
        "datasetName":"Synthetic test dataset",
        "datasetVersion":"test-v1",
        "metricName":"Synthetic similarity score",
        "value":0.75,
        "unit":"ratio"
      }'::jsonb
    ),
    (
      'product_market',
      '{
        "kind":"product_market",
        "trace":{"sourceLocator":"$.synthetic.market","extractionMethod":"structured"},
        "subjectExternalKey":"synthetic-graph-record-001",
        "countryCode":"ZZ",
        "medical":true
      }'::jsonb
    )
) as invalid_assertion(assertion_kind, payload);

select $batch$
{
  "contractVersion": 2,
  "sourceId": "synthetic-schema-source",
  "startedAt": "2026-07-28T18:10:00.000Z",
  "completedAt": "2026-07-28T18:10:01.000Z",
  "cursor": null,
  "records": [{
    "externalRecordKey": "synthetic-graph-record-001",
    "upstreamState": "present",
    "retrievedAt": "2026-07-28T18:10:01.000Z",
    "sourceVersion": "synthetic-graph-fixture-1",
    "evidence": {
      "kind": "checksum",
      "algorithm": "sha256",
      "digest": "9999999999999999999999999999999999999999999999999999999999999999",
      "retrievalReference": "https://example.invalid/synthetic-graph-record-001"
    },
    "validFrom": null,
    "validTo": null,
    "assertions": [
      {
        "kind": "entity_kind",
        "trace": {
          "sourceLocator": "$.synthetic.entityKind",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "entityKind": "cultivar"
      },
      {
        "kind": "traditional_classification",
        "trace": {
          "sourceLocator": "$.synthetic.classification",
          "extractionMethod": "manual"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "classification": "hybrid"
      },
      {
        "kind": "origin_region",
        "trace": {
          "sourceLocator": "$.synthetic.origin",
          "extractionMethod": "ai_assisted"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "regionName": "Synthetic Test Region",
        "regionCode": "ZZ"
      },
      {
        "kind": "era",
        "trace": {
          "sourceLocator": "$.synthetic.era",
          "extractionMethod": "manual"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "startYear": 1900,
        "endYear": 2000,
        "label": "Synthetic test era"
      },
      {
        "kind": "sample_reference",
        "trace": {
          "sourceLocator": "$.synthetic.sample",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "sampleIdentifier": "SYNTHETIC-SAMPLE-001",
        "datasetName": "Synthetic test dataset",
        "datasetVersion": "test-v1",
        "submitter": "Synthetic submitter",
        "laboratory": "Synthetic laboratory",
        "sampledAt": "2026-07-28T18:00:00.000Z"
      },
      {
        "kind": "genetic_relation",
        "trace": {
          "sourceLocator": "$.synthetic.geneticRelation",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "relatedExternalKey": "synthetic-graph-record-002",
        "relationship": "genetic_similarity",
        "method": "Synthetic comparison method",
        "datasetName": "Synthetic test dataset",
        "datasetVersion": "test-v1",
        "metricName": "Synthetic similarity score",
        "value": 0.75,
        "unit": "ratio"
      },
      {
        "kind": "product_market",
        "trace": {
          "sourceLocator": "$.synthetic.market",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "synthetic-graph-record-001",
        "countryCode": "ZZ",
        "medical": true
      }
    ]
  }],
  "errors": []
}
$batch$ as graph_batch
\gset

select throws_ok(
  pg_catalog.format(
    'select * from private.record_source_import(%L::jsonb)',
    (:'graph_batch'::jsonb - 'contractVersion')::text
  ),
  '22023',
  null,
  'a missing adapter contract version is rejected'
);

select throws_ok(
  pg_catalog.format(
    'select * from private.record_source_import(%L::jsonb)',
    pg_catalog.jsonb_set(
      :'graph_batch'::jsonb,
      '{contractVersion}',
      '1'::jsonb
    )::text
  ),
  '22023',
  null,
  'adapter contract versions other than 2 are rejected'
);

select is(
  private.source_assertion_trace_valid(null::jsonb),
  false,
  'trace validation is total for a missing SQL value'
);

select throws_ok(
  pg_catalog.format(
    'select * from private.record_source_import(%L::jsonb)',
    pg_catalog.jsonb_build_object(
      'contractVersion', 2,
      'sourceId', 'synthetic-schema-source',
      'startedAt', '2026-07-28T18:08:00.000Z',
      'completedAt', '2026-07-28T18:08:01.000Z',
      'cursor', null,
      'records', pg_catalog.jsonb_build_array(
        pg_catalog.jsonb_build_object(
          'externalRecordKey',
            'synthetic-missing-trace-' || missing_trace.assertion_kind,
          'upstreamState', 'present',
          'retrievedAt', '2026-07-28T18:08:01.000Z',
          'sourceVersion', 'synthetic-missing-trace-fixture-1',
          'evidence', pg_catalog.jsonb_build_object(
            'kind', 'checksum',
            'algorithm', 'sha256',
            'digest',
              pg_catalog.md5(missing_trace.assertion_kind)
              || pg_catalog.md5(missing_trace.assertion_kind),
            'retrievalReference',
              'https://example.invalid/missing-trace-'
              || missing_trace.assertion_kind
          ),
          'validFrom', null,
          'validTo', null,
          'assertions',
            pg_catalog.jsonb_build_array(missing_trace.assertion_payload)
        )
      ),
      'errors', pg_catalog.jsonb_build_array()
    )::text
  ),
  '22023',
  null,
  pg_catalog.format(
    'a version-2 %s assertion cannot use its trace-free legacy shape',
    missing_trace.assertion_kind
  )
)
from (
  values
    (
      'name',
      '{
        "kind":"name",
        "subjectExternalKey":"synthetic-missing-trace-name",
        "name":"Synthetic missing-trace name",
        "language":"en"
      }'::jsonb
    ),
    (
      'alias',
      '{
        "kind":"alias",
        "subjectExternalKey":"synthetic-missing-trace-alias",
        "name":"Synthetic missing-trace alias",
        "language":"en"
      }'::jsonb
    ),
    (
      'lineage',
      '{
        "kind":"lineage",
        "subjectExternalKey":"synthetic-missing-trace-lineage",
        "parentExternalKey":"synthetic-missing-trace-parent",
        "relationship":"reported_parent",
        "position":1
      }'::jsonb
    ),
    (
      'product_cultivar',
      '{
        "kind":"product_cultivar",
        "subjectExternalKey":"synthetic-missing-trace-product_cultivar",
        "cultivarExternalKey":"synthetic-missing-trace-cultivar",
        "productForm":"flower"
      }'::jsonb
    ),
    (
      'measurement',
      '{
        "kind":"measurement",
        "subjectExternalKey":"synthetic-missing-trace-measurement",
        "analyte":"thc",
        "value":12.5,
        "unit":"percent",
        "productForm":"flower",
        "measuredAt":null
      }'::jsonb
    )
) as missing_trace(assertion_kind, assertion_payload);

select throws_ok(
  pg_catalog.format(
    'select * from private.record_source_import(%L::jsonb)',
    (
      :'graph_batch'::jsonb
      #- '{records,0,assertions,0,trace}'
    )::text
  ),
  '22023',
  null,
  'a version-2 assertion without trace is rejected'
);

select throws_ok(
  pg_catalog.format(
    'select * from private.record_source_import(%L::jsonb)',
    pg_catalog.jsonb_set(
      :'graph_batch'::jsonb,
      '{records,0,assertions,0,trace}',
      (
        :'graph_batch'::jsonb
        #> '{records,0,assertions,0,trace}'
      ) || '{"unexpected":"synthetic"}'::jsonb
    )::text
  ),
  '22023',
  null,
  'unknown version-2 trace keys are rejected'
);

select *
from private.record_source_import(:'graph_batch'::jsonb);

select ok(
  not exists (
    select 1
    from catalog.source_records source_record
    left join catalog.import_runs import_run
      on import_run.id = source_record.import_run_id
    where source_record.source_id = 'synthetic-schema-source'
      and source_record.external_record_key = 'synthetic-graph-record-001'
      and (
        source_record.import_run_id is null
        or import_run.contract_version <> 2
      )
  ),
  'every version-2 source record links to a version-2 import run'
);

select is(
  (
    select count(*)
    from catalog.normalized_assertions
    where source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
  )::bigint,
  7::bigint,
  'all seven new assertion kinds are stored'
);

insert into catalog.assertion_reviews(
  assertion_id,
  decision,
  entity_id,
  related_entity_id,
  reviewer_name,
  reviewed_at,
  note,
  evidence_status
)
select
  assertion.id,
  'accepted',
  '30000000-0000-4000-8000-000000000002',
  null,
  'synthetic-schema-reviewer',
  now(),
  'Synthetic evidence-state acceptance',
  evidence_state.evidence_status
from (
  values
    (0, 'confirmed'),
    (1, 'single_source'),
    (2, 'disputed'),
    (3, 'historical'),
    (4, 'unknown'),
    (5, 'retracted')
) as evidence_state(assertion_index, evidence_status)
join catalog.normalized_assertions assertion
  on assertion.source_record_id = (
    select id
    from catalog.source_records
    where source_id = 'synthetic-schema-source'
      and external_record_key = 'synthetic-graph-record-001'
  )
 and assertion.assertion_index = evidence_state.assertion_index;

select is(
  (
    select count(distinct review.evidence_status)
    from catalog.assertion_reviews review
    join catalog.normalized_assertions assertion
      on assertion.id = review.assertion_id
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and review.decision = 'accepted'
  )::bigint,
  6::bigint,
  'all six accepted evidence states are allowed'
);

select throws_ok(
  $$insert into catalog.assertion_reviews(
      assertion_id, decision, entity_id, related_entity_id,
      reviewer_name, reviewed_at, note, evidence_status
    )
    select
      assertion.id,
      'accepted',
      '30000000-0000-4000-8000-000000000002',
      null,
      'synthetic-schema-reviewer',
      now(),
      'Synthetic invalid missing evidence state',
      null
    from catalog.normalized_assertions assertion
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and assertion.assertion_index = 6$$,
  '23514',
  null,
  'accepted reviews require an evidence state'
);

select throws_ok(
  $$insert into catalog.assertion_reviews(
      assertion_id, decision, entity_id, related_entity_id,
      reviewer_name, reviewed_at, note, evidence_status
    )
    select
      assertion.id,
      'accepted',
      '30000000-0000-4000-8000-000000000002',
      null,
      'synthetic-schema-reviewer',
      now(),
      'Synthetic invalid evidence state',
      'synthetic_invalid'
    from catalog.normalized_assertions assertion
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and assertion.assertion_index = 6$$,
  '23514',
  null,
  'accepted reviews reject evidence states outside the closed set'
);

select throws_ok(
  $$insert into catalog.assertion_reviews(
      assertion_id, decision, entity_id, related_entity_id,
      reviewer_name, reviewed_at, note, evidence_status
    )
    select
      assertion.id,
      'rejected',
      null,
      null,
      'synthetic-schema-reviewer',
      now(),
      'Synthetic invalid rejected evidence state',
      'confirmed'
    from catalog.normalized_assertions assertion
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and assertion.assertion_index = 6$$,
  '23514',
  null,
  'rejected reviews require a null evidence state'
);

insert into catalog.knowledge_publication_snapshots(
  id,
  previous_snapshot_id,
  published_by,
  published_at,
  assertion_count
) values
  (
    '34000000-0000-4000-8000-000000000001',
    null,
    'synthetic-schema-reviewer',
    '2026-07-28T18:20:00Z',
    2
  ),
  (
    '34000000-0000-4000-8000-000000000002',
    '34000000-0000-4000-8000-000000000001',
    'synthetic-schema-reviewer',
    '2026-07-28T18:21:00Z',
    0
  );

insert into catalog.knowledge_snapshot_nodes(
  snapshot_id,
  entity_id,
  kind,
  canonical_name
) values (
  '34000000-0000-4000-8000-000000000001',
  '30000000-0000-4000-8000-000000000002',
  'cultivar',
  'Synthetic cultivar node'
);

insert into catalog.knowledge_snapshot_claims(
  snapshot_id,
  assertion_id,
  entity_id,
  claim_kind,
  value,
  evidence_status,
  evidence
)
select
  '34000000-0000-4000-8000-000000000001',
  assertion.id,
  '30000000-0000-4000-8000-000000000002',
  'entity_kind',
  '"cultivar"'::jsonb,
  'confirmed',
  '{"sourceLocator":"$.synthetic.entityKind"}'::jsonb
from catalog.normalized_assertions assertion
where assertion.source_record_id = (
  select id
  from catalog.source_records
  where source_id = 'synthetic-schema-source'
    and external_record_key = 'synthetic-graph-record-001'
)
  and assertion.assertion_index = 0;

insert into catalog.knowledge_snapshot_edges(
  snapshot_id,
  assertion_id,
  from_entity_id,
  to_entity_id,
  layer,
  relationship,
  position,
  evidence_status,
  details,
  evidence
)
select
  '34000000-0000-4000-8000-000000000001',
  assertion.id,
  '30000000-0000-4000-8000-000000000002',
  '30000000-0000-4000-8000-000000000003',
  'genetic_similarity',
  'genetic_similarity',
  null,
  'single_source',
  '{"synthetic":true}'::jsonb,
  '{"sourceLocator":"$.synthetic.geneticRelation"}'::jsonb
from catalog.normalized_assertions assertion
where assertion.source_record_id = (
  select id
  from catalog.source_records
  where source_id = 'synthetic-schema-source'
    and external_record_key = 'synthetic-graph-record-001'
)
  and assertion.assertion_index = 5;

select throws_ok(
  $$insert into catalog.knowledge_snapshot_claims(
      snapshot_id,
      assertion_id,
      entity_id,
      claim_kind,
      value,
      evidence_status,
      evidence
    )
    select
      '34000000-0000-4000-8000-000000000002',
      assertion.id,
      '30000000-0000-4000-8000-000000000002',
      'traditional_classification',
      '"hybrid"'::jsonb,
      'synthetic_invalid',
      '{"sourceLocator":"$.synthetic.classification"}'::jsonb
    from catalog.normalized_assertions assertion
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and assertion.assertion_index = 1$$,
  '23514',
  null,
  'snapshot claims reject evidence states outside the closed set'
);

select throws_ok(
  $$insert into catalog.knowledge_snapshot_edges(
      snapshot_id,
      assertion_id,
      from_entity_id,
      to_entity_id,
      layer,
      relationship,
      position,
      evidence_status,
      details,
      evidence
    )
    select
      '34000000-0000-4000-8000-000000000002',
      assertion.id,
      '30000000-0000-4000-8000-000000000002',
      '30000000-0000-4000-8000-000000000003',
      'genetic_similarity',
      'genetic_similarity',
      null,
      'synthetic_invalid',
      '{"synthetic":true}'::jsonb,
      '{"sourceLocator":"$.synthetic.geneticRelation"}'::jsonb
    from catalog.normalized_assertions assertion
    where assertion.source_record_id = (
      select id
      from catalog.source_records
      where source_id = 'synthetic-schema-source'
        and external_record_key = 'synthetic-graph-record-001'
    )
      and assertion.assertion_index = 5$$,
  '23514',
  null,
  'snapshot edges reject evidence states outside the closed set'
);

insert into catalog.knowledge_current_snapshot(singleton, snapshot_id)
values (
  true,
  '34000000-0000-4000-8000-000000000001'
);

select lives_ok(
  $$update catalog.knowledge_current_snapshot
    set snapshot_id = '34000000-0000-4000-8000-000000000002'
    where singleton$$,
  'the singleton pointer may move to a newer immutable snapshot'
);

select ok(
  (
    select count(*) = 1
      and bool_and(snapshot_id =
        '34000000-0000-4000-8000-000000000002'::uuid
      )
    from catalog.knowledge_current_snapshot
  ),
  'the current snapshot remains a single row after moving'
);

select throws_ok(
  $$insert into catalog.knowledge_current_snapshot(singleton, snapshot_id)
    values (
      false,
      '34000000-0000-4000-8000-000000000001'
    )$$,
  '23514',
  null,
  'a second current-snapshot pointer cannot be created'
);

select throws_ok(
  $$update catalog.knowledge_publication_snapshots
    set assertion_count = 3
    where id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot metadata cannot be updated'
);

select throws_ok(
  $$delete from catalog.knowledge_publication_snapshots
    where id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot metadata cannot be deleted'
);

select throws_ok(
  $$update catalog.knowledge_snapshot_nodes
    set canonical_name = 'Synthetic rewritten node'
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot nodes cannot be updated'
);

select throws_ok(
  $$delete from catalog.knowledge_snapshot_nodes
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot nodes cannot be deleted'
);

select throws_ok(
  $$update catalog.knowledge_snapshot_claims
    set evidence_status = 'retracted'
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot claims cannot be updated'
);

select throws_ok(
  $$delete from catalog.knowledge_snapshot_claims
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot claims cannot be deleted'
);

select throws_ok(
  $$update catalog.knowledge_snapshot_edges
    set evidence_status = 'retracted'
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot edges cannot be updated'
);

select throws_ok(
  $$delete from catalog.knowledge_snapshot_edges
    where snapshot_id = '34000000-0000-4000-8000-000000000001'$$,
  '55000',
  'knowledge publication snapshots are immutable',
  'completed snapshot edges cannot be deleted'
);

select * from finish();
rollback;
