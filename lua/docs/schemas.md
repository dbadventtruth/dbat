# Content Definition Schemas

Each content file in `lua/characters/<category>/` returns a table. The table is registered by Zig, then passed through the category class's `wrap()` if one exists. The `id` field is authoritative; if absent, the filename slug is used.

All definitions automatically get `id`, `_path`, `_category`, and `_namespace` set by the registration system.

---

## Conditions (`lua/characters/conditions/`)

Class: `lua/characters/conditions.lua` → `Condition.wrap(def)`

**Required:**
```lua
id   = "slug_id",    -- string, must be unique in category
name = "Display Name",
```

**Optional:**
```lua
tags           = { "tag1", "tag2" },      -- default: {}
exclusive_tags = { "exclusive_tag" },     -- conditions with any of these tags conflict
persistent     = false,                   -- survive logout/extract (default: false)
stackable      = false,                   -- allow multiple stacks (default: false)
legacy_affects = { AFF_FLAG_NUM, … },     -- maps to old bitvector flags
modifiers      = function(ch, instance)   -- returns modifier list (see below)
                     return { … }
                 end,
on_apply       = function(ch, instance)         -- called when condition is added
                 end,
on_remove      = function(ch, instance, reason) -- called when condition is removed
                 end,                           -- reason is a string or nil
on_update      = function(ch, instance, ctx)    -- called from C++ tick (rarely needed)
                     -- ctx = { kind="manual"|"second"|..., pulses=n, seconds=n }
                 end,
on_event       = function(ch, instance, event)  -- dispatched via ch:on_update("condition:<id>:<event>")
                 end,                           -- event defaults to "tick" if omitted from kind
```

**Modifier table format** (returned from `modifiers()`):
```lua
{
    target = { "category", "stat_id" },  -- e.g. { "derived", "powerlevel" }
    kind   = "flat"          -- additive bonus (integer)
           | "percent"       -- percent bonus (integer, scaled ×10000; 10000 = 100%)
           | "multiplier"    -- multiplicative (integer, scaled ×10000; 10000 = ×1.0)
           | "override_min"  -- floor override
           | "override_max"  -- ceiling override
           | "set",          -- absolute override
    value  = integer,
    label  = "Source Name",  -- optional display label
}
```

**Condition instance** (second arg to hooks): Condition userdata — see [api-character.md](api-character.md).

---

## Transformations (`lua/characters/transformations/`)

Class: `lua/characters/transformations.lua` → `M.wrap(def)`

**Required:**
```lua
id   = "slug_id",
name = "Display Name",
```

**Optional — identity:**
```lua
alias      = "alt" | { "alt1", "alt2" },  -- alternate names for resolve()
sort_order = 100,                          -- lower = listed first (default: 100000)
family     = "saiyan",                     -- grouping string
tier       = 1,                            -- numeric tier within family
condition  = "condition_id" | false,       -- associated condition; false = no condition
```

**Optional — race/power gating:**
```lua
races       = { "saiyan", "human" },          -- restrict to these races (string or legacy int)
requires_pl = 1200000 | function(ch) end,     -- minimum powerlevel to enter
rpp_cost    = 0,                              -- RP point cost to unlock
```

**Optional — stat effects:**
```lua
bonus  = integer | function(ch) end,  -- flat powerlevel bonus
mult   = 2.0     | function(ch) end,  -- powerlevel multiplier (e.g. 2.0 = double)
drain  = 0.1     | function(ch) end,  -- ki drain rate (default: 0.0)
```

**Optional — predicates (all return `true` or `false, "reason string"`):**
```lua
available     = function(ch) end,       -- show in list at all? (default: race check)
visible       = function(ch) end,       -- show in list to ch? (default: available())
is_unlocked   = function(ch) end,       -- is it unlocked? (default: ch:transform_unlocked(id))
can_unlock    = function(ch, def) end,  -- can ch unlock it?
can_enter     = function(ch, def) end,  -- can ch enter this form?
can_revert    = function(ch, def) end,  -- can ch leave this form?
```

**Optional — hooks:**
```lua
enter        = function(ch, def) end,   -- custom enter logic (skips default condition_apply)
revert       = function(ch, def) end,   -- custom revert logic
display_name = function(ch) end,        -- dynamic display name
form         = function(ch) end,        -- advanced: return form data table
```

**Optional — messages:**
```lua
msg_transform_self   = "You power up!",
msg_transform_others = "$n powers up!",
zone_echo            = "You sense a power surge!" | false,
sense_echo           = "A power flares!",
```

---

## Commands (`lua/characters/commands/`)

Class: `lua/characters/commands.lua` → `M.wrap(def)`

**Required:**
```lua
id      = "command_id",
execute = function(ctx) end,
```

**Optional:**
```lua
aliases  = {
    { "fullword", min_chars },       -- positional form: pattern, minimum length
    { "shortname", 2, sensitive },   -- with case-sensitivity flag
    { name = "word", min = 3 },      -- named form
},
priority = 0,        -- higher = checked first in sorted list (default: 0)
can_see  = function(ch) end,      -- return false to hide from help/lists
can_execute = function(ch) end,   -- return true, or false, "reason"
```

**Execute context object** (`ctx`):
```lua
{
    ch        = Character,   -- the actor
    actor     = Character,   -- alias for ch
    command   = "cmd_id",    -- registered command id
    alias     = "word",      -- the word the player typed
    arguments = "rest of line",
    argparams = {
        raw          = "rest of line",
        tokens       = { "word1", "word2", … },  -- space-split tokens
        equals       = bool,       -- true if "=" present in arguments
        lsargs       = "left",     -- left of "="
        rsargs       = "right",    -- right of "=" (empty string if no "=")
        left_tokens  = { … },
        right_tokens = { … },
    }
}
```

---

## Player Commands / PCommands (`lua/characters/pcommands/`)

**Identical schema to Commands.** Different dispatch: pcommands are matched first (before command queue) by `dbat.characters.pcommand_try`. Use for out-of-band / meta commands that should always be available regardless of combat/position state.

Class: `lua/characters/pcommands.lua` → `M.wrap(def)`

---

## Races (`lua/characters/races/`)

No class wrapper (`wrap` is not defined; definitions are stored raw after id injection).

```lua
{
    id                   = "race_slug",
    legacy_id            = 0,               -- integer mapping from old C++ race enum
    name                 = "Race Name",
    abbreviation         = "Abbr",          -- short code for display
    size                 = "medium",        -- size string
    pc_ok                = true,            -- playable by players
    unavailable_for_races = { "android" },  -- can't be this race if you were one of these
    modifiers            = function(ch)     -- optional, returns modifier list
                               return { … }
                           end,
}
```

---

## Senseis (`lua/characters/senseis/`)

No class wrapper.

```lua
{
    id                   = "sensei_slug",
    legacy_id            = 0,
    name                 = "Trainer Name",
    abbreviation         = "Abbr",
    style                = "Fighting Style Name",
    location             = room_vnum,       -- room where sensei NPC lives
    start_room           = room_vnum,       -- player start room for this sensei
    pc_ok                = true,
    unavailable_for_races = { "race_slug" },
    modifiers            = function(ch)     -- optional
                               return { … }
                           end,
}
```

---

## Stats (`lua/characters/stats/`)

No class wrapper. Stats are simple persistent integers stored by name on each character.

```lua
{
    id            = "stat_slug",
    name          = "Display Name",
    min_value     = -1000,      -- optional; Zig clamps on set
    max_value     = 1000,       -- optional
    default_value = 0,          -- optional; used when stat not yet set
    tags          = { "tag" },  -- optional; used by some systems for grouping
    legacy_modifiers = {        -- optional; maps old APPLY_* location to this stat
        { location_int, specific_int },
    },
}
```

---

## Derived Stats (`lua/characters/derived/`)

No class wrapper. Derived stats are computed from a base stat + modifier accumulation.

```lua
{
    id               = "derived_slug",
    name             = "Display Name",

    -- Base value source (pick one or neither):
    base_stat        = "stat_slug",          -- uses ch:stat_get(base_stat) as base; defaults to id
    calculate_base   = function(ch) end,     -- overrides base_stat if present

    -- Additional modifier targets accumulated into this stat:
    modifier_targets = {
        { "category", "id" },               -- e.g. { "derived", "other_stat" }
    },

    -- Bounds:
    min_value   = 0,         -- optional
    max_value   = 1000,      -- optional
    no_modifiers = false,    -- optional; if true, skip modifier accumulation entirely

    -- Legacy support:
    legacy_modifiers = {
        { location_int, specific_int },
    },
}
```

**Modifier math order** (done in `lua/characters/character.lua:der_total`):
1. Base value (from `calculate_base(ch)` or `ch:stat_get(base_stat)`)
2. Add `flat` bonus
3. Apply `percent` bonus: `value += floor(value * percent / 10000)`
4. Apply each `multiplier`: `value = floor(value * m / 10000)`
5. Clamp to `def.min_value` / `def.max_value`
6. Apply `override_min` / `override_max` from modifier sources
7. Apply `set` override (wins over everything)

---

## Meters (`lua/characters/meters/`)

No class wrapper. Meters are capped resource pools with a current and max value.

```lua
{
    id           = "meter_slug",
    name         = "Display Name",
    derived_stat = "derived_slug",   -- the derived stat used as the max value
    -- also accepted: derived = "derived_slug" (alias)
}
```
