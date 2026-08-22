// NUI contract with client.lua:
//   inbound (SendNUIMessage):  { action: 'open' | 'close' | 'characters' | 'notify' }
//   outbound (RegisterNUICallback): previewCharacter, previewGender, createCharacter,
//                                   selectCharacter, deleteCharacter, refreshCharacters
//
// character objects are qbx_core's real PlayerEntity shape as returned by
// qbx_core:server:getCharacters — citizenid, cid, charinfo{firstname,
// lastname,birthdate,nationality,gender,phone,account,backstory},
// money{cash,bank,crypto}, job{label,grade{name}}, gang{label,grade{name}},
// position, metadata.

const DEFAULT_NATIONALITY = 'USA';

const state = {
  characters: [],
  maxSlots: 3,
  apartments: [],
  focusedSlot: 1,
  selectedCitizenId: null,
  selectedGender: 0,
  selectedApartmentId: null,
  spawnLocations: [],
  selectedSpawnId: null,
  busy: false,
};

const el = (id) => document.getElementById(id);

const app = el('app');
const slotSwitcher = el('slot-switcher');
const toast = el('toast');

const infoPanel = el('info-panel');
const infoName = el('info-name');
const infoSubtitle = el('info-subtitle');
const infoGenderIcon = el('info-gender-icon');
const infoGrid = el('info-grid');

// Small monochrome (currentColor) glyphs for each dossier field, sat inside
// a circular badge (see .info-icon in style.css) — hand-rolled generic
// shapes rather than an icon font/library, since this NUI page has no
// external asset pipeline to pull one in through.
const ICONS = {
  male: '<svg viewBox="0 0 24 24"><circle cx="10" cy="14" r="5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M14 10 20 4M15 4h5v5" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  female: '<svg viewBox="0 0 24 24"><circle cx="12" cy="9" r="5" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M12 14v7M8.5 18h7" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
  birthdate: '<svg viewBox="0 0 24 24"><rect x="3" y="5" width="18" height="16" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M3 10h18M8 3v4M16 3v4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
  nationality: '<svg viewBox="0 0 24 24"><path d="M5 3v18" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/><path d="M5 4h13l-3 4 3 4H5Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>',
  account: '<svg viewBox="0 0 24 24"><rect x="2" y="5" width="20" height="14" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M2 10h20" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>',
  bank: '<svg viewBox="0 0 24 24"><path d="M3 10 12 4l9 6" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/><path d="M4 10h16v9H4Z" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M8 13v4M12 13v4M16 13v4" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
  cash: '<svg viewBox="0 0 24 24"><circle cx="12" cy="12" r="9" fill="none" stroke="currentColor" stroke-width="1.6"/><text x="12" y="16.5" font-size="11" text-anchor="middle" fill="currentColor" font-weight="700">$</text></svg>',
  job: '<svg viewBox="0 0 24 24"><rect x="3" y="8" width="18" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M9 8V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M3 13h18" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>',
  jobGrade: '<svg viewBox="0 0 24 24"><path d="m12 2 2.47 5.6 6.03.57-4.55 4.06 1.33 5.94L12 15.1l-5.28 3.07 1.33-5.94-4.55-4.06 6.03-.57Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>',
  gang: '<svg viewBox="0 0 24 24"><path d="M12 3 20 6.5V11c0 5-3.5 8.5-8 10-4.5-1.5-8-5-8-10V6.5Z" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linejoin="round"/></svg>',
  gangGrade: '<svg viewBox="0 0 24 24"><path d="M5 10.5 12 5l7 5.5M5 15.5 12 10l7 5.5" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round"/></svg>',
  phone: '<svg viewBox="0 0 24 24"><rect x="7" y="2" width="10" height="20" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M11 18h2" fill="none" stroke="currentColor" stroke-width="1.6" stroke-linecap="round"/></svg>',
};

const emptyPanel = el('empty-panel');
const emptyTitle = el('empty-title');

const dock = el('dock');
const btnDelete = el('btn-delete');
const btnSelect = el('btn-select');

const modalIdentity = el('modal-identity');
const stepIdentity = el('step-identity');
const stepApartment = el('step-apartment');
const inputFirstName = el('input-first-name');
const inputLastName = el('input-last-name');
const inputBirthdate = el('input-birthdate');
const inputNationality = el('input-nationality');
const btnGenderMale = el('btn-gender-male');
const btnGenderFemale = el('btn-gender-female');
const btnIdentityCancel = el('btn-identity-cancel');
const btnIdentityNext = el('btn-identity-next');
const apartmentList = el('apartment-list');
const btnApartmentBack = el('btn-apartment-back');
const btnApartmentConfirm = el('btn-apartment-confirm');

const modalDelete = el('modal-delete');
const deleteCharName = el('delete-char-name');
const inputDeleteConfirm = el('input-delete-confirm');
const btnDeleteCancel = el('btn-delete-cancel');
const btnDeleteConfirm = el('btn-delete-confirm');

const DELETE_CONFIRM_WORD = 'confirm';

const modalSpawn = el('modal-spawn');
const spawnList = el('spawn-list');
const btnSpawnConfirm = el('btn-spawn-confirm');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-multichar';
}

async function nuiPost(name, data = {}) {
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

let toastTimer = null;
function showToast(kind, message) {
  toast.textContent = message;
  toast.className = 'toast' + (kind && kind !== 'info' ? ` ${kind}` : '');
  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toast.classList.add('hidden'), 3500);
}

function setBusy(busy) {
  state.busy = busy;
  const isCreateMode = btnSelect.dataset.mode === 'create';
  const hasSelection = state.selectedCitizenId !== null;
  btnSelect.disabled = busy || (!isCreateMode && !hasSelection);
  btnDelete.disabled = busy || !hasSelection;
  btnIdentityNext.disabled = busy;
  btnApartmentConfirm.disabled = busy || !state.selectedApartmentId;
  btnDeleteConfirm.disabled = busy || inputDeleteConfirm.value.trim().toLowerCase() !== DELETE_CONFIRM_WORD;
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

function groupDigits(n) {
  n = Number(n) || 0;
  return n.toLocaleString('en-US');
}

function genderLabel(g) {
  return Number(g) === 1 ? 'Female' : 'Male';
}

// qbx_core numbers character slots starting at 1, not 0 — the first
// character ever created gets cid 1 (see getNextCid() in
// qbx_core/server/character.lua: `(lastCharacter.charinfo.cid or 0) + 1`).
// getCharacters' SQL SELECT never returns a top-level `cid` column - it only
// exists nested inside the JSON-decoded `charinfo` - so this has to read
// c.charinfo.cid, not c.cid (which was always undefined).
function byCidMap() {
  return new Map(state.characters.map((c) => [c.charinfo?.cid, c]));
}

function renderSlotSwitcher() {
  slotSwitcher.innerHTML = '';
  for (let i = 1; i <= state.maxSlots; i++) {
    const btn = document.createElement('button');
    btn.className = 'slot-number' + (i === state.focusedSlot ? ' active' : '');
    btn.textContent = String(i);
    btn.addEventListener('click', () => focusSlot(i));
    slotSwitcher.appendChild(btn);
  }
}

// Focuses one slot at a time — previews that character (or the default
// look, for an empty slot) and swaps the dock's primary action between
// ENTER CITY and CREATE CHARACTER. Doesn't act on anything by itself.
function focusSlot(i) {
  state.focusedSlot = i;
  renderSlotSwitcher();

  const charRecord = byCidMap().get(i);
  dock.classList.remove('hidden');

  if (charRecord) {
    state.selectedCitizenId = charRecord.citizenid;
    infoPanel.classList.remove('hidden');
    emptyPanel.classList.add('hidden');
    btnDelete.classList.remove('hidden');
    btnSelect.textContent = 'ENTER CITY';
    btnSelect.dataset.mode = 'enter';
    renderInfoPanel(charRecord);
    nuiPost('previewCharacter', { citizenid: charRecord.citizenid, gender: charRecord.charinfo?.gender ?? 0 });
  } else {
    state.selectedCitizenId = null;
    infoPanel.classList.add('hidden');
    emptyPanel.classList.remove('hidden');
    emptyTitle.textContent = `SLOT ${String(i).padStart(2, '0')}`;
    btnDelete.classList.add('hidden');
    btnSelect.textContent = 'CREATE CHARACTER';
    btnSelect.dataset.mode = 'create';
    nuiPost('previewGender', { gender: 0 });
  }

  setBusy(state.busy);
}

function renderInfoPanel(charRecord) {
  const { charinfo = {}, money = {}, job, gang } = charRecord;

  infoName.textContent = `${charinfo.firstname || ''} ${charinfo.lastname || ''}`.trim() || '—';
  infoSubtitle.textContent = `CHARACTER ${state.focusedSlot} / ${state.maxSlots}`;
  infoGenderIcon.innerHTML = Number(charinfo.gender) === 1 ? ICONS.female : ICONS.male;

  const fields = [
    [ICONS.birthdate, 'Birthdate', charinfo.birthdate || '—'],
    [ICONS.nationality, 'Nationality', charinfo.nationality || '—'],
    [ICONS.account, 'Account Number', charinfo.account || '—'],
    [ICONS.bank, 'Bank', `$${groupDigits(money.bank)}`],
    [ICONS.cash, 'Cash', `$${groupDigits(money.cash)}`],
    [ICONS.job, 'Job', job?.label || 'Unemployed'],
    [ICONS.jobGrade, 'Job Grade', job?.grade?.name || '—'],
    [ICONS.gang, 'Gang', gang?.label || 'None'],
    [ICONS.gangGrade, 'Gang Grade', gang?.grade?.name || '—'],
    [ICONS.phone, 'Phone Number', charinfo.phone || '—'],
  ];

  infoGrid.innerHTML = fields
    .map(([icon, label, value]) => `
      <div class="info-field">
        <div class="info-icon">${icon}</div>
        <div class="info-text">
          <div class="label">${escapeHtml(label)}</div>
          <div class="value">${escapeHtml(String(value))}</div>
        </div>
      </div>
    `)
    .join('');

  infoPanel.classList.remove('hidden');
}

function setGender(gender) {
  state.selectedGender = gender;
  btnGenderMale.classList.toggle('active', gender === 0);
  btnGenderFemale.classList.toggle('active', gender === 1);
  nuiPost('previewGender', { gender });
}

function renderApartments() {
  apartmentList.innerHTML = '';
  state.apartments.forEach((apt) => {
    const card = document.createElement('div');
    card.className = 'apartment-card';
    card.innerHTML = `
      <div class="apartment-label">${escapeHtml(apt.label)}</div>
      <div class="apartment-blurb">${escapeHtml(apt.blurb)}</div>
    `;
    card.addEventListener('click', () => {
      apartmentList.querySelectorAll('.apartment-card').forEach((c) => c.classList.remove('selected'));
      card.classList.add('selected');
      state.selectedApartmentId = apt.id;
      setBusy(state.busy);
    });
    apartmentList.appendChild(card);

    // Only one apartment on file — auto-select it so there's nothing extra
    // to click for the common case, while still showing what it is.
    if (state.apartments.length === 1) card.click();
  });
}

function closeIdentityModal() {
  modalIdentity.classList.add('hidden');
  stepApartment.classList.add('hidden');
  stepIdentity.classList.remove('hidden');
  state.selectedApartmentId = null;
}

function openIdentityModal() {
  inputFirstName.value = '';
  inputLastName.value = '';
  inputBirthdate.value = '';
  inputNationality.value = DEFAULT_NATIONALITY;
  setGender(0);

  stepIdentity.classList.remove('hidden');
  stepApartment.classList.add('hidden');
  modalIdentity.classList.remove('hidden');
}

btnGenderMale.addEventListener('click', () => setGender(0));
btnGenderFemale.addEventListener('click', () => setGender(1));

btnIdentityCancel.addEventListener('click', () => {
  closeIdentityModal();
  focusSlot(state.focusedSlot);
});

btnIdentityNext.addEventListener('click', () => {
  if (!inputFirstName.value.trim() || !inputLastName.value.trim() || !inputBirthdate.value) {
    showToast('error', 'Fill in first name, last name, and date of birth.');
    return;
  }
  stepIdentity.classList.add('hidden');
  stepApartment.classList.remove('hidden');
  renderApartments();
  setBusy(state.busy);
});

btnApartmentBack.addEventListener('click', () => {
  stepApartment.classList.add('hidden');
  stepIdentity.classList.remove('hidden');
});

btnApartmentConfirm.addEventListener('click', async () => {
  if (!state.selectedApartmentId) {
    showToast('error', 'Pick a starting apartment first.');
    return;
  }

  setBusy(true);
  const result = await nuiPost('createCharacter', {
    firstName: inputFirstName.value.trim(),
    lastName: inputLastName.value.trim(),
    birthdate: inputBirthdate.value,
    nationality: inputNationality.value.trim() || DEFAULT_NATIONALITY,
    gender: state.selectedGender,
    apartmentId: state.selectedApartmentId,
  });

  if (result === 'error') {
    setBusy(false);
  } else {
    closeIdentityModal();
  }
});

btnDelete.addEventListener('click', () => {
  if (!state.selectedCitizenId) return;
  const charRecord = state.characters.find((c) => c.citizenid === state.selectedCitizenId);
  const name = charRecord ? `${charRecord.charinfo?.firstname || ''} ${charRecord.charinfo?.lastname || ''}`.trim() : 'this character';
  deleteCharName.textContent = name;
  inputDeleteConfirm.value = '';
  setBusy(state.busy);
  modalDelete.classList.remove('hidden');
});

inputDeleteConfirm.addEventListener('input', () => setBusy(state.busy));

btnDeleteCancel.addEventListener('click', () => modalDelete.classList.add('hidden'));

btnDeleteConfirm.addEventListener('click', async () => {
  setBusy(true);
  await nuiPost('deleteCharacter', { citizenid: state.selectedCitizenId });
  modalDelete.classList.add('hidden');
  setBusy(false);
});

btnSelect.addEventListener('click', async () => {
  if (btnSelect.dataset.mode === 'create') {
    openIdentityModal();
    return;
  }
  if (!state.selectedCitizenId) return;
  const charRecord = state.characters.find((c) => c.citizenid === state.selectedCitizenId);
  if (!charRecord) return;
  setBusy(true);
  await nuiPost('selectCharacter', charRecord);
});

function renderSpawnLocations() {
  spawnList.innerHTML = '';
  state.spawnLocations.forEach((loc) => {
    const card = document.createElement('div');
    card.className = 'spawn-card';
    card.innerHTML = `
      <div class="spawn-label">${escapeHtml(loc.label)}</div>
      <div class="spawn-blurb">${escapeHtml(loc.blurb || '')}</div>
    `;
    card.addEventListener('click', () => {
      spawnList.querySelectorAll('.spawn-card').forEach((c) => c.classList.remove('selected'));
      card.classList.add('selected');
      state.selectedSpawnId = loc.id;
      btnSpawnConfirm.disabled = false;
      // Swaps the hovering preview camera to this location - client.lua
      // just moves it in place, no fade, since this is meant to respond
      // instantly to picking a different option.
      nuiPost('previewSpawnLocation', { id: loc.id });
    });
    spawnList.appendChild(card);
  });

  // First option is focused by default so the preview camera has
  // something to show as soon as the screen appears, not an empty
  // unselected list.
  const firstCard = spawnList.querySelector('.spawn-card');
  if (firstCard) firstCard.click();
}

function openSpawnModal(locations) {
  state.spawnLocations = locations || [];
  state.selectedSpawnId = null;
  btnSpawnConfirm.disabled = true;
  renderSpawnLocations();
  modalSpawn.classList.remove('hidden');
}

btnSpawnConfirm.addEventListener('click', async () => {
  if (!state.selectedSpawnId) return;
  btnSpawnConfirm.disabled = true;
  await nuiPost('selectSpawnLocation', { id: state.selectedSpawnId });
  modalSpawn.classList.add('hidden');
});

function showApp() {
  app.classList.remove('hidden');
  closeIdentityModal();
  modalDelete.classList.add('hidden');
  modalSpawn.classList.add('hidden');
  toast.classList.add('hidden');
  setBusy(false);
}

function hideApp() {
  app.classList.add('hidden');
}

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      showApp();
      break;
    case 'close':
      hideApp();
      break;
    case 'characters': {
      state.characters = data.characters || [];
      state.maxSlots = data.maxSlots || 3;
      // First load defaults to slot 1 (state.focusedSlot's initial value);
      // a refresh after create/delete keeps whatever slot was already
      // focused, clamped in case maxSlots ever shrank.
      focusSlot(Math.min(Math.max(state.focusedSlot || 1, 1), state.maxSlots));
      break;
    }
    case 'apartments':
      state.apartments = data.apartments || [];
      break;
    case 'spawnLocations':
      openSpawnModal(data.locations);
      break;
    case 'notify':
      showToast(data.kind, data.message);
      setBusy(false);
      break;
  }
});
