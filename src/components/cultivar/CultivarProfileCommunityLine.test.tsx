import { cleanup, render, screen } from '@testing-library/react'
import { afterEach, describe, expect, it } from 'vitest'
import type { PublishedCommunityAverage } from '../../community/community-values'
import { CultivarProfileCommunityLine } from './CultivarProfileCommunityLine'

const average: PublishedCommunityAverage = {
  cultivarId: '51000000-0000-4000-8000-000000000001',
  thcMean: 21.3,
  cbdMean: 0.7,
  contributorBand: '5+',
  computedAt: '2026-07-28T18:00:00.000Z',
}

describe('CultivarProfileCommunityLine', () => {
  afterEach(cleanup)

  it('renders one subtle privacy-safe community line', () => {
    const { container } = render(
      <CultivarProfileCommunityLine average={average} />,
    )

    expect(container.firstChild).toHaveTextContent(
      'ØCommunity-MittelwertTHC 21,3 %CBD 0,7 %5+',
    )
    expect(screen.queryByText('label')).not.toBeInTheDocument()
    expect(screen.queryByText('laboratory')).not.toBeInTheDocument()
  })

  it('renders the same below-threshold copy without raw values', () => {
    render(<CultivarProfileCommunityLine average={null} />)

    expect(screen.getByText(
      'Noch nicht genügend Community-Werte.',
    )).toBeInTheDocument()
  })
})
