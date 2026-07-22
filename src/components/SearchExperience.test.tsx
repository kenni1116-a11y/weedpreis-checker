import { act, cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, it, vi } from 'vitest'
import { App } from '../app/App'
import type { OffersRepository } from '../data/offers-repository'
import type { RankedOffer } from '../domain/offer'
import { SearchExperience } from './SearchExperience'

function deferred<T>() {
  let resolve!: (value: T) => void
  let reject!: (reason?: unknown) => void
  const promise = new Promise<T>((resolvePromise, rejectPromise) => {
    resolve = resolvePromise
    reject = rejectPromise
  })
  return { promise, reject, resolve }
}

function rankedOffer(id: string, productName: string, priceUnit: 'g' | 'ml'): RankedOffer {
  return {
    offer: {
      id,
      productId: id,
      productName,
      manufacturer: 'Testlabor',
      form: priceUnit === 'g' ? 'flower' : 'extract',
      thcPercent: 20,
      cbdPercent: 1,
      pharmacyId: id,
      pharmacyName: `Apotheke ${id}`,
      sourceType: 'feed',
      sourceUrl: `https://example.invalid/${id}`,
      unitPriceCents: 100,
      priceUnit,
      shippingCents: 0,
      pickup: true,
      shipping: true,
      available: true,
      checkedAt: new Date().toISOString(),
    },
    totalPriceCents: 700,
    current: true,
  }
}

function deferredRepository(search: OffersRepository['search']): OffersRepository {
  return { search, getByIds: async () => [] }
}

beforeEach(() => {
  cleanup()
  localStorage.clear()
  localStorage.setItem('weedpreis.adult', 'true')
})

it('searches test offers and shows transparent totals', async () => {
  const user = userEvent.setup()

  render(<App />)

  expect(screen.getByText('Ausschließlich synthetische Testdaten')).toBeInTheDocument()
  await user.type(screen.getByRole('searchbox'), 'Alpha')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))

  expect((await screen.findAllByText(/Gesamtpreis für 10 g/)).length).toBeGreaterThan(0)
  expect(screen.getAllByText(/zuletzt geprüft/).length).toBeGreaterThan(0)
})

it('renders extract price and quantity totals in milliliters', async () => {
  const user = userEvent.setup()

  render(<App />)
  await user.type(screen.getByRole('searchbox'), 'Beta')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))

  expect(await screen.findByText((_, element) =>
    element?.tagName === 'STRONG' && element.textContent === '7,10 € / ml',
  )).toBeInTheDocument()
  expect(screen.getByText((_, element) =>
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 ml: 75,99 €',
  )).toBeInTheDocument()
})

it('keeps a newer result and quantity when an older search resolves last', async () => {
  const first = deferred<RankedOffer[]>()
  const second = deferred<RankedOffer[]>()
  const search = vi.fn()
    .mockImplementationOnce(() => first.promise)
    .mockImplementationOnce(() => second.promise)
  const onResultsChange = vi.fn()
  const user = userEvent.setup()
  render(<SearchExperience repository={deferredRepository(search)} onResultsChange={onResultsChange} />)

  await user.type(screen.getByRole('searchbox'), 'Alpha')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))
  await user.clear(screen.getByRole('searchbox'))
  await user.type(screen.getByRole('searchbox'), 'Beta')
  await user.clear(screen.getByRole('spinbutton', { name: 'Menge' }))
  await user.type(screen.getByRole('spinbutton', { name: 'Menge' }), '7')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))

  await act(async () => second.resolve([rankedOffer('offer-b', 'Beta', 'ml')]))
  expect(await screen.findByText((_, element) =>
    element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 ml: 7,00 €',
  )).toBeInTheDocument()

  await act(async () => first.resolve([rankedOffer('offer-a', 'Alpha', 'g')]))
  expect(screen.queryByText('Alpha · Testlabor')).not.toBeInTheDocument()
  expect(screen.getByText('Beta · Testlabor')).toBeInTheDocument()
  expect(onResultsChange).toHaveBeenCalledOnce()
  expect(onResultsChange.mock.calls[0][1]).toMatchObject({ quantity: 7, text: 'Beta' })
})

it('ignores an older error after a newer search succeeds', async () => {
  const first = deferred<RankedOffer[]>()
  const second = deferred<RankedOffer[]>()
  const search = vi.fn()
    .mockImplementationOnce(() => first.promise)
    .mockImplementationOnce(() => second.promise)
  const user = userEvent.setup()
  render(<SearchExperience repository={deferredRepository(search)} />)

  await user.type(screen.getByRole('searchbox'), 'Alpha')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))
  await user.clear(screen.getByRole('searchbox'))
  await user.type(screen.getByRole('searchbox'), 'Beta')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))

  await act(async () => second.resolve([rankedOffer('offer-b', 'Beta', 'ml')]))
  await act(async () => first.reject(new Error('slow failure')))

  expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  expect(screen.getByText('Beta · Testlabor')).toBeInTheDocument()
})

it('keeps a newer error when an older search resolves afterwards', async () => {
  const first = deferred<RankedOffer[]>()
  const second = deferred<RankedOffer[]>()
  const search = vi.fn()
    .mockImplementationOnce(() => first.promise)
    .mockImplementationOnce(() => second.promise)
  const user = userEvent.setup()
  render(<SearchExperience repository={deferredRepository(search)} />)

  await user.type(screen.getByRole('searchbox'), 'Alpha')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))
  await user.clear(screen.getByRole('searchbox'))
  await user.type(screen.getByRole('searchbox'), 'Beta')
  await user.click(screen.getByRole('button', { name: 'Suchen' }))

  await act(async () => second.reject(new Error('latest failure')))
  expect(await screen.findByRole('alert')).toBeInTheDocument()
  await act(async () => first.resolve([rankedOffer('offer-a', 'Alpha', 'g')]))

  expect(screen.getByRole('alert')).toBeInTheDocument()
  expect(screen.queryByText('Alpha · Testlabor')).not.toBeInTheDocument()
})

it('states that pickup locations are synthetic and not postcode-resolved', async () => {
  const user = userEvent.setup()
  render(<App />)

  await user.click(screen.getByRole('button', { name: 'Abholung' }))

  expect(screen.getByText(/keine Live-Standortsuche/i)).toBeInTheDocument()
  expect(screen.queryByRole('textbox', { name: /Postleitzahl/i })).not.toBeInTheDocument()
})
