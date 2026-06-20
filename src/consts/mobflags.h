#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Mobile flags: used by char_data.act */
typedef enum {
    MOB_SPEC        = 0,  /* Mob has a callable spec-proc   	*/
    MOB_SENTINEL    = 1,  /* Mob should not move            	*/
    MOB_NOSCAVENGER = 2,  /* Mob won't pick up items from rooms*/
    MOB_ISNPC       = 3,  /* (R) Automatically set on all Mobs */
    MOB_AWARE       = 4,  /* Mob can't be backstabbed          */
    MOB_AGGRESSIVE  = 5,  /* Mob auto-attacks everybody nearby	*/
    MOB_STAY_ZONE   = 6,  /* Mob shouldn't wander out of zone  */
    MOB_WIMPY       = 7,  /* Mob flees if severely injured  	*/
    MOB_AGGR_EVIL   = 8,  /* Auto-attack any evil PC's		*/
    MOB_AGGR_GOOD   = 9,  /* Auto-attack any good PC's      	*/
    MOB_AGGR_NEUTRAL = 10, /* Auto-attack any neutral PC's   	*/
    MOB_MEMORY      = 11, /* remember attackers if attacked    */
    MOB_HELPER      = 12, /* attack PCs fighting other NPCs    */
    MOB_NOCHARM     = 13, /* Mob can't be charmed         	*/
    MOB_NOSUMMON    = 14, /* Mob can't be summoned             */
    MOB_NOSLEEP     = 15, /* Mob can't be slept           	*/
    MOB_AUTOBALANCE = 16, /* Mob stats autobalance		*/
    MOB_NOBLIND     = 17, /* Mob can't be blinded         	*/
    MOB_NOKILL      = 18, /* Mob can't be killed               */
    MOB_NOTDEADYET  = 19, /* (R) Mob being extracted.          */
    MOB_MOUNTABLE   = 20, /* Mob is mountable.			*/
    MOB_RARM        = 21, /* Player has a right arm            */
    MOB_LARM        = 22, /* Player has a left arm             */
    MOB_RLEG        = 23, /* Player has a right leg            */
    MOB_LLEG        = 24, /* Player has a left leg             */
    MOB_HEAD        = 25, /* Player has a head                 */
    MOB_JUSTDESC    = 26, /* Mob doesn't use auto desc         */
    MOB_HUSK        = 27, /* Is an extracted Husk              */
    MOB_SPAR        = 28, /* This is mob sparring              */
    MOB_DUMMY       = 29, /* This mob will not fight back      */
    MOB_ABSORB      = 30, /* Absorb type android               */
    MOB_REPAIR      = 31, /* Repair type android               */
    MOB_NOPOISON    = 32, /* No poison                         */
    MOB_KNOWKAIO    = 33, /* Knows kaioken                     */
    MOB_POWERUP     = 34, /* Is powering up                    */
} MobFlags;

#define NUM_MOB_FLAGS 35

extern const char *action_bits[NUM_MOB_FLAGS + 1];

#ifdef __cplusplus
}
#endif
