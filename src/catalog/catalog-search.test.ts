import { describe, expect, it } from 'vitest'
import {
  mapCatalogSearchRow,
  type CatalogSearchMatch,
} from './catalog-search'

const validRow = {
  id: '51000000-0000-4000-8000-000000000001',
  kind: 'product',
  canonical_name: 'Synthetic Gorilla Skittlez 22/1',
  matched_name: 'Gorilla Skittlez',
  match_reason: 'product',
  canonical_cultivar_id: '51000000-0000-4000-8000-000000000002',
  is_flower: true,
  preferred_parents: ['Gorilla Glue', 'Skittlez'],
  has_additional_lineage: true,
  sourced_thc_label: '22.4 %',
  sourced_cbd_label: '0.8 %',
  sourced_value_evidence: [{
    sourceName: 'Synthetic source',
    sourceVersion: 'fixture-1',
    retrievedAt: '2026-07-28T18:00:01.000Z',
    citationUrl: 'https://example.invalid/record',
    attribution: 'Synthetic attribution',
  }],
}

describe('catalog search row mapper', () => {
  it('maps public database fields without replacing the matched spelling', () => {
    const result: CatalogSearchMatch = mapCatalogSearchRow(validRow)

    expect(result).toEqual({
      id: validRow.id,
      kind: 'product',
      canonicalName: 'Synthetic Gorilla Skittlez 22/1',
      matchedName: 'Gorilla Skittlez',
      matchReason: 'product',
      canonicalCultivarId: validRow.canonical_cultivar_id,
      isFlower: true,
      preferredParents: ['Gorilla Glue', 'Skittlez'],
      hasAdditionalLineage: true,
      sourcedThcLabel: '22.4 %',
      sourcedCbdLabel: '0.8 %',
      sourcedValueEvidence: validRow.sourced_value_evidence,
    })
    expect(result.matchedName).not.toBe(result.canonicalName)
  })

  it.each([
    [{ ...validRow, kind: 'company' }, 'kind'],
    [{ ...validRow, match_reason: 'guess' }, 'match reason'],
    [{ ...validRow, preferred_parents: ['One', 'Two', 'Three'] }, 'parents'],
    [{
      ...validRow,
      canonical_cultivar_id: null,
      kind: 'product',
      is_flower: true,
    }, 'cultivar mapping'],
  ])('rejects malformed public rows: %s', (row, message) => {
    expect(() => mapCatalogSearchRow(row)).toThrow(message)
  })

  it('rejects unsafe or incomplete source evidence', () => {
    expect(() =>
      mapCatalogSearchRow({
        ...validRow,
        sourced_value_evidence: [{
          ...validRow.sourced_value_evidence[0],
          citationUrl: 'javascript:alert(1)',
        }],
      })
    ).toThrow('source evidence')

    expect(() =>
      mapCatalogSearchRow({
        ...validRow,
        sourced_value_evidence: [{
          sourceName: 'Missing the other required fields',
        }],
      })
    ).toThrow('source evidence')
  })
})
