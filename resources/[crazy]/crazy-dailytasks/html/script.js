// NUI contract with client/main.lua:
//   inbound (SendNUIMessage):  { action: 'open'|'update', tasks: [{ job,
//     label, target, progress, completed, claimed }] } | { action: 'close' }
//   outbound (RegisterNUICallback): 'close' | 'setWaypoint' ({ job }) |
//     'claimRewards'

const el = (id) => document.getElementById(id);

const app = el('app');
const taskList = el('task-list');
const btnClose = el('btn-close');
const btnClaim = el('btn-claim');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-dailytasks';
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

const BRIEFCASE_ICON = '<svg viewBox="0 0 24 24"><rect x="3" y="8" width="18" height="12" rx="2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M9 8V6a2 2 0 0 1 2-2h2a2 2 0 0 1 2 2v2" fill="none" stroke="currentColor" stroke-width="1.6"/><path d="M3 13h18" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';
const CHECK_ICON = '<svg viewBox="0 0 24 24"><path d="M5 13l4 4L19 7" fill="none" stroke="currentColor" stroke-width="2.2" stroke-linecap="round" stroke-linejoin="round"/></svg>';
const PIN_ICON = '<svg viewBox="0 0 24 24"><path d="M12 21s7-6.3 7-12a7 7 0 1 0-14 0c0 5.7 7 12 7 12z" fill="none" stroke="currentColor" stroke-width="1.6"/><circle cx="12" cy="9" r="2.3" fill="none" stroke="currentColor" stroke-width="1.6"/></svg>';

function renderTasks(tasks) {
  if (!tasks || !tasks.length) {
    taskList.innerHTML = '<div class="empty-state">No tasks assigned. Check back tomorrow.</div>';
    btnClaim.classList.add('hidden');
    return;
  }

  const hasUnclaimed = tasks.some((task) => task.completed && !task.claimed);
  btnClaim.classList.toggle('hidden', !hasUnclaimed);

  taskList.innerHTML = tasks
    .map((task) => {
      const pct = Math.min(100, Math.round((task.progress / task.target) * 100));
      const ready = task.completed && !task.claimed;
      const cardClass = task.completed ? (ready ? 'is-complete is-ready' : 'is-complete is-claimed') : '';
      let rewardText = '+1 Case';
      if (ready) rewardText = 'Ready to Claim';
      else if (task.claimed) rewardText = 'Claimed';
      return `
        <div class="task-card ${cardClass}">
          <div class="task-icon">${task.completed ? CHECK_ICON : BRIEFCASE_ICON}</div>
          <div class="task-info">
            <div class="task-top-row">
              <div class="task-label">${escapeHtml(task.label)}</div>
              <div class="task-reward">${rewardText}</div>
            </div>
            <div class="task-progress-bar"><div class="task-progress-fill" style="width:${pct}%"></div></div>
            <div class="task-progress-text">${task.progress} / ${task.target} completed</div>
            <button class="task-waypoint-btn" data-job="${escapeHtml(task.job)}">${PIN_ICON}Set Waypoint</button>
          </div>
        </div>
      `;
    })
    .join('');

  taskList.querySelectorAll('.task-waypoint-btn').forEach((btn) => {
    btn.addEventListener('click', () => nuiPost('setWaypoint', { job: btn.dataset.job }));
  });
}

function closeBox() {
  app.classList.add('hidden');
  nuiPost('close');
}

btnClose.addEventListener('click', closeBox);
btnClaim.addEventListener('click', () => nuiPost('claimRewards'));

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeBox();
});

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      renderTasks(data.tasks);
      app.classList.remove('hidden');
      break;
    case 'update':
      renderTasks(data.tasks);
      break;
    case 'close':
      app.classList.add('hidden');
      break;
  }
});

// Standalone browser preview: outside the game there's no NUI postMessage
// to open the box, so if we're not running inside CEF, show it immediately
// with sample tasks in different progress states for design review.
if (typeof GetParentResourceName === 'undefined') {
  renderTasks([
    { job: 'taxi', label: 'Taxi', target: 6, progress: 2, completed: false },
    { job: 'tow', label: 'Towing', target: 5, progress: 4, completed: false },
    { job: 'garbage', label: 'Garbage', target: 3, progress: 3, completed: true, claimed: false },
    { job: 'bus', label: 'Bus', target: 5, progress: 5, completed: true, claimed: true },
  ]);
  app.classList.remove('hidden');
}
