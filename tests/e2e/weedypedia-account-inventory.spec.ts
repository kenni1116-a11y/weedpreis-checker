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
const canonicalCultivarId = '10000000-0000-4000-8000-000000000001'
const aliasName = 'Test-Hybrid – keine Echtdaten'
const canonicalCultivarName = 'Test-Cultivar – keine Echtdaten'
const productName = 'Testprodukt – keine Echtdaten'
const privateEntryName = 'Freier E2E-Bestand – keine Echtdaten'

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
    search: string
    matchText?: string
    expectCommunity?: boolean
    quantity: string
    unit?: 'g' | 'ml' | 'piece'
    originOne?: string
    originTwo?: string
    batch?: string
    expiresOn?: string
    storageLocation?: string
    note?: string
    contribution?: {
      thc: string
      cbd: string
      source: 'label' | 'laboratory'
    }
  },
): Promise<void> {
  await page.getByRole('button', { name: 'Eintrag hinzufügen' }).click()
  const search = page.getByRole('combobox', { name: 'Sorte oder Produkt' })
  await search.fill(input.search)
  if (input.matchText) {
    await page.getByRole('option')
      .filter({ hasText: input.matchText })
      .click()
  } else {
    await expect(page.getByText(
      'Kein Katalogtreffer. Der Name kann privat gespeichert werden.',
    )).toBeVisible()
  }
  if (input.originOne !== undefined) {
    await page.getByLabel('Herkunft 1 (optional)').fill(input.originOne)
  }
  if (input.originTwo !== undefined) {
    await page.getByLabel('Herkunft 2 (optional)').fill(input.originTwo)
  }
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
  if (input.expectCommunity) {
    await expect(page.getByLabel(
      'Community-Werte freiwillig beitragen',
    )).toBeVisible()
  }
  if (input.contribution) {
    await page.getByLabel(
      'Community-Werte freiwillig beitragen',
    ).check()
    await page.getByLabel('THC in Prozent').fill(input.contribution.thc)
    await page.getByLabel('CBD in Prozent').fill(input.contribution.cbd)
    await page.getByLabel('Quelle der Werte').selectOption(
      input.contribution.source,
    )
    await page.getByLabel(
      'Ich bestätige: Die Werte stammen vom Etikett oder aus einem Laborbericht und sind nicht geschätzt.',
    ).check()
  }
  await page.getByRole('button', { name: 'Speichern' }).click()
}

function apiHeaders(token: string): Record<string, string> {
  return {
    apikey: anonKey!,
    Authorization: `Bearer ${token}`,
    'Accept-Profile': 'api',
    'Content-Profile': 'api',
    'Content-Type': 'application/json',
  }
}

async function ownCommunityContribution(
  request: APIRequestContext,
  token: string,
): Promise<Array<{
  cultivar_id: string
  thc_percent: number
  cbd_percent: number
  source_kind: string
}>> {
  const response = await request.post(
    `${apiUrl}/rest/v1/rpc/get_my_community_flower_contribution`,
    {
      headers: apiHeaders(token),
      data: { p_cultivar_id: canonicalCultivarId },
    },
  )
  expect(response.ok()).toBe(true)
  return response.json()
}

async function ownInventory(
  request: APIRequestContext,
  token: string,
): Promise<Array<{ id: string; entry_name: string }>> {
  const response = await request.get(
    `${apiUrl}/rest/v1/inventory_items?select=id,entry_name&order=created_at.asc`,
    { headers: apiHeaders(token) },
  )
  expect(response.ok()).toBe(true)
  return response.json()
}

async function accessToken(page: Page): Promise<string> {
  let token = ''
  await expect.poll(async () => {
    token = await page.evaluate(() => {
      for (const key of Object.keys(localStorage)) {
        if (!key.startsWith('sb-') || !key.endsWith('-auth-token')) continue
        const value = localStorage.getItem(key)
        if (!value) continue
        const parsed = JSON.parse(value) as { access_token?: string }
        if (parsed.access_token) return parsed.access_token
      }
      return ''
    })
    return token
  }, {
    message: 'persisted browser access token',
  }).not.toBe('')
  return token
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
  test.setTimeout(300_000)
  expect(apiUrl, 'E2E_SUPABASE_API_URL').toBeTruthy()
  expect(anonKey, 'E2E_SUPABASE_ANON_KEY').toBeTruthy()
  const runMarker = (
    `${process.env.GITHUB_RUN_ID ?? Date.now().toString(36)}-`
    + `${process.env.GITHUB_RUN_ATTEMPT ?? 'local'}`
  ).slice(-12)
  const identityMarker = `${runMarker}-${testInfo.retry}`
  const emailA = `account-a-${identityMarker}@example.invalid`
  const changedEmailA = `account-a-new-${identityMarker}@example.invalid`
  const emailB = `account-b-${identityMarker}@example.invalid`
  const usernameA = `Account.A.${identityMarker}`
  const usernameB = `Account.B.${identityMarker}`
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
  await expect(page.getByRole(
    'heading',
    { name: 'Zwei-Faktor-Bestätigung' },
  )).toBeVisible()

  const aal1Token = await accessToken(page)
  const blockedCommunityRead = await request.post(
    `${apiUrl}/rest/v1/rpc/get_my_community_flower_contribution`,
    {
      headers: apiHeaders(aal1Token),
      data: { p_cultivar_id: canonicalCultivarId },
    },
  )
  expect(blockedCommunityRead.ok()).toBe(false)

  let lastCode = await completeMfa(page, secret!, enrollmentCode)
  let tokenA = await accessToken(page)
  expect(await ownCommunityContribution(request, tokenA)).toEqual([])

  await page.getByRole('button', { name: 'Bestand' }).click()
  await page.getByRole('button', { name: 'Eintrag hinzufügen' }).click()
  const aliasSearch = page.getByRole('combobox', {
    name: 'Sorte oder Produkt',
  })
  await aliasSearch.fill('Test-Hybrid')
  const aliasOption = page.getByRole('option').filter({ hasText: aliasName })
  await expect(aliasOption).toContainText('Alias')
  await expect(aliasOption).toContainText(canonicalCultivarName)
  await aliasOption.click()
  await expect(aliasSearch).toHaveValue(aliasName)
  await expect(page.getByText(
    `Kanonischer Vorschlag: ${canonicalCultivarName}`,
  )).toBeVisible()
  await expect(page.getByLabel('Herkunft 1 (optional)')).toHaveValue(
    'Test-Ursprung A – keine Echtdaten',
  )
  await expect(page.getByLabel('Herkunft 2 (optional)')).toHaveValue(
    'Test-Ursprung B – keine Echtdaten',
  )
  await page.getByLabel('Herkunft 2 (optional)').fill(
    'Privat angepasste Herkunft – keine Echtdaten',
  )
  await page.getByLabel('Menge').fill('2')
  await expect(page.getByLabel(
    'Community-Werte freiwillig beitragen',
  )).toHaveCount(0)
  await page.getByRole('button', { name: 'Speichern' }).click()
  await expect(page.getByRole('status')).toHaveText('Gespeichert.')
  await expect(page.getByRole(
    'heading',
    { name: aliasName },
  )).toBeVisible()

  await page.reload()
  await page.getByRole('button', { name: 'Bestand' }).click()
  await expect(page.getByText(
    'Privat angepasste Herkunft – keine Echtdaten',
  )).toBeVisible()
  await page.getByRole('button', { name: `${aliasName} bearbeiten` }).click()
  await expect(page.getByLabel('Herkunft 1 (optional)')).toHaveValue(
    'Test-Ursprung A – keine Echtdaten',
  )
  await expect(page.getByLabel('Herkunft 2 (optional)')).toHaveValue(
    'Privat angepasste Herkunft – keine Echtdaten',
  )
  await page.getByRole('button', { name: 'Abbrechen' }).click()

  await addInventory(page, {
    search: privateEntryName,
    quantity: '0.5',
    note: 'Nur privater Freitext.',
  })
  await expect(page.getByRole(
    'heading',
    { name: privateEntryName },
  )).toBeVisible()
  await expect(page.getByLabel(
    'Community-Werte freiwillig beitragen',
  )).toHaveCount(0)

  await page.getByRole('button', { name: 'Eintrag hinzufügen' }).click()
  const productSearch = page.getByRole('combobox', {
    name: 'Sorte oder Produkt',
  })
  await productSearch.fill('Testprodukt')
  const productOption = page.getByRole('option').filter({
    hasText: productName,
  })
  await expect(productOption).toContainText('Produkt')
  await productOption.click()
  await expect(page.getByLabel(
    'Community-Werte freiwillig beitragen',
  )).toBeVisible()
  await page.getByLabel('Menge').fill('1')
  await page.getByLabel('Einheit').selectOption('piece')
  await page.getByLabel('Charge (optional)').fill('SYNTHETIC-BATCH')
  await page.getByLabel('Ablaufdatum (optional)').fill('2027-07-25')
  await page.getByLabel('Lagerort (optional)').fill('Testschrank')
  await page.getByLabel('Notiz (optional)').fill(
    'Ausschließlich synthetischer E2E-Eintrag.',
  )
  await page.getByLabel('Community-Werte freiwillig beitragen').check()
  await page.getByLabel('THC in Prozent').fill('70,01')
  await page.getByLabel('CBD in Prozent').fill('0')
  await page.getByLabel('Quelle der Werte').selectOption('label')
  await page.getByLabel(
    'Ich bestätige: Die Werte stammen vom Etikett oder aus einem Laborbericht und sind nicht geschätzt.',
  ).check()
  await page.getByRole('button', { name: 'Speichern' }).click()
  await expect(page.getByText(
    'Keine Fantasiewerte. Bitte AUSSCHLIESSLICH die Werte des Labels oder eines Laborberichts angeben.',
  ).first()).toBeVisible()
  await page.getByLabel('THC in Prozent').fill('70,00')
  await page.getByRole('button', { name: 'Speichern' }).click()
  await expect(page.getByRole('status')).toHaveText(
    'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
  )
  await expect(page.getByText('2 g')).toBeVisible()
  await expect(page.getByText('1 Stück')).toBeVisible()

  tokenA = await accessToken(page)
  expect((await ownCommunityContribution(request, tokenA))[0]).toMatchObject({
    cultivar_id: canonicalCultivarId,
    thc_percent: 70,
    cbd_percent: 0,
    source_kind: 'label',
  })
  await page.getByRole(
    'button',
    { name: `${productName} bearbeiten` },
  ).click()
  await expect(page.getByLabel('THC in Prozent')).toHaveValue('70')
  await page.getByLabel('THC in Prozent').fill('22,5')
  await page.getByLabel('CBD in Prozent').fill('0,8')
  await page.getByLabel('Quelle der Werte').selectOption('laboratory')
  await page.getByRole('button', { name: 'Änderungen speichern' }).click()
  await expect(page.getByRole('status')).toHaveText(
    'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
  )
  await expect.poll(async () => ownCommunityContribution(
    request,
    tokenA,
  )).toEqual([
    expect.objectContaining({
      cultivar_id: canonicalCultivarId,
      thc_percent: 22.5,
      cbd_percent: 0.8,
      source_kind: 'laboratory',
    }),
  ])

  const invalidContributionBase = {
    p_cultivar_id: canonicalCultivarId,
    p_thc_percent: 23,
    p_cbd_percent: 1,
    p_consent_version: 'weedypedia-community-values-2026-07-28',
  }
  for (const invalidInput of [
    {
      ...invalidContributionBase,
      p_source_kind: null,
      p_declaration_confirmed: true,
      p_opt_in: true,
    },
    {
      ...invalidContributionBase,
      p_source_kind: 'label',
      p_declaration_confirmed: false,
      p_opt_in: true,
    },
    {
      ...invalidContributionBase,
      p_source_kind: 'label',
      p_declaration_confirmed: true,
      p_opt_in: false,
    },
  ]) {
    const rejected = await request.post(
      `${apiUrl}/rest/v1/rpc/upsert_my_community_flower_contribution`,
      { headers: apiHeaders(tokenA), data: invalidInput },
    )
    expect(rejected.ok()).toBe(false)
  }
  expect((await ownCommunityContribution(request, tokenA))[0]).toMatchObject({
    thc_percent: 22.5,
    cbd_percent: 0.8,
  })

  let failCommunityOnce = true
  await page.route(
    '**/rest/v1/rpc/upsert_my_community_flower_contribution',
    async (route) => {
      if (failCommunityOnce) {
        failCommunityOnce = false
        await route.fulfill({
          status: 503,
          contentType: 'application/json',
          body: JSON.stringify({ message: 'synthetic retry boundary' }),
        })
        return
      }
      await route.continue()
    },
  )
  await addInventory(page, {
    search: 'Testprodukt',
    matchText: productName,
    expectCommunity: true,
    quantity: '3',
    contribution: {
      thc: '24',
      cbd: '1',
      source: 'label',
    },
  })
  await expect(page.getByRole('alert')).toHaveText(
    'Der Bestand wurde gespeichert. Der Community-Beitrag konnte nicht übernommen werden.',
  )
  const inventoryBeforeRetry = await ownInventory(request, tokenA)
  expect(inventoryBeforeRetry).toHaveLength(4)
  await page.getByRole(
    'button',
    { name: 'Community-Beitrag erneut versuchen' },
  ).click()
  await expect(page.getByRole('status')).toHaveText(
    'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
  )
  expect(await ownInventory(request, tokenA)).toHaveLength(4)
  await page.unroute(
    '**/rest/v1/rpc/upsert_my_community_flower_contribution',
  )
  expect((await ownCommunityContribution(request, tokenA))[0]).toMatchObject({
    thc_percent: 24,
    cbd_percent: 1,
  })

  await page.getByRole('button', { name: `${aliasName} löschen` }).click()
  await page.getByRole('button', { name: 'Löschen bestätigen' }).click()
  await expect(page.getByRole(
    'heading',
    { name: aliasName },
  )).toHaveCount(0)
  expect(await ownCommunityContribution(request, tokenA)).toHaveLength(1)

  const productDeleteButtons = page.getByRole(
    'button',
    { name: `${productName} löschen` },
  )
  await productDeleteButtons
    .first()
    .click()
  await page.getByRole('button', { name: 'Löschen bestätigen' }).click()
  await expect(productDeleteButtons).toHaveCount(1)
  expect(await ownCommunityContribution(request, tokenA)).toHaveLength(1)
  await productDeleteButtons.click()
  await page.getByRole('button', { name: 'Löschen bestätigen' }).click()
  await expect(productDeleteButtons).toHaveCount(0)
  await expect.poll(async () => ownCommunityContribution(
    request,
    tokenA,
  )).toEqual([])

  await addInventory(page, {
    search: 'Testprodukt',
    matchText: productName,
    expectCommunity: true,
    quantity: '1',
    unit: 'piece',
    contribution: {
      thc: '25',
      cbd: '1,2',
      source: 'laboratory',
    },
  })
  await expect(page.getByRole('status')).toHaveText(
    'Gespeichert. Der Community-Mittelwert wird später aktualisiert.',
  )
  expect(await ownInventory(request, tokenA)).toHaveLength(2)
  expect((await ownCommunityContribution(request, tokenA))[0]).toMatchObject({
    thc_percent: 25,
    cbd_percent: 1.2,
    source_kind: 'laboratory',
  })

  await page.reload()
  await page.getByRole('button', { name: 'Bestand' }).click()
  await expect(page.getByText('Nur privater Freitext.')).toBeVisible()
  await expect(page.getByRole(
    'heading',
    { name: productName },
  )).toBeVisible()
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
    communityFlowerContributions: Array<{
      cultivarId: string
      cultivarName: string
      thcPercent: number
      cbdPercent: number
      sourceKind: string
      consentVersion: string
    }>
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
  expect(accountExport.communityFlowerContributions).toEqual([
    expect.objectContaining({
      cultivarId: canonicalCultivarId,
      cultivarName: canonicalCultivarName,
      thcPercent: 25,
      cbdPercent: 1.2,
      sourceKind: 'laboratory',
      consentVersion: 'weedypedia-community-values-2026-07-28',
    }),
  ])
  expect(exportText).not.toContain(passwordA)
  expect(exportText).not.toMatch(
    /access_token|refresh_token|app_metadata|user_metadata|service_role|contributor_count|review_status/i,
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
  const headersB = apiHeaders(tokenB)
  const listAsB = await request.get(
    `${apiUrl}/rest/v1/inventory_items?select=id`,
    { headers: headersB },
  )
  expect(listAsB.ok()).toBe(true)
  expect(await listAsB.json()).toEqual([])
  expect(await ownCommunityContribution(request, tokenB)).toEqual([])
  const rawContributionRead = await request.get(
    `${apiUrl}/rest/v1/community_flower_contributions?select=*`,
    {
      headers: {
        ...headersB,
        'Accept-Profile': 'private',
      },
    },
  )
  expect(rawContributionRead.ok()).toBe(false)
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
  await expect(page.getByRole(
    'heading',
    { name: privateEntryName },
  )).toBeVisible()
  await expect(page.getByRole(
    'heading',
    { name: productName },
  )).toBeVisible()
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
  lastCode = await completeMfa(page, secret!, lastCode)
  await page.getByRole('button', { name: 'Profil' }).click()
  await page.getByRole('button', { name: 'Abmelden' }).click()
  await login(page, changedEmailA, recoveredPasswordA)
  lastCode = await completeMfa(page, secret!, lastCode)
  tokenA = await accessToken(page)

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
  const tokenBeforeDeletion = tokenA
  await page.getByRole('button', { name: 'Konto endgültig löschen' }).click()
  await expect(page.getByRole(
    'heading',
    { name: 'Bei Weedypedia anmelden' },
  )).toBeVisible()

  await login(page, changedEmailA, recoveredPasswordA)
  await expect(page.getByRole('alert')).toHaveText(
    'Anmeldung nicht möglich. Prüfe E-Mail-Adresse und Passwort.',
  )

  expect(await ownInventory(request, tokenBeforeDeletion)).toEqual([])
  expect(
    await ownCommunityContribution(request, tokenBeforeDeletion),
  ).toEqual([])
})
