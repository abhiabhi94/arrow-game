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
//                            [--viewport 1440x900] [--keys Equal,KeyH] [--crash 2,4]
//                            [--riddle 2,4,2,3,2,2] [--riddle-answer shadow] [--lang hi]
//
//   --levels  opens each level and captures its board (level-NN-*.png); the
//             first one that has to be scrolled to also captures home with
//             its pinned header collapsed (home-scrolled-*.png)
//   --hint    also taps the hint button and captures the glowing arrow
//             (level-NN-hint-*.png)
//   --grid    seeds the grid-lines preference on (the lattice under the arrows)
//   --resume  seeds a saved game on the first level (home shows Continue, the level its Welcome back card)
//   --onboarding  boots into the first-launch walkthrough instead of home
//   --viewport WxH  renders the desktop layout instead of a phone (the web build
//             is also served on GitHub Pages, where people play it on a laptop);
//             non-phone shots carry the size in their filename
//   --keys    Playwright key names pressed on each opened level, then captured
//             (level-NN-keys-*.png): e.g. Equal zooms in, KeyH asks for a hint
//   --riddle x,y,...  spends every life on the first level by tapping the
//             given blocked cells (level 1: 2,4,2,3,2,2 are three different
//             blocked heads), then captures the "Out of lives" card, the
//             riddle behind it, the riddle with its clue out, the riddle with
//             its first letter out too, and the answer accepted
//             (level-NN-riddle-*.png). The pack is seeded in order,
//             so the riddle is always the first in the bank and
//             --riddle-answer (default "shadow") is its answer. The run
//             is a problem (exit 1) unless the solved card appears: the
//             answer is typed with the keyboard, so this is what checks
//             that the field still had it after the chips were pressed.
//   --lang    seeds the language setting ('en' or 'hi'), so the shots show the
//             app in that language whatever the browser's locale is; the
//             language lands in the filename
//   --crash x,y  taps grid cell (x, y) on the first level and captures the
//             moment after impact (level-NN-crash-*.png): the screen jolt and
//             the red flash of a bump. On level 1, cell 2,4 is a blocked head.
//             A screenshot takes longer than the bump, so this run drives the
//             page on Playwright's fake clock and steps it to the frame.
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
// Fonts: the app bundles Google Sans Flex (assets/fonts/), but the engine still fetches
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
// Phone by default; `--viewport WxH` renders the desktop layout instead.
const viewport = parseViewport(args.viewport);
const isPhone = viewport.width < 600;
// Keys to press on each opened level, so keyboard shortcuts can be smoke-tested
// the same way taps are (e.g. `--keys Equal,Equal,KeyH`).
const keys = String(args.keys ?? '').split(',').map((s) => s.trim()).filter(Boolean);
const crash = parseCell(args.crash);
const riddleCells = parseCells(args.riddle);
const riddleAnswer = typeof args['riddle-answer'] === 'string' ? args['riddle-answer'] : 'shadow';
const lang = parseLang(args.lang);
// The driver finds widgets by their accessible name, which is localized, so
// a --lang run needs that language's names.
const labels = lang === 'hindi'
  ? {
      settings: /^सेटिंग्स/,
      level: (n) => new RegExp(`^लेवल ${n}(\\s|$)`),
      hint: /^संकेत/,
      back: /^(वापस|back)/i,
      solveRiddle: /पहेली बूझें$/,
      riddleHint: /थोड़ा संकेत दीजिए$/,
      riddleNudge: /एक और इशारा$/,
      riddleSubmit: /यही मेरा जवाब है$/,
      riddleSolved: /तीरों पर वापस$/,
    }
  : {
      settings: /^settings/i,
      level: (n) => new RegExp(`^Level ${n}(\\s|$)`),
      hint: /^Hint/,
      back: /^back/i,
      solveRiddle: /Solve a riddle$/,
      riddleHint: /Give me a hint$/,
      riddleNudge: /One more nudge$/,
      riddleSubmit: /That's my answer$/,
      riddleSolved: /Back to the arrows$/,
    };

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
  // Only forced on with --grid; otherwise left unset so a shot shows the
  // app's own default (on, once the toggle has been earned).
  ...(grid ? { 'flutter.arrow_grid_lines': 'true' } : {}),
  'flutter.arrow_theme': JSON.stringify(dark ? 'dark' : 'light'),
  // Unset by default, which is the app's own default: follow the device.
  ...(lang ? { 'flutter.arrow_language': JSON.stringify(lang) } : {}),
  // A string preference is stored JSON-encoded (quoted); the saved game is a
  // JSON document inside that string.
  // An unshuffled pack starting at the top, so the riddle in the shot is
  // always the same one (and --riddle-answer is its answer).
  ...(riddleCells
    ? {
        'flutter.arrow_riddle_order': JSON.stringify(
          Array.from({ length: 50 }, (_, i) => String(i + 1)),
        ),
        'flutter.arrow_riddle_cursor': '0',
      }
    : {}),
  ...(resume && levels.length
    ? { 'flutter.arrow_saved_game': JSON.stringify(JSON.stringify({ level: levels[0], removed: [0, 1], mistakes: 1, hintsLeft: 2, elapsedMs: 30_000 })) }
    : {}),
};

const problems = [];
const browser = await chromium.launch();
const context = await browser.newContext({
  viewport,
  deviceScaleFactor: scale,
  isMobile: isPhone,
  hasTouch: isPhone,
  colorScheme: dark ? 'dark' : 'light',
  locale: 'en-US',
});
await context.addInitScript((p) => {
  for (const [k, v] of Object.entries(p)) localStorage.setItem(k, v);
}, prefs);

const page = await context.newPage();
// The bump is over (180-460 ms in, 480 ms back) before a screenshot of the
// canvas can be taken, so a crash run puts the page on a fake clock — which
// keeps real time until pauseAt — and steps it to the frame it wants.
// Installed before the app boots: switching clocks under a running Flutter
// engine trips its frame-timestamp assertion in the debug build.
if (crash) await page.clock.install();
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

  // Non-phone runs carry their size in the filename so a desktop run doesn't
  // overwrite the phone shot of the same screen.
  const size = isPhone ? '' : `-${viewport.width}x${viewport.height}`;
  const tag = `${dark ? 'dark' : 'light'}${grid ? '-grid' : ''}${resume ? '-resume' : ''}${lang ? `-${args.lang}` : ''}${size}`;
  await shoot(page, `${args.onboarding ? 'onboarding' : 'home'}-${tag}`);

  if (args.settings) {
    await page.getByRole('button', { name: labels.settings }).first().click();
    await settle(page, 800);
    await shoot(page, `settings-${tag}`);
    await goBack(page);
  }

  // The journey trail is a long scroll view. Playwright cannot scroll a
  // Flutter scroll view through the semantics tree, and a single big wheel
  // delta is clamped, so nudge the wheel until the node's box is in view.
  // The home header is pinned, so the first level that needs scrolling to
  // reach also shows the header in its collapsed state — worth a shot, and
  // worth the smoke test seeing it laid out.
  let shotScrolledHome = false;
  for (const level of levels) {
    // The accessible name of a node is "Level N" + its digit (and the "Next
    // up" card is "Level N <name>"), so anchor only the start and take the
    // trail node, which comes after the card in the tree.
    const name = labels.level(level);
    const tile = page.getByRole('button', { name }).last();
    await page.mouse.move(195, 500);
    // A node that is not yet in the semantics tree (Flutter builds it lazily
    // for the visible part of the list) has no box; ask briefly and keep
    // nudging rather than sit through Playwright's 30 s default per probe.
    let nudged = false;
    for (let i = 0; i < 120; i++) {
      const box = await tile.boundingBox({ timeout: 500 }).catch(() => null);
      if (box && box.y > 120 && box.y + box.height < 720) break;
      await page.mouse.wheel(0, box && box.y <= 120 ? -180 : 180);
      await settle(page, 150);
      nudged = true;
    }
    if (nudged && !shotScrolledHome) {
      shotScrolledHome = true;
      await shoot(page, `home-scrolled-${tag}`);
    }
    await tile.click();
    await settle(page, 1200);
    if (args.dump) console.log(await dumpSemantics(page));
    const id = String(level).padStart(2, '0');
    await shoot(page, `level-${id}-${tag}`);
    if (crash && level === levels[0]) {
      await page.clock.pauseAt(Date.now() + 1000);
      await tapCell(page, crash);
      // 260 ms in: a short run hit at 180 ms, the screen is mid-shake and
      // the red edge is still most of the way up.
      await page.clock.runFor(260);
      await shoot(page, `level-${id}-crash-${tag}`);
      await page.clock.runFor(900);
      await page.clock.resume();
    }
    if (riddleCells && level === levels[0]) {
      // Three different blocked arrows: the same one twice is free.
      for (const cell of riddleCells) {
        await tapCell(page, cell);
        await settle(page, 1200); // the whole bump, or the tap is dropped
      }
      await shoot(page, `level-${id}-outoflives-${tag}`);
      await page.getByRole('button', { name: labels.solveRiddle }).first().click();
      await settle(page, 700);
      await shoot(page, `level-${id}-riddle-${tag}`);
      await page.getByRole('button', { name: labels.riddleHint }).first().click();
      await settle(page, 600);
      await shoot(page, `level-${id}-riddle-hint-${tag}`);
      // The second nudge gives the first letter: the fullest the card gets.
      await page.getByRole('button', { name: labels.riddleNudge }).first().click();
      await settle(page, 600);
      await shoot(page, `level-${id}-riddle-letter-${tag}`);
      await page.keyboard.type(riddleAnswer);
      await settle(page, 300);
      await page.getByRole('button', { name: labels.riddleSubmit }).first().click();
      // The answer was typed into whatever had the keyboard. If that was not
      // the field, the card is still asking, with an empty guess judged
      // wrong under it — and a screenshot of that is a passing run only if
      // nobody looks. So the run waits for the solved card's button by name
      // and counts its absence as a problem, the way a Flutter exception is.
      const solved = page.getByRole('button', { name: labels.riddleSolved }).first();
      const answered = await solved.waitFor({ state: 'attached', timeout: 5000 }).then(() => true, () => false);
      if (!answered) {
        problems.push(`Riddle not solved: typed "${riddleAnswer}" and submitted, but no "${labels.riddleSolved.source}" button appeared (the answer field lost the keyboard?)`);
      }
      await settle(page, 900);
      await shoot(page, `level-${id}-riddle-solved-${tag}`);
    }
    if (hint) {
      await page.getByRole('button', { name: labels.hint }).first().click();
      await settle(page, 500);
      await shoot(page, `level-${id}-hint-${tag}`);
    }
    if (keys.length) {
      for (const key of keys) {
        await page.keyboard.press(key);
        await settle(page, 250);
      }
      await shoot(page, `level-${id}-keys-${tag}`);
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
  const back = page.getByRole('button', { name: labels.back }).first();
  if (await back.count()) await back.click(); else await page.goBack();
  await settle(page, 800);
}

function settle(page, ms) { return page.waitForTimeout(ms); }

/// Taps the centre of grid cell {x, y} on the board. The board is one canvas
/// (a tappable node named "Puzzle board W by H"), so the cell size comes
/// from its box. With semantics on, a click lands on that node and Flutter
/// turns it into a *semantic* tap at the node's centre, whatever the cell;
/// so the semantics layer is made transparent to the pointer for the tap and
/// the click reaches the canvas with its real coordinates.
async function tapCell(page, { x, y }) {
  const board = page.getByRole('button', { name: /^Puzzle board \d+ by \d+$/ }).first();
  const name = await board.textContent();
  const [, w, h] = /(\d+) by (\d+)/.exec(name).map(Number);
  const box = await board.boundingBox();
  const cell = Math.min(box.width / w, box.height / h);
  const left = box.x + (box.width - cell * w) / 2;
  const top = box.y + (box.height - cell * h) / 2;
  const style = await page.addStyleTag({
    // The nodes set their own pointer-events inline, so hit every one of them.
    content: 'flt-semantics-host, flt-semantics-host * { pointer-events: none !important; }',
  });
  await page.mouse.click(left + (x + 0.5) * cell, top + (y + 0.5) * cell);
  await style.evaluate((el) => el.remove());
}

async function shoot(page, name) {
  const file = path.join(outDir, `${name}.png`);
  await page.screenshot({ path: file });
  console.log('  wrote', path.relative(process.cwd(), file));
}

/// `--crash 2,4` -> { x, y }; nothing when the flag is absent.
function parseCell(value) {
  if (!value || value === true) return null;
  const m = /^(\d+),(\d+)$/.exec(String(value));
  if (!m) { console.error(`Bad --crash ${value}; expected a grid cell, e.g. 2,4`); process.exit(2); }
  return { x: Number(m[1]), y: Number(m[2]) };
}

/// `--lang hi` -> the LanguageChoice name the app persists; nothing when the
/// flag is absent (the app then follows the device).
function parseLang(value) {
  if (!value || value === true) return null;
  const names = { en: 'english', hi: 'hindi' };
  const name = names[String(value)];
  if (!name) { console.error(`Bad --lang ${value}; expected en or hi`); process.exit(2); }
  return name;
}

/// `--riddle 2,4,2,3` -> [{x, y}, {x, y}]; nothing when the flag is absent.
function parseCells(value) {
  if (!value || value === true) return null;
  const parts = String(value).split(',').map((n) => n.trim());
  if (parts.length < 2 || parts.length % 2 || parts.some((n) => !/^\d+$/.test(n))) {
    console.error(`Bad --riddle ${value}; expected grid cells, e.g. 2,4,2,3,2,2`);
    process.exit(2);
  }
  const cells = [];
  for (let i = 0; i < parts.length; i += 2) cells.push({ x: Number(parts[i]), y: Number(parts[i + 1]) });
  return cells;
}

/// `--viewport 1440x900` -> { width, height }; defaults to a phone.
function parseViewport(value) {
  if (!value || value === true) return { width: 390, height: 844 };
  const m = /^(\d+)x(\d+)$/.exec(String(value));
  if (!m) { console.error(`Bad --viewport ${value}; expected WxH, e.g. 1440x900`); process.exit(2); }
  return { width: Number(m[1]), height: Number(m[2]) };
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
