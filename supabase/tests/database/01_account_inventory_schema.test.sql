begin;
select no_plan();

select has_schema('private');
select has_schema('catalog');
select has_schema('api');
select has_table('private', 'legal_versions', 'private legal versions table exists');
select has_table('catalog', 'entities', 'internal catalog table exists');
select has_table('api', 'profiles', 'API profiles table exists');
select has_table('api', 'consent_receipts', 'API consent receipts table exists');
select has_table('api', 'catalog_references', 'API catalog references table exists');
select has_table('api', 'inventory_items', 'API inventory table exists');
select col_is_pk('api', 'profiles', 'user_id', 'profile user_id is the primary key');
select col_is_pk('api', 'inventory_items', 'id', 'inventory id is the primary key');
select has_index(
  'private',
  'legal_versions',
  'legal_versions_one_active_per_kind',
  'legal versions enforce one active version per kind'
);
select has_index(
  'api',
  'profiles',
  'profiles_username_normalized_key',
  'normalized usernames are uniquely indexed'
);
select has_index(
  'api',
  'inventory_items',
  'inventory_items_user_id_idx',
  'inventory owner lookups are indexed'
);
select is(
  (
    select count(*)
    from pg_class
    join pg_namespace on pg_namespace.oid = pg_class.relnamespace
    where pg_namespace.nspname = 'api'
      and pg_class.relname in (
        'profiles',
        'consent_receipts',
        'catalog_references',
        'inventory_items'
      )
      and pg_class.relrowsecurity
  )::bigint,
  4::bigint,
  'RLS is enabled on every API table'
);

insert into private.legal_versions(kind, version, active, effective_at) values
  ('privacy', 'weedypedia-privacy-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('terms', 'weedypedia-terms-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('adult', 'weedypedia-adult-2026-07-25', true, '2026-07-25T00:00:00Z')
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

select throws_ok(
  $$insert into private.legal_versions(kind, version, active, effective_at)
    values ('privacy', 'second-active-version', true, now())$$,
  '23505',
  null,
  'only one active version per legal kind is allowed'
);

insert into auth.users(
  id,
  instance_id,
  aud,
  role,
  email,
  email_confirmed_at,
  raw_user_meta_data,
  created_at,
  updated_at
) values (
  '00000000-0000-4000-8000-000000000001',
  '00000000-0000-0000-0000-000000000000',
  'authenticated',
  'authenticated',
  'schema-user@example.invalid',
  now(),
  jsonb_build_object(
    'registration_username', 'Schema.User',
    'adult_confirmed', true,
    'privacy_version', 'weedypedia-privacy-2026-07-25',
    'terms_version', 'weedypedia-terms-2026-07-25'
  ),
  now(),
  now()
);

select is(
  (select count(*) from api.profiles where user_id = '00000000-0000-4000-8000-000000000001')::bigint,
  1::bigint,
  'a valid Auth user creates one profile'
);
select is(
  (select username_normalized from api.profiles where user_id = '00000000-0000-4000-8000-000000000001'),
  'schema.user',
  'username is trimmed and normalized'
);
select is(
  (select count(*) from api.consent_receipts where user_id = '00000000-0000-4000-8000-000000000001')::bigint,
  3::bigint,
  'registration creates privacy, terms, and adult receipts'
);
select is(
  (
    select count(*)
    from information_schema.columns
    where table_schema = 'api' and column_name in ('email', 'email_address')
  )::bigint,
  0::bigint,
  'email is not duplicated into API tables'
);

update auth.users
set raw_user_meta_data = jsonb_build_object(
  'registration_username', 'Changed.Name',
  'adult_confirmed', true,
  'privacy_version', 'weedypedia-privacy-2026-07-25',
  'terms_version', 'weedypedia-terms-2026-07-25'
)
where id = '00000000-0000-4000-8000-000000000001';

select is(
  (select username_normalized from api.profiles where user_id = '00000000-0000-4000-8000-000000000001'),
  'schema.user',
  'later Auth metadata cannot rewrite the profile'
);
select is(
  (select count(*) from api.consent_receipts where user_id = '00000000-0000-4000-8000-000000000001')::bigint,
  3::bigint,
  'later Auth metadata cannot rewrite consent history'
);

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000002',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'minor@example.invalid', now(),
      '{"registration_username":"NotAdult","adult_confirmed":false,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  'P0001',
  'Adult confirmation is required',
  'adult confirmation cannot be bypassed'
);

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000003',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'invalid-name@example.invalid', now(),
      '{"registration_username":"bad name","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  '22023',
  'Invalid username',
  'invalid usernames are rejected'
);

update private.legal_versions
set active = false
where kind = 'privacy';

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000004',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'inactive-privacy@example.invalid', now(),
      '{"registration_username":"InactivePrivacy","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  '22023',
  'Inactive privacy version',
  'inactive privacy wording rejects registration'
);

update private.legal_versions
set active = true
where kind = 'privacy';

update private.legal_versions
set active = false
where kind = 'terms';

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000005',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'inactive-terms@example.invalid', now(),
      '{"registration_username":"InactiveTerms","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  '22023',
  'Inactive terms version',
  'inactive terms wording rejects registration'
);

update private.legal_versions
set active = true
where kind = 'terms';

update private.legal_versions
set active = false
where kind = 'adult';

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000006',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'missing-adult-version@example.invalid', now(),
      '{"registration_username":"MissingAdult","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  '22023',
  'Active adult version is missing',
  'registration requires active server-side adult wording'
);

update private.legal_versions
set active = true
where kind = 'adult';

select throws_ok(
  $$insert into auth.users(
      id, instance_id, aud, role, email, email_confirmed_at,
      raw_user_meta_data, created_at, updated_at
    ) values (
      '00000000-0000-4000-8000-000000000007',
      '00000000-0000-0000-0000-000000000000',
      'authenticated', 'authenticated', 'duplicate-name@example.invalid', now(),
      '{"registration_username":" schema.USER ","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
      now(), now()
    )$$,
  '23505',
  null,
  'normalized usernames remain unique'
);

insert into catalog.entities(id, kind, canonical_name, published) values
  ('10000000-0000-4000-8000-000000000001', 'cultivar', 'Test-Cultivar – keine Echtdaten', true)
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name,
    published = excluded.published;
insert into api.catalog_references(id, kind, canonical_name) values
  ('10000000-0000-4000-8000-000000000001', 'cultivar', 'Test-Cultivar – keine Echtdaten')
on conflict (id) do update
set kind = excluded.kind,
    canonical_name = excluded.canonical_name;

select throws_ok(
  $$insert into api.inventory_items(user_id, entity_id, quantity, unit)
    values (
      '00000000-0000-4000-8000-000000000001',
      '10000000-0000-4000-8000-000000000001',
      0,
      'g'
    )$$,
  '23514',
  null,
  'inventory quantity must be positive'
);

select throws_ok(
  $$insert into api.inventory_items(user_id, entity_id, quantity, unit, note)
    values (
      '00000000-0000-4000-8000-000000000001',
      '10000000-0000-4000-8000-000000000001',
      1,
      'g',
      repeat('x', 1001)
    )$$,
  '23514',
  null,
  'inventory note length is bounded'
);

select * from finish();
rollback;
