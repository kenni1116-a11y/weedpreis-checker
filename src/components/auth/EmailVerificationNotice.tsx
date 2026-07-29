type EmailVerificationNoticeProps = {
  email: string
  onBackToLogin?: () => void
}

export function maskEmail(email: string): string {
  const [local = '', domain = ''] = email.trim().split('@')
  if (!local || !domain) return 'deine private E-Mail-Adresse'
  return `${local.slice(0, 1)}***@${domain}`
}

export function EmailVerificationNotice({
  email,
  onBackToLogin,
}: EmailVerificationNoticeProps) {
  return (
    <section className="auth-panel" aria-labelledby="verification-title">
      <h2 id="verification-title">Verifizierungsnachricht versendet</h2>
      <p>
        Bitte öffne die neutrale Nachricht an{' '}
        <strong>{maskEmail(email)}</strong> und bestätige deine Adresse.
      </p>
      <p>
        Die vollständige Adresse wird auf diesem Bildschirm nicht angezeigt.
      </p>
      {onBackToLogin && (
        <button type="button" onClick={onBackToLogin}>
          Zur Anmeldung
        </button>
      )}
    </section>
  )
}
