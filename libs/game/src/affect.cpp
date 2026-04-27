#include "dbat/game/affect.h"
#include "dbat/db/consts/applies.h"
#include "dbat/db/utils.h"

#include "dbat/game/character_utils.h"
#include "dbat/game/object_utils.h"
#include "dbat/game/spells.h"
#include "dbat/game/feats.h"

void aff_apply_modify(struct char_data *ch, int loc, int mod, int spec, char *msg)
{
  switch (loc) {
  case APPLY_NONE:
  case APPLY_STR:
  case APPLY_DEX:
  case APPLY_INT:
  case APPLY_WIS:
  case APPLY_CON:
  case APPLY_CHA:
  case APPLY_CLASS:
  case APPLY_LEVEL:
    break;

  case APPLY_AGE:
    ch->time.birth -= (mod * SECS_PER_MUD_YEAR);
    break;

  case APPLY_CHAR_WEIGHT:
  case APPLY_CHAR_HEIGHT:
    break;

  case APPLY_MANA:
  case APPLY_KI:
    break;

  case APPLY_HIT:
    break;

  case APPLY_MOVE:
    break;

  case APPLY_AC:
    GET_ARMOR(ch) += mod;
    break;

  case APPLY_ACCURACY:
    break;

  case APPLY_DAMAGE:
    break;

  case APPLY_LIFEMAX:
    ch->lifebonus += mod;
    break;

  default:
    log("SYSERR: Unknown apply adjust %d attempt (%s, affect_modify).", loc, __FILE__);
    break;

  } /* switch */
}


void affect_modify(struct char_data * ch, int loc, int mod, int spec, long bitv, bool add)
{
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


void affect_modify_ar(struct char_data * ch, int loc, int mod, int spec, bitvector_t bitv[], bool add)
{
  int i , j;

  if (add) {
    for(i = 0; i < AF_ARRAY_MAX; i++)
      for(j = 0; j < 32; j++)
        if(IS_SET_AR(bitv, (i*32)+j)) {
         if ((i*32)+j != AFF_INFRAVISION || !IS_ANDROID(ch)) {
          SET_BIT_AR(AFF_FLAGS(ch), (i*32)+j);
         }
        }
  } else {
    for(i = 0; i < AF_ARRAY_MAX; i++)
      for(j = 0; j < 32; j++)
        if(IS_SET_AR(bitv, (i*32)+j)) {
         if ((i*32)+j != AFF_INFRAVISION || !IS_ANDROID(ch)) {
          REMOVE_BIT_AR(AFF_FLAGS(ch), (i*32)+j);
         }
        }
    mod = -mod;
  }

  aff_apply_modify(ch, loc, mod, spec, "affect_modify_ar");
}

/* Insert an affect_type in a char_data structure
   Automatically sets apropriate bits and apply's */
void affect_to_char(struct char_data *ch, struct affected_type *af)
{
  struct affected_type *affected_alloc;

  CREATE(affected_alloc, struct affected_type, 1);

  if (!ch->affected) {
    ch->next_affect = affect_list;
    affect_list = ch;
  }
  *affected_alloc = *af;
  affected_alloc->next = ch->affected;
  ch->affected = affected_alloc;

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector, TRUE);
  char_der_invalidate(ch);
}



/*
 * Remove an affected_type structure from a char (called when duration
 * reaches zero). Pointer *af must never be NIL!  Frees mem and calls
 * affect_location_apply
 */
void affect_remove(struct char_data *ch, struct affected_type *af)
{
  struct affected_type *cmtemp;

  if (ch->affected == NULL) {
    core_dump();
    return;
  }

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector, FALSE);
  REMOVE_FROM_LIST(af, ch->affected, next, cmtemp);
  free(af);
  char_der_invalidate(ch);
  if (!ch->affected) {
    struct char_data *temp;
    REMOVE_FROM_LIST(ch, affect_list, next_affect, temp);
    ch->next_affect = NULL;
  }
}



/* Call affect_remove with every spell of spelltype "skill" */
void affect_from_char(struct char_data *ch, int type)
{
  struct affected_type *hjp, *next;

  for (hjp = ch->affected; hjp; hjp = next) {
    next = hjp->next;
    if (hjp->type == type)
      affect_remove(ch, hjp);
  }
}



/* Call affect_remove with every spell of spelltype "skill" */
void affectv_from_char(struct char_data *ch, int type)
{
  struct affected_type *hjp, *next;

  for (hjp = ch->affectedv; hjp; hjp = next) {
    next = hjp->next;
    if (hjp->type == type)
      affectv_remove(ch, hjp);
  }
}



/*
 * Return TRUE if a char is affected by a spell (SPELL_XXX),
 * FALSE indicates not affected.
 */
bool affected_by_spell(struct char_data *ch, int type)
{
  struct affected_type *hjp;

  for (hjp = ch->affected; hjp; hjp = hjp->next)
    if (hjp->type == type)
      return (TRUE);

  return (FALSE);
}



/*
 * Return TRUE if a char is affected by a spell (SPELL_XXX),
 * FALSE indicates not affected.
 */
bool affectedv_by_spell(struct char_data *ch, int type)
{
  struct affected_type *hjp;

  for (hjp = ch->affectedv; hjp; hjp = hjp->next)
    if (hjp->type == type)
      return (TRUE);

  return (FALSE);
}



void affect_join(struct char_data *ch, struct affected_type *af,
		      bool add_dur, bool avg_dur, bool add_mod, bool avg_mod)
{
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


void affectv_to_char(struct char_data *ch, struct affected_type *af)
{
  struct affected_type *affected_alloc;

  CREATE(affected_alloc, struct affected_type, 1);

  if (!ch->affectedv) {
    ch->next_affectv = affectv_list;
    affectv_list = ch;
  }
  *affected_alloc = *af;
  affected_alloc->next = ch->affectedv;
  ch->affectedv = affected_alloc;

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector, TRUE);
  char_der_invalidate(ch);
}

void affectv_remove(struct char_data *ch, struct affected_type *af)
{
  struct affected_type *cmtemp;

  if (ch->affectedv == NULL) {
    core_dump();
    return;
  }

  affect_modify(ch, af->location, af->modifier, af->specific, af->bitvector, FALSE);
  REMOVE_FROM_LIST(af, ch->affectedv, next, cmtemp);
  free(af);
  char_der_invalidate(ch);
  if (!ch->affectedv) {
    struct char_data *temp;
    REMOVE_FROM_LIST(ch, affectv_list, next_affectv, temp);
    ch->next_affectv = NULL;
  }
}

void affectv_join(struct char_data *ch, struct affected_type *af,
                      bool add_dur, bool avg_dur, bool add_mod, bool avg_mod)
{
  struct affected_type *hjp, *next;
  bool found = FALSE;

  for (hjp = ch->affectedv; !found && hjp; hjp = next) {
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

      affectv_remove(ch, hjp);
      affectv_to_char(ch, af);
      found = TRUE;
    }
  }
  if (!found)
    affectv_to_char(ch, af);
}
