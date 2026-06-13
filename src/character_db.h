#pragma once

#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

struct obj_data;

extern struct char_data *affect_list;

extern long max_mob_id;

mob_vnum mob_proto_vnum_check(mob_vnum vnum);
struct mob_proto_data *mob_proto_by_id(mob_vnum vnum);

struct char_data *char_by_id(int64_t id);
int char_register_id(int64_t id, struct char_data *ch);
void char_unregister_id(int64_t id);
int char_subscribe(int64_t id, const char *list_name);
void char_unsubscribe(int64_t id, const char *list_name);
void char_clear_subscriptions(int64_t id);
void char_for_each(const char *list_name, void (*func)(struct char_data *ch));

int char_subscribe_add(struct char_data *ch, const char *tag);
void char_subscribe_remove(struct char_data *ch, const char *tag);
void char_unsubscribe_all(struct char_data *ch);
int64_t *char_subscribe_ids(const char *tag, size_t *count);
void char_subscribe_ids_free(int64_t *ptr);
int64_t *char_all_ids(size_t *count);
int64_t *char_all_ids_newest(size_t *count);
void char_extract_pending_add(int64_t id);
int64_t *char_extract_pending_take(size_t *count);

void char_inventory_add(struct char_data *ch, struct obj_data *obj);
void char_inventory_remove(struct char_data *ch, struct obj_data *obj);
int64_t *char_inventory_ids(struct char_data *ch, size_t *out_count);
void char_inventory_ids_free(int64_t *ptr);
void char_inventory_move_after(struct char_data *ch, struct obj_data *obj, struct obj_data *after);

void char_follower_add(struct char_data *master, struct char_data *follower);
void char_follower_remove(struct char_data *master, struct char_data *follower);
int64_t *char_follower_ids(struct char_data *master, size_t *out_count);
void char_follower_ids_free(int64_t *ptr);
size_t char_follower_count(struct char_data *master);

void *char_iterator_create();
struct char_data *char_next(void *iterator);
void char_iterator_free(void *iterator);

void *mob_proto_iterator_create();
struct mob_proto_data *mob_proto_next(void *iterator);
void mob_proto_iterator_free(void *iterator);

void mob_proto_put(mob_vnum vnum, struct mob_proto_data *mob);
void mob_proto_delete(mob_vnum vnum);
struct mob_proto_data *mob_proto_get(mob_vnum vnum);
size_t mob_proto_count();
SpecialFunc mob_proto_special_get(mob_vnum vnum);
void mob_proto_special_set(mob_vnum vnum, SpecialFunc func);

void mob_proto_count_increment(mob_vnum vnum);
size_t mob_proto_count_get(mob_vnum vnum);
void mob_proto_count_decrement(mob_vnum vnum);

#ifdef __cplusplus
}
#endif
