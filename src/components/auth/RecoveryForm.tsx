import { useState, type FormEvent } from 'react'
import { useAuth } from '../../auth/useAuth'

type RecoveryFormProps = {
  onBackToLogin: () => void
}

const RECOVERY_NOTICE =
  'Falls ein passendes Konto existiert, wurde eine Wiederherstellungsnachricht versendet.'

export function RecoveryForm({ onBackToLogin }: RecoveryFormProps) {
  const { service } = useAuth()
  const [email, setEmail] = useState('')
  const [pending, setPending] = useState(false)
  const [sent, setSent] = useState(false)

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    setPending(true)
    try {
      await service.requestPasswordRecovery(email)
    } catch {
      // The visible response deliberately stays identical to prevent enumeration.
    } finally {
      setPending(false)
      setSent(true)
    }
  }

  return (
    <section className="auth-panel" aria-labelledby="recovery-title">
      <h2 id="recovery-title">Passwort wiederherstellen</h2>
      {sent ? (
        <p role="status">{RECOVERY_NOTICE}</p>
      ) : (
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
          <button type="submit" disabled={pending}>
            {pending
              ? 'Anfrage läuft …'
              : 'Wiederherstellung anfordern'}
          </button>
        </form>
      )}
      <button type="button" onClick={onBackToLogin}>
        Zur Anmeldung
      </button>
    </section>
  )
}
