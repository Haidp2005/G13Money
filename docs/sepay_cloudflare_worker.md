# SePay without Firebase Blaze (Cloudflare Worker)

This setup receives SePay webhook and writes directly to Firestore using service-account OAuth.

## What you get

- No Firebase Blaze upgrade required for webhook runtime.
- SePay webhook -> Cloudflare Worker -> Firestore:
  - `users/{uid}/GiaoDich/{txId}`
  - `users/{uid}/transactions/{txId}`
  - `users/{uid}/notifications/{notiId}`
  - `sepay_events/{eventId}`

## Files added

- `cloudflare/sepay-webhook/src/index.js`
- `cloudflare/sepay-webhook/wrangler.toml.example`

## 1) Prepare Cloudflare Worker

Install Wrangler globally if needed:

```powershell
npm install -g wrangler
```

Login:

```powershell
wrangler login
```

In `cloudflare/sepay-webhook`, copy `wrangler.toml.example` to `wrangler.toml` and update values.

## 2) Add secrets to Worker

Run these commands in `cloudflare/sepay-webhook`:

```powershell
wrangler secret put FIREBASE_CLIENT_EMAIL
wrangler secret put FIREBASE_PRIVATE_KEY
```

Values come from your Firebase service account JSON:

- `client_email` -> `FIREBASE_CLIENT_EMAIL`
- `private_key` -> `FIREBASE_PRIVATE_KEY`

Note for private key:
- Paste full key with BEGIN/END lines.

## 3) Deploy Worker

```powershell
wrangler deploy
```

You will get URL like:

```txt
https://g13money-sepay-webhook.<subdomain>.workers.dev
```

## 4) Configure SePay webhook

Set SePay webhook URL:

```txt
https://g13money-sepay-webhook.<subdomain>.workers.dev?token=<SEPAY_WEBHOOK_TOKEN>
```

Use the same token as `SEPAY_WEBHOOK_TOKEN` in `wrangler.toml`.

## 5) Create Firestore binding

Create one document in `sepay_bindings` for each receiving account.

Example:

```json
{
  "uid": "cUBQnmPCwGdDQSmOs60Q9RnF4We2",
  "accountNumber": "123456789",
  "bankCode": "VCB",
  "walletId": "acc_vcb",
  "walletName": "Vietcombank",
  "categoryId": "cat_salary",
  "categoryName": "Luong",
  "active": true
}
```

## 6) Quick test

```powershell
$body = @{
  transaction_id = "TEST_001"
  amount = 150000
  account_number = "123456789"
  bank_code = "VCB"
  content = "Chuyen tien test"
  transaction_time = "2026-04-04T10:30:00Z"
} | ConvertTo-Json

Invoke-RestMethod -Method Post `
  -Uri "https://g13money-sepay-webhook.<subdomain>.workers.dev?token=<SEPAY_WEBHOOK_TOKEN>" `
  -ContentType "application/json" `
  -Body $body
```

Expected:

```json
{ "ok": true, "uid": "...", "transactionId": "sepay_TEST_001" }
```

## Security notes

- Keep service-account secrets only in Worker secrets.
- Keep webhook token long and random.
- Do not expose `sepay_events` to clients.
- Rotate secrets if leaked.
