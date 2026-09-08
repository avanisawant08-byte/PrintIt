import { test, expect } from '@playwright/test';

test.describe('PrintIt Customer Web App End-to-End Tests', () => {

  test('01: Customer Web Shell Loads with correct title and scripts', async ({ page }) => {
    await page.goto('/');

    // Check page title (Print It)
    await expect(page).toHaveTitle(/Print\s*It/i);

    // Verify flutter bootstrap elements
    const flutterBootstrap = await page.evaluate(() => {
      return typeof window._flutter !== 'undefined' || document.querySelector('script[src*="flutter"]') !== null;
    });
    expect(flutterBootstrap).toBeTruthy();

    await page.screenshot({ path: 'test-results/screenshots/customer_01_shell.png' });
  });

  test('02: Customer Login and Register Screen Navigation', async ({ page }) => {
    // Set mobile-friendly viewport for customer app
    await page.setViewportSize({ width: 412, height: 915 });

    // Navigate to Login
    await page.goto('/#/login');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: 'test-results/screenshots/customer_02_login.png' });

    // Navigate to Register
    await page.goto('/#/register');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: 'test-results/screenshots/customer_02_register.png' });
  });

  test('03: Authenticated Customer Home, Shops, and Marketplace Navigation', async ({ page }) => {
    test.setTimeout(60000);
    await page.setViewportSize({ width: 412, height: 915 });

    // Step 1: Obtain a live authentication token from the backend
    const authResponse = await page.request.post('http://127.0.0.1:3000/api/auth/login', {
      data: {
        email: 'pradneshkank0935@gmail.com',
        password: 'password123'
      }
    });
    const authData = await authResponse.json();
    const token = authData.token;
    expect(token).toBeTruthy();

    // Step 2: Initialize localStorage on customer domain
    await page.goto('/#/login');
    await page.evaluate(({ jwtToken }) => {
      window.localStorage.setItem('flutter.token', JSON.stringify(jwtToken));
      window.localStorage.setItem('flutter.saved_server_url', JSON.stringify('http://127.0.0.1:3000/api'));
    }, { jwtToken: token });

    // Step 3: Test Home Screen
    await page.goto('/#/home');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/screenshots/customer_03_home.png' });

    // Step 4: Test Browse Categories
    await page.goto('/#/browse-categories');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: 'test-results/screenshots/customer_03_categories.png' });

    // Step 5: Test All Shops List
    await page.goto('/#/shop-list/all?name=All%20Shops');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/screenshots/customer_03_shop_list.png' });

    // Step 6: Test Stationery / Manuals Marketplace
    await page.goto('/#/browse-manuals');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/screenshots/customer_03_marketplace.png' });
  });

  test('04: Authenticated Customer Orders, Wallet, Profile, and Support Navigation', async ({ page }) => {
    test.setTimeout(60000);
    await page.setViewportSize({ width: 412, height: 915 });

    // Obtain token
    const authResponse = await page.request.post('http://127.0.0.1:3000/api/auth/login', {
      data: {
        email: 'pradneshkank0935@gmail.com',
        password: 'password123'
      }
    });
    const authData = await authResponse.json();
    const token = authData.token;
    expect(token).toBeTruthy();

    // Initialize localStorage
    await page.goto('/#/login');
    await page.evaluate(({ jwtToken }) => {
      window.localStorage.setItem('flutter.token', JSON.stringify(jwtToken));
      window.localStorage.setItem('flutter.saved_server_url', JSON.stringify('http://127.0.0.1:3000/api'));
    }, { jwtToken: token });

    // Step 1: Orders History
    await page.goto('/#/orders');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/screenshots/customer_04_orders.png' });

    // Step 2: Wallet
    await page.goto('/#/wallet');
    await page.waitForTimeout(3000);
    await page.screenshot({ path: 'test-results/screenshots/customer_04_wallet.png' });

    // Step 3: Profile
    await page.goto('/#/profile');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: 'test-results/screenshots/customer_04_profile.png' });

    // Step 4: Help & Support
    await page.goto('/#/help');
    await page.waitForTimeout(2500);
    await page.screenshot({ path: 'test-results/screenshots/customer_04_help.png' });
  });

});
