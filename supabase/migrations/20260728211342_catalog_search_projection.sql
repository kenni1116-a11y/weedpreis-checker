alter table api.catalog_references
  add column canonical_cultivar_id uuid
    references catalog.entities(id) on delete restrict,
  add column is_flower boolean not null default false,
  add column preferred_parent_one_name text
    check (
      preferred_parent_one_name is null
      or char_length(preferred_parent_one_name) between 1 and 160
    ),
  add column preferred_parent_two_name text
    check (
      preferred_parent_two_name is null
      or char_length(preferred_parent_two_name) between 1 and 160
    ),
  add column has_additional_lineage boolean not null default false,
  add column sourced_thc_label text
    check (
      sourced_thc_label is null
      or char_length(sourced_thc_label) between 1 and 80
    ),
  add column sourced_cbd_label text
    check (
      sourced_cbd_label is null
      or char_length(sourced_cbd_label) between 1 and 80
    ),
  add column sourced_value_evidence jsonb not null default '[]'::jsonb
    check (jsonb_typeof(sourced_value_evidence) = 'array'),
  add column published_at timestamptz not null default now();

create table catalog.published_search_terms (
  reference_id uuid not null
    references api.catalog_references(id) on delete cascade,
  term text not null check (char_length(term) between 1 and 240),
  language text not null default ''
    check (char_length(language) <= 35),
  match_reason text not null
    check (match_reason in ('canonical', 'alias', 'product')),
  primary key (reference_id, term, language, match_reason)
);

create index published_search_terms_lookup_idx
  on catalog.published_search_terms(lower(term) text_pattern_ops);

alter table catalog.published_search_terms enable row level security;

revoke all on catalog.published_search_terms
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create table catalog.publication_assertion_staging (
  snapshot_id uuid not null,
  assertion_id uuid not null,
  assertion_kind text not null,
  payload jsonb not null,
  entity_id uuid not null,
  related_entity_id uuid,
  reviewed_at timestamptz not null,
  source_version text,
  retrieved_at timestamptz not null,
  retrieval_reference text,
  attribution_snapshot text not null,
  source_name text not null,
  primary key (snapshot_id, assertion_id)
);

create table catalog.catalog_reference_staging (
  snapshot_id uuid not null,
  id uuid not null,
  kind text not null,
  canonical_name text not null,
  canonical_cultivar_id uuid,
  is_flower boolean not null,
  preferred_parent_one_name text,
  preferred_parent_two_name text,
  has_additional_lineage boolean not null,
  sourced_thc_label text,
  sourced_cbd_label text,
  sourced_value_evidence jsonb not null,
  primary key (snapshot_id, id)
);

create table catalog.catalog_term_staging (
  snapshot_id uuid not null,
  reference_id uuid not null,
  term text not null,
  language text not null,
  match_reason text not null,
  primary key (
    snapshot_id,
    reference_id,
    term,
    language,
    match_reason
  )
);

alter table catalog.publication_assertion_staging enable row level security;
alter table catalog.catalog_reference_staging enable row level security;
alter table catalog.catalog_term_staging enable row level security;

revoke all on
  catalog.publication_assertion_staging,
  catalog.catalog_reference_staging,
  catalog.catalog_term_staging
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function private.publish_reviewed_catalog()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  snapshot_identifier uuid := gen_random_uuid();
begin
  perform pg_catalog.pg_advisory_xact_lock(20773691, 1);

  insert into catalog.publication_assertion_staging(
    snapshot_id,
    assertion_id,
    assertion_kind,
    payload,
    entity_id,
    related_entity_id,
    reviewed_at,
    source_version,
    retrieved_at,
    retrieval_reference,
    attribution_snapshot,
    source_name
  )
  select
    snapshot_identifier,
    assertion.id as assertion_id,
    assertion.assertion_kind,
    assertion.payload,
    review.entity_id,
    review.related_entity_id,
    review.reviewed_at,
    source_record.source_version,
    source_record.retrieved_at,
    source_record.retrieval_reference,
    source_record.attribution_snapshot,
    source.display_name as source_name
  from catalog.normalized_assertions assertion
  join catalog.assertion_reviews review
    on review.assertion_id = assertion.id
   and review.decision = 'accepted'
  join catalog.source_records source_record
    on source_record.id = assertion.source_record_id
   and source_record.upstream_state = 'present'
   and source_record.license_status_snapshot = 'approved'
  join catalog.sources source
    on source.id = source_record.source_id
   and source.license_status = 'approved'
   and source.status <> 'blocked'
  where (assertion.valid_from is null or assertion.valid_from <= now())
    and (assertion.valid_to is null or assertion.valid_to > now());

  if exists (
    select 1
    from catalog.publication_assertion_staging
    where snapshot_id = snapshot_identifier
      and assertion_kind = 'name'
    group by entity_id
    having count(distinct payload ->> 'name') <> 1
  )
  or exists (
    select 1
    from catalog.publication_assertion_staging
    where snapshot_id = snapshot_identifier
      and assertion_kind = 'name'
      and char_length(payload ->> 'name') not between 1 and 160
  )
  or exists (
    select 1
    from catalog.publication_assertion_staging accepted
    left join catalog.entities entity on entity.id = accepted.entity_id
    where accepted.snapshot_id = snapshot_identifier
      and entity.id is null
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  if exists (
    select 1
    from catalog.publication_assertion_staging accepted
    join catalog.entities entity on entity.id = accepted.entity_id
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'measurement'
      and (
        accepted.payload ->> 'unit' <> 'percent'
        or (
          accepted.payload ->> 'productForm' = 'flower'
          and (accepted.payload ->> 'value')::numeric > 70
        )
      )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  if exists (
    select 1
    from catalog.publication_assertion_staging
    where snapshot_id = snapshot_identifier
      and assertion_kind = 'lineage'
      and payload ->> 'position' in ('1', '2')
    group by entity_id, payload ->> 'position'
    having count(*) > 1
  )
  or exists (
    select 1
    from catalog.publication_assertion_staging accepted
    left join catalog.entities child on child.id = accepted.entity_id
    left join catalog.entities parent on parent.id = accepted.related_entity_id
    left join catalog.publication_assertion_staging parent_name
      on parent_name.snapshot_id = accepted.snapshot_id
     and parent_name.entity_id = accepted.related_entity_id
     and parent_name.assertion_kind = 'name'
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'lineage'
      and (
        child.kind <> 'cultivar'
        or parent.kind <> 'cultivar'
        or parent_name.assertion_id is null
      )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  if exists (
    select 1
    from catalog.publication_assertion_staging
    where snapshot_id = snapshot_identifier
      and assertion_kind = 'product_cultivar'
    group by entity_id
    having count(*) <> 1
  )
  or exists (
    select 1
    from catalog.publication_assertion_staging accepted
    left join catalog.entities product on product.id = accepted.entity_id
    left join catalog.entities cultivar
      on cultivar.id = accepted.related_entity_id
    left join catalog.publication_assertion_staging product_name
      on product_name.snapshot_id = accepted.snapshot_id
     and product_name.entity_id = accepted.entity_id
     and product_name.assertion_kind = 'name'
    left join catalog.publication_assertion_staging cultivar_name
      on cultivar_name.snapshot_id = accepted.snapshot_id
     and cultivar_name.entity_id = accepted.related_entity_id
     and cultivar_name.assertion_kind = 'name'
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'product_cultivar'
      and (
        product.kind <> 'product'
        or cultivar.kind <> 'cultivar'
        or product_name.assertion_id is null
        or cultivar_name.assertion_id is null
      )
  )
  or exists (
    select 1
    from catalog.publication_assertion_staging name_assertion
    join catalog.entities entity on entity.id = name_assertion.entity_id
    left join catalog.publication_assertion_staging mapping
      on mapping.snapshot_id = name_assertion.snapshot_id
     and mapping.entity_id = name_assertion.entity_id
     and mapping.assertion_kind = 'product_cultivar'
    where name_assertion.snapshot_id = snapshot_identifier
      and name_assertion.assertion_kind = 'name'
      and entity.kind = 'product'
    group by name_assertion.entity_id
    having count(distinct mapping.assertion_id) <> 1
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  if exists (
    select 1
    from catalog.publication_assertion_staging accepted
    left join catalog.publication_assertion_staging canonical_name
      on canonical_name.snapshot_id = accepted.snapshot_id
     and canonical_name.entity_id = accepted.entity_id
     and canonical_name.assertion_kind = 'name'
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind in ('alias', 'lineage', 'measurement')
      and canonical_name.assertion_id is null
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  insert into catalog.catalog_reference_staging(
    snapshot_id,
    id,
    kind,
    canonical_name,
    canonical_cultivar_id,
    is_flower,
    preferred_parent_one_name,
    preferred_parent_two_name,
    has_additional_lineage,
    sourced_thc_label,
    sourced_cbd_label,
    sourced_value_evidence
  )
  with canonical_names as (
    select
      accepted.entity_id,
      min(accepted.payload ->> 'name') as canonical_name
    from catalog.publication_assertion_staging accepted
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'name'
    group by accepted.entity_id
  ),
  product_mappings as (
    select
      accepted.entity_id as product_id,
      min(accepted.related_entity_id::text)::uuid as cultivar_id,
      bool_or(accepted.payload ->> 'productForm' = 'flower') as is_flower
    from catalog.publication_assertion_staging accepted
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'product_cultivar'
    group by accepted.entity_id
  ),
  references_with_cultivar as (
    select
      entity.id,
      entity.kind,
      canonical_names.canonical_name,
      case
        when entity.kind = 'cultivar' then entity.id
        else product_mappings.cultivar_id
      end as canonical_cultivar_id,
      coalesce(product_mappings.is_flower, false) as is_flower
    from canonical_names
    join catalog.entities entity on entity.id = canonical_names.entity_id
    left join product_mappings on product_mappings.product_id = entity.id
  ),
  lineage as (
    select
      accepted.entity_id as cultivar_id,
      min(parent_name.canonical_name)
        filter (where accepted.payload ->> 'position' = '1')
        as preferred_parent_one_name,
      min(parent_name.canonical_name)
        filter (where accepted.payload ->> 'position' = '2')
        as preferred_parent_two_name,
      bool_or(accepted.payload -> 'position' = 'null'::jsonb)
        as has_additional_lineage
    from catalog.publication_assertion_staging accepted
    join canonical_names parent_name
      on parent_name.entity_id = accepted.related_entity_id
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'lineage'
    group by accepted.entity_id
  ),
  measurement_ranges as (
    select
      accepted.entity_id,
      accepted.payload ->> 'analyte' as analyte,
      min((accepted.payload ->> 'value')::numeric) as minimum_value,
      max((accepted.payload ->> 'value')::numeric) as maximum_value
    from catalog.publication_assertion_staging accepted
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'measurement'
    group by accepted.entity_id, accepted.payload ->> 'analyte'
  ),
  measurement_labels as (
    select
      ranges.entity_id,
      max(
        case when ranges.analyte = 'thc' then
          case
            when ranges.minimum_value = ranges.maximum_value
              then to_char(ranges.minimum_value, 'FM999999990.999') || ' %'
            else
              to_char(ranges.minimum_value, 'FM999999990.999')
              || '–'
              || to_char(ranges.maximum_value, 'FM999999990.999')
              || ' %'
          end
        end
      ) as sourced_thc_label,
      max(
        case when ranges.analyte = 'cbd' then
          case
            when ranges.minimum_value = ranges.maximum_value
              then to_char(ranges.minimum_value, 'FM999999990.999') || ' %'
            else
              to_char(ranges.minimum_value, 'FM999999990.999')
              || '–'
              || to_char(ranges.maximum_value, 'FM999999990.999')
              || ' %'
          end
        end
      ) as sourced_cbd_label
    from measurement_ranges ranges
    group by ranges.entity_id
  ),
  evidence_rows as (
    select distinct
      accepted.entity_id,
      accepted.source_name,
      accepted.source_version,
      accepted.retrieved_at,
      case
        when accepted.retrieval_reference ~ '^https://'
          then accepted.retrieval_reference
        else null
      end as citation_url,
      accepted.attribution_snapshot
    from catalog.publication_assertion_staging accepted
    where accepted.snapshot_id = snapshot_identifier
      and accepted.assertion_kind = 'measurement'
  ),
  evidence as (
    select
      evidence_rows.entity_id,
      jsonb_agg(
        jsonb_build_object(
          'sourceName', evidence_rows.source_name,
          'sourceVersion', evidence_rows.source_version,
          'retrievedAt', evidence_rows.retrieved_at,
          'citationUrl', evidence_rows.citation_url,
          'attribution', evidence_rows.attribution_snapshot
        )
        order by
          evidence_rows.retrieved_at desc,
          evidence_rows.source_name
      ) as sourced_value_evidence
    from evidence_rows
    group by evidence_rows.entity_id
  )
  select
    snapshot_identifier,
    reference.id,
    reference.kind,
    reference.canonical_name,
    reference.canonical_cultivar_id,
    reference.is_flower,
    lineage.preferred_parent_one_name,
    lineage.preferred_parent_two_name,
    coalesce(lineage.has_additional_lineage, false)
      as has_additional_lineage,
    measurement_labels.sourced_thc_label,
    measurement_labels.sourced_cbd_label,
    coalesce(evidence.sourced_value_evidence, '[]'::jsonb)
      as sourced_value_evidence
  from references_with_cultivar reference
  left join lineage on lineage.cultivar_id = reference.canonical_cultivar_id
  left join measurement_labels
    on measurement_labels.entity_id = reference.id
  left join evidence on evidence.entity_id = reference.id;

  if exists (
    select 1
    from catalog.catalog_reference_staging snapshot
    where snapshot.snapshot_id = snapshot_identifier
      and snapshot.kind = 'product'
      and snapshot.canonical_cultivar_id is null
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid catalog snapshot';
  end if;

  insert into catalog.catalog_term_staging(
    snapshot_id,
    reference_id,
    term,
    language,
    match_reason
  )
  select
    snapshot_identifier,
    snapshot.id as reference_id,
    snapshot.canonical_name as term,
    ''::text as language,
    case
      when snapshot.kind = 'product' then 'product'
      else 'canonical'
    end::text as match_reason
  from catalog.catalog_reference_staging snapshot
  where snapshot.snapshot_id = snapshot_identifier
  union
  select
    snapshot_identifier,
    accepted.entity_id,
    accepted.payload ->> 'name',
    coalesce(accepted.payload ->> 'language', ''),
    'alias'::text
  from catalog.publication_assertion_staging accepted
  join catalog.catalog_reference_staging snapshot
    on snapshot.snapshot_id = accepted.snapshot_id
   and snapshot.id = accepted.entity_id
  where accepted.snapshot_id = snapshot_identifier
    and accepted.assertion_kind = 'alias';

  update catalog.entities entity
  set canonical_name = snapshot.canonical_name,
      published = true
  from catalog.catalog_reference_staging snapshot
  where snapshot.snapshot_id = snapshot_identifier
    and entity.id = snapshot.id;

  update catalog.entities entity
  set published = false
  where entity.published
    and not exists (
      select 1
      from catalog.catalog_reference_staging snapshot
      where snapshot.snapshot_id = snapshot_identifier
        and snapshot.id = entity.id
    );

  insert into api.catalog_references(
    id,
    kind,
    canonical_name,
    canonical_cultivar_id,
    is_flower,
    preferred_parent_one_name,
    preferred_parent_two_name,
    has_additional_lineage,
    sourced_thc_label,
    sourced_cbd_label,
    sourced_value_evidence,
    published_at
  )
  select
    snapshot.id,
    snapshot.kind,
    snapshot.canonical_name,
    snapshot.canonical_cultivar_id,
    snapshot.is_flower,
    snapshot.preferred_parent_one_name,
    snapshot.preferred_parent_two_name,
    snapshot.has_additional_lineage,
    snapshot.sourced_thc_label,
    snapshot.sourced_cbd_label,
    snapshot.sourced_value_evidence,
    now()
  from catalog.catalog_reference_staging snapshot
  where snapshot.snapshot_id = snapshot_identifier
  on conflict (id) do update
  set kind = excluded.kind,
      canonical_name = excluded.canonical_name,
      canonical_cultivar_id = excluded.canonical_cultivar_id,
      is_flower = excluded.is_flower,
      preferred_parent_one_name = excluded.preferred_parent_one_name,
      preferred_parent_two_name = excluded.preferred_parent_two_name,
      has_additional_lineage = excluded.has_additional_lineage,
      sourced_thc_label = excluded.sourced_thc_label,
      sourced_cbd_label = excluded.sourced_cbd_label,
      sourced_value_evidence = excluded.sourced_value_evidence,
      published_at = excluded.published_at;

  delete from catalog.published_search_terms;

  delete from api.catalog_references reference
  where not exists (
      select 1
      from catalog.catalog_reference_staging snapshot
      where snapshot.snapshot_id = snapshot_identifier
        and snapshot.id = reference.id
    )
    and not exists (
      select 1
      from api.inventory_items inventory
      where inventory.entity_id = reference.id
    );

  insert into catalog.published_search_terms(
    reference_id,
    term,
    language,
    match_reason
  )
  select
    term.reference_id,
    term.term,
    term.language,
    term.match_reason
  from catalog.catalog_term_staging term
  where term.snapshot_id = snapshot_identifier;

  delete from catalog.catalog_term_staging
  where snapshot_id = snapshot_identifier;
  delete from catalog.catalog_reference_staging
  where snapshot_id = snapshot_identifier;
  delete from catalog.publication_assertion_staging
  where snapshot_id = snapshot_identifier;
end;
$$;

revoke all on function private.publish_reviewed_catalog()
  from public, anon, authenticated, service_role, source_ingestor;
grant execute on function private.publish_reviewed_catalog()
  to source_reviewer;

create function api.search_catalog_references(p_query text)
returns table (
  id uuid,
  kind text,
  canonical_name text,
  matched_name text,
  match_reason text,
  canonical_cultivar_id uuid,
  is_flower boolean,
  preferred_parents text[],
  has_additional_lineage boolean,
  sourced_thc_label text,
  sourced_cbd_label text,
  sourced_value_evidence jsonb
)
language sql
stable
security definer
set search_path = ''
as $$
  with search_input as (
    select lower(btrim(coalesce(p_query, ''))) as query
  ),
  ranked as (
    select
      reference.id,
      reference.kind,
      reference.canonical_name,
      term.term as matched_name,
      term.match_reason,
      reference.canonical_cultivar_id,
      reference.is_flower,
      array[
        reference.preferred_parent_one_name,
        reference.preferred_parent_two_name
      ]::text[] as preferred_parents,
      reference.has_additional_lineage,
      reference.sourced_thc_label,
      reference.sourced_cbd_label,
      reference.sourced_value_evidence,
      case
        when term.match_reason = 'canonical'
          and lower(term.term) = search_input.query then 0
        when term.match_reason = 'canonical'
          and left(lower(term.term), char_length(search_input.query))
            = search_input.query then 1
        when term.match_reason in ('alias', 'product')
          and lower(term.term) = search_input.query then 2
        when left(lower(term.term), char_length(search_input.query))
          = search_input.query then 3
        else 4
      end as match_rank,
      row_number() over (
        partition by reference.id
        order by
          case
            when term.match_reason = 'canonical'
              and lower(term.term) = search_input.query then 0
            when term.match_reason = 'canonical'
              and left(lower(term.term), char_length(search_input.query))
                = search_input.query then 1
            when term.match_reason in ('alias', 'product')
              and lower(term.term) = search_input.query then 2
            when left(lower(term.term), char_length(search_input.query))
              = search_input.query then 3
            else 4
          end,
          char_length(term.term),
          term.term
      ) as reference_rank
    from search_input
    join catalog.published_search_terms term
      on strpos(lower(term.term), search_input.query) > 0
    join api.catalog_references reference
      on reference.id = term.reference_id
    where search_input.query <> ''
      and char_length(search_input.query) <= 160
  )
  select
    ranked.id,
    ranked.kind,
    ranked.canonical_name,
    ranked.matched_name,
    ranked.match_reason,
    ranked.canonical_cultivar_id,
    ranked.is_flower,
    ranked.preferred_parents,
    ranked.has_additional_lineage,
    ranked.sourced_thc_label,
    ranked.sourced_cbd_label,
    ranked.sourced_value_evidence
  from ranked
  where ranked.reference_rank = 1
  order by
    ranked.match_rank,
    char_length(ranked.matched_name),
    ranked.canonical_name
  limit 8;
$$;

revoke all on function api.search_catalog_references(text)
  from public, anon, service_role, source_ingestor, source_reviewer;
grant execute on function api.search_catalog_references(text)
  to authenticated;
