import { useState } from 'react'
import type { OfferQuery, RankedOffer } from '../domain/offer'
import type { OffersRepository } from '../data/offers-repository'
import { ResultsList } from './ResultsList'
import { SearchControls } from './SearchControls'

type SearchExperienceProps = {
  repository: OffersRepository
}

export function SearchExperience({ repository }: SearchExperienceProps) {
  const [results, setResults] = useState<RankedOffer[] | null>(null)
  const [grams, setGrams] = useState(10)
  const [status, setStatus] = useState<'idle' | 'loading' | 'error'>('idle')

  async function search(query: OfferQuery) {
    setStatus('loading')
    setResults(null)
    setGrams(query.grams)

    try {
      setResults(await repository.search(query))
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
