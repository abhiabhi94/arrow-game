#!/usr/bin/env node
// Publishes to Google Play through the Play Developer API — no third-party
// action and no npm dependencies: Node's own fetch and crypto do the OAuth
// (a service-account JWT) and the REST calls. Used by the Release workflow
// (upload to alpha) and the Promote workflow (alpha -> production).
//
// Usage:
//   node tool/play_publish.mjs upload --aab app.aab [--mapping mapping.txt] [--name "1.7.2 (11)"]
//   node tool/play_publish.mjs promote [--version-code 11]
//
//   upload   uploads the bundle (and the R8 mapping, so crash reports are
//            readable) and makes it the alpha track's release, at 100%
//   promote  makes the release on alpha the production release, at 100% —
//            the same version code, so production gets exactly the build the
//            testers had (a bundle cannot be uploaded twice anyway). With
//            --version-code, that build instead of alpha's newest one.
//
// Environment:
//   PLAY_SERVICE_ACCOUNT_JSON  the service account's JSON key (required)
//   PLAY_PACKAGE_NAME          default app.curious.arrow
//   PLAY_API_ROOT, PLAY_TOKEN_URL  overrides, for testing against a mock
//
// Only two tracks are used: alpha (closed testing) and production. See
// docs/release.md for the one-time Play Console / Google Cloud setup.

import { createSign } from 'node:crypto';
import { readFileSync } from 'node:fs';

const PACKAGE = process.env.PLAY_PACKAGE_NAME || 'app.curious.arrow';
const API = process.env.PLAY_API_ROOT || 'https://androidpublisher.googleapis.com';
const SCOPE = 'https://www.googleapis.com/auth/androidpublisher';
const TESTING = 'alpha';
const PRODUCTION = 'production';

function fail(message) {
  console.error(`::error::${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const [command, ...rest] = argv;
  const opts = {};
  for (let i = 0; i < rest.length; i++) {
    const key = rest[i];
    if (!key.startsWith('--') || i + 1 >= rest.length) fail(`Bad argument: ${key}`);
    opts[key.slice(2)] = rest[++i];
  }
  return { command, opts };
}

function serviceAccount() {
  const raw = process.env.PLAY_SERVICE_ACCOUNT_JSON;
  if (!raw) fail('PLAY_SERVICE_ACCOUNT_JSON is not set. See docs/release.md.');
  let key;
  try {
    key = JSON.parse(raw);
  } catch {
    fail('PLAY_SERVICE_ACCOUNT_JSON is not valid JSON — paste the whole key file.');
  }
  if (!key.client_email || !key.private_key) {
    fail('PLAY_SERVICE_ACCOUNT_JSON has no client_email/private_key — is it a service-account key?');
  }
  return key;
}

const b64url = (data) => Buffer.from(data).toString('base64url');

/** An OAuth access token for [key], by the JWT-bearer grant. */
async function accessToken(key) {
  const tokenUrl = process.env.PLAY_TOKEN_URL || key.token_uri || 'https://oauth2.googleapis.com/token';
  const now = Math.floor(Date.now() / 1000);
  const header = b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }));
  const claims = b64url(
    JSON.stringify({ iss: key.client_email, scope: SCOPE, aud: tokenUrl, iat: now, exp: now + 3600 }),
  );
  const signature = createSign('RSA-SHA256').update(`${header}.${claims}`).sign(key.private_key);
  const res = await fetch(tokenUrl, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion: `${header}.${claims}.${b64url(signature)}`,
    }),
  });
  if (!res.ok) fail(`Could not sign in as ${key.client_email}: ${res.status} ${await res.text()}`);
  return (await res.json()).access_token;
}

/** A thin client for one edit on the app. */
function client(token) {
  const base = `${API}/androidpublisher/v3/applications/${PACKAGE}`;
  const upload = `${API}/upload/androidpublisher/v3/applications/${PACKAGE}`;
  async function call(method, url, { json, file } = {}) {
    const headers = { Authorization: `Bearer ${token}` };
    let body;
    if (json !== undefined) {
      headers['Content-Type'] = 'application/json';
      body = JSON.stringify(json);
    } else if (file !== undefined) {
      headers['Content-Type'] = 'application/octet-stream';
      body = readFileSync(file);
    }
    const res = await fetch(url, { method, headers, body });
    const text = await res.text();
    if (!res.ok) fail(`${method} ${url.replace(API, '')} -> ${res.status}: ${text}`);
    return text ? JSON.parse(text) : {};
  }
  return {
    async openEdit() {
      return (await call('POST', `${base}/edits`, { json: {} })).id;
    },
    uploadBundle: (edit, aab) =>
      call('POST', `${upload}/edits/${edit}/bundles?uploadType=media`, { file: aab }),
    uploadMapping: (edit, versionCode, mapping) =>
      call(
        'POST',
        `${upload}/edits/${edit}/deobfuscationFiles/${versionCode}/proguard?uploadType=media`,
        { file: mapping },
      ),
    getTrack: (edit, track) => call('GET', `${base}/edits/${edit}/tracks/${track}`),
    setTrack: (edit, track, release) =>
      call('PUT', `${base}/edits/${edit}/tracks/${track}`, { json: { track, releases: [release] } }),
    commit: (edit) => call('POST', `${base}/edits/${edit}:commit`),
  };
}

async function upload(play, opts) {
  if (!opts.aab) fail('upload needs --aab');
  const edit = await play.openEdit();
  const { versionCode } = await play.uploadBundle(edit, opts.aab);
  console.log(`Uploaded ${opts.aab} as version code ${versionCode}`);
  if (opts.mapping) {
    await play.uploadMapping(edit, versionCode, opts.mapping);
    console.log(`Uploaded R8 mapping for ${versionCode}`);
  }
  const release = { versionCodes: [String(versionCode)], status: 'completed' };
  if (opts.name) release.name = opts.name;
  await play.setTrack(edit, TESTING, release);
  await play.commit(edit);
  console.log(`Version code ${versionCode} is the ${TESTING} release (100%).`);
}

async function promote(play, opts) {
  const edit = await play.openEdit();
  const { releases = [] } = await play.getTrack(edit, TESTING);
  const codeOf = (r) => Math.max(...(r.versionCodes || []).map(Number));
  const candidates = releases.filter((r) => (r.versionCodes || []).length > 0);
  const wanted = opts['version-code'];
  const from = wanted
    ? candidates.find((r) => r.versionCodes.map(String).includes(String(wanted)))
    : candidates.sort((a, b) => codeOf(b) - codeOf(a))[0];
  if (!from) {
    fail(
      wanted
        ? `Version code ${wanted} is not on the ${TESTING} track — upload it there first.`
        : `The ${TESTING} track has no release to promote.`,
    );
  }
  const release = { versionCodes: from.versionCodes, status: 'completed' };
  if (from.name) release.name = from.name;
  if (from.releaseNotes) release.releaseNotes = from.releaseNotes;
  await play.setTrack(edit, PRODUCTION, release);
  await play.commit(edit);
  console.log(`Promoted ${from.name ?? from.versionCodes.join(',')} from ${TESTING} to ${PRODUCTION} (100%).`);
}

const { command, opts } = parseArgs(process.argv.slice(2));
if (command !== 'upload' && command !== 'promote') {
  fail('Usage: play_publish.mjs upload --aab F [--mapping F] [--name N] | promote [--version-code N]');
}
const play = client(await accessToken(serviceAccount()));
await (command === 'upload' ? upload(play, opts) : promote(play, opts));
