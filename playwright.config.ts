import { existsSync, readFileSync } from 'node:fs'
import { resolve } from 'node:path'
import { defineConfig, devices } from '@playwright/test'

const statusPath = resolve('supabase/.temp/status.env')

function parseStatusEnv(source: string): Record<string, string> {
  const values: Record<string, string> = {}
  for (const line of source.split(/\r?\n/)) {
    const match = /^([A-Z][A-Z0-9_]*)=(.*)$/.exec(line.trim())
    if (!match) continue
    let value = match[2].trim()
    if (
      (value.startsWith('"') && value.endsWith('"'))
      || (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1)
    }
    values[match[1]] = value
  }
  return values
}

if (!existsSync(statusPath)) {
  throw new Error(
    'Missing supabase/.temp/status.env. Start local Supabase and write a fresh status file before Playwright.',
  )
}

const status = parseStatusEnv(readFileSync(statusPath, 'utf8'))
const apiUrl = status.API_URL?.trim()
const anonKey = status.ANON_KEY?.trim()

if (!apiUrl || !anonKey) {
  throw new Error(
    'supabase/.temp/status.env must contain non-empty API_URL and ANON_KEY values.',
  )
}
if (anonKey.startsWith('sb_secret_')) {
  throw new Error('Refusing to pass a secret key to the browser.')
}
if (status.SERVICE_ROLE_KEY && anonKey === status.SERVICE_ROLE_KEY) {
  throw new Error('Refusing to pass a service-role key to the browser.')
}

process.env.E2E_SUPABASE_API_URL = apiUrl
process.env.E2E_SUPABASE_ANON_KEY = anonKey

export default defineConfig({
  testDir: './tests/e2e',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: process.env.CI
    ? [['line'], ['html', { open: 'never' }]]
    : 'list',
  use: {
    baseURL: 'http://127.0.0.1:4173',
    ...devices['iPhone 14'],
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },
  webServer: {
    command: 'pnpm build && pnpm vite preview --host 127.0.0.1',
    port: 4173,
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
    env: {
      VITE_SUPABASE_URL: apiUrl,
      VITE_SUPABASE_PUBLISHABLE_KEY: anonKey,
      VITE_PRIVACY_VERSION: 'weedypedia-privacy-2026-07-25',
      VITE_TERMS_VERSION: 'weedypedia-terms-2026-07-25',
      VITE_AUTH_REDIRECT_URL: 'http://127.0.0.1:4173/auth/callback',
    },
  },
})
