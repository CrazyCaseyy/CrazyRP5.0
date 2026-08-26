const app = document.getElementById('app');
const rulesList = document.getElementById('rules-list');
const btnClose = document.getElementById('btn-close');
const btnConfirm = document.getElementById('btn-confirm');
const acceptCheckbox = document.getElementById('accept-checkbox');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-rules';
}

async function nuiPost(name, data = {}) {
  try {
    await fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
  } catch (e) {
    // NUI focus is already going away regardless - nothing to recover here.
  }
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

function renderRules(rules) {
  rulesList.innerHTML = (rules || [])
    .map((rule, i) => `<li data-index="${i + 1}">${escapeHtml(rule)}</li>`)
    .join('');
}

function closeBox() {
  app.classList.add('hidden');
  nuiPost('close');
}

function resetAccept() {
  acceptCheckbox.checked = false;
  btnConfirm.disabled = true;
  btnConfirm.classList.remove('is-ready');
}

acceptCheckbox.addEventListener('change', () => {
  btnConfirm.disabled = !acceptCheckbox.checked;
  btnConfirm.classList.toggle('is-ready', acceptCheckbox.checked);
});

btnConfirm.addEventListener('click', () => {
  if (btnConfirm.disabled) return;
  app.classList.add('hidden');
  nuiPost('accept');
});

btnClose.addEventListener('click', closeBox);

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeBox();
});

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      resetAccept();
      renderRules(data.rules);
      app.classList.remove('hidden');
      break;
    case 'close':
      app.classList.add('hidden');
      break;
  }
});
