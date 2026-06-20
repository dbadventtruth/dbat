#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Player conditions */
typedef enum {
    DRUNK  = 0,
    HUNGER = 1,
    THIRST = 2,
} PlayerCond;

#define NUM_CONDITIONS 3

#ifdef __cplusplus
}
#endif
