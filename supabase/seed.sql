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
    true
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'product',
    'Testprodukt – keine Echtdaten',
    true
  )
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name,
    published = excluded.published;

insert into api.catalog_references(id, kind, canonical_name) values
  (
    '10000000-0000-4000-8000-000000000001',
    'cultivar',
    'Test-Cultivar – keine Echtdaten'
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'product',
    'Testprodukt – keine Echtdaten'
  )
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name;

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
