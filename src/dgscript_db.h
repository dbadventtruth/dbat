#pragma once
#include "consts/types.h"
#include <stddef.h>
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

extern struct trig_data *trigger_list;

int64_t trig_assign_id(struct trig_data *trig);
struct trig_data *trig_by_id(int64_t id);
void trig_unregister_id(int64_t id);

void *trig_proto_iterator_create();
struct trig_data *trig_proto_next(void *iterator);
void trig_proto_iterator_free(void *iterator);

struct trig_data *trig_proto_get(trig_vnum vnum);
struct trig_data *trig_proto_by_id(trig_vnum vnum);
size_t trig_proto_count();
void trig_proto_put(trig_vnum vnum, struct trig_data *trig);
void trig_proto_delete(trig_vnum vnum);
void trig_proto_count_increment(trig_vnum vnum);
size_t trig_proto_count_get(trig_vnum vnum);
void trig_proto_count_decrement(trig_vnum vnum);

#ifdef __cplusplus
}
#endif
