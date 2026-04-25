#pragma once
#include "types.h"

typedef int64_t stat_t;

// this struct is used on char_data to store the actual stats for a character.
struct stat_data {
    // The base value of the stat without any modifiers.
    stat_t value;
    // The cumulative flat modifier for this stat.
    stat_t modifier;
};


// Flags for stat definitions. These control validation and other behavior.
#define STATDEF_MIN (1 << 0)
#define STATDEF_MAX (1 << 1)

// this struct is used for a global table of stat information.
struct stat_definition {
    const char* name;
    // Flags for this stat definition.
    bitvector_t flags;

    // The default value for this stat. Used when creating
    // a new character and when resetting stats.
    stat_t default_value;

    // Min and max are used for validation if the flags are set.
    stat_t min_value;
    stat_t max_value;
};

// TODO: Renumber this all.
#define STAT_RACE 0
#define STAT_RACE_SUBTYPE 1
#define STAT_SENSEI 1
#define STAT_SIZE 2
#define STAT_LEVEL 3
#define STAT_HEIGHT 4
#define STAT_WEIGHT 5

#define STAT_HAIR_LENGTH 6
#define STAT_HAIR_STYLE 7
#define STAT_HAIR_COLOR 8
#define STAT_SKIN_COLOR 9
#define STAT_EYE_COLOR 10
#define STAT_DISTINGUISHING_FEATURE 11
#define STAT_AURA_COLOR 12

#define STAT_ALIGNMENT 13

#define STAT_STRENGTH 14
#define STAT_INTELLIGENCE 15
#define STAT_WISDOM 16
// labeled in-game as agility
#define STAT_DEXTERITY 17
#define STAT_CONSTITUTION 18
// labeled in-game as speed... oi.
#define STAT_CHARISMA 19

// the training data for increasing Attributes.
#define STAT_STRENGTH_TRAIN
#define STAT_INTELLIGENCE_TRAIN
#define STAT_WISDOM_TRAIN
#define STAT_DEXTERITY_TRAIN
#define STAT_CONSTITUTION_TRAIN
#define STAT_CHARISMA_TRAIN

#define STAT_POWERLEVEL
#define STAT_KI
#define STAT_STAMINA

#define STAT_WIMPY
#define STAT_SUPPRESS 

#define STAT_NUTRITION
#define STAT_HYDRATION
#define STAT_DRUNK

#define STAT_PRACTICES
#define STAT_UPGRADES
#define STAT_MOLT_LEVEL
#define STAT_MOLT_EXPERIENCE

// Standing, fighting, sleeping, etc
#define STAT_POSITION

#define STAT_SKILL_SLOTS

#define STAT_MONEY
#define STAT_MONEY_BANK

#define NUM_STATS 20

extern const struct stat_definition stat_definitions[NUM_STATS];