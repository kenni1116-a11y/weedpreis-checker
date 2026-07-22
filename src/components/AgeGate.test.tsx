import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { expect, it, vi } from 'vitest'
import { AgeGate } from './AgeGate'

it('requires explicit adult confirmation', async () => {
  const onConfirm = vi.fn()
  render(<AgeGate onConfirm={onConfirm} />)

  await userEvent.click(screen.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }))

  expect(onConfirm).toHaveBeenCalledOnce()
})
