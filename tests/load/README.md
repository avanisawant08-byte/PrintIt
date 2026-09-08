# PrintIt — Complete k6 File-Upload Load & Stress Testing Suite

This directory contains a complete, dedicated load- and stress-testing framework using **k6** tailored specifically for the PrintIt backend, file-upload system, storage provider, and PostgreSQL database.

---

## ⚠️ SAFETY & PRE-FLIGHT WARNING

> [!WARNING]
> **DO NOT RUN HIGH-CONCURRENCY TESTS (50–100+ VUs) AGAINST PRODUCTION WITHOUT PRIOR NOTICE.**
> - High concurrency file uploads consume significant network bandwidth, memory on the Node.js server, and storage quota in Firebase.
> - Default `BASE_URL` is hardcoded to `http://127.0.0.1:3000` (Localhost / Staging).
> - Always monitor the backend host process and database connections while executing heavy load tests.

---

## 1. Project Analysis & Technical Specifications

| Parameter | Actual Project Implementation | Source of Truth |
|---|---|---|
| **Backend Framework** | Node.js Express 5.2.1 | `backend/src/app.js` |
| **Server Entry Point** | `backend/src/app.js` (default port `3000`) | `backend/src/app.js` |
| **File-Upload Endpoints** | `POST /api/upload` (Authenticated)<br>`POST /api/upload/guest` (Public/Guest)<br>`POST /api/upload/multiple` (Batch up to 5) | `backend/src/routes/uploadRoutes.js` |
| **HTTP Method** | `POST` | `backend/src/routes/uploadRoutes.js` |
| **Multipart Form Field** | `file` (single) or `files` (multiple) | `backend/src/config/multer.js` |
| **Authentication** | JWT Bearer (`Authorization: Bearer <token>`) via `auth` middleware | `backend/src/middleware/auth.js` |
| **Storage Provider** | Google Cloud Storage via Firebase Admin SDK (`bucket.file().createWriteStream()`) | `backend/src/routes/uploadRoutes.js` |
| **Bucket Name** | `printit-4d823.firebasestorage.app` | `backend/.env` |
| **Max Allowed File Size** | **10 MB** (`10 * 1024 * 1024` bytes) | `backend/src/config/multer.js` |
| **Accepted MIME Types** | `application/pdf`, `image/jpeg`, `image/png`, `image/webp`, `application/msword`, `docx`, `ppt`, `pptx`, `xls`, `xlsx`, `text/plain` | `backend/src/config/multer.js` |
| **Storage Mechanism** | `multer.memoryStorage()` (files buffered into Node.js heap RAM before upload) | `backend/src/config/multer.js` |
| **Database** | PostgreSQL (Supabase pooler on AWS ap-southeast-1) via `pg.Pool` | `backend/src/config/db.js` |
| **Database Pool Limits** | `max: 20`, `idleTimeoutMillis: 30000`, `connectionTimeoutMillis: 10000` | `backend/src/config/db.js` |
| **Rate Limiting** | Multi-tier rate limiting via `express-rate-limit` (`apiLimiter`, `authLimiter`, `paymentLimiter`) | `backend/src/middleware/rateLimiter.js` |

---

## 2. Directory Structure

```text
tests/load/
├── assets/                       # Realistic binary test documents
│   ├── test_100k.pdf             # 100 KB PDF
│   ├── test_500k.pdf             # 500 KB PDF
│   ├── test_1m.pdf               # 1 MB PDF
│   ├── test_5m.pdf               # 5 MB PDF
│   ├── test_10m.pdf              # 10 MB PDF (at Multer limit)
│   ├── test_oversize_12m.pdf     # 12 MB PDF (exceeds limit, for negative test)
│   ├── test_empty.pdf            # 0 KB PDF (empty file)
│   └── test_unsupported.exe      # Executable (unsupported MIME/ext)
├── generate_assets.js            # Script to recreate realistic binary test files
├── upload_test.js                # Core test script (Baseline, Normal, Moderate, Heavy, Stress)
├── spike_test.js                 # Dedicated 0 -> 10 -> 25 -> 50 -> 100 VU spike test
├── negative_tests.js             # Negative edge cases (auth, size, types, malformed)
└── README.md                     # Complete execution and monitoring guide
```

---

## 3. Installation of k6

### Windows (Portable / Pre-configured)
k6 is already installed in `C:\Users\avani\.k6\k6.exe` and copied to `C:\Users\avani\AppData\Roaming\npm\k6.exe`.
Verify installation:
```powershell
k6 version
```

### macOS
```bash
brew install k6
```

### Linux / Ubuntu
```bash
sudo gpg -k
sudo gpg --no-default-keyring --keyring /usr/share/keyrings/k6-archive-keyring.gpg --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys C5AD17C747E3415A3642D57D77C6C491D6AC1D69
echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
sudo apt-get update && sudo apt-get install k6
```

---

## 4. Test Scenarios & Exact Commands

Make sure your backend is running (`node src/app.js` in `backend/`).

### Scenario A: Baseline (5 Concurrent Users)
Simulates low, steady traffic to establish performance baselines.
```bash
k6 run -e SCENARIO=baseline -e FILE_SIZE=100k tests/load/upload_test.js
```

### Scenario B: Normal Load (10 Concurrent Users)
Simulates typical everyday usage with steady uploads.
```bash
k6 run -e SCENARIO=normal -e FILE_SIZE=100k tests/load/upload_test.js
```

### Scenario C: Moderate Load (25 Concurrent Users)
Ramps to 25 concurrent users over 20 seconds.
```bash
k6 run -e SCENARIO=moderate -e FILE_SIZE=500k tests/load/upload_test.js
```

### Scenario D: Heavy Load (50 Concurrent Users)
Ramps to 50 concurrent uploading users. Tests Node.js memory buffer usage.
```bash
k6 run -e SCENARIO=heavy -e FILE_SIZE=1m tests/load/upload_test.js
```

### Scenario E: Stress Test (100 Concurrent Users)
Pushes the system to maximum capacity (100 concurrent uploads).
```bash
k6 run -e SCENARIO=stress -e FILE_SIZE=1m tests/load/upload_test.js
```

### Scenario F: Spike Test (Rapid 0 → 100 VU Burst)
Simulates a sudden traffic surge (e.g. students uploading assignments right before a deadline):
- 0 → 10 VUs (5s)
- 10 → 25 VUs (5s)
- 25 → 50 VUs (10s)
- 50 → 100 VUs spike (10s)
- Hold 100 VUs (20s)
- Drop to 10 VUs and 0 VUs to observe system recovery.
```bash
k6 run tests/load/spike_test.js
```

### Scenario G: Negative Tests
Validates that invalid inputs and malicious payloads are cleanly rejected without server crash:
```bash
k6 run tests/load/negative_tests.js
```

---

## 5. Configurable Parameters & Options

You can pass environment flags with `-e <KEY>=<VALUE>`:

| Parameter | Options | Default | Description |
|---|---|---|---|
| `BASE_URL` | `http://127.0.0.1:3000`, `https://staging.printit.in` | `http://127.0.0.1:3000` | Target server URL |
| `FILE_SIZE` | `100k`, `500k`, `1m`, `5m`, `10m` | `100k` | Upload file payload size |
| `AUTH_MODE` | `guest` or `auth` | `guest` | Use `/api/upload/guest` or authenticated `/api/upload` |
| `CREATE_ORDER` | `true` or `false` | `false` | Execute full flow: upload document AND insert order into DB |
| `TEST_USER_EMAIL` | any email | Auto-generated | Test customer email for authenticated uploads |
| `TEST_USER_PASSWORD`| any password | `LoadTestPass123!` | Test customer password |

#### Example: Authenticated Full-Workflow Upload (5MB File, 10 VUs)
```bash
k6 run -e AUTH_MODE=auth -e FILE_SIZE=5m -e CREATE_ORDER=true --vus 10 --duration 30s tests/load/upload_test.js
```

---

## 6. How to Monitor the Backend During Stress Tests

Open a second terminal alongside k6 to observe backend metrics:

### 1. Process CPU & RAM Usage (Windows PowerShell)
```powershell
Get-Process node | Select-Object Id, ProcessName, @{Name="RAM (MB)";Expression={[math]::Round($_.WorkingSet64/1MB, 2)}}, @{Name="CPU (s)";Expression={$_.TotalProcessorTime.TotalSeconds}}
```

### 2. Live CPU & RAM Graph (Windows Performance Monitor / CLI)
```powershell
while ($true) {
    Get-Process node -ErrorAction SilentlyContinue | Format-Table Id, @{N='RAM(MB)';E={[math]::round($_.WS/1MB,1)}}, @{N='CPU%';E={$_.CPU}} -AutoSize
    Start-Sleep -Seconds 2
}
```

### 3. Database Pool & Active Connections (PostgreSQL / Supabase)
Run inside Supabase SQL editor or via `testdb.js`:
```sql
SELECT count(*), state FROM pg_stat_activity WHERE datname = 'postgres' GROUP BY state;
```

---

## 7. Metrics Interpretation & Thresholds

| Metric | Healthy Benchmark | Warning Sign | Action Required |
|---|---|---|---|
| **`upload_success_rate`** | `> 99.0%` | `< 98.0%` | Inspect backend error logs for 500/504 errors |
| **`upload_duration_ms (p95)`** | `< 2,000ms` (100KB–1MB) | `> 4,000ms` | Network saturation or Firebase upload latency |
| **`http_req_failed`** | `< 1.0%` | `> 2.0%` | Connection drops, timeouts, or unhandled errors |
| **Node.js RAM (MB)** | `< 400 MB` | `> 1.2 GB` | Memory leak or buffering too many files in RAM |

---

## 8. Identified Bottlenecks & Recommendations

From our deep source inspection of `backend/src/routes/uploadRoutes.js`:

### 🚨 1. Memory Exhaustion via `multer.memoryStorage()`
* **Issue:** Files are fully loaded into Node.js buffer memory (`req.file.buffer`) before being streamed to Firebase Storage.
* **Impact:** 100 concurrent users uploading 10MB files require **1 GB+ of RAM** in an active single-threaded V8 process, which can cause garbage collection pauses or `JavaScript heap out of memory` crashes.
* **Recommendation:**
  - For files > 2MB, use **Cloud Storage Presigned URLs** (`@google-cloud/storage` `getSignedUrl('write')`). The browser uploads directly to Firebase/GCS, completely bypassing the Node.js backend server!

### 🚨 2. Supabase Pooler Client Limits
* **Issue:** In `backend/.env`, the database connects to port `5432` in Session Mode, which enforces `max clients are limited to pool_size: 15`.
* **Impact:** At 50–100 concurrent order creations, queries risk encountering `(EMAXCONNSESSION) max clients reached`.
* **Recommendation:**
  - Switch `DATABASE_URL` to Supabase's transaction pooler port **`6543`** with `?pgbouncer=true`.
  - In `backend/src/config/db.js`, keep `max: 12` to guarantee pool limits are never exceeded.
