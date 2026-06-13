#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

struct char_data;
struct obj_data;

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

void room_person_add(struct room_data *room, struct char_data *ch);
void room_person_remove(struct room_data *room, struct char_data *ch);
int64_t *room_person_ids(struct room_data *room, size_t *out_count);
void room_person_ids_free(int64_t *ptr);

void room_object_add(struct room_data *room, struct obj_data *obj);
void room_object_remove(struct room_data *room, struct obj_data *obj);
int64_t *room_object_ids(struct room_data *room, size_t *out_count);
void room_object_ids_free(int64_t *ptr);

#ifdef __cplusplus
}
#endif
