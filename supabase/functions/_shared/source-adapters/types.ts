export type JsonValue =
  | null
  | boolean
  | number
  | string
  | JsonValue[]
  | { [key: string]: JsonValue }

export type SourceEvidence =
  | {
      kind: 'raw'
      mediaType: 'application/json' | 'application/xml' | 'text/csv'
      payload: JsonValue
    }
  | {
      kind: 'checksum'
      algorithm: 'sha256'
      digest: string
      retrievalReference: string
    }

export type NormalizedAssertion =
  | {
      kind: 'name' | 'alias'
      subjectExternalKey: string
      name: string
      language: string | null
    }
  | {
      kind: 'lineage'
      subjectExternalKey: string
      parentExternalKey: string
      relationship: 'reported_parent' | 'historical_origin'
      position: 1 | 2 | null
    }
  | {
      kind: 'product_cultivar'
      subjectExternalKey: string
      cultivarExternalKey: string
      productForm: 'flower' | 'extract' | 'oil' | 'other'
    }
  | {
      kind: 'measurement'
      subjectExternalKey: string
      analyte: 'thc' | 'cbd'
      value: number
      unit: 'percent'
      productForm: 'flower' | 'extract' | 'oil' | 'other'
      measuredAt: string | null
    }

export type AdapterRecord = {
  externalRecordKey: string
  upstreamState: 'present' | 'deleted'
  retrievedAt: string
  sourceVersion: string | null
  evidence: SourceEvidence
  validFrom: string | null
  validTo: string | null
  assertions: NormalizedAssertion[]
}

export type AdapterError = {
  externalRecordKey: string | null
  code: 'timeout' | 'schema_changed' | 'rate_limited' | 'invalid_record'
  message: string
}

export type AdapterBatch = {
  sourceId: string
  startedAt: string
  completedAt: string
  cursor: string | null
  records: AdapterRecord[]
  errors: AdapterError[]
}

export type ValidatedAdapterBatch = {
  batch: AdapterBatch
  reviewReasonsByRecord: Record<string, string[]>
}
