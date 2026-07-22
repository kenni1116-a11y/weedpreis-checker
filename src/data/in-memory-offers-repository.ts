import type { Offer } from '../domain/offer'
import { rankOffers } from '../domain/pricing'
import type { OffersRepository } from './offers-repository'

export function createInMemoryOffersRepository(offers: Offer[]): OffersRepository {
  return {
    async search(query, now = new Date()) {
      const needle = query.text?.trim().toLocaleLowerCase('de-DE')
      const matches = offers.filter(
        (offer) =>
          (!needle ||
            `${offer.productName} ${offer.manufacturer}`.toLocaleLowerCase('de-DE').includes(needle)) &&
          (!query.form || offer.form === query.form) &&
          (query.minThcPercent === undefined || offer.thcPercent >= query.minThcPercent)
      )

      return rankOffers(matches, query, now)
    }
  }
}
