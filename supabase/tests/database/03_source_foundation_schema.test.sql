begin;
select no_plan();

select has_table('catalog', 'sources', 'source register exists internally');
select has_table('catalog', 'import_runs', 'source import runs exist internally');
select has_table('catalog', 'source_records', 'immutable source records exist internally');
select has_table('catalog', 'normalized_assertions', 'normalized assertions exist internally');
select has_table('catalog', 'review_cases', 'source review cases exist internally');
select has_table('catalog', 'assertion_reviews', 'assertion reviews exist internally');

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

select * from finish();
rollback;
