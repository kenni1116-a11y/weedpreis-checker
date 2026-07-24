import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { renderToString } from 'react-dom/server'
import { beforeEach, expect, it, vi } from 'vitest'
import { createInMemoryOffersRepository } from '../data/in-memory-offers-repository'
import type { Offer } from '../domain/offer'
import { devicePreferences } from '../storage/device-preferences'
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

const shippingOnlyOffer: Offer = {
  ...offers[0],
  id: 'offer-b',
  productId: 'bravo',
  pharmacyId: 'test-b',
  pharmacyName: 'Muster-Apotheke B – Testdaten',
  sourceType: 'manual-review',
  sourceUrl: 'https://example.invalid/b',
  unitPriceCents: 675,
  shippingCents: 0,
  pickup: false,
}

const unavailableOffer: Offer = {
  ...offers[0],
  id: 'offer-unavailable',
  pharmacyId: 'test-unavailable',
  pharmacyName: 'Nicht verfügbare Muster-Apotheke – Testdaten',
  available: false,
}

const repository = createInMemoryOffersRepository([...offers, shippingOnlyOffer, unavailableOffer])

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
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 g (Versand): 69,89 €',
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

it('renders a loading state on the first render when favorite IDs are persisted', () => {
  localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))

  const html = renderToString(
    <FavoritesView repository={repository} pricingContext={{ mode: 'shipping', quantity: 10 }} />,
  )

  expect(html).toContain('Favoriten werden geladen')
  expect(html).not.toContain('Noch keine Favoriten gespeichert')
})

it('keeps a shipping-only favorite visible after a pickup search context', async () => {
  localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-b']))

  render(
    <FavoritesView
      repository={repository}
      pricingContext={{ mode: 'pickup', quantity: 7 }}
      now={new Date('2026-07-22T18:00:00.000Z')}
    />,
  )

  expect(await screen.findByText('Muster-Apotheke B – Testdaten')).toBeInTheDocument()
  expect(screen.getByText('Dieses Angebot ist nicht zur Abholung verfügbar.')).toBeInTheDocument()
  expect(screen.getByText((_, element) =>
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g (Versand): 47,25 €',
  )).toBeInTheDocument()
  expect(screen.getByText(/manual-review · zuletzt geprüft/)).toBeInTheDocument()
  expect(screen.getByRole('button', { name: 'Favorit entfernen' })).toBeInTheDocument()
  expect(screen.queryByText('Noch keine Favoriten gespeichert.')).not.toBeInTheDocument()
})

it('shows unavailable and unknown saved IDs and lets the user remove either', async () => {
  localStorage.setItem(
    'weedpreis.favorites',
    JSON.stringify(['offer-unavailable', 'offer-missing']),
  )
  const user = userEvent.setup()

  render(
    <FavoritesView
      repository={repository}
      pricingContext={{ mode: 'shipping', quantity: 10 }}
      now={new Date('2026-07-22T18:00:00.000Z')}
    />,
  )

  expect(await screen.findByText('Nicht verfügbare Muster-Apotheke – Testdaten')).toBeInTheDocument()
  expect(screen.getByText('Dieses gespeicherte Angebot ist derzeit nicht verfügbar.')).toBeInTheDocument()
  const missing = screen.getByText('Gespeichertes Angebot offer-missing ist nicht mehr im Testkatalog verfügbar.')
  expect(missing).toBeInTheDocument()
  expect(screen.queryByText('Noch keine Favoriten gespeichert.')).not.toBeInTheDocument()

  await user.click(missing.closest('article')!.querySelector('button')!)

  expect(devicePreferences.getFavoriteIds()).toEqual(['offer-unavailable'])
  expect(await screen.findByText('Nicht verfügbare Muster-Apotheke – Testdaten')).toBeInTheDocument()
  expect(screen.queryByText(/offer-missing/)).not.toBeInTheDocument()
})
