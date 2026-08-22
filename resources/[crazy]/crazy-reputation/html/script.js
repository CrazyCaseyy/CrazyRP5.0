// NUI contract with client/main.lua:
//   inbound (SendNUIMessage):  { action: 'open', jobs: [{ name, label }] } | { action: 'close' }
//   outbound (RegisterNUICallback): 'close'
//
// UI-only pass - no real reputation data exists yet (that's a later,
// separate build). Each job expands into a 10-level list with level 1
// shown as current and the rest locked, as a placeholder wired up so real
// per-player progress can drive it once the reputation system exists.

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

// UI-only placeholder: every job starts at level 1 with the rest locked
// until the real reputation system exists to drive progress for real.
const CURRENT_LEVEL = 1;

// Placeholder tier names - purely cosmetic until the real reputation
// system defines what each level actually represents per job.
const LEVEL_NAMES = [
  'Newcomer', 'Novice', 'Apprentice', 'Regular', 'Skilled',
  'Experienced', 'Veteran', 'Expert', 'Elite', 'Master',
];

function renderLevelTrack() {
  const fillPct = ((CURRENT_LEVEL - 1) / (LEVEL_COUNT - 1)) * 100;

  let dots = '';
  for (let level = 1; level <= LEVEL_COUNT; level++) {
    const isCurrent = level === CURRENT_LEVEL;
    const isDone = level < CURRENT_LEVEL;
    const state = isCurrent ? 'is-current' : isDone ? 'is-done' : 'is-locked';
    const name = LEVEL_NAMES[level - 1];
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
              <div class="job-rep-value">Not tracked yet</div>
            </div>
            <div class="job-chevron">${CHEVRON_ICON}</div>
          </button>
          <div class="job-levels">
            ${renderLevelTrack()}
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
// immediately with the same civilian job list qbx_core actually has
// (mirrored from qbx_core/shared/jobs.lua, minus leo/ems/unemployed), so
// the preview matches what's shown in-game.
if (typeof GetParentResourceName === 'undefined') {
  renderJobs([
    { name: 'realestate', label: 'Real Estate' },
    { name: 'taxi', label: 'Taxi' },
    { name: 'bus', label: 'Bus' },
    { name: 'cardealer', label: 'Vehicle Dealer' },
    { name: 'mechanic', label: 'Mechanic' },
    { name: 'judge', label: 'Honorary' },
    { name: 'lawyer', label: 'Law Firm' },
    { name: 'reporter', label: 'Reporter' },
    { name: 'trucker', label: 'Trucker' },
    { name: 'tow', label: 'Towing' },
    { name: 'garbage', label: 'Garbage' },
    { name: 'vineyard', label: 'Vineyard' },
    { name: 'hotdog', label: 'Hotdog' },
    { name: 'koi', label: 'Koi' },
    { name: 'upnatom', label: 'Up n Atom' },
    { name: 'hornys', label: "Horny's" },
    { name: 'beanmachine', label: 'Bean Machine' },
    { name: 'burgershot', label: 'BurgerShot' },
    { name: 'catcafe', label: 'Cat Cafe' },
    { name: 'pizzathis', label: 'Pizza This' },
    { name: 'lscustoms', label: 'LS Customs' },
    { name: 'redline', label: 'Redline Mechanic' },
    { name: 'ottos', label: 'Ottos Autos' },
    { name: 'standcustoms', label: 'Stand Customs' },
    { name: 'eastcustoms', label: 'East Customs' },
    { name: 'beekers', label: 'Beekers' },
    { name: 'bennys', label: 'Bennys' },
    { name: 'tunershop', label: 'Tunershop' },
    { name: 'importshop', label: 'Importshop' },
    { name: 'hayes', label: 'Hayes' },
    { name: 'reaper', label: 'Reaper Mechanic' },
    { name: 'harmony', label: 'Harmony' },
    { name: 'exotic', label: 'Exotics' },
    { name: 'dreamworks', label: 'Dreamwork Customs' },
    { name: 'mirrorparkmech', label: 'Mirrior Park Customs' },
    { name: 'thommy', label: 'Thommy' },
    { name: 'youtuber', label: 'Rockstar' },
    { name: 'customped', label: 'Custom Ped' },
  ]);
  app.classList.remove('hidden');
}
