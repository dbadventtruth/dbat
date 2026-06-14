'use strict';

// ---- State ----
const state = {
  token: null,
  account: null,
  adminLevel: 0,
  meta: {},   // keyed by endpoint slug
};

// ---- API ----
const api = {
  base: '',

  async req(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    if (state.token) headers['Authorization'] = `Bearer ${state.token}`;
    const res = await fetch(api.base + path, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw Object.assign(new Error(data.error || `HTTP ${res.status}`), { status: res.status });
    return data;
  },

  get:    (path) => api.req('GET', path),
  put:    (path, body) => api.req('PUT', path, body),
  post:   (path, body) => api.req('POST', path, body),
};

// ---- Toast ----
function toast(msg, type = 'info') {
  const el = document.createElement('div');
  el.className = `toast ${type}`;
  el.textContent = msg;
  document.getElementById('toast-container').appendChild(el);
  setTimeout(() => el.remove(), 3500);
}

// ---- Auth ----
function saveSession(token, account, adminLevel) {
  state.token = token;
  state.account = account;
  state.adminLevel = adminLevel;
  sessionStorage.setItem('dbat_token', token);
  sessionStorage.setItem('dbat_account', account);
  sessionStorage.setItem('dbat_admin_level', adminLevel);
}

function loadSession() {
  state.token = sessionStorage.getItem('dbat_token');
  state.account = sessionStorage.getItem('dbat_account');
  state.adminLevel = parseInt(sessionStorage.getItem('dbat_admin_level') || '0', 10);
}

function clearSession() {
  state.token = null; state.account = null; state.adminLevel = 0;
  sessionStorage.removeItem('dbat_token');
  sessionStorage.removeItem('dbat_account');
  sessionStorage.removeItem('dbat_admin_level');
}

document.getElementById('login-form').addEventListener('submit', async (e) => {
  e.preventDefault();
  const account = document.getElementById('login-account').value.trim();
  const password = document.getElementById('login-password').value;
  try {
    const data = await api.post('/api/auth/token', { account, password });
    saveSession(data.token, data.account, data.admin_level);
    document.getElementById('login-overlay').classList.add('hidden');
    document.getElementById('user-info').textContent = `${data.account} (lvl ${data.admin_level})`;
    await loadMeta();
    showTab('status');
  } catch (err) {
    toast(err.message, 'error');
  }
});

document.getElementById('logout-btn').addEventListener('click', () => {
  clearSession();
  document.getElementById('login-overlay').classList.remove('hidden');
});

// ---- Meta ----
const META_ENDPOINTS = [
  'room-flags', 'sector-types', 'mob-flags', 'mob-affect-flags',
  'object-types', 'object-extra-flags', 'object-wear-flags',
  'directions', 'character-races', 'character-senseis',
  'dgscript-attach-types', 'dgscript-mob-triggers',
  'dgscript-obj-triggers', 'dgscript-room-triggers',
];

async function loadMeta() {
  await Promise.all(META_ENDPOINTS.map(async (key) => {
    try {
      state.meta[key] = await api.get(`/api/meta/${key}`);
    } catch {
      state.meta[key] = [];
    }
  }));
}

// ---- Tabs ----
function showTab(name) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.toggle('active', b.dataset.tab === name));
  document.querySelectorAll('.pane').forEach(p => p.classList.toggle('active', p.id === `pane-${name}`));
  if (name === 'status') loadStatus();
  if (name === 'zones') loadZoneList();
}

document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => showTab(btn.dataset.tab));
});

// ---- Status ----
async function loadStatus() {
  try {
    const data = await api.get('/api/status');
    const el = document.getElementById('status-content');
    el.innerHTML = `
      <div class="status-grid">
        <div class="stat-card"><div class="value">${data.players ?? 0}</div><div class="label">Players Online</div></div>
        <div class="stat-card"><div class="value">OK</div><div class="label">Server Status</div></div>
      </div>`;
  } catch (err) {
    document.getElementById('status-content').textContent = `Error: ${err.message}`;
  }
}

// ---- Helpers: Flag grids ----
function buildFlagGrid(containerId, metaKey, currentValue) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  const flags = state.meta[metaKey] || [];
  for (const f of flags) {
    const bit = f.bit ?? f.id;
    const checked = (currentValue & (1 << bit)) !== 0;
    const label = document.createElement('label');
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = checked;
    cb.dataset.bit = bit;
    label.appendChild(cb);
    label.appendChild(document.createTextNode(f.name));
    container.appendChild(label);
  }
}

function readFlagGrid(containerId) {
  let val = 0;
  document.querySelectorAll(`#${containerId} input[type=checkbox]`).forEach(cb => {
    if (cb.checked) val |= (1 << parseInt(cb.dataset.bit, 10));
  });
  return val;
}

function buildSelect(selectId, metaKey, currentId) {
  const sel = document.getElementById(selectId);
  sel.innerHTML = '';
  const items = state.meta[metaKey] || [];
  for (const item of items) {
    const id = item.id ?? item.bit;
    const opt = document.createElement('option');
    opt.value = id;
    opt.textContent = item.name;
    opt.selected = id === currentId;
    sel.appendChild(opt);
  }
}

// ---- Zone list ----
async function loadZoneList() {
  // Fetch all zones by iterating known vnums — the API doesn't have a list endpoint yet,
  // so we fetch /api/status and hint at zone count, or just show a vnum search bar.
  const el = document.getElementById('zone-list-content');
  el.innerHTML = '<p style="color:var(--muted)">Enter a zone vnum above to load it, or use the Rooms/Objects/etc. tabs to browse by vnum.</p>';
}

// ---- Room editor ----
(function setupRoomEditor() {
  const loadBtn = document.getElementById('room-load-btn');
  const saveBtn = document.getElementById('room-save-btn');
  const vnumInput = document.getElementById('room-vnum-input');
  let currentRoom = null;

  loadBtn.addEventListener('click', () => loadRoom());
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadRoom(); });

  async function loadRoom() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentRoom = await api.get(`/api/rooms/${vnum}`);
      renderRoom(currentRoom);
      saveBtn.disabled = false;
      toast(`Room ${vnum} loaded`, 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  }

  function renderRoom(room) {
    document.getElementById('room-name').value = room.name || '';
    document.getElementById('room-description').value = room.description || '';
    buildSelect('room-sector', 'sector-types', room.sector_type ?? 0);
    buildFlagGrid('room-flags-grid', 'room-flags', room.flags ?? 0);
    renderExits(room.exits || {});
    renderExtraDescs(room.extra_descriptions || []);
  }

  function renderExits(exits) {
    const tbody = document.getElementById('room-exits-tbody');
    tbody.innerHTML = '';
    const dirs = state.meta['directions'] || [];
    for (const dir of dirs) {
      const exit = exits[dir.id] || {};
      const tr = document.createElement('tr');
      tr.dataset.dirId = dir.id;
      tr.innerHTML = `
        <td><label><input type="checkbox" class="exit-enabled" ${exit.to_room !== undefined ? 'checked' : ''}> ${dir.name}</label></td>
        <td><input type="number" class="exit-to-room" value="${exit.to_room ?? ''}"></td>
        <td><input type="text" class="exit-keyword" value="${exit.keyword || ''}"></td>
        <td><input type="text" class="exit-description" value="${exit.description || ''}"></td>`;
      tbody.appendChild(tr);
    }
  }

  function renderExtraDescs(descs) {
    const container = document.getElementById('room-extra-descs');
    container.innerHTML = '';
    for (let i = 0; i < descs.length; i++) addExtraDescEntry(container, descs[i]);
  }

  document.getElementById('room-add-extradesc').addEventListener('click', () => {
    addExtraDescEntry(document.getElementById('room-extra-descs'), {});
  });

  function addExtraDescEntry(container, ed) {
    const div = document.createElement('div');
    div.className = 'extra-desc-entry';
    div.innerHTML = `
      <button class="remove-btn danger" type="button">Remove</button>
      <div class="form-group"><label>Keywords</label><input type="text" class="ed-keyword" value="${ed.keyword || ''}"></div>
      <div class="form-group"><label>Description</label><textarea class="ed-description">${ed.description || ''}</textarea></div>`;
    div.querySelector('.remove-btn').addEventListener('click', () => div.remove());
    container.appendChild(div);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentRoom) return;
    const vnum = parseInt(vnumInput.value, 10);

    // Collect exits
    const exits = {};
    document.querySelectorAll('#room-exits-tbody tr').forEach(tr => {
      const enabled = tr.querySelector('.exit-enabled').checked;
      if (!enabled) return;
      const dirId = parseInt(tr.dataset.dirId, 10);
      const toRoom = tr.querySelector('.exit-to-room').value;
      if (toRoom === '') return;
      exits[dirId] = {
        to_room: parseInt(toRoom, 10),
        keyword: tr.querySelector('.exit-keyword').value,
        description: tr.querySelector('.exit-description').value,
      };
    });

    // Collect extra descs
    const extraDescs = [];
    document.querySelectorAll('#room-extra-descs .extra-desc-entry').forEach(div => {
      extraDescs.push({
        keyword: div.querySelector('.ed-keyword').value,
        description: div.querySelector('.ed-description').value,
      });
    });

    const body = {
      name: document.getElementById('room-name').value,
      description: document.getElementById('room-description').value,
      sector_type: parseInt(document.getElementById('room-sector').value, 10),
      flags: readFlagGrid('room-flags-grid'),
      exits,
      extra_descriptions: extraDescs,
    };

    try {
      currentRoom = await api.put(`/api/rooms/${vnum}`, body);
      toast('Room saved', 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  });
})();

// ---- Object editor ----
(function setupObjectEditor() {
  const loadBtn = document.getElementById('object-load-btn');
  const saveBtn = document.getElementById('object-save-btn');
  const vnumInput = document.getElementById('object-vnum-input');
  let currentObj = null;

  loadBtn.addEventListener('click', () => loadObject());
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadObject(); });

  async function loadObject() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentObj = await api.get(`/api/objects/${vnum}`);
      renderObject(currentObj);
      saveBtn.disabled = false;
      toast(`Object ${vnum} loaded`, 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  }

  function renderObject(obj) {
    document.getElementById('obj-name').value = obj.name || '';
    document.getElementById('obj-short-desc').value = obj.short_description || '';
    document.getElementById('obj-long-desc').value = obj.long_description || '';
    document.getElementById('obj-action-desc').value = obj.action_description || '';
    buildSelect('obj-type', 'object-types', obj.type ?? 0);
    buildFlagGrid('obj-extra-flags-grid', 'object-extra-flags', obj.extra_flags ?? 0);
    buildFlagGrid('obj-wear-flags-grid', 'object-wear-flags', obj.wear_flags ?? 0);
    for (let i = 0; i < 8; i++) {
      const el = document.getElementById(`obj-val${i}`);
      if (el) el.value = obj[`value${i}`] ?? obj[`val${i}`] ?? 0;
    }
    document.getElementById('obj-weight').value = obj.weight ?? 0;
    document.getElementById('obj-cost').value = obj.cost ?? 0;
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentObj) return;
    const vnum = parseInt(vnumInput.value, 10);
    const body = {
      name: document.getElementById('obj-name').value,
      short_description: document.getElementById('obj-short-desc').value,
      long_description: document.getElementById('obj-long-desc').value,
      action_description: document.getElementById('obj-action-desc').value,
      type: parseInt(document.getElementById('obj-type').value, 10),
      extra_flags: readFlagGrid('obj-extra-flags-grid'),
      wear_flags: readFlagGrid('obj-wear-flags-grid'),
      weight: parseFloat(document.getElementById('obj-weight').value) || 0,
      cost: parseInt(document.getElementById('obj-cost').value, 10) || 0,
    };
    for (let i = 0; i < 8; i++) {
      const el = document.getElementById(`obj-val${i}`);
      if (el) body[`value${i}`] = parseInt(el.value, 10) || 0;
    }
    try {
      currentObj = await api.put(`/api/objects/${vnum}`, body);
      toast('Object saved', 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  });
})();

// ---- Mob editor ----
(function setupMobEditor() {
  const loadBtn = document.getElementById('mob-load-btn');
  const saveBtn = document.getElementById('mob-save-btn');
  const vnumInput = document.getElementById('mob-vnum-input');
  let currentMob = null;

  loadBtn.addEventListener('click', () => loadMob());
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadMob(); });

  async function loadMob() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentMob = await api.get(`/api/mobs/${vnum}`);
      renderMob(currentMob);
      saveBtn.disabled = false;
      toast(`Mob ${vnum} loaded`, 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  }

  function renderMob(mob) {
    document.getElementById('mob-name').value = mob.name || '';
    document.getElementById('mob-short-desc').value = mob.short_description || '';
    document.getElementById('mob-long-desc').value = mob.long_description || '';
    document.getElementById('mob-level').value = mob.level ?? 0;
    buildSelect('mob-race', 'character-races', mob.race ?? 0);
    buildSelect('mob-sensei', 'character-senseis', mob.sensei ?? 0);
    buildFlagGrid('mob-flags-grid', 'mob-flags', mob.act_flags ?? 0);
    buildFlagGrid('mob-aff-flags-grid', 'mob-affect-flags', mob.aff_flags ?? 0);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentMob) return;
    const vnum = parseInt(vnumInput.value, 10);
    const body = {
      name: document.getElementById('mob-name').value,
      short_description: document.getElementById('mob-short-desc').value,
      long_description: document.getElementById('mob-long-desc').value,
      level: parseInt(document.getElementById('mob-level').value, 10) || 0,
      race: parseInt(document.getElementById('mob-race').value, 10),
      sensei: parseInt(document.getElementById('mob-sensei').value, 10),
      act_flags: readFlagGrid('mob-flags-grid'),
      aff_flags: readFlagGrid('mob-aff-flags-grid'),
    };
    try {
      currentMob = await api.put(`/api/mobs/${vnum}`, body);
      toast('Mob saved', 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  });
})();

// ---- Trigger editor ----
(function setupTrigEditor() {
  const loadBtn = document.getElementById('trig-load-btn');
  const saveBtn = document.getElementById('trig-save-btn');
  const vnumInput = document.getElementById('trig-vnum-input');
  let currentTrig = null;

  loadBtn.addEventListener('click', () => loadTrig());
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') loadTrig(); });

  const attachSel = document.getElementById('trig-attach-type');

  function updateTrigTypeGrid(attachId) {
    const metaKey = ['dgscript-mob-triggers', 'dgscript-obj-triggers', 'dgscript-room-triggers'][attachId] || 'dgscript-mob-triggers';
    buildFlagGrid('trig-type-grid', metaKey, currentTrig ? (currentTrig.trigger_type ?? 0) : 0);
  }

  attachSel.addEventListener('change', () => updateTrigTypeGrid(parseInt(attachSel.value, 10)));

  async function loadTrig() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentTrig = await api.get(`/api/triggers/${vnum}`);
      renderTrig(currentTrig);
      saveBtn.disabled = false;
      toast(`Trigger ${vnum} loaded`, 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  }

  function renderTrig(trig) {
    document.getElementById('trig-name').value = trig.name || '';
    document.getElementById('trig-narg').value = trig.narg ?? 0;
    document.getElementById('trig-argument').value = trig.argument || '';
    document.getElementById('trig-code').value = trig.code || '';
    buildSelect('trig-attach-type', 'dgscript-attach-types', trig.attach_type ?? 0);
    updateTrigTypeGrid(trig.attach_type ?? 0);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentTrig) return;
    const vnum = parseInt(vnumInput.value, 10);
    const attachType = parseInt(document.getElementById('trig-attach-type').value, 10);
    const body = {
      name: document.getElementById('trig-name').value,
      attach_type: attachType,
      narg: parseInt(document.getElementById('trig-narg').value, 10) || 0,
      argument: document.getElementById('trig-argument').value,
      trigger_type: readFlagGrid('trig-type-grid'),
      code: document.getElementById('trig-code').value,
    };
    try {
      currentTrig = await api.put(`/api/triggers/${vnum}`, body);
      toast('Trigger saved', 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  });
})();

// ---- Generic vnum editors (zone/shop/guild) ----
function makeSimpleEditor(prefix, apiPath) {
  const loadBtn = document.getElementById(`${prefix}-load-btn`);
  const saveBtn = document.getElementById(`${prefix}-save-btn`);
  const vnumInput = document.getElementById(`${prefix}-vnum-input`);
  let current = null;

  if (!loadBtn) return;

  loadBtn.addEventListener('click', () => load());
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      current = await api.get(`/api/${apiPath}/${vnum}`);
      renderJson(prefix, current);
      saveBtn.disabled = false;
      toast(`Loaded ${vnum}`, 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  }

  saveBtn.addEventListener('click', async () => {
    if (!current) return;
    const vnum = parseInt(vnumInput.value, 10);
    try {
      const raw = document.getElementById(`${prefix}-raw-json`).value;
      const body = JSON.parse(raw);
      current = await api.put(`/api/${apiPath}/${vnum}`, body);
      document.getElementById(`${prefix}-raw-json`).value = JSON.stringify(current, null, 2);
      toast('Saved', 'success');
    } catch (err) {
      toast(err.message, 'error');
    }
  });
}

function renderJson(prefix, data) {
  const el = document.getElementById(`${prefix}-raw-json`);
  if (el) el.value = JSON.stringify(data, null, 2);
}

makeSimpleEditor('zone', 'zones');
makeSimpleEditor('shop', 'shops');
makeSimpleEditor('guild', 'guilds');

// ---- Init ----
(function init() {
  loadSession();
  if (state.token) {
    document.getElementById('login-overlay').classList.add('hidden');
    document.getElementById('user-info').textContent = `${state.account} (lvl ${state.adminLevel})`;
    loadMeta().then(() => showTab('status'));
  }
})();
