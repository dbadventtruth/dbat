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

int room_subscribe_add(struct room_data *room, const char *tag);
void room_subscribe_remove(struct room_data *room, const char *tag);
void room_unsubscribe_all(struct room_data *room);
void room_clear_subscriptions(room_vnum vnum);
room_vnum *room_subscribe_ids(const char *tag, size_t *count);
void room_subscribe_ids_free(room_vnum *ptr);

#ifdef __cplusplus
}
#endif
