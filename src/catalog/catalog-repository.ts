import type { CatalogSearchMatch } from './catalog-search'

export type CatalogRepository = {
  search(
    query: string,
    signal?: AbortSignal,
  ): Promise<CatalogSearchMatch[]>
}
