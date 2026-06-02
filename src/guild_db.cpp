#include "guild_impl.h"
#include "guild_db.h"


guild_rnum real_guild(guild_vnum vnum)
{
  return guild_by_id(vnum) ? vnum : NOTHING;
}
