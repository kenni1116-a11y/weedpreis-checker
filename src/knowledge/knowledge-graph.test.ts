import { describe, expect, it } from 'vitest'
import { mapKnowledgeGraph } from './knowledge-graph'

const ids = {
  snapshot: '71000000-0000-4000-8000-000000000001',
  population: '71000000-0000-4000-8000-000000000002',
  populationTwo: '71000000-0000-4000-8000-000000000008',
  cultivar: '7a000000-0000-4000-8000-000000000003',
  cultivarParent: '71000000-0000-4000-8000-000000000004',
  sample: '71000000-0000-4000-8000-000000000005',
  sampleMatch: '71000000-0000-4000-8000-000000000006',
  product: '71000000-0000-4000-8000-000000000007',
}

const evidence = {
  sourceName: 'Synthetic knowledge source',
  sourceVersion: 'fixture-1',
  retrievedAt: '2026-07-30T12:00:00.000Z',
  citationUrl: 'https://example.invalid/knowledge',
  sourceLocator: '$.fixture',
  extractionMethod: 'structured',
  attribution: 'Synthetic fixture attribution',
}

const validGraph = {
  snapshotId: ids.snapshot,
  publishedAt: '2026-07-30T12:00:00.000Z',
  nodes: [
    { id: ids.population, kind: 'origin_population', canonicalName: 'Population' },
    { id: ids.populationTwo, kind: 'origin_population', canonicalName: 'Second population' },
    { id: ids.cultivar, kind: 'cultivar', canonicalName: 'Cultivar' },
    { id: ids.cultivarParent, kind: 'cultivar', canonicalName: 'Parent cultivar' },
    { id: ids.sample, kind: 'genetic_sample', canonicalName: 'Sample' },
    { id: ids.sampleMatch, kind: 'genetic_sample', canonicalName: 'Matching sample' },
    { id: ids.product, kind: 'product', canonicalName: 'Product' },
  ],
  claims: [
    {
      assertionId: '72000000-0000-4000-8000-000000000001',
      nodeId: ids.cultivar,
      kind: 'entity_kind',
      value: { entityKind: 'cultivar' },
      evidenceStatus: 'confirmed',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000002',
      nodeId: ids.cultivar,
      kind: 'name',
      value: { name: 'Cultivar', language: 'en' },
      evidenceStatus: 'single_source',
      evidence: { ...evidence, extractionMethod: 'manual' },
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000003',
      nodeId: ids.cultivar,
      kind: 'alias',
      value: { name: 'Market name', language: null, aliasType: 'market', market: 'DE' },
      evidenceStatus: 'disputed',
      evidence: { ...evidence, extractionMethod: 'ai_assisted' },
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000004',
      nodeId: ids.cultivar,
      kind: 'traditional_classification',
      value: { classification: 'hybrid' },
      evidenceStatus: 'historical',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000005',
      nodeId: ids.population,
      kind: 'origin_region',
      value: { regionName: 'Region', regionCode: 'RG' },
      evidenceStatus: 'unknown',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000006',
      nodeId: ids.population,
      kind: 'era',
      value: { startYear: 1970, endYear: null, label: 'Historical era' },
      evidenceStatus: 'retracted',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000007',
      nodeId: ids.sample,
      kind: 'sample_reference',
      value: { sampleIdentifier: 'Sample-1', datasetName: 'Dataset', datasetVersion: null, submitter: null, laboratory: 'Lab', sampledAt: '2026-07-29T12:00:00.000Z' },
      evidenceStatus: 'confirmed',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000008',
      nodeId: ids.product,
      kind: 'product_market',
      value: { countryCode: 'DE', medical: true },
      evidenceStatus: 'single_source',
      evidence,
    },
    {
      assertionId: '72000000-0000-4000-8000-000000000009',
      nodeId: ids.product,
      kind: 'measurement',
      value: { analyte: 'thc', value: 22.4, unit: 'percent', productForm: 'flower', batchIdentifier: null, measuredAt: null },
      evidenceStatus: 'disputed',
      evidence,
    },
  ],
  edges: [
    {
      assertionId: '73000000-0000-4000-8000-000000000001',
      fromNodeId: ids.cultivar,
      toNodeId: ids.cultivarParent,
      layer: 'documented_lineage',
      relationship: 'reported_parent',
      position: 1,
      evidenceStatus: 'historical',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000002',
      fromNodeId: ids.cultivar,
      toNodeId: null,
      layer: 'documented_lineage',
      relationship: 'unknown_parent',
      position: 2,
      evidenceStatus: 'unknown',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000003',
      fromNodeId: ids.sample,
      toNodeId: ids.sampleMatch,
      layer: 'genetic_similarity',
      relationship: 'genetic_similarity',
      position: null,
      evidenceStatus: 'confirmed',
      details: { method: 'SNP', datasetName: 'Dataset', datasetVersion: '1', metricName: 'Similarity', value: 0.9, unit: 'score' },
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000004',
      fromNodeId: ids.sampleMatch,
      toNodeId: ids.sample,
      layer: 'genetic_similarity',
      relationship: 'sample_match',
      position: null,
      evidenceStatus: 'single_source',
      details: { method: 'Fingerprint', datasetName: 'Dataset', datasetVersion: null, metricName: 'Exact match', value: null, unit: null },
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000005',
      fromNodeId: ids.product,
      toNodeId: ids.cultivar,
      layer: 'product_mapping',
      relationship: 'product_cultivar',
      position: null,
      evidenceStatus: 'retracted',
      details: { productForm: 'flower' },
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000006',
      fromNodeId: ids.cultivar,
      toNodeId: ids.cultivarParent,
      layer: 'documented_lineage',
      relationship: 'cross',
      position: 2,
      evidenceStatus: 'confirmed',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000007',
      fromNodeId: ids.cultivar,
      toNodeId: ids.cultivarParent,
      layer: 'documented_lineage',
      relationship: 'backcross',
      position: null,
      evidenceStatus: 'confirmed',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000008',
      fromNodeId: ids.cultivar,
      toNodeId: ids.population,
      layer: 'documented_lineage',
      relationship: 'selection_from',
      position: null,
      evidenceStatus: 'confirmed',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000009',
      fromNodeId: ids.populationTwo,
      toNodeId: ids.population,
      layer: 'documented_lineage',
      relationship: 'historical_origin',
      position: null,
      evidenceStatus: 'confirmed',
      details: {},
      evidence,
    },
    {
      assertionId: '73000000-0000-4000-8000-000000000010',
      fromNodeId: ids.sample,
      toNodeId: ids.population,
      layer: 'documented_lineage',
      relationship: 'population_membership',
      position: null,
      evidenceStatus: 'confirmed',
      details: {},
      evidence,
    },
  ],
}

function cloneGraph(): Record<string, unknown> {
  return structuredClone(validGraph) as Record<string, unknown>
}

type GraphChange = (graph: Record<string, unknown>) => void

function expectInvalid(change: GraphChange): void {
  const graph = cloneGraph()
  change(graph)
  expect(() => mapKnowledgeGraph(graph)).toThrow('Invalid knowledge graph')
}

describe('knowledge graph mapper', () => {
  it('maps the complete published graph without changing evidence statuses or inferring spatial meaning', () => {
    const result = mapKnowledgeGraph(validGraph)

    expect(result).toEqual(validGraph)
    expect(result.nodes.map((node) => node.kind)).toEqual([
      'origin_population',
      'origin_population',
      'cultivar',
      'cultivar',
      'genetic_sample',
      'genetic_sample',
      'product',
    ])
    expect(result.edges.map((edge) => edge.layer)).toEqual([
      'documented_lineage',
      'documented_lineage',
      'genetic_similarity',
      'genetic_similarity',
      'product_mapping',
      'documented_lineage',
      'documented_lineage',
      'documented_lineage',
      'documented_lineage',
      'documented_lineage',
    ])
    expect(new Set([...result.claims, ...result.edges].map((item) => item.evidenceStatus))).toEqual(new Set([
      'confirmed', 'single_source', 'disputed', 'historical', 'unknown', 'retracted',
    ]))
    expect('spatialDistance' in result.edges[0]).toBe(false)
  })

  it('accepts a null citation URL and canonicalizes mixed-case UUID references', () => {
    const graph = cloneGraph()
    const claim = (graph.claims as Array<Record<string, unknown>>)[0]
    claim.nodeId = ids.cultivar.toUpperCase()
    claim.evidence = { ...evidence, citationUrl: null }

    const result = mapKnowledgeGraph(graph)

    expect(result.claims[0].nodeId).toBe(ids.cultivar)
    expect(result.claims[0].evidence.citationUrl).toBeNull()
  })

  it('measures text limits in Unicode code points rather than UTF-16 code units', () => {
    const graph = cloneGraph()
    const astralName = '𠜎'.repeat(100)
    ;(graph.nodes as Array<Record<string, unknown>>)[0].canonicalName = astralName

    expect(mapKnowledgeGraph(graph).nodes[0].canonicalName).toBe(astralName)
    expectInvalid((invalidGraph) => {
      ;(invalidGraph.nodes as Array<Record<string, unknown>>)[0].canonicalName = '𠜎'.repeat(161)
    })
  })

  it.each<readonly [GraphChange]>([
    [(graph) => { graph.snapshotId = 'not-a-uuid' }],
    [(graph) => { graph.publishedAt = 'not-a-timestamp' }],
    [(graph) => { graph.nodes = {} }],
    [(graph) => { graph.claims = null }],
    [(graph) => { graph.edges = 'not-an-array' }],
    [(graph) => { graph.unexpected = true }],
    [(graph) => { (graph.nodes as Array<Record<string, unknown>>)[0].unexpected = true }],
    [(graph) => { (graph.claims as Array<Record<string, unknown>>)[0].value = [] }],
    [(graph) => { (graph.claims as Array<Record<string, unknown>>)[0].evidence = [] }],
    [(graph) => { (graph.edges as Array<Record<string, unknown>>)[0].details = [] }],
    [(graph) => { (graph.edges as Array<Record<string, unknown>>)[0].spatialDistance = 0.1 }],
    [(graph) => { ((graph.claims as Array<Record<string, unknown>>)[0].value as Record<string, unknown>).unexpected = true }],
    [(graph) => { ((graph.claims as Array<Record<string, unknown>>)[0].evidence as Record<string, unknown>).unexpected = true }],
    [(graph) => { ((graph.edges as Array<Record<string, unknown>>)[2].details as Record<string, unknown>).unexpected = true }],
    [(graph) => { ((graph.edges as Array<Record<string, unknown>>)[4].details as Record<string, unknown>).unexpected = true }],
    [(graph) => { (graph.claims as Array<Record<string, unknown>>)[0].evidence = { ...evidence, citationUrl: 'http://example.invalid/knowledge' } }],
    [(graph) => { (graph.claims as Array<Record<string, unknown>>)[0].evidence = { ...evidence, retrievedAt: '2026-02-30T12:00:00.000Z' } }],
    [(graph) => { ((graph.claims as Array<Record<string, unknown>>)[1].value as Record<string, unknown>).language = 'not a language tag' }],
    [(graph) => { ((graph.claims as Array<Record<string, unknown>>)[8].value as Record<string, unknown>).value = Number.POSITIVE_INFINITY }],
  ])('rejects malformed JSON-shaped graph values', (change) => {
    expectInvalid(change)
  })

  it.each<readonly [string, GraphChange]>([
    ['node ID', (graph) => { (graph.nodes as Array<Record<string, unknown>>)[1].id = ids.population }],
    ['mixed-case node ID', (graph) => { (graph.nodes as Array<Record<string, unknown>>)[1].id = ids.cultivar.toUpperCase() }],
    ['claim assertion ID', (graph) => { (graph.claims as Array<Record<string, unknown>>)[1].assertionId = '72000000-0000-4000-8000-000000000001' }],
    ['edge assertion ID', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].assertionId = '72000000-0000-4000-8000-000000000001' }],
    ['claim node reference', (graph) => { (graph.claims as Array<Record<string, unknown>>)[0].nodeId = '74000000-0000-4000-8000-000000000001' }],
    ['edge source reference', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].fromNodeId = '74000000-0000-4000-8000-000000000001' }],
    ['edge target reference', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].toNodeId = '74000000-0000-4000-8000-000000000001' }],
  ])('rejects duplicate or dangling %s', (_description, change) => {
    expectInvalid(change)
  })

  it.each<readonly [string, GraphChange]>([
    ['claims whose subject conflicts with their kind', (graph) => { (graph.claims as Array<Record<string, unknown>>)[6].nodeId = ids.cultivar }],
    ['entity kind claims that disagree with their node', (graph) => { ((graph.claims as Array<Record<string, unknown>>)[0].value as Record<string, unknown>).entityKind = 'product' }],
    ['documented edges with a target for unknown parents', (graph) => { (graph.edges as Array<Record<string, unknown>>)[1].toNodeId = ids.cultivarParent }],
    ['documented edges without a target', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].toNodeId = null }],
    ['documented edges between incompatible kinds', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].toNodeId = ids.population }],
    ['documented self relations', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].toNodeId = ids.cultivar }],
    ['genetic edges that do not connect distinct samples', (graph) => { (graph.edges as Array<Record<string, unknown>>)[2].toNodeId = ids.sample }],
    ['product mappings other than product to cultivar', (graph) => { (graph.edges as Array<Record<string, unknown>>)[4].toNodeId = ids.population }],
    ['genetic relationships mislabeled as documented lineage', (graph) => { const edge = (graph.edges as Array<Record<string, unknown>>)[2]; edge.layer = 'documented_lineage'; edge.relationship = 'genetic_similarity'; edge.details = {}; edge.position = null }],
    ['pedigree relationships mislabeled as genetic similarity', (graph) => { const edge = (graph.edges as Array<Record<string, unknown>>)[0]; edge.layer = 'genetic_similarity'; edge.relationship = 'reported_parent'; edge.details = { ...((validGraph.edges[2].details)) }; edge.position = null; edge.fromNodeId = ids.sample; edge.toNodeId = ids.sampleMatch }],
    ['invalid documented-lineage position', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].position = 3 }],
    ['extra details on documented lineage', (graph) => { (graph.edges as Array<Record<string, unknown>>)[0].details = { note: 'not permitted' } }],
    ['sample-match metrics', (graph) => { const details = (graph.edges as Array<Record<string, unknown>>)[3].details as Record<string, unknown>; details.value = 1; details.unit = 'score' }],
    ['cross endpoints', (graph) => { (graph.edges as Array<Record<string, unknown>>)[5].toNodeId = ids.population }],
    ['cross self relation', (graph) => { (graph.edges as Array<Record<string, unknown>>)[5].toNodeId = ids.cultivar }],
    ['backcross endpoints', (graph) => { (graph.edges as Array<Record<string, unknown>>)[6].toNodeId = ids.population }],
    ['backcross self relation', (graph) => { (graph.edges as Array<Record<string, unknown>>)[6].toNodeId = ids.cultivar }],
    ['selection endpoints', (graph) => { (graph.edges as Array<Record<string, unknown>>)[7].toNodeId = ids.sample }],
    ['selection self relation', (graph) => { (graph.edges as Array<Record<string, unknown>>)[7].toNodeId = ids.cultivar }],
    ['historical-origin endpoints', (graph) => { (graph.edges as Array<Record<string, unknown>>)[8].toNodeId = ids.cultivar }],
    ['historical-origin self relation', (graph) => { (graph.edges as Array<Record<string, unknown>>)[8].toNodeId = ids.populationTwo }],
    ['population-membership endpoints', (graph) => { (graph.edges as Array<Record<string, unknown>>)[9].toNodeId = ids.cultivar }],
    ['population-membership self relation', (graph) => { (graph.edges as Array<Record<string, unknown>>)[9].toNodeId = ids.sample }],
  ])('rejects %s', (_description, change) => {
    expectInvalid(change)
  })
})
