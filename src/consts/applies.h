#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Modifier constants used with obj affects ('A' fields) */
typedef enum {
    APPLY_NONE       = 0,  /* No effect			*/
    APPLY_STR        = 1,  /* Apply to strength		*/
    APPLY_DEX        = 2,  /* Apply to dexterity		*/
    APPLY_INT        = 3,  /* Apply to intelligence	*/
    APPLY_WIS        = 4,  /* Apply to wisdom		*/
    APPLY_CON        = 5,  /* Apply to constitution	*/
    APPLY_CHA        = 6,  /* Apply to charisma		*/
    APPLY_CLASS      = 7,  /* Reserved			*/
    APPLY_LEVEL      = 8,  /* Reserved			*/
    APPLY_AGE        = 9,  /* Apply to age			*/
    APPLY_CHAR_WEIGHT = 10, /* Apply to weight		*/
    APPLY_CHAR_HEIGHT = 11, /* Apply to height		*/
    APPLY_MANA       = 12, /* Apply to max mana		*/
    APPLY_HIT        = 13, /* Apply to max hit points	*/
    APPLY_MOVE       = 14, /* Apply to max move points	*/
    APPLY_GOLD       = 15, /* Reserved			*/
    APPLY_EXP        = 16, /* Reserved			*/
    APPLY_AC         = 17, /* Apply to Armor Class		*/
    APPLY_ACCURACY   = 18, /* Apply to accuracy		*/
    APPLY_DAMAGE     = 19, /* Apply to damage 		*/
    APPLY_REGEN      = 20, /* Regen Rate Buffed            */
    APPLY_TRAIN      = 21, /* Skill training rate buffed   */
    APPLY_LIFEMAX    = 22, /* Life Force max buffed        */
    APPLY_UNUSED3    = 23, /* Unused			*/
    APPLY_UNUSED4    = 24, /* Unused			*/
    APPLY_RACE       = 25, /* Apply to race                */
    APPLY_TURN_LEVEL = 26, /* Apply to turn undead         */
    APPLY_SPELL_LVL_0 = 27, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_1 = 28, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_2 = 29, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_3 = 30, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_4 = 31, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_5 = 32, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_6 = 33, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_7 = 34, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_8 = 35, /* Apply to spell cast per day  */
    APPLY_SPELL_LVL_9 = 36, /* Apply to spell cast per day  */
    APPLY_KI          = 37, /* Apply to max ki		*/
    APPLY_FORTITUDE   = 38, /* Apply to fortitue save	*/
    APPLY_REFLEX      = 39, /* Apply to reflex save		*/
    APPLY_WILL        = 40, /* Apply to will save		*/
    APPLY_SKILL       = 41, /* Apply to a specific skill    */
    APPLY_FEAT        = 42, /* Apply to a specific feat     */
    APPLY_ALLSAVES    = 43, /* Apply to all 3 save types 	*/
    APPLY_RESISTANCE  = 44, /* Apply to resistance	 	*/
    APPLY_ALL_STATS   = 45, /* Apply to all attributes	*/
} ApplyType;

#define NUM_APPLIES 46

extern const char *apply_types[NUM_APPLIES + 1];

#ifdef __cplusplus
}
#endif
