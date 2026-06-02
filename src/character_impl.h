#pragma once
#include "consts/types.h"
#include "consts/prefflags.h"
#include "consts/colors.h"
#include "consts/history.h"
#include "consts/itemdata.h"
#include "consts/skills.h"
#include "consts/bonus.h"
#include "consts/affflags.h"
#include "consts/adminflags.h"

#include <time.h>


#ifdef __cplusplus
extern "C" {
#endif

#define PM_ARRAY_MAX 4

/* These data contain information about a players time data */
struct time_data
{
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
struct pclean_criteria_data
{
   int level; /* max level for this time limit	*/
   int days;  /* time limit in days			*/
};

/* Char's abilities. */
struct abil_data
{
   int8_t str; /* New stats can go over 18 freely, no more /xx */
   int8_t intel;
   int8_t wis;
   int8_t dex;
   int8_t con;
   int8_t cha;
};


/* memory structure for characters */
struct memory_rec_struct
{
   int32_t id;
   struct memory_rec_struct *next;
};

typedef struct memory_rec_struct memory_rec;

/* Specials used by NPCs, not PCs */
struct mob_special_data
{
   memory_rec *memory; /* List of attackers to remember	       */
   int newitem;        /* Check if mob has new inv item       */
   int8_t default_pos; /* Default position for NPC                */
};


/* Structure used for chars following other chars */
struct follow_type
{
   struct char_data *follower;
   struct follow_type *next;
};

struct skill_data {
   int8_t base;
   int8_t perf;
};

struct mob_proto_data
{
   mob_vnum vnum;                       /* Where in data-base                 */

   char *name;                          /* NPC aliases / keywords             */
   char *short_descr;                   /* NPC short description              */
   char *long_descr;                    /* NPC room description               */
   char *description;                   /* NPC look description               */
   char *title;                         /* Shared character title field       */

   int size;                            /* Size class                         */
   int8_t sex;                          /* NPC sex                            */
   int race;                            /* NPC race                           */
   int chclass;                         /* NPC class                          */
   struct mob_special_data mob_specials;/* NPC defaults                       */

   int8_t position;                     /* Load position                      */
   int speaking;                        /* Default language                   */

   bitvector_t act[PM_ARRAY_MAX];       /* Mob flags                          */
   bitvector_t affected_by[AF_ARRAY_MAX]; /* Permanent affect flags            */

   struct trig_proto_list *proto_script;/* Prototype trigger list             */
   void *zigdata;                       /* Zig stat storage                   */
};

struct char_data
{
   int32_t id;                   /* used by DG triggers			*/
   int32_t idnum;                 /* player's idnum; -1 for mobiles	*/

   int pfilepos;          /* playerfile pos			*/
   mob_vnum vnum;           /* Mob's vnum. -1 for non-mobs	*/
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
   int admlevel;                       /* PC / NPC's admin level               */
   bitvector_t admflags[AD_ARRAY_MAX]; /* Bitvector for admin privs		*/
   
   room_vnum hometown;                 /* PC Hometown / NPC spawn room         */
   struct time_data time;              /* PC's AGE in days			*/
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

   struct affected_type *affected;
   /* affected by what spells		*/

   // inventory and equipment
   struct obj_data *equipment[NUM_WEARS];
   struct obj_data *carrying;
   int carry_weight; // carried weight
   int8_t carry_items; // number of carried items

   struct descriptor_data *desc; /* NULL for mobiles			*/
   char *loguser; /* What user was I last saved as?      */

   // dgscripts data
   struct trig_proto_list *proto_script;
   struct script_data *script;   /* script info for the object		*/
   struct script_memory *memory; /* for mob memory triggers		*/

   struct char_data *next_in_room;
   /* For room->people - list		*/
   struct char_data *next; /* For either monster or ppl-list	*/
   struct char_data *next_fighting;
   /* For fighting list			*/
   struct char_data *next_affect; /* For affect wearoff			*/

   struct follow_type *followers; /* List of chars followers		*/
   struct char_data *master;      /* Who is char following?		*/
   int32_t master_id;

   struct char_data *fighting; /* Opponent				*/

   int8_t position; /* Standing, fighting, sleeping, etc.	*/

   int timer;          /* Timer for update			*/

   struct obj_data *sits;       /* What am I sitting on? */

   // combat blocking
   struct char_data *blocks;    /* Who am I blocking?    */
   struct char_data *blocked;   /* Who is blocking me?    */

   // android absorb 
   struct char_data *absorbing; /* Who am I absorbing */
   struct char_data *absorbby;  /* Who is absorbing me */

   // defend stuff
   struct char_data *defender;
   struct char_data *defending;

   struct char_data *poisonby;

   // grappling stuff
   int grap;
   struct char_data *grappling;
   struct char_data *grappled;

   // Skill info
   int forgeting;
   int forgetcount;
   skill_data skills[SKILL_TABLE_SIZE];

   bitvector_t act[PM_ARRAY_MAX]; /* act flag for NPC's; player flag for PC's */

   bitvector_t affected_by[AF_ARRAY_MAX]; /* Bitvector for current affects	*/

   // magic music
   short song;

   int group_kills;

   time_t lastint; // last interest time

   // used for temporaryt storage of bonuses
   int64_t max_mana; /* Max mana for PC/NPC			*/
   int64_t max_hit; /* Max hit for PC/NPC			*/
   int64_t max_move; /* Max move for PC/NPC			*/
   int64_t max_ki; /* Max ki for PC/NPC			*/

   // resource meters, ranges from 0 to 1.0
   double health;
   double energy;
   double stamina;
   double life;

   // charge systemm
   int64_t charge;
   int64_t chargeto;

   // current barrier strength
   int64_t barrier;

   int boosts;

   int altitude; // used for fly/fly higher

   int spam; // channel spam

   time_t lastpl;
   time_t lboard[5];

   // absorbtion data for bio/majin
   int absorbs;
   int ingestLearned;

   // food, drink, sleep
   int sleeptime;
   int foodr;
   int overf;

   // Saiyan and halfy stuff
   int tail_growth;
   int rage_meter;

   // distance attention stuff
   room_vnum listenroom;
   int eavesdir;
   int arenawatch;

   // dragging
   struct char_data *drag;
   struct char_data *dragged;
   
   struct char_data *mindlink;
   int lasthit;

   // limb information... why do we have three of them?
   int limbs[4]; /* 0 Right Arm, 1 Left Arm, 2 Right Leg, 3 Left Leg */
   int limb_condition[4];
   bitvector_t bodyparts[AF_ARRAY_MAX];   /* Bitvector for current bodyparts      */

   time_t rewtime;

   int genome[2]; /* Bio racial bonus, Genome */

   // roleplay points stuff
   int rp;
   int trp;

   // combo system data
   int combo;
   int lastattack;
   int combhits;

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
   
   // majinize
   int64_t majinizer;
   int majinize;

   // misc combat stuff
   int speedboost;
   // transformation data
   int transclass;
   int transcost[6];

   // Fishing stuff - accuracy_mod is fish_pole_bonus
   int fishstate;
   int fishdistance;

   char *temp_prompt;

   int personality;
   int combine;
   int linker;

   int throws;

   int mobcharge;
   int preference;
   int aggtimer;

   // miscellaneous bonuses
   int blesslvl;
   int lifebonus;

   // multiform stuff
   struct char_data *original;
   short clones;

   int relax_count;

   // Zig Fields
   void *zigdata;

   // COPIED FROM PLAYER_SPECIALS
   char *poofin;                      /* Description on arrival of a god.     */
   char *poofout;                     /* Description upon a god's exit.       */
   struct alias_data *aliases;        /* Character's aliases                  */
   int32_t last_tell;                 /* idnum of last tell from              */
   void *last_olc_targ;               /* olc control                          */
   int last_olc_mode;                 /* olc control                          */
   char *host;                        /* host of last logon                   */
   int wimp_level;                    /* Below this # of hit points, flee!	*/
   int8_t freeze_level;               /* Level of god who froze char, if any	*/
   int16_t invis_level;               /* level of invisibility		*/
   room_vnum load_room;               /* Which room to place char in		*/
   bitvector_t pref[PR_ARRAY_MAX];    /* preference flags for PC's.		*/
   uint8_t bad_pws;                   /* number of bad password attemps	*/
   struct txt_block *comm_hist[NUM_HIST]; /* Player's communcations history     */
   int olc_zone;                          /* Zone where OLC is permitted		*/
   int speaking;                          /* Language currently speaking		*/

   char *color_choices[NUM_COLOR]; /* Choices for custom colors		*/
   int murder; /* Murder of PC's count                 */

   // player characters can carry others.
   struct char_data *carrying_char;
   struct char_data *carried_by_char;

   int racial_pref;

   // UNUSED STUFF BELOW HERE
   int64_t mana;
   int64_t hit;
   int64_t move;
   int64_t ki;
   int64_t lifeforce;
   int damage_mod;        /* Any bonus or penalty to the damage	*/
   int16_t spellfail;     /* Total spell failure %                 */
   int16_t armorcheck;    /* Total armorcheck penalty with proficiency forgiveness */
   int16_t armorcheckall; /* Total armorcheck penalty regardless of proficiency */
   int crank; // clank rank
   char *clan;
};

#ifdef __cplusplus
}
#endif
