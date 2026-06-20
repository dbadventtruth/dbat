#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Room flags: used in room_data.room_flags */
/* WARNING: In the world files, NEVER set the bits marked "R" ("Reserved") */
typedef enum {
    ROOM_DARK        = 0,  /* Dark			*/
    ROOM_DEATH       = 1,  /* Death trap		*/
    ROOM_NOMOB       = 2,  /* MOBs not allowed		*/
    ROOM_INDOORS     = 3,  /* Indoors			*/
    ROOM_PEACEFUL    = 4,  /* Violence not allowed	*/
    ROOM_SOUNDPROOF  = 5,  /* Shouts, gossip blocked	*/
    ROOM_NOTRACK     = 6,  /* Track won't go through	*/
    ROOM_NOINSTANT   = 7,  /* IT not allowed		*/
    ROOM_TUNNEL      = 8,  /* room for only 1 pers	*/
    ROOM_PRIVATE     = 9,  /* Can't teleport in		*/
    ROOM_GODROOM     = 10, /* LVL_GOD+ only allowed	*/
    ROOM_HOUSE       = 11, /* (R) Room is a house	*/
    ROOM_HOUSE_CRASH = 12, /* (R) House needs saving	*/
    ROOM_ATRIUM      = 13, /* (R) The door to a house	*/
    ROOM_OLC         = 14, /* (R) Modifyable/!compress	*/
    ROOM_BFS_MARK    = 15, /* (R) breath-first srch mrk	*/
    ROOM_VEHICLE     = 16, /* Requires a vehicle to pass       */
    ROOM_UNDERGROUND = 17, /* Room is below ground      */
    ROOM_CURRENT     = 18, /* Room move with random currents	*/
    ROOM_TIMED_DT    = 19, /* Room has a timed death trap  	*/
    ROOM_EARTH       = 20, /* Room is on Earth */
    ROOM_VEGETA      = 21, /* Room is on Vegeta */
    ROOM_FRIGID      = 22, /* Room is on Frigid */
    ROOM_KONACK      = 23, /* Room is on Konack */
    ROOM_NAMEK       = 24, /* Room is on Namek */
    ROOM_NEO         = 25, /* Room is on Neo */
    ROOM_AL          = 26, /* Room is on AL */
    ROOM_SPACE       = 27, /* Room is on Space */
    ROOM_HELL        = 28, /* Room is Punishment Hell*/
    ROOM_REGEN       = 29, /* Better regen */
    ROOM_RHELL       = 30, /* Room is HELLLLLLL */
    ROOM_GRAVITYX10  = 31, /* For rooms that have 10x grav */
    ROOM_AETHER      = 32, /* Room is on Aether */
    ROOM_HBTC        = 33, /* Room is extra special training area */
    ROOM_PAST        = 34, /* Inside the pendulum room */
    ROOM_CBANK       = 35, /* This room is a clan bank */
    ROOM_SHIP        = 36, /* This room is a private ship room */
    ROOM_YARDRAT     = 37, /* This room is on planet Yardrat   */
    ROOM_KANASSA     = 38, /* This room is on planet Kanassa   */
    ROOM_ARLIA       = 39, /* This room is on planet Arlia     */
    ROOM_AURA        = 40, /* This room has an aura around it  */
    ROOM_EORBIT      = 41, /* Earth Orbit                      */
    ROOM_FORBIT      = 42, /* Frigid Orbit                     */
    ROOM_KORBIT      = 43, /* Konack Orbit                     */
    ROOM_NORBIT      = 44, /* Namek  Orbit                     */
    ROOM_VORBIT      = 45, /* Vegeta Orbit                     */
    ROOM_AORBIT      = 46, /* Aether Orbit                     */
    ROOM_YORBIT      = 47, /* Yardrat Orbit                    */
    ROOM_KANORB      = 48, /* Kanassa Orbit                    */
    ROOM_ARLORB      = 49, /* Arlia Orbit                      */
    ROOM_NEBULA      = 50, /* Nebulae                          */
    ROOM_ASTERO      = 51, /* Asteroid                         */
    ROOM_WORMHO      = 52, /* Wormhole                         */
    ROOM_STATION     = 53, /* Space Station                    */
    ROOM_STAR        = 54, /* Is a star                        */
    ROOM_CERRIA      = 55, /* This room is on planet Cerria    */
    ROOM_CORBIT      = 56, /* This room is in Cerria's Orbit   */
    ROOM_BEDROOM     = 57, /* +25% regen                       */
    ROOM_WORKOUT     = 58, /* Workout Room                     */
    ROOM_GARDEN1     = 59, /* 8 plant garden                   */
    ROOM_GARDEN2     = 60, /* 20 plant garden                  */
    ROOM_FERTILE1    = 61,
    ROOM_FERTILE2    = 62,
    ROOM_FISHING     = 63,
    ROOM_FISHFRESH   = 64,
    ROOM_CANREMODEL  = 65,
} RoomFlags;

#define NUM_ROOM_FLAGS 66
#define RF_ARRAY_MAX 4

extern const char *room_bits[NUM_ROOM_FLAGS + 1];

#ifdef __cplusplus
}
#endif
