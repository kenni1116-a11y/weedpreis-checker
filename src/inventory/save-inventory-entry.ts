import type { CommunityRepository } from '../community/community-repository'
import type { ValidCommunityContribution } from '../community/community-values'
import type {
  InventoryItem,
  ValidInventoryDraft,
} from './inventory'
import type { InventoryRepository } from './inventory-repository'

export type PendingCommunityMutation =
  | { kind: 'upsert'; input: ValidCommunityContribution }
  | { kind: 'remove'; cultivarId: string }

export type SaveInventoryOutcome =
  | {
      kind: 'saved'
      item: InventoryItem
      community: 'unchanged' | 'saved' | 'removed'
    }
  | {
      kind: 'inventory_saved_community_failed'
      item: InventoryItem
      pendingCommunityMutation: PendingCommunityMutation
    }

type SaveInventoryEntryInput = {
  itemId?: string
  draft: ValidInventoryDraft
  communityMutation?: PendingCommunityMutation | null
  inventoryRepository: InventoryRepository
  communityRepository: CommunityRepository
}

function mutationMatchesSavedItem(
  item: InventoryItem,
  mutation: PendingCommunityMutation,
): boolean {
  const cultivarId = mutation.kind === 'upsert'
    ? mutation.input.cultivarId
    : mutation.cultivarId
  return (
    item.isFlower
    && item.canonicalCultivarId !== null
    && item.canonicalCultivarId === cultivarId
  )
}

export async function retryCommunityMutation(
  mutation: PendingCommunityMutation,
  repository: CommunityRepository,
): Promise<void> {
  if (mutation.kind === 'upsert') {
    await repository.upsert(mutation.input)
    return
  }
  await repository.remove(mutation.cultivarId)
}

export async function saveInventoryEntry({
  itemId,
  draft,
  communityMutation,
  inventoryRepository,
  communityRepository,
}: SaveInventoryEntryInput): Promise<SaveInventoryOutcome> {
  const item = itemId
    ? await inventoryRepository.update(itemId, draft)
    : await inventoryRepository.create(draft)

  if (
    !communityMutation
    || !mutationMatchesSavedItem(item, communityMutation)
  ) {
    return {
      kind: 'saved',
      item,
      community: 'unchanged',
    }
  }

  try {
    await retryCommunityMutation(communityMutation, communityRepository)
    return {
      kind: 'saved',
      item,
      community: communityMutation.kind === 'upsert' ? 'saved' : 'removed',
    }
  } catch {
    return {
      kind: 'inventory_saved_community_failed',
      item,
      pendingCommunityMutation: communityMutation,
    }
  }
}
