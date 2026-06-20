#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Let's define bonuses/negatives */
typedef enum {
    BONUS_THRIFTY      = 0,
    BONUS_PRODIGY      = 1,
    BONUS_QUICK_STUDY  = 2,
    BONUS_DIEHARD      = 3,
    BONUS_BRAWLER      = 4,
    BONUS_DESTROYER    = 5,
    BONUS_HARDWORKER   = 6,
    BONUS_HEALER       = 7,
    BONUS_LOYAL        = 8,
    BONUS_BRAWNY       = 9,
    BONUS_SCHOLARLY    = 10,
    BONUS_SAGE         = 11,
    BONUS_AGILE        = 12,
    BONUS_QUICK        = 13,
    BONUS_STURDY       = 14,
    BONUS_THICKSKIN    = 15,
    BONUS_RECIPE       = 16,
    BONUS_FIREPROOF    = 17,
    BONUS_POWERHIT     = 18,
    BONUS_HEALTHY      = 19,
    BONUS_INSOMNIAC    = 20,
    BONUS_EVASIVE      = 21,
    BONUS_WALL         = 22,
    BONUS_ACCURATE     = 23,
    BONUS_LEECH        = 24,
    BONUS_GMEMORY      = 25,
    BONUS_SOFT         = 26,
    BONUS_LATE         = 27,
    BONUS_IMPULSE      = 28,
    BONUS_SICKLY       = 29,
    BONUS_PUNCHINGBAG  = 30,
    BONUS_PUSHOVER     = 31,
    BONUS_POORDEPTH    = 32,
    BONUS_THINSKIN     = 33,
    BONUS_FIREPRONE    = 34,
    BONUS_INTOLERANT   = 35,
    BONUS_COWARD       = 36,
    BONUS_ARROGANT     = 37,
    BONUS_UNFOCUSED    = 38,
    BONUS_SLACKER      = 39,
    BONUS_SLOW_LEARNER = 40,
    BONUS_MASOCHISTIC  = 41,
    BONUS_MUTE         = 42,
    BONUS_WIMP         = 43,
    BONUS_DULL         = 44,
    BONUS_FOOLISH      = 45,
    BONUS_CLUMSY       = 46,
    BONUS_SLOW         = 47,
    BONUS_FRAIL        = 48,
    BONUS_SADISTIC     = 49,
    BONUS_LONER        = 50,
    BONUS_BMEMORY      = 51,
} BonusType;

#define MAX_BONUSES 52

#ifdef __cplusplus
}
#endif
