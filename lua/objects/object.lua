-- Constants from dbat are loaded lazily so this module can be
-- required at engine startup before dbat's registry is initialized.
local _C  -- lazy cache for dbat.consts tables

local function C()
    if _C then return _C end
    local d = require("dbat")
    _C = {
        EF  = d.consts.item_extra_flags,
        IT  = d.consts.item_types,
        PRF = d.consts.prf_flags,
        AF  = d.consts.aff_flags,
        MAT = d.consts.materials,
        CF  = d.consts.container_flags,
    }
    return _C
end

local function keywords_for(obj, viewer)
  local keywords = {}

  local name = obj:name_get()
  for word in string.gmatch(name or "", "%S+") do
    keywords[#keywords + 1] = word
  end

  return keywords
end

local function display_name_for(obj, viewer, prefix)
  viewer = viewer or obj

  return obj:short_description_get()
end

-- Used for furniture-based modifiers.
local function modifiers(obj)
  local mods = {}

  local vital_regen = 10000

  if obj:proto_id_get() == 19090 then
    vital_regen = vital_regen + 10000
  end
  if obj:proto_id_get() == 19091 then
    vital_regen = vital_regen + 30000
  end

  -- healing tanks
  if obj:proto_id_get() == 65 then
    vital_regen = 200000
  end

  if vital_regen ~= 0 then
    local label = obj:short_description_get()
    mods[#mods + 1] = { target = { "regen", "vitals" }, kind = "percent", value = vital_regen, label = label }
  end

  return mods
end

local function on_mud_hour(obj)
end

local function on_second(obj)
end

local function on_heartbeat(obj, hb)
end

-- ---------------------------------------------------------------------------
-- Inventory rendering
-- ---------------------------------------------------------------------------

local QUALITY_LABELS = {
  [0] = " @D[@wQuality @RC@D]@n",
  [1] = " @D[@wQuality @RC@D]@n",
  [2] = " @D[@wQuality @RC+@D]@n",
  [3] = " @D[@wQuality @yC++@D]@n",
  [4] = " @D[@wQuality @yB@D]@n",
  [5] = " @D[@wQuality @CB+@D]@n",
  [6] = " @D[@wQuality @CB++@D]@n",
  [7] = " @D[@wQuality @CA@D]@n",
  [8] = " @D[@wQuality @GA+@D]@n",
}

local PLANT_STAGES = {
  [0] = " @D[@ySeed@D]@n",
  [1] = " @D[@GSprout@D]@n",
  [2] = " @D[@GYoung@D]@n",
  [3] = " @D[@GMature@D]@n",
  [4] = " @D[@GBudding@D]@n",
  [5] = "@D[@GClose Harvest@D]@n",
  [6] = "@D[@gHarvest@D]@n",
}

-- Key used to group identical objects for stacking in inventory display.
-- Matches the multi-condition comparison in list_obj_to_char.
local function stack_key(obj)
  local c = C()
  local EF, IT = c.EF, c.IT
  local proto = obj:proto_id_get()
  local parts = {
    tostring(proto),
    (obj:short_description_get() or ""):lower(),
    (obj:description_get() or ""):lower(),
    obj:extra_flagged(EF.BROKEN) and "1" or "0",
    obj:extra_flagged(EF.DUPLICATE) and "1" or "0",
    tostring(obj:value_get(6)),
  }
  if obj:type_get() == IT.PLANT then
    parts[#parts+1] = tostring(obj:value_get(2))  -- VAL_MATURITY
  end
  if proto == 255 then
    parts[#parts+1] = tostring(obj:value_get(0))
  end
  return table.concat(parts, "\0")
end

-- Port of show_obj_to_char(SHOW_OBJ_SHORT) + show_obj_modifiers.
-- Returns a fully formatted string with trailing \n.
-- Count prefix (for stacking) is the caller's responsibility.
local function render_inventory_line(obj, viewer)
  local c = C()
  local EF, IT, PRF, AF, MAT, CF = c.EF, c.IT, c.PRF, c.AF, c.MAT, c.CF

  local t = {}

  -- PRF_ROOMFLAGS: vnum prefix
  if viewer:pref_flagged(PRF.ROOMFLAGS) then
    t[#t+1] = string.format("[%d] ", obj:proto_id_get())
  end

  -- PRF_IHEALTH: health + short description; otherwise just short description
  local sdesc = obj:short_description_get() or ""
  if viewer:pref_flagged(PRF.IHEALTH) then
    t[#t+1] = string.format("@D<@gH@D: @C%d@D>@w %s", obj:value_get(4), sdesc)
  else
    t[#t+1] = sdesc
  end

  -- Special VNUM suffixes
  local vid = obj:proto_id_get()
  if vid == 255 then
    t[#t+1] = QUALITY_LABELS[obj:value_get(0)] or ""
  elseif vid == 3424 then
    t[#t+1] = string.format(" @D[@bInk Remaining@D: @w%d@D]@n", obj:value_get(6))
  elseif vid == 3423 then
    t[#t+1] = string.format(" @D[@B%d@D/@B24 Inks@D]@n", obj:value_get(6))
  end

  -- THROW flag
  if obj:extra_flagged(EF.THROW) then
    t[#t+1] = " @D[@RThrow Only@D]@n"
  end

  -- Plant growth stages
  local otype = obj:type_get()
  if otype == IT.PLANT and not obj:extra_flagged(EF.MATURE) then
    if obj:value_get(6) < -9 then   -- VAL_WATERLEVEL = 6
      t[#t+1] = "@D[@RDead@D]@n"
    else
      t[#t+1] = PLANT_STAGES[obj:value_get(2)] or ""  -- VAL_MATURITY = 2
    end
  end

  -- Container open/closed (skip sheaths and corpses)
  if otype == IT.CONTAINER and obj:value_get(3) ~= 1 and not obj:extra_flagged(EF.SHEATH) then
    if (obj:value_get(1) & CF.CLOSED) == 0 then
      t[#t+1] = " @D[@G-open-@D]@n"
    else
      t[#t+1] = " @D[@rclosed@D]@n"
    end
  end

  -- Duplicate
  if obj:extra_flagged(EF.DUPLICATE) then
    t[#t+1] = " @D[@YDuplicate@D]@n"
  end

  -- show_obj_modifiers: visibility and aura flags
  if obj:extra_flagged(EF.INVISIBLE) then t[#t+1] = " (invisible)" end
  if obj:extra_flagged(EF.BLESS) and viewer:aff_flagged(AF.DETECT_ALIGN) then
    t[#t+1] = " ..It glows blue!"
  end
  if obj:extra_flagged(EF.MAGIC) and viewer:aff_flagged(AF.DETECT_MAGIC) then
    t[#t+1] = " ..It glows yellow!"
  end
  if obj:extra_flagged(EF.GLOW) then t[#t+1] = " @D(@GGlowing@D)@n" end
  if obj:extra_flagged(EF.HOT)  then t[#t+1] = " @D(@RHOT@D)@n"     end
  if obj:extra_flagged(EF.HUM)  then t[#t+1] = " @D(@RHumming@D)@n" end

  -- Token slots
  if obj:extra_flagged(EF.SLOT2) then
    if obj:extra_flagged(EF.SLOT_ONE) and not obj:extra_flagged(EF.SLOTS_FILLED) then
      t[#t+1] = " @D[@m1/2 Tokens@D]@n"
    elseif obj:extra_flagged(EF.SLOTS_FILLED) then
      t[#t+1] = " @D[@m2/2 Tokens@D]@n"
    else
      t[#t+1] = " @D[@m0/2 Tokens@D]@n"
    end
  end
  if obj:extra_flagged(EF.SLOT1) then
    if obj:extra_flagged(EF.SLOTS_FILLED) then
      t[#t+1] = " @D[@m1/1 Tokens@D]@n"
    else
      t[#t+1] = " @D[@m0/1 Tokens@D]@n"
    end
  end

  -- Ki charge distance
  if obj:kicharge_get() > 0 then
    t[#t+1] = string.format(" %d meters away", obj:distance_get() * 20 + math.random(1, 5))
  end

  -- Custom / restring labels
  if obj:extra_flagged(EF.CUSTOM)   then t[#t+1] = " @D(@YCUSTOM@D)@n" end
  if obj:extra_flagged(EF.RESTRING) then t[#t+1] = " @D(@R*@D)@n"      end

  -- Broken condition or trailing period
  if obj:extra_flagged(EF.BROKEN) then
    local mat = obj:value_get(7)  -- VAL_ALL_MATERIAL = 7
    if mat == MAT.STEEL or mat == MAT.MITHRIL or mat == MAT.METAL then
      t[#t+1] = ", and appears to be twisted and broken."
    elseif mat == MAT.WOOD then
      t[#t+1] = ", and is broken into hundreds of splinters."
    elseif mat == MAT.GLASS then
      t[#t+1] = ", and is shattered on the ground."
    elseif mat == MAT.STONE then
      t[#t+1] = ", and is a pile of rubble."
    else
      t[#t+1] = ", and is broken."
    end
  else
    if otype ~= IT.BOARD and otype ~= IT.CONTAINER then
      t[#t+1] = "."
    end
  end

  t[#t+1] = "\n"
  return table.concat(t)
end

return {
  keywords_for = keywords_for,
  display_name_for = display_name_for,
  stack_key = stack_key,
  render_inventory_line = render_inventory_line,
  modifiers = modifiers,
  on_mud_hour = on_mud_hour,
  on_second = on_second,
  on_heartbeat = on_heartbeat,
}
