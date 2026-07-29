import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { devicePreferences } from './device-preferences'

describe('device preferences', () => {
  beforeEach(() => localStorage.clear())
  afterEach(() => vi.restoreAllMocks())

  it('stores only legacy favorite IDs', () => {
    devicePreferences.toggleFavorite('offer-a')

    expect(Object.keys(localStorage)).toEqual(['weedpreis.favorites'])
    expect(devicePreferences.getFavoriteIds()).toEqual(['offer-a'])
  })

  it('falls back to no favorites for malformed JSON', () => {
    localStorage.setItem('weedpreis.favorites', '{not-json')

    expect(devicePreferences.getFavoriteIds()).toEqual([])
  })

  it.each([
    ['an object', JSON.stringify({ id: 'offer-a' })],
    ['a mixed array', JSON.stringify(['offer-a', 7])],
  ])('falls back to no favorites for %s', (_, storedValue) => {
    localStorage.setItem('weedpreis.favorites', storedValue)

    expect(devicePreferences.getFavoriteIds()).toEqual([])
  })

  it('falls back to no favorites when storage cannot be read', () => {
    vi.spyOn(Storage.prototype, 'getItem').mockImplementation(() => {
      throw new DOMException('blocked')
    })

    expect(devicePreferences.getFavoriteIds()).toEqual([])
  })

  it('does not throw or claim a favorite was stored when storage cannot be written', () => {
    vi.spyOn(Storage.prototype, 'setItem').mockImplementation(() => {
      throw new DOMException('quota exceeded')
    })

    expect(devicePreferences.toggleFavorite('offer-a')).toEqual([])
  })
})
