local dbat = require("dbat")
local act  = dbat.lib.act
local fmt  = dbat.lib.text.add_commas
local PLR  = dbat.consts.player_flags

-- Port of tick_player_android_absorb() from act.other.cpp.
-- Fires every 2 seconds via the condition "tick" event.

local function send_stop(ch, target, msg_ch, msg_vict, msg_room)
  act.message(
    { actor = msg_ch, target = msg_vict, room = msg_room },
    { actor = ch, target = target }
  )
  -- Original code: set_fighting(ch, ABSORBBY(target)) which resolves to
  -- set_fighting(ch, ch) — a no-op by design since the relationship is intact.
  -- Reproduce faithfully; set_fighting guards against self-fight internally.
  local absorber = target:absorbed_by_get()
  if absorber then
    if not ch:fighting_get() then ch:start_fighting(absorber) end
    if not absorber:fighting_get() then absorber:start_fighting(ch) end
  end
  target:condition_remove("absorbed_by", "absorb_stop")
  ch:condition_remove("absorbing", "absorb_stop")
end

local function absorb_gain(ch, under_cap, is_ki_check, msg_cap, msg_soft)
  if math.random(1, 8) < 6 then return end
  local level = ch:stat_get("level")
  local gain = 1
  if under_cap then
    gain = math.random(level // 2, level * 3) + level * 18
    if level > 30 then gain = gain + math.random(level * 2, level * 4) + level * 50 end
    if level > 60 then gain = gain * 2 end
    if level > 80 then gain = gain * 3 end
    if level > 90 then gain = gain * 4 end
    local leader = ch:following_get() or ch
    if ch:group_bonus(2) == 7 and (not is_ki_check or ch:following_get()) and leader:player_flagged(PLR.SENSEM) then
      local gbonus = math.floor(gain * 0.15)
      gain = gain + gbonus
      ch:send_line(string.format("The leader of your group conveys an extra bonus! @D[@G+%s@D]@n", fmt(gbonus)))
    end
    ch:send_line(string.format(msg_cap, fmt(gain)))
  else
    ch:send_line(string.format(msg_soft, fmt(gain)))
  end
  return gain
end

local function on_tick(ch, cond)
  local target = ch:absorbing_get()
  if not target then return end

  -- Cancel if target moved to a different room
  if ch:room_vnum_get() ~= target:room_vnum_get() then
    ch:send_line(string.format("You stop absorbing %s!", target:name_get()))
    target:condition_remove("absorbed_by", "left_room")
    ch:condition_remove("absorbing", "left_room")
    return
  end

  if ch:race_get() ~= "android" then return end

  local max_ki = ch:meter_max("ki")
  local max_st = ch:meter_max("stamina")
  local threshold_ki = max_ki // 15
  local threshold_st = max_st // 15

  -- Stop if target doesn't have enough of either resource
  if target:meter_current("stamina") < threshold_st
      and target:meter_current("ki") < threshold_ki then
    send_stop(ch, target,
      "@WYou stop absorbing stamina and ki from @c$N as they don't have enough for you to take@W!@n",
      "@C$n@W stops absorbing stamina and ki from you!@n",
      "@C$n@W stops absorbing stamina and ki from @c$N@w!@n")
    return
  end

  -- 4 in 9 chance to skip this tick
  if math.random(1, 9) < 6 then return end

  -- Also skip if both resources are at or below threshold (not strictly both below)
  if target:meter_current("stamina") <= threshold_st
      and target:meter_current("ki") <= threshold_ki then
    return
  end

  -- Drain from target, gain for absorber
  ch:meter_mod_int("ki",      math.floor(max_ki * 0.08))
  ch:meter_mod_int("stamina", math.floor(max_st * 0.08))

  local drain_ki = max_ki // 20
  local drain_st = max_st // 20
  target:meter_set_int("ki",      math.max(1, target:meter_current("ki")      - drain_ki))
  target:meter_set_int("stamina", math.max(1, target:meter_current("stamina") - drain_st))

  act.message(
    {
      actor  = "@WYou absorb stamina and ki from @c$N@W!@n",
      target = "@C$n@W absorbs stamina and ki from you!@n",
      room   = "@C$n@W absorbs stamina and ki from @c$N@w!@n",
    },
    { actor = ch, target = target }
  )
  target:send_line("@wTry 'escape'!@n")

  if ch:meter_current("powerlevel") < ch:meter_max("powerlevel") then
    ch:meter_mod_int("powerlevel", math.floor(max_ki * 0.04))
    ch:send_line("@CYou convert a portion of the absorbed energy into refilling your powerlevel.@n")
  end

  -- Stop if absorber is now full
  if ch:meter_current("ki") >= ch:meter_max("ki")
      and ch:meter_current("stamina") >= ch:meter_max("stamina") then
    send_stop(ch, target,
      "@WYou stop absorbing stamina and ki from @c$N as you are full@W!@n",
      "@C$n@W stops absorbing stamina and ki from you!@n",
      "@C$n@W stops absorbing stamina and ki from @c$N@w!@n")
    return
  end

  -- Passive base stat gains
  local pl_under = not ch:is_soft_cap(0)
  local ki_under = not ch:is_soft_cap(1)
  local st_under = not ch:is_soft_cap(2)

  local pl_gain = absorb_gain(ch, pl_under, false,
    "@gYou gain +@G%s@g permanent powerlevel!@n",
    "@gYou gain +@G%s@g permanent powerlevel. You may need to level.@n")
  if pl_gain then ch:stat_mod("powerlevel", pl_gain) end

  local st_gain = absorb_gain(ch, st_under, false,
    "@gYou gain +@G%s@g permanent stamina!@n",
    "@gYou gain +@G%s@g permanent stamina. You may need to level.@n")
  if st_gain then ch:stat_mod("stamina", st_gain) end

  local ki_gain = absorb_gain(ch, ki_under, true,
    "@gYou gain +@G%s@g permanent ki!@n",
    "@gYou gain +@G%s@g permanent ki. You may need to level.@n")
  if ki_gain then ch:stat_mod("ki", ki_gain) end
end

return {
  id         = "absorbing",
  name       = "Absorbing",
  tags       = { "absorbing" },
  persistent = false,

  on_apply = function(ch, cond)
    cond:schedule_event("tick", 2000, 2000)
  end,

  on_game_activate = function(ch, cond)
    if not cond:event_pending("tick") then
      cond:schedule_event("tick", 2000, 2000)
    end
  end,

  on_remove = function(ch, cond, reason)
    cond:cancel_event("tick")
  end,

  on_event = function(ch, cond, event)
    if event == "tick" then on_tick(ch, cond) end
  end,
}
