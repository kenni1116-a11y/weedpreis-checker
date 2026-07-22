import type { FulfillmentMode, RankedOffer } from '../domain/offer'
import { OfferCard } from './OfferCard'

type ResultsListProps = {
  results: RankedOffer[]
  quantity: number
  getCardContext?: (result: RankedOffer) => {
    totalMode?: FulfillmentMode
    availabilityMessage?: string
  }
  onFavoriteChange?: (ids: string[]) => void
}

export function ResultsList({ results, quantity, getCardContext, onFavoriteChange }: ResultsListProps) {
  const current = results.filter((result) => result.current)
  const stale = results.filter((result) => !result.current)

  if (!results.length) {
    return <p>Keine passenden Angebote gefunden.</p>
  }

  return (
    <section aria-live="polite" aria-label="Suchergebnisse">
      <h2>{current.length} aktuelle Angebote</h2>
      {current.map((result) => (
        <OfferCard
          key={result.offer.id}
          result={result}
          quantity={quantity}
          onFavoriteChange={onFavoriteChange}
          {...getCardContext?.(result)}
        />
      ))}
      {stale.length > 0 && (
        <>
          <h2>Zuletzt gesehen</h2>
          {stale.map((result) => (
            <OfferCard
              key={result.offer.id}
              result={result}
              quantity={quantity}
              onFavoriteChange={onFavoriteChange}
              {...getCardContext?.(result)}
            />
          ))}
        </>
      )}
    </section>
  )
}
