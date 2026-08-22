const invoiceEl = document.getElementById('invoice');
const orderIdEl = document.getElementById('order-id');
const businessLabelEl = document.getElementById('business-label');
const descriptionEl = document.getElementById('order-description');
const priceEl = document.getElementById('order-price');
const totalDueEl = document.getElementById('total-due');
const closeBtn = document.getElementById('close-btn');
const cashBtn = document.getElementById('cash-btn');
const cardBtn = document.getElementById('card-btn');

let currentInvoiceId = null;

async function postNui(endpoint, data) {
    const resourceName = window.GetParentResourceName ? window.GetParentResourceName() : 'crazy-invoicing';

    return fetch(`https://${resourceName}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data ?? {}),
    });
}

function showInvoice(data) {
    currentInvoiceId = data.id;
    orderIdEl.textContent = `Order #${data.id}`;
    businessLabelEl.textContent = data.business ?? '';
    descriptionEl.textContent = data.description;
    descriptionEl.title = data.description;
    priceEl.textContent = `$${data.amount.toLocaleString('en-US')}`;
    totalDueEl.textContent = `$${data.amount.toLocaleString('en-US')}`;
    invoiceEl.classList.remove('hidden');
}

function closeInvoice() {
    currentInvoiceId = null;
    invoiceEl.classList.add('hidden');
}

function pay(method) {
    if (currentInvoiceId === null) return;
    postNui('payInvoice', { id: currentInvoiceId, method });
}

closeBtn.addEventListener('click', () => {
    postNui('closeInvoice');
    closeInvoice();
});

cashBtn.addEventListener('click', () => pay('cash'));
cardBtn.addEventListener('click', () => pay('card'));

window.addEventListener('message', (event) => {
    const { action, data } = event.data;

    if (action === 'showInvoice') {
        showInvoice(data);
    } else if (action === 'closeInvoice') {
        closeInvoice();
    }
});

document.addEventListener('keyup', (event) => {
    if (event.key === 'Escape') {
        postNui('closeInvoice');
        closeInvoice();
    }
});
