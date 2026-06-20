#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* The cardinal directions: used as index to room_data.dir_option[] */
typedef enum {
    NORTH     = 0,
    EAST      = 1,
    SOUTH     = 2,
    WEST      = 3,
    UP        = 4,
    DOWN      = 5,
    NORTHWEST = 6,
    NORTHEAST = 7,
    SOUTHEAST = 8,
    SOUTHWEST = 9,
    INDIR     = 10,
    OUTDIR    = 11,
} Direction;

#define NUM_OF_DIRS 12 /* number of directions in a room (nsewud) */

extern const char *dirs[NUM_OF_DIRS + 1];
extern const char *abbr_dirs[NUM_OF_DIRS + 1];
extern int rev_dir[NUM_OF_DIRS];

#ifdef __cplusplus
}
#endif
