#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Zone API functions, implemented in zones_api.zig
zone_vnum zone_id_get(struct zone_data *zone);
void zone_id_set(struct zone_data *zone, zone_vnum id);
const char *zone_name_get(struct zone_data *zone);
void zone_name_set(struct zone_data *zone, const char *value);
const char *zone_builders_get(struct zone_data *zone);
void zone_builders_set(struct zone_data *zone, const char *value);
int zone_lifespan_get(struct zone_data *zone);
void zone_lifespan_set(struct zone_data *zone, int lifespan);
int zone_age_get(struct zone_data *zone);
void zone_age_set(struct zone_data *zone, int age);
room_vnum zone_bottom_get(struct zone_data *zone);
void zone_bottom_set(struct zone_data *zone, room_vnum bottom);
room_vnum zone_top_get(struct zone_data *zone);
void zone_top_set(struct zone_data *zone, room_vnum top);
int zone_reset_mode_get(struct zone_data *zone);
void zone_reset_mode_set(struct zone_data *zone, int mode);
int zone_min_level_get(struct zone_data *zone);
void zone_min_level_set(struct zone_data *zone, int level);
int zone_max_level_get(struct zone_data *zone);
void zone_max_level_set(struct zone_data *zone, int level);
bool zone_flagged(struct zone_data *zone, int pos);
bool zone_flag_toggle(struct zone_data *zone, int pos);
void zone_flag_set(struct zone_data *zone, int pos, bool value);
struct reset_com *zone_command_get(struct zone_data *zone, size_t index);

char zone_command_type_get(struct reset_com *cmd);
void zone_command_type_set(struct reset_com *cmd, char command);
bool zone_command_if_flag_get(struct reset_com *cmd);
void zone_command_if_flag_set(struct reset_com *cmd, bool value);
int zone_command_arg_get(struct reset_com *cmd, size_t index);
void zone_command_arg_set(struct reset_com *cmd, size_t index, int value);
int zone_command_line_get(struct reset_com *cmd);
void zone_command_line_set(struct reset_com *cmd, int line);
const char *zone_command_sarg1_get(struct reset_com *cmd);
void zone_command_sarg1_set(struct reset_com *cmd, const char *value);
const char *zone_command_sarg2_get(struct reset_com *cmd);
void zone_command_sarg2_set(struct reset_com *cmd, const char *value);

void zone_player_count_inc(zone_vnum vnum);
void zone_player_count_dec(zone_vnum vnum);
int zone_player_count_get(zone_vnum vnum);

#ifdef __cplusplus
}
#endif
