/* ═══════════════════════════════════════════════════════════════════════
   crazy-register — app.js
   Crazy RP | Staff Register · Management · Pay Terminal · Menu Board
═══════════════════════════════════════════════════════════════════════ */

/* ── Duotone SVG sprite loader ── */
fetch('sprites/duotone.svg')
    .then(r => r.text())
    .then(svgText => {
        const tmp = document.createElement('div');
        tmp.innerHTML = svgText;
        const svg = tmp.querySelector('svg');
        if (!svg) return;
        for (const child of svg.children) {
            if (child.id) child.id = 'duotone-' + child.id;
        }
        svg.style.display = 'none';
        document.body.appendChild(svg);
    });

/* ── Duotone icon helpers ── */
function fad(name) {
    return `<svg class="fad" aria-hidden="true"><use href="#duotone-${name}"></use></svg>`;
}
const _FA_ALIASES = {
    'box':          'box-open',
    'star':         'star',
    'sun':          'sun',
    'users':        'users',
    'burger':       'burger',
    'ice-cream':    'ice-cream',
};
function fadFromClass(faClass) {
    // Accepts "fa-solid fa-burger" or "fa-burger" — extracts the icon name
    const parts = faClass.trim().split(/\s+/);
    const raw   = parts[parts.length - 1].replace(/^fa-/, '');
    return fad(_FA_ALIASES[raw] || raw);
}

/* ── Bundle image helper — item name → ox_inventory img, or fa- class → duotone icon ── */
function bundleIconHtml(icon) {
    if (!icon || icon.startsWith('fa-')) {
        return fadFromClass(icon || 'fa-box-open');
    }
    return `<img src="https://cfx-nui-ox_inventory/web/images/${icon}.png" alt="${icon}">`;
}

/* ── Price formatter — whole dollars with commas e.g. $1,250 ── */
function fmt(n) { return Number(n).toLocaleString('en-US', { maximumFractionDigits: 0 }); }

/* ── State ── */
const State = {
    business:     null,
    bizLabel:     null,
    tillIndex:    null,
    products:     [],
    bundles:      [],
    cart:         {},   // { [bundleId]: { bundleId, name, description, price, qty } }
    pendingOrder: null, // { id, total } when a terminal order is active
    serviceOnly:  false,
    iconItems:    [],
};

/* ── Helpers ── */
// oxmysql may return TINYINT(1) as boolean true or integer 1 — treat both as active
const isActive = b => b.active === 1 || b.active === true;

/* ── NUI Bridge ── */
const NUI_RESOURCE = window.GetParentResourceName ? window.GetParentResourceName() : 'crazy-register';
function nuiFetch(event, data = {}) {
    return fetch(`https://${NUI_RESOURCE}/${event}`, {
        method:  'POST',
        headers: { 'Content-Type': 'application/json' },
        body:    JSON.stringify(data),
    }).then(r => r.json()).catch(() => ({}));
}

/* ── Global close ── */
function closeUI() {
    showView(null);
    document.getElementById('bundle-modal-overlay').style.display = 'none';
    const payOvr = document.getElementById('menu-pay-overlay');
    if (payOvr) payOvr.remove();
    nuiFetch('close');
}

document.addEventListener('keydown', e => {
    if (e.key === 'Escape') closeUI();
});

/* ── In-game notify (replaces UI toast) ── */
function gameNotify(description, type, title) {
    nuiFetch('notify', { title: title || '', description, type: type || 'inform' });
}

/* ── View switching ── */
function showView(name) {
    ['register', 'management', 'pay-terminal', 'menu'].forEach(v => {
        document.getElementById(`view-${v}`).style.display = 'none';
    });
    if (name) document.getElementById(`view-${name}`).style.display = 'flex';
}

/* ══════════════════════════════════════════════════════
   REGISTER MODULE — staff bundle selection + cart
══════════════════════════════════════════════════════ */
const Register = {

    init(data) {
        State.business     = data.business;
        State.bizLabel     = data.bizLabel;
        State.tillIndex    = data.tillIndex;
        State.products     = data.products    || [];
        State.bundles      = data.bundles     || [];
        State.cart         = {};
        State.pendingOrder = data.pendingOrder || null;
        State.serviceOnly  = data.serviceOnly  || false;
        State.iconItems    = data.iconItems    || [];

        document.getElementById('reg-biz-label').textContent =
            data.bizLabel + (data.tillIndex ? '  ·  Till ' + data.tillIndex : '');
        document.getElementById('reg-search').value = '';
        this.render();
        this.renderCart();
        this.renderTerminalStatus(State.pendingOrder);
        showView('register');
    },

    filter() { this.render(); },

    render() {
        const q    = (document.getElementById('reg-search').value || '').toLowerCase();
        const grid = document.getElementById('reg-bundles');
        const list = State.bundles.filter(b =>
            isActive(b) && b.name.toLowerCase().includes(q)
        );

        if (!list.length) {
            const msg = State.bundles.some(isActive)
                ? 'No bundles match your search.'
                : 'No active bundles — create some in management.';
            grid.innerHTML = `<div class="empty" style="grid-column:1/-1"><span>${fad('box-open')}</span><p>${msg}</p></div>`;
            return;
        }

        grid.innerHTML = list.map(b => {
            const inCart    = !!State.cart[b.id];
            const cartEntry = State.cart[b.id];
            const qty       = cartEntry ? cartEntry.qty : 0;
            return `
                <div class="bcard${inCart ? ' in-cart' : ''}">
                  <div class="bcard-body">
                    <div class="bundle-icon-box">${bundleIconHtml(b.icon)}</div>
                    <div class="bcard-content">
                      <div class="bcard-name">${b.name}</div>
                      <div class="bcard-divider"></div>
                      ${b.description ? `<div class="bcard-desc">${b.description}</div>` : ''}
                    </div>
                  </div>
                  <div class="bcard-foot">
                    <div class="bcard-price">
                      ${fad('tag')}
                      <span class="bcard-price-val">$${fmt(b.price)}</span>
                    </div>
                    ${inCart ? `
                      <div class="qty-ctrl">
                        <button class="btn-qty" onclick="Register.changeQty(${b.id},-1)">${fad('minus')}</button>
                        <span class="qty-val">${qty}</span>
                        <button class="btn-qty" onclick="Register.changeQty(${b.id},1)">${fad('plus')}</button>
                      </div>
                    ` : `
                      <button class="btn-add" onclick="Register.addBundle(${b.id})">${fad('plus')} Add to cart</button>
                    `}
                  </div>
                </div>
            `;
        }).join('');
    },

    addBundle(id) {
        const b = State.bundles.find(x => x.id == id);
        if (!b || State.cart[id]) return;
        State.cart[id] = { bundleId: b.id, name: b.name, description: b.description, price: b.price, qty: 1 };
        this.render();
        this.renderCart();
        gameNotify(b.name + ' added to order', 'success');
    },

    changeQty(id, delta) {
        if (!State.cart[id]) return;
        const newQty = State.cart[id].qty + delta;
        if (newQty <= 0) {
            delete State.cart[id];
        } else {
            State.cart[id].qty = newQty;
        }
        this.render();
        this.renderCart();
    },

    removeBundle(id) {
        delete State.cart[id];
        this.render();
        this.renderCart();
    },

    renderCart() {
        const items     = Object.values(State.cart);
        const container = document.getElementById('cart-items');

        if (!items.length) {
            container.innerHTML = `<div class="empty-sm"><span>${fad('cart-shopping')}</span><p>Cart is empty</p></div>`;
        } else {
            container.innerHTML = items.map(b => `
                <div class="cart-row">
                  <div class="cart-row-info">
                    <div class="cart-row-name">${b.name}</div>
                    <div class="cart-row-sub">×${b.qty} — $${fmt(b.price)} each</div>
                  </div>
                  <div class="cart-row-price">$${fmt(Number(b.price) * b.qty)}</div>
                  <button class="btn-remove" onclick="Register.removeBundle(${b.bundleId})">✕</button>
                </div>
            `).join('');
        }

        const total      = items.reduce((s, b) => s + Number(b.price) * b.qty, 0);
        const totalQty   = items.reduce((s, b) => s + b.qty, 0);
        document.getElementById('cart-total').textContent =
            '$' + fmt(total);
        document.getElementById('cart-count').textContent =
            totalQty + (totalQty === 1 ? ' bundle selected' : ' bundles selected');
        document.getElementById('place-order-btn').disabled = items.length === 0;
    },

    renderTerminalStatus(order) {
        const el = document.getElementById('terminal-status');
        if (!order) {
            el.style.display = 'none';
            el.innerHTML     = '';
            return;
        }
        el.style.display = 'block';
        el.innerHTML = `
            <div class="terminal-status-lbl">Terminal — Active Order</div>
            <div class="terminal-status-row">
              <span class="terminal-status-info">Order #${order.id}</span>
              <span class="terminal-status-total">$${fmt(order.total)}</span>
              <button class="btn-sm btn-sm-del" onclick="Register.clearOrder()">Clear</button>
            </div>
        `;
    },

    clearOrder() {
        nuiFetch('clearOrder', {}).then(res => {
            if (res.ok) {
                State.pendingOrder = null;
                this.renderTerminalStatus(null);
            }
        });
    },

    placeOrder() {
        const items = Object.values(State.cart);
        if (!items.length) return;

        // Block if terminal already has an active order
        if (State.pendingOrder) {
            gameNotify('Terminal already has a pending order — clear it first', 'error');
            return;
        }

        const total       = items.reduce((s, b) => s + Number(b.price) * b.qty, 0);
        const cartBundles = items.map(b => ({ bundleId: b.bundleId, qty: b.qty }));
        document.getElementById('place-order-btn').disabled = true;

        nuiFetch('placeOrder', { cartBundles }).then(res => {
            if (res.ok) {
                State.pendingOrder = { id: res.orderId, total };
                this.renderTerminalStatus(State.pendingOrder);
                State.cart = {};
                this.render();
                this.renderCart();
            } else {
                document.getElementById('place-order-btn').disabled = false;
            }
        });
    },

    openManagement() {
        Management.init();
    },
};

/* ── Picker qty helper (called by inline onclick) ── */
function pickerQtyChange(item, delta) {
    const input   = document.getElementById('pickqty-'  + item);
    const display = document.getElementById('pickerval-' + item);
    if (!input) return;
    const newVal = Math.max(1, parseInt(input.value || 1) + delta);
    input.value       = newVal;
    if (display) display.textContent = newVal;
}

/* ══════════════════════════════════════════════════════
   MANAGEMENT MODULE — bundle CRUD
══════════════════════════════════════════════════════ */
const Management = {

    init() {
        document.getElementById('mgmt-biz-label').textContent = State.bizLabel || '';
        this.render();
        showView('management');
    },

    render() {
        const list = document.getElementById('mgmt-list');
        if (!State.bundles.length) {
            list.innerHTML = `<div class="empty"><span>${fad('box-open')}</span><p>No bundles yet. Create one!</p></div>`;
            return;
        }
        list.innerHTML = State.bundles.map(b => {
            const active = isActive(b);
            return `
                <div class="mgmt-card">
                  <div class="mgmt-card-body">
                    <div class="bundle-icon-box">${bundleIconHtml(b.icon)}</div>
                    <div class="mgmt-card-content">
                      <div class="mgmt-card-name">${b.name}</div>
                      <div class="mgmt-card-divider"></div>
                      ${b.description ? `<div class="mgmt-card-desc">${b.description}</div>` : ''}
                    </div>
                  </div>
                  <div class="mgmt-card-foot">
                    <div class="mgmt-card-meta">
                      <div class="mgmt-card-price">
                        ${fad('tag')}
                        <span class="mgmt-card-price-val">$${fmt(b.price)}</span>
                      </div>
                      <div class="mgmt-meta-sep"></div>
                      <div class="badge ${active ? 'badge-active' : 'badge-inactive'}">
                        ${active ? fad('circle-check') : fad('circle-xmark')}
                        ${active ? 'Active' : 'Inactive'}
                      </div>
                    </div>
                    <div class="mgmt-btns">
                      <button class="btn-sm" onclick="Management.toggle(${b.id})" title="${active ? 'Disable' : 'Enable'}">
                        ${active ? fad('toggle-off') : fad('toggle-on')} ${active ? 'Disable' : 'Enable'}
                      </button>
                      <button class="btn-sm btn-sm-edit" onclick="Management.openModal(${b.id})" title="Edit">
                        ${fad('pen-to-square')} Edit
                      </button>
                      <button class="btn-sm btn-sm-del" onclick="Management.del(${b.id})" title="Delete">
                        ${fad('trash')}
                      </button>
                    </div>
                  </div>
                </div>
            `;
        }).join('');
    },

    openModal(editId = null) {
        document.getElementById('bundle-modal-title').innerHTML = editId
            ? `${fad('pen-to-square')} EDIT BUNDLE`
            : `${fad('plus')} CREATE BUNDLE`;
        document.getElementById('bundle-edit-id').value = editId || '';
        document.getElementById('b-name').value  = '';
        document.getElementById('b-desc').value  = '';
        document.getElementById('b-price').value = '';

        // Build image picker — use iconItems for service-only businesses, products otherwise
        const iconSource  = (State.serviceOnly && State.iconItems.length) ? State.iconItems : State.products;
        const defaultIcon = iconSource.length ? iconSource[0].item : '';
        document.getElementById('b-icon').value = defaultIcon;
        document.getElementById('b-icon-picker').innerHTML = iconSource.map(p => `
            <div class="icon-picker-item${p.item === defaultIcon ? ' selected' : ''}"
                 title="${p.item}"
                 onclick="Management.selectIcon('${p.item}', this)">
              <img src="https://cfx-nui-ox_inventory/web/images/${p.item}.png" alt="${p.label}">
            </div>
        `).join('');

        // Hide items picker for service-only businesses (no inventory items needed)
        const itemsSection = document.getElementById('b-items-section');
        if (itemsSection) itemsSection.style.display = State.serviceOnly ? 'none' : '';

        document.getElementById('b-items-picker').innerHTML = State.serviceOnly ? '' : State.products.map(p => `
            <div class="picker-row">
              <input type="checkbox" id="pick-${p.item}" value="${p.item}">
              <label for="pick-${p.item}">${p.label}</label>
              <div class="picker-qty-ctrl">
                <button type="button" class="btn-qty-sm" onclick="pickerQtyChange('${p.item}',-1)">−</button>
                <span class="picker-qty-val" id="pickerval-${p.item}">1</span>
                <button type="button" class="btn-qty-sm" onclick="pickerQtyChange('${p.item}',1)">+</button>
              </div>
              <input type="hidden" id="pickqty-${p.item}" value="1">
            </div>
        `).join('');

        if (editId) {
            const b = State.bundles.find(x => x.id == editId);
            if (b) {
                document.getElementById('b-name').value  = b.name;
                document.getElementById('b-desc').value  = b.description || '';
                document.getElementById('b-price').value = b.price;
                // Pre-select icon
                const savedIcon = b.icon || defaultIcon;
                document.getElementById('b-icon').value = savedIcon;
                document.querySelectorAll('.icon-picker-item').forEach(el => {
                    el.classList.toggle('selected', el.title === savedIcon);
                });
                (b.items || []).forEach(i => {
                    const cb  = document.getElementById('pick-' + i.item);
                    const qty = document.getElementById('pickqty-' + i.item);
                    const val = document.getElementById('pickerval-' + i.item);
                    if (cb)  cb.checked      = true;
                    if (qty) qty.value       = i.qty;
                    if (val) val.textContent = i.qty;
                });
            }
        }

        document.getElementById('bundle-modal-overlay').style.display = 'flex';
    },

    selectIcon(cls, el) {
        document.getElementById('b-icon').value = cls;
        document.querySelectorAll('.icon-picker-item').forEach(x => x.classList.remove('selected'));
        el.classList.add('selected');
    },

    closeModal() {
        document.getElementById('bundle-modal-overlay').style.display = 'none';
    },

    saveBundle() {
        const name   = document.getElementById('b-name').value.trim();
        const desc   = document.getElementById('b-desc').value.trim();
        const price  = parseFloat(document.getElementById('b-price').value) || 0;
        const icon   = document.getElementById('b-icon').value || (State.products.length ? State.products[0].item : '');
        const editId = document.getElementById('bundle-edit-id').value;

        if (!name) { gameNotify('Bundle name is required', 'error'); return; }

        let items = [];
        if (!State.serviceOnly) {
            items = State.products
                .filter(p => document.getElementById('pick-' + p.item)?.checked)
                .map(p => ({
                    item: p.item,
                    qty:  parseInt(document.getElementById('pickqty-' + p.item)?.value) || 1,
                }));
            if (!items.length) { gameNotify('Select at least one item', 'error'); return; }
        }

        const event = editId ? 'editBundle' : 'createBundle';
        const body  = editId
            ? { id: parseInt(editId), name, description: desc, price, icon, items }
            : { name, description: desc, price, icon, items };

        nuiFetch(event, body).then(res => {
            if (res.ok) {
                this.closeModal();
            }
        });
    },

    del(id) {
        nuiFetch('deleteBundle', { id }).then(res => {
            if (!res.ok) toast('Failed to delete', 'error');
        });
    },

    toggle(id) {
        nuiFetch('toggleBundle', { id });
    },

    refresh(bundles) {
        State.bundles = bundles;
        this.render();
        const reg = document.getElementById('view-register');
        if (reg && reg.style.display !== 'none') Register.render();
    },

    back() {
        showView('register');
    },
};

/* ══════════════════════════════════════════════════════
   PAY TERMINAL MODULE — customer views and pays order
══════════════════════════════════════════════════════ */
const PayTerminal = {

    _orderId: null,

    init(data) {
        State.business = data.business;
        State.bizLabel = data.bizLabel;
        const body     = document.getElementById('pay-terminal-body');

        if (!data.order) {
            body.innerHTML = `<div class="empty"><span>${fad('receipt')}</span><p>No pending order at this terminal.</p></div>`;
            showView('pay-terminal');
            return;
        }

        this._orderId  = data.order.id;
        const order    = data.order;

        const rows = (order.bundles || []).map(b => `
            <div class="pay-bundle-row">
              <div class="pay-bundle-icon">${bundleIconHtml(b.icon)}</div>
              <div class="pay-bundle-info">
                <div class="pay-bundle-name">
                  ${b.name}
                  ${b.qty > 1 ? `<span class="pay-qty-badge">×${b.qty}</span>` : ''}
                </div>
                <div class="pay-bundle-divider"></div>
                ${b.description ? `<div class="pay-bundle-desc">${b.description}</div>` : ''}
              </div>
              <div class="pay-bundle-price-col">
                <div class="pay-bundle-price-label">${fad('coins')} PRICE</div>
                <div class="pay-bundle-price">$${fmt(b.price)}</div>
              </div>
            </div>`).join('');

        body.innerHTML = `
            <div class="pay-left">
              <div class="pay-order-header">
                <span class="pay-order-num">${fad('receipt')} ORDER #${order.id}</span>
                <span class="pay-order-biz">${order.bizLabel || State.bizLabel}</span>
              </div>
              <div class="pay-cards-scroll">${rows || `<div class="empty"><span>${fad('box-open')}</span><p>No items</p></div>`}</div>
            </div>
            <div class="pay-footer">
              <div class="order-total-row">
                <span class="order-total-label">Total Due</span>
                <span class="order-total-val">$${fmt(order.total)}</span>
              </div>
              <div class="pay-btns">
                <button class="btn-pay" onclick="PayTerminal.pay('cash')">${fad('money-bill-wave')} CASH</button>
                <button class="btn-pay btn-pay-card" onclick="PayTerminal.pay('bank')">${fad('credit-card')} CARD</button>
              </div>
            </div>`;

        showView('pay-terminal');
    },

    pay(method) {
        if (!this._orderId) return;
        const btns = document.querySelectorAll('.btn-pay');
        btns.forEach(b => b.disabled = true);

        nuiFetch('payOrder', { orderId: this._orderId, method }).then(res => {
            if (res.ok) {
                closeUI();
            } else {
                btns.forEach(b => b.disabled = false);
            }
        });
    },
};

/* ══════════════════════════════════════════════════════
   MENU MODULE — customer menu board (browse + order)
══════════════════════════════════════════════════════ */
const Menu = {

    init(data) {
        State.business = data.business;
        State.bizLabel = data.bizLabel;
        State.bundles  = data.bundles  || [];
        State.products = data.products || [];

        document.getElementById('menu-biz-name').textContent = data.bizLabel;
        this.render();
        showView('menu');
    },

    render() {
        const grid   = document.getElementById('menu-grid');
        const active = State.bundles.filter(isActive);

        if (!active.length) {
            grid.innerHTML = `<div class="empty"><span>${fad('clipboard-list')}</span><p>No menu items available right now.</p></div>`;
            return;
        }

        grid.innerHTML = active.map(b => {
            return `
                <div class="menu-card">
                  <div class="menu-card-body">
                    <div class="bundle-icon-box">${bundleIconHtml(b.icon)}</div>
                    <div class="menu-card-content">
                      <div class="menu-card-name">${b.name}</div>
                      <div class="menu-card-divider"></div>
                      ${b.description ? `<div class="menu-card-desc">${b.description}</div>` : ''}
                    </div>
                  </div>
                  <div class="menu-card-foot">
                    <div class="menu-card-price">
                      ${fad('tag')}
                      <span class="menu-card-price-val">$${fmt(b.price)}</span>
                    </div>
                  </div>
                </div>
            `;
        }).join('');
    },
};

/* ══════════════════════════════════════════════════════
   MESSAGE LISTENER — receives events from Lua client
══════════════════════════════════════════════════════ */
window.addEventListener('message', e => {
    const { action, data } = e.data;

    switch (action) {

        case 'openRegister':
            Register.init(data);
            break;

        case 'openPayTerminal':
            PayTerminal.init(data);
            break;

        case 'openMenu':
            Menu.init(data);
            break;

        case 'refreshBundles':
            State.bundles = data.bundles || [];
            Management.render();
            break;

        case 'close':
            showView(null);
            document.getElementById('bundle-modal-overlay').style.display = 'none';
            const payOvr = document.getElementById('menu-pay-overlay');
            if (payOvr) payOvr.remove();
            break;
    }
});

/* ══════════════════════════════════════════════════════
   DEV PREVIEW — disabled. To re-enable, change `false` back
   to `!window.invokeNative` on the line below.
══════════════════════════════════════════════════════ */
if (false) { // was: if (!window.invokeNative)

    /* ── Mock data ── */
    const devProducts = [
        { item: 'burger',    label: 'Burger',    price: 12, icon: '🍔', limit: 20, category: 'food'   },
        { item: 'fries',     label: 'Fries',     price: 6,  icon: '🍟', limit: 30, category: 'food'   },
        { item: 'soda_can',  label: 'Soda Can',  price: 4,  icon: '🥤', limit: 50, category: 'drinks' },
        { item: 'milkshake', label: 'Milkshake', price: 8,  icon: '🥛', limit: 15, category: 'drinks' },
        { item: 'hotdog',    label: 'Hot Dog',   price: 10, icon: '🌭', limit: 20, category: 'food'   },
        { item: 'juice',     label: 'Orange Juice', price: 5, icon: '🧃', limit: 25, category: 'drinks' },
    ];
    const devBundles = [
        { id: 1, name: 'Meal Deal',      description: 'Burger, fries & a drink.',             price: 22, icon: 'fa-solid fa-burger',       items: [{ item: 'burger', qty: 1 }, { item: 'fries', qty: 1 }, { item: 'soda_can', qty: 1 }], active: 1 },
        { id: 2, name: 'Family Pack',    description: '4 burgers and drinks for the table.',  price: 56, icon: 'fa-solid fa-users',         items: [{ item: 'burger', qty: 4 }, { item: 'soda_can', qty: 4 }], active: 1 },
        { id: 3, name: 'Kids Combo',     description: 'Hotdog + milkshake — perfect for kids.', price: 18, icon: 'fa-solid fa-ice-cream',  items: [{ item: 'hotdog', qty: 1 }, { item: 'milkshake', qty: 1 }], active: 0 },
        { id: 4, name: 'Morning Boost',  description: 'Fries and a juice to start the day.',  price: 11, icon: 'fa-solid fa-sun',          items: [{ item: 'fries', qty: 1 }, { item: 'juice', qty: 1 }], active: 1 },
        { id: 5, name: 'Double Up',      description: 'Two burgers, two drinks.',              price: 38, icon: 'fa-solid fa-star',         items: [{ item: 'burger', qty: 2 }, { item: 'soda_can', qty: 2 }], active: 1 },
    ];
    const devOrder = {
        id: 42,
        bizLabel: 'Burger Shot',
        total: 78,
        bundles: [
            { name: 'Meal Deal',   description: 'Burger, fries & a drink.',    price: 22, icon: 'fa-solid fa-burger' },
            { name: 'Family Pack', description: '4 burgers and drinks.',        price: 56, icon: 'fa-solid fa-users'  },
        ],
    };

    /* ── Stub fetch so nuiFetch calls don't throw ── */
    window.fetch = (url, opts) => {
        console.log('[DEV nuiFetch]', url, opts && JSON.parse(opts.body));
        return Promise.resolve({ json: () => ({ ok: true, orderId: 42 }) });
    };

    /* ── Dev toolbar ── */
    const toolbar = document.createElement('div');
    toolbar.id = '__dev-toolbar';
    toolbar.style.cssText = [
        'position:fixed', 'bottom:14px', 'left:50%', 'transform:translateX(-50%)',
        'display:flex', 'gap:6px', 'padding:8px 12px', 'border-radius:10px',
        'background:rgba(0,0,0,0.82)', 'border:1px solid rgba(255,255,255,0.12)',
        'z-index:99999', 'font-family:sans-serif', 'font-size:12px',
    ].join(';');

    const devViews = [
        { label: '🖥 Register',    action: () => window.dispatchEvent(new MessageEvent('message', { data: { action: 'openRegister',    data: { business: 'burgershop', bizLabel: 'Burger Shot', tillIndex: 2, products: devProducts, bundles: devBundles, isStaff: true } }})) },
        { label: '⚙ Management',  action: () => { Register.init({ business: 'burgershop', bizLabel: 'Burger Shot', tillIndex: 1, products: devProducts, bundles: devBundles }); Management.init(); } },
        { label: '💳 Pay Terminal',action: () => window.dispatchEvent(new MessageEvent('message', { data: { action: 'openPayTerminal', data: { business: 'burgershop', bizLabel: 'Burger Shot', order: devOrder } }})) },
        { label: '📋 Menu Board',  action: () => window.dispatchEvent(new MessageEvent('message', { data: { action: 'openMenu',        data: { business: 'burgershop', bizLabel: 'Burger Shot', products: devProducts, bundles: devBundles } }})) },
        { label: '➕ New Bundle',  action: () => { Register.init({ business: 'burgershop', bizLabel: 'Burger Shot', tillIndex: 1, products: devProducts, bundles: devBundles }); Management.init(); Management.openModal(); } },
        { label: '✏ Edit Bundle', action: () => { Register.init({ business: 'burgershop', bizLabel: 'Burger Shot', tillIndex: 1, products: devProducts, bundles: devBundles }); Management.init(); Management.openModal(1); } },
        { label: '🧾 Empty Terminal', action: () => window.dispatchEvent(new MessageEvent('message', { data: { action: 'openPayTerminal', data: { business: 'burgershop', bizLabel: 'Burger Shot', order: null } }})) },
        { label: '🛒 Register+Order', action: () => window.dispatchEvent(new MessageEvent('message', { data: { action: 'openRegister', data: { business: 'burgershop', bizLabel: 'Burger Shot', tillIndex: 1, products: devProducts, bundles: devBundles, pendingOrder: devOrder } }})) },
    ];

    devViews.forEach(({ label, action }) => {
        const btn = document.createElement('button');
        btn.textContent = label;
        btn.style.cssText = 'padding:5px 10px;border-radius:6px;border:1px solid rgba(255,255,255,0.18);background:rgba(255,255,255,0.07);color:#ddd;cursor:pointer;white-space:nowrap;';
        btn.onmouseenter = () => btn.style.background = 'rgba(255,255,255,0.18)';
        btn.onmouseleave = () => btn.style.background = 'rgba(255,255,255,0.07)';
        btn.onclick = action;
        toolbar.appendChild(btn);
    });

    document.body.appendChild(toolbar);

    /* ── Open Register by default ── */
    devViews[0].action();
}
