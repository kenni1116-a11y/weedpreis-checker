import { beforeEach, describe, expect, it } from 'vitest'
import { devicePreferences } from './device-preferences'

describe('device preferences', () => {
  beforeEach(() => localStorage.clear())

  it('stores only an adult boolean and favorite IDs', () => {
    devicePreferences.confirmAdult()
    devicePreferences.toggleFavorite('offer-a')

    expect(Object.keys(localStorage).sort()).toEqual(['weedpreis.adult', 'weedpreis.favorites'])
    expect(devicePreferences.getFavoriteIds()).toEqual(['offer-a'])
  })
})
