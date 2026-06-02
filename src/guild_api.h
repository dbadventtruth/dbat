#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define GW_ARRAY_MAX 4

// Guild API functions, implemented in guilds_api.zig
guild_vnum guild_id_get(struct guild_data *guild);
void guild_id_set(struct guild_data *guild, guild_vnum id);
bool guild_skill_get(struct guild_data *guild, size_t skill);
void guild_skill_set(struct guild_data *guild, size_t skill, bool value);
bool guild_feat_get(struct guild_data *guild, size_t feat);
void guild_feat_set(struct guild_data *guild, size_t feat, bool value);
float guild_charge_get(struct guild_data *guild);
void guild_charge_set(struct guild_data *guild, float charge);
const char *guild_no_such_skill_get(struct guild_data *guild);
void guild_no_such_skill_set(struct guild_data *guild, const char *value);
const char *guild_not_enough_gold_get(struct guild_data *guild);
void guild_not_enough_gold_set(struct guild_data *guild, const char *value);
int guild_min_level_get(struct guild_data *guild);
void guild_min_level_set(struct guild_data *guild, int level);
mob_vnum guild_master_get(struct guild_data *guild);
void guild_master_set(struct guild_data *guild, mob_vnum vnum);
bool guild_trade_flagged(struct guild_data *guild, int pos);
bool guild_trade_flag_toggle(struct guild_data *guild, int pos);
void guild_trade_flag_set(struct guild_data *guild, int pos, bool value);
int guild_open_get(struct guild_data *guild);
void guild_open_set(struct guild_data *guild, int value);
int guild_close_get(struct guild_data *guild);
void guild_close_set(struct guild_data *guild, int value);
SpecialFunc guild_func_get(struct guild_data *guild);
void guild_func_set(struct guild_data *guild, SpecialFunc func);

#ifdef __cplusplus
}
#endif
