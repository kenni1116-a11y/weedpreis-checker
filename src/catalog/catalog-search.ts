export type CatalogSearchMatch = {
  id: string
  kind: 'cultivar' | 'product'
  canonicalName: string
  matchedName: string
  matchReason: 'canonical' | 'alias' | 'product'
  canonicalCultivarId: string | null
  isFlower: boolean
  preferredParents: readonly [string | null, string | null]
  hasAdditionalLineage: boolean
  sourcedThcLabel: string | null
  sourcedCbdLabel: string | null
  sourcedValueEvidence: ReadonlyArray<{
    sourceName: string
    sourceVersion: string | null
    retrievedAt: string
    citationUrl: string | null
    attribution: string
  }>
}

type UnknownRecord = Record<string, unknown>

const uuidPattern =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i

function record(value: unknown, description: string): UnknownRecord {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) {
    throw new Error(`Invalid catalog search ${description}`)
  }
  return value as UnknownRecord
}

function text(
  value: unknown,
  description: string,
  maximumLength: number,
): string {
  if (
    typeof value !== 'string'
    || value.trim() !== value
    || value.length < 1
    || value.length > maximumLength
  ) {
    throw new Error(`Invalid catalog search ${description}`)
  }
  return value
}

function nullableText(
  value: unknown,
  description: string,
  maximumLength: number,
): string | null {
  return value === null ? null : text(value, description, maximumLength)
}

function uuid(value: unknown, description: string): string {
  const result = text(value, description, 36)
  if (!uuidPattern.test(result)) {
    throw new Error(`Invalid catalog search ${description}`)
  }
  return result
}

function nullableUuid(value: unknown, description: string): string | null {
  return value === null ? null : uuid(value, description)
}

function boolean(value: unknown, description: string): boolean {
  if (typeof value !== 'boolean') {
    throw new Error(`Invalid catalog search ${description}`)
  }
  return value
}

function sourceEvidence(value: unknown): CatalogSearchMatch[
  'sourcedValueEvidence'
] {
  if (!Array.isArray(value)) {
    throw new Error('Invalid catalog search source evidence')
  }
  return value.map((item) => {
    const input = record(item, 'source evidence')
    const retrievedAt = text(input.retrievedAt, 'source evidence', 80)
    if (!Number.isFinite(Date.parse(retrievedAt))) {
      throw new Error('Invalid catalog search source evidence')
    }

    const citationUrl = nullableText(
      input.citationUrl,
      'source evidence',
      2048,
    )
    if (citationUrl !== null) {
      let url: URL
      try {
        url = new URL(citationUrl)
      } catch {
        throw new Error('Invalid catalog search source evidence')
      }
      if (url.protocol !== 'https:') {
        throw new Error('Invalid catalog search source evidence')
      }
    }

    return {
      sourceName: text(input.sourceName, 'source evidence', 160),
      sourceVersion: nullableText(
        input.sourceVersion,
        'source evidence',
        160,
      ),
      retrievedAt,
      citationUrl,
      attribution: text(input.attribution, 'source evidence', 2000),
    }
  })
}

function parents(value: unknown): readonly [string | null, string | null] {
  if (!Array.isArray(value) || value.length > 2) {
    throw new Error('Invalid catalog search parents')
  }
  const first = nullableText(value[0] ?? null, 'parents', 160)
  const second = nullableText(value[1] ?? null, 'parents', 160)
  return [first, second]
}

export function mapCatalogSearchRow(row: unknown): CatalogSearchMatch {
  const input = record(row, 'row')
  if (input.kind !== 'cultivar' && input.kind !== 'product') {
    throw new Error('Invalid catalog search kind')
  }
  if (
    input.match_reason !== 'canonical'
    && input.match_reason !== 'alias'
    && input.match_reason !== 'product'
  ) {
    throw new Error('Invalid catalog search match reason')
  }

  const isFlower = boolean(input.is_flower, 'flower flag')
  const canonicalCultivarId = nullableUuid(
    input.canonical_cultivar_id,
    'cultivar ID',
  )
  if (input.kind === 'product' && isFlower && canonicalCultivarId === null) {
    throw new Error('Invalid catalog search cultivar mapping')
  }

  return {
    id: uuid(input.id, 'ID'),
    kind: input.kind,
    canonicalName: text(input.canonical_name, 'canonical name', 160),
    matchedName: text(input.matched_name, 'matched name', 240),
    matchReason: input.match_reason,
    canonicalCultivarId,
    isFlower,
    preferredParents: parents(input.preferred_parents),
    hasAdditionalLineage: boolean(
      input.has_additional_lineage,
      'additional lineage flag',
    ),
    sourcedThcLabel: nullableText(
      input.sourced_thc_label,
      'THC label',
      80,
    ),
    sourcedCbdLabel: nullableText(
      input.sourced_cbd_label,
      'CBD label',
      80,
    ),
    sourcedValueEvidence: sourceEvidence(input.sourced_value_evidence),
  }
}
