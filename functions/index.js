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

function normalizeDocId(input) {
  return String(input).replace(/[^a-zA-Z0-9_-]/g, "_").slice(0, 120);
}

function signedAmount(isIncome, amount) {
  return isIncome ? Math.abs(amount) : -Math.abs(amount);
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

    const transferTypeRaw = String(
      pick(payload, ["transferType", "transfer_type", "direction"], ""),
    ).trim().toLowerCase();

    const incomingAmount = parseAmount(
      pick(payload, ["credit_amount", "in_amount", "amount_in"], ""),
    );
    const outgoingAmount = parseAmount(
      pick(payload, ["debit_amount", "out_amount", "amount_out"], ""),
    );
    const genericAmount = parseAmount(
      pick(payload, ["amount", "money", "transferAmount", "transfer_amount"], "0"),
    );

    let isOutgoing = transferTypeRaw === "out" || transferTypeRaw === "debit";
    if (!isOutgoing && Number.isFinite(outgoingAmount) && outgoingAmount > 0) {
      isOutgoing = true;
    }

    const amount = Number.isFinite(genericAmount) && genericAmount > 0
      ? genericAmount
      : (isOutgoing ? outgoingAmount : incomingAmount);

    if (!Number.isFinite(amount) || amount <= 0) {
      return res.status(400).json({ ok: false, message: "Invalid amount" });
    }

    const isIncome = !isOutgoing;

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
      title: transferContent || (isIncome ? "Thu tien tu SePay" : "Chi tien tu SePay"),
      note: "Dong bo tu SePay webhook",
      amount,
      type: isIncome ? "income" : "expense",
      isIncome,
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
        transferType: transferTypeRaw,
        ingestMode: "manual_like",
      },
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const notificationId = `${txId}_notification`;
    const notificationPayload = {
      type: "system",
      title: "Nhan thong bao ngan hang",
      body: `Co Giao dich moi: ${isIncome ? "+" : "-"}${amount} VND`,
      isRead: false,
      meta: {
        provider: "sepay",
        transactionId: String(rawTxId),
      },
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    };

    const db = admin.firestore();
    const preferencesDoc = await db.doc(`users/${uid}/settings/preferences`).get();
    const shouldNotifyNewTransaction =
      (preferencesDoc.data()?.transactionAlerts ?? true) !== false;

    const primaryTxDoc = db.doc(`users/${uid}/GiaoDich/${txId}`);
    const accountsCollection = db.collection(`users/${uid}/accounts`);
    const targetWalletDoc = accountsCollection.doc(walletId);

    const existingTxSnapshot = await primaryTxDoc.get();
    const existingTx = existingTxSnapshot.exists ? existingTxSnapshot.data() : null;

    const oldWalletId = String(existingTx?.walletId || "").trim();
    const oldAmount = Number(existingTx?.amount || 0);
    const oldIsIncome = Boolean(existingTx?.isIncome);

    const oldEffect = existingTx ? signedAmount(oldIsIncome, oldAmount) : 0;
    const newEffect = signedAmount(isIncome, amount);

    const walletIdsToRead = new Set([walletId]);
    if (oldWalletId) {
      walletIdsToRead.add(oldWalletId);
    }

    const walletSnapshots = await Promise.all(
      Array.from(walletIdsToRead).map((id) => accountsCollection.doc(id).get()),
    );

    const walletById = {};
    for (const snap of walletSnapshots) {
      walletById[snap.id] = snap;
    }

    const batch = db.batch();

    batch.set(primaryTxDoc, txPayload, { merge: true });
    batch.set(db.doc(`users/${uid}/transactions/${txId}`), txPayload, { merge: true });
    if (shouldNotifyNewTransaction) {
      batch.set(db.doc(`users/${uid}/notifications/${notificationId}`), notificationPayload, { merge: true });
    }

    if (!oldWalletId || oldWalletId === walletId) {
      const walletSnap = walletById[walletId];
      const currentBalance = Number(walletSnap?.data()?.balance || 0);
      const nextBalance = currentBalance - oldEffect + newEffect;
      batch.set(
        targetWalletDoc,
        {
          name: walletName,
          type: String(walletSnap?.data()?.type || "bank"),
          colorHex: String(walletSnap?.data()?.colorHex || "#0D7377"),
          isArchived: Boolean(walletSnap?.data()?.isArchived || false),
          balance: nextBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: walletSnap?.exists
            ? walletSnap.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp()
            : admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } else {
      const oldWalletSnap = walletById[oldWalletId];
      const newWalletSnap = walletById[walletId];
      const oldWalletCurrentBalance = Number(oldWalletSnap?.data()?.balance || 0);
      const newWalletCurrentBalance = Number(newWalletSnap?.data()?.balance || 0);

      batch.set(
        accountsCollection.doc(oldWalletId),
        {
          balance: oldWalletCurrentBalance - oldEffect,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: oldWalletSnap?.exists
            ? oldWalletSnap.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp()
            : admin.firestore.FieldValue.serverTimestamp(),
          isArchived: Boolean(oldWalletSnap?.data()?.isArchived || false),
        },
        { merge: true },
      );

      batch.set(
        targetWalletDoc,
        {
          name: walletName,
          type: String(newWalletSnap?.data()?.type || "bank"),
          colorHex: String(newWalletSnap?.data()?.colorHex || "#0D7377"),
          isArchived: Boolean(newWalletSnap?.data()?.isArchived || false),
          balance: newWalletCurrentBalance + newEffect,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          createdAt: newWalletSnap?.exists
            ? newWalletSnap.data()?.createdAt || admin.firestore.FieldValue.serverTimestamp()
            : admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }

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
