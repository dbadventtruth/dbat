#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/*
 * ADMLVL_IMPL should always be the HIGHEST possible admin level, and
 * ADMLVL_IMMORT should always be the LOWEST immortal level.
 */
 // ENUM: AdminLevels
typedef enum {
    ADMLVL_NONE   = 0,
    ADMLVL_IMMORT = 1,
    ADMLVL_BUILDER = 2,
    ADMLVL_GOD    = 3,
    ADMLVL_VICE   = 4,
    ADMLVL_GRGOD  = 5,
    ADMLVL_IMPL   = 6,
} AdminLevels;
// End Enum: AdminLevels
extern const char *admin_level_names[ADMLVL_IMPL + 2];

#ifdef __cplusplus
}
#endif
