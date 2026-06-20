#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Distinguishing Feature */
// ENUM: DistinguishingFeatures
typedef enum {
    DISTFEA_EYE    = 0,
    DISTFEA_HAIR   = 1,
    DISTFEA_SKIN   = 2,
    DISTFEA_HEIGHT = 3,
    DISTFEA_WEIGHT = 4,
} DistinguishingFeatures;
// End Enum: DistinguishingFeatures

/* Custom Aura */
// ENUM: AuraColors
typedef enum {
    AURA_WHITE  = 0,
    AURA_BLUE   = 1,
    AURA_RED    = 2,
    AURA_GREEN  = 3,
    AURA_PINK   = 4,
    AURA_PURPLE = 5,
    AURA_YELLOW = 6,
    AURA_BLACK  = 7,
    AURA_ORANGE = 8,
} AuraColors;
// End Enum: AuraColors

// ENUM: EyeColors
typedef enum {
    EYE_UNDEFINED = -1,
    EYE_BLUE      = 0,
    EYE_BLACK     = 1,
    EYE_GREEN     = 2,
    EYE_BROWN     = 3,
    EYE_RED       = 4,
    EYE_AQUA      = 5,
    EYE_PINK      = 6,
    EYE_PURPLE    = 7,
    EYE_CRIMSON   = 8,
    EYE_GOLD      = 9,
    EYE_AMBER     = 10,
    EYE_EMERALD   = 11,
} EyeColors;
// End Enum: EyeColors

/*Hair Length */
typedef enum {
    HAIRL_UNDEFINED = -1,
    HAIRL_BALD      = 0,
    HAIRL_SHORT     = 1,
    HAIRL_MEDIUM    = 2,
    HAIRL_LONG      = 3,
    HAIRL_RLONG     = 4,
} HairLength;

/*Hair Color */
typedef enum {
    HAIRC_UNDEFINED = -1,
    HAIRC_NONE      = 0,
    HAIRC_BLACK     = 1,
    HAIRC_BROWN     = 2,
    HAIRC_BLONDE    = 3,
    HAIRC_GREY      = 4,
    HAIRC_RED       = 5,
    HAIRC_ORANGE    = 6,
    HAIRC_GREEN     = 7,
    HAIRC_BLUE      = 8,
    HAIRC_PINK      = 9,
    HAIRC_PURPLE    = 10,
    HAIRC_SILVER    = 11,
    HAIRC_CRIMSON   = 12,
    HAIRC_WHITE     = 13,
} HairColor;

/* Hair Style */
typedef enum {
    HAIRS_UNDEFINED = -1,
    HAIRS_NONE      = 0,
    HAIRS_PLAIN     = 1,
    HAIRS_MOHAWK    = 2,
    HAIRS_SPIKY     = 3,
    HAIRS_CURLY     = 4,
    HAIRS_UNEVEN    = 5,
    HAIRS_PONYTAIL  = 6,
    HAIRS_AFRO      = 7,
    HAIRS_FADE      = 8,
    HAIRS_CREW      = 9,
    HAIRS_FEATHERED = 10,
    HAIRS_DRED      = 11,
} HairStyle;

/* Skin Color */
typedef enum {
    SKIN_UNDEFINED = -1,
    SKIN_WHITE     = 0,
    SKIN_BLACK     = 1,
    SKIN_GREEN     = 2,
    SKIN_ORANGE    = 3,
    SKIN_YELLOW    = 4,
    SKIN_RED       = 5,
    SKIN_GREY      = 6,
    SKIN_BLUE      = 7,
    SKIN_AQUA      = 8,
    SKIN_PINK      = 9,
    SKIN_PURPLE    = 10,
    SKIN_TAN       = 11,
} SkinColor;

/* Annual Sign Phase */
typedef enum {
    PHASE_PURITY    = 0,
    PHASE_BRAVERY   = 1,
    PHASE_HATRED    = 2,
    PHASE_DOMINANCE = 3,
    PHASE_GUARDIAN  = 4,
    PHASE_LOVE      = 5,
    PHASE_STRENGTH  = 6,
} AnnualPhase;

extern const char *hairl_types[];
extern const char *eye_types[];
extern const char *FHA_types[];
extern const char *hairc_types[];
extern const char *hairs_types[];
extern const char *skin_types[];
extern const char *aura_types[];

#ifdef __cplusplus
}
#endif
