import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './e2e',
  reporter: 'list',
  use: {
    baseURL: 'http://127.0.0.1:5173',
    headless: true,
  },
  webServer: [
    {
      command:
        'dotnet run --no-launch-profile --project ../api/gh-api/gh-api.csproj --urls http://127.0.0.1:5081',
      url: 'http://127.0.0.1:5081/api/gh-api/hello',
      timeout: 120_000,
      reuseExistingServer: false,
    },
    {
      command: 'npm run dev -- --host 127.0.0.1 --port 5173 --strictPort',
      url: 'http://127.0.0.1:5173',
      timeout: 120_000,
      reuseExistingServer: false,
    },
  ],
});
