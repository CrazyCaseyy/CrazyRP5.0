// NUI contract with client/main.lua:
//   inbound (SendNUIMessage):  { action: 'open', jobs: [{ name, label, level,
//     xp, xpIntoLevel, xpForNextLevel, maxLevel }] } | { action: 'close' }
//   outbound (RegisterNUICallback): 'close'
//
// Real per-player, per-job reputation data comes from server/reputation.lua
// via the getCivilianJobs callback - each job expands into its actual
// level track (current level highlighted, lower levels marked done, higher
// ones locked) with real XP progress toward the next level.

const el = (id) => document.getElementById(id);

const app = el('app');
const jobGrid = el('job-grid');
const btnClose = el('btn-close');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-reputation';
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
const CHEVRON_ICON = '<svg viewBox="0 0 24 24"><path d="M6 9l6 6 6-6" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/></svg>';

const LEVEL_COUNT = 10;

// Cosmetic tier names shown under each dot - purely a label, the actual
// level/progress values always come from the server.
const LEVEL_NAMES = [
  'Newcomer', 'Novice', 'Apprentice', 'Regular', 'Skilled',
  'Experienced', 'Veteran', 'Expert', 'Elite', 'Master',
];

function renderLevelTrack(job) {
  const maxLevel = job.maxLevel || LEVEL_COUNT;
  const currentLevel = job.level || 1;
  const fillPct = ((currentLevel - 1) / (maxLevel - 1)) * 100;

  let dots = '';
  for (let level = 1; level <= maxLevel; level++) {
    const isCurrent = level === currentLevel;
    const isDone = level < currentLevel;
    const state = isCurrent ? 'is-current' : isDone ? 'is-done' : 'is-locked';
    const name = LEVEL_NAMES[level - 1] || `Level ${level}`;
    dots += `
      <div class="job-level-dot ${state}" title="Level ${level}: ${name}">
        <span class="job-level-dot-inner"></span>
        <span class="job-level-dot-label">${name}</span>
      </div>`;
  }

  return `
    <div class="job-level-track">
      <div class="job-level-line"></div>
      <div class="job-level-line-fill" style="width:${fillPct}%"></div>
      <div class="job-level-dots">${dots}</div>
    </div>`;
}

function repValueText(job) {
  const level = job.level || 1;
  if (!job.xpForNextLevel || job.xpForNextLevel <= 0) {
    return `Level ${level} — Max Level`;
  }
  return `Level ${level} — ${job.xpIntoLevel ?? 0} / ${job.xpForNextLevel} XP`;
}

function renderJobs(jobs) {
  if (!jobs || !jobs.length) {
    jobGrid.innerHTML = '<div class="empty-state">No civilian jobs found.</div>';
    return;
  }

  jobGrid.innerHTML = jobs
    .map(
      (job) => `
        <div class="job-card">
          <button type="button" class="job-header">
            <div class="job-icon">${BRIEFCASE_ICON}</div>
            <div class="job-info">
              <div class="job-label">${escapeHtml(job.label)}</div>
              <div class="job-rep-value">${repValueText(job)}</div>
            </div>
            <div class="job-chevron">${CHEVRON_ICON}</div>
          </button>
          <div class="job-levels">
            ${renderLevelTrack(job)}
          </div>
        </div>
      `
    )
    .join('');
}

jobGrid.addEventListener('click', (e) => {
  const header = e.target.closest('.job-header');
  if (!header) return;
  header.closest('.job-card').classList.toggle('expanded');
});

function closeTablet() {
  app.classList.add('hidden');
  nuiPost('close');
}

btnClose.addEventListener('click', closeTablet);

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') closeTablet();
});

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      renderJobs(data.jobs);
      app.classList.remove('hidden');
      break;
    case 'close':
      app.classList.add('hidden');
      break;
  }
});

// Standalone browser preview: outside the game there's no NUI postMessage
// to open the tablet, so if we're not running inside CEF, show it
// immediately with the same 5 jobs Config.IncludedJobs actually allows,
// using sample level/XP progress (matching config.lua's curve) to show
// off what a real, in-progress reputation looks like at different stages.
if (typeof GetParentResourceName === 'undefined') {
  renderJobs([
    { name: 'bus', label: 'Bus', level: 1, xp: 40, xpIntoLevel: 40, xpForNextLevel: 150, maxLevel: 10 },
    { name: 'garbage', label: 'Garbage', level: 3, xp: 510, xpIntoLevel: 120, xpForNextLevel: 330, maxLevel: 10 },
    { name: 'taxi', label: 'Taxi', level: 6, xp: 1850, xpIntoLevel: 200, xpForNextLevel: 600, maxLevel: 10 },
    { name: 'tow', label: 'Towing', level: 9, xp: 4020, xpIntoLevel: 300, xpForNextLevel: 870, maxLevel: 10 },
    { name: 'trucker', label: 'Trucker', level: 10, xp: 4590, xpIntoLevel: 0, xpForNextLevel: 0, maxLevel: 10 },
  ]);
  app.classList.remove('hidden');
}
