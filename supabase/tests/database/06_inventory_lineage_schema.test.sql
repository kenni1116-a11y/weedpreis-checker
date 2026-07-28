begin;
select no_plan();

select has_column(
  'api',
  'inventory_items',
  'entry_name',
  'inventory stores the user-entered name'
);
select has_column(
  'api',
  'inventory_items',
  'canonical_cultivar_id',
  'inventory stores a server-derived cultivar'
);
select has_column(
  'api',
  'inventory_items',
  'is_flower',
  'inventory stores server-derived flower eligibility'
);
select has_column(
  'api',
  'inventory_items',
  'origin_one_name',
  'inventory stores the first private origin'
);
select has_column(
  'api',
  'inventory_items',
  'origin_two_name',
  'inventory stores the second private origin'
);
select col_not_null(
  'api',
  'inventory_items',
  'entry_name',
  'inventory entry name is required'
);
select col_not_null(
  'api',
  'inventory_items',
  'is_flower',
  'flower eligibility is always explicit'
);
select col_is_null(
  'api',
  'inventory_items',
  'entity_id',
  'catalog reference is optional'
);

insert into private.legal_versions(kind, version, active, effective_at) values
  ('privacy', 'weedypedia-privacy-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('terms', 'weedypedia-terms-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('adult', 'weedypedia-adult-2026-07-25', true, '2026-07-25T00:00:00Z')
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

insert into auth.users(
  id, instance_id, aud, role, email, email_confirmed_at,
  raw_user_meta_data, created_at, updated_at
) values (
  '60000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'lineage@example.invalid', now(),
  '{"registration_username":"Lineage.User","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
  now(), now()
);

insert into catalog.entities(id, kind, canonical_name, published) values
  ('61000000-0000-4000-8000-000000000001', 'cultivar', 'Synthetic Flower', true),
  ('61000000-0000-4000-8000-000000000002', 'product', 'Synthetic Flower Product', true),
  ('61000000-0000-4000-8000-000000000003', 'product', 'Synthetic Extract', true);

insert into api.catalog_references(
  id,
  kind,
  canonical_name,
  canonical_cultivar_id,
  is_flower
) values
  (
    '61000000-0000-4000-8000-000000000001',
    'cultivar',
    'Synthetic Flower',
    '61000000-0000-4000-8000-000000000001',
    true
  ),
  (
    '61000000-0000-4000-8000-000000000002',
    'product',
    'Synthetic Flower Product',
    '61000000-0000-4000-8000-000000000001',
    true
  ),
  (
    '61000000-0000-4000-8000-000000000003',
    'product',
    'Synthetic Extract',
    '61000000-0000-4000-8000-000000000001',
    false
  );

insert into api.inventory_items(
  id,
  user_id,
  entity_id,
  entry_name,
  origin_one_name,
  origin_two_name,
  quantity,
  unit
) values
  (
    '62000000-0000-4000-8000-000000000001',
    '60000000-0000-4000-8000-000000000001',
    '61000000-0000-4000-8000-000000000001',
    'Synthetic Alias',
    'Private Parent One',
    'Private Parent Two',
    3.5,
    'g'
  ),
  (
    '62000000-0000-4000-8000-000000000002',
    '60000000-0000-4000-8000-000000000001',
    null,
    'Unmatched private text',
    null,
    null,
    1,
    'g'
  ),
  (
    '62000000-0000-4000-8000-000000000003',
    '60000000-0000-4000-8000-000000000001',
    '61000000-0000-4000-8000-000000000002',
    'Flower product label',
    null,
    null,
    2,
    'g'
  ),
  (
    '62000000-0000-4000-8000-000000000004',
    '60000000-0000-4000-8000-000000000001',
    '61000000-0000-4000-8000-000000000003',
    'Extract product label',
    null,
    null,
    2,
    'g'
  );

select is(
  (
    select entry_name
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000001'
  ),
  'Synthetic Alias',
  'matched alias spelling remains private inventory text'
);
select is(
  (
    select canonical_cultivar_id
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000001'
  ),
  '61000000-0000-4000-8000-000000000001'::uuid,
  'cultivar maps to itself server-side'
);
select ok(
  (
    select is_flower
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000003'
  ),
  'mapped flower product is flower eligible'
);
select ok(
  not (
    select is_flower
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000004'
  ),
  'non-flower product is not eligible'
);
select is(
  (
    select canonical_cultivar_id
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000002'
  ),
  null::uuid,
  'free text has no canonical cultivar'
);
select ok(
  not (
    select is_flower
    from api.inventory_items
    where id = '62000000-0000-4000-8000-000000000002'
  ),
  'free text cannot become flower eligible'
);

select throws_ok(
  $$insert into api.inventory_items(
      user_id, entity_id, entry_name, quantity, unit
    ) values (
      '60000000-0000-4000-8000-000000000001',
      null,
      repeat('x', 161),
      1,
      'g'
    )$$,
  '23514',
  null,
  'entry name is limited to 160 characters'
);
select throws_ok(
  $$insert into api.inventory_items(
      user_id, entity_id, entry_name, origin_one_name, quantity, unit
    ) values (
      '60000000-0000-4000-8000-000000000001',
      null,
      'Private',
      repeat('x', 161),
      1,
      'g'
    )$$,
  '23514',
  null,
  'private origins are limited to 160 characters'
);

select ok(
  not has_column_privilege(
    'authenticated',
    'api.inventory_items',
    'canonical_cultivar_id',
    'INSERT'
  ),
  'browser cannot insert canonical cultivar mapping'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'api.inventory_items',
    'is_flower',
    'UPDATE'
  ),
  'browser cannot update flower eligibility'
);
select ok(
  not has_column_privilege(
    'authenticated',
    'api.inventory_items',
    'user_id',
    'INSERT'
  ),
  'browser cannot insert an inventory owner'
);

update api.inventory_items
set entry_name = 'Changed private name',
    origin_one_name = 'Changed private origin'
where id = '62000000-0000-4000-8000-000000000001';

select is(
  (
    select canonical_name
    from api.catalog_references
    where id = '61000000-0000-4000-8000-000000000001'
  ),
  'Synthetic Flower',
  'private text never mutates the public catalog'
);

select * from finish();
rollback;
