#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Player flags: used by char_data.act */
typedef enum {
    PLR_KILLER       = 0,  /* Player is a player-killer        */
    PLR_THIEF        = 1,  /* Player is a player-thief         */
    PLR_FROZEN       = 2,  /* Player is frozen                 */
    PLR_DONTSET      = 3,  /* Don't EVER set (ISNPC bit) 	*/
    PLR_WRITING      = 4,  /* Player writing (board/mail/olc)  */
    PLR_MAILING      = 5,  /* Player is writing mail           */
    PLR_CRASH        = 6,  /* Player needs to be crash-saved   */
    PLR_SITEOK       = 7,  /* Player has been site-cleared     */
    PLR_NOSHOUT      = 8,  /* Player not allowed to shout/goss */
    PLR_NOTITLE      = 9,  /* Player not allowed to set title  */
    PLR_DELETED      = 10, /* Player deleted - space reusable  */
    PLR_LOADROOM     = 11, /* Player uses nonstandard loadroom */
    PLR_NOWIZLIST    = 12, /* Player shouldn't be on wizlist  	*/
    PLR_NODELETE     = 13, /* Player shouldn't be deleted     	*/
    PLR_INVSTART     = 14, /* Player should enter game wizinvis*/
    PLR_CRYO         = 15, /* Player is cryo-saved (purge prog)*/
    PLR_NOTDEADYET   = 16, /* (R) Player being extracted.     	*/
    PLR_AGEMID_G     = 17, /* Player has had pos of middle age	*/
    PLR_AGEMID_B     = 18, /* Player has had neg of middle age	*/
    PLR_AGEOLD_G     = 19, /* Player has had pos of old age	*/
    PLR_AGEOLD_B     = 20, /* Player has had neg of old age	*/
    PLR_AGEVEN_G     = 21, /* Player has had pos of venerable age	*/
    PLR_AGEVEN_B     = 22, /* Player has had neg of venerable age	*/
    PLR_OLDAGE       = 23, /* Player is dead of old age	*/
    PLR_RARM         = 24, /* Player has a right arm           */
    PLR_LARM         = 25, /* Player has a left arm            */
    PLR_RLEG         = 26, /* Player has a right leg           */
    PLR_LLEG         = 27, /* Player has a left leg            */
    PLR_HEAD         = 28, /* Player has a head                */
    PLR_STAIL        = 29, /* Player has a saiyan tail         */
    PLR_TAIL         = 30, /* Player has a non-saiyan tail     */
    PLR_PILOTING     = 31, /* Player is sitting in the pilots chair */
    PLR_SKILLP       = 32, /* Player made a good choice in CC  */
    PLR_SPAR         = 33, /* Player is in a spar stance       */
    PLR_CHARGE       = 34, /* Player is charging               */
    PLR_TRANS1       = 35, /* Transformation 1                 */
    PLR_TRANS2       = 36, /* Transformation 2                 */
    PLR_TRANS3       = 37, /* Transformation 3                 */
    PLR_TRANS4       = 38, /* Transformation 4                 */
    PLR_TRANS5       = 39, /* Transformation 5                 */
    PLR_TRANS6       = 40, /* Transformation 6                 */
    PLR_ABSORB       = 41, /* Absorb model                     */
    PLR_REPAIR       = 42, /* Repair model                     */
    PLR_SENSEM       = 43, /* Sense-Powersense model           */
    PLR_POWERUP      = 44, /* Powering Up                      */
    PLR_KNOCKED      = 45, /* Knocked OUT                      */
    PLR_CRARM        = 46, /* Cybernetic Right Arm             */
    PLR_CLARM        = 47, /* Cybernetic Left Arm              */
    PLR_CRLEG        = 48, /* Cybernetic Right Leg             */
    PLR_CLLEG        = 49, /* Cybernetic Left Leg              */
    PLR_FPSSJ        = 50, /* Full Power Super Saiyan          */
    PLR_IMMORTAL     = 51, /* The player is immortal           */
    PLR_EYEC         = 52, /* The player has their eyes closed */
    PLR_DISGUISED    = 53, /* The player is disguised          */
    PLR_BANDAGED     = 54, /* THe player has been bandaged     */
    PLR_PR           = 55, /* Has had their potential released */
    PLR_HEALT        = 56, /* Is inside a healing tank         */
    PLR_FURY         = 57, /* Is in fury mode                  */
    PLR_POSE         = 58, /* Ginyu Pose Effect - NO LONGER USED */
    PLR_OOZARU       = 59,
    PLR_ABSORBED     = 60,
    PLR_MULTP        = 61,
    PLR_PDEATH       = 62,
    PLR_THANDW       = 63,
    PLR_SELFD        = 64,
    PLR_SELFD2       = 65,
    PLR_SPIRAL       = 66,
    PLR_BIOGR        = 67,
    PLR_LSSJ         = 68,
    PLR_REPLEARN     = 69,
    PLR_FORGET       = 70,
    PLR_TRANSMISSION = 71,
    PLR_FISHING      = 72, /* now is a condition */
    PLR_GOOP         = 73,
    PLR_MULTIHIT     = 74,
    PLR_AURALIGHT    = 75,
    PLR_RDISPLAY     = 76,
    PLR_STOLEN       = 77,
    PLR_TAILHIDE     = 78, /* Hides tail for S & HB            */
    PLR_NOGROW       = 79, /* Halt Growth for S & HB           */
} PlayerFlags;

#define NUM_PLR_FLAGS 80

extern const char *player_bits[NUM_PLR_FLAGS + 1];

#ifdef __cplusplus
}
#endif
