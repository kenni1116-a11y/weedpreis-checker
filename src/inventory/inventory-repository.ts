import type { InventoryItem, ValidInventoryDraft } from './inventory'

export type InventoryRepository = {
  list(signal?: AbortSignal): Promise<InventoryItem[]>
  create(input: ValidInventoryDraft): Promise<InventoryItem>
  update(id: string, input: ValidInventoryDraft): Promise<InventoryItem>
  remove(id: string): Promise<void>
}
