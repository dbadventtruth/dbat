#pragma once
#include "zone_impl.h"
#ifdef __cplusplus
extern "C" {
#endif

bool zone_script_add(struct zone_data *zone, const char *script_id);
bool zone_script_remove(struct zone_data *zone, const char *script_id, const char *reason);
bool zone_script_has(struct zone_data *zone, const char *script_id);
int64_t     zone_script_number_get(struct zone_data *zone, const char *script_id, const char *key);
void        zone_script_number_set(struct zone_data *zone, const char *script_id, const char *key, int64_t value);
const char *zone_script_text_get(struct zone_data *zone, const char *script_id, const char *key);
void        zone_script_text_set(struct zone_data *zone, const char *script_id, const char *key, const char *value);
void        zone_script_event_dispatch(struct zone_data *zone, const char *script_id, const char *event_name);

#ifdef __cplusplus
}
#endif
