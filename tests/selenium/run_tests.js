const http = require('http');
const { spawn } = require('child_process');
const path = require('path');
const { createDriver } = require('./helpers/driver');
const { runShopkeeperTestSuite } = require('./shopkeeper_portal.test');

function checkHttp(url, timeoutMs = 2000) {
    return new Promise((resolve) => {
        const u = new URL(url);
        const req = http.request({
            hostname: u.hostname,
            port: u.port,
            path: u.pathname,
            method: 'GET',
            timeout: timeoutMs
        }, (res) => {
            resolve(true);
        });
        req.on('error', () => resolve(false));
        req.on('timeout', () => {
            req.destroy();
            resolve(false);
        });
        req.end();
    });
}

async function waitForServer(url, name, maxWaitMs = 30000) {
    const start = Date.now();
    process.stdout.write(`⏳ Waiting for ${name} at ${url}... `);
    while (Date.now() - start < maxWaitMs) {
        const isUp = await checkHttp(url);
        if (isUp) {
            console.log('Online! ✅');
            return true;
        }
        await new Promise(r => setTimeout(r, 1000));
    }
    console.log('Timed out! ❌');
    return false;
}

async function main() {
    console.log('================================================================');
    console.log('🧪 PRINTIT SELENIUM END-TO-END TEST RUNNER');
    console.log('================================================================\n');

    const spawnedProcesses = [];

    const isWin = process.platform === 'win32';

    try {
        // 1. Check & start Backend if needed
        const backendUrl = 'http://127.0.0.1:3000/api/health';
        let backendRunning = await checkHttp(backendUrl);

        if (!backendRunning) {
            console.log('📦 Starting Backend server on port 3000...');
            const backendProc = spawn(isWin ? 'node.exe' : 'node', ['src/app.js'], {
                cwd: path.resolve(__dirname, '../../backend'),
                stdio: 'inherit',
                shell: false
            });
            spawnedProcesses.push(backendProc);
            const isReady = await waitForServer(backendUrl, 'Backend Server', 25000);
            if (!isReady) {
                throw new Error('Backend failed to start on port 3000');
            }
        } else {
            console.log('✅ Backend server is already running on port 3000.');
        }

        // 2. Check & start Shop Portal if needed
        const portalUrl = 'http://127.0.0.1:5173/';
        let portalRunning = await checkHttp(portalUrl);

        if (!portalRunning) {
            console.log('📦 Starting Shop Portal Vite dev server on port 5173...');
            const cmd = isWin ? 'cmd.exe' : 'npx';
            const args = isWin ? ['/c', 'npx', 'vite', '--port', '5173', '--host', '127.0.0.1'] : ['vite', '--port', '5173', '--host', '127.0.0.1'];
            const portalProc = spawn(cmd, args, {
                cwd: path.resolve(__dirname, '../../shop_portal'),
                stdio: 'ignore',
                shell: false
            });
            spawnedProcesses.push(portalProc);
            const isReady = await waitForServer(portalUrl, 'Shopkeeper Portal', 30000);
            if (!isReady) {
                throw new Error('Shop Portal failed to start on port 5173');
            }
        } else {
            console.log('✅ Shop Portal is already running on port 5173.');
        }

        // 3. Initialize Selenium WebDriver
        console.log('\n🌐 Initializing Headless Chrome WebDriver...');
        const driver = await createDriver({ headless: true });
        console.log('✅ Chrome WebDriver initialized successfully.');

        // 4. Run Test Suite
        try {
            const results = await runShopkeeperTestSuite(driver, 'http://127.0.0.1:5173');
            await driver.quit();

            if (results.failed > 0) {
                process.exit(1);
            } else {
                process.exit(0);
            }
        } catch (testError) {
            console.error('Fatal error during test execution:', testError);
            try { await driver.quit(); } catch (_) {}
            process.exit(1);
        }

    } catch (err) {
        console.error('Test runner setup error:', err.message);
        process.exit(1);
    } finally {
        for (const proc of spawnedProcesses) {
            try {
                if (process.platform === 'win32') {
                    spawn('taskkill', ['/pid', proc.pid, '/f', '/t']);
                } else {
                    proc.kill('SIGTERM');
                }
            } catch (_) {}
        }
    }
}

main();
