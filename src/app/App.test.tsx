import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { App } from './App'

describe('App', () => {
  it('identifies itself as a neutral pharmacy comparison', () => {
    render(<App />)
    expect(screen.getByRole('heading', { name: 'Weedpreis' })).toBeInTheDocument()
    expect(screen.getByText('Neutraler Apothekenvergleich')).toBeInTheDocument()
  })
})
