import { useEffect, useState } from 'react'
import type { OffersRepository } from '../data/offers-repository'
import type { PricingContext, RankedOffer } from '../domain/offer'
import { devicePreferences } from '../storage/device-preferences'
import { ResultsList } from './ResultsList'

type FavoritesViewProps = {
  repository: OffersRepository
  pricingContext: PricingContext
  now?: Date
}

type FavoritesState = {
  results: RankedOffer[]
  status: 'idle' | 'loading' | 'error'
}

export function FavoritesView({ repository, pricingContext, now }: FavoritesViewProps) {
  const [favoriteIds, setFavoriteIds] = useState(() => devicePreferences.getFavoriteIds())
  const [state, setState] = useState<FavoritesState>({ results: [], status: 'idle' })
  const nowTimestamp = now?.getTime()

  useEffect(() => {
    if (!favoriteIds.length) {
      setState({ results: [], status: 'idle' })
      return
    }

    let active = true
    setState({ results: [], status: 'loading' })
    repository.getByIds(favoriteIds, pricingContext, now).then(
      (results) => {
        if (active) setState({ results, status: 'idle' })
      },
      () => {
        if (active) setState({ results: [], status: 'error' })
      },
    )

    return () => {
      active = false
    }
  }, [favoriteIds, nowTimestamp, pricingContext.mode, pricingContext.quantity, repository])

  return (
    <section aria-label="Favoriten">
      <h2>Favoriten</h2>
      {state.status === 'loading' && <p role="status">Favoriten werden geladen …</p>}
      {state.status === 'error' && <p role="alert">Favoriten konnten nicht geladen werden.</p>}
      {state.status === 'idle' && state.results.length > 0 ? (
        <ResultsList
          results={state.results}
          quantity={pricingContext.quantity}
          onFavoriteChange={setFavoriteIds}
        />
      ) : state.status === 'idle' ? (
        <p>Noch keine Favoriten gespeichert.</p>
      ) : null}
    </section>
  )
}
