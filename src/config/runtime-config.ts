export type RuntimeConfig = {
  supabaseUrl: string
  supabasePublishableKey: string
  privacyVersion: string
  termsVersion: string
  authRedirectUrl: string
}

type RuntimeEnv = Record<string, string | undefined>

function required(env: RuntimeEnv, key: string): string {
  const value = env[key]?.trim()
  if (!value) throw new Error(`Missing ${key}`)
  return value
}

function absoluteUrl(env: RuntimeEnv, key: string): string {
  const value = required(env, key)
  if (!URL.canParse(value)) throw new Error(`Invalid ${key}`)
  const url = new URL(value)
  if (url.protocol !== 'http:' && url.protocol !== 'https:') {
    throw new Error(`Invalid ${key}`)
  }
  return value
}

export function readRuntimeConfig(env: RuntimeEnv): RuntimeConfig {
  const supabasePublishableKey = required(env, 'VITE_SUPABASE_PUBLISHABLE_KEY')
  if (supabasePublishableKey.startsWith('sb_secret_')) {
    throw new Error('Invalid VITE_SUPABASE_PUBLISHABLE_KEY')
  }

  return {
    supabaseUrl: absoluteUrl(env, 'VITE_SUPABASE_URL'),
    supabasePublishableKey,
    privacyVersion: required(env, 'VITE_PRIVACY_VERSION'),
    termsVersion: required(env, 'VITE_TERMS_VERSION'),
    authRedirectUrl: absoluteUrl(env, 'VITE_AUTH_REDIRECT_URL'),
  }
}
