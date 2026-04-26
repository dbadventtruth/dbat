#include "dbat/db/stats.h"
#include "dbat/db/consts/sizes.h"

// ORDER: name, flags, default, min, max
const struct stat_definition stat_definitions[NUM_CHARACTER_STATS] = {
    {"strength", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"intelligence", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"wisdom", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"agility", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"constitution", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"speed", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},

    {"powerlevel", STATDEF_MIN, 5, 1, 0},
    {"ki", STATDEF_MIN, 5, 1, 0},
    {"stamina", STATDEF_MIN, 5, 1, 0},

};