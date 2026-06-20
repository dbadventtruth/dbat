#pragma once

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    SPELL_LEVEL_0 = 0,
    SPELL_LEVEL_1 = 1,
    SPELL_LEVEL_2 = 2,
    SPELL_LEVEL_3 = 3,
    SPELL_LEVEL_4 = 4,
    SPELL_LEVEL_5 = 5,
    SPELL_LEVEL_6 = 6,
    SPELL_LEVEL_7 = 7,
    SPELL_LEVEL_8 = 8,
    SPELL_LEVEL_9 = 9,
} SpellLevel;

#define MAX_SPELL_LEVEL 10             /* how many spell levels */
#define MAX_MEM (MAX_SPELL_LEVEL * 10) /* how many total spells */

typedef enum {
    DOMAIN_UNDEFINED    = -1,
    DOMAIN_AIR          = 0,
    DOMAIN_ANIMAL       = 1,
    DOMAIN_CHAOS        = 2,
    DOMAIN_DEATH        = 3,
    DOMAIN_DESTRUCTION  = 4,
    DOMAIN_EARTH        = 5,
    DOMAIN_EVIL         = 6,
    DOMAIN_FIRE         = 7,
    DOMAIN_GOOD         = 8,
    DOMAIN_HEALING      = 9,
    DOMAIN_KNOWLEDGE    = 10,
    DOMAIN_LAW          = 11,
    DOMAIN_LUCK         = 12,
    DOMAIN_MAGIC        = 13,
    DOMAIN_PLANT        = 14,
    DOMAIN_PROTECTION   = 15,
    DOMAIN_STRENGTH     = 16,
    DOMAIN_SUN          = 17,
    DOMAIN_TRAVEL       = 18,
    DOMAIN_TRICKERY     = 19,
    DOMAIN_UNIVERSAL    = 20,
    DOMAIN_WAR          = 22,
    DOMAIN_WATER        = 23,
    DOMAIN_ARTIFACE     = 24,
    DOMAIN_CHARM        = 25,
    DOMAIN_COMMUNITY    = 26,
    DOMAIN_CREATION     = 27,
    DOMAIN_DARKNESS     = 28,
    DOMAIN_GLORY        = 29,
    DOMAIN_LIBERATION   = 30,
    DOMAIN_MADNESS      = 31,
    DOMAIN_NOBILITY     = 32,
    DOMAIN_REPOSE       = 33,
    DOMAIN_RUNE         = 34,
    DOMAIN_SCALYKIND    = 35,
    DOMAIN_WEATHER      = 36,
} MagicDomain;

#define NUM_DOMAINS 37

typedef enum {
    SCHOOL_UNDEFINED     = -1,
    SCHOOL_ABJURATION    = 0,
    SCHOOL_CONJURATION   = 1,
    SCHOOL_DIVINATION    = 2,
    SCHOOL_ENCHANTMENT   = 3,
    SCHOOL_EVOCATION     = 4,
    SCHOOL_ILLUSION      = 5,
    SCHOOL_NECROMANCY    = 6,
    SCHOOL_TRANSMUTATION = 7,
    SCHOOL_UNIVERSAL     = 8,
} MagicSchool;

#define NUM_SCHOOLS 10

#define DEITY_UNDEFINED -1

#define NUM_DEITIES 0

/* Spell feats that apply to a specific school of spells */
#define CFEAT_SPELL_FOCUS 0
#define CFEAT_GREATER_SPELL_FOCUS 1

#define SFEAT_MAX 1

extern const char *spell_schools[NUM_SCHOOLS + 1];

#ifdef __cplusplus
}
#endif
