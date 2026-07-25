begin;
select no_plan();

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
) values
(
  '00000000-0000-4000-8000-00000000000a',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'user-a@example.invalid', now(),
  '{"registration_username":"User.A","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
  now(), now()
),
(
  '00000000-0000-4000-8000-00000000000b',
  '00000000-0000-0000-0000-000000000000',
  'authenticated', 'authenticated', 'user-b@example.invalid', now(),
  '{"registration_username":"User.B","adult_confirmed":true,"privacy_version":"weedypedia-privacy-2026-07-25","terms_version":"weedypedia-terms-2026-07-25"}',
  now(), now()
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
insert into api.inventory_items(id, user_id, entity_id, quantity, unit) values
  (
    '20000000-0000-4000-8000-000000000001',
    '00000000-0000-4000-8000-00000000000a',
    '10000000-0000-4000-8000-000000000001',
    3.5,
    'g'
  );

set local role anon;
select throws_ok(
  $$select * from api.profiles$$,
  '42501',
  null,
  'anonymous users cannot read profiles'
);
select throws_ok(
  $$select * from api.inventory_items$$,
  '42501',
  null,
  'anonymous users cannot read inventory'
);
select throws_ok(
  $$select * from api.consent_receipts$$,
  '42501',
  null,
  'anonymous users cannot read consent receipts'
);
select throws_ok(
  $$select * from api.catalog_references$$,
  '42501',
  null,
  'anonymous users cannot read catalog references'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000b","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;

select is(
  (select count(*) from api.profiles)::bigint,
  1::bigint,
  'user B reads only their own profile'
);
select is(
  (select count(*) from api.consent_receipts)::bigint,
  3::bigint,
  'user B reads only their own consent receipts'
);
select is(
  (select count(*) from api.inventory_items)::bigint,
  0::bigint,
  'user B cannot read user A inventory'
);
select is(
  (select count(*) from api.catalog_references)::bigint,
  2::bigint,
  'authenticated users can read all seeded catalog references'
);
select throws_ok(
  $$select * from private.legal_versions$$,
  '42501',
  null,
  'browser roles cannot resolve private legal versions'
);
select throws_ok(
  $$select * from catalog.entities$$,
  '42501',
  null,
  'browser roles cannot resolve catalog internals'
);
select throws_ok(
  $$update api.profiles
    set username = 'Changed'
    where user_id = '00000000-0000-4000-8000-00000000000b'$$,
  '42501',
  null,
  'browser roles cannot update profiles'
);
select throws_ok(
  $$insert into api.consent_receipts(user_id, kind, version, accepted_at)
    values (
      '00000000-0000-4000-8000-00000000000b',
      'privacy',
      'browser-write',
      now()
    )$$,
  '42501',
  null,
  'browser roles cannot append consent receipts'
);

update api.inventory_items
set note = 'cross-user update'
where id = '20000000-0000-4000-8000-000000000001';
delete from api.inventory_items
where id = '20000000-0000-4000-8000-000000000001';

reset role;
select is(
  (
    select count(*)
    from api.inventory_items
    where id = '20000000-0000-4000-8000-000000000001'
      and note is null
  )::bigint,
  1::bigint,
  'cross-user update and delete affect no rows'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select is(
  (select count(*) from api.inventory_items)::bigint,
  1::bigint,
  'user A reads their own inventory'
);
update api.inventory_items
set note = 'owner update'
where id = '20000000-0000-4000-8000-000000000001';
reset role;

select is(
  (
    select note
    from api.inventory_items
    where id = '20000000-0000-4000-8000-000000000001'
  ),
  'owner update',
  'the owner can update their inventory'
);

insert into auth.mfa_factors(
  id,
  user_id,
  friendly_name,
  factor_type,
  status,
  created_at,
  updated_at,
  secret
) values (
  '30000000-0000-4000-8000-000000000001',
  '00000000-0000-4000-8000-00000000000a',
  'Test TOTP',
  'totp',
  'verified',
  now(),
  now(),
  'TESTSECRET'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select is(
  (select count(*) from api.profiles)::bigint,
  0::bigint,
  'AAL1 cannot read a profile after verified TOTP enrollment'
);
select is(
  (select count(*) from api.consent_receipts)::bigint,
  0::bigint,
  'AAL1 cannot read consent receipts after verified TOTP enrollment'
);
select is(
  (select count(*) from api.inventory_items)::bigint,
  0::bigint,
  'AAL1 cannot read inventory after verified TOTP enrollment'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"00000000-0000-4000-8000-00000000000a","role":"authenticated","aal":"aal2"}',
  true
);
set local role authenticated;
select is(
  (select count(*) from api.profiles)::bigint,
  1::bigint,
  'AAL2 can read the protected profile'
);
select is(
  (select count(*) from api.consent_receipts)::bigint,
  3::bigint,
  'AAL2 can read protected consent receipts'
);
select is(
  (select count(*) from api.inventory_items)::bigint,
  1::bigint,
  'AAL2 can read protected inventory'
);
reset role;

select * from finish();
rollback;
