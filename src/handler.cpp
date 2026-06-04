/* ************************************************************************
 *   File: handler.c                                     Part of CircleMUD *
 *  Usage: internal funcs: moving and finding chars/objs                   *
 *                                                                         *
 *  All rights reserved.  See license.doc for complete information.        *
 *                                                                         *
 *  Copyright (C) 1993, 94 by the Trustees of the Johns Hopkins University *
 *  CircleMUD is based on DikuMUD, Copyright (C) 1990, 1991.               *
 ************************************************************************ */
#include "handler.h"

#include "class.h"
#include "comm.h"
#include "dg_scripts.h"
#include "interpreter.h"
#include "shop.h"

#include "character_api.h"
#include "character_db.h"
#include "character_impl.h"
#include "character_macros.h"
#include "character_utils.h"
#include "consts/applies.h"
#include "consts/itemdata.h"
#include "consts/mobflags.h"
#include "consts/races.h"
#include "consts/triggers.h"
#include "descriptor_impl.h"
#include "dgscript_impl.h"
#include "flags.h"
#include "object_impl.h"
#include "object_macros.h"
#include "object_utils.h"
#include "relocate.h"
#include "room_api.h"
#include "search.h"
#include "iterate.hpp"
/* external vars */

/* local functions */
static int apply_ac(struct char_data *ch, int eq_pos);
static void update_object(struct obj_data *obj, int use);

/* external functions */

/* Stock isname().  Leave this here even if you put in a newer  *
 * isname().  Used for OasisOLC.                                */

static void update_object(struct obj_data *obj, int use) {
  if (!obj)
    return;
  /* dont update objects with a timer trigger */
  if (!SCRIPT_CHECK(obj, OTRIG_TIMER) && (GET_OBJ_TIMER(obj) > 0))
    GET_OBJ_TIMER(obj) -= use;
  obj_contents_iterate(obj, [&](auto i) {
    update_object(i, use);
    return true;
  });
}

void update_char_objects(struct char_data *ch) {
  int j;

  char_equipment_iterate(ch, [&](auto i, auto eq) {
    if (GET_OBJ_TYPE(eq) == ITEM_LIGHT &&
        GET_OBJ_VAL(eq, VAL_LIGHT_HOURS) > 0 &&
        GET_OBJ_VAL(eq, VAL_LIGHT_TIME) <= 0) {
      j = --GET_OBJ_VAL(eq, VAL_LIGHT_HOURS);
      GET_OBJ_VAL(eq, VAL_LIGHT_TIME) = 3;
      if (j == 1) {
        send_to_char(ch, "Your light begins to flicker and fade.\r\n");
        act("$n's light begins to flicker and fade.", FALSE, ch, 0, 0,
            TO_ROOM);
      } else if (j == 0) {
        send_to_char(ch, "Your light sputters out and dies.\r\n");
        act("$n's light sputters out and dies.", FALSE, ch, 0, 0, TO_ROOM);
        room_light_mod(char_room_get(ch), -1);
      }
    } else if (GET_OBJ_TYPE(eq) == ITEM_LIGHT &&
               GET_OBJ_VAL(eq, VAL_LIGHT_HOURS) > 0) {
      GET_OBJ_VAL(eq, VAL_LIGHT_TIME) -= 1;
    }
    update_object(eq, 2);
    return true;
  });

  char_inventory_iterate(ch, [&](auto obj) {
    update_object(obj, 1);
    return true;
  });
}

/* check and see if this item is better */
void item_check(struct obj_data *object, struct char_data *ch) {
  int where = 0;

  if (IS_HUMANOID(ch) &&
      !(mob_proto_special_get(GET_MOB_VNUM(ch)) == shop_keeper)) {
    if (invalid_align(ch, object) || invalid_class(ch, object))
      return;

    switch (GET_OBJ_TYPE(object)) {
    case ITEM_WEAPON:
      if (!GET_EQ(ch, WEAR_WIELD1)) {
        perform_wear(ch, object, WEAR_WIELD1);
      } else {
        if (is_better(object, GET_EQ(ch, WEAR_WIELD1))) {
          perform_remove(ch, WEAR_WIELD1);
          perform_wear(ch, object, WEAR_WIELD1);
        }
      }
      break;
    case ITEM_ARMOR:
    case ITEM_WORN:
      where = find_eq_pos(ch, object, 0);
      if (!GET_EQ(ch, where)) {
        perform_wear(ch, object, where);
      } else {
        if (is_better(object, GET_EQ(ch, where))) {
          perform_remove(ch, where);
          perform_wear(ch, object, where);
        }
      }

      break;
    default:
      break;
    }
  }
}
