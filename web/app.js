'use strict';

// ---- State ----
const state = {
  token: null,
  account: null,
  adminLevel: 0,
  meta: {},
};

// ---- API ----
const api = {
  async req(method, path, body) {
    const headers = { 'Content-Type': 'application/json' };
    if (state.token) headers['Authorization'] = `Bearer ${state.token}`;
    const res = await fetch(path, {
      method,
      headers,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
    const data = await res.json().catch(() => ({}));
    if (!res.ok) throw Object.assign(new Error(data.error || `HTTP ${res.status}`), { status: res.status });
    return data;
  },
  get:  (path)       => api.req('GET', path),
  put:  (path, body) => api.req('PUT', path, body),
  post: (path, body) => api.req('POST', path, body),
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
  state.token = token; state.account = account; state.adminLevel = adminLevel;
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
  'zone-flags', 'trade-flags',
];

async function loadMeta() {
  await Promise.all(META_ENDPOINTS.map(async (key) => {
    try { state.meta[key] = await api.get(`/api/meta/${key}`); }
    catch { state.meta[key] = []; }
  }));
}

// ---- Tabs ----
function showTab(name) {
  document.querySelectorAll('.tab-btn').forEach(b => b.classList.toggle('active', b.dataset.tab === name));
  document.querySelectorAll('.pane').forEach(p => p.classList.toggle('active', p.id === `pane-${name}`));
  if (name === 'status') loadStatus();
}

document.querySelectorAll('.tab-btn').forEach(btn => {
  btn.addEventListener('click', () => showTab(btn.dataset.tab));
});

// ---- Status ----
async function loadStatus() {
  try {
    const data = await api.get('/api/status');
    document.getElementById('status-content').innerHTML = `
      <div class="status-grid">
        <div class="stat-card"><div class="value">${data.players ?? 0}</div><div class="label">Players Online</div></div>
        <div class="stat-card"><div class="value">OK</div><div class="label">Server Status</div></div>
      </div>`;
  } catch (err) {
    document.getElementById('status-content').textContent = `Error: ${err.message}`;
  }
}

// ---- Flag grid helpers ----

// Array-format flags: stored as [bit, bit, ...] in JSON (most entities)
function buildFlagGridArr(containerId, metaKey, flagArr) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  const flags = state.meta[metaKey] || [];
  const active = Array.isArray(flagArr) ? flagArr : [];
  for (const f of flags) {
    const bit = f.bit ?? f.id;
    const label = document.createElement('label');
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = active.includes(bit);
    cb.dataset.bit = bit;
    label.appendChild(cb);
    label.appendChild(document.createTextNode(f.name));
    container.appendChild(label);
  }
}

function readFlagArr(containerId) {
  const result = [];
  document.querySelectorAll(`#${containerId} input[type=checkbox]`).forEach(cb => {
    if (cb.checked) result.push(parseInt(cb.dataset.bit, 10));
  });
  return result;
}

// Integer-bitmask flags: stored as a plain integer (trigger_type, exit.flags, shop.bitvector)
function buildFlagGridInt(containerId, metaKey, intVal) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  const flags = state.meta[metaKey] || [];
  const val = intVal || 0;
  for (const f of flags) {
    const bit = f.bit ?? f.id;
    const label = document.createElement('label');
    const cb = document.createElement('input');
    cb.type = 'checkbox';
    cb.checked = ((val >> bit) & 1) !== 0;
    cb.dataset.bit = bit;
    label.appendChild(cb);
    label.appendChild(document.createTextNode(f.name));
    container.appendChild(label);
  }
}

function readFlagInt(containerId) {
  let val = 0;
  document.querySelectorAll(`#${containerId} input[type=checkbox]`).forEach(cb => {
    if (cb.checked) val |= (1 << parseInt(cb.dataset.bit, 10));
  });
  return val;
}

// ---- Select helper ----
function buildSelect(selectId, metaKey, currentId) {
  const sel = document.getElementById(selectId);
  sel.innerHTML = '';
  for (const item of (state.meta[metaKey] || [])) {
    const id = item.id ?? item.bit;
    const opt = document.createElement('option');
    opt.value = id;
    opt.textContent = item.name;
    opt.selected = id === currentId;
    sel.appendChild(opt);
  }
}

// ---- Vnum list helpers (proto_script, producing, in_room) ----
function renderVnumList(containerId, vnums) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  for (const v of (vnums || [])) addVnumListRow(container, v);
}

function addVnumListRow(container, vnum) {
  const row = document.createElement('div');
  row.className = 'vnum-list-row';
  const inp = document.createElement('input');
  inp.type = 'number';
  inp.value = vnum ?? '';
  const btn = document.createElement('button');
  btn.className = 'danger';
  btn.textContent = 'Remove';
  btn.addEventListener('click', () => row.remove());
  row.appendChild(inp);
  row.appendChild(btn);
  container.appendChild(row);
}

function readVnumList(containerId) {
  return Array.from(document.querySelectorAll(`#${containerId} .vnum-list-row input`))
    .map(inp => parseInt(inp.value, 10)).filter(v => !isNaN(v));
}

// ---- Extra descriptions ----
function renderExtraDescs(containerId, descs) {
  const container = document.getElementById(containerId);
  container.innerHTML = '';
  for (const ed of (descs || [])) addExtraDescEntry(container, ed);
}

function addExtraDescEntry(container, ed) {
  const div = document.createElement('div');
  div.className = 'extra-desc-entry';
  div.innerHTML = `
    <button class="remove-btn danger" type="button">Remove</button>
    <div class="form-group"><label>Keywords</label><input type="text" class="ed-keyword" value="${(ed.keyword || '').replace(/"/g, '&quot;')}"></div>
    <div class="form-group"><label>Description</label><textarea class="ed-description">${ed.description || ''}</textarea></div>`;
  div.querySelector('.remove-btn').addEventListener('click', () => div.remove());
  container.appendChild(div);
}

function readExtraDescs(containerId) {
  return Array.from(document.querySelectorAll(`#${containerId} .extra-desc-entry`)).map(div => ({
    keyword: div.querySelector('.ed-keyword').value,
    description: div.querySelector('.ed-description').value,
  }));
}

// ---- Object type value labels ----
const OBJ_VAL_LABELS = {
  1:  ['Time', '-', 'Hours', '-', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  2:  ['Level', 'Spell 1', 'Spell 2', 'Spell 3', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  3:  ['Level', 'Max Charges', 'Charges', 'Spell', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  4:  ['Level', 'Max Charges', 'Charges', 'Spell', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  5:  ['Skill', 'Dam Dice', 'Dam Size', 'Dam Type', 'Health', 'Max Health', 'Crit Type', 'Material', 'Crit Range', '-', '-', '-', '-', '-', '-', '-'],
  9:  ['Apply AC', 'Skill', 'Max Dex Mod', 'Check Penalty', 'Health', 'Max Health', 'Spell Fail', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  10: ['Level', 'Spell 1', 'Spell 2', 'Spell 3', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  15: ['Capacity', 'Flags', 'Key Vnum', 'Is Corpse', 'Health', 'Max Health', '-', 'Material', 'Owner', '-', '-', '-', '-', '-', '-', '-'],
  17: ['Capacity', 'How Full', 'Liquid', 'Poison', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  19: ['Food Value', 'Max Food Val', 'PS Bonus', 'Poison', 'Health', 'Max Health', 'Exp Bonus', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  20: ['Amount', '-', '-', '-', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  23: ['Capacity', 'How Full', 'Liquid', 'Poison', 'Health', 'Max Health', '-', 'Material', '-', '-', '-', '-', '-', '-', '-', '-'],
  25: ['Vehicle Vnum', 'Flags', 'DC Skill', 'DC Move', 'Health', 'Max Health', '-', 'Material', 'DC Lock', 'DC Hide', '-', '-', '-', '-', 'VehicleID Hi', 'VehicleID Lo'],
  28: ['Dest Room', 'DC Skill', 'DC Move', 'Appear', 'Health', 'Max Health', '-', 'Material', 'DC Lock', 'DC Hide', '-', '-', '-', '-', '-', '-'],
  34: ['Growth', 'Mat Goal', 'Maturity', 'Max Mature', 'Health', 'Max Health', 'Water Level', 'Material', 'Soil Quality', '-', '-', '-', '-', '-', '-', '-'],
};
const OBJ_VAL_DEFAULT = ['Value 0', 'Value 1', 'Value 2', 'Value 3', 'Health', 'Max Health', 'Value 6', 'Material', 'Value 8', 'Value 9', 'Value 10', 'Value 11', 'Value 12', 'Value 13', 'Value 14', 'Value 15'];

function updateObjValueLabels(typeId) {
  const labels = OBJ_VAL_LABELS[typeId] || OBJ_VAL_DEFAULT;
  for (let i = 0; i < 16; i++) {
    const el = document.getElementById(`obj-val${i}-label`);
    if (el) el.textContent = labels[i];
  }
}

// ---- Zone reset command editor ----
const CMD_ARG_LABELS = {
  M: ['Mob Vnum', 'World Max', 'Room Vnum', 'Room Max', 'Fail Chance %'],
  O: ['Obj Vnum', 'World Max', 'Room Vnum', 'Room Max', 'Fail Chance %'],
  G: ['Obj Vnum', 'World Max', '', '', 'Fail Chance %'],
  E: ['Obj Vnum', 'World Max', 'EQ Position', '', 'Fail Chance %'],
  P: ['Obj Vnum', 'World Max', 'Target Obj Vnum', '', 'Fail Chance %'],
  D: ['Room Vnum', 'Door Dir', 'State (0/1/2)', '', ''],
  R: ['Room Vnum', 'Obj Vnum', '', '', ''],
  T: ['Trig Type (0/1/2)', 'Trig Vnum', 'Room Vnum', '', 'Fail Chance %'],
  V: ['Trig Type (0/1/2)', 'Context', 'Room Vnum', '', 'Fail Chance %'],
};

function updateCmdArgLabels(li, type) {
  const labels = CMD_ARG_LABELS[type] || ['Arg 0', 'Arg 1', 'Arg 2', 'Arg 3', 'Arg 4'];
  li.querySelectorAll('.cmd-arg-group').forEach((grp, i) => {
    const lbl = grp.querySelector('label');
    const inp = grp.querySelector('input');
    const name = labels[i] || '';
    lbl.textContent = name;
    grp.style.display = name ? '' : 'none';
    inp.disabled = !name;
  });
  // sarg fields only for V
  li.querySelectorAll('.cmd-sarg-group').forEach(grp => {
    grp.style.display = type === 'V' ? '' : 'none';
  });
}

function createResetCommandRow(cmd) {
  const li = document.createElement('li');
  li.className = 'zone-cmd';
  li.draggable = true;

  const args = cmd?.args || [0, 0, 0, 0, 0];
  const type = cmd?.command || 'M';

  li.innerHTML = `
    <span class="drag-handle" title="Drag to reorder">⠿</span>
    <div class="form-group" style="margin-bottom:0">
      <label style="font-size:0.7rem;color:var(--muted)">Type</label>
      <select class="cmd-type" style="width:60px">
        ${['M','O','G','E','P','D','R','T','V'].map(t => `<option${t===type?' selected':''}>${t}</option>`).join('')}
      </select>
    </div>
    <label style="display:flex;align-items:center;gap:0.3rem;font-size:0.8rem">
      <input type="checkbox" class="cmd-if-flag"${cmd?.if_flag ? ' checked' : ''}> if_flag
    </label>
    ${[0,1,2,3,4].map(i => `
      <div class="cmd-arg-group">
        <label>Arg ${i}</label>
        <input type="number" class="cmd-arg" data-arg="${i}" value="${args[i] ?? 0}">
      </div>`).join('')}
    <div class="cmd-sarg-group">
      <label>Var Name</label>
      <input type="text" class="cmd-sarg1" value="${cmd?.sarg1 || ''}">
    </div>
    <div class="cmd-sarg-group">
      <label>Var Value</label>
      <input type="text" class="cmd-sarg2" value="${cmd?.sarg2 || ''}">
    </div>
    <button class="danger cmd-remove" type="button">✕</button>`;

  li.querySelector('.cmd-type').addEventListener('change', (e) => updateCmdArgLabels(li, e.target.value));
  li.querySelector('.cmd-remove').addEventListener('click', () => li.remove());

  // drag-and-drop
  li.addEventListener('dragstart', (e) => {
    e.dataTransfer.effectAllowed = 'move';
    li.classList.add('dragging');
    li._dragSrc = li;
  });
  li.addEventListener('dragend', () => li.classList.remove('dragging'));
  li.addEventListener('dragover', (e) => { e.preventDefault(); li.classList.add('drag-over'); });
  li.addEventListener('dragleave', () => li.classList.remove('drag-over'));
  li.addEventListener('drop', (e) => {
    e.preventDefault();
    li.classList.remove('drag-over');
    const src = document.querySelector('.zone-cmd.dragging');
    if (src && src !== li) {
      const list = li.parentNode;
      const items = Array.from(list.children);
      const srcIdx = items.indexOf(src);
      const dstIdx = items.indexOf(li);
      if (srcIdx < dstIdx) list.insertBefore(src, li.nextSibling);
      else list.insertBefore(src, li);
    }
  });

  updateCmdArgLabels(li, type);
  return li;
}

function renderResetCommands(cmds) {
  const list = document.getElementById('zone-reset-list');
  list.innerHTML = '';
  for (const cmd of (cmds || [])) list.appendChild(createResetCommandRow(cmd));
}

function collectResetCommands() {
  return Array.from(document.querySelectorAll('#zone-reset-list .zone-cmd')).map(li => {
    const args = [0,1,2,3,4].map(i => parseInt(li.querySelector(`.cmd-arg[data-arg="${i}"]`).value, 10) || 0);
    return {
      command: li.querySelector('.cmd-type').value,
      if_flag: li.querySelector('.cmd-if-flag').checked,
      args,
      sarg1: li.querySelector('.cmd-sarg1').value || null,
      sarg2: li.querySelector('.cmd-sarg2').value || null,
    };
  });
}

// ---- Zone editor ----
(function setupZoneEditor() {
  const loadBtn = document.getElementById('zone-load-btn');
  const saveBtn = document.getElementById('zone-save-btn');
  const vnumInput = document.getElementById('zone-vnum-input');
  let currentZone = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });
  document.getElementById('zone-add-cmd').addEventListener('click', () => {
    document.getElementById('zone-reset-list').appendChild(createResetCommandRow(null));
  });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentZone = await api.get(`/api/zones/${vnum}`);
      renderZone(currentZone);
      saveBtn.disabled = false;
      toast(`Zone ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderZone(z) {
    document.getElementById('zone-name').value = z.name || '';
    document.getElementById('zone-builders').value = z.builders || '';
    document.getElementById('zone-bottom').value = z.bottom ?? '';
    document.getElementById('zone-top').value = z.top ?? '';
    document.getElementById('zone-lifespan').value = z.lifespan ?? 30;
    document.getElementById('zone-reset-mode').value = z.reset_mode ?? 2;
    document.getElementById('zone-min-level').value = z.min_level ?? 0;
    document.getElementById('zone-max-level').value = z.max_level ?? 0;
    buildFlagGridArr('zone-flags-grid', 'zone-flags', z.flags ?? []);
    renderResetCommands(z.reset_commands ?? []);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentZone) return;
    const vnum = parseInt(vnumInput.value, 10);
    const body = {
      name: document.getElementById('zone-name').value,
      builders: document.getElementById('zone-builders').value,
      bottom: parseInt(document.getElementById('zone-bottom').value, 10) || 0,
      top: parseInt(document.getElementById('zone-top').value, 10) || 0,
      lifespan: parseInt(document.getElementById('zone-lifespan').value, 10) || 30,
      reset_mode: parseInt(document.getElementById('zone-reset-mode').value, 10),
      min_level: parseInt(document.getElementById('zone-min-level').value, 10) || 0,
      max_level: parseInt(document.getElementById('zone-max-level').value, 10) || 0,
      flags: readFlagArr('zone-flags-grid'),
      reset_commands: collectResetCommands(),
    };
    try {
      currentZone = await api.put(`/api/zones/${vnum}`, body);
      toast('Zone saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Room editor ----
(function setupRoomEditor() {
  const loadBtn = document.getElementById('room-load-btn');
  const saveBtn = document.getElementById('room-save-btn');
  const vnumInput = document.getElementById('room-vnum-input');
  let currentRoom = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  document.getElementById('room-add-extradesc').addEventListener('click', () => {
    addExtraDescEntry(document.getElementById('room-extra-descs'), {});
  });
  document.getElementById('room-add-script').addEventListener('click', () => {
    const inp = document.getElementById('room-proto-script-input');
    const v = parseInt(inp.value, 10);
    if (!isNaN(v)) { addVnumListRow(document.getElementById('room-proto-script'), v); inp.value = ''; }
  });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentRoom = await api.get(`/api/rooms/${vnum}`);
      renderRoom(currentRoom);
      saveBtn.disabled = false;
      toast(`Room ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderRoom(room) {
    document.getElementById('room-name').value = room.name || '';
    document.getElementById('room-description').value = room.description || '';
    buildSelect('room-sector', 'sector-types', room.sector ?? 0);
    buildFlagGridArr('room-flags-grid', 'room-flags', room.flags ?? []);
    renderExits(room.exits || {});
    renderExtraDescs('room-extra-descs', room.extra_descriptions || []);
    renderVnumList('room-proto-script', room.proto_script || []);
  }

  function renderExits(exits) {
    const tbody = document.getElementById('room-exits-tbody');
    tbody.innerHTML = '';
    for (const dir of (state.meta['directions'] || [])) {
      const exit = exits[dir.name] || {};   // keyed by name, not id
      const tr = document.createElement('tr');
      tr.dataset.dirName = dir.name;
      tr.innerHTML = `
        <td><label><input type="checkbox" class="exit-enabled"${exit.to_room !== undefined ? ' checked' : ''}> ${dir.name}</label></td>
        <td><input type="number" class="exit-to-room" value="${exit.to_room ?? ''}"></td>
        <td><input type="text" class="exit-keyword" value="${exit.keyword || ''}"></td>
        <td><input type="text" class="exit-description" value="${exit.description || ''}"></td>`;
      tbody.appendChild(tr);
    }
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentRoom) return;
    const vnum = parseInt(vnumInput.value, 10);

    const exits = {};
    document.querySelectorAll('#room-exits-tbody tr').forEach(tr => {
      if (!tr.querySelector('.exit-enabled').checked) return;
      const toRoom = tr.querySelector('.exit-to-room').value;
      if (toRoom === '') return;
      exits[tr.dataset.dirName] = {
        to_room: parseInt(toRoom, 10),
        keyword: tr.querySelector('.exit-keyword').value,
        description: tr.querySelector('.exit-description').value,
      };
    });

    const body = {
      name: document.getElementById('room-name').value,
      description: document.getElementById('room-description').value,
      sector: parseInt(document.getElementById('room-sector').value, 10),
      flags: readFlagArr('room-flags-grid'),
      exits,
      extra_descriptions: readExtraDescs('room-extra-descs'),
      proto_script: readVnumList('room-proto-script'),
    };

    try {
      currentRoom = await api.put(`/api/rooms/${vnum}`, body);
      toast('Room saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });

  document.getElementById('room-save-bottom').addEventListener('click', () =>
    document.getElementById('room-save-btn').click());
})();

// ---- Object editor ----
(function setupObjectEditor() {
  const loadBtn = document.getElementById('object-load-btn');
  const saveBtn = document.getElementById('object-save-btn');
  const vnumInput = document.getElementById('object-vnum-input');
  let currentObj = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  document.getElementById('obj-type').addEventListener('change', (e) => {
    updateObjValueLabels(parseInt(e.target.value, 10));
  });
  document.getElementById('obj-add-script').addEventListener('click', () => {
    const inp = document.getElementById('obj-proto-script-input');
    const v = parseInt(inp.value, 10);
    if (!isNaN(v)) { addVnumListRow(document.getElementById('obj-proto-script'), v); inp.value = ''; }
  });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentObj = await api.get(`/api/objects/${vnum}`);
      renderObject(currentObj);
      saveBtn.disabled = false;
      toast(`Object ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderObject(obj) {
    document.getElementById('obj-name').value = obj.name || '';
    document.getElementById('obj-short-desc').value = obj.short_description || '';
    document.getElementById('obj-long-desc').value = obj.description || '';      // JSON field is "description"
    document.getElementById('obj-action-desc').value = obj.action_description || '';
    const typeId = obj.type ?? 0;
    buildSelect('obj-type', 'object-types', typeId);
    updateObjValueLabels(typeId);
    const vals = obj.values || [];
    for (let i = 0; i < 16; i++) {
      const el = document.getElementById(`obj-val${i}`);
      if (el) el.value = vals[i] ?? 0;
    }
    document.getElementById('obj-weight').value = obj.weight ?? 0;
    document.getElementById('obj-cost').value = obj.cost ?? 0;
    document.getElementById('obj-level').value = obj.level ?? 0;
    buildFlagGridArr('obj-extra-flags-grid', 'object-extra-flags', obj.extra_flags ?? []);
    buildFlagGridArr('obj-wear-flags-grid', 'object-wear-flags', obj.wear_flags ?? []);
    renderVnumList('obj-proto-script', obj.proto_script || []);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentObj) return;
    const vnum = parseInt(vnumInput.value, 10);
    const values = [];
    for (let i = 0; i < 16; i++) {
      const el = document.getElementById(`obj-val${i}`);
      values.push(el ? (parseInt(el.value, 10) || 0) : 0);
    }
    const body = {
      name: document.getElementById('obj-name').value,
      short_description: document.getElementById('obj-short-desc').value,
      description: document.getElementById('obj-long-desc').value,
      action_description: document.getElementById('obj-action-desc').value,
      type: parseInt(document.getElementById('obj-type').value, 10),
      values,
      weight: parseInt(document.getElementById('obj-weight').value, 10) || 0,
      cost: parseInt(document.getElementById('obj-cost').value, 10) || 0,
      level: parseInt(document.getElementById('obj-level').value, 10) || 0,
      extra_flags: readFlagArr('obj-extra-flags-grid'),
      wear_flags: readFlagArr('obj-wear-flags-grid'),
      proto_script: readVnumList('obj-proto-script'),
    };
    try {
      currentObj = await api.put(`/api/objects/${vnum}`, body);
      toast('Object saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Mob editor ----
(function setupMobEditor() {
  const loadBtn = document.getElementById('mob-load-btn');
  const saveBtn = document.getElementById('mob-save-btn');
  const vnumInput = document.getElementById('mob-vnum-input');
  let currentMob = null;

  const MOB_STAT_KEYS = ['level','powerlevel','ki','alignment','strength','intelligence',
    'wisdom','constitution','speed','agility','armor','experience','money'];

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });
  document.getElementById('mob-add-script').addEventListener('click', () => {
    const inp = document.getElementById('mob-proto-script-input');
    const v = parseInt(inp.value, 10);
    if (!isNaN(v)) { addVnumListRow(document.getElementById('mob-proto-script'), v); inp.value = ''; }
  });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentMob = await api.get(`/api/mobs/${vnum}`);
      renderMob(currentMob);
      saveBtn.disabled = false;
      toast(`Mob ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderMob(mob) {
    document.getElementById('mob-name').value = mob.name || '';
    document.getElementById('mob-short-desc').value = mob.short_description || '';
    document.getElementById('mob-description').value = mob.description || '';
    document.getElementById('mob-long-desc').value = mob.long_description || '';
    buildSelect('mob-race', 'character-races', mob.race ?? 0);
    buildSelect('mob-sensei', 'character-senseis', mob.class ?? 0);  // JSON field is "class"
    const stats = mob.stats || {};
    for (const key of MOB_STAT_KEYS) {
      const el = document.getElementById(`mob-${key}`);
      if (el) el.value = stats[key] ?? 0;
    }
    buildFlagGridArr('mob-flags-grid', 'mob-flags', mob.mob_flags ?? []);
    renderVnumList('mob-proto-script', mob.proto_script || []);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentMob) return;
    const vnum = parseInt(vnumInput.value, 10);
    const stats = {};
    for (const key of MOB_STAT_KEYS) {
      const el = document.getElementById(`mob-${key}`);
      if (el) stats[key] = parseInt(el.value, 10) || 0;
    }
    const body = {
      name: document.getElementById('mob-name').value,
      short_description: document.getElementById('mob-short-desc').value,
      description: document.getElementById('mob-description').value,
      long_description: document.getElementById('mob-long-desc').value,
      race: parseInt(document.getElementById('mob-race').value, 10),
      class: parseInt(document.getElementById('mob-sensei').value, 10),
      stats,
      mob_flags: readFlagArr('mob-flags-grid'),
      proto_script: readVnumList('mob-proto-script'),
    };
    try {
      currentMob = await api.put(`/api/mobs/${vnum}`, body);
      toast('Mob saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Shop editor ----
(function setupShopEditor() {
  const loadBtn = document.getElementById('shop-load-btn');
  const saveBtn = document.getElementById('shop-save-btn');
  const vnumInput = document.getElementById('shop-vnum-input');
  let currentShop = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });
  document.getElementById('shop-add-producing').addEventListener('click', () => {
    const inp = document.getElementById('shop-producing-input');
    const v = parseInt(inp.value, 10);
    if (!isNaN(v)) { addVnumListRow(document.getElementById('shop-producing'), v); inp.value = ''; }
  });
  document.getElementById('shop-add-in-room').addEventListener('click', () => {
    const inp = document.getElementById('shop-in-room-input');
    const v = parseInt(inp.value, 10);
    if (!isNaN(v)) { addVnumListRow(document.getElementById('shop-in-room'), v); inp.value = ''; }
  });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentShop = await api.get(`/api/shops/${vnum}`);
      renderShop(currentShop);
      saveBtn.disabled = false;
      toast(`Shop ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderShop(s) {
    document.getElementById('shop-keeper').value = s.keeper ?? 0;
    document.getElementById('shop-profit-buy').value = s.profit_buy ?? 1;
    document.getElementById('shop-profit-sell').value = s.profit_sell ?? 1;
    document.getElementById('shop-bank').value = s.bank ?? 0;
    document.getElementById('shop-temper').value = s.temper ?? 0;
    document.getElementById('shop-bitvector').value = s.bitvector ?? 0;
    document.getElementById('shop-open1').value = s.open1 ?? 0;
    document.getElementById('shop-close1').value = s.close1 ?? 0;
    document.getElementById('shop-open2').value = s.open2 ?? 0;
    document.getElementById('shop-close2').value = s.close2 ?? 0;
    document.getElementById('shop-no-such-item1').value = s.no_such_item1 || '';
    document.getElementById('shop-no-such-item2').value = s.no_such_item2 || '';
    document.getElementById('shop-missing-cash1').value = s.missing_cash1 || '';
    document.getElementById('shop-missing-cash2').value = s.missing_cash2 || '';
    document.getElementById('shop-do-not-buy').value = s.do_not_buy || '';
    document.getElementById('shop-message-buy').value = s.message_buy || '';
    document.getElementById('shop-message-sell').value = s.message_sell || '';
    renderVnumList('shop-producing', s.producing || []);
    renderVnumList('shop-in-room', s.in_room || []);
    buildFlagGridArr('shop-with-who-grid', 'trade-flags', s.with_who ?? []);
  }

  function collectShop() {
    const with_who = readFlagArr('shop-with-who-grid');
    return {
      keeper: parseInt(document.getElementById('shop-keeper').value, 10) || 0,
      profit_buy: parseFloat(document.getElementById('shop-profit-buy').value) || 1,
      profit_sell: parseFloat(document.getElementById('shop-profit-sell').value) || 1,
      bank: parseInt(document.getElementById('shop-bank').value, 10) || 0,
      temper: parseInt(document.getElementById('shop-temper').value, 10) || 0,
      bitvector: parseInt(document.getElementById('shop-bitvector').value, 10) || 0,
      open1: parseInt(document.getElementById('shop-open1').value, 10) || 0,
      close1: parseInt(document.getElementById('shop-close1').value, 10) || 0,
      open2: parseInt(document.getElementById('shop-open2').value, 10) || 0,
      close2: parseInt(document.getElementById('shop-close2').value, 10) || 0,
      no_such_item1: document.getElementById('shop-no-such-item1').value,
      no_such_item2: document.getElementById('shop-no-such-item2').value,
      missing_cash1: document.getElementById('shop-missing-cash1').value,
      missing_cash2: document.getElementById('shop-missing-cash2').value,
      do_not_buy: document.getElementById('shop-do-not-buy').value,
      message_buy: document.getElementById('shop-message-buy').value,
      message_sell: document.getElementById('shop-message-sell').value,
      producing: readVnumList('shop-producing'),
      in_room: readVnumList('shop-in-room'),
      with_who,
    };
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentShop) return;
    const vnum = parseInt(vnumInput.value, 10);
    try {
      currentShop = await api.put(`/api/shops/${vnum}`, collectShop());
      toast('Shop saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Guild editor ----
(function setupGuildEditor() {
  const loadBtn = document.getElementById('guild-load-btn');
  const saveBtn = document.getElementById('guild-save-btn');
  const vnumInput = document.getElementById('guild-vnum-input');
  let currentGuild = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentGuild = await api.get(`/api/guilds/${vnum}`);
      renderGuild(currentGuild);
      saveBtn.disabled = false;
      toast(`Guild ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderGuild(g) {
    document.getElementById('guild-master').value = g.guildmaster ?? 0;
    document.getElementById('guild-charge').value = g.charge ?? 1;
    document.getElementById('guild-min-level').value = g.min_level ?? 0;
    document.getElementById('guild-open').value = g.open ?? 0;
    document.getElementById('guild-close').value = g.close ?? 0;
    document.getElementById('guild-no-such-skill').value = g.no_such_skill || '';
    document.getElementById('guild-not-enough-gold').value = g.not_enough_gold || '';
    document.getElementById('guild-skills').value = (g.skills || []).join(', ');
    document.getElementById('guild-feats').value = (g.feats || []).join(', ');
    buildFlagGridArr('guild-with-who-grid', 'trade-flags', g.with_who ?? []);
  }

  function parseIndexList(str) {
    return str.split(',').map(s => parseInt(s.trim(), 10)).filter(n => !isNaN(n));
  }

  function collectGuild() {
    const with_who = readFlagArr('guild-with-who-grid');
    return {
      guildmaster: parseInt(document.getElementById('guild-master').value, 10) || 0,
      charge: parseFloat(document.getElementById('guild-charge').value) || 1,
      min_level: parseInt(document.getElementById('guild-min-level').value, 10) || 0,
      open: parseInt(document.getElementById('guild-open').value, 10) || 0,
      close: parseInt(document.getElementById('guild-close').value, 10) || 0,
      no_such_skill: document.getElementById('guild-no-such-skill').value,
      not_enough_gold: document.getElementById('guild-not-enough-gold').value,
      skills: parseIndexList(document.getElementById('guild-skills').value),
      feats: parseIndexList(document.getElementById('guild-feats').value),
      with_who,
    };
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentGuild) return;
    const vnum = parseInt(vnumInput.value, 10);
    try {
      currentGuild = await api.put(`/api/guilds/${vnum}`, collectGuild());
      toast('Guild saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Trigger editor ----
(function setupTrigEditor() {
  const loadBtn = document.getElementById('trig-load-btn');
  const saveBtn = document.getElementById('trig-save-btn');
  const vnumInput = document.getElementById('trig-vnum-input');
  let currentTrig = null;

  loadBtn.addEventListener('click', load);
  vnumInput.addEventListener('keydown', (e) => { if (e.key === 'Enter') load(); });

  const attachSel = document.getElementById('trig-attach-type');
  function updateTrigTypeGrid(attachId, trigType) {
    const metaKey = ['dgscript-mob-triggers', 'dgscript-obj-triggers', 'dgscript-room-triggers'][attachId] || 'dgscript-mob-triggers';
    buildFlagGridInt('trig-type-grid', metaKey, trigType ?? 0);
  }
  attachSel.addEventListener('change', () =>
    updateTrigTypeGrid(parseInt(attachSel.value, 10), readFlagInt('trig-type-grid')));

  async function load() {
    const vnum = parseInt(vnumInput.value, 10);
    if (isNaN(vnum)) return toast('Enter a valid vnum', 'error');
    try {
      currentTrig = await api.get(`/api/triggers/${vnum}`);
      renderTrig(currentTrig);
      saveBtn.disabled = false;
      toast(`Trigger ${vnum} loaded`, 'success');
    } catch (err) { toast(err.message, 'error'); }
  }

  function renderTrig(trig) {
    document.getElementById('trig-name').value = trig.name || '';
    document.getElementById('trig-narg').value = trig.narg ?? 0;
    document.getElementById('trig-argument').value = trig.arglist || '';  // JSON field is "arglist"
    document.getElementById('trig-code').value = (trig.lines || []).join('\n');  // join lines array
    buildSelect('trig-attach-type', 'dgscript-attach-types', trig.attach_type ?? 0);
    updateTrigTypeGrid(trig.attach_type ?? 0, trig.trigger_type ?? 0);
  }

  saveBtn.addEventListener('click', async () => {
    if (!currentTrig) return;
    const vnum = parseInt(vnumInput.value, 10);
    const attachType = parseInt(document.getElementById('trig-attach-type').value, 10);
    const body = {
      name: document.getElementById('trig-name').value,
      attach_type: attachType,
      narg: parseInt(document.getElementById('trig-narg').value, 10) || 0,
      arglist: document.getElementById('trig-argument').value,
      trigger_type: readFlagInt('trig-type-grid'),
      lines: document.getElementById('trig-code').value.split('\n'),
    };
    try {
      currentTrig = await api.put(`/api/triggers/${vnum}`, body);
      toast('Trigger saved', 'success');
    } catch (err) { toast(err.message, 'error'); }
  });
})();

// ---- Init ----
(function init() {
  loadSession();
  if (state.token) {
    document.getElementById('login-overlay').classList.add('hidden');
    document.getElementById('user-info').textContent = `${state.account} (lvl ${state.adminLevel})`;
    loadMeta().then(() => showTab('status'));
  }
})();
