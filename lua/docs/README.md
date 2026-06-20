# Lua API Documentation

Reference documentation for the DBAT Lua scripting layer. The API has two surfaces:
- **Userdata methods** — C++/Zig-backed objects passed into Lua scripts
- **Content definition schemas** — the table format each `lua/characters/<category>/` file must return

---

## Files

| File | Contents |
|------|----------|
| [api-character.md](api-character.md) | Character userdata (127 methods), Condition userdata, MobPrototype userdata |
| [api-objects.md](api-objects.md) | Object userdata (77 methods), ObjectPrototype userdata |
| [api-room-zone.md](api-room-zone.md) | Room userdata (26 methods), Zone userdata |
| [api-global.md](api-global.md) | `dbat.*` global functions, registry access, constants table, test utilities |
| [schemas.md](schemas.md) | Definition schemas for conditions, transformations, commands, pcommands, races, senseis, stats, derived stats, meters |
| [libs.md](libs.md) | Utility libraries: act, comm, text, utils, search, multiform, transforms |

---

## Quick Reference

### Common Patterns

**Send a message:**
```lua
ch:send("Hello!\r\n")                        -- raw send
dbat.lib.act.to_char(ch, "Hello!\r\n", {})   -- rendered send
dbat.lib.act.around(ch, "$n waves.", { actor = ch })  -- to room except ch
```

**Find an entity:**
```lua
local s = dbat.lib.search.new(ch)
s:add_room_objects(ch:room_get())
s:add_room_people(ch:room_get())
local target = s:find("orc")           -- first match
local target2 = s:find("2.orc")        -- second match
local all = s:find("all.orc")          -- all matches
```

**Check/apply a condition:**
```lua
if not ch:condition_has("kaioken") then
    ch:condition_apply("kaioken", "transformation", "kaioken")
end
ch:condition_number_set("kaioken", "multiplier", 2)
```

**Get a derived stat:**
```lua
local pl = ch:der_total("powerlevel")
local ki = ch:meter_current("ki")
```

**Access a definition:**
```lua
local def = dbat.get("transformations", "super_saiyan_1")
local all_races = dbat.category("races")
```

---

## Loading Order

1. `lua/bootstrap.lua` — registers `dbat._register`, `dbat.get`, `dbat.category`, dispatch hooks
2. `lua/lib.lua` — loaded into `dbat.lib` by bootstrap
3. All `lua/characters/<category>/*.lua` files — loaded by Zig, registered via `dbat._register`
4. Zig calls `lua_meta.mergeMethods` — merges Lua-side methods (from `lua/characters/character.lua`, etc.) into the C-side metatables

Category load order (from `src/lua_api.zig`):
`commands` → `conditions` → `derived` → `modifiers` → `meters` → `pcommands` → `races` → `senseis` → `skills` → `stats` → `transformations`

---

## Stale Handles

All userdata objects (Character, Object, Room, Zone) are **handles** — thin wrappers around an id or vnum. If the underlying entity is extracted or unloaded between the time you obtained the handle and when you use it, method calls will raise a Lua error. Always check `handle:valid()` when in doubt, especially across coroutine yields or after calling `extract()`.
