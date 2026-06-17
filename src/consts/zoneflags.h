#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Zone info: Used in zone_data.zone_flags */
typedef enum {
    ZONE_CLOSED  = 0,
    ZONE_NOIMMORT = 1,
    ZONE_QUEST   = 2,
    ZONE_DBALLS  = 3,
    ZONE_SPARE2  = 4,
    ZONE_SPARE3  = 5,
    ZONE_SPARE4  = 6,
    ZONE_SPARE5  = 7,
    ZONE_SPARE6  = 8,
    ZONE_SPARE7  = 9,
    ZONE_SPARE8  = 10,
    ZONE_SPARE9  = 11,
    ZONE_SPARE10 = 12,
    ZONE_SPARE11 = 13,
    ZONE_SPARE12 = 14,
    ZONE_SPARE13 = 15,
    ZONE_SPARE14 = 16,
    ZONE_SPARE15 = 17,
    ZONE_SPARE16 = 18,
    ZONE_SPARE17 = 19,
    ZONE_SPARE18 = 20,
    ZONE_SPARE19 = 21,
    ZONE_SPARE20 = 22,
    ZONE_SPARE21 = 23,
    ZONE_SPARE22 = 24,
    ZONE_SPARE23 = 25,
    ZONE_SPARE24 = 26,
    ZONE_SPARE25 = 27,
    ZONE_SPARE26 = 28,
    ZONE_SPARE27 = 29,
    ZONE_SPARE28 = 30,
    ZONE_SPARE29 = 31,
    ZONE_SPARE30 = 32,
    ZONE_SPARE31 = 33,
    ZONE_SPARE32 = 34,
    ZONE_SPARE33 = 35,
} ZoneFlags;

#define NUM_ZONE_FLAGS 36
#define ZF_ARRAY_MAX 4

extern const char *zone_bits[NUM_ZONE_FLAGS + 1];

#ifdef __cplusplus
}
#endif
