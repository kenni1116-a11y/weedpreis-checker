import { useState } from 'react'
import type { RankedOffer } from '../domain/offer'
import { devicePreferences } from '../storage/device-preferences'
import { ResultsList } from './ResultsList'

type FavoritesViewProps = {
  results: RankedOffer[]
  grams: number
}

export function FavoritesView({ results, grams }: FavoritesViewProps) {
  const [favoriteIds, setFavoriteIds] = useState(() => devicePreferences.getFavoriteIds())
  const favorites = new Set(favoriteIds)
  const favoriteResults = results.filter((result) => favorites.has(result.offer.id))

  return (
    <section aria-label="Favoriten">
      <h2>Favoriten</h2>
      {favoriteResults.length > 0 ? (
        <ResultsList
          results={favoriteResults}
          grams={grams}
          onFavoriteChange={setFavoriteIds}
        />
      ) : (
        <p>Noch keine Favoriten gespeichert.</p>
      )}
    </section>
  )
}
