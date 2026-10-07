/* Jiff Tweaks V9 - UI logic */
(function () {
'use strict';

const $ = (s, el) => (el || document).querySelector(s);
const $$ = (s, el) => Array.from((el || document).querySelectorAll(s));
const esc = s => String(s).replace(/[&<>"]/g, c => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
const html = document.documentElement;

const S = {
  state: null, view: 'dashboard',
  anim: 'full', accent: 'green',
  applied: {}, needReboot: false,
  cpu: [], ram: [], metrics: null,
  run: null, pollTimer: null, tickTimer: null,
  online: true, fails: 0, pendingLog: null
};
const SAMPLES = 60;
const STEP_NAMES = ['Restore point', 'Registry', 'Services', 'Scheduled tasks', 'Network', 'Power plan', 'USB and PnP', 'Privacy', 'GPU', 'Boot timer', 'Debloat'];

/* ---------------------------------------------------------------- storage */
function lsGet(k, d) { try { const v = localStorage.getItem(k); return v === null ? d : v; } catch (e) { return d; } }
function lsSet(k, v) { try { localStorage.setItem(k, v); } catch (e) { /* ignore */ } }

/* ---------------------------------------------------------------- api */
async function api(path, opt) {
  const r = await fetch(path, Object.assign({ credentials: 'same-origin', cache: 'no-store' }, opt || {}));
  let body = null;
  try { body = await r.json(); } catch (e) { /* not json */ }
  if (!r.ok) { const err = new Error((body && body.error) || ('HTTP ' + r.status)); err.status = r.status; throw err; }
  return body;
}
const post = (p, b) => api(p, { method: 'POST', headers: { 'Content-Type': 'application/json' }, body: JSON.stringify(b || {}) });

/* ---------------------------------------------------------------- helpers */
function fmtTime(sec) { sec = Math.max(0, Math.floor(sec)); return Math.floor(sec / 60) + ':' + String(sec % 60).padStart(2, '0'); }
function fmtUptime(sec) {
  const d = Math.floor(sec / 86400), h = Math.floor(sec % 86400 / 3600), m = Math.floor(sec % 3600 / 60);
  return d ? d + 'd ' + h + 'h' : h ? h + 'h ' + m + 'm' : m + 'm';
}
function countTo(el, to, ms) {
  if (html.dataset.anim === 'off') { el.textContent = to.toLocaleString(); return; }
  const from = Number(el.dataset.cur || 0), t0 = performance.now(); ms = ms || 1000;
  (function f(t) {
    const p = Math.min(1, (t - t0) / ms), e = 1 - Math.pow(1 - p, 4);
    el.textContent = Math.round(from + (to - from) * e).toLocaleString();
    if (p < 1) requestAnimationFrame(f); else el.dataset.cur = to;
  })(t0);
}
function toast(title, msg, kind) {
  const el = document.createElement('div');
  el.className = 'toast ' + (kind || '');
  el.innerHTML = icon(kind === 'bad' ? 'alert' : 'check') + '<div><b>' + esc(title) + '</b>' + (msg ? '<span>' + esc(msg) + '</span>' : '') + '</div>';
  $('#toasts').appendChild(el);
  setTimeout(() => { el.classList.add('out'); setTimeout(() => el.remove(), 400); }, 4200);
}
function ripple(e) {
  const b = e.target.closest('.btn'); if (!b || html.dataset.anim === 'off') return;
  const r = b.getBoundingClientRect(), d = Math.max(r.width, r.height) * 2;
  const s = document.createElement('span'); s.className = 'ripple';
  s.style.cssText = 'width:' + d + 'px;height:' + d + 'px;left:' + (e.clientX - r.left - d / 2) + 'px;top:' + (e.clientY - r.top - d / 2) + 'px';
  b.appendChild(s); setTimeout(() => s.remove(), 700);
}

/* ---------------------------------------------------------------- settings */
function applyAnim(v) { S.anim = v; html.dataset.anim = v; lsSet('jt.anim', v); }
function applyAccent(v) { S.accent = v; html.dataset.accent = v; lsSet('jt.accent', v); }
function loadSettings() {
  let a = lsGet('jt.anim', null);
  if (!a) a = (window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches) ? 'reduced' : 'full';
  applyAnim(a); applyAccent(lsGet('jt.accent', 'green'));
  try { S.applied = JSON.parse(lsGet('jt.applied', '{}')) || {}; } catch (e) { S.applied = {}; }
}
function markApplied(id) {
  if (id.indexOf('restore') === 0 || id === 'forget_originals') { if (id === 'restore_all') S.applied = {}; }
  else S.applied[id] = Date.now();
  lsSet('jt.applied', JSON.stringify(S.applied));
}

/* ---------------------------------------------------------------- splash */
function splash() {
  const el = $('#splash');
  if (html.dataset.anim === 'off' || sessionStorage.getItem('jt.splash')) { el.remove(); return; }
  try { sessionStorage.setItem('jt.splash', '1'); } catch (e) { /* ignore */ }
  const end = () => { el.classList.add('gone'); setTimeout(() => el.remove(), 800); };
  const t = setTimeout(end, 2300);
  el.addEventListener('click', () => { clearTimeout(t); end(); });
}

/* ---------------------------------------------------------------- nav */
function buildNav() {
  const nav = $('#nav');
  GROUPS.forEach(g => {
    if (g.id === 'restore') { const gap = document.createElement('div'); gap.className = 'nav-gap'; nav.appendChild(gap); }
    const b = document.createElement('button');
    b.className = 'nav-item'; b.dataset.view = g.id; b.type = 'button';
    b.innerHTML = icon(g.icon) + '<span>' + esc(g.title) + '</span>';
    b.addEventListener('click', () => go(g.id));
    nav.appendChild(b);
  });
}
function movePill() {
  const a = $('.nav-item.active'); if (!a) return;
  const p = $('.nav-pill'); p.style.height = a.offsetHeight + 'px'; p.style.transform = 'translateY(' + a.offsetTop + 'px)';
}

/* ---------------------------------------------------------------- views */
function go(id) {
  S.view = id;
  $$('.nav-item').forEach(b => b.classList.toggle('active', b.dataset.view === id));
  movePill();
  const g = GROUPS.find(x => x.id === id);
  $('#pageTitle').textContent = g.title; $('#pageSub').textContent = g.sub;
  const v = $('#view');
  v.innerHTML = '';
  const wrap = document.createElement('div'); wrap.className = 'page'; v.appendChild(wrap);
  if (id === 'dashboard') viewDashboard(wrap);
  else if (id === 'restore') viewRestore(wrap);
  else if (id === 'logs') viewLogs(wrap);
  else if (id === 'settings') viewSettings(wrap);
  else viewPage(wrap, id);
  v.scrollTop = 0;
  renderTopRight();
}

function backupTotal(b) { return b ? (b.services + b.regKeys + b.tasks + b.plans) : 0; }

function viewDashboard(w) {
  const st = S.state, sys = (st && st.sys) || {}, b = (st && st.backup) || { services: 0, regKeys: 0, regValues: 0, tasks: 0, plans: 0, hasBaseline: false };
  const gpus = (sys.gpu || []).join(' / ') || 'Unknown';
  const full = CATALOG.apply_full;
  w.innerHTML = `
  <div class="dash">
    <section class="card hero rise tilt" style="--i:0">
      <div class="hero-kicker">${icon('sparkle')} Recommended</div>
      <h2>Full profile in one click</h2>
      <p>Registry, services, network, power plan, privacy, GPU and debloat. A restore point is created first and every original value is saved.</p>
      <div class="hero-tags">${['Registry', 'Services', 'Network', 'Power', 'Privacy', 'GPU', 'Debloat'].map(t => '<span class="chip accent">' + t + '</span>').join('')}</div>
      <div class="hero-meta"><div class="seg-bar">${Array.from({ length: 11 }, (_, k) => '<i style="--k:' + k + '"></i>').join('')}</div><span>11 steps, usually a few minutes. Restart required afterward.</span></div>
      <div class="hero-actions">
        <button class="btn primary big" data-act="open" data-id="apply_full">${icon('play')} Apply full profile</button>
        <button class="btn ghost" data-act="open" data-id="apply_full" data-info="1">What it does</button>
      </div>
      <svg class="hero-art" viewBox="0 0 64 64" fill="none" aria-hidden="true"><circle cx="32" cy="32" r="28" stroke="url(#jg)" stroke-width="3"/><path d="M38 16v22a8 8 0 0 1-8 8 8 8 0 0 1-8-6" stroke="url(#jg)" stroke-width="4.5" stroke-linecap="round" stroke-linejoin="round"/></svg>
    </section>

    <section class="card sys rise" style="--i:1">
      <h3>This PC</h3>
      <div class="gauges">
        <div class="gauge" id="gCpu"><svg viewBox="0 0 100 100"><circle class="trk" cx="50" cy="50" r="44"/><circle class="val" cx="50" cy="50" r="44"/></svg><div class="mid"><b>--</b><small>CPU</small></div></div>
        <div class="gauge" id="gRam"><svg viewBox="0 0 100 100"><circle class="trk" cx="50" cy="50" r="44"/><circle class="val" cx="50" cy="50" r="44"/></svg><div class="mid"><b>--</b><small>RAM</small></div></div>
      </div>
      <div class="kv">
        <div><span>System</span><span>${esc(sys.os || '-')} ${esc(sys.version || '')}</span></div>
        <div><span>CPU</span><span title="${esc(sys.cpu || '')}">${esc(sys.cpu || '-')}</span></div>
        <div><span>GPU</span><span title="${esc(gpus)}">${esc(gpus)}</span></div>
        <div><span>Memory</span><span>${sys.ramGb || '-'} GB</span></div>
        <div><span>Disk</span><span>${sys.diskFreeGb || '-'} GB free of ${sys.diskTotalGb || '-'} GB</span></div>
        <div><span>Uptime</span><span id="kvUp">-</span></div>
        <div><span>Power plan</span><span id="kvPlan">${esc(sys.plan || '-')}</span></div>
      </div>
    </section>

    <div class="stats">
      <section class="card tile hero-fig rise" style="--i:2"><div class="tile-head">Changes you can undo</div><div class="num" data-count="${backupTotal(b)}">0</div><div class="sub">${b.hasBaseline ? 'Saved originals are ready for Restore' : 'Nothing saved yet. Originals are saved the first time you apply a tweak.'}</div></section>
      <section class="card tile rise" style="--i:3"><div class="tile-head">Services</div><div class="num" data-count="${b.services}">0</div><div class="lbl">start types saved</div></section>
      <section class="card tile rise" style="--i:4"><div class="tile-head">Registry keys</div><div class="num" data-count="${b.regKeys}">0</div><div class="lbl">backed up, ${b.regValues} values added</div></section>
      <section class="card tile rise" style="--i:5"><div class="tile-head">Tasks</div><div class="num" data-count="${b.tasks}">0</div><div class="lbl">disabled by Jiff Tweaks</div></section>
      <section class="card tile rise" style="--i:6"><div class="tile-head">Power plans</div><div class="num" data-count="${b.plans}">0</div><div class="lbl">exported</div></section>
    </div>

    <div class="metrics">
      ${sparkCard('cpu', 'CPU load', 7)}
      ${sparkCard('ram', 'Memory in use', 8)}
      <section class="card baseline rise" style="--i:9">
        <div class="tile-head">Safety</div>
        <div class="state"><div class="badge-ic ${b.hasBaseline ? '' : 'muted'}">${icon(b.hasBaseline ? 'database' : 'info')}</div>
          <div><b>${b.hasBaseline ? 'Baseline saved' : 'No baseline yet'}</b><div class="lbl" style="color:var(--text-2);font-size:13px">${b.hasBaseline ? 'Restore can return this PC to its original state.' : 'It is created automatically on your first change.'}</div></div></div>
        <div style="margin-top:auto;display:flex;gap:10px"><button class="btn ghost small" data-go="restore">${icon('restore')} Open Restore</button><button class="btn ghost small" data-go="logs">${icon('file')} Logs</button></div>
      </section>
    </div>
  </div>`;
  $$('[data-count]', w).forEach((el, i) => setTimeout(() => countTo(el, Number(el.dataset.count)), 250 + i * 90));
  updateLive();
  drawSpark('cpu'); drawSpark('ram');
}

function sparkCard(key, title, i) {
  return `<section class="card spark-card rise" style="--i:${i}">
    <div class="spark-head"><div class="tile-head">${title}</div><div class="big" id="sv-${key}">--<small>%</small></div></div>
    <div class="spark" id="sp-${key}"><svg></svg><div class="tip"></div></div>
  </section>`;
}

/* ---- sparkline: 2px line, 10% area wash, end dot with surface ring, hover crosshair + tooltip */
function drawSpark(key) {
  const host = $('#sp-' + key); if (!host) return;
  const data = S[key], svg = $('svg', host), W = Math.max(120, host.clientWidth), H = host.clientHeight;
  svg.setAttribute('viewBox', '0 0 ' + W + ' ' + H);
  const pad = 6, n = Math.max(1, data.length - 1), x = i => (data.length < 2 ? W : (i / n) * W), y = v => H - pad - (Math.max(0, Math.min(100, v)) / 100) * (H - pad * 2);
  const off = 0;
  let line = '', area = '';
  data.forEach((v, i) => { const X = x(i + off).toFixed(1), Y = y(v).toFixed(1); line += (i ? 'L' : 'M') + X + ' ' + Y + ' '; });
  if (data.length > 1) area = line + 'L' + x(data.length - 1).toFixed(1) + ' ' + (H - pad) + ' L' + x(0).toFixed(1) + ' ' + (H - pad) + ' Z';
  const last = data.length ? data[data.length - 1] : 0;
  svg.innerHTML =
    [0, 50, 100].map(g => '<line class="grid" x1="0" x2="' + W + '" y1="' + y(g).toFixed(1) + '" y2="' + y(g).toFixed(1) + '"/>').join('') +
    (area ? '<path class="area" d="' + area + '"/>' : '') +
    (line ? '<path class="line" d="' + line + '"/>' : '') +
    (data.length ? '<circle class="dot" r="4.5" cx="' + x(data.length - 1).toFixed(1) + '" cy="' + y(last).toFixed(1) + '"/>' : '') +
    '<line class="cross" id="cr-' + key + '" y1="0" y2="' + H + '" style="display:none"/><circle class="hdot" id="hd-' + key + '" r="4.5" style="display:none"/>';
  host.__draw = { W, H, x, y, off };
  if (!host.__bound) {
    host.__bound = true;
    host.addEventListener('pointermove', e => {
      const d = host.__draw, S2 = S[key]; if (!S2.length) return;
      const r = host.getBoundingClientRect(), px = e.clientX - r.left;
      let i = Math.round(px / d.W * Math.max(1, S2.length - 1)); i = Math.max(0, Math.min(S2.length - 1, i));
      const X = d.x(i), Y = d.y(S2[i]);
      const cr = $('#cr-' + key), hd = $('#hd-' + key), tip = $('.tip', host);
      cr.setAttribute('x1', X); cr.setAttribute('x2', X); cr.style.display = '';
      hd.setAttribute('cx', X); hd.setAttribute('cy', Y); hd.style.display = '';
      const ago = (S2.length - 1 - i) * 2;
      tip.innerHTML = '<b>' + S2[i] + '%</b><span>' + (ago ? ago + 's ago' : 'now') + '</span>';
      tip.style.left = Math.max(40, Math.min(d.W - 40, X)) + 'px'; tip.style.top = Y + 'px'; tip.classList.add('on');
    });
    host.addEventListener('pointerleave', () => {
      const cr = $('#cr-' + key), hd = $('#hd-' + key); if (cr) cr.style.display = 'none'; if (hd) hd.style.display = 'none';
      $('.tip', host).classList.remove('on');
    });
  }
}

function setGauge(id, v) {
  const g = $('#' + id); if (!g) return;
  const C = 276.46;
  $('.val', g).style.strokeDashoffset = (C * (1 - Math.max(0, Math.min(100, v)) / 100)).toFixed(1);
  g.classList.toggle('warn', v >= 70 && v < 90); g.classList.toggle('bad', v >= 90);
  $('b', g).textContent = Math.round(v) + '%';
}
function updateLive() {
  const m = S.metrics; if (!m || S.view !== 'dashboard') return;
  setGauge('gCpu', m.cpu); setGauge('gRam', m.ram);
  const a = $('#sv-cpu'), b = $('#sv-ram');
  if (a) a.innerHTML = m.cpu + '<small>%</small>'; if (b) b.innerHTML = m.ram + '<small>%</small>';
  const up = $('#kvUp'); if (up) up.textContent = fmtUptime(m.uptimeSec || 0);
  const pl = $('#kvPlan'); if (pl && m.plan) pl.textContent = m.plan;
  drawSpark('cpu'); drawSpark('ram');
}

/* ---- tweak pages */
function tcardHTML(id, i, featured) {
  const c = CATALOG[id], sys = (S.state && S.state.sys) || {};
  const isRestore = id.indexOf('restore') === 0 || id === 'forget_originals';
  const offVendor = c.vendor && sys.gpuVendor && sys.gpuVendor !== c.vendor;
  const applied = S.applied[id];
  const btnCls = c.risk === 'danger' ? 'btn danger small' : 'btn primary small';
  let extra = '';
  if (id === 'gpu_auto') extra = '<div class="t-note">' + icon('monitor') + ' Detected: ' + esc(((sys.gpu || []).join(' / ')) || 'unknown') + '</div>';
  const sec = (c.risk === 'security' || c.risk === 'danger') ? ' sec' : '';
  const label = id === 'forget_originals' ? 'Forget' : (isRestore ? 'Restore' : 'Apply');
  return `<article class="card tcard tilt rise${sec} ${featured ? 'featured' : ''} ${offVendor ? 'dim' : ''}" style="--i:${i}" data-id="${id}">
    <div class="t-main">
      <div class="t-top"><div class="t-ic">${icon(c.icon)}</div><div class="t-title">${esc(c.title)}</div></div>
      <p class="t-desc">${esc(c.short)}</p>
      ${c.tags ? '<div class="t-tags">' + c.tags.map(t => '<span>' + esc(t) + '</span>').join('') + '</div>' : ''}
      ${extra}
    </div>
    <div class="t-foot">
      ${offVendor ? '<span class="chip">Not detected</span>' : '<span class="chip risk-' + c.risk + '">' + RISK[c.risk].label + '</span>'}
      ${applied ? '<span class="applied">' + icon('check') + 'Applied</span>' : ''}
      <span class="grow"></span>
      <button class="btn ghost small" data-act="open" data-id="${id}" data-info="1">Details</button>
      <button class="${btnCls}" data-act="open" data-id="${id}">${label}</button>
    </div>
  </article>`;
}
function viewPage(w, id) {
  const ids = PAGES[id] || [], feat = FEATURED[id];
  const st = S.state;
  let tools = '';
  if (id === 'services' && st) tools = '<div class="page-tools">' + icon('info') + '<span>' + st.backup.services + ' service start types saved. Advanced always keeps SamSs, Themes, TokenBroker and Defender.</span></div>';
  if (id === 'expert') tools = '<div class="page-tools">' + icon('alert') + '<span>These options reduce security or remove features. Each one asks you to hold the button to confirm.</span></div>';
  w.innerHTML = tools + '<div class="grid">' + ids.map((x, i) => tcardHTML(x, i, x === feat)).join('') + '</div>';
}
function viewRestore(w) {
  const b = (S.state && S.state.backup) || { services: 0, regKeys: 0, regValues: 0, tasks: 0, plans: 0, hasBaseline: false };
  const tile = (t, n, l, i) => `<section class="card tile rise" style="--i:${i}"><div class="tile-head">${t}</div><div class="num" data-count="${n}">0</div><div class="lbl">${l}</div></section>`;
  const ids = PAGES.restore;
  w.innerHTML = `<div class="rest-grid">${tile('Services', b.services, 'saved start types', 0)}${tile('Registry keys', b.regKeys, 'exported', 1)}${tile('Tasks', b.tasks, 'recorded', 2)}${tile('Power plans', b.plans, 'exported', 3)}</div>
    ${b.hasBaseline ? '' : '<div class="page-tools">' + icon('info') + '<span>No saved originals yet. They are created the first time you apply a tweak.</span></div>'}
    <div class="grid">${ids.map((x, i) => tcardHTML(x, i + 4, x === FEATURED.restore)).join('')}</div>`;
  $$('[data-count]', w).forEach((el, i) => setTimeout(() => countTo(el, Number(el.dataset.count), 800), 200 + i * 80));
}
function viewSettings(w) {
  const sys = (S.state && S.state.sys) || {};
  const sw = [['green', '#00e676'], ['cyan', '#22d3ee'], ['violet', '#a78bfa'], ['amber', '#fbbf24'], ['rose', '#fb7185']];
  w.innerHTML = `<div class="set-grid">
    <section class="card set-card rise" style="--i:0"><h3>Animations</h3><p>Reduced stops the moving background and hover effects. Off removes all motion. Animations also pause when this window is in the background.</p>
      <div class="seg" id="segAnim">${['full', 'reduced', 'off'].map(v => '<button type="button" data-v="' + v + '" class="' + (S.anim === v ? 'on' : '') + '">' + v[0].toUpperCase() + v.slice(1) + '</button>').join('')}</div></section>
    <section class="card set-card rise" style="--i:1"><h3>Accent color</h3>
      <div class="swatches" id="swatches">${sw.map(s => '<button type="button" class="sw ' + (S.accent === s[0] ? 'on' : '') + '" data-v="' + s[0] + '" style="background:' + s[1] + ';color:' + s[1] + '" aria-label="' + s[0] + '"></button>').join('')}</div></section>
    <section class="card set-card rise" style="--i:2"><h3>About</h3>
      <div class="kv"><div><span>Version</span><span>Jiff Tweaks V${esc((S.state && S.state.version) || '9')}</span></div>
      <div><span>Computer</span><span>${esc(sys.host || '-')}</span></div>
      <div><span>Saved data</span><span>C:\\JiffTweaks</span></div>
      <div><span>Network use</span><span>None, except the optional wallpaper download in Branding</span></div></div>
      <div><button class="btn ghost" id="btnQuit">Quit Jiff Tweaks</button></div></section>
  </div>`;
  $('#segAnim', w).addEventListener('click', e => { const b = e.target.closest('button'); if (!b) return; applyAnim(b.dataset.v); $$('#segAnim button', w).forEach(x => x.classList.toggle('on', x === b)); });
  $('#swatches', w).addEventListener('click', e => { const b = e.target.closest('button'); if (!b) return; applyAccent(b.dataset.v); $$('#swatches .sw', w).forEach(x => x.classList.toggle('on', x === b)); });
  $('#btnQuit', w).addEventListener('click', async () => { try { await post('/api/quit'); } catch (e) { /* ignore */ } offline('Jiff Tweaks has closed. You can close this window.'); });
}

/* ---- logs */
function parseLine(raw) {
  const m = /^\[\s*([^\]]*)\]\s+\[([^\]]+)\]\s?(.*)$/.exec(raw);
  if (!m) return { time: '', tag: '', msg: raw, cls: 'info' };
  const tag = m[2].trim(), t = tag.toUpperCase();
  let cls = 'info';
  if (t === 'STEP') cls = 'step'; else if (t === 'DONE') cls = 'done';
  else if (t.indexOf('OK') === 0) cls = 'ok';
  else if (t.indexOf('FAIL') === 0 || t === 'ERROR') cls = 'fail';
  else if (t.indexOf('SKIP') === 0 || t === 'BK-SKIP') cls = 'skip';
  let label = t; if (cls === 'ok') label = 'OK'; else if (cls === 'fail') label = 'FAIL'; else if (cls === 'skip') label = 'SKIP';
  return { time: m[1].trim(), tag: label, msg: m[3], cls: cls };
}
function lineEl(raw) {
  const p = parseLine(raw), d = document.createElement('div');
  d.className = 'ln ' + p.cls;
  d.innerHTML = '<span class="tg">' + esc(p.tag || 'LOG') + '</span><span class="tx">' + esc(p.msg) + '</span>';
  return d;
}
async function viewLogs(w) {
  w.innerHTML = '<div class="logs-wrap"><div class="card log-list" id="logList"></div><div class="card log-view"><div class="term" id="logTerm"></div></div></div>';
  let list = [];
  try { list = (await api('/api/logs')).logs; } catch (e) { /* ignore */ }
  const el = $('#logList');
  if (!list.length) { el.innerHTML = '<div class="empty">' + icon('file') + '<b>No logs yet</b><span>Run any action and its log appears here.</span></div>'; $('#logTerm').innerHTML = ''; return; }
  el.innerHTML = list.map(l => '<button class="log-item" data-name="' + esc(l.name) + '"><b>' + esc(l.name.replace(/^gui_|\.log$/g, '')) + '</b><span>' + esc(l.time.replace('T', ' ')) + ' &middot; ' + Math.max(1, Math.round(l.size / 1024)) + ' KB</span></button>').join('');
  const open = async name => {
    $$('.log-item', el).forEach(b => b.classList.toggle('active', b.dataset.name === name));
    const t = $('#logTerm'); t.innerHTML = '';
    try {
      const d = await api('/api/log?name=' + encodeURIComponent(name));
      const f = document.createDocumentFragment(); d.lines.forEach(l => { const e = lineEl(l); e.style.animation = 'none'; f.appendChild(e); }); t.appendChild(f); t.scrollTop = t.scrollHeight;
    } catch (e) { t.textContent = 'Could not read this log.'; }
  };
  el.addEventListener('click', e => { const b = e.target.closest('.log-item'); if (b) open(b.dataset.name); });
  const pick = S.pendingLog && list.find(l => l.name === S.pendingLog) ? S.pendingLog : list[0].name; S.pendingLog = null;
  open(pick);
}

/* ---------------------------------------------------------------- top bar / banners */
function renderTopRight() {
  const t = $('#topRight'); let h = '';
  if (S.run && S.run.running && !$('#drawer').classList.contains('open')) h += '<button class="chip accent" id="chipRun" type="button"><span class="live-dot"></span>Running ' + esc(CATALOG[S.run.id].title) + '</button>';
  if (S.needReboot) h += '<button class="chip warn" id="chipReboot" type="button">' + icon('refresh') + 'Restart required</button>';
  t.innerHTML = h;
  const r = $('#chipRun'); if (r) r.onclick = openDrawer;
  const b = $('#chipReboot'); if (b) b.onclick = rebootConfirm;
}
function renderBanners() {
  const st = S.state, bn = $('#banners'); let h = '';
  if (st && !st.admin) h += '<div class="banner bad">' + icon('alert') + '<span>Not running as administrator. Tweaks will fail. Close this window and start <b>Jiff Tweaks.bat</b> again.</span></div>';
  if (st && !st.engine) h += '<div class="banner bad">' + icon('alert') + '<span>The engine file is missing. Keep the <b>engine</b> folder next to the <b>app</b> folder.</span></div>';
  bn.innerHTML = h;
  const ac = $('#adminChip');
  ac.className = 'chip ' + (st && st.admin ? 'ok' : 'bad');
  ac.innerHTML = icon(st && st.admin ? 'shield' : 'alert') + '<span>' + (st && st.admin ? 'Administrator' : 'Not elevated') + '</span>';
}

/* ---------------------------------------------------------------- modal */
function modal(inner, cls) {
  const root = $('#modalRoot');
  const back = document.createElement('div'); back.className = 'back';
  back.innerHTML = '<div class="modal ' + (cls || '') + '" role="dialog" aria-modal="true">' + inner + '</div>';
  root.appendChild(back);
  const close = () => { back.style.transition = 'opacity .2s'; back.style.opacity = '0'; setTimeout(() => back.remove(), 200); document.removeEventListener('keydown', onKey); };
  const onKey = e => { if (e.key === 'Escape') close(); };
  document.addEventListener('keydown', onKey);
  back.addEventListener('mousedown', e => { if (e.target === back) close(); });
  return { el: back, close };
}

function holdButton(btn, ms, done) {
  let t0 = 0, raf = 0, active = false;
  const tick = t => { if (!active) return; const p = Math.min(1, (t - t0) / ms); btn.style.setProperty('--p', p); if (p >= 1) { active = false; done(); } else raf = requestAnimationFrame(tick); };
  const start = () => { if (active) return; active = true; t0 = performance.now(); raf = requestAnimationFrame(tick); };
  const stop = () => { active = false; cancelAnimationFrame(raf); btn.style.setProperty('--p', 0); };
  btn.addEventListener('pointerdown', start); ['pointerup', 'pointerleave', 'pointercancel', 'blur'].forEach(ev => btn.addEventListener(ev, stop));
  btn.addEventListener('keydown', e => { if ((e.key === ' ' || e.key === 'Enter') && !e.repeat) { e.preventDefault(); start(); } });
  btn.addEventListener('keyup', e => { if (e.key === ' ' || e.key === 'Enter') stop(); });
}

function confirmAction(id) {
  const c = CATALOG[id], isRestore = id.indexOf('restore') === 0;
  const hold = c.risk === 'aggressive' || c.risk === 'security' || c.risk === 'danger';
  const sec = c.risk === 'security' || c.risk === 'danger';
  const warn = (c.note ? '<div class="m-warn ' + (sec ? 'bad' : '') + '">' + icon('alert') + '<span>' + esc(c.note) + '</span></div>' : '') +
    (c.risk === 'aggressive' && !c.note ? '<div class="m-warn">' + icon('alert') + '<span>' + esc(RISK.aggressive.note) + '</span></div>' : '');
  const foot = (c.reboot ? 'Restart required afterward. ' : '') + (!isRestore && c.risk !== 'danger' ? 'Originals are saved first.' : '');
  const m = modal(`
    <div class="m-head"><div class="t-ic">${icon(c.icon)}</div><div><h3>${esc(c.title)}</h3><p>${esc(c.short)}</p></div><span class="chip risk-${c.risk}" style="margin-left:auto">${RISK[c.risk].label}</span></div>
    <ul class="m-list">${c.does.map(x => '<li>' + icon('check') + '<span>' + esc(x) + '</span></li>').join('')}</ul>
    ${warn}
    ${foot ? '<div class="t-note">' + icon('info') + esc(foot) + '</div>' : ''}
    <div class="m-foot"><button class="btn ghost" id="mCancel" type="button">Cancel</button>
      ${hold ? '<button class="btn ' + (sec ? 'danger' : 'primary') + ' hold" id="mGo" type="button"><i class="fill"></i><span>Hold to ' + (isRestore ? 'confirm' : 'apply') + '</span></button>'
             : '<button class="btn primary" id="mGo" type="button">' + (isRestore ? 'Restore' : 'Apply') + '</button>'}</div>`, sec ? 'sec' : '');
  $('#mCancel', m.el).onclick = m.close;
  const go = $('#mGo', m.el);
  if (hold) holdButton(go, 1100, () => { m.close(); startRun(id); });
  else go.onclick = () => { m.close(); startRun(id); };
  go.focus();
}
function rebootConfirm() {
  const m = modal(`<div class="m-head"><div class="t-ic">${icon('refresh')}</div><div><h3>Restart now?</h3><p>Windows restarts about 8 seconds after you confirm. Save your work first.</p></div></div>
    <div class="m-foot"><button class="btn ghost" id="mCancel">Later</button><button class="btn warn" id="mGo">Restart</button></div>`);
  $('#mCancel', m.el).onclick = m.close;
  $('#mGo', m.el).onclick = async () => { m.close(); try { await post('/api/reboot'); toast('Restarting', 'Windows restarts in a few seconds.'); } catch (e) { toast('Could not restart', e.message, 'bad'); } };
}

/* ---------------------------------------------------------------- run drawer */
function resetDrawer(id) {
  const c = CATALOG[id];
  $('#dwTitle').textContent = c.title; $('#dwKicker').textContent = 'Running'; $('#dwKicker').className = 'dw-kicker';
  $('#dwStep').textContent = 'Starting...'; $('#term').innerHTML = ''; $('#dwSummary').innerHTML = '';
  ['cOk', 'cSkip', 'cFail'].forEach(x => $('#' + x).textContent = '0'); $('#cTime').textContent = '0:00';
  const ring = $('.dw-ring'); ring.className = 'dw-ring'; $('#dwPct').textContent = '0';
  $('#dwArc').style.strokeDashoffset = '276.46';
  if (c.steps) ring.classList.remove('spin'); else ring.classList.add('spin');
  $('#dwCheck').innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"/></svg>';
  $('#dwSteps').innerHTML = c.steps ? STEP_NAMES.map((n, i) => '<span class="stp" data-i="' + (i + 1) + '"><i></i>' + esc(n) + '</span>').join('') : '';
  $('#dwStop').hidden = false; $('#dwStop').disabled = false; $('#dwReboot').hidden = true; $('#dwClose').hidden = true; $('#dwLog').hidden = true;
}
function openDrawer() { const d = $('#drawer'); d.classList.add('open'); d.setAttribute('aria-hidden', 'false'); renderTopRight(); }
function closeDrawer() { const d = $('#drawer'); d.classList.remove('open'); d.setAttribute('aria-hidden', 'true'); renderTopRight(); }

async function startRun(id) {
  if (S.run && S.run.running) { toast('Busy', 'Another action is still running.', 'bad'); openDrawer(); return; }
  let r;
  try { r = await post('/api/run', { action: id }); }
  catch (e) { toast('Could not start', e.message, 'bad'); return; }
  S.run = { id, runId: r.id, running: true, from: 0, ok: 0, skip: 0, fail: 0, step: 0, total: CATALOG[id].steps || 0, t0: Date.now() };
  resetDrawer(id); openDrawer();
  S.tickTimer = setInterval(() => { if (S.run) $('#cTime').textContent = fmtTime((Date.now() - S.run.t0) / 1000); }, 500);
  poll();
}
function setProgress(p) {
  const ring = $('.dw-ring'); ring.classList.remove('spin');
  $('#dwArc').style.strokeDashoffset = (276.46 * (1 - p / 100)).toFixed(1); $('#dwPct').textContent = Math.round(p);
}
function addLines(lines) {
  const term = $('#term'), run = S.run, near = term.scrollHeight - term.scrollTop - term.clientHeight < 60;
  const f = document.createDocumentFragment();
  lines.forEach(raw => {
    const p = parseLine(raw);
    if (p.cls === 'ok') run.ok++; else if (p.cls === 'skip') run.skip++; else if (p.cls === 'fail') run.fail++;
    if (p.cls === 'step') {
      const m = /^(\d+)\/(\d+)\s+(.*)$/.exec(p.msg);
      if (m) { run.step = Number(m[1]); run.total = Number(m[2]); $('#dwStep').textContent = 'Step ' + m[1] + ' of ' + m[2] + ': ' + m[3];
        setProgress((run.step - 1) / run.total * 100);
        $$('.stp').forEach(s => { const i = Number(s.dataset.i); s.classList.toggle('done', i < run.step); s.classList.toggle('cur', i === run.step); }); }
    } else if (p.cls === 'ok' && !run.total) { $('#dwStep').textContent = p.msg ? p.msg.slice(0, 60) : 'Working...'; }
    if (p.tag === 'ACTION' || p.tag === 'INIT') return; // keep the console focused on changes
    f.appendChild(lineEl(raw));
  });
  term.appendChild(f);
  while (term.childElementCount > 1500) term.removeChild(term.firstChild);
  if (near) term.scrollTop = term.scrollHeight;
  $('#cOk').textContent = run.ok; $('#cSkip').textContent = run.skip; $('#cFail').textContent = run.fail;
}
async function poll() {
  const run = S.run; if (!run) return;
  let d;
  try { d = await api('/api/run?id=' + encodeURIComponent(run.runId) + '&from=' + run.from); }
  catch (e) { if (e.status === 404) { finishRun('failed', null); return; } S.pollTimer = setTimeout(poll, 800); return; }
  if (d.lines && d.lines.length) { addLines(d.lines); run.from = d.next; }
  if (d.status === 'running') { S.pollTimer = setTimeout(poll, 320); return; }
  finishRun(d.status, d);
}
function finishRun(status, d) {
  const run = S.run; clearInterval(S.tickTimer);
  run.running = false; run.status = status;
  const c = CATALOG[run.id], ring = $('.dw-ring'), kick = $('#dwKicker');
  const secs = (Date.now() - run.t0) / 1000;
  ring.classList.remove('spin');
  $('#dwStop').hidden = true; $('#dwClose').hidden = false; $('#dwLog').hidden = false;
  $('#dwStep').textContent = 'Finished in ' + fmtTime(secs);
  if (status === 'done') {
    setProgress(100); setTimeout(() => ring.classList.add('fin'), 350);
    kick.textContent = run.fail ? 'Completed with ' + run.fail + ' item' + (run.fail > 1 ? 's' : '') + ' not changed' : 'Completed'; kick.className = 'dw-kicker done';
    $$('.stp').forEach(s => { s.classList.remove('cur'); s.classList.add('done'); });
    markApplied(run.id);
    if (c.reboot) { S.needReboot = true; $('#dwReboot').hidden = false; }
    toast(c.title, run.fail ? 'Done. ' + run.fail + ' item(s) could not be changed (see log).' : 'Done in ' + fmtTime(secs) + '.');
  } else if (status === 'cancelled') {
    kick.textContent = 'Stopped'; kick.className = 'dw-kicker fail'; ring.classList.add('fail');
    $('#dwStep').textContent = 'Stopped before it finished. Some changes may already be applied.';
  } else if (status === 'noadmin') {
    kick.textContent = 'Needs administrator'; kick.className = 'dw-kicker fail'; ring.classList.add('fail', 'fin');
    $('#dwCheck').innerHTML = icon('x'); $('#dwStep').textContent = 'Close this window and start Jiff Tweaks.bat again.';
  } else {
    kick.textContent = 'Did not finish'; kick.className = 'dw-kicker fail'; ring.classList.add('fail', 'fin');
    $('#dwCheck').innerHTML = icon('x'); $('#dwStep').textContent = 'Something stopped the engine. Open the full log for details.';
  }
  if (d && d.summary && d.summary.length) $('#dwSummary').innerHTML = d.summary.map(x => '<div>' + icon('arrow') + '<span>' + esc(x) + '</span></div>').join('');
  refreshState().then(() => { if (S.view === 'dashboard' || S.view === 'restore' || PAGES[S.view]) go(S.view); });
  renderTopRight();
}

/* ---------------------------------------------------------------- state / live */
async function refreshState() {
  try { S.state = await api('/api/state'); renderBanners(); } catch (e) { /* ignore */ }
}
async function pollMetrics() {
  if (document.hidden) return;
  try {
    const m = await api('/api/metrics'); S.metrics = m;
    S.cpu.push(m.cpu); S.ram.push(m.ram);
    if (S.cpu.length > SAMPLES) S.cpu.shift(); if (S.ram.length > SAMPLES) S.ram.shift();
    updateLive();
  } catch (e) { /* ignore */ }
}
function offline(msg) {
  S.online = false; $('.live-dot', $('.side-foot')).classList.add('off'); $('#connLabel').textContent = 'Disconnected';
  const m = modal('<div class="m-head"><div class="t-ic">' + icon('alert') + '</div><div><h3>Connection lost</h3><p>' + esc(msg || 'The Jiff Tweaks service stopped. Close this window and start Jiff Tweaks.bat again.') + '</p></div></div>', 'sec');
  m.el.onmousedown = null;
}
async function heartbeat() {
  try { await post('/api/ping'); S.fails = 0; }
  catch (e) { if (e.status === 401 || ++S.fails >= 3) { if (S.online) offline(); } }
}

/* ---------------------------------------------------------------- pointer fx */
let fxRaf = 0;
function pointerFx(e) {
  const card = e.target.closest && e.target.closest('.card'); if (!card) return;
  if (fxRaf) return;
  fxRaf = requestAnimationFrame(() => {
    fxRaf = 0;
    const r = card.getBoundingClientRect(), x = e.clientX - r.left, y = e.clientY - r.top;
    card.style.setProperty('--mx', x + 'px'); card.style.setProperty('--my', y + 'px');
    if (html.dataset.anim === 'full' && card.classList.contains('tilt') && !card.classList.contains('featured')) {
      const rx = ((y / r.height) - .5) * -5, ry = ((x / r.width) - .5) * 6;
      card.style.transform = 'perspective(900px) rotateX(' + rx.toFixed(2) + 'deg) rotateY(' + ry.toFixed(2) + 'deg) translateY(-2px)';
    }
  });
}
function pointerReset(e) { const c = e.target.closest && e.target.closest('.card.tilt'); if (c && !c.contains(e.relatedTarget)) c.style.transform = ''; }

/* ---------------------------------------------------------------- init */
function wire() {
  document.addEventListener('click', ripple, true);
  $('#view').addEventListener('pointermove', pointerFx);
  $('#view').addEventListener('pointerout', pointerReset);
  $('#view').addEventListener('click', e => {
    const o = e.target.closest('[data-act="open"]'); if (o) { confirmAction(o.dataset.id); return; }
    const g = e.target.closest('[data-go]'); if (g) go(g.dataset.go);
  });
  $('#dwStop').onclick = async () => { $('#dwStop').disabled = true; try { await post('/api/cancel'); } catch (e) { /* ignore */ } };
  $('#dwClose').onclick = closeDrawer;
  $('#dwReboot').onclick = rebootConfirm;
  $('#dwLog').onclick = () => { S.pendingLog = 'gui_' + S.run.runId + '.log'; closeDrawer(); go('logs'); };
  $('#drawer .scrim').addEventListener('click', () => { closeDrawer(); });
  document.addEventListener('keydown', e => { if (e.key === 'Escape' && !$('#modalRoot').childElementCount) closeDrawer(); });
  const pause = () => html.classList.toggle('paused', document.hidden || !document.hasFocus());
  document.addEventListener('visibilitychange', pause); window.addEventListener('blur', pause); window.addEventListener('focus', pause);
  window.addEventListener('resize', () => { movePill(); drawSpark('cpu'); drawSpark('ram'); });
  window.addEventListener('pagehide', () => { try { navigator.sendBeacon('/api/bye', new Blob(['{}'], { type: 'application/json' })); } catch (e) { /* ignore */ } });
}

async function init() {
  loadSettings(); buildNav(); wire(); splash();
  await refreshState();
  go('dashboard');
  pollMetrics(); setInterval(pollMetrics, 2000);
  heartbeat(); setInterval(heartbeat, 4000);
  // after fonts/layout settle
  setTimeout(movePill, 60);
}
init();
})();
