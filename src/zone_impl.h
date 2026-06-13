#pragma once
#include "consts/types.h"
#include "consts/zoneflags.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* structure for the reset commands */
struct reset_com {
  char command; /* current command                      */

  bool if_flag; /* if TRUE: exe only if preceding exe'd */
  int arg1;     /*                                      */
  int arg2;     /* Arguments to the command             */
  int arg3;     /*                                      */
  int arg4;     /* room_max  default 0			*/
  int arg5;     /* percentages variable                 */
  int line;     /* line number this command appears on  */
  char *sarg1;  /* string argument                      */
  char *sarg2;  /* string argument                      */

  /*
   *  Commands:              *
   *  'M': Read a mobile     *
   *  'O': Read an object    *
   *  'G': Give obj to mob   *
   *  'P': Put obj in obj    *
   *  'G': Obj to char       *
   *  'E': Obj to char equip *
   *  'D': Set state of door *
   *  'T': Trigger command   *
   *  'V': Assign a variable *
   */
};

/* zone definition structure. for the 'zone-table'   */
#define CUR_WORLD_VERSION 1
#define CUR_ZONE_VERSION 2

struct zone_data {
  zone_vnum id;     /* virtual number of this zone	  */
  char *name;       /* name of this zone                  */
  char *builders;   /* namelist of builders allowed to modify this zone.
                     */
  int lifespan;     /* how long between resets (minutes)  */
  int age;          /* current age of this zone (minutes) */
  room_vnum bot;    /* starting room number for this zone */
  room_vnum top;    /* upper limit for rooms in this zone */
  int reset_mode;   /* conditions for reset (see below)   */
  int min_level;    /* Minimum level to enter zone        */
  int max_level;    /* Max Mortal level to enter zone     */
  bitvector_t zone_flags[ZF_ARRAY_MAX]; /* Flags for the zone.                */
  struct reset_com *cmd;                /* command table for reset	          */

  /*
   * Reset mode:
   *   0: Don't reset, and don't update age.
   *   1: Reset if no PC's are located in zone.
   *   2: Just reset.
   */
};

zone_vnum real_zone(zone_vnum vnum);
struct zone_data *zone_by_id(zone_vnum vnum);
struct zone_data *zone_get(zone_vnum vnum);

zone_vnum virtual_zone_by_thing(room_vnum vznum);

void *zone_iterator_create();
struct zone_data *zone_next(void *iterator);
void zone_iterator_free(void *iterator);

void zone_put(zone_vnum vnum, struct zone_data *zone);
void zone_delete(zone_vnum vnum);
size_t zone_count();

#ifdef __cplusplus
}
#endif
