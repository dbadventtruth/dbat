#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Taken from the SRD under OGL, see ../doc/srd.txt for information */
typedef enum {
    CLASS_UNDEFINED         = -1,
    CLASS_ROSHI             = 0,
    CLASS_PICCOLO           = 1,
    CLASS_KRANE             = 2,
    CLASS_NAIL              = 3,
    CLASS_BARDOCK           = 4,
    CLASS_GINYU             = 5,
    CLASS_FRIEZA            = 6,
    CLASS_TAPION            = 7,
    CLASS_ANDSIX            = 8,
    CLASS_DABURA            = 9,
    CLASS_KABITO            = 10,
    CLASS_JINTO             = 11,
    CLASS_TSUNA             = 12,
    CLASS_KURZAK            = 13,
    CLASS_ASSASSIN          = 14,
    CLASS_BLACKGUARD        = 15,
    CLASS_DRAGON_DISCIPLE   = 16,
    CLASS_DUELIST           = 17,
    CLASS_DWARVEN_DEFENDER  = 18,
    CLASS_ELDRITCH_KNIGHT   = 19,
    CLASS_HIEROPHANT        = 20,
    CLASS_HORIZON_WALKER    = 21,
    CLASS_LOREMASTER        = 22,
    CLASS_MYSTIC_THEURGE    = 23,
    CLASS_SHADOWDANCER      = 24,
    CLASS_THAUMATURGIST     = 25,
    CLASS_NPC_EXPERT        = 26,
    CLASS_NPC_ADEPT         = 27,
    CLASS_NPC_COMMONER      = 28,
    CLASS_NPC_ARISTOCRAT    = 29,
    CLASS_NPC_WARRIOR       = 30,
} ClassType;

#define MAX_SENSEI 15 /* Used by Sensei Style */
#define NUM_CLASSES 31
#define NUM_NPC_CLASSES 4
#define NUM_PRESTIGE_CLASSES 15
#define NUM_BASIC_CLASSES (14)

/* Taken from the SRD under OGL, see ../doc/srd.txt for information */
typedef enum {
    SENSEI_UNDEFINED        = -1,
    SENSEI_ROSHI            = 0,
    SENSEI_PICCOLO          = 1,
    SENSEI_KRANE            = 2,
    SENSEI_NAIL             = 3,
    SENSEI_BARDOCK          = 4,
    SENSEI_GINYU            = 5,
    SENSEI_FRIEZA           = 6,
    SENSEI_TAPION           = 7,
    SENSEI_ANDSIX           = 8,
    SENSEI_DABURA           = 9,
    SENSEI_KABITO           = 10,
    SENSEI_JINTO            = 11,
    SENSEI_TSUNA            = 12,
    SENSEI_KURZAK           = 13,
    SENSEI_ASSASSIN         = 14,
    SENSEI_BLACKGUARD       = 15,
    SENSEI_DRAGON_DISCIPLE  = 16,
    SENSEI_DUELIST          = 17,
    SENSEI_DWARVEN_DEFENDER = 18,
    SENSEI_ELDRITCH_KNIGHT  = 19,
    SENSEI_HIEROPHANT       = 20,
    SENSEI_HORIZON_WALKER   = 21,
    SENSEI_LOREMASTER       = 22,
    SENSEI_MYSTIC_THEURGE   = 23,
    SENSEI_SHADOWDANCER     = 24,
    SENSEI_THAUMATURGIST    = 25,
    SENSEI_NPC_EXPERT       = 26,
    SENSEI_NPC_ADEPT        = 27,
    SENSEI_NPC_COMMONER     = 28,
    SENSEI_NPC_ARISTOCRAT   = 29,
    SENSEI_NPC_WARRIOR      = 30,
} SenseiType;

extern const char *sensei_style[MAX_SENSEI];

extern const char *pc_class_types[NUM_CLASSES + 1];
extern const char *class_names[NUM_CLASSES + 1];
extern const char *class_abbrevs[NUM_CLASSES + 1];

#ifdef __cplusplus
}
#endif
