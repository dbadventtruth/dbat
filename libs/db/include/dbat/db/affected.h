#pragma once
#include <stdint.h>
#include "consts/types.h"
#include "stats.h"

struct obj_affected_type {
   int location;       /* Which ability to change (APPLY_XXX) */
   int specific;       /* Some locations have parameters      */
   stat_t modifier;       /* How much it changes by              */
};

/* A legacy affect structure. */
struct affected_type {
   uint8_t type;          /* The type of spell that caused this      */
   int16_t duration;      /* For how long its effects will last      */
   stat_t modifier;         /* This is added to apropriate ability     */
   int location;         /* Tells which ability to change(APPLY_XXX)*/
   int specific;         /* Some locations have parameters          */
   bitvector_t bitvector; /* Tells which bits to set (AFF_XXX) */

   struct affected_type *next;
};

// the new and improved affect structure
struct effect_data {
   // The derived stat this effect applies to.
   uint8_t der_id;
   // 0: pre_bonus, 1: additive multiplier, 2: post_bonus
   uint8_t bonus_type;
   stat_t modifier;
   struct effect_data *next;
};

#define MODFAM_SKILL 0
#define MODFAM_TRANSFORMATION 1

struct modifier_data {
   // the family of modifiers this belongs to. Transformations, Spells, Racial, etc.
   uint8_t family;
   // The specific ID of the modifier. Transform ID, Race ID, Sensei ID, etc.
   // A given thing should only have one modifier of a given family.
   int id;

   int16_t duration;      /* For how long its effects will last, -1 for indefinite      */

   struct effect_data* effects;
   struct modifier_data *next;
};