#pragma once
#include "derived.h"

struct meter_definition {
    const char *name;
    uint128_t flags;
    // the derived stat this is a percent of.
    uint8_t der_id;
};

#define MTR_POWERLEVEL 0
#define MTR_KI 1
#define MTR_STAMINA 2
#define MTR_LIFE_FORCE 3

#define NUM_METERS 4

extern const struct meter_definition meter_definitions[NUM_METERS];