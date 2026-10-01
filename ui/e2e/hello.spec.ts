import { expect, test } from '@playwright/test';

test('renders the greeting returned by the running API', async ({ page }) => {
  // AC3
  const apiResponse = page.waitForResponse((response) =>
    response.url().includes('/api/gh-api/hello'),
  );

  await page.goto('/');

  const response = await apiResponse;
  expect(response.status()).toBe(200);
  await expect(
    page.getByRole('heading', { name: 'Hello, world!' }),
  ).toBeVisible();
});
