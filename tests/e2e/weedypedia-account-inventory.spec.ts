import { createHmac } from 'node:crypto'
import { readFile } from 'node:fs/promises'
import {
  expect,
  test,
  type APIRequestContext,
  type Page,
  type TestInfo,
} from '@playwright/test'

const mailpitUrl = 'http://127.0.0.1:54324'
const apiUrl = process.env.E2E_SUPABASE_API_URL
const anonKey = process.env.E2E_SUPABASE_ANON_KEY
const passwordA = 'Synthetic-A-Password-2026!'
const recoveredPasswordA = 'Recovered-A-Password-2026!'
const passwordB = 'Synthetic-B-Password-2026!'
const emailA = 'account-a@example.invalid'
const changedEmailA = 'account-a-new@example.invalid'
const emailB = 'account-b@example.invalid'
const usernameA = 'Account.A'
const usernameB = 'Account.B'

type MailSummary = {
  ID?: string
  id?: string
  Subject?: string
  subject?: string
  To?: Array<{ Address?: string; address?: string }>
}

type MailSearch = {
  messages?: MailSummary[]
  Messages?: MailSummary[]
}

type MailDetail = {
  HTML?: string
  html?: string
  Text?: string
  text?: string
  Subject?: string
  subject?: string
}

function base32Bytes(secret: string): Buffer {
  const alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'
  const normalized = secret.toUpperCase().replace(/=+$/g, '')
  let bits = ''
  for (const character of normalized) {
    const value = alphabet.indexOf(character)
    if (value < 0) throw new Error('Invalid synthetic TOTP secret.')
    bits += value.toString(2).padStart(5, '0')
  }
  const bytes: number[] = []
  for (let index = 0; index + 8 <= bits.length; index += 8) {
    bytes.push(Number.parseInt(bits.slice(index, index + 8), 2))
  }
  return Buffer.from(bytes)
}

function totp(secret: string, now = Date.now()): string {
  const counter = Math.floor(now / 30_000)
  const counterBytes = Buffer.alloc(8)
  counterBytes.writeBigUInt64BE(BigInt(counter))
  const digest = createHmac('sha1', base32Bytes(secret))
    .update(counterBytes)
    .digest()
  const offset = digest[digest.length - 1] & 0x0f
  const binary =
    ((digest[offset] & 0x7f) << 24)
    | ((digest[offset + 1] & 0xff) << 16)
    | ((digest[offset + 2] & 0xff) << 8)
    | (digest[offset + 3] & 0xff)
  return String(binary % 1_000_000).padStart(6, '0')
}

async function nextTotp(secret: string, previous?: string): Promise<string> {
  const deadline = Date.now() + 35_000
  while (Date.now() < deadline) {
    const code = totp(secret)
    if (!previous || code !== previous) return code
    await new Promise((resolve) => setTimeout(resolve, 400))
  }
  throw new Error('Timed out waiting for a fresh synthetic TOTP code.')
}

async function clearMailpit(request: APIRequestContext): Promise<void> {
  const response = await request.delete(`${mailpitUrl}/api/v1/messages`)
  expect(response.ok()).toBeTruthy()
}

function mailId(summary: MailSummary): string {
  const id = summary.ID ?? summary.id
  if (!id) throw new Error('Mailpit response did not contain a message ID.')
  return id
}

function mailSubject(summary: MailSummary | MailDetail): string {
  return summary.Subject ?? summary.subject ?? ''
}

async function findMail(
  request: APIRequestContext,
  recipient: string,
  subject: string,
): Promise<{ detail: MailDetail; id: string }> {
  let found: MailSummary | undefined
  await expect.poll(async () => {
    const query = encodeURIComponent(`to:"${recipient}"`)
    const response = await request.get(
      `${mailpitUrl}/api/v1/search?query=${query}&limit=100`,
    )
    if (!response.ok()) return false
    const body = await response.json() as MailSearch
    const messages = body.messages ?? body.Messages ?? []
    found = messages.find((message) => (
      mailSubject(message) === subject
      && (message.To ?? []).some(
        (address) =>
          (address.Address ?? address.address)?.toLowerCase()
          === recipient.toLowerCase(),
      )
    ))
    return Boolean(found)
  }, {
    message: `Mailpit message "${subject}" for ${recipient}`,
    timeout: 15_000,
  }).toBe(true)

  const id = mailId(found!)
  const response = await request.get(`${mailpitUrl}/api/v1/message/${id}`)
  expect(response.ok()).toBeTruthy()
  const detail = await response.json() as MailDetail
  expect(mailSubject(detail)).toBe(subject)
  const body = `${detail.HTML ?? detail.html ?? ''}\n${detail.Text ?? detail.text ?? ''}`
  expect(body).not.toMatch(/cannabis|bestand|medizin|sorte|produkt/i)
  return { detail, id }
}

function confirmationLink(detail: MailDetail): string {
  const html = detail.HTML ?? detail.html ?? ''
  const text = detail.Text ?? detail.text ?? ''
  const match =
    /href=["']([^"']+)["']/i.exec(html)
    ?? /https?:\/\/\S+/i.exec(text)
  if (!match) throw new Error('No confirmation link found in Mailpit message.')
  return (match[1] ?? match[0]).replaceAll('&amp;', '&')
}

async function register(
  page: Page,
  input: { username: string; email: string; password: string },
): Promise<void> {
  await page.getByRole('button', { name: 'Konto erstellen' }).click()
  await page.getByLabel('Pseudonymer Benutzername').fill(input.username)
  await page.getByLabel('E-Mail-Adresse').fill(input.email)
  await page.getByLabel('Passwort').fill(input.password)
  await page.getByLabel('Ich bin mindestens 18 Jahre alt').check()
  await page.getByLabel('Datenschutzerklärung akzeptieren').check()
  await page.getByLabel('Nutzungsbedingungen akzeptieren').check()
  await page.getByRole('button', { name: 'Registrieren' }).click()
  await expect(page.getByRole(
    'heading',
    { name: 'Verifizierungsnachricht versendet' },
  )).toBeVisible()
}

async function login(
  page: Page,
  email: string,
  password: string,
): Promise<void> {
  await expect(page.getByRole(
    'heading',
    { name: 'Bei Weedypedia anmelden' },
  )).toBeVisible()
  await page.getByLabel('E-Mail-Adresse').fill(email)
  await page.getByLabel('Passwort').fill(password)
  await page.getByRole('button', { name: 'Anmelden' }).click()
}

async function completeMfa(
  page: Page,
  secret: string,
  previousCode?: string,
): Promise<string> {
  await expect(page.getByRole(
    'heading',
    { name: 'Zwei-Faktor-Bestätigung' },
  )).toBeVisible()
  const code = await nextTotp(secret, previousCode)
  await page.getByLabel('Sechsstelliger Code').fill(code)
  await page.getByRole('button', { name: 'Code bestätigen' }).click()
  await expect(page.getByRole(
    'heading',
    { name: 'Weedypedia' },
  )).toBeVisible()
  return code
}

async function addInventory(
  page: Page,
  input: {
    reference: string
    quantity: string
    unit?: 'g' | 'ml' | 'piece'
    batch?: string
    expiresOn?: string
    storageLocation?: string
    note?: string
  },
): Promise<void> {
  await page.getByRole('button', { name: 'Eintrag hinzufügen' }).click()
  await page.getByLabel('Sorte oder Produkt').selectOption({
    label: input.reference,
  })
  await page.getByLabel('Menge').fill(input.quantity)
  if (input.unit) await page.getByLabel('Einheit').selectOption(input.unit)
  if (input.batch) await page.getByLabel('Charge (optional)').fill(input.batch)
  if (input.expiresOn) {
    await page.getByLabel('Ablaufdatum (optional)').fill(input.expiresOn)
  }
  if (input.storageLocation) {
    await page.getByLabel('Lagerort (optional)').fill(input.storageLocation)
  }
  if (input.note) await page.getByLabel('Notiz (optional)').fill(input.note)
  await page.getByRole('button', { name: 'Speichern' }).click()
}

async function accessToken(page: Page): Promise<string> {
  return page.evaluate(() => {
    for (const key of Object.keys(localStorage)) {
      if (!key.startsWith('sb-') || !key.endsWith('-auth-token')) continue
      const value = localStorage.getItem(key)
      if (!value) continue
      const parsed = JSON.parse(value) as { access_token?: string }
      if (parsed.access_token) return parsed.access_token
    }
    throw new Error('No browser access token found.')
  })
}

async function requestRecovery(page: Page, email: string): Promise<string> {
  await page.getByRole('button', { name: 'Passwort vergessen' }).click()
  await page.getByLabel('E-Mail-Adresse').fill(email)
  await page.getByRole(
    'button',
    { name: 'Wiederherstellung anfordern' },
  ).click()
  return page.getByRole('status').textContent()
}

async function capture(
  page: Page,
  testInfo: TestInfo,
  name: string,
): Promise<void> {
  const path = testInfo.outputPath(`${name}.png`)
  await page.screenshot({ path, fullPage: true })
  await testInfo.attach(name, { path, contentType: 'image/png' })
}

test('verified iPhone account keeps inventory private through its full lifecycle', async ({
  page,
  request,
  context,
}, testInfo) => {
  test.setTimeout(240_000)
  expect(apiUrl, 'E2E_SUPABASE_API_URL').toBeTruthy()
  expect(anonKey, 'E2E_SUPABASE_ANON_KEY').toBeTruthy()
  await clearMailpit(request)
  await page.goto('/')

  const emailInput = page.getByLabel('E-Mail-Adresse')
  await emailInput.focus()
  await page.keyboard.press('Tab')
  await expect(page.getByLabel('Passwort')).toBeFocused()
  await page.keyboard.press('Alt+Tab')
  await expect(page.getByRole('button', { name: 'Anmelden' })).toBeFocused()

  await register(page, {
    username: usernameA,
    email: emailA,
    password: passwordA,
  })
  await expect(page.getByRole(
    'button',
    { name: 'Bestand' },
  )).toHaveCount(0)

  const confirmationA = await findMail(
    request,
    emailA,
    'E-Mail-Adresse bestätigen',
  )
  const mailpitPage = await context.newPage()
  await mailpitPage.goto(mailpitUrl)
  await capture(mailpitPage, testInfo, 'mailpit-confirmation-a')
  await mailpitPage.close()

  await page.goto(confirmationLink(confirmationA.detail))
  await expect(page.getByRole(
    'heading',
    { name: 'Weedypedia' },
  )).toBeVisible()

  await page.getByRole('button', { name: 'Profil' }).click()
  await page.getByRole(
    'button',
    { name: 'Authenticator-App einrichten' },
  ).click()
  const authenticator = page.getByRole(
    'heading',
    { name: 'Authenticator-App' },
  ).locator('..')
  const secret = (await authenticator.locator('code').textContent())?.trim()
  expect(secret).toBeTruthy()
  const enrollmentCode = await nextTotp(secret!)
  await page.getByLabel('Code zur Aktivierung').fill(enrollmentCode)
  await page.getByRole(
    'button',
    { name: 'Zwei-Faktor-Schutz aktivieren' },
  ).click()
  await expect(page.getByText(
    'Zwei-Faktor-Schutz wurde aktiviert.',
  )).toBeVisible()
  await page.reload()
  await page.getByRole('button', { name: 'Profil' }).click()
  await expect(authenticator.getByText(/aktiv/)).toBeVisible()
  await capture(page, testInfo, 'totp-active-a')

  await page.getByRole('button', { name: 'Abmelden' }).click()
  await login(page, emailA, passwordA)
  let lastCode = await completeMfa(page, secret!, enrollmentCode)

  await page.getByRole('button', { name: 'Bestand' }).click()
  await addInventory(page, {
    reference: 'Test-Cultivar – keine Echtdaten · Sorte',
    quantity: '2',
  })
  await addInventory(page, {
    reference: 'Testprodukt – keine Echtdaten · Produkt',
    quantity: '1',
    unit: 'piece',
    batch: 'SYNTHETIC-BATCH',
    expiresOn: '2027-07-25',
    storageLocation: 'Testschrank',
    note: 'Ausschließlich synthetischer E2E-Eintrag.',
  })
  await expect(page.getByText('2 g')).toBeVisible()
  await expect(page.getByText('1 Stück')).toBeVisible()
  await page.reload()
  await page.getByRole('button', { name: 'Bestand' }).click()
  await expect(page.getByText('2 g')).toBeVisible()
  await expect(page.getByText('SYNTHETIC-BATCH')).toBeVisible()
  await capture(page, testInfo, 'private-inventory-a')

  await expect(page.locator('meta[name="theme-color"]')).toHaveAttribute(
    'content',
    '#07110f',
  )
  const manifestHref = await page.locator(
    'link[rel="manifest"]',
  ).getAttribute('href')
  expect(manifestHref).toBeTruthy()
  const manifestResponse = await page.request.get(
    new URL(manifestHref!, page.url()).toString(),
  )
  expect(await manifestResponse.json()).toMatchObject({
    lang: 'de',
    name: 'Weedypedia – Sortenwissen mit Quellen',
    display: 'standalone',
    theme_color: '#07110f',
    background_color: '#07110f',
  })
  const targetHeights = await page.locator(
    'button:visible, input:not([type="checkbox"]):visible, select:visible, textarea:visible',
  ).evaluateAll((elements) => (
    elements.map((element) => element.getBoundingClientRect().height)
  ))
  expect(targetHeights.every((height) => height >= 44)).toBe(true)
  const checkboxTargets = await page.locator(
    'label.checkbox-label:visible',
  ).evaluateAll((labels) => (
    labels.map((label) => label.getBoundingClientRect().height)
  ))
  expect(checkboxTargets.every((height) => height >= 44)).toBe(true)
  expect(await page.evaluate(() => (
    document.documentElement.scrollWidth
    <= document.documentElement.clientWidth
  ))).toBe(true)
  await page.emulateMedia({ reducedMotion: 'reduce' })
  expect(await page.evaluate(() => (
    matchMedia('(prefers-reduced-motion: reduce)').matches
  ))).toBe(true)

  await page.getByRole('button', { name: 'Profil' }).click()
  const exportCode = await nextTotp(secret!, lastCode)
  lastCode = exportCode
  await page.getByLabel('Aktuelles Passwort für Export').fill(passwordA)
  await page.getByLabel('Aktueller TOTP-Code für Export').fill(exportCode)
  const downloadPromise = page.waitForEvent('download')
  await page.getByRole(
    'button',
    { name: 'Privaten Export herunterladen' },
  ).click()
  const download = await downloadPromise
  expect(download.suggestedFilename()).toMatch(
    /^weedypedia-private-export-\d{4}-\d{2}-\d{2}\.json$/,
  )
  const downloadPath = await download.path()
  expect(downloadPath).toBeTruthy()
  const exportText = await readFile(downloadPath!, 'utf8')
  const accountExport = JSON.parse(exportText) as {
    account: { username: string; email: string }
    consents: Array<{ kind: string }>
    inventory: Array<{ id: string; quantity: number }>
  }
  expect(accountExport.account).toMatchObject({
    username: usernameA,
    email: emailA,
  })
  expect(accountExport.consents.map((receipt) => receipt.kind).sort()).toEqual([
    'adult',
    'privacy',
    'terms',
  ])
  expect(accountExport.inventory).toHaveLength(2)
  expect(exportText).not.toContain(passwordA)
  expect(exportText).not.toMatch(
    /access_token|refresh_token|app_metadata|user_metadata|service_role/i,
  )
  const accountAItemIds = accountExport.inventory.map((item) => item.id)

  await page.getByRole('button', { name: 'Abmelden' }).click()
  await clearMailpit(request)
  await register(page, {
    username: usernameB,
    email: emailB,
    password: passwordB,
  })
  const confirmationB = await findMail(
    request,
    emailB,
    'E-Mail-Adresse bestätigen',
  )
  await page.goto(confirmationLink(confirmationB.detail))
  await expect(page.getByRole(
    'heading',
    { name: 'Weedypedia' },
  )).toBeVisible()
  await page.getByRole('button', { name: 'Bestand' }).click()
  await expect(page.getByText('Noch kein Bestand gespeichert.')).toBeVisible()

  const tokenB = await accessToken(page)
  const headersB = {
    apikey: anonKey!,
    Authorization: `Bearer ${tokenB}`,
    'Accept-Profile': 'api',
    'Content-Profile': 'api',
  }
  const listAsB = await request.get(
    `${apiUrl}/rest/v1/inventory_items?select=id`,
    { headers: headersB },
  )
  expect(listAsB.ok()).toBe(true)
  expect(await listAsB.json()).toEqual([])
  for (const itemId of accountAItemIds) {
    const readAAsB = await request.get(
      `${apiUrl}/rest/v1/inventory_items?id=eq.${itemId}&select=id,quantity`,
      { headers: headersB },
    )
    expect(await readAAsB.json()).toEqual([])
    const mutateAAsB = await request.patch(
      `${apiUrl}/rest/v1/inventory_items?id=eq.${itemId}`,
      {
        headers: {
          ...headersB,
          Prefer: 'return=representation',
          'Content-Type': 'application/json',
        },
        data: { quantity: 999 },
      },
    )
    expect(mutateAAsB.ok()).toBe(true)
    expect(await mutateAAsB.json()).toEqual([])
  }

  await page.getByRole('button', { name: 'Profil' }).click()
  await page.getByRole('button', { name: 'Abmelden' }).click()
  const unknownNotice = await requestRecovery(
    page,
    'unknown-account@example.invalid',
  )
  await page.getByRole('button', { name: 'Zur Anmeldung' }).click()
  const knownNotice = await requestRecovery(page, emailA)
  expect(knownNotice).toBe(unknownNotice)

  const recoveryA = await findMail(
    request,
    emailA,
    'Kontozugang wiederherstellen',
  )
  await page.goto(confirmationLink(recoveryA.detail))
  await expect(page.getByRole(
    'heading',
    { name: 'Zwei-Faktor-Bestätigung' },
  )).toBeVisible()
  const recoveryCode = await nextTotp(secret!, lastCode)
  lastCode = recoveryCode
  await page.getByLabel('Sechsstelliger Code').fill(recoveryCode)
  await page.getByRole('button', { name: 'Code bestätigen' }).click()
  await expect(page.getByRole(
    'heading',
    { name: 'Neues Passwort festlegen' },
  )).toBeVisible()
  await page.getByLabel('Neues Passwort', { exact: true }).fill(
    recoveredPasswordA,
  )
  await page.getByLabel('Neues Passwort wiederholen').fill(
    recoveredPasswordA,
  )
  await page.getByRole('button', { name: 'Passwort aktualisieren' }).click()
  await expect(page.getByRole('status')).toHaveText(
    'Das Passwort wurde aktualisiert.',
  )
  await page.goto('/')
  await expect(page.getByRole(
    'heading',
    { name: 'Weedypedia' },
  )).toBeVisible()
  await page.getByRole('button', { name: 'Bestand' }).click()
  await expect(page.getByText('2 g')).toBeVisible()
  await expect(page.getByText('999 g')).toHaveCount(0)

  await clearMailpit(request)
  await page.getByRole('button', { name: 'Profil' }).click()
  await page.getByLabel('Neue E-Mail-Adresse').fill(changedEmailA)
  await page.getByLabel('Aktuelles Passwort für E-Mail-Änderung').fill(
    recoveredPasswordA,
  )
  await page.getByRole('button', { name: 'E-Mail ändern' }).click()
  await expect(page.getByRole('status')).toHaveText(
    'Bestätigungsnachrichten wurden versendet.',
  )
  const oldAddressChange = await findMail(
    request,
    emailA,
    'E-Mail-Änderung bestätigen',
  )
  const newAddressChange = await findMail(
    request,
    changedEmailA,
    'E-Mail-Änderung bestätigen',
  )
  await page.goto(confirmationLink(oldAddressChange.detail))
  await page.goto(confirmationLink(newAddressChange.detail))
  await page.evaluate(() => localStorage.clear())
  await page.goto('/')
  await login(page, changedEmailA, recoveredPasswordA)
  lastCode = await completeMfa(page, secret!, lastCode)

  await page.getByRole('button', { name: 'Profil' }).click()
  await page.getByLabel(
    'Normalisierten Benutzernamen eingeben',
  ).fill(usernameA.toLowerCase())
  await page.getByLabel('Aktuelles Passwort für Kontolöschung').fill(
    recoveredPasswordA,
  )
  const deletionCode = await nextTotp(secret!, lastCode)
  await page.getByLabel('Aktueller TOTP-Code für Kontolöschung').fill(
    deletionCode,
  )
  await page.getByLabel(
    'Ich bestätige die unwiderrufliche Kontolöschung',
  ).check()
  await page.getByRole('button', { name: 'Konto endgültig löschen' }).click()
  await expect(page.getByRole(
    'heading',
    { name: 'Bei Weedypedia anmelden' },
  )).toBeVisible()

  await login(page, changedEmailA, recoveredPasswordA)
  await expect(page.getByRole('alert')).toHaveText(
    'Anmeldung nicht möglich. Prüfe E-Mail-Adresse und Passwort.',
  )
})
