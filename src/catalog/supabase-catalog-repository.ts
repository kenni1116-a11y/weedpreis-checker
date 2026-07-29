import {
  mapCatalogSearchRow,
  type CatalogSearchMatch,
} from './catalog-search'
import type { CatalogRepository } from './catalog-repository'

type ServiceError = {
  code?: string
  message: string
} | null

type RpcResult = {
  data: unknown
  error: ServiceError
}

type RpcQueryPort = PromiseLike<RpcResult> & {
  abortSignal(signal: AbortSignal): RpcQueryPort
}

export type SupabaseCatalogClientPort = {
  rpc(
    name: string,
    values: Record<string, unknown>,
  ): RpcQueryPort
}

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) throw abortError()
}

function visibleLength(value: string): number {
  return Array.from(value).length
}

class SupabaseCatalogRepository implements CatalogRepository {
  readonly #client: SupabaseCatalogClientPort

  constructor(client: SupabaseCatalogClientPort) {
    this.#client = client
  }

  async search(
    input: string,
    signal?: AbortSignal,
  ): Promise<CatalogSearchMatch[]> {
    throwIfAborted(signal)
    const query = input.trim()
    if (visibleLength(query) < 2) return []

    let request = this.#client.rpc('search_catalog_references', {
      p_query: query,
    })
    if (signal) request = request.abortSignal(signal)

    const result = await request
    throwIfAborted(signal)
    if (result.error) {
      throw new Error('Die Bestandssuche ist derzeit nicht verfügbar.')
    }
    if (!Array.isArray(result.data)) {
      throw new Error('Invalid catalog search response')
    }
    return result.data.map(mapCatalogSearchRow)
  }
}

export function createSupabaseCatalogRepository(options: {
  client: SupabaseCatalogClientPort
}): CatalogRepository {
  return new SupabaseCatalogRepository(options.client)
}
