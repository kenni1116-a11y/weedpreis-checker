import { describe, expect, it, vi } from 'vitest'
import { createSupabaseInventoryRepository } from './supabase-inventory-repository'
import type { ValidInventoryDraft } from './inventory'

type QueryResult = {
  data: unknown
  error: null | { code?: string; message: string }
}

function query(result: QueryResult) {
  const promise = Promise.resolve(result)
  const builder = {
    select: vi.fn(),
    insert: vi.fn(),
    update: vi.fn(),
    delete: vi.fn(),
    eq: vi.fn(),
    order: vi.fn(),
    abortSignal: vi.fn(),
    single: vi.fn(() => promise),
    then: promise.then.bind(promise),
  }

  builder.select.mockReturnValue(builder)
  builder.insert.mockReturnValue(builder)
  builder.update.mockReturnValue(builder)
  builder.delete.mockReturnValue(builder)
  builder.eq.mockReturnValue(builder)
  builder.order.mockReturnValue(builder)
  builder.abortSignal.mockReturnValue(builder)
  return builder
}

const reference = {
  id: '10000000-0000-4000-8000-000000000001',
  kind: 'cultivar',
  canonical_name: 'Test-Cultivar',
}

const itemRow = {
  id: '20000000-0000-4000-8000-000000000001',
  entity_id: reference.id,
  quantity: '3.500',
  unit: 'g',
  batch: null,
  expires_on: '2027-02-28',
  storage_location: 'Schrank',
  note: null,
  created_at: '2026-07-25T12:00:00.000Z',
  updated_at: '2026-07-25T12:00:00.000Z',
  catalog_references: reference,
}

const draft: ValidInventoryDraft = {
  entityId: reference.id,
  quantity: 3.5,
  unit: 'g',
  batch: null,
  expiresOn: '2027-02-28',
  storageLocation: 'Schrank',
  note: null,
}

function client(
  referenceResult: QueryResult = { data: [reference], error: null },
  inventoryResult: QueryResult = { data: [itemRow], error: null },
) {
  const references = query(referenceResult)
  const inventory = query(inventoryResult)
  const from = vi.fn((table: string) => (
    table === 'catalog_references' ? references : inventory
  ))
  return { from, references, inventory }
}

describe('createSupabaseInventoryRepository', () => {
  it('reads references only from the API catalog projection', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await expect(repository.references()).resolves.toEqual([{
      id: reference.id,
      kind: 'cultivar',
      canonicalName: 'Test-Cultivar',
    }])

    expect(active.from).toHaveBeenCalledWith('catalog_references')
    expect(active.references.select).toHaveBeenCalledWith(
      'id,kind,canonical_name',
    )
  })

  it('lists inventory joined only with its canonical reference', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await expect(repository.list()).resolves.toEqual([{
      id: itemRow.id,
      reference: {
        id: reference.id,
        kind: 'cultivar',
        canonicalName: 'Test-Cultivar',
      },
      quantity: 3.5,
      unit: 'g',
      batch: null,
      expiresOn: '2027-02-28',
      storageLocation: 'Schrank',
      note: null,
      createdAt: '2026-07-25T12:00:00.000Z',
      updatedAt: '2026-07-25T12:00:00.000Z',
    }])

    expect(active.inventory.select).toHaveBeenCalledWith(
      expect.stringContaining(
        'catalog_references!inner(id,kind,canonical_name)',
      ),
    )
  })

  it('creates without accepting or sending a user ID', async () => {
    const active = client(
      { data: [reference], error: null },
      { data: itemRow, error: null },
    )
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await repository.create(draft)

    expect(active.inventory.insert).toHaveBeenCalledWith({
      entity_id: reference.id,
      quantity: 3.5,
      unit: 'g',
      batch: null,
      expires_on: '2027-02-28',
      storage_location: 'Schrank',
      note: null,
    })
    expect(active.inventory.insert.mock.calls[0]?.[0]).not.toHaveProperty(
      'user_id',
    )
  })

  it('updates and deletes only by item ID so RLS owns authorization', async () => {
    const active = client(
      { data: [reference], error: null },
      { data: itemRow, error: null },
    )
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await repository.update(itemRow.id, draft)
    await repository.remove(itemRow.id)

    expect(active.inventory.update).toHaveBeenCalledTimes(1)
    expect(active.inventory.eq).toHaveBeenCalledWith('id', itemRow.id)
    expect(active.inventory.delete).toHaveBeenCalledTimes(1)
    expect(active.inventory.eq).not.toHaveBeenCalledWith(
      'user_id',
      expect.anything(),
    )
  })

  it('maps permission errors to INVENTORY_FORBIDDEN', async () => {
    const active = client(
      { data: [], error: null },
      {
        data: null,
        error: {
          code: '42501',
          message: 'new row violates row-level security policy',
        },
      },
    )
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await expect(repository.create(draft)).rejects.toMatchObject({
      code: 'INVENTORY_FORBIDDEN',
    })
  })

  it('rejects reads that were already aborted', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })
    const controller = new AbortController()
    controller.abort()

    await expect(repository.list(controller.signal)).rejects.toMatchObject({
      name: 'AbortError',
    })
    expect(active.from).not.toHaveBeenCalled()
  })

  it('forwards live abort signals to both read queries', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })
    const controller = new AbortController()

    await repository.references(controller.signal)
    await repository.list(controller.signal)

    expect(active.references.abortSignal).toHaveBeenCalledWith(
      controller.signal,
    )
    expect(active.inventory.abortSignal).toHaveBeenCalledWith(
      controller.signal,
    )
  })

  it('never selects Auth email or consent metadata', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await repository.references()
    await repository.list()

    const selectedColumns = [
      ...active.references.select.mock.calls,
      ...active.inventory.select.mock.calls,
    ].flat().join(',')

    expect(selectedColumns).not.toMatch(
      /email|consent|privacy|terms|adult|user_id/i,
    )
  })
})
