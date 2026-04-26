#pragma once
#include "stats.h"

typedef stat_t (*der_func)(struct char_data *ch, uint8_t der_id);

// This struct is used for a global table of derived stat information.
struct der_definition {
    const char* name;
    bitvector_t flags;
    // Every derived_stat needs function pointers for retrieving the base stat.
    der_func base_func;
    // If not provided, effective values are calculated as base + standard applies modifiers.
    der_func effective_func;
    stat_t min_value;
    stat_t max_value;
    int apply; // a legacy apply location that should be checked. leave 0 to disable. If set, legacy affects will be counted as post_bonus modifiers.
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

#define DER_HEIGHT 11
#define DER_WEIGHT 12

#define DER_ARMOR 13

#define DER_FISHING_POLE 14

#define DER_REGEN 15

#define DER_SKILL_LEARN 16

#define DER_WEIGHT_INVENTORY 17
#define DER_WEIGHT_EQUIPPED 18
#define DER_WEIGHT_CARRIED 19
#define DER_WEIGHT_TOTAL 20
#define DER_ITEMS_INVENTORY 21
#define DER_ITEMS_TOTAL 22
#define DER_CARRY_CAPACITY 23
#define DER_WEIGHT_BURDEN 24

#define NUM_DERIVED_STATS 25

// This struct is used for storing derived stat data on the character.
struct der_data {
    // If not calculated, base/effective will be recalculated
    bool calculated;

    // The base value calculated by the base_func.
    stat_t base;
    // Apply modifiers set by affects/applies.
    stat_t pre_bonus;

    stat_t additive_multiplier;

    stat_t post_bonus;

    // The final effective value after all calculations.
    stat_t effective;
    
};

extern const struct der_definition der_definitions[NUM_DERIVED_STATS];