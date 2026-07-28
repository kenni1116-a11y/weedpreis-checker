insert into private.legal_versions(kind, version, active, effective_at) values
  (
    'privacy',
    'weedypedia-privacy-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  ),
  (
    'terms',
    'weedypedia-terms-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  ),
  (
    'adult',
    'weedypedia-adult-2026-07-25',
    true,
    '2026-07-25T00:00:00Z'
  )
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '10000000-0000-4000-8000-000000000001',
    'cultivar',
    'Test-Cultivar – keine Echtdaten',
    false
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'product',
    'Testprodukt – keine Echtdaten',
    false
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    'cultivar',
    'Test-Ursprung A – keine Echtdaten',
    false
  ),
  (
    '10000000-0000-4000-8000-000000000004',
    'cultivar',
    'Test-Ursprung B – keine Echtdaten',
    false
  ),
  (
    '10000000-0000-4000-8000-000000000005',
    'cultivar',
    'Test-Zusatzherkunft – keine Echtdaten',
    false
  )
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name,
    published = excluded.published;

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
  'synthetic-contract-source',
  'Synthetische Vertragsquelle',
  'Weedypedia-Testfixture',
  'Lokale synthetische Fixture',
  'Nur manuell in Tests',
  'approved',
  'https://example.invalid/synthetic-license',
  true,
  'Synthetische Testdaten – keine Echtdaten',
  'Keine Bilder enthalten',
  'discovery',
  'Lokale Testprüfung',
  'inactive'
)
on conflict (id) do update
set display_name = excluded.display_name,
    owner_name = excluded.owner_name,
    access_method = excluded.access_method,
    permitted_frequency = excluded.permitted_frequency,
    license_status = excluded.license_status,
    license_reference = excluded.license_reference,
    raw_storage_allowed = excluded.raw_storage_allowed,
    attribution_rules = excluded.attribution_rules,
    image_rights_status = excluded.image_rights_status,
    confidence_class = excluded.confidence_class,
    responsible_reviewer = excluded.responsible_reviewer,
    status = excluded.status;

set role source_ingestor;
select *
from private.record_source_import(
  $seed$
  {
    "sourceId": "synthetic-contract-source",
    "startedAt": "2026-07-28T12:00:00.000Z",
    "completedAt": "2026-07-28T12:00:01.000Z",
    "cursor": null,
    "records": [
      {
        "externalRecordKey": "seed-child",
        "upstreamState": "present",
        "retrievedAt": "2026-07-28T12:00:01.000Z",
        "sourceVersion": "synthetic-seed-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "a111111111111111111111111111111111111111111111111111111111111111",
          "retrievalReference": "https://example.invalid/seed-child"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "name",
            "subjectExternalKey": "seed-child",
            "name": "Test-Cultivar – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "alias",
            "subjectExternalKey": "seed-child",
            "name": "Test-Hybrid – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "lineage",
            "subjectExternalKey": "seed-child",
            "parentExternalKey": "seed-parent-a",
            "relationship": "reported_parent",
            "position": 1
          },
          {
            "kind": "lineage",
            "subjectExternalKey": "seed-child",
            "parentExternalKey": "seed-parent-b",
            "relationship": "reported_parent",
            "position": 2
          },
          {
            "kind": "lineage",
            "subjectExternalKey": "seed-child",
            "parentExternalKey": "seed-additional-origin",
            "relationship": "historical_origin",
            "position": null
          }
        ]
      },
      {
        "externalRecordKey": "seed-parent-a",
        "upstreamState": "present",
        "retrievedAt": "2026-07-28T12:00:01.000Z",
        "sourceVersion": "synthetic-seed-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "a222222222222222222222222222222222222222222222222222222222222222",
          "retrievalReference": "https://example.invalid/seed-parent-a"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [{
          "kind": "name",
          "subjectExternalKey": "seed-parent-a",
          "name": "Test-Ursprung A – keine Echtdaten",
          "language": "de"
        }]
      },
      {
        "externalRecordKey": "seed-parent-b",
        "upstreamState": "present",
        "retrievedAt": "2026-07-28T12:00:01.000Z",
        "sourceVersion": "synthetic-seed-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "a333333333333333333333333333333333333333333333333333333333333333",
          "retrievalReference": "https://example.invalid/seed-parent-b"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [{
          "kind": "name",
          "subjectExternalKey": "seed-parent-b",
          "name": "Test-Ursprung B – keine Echtdaten",
          "language": "de"
        }]
      },
      {
        "externalRecordKey": "seed-additional-origin",
        "upstreamState": "present",
        "retrievedAt": "2026-07-28T12:00:01.000Z",
        "sourceVersion": "synthetic-seed-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "a444444444444444444444444444444444444444444444444444444444444444",
          "retrievalReference": "https://example.invalid/seed-additional-origin"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [{
          "kind": "name",
          "subjectExternalKey": "seed-additional-origin",
          "name": "Test-Zusatzherkunft – keine Echtdaten",
          "language": "de"
        }]
      },
      {
        "externalRecordKey": "seed-product",
        "upstreamState": "present",
        "retrievedAt": "2026-07-28T12:00:01.000Z",
        "sourceVersion": "synthetic-seed-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "a555555555555555555555555555555555555555555555555555555555555555",
          "retrievalReference": "https://example.invalid/seed-product"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "name",
            "subjectExternalKey": "seed-product",
            "name": "Testprodukt – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "product_cultivar",
            "subjectExternalKey": "seed-product",
            "cultivarExternalKey": "seed-child",
            "productForm": "flower"
          }
        ]
      }
    ],
    "errors": []
  }
  $seed$::jsonb
);
reset role;

select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-child'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000001',
  null,
  'Synthetische kanonische Testangabe'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-child'
      and assertion.assertion_index = 1
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000001',
  null,
  'Synthetischer Testalias'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-child'
      and assertion.assertion_index = 2
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000003',
  'Synthetische erste Elternangabe'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-child'
      and assertion.assertion_index = 3
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000004',
  'Synthetische zweite Elternangabe'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-child'
      and assertion.assertion_index = 4
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000001',
  '10000000-0000-4000-8000-000000000005',
  'Synthetische zusätzliche Herkunft'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-parent-a'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000003',
  null,
  'Synthetischer Elternname'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-parent-b'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000004',
  null,
  'Synthetischer Elternname'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-additional-origin'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000005',
  null,
  'Synthetischer Herkunftsname'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-product'
      and assertion.assertion_index = 0
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000002',
  null,
  'Synthetischer Produktname'
);
select private.review_source_assertion(
  (
    select assertion.id
    from catalog.normalized_assertions assertion
    join catalog.source_records record
      on record.id = assertion.source_record_id
    where record.source_id = 'synthetic-contract-source'
      and record.external_record_key = 'seed-product'
      and assertion.assertion_index = 1
  ),
  'accepted',
  '10000000-0000-4000-8000-000000000002',
  '10000000-0000-4000-8000-000000000001',
  'Synthetische Blütenzuordnung'
);

set role source_reviewer;
select private.publish_reviewed_catalog();
reset role;
