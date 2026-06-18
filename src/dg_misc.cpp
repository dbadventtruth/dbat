/**************************************************************************
 *  File: dg_misc.c                                                        *
 *  Usage: contains general functions for script usage.                    *
 *                                                                         *
 *  $Author: Mark A. Heilpern/egreen/Welcor $                              *
 *  $Date: 2004/10/11 12:07:00$                                            *
 *  $Revision: 1.0.14 $                                                    *
 **************************************************************************/
#include "character_api.h"
#include "room_api.h"
#include "character_impl.h"
#include "character_macros.h"
#include "character_utils.h"
#include "comm.h"
#include "consts/admlevel.h"
#include "consts/applies.h"
#include "consts/maximums.h"
#include "consts/mobflags.h"
#include "consts/positions.h"
#include "consts/skills.h"
#include "consts/triggers.h"
#include "db.h"
#include "dg_scripts.h"
#include "dgscript_impl.h"
#include "fight.h"
#include "flags.h"
#include "handler.h"
#include "interpreter.h"
#include "log.h"
#include "object_impl.h"
#include "room_impl.h"
#include "skills.h"
#include "spells.h"
#include <cstdlib>
#include <cstring>

#include "extract.h"
#include "relocate.h"

/* copied from spell_parser.c: */
#define SINFO spell_info[spellnum]

void send_char_pos(struct char_data *ch, int dam) {
  switch (GET_POS(ch)) {
  case POS_MORTALLYW:
    act("$n is mortally wounded, and will die soon, if not aided.", TRUE, ch, 0,
        0, TO_ROOM);
    send_to_char(
        ch, "You are mortally wounded, and will die soon, if not aided.\r\n");
    break;
  case POS_INCAP:
    act("$n is incapacitated and will slowly die, if not aided.", TRUE, ch, 0,
        0, TO_ROOM);
    send_to_char(
        ch, "You are incapacitated and will slowly die, if not aided.\r\n");
    break;
  case POS_STUNNED:
    act("$n is stunned, but will probably regain consciousness again.", TRUE,
        ch, 0, 0, TO_ROOM);
    send_to_char(
        ch,
        "You're stunned, but will probably regain consciousness again.\r\n");
    break;
  case POS_DEAD:
    act("$n is dead!  R.I.P.", FALSE, ch, 0, 0, TO_ROOM);
    send_to_char(ch, "You are dead!  Sorry...\r\n");
    break;
  default: /* >= POSITION SLEEPING */
    if (dam > (GET_MAX_HIT(ch) >> 2))
      act("That really did HURT!", FALSE, ch, 0, 0, TO_CHAR);
    if (GET_HIT(ch) < (GET_MAX_HIT(ch) >> 2))
      send_to_char(
          ch, "@rYou wish that your wounds would stop BLEEDING so much!@n\r\n");
  }
}

/* Used throughout the xxxcmds.c files for checking if a char
 * can be targetted
 * - allow_gods is false when called by %force%, for instance,
 * while true for %teleport%.  -- Welcor
 */
int valid_dg_target(struct char_data *ch, int bitvector) {
  if (IS_NPC(ch))
    return TRUE; /* all npcs are allowed as targets */
  else if (GET_ADMLEVEL(ch) < ADMLVL_IMMORT)
    return TRUE; /* as well as all mortals */
  else if (!IS_SET(bitvector, DG_ALLOW_GODS) &&
           (GET_ADMLEVEL(ch) >= 2 &&
            !PRF_FLAGGED(ch, PRF_TEST))) /* LVL_GOD has the advance command.
                                            Can't allow them to be forced. */
    return FALSE;                        /* but not always the highest gods */
  else if (!PRF_FLAGGED(ch, PRF_NOHASSLE) || PRF_FLAGGED(ch, PRF_TEST))
    return TRUE; /* the ones in between as allowed as long as they have
                    no-hassle off.   */
  else
    return FALSE; /* The rest are gods with nohassle on... */
}

void script_damage(struct char_data *vict, int dam) {
  if (ADM_FLAGGED(vict, ADM_NODAMAGE) && (dam > 0)) {
    send_to_char(vict, "Being the cool immortal you are, you sidestep a trap, "
                       "obviously placed to kill you.\r\n");
    return;
  }

  decCurHealth(vict, dam);

  update_pos(vict);
  send_char_pos(vict, dam);

  if (GET_POS(vict) == POS_DEAD) {
    if (!IS_NPC(vict))
      mudlog(BRF, 0, TRUE, "%s killed by script at %s", GET_NAME(vict),
             room_name_get(char_room_get(vict)));
    die(vict, NULL);
  }
}
