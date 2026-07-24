import type { Offer, OfferQuery, RankedOffer } from '../domain/offer'

export type OfferLookupResult =
  | { id: string; status: 'found'; offer: Offer }
  | { id: string; status: 'not-found' }

export interface OffersRepository {
  search(query: OfferQuery, now?: Date): Promise<RankedOffer[]>
  getByIds(ids: string[]): Promise<OfferLookupResult[]>
}
