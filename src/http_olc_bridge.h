#pragma once
#include "consts/types.h"

#ifdef __cplusplus
extern "C" {
#endif

int olc_save_rooms(zone_vnum zvnum);
int olc_save_objects(zone_vnum zvnum);
int olc_save_mobs(zone_vnum zvnum);
int olc_save_shops(zone_vnum zvnum);
int olc_save_guilds(zone_vnum zvnum);
int olc_save_zone(zone_vnum zvnum);
int olc_save_triggers(zone_vnum zvnum);

#ifdef __cplusplus
}
#endif
