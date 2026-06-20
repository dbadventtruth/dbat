#pragma once
#include "conditions.h"
#include "materials.h"

#ifdef __cplusplus
extern "C" {
#endif

/* Character equipment positions: used as index for char_data.equipment[] */
/* NOTE: Don't confuse these constants with the ITEM_ bitvectors
   which control the valid places you can wear a piece of equipment */
typedef enum {
    WEAR_UNUSED0  = 0,
    WEAR_FINGER_R = 1,
    WEAR_FINGER_L = 2,
    WEAR_NECK_1   = 3,
    WEAR_NECK_2   = 4,
    WEAR_BODY     = 5,
    WEAR_HEAD     = 6,
    WEAR_LEGS     = 7,
    WEAR_FEET     = 8,
    WEAR_HANDS    = 9,
    WEAR_ARMS     = 10,
    WEAR_UNUSED1  = 11,
    WEAR_ABOUT    = 12,
    WEAR_WAIST    = 13,
    WEAR_WRIST_R  = 14,
    WEAR_WRIST_L  = 15,
    WEAR_WIELD1   = 16,
    WEAR_WIELD2   = 17,
    WEAR_BACKPACK = 18,
    WEAR_EAR_R    = 19,
    WEAR_EAR_L    = 20,
    WEAR_SH       = 21,
    WEAR_EYE      = 22,
} WearPosition;

#define NUM_WEARS 23 /* This must be the # of eq positions!! */

/* object-related defines ********************************************/

/* Item types: used by obj_data.type_flag */
typedef enum {
    ITEM_LIGHT      = 1,  /* Item is a light source	*/
    ITEM_SCROLL     = 2,  /* Item is a scroll		*/
    ITEM_WAND       = 3,  /* Item is a wand		*/
    ITEM_STAFF      = 4,  /* Item is a staff		*/
    ITEM_WEAPON     = 5,  /* Item is a weapon		*/
    ITEM_FIREWEAPON = 6,  /* Unimplemented		*/
    ITEM_CAMPFIRE   = 7,  /* Burn things for fun!		*/
    ITEM_TREASURE   = 8,  /* Item is a treasure, not gold	*/
    ITEM_ARMOR      = 9,  /* Item is armor		*/
    ITEM_POTION     = 10, /* Item is a potion		*/
    ITEM_WORN       = 11, /* Unimplemented		*/
    ITEM_OTHER      = 12, /* Misc object			*/
    ITEM_TRASH      = 13, /* Trash - shopkeeps won't buy	*/
    ITEM_TRAP       = 14, /* Unimplemented		*/
    ITEM_CONTAINER  = 15, /* Item is a container		*/
    ITEM_NOTE       = 16, /* Item is note 		*/
    ITEM_DRINKCON   = 17, /* Item is a drink container	*/
    ITEM_KEY        = 18, /* Item is a key		*/
    ITEM_FOOD       = 19, /* Item is food			*/
    ITEM_MONEY      = 20, /* Item is money (gold)		*/
    ITEM_PEN        = 21, /* Item is a pen		*/
    ITEM_BOAT       = 22, /* Item is a boat		*/
    ITEM_FOUNTAIN   = 23, /* Item is a fountain		*/
    ITEM_VEHICLE    = 24, /* Item is a vehicle            */
    ITEM_HATCH      = 25, /* Item is a vehicle hatch      */
    ITEM_WINDOW     = 26, /* Item is a vehicle window     */
    ITEM_CONTROL    = 27, /* Item is a vehicle control    */
    ITEM_PORTAL     = 28, /* Item is a portal	        */
    ITEM_SPELLBOOK  = 29, /* Item is a spellbook	        */
    ITEM_BOARD      = 30, /* Item is a message board 	*/
    ITEM_CHAIR      = 31, /* Is a chair                   */
    ITEM_BED        = 32, /* Is a bed                     */
    ITEM_YUM        = 33, /* This was good food           */
    ITEM_PLANT      = 34, /* This will grow!              */
    ITEM_FISHPOLE   = 35, /* FOR FISHING                  */
    ITEM_FISHBAIT   = 36, /* DITTO                        */
} ItemType;

#define NUM_ITEM_TYPES 37

/* Take/Wear flags: used by obj_data.wear_flags */
typedef enum {
    ITEM_WEAR_TAKE   = 0,  /* Item can be taken         */
    ITEM_WEAR_FINGER = 1,  /* Can be worn on finger     */
    ITEM_WEAR_NECK   = 2,  /* Can be worn around neck   */
    ITEM_WEAR_BODY   = 3,  /* Can be worn on body       */
    ITEM_WEAR_HEAD   = 4,  /* Can be worn on head       */
    ITEM_WEAR_LEGS   = 5,  /* Can be worn on legs       */
    ITEM_WEAR_FEET   = 6,  /* Can be worn on feet       */
    ITEM_WEAR_HANDS  = 7,  /* Can be worn on hands      */
    ITEM_WEAR_ARMS   = 8,  /* Can be worn on arms       */
    ITEM_WEAR_SHIELD = 9,  /* Can be used as a shield   */
    ITEM_WEAR_ABOUT  = 10, /* Can be worn about body    */
    ITEM_WEAR_WAIST  = 11, /* Can be worn around waist  */
    ITEM_WEAR_WRIST  = 12, /* Can be worn on wrist      */
    ITEM_WEAR_WIELD  = 13, /* Can be wielded            */
    ITEM_WEAR_HOLD   = 14, /* Can be held               */
    ITEM_WEAR_PACK   = 15, /* Can be worn as a backpack */
    ITEM_WEAR_EAR    = 16, /* Can be worn as an earring */
    ITEM_WEAR_SH     = 17, /* Can be worn as wings      */
    ITEM_WEAR_EYE    = 18, /* Can be worn as a mask     */
} ItemWearFlag;

#define NUM_ITEM_WEARS 19

/* Extra object flags: used by obj_data.extra_flags */
typedef enum {
    ITEM_GLOW                  = 0,  /* Item is glowing              */
    ITEM_HUM                   = 1,  /* Item is humming              */
    ITEM_NORENT                = 2,  /* Item cannot be rented        */
    ITEM_NODONATE              = 3,  /* Item cannot be donated       */
    ITEM_NOINVIS               = 4,  /* Item cannot be made invis    */
    ITEM_INVISIBLE             = 5,  /* Item is invisible            */
    ITEM_MAGIC                 = 6,  /* Item is magical              */
    ITEM_NODROP                = 7,  /* Item is cursed: can't drop   */
    ITEM_BLESS                 = 8,  /* Item is blessed              */
    ITEM_ANTI_GOOD             = 9,  /* Not usable by good people    */
    ITEM_ANTI_EVIL             = 10, /* Not usable by evil people    */
    ITEM_ANTI_NEUTRAL          = 11, /* Not usable by neutral people */
    ITEM_ANTI_WIZARD           = 12, /* Not usable by mages          */
    ITEM_ANTI_CLERIC           = 13, /* Not usable by clerics        */
    ITEM_ANTI_ROGUE            = 14, /* Not usable by thieves        */
    ITEM_ANTI_FIGHTER          = 15, /* Not usable by warriors       */
    ITEM_NOSELL                = 16, /* Shopkeepers won't touch it   */
    ITEM_ANTI_DRUID            = 17, /* Not usable by druids         */
    ITEM_2H                    = 18, /* Requires two free hands      */
    ITEM_ANTI_BARD             = 19, /* Not usable by bards          */
    ITEM_ANTI_RANGER           = 20, /* Not usable by rangers        */
    ITEM_ANTI_PALADIN          = 21, /* Not usable by paladins       */
    ITEM_ANTI_HUMAN            = 22, /* Not usable by humans         */
    ITEM_ANTI_ICER             = 23, /* Not usable by dwarves        */
    ITEM_ANTI_SAIYAN           = 24, /* Not usable by elves          */
    ITEM_ANTI_KONATSU          = 25, /* Not usable by gnomes         */
    ITEM_UNIQUE_SAVE           = 26, /* unique object save           */
    ITEM_BROKEN                = 27, /* Item is broken hands         */
    ITEM_UNBREAKABLE           = 28, /* Item is unbreakable          */
    ITEM_ANTI_MONK             = 29, /* Not usable by monks          */
    ITEM_ANTI_BARBARIAN        = 30, /* Not usable by barbarians     */
    ITEM_ANTI_SORCERER         = 31, /* Not usable by sorcerers      */
    ITEM_DOUBLE                = 32, /* Double weapon                */
    ITEM_ONLY_WIZARD           = 33, /* Only usable by mages         */
    ITEM_ONLY_CLERIC           = 34, /* Only usable by clerics       */
    ITEM_ONLY_ROGUE            = 35, /* Only usable by thieves       */
    ITEM_ONLY_FIGHTER          = 36, /* Only usable by warriors      */
    ITEM_ONLY_DRUID            = 37, /* Only usable by druids        */
    ITEM_ONLY_BARD             = 38, /* Only usable by bards         */
    ITEM_ONLY_RANGER           = 39, /* Only usable by rangers       */
    ITEM_ONLY_PALADIN          = 40, /* Only usable by paladins      */
    ITEM_ONLY_HUMAN            = 41, /* Only usable by humans        */
    ITEM_ONLY_ICER             = 42, /* Only usable by dwarves       */
    ITEM_ONLY_SAIYAN           = 43, /* Only usable by elves         */
    ITEM_ONLY_KONATSU          = 44, /* Only usable by gnomes        */
    ITEM_ONLY_MONK             = 45, /* Only usable by monks         */
    ITEM_ONLY_BARBARIAN        = 46, /* Only usable by barbarians    */
    ITEM_ONLY_SORCERER         = 47, /* Only usable by sorcerers     */
    ITEM_ANTI_ARCANE_ARCHER    = 48, /* Not usable by Aracane Archers */
    ITEM_ANTI_ARCANE_TRICKSTER = 49, /* Not usable by Aracane tricksters */
    ITEM_ANTI_ARCHMAGE         = 50, /* Not usable by Archmages      */
    ITEM_ANTI_ASSASSIN         = 51, /* Not usable by Assassins      */
    ITEM_ANTI_BLACKGUARD       = 52, /* Not usable by Blackguards    */
    ITEM_ANTI_DRAGON_DISCIPLE  = 53, /* Not usable by Dragon disciples */
    ITEM_ANTI_DUELIST          = 54, /* Not usable by Duelists       */
    ITEM_ANTI_DWARVEN_DEFENDER = 55, /* Not usable by Dwarven defenders */
    ITEM_ANTI_ELDRITCH_KNIGHT  = 56, /* Not usable by Eldritch knights */
    ITEM_ANTI_HIEROPHANT       = 57, /* Not usable by Hierophants    */
    ITEM_ANTI_HORIZON_WALKER   = 58, /* Not usable by Horizon walkers */
    ITEM_ANTI_LOREMASTER       = 59, /* Not usable by Loremasters    */
    ITEM_ANTI_MYSTIC_THEURGE   = 60, /* Not usable by Mystic theurges */
    ITEM_ANTI_SHADOWDANCER     = 61, /* Not useable by shadowdancers */
    ITEM_ANTI_THAUMATURGIST    = 62, /* Not useable by thaumaturgists */
    ITEM_BSCOUTER              = 63,
    ITEM_MSCOUTER              = 64,
    ITEM_ASCOUTER              = 65,
    ITEM_USCOUTER              = 66,
    ITEM_WEAPLVL1              = 67,
    ITEM_WEAPLVL2              = 68,
    ITEM_WEAPLVL3              = 69,
    ITEM_WEAPLVL4              = 70,
    ITEM_WEAPLVL5              = 71,
    ITEM_CBOARD                = 72,
    ITEM_FORGED                = 73,
    ITEM_SHEATH                = 74,
    ITEM_ONLY_JINTO            = 75,
    ITEM_BURIED                = 76,
    ITEM_SLOT1                 = 77,
    ITEM_SLOT2                 = 78,
    ITEM_TOKEN                 = 79,
    ITEM_SLOT_ONE              = 80,
    ITEM_SLOTS_FILLED          = 81,
    ITEM_RESTRING              = 82,
    ITEM_CUSTOM                = 83,
    ITEM_PROTECTED             = 84,
    ITEM_NORANDOM              = 85,
    ITEM_THROW                 = 86,
    ITEM_HOT                   = 87,
    ITEM_PURGE                 = 88,
    ITEM_ICE                   = 89,
    ITEM_DUPLICATE             = 90,
    ITEM_MATURE                = 91,
    ITEM_CARDCASE              = 92,
    ITEM_NOPICKUP              = 93,
    ITEM_NOSTEAL               = 94,
} ItemExtraFlag;

#define NUM_ITEM_FLAGS 95

/* Container flags - value[1] */
typedef enum {
    CONT_CLOSEABLE = (1 << 0), /* Container can be closed	*/
    CONT_PICKPROOF = (1 << 1), /* Container is pickproof	*/
    CONT_CLOSED    = (1 << 2), /* Container is closed		*/
    CONT_LOCKED    = (1 << 3), /* Container is locked		*/
} ContainerFlag;

#define NUM_CONT_FLAGS 4

/* object-related structures ******************************************/
#define NUM_OBJ_VAL_POSITIONS 16

#define VAL_ALL_HEALTH 4
#define VAL_ALL_MAXHEALTH 5
#define VAL_ALL_MATERIAL 7
/*
 * Uses for generic object values on specific object types
 * Please use these instead of numbers to prevent overlaps.
 */
#define VAL_LIGHT_TIME 0
#define VAL_LIGHT_UNUSED2 1
#define VAL_LIGHT_HOURS 2
#define VAL_LIGHT_UNUSED4 3
#define VAL_LIGHT_HEALTH 4
#define VAL_LIGHT_MAXHEALTH 5
#define VAL_LIGHT_UNUSED7 6
#define VAL_LIGHT_MATERIAL 7
#define VAL_SCROLL_LEVEL 0
#define VAL_SCROLL_SPELL1 1
#define VAL_SCROLL_SPELL2 2
#define VAL_SCROLL_SPELL3 3
#define VAL_SCROLL_HEALTH 4
#define VAL_SCROLL_MAXHEALTH 5
#define VAL_SCROLL_UNUSED7 6
#define VAL_SCROLL_MATERIAL 7
#define VAL_WAND_LEVEL 0
#define VAL_WAND_MAXCHARGES 1
#define VAL_WAND_CHARGES 2
#define VAL_WAND_SPELL 3
#define VAL_WAND_HEALTH 4
#define VAL_WAND_MAXHEALTH 5
#define VAL_WAND_UNUSED7 6
#define VAL_WAND_MATERIAL 7
#define VAL_STAFF_LEVEL 0
#define VAL_STAFF_MAXCHARGES 1
#define VAL_STAFF_CHARGES 2
#define VAL_STAFF_SPELL 3
#define VAL_STAFF_HEALTH 4
#define VAL_STAFF_MAXHEALTH 5
#define VAL_STAFF_UNUSED7 6
#define VAL_STAFF_MATERIAL 7
#define VAL_WEAPON_SKILL 0
#define VAL_WEAPON_DAMDICE 1
#define VAL_WEAPON_DAMSIZE 2
#define VAL_WEAPON_DAMTYPE 3
#define VAL_WEAPON_HEALTH 4
#define VAL_WEAPON_MAXHEALTH 5
#define VAL_WEAPON_CRITTYPE 6
#define VAL_WEAPON_MATERIAL 7
#define VAL_WEAPON_CRITRANGE 8
#define VAL_FIREWEAPON_UNUSED1 0
#define VAL_FIREWEAPON_UNUSED2 1
#define VAL_FIREWEAPON_UNUSED3 2
#define VAL_FIREWEAPON_UNUSED4 3
#define VAL_FIREWEAPON_HEALTH 4
#define VAL_FIREWEAPON_MAXHEALTH 5
#define VAL_FIREWEAPON_UNUSED7 6
#define VAL_FIREWEAPON_MATERIAL 7
#define VAL_MISSILE_UNUSED1 0
#define VAL_MISSILE_UNUSED2 1
#define VAL_MISSILE_UNUSED3 2
#define VAL_MISSILE_UNUSED4 3
#define VAL_MISSILE_HEALTH 4
#define VAL_MISSILE_MAXHEALTH 5
#define VAL_MISSILE_UNUSED7 6
#define VAL_MISSILE_MATERIAL 7
#define VAL_TREASURE_UNUSED1 0
#define VAL_TREASURE_UNUSED2 1
#define VAL_TREASURE_UNUSED3 2
#define VAL_TREASURE_UNUSED4 3
#define VAL_TREASURE_HEALTH 4
#define VAL_TREASURE_MAXHEALTH 5
#define VAL_TREASURE_UNUSED7 6
#define VAL_TREASURE_MATERIAL 7
#define VAL_ARMOR_APPLYAC 0
#define VAL_ARMOR_SKILL 1
#define VAL_ARMOR_MAXDEXMOD 2
#define VAL_ARMOR_CHECK 3
#define VAL_ARMOR_HEALTH 4
#define VAL_ARMOR_MAXHEALTH 5
#define VAL_ARMOR_SPELLFAIL 6
#define VAL_ARMOR_MATERIAL 7
#define VAL_POTION_LEVEL 0
#define VAL_POTION_SPELL1 1
#define VAL_POTION_SPELL2 2
#define VAL_POTION_SPELL3 3
#define VAL_POTION_HEALTH 4
#define VAL_POTION_MAXHEALTH 5
#define VAL_POTION_UNUSED7 6
#define VAL_POTION_MATERIAL 7
#define VAL_WORN_UNUSED1 0
#define VAL_WORN_UNUSED2 1
#define VAL_WORN_UNUSED3 2
#define VAL_WORN_UNUSED4 3
#define VAL_WORN_HEALTH 4
#define VAL_WORN_MAXHEALTH 5
#define VAL_WORN_UNUSED7 6
#define VAL_WORN_MATERIAL 7
#define VAL_OTHER_UNUSED1 0
#define VAL_OTHER_UNUSED2 1
#define VAL_OTHER_UNUSED3 2
#define VAL_OTHER_UNUSED4 3
#define VAL_OTHER_HEALTH 4
#define VAL_OTHER_MAXHEALTH 5
#define VAL_OTHER_UNUSED7 6
#define VAL_OTHER_MATERIAL 7
#define VAL_TRASH_UNUSED1 0
#define VAL_TRASH_UNUSED2 1
#define VAL_TRASH_UNUSED3 2
#define VAL_TRASH_UNUSED4 3
#define VAL_TRASH_HEALTH 4
#define VAL_TRASH_MAXHEALTH 5
#define VAL_TRASH_UNUSED7 6
#define VAL_TRASH_MATERIAL 7
#define VAL_TRAP_SPELL 0
#define VAL_TRAP_HITPOINTS 1
#define VAL_TRAP_UNUSED3 2
#define VAL_TRAP_UNUSED4 3
#define VAL_TRAP_HEALTH 4
#define VAL_TRAP_MAXHEALTH 5
#define VAL_TRAP_UNUSED7 6
#define VAL_TRAP_MATERIAL 7
#define VAL_CONTAINER_CAPACITY 0
#define VAL_CONTAINER_FLAGS 1
#define VAL_CONTAINER_KEY 2
#define VAL_CONTAINER_CORPSE 3
#define VAL_CONTAINER_HEALTH 4
#define VAL_CONTAINER_MAXHEALTH 5
#define VAL_CONTAINER_UNUSED7 6
#define VAL_CONTAINER_MATERIAL 7
#define VAL_CONTAINER_OWNER 8
#define VAL_NOTE_LANGUAGE 0
#define VAL_NOTE_UNUSED2 1
#define VAL_NOTE_UNUSED3 2
#define VAL_NOTE_UNUSED4 3
#define VAL_NOTE_HEALTH 4
#define VAL_NOTE_MAXHEALTH 5
#define VAL_NOTE_UNUSED7 6
#define VAL_NOTE_MATERIAL 7
#define VAL_DRINKCON_CAPACITY 0
#define VAL_DRINKCON_HOWFULL 1
#define VAL_DRINKCON_LIQUID 2
#define VAL_DRINKCON_POISON 3
#define VAL_DRINKCON_HEALTH 4
#define VAL_DRINKCON_MAXHEALTH 5
#define VAL_DRINKCON_UNUSED7 6
#define VAL_DRINKCON_MATERIAL 7
#define VAL_KEY_UNUSED1 0
#define VAL_KEY_UNUSED2 1
#define VAL_KEY_KEYCODE 2
#define VAL_KEY_UNUSED4 3
#define VAL_KEY_HEALTH 4
#define VAL_KEY_MAXHEALTH 5
#define VAL_KEY_UNUSED7 6
#define VAL_KEY_MATERIAL 7
#define VAL_FOOD_FOODVAL 0
#define VAL_FOOD_MAXFOODVAL 1
#define VAL_FOOD_PSBONUS 2
#define VAL_FOOD_POISON 3
#define VAL_FOOD_HEALTH 4
#define VAL_FOOD_MAXHEALTH 5
#define VAL_FOOD_EXPBONUS 6
#define VAL_FOOD_MATERIAL 7
#define VAL_MONEY_SIZE 0
#define VAL_MONEY_UNUSED2 1
#define VAL_MONEY_UNUSED3 2
#define VAL_MONEY_UNUSED4 3
#define VAL_MONEY_HEALTH 4
#define VAL_MONEY_MAXHEALTH 5
#define VAL_MONEY_UNUSED7 6
#define VAL_MONEY_MATERIAL 7
#define VAL_PEN_UNUSED1 0
#define VAL_PEN_UNUSED2 1
#define VAL_PEN_UNUSED3 2
#define VAL_PEN_UNUSED4 3
#define VAL_PEN_HEALTH 4
#define VAL_PEN_MAXHEALTH 5
#define VAL_PEN_UNUSED7 6
#define VAL_PEN_MATERIAL 7
#define VAL_BOAT_UNUSED1 0
#define VAL_BOAT_UNUSED2 1
#define VAL_BOAT_UNUSED3 2
#define VAL_BOAT_UNUSED4 3
#define VAL_BOAT_HEALTH 4
#define VAL_BOAT_MAXHEALTH 5
#define VAL_BOAT_UNUSED7 6
#define VAL_BOAT_MATERIAL 7
#define VAL_FOUNTAIN_CAPACITY 0
#define VAL_FOUNTAIN_HOWFULL 1
#define VAL_FOUNTAIN_LIQUID 2
#define VAL_FOUNTAIN_POISON 3
#define VAL_FOUNTAIN_HEALTH 4
#define VAL_FOUNTAIN_MAXHEALTH 5
#define VAL_FOUNTAIN_UNUSED7 6
#define VAL_FOUNTAIN_MATERIAL 7
#define VAL_VEHICLE_ROOM 0
#define VAL_VEHICLE_UNUSED2 1
#define VAL_VEHICLE_UNUSED3 2
#define VAL_VEHICLE_APPEAR 3
#define VAL_VEHICLE_HEALTH 4
#define VAL_VEHICLE_MAXHEALTH 5
#define VAL_VEHICLE_UNUSED7 6
#define VAL_VEHICLE_MATERIAL 7
#define VAL_HATCH_DEST 0
#define VAL_HATCH_FLAGS 1
#define VAL_HATCH_DCSKILL 2
#define VAL_HATCH_DCMOVE 3
#define VAL_HATCH_HEALTH 4
#define VAL_HATCH_MAXHEALTH 5
#define VAL_HATCH_UNUSED7 6
#define VAL_HATCH_MATERIAL 7
#define VAL_HATCH_DCLOCK 8
#define VAL_HATCH_DCHIDE 9
#define VAL_HATCH_VEHICLE_ID_HI 14
#define VAL_HATCH_VEHICLE_ID_LO 15
#define VAL_WINDOW_UNUSED1 0
#define VAL_WINDOW_UNUSED2 1
#define VAL_WINDOW_UNUSED3 2
#define VAL_WINDOW_UNUSED4 3
#define VAL_WINDOW_HEALTH 4
#define VAL_WINDOW_MAXHEALTH 5
#define VAL_WINDOW_UNUSED7 6
#define VAL_WINDOW_MATERIAL 7
#define VAL_CONTROL_UNUSED1 0
#define VAL_CONTROL_UNUSED2 1
#define VAL_CONTROL_UNUSED3 2
#define VAL_CONTROL_UNUSED4 3
#define VAL_CONTROL_HEALTH 4
#define VAL_CONTROL_MAXHEALTH 5
#define VAL_CONTROL_UNUSED7 6
#define VAL_CONTROL_MATERIAL 7
#define VAL_PORTAL_DEST 0
#define VAL_PORTAL_DCSKILL 1
#define VAL_PORTAL_DCMOVE 2
#define VAL_PORTAL_APPEAR 3
#define VAL_PORTAL_HEALTH 4
#define VAL_PORTAL_MAXHEALTH 5
#define VAL_PORTAL_UNUSED7 6
#define VAL_PORTAL_MATERIAL 7
#define VAL_PORTAL_DCLOCK 8
#define VAL_PORTAL_DCHIDE 9
#define VAL_BOARD_READ 0
#define VAL_BOARD_WRITE 1
#define VAL_BOARD_ERASE 2
#define VAL_BOARD_UNUSED4 3
#define VAL_BOARD_HEALTH 4
#define VAL_BOARD_MAXHEALTH 5
#define VAL_BOARD_UNUSED7 6
#define VAL_BOARD_MATERIAL 7
#define VAL_DOOR_DCLOCK 8
#define VAL_DOOR_DCHIDE 9
#define VAL_CORPSE_HEAD 8
#define VAL_CORPSE_RARM 9
#define VAL_CORPSE_LARM 10
#define VAL_CORPSE_RLEG 11
#define VAL_CORPSE_LLEG 12
#define VAL_GROWTH 0
#define VAL_MATGOAL 1
#define VAL_MATURITY 2
#define VAL_MAXMATURE 3
#define VAL_WATERLEVEL 6
#define VAL_SOILQ 8

#define NUM_FULLNESS 5

#define EF_ARRAY_MAX 4
#define TW_ARRAY_MAX 4

extern const char *equipment_types[NUM_WEARS + 1];
extern const char *wear_where[NUM_WEARS + 1];
extern const char *item_types[NUM_ITEM_TYPES + 1];
extern const char *wear_bits[NUM_ITEM_WEARS + 1];
extern const char *extra_bits[NUM_ITEM_FLAGS + 1];
extern const char *container_bits[NUM_CONT_FLAGS + 1];

extern const char *drinks[NUM_LIQ_TYPES + 1];
extern const char *drinknames[NUM_LIQ_TYPES + 1];
extern const char *color_liquid[NUM_LIQ_TYPES + 1];
extern int drink_aff[NUM_LIQ_TYPES][NUM_CONDITIONS];
extern const char *fullness[NUM_FULLNESS + 1];
extern const char *material_names[NUM_MATERIALS + 1];

#ifdef __cplusplus
}
#endif
