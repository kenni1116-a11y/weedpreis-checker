-- Remote staging version: 20260729183539; original version: 20260725222253.
create schema if not exists private;
create schema if not exists catalog;
create schema if not exists api;

revoke all on schema private, catalog, api from public, anon, authenticated;

alter default privileges in schema private
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema catalog
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema api
  revoke all on tables from public, anon, authenticated;
alter default privileges in schema private
  revoke execute on functions from public, anon, authenticated;
alter default privileges in schema catalog
  revoke execute on functions from public, anon, authenticated;
alter default privileges in schema api
  revoke execute on functions from public, anon, authenticated;

create table private.legal_versions (
  kind text not null check (kind in ('privacy', 'terms', 'adult')),
  version text not null check (char_length(version) between 1 and 80),
  active boolean not null default false,
  effective_at timestamptz not null,
  primary key (kind, version)
);

create unique index legal_versions_one_active_per_kind
  on private.legal_versions(kind)
  where active;

create table api.profiles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  username text not null check (char_length(username) between 3 and 32),
  username_normalized text not null unique
    check (username_normalized ~ '^[a-z0-9][a-z0-9._-]{2,31}$'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table api.consent_receipts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  kind text not null check (kind in ('privacy', 'terms', 'adult')),
  version text not null check (char_length(version) between 1 and 80),
  accepted_at timestamptz not null,
  unique (user_id, kind, version)
);

create table catalog.entities (
  id uuid primary key,
  kind text not null check (kind in ('cultivar', 'product')),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160),
  published boolean not null default false,
  unique (kind, canonical_name)
);

create table api.catalog_references (
  id uuid primary key references catalog.entities(id) on delete cascade,
  kind text not null check (kind in ('cultivar', 'product')),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160)
);

create table api.inventory_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid()
    references auth.users(id) on delete cascade,
  entity_id uuid not null
    references api.catalog_references(id) on delete restrict,
  quantity numeric(12, 3) not null
    check (quantity > 0 and quantity <= 100000),
  unit text not null check (unit in ('g', 'ml', 'piece')),
  batch text check (batch is null or char_length(batch) <= 120),
  expires_on date,
  storage_location text
    check (
      storage_location is null
      or char_length(storage_location) <= 120
    ),
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index inventory_items_user_id_idx
  on api.inventory_items(user_id);

create function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  registration_username text;
  normalized_username text;
  privacy_version text;
  terms_version text;
  adult_version text;
  accepted_at timestamptz;
begin
  if new.raw_user_meta_data -> 'adult_confirmed' is distinct from 'true'::jsonb then
    raise exception using
      errcode = 'P0001',
      message = 'Adult confirmation is required';
  end if;

  registration_username :=
    btrim(coalesce(new.raw_user_meta_data ->> 'registration_username', ''));
  normalized_username := lower(registration_username);

  if char_length(registration_username) not between 3 and 32
     or normalized_username !~ '^[a-z0-9][a-z0-9._-]{2,31}$' then
    raise exception using
      errcode = '22023',
      message = 'Invalid username';
  end if;

  privacy_version :=
    btrim(coalesce(new.raw_user_meta_data ->> 'privacy_version', ''));
  terms_version :=
    btrim(coalesce(new.raw_user_meta_data ->> 'terms_version', ''));

  if not exists (
    select 1
    from private.legal_versions
    where kind = 'privacy'
      and version = privacy_version
      and active
  ) then
    raise exception using
      errcode = '22023',
      message = 'Inactive privacy version';
  end if;

  if not exists (
    select 1
    from private.legal_versions
    where kind = 'terms'
      and version = terms_version
      and active
  ) then
    raise exception using
      errcode = '22023',
      message = 'Inactive terms version';
  end if;

  select version
  into adult_version
  from private.legal_versions
  where kind = 'adult'
    and active;

  if adult_version is null then
    raise exception using
      errcode = '22023',
      message = 'Active adult version is missing';
  end if;

  accepted_at := coalesce(new.created_at, now());

  insert into api.profiles(
    user_id,
    username,
    username_normalized,
    created_at,
    updated_at
  ) values (
    new.id,
    registration_username,
    normalized_username,
    accepted_at,
    accepted_at
  );

  insert into api.consent_receipts(user_id, kind, version, accepted_at)
  values
    (new.id, 'privacy', privacy_version, accepted_at),
    (new.id, 'terms', terms_version, accepted_at),
    (new.id, 'adult', adult_version, accepted_at);

  return new;
end;
$$;

revoke all on function private.handle_new_auth_user()
  from public, anon, authenticated;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

create function private.set_inventory_updated_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

revoke all on function private.set_inventory_updated_at()
  from public, anon, authenticated;

create trigger inventory_items_set_updated_at
  before update on api.inventory_items
  for each row execute function private.set_inventory_updated_at();

create function private.personal_data_access_allowed(target_user_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    target_user_id = (select auth.uid())
    and (
      not exists (
        select 1
        from auth.mfa_factors
        where user_id = target_user_id
          and status = 'verified'::auth.factor_status
      )
      or coalesce((select auth.jwt() ->> 'aal') = 'aal2', false)
    );
$$;

revoke all on function private.personal_data_access_allowed(uuid)
  from public, anon;
grant execute on function private.personal_data_access_allowed(uuid)
  to authenticated;

alter table api.profiles enable row level security;
alter table api.consent_receipts enable row level security;
alter table api.catalog_references enable row level security;
alter table api.inventory_items enable row level security;

create policy profiles_select_own
  on api.profiles
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy profiles_require_current_aal
  on api.profiles
  as restrictive
  for select
  to authenticated
  using (private.personal_data_access_allowed(user_id));

create policy consent_receipts_select_own
  on api.consent_receipts
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy consent_receipts_require_current_aal
  on api.consent_receipts
  as restrictive
  for select
  to authenticated
  using (private.personal_data_access_allowed(user_id));

create policy catalog_references_select_authenticated
  on api.catalog_references
  for select
  to authenticated
  using (true);

create policy inventory_items_select_own
  on api.inventory_items
  for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy inventory_items_insert_own
  on api.inventory_items
  for insert
  to authenticated
  with check (user_id = (select auth.uid()));

create policy inventory_items_update_own
  on api.inventory_items
  for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

create policy inventory_items_delete_own
  on api.inventory_items
  for delete
  to authenticated
  using (user_id = (select auth.uid()));

create policy inventory_items_require_current_aal
  on api.inventory_items
  as restrictive
  for all
  to authenticated
  using (private.personal_data_access_allowed(user_id))
  with check (private.personal_data_access_allowed(user_id));

revoke all on all tables in schema private
  from public, anon, authenticated;
revoke all on all tables in schema catalog
  from public, anon, authenticated;
revoke all on all tables in schema api
  from public, anon, authenticated;

grant usage on schema api to authenticated;
grant select on api.profiles to authenticated;
grant select on api.consent_receipts to authenticated;
grant select on api.catalog_references to authenticated;
grant select, delete on api.inventory_items to authenticated;
grant insert (
  entity_id,
  quantity,
  unit,
  batch,
  expires_on,
  storage_location,
  note
) on api.inventory_items to authenticated;
grant update (
  entity_id,
  quantity,
  unit,
  batch,
  expires_on,
  storage_location,
  note
) on api.inventory_items to authenticated;

grant usage on schema private, catalog, api to service_role;
grant all on all tables in schema private, catalog, api to service_role;
