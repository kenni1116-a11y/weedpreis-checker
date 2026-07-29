begin;
select no_plan();

select has_table(
  'api',
  'community_flower_averages',
  'privacy-thresholded aggregate table exists'
);
select has_function(
  'private',
  'refresh_community_flower_averages',
  'restricted aggregate refresh exists'
);
select ok(
  not exists (
    select 1
    from information_schema.columns
    where table_schema = 'api'
      and table_name = 'community_flower_averages'
      and column_name in (
        'user_id',
        'exact_count',
        'contributor_count',
        'source_kind',
        'inventory_id'
      )
  ),
  'aggregate exposes no identity, raw source, inventory, or exact count'
);

insert into private.legal_versions(kind, version, active, effective_at) values
  ('privacy', 'weedypedia-privacy-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('terms', 'weedypedia-terms-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('adult', 'weedypedia-adult-2026-07-25', true, '2026-07-25T00:00:00Z'),
  ('community_values', 'weedypedia-community-values-2026-07-28', true, '2026-07-28T00:00:00Z')
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

insert into catalog.entities(id, kind, canonical_name, published) values (
  '81000000-0000-4000-8000-000000000001',
  'cultivar',
  'Synthetic Aggregate Flower',
  true
);
insert into api.catalog_references(
  id, kind, canonical_name, canonical_cultivar_id, is_flower
) values (
  '81000000-0000-4000-8000-000000000001',
  'cultivar',
  'Synthetic Aggregate Flower',
  '81000000-0000-4000-8000-000000000001',
  true
);

insert into auth.users(
  id, instance_id, aud, role, email, email_confirmed_at,
  raw_user_meta_data, created_at, updated_at
)
select
  (
    '82000000-0000-4000-8000-'
    || lpad(series::text, 12, '0')
  )::uuid,
  '00000000-0000-0000-0000-000000000000'::uuid,
  'authenticated',
  'authenticated',
  'aggregate-' || series || '@example.invalid',
  now(),
  jsonb_build_object(
    'registration_username', 'aggregate.' || series,
    'adult_confirmed', true,
    'privacy_version', 'weedypedia-privacy-2026-07-25',
    'terms_version', 'weedypedia-terms-2026-07-25'
  ),
  now(),
  now()
from generate_series(1, 50) as series;

insert into private.community_flower_contributions(
  user_id,
  cultivar_id,
  thc_percent,
  cbd_percent,
  source_kind,
  consent_version
)
select
  (
    '82000000-0000-4000-8000-'
    || lpad(series::text, 12, '0')
  )::uuid,
  '81000000-0000-4000-8000-000000000001',
  20 + series::numeric / 10,
  series::numeric / 100,
  case when series % 2 = 0 then 'label' else 'laboratory' end,
  'weedypedia-community-values-2026-07-28'
from generate_series(1, 4) as series;

select private.refresh_community_flower_averages();
select is(
  (select count(*) from api.community_flower_averages)::bigint,
  0::bigint,
  'four contributors publish no row'
);

insert into private.community_flower_contributions(
  user_id, cultivar_id, thc_percent, cbd_percent, source_kind, consent_version
) values (
  '82000000-0000-4000-8000-000000000005',
  '81000000-0000-4000-8000-000000000001',
  20.5,
  0.05,
  'label',
  'weedypedia-community-values-2026-07-28'
);
select private.refresh_community_flower_averages();
select is(
  (
    select contributor_band
    from api.community_flower_averages
  ),
  '5+',
  'the fifth contributor publishes only the 5+ band'
);
select is(
  (select thc_mean from api.community_flower_averages),
  20.3::numeric,
  'THC mean is rounded to one decimal'
);
select is(
  (select cbd_mean from api.community_flower_averages),
  0.0::numeric,
  'CBD mean is rounded to one decimal'
);

insert into private.community_flower_contributions(
  user_id, cultivar_id, thc_percent, cbd_percent, source_kind, consent_version
)
select
  (
    '82000000-0000-4000-8000-'
    || lpad(series::text, 12, '0')
  )::uuid,
  '81000000-0000-4000-8000-000000000001',
  20,
  1,
  'label',
  'weedypedia-community-values-2026-07-28'
from generate_series(6, 10) as series;
select private.refresh_community_flower_averages();
select is(
  (select contributor_band from api.community_flower_averages),
  '10+',
  'ten contributors publish the 10+ band'
);

insert into private.community_flower_contributions(
  user_id, cultivar_id, thc_percent, cbd_percent, source_kind, consent_version
)
select
  (
    '82000000-0000-4000-8000-'
    || lpad(series::text, 12, '0')
  )::uuid,
  '81000000-0000-4000-8000-000000000001',
  20,
  1,
  'label',
  'weedypedia-community-values-2026-07-28'
from generate_series(11, 25) as series;
select private.refresh_community_flower_averages();
select is(
  (select contributor_band from api.community_flower_averages),
  '25+',
  'twenty-five contributors publish the 25+ band'
);

insert into private.community_flower_contributions(
  user_id, cultivar_id, thc_percent, cbd_percent, source_kind, consent_version
)
select
  (
    '82000000-0000-4000-8000-'
    || lpad(series::text, 12, '0')
  )::uuid,
  '81000000-0000-4000-8000-000000000001',
  20,
  1,
  'label',
  'weedypedia-community-values-2026-07-28'
from generate_series(26, 50) as series;
select private.refresh_community_flower_averages();
select is(
  (select contributor_band from api.community_flower_averages),
  '50+',
  'fifty contributors publish the 50+ band'
);

update private.community_flower_contributions
set thc_percent = 70
where user_id = '82000000-0000-4000-8000-000000000001';
select isnt(
  (select thc_mean from api.community_flower_averages),
  (
    select round(avg(thc_percent), 1)
    from private.community_flower_contributions
  ),
  'raw changes remain delayed until refresh'
);
select private.refresh_community_flower_averages();
select is(
  (select thc_mean from api.community_flower_averages),
  (
    select round(avg(thc_percent), 1)
    from private.community_flower_contributions
  ),
  'refresh atomically replaces the published mean'
);

delete from private.community_flower_contributions
where user_id not in (
  '82000000-0000-4000-8000-000000000001',
  '82000000-0000-4000-8000-000000000002',
  '82000000-0000-4000-8000-000000000003',
  '82000000-0000-4000-8000-000000000004'
);
select private.refresh_community_flower_averages();
select is(
  (select count(*) from api.community_flower_averages)::bigint,
  0::bigint,
  'falling below five removes the published row on refresh'
);

set local role anon;
select throws_ok(
  $$select * from api.community_flower_averages$$,
  '42501',
  null,
  'anonymous users cannot read aggregates'
);
reset role;

select set_config(
  'request.jwt.claims',
  '{"sub":"82000000-0000-4000-8000-000000000001","role":"authenticated","aal":"aal1"}',
  true
);
set local role authenticated;
select lives_ok(
  $$select * from api.community_flower_averages$$,
  'authenticated users can read only the aggregate'
);
select throws_ok(
  $$insert into api.community_flower_averages(
      cultivar_id, thc_mean, cbd_mean, contributor_band, computed_at
    ) values (
      '81000000-0000-4000-8000-000000000001',
      20,
      1,
      '5+',
      now()
    )$$,
  '42501',
  null,
  'browser users cannot write aggregates'
);
select throws_ok(
  $$select private.refresh_community_flower_averages()$$,
  '42501',
  null,
  'browser users cannot execute refresh'
);
reset role;

select * from finish();
rollback;
