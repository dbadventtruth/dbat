#pragma once
#include "consts/adminflags.h"
#include "consts/affflags.h"
#include "consts/bonus.h"
#include "consts/colors.h"
#include "consts/history.h"
#include "consts/itemdata.h"
#include "consts/prefflags.h"
#include "consts/skills.h"
#include "consts/types.h"

#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PM_ARRAY_MAX 4

/* These data contain information about a players time data */
struct time_data {
  time_t birth;   /* This represents the characters current age        */
  time_t created; /* This does not change                              */
  time_t maxage;  /* This represents death by natural causes           */
  time_t logon;   /* Time of the last logon (used to calculate played) */
  time_t played;  /* This is the total accumulated time played in secs */
};

/* The pclean_criteria_data is set up in config.c and used in db.c to
   determine the conditions which will cause a player character to be
   deleted from disk if the automagic pwipe system is enabled (see config.c).
*/
struct pclean_criteria_data {
  int level; /* max level for this time limit	*/
  int days;  /* time limit in days			*/
};

/* memory structure for characters */
struct memory_rec_struct {
  int32_t id;
  struct memory_rec_struct *next;
};

typedef struct memory_rec_struct memory_rec;

/* Specials used by NPCs, not PCs */
struct mob_special_data {
  memory_rec *memory; /* List of attackers to remember	       */
  int newitem;        /* Check if mob has new inv item       */
  int8_t default_pos; /* Default position for NPC                */
};

/* Structure used for chars following other chars */
struct skill_data {
  int8_t base;
  int8_t perf;
};

struct mob_proto_data {
  mob_vnum id;   /* Where in data-base                 */

  char *name;        /* NPC aliases / keywords             */
  char *short_descr; /* NPC short description              */
  char *long_descr;  /* NPC room description               */
  char *description; /* NPC look description               */
  char *title;       /* Shared character title field       */

  int size;                             /* Size class                         */
  int8_t sex;                           /* NPC sex                            */
  int race;                             /* NPC race                           */
  int chclass;                          /* NPC class                          */
  struct mob_special_data mob_specials; /* NPC defaults                       */

  int8_t position; /* Load position                      */
  int speaking;    /* Default language                   */

  bitvector_t act[PM_ARRAY_MAX]; /* Mob flags                          */
  bitvector_t affected_by[AF_ARRAY_MAX]; /* Permanent affect flags            */

  struct trig_proto_list *proto_script; /* Prototype trigger list             */
  void *zigdata;                        /* Zig stat storage                   */
};

struct char_data {
  int32_t id;    /* used by DG triggers			*/
  int32_t idnum; /* player's idnum; -1 for mobiles	*/

  int pfilepos;          /* playerfile pos			*/
  mob_vnum proto_id;     /* Mob's proto vnum. -1 for non-mobs	*/
  room_vnum in_room;     /* Location (real room number)		*/
  room_vnum was_in_room; /* location for linkdead people		*/
  int wait;              /* wait for how many loops		*/

  char *name;        /* PC / NPC s name (kill ...  )		*/
  char *short_descr; /* for NPC 'actions'			*/
  char *long_descr;  /* for 'look'				*/
  char *description; /* Extra descriptions                   */
  char *title;       /* PC / NPC's title                     */

  int size;   /* Size class of char                   */
  int8_t sex; /* PC / NPC's sex                       */
  int race;

  int chclass; /* Last class taken                     */

  // admin stuff
  int admlevel; /* PC / NPC's admin level               */
  bitvector_t
      admflags[AD_ARRAY_MAX]; /* Bitvector for admin privs		*/

  room_vnum hometown;    /* PC Hometown / NPC spawn room         */
  struct time_data time; /* PC's AGE in days			*/
  // appearance fields
  int8_t hairl;   /* PC hair length                       */
  int8_t hairs;   /* PC hair style                        */
  int8_t hairc;   /* PC hair color                        */
  int8_t skin;    /* PC skin color                        */
  int8_t eye;     /* PC eye color                         */
  int8_t distfea; /* PC's Distinguishing Feature          */
  int aura;
  char *feature;
  char *rdisplay;
  char *voice; /* PC's snet voice */

  struct mob_special_data mob_specials;
  /* NPC specials				*/

  // affected is now vestigial; it was replaced by the Conditions system.
  // Keeping it around until we can migrate all the old code.
  struct affected_type *affected;

  // inventory and equipment
  struct obj_data *equipment[NUM_WEARS];

  struct descriptor_data *desc; /* NULL for mobiles			*/
  char *loguser;                /* What user was I last saved as?      */

  // dgscripts data
  struct trig_proto_list *proto_script;
  struct script_data *script;   /* script info for the object		*/
  struct script_memory *memory; /* for mob memory triggers		*/

  int32_t master_id;

  int timer; /* Timer for update			*/

  struct obj_data *sits; /* What am I sitting on? */

  // Skill info
  int forgeting;
  int forgetcount;
  skill_data skills[SKILL_TABLE_SIZE];

  bitvector_t act[PM_ARRAY_MAX]; /* act flag for NPC's; player flag for PC's */

  bitvector_t
      affected_by[AF_ARRAY_MAX]; /* Bitvector for current affects	*/

  // magic music
  short song;

  time_t lastint; // last interest time

  // charge systemm
  int64_t charge;
  int64_t chargeto;

  // current barrier strength
  int64_t barrier;

  int boosts;

  int spam; // channel spam

  time_t lastpl;
  time_t lboard[5];

  // absorbtion data for bio/majin
  int absorbs;
  int ingestLearned;

  // food, drink, sleep
  int sleeptime;
  int foodr;

  // Saiyan and halfy stuff
  int tail_growth;
  int rage_meter;

  // distance attention stuff
  room_vnum listenroom;
  int eavesdir;
  int arenawatch;

  int lasthit;

  // limb information... why do we have three of them?
  int limbs[4]; /* 0 Right Arm, 1 Left Arm, 2 Right Leg, 3 Left Leg */
  int limb_condition[4];
  bitvector_t bodyparts[AF_ARRAY_MAX]; /* Bitvector for current bodyparts */

  time_t rewtime;

  int genome[2]; /* Bio racial bonus, Genome */

  // roleplay points stuff
  int rp;
  int trp;

  // combo system data
  int lastattack;

  // spaceship piloting
  int ping;
  room_vnum radar1;
  room_vnum radar2;
  room_vnum radar3;

  // hoshijin stuff
  int starphase;
  int mimic;

  // Chargen bonus/flaw points
  int ccpoints;
  int negcount;
  int bonuses[MAX_BONUSES];
  int choice;

  // cooldowns here
  int cooldown;
  int backstabcool;
  int con_cooldown;
  int con_sdcooldown;
  int gooptime;

  // Death stuff
  int death_type;
  room_vnum droom;
  time_t deathtime;

  // transformation data
  int transclass;
  int transcost[6];

  char *temp_prompt;

  int personality;
  int combine;
  int linker;

  int throws;

  int mobcharge;
  int preference;
  int aggtimer;

  int relax_count;

  // Zig Fields
  void *zigdata;

  // COPIED FROM PLAYER_SPECIALS
  char *poofin;                   /* Description on arrival of a god.     */
  char *poofout;                  /* Description upon a god's exit.       */
  struct alias_data *aliases;     /* Character's aliases                  */
  int32_t last_tell;              /* idnum of last tell from              */
  void *last_olc_targ;            /* olc control                          */
  int last_olc_mode;              /* olc control                          */
  char *host;                     /* host of last logon                   */
  int wimp_level;                 /* Below this # of hit points, flee!	*/
  int8_t freeze_level;            /* Level of god who froze char, if any	*/
  int16_t invis_level;            /* level of invisibility		*/
  room_vnum load_room;            /* Which room to place char in		*/
  bitvector_t pref[PR_ARRAY_MAX]; /* preference flags for PC's.		*/
  uint8_t bad_pws;                /* number of bad password attemps	*/
  struct txt_block *comm_hist[NUM_HIST]; /* Player's communcations history */
  int olc_zone;                          /* Zone where OLC is permitted		*/
  int speaking;                          /* Language currently speaking		*/

  char *color_choices[NUM_COLOR]; /* Choices for custom colors		*/
  int murder;                     /* Murder of PC's count                 */

  int racial_pref;

  // UNUSED STUFF BELOW HERE
  int crank;         // clank rank
  char *clan;
};

#ifdef __cplusplus
}
#endif
