import { useEffect, useRef, useState, type FormEvent } from 'react'
import { useAuth } from '../../auth/useAuth'

export function UpdatePasswordForm() {
  const { service } = useAuth()
  const [password, setPassword] = useState('')
  const [confirmation, setConfirmation] = useState('')
  const [pending, setPending] = useState(false)
  const [error, setError] = useState('')
  const [complete, setComplete] = useState(false)
  const errorRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (password !== confirmation) {
      setError('Die Passwörter stimmen nicht überein.')
      return
    }
    setPending(true)
    setError('')
    try {
      await service.updateRecoveredPassword(password)
      setComplete(true)
    } catch (cause) {
      setError(
        cause instanceof Error
          ? cause.message
          : 'Das Passwort konnte nicht aktualisiert werden.',
      )
    } finally {
      setPassword('')
      setConfirmation('')
      setPending(false)
    }
  }

  return (
    <section className="auth-panel" aria-labelledby="new-password-title">
      <h2 id="new-password-title">Neues Passwort festlegen</h2>
      {complete ? (
        <p role="status">Das Passwort wurde aktualisiert.</p>
      ) : (
        <>
          {error && (
            <div
              ref={errorRef}
              role="alert"
              tabIndex={-1}
              className="error-summary"
            >
              {error}
            </div>
          )}
          <form onSubmit={submit}>
            <label>
              Neues Passwort
              <input
                type="password"
                autoComplete="new-password"
                minLength={12}
                maxLength={128}
                value={password}
                onChange={(event) => setPassword(event.currentTarget.value)}
                required
              />
            </label>
            <label>
              Neues Passwort wiederholen
              <input
                type="password"
                autoComplete="new-password"
                minLength={12}
                maxLength={128}
                value={confirmation}
                onChange={(event) =>
                  setConfirmation(event.currentTarget.value)}
                required
              />
            </label>
            <button type="submit" disabled={pending}>
              {pending ? 'Aktualisierung läuft …' : 'Passwort aktualisieren'}
            </button>
          </form>
        </>
      )}
    </section>
  )
}
