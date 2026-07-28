import type { CommunityRepository } from './community-repository'
import type {
  OwnCommunityContribution,
  PublishedCommunityAverage,
  ValidCommunityContribution,
} from './community-values'

type InMemoryCommunityOptions = {
  own?: OwnCommunityContribution[]
  published?: PublishedCommunityAverage[]
  now?: () => Date
}

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

export class InMemoryCommunityRepository implements CommunityRepository {
  readonly #own = new Map<string, OwnCommunityContribution>()
  readonly #published = new Map<string, PublishedCommunityAverage>()
  readonly #now: () => Date

  constructor(options: InMemoryCommunityOptions = {}) {
    for (const row of options.own ?? []) this.#own.set(row.cultivarId, row)
    for (const row of options.published ?? []) {
      this.#published.set(row.cultivarId, row)
    }
    this.#now = options.now ?? (() => new Date())
  }

  async getOwn(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<OwnCommunityContribution | null> {
    if (signal?.aborted) throw abortError()
    await Promise.resolve()
    if (signal?.aborted) throw abortError()
    const row = this.#own.get(cultivarId)
    return row ? { ...row } : null
  }

  async getPublished(
    cultivarId: string,
    signal?: AbortSignal,
  ): Promise<PublishedCommunityAverage | null> {
    if (signal?.aborted) throw abortError()
    await Promise.resolve()
    if (signal?.aborted) throw abortError()
    const row = this.#published.get(cultivarId)
    return row ? { ...row } : null
  }

  async upsert(
    input: ValidCommunityContribution,
  ): Promise<OwnCommunityContribution> {
    const row: OwnCommunityContribution = {
      cultivarId: input.cultivarId,
      thcPercent: input.thcPercent,
      cbdPercent: input.cbdPercent,
      sourceKind: input.sourceKind,
      consentVersion: input.consentVersion,
      updatedAt: this.#now().toISOString(),
    }
    this.#own.set(input.cultivarId, row)
    return { ...row }
  }

  async remove(cultivarId: string): Promise<void> {
    this.#own.delete(cultivarId)
  }

  seedPublished(row: PublishedCommunityAverage | null): void {
    if (row === null) return
    this.#published.set(row.cultivarId, { ...row })
  }
}
