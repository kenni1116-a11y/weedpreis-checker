import {
  cleanup,
  render,
  screen,
  waitFor,
} from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { InMemoryInventoryRepository } from '../../inventory/in-memory-inventory-repository'
import type {
  CatalogReference,
  InventoryItem,
} from '../../inventory/inventory'
import type { InventoryRepository } from '../../inventory/inventory-repository'
import { InventoryView } from './InventoryView'

const cultivar: CatalogReference = {
  id: '10000000-0000-4000-8000-000000000001',
  kind: 'cultivar',
  canonicalName: 'Test-Cultivar',
}

const product: CatalogReference = {
  id: '20000000-0000-4000-8000-000000000001',
  kind: 'product',
  canonicalName: 'Test-Produkt',
}

function item(overrides: Partial<InventoryItem> = {}): InventoryItem {
  return {
    id: '30000000-0000-4000-8000-000000000001',
    reference: cultivar,
    quantity: 2,
    unit: 'g',
    batch: null,
    expiresOn: null,
    storageLocation: null,
    note: null,
    createdAt: '2026-07-25T12:00:00.000Z',
    updatedAt: '2026-07-25T12:00:00.000Z',
    ...overrides,
  }
}

function repository(items: InventoryItem[] = []) {
  return new InMemoryInventoryRepository({
    references: [cultivar, product],
    items,
    createId: () => '40000000-0000-4000-8000-000000000001',
    now: () => new Date('2026-07-25T13:00:00.000Z'),
  })
}

async function openAddForm() {
  await screen.findByRole('heading', { name: 'Mein Bestand' })
  await userEvent.click(
    await screen.findByRole('button', { name: 'Eintrag hinzufügen' }),
  )
}

describe('InventoryView', () => {
  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  it('explains the private empty state', async () => {
    render(<InventoryView repository={repository()} />)

    expect(
      await screen.findByText('Noch kein Bestand gespeichert.'),
    ).toBeInTheDocument()
    expect(screen.getByText(
      'Deine Einträge sind privat und nur in deinem Konto sichtbar.',
    )).toBeInTheDocument()
  })

  it('requires only reference, quantity, and unit when adding', async () => {
    const active = repository()
    const create = vi.spyOn(active, 'create')
    render(<InventoryView repository={active} />)
    await openAddForm()

    expect(screen.getByLabelText('Sorte oder Produkt')).toBeRequired()
    expect(screen.getByLabelText('Menge')).toBeRequired()
    expect(screen.getByLabelText('Einheit')).toBeRequired()
    expect(screen.getByLabelText('Charge (optional)')).not.toBeRequired()
    expect(screen.getByLabelText('Ablaufdatum (optional)')).not.toBeRequired()
    expect(screen.getByLabelText('Lagerort (optional)')).not.toBeRequired()
    expect(screen.getByLabelText('Notiz (optional)')).not.toBeRequired()

    await userEvent.selectOptions(
      screen.getByLabelText('Sorte oder Produkt'),
      cultivar.id,
    )
    await userEvent.type(screen.getByLabelText('Menge'), '3.5')
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    expect(create).toHaveBeenCalledTimes(1)
    expect(await screen.findByRole(
      'heading',
      { name: 'Test-Cultivar' },
    )).toBeInTheDocument()
    expect(screen.getByText('3,5 g')).toBeInTheDocument()
  })

  it('validates fields before calling the repository', async () => {
    const active = repository()
    const create = vi.spyOn(active, 'create')
    render(<InventoryView repository={active} />)
    await openAddForm()

    await userEvent.selectOptions(
      screen.getByLabelText('Sorte oder Produkt'),
      cultivar.id,
    )
    await userEvent.type(screen.getByLabelText('Menge'), '0')
    await userEvent.click(screen.getByRole('button', { name: 'Speichern' }))

    const summary = screen.getByRole('alert')
    expect(summary).toHaveTextContent(
      'Die Menge muss größer als 0 und höchstens 100000 sein.',
    )
    expect(summary).toHaveFocus()
    expect(create).not.toHaveBeenCalled()
  })

  it('edits an existing item and updates the list after success', async () => {
    const active = repository([item()])
    render(<InventoryView repository={active} />)

    await userEvent.click(await screen.findByRole(
      'button',
      { name: 'Test-Cultivar bearbeiten' },
    ))
    const quantity = screen.getByLabelText('Menge')
    await userEvent.clear(quantity)
    await userEvent.type(quantity, '4')
    await userEvent.click(
      screen.getByRole('button', { name: 'Änderungen speichern' }),
    )

    expect(await screen.findByText('4 g')).toBeInTheDocument()
    expect(screen.queryByText('2 g')).not.toBeInTheDocument()
  })

  it('requires confirmation before deleting', async () => {
    const active = repository([item()])
    const remove = vi.spyOn(active, 'remove')
    render(<InventoryView repository={active} />)

    await userEvent.click(await screen.findByRole(
      'button',
      { name: 'Test-Cultivar löschen' },
    ))

    expect(screen.getByRole(
      'heading',
      { name: 'Eintrag wirklich löschen?' },
    )).toBeInTheDocument()
    expect(remove).not.toHaveBeenCalled()

    await userEvent.click(
      screen.getByRole('button', { name: 'Löschen bestätigen' }),
    )
    await waitFor(() => expect(remove).toHaveBeenCalledWith(item().id))
    expect(screen.queryByRole(
      'heading',
      { name: 'Test-Cultivar' },
    )).not.toBeInTheDocument()
  })

  it('preserves the previous list and announces write failures', async () => {
    const base = repository([item()])
    const failing: InventoryRepository = {
      references: (signal) => base.references(signal),
      list: (signal) => base.list(signal),
      create: (input) => base.create(input),
      update: vi.fn().mockRejectedValue(new Error(
        'Änderung konnte nicht gespeichert werden.',
      )),
      remove: (id) => base.remove(id),
    }
    render(<InventoryView repository={failing} />)

    await userEvent.click(await screen.findByRole(
      'button',
      { name: 'Test-Cultivar bearbeiten' },
    ))
    const quantity = screen.getByLabelText('Menge')
    await userEvent.clear(quantity)
    await userEvent.type(quantity, '9')
    await userEvent.click(
      screen.getByRole('button', { name: 'Änderungen speichern' }),
    )

    expect(await screen.findByRole('alert')).toHaveTextContent(
      'Änderung konnte nicht gespeichert werden.',
    )
    expect(screen.getByText('2 g')).toBeInTheDocument()
    expect(screen.queryByText('9 g')).not.toBeInTheDocument()
  })

  it('never asks for price, health, prescription, or consumption data', async () => {
    render(<InventoryView repository={repository()} />)
    await openAddForm()

    expect(screen.queryByLabelText(/preis/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/dosierung/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/konsum/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/diagnose/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/rezept/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/e-mail/i)).not.toBeInTheDocument()
    expect(screen.queryByLabelText(/wirkung/i)).not.toBeInTheDocument()
  })

  it('aborts stale reads when the view unmounts', async () => {
    let abortCount = 0
    const pendingRead = (signal?: AbortSignal) => new Promise<never>(
      (_resolve, reject) => {
        signal?.addEventListener('abort', () => {
          abortCount += 1
          reject(new DOMException('aborted', 'AbortError'))
        })
      },
    )
    const pending: InventoryRepository = {
      references: pendingRead,
      list: pendingRead,
      create: vi.fn(),
      update: vi.fn(),
      remove: vi.fn(),
    }

    const view = render(<InventoryView repository={pending} />)
    view.unmount()

    await waitFor(() => expect(abortCount).toBe(2))
  })
})
