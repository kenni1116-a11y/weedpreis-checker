import { render, screen } from '@testing-library/react'
import { beforeEach, expect, it } from 'vitest'
import type { RankedOffer } from '../domain/offer'
import { FavoritesView } from './FavoritesView'

const results: RankedOffer[] = [
  {
    offer: {
      id: 'offer-a',
      productId: 'alpha',
      productName: 'Testblüte Alpha 22/1',
      manufacturer: 'Testlabor Nord',
      form: 'flower',
      thcPercent: 22,
      cbdPercent: 1,
      pharmacyId: 'test-a',
      pharmacyName: 'Muster-Apotheke A – Testdaten',
      sourceType: 'feed',
      sourceUrl: 'https://example.invalid/a',
      unitPriceCents: 649,
      shippingCents: 499,
      pickup: true,
      shipping: true,
      available: true,
      checkedAt: '2026-07-22T12:00:00.000Z',
    },
    totalPriceCents: 6989,
    current: true,
  },
]

beforeEach(() => localStorage.clear())

it('shows locally saved offers with the shared result presentation', () => {
  localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))

  render(<FavoritesView results={results} grams={10} />)

  expect(screen.getByRole('heading', { name: 'Favoriten' })).toBeInTheDocument()
  expect(screen.getByText('Muster-Apotheke A – Testdaten')).toBeInTheDocument()
  expect(screen.getByText((_, element) =>
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 g: 69,89 €',
  )).toBeInTheDocument()
  expect(screen.getByText(/zuletzt geprüft/)).toBeInTheDocument()
})

it('explains when no local favorites have been saved', () => {
  render(<FavoritesView results={results} grams={10} />)

  expect(screen.getByText('Noch keine Favoriten gespeichert.')).toBeInTheDocument()
})
