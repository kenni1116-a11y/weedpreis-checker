alter table catalog.entities
  drop constraint entities_kind_check;

alter table catalog.entities
  add constraint entities_kind_check
  check (
    kind in (
      'origin_population',
      'cultivar',
      'genetic_sample',
      'product'
    )
  );

alter table catalog.import_runs
  add column contract_version smallint not null default 1
    check (contract_version in (1, 2));

alter table catalog.source_records
  add column import_run_id uuid
    references catalog.import_runs(id) on delete restrict;

create index source_records_import_run_idx
  on catalog.source_records(import_run_id)
  where import_run_id is not null;

alter table catalog.assertion_reviews
  add column evidence_status text;

update catalog.assertion_reviews
set evidence_status = 'single_source'
where decision = 'accepted';

alter table catalog.assertion_reviews
  add constraint assertion_reviews_evidence_status_check
  check (
    (
      decision = 'accepted'
      and evidence_status is not null
      and evidence_status in (
        'confirmed',
        'single_source',
        'disputed',
        'historical',
        'unknown',
        'retracted'
      )
    )
    or (
      decision = 'rejected'
      and evidence_status is null
    )
  );

create function private.source_assertion_trace_valid(payload jsonb)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select case
    when jsonb_typeof(payload) <> 'object' then false
    else
      private.jsonb_has_exact_keys(
        payload,
        array['sourceLocator', 'extractionMethod']
      )
      and jsonb_typeof(payload -> 'sourceLocator') = 'string'
      and char_length(payload ->> 'sourceLocator') between 1 and 1000
      and btrim(payload ->> 'sourceLocator') = payload ->> 'sourceLocator'
      and payload ->> 'extractionMethod'
        in ('structured', 'manual', 'ai_assisted')
  end;
$$;

revoke all on function private.source_assertion_trace_valid(jsonb)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create or replace function private.source_assertion_payload_valid(
  expected_kind text,
  payload jsonb
)
returns boolean
language sql
immutable
security invoker
set search_path = ''
as $$
  select coalesce(
    case
      when jsonb_typeof(payload) <> 'object' then false
      when expected_kind = 'entity_kind' then
        private.jsonb_has_exact_keys(
          payload,
          array['kind', 'trace', 'subjectExternalKey', 'entityKind']
        )
        and payload ->> 'kind' = 'entity_kind'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and payload ->> 'entityKind' in (
          'origin_population',
          'cultivar',
          'genetic_sample',
          'product'
        )
      when expected_kind = 'name' then
        (
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
        )
        or
        (
          private.jsonb_has_exact_keys(
            payload,
            array[
              'kind',
              'trace',
              'subjectExternalKey',
              'name',
              'language'
            ]
          )
          and payload ->> 'kind' = 'name'
          and private.source_assertion_trace_valid(payload -> 'trace')
          and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
          and char_length(payload ->> 'subjectExternalKey') between 1 and 240
          and btrim(payload ->> 'subjectExternalKey')
            = payload ->> 'subjectExternalKey'
          and jsonb_typeof(payload -> 'name') = 'string'
          and char_length(payload ->> 'name') between 1 and 240
          and btrim(payload ->> 'name') = payload ->> 'name'
          and (
            payload -> 'language' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'language') = 'string'
              and char_length(payload ->> 'language') between 1 and 35
              and btrim(payload ->> 'language') = payload ->> 'language'
              and payload ->> 'language'
                ~ '^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$'
            )
          )
        )
      when expected_kind = 'alias' then
        (
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
        )
        or
        (
          private.jsonb_has_exact_keys(
            payload,
            array[
              'kind',
              'trace',
              'subjectExternalKey',
              'name',
              'language',
              'aliasType',
              'market'
            ]
          )
          and payload ->> 'kind' = 'alias'
          and private.source_assertion_trace_valid(payload -> 'trace')
          and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
          and char_length(payload ->> 'subjectExternalKey') between 1 and 240
          and btrim(payload ->> 'subjectExternalKey')
            = payload ->> 'subjectExternalKey'
          and jsonb_typeof(payload -> 'name') = 'string'
          and char_length(payload ->> 'name') between 1 and 240
          and btrim(payload ->> 'name') = payload ->> 'name'
          and (
            payload -> 'language' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'language') = 'string'
              and char_length(payload ->> 'language') between 1 and 35
              and btrim(payload ->> 'language') = payload ->> 'language'
              and payload ->> 'language'
                ~ '^[A-Za-z]{2,8}(-[A-Za-z0-9]{1,8})*$'
            )
          )
          and payload ->> 'aliasType'
            in ('spelling', 'breeder', 'market', 'historical', 'other')
          and (
            payload -> 'market' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'market') = 'string'
              and char_length(payload ->> 'market') between 1 and 240
              and btrim(payload ->> 'market') = payload ->> 'market'
            )
          )
        )
      when expected_kind = 'traditional_classification' then
        private.jsonb_has_exact_keys(
          payload,
          array['kind', 'trace', 'subjectExternalKey', 'classification']
        )
        and payload ->> 'kind' = 'traditional_classification'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and payload ->> 'classification' in ('sativa', 'indica', 'hybrid')
      when expected_kind = 'origin_region' then
        private.jsonb_has_exact_keys(
          payload,
          array[
            'kind',
            'trace',
            'subjectExternalKey',
            'regionName',
            'regionCode'
          ]
        )
        and payload ->> 'kind' = 'origin_region'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and jsonb_typeof(payload -> 'regionName') = 'string'
        and char_length(payload ->> 'regionName') between 1 and 240
        and btrim(payload ->> 'regionName') = payload ->> 'regionName'
        and (
          payload -> 'regionCode' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'regionCode') = 'string'
            and char_length(payload ->> 'regionCode') between 1 and 35
            and btrim(payload ->> 'regionCode') = payload ->> 'regionCode'
          )
        )
      when expected_kind = 'era' then
        private.jsonb_has_exact_keys(
          payload,
          array[
            'kind',
            'trace',
            'subjectExternalKey',
            'startYear',
            'endYear',
            'label'
          ]
        )
        and payload ->> 'kind' = 'era'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and (
          payload -> 'startYear' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'startYear') = 'number'
            and (payload ->> 'startYear')::numeric
              = trunc((payload ->> 'startYear')::numeric)
            and (payload ->> 'startYear')::numeric between -10000 and 2100
          )
        )
        and (
          payload -> 'endYear' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'endYear') = 'number'
            and (payload ->> 'endYear')::numeric
              = trunc((payload ->> 'endYear')::numeric)
            and (payload ->> 'endYear')::numeric between -10000 and 2100
          )
        )
        and (
          payload -> 'startYear' = 'null'::jsonb
          or payload -> 'endYear' = 'null'::jsonb
          or (payload ->> 'endYear')::numeric
            >= (payload ->> 'startYear')::numeric
        )
        and (
          payload -> 'label' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'label') = 'string'
            and char_length(payload ->> 'label') between 1 and 240
            and btrim(payload ->> 'label') = payload ->> 'label'
          )
        )
      when expected_kind = 'sample_reference' then
        private.jsonb_has_exact_keys(
          payload,
          array[
            'kind',
            'trace',
            'subjectExternalKey',
            'sampleIdentifier',
            'datasetName',
            'datasetVersion',
            'submitter',
            'laboratory',
            'sampledAt'
          ]
        )
        and payload ->> 'kind' = 'sample_reference'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and jsonb_typeof(payload -> 'sampleIdentifier') = 'string'
        and char_length(payload ->> 'sampleIdentifier') between 1 and 240
        and btrim(payload ->> 'sampleIdentifier')
          = payload ->> 'sampleIdentifier'
        and jsonb_typeof(payload -> 'datasetName') = 'string'
        and char_length(payload ->> 'datasetName') between 1 and 240
        and btrim(payload ->> 'datasetName') = payload ->> 'datasetName'
        and (
          payload -> 'datasetVersion' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'datasetVersion') = 'string'
            and char_length(payload ->> 'datasetVersion') between 1 and 160
            and btrim(payload ->> 'datasetVersion')
              = payload ->> 'datasetVersion'
          )
        )
        and (
          payload -> 'submitter' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'submitter') = 'string'
            and char_length(payload ->> 'submitter') between 1 and 240
            and btrim(payload ->> 'submitter') = payload ->> 'submitter'
          )
        )
        and (
          payload -> 'laboratory' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'laboratory') = 'string'
            and char_length(payload ->> 'laboratory') between 1 and 240
            and btrim(payload ->> 'laboratory') = payload ->> 'laboratory'
          )
        )
        and (
          payload -> 'sampledAt' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'sampledAt') = 'string'
            and payload ->> 'sampledAt'
              ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})$'
          )
        )
      when expected_kind = 'lineage' then
        (
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
        )
        or
        (
          private.jsonb_has_exact_keys(
            payload,
            array[
              'kind',
              'trace',
              'subjectExternalKey',
              'relatedExternalKey',
              'relationship',
              'position'
            ]
          )
          and payload ->> 'kind' = 'lineage'
          and private.source_assertion_trace_valid(payload -> 'trace')
          and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
          and char_length(payload ->> 'subjectExternalKey') between 1 and 240
          and btrim(payload ->> 'subjectExternalKey')
            = payload ->> 'subjectExternalKey'
          and payload ->> 'relationship' in (
            'reported_parent',
            'cross',
            'backcross',
            'selection_from',
            'historical_origin',
            'population_membership',
            'unknown_parent'
          )
          and (
            (
              payload ->> 'relationship' = 'unknown_parent'
              and payload -> 'relatedExternalKey' = 'null'::jsonb
            )
            or
            (
              payload ->> 'relationship' <> 'unknown_parent'
              and jsonb_typeof(payload -> 'relatedExternalKey') = 'string'
              and char_length(payload ->> 'relatedExternalKey')
                between 1 and 240
              and btrim(payload ->> 'relatedExternalKey')
                = payload ->> 'relatedExternalKey'
            )
          )
          and (
            payload -> 'position' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'position') = 'number'
              and payload ->> 'position' in ('1', '2')
            )
          )
        )
      when expected_kind = 'genetic_relation' then
        private.jsonb_has_exact_keys(
          payload,
          array[
            'kind',
            'trace',
            'subjectExternalKey',
            'relatedExternalKey',
            'relationship',
            'method',
            'datasetName',
            'datasetVersion',
            'metricName',
            'value',
            'unit'
          ]
        )
        and payload ->> 'kind' = 'genetic_relation'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and jsonb_typeof(payload -> 'relatedExternalKey') = 'string'
        and char_length(payload ->> 'relatedExternalKey') between 1 and 240
        and btrim(payload ->> 'relatedExternalKey')
          = payload ->> 'relatedExternalKey'
        and payload ->> 'relatedExternalKey'
          <> payload ->> 'subjectExternalKey'
        and payload ->> 'relationship'
          in ('genetic_similarity', 'sample_match')
        and jsonb_typeof(payload -> 'method') = 'string'
        and char_length(payload ->> 'method') between 1 and 240
        and btrim(payload ->> 'method') = payload ->> 'method'
        and jsonb_typeof(payload -> 'datasetName') = 'string'
        and char_length(payload ->> 'datasetName') between 1 and 240
        and btrim(payload ->> 'datasetName') = payload ->> 'datasetName'
        and (
          payload -> 'datasetVersion' = 'null'::jsonb
          or (
            jsonb_typeof(payload -> 'datasetVersion') = 'string'
            and char_length(payload ->> 'datasetVersion') between 1 and 160
            and btrim(payload ->> 'datasetVersion')
              = payload ->> 'datasetVersion'
          )
        )
        and jsonb_typeof(payload -> 'metricName') = 'string'
        and char_length(payload ->> 'metricName') between 1 and 240
        and btrim(payload ->> 'metricName') = payload ->> 'metricName'
        and (
          (
            payload -> 'value' = 'null'::jsonb
            and payload -> 'unit' = 'null'::jsonb
          )
          or
          (
            jsonb_typeof(payload -> 'value') = 'number'
            and jsonb_typeof(payload -> 'unit') = 'string'
            and char_length(payload ->> 'unit') between 1 and 100
            and btrim(payload ->> 'unit') = payload ->> 'unit'
          )
        )
        and (
          payload ->> 'relationship' <> 'sample_match'
          or (
            payload -> 'value' = 'null'::jsonb
            and payload -> 'unit' = 'null'::jsonb
          )
        )
      when expected_kind = 'product_cultivar' then
        (
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
        )
        or
        (
          private.jsonb_has_exact_keys(
            payload,
            array[
              'kind',
              'trace',
              'subjectExternalKey',
              'cultivarExternalKey',
              'productForm'
            ]
          )
          and payload ->> 'kind' = 'product_cultivar'
          and private.source_assertion_trace_valid(payload -> 'trace')
          and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
          and char_length(payload ->> 'subjectExternalKey') between 1 and 240
          and btrim(payload ->> 'subjectExternalKey')
            = payload ->> 'subjectExternalKey'
          and jsonb_typeof(payload -> 'cultivarExternalKey') = 'string'
          and char_length(payload ->> 'cultivarExternalKey') between 1 and 240
          and btrim(payload ->> 'cultivarExternalKey')
            = payload ->> 'cultivarExternalKey'
          and payload ->> 'productForm'
            in ('flower', 'extract', 'oil', 'other')
        )
      when expected_kind = 'product_market' then
        private.jsonb_has_exact_keys(
          payload,
          array[
            'kind',
            'trace',
            'subjectExternalKey',
            'countryCode',
            'medical'
          ]
        )
        and payload ->> 'kind' = 'product_market'
        and private.source_assertion_trace_valid(payload -> 'trace')
        and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
        and char_length(payload ->> 'subjectExternalKey') between 1 and 240
        and btrim(payload ->> 'subjectExternalKey')
          = payload ->> 'subjectExternalKey'
        and jsonb_typeof(payload -> 'countryCode') = 'string'
        and payload ->> 'countryCode' ~ '^[A-Z]{2}$'
        and payload -> 'medical' = 'true'::jsonb
      when expected_kind = 'measurement' then
        (
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
              and payload ->> 'measuredAt' ~ '^\d{4}-\d{2}-\d{2}T'
            )
          )
        )
        or
        (
          private.jsonb_has_exact_keys(
            payload,
            array[
              'kind',
              'trace',
              'subjectExternalKey',
              'analyte',
              'value',
              'unit',
              'productForm',
              'batchIdentifier',
              'measuredAt'
            ]
          )
          and payload ->> 'kind' = 'measurement'
          and private.source_assertion_trace_valid(payload -> 'trace')
          and jsonb_typeof(payload -> 'subjectExternalKey') = 'string'
          and char_length(payload ->> 'subjectExternalKey') between 1 and 240
          and btrim(payload ->> 'subjectExternalKey')
            = payload ->> 'subjectExternalKey'
          and payload ->> 'analyte' in ('thc', 'cbd')
          and jsonb_typeof(payload -> 'value') = 'number'
          and payload ->> 'unit' = 'percent'
          and payload ->> 'productForm'
            in ('flower', 'extract', 'oil', 'other')
          and (
            payload -> 'batchIdentifier' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'batchIdentifier') = 'string'
              and char_length(payload ->> 'batchIdentifier') between 1 and 240
              and btrim(payload ->> 'batchIdentifier')
                = payload ->> 'batchIdentifier'
            )
          )
          and (
            payload -> 'measuredAt' = 'null'::jsonb
            or (
              jsonb_typeof(payload -> 'measuredAt') = 'string'
              and payload ->> 'measuredAt'
                ~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})$'
            )
          )
        )
      else false
    end,
    false
  );
$$;

alter table catalog.normalized_assertions
  drop constraint normalized_assertions_assertion_kind_check;

alter table catalog.normalized_assertions
  add constraint normalized_assertions_assertion_kind_check
  check (
    assertion_kind in (
      'entity_kind',
      'name',
      'alias',
      'traditional_classification',
      'origin_region',
      'era',
      'sample_reference',
      'lineage',
      'genetic_relation',
      'product_cultivar',
      'product_market',
      'measurement'
    )
  );

create or replace function private.record_source_import(p_batch jsonb)
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
  assertion_ordinality bigint;
begin
  if not private.jsonb_has_exact_keys(
    p_batch,
    array[
      'contractVersion',
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

  if jsonb_typeof(p_batch -> 'contractVersion') <> 'number' then
    raise exception using
      errcode = '22023',
      message = 'Invalid source import contract version';
  end if;
  if (p_batch ->> 'contractVersion')::numeric <> 2 then
    raise exception using
      errcode = '22023',
      message = 'Invalid source import contract version';
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
    adapter_errors,
    contract_version
  ) values (
    source_row.id,
    (p_batch ->> 'startedAt')::timestamptz,
    (p_batch ->> 'completedAt')::timestamptz,
    nullif(p_batch ->> 'cursor', ''),
    p_batch -> 'errors',
    2
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
      import_run_id,
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
      run_identifier,
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
      if not private.source_assertion_trace_valid(assertion_value -> 'trace')
         or not private.source_assertion_payload_valid(
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
             and coalesce(
               existing.payload ->> 'relatedExternalKey',
               existing.payload ->> 'parentExternalKey'
             ) <> assertion_value ->> 'relatedExternalKey'
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

create or replace function private.review_source_assertion(
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
    note,
    evidence_status
  ) values (
    p_assertion_id,
    p_decision,
    p_entity_id,
    p_related_entity_id,
    reviewer,
    review_time,
    nullif(btrim(p_note), ''),
    case
      when p_decision = 'accepted' then 'single_source'
      else null
    end
  )
  on conflict (assertion_id) do update
  set decision = excluded.decision,
      entity_id = excluded.entity_id,
      related_entity_id = excluded.related_entity_id,
      reviewer_name = excluded.reviewer_name,
      reviewed_at = excluded.reviewed_at,
      note = excluded.note,
      evidence_status = excluded.evidence_status;

  update catalog.review_cases
  set status = 'closed',
      decision = p_decision,
      reviewer_name = reviewer,
      reviewed_at = review_time,
      note = nullif(btrim(p_note), '')
  where assertion_id = p_assertion_id;
end;
$$;

create table catalog.knowledge_publication_snapshots (
  id uuid primary key default gen_random_uuid(),
  previous_snapshot_id uuid
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  published_by text not null check (char_length(published_by) between 1 and 240),
  published_at timestamptz not null default now(),
  assertion_count integer not null check (assertion_count >= 0)
);

create table catalog.knowledge_current_snapshot (
  singleton boolean primary key default true check (singleton),
  snapshot_id uuid not null unique
    references catalog.knowledge_publication_snapshots(id) on delete restrict
);

create table catalog.knowledge_snapshot_nodes (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  entity_id uuid not null references catalog.entities(id) on delete restrict,
  kind text not null check (
    kind in ('origin_population', 'cultivar', 'genetic_sample', 'product')
  ),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160),
  primary key (snapshot_id, entity_id)
);

create table catalog.knowledge_snapshot_claims (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  assertion_id uuid not null
    references catalog.normalized_assertions(id) on delete restrict,
  entity_id uuid not null references catalog.entities(id) on delete restrict,
  claim_kind text not null check (
    claim_kind in (
      'entity_kind',
      'name',
      'alias',
      'traditional_classification',
      'origin_region',
      'era',
      'sample_reference',
      'product_market',
      'measurement'
    )
  ),
  value jsonb not null,
  evidence_status text not null,
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object'),
  primary key (snapshot_id, assertion_id)
);

create table catalog.knowledge_snapshot_edges (
  snapshot_id uuid not null
    references catalog.knowledge_publication_snapshots(id) on delete restrict,
  assertion_id uuid not null
    references catalog.normalized_assertions(id) on delete restrict,
  from_entity_id uuid not null
    references catalog.entities(id) on delete restrict,
  to_entity_id uuid references catalog.entities(id) on delete restrict,
  layer text not null check (
    layer in ('documented_lineage', 'genetic_similarity', 'product_mapping')
  ),
  relationship text not null check (
    relationship in (
      'reported_parent',
      'cross',
      'backcross',
      'selection_from',
      'historical_origin',
      'population_membership',
      'unknown_parent',
      'genetic_similarity',
      'sample_match',
      'product_cultivar'
    )
  ),
  position smallint check (position in (1, 2)),
  evidence_status text not null,
  details jsonb not null check (jsonb_typeof(details) = 'object'),
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object'),
  primary key (snapshot_id, assertion_id)
);

create function private.reject_knowledge_snapshot_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  raise exception using
    errcode = '55000',
    message = 'knowledge publication snapshots are immutable';
end;
$$;

revoke all on function private.reject_knowledge_snapshot_mutation()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create trigger knowledge_publication_snapshots_are_immutable
  before update or delete on catalog.knowledge_publication_snapshots
  for each row execute function private.reject_knowledge_snapshot_mutation();

create trigger knowledge_snapshot_nodes_are_immutable
  before update or delete on catalog.knowledge_snapshot_nodes
  for each row execute function private.reject_knowledge_snapshot_mutation();

create trigger knowledge_snapshot_claims_are_immutable
  before update or delete on catalog.knowledge_snapshot_claims
  for each row execute function private.reject_knowledge_snapshot_mutation();

create trigger knowledge_snapshot_edges_are_immutable
  before update or delete on catalog.knowledge_snapshot_edges
  for each row execute function private.reject_knowledge_snapshot_mutation();

alter table catalog.knowledge_publication_snapshots enable row level security;
alter table catalog.knowledge_current_snapshot enable row level security;
alter table catalog.knowledge_snapshot_nodes enable row level security;
alter table catalog.knowledge_snapshot_claims enable row level security;
alter table catalog.knowledge_snapshot_edges enable row level security;

revoke all on
  catalog.knowledge_publication_snapshots,
  catalog.knowledge_current_snapshot,
  catalog.knowledge_snapshot_nodes,
  catalog.knowledge_snapshot_claims,
  catalog.knowledge_snapshot_edges
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
