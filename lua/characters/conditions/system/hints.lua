local hints = {}

hints.id = "system_hints"
hints.name = "System Hints"
hints.tags = { "system" }
hints.persistent = true
hints.description = "Provides hints about the game system to players."


local function schedule_hints(ch, cond)
    if not cond:event_pending("show_hint") then
         -- Show a hint every 5 minutes
        cond:schedule_event("show_hint", 300000, 300000)
    end
end

function hints.on_apply(ch, cond)
    schedule_hints(ch, cond)
    ch:send_line("Hints enabled.")
end

function hints.on_game_activate(ch, cond)
    schedule_hints(ch, cond)
end

function hints.on_remove(ch, cond, reason)
    cond:cancel_event("show_hint")
    ch:send_line("Hints disabled.")
end

-- Add to this list as you add hints to the system.
local hints_list = {
    "Remember to save often.",

    "Remember to eat or drink if you want to stay alive.",

    "It is a good idea to save up PS for learning skills instead of just practicing them.",
    "A good way to save up money is with the bank.",

    "If you want to stay alive in this rough world you will need to be mindful of your surroundings.",

    "Knowing when to rest and recover can be the difference between life and death.",

    "Not every battle can be won. Great warriors know how to pick their fights.",

    "It is a good idea to experiment with skills fully before deciding their worth.",

    "Having a well balanced repertoire of skills can help you out of any situation.",

    "You can become hidden from your enemies on who and ooc with the whohide command.",

    "You can value an item at a shopkeeper with the value command.",

    "There are ways to earn money through jobs, try looking for a job. Bum.",

    "You never know what may be hidden nearby. You should always check out anything you can.",

    "You should check for a help file on any subject you can, you never know how the info may 'help' you.",

    "Until you are capable of taking care of yourself for long periods of time you should stick near your sensei.",

    "You shouldn't travel to other planets until you have a stable supply of money.",

    "There is a vast galaxy out there that you may not be able to reach by public ship.",

    "Score is used to view the various statistics about your character.",

    "Status is used to view what is influencing your character and its characteristics.",

    "You will need a scouter in order to use the Scouter Network (SNET).",

    "Found a bug or have a suggestion? Log into our forums and post in the relevant section."
}

function hints.on_event(ch, cond, event)
    if event == "show_hint" then
        -- Pick a random hint from the list and show it to the player
        local hint = hints_list[math.random(1, #hints_list)]
        ch:send_line("@C[Hint]@n %s", hint)
    end
end

return hints