// NUI contract with client/main.lua — purely one-way (SendNUIMessage), this
// page never posts back to Lua, there's nothing here for it to request.
// inbound actions: { action: 'show', stage } | { action: 'update', stage, seconds } | { action: 'hide' }

const el = (id) => document.getElementById(id);

// A believable heartbeat trace vs. a dead-flat line, drawn once and swapped
// on stage change rather than redrawn every tick.
const ECG_PATH_BEATING = 'M0 23 L60 23 L72 6 L84 40 L96 12 L108 23 L150 23 L162 8 L174 34 L186 23 L260 23';
const ECG_PATH_FLAT = 'M0 23 L260 23';

function formatTime(totalSeconds) {
  const s = Math.max(0, Math.ceil(Number(totalSeconds) || 0));
  const m = Math.floor(s / 60);
  const r = s % 60;
  return `${String(m).padStart(2, '0')}:${String(r).padStart(2, '0')}`;
}

function applyStage(stage) {
  const panel = el('deathPanel');
  const vignette = el('vignette');
  const heart = el('heartIcon');
  const ecg = el('ecgPath');

  panel.classList.remove('hidden');
  panel.classList.toggle('dead', stage === 'dead');
  vignette.classList.remove('laststand', 'dead');
  vignette.classList.add(stage === 'dead' ? 'dead' : 'laststand');

  if (stage === 'dead') {
    el('stageLabel').textContent = 'Dead';
    el('hint').textContent = 'Hold [E] to respawn early, or wait it out';
    heart.classList.remove('beating');
    heart.classList.add('flatlined');
    ecg.setAttribute('d', ECG_PATH_FLAT);
    ecg.classList.remove('sweeping');
    ecg.classList.add('flat');
  } else {
    el('stageLabel').textContent = 'Knocked Out';
    el('hint').textContent = 'Wait for help, or someone nearby can revive you';
    heart.classList.add('beating');
    heart.classList.remove('flatlined');
    ecg.setAttribute('d', ECG_PATH_BEATING);
    ecg.classList.add('sweeping');
    ecg.classList.remove('flat');
  }
}

function updateStage(data) {
  el('timer').textContent = formatTime(data.seconds);
}

function hideScreen() {
  el('deathPanel').classList.add('hidden');
  el('vignette').classList.remove('laststand', 'dead');
}

window.addEventListener('message', (event) => {
  const data = event.data || {};
  if (data.action === 'show') {
    applyStage(data.stage);
    el('timer').textContent = data.stage === 'dead' ? '05:00' : '06:00';
  } else if (data.action === 'update') {
    updateStage(data);
  } else if (data.action === 'hide') {
    hideScreen();
  }
});
