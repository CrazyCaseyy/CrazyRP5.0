// NUI contract with client/main.lua:
//   inbound (SendNUIMessage):  { action: 'open'|'update', tasks: [{ job,
//     label, target, progress, completed }] } | { action: 'close' }
//   outbound (RegisterNUICallback): 'close'

const el = (id) => document.getElementById(id);

const app = el('app');
const taskList = el('task-list');
const btnClose = el('btn-close');

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

function renderTasks(tasks) {
  if (!tasks || !tasks.length) {
    taskList.innerHTML = '<div class="empty-state">No tasks assigned. Check back tomorrow.</div>';
    return;
  }

  taskList.innerHTML = tasks
    .map((task) => {
      const pct = Math.min(100, Math.round((task.progress / task.target) * 100));
      return `
        <div class="task-card ${task.completed ? 'is-complete' : ''}">
          <div class="task-icon">${task.completed ? CHECK_ICON : BRIEFCASE_ICON}</div>
          <div class="task-info">
            <div class="task-top-row">
              <div class="task-label">${escapeHtml(task.label)}</div>
              <div class="task-reward">${task.completed ? 'Claimed' : '+1 Case'}</div>
            </div>
            <div class="task-progress-bar"><div class="task-progress-fill" style="width:${pct}%"></div></div>
            <div class="task-progress-text">${task.progress} / ${task.target} completed</div>
          </div>
        </div>
      `;
    })
    .join('');
}

function closeBox() {
  app.classList.add('hidden');
  nuiPost('close');
}

btnClose.addEventListener('click', closeBox);

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
    { job: 'garbage', label: 'Garbage', target: 3, progress: 3, completed: true },
  ]);
  app.classList.remove('hidden');
}
