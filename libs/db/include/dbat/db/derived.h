#pragma once
#include "stats.h"

typedef stat_t (*der_func)(const struct char_data *ch, uint8_t der_id);

// This struct is used for a global table of derived stat information.
struct der_definition {
    const char* name;
    bitvector_t flags;
    // Every derived_stat needs function pointers for retrieving the base stat.
    der_func base_func;
    // If not provided, effective values will be same as base.. for now.
    // Later, we will have the default be a Modifier scanning system.
    der_func effective_func;
    stat_t min_value;
    stat_t max_value;
    int depends_on[5];
};

#define DER_STRENGTH 0
#define DER_INTELLIGENCE 1
#define DER_WISDOM 2
#define DER_AGILITY 3
#define DER_CONSTITUTION 4
#define DER_SPEED 5

#define DER_POWERLEVEL 6
#define DER_KI 7
#define DER_STAMINA 8
#define DER_LIFE_FORCE 9

#define DER_POWERLEVEL_SUPPRESSED 10

#define NUM_DERIVED_STATS 11

// This struct is used for storing derived stat data on the character.
struct der_data {
    stat_t base;
    // Apply modifiers set by affects/applies.
    stat_t applies;
    // The final effective value after all calculations.
    stat_t effective;
    // If not calculated, base/effective will be recalculated
    bool calculated;
};

extern const struct der_definition der_definitions[NUM_DERIVED_STATS];