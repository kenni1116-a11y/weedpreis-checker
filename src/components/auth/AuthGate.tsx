import { useState, type ReactNode } from 'react'
import { useAuth } from '../../auth/useAuth'
import { EmailVerificationNotice } from './EmailVerificationNotice'
import { LoginForm } from './LoginForm'
import { MfaChallenge } from './MfaChallenge'
import { RecoveryForm } from './RecoveryForm'
import { RegisterForm } from './RegisterForm'
import { UpdatePasswordForm } from './UpdatePasswordForm'

type SignedOutView = 'login' | 'register' | 'recovery'

type AuthGateProps = {
  privacyVersion: string
  termsVersion: string
  children: ReactNode
}

function isPasswordRecoveryCallback(): boolean {
  if (!window.location.pathname.endsWith('/auth/callback')) return false
  const search = new URLSearchParams(window.location.search)
  const hash = new URLSearchParams(window.location.hash.replace(/^#/, ''))
  return search.get('type') === 'recovery' || hash.get('type') === 'recovery'
}

export function AuthGate({
  privacyVersion,
  termsVersion,
  children,
}: AuthGateProps) {
  const { state } = useAuth()
  const [view, setView] = useState<SignedOutView>('login')
  const [verificationEmail, setVerificationEmail] = useState('')

  if (state.status === 'loading') {
    return (
      <p role="status" aria-label="Kontostatus wird geladen">
        Kontostatus wird geladen …
      </p>
    )
  }

  if (state.status === 'error') {
    return <div role="alert">{state.message}</div>
  }

  if (state.status === 'verification-required') {
    return <EmailVerificationNotice email={state.email} />
  }

  if (state.status === 'mfa-required') {
    return <MfaChallenge factors={state.factors} />
  }

  if (state.status === 'signed-in') {
    if (isPasswordRecoveryCallback()) return <UpdatePasswordForm />
    return <>{children}</>
  }

  if (verificationEmail) {
    return (
      <EmailVerificationNotice
        email={verificationEmail}
        onBackToLogin={() => {
          setVerificationEmail('')
          setView('login')
        }}
      />
    )
  }

  if (view === 'register') {
    return (
      <RegisterForm
        privacyVersion={privacyVersion}
        termsVersion={termsVersion}
        onVerificationSent={setVerificationEmail}
        onBackToLogin={() => setView('login')}
      />
    )
  }

  if (view === 'recovery') {
    return <RecoveryForm onBackToLogin={() => setView('login')} />
  }

  return (
    <LoginForm
      onShowRegister={() => setView('register')}
      onShowRecovery={() => setView('recovery')}
    />
  )
}
