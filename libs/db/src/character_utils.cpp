#include "dbat/db/character_utils.h"
#include <stdlib.h>
#include <string.h>
#include "dbat/db/consts/types.h"
#include "dbat/db/utils.h"
#include "dbat/db/consts/maximums.h"
#include "dbat/db/consts/positions.h"
#include "dbat/db/consts/playerflags.h"
#include "dbat/db/consts/mobflags.h"
#include "dbat/db/consts/sex.h"
#include "dbat/db/consts/races.h"
#include "dbat/db/weather.h"
#include "dbat/db/affected.h"
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

static void char_skills_invalidate_specific(struct char_data *ch, uint8_t skill_id) {
  ch->skills[skill_id].cached = false;
  ch->skills[skill_id].bonus = 0;
  ch->skills[skill_id].total = 0;
}

void char_skills_invalidate(struct char_data *ch) {
  for(int i = 0; i < SKILL_TABLE_SIZE; i++) {
    char_skills_invalidate_specific(ch, i);
  }
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
  char_skills_invalidate_specific(ch, skill_id);
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

struct der_bonus char_der_calculate_bonuses(struct char_data *ch, uint8_t der_id) {
  // TODO: new modifier system will go here.
  struct der_bonus bonus = {0, 0, 0};

  // now if it makes sense, we'll iterate other affect sources...
  if(der_definitions[der_id].apply != APPLY_NONE) {
    bonus.post_bonus += char_der_get_affect_bonus(ch, der_definitions[der_id].apply, -1);
  }

  return bonus;
}

stat_t char_der_apply_bonuses(struct char_data *ch, uint8_t der_id, stat_t base_value, struct der_bonus bonus) {
  double pre_bonus = base_value + bonus.pre_bonus;
  double additive_multiplier = (100.0 + bonus.additive_multiplier) / 100.0;

  stat_t multiplied = pre_bonus * additive_multiplier;

  stat_t post_bonus = multiplied + bonus.post_bonus;

  return post_bonus;
}

stat_t char_der_calculate(struct char_data *ch, uint8_t der_id, stat_t base_value) {
  struct der_bonus bonus = char_der_calculate_bonuses(ch, der_id);

  stat_t total_value = char_der_apply_bonuses(ch, der_id, base_value, bonus);
  return total_value;
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


double char_meter_get(struct char_data *ch, uint8_t meter_id) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  return ch->meters[meter_id];
}

double char_meter_set(struct char_data *ch, uint8_t meter_id, double value) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  ch->meters[meter_id] = MAX(0.0, MIN(1.0, value));
  return ch->meters[meter_id];
}

double char_meter_modify(struct char_data *ch, uint8_t meter_id, double delta) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  double new_value = ch->meters[meter_id] + delta;
  return char_meter_set(ch, meter_id, new_value);
}

stat_t char_meter_max(struct char_data *ch, uint8_t meter_id) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  uint8_t der_id = meter_definitions[meter_id].der_id;
  return char_der_get(ch, der_id);
}

stat_t char_meter_current(struct char_data *ch, uint8_t meter_id) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  double perc = char_meter_get(ch, meter_id);
  stat_t max = char_meter_max(ch, meter_id);
  return (stat_t)(perc * max);
}

stat_t char_meter_set_amount(struct char_data *ch, uint8_t meter_id, stat_t amount) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  stat_t max = char_meter_max(ch, meter_id);
  double perc = (max > 0) ? ((double)amount / (double)max) : 0;
  char_meter_set(ch, meter_id, perc);
  return char_meter_current(ch, meter_id);
}

stat_t char_meter_modify_amount(struct char_data *ch, uint8_t meter_id, stat_t delta) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  stat_t current = char_meter_current(ch, meter_id);
  stat_t new_amount = current + delta;
  return char_meter_set_amount(ch, meter_id, new_amount);
}

stat_t char_meter_percent(struct char_data *ch, uint8_t meter_id, double percent) {
  if (meter_id < 0 || meter_id > NUM_METERS) {
    return 0; // or some error value
  }
  stat_t max = char_meter_max(ch, meter_id);
  double value = MAX(0.0, MIN(1.0, percent));
  return max*value;
}