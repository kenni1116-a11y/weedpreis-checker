import {
  useEffect,
  useRef,
  useState,
  type FormEvent,
} from 'react'
import type {
  AccountExport,
  TotpEnrollment,
  TotpFactor,
} from '../../auth/auth-service'
import { useAuth } from '../../auth/useAuth'
import { maskEmail } from './EmailVerificationNotice'

function downloadPrivateExport(accountExport: AccountExport): void {
  const blob = new Blob([JSON.stringify(accountExport, null, 2)], {
    type: 'application/json',
  })
  const objectUrl = URL.createObjectURL(blob)
  const anchor = document.createElement('a')
  const date = /^\d{4}-\d{2}-\d{2}/.exec(accountExport.exportedAt)?.[0]
    ?? new Date().toISOString().slice(0, 10)
  anchor.href = objectUrl
  anchor.download = `weedypedia-private-export-${date}.json`
  anchor.rel = 'noopener'
  document.body.append(anchor)
  anchor.click()
  anchor.remove()
  URL.revokeObjectURL(objectUrl)
}

export function AccountSettings() {
  const { state, service } = useAuth()
  const [factors, setFactors] = useState<TotpFactor[]>([])
  const [newEmail, setNewEmail] = useState('')
  const [emailPassword, setEmailPassword] = useState('')
  const [enrollment, setEnrollment] = useState<TotpEnrollment | null>(null)
  const [enrollmentCode, setEnrollmentCode] = useState('')
  const [removePassword, setRemovePassword] = useState('')
  const [exportPassword, setExportPassword] = useState('')
  const [exportTotp, setExportTotp] = useState('')
  const [deletionUsername, setDeletionUsername] = useState('')
  const [deletionPassword, setDeletionPassword] = useState('')
  const [deletionTotp, setDeletionTotp] = useState('')
  const [deletionConfirmed, setDeletionConfirmed] = useState(false)
  const [pendingAction, setPendingAction] = useState('')
  const [notice, setNotice] = useState('')
  const [error, setError] = useState('')
  const errorRef = useRef<HTMLDivElement>(null)

  const user = state.status === 'signed-in' ? state.user : null
  const verifiedFactors = factors.filter(
    (factor) => factor.status === 'verified',
  )
  const hasVerifiedTotp = verifiedFactors.length > 0

  useEffect(() => {
    if (error) errorRef.current?.focus()
  }, [error])

  useEffect(() => {
    if (!user) return
    let active = true
    void service
      .listTotpFactors()
      .then((nextFactors) => {
        if (active) setFactors(nextFactors)
      })
      .catch(() => {
        if (active) setError('Authenticator-Status konnte nicht geladen werden.')
      })
    return () => {
      active = false
    }
  }, [service, user])

  if (!user) {
    return (
      <p role="status" aria-label="Privates Konto wird geladen">
        Privates Konto wird geladen …
      </p>
    )
  }

  const normalizedUsername = user.username.trim().toLowerCase()

  function beginAction(name: string) {
    setPendingAction(name)
    setError('')
    setNotice('')
  }

  function fail(cause: unknown, fallback: string) {
    setError(cause instanceof Error ? cause.message : fallback)
  }

  async function changeEmail(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    beginAction('email')
    try {
      await service.changeEmail({
        email: newEmail,
        currentPassword: emailPassword,
      })
      setNewEmail('')
      setNotice('Bestätigungsnachrichten wurden versendet.')
    } catch (cause) {
      fail(cause, 'Die E-Mail-Änderung konnte nicht gestartet werden.')
    } finally {
      setEmailPassword('')
      setPendingAction('')
    }
  }

  async function startEnrollment() {
    beginAction('enroll')
    try {
      setEnrollment(await service.enrollTotp())
    } catch (cause) {
      fail(cause, 'Die Authenticator-Einrichtung konnte nicht gestartet werden.')
    } finally {
      setPendingAction('')
    }
  }

  async function verifyEnrollment(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (!enrollment) return
    beginAction('verify-enrollment')
    try {
      await service.verifyTotp({
        factorId: enrollment.factorId,
        code: enrollmentCode,
      })
      setEnrollment(null)
      setNotice('Zwei-Faktor-Schutz wurde aktiviert.')
    } catch (cause) {
      fail(cause, 'Der Aktivierungscode konnte nicht bestätigt werden.')
    } finally {
      setEnrollmentCode('')
      setPendingAction('')
    }
  }

  async function removeFactor(factorId: string) {
    beginAction('remove-factor')
    try {
      await service.unenrollTotp({
        factorId,
        currentPassword: removePassword,
      })
      setFactors((current) =>
        current.filter((factor) => factor.id !== factorId))
      setNotice('Authenticator wurde entfernt.')
    } catch (cause) {
      fail(cause, 'Der Authenticator konnte nicht entfernt werden.')
    } finally {
      setRemovePassword('')
      setPendingAction('')
    }
  }

  async function exportAccount(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    beginAction('export')
    try {
      const accountExport = await service.exportAccount({
        currentPassword: exportPassword,
        ...(hasVerifiedTotp ? { totpCode: exportTotp } : {}),
      })
      downloadPrivateExport(accountExport)
      setNotice('Privater Export wurde heruntergeladen.')
    } catch (cause) {
      fail(cause, 'Der private Export konnte nicht erstellt werden.')
    } finally {
      setExportPassword('')
      setExportTotp('')
      setPendingAction('')
    }
  }

  async function logout() {
    beginAction('logout')
    try {
      await service.logout()
    } catch (cause) {
      fail(cause, 'Abmeldung nicht möglich.')
    } finally {
      setPendingAction('')
    }
  }

  async function deleteAccount(event: FormEvent<HTMLFormElement>) {
    event.preventDefault()
    if (deletionUsername.trim() !== normalizedUsername) {
      setError('Der normalisierte Benutzername stimmt nicht überein.')
      return
    }
    if (!deletionConfirmed) {
      setError('Bestätige die unwiderrufliche Kontolöschung.')
      return
    }

    beginAction('delete')
    try {
      await service.deleteAccount({
        usernameConfirmation: deletionUsername.trim(),
        currentPassword: deletionPassword,
        ...(hasVerifiedTotp ? { totpCode: deletionTotp } : {}),
      })
    } catch (cause) {
      fail(cause, 'Das Konto konnte nicht gelöscht werden.')
    } finally {
      setDeletionUsername('')
      setDeletionPassword('')
      setDeletionTotp('')
      setDeletionConfirmed(false)
      setPendingAction('')
    }
  }

  return (
    <section
      className="account-settings"
      role="region"
      aria-labelledby="private-account-title"
    >
      <h2 id="private-account-title">Privates Konto</h2>
      <dl>
        <div>
          <dt>Pseudonym</dt>
          <dd>{user.username}</dd>
        </div>
        <div>
          <dt>Private E-Mail</dt>
          <dd>{maskEmail(user.email)}</dd>
        </div>
        <div>
          <dt>Status</dt>
          <dd>{user.emailVerified ? 'E-Mail verifiziert' : 'Verifizierung offen'}</dd>
        </div>
      </dl>

      {error && (
        <div ref={errorRef} role="alert" tabIndex={-1} className="error-summary">
          {error}
        </div>
      )}
      {notice && <p role="status">{notice}</p>}

      <section aria-labelledby="email-change-title">
        <h3 id="email-change-title">E-Mail ändern</h3>
        <p>
          Die Änderung wird erst wirksam, nachdem alte und neue Adresse
          bestätigt wurden.
        </p>
        <form onSubmit={changeEmail}>
          <label>
            Neue E-Mail-Adresse
            <input
              type="email"
              autoComplete="email"
              value={newEmail}
              onChange={(event) => setNewEmail(event.currentTarget.value)}
              required
            />
          </label>
          <label>
            Aktuelles Passwort für E-Mail-Änderung
            <input
              type="password"
              autoComplete="current-password"
              value={emailPassword}
              onChange={(event) => setEmailPassword(event.currentTarget.value)}
              required
            />
          </label>
          <button type="submit" disabled={pendingAction === 'email'}>
            E-Mail ändern
          </button>
        </form>
      </section>

      <section aria-labelledby="totp-title">
        <h3 id="totp-title">Authenticator-App</h3>
        {verifiedFactors.map((factor) => (
          <div key={factor.id} className="account-factor">
            <p><strong>{factor.friendlyName}</strong> · aktiv</p>
            {user.aal === 'aal2' ? (
              <>
                <label>
                  Aktuelles Passwort zum Entfernen
                  <input
                    type="password"
                    autoComplete="current-password"
                    value={removePassword}
                    onChange={(event) =>
                      setRemovePassword(event.currentTarget.value)}
                    required
                  />
                </label>
                <button
                  type="button"
                  disabled={
                    !removePassword || pendingAction === 'remove-factor'
                  }
                  onClick={() => void removeFactor(factor.id)}
                >
                  Authenticator entfernen
                </button>
              </>
            ) : (
              <p>Bestätige zuerst deinen aktuellen Authenticator-Code.</p>
            )}
          </div>
        ))}

        {!hasVerifiedTotp && !enrollment && (
          <button
            type="button"
            onClick={() => void startEnrollment()}
            disabled={pendingAction === 'enroll'}
          >
            Authenticator-App einrichten
          </button>
        )}

        {enrollment && (
          <form onSubmit={verifyEnrollment}>
            <p>
              Scanne den QR-Code. Falls das nicht möglich ist, übertrage das
              Geheimnis einmalig manuell.
            </p>
            <img
              src={enrollment.qrCode}
              alt="QR-Code für die Authenticator-App"
            />
            <p><code>{enrollment.secret}</code></p>
            <label>
              Code zur Aktivierung
              <input
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="[0-9]{6}"
                minLength={6}
                maxLength={6}
                value={enrollmentCode}
                onChange={(event) =>
                  setEnrollmentCode(
                    event.currentTarget.value.replace(/\D/g, '').slice(0, 6),
                  )}
                required
              />
            </label>
            <button
              type="submit"
              disabled={pendingAction === 'verify-enrollment'}
            >
              Zwei-Faktor-Schutz aktivieren
            </button>
            <button
              type="button"
              onClick={() => {
                setEnrollment(null)
                setEnrollmentCode('')
              }}
            >
              Abbrechen
            </button>
          </form>
        )}
      </section>

      <section aria-labelledby="export-title">
        <h3 id="export-title">Privater Export</h3>
        <p>
          Die Exportdatei enthält persönliche Daten. Bewahre sie sicher auf.
        </p>
        <form onSubmit={exportAccount}>
          <label>
            Aktuelles Passwort für Export
            <input
              type="password"
              autoComplete="current-password"
              value={exportPassword}
              onChange={(event) => setExportPassword(event.currentTarget.value)}
              required
            />
          </label>
          {hasVerifiedTotp && (
            <label>
              Aktueller TOTP-Code für Export
              <input
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="[0-9]{6}"
                minLength={6}
                maxLength={6}
                value={exportTotp}
                onChange={(event) =>
                  setExportTotp(
                    event.currentTarget.value.replace(/\D/g, '').slice(0, 6),
                  )}
                required
              />
            </label>
          )}
          <button type="submit" disabled={pendingAction === 'export'}>
            Privaten Export herunterladen
          </button>
        </form>
      </section>

      <section aria-labelledby="session-title">
        <h3 id="session-title">Sitzung</h3>
        <button
          type="button"
          onClick={() => void logout()}
          disabled={pendingAction === 'logout'}
        >
          Abmelden
        </button>
      </section>

      <section className="danger-zone" aria-labelledby="delete-title">
        <h3 id="delete-title">Konto löschen</h3>
        <p>
          Diese Aktion entfernt Konto, Einwilligungsbelege und persönlichen
          Bestand unwiderruflich.
        </p>
        <form onSubmit={deleteAccount}>
          <label>
            Normalisierten Benutzernamen eingeben
            <input
              autoComplete="off"
              value={deletionUsername}
              onChange={(event) =>
                setDeletionUsername(event.currentTarget.value)}
              required
            />
          </label>
          <label>
            Aktuelles Passwort für Kontolöschung
            <input
              type="password"
              autoComplete="current-password"
              value={deletionPassword}
              onChange={(event) =>
                setDeletionPassword(event.currentTarget.value)}
              required
            />
          </label>
          {hasVerifiedTotp && (
            <label>
              Aktueller TOTP-Code für Kontolöschung
              <input
                inputMode="numeric"
                autoComplete="one-time-code"
                pattern="[0-9]{6}"
                minLength={6}
                maxLength={6}
                value={deletionTotp}
                onChange={(event) =>
                  setDeletionTotp(
                    event.currentTarget.value.replace(/\D/g, '').slice(0, 6),
                  )}
                required
              />
            </label>
          )}
          <label className="checkbox-label">
            <input
              type="checkbox"
              checked={deletionConfirmed}
              onChange={(event) =>
                setDeletionConfirmed(event.currentTarget.checked)}
              required
            />
            Ich bestätige die unwiderrufliche Kontolöschung
          </label>
          <button type="submit" disabled={pendingAction === 'delete'}>
            Konto endgültig löschen
          </button>
        </form>
      </section>
    </section>
  )
}
