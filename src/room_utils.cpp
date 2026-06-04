#include "room_utils.h"
#include "room_api.h"

#include "character_impl.h"
#include "character_macros.h"
#include "consts/applies.h"
#include "consts/itemdata.h"
#include "consts/mobflags.h"
#include "consts/positions.h"
#include "consts/races.h"
#include "consts/roomflags.h"
#include "consts/sectortypes.h"
#include "consts/weather.h"
#include "flags.h"
#include "object_impl.h"
#include "object_macros.h"
#include "weather_db.h"

#include "iterate.hpp"

int num_pc_in_room(struct room_data *room) {
  int i = 0;

  room_people_iterate(room, [&](struct char_data *ch) {
    if (!IS_NPC(ch)) {
      i++;
    }
    return true;
  });

  return (i);
}

/* Is there a campfire in the room? */
bool cook_element(struct room_data *room) {
  struct obj_data *obj, *next_obj;
  int found = FALSE;

  room_contents_iterate(room, [&](auto obj) {
    if (GET_OBJ_TYPE(obj) == ITEM_CAMPFIRE) {
      found = 1;
    } else if (GET_OBJ_VNUM(obj) == 19093) {
      found = 2;
      return false;
    }
    return true;
  });
  return (found);
}

/* Rules (unless overridden by ROOM_DARK):
 *
 * Inside and City rooms are always lit.
 * Outside rooms are dark at sunset and night.  */
bool room_is_dark(struct room_data *room) {

  struct room_data *rm = room;

  if (room_light_get(rm))
    return (FALSE);

  if (cook_element(rm))
    return (FALSE);

  if (room_flagged(rm, ROOM_NOINSTANT) && room_flagged(rm, ROOM_DARK)) {
    return (TRUE);
  }
  if (room_flagged(rm, ROOM_NOINSTANT) && !room_flagged(rm, ROOM_DARK)) {
    return (FALSE);
  }

  if (room_flagged(rm, ROOM_DARK))
    return (TRUE);

  if (room_flagged(rm, ROOM_INDOORS))
    return (FALSE);

  int sec = room_sector_type_get(rm);

  if (sec == SECT_INSIDE || sec == SECT_CITY || sec == SECT_IMPORTANT ||
      sec == SECT_SHOP)
    return (FALSE);

  if (sec == SECT_SPACE)
    return (FALSE);

  if (weather_info.sunlight == SUN_SET)
    return (TRUE);

  if (weather_info.sunlight == SUN_DARK)
    return (TRUE);

  return (FALSE);
}

bool room_is_sunken(struct room_data *room) {
  if (room_geffect_get(room) < 0)
    return true;
  if (room_sector_type_get(room) == SECT_UNDERWATER)
    return true;
  return false;
}
