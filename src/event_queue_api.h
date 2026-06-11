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

// Cancel a previously scheduled event by ID. Safe to call with stale IDs.
void eq_cancel(uint64_t id);

// Milliseconds until the event fires, or -1 if not pending (unknown/cancelled).
int64_t eq_remaining_ms(uint64_t id);

// Current wall time in milliseconds. Use as base for fire_at calculations.
int64_t event_queue_now_ms(void);

// Register all heartbeat sub-functions as recurring events.
// Called once at startup after config and Lua are loaded.
void event_queue_register_heartbeat_events(void);

#ifdef __cplusplus
}
#endif
