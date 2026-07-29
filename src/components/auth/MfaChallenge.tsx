import { useEffect, useRef, useState, type FormEvent } from 'react'
import type { TotpFactor } from '../../auth/auth-service'
import { useAuth } from '../../auth/useAuth'

type MfaChallengeProps = {
  factors: TotpFactor[]
}

export function MfaChallenge({ factors }: MfaChallengeProps) {
  const { service } = useAuth()
  const [factorId, setFactorId] = useState(factors[0]?.id ?? '')
  const [code, setCode] = useState('')
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
      await service.verifyTotp({ factorId, code })
    } catch (cause) {
      setError(
        cause instanceof Error
          ? cause.message
          : 'Der Code konnte nicht bestätigt werden.',
      )
    } finally {
      setCode('')
      setPending(false)
    }
  }

  return (
    <section className="auth-panel" aria-labelledby="mfa-title">
      <h2 id="mfa-title">Zwei-Faktor-Bestätigung</h2>
      <p>Öffne deine Authenticator-App und gib den aktuellen Code ein.</p>
      {error && (
        <div ref={errorRef} role="alert" tabIndex={-1} className="error-summary">
          {error}
        </div>
      )}
      <form onSubmit={submit}>
        {factors.length > 1 && (
          <label>
            Authenticator
            <select
              value={factorId}
              onChange={(event) => setFactorId(event.currentTarget.value)}
            >
              {factors.map((factor) => (
                <option key={factor.id} value={factor.id}>
                  {factor.friendlyName}
                </option>
              ))}
            </select>
          </label>
        )}
        <label>
          Sechsstelliger Code
          <input
            inputMode="numeric"
            autoComplete="one-time-code"
            pattern="[0-9]{6}"
            minLength={6}
            maxLength={6}
            value={code}
            onChange={(event) =>
              setCode(event.currentTarget.value.replace(/\D/g, '').slice(0, 6))}
            required
          />
        </label>
        <button type="submit" disabled={pending || !factorId}>
          {pending ? 'Bestätigung läuft …' : 'Code bestätigen'}
        </button>
      </form>
    </section>
  )
}
