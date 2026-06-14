#include "http_meta.h"
#include "consts/roomflags.h"
#include "consts/sectortypes.h"
#include "consts/mobflags.h"
#include "consts/affflags.h"
#include "consts/itemdata.h"
#include "consts/directions.h"
#include "consts/races.h"
#include "consts/senseis.h"
#include "consts/triggers.h"
#include <string.h>

static const char *sentinel_or_null(const char *s) {
    if (!s || s[0] == '\n') return NULL;
    return s;
}

const char *http_meta_room_flag_name(int bit) {
    if (bit < 0 || bit >= NUM_ROOM_FLAGS) return NULL;
    return sentinel_or_null(room_bits[bit]);
}
int http_meta_room_flag_count(void) { return NUM_ROOM_FLAGS; }

const char *http_meta_sector_type_name(int id) {
    if (id < 0 || id >= NUM_ROOM_SECTORS) return NULL;
    return sentinel_or_null(sector_types[id]);
}
int http_meta_sector_type_count(void) { return NUM_ROOM_SECTORS; }

const char *http_meta_mob_flag_name(int bit) {
    if (bit < 0 || bit >= NUM_MOB_FLAGS) return NULL;
    return sentinel_or_null(action_bits[bit]);
}
int http_meta_mob_flag_count(void) { return NUM_MOB_FLAGS; }

const char *http_meta_aff_flag_name(int bit) {
    if (bit < 0 || bit >= NUM_AFF_FLAGS) return NULL;
    return sentinel_or_null(affected_bits[bit]);
}
int http_meta_aff_flag_count(void) { return NUM_AFF_FLAGS; }

const char *http_meta_object_type_name(int id) {
    if (id < 0 || id >= NUM_ITEM_TYPES) return NULL;
    return sentinel_or_null(item_types[id]);
}
int http_meta_object_type_count(void) { return NUM_ITEM_TYPES; }

const char *http_meta_object_extra_flag_name(int bit) {
    if (bit < 0 || bit >= NUM_ITEM_FLAGS) return NULL;
    return sentinel_or_null(extra_bits[bit]);
}
int http_meta_object_extra_flag_count(void) { return NUM_ITEM_FLAGS; }

const char *http_meta_object_wear_flag_name(int bit) {
    if (bit < 0 || bit >= NUM_ITEM_WEARS) return NULL;
    return sentinel_or_null(wear_bits[bit]);
}
int http_meta_object_wear_flag_count(void) { return NUM_ITEM_WEARS; }

const char *http_meta_direction_name(int id) {
    if (id < 0 || id >= NUM_OF_DIRS) return NULL;
    return sentinel_or_null(dirs[id]);
}
int http_meta_direction_count(void) { return NUM_OF_DIRS; }

const char *http_meta_race_name(int id) {
    if (id < 0 || id >= NUM_RACES) return NULL;
    return sentinel_or_null(race_names[id]);
}
int http_meta_race_count(void) { return NUM_RACES; }

const char *http_meta_sensei_name(int id) {
    if (id < 0 || id >= MAX_SENSEI) return NULL;
    return sensei_style[id]; /* no sentinel in this array */
}
int http_meta_sensei_count(void) { return MAX_SENSEI; }

static const char *dgscript_attach_names[] = {"mob", "obj", "room"};
const char *http_meta_dgscript_attach_type_name(int id) {
    if (id < 0 || id > 2) return NULL;
    return dgscript_attach_names[id];
}
int http_meta_dgscript_attach_type_count(void) { return 3; }

const char *http_meta_mob_trig_name(int bit) {
    if (bit < 0 || bit >= NUM_MTRIG_TYPES) return NULL;
    return sentinel_or_null(trig_types[bit]);
}
const char *http_meta_obj_trig_name(int bit) {
    if (bit < 0 || bit >= NUM_OTRIG_TYPES) return NULL;
    return sentinel_or_null(otrig_types[bit]);
}
const char *http_meta_room_trig_name(int bit) {
    if (bit < 0 || bit >= NUM_WTRIG_TYPES) return NULL;
    return sentinel_or_null(wtrig_types[bit]);
}
int http_meta_trig_type_count(void) { return NUM_MTRIG_TYPES; }
