#pragma once
#include <stdint.h>

// Context type tags — mirrored from event_queue.zig
#define EQ_CTX_NONE      0
#define EQ_CTX_CHAR_ID   1
#define EQ_CTX_OBJ_ID    2
#define EQ_CTX_ZONE_ID   3
#define EQ_CTX_ROOM_ID   4
#define EQ_CTX_PAIR      5
#define EQ_CTX_LUA_TABLE 6

// Convenience interval constants (milliseconds)
#define EQ_MS_1SEC    1000LL
#define EQ_MS_2SEC    2000LL
#define EQ_MS_5SEC    5000LL
#define EQ_MS_10SEC  10000LL
#define EQ_MS_15SEC  15000LL
#define EQ_MS_1MIN   60000LL

// Owner kinds — mirrored from event_queue.zig
#define EQ_OWNER_NONE 0
#define EQ_OWNER_CHAR 1
#define EQ_OWNER_OBJ  2
#define EQ_OWNER_ROOM 3
#define EQ_OWNER_ZONE 4
#define EQ_OWNER_TRIG 5

#ifdef __cplusplus
extern "C" {
#endif

typedef void (*event_handler_fn)(int ctx_type, int64_t ctx_a, int64_t ctx_b);

// Schedule a Lua-named event (handler looked up by dotted path at fire time).
// Returns a cancellation ID, or 0 on failure.
// fire_at: absolute ms timestamp (use event_queue_now_ms() + delay)
// interval: 0 = one-shot, >0 = recurring interval in ms
uint64_t event_schedule_lua(int64_t fire_at, int64_t interval,
    const char *name,
    int ctx_type, int64_t ctx_a, int64_t ctx_b);

// Schedule a C function handler.
uint64_t event_schedule_c(int64_t fire_at, int64_t interval,
    event_handler_fn handler,
    int ctx_type, int64_t ctx_a, int64_t ctx_b);

// Owned variants: the event is registered under (owner_kind, owner_id) with a
// required kind tag (e.g. "fish_tick"), enabling per-entity cancel/introspection
// and automatic cancellation when the entity is unregistered.
uint64_t event_schedule_c_owned(int64_t fire_at, int64_t interval,
    event_handler_fn handler,
    int ctx_type, int64_t ctx_a, int64_t ctx_b,
    int owner_kind, int64_t owner_id, const char *tag);

uint64_t event_schedule_lua_owned(int64_t fire_at, int64_t interval,
    const char *name,
    int ctx_type, int64_t ctx_a, int64_t ctx_b,
    int owner_kind, int64_t owner_id, const char *tag);

// Cancel a previously scheduled event by ID. Safe to call with stale IDs.
void eq_cancel(uint64_t id);

// Cancel all pending events for an owner; tag NULL = every kind.
// Returns the number of events cancelled.
int64_t eq_cancel_owner(int owner_kind, int64_t owner_id, const char *tag);

// Pending-event count for an owner (tag NULL = every kind).
int64_t eq_owner_count(int owner_kind, int64_t owner_id, const char *tag);

// Milliseconds until the owner's soonest pending event (tag NULL = any kind),
// or -1 if none.
int64_t eq_owner_next_ms(int owner_kind, int64_t owner_id, const char *tag);

// Move a pending event's deadline, keeping its id. 0 = ok, -1 = unknown id.
int eq_reschedule(uint64_t id, int64_t new_fire_at);

// Milliseconds until the event fires, or -1 if not pending (unknown/cancelled).
int64_t eq_remaining_ms(uint64_t id);

// Current wall time in milliseconds. Use as base for fire_at calculations.
int64_t event_queue_now_ms(void);

// Schedule a lua_entity_update event: fires entity:on_event(kind) on the target entity.
// kind is the colon-delimited routing string (e.g. "condition:bonus_healthy:tick").
// It doubles as the owner-index tag, so eq_cancel_owner / eq_owner_count / eq_owner_next_ms
// all work with the same string.
uint64_t event_schedule_lua_char_update(int64_t fire_at, int64_t interval, const char *kind, int64_t char_id);
uint64_t event_schedule_lua_room_update(int64_t fire_at, int64_t interval, const char *kind, int32_t room_id);
uint64_t event_schedule_lua_obj_update (int64_t fire_at, int64_t interval, const char *kind, int64_t obj_id);
uint64_t event_schedule_lua_zone_update(int64_t fire_at, int64_t interval, const char *kind, int32_t zone_id);

// Register all heartbeat sub-functions as recurring events.
// Called once at startup after config and Lua are loaded.
void event_queue_register_heartbeat_events(void);

#ifdef __cplusplus
}
#endif
