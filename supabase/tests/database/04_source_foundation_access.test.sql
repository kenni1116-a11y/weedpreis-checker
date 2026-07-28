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
) values (
  'synthetic-access-source',
  'Synthetic access source',
  'Synthetic owner',
  'synthetic fixture',
  'manual tests only',
  'approved',
  'https://example.invalid/license',
  false,
  'Synthetic attribution',
  'not included',
  'supporting',
  'access-test-reviewer',
  'inactive'
);

insert into catalog.entities(id, kind, canonical_name, published) values (
  '33000000-0000-4000-8000-000000000001',
  'cultivar',
  'Synthetic reviewed cultivar',
  false
);

select ok(
  not has_schema_privilege('anon', 'catalog', 'usage'),
  'anonymous browser cannot resolve catalog internals'
);
select ok(
  not has_schema_privilege('authenticated', 'catalog', 'usage'),
  'authenticated browser cannot resolve catalog internals'
);
select ok(
  not has_table_privilege('source_ingestor', 'catalog.sources', 'select'),
  'ingestor has no direct source-table read'
);
select ok(
  not has_table_privilege(
    'source_reviewer',
    'catalog.normalized_assertions',
    'insert'
  ),
  'reviewer cannot insert assertions directly'
);

select ok(
  has_function_privilege(
    'source_ingestor',
    'private.record_source_import(jsonb)',
    'execute'
  ),
  'ingestor can execute only the import capability'
);
select ok(
  not has_function_privilege(
    'source_ingestor',
    'private.review_source_assertion(uuid,text,uuid,uuid,text)',
    'execute'
  ),
  'ingestor cannot review assertions'
);
select ok(
  not has_function_privilege(
    'source_ingestor',
    'private.review_source_record_deletion(uuid,text,text)',
    'execute'
  ),
  'ingestor cannot review upstream deletions'
);
select ok(
  has_function_privilege(
    'source_reviewer',
    'private.review_source_assertion(uuid,text,uuid,uuid,text)',
    'execute'
  ),
  'reviewer can execute the review capability'
);
select ok(
  has_function_privilege(
    'source_reviewer',
    'private.review_source_record_deletion(uuid,text,text)',
    'execute'
  ),
  'reviewer can decide an upstream deletion case'
);
select ok(
  not has_function_privilege(
    'source_reviewer',
    'private.record_source_import(jsonb)',
    'execute'
  ),
  'reviewer cannot import records'
);

select ok(
  not has_function_privilege(
    'anon',
    'private.record_source_import(jsonb)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.record_source_import(jsonb)',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.record_source_import(jsonb)',
    'execute'
  ),
  'browser and broad API roles cannot execute source import'
);
select ok(
  not has_function_privilege(
    'anon',
    'private.review_source_assertion(uuid,text,uuid,uuid,text)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.review_source_assertion(uuid,text,uuid,uuid,text)',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.review_source_assertion(uuid,text,uuid,uuid,text)',
    'execute'
  ),
  'browser and broad API roles cannot execute source review'
);
select ok(
  not has_function_privilege(
    'anon',
    'private.review_source_record_deletion(uuid,text,text)',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.review_source_record_deletion(uuid,text,text)',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.review_source_record_deletion(uuid,text,text)',
    'execute'
  ),
  'browser and broad API roles cannot review upstream deletions'
);

select ok(
  (
    select prosecdef
    from pg_proc
    where oid = 'private.record_source_import(jsonb)'::regprocedure
  ),
  'source import is a security-definer capability'
);
select ok(
  (
    select array_to_string(proconfig, ',')
    from pg_proc
    where oid = 'private.record_source_import(jsonb)'::regprocedure
  ) like '%search_path=""%',
  'source import has an empty search path'
);
select ok(
  (
    select prosecdef
    from pg_proc
    where oid =
      'private.review_source_assertion(uuid,text,uuid,uuid,text)'::regprocedure
  ),
  'source review is a security-definer capability'
);
select ok(
  (
    select array_to_string(proconfig, ',')
    from pg_proc
    where oid =
      'private.review_source_assertion(uuid,text,uuid,uuid,text)'::regprocedure
  ) like '%search_path=""%',
  'source review has an empty search path'
);

select $batch$
  {
    "sourceId": "synthetic-access-source",
    "startedAt": "2026-07-28T18:00:00.000Z",
    "completedAt": "2026-07-28T18:00:01.000Z",
    "cursor": null,
    "records": [{
      "externalRecordKey": "synthetic-access-record",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "abcdef0123456789abcdef0123456789abcdef0123456789abcdef0123456789",
        "retrievalReference": "https://example.invalid/access-record"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [{
        "kind": "name",
        "subjectExternalKey": "synthetic-access-record",
        "name": "Synthetic access record",
        "language": "en"
      }]
    }],
    "errors": []
  }
$batch$ as access_batch
\gset

set local role source_ingestor;
select
  run_id as first_run_id,
  inserted_records as first_inserted_records,
  inserted_assertions as first_inserted_assertions,
  review_cases as first_review_cases
from private.record_source_import(:'access_batch'::jsonb)
\gset
select
  inserted_records as retry_inserted_records,
  inserted_assertions as retry_inserted_assertions,
  review_cases as retry_review_cases
from private.record_source_import(:'access_batch'::jsonb)
\gset
reset role;

select is(
  :'first_inserted_records'::integer,
  1,
  'first import stores one source record'
);
select is(
  :'first_inserted_assertions'::integer,
  1,
  'first import stores one assertion'
);
select is(
  :'retry_inserted_records'::integer,
  0,
  'identical import retry stores no duplicate record'
);
select is(
  :'retry_inserted_assertions'::integer,
  0,
  'identical import retry stores no duplicate assertion'
);
select is(
  :'retry_review_cases'::integer,
  0,
  'identical import retry stores no duplicate review case'
);

select is(
  (
    select count(*)
    from catalog.source_records
    where source_id = 'synthetic-access-source'
  )::bigint,
  1::bigint,
  'ingestor records one immutable source version'
);
select is(
  (
    select count(*)
    from catalog.normalized_assertions
    where subject_external_key = 'synthetic-access-record'
  )::bigint,
  1::bigint,
  'ingestor records one normalized assertion'
);

select id as access_assertion_id
from catalog.normalized_assertions
where subject_external_key = 'synthetic-access-record'
\gset

set local role source_reviewer;
select private.review_source_assertion(
  :'access_assertion_id'::uuid,
  'accepted',
  '33000000-0000-4000-8000-000000000001',
  null,
  'Synthetic acceptance'
);
reset role;

select is(
  (
    select decision
    from catalog.assertion_reviews
    where assertion_id = (
      select id
      from catalog.normalized_assertions
      where subject_external_key = 'synthetic-access-record'
    )
  ),
  'accepted',
  'reviewer records one accepted decision'
);
select is(
  (
    select count(*)
    from catalog.review_cases
    where assertion_id = (
      select id
      from catalog.normalized_assertions
      where subject_external_key = 'synthetic-access-record'
    )
      and status = 'open'
  )::bigint,
  0::bigint,
  'review decision closes its mapping case'
);

select $batch$
  {
    "sourceId": "synthetic-access-source",
    "startedAt": "2026-07-28T18:05:00.000Z",
    "completedAt": "2026-07-28T18:05:01.000Z",
    "cursor": null,
    "records": [{
      "externalRecordKey": "synthetic-deleted-record",
      "upstreamState": "deleted",
      "retrievedAt": "2026-07-28T18:05:01.000Z",
      "sourceVersion": "fixture-deleted",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef0",
        "retrievalReference": "https://example.invalid/deleted-record"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": []
    }],
    "errors": []
  }
$batch$ as deletion_batch
\gset

set local role source_ingestor;
select *
from private.record_source_import(:'deletion_batch'::jsonb);
reset role;

select id as deletion_record_id
from catalog.source_records
where source_id = 'synthetic-access-source'
  and external_record_key = 'synthetic-deleted-record'
\gset

select is(
  (
    select count(*)
    from catalog.review_cases
    where source_record_id = :'deletion_record_id'::uuid
      and case_kind = 'upstream_record_deleted'
      and status = 'open'
  )::bigint,
  1::bigint,
  'upstream deletion creates one open review case'
);

set local role source_reviewer;
select private.review_source_record_deletion(
  :'deletion_record_id'::uuid,
  'accepted',
  'Synthetic deletion accepted for later publication review'
);
reset role;

select is(
  (
    select status
    from catalog.review_cases
    where source_record_id = :'deletion_record_id'::uuid
      and case_kind = 'upstream_record_deleted'
  ),
  'closed',
  'reviewer closes an upstream deletion case'
);
select is(
  (
    select decision
    from catalog.review_cases
    where source_record_id = :'deletion_record_id'::uuid
      and case_kind = 'upstream_record_deleted'
  ),
  'accepted',
  'deletion review records a decision without deleting public data'
);

select * from finish();
rollback;
