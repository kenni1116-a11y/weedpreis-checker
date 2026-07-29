-- Remote staging version: 20260729183603; original version: 20260728214423.
alter table private.legal_versions
  drop constraint legal_versions_kind_check;

alter table private.legal_versions
  add constraint legal_versions_kind_check
  check (kind in ('privacy', 'terms', 'adult', 'community_values'));

insert into private.legal_versions(kind, version, active, effective_at)
values (
  'community_values',
  'weedypedia-community-values-2026-07-28',
  true,
  '2026-07-28T00:00:00Z'
)
on conflict (kind, version) do update
set active = excluded.active,
    effective_at = excluded.effective_at;

alter table api.inventory_items
  add column entry_name text,
  add column origin_one_name text,
  add column origin_two_name text,
  add column canonical_cultivar_id uuid
    references catalog.entities(id) on delete restrict,
  add column is_flower boolean not null default false;

update api.inventory_items inventory
set entry_name = reference.canonical_name,
    canonical_cultivar_id = case
      when reference.kind = 'cultivar'
        then coalesce(reference.canonical_cultivar_id, reference.id)
      else reference.canonical_cultivar_id
    end,
    is_flower = reference.is_flower
from api.catalog_references reference
where reference.id = inventory.entity_id;

alter table api.inventory_items
  alter column entry_name set not null,
  alter column entity_id drop not null,
  add constraint inventory_items_entry_name_check
    check (char_length(entry_name) between 1 and 160),
  add constraint inventory_items_origin_one_name_check
    check (
      origin_one_name is null
      or char_length(origin_one_name) between 1 and 160
    ),
  add constraint inventory_items_origin_two_name_check
    check (
      origin_two_name is null
      or char_length(origin_two_name) between 1 and 160
    );

create index inventory_items_canonical_flower_idx
  on api.inventory_items(user_id, canonical_cultivar_id)
  where is_flower;

create function private.derive_inventory_catalog_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  reference_record record;
begin
  if tg_op = 'UPDATE' and new.user_id is distinct from old.user_id then
    raise exception using
      errcode = '42501',
      message = 'Inventory owner is immutable';
  end if;

  if new.entity_id is null then
    new.canonical_cultivar_id := null;
    new.is_flower := false;
    return new;
  end if;

  select
    reference.kind,
    reference.canonical_cultivar_id,
    reference.is_flower
  into reference_record
  from api.catalog_references reference
  join catalog.entities entity
    on entity.id = reference.id
   and entity.published
  where reference.id = new.entity_id;

  if not found then
    raise exception using
      errcode = '23503',
      message = 'Published catalog reference is required';
  end if;

  new.canonical_cultivar_id := case
    when reference_record.kind = 'cultivar'
      then coalesce(reference_record.canonical_cultivar_id, new.entity_id)
    else reference_record.canonical_cultivar_id
  end;
  new.is_flower := reference_record.is_flower;
  return new;
end;
$$;

revoke all on function private.derive_inventory_catalog_fields()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create trigger inventory_items_derive_catalog_fields
  before insert or update of entity_id, user_id
  on api.inventory_items
  for each row execute function private.derive_inventory_catalog_fields();

revoke insert, update on api.inventory_items from authenticated;
grant insert (
  entity_id,
  entry_name,
  origin_one_name,
  origin_two_name,
  quantity,
  unit,
  batch,
  expires_on,
  storage_location,
  note
) on api.inventory_items to authenticated;
grant update (
  entity_id,
  entry_name,
  origin_one_name,
  origin_two_name,
  quantity,
  unit,
  batch,
  expires_on,
  storage_location,
  note
) on api.inventory_items to authenticated;

create table private.community_flower_contributions (
  user_id uuid not null
    references auth.users(id) on delete cascade,
  cultivar_id uuid not null
    references catalog.entities(id) on delete restrict,
  thc_percent numeric(4, 2) not null
    check (thc_percent between 0 and 70),
  cbd_percent numeric(4, 2) not null
    check (cbd_percent between 0 and 70),
  source_kind text not null
    check (source_kind in ('label', 'laboratory')),
  consent_version text not null
    check (char_length(consent_version) between 1 and 80),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (user_id, cultivar_id)
);

create index community_flower_contributions_cultivar_idx
  on private.community_flower_contributions(cultivar_id);

alter table private.community_flower_contributions enable row level security;

revoke all on private.community_flower_contributions
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function private.current_personal_user()
returns uuid
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := auth.uid();
begin
  if current_user_id is null then
    raise exception using
      errcode = '28000',
      message = 'Authentication is required';
  end if;

  if not private.personal_data_access_allowed(current_user_id) then
    raise exception using
      errcode = '42501',
      message = 'Current authentication assurance is required';
  end if;

  return current_user_id;
end;
$$;

revoke all on function private.current_personal_user()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function api.get_my_community_flower_contribution(
  p_cultivar_id uuid
)
returns table (
  cultivar_id uuid,
  thc_percent numeric,
  cbd_percent numeric,
  source_kind text,
  consent_version text,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.current_personal_user();
begin
  return query
  select
    contribution.cultivar_id,
    contribution.thc_percent,
    contribution.cbd_percent,
    contribution.source_kind,
    contribution.consent_version,
    contribution.updated_at
  from private.community_flower_contributions contribution
  where contribution.user_id = current_user_id
    and contribution.cultivar_id = p_cultivar_id;
end;
$$;

create function api.upsert_my_community_flower_contribution(
  p_cultivar_id uuid,
  p_thc_percent numeric,
  p_cbd_percent numeric,
  p_source_kind text,
  p_consent_version text,
  p_declaration_confirmed boolean,
  p_opt_in boolean
)
returns table (
  cultivar_id uuid,
  thc_percent numeric,
  cbd_percent numeric,
  source_kind text,
  consent_version text,
  updated_at timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.current_personal_user();
begin
  if p_thc_percent is null
     or p_cbd_percent is null
     or p_thc_percent < 0
     or p_thc_percent > 70
     or p_cbd_percent < 0
     or p_cbd_percent > 70
     or p_thc_percent <> trunc(p_thc_percent, 2)
     or p_cbd_percent <> trunc(p_cbd_percent, 2) then
    raise exception using
      errcode = '22023',
      message = 'Flower values must be between 0 and 70';
  end if;

  if p_source_kind not in ('label', 'laboratory') then
    raise exception using
      errcode = '22023',
      message = 'Label or laboratory source is required';
  end if;

  if p_declaration_confirmed is distinct from true
     or p_opt_in is distinct from true then
    raise exception using
      errcode = '22023',
      message = 'Declaration and opt-in are required';
  end if;

  if not exists (
    select 1
    from private.legal_versions version
    where version.kind = 'community_values'
      and version.version = btrim(coalesce(p_consent_version, ''))
      and version.active
  ) then
    raise exception using
      errcode = '22023',
      message = 'Active community consent version is required';
  end if;

  if not exists (
    select 1
    from api.catalog_references reference
    join catalog.entities entity
      on entity.id = reference.id
     and entity.published
    where reference.id = p_cultivar_id
      and reference.kind = 'cultivar'
      and coalesce(reference.canonical_cultivar_id, reference.id)
        = p_cultivar_id
      and reference.is_flower
  ) then
    raise exception using
      errcode = '22023',
      message = 'Published canonical flower cultivar is required';
  end if;

  if not exists (
    select 1
    from api.inventory_items inventory
    where inventory.user_id = current_user_id
      and inventory.canonical_cultivar_id = p_cultivar_id
      and inventory.is_flower
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'Eligible flower inventory is required';
  end if;

  return query
  with saved as (
    insert into private.community_flower_contributions(
      user_id,
      cultivar_id,
      thc_percent,
      cbd_percent,
      source_kind,
      consent_version
    ) values (
      current_user_id,
      p_cultivar_id,
      p_thc_percent,
      p_cbd_percent,
      p_source_kind,
      btrim(p_consent_version)
    )
    on conflict on constraint community_flower_contributions_pkey do update
    set thc_percent = excluded.thc_percent,
        cbd_percent = excluded.cbd_percent,
        source_kind = excluded.source_kind,
        consent_version = excluded.consent_version,
        updated_at = now()
    returning
      private.community_flower_contributions.cultivar_id,
      private.community_flower_contributions.thc_percent,
      private.community_flower_contributions.cbd_percent,
      private.community_flower_contributions.source_kind,
      private.community_flower_contributions.consent_version,
      private.community_flower_contributions.updated_at
  )
  select
    saved.cultivar_id,
    saved.thc_percent,
    saved.cbd_percent,
    saved.source_kind,
    saved.consent_version,
    saved.updated_at
  from saved;
end;
$$;

create function api.delete_my_community_flower_contribution(
  p_cultivar_id uuid
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.current_personal_user();
begin
  delete from private.community_flower_contributions contribution
  where contribution.user_id = current_user_id
    and contribution.cultivar_id = p_cultivar_id;
end;
$$;

create function api.export_my_community_flower_contributions()
returns table (
  cultivar_id uuid,
  cultivar_name text,
  thc_percent numeric,
  cbd_percent numeric,
  source_kind text,
  consent_version text,
  created_at timestamptz,
  updated_at timestamptz
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  current_user_id uuid := private.current_personal_user();
begin
  return query
  select
    contribution.cultivar_id,
    reference.canonical_name,
    contribution.thc_percent,
    contribution.cbd_percent,
    contribution.source_kind,
    contribution.consent_version,
    contribution.created_at,
    contribution.updated_at
  from private.community_flower_contributions contribution
  join api.catalog_references reference
    on reference.id = contribution.cultivar_id
  where contribution.user_id = current_user_id
  order by reference.canonical_name, contribution.cultivar_id;
end;
$$;

revoke all on function api.get_my_community_flower_contribution(uuid)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on function api.upsert_my_community_flower_contribution(
  uuid,
  numeric,
  numeric,
  text,
  text,
  boolean,
  boolean
) from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on function api.delete_my_community_flower_contribution(uuid)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on function api.export_my_community_flower_contributions()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

grant execute on function api.get_my_community_flower_contribution(uuid)
  to authenticated;
grant execute on function api.upsert_my_community_flower_contribution(
  uuid,
  numeric,
  numeric,
  text,
  text,
  boolean,
  boolean
) to authenticated;
grant execute on function api.delete_my_community_flower_contribution(uuid)
  to authenticated;
grant execute on function api.export_my_community_flower_contributions()
  to authenticated;

create function private.remove_orphaned_community_contribution()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.canonical_cultivar_id is null or not old.is_flower then
    return coalesce(new, old);
  end if;

  if tg_op = 'UPDATE'
     and new.canonical_cultivar_id is not distinct from old.canonical_cultivar_id
     and new.is_flower then
    return new;
  end if;

  if not exists (
    select 1
    from api.inventory_items remaining
    where remaining.user_id = old.user_id
      and remaining.canonical_cultivar_id = old.canonical_cultivar_id
      and remaining.is_flower
      and remaining.id <> old.id
  ) then
    delete from private.community_flower_contributions contribution
    where contribution.user_id = old.user_id
      and contribution.cultivar_id = old.canonical_cultivar_id;
  end if;

  return coalesce(new, old);
end;
$$;

revoke all on function private.remove_orphaned_community_contribution()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create trigger inventory_items_remove_orphaned_community_contribution
  after delete or update of canonical_cultivar_id, is_flower
  on api.inventory_items
  for each row execute function private.remove_orphaned_community_contribution();

create table api.community_flower_averages (
  cultivar_id uuid primary key
    references catalog.entities(id) on delete cascade,
  thc_mean numeric(4, 1) not null
    check (thc_mean between 0 and 70),
  cbd_mean numeric(4, 1) not null
    check (cbd_mean between 0 and 70),
  contributor_band text not null
    check (contributor_band in ('5+', '10+', '25+', '50+')),
  computed_at timestamptz not null
);

alter table api.community_flower_averages enable row level security;

create policy community_flower_averages_select_authenticated
  on api.community_flower_averages
  for select
  to authenticated
  using (true);

revoke all on api.community_flower_averages
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
grant select on api.community_flower_averages to authenticated;

create function private.refresh_community_flower_averages()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  refresh_time timestamptz := now();
begin
  perform pg_catalog.pg_advisory_xact_lock(20773691, 2);

  delete from api.community_flower_averages;

  insert into api.community_flower_averages(
    cultivar_id,
    thc_mean,
    cbd_mean,
    contributor_band,
    computed_at
  )
  select
    grouped.cultivar_id,
    round(grouped.thc_mean, 1),
    round(grouped.cbd_mean, 1),
    case
      when grouped.contributor_count >= 50 then '50+'
      when grouped.contributor_count >= 25 then '25+'
      when grouped.contributor_count >= 10 then '10+'
      else '5+'
    end,
    refresh_time
  from (
    select
      contribution.cultivar_id,
      avg(contribution.thc_percent) as thc_mean,
      avg(contribution.cbd_percent) as cbd_mean,
      count(*) as contributor_count
    from private.community_flower_contributions contribution
    group by contribution.cultivar_id
    having count(*) >= 5
  ) grouped;
end;
$$;

revoke all on function private.refresh_community_flower_averages()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create extension if not exists pg_cron;

do $$
declare
  existing_job_id bigint;
begin
  for existing_job_id in
    select jobid
    from cron.job
    where jobname = 'weedypedia-community-flower-averages-six-hourly'
  loop
    perform cron.unschedule(existing_job_id);
  end loop;
end;
$$;

select cron.schedule(
  'weedypedia-community-flower-averages-six-hourly',
  '17 */6 * * *',
  $schedule$select private.refresh_community_flower_averages()$schedule$
);
