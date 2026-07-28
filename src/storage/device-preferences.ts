const FAVORITES_KEY = 'weedpreis.favorites'

function getStorage(): Storage | undefined {
  try {
    return globalThis.localStorage
  } catch {
    return undefined
  }
}

export const devicePreferences = {
  getFavoriteIds(): string[] {
    try {
      const value: unknown = JSON.parse(getStorage()?.getItem(FAVORITES_KEY) ?? '[]')
      if (!Array.isArray(value) || !value.every((id): id is string => typeof id === 'string')) {
        return []
      }
      return [...new Set(value)]
    } catch {
      return []
    }
  },
  toggleFavorite(id: string): string[] {
    const ids = new Set(this.getFavoriteIds())

    if (ids.has(id)) {
      ids.delete(id)
    } else {
      ids.add(id)
    }

    const result = [...ids]
    try {
      const storage = getStorage()
      if (!storage) return []
      storage.setItem(FAVORITES_KEY, JSON.stringify(result))
      return result
    } catch {
      return []
    }
  },
}
