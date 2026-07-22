import type { Offer } from '../domain/offer'
import { createInMemoryOffersRepository } from './in-memory-offers-repository'

const hoursAgo = (hours: number) => new Date(Date.now() - hours * 3_600_000).toISOString()

export const syntheticOffers: Offer[] = [
  {
    id: 'offer-a',
    productId: 'alpha',
    productName: 'Testblüte Alpha 22/1',
    manufacturer: 'Testlabor Nord',
    form: 'flower',
    thcPercent: 22,
    cbdPercent: 1,
    pharmacyId: 'test-a',
    pharmacyName: 'Muster-Apotheke A – Testdaten',
    sourceType: 'feed',
    sourceUrl: 'https://example.invalid/a',
    unitPriceCents: 649,
    shippingCents: 499,
    pickup: true,
    shipping: true,
    available: true,
    checkedAt: hoursAgo(1),
    distanceMeters: 2400
  },
  {
    id: 'offer-b',
    productId: 'alpha',
    productName: 'Testblüte Alpha 22/1',
    manufacturer: 'Testlabor Nord',
    form: 'flower',
    thcPercent: 22,
    cbdPercent: 1,
    pharmacyId: 'test-b',
    pharmacyName: 'Muster-Apotheke B – Testdaten',
    sourceType: 'manual-review',
    sourceUrl: 'https://example.invalid/b',
    unitPriceCents: 675,
    shippingCents: 0,
    pickup: false,
    shipping: true,
    available: true,
    checkedAt: hoursAgo(3)
  },
  {
    id: 'offer-c',
    productId: 'beta',
    productName: 'Testextrakt Beta 10/10',
    manufacturer: 'Testlabor Süd',
    form: 'extract',
    thcPercent: 10,
    cbdPercent: 10,
    pharmacyId: 'test-c',
    pharmacyName: 'Muster-Apotheke C – Testdaten',
    sourceType: 'public-source',
    sourceUrl: 'https://example.invalid/c',
    unitPriceCents: 710,
    shippingCents: 499,
    pickup: true,
    shipping: true,
    available: true,
    checkedAt: hoursAgo(30),
    distanceMeters: 5100
  }
]

export const inMemoryOffersRepository = createInMemoryOffersRepository(syntheticOffers)
