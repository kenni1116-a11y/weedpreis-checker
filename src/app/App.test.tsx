import { render, screen } from '@testing-library/react'
import { beforeEach, describe, expect, it } from 'vitest'
import { App } from './App'

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
})
