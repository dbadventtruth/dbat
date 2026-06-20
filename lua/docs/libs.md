# Utility Libraries

All libraries are available via `dbat.lib.<name>` after bootstrap, or via `require("lua.libs.<name>")`.

```lua
local act       = dbat.lib.act
local text      = dbat.lib.text
local utils     = dbat.lib.utils
local search    = dbat.lib.search
local multiform = dbat.lib.multiform
local transforms = dbat.lib.transforms
-- dbat.lib.comm is a thin re-export of act functions
```

---

## act (`lua/libs/act.lua`)

Message rendering with placeholder substitution. Templates are strings; `\r\n` is appended if missing.

### Functions

| Function | Signature | Notes |
|----------|-----------|-------|
| `render_for` | `act.render_for(viewer, template, ctx)` | Render template for a specific viewer |
| `render` | `act.render(template, ctx)` | Render without a viewer (no pronoun personalization) |
| `to_char` | `act.to_char(ch, message, ctx)` | Render and send to one character |
| `to_actor` | `act.to_actor(message, ctx)` | Send to `ctx.actor` |
| `to_target` | `act.to_target(message, ctx)` | Send to `ctx.target` |
| `to_room` | `act.to_room(message, ctx)` | Send to all in room (uses `ctx.actor`'s room or `ctx.room`) |
| `around` | `act.around(ch, message, ctx)` | Send to room except `ch` |
| `message` | `act.message(msgs, ctx)` | Dispatch `msgs.actor`, `msgs.target`, `msgs.room` separately |

### Context Fields

| Field | Aliases | Notes |
|-------|---------|-------|
| `actor` | `ch` | The acting character |
| `target` | `victim` | The target character |
| `tool` | `object`, `obj` | An item involved in the action |
| `room` | — | Override room for `to_room` (default: actor's room) |
| `exclude` | — | `{ch, …}` list excluded from `to_room` |
| `hide_invisible` | — | If true, skip characters who can't see actor |

### Placeholders

Used in template strings as `$x` or `$name`:

| Placeholder | Meaning |
|-------------|---------|
| `$n` | Actor name (or "you" if viewer is actor) |
| `$N` | Target name (or "you" if viewer is target) |
| `$p` / `$P` | Tool/object name |
| `$e` | Actor subjective pronoun (he/she/it/you) |
| `$m` | Actor objective pronoun (him/her/it/you) |
| `$s` | Actor possessive pronoun (his/her/its/your) |
| `$E` | Target subjective pronoun |
| `$M` | Target objective pronoun |
| `$S` | Target possessive pronoun |
| `$$` | Literal `$` |
| `$key` | Value of `ctx[key]` (coerced to string) |
| `$func(a,b)` | Call `act.functions["func"](viewer, ctx, {"a","b"})` |

Custom placeholders: add to `act.placeholders["key"] = function(viewer, ctx) end`.  
Custom functions: add to `act.functions["name"] = function(viewer, ctx, args) end`.

---

## comm (`lua/libs/comm.lua`)

Thin re-export of act functions with shorter names.

| Name | Alias for |
|------|-----------|
| `comm.act` | `act.message` |
| `comm.render` | `act.render` |
| `comm.render_for` | `act.render_for` |
| `comm.send_room` | `act.to_room` |

---

## text (`lua/libs/text.lua`)

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `normalize_key` | `text.normalize_key(value)` | string | Lowercase, strip non-alphanumeric. Used for alias matching. |
| `add_commas` | `text.add_commas(value)` | string | Format integer with thousand separators |
| `format_number` | `text.format_number(value)` | string | Alias for `add_commas` |

---

## utils (`lua/libs/utils.lua`)

Partial-match searching over a list.

| Function | Signature | Returns |
|----------|-----------|---------|
| `partial_match` | `utils.partial_match(list, input [, opts])` | value\|nil |
| `partial_matches` | `utils.partial_matches(list, input [, opts])` | {value, …} |

**Options table:**

| Key | Values | Notes |
|-----|--------|-------|
| `case` | `true` or `"sensitive"` | Case-sensitive match; default: case-insensitive |
| `str_func` | `function(v) return string` | Custom stringifier per list item |
| `mode` | `"multi"` | `partial_match` returns all matches instead of first |

**Match priority:**
1. Exact matches (case-insensitive by default)
2. Prefix matches, sorted by string length (shortest first), then list insertion order

---

## search (`lua/libs/search.lua`)

Chainable entity search across multiple providers.

### Construction

```lua
local s = search.new(searcher)   -- searcher = the character doing the looking (for visibility checks)
```

### Provider Methods (chainable)

| Method | Signature | Notes |
|--------|-----------|-------|
| `add_provider` | `s:add_provider(factory)` | `factory` is `function() return iterator` |
| `add_filter` | `s:add_filter(filter)` | `filter(searcher, entity)` → bool |
| `add_room_objects` | `s:add_room_objects(room)` | |
| `add_room_people` | `s:add_room_people(room)` | |
| `add_character_inventory` | `s:add_character_inventory(ch)` | |
| `add_character_equipment` | `s:add_character_equipment(ch)` | |
| `add_object_inventory` | `s:add_object_inventory(obj)` | |
| `add_global_objects` | `s:add_global_objects()` | All objects in world |
| `add_global_characters` | `s:add_global_characters()` | All characters in world |

### Find Methods

| Method | Signature | Returns |
|--------|-----------|---------|
| `find_one` | `s:find_one(pattern)` | entity\|nil |
| `find` | `s:find(pattern)` | entity\|nil (or table if `all.`) |
| `find_all` | `s:find_all(pattern)` | {entity, …} |

### Pattern Syntax

| Pattern | Meaning |
|---------|---------|
| `"sword"` | First entity matching keyword "sword" |
| `"2.sword"` | Second match |
| `"all.sword"` | All matches as a table |
| `"*"` | Match everything (useful for inventory listings) |

Keyword matching uses prefix matching: `"sw"` matches `"sword"`. Entity keywords come from `entity:keywords_for(searcher)` if available.

---

## multiform (`lua/libs/multiform.lua`)

Handle clone-split stat accounting. When a character creates clones, their base stats are divided.

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `multiform.base` | `multiform.base(ch, stat)` | integer | Gets the "true" base stat value, accounting for multiform/clone state |

**Logic:**
- If `ch` has condition `"multiform"` and an original exists: returns `original:der_base(stat)`
- If `ch` has condition `"multiform_original"`: returns `ch:stat_get(stat) // (clones + 1)`
- Otherwise: returns `ch:stat_get(stat)`

---

## transforms (`lua/characters/transformations.lua`)

The transformation system module. Available as `dbat.lib.transforms`.

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `transforms.display_name` | `transforms.display_name(def, ch)` | string | Name shown to player; uses `def.display_name(ch)` or `def.name` or `def.id` |
| `transforms.visible` | `transforms.visible(def, ch)` | bool | Whether ch can see this transformation |
| `transforms.is_unlocked` | `transforms.is_unlocked(def, ch)` | bool | Whether ch has unlocked it |
| `transforms.can_unlock` | `transforms.can_unlock(def, ch)` | bool[, reason] | |
| `transforms.unlock` | `transforms.unlock(def, ch [, source])` | bool | |
| `transforms.requires_pl` | `transforms.requires_pl(def, ch)` | integer | Minimum PL required |
| `transforms.active` | `transforms.active(def, ch)` | bool | Whether ch is currently in this form |
| `transforms.can_enter` | `transforms.can_enter(def, ch)` | bool[, reason] | |
| `transforms.enter` | `transforms.enter(def, ch [, cat [, src]])` | bool[, reason] | |
| `transforms.can_revert` | `transforms.can_revert(def, ch)` | bool[, reason] | |
| `transforms.revert` | `transforms.revert(def, ch [, reason_text])` | bool[, reason] | |
| `transforms.visible_list` | `transforms.visible_list(ch)` | `{{id, def}, …}` | Sorted visible list |
| `transforms.resolve` | `transforms.resolve(ch, input)` | def\|nil | Find def by name/alias input |
