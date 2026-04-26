#pragma once
#include "consts/types.h"

// Flags for stat definitions. These control validation and other behavior.
#define STATDEF_MIN (1 << 0)
#define STATDEF_MAX (1 << 1)

// this struct is used for a global table of stat information.
struct stat_definition {
    const char* name;
    // Flags for this stat definition.
    uint128_t flags;

    // The default value for this stat. Used when creating
    // a new character and when resetting stats.
    stat_t default_value;

    // Min and max are used for validation if the flags are set.
    stat_t min_value;
    stat_t max_value;
};

// Attributes
#define STAT_STRENGTH 0
#define STAT_INTELLIGENCE 1
#define STAT_WISDOM 2
#define STAT_AGILITY 3
#define STAT_CONSTITUTION 4
#define STAT_SPEED 5

// Vitals
#define STAT_POWERLEVEL 6
#define STAT_KI 7
#define STAT_STAMINA 8


#define NUM_CHARACTER_STATS 9

extern const struct stat_definition stat_definitions[NUM_CHARACTER_STATS];