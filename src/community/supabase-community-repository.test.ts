import { describe, expect, it, vi } from 'vitest'
import type { ValidCommunityContribution } from './community-values'
import {
  CommunityRepositoryError,
  createSupabaseCommunityRepository,
} from './supabase-community-repository'

const cultivarId = '51000000-0000-4000-8000-000000000001'
const ownRow = {
  cultivar_id: cultivarId,
  thc_percent: '21.30',
  cbd_percent: '0.70',
  source_kind: 'label',
  consent_version: 'weedypedia-community-values-2026-07-28',
  updated_at: '2026-07-28T12:00:00.000Z',
}
const averageRow = {
  cultivar_id: cultivarId,
  thc_mean: '21.3',
  cbd_mean: '0.7',
  contributor_band: '5+',
  computed_at: '2026-07-28T12:00:00.000Z',
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

type Result = {
  data: unknown
  error: null | { code?: string; message: string }
}

function query(result: Result) {
  const promise = Promise.resolve(result)
  const builder = {
    select: vi.fn(),
    eq: vi.fn(),
    maybeSingle: vi.fn(() => promise),
    single: vi.fn(() => promise),
    abortSignal: vi.fn(),
    then: promise.then.bind(promise),
  }
  builder.select.mockReturnValue(builder)
  builder.eq.mockReturnValue(builder)
  builder.abortSignal.mockReturnValue(builder)
  return builder
}

function client(options: {
  own?: Result
  upsert?: Result
  remove?: Result
  average?: Result
} = {}) {
  const own = query(options.own ?? { data: ownRow, error: null })
  const upsert = query(options.upsert ?? { data: ownRow, error: null })
  const remove = query(options.remove ?? { data: null, error: null })
  const average = query(options.average ?? { data: averageRow, error: null })
  const rpc = vi.fn((
    name: string,
    _values?: Record<string, unknown>,
  ) => {
    if (name === 'get_my_community_flower_contribution') return own
    if (name === 'upsert_my_community_flower_contribution') return upsert
    return remove
  })
  return {
    client: {
      rpc,
      from: vi.fn(() => average),
    },
    rpc,
    own,
    upsert,
    remove,
    average,
  }
}

describe('createSupabaseCommunityRepository', () => {
  it('gets only the caller-owned contribution through its narrow RPC', async () => {
    const active = client()
    const repository = createSupabaseCommunityRepository({
      client: active.client,
    })

    await expect(repository.getOwn(cultivarId)).resolves.toEqual({
      cultivarId,
      thcPercent: 21.3,
      cbdPercent: 0.7,
      sourceKind: 'label',
      consentVersion: 'weedypedia-community-values-2026-07-28',
      updatedAt: '2026-07-28T12:00:00.000Z',
    })
    expect(active.rpc).toHaveBeenCalledWith(
      'get_my_community_flower_contribution',
      { p_cultivar_id: cultivarId },
    )
  })

  it('upserts the validated pair without owner, inventory, or count fields', async () => {
    const active = client()
    const repository = createSupabaseCommunityRepository({
      client: active.client,
    })

    await repository.upsert(contribution)

    expect(active.rpc).toHaveBeenCalledWith(
      'upsert_my_community_flower_contribution',
      {
        p_cultivar_id: cultivarId,
        p_thc_percent: 21.3,
        p_cbd_percent: 0.7,
        p_source_kind: 'label',
        p_consent_version:
          'weedypedia-community-values-2026-07-28',
        p_declaration_confirmed: true,
        p_opt_in: true,
      },
    )
    const payload = active.rpc.mock.calls[0]?.[1]
    expect(payload).not.toHaveProperty('user_id')
    expect(payload).not.toHaveProperty('inventory_id')
    expect(payload).not.toHaveProperty('contributor_count')
  })

  it('removes only through the own-record RPC', async () => {
    const active = client()
    const repository = createSupabaseCommunityRepository({
      client: active.client,
    })

    await repository.remove(cultivarId)

    expect(active.rpc).toHaveBeenCalledWith(
      'delete_my_community_flower_contribution',
      { p_cultivar_id: cultivarId },
    )
  })

  it('selects only the privacy-safe published aggregate fields', async () => {
    const active = client()
    const repository = createSupabaseCommunityRepository({
      client: active.client,
    })

    await expect(repository.getPublished(cultivarId)).resolves.toEqual({
      cultivarId,
      thcMean: 21.3,
      cbdMean: 0.7,
      contributorBand: '5+',
      computedAt: '2026-07-28T12:00:00.000Z',
    })
    expect(active.client.from).toHaveBeenCalledWith(
      'community_flower_averages',
    )
    expect(active.average.select).toHaveBeenCalledWith(
      'cultivar_id,thc_mean,cbd_mean,contributor_band,computed_at',
    )
  })

  it('maps zero own and published rows to null', async () => {
    const active = client({
      own: { data: null, error: null },
      average: { data: null, error: null },
    })
    const repository = createSupabaseCommunityRepository({
      client: active.client,
    })

    await expect(repository.getOwn(cultivarId)).resolves.toBeNull()
    await expect(repository.getPublished(cultivarId)).resolves.toBeNull()
  })

  it('distinguishes permission failures from availability failures', async () => {
    const forbidden = client({
      own: {
        data: null,
        error: { code: '42501', message: 'permission denied' },
      },
    })
    const unavailable = client({
      own: {
        data: null,
        error: { code: '500', message: 'network unavailable' },
      },
    })

    await expect(
      createSupabaseCommunityRepository({
        client: forbidden.client,
      }).getOwn(cultivarId),
    ).rejects.toEqual(
      new CommunityRepositoryError('COMMUNITY_FORBIDDEN'),
    )
    await expect(
      createSupabaseCommunityRepository({
        client: unavailable.client,
      }).getOwn(cultivarId),
    ).rejects.toEqual(
      new CommunityRepositoryError('COMMUNITY_UNAVAILABLE'),
    )
  })
})
