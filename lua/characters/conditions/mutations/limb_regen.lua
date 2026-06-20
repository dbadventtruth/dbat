local LIMBS = {
    { n = 1, name = "right arm",
      mend_self  = "The bones in your right arm have mended them selves.",
      mend_room  = "$n starts moving $s right arm gingerly for a moment.",
      regrow_self = "Your right arm begins to grow back very quickly. Within moments it is whole again!",
      regrow_room = "$n's right arm starts to regrow! Within moments the arm is whole again!.",
    },
    { n = 2, name = "left arm",
      mend_self  = "The bones in your left arm have mended them selves.",
      mend_room  = "$n starts moving $s left arm gingerly for a moment.",
      regrow_self = "Your right arm begins to grow back very quickly. Within moments it is whole again!",
      regrow_room = "$n's right arm starts to regrow! Within moments the arm is whole again!.",
    },
    { n = 3, name = "right leg",
      mend_self  = "The bones in your right leg have mended them selves.",
      mend_room  = "$n starts moving $s right leg gingerly for a moment.",
      regrow_self = "Your right arm begins to grow back very quickly. Within moments it is whole again!",
      regrow_room = "$n's right arm starts to regrow! Within moments the arm is whole again!.",
    },
    { n = 4, name = "left leg",
      mend_self  = "The bones in your left leg have mended them selves.",
      mend_room  = "$n starts moving $s left leg gingerly for a moment.",
      regrow_self = "Your right arm begins to grow back very quickly. Within moments it is whole again!",
      regrow_room = "$n's right arm starts to regrow! Within moments the arm is whole again!.",
    },
}

local function on_tick(ch, cond)
    for _, limb in ipairs(LIMBS) do
        local cnd = ch:limbcond_get(limb.n)
        if cnd > 0 and cnd < 50 then
            ch:send_line(limb.mend_self)
            ch:act_around(limb.mend_room)
            ch:limbcond_set(limb.n, 100)
        elseif cnd <= 0 then
            ch:send_line(limb.regrow_self)
            ch:act_around(limb.regrow_room)
            ch:limbcond_set(limb.n, 100)
        end
    end
end

return {
    id         = "mutation_limb_regen",
    name       = "Limb Regen",
    tags       = { "mutation" },
    persistent = false,
    on_apply = function(ch, cond)
        cond:schedule_event("tick", 100000, 100000)
    end,
    on_game_activate = function(ch, cond)
        if not cond:event_pending("tick") then
            cond:schedule_event("tick", 100000, 100000)
        end
    end,
    on_remove = function(ch, cond)
        cond:cancel_event("tick")
    end,
    on_event = function(ch, cond, event)
        if event == "tick" then on_tick(ch, cond) end
    end,
}
