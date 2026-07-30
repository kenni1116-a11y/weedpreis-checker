import { mapKnowledgeGraph } from './knowledge-graph'
import type { KnowledgeRepository } from './knowledge-repository'

type RpcResult = {
  data: unknown
  error: { code?: string; message: string } | null
}

type RpcQueryPort = PromiseLike<RpcResult> & {
  abortSignal(signal: AbortSignal): RpcQueryPort
}

export type SupabaseKnowledgeClientPort = {
  rpc(name: string): RpcQueryPort
}

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) throw abortError()
}

class SupabaseKnowledgeRepository implements KnowledgeRepository {
  readonly #client: SupabaseKnowledgeClientPort

  constructor(client: SupabaseKnowledgeClientPort) {
    this.#client = client
  }

  async loadGraph(signal?: AbortSignal) {
    throwIfAborted(signal)

    let request = this.#client.rpc('get_published_knowledge_graph')
    if (signal) request = request.abortSignal(signal)

    const result = await request
    throwIfAborted(signal)
    if (result.error) {
      throw new Error('Der Weedypedia-Datenstand ist derzeit nicht verfügbar.')
    }
    if (result.data === null) return null

    return mapKnowledgeGraph(result.data)
  }
}

export function createSupabaseKnowledgeRepository(options: {
  client: SupabaseKnowledgeClientPort
}): KnowledgeRepository {
  return new SupabaseKnowledgeRepository(options.client)
}
