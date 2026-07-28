import type {
  AdapterBatch,
  AdapterRecord,
  JsonValue,
  NormalizedAssertion,
  SourceEvidence,
  ValidatedAdapterBatch,
} from './types.ts'

type UnknownRecord = Record<string, unknown>

const timestampPattern =
  /^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$/
const sha256Pattern = /^[0-9a-f]{64}$/
const sourceIdPattern = /^[a-z0-9][a-z0-9._-]{2,79}$/
const productForms = ['flower', 'extract', 'oil', 'other'] as const

function invalid(path: string, reason: string): never {
  throw new Error(`Invalid adapter batch at ${path}: ${reason}`)
}

function recordAt(value: unknown, path: string): UnknownRecord {
  if (
    typeof value !== 'object'
    || value === null
    || Array.isArray(value)
    || (
      Object.getPrototypeOf(value) !== Object.prototype
      && Object.getPrototypeOf(value) !== null
    )
  ) {
    invalid(path, 'expected an object')
  }
  return value as UnknownRecord
}

function exactKeys(
  record: UnknownRecord,
  allowed: readonly string[],
  path: string,
): void {
  const allowedKeys = new Set(allowed)
  const unknownKey = Object.keys(record).find((key) => !allowedKeys.has(key))
  if (unknownKey) invalid(path, `unknown field ${unknownKey}`)

  const missingKey = allowed.find((key) => !(key in record))
  if (missingKey) invalid(path, `missing field ${missingKey}`)
}

function text(
  value: unknown,
  path: string,
  maximumLength: number,
): string {
  if (
    typeof value !== 'string'
    || value.length === 0
    || value.length > maximumLength
    || value.trim() !== value
  ) {
    invalid(path, `expected 1-${maximumLength} trimmed characters`)
  }
  return value
}

function nullableText(
  value: unknown,
  path: string,
  maximumLength: number,
): string | null {
  return value === null ? null : text(value, path, maximumLength)
}

function timestamp(value: unknown, path: string): string {
  if (
    typeof value !== 'string'
    || !timestampPattern.test(value)
    || !Number.isFinite(Date.parse(value))
  ) {
    invalid(path, 'expected an ISO timestamp')
  }
  return value
}

function nullableTimestamp(value: unknown, path: string): string | null {
  return value === null ? null : timestamp(value, path)
}

function oneOf<const Values extends readonly string[]>(
  value: unknown,
  values: Values,
  path: string,
): Values[number] {
  if (typeof value !== 'string' || !values.includes(value)) {
    invalid(path, `expected one of ${values.join(', ')}`)
  }
  return value as Values[number]
}

function isJsonValue(value: unknown): value is JsonValue {
  if (
    value === null
    || typeof value === 'string'
    || typeof value === 'boolean'
  ) {
    return true
  }
  if (typeof value === 'number') return Number.isFinite(value)
  if (Array.isArray(value)) return value.every(isJsonValue)
  if (typeof value !== 'object') return false
  if (
    Object.getPrototypeOf(value) !== Object.prototype
    && Object.getPrototypeOf(value) !== null
  ) {
    return false
  }
  return Object.values(value).every(isJsonValue)
}

function safeRetrievalReference(value: unknown, path: string): string {
  const reference = text(value, path, 2048)
  let url: URL
  try {
    url = new URL(reference)
  } catch {
    invalid(path, 'expected an absolute HTTP(S) URL')
  }
  if (url.protocol !== 'https:' && url.protocol !== 'http:') {
    invalid(path, 'expected an absolute HTTP(S) URL')
  }
  return reference
}

function evidence(value: unknown, path: string): SourceEvidence {
  const input = recordAt(value, path)
  const kind = input.kind

  if (kind === 'raw') {
    exactKeys(input, ['kind', 'mediaType', 'payload'], path)
    const mediaType = oneOf(
      input.mediaType,
      ['application/json', 'application/xml', 'text/csv'] as const,
      `${path}.mediaType`,
    )
    if (!isJsonValue(input.payload)) {
      invalid(`${path}.payload`, 'expected a finite JSON value')
    }
    return { kind, mediaType, payload: input.payload }
  }

  if (kind === 'checksum') {
    exactKeys(
      input,
      ['kind', 'algorithm', 'digest', 'retrievalReference'],
      path,
    )
    if (input.algorithm !== 'sha256') {
      invalid(`${path}.algorithm`, 'expected sha256')
    }
    if (typeof input.digest !== 'string' || !sha256Pattern.test(input.digest)) {
      invalid(`${path}.digest`, 'expected a lowercase SHA-256 digest')
    }
    return {
      kind,
      algorithm: input.algorithm,
      digest: input.digest,
      retrievalReference: safeRetrievalReference(
        input.retrievalReference,
        `${path}.retrievalReference`,
      ),
    }
  }

  invalid(`${path}.kind`, 'expected raw or checksum')
}

function externalKey(value: unknown, path: string): string {
  return text(value, path, 240)
}

function language(value: unknown, path: string): string | null {
  const result = nullableText(value, path, 35)
  if (
    result !== null
    && !/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(result)
  ) {
    invalid(path, 'expected a BCP 47-style language tag')
  }
  return result
}

function assertion(
  value: unknown,
  path: string,
): NormalizedAssertion {
  const input = recordAt(value, path)
  const kind = input.kind

  if (kind === 'name' || kind === 'alias') {
    exactKeys(input, ['kind', 'subjectExternalKey', 'name', 'language'], path)
    return {
      kind,
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      name: text(input.name, `${path}.name`, 240),
      language: language(input.language, `${path}.language`),
    }
  }

  if (kind === 'lineage') {
    exactKeys(
      input,
      [
        'kind',
        'subjectExternalKey',
        'parentExternalKey',
        'relationship',
        'position',
      ],
      path,
    )
    if (input.position !== null && input.position !== 1 && input.position !== 2) {
      invalid(`${path}.position`, 'expected 1, 2, or null')
    }
    return {
      kind,
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      parentExternalKey: externalKey(
        input.parentExternalKey,
        `${path}.parentExternalKey`,
      ),
      relationship: oneOf(
        input.relationship,
        ['reported_parent', 'historical_origin'] as const,
        `${path}.relationship`,
      ),
      position: input.position,
    }
  }

  if (kind === 'product_cultivar') {
    exactKeys(
      input,
      [
        'kind',
        'subjectExternalKey',
        'cultivarExternalKey',
        'productForm',
      ],
      path,
    )
    return {
      kind,
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      cultivarExternalKey: externalKey(
        input.cultivarExternalKey,
        `${path}.cultivarExternalKey`,
      ),
      productForm: oneOf(
        input.productForm,
        productForms,
        `${path}.productForm`,
      ),
    }
  }

  if (kind === 'measurement') {
    exactKeys(
      input,
      [
        'kind',
        'subjectExternalKey',
        'analyte',
        'value',
        'unit',
        'productForm',
        'measuredAt',
      ],
      path,
    )
    if (typeof input.value !== 'number' || !Number.isFinite(input.value)) {
      invalid(`${path}.value`, 'expected a finite number')
    }
    if (input.unit !== 'percent') {
      invalid(`${path}.unit`, 'expected percent')
    }
    return {
      kind,
      subjectExternalKey: externalKey(
        input.subjectExternalKey,
        `${path}.subjectExternalKey`,
      ),
      analyte: oneOf(
        input.analyte,
        ['thc', 'cbd'] as const,
        `${path}.analyte`,
      ),
      value: input.value,
      unit: input.unit,
      productForm: oneOf(
        input.productForm,
        productForms,
        `${path}.productForm`,
      ),
      measuredAt: nullableTimestamp(
        input.measuredAt,
        `${path}.measuredAt`,
      ),
    }
  }

  invalid(`${path}.kind`, 'unknown assertion kind')
}

function adapterRecord(value: unknown, path: string): AdapterRecord {
  const input = recordAt(value, path)
  exactKeys(
    input,
    [
      'externalRecordKey',
      'retrievedAt',
      'sourceVersion',
      'evidence',
      'validFrom',
      'validTo',
      'assertions',
    ],
    path,
  )
  if (!Array.isArray(input.assertions) || input.assertions.length === 0) {
    invalid(`${path}.assertions`, 'expected at least one assertion')
  }

  const validFrom = nullableTimestamp(input.validFrom, `${path}.validFrom`)
  const validTo = nullableTimestamp(input.validTo, `${path}.validTo`)
  if (
    validFrom !== null
    && validTo !== null
    && Date.parse(validTo) < Date.parse(validFrom)
  ) {
    invalid(`${path}.validTo`, 'must not be before validFrom')
  }

  return {
    externalRecordKey: externalKey(
      input.externalRecordKey,
      `${path}.externalRecordKey`,
    ),
    retrievedAt: timestamp(input.retrievedAt, `${path}.retrievedAt`),
    sourceVersion: nullableText(
      input.sourceVersion,
      `${path}.sourceVersion`,
      160,
    ),
    evidence: evidence(input.evidence, `${path}.evidence`),
    validFrom,
    validTo,
    assertions: input.assertions.map((item, index) =>
      assertion(item, `${path}.assertions[${index}]`)
    ),
  }
}

function adapterError(value: unknown, path: string) {
  const input = recordAt(value, path)
  exactKeys(input, ['externalRecordKey', 'code', 'message'], path)
  return {
    externalRecordKey: nullableText(
      input.externalRecordKey,
      `${path}.externalRecordKey`,
      240,
    ),
    code: oneOf(
      input.code,
      ['timeout', 'schema_changed', 'rate_limited', 'invalid_record'] as const,
      `${path}.code`,
    ),
    message: text(input.message, `${path}.message`, 1000),
  }
}

export function validateAdapterBatch(input: unknown): ValidatedAdapterBatch {
  const value = recordAt(input, 'batch')
  exactKeys(
    value,
    [
      'sourceId',
      'startedAt',
      'completedAt',
      'cursor',
      'records',
      'errors',
    ],
    'batch',
  )
  if (
    typeof value.sourceId !== 'string'
    || !sourceIdPattern.test(value.sourceId)
  ) {
    invalid('batch.sourceId', 'expected a stable lowercase source ID')
  }
  if (!Array.isArray(value.records)) {
    invalid('batch.records', 'expected an array')
  }
  if (!Array.isArray(value.errors)) {
    invalid('batch.errors', 'expected an array')
  }

  const startedAt = timestamp(value.startedAt, 'batch.startedAt')
  const completedAt = timestamp(value.completedAt, 'batch.completedAt')
  if (Date.parse(completedAt) < Date.parse(startedAt)) {
    invalid('batch.completedAt', 'must not be before startedAt')
  }

  const records = value.records.map((item, index) =>
    adapterRecord(item, `records[${index}]`)
  )
  const seenKeys = new Set<string>()
  for (const record of records) {
    if (seenKeys.has(record.externalRecordKey)) {
      invalid(
        'batch.records.externalRecordKey',
        `duplicate ${record.externalRecordKey}`,
      )
    }
    seenKeys.add(record.externalRecordKey)
  }

  const reviewReasonsByRecord: Record<string, string[]> = {}
  for (const record of records) {
    const hasUnrealisticFlowerValue = record.assertions.some((item) =>
      item.kind === 'measurement'
      && item.productForm === 'flower'
      && item.value > 70
    )
    if (hasUnrealisticFlowerValue) {
      reviewReasonsByRecord[record.externalRecordKey] = [
        'flower_value_above_70',
      ]
    }
  }

  const batch: AdapterBatch = {
    sourceId: value.sourceId,
    startedAt,
    completedAt,
    cursor: nullableText(value.cursor, 'batch.cursor', 2000),
    records,
    errors: value.errors.map((item, index) =>
      adapterError(item, `errors[${index}]`)
    ),
  }

  return { batch, reviewReasonsByRecord }
}
