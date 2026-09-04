// NUI contract with client/main.lua:
//   inbound (SendNUIMessage): { action: 'open', rewards: Reward[] } |
//     { action: 'spin', rewardId, result: { rewardId, amount?, count? } } |
//     { action: 'close' }
//   outbound (RegisterNUICallback): 'close' | 'rollCase' | 'tick' |
//     'reveal' ({ rarity })
//
// Reward shape (from config.lua): { id, type: 'cash'|'item', item?,
//   label, rarity, amount? ([min,max], cash only), image? (true = use
//   the real ox_inventory icon for `item`) }
//
// Flow: 'open' shows the case with an Open button - nothing is rolled or
// removed yet. Clicking it posts 'rollCase', which is what actually
// consumes the case and rolls a reward server-side; the reply comes back
// as a 'spin' message with the predetermined winner. The reward itself
// isn't granted until the reel actually lands and posts 'reveal'.

const el = (id) => document.getElementById(id);

const app = el('app');
const reelTrack = el('reel-track');
const idleState = el('idle-state');
const resultPanel = el('result-panel');
const btnClose = el('btn-close');
const btnOpen = el('btn-open');

function resourceName() {
  return window.GetParentResourceName ? GetParentResourceName() : 'crazy-caseopening';
}

async function nuiPost(name, data = {}) {
  try {
    await fetch(`https://${resourceName()}/${name}`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json; charset=UTF-8' },
      body: JSON.stringify(data),
    });
  } catch (e) {
    // Nothing to recover here - focus is already moving on regardless.
  }
}

function escapeHtml(str) {
  const div = document.createElement('div');
  div.textContent = str ?? '';
  return div.innerHTML;
}

// No FontAwesome bundled into this page (only ox_lib's own NUI ships
// that) - plain inline SVG, same approach crazy-dailytasks uses. Only
// used as a last-resort fallback - every cash reward uses ox_inventory's
// own money.png, and every item reward has its own real ox_inventory
// image.
const DOLLAR_ICON = '<svg viewBox="0 0 24 24"><path d="M12 1v22M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/></svg>';

function formatMoney(n) {
  return `$${n.toLocaleString()}`;
}

// Picture only - the amount is shown as the card's label text instead
// (see cardLabel below), not baked into this.
function rewardIconHtml(reward) {
  if (reward.type === 'cash') {
    return `<img src="nui://ox_inventory/web/images/money.png" />`;
  }
  if (reward.image) {
    // `image: true` = ox_inventory's default filename-equals-item-key
    // convention; a string means items.lua's own client.image override
    // doesn't match the item key (e.g. cash_band -> cashband.png), so
    // config.lua spells out the real filename instead.
    const file = reward.image === true ? `${reward.item}.png` : reward.image;
    return `<img src="nui://ox_inventory/web/images/${file}" />`;
  }
  return DOLLAR_ICON;
}

// A specific-looking number for the reel's scrolling filler cards, which
// aren't tied to any real roll - same idea as the filler item cards not
// being the actual reward either, just visual variety.
function randomCashAmount(reward) {
  const [min, max] = reward.amount;
  return Math.floor(min + Math.random() * (max - min));
}

// exactAmount is only known for the one card that's actually about to
// win (see buildReel) - every other cash card just shows a plausible
// random figure from its own range.
function cardLabel(reward, exactAmount) {
  if (reward.type === 'cash') {
    return formatMoney(exactAmount != null ? exactAmount : randomCashAmount(reward));
  }
  return reward.label;
}

const CARD_WIDTH = 140;
const CARD_GAP = 10;
const SLOT = CARD_WIDTH + CARD_GAP;
const REEL_LENGTH = 60;
const WINNING_INDEX = 50;
const SPIN_MS = 6000;

let rewardPool = [];
let lastTickIndex = -1;
let tickInterval = null;

function buildCard(reward, exactAmount) {
  const div = document.createElement('div');
  div.className = `reel-card rarity-${reward.rarity}`;
  div.innerHTML = `${rewardIconHtml(reward)}<div class="reel-card-label">${escapeHtml(cardLabel(reward, exactAmount))}</div>`;
  return div;
}

function randomReward() {
  return rewardPool[Math.floor(Math.random() * rewardPool.length)];
}

function buildReel(winningRewardId, result) {
  reelTrack.innerHTML = '';
  reelTrack.style.transition = 'none';
  reelTrack.style.transform = 'translateX(0px)';
  // Force the transition:none to apply before anything else touches
  // transform, or the browser can coalesce it with the next frame.
  void reelTrack.offsetWidth;

  const winning = rewardPool.find((r) => r.id === winningRewardId) || rewardPool[0];

  const frag = document.createDocumentFragment();
  for (let i = 0; i < REEL_LENGTH; i++) {
    if (i === WINNING_INDEX) {
      frag.appendChild(buildCard(winning, result.amount));
    } else {
      frag.appendChild(buildCard(randomReward()));
    }
  }
  reelTrack.appendChild(frag);
}

function currentTranslateX() {
  const matrix = new DOMMatrixReadOnly(getComputedStyle(reelTrack).transform);
  return matrix.m41;
}

function spinTo(winningRewardId, result) {
  idleState.classList.add('hidden');
  resultPanel.classList.add('hidden');
  buildReel(winningRewardId, result);
  lastTickIndex = -1;

  // Small random offset within the winning card so it doesn't always
  // stop dead center - reads more like a real spin.
  const jitter = (Math.random() - 0.5) * (CARD_WIDTH * 0.5);
  const targetX = -(WINNING_INDEX * SLOT + CARD_WIDTH / 2 - jitter);

  requestAnimationFrame(() => {
    reelTrack.style.transition = `transform ${SPIN_MS}ms cubic-bezier(0.12, 0.65, 0.15, 1)`;
    reelTrack.style.transform = `translateX(${targetX}px)`;
  });

  if (tickInterval) clearInterval(tickInterval);
  tickInterval = setInterval(() => {
    const index = Math.round(-currentTranslateX() / SLOT);
    if (index !== lastTickIndex) {
      lastTickIndex = index;
      nuiPost('tick');
    }
  }, 40);

  setTimeout(() => {
    clearInterval(tickInterval);
    tickInterval = null;
    showResult(result);
  }, SPIN_MS + 150);
}

function showResult(result) {
  const reward = rewardPool.find((r) => r.id === result.rewardId);
  if (!reward) return;

  const rarityColor = `var(--rarity-${reward.rarity})`;

  el('result-rarity').textContent = reward.rarity.toUpperCase();
  el('result-rarity').style.color = rarityColor;
  el('result-icon').innerHTML = rewardIconHtml(reward);
  el('result-icon').style.color = rarityColor;

  let label = cardLabel(reward, result.amount);
  if (reward.type === 'item' && result.count > 1) label = `${label} x${result.count}`;
  el('result-label').textContent = label;
  el('result-label').style.color = rarityColor;

  el('result-value').textContent = result.amount ? 'Added to your bank' : 'Added to your inventory';

  resultPanel.classList.remove('hidden');
  nuiPost('reveal', { rarity: reward.rarity });
}

function closeBox() {
  app.classList.add('hidden');
  resultPanel.classList.add('hidden');
  idleState.classList.remove('hidden');
  if (tickInterval) {
    clearInterval(tickInterval);
    tickInterval = null;
  }
  nuiPost('close');
}

btnClose.addEventListener('click', closeBox);

btnOpen.addEventListener('click', () => {
  btnOpen.disabled = true;
  nuiPost('rollCase');
});

document.addEventListener('keydown', (e) => {
  if (e.key === 'Escape' && !resultPanel.classList.contains('hidden')) closeBox();
  // Backing out before actually opening is free - nothing's been rolled
  // or removed yet at this point.
  if (e.key === 'Escape' && !idleState.classList.contains('hidden')) closeBox();
});

window.addEventListener('message', ({ data }) => {
  switch (data.action) {
    case 'open':
      rewardPool = data.rewards;
      reelTrack.innerHTML = '';
      btnOpen.disabled = false;
      idleState.classList.remove('hidden');
      resultPanel.classList.add('hidden');
      app.classList.remove('hidden');
      break;
    case 'spin':
      spinTo(data.rewardId, data.result);
      break;
    case 'close':
      closeBox();
      break;
  }
});

// Standalone browser preview: outside the game there's no real client.lua
// on the other end of nuiPost, so fake just enough of a response to
// exercise the real button/message flow (not a separate spin call) for
// design review.
if (typeof GetParentResourceName === 'undefined') {
  rewardPool = [
    { id: 'cash_small', type: 'cash', label: 'Petty Cash', rarity: 'common', amount: [50, 100] },
    { id: 'cash_small2', type: 'cash', label: 'Loose Change', rarity: 'common', amount: [100, 150] },
    { id: 'cash_med', type: 'cash', label: 'Decent Stack', rarity: 'uncommon', amount: [200, 350] },
    { id: 'cash_med2', type: 'cash', label: 'Fat Stack', rarity: 'uncommon', amount: [350, 500] },
    { id: 'cash_big', type: 'cash', label: 'Big Money', rarity: 'rare', amount: [750, 1200] },
    { id: 'diamond_ring', type: 'item', item: 'diamond_ring', label: 'Diamond', rarity: 'rare', image: true },
    { id: 'rolex', type: 'item', item: 'rolex', label: 'Golden Watch', rarity: 'rare', image: true },
    { id: 'goldchain', type: 'item', item: 'goldchain', label: 'Golden Chain', rarity: 'rare', image: true },
    { id: 'goldbar', type: 'item', item: 'goldbar', label: 'Gold Bar', rarity: 'epic', image: true },
    { id: 'jackpot', type: 'cash', label: 'JACKPOT', rarity: 'legendary', amount: [8500, 10000] },
  ];

  const realNuiPost = nuiPost;
  nuiPost = async (name, data = {}) => {
    if (name === 'rollCase') {
      window.postMessage({ action: 'spin', rewardId: 'goldbar', result: { rewardId: 'goldbar' } }, '*');
      return;
    }
    return realNuiPost(name, data);
  };

  window.postMessage({ action: 'open', rewards: rewardPool }, '*');
}
