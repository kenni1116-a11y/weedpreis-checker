import { describe, expect, it, vi } from 'vitest'
import { createSupabaseCatalogRepository } from './supabase-catalog-repository'

const row = {
  id: '51000000-0000-4000-8000-000000000001',
  kind: 'cultivar',
  canonical_name: 'Synthetic Cultivar',
  matched_name: 'Synthetic Alias',
  match_reason: 'alias',
  canonical_cultivar_id: '51000000-0000-4000-8000-000000000001',
  is_flower: true,
  preferred_parents: ['Parent One', 'Parent Two'],
  has_additional_lineage: false,
  sourced_thc_label: '21,3 %',
  sourced_cbd_label: '0,7 %',
  sourced_value_evidence: [],
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

describe('createSupabaseCatalogRepository', () => {
  it('trims queries and maps only the approved catalog contract', async () => {
    const result = rpcQuery({ data: [row], error: null })
    const rpc = vi.fn(() => result)
    const repository = createSupabaseCatalogRepository({ client: { rpc } })

    await expect(repository.search('  Synthetic  ')).resolves.toEqual([{
      id: row.id,
      kind: 'cultivar',
      canonicalName: 'Synthetic Cultivar',
      matchedName: 'Synthetic Alias',
      matchReason: 'alias',
      canonicalCultivarId: row.canonical_cultivar_id,
      isFlower: true,
      preferredParents: ['Parent One', 'Parent Two'],
      hasAdditionalLineage: false,
      sourcedThcLabel: '21,3 %',
      sourcedCbdLabel: '0,7 %',
      sourcedValueEvidence: [],
    }])
    expect(rpc).toHaveBeenCalledWith('search_catalog_references', {
      p_query: 'Synthetic',
    })
  })

  it.each(['', ' ', 'a', ' 🌿 '])(
    'does not call the server for a short query %j',
    async (query) => {
      const rpc = vi.fn()
      const repository = createSupabaseCatalogRepository({ client: { rpc } })

      await expect(repository.search(query)).resolves.toEqual([])
      expect(rpc).not.toHaveBeenCalled()
    },
  )

  it('never replaces the user query with a canonical spelling', async () => {
    const result = rpcQuery({ data: [row], error: null })
    const rpc = vi.fn(() => result)
    const repository = createSupabaseCatalogRepository({ client: { rpc } })

    const [match] = await repository.search('Synthetic Alias')

    expect(match.matchedName).toBe('Synthetic Alias')
    expect(match.canonicalName).toBe('Synthetic Cultivar')
    expect(rpc).toHaveBeenCalledWith(
      'search_catalog_references',
      { p_query: 'Synthetic Alias' },
    )
  })

  it('checks abort before and after the RPC and forwards the signal', async () => {
    const firstController = new AbortController()
    firstController.abort()
    const firstRpc = vi.fn()
    const firstRepository = createSupabaseCatalogRepository({
      client: { rpc: firstRpc },
    })
    await expect(
      firstRepository.search('Synthetic', firstController.signal),
    ).rejects.toMatchObject({ name: 'AbortError' })
    expect(firstRpc).not.toHaveBeenCalled()

    const secondController = new AbortController()
    let resolveResult!: (value: {
      data: unknown
      error: null
    }) => void
    const promise = new Promise<{ data: unknown; error: null }>((resolve) => {
      resolveResult = resolve
    })
    const pending = {
      abortSignal: vi.fn(),
      then: promise.then.bind(promise),
    }
    pending.abortSignal.mockReturnValue(pending)
    const secondRepository = createSupabaseCatalogRepository({
      client: { rpc: vi.fn(() => pending) },
    })
    const search = secondRepository.search(
      'Synthetic',
      secondController.signal,
    )
    secondController.abort()
    resolveResult({ data: [row], error: null })

    await expect(search).rejects.toMatchObject({ name: 'AbortError' })
    expect(pending.abortSignal).toHaveBeenCalledWith(secondController.signal)
  })

  it('fails closed when the RPC returns malformed rows', async () => {
    const result = rpcQuery({
      data: [{ ...row, match_reason: 'guess' }],
      error: null,
    })
    const repository = createSupabaseCatalogRepository({
      client: { rpc: vi.fn(() => result) },
    })

    await expect(repository.search('Synthetic')).rejects.toThrow(
      'match reason',
    )
  })
})
