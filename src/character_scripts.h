#pragma once
#include "character_impl.h"
#ifdef __cplusplus
extern "C" {
#endif

bool char_script_add(struct char_data *ch, const char *script_id);
bool char_script_remove(struct char_data *ch, const char *script_id, const char *reason);
bool char_script_has(struct char_data *ch, const char *script_id);
int64_t     char_script_number_get(struct char_data *ch, const char *script_id, const char *key);
void        char_script_number_set(struct char_data *ch, const char *script_id, const char *key, int64_t value);
const char *char_script_text_get(struct char_data *ch, const char *script_id, const char *key);
void        char_script_text_set(struct char_data *ch, const char *script_id, const char *key, const char *value);
void        char_script_event_dispatch(struct char_data *ch, const char *script_id, const char *event_name);

#ifdef __cplusplus
}
#endif
