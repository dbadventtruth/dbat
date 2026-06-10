/* ************************************************************************
 *   File: limits.c                                      Part of CircleMUD *
 *  Usage: limits & gain funcs for HMV, exp, hunger/thirst, idle time      *
 *                                                                         *
 *  All rights reserved.  See license.doc for complete information.        *
 *                                                                         *
 *  Copyright (C) 1993, 94 by the Trustees of the Johns Hopkins University *
 *  CircleMUD is based on DikuMUD, Copyright (C) 1990, 1991.               *
 ************************************************************************ */
#include "local_limits.h"
#include "config.h"

#include "act.item.h"
#include "act.movement.h"
#include "act.other.h"
#include "alias.h"
#include "character_api.h"
#include "character_impl.h"
#include "character_macros.h"
#include "character_utils.h"
#include "class.h"
#include "comm.h"
#include "config_db.h"
#include "consts/admlevel.h"
#include "consts/affflags.h"
#include "consts/applies.h"
#include "consts/bonus.h"
#include "consts/constates.h"
#include "consts/fightprefs.h"
#include "consts/mobflags.h"
#include "consts/playerflags.h"
#include "consts/positions.h"
#include "consts/races.h"
#include "consts/roomflags.h"
#include "consts/sectortypes.h"
#include "consts/sex.h"
#include "consts/skills.h"
#include "consts/weather.h"
#include "db.h"
#include "descriptor_db.h"
#include "descriptor_impl.h"
#include "descriptor_macros.h"
#include "dg_comm.h"
#include "dg_scripts.h"
#include "extract.h"
#include "fight.h"
#include "flags.h"
#include "handler.h"
#include "log.h"
#include "object_api.h"
#include "object_impl.h"
#include "object_macros.h"
#include "objsave.h"
#include "random.h"
#include "relocate.h"
#include "room_api.h"

#include "room_utils.h"
#include "spells.h"
#include "stringutils.h"
#include "util_macros.h"
#include "vehicles.h"
#include "weather_db.h"

#include "iterate.hpp"

#include <initializer_list>

#include <cstring>
#include <unistd.h>

/* local defines */
#define sick_fail 2

/* local functions */
static void heal_limb(struct char_data *ch);
static int64_t move_gain(struct char_data *ch);
static int64_t mana_gain(struct char_data *ch);
static int64_t hit_gain(struct char_data *ch);
static void update_flags(struct char_data *ch);

static int wearing_stardust(struct char_data *ch);
static void healthy_check(struct char_data *ch);
static void barrier_shed(struct char_data *ch);
static void check_idling(struct char_data *ch);

static void barrier_shed(struct char_data *ch) {

  if (!AFF_FLAGGED(ch, AFF_SANCTUARY)) {
    return;
  }

  if (GET_SKILL(ch, SKILL_AQUA_BARRIER) > 0) {
    return;
  }

  int chance = axion_dice(0), barrier = GET_SKILL(ch, SKILL_BARRIER),
      concentrate = GET_SKILL(ch, SKILL_CONCENTRATION);
  double rate = 0.3;

  if (barrier >= 100) {
    rate = 0.01;
  } else if (barrier >= 95) {
    rate = 0.02;
  } else if (barrier >= 90) {
    rate = 0.04;
  } else if (barrier >= 80) {
    rate = 0.08;
  } else if (barrier >= 70) {
    rate = 0.10;
  } else if (barrier >= 60) {
    rate = 0.15;
  } else if (barrier >= 50) {
    rate = 0.20;
  } else if (barrier >= 40) {
    rate = 0.25;
  } else if (barrier >= 30) {
    rate = 0.27;
  } else if (barrier >= 20) {
    rate = 0.29;
  }

  int64_t loss = (long double)(GET_BARRIER(ch)) * rate, recharge = 0;

  if (concentrate >= chance) {
    recharge = loss * 0.5;
  }

  GET_BARRIER(ch) -= loss;

  if (GET_BARRIER(ch) <= 0) {
    GET_BARRIER(ch) = 0;
    act("@cYour barrier disappears.@n", TRUE, ch, 0, 0, TO_CHAR);
    act("@c$n@c's barrier disappears.@n", TRUE, ch, 0, 0, TO_ROOM);
  } else {
    act("@cYour barrier loses some energy.@n", TRUE, ch, 0, 0, TO_CHAR);
    send_to_char(ch, "@D[@C%s@D]@n\r\n", add_commas(loss));
    act("@c$n@c's barrier sends some sparks into the air as it seems to get a "
        "bit weaker.@n",
        TRUE, ch, 0, 0, TO_ROOM);
  }

  if (recharge > 0 && (getCurKI(ch)) < GET_MAX_MANA(ch)) {
    incCurKI(ch, recharge);
    send_to_char(
        ch, "@CYou reabsorb some of the energy lost into your body!@n\r\n");
  }
}

/* If they have the Healthy trait then they have a chance to lose each of these
 */
static void healthy_check(struct char_data *ch) {

  if (!GET_BONUS(ch, BONUS_HEALTHY) || GET_POS(ch) != POS_SLEEPING) {
    return;
  }

  int chance = 70, roll = rand_number(1, 100), change = FALSE;

  if(roll < chance) 
    return;

  if (AFF_FLAGGED(ch, AFF_SHOCKED)) {
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_SHOCKED);
    change = TRUE;
  }

  if (AFF_FLAGGED(ch, AFF_MBREAK)) {
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_MBREAK);
    change = TRUE;
  }

  if(char_condition_remove_tag(ch, "healthy_clear", "healthy")) {
    change = TRUE;
  }


  if (AFF_FLAGGED(ch, AFF_KNOCKED)) {
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_KNOCKED);
    char_position_set(ch, POS_SITTING);
    change = TRUE;
  }
  if (change) {
    send_to_char(ch,
                 "@CYou feel your body recover from all its ailments!@n\r\n");
  }
  return;
}

static int wearing_stardust(struct char_data *ch) {

  int count = 0;

  char_equipment_iterate(ch, [&](auto i, auto eq) {
    if (i == 0) return true;
    switch (GET_OBJ_VNUM(eq)) {
    case 1110:
    case 1111:
    case 1112:
    case 1113:
    case 1114:
    case 1115:
    case 1116:
    case 1117:
    case 1118:
    case 1119:
      count += 1;
      break;
    }
    return true;
  });

  if (count == 26)
    return (1);
  else
    return (0);
}

/*
 * The hit_limit, mana_limit, and move_limit functions are gone.  They
 * added an unnecessary level of complexity to the internal structure,
 * weren't particularly useful, and led to some annoying bugs.  From the
 * players' point of view, the only difference the removal of these
 * functions will make is that a character's age will now only affect
 * the HMV gain per tick, and _not_ the HMV maximums.
 */

/* manapoint gain pr. game hour */
static int64_t mana_gain(struct char_data *ch) {
  int64_t gain = char_der_total_get(ch, "ki_regen");

  if(auto conc = GET_SKILL(ch, SKILL_CONCENTRATION)) {

    gain += (gain * 0.005) * conc;
  }

  if (GET_FOODR(ch) > 0 && rand_number(1, 2) == 2) {
    GET_FOODR(ch) -= 1;
  }

  if (!IS_NPC(ch) && PRF_FLAGGED(ch, PRF_HINTS) && rand_number(1, 5) == 5) {
    hint_system(ch, 0);
  }

  return (gain);
}

/* Hitpoint gain pr. game hour */
int64_t hit_gain(struct char_data *ch) {
  
  auto gain = char_der_total_get(ch, "powerlevel_regen");

  healthy_check(ch);

  /* Fury Mode Loss for halfbreeds */

  if (PLR_FLAGGED(ch, PLR_FURY)) {
    send_to_char(ch, "Your fury subsides for now.\r\n");
    REMOVE_BIT_AR(PLR_FLAGS(ch), PLR_FURY);
  }

  if (auto regen = GET_REGEN(ch)) {
    gain += (gain * 0.01) * regen;
  }

  return (gain);
}

/* move gain pr. game hour */
static int64_t move_gain(struct char_data *ch) {
  int64_t gain = char_der_total_get(ch, "stamina_regen");
  struct room_data *room = char_room_get(ch);

  if (!calcGravCost(ch, 0)) {
    send_to_char(ch, "This gravity is wearing you out!\r\n");
    gain /= 4;
  }

  if (auto regen = GET_REGEN(ch)) {
    gain += (gain * 0.01) * regen;
  }

  return (gain);
}

static void update_flags(struct char_data *ch) {
  if (ch == NULL) {
    send_to_imm("ERROR: Empty ch variable sent to update_flags.");
    return;
  }

  if (GET_BONUS(ch, BONUS_LATE) && GET_POS(ch) == POS_SLEEPING &&
      rand_number(1, 3) == 3) {
    if (GET_HIT(ch) >= (getMaxPL(ch)) && (getCurST(ch)) >= GET_MAX_MOVE(ch) &&
        (getCurKI(ch)) >= GET_MAX_MANA(ch)) {
      send_to_char(ch, "You FINALLY wake up.\r\n");
      act("$n wakes up.", TRUE, ch, 0, 0, TO_ROOM);
      char_position_set(ch, POS_SITTING);
    }
  }

  if (AFF_FLAGGED(ch, AFF_KNOCKED) && !FIGHTING(ch)) {
    cureStatusKnockedOutAnnounced(ch, true);
  }

  barrier_shed(ch);

  if (AFF_FLAGGED(ch, AFF_FIRESHIELD) && !FIGHTING(ch) &&
      rand_number(1, 101) > GET_SKILL(ch, SKILL_FIRESHIELD)) {
    send_to_char(ch, "Your fireshield disappears.\r\n");
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_FIRESHIELD);
  }
  if (char_condition_has(ch, "zanzoken") && !FIGHTING(ch) &&
      rand_number(1, 3) == 2) {
    send_to_char(
        ch, "You lose concentration and no longer are ready to zanzoken.\r\n");
    char_condition_remove(ch, "zanzoken", "zanzoken_over");
  }
  if (AFF_FLAGGED(ch, AFF_ENSNARED) && rand_number(1, 3) == 2) {
    send_to_char(ch, "The silk ensnaring your arms disolves enough for you to "
                     "break it!\r\n");
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_ENSNARED);
  }

  if ((IS_SAIYAN(ch) || IS_HALFBREED(ch)) && PLR_FLAGGED(ch, PLR_TRANS1) &&
      !PLR_FLAGGED(ch, PLR_FPSSJ)) {
    GET_ABSORBS(ch) += 1;
    if (GET_ABSORBS(ch) >= 300) {
      send_to_char(ch, "You have mastered the base Super Saiyan transformation "
                       "and achieved Full Power Super Saiyan! Super Saiyan "
                       "First can now be maintained effortlessly.\r\n");
      SET_BIT_AR(PLR_FLAGS(ch), PLR_FPSSJ);
      GET_ABSORBS(ch) = 0;
    }
  }

  if (!IS_NPC(ch) && !PLR_FLAGGED(ch, PLR_STAIL) &&
      !PLR_FLAGGED(ch, PLR_NOGROW) && (IS_SAIYAN(ch) || IS_HALFBREED(ch))) {
    if (RACIAL_PREF(ch) == 1 && rand_number(1, 50) >= 40) {
      GET_TGROWTH(ch) += 1;
    } else if (RACIAL_PREF(ch) != 1 || IS_SAIYAN(ch)) {
      GET_TGROWTH(ch) += 1;
    }
    if (GET_TGROWTH(ch) >= 10) {
      send_to_char(ch, "@wYour tail grows back.@n\r\n");
      act("$n@w's tail grows back.@n", TRUE, ch, 0, 0, TO_ROOM);
      char_gain_tail(ch, true);
      GET_TGROWTH(ch) = 0;
    }
  }
  if (!IS_NPC(ch) && !PLR_FLAGGED(ch, PLR_TAIL) &&
      (IS_ICER(ch) || IS_BIO(ch))) {
    GET_TGROWTH(ch) += 1;
    if (GET_TGROWTH(ch) >= 10) {
      send_to_char(ch, "@wYour tail grows back.@n\r\n");
      act("$n@w's tail grows back.@n", TRUE, ch, 0, 0, TO_ROOM);
      char_gain_tail(ch, true);
      GET_TGROWTH(ch) = 0;
    }
  }
  if (AFF_FLAGGED(ch, AFF_MBREAK) && rand_number(1, 3 + sick_fail) == 2) {
    send_to_char(
        ch,
        "@wYour mind is no longer in turmoil, you can charge ki again.@n\r\n");
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_MBREAK);
    if (GET_SKILL(ch, SKILL_TELEPATHY) <= 0 && rand_number(1, 2) == 2) {
      char_stat_mod(ch, "intelligence", -1);
      char_stat_mod(ch, "wisdom", -1);
      send_to_char(
          ch,
          "@RDue to the stress you've lost 1 Intelligence and Wisdom!@n\r\n");
      if (char_stat_get(ch, "wisdom") < 4)
        char_stat_set(ch, "wisdom", 4);
      if (char_stat_get(ch, "intelligence") < 4)
        char_stat_set(ch, "intelligence", 4);
    } else if (GET_SKILL(ch, SKILL_TELEPATHY) <= 0 && rand_number(1, 20) == 1) {
      char_stat_mod(ch, "intelligence", -1);
      char_stat_mod(ch, "wisdom", -1);
      send_to_char(
          ch,
          "@RDue to the stress you've lost 1 Intelligence and Wisdom!@n\r\n");
      if (char_stat_get(ch, "wisdom") < 4)
        char_stat_set(ch, "wisdom", 4);
      if (char_stat_get(ch, "intelligence") < 4)
        char_stat_set(ch, "intelligence", 4);
    }
  }
  if (AFF_FLAGGED(ch, AFF_SHOCKED) && rand_number(1, 4) == 4) {
    send_to_char(ch, "@wYour mind is no longer shocked.@n\r\n");
    if (GET_SKILL(ch, SKILL_TELEPATHY) > 0) {
      int skill = GET_SKILL(ch, SKILL_TELEPATHY), stop = FALSE;
      improve_skill(ch, SKILL_TELEPATHY, 0);
      while (stop == FALSE) {
        if (rand_number(1, 8) == 5)
          stop = TRUE;
        else
          improve_skill(ch, SKILL_TELEPATHY, 0);
      }
      if (skill < GET_SKILL(ch, SKILL_TELEPATHY))
        send_to_char(ch, "Your mental damage and recovery has taught you "
                         "things about your own mind.\r\n");
    }
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_SHOCKED);
  }
  if (AFF_FLAGGED(ch, AFF_FROZEN) && rand_number(1, 2) == 2) {
    send_to_char(ch, "@wYou realize you have thawed enough and break out of "
                     "the ice holding you prisoner!\r\n");
    act("$n@W breaks out of the ice holding $m prisoner!", TRUE, ch, 0, 0,
        TO_ROOM);
    REMOVE_BIT_AR(AFF_FLAGS(ch), AFF_FROZEN);
  }
  if (char_condition_has(ch, "wither") && rand_number(1, 6 + sick_fail) == 2) {
    send_to_char(ch, "@wYour body returns to normal and you beat the withering "
                     "that plagued you.\r\n");
    act("$n@W's looks more fit now.", TRUE, ch, 0, 0, TO_ROOM);
    char_condition_remove(ch, "wither", "wore_off");
    save_char(ch);
  }
  if (wearing_stardust(ch) == 1) {
    char_condition_add(ch, "zanzoken", "skill", "zanzoken");
    send_to_char(ch, "The stardust armor blesses you with a free zanzoken when "
                     "you next need it.\r\n");
  }
}

void set_title(struct char_data *ch, char *title) {
  if (ch) {
    send_to_char(ch, "Title is disabled for the time being while Iovan works "
                     "on a brand new and fancier title system.\r\n");
    return;
  }
}

void gain_level(struct char_data *ch, int whichclass) {
  if (whichclass < 0)
    whichclass = GET_CLASS(ch);
  if (GET_LEVEL(ch) < 100 && GET_EXP(ch) >= level_exp(ch, GET_LEVEL(ch) + 1)) {
    char_stat_mod(ch, "level", 1);
    // GET_CLASS(ch) = whichclass; /* Now tracks latest class instead of highest
    // */
    advance_level(ch, whichclass);
    mudlog(BRF, MAX(ADMLVL_IMMORT, GET_INVIS_LEV(ch)), TRUE,
           "%s advanced level to level %d.", GET_NAME(ch), GET_LEVEL(ch));
    send_to_char(ch, "You rise a level!\r\n");
    char_stat_mod(ch, "experience", -level_exp(ch, GET_LEVEL(ch)));
    /*set_title(ch, NULL);*/
    write_aliases(ch);
    save_char(ch);
  }
}

void run_autowiz(void) {
#if defined(CIRCLE_UNIX) || defined(CIRCLE_WINDOWS)
  if (CONFIG_USE_AUTOWIZ) {
    size_t res;
    char buf[256];

#if defined(CIRCLE_UNIX)
    res = snprintf(buf, sizeof(buf), "nice ../bin/autowiz %d %s %d %s %d &",
                   CONFIG_MIN_WIZLIST_LEV, WIZLIST_FILE, ADMLVL_IMMORT,
                   IMMLIST_FILE, (int)getpid());
#elif defined(CIRCLE_WINDOWS)
    res = snprintf(buf, sizeof(buf), "autowiz %d %s %d %s",
                   CONFIG_MIN_WIZLIST_LEV, WIZLIST_FILE, ADMLVL_IMMORT,
                   IMMLIST_FILE);
#endif /* CIRCLE_WINDOWS */

    /* Abusing signed -> unsigned conversion to avoid '-1' check. */
    if (res < sizeof(buf)) {
      mudlog(CMP, ADMLVL_IMMORT, FALSE, "Initiating autowiz.");
      system(buf);
      reboot_wizlists();
    } else
      mud_log("Cannot run autowiz: command-line doesn't fit in buffer.");
  }
#endif /* CIRCLE_UNIX || CIRCLE_WINDOWS */
}

void gain_exp(struct char_data *ch, int64_t gain) {

  if (gain > 20000000) {
    gain = 20000000;
  }

  if (IN_ARENA(ch)) {
    send_to_char(ch,
                 "EXP CANCEL: You can not gain experience from the arena.\r\n");
    return;
  }

  if (char_condition_has(ch, "rune_wunjo")) {
    gain += gain * 0.15;
  }
  if (PLR_FLAGGED(ch, PLR_IMMORTAL)) {
    gain = gain * 0.95;
  }

  int64_t diff = gain * 0.15;

  if (!IS_NPC(ch) && GET_LEVEL(ch) < 1)
    return;

  if (IS_NPC(ch)) {
    char_stat_mod(ch, "experience", gain);
    return;
  }

  if (gain > 0) {
    gain =
        MIN(CONFIG_MAX_EXP_GAIN, gain); /* put a cap on the max gain per kill */
    if (GET_EQ(ch, WEAR_SH)) {
      struct obj_data *obj = GET_EQ(ch, WEAR_SH);
      if (GET_OBJ_VNUM(obj) == 1127) {
        int64_t spar = gain;
        gain += gain * 2.5;
        spar = gain - spar;
        send_to_char(ch, "@D[@BBooster EXP@W: @G+%s@D]\r\n", add_commas(spar));
      }
    }
    if (GET_LEVEL(ch) < 100) {
      if (MINDLINK(ch) && gain > 0 && LINKER(ch) == 0) {
        if (GET_LEVEL(ch) + 20 < GET_LEVEL(MINDLINK(ch)) ||
            GET_LEVEL(ch) - 20 > GET_LEVEL(MINDLINK(ch))) {
          send_to_char(MINDLINK(ch),
                       "The level difference between the two of you is too "
                       "great to gain from mind read.\r\n");
        } else {
          act("@GYou've absorbed some new experiences from @W$n@G!@n", FALSE,
              ch, 0, MINDLINK(ch), TO_VICT);
          int read = gain * 0.12;
          gain -= read;
          if (read == 0)
            read = 1;
          gain_exp(MINDLINK(ch), read);
          act("@RYou sense that @W$N@R has stolen some of your experiences "
              "with $S mind!@n",
              FALSE, ch, 0, MINDLINK(ch), TO_CHAR);
        }
      }
      int64_t difff = level_exp(ch, GET_LEVEL(ch) + 1) * 5;
      if (GET_LEVEL(ch) <= 90 &&
          (level_exp(ch, GET_LEVEL(ch) + 1) - (GET_EXP(ch) + gain) <=
           (level_exp(ch, GET_LEVEL(ch) + 1) - difff))) {
        send_to_char(ch, "@WYou -@RNEED@W- to @ylevel@W you can't hold any "
                         "more experience.@n\r\n");
      } else if (GET_LEVEL(ch) >= 91 &&
                 level_exp(ch, GET_LEVEL(ch) + 1) - GET_EXP(ch) <= -1) {
        send_to_char(ch, "@WYou -@RNEED@W- to @ylevel@W you can't hold any "
                         "more experience.@n\r\n");
      } else {
        char_stat_mod(ch, "experience", gain);
      }
    }
    if (GET_LEVEL(ch) < 100 && GET_EXP(ch) >= level_exp(ch, GET_LEVEL(ch) + 1))
      send_to_char(
          ch, "@rYou have earned enough experience to gain a @ylevel@r.@n\r\n");

    if (GET_LEVEL(ch) == 100 && GET_ADMLEVEL(ch) < 1) {
      if (IS_KANASSAN(ch) || IS_DEMON(ch)) {
        diff = diff * 1.3;
      }
      if (IS_ANDROID(ch)) {
        diff = diff * 1.2;
      }
      if (MINDLINK(ch) && gain > 0 && LINKER(ch) == 0) {
        if (GET_LEVEL(ch) + 20 < GET_LEVEL(MINDLINK(ch)) ||
            GET_LEVEL(ch) - 20 > GET_LEVEL(MINDLINK(ch))) {
          send_to_char(MINDLINK(ch),
                       "The level difference between the two of you is too "
                       "great to gain from mind read.\r\n");
        } else {
          act("@GYou've absorbed some new experiences from @W$n@G!@n", FALSE,
              ch, 0, MINDLINK(ch), TO_VICT);
          int64_t read = gain * 0.12;
          diff -= (read * 0.15);
          gain -= read;
          if (read == 0)
            read = 1;
          gain_exp(MINDLINK(ch), read);
          act("@RYou sense that @W$N@R has stolen some of your experiences "
              "with $S mind!@n",
              FALSE, ch, 0, MINDLINK(ch), TO_CHAR);
        }
      }
      if (rand_number(1, 5) >= 2) {
        if (IS_HUMAN(ch)) {
          gainBasePL(ch, diff * 0.8);
        } else {
          gainBasePL(ch, diff);
        }
        send_to_char(ch, "@D[@G+@Y%s @RPL@D]@n ", add_commas(diff));
      }
      if (rand_number(1, 5) >= 2) {
        if (IS_HALFBREED(ch)) {
          gainBaseST(ch, diff * 0.85);
        } else {
          gainBaseST(ch, diff);
        }
        send_to_char(ch, "@D[@G+@Y%s @gSTA@D]@n ", add_commas(diff));
      }
      if (rand_number(1, 5) >= 2) {
        gainBaseKI(ch, diff);
        send_to_char(ch, "@D[@G+@Y%s @CKi@D]@n", add_commas(diff));
      }
    }
  } else if (gain < 0) {
    gain = MAX(-CONFIG_MAX_EXP_LOSS, gain); /* Cap max exp lost per death */
    char_stat_mod(ch, "experience", gain);
    if (GET_EXP(ch) < 0)
      char_stat_set(ch, "experience", 0);
  }
}

void gain_exp_regardless(struct char_data *ch, int gain) {
  int is_altered = FALSE;
  int num_levels = 0;

  gain = (gain * CONFIG_EXP_MULTIPLIER);

  char_stat_mod(ch, "experience", gain);
  if (GET_EXP(ch) < 0)
    char_stat_set(ch, "experience", 0);

  if (!IS_NPC(ch)) {
    while (GET_LEVEL(ch) < CONFIG_LEVEL_CAP - 1 &&
           GET_EXP(ch) >= level_exp(ch, GET_LEVEL(ch) + 1)) {
      char_stat_mod(ch, "level", 1);
      num_levels++;
      advance_level(ch, GET_CLASS(ch));
      is_altered = TRUE;
    }

    if (is_altered) {
      mudlog(BRF, MAX(ADMLVL_IMMORT, GET_INVIS_LEV(ch)), TRUE,
             "%s advanced %d level%s to level %d.", GET_NAME(ch), num_levels,
             num_levels == 1 ? "" : "s", GET_LEVEL(ch));
      if (num_levels == 1)
        send_to_char(ch, "You rise a level!\r\n");
      else
        send_to_char(ch, "You rise %d levels!\r\n", num_levels);
      /*set_title(ch, NULL);*/
    }
  }
}

void gain_condition(struct char_data *ch, int condition, int value) {
  const char *condition_name;
  bool intoxicated;

  switch (condition) {
  case DRUNK:
    condition_name = "drunk";
    break;
  case HUNGER:
    condition_name = "hunger";
    break;
  case THIRST:
    condition_name = "thirst";
    break;
  default:
    return;
  }

  if (IS_NPC(ch))
    return;

  if (IS_ANDROID(ch)) {
    return;
  }

  if (char_stat_get(ch, condition_name) < 0) { /* No change */
    return;
  }

  if (char_room_vnum_get(ch) <= 1) {
    return;
  }

  if (PLR_FLAGGED(ch, PLR_WRITING))
    return;

  intoxicated = (char_stat_get(ch, "drunk") > 0);
  if (value > 0) {
    if (char_stat_get(ch, condition_name) >= 0) {
      if (char_stat_get(ch, condition_name) + value > 48) {
        int prior = char_stat_get(ch, condition_name);
        char_stat_set(ch, condition_name, 48);
        if (condition != DRUNK && prior >= 48 && !IS_MAJIN(ch)) {
          int ocond = condition;
          if (condition == HUNGER)
            ocond = THIRST;
          else if (condition == THIRST)
            ocond = HUNGER;
        }
      } else {
        char_stat_mod(ch, condition_name, value);
      }
    }
  } else {
    if (char_stat_get(ch, condition_name) >= 0) {
      if (char_stat_get(ch, condition_name) + value < 0) {
        char_stat_set(ch, condition_name, 0);
      } else {
        char_stat_mod(ch, condition_name, value);
      }
    }
  }
  switch (condition) {
  case HUNGER:
    switch (char_stat_get(ch, condition_name)) {
    case 0:
      // send_to_char(ch, "@RYou are feeling ravenous!@n\r\n");
      break;
    case 1:
    case 2:
    case 3:
      send_to_char(ch, "You are extremely hungry!\r\n");
      break;
    case 9:
    case 10:
    case 11:
      send_to_char(ch, "You are hungry!\r\n");
      break;
    case 19:
    case 20:
    case 21:
      send_to_char(ch, "You could use something to eat.\r\n");
      break;
    default:
      break;
    }
    break;
  case THIRST:
    switch (char_stat_get(ch, condition_name)) {
    case 0:
      // send_to_char(ch, "@RYou are dehydrated!@n\r\n");
      break;
    case 1:
    case 2:
    case 3:
      send_to_char(ch, "You are extremely thirsty!\r\n");
      break;
    case 9:
    case 10:
    case 11:
      send_to_char(ch, "Your throat is pretty dry!\r\n");
      break;
    case 19:
    case 20:
    case 21:
      send_to_char(ch, "You could use something to drink.\r\n");
      break;
    default:
      break;
    }
    break;
  case DRUNK:
    if (intoxicated) {
      if (char_stat_get(ch, "drunk") <= 0) {
        send_to_char(ch, "You are now sober.\r\n");
      }
    }
    break;
  default:
    break;
  }
}

static void check_idling(struct char_data *ch) {
  if (dball_count(ch)) {
    return;
  }

  struct room_data *room = char_room_get(ch);

  if (++(ch->timer) > CONFIG_IDLE_VOID) {
    if (GET_WAS_IN(ch) == NOWHERE && room) {
      GET_WAS_IN(ch) = IN_ROOM(ch);
      if (FIGHTING(ch)) {
        stop_fighting(FIGHTING(ch));
        stop_fighting(ch);
      }

      room_vnum v = room_vnum_get(room);

      if (!room_flagged(room, ROOM_PAST) && (v < 19800 || v > 19899)) {
        GET_LOADROOM(ch) = v;
      }
      if (room_flagged(room, ROOM_PAST)) {
        GET_LOADROOM(ch) = room_vnum_check(1561);
      }
      if (v >= 2002 && v <= 2011) {
        GET_LOADROOM(ch) = room_vnum_check(1960);
      }
      if (v == 2069) {
        GET_LOADROOM(ch) = room_vnum_check(2017);
      }
      if (v == 2070) {
        GET_LOADROOM(ch) = room_vnum_check(2046);
      }
      if (v >= 101 && v <= 139) {
        if (GET_LEVEL(ch) == 1) {
          GET_LOADROOM(ch) = room_vnum_check(100);
          char_stat_set(ch, "experience", 0);
        } else {
          if (IS_ROSHI(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(1130);
          }
          if (IS_KABITO(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(12098);
          }
          if (IS_NAIL(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(11683);
          }
          if (IS_BARDOCK(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(2268);
          }
          if (IS_KRANE(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(13009);
          }
          if (IS_TAPION(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(8231);
          }
          if (IS_PICCOLO(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(1659);
          }
          if (IS_ANDSIX(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(1713);
          }
          if (IS_DABURA(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(6486);
          }
          if (IS_FRIEZA(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(4282);
          }
          if (IS_GINYU(ch)) {
            GET_LOADROOM(ch) = room_vnum_check(4289);
          }
        }
      }
      act("$n disappears into the void.", TRUE, ch, 0, 0, TO_ROOM);
      send_to_char(ch, "You have been idle, and are pulled into a void.\r\n");
      save_char(ch);
      char_from_room(ch);
      char_to_room(ch, room_by_id(1));
    } else if (ch->timer > CONFIG_IDLE_RENT_TIME) {
      if (char_room_get(ch) != NULL) {
        char_from_room(ch);
        char_to_room(ch, room_by_id(3));
      }
      if (ch->desc) {
        send_to_char(
            ch, "You are idle and are extracted safely from the game.\r\n");
        STATE(ch->desc) = CON_DISCONNECT;
        /*
         * For the 'if (d->character)' test in close().
         * -gg 3/1/98 (Happy anniversary.)
         */
        ch->desc->character = NULL;
        ch->desc = NULL;
      }
      Crash_rentsave(ch, 0);
      mudlog(CMP, ADMLVL_GOD, TRUE, "%s force-rented and extracted (idle).",
             GET_NAME(ch));
      extract_char(ch);
    }
  }
}

static void heal_limb(struct char_data *ch) {
  int healrate = 0, recovered = FALSE;

  if (PLR_FLAGGED(ch, PLR_BANDAGED)) {
    healrate += 10;
  }

  if (GET_POS(ch) == POS_SITTING) {
    healrate += 1;
  } else if (GET_POS(ch) == POS_RESTING) {
    healrate += 3;
  } else if (GET_POS(ch) == POS_SLEEPING) {
    healrate += 5;
  }

  if (healrate > 0) {
    if (GET_LIMBCOND(ch, 1) > 0 && GET_LIMBCOND(ch, 1) < 50) {
      if (GET_LIMBCOND(ch, 1) + healrate >= 50) {
        act("You realize your right arm is no longer broken.", TRUE, ch, 0, 0,
            TO_CHAR);
        act("$n starts moving $s right arm gingerly for a moment.", TRUE, ch, 0,
            0, TO_ROOM);
        GET_LIMBCOND(ch, 1) += healrate;
        recovered = TRUE;
      } else {
        GET_LIMBCOND(ch, 1) += healrate;
        send_to_char(ch,
                     "Your right arm feels a little better "
                     "@D[@G%d%s@D/@g100%s@D]@n.\r\n",
                     GET_LIMBCOND(ch, 1), "%", "%");
      }
    } else if (GET_LIMBCOND(ch, 1) + healrate < 100) {
      GET_LIMBCOND(ch, 1) += healrate;
      send_to_char(
          ch,
          "Your right arm feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
          GET_LIMBCOND(ch, 1), "%", "%");
    } else if (GET_LIMBCOND(ch, 1) < 100 &&
               GET_LIMBCOND(ch, 1) + healrate >= 100) {
      GET_LIMBCOND(ch, 1) = 100;
      send_to_char(ch, "Your right arm has fully recovered.\r\n");
    }

    if (GET_LIMBCOND(ch, 2) > 0 && GET_LIMBCOND(ch, 2) < 50) {
      if (GET_LIMBCOND(ch, 2) + healrate >= 50) {
        act("You realize your left arm is no longer broken.", TRUE, ch, 0, 0,
            TO_CHAR);
        act("$n starts moving $s left arm gingerly for a moment.", TRUE, ch, 0,
            0, TO_ROOM);
        GET_LIMBCOND(ch, 2) += healrate;
        recovered = TRUE;
      } else {
        GET_LIMBCOND(ch, 2) += healrate;
        send_to_char(
            ch,
            "Your left arm feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
            GET_LIMBCOND(ch, 1), "%", "%");
      }
    } else if (GET_LIMBCOND(ch, 2) + healrate < 100) {
      GET_LIMBCOND(ch, 2) += healrate;
      send_to_char(
          ch,
          "Your left arm feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
          GET_LIMBCOND(ch, 2), "%", "%");
    } else if (GET_LIMBCOND(ch, 2) < 100 &&
               GET_LIMBCOND(ch, 2) + healrate >= 100) {
      GET_LIMBCOND(ch, 2) = 100;
      send_to_char(ch, "Your left arm has fully recovered.\r\n");
    }

    if (GET_LIMBCOND(ch, 3) > 0 && GET_LIMBCOND(ch, 3) < 50) {
      if (GET_LIMBCOND(ch, 3) + healrate >= 50) {
        act("You realize your right leg is no longer broken.", TRUE, ch, 0, 0,
            TO_CHAR);
        act("$n starts moving $s right leg gingerly for a moment.", TRUE, ch, 0,
            0, TO_ROOM);
        GET_LIMBCOND(ch, 3) += healrate;
        recovered = TRUE;
      } else {
        GET_LIMBCOND(ch, 3) += healrate;
        send_to_char(ch,
                     "Your right leg feels a little better "
                     "@D[@G%d%s@D/@g100%s@D]@n.\r\n",
                     GET_LIMBCOND(ch, 1), "%", "%");
      }
    } else if (GET_LIMBCOND(ch, 3) + healrate < 100) {
      GET_LIMBCOND(ch, 3) += healrate;
      send_to_char(
          ch,
          "Your right leg feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
          GET_LIMBCOND(ch, 3), "%", "%");
    } else if (GET_LIMBCOND(ch, 3) < 100 &&
               GET_LIMBCOND(ch, 3) + healrate >= 100) {
      GET_LIMBCOND(ch, 3) = 100;
      send_to_char(ch, "Your right leg has fully recovered.\r\n");
    }

    if (GET_LIMBCOND(ch, 4) > 0 && GET_LIMBCOND(ch, 4) < 50) {
      if (GET_LIMBCOND(ch, 4) + healrate >= 50) {
        act("You realize your left leg is no longer broken.", TRUE, ch, 0, 0,
            TO_CHAR);
        act("$n starts moving $s left leg gingerly for a moment.", TRUE, ch, 0,
            0, TO_ROOM);
        GET_LIMBCOND(ch, 4) += healrate;
        recovered = TRUE;
      } else {
        GET_LIMBCOND(ch, 4) += healrate;
        send_to_char(
            ch,
            "Your left leg feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
            GET_LIMBCOND(ch, 1), "%", "%");
      }
    } else if (GET_LIMBCOND(ch, 4) + healrate < 100) {
      GET_LIMBCOND(ch, 4) += healrate;
      send_to_char(
          ch,
          "Your left leg feels a little better @D[@G%d%s@D/@g100%s@D]@n.\r\n",
          GET_LIMBCOND(ch, 4), "%", "%");
    } else if (GET_LIMBCOND(ch, 4) < 100 &&
               GET_LIMBCOND(ch, 4) + healrate >= 100) {
      GET_LIMBCOND(ch, 4) = 100;
      send_to_char(ch, "Your left leg as fully recovered.\r\n");
    }

    if (!PLR_FLAGGED(ch, PLR_BANDAGED) && recovered == TRUE) {
      if (axion_dice(-10) > GET_CON(ch)) {
        char_stat_mod(ch, "strength", -1);
        char_stat_mod(ch, "agility", -1);
        char_stat_mod(ch, "speed", -1);
        send_to_char(ch, "@RYou lose 1 Strength, Agility, and Speed!\r\n");
        if (char_stat_get(ch, "strength") < 4) {
          char_stat_set(ch, "strength", 4);
        }
        if (char_stat_get(ch, "constitution") < 4) {
          char_stat_set(ch, "constitution", 4);
        }
        if (char_stat_get(ch, "agility") < 4) {
          char_stat_set(ch, "agility", 4);
        }
        if (char_stat_get(ch, "speed") < 4) {
          char_stat_set(ch, "speed", 4);
        }
        save_char(ch);
      }
    }
  }

  if (PLR_FLAGGED(ch, PLR_BANDAGED) && recovered == TRUE) {
    REMOVE_BIT_AR(PLR_FLAGS(ch), PLR_BANDAGED);
    send_to_char(ch, "You remove your bandages.\r\n");
    return;
  }
}

static void tick_char_relax(struct char_data *i) {
  if (IS_NPC(i) || !char_room_get(i)) return;
  if (room_flagged(char_room_get(i), ROOM_HOUSE)) {
    GET_RELAXCOUNT(i) += 1;
  } else if (GET_RELAXCOUNT(i) >= 464) {
    GET_RELAXCOUNT(i) -= 4;
  } else if (GET_RELAXCOUNT(i) >= 232) {
    GET_RELAXCOUNT(i) -= 3;
  } else if (GET_RELAXCOUNT(i) > 0 && rand_number(1, 3) == 3) {
    GET_RELAXCOUNT(i) -= 2;
  } else {
    GET_RELAXCOUNT(i) -= 1;
  }
  if (GET_RELAXCOUNT(i) < 0) GET_RELAXCOUNT(i) = 0;
}

static void tick_char_needs(struct char_data *i) {
  if (rand_number(1, 2) == 2) gain_condition(i, HUNGER, -1);
  if (rand_number(1, 2) == 2) gain_condition(i, THIRST, -1);
  if (rand_number(1, 2) == 2) gain_condition(i, DRUNK, -1);
}

static void tick_char_aura(struct char_data *i) {
  if (!PLR_FLAGGED(i, PLR_AURALIGHT)) return;
  if (getCurKI(i) > mana_gain(i) + getPercentOfMaxKI(i, .05)) {
    send_to_char(i, "You send more energy into your aura to keep the light active.\r\n");
    decCurKI(i, mana_gain(i) + getPercentOfMaxKI(i, .05));
  } else {
    send_to_char(i, "You don't have enough energy to keep the aura active.\r\n");
    act("$n's aura slowly stops shining and fades.\r\n", TRUE, i, nullptr, nullptr, TO_ROOM);
    REMOVE_BIT_AR(PLR_FLAGS(i), PLR_AURALIGHT);
    room_light_mod(char_room_get(i), -1);
  }
}

static void tick_char_sleep_kaioken(struct char_data *i) {
  int x = (GET_KAIOKEN(i) * 5) + 5;
  if (GET_SLEEPT(i) > 0 && GET_POS(i) != POS_SLEEPING)
    GET_SLEEPT(i) -= 1;
  if (GET_SLEEPT(i) < 8 && GET_POS(i) == POS_SLEEPING) {
    GET_SLEEPT(i) += rand_number(2, 4);
    if (GET_SLEEPT(i) > 8) GET_SLEEPT(i) = 8;
  }
  if (GET_KAIOKEN(i) > 0) {
    improve_skill(i, SKILL_KAIOKEN, -1);
    if (GET_SKILL(i, SKILL_KAIOKEN) < rand_number(1, x) ||
        getCurST(i) <= GET_MAX_MOVE(i) / 10)
      remove_kaioken(i, 2);
  }
}

static void tick_char_burns(struct char_data *i) {
  if (!char_condition_has(i, "burned")) return;
  if (rand_number(1, 5) >= 4) {
    send_to_char(i, "Your burns are healed now.\r\n");
    act("$n@w's burns are now healed.@n", TRUE, i, 0, 0, TO_ROOM);
    char_condition_remove(i, "burned", "healing_burned");
  }
}

static void tick_char_vitals(struct char_data *i) {
  incCurHealth(i, hit_gain(i));
  incCurST(i, move_gain(i));
  incCurKI(i, mana_gain(i));
  if (!IS_NPC(i)) heal_limb(i);
}

/* Returns true if any die() was called (caller should continue to next char). */
static bool tick_char_survival(struct char_data *i) {
  bool died = false;

  if (room_sector_type_get(char_room_get(i)) == SECT_WATER_NOSWIM &&
      !CARRIED_BY(i) && !IS_KANASSAN(i)) {
    if (getCurST(i) >= getCurCarriedWeight(i)) {
      act("@bYou swim in place.@n", TRUE, i, 0, 0, TO_CHAR);
      act("@C$n@b swims in place.@n", TRUE, i, 0, 0, TO_ROOM);
      decCurST(i, getCurCarriedWeight(i));
    } else {
      decCurST(i, getCurCarriedWeight(i));
      act("@RYou are drowning!@n", TRUE, i, 0, 0, TO_CHAR);
      act("@C$n@b gulps water as $e struggles to stay above the water line.@n",
          TRUE, i, 0, 0, TO_ROOM);
      if (GET_HIT(i) - (getMaxPL(i) / 3) <= 0) {
        act("@rYou drown!@n", TRUE, i, 0, 0, TO_CHAR);
        act("@R$n@r drowns!@n", TRUE, i, 0, 0, TO_ROOM);
        die(i, NULL);
        died = true;
      } else {
        decCurHealth(i, getMaxPL(i) / 3);
      }
    }
  }

  if (!has_o2(i) && room_is_sunken(char_room_get(i)) &&
      !room_flagged(char_room_get(i), ROOM_SPACE)) {
    if (getCurKI(i) - mana_gain(i) > GET_MAX_MANA(i) / 200) {
      send_to_char(i, "Your ki holds an atmosphere around you.\r\n");
      decCurKI(i, mana_gain(i) + getPercentOfMaxKI(i, .005));
    } else {
      if (GET_HIT(i) - hit_gain(i) > getMaxPL(i) * 0.05) {
        send_to_char(i, "You struggle trying to hold your breath!\r\n");
        decCurHealth(i, hit_gain(i) + getPercentOfMaxHealth(i, .05));
      } else if (GET_HIT(i) <= GET_MAX_HIT(i) / 20) {
        send_to_char(i, "You have drowned!\r\n");
        act("@W$n@W drowns right in front of you.@n", FALSE, i, 0, 0, TO_ROOM);
        die(i, NULL);
        died = true;
      }
    }
  }

  if (!has_o2(i) && room_flagged(char_room_get(i), ROOM_SPACE)) {
    if (getCurKI(i) - mana_gain(i) > GET_MAX_MANA(i) * 0.005) {
      send_to_char(i, "Your ki holds an atmosphere around you.\r\n");
      decCurKI(i, mana_gain(i) + getPercentOfMaxKI(i, .005));
    } else {
      if (GET_HIT(i) - hit_gain(i) > getMaxPL(i) * 0.05) {
        send_to_char(i, "You struggle trying to hold your breath!\r\n");
        decCurHealth(i, hit_gain(i) + getPercentOfMaxHealth(i, .05));
      } else if (GET_HIT(i) <= GET_MAX_HIT(i) / 20) {
        send_to_char(i, "You have drowned!\r\n");
        decCurHealthPercentFloored(i, 1, 1);
        act("@W$n@W drowns right in front of you.@n", FALSE, i, 0, 0, TO_ROOM);
        die(i, NULL);
        died = true;
      }
    }
  }

  if (!char_condition_has(i, "flying") &&
      room_geffect_get(char_room_get(i)) == 6 &&
      !MOB_FLAGGED(i, MOB_NOKILL) && !IS_DEMON(i)) {
    act("@rYour legs are burned by the lava!@n", TRUE, i, 0, 0, TO_CHAR);
    act("@R$n@r's legs are burned by the lava!@n", TRUE, i, 0, 0, TO_ROOM);
    if (IS_NPC(i) && IS_HUMANOID(i) && rand_number(1, 2) == 2)
      do_fly(i, 0, 0, 0);
    decCurHealthPercent(i, .05);
    if (GET_HIT(i) < 0) {
      act("@rYou have burned to death!@n", TRUE, i, 0, 0, TO_CHAR);
      act("@R$n@r has burned to death!@n", TRUE, i, 0, 0, TO_ROOM);
      die(i, NULL);
      died = true;
    }
  }

  return died;
}

static void tick_char_heal_messages(struct char_data *i, bool change) {
  if (!change || char_condition_has(i, "poison")) return;
  if (PLR_FLAGGED(i, PLR_HEALT) && SITS(i) != NULL) {
    send_to_char(i, "@wThe healing tank works wonders on your injuries.@n\r\n");
    HCHARGE(SITS(i)) -= rand_number(1, 2);
    if (HCHARGE(SITS(i)) == 0) {
      send_to_char(i, "@wThe healing tank is now too low on energy to heal you.\r\n");
      act("You step out of the now empty healing tank.", TRUE, i, 0, 0, TO_CHAR);
      act("@C$n@w steps out of the now empty healing tank.@n", TRUE, i, 0, 0, TO_ROOM);
      REMOVE_BIT_AR(PLR_FLAGS(i), PLR_HEALT);
      SITTING(SITS(i)) = NULL;
      SITS(i) = NULL;
    } else if (isFullVitals(i)) {
      send_to_char(i, "@wYou are fully recovered now.\r\n");
      act("You step out of the now empty healing tank.", TRUE, i, 0, 0, TO_CHAR);
      act("@C$n@w steps out of the now empty healing tank.@n", TRUE, i, 0, 0, TO_ROOM);
      REMOVE_BIT_AR(PLR_FLAGS(i), PLR_HEALT);
      SITTING(SITS(i)) = NULL;
      SITS(i) = NULL;
    }
  } else if (PLR_FLAGGED(i, PLR_HEALT) && SITS(i) == NULL) {
    REMOVE_BIT_AR(PLR_FLAGS(i), PLR_HEALT);
  } else if (GET_POS(i) == POS_SLEEPING) {
    send_to_char(i, "@wYour sleep does you some good.@n\r\n");
    if (!IS_ANDROID(i) && !FIGHTING(i))
      restoreLFAnnounced(i, false);
  } else if (GET_POS(i) == POS_RESTING) {
    send_to_char(i, "@wYou feel relaxed and better.@n\r\n");
    if (!isFullLF(i) && !IS_ANDROID(i) && !FIGHTING(i) &&
        GET_SUPPRESS(i) <= 0 && GET_HIT(i) != getMaxPL(i)) {
      incCurLFPercent(i, .15);
      send_to_char(i, "@CYou feel more lively.@n\r\n");
    }
  } else if (GET_POS(i) == POS_SITTING) {
    send_to_char(i, "@wYou feel rested and better.@n\r\n");
  } else {
    send_to_char(i, "You feel slightly better.\r\n");
  }
}

/* Returns true if the character died from poison. */
static bool tick_char_poison(struct char_data *i) {
  if (!char_condition_has(i, "poison")) return false;
  auto con = GET_CON(i);
  double cost = con >= 100 ? 0.01
              : con >= 80  ? 0.02
              : con >= 50  ? 0.03
              : con >= 30  ? 0.04
              : con >= 20  ? 0.05
              :                     0.06;
  if (GET_HIT(i) - GET_MAX_HIT(i) * cost > 0) {
    send_to_char(i, "You puke as the poison burns through your blood.\r\n");
    act("$n shivers and then pukes.", TRUE, i, 0, 0, TO_ROOM);
    decCurHealth(i, getMaxPL(i) * cost);
    return false;
  } else {
    send_to_char(i, "The poison claims your life!\r\n");
    act("$n pukes up blood and falls down dead!", TRUE, i, 0, 0, TO_ROOM);
    auto poisonby = char_by_id(char_condition_number_get(i, "poison", "poison_by"));
    die(i, poisonby);
    return true;
  }
}

static void point_update_characters(void) {
  struct char_data *next_char;
  for (auto *i = character_list; i; i = next_char) {
    next_char = i->next;

    tick_char_relax(i);
    tick_char_needs(i);
    if (IS_NPC(i)) i->aggtimer = 0;

    if (GET_POS(i) >= POS_STUNNED) {
      bool change = false;
      update_flags(i);
      if (!IS_NPC(i) && !isFullVitals(i)) change = true;

      tick_char_aura(i);
      if (IS_MUTANT(i) && (GET_GENOME(i, 0) == 6 || GET_GENOME(i, 1) == 6))
        mutant_limb_regen(i);
      tick_char_sleep_kaioken(i);
      tick_char_burns(i);
      tick_char_vitals(i);
      if (tick_char_survival(i)) continue;
      tick_char_heal_messages(i, change);
      if (tick_char_poison(i)) continue;
      if (GET_POS(i) <= POS_STUNNED)
        update_pos(i);
    } else if (GET_POS(i) == POS_INCAP || GET_POS(i) == POS_MORTALLYW) {
      continue;
    }

    if (getCurKI(i) >= GET_MAX_MANA(i) * 0.5 &&
        GET_CHARGE(i) < GET_MAX_MANA(i) * 0.1 &&
        GET_PREFERENCE(i) == PREFERENCE_KI && !PLR_FLAGGED(i, PLR_AURALIGHT))
      GET_CHARGE(i) = GET_MAX_MANA(i) * 0.1;

    if (!IS_NPC(i)) {
      update_char_objects(i);
      update_innate(i);
      if (GET_ADMLEVEL(i) < CONFIG_IDLE_MAX_LEVEL)
        check_idling(i);
      else
        (i->timer)++;
    }
  }
}

/* Returns true if the object was extracted. */
static bool tick_obj_norent(struct obj_data *j) {
  if (!OBJ_FLAGGED(j, ITEM_NORENT) || j->worn_by || j->carried_by ||
      obj_selling == j || GET_OBJ_VNUM(j) == 7200)
    return false;
  time_t diff = time(0) - GET_LAST_LOAD(j);
  if (diff > 240 && GET_LAST_LOAD(j) > 0) {
    mud_log("No rent object (%s) extracted from room (%d)",
        j->short_description, obj_room_vnum_get(j));
    extract_obj(j);
    return true;
  }
  return false;
}

static void tick_obj_hatch(struct obj_data *j) {
  if (GET_OBJ_TYPE(j) != ITEM_HATCH) return;
  struct obj_data *vehicle;
  if ((vehicle = find_vehicle_by_vnum(GET_OBJ_VAL(j, VAL_HATCH_DEST))))
    GET_OBJ_VAL(j, 3) = obj_room_vnum_get(vehicle);
}

static void tick_obj_healing_tank(struct obj_data *j) {
  if (GET_OBJ_VNUM(j) != 65) return;
  if (HCHARGE(j) < 20 && !SITTING(j))
    HCHARGE(j) += rand_number(0, 1);
}

/* Handles the mutually exclusive portal/vnum1306/generic-timer chain.
   Returns true if the object was extracted. */
static bool tick_obj_timed(struct obj_data *j) {
  if (GET_OBJ_TYPE(j) == ITEM_PORTAL) {
    if (GET_OBJ_TIMER(j) > 0) GET_OBJ_TIMER(j)--;
    if (GET_OBJ_TIMER(j) == 0) {
      act("A glowing portal fades from existence.", TRUE,
          room_people_get(obj_room_get(j)), j, 0, TO_ROOM);
      act("A glowing portal fades from existence.", TRUE,
          room_people_get(obj_room_get(j)), j, 0, TO_CHAR);
      extract_obj(j);
      return true;
    }
  } else if (GET_OBJ_VNUM(j) == 1306) {
    if (GET_OBJ_TIMER(j) > 0) GET_OBJ_TIMER(j)--;
    if (GET_OBJ_TIMER(j) == 0) {
      act("The $p@n settles to the ground and goes out.", TRUE,
          room_people_get(obj_room_get(j)), j, 0, TO_ROOM);
      act("A $p@n settles to the ground and goes out.", TRUE,
          room_people_get(obj_room_get(j)), j, 0, TO_CHAR);
      extract_obj(j);
      return true;
    }
  } else if (GET_OBJ_TIMER(j) > 0) {
    GET_OBJ_TIMER(j)--;
    if (!GET_OBJ_TIMER(j))
      timer_otrigger(j);
  }
  return false;
}

static void tick_obj_corpse(struct obj_data *j) {
  if (GET_OBJ_TIMER(j) > 0) GET_OBJ_TIMER(j)--;

  if (!strstr(j->name, "android") && !strstr(j->name, "Android") &&
      !OBJ_FLAGGED(j, ITEM_BURIED)) {
    auto oroom = obj_room_get(j);
    static const struct { int timer; const char *msg; } decay_msgs[] = {
      {5, "@DFlies start to gather around $p@D.@n"},
      {3, "@DA cloud of flies has formed over $p@D.@n"},
      {2, "@DMaggots can be seen crawling all over $p@D.@n"},
      {1, "@DMaggots have nearly stripped $p of all its flesh@D.@n"},
    };
    for (auto &dm : decay_msgs) {
      if (GET_OBJ_TIMER(j) == dm.timer && oroom && room_people_get(oroom)) {
        act(dm.msg, TRUE, room_people_get(oroom), j, 0, TO_CHAR);
        act(dm.msg, TRUE, room_people_get(oroom), j, 0, TO_ROOM);
        break;
      }
    }
  }

  if (GET_OBJ_TIMER(j) != 0) return;

  auto oroom = obj_room_get(j);
  if (j->carried_by) {
    if (!strstr(j->name, "android")) {
      act("$p decays in your hands.", FALSE, j->carried_by, j, 0, TO_CHAR);
      if (oroom && room_people_get(oroom)) {
        act("A quivering horde of maggots consumes $p.", TRUE,
            room_people_get(oroom), j, 0, TO_ROOM);
        act("A quivering horde of maggots consumes $p.", TRUE,
            room_people_get(oroom), j, 0, TO_CHAR);
      }
    } else {
      act("$p decays in your hands.", FALSE, j->carried_by, j, 0, TO_CHAR);
      if (oroom && room_people_get(oroom)) {
        act("$p breaks down completely into a pile of junk.", TRUE,
            room_people_get(oroom), j, 0, TO_ROOM);
        act("$p breaks down completely into a pile of junk.", TRUE,
            room_people_get(oroom), j, 0, TO_CHAR);
      }
    }
  }
  obj_contents_iterate(j, [&](struct obj_data *jj) {
    obj_from_obj(jj);
    if (j->in_obj)            obj_to_obj(jj, j->in_obj);
    else if (j->carried_by)   obj_to_room(jj, char_room_get(j->carried_by));
    else if (obj_room_get(j)) obj_to_room(jj, obj_room_get(j));
    else                      core_dump();
    return true;
  });
  extract_obj(j);
}

static void tick_obj_ice(struct obj_data *j) {
  auto oroom = obj_room_get(j);
  if (GET_OBJ_VNUM(j) == 79 && rand_number(1, 2) == 2) {
    if (room_geffect_get(oroom) >= 1 && room_geffect_get(oroom) <= 5) {
      send_to_room(oroom,
                   "The heat from the lava melts a great deal of the "
                   "glacial wall and the lava cools a bit in turn.\r\n");
      room_geffect_mod(oroom, -1);
      if (GET_OBJ_WEIGHT(j) - (5 + GET_OBJ_WEIGHT(j) * 0.025) > 0) {
        GET_OBJ_WEIGHT(j) -= 5 + (GET_OBJ_WEIGHT(j) * 0.025);
      } else {
        send_to_room(oroom, "The glacial wall blocking off the %s direction "
                            "melts completely away.\r\n", dirs[GET_OBJ_COST(j)]);
        extract_obj(j);
      }
    } else if (GET_OBJ_WEIGHT(j) - (5 + GET_OBJ_WEIGHT(j) * 0.025) > 0) {
      GET_OBJ_WEIGHT(j) -= 5 + (GET_OBJ_WEIGHT(j) * 0.025);
      send_to_room(oroom, "The glacial wall blocking off the %s direction "
                          "melts some what.\r\n", dirs[GET_OBJ_COST(j)]);
    } else {
      send_to_room(oroom, "The glacial wall blocking off the %s direction "
                          "melts completely away.\r\n", dirs[GET_OBJ_COST(j)]);
      extract_obj(j);
    }
  } else if (GET_OBJ_VNUM(j) != 79) {
    if (j->carried_by && !j->in_obj) {
      int melt = 5 + (GET_OBJ_WEIGHT(j) * 0.02);
      if (GET_OBJ_WEIGHT(j) - melt > 0) {
        GET_OBJ_WEIGHT(j) -= melt;
        send_to_char(j->carried_by, "%s @wmelts a little.\r\n",
                     j->short_description);
      } else {
        send_to_char(j->carried_by, "%s @wmelts completely away.\r\n",
                     j->short_description);
        extract_obj(j);
      }
    } else if (oroom) {
      if (GET_OBJ_WEIGHT(j) - (5 + GET_OBJ_WEIGHT(j) * 0.02) > 0) {
        GET_OBJ_WEIGHT(j) -= 5 + (GET_OBJ_WEIGHT(j) * 0.02);
        send_to_room(oroom, "%s @wmelts a little.\r\n", j->short_description);
      } else {
        send_to_room(oroom, "%s @wmelts completely away.\r\n",
                     j->short_description);
        extract_obj(j);
      }
    }
  }
}

static void point_update_objects(void) {
  struct obj_data *next_thing;
  for (auto *j = object_list; j; j = next_thing) {
    next_thing = j->next;
    if (IS_CORPSE(j) || OBJ_FLAGGED(j, ITEM_ICE)) continue;
    if (tick_obj_norent(j)) continue;
    tick_obj_hatch(j);
    tick_obj_healing_tank(j);
    if (tick_obj_timed(j)) continue;
  }
  obj_iterate_subscriptions("obj_corpse", [](struct obj_data *j) {
    tick_obj_corpse(j);
    return true;
  });
  obj_iterate_subscriptions("obj_ice", [](struct obj_data *j) {
    tick_obj_ice(j);
    return true;
  });
}

void point_update(void) {
  point_update_characters();
  point_update_objects();
}
