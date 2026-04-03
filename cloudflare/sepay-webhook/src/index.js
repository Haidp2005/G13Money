function pick(obj, keys, fallback = "") {
  for (const key of keys) {
    const value = obj?.[key];
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return fallback;
}

function dig(obj, path) {
  const parts = path.split(".");
  let cur = obj;
  for (const part of parts) {
    if (cur == null || typeof cur !== "object") return undefined;
    cur = cur[part];
  }
  return cur;
}

function pickDeep(obj, paths, fallback = "") {
  for (const path of paths) {
    const value = dig(obj, path);
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return fallback;
}

function parseAmount(value) {
  if (value === null || value === undefined) return NaN;
  if (typeof value === "number") return value;
  const normalized = String(value)
    .trim()
    .replace(/\s+/g, "")
    .replace(/[^0-9,.-]/g, "")
    .replace(/,/g, "");
  if (!normalized) return NaN;
  return Number(normalized);
}

function toDate(value) {
  if (!value) return new Date();
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) return new Date();
  return date;
}

function normalizeDocId(input) {
  return String(input).replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 120);
}

function normalizeAccountNumber(value) {
  return String(value ?? "").replace(/[^0-9]/g, "");
}

function base64Url(bytes) {
  let binary = "";
  for (let i = 0; i < bytes.length; i++) {
    binary += String.fromCharCode(bytes[i]);
  }
  return btoa(binary).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}

async function signJwt(payload, privateKeyPem) {
  const header = { alg: "RS256", typ: "JWT" };
  const encoder = new TextEncoder();

  const headerPart = base64Url(encoder.encode(JSON.stringify(header)));
  const payloadPart = base64Url(encoder.encode(JSON.stringify(payload)));
  const signingInput = `${headerPart}.${payloadPart}`;

  const pemBody = privateKeyPem
    .replace("-----BEGIN PRIVATE KEY-----", "")
    .replace("-----END PRIVATE KEY-----", "")
    .replace(/\s+/g, "");

  const der = Uint8Array.from(atob(pemBody), (char) => char.charCodeAt(0));

  const cryptoKey = await crypto.subtle.importKey(
    "pkcs8",
    der.buffer,
    { name: "RSASSA-PKCS1-v1_5", hash: "SHA-256" },
    false,
    ["sign"],
  );

  const signature = await crypto.subtle.sign(
    { name: "RSASSA-PKCS1-v1_5" },
    cryptoKey,
    encoder.encode(signingInput),
  );

  const signaturePart = base64Url(new Uint8Array(signature));
  return `${signingInput}.${signaturePart}`;
}

async function getAccessToken(env) {
  const now = Math.floor(Date.now() / 1000);
  const payload = {
    iss: env.FIREBASE_CLIENT_EMAIL,
    scope: "https://www.googleapis.com/auth/datastore",
    aud: "https://oauth2.googleapis.com/token",
    exp: now + 3600,
    iat: now,
  };

  const assertion = await signJwt(payload, env.FIREBASE_PRIVATE_KEY);

  const body = new URLSearchParams({
    grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
    assertion,
  });

  const response = await fetch("https://oauth2.googleapis.com/token", {
    method: "POST",
    headers: { "content-type": "application/x-www-form-urlencoded" },
    body,
  });

  if (!response.ok) {
    throw new Error(`Token request failed: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  return data.access_token;
}

function firestoreValue(value) {
  if (value === null || value === undefined) return { nullValue: null };
  if (typeof value === "string") return { stringValue: value };
  if (typeof value === "boolean") return { booleanValue: value };
  if (typeof value === "number") {
    if (Number.isInteger(value)) return { integerValue: String(value) };
    return { doubleValue: value };
  }
  if (value instanceof Date) return { timestampValue: value.toISOString() };
  if (Array.isArray(value)) {
    return { arrayValue: { values: value.map((v) => firestoreValue(v)) } };
  }
  if (typeof value === "object") {
    const fields = {};
    for (const [k, v] of Object.entries(value)) fields[k] = firestoreValue(v);
    return { mapValue: { fields } };
  }
  return { stringValue: String(value) };
}

function firestoreFields(obj) {
  const fields = {};
  for (const [k, v] of Object.entries(obj)) {
    fields[k] = firestoreValue(v);
  }
  return { fields };
}

async function patchDoc(env, token, docPath, data) {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents/${docPath}`;
  const response = await fetch(url, {
    method: "PATCH",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(firestoreFields(data)),
  });

  if (!response.ok) {
    throw new Error(`Firestore patch failed (${docPath}): ${response.status} ${await response.text()}`);
  }
}

async function queryBinding(env, token, accountNumber, bankCode = "") {
  const url = `https://firestore.googleapis.com/v1/projects/${env.FIREBASE_PROJECT_ID}/databases/(default)/documents:runQuery`;
  const body = {
    structuredQuery: {
      from: [{ collectionId: "sepay_bindings" }],
      where: {
        fieldFilter: {
          field: { fieldPath: "active" },
          op: "EQUAL",
          value: { booleanValue: true },
        },
      },
      limit: 50,
    },
  };

  const response = await fetch(url, {
    method: "POST",
    headers: {
      authorization: `Bearer ${token}`,
      "content-type": "application/json",
    },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    throw new Error(`Binding query failed: ${response.status} ${await response.text()}`);
  }

  const rows = await response.json();
  const candidates = rows
    .filter((r) => r.document?.fields)
    .map((r) => r.document.fields)
    .map((f) => {
      const s = (key, fallback = "") => f[key]?.stringValue ?? fallback;
      const b = (key, fallback = false) => f[key]?.booleanValue ?? fallback;
      return {
        uid: s("uid"),
        accountNumber: s("accountNumber"),
        bankCode: s("bankCode"),
        walletId: s("walletId", "acc_vcb"),
        walletName: s("walletName", "Ngan hang"),
        categoryId: s("categoryId", ""),
        categoryName: s("categoryName", ""),
        active: b("active", true),
      };
    });

  if (candidates.length === 0) return null;

  const requestedRaw = String(accountNumber ?? "").trim();
  const requestedNorm = normalizeAccountNumber(requestedRaw);
  const requestedBankCode = String(bankCode ?? "").trim().toUpperCase();

  const exact = candidates.find((c) => c.accountNumber.trim() === requestedRaw);
  if (exact) return exact;

  if (requestedNorm) {
    const normalized = candidates.find(
      (c) => normalizeAccountNumber(c.accountNumber) === requestedNorm,
    );
    if (normalized) return normalized;
  }

  if (requestedBankCode) {
    const byBank = candidates.filter(
      (c) => String(c.bankCode ?? "").trim().toUpperCase() === requestedBankCode,
    );
    if (byBank.length === 1) {
      return byBank[0];
    }
  }

  // Fallback for single-user setups: if there is exactly one active binding,
  // treat it as default mapping even if account format differs.
  if (candidates.length === 1) {
    return candidates[0];
  }

  return null;
}

export default {
  async fetch(request, env) {
    if (request.method !== "POST") {
      return new Response(JSON.stringify({ ok: false, message: "Method Not Allowed" }), {
        status: 405,
        headers: { "content-type": "application/json" },
      });
    }

    try {
      if (!env.FIREBASE_PROJECT_ID || !env.FIREBASE_CLIENT_EMAIL || !env.FIREBASE_PRIVATE_KEY) {
        return new Response(
          JSON.stringify({
            ok: false,
            message: "Worker is missing Firebase configuration secrets",
          }),
          { status: 500, headers: { "content-type": "application/json" } },
        );
      }

      const tokenFromQuery = new URL(request.url).searchParams.get("token") || "";
      const tokenFromHeader = request.headers.get("x-sepay-token") || "";
      const bearer = request.headers.get("authorization") || "";
      const tokenFromBearer = bearer.toLowerCase().startsWith("bearer ")
        ? bearer.slice(7).trim()
        : "";
      const expectedToken = (env.SEPAY_WEBHOOK_TOKEN || "").trim();
      const isPlaceholderToken = expectedToken === "g13money-sepay-token-change-me";
      const shouldEnforceToken = expectedToken.length > 0 && !isPlaceholderToken;

      if (
        shouldEnforceToken
        && tokenFromQuery !== expectedToken
        && tokenFromHeader !== expectedToken
        && tokenFromBearer !== expectedToken
      ) {
        return new Response(JSON.stringify({ ok: false, message: "Invalid webhook token" }), {
          status: 401,
          headers: { "content-type": "application/json" },
        });
      }

      const payload = await request.json();

      const rawTxId = pickDeep(payload, [
        "transaction_id",
        "transactionId",
        "id",
        "trans_id",
        "reference",
        "txnId",
        "data.transaction_id",
        "data.transactionId",
        "data.id",
        "data.reference",
      ], Date.now().toString());

      const amount = parseAmount(
        pickDeep(payload, [
          "amount",
          "credit_amount",
          "in_amount",
          "money",
          "transferAmount",
          "transfer_amount",
          "amount_in",
          "data.amount",
          "data.credit_amount",
          "data.in_amount",
          "data.money",
          "data.transferAmount",
          "data.transfer_amount",
          "data.amount_in",
        ], "0"),
      );

      if (!Number.isFinite(amount) || amount <= 0) {
        return new Response(JSON.stringify({ ok: false, message: "Invalid amount" }), {
          status: 400,
          headers: { "content-type": "application/json" },
        });
      }

      const accountNumber = String(
        pickDeep(payload, [
          "account_number",
          "virtual_account",
          "accountNo",
          "account_number_to",
          "bank_account",
          "accountNumber",
          "toAccountNumber",
          "data.account_number",
          "data.virtual_account",
          "data.accountNo",
          "data.account_number_to",
          "data.bank_account",
          "data.accountNumber",
          "data.toAccountNumber",
        ], ""),
      ).trim();

      if (!accountNumber) {
        return new Response(JSON.stringify({ ok: false, message: "Missing account number" }), {
          status: 400,
          headers: { "content-type": "application/json" },
        });
      }

      const transferContent = String(
        pickDeep(payload, [
          "content",
          "description",
          "transfer_content",
          "message",
          "remark",
          "data.content",
          "data.description",
          "data.transfer_content",
          "data.message",
          "data.remark",
        ], "Nap tien qua SePay"),
      ).trim();

      const transferTypeRaw = String(
        pickDeep(payload, [
          "transferType",
          "transfer_type",
          "direction",
          "data.transferType",
          "data.transfer_type",
          "data.direction",
        ], ""),
      ).trim().toLowerCase();
      const isOutgoing = transferTypeRaw === "out" || transferTypeRaw === "debit";
      const isIncome = !isOutgoing;

      const bankCode = String(
        pickDeep(payload, [
          "bank_code",
          "bankCode",
          "bank",
          "bank_name",
          "bankName",
          "data.bank_code",
          "data.bankCode",
          "data.bank",
          "data.bank_name",
          "data.bankName",
        ], ""),
      ).trim();

      const paidAt = toDate(
        pickDeep(payload, [
          "transaction_time",
          "created_at",
          "paid_at",
          "timestamp",
          "time",
          "data.transaction_time",
          "data.created_at",
          "data.paid_at",
          "data.timestamp",
          "data.time",
        ], ""),
      );

      const accessToken = await getAccessToken(env);
      const binding = await queryBinding(env, accessToken, accountNumber, bankCode);

      const resolvedUid = String(binding?.uid ?? "").trim();
      if (!binding || !resolvedUid) {
        const diagId = normalizeDocId(`unmatched_${Date.now()}_${rawTxId}`);
        await patchDoc(env, accessToken, `sepay_events/${diagId}`, {
          status: "unmatched_binding",
          accountNumberRaw: accountNumber,
          accountNumberNormalized: normalizeAccountNumber(accountNumber),
          rawTxId: String(rawTxId),
          payload,
          processedAt: new Date(),
        });

        return new Response(JSON.stringify({
          ok: true,
          message: "No binding found",
          extracted: {
            accountNumber,
            normalizedAccountNumber: normalizeAccountNumber(accountNumber),
            transactionId: String(rawTxId),
          },
        }), {
          status: 202,
          headers: { "content-type": "application/json" },
        });
      }

      const year = paidAt.getFullYear();
      const month = paidAt.getMonth() + 1;
      const day = paidAt.getDate();
      const yearMonth = `${year}-${String(month).padStart(2, "0")}`;

      const txId = normalizeDocId(`sepay_${rawTxId}`);
      const txPayload = {
        title: transferContent || (isIncome ? "Thu tien tu SePay" : "Chi tien tu SePay"),
        note: "Dong bo tu SePay webhook",
        amount,
        type: isIncome ? "income" : "expense",
        isIncome,
        categoryId: "",
        categoryName: "",
        walletId: binding.walletId,
        walletName: binding.walletName,
        date: paidAt,
        attachmentUrls: [],
        tags: ["sepay", "bank"],
        year,
        month,
        day,
        yearMonth,
        reviewNeeded: true,
        source: {
          provider: "sepay",
          transactionId: String(rawTxId),
          accountNumber,
          bankCode,
          transferType: transferTypeRaw,
        },
        updatedAt: new Date(),
        createdAt: new Date(),
      };

      const notiId = `${txId}_notification`;
      const notiPayload = {
        type: "system",
        title: "Can xac nhan giao dich ngan hang",
        body: `Da nhan ${amount} VND. Vui long mo thong bao de bo sung danh muc.`,
        isRead: false,
        meta: {
          provider: "sepay",
          transactionId: String(rawTxId),
          transactionDocId: txId,
        },
        reviewStatus: "pending",
        createdAt: new Date(),
      };

      txPayload.notificationId = notiId;

      const writeTargets = {
        primaryTransaction: `users/${resolvedUid}/GiaoDich/${txId}`,
        legacyTransaction: `users/${resolvedUid}/transactions/${txId}`,
        notification: `users/${resolvedUid}/notifications/${notiId}`,
      };

      await patchDoc(env, accessToken, writeTargets.primaryTransaction, txPayload);
      await patchDoc(env, accessToken, writeTargets.legacyTransaction, txPayload);
      await patchDoc(env, accessToken, writeTargets.notification, notiPayload);
      await patchDoc(env, accessToken, `sepay_events/${txId}`, {
        uid: resolvedUid,
        accountNumber,
        transactionId: txId,
        writeTargets,
        rawPayload: payload,
        processedAt: new Date(),
      });

      return new Response(
        JSON.stringify({
          ok: true,
          uid: resolvedUid,
          transactionId: txId,
          writeTargets,
        }),
        { status: 200, headers: { "content-type": "application/json" } },
      );
    } catch (error) {
      return new Response(
        JSON.stringify({ ok: false, message: "Internal error", error: String(error) }),
        { status: 500, headers: { "content-type": "application/json" } },
      );
    }
  },
};
