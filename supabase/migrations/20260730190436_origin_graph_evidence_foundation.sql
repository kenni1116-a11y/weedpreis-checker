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
  select coalesce(case
    when jsonb_typeof(payload) is distinct from 'object' then false
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
  end, false);
$$;

revoke all on function private.source_assertion_trace_valid(jsonb)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function private.source_timestamp_valid(value text)
returns boolean
language plpgsql
immutable
security invoker
set search_path = ''
as $$
declare
  year_value integer;
  month_value integer;
  day_value integer;
  hour_value integer;
  minute_value integer;
  second_value integer;
  parsed_value timestamptz;
begin
  if value is null
     or value !~ '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(\.\d{1,9})?(Z|[+-]\d{2}:\d{2})$' then
    return false;
  end if;

  year_value := substring(value from 1 for 4)::integer;
  month_value := substring(value from 6 for 2)::integer;
  day_value := substring(value from 9 for 2)::integer;
  hour_value := substring(value from 12 for 2)::integer;
  minute_value := substring(value from 15 for 2)::integer;
  second_value := substring(value from 18 for 2)::integer;

  if hour_value not between 0 and 23
     or minute_value not between 0 and 59
     or second_value not between 0 and 59 then
    return false;
  end if;

  begin
    perform pg_catalog.make_date(year_value, month_value, day_value);
    parsed_value := value::timestamptz;
  exception
    when others then
      return false;
  end;

  return parsed_value is not null;
end;
$$;

revoke all on function private.source_timestamp_valid(text)
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
            and private.source_timestamp_valid(payload ->> 'sampledAt')
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
              and private.source_timestamp_valid(payload ->> 'measuredAt')
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
              and private.source_timestamp_valid(payload ->> 'measuredAt')
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
      if not coalesce(
           private.source_assertion_trace_valid(assertion_value -> 'trace'),
           false
         )
         or not coalesce(
           private.source_assertion_payload_valid(
             assertion_value ->> 'kind',
             assertion_value
           ),
           false
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
  import_contract_version smallint;
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

  select import_run.contract_version
  into import_contract_version
  from catalog.source_records as source_record
  left join catalog.import_runs as import_run
    on import_run.id = source_record.import_run_id
   and import_run.source_id = source_record.source_id
  where source_record.id = assertion_row.source_record_id;

  if coalesce(import_contract_version, 1) = 2 then
    raise exception using
      errcode = '22023',
      message = 'Version-2 assertions require knowledge review';
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

create function private.review_knowledge_assertion(
  p_assertion_id uuid,
  p_decision text,
  p_entity_id uuid,
  p_related_entity_id uuid,
  p_evidence_status text,
  p_note text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  assertion_row catalog.normalized_assertions%rowtype;
  source_status text;
  import_contract_version smallint;
  entity_kind text;
  related_kind text;
  relationship_kind text;
  reviewer text := session_user::text;
  review_time timestamptz := now();
begin
  select assertion.*
  into assertion_row
  from catalog.normalized_assertions as assertion
  join catalog.source_records as source_record
    on source_record.id = assertion.source_record_id
  join catalog.sources as source
    on source.id = source_record.source_id
  where assertion.id = p_assertion_id
  for update of assertion, source_record, source;

  if not found then
    raise exception using
      errcode = '22023',
      message = 'Unknown knowledge assertion';
  end if;

  select source.status
  into source_status
  from catalog.sources as source
  join catalog.source_records as source_record
    on source_record.source_id = source.id
  where source_record.id = assertion_row.source_record_id;

  select import_run.contract_version
  into import_contract_version
  from catalog.source_records as source_record
  join catalog.import_runs as import_run
    on import_run.id = source_record.import_run_id
   and import_run.source_id = source_record.source_id
  where source_record.id = assertion_row.source_record_id
  for update of import_run;

  if import_contract_version is distinct from 2
     or assertion_row.assertion_kind not in (
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
     ) then
    raise exception using
      errcode = '22023',
      message = 'Knowledge review requires a version-2 graph assertion';
  end if;

  if p_decision is null
     or p_decision not in ('accepted', 'rejected')
     or char_length(coalesce(p_note, '')) > 1000 then
    raise exception using
      errcode = '22023',
      message = 'Invalid knowledge review';
  end if;

  if p_decision = 'rejected' then
    if p_entity_id is not null
       or p_related_entity_id is not null
       or p_evidence_status is not null then
      raise exception using
        errcode = '22023',
        message = 'Rejected knowledge assertions cannot map canonical entities or evidence';
    end if;
  else
    if source_status = 'blocked' then
      raise exception using
        errcode = '42501',
        message = 'Blocked source assertions cannot be accepted';
    end if;

    if p_entity_id is null then
      raise exception using
        errcode = '22023',
        message = 'Accepted knowledge assertions require a canonical entity';
    end if;

    if p_evidence_status is null
       or p_evidence_status not in (
         'confirmed',
         'single_source',
         'disputed',
         'historical',
         'unknown',
         'retracted'
       ) then
      raise exception using
        errcode = '22023',
        message = 'Accepted knowledge assertions require a valid evidence status';
    end if;

    select entity.kind
    into entity_kind
    from catalog.entities as entity
    where entity.id = p_entity_id;

    if entity_kind is null then
      raise exception using
        errcode = '22023',
        message = 'Unknown canonical entity';
    end if;

    if p_related_entity_id is not null then
      select entity.kind
      into related_kind
      from catalog.entities as entity
      where entity.id = p_related_entity_id;

      if related_kind is null then
        raise exception using
          errcode = '22023',
          message = 'Unknown related canonical entity';
      end if;
    end if;

    if assertion_row.assertion_kind = 'entity_kind' then
      if entity_kind <> assertion_row.payload ->> 'entityKind' then
        raise exception using
          errcode = '22023',
          message = 'Canonical entity kind does not match the assertion';
      end if;
    end if;

    if assertion_row.assertion_kind in ('measurement', 'product_market')
       and entity_kind <> 'product' then
      raise exception using
        errcode = '22023',
        message = 'Product evidence requires a product entity';
    elsif assertion_row.assertion_kind = 'sample_reference'
          and entity_kind <> 'genetic_sample' then
      raise exception using
        errcode = '22023',
        message = 'Sample references require a genetic sample entity';
    end if;

    if assertion_row.assertion_kind = 'measurement'
       and assertion_row.payload ->> 'productForm' = 'flower'
       and (assertion_row.payload ->> 'value')::numeric > 70 then
      raise exception using
        errcode = '22023',
        message = 'Unrealistic flower measurements cannot be accepted';
    end if;

    if assertion_row.assertion_kind = 'lineage' then
      relationship_kind := assertion_row.payload ->> 'relationship';

      if relationship_kind in ('reported_parent', 'cross', 'backcross') then
        if p_related_entity_id is null
           or entity_kind <> 'cultivar'
           or related_kind <> 'cultivar' then
          raise exception using
            errcode = '22023',
            message = 'Documented parentage requires two cultivars';
        end if;
      elsif relationship_kind = 'selection_from' then
        if p_related_entity_id is null
           or entity_kind <> 'cultivar'
           or related_kind not in ('cultivar', 'origin_population') then
          raise exception using
            errcode = '22023',
            message = 'Selection requires a cultivar and a cultivar or origin population';
        end if;
      elsif relationship_kind = 'historical_origin' then
        if p_related_entity_id is null
           or entity_kind not in ('cultivar', 'origin_population')
           or related_kind <> 'origin_population'
           or p_entity_id = p_related_entity_id then
          raise exception using
            errcode = '22023',
            message = 'Historical origin requires a distinct origin population';
        end if;
      elsif relationship_kind = 'population_membership' then
        if p_related_entity_id is null
           or entity_kind not in ('cultivar', 'genetic_sample')
           or related_kind <> 'origin_population' then
          raise exception using
            errcode = '22023',
            message = 'Population membership requires a cultivar or genetic sample and an origin population';
        end if;
      elsif relationship_kind = 'unknown_parent' then
        if entity_kind <> 'cultivar'
           or p_related_entity_id is not null then
          raise exception using
            errcode = '22023',
            message = 'Unknown parent requires a cultivar without a related entity';
        end if;
      else
        raise exception using
          errcode = '22023',
          message = 'Unsupported lineage relationship';
      end if;
    elsif assertion_row.assertion_kind = 'genetic_relation' then
      if p_related_entity_id is null
         or entity_kind <> 'genetic_sample'
         or related_kind <> 'genetic_sample'
         or p_entity_id = p_related_entity_id then
        raise exception using
          errcode = '22023',
          message = 'Genetic relations require two different genetic samples';
      end if;
    elsif assertion_row.assertion_kind = 'product_cultivar' then
      if p_related_entity_id is null
         or entity_kind <> 'product'
         or related_kind <> 'cultivar' then
        raise exception using
          errcode = '22023',
          message = 'Product mapping requires a product and cultivar';
      end if;
    elsif p_related_entity_id is not null then
      raise exception using
        errcode = '22023',
        message = 'This knowledge assertion has no related entity';
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
    p_evidence_status
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

revoke all on function private.review_knowledge_assertion(
  uuid, text, uuid, uuid, text, text
) from public, anon, authenticated, service_role, source_ingestor;

grant execute on function private.review_knowledge_assertion(
  uuid, text, uuid, uuid, text, text
) to source_reviewer;

create function private.legacy_catalog_entity_has_name(p_entity_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from catalog.normalized_assertions as assertion
    join catalog.assertion_reviews as review
      on review.assertion_id = assertion.id
     and review.decision = 'accepted'
     and review.entity_id = p_entity_id
    join catalog.source_records as source_record
      on source_record.id = assertion.source_record_id
     and source_record.upstream_state = 'present'
     and source_record.license_status_snapshot = 'approved'
    left join catalog.import_runs as import_run
      on import_run.id = source_record.import_run_id
     and import_run.source_id = source_record.source_id
    join catalog.sources as source
      on source.id = source_record.source_id
     and source.license_status = 'approved'
     and source.status <> 'blocked'
    join catalog.entities as entity
      on entity.id = review.entity_id
     and entity.kind in ('cultivar', 'product')
    where assertion.assertion_kind = 'name'
      and (
        coalesce(import_run.contract_version, 1) = 1
        or (
          import_run.contract_version = 2
          and review.evidence_status in ('confirmed', 'single_source')
        )
      )
      and (source_record.valid_from is null or source_record.valid_from <= now())
      and (source_record.valid_to is null or source_record.valid_to > now())
      and (assertion.valid_from is null or assertion.valid_from <= now())
      and (assertion.valid_to is null or assertion.valid_to > now())
  );
$$;

revoke all on function private.legacy_catalog_entity_has_name(uuid)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function private.legacy_catalog_product_has_mapping(p_product_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select exists (
    select 1
    from catalog.normalized_assertions as assertion
    join catalog.assertion_reviews as review
      on review.assertion_id = assertion.id
     and review.decision = 'accepted'
     and review.entity_id = p_product_id
    join catalog.source_records as source_record
      on source_record.id = assertion.source_record_id
     and source_record.upstream_state = 'present'
     and source_record.license_status_snapshot = 'approved'
    left join catalog.import_runs as import_run
      on import_run.id = source_record.import_run_id
     and import_run.source_id = source_record.source_id
    join catalog.sources as source
      on source.id = source_record.source_id
     and source.license_status = 'approved'
     and source.status <> 'blocked'
    join catalog.entities as product
      on product.id = review.entity_id
     and product.kind = 'product'
    join catalog.entities as cultivar
      on cultivar.id = review.related_entity_id
     and cultivar.kind = 'cultivar'
    where assertion.assertion_kind = 'product_cultivar'
      and (
        coalesce(import_run.contract_version, 1) = 1
        or (
          import_run.contract_version = 2
          and review.evidence_status in ('confirmed', 'single_source')
        )
      )
      and private.legacy_catalog_entity_has_name(product.id)
      and private.legacy_catalog_entity_has_name(cultivar.id)
      and (source_record.valid_from is null or source_record.valid_from <= now())
      and (source_record.valid_to is null or source_record.valid_to > now())
      and (assertion.valid_from is null or assertion.valid_from <= now())
      and (assertion.valid_to is null or assertion.valid_to > now())
  );
$$;

revoke all on function private.legacy_catalog_product_has_mapping(uuid)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

create function private.legacy_catalog_assertion_eligible(p_assertion_id uuid)
returns boolean
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce((
    select case
      when coalesce(import_run.contract_version, 1) = 1 then true
      when import_run.contract_version <> 2
        or review.evidence_status not in ('confirmed', 'single_source')
        then false
      when assertion.assertion_kind = 'name' then
        entity.kind = 'cultivar'
        or (
          entity.kind = 'product'
          and private.legacy_catalog_product_has_mapping(entity.id)
        )
      when assertion.assertion_kind = 'alias' then
        entity.kind in ('cultivar', 'product')
        and private.legacy_catalog_entity_has_name(entity.id)
        and (
          entity.kind = 'cultivar'
          or private.legacy_catalog_product_has_mapping(entity.id)
        )
      when assertion.assertion_kind = 'measurement' then
        entity.kind = 'product'
        and private.legacy_catalog_entity_has_name(entity.id)
        and private.legacy_catalog_product_has_mapping(entity.id)
      when assertion.assertion_kind = 'product_cultivar' then
        entity.kind = 'product'
        and related_entity.kind = 'cultivar'
        and private.legacy_catalog_product_has_mapping(entity.id)
      when assertion.assertion_kind = 'lineage' then
        assertion.payload ->> 'relationship' in (
          'reported_parent',
          'cross',
          'backcross',
          'selection_from'
        )
        and entity.kind = 'cultivar'
        and related_entity.kind = 'cultivar'
        and private.legacy_catalog_entity_has_name(entity.id)
        and private.legacy_catalog_entity_has_name(related_entity.id)
      else false
    end
    from catalog.normalized_assertions as assertion
    join catalog.assertion_reviews as review
      on review.assertion_id = assertion.id
     and review.decision = 'accepted'
    join catalog.source_records as source_record
      on source_record.id = assertion.source_record_id
    left join catalog.import_runs as import_run
      on import_run.id = source_record.import_run_id
     and import_run.source_id = source_record.source_id
    join catalog.entities as entity
      on entity.id = review.entity_id
    left join catalog.entities as related_entity
      on related_entity.id = review.related_entity_id
    where assertion.id = p_assertion_id
  ), false);
$$;

revoke all on function private.legacy_catalog_assertion_eligible(uuid)
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

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
  evidence_status text not null check (
    evidence_status in (
      'confirmed',
      'single_source',
      'disputed',
      'historical',
      'unknown',
      'retracted'
    )
  ),
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
  evidence_status text not null check (
    evidence_status in (
      'confirmed',
      'single_source',
      'disputed',
      'historical',
      'unknown',
      'retracted'
    )
  ),
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

create table api.published_knowledge_snapshot (
  singleton boolean primary key default true check (singleton),
  snapshot_id uuid not null unique,
  published_at timestamptz not null
);

create table api.published_knowledge_nodes (
  snapshot_id uuid not null,
  id uuid primary key,
  kind text not null check (
    kind in ('origin_population', 'cultivar', 'genetic_sample', 'product')
  ),
  canonical_name text not null
    check (char_length(canonical_name) between 1 and 160)
);

create table api.published_knowledge_claims (
  snapshot_id uuid not null,
  assertion_id uuid primary key,
  node_id uuid not null
    references api.published_knowledge_nodes(id) on delete cascade,
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
  evidence_status text not null check (
    evidence_status in (
      'confirmed',
      'single_source',
      'disputed',
      'historical',
      'unknown',
      'retracted'
    )
  ),
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object')
);

create table api.published_knowledge_edges (
  snapshot_id uuid not null,
  assertion_id uuid primary key,
  from_node_id uuid not null
    references api.published_knowledge_nodes(id) on delete cascade,
  to_node_id uuid
    references api.published_knowledge_nodes(id) on delete cascade,
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
  evidence_status text not null check (
    evidence_status in (
      'confirmed',
      'single_source',
      'disputed',
      'historical',
      'unknown',
      'retracted'
    )
  ),
  details jsonb not null check (jsonb_typeof(details) = 'object'),
  evidence jsonb not null check (jsonb_typeof(evidence) = 'object')
);

create function private.publish_reviewed_knowledge_graph()
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  accepted_assertions jsonb;
  snapshot_identifier uuid := extensions.gen_random_uuid();
  previous_snapshot_identifier uuid;
  publication_time timestamptz := pg_catalog.now();
begin
  perform pg_catalog.pg_advisory_xact_lock(20773691, 2);

  select coalesce(
    jsonb_agg(
      jsonb_build_object(
        'assertionId', assertion.id,
        'assertionKind', assertion.assertion_kind,
        'payload', assertion.payload,
        'entityId', review.entity_id,
        'relatedEntityId', review.related_entity_id,
        'entityKind', entity.kind,
        'relatedEntityKind', related_entity.kind,
        'evidenceStatus', review.evidence_status,
        'sourceName', source.display_name,
        'sourceVersion', source_record.source_version,
        'retrievedAt', source_record.retrieved_at,
        'retrievalReference', source_record.retrieval_reference,
        'attribution', source_record.attribution_snapshot
      )
      order by assertion.id
    ),
    '[]'::jsonb
  )
  into accepted_assertions
  from catalog.normalized_assertions as assertion
  join catalog.assertion_reviews as review
    on review.assertion_id = assertion.id
   and review.decision = 'accepted'
   and review.evidence_status in (
     'confirmed',
     'single_source',
     'disputed',
     'historical',
     'unknown',
     'retracted'
   )
  join catalog.source_records as source_record
    on source_record.id = assertion.source_record_id
   and source_record.upstream_state = 'present'
   and source_record.license_status_snapshot = 'approved'
  join catalog.import_runs as import_run
    on import_run.id = source_record.import_run_id
   and import_run.source_id = source_record.source_id
   and import_run.contract_version = 2
  join catalog.sources as source
    on source.id = source_record.source_id
   and source.license_status = 'approved'
   and source.status <> 'blocked'
  join catalog.entities as entity
    on entity.id = review.entity_id
  left join catalog.entities as related_entity
    on related_entity.id = review.related_entity_id
  where private.source_assertion_trace_valid(assertion.payload -> 'trace')
    and exists (
      select 1
      from catalog.normalized_assertions as kind_assertion
      join catalog.assertion_reviews as kind_review
        on kind_review.assertion_id = kind_assertion.id
       and kind_review.decision = 'accepted'
       and kind_review.entity_id = review.entity_id
      join catalog.source_records as kind_source_record
        on kind_source_record.id = kind_assertion.source_record_id
       and kind_source_record.upstream_state = 'present'
       and kind_source_record.license_status_snapshot = 'approved'
      join catalog.import_runs as kind_import_run
        on kind_import_run.id = kind_source_record.import_run_id
       and kind_import_run.source_id = kind_source_record.source_id
       and kind_import_run.contract_version = 2
      join catalog.sources as kind_source
        on kind_source.id = kind_source_record.source_id
       and kind_source.license_status = 'approved'
       and kind_source.status <> 'blocked'
      where kind_assertion.assertion_kind = 'entity_kind'
        and kind_assertion.payload ->> 'entityKind' = entity.kind
        and private.source_assertion_trace_valid(
          kind_assertion.payload -> 'trace'
        )
        and (
          kind_source_record.valid_from is null
          or kind_source_record.valid_from <= publication_time
        )
        and (
          kind_source_record.valid_to is null
          or kind_source_record.valid_to > publication_time
        )
        and (
          kind_assertion.valid_from is null
          or kind_assertion.valid_from <= publication_time
        )
        and (
          kind_assertion.valid_to is null
          or kind_assertion.valid_to > publication_time
        )
    )
    and (
      review.related_entity_id is null
      or exists (
        select 1
        from catalog.normalized_assertions as related_kind_assertion
        join catalog.assertion_reviews as related_kind_review
          on related_kind_review.assertion_id = related_kind_assertion.id
         and related_kind_review.decision = 'accepted'
         and related_kind_review.entity_id = review.related_entity_id
        join catalog.source_records as related_kind_source_record
          on related_kind_source_record.id =
            related_kind_assertion.source_record_id
         and related_kind_source_record.upstream_state = 'present'
         and related_kind_source_record.license_status_snapshot = 'approved'
        join catalog.import_runs as related_kind_import_run
          on related_kind_import_run.id =
            related_kind_source_record.import_run_id
         and related_kind_import_run.source_id =
            related_kind_source_record.source_id
         and related_kind_import_run.contract_version = 2
        join catalog.sources as related_kind_source
          on related_kind_source.id = related_kind_source_record.source_id
         and related_kind_source.license_status = 'approved'
         and related_kind_source.status <> 'blocked'
        where related_kind_assertion.assertion_kind = 'entity_kind'
          and related_kind_assertion.payload ->> 'entityKind'
            = related_entity.kind
          and private.source_assertion_trace_valid(
            related_kind_assertion.payload -> 'trace'
          )
          and (
            related_kind_source_record.valid_from is null
            or related_kind_source_record.valid_from <= publication_time
          )
          and (
            related_kind_source_record.valid_to is null
            or related_kind_source_record.valid_to > publication_time
          )
          and (
            related_kind_assertion.valid_from is null
            or related_kind_assertion.valid_from <= publication_time
          )
          and (
            related_kind_assertion.valid_to is null
            or related_kind_assertion.valid_to > publication_time
          )
      )
    )
    and (
      source_record.valid_from is null
      or source_record.valid_from <= publication_time
    )
    and (
      source_record.valid_to is null
      or source_record.valid_to > publication_time
    )
    and (
      assertion.valid_from is null
      or assertion.valid_from <= publication_time
    )
    and (
      assertion.valid_to is null
      or assertion.valid_to > publication_time
    );

  if exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where accepted.value ->> 'assertionKind' = 'measurement'
      and accepted.value #>> '{payload,productForm}' = 'flower'
      and (accepted.value #>> '{payload,value}')::numeric > 70
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid knowledge graph snapshot';
  end if;

  if exists (
    with accepted as (
      select assertion.value
      from jsonb_array_elements(accepted_assertions) as assertion(value)
    ),
    endpoints as (
      select value ->> 'entityId' as entity_id
      from accepted
      union
      select value ->> 'relatedEntityId'
      from accepted
      where value -> 'relatedEntityId' <> 'null'::jsonb
    ),
    node_assertions as (
      select
        value ->> 'entityId' as entity_id,
        count(*) filter (
          where value ->> 'assertionKind' = 'entity_kind'
        ) as kind_count,
        count(*) filter (
          where value ->> 'assertionKind' = 'name'
        ) as name_count,
        count(distinct value #>> '{payload,entityKind}') filter (
          where value ->> 'assertionKind' = 'entity_kind'
        ) as distinct_kind_count,
        count(distinct value #>> '{payload,name}') filter (
          where value ->> 'assertionKind' = 'name'
        ) as distinct_name_count
      from accepted
      group by value ->> 'entityId'
    )
    select 1
    from endpoints
    left join node_assertions
      on node_assertions.entity_id = endpoints.entity_id
    where node_assertions.kind_count is distinct from 1
      or node_assertions.name_count is distinct from 1
      or node_assertions.distinct_kind_count is distinct from 1
      or node_assertions.distinct_name_count is distinct from 1
  )
  or exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where (
      accepted.value ->> 'assertionKind' = 'entity_kind'
      and (
        accepted.value #>> '{payload,entityKind}'
          <> accepted.value ->> 'entityKind'
        or accepted.value ->> 'entityKind' not in (
          'origin_population',
          'cultivar',
          'genetic_sample',
          'product'
        )
      )
    )
    or (
      accepted.value ->> 'assertionKind' = 'name'
      and char_length(accepted.value #>> '{payload,name}')
        not between 1 and 160
    )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid knowledge graph snapshot';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where accepted.value ->> 'assertionKind' not in (
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
    or (
      accepted.value ->> 'assertionKind' in (
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
      and accepted.value -> 'relatedEntityId' <> 'null'::jsonb
    )
    or (
      accepted.value ->> 'assertionKind' in (
        'measurement',
        'product_market'
      )
      and accepted.value ->> 'entityKind' <> 'product'
    )
    or (
      accepted.value ->> 'assertionKind' = 'sample_reference'
      and accepted.value ->> 'entityKind' <> 'genetic_sample'
    )
    or (
      accepted.value -> 'relatedEntityId' <> 'null'::jsonb
      and accepted.value ->> 'entityId'
        = accepted.value ->> 'relatedEntityId'
    )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid knowledge graph snapshot';
  end if;

  if exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where accepted.value ->> 'assertionKind' = 'lineage'
      and not coalesce((
        (
          accepted.value #>> '{payload,relationship}' in (
            'reported_parent',
            'cross',
            'backcross'
          )
          and accepted.value ->> 'entityKind' = 'cultivar'
          and accepted.value ->> 'relatedEntityKind' = 'cultivar'
        )
        or
        (
          accepted.value #>> '{payload,relationship}' = 'selection_from'
          and accepted.value ->> 'entityKind' = 'cultivar'
          and accepted.value ->> 'relatedEntityKind'
            in ('cultivar', 'origin_population')
        )
        or
        (
          accepted.value #>> '{payload,relationship}'
            = 'historical_origin'
          and accepted.value ->> 'entityKind'
            in ('cultivar', 'origin_population')
          and accepted.value ->> 'relatedEntityKind'
            = 'origin_population'
        )
        or
        (
          accepted.value #>> '{payload,relationship}'
            = 'population_membership'
          and accepted.value ->> 'entityKind'
            in ('cultivar', 'genetic_sample')
          and accepted.value ->> 'relatedEntityKind'
            = 'origin_population'
        )
        or
        (
          accepted.value #>> '{payload,relationship}' = 'unknown_parent'
          and accepted.value ->> 'entityKind' = 'cultivar'
          and accepted.value -> 'relatedEntityId' = 'null'::jsonb
        )
      ), false)
  )
  or exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where accepted.value ->> 'assertionKind' = 'genetic_relation'
      and (
        accepted.value ->> 'entityKind' <> 'genetic_sample'
        or accepted.value ->> 'relatedEntityKind' <> 'genetic_sample'
        or accepted.value -> 'relatedEntityId' = 'null'::jsonb
      )
  )
  or exists (
    select 1
    from jsonb_array_elements(accepted_assertions) as accepted(value)
    where accepted.value ->> 'assertionKind' = 'product_cultivar'
      and (
        accepted.value ->> 'entityKind' <> 'product'
        or accepted.value ->> 'relatedEntityKind' <> 'cultivar'
        or accepted.value -> 'relatedEntityId' = 'null'::jsonb
      )
  ) then
    raise exception using
      errcode = '22023',
      message = 'Invalid knowledge graph snapshot';
  end if;

  select current_snapshot.snapshot_id
  into previous_snapshot_identifier
  from catalog.knowledge_current_snapshot as current_snapshot
  where current_snapshot.singleton;

  insert into catalog.knowledge_publication_snapshots(
    id,
    previous_snapshot_id,
    published_by,
    published_at,
    assertion_count
  ) values (
    snapshot_identifier,
    previous_snapshot_identifier,
    session_user::text,
    publication_time,
    jsonb_array_length(accepted_assertions)
  );

  insert into catalog.knowledge_snapshot_nodes(
    snapshot_id,
    entity_id,
    kind,
    canonical_name
  )
  with accepted as (
    select assertion.value
    from jsonb_array_elements(accepted_assertions) as assertion(value)
  ),
  kinds as (
    select
      value ->> 'entityId' as entity_id,
      value #>> '{payload,entityKind}' as kind
    from accepted
    where value ->> 'assertionKind' = 'entity_kind'
  ),
  names as (
    select
      value ->> 'entityId' as entity_id,
      value #>> '{payload,name}' as canonical_name
    from accepted
    where value ->> 'assertionKind' = 'name'
  )
  select
    snapshot_identifier,
    kinds.entity_id::uuid,
    kinds.kind,
    names.canonical_name
  from kinds
  join names on names.entity_id = kinds.entity_id;

  insert into catalog.knowledge_snapshot_claims(
    snapshot_id,
    assertion_id,
    entity_id,
    claim_kind,
    value,
    evidence_status,
    evidence
  )
  select
    snapshot_identifier,
    (accepted.value ->> 'assertionId')::uuid,
    (accepted.value ->> 'entityId')::uuid,
    accepted.value ->> 'assertionKind',
    case accepted.value ->> 'assertionKind'
      when 'entity_kind' then jsonb_build_object(
        'entityKind',
        accepted.value #>> '{payload,entityKind}'
      )
      when 'name' then jsonb_build_object(
        'name',
        accepted.value #>> '{payload,name}',
        'language',
        accepted.value #> '{payload,language}'
      )
      when 'alias' then jsonb_build_object(
        'name',
        accepted.value #>> '{payload,name}',
        'language',
        accepted.value #> '{payload,language}',
        'aliasType',
        accepted.value #>> '{payload,aliasType}',
        'market',
        accepted.value #> '{payload,market}'
      )
      when 'traditional_classification' then jsonb_build_object(
        'classification',
        accepted.value #>> '{payload,classification}'
      )
      when 'origin_region' then jsonb_build_object(
        'regionName',
        accepted.value #>> '{payload,regionName}',
        'regionCode',
        accepted.value #> '{payload,regionCode}'
      )
      when 'era' then jsonb_build_object(
        'startYear',
        accepted.value #> '{payload,startYear}',
        'endYear',
        accepted.value #> '{payload,endYear}',
        'label',
        accepted.value #> '{payload,label}'
      )
      when 'sample_reference' then jsonb_build_object(
        'sampleIdentifier',
        accepted.value #>> '{payload,sampleIdentifier}',
        'datasetName',
        accepted.value #>> '{payload,datasetName}',
        'datasetVersion',
        accepted.value #> '{payload,datasetVersion}',
        'submitter',
        accepted.value #> '{payload,submitter}',
        'laboratory',
        accepted.value #> '{payload,laboratory}',
        'sampledAt',
        accepted.value #> '{payload,sampledAt}'
      )
      when 'product_market' then jsonb_build_object(
        'countryCode',
        accepted.value #>> '{payload,countryCode}',
        'medical',
        accepted.value #> '{payload,medical}'
      )
      when 'measurement' then jsonb_build_object(
        'analyte',
        accepted.value #>> '{payload,analyte}',
        'value',
        accepted.value #> '{payload,value}',
        'unit',
        accepted.value #>> '{payload,unit}',
        'productForm',
        accepted.value #>> '{payload,productForm}',
        'batchIdentifier',
        accepted.value #> '{payload,batchIdentifier}',
        'measuredAt',
        accepted.value #> '{payload,measuredAt}'
      )
    end,
    accepted.value ->> 'evidenceStatus',
    jsonb_build_object(
      'sourceName',
      accepted.value ->> 'sourceName',
      'sourceVersion',
      accepted.value -> 'sourceVersion',
      'retrievedAt',
      accepted.value -> 'retrievedAt',
      'citationUrl',
      case
        when accepted.value ->> 'retrievalReference' ~ '^https://'
          then accepted.value -> 'retrievalReference'
        else 'null'::jsonb
      end,
      'sourceLocator',
      accepted.value #>> '{payload,trace,sourceLocator}',
      'extractionMethod',
      accepted.value #>> '{payload,trace,extractionMethod}',
      'attribution',
      accepted.value ->> 'attribution'
    )
  from jsonb_array_elements(accepted_assertions) as accepted(value)
  where accepted.value ->> 'assertionKind' in (
    'entity_kind',
    'name',
    'alias',
    'traditional_classification',
    'origin_region',
    'era',
    'sample_reference',
    'product_market',
    'measurement'
  );

  insert into catalog.knowledge_snapshot_edges(
    snapshot_id,
    assertion_id,
    from_entity_id,
    to_entity_id,
    layer,
    relationship,
    position,
    evidence_status,
    details,
    evidence
  )
  select
    snapshot_identifier,
    (accepted.value ->> 'assertionId')::uuid,
    (accepted.value ->> 'entityId')::uuid,
    nullif(accepted.value ->> 'relatedEntityId', '')::uuid,
    case accepted.value ->> 'assertionKind'
      when 'lineage' then 'documented_lineage'
      when 'genetic_relation' then 'genetic_similarity'
      when 'product_cultivar' then 'product_mapping'
    end,
    case accepted.value ->> 'assertionKind'
      when 'product_cultivar' then 'product_cultivar'
      else accepted.value #>> '{payload,relationship}'
    end,
    case
      when accepted.value ->> 'assertionKind' = 'lineage'
        then (accepted.value #>> '{payload,position}')::smallint
      else null
    end,
    accepted.value ->> 'evidenceStatus',
    case accepted.value ->> 'assertionKind'
      when 'lineage' then '{}'::jsonb
      when 'genetic_relation' then jsonb_build_object(
        'method',
        accepted.value #>> '{payload,method}',
        'datasetName',
        accepted.value #>> '{payload,datasetName}',
        'datasetVersion',
        accepted.value #> '{payload,datasetVersion}',
        'metricName',
        accepted.value #>> '{payload,metricName}',
        'value',
        accepted.value #> '{payload,value}',
        'unit',
        accepted.value #> '{payload,unit}'
      )
      when 'product_cultivar' then jsonb_build_object(
        'productForm',
        accepted.value #>> '{payload,productForm}'
      )
    end,
    jsonb_build_object(
      'sourceName',
      accepted.value ->> 'sourceName',
      'sourceVersion',
      accepted.value -> 'sourceVersion',
      'retrievedAt',
      accepted.value -> 'retrievedAt',
      'citationUrl',
      case
        when accepted.value ->> 'retrievalReference' ~ '^https://'
          then accepted.value -> 'retrievalReference'
        else 'null'::jsonb
      end,
      'sourceLocator',
      accepted.value #>> '{payload,trace,sourceLocator}',
      'extractionMethod',
      accepted.value #>> '{payload,trace,extractionMethod}',
      'attribution',
      accepted.value ->> 'attribution'
    )
  from jsonb_array_elements(accepted_assertions) as accepted(value)
  where accepted.value ->> 'assertionKind' in (
    'lineage',
    'genetic_relation',
    'product_cultivar'
  );

  insert into catalog.knowledge_current_snapshot(singleton, snapshot_id)
  values (true, snapshot_identifier)
  on conflict (singleton) do update
  set snapshot_id = excluded.snapshot_id;

  delete from api.published_knowledge_edges;
  delete from api.published_knowledge_claims;
  delete from api.published_knowledge_nodes;
  delete from api.published_knowledge_snapshot;

  insert into api.published_knowledge_snapshot(
    singleton,
    snapshot_id,
    published_at
  ) values (
    true,
    snapshot_identifier,
    publication_time
  );

  insert into api.published_knowledge_nodes(
    snapshot_id,
    id,
    kind,
    canonical_name
  )
  select
    snapshot.snapshot_id,
    snapshot.entity_id,
    snapshot.kind,
    snapshot.canonical_name
  from catalog.knowledge_snapshot_nodes as snapshot
  where snapshot.snapshot_id = snapshot_identifier;

  insert into api.published_knowledge_claims(
    snapshot_id,
    assertion_id,
    node_id,
    claim_kind,
    value,
    evidence_status,
    evidence
  )
  select
    snapshot.snapshot_id,
    snapshot.assertion_id,
    snapshot.entity_id,
    snapshot.claim_kind,
    snapshot.value,
    snapshot.evidence_status,
    snapshot.evidence
  from catalog.knowledge_snapshot_claims as snapshot
  where snapshot.snapshot_id = snapshot_identifier;

  insert into api.published_knowledge_edges(
    snapshot_id,
    assertion_id,
    from_node_id,
    to_node_id,
    layer,
    relationship,
    position,
    evidence_status,
    details,
    evidence
  )
  select
    snapshot.snapshot_id,
    snapshot.assertion_id,
    snapshot.from_entity_id,
    snapshot.to_entity_id,
    snapshot.layer,
    snapshot.relationship,
    snapshot.position,
    snapshot.evidence_status,
    snapshot.details,
    snapshot.evidence
  from catalog.knowledge_snapshot_edges as snapshot
  where snapshot.snapshot_id = snapshot_identifier;

  return snapshot_identifier;
end;
$$;

revoke all on function private.publish_reviewed_knowledge_graph()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
grant execute on function private.publish_reviewed_knowledge_graph()
  to source_reviewer;

create function api.get_published_knowledge_graph()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select jsonb_build_object(
    'snapshotId',
    snapshot.snapshot_id,
    'publishedAt',
    snapshot.published_at,
    'nodes',
    (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'id',
            node.id,
            'kind',
            node.kind,
            'canonicalName',
            node.canonical_name
          )
          order by node.id
        ),
        '[]'::jsonb
      )
      from api.published_knowledge_nodes as node
      where node.snapshot_id = snapshot.snapshot_id
    ),
    'claims',
    (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'assertionId',
            claim.assertion_id,
            'nodeId',
            claim.node_id,
            'kind',
            claim.claim_kind,
            'value',
            claim.value,
            'evidenceStatus',
            claim.evidence_status,
            'evidence',
            claim.evidence
          )
          order by claim.assertion_id
        ),
        '[]'::jsonb
      )
      from api.published_knowledge_claims as claim
      where claim.snapshot_id = snapshot.snapshot_id
    ),
    'edges',
    (
      select coalesce(
        jsonb_agg(
          jsonb_build_object(
            'assertionId',
            edge.assertion_id,
            'fromNodeId',
            edge.from_node_id,
            'toNodeId',
            edge.to_node_id,
            'layer',
            edge.layer,
            'relationship',
            edge.relationship,
            'position',
            edge.position,
            'evidenceStatus',
            edge.evidence_status,
            'details',
            edge.details,
            'evidence',
            edge.evidence
          )
          order by edge.assertion_id
        ),
        '[]'::jsonb
      )
      from api.published_knowledge_edges as edge
      where edge.snapshot_id = snapshot.snapshot_id
    )
  )
  from api.published_knowledge_snapshot as snapshot
  where snapshot.singleton;
$$;

revoke all on function api.get_published_knowledge_graph()
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;
grant execute on function api.get_published_knowledge_graph()
  to authenticated;

alter table api.published_knowledge_snapshot enable row level security;
alter table api.published_knowledge_nodes enable row level security;
alter table api.published_knowledge_claims enable row level security;
alter table api.published_knowledge_edges enable row level security;

create policy published_knowledge_snapshot_select_authenticated
  on api.published_knowledge_snapshot
  for select
  to authenticated
  using (true);

create policy published_knowledge_nodes_select_authenticated
  on api.published_knowledge_nodes
  for select
  to authenticated
  using (true);

create policy published_knowledge_claims_select_authenticated
  on api.published_knowledge_claims
  for select
  to authenticated
  using (true);

create policy published_knowledge_edges_select_authenticated
  on api.published_knowledge_edges
  for select
  to authenticated
  using (true);

revoke all on
  api.published_knowledge_snapshot,
  api.published_knowledge_nodes,
  api.published_knowledge_claims,
  api.published_knowledge_edges
  from public, anon, authenticated, service_role, source_ingestor, source_reviewer;

grant select on
  api.published_knowledge_snapshot,
  api.published_knowledge_nodes,
  api.published_knowledge_claims,
  api.published_knowledge_edges
  to authenticated;


create or replace function private.publish_reviewed_catalog()
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
  where private.legacy_catalog_assertion_eligible(assertion.id)
    and (assertion.valid_from is null or assertion.valid_from <= now())
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
