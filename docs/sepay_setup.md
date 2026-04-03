# SePay webhook setup for G13 Money

This guide configures SePay to send bank notifications into Firestore.

## 1) What was added

- Firebase Function endpoint: `functions/index.js` -> `sepayWebhook`
- Firestore mapping collection: `sepay_bindings`
- Firestore webhook logs collection: `sepay_events`
- App transaction sync targets:
  - `users/{uid}/GiaoDich/{txId}`
  - `users/{uid}/transactions/{txId}` (backward compatibility)
- App notification target:
  - `users/{uid}/notifications/{notificationId}`

## 2) Install and deploy Functions

From project root:

```powershell
cd functions
npm install
cd ..
firebase deploy --project g13pals --only functions
```

Optional: deploy rules too

```powershell
firebase deploy --project g13pals --only firestore:rules
```

## 3) Configure webhook token (security)

Use one of these options.

Option A (recommended): pass token in webhook URL query

- Choose a secret token, example: `my-very-strong-token`
- Webhook URL format:

```txt
https://<region>-<project-id>.cloudfunctions.net/sepayWebhook?token=my-very-strong-token
```

Option B: header `x-sepay-token` with the same token value.

The function checks:
- `token` query param
- `x-sepay-token` header

If token does not match, webhook returns `401`.

## 4) Create binding document (map bank account -> user)

Create a document in top-level collection `sepay_bindings`.

Example document data:

```json
{
  "uid": "cUBQnmPCwGdDQSmOs60Q9RnF4We2",
  "accountNumber": "123456789",
  "bankCode": "VCB",
  "walletId": "acc_vcb",
  "walletName": "Vietcombank",
  "categoryId": "cat_salary",
  "categoryName": "Luong",
  "active": true,
  "updatedAt": "serverTimestamp"
}
```

Notes:
- `uid` must match Firebase Auth user id.
- `accountNumber` must match the account number/virtual account from SePay payload.
- You can use one document per account.

## 5) Configure SePay dashboard

In SePay webhook settings:
- Method: `POST`
- URL: your deployed function URL
- Payload: JSON
- Add token either via query string or `x-sepay-token` header

## 6) Data flow

When webhook is received and binding is found:

1. Create/update transaction in:
   - `users/{uid}/GiaoDich/sepay_<transaction_id>`
   - `users/{uid}/transactions/sepay_<transaction_id>`
2. Create/update notification in:
   - `users/{uid}/notifications/sepay_<transaction_id>_notification`
3. Save raw event log in:
   - `sepay_events/sepay_<transaction_id>`

If no binding is found, function returns HTTP `202` and does not write user data.

## 7) Test quickly with curl/PowerShell

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
  -Uri "https://<region>-<project-id>.cloudfunctions.net/sepayWebhook?token=my-very-strong-token" `
  -ContentType "application/json" `
  -Body $body
```

Expected response:

```json
{ "ok": true, "uid": "...", "transactionId": "sepay_TEST_001" }
```
