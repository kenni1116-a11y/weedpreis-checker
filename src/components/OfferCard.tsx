import { useState } from 'react'
import type { FulfillmentMode, RankedOffer } from '../domain/offer'
import { devicePreferences } from '../storage/device-preferences'

const euros = (cents: number) =>
  new Intl.NumberFormat('de-DE', { style: 'currency', currency: 'EUR' }).format(cents / 100)

type OfferCardProps = {
  result: RankedOffer
  quantity: number
  totalMode?: FulfillmentMode
  availabilityMessage?: string
  onFavoriteChange?: (ids: string[]) => void
}

export function OfferCard({
  result,
  quantity,
  totalMode,
  availabilityMessage,
  onFavoriteChange,
}: OfferCardProps) {
  const { offer, totalPriceCents, current } = result
  const [favorite, setFavorite] = useState(devicePreferences.getFavoriteIds().includes(offer.id))
  const formLabel = offer.form === 'flower' ? 'Blüte' : 'Extrakt'

  return (
    <article className={current ? 'offer-card' : 'offer-card stale'}>
      <p>{current ? 'Aktuelles Angebot' : 'Zuletzt gesehen'}</p>
      <h3>{offer.pharmacyName}</h3>
      <p>{offer.productName} · {offer.manufacturer}</p>
      <p>THC {offer.thcPercent}% · CBD {offer.cbdPercent}% · {formLabel}</p>
      <strong>{euros(offer.unitPriceCents)} / {offer.priceUnit}</strong>
      <p>
        Gesamtpreis für {quantity} {offer.priceUnit}
        {totalMode ? ` (${totalMode === 'shipping' ? 'Versand' : 'Abholung'})` : ''}: {euros(totalPriceCents)}
      </p>
      {availabilityMessage && <p>{availabilityMessage}</p>}
      <p>
        {offer.available ? 'verfügbar' : 'nicht verfügbar'} · {offer.sourceType} · zuletzt geprüft{' '}
        {new Date(offer.checkedAt).toLocaleString('de-DE')}
      </p>
      <button
        aria-pressed={favorite}
        onClick={() => {
          const favoriteIds = devicePreferences.toggleFavorite(offer.id)
          setFavorite(favoriteIds.includes(offer.id))
          onFavoriteChange?.(favoriteIds)
        }}
      >
        {favorite ? 'Favorit entfernen' : 'Als Favorit speichern'}
      </button>
      <a href={offer.sourceUrl} target="_blank" rel="noopener noreferrer">Zur Apotheke</a>
    </article>
  )
}
