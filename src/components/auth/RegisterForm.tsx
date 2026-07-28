import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useAuth } from '../../auth/useAuth'

type RegisterFormProps = {
  privacyVersion: string
  termsVersion: string
  onVerificationSent: (email: string) => void
  onBackToLogin: () => void
}

export function RegisterForm({
  privacyVersion,
  termsVersion,
  onVerificationSent,
  onBackToLogin,
}: RegisterFormProps) {
  const { service } = useAuth()
  const [username, setUsername] = useState('')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [adultConfirmed, setAdultConfirmed] = useState(false)
  const [privacyAccepted, setPrivacyAccepted] = useState(false)
  const [termsAccepted, setTermsAccepted] = useState(false)
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const errorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!adultConfirmed || !privacyAccepted || !termsAccepted) {
      setError('Bitte bestätige Alter, Datenschutz und Nutzungsbedingungen.')
      return
    }

    setPending(true)
    setError('')
    try {
      await service.register({
        username,
        email,
        password,
        adultConfirmed: true,
        privacyVersion,
        termsVersion,
      })
      setPassword('')
      onVerificationSent(email.trim())
    } catch (cause) {
      setPassword('')
      setError(
        cause instanceof Error
          ? cause.message
          : 'Die Registrierung konnte nicht abgeschlossen werden.',
      )
    } finally {
      setPending(false)
    }
  }

  return (
    <section className="auth-panel" aria-labelledby="register-title">
      <h2 id="register-title">Konto erstellen</h2>
      <p>
        Deine E-Mail bleibt privat und dient nur Anmeldung, Verifizierung,
        Wiederherstellung und Sicherheitsmeldungen. Öffentlich sichtbar ist
        nur dein pseudonymer Benutzername.
      </p>
      {error && (
        <div ref={errorRef} role="alert" tabIndex={-1} className="error-summary">
          {error}
        </div>
      )}
      <form onSubmit={submit}>
        <label>
          Pseudonymer Benutzername
          <input
            autoComplete="username"
            value={username}
            onChange={(event) => setUsername(event.currentTarget.value)}
            minLength={3}
            maxLength={32}
            pattern="[A-Za-z0-9][A-Za-z0-9._-]{2,31}"
            required
          />
        </label>
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
            autoComplete="new-password"
            value={password}
            onChange={(event) => setPassword(event.currentTarget.value)}
            minLength={12}
            maxLength={128}
            required
          />
        </label>
        <label className="checkbox-label">
          <input
            type="checkbox"
            checked={adultConfirmed}
            onChange={(event) => setAdultConfirmed(event.currentTarget.checked)}
            required
          />
          Ich bin mindestens 18 Jahre alt
        </label>
        <label className="checkbox-label">
          <input
            type="checkbox"
            checked={privacyAccepted}
            onChange={(event) => setPrivacyAccepted(event.currentTarget.checked)}
            required
          />
          Datenschutzerklärung akzeptieren
        </label>
        <label className="checkbox-label">
          <input
            type="checkbox"
            checked={termsAccepted}
            onChange={(event) => setTermsAccepted(event.currentTarget.checked)}
            required
          />
          Nutzungsbedingungen akzeptieren
        </label>
        <button type="submit" disabled={pending}>
          {pending ? 'Registrierung läuft …' : 'Registrieren'}
        </button>
      </form>
      <button type="button" onClick={onBackToLogin}>
        Zur Anmeldung
      </button>
    </section>
  )
}
