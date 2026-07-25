import { describe, expect, it, vi } from 'vitest'
import type { RuntimeConfig } from '../config/runtime-config'
import { createSupabaseAuthService } from './supabase-auth-service'

const config: RuntimeConfig = {
  supabaseUrl: 'https://project.supabase.co',
  supabasePublishableKey: 'sb_publishable_test',
  privacyVersion: 'weedypedia-privacy-2026-07-25',
  termsVersion: 'weedypedia-terms-2026-07-25',
  authRedirectUrl: 'https://example.invalid/auth/callback',
}

const activeSession = {
  access_token: 'active-token',
  user: {
    id: 'user-1',
    email: 'user@example.invalid',
    email_confirmed_at: '2026-07-25T12:00:00Z',
  },
}

type QueryResult = {
  data: unknown
  error: null | { message: string }
}

function query(result: QueryResult) {
  const promise = Promise.resolve(result)
  const builder = {
    select: vi.fn(),
    eq: vi.fn(),
    order: vi.fn(),
    single: vi.fn(() => promise),
    maybeSingle: vi.fn(() => promise),
    then: promise.then.bind(promise),
  }
  builder.select.mockReturnValue(builder)
  builder.eq.mockReturnValue(builder)
  builder.order.mockReturnValue(builder)
  return builder
}

function client(overrides: Record<string, unknown> = {}) {
  const profile = query({ data: { username: 'User.One' }, error: null })
  const receipts = query({ data: [], error: null })
  const inventory = query({ data: [], error: null })
  const from = vi.fn((table: string) => {
    if (table === 'profiles') return profile
    if (table === 'consent_receipts') return receipts
    return inventory
  })

  const auth = {
    signUp: vi.fn().mockResolvedValue({ data: {}, error: null }),
    signInWithPassword: vi.fn().mockResolvedValue({
      data: { user: activeSession.user, session: activeSession },
      error: null,
    }),
    getSession: vi.fn().mockResolvedValue({
      data: { session: activeSession },
      error: null,
    }),
    onAuthStateChange: vi.fn().mockReturnValue({
      data: { subscription: { unsubscribe: vi.fn() } },
    }),
    resetPasswordForEmail: vi.fn().mockResolvedValue({ data: {}, error: null }),
    updateUser: vi.fn().mockResolvedValue({ data: {}, error: null }),
    signOut: vi.fn().mockResolvedValue({ error: null }),
    mfa: {
      enroll: vi.fn().mockResolvedValue({
        data: {
          id: 'factor-1',
          totp: {
            qr_code: '<svg>qr</svg>',
            secret: 'TESTSECRET',
          },
        },
        error: null,
      }),
      listFactors: vi.fn().mockResolvedValue({
        data: { all: [], totp: [], phone: [] },
        error: null,
      }),
      getAuthenticatorAssuranceLevel: vi.fn().mockResolvedValue({
        data: { currentLevel: 'aal1', nextLevel: 'aal1' },
        error: null,
      }),
      challenge: vi.fn().mockResolvedValue({
        data: { id: 'challenge-1' },
        error: null,
      }),
      verify: vi.fn().mockResolvedValue({
        data: { session: activeSession },
        error: null,
      }),
      unenroll: vi.fn().mockResolvedValue({ data: {}, error: null }),
    },
  }
  const functions = {
    invoke: vi.fn().mockResolvedValue({ data: null, error: null }),
  }

  const result = { auth, from, functions, profile, receipts, inventory }
  Object.assign(result, overrides)
  return result
}

describe('createSupabaseAuthService', () => {
  it('sends only approved signup metadata and the configured callback', async () => {
    const active = client()
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await service.register({
      username: ' User.One ',
      email: ' User@Example.invalid ',
      password: 'very-safe-password',
      adultConfirmed: true,
      privacyVersion: config.privacyVersion,
      termsVersion: config.termsVersion,
    })

    expect(active.auth.signUp).toHaveBeenCalledWith({
      email: 'User@Example.invalid',
      password: 'very-safe-password',
      options: {
        emailRedirectTo: config.authRedirectUrl,
        data: {
          registration_username: 'User.One',
          adult_confirmed: true,
          privacy_version: config.privacyVersion,
          terms_version: config.termsVersion,
        },
      },
    })
  })

  it('maps credential failures to one non-enumerating login message', async () => {
    const active = client()
    active.auth.signInWithPassword.mockResolvedValue({
      data: { user: null, session: null },
      error: { message: 'User does not exist' },
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await expect(
      service.login({
        email: 'missing@example.invalid',
        password: 'wrong-password',
      }),
    ).rejects.toThrow('Anmeldung nicht möglich. Prüfe E-Mail-Adresse und Passwort.')
  })

  it('does not query personal API tables before a verified factor reaches AAL2', async () => {
    const active = client()
    active.auth.mfa.listFactors.mockResolvedValue({
      data: {
        all: [],
        phone: [],
        totp: [
          {
            id: 'factor-1',
            friendly_name: 'Weedypedia',
            factor_type: 'totp',
            status: 'verified',
          },
        ],
      },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await expect(service.currentState()).resolves.toEqual({
      status: 'mfa-required',
      email: 'user@example.invalid',
      factors: [
        {
          id: 'factor-1',
          friendlyName: 'Weedypedia',
          status: 'verified',
        },
      ],
    })
    expect(active.from).not.toHaveBeenCalled()
  })

  it('maps verified email explicitly and selects no email from the profile', async () => {
    const active = client()
    active.auth.mfa.getAuthenticatorAssuranceLevel.mockResolvedValue({
      data: { currentLevel: 'aal2', nextLevel: 'aal2' },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await expect(service.currentState()).resolves.toEqual({
      status: 'signed-in',
      user: {
        id: 'user-1',
        username: 'User.One',
        email: 'user@example.invalid',
        emailVerified: true,
        aal: 'aal2',
      },
    })
    expect(active.profile.select).toHaveBeenCalledWith('username')
    expect(active.profile.select.mock.calls.flat().join(' ')).not.toContain('email')
  })

  it('keeps password recovery responses non-enumerating', async () => {
    const active = client()
    active.auth.resetPasswordForEmail.mockResolvedValue({
      data: null,
      error: { message: 'Unknown email' },
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await expect(
      service.requestPasswordRecovery('missing@example.invalid'),
    ).resolves.toBeUndefined()
    expect(active.auth.resetPasswordForEmail).toHaveBeenCalledWith(
      'missing@example.invalid',
      { redirectTo: config.authRedirectUrl },
    )
  })

  it('updates a recovered password only after a PASSWORD_RECOVERY event', async () => {
    const active = client()
    let authListener:
      | ((event: string, session: typeof activeSession) => void)
      | undefined
    active.auth.onAuthStateChange.mockImplementation((listener) => {
      authListener = listener
      return { data: { subscription: { unsubscribe: vi.fn() } } }
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    service.subscribe(() => undefined)
    await expect(
      service.updateRecoveredPassword('new-safe-password'),
    ).rejects.toThrow('Der Wiederherstellungslink ist nicht aktiv.')

    authListener?.('PASSWORD_RECOVERY', activeSession)
    await service.updateRecoveredPassword('new-safe-password')

    expect(active.auth.updateUser).toHaveBeenCalledWith({
      password: 'new-safe-password',
    })
  })

  it('passes current password proof to Secure Email Change', async () => {
    const active = client()
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await service.changeEmail({
      email: 'new@example.invalid',
      currentPassword: 'current-password',
    })

    expect(active.auth.updateUser).toHaveBeenCalledWith({
      email: 'new@example.invalid',
      current_password: 'current-password',
    })
  })

  it('enrolls and lists only TOTP factors', async () => {
    const active = client()
    active.auth.mfa.listFactors.mockResolvedValue({
      data: {
        all: [],
        phone: [
          {
            id: 'phone-1',
            friendly_name: 'Phone',
            factor_type: 'phone',
            status: 'verified',
          },
        ],
        totp: [
          {
            id: 'factor-1',
            friendly_name: 'Weedypedia',
            factor_type: 'totp',
            status: 'verified',
          },
        ],
      },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => client(),
      config,
    })

    await expect(service.enrollTotp()).resolves.toEqual({
      factorId: 'factor-1',
      qrCode: '<svg>qr</svg>',
      secret: 'TESTSECRET',
    })
    await expect(service.listTotpFactors()).resolves.toEqual([
      {
        id: 'factor-1',
        friendlyName: 'Weedypedia',
        status: 'verified',
      },
    ])
    expect(active.auth.mfa.enroll).toHaveBeenCalledWith({
      factorType: 'totp',
      friendlyName: 'Weedypedia',
    })
  })

  it('requires active AAL2 and isolated password proof before factor removal', async () => {
    const active = client()
    const proof = client()
    active.auth.mfa.getAuthenticatorAssuranceLevel.mockResolvedValue({
      data: { currentLevel: 'aal2', nextLevel: 'aal2' },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => proof,
      config,
    })

    await service.unenrollTotp({
      factorId: 'factor-1',
      currentPassword: 'current-password',
    })

    expect(proof.auth.signInWithPassword).toHaveBeenCalledWith({
      email: 'user@example.invalid',
      password: 'current-password',
    })
    expect(active.auth.mfa.unenroll).toHaveBeenCalledWith({
      factorId: 'factor-1',
    })
    expect(proof.auth.signOut).toHaveBeenCalled()
  })

  it('exports only the approved account, consent, and inventory fields', async () => {
    const active = client()
    const proof = client()
    proof.profile = query({ data: { username: 'User.One' }, error: null })
    proof.receipts = query({
      data: [
        {
          kind: 'privacy',
          version: config.privacyVersion,
          accepted_at: '2026-07-25T12:00:00Z',
        },
      ],
      error: null,
    })
    proof.inventory = query({
      data: [
        {
          id: 'item-1',
          entity_id: 'entity-1',
          quantity: 2.5,
          unit: 'g',
          batch: null,
          expires_on: null,
          storage_location: 'Schrank',
          note: null,
          created_at: '2026-07-25T12:00:00Z',
          updated_at: '2026-07-25T12:00:00Z',
          catalog_references: { canonical_name: 'Test-Cultivar' },
        },
      ],
      error: null,
    })
    proof.from.mockImplementation((table: string) => {
      if (table === 'profiles') return proof.profile
      if (table === 'consent_receipts') return proof.receipts
      return proof.inventory
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => proof,
      config,
      now: () => new Date('2026-07-25T13:00:00Z'),
    })

    const exported = await service.exportAccount({
      currentPassword: 'current-password',
    })

    expect(exported).toEqual({
      exportedAt: '2026-07-25T13:00:00.000Z',
      account: {
        id: 'user-1',
        username: 'User.One',
        email: 'user@example.invalid',
        emailVerified: true,
      },
      consents: [
        {
          kind: 'privacy',
          version: config.privacyVersion,
          acceptedAt: '2026-07-25T12:00:00Z',
        },
      ],
      inventory: [
        {
          id: 'item-1',
          entityId: 'entity-1',
          canonicalName: 'Test-Cultivar',
          quantity: 2.5,
          unit: 'g',
          batch: null,
          expiresOn: null,
          storageLocation: 'Schrank',
          note: null,
          createdAt: '2026-07-25T12:00:00Z',
          updatedAt: '2026-07-25T12:00:00Z',
        },
      ],
    })
    expect(JSON.stringify(exported)).not.toMatch(
      /password|access_token|raw_user_meta_data|role/i,
    )
    expect(proof.auth.signOut).toHaveBeenCalled()
  })

  it('uses only the isolated fresh session for deletion and clears the active session', async () => {
    const active = client()
    const proof = client()
    proof.auth.getSession.mockResolvedValue({
      data: {
        session: {
          ...activeSession,
          access_token: 'fresh-proof-token',
        },
      },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => proof,
      config,
    })

    await service.deleteAccount({
      usernameConfirmation: 'user.one',
      currentPassword: 'current-password',
    })

    expect(proof.functions.invoke).toHaveBeenCalledWith('account-delete', {
      method: 'DELETE',
      headers: {
        Authorization: 'Bearer fresh-proof-token',
      },
    })
    expect(active.functions.invoke).not.toHaveBeenCalled()
    expect(active.auth.signOut).toHaveBeenCalled()
    expect(proof.auth.signOut).toHaveBeenCalled()
  })

  it('requires a fresh TOTP challenge for deletion when the proof account has TOTP', async () => {
    const active = client()
    const proof = client()
    proof.auth.mfa.listFactors.mockResolvedValue({
      data: {
        all: [],
        phone: [],
        totp: [
          {
            id: 'factor-1',
            friendly_name: 'Weedypedia',
            factor_type: 'totp',
            status: 'verified',
          },
        ],
      },
      error: null,
    })
    proof.auth.getSession.mockResolvedValue({
      data: {
        session: {
          ...activeSession,
          access_token: 'fresh-aal2-token',
        },
      },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => proof,
      config,
    })

    await expect(
      service.deleteAccount({
        usernameConfirmation: 'user.one',
        currentPassword: 'current-password',
      }),
    ).rejects.toThrow('sichere Kontoaktion')

    await service.deleteAccount({
      usernameConfirmation: 'user.one',
      currentPassword: 'current-password',
      totpCode: '123456',
    })

    expect(proof.auth.mfa.challenge).toHaveBeenCalledWith({
      factorId: 'factor-1',
    })
    expect(proof.auth.mfa.verify).toHaveBeenCalledWith({
      factorId: 'factor-1',
      challengeId: 'challenge-1',
      code: '123456',
    })
  })

  it('rejects an isolated password proof that belongs to another user', async () => {
    const active = client()
    const proof = client()
    proof.auth.signInWithPassword.mockResolvedValue({
      data: {
        user: {
          ...activeSession.user,
          id: 'different-user',
        },
        session: activeSession,
      },
      error: null,
    })
    const service = createSupabaseAuthService({
      client: active,
      createProofClient: () => proof,
      config,
    })

    await expect(
      service.exportAccount({ currentPassword: 'current-password' }),
    ).rejects.toThrow('sichere Kontoaktion')
    expect(proof.from).not.toHaveBeenCalled()
    expect(proof.auth.signOut).toHaveBeenCalled()
  })
})
