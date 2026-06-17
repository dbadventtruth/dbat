#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Character Creation Styles */
typedef enum {
    WIELD_NONE    = 0,
    WIELD_LIGHT   = 1,
    WIELD_ONEHAND = 2,
    WIELD_TWOHAND = 3,
} WieldType;

/* Number of weapon types */
#define MAX_WEAPON_TYPES 26

/* Critical hit types */
typedef enum {
    CRIT_X2 = 0,
    CRIT_X3 = 1,
    CRIT_X4 = 2,
} CritType;

#define MAX_CRIT_TYPE CRIT_X4
#define NUM_CRIT_TYPES 3

#define MAX_ARMOR_TYPES 5
#define NUM_WIELD_NAMES 4

extern const char *weapon_type[MAX_WEAPON_TYPES + 2];
extern const char *armor_type[MAX_ARMOR_TYPES + 1];
extern const char *wield_names[NUM_WIELD_NAMES + 1];
extern const char *crit_type[NUM_CRIT_TYPES + 1];

#ifdef __cplusplus
}
#endif
