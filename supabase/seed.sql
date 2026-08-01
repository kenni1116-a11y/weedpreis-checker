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
  ),
  (
    'community_values',
    'weedypedia-community-values-2026-07-28',
    true,
    '2026-07-28T00:00:00Z'
  )
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

update catalog.sources
set status = 'blocked'
where id = 'synthetic-knowledge-graph-seed-source';

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
    "contractVersion": 2,
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
            "trace": {
              "sourceLocator": "$.synthetic.seedChild.name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-child",
            "name": "Test-Cultivar – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "alias",
            "trace": {
              "sourceLocator": "$.synthetic.seedChild.aliases[0]",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-child",
            "name": "Test-Hybrid – keine Echtdaten",
            "language": "de",
            "aliasType": "other",
            "market": null
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.synthetic.seedChild.lineage[0]",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-child",
            "relatedExternalKey": "seed-parent-a",
            "relationship": "reported_parent",
            "position": 1
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.synthetic.seedChild.lineage[1]",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-child",
            "relatedExternalKey": "seed-parent-b",
            "relationship": "reported_parent",
            "position": 2
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.synthetic.seedChild.lineage[2]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-child",
            "relatedExternalKey": "seed-additional-origin",
            "relationship": "selection_from",
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
          "trace": {
            "sourceLocator": "$.synthetic.seedParentA.name",
            "extractionMethod": "structured"
          },
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
          "trace": {
            "sourceLocator": "$.synthetic.seedParentB.name",
            "extractionMethod": "structured"
          },
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
          "trace": {
            "sourceLocator": "$.synthetic.seedAdditionalOrigin.name",
            "extractionMethod": "manual"
          },
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
            "trace": {
              "sourceLocator": "$.synthetic.seedProduct.name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-product",
            "name": "Testprodukt – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "product_cultivar",
            "trace": {
              "sourceLocator": "$.synthetic.seedProduct.cultivar",
              "extractionMethod": "structured"
            },
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

select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetische kanonische Testangabe'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetischer Testalias'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetische erste Elternangabe'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetische zweite Elternangabe'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetische zusätzliche Herkunft'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetischer Elternname'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetischer Elternname'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetischer Herkunftsname'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetischer Produktname'
);
select private.review_knowledge_assertion(
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
  'single_source',
  'Synthetische Blütenzuordnung'
);

set role source_reviewer;
select private.publish_reviewed_catalog();
reset role;

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
  'synthetic-knowledge-graph-seed-source',
  'Synthetische Wissensgraph-Seedquelle',
  'Weedypedia-Testfixture',
  'Lokale synthetische Fixture',
  'Nur manuell in Tests',
  'approved',
  'https://example.invalid/synthetic-knowledge-graph-seed-license',
  true,
  'Synthetische Wissensgraph-Testdaten – keine Echtdaten',
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

insert into catalog.entities(id, kind, canonical_name, published) values
  (
    '62000000-0000-4000-8000-000000000101',
    'origin_population',
    'Seed-Herkunftspopulation – keine Echtdaten',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000102',
    'cultivar',
    'Seed-Elternsorte – keine Echtdaten',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000103',
    'cultivar',
    'Seed-Kindsorte – keine Echtdaten',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000104',
    'genetic_sample',
    'Seed-Probe Eins – keine Echtdaten',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000105',
    'genetic_sample',
    'Seed-Probe Zwei – keine Echtdaten',
    false
  ),
  (
    '62000000-0000-4000-8000-000000000106',
    'product',
    'Seed-Medizinprodukt – keine Echtdaten',
    false
  )
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name,
    published = excluded.published;

set role source_ingestor;
select *
from private.record_source_import(
  $seed_graph$
  {
    "contractVersion": 2,
    "sourceId": "synthetic-knowledge-graph-seed-source",
    "startedAt": "2026-07-30T11:00:00.000Z",
    "completedAt": "2026-07-30T11:00:06.000Z",
    "cursor": null,
    "records": [
      {
        "externalRecordKey": "seed-graph-origin",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:01.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b101010101010101010101010101010101010101010101010101010101010101",
          "retrievalReference": "https://example.invalid/seed-graph-origin"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[0].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-origin",
            "entityKind": "origin_population"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[0].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-origin",
            "name": "Seed-Herkunftspopulation – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "traditional_classification",
            "trace": {
              "sourceLocator": "$.seedGraph.records[0].classification",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-origin",
            "classification": "sativa"
          },
          {
            "kind": "origin_region",
            "trace": {
              "sourceLocator": "$.seedGraph.records[0].region",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-origin",
            "regionName": "Synthetisches Hochland",
            "regionCode": null
          },
          {
            "kind": "era",
            "trace": {
              "sourceLocator": "$.seedGraph.records[0].era",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-origin",
            "startYear": -1200,
            "endYear": -800,
            "label": "Synthetische historische Epoche"
          }
        ]
      },
      {
        "externalRecordKey": "seed-graph-parent",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:02.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b202020202020202020202020202020202020202020202020202020202020202",
          "retrievalReference": "https://example.invalid/seed-graph-parent"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[1].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-parent",
            "entityKind": "cultivar"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[1].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-parent",
            "name": "Seed-Elternsorte – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "alias",
            "trace": {
              "sourceLocator": "$.seedGraph.records[1].aliases[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-parent",
            "name": "Seed-Elternalias – keine Echtdaten",
            "language": "de",
            "aliasType": "other",
            "market": null
          }
        ]
      },
      {
        "externalRecordKey": "seed-graph-child",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:03.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b303030303030303030303030303030303030303030303030303030303030303",
          "retrievalReference": "https://example.invalid/seed-graph-child"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[2].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-child",
            "entityKind": "cultivar"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[2].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-child",
            "name": "Seed-Kindsorte – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.seedGraph.records[2].lineage[0]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-child",
            "relatedExternalKey": "seed-graph-parent",
            "relationship": "reported_parent",
            "position": 1
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.seedGraph.records[2].lineage[1]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-child",
            "relatedExternalKey": "seed-graph-origin",
            "relationship": "population_membership",
            "position": null
          },
          {
            "kind": "lineage",
            "trace": {
              "sourceLocator": "$.seedGraph.records[2].lineage[2]",
              "extractionMethod": "manual"
            },
            "subjectExternalKey": "seed-graph-child",
            "relatedExternalKey": null,
            "relationship": "unknown_parent",
            "position": 2
          }
        ]
      },
      {
        "externalRecordKey": "seed-graph-sample-one",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:04.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b404040404040404040404040404040404040404040404040404040404040404",
          "retrievalReference": "https://example.invalid/seed-graph-sample-one"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[3].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-one",
            "entityKind": "genetic_sample"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[3].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-one",
            "name": "Seed-Probe Eins – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "sample_reference",
            "trace": {
              "sourceLocator": "$.seedGraph.records[3].sample",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-one",
            "sampleIdentifier": "SEED-SYN-001",
            "datasetName": "Synthetischer Seed-Datensatz",
            "datasetVersion": "1.0",
            "submitter": null,
            "laboratory": "Synthetisches Seed-Labor",
            "sampledAt": "2026-07-01T00:00:00.000Z"
          },
          {
            "kind": "genetic_relation",
            "trace": {
              "sourceLocator": "$.seedGraph.records[3].relations[0]",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-one",
            "relatedExternalKey": "seed-graph-sample-two",
            "relationship": "genetic_similarity",
            "method": "synthetische-seed-methode",
            "datasetName": "Synthetischer Seed-Datensatz",
            "datasetVersion": "1.0",
            "metricName": "synthetische-aehnlichkeit",
            "value": 0.875,
            "unit": "score"
          }
        ]
      },
      {
        "externalRecordKey": "seed-graph-sample-two",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:05.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b505050505050505050505050505050505050505050505050505050505050505",
          "retrievalReference": "https://example.invalid/seed-graph-sample-two"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[4].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-two",
            "entityKind": "genetic_sample"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[4].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-two",
            "name": "Seed-Probe Zwei – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "sample_reference",
            "trace": {
              "sourceLocator": "$.seedGraph.records[4].sample",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-sample-two",
            "sampleIdentifier": "SEED-SYN-002",
            "datasetName": "Synthetischer Seed-Datensatz",
            "datasetVersion": "1.0",
            "submitter": null,
            "laboratory": "Synthetisches Seed-Labor",
            "sampledAt": "2026-07-02T00:00:00.000Z"
          }
        ]
      },
      {
        "externalRecordKey": "seed-graph-product",
        "upstreamState": "present",
        "retrievedAt": "2026-07-30T11:00:06.000Z",
        "sourceVersion": "synthetic-seed-graph-1",
        "evidence": {
          "kind": "checksum",
          "algorithm": "sha256",
          "digest": "b606060606060606060606060606060606060606060606060606060606060606",
          "retrievalReference": "https://example.invalid/seed-graph-product"
        },
        "validFrom": null,
        "validTo": null,
        "assertions": [
          {
            "kind": "entity_kind",
            "trace": {
              "sourceLocator": "$.seedGraph.records[5].kind",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-product",
            "entityKind": "product"
          },
          {
            "kind": "name",
            "trace": {
              "sourceLocator": "$.seedGraph.records[5].name",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-product",
            "name": "Seed-Medizinprodukt – keine Echtdaten",
            "language": "de"
          },
          {
            "kind": "product_cultivar",
            "trace": {
              "sourceLocator": "$.seedGraph.records[5].cultivar",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-product",
            "cultivarExternalKey": "seed-graph-child",
            "productForm": "flower"
          },
          {
            "kind": "product_market",
            "trace": {
              "sourceLocator": "$.seedGraph.records[5].market",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-product",
            "countryCode": "DE",
            "medical": true
          },
          {
            "kind": "measurement",
            "trace": {
              "sourceLocator": "$.seedGraph.records[5].measurement.thc",
              "extractionMethod": "structured"
            },
            "subjectExternalKey": "seed-graph-product",
            "analyte": "thc",
            "value": 20.5,
            "unit": "percent",
            "productForm": "flower",
            "batchIdentifier": "SEED-SYN-BATCH-001",
            "measuredAt": "2026-07-30T00:00:00.000Z"
          }
        ]
      }
    ],
    "errors": []
  }
  $seed_graph$::jsonb
);
reset role;

select private.review_knowledge_assertion(
  assertion.id,
  'accepted',
  review.entity_id,
  review.related_entity_id,
  review.evidence_status,
  'Explizite synthetische Seed-Prüfung'
)
from (
  values
    ('seed-graph-origin', 0, '62000000-0000-4000-8000-000000000101'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-origin', 1, '62000000-0000-4000-8000-000000000101'::uuid, null::uuid, 'single_source'),
    ('seed-graph-origin', 2, '62000000-0000-4000-8000-000000000101'::uuid, null::uuid, 'historical'),
    ('seed-graph-origin', 3, '62000000-0000-4000-8000-000000000101'::uuid, null::uuid, 'historical'),
    ('seed-graph-origin', 4, '62000000-0000-4000-8000-000000000101'::uuid, null::uuid, 'retracted'),
    ('seed-graph-parent', 0, '62000000-0000-4000-8000-000000000102'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-parent', 1, '62000000-0000-4000-8000-000000000102'::uuid, null::uuid, 'single_source'),
    ('seed-graph-parent', 2, '62000000-0000-4000-8000-000000000102'::uuid, null::uuid, 'single_source'),
    ('seed-graph-child', 0, '62000000-0000-4000-8000-000000000103'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-child', 1, '62000000-0000-4000-8000-000000000103'::uuid, null::uuid, 'single_source'),
    ('seed-graph-child', 2, '62000000-0000-4000-8000-000000000103'::uuid, '62000000-0000-4000-8000-000000000102'::uuid, 'single_source'),
    ('seed-graph-child', 3, '62000000-0000-4000-8000-000000000103'::uuid, '62000000-0000-4000-8000-000000000101'::uuid, 'historical'),
    ('seed-graph-child', 4, '62000000-0000-4000-8000-000000000103'::uuid, null::uuid, 'unknown'),
    ('seed-graph-sample-one', 0, '62000000-0000-4000-8000-000000000104'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-sample-one', 1, '62000000-0000-4000-8000-000000000104'::uuid, null::uuid, 'single_source'),
    ('seed-graph-sample-one', 2, '62000000-0000-4000-8000-000000000104'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-sample-one', 3, '62000000-0000-4000-8000-000000000104'::uuid, '62000000-0000-4000-8000-000000000105'::uuid, 'confirmed'),
    ('seed-graph-sample-two', 0, '62000000-0000-4000-8000-000000000105'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-sample-two', 1, '62000000-0000-4000-8000-000000000105'::uuid, null::uuid, 'single_source'),
    ('seed-graph-sample-two', 2, '62000000-0000-4000-8000-000000000105'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-product', 0, '62000000-0000-4000-8000-000000000106'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-product', 1, '62000000-0000-4000-8000-000000000106'::uuid, null::uuid, 'single_source'),
    ('seed-graph-product', 2, '62000000-0000-4000-8000-000000000106'::uuid, '62000000-0000-4000-8000-000000000103'::uuid, 'confirmed'),
    ('seed-graph-product', 3, '62000000-0000-4000-8000-000000000106'::uuid, null::uuid, 'confirmed'),
    ('seed-graph-product', 4, '62000000-0000-4000-8000-000000000106'::uuid, null::uuid, 'single_source')
) as review(
  external_record_key,
  assertion_index,
  entity_id,
  related_entity_id,
  evidence_status
)
join catalog.source_records as record
  on record.source_id = 'synthetic-knowledge-graph-seed-source'
 and record.external_record_key = review.external_record_key
join catalog.normalized_assertions as assertion
  on assertion.source_record_id = record.id
 and assertion.assertion_index = review.assertion_index;

update catalog.sources
set status = 'blocked'
where id = 'synthetic-knowledge-graph-seed-source';
