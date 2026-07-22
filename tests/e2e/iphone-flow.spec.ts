import { expect, test } from '@playwright/test'

test('adult user compares a 10 g shipping offer', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }).click()
  await page.getByRole('searchbox').fill('Alpha')
  await page.getByRole('button', { name: 'Suchen' }).click()

  await expect(page.getByText('Ausschließlich synthetische Testdaten')).toBeVisible()
  await expect(page.getByText(/Gesamtpreis für 10 g/).first()).toBeVisible()
  await expect(page.locator('meta[name="theme-color"]')).toHaveAttribute('content', '#07110f')

  const manifestHref = await page.locator('link[rel="manifest"]').getAttribute('href')
  expect(manifestHref).toBeTruthy()
  const manifest = await page.request.get(new URL(manifestHref!, page.url()).toString())
  expect((await manifest.json()).lang).toBe('de')
})

test('pickup limitations and interactive controls are clear on iPhone', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }).click()
  await page.getByRole('button', { name: 'Abholung' }).click()

  await expect(page.getByText(/keine Live-Standortsuche/i)).toBeVisible()
  const selectBox = await page.getByRole('combobox', { name: 'Darreichungsform' }).boundingBox()
  expect(selectBox?.height).toBeGreaterThanOrEqual(44)

  await page.getByRole('button', { name: 'Suchen' }).click()
  const pharmacyLinkBox = await page.getByRole('link', { name: 'Zur Apotheke' }).first().boundingBox()
  expect(pharmacyLinkBox?.height).toBeGreaterThanOrEqual(44)
})
