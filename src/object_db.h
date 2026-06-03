#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Below this is global variables and database functions
extern struct obj_data *object_list;
extern long max_obj_id;

obj_rnum real_object(obj_vnum vnum);
struct obj_proto_data *obj_proto_by_id(obj_vnum vnum);

void *obj_proto_iterator_create();
struct obj_proto_data *obj_proto_next(void *iterator);
void obj_proto_iterator_free(void *iterator);

struct obj_proto_data *obj_proto_get(obj_vnum vnum);
size_t obj_proto_count();
void obj_proto_put(obj_vnum vnum, struct obj_proto_data *obj);
void obj_proto_delete(obj_vnum vnum);
SpecialFunc obj_proto_special_get(obj_vnum vnum);
void obj_proto_special_set(obj_vnum vnum, SpecialFunc func);
void obj_proto_count_increment(obj_vnum vnum);
size_t obj_proto_count_get(obj_vnum vnum);
void obj_proto_count_decrement(obj_vnum vnum);

struct obj_data *obj_by_id(int64_t id);
int obj_register_id(int64_t id, struct obj_data *obj);
void obj_unregister_id(int64_t id);
int obj_subscribe(int64_t id, const char *list_name);
void obj_unsubscribe(int64_t id, const char *list_name);
void obj_clear_subscriptions(int64_t id);
void obj_for_each(const char *list_name, void (*func)(struct obj_data *obj));

#ifdef __cplusplus
}
#endif
