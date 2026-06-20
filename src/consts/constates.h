#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Modes of connectedness: used by descriptor_data.state */
typedef enum {
    CON_PLAYING      = 0,  /* Playing - Nominal state		*/
    CON_CLOSE        = 1,  /* User disconnect, remove character.	*/
    CON_GET_NAME     = 2,  /* By what name ..?			*/
    CON_NAME_CNFRM   = 3,  /* Did I get that right, x?		*/
    CON_PASSWORD     = 4,  /* Password:				*/
    CON_NEWPASSWD    = 5,  /* Give me a password for x		*/
    CON_CNFPASSWD    = 6,  /* Please retype password:		*/
    CON_QSEX         = 7,  /* Sex?					*/
    CON_QCLASS       = 8,  /* Class?				*/
    CON_RMOTD        = 9,  /* PRESS RETURN after MOTD		*/
    CON_MENU         = 10, /* Your choice: (main menu)		*/
    CON_EXDESC       = 11, /* Enter a new description:		*/
    CON_CHPWD_GETOLD = 12, /* Changing passwd: get old		*/
    CON_CHPWD_GETNEW = 13, /* Changing passwd: get new		*/
    CON_CHPWD_VRFY   = 14, /* Verify new password			*/
    CON_DELCNF1      = 15, /* Delete confirmation 1		*/
    CON_DELCNF2      = 16, /* Delete confirmation 2		*/
    CON_DISCONNECT   = 17, /* In-game link loss (leave character)	*/
    CON_OEDIT        = 18, /* OLC mode - object editor		*/
    CON_REDIT        = 19, /* OLC mode - room editor		*/
    CON_ZEDIT        = 20, /* OLC mode - zone info editor		*/
    CON_MEDIT        = 21, /* OLC mode - mobile editor		*/
    CON_SEDIT        = 22, /* OLC mode - shop editor		*/
    CON_TEDIT        = 23, /* OLC mode - text editor		*/
    CON_CEDIT        = 24, /* OLC mode - config editor		*/
    CON_QRACE        = 25, /* Race? 				*/
    CON_ASSEDIT      = 26, /* OLC mode - Assemblies                */
    CON_AEDIT        = 27, /* OLC mode - social (action) edit      */
    CON_TRIGEDIT     = 28, /* OLC mode - trigger edit              */
    CON_RACE_HELP    = 29, /* Race Help 				*/
    CON_CLASS_HELP   = 30, /* Class Help 				*/
    CON_QANSI        = 31, /* Ask for ANSI support     */
    CON_GEDIT        = 32, /* OLC mode - guild editor 		*/
    CON_QROLLSTATS   = 33, /* Reroll stats 			*/
    CON_IEDIT        = 34, /* OLC mode - individual edit		*/
    CON_LEVELUP      = 35, /* Level up menu			*/
    CON_QSTATS       = 36, /* Assign starting stats        	*/
    CON_HAIRL        = 37, /* Choose your hair length        */
    CON_HAIRS        = 38, /* Choose your hair style         */
    CON_HAIRC        = 39, /* Choose your hair color         */
    CON_SKIN         = 40, /* Choose your skin color         */
    CON_EYE          = 41, /* Choose your eye color          */
    CON_Q1           = 42, /* Make a life choice!            */
    CON_Q2           = 43, /* Make a second life choice!     */
    CON_Q3           = 44, /* Make a third life choice!      */
    CON_Q4           = 45, /* Make a fourth life choice!     */
    CON_Q5           = 46, /* Make a fifth life choice!      */
    CON_Q6           = 47, /* Make a sixth life choice!      */
    CON_Q7           = 48, /* Make a seventh life choice!    */
    CON_Q8           = 49, /* Make an eighth life choice!    */
    CON_Q9           = 50, /* Make a ninth life choice!      */
    CON_QX           = 51, /* Make a tenth life choice!      */
    CON_HSEDIT       = 52, /* House Olc                      */
    CON_ALPHA        = 53, /* Alpha Password                 */
    CON_ALPHA2       = 54, /* Alpha Password For Newb        */
    CON_ANDROID      = 55,
    CON_HEDIT        = 56, /* OLC mode - help edit           */
    CON_GET_USER     = 57,
    CON_GET_EMAIL    = 58,
    CON_UMENU        = 59,
    CON_USER_CONF    = 60,
    CON_DISTFEA      = 61,
    CON_HW           = 62,
    CON_AURA         = 63,
    CON_BONUS        = 64,
    CON_NEGATIVE     = 65,
    CON_NEWSEDIT     = 66,
    CON_RACIAL       = 67,
    CON_POBJ         = 68,
    CON_ALIGN        = 69,
    CON_SKILLS       = 70,
    CON_USER_TITLE   = 71,
    CON_GENOME       = 72,
    CON_LUA          = 73,
} ConnectState;

#define NUM_CON_TYPES 74

extern const char *connected_types[NUM_CON_TYPES + 1];

#ifdef __cplusplus
}
#endif
