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
