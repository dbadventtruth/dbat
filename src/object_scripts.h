#pragma once
#include "object_impl.h"
#ifdef __cplusplus
extern "C" {
#endif

bool obj_script_add(struct obj_data *obj, const char *script_id);
bool obj_script_remove(struct obj_data *obj, const char *script_id, const char *reason);
bool obj_script_has(struct obj_data *obj, const char *script_id);
int64_t     obj_script_number_get(struct obj_data *obj, const char *script_id, const char *key);
void        obj_script_number_set(struct obj_data *obj, const char *script_id, const char *key, int64_t value);
const char *obj_script_text_get(struct obj_data *obj, const char *script_id, const char *key);
void        obj_script_text_set(struct obj_data *obj, const char *script_id, const char *key, const char *value);
void        obj_script_event_dispatch(struct obj_data *obj, const char *script_id, const char *event_name);

#ifdef __cplusplus
}
#endif
