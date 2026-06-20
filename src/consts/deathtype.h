#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Death Types for producing corpses with depth */
typedef enum {
    DTYPE_NORMAL = 0, /* Default Death Type */
    DTYPE_HEAD   = 1, /* Lost their head    */
    DTYPE_HALF   = 2, /* Blown in half      */
    DTYPE_VAPOR  = 3, /* Vaporized by attack*/
    DTYPE_PULP   = 4, /* Beat to a pulp     */
} DmgDeathType;

#ifdef __cplusplus
}
#endif
