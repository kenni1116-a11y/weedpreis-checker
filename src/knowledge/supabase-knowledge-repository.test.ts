import { describe, expect, it, vi } from 'vitest'
import { createSupabaseKnowledgeRepository } from './supabase-knowledge-repository'

const graph = {
  snapshotId: '7A000000-0000-4000-8000-000000000001',
  publishedAt: '2026-07-30T12:00:00.000Z',
  nodes: [{
    id: '7A000000-0000-4000-8000-000000000002',
    kind: 'cultivar',
    canonicalName: 'Synthetic Cultivar',
  }],
  claims: [],
  edges: [],
}

function rpcQuery(result: {
  data: unknown
  error: null | { code?: string; message: string }
}) {
  const promise = Promise.resolve(result)
  const builder = {
    abortSignal: vi.fn(),
    then: promise.then.bind(promise),
  }
  builder.abortSignal.mockReturnValue(builder)
  return builder
}

describe('createSupabaseKnowledgeRepository', () => {
  it('loads the published graph without browser-supplied source or reviewer values', async () => {
    const result = rpcQuery({ data: graph, error: null })
    const rpc = vi.fn(() => result)
    const repository = createSupabaseKnowledgeRepository({ client: { rpc } })

    await expect(repository.loadGraph()).resolves.toEqual({
      ...graph,
      snapshotId: '7a000000-0000-4000-8000-000000000001',
      nodes: [{ ...graph.nodes[0], id: '7a000000-0000-4000-8000-000000000002' }],
    })

    expect(rpc).toHaveBeenCalledWith('get_published_knowledge_graph')
    expect(result.abortSignal).not.toHaveBeenCalled()
  })

  it('returns null when no knowledge graph has been published', async () => {
    const result = rpcQuery({ data: null, error: null })
    const repository = createSupabaseKnowledgeRepository({
      client: { rpc: vi.fn(() => result) },
    })

    await expect(repository.loadGraph()).resolves.toBeNull()
  })

  it('fails closed when the RPC returns a malformed graph', async () => {
    const result = rpcQuery({
      data: { ...graph, nodes: [{ ...graph.nodes[0], kind: 'unknown' }] },
      error: null,
    })
    const repository = createSupabaseKnowledgeRepository({
      client: { rpc: vi.fn(() => result) },
    })

    await expect(repository.loadGraph()).rejects.toThrow('Invalid knowledge graph')
  })

  it('returns the knowledge availability error for Supabase failures', async () => {
    const result = rpcQuery({
      data: null,
      error: { code: '42501', message: 'permission denied' },
    })
    const repository = createSupabaseKnowledgeRepository({
      client: { rpc: vi.fn(() => result) },
    })

    const error = await repository.loadGraph().catch((reason: unknown) => reason)

    expect(error).toBeInstanceOf(Error)
    expect((error as Error).message).toBe(
      'Der Weedypedia-Datenstand ist derzeit nicht verfügbar.',
    )
  })

  it('does not start the RPC when the signal is already aborted', async () => {
    const controller = new AbortController()
    controller.abort()
    const rpc = vi.fn()
    const repository = createSupabaseKnowledgeRepository({ client: { rpc } })

    await expect(repository.loadGraph(controller.signal)).rejects.toMatchObject({
      name: 'AbortError',
    })

    expect(rpc).not.toHaveBeenCalled()
  })

  it('forwards an abort signal and rejects if it aborts after the RPC resolves', async () => {
    const controller = new AbortController()
    let resolveResult!: (value: { data: unknown; error: null }) => void
    const promise = new Promise<{ data: unknown; error: null }>((resolve) => {
      resolveResult = resolve
    })
    const pending = {
      abortSignal: vi.fn(),
      then: promise.then.bind(promise),
    }
    pending.abortSignal.mockReturnValue(pending)
    const repository = createSupabaseKnowledgeRepository({
      client: { rpc: vi.fn(() => pending) },
    })

    const load = repository.loadGraph(controller.signal)
    controller.abort()
    resolveResult({ data: graph, error: null })

    await expect(load).rejects.toMatchObject({ name: 'AbortError' })
    expect(pending.abortSignal).toHaveBeenCalledWith(controller.signal)
  })

  it('prioritizes a post-RPC abort over a Supabase availability error', async () => {
    const controller = new AbortController()
    let resolveResult!: (value: {
      data: unknown
      error: { code?: string; message: string }
    }) => void
    const promise = new Promise<{
      data: unknown
      error: { code?: string; message: string }
    }>((resolve) => {
      resolveResult = resolve
    })
    const pending = {
      abortSignal: vi.fn(),
      then: promise.then.bind(promise),
    }
    pending.abortSignal.mockReturnValue(pending)
    const repository = createSupabaseKnowledgeRepository({
      client: { rpc: vi.fn(() => pending) },
    })

    const load = repository.loadGraph(controller.signal)
    controller.abort()
    resolveResult({
      data: null,
      error: { code: '57014', message: 'query cancelled' },
    })

    await expect(load).rejects.toMatchObject({ name: 'AbortError' })
  })
})
