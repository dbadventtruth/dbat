#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

room_vnum real_room(room_vnum vnum);
struct room_data *room_by_id(room_vnum vnum);
struct room_data *room_get(room_vnum vnum);

void *room_iterator_create();
struct room_data *room_next(void *iterator);
void room_iterator_free(void *iterator);

void room_put(room_vnum vnum, struct room_data *room);
void room_delete(room_vnum vnum);
size_t room_count();

room_vnum room_vnum_check(room_vnum vnum);

#ifdef __cplusplus
}
#endif
