import type {
  CatalogReference,
  InventoryItem,
  ValidInventoryDraft,
} from './inventory'
import type { InventoryRepository } from './inventory-repository'

type InMemoryReference = CatalogReference & {
  canonicalCultivarId?: string | null
  isFlower?: boolean
}

type InMemoryInventoryOptions = {
  references?: InMemoryReference[]
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
    reference: item.reference ? cloneReference(item.reference) : null,
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
  readonly #references: InMemoryReference[]
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
    const mapping = this.#mapping(input.entityId)
    const timestamp = this.#now().toISOString()
    const item: InventoryItem = {
      id: this.#createId(),
      entryName: input.entryName,
      reference: mapping.reference,
      canonicalCultivarId: mapping.canonicalCultivarId,
      isFlower: mapping.isFlower,
      originOneName: input.originOneName,
      originTwoName: input.originTwoName,
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
      entryName: input.entryName,
      ...this.#mapping(input.entityId),
      originOneName: input.originOneName,
      originTwoName: input.originTwoName,
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

  #mapping(id: string | null): {
    reference: CatalogReference | null
    canonicalCultivarId: string | null
    isFlower: boolean
  } {
    if (id === null) {
      return {
        reference: null,
        canonicalCultivarId: null,
        isFlower: false,
      }
    }

    const reference = this.#references.find((candidate) => candidate.id === id)
    if (!reference) throw new Error('Katalogreferenz wurde nicht gefunden.')
    return {
      reference: cloneReference(reference),
      canonicalCultivarId:
        reference.canonicalCultivarId
        ?? (reference.kind === 'cultivar' ? reference.id : null),
      isFlower: reference.isFlower ?? reference.kind === 'cultivar',
    }
  }
}
