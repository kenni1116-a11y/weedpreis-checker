import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, expect, it, vi } from 'vitest'
import { AppNavigation } from './AppNavigation'

afterEach(() => cleanup())

it('exposes all four Weedypedia destinations', async () => {
  const onSelect = vi.fn()
  render(<AppNavigation active="discover" onSelect={onSelect} />)

  expect(
    screen.getAllByRole('button').map((button) => button.textContent),
  ).toEqual([
    'Entdecken',
    'Suche',
    'Bestand',
    'Profil',
  ])

  expect(screen.getByRole(
    'button',
    { name: 'Entdecken' },
  )).toHaveAttribute('aria-current', 'page')

  await userEvent.click(screen.getByRole('button', { name: 'Bestand' }))

  expect(onSelect).toHaveBeenCalledWith('inventory')
})
