# Global `dbat` API

Everything lives on the `dbat` global table, registered in `src/lua_api.zig` and extended in `lua/bootstrap.lua`.

---

## Top-level Functions

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `dbat.log` | `dbat.log(msg)` | — | Writes to server log |
| `dbat.time` | `dbat.time()` | table | `{hours, day, month, year}` |
| `dbat.weather` | `dbat.weather()` | table | `{pressure, change, sky, sunlight}` |
| `dbat.add_commas` | `dbat.add_commas(n)` | string\|nil | Format integer with thousand separators |
| `dbat.format_number` | `dbat.format_number(n)` | string\|nil | Alias for `add_commas` |
| `dbat.condition_has_tag` | `dbat.condition_has_tag(name, tag)` | bool | Check a condition definition's tags without a character |

---

## Registry Access

Populated after all Lua files load. Use these to look up content definitions.

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `dbat.get` | `dbat.get(category, slug)` | table\|nil | Get one definition by category + id |
| `dbat.category` | `dbat.category(category)` | table | All definitions in a category (`{}` if unknown) |

**Categories:** `commands`, `conditions`, `derived`, `modifiers`, `meters`, `pcommands`, `races`, `senseis`, `skills`, `stats`, `transformations`

---

## Character Dispatch

Called by Zig at runtime; also callable from Lua.

| Function | Signature | Returns | Notes |
|----------|-----------|---------|-------|
| `dbat.characters.pcommand_try` | `dbat.characters.pcommand_try(ch, full_input)` | bool | Dispatch pcommand; bypasses command queue |
| `dbat.characters.command_fallback` | `dbat.characters.command_fallback(ch, cmd_word, arguments)` | bool | Dispatch Lua command after C++ miss |

---

## Entity Iterators / Lookup

| Table / Function | Signature | Returns |
|-----------------|-----------|---------|
| `dbat.characters.by_id` | `dbat.characters.by_id(id)` | Character\|nil |
| `dbat.characters.all` | `dbat.characters.all()` | iterator |
| `dbat.mob_protos.by_id` | `dbat.mob_protos.by_id(vnum)` | MobPrototype\|nil |
| `dbat.objects.by_id` | `dbat.objects.by_id(id)` | Object\|nil |
| `dbat.objects.all` | `dbat.objects.all()` | iterator |
| `dbat.obj_protos.by_id` | `dbat.obj_protos.by_id(vnum)` | ObjectPrototype\|nil |
| `dbat.rooms.by_id` | `dbat.rooms.by_id(vnum)` | Room\|nil |
| `dbat.zones.by_id` | `dbat.zones.by_id(vnum)` | Zone\|nil |

---

## Library Access

After bootstrap, `dbat.lib` holds all utility modules from `lua/lib.lua`:

```lua
dbat.lib.act        -- message rendering (see libs.md)
dbat.lib.comm       -- short aliases for act functions
dbat.lib.text       -- string utilities
dbat.lib.transforms -- transformation system API
dbat.lib.utils      -- partial matching
dbat.lib.search     -- entity search
dbat.lib.multiform  -- clone/multiform stat helpers
```

---

## Constants (`dbat.consts`)

All constants are integers. Access via `dbat.consts.<group>.<name>`.

| Group | Contents |
|-------|----------|
| `positions` | `STANDING`, `SITTING`, `RESTING`, `SLEEPING`, etc. |
| `races` | Legacy race integer ids |
| `sexes` | `NEUTRAL`, `MALE`, `FEMALE` |
| `sizes` | Size category integers |
| `aligns` | Alignment values |
| `room_flags` | `DARK`, `INDOORS`, `PEACEFUL`, `REGEN`, etc. |
| `sector_types` | `INSIDE`, `CITY`, `FIELD`, `FOREST`, `HILLS`, `MOUNTAIN`, `WATER_SWIM`, etc. |
| `item_types` | `WEAPON`, `ARMOR`, `CONTAINER`, `FOOD`, `DRINK`, etc. |
| `item_wear_flags` | `TAKE`, `FINGER`, `NECK`, `BODY`, `HEAD`, `LEGS`, `FEET`, `HANDS`, `ARMS`, `SHIELD`, `ABOUT`, `WAIST`, `WRIST`, `WIELD`, `HOLD`, etc. |
| `item_extra_flags` | `GLOW`, `HUM`, `NO_RENT`, `NO_DONATE`, `INVISIBLE`, `MAGIC`, `NO_DROP`, `BLESSED`, etc. |
| `aff_flags` | `BLIND`, `INVISIBLE`, `DETECT_ALIGN`, `DETECT_INVIS`, `SENSE_LIFE`, `SNEAK`, `HIDE`, `FLY`, etc. |
| `mob_flags` | `SPEC`, `SENTINEL`, `SCAVENGER`, `ISNPC`, `AWARE`, `AGGR`, `WIMPY`, etc. |
| `player_flags` | `KILLER`, `THIEF`, `FROZEN`, `DONTSET`, `WRITING`, `MAILING`, etc. |
| `admin_flags` | `WIZINVIS`, `NOHASSLE`, `ROOMFLAGS`, `HOLYLIGHT`, etc. |
| `adm_levels` | `IMMORT`, `BUILDER`, `CODER`, `GRGOD`, `IMPL`, etc. |
| `prf_flags` | `BRIEF`, `COMPACT`, `NOSHOUT`, `NOTELL`, `AUTOEXIT`, `COLOR_1`, `COLOR_2`, etc. |
| `wear_positions` | `WEAR_FINGER_R`, `WEAR_NECK_1`, `WEAR_BODY`, `WEAR_HEAD`, `WEAR_WIELD`, etc. |
| `skills` | Named skill integer ids |
| `senseis` | Legacy sensei integer ids |
| `directions` | `NORTH`, `EAST`, `SOUTH`, `WEST`, `UP`, `DOWN`, etc. |
| `con_states` | Connection state integers |
| `applies` | `APPLY_NONE`, `APPLY_STR`, `APPLY_DEX`, etc. (legacy affect locations) |
| `death_types` | Death cause integers |
| `aura_colors` | Aura color integers |
| `attack_types` | Attack type integers |
| `liquid_types` | Liquid type integers |
| `materials` | Material type integers |
| `spell_levels` | Spell level integers |
| `magic_domains` | Magic domain integers |
| `magic_schools` | Magic school integers |

---

## Test Utilities (`dbat.test`)

Only meaningful in test mode (`zig-out/bin/dbat -t`).

| Function | Signature | Returns |
|----------|-----------|---------|
| `dbat.test.mode_enabled` | `dbat.test.mode_enabled()` | bool |
| `dbat.test.mob_proto_exists` | `dbat.test.mob_proto_exists(vnum)` | bool |
| `dbat.test.obj_proto_exists` | `dbat.test.obj_proto_exists(vnum)` | bool |
| `dbat.test.loaded_lua_entries` | `dbat.test.loaded_lua_entries()` | integer |

---

## Internal / Bootstrap

| Symbol | Notes |
|--------|-------|
| `dbat._register(ns, cat, slug, path, value)` | Called by Zig after loading each file; applies `wrap()` if a category class exists |
| `dbat._values(list)` | Returns a stateless iterator over a sequential table |
| `dbat._category_to_namespace` | Maps category name → namespace string |
| `dbat._category_classes` | Cache of `wrap`-able category modules |
| `dbat.characters.registry` | Direct registry table: `registry[category][slug]` |
