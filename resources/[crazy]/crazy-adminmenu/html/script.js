// NUI contract with client.lua — see resources/[crazy]/crazy-adminmenu/client/client.lua
// inbound (SendNUIMessage):  { action: 'open' | 'close' | 'toggleState' }
// outbound (RegisterNUICallback): close, getPlayers, getPlayerDetail, playerGeneral,
//   playerAdmin, changePlayerData, giveWeapons, clothingMenu, openInventory, giveItem,
//   mutePlayer, toggleSelf, giveWeaponType, setPedModel, refreshPedModel, getToggleState,
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
  players: { title: 'Players', subtitle: 'Manage the current online playerbase' },
  self: { title: 'Self Tools', subtitle: 'Options that only affect you' },
  vehicles: { title: 'Vehicles', subtitle: 'Spawn, fix, delete and manage vehicles' },
  server: { title: 'Server', subtitle: 'Weather, time, radio and stash lookups' },
  dev: { title: 'Dev Tools', subtitle: 'Handy things for developers' },
  reports: { title: 'Reports', subtitle: 'Pending player reports' },
  bans: { title: 'Ban Logs', subtitle: 'Reason and duration for every ban on record' },
  characters: { title: 'Characters', subtitle: 'Look up any character in the database, online or not' },
};

let currentTab = 'players';

function switchTab(tab) {
  currentTab = tab;
  document.querySelectorAll('.nav-item').forEach((n) => n.classList.toggle('active', n.dataset.tab === tab));
  document.querySelectorAll('.panel').forEach((p) => p.classList.toggle('hidden', p.dataset.panel !== tab));
  el('topbarTitle').textContent = TAB_META[tab].title;
  el('topbarSubtitle').textContent = TAB_META[tab].subtitle;

  if (tab === 'players') loadPlayers();
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
  switchTab('players');
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
  { action: 'noclip', label: 'Noclip', icon: '\u{1F6F8}' },
  { action: 'godmode', label: 'Godmode', icon: '\u{1F6E1}️' },
  { action: 'invisible', label: 'Invisible', icon: '\u{1F47B}' },
  { action: 'vehicleGodmode', label: 'Vehicle Godmode', icon: '\u{1F697}' },
  { action: 'infiniteAmmo', label: 'Infinite Ammo', icon: '\u{1F3AF}' },
  { action: 'names', label: 'Player Names', icon: '\u{1F3F7}️' },
  { action: 'blips', label: 'Player Blips', icon: '\u{1F4CD}' },
];

const DEV_TOGGLE_TILES = [
  { action: 'coords', label: 'Coords Overlay', icon: '\u{1F4D0}' },
  { action: 'vehicleInfo', label: 'Vehicle Info Overlay', icon: '\u{1F699}' },
  { action: 'laser', label: 'Laser Pointer', icon: '\u{1F4A5}' },
];

function buildToggleTile(def) {
  const tile = document.createElement('div');
  tile.className = 'toggle-tile';
  tile.dataset.action = def.action;
  tile.innerHTML = `
    <div class="tile-top">
      <span class="tile-icon">${def.icon}</span>
      <span class="dot"></span>
    </div>
    <span class="tile-label">${def.label}</span>
    <span class="tile-state">Off</span>
  `;
  tile.addEventListener('click', async () => {
    // Flip immediately rather than waiting on the round trip - the Lua
    // side's toggle fires inside a CreateThread (so the NUI callback that
    // reports state back doesn't block on it forever), which races with
    // that state report and used to leave the tile showing the old state
    // until the menu was closed and reopened. These are simple booleans
    // that always succeed, so flipping optimistically here is safe; the
    // next real toggleState push (menu reopen, another toggle) still wins
    // if it ever disagrees.
    const nowOn = !tile.classList.contains('active');
    tile.classList.toggle('active', nowOn);
    tile.querySelector('.tile-state').textContent = nowOn ? 'On' : 'Off';
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
    const on = !!state[tile.dataset.action];
    tile.classList.toggle('active', on);
    tile.querySelector('.tile-state').textContent = on ? 'On' : 'Off';
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

  const WEAPON_TYPES = [
    { key: 'pistol', label: 'Pistols' },
    { key: 'smg', label: 'SMGs' },
    { key: 'shotgun', label: 'Shotguns' },
    { key: 'assault', label: 'Assault Rifles' },
    { key: 'lmg', label: 'LMGs' },
    { key: 'sniper', label: 'Snipers' },
    { key: 'heavy', label: 'Heavy' },
  ];

  const row = el('selfWeaponRow');
  WEAPON_TYPES.forEach((w) => {
    const btn = document.createElement('button');
    btn.className = 'btn small';
    btn.textContent = w.label;
    btn.addEventListener('click', async () => {
      await post('giveWeaponType', { weaponType: w.key });
      showToast(`Gave yourself all ${w.label.toLowerCase()}`);
    });
    row.appendChild(btn);
  });

  // Revive + cuff live in the self toggle grid area as plain action chips.
  const selfGrid = el('selfToggleGrid');
  const reviveBtn = document.createElement('button');
  reviveBtn.className = 'toggle-tile instant-tile';
  reviveBtn.style.cursor = 'pointer';
  reviveBtn.innerHTML = `<div class="tile-top"><span class="tile-icon">❤️</span></div><span class="tile-label">Revive Yourself</span><span class="tile-state">Instant</span>`;
  reviveBtn.addEventListener('click', async () => { await post('toggleSelf', { action: 'revive' }); showToast('Revived'); });
  selfGrid.appendChild(reviveBtn);

  const cuffBtn = document.createElement('button');
  cuffBtn.className = 'toggle-tile instant-tile';
  cuffBtn.style.cursor = 'pointer';
  cuffBtn.innerHTML = `<div class="tile-top"><span class="tile-icon">\u{1F517}</span></div><span class="tile-label">Cuff / Uncuff</span><span class="tile-state">Instant</span>`;
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
}

function renderPlayersList(list) {
  const container = el('playersList');
  const query = el('playerSearch').value.trim().toLowerCase();
  const filtered = query
    ? list.filter((p) => String(p.id).includes(query) || (p.name || '').toLowerCase().includes(query))
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
    row.innerHTML = `
      <div class="player-avatar">${initials}</div>
      <div class="player-row-text">
        <div class="player-row-name">${escapeHtml(p.name || 'Unknown')}</div>
        <div class="player-row-id">ID ${p.id} &middot; ${escapeHtml(p.cid || '')}</div>
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

const DATA_FIELDS = [
  { field: 'name', label: 'Name', inputs: [{ type: 'text', placeholder: 'First' }, { type: 'text', placeholder: 'Last' }] },
  { field: 'food', label: 'Hunger %', inputs: [{ type: 'number', placeholder: '0-100' }] },
  { field: 'thirst', label: 'Thirst %', inputs: [{ type: 'number', placeholder: '0-100' }] },
  { field: 'stress', label: 'Stress %', inputs: [{ type: 'number', placeholder: '0-100' }] },
  { field: 'armor', label: 'Armor %', inputs: [{ type: 'number', placeholder: '0-100' }] },
  { field: 'phone', label: 'Phone', inputs: [{ type: 'text', placeholder: 'Number' }] },
  { field: 'crafting', label: 'Crafting Rep', inputs: [{ type: 'number', placeholder: '0' }] },
  { field: 'dealer', label: 'Dealer Rep', inputs: [{ type: 'number', placeholder: '0' }] },
  { field: 'cash', label: 'Cash', inputs: [{ type: 'number', placeholder: '0' }] },
  { field: 'bank', label: 'Bank', inputs: [{ type: 'number', placeholder: '0' }] },
  { field: 'job', label: 'Job', inputs: [{ type: 'text', placeholder: 'Name' }, { type: 'number', placeholder: 'Grade' }] },
  { field: 'gang', label: 'Gang', inputs: [{ type: 'text', placeholder: 'Name' }, { type: 'number', placeholder: 'Grade' }] },
  { field: 'radio', label: 'Radio Channel', inputs: [{ type: 'number', placeholder: 'Freq' }] },
];

const WEAPON_TYPES_SHORT = [
  { key: 'pistol', label: 'Pistols' }, { key: 'smg', label: 'SMGs' }, { key: 'shotgun', label: 'Shotguns' },
  { key: 'assault', label: 'Assault' }, { key: 'lmg', label: 'LMGs' }, { key: 'sniper', label: 'Snipers' }, { key: 'heavy', label: 'Heavy' },
];

async function selectPlayer(id) {
  selectedPlayerId = id;
  renderPlayersList(players);
  const detail = el('playerDetail');
  detail.innerHTML = '<div class="empty-state">Loading...</div>';
  const player = await post('getPlayerDetail', { id });
  if (!player) {
    detail.innerHTML = '<div class="empty-state">Could not load this player (they may have disconnected).</div>';
    return;
  }
  renderPlayerDetail(player);
}

function statTile(label, value) {
  return `<div class="stat-tile"><div class="stat-label">${label}</div><div class="stat-value">${escapeHtml(value)}</div></div>`;
}

function renderPlayerDetail(player) {
  const detail = el('playerDetail');
  detail.innerHTML = '';

  const header = document.createElement('div');
  header.className = 'detail-header';
  header.innerHTML = `<div><h2>${escapeHtml(player.name)}</h2><div class="cid">CID: ${escapeHtml(player.cid || '')} &middot; ID: ${player.id}</div></div>`;
  detail.appendChild(header);

  const stats = document.createElement('div');
  stats.className = 'stat-grid';
  stats.innerHTML = [
    statTile('Hunger', player.food), statTile('Thirst', player.water), statTile('Stress', player.stress),
    statTile('Armor', player.armor), statTile('Job', player.job), statTile('Gang', player.gang),
    statTile('Cash', player.cash), statTile('Bank', player.bank), statTile('Phone', player.phone),
  ].join('');
  detail.appendChild(stats);

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

  const routingRow = document.createElement('div');
  routingRow.className = 'field-row';
  routingRow.style.marginTop = '8px';
  routingRow.innerHTML = `
    <div class="field"><label>Routing Bucket</label><input type="number" id="routingInput" placeholder="25"></div>
  `;
  const routingBtn = document.createElement('button');
  routingBtn.className = 'btn small';
  routingBtn.textContent = 'Apply';
  routingBtn.addEventListener('click', async () => {
    const val = detail.querySelector('#routingInput').value;
    if (val === '') return;
    await post('playerGeneral', { id: player.id, action: 'routing', input: Number(val) });
    showToast('Routing bucket set');
  });
  routingRow.appendChild(routingBtn);
  generalGroup.appendChild(routingRow);
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
    f.inputs.forEach((inputDef, i) => {
      const wrap = document.createElement('div');
      wrap.className = 'field';
      if (i === 0) wrap.innerHTML = `<label>${f.label}</label>`;
      const input = document.createElement('input');
      input.type = inputDef.type;
      input.placeholder = inputDef.placeholder;
      wrap.appendChild(input);
      inputEls.push(input);
      row.appendChild(wrap);
    });
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

  // --- Weapons ---
  const weaponGroup = document.createElement('div');
  weaponGroup.className = 'action-group';
  weaponGroup.innerHTML = '<div class="action-group-title">Give All Weapons</div>';
  const weaponRow = document.createElement('div');
  weaponRow.className = 'btn-row';
  WEAPON_TYPES_SHORT.forEach((w) => {
    const btn = document.createElement('button');
    btn.className = 'btn small';
    btn.textContent = w.label;
    btn.addEventListener('click', async () => {
      await post('giveWeapons', { id: player.id, weaponType: w.key });
      showToast(`Gave ${player.name} all ${w.label.toLowerCase()}`);
    });
    weaponRow.appendChild(btn);
  });
  weaponGroup.appendChild(weaponRow);
  detail.appendChild(weaponGroup);

  // --- Extra ---
  const extraGroup = document.createElement('div');
  extraGroup.className = 'action-group';
  extraGroup.innerHTML = '<div class="action-group-title">Extra</div>';
  const extraRow = document.createElement('div');
  extraRow.className = 'btn-row';

  const invBtn = document.createElement('button');
  invBtn.className = 'btn small';
  invBtn.textContent = 'Open Inventory';
  invBtn.addEventListener('click', async () => { await post('openInventory', { id: player.id }); });
  extraRow.appendChild(invBtn);

  const muteBtn = document.createElement('button');
  muteBtn.className = 'btn small';
  muteBtn.textContent = 'Toggle Mute';
  muteBtn.addEventListener('click', async () => { await post('mutePlayer', { id: player.id }); showToast('Mute toggled'); });
  extraRow.appendChild(muteBtn);

  const clothingBtn = document.createElement('button');
  clothingBtn.className = 'btn small';
  clothingBtn.textContent = 'Clothing Menu';
  clothingBtn.addEventListener('click', async () => {
    const ok = await post('clothingMenu', { id: player.id });
    if (!ok) showToast('Clothing menu is unavailable on this server', 'error');
  });
  extraRow.appendChild(clothingBtn);

  extraGroup.appendChild(extraRow);

  const giveItemRow = document.createElement('div');
  giveItemRow.className = 'field-row';
  giveItemRow.style.marginTop = '8px';
  giveItemRow.innerHTML = `
    <div class="field"><label>Item</label><input type="text" id="giveItemName" placeholder="phone"></div>
    <div class="field" style="max-width:90px"><label>Amount</label><input type="number" id="giveItemAmount" placeholder="1" value="1"></div>
  `;
  const giveItemBtn = document.createElement('button');
  giveItemBtn.className = 'btn small';
  giveItemBtn.textContent = 'Give Item';
  giveItemBtn.addEventListener('click', async () => {
    const item = detail.querySelector('#giveItemName').value.trim();
    const amount = detail.querySelector('#giveItemAmount').value || 1;
    if (!item) return;
    await post('giveItem', { id: player.id, item, amount });
    showToast(`Gave ${player.name} ${amount}x ${item}`);
  });
  giveItemRow.appendChild(giveItemBtn);
  extraGroup.appendChild(giveItemRow);
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
