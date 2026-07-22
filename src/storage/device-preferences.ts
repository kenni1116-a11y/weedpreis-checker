const ADULT_KEY = 'weedpreis.adult'
const FAVORITES_KEY = 'weedpreis.favorites'

export const devicePreferences = {
  isAdultConfirmed: () => localStorage.getItem(ADULT_KEY) === 'true',
  confirmAdult: () => localStorage.setItem(ADULT_KEY, 'true'),
  getFavoriteIds: (): string[] => JSON.parse(localStorage.getItem(FAVORITES_KEY) ?? '[]'),
  toggleFavorite(id: string): string[] {
    const ids = new Set(this.getFavoriteIds())

    if (ids.has(id)) {
      ids.delete(id)
    } else {
      ids.add(id)
    }

    const result = [...ids]
    localStorage.setItem(FAVORITES_KEY, JSON.stringify(result))
    return result
  },
}
