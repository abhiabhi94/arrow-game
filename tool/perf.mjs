#!/usr/bin/env node
// Plays levels of the web build in headless Chromium slowed to a phone's
// speed, and fails (exit 1) when a frame's work goes over its budget: CI's
// guard against a change that makes the game lag on a phone.
//
// Usage:
//   node tool/perf.mjs [--levels 1,20,100,150,200,201,230,250] [--throttle 4]
//                      [--build-dir build/web] [--out perf] [--port 0]
//                      [--cpu-profile]
//
// Prereq: a release web build with every level open, which carries the
// profiling hooks (lib/utils/perf_hooks.dart):
//   flutter build web --release --dart-define=UNLOCK_ALL=true --no-web-resources-cdn --no-wasm-dry-run
// (a debug build is many times slower and measures nothing a player sees).
//
// How it measures. Each level is opened at `?perf&level=N`, straight onto
// its board — no semantics tree, which a player does not have either —
// with Chromium's CPU throttled through the DevTools protocol (`--throttle`,
// default 4: about a mid-range phone's JavaScript against a CI runner).
// The level is then played in phases:
//
//   deal   the board being dealt: how long, and the longest freeze of the
//          screen meanwhile (the web deals on the screen's own thread, a
//          face of a block at a time)
//   idle   3 s left alone (the clock ticks ten times a second)
//   turn   Shift+Right, Shift+Up, Shift+Down: the block turning
//   drag   a finger dragged across the block
//   play   arrows played with the keyboard (cursor, Enter): slides and
//          bumps; at least one has to reach an arrow
//
// What is budgeted is each frame's **Dart work** — build, layout and paint,
// reported by the app itself (`perf:frames`, Flutter's FrameTiming): the
// same code a phone runs, so it scales with the CPU and the throttle stands
// in for a phone. Its 95th percentile and its worst frame, per phase. The
// frames' *drawing* is not budgeted: a CI runner has no GPU, so Chromium
// draws in software, many times slower than a phone's GPU; it is reported
// (`raster`, and `gap`, the gaps between the page's own animation frames,
// and `tap`, a key press to the next frame) to read, not to gate.
//
// Out: <out>/perf.json (everything), <out>/summary.md (the table, which CI
// posts on the PR and in the job summary), and with --cpu-profile a CPU
// profile of the idle and play phases per level (.cpuprofile, for Chrome
// DevTools, plus the hottest functions in perf.json — a `--profile` web
// build keeps their names).

process.env.NODE_USE_ENV_PROXY ??= '1';

import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const { chromium } = require('playwright');

const args = parseArgs(process.argv.slice(2));
const buildDir = path.resolve(args['build-dir'] ?? 'build/web');
const outDir = path.resolve(args.out ?? 'perf');
const levels = String(args.levels ?? '1,100,150,201,230,250').split(',').map(Number).filter(Boolean);
const throttle = Number(args.throttle ?? 4);
const port = Number(args.port ?? 0);

/// Budgets in ms at 4x throttle, per phase: `p95` and `max` are a frame's
/// Dart work (95th percentile, worst frame); the deal has its whole time
/// (`ms`) and its longest freeze (`freeze`). See BUDGETS_NOTE.
const BUDGETS = {
  deal: { ms: 20_000, freeze: 4_000 },
  idle: { p95: 60, max: 120 },
  turn: { p95: 120, max: 250 },
  drag: { p95: 120, max: 250 },
  play: { p95: 150, max: 300 },
};
const BUDGETS_NOTE = '';
// Budgets hold at the throttle they were set for; another throttle scales
// them (a phone twice as slow does twice the work in a frame's time).
const scale = throttle / 4;

if (!fs.existsSync(path.join(buildDir, 'index.html'))) {
  console.error(`No web build at ${buildDir}. Run: flutter build web --release --dart-define=UNLOCK_ALL=true --no-web-resources-cdn --no-wasm-dry-run`);
  process.exit(2);
}
fs.mkdirSync(outDir, { recursive: true });

// A plain static server for the build (the profiler needs no fallback
// fonts: nothing it measures is text).
const MIME = {
  '.html': 'text/html', '.js': 'text/javascript', '.mjs': 'text/javascript', '.css': 'text/css',
  '.json': 'application/json', '.wasm': 'application/wasm', '.png': 'image/png', '.ico': 'image/x-icon',
  '.mp3': 'audio/mpeg', '.wav': 'audio/wav', '.ttf': 'font/ttf', '.otf': 'font/otf',
};
const server = http.createServer((req, res) => {
  const urlPath = decodeURIComponent(new URL(req.url, 'http://x').pathname);
  const file = path.join(buildDir, urlPath === '/' ? 'index.html' : urlPath);
  if (!file.startsWith(buildDir) || !fs.existsSync(file) || fs.statSync(file).isDirectory()) {
    res.writeHead(404); res.end(); return;
  }
  res.writeHead(200, { 'Content-Type': MIME[path.extname(file)] ?? 'application/octet-stream' });
  fs.createReadStream(file).pipe(res);
});
await new Promise((r) => server.listen(port, '127.0.0.1', r));
const base = `http://127.0.0.1:${server.address().port}/`;

// Every chapter card already seen (a card over the board is not play), no
// sound (no audio device), the walkthrough done.
const prefs = {
  'flutter.arrow_onboarding_done': 'true',
  'flutter.arrow_music_on': 'false',
  'flutter.arrow_sfx_on': 'false',
  'flutter.arrow_haptics_on': 'false',
  'flutter.arrow_theme': JSON.stringify('light'),
  'flutter.arrow_intros_seen': JSON.stringify(['mirrors', 'locks', 'fog', 'pairs', 'cube', 'squeeze', 'box']),
};

const browser = await chromium.launch();
const report = [];
const failures = [];
const problems = [];
try {
  for (const level of levels) report.push(await profile(level));
} finally {
  await browser.close();
  server.close();
}

for (const r of report) {
  for (const [phase, budget] of Object.entries(BUDGETS)) {
    const got = r[phase];
    if (!got) continue;
    for (const [key, limit] of Object.entries(budget)) {
      const value = phase === 'deal' ? got[key] : got.dart?.[key];
      if (value === undefined) {
        failures.push(`level ${r.level} ${phase}: no ${key} measured (no frames reported)`);
      } else if (value > limit * scale) {
        failures.push(`level ${r.level} ${phase}: ${phase === 'deal' ? key : `Dart work ${key}`} ${value} ms > ${Math.round(limit * scale)} ms`);
      }
    }
  }
}

fs.writeFileSync(path.join(outDir, 'perf.json'), JSON.stringify({ throttle, budgets: BUDGETS, levels: report }, null, 2));
const table = renderTable(report, failures);
fs.writeFileSync(path.join(outDir, 'summary.md'), `${table}\n`);
console.log(table);
if (process.env.GITHUB_STEP_SUMMARY) fs.appendFileSync(process.env.GITHUB_STEP_SUMMARY, `${table}\n`);
for (const p of problems) console.error(' -', p);
if (failures.length) {
  console.error(`\n${failures.length} budget(s) broken at ${throttle}x CPU throttle:`);
  for (const f of failures) console.error(' -', f);
}
process.exit(failures.length || problems.length ? 1 : 0);

// --------------------------------------------------------------------------

async function profile(level) {
  const context = await browser.newContext({
    viewport: { width: 390, height: 844 },
    deviceScaleFactor: 2,
    isMobile: true,
    hasTouch: true,
    locale: 'en-US',
  });
  await context.addInitScript((p) => {
    for (const [k, v] of Object.entries(p)) localStorage.setItem(k, v);
    // Every frame's timestamp, from before the app boots.
    window.__frames = [];
    const loop = (t) => { window.__frames.push(t); requestAnimationFrame(loop); };
    requestAnimationFrame(loop);
  }, prefs);
  const page = await context.newPage();
  const cdp = await context.newCDPSession(page);
  await cdp.send('Emulation.setCPUThrottlingRate', { rate: throttle });

  const marks = {};
  const frameTimings = [];
  const played = [];
  page.on('console', (m) => {
    const text = m.text();
    if (text.startsWith('perf:frames ')) {
      frameTimings.push(text.slice(12).split(' ').map((p) => {
        const [build, raster] = p.split('/').map(Number);
        return { build: build / 1000, raster: raster / 1000 };
      }));
      return;
    }
    if (text.startsWith('perf:tap ')) { played.push(Number(text.slice(9))); return; }
    const mark = /^perf:(\w+) (\d+)/.exec(text);
    if (mark) marks[mark[1]] = page.evaluate(() => performance.now()).catch(() => 0);
    if (text.includes('EXCEPTION CAUGHT BY')) problems.push(`level ${level}: ${text.split('\n').slice(0, 3).join(' ')}`);
  });
  page.on('pageerror', (e) =>
    problems.push(`level ${level}: JS error ${e.message}\n${String(e.stack ?? '').split('\n').slice(0, 8).join('\n')}`),
  );

  const result = { level };
  await page.goto(`${base}?perf&level=${level}`, { waitUntil: 'load' });
  const until = Date.now() + 180_000;
  while (!marks.dealt && Date.now() < until) await page.waitForTimeout(100);
  if (!marks.dealt) {
    problems.push(`level ${level}: no board after 180 s`);
    await context.close();
    return result;
  }
  const dealing = await marks.dealing;
  const dealt = await marks.dealt;
  await page.waitForTimeout(1500); // the board's entrance
  const dealGaps = await gaps(page, dealing, dealt);
  result.deal = { ms: Math.round(dealt - dealing), freeze: dealGaps.max };

  if (args['cpu-profile']) {
    await cdp.send('Profiler.enable');
    await cdp.send('Profiler.setSamplingInterval', { interval: 200 });
    await cdp.send('Profiler.start');
  }
  result.idle = await phase(page, frameTimings, async () => page.waitForTimeout(3000));
  if (args['cpu-profile']) {
    const { profile } = await cdp.send('Profiler.stop');
    fs.writeFileSync(path.join(outDir, `idle-${level}.cpuprofile`), JSON.stringify(profile));
    result.idle.hot = hottest(profile, 60);
  }
  result.turn = await phase(page, frameTimings, async () => {
    await page.keyboard.press('Shift+ArrowRight');
    await page.waitForTimeout(900);
    await page.keyboard.press('Shift+ArrowUp');
    await page.waitForTimeout(900);
    await page.keyboard.press('Shift+ArrowDown');
    await page.waitForTimeout(900);
  });
  result.drag = await phase(page, frameTimings, async () => {
    const x = 195;
    const y = 470;
    await page.mouse.move(x, y);
    await page.mouse.down();
    for (let i = 1; i <= 30; i++) {
      await page.mouse.move(x - 3 * i, y + i);
      await page.waitForTimeout(30);
    }
    await page.mouse.up();
    await page.waitForTimeout(1000);
  });
  // An arrow played: the cursor walks to one and Enter plays it — a slide
  // out, or a bump (which may spend a life; that is play too). What a
  // player feels is the wait from the touch to the first frame that
  // answers it (`tap`, the worst of the arrows played) and how smoothly the
  // arrow then slides away (the frame gaps over the whole move).
  const taps = [];
  if (args['cpu-profile']) {
    await cdp.send('Profiler.enable');
    await cdp.send('Profiler.setSamplingInterval', { interval: 200 });
    await cdp.send('Profiler.start');
  }
  result.play = await phase(page, frameTimings, async () => {
    const walk = ['ArrowDown', 'ArrowRight', 'ArrowUp', 'ArrowLeft', 'ArrowDown', 'ArrowRight'];
    for (const key of walk) {
      await page.keyboard.press(key);
      await page.waitForTimeout(300);
      const at = await page.evaluate(() => performance.now());
      await page.keyboard.press('Enter');
      await page.waitForTimeout(900);
      taps.push(await page.evaluate((t) => {
        const next = window.__frames.find((f) => f > t);
        return next === undefined ? 900 : next - t;
      }, at));
    }
  });
  result.play.tap = Math.round(Math.max(...taps));
  // Arrows the taps reached: a play phase that played nothing measured
  // nothing.
  result.play.played = played.length;
  if (!played.length) problems.push(`level ${level}: the keyboard played no arrow`);
  if (args['cpu-profile']) {
    const { profile } = await cdp.send('Profiler.stop');
    fs.writeFileSync(path.join(outDir, `play-${level}.cpuprofile`), JSON.stringify(profile));
    result.play.hot = hottest(profile);
  }
  await context.close();
  return result;
}

/// Runs [act] and returns the frame gaps it saw, and the Dart build and
/// raster times of the frames the app reported meanwhile ([frameTimings],
/// filled from its `perf:frames` lines).
async function phase(page, frameTimings, act) {
  const before = frameTimings.length;
  const from = await page.evaluate(() => performance.now());
  await act();
  const to = await page.evaluate(() => performance.now());
  await page.waitForTimeout(400); // the last frames' report
  const timings = frameTimings.slice(before).flat();
  return {
    dart: spread(timings.map((t) => t.build)),
    raster: spread(timings.map((t) => t.raster)),
    gap: await gaps(page, from, to),
    frames: timings.length,
  };
}

/// The 95th percentile and maximum of [values] (ms), or undefined for none.
function spread(values) {
  if (!values.length) return undefined;
  const v = [...values].sort((a, b) => a - b);
  return { p95: Math.round(v[Math.min(v.length - 1, Math.floor(v.length * 0.95))]), max: Math.round(v[v.length - 1]) };
}

/// The frames between [from] and [to] (page time): how many, and their
/// gaps' 95th percentile and maximum, in ms.
async function gaps(page, from, to) {
  const frames = await page.evaluate(([a, b]) => window.__frames.filter((t) => t >= a && t <= b), [from, to]);
  const d = [];
  for (let i = 1; i < frames.length; i++) d.push(frames[i] - frames[i - 1]);
  // (A phase is measured from just before it to just after.)
  // The stretch before the first frame and after the last counts too: a
  // freeze that swallows the whole phase has no frames at all.
  if (frames.length) {
    d.push(frames[0] - from);
    d.push(to - frames[frames.length - 1]);
  } else {
    d.push(to - from);
  }
  d.sort((a, b) => a - b);
  return {
    frames: frames.length,
    p95: Math.round(d[Math.min(d.length - 1, Math.floor(d.length * 0.95))]),
    max: Math.round(d[d.length - 1]),
  };
}

/// The functions that took the most of a CPU profile's time, by their own
/// time and with what they called (`--cpu-profile`): where a slow phase
/// went.
function hottest(profile, count = 25) {
  const byId = new Map(profile.nodes.map((n) => [n.id, n]));
  const self = new Map();
  const dt = profile.timeDeltas;
  for (let i = 0; i < profile.samples.length; i++) {
    const id = profile.samples[i];
    self.set(id, (self.get(id) ?? 0) + (dt[i] ?? 0));
  }
  // Total time per node: its own plus its descendants'.
  const total = new Map();
  const sum = (n) => {
    if (total.has(n.id)) return total.get(n.id);
    let t = self.get(n.id) ?? 0;
    for (const c of n.children ?? []) t += sum(byId.get(c));
    total.set(n.id, t);
    return t;
  };
  for (const n of profile.nodes) sum(n);
  const name = (n) => `${n.callFrame.functionName || '(anon)'} ${path.basename(n.callFrame.url || '')}:${n.callFrame.lineNumber}`;
  const selfBy = new Map();
  const totalBy = new Map();
  for (const n of profile.nodes) {
    const k = name(n);
    selfBy.set(k, (selfBy.get(k) ?? 0) + (self.get(n.id) ?? 0));
    totalBy.set(k, Math.max(totalBy.get(k) ?? 0, total.get(n.id)));
  }
  const top = (m) => [...m.entries()].sort((a, b) => b[1] - a[1]).slice(0, count).map(([k, v]) => `${Math.round(v / 1000)} ms ${k}`);
  return { self: top(selfBy), total: top(totalBy) };
}

function renderTable(rows, broken) {
  const pair = (v) => (v ? `${v.p95} / ${v.max}` : '—');
  const lines = [
    `### ${broken.length ? '❌' : '✅'} Frame budget at ${throttle}x CPU throttle`,
    '',
    'Each level of the release web build played in headless Chromium slowed to a phone\'s speed (390×844). ' +
      'Budgeted: each frame\'s **Dart work** (build, layout, paint), 95th percentile / worst frame, in ms. ' +
      'The deal: its time and its longest freeze of the screen.',
    '',
    '| Level | Deal | Deal freeze | Idle | Turn | Drag | Play | Arrows played |',
    '|---|---|---|---|---|---|---|---|',
  ];
  for (const r of rows) {
    lines.push(`| ${r.level} | ${r.deal?.ms ?? '—'} | ${r.deal?.freeze ?? '—'} | ${pair(r.idle?.dart)} | ${pair(r.turn?.dart)} | ${pair(r.drag?.dart)} | ${pair(r.play?.dart)} | ${r.play?.played ?? '—'} |`);
  }
  const b = (k) => `${Math.round(BUDGETS[k].p95 * scale)} / ${Math.round(BUDGETS[k].max * scale)}`;
  lines.push(
    `| **Budget** | ${Math.round(BUDGETS.deal.ms * scale)} | ${Math.round(BUDGETS.deal.freeze * scale)} | ${b('idle')} | ${b('turn')} | ${b('drag')} | ${b('play')} | ≥ 1 |`,
    '',
  );
  if (broken.length) lines.push('**Over budget:**', '', ...broken.map((f) => `- ${f}`), '');
  lines.push(
    '<details><summary>Drawing (not budgeted)</summary>',
    '',
    'A CI runner has no GPU, so Chromium draws in software, many times slower than a phone\'s GPU: these are here to read, not to gate. ' +
      '`raster` is a frame\'s drawing, `gap` the gaps between the page\'s animation frames, `tap` a key press to the next frame (ms, 95th percentile / worst).',
    '',
    '| Level | Idle raster | Play raster | Idle gap | Play gap | Tap |',
    '|---|---|---|---|---|---|',
    ...rows.map((r) => `| ${r.level} | ${pair(r.idle?.raster)} | ${pair(r.play?.raster)} | ${pair(r.idle?.gap)} | ${pair(r.play?.gap)} | ${r.play?.tap ?? '—'} |`),
    '',
    '</details>',
  );
  if (BUDGETS_NOTE) lines.push('', BUDGETS_NOTE);
  return lines.join('\n');
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
