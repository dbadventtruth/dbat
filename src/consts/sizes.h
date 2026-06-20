#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Taken from the SRD under OGL, see ../doc/srd.txt for information */
typedef enum {
    SIZE_UNDEFINED  = -1,
    SIZE_FINE       = 0,
    SIZE_DIMINUTIVE = 1,
    SIZE_TINY       = 2,
    SIZE_SMALL      = 3,
    SIZE_MEDIUM     = 4,
    SIZE_LARGE      = 5,
    SIZE_HUGE       = 6,
    SIZE_GARGANTUAN = 7,
    SIZE_COLOSSAL   = 8,
} Size;

#define NUM_SIZES 9

extern const char *size_names[NUM_SIZES + 1];

#ifdef __cplusplus
}
#endif
