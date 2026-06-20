#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Sex */
typedef enum {
    SEX_NEUTRAL = 0,
    SEX_MALE    = 1,
    SEX_FEMALE  = 2,
} Sex;

#define NUM_SEX 3

extern const char *genders[NUM_SEX + 1];

#ifdef __cplusplus
}
#endif
