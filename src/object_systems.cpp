#include "object_systems.h"

#include "comm.h"
#include "consts/itemdata.h"
#include "handler.h"
#include "iterate.hpp"
#include "object_api.h"
#include "object_db.h"
#include "object_impl.h"
#include "object_macros.h"
#include "random.h"
#include "relocate.h"
#include "room_api.h"

static const int rand_gravity[14] = {0,   10,  20,   30,   40,   50,   100,
                                     200, 300, 400,  500,  1000, 5000, 10000};

static void tick_broken(struct obj_data *k) {
  if (k->carried_by) return;
  if (rand_number(1, 2) == 2) return;

  int health          = GET_OBJ_VAL(k, VAL_ALL_HEALTH);
  struct room_data *room = obj_room_get(k);
  int dice            = rand_number(2, 12);

  if (GET_OBJ_VNUM(k) == 11) { /* Gravity Generator */
    int  grav_roll    = rand_number(0, 13);
    bool grav_change  = health <= 10
                     || (health <= 40 && dice <= 8)
                     || (health <= 80 && dice <= 5)
                     || (health <= 99 && dice <= 3);
    if (grav_change) {
      room_gravity_set(room, rand_gravity[grav_roll]);
      GET_OBJ_WEIGHT(k) = rand_gravity[grav_roll];
      send_to_room(room, "@RThe gravity generator malfunctions! The gravity "
                         "level has changed!@n\r\n");
    }
  } else if (GET_OBJ_VNUM(k) == 3034) { /* ATM */
    if (health <= 10) {
      send_to_room(room,
                   "@RThe ATM machine shoots smoking bills from its money slot. "
                   "The bills burn up as they float through the air!@n\r\n");
    } else if (health <= 40 && dice <= 8) {
      send_to_room(room,
                   "@RGibberish flashes across the cracked ATM info screen.@n\r\n");
    } else if (health <= 80 && dice == 4) {
      send_to_room(room, "@GThe damaged ATM spits out some money while "
                         "flashing ERROR on its screen!@n\r\n");
      obj_to_room(create_money(rand_number(1, 30)), room);
    } else if (health <= 99 && dice < 4) {
      send_to_room(room,
                   "@RThe ATM machine emits a loud grinding sound from inside.@n\r\n");
    }
  }
}

/* This updates the malfunctioning of certain objects that are damaged. */
void broken_update() {
  obj_iterate_subscriptions("obj_broken", [](struct obj_data *k) {
    tick_broken(k);
    return true;
  });
}
