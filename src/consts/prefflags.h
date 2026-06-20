#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/*  flags: used by char_data.pref */
typedef enum {
    PRF_BRIEF      = 0,  /* Room descs won't normally be shown	*/
    PRF_COMPACT    = 1,  /* No extra CRLF pair before prompts		*/
    PRF_DEAF       = 2,  /* Can't hear shouts              		*/
    PRF_NOTELL     = 3,  /* Can't receive tells		    	*/
    PRF_DISPHP     = 4,  /* Display hit points in prompt  		*/
    PRF_DISPMANA   = 5,  /* Display mana points in prompt    		*/
    PRF_DISPMOVE   = 6,  /* Display move points in prompt 		*/
    PRF_AUTOEXIT   = 7,  /* Display exits in a room          		*/
    PRF_NOHASSLE   = 8,  /* Aggr mobs won't attack           		*/
    PRF_QUEST      = 9,  /* On quest					*/
    PRF_SUMMONABLE = 10, /* Can be summoned				*/
    PRF_NOREPEAT   = 11, /* No repetition of comm commands		*/
    PRF_HOLYLIGHT  = 12, /* Can see in dark				*/
    PRF_COLOR      = 13, /* Color					*/
    PRF_SPARE      = 14, /* Used to be second color bit		*/
    PRF_NOWIZ      = 15, /* Can't hear wizline			*/
    PRF_LOG1       = 16, /* On-line System Log (low bit)		*/
    PRF_LOG2       = 17, /* On-line System Log (high bit)		*/
    PRF_NOAUCT     = 18, /* Can't hear auction channel		*/
    PRF_NOGOSS     = 19, /* Can't hear gossip channel			*/
    PRF_NOGRATZ    = 20, /* Can't hear grats channel			*/
    PRF_ROOMFLAGS  = 21, /* Can see room flags (ROOM_x)		*/
    PRF_DISPAUTO   = 22, /* Show prompt HP, MP, MV when < 30%.	*/
    PRF_CLS        = 23, /* Clear screen in OasisOLC 			*/
    PRF_BUILDWALK  = 24, /* Build new rooms when walking		*/
    PRF_AFK        = 25, /* Player is AFK				*/
    PRF_AUTOLOOT   = 26, /* Loot everything from a corpse		*/
    PRF_AUTOGOLD   = 27, /* Loot gold from a corpse			*/
    PRF_AUTOSPLIT  = 28, /* Split gold with group			*/
    PRF_FULL_EXIT  = 29, /* Shows full autoexit details		*/
    PRF_AUTOSAC    = 30, /* Sacrifice a corpse 			*/
    PRF_AUTOMEM    = 31, /* Memorize spells				*/
    PRF_VIEWORDER  = 32, /* if you want to see the newest first 	*/
    PRF_NOCOMPRESS = 33, /* If you want to force MCCP2 off          	*/
    PRF_AUTOASSIST = 34, /* Auto-assist toggle                      	*/
    PRF_DISPKI     = 35, /* Display ki points in prompt 		*/
    PRF_DISPEXP    = 36, /* Display exp points in prompt 		*/
    PRF_DISPTNL    = 37, /* Display TNL exp points in prompt 		*/
    PRF_TEST       = 38, /* Sets triggers safety off for imms         */
    PRF_HIDE       = 39, /* Hide on who from other mortals            */
    PRF_NMWARN     = 40, /* No mail warning                           */
    PRF_HINTS      = 41, /* Receives hints                            */
    PRF_FURY       = 42, /* Sees fury meter                           */
    PRF_NODEC      = 43,
    PRF_NOEQSEE    = 44,
    PRF_NOMUSIC    = 45,
    PRF_LKEEP      = 46,
    PRF_DISTIME    = 47, /* Part of Prompt Options */
    PRF_DISGOLD    = 48, /* Part of Prompt Options */
    PRF_DISPRAC    = 49, /* Part of Prompt Options */
    PRF_NOPARRY    = 50,
    PRF_DISHUTH    = 51, /* Part of Prompt Options */
    PRF_DISPERC    = 52, /* Part of Prompt Options */
    PRF_CARVE      = 53,
    PRF_ARENAWATCH = 54,
    PRF_NOGIVE     = 55,
    PRF_INSTRUCT   = 56,
    PRF_GHEALTH    = 57,
    PRF_IHEALTH    = 58,
    PRF_ENERGIZE   = 59,
} PrefFlags;

#define NUM_PRF_FLAGS 60
#define PR_ARRAY_MAX 4

extern const char *preference_bits[NUM_PRF_FLAGS + 1];

#ifdef __cplusplus
}
#endif
