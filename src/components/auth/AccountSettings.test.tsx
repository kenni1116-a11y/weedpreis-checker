import { cleanup, render, screen, within } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { TotpFactor } from '../../auth/auth-service'
import { AuthProvider } from '../../auth/AuthProvider'
import { createInMemoryAuthService } from '../../auth/in-memory-auth-service'
import { AccountSettings } from './AccountSettings'

function renderSettings(options: {
  aal?: 'aal1' | 'aal2'
  factors?: TotpFactor[]
} = {}) {
  const service = createInMemoryAuthService({
    initialState: {
      status: 'signed-in',
      user: {
        id: 'synthetic-user',
        username: 'Ken.Test',
        email: 'ken@example.invalid',
        emailVerified: true,
        aal: options.aal ?? 'aal2',
      },
    },
    factors: options.factors,
  })
  return {
    service,
    ...render(
      <AuthProvider service={service}>
        <AccountSettings />
      </AuthProvider>,
    ),
  }
}

describe('AccountSettings', () => {
  beforeEach(() => {
    window.history.replaceState({}, '', '/profil')
  })

  afterEach(() => {
    cleanup()
    vi.restoreAllMocks()
  })

  it('shows only a masked email inside the private account panel', async () => {
    renderSettings()

    const panel = await screen.findByRole('region', { name: 'Privates Konto' })
    expect(within(panel).getByText('k***@example.invalid')).toBeInTheDocument()
    expect(within(panel).getByText('E-Mail verifiziert')).toBeInTheDocument()
    expect(screen.queryByText('ken@example.invalid')).not.toBeInTheDocument()
    expect(screen.getByText('Ken.Test')).toBeInTheDocument()
  })

  it('requires the current password and explains dual confirmation for an email change', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings()

    expect(
      await screen.findByText(
        'Die Änderung wird erst wirksam, nachdem alte und neue Adresse bestätigt wurden.',
      ),
    ).toBeInTheDocument()
    await user.type(
      screen.getByLabelText('Neue E-Mail-Adresse'),
      'new@example.invalid',
    )
    await user.type(
      screen.getByLabelText('Aktuelles Passwort für E-Mail-Änderung'),
      'synthetic-password',
    )
    await user.click(screen.getByRole('button', { name: 'E-Mail ändern' }))

    expect(service.calls.changeEmail).toEqual([
      {
        email: 'new@example.invalid',
        currentPassword: 'synthetic-password',
      },
    ])
    expect(
      await screen.findByText('Bestätigungsnachrichten wurden versendet.'),
    ).toBeInTheDocument()
    expect(window.location.href).not.toContain('new@example.invalid')
  })

  it('shows the TOTP QR and secret only until successful verification', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings()

    await user.click(
      await screen.findByRole('button', {
        name: 'Authenticator-App einrichten',
      }),
    )

    expect(
      screen.getByRole('img', { name: 'QR-Code für die Authenticator-App' }),
    ).toBeInTheDocument()
    expect(screen.getByText('SYNTHETICSECRET')).toBeInTheDocument()

    await user.type(
      screen.getByLabelText('Code zur Aktivierung'),
      '123456',
    )
    await user.click(
      screen.getByRole('button', { name: 'Zwei-Faktor-Schutz aktivieren' }),
    )

    expect(service.calls.verifyTotp).toEqual([
      { factorId: 'synthetic-factor', code: '123456' },
    ])
    expect(
      screen.queryByRole('img', { name: 'QR-Code für die Authenticator-App' }),
    ).not.toBeInTheDocument()
    expect(screen.queryByText('SYNTHETICSECRET')).not.toBeInTheDocument()
  })

  it('removes a verified factor at AAL2 only after fresh password proof', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings({
      aal: 'aal2',
      factors: [
        {
          id: 'factor-1',
          friendlyName: 'Weedypedia',
          status: 'verified',
        },
      ],
    })

    expect(await screen.findByText('Weedypedia')).toBeInTheDocument()
    await user.type(
      screen.getByLabelText('Aktuelles Passwort zum Entfernen'),
      'synthetic-password',
    )
    await user.click(
      screen.getByRole('button', { name: 'Authenticator entfernen' }),
    )

    expect(service.calls.unenrollTotp).toEqual([
      {
        factorId: 'factor-1',
        currentPassword: 'synthetic-password',
      },
    ])
  })

  it('does not offer factor removal while the current session is only AAL1', async () => {
    renderSettings({
      aal: 'aal1',
      factors: [
        {
          id: 'factor-1',
          friendlyName: 'Weedypedia',
          status: 'verified',
        },
      ],
    })

    expect(
      await screen.findByText(
        'Bestätige zuerst deinen aktuellen Authenticator-Code.',
      ),
    ).toBeInTheDocument()
    expect(
      screen.queryByRole('button', { name: 'Authenticator entfernen' }),
    ).not.toBeInTheDocument()
  })

  it('downloads a private JSON export through a blob URL after fresh proof', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings({
      factors: [
        {
          id: 'factor-1',
          friendlyName: 'Weedypedia',
          status: 'verified',
        },
      ],
    })
    const createObjectURL = vi.fn(() => 'blob:weedypedia-private-export')
    const revokeObjectURL = vi.fn()
    Object.defineProperty(URL, 'createObjectURL', {
      configurable: true,
      value: createObjectURL,
    })
    Object.defineProperty(URL, 'revokeObjectURL', {
      configurable: true,
      value: revokeObjectURL,
    })
    let clickedHref = ''
    let clickedDownload = ''
    vi.spyOn(HTMLAnchorElement.prototype, 'click').mockImplementation(function (
      this: HTMLAnchorElement,
    ) {
      clickedHref = this.href
      clickedDownload = this.download
    })

    expect(
      await screen.findByText(
        'Die Exportdatei enthält persönliche Daten. Bewahre sie sicher auf.',
      ),
    ).toBeInTheDocument()
    await user.type(
      screen.getByLabelText('Aktuelles Passwort für Export'),
      'synthetic-password',
    )
    await user.type(
      screen.getByLabelText('Aktueller TOTP-Code für Export'),
      '123456',
    )
    await user.click(
      screen.getByRole('button', { name: 'Privaten Export herunterladen' }),
    )

    expect(service.calls.exportAccount).toEqual([
      {
        currentPassword: 'synthetic-password',
        totpCode: '123456',
      },
    ])
    expect(createObjectURL).toHaveBeenCalledOnce()
    expect(clickedHref).toBe('blob:weedypedia-private-export')
    expect(clickedDownload).toBe('weedypedia-private-export-2026-07-25.json')
    expect(clickedHref).not.toMatch(/ken|inventory|example/i)
    expect(revokeObjectURL).toHaveBeenCalledWith(
      'blob:weedypedia-private-export',
    )
  })

  it('logs out without exposing account data in the URL', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings()

    await user.click(await screen.findByRole('button', { name: 'Abmelden' }))

    expect(service.calls.logout).toBe(1)
    expect(window.location.pathname).toBe('/profil')
    expect(window.location.href).not.toContain('ken@example.invalid')
  })

  it('requires username, password, explicit confirmation, and TOTP for deletion', async () => {
    const user = userEvent.setup()
    const { service } = renderSettings({
      factors: [
        {
          id: 'factor-1',
          friendlyName: 'Weedypedia',
          status: 'verified',
        },
      ],
    })

    await user.type(
      await screen.findByLabelText('Normalisierten Benutzernamen eingeben'),
      'ken.test',
    )
    await user.type(
      screen.getByLabelText('Aktuelles Passwort für Kontolöschung'),
      'synthetic-password',
    )
    await user.type(
      screen.getByLabelText('Aktueller TOTP-Code für Kontolöschung'),
      '123456',
    )
    await user.click(
      screen.getByRole('checkbox', {
        name: 'Ich bestätige die unwiderrufliche Kontolöschung',
      }),
    )
    await user.click(
      screen.getByRole('button', { name: 'Konto endgültig löschen' }),
    )

    expect(service.calls.deleteAccount).toEqual([
      {
        usernameConfirmation: 'ken.test',
        currentPassword: 'synthetic-password',
        totpCode: '123456',
      },
    ])
    expect(window.location.href).not.toMatch(/ken\.test|synthetic-password|123456/)
  })
})
