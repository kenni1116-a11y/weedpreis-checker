import { cleanup, render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'
import { App } from './App'

const pickupTotal = (_: string, element: Element | null) =>
  element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g: 45,43 €'

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

    expect(await app.findByText(pickupTotal)).toBeInTheDocument()
    await user.click(app.getByRole('button', { name: 'Als Favorit speichern' }))
    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(await app.findByText(pickupTotal)).toBeInTheDocument()
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
      element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 10 g: 69,89 €',
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
})
