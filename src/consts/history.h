#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    HIST_ALL     = 0,
    HIST_SAY     = 1,
    HIST_GOSSIP  = 2,
    HIST_WIZNET  = 3,
    HIST_TELL    = 4,
    HIST_SHOUT   = 5,
    HIST_GRATS   = 6,
    HIST_HOLLER  = 7,
    HIST_AUCTION = 8,
    HIST_SNET    = 9,
} HistoryType;

#define NUM_HIST 10

extern const char *history_types[NUM_HIST + 1];

#ifdef __cplusplus
}
#endif
