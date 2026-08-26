const app = document.getElementById('app');
const track = document.getElementById('bar-track');
const marker = document.getElementById('bar-marker');
const zoneEls = [
  document.getElementById('zone-0'),
  document.getElementById('zone-1'),
  document.getElementById('zone-2'),
];

function freezeMarker() {
  // getComputedStyle resolves the marker's current interpolated position
  // even mid-transition, so pinning it here just stops it where it is
  // instead of snapping back or continuing to slide.
  const currentLeft = getComputedStyle(marker).left;
  marker.style.transition = 'none';
  marker.style.left = currentLeft;
}

function startRun(duration, zones) {
  app.classList.remove('hidden', 'is-fail', 'is-success');

  zones.forEach((zone, i) => {
    const el = zoneEls[i];
    if (!el) return;
    el.classList.remove('is-hit');
    el.style.left = `${zone.min}%`;
    el.style.width = `${zone.max - zone.min}%`;
  });

  marker.style.transition = 'none';
  marker.style.left = '0%';

  // Force a reflow so the browser commits the "left: 0%, no transition"
  // state above before the next frame re-enables the transition and
  // moves it - otherwise it just jumps straight to 100% with no animation.
  void marker.offsetWidth;

  requestAnimationFrame(() => {
    marker.style.transition = `left ${duration}ms linear`;
    marker.style.left = '100%';
  });
}

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'start':
      startRun(data.duration, data.zones);
      break;
    case 'hitZone': {
      const el = zoneEls[data.index - 1];
      if (el) el.classList.add('is-hit');
      break;
    }
    case 'fail':
      freezeMarker();
      app.classList.add('is-fail');
      break;
    case 'success':
      freezeMarker();
      app.classList.add('is-success');
      break;
    case 'hide':
      app.classList.add('hidden');
      break;
  }
});
