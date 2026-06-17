#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Some different kind of liquids for use in values of drink containers */
typedef enum {
    LIQ_WATER      = 0,
    LIQ_BEER       = 1,
    LIQ_WINE       = 2,
    LIQ_ALE        = 3,
    LIQ_DARKALE    = 4,
    LIQ_WHISKY     = 5,
    LIQ_LEMONADE   = 6,
    LIQ_FIREBRT    = 7,
    LIQ_LOCALSPC   = 8,
    LIQ_SLIME      = 9,
    LIQ_MILK       = 10,
    LIQ_TEA        = 11,
    LIQ_COFFE      = 12,
    LIQ_BLOOD      = 13,
    LIQ_SALTWATER  = 14,
    LIQ_CLEARWATER = 15,
} LiquidType;

#define NUM_LIQ_TYPES 16

typedef enum {
    MATERIAL_BONE       = 0,
    MATERIAL_CERAMIC    = 1,
    MATERIAL_COPPER     = 2,
    MATERIAL_DIAMOND    = 3,
    MATERIAL_GOLD       = 4,
    MATERIAL_IRON       = 5,
    MATERIAL_LEATHER    = 6,
    MATERIAL_MITHRIL    = 7,
    MATERIAL_OBSIDIAN   = 8,
    MATERIAL_STEEL      = 9,
    MATERIAL_STONE      = 10,
    MATERIAL_SILVER     = 11,
    MATERIAL_WOOD       = 12,
    MATERIAL_GLASS      = 13,
    MATERIAL_ORGANIC    = 14,
    MATERIAL_CURRENCY   = 15,
    MATERIAL_PAPER      = 16,
    MATERIAL_COTTON     = 17,
    MATERIAL_SATIN      = 18,
    MATERIAL_SILK       = 19,
    MATERIAL_BURLAP     = 20,
    MATERIAL_VELVET     = 21,
    MATERIAL_PLATINUM   = 22,
    MATERIAL_ADAMANTINE = 23,
    MATERIAL_WOOL       = 24,
    MATERIAL_ONYX       = 25,
    MATERIAL_IVORY      = 26,
    MATERIAL_BRASS      = 27,
    MATERIAL_MARBLE     = 28,
    MATERIAL_BRONZE     = 29,
    MATERIAL_KACHIN     = 30,
    MATERIAL_RUBY       = 31,
    MATERIAL_SAPPHIRE   = 32,
    MATERIAL_EMERALD    = 33,
    MATERIAL_GEMSTONE   = 34,
    MATERIAL_GRANITE    = 35,
    MATERIAL_ENERGY     = 36,
    MATERIAL_HEMP       = 37,
    MATERIAL_CRYSTAL    = 38,
    MATERIAL_EARTH      = 39,
    MATERIAL_LIQUID     = 40,
    MATERIAL_CLOTH      = 41,
    MATERIAL_METAL      = 42,
    MATERIAL_WAX        = 43,
    MATERIAL_OTHER      = 44,
    MATERIAL_FOOD       = 45,
    MATERIAL_OIL        = 46,
} Material;

#define NUM_MATERIALS 47

#ifdef __cplusplus
}
#endif
