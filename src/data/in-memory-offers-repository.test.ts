import { describe, expect, it } from 'vitest'
import { createInMemoryOffersRepository } from './in-memory-offers-repository'
import { syntheticOffers } from './synthetic-offers'

describe('in-memory repository', () => {
  it('matches product and manufacturer case-insensitively', async () => {
    const repository = createInMemoryOffersRepository(syntheticOffers)
    const result = await repository.search(
      { mode: 'shipping', quantity: 10, text: 'testlabor nord' },
      new Date('2026-07-22T18:00:00Z')
    )

    expect(result.length).toBeGreaterThan(0)
    expect(result.every(({ offer }) => offer.manufacturer === 'Testlabor Nord')).toBe(true)
  })

  it('filters the neutral catalog by form and factual THC value', async () => {
    const repository = createInMemoryOffersRepository(syntheticOffers)
    const result = await repository.search({
      mode: 'shipping',
      quantity: 10,
      form: 'flower',
      minThcPercent: 20
    })

    expect(result.length).toBeGreaterThan(0)
    expect(result.every(({ offer }) => offer.form === 'flower' && offer.thcPercent >= 20)).toBe(true)
  })

  it('resolves favorite IDs independently of catalog search filters', async () => {
    const repository = createInMemoryOffersRepository(syntheticOffers)

    const result = await repository.getByIds(['offer-a', 'offer-c'])

    expect(result.map((item) => item.status === 'found'
      ? [item.offer.id, item.offer.priceUnit]
      : [item.id, item.status],
    )).toEqual([
      ['offer-a', 'g'],
      ['offer-c', 'ml'],
    ])
  })

  it('returns unavailable offers and explicit not-found entries for every saved ID', async () => {
    const unavailableOffer = {
      ...syntheticOffers[0],
      id: 'offer-unavailable',
      available: false,
    }
    const repository = createInMemoryOffersRepository([...syntheticOffers, unavailableOffer])

    const result = await repository.getByIds(['offer-unavailable', 'offer-missing'])

    expect(result).toMatchObject([
      { id: 'offer-unavailable', status: 'found', offer: { available: false } },
      { id: 'offer-missing', status: 'not-found' },
    ])
  })
})
