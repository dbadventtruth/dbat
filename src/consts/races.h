#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Races */
typedef enum {
    RACE_UNDEFINED = -1,
    RACE_HUMAN     = 0,
    RACE_SAIYAN    = 1,
    RACE_ICER      = 2,
    RACE_KONATSU   = 3,
    RACE_NAMEK     = 4,
    RACE_MUTANT    = 5,
    RACE_KANASSAN  = 6,
    RACE_HALFBREED = 7,
    RACE_BIO       = 8,
    RACE_ANDROID   = 9,
    RACE_DEMON     = 10,
    RACE_MAJIN     = 11,
    RACE_KAI       = 12,
    RACE_TRUFFLE   = 13,
    RACE_HOSHIJIN  = 14,
    RACE_ANIMAL    = 15,
    RACE_SAIBA     = 16,
    RACE_SERPENT   = 17,
    RACE_OGRE      = 18,
    RACE_YARDRATIAN = 19,
    RACE_ARLIAN    = 20,
    RACE_DRAGON    = 21,
    RACE_MECHANICAL = 22,
    RACE_SPIRIT    = 23,
} Race;

#define NUM_RACES 24

struct aging_data {
  int adult;           /* Adulthood */
  int classdice[3][2]; /* Dice info for starting age based on class age type */
  int middle;          /* Middle age */
  int old;             /* Old age */
  int venerable;       /* Venerable age */
  int maxdice[2]; /* For roll to determine natural death beyond venerable */
};

extern const struct aging_data racial_aging_data[NUM_RACES];

extern const char *d_race_types[NUM_RACES + 1];
extern const char *race_names[NUM_RACES + 1];
extern const char *pc_race_types[NUM_RACES + 1];
extern const int race_def_sizetable[NUM_RACES + 1];
extern const char *race_abbrevs[NUM_RACES + 1];

#ifdef __cplusplus
}
#endif
