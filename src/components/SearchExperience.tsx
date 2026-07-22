import { useState } from 'react'
import type { OfferQuery, RankedOffer } from '../domain/offer'
import type { OffersRepository } from '../data/offers-repository'
import { ResultsList } from './ResultsList'
import { SearchControls } from './SearchControls'

type SearchExperienceProps = {
  repository: OffersRepository
  onResultsChange?: (results: RankedOffer[], grams: number) => void
}

export function SearchExperience({ repository, onResultsChange }: SearchExperienceProps) {
  const [results, setResults] = useState<RankedOffer[] | null>(null)
  const [grams, setGrams] = useState(10)
  const [status, setStatus] = useState<'idle' | 'loading' | 'error'>('idle')

  async function search(query: OfferQuery) {
    setStatus('loading')
    setResults(null)
    setGrams(query.grams)

    try {
      const nextResults = await repository.search(query)
      setResults(nextResults)
      onResultsChange?.(nextResults, query.grams)
      setStatus('idle')
    } catch {
      setStatus('error')
    }
  }

  return (
    <>
      <SearchControls onSearch={search} />
      {status === 'loading' && <p role="status">Angebote werden geladen …</p>}
      {status === 'error' && (
        <p role="alert">Angebote konnten nicht geladen werden. Es wird keine Verfügbarkeit angenommen.</p>
      )}
      {results && <ResultsList results={results} grams={grams} />}
    </>
  )
}
