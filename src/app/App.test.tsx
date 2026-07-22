import { render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, describe, expect, it } from 'vitest'
import { App } from './App'

const pickupTotal = (_: string, element: Element | null) =>
  element?.tagName === 'P' && element.textContent === 'Gesamtpreis für 7 g: 45,43 €'

describe('App', () => {
  beforeEach(() => {
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
    await user.clear(app.getByRole('spinbutton', { name: 'Menge in Gramm' }))
    await user.type(app.getByRole('spinbutton', { name: 'Menge in Gramm' }), '7')
    await user.type(app.getByRole('searchbox'), 'Alpha')
    await user.click(app.getByRole('button', { name: 'Suchen' }))

    expect(await app.findByText(pickupTotal)).toBeInTheDocument()
    await user.click(app.getByRole('button', { name: 'Als Favorit speichern' }))
    await user.click(app.getByRole('button', { name: 'Favoriten' }))

    expect(app.getByText(pickupTotal)).toBeInTheDocument()
  })
})
