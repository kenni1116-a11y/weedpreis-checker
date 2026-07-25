import type {
  AccountExport,
  AuthService,
  AuthState,
  DeleteAccountInput,
  EmailChangeInput,
  RegistrationInput,
  SensitiveActionProof,
  TotpEnrollment,
  TotpFactor,
  TotpVerificationInput,
  UnenrollTotpInput,
} from './auth-service'

type InMemoryAuthOptions = {
  initialState?: AuthState
  factors?: TotpFactor[]
  accountExport?: AccountExport
}

type LoginInput = { email: string; password: string }

type InMemoryCalls = {
  register: RegistrationInput[]
  login: LoginInput[]
  requestPasswordRecovery: string[]
  updateRecoveredPassword: string[]
  changeEmail: EmailChangeInput[]
  enrollTotp: number
  listTotpFactors: number
  verifyTotp: TotpVerificationInput[]
  unenrollTotp: UnenrollTotpInput[]
  logout: number
  exportAccount: SensitiveActionProof[]
  deleteAccount: DeleteAccountInput[]
}

function assertSyntheticEmail(email: string): void {
  const domain = email.trim().toLowerCase().split('@')[1] ?? ''
  if (!domain.endsWith('.invalid')) {
    throw new Error('In-memory Auth accepts synthetic .invalid emails only.')
  }
}

function validateState(state: AuthState): void {
  if (
    state.status === 'verification-required'
    || state.status === 'mfa-required'
  ) {
    assertSyntheticEmail(state.email)
  }
  if (state.status === 'signed-in') {
    assertSyntheticEmail(state.user.email)
  }
}

function defaultExport(): AccountExport {
  return {
    exportedAt: '2026-07-25T00:00:00.000Z',
    account: {
      id: 'synthetic-user',
      username: 'Test.User',
      email: 'test-user@example.invalid',
      emailVerified: true,
    },
    consents: [],
    inventory: [],
  }
}

export class InMemoryAuthService implements AuthService {
  readonly calls: InMemoryCalls = {
    register: [],
    login: [],
    requestPasswordRecovery: [],
    updateRecoveredPassword: [],
    changeEmail: [],
    enrollTotp: 0,
    listTotpFactors: 0,
    verifyTotp: [],
    unenrollTotp: [],
    logout: 0,
    exportAccount: [],
    deleteAccount: [],
  }

  readonly #listeners = new Set<(state: AuthState) => void>()
  readonly #factors: TotpFactor[]
  readonly #accountExport: AccountExport
  #state: AuthState

  constructor(options: InMemoryAuthOptions = {}) {
    this.#state = options.initialState ?? { status: 'signed-out' }
    validateState(this.#state)
    this.#factors = structuredClone(options.factors ?? [])
    this.#accountExport = structuredClone(
      options.accountExport ?? defaultExport(),
    )
  }

  setState(state: AuthState): void {
    validateState(state)
    this.#state = structuredClone(state)
    for (const listener of this.#listeners) {
      listener(structuredClone(this.#state))
    }
  }

  async currentState(): Promise<AuthState> {
    return structuredClone(this.#state)
  }

  subscribe(listener: (state: AuthState) => void): () => void {
    this.#listeners.add(listener)
    return () => this.#listeners.delete(listener)
  }

  async register(
    input: RegistrationInput,
  ): Promise<'verification-sent'> {
    assertSyntheticEmail(input.email)
    this.calls.register.push(structuredClone(input))
    return 'verification-sent'
  }

  async login(input: LoginInput): Promise<void> {
    assertSyntheticEmail(input.email)
    this.calls.login.push(structuredClone(input))
  }

  async requestPasswordRecovery(email: string): Promise<void> {
    assertSyntheticEmail(email)
    this.calls.requestPasswordRecovery.push(email)
  }

  async updateRecoveredPassword(password: string): Promise<void> {
    this.calls.updateRecoveredPassword.push(password)
  }

  async changeEmail(
    input: EmailChangeInput,
  ): Promise<'verification-sent'> {
    assertSyntheticEmail(input.email)
    this.calls.changeEmail.push(structuredClone(input))
    return 'verification-sent'
  }

  async enrollTotp(): Promise<TotpEnrollment> {
    this.calls.enrollTotp += 1
    return {
      factorId: 'synthetic-factor',
      qrCode: '<svg aria-label="synthetic QR code"></svg>',
      secret: 'SYNTHETICSECRET',
    }
  }

  async listTotpFactors(): Promise<TotpFactor[]> {
    this.calls.listTotpFactors += 1
    return structuredClone(this.#factors)
  }

  async verifyTotp(input: TotpVerificationInput): Promise<void> {
    this.calls.verifyTotp.push(structuredClone(input))
  }

  async unenrollTotp(input: UnenrollTotpInput): Promise<void> {
    this.calls.unenrollTotp.push(structuredClone(input))
  }

  async logout(): Promise<void> {
    this.calls.logout += 1
    this.setState({ status: 'signed-out' })
  }

  async exportAccount(
    proof: SensitiveActionProof,
  ): Promise<AccountExport> {
    this.calls.exportAccount.push(structuredClone(proof))
    return structuredClone(this.#accountExport)
  }

  async deleteAccount(input: DeleteAccountInput): Promise<void> {
    this.calls.deleteAccount.push(structuredClone(input))
    this.setState({ status: 'signed-out' })
  }
}

export function createInMemoryAuthService(
  options: InMemoryAuthOptions = {},
): InMemoryAuthService {
  return new InMemoryAuthService(options)
}
