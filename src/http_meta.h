#pragma once
#include "consts/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Each function returns the name string for the given index/bit.
 * Returns NULL when the index is out of range.
 * Arrays that use a "\n" sentinel: the function returns NULL for that entry.
 * The *_count functions return the number of valid entries (excluding sentinel). */

/* Room flags (room_bits, NUM_ROOM_FLAGS=66) */
const char *http_meta_room_flag_name(int bit);
int         http_meta_room_flag_count(void);

/* Sector types (sector_types, NUM_ROOM_SECTORS) */
const char *http_meta_sector_type_name(int id);
int         http_meta_sector_type_count(void);

/* Mob action flags (action_bits, NUM_MOB_FLAGS=35) */
const char *http_meta_mob_flag_name(int bit);
int         http_meta_mob_flag_count(void);

/* Mob affect flags (affected_bits, NUM_AFF_FLAGS=79) */
const char *http_meta_aff_flag_name(int bit);
int         http_meta_aff_flag_count(void);

/* Object item types (item_types, NUM_ITEM_TYPES=37) */
const char *http_meta_object_type_name(int id);
int         http_meta_object_type_count(void);

/* Object extra flags (extra_bits, NUM_ITEM_FLAGS=95) */
const char *http_meta_object_extra_flag_name(int bit);
int         http_meta_object_extra_flag_count(void);

/* Object wear flags (wear_bits, NUM_ITEM_WEARS=19) */
const char *http_meta_object_wear_flag_name(int bit);
int         http_meta_object_wear_flag_count(void);

/* Directions (dirs, NUM_OF_DIRS=12) */
const char *http_meta_direction_name(int id);
int         http_meta_direction_count(void);

/* Character races (race_names, NUM_RACES=24) */
const char *http_meta_race_name(int id);
int         http_meta_race_count(void);

/* Character senseis (sensei_style, MAX_SENSEI=15, no sentinel) */
const char *http_meta_sensei_name(int id);
int         http_meta_sensei_count(void);

/* DG Script attach types: 0=mob, 1=obj, 2=room */
const char *http_meta_dgscript_attach_type_name(int id);
int         http_meta_dgscript_attach_type_count(void);

/* DG Script trigger type flags (indexed by bit position) */
const char *http_meta_mob_trig_name(int bit);
const char *http_meta_obj_trig_name(int bit);
const char *http_meta_room_trig_name(int bit);
int         http_meta_trig_type_count(void); /* same for all three: NUM_MTRIG_TYPES=20 */

/* Zone flags (zone_bits, NUM_ZONE_FLAGS=36) */
const char *http_meta_zone_flag_name(int bit);
int         http_meta_zone_flag_count(void);

/* Trade restriction flags for shops/guilds (trade_letters, NUM_TRADERS=78) */
const char *http_meta_trade_flag_name(int bit);
int         http_meta_trade_flag_count(void);

#ifdef __cplusplus
}
#endif
