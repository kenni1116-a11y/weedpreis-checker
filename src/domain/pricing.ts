import type { Offer, OfferQuery, RankedOffer } from './offer'

export const CURRENT_WINDOW_MS = 24 * 60 * 60 * 1000

export function isCurrent(checkedAt: string, now: Date): boolean {
  return now.getTime() - new Date(checkedAt).getTime() < CURRENT_WINDOW_MS
}

export function totalPriceCents(offer: Offer, query: OfferQuery): number {
  return offer.unitPriceCents * query.grams + (query.mode === 'shipping' ? offer.shippingCents : 0)
}

export function rankOffers(offers: Offer[], query: OfferQuery, now: Date): RankedOffer[] {
  return offers
    .filter((offer) => offer.available && (query.mode === 'shipping' ? offer.shipping : offer.pickup))
    .map((offer) => ({
      offer,
      totalPriceCents: totalPriceCents(offer, query),
      current: isCurrent(offer.checkedAt, now)
    }))
    .sort((a, b) => Number(b.current) - Number(a.current) || a.totalPriceCents - b.totalPriceCents || a.offer.id.localeCompare(b.offer.id))
}
