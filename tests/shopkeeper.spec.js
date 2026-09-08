import { test, expect } from '@playwright/test';

test.describe('PrintIt Shopkeeper Portal End-to-End Tests', () => {

  test('01: Shopkeeper Landing Page displays branding and navigation', async ({ page }) => {
    await page.goto('/');
    
    // Check Title
    await expect(page).toHaveTitle(/PrintIt/i);

    // Verify Main Heading & CTA buttons
    const heading = page.locator('h1');
    await expect(heading).toContainText(/Partner Portal/i);

    const signInBtn = page.getByRole('button', { name: /Sign In to Dashboard/i });
    await expect(signInBtn).toBeVisible();

    const registerBtn = page.getByRole('button', { name: /Register New Shop/i });
    await expect(registerBtn).toBeVisible();

    // Verify Footer Legal Links
    const privacyLink = page.getByRole('link', { name: /Privacy Policy/i });
    await expect(privacyLink).toBeVisible();

    const termsLink = page.getByRole('link', { name: /Terms of Service/i });
    await expect(termsLink).toBeVisible();

    const refundLink = page.getByRole('link', { name: /Refund & Cancellation/i });
    await expect(refundLink).toBeVisible();

    // Take screenshot
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_01_landing.png' });
  });

  test('02: Legal and Policy pages load and navigate back', async ({ page }) => {
    // Visit Privacy Policy
    await page.goto('/privacy');
    await expect(page.locator('h1')).toContainText(/Privacy/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_02_privacy.png' });

    // Visit Terms of Service
    await page.goto('/terms');
    await expect(page.locator('h1')).toContainText(/Terms/i);

    // Visit Refund Policy
    await page.goto('/refund-policy');
    await expect(page.locator('h1')).toContainText(/Refund/i);

    // Visit Security Policy
    await page.goto('/security');
    await expect(page.locator('h1')).toContainText(/Security/i);

    // Visit Accessibility Statement
    await page.goto('/accessibility');
    await expect(page.locator('h1')).toContainText(/Accessibility/i);
  });

  test('03: Shopkeeper Login validation with invalid and valid credentials', async ({ page }) => {
    await page.goto('/login');

    // Verify form elements
    const emailInput = page.locator('input[type="email"]');
    const passwordInput = page.locator('input[type="password"]');
    const submitBtn = page.locator('button[type="submit"]');

    await expect(emailInput).toBeVisible();
    await expect(passwordInput).toBeVisible();
    await expect(submitBtn).toBeVisible();

    // Test invalid login
    await emailInput.fill('invalid@shop.com');
    await passwordInput.fill('wrongpassword');
    await submitBtn.click();

    // Verify error notification
    const alert = page.locator('[role="alert"]');
    await expect(alert).toBeVisible({ timeout: 10000 });
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_03_login_invalid.png' });

    // Test valid shopkeeper login
    await emailInput.fill('avani.sawant24@pcpolytechnic.com');
    await passwordInput.fill('password123');
    await submitBtn.click();

    // Verify redirect to dashboard
    await expect(page).toHaveURL(/.*dashboard.*/, { timeout: 15000 });
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_03_login_success.png' });
  });

  test('04: Dashboard Live Queue and Navigation items', async ({ page }) => {
    // Log in directly or set auth state
    await page.goto('/login');
    await page.locator('input[type="email"]').fill('avani.sawant24@pcpolytechnic.com');
    await page.locator('input[type="password"]').fill('password123');
    await page.locator('button[type="submit"]').click();
    await expect(page).toHaveURL(/.*dashboard.*/, { timeout: 15000 });

    // Verify Live Queue navigation item and content
    await page.goto('/dashboard/queue');
    await expect(page.locator('body')).toContainText(/Queue|Live Queue|Orders/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_live_queue.png' });

    // Verify Orders tab
    await page.goto('/dashboard/orders');
    await expect(page.locator('body')).toContainText(/Orders/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_orders.png' });

    // Verify My Listings tab
    await page.goto('/dashboard/listings');
    await expect(page.locator('body')).toContainText(/Listings|Catalogue|Products/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_listings.png' });

    // Verify Pricing tab
    await page.goto('/dashboard/pricing');
    await expect(page.locator('body')).toContainText(/Pricing|Rates|Per Page/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_pricing.png' });

    // Verify Wallet tab
    await page.goto('/dashboard/wallet');
    await expect(page.locator('body')).toContainText(/Wallet|Earnings|Payout/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_wallet.png' });

    // Verify Analytics tab
    await page.goto('/dashboard/analytics');
    await expect(page.locator('body')).toContainText(/Analytics|Performance|Revenue/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_analytics.png' });

    // Verify Settings tab
    await page.goto('/dashboard/settings');
    await expect(page.locator('body')).toContainText(/Settings|Profile|Shop/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_settings.png' });

    // Verify Support tab
    await page.goto('/dashboard/support');
    await expect(page.locator('body')).toContainText(/Support|FAQ|Help/i);
    await page.screenshot({ path: 'test-results/screenshots/shopkeeper_04_support.png' });
  });

});
