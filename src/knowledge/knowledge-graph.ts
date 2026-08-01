export type KnowledgeEvidence = {
  sourceName: string
  sourceVersion: string | null
  retrievedAt: string
  citationUrl: string | null
  sourceLocator: string
  extractionMethod: 'structured' | 'manual' | 'ai_assisted'
  attribution: string
}

export type EvidenceStatus =
  | 'confirmed'
  | 'single_source'
  | 'disputed'
  | 'historical'
  | 'unknown'
  | 'retracted'

export type KnowledgeNode = {
  id: string
  kind: 'origin_population' | 'cultivar' | 'genetic_sample' | 'product'
  canonicalName: string
}

type ClaimBase = {
  assertionId: string
  nodeId: string
  evidenceStatus: EvidenceStatus
  evidence: KnowledgeEvidence
}

export type KnowledgeClaim =
  | (ClaimBase & { kind: 'entity_kind'; value: { entityKind: KnowledgeNode['kind'] } })
  | (ClaimBase & { kind: 'name'; value: { name: string; language: string | null } })
  | (ClaimBase & { kind: 'alias'; value: { name: string; language: string | null; aliasType: 'spelling' | 'breeder' | 'market' | 'historical' | 'other'; market: string | null } })
  | (ClaimBase & { kind: 'traditional_classification'; value: { classification: 'sativa' | 'indica' | 'hybrid' } })
  | (ClaimBase & { kind: 'origin_region'; value: { regionName: string; regionCode: string | null } })
  | (ClaimBase & { kind: 'era'; value: { startYear: number | null; endYear: number | null; label: string | null } })
  | (ClaimBase & { kind: 'sample_reference'; value: { sampleIdentifier: string; datasetName: string; datasetVersion: string | null; submitter: string | null; laboratory: string | null; sampledAt: string | null } })
  | (ClaimBase & { kind: 'product_market'; value: { countryCode: string; medical: true } })
  | (ClaimBase & { kind: 'measurement'; value: { analyte: 'thc' | 'cbd'; value: number; unit: 'percent'; productForm: 'flower' | 'extract' | 'oil' | 'other'; batchIdentifier: string | null; measuredAt: string | null } })

type EdgeBase = {
  assertionId: string
  fromNodeId: string
  evidenceStatus: EvidenceStatus
  evidence: KnowledgeEvidence
}

export type KnowledgeEdge =
  | (EdgeBase & { toNodeId: string | null; layer: 'documented_lineage'; relationship: 'reported_parent' | 'cross' | 'backcross' | 'selection_from' | 'historical_origin' | 'population_membership' | 'unknown_parent'; position: 1 | 2 | null; details: Record<string, never> })
  | (EdgeBase & { toNodeId: string; layer: 'genetic_similarity'; relationship: 'genetic_similarity' | 'sample_match'; position: null; details: { method: string; datasetName: string; datasetVersion: string | null; metricName: string; value: number | null; unit: string | null } })
  | (EdgeBase & { toNodeId: string; layer: 'product_mapping'; relationship: 'product_cultivar'; position: null; details: { productForm: 'flower' | 'extract' | 'oil' | 'other' } })

export type KnowledgeGraph = {
  snapshotId: string
  publishedAt: string
  nodes: readonly KnowledgeNode[]
  claims: readonly KnowledgeClaim[]
  edges: readonly KnowledgeEdge[]
}

type UnknownRecord = Record<string, unknown>

const uuidPattern = /^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
const timestampPattern = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2}):(\d{2})(?:\.\d{1,9})?(?:Z|[+-]\d{2}:\d{2})$/
const nodeKinds = ['origin_population', 'cultivar', 'genetic_sample', 'product'] as const
const evidenceStatuses = ['confirmed', 'single_source', 'disputed', 'historical', 'unknown', 'retracted'] as const
const productForms = ['flower', 'extract', 'oil', 'other'] as const
const extractionMethods = ['structured', 'manual', 'ai_assisted'] as const
const aliasTypes = ['spelling', 'breeder', 'market', 'historical', 'other'] as const
const classifications = ['sativa', 'indica', 'hybrid'] as const
const analytes = ['thc', 'cbd'] as const
const units = ['percent'] as const
const lineageRelationships = ['reported_parent', 'cross', 'backcross', 'selection_from', 'historical_origin', 'population_membership', 'unknown_parent'] as const
const geneticRelationships = ['genetic_similarity', 'sample_match'] as const

function invalid(description: string): never {
  throw new Error(`Invalid knowledge graph ${description}`)
}

function record(value: unknown, description: string, keys: readonly string[]): UnknownRecord {
  if (typeof value !== 'object' || value === null || Array.isArray(value)) invalid(description)
  const result = value as UnknownRecord
  const actualKeys = Object.keys(result)
  if (actualKeys.length !== keys.length || actualKeys.some((key) => !keys.includes(key))) invalid(description)
  return result
}

function text(value: unknown, description: string, maximumLength: number): string {
  if (typeof value !== 'string' || value.trim() !== value) invalid(description)
  const length = [...value].length
  if (length < 1 || length > maximumLength) invalid(description)
  return value
}

function nullableText(value: unknown, description: string, maximumLength: number): string | null {
  return value === null ? null : text(value, description, maximumLength)
}

function nullableLanguage(value: unknown, description: string): string | null {
  const result = nullableText(value, description, 35)
  if (result !== null && !/^[A-Za-z]{2,8}(?:-[A-Za-z0-9]{1,8})*$/.test(result)) invalid(description)
  return result
}

function choice<T extends readonly string[]>(value: unknown, description: string, choices: T): T[number] {
  if (typeof value !== 'string' || !choices.includes(value)) invalid(description)
  return value as T[number]
}

function uuid(value: unknown, description: string): string {
  const result = text(value, description, 36)
  if (!uuidPattern.test(result)) invalid(description)
  return result.toLowerCase()
}

function timestamp(value: unknown, description: string): string {
  const result = text(value, description, 80)
  const match = timestampPattern.exec(result)
  if (!match || !Number.isFinite(Date.parse(result))) invalid(description)
  const [year, month, day, hour, minute, second] = match.slice(1, 7).map(Number)
  const calendar = new Date(Date.UTC(year, month - 1, day, hour, minute, second))
  if (
    month < 1 || month > 12 || hour > 23 || minute > 59 || second > 59
    || calendar.getUTCFullYear() !== year || calendar.getUTCMonth() !== month - 1
    || calendar.getUTCDate() !== day || calendar.getUTCHours() !== hour
    || calendar.getUTCMinutes() !== minute || calendar.getUTCSeconds() !== second
  ) invalid(description)
  return result
}

function nullableTimestamp(value: unknown, description: string): string | null {
  return value === null ? null : timestamp(value, description)
}

function finiteNumber(value: unknown, description: string): number {
  if (typeof value !== 'number' || !Number.isFinite(value)) invalid(description)
  return value
}

function nullableFiniteNumber(value: unknown, description: string): number | null {
  return value === null ? null : finiteNumber(value, description)
}

function nullableIntegerYear(value: unknown, description: string): number | null {
  if (value === null) return null
  const result = finiteNumber(value, description)
  if (!Number.isInteger(result) || result < -10_000 || result > 2100) invalid(description)
  return result
}

function evidence(value: unknown): KnowledgeEvidence {
  const input = record(value, 'evidence', [
    'sourceName', 'sourceVersion', 'retrievedAt', 'citationUrl', 'sourceLocator', 'extractionMethod', 'attribution',
  ])
  const citationUrl = nullableText(input.citationUrl, 'evidence', 2048)
  if (citationUrl !== null) {
    let parsed: URL
    try {
      parsed = new URL(citationUrl)
    } catch {
      invalid('evidence')
    }
    if (parsed.protocol !== 'https:' || parsed.hostname.length === 0) invalid('evidence')
  }
  return {
    sourceName: text(input.sourceName, 'evidence', 240),
    sourceVersion: nullableText(input.sourceVersion, 'evidence', 160),
    retrievedAt: timestamp(input.retrievedAt, 'evidence'),
    citationUrl,
    sourceLocator: text(input.sourceLocator, 'evidence', 1000),
    extractionMethod: choice(input.extractionMethod, 'evidence', extractionMethods),
    attribution: text(input.attribution, 'evidence', 2000),
  }
}

function claimBase(input: UnknownRecord): ClaimBase {
  return {
    assertionId: uuid(input.assertionId, 'claim'),
    nodeId: uuid(input.nodeId, 'claim'),
    evidenceStatus: choice(input.evidenceStatus, 'claim', evidenceStatuses),
    evidence: evidence(input.evidence),
  }
}

function mapClaim(value: unknown): KnowledgeClaim {
  const input = record(value, 'claim', ['assertionId', 'nodeId', 'kind', 'value', 'evidenceStatus', 'evidence'])
  const base = claimBase(input)
  switch (input.kind) {
    case 'entity_kind': {
      const parsed = record(input.value, 'claim value', ['entityKind'])
      return { ...base, kind: 'entity_kind', value: { entityKind: choice(parsed.entityKind, 'claim value', nodeKinds) } }
    }
    case 'name': {
      const parsed = record(input.value, 'claim value', ['name', 'language'])
      return { ...base, kind: 'name', value: { name: text(parsed.name, 'claim value', 240), language: nullableLanguage(parsed.language, 'claim value') } }
    }
    case 'alias': {
      const parsed = record(input.value, 'claim value', ['name', 'language', 'aliasType', 'market'])
      return { ...base, kind: 'alias', value: { name: text(parsed.name, 'claim value', 240), language: nullableLanguage(parsed.language, 'claim value'), aliasType: choice(parsed.aliasType, 'claim value', aliasTypes), market: nullableText(parsed.market, 'claim value', 240) } }
    }
    case 'traditional_classification': {
      const parsed = record(input.value, 'claim value', ['classification'])
      return { ...base, kind: 'traditional_classification', value: { classification: choice(parsed.classification, 'claim value', classifications) } }
    }
    case 'origin_region': {
      const parsed = record(input.value, 'claim value', ['regionName', 'regionCode'])
      return { ...base, kind: 'origin_region', value: { regionName: text(parsed.regionName, 'claim value', 240), regionCode: nullableText(parsed.regionCode, 'claim value', 35) } }
    }
    case 'era': {
      const parsed = record(input.value, 'claim value', ['startYear', 'endYear', 'label'])
      const startYear = nullableIntegerYear(parsed.startYear, 'claim value')
      const endYear = nullableIntegerYear(parsed.endYear, 'claim value')
      if (startYear !== null && endYear !== null && endYear < startYear) invalid('claim value')
      return { ...base, kind: 'era', value: { startYear, endYear, label: nullableText(parsed.label, 'claim value', 240) } }
    }
    case 'sample_reference': {
      const parsed = record(input.value, 'claim value', ['sampleIdentifier', 'datasetName', 'datasetVersion', 'submitter', 'laboratory', 'sampledAt'])
      return { ...base, kind: 'sample_reference', value: { sampleIdentifier: text(parsed.sampleIdentifier, 'claim value', 240), datasetName: text(parsed.datasetName, 'claim value', 240), datasetVersion: nullableText(parsed.datasetVersion, 'claim value', 160), submitter: nullableText(parsed.submitter, 'claim value', 240), laboratory: nullableText(parsed.laboratory, 'claim value', 240), sampledAt: nullableTimestamp(parsed.sampledAt, 'claim value') } }
    }
    case 'product_market': {
      const parsed = record(input.value, 'claim value', ['countryCode', 'medical'])
      const countryCode = text(parsed.countryCode, 'claim value', 2)
      if (!/^[A-Z]{2}$/.test(countryCode) || parsed.medical !== true) invalid('claim value')
      return { ...base, kind: 'product_market', value: { countryCode, medical: true } }
    }
    case 'measurement': {
      const parsed = record(input.value, 'claim value', ['analyte', 'value', 'unit', 'productForm', 'batchIdentifier', 'measuredAt'])
      return { ...base, kind: 'measurement', value: { analyte: choice(parsed.analyte, 'claim value', analytes), value: finiteNumber(parsed.value, 'claim value'), unit: choice(parsed.unit, 'claim value', units), productForm: choice(parsed.productForm, 'claim value', productForms), batchIdentifier: nullableText(parsed.batchIdentifier, 'claim value', 240), measuredAt: nullableTimestamp(parsed.measuredAt, 'claim value') } }
    }
    default:
      invalid('claim kind')
  }
}

function edgeBase(input: UnknownRecord): EdgeBase {
  return {
    assertionId: uuid(input.assertionId, 'edge'),
    fromNodeId: uuid(input.fromNodeId, 'edge'),
    evidenceStatus: choice(input.evidenceStatus, 'edge', evidenceStatuses),
    evidence: evidence(input.evidence),
  }
}

function mapEdge(value: unknown): KnowledgeEdge {
  const input = record(value, 'edge', ['assertionId', 'fromNodeId', 'toNodeId', 'layer', 'relationship', 'position', 'evidenceStatus', 'details', 'evidence'])
  const base = edgeBase(input)
  if (input.layer === 'documented_lineage') {
    const toNodeId = input.toNodeId === null ? null : uuid(input.toNodeId, 'edge')
    const relationship = choice(input.relationship, 'edge', lineageRelationships)
    const position = input.position === null ? null : finiteNumber(input.position, 'edge')
    if (position !== null && position !== 1 && position !== 2) invalid('edge')
    record(input.details, 'edge details', [])
    return { ...base, toNodeId, layer: 'documented_lineage', relationship, position, details: {} }
  }
  if (input.layer === 'genetic_similarity') {
    const parsed = record(input.details, 'edge details', ['method', 'datasetName', 'datasetVersion', 'metricName', 'value', 'unit'])
    const relationship = choice(input.relationship, 'edge', geneticRelationships)
    if (input.position !== null) invalid('edge')
    const details = { method: text(parsed.method, 'edge details', 240), datasetName: text(parsed.datasetName, 'edge details', 240), datasetVersion: nullableText(parsed.datasetVersion, 'edge details', 160), metricName: text(parsed.metricName, 'edge details', 240), value: nullableFiniteNumber(parsed.value, 'edge details'), unit: nullableText(parsed.unit, 'edge details', 100) }
    if ((details.value === null) !== (details.unit === null) || (relationship === 'sample_match' && details.value !== null)) invalid('edge details')
    return { ...base, toNodeId: uuid(input.toNodeId, 'edge'), layer: 'genetic_similarity', relationship, position: null, details }
  }
  if (input.layer === 'product_mapping') {
    const parsed = record(input.details, 'edge details', ['productForm'])
    if (input.relationship !== 'product_cultivar' || input.position !== null) invalid('edge')
    return { ...base, toNodeId: uuid(input.toNodeId, 'edge'), layer: 'product_mapping', relationship: 'product_cultivar', position: null, details: { productForm: choice(parsed.productForm, 'edge details', productForms) } }
  }
  invalid('edge layer')
}

function validateClaimSubjects(claims: readonly KnowledgeClaim[], nodesById: ReadonlyMap<string, KnowledgeNode>): void {
  for (const claim of claims) {
    const node = nodesById.get(claim.nodeId)
    if (!node) invalid('claim reference')
    if (claim.kind === 'entity_kind' && claim.value.entityKind !== node.kind) invalid('claim subject')
    if (claim.kind === 'sample_reference' && node.kind !== 'genetic_sample') invalid('claim subject')
    if ((claim.kind === 'product_market' || claim.kind === 'measurement') && node.kind !== 'product') invalid('claim subject')
  }
}

function validateEdges(edges: readonly KnowledgeEdge[], nodesById: ReadonlyMap<string, KnowledgeNode>): void {
  for (const edge of edges) {
    const from = nodesById.get(edge.fromNodeId)
    const to = edge.toNodeId === null ? null : nodesById.get(edge.toNodeId)
    if (!from || (edge.toNodeId !== null && !to)) invalid('edge reference')
    if (edge.toNodeId !== null && edge.fromNodeId === edge.toNodeId) invalid('edge relationship')
    if (edge.layer === 'documented_lineage') {
      if (edge.relationship === 'unknown_parent') {
        if (from.kind !== 'cultivar' || to !== null) invalid('edge relationship')
      } else {
        if (!to) invalid('edge relationship')
        if (['reported_parent', 'cross', 'backcross'].includes(edge.relationship) && (from.kind !== 'cultivar' || to.kind !== 'cultivar')) invalid('edge relationship')
        if (edge.relationship === 'selection_from' && (from.kind !== 'cultivar' || !['cultivar', 'origin_population'].includes(to.kind))) invalid('edge relationship')
        if (edge.relationship === 'historical_origin' && (!['cultivar', 'origin_population'].includes(from.kind) || to.kind !== 'origin_population' || from.id === to.id)) invalid('edge relationship')
        if (edge.relationship === 'population_membership' && (!['cultivar', 'genetic_sample'].includes(from.kind) || to.kind !== 'origin_population')) invalid('edge relationship')
      }
    } else if (edge.layer === 'genetic_similarity') {
      if (from.kind !== 'genetic_sample' || !to || to.kind !== 'genetic_sample' || from.id === to.id) invalid('edge relationship')
    } else if (from.kind !== 'product' || !to || to.kind !== 'cultivar') {
      invalid('edge relationship')
    }
  }
}

export function mapKnowledgeGraph(value: unknown): KnowledgeGraph {
  const input = record(value, 'response', ['snapshotId', 'publishedAt', 'nodes', 'claims', 'edges'])
  if (!Array.isArray(input.nodes) || !Array.isArray(input.claims) || !Array.isArray(input.edges)) invalid('response')
  const nodes = input.nodes.map((item) => {
    const node = record(item, 'node', ['id', 'kind', 'canonicalName'])
    return { id: uuid(node.id, 'node'), kind: choice(node.kind, 'node', nodeKinds), canonicalName: text(node.canonicalName, 'node', 160) }
  })
  const nodeIds = new Set<string>()
  for (const node of nodes) {
    if (nodeIds.has(node.id)) invalid('duplicate node ID')
    nodeIds.add(node.id)
  }
  const claims = input.claims.map(mapClaim)
  const edges = input.edges.map(mapEdge)
  const assertionIds = new Set<string>()
  for (const item of [...claims, ...edges]) {
    if (assertionIds.has(item.assertionId)) invalid('duplicate assertion ID')
    assertionIds.add(item.assertionId)
  }
  const nodesById = new Map(nodes.map((node) => [node.id, node]))
  validateClaimSubjects(claims, nodesById)
  validateEdges(edges, nodesById)
  return { snapshotId: uuid(input.snapshotId, 'snapshot ID'), publishedAt: timestamp(input.publishedAt, 'published timestamp'), nodes, claims, edges }
}
