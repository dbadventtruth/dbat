#pragma once
#include "consts/directions.h"
#include "consts/itemdata.h"

#include "character_db.h"
#include "character_api.h"
#include "dgscript_db.h"
#include "guild_db.h"
#include "object_db.h"
#include "object_api.h"
#include "room_db.h"
#include "room_api.h"
#include "shop_db.h"
#include "zone_db.h"
#include "zone_api.h"

template <typename Func> inline void mob_proto_iterate(Func &&func) {
  void *iterator = mob_proto_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct mob_proto_data *mob = mob_proto_next(iterator);
    if (!mob) {
      break;
    }
    if (!func(mob)) {
      break;
    }
  }

  mob_proto_iterator_free(iterator);
}

inline void mob_proto_iterate(bool (*func)(struct mob_proto_data *mob)) {
  if (!func) {
    return;
  }
  mob_proto_iterate([&](struct mob_proto_data *mob) { return func(mob); });
}

template <typename Func> inline void obj_proto_iterate(Func &&func) {
  void *iterator = obj_proto_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct obj_proto_data *obj = obj_proto_next(iterator);
    if (!obj) {
      break;
    }
    if (!func(obj)) {
      break;
    }
  }

  obj_proto_iterator_free(iterator);
}

inline void obj_proto_iterate(bool (*func)(struct obj_proto_data *obj)) {
  if (!func) {
    return;
  }
  obj_proto_iterate([&](struct obj_proto_data *obj) { return func(obj); });
}

template <typename Func> inline void trig_proto_iterate(Func &&func) {
  void *iterator = trig_proto_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct trig_data *trig = trig_proto_next(iterator);
    if (!trig) {
      break;
    }
    if (!func(trig)) {
      break;
    }
  }

  trig_proto_iterator_free(iterator);
}

inline void trig_proto_iterate(bool (*func)(struct trig_data *trig)) {
  if (!func) {
    return;
  }
  trig_proto_iterate([&](struct trig_data *trig) { return func(trig); });
}

template <typename Func> inline void room_iterate(Func &&func) {
  void *iterator = room_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct room_data *room = room_next(iterator);
    if (!room) {
      break;
    }
    if (!func(room)) {
      break;
    }
  }

  room_iterator_free(iterator);
}

template <typename Func> inline void room_iterate_id_list(const int *ids, size_t count, Func &&func) {
  for(size_t i = 0; i < count; i++) {
    if(auto room = room_by_id(ids[i])) {
      if(!func(room)) {
        break;
      }
    }
  }
}

template <typename Func> inline void room_iterate_subscriptions(const char* subs, Func &&func) {
  size_t count;
  auto ids = room_subscribe_ids(subs, &count);
  room_iterate_id_list(ids, count, func);
  room_subscribe_ids_free(ids);
}

template <typename Func> inline void obj_iterate_id_list(const int64_t *ids, size_t count, Func &&func) {
  for(size_t i = 0; i < count; i++) {
    if(auto obj = obj_by_id(ids[i])) {
      if(!func(obj)) {
        break;
      }
    }
  }
}

template <typename Func> inline void obj_iterate_subscriptions(const char* subs, Func &&func) {
  size_t count;
  auto ids = obj_subscribe_ids(subs, &count);
  obj_iterate_id_list(ids, count, func);
  obj_subscribe_ids_free(ids);
}

template <typename Func> inline void char_iterate_id_list(const int64_t *ids, size_t count, Func &&func) {
  for(size_t i = 0; i < count; i++) {
    
    if(auto ch = char_by_id(ids[i])) {
      if(!func(ch)) {
        break;
      }
    }
  }
}

template <typename Func> inline void char_iterate_subscriptions(const char* subs, Func &&func) {
  size_t count;
  auto ids = char_subscribe_ids(subs, &count);
  char_iterate_id_list(ids, count, func);
  char_subscribe_ids_free(ids);
}

/* Every live character, unordered. Snapshot-based: safe across extraction. */
template <typename Func> inline void char_iterate_all(Func &&func) {
  size_t count;
  auto ids = char_all_ids(&count);
  char_iterate_id_list(ids, count, func);
  char_subscribe_ids_free(ids);
}

/* Every live character, newest first (matches old character_list order). */
template <typename Func> inline void char_iterate_all_newest(Func &&func) {
  size_t count;
  auto ids = char_all_ids_newest(&count);
  char_iterate_id_list(ids, count, func);
  char_subscribe_ids_free(ids);
}

/* Every live object, unordered. Snapshot-based: safe across extraction. */
template <typename Func> inline void obj_iterate_all(Func &&func) {
  size_t count;
  auto ids = obj_all_ids(&count);
  obj_iterate_id_list(ids, count, func);
  obj_subscribe_ids_free(ids);
}

/* Every live object, newest first (matches old object_list order). */
template <typename Func> inline void obj_iterate_all_newest(Func &&func) {
  size_t count;
  auto ids = obj_all_ids_newest(&count);
  obj_iterate_id_list(ids, count, func);
  obj_subscribe_ids_free(ids);
}

template <typename Func> inline void room_exits_iterate(struct room_data *room, Func &&func) {
  if(!room) return;

  for(auto i = 0; i < NUM_OF_DIRS; i++) {
    if(auto exit = room_dir_option_get(room, i); exit) {
      if(!func(i, exit)) {
        break;
      }
    }
  }
}

/* Snapshot-based room/obj/char containment iterators — safe across extraction
   and modification of the list during iteration. */

template <typename Func> inline void room_people_iterate(struct room_data *room, Func &&func) {
  if(!room) return;
  size_t count;
  auto ids = room_person_ids(room, &count);
  char_iterate_id_list(ids, count, func);
  room_person_ids_free(ids);
}

template <typename Func> inline void room_contents_iterate(struct room_data *room, Func &&func) {
  if(!room) return;
  size_t count;
  auto ids = room_object_ids(room, &count);
  obj_iterate_id_list(ids, count, func);
  room_object_ids_free(ids);
}

template <typename Func> inline void obj_contents_iterate(struct obj_data *obj, Func &&func) {
  if(!obj) return;
  size_t count;
  auto ids = obj_contents_ids(obj, &count);
  obj_iterate_id_list(ids, count, func);
  obj_contents_ids_free(ids);
}

template <typename Func> inline void char_inventory_iterate(struct char_data *ch, Func &&func) {
  if(!ch) return;
  size_t count;
  auto ids = char_inventory_ids(ch, &count);
  obj_iterate_id_list(ids, count, func);
  char_inventory_ids_free(ids);
}

template <typename Func> inline void char_followers_iterate(struct char_data *ch, Func &&func) {
  if(!ch) return;
  size_t count;
  auto ids = char_follower_ids(ch, &count);
  char_iterate_id_list(ids, count, func);
  char_follower_ids_free(ids);
}

template <typename Func> inline void char_equipment_iterate(struct char_data *ch, Func &&func) {
  if(!ch) return;

  for (auto i = 0; i < NUM_WEARS; i++) {
    if (auto o = char_equipment_get(ch, i); o) {
      if (!func(i, o)) {
        break;
      }
    }
  }
}

template <typename Func> inline void zone_iterate(Func &&func) {
  void *iterator = zone_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct zone_data *zone = zone_next(iterator);
    if (!zone) {
      break;
    }
    if (!func(zone)) {
      break;
    }
  }

  zone_iterator_free(iterator);
}

inline void zone_iterate(bool (*func)(struct zone_data *zone)) {
  if (!func) {
    return;
  }
  zone_iterate([&](struct zone_data *zone) { return func(zone); });
}

template <typename Func> inline void shop_iterate(Func &&func) {
  void *iterator = shop_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct shop_data *shop = shop_next(iterator);
    if (!shop) {
      break;
    }
    if (!func(shop)) {
      break;
    }
  }

  shop_iterator_free(iterator);
}

inline void shop_iterate(bool (*func)(struct shop_data *shop)) {
  if (!func) {
    return;
  }
  shop_iterate([&](struct shop_data *shop) { return func(shop); });
}

template <typename Func> inline void guild_iterate(Func &&func) {
  void *iterator = guild_iterator_create();
  if (!iterator) {
    return;
  }

  for (;;) {
    struct guild_data *guild = guild_next(iterator);
    if (!guild) {
      break;
    }
    if (!func(guild)) {
      break;
    }
  }

  guild_iterator_free(iterator);
}

inline void guild_iterate(bool (*func)(struct guild_data *guild)) {
  if (!func) {
    return;
  }
  guild_iterate([&](struct guild_data *guild) { return func(guild); });
}

template <typename Func> inline void zone_iterate_active(Func &&func) {
  zone_iterate([&](struct zone_data *zone) {
    if (zone_player_count_get(zone_id_get(zone)) > 0)
      return func(zone);
    return true;
  });
}

template <typename Func> inline void zone_players_iterate(zone_vnum vnum, Func &&func) {
  size_t count;
  auto ids = zone_player_ids(vnum, &count);
  char_iterate_id_list(ids, count, func);
  zone_player_ids_free(ids);
}

template <typename Func> inline void zone_mobs_iterate(zone_vnum vnum, Func &&func) {
  size_t count;
  auto ids = zone_mob_ids(vnum, &count);
  char_iterate_id_list(ids, count, func);
  zone_mob_ids_free(ids);
}

template <typename Func> inline void zone_objs_iterate(zone_vnum vnum, Func &&func) {
  size_t count;
  auto ids = zone_obj_ids(vnum, &count);
  obj_iterate_id_list(ids, count, func);
  zone_obj_ids_free(ids);
}
