#pragma once
#include "room_impl.h"
#ifdef __cplusplus
extern "C" {
#endif

bool room_script_add(struct room_data *room, const char *script_id);
bool room_script_remove(struct room_data *room, const char *script_id, const char *reason);
bool room_script_has(struct room_data *room, const char *script_id);
int64_t     room_script_number_get(struct room_data *room, const char *script_id, const char *key);
void        room_script_number_set(struct room_data *room, const char *script_id, const char *key, int64_t value);
const char *room_script_text_get(struct room_data *room, const char *script_id, const char *key);
void        room_script_text_set(struct room_data *room, const char *script_id, const char *key, const char *value);
void        room_script_event_dispatch(struct room_data *room, const char *script_id, const char *event_name);

#ifdef __cplusplus
}
#endif
