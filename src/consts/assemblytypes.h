#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Assembly type: Used in ASSEMBLY.iAssemblyType */
typedef enum {
    ASSM_MAKE     = 0,  // Assembly must be made.
    ASSM_BAKE     = 1,  // Assembly must be baked.
    ASSM_BREW     = 2,  // Assembly must be brewed.
    ASSM_ASSEMBLE = 3,  // Assembly must be assembled.
    ASSM_CRAFT    = 4,  // Assembly must be crafted.
    ASSM_FLETCH   = 5,  // Assembly must be fletched.
    ASSM_KNIT     = 6,  // Assembly must be knitted.
    ASSM_MIX      = 7,  // Assembly must be mixed.
    ASSM_THATCH   = 8,  // Assembly must be thatched.
    ASSM_WEAVE    = 9,  // Assembly must be woven.
    ASSM_FORGE    = 10, // Assembly must be forged.
} AssemblyType;

#define MAX_ASSM 11

extern const char *AssemblyTypes[MAX_ASSM + 1];

#ifdef __cplusplus
}
#endif
