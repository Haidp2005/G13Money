#!/usr/bin/env node

const fs = require('fs');
const path = require('path');
const crypto = require('crypto');

function parseArgs() {
  const args = process.argv.slice(2);
  const result = {};
  for (let i = 0; i < args.length; i += 1) {
    const arg = args[i];
    if (!arg.startsWith('--')) continue;
    const key = arg.slice(2);
    const value = args[i + 1];
    result[key] = value;
    i += 1;
  }
  return result;
}

function base64Url(input) {
  return Buffer.from(input)
    .toString('base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');
}

function createJwt(clientEmail, privateKey) {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const payload = {
    iss: clientEmail,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const encodedHeader = base64Url(JSON.stringify(header));
  const encodedPayload = base64Url(JSON.stringify(payload));
  const signingInput = `${encodedHeader}.${encodedPayload}`;

  const signer = crypto.createSign('RSA-SHA256');
  signer.update(signingInput);
  signer.end();

  const signature = signer
    .sign(privateKey, 'base64')
    .replace(/=/g, '')
    .replace(/\+/g, '-')
    .replace(/\//g, '_');

  return `${signingInput}.${signature}`;
}

async function getAccessToken(jwt) {
  const body = new URLSearchParams({
    grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
    assertion: jwt,
  });

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body,
  });

  if (!response.ok) {
    throw new Error(`Failed to get access token: ${response.status} ${await response.text()}`);
  }

  const data = await response.json();
  return data.access_token;
}

async function sendPush({ projectId, accessToken, deviceToken, title, body }) {
  const endpoint = `https://fcm.googleapis.com/v1/projects/${projectId}/messages:send`;
  const payload = {
    message: {
      token: deviceToken,
      notification: {
        title,
        body,
      },
      android: {
        priority: 'HIGH',
        notification: {
          channel_id: 'g13money_default_channel',
        },
      },
      data: {
        source: 'manual-test',
        sentAt: new Date().toISOString(),
      },
    },
  };

  const response = await fetch(endpoint, {
    method: 'POST',
    headers: {
      authorization: `Bearer ${accessToken}`,
      'content-type': 'application/json',
    },
    body: JSON.stringify(payload),
  });

  const text = await response.text();
  if (!response.ok) {
    throw new Error(`Failed to send push: ${response.status} ${text}`);
  }

  return text;
}

(async function main() {
  try {
    const args = parseArgs();
    const projectId = args.projectId;
    const serviceAccountPath = args.serviceAccount;
    const deviceToken = args.deviceToken;
    const title = args.title || 'G13 Money';
    const body = args.body || 'Thong bao thu nghiem tu FCM';

    if (!projectId || !serviceAccountPath || !deviceToken) {
      throw new Error(
        'Usage: node tool/send_fcm_notification.js --projectId <id> --serviceAccount <path-to-json> --deviceToken <token> [--title <title>] [--body <body>]'
      );
    }

    const absolutePath = path.resolve(serviceAccountPath);
    const raw = fs.readFileSync(absolutePath, 'utf8');
    const serviceAccount = JSON.parse(raw);

    const jwt = createJwt(serviceAccount.client_email, serviceAccount.private_key);
    const accessToken = await getAccessToken(jwt);

    const response = await sendPush({
      projectId,
      accessToken,
      deviceToken,
      title,
      body,
    });

    console.log('Push sent successfully');
    console.log(response);
  } catch (error) {
    console.error(error.message || String(error));
    process.exit(1);
  }
})();
