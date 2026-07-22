import { describe, expect, it } from 'vitest'
import { isCurrent, rankOffers } from './pricing'
import type { Offer } from './offer'

const base: Offer = {
  id: 'offer-a', productId: 'product-a', productName: 'Testblüte Alpha 22/1', manufacturer: 'Testlabor Nord',
  form: 'flower', thcPercent: 22, cbdPercent: 1,
  pharmacyId: 'pharmacy-a', pharmacyName: 'Muster-Apotheke A – Testdaten', sourceType: 'feed',
  sourceUrl: 'https://example.invalid/a', unitPriceCents: 650, shippingCents: 499,
  pickup: false, shipping: true, available: true, checkedAt: '2026-07-22T12:00:00.000Z'
}

describe('pricing', () => {
  it('treats exactly 24 hours as stale', () => {
    expect(isCurrent(base.checkedAt, new Date('2026-07-23T11:59:59.000Z'))).toBe(true)
    expect(isCurrent(base.checkedAt, new Date('2026-07-23T12:00:00.000Z'))).toBe(false)
  })

  it('ranks current shipping offers by total price for requested grams', () => {
    const freeShipping = { ...base, id: 'offer-b', unitPriceCents: 675, shippingCents: 0 }
    const ranked = rankOffers([base, freeShipping], { mode: 'shipping', grams: 10 }, new Date('2026-07-22T18:00:00.000Z'))
    expect(ranked.map(({ offer, totalPriceCents }) => [offer.id, totalPriceCents])).toEqual([
      ['offer-b', 6750], ['offer-a', 6999]
    ])
  })
})
