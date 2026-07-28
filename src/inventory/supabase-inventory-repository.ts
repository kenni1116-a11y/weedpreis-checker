import type {
  CatalogReference,
  InventoryItem,
  ValidInventoryDraft,
} from './inventory'
import type { InventoryRepository } from './inventory-repository'

type ServiceError = {
  code?: string
  message: string
} | null

type QueryResult = {
  data: unknown
  error: ServiceError
}

type QueryPort = {
  select(columns: string): QueryPort
  insert(values: Record<string, unknown>): QueryPort
  update(values: Record<string, unknown>): QueryPort
  delete(): QueryPort
  eq(column: string, value: unknown): QueryPort
  order(
    column: string,
    options?: { ascending?: boolean },
  ): QueryPort
  abortSignal(signal: AbortSignal): QueryPort
  single(): Promise<QueryResult>
}

export type SupabaseInventoryClientPort = {
  from(table: string): QueryPort
}

type CatalogReferenceRow = {
  id: string
  kind: 'cultivar' | 'product'
  canonical_name: string
}

type InventoryRow = {
  id: string
  entity_id: string | null
  entry_name: string
  canonical_cultivar_id: string | null
  is_flower: boolean
  origin_one_name: string | null
  origin_two_name: string | null
  quantity: number | string
  unit: 'g' | 'ml' | 'piece'
  batch: string | null
  expires_on: string | null
  storage_location: string | null
  note: string | null
  created_at: string
  updated_at: string
  catalog_references:
    | CatalogReferenceRow
    | CatalogReferenceRow[]
    | null
}

type InventoryErrorCode =
  | 'INVENTORY_FORBIDDEN'
  | 'INVENTORY_UNAVAILABLE'

export class InventoryRepositoryError extends Error {
  readonly code: InventoryErrorCode

  constructor(code: InventoryErrorCode) {
    super(
      code === 'INVENTORY_FORBIDDEN'
        ? 'Der private Bestand ist für diese Sitzung nicht freigegeben.'
        : 'Der private Bestand ist derzeit nicht verfügbar.',
    )
    this.name = 'InventoryRepositoryError'
    this.code = code
  }
}

const itemColumns = [
  'id',
  'entity_id',
  'entry_name',
  'canonical_cultivar_id',
  'is_flower',
  'origin_one_name',
  'origin_two_name',
  'quantity',
  'unit',
  'batch',
  'expires_on',
  'storage_location',
  'note',
  'created_at',
  'updated_at',
  'catalog_references(id,kind,canonical_name)',
].join(',')

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) throw abortError()
}

function mapError(error: Exclude<ServiceError, null>): never {
  const permissionDenied =
    error.code === '42501'
    || error.code === '403'
    || /row-level security|permission|forbidden/i.test(error.message)

  throw new InventoryRepositoryError(
    permissionDenied ? 'INVENTORY_FORBIDDEN' : 'INVENTORY_UNAVAILABLE',
  )
}

async function executeQuery(query: QueryPort): Promise<QueryResult> {
  return query as unknown as Promise<QueryResult>
}

function mapReference(row: CatalogReferenceRow): CatalogReference {
  return {
    id: row.id,
    kind: row.kind,
    canonicalName: row.canonical_name,
  }
}

function joinedReference(row: InventoryRow): CatalogReferenceRow | null {
  const reference = Array.isArray(row.catalog_references)
    ? row.catalog_references[0]
    : row.catalog_references
  return reference ?? null
}

function mapItem(row: InventoryRow): InventoryItem {
  const reference = joinedReference(row)
  return {
    id: row.id,
    entryName: row.entry_name,
    reference: reference ? mapReference(reference) : null,
    canonicalCultivarId: row.canonical_cultivar_id,
    isFlower: row.is_flower,
    originOneName: row.origin_one_name,
    originTwoName: row.origin_two_name,
    quantity: Number(row.quantity),
    unit: row.unit,
    batch: row.batch,
    expiresOn: row.expires_on,
    storageLocation: row.storage_location,
    note: row.note,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  }
}

function insertValues(
  input: ValidInventoryDraft,
): Record<string, unknown> {
  return {
    entity_id: input.entityId,
    entry_name: input.entryName,
    origin_one_name: input.originOneName,
    origin_two_name: input.originTwoName,
    quantity: input.quantity,
    unit: input.unit,
    batch: input.batch,
    expires_on: input.expiresOn,
    storage_location: input.storageLocation,
    note: input.note,
  }
}

class SupabaseInventoryRepository implements InventoryRepository {
  readonly #client: SupabaseInventoryClientPort

  constructor(client: SupabaseInventoryClientPort) {
    this.#client = client
  }

  async references(signal?: AbortSignal): Promise<CatalogReference[]> {
    throwIfAborted(signal)
    let query = this.#client
      .from('catalog_references')
      .select('id,kind,canonical_name')
      .order('canonical_name', { ascending: true })
    if (signal) query = query.abortSignal(signal)

    const result = await executeQuery(query)
    throwIfAborted(signal)
    if (result.error) mapError(result.error)
    return (result.data as CatalogReferenceRow[]).map(mapReference)
  }

  async list(signal?: AbortSignal): Promise<InventoryItem[]> {
    throwIfAborted(signal)
    let query = this.#client
      .from('inventory_items')
      .select(itemColumns)
      .order('updated_at', { ascending: false })
    if (signal) query = query.abortSignal(signal)

    const result = await executeQuery(query)
    throwIfAborted(signal)
    if (result.error) mapError(result.error)
    return (result.data as InventoryRow[]).map(mapItem)
  }

  async create(input: ValidInventoryDraft): Promise<InventoryItem> {
    const result = await this.#client
      .from('inventory_items')
      .insert(insertValues(input))
      .select(itemColumns)
      .single()
    if (result.error) mapError(result.error)
    return mapItem(result.data as InventoryRow)
  }

  async update(
    id: string,
    input: ValidInventoryDraft,
  ): Promise<InventoryItem> {
    const result = await this.#client
      .from('inventory_items')
      .update(insertValues(input))
      .eq('id', id)
      .select(itemColumns)
      .single()
    if (result.error) mapError(result.error)
    return mapItem(result.data as InventoryRow)
  }

  async remove(id: string): Promise<void> {
    const query = this.#client
      .from('inventory_items')
      .delete()
      .eq('id', id)
    const result = await executeQuery(query)
    if (result.error) mapError(result.error)
  }
}

export function createSupabaseInventoryRepository(options: {
  client: SupabaseInventoryClientPort
}): InventoryRepository {
  return new SupabaseInventoryRepository(options.client)
}
