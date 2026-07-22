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

    const result = await repository.getByIds(
      ['offer-a', 'offer-c'],
      { mode: 'shipping', quantity: 2 },
    )

    expect(result.map(({ offer }) => [offer.id, offer.priceUnit])).toEqual([
      ['offer-a', 'g'],
      ['offer-c', 'ml'],
    ])
  })
})
