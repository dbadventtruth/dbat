#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/*
 * ADM flags - define admin privs for chars
 */
// ENUM: AdminFlags
typedef enum {
    ADM_TELLALL      = 0,  /* Can use 'tell all' to broadcast GOD */
    ADM_SEEINV       = 1,  /* Sees other chars inventory IMM */
    ADM_SEESECRET    = 2,  /* Sees secret doors IMM */
    ADM_KNOWWEATHER  = 3,  /* Knows details of weather GOD */
    ADM_FULLWHERE    = 4,  /* Full output of 'where' command IMM */
    ADM_MONEY        = 5,  /* Char has a bottomless wallet GOD */
    ADM_EATANYTHING  = 6,  /* Char can eat anything GOD */
    ADM_NOPOISON     = 7,  /* Char can't be poisoned IMM */
    ADM_WALKANYWHERE = 8,  /* Char has unrestricted walking IMM */
    ADM_NOKEYS       = 9,  /* Char needs no keys for locks GOD */
    ADM_INSTANTKILL  = 10, /* "kill" command is instant IMPL */
    ADM_NOSTEAL      = 11, /* Char cannot be stolen from IMM */
    ADM_TRANSALL     = 12, /* Can use 'trans all' GRGOD */
    ADM_SWITCHMORTAL = 13, /* Can 'switch' to a mortal PC body IMPL */
    ADM_FORCEMASS    = 14, /* Can force rooms or all GRGOD */
    ADM_ALLHOUSES    = 15, /* Can enter any house GRGOD */
    ADM_NODAMAGE     = 16, /* Cannot be damaged IMM */
    ADM_ALLSHOPS     = 17, /* Can use all shops GOD */
    ADM_CEDIT        = 18, /* Can use cedit IMPL */
} AdminFlags;
// End Enum: AdminFlags

#define NUM_ADMFLAGS 19
#define AD_ARRAY_MAX 4
extern const char *admin_flags[NUM_ADMFLAGS + 1];

#ifdef __cplusplus
}
#endif
