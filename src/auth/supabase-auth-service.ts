import { createClient } from '@supabase/supabase-js'
import type { RuntimeConfig } from '../config/runtime-config'
import type {
  AccountExport,
  AuthService,
  AuthState,
  AuthUser,
  DeleteAccountInput,
  EmailChangeInput,
  RegistrationInput,
  SensitiveActionProof,
  TotpEnrollment,
  TotpFactor,
  TotpVerificationInput,
  UnenrollTotpInput,
} from './auth-service'

type ServiceError = { message: string } | null

type AuthSession = {
  access_token: string
  user: {
    id: string
    email?: string
    email_confirmed_at?: string | null
  }
}

type AuthFactor = {
  id: string
  friendly_name?: string | null
  factor_type?: string
  status: 'unverified' | 'verified'
}

type QueryPort = {
  select(columns: string): QueryPort
  eq(column: string, value: unknown): QueryPort
  order(
    column: string,
    options?: { ascending?: boolean },
  ): QueryPort
  single(): Promise<{ data: unknown; error: ServiceError }>
  maybeSingle(): Promise<{ data: unknown; error: ServiceError }>
}

export type SupabaseClientPort = {
  auth: {
    signUp(input: {
      email: string
      password: string
      options: {
        emailRedirectTo: string
        data: Record<string, unknown>
      }
    }): Promise<{ data: unknown; error: ServiceError }>
    signInWithPassword(input: {
      email: string
      password: string
    }): Promise<{
      data: { user: AuthSession['user'] | null; session: AuthSession | null }
      error: ServiceError
    }>
    getSession(): Promise<{
      data: { session: AuthSession | null }
      error: ServiceError
    }>
    onAuthStateChange(
      listener: (event: string, session: AuthSession | null) => void,
    ): { data: { subscription: { unsubscribe(): void } } }
    resetPasswordForEmail(
      email: string,
      options: { redirectTo: string },
    ): Promise<{ data: unknown; error: ServiceError }>
    updateUser(
      attributes: Record<string, string>,
    ): Promise<{ data: unknown; error: ServiceError }>
    signOut(options?: {
      scope?: 'global' | 'local' | 'others'
    }): Promise<{ error: ServiceError }>
    mfa: {
      enroll(input: {
        factorType: 'totp'
        friendlyName: string
      }): Promise<{
        data: {
          id: string
          totp?: { qr_code: string; secret: string }
        } | null
        error: ServiceError
      }>
      listFactors(): Promise<{
        data: {
          all?: AuthFactor[]
          totp?: AuthFactor[]
          phone?: AuthFactor[]
        } | null
        error: ServiceError
      }>
      getAuthenticatorAssuranceLevel(): Promise<{
        data: {
          currentLevel: 'aal1' | 'aal2' | null
          nextLevel: 'aal1' | 'aal2' | null
        } | null
        error: ServiceError
      }>
      challenge(input: { factorId: string }): Promise<{
        data: { id: string } | null
        error: ServiceError
      }>
      verify(input: {
        factorId: string
        challengeId: string
        code: string
      }): Promise<{ data: unknown; error: ServiceError }>
      unenroll(input: {
        factorId: string
      }): Promise<{ data: unknown; error: ServiceError }>
    }
  }
  from(table: string): QueryPort
  functions: {
    invoke(
      functionName: string,
      options: {
        method: 'DELETE'
        headers: { Authorization: string }
      },
    ): Promise<{ data: unknown; error: ServiceError }>
  }
}

type SupabaseAuthServiceOptions = {
  client: SupabaseClientPort
  createProofClient: () => SupabaseClientPort
  config: RuntimeConfig
  now?: () => Date
}

type ProfileRow = {
  username: string
}

type ConsentRow = {
  kind: 'privacy' | 'terms' | 'adult'
  version: string
  accepted_at: string
}

type InventoryRow = {
  id: string
  entity_id: string
  quantity: number | string
  unit: 'g' | 'ml' | 'piece'
  batch: string | null
  expires_on: string | null
  storage_location: string | null
  note: string | null
  created_at: string
  updated_at: string
  catalog_references:
    | { canonical_name: string }
    | Array<{ canonical_name: string }>
    | null
}

const GENERIC_LOGIN_ERROR =
  'Anmeldung nicht möglich. Prüfe E-Mail-Adresse und Passwort.'
const GENERIC_AUTH_ERROR = 'Die sichere Kontoaktion konnte nicht abgeschlossen werden.'
const PASSWORD_MIN_LENGTH = 12
const PASSWORD_MAX_LENGTH = 128
const USERNAME_PATTERN = /^[A-Za-z0-9][A-Za-z0-9._-]{2,31}$/
const EMAIL_PATTERN = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

function ensureNoError(error: ServiceError, message = GENERIC_AUTH_ERROR): void {
  if (error) throw new Error(message)
}

function validatePassword(password: string): void {
  if (
    password.length < PASSWORD_MIN_LENGTH
    || password.length > PASSWORD_MAX_LENGTH
  ) {
    throw new Error('Das Passwort muss zwischen 12 und 128 Zeichen lang sein.')
  }
}

function validateEmail(email: string): string {
  const normalized = email.trim()
  if (!EMAIL_PATTERN.test(normalized)) {
    throw new Error('Bitte gib eine gültige E-Mail-Adresse ein.')
  }
  return normalized
}

function mapTotpFactors(
  data: { totp?: AuthFactor[] } | null,
): TotpFactor[] {
  return (data?.totp ?? [])
    .filter(
      (factor) =>
        factor.status === 'unverified' || factor.status === 'verified',
    )
    .map((factor) => ({
      id: factor.id,
      friendlyName: factor.friendly_name?.trim() || 'Weedypedia',
      status: factor.status,
    }))
}

async function executeQuery<T>(
  query: QueryPort,
): Promise<{ data: T; error: ServiceError }> {
  return query as unknown as Promise<{ data: T; error: ServiceError }>
}

function canonicalName(row: InventoryRow): string {
  if (Array.isArray(row.catalog_references)) {
    return row.catalog_references[0]?.canonical_name ?? ''
  }
  return row.catalog_references?.canonical_name ?? ''
}

class SupabaseAuthService implements AuthService {
  readonly #client: SupabaseClientPort
  readonly #createProofClient: () => SupabaseClientPort
  readonly #config: RuntimeConfig
  readonly #now: () => Date
  #recoverySessionActive = false

  constructor(options: SupabaseAuthServiceOptions) {
    this.#client = options.client
    this.#createProofClient = options.createProofClient
    this.#config = options.config
    this.#now = options.now ?? (() => new Date())
  }

  async currentState(): Promise<AuthState> {
    try {
      return await this.#loadCurrentState()
    } catch {
      return {
        status: 'error',
        message: 'Der Kontostatus konnte nicht sicher geladen werden.',
      }
    }
  }

  subscribe(listener: (state: AuthState) => void): () => void {
    const { data } = this.#client.auth.onAuthStateChange((event) => {
      if (event === 'PASSWORD_RECOVERY') this.#recoverySessionActive = true
      if (event === 'SIGNED_OUT') this.#recoverySessionActive = false
      globalThis.setTimeout(() => {
        void this.currentState().then(listener)
      }, 0)
    })
    return () => data.subscription.unsubscribe()
  }

  async register(input: RegistrationInput): Promise<'verification-sent'> {
    const username = input.username.trim()
    if (!USERNAME_PATTERN.test(username)) {
      throw new Error(
        'Der Benutzername benötigt 3 bis 32 Zeichen und darf Buchstaben, Zahlen, Punkt, Unterstrich oder Bindestrich enthalten.',
      )
    }
    const email = validateEmail(input.email)
    validatePassword(input.password)
    if (input.adultConfirmed !== true) {
      throw new Error('Die Bestätigung ab 18 Jahren ist erforderlich.')
    }
    if (
      input.privacyVersion !== this.#config.privacyVersion
      || input.termsVersion !== this.#config.termsVersion
    ) {
      throw new Error('Die rechtlichen Hinweise wurden aktualisiert. Bitte lade die Seite neu.')
    }

    const { error } = await this.#client.auth.signUp({
      email,
      password: input.password,
      options: {
        emailRedirectTo: this.#config.authRedirectUrl,
        data: {
          registration_username: username,
          adult_confirmed: input.adultConfirmed,
          privacy_version: input.privacyVersion,
          terms_version: input.termsVersion,
        },
      },
    })
    ensureNoError(error, 'Die Registrierung konnte nicht abgeschlossen werden.')
    return 'verification-sent'
  }

  async login(input: { email: string; password: string }): Promise<void> {
    const email = validateEmail(input.email)
    const { error } = await this.#client.auth.signInWithPassword({
      email,
      password: input.password,
    })
    ensureNoError(error, GENERIC_LOGIN_ERROR)
  }

  async requestPasswordRecovery(email: string): Promise<void> {
    const normalizedEmail = validateEmail(email)
    await this.#client.auth.resetPasswordForEmail(normalizedEmail, {
      redirectTo: this.#config.authRedirectUrl,
    })
  }

  async updateRecoveredPassword(password: string): Promise<void> {
    if (!this.#recoverySessionActive) {
      throw new Error('Der Wiederherstellungslink ist nicht aktiv.')
    }
    validatePassword(password)
    const { error } = await this.#client.auth.updateUser({ password })
    ensureNoError(error)
    this.#recoverySessionActive = false
  }

  async changeEmail(
    input: EmailChangeInput,
  ): Promise<'verification-sent'> {
    const email = validateEmail(input.email)
    const { error } = await this.#client.auth.updateUser({
      email,
      current_password: input.currentPassword,
    })
    ensureNoError(error)
    return 'verification-sent'
  }

  async enrollTotp(): Promise<TotpEnrollment> {
    const { data, error } = await this.#client.auth.mfa.enroll({
      factorType: 'totp',
      friendlyName: 'Weedypedia',
    })
    ensureNoError(error)
    if (!data?.totp) throw new Error(GENERIC_AUTH_ERROR)
    return {
      factorId: data.id,
      qrCode: data.totp.qr_code,
      secret: data.totp.secret,
    }
  }

  async listTotpFactors(): Promise<TotpFactor[]> {
    const { data, error } = await this.#client.auth.mfa.listFactors()
    ensureNoError(error)
    return mapTotpFactors(data)
  }

  async verifyTotp(input: TotpVerificationInput): Promise<void> {
    const { data: challenge, error: challengeError } =
      await this.#client.auth.mfa.challenge({ factorId: input.factorId })
    ensureNoError(challengeError)
    if (!challenge) throw new Error(GENERIC_AUTH_ERROR)

    const { error } = await this.#client.auth.mfa.verify({
      factorId: input.factorId,
      challengeId: challenge.id,
      code: input.code.trim(),
    })
    ensureNoError(error)
  }

  async unenrollTotp(input: UnenrollTotpInput): Promise<void> {
    const { data: aal, error: aalError } =
      await this.#client.auth.mfa.getAuthenticatorAssuranceLevel()
    ensureNoError(aalError)
    if (aal?.currentLevel !== 'aal2') {
      throw new Error('Zum Entfernen ist eine aktuelle Zwei-Faktor-Bestätigung erforderlich.')
    }

    const user = await this.#requireSignedInUser()
    const proofClient = this.#createProofClient()
    try {
      await this.#verifyPasswordOnly(
        proofClient,
        user,
        input.currentPassword,
      )
      const { error } = await this.#client.auth.mfa.unenroll({
        factorId: input.factorId,
      })
      ensureNoError(error)
    } finally {
      await proofClient.auth.signOut({ scope: 'local' }).catch(() => undefined)
    }
  }

  async logout(): Promise<void> {
    const { error } = await this.#client.auth.signOut({ scope: 'local' })
    ensureNoError(error)
  }

  async exportAccount(
    proof: SensitiveActionProof,
  ): Promise<AccountExport> {
    return this.#withFreshProof(proof, async (proofClient, user) => {
      const profileResult = await proofClient
        .from('profiles')
        .select('username')
        .eq('user_id', user.id)
        .single()
      ensureNoError(profileResult.error)
      const profile = profileResult.data as ProfileRow

      const receiptsResult = await executeQuery<ConsentRow[]>(
        proofClient
          .from('consent_receipts')
          .select('kind,version,accepted_at')
          .eq('user_id', user.id)
          .order('accepted_at', { ascending: true }),
      )
      ensureNoError(receiptsResult.error)

      const inventoryResult = await executeQuery<InventoryRow[]>(
        proofClient
          .from('inventory_items')
          .select(
            'id,entity_id,quantity,unit,batch,expires_on,storage_location,note,created_at,updated_at,catalog_references(canonical_name)',
          )
          .eq('user_id', user.id)
          .order('created_at', { ascending: true }),
      )
      ensureNoError(inventoryResult.error)

      return {
        exportedAt: this.#now().toISOString(),
        account: {
          id: user.id,
          username: profile.username,
          email: user.email,
          emailVerified: user.emailVerified,
        },
        consents: receiptsResult.data.map((receipt) => ({
          kind: receipt.kind,
          version: receipt.version,
          acceptedAt: receipt.accepted_at,
        })),
        inventory: inventoryResult.data.map((item) => ({
          id: item.id,
          entityId: item.entity_id,
          canonicalName: canonicalName(item),
          quantity: Number(item.quantity),
          unit: item.unit,
          batch: item.batch,
          expiresOn: item.expires_on,
          storageLocation: item.storage_location,
          note: item.note,
          createdAt: item.created_at,
          updatedAt: item.updated_at,
        })),
      }
    })
  }

  async deleteAccount(input: DeleteAccountInput): Promise<void> {
    const user = await this.#requireSignedInUser()
    if (input.usernameConfirmation.trim() !== user.username.trim().toLowerCase()) {
      throw new Error('Der normalisierte Benutzername stimmt nicht überein.')
    }

    await this.#withFreshProof(input, async (proofClient) => {
      const { data, error } = await proofClient.auth.getSession()
      ensureNoError(error)
      const accessToken = data.session?.access_token
      if (!accessToken) throw new Error(GENERIC_AUTH_ERROR)

      const deletion = await proofClient.functions.invoke('account-delete', {
        method: 'DELETE',
        headers: {
          Authorization: `Bearer ${accessToken}`,
        },
      })
      ensureNoError(deletion.error)
    })

    const { error } = await this.#client.auth.signOut({ scope: 'local' })
    ensureNoError(error)
  }

  async #loadCurrentState(): Promise<AuthState> {
    const { data, error } = await this.#client.auth.getSession()
    ensureNoError(error)
    const session = data.session
    if (!session) return { status: 'signed-out' }

    const email = session.user.email?.trim() ?? ''
    if (!session.user.email_confirmed_at) {
      return { status: 'verification-required', email }
    }

    const factors = await this.#loadTotpFactors(this.#client)
    const { data: aal, error: aalError } =
      await this.#client.auth.mfa.getAuthenticatorAssuranceLevel()
    ensureNoError(aalError)
    const currentLevel = aal?.currentLevel === 'aal2' ? 'aal2' : 'aal1'

    if (
      currentLevel === 'aal1'
      && factors.some((factor) => factor.status === 'verified')
    ) {
      return {
        status: 'mfa-required',
        email,
        factors: factors.filter((factor) => factor.status === 'verified'),
      }
    }

    const profileResult = await this.#client
      .from('profiles')
      .select('username')
      .eq('user_id', session.user.id)
      .single()
    ensureNoError(profileResult.error)
    const profile = profileResult.data as ProfileRow

    return {
      status: 'signed-in',
      user: {
        id: session.user.id,
        username: profile.username,
        email,
        emailVerified: Boolean(session.user.email_confirmed_at),
        aal: currentLevel,
      },
    }
  }

  async #loadTotpFactors(
    client: SupabaseClientPort,
  ): Promise<TotpFactor[]> {
    const { data, error } = await client.auth.mfa.listFactors()
    ensureNoError(error)
    return mapTotpFactors(data)
  }

  async #requireSignedInUser(): Promise<AuthUser> {
    const state = await this.#loadCurrentState()
    if (state.status !== 'signed-in') throw new Error(GENERIC_AUTH_ERROR)
    return state.user
  }

  async #verifyPasswordOnly(
    proofClient: SupabaseClientPort,
    user: AuthUser,
    currentPassword: string,
  ): Promise<void> {
    const signIn = await proofClient.auth.signInWithPassword({
      email: user.email,
      password: currentPassword,
    })
    if (signIn.error || signIn.data.user?.id !== user.id) {
      throw new Error(GENERIC_AUTH_ERROR)
    }
  }

  async #withFreshProof<T>(
    proof: SensitiveActionProof,
    action: (
      proofClient: SupabaseClientPort,
      user: AuthUser,
    ) => Promise<T>,
  ): Promise<T> {
    const user = await this.#requireSignedInUser()
    const proofClient = this.#createProofClient()
    try {
      await this.#verifyPasswordOnly(
        proofClient,
        user,
        proof.currentPassword,
      )
      const factors = await this.#loadTotpFactors(proofClient)
      const verifiedFactor = factors.find(
        (factor) => factor.status === 'verified',
      )
      if (verifiedFactor) {
        if (!proof.totpCode?.trim()) throw new Error(GENERIC_AUTH_ERROR)
        const challenge = await proofClient.auth.mfa.challenge({
          factorId: verifiedFactor.id,
        })
        ensureNoError(challenge.error)
        if (!challenge.data) throw new Error(GENERIC_AUTH_ERROR)
        const verification = await proofClient.auth.mfa.verify({
          factorId: verifiedFactor.id,
          challengeId: challenge.data.id,
          code: proof.totpCode.trim(),
        })
        ensureNoError(verification.error)
      }
      return await action(proofClient, user)
    } finally {
      await proofClient.auth.signOut({ scope: 'local' }).catch(() => undefined)
    }
  }
}

export function createSupabaseAuthService(
  options: SupabaseAuthServiceOptions,
): AuthService {
  return new SupabaseAuthService(options)
}

export function createBrowserSupabaseAuthService(
  config: RuntimeConfig,
): AuthService {
  const client = createClient(
    config.supabaseUrl,
    config.supabasePublishableKey,
    {
      db: { schema: 'api' },
      auth: {
        persistSession: true,
        autoRefreshToken: true,
        detectSessionInUrl: true,
      },
    },
  ) as unknown as SupabaseClientPort

  return createSupabaseAuthService({
    client,
    config,
    createProofClient: () =>
      createClient(
        config.supabaseUrl,
        config.supabasePublishableKey,
        {
          db: { schema: 'api' },
          auth: {
            persistSession: false,
            autoRefreshToken: false,
            detectSessionInUrl: false,
          },
        },
      ) as unknown as SupabaseClientPort,
  })
}
