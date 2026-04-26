#include "dbat/db/derived.h"
#include "dbat/db/character_utils.h"
#include "dbat/db/objects.h"
#include "dbat/db/object_utils.h"
#include "dbat/db/consts/applies.h"
#include "dbat/db/utils.h"

static stat_t der_simple_base(struct char_data *ch, uint8_t der_id)
{
    int stat_id;
    switch (der_id) {
        // attributes
        case DER_STRENGTH: stat_id = STAT_STRENGTH; break;
        case DER_INTELLIGENCE: stat_id = STAT_INTELLIGENCE; break;
        case DER_WISDOM: stat_id = STAT_WISDOM; break;
        case DER_AGILITY: stat_id = STAT_AGILITY; break;
        case DER_CONSTITUTION: stat_id = STAT_CONSTITUTION; break;
        case DER_SPEED: stat_id = STAT_SPEED; break;
        // Vitals
        case DER_POWERLEVEL: stat_id = STAT_POWERLEVEL; break;
        case DER_KI: stat_id = STAT_KI; break;
        case DER_STAMINA: stat_id = STAT_STAMINA; break;
        // Physics
        case DER_HEIGHT: stat_id = STAT_HEIGHT; break;
        case DER_WEIGHT: stat_id = STAT_WEIGHT; break;
        default: return 0;
    }
    return char_stats_get(ch, stat_id);
}

static stat_t _obj_weight(struct obj_data *obj) {
    stat_t out = GET_OBJ_WEIGHT(obj);
    struct obj_data *tmp;
    for (tmp = obj->contains; tmp; tmp = tmp->next_content) {
        out += _obj_weight(tmp);
    }
    return out;
}

static stat_t der_weight_inventory(struct char_data *ch, uint8_t der_id)
{
    stat_t out = 0;
    struct obj_data *obj;
    for (obj = ch->carrying; obj; obj = obj->next_content) {
        out += _obj_weight(obj);
    }
    return out;
}

static stat_t der_weight_equipped(struct char_data *ch, uint8_t der_id)
{
    stat_t out = 0;
    for (int i = 0; i < NUM_WEARS; i++) {
        if (GET_EQ(ch, i)) {
            out += _obj_weight(GET_EQ(ch, i));
        }
    }
    return out;
}

static stat_t der_weight_carried(struct char_data *ch, uint8_t der_id)
{
    return char_der_get(ch, DER_WEIGHT_INVENTORY) + char_der_get(ch, DER_WEIGHT_EQUIPPED);
}

static stat_t der_weight_total(struct char_data *ch, uint8_t der_id)
{
    return char_der_get(ch, DER_WEIGHT) + char_der_get(ch, DER_WEIGHT_CARRIED);
}

static stat_t der_itemcount_recurse(struct obj_data *obj) {
    stat_t out = 1;
    struct obj_data *tmp;
    for (tmp = obj->contains; tmp; tmp = tmp->next_content) {
        out += der_itemcount_recurse(tmp);
    }
    return out;
}

static stat_t der_items_inventory(struct char_data *ch, uint8_t der_id)
{
    stat_t out = 0;
    struct obj_data *obj;
    for (obj = ch->carrying; obj; obj = obj->next_content) {
        out += der_itemcount_recurse(obj);
    }
    return out;
}

static stat_t der_items_total(struct char_data *ch, uint8_t der_id)
{
    stat_t out = char_der_get(ch, DER_ITEMS_INVENTORY);
    for (int i = 0; i < NUM_WEARS; i++) {
        if (GET_EQ(ch, i)) {
            out += der_itemcount_recurse(GET_EQ(ch, i));
        }
    }
    return out;
}

static stat_t der_carry_capacity(struct char_data *ch, uint8_t der_id)
{
    stat_t str = char_der_get(ch, DER_STRENGTH);
    stat_t powerlevel = char_der_get(ch, DER_POWERLEVEL);
    return powerlevel / 200 + str * 50;
}

static stat_t der_weight_burden(struct char_data *ch, uint8_t der_id)
{
    stat_t carried = char_der_get(ch, DER_WEIGHT_CARRIED);
    stat_t capacity = char_der_get(ch, DER_CARRY_CAPACITY);
    if(capacity == 0) return 0;
    return (((double)carried / (double)capacity) * 100.0);
}

static stat_t der_powerlevel_suppressed(struct char_data *ch, uint8_t der_id) {
    stat_t powerlevel = char_der_get(ch, DER_POWERLEVEL);
    stat_t burden = 100 - char_der_get(ch, DER_WEIGHT_BURDEN);
    stat_t suppressed = char_stats_get(ch, STAT_SUPPRESS);

    stat_t max_burden = (suppressed > 0) ? MIN(burden, suppressed) : burden;
    if(max_burden <= 0) return 0;
    if(max_burden >= 100) return powerlevel;
    powerlevel = (powerlevel * max_burden) / 100;

    return powerlevel;
}

const struct der_definition der_definitions[NUM_DERIVED_STATS] = {
    // Attributes
    {"strength", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_STR, {-1, -1, -1, -1, -1}},
    {"intelligence", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_INT, {-1, -1, -1, -1, -1}},
    {"wisdom", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_WIS, {-1, -1, -1, -1, -1}},
    {"agility", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_DEX, {-1, -1, -1, -1, -1}},
    {"constitution", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_CON, {-1, -1, -1, -1, -1}},
    {"speed", STATDEF_MIN | STATDEF_MAX, der_simple_base, NULL, 1, 150, APPLY_CHA, {-1, -1, -1, -1, -1}},

    // Vitals
    {"powerlevel", STATDEF_MIN, der_simple_base, NULL, 1, 0, APPLY_HIT, {-1, -1, -1, -1, -1}},
    {"ki", STATDEF_MIN, der_simple_base, NULL, 1, 0, APPLY_MANA, {-1, -1, -1, -1, -1}},
    {"stamina", STATDEF_MIN, der_simple_base, NULL, 1, 0, APPLY_MOVE, {-1, -1, -1, -1, -1}},

    {"life_force", STATDEF_MIN, NULL, NULL, 1, 0, 0, {DER_POWERLEVEL, DER_KI, DER_STAMINA, -1, -1}},

    {"powerlevel_suppressed", STATDEF_MIN, NULL, NULL, 1, 100, 0, {DER_POWERLEVEL, -1, -1, -1, -1}},

    // physics
    {"height", 0, der_simple_base, NULL, 0, 0, APPLY_CHAR_HEIGHT, {-1, -1, -1, -1, -1}},
    {"weight", 0, der_simple_base, NULL, 0, 0, APPLY_CHAR_WEIGHT, {-1, -1, -1, -1, -1}},

    // other
    {"armor", 0, NULL, NULL, 0, 0, APPLY_AC, {-1, -1, -1, -1, -1}},

    {"fishing_pole", 0, NULL, NULL, 0, 0, APPLY_ACCURACY, {-1, -1, -1, -1, -1}},

    {"regen", 0, NULL, NULL, 0, 0, APPLY_REGEN, {-1, -1, -1, -1, -1}},

    {"skill_learn", 0, NULL, NULL, 0, 0, APPLY_TRAIN, {-1, -1, -1, -1, -1}},

    // weight and inventory stuff
    {"weight_inventory", 0, der_weight_inventory, NULL, 0, 0, 0, {-1, -1, -1, -1, -1}},
    {"weight_equipped", 0, der_weight_equipped, NULL, 0, 0, 0, {-1, -1, -1, -1, -1}},
    {"weight_carried", 0, der_weight_carried, NULL, 0, 0, 0, {DER_WEIGHT_INVENTORY, DER_WEIGHT_EQUIPPED, -1, -1, -1}},
    {"weight_total", 0, der_weight_total, NULL, 0, 0, 0, {DER_WEIGHT, DER_WEIGHT_CARRIED, -1, -1, -1}},
    {"items_inventory", 0, der_items_inventory, NULL, 0, 0, 0, {-1, -1, -1, -1, -1}},
    {"items_total", 0, der_items_total, NULL, 0, 0, 0, {DER_ITEMS_INVENTORY, -1, -1, -1, -1}},

    {"carry_capacity", 0, der_carry_capacity, NULL, 0, 0, 0, {DER_POWERLEVEL, DER_STRENGTH, -1, -1, -1}},
    {"weight_burden", 0, der_weight_burden, NULL, 0, 0, 0, {DER_WEIGHT_CARRIED, DER_CARRY_CAPACITY, -1, -1, -1}},
};