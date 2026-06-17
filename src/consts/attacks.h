#pragma once

#ifdef __cplusplus
extern "C" {
#endif

extern const char *attack_names_comp[];
extern const char *attack_names[];
extern const int attack_skills[];

typedef enum {
    TYPE_HIT      = 300,
    TYPE_STING    = 301,
    TYPE_WHIP     = 302,
    TYPE_SLASH    = 303,
    TYPE_BITE     = 304,
    TYPE_BLUDGEON = 305,
    TYPE_CRUSH    = 306,
    TYPE_POUND    = 307,
    TYPE_CLAW     = 308,
    TYPE_MAUL     = 309,
    TYPE_THRASH   = 310,
    TYPE_PIERCE   = 311,
    TYPE_BLAST    = 312,
    TYPE_PUNCH    = 313,
    TYPE_STAB     = 314,
    /* new attack types can be added here - up to TYPE_SUFFERING */
    TYPE_SUFFERING = 399,
} AttackType;

#ifdef __cplusplus
}
#endif
