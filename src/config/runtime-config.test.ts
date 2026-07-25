import { describe, expect, it } from 'vitest'
import { readRuntimeConfig } from './runtime-config'

const valid = {
  VITE_SUPABASE_URL: 'https://project.supabase.co',
  VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_publishable_test',
  VITE_PRIVACY_VERSION: 'weedypedia-privacy-2026-07-25',
  VITE_TERMS_VERSION: 'weedypedia-terms-2026-07-25',
  VITE_AUTH_REDIRECT_URL: 'https://example.invalid/auth/callback',
}

describe('readRuntimeConfig', () => {
  it('returns only complete browser-safe configuration', () => {
    expect(readRuntimeConfig(valid)).toEqual({
      supabaseUrl: 'https://project.supabase.co',
      supabasePublishableKey: 'sb_publishable_test',
      privacyVersion: 'weedypedia-privacy-2026-07-25',
      termsVersion: 'weedypedia-terms-2026-07-25',
      authRedirectUrl: 'https://example.invalid/auth/callback',
    })
  })

  it.each(Object.keys(valid))('rejects missing %s', (key) => {
    expect(() => readRuntimeConfig({ ...valid, [key]: '' })).toThrow(key)
  })

  it.each([
    ['VITE_SUPABASE_URL', 'not-a-url'],
    ['VITE_AUTH_REDIRECT_URL', '/relative/callback'],
  ])('rejects malformed %s', (key, value) => {
    expect(() => readRuntimeConfig({ ...valid, [key]: value })).toThrow(key)
  })

  it('rejects a secret key in browser configuration', () => {
    expect(() =>
      readRuntimeConfig({
        ...valid,
        VITE_SUPABASE_PUBLISHABLE_KEY: 'sb_secret_never_in_browser',
      }),
    ).toThrow('VITE_SUPABASE_PUBLISHABLE_KEY')
  })
})
