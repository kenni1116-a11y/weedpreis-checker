import type { CatalogRepository } from './catalog-repository'
import type { CatalogSearchMatch } from './catalog-search'

function abortError(): DOMException {
  return new DOMException('Vorgang abgebrochen.', 'AbortError')
}

function clone(match: CatalogSearchMatch): CatalogSearchMatch {
  return {
    ...match,
    preferredParents: [...match.preferredParents],
    sourcedValueEvidence: match.sourcedValueEvidence.map((item) => ({
      ...item,
    })),
  }
}

export class InMemoryCatalogRepository implements CatalogRepository {
  readonly #matches: CatalogSearchMatch[]

  constructor(matches: CatalogSearchMatch[] = []) {
    this.#matches = matches.map(clone)
  }

  async search(
    input: string,
    signal?: AbortSignal,
  ): Promise<CatalogSearchMatch[]> {
    if (signal?.aborted) throw abortError()
    await Promise.resolve()
    if (signal?.aborted) throw abortError()

    const query = input.trim().toLocaleLowerCase('de-DE')
    if (Array.from(query).length < 2) return []

    return this.#matches
      .filter((match) => (
        match.canonicalName.toLocaleLowerCase('de-DE').includes(query)
        || match.matchedName.toLocaleLowerCase('de-DE').includes(query)
      ))
      .map(clone)
  }
}
