#pragma once
#include "consts/types.h"

typedef int64_t stat_t;

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
#define STAT_SENSEI 2
#define STAT_SIZE 3
#define STAT_LEVEL 4
#define STAT_HEIGHT 5
#define STAT_WEIGHT 6

#define STAT_SEX 7
#define STAT_HAIR_LENGTH 8
#define STAT_HAIR_STYLE 9
#define STAT_HAIR_COLOR 10
#define STAT_SKIN_COLOR 11
#define STAT_EYE_COLOR 12
#define STAT_DISTINGUISHING_FEATURE 13
#define STAT_AURA_COLOR 14

#define STAT_ALIGNMENT 15

#define STAT_STRENGTH 16
#define STAT_INTELLIGENCE 17
#define STAT_WISDOM 18
#define STAT_AGILITY 19
#define STAT_CONSTITUTION 20
#define STAT_SPEED 21

// the training data for increasing Attributes.
#define STAT_STRENGTH_TRAIN 22
#define STAT_INTELLIGENCE_TRAIN 23
#define STAT_WISDOM_TRAIN 24
#define STAT_AGILITY_TRAIN 25
#define STAT_CONSTITUTION_TRAIN 26
#define STAT_SPEED_TRAIN 27

#define STAT_POWERLEVEL 28
#define STAT_KI 29
#define STAT_STAMINA 30

#define STAT_WIMPY 31

#define STAT_HUNGER 32
#define STAT_THIRST 33
#define STAT_DRUNK 34

#define STAT_PRACTICES 35
#define STAT_UPGRADES 36
#define STAT_MOLT_LEVEL 37
#define STAT_MOLT_EXPERIENCE 38

// Standing, fighting, sleeping, etc
#define STAT_POSITION 39

#define STAT_SKILL_SLOTS 40

#define STAT_MONEY 41
#define STAT_MONEY_BANK 42

#define STAT_CHARGE 43
#define STAT_BARRIER 44
#define STAT_SUPPRESS 45

#define STAT_DEATH_COUNT 46
#define STAT_KILL_COUNT 47
#define STAT_PLAYER_KILL_COUNT 48

#define NUM_CHARACTER_STATS 49

extern const struct stat_definition stat_definitions[NUM_CHARACTER_STATS];