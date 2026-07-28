import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, describe, expect, it, vi } from 'vitest'
import type { AuthState } from '../auth/auth-service'
import { createInMemoryAuthService } from '../auth/in-memory-auth-service'
import type { RuntimeConfig } from '../config/runtime-config'
import { InMemoryInventoryRepository } from '../inventory/in-memory-inventory-repository'
import { App } from './App'

const config: RuntimeConfig = {
  supabaseUrl: 'https://example.supabase.co',
  supabasePublishableKey: 'sb_publishable_test',
  privacyVersion: 'weedypedia-privacy-2026-07-25',
  termsVersion: 'weedypedia-terms-2026-07-25',
  communityValuesConsentVersion:
    'weedypedia-community-values-2026-07-28',
  authRedirectUrl: 'https://example.invalid/auth/callback',
}

const signedInState: AuthState = {
  status: 'signed-in',
  user: {
    id: 'synthetic-user',
    username: 'Test.User',
    email: 'test@example.invalid',
    emailVerified: true,
    aal: 'aal2',
  },
}

function renderApp(state: AuthState) {
  const authService = createInMemoryAuthService({
    initialState: state,
    factors: state.status === 'mfa-required' ? state.factors : [],
  })
  const inventoryRepository = new InMemoryInventoryRepository()
  return {
    authService,
    inventoryRepository,
    ...render(
      <App
        authService={authService}
        inventoryRepository={inventoryRepository}
        config={config}
      />,
    ),
  }
}

describe('App', () => {
  afterEach(() => {
    cleanup()
    localStorage.clear()
    vi.restoreAllMocks()
  })

  it('identifies itself as Weedypedia after authentication', async () => {
    renderApp(signedInState)

    expect(await screen.findByRole(
      'heading',
      { name: 'Weedypedia' },
    )).toBeInTheDocument()
    expect(screen.getByText(
      'Sorten, Herkunft und Produkte nachvollziehbar verbunden',
    )).toBeInTheDocument()
  })

  it('keeps inventory behind verified authentication', async () => {
    localStorage.setItem('weedpreis.adult', 'true')
    renderApp({ status: 'signed-out' })

    expect(await screen.findByRole(
      'heading',
      { name: 'Bei Weedypedia anmelden' },
    )).toBeInTheDocument()
    expect(screen.queryByRole(
      'button',
      { name: 'Bestand' },
    )).not.toBeInTheDocument()
  })

  it('announces session loading before rendering the shell', () => {
    const authService = createInMemoryAuthService()
    vi.spyOn(authService, 'currentState').mockReturnValue(
      new Promise(() => undefined),
    )
    render(
      <App
        authService={authService}
        inventoryRepository={new InMemoryInventoryRepository()}
        config={config}
      />,
    )

    expect(screen.getByRole(
      'status',
      { name: 'Kontostatus wird geladen' },
    )).toBeInTheDocument()
    expect(screen.queryByRole(
      'heading',
      { name: 'Weedypedia' },
    )).not.toBeInTheDocument()
  })

  it('keeps the shell closed until email verification completes', async () => {
    renderApp({
      status: 'verification-required',
      email: 'test@example.invalid',
    })

    expect(await screen.findByRole(
      'heading',
      { name: 'Verifizierungsnachricht versendet' },
    )).toBeInTheDocument()
    expect(screen.queryByRole(
      'navigation',
      { name: 'Hauptnavigation' },
    )).not.toBeInTheDocument()
  })

  it('requires TOTP before showing private tabs', async () => {
    renderApp({
      status: 'mfa-required',
      email: 'test@example.invalid',
      factors: [{
        id: 'factor-1',
        friendlyName: 'Weedypedia',
        status: 'verified',
      }],
    })

    expect(await screen.findByRole(
      'heading',
      { name: 'Zwei-Faktor-Bestätigung' },
    )).toBeInTheDocument()
    expect(screen.queryByRole(
      'button',
      { name: 'Bestand' },
    )).not.toBeInTheDocument()
  })

  it('opens the private inventory and account profile tabs', async () => {
    renderApp(signedInState)
    const user = userEvent.setup()

    await user.click(await screen.findByRole(
      'button',
      { name: 'Bestand' },
    ))
    expect(await screen.findByRole(
      'heading',
      { name: 'Mein Bestand' },
    )).toBeInTheDocument()

    await user.click(screen.getByRole('button', { name: 'Profil' }))
    expect(await screen.findByRole(
      'region',
      { name: 'Privates Konto' },
    )).toBeInTheDocument()
  })

  it.each(['Entdecken', 'Suche'])(
    'marks the %s knowledge area as the next sourced stage',
    async (tab) => {
      renderApp(signedInState)
      const user = userEvent.setup()

      await user.click(await screen.findByRole('button', { name: tab }))

      expect(screen.getByText(
        'Der nachweisbare Weedypedia-Wissenskatalog wird in der nächsten freigegebenen Etappe verbunden. Konto und persönlicher Bestand sind bereits getrennt abgesichert.',
      )).toBeInTheDocument()
      expect(screen.queryByText(/Apothekenvergleich/)).not.toBeInTheDocument()
    },
  )
})
