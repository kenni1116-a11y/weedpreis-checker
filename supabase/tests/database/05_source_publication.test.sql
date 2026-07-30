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
  'synthetic-publication-source',
  'Synthetic publication source',
  'Synthetic owner',
  'synthetic fixture',
  'manual tests only',
  'approved',
  'https://example.invalid/license',
  false,
  'Synthetic publication attribution',
  'not included',
  'supporting',
  'publication-test-reviewer',
  'inactive'
);

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '51000000-0000-4000-8000-000000000001',
    'cultivar',
    'Placeholder child',
    false
  ),
  (
    '51000000-0000-4000-8000-000000000002',
    'cultivar',
    'Placeholder parent one',
    false
  ),
  (
    '51000000-0000-4000-8000-000000000003',
    'cultivar',
    'Placeholder parent two',
    false
  ),
  (
    '51000000-0000-4000-8000-000000000004',
    'cultivar',
    'Placeholder historical origin',
    false
  ),
  (
    '51000000-0000-4000-8000-000000000005',
    'product',
    'Placeholder product',
    false
  ),
  (
    '51000000-0000-4000-8000-000000000006',
    'cultivar',
    'Unreviewed cultivar',
    false
  );

select $batch$
{
  "contractVersion": 2,
  "sourceId": "synthetic-publication-source",
  "startedAt": "2026-07-28T18:00:00.000Z",
  "completedAt": "2026-07-28T18:00:01.000Z",
  "cursor": null,
  "records": [
    {
      "externalRecordKey": "child",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "1111111111111111111111111111111111111111111111111111111111111111",
        "retrievalReference": "https://example.invalid/child"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [
        {
          "kind": "name",
          "trace": {
            "sourceLocator": "$.synthetic.child.name",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "name": "Synthetic Gorilla Skittlez",
          "language": "en"
        },
        {
          "kind": "alias",
          "trace": {
            "sourceLocator": "$.synthetic.child.aliases[0]",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "name": "Synthetic G-Skittlez",
          "language": "en",
          "aliasType": "market",
          "market": "synthetic-test-market"
        },
        {
          "kind": "alias",
          "trace": {
            "sourceLocator": "$.synthetic.child.aliases[1]",
            "extractionMethod": "manual"
          },
          "subjectExternalKey": "child",
          "name": "Rejected private nickname",
          "language": "en",
          "aliasType": "other",
          "market": null
        },
        {
          "kind": "lineage",
          "trace": {
            "sourceLocator": "$.synthetic.child.lineage[0]",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "relatedExternalKey": "parent-one",
          "relationship": "reported_parent",
          "position": 1
        },
        {
          "kind": "lineage",
          "trace": {
            "sourceLocator": "$.synthetic.child.lineage[1]",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "relatedExternalKey": "parent-two",
          "relationship": "reported_parent",
          "position": 2
        },
        {
          "kind": "lineage",
          "trace": {
            "sourceLocator": "$.synthetic.child.lineage[2]",
            "extractionMethod": "manual"
          },
          "subjectExternalKey": "child",
          "relatedExternalKey": "historical-origin",
          "relationship": "historical_origin",
          "position": null
        },
        {
          "kind": "measurement",
          "trace": {
            "sourceLocator": "$.synthetic.child.measurements[0]",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "analyte": "thc",
          "value": 22.4,
          "unit": "percent",
          "productForm": "flower",
          "batchIdentifier": "SYNTHETIC-PUBLICATION-BATCH-001",
          "measuredAt": "2026-07-27T10:00:00.000Z"
        },
        {
          "kind": "measurement",
          "trace": {
            "sourceLocator": "$.synthetic.child.measurements[1]",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "child",
          "analyte": "cbd",
          "value": 0.8,
          "unit": "percent",
          "productForm": "flower",
          "batchIdentifier": "SYNTHETIC-PUBLICATION-BATCH-001",
          "measuredAt": "2026-07-27T10:00:00.000Z"
        },
        {
          "kind": "measurement",
          "trace": {
            "sourceLocator": "$.synthetic.child.measurements[2]",
            "extractionMethod": "manual"
          },
          "subjectExternalKey": "child",
          "analyte": "thc",
          "value": 71,
          "unit": "percent",
          "productForm": "flower",
          "batchIdentifier": "SYNTHETIC-PUBLICATION-OVER-LIMIT",
          "measuredAt": "2026-07-27T10:00:00.000Z"
        }
      ]
    },
    {
      "externalRecordKey": "parent-one",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "2222222222222222222222222222222222222222222222222222222222222222",
        "retrievalReference": "https://example.invalid/parent-one"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [{
        "kind": "name",
        "trace": {
          "sourceLocator": "$.synthetic.parentOne.name",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "parent-one",
        "name": "Synthetic Gorilla Glue",
        "language": "en"
      }]
    },
    {
      "externalRecordKey": "parent-two",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "3333333333333333333333333333333333333333333333333333333333333333",
        "retrievalReference": "https://example.invalid/parent-two"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [{
        "kind": "name",
        "trace": {
          "sourceLocator": "$.synthetic.parentTwo.name",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "parent-two",
        "name": "Synthetic Skittlez",
        "language": "en"
      }]
    },
    {
      "externalRecordKey": "historical-origin",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "4444444444444444444444444444444444444444444444444444444444444444",
        "retrievalReference": "https://example.invalid/historical-origin"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [{
        "kind": "name",
        "trace": {
          "sourceLocator": "$.synthetic.historicalOrigin.name",
          "extractionMethod": "manual"
        },
        "subjectExternalKey": "historical-origin",
        "name": "Synthetic Afghani",
        "language": "en"
      }]
    },
    {
      "externalRecordKey": "product",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "5555555555555555555555555555555555555555555555555555555555555555",
        "retrievalReference": "http://example.invalid/product"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [
        {
          "kind": "name",
          "trace": {
            "sourceLocator": "$.synthetic.product.name",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "product",
          "name": "Synthetic Gorilla Skittlez 22/1",
          "language": "en"
        },
        {
          "kind": "product_cultivar",
          "trace": {
            "sourceLocator": "$.synthetic.product.cultivar",
            "extractionMethod": "structured"
          },
          "subjectExternalKey": "product",
          "cultivarExternalKey": "child",
          "productForm": "flower"
        }
      ]
    },
    {
      "externalRecordKey": "unreviewed",
      "upstreamState": "present",
      "retrievedAt": "2026-07-28T18:00:01.000Z",
      "sourceVersion": "fixture-1",
      "evidence": {
        "kind": "checksum",
        "algorithm": "sha256",
        "digest": "6666666666666666666666666666666666666666666666666666666666666666",
        "retrievalReference": "https://example.invalid/unreviewed"
      },
      "validFrom": null,
      "validTo": null,
      "assertions": [{
        "kind": "name",
        "trace": {
          "sourceLocator": "$.synthetic.unreviewed.name",
          "extractionMethod": "structured"
        },
        "subjectExternalKey": "unreviewed",
        "name": "Must remain private",
        "language": "en"
      }]
    }
  ],
  "errors": []
}
$batch$ as publication_batch
\gset

set local role source_ingestor;
select * from private.record_source_import(:'publication_batch'::jsonb);
reset role;

select is(
  (
    select count(*)
    from api.catalog_references
    where id between
      '51000000-0000-4000-8000-000000000001'::uuid
      and '51000000-0000-4000-8000-000000000006'::uuid
  ),
  0::bigint,
  'an adapter import alone publishes no public catalog row'
);

select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  null,
  'synthetic canonical review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 1
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  null,
  'synthetic alias review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 2
  ),
  'rejected',
  null,
  null,
  'synthetic rejection'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 3
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  '51000000-0000-4000-8000-000000000002',
  'synthetic parent one review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 4
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  '51000000-0000-4000-8000-000000000003',
  'synthetic parent two review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 5
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  '51000000-0000-4000-8000-000000000004',
  'synthetic historical origin review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 6
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  null,
  'synthetic THC review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'child'
      and assertion.assertion_index = 7
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  null,
  'synthetic CBD review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'parent-one'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000002',
  null,
  'synthetic parent name review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'parent-two'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000003',
  null,
  'synthetic parent name review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'historical-origin'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000004',
  null,
  'synthetic origin name review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'product'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000005',
  null,
  'synthetic product name review'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'product'
      and assertion.assertion_index = 1
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000005',
  '51000000-0000-4000-8000-000000000001',
  'synthetic flower mapping review'
);

select lives_ok(
  $$set local role source_reviewer;
    select private.publish_reviewed_catalog();
    reset role$$,
  'the reviewer can publish an accepted snapshot'
);

select is(
  (
    select canonical_name
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  'Synthetic Gorilla Skittlez',
  'accepted canonical names enter the public projection'
);
select ok(
  (
    select
      preferred_parent_one_name = 'Synthetic Gorilla Glue'
      and preferred_parent_two_name = 'Synthetic Skittlez'
      and has_additional_lineage
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  'two preferred parents and additional lineage are projected'
);
select is(
  (
    select canonical_cultivar_id
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  '51000000-0000-4000-8000-000000000001'::uuid,
  'a cultivar projection identifies itself as the canonical cultivar'
);
select is(
  (
    select is_flower
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  false,
  'a cultivar is not mislabeled as a flower product'
);
select is(
  (
    select sourced_thc_label
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  '22.4 %',
  'reviewed sourced THC remains distinct from community values'
);
select is(
  (
    select sourced_cbd_label
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  '0.8 %',
  'reviewed sourced CBD remains distinct from community values'
);
select ok(
  (
    select
      canonical_cultivar_id =
        '51000000-0000-4000-8000-000000000001'::uuid
      and is_flower
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000005'
  ),
  'the accepted flower product maps to its canonical cultivar'
);
select is(
  (
    select count(*)
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000006'
  ),
  0::bigint,
  'unreviewed names never enter the public projection'
);
select is(
  (
    select count(*)
    from api.search_catalog_references('Rejected private nickname')
  ),
  0::bigint,
  'rejected aliases are not searchable'
);
select ok(
  (
    select
      matched_name = 'Synthetic G-Skittlez'
      and match_reason = 'alias'
      and canonical_name = 'Synthetic Gorilla Skittlez'
    from api.search_catalog_references('Synthetic G-Skittlez')
    limit 1
  ),
  'accepted aliases explain the match without replacing the canonical name'
);
select ok(
  (
    select
      matched_name = 'Synthetic Gorilla Skittlez 22/1'
      and match_reason = 'product'
      and is_flower
    from api.search_catalog_references('Synthetic Gorilla Skittlez 22/1')
    limit 1
  ),
  'accepted products are searchable with an explicit product reason'
);
select ok(
  (
    select
      jsonb_array_length(sourced_value_evidence) >= 1
      and sourced_value_evidence #>> '{0,sourceName}'
        = 'Synthetic publication source'
      and sourced_value_evidence #>> '{0,sourceVersion}' = 'fixture-1'
      and sourced_value_evidence #>> '{0,retrievedAt}'
        = '2026-07-28T18:00:01+00:00'
      and sourced_value_evidence #>> '{0,citationUrl}'
        = 'https://example.invalid/child'
      and sourced_value_evidence #>> '{0,attribution}'
        = 'Synthetic publication attribution'
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  'sourced labels carry public citation metadata'
);
select is(
  (
    select sourced_value_evidence #>> '{0,citationUrl}'
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000005'
  ),
  null,
  'unsafe non-HTTPS retrieval references are not published'
);
select ok(
  exists (
    select 1
    from catalog.review_cases review_case
    join catalog.normalized_assertions assertion
      on assertion.id = review_case.assertion_id
    where review_case.case_kind = 'flower_value_above_70'
      and review_case.status = 'open'
      and assertion.payload ->> 'value' = '71'
  ),
  'a flower value above 70 remains an open review case'
);
select ok(
  (
    select sourced_thc_label not like '%71%'
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  'a flower value above 70 is absent from the public label'
);

select lives_ok(
  $$set local role source_reviewer;
    select private.publish_reviewed_catalog();
    reset role$$,
  'retrying publication is idempotent'
);
select is(
  (
    select count(*)
    from api.search_catalog_references('Synthetic G-Skittlez')
  ),
  1::bigint,
  'idempotent publication creates no duplicate search term'
);

select $conflict$
{
  "contractVersion": 2,
  "sourceId": "synthetic-publication-source",
  "startedAt": "2026-07-28T18:01:00.000Z",
  "completedAt": "2026-07-28T18:01:01.000Z",
  "cursor": null,
  "records": [{
    "externalRecordKey": "conflicting-parent",
    "upstreamState": "present",
    "retrievedAt": "2026-07-28T18:01:01.000Z",
    "sourceVersion": "fixture-conflict",
    "evidence": {
      "kind": "checksum",
      "algorithm": "sha256",
      "digest": "7777777777777777777777777777777777777777777777777777777777777777",
      "retrievalReference": "https://example.invalid/conflicting-parent"
    },
    "validFrom": null,
    "validTo": null,
    "assertions": [{
      "kind": "lineage",
      "trace": {
        "sourceLocator": "$.synthetic.conflict.lineage[0]",
        "extractionMethod": "manual"
      },
      "subjectExternalKey": "child",
      "relatedExternalKey": "parent-two",
      "relationship": "reported_parent",
      "position": 1
    }]
  }],
  "errors": []
}
$conflict$ as conflict_batch
\gset

set local role source_ingestor;
select * from private.record_source_import(:'conflict_batch'::jsonb);
reset role;
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.external_record_key = 'conflicting-parent'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '51000000-0000-4000-8000-000000000001',
  '51000000-0000-4000-8000-000000000003',
  'synthetic conflicting parent'
);

select throws_ok(
  $$set local role source_reviewer;
    select private.publish_reviewed_catalog();
    reset role$$,
  '22023',
  'Invalid catalog snapshot',
  'a deliberately invalid snapshot is rejected'
);
select is(
  (
    select canonical_name
    from api.catalog_references
    where id = '51000000-0000-4000-8000-000000000001'
  ),
  'Synthetic Gorilla Skittlez',
  'failed publication leaves the prior snapshot unchanged'
);

select ok(
  not has_function_privilege(
    'anon',
    'api.search_catalog_references(text)',
    'execute'
  )
  and has_function_privilege(
    'authenticated',
    'api.search_catalog_references(text)',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'api.search_catalog_references(text)',
    'execute'
  ),
  'catalog search is authenticated-only'
);
select ok(
  has_function_privilege(
    'source_reviewer',
    'private.publish_reviewed_catalog()',
    'execute'
  )
  and not has_function_privilege(
    'source_ingestor',
    'private.publish_reviewed_catalog()',
    'execute'
  )
  and not has_function_privilege(
    'anon',
    'private.publish_reviewed_catalog()',
    'execute'
  )
  and not has_function_privilege(
    'authenticated',
    'private.publish_reviewed_catalog()',
    'execute'
  )
  and not has_function_privilege(
    'service_role',
    'private.publish_reviewed_catalog()',
    'execute'
  ),
  'only the reviewer capability can publish a catalog snapshot'
);
select ok(
  (
    select
      procedure.prosecdef
      and array_to_string(procedure.proconfig, ',') like '%search_path=""%'
    from pg_proc procedure
    where procedure.oid =
      'private.publish_reviewed_catalog()'::regprocedure
  ),
  'the publisher is a fixed-path security-definer capability'
);
select ok(
  (
    select
      procedure.prosecdef
      and procedure.provolatile = 's'
      and array_to_string(procedure.proconfig, ',') like '%search_path=""%'
    from pg_proc procedure
    where procedure.oid =
      'api.search_catalog_references(text)'::regprocedure
  ),
  'catalog search is stable and uses a fixed security-definer path'
);
select throws_ok(
  $$set local role anon;
    select * from api.search_catalog_references('Synthetic');
    reset role$$,
  '42501',
  null,
  'anonymous catalog search is denied'
);
select is(
  (
    select count(*)
    from api.search_catalog_references('   ')
  ),
  0::bigint,
  'blank catalog search returns no matches'
);
select is(
  (
    select count(*)
    from api.search_catalog_references(repeat('x', 161))
  ),
  0::bigint,
  'overlong catalog search returns no matches'
);
select cmp_ok(
  (
    select count(*)
    from api.search_catalog_references('Synthetic')
  ),
  '<=',
  8::bigint,
  'catalog search returns no more than eight matches'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'catalog.published_search_terms',
    'select'
  ),
  'authenticated users cannot read internal search terms directly'
);
select ok(
  not has_table_privilege(
    'authenticated',
    'catalog.publication_assertion_staging',
    'select'
  )
  and not has_table_privilege(
    'authenticated',
    'catalog.catalog_reference_staging',
    'select'
  )
  and not has_table_privilege(
    'authenticated',
    'catalog.catalog_term_staging',
    'select'
  )
  and not has_table_privilege(
    'source_reviewer',
    'catalog.publication_assertion_staging',
    'select'
  ),
  'browser and reviewer roles cannot inspect publication staging'
);
select is(
  (
    (select count(*) from catalog.publication_assertion_staging)
    + (select count(*) from catalog.catalog_reference_staging)
    + (select count(*) from catalog.catalog_term_staging)
  ),
  0::bigint,
  'successful publication leaves no staged snapshot rows'
);
select ok(
  not exists (
    select 1
    from information_schema.columns
    where table_schema = 'api'
      and table_name = 'catalog_references'
      and column_name in (
        'raw_payload',
        'reviewer_name',
        'note',
        'confidence_class',
        'source_record_id',
        'assertion_id'
      )
  ),
  'the public projection exposes no source payload or review internals'
);

select * from finish();
rollback;
