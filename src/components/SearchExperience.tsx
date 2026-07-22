import { useEffect, useRef, useState } from 'react'
import type { OfferQuery, RankedOffer } from '../domain/offer'
import type { OffersRepository } from '../data/offers-repository'
import { ResultsList } from './ResultsList'
import { SearchControls } from './SearchControls'

type SearchExperienceProps = {
  repository: OffersRepository
  onResultsChange?: (results: RankedOffer[], query: OfferQuery) => void
}

type SearchView = {
  results: RankedOffer[] | null
  quantity: number
  status: 'idle' | 'loading' | 'error'
}

export function SearchExperience({ repository, onResultsChange }: SearchExperienceProps) {
  const [view, setView] = useState<SearchView>({ results: null, quantity: 10, status: 'idle' })
  const latestRequest = useRef(0)

  useEffect(() => () => {
    latestRequest.current += 1
  }, [])

  async function search(query: OfferQuery) {
    const requestId = ++latestRequest.current
    setView({ results: null, quantity: query.quantity, status: 'loading' })

    try {
      const nextResults = await repository.search(query)
      if (requestId !== latestRequest.current) return
      setView({ results: nextResults, quantity: query.quantity, status: 'idle' })
      onResultsChange?.(nextResults, query)
    } catch {
      if (requestId !== latestRequest.current) return
      setView({ results: null, quantity: query.quantity, status: 'error' })
    }
  }

  return (
    <>
      <SearchControls onSearch={search} />
      {view.status === 'loading' && <p role="status">Angebote werden geladen …</p>}
      {view.status === 'error' && (
        <p role="alert">Angebote konnten nicht geladen werden. Es wird keine Verfügbarkeit angenommen.</p>
      )}
      {view.results && <ResultsList results={view.results} quantity={view.quantity} />}
    </>
  )
}
