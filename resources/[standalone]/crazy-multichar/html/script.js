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
  selectedCitizenId: null,
  selectedGender: 0,
  selectedApartmentId: null,
  busy: false,
};

const el = (id) => document.getElementById(id);

const app = el('app');
const slotRow = el('slot-row');
const slotCountCurrent = el('slot-count-current');
const slotCountMax = el('slot-count-max');
const toast = el('toast');

const infoPanel = el('info-panel');
const infoName = el('info-name');
const infoGrid = el('info-grid');

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
const btnDeleteCancel = el('btn-delete-cancel');
const btnDeleteConfirm = el('btn-delete-confirm');

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
  const hasSelection = state.selectedCitizenId !== null;
  btnSelect.disabled = busy || !hasSelection;
  btnDelete.disabled = busy || !hasSelection;
  btnIdentityNext.disabled = busy;
  btnApartmentConfirm.disabled = busy || !state.selectedApartmentId;
  btnDeleteConfirm.disabled = busy;
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

function renderSlots() {
  slotRow.innerHTML = '';

  // qbx_core numbers character slots starting at 1, not 0 — the first
  // character ever created gets cid 1 (see getNextCid() in
  // qbx_core/server/character.lua: `(lastCharacter.charinfo.cid or 0) + 1`).
  const byCid = new Map(state.characters.map((c) => [c.cid, c]));

  for (let i = 1; i <= state.maxSlots; i++) {
    const charRecord = byCid.get(i);
    const card = document.createElement('div');

    if (charRecord) {
      const { charinfo = {}, job } = charRecord;
      card.className = 'slot-card';
      card.innerHTML = `
        <div class="slot-index">SLOT ${String(i).padStart(2, '0')}</div>
        <div class="slot-name">${escapeHtml(charinfo.firstname || '')} ${escapeHtml(charinfo.lastname || '')}</div>
        <div class="slot-meta">${escapeHtml(job?.label || 'Unemployed')}</div>
      `;
      card.addEventListener('click', () => selectCharacterCard(card, charRecord));
    } else {
      card.className = 'slot-card empty';
      card.innerHTML = `
        <div class="slot-index">SLOT ${String(i).padStart(2, '0')}</div>
        <div class="slot-plus">+</div>
        <div class="slot-name">NEW CHARACTER</div>
      `;
      card.addEventListener('click', () => openIdentityModal());
    }

    slotRow.appendChild(card);
  }

  slotCountCurrent.textContent = state.characters.length;
  slotCountMax.textContent = state.maxSlots;
}

function renderInfoPanel(charRecord) {
  const { charinfo = {}, money = {}, job, gang } = charRecord;

  infoName.textContent = `${charinfo.firstname || ''} ${charinfo.lastname || ''}`.trim() || '—';

  const fields = [
    ['Gender', genderLabel(charinfo.gender)],
    ['Birthdate', charinfo.birthdate || '—'],
    ['Nationality', charinfo.nationality || '—'],
    ['Account Number', charinfo.account || '—'],
    ['Bank', `$${groupDigits(money.bank)}`],
    ['Cash', `$${groupDigits(money.cash)}`],
    ['Job', job?.label || 'Unemployed'],
    ['Job Grade', job?.grade?.name || '—'],
    ['Gang', gang?.label || 'None'],
    ['Gang Grade', gang?.grade?.name || '—'],
    ['Phone Number', charinfo.phone || '—'],
  ];

  infoGrid.innerHTML = fields
    .map(([label, value]) => `
      <div class="info-field">
        <div class="label">${escapeHtml(label)}</div>
        <div class="value">${escapeHtml(String(value))}</div>
      </div>
    `)
    .join('');

  infoPanel.classList.remove('hidden');
}

function selectCharacterCard(cardEl, charRecord) {
  slotRow.querySelectorAll('.slot-card').forEach((c) => c.classList.remove('selected'));
  cardEl.classList.add('selected');
  state.selectedCitizenId = charRecord.citizenid;
  dock.classList.remove('hidden');
  renderInfoPanel(charRecord);
  setBusy(state.busy);
  nuiPost('previewCharacter', { citizenid: charRecord.citizenid, gender: charRecord.charinfo?.gender ?? 0 });
}

function clearSelection() {
  slotRow.querySelectorAll('.slot-card').forEach((c) => c.classList.remove('selected'));
  state.selectedCitizenId = null;
  dock.classList.add('hidden');
  infoPanel.classList.add('hidden');
  setBusy(state.busy);
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
  clearSelection();

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
  const firstCard = slotRow.querySelector('.slot-card:not(.empty)');
  if (firstCard && state.characters[0]) selectCharacterCard(firstCard, state.characters[0]);
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
  if (!state.selectedApartmentId) return;

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
  modalDelete.classList.remove('hidden');
});

btnDeleteCancel.addEventListener('click', () => modalDelete.classList.add('hidden'));

btnDeleteConfirm.addEventListener('click', async () => {
  setBusy(true);
  await nuiPost('deleteCharacter', { citizenid: state.selectedCitizenId });
  modalDelete.classList.add('hidden');
  setBusy(false);
});

btnSelect.addEventListener('click', async () => {
  if (!state.selectedCitizenId) return;
  const charRecord = state.characters.find((c) => c.citizenid === state.selectedCitizenId);
  if (!charRecord) return;
  setBusy(true);
  await nuiPost('selectCharacter', charRecord);
});

function showApp() {
  app.classList.remove('hidden');
  closeIdentityModal();
  modalDelete.classList.add('hidden');
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
      renderSlots();

      const firstCard = slotRow.querySelector('.slot-card:not(.empty)');
      if (firstCard && state.characters[0]) {
        selectCharacterCard(firstCard, state.characters[0]);
      } else {
        clearSelection();
      }
      break;
    }
    case 'apartments':
      state.apartments = data.apartments || [];
      break;
    case 'notify':
      showToast(data.kind, data.message);
      setBusy(false);
      break;
  }
});
