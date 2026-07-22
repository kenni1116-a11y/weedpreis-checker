import { useEffect, useState } from 'react'
import type { OfferLookupResult, OffersRepository } from '../data/offers-repository'
import type { FulfillmentMode, Offer, PricingContext, RankedOffer } from '../domain/offer'
import { isCurrent, totalPriceCents } from '../domain/pricing'
import { devicePreferences } from '../storage/device-preferences'
import { ResultsList } from './ResultsList'

type FavoritesViewProps = {
  repository: OffersRepository
  pricingContext: PricingContext
  now?: Date
}

type FavoritesState = {
  lookups: OfferLookupResult[]
  status: 'idle' | 'loading' | 'error'
}

type FavoritePresentation = {
  availabilityMessage?: string
  pricingMode: FulfillmentMode
  result: RankedOffer
}

function supportsMode(offer: Offer, mode: FulfillmentMode): boolean {
  return mode === 'shipping' ? offer.shipping : offer.pickup
}

function favoritePresentation(
  offer: Offer,
  pricingContext: PricingContext,
  now: Date,
): FavoritePresentation {
  const supportsRequestedMode = supportsMode(offer, pricingContext.mode)
  const pricingMode = supportsRequestedMode
    ? pricingContext.mode
    : offer.shipping
      ? 'shipping'
      : offer.pickup
        ? 'pickup'
        : pricingContext.mode

  let availabilityMessage: string | undefined
  if (!offer.available) {
    availabilityMessage = 'Dieses gespeicherte Angebot ist derzeit nicht verfügbar.'
  } else if (!supportsRequestedMode) {
    availabilityMessage = pricingContext.mode === 'shipping'
      ? 'Dieses Angebot ist nicht für den Versand verfügbar.'
      : 'Dieses Angebot ist nicht zur Abholung verfügbar.'
  }

  return {
    availabilityMessage,
    pricingMode,
    result: {
      offer,
      current: isCurrent(offer.checkedAt, now),
      totalPriceCents: totalPriceCents(offer, { ...pricingContext, mode: pricingMode }),
    },
  }
}

export function FavoritesView({ repository, pricingContext, now }: FavoritesViewProps) {
  const [favoriteIds, setFavoriteIds] = useState(() => devicePreferences.getFavoriteIds())
  const [state, setState] = useState<FavoritesState>(() => ({
    lookups: [],
    status: favoriteIds.length ? 'loading' : 'idle',
  }))

  useEffect(() => {
    if (!favoriteIds.length) {
      setState({ lookups: [], status: 'idle' })
      return
    }

    let active = true
    setState({ lookups: [], status: 'loading' })
    repository.getByIds(favoriteIds).then(
      (lookups) => {
        if (active) setState({ lookups, status: 'idle' })
      },
      () => {
        if (active) setState({ lookups: [], status: 'error' })
      },
    )

    return () => {
      active = false
    }
  }, [favoriteIds, repository])

  const presentationNow = now ?? new Date()
  const presentations = state.lookups
    .filter((lookup): lookup is Extract<OfferLookupResult, { status: 'found' }> => lookup.status === 'found')
    .map(({ offer }) => favoritePresentation(offer, pricingContext, presentationNow))
  const presentationByOfferId = new Map(
    presentations.map((presentation) => [presentation.result.offer.id, presentation]),
  )
  const missingLookups = state.lookups.filter((lookup) => lookup.status === 'not-found')

  function removeFavorite(id: string) {
    setFavoriteIds(devicePreferences.toggleFavorite(id))
  }

  return (
    <section aria-label="Favoriten">
      <h2>Favoriten</h2>
      {state.status === 'loading' && <p role="status">Favoriten werden geladen …</p>}
      {state.status === 'error' && <p role="alert">Favoriten konnten nicht geladen werden.</p>}
      {state.status === 'idle' && presentations.length > 0 && (
        <ResultsList
          results={presentations.map(({ result }) => result)}
          quantity={pricingContext.quantity}
          getCardContext={(result) => {
            const presentation = presentationByOfferId.get(result.offer.id)
            return {
              availabilityMessage: presentation?.availabilityMessage,
              totalMode: presentation?.pricingMode,
            }
          }}
          onFavoriteChange={setFavoriteIds}
        />
      )}
      {state.status === 'idle' && missingLookups.map(({ id }) => (
        <article className="offer-card stale" key={id}>
          <p>Gespeicherter Favorit</p>
          <h3>Angebot nicht gefunden</h3>
          <p>Gespeichertes Angebot {id} ist nicht mehr im Testkatalog verfügbar.</p>
          <button aria-pressed="true" onClick={() => removeFavorite(id)}>Favorit entfernen</button>
        </article>
      ))}
      {state.status === 'idle' && favoriteIds.length === 0 && (
        <p>Noch keine Favoriten gespeichert.</p>
      )}
    </section>
  )
}
