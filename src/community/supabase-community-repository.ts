import type { CommunityRepository } from './community-repository'
import {
  mapOwnCommunityContribution,
  mapPublishedCommunityAverage,
  type OwnCommunityContribution,
  type PublishedCommunityAverage,
  type ValidCommunityContribution,
} from './community-values'

type ServiceError = {
  code?: string
  message: string
} | null

type QueryResult = {
  data: unknown
  error: ServiceError
}

type QueryPort = PromiseLike<QueryResult> & {
  select(columns: string): QueryPort
  eq(column: string, value: unknown): QueryPort
  maybeSingle(): Promise<QueryResult>
  single(): Promise<QueryResult>
  abortSignal(signal: AbortSignal): QueryPort
}

export type SupabaseCommunityClientPort = {
  rpc(name: string, values?: Record<string, unknown>): QueryPort
  from(table: string): QueryPort
}

type CommunityErrorCode =
  | 'COMMUNITY_FORBIDDEN'
  | 'COMMUNITY_UNAVAILABLE'

export class CommunityRepositoryError extends Error {
  readonly code: CommunityErrorCode

  constructor(code: CommunityErrorCode) {
    super(
      code === 'COMMUNITY_FORBIDDEN'
        ? 'Community-Werte sind für diese Sitzung nicht freigegeben.'
        : 'Community-Werte sind derzeit nicht verfügbar.',
    )
    this.name = 'CommunityRepositoryError'
    this.code = code
  }
}

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

function throwIfAborted(signal?: AbortSignal): void {
  if (signal?.aborted) throw abortError()
}

function mapError(error: Exclude<ServiceError, null>): never {
  const forbidden =
    error.code === '42501'
    || error.code === '403'
    || /permission|forbidden|assurance/i.test(error.message)
  throw new CommunityRepositoryError(
    forbidden ? 'COMMUNITY_FORBIDDEN' : 'COMMUNITY_UNAVAILABLE',
  )
}

async function maybeSingle(
  query: QueryPort,
  signal?: AbortSignal,
): Promise<QueryResult> {
  let request = query
  if (signal) request = request.abortSignal(signal)
  const result = await request.maybeSingle()
  throwIfAborted(signal)
  return result
}

class SupabaseCommunityRepository implements CommunityRepository {
  readonly #client: SupabaseCommunityClientPort

  constructor(client: SupabaseCommunityClientPort) {
    this.#client = client
  }

  async getOwn(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<OwnCommunityContribution | null> {
    throwIfAborted(signal)
    const result = await maybeSingle(
      this.#client.rpc('get_my_community_flower_contribution', {
        p_cultivar_id: cultivarId,
      }),
      signal,
    )
    if (result.error) mapError(result.error)
    return result.data === null
      ? null
      : mapOwnCommunityContribution(result.data)
  }

  async getPublished(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<PublishedCommunityAverage | null> {
    throwIfAborted(signal)
    const result = await maybeSingle(
      this.#client
        .from('community_flower_averages')
        .select(
          'cultivar_id,thc_mean,cbd_mean,contributor_band,computed_at',
        )
        .eq('cultivar_id', cultivarId),
      signal,
    )
    if (result.error) mapError(result.error)
    return result.data === null
      ? null
      : mapPublishedCommunityAverage(result.data)
  }

  async upsert(
    input: ValidCommunityContribution,
  ): Promise<OwnCommunityContribution> {
    const result = await this.#client
      .rpc('upsert_my_community_flower_contribution', {
        p_cultivar_id: input.cultivarId,
        p_thc_percent: input.thcPercent,
        p_cbd_percent: input.cbdPercent,
        p_source_kind: input.sourceKind,
        p_consent_version: input.consentVersion,
        p_declaration_confirmed: input.declarationAccepted,
        p_opt_in: input.optIn,
      })
      .single()
    if (result.error) mapError(result.error)
    return mapOwnCommunityContribution(result.data)
  }

  async remove(cultivarId: string): Promise<void> {
    const result = await this.#client.rpc(
      'delete_my_community_flower_contribution',
      { p_cultivar_id: cultivarId },
    )
    if (result.error) mapError(result.error)
  }
}

export function createSupabaseCommunityRepository(options: {
  client: SupabaseCommunityClientPort
}): CommunityRepository {
  return new SupabaseCommunityRepository(options.client)
}
