#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Colors that the player can define */
typedef enum {
    COLOR_NORMAL      = 0,
    COLOR_ROOMNAME    = 1,
    COLOR_ROOMOBJS    = 2,
    COLOR_ROOMPEOPLE  = 3,
    COLOR_HITYOU      = 4,
    COLOR_YOUHIT      = 5,
    COLOR_OTHERHIT    = 6,
    COLOR_CRITICAL    = 7,
    COLOR_HOLLER      = 8,
    COLOR_SHOUT       = 9,
    COLOR_GOSSIP      = 10,
    COLOR_AUCTION     = 11,
    COLOR_CONGRAT     = 12,
    COLOR_TELL        = 13,
    COLOR_YOUSAY      = 14,
    COLOR_ROOMSAY     = 15,
} ColorChoice;

#define NUM_COLOR 16

extern const char *cchoice_names[NUM_COLOR + 1];

#ifdef __cplusplus
}
#endif
