/************************************************************************
 *  --Statedit  Part of UrathMud                                v1.0    *
 *  Copyright 1999 Karl N. Matthias.  All rights Reserved.              *
 *  You may freely distribute, modify, or sell this code                *
 *  as long as this copyright remains intact.                           *
 *                                                                      *
 *  Based on code by Jeremy Elson, Harvey Gilpin, and George Greer.     *
 ************************************************************************/

/* --relistan 2/22/99 - 2/24/99 */

#include "dbat/game/statedit.h"
#include "dbat/game/interpreter.h"
#include "dbat/game/comm.h"
#include "dbat/game/utils.h"
#include "dbat/game/db.h"
#include "dbat/game/oasis.h"

int parse_stat_menu(struct descriptor_data *d, char *arg);
int stats_assign_stat(int abil, char *arg, struct descriptor_data *d);

/* --relistan 2/22/99 for player configurable stats */
int parse_stats(struct descriptor_data *d, char *arg)
{

  return 0;
}

int stats_disp_menu(struct descriptor_data *d)
{


  return 1;
}

int parse_stat_menu(struct descriptor_data *d, char *arg)
{
  /* Main parse loop */
  *arg = LOWER(*arg);
  switch (*arg) {
    case 's': 
      OLC_MODE(d) = STAT_GET_STR;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'i': 
      OLC_MODE(d) = STAT_GET_INT;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'w': 
      OLC_MODE(d) = STAT_GET_WIS;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'd': 
      OLC_MODE(d) = STAT_GET_DEX;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'n': 
      OLC_MODE(d) = STAT_GET_CON;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'c': 
      OLC_MODE(d) = STAT_GET_CHA;
      send_to_char(d->character, "Enter new value: ");
    break;
    case 'q': 
      OLC_MODE(d) = STAT_QUIT; 
      return 1;
    default: 
      stats_disp_menu(d);
  }
  return 0;
}

int stats_assign_stat(int abil, char *arg, struct descriptor_data *d)
{
  int temp;

  if (abil > 0) {
      OLC_VAL(d) = OLC_VAL(d)
          + abil;
      abil = 0;
  }

  if (atoi(arg) > OLC_VAL(d))
    temp = OLC_VAL(d);
  else
    temp = atoi(arg);
  if (temp > 100) {
    if (OLC_VAL(d) < 100)
      temp = OLC_VAL(d);
    else temp = 100;
  }
  if (temp < 3) {
    temp = 3;
  }
  /* This should throw an error! */
  if (OLC_VAL(d) <= 0) {
    temp = 0;
    OLC_VAL(d) = 0;
    mudlog(NRM, ADMLVL_IMMORT, TRUE, "Stat total below 0: possible code error");
  }
  abil = temp;
  OLC_VAL(d) -= temp;

  return abil;
}

