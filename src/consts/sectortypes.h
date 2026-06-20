#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Sector types: used in room_data.sector_type */
typedef enum {
    SECT_INSIDE       = 0,  /* Indoors			*/
    SECT_CITY         = 1,  /* In a city			*/
    SECT_FIELD        = 2,  /* In a field		*/
    SECT_FOREST       = 3,  /* In a forest		*/
    SECT_HILLS        = 4,  /* In the hills		*/
    SECT_MOUNTAIN     = 5,  /* On a mountain		*/
    SECT_WATER_SWIM   = 6,  /* Swimmable water		*/
    SECT_WATER_NOSWIM = 7,  /* Water - need a boat	*/
    SECT_FLYING       = 8,  /* Wheee!			*/
    SECT_UNDERWATER   = 9,  /* Underwater		*/
    SECT_SHOP         = 10, /* Shop                      */
    SECT_IMPORTANT    = 11, /* Important Rooms           */
    SECT_DESERT       = 12, /* A desert                  */
    SECT_SPACE        = 13, /* This is a space room      */
    SECT_LAVA         = 14, /* This room always has lava */
} SectorType;

#define NUM_ROOM_SECTORS 15

extern const char *sector_types[NUM_ROOM_SECTORS + 1];

extern int movement_loss[NUM_ROOM_SECTORS];

#ifdef __cplusplus
}
#endif
