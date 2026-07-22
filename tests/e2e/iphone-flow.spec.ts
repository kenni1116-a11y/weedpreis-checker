import { expect, test } from '@playwright/test'

test('adult user compares a 10 g shipping offer', async ({ page }) => {
  await page.goto('/')
  await page.getByRole('button', { name: 'Ich bin mindestens 18 Jahre alt' }).click()
  await page.getByRole('searchbox').fill('Alpha')
  await page.getByRole('button', { name: 'Suchen' }).click()

  await expect(page.getByText('Ausschließlich synthetische Testdaten')).toBeVisible()
  await expect(page.getByText(/Gesamtpreis für 10 g/).first()).toBeVisible()
  await expect(page.locator('meta[name="theme-color"]')).toHaveAttribute('content', '#07110f')
})
