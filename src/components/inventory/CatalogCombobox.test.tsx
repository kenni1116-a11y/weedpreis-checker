import { act, cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useState } from 'react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { CatalogRepository } from '../../catalog/catalog-repository'
import type { CatalogSearchMatch } from '../../catalog/catalog-search'
import { CatalogCombobox } from './CatalogCombobox'

const aliasMatch: CatalogSearchMatch = {
  id: '51000000-0000-4000-8000-000000000001',
  kind: 'cultivar',
  canonicalName: 'Synthetic Cultivar',
  matchedName: 'Synthetic Alias',
  matchReason: 'alias',
  canonicalCultivarId: '51000000-0000-4000-8000-000000000001',
  isFlower: true,
  preferredParents: ['Parent One', 'Parent Two'],
  hasAdditionalLineage: true,
  sourcedThcLabel: '21,3 %',
  sourcedCbdLabel: '0,7 %',
  sourcedValueEvidence: [],
}

const productMatch: CatalogSearchMatch = {
  ...aliasMatch,
  id: '51000000-0000-4000-8000-000000000002',
  kind: 'product',
  canonicalName: 'Synthetic Product 22/1',
  matchedName: 'Synthetic Product',
  matchReason: 'product',
}

async function waitForDebounce() {
  await act(async () => {
    await new Promise((resolve) => window.setTimeout(resolve, 220))
  })
}

function controlled(repository: CatalogRepository) {
  function Wrapper() {
    const [value, setValue] = useState('')
    const [selected, setSelected] =
      useState<CatalogSearchMatch | null>(null)
    return (
      <CatalogCombobox
        value={value}
        selectedMatch={selected}
        repository={repository}
        onChange={(nextValue, nextMatch) => {
          setValue(nextValue)
          setSelected(nextMatch)
        }}
      />
    )
  }
  return render(<Wrapper />)
}

describe('CatalogCombobox', () => {
  afterEach(() => {
    cleanup()
  })

  it('is an editable labelled ARIA combobox rather than a select', () => {
    controlled({ search: vi.fn().mockResolvedValue([]) })

    const input = screen.getByRole('combobox', {
      name: 'Sorte oder Produkt',
    })
    expect(input).toHaveAttribute('aria-expanded', 'false')
    expect(input.tagName).toBe('INPUT')
    expect(screen.queryByRole('option')).not.toBeInTheDocument()
  })

  it('debounces two characters and aborts a stale request', async () => {
    const signals: AbortSignal[] = []
    const repository: CatalogRepository = {
      search: vi.fn((_query, signal): Promise<CatalogSearchMatch[]> => {
        if (signal) signals.push(signal)
        return new Promise<CatalogSearchMatch[]>(() => undefined)
      }),
    }
    controlled(repository)
    const user = userEvent.setup()
    const input = screen.getByRole('combobox')

    await user.type(input, 'S')
    await waitForDebounce()
    expect(repository.search).not.toHaveBeenCalled()
    await user.type(input, 'y')
    expect(repository.search).not.toHaveBeenCalled()
    await waitForDebounce()
    expect(repository.search).toHaveBeenCalledTimes(1)

    await user.type(input, 'n')
    await waitForDebounce()
    expect(repository.search).toHaveBeenCalledTimes(2)
    expect(signals[0]?.aborted).toBe(true)
  })

  it('states match reasons and supports keyboard selection', async () => {
    const repository: CatalogRepository = {
      search: vi.fn().mockResolvedValue([aliasMatch, productMatch]),
    }
    controlled(repository)
    const user = userEvent.setup()
    const input = screen.getByRole('combobox')

    await user.type(input, 'Synthetic')
    await waitForDebounce()
    expect(await screen.findByText('Alias')).toBeInTheDocument()
    expect(screen.getByText('Produkt')).toBeInTheDocument()
    expect(screen.queryByText(/community|mittelwert/i)).not.toBeInTheDocument()

    await user.keyboard('{ArrowDown}{Enter}')

    expect(input).toHaveValue('Synthetic Alias')
    expect(screen.getByText(
      'Kanonischer Vorschlag: Synthetic Cultivar',
    )).toBeInTheDocument()
  })

  it('supports touch selection and clears a stale match after editing', async () => {
    const repository: CatalogRepository = {
      search: vi.fn().mockResolvedValue([productMatch]),
    }
    controlled(repository)
    const user = userEvent.setup()
    const input = screen.getByRole('combobox')

    await user.type(input, 'Synthetic')
    await waitForDebounce()
    await user.click(await screen.findByRole('option'))
    expect(input).toHaveValue('Synthetic Product')
    expect(screen.getByText(
      'Kanonischer Vorschlag: Synthetic Product 22/1',
    )).toBeInTheDocument()

    await user.type(input, ' privat')
    expect(screen.queryByText(/Kanonischer Vorschlag/)).not.toBeInTheDocument()
  })

  it('announces empty and failed searches and closes results with Escape', async () => {
    const search = vi
      .fn()
      .mockResolvedValueOnce([])
      .mockResolvedValueOnce([aliasMatch])
      .mockRejectedValueOnce(new Error('failed'))
    controlled({ search })
    const user = userEvent.setup()
    const input = screen.getByRole('combobox')

    await user.type(input, 'none')
    await waitForDebounce()
    expect(await screen.findByRole('status')).toHaveTextContent(
      'Kein Katalogtreffer. Der Name kann privat gespeichert werden.',
    )

    await user.clear(input)
    await user.type(input, 'alias')
    await waitForDebounce()
    expect(await screen.findByRole('option')).toBeInTheDocument()
    await user.keyboard('{Escape}')
    expect(screen.queryByRole('option')).not.toBeInTheDocument()

    await user.clear(input)
    await user.type(input, 'error')
    await waitForDebounce()
    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Die Bestandssuche ist derzeit nicht verfügbar.',
    )
  })
})
