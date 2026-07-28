import type {
  CatalogReference,
  InventoryItem,
  ValidInventoryDraft,
} from './inventory'
import type { InventoryRepository } from './inventory-repository'

type InMemoryInventoryOptions = {
  references?: CatalogReference[]
  items?: InventoryItem[]
  createId?: () => string
  now?: () => Date
}

function cloneReference(reference: CatalogReference): CatalogReference {
  return { ...reference }
}

function cloneItem(item: InventoryItem): InventoryItem {
  return {
    ...item,
    reference: cloneReference(item.reference),
  }
}

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

async function cancellableTurn(signal?: AbortSignal): Promise<void> {
  if (signal?.aborted) throw abortError()
  await Promise.resolve()
  if (signal?.aborted) throw abortError()
}

export class InMemoryInventoryRepository implements InventoryRepository {
  readonly #references: CatalogReference[]
  readonly #createId: () => string
  readonly #now: () => Date
  #items: InventoryItem[]

  constructor(options: InMemoryInventoryOptions = {}) {
    this.#references = (options.references ?? []).map(cloneReference)
    this.#items = (options.items ?? []).map(cloneItem)
    this.#createId = options.createId ?? (() => crypto.randomUUID())
    this.#now = options.now ?? (() => new Date())
  }

  async references(signal?: AbortSignal): Promise<CatalogReference[]> {
    await cancellableTurn(signal)
    return this.#references.map(cloneReference)
  }

  async list(signal?: AbortSignal): Promise<InventoryItem[]> {
    await cancellableTurn(signal)
    return this.#items.map(cloneItem)
  }

  async create(input: ValidInventoryDraft): Promise<InventoryItem> {
    const reference = this.#reference(input.entityId)
    const timestamp = this.#now().toISOString()
    const item: InventoryItem = {
      id: this.#createId(),
      reference,
      quantity: input.quantity,
      unit: input.unit,
      batch: input.batch,
      expiresOn: input.expiresOn,
      storageLocation: input.storageLocation,
      note: input.note,
      createdAt: timestamp,
      updatedAt: timestamp,
    }
    this.#items = [item, ...this.#items]
    return cloneItem(item)
  }

  async update(
    id: string,
    input: ValidInventoryDraft,
  ): Promise<InventoryItem> {
    const current = this.#items.find((item) => item.id === id)
    if (!current) throw new Error('Bestandseintrag wurde nicht gefunden.')
    const updated: InventoryItem = {
      ...current,
      reference: this.#reference(input.entityId),
      quantity: input.quantity,
      unit: input.unit,
      batch: input.batch,
      expiresOn: input.expiresOn,
      storageLocation: input.storageLocation,
      note: input.note,
      updatedAt: this.#now().toISOString(),
    }
    this.#items = this.#items.map((item) => (
      item.id === id ? updated : item
    ))
    return cloneItem(updated)
  }

  async remove(id: string): Promise<void> {
    if (!this.#items.some((item) => item.id === id)) {
      throw new Error('Bestandseintrag wurde nicht gefunden.')
    }
    this.#items = this.#items.filter((item) => item.id !== id)
  }

  #reference(id: string): CatalogReference {
    const reference = this.#references.find((candidate) => candidate.id === id)
    if (!reference) throw new Error('Katalogreferenz wurde nicht gefunden.')
    return cloneReference(reference)
  }
}
