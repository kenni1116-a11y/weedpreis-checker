import { act, cleanup, render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { OffersRepository } from '../data/offers-repository'
import { syntheticOffers } from '../data/synthetic-offers'
import { App } from './App'

const pickupSearchTotal = (_: string, element: Element | null) =>
  element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g: 45,43 €'

const pickupFavoriteTotal = (_: string, element: Element | null) =>
  element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g (Abholung): 45,43 €'

function deferred<T>() {
  let resolve!: (value: T) => void
  const promise = new Promise<T>((resolvePromise) => {
    resolve = resolvePromise
  })
  return { promise, resolve }
}

describe('App', () => {
  beforeEach(() => {
    cleanup()
    localStorage.clear()
    localStorage.setItem('weedpreis.adult', 'true')
  })

  it('identifies itself as a neutral pharmacy comparison', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Weedpreis' })).toBeInTheDocument()
    expect(screen.getByText('Neutraler Apothekenvergleich')).toBeInTheDocument()
  })

  it('keeps a pickup favorite at the searched quantity', async () => {
    const user = userEvent.setup()
    const app = within(render(<App />).container)

    await user.click(app.getByRole('button', { name: 'Abholung' }))
    await user.clear(app.getByRole('spinbutton', { name: 'Menge' }))
    await user.type(app.getByRole('spinbutton', { name: 'Menge' }), '7')
    await user.type(app.getByRole('searchbox'), 'Alpha')
    await user.click(app.getByRole('button', { name: 'Suchen' }))

    expect(await app.findByText(pickupSearchTotal)).toBeInTheDocument()
    await user.click(app.getByRole('button', { name: 'Als Favorit speichern' }))
    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(await app.findByText(pickupFavoriteTotal)).toBeInTheDocument()
  })

  it('restores a persisted favorite after an app reload without requiring a search', async () => {
    localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))
    const user = userEvent.setup()
    const app = within(render(<App />).container)

    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(await app.findByText('Muster-Apotheke A – Testdaten')).toBeInTheDocument()
    expect(app.getByText((_, element) =>
      element?.tagName === 'STRONG' && element.textContent === '6,49 € / g',
    )).toBeInTheDocument()
    expect(app.getByText((_, element) =>
      element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 g (Versand): 69,89 €',
    )).toBeInTheDocument()
    expect(app.getByText(/feed · zuletzt geprüft/)).toBeInTheDocument()
  })

  it('keeps favorite A visible after a later search returns only B', async () => {
    const user = userEvent.setup()
    const app = within(render(<App />).container)

    await user.type(app.getByRole('searchbox'), 'Alpha')
    await user.click(app.getByRole('button', { name: 'Suchen' }))
    const pharmacyA = await app.findByRole('heading', { name: 'Muster-Apotheke A – Testdaten' })
    await user.click(within(pharmacyA.closest('article')!).getByRole('button', { name: 'Als Favorit speichern' }))

    await user.clear(app.getByRole('searchbox'))
    await user.type(app.getByRole('searchbox'), 'Beta')
    await user.click(app.getByRole('button', { name: 'Suchen' }))
    expect(await app.findByText('Testextrakt Beta 10/10 · Testlabor Süd')).toBeInTheDocument()
    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(await app.findByRole('heading', { name: 'Muster-Apotheke A – Testdaten' })).toBeInTheDocument()
    expect(app.queryByText('Muster-Apotheke C – Testdaten')).not.toBeInTheDocument()
  })

  it('ignores an obsolete search callback after the search tab remounts', async () => {
    localStorage.setItem('weedpreis.favorites', JSON.stringify(['offer-a']))
    const first = deferred<Awaited<ReturnType<OffersRepository['search']>>>()
    const second = deferred<Awaited<ReturnType<OffersRepository['search']>>>()
    const search = vi.fn()
      .mockImplementationOnce(() => first.promise)
      .mockImplementationOnce(() => second.promise)
    const repository: OffersRepository = {
      search,
      async getByIds(ids) {
        return ids.map((id) => id === 'offer-a'
          ? { id, status: 'found', offer: syntheticOffers[0] }
          : { id, status: 'not-found' },
        )
      },
    }
    const user = userEvent.setup()
    const app = within(render(<App repository={repository} />).container)

    await user.clear(app.getByRole('spinbutton', { name: 'Menge' }))
    await user.type(app.getByRole('spinbutton', { name: 'Menge' }), '5')
    await user.click(app.getByRole('button', { name: 'Suchen' }))
    await user.click(app.getByRole('button', { name: 'Info' }))
    await user.click(app.getByRole('button', { name: 'Suche' }))
    await user.clear(app.getByRole('spinbutton', { name: 'Menge' }))
    await user.type(app.getByRole('spinbutton', { name: 'Menge' }), '7')
    await user.click(app.getByRole('button', { name: 'Suchen' }))

    expect(search).toHaveBeenCalledTimes(2)
    await act(async () => second.resolve([]))
    expect(await app.findByText('Keine passenden Angebote gefunden.')).toBeInTheDocument()
    await act(async () => first.resolve([]))
    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(await app.findByText((_, element) =>
      element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g (Versand): 50,42 €',
    )).toBeInTheDocument()
    expect(app.queryByText(/Gesamtpreis für 5 g/)).not.toBeInTheDocument()
  })
})
