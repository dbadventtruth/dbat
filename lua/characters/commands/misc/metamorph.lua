local dbat = require("dbat")

local function execute(ctx)
    local ch = ctx.ch

    if not ch:know_skill("metamorph") then
        return
    end

    if ch:stat_get("alignment") >= 51 then
        ch:send_line("Your heart is too pure to use that technique!")
        return
    end

    local cost = math.floor(ch:meter_max("ki") * 0.16)

    if ch:condition_has("dark_metamorphosis") then
        ch:send_line("You are already surrounded by a dark aura!")
        return
    end

    if ch:meter_current("ki") < cost then
        ch:send_line(string.format("You do not have enough ki. You need %d.", cost))
        return
    end

    local wis   = ch:stat_get("wisdom")
    local perc  = wis * 2
    if perc < 100 and perc > 60 then
        perc = perc + (100 - perc)
    elseif perc < 100 then
        perc = perc + 10
    end

    ch:meter_mod("ki", -math.floor(cost / 2))

    if perc < dbat.axion_dice(0) then
        ch:send_line("@WYou focus your energies and prepare your @RDark Metamorphisis@W but screw up your focus!@n")
        ch:act_around("@WA dark @Rred@W glow starts to surround @C$n@W, but it fades quickly.@n")
        return
    end

    ch:send_line("'@RDark@W...' An explosion of sanguine aura erupts over the surface of your body, your eyes darkening to a bleeding crimson. The flaring glow emanating from your body pronounces the shadows cast, a darkening umbrage that threatens a malicious promise. Fists clench tightly, muscles bulking as you hiss; You complete the transition, relaxing visibly, '...@RMetamorphosis@W'@n")
    ch:act_around("'@RDark@W...' An explosion of sanguine aura erupts over the surface of @C$n@W's body, $s eyes darkening to a bleeding crimson. The flaring glow emanating from $s body pronounces the shadows cast, a darkening umbrage that threatens a malicious promise. Fists clench tightly, muscles bulking as $e hisses; $e completes the transition, relaxing visibly, '...@RMetamorphosis@W'@n")

    local duration = math.floor(ch:stat_get("intelligence") / 12) * dbat.consts.secs_per_mud_hour
    ch:condition_apply_with_duration("dark_metamorphosis", "affect", "dark_metamorphosis", duration)
    ch:meter_mod("powerlevel", math.floor(ch:meter_max("powerlevel") * 0.6))
end

return { id = "metamorph", aliases = { { "metamorph", 4 } }, execute = execute }
