#pragma once
#ifdef __cplusplus
extern "C" {
#endif

#include "flags.h"

zone_rnum real_zone(zone_vnum vnum);
void zone_game_register(zone_vnum vnum, zone_rnum rnum);
void zone_game_deregister(zone_vnum vnum);
zone_data* zone_by_id(zone_vnum vnum);

#define ZONE_FLAGS(rnum)       (zone_table[(rnum)].zone_flags)
#define ZONE_MINLVL(rnum)      (zone_table[(rnum)].min_level)
#define ZONE_MAXLVL(rnum)      (zone_table[(rnum)].max_level)
#define ZONE_FLAGGED(rnum, flag)   (IS_SET_AR(zone_table[(rnum)].zone_flags, flag))

#ifdef __cplusplus
}
#endif
