#include "dbat/db/character_utils.h"
#include <stdlib.h>
#include <string.h>
#include "dbat/db/consts/types.h"
#include "dbat/db/consts/maximums.h"
#include "dbat/db/utils.h"
#include "dbat/db/consts/positions.h"
#include "dbat/db/consts/playerflags.h"
#include "dbat/db/consts/mobflags.h"
#include "dbat/db/consts/sex.h"
#include "dbat/db/consts/races.h"
#include "dbat/db/weather.h"
#include "dbat/db/affected.h"
#include "dbat/db/consts/applies.h"
#include "dbat/db/objects.h"


bool MOON_TIMECHECK() {
    switch(time_info.day) {
        case 20:
            return time_info.hours >= 21;
        case 21:
            return time_info.hours < 4 || time_info.hours >= 21;
        case 22:
            return time_info.hours < 4;
    }
    return false;
}

// Stats System
void char_stats_init(struct char_data *ch) {
  for(int i = 0; i < NUM_CHARACTER_STATS; i++) {
    ch->stats[i] = stat_definitions[i].default_value;
  }
  char_der_invalidate(ch);
}

stat_t char_stats_get(const struct char_data *ch, uint8_t stat_id) {
  if (stat_id < 0 || stat_id > NUM_CHARACTER_STATS) {
    return 0; // or some error value
  }
  return ch->stats[stat_id];
}

stat_t char_stats_set(struct char_data *ch, uint8_t stat_id, stat_t value) {
  if (stat_id < 0 || stat_id > NUM_CHARACTER_STATS) {
    return 0; // or some error value
  }
  stat_t set_to = value;
  if(stat_definitions[stat_id].flags & STATDEF_MIN) {
    set_to = MAX(set_to, stat_definitions[stat_id].min_value);
  }
  if(stat_definitions[stat_id].flags & STATDEF_MAX) {
    set_to = MIN(set_to, stat_definitions[stat_id].max_value);
  }
  ch->stats[stat_id] = set_to;
  // just naively invalidate the entire cache for now.
  // worry about optimizing this later.
  char_der_invalidate(ch);
  return set_to;
}

stat_t char_stats_modify(struct char_data *ch, uint8_t stat_id, stat_t delta) {
  if (stat_id < 0 || stat_id > NUM_CHARACTER_STATS) {
    return 0; // or some error value
  }
  stat_t new_value = ch->stats[stat_id] + delta;
  return char_stats_set(ch, stat_id, new_value);
}

static void char_der_invalidate_specific(struct char_data *ch, uint8_t der_id) {
  ch->derived_stats[der_id].calculated = false;
  ch->derived_stats[der_id].base = 0;
  ch->derived_stats[der_id].pre_bonus = 0;
  ch->derived_stats[der_id].additive_multiplier = 0;
  ch->derived_stats[der_id].post_bonus = 0;
  ch->derived_stats[der_id].effective = 0;
}

void char_der_invalidate(struct char_data *ch) {
  for(int i = 0; i < NUM_DERIVED_STATS; i++) {
    char_der_invalidate_specific(ch, i);
  }
}

stat_t char_der_get_affect_bonus(struct char_data *ch, int location, int specific) {
  stat_t bonus = 0;
  struct affected_type *af;
  for(af = ch->affected; af; af = af->next) {
    if(af->location == location && (specific == -1 || af->specific == specific)) {
      bonus += af->modifier;
    }
  }

  // and now for equipment.
  for(int i = 0; i < NUM_WEARS; i++) {
    if(GET_EQ(ch, i)) {
      struct obj_data *obj = GET_EQ(ch, i);
      for(int i = 0; i < MAX_OBJ_AFFECT; i++) {
        if(obj->affected[i].location == location && (specific == -1 || obj->affected[i].specific == specific)) {
          bonus += obj->affected[i].modifier;
        }
      }
    }
  }

  return bonus;
}

static void char_skills_helper(struct char_data *ch, uint8_t skill_id) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return; // or some error value
  }
  if(ch->skills[skill_id].cached) {
    return;
  }
  ch->skills[skill_id].bonus = char_der_get_affect_bonus(ch, APPLY_SKILL, skill_id);
  ch->skills[skill_id].total = ch->skills[skill_id].base + ch->skills[skill_id].bonus;
  ch->skills[skill_id].cached = true;
}

stat_t char_skills_base_get(struct char_data *ch, uint8_t skill_id) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return 0; // or some error value
  }
  return ch->skills[skill_id].base;
}

stat_t char_skills_set(struct char_data *ch, uint8_t skill_id, stat_t value) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return 0; // or some error value
  }
  ch->skills[skill_id].base = MIN(0, MAX(100, value));
  // just naively invalidate the entire cache for now.
  // worry about optimizing this later.
  char_skills_helper(ch, skill_id);
  return ch->skills[skill_id].base;
}

stat_t char_skills_modify(struct char_data *ch, uint8_t skill_id, stat_t delta) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return 0; // or some error value
  }
  stat_t new_base = ch->skills[skill_id].base + delta;
  return char_skills_set(ch, skill_id, new_base);
}

stat_t char_skills_get(struct char_data *ch, uint8_t skill_id) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return 0; // or some error value
  }
  char_skills_helper(ch, skill_id);
  return ch->skills[skill_id].total;
}

stat_t char_skills_bonus_get(struct char_data *ch, uint8_t skill_id) {
  if(skill_id < 0 || skill_id > SKILL_TABLE_SIZE) {
    return 0; // or some error value
  }
  char_skills_helper(ch, skill_id);
  return ch->skills[skill_id].bonus;
}

static stat_t char_der_calculate(struct char_data *ch, uint8_t der_id, stat_t base_value) {
  stat_t total_value = 0;
  
  struct modifier_data *m;
  struct effect_data *e;

  // First iterate all new Modifiers.
  for(m = ch->modifiers; m; m = m->next) {
    for(e = m->effects; e; e = e->next) {
      if(e->der_id != der_id) continue;
      switch(e->bonus_type) {
        case 0:
          ch->derived_stats[der_id].pre_bonus += e->modifier;
          break;
        case 1:
          ch->derived_stats[der_id].additive_multiplier += e->modifier;
          break;
        case 2:
          ch->derived_stats[der_id].post_bonus += e->modifier;
          break;
      }
    }
  }

  // now if it makes sense, we'll iterate other affect sources...
  if(der_definitions[der_id].apply != APPLY_NONE) {
    ch->derived_stats[der_id].post_bonus += char_der_get_affect_bonus(ch, der_definitions[der_id].apply, -1);
  }

  double pre_bonus = base_value + ch->derived_stats[der_id].pre_bonus;
  double additive_multiplier = (100.0 + ch->derived_stats[der_id].additive_multiplier) / 100.0;

  stat_t multiplied = pre_bonus * additive_multiplier;

  stat_t post_bonus = multiplied + ch->derived_stats[der_id].post_bonus;

  return post_bonus;
}

stat_t char_der_get(struct char_data *ch, uint8_t der_id) {
  if (der_id < 0 || der_id > NUM_DERIVED_STATS) {
    return 0; // or some error value
  }
  // if we have a cached value, let's use it by all means!
  if(ch->derived_stats[der_id].calculated) {
    return ch->derived_stats[der_id].effective;
  }
  char_der_invalidate_specific(ch, der_id);

  // We don't have a cached value. We'll have to calculate it.

  for(int i = 0; i < 5; i++) {
    if(der_definitions[der_id].depends_on[i] == -1) break;
    // Ensures that all dependencies are calculated before we calculate this stat.
    // Beware of circular dependencies! We have no protection against those.
    char_der_get(ch, der_definitions[der_id].depends_on[i]);
  }

  stat_t base_value = 0;
  if(der_definitions[der_id].base_func) {
    base_value = der_definitions[der_id].base_func(ch, der_id);
  }

  ch->derived_stats[der_id].base = base_value;

  stat_t total_value = base_value;
  if(der_definitions[der_id].effective_func) {
    total_value = der_definitions[der_id].effective_func(ch, der_id);
  } else {
    total_value = char_der_calculate(ch, der_id, base_value);
  }

  ch->derived_stats[der_id].effective = total_value;
  ch->derived_stats[der_id].calculated = true;

  return total_value;
}