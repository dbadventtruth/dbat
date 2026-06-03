#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Characters API, implemented in characters_api.zig
int64_t char_id_get(struct char_data *ch);
void char_id_set(struct char_data *ch, int64_t id);
mob_vnum char_proto_id_get(struct char_data *ch);
void char_proto_id_set(struct char_data *ch, mob_vnum vnum);
mob_vnum char_vnum_get(struct char_data *ch);
void char_vnum_set(struct char_data *ch, mob_vnum vnum);
struct room_data *char_room_get(struct char_data *ch);
struct zone_data *char_zone_get(struct char_data *ch);
zone_vnum char_zone_vnum_get(struct char_data *ch);
room_vnum char_room_vnum_get(struct char_data *ch);
void char_room_vnum_set(struct char_data *ch, room_vnum vnum);
const char *char_name_get(struct char_data *ch);
void char_name_set(struct char_data *ch, const char *value);
const char *char_description_get(struct char_data *ch);
void char_description_set(struct char_data *ch, const char *value);
const char *char_short_description_get(struct char_data *ch);
void char_short_description_set(struct char_data *ch, const char *value);
const char *char_long_description_get(struct char_data *ch);
void char_long_description_set(struct char_data *ch, const char *value);
const char *char_title_get(struct char_data *ch);
void char_title_set(struct char_data *ch, const char *value);

bool char_is_npc(struct char_data *ch);

int char_class_get(struct char_data *ch);
void char_class_set(struct char_data *ch, int chclass);
int char_race_get(struct char_data *ch);
void char_race_set(struct char_data *ch, int race);
int char_size_get(struct char_data *ch);
void char_size_set(struct char_data *ch, int size);
int char_sex_get(struct char_data *ch);
void char_sex_set(struct char_data *ch, int sex);
int char_admlevel_get(struct char_data *ch);
void char_admlevel_set(struct char_data *ch, int admlevel);
bool char_admflagged(struct char_data *ch, int pos);
bool char_admflag_toggle(struct char_data *ch, int pos);
void char_admflag_set(struct char_data *ch, int pos, bool value);
bool char_plrflagged(struct char_data *ch, int pos);
bool char_plrflag_toggle(struct char_data *ch, int pos);
void char_plrflag_set(struct char_data *ch, int pos, bool value);

void char_inventory_iterate(struct char_data *ch, bool recursive,
                            obj_iter_fn func, void *ctx);
void char_equipment_iterate(struct char_data *ch, bool recursive,
                            obj_iter_fn func, void *ctx);
struct obj_data *char_inventory_search_vnum(struct char_data *ch, obj_vnum vnum,
                                            bool recursive, int flags);
struct obj_data *char_inventory_search_type(struct char_data *ch, int type,
                                            bool recursive, int flags);

size_t char_inventory_count(struct char_data *ch, bool recursive);
size_t char_equipment_count(struct char_data *ch, bool recursive);
struct obj_data *char_inventory_get(struct char_data *ch, size_t pos);
struct obj_data *char_equipment_get(struct char_data *ch, size_t pos);

void char_send_text(struct char_data *ch, const char *text);
void char_send_textf(struct char_data *ch, const char *format, ...);
bool char_cmd_execute(struct char_data *ch, const char *command,
                      const char *arguments);

// Character API stuff that makes use of the new Lua API.
void char_zig_free(struct char_data *ch);
int64_t char_stat_get(struct char_data *ch, const char *stat);
int64_t char_stat_set(struct char_data *ch, const char *stat, int64_t value);
int64_t char_stat_mod(struct char_data *ch, const char *stat, int64_t mod);
void char_stats_copy_to_mob_proto(struct char_data *ch,
                                  struct mob_proto_data *proto);
void mob_proto_stats_copy_to_char(struct mob_proto_data *proto,
                                  struct char_data *ch);
void mob_proto_zig_free(struct mob_proto_data *proto);
int64_t mob_proto_stat_get(struct mob_proto_data *proto, const char *stat);
int64_t mob_proto_stat_set(struct mob_proto_data *proto, const char *stat,
                           int64_t value);
int64_t mob_proto_stat_mod(struct mob_proto_data *proto, const char *stat,
                           int64_t mod);

int64_t char_legacy_modifier(struct char_data *ch, int location, int specific);

int64_t char_der_base_get(struct char_data *ch, const char *stat);
int64_t char_der_total_get(struct char_data *ch, const char *stat);
void char_der_invalidate(struct char_data *ch);

int64_t char_meter_get(struct char_data *ch, const char *meter);
int64_t char_meter_set(struct char_data *ch, const char *meter, int64_t value);
int64_t char_meter_set_int(struct char_data *ch, const char *meter,
                           int64_t value);
int64_t char_meter_mod(struct char_data *ch, const char *meter, int64_t mod);
int64_t char_meter_mod_int(struct char_data *ch, const char *meter,
                           int64_t mod);
int64_t char_meter_current(struct char_data *ch, const char *meter);
int64_t char_meter_max(struct char_data *ch, const char *meter);

int64_t char_skill_base_get(struct char_data *ch, const char *skill);
int64_t char_skill_base_set(struct char_data *ch, const char *skill,
                            int64_t value);
int64_t char_skill_base_mod(struct char_data *ch, const char *skill,
                            int64_t mod);
int64_t char_skill_modifier_get(struct char_data *ch, const char *skill);
int64_t char_skill_total_get(struct char_data *ch, const char *skill);
int64_t char_skill_perf_get(struct char_data *ch, const char *skill);
int64_t char_skill_perf_set(struct char_data *ch, const char *skill,
                            int64_t value);
int64_t char_skill_perf_mod(struct char_data *ch, const char *skill,
                            int64_t mod);

struct condition_number_arg {
  const char *key;
  int64_t value;
};

struct condition_string_arg {
  const char *key;
  const char *value;
};

bool char_condition_has(struct char_data *ch, const char *condition);
bool char_condition_id_has_tag(const char *condition, const char *tag);
bool char_condition_has_tag(struct char_data *ch, const char *tag);
const char *char_condition_active_with_tag(struct char_data *ch,
                                           const char *tag);
bool char_condition_add(struct char_data *ch, const char *condition,
                        const char *source_category, const char *source_id);
bool char_condition_add_with_variables(
    struct char_data *ch, const char *condition, const char *source_category,
    const char *source_id, const struct condition_number_arg *numbers,
    size_t number_count, const struct condition_string_arg *strings,
    size_t string_count);
bool char_condition_apply(struct char_data *ch, const char *condition,
                          const char *source_category, const char *source_id);
bool char_condition_apply_with_variables(
    struct char_data *ch, const char *condition, const char *source_category,
    const char *source_id, const struct condition_number_arg *numbers,
    size_t number_count, const struct condition_string_arg *strings,
    size_t string_count);
bool char_condition_apply_with_number(struct char_data *ch,
                                      const char *condition,
                                      const char *source_category,
                                      const char *source_id, const char *key,
                                      int64_t value);
bool char_condition_apply_with_numbers2(struct char_data *ch,
                                        const char *condition,
                                        const char *source_category,
                                        const char *source_id, const char *key1,
                                        int64_t value1, const char *key2,
                                        int64_t value2);
bool char_condition_remove(struct char_data *ch, const char *condition,
                           const char *reason);
int char_condition_remove_tag(struct char_data *ch, const char *tag,
                              const char *reason);
void char_condition_update(struct char_data *ch);
int64_t char_condition_stacks_get(struct char_data *ch, const char *condition);
int64_t char_condition_stacks_set(struct char_data *ch, const char *condition,
                                  int64_t value);
int64_t char_condition_duration_get(struct char_data *ch,
                                    const char *condition);
int64_t char_condition_duration_set(struct char_data *ch, const char *condition,
                                    int64_t value);
int64_t char_condition_number_get(struct char_data *ch, const char *condition,
                                  const char *key);
int64_t char_condition_number_set(struct char_data *ch, const char *condition,
                                  const char *key, int64_t value);
int64_t char_condition_number_mod(struct char_data *ch, const char *condition,
                                  const char *key, int64_t mod);
const char *char_condition_string_get(struct char_data *ch,
                                      const char *condition, const char *key);
bool char_condition_string_set(struct char_data *ch, const char *condition,
                               const char *key, const char *value);

bool char_transform_has(struct char_data *ch, const char *transform);
bool char_transform_add(struct char_data *ch, const char *transform);
bool char_transform_remove(struct char_data *ch, const char *transform);
bool char_transform_unlocked(struct char_data *ch, const char *transform);
bool char_transform_unlock(struct char_data *ch, const char *transform,
                           const char *source);
int64_t char_transform_number_get(struct char_data *ch, const char *transform,
                                  const char *key);
int64_t char_transform_number_set(struct char_data *ch, const char *transform,
                                  const char *key, int64_t value);
int64_t char_transform_number_mod(struct char_data *ch, const char *transform,
                                  const char *key, int64_t mod);
const char *char_transform_string_get(struct char_data *ch,
                                      const char *transform, const char *key);
bool char_transform_string_set(struct char_data *ch, const char *transform,
                               const char *key, const char *value);

#ifdef __cplusplus
}
#endif