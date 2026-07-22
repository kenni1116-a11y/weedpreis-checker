import { cleanup, render, screen } from '@testing-library/react'
import { beforeEach, expect, it, vi } from 'vitest'
import { createInMemoryOffersRepository } from '../data/in-memory-offers-repository'
import type { Offer } from '../domain/offer'
import { FavoritesView } from './FavoritesView'

const offers: Offer[] = [
  {
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
      priceUnit: 'g',
      shippingCents: 499,
      pickup: true,
      shipping: true,
      available: true,
      checkedAt: '2026-07-22T12:00:00.000Z',
  },
]

const repository = createInMemoryOffersRepository(offers)

beforeEach(() => {
  cleanup()
  localStorage.clear()
})

it('resolves locally saved offer IDs with the shared result presentation', async () => {
  localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))

  render(
    <FavoritesView
      repository={repository}
      pricingContext={{ mode: 'shipping', quantity: 10 }}
      now={new Date('2026-07-22T18:00:00.000Z')}
    />,
  )

  expect(screen.getByRole('heading', { name: 'Favoriten' })).toBeInTheDocument()
  expect(await screen.findByText('Muster-Apotheke A – Testdaten')).toBeInTheDocument()
  expect(screen.getByText((_, element) =>
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 g: 69,89 €',
  )).toBeInTheDocument()
  expect(screen.getByText(/zuletzt geprüft/)).toBeInTheDocument()
})

it('explains when no local favorites have been saved', () => {
  render(<FavoritesView repository={repository} pricingContext={{ mode: 'shipping', quantity: 10 }} />)

  expect(screen.getByText('Noch keine Favoriten gespeichert.')).toBeInTheDocument()
})

it('reports when saved favorites cannot be resolved', async () => {
  localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))
  const failingRepository = {
    search: vi.fn(),
    getByIds: vi.fn().mockRejectedValue(new Error('offline')),
  }

  render(
    <FavoritesView
      repository={failingRepository}
      pricingContext={{ mode: 'shipping', quantity: 10 }}
    />,
  )

  expect(await screen.findByRole('alert')).toHaveTextContent('Favoriten konnten nicht geladen werden')
})
