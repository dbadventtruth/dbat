#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Fishing Defines */
typedef enum {
    FISH_NOFISH  = 0,
    FISH_BITE    = 1,
    FISH_HOOKED  = 2,
    FISH_REELING = 3,
} FishState;

#ifdef __cplusplus
}
#endif
