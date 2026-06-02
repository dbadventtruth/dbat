#pragma once

#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

extern struct char_data *character_list;
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