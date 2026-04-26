#include "dbat/db/stats.h"
#include "dbat/db/consts/sizes.h"

// ORDER: name, flags, default, min, max
const struct stat_definition stat_definitions[NUM_CHARACTER_STATS] = {
    {"race", STATDEF_MIN | STATDEF_MAX, 0, 0, 23},
    {"racial_pref", 0, 0, 0, 0},
    {"sensei", STATDEF_MIN | STATDEF_MAX, 0, 0, 30},
    {"size", STATDEF_MIN | STATDEF_MAX, SIZE_MEDIUM, SIZE_TINY, SIZE_GARGANTUAN},
    {"level", STATDEF_MIN | STATDEF_MAX, 1, 1, 110},
    {"height", 0, 0, 0, 0},
    {"weight", 0, 0, 0, 0},

    {"sex", STATDEF_MIN | STATDEF_MAX, 0, 0, 2},
    // TODO: define ranges for the appearances
    {"hair_length", 0, 0, 0, 0},
    {"hair_style", 0, 0, 0, 0},
    {"hair_color", 0, 0, 0, 0},
    {"skin_color", 0, 0, 0, 0},
    {"eye_color", 0, 0, 0, 0},
    {"distinguishing_feature", 0, 0, 0, 0},
    {"aura_color", 0, 0, 0, 0},

    {"alignment", STATDEF_MIN | STATDEF_MAX, 0, -1000, 1000},

    {"strength", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"intelligence", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"wisdom", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"agility", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"constitution", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},
    {"speed", STATDEF_MIN | STATDEF_MAX, 10, 1, 100},

    {"strength_train", STATDEF_MIN, 0, 0, 0},
    {"intelligence_train", STATDEF_MIN, 0, 0, 0},
    {"wisdom_train", STATDEF_MIN, 0, 0, 0},
    {"agility_train", STATDEF_MIN, 0, 0, 0},
    {"constitution_train", STATDEF_MIN, 0, 0, 0},
    {"speed_train", STATDEF_MIN, 0, 0, 0},

    {"powerlevel", STATDEF_MIN, 5, 1, 0},
    {"ki", STATDEF_MIN, 5, 1, 0},
    {"stamina", STATDEF_MIN, 5, 1, 0},

    {"wimpy", STATDEF_MIN | STATDEF_MAX, 0, 0, 100},

    {"hunger", STATDEF_MIN | STATDEF_MAX, 48, 0, 48},
    {"thirst", STATDEF_MIN | STATDEF_MAX, 48, 0, 48},
    {"drunk", STATDEF_MIN | STATDEF_MAX, 0, 0, 100},

    {"practices", STATDEF_MIN, 0, 0, 0},
    {"upgrades", STATDEF_MIN, 0, 0, 0},
    {"molt_level", STATDEF_MIN, 0, 0, 0},
    {"molt_experience", STATDEF_MIN, 0, 0, 0},

    {"position", STATDEF_MIN | STATDEF_MAX, 8, 0, 8},
    {"skill_slots", STATDEF_MIN, 30, 0, 0},

    {"money", STATDEF_MIN, 0, 0, 0},
    {"money_bank", STATDEF_MIN, 0, 0, 0},

    {"charge", STATDEF_MIN, 0, 0, 0},
    {"barrier", STATDEF_MIN, 0, 0, 0},
    {"suppress", STATDEF_MIN | STATDEF_MAX, 0, 0, 99},

    {"death_count", STATDEF_MIN, 0, 0, 0},
    {"kill_count", STATDEF_MIN, 0, 0, 0},
    {"player_kill_count", STATDEF_MIN, 0, 0, 0},

    {"experience", STATDEF_MIN, 0, 0, 0},
};