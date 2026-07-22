import type { OfferQuery, PricingContext, RankedOffer } from '../domain/offer'

export interface OffersRepository {
  search(query: OfferQuery, now?: Date): Promise<RankedOffer[]>
  getByIds(ids: string[], pricingContext: PricingContext, now?: Date): Promise<RankedOffer[]>
}
