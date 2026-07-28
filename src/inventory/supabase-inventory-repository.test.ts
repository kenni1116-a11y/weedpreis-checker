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
  entry_name: 'Synthetic Alias',
  canonical_cultivar_id: reference.id,
  is_flower: true,
  origin_one_name: 'Parent One',
  origin_two_name: 'Parent Two',
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
  entryName: 'Synthetic Alias',
  entityId: reference.id,
  originOneName: 'Parent One',
  originTwoName: 'Parent Two',
  quantity: 3.5,
  unit: 'g',
  batch: null,
  expiresOn: '2027-02-28',
  storageLocation: 'Schrank',
  note: null,
}

function client(
  inventoryResult: QueryResult = { data: [itemRow], error: null },
) {
  const inventory = query(inventoryResult)
  const from = vi.fn(() => inventory)
  return { from, inventory }
}

describe('createSupabaseInventoryRepository', () => {
  it('lists matched inventory with an optional catalog reference', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await expect(repository.list()).resolves.toEqual([{
      id: itemRow.id,
      entryName: 'Synthetic Alias',
      reference: {
        id: reference.id,
        kind: 'cultivar',
        canonicalName: 'Test-Cultivar',
      },
      canonicalCultivarId: reference.id,
      isFlower: true,
      originOneName: 'Parent One',
      originTwoName: 'Parent Two',
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
        'catalog_references(id,kind,canonical_name)',
      ),
    )
  })

  it('maps a free entry without inventing canonical or flower data', async () => {
    const active = client({
      data: [{
        ...itemRow,
        entity_id: null,
        canonical_cultivar_id: null,
        is_flower: false,
        catalog_references: null,
      }],
      error: null,
    })
    const repository = createSupabaseInventoryRepository({ client: active })

    await expect(repository.list()).resolves.toEqual([
      expect.objectContaining({
        entryName: 'Synthetic Alias',
        reference: null,
        canonicalCultivarId: null,
        isFlower: false,
      }),
    ])
  })

  it('creates without sending user or server-derived fields', async () => {
    const active = client({ data: itemRow, error: null })
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await repository.create(draft)

    expect(active.inventory.insert).toHaveBeenCalledWith({
      entity_id: reference.id,
      entry_name: 'Synthetic Alias',
      origin_one_name: 'Parent One',
      origin_two_name: 'Parent Two',
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
    expect(active.inventory.insert.mock.calls[0]?.[0]).not.toHaveProperty(
      'canonical_cultivar_id',
    )
    expect(active.inventory.insert.mock.calls[0]?.[0]).not.toHaveProperty(
      'is_flower',
    )
  })

  it('updates and deletes only by item ID so RLS owns authorization', async () => {
    const active = client({ data: itemRow, error: null })
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
    const active = client({
        data: null,
        error: {
          code: '42501',
          message: 'new row violates row-level security policy',
        },
      })
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

  it('forwards live abort signals to list reads', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })
    const controller = new AbortController()

    await repository.list(controller.signal)

    expect(active.inventory.abortSignal).toHaveBeenCalledWith(
      controller.signal,
    )
  })

  it('never selects Auth email or consent metadata', async () => {
    const active = client()
    const repository = createSupabaseInventoryRepository({
      client: active,
    })

    await repository.list()

    const selectedColumns = active.inventory.select.mock.calls.flat().join(',')

    expect(selectedColumns).not.toMatch(
      /email|consent|privacy|terms|adult|user_id/i,
    )
  })
})
