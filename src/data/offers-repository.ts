import type { OfferQuery, RankedOffer } from '../domain/offer'

export interface OffersRepository {
  search(query: OfferQuery, now?: Date): Promise<RankedOffer[]>
}
