import { defineConfig, devices } from '@playwright/test';

export default defineConfig({
  testDir: './tests',
  fullyParallel: false,
  workers: 1,
  retries: 0,
  timeout: 30000,
  reporter: [
    ['list'],
    ['html', { outputFolder: 'playwright-report', open: 'never' }],
    ['json', { outputFile: 'test-results/results.json' }]
  ],
  use: {
    headless: true,
    viewport: { width: 1280, height: 800 },
    screenshot: 'on',
    video: 'off',
    trace: 'retain-on-failure',
  },
  projects: [
    {
      name: 'Shopkeeper Portal',
      testMatch: /.*shopkeeper\.spec\.js/,
      use: {
        baseURL: 'http://127.0.0.1:5173',
      },
    },
    {
      name: 'Customer Web',
      testMatch: /.*customer\.spec\.js/,
      use: {
        baseURL: 'http://127.0.0.1:8080',
      },
    },
  ],
});
