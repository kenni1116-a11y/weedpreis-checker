import type { RankedOffer } from '../domain/offer'
import { OfferCard } from './OfferCard'

type ResultsListProps = {
  results: RankedOffer[]
  grams: number
}

export function ResultsList({ results, grams }: ResultsListProps) {
  const current = results.filter((result) => result.current)
  const stale = results.filter((result) => !result.current)

  if (!results.length) {
    return <p>Keine passenden Angebote gefunden.</p>
  }

  return (
    <section aria-live="polite" aria-label="Suchergebnisse">
      <h2>{current.length} aktuelle Angebote</h2>
      {current.map((result) => <OfferCard key={result.offer.id} result={result} grams={grams} />)}
      {stale.length > 0 && (
        <>
          <h2>Zuletzt gesehen</h2>
          {stale.map((result) => <OfferCard key={result.offer.id} result={result} grams={grams} />)}
        </>
      )}
    </section>
  )
}
