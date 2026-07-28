import {
  assertEquals,
  assertThrows,
} from '@std/assert'
import invalidFlowerValue from '../../tests/fixtures/source-adapter-invalid-flower-value.json' with {
  type: 'json',
}
import validFixture from '../../tests/fixtures/source-adapter-valid.json' with {
  type: 'json',
}
import { validateAdapterBatch } from './validate.ts'

function cloned<T>(value: T): T {
  return structuredClone(value)
}

Deno.test('source adapter accepts raw and checksum evidence without changing source precision', () => {
  const result = validateAdapterBatch(cloned(validFixture))

  assertEquals(result.batch as unknown, validFixture)
  assertEquals(
    result.batch.records[0].assertions[2],
    {
      kind: 'measurement',
      subjectExternalKey: 'synthetic-cultivar-001',
      analyte: 'thc',
      value: 21.375,
      unit: 'percent',
      productForm: 'flower',
      measuredAt: '2026-07-01T00:00:00.000Z',
    },
  )
  assertEquals(result.reviewReasonsByRecord, {})
})

Deno.test('source adapter retains an unrealistic flower value only for review', () => {
  const result = validateAdapterBatch(cloned(invalidFlowerValue))

  assertEquals(
    result.batch.records[0].assertions[0] as unknown,
    invalidFlowerValue.records[0].assertions[0],
  )
  assertEquals(result.reviewReasonsByRecord, {
    'synthetic-flower-above-limit': ['flower_value_above_70'],
  })
})

Deno.test('source adapter represents upstream deletion as review-only evidence', () => {
  const input = cloned(validFixture) as Record<string, unknown>
  const records = input.records as Array<Record<string, unknown>>
  records[0].upstreamState = 'deleted'
  records[0].assertions = []

  const result = validateAdapterBatch(input)

  assertEquals(result.batch.records[0].upstreamState, 'deleted')
  assertEquals(result.batch.records[0].assertions, [])
  assertEquals(result.reviewReasonsByRecord, {
    'synthetic-cultivar-001': ['upstream_record_deleted'],
  })
})

Deno.test('source adapter accepts only the closed normalized assertion contract', () => {
  const input = cloned(validFixture) as Record<string, unknown>
  const records = input.records as Array<Record<string, unknown>>
  const assertions = records[0].assertions as Array<Record<string, unknown>>
  assertions[0].sourceSpecificTitle = 'must not cross the adapter boundary'

  assertThrows(
    () => validateAdapterBatch(input),
    Error,
    'records[0].assertions[0]',
  )
})

Deno.test('source adapter rejects malformed checksums, timestamps, positions, and measurements', () => {
  const mutations: Array<[string, (input: Record<string, unknown>) => void]> = [
    ['checksum', (input) => {
      const records = input.records as Array<Record<string, unknown>>
      const evidence = records[1].evidence as Record<string, unknown>
      evidence.digest = 'ABC123'
    }],
    ['timestamp', (input) => {
      input.completedAt = 'not-a-timestamp'
    }],
    ['position', (input) => {
      const records = input.records as Array<Record<string, unknown>>
      records[0].assertions = [{
        kind: 'lineage',
        subjectExternalKey: 'synthetic-cultivar-001',
        parentExternalKey: 'synthetic-parent-001',
        relationship: 'reported_parent',
        position: 3,
      }]
    }],
    ['measurement', (input) => {
      const records = input.records as Array<Record<string, unknown>>
      const assertions = records[0].assertions as Array<Record<string, unknown>>
      assertions[2].value = Number.POSITIVE_INFINITY
    }],
  ]

  for (const [name, mutate] of mutations) {
    const input = cloned(validFixture) as Record<string, unknown>
    mutate(input)
    assertThrows(
      () => validateAdapterBatch(input),
      Error,
      undefined,
      `expected ${name} mutation to be rejected`,
    )
  }
})

Deno.test('source adapter rejects unknown batch and record fields', () => {
  const batch = cloned(validFixture) as Record<string, unknown>
  batch.providerCursor = 'source-specific'
  assertThrows(() => validateAdapterBatch(batch), Error, 'batch')

  const record = cloned(validFixture) as Record<string, unknown>
  const records = record.records as Array<Record<string, unknown>>
  records[0].providerUpdatedAt = '2026-07-28'
  assertThrows(
    () => validateAdapterBatch(record),
    Error,
    'records[0]',
  )
})

Deno.test('source adapter rejects non-JSON raw payload objects', () => {
  const input = cloned(validFixture) as Record<string, unknown>
  const records = input.records as Array<Record<string, unknown>>
  const evidence = records[0].evidence as Record<string, unknown>
  evidence.payload = new Date('2026-07-28T18:00:00.000Z')

  assertThrows(
    () => validateAdapterBatch(input),
    Error,
    'payload',
  )
})

Deno.test('source adapter rejects duplicate record keys and invalid validity windows', () => {
  const duplicate = cloned(validFixture) as Record<string, unknown>
  const duplicateRecords = duplicate.records as Array<Record<string, unknown>>
  duplicateRecords[1].externalRecordKey =
    duplicateRecords[0].externalRecordKey
  assertThrows(
    () => validateAdapterBatch(duplicate),
    Error,
    'externalRecordKey',
  )

  const invalidWindow = cloned(validFixture) as Record<string, unknown>
  const windowRecords =
    invalidWindow.records as Array<Record<string, unknown>>
  windowRecords[0].validFrom = '2026-07-02T00:00:00.000Z'
  windowRecords[0].validTo = '2026-07-01T00:00:00.000Z'
  assertThrows(
    () => validateAdapterBatch(invalidWindow),
    Error,
    'validTo',
  )
})
