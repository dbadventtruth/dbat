#include "dbat/db/derived.h"
#include "dbat/db/character_utils.h"

stat_t der_attr_base(const struct char_data *ch, uint8_t der_id)
{
    int stat_id;
    switch (der_id) {
        case DER_STRENGTH: stat_id = STAT_STRENGTH; break;
        case DER_INTELLIGENCE: stat_id = STAT_INTELLIGENCE; break;
        case DER_WISDOM: stat_id = STAT_WISDOM; break;
        case DER_AGILITY: stat_id = STAT_AGILITY; break;
        case DER_CONSTITUTION: stat_id = STAT_CONSTITUTION; break;
        case DER_SPEED: stat_id = STAT_SPEED; break;
        default: return 0;
    }
    return char_stats_get(ch, stat_id);
}

const struct der_definition der_definitions[NUM_DERIVED_STATS] = {
    {"strength", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},
    {"intelligence", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},
    {"wisdom", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},
    {"agility", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},
    {"constitution", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},
    {"speed", STATDEF_MIN | STATDEF_MAX, der_attr_base, NULL, 1, 150, {-1, -1, -1, -1, -1}},

    {"powerlevel", 0, NULL, NULL, 1, 0, {-1, -1, -1, -1, -1}},
    {"ki", 0, NULL, NULL, 1, 0, {-1, -1, -1, -1, -1}},
    {"stamina", 0, NULL, NULL, 1, 0, {-1, -1, -1, -1, -1}},
    
    {"life_force", 0, NULL, NULL, 1, 0, {DER_POWERLEVEL, -1, -1, -1, -1}},

    {"powerlevel_suppressed", 0, NULL, NULL, 1, 100, {DER_POWERLEVEL, -1, -1, -1, -1}},
};