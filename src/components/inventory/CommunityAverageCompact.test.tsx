import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import type { CatalogSearchMatch } from '../../catalog/catalog-search'
import type { PublishedCommunityAverage } from '../../community/community-values'
import { CommunityAverageCompact } from './CommunityAverageCompact'

const match: CatalogSearchMatch = {
  id: '51000000-0000-4000-8000-000000000001',
  kind: 'cultivar',
  canonicalName: 'Synthetic Cultivar',
  matchedName: 'Synthetic Cultivar',
  matchReason: 'canonical',
  canonicalCultivarId: '51000000-0000-4000-8000-000000000001',
  isFlower: true,
  preferredParents: [null, null],
  hasAdditionalLineage: false,
  sourcedThcLabel: '22,4 %',
  sourcedCbdLabel: '0,8 %',
  sourcedValueEvidence: [{
    sourceName: 'Synthetic source',
    sourceVersion: 'fixture-1',
    retrievedAt: '2026-07-28T18:00:01.000Z',
    citationUrl: 'https://example.invalid/record',
    attribution: 'Synthetic attribution',
  }],
}

const average: PublishedCommunityAverage = {
  cultivarId: '51000000-0000-4000-8000-000000000001',
  thcMean: 21.3,
  cbdMean: 0.7,
  contributorBand: '25+',
  computedAt: '2026-07-28T18:00:00.000Z',
}

describe('CommunityAverageCompact', () => {
  afterEach(cleanup)

  it('keeps sourced evidence and community values as separate layers', () => {
    const { container } = render(
      <CommunityAverageCompact match={match} average={average} />,
    )

    expect(screen.getByText('Hersteller-/Labordaten')).toBeInTheDocument()
    expect(screen.getByText('THC 22,4 %')).toBeInTheDocument()
    expect(screen.getByText('CBD 0,8 %')).toBeInTheDocument()
    expect(screen.getByText('Belege')).toBeInTheDocument()
    expect(screen.getByText('Synthetic source')).toBeInTheDocument()
    expect(screen.getByText('Version fixture-1')).toBeInTheDocument()
    expect(screen.getByText('Abruf 28.07.2026')).toBeInTheDocument()
    expect(screen.getByText('Synthetic attribution')).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Quelle öffnen' })).toHaveAttribute(
      'href',
      'https://example.invalid/record',
    )

    const community = container.querySelector('.community-average')
    expect(community?.textContent).toMatch(/^ØCommunity-Mittelwert/)
    expect(screen.getByText('THC 21,3 %')).toBeInTheDocument()
    expect(screen.getByText('CBD 0,7 %')).toBeInTheDocument()
    expect(screen.getByText('25+')).toBeInTheDocument()
    expect(community).not.toHaveTextContent('THC Ø')
    expect(community).not.toHaveTextContent('CBD Ø')
    expect(container.querySelector('svg')).toHaveAttribute(
      'aria-hidden',
      'true',
    )
    expect(screen.getAllByText('Community-Mittelwert')).toHaveLength(1)
  })

  it('shows a threshold message without an exact count', () => {
    render(<CommunityAverageCompact match={match} average={null} />)

    expect(screen.getByText(
      'Noch nicht genügend Community-Werte.',
    )).toBeInTheDocument()
    expect(screen.getByLabelText('Community-Werte')).not.toHaveTextContent(
      /\b[0-4]\s+(Personen|Beiträge)/,
    )
  })
})
