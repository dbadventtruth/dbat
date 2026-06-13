#include "character_db.h"
#include "character_api.h"
#include "character_impl.h"
#include "consts/search.h"
#include "consts/triggers.h"
#include "object_api.h"
#include "object_impl.h"

#include "iterate.hpp"

struct char_data *affect_list;

long max_mob_id = MOB_ID_BASE;

struct mob_proto_data *mob_proto_by_id(mob_vnum vnum) {
  return mob_proto_get(vnum);
}

mob_vnum mob_proto_vnum_check(mob_vnum vnum) {
  return mob_proto_by_id(vnum) ? vnum : NOTHING;
}

struct obj_data *char_inventory_search_vnum(struct char_data *ch, obj_vnum vnum,
                                            bool recursive, int flags) {
  struct obj_vnum_search_data data = {
      .vnum = vnum, .flags = flags, .ch = ch, .found = nullptr};
  char_inventory_iterate(ch, recursive, obj_search_vnum_match, &data);
  return data.found;
}

struct obj_data *char_inventory_search_type(struct char_data *ch, int type,
                                            bool recursive, int flags) {
  struct obj_type_search_data data = {
      .type = type, .flags = flags, .ch = ch, .found = nullptr};
  char_inventory_iterate(ch, recursive, obj_search_type_match, &data);
  return data.found;
}

int64_t char_legacy_modifier(struct char_data *ch, int location, int specific) {
  int64_t mod = 0;

  char_equipment_iterate(ch, [&](auto i, auto eq) {
    for (auto j = 0; j < MAX_OBJ_AFFECT; j++) {
      auto &af = eq->affected[j];
      if (af.location != location)
        continue;
      if (af.specific == specific ||
          specific == -1) {
        mod += af.modifier;
      }
    }
    return true;
  });

  for (auto af = ch->affected; af; af = af->next) {
    if (af->location != location)
      continue;
    if (af->specific == specific || af->specific == -1) {
      mod += af->modifier;
    }
  }
  return mod;
}
