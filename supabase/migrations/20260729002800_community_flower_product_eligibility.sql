create or replace function api.upsert_my_community_flower_contribution(
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

  if p_source_kind is null
     or p_source_kind not in ('label', 'laboratory') then
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
    from api.catalog_references cultivar
    join catalog.entities cultivar_entity
      on cultivar_entity.id = cultivar.id
     and cultivar_entity.published
    where cultivar.id = p_cultivar_id
      and cultivar.kind = 'cultivar'
      and coalesce(cultivar.canonical_cultivar_id, cultivar.id)
        = p_cultivar_id
      and exists (
        select 1
        from api.catalog_references flower_reference
        join catalog.entities flower_entity
          on flower_entity.id = flower_reference.id
         and flower_entity.published
        where flower_reference.canonical_cultivar_id = p_cultivar_id
          and flower_reference.is_flower
      )
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
