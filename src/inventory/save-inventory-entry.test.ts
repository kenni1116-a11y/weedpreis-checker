import { describe, expect, it, vi } from 'vitest'
import type { CommunityRepository } from '../community/community-repository'
import type {
  OwnCommunityContribution,
  ValidCommunityContribution,
} from '../community/community-values'
import type {
  InventoryItem,
  ValidInventoryDraft,
} from './inventory'
import type { InventoryRepository } from './inventory-repository'
import {
  retryCommunityMutation,
  saveInventoryEntry,
} from './save-inventory-entry'

const cultivarId = '51000000-0000-4000-8000-000000000001'
const secondCultivarId = '51000000-0000-4000-8000-000000000002'
const itemId = '52000000-0000-4000-8000-000000000001'

const draft: ValidInventoryDraft = {
  entryName: 'Synthetic Alias',
  entityId: cultivarId,
  originOneName: 'Parent One',
  originTwoName: 'Parent Two',
  quantity: 3.5,
  unit: 'g',
  batch: null,
  expiresOn: null,
  storageLocation: null,
  note: null,
}

function item(
  overrides: Partial<InventoryItem> = {},
): InventoryItem {
  return {
    id: itemId,
    entryName: 'Synthetic Alias',
    reference: {
      id: cultivarId,
      kind: 'cultivar',
      canonicalName: 'Synthetic Cultivar',
    },
    canonicalCultivarId: cultivarId,
    isFlower: true,
    originOneName: 'Parent One',
    originTwoName: 'Parent Two',
    quantity: 3.5,
    unit: 'g',
    batch: null,
    expiresOn: null,
    storageLocation: null,
    note: null,
    createdAt: '2026-07-28T12:00:00.000Z',
    updatedAt: '2026-07-28T12:00:00.000Z',
    ...overrides,
  }
}

const contribution: ValidCommunityContribution = {
  cultivarId,
  thcPercent: 21.3,
  cbdPercent: 0.7,
  sourceKind: 'label',
  consentVersion: 'weedypedia-community-values-2026-07-28',
  declarationAccepted: true,
  optIn: true,
}

function own(
  input: ValidCommunityContribution = contribution,
): OwnCommunityContribution {
  return {
    cultivarId: input.cultivarId,
    thcPercent: input.thcPercent,
    cbdPercent: input.cbdPercent,
    sourceKind: input.sourceKind,
    consentVersion: input.consentVersion,
    updatedAt: '2026-07-28T12:01:00.000Z',
  }
}

function dependencies(savedItem = item()) {
  const inventory: InventoryRepository = {
    list: vi.fn().mockResolvedValue([]),
    create: vi.fn().mockResolvedValue(savedItem),
    update: vi.fn().mockResolvedValue(savedItem),
    remove: vi.fn().mockResolvedValue(undefined),
  }
  const community: CommunityRepository = {
    getOwn: vi.fn().mockResolvedValue(null),
    getPublished: vi.fn().mockResolvedValue(null),
    upsert: vi.fn().mockResolvedValue(own()),
    remove: vi.fn().mockResolvedValue(undefined),
  }
  return { inventory, community }
}

describe('saveInventoryEntry', () => {
  it('never mutates community data when inventory saving fails', async () => {
    const active = dependencies()
    vi.mocked(active.inventory.create).mockRejectedValue(
      new Error('inventory failed'),
    )

    await expect(
      saveInventoryEntry({
        draft,
        communityMutation: { kind: 'upsert', input: contribution },
        inventoryRepository: active.inventory,
        communityRepository: active.community,
      }),
    ).rejects.toThrow('inventory failed')
    expect(active.community.upsert).not.toHaveBeenCalled()
    expect(active.community.remove).not.toHaveBeenCalled()
  })

  it.each([
    item({
      reference: null,
      canonicalCultivarId: null,
      isFlower: false,
    }),
    item({ isFlower: false }),
  ])('does not call community RPCs for free or non-flower rows', async (saved) => {
    const active = dependencies(saved)

    await expect(
      saveInventoryEntry({
        draft,
        communityMutation: { kind: 'upsert', input: contribution },
        inventoryRepository: active.inventory,
        communityRepository: active.community,
      }),
    ).resolves.toMatchObject({
      kind: 'saved',
      community: 'unchanged',
    })
    expect(active.community.upsert).not.toHaveBeenCalled()
    expect(active.community.remove).not.toHaveBeenCalled()
  })

  it('saves inventory first and then one eligible contribution', async () => {
    const active = dependencies()
    const order: string[] = []
    vi.mocked(active.inventory.create).mockImplementation(async () => {
      order.push('inventory')
      return item()
    })
    vi.mocked(active.community.upsert).mockImplementation(async () => {
      order.push('community')
      return own()
    })

    await expect(
      saveInventoryEntry({
        draft,
        communityMutation: { kind: 'upsert', input: contribution },
        inventoryRepository: active.inventory,
        communityRepository: active.community,
      }),
    ).resolves.toMatchObject({
      kind: 'saved',
      community: 'saved',
    })
    expect(order).toEqual(['inventory', 'community'])
  })

  it('saves an edit before explicitly removing opt-in', async () => {
    const active = dependencies()

    await expect(
      saveInventoryEntry({
        itemId,
        draft,
        communityMutation: { kind: 'remove', cultivarId },
        inventoryRepository: active.inventory,
        communityRepository: active.community,
      }),
    ).resolves.toMatchObject({
      kind: 'saved',
      community: 'removed',
    })
    expect(active.inventory.update).toHaveBeenCalledWith(itemId, draft)
    expect(active.community.remove).toHaveBeenCalledWith(cultivarId)
  })

  it('returns partial success and retry touches only community state', async () => {
    const active = dependencies()
    vi.mocked(active.community.upsert)
      .mockRejectedValueOnce(new Error('community failed'))
      .mockResolvedValueOnce(own())

    const outcome = await saveInventoryEntry({
      draft,
      communityMutation: { kind: 'upsert', input: contribution },
      inventoryRepository: active.inventory,
      communityRepository: active.community,
    })

    expect(outcome).toEqual({
      kind: 'inventory_saved_community_failed',
      item: item(),
      pendingCommunityMutation: {
        kind: 'upsert',
        input: contribution,
      },
    })
    if (outcome.kind !== 'inventory_saved_community_failed') {
      throw new Error('expected partial success')
    }

    await retryCommunityMutation(
      outcome.pendingCommunityMutation,
      active.community,
    )
    expect(active.inventory.create).toHaveBeenCalledTimes(1)
    expect(active.inventory.update).not.toHaveBeenCalled()
    expect(active.community.upsert).toHaveBeenCalledTimes(2)
  })

  it('never submits a contribution for the prior cultivar after a switch', async () => {
    const switched = item({
      canonicalCultivarId: secondCultivarId,
      reference: {
        id: secondCultivarId,
        kind: 'cultivar',
        canonicalName: 'Second Cultivar',
      },
    })
    const active = dependencies(switched)

    await saveInventoryEntry({
      itemId,
      draft: { ...draft, entityId: secondCultivarId },
      communityMutation: {
        kind: 'upsert',
        input: { ...contribution, cultivarId: secondCultivarId },
      },
      inventoryRepository: active.inventory,
      communityRepository: active.community,
    })

    expect(active.community.upsert).toHaveBeenCalledTimes(1)
    expect(active.community.upsert).toHaveBeenCalledWith(
      expect.objectContaining({ cultivarId: secondCultivarId }),
    )
    expect(active.community.remove).not.toHaveBeenCalled()
  })
})
