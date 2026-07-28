import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useAuth } from '../../auth/useAuth'

type LoginFormProps = {
  onShowRegister: () => void
  onShowRecovery: () => void
}

export function LoginForm({
  onShowRegister,
  onShowRecovery,
}: LoginFormProps) {
  const { service } = useAuth()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const errorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPending(true)
    setError('')
    try {
      await service.login({ email, password })
      setPassword('')
    } catch (cause) {
      setError(
        cause instanceof Error
          ? cause.message
          : 'Anmeldung nicht möglich. Prüfe E-Mail-Adresse und Passwort.',
      )
      setPassword('')
    } finally {
      setPending(false)
    }
  }

  return (
    <section className="auth-panel" aria-labelledby="login-title">
      <h2 id="login-title">Anmelden</h2>
      {error && (
        <div ref={errorRef} role="alert" tabIndex={-1} className="error-summary">
          {error}
        </div>
      )}
      <form onSubmit={submit}>
        <label>
          E-Mail-Adresse
          <input
            type="email"
            autoComplete="email"
            value={email}
            onChange={(event) => setEmail(event.currentTarget.value)}
            required
          />
        </label>
        <label>
          Passwort
          <input
            type="password"
            autoComplete="current-password"
            value={password}
            onChange={(event) => setPassword(event.currentTarget.value)}
            required
          />
        </label>
        <button type="submit" disabled={pending}>
          {pending ? 'Anmeldung läuft …' : 'Anmelden'}
        </button>
      </form>
      <div className="auth-secondary-actions">
        <button type="button" onClick={onShowRegister}>
          Konto erstellen
        </button>
        <button type="button" onClick={onShowRecovery}>
          Passwort vergessen
        </button>
      </div>
    </section>
  )
}
