import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { AppNavigation } from './AppNavigation'

it('exposes all three primary destinations', async () => {
  const onSelect = vi.fn()
  render(<AppNavigation active="search" onSelect={onSelect} />)

  expect(screen.getAllByRole('button').map((button) => button.textContent)).toEqual([
    'Suche',
    'Favoriten',
    'Info',
  ])

  await userEvent.click(screen.getByRole('button', { name: 'Info' }))

  expect(onSelect).toHaveBeenCalledWith('info')
})
