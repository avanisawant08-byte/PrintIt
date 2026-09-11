const { Builder } = require('selenium-webdriver');
const chrome = require('selenium-webdriver/chrome');
const fs = require('fs');
const path = require('path');

async function createDriver(options = {}) {
    const headless = options.headless !== undefined ? options.headless : true;
    const chromeOptions = new chrome.Options();

    if (headless) {
        chromeOptions.addArguments('--headless=new');
    }
    chromeOptions.addArguments(
        '--no-sandbox',
        '--disable-dev-shm-usage',
        '--disable-gpu',
        '--window-size=1366,850',
        '--disable-background-networking',
        '--disable-default-apps',
        '--disable-sync'
    );

    const driver = await new Builder()
        .forBrowser('chrome')
        .setChromeOptions(chromeOptions)
        .build();

    await driver.manage().setTimeouts({
        implicit: 5000,
        pageLoad: 30000,
        script: 15000
    });

    return driver;
}

async function takeScreenshot(driver, filename) {
    try {
        const screenshotDir = path.resolve(__dirname, '../../../test-results/screenshots/selenium');
        if (!fs.existsSync(screenshotDir)) {
            fs.mkdirSync(screenshotDir, { recursive: true });
        }
        const img = await driver.takeScreenshot();
        const filePath = path.join(screenshotDir, filename);
        fs.writeFileSync(filePath, img, 'base64');
        return filePath;
    } catch (e) {
        console.error(`Failed to take screenshot ${filename}:`, e.message);
        return null;
    }
}

module.exports = {
    createDriver,
    takeScreenshot
};
