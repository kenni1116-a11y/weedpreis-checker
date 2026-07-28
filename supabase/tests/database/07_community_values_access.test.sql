begin;
select no_plan();

select has_table(
  'private',
  'community_flower_contributions',
  'raw community values have a private table'
);
select has_function(
  'api',
  'get_my_community_flower_contribution',
  array['uuid'],
  'own contribution getter exists'
);
select has_function(
  'api',
  'upsert_my_community_flower_contribution',
  array['uuid', 'numeric', 'numeric', 'text', 'text', 'boolean', 'boolean'],
  'own contribution upsert exists'
);
select has_function(
  'api',
  'delete_my_community_flower_contribution',
  array['uuid'],
  'own contribution delete exists'
);
select has_function(
  'api',
  'export_my_community_flower_contributions',
  'own contribution export exists'
);

insert into private.legal_versions(kind, version, active, effective_at) values
  ('privacy', 'weedypedia-privacy-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('terms', 'weedypedia-terms-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('adult', 'weedypedia-adult-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('community_values', 'weedypedia-community-values-2026-07-28', true, '2026-07-28T00:00:00Z')
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

insert into auth.users(
  id, instance_id, aud, role, email, email_confirmed_at,
  raw_user_meta_data, created_at, updated_at
) values
(
  '70000000-0000-4000-8000-00000000000a',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'community-a@example.invalid', now(),
  '{"registration_username":"Community.A","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
  now(), now()
),
(
  '70000000-0000-4000-8000-00000000000b',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'community-b@example.invalid', now(),
  '{"registration_username":"Community.B","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
  now(), now()
);

insert into catalog.entities(id, kind, canonical_name, published) values
  ('71000000-0000-4000-8000-000000000001', 'cultivar', 'Synthetic Community Flower', true),
  ('71000000-0000-4000-8000-000000000002', 'product', 'Synthetic Community Extract', true),
  ('71000000-0000-4000-8000-000000000003', 'product', 'Synthetic Community Flower Product', true);
insert into api.catalog_references(
  id, kind, canonical_name, canonical_cultivar_id, is_flower
) values
  (
    '71000000-0000-4000-8000-000000000001',
    'cultivar',
    'Synthetic Community Flower',
    '71000000-0000-4000-8000-000000000001',
    false
  ),
  (
    '71000000-0000-4000-8000-000000000002',
    'product',
    'Synthetic Community Extract',
    '71000000-0000-4000-8000-000000000001',
    false
  ),
  (
    '71000000-0000-4000-8000-000000000003',
    'product',
    'Synthetic Community Flower Product',
    '71000000-0000-4000-8000-000000000001',
    true
  );
insert into api.inventory_items(
  id, user_id, entity_id, entry_name, quantity, unit
) values
  (
    '72000000-0000-4000-8000-000000000001',
    '70000000-0000-4000-8000-00000000000a',
    '71000000-0000-4000-8000-000000000003',
    'My Flower',
    2,
    'g'
  ),
  (
    '72000000-0000-4000-8000-000000000002',
    '70000000-0000-4000-8000-00000000000a',
    '71000000-0000-4000-8000-000000000003',
    'Second jar',
    1,
    'g'
  ),
  (
    '72000000-0000-4000-8000-000000000003',
    '70000000-0000-4000-8000-00000000000b',
    '71000000-0000-4000-8000-000000000002',
    'Extract only',
    1,
    'g'
  );

set local role anon;
select throws_ok(
  $$select * from private.community_flower_contributions$$,
  '42501',
  null,
  'anonymous users cannot inspect raw contributions'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-4000-8000-00000000000a","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select throws_ok(
  $$select * from private.community_flower_contributions$$,
  '42501',
  null,
  'authenticated users cannot inspect raw contributions'
);
select lives_ok(
  $$select api.upsert_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001',
      21.30,
      0.70,
      'label',
      'weedypedia-community-values-2026-07-28',
      true,
      true
    )$$,
  'eligible owner can submit one current pair'
);
select is(
  (
    select count(*)
    from api.get_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001'
    )
  )::bigint,
  1::bigint,
  'own getter returns the current row'
);
select lives_ok(
  $$select api.upsert_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001',
      23,
      1,
      'laboratory',
      'weedypedia-community-values-2026-07-28',
      true,
      true
    )$$,
  'second submission replaces the current pair'
);
reset role;

select is(
  (
    select count(*)
    from private.community_flower_contributions
    where user_id = '70000000-0000-4000-8000-00000000000a'
      and cultivar_id = '71000000-0000-4000-8000-000000000001'
  )::bigint,
  1::bigint,
  'one user has one current row per cultivar'
);
select is(
  (
    select thc_percent
    from private.community_flower_contributions
    where user_id = '70000000-0000-4000-8000-00000000000a'
      and cultivar_id = '71000000-0000-4000-8000-000000000001'
  ),
  23.00::numeric,
  'replacement stores the new exact value'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-4000-8000-00000000000b","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select is(
  (
    select count(*)
    from api.get_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001'
    )
  )::bigint,
  0::bigint,
  'another account cannot see the first account contribution'
);
select throws_ok(
  $$select api.upsert_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001',
      20,
      1,
      'label',
      'weedypedia-community-values-2026-07-28',
      true,
      true
    )$$,
  'P0001',
  'Eligible flower inventory is required',
  'non-owner without flower inventory cannot replace another row'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"70000000-0000-4000-8000-00000000000a","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select throws_ok(
  $$select api.upsert_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001',
      70.01,
      0,
      'label',
      'weedypedia-community-values-2026-07-28',
      true,
      true
    )$$,
  '22023',
  'Flower values must be between 0 and 70',
  'server rejects values above 70'
);
select throws_ok(
  $$select api.upsert_my_community_flower_contribution(
      '71000000-0000-4000-8000-000000000001',
      20,
      1,
      'estimate',
      'weedypedia-community-values-2026-07-28',
      true,
      true
    )$$,
  '22023',
  'Label or laboratory source is required',
  'server rejects estimated source kinds'
);
reset role;

delete from api.inventory_items
where id = '72000000-0000-4000-8000-000000000001';
select is(
  (
    select count(*)
    from private.community_flower_contributions
    where user_id = '70000000-0000-4000-8000-00000000000a'
  )::bigint,
  1::bigint,
  'deleting a non-last matching item keeps the contribution'
);
delete from api.inventory_items
where id = '72000000-0000-4000-8000-000000000002';
select is(
  (
    select count(*)
    from private.community_flower_contributions
    where user_id = '70000000-0000-4000-8000-00000000000a'
  )::bigint,
  0::bigint,
  'deleting the last matching item removes the contribution'
);

select * from finish();
rollback;
