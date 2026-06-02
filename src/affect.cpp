#include "affect.h"
#include "consts/affflags.h"
#include "consts/applies.h"
#include "consts/maximums.h"

#include "affected_impl.h"
#include "character_db.h"
#include "character_impl.h"
#include "character_macros.h"
#include "consts/applies.h"
#include "consts/mobflags.h"
#include "consts/positions.h"
#include "consts/races.h"
#include "feats.h"
#include "flags.h"
#include "log.h"
#include "object_impl.h"
#include "object_macros.h"
#include "races_plus.h"
#include "spells.h"
#include "util_macros.h"

void aff_apply_modify(struct char_data *ch, int loc, int mod, int spec,
                      char *msg) {
  (void)ch;
  (void)loc;
  (void)mod;
  (void)spec;
  (void)msg;
}

void affect_modify(struct char_data *ch, int loc, int mod, int spec, long bitv,
                   bool add) {
  if (add) {
    if (bitv != AFF_INFRAVISION || !IS_ANDROID(ch)) {
      SET_BIT_AR(AFF_FLAGS(ch), bitv);
    }
  } else {
    if (bitv != AFF_INFRAVISION || !IS_ANDROID(ch)) {
      REMOVE_BIT_AR(AFF_FLAGS(ch), bitv);
      mod = -mod;
    }
  }

  aff_apply_modify(ch, loc, mod, spec, "affect_modify");
}

void affect_modify_ar(struct char_data *ch, int loc, int mod, int spec,
                      bitvector_t bitv[], bool add) {
  int i, j;

  if (add) {
    for (i = 0; i < AF_ARRAY_MAX; i++)
      for (j = 0; j < 32; j++)
        if (IS_SET_AR(bitv, (i * 32) + j)) {
          if ((i * 32) + j != AFF_INFRAVISION || !IS_ANDROID(ch)) {
            SET_BIT_AR(AFF_FLAGS(ch), (i * 32) + j);
          }
        }
  } else {
    for (i = 0; i < AF_ARRAY_MAX; i++)
      for (j = 0; j < 32; j++)
        if (IS_SET_AR(bitv, (i * 32) + j)) {
          if ((i * 32) + j != AFF_INFRAVISION || !IS_ANDROID(ch)) {
            REMOVE_BIT_AR(AFF_FLAGS(ch), (i * 32) + j);
          }
        }
    mod = -mod;
  }

  aff_apply_modify(ch, loc, mod, spec, "affect_modify_ar");
}

/* This updates a character by subtracting everything he is affected by */
/* restoring original abilities, and then affecting all again           */
void affect_total(struct char_data *ch) {
  struct affected_type *af;
  int i, j;

  GET_SPELLFAIL(ch) = GET_ARMORCHECK(ch) = GET_ARMORCHECKALL(ch) = 0;

  for (i = 0; i < NUM_WEARS; i++) {
    if (GET_EQ(ch, i))
      for (j = 0; j < MAX_OBJ_AFFECT; j++)
        affect_modify_ar(ch, GET_EQ(ch, i)->affected[j].location,
                         GET_EQ(ch, i)->affected[j].modifier,
                         GET_EQ(ch, i)->affected[j].specific,
                         GET_OBJ_PERM(GET_EQ(ch, i)), FALSE);
  }

  for (af = ch->affected; af; af = af->next)
    affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector,
                  FALSE);

  for (i = 0; i < NUM_WEARS; i++) {
    if (GET_EQ(ch, i)) {
      if (GET_OBJ_TYPE(GET_EQ(ch, i)) == ITEM_ARMOR) {
        GET_SPELLFAIL(ch) += GET_OBJ_VAL(GET_EQ(ch, i), VAL_ARMOR_SPELLFAIL);
        GET_ARMORCHECKALL(ch) += GET_OBJ_VAL(GET_EQ(ch, i), VAL_ARMOR_CHECK);
        if (!is_proficient_with_armor(
                ch, GET_OBJ_VAL(GET_EQ(ch, i), VAL_ARMOR_SKILL)))
          GET_ARMORCHECK(ch) += GET_OBJ_VAL(GET_EQ(ch, i), VAL_ARMOR_CHECK);
      }
      for (j = 0; j < MAX_OBJ_AFFECT; j++)
        affect_modify_ar(ch, GET_EQ(ch, i)->affected[j].location,
                         GET_EQ(ch, i)->affected[j].modifier,
                         GET_EQ(ch, i)->affected[j].specific,
                         GET_OBJ_PERM(GET_EQ(ch, i)), TRUE);
    }
  }

  for (af = ch->affected; af; af = af->next)
    affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector,
                  TRUE);
}

/* Insert an affect_type in a char_data structure
   Automatically sets apropriate bits and apply's */
void affect_to_char(struct char_data *ch, struct affected_type *af) {
  struct affected_type *affected_alloc;

  CREATE(affected_alloc, struct affected_type, 1);

  if (!ch->affected) {
    ch->next_affect = affect_list;
    affect_list = ch;
  }
  *affected_alloc = *af;
  affected_alloc->next = ch->affected;
  ch->affected = affected_alloc;

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector,
                TRUE);
  affect_total(ch);
}

/*
 * Remove an affected_type structure from a char (called when duration
 * reaches zero). Pointer *af must never be NIL!  Frees mem and calls
 * affect_location_apply
 */
void affect_remove(struct char_data *ch, struct affected_type *af) {
  struct affected_type *cmtemp;

  if (ch->affected == NULL) {
    core_dump();
    return;
  }

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector,
                FALSE);
  REMOVE_FROM_LIST(af, ch->affected, next, cmtemp);
  free(af);
  affect_total(ch);
  if (!ch->affected) {
    struct char_data *temp;
    REMOVE_FROM_LIST(ch, affect_list, next_affect, temp);
    ch->next_affect = NULL;
  }
}

/* Call affect_remove with every spell of spelltype "skill" */
void affect_from_char(struct char_data *ch, int type) {
  struct affected_type *hjp, *next;

  for (hjp = ch->affected; hjp; hjp = next) {
    next = hjp->next;
    if (hjp->type == type)
      affect_remove(ch, hjp);
  }
}

/*
 * Return TRUE if a char is affected by a spell (SPELL_XXX),
 * FALSE indicates not affected.
 */
bool affected_by_spell(struct char_data *ch, int type) {
  struct affected_type *hjp;

  for (hjp = ch->affected; hjp; hjp = hjp->next)
    if (hjp->type == type)
      return (TRUE);

  return (FALSE);
}

void affect_join(struct char_data *ch, struct affected_type *af, bool add_dur,
                 bool avg_dur, bool add_mod, bool avg_mod) {
  struct affected_type *hjp, *next;
  bool found = FALSE;

  for (hjp = ch->affected; !found && hjp; hjp = next) {
    next = hjp->next;

    if ((hjp->type == af->type) && (hjp->location == af->location)) {
      if (add_dur)
        af->duration += hjp->duration;
      if (avg_dur)
        af->duration /= 2;

      if (add_mod)
        af->modifier += hjp->modifier;
      if (avg_mod)
        af->modifier /= 2;

      affect_remove(ch, hjp);
      affect_to_char(ch, af);
      found = TRUE;
    }
  }
  if (!found)
    affect_to_char(ch, af);
}
