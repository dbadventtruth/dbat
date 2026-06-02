#pragma once
#include "consts/types.h"
#include "consts/skills.h"
#include "consts/feats.h"

#ifdef __cplusplus
extern "C" {
#endif

guild_rnum real_guild(guild_vnum vnum);
struct guild_data *guild_by_id(guild_vnum vnum);

void* guild_iterator_create();
struct guild_data* guild_next(void* iterator);
void guild_iterator_free(void* iterator);

void guild_put(guild_vnum vnum, struct guild_data *guild);
void guild_delete(guild_vnum vnum);
size_t guild_count();

#ifdef __cplusplus
}
#endif
