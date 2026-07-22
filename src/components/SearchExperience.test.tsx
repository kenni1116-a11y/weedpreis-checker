import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { beforeEach, expect, it } from 'vitest'
import { App } from '../app/App'

beforeEach(() => {
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
