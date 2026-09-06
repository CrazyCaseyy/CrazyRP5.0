// NUI contract with client.lua — see resources/[crazy]/crazy-adminmenu/client/client.lua
// inbound (SendNUIMessage):  { action: 'open' | 'close' | 'toggleState' }
// outbound (RegisterNUICallback): close, getPlayers, getPlayerDetail, getDashboardStats, getPlayerHistory,
//   getJobsAndGangs, playerGeneral, playerAdmin, changePlayerData, clothingMenu, giveItem, removePlayerItem,
//   getPlayerInventory, toggleSelf, setPedModel, refreshPedModel, getToggleState,
//   getVehicles, spawnVehicle, fixVehicle, deleteVehicle, adminCar, setPlate, setWeather,
//   setTime, getRadioList, pullStash, copyToClipboard, copyText, getReports, replyReport,
//   closeReport, getBans, unban, searchCharacters, getCharacterDetail, openCharacterInventory

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-adminmenu';
}

async function post(name, data = {}) {
  try {
    const resp = await fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
    return await resp.json();
  } catch (e) {
    return null;
  }
}

const el = (id) => document.getElementById(id);
const app = el('app');

// ===================================================================
// Toasts
// ===================================================================

function showToast(message, kind = 'success') {
  const container = el('toasts');
  const toast = document.createElement('div');
  toast.className = `toast ${kind}`;
  toast.textContent = message;
  container.appendChild(toast);
  requestAnimationFrame(() => toast.classList.add('show'));
  setTimeout(() => {
    toast.classList.remove('show');
    setTimeout(() => toast.remove(), 250);
  }, 2600);
}

// ===================================================================
// Tabs
// ===================================================================

const TAB_META = {
  dashboard: { title: 'Dashboard', subtitle: 'Server overview' },
  players: { title: 'Players', subtitle: 'Manage the current online playerbase' },
  self: { title: 'Self Tools', subtitle: 'Options that only affect you' },
  vehicles: { title: 'Vehicles', subtitle: 'Spawn, fix, delete and manage vehicles' },
  server: { title: 'Server', subtitle: 'Weather, time, radio and stash lookups' },
  dev: { title: 'Dev Tools', subtitle: 'Handy things for developers' },
  reports: { title: 'Reports', subtitle: 'Pending player reports' },
  bans: { title: 'Ban Logs', subtitle: 'Reason and duration for every ban on record' },
  characters: { title: 'Characters', subtitle: 'Look up any character in the database, online or not' },
};

let currentTab = 'dashboard';

function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.nav-item').forEach((n) => n.classList.toggle('active', n.dataset.tab === tab));
  document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('hidden', p.dataset.panel !== tab));
  el('topbarTitle').textContent = TAB_META[tab].title;
  el('topbarSubtitle').textContent = TAB_META[tab].subtitle;

  if (tab === 'dashboard') loadDashboard();
  else if (tab === 'players') { showPlayersList(); loadPlayers(); }
  else if (tab === 'vehicles' && !vehicleData) loadVehicles();
  else if (tab === 'reports') loadReports();
  else if (tab === 'bans') loadBans();
}

document.querySelectorAll('.nav-item').forEach((item) => {
  item.addEventListener('click', () => switchTab(item.dataset.tab));
});

// ===================================================================
// Open / close
// ===================================================================

function openApp() {
  app.classList.add('open');
  switchTab('dashboard');
  post('getToggleState');
}

function closeApp() {
  app.classList.remove('open');
  selectedPlayerId = null;
}

el('closeBtn').addEventListener('click', () => { post('close'); closeApp(); });

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && app.classList.contains('open')) {
    post('close');
    closeApp();
  }
});

window.addEventListener('message', (e) => {
  const data = e.data || {};
  if (data.action === 'open') openApp();
  else if (data.action === 'close') closeApp();
  else if (data.action === 'toggleState') applyToggleState(data.state || {});
});

// ===================================================================
// Toggle state (self tools + dev overlays)
// ===================================================================

const SELF_TOGGLE_TILES = [
  { action: 'noclip', label: 'Noclip' },
  { action: 'godmode', label: 'Godmode' },
  { action: 'invisible', label: 'Invisible' },
  { action: 'vehicleGodmode', label: 'Vehicle Godmode' },
  { action: 'infiniteAmmo', label: 'Infinite Ammo' },
  { action: 'names', label: 'Player Names' },
  { action: 'blips', label: 'Player Blips' },
];

const DEV_TOGGLE_TILES = [
  { action: 'coords', label: 'Coords Overlay' },
  { action: 'vehicleInfo', label: 'Vehicle Info Overlay' },
  { action: 'laser', label: 'Laser Pointer' },
];

function buildToggleTile(def) {
  const tile = document.createElement('div');
  tile.className = 'toggle-tile';
  tile.dataset.action = def.action;
  tile.innerHTML = `<span class="tile-label">${def.label}</span>`;
  tile.addEventListener('click', async () => {
    // Flip immediately rather than waiting on the round trip - the Lua
    // side's toggle fires inside a CreateThread (so the NUI callback that
    // reports state back doesn't block on it forever), which races with
    // that state report and used to leave the tile showing the old state
    // until the menu was closed and reopened. These are simple booleans
    // that always succeed, so flipping optimistically here is safe; the
    // next real toggleState push (menu reopen, another toggle) still wins
    // if it ever disagrees.
    tile.classList.toggle('active');
    tile.style.opacity = '0.6';
    await post('toggleSelf', { action: def.action });
    tile.style.opacity = '1';
  });
  return tile;
}

function initToggleGrids() {
  const selfGrid = el('selfToggleGrid');
  SELF_TOGGLE_TILES.forEach((def) => selfGrid.appendChild(buildToggleTile(def)));

  const devGrid = el('devToggleGrid');
  DEV_TOGGLE_TILES.forEach((def) => devGrid.appendChild(buildToggleTile(def)));
}

function applyToggleState(state) {
  // Skip revive/cuff — they're momentary action chips (labelled
  // "Instant") that happen to reuse .toggle-tile for matching visuals,
  // not real tracked toggles state has a key for.
  document.querySelectorAll('.toggle-tile:not(.instant-tile)').forEach((tile) => {
    tile.classList.toggle('active', !!state[tile.dataset.action]);
  });
}

// Revive / cuff are momentary actions, not tracked toggles — added as
// plain action chips inside initSelfExtras() below rather than the grid.
function initSelfExtras() {
  const modelBtn = el('applyPedModelBtn');
  modelBtn.addEventListener('click', async () => {
    const model = el('pedModelInput').value.trim();
    if (!model) return;
    await post('setPedModel', { model });
    showToast('Ped model applied');
  });

  el('resetPedModelBtn').addEventListener('click', async () => {
    await post('refreshPedModel');
    showToast('Ped model reset');
  });

  // Revive + cuff live in the self toggle grid area as plain action chips.
  const selfGrid = el('selfToggleGrid');
  const reviveBtn = document.createElement('button');
  reviveBtn.className = 'toggle-tile instant-tile';
  reviveBtn.style.cursor = 'pointer';
  reviveBtn.innerHTML = `<span class="tile-label">Revive Yourself</span>`;
  reviveBtn.addEventListener('click', async () => { await post('toggleSelf', { action: 'revive' }); showToast('Revived'); });
  selfGrid.appendChild(reviveBtn);

  const cuffBtn = document.createElement('button');
  cuffBtn.className = 'toggle-tile instant-tile';
  cuffBtn.style.cursor = 'pointer';
  cuffBtn.innerHTML = `<span class="tile-label">Cuff / Uncuff</span>`;
  cuffBtn.addEventListener('click', async () => { await post('toggleSelf', { action: 'cuff' }); });
  selfGrid.appendChild(cuffBtn);

  document.querySelectorAll('[data-copy]').forEach((btn) => {
    btn.addEventListener('click', async () => {
      await post('copyToClipboard', { kind: btn.dataset.copy });
    });
  });
}

// ===================================================================
// Players
// ===================================================================

let players = [];
let selectedPlayerId = null;

async function loadPlayers() {
  const result = await post('getPlayers');
  players = Array.isArray(result) ? result : [];
  renderPlayersList(players);
  // Tallied locally from the list just fetched instead of firing a second
  // callback that would re-loop every online player on the server just to
  // recompute what getPlayers already carries per-row (see `onduty` on
  // server/admin.lua's getPlayers).
  renderJobCounts('dutySummary', computeJobCounts(players));
}

// getPlayers' job field is qbx_adminmenu's own flattened "Label | Grade"
// string (server/main.lua) - just the label half is useful as a quick
// badge on each row, the grade number isn't meaningful without more
// context than fits here.
function jobLabelOf(p) {
  return (p.job || '').split('|')[0].trim();
}

function computeJobCounts(list) {
  const counts = {};
  for (const p of list) {
    if (!p.onduty) continue;
    const label = jobLabelOf(p);
    if (!label) continue;
    counts[label] = (counts[label] || 0) + 1;
  }
  return Object.entries(counts)
    .map(([label, count]) => ({ label, count }))
    .sort((a, b) => (b.count - a.count) || a.label.localeCompare(b.label));
}

function renderJobCounts(containerId, counts) {
  const container = el(containerId);
  if (!Array.isArray(counts) || !counts.length) {
    container.innerHTML = '<div class="duty-empty">Nobody is on duty right now.</div>';
    return;
  }
  container.innerHTML = counts.map((c) => `
    <div class="duty-chip">
      <span class="duty-count">${Number(c.count) || 0}</span>
      <span class="duty-label">${escapeHtml(c.label)}</span>
    </div>
  `).join('');
}

// ===================================================================
// Dashboard (landing screen)
// ===================================================================

async function loadDashboard() {
  const countEl = el('dashboardPlayerCount');
  countEl.textContent = '—';
  // One bundled callback (server/server.lua's getDashboardStats) instead of
  // fetching the full per-player getPlayers payload just to read its
  // length - that endpoint builds ~15 fields per player (several native
  // identifier lookups included) purely so this page could throw all of
  // it away but the count.
  const stats = await post('getDashboardStats');
  countEl.textContent = stats && typeof stats.playerCount === 'number' ? stats.playerCount : '0';
  renderJobCounts('dashboardDutySummary', stats ? stats.jobCounts : []);
  loadPlayerHistoryChart();
}

// Server samples the online player count every 15 minutes (see
// server/server.lua) and keeps the last 48h - plotted here by index rather
// than by parsing each row's actual timestamp, since the samples are
// already evenly spaced across that fixed window (the axis labels below
// the chart are static text for the same reason: 48h ago / 24h ago / now
// always lines up with the first/middle/last point).
async function loadPlayerHistoryChart() {
  const svg = el('playerHistoryChart');
  const emptyState = el('playerHistoryEmpty');
  const rows = await post('getPlayerHistory');

  if (!Array.isArray(rows) || rows.length < 2) {
    svg.innerHTML = '';
    emptyState.classList.remove('hidden');
    return;
  }
  emptyState.classList.add('hidden');

  const width = 600, height = 160, padX = 6, padY = 10;
  const counts = rows.map((r) => Number(r.player_count) || 0);
  const maxCount = Math.max(...counts, 1);
  const stepX = (width - padX * 2) / (rows.length - 1);

  const points = counts.map((c, i) => [
    padX + i * stepX,
    height - padY - (c / maxCount) * (height - padY * 2),
  ]);

  const linePath = points.map(([x, y], i) => `${i === 0 ? 'M' : 'L'} ${x.toFixed(1)} ${y.toFixed(1)}`).join(' ');
  const floorY = (height - padY).toFixed(1);
  const areaPath = `${linePath} L ${points[points.length - 1][0].toFixed(1)} ${floorY} L ${points[0][0].toFixed(1)} ${floorY} Z`;

  svg.innerHTML = `
    <defs>
      <linearGradient id="chartFill" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="rgba(21, 115, 237, 0.35)" />
        <stop offset="100%" stop-color="rgba(21, 115, 237, 0)" />
      </linearGradient>
    </defs>
    <path d="${areaPath}" fill="url(#chartFill)" stroke="none"></path>
    <path d="${linePath}" fill="none" stroke="#1573ed" stroke-width="2.5" stroke-linejoin="round" stroke-linecap="round"></path>
  `;
}

function renderPlayersList(list) {
  const container = el('playersList');
  const query = el('playerSearch').value.trim().toLowerCase();
  const filtered = query
    ? list.filter((p) => String(p.id).includes(query) || (p.name || '').toLowerCase().includes(query) || jobLabelOf(p).toLowerCase().includes(query))
    : list;

  if (!filtered.length) {
    container.innerHTML = '<div class="empty-state">No players found.</div>';
    return;
  }

  container.innerHTML = '';
  filtered.forEach((p) => {
    const row = document.createElement('div');
    row.className = 'player-row' + (String(p.id) === String(selectedPlayerId) ? ' selected' : '');
    const initials = (p.name || '?').trim().slice(0, 2).toUpperCase();
    const job = jobLabelOf(p);
    row.innerHTML = `
      <div class="player-avatar">${initials}</div>
      <div class="player-row-text">
        <div class="player-row-top">
          <span class="player-row-name">${escapeHtml(p.name || 'Unknown')}</span>
          <span class="player-row-id">#${p.id}</span>
        </div>
        <div class="player-row-meta">
          ${job ? `<span class="player-row-job">${escapeHtml(job)}</span>` : ''}
          <span class="player-row-cid">${escapeHtml(p.cid || '')}</span>
        </div>
      </div>
    `;
    row.addEventListener('click', () => selectPlayer(p.id));
    container.appendChild(row);
  });
}

el('playerSearch').addEventListener('input', () => renderPlayersList(players));

function escapeHtml(str) {
  return String(str).replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

const GENERAL_ACTIONS = [
  { action: 'kill', label: 'Kill' },
  { action: 'revive', label: 'Revive' },
  { action: 'freeze', label: 'Freeze/Unfreeze' },
  { action: 'goto_', label: 'Go To' },
  { action: 'bring', label: 'Bring' },
  { action: 'sit', label: 'Sit In Their Vehicle' },
];

const ADMIN_PERM_VALUES = [
  { value: 'remove', label: 'Remove' },
  { value: 'mod', label: 'Mod' },
  { value: 'admin', label: 'Admin' },
  { value: 'god', label: 'God' },
];

// Jobs/gangs list (name/label/maxGrade per entry) - fetched once and
// cached, since it's static config data that only changes on a resource
// restart. Lets the job/gang fields below be real <select> dropdowns
// (populated with every job/gang that actually exists) instead of a
// free-text box, with the grade input capped to however many grades that
// specific job/gang has.
let JOBS_LIST = [];
let GANGS_LIST = [];
let jobsGangsPromise = null;

function ensureJobsGangsLoaded() {
  if (!jobsGangsPromise) {
    jobsGangsPromise = post('getJobsAndGangs').then((data) => {
      JOBS_LIST = (data && data.jobs) || [];
      GANGS_LIST = (data && data.gangs) || [];
    });
  }
  return jobsGangsPromise;
}

// getValue pre-fills each input with the player's actual current value -
// safe to resubmit unchanged, since it's already in the exact shape
// changePlayerData expects (job/gang resolve the display label back to
// the real job/gang key via JOBS_LIST/GANGS_LIST so the dropdown can
// select the right option, rather than showing the label as if it were
// the key).
const DATA_FIELDS = [
  {
    field: 'name', label: 'Name', inputs: [{ type: 'text', placeholder: 'First' }, { type: 'text', placeholder: 'Last' }],
    getValue: (p) => {
      const [first, ...rest] = (p.name || '').split(' | (')[0].split(' ');
      return [first || '', rest.join(' ')];
    },
  },
  { field: 'food', label: 'Hunger %', inputs: [{ type: 'number', placeholder: '0-100' }], getValue: (p) => [p.food] },
  { field: 'thirst', label: 'Thirst %', inputs: [{ type: 'number', placeholder: '0-100' }], getValue: (p) => [p.water] },
  { field: 'stress', label: 'Stress %', inputs: [{ type: 'number', placeholder: '0-100' }], getValue: (p) => [p.stress] },
  { field: 'health', label: 'Health %', inputs: [{ type: 'number', placeholder: '0-100' }], getValue: (p) => [p.health] },
  { field: 'armor', label: 'Armor %', inputs: [{ type: 'number', placeholder: '0-100' }], getValue: (p) => [p.armor] },
  { field: 'phone', label: 'Phone', inputs: [{ type: 'text', placeholder: 'Number' }], getValue: (p) => [p.phone] },
  { field: 'crafting', label: 'Crafting Rep', inputs: [{ type: 'number', placeholder: '0' }], getValue: (p) => [p.craftingrep] },
  { field: 'dealer', label: 'Dealer Rep', inputs: [{ type: 'number', placeholder: '0' }], getValue: (p) => [p.dealerrep] },
  { field: 'cash', label: 'Cash', inputs: [{ type: 'number', placeholder: '0' }], getValue: (p) => [p.cash] },
  { field: 'bank', label: 'Bank', inputs: [{ type: 'number', placeholder: '0' }], getValue: (p) => [p.bank] },
  {
    field: 'job', label: 'Job', group: () => JOBS_LIST,
    inputs: [{ type: 'select' }, { type: 'number', placeholder: 'Grade' }],
    getValue: (p) => {
      const currentLabel = (p.job || '').split(' | ')[0].trim();
      const match = JOBS_LIST.find((j) => j.label === currentLabel);
      const grade = (p.job || '').split(' | ')[1];
      return [match ? match.name : '', grade || ''];
    },
  },
  {
    field: 'gang', label: 'Gang', group: () => GANGS_LIST,
    inputs: [{ type: 'select' }, { type: 'number', placeholder: 'Grade' }],
    getValue: (p) => {
      const match = GANGS_LIST.find((g) => g.label === (p.gang || '').trim());
      return [match ? match.name : '', ''];
    },
  },
  { field: 'radio', label: 'Radio Channel', inputs: [{ type: 'number', placeholder: 'Freq' }] },
];

function showPlayersList() {
  selectedPlayerId = null;
  el('playersDetailView').classList.add('hidden');
  el('playersListView').classList.remove('hidden');
}

function showPlayersDetail() {
  el('playersListView').classList.add('hidden');
  el('playersDetailView').classList.remove('hidden');
}

el('playerBackBtn').addEventListener('click', showPlayersList);

async function selectPlayer(id) {
  selectedPlayerId = id;
  showPlayersDetail();
  const detail = el('playerDetail');
  detail.innerHTML = '<div class="empty-state">Loading...</div>';
  const [player] = await Promise.all([post('getPlayerDetail', { id }), ensureJobsGangsLoaded()]);
  if (!player) {
    detail.innerHTML = '<div class="empty-state">Could not load this player (they may have disconnected).</div>';
    return;
  }
  renderPlayerDetail(player);
}

function statTile(label, value) {
  return `<div class="stat-tile"><div class="stat-label">${label}</div><div class="stat-value">${escapeHtml(value)}</div></div>`;
}

// ===================================================================
// Player inventory viewer (add/remove + live stack list)
// ===================================================================

let inventoryPlayer = null;

async function refreshPlayerInventory() {
  const grid = el('playerInventoryGrid');
  grid.innerHTML = '<div class="empty-state">Loading...</div>';
  const items = await post('getPlayerInventory', { id: inventoryPlayer.id });
  el('inventoryTitle').textContent = `Inventory (${(items || []).length} stacks)`;
  if (!items || !items.length) {
    grid.innerHTML = '<div class="empty-state">Empty inventory.</div>';
    return;
  }
  grid.innerHTML = '';
  items.forEach((item) => {
    const chip = document.createElement('div');
    chip.className = 'item-chip';
    chip.innerHTML = `<span>${escapeHtml(item.label)}</span><span class="item-count">${item.count}x</span>`;
    grid.appendChild(chip);
  });
}

function showPlayerInventory(player) {
  inventoryPlayer = player;
  el('inventoryPlayerName').textContent = player.name;
  el('invItemName').value = '';
  el('invItemAmount').value = 1;
  el('playersDetailView').classList.add('hidden');
  el('playerInventoryView').classList.remove('hidden');
  refreshPlayerInventory();
}

el('inventoryBackBtn').addEventListener('click', () => {
  el('playerInventoryView').classList.add('hidden');
  el('playersDetailView').classList.remove('hidden');
});

el('invAddBtn').addEventListener('click', async () => {
  const item = el('invItemName').value.trim();
  const amount = Number(el('invItemAmount').value) || 1;
  if (!item) return;
  await post('giveItem', { id: inventoryPlayer.id, item, amount });
  showToast(`Gave ${amount}x ${item}`);
  refreshPlayerInventory();
});

el('invRemoveBtn').addEventListener('click', async () => {
  const item = el('invItemName').value.trim();
  const amount = Number(el('invItemAmount').value) || 1;
  if (!item) return;
  await post('removePlayerItem', { id: inventoryPlayer.id, item, amount });
  showToast(`Removed ${amount}x ${item}`);
  refreshPlayerInventory();
});

function renderPlayerDetail(player) {
  const detail = el('playerDetail');
  detail.innerHTML = '';

  // --- General actions ---
  const generalGroup = document.createElement('div');
  generalGroup.className = 'action-group';
  generalGroup.innerHTML = '<div class="action-group-title">General</div>';
  const generalRow = document.createElement('div');
  generalRow.className = 'btn-row';
  GENERAL_ACTIONS.forEach((a) => {
    const btn = document.createElement('button');
    btn.className = 'btn small';
    btn.textContent = a.label;
    btn.addEventListener('click', async () => {
      await post('playerGeneral', { id: player.id, action: a.action });
      showToast(`${a.label} sent`);
    });
    generalRow.appendChild(btn);
  });
  generalGroup.appendChild(generalRow);
  detail.appendChild(generalGroup);

  // --- Administration ---
  const adminGroup = document.createElement('div');
  adminGroup.className = 'action-group';
  adminGroup.innerHTML = '<div class="action-group-title">Administration</div>';

  const kickRow = document.createElement('div');
  kickRow.className = 'field-row';
  kickRow.innerHTML = `<div class="field"><label>Kick Reason</label><input type="text" id="kickReason" placeholder="Reason"></div>`;
  const kickBtn = document.createElement('button');
  kickBtn.className = 'btn small danger';
  kickBtn.textContent = 'Kick';
  kickBtn.addEventListener('click', async () => {
    const reason = detail.querySelector('#kickReason').value || 'No reason given';
    await post('playerAdmin', { id: player.id, action: 'kick', input: reason });
    showToast(`Kicked ${player.name}`, 'error');
  });
  kickRow.appendChild(kickBtn);
  adminGroup.appendChild(kickRow);

  const banRow = document.createElement('div');
  banRow.className = 'field-row';
  banRow.style.marginTop = '8px';
  banRow.innerHTML = `
    <div class="field"><label>Ban Reason</label><input type="text" id="banReason" placeholder="VDM"></div>
    <div class="field" style="max-width:70px"><label>Hours</label><input type="number" id="banHours" placeholder="0"></div>
    <div class="field" style="max-width:70px"><label>Days</label><input type="number" id="banDays" placeholder="0"></div>
    <div class="field" style="max-width:70px"><label>Months</label><input type="number" id="banMonths" placeholder="0"></div>
  `;
  const banBtn = document.createElement('button');
  banBtn.className = 'btn small danger';
  banBtn.textContent = 'Ban';
  banBtn.addEventListener('click', async () => {
    const reason = detail.querySelector('#banReason').value;
    if (!reason) { showToast('Ban reason is required', 'error'); return; }
    const hours = Number(detail.querySelector('#banHours').value) || 0;
    const days = Number(detail.querySelector('#banDays').value) || 0;
    const months = Number(detail.querySelector('#banMonths').value) || 0;
    await post('playerAdmin', { id: player.id, action: 'ban', input: [reason, hours, days, months] });
    showToast(`Banned ${player.name}`, 'error');
  });
  banRow.appendChild(banBtn);
  adminGroup.appendChild(banRow);

  const permRow = document.createElement('div');
  permRow.className = 'field-row';
  permRow.style.marginTop = '8px';
  const permSelect = document.createElement('select');
  ADMIN_PERM_VALUES.forEach((p) => {
    const opt = document.createElement('option');
    opt.value = p.value; opt.textContent = p.label;
    permSelect.appendChild(opt);
  });
  const permField = document.createElement('div');
  permField.className = 'field';
  permField.innerHTML = '<label>Permission</label>';
  permField.appendChild(permSelect);
  permRow.appendChild(permField);
  const permBtn = document.createElement('button');
  permBtn.className = 'btn small';
  permBtn.textContent = 'Set';
  permBtn.addEventListener('click', async () => {
    await post('playerAdmin', { id: player.id, action: 'perm', input: permSelect.value });
    showToast('Permission updated');
  });
  permRow.appendChild(permBtn);
  adminGroup.appendChild(permRow);
  detail.appendChild(adminGroup);

  // --- Data editor ---
  const dataGroup = document.createElement('div');
  dataGroup.className = 'action-group';
  dataGroup.innerHTML = '<div class="action-group-title">Edit Character Data</div>';
  DATA_FIELDS.forEach((f) => {
    const row = document.createElement('div');
    row.className = 'field-row';
    row.style.marginBottom = '8px';
    const inputEls = [];
    const current = f.getValue ? f.getValue(player) : [];
    f.inputs.forEach((inputDef, i) => {
      const wrap = document.createElement('div');
      wrap.className = 'field';
      if (i === 0) wrap.innerHTML = `<label>${f.label}</label>`;
      let input;
      if (inputDef.type === 'select') {
        input = document.createElement('select');
        (f.group ? f.group() : []).forEach((opt) => {
          const option = document.createElement('option');
          option.value = opt.name;
          option.textContent = opt.label;
          input.appendChild(option);
        });
        if (current[i]) input.value = current[i];
      } else {
        input = document.createElement('input');
        input.type = inputDef.type;
        input.placeholder = inputDef.placeholder;
        const value = current[i];
        if (value !== undefined && value !== null && value !== '') input.value = value;
      }
      wrap.appendChild(input);
      inputEls.push(input);
      row.appendChild(wrap);
    });

    // Job/gang: cap the grade input to however many grades the currently
    // selected job/gang actually has, and re-cap whenever the dropdown
    // changes - a grade that doesn't exist on that job would just get
    // rejected/ignored server-side, so keep the input from offering it at all.
    if (f.group) {
      const groupSelect = inputEls[0];
      const gradeInput = inputEls[1];
      const applyGradeCap = () => {
        const match = f.group().find((g) => g.name === groupSelect.value);
        const maxGrade = match ? match.maxGrade : 0;
        gradeInput.min = 0;
        gradeInput.max = maxGrade;
        gradeInput.placeholder = `0-${maxGrade}`;
        if (gradeInput.value !== '' && Number(gradeInput.value) > maxGrade) gradeInput.value = maxGrade;
      };
      groupSelect.addEventListener('change', applyGradeCap);
      applyGradeCap();
    }

    const applyBtn = document.createElement('button');
    applyBtn.className = 'btn small';
    applyBtn.textContent = 'Set';
    applyBtn.addEventListener('click', async () => {
      const values = inputEls.map((i) => (i.type === 'number' ? Number(i.value) : i.value));
      if (values.every((v) => v === '' || v === null || Number.isNaN(v))) return;
      await post('changePlayerData', { id: player.id, field: f.field, input: values });
      showToast(`${f.label} updated`);
    });
    row.appendChild(applyBtn);
    dataGroup.appendChild(row);
  });
  detail.appendChild(dataGroup);

  // --- Extra ---
  const extraGroup = document.createElement('div');
  extraGroup.className = 'action-group';
  extraGroup.innerHTML = '<div class="action-group-title">Extra</div>';
  const extraRow = document.createElement('div');
  extraRow.className = 'btn-row';

  const showInvBtn = document.createElement('button');
  showInvBtn.className = 'btn small';
  showInvBtn.textContent = 'Show Inventory';
  showInvBtn.addEventListener('click', () => showPlayerInventory(player));
  extraRow.appendChild(showInvBtn);

  const clothingBtn = document.createElement('button');
  clothingBtn.className = 'btn small';
  clothingBtn.textContent = 'Clothing Menu';
  clothingBtn.addEventListener('click', async () => {
    const ok = await post('clothingMenu', { id: player.id });
    if (!ok) showToast('Clothing menu is unavailable on this server', 'error');
  });
  extraRow.appendChild(clothingBtn);

  extraGroup.appendChild(extraRow);
  detail.appendChild(extraGroup);

  // --- Identifiers ---
  const idGroup = document.createElement('div');
  idGroup.className = 'action-group';
  idGroup.innerHTML = '<div class="action-group-title">Identifiers (click to copy)</div>';
  [['License', player.license], ['Discord', player.discord], ['Steam', player.steam]].forEach(([label, value]) => {
    const chip = document.createElement('span');
    chip.className = 'copy-chip';
    chip.textContent = `${label}: ${value}`;
    chip.addEventListener('click', async () => {
      await post('copyText', { value });
      showToast(`${label} copied`);
    });
    idGroup.appendChild(chip);
  });
  detail.appendChild(idGroup);
}

// ===================================================================
// Vehicles
// ===================================================================

let vehicleData = null;

async function loadVehicles() {
  vehicleData = await post('getVehicles');
  renderVehicles();
}

function renderVehicles() {
  const container = el('vehicleCategories');
  if (!vehicleData || !vehicleData.categories || !vehicleData.categories.length) {
    container.innerHTML = '<div class="empty-state">No vehicles found.</div>';
    return;
  }

  const query = el('vehicleSearch').value.trim().toLowerCase();
  container.innerHTML = '';

  vehicleData.categories.forEach((cat) => {
    let vehicles = vehicleData.byCategory[cat] || [];
    if (query) {
      vehicles = vehicles.filter((v) => v.name.toLowerCase().includes(query) || v.model.toLowerCase().includes(query));
    }
    if (!vehicles.length) return;

    const details = document.createElement('details');
    details.className = 'vehicle-category';
    if (query) details.open = true;
    const summary = document.createElement('summary');
    summary.textContent = `${capitalize(cat)} (${vehicles.length})`;
    details.appendChild(summary);

    const grid = document.createElement('div');
    grid.className = 'vehicle-grid';
    vehicles.forEach((v) => {
      const chip = document.createElement('button');
      chip.className = 'vehicle-chip';
      chip.innerHTML = `${escapeHtml(v.name)}<span class="veh-model">${escapeHtml(v.model)}</span>`;
      chip.addEventListener('click', async () => {
        chip.disabled = true;
        await post('spawnVehicle', { model: v.model });
        chip.disabled = false;
      });
      grid.appendChild(chip);
    });
    details.appendChild(grid);
    container.appendChild(details);
  });

  if (!container.children.length) {
    container.innerHTML = '<div class="empty-state">No vehicles match your search.</div>';
  }
}

function capitalize(str) {
  return str.charAt(0).toUpperCase() + str.slice(1);
}

el('vehicleSearch').addEventListener('input', renderVehicles);
el('fixVehicleBtn').addEventListener('click', async () => { await post('fixVehicle'); showToast('Vehicle fixed'); });
el('deleteVehicleBtn').addEventListener('click', async () => { await post('deleteVehicle'); showToast('Nearest vehicle deleted'); });
el('adminCarBtn').addEventListener('click', async () => { await post('adminCar'); showToast('Ownership requested'); });
el('setPlateBtn').addEventListener('click', async () => {
  const plate = el('plateInput').value.trim();
  if (!plate) return;
  await post('setPlate', { plate });
  showToast('Plate updated');
});

// ===================================================================
// Server
// ===================================================================

const WEATHER_LIST = ['Extrasunny', 'Clear', 'Neutral', 'Smog', 'Foggy', 'Overcast', 'Clouds', 'Clearing', 'Rain', 'Thunder', 'Snow', 'Blizzard', 'Snowlight', 'Xmas', 'Halloween'];

function initServerTab() {
  const weatherGrid = el('weatherGrid');
  WEATHER_LIST.forEach((w) => {
    const chip = document.createElement('button');
    chip.className = 'weather-chip';
    chip.textContent = w;
    chip.addEventListener('click', async () => { await post('setWeather', { weather: w }); showToast(`Weather set to ${w}`); });
    weatherGrid.appendChild(chip);
  });

  const timeGrid = el('timeGrid');
  for (let h = 0; h < 24; h++) {
    const hourStr = String(h).padStart(2, '0');
    const chip = document.createElement('button');
    chip.className = 'time-chip';
    chip.textContent = `${hourStr}:00`;
    chip.addEventListener('click', async () => { await post('setTime', { hour: hourStr }); showToast(`Time set to ${hourStr}:00`); });
    timeGrid.appendChild(chip);
  }

  el('radioLookupBtn').addEventListener('click', async () => {
    const freq = el('radioFreqInput').value;
    if (!freq) return;
    const result = await post('getRadioList', { frequency: freq });
    const container = el('radioResults');
    container.innerHTML = '';
    if (!result || !result.players || !result.players.length) {
      container.innerHTML = '<div class="empty-state">Nobody is on that frequency.</div>';
      return;
    }
    result.players.forEach((p) => {
      const row = document.createElement('div');
      row.className = 'radio-result-row';
      row.textContent = p.name;
      container.appendChild(row);
    });
  });

  el('pullStashBtn').addEventListener('click', async () => {
    const name = el('stashInput').value.trim();
    if (!name) return;
    await post('pullStash', { name });
  });
}

// ===================================================================
// Reports
// ===================================================================

async function loadReports() {
  const container = el('reportsList');
  container.innerHTML = '<div class="empty-state">Loading reports...</div>';
  const reports = await post('getReports');
  renderReports(Array.isArray(reports) ? reports : []);
}

function renderReports(reports) {
  const container = el('reportsList');
  if (!reports.length) {
    container.innerHTML = '<div class="empty-state">No pending reports.</div>';
    return;
  }

  container.innerHTML = '';
  reports.forEach((report) => {
    const card = document.createElement('div');
    card.className = 'card report-card';
    card.innerHTML = `
      <div class="report-card-header">
        <span class="rid">#${report.id} &middot; ${escapeHtml(report.senderName)}</span>
        <span class="claimed">Claimed: ${escapeHtml(report.claimed)}</span>
      </div>
      <div class="report-message">${escapeHtml(report.message)}</div>
    `;

    const replyRow = document.createElement('div');
    replyRow.className = 'field-row';
    replyRow.innerHTML = `<div class="field"><label>Reply</label><input type="text" class="reply-input" placeholder="Message"></div>`;
    const replyBtn = document.createElement('button');
    replyBtn.className = 'btn small primary';
    replyBtn.textContent = 'Send';
    replyBtn.addEventListener('click', async () => {
      const input = card.querySelector('.reply-input');
      if (!input.value.trim()) return;
      await post('replyReport', { report, message: input.value.trim() });
      showToast('Reply sent');
      input.value = '';
    });
    replyRow.appendChild(replyBtn);
    card.appendChild(replyRow);

    const closeBtn = document.createElement('button');
    closeBtn.className = 'btn small danger';
    closeBtn.textContent = 'Close Report';
    closeBtn.style.alignSelf = 'flex-start';
    closeBtn.addEventListener('click', async () => {
      await post('closeReport', { report });
      showToast('Report closed');
      loadReports();
    });
    card.appendChild(closeBtn);

    container.appendChild(card);
  });
}

el('refreshReportsBtn').addEventListener('click', loadReports);

// ===================================================================
// Ban logs
// ===================================================================

function formatExpiry(expireUnix) {
  if (!expireUnix) return { text: 'Unknown', active: false };
  const expireMs = expireUnix * 1000;
  const now = Date.now();
  const date = new Date(expireMs).toLocaleString();
  if (expireMs <= now) return { text: `Expired · ${date}`, active: false };

  const diffMs = expireMs - now;
  const days = Math.floor(diffMs / 86400000);
  const hours = Math.floor((diffMs % 86400000) / 3600000);
  const remaining = days > 0 ? `${days}d ${hours}h remaining` : `${hours}h remaining`;
  return { text: `${remaining} · until ${date}`, active: true };
}

async function loadBans() {
  const container = el('bansList');
  container.innerHTML = '<div class="empty-state">Loading ban logs...</div>';
  const bans = await post('getBans');
  renderBans(Array.isArray(bans) ? bans : []);
}

function renderBans(bans) {
  const container = el('bansList');
  if (!bans.length) {
    container.innerHTML = '<div class="empty-state">No bans on record.</div>';
    return;
  }

  container.innerHTML = '';
  bans.forEach((ban) => {
    const expiry = formatExpiry(ban.expire);
    const card = document.createElement('div');
    card.className = 'card ban-card';
    card.innerHTML = `
      <div class="ban-card-header">
        <span class="bname">${escapeHtml(ban.name || 'Unknown')}</span>
        <span class="expiry ${expiry.active ? 'active' : 'expired'}">${expiry.active ? 'Active' : 'Expired'}</span>
      </div>
      <div class="ban-reason">${escapeHtml(ban.reason || 'No reason given')}</div>
      <div class="ban-meta">${expiry.text} &middot; Banned by ${escapeHtml(ban.bannedby || 'Unknown')} &middot; License: ${escapeHtml(ban.license || 'n/a')}</div>
    `;

    if (expiry.active) {
      const unbanBtn = document.createElement('button');
      unbanBtn.className = 'btn small danger';
      unbanBtn.textContent = 'Unban';
      unbanBtn.style.alignSelf = 'flex-start';
      unbanBtn.addEventListener('click', async () => {
        await post('unban', { id: ban.id });
        showToast(`Unbanned ${ban.name || 'player'}`);
        loadBans();
      });
      card.appendChild(unbanBtn);
    }

    container.appendChild(card);
  });
}

el('refreshBansBtn').addEventListener('click', loadBans);

// ===================================================================
// Character lookup
// ===================================================================

let characters = [];
let selectedCitizenId = null;

async function searchCharacters() {
  const term = el('characterSearch').value.trim();
  const container = el('charactersList');
  if (!term) {
    container.innerHTML = '<div class="empty-state">Search for a character above.</div>';
    return;
  }
  container.innerHTML = '<div class="empty-state">Searching...</div>';
  const results = await post('searchCharacters', { term });
  characters = Array.isArray(results) ? results : [];
  renderCharactersList();
}

function renderCharactersList() {
  const container = el('charactersList');
  if (!characters.length) {
    container.innerHTML = '<div class="empty-state">No characters match that search.</div>';
    return;
  }

  container.innerHTML = '';
  characters.forEach((c) => {
    const row = document.createElement('div');
    row.className = 'player-row' + (c.citizenid === selectedCitizenId ? ' selected' : '');
    const initials = (c.name || '?').trim().slice(0, 2).toUpperCase();
    row.innerHTML = `
      <div class="player-avatar">${initials}</div>
      <div class="player-row-text">
        <div class="player-row-name">${escapeHtml(c.name || 'Unknown')}</div>
        <div class="player-row-id">${escapeHtml(c.citizenid)}</div>
      </div>
    `;
    row.addEventListener('click', () => selectCharacter(c.citizenid));
    container.appendChild(row);
  });
}

el('characterSearchBtn').addEventListener('click', searchCharacters);
el('characterSearch').addEventListener('keydown', (e) => { if (e.key === 'Enter') searchCharacters(); });

async function selectCharacter(citizenid) {
  selectedCitizenId = citizenid;
  renderCharactersList();
  const detail = el('characterDetail');
  detail.innerHTML = '<div class="empty-state">Loading...</div>';
  const character = await post('getCharacterDetail', { citizenid });
  if (!character) {
    detail.innerHTML = '<div class="empty-state">Could not load this character.</div>';
    return;
  }
  renderCharacterDetail(character);
}

function renderCharacterDetail(c) {
  const detail = el('characterDetail');
  detail.innerHTML = '';

  const charinfo = c.charinfo || {};
  const fullName = `${charinfo.firstname || ''} ${charinfo.lastname || ''}`.trim() || c.name;

  const header = document.createElement('div');
  header.className = 'detail-header';
  header.innerHTML = `
    <div><h2>${escapeHtml(fullName)}</h2><div class="cid">CID: ${escapeHtml(c.citizenid)}</div></div>
    <span class="expiry ${c.online ? 'active' : 'expired'}">${c.online ? 'Online' : 'Offline'}</span>
  `;
  detail.appendChild(header);

  const stats = document.createElement('div');
  stats.className = 'stat-grid';
  stats.innerHTML = [
    statTile('Nationality', charinfo.nationality || 'n/a'),
    statTile('Birthdate', charinfo.birthdate || 'n/a'),
    statTile('Phone', charinfo.phone || 'n/a'),
    statTile('Job', c.job ? `${c.job.label} (${c.job.grade?.name || c.job.grade})` : 'n/a'),
    statTile('Gang', c.gang ? c.gang.label : 'n/a'),
    statTile('Cash', c.money ? formatMoney(c.money.cash) : '0'),
    statTile('Bank', c.money ? formatMoney(c.money.bank) : '0'),
  ].join('');
  detail.appendChild(stats);

  const idGroup = document.createElement('div');
  idGroup.className = 'action-group';
  idGroup.innerHTML = '<div class="action-group-title">Identifiers (click to copy)</div>';
  [['License', c.license], ['Citizen ID', c.citizenid]].forEach(([label, value]) => {
    const chip = document.createElement('span');
    chip.className = 'copy-chip';
    chip.textContent = `${label}: ${value}`;
    chip.addEventListener('click', async () => {
      await post('copyText', { value });
      showToast(`${label} copied`);
    });
    idGroup.appendChild(chip);
  });
  detail.appendChild(idGroup);

  const actionGroup = document.createElement('div');
  actionGroup.className = 'action-group';
  actionGroup.innerHTML = '<div class="action-group-title">Actions</div>';
  const invBtn = document.createElement('button');
  invBtn.className = 'btn small' + (c.online ? '' : ' disabled');
  invBtn.textContent = c.online ? 'Open Live Inventory' : 'Inventory (offline — read only below)';
  invBtn.disabled = !c.online;
  invBtn.addEventListener('click', async () => {
    if (!c.online) return;
    await post('openCharacterInventory', { onlineId: c.onlineId });
  });
  actionGroup.appendChild(invBtn);
  detail.appendChild(actionGroup);

  const invGroup = document.createElement('div');
  invGroup.className = 'action-group';
  invGroup.innerHTML = `<div class="action-group-title">Inventory Snapshot (${(c.items || []).length} stacks)</div>`;
  const itemGrid = document.createElement('div');
  itemGrid.className = 'item-grid';
  if (!c.items || !c.items.length) {
    itemGrid.innerHTML = '<div class="empty-state">Empty inventory.</div>';
  } else {
    c.items.forEach((item) => {
      const chip = document.createElement('div');
      chip.className = 'item-chip';
      chip.innerHTML = `<span>${escapeHtml(item.label)}</span><span class="item-count">${item.count}x</span>`;
      itemGrid.appendChild(chip);
    });
  }
  invGroup.appendChild(itemGrid);
  detail.appendChild(invGroup);
}

function formatMoney(n) {
  return Number(n || 0).toLocaleString('en-US');
}

// ===================================================================
// Init
// ===================================================================

initToggleGrids();
initSelfExtras();
initServerTab();
