#!/usr/bin/env node
// Phone-viewport screenshots + smoke test of the Flutter *web* build, driven by
// headless Chromium via Playwright. This is the cloud stand-in for an Android
// emulator: the container has no KVM, so the app is built for web and rendered
// at a phone-sized viewport instead.
//
// Usage:
//   node tool/screenshot.mjs [--levels 1,7,20] [--out shots] [--dark] [--hint] [--grid] [--resume]
//                            [--settings] [--onboarding] [--dump] [--no-strict]
//                            [--build-dir build/web] [--scale 2] [--port 0]
//
//   --levels  opens each level and captures its board (level-NN-*.png)
//   --hint    also taps the hint button and captures the glowing arrow
//   --grid    seeds the grid-lines preference on (the lattice under the arrows)
//   --resume  seeds a saved game on the first level (home shows Continue, the level its Welcome back card)
//             (level-NN-hint-*.png)
//   --onboarding  boots into the first-launch walkthrough instead of home
//
// Prereq: `flutter build web --debug --no-web-resources-cdn`
//   debug   = all levels unlocked (same as the "Arrow Testing" Android build)
//   no-cdn  = CanvasKit served from build/web, not www.gstatic.com
//
// Exit status: 1 (after writing whatever screenshots it could) if the app threw
// a Flutter exception (e.g. a RenderFlex overflow) or a JS error while the
// script drove it, unless --no-strict. That is the CI "smoke test" contract.
//
// How it drives the UI: Flutter web paints to a canvas, so there is no DOM to
// query. The script clicks Flutter's hidden "Enable accessibility" placeholder,
// which materialises the semantics tree as ARIA nodes; from then on any widget
// wrapped in Semantics(label: …, button: true) / any IconButton(tooltip: …) is
// reachable with getByRole. `--dump` prints what is reachable on the screen.
//
// Fonts: the app bundles Nunito (assets/fonts/), but the engine still fetches
// *fallback* fonts (emoji, …) from fonts.gstatic.com at runtime.
// Headless Chromium cannot reach that host through the cloud egress proxy, so
// the local server mirrors it at /__fonts/ (fetched by Node, which can, and
// cached under build/font-cache/) and flutter_bootstrap.js is rewritten to
// point `fontFallbackBaseUrl` there.

process.env.NODE_USE_ENV_PROXY ??= '1'; // let Node's fetch honour HTTPS_PROXY

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const args = parseArgs(process.argv.slice(2));
const buildDir = path.resolve(args['build-dir'] ?? 'build/web');
const fontCache = path.join(path.dirname(buildDir), 'font-cache');
const outDir = path.resolve(args.out ?? 'shots');
const levels = String(args.levels ?? '').split(',').map((s) => s.trim()).filter(Boolean).map(Number);
const dark = Boolean(args.dark);
const hint = Boolean(args.hint);
const grid = Boolean(args.grid);
const resume = Boolean(args.resume);
const scale = Number(args.scale ?? 2);
const port = Number(args.port ?? 0);
const strict = !args['no-strict'];

if (!fs.existsSync(path.join(buildDir, 'index.html'))) {
  console.error(`No web build at ${buildDir}. Run: flutter build web --debug --no-web-resources-cdn`);
  process.exit(2);
}
fs.mkdirSync(outDir, { recursive: true });
fs.mkdirSync(fontCache, { recursive: true });

// --------------------------------------------------------------------------
// Static server for build/web (+ font-fallback mirror, + bootstrap rewrite)
// --------------------------------------------------------------------------

const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript',
  '.css': 'text/css', '.json': 'application/json', '.wasm': 'application/wasm',
  '.png': 'image/png', '.ico': 'image/x-icon', '.svg': 'image/svg+xml',
  '.mp3': 'audio/mpeg', '.ttf': 'font/ttf', '.otf': 'font/otf', '.woff2': 'font/woff2',
};
const FONT_UPSTREAM = 'https://fonts.gstatic.com/s/';
let base = '';

const server = http.createServer(async (req, res) => {
  const urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);

  if (urlPath.startsWith('/__fonts/')) return serveFallbackFont(urlPath.slice('/__fonts/'.length), res);

  const file = path.join(buildDir, urlPath === '/' ? 'index.html' : urlPath);
  if (!file.startsWith(buildDir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404); res.end(); return;
  }
  const headers = { 'Content-Type': MIME[path.extname(file)] ?? 'application/octet-stream', 'Cache-Control': 'no-store' };

  if (path.basename(file) === 'flutter_bootstrap.js') {
    // Inject config.fontFallbackBaseUrl into the generated loader call.
    const src = fs.readFileSync(file, 'utf8');
    const cfg = `config:{fontFallbackBaseUrl:${JSON.stringify(base + '__fonts/')}},`;
    const patched = src.replace(/_flutter\.loader\.load\(\s*\{/, (m) => m + cfg)
                       .replace(/_flutter\.loader\.load\(\s*\)/, `_flutter.loader.load({${cfg}})`);
    res.writeHead(200, headers); res.end(patched); return;
  }
  res.writeHead(200, headers);
  fs.createReadStream(file).pipe(res);
});

async function serveFallbackFont(rel, res) {
  const cached = path.join(fontCache, rel);
  if (!cached.startsWith(fontCache)) { res.writeHead(400); res.end(); return; }
  if (!fs.existsSync(cached)) {
    const r = await fetch(FONT_UPSTREAM + rel).catch(() => null);
    if (!r || !r.ok) { console.error(`[fonts] upstream ${r?.status ?? 'error'} for ${rel}`); res.writeHead(502); res.end(); return; }
    fs.mkdirSync(path.dirname(cached), { recursive: true });
    fs.writeFileSync(cached, Buffer.from(await r.arrayBuffer()));
  }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(cached)] ?? 'font/ttf', 'Access-Control-Allow-Origin': '*' });
  fs.createReadStream(cached).pipe(res);
}

await new Promise((r) => server.listen(port, '127.0.0.1', r));
base = `http://127.0.0.1:${server.address().port}/`;

// --------------------------------------------------------------------------
// Browser
// --------------------------------------------------------------------------

// shared_preferences_web keeps every key in localStorage as `flutter.<key>`
// with a JSON-encoded value. Seeding it before the app boots skips the
// walkthrough, silences music (no audio device in the container) and picks
// the theme without touching the UI.
const prefs = {
  'flutter.arrow_onboarding_done': args.onboarding ? 'false' : 'true',
  'flutter.arrow_music_on': 'false',
  'flutter.arrow_haptics_on': 'false',
  'flutter.arrow_sfx_on': 'false',
  'flutter.arrow_grid_lines': grid ? 'true' : 'false',
  'flutter.arrow_theme': JSON.stringify(dark ? 'dark' : 'light'),
  // A string preference is stored JSON-encoded (quoted); the saved game is a
  // JSON document inside that string.
  ...(resume && levels.length
    ? { 'flutter.arrow_saved_game': JSON.stringify(JSON.stringify({ level: levels[0], removed: [0, 1], mistakes: 1, hintsLeft: 2, elapsedMs: 30_000 })) }
    : {}),
};

const problems = [];
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport: { width: 390, height: 844 },
  deviceScaleFactor: scale,
  isMobile: true,
  hasTouch: true,
  colorScheme: dark ? 'dark' : 'light',
  locale: 'en-US',
});
await context.addInitScript((p) => {
  for (const [k, v] of Object.entries(p)) localStorage.setItem(k, v);
}, prefs);

const page = await context.newPage();
page.on('pageerror', (e) => problems.push(`JS error: ${e.message}\n${String(e.stack ?? '').split('\n').slice(0, 8).join('\n')}`));
page.on('console', (m) => {
  const text = m.text();
  if (text.includes('EXCEPTION CAUGHT BY')) problems.push(text.split('\n').slice(0, 4).join('\n'));
  else if (m.type() === 'error') console.error('[console]', text.slice(0, 300));
});

let exitCode = 0;
try {
  await page.goto(base, { waitUntil: 'load' });
  await page.waitForSelector('flutter-view, flt-glass-pane', { state: 'attached', timeout: 60_000 });
  await enableSemantics(page);
  await settle(page, 1500);

  if (args.dump) console.log(await dumpSemantics(page));

  const tag = `${dark ? 'dark' : 'light'}${grid ? '-grid' : ''}${resume ? '-resume' : ''}`;
  await shoot(page, `${args.onboarding ? 'onboarding' : 'home'}-${tag}`);

  if (args.settings) {
    await page.getByRole('button', { name: /^settings/i }).first().click();
    await settle(page, 800);
    await shoot(page, `settings-${tag}`);
    await goBack(page);
  }

  // The journey trail is a long scroll view. Playwright cannot scroll a
  // Flutter scroll view through the semantics tree, and a single big wheel
  // delta is clamped, so nudge the wheel until the node's box is in view.
  for (const level of levels) {
    // The accessible name of a node is "Level N" + its digit (and the "Next
    // up" card is "Level N <name>"), so anchor only the start and take the
    // trail node, which comes after the card in the tree.
    const name = new RegExp(`^Level ${level}(\\s|$)`);
    const tile = page.getByRole('button', { name }).last();
    await page.mouse.move(195, 500);
    // A node that is not yet in the semantics tree (Flutter builds it lazily
    // for the visible part of the list) has no box; ask briefly and keep
    // nudging rather than sit through Playwright's 30 s default per probe.
    for (let i = 0; i < 120; i++) {
      const box = await tile.boundingBox({ timeout: 500 }).catch(() => null);
      if (box && box.y > 120 && box.y + box.height < 720) break;
      await page.mouse.wheel(0, box && box.y <= 120 ? -180 : 180);
      await settle(page, 150);
    }
    await tile.click();
    await settle(page, 1200);
    const id = String(level).padStart(2, '0');
    await shoot(page, `level-${id}-${tag}`);
    if (hint) {
      await page.getByRole('button', { name: /^Hint/ }).first().click();
      await settle(page, 500);
      await shoot(page, `level-${id}-hint-${tag}`);
    }
    await goBack(page);
  }
} catch (e) {
  problems.push(`Driver failed: ${e.message.split('\n')[0]}`);
  await shoot(page, 'failure').catch(() => {});
} finally {
  await browser.close();
  server.close();
}

if (problems.length) {
  console.error(`\n${problems.length} problem(s) while driving the app:`);
  for (const p of problems) console.error(' -', p.replace(/\n/g, '\n   '));
  if (strict) exitCode = 1;
}
console.log(`Screenshots written to ${outDir}`);
process.exit(exitCode);

// --------------------------------------------------------------------------

async function enableSemantics(page) {
  // Flutter renders an off-screen "Enable accessibility" button; clicking it
  // (programmatically — it is not visible) switches the semantics tree on.
  const placeholder = page.locator('flt-semantics-placeholder, [aria-label="Enable accessibility"]').first();
  await placeholder.waitFor({ state: 'attached', timeout: 60_000 });
  await placeholder.dispatchEvent('click');
  await page.waitForSelector('flt-semantics-host [role]', { state: 'attached', timeout: 30_000 });
}

async function dumpSemantics(page) {
  return page.evaluate(() => {
    const out = [];
    for (const el of document.querySelectorAll('flt-semantics-host *')) {
      const role = el.getAttribute('role');
      const label = el.getAttribute('aria-label');
      const text = (el.childNodes.length === 1 && el.firstChild.nodeType === 3) ? el.textContent.trim() : '';
      if (role || label || text) out.push(`${el.tagName.toLowerCase()} role=${role ?? '-'} label=${label ?? '-'} text=${text}`);
    }
    return out.join('\n');
  });
}

async function goBack(page) {
  const back = page.getByRole('button', { name: /^back/i }).first();
  if (await back.count()) await back.click(); else await page.goBack();
  await settle(page, 800);
}

function settle(page, ms) { return page.waitForTimeout(ms); }

async function shoot(page, name) {
  const file = path.join(outDir, `${name}.png`);
  await page.screenshot({ path: file });
  console.log('  wrote', path.relative(process.cwd(), file));
}

function parseArgs(argv) {
  const out = {};
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (!a.startsWith('--')) continue;
    const key = a.slice(2);
    const next = argv[i + 1];
    if (next === undefined || next.startsWith('--')) out[key] = true;
    else { out[key] = next; i++; }
  }
  return out;
}
