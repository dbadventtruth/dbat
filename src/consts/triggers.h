#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* MOB_TRIGGER/OBJ_TRIGGER/WLD_TRIGGER are also defined in dgscript_impl.h */
#ifndef MOB_TRIGGER
#define MOB_TRIGGER 0
#define OBJ_TRIGGER 1
#define WLD_TRIGGER 2
#endif

/* mob trigger types */
typedef enum {
    MTRIG_GLOBAL    = (1 << 0),  /* check even if zone empty   */
    MTRIG_RANDOM    = (1 << 1),  /* checked randomly           */
    MTRIG_COMMAND   = (1 << 2),  /* character types a command  */
    MTRIG_SPEECH    = (1 << 3),  /* a char says a word/phrase  */
    MTRIG_ACT       = (1 << 4),  /* word or phrase sent to act */
    MTRIG_DEATH     = (1 << 5),  /* character dies             */
    MTRIG_GREET     = (1 << 6),  /* something enters room seen */
    MTRIG_GREET_ALL = (1 << 7),  /* anything enters room       */
    MTRIG_ENTRY     = (1 << 8),  /* the mob enters a room      */
    MTRIG_RECEIVE   = (1 << 9),  /* character is given obj     */
    MTRIG_FIGHT     = (1 << 10), /* each pulse while fighting  */
    MTRIG_HITPRCNT  = (1 << 11), /* fighting and below some hp */
    MTRIG_BRIBE     = (1 << 12), /* coins are given to mob     */
    MTRIG_LOAD      = (1 << 13), /* the mob is loaded          */
    MTRIG_MEMORY    = (1 << 14), /* mob see's someone remembered */
    MTRIG_CAST      = (1 << 15), /* mob targetted by spell     */
    MTRIG_LEAVE     = (1 << 16), /* someone leaves room seen   */
    MTRIG_DOOR      = (1 << 17), /* door manipulated in room   */
    MTRIG_TIME      = (1 << 19), /* trigger based on game hour */
} MobTrigType;

/* obj trigger types */
typedef enum {
    OTRIG_GLOBAL  = (1 << 0),  /* unused                     */
    OTRIG_RANDOM  = (1 << 1),  /* checked randomly           */
    OTRIG_COMMAND = (1 << 2),  /* character types a command  */
    OTRIG_TIMER   = (1 << 5),  /* item's timer expires       */
    OTRIG_GET     = (1 << 6),  /* item is picked up          */
    OTRIG_DROP    = (1 << 7),  /* character trys to drop obj */
    OTRIG_GIVE    = (1 << 8),  /* character trys to give obj */
    OTRIG_WEAR    = (1 << 9),  /* character trys to wear obj */
    OTRIG_REMOVE  = (1 << 11), /* character trys to remove obj */
    OTRIG_LOAD    = (1 << 13), /* the object is loaded        */
    OTRIG_CAST    = (1 << 15), /* object targetted by spell   */
    OTRIG_LEAVE   = (1 << 16), /* someone leaves room seen    */
    OTRIG_CONSUME = (1 << 18), /* char tries to eat/drink obj */
    OTRIG_TIME    = (1 << 19), /* trigger based on game hour */
} ObjTrigType;

/* wld trigger types */
typedef enum {
    WTRIG_GLOBAL  = (1 << 0),  /* check even if zone empty   */
    WTRIG_RANDOM  = (1 << 1),  /* checked randomly           */
    WTRIG_COMMAND = (1 << 2),  /* character types a command  */
    WTRIG_SPEECH  = (1 << 3),  /* a char says word/phrase    */
    WTRIG_RESET   = (1 << 5),  /* zone has been reset        */
    WTRIG_ENTER   = (1 << 6),  /* character enters room      */
    WTRIG_DROP    = (1 << 7),  /* something dropped in room  */
    WTRIG_CAST    = (1 << 15), /* spell cast in room */
    WTRIG_LEAVE   = (1 << 16), /* character leaves the room */
    WTRIG_DOOR    = (1 << 17), /* door manipulated in room  */
    WTRIG_TIME    = (1 << 19), /* trigger based on game hour */
} WldTrigType;

/* obj command trigger types */
typedef enum {
    OCMD_EQUIP = (1 << 0), /* obj must be in char's equip */
    OCMD_INVEN = (1 << 1), /* obj must be in char's inven */
    OCMD_ROOM  = (1 << 2), /* obj must be in char's room  */
} ObjCmdType;

/* obj consume trigger commands */
typedef enum {
    OCMD_EAT   = 1,
    OCMD_DRINK = 2,
    OCMD_QUAFF = 3,
} ObjCmdConsumeType;

typedef enum {
    TRIG_NEW     = 0, /* trigger starts from top  */
    TRIG_RESTART = 1, /* trigger restarting       */
} TrigState;

#define NUM_MTRIG_TYPES 20
#define NUM_OTRIG_TYPES 20
#define NUM_WTRIG_TYPES 20

extern const char *trig_types[NUM_MTRIG_TYPES + 1];
extern const char *otrig_types[NUM_OTRIG_TYPES + 1];
extern const char *wtrig_types[NUM_WTRIG_TYPES + 1];

#define MOB_ID_BASE 50000    /* 50000 player IDNUMS should suffice */
#define ROOM_ID_BASE 1050000 /* 1000000 Mobs */
#define OBJ_ID_BASE 1300000  /* 250000 Rooms */

#ifdef __cplusplus
}
#endif
