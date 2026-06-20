#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Positions */
typedef enum {
    POS_DEAD      = 0, /* dead			*/
    POS_MORTALLYW = 1, /* mortally wounded	*/
    POS_INCAP     = 2, /* incapacitated	*/
    POS_STUNNED   = 3, /* stunned		*/
    POS_SLEEPING  = 4, /* sleeping		*/
    POS_RESTING   = 5, /* resting		*/
    POS_SITTING   = 6, /* sitting		*/
    POS_FIGHTING  = 7, /* fighting		*/
    POS_STANDING  = 8, /* standing		*/
} Position;

#define NUM_POSITIONS 9

extern const char *position_types[NUM_POSITIONS + 1];

#ifdef __cplusplus
}
#endif
