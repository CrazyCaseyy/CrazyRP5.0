const app = document.getElementById('app');
const stepList = document.getElementById('step-list');
const btnClose = document.getElementById('btn-close');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-tutorial';
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

function render(steps) {
  stepList.innerHTML = '';
  steps.forEach((step, i) => {
    const card = document.createElement('div');
    card.className = 'step-card' + (step.done ? ' is-complete' : '');
    card.dataset.id = step.id;
    card.innerHTML = `
      <div class="step-icon">
        <span class="step-num">${i + 1}</span>
        <svg class="step-check" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"><polyline points="20 6 9 17 4 12"></polyline></svg>
      </div>
      <div class="step-info">
        <div class="step-label">${escapeHtml(step.label)}</div>
        ${step.description ? `<div class="step-description">${escapeHtml(step.description)}</div>` : ''}
      </div>
    `;
    stepList.appendChild(card);
  });
}

function closePanel() {
  app.classList.add('hidden');
  nuiPost('close');
}

btnClose.addEventListener('click', closePanel);

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closePanel();
});

window.addEventListener('message', (event) => {
  const data = event.data;

  if (data.action === 'show') {
    render(data.steps);
    app.classList.remove('hidden');
  } else if (data.action === 'markStep') {
    const card = stepList.querySelector(`[data-id="${data.id}"]`);
    if (card) card.classList.add('is-complete');
  } else if (data.action === 'hide') {
    app.classList.add('hidden');
  }
});
