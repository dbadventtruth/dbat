-- Per-character derived stat cache, keyed by character id.
-- Each entry stores {gen=N, ...derived_name=value} so stale entries
-- are detected via the modifier_gen counter from Zig.
local der_caches = {}

local scale = 10000

local function der_total(ch, name)
  local id = ch:id_get()
  local gen = ch:modifier_gen()
  local cache = der_caches[id]
  if cache and cache.gen == gen then
    local v = cache[name]
    if v ~= nil then return v end
  else
    cache = {gen = gen}
    der_caches[id] = cache
  end

  local def = dbat.characters.registry.derived[name]
  if not def then return 0 end

  -- Base value
  local base
  if def.calculate_base then
    base = def.calculate_base(ch) or 0
  else
    base = ch:stat_get(def.base_stat or name)
  end

  if def.no_modifiers then
    local value = base
    if def.min_value ~= nil then value = math.max(value, def.min_value) end
    if def.max_value ~= nil then value = math.min(value, def.max_value) end
    cache[name] = value
    return value
  end

  -- Modifier accumulation: direct target
  local mods = ch:modifiers_for("derived", name)
  local flat = mods.flat
  local percent = mods.percent
  local multipliers = mods.multipliers
  local min_ov = mods.min
  local max_ov = mods.max
  local set_ov = mods.set

  -- Additional modifier targets
  if def.modifier_targets then
    for _, target in ipairs(def.modifier_targets) do
      local more = ch:modifiers_for(target[1], target[2])
      flat = flat + more.flat
      percent = percent + more.percent
      for _, m in ipairs(more.multipliers) do
        multipliers[#multipliers + 1] = m
      end
      if more.min ~= nil then
        min_ov = min_ov and math.max(min_ov, more.min) or more.min
      end
      if more.max ~= nil then
        max_ov = max_ov and math.min(max_ov, more.max) or more.max
      end
      if more.set ~= nil then set_ov = more.set end
    end
  end

  -- Legacy modifiers (from old affect system)
  if def.legacy_modifiers then
    for _, lm in ipairs(def.legacy_modifiers) do
      flat = flat + ch:legacy_modifier(lm[1], lm[2])
    end
  end

  -- Apply modifiers to base
  local value = base + flat
  if percent ~= 0 then
    value = value + math.floor(value * percent / scale)
  end
  for _, m in ipairs(multipliers) do
    value = math.floor(value * m / scale)
  end

  -- Clamp with definition bounds first, then overrides
  if def.min_value ~= nil then value = math.max(value, def.min_value) end
  if def.max_value ~= nil then value = math.min(value, def.max_value) end
  if min_ov ~= nil then value = math.max(value, min_ov) end
  if max_ov ~= nil then value = math.min(value, max_ov) end
  if set_ov ~= nil then value = set_ov end

  cache[name] = value
  return value
end

local function can_see(ch, entref)
  local kind = entref and entref:reftype()

  if kind == "character" then
    return ch:can_see_char(entref)
  end
  if kind == "object" then
    return ch:can_see_obj(entref)
  end

  error("Character:can_see expected character or object", 2)
end

local function apparent_sex(ch, viewer)
  viewer = viewer or ch

  return ch:sex_get()
end

local function apparent_race(ch, viewer)
  viewer = viewer or ch

  return ch:race_get()
end

local function display_name_for(ch, viewer)
  viewer = viewer or ch

  -- viewer is looking at an NPC, so we just have short descriptions.
  if(ch:is_npc()) then
    return ch:short_description_get()
  end

  -- Okay so ch is a player then.

  -- NPCs and admins can always see player names.
  if(viewer:is_npc() or viewer:admin_level_get() > 0) then
    return ch:name_get()
  end

  -- If we reached this far, we're a player looking at another player.
  -- TODO: use the dub system! For now, just show the name.
  return ch:name_get()
end

local function keywords_for(ch, viewer)
  viewer = viewer or ch
  local keywords = {}

  local name = ch:name_get()
  for word in string.gmatch(name or "", "%S+") do
    keywords[#keywords + 1] = word
  end

  return keywords
end

local function find_in_registry(category, legacy_id)
  local registry = dbat.characters.registry[category]
  if not registry then return nil end
  for _, entry in pairs(registry) do
    if entry.legacy_id == legacy_id then
      return entry
    end
  end
  return nil
end

local function append_mods(out, mods)
  for _, m in ipairs(mods or {}) do
    out[#out + 1] = m
  end
end

local function modifiers(ch)
  local all = {}

  -- Race
  local race_id = ch:race_get()
  if race_id then
    local entry = find_in_registry("races", race_id)
    if entry and entry.modifiers then
      append_mods(all, entry.modifiers(ch))
    end
  end

  -- Sensei
  local sensei_id = ch:sensei_get()
  if sensei_id then
    local entry = find_in_registry("senseis", sensei_id)
    if entry and entry.modifiers then
      append_mods(all, entry.modifiers(ch))
    end
  end

  -- Conditions
  for _, cond_id in ipairs(ch:conditions()) do
    local cond = ch:condition(cond_id)
    local cond_def = dbat.characters.registry.conditions[cond_id]
    if cond_def and cond_def.modifiers then
      append_mods(all, cond_def.modifiers(ch, cond))
    end
  end

  -- Room
  local room = ch:room_get()
  if room then
    append_mods(all, room:modifiers())
  end

  -- Sitting object
  local obj = ch:sits_get()
  if obj then
    append_mods(all, obj:modifiers())
  end

  return all
end

local function on_event(ch, kind)
  local subsystem, id, event_name = kind:match("^([^:]+):([^:]+):?(.*)$")
  event_name = (event_name and event_name ~= "") and event_name or "tick"

  if subsystem == "condition" then
    if not ch:condition_has(id) then return end
    local def = dbat.get("conditions", id)
    if def and def.on_event then
      def.on_event(ch, ch:condition(id), event_name)
    end
  elseif subsystem == "transformation" then
    -- future: route to transformation registry
  end
end

local function act_self(ch, msg, ctx)
  context = ctx or {}
  context.actor = ch
  local dbat = require("dbat")
  dbat.lib.act.to_char(ch, msg, context)
end

local function act_around(ch, msg, ctx)
  context = ctx or {}
  local dbat = require("dbat")
  dbat.lib.act.around(ch, msg, context)
end

-- Build the argparams table — mirrors lua_api.zig:pushArgParams/pushTokens.
local function build_argparams(arguments)
    local function tokenize(s)
        local t = {}
        for tok in string.gmatch(s, "%S+") do t[#t + 1] = tok end
        return t
    end
    local params = { raw = arguments }
    local eq = string.find(arguments, "=", 1, true)
    if eq then
        params.equals      = true
        params.lsargs      = string.sub(arguments, 1, eq - 1)
        params.rsargs      = string.sub(arguments, eq + 1)
        params.left_tokens  = tokenize(params.lsargs)
        params.right_tokens = tokenize(params.rsargs)
    else
        params.equals      = false
        params.lsargs      = arguments
        params.rsargs      = ""
        params.left_tokens  = tokenize(arguments)
        params.right_tokens = {}
    end
    params.tokens = tokenize(arguments)
    return params
end

-- Alias matching — mirrors lua_api.zig:aliasMatches().
-- alias format: {pattern, min_len, sensitive?} or {name=..., min=..., sensitive=...}
local function alias_matches_word(aliases, word)
    for _, alias in ipairs(aliases or {}) do
        local pattern   = alias[1] or alias.name
        local min_len   = alias[2] or alias.min or (pattern and #pattern)
        local sensitive = alias[3] or alias.sensitive or false
        if not pattern then goto continue end
        if #word >= min_len and #word <= #pattern then
            local prefix = string.sub(pattern, 1, #word)
            local matched = sensitive and (word == prefix)
                                       or (string.lower(word) == string.lower(prefix))
            if matched then return true end
        end
        ::continue::
    end
    return false
end

-- Try to dispatch `input` against the commands in cmd_class (must have sorted_list()).
-- Returns true if a command was matched (even if can_execute blocked it).
-- Used by: pcommand_try (bypass wait), command_fallback (after C++ miss).
local function execute_command(ch, input, cmd_class)
    local word = (input or ""):match("^(%S+)") or ""
    local rest = (input or ""):match("^%S+%s*(.-)$") or ""
    for _, def in ipairs(cmd_class.sorted_list()) do
        if alias_matches_word(def.aliases, word) then
            if def.can_see and not def.can_see(ch) then goto next end
            if def.can_execute then
                local ok, reason = def.can_execute(ch)
                if not ok then
                    ch:send((reason or "You cannot do that.") .. "\r\n")
                    return true
                end
            end
            def.execute({ ch = ch, actor = ch,
                          command = def.id or word, alias = word,
                          arguments = rest, argparams = build_argparams(rest) })
            return true
        end
        ::next::
    end
    return false
end

-- Return sorted list of commands from cmd_class visible to ch.
-- Useful for help displays, score sheets, etc.
local function visible_commands(ch, cmd_class)
    local visible = {}
    for _, def in ipairs(cmd_class.sorted_list()) do
        if not def.can_see or def.can_see(ch) then
            visible[#visible + 1] = def
        end
    end
    return visible
end

local function send_text(ch, msg, ...)
  local text = select('#', ...) > 0 and string.format(msg, ...) or msg
  ch:send_raw(text)
end

local function send_around(ch, msg)
  local room = ch:room_get()
  if not room then return end
  for other in room:people() do
    if other:id_get() ~= ch:id_get() then
      other:send(msg)
    end
  end
end

local function send_line(ch, msg, ...)
  local text = select('#', ...) > 0 and string.format(msg, ...) or msg
  if not text:match("\r\n$") then text = text .. "\r\n" end
  ch:send_raw(text)
end

local function send_line_around(ch, msg, ...)
  local text = select('#', ...) > 0 and string.format(msg, ...) or msg
  if not text:match("\r\n$") then text = text .. "\r\n" end
  local room = ch:room_get()
  if not room then return end
  for other in room:people() do
    if other:id_get() ~= ch:id_get() then
      other:send_raw(text)
    end
  end
end

return {
  can_see = can_see,
  keywords_for = keywords_for,
  modifiers = modifiers,
  apparent_sex = apparent_sex,
  apparent_race = apparent_race,
  display_name_for = display_name_for,
  on_event = on_event,
  act_self = act_self,
  act_around = act_around,
  der_total = der_total,
  execute_command = execute_command,
  visible_commands = visible_commands,
  send_text = send_text,
  send_around = send_around,
  send_line = send_line,
  send_line_around = send_line_around,
}
