'use strict';

// ─────────────────────────────────────────────────────────────────
//  State
// ─────────────────────────────────────────────────────────────────

let mode       = 'craft'; // 'craft' | 'supply'
let recipes    = [];
let supplies   = [];
let stashId    = null;
let quantities = {};
let queue      = [];
let purchases  = [];
let craftRAF   = null;

// ─────────────────────────────────────────────────────────────────
//  NUI fetch helper
// ─────────────────────────────────────────────────────────────────

function nuiFetch(endpoint, data) {
    return fetch(`https://${GetParentResourceName()}/${endpoint}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data ?? {}),
    }).then(r => r.json()).catch(() => ({}));
}

// ─────────────────────────────────────────────────────────────────
//  Inbound NUI messages from Lua
// ─────────────────────────────────────────────────────────────────

window.addEventListener('message', (event) => {
    const { action, data } = event.data;

    switch (action) {

        case 'open':
            mode       = 'craft';
            recipes    = event.data.recipes || [];
            stashId    = event.data.stashId;
            quantities = {};
            queue      = [];
            recipes.forEach(r => { quantities[r.id] = 1; });
            setPanelMode('craft');
            document.getElementById('biz-label').textContent = event.data.business || '';
            document.getElementById('search').value = '';
            document.getElementById('app').style.display = '';
            renderRecipes(recipes);

            // Restore any in-progress queue from the server
            (event.data.queue || []).forEach(qi => {
                const recipe = recipes.find(r => r.id === qi.recipeId);
                if (!recipe) return;
                const entry = { queueId: qi.queueId, recipe, qty: qi.qty, crafting: qi.crafting };
                queue.push(entry);
                if (qi.crafting) startCraftAnim(entry, qi.elapsedMs || 0);
            });

            renderQueue();
            break;

        case 'openSupplier':
            mode       = 'supply';
            supplies   = event.data.supplies || [];
            quantities = {};
            purchases  = [];
            supplies.forEach(s => { quantities[s.item] = 1; });
            setPanelMode('supply');
            document.getElementById('biz-label').textContent = event.data.business || '';
            document.getElementById('search').value = '';
            document.getElementById('app').style.display = '';
            renderSupplies(supplies);
            renderPurchases();
            break;

        case 'close':
            document.getElementById('app').style.display = 'none';
            queue     = [];
            recipes   = [];
            supplies  = [];
            purchases = [];
            cancelCraftAnim();
            break;

        case 'queueResponse':
            handleQueueResponse(data);
            break;

        case 'cancelResponse':
            handleCancelResponse(data);
            break;

        case 'craftComplete':
            handleCraftComplete(data);
            break;

        case 'queueSync':
            handleQueueSync(data);
            break;

        case 'buySupplyResponse':
            handleBuySupplyResponse(data);
            break;
    }
});

// ─────────────────────────────────────────────────────────────────
//  Panel mode switching (craft station vs. order supplies)
// ─────────────────────────────────────────────────────────────────

function setPanelMode(m) {
    const isSupply = m === 'supply';
    document.getElementById('panel-mode-title').textContent = isSupply ? 'SUPPLIES' : 'STATION';
    document.getElementById('search').placeholder = isSupply ? 'Search supplies…' : 'Search recipes…';
    document.getElementById('queue-title-text').textContent = isSupply ? 'PURCHASE LOG' : 'CRAFTING QUEUE';
    document.getElementById('queue-stat-label-left').textContent = isSupply ? 'Items Bought' : 'In Queue';
    document.getElementById('queue-stat-label-right').textContent = isSupply ? 'Total Spent' : 'Est. Time';
}

// ─────────────────────────────────────────────────────────────────
//  App namespace (called from HTML onclick)
// ─────────────────────────────────────────────────────────────────

const App = {
    close() { nuiFetch('close'); },
    filterRecipes() {
        const q = document.getElementById('search').value.toLowerCase();
        if (mode === 'supply') {
            renderSupplies(supplies.filter(s => s.name.toLowerCase().includes(q)));
        } else {
            renderRecipes(recipes.filter(r => r.name.toLowerCase().includes(q)));
        }
    },
};

// ESC key
document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape' && document.getElementById('app').style.display !== 'none') {
        App.close();
    }
});

// ─────────────────────────────────────────────────────────────────
//  Render – Recipe Cards
// ─────────────────────────────────────────────────────────────────

function renderRecipes(list) {
    const grid = document.getElementById('recipe-grid');
    grid.innerHTML = '';

    list.forEach(r => {
        const card = document.createElement('div');
        card.className = 'rcard';
        card.id = 'rcard-' + r.id;

        const ingHtml = r.ingredients.map(ing =>
            `<div class="rcard-ing">
               <i class="fa-solid fa-angle-right"></i>
               <span class="rcard-ing-name">${esc(ing.name)}</span>
               <span class="rcard-ing-qty">x${ing.qty}</span>
             </div>`
        ).join('');

        const mins      = r.craftTime >= 60 ? Math.floor(r.craftTime / 60) + 'm ' : '';
        const secs      = (r.craftTime % 60) > 0 ? (r.craftTime % 60) + 's' : '';
        const timeLabel = mins + secs;

        const imgHtml = r.output
            ? `<img src="https://cfx-nui-ox_inventory/web/images/${esc(r.output)}.png"
                    onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
               <span class="rcard-img-placeholder" style="display:none"><i class="${esc(r.icon)}"></i></span>`
            : `<span class="rcard-img-placeholder"><i class="${esc(r.icon)}"></i></span>`;

        card.innerHTML = `
          <div class="rcard-body">
            <div class="rcard-img">
              ${imgHtml}
              <span class="rcard-yield">x${r.yield}</span>
            </div>
            <div class="rcard-content">
              <div class="rcard-name">${esc(r.name)}</div>
              <div class="rcard-divider"></div>
              <div class="rcard-ingredients">${ingHtml}</div>
            </div>
          </div>
          <div class="rcard-foot">
            <div class="craft-time"><i class="fa-solid fa-clock"></i> ${timeLabel}</div>
            <div class="rcard-foot-right">
              <div class="stepper">
                <button class="stepper-btn" onclick="changeQty('${r.id}',-1)"><i class="fa-solid fa-minus"></i></button>
                <span class="stepper-val" id="qty-${r.id}">${quantities[r.id] || 1}</span>
                <button class="stepper-btn" onclick="changeQty('${r.id}',+1)"><i class="fa-solid fa-plus"></i></button>
              </div>
              <button class="btn-add" id="addbtn-${r.id}" onclick="addToQueue('${r.id}')">
                <i class="fa-solid fa-plus"></i> Queue
              </button>
            </div>
          </div>`;
        grid.appendChild(card);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Render – Supply Cards
// ─────────────────────────────────────────────────────────────────

function renderSupplies(list) {
    const grid = document.getElementById('recipe-grid');
    grid.innerHTML = '';

    list.forEach(s => {
        const card = document.createElement('div');
        card.className = 'rcard';
        card.id = 'scard-' + s.item;

        card.innerHTML = `
          <div class="rcard-body">
            <div class="rcard-img">
              <img src="https://cfx-nui-ox_inventory/web/images/${esc(s.item)}.png"
                   onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
              <span class="rcard-img-placeholder" style="display:none"><i class="fa-solid fa-box"></i></span>
            </div>
            <div class="rcard-content">
              <div class="rcard-name">${esc(s.name)}</div>
              <div class="rcard-divider"></div>
              <div class="rcard-ing">
                <i class="fa-solid fa-tag"></i>
                <span class="rcard-ing-name">Price</span>
                <span class="rcard-ing-qty">$${s.price}</span>
              </div>
            </div>
          </div>
          <div class="rcard-foot">
            <div class="craft-time" id="price-${s.item}"><i class="fa-solid fa-dollar-sign"></i> $${s.price * (quantities[s.item] || 1)}</div>
            <div class="rcard-foot-right">
              <div class="stepper">
                <button class="stepper-btn" onclick="changeQty('${s.item}',-1)"><i class="fa-solid fa-minus"></i></button>
                <span class="stepper-val" id="qty-${s.item}">${quantities[s.item] || 1}</span>
                <button class="stepper-btn" onclick="changeQty('${s.item}',+1)"><i class="fa-solid fa-plus"></i></button>
              </div>
              <button class="btn-add" id="buybtn-${s.item}" onclick="buySupply('${s.item}')">
                <i class="fa-solid fa-cart-shopping"></i> Buy
              </button>
            </div>
          </div>`;
        grid.appendChild(card);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Stepper
// ─────────────────────────────────────────────────────────────────

function changeQty(id, delta) {
    quantities[id] = Math.max(1, Math.min(99, (quantities[id] || 1) + delta));
    const el = document.getElementById('qty-' + id);
    if (el) el.textContent = quantities[id];

    if (mode === 'supply') {
        const supply = supplies.find(s => s.item === id);
        const priceEl = document.getElementById('price-' + id);
        if (supply && priceEl) priceEl.innerHTML = `<i class="fa-solid fa-dollar-sign"></i> $${supply.price * quantities[id]}`;
    }
}

// ─────────────────────────────────────────────────────────────────
//  Add to Queue
// ─────────────────────────────────────────────────────────────────

function addToQueue(id) {
    const recipe = recipes.find(r => r.id === id);
    if (!recipe) return;

    const qty = quantities[id] || 1;
    const btn = document.getElementById('addbtn-' + id);
    if (btn) btn.disabled = true;

    nuiFetch('addToQueue', { recipeId: id, qty, stashId }).then(() => {
        setTimeout(() => { if (btn) btn.disabled = false; }, 1500);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Cancel a queue item
// ─────────────────────────────────────────────────────────────────

function cancelQueueItem(queueId) {
    nuiFetch('cancelQueue', { queueId });
}

// ─────────────────────────────────────────────────────────────────
//  Buy a supply item
// ─────────────────────────────────────────────────────────────────

function buySupply(item) {
    const qty = quantities[item] || 1;
    const btn = document.getElementById('buybtn-' + item);
    if (btn) btn.disabled = true;

    nuiFetch('buySupply', { item, qty }).then(() => {
        setTimeout(() => { if (btn) btn.disabled = false; }, 800);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Server → client handlers
// ─────────────────────────────────────────────────────────────────

// Authoritative queue state from server — replaces local queue entirely
function handleQueueSync(items) {
    const prevActiveId = (queue.find(q => q.crafting) || {}).queueId;

    queue = (items || []).map(qi => {
        const recipe = recipes.find(r => r.id === qi.recipeId);
        if (!recipe) return null;
        return { queueId: qi.queueId, recipe, qty: qi.qty, crafting: qi.crafting, elapsedMs: qi.elapsedMs };
    }).filter(Boolean);

    const newActive = queue.find(q => q.crafting);

    if (newActive) {
        // Only restart animation if a different item is now active
        if (newActive.queueId !== prevActiveId) {
            startCraftAnim(newActive, newActive.elapsedMs || 0);
        }
    } else {
        cancelCraftAnim();
    }

    renderQueue();
}

// Notification only — queue display is handled by queueSync
function handleQueueResponse(data) {
    if (!data) return;
    document.querySelectorAll('.btn-add').forEach(b => b.disabled = false);
    if (!data.ok) {
        showToast('⚠ ' + (data.reason || 'Could not add to queue'));
    }
}

function handleCancelResponse(data) {
    if (!data || !data.ok) return;
    if (data.warning) showToast('⚠ ' + data.warning);
}

function handleCraftComplete(data) {
    if (!data) return;
    // Queue display updated via queueSync — this is notification only
}

function handleBuySupplyResponse(data) {
    document.querySelectorAll('.btn-add').forEach(b => b.disabled = false);
    if (!data) return;
    if (!data.ok) {
        showToast('⚠ ' + (data.reason || 'Purchase failed'));
        return;
    }
    purchases.unshift({ label: data.label, qty: data.qty, total: data.total });
    if (purchases.length > 20) purchases.length = 20;
    renderPurchases();
}

// ─────────────────────────────────────────────────────────────────
//  Progress animation (visual only – server is authoritative)
// ─────────────────────────────────────────────────────────────────

function startCraftAnim(entry, offsetMs = 0) {
    cancelCraftAnim();

    const totalMs = entry.recipe.craftTime * entry.qty * 1000;
    // Subtract elapsed time so the bar starts at the correct position
    const start   = performance.now() - offsetMs;

    function tick() {
        const pct  = Math.min((performance.now() - start) / totalMs, 1);
        const fill = document.querySelector(`#qitem-${entry.queueId} .progress-bar-fill`);
        if (fill) fill.style.width = Math.round(pct * 100) + '%';
        if (pct < 1) craftRAF = requestAnimationFrame(tick);
    }

    craftRAF = requestAnimationFrame(tick);
}

function cancelCraftAnim() {
    if (craftRAF) { cancelAnimationFrame(craftRAF); craftRAF = null; }
}

// ─────────────────────────────────────────────────────────────────
//  Render – Cook Queue
// ─────────────────────────────────────────────────────────────────

function renderQueue() {
    const container = document.getElementById('queue-items');
    const countEl   = document.getElementById('queue-count');
    const timeEl    = document.getElementById('queue-time');

    if (queue.length === 0) {
        container.innerHTML = `
          <div class="empty-queue">
            <i class="fa-solid fa-fire-flame-curved"></i>
            <p>Queue is empty</p>
          </div>`;
        countEl.textContent = '0';
        timeEl.textContent  = '—';
        return;
    }

    const totalSec  = queue.reduce((acc, q) => acc + q.recipe.craftTime * q.qty, 0);
    const tMins     = Math.floor(totalSec / 60);
    const tSecs     = totalSec % 60;
    timeEl.textContent  = totalSec > 0 ? (tMins > 0 ? tMins + 'm ' + tSecs + 's' : tSecs + 's') : '—';
    countEl.textContent = String(queue.length);

    container.innerHTML = '';
    queue.forEach(item => {
        const div = document.createElement('div');
        div.className = 'qitem' + (item.crafting ? ' crafting' : '');
        div.id = 'qitem-' + item.queueId;

        const mins = item.recipe.craftTime >= 60 ? Math.floor(item.recipe.craftTime / 60) + 'm ' : '';
        const secs = (item.recipe.craftTime % 60) > 0 ? (item.recipe.craftTime % 60) + 's' : '';

        const imgContent = item.recipe.output
            ? `<img src="https://cfx-nui-ox_inventory/web/images/${esc(item.recipe.output)}.png"
                     onerror="this.style.display='none';this.nextElementSibling.style.display='flex'">
               <span class="qitem-img-ph" style="display:none"><i class="${esc(item.recipe.icon)}"></i></span>`
            : `<span class="qitem-img-ph"><i class="${esc(item.recipe.icon)}"></i></span>`;

        // Cancel button shown on all items (server will reject if it's actively crafting)
        const cancelBtn = `
          <button class="btn-cancel" onclick="cancelQueueItem('${item.queueId}')">
            <i class="fa-solid fa-xmark"></i> Cancel
          </button>`;

        // Status row — crafting shows a thin progress bar, pending shows waiting label
        const statusHtml = item.crafting
            ? `<div class="qitem-crafting-label">
                 <span class="status-dot"></span> Cooking…
               </div>
               <div class="progress-bar-bg" style="height:3px;background:#111;border-radius:2px;overflow:hidden;margin-top:2px">
                 <div class="progress-bar-fill" style="height:100%;background:var(--accent);width:0%;transition:width 0.5s linear;box-shadow:0 0 5px var(--accent-glow)"></div>
               </div>`
            : `<div class="qitem-pending-label">
                 <i class="fa-solid fa-clock"></i> Waiting in queue
               </div>`;

        div.innerHTML = `
          <div class="qitem-top">
            <div class="qitem-img">${imgContent}</div>
            <div class="qitem-info">
              <div class="qitem-name">${esc(item.recipe.name)}</div>
              <div class="qitem-meta">${item.qty}x batch · yields ${item.recipe.yield * item.qty} · ${mins}${secs}/ea</div>
            </div>
            ${cancelBtn}
          </div>
          ${statusHtml}`;

        container.appendChild(div);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Render – Purchase Log (supply mode)
// ─────────────────────────────────────────────────────────────────

function renderPurchases() {
    const container = document.getElementById('queue-items');
    const countEl   = document.getElementById('queue-count');
    const totalEl   = document.getElementById('queue-time');

    if (purchases.length === 0) {
        container.innerHTML = `
          <div class="empty-queue">
            <i class="fa-solid fa-truck-ramp-box"></i>
            <p>No purchases yet</p>
          </div>`;
        countEl.textContent = '0';
        totalEl.textContent = '—';
        return;
    }

    const totalSpent = purchases.reduce((acc, p) => acc + p.total, 0);
    countEl.textContent = String(purchases.length);
    totalEl.textContent = '$' + totalSpent;

    container.innerHTML = '';
    purchases.forEach(p => {
        const div = document.createElement('div');
        div.className = 'qitem';
        div.innerHTML = `
          <div class="qitem-top">
            <div class="qitem-img"><span class="qitem-img-ph"><i class="fa-solid fa-box"></i></span></div>
            <div class="qitem-info">
              <div class="qitem-name">${esc(p.label)}</div>
              <div class="qitem-meta">${p.qty}x purchased · $${p.total}</div>
            </div>
          </div>`;
        container.appendChild(div);
    });
}

// ─────────────────────────────────────────────────────────────────
//  Utility
// ─────────────────────────────────────────────────────────────────

function esc(str) {
    return String(str)
        .replace(/&/g, '&amp;').replace(/</g, '&lt;')
        .replace(/>/g, '&gt;').replace(/"/g, '&quot;');
}

let toastTimer;
function showToast(msg) {
    // Notifications handled by the Lua layer — suppress HTML toasts
}

// Fallback for browser dev - this shadows FiveM's real native binding of the
// same name, so it must be kept in sync with fxmanifest's resource name or
// nuiFetch silently posts to the wrong resource.
function GetParentResourceName() { return 'crazy-kitchen'; }
