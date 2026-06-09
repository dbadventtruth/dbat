# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands

```bash
zig build              # Build the dbat binary to zig-out/bin/dbat
zig build cdb          # Regenerate compile_commands.json for clangd
zig build include-audit       # Audit C++ header include hygiene
zig build include-self-check  # Verify headers are self-contained
./autorun.sh           # Run server with auto-restart loop
zig-out/bin/dbat       # Run server directly (single instance)
```

## Testing

Tests are Lua scripts in `lua/tests/`. Run them via the test-mode build step:

```bash
zig build && zig-out/bin/dbat -t                         # Run all tests
zig-out/bin/dbat -t --test-file=lua/tests/foo.lua        # Single test file
zig-out/bin/dbat -t --test-filter=conditions             # Filter by name pattern
DBAT_TEST_MODE=1 zig-out/bin/dbat                        # Via env var
```

Each test file must return `true` on success. Exit code 0 = all pass.

## Architecture Overview

DBAT is a Dragon Ball MUD server based on CircleMUD 3.5, implemented in a three-language stack:
- **C++** (157 files, `-std=gnu++23`): legacy game logic — entities, commands, combat, skills, networking
- **Zig** (42 files): program entry point, game loop, entity lifecycle management, Lua orchestration, JSON persistence, network I/O
- **Lua 5.5** (263 files): game content as data — conditions, transformations, stats, races, commands

### Zig/C++ Interop

The bridge works through `src/zig_api.h`, which aggregates ~65 C++ headers. `build.zig` translates this via `zig translate-c` into a `cdb` module importable from Zig. All `.cpp` files are compiled and linked into the same binary.

**Zig → C++:** `pub export fn` in Zig files makes functions callable from C++. Corresponding declarations appear in `*_api.h` headers without implementations.

**C++ → Zig:** `extern fn` declarations in Zig reference C++ functions directly.

All headers wrap declarations in `extern "C" {}` for seamless Zig integration.

### Per-Entity Type Pattern

Each major entity follows a four-file Zig pattern:

| Layer | Purpose |
|-------|---------|
| `character.zig` | HashMaps, lifecycle, subscriptions |
| `character_api.zig` | Exported C API (51K — the main interface layer) |
| `character_json.zig` | JSON serialization/persistence |
| `character_lua.zig` | Lua metatable and event hooks |

Same pattern for: object, room, zone, shop, guild.

`src/root.zig` orchestrates `init()`/`deinit()` for all Zig modules and uses a `comptime` block to force all `pub export fn` symbols into the binary (preventing dead-code elimination of C-callable functions).

### Game Loop

**Entry:** `src/main.zig` → boots DB, opens socket, calls `cdb.game_loop()`

**Loop** (100ms tick, `src/game.zig`):
1. `net_wait()` — poll sockets
2. `net_accept_all_pending()` — new connections
3. `net_read_all_pending()` — read input
4. `game_legacy_process_commands()` — dispatch commands
5. `extract_pending_chars()` — cleanup extracted entities
6. `heartbeat()` — on tick boundary, fires `on_second`/`on_mud_hour`/`on_heartbeat` Lua hooks on all entities
7. `game_legacy_send_outputs()` + `net_flush_all_outputs()` — send output

**Network I/O** is pure Zig (`src/net.zig`) using `poll()`. Telnet protocol parsing is C++ (`descriptor_impl.h`). The two connect via `struct net_connection *conn` in `descriptor_data`.

### Core Entity Types

- **`char_data`** (`src/character_impl.h`): Characters and mobs. Key fields: `id`, `idnum` (-1 for mobs), `in_room`, linked lists for `carrying`/`equipment`/`affected`, combat pointers (`fighting`, `grappling`, etc.)
- **`obj_data`** (`src/object_impl.h`): Items. Key fields: `vnum`, `type_flag`, `value[NUM_OBJ_VAL_POSITIONS]`, wear/extra flags, containment links (`in_obj`/`contains`)
- **`room_data`** (`src/room_impl.h`): Locations. Key fields: `number`, `zone`, `sector_type`, `dir_option[NUM_OF_DIRS]` (14 exits), `people`/`contents` linked lists
- **`affected_type`** (`src/affected_impl.h`): Spell effects on characters. Fields: `type`, `duration`, `modifier`, `location` (APPLY_XXX), `bitvector`

### Command System

Commands are registered in a table in `src/command.cpp` (`cmd_info[]`). Each entry maps a command string to an `ACMD(name)` handler function with minimum level/position requirements. The dispatcher is `command_interpreter()` in the same file.

All command handlers use the macro:
```cpp
ACMD(do_say) { /* ch, argument, cmd, subcmd */ }
```

Commands are grouped by type in `src/act.*.cpp` files (comm, movement, item, attack, offensive, wizard, etc.).

DG Script triggers (`command_wtrigger`, `command_mtrigger`, `command_otrigger`) fire before the command table is checked.

### Lua Scripting System

Scripts live in `lua/` and are loaded at startup by `src/lua_api.zig` into a registry: `dbat.registry[category][slug]`. Categories: `commands`, `conditions`, `derived`, `modifiers`, `meters`, `ocommands`, `races`, `senseis`, `skills`, `stats`, `transformations`.

Each script file returns a table. Example pattern for a condition:
```lua
return {
    id = "kaioken",
    tags = { "power_amp", "kaioken" },
    persistent = false,
    modifiers = function(ch, condition) ... end
}
```

`lua/lib.lua` is the central shared library. `lua/tests/` contains the test suite.

### Affect/Condition Systems

**Legacy:** `struct affected_type` linked list on `char_data`. Functions in `src/affect.h` — `affect_to_char()`, `affect_remove()`, `affect_total()` (recalculates all stats).

**Newer condition system:** `char_condition_add()`, `char_condition_has()`, `char_condition_apply()` in `src/character_api.h`. Supports variables (numbers + strings) and tags for grouping.

### C++ Search Utilities

`src/search.hpp` provides higher-order templates for iterating and searching entity linked lists without allocation:
```cpp
room_people_each(room, [](char_data *ch) { /* ... */ });
character_inventory_find(ch, false, [](obj_data *obj) { return obj->vnum == target; });
```

### Data Storage

Game world data is in `data/world/` (zone/room definitions). Player data in `data/plrfiles/` (JSON). Player housing in `data/housing/` (127K+ individual JSON files). Config/state in `data/etc/`.

### autorun.sh Behavior

Loops `zig-out/bin/dbat`, rotates syslog (6 versions), parses log events into `log/` subdirectories. Exit code 52 from the binary signals a reboot. Control files: `.fastboot` (5s delay), `.killscript` (stop loop), `pause` (hold restarts). Loads `.env` for environment overrides.
