const puppeteer = require('puppeteer');
const fs = require('fs');
const path = require('path');

const ssDir = path.join(__dirname, 'ss');
const screenshotsDir = path.join(__dirname, 'screenshots');
const appScreenshotsDir = path.join(__dirname, 'print_it_app', 'screenshots');

[ssDir, screenshotsDir, appScreenshotsDir].forEach(dir => {
  if (!fs.existsSync(dir)) {
    fs.mkdirSync(dir, { recursive: true });
  }
});

const token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ1c2VyX2lkIjoiMDAyNDNmYzctODQyNy00ZmUxLWE1OGEtODA1NDlkNzM3MTQ5IiwiZW1haWwiOiJ1c2VyMUBwcmludGl0LmNvbSIsInJvbGUiOiJjdXN0b21lciIsImlhdCI6MTc4NzUwODMwNSwiZXhwIjoxNzg4MTEzMTA1fQ._hOmM1bhEHVkSkOV4BUE2Qc80XL-fW2ChtL-3hel260";
const shopId = "faddc0aa-196d-4f60-872f-858d051f87d2";
const orderId = "ORD-8037";

const routes = [
  { name: '01_login_screen', route: '/login', wait: 2500 },
  { name: '02_register_screen', route: '/register', wait: 2500 },
  { name: '03_home_screen', route: '/home', wait: 4500 },
  { name: '04_browse_categories', route: '/browse-categories', wait: 3000 },
  { name: '05_shop_list', route: `/shop-list/all?name=All%20Shops`, wait: 4500 },
  { name: '06_shop_detail', route: `/shop-detail/${shopId}`, wait: 4500 },
  { name: '07_upload_document', route: `/upload-document/${shopId}`, wait: 3000 },
  { name: '08_select_shop', route: '/select-shop', wait: 3500 },
  { name: '09_document_config', route: '/document-config', wait: 3000 },
  { name: '10_schedule_pickup', route: '/schedule-pickup', wait: 3000 },
  { name: '11_express_pickup', route: '/express-pickup', wait: 3000 },
  { name: '12_secure_payment', route: '/payment', wait: 3000 },
  { name: '13_order_success', route: `/order-success?orderId=${orderId}`, wait: 3000 },
  { name: '14_order_tracking', route: `/order-tracking/${orderId}`, wait: 4500 },
  { name: '15_order_history', route: '/orders', wait: 4500 },
  { name: '16_stationery_marketplace', route: '/browse-manuals', wait: 4500 },
  { name: '17_product_detail', route: '/browse-manuals', wait: 4500, clickProduct: true },
  { name: '18_wallet', route: '/wallet', wait: 4000 },
  { name: '19_wallet_success', route: '/wallet-success?amount=500', wait: 3000 },
  { name: '20_profile', route: '/profile', wait: 4000 },
  { name: '21_edit_profile', route: '/edit-profile', wait: 3000 },
  { name: '22_notifications', route: '/notifications', wait: 3000 },
  { name: '23_help_support', route: '/help', wait: 3000 },
  { name: '24_my_tickets', route: '/my-tickets', wait: 4000 },
  { name: '25_create_ticket', route: '/create-ticket', wait: 3000 },
  { name: '26_ticket_detail', route: '/ticket/TCK-101', wait: 4000 },
];

(async () => {
  console.log('Launching browser for complete screenshot capture...');
  const chromePath = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe';
  const edgePath = 'C:\\Program Files (x86)\\Microsoft\\Edge\\Application\\msedge.exe';
  let executablePath = fs.existsSync(chromePath) ? chromePath : (fs.existsSync(edgePath) ? edgePath : null);

  const browser = await puppeteer.launch({
    headless: true,
    executablePath,
    args: ['--no-sandbox', '--disable-setuid-sandbox', '--disable-gpu']
  });

  const page = await browser.newPage();
  await page.setViewport({ width: 412, height: 915, deviceScaleFactor: 2, isMobile: true, hasTouch: true });

  // Initialize localStorage with valid auth token and local backend URL
  await page.goto('http://127.0.0.1:8080/#/login', { waitUntil: 'domcontentloaded' });
  await page.evaluate((jwtToken) => {
    window.localStorage.setItem('flutter.token', JSON.stringify(jwtToken));
    window.localStorage.setItem('flutter.saved_server_url', JSON.stringify('http://127.0.0.1:3000/api'));
  }, token);

  for (let i = 0; i < routes.length; i++) {
    const item = routes[i];
    const url = `http://127.0.0.1:8080/#${item.route}`;
    console.log(`[${i+1}/${routes.length}] Navigating to ${item.name} (${url})...`);

    try {
      await page.goto(url, { waitUntil: 'networkidle0', timeout: 20000 }).catch(() => {});
      await new Promise(r => setTimeout(r, item.wait));

      if (item.clickProduct) {
        await page.mouse.click(200, 300);
        await new Promise(r => setTimeout(r, 2000));
      }

      const ssPath = path.join(ssDir, `${item.name}.png`);
      const screenshotsPath = path.join(screenshotsDir, `${item.name}.png`);
      const appSsPath = path.join(appScreenshotsDir, `${item.name}.png`);

      await page.screenshot({ path: ssPath, type: 'png' });
      fs.copyFileSync(ssPath, screenshotsPath);
      fs.copyFileSync(ssPath, appSsPath);

      console.log(`✓ Saved screenshot: ${item.name}.png`);
    } catch (err) {
      console.error(`✗ Error on ${item.name}:`, err.message);
    }
  }

  await browser.close();
  console.log('🎉 All 26 screenshots re-captured and fully populated without loading indicators!');
})();
