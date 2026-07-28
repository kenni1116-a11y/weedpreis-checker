create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if not exists (
    select 1 from pg_roles where rolname = 'source_ingestor'
  ) then
    create role source_ingestor nologin noinherit;
  end if;
  if not exists (
    select 1 from pg_roles where rolname = 'source_reviewer'
  ) then
    create role source_reviewer nologin noinherit;
  end if;
end;
$$;

grant source_ingestor, source_reviewer to postgres;

create table catalog.sources (
  id text primary key
    check (
      char_length(id) between 3 and 80
      and id ~ '^[a-z0-9][a-z0-9._-]+$'
    ),
  display_name text not null
    check (char_length(display_name) between 1 and 160),
  owner_name text not null
    check (char_length(owner_name) between 1 and 240),
  access_method text not null
    check (char_length(access_method) between 1 and 240),
  permitted_frequency text not null
    check (char_length(permitted_frequency) between 1 and 240),
  license_status text not null
    check (
      license_status in (
        'unknown',
        'review_required',
        'approved',
        'forbidden'
      )
    ),
  license_reference text
    check (
      license_reference is null
      or char_length(license_reference) between 1 and 2048
    ),
  raw_storage_allowed boolean not null default false,
  attribution_rules text not null
    check (char_length(attribution_rules) between 1 and 2000),
  image_rights_status text not null
    check (char_length(image_rights_status) between 1 and 1000),
  confidence_class text not null
    check (
      confidence_class in ('discovery', 'supporting', 'authoritative')
    ),
  responsible_reviewer text not null
    check (char_length(responsible_reviewer) between 1 and 240),
  status text not null
    check (status in ('inactive', 'pilot', 'active', 'blocked')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table catalog.import_runs (
  id uuid primary key default gen_random_uuid(),
  source_id text not null
    references catalog.sources(id) on delete restrict,
  started_at timestamptz not null,
  completed_at timestamptz not null,
  cursor text check (cursor is null or char_length(cursor) <= 2000),
  adapter_errors jsonb not null default '[]'::jsonb
    check (jsonb_typeof(adapter_errors) = 'array'),
  created_at timestamptz not null default now(),
  check (completed_at >= started_at)
);

create table catalog.source_records (
  id uuid primary key default gen_random_uuid(),
  source_id text not null
    references catalog.sources(id) on delete restrict,
  external_record_key text not null
    check (char_length(external_record_key) between 1 and 240),
  upstream_state text not null
    check (upstream_state in ('present', 'deleted')),
  retrieved_at timestamptz not null,
  source_version text
    check (
      source_version is null
      or char_length(source_version) between 1 and 160
    ),
  evidence_kind text not null
    check (evidence_kind in ('raw', 'checksum')),
  raw_media_type text
    check (
      raw_media_type is null
      or raw_media_type in (
        'application/json',
        'application/xml',
        'text/csv'
      )
    ),
  raw_payload jsonb,
  content_hash text not null
    check (content_hash ~ '^[0-9a-f]{64}$'),
  retrieval_reference text
    check (
      retrieval_reference is null
      or char_length(retrieval_reference) between 1 and 2048
    ),
  valid_from timestamptz,
  valid_to timestamptz,
  license_status_snapshot text not null
    check (
      license_status_snapshot in (
        'unknown',
        'review_required',
        'approved',
        'forbidden'
      )
    ),
  raw_storage_allowed_snapshot boolean not null,
  attribution_snapshot text not null
    check (char_length(attribution_snapshot) between 1 and 2000),
  created_at timestamptz not null default now(),
  constraint source_records_source_external_hash_key
    unique (source_id, external_record_key, content_hash),
  check (valid_to is null or valid_from is null or valid_to >= valid_from),
  check (
    (
      evidence_kind = 'raw'
      and raw_media_type is not null
      and raw_payload is not null
      and retrieval_reference is null
      and raw_storage_allowed_snapshot
    )
    or
    (
      evidence_kind = 'checksum'
      and raw_media_type is null
      and raw_payload is null
      and retrieval_reference is not null
    )
  )
);

create index source_records_source_external_idx
  on catalog.source_records(source_id, external_record_key, retrieved_at desc);

create function private.jsonb_has_exact_keys(
  payload jsonb,
  expected_keys text[]
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select
    jsonb_typeof(payload) = 'object'
    and payload ?& expected_keys
    and not exists (
      select 1
      from jsonb_object_keys(payload) as actual(key)
      where not actual.key = any(expected_keys)
    );
$$;

revoke all on function private.jsonb_has_exact_keys(jsonb, text[])
  from public, anon, authenticated, service_role;

create function private.source_assertion_payload_valid(
  expected_kind text,
  payload jsonb
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select case expected_kind
    when 'name' then
      private.jsonb_has_exact_keys(
        payload,
        array['kind', 'subjectExternalKey', 'name', 'language']
      )
      and payload ->> 'kind' = 'name'
      and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
      and char_length(payload ->> 'subjectExternalKey') between 1 and 240
      and jsonb_typeof(payload -> 'name') = 'string'
      and char_length(payload ->> 'name') between 1 and 240
      and (
        payload -> 'language' = 'null'::jsonb
        or jsonb_typeof(payload -> 'language') = 'string'
      )
    when 'alias' then
      private.jsonb_has_exact_keys(
        payload,
        array['kind', 'subjectExternalKey', 'name', 'language']
      )
      and payload ->> 'kind' = 'alias'
      and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
      and char_length(payload ->> 'subjectExternalKey') between 1 and 240
      and jsonb_typeof(payload -> 'name') = 'string'
      and char_length(payload ->> 'name') between 1 and 240
      and (
        payload -> 'language' = 'null'::jsonb
        or jsonb_typeof(payload -> 'language') = 'string'
      )
    when 'lineage' then
      private.jsonb_has_exact_keys(
        payload,
        array[
          'kind',
          'subjectExternalKey',
          'parentExternalKey',
          'relationship',
          'position'
        ]
      )
      and payload ->> 'kind' = 'lineage'
      and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
      and char_length(payload ->> 'subjectExternalKey') between 1 and 240
      and jsonb_typeof(payload -> 'parentExternalKey') = 'string'
      and char_length(payload ->> 'parentExternalKey') between 1 and 240
      and payload ->> 'relationship'
        in ('reported_parent', 'historical_origin')
      and (
        payload -> 'position' = 'null'::jsonb
        or (
          jsonb_typeof(payload -> 'position') = 'number'
          and payload ->> 'position' in ('1', '2')
        )
      )
    when 'product_cultivar' then
      private.jsonb_has_exact_keys(
        payload,
        array[
          'kind',
          'subjectExternalKey',
          'cultivarExternalKey',
          'productForm'
        ]
      )
      and payload ->> 'kind' = 'product_cultivar'
      and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
      and char_length(payload ->> 'subjectExternalKey') between 1 and 240
      and jsonb_typeof(payload -> 'cultivarExternalKey') = 'string'
      and char_length(payload ->> 'cultivarExternalKey') between 1 and 240
      and payload ->> 'productForm'
        in ('flower', 'extract', 'oil', 'other')
    when 'measurement' then
      private.jsonb_has_exact_keys(
        payload,
        array[
          'kind',
          'subjectExternalKey',
          'analyte',
          'value',
          'unit',
          'productForm',
          'measuredAt'
        ]
      )
      and payload ->> 'kind' = 'measurement'
      and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
      and char_length(payload ->> 'subjectExternalKey') between 1 and 240
      and payload ->> 'analyte' in ('thc', 'cbd')
      and jsonb_typeof(payload -> 'value') = 'number'
      and payload ->> 'unit' = 'percent'
      and payload ->> 'productForm'
        in ('flower', 'extract', 'oil', 'other')
      and (
        payload -> 'measuredAt' = 'null'::jsonb
        or (
          jsonb_typeof(payload -> 'measuredAt') = 'string'
          and payload ->> 'measuredAt'
            ~ '^\d{4}-\d{2}-\d{2}T'
        )
      )
    else false
  end;
$$;

revoke all on function private.source_assertion_payload_valid(text, jsonb)
  from public, anon, authenticated, service_role;

create table catalog.normalized_assertions (
  id uuid primary key default gen_random_uuid(),
  source_record_id uuid not null
    references catalog.source_records(id) on delete restrict,
  assertion_index integer not null check (assertion_index >= 0),
  assertion_kind text not null
    check (
      assertion_kind in (
        'name',
        'alias',
        'lineage',
        'product_cultivar',
        'measurement'
      )
    ),
  subject_external_key text not null
    check (char_length(subject_external_key) between 1 and 240),
  payload jsonb not null,
  valid_from timestamptz,
  valid_to timestamptz,
  created_at timestamptz not null default now(),
  unique (source_record_id, assertion_index),
  check (valid_to is null or valid_from is null or valid_to >= valid_from),
  check (
    private.source_assertion_payload_valid(assertion_kind, payload)
    and subject_external_key = payload ->> 'subjectExternalKey'
  )
);

create index normalized_assertions_subject_kind_idx
  on catalog.normalized_assertions(subject_external_key, assertion_kind);

create table catalog.review_cases (
  id uuid primary key default gen_random_uuid(),
  source_record_id uuid not null
    references catalog.source_records(id) on delete restrict,
  assertion_id uuid
    references catalog.normalized_assertions(id) on delete restrict,
  case_kind text not null
    check (
      case_kind in (
        'unknown_mapping',
        'conflicting_lineage',
        'flower_value_above_70',
        'upstream_record_deleted'
      )
    ),
  detail_code text not null
    check (char_length(detail_code) between 1 and 160),
  status text not null default 'open'
    check (status in ('open', 'closed')),
  decision text check (decision is null or decision in ('accepted', 'rejected')),
  reviewer_name text
    check (
      reviewer_name is null
      or char_length(reviewer_name) between 1 and 240
    ),
  reviewed_at timestamptz,
  note text check (note is null or char_length(note) <= 1000),
  created_at timestamptz not null default now(),
  unique (source_record_id, assertion_id, case_kind),
  check (
    (
      status = 'open'
      and decision is null
      and reviewer_name is null
      and reviewed_at is null
    )
    or
    (
      status = 'closed'
      and decision is not null
      and reviewer_name is not null
      and reviewed_at is not null
    )
  )
);

create index review_cases_open_idx
  on catalog.review_cases(created_at)
  where status = 'open';

create table catalog.assertion_reviews (
  assertion_id uuid primary key
    references catalog.normalized_assertions(id) on delete restrict,
  decision text not null
    check (decision in ('accepted', 'rejected')),
  entity_id uuid references catalog.entities(id) on delete restrict,
  related_entity_id uuid references catalog.entities(id) on delete restrict,
  reviewer_name text not null
    check (char_length(reviewer_name) between 1 and 240),
  reviewed_at timestamptz not null,
  note text check (note is null or char_length(note) <= 1000),
  check (
    (
      decision = 'accepted'
      and entity_id is not null
    )
    or
    (
      decision = 'rejected'
      and entity_id is null
      and related_entity_id is null
    )
  )
);

create function private.reject_source_record_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using
    errcode = '55000',
    message = 'source records are immutable';
end;
$$;

revoke all on function private.reject_source_record_mutation()
  from public, anon, authenticated, service_role;

create trigger source_records_are_immutable
  before update or delete on catalog.source_records
  for each row execute function private.reject_source_record_mutation();

create function private.reject_normalized_assertion_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using
    errcode = '55000',
    message = 'normalized assertions are immutable';
end;
$$;

revoke all on function private.reject_normalized_assertion_mutation()
  from public, anon, authenticated, service_role;

create trigger normalized_assertions_are_immutable
  before update or delete on catalog.normalized_assertions
  for each row execute function private.reject_normalized_assertion_mutation();

create function private.record_source_import(p_batch jsonb)
returns table (
  run_id uuid,
  inserted_records integer,
  inserted_assertions integer,
  review_cases integer
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  source_row catalog.sources%rowtype;
  record_value jsonb;
  assertion_value jsonb;
  evidence_value jsonb;
  record_id uuid;
  assertion_id uuid;
  run_identifier uuid;
  record_hash text;
  raw_media text;
  raw_value jsonb;
  retrieval_value text;
  record_count integer := 0;
  assertion_count integer := 0;
  case_count integer := 0;
  affected_count integer := 0;
  assertion_ordinality bigint;
begin
  if not private.jsonb_has_exact_keys(
    p_batch,
    array[
      'sourceId',
      'startedAt',
      'completedAt',
      'cursor',
      'records',
      'errors'
    ]
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid source import batch';
  end if;

  if jsonb_typeof(p_batch -> 'records') <> 'array'
     or jsonb_typeof(p_batch -> 'errors') <> 'array' then
    raise exception using
      errcode = '22023',
      message = 'Invalid source import collections';
  end if;

  select *
  into source_row
  from catalog.sources
  where id = p_batch ->> 'sourceId';

  if not found then
    raise exception using
      errcode = '22023',
      message = 'Unknown source';
  end if;
  if source_row.status = 'blocked'
     or source_row.license_status = 'forbidden' then
    raise exception using
      errcode = '42501',
      message = 'Source import is blocked';
  end if;

  insert into catalog.import_runs(
    source_id,
    started_at,
    completed_at,
    cursor,
    adapter_errors
  ) values (
    source_row.id,
    (p_batch ->> 'startedAt')::timestamptz,
    (p_batch ->> 'completedAt')::timestamptz,
    nullif(p_batch ->> 'cursor', ''),
    p_batch -> 'errors'
  )
  returning id into run_identifier;

  for record_value in
    select item.value
    from jsonb_array_elements(p_batch -> 'records') as item(value)
  loop
    if not private.jsonb_has_exact_keys(
      record_value,
      array[
        'externalRecordKey',
        'upstreamState',
        'retrievedAt',
        'sourceVersion',
        'evidence',
        'validFrom',
        'validTo',
        'assertions'
      ]
    ) then
      raise exception using
        errcode = '22023',
        message = 'Invalid source record';
    end if;
    if record_value ->> 'upstreamState' not in ('present', 'deleted')
       or jsonb_typeof(record_value -> 'assertions') <> 'array' then
      raise exception using
        errcode = '22023',
        message = 'Invalid source record state';
    end if;
    if record_value ->> 'upstreamState' = 'present'
       and jsonb_array_length(record_value -> 'assertions') = 0 then
      raise exception using
        errcode = '22023',
        message = 'Present source records require assertions';
    end if;
    if record_value ->> 'upstreamState' = 'deleted'
       and jsonb_array_length(record_value -> 'assertions') <> 0 then
      raise exception using
        errcode = '22023',
        message = 'Deleted source records cannot assert facts';
    end if;

    evidence_value := record_value -> 'evidence';
    if evidence_value ->> 'kind' = 'raw' then
      if not source_row.raw_storage_allowed then
        raise exception using
          errcode = '42501',
          message = 'Raw source storage is not allowed';
      end if;
      if not private.jsonb_has_exact_keys(
        evidence_value,
        array['kind', 'mediaType', 'payload']
      ) then
        raise exception using
          errcode = '22023',
          message = 'Invalid raw source evidence';
      end if;
      raw_media := evidence_value ->> 'mediaType';
      if raw_media not in ('application/json', 'application/xml', 'text/csv') then
        raise exception using
          errcode = '22023',
          message = 'Invalid raw source media type';
      end if;
      raw_value := evidence_value -> 'payload';
      retrieval_value := null;
      record_hash := encode(
        extensions.digest(
          convert_to(raw_value::text, 'UTF8'),
          'sha256'
        ),
        'hex'
      );
    elsif evidence_value ->> 'kind' = 'checksum' then
      if not private.jsonb_has_exact_keys(
        evidence_value,
        array['kind', 'algorithm', 'digest', 'retrievalReference']
      )
      or evidence_value ->> 'algorithm' <> 'sha256'
      or evidence_value ->> 'digest' !~ '^[0-9a-f]{64}$' then
        raise exception using
          errcode = '22023',
          message = 'Invalid checksum source evidence';
      end if;
      raw_media := null;
      raw_value := null;
      record_hash := evidence_value ->> 'digest';
      retrieval_value := evidence_value ->> 'retrievalReference';
      if retrieval_value is null
         or char_length(retrieval_value) not between 1 and 2048 then
        raise exception using
          errcode = '22023',
          message = 'Invalid source retrieval reference';
      end if;
    else
      raise exception using
        errcode = '22023',
        message = 'Invalid source evidence kind';
    end if;

    record_id := null;
    insert into catalog.source_records(
      source_id,
      external_record_key,
      upstream_state,
      retrieved_at,
      source_version,
      evidence_kind,
      raw_media_type,
      raw_payload,
      content_hash,
      retrieval_reference,
      valid_from,
      valid_to,
      license_status_snapshot,
      raw_storage_allowed_snapshot,
      attribution_snapshot
    ) values (
      source_row.id,
      record_value ->> 'externalRecordKey',
      record_value ->> 'upstreamState',
      (record_value ->> 'retrievedAt')::timestamptz,
      nullif(record_value ->> 'sourceVersion', ''),
      evidence_value ->> 'kind',
      raw_media,
      raw_value,
      record_hash,
      retrieval_value,
      (record_value ->> 'validFrom')::timestamptz,
      (record_value ->> 'validTo')::timestamptz,
      source_row.license_status,
      source_row.raw_storage_allowed,
      source_row.attribution_rules
    )
    on conflict (source_id, external_record_key, content_hash) do nothing
    returning id into record_id;

    if record_id is null then
      continue;
    end if;
    record_count := record_count + 1;

    if record_value ->> 'upstreamState' = 'deleted' then
      insert into catalog.review_cases(
        source_record_id,
        assertion_id,
        case_kind,
        detail_code
      ) values (
        record_id,
        null,
        'upstream_record_deleted',
        'upstream_record_deleted'
      );
      case_count := case_count + 1;
      continue;
    end if;

    for assertion_value, assertion_ordinality in
      select item.value, item.ordinality
      from jsonb_array_elements(record_value -> 'assertions')
        with ordinality as item(value, ordinality)
    loop
      if not private.source_assertion_payload_valid(
        assertion_value ->> 'kind',
        assertion_value
      ) then
        raise exception using
          errcode = '22023',
          message = 'Invalid normalized assertion';
      end if;

      insert into catalog.normalized_assertions(
        source_record_id,
        assertion_index,
        assertion_kind,
        subject_external_key,
        payload,
        valid_from,
        valid_to
      ) values (
        record_id,
        assertion_ordinality - 1,
        assertion_value ->> 'kind',
        assertion_value ->> 'subjectExternalKey',
        assertion_value,
        (record_value ->> 'validFrom')::timestamptz,
        (record_value ->> 'validTo')::timestamptz
      )
      returning id into assertion_id;
      assertion_count := assertion_count + 1;

      insert into catalog.review_cases(
        source_record_id,
        assertion_id,
        case_kind,
        detail_code
      ) values (
        record_id,
        assertion_id,
        'unknown_mapping',
        'canonical_mapping_required'
      );
      case_count := case_count + 1;

      if assertion_value ->> 'kind' = 'measurement'
         and assertion_value ->> 'productForm' = 'flower'
         and (assertion_value ->> 'value')::numeric > 70 then
        insert into catalog.review_cases(
          source_record_id,
          assertion_id,
          case_kind,
          detail_code
        ) values (
          record_id,
          assertion_id,
          'flower_value_above_70',
          'flower_value_above_70'
        );
        case_count := case_count + 1;
      end if;

      if assertion_value ->> 'kind' = 'lineage'
         and exists (
           select 1
           from catalog.normalized_assertions existing
           where existing.id <> assertion_id
             and existing.assertion_kind = 'lineage'
             and existing.subject_external_key =
               assertion_value ->> 'subjectExternalKey'
             and existing.payload -> 'position'
               is not distinct from assertion_value -> 'position'
             and existing.payload ->> 'parentExternalKey'
               <> assertion_value ->> 'parentExternalKey'
         ) then
        insert into catalog.review_cases(
          source_record_id,
          assertion_id,
          case_kind,
          detail_code
        ) values (
          record_id,
          assertion_id,
          'conflicting_lineage',
          'conflicting_parent_for_position'
        );
        case_count := case_count + 1;
      end if;
    end loop;
  end loop;

  return query
  select run_identifier, record_count, assertion_count, case_count;
end;
$$;

create function private.review_source_assertion(
  p_assertion_id uuid,
  p_decision text,
  p_entity_id uuid,
  p_related_entity_id uuid,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  assertion_row catalog.normalized_assertions%rowtype;
  entity_kind text;
  related_kind text;
  reviewer text := session_user::text;
  review_time timestamptz := now();
begin
  select *
  into assertion_row
  from catalog.normalized_assertions
  where id = p_assertion_id;

  if not found then
    raise exception using
      errcode = '22023',
      message = 'Unknown source assertion';
  end if;
  if p_decision not in ('accepted', 'rejected')
     or char_length(coalesce(p_note, '')) > 1000 then
    raise exception using
      errcode = '22023',
      message = 'Invalid source review';
  end if;

  if p_decision = 'rejected' then
    if p_entity_id is not null or p_related_entity_id is not null then
      raise exception using
        errcode = '22023',
        message = 'Rejected assertions cannot map entities';
    end if;
  else
    if p_entity_id is null then
      raise exception using
        errcode = '22023',
        message = 'Accepted assertions require an entity';
    end if;
    select kind into entity_kind
    from catalog.entities
    where id = p_entity_id;
    if entity_kind is null then
      raise exception using
        errcode = '22023',
        message = 'Unknown canonical entity';
    end if;

    if assertion_row.assertion_kind in ('lineage', 'product_cultivar') then
      if p_related_entity_id is null then
        raise exception using
          errcode = '22023',
          message = 'Accepted relationship requires a related entity';
      end if;
      select kind into related_kind
      from catalog.entities
      where id = p_related_entity_id;
      if assertion_row.assertion_kind = 'lineage'
         and (entity_kind <> 'cultivar' or related_kind <> 'cultivar') then
        raise exception using
          errcode = '22023',
          message = 'Lineage requires two cultivars';
      end if;
      if assertion_row.assertion_kind = 'product_cultivar'
         and (entity_kind <> 'product' or related_kind <> 'cultivar') then
        raise exception using
          errcode = '22023',
          message = 'Product mapping requires product and cultivar';
      end if;
    elsif p_related_entity_id is not null then
      raise exception using
        errcode = '22023',
        message = 'This assertion has no related entity';
    end if;

    if assertion_row.assertion_kind = 'measurement'
       and assertion_row.payload ->> 'productForm' = 'flower'
       and (assertion_row.payload ->> 'value')::numeric > 70 then
      raise exception using
        errcode = '22023',
        message = 'Unrealistic flower measurements cannot be accepted';
    end if;
  end if;

  insert into catalog.assertion_reviews(
    assertion_id,
    decision,
    entity_id,
    related_entity_id,
    reviewer_name,
    reviewed_at,
    note
  ) values (
    p_assertion_id,
    p_decision,
    p_entity_id,
    p_related_entity_id,
    reviewer,
    review_time,
    nullif(btrim(p_note), '')
  )
  on conflict (assertion_id) do update
  set decision = excluded.decision,
      entity_id = excluded.entity_id,
      related_entity_id = excluded.related_entity_id,
      reviewer_name = excluded.reviewer_name,
      reviewed_at = excluded.reviewed_at,
      note = excluded.note;

  update catalog.review_cases
  set status = 'closed',
      decision = p_decision,
      reviewer_name = reviewer,
      reviewed_at = review_time,
      note = nullif(btrim(p_note), '')
  where assertion_id = p_assertion_id;
end;
$$;

create function private.review_source_record_deletion(
  p_source_record_id uuid,
  p_decision text,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  reviewer text := session_user::text;
  review_time timestamptz := now();
  affected integer;
begin
  if p_decision not in ('accepted', 'rejected')
     or char_length(coalesce(p_note, '')) > 1000 then
    raise exception using
      errcode = '22023',
      message = 'Invalid source deletion review';
  end if;

  update catalog.review_cases review_case
  set status = 'closed',
      decision = p_decision,
      reviewer_name = reviewer,
      reviewed_at = review_time,
      note = nullif(btrim(p_note), '')
  from catalog.source_records source_record
  where review_case.source_record_id = p_source_record_id
    and source_record.id = review_case.source_record_id
    and source_record.upstream_state = 'deleted'
    and review_case.assertion_id is null
    and review_case.case_kind = 'upstream_record_deleted';

  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception using
      errcode = '22023',
      message = 'Unknown source deletion review case';
  end if;
end;
$$;

alter table catalog.sources enable row level security;
alter table catalog.import_runs enable row level security;
alter table catalog.source_records enable row level security;
alter table catalog.normalized_assertions enable row level security;
alter table catalog.review_cases enable row level security;
alter table catalog.assertion_reviews enable row level security;

revoke all on catalog.sources
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on catalog.import_runs
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on catalog.source_records
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on catalog.normalized_assertions
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on catalog.review_cases
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
revoke all on catalog.assertion_reviews
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

revoke all on function private.record_source_import(jsonb)
  from public, anon, authenticated, service_role, source_reviewer;
revoke all on function private.review_source_assertion(uuid, text, uuid, uuid, text)
  from public, anon, authenticated, service_role, source_ingestor;
revoke all on function private.review_source_record_deletion(uuid, text, text)
  from public, anon, authenticated, service_role, source_ingestor;

grant usage on schema private to source_ingestor, source_reviewer;
grant execute on function private.record_source_import(jsonb)
  to source_ingestor;
grant execute on function private.review_source_assertion(uuid, text, uuid, uuid, text)
  to source_reviewer;
grant execute on function private.review_source_record_deletion(uuid, text, text)
  to source_reviewer;
