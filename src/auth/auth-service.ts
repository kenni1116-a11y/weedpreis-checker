export type AuthUser = {
  id: string
  username: string
  email: string
  emailVerified: boolean
  aal: 'aal1' | 'aal2'
}

export type TotpFactor = {
  id: string
  friendlyName: string
  status: 'unverified' | 'verified'
}

export type AuthState =
  | { status: 'loading' }
  | { status: 'signed-out' }
  | { status: 'verification-required'; email: string }
  | { status: 'mfa-required'; email: string; factors: TotpFactor[] }
  | { status: 'signed-in'; user: AuthUser }
  | { status: 'error'; message: string }

export type RegistrationInput = {
  username: string
  email: string
  password: string
  adultConfirmed: true
  privacyVersion: string
  termsVersion: string
}

export type EmailChangeInput = {
  email: string
  currentPassword: string
}

export type TotpEnrollment = {
  factorId: string
  qrCode: string
  secret: string
}

export type TotpVerificationInput = {
  factorId: string
  code: string
}

export type UnenrollTotpInput = {
  factorId: string
  currentPassword: string
}

export type SensitiveActionProof = {
  currentPassword: string
  totpCode?: string
}

export type DeleteAccountInput = SensitiveActionProof & {
  usernameConfirmation: string
}

export type AccountExport = {
  exportedAt: string
  account: Pick<AuthUser, 'id' | 'username' | 'email' | 'emailVerified'>
  consents: Array<{
    kind: 'privacy' | 'terms' | 'adult'
    version: string
    acceptedAt: string
  }>
  inventory: Array<{
    id: string
    entityId: string
    canonicalName: string
    quantity: number
    unit: 'g' | 'ml' | 'piece'
    batch: string | null
    expiresOn: string | null
    storageLocation: string | null
    note: string | null
    createdAt: string
    updatedAt: string
  }>
  communityFlowerContributions: Array<{
    cultivarId: string
    cultivarName: string
    thcPercent: number
    cbdPercent: number
    sourceKind: CommunityValueSource
    consentVersion: string
    createdAt: string
    updatedAt: string
  }>
}

export interface AuthService {
  currentState(): Promise<AuthState>
  subscribe(listener: (state: AuthState) => void): () => void
  register(input: RegistrationInput): Promise<'verification-sent'>
  login(input: { email: string; password: string }): Promise<void>
  requestPasswordRecovery(email: string): Promise<void>
  updateRecoveredPassword(password: string): Promise<void>
  changeEmail(input: EmailChangeInput): Promise<'verification-sent'>
  enrollTotp(): Promise<TotpEnrollment>
  listTotpFactors(): Promise<TotpFactor[]>
  verifyTotp(input: TotpVerificationInput): Promise<void>
  unenrollTotp(input: UnenrollTotpInput): Promise<void>
  logout(): Promise<void>
  exportAccount(proof: SensitiveActionProof): Promise<AccountExport>
  deleteAccount(input: DeleteAccountInput): Promise<void>
}
import type { CommunityValueSource } from '../community/community-values'
