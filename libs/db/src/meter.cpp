#include "dbat/db/meter.h"

const struct meter_definition meter_definitions[NUM_METERS] = {
    {"Powerlevel", 0, DER_POWERLEVEL_SUPPRESSED},
    {"Ki", 0, DER_KI},
    {"Stamina", 0, DER_STAMINA},
    {"Life Force", 0, DER_LIFE_FORCE},
};