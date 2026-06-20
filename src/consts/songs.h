#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Ocarina Songs */
typedef enum {
    SONG_SAFETY          = 1,
    SONG_SHIELDING       = 2,
    SONG_SHADOW_STITCH   = 3,
    SONG_TELEPORT_EARTH  = 4,
    SONG_TELEPORT_KONACK = 5,
    SONG_TELEPORT_ARLIA  = 6,
    SONG_TELEPORT_NAMEK  = 7,
    SONG_TELEPORT_VEGETA = 8,
    SONG_TELEPORT_FRIGID = 9,
    SONG_TELEPORT_AETHER = 10,
    SONG_TELEPORT_KANASSA = 11,
} OcarinaSong;

extern const char *song_types[];

#ifdef __cplusplus
}
#endif
