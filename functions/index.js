const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");
const admin = require("firebase-admin");

admin.initializeApp();

function pick(obj, keys, fallback = "") {
  for (const key of keys) {
    const value = obj?.[key];
    if (value !== undefined && value !== null && String(value).trim() !== "") {
      return value;
    }
  }
  return fallback;
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

exports.sepayWebhook = onRequest({ cors: true }, async (req, res) => {
  if (req.method !== "POST") {
    return res.status(405).json({ ok: false, message: "Method Not Allowed" });
  }

  try {
    const webhookToken = process.env.SEPAY_WEBHOOK_TOKEN || "";
    const tokenFromQuery = String(req.query.token || "");
    const tokenFromHeader = String(req.headers["x-sepay-token"] || "");

    if (webhookToken && tokenFromQuery !== webhookToken && tokenFromHeader !== webhookToken) {
      return res.status(401).json({ ok: false, message: "Invalid webhook token" });
    }

    const payload = typeof req.body === "object" && req.body ? req.body : {};

    const rawTxId = pick(payload, [
      "transaction_id",
      "transactionId",
      "id",
      "trans_id",
      "reference",
    ], Date.now().toString());

    const amount = Number(
      pick(payload, ["amount", "credit_amount", "in_amount", "money"], "0"),
    );

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ ok: false, message: "Invalid amount" });
    }

    const accountNumber = String(
      pick(payload, ["account_number", "virtual_account", "accountNo", "bank_account"], ""),
    ).trim();

    if (!accountNumber) {
      return res.status(400).json({ ok: false, message: "Missing account number" });
    }

    const transferContent = String(
      pick(payload, ["content", "description", "transfer_content", "message"], "Nap tien qua SePay"),
    ).trim();

    const bankCode = String(
      pick(payload, ["bank_code", "bankCode", "bank", "bank_name"], ""),
    ).trim();

    const paidAt = toDate(
      pick(payload, ["transaction_time", "created_at", "paid_at", "timestamp"], ""),
    );

    const bindingQuery = await admin
      .firestore()
      .collection("sepay_bindings")
      .where("accountNumber", "==", accountNumber)
      .where("active", "!=", false)
      .limit(1)
      .get();

    if (bindingQuery.empty) {
      logger.warn("SePay webhook received but no binding matched", { accountNumber, rawTxId });
      return res.status(202).json({ ok: true, message: "No mapping binding found" });
    }

    const bindingData = bindingQuery.docs[0].data();
    const uid = String(bindingData.uid || "").trim();

    if (!uid) {
      return res.status(500).json({ ok: false, message: "Binding is missing uid" });
    }

    const walletId = String(bindingData.walletId || "acc_vcb").trim();
    const walletName = String(bindingData.walletName || "Ngan hang").trim();
    const categoryId = String(bindingData.categoryId || "cat_salary").trim();
    const categoryName = String(bindingData.categoryName || "Thu nhap ngan hang").trim();

    const year = paidAt.getFullYear();
    const month = paidAt.getMonth() + 1;
    const day = paidAt.getDate();
    const yearMonth = `${year}-${String(month).padStart(2, "0")}`;

    const txId = normalizeDocId(`sepay_${rawTxId}`);
    const txPayload = {
      title: transferContent || "Thu tien tu SePay",
      note: "Dong bo tu SePay webhook",
      amount,
      type: "income",
      isIncome: true,
      categoryId,
      categoryName,
      walletId,
      walletName,
      date: admin.firestore.Timestamp.fromDate(paidAt),
      attachmentUrls: [],
      tags: ["sepay", "bank"],
      year,
      month,
      day,
      yearMonth,
      source: {
        provider: "sepay",
        transactionId: String(rawTxId),
        accountNumber,
        bankCode,
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const notificationId = `${txId}_notification`;
    const notificationPayload = {
      type: "system",
      title: "Nhan thong bao ngan hang",
      body: `Da nhan ${amount} VND tu SePay vao vi ${walletName}`,
      isRead: false,
      meta: {
        provider: "sepay",
        transactionId: String(rawTxId),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const db = admin.firestore();
    const batch = db.batch();

    batch.set(db.doc(`users/${uid}/GiaoDich/${txId}`), txPayload, { merge: true });
    batch.set(db.doc(`users/${uid}/transactions/${txId}`), txPayload, { merge: true });
    batch.set(db.doc(`users/${uid}/notifications/${notificationId}`), notificationPayload, { merge: true });
    batch.set(
      db.doc(`sepay_events/${txId}`),
      {
        uid,
        accountNumber,
        rawPayload: payload,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    await batch.commit();

    return res.status(200).json({ ok: true, uid, transactionId: txId });
  } catch (error) {
    logger.error("sepayWebhook error", error);
    return res.status(500).json({ ok: false, message: "Internal error", error: String(error) });
  }
});
