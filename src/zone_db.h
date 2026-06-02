#pragma once
#include "consts/types.h"
#include "consts/zoneflags.h"


#ifdef __cplusplus
extern "C" {
#endif

zone_vnum real_zone(zone_vnum vnum);
struct zone_data *zone_by_id(zone_vnum vnum);
struct zone_data *zone_get(zone_vnum vnum);

zone_vnum virtual_zone_by_thing(room_vnum vznum);

void* zone_iterator_create();
struct zone_data* zone_next(void* iterator);
void zone_iterator_free(void* iterator);

void zone_put(zone_vnum vnum, struct zone_data *zone);
void zone_delete(zone_vnum vnum);
size_t zone_count();

#ifdef __cplusplus
}
#endif
