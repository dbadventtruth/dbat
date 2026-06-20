#pragma once

#ifdef __cplusplus
extern "C" {
#endif

// ENUM: Alignments
typedef enum {
    ALIGN_SAINT    = 0,
    ALIGN_VALIANT  = 1,
    ALIGN_HERO     = 2,
    ALIGN_DOGOOD   = 3,
    ALIGN_NEUTRAL  = 4,
    ALIGN_CROOK    = 5,
    ALIGN_VILLAIN  = 6,
    ALIGN_TERRIBLE = 7,
    ALIGN_HORRIBLE = 8,
} Alignments;
// End Enum: Alignments

#define NUM_ALIGNS 9

extern const char *alignments[NUM_ALIGNS + 1];

#ifdef __cplusplus
}
#endif
