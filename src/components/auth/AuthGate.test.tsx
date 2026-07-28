import { cleanup, render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { AuthProvider } from '../../auth/AuthProvider'
import { createInMemoryAuthService } from '../../auth/in-memory-auth-service'
import { AuthGate } from './AuthGate'

function renderGate(
  service = createInMemoryAuthService(),
) {
  return {
    service,
    ...render(
      <AuthProvider service={service}>
        <AuthGate
          privacyVersion="weedypedia-privacy-2026-07-25"
          termsVersion="weedypedia-terms-2026-07-25"
        >
          <p>Geschützter Inhalt</p>
        </AuthGate>
      </AuthProvider>,
    ),
  }
}

describe('AuthGate', () => {
  beforeEach(() => {
    window.history.replaceState({}, '', '/')
  })

  afterEach(() => {
    cleanup()
  })

  it('announces the loading state before account access is known', () => {
    const service = createInMemoryAuthService()
    vi.spyOn(service, 'currentState').mockReturnValue(
      new Promise(() => undefined),
    )

    renderGate(service)

    expect(
      screen.getByRole('status', { name: 'Kontostatus wird geladen' }),
    ).toBeInTheDocument()
  })

  it('starts signed-out users with keyboard-accessible email and password login', async () => {
    const user = userEvent.setup()
    renderGate()

    expect(
      await screen.findByRole('heading', { name: 'Anmelden' }),
    ).toBeInTheDocument()
    expect(screen.getByLabelText('E-Mail-Adresse')).toHaveAttribute(
      'autocomplete',
      'email',
    )
    expect(screen.getByLabelText('Passwort')).toHaveAttribute(
      'autocomplete',
      'current-password',
    )

    await user.tab()
    expect(screen.getByLabelText('E-Mail-Adresse')).toHaveFocus()
  })

  it('registers with only the minimal pseudonymous fields and masks the verification address', async () => {
    const user = userEvent.setup()
    const { service } = renderGate()

    await user.click(
      await screen.findByRole('button', { name: 'Konto erstellen' }),
    )

    const username = screen.getByLabelText('Pseudonymer Benutzername')
    const email = screen.getByLabelText('E-Mail-Adresse')
    const password = screen.getByLabelText('Passwort')
    const adult = screen.getByRole('checkbox', {
      name: 'Ich bin mindestens 18 Jahre alt',
    })
    const privacy = screen.getByRole('checkbox', {
      name: 'Datenschutzerklärung akzeptieren',
    })
    const terms = screen.getByRole('checkbox', {
      name: 'Nutzungsbedingungen akzeptieren',
    })

    expect(username).toHaveAttribute('autocomplete', 'username')
    expect(email).toHaveAttribute('autocomplete', 'email')
    expect(password).toHaveAttribute('autocomplete', 'new-password')
    expect(screen.queryByLabelText('Echter Name')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Anschrift')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Telefonnummer')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Geburtsdatum')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Diagnose')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Rezept')).not.toBeInTheDocument()
    expect(screen.queryByLabelText('Bestand')).not.toBeInTheDocument()

    await user.type(username, 'Ken.Test')
    await user.type(password, 'synthetic-password')
    await user.click(screen.getByRole('button', { name: 'Registrieren' }))
    expect(service.calls.register).toHaveLength(0)

    await user.type(email, 'ken@example.invalid')
    await user.click(adult)
    await user.click(privacy)
    await user.click(terms)
    await user.click(screen.getByRole('button', { name: 'Registrieren' }))

    expect(await screen.findByText('Verifizierungsnachricht versendet')).toBeInTheDocument()
    expect(screen.getByText('k***@example.invalid')).toBeInTheDocument()
    expect(screen.queryByText('ken@example.invalid')).not.toBeInTheDocument()
    expect(service.calls.register).toHaveLength(1)
  })

  it('shows the same recovery result without revealing whether an account exists', async () => {
    const user = userEvent.setup()
    renderGate()

    await user.click(
      await screen.findByRole('button', { name: 'Passwort vergessen' }),
    )
    await user.type(
      screen.getByLabelText('E-Mail-Adresse'),
      'missing@example.invalid',
    )
    await user.click(
      screen.getByRole('button', { name: 'Wiederherstellung anfordern' }),
    )

    expect(
      await screen.findByText(
        'Falls ein passendes Konto existiert, wurde eine Wiederherstellungsnachricht versendet.',
      ),
    ).toBeInTheDocument()
  })

  it('renders the new-password form for a password recovery callback', async () => {
    window.history.replaceState({}, '', '/auth/callback?type=recovery')
    const service = createInMemoryAuthService({
      initialState: {
        status: 'signed-in',
        user: {
          id: 'synthetic-user',
          username: 'Ken.Test',
          email: 'ken@example.invalid',
          emailVerified: true,
          aal: 'aal1',
        },
      },
    })

    renderGate(service)

    expect(
      await screen.findByRole('heading', { name: 'Neues Passwort festlegen' }),
    ).toBeInTheDocument()
    expect(screen.queryByText('Geschützter Inhalt')).not.toBeInTheDocument()
  })

  it('blocks protected content at AAL1 and submits one six-digit TOTP challenge', async () => {
    const user = userEvent.setup()
    const service = createInMemoryAuthService({
      initialState: {
        status: 'mfa-required',
        email: 'ken@example.invalid',
        factors: [
          {
            id: 'factor-1',
            friendlyName: 'Weedypedia',
            status: 'verified',
          },
        ],
      },
    })
    renderGate(service)

    const code = await screen.findByLabelText('Sechsstelliger Code')
    expect(code).toHaveAttribute('inputmode', 'numeric')
    expect(code).toHaveAttribute('autocomplete', 'one-time-code')
    expect(code).toHaveAttribute('maxlength', '6')
    expect(screen.queryByText('Geschützter Inhalt')).not.toBeInTheDocument()

    await user.type(code, '123456')
    await user.click(screen.getByRole('button', { name: 'Code bestätigen' }))

    expect(service.calls.verifyTotp).toEqual([
      { factorId: 'factor-1', code: '123456' },
    ])
    expect(code).toHaveValue('')
  })

  it('moves focus to the error summary after a failed registration', async () => {
    const user = userEvent.setup()
    const service = createInMemoryAuthService()
    vi.spyOn(service, 'register').mockRejectedValue(
      new Error('Registrierung vorübergehend nicht möglich.'),
    )
    renderGate(service)

    await user.click(
      await screen.findByRole('button', { name: 'Konto erstellen' }),
    )
    await user.type(
      screen.getByLabelText('Pseudonymer Benutzername'),
      'Ken.Test',
    )
    await user.type(
      screen.getByLabelText('E-Mail-Adresse'),
      'ken@example.invalid',
    )
    await user.type(
      screen.getByLabelText('Passwort'),
      'synthetic-password',
    )
    await user.click(
      screen.getByRole('checkbox', {
        name: 'Ich bin mindestens 18 Jahre alt',
      }),
    )
    await user.click(
      screen.getByRole('checkbox', {
        name: 'Datenschutzerklärung akzeptieren',
      }),
    )
    await user.click(
      screen.getByRole('checkbox', {
        name: 'Nutzungsbedingungen akzeptieren',
      }),
    )
    await user.click(screen.getByRole('button', { name: 'Registrieren' }))

    const alert = await screen.findByRole('alert')
    expect(alert).toHaveTextContent('Registrierung vorübergehend nicht möglich.')
    expect(alert).toHaveFocus()
  })
})
