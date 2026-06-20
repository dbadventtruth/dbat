#pragma once

#ifdef __cplusplus
extern "C" {
#endif

/* Affect bits: used in char_data.affected_by */
/* WARNING: In the world files, NEVER set the bits marked "R" ("Reserved") */
// ENUM: AffectFlags
typedef enum {
    AFF_DONTUSE       = 0,  /* DON'T USE! 		*/
    AFF_BLIND         = 1,  /* (R) Char is blind         */
    AFF_INVISIBLE     = 2,  /* Char is invisible         */
    AFF_DETECT_ALIGN  = 3,  /* Char is sensitive to align*/
    AFF_DETECT_INVIS  = 4,  /* Char can see invis chars  */
    AFF_DETECT_MAGIC  = 5,  /* Char is sensitive to magic*/
    AFF_SENSE_LIFE    = 6,  /* Char can sense hidden life*/
    AFF_WATERWALK     = 7,  /* Char can walk on water    */
    AFF_SANCTUARY     = 8,  /* Char protected by sanct.  */
    AFF_GROUP         = 9,  /* (R) Char is grouped       */
    AFF_CURSE         = 10, /* Char is cursed  - converted to conditions          */
    AFF_INFRAVISION   = 11, /* Char can see in dark      */
    AFF_POISON        = 12, /* (R) Char is poisoned - Converted to Condition      */
    AFF_WEAKENED_STATE = 13, /* Char protected from evil  */
    AFF_PROTECT_GOOD  = 14, /* Char protected from good  */
    AFF_SLEEP         = 15, /* (R) Char magically asleep */
    AFF_NOTRACK       = 16, /* Char can't be tracked     */
    AFF_UNDEAD        = 17, /* Char is undead 		*/
    AFF_PARALYZE      = 18, /* Char is paralized		*/
    AFF_SNEAK         = 19, /* Char can move quietly     */
    AFF_HIDE          = 20, /* Char is hidden            */
    AFF_UNUSED20      = 21, /* Room for future expansion */
    AFF_CHARM         = 22, /* Char is charmed         	*/
    AFF_FLYING        = 23, /* Char is flying         	*/
    AFF_WATERBREATH   = 24, /* Char can breath non O2    */
    AFF_ANGELIC       = 25, /* Char is an angelic being  */
    AFF_ETHEREAL      = 26, /* Char is ethereal          */
    AFF_MAGICONLY     = 27, /* Char only hurt by magic   */
    AFF_NEXTPARTIAL   = 28, /* Next action cannot be full*/
    AFF_NEXTNOACTION  = 29, /* Next action cannot attack (took full action between rounds) */
    AFF_STUNNED       = 30, /* Char is stunned		*/
    AFF_TAMED         = 31, /* Char has been tamed	*/
    AFF_CDEATH        = 32, /* Char is undergoing creeping death */
    AFF_SPIRIT        = 33, /* Char has no body          */
    AFF_STONESKIN     = 34, /* Char has temporary DR     */
    AFF_SUMMONED      = 35, /* Char is summoned (i.e. transient */
    AFF_CELESTIAL     = 36, /* Char is celestial         */
    AFF_FIENDISH      = 37, /* Char is fiendish          */
    AFF_FIRE_SHIELD   = 38, /* Char has fire shield      */
    AFF_LOW_LIGHT     = 39, /* Char has low light eyes   */
    AFF_ZANZOKEN      = 40, /* Char is ready to zanzoken */
    AFF_KNOCKED       = 41, /* Char is knocked OUT!      */
    AFF_MIGHT         = 42, /* Strength +3               */
    AFF_FLEX          = 43, /* Agility +3                */
    AFF_GENIUS        = 44, /* Intelligence +3           */
    AFF_BLESS         = 45, /* Bless for better regen    */
    AFF_BURNT         = 46, /* Disintergrated corpse     */
    AFF_BURNED        = 47, /* Burned by honoo or similar skill */
    AFF_MBREAK        = 48, /* Can't charge while flagged */
    AFF_HASS          = 49, /* Does double punch damage  */
    AFF_FUTURE        = 50, /* Future Sight */
    AFF_PARA          = 51, /* Real Paralyze */
    AFF_INFUSE        = 52, /* Ki infused attacks */
    AFF_ENLIGHTEN     = 53, /* Enlighten */
    AFF_FROZEN        = 54, /* They got frozededed */
    AFF_FIRESHIELD    = 55, /* They have a blazing personality */
    AFF_ENSNARED      = 56, /* They have silk ensnaring their arms! */
    AFF_HAYASA        = 57, /* They are speedy!                */
    AFF_PURSUIT       = 58, /* Being followed */
    AFF_WITHER        = 59, /* Their body is withered */
    AFF_HYDROZAP      = 60, /* Custom Skill Kanso Suru - removed */
    AFF_POSITION      = 61, /* Better combat position */
    AFF_SHOCKED       = 62, /* Psychic Shock          */
    AFF_METAMORPH     = 63, /* Dark Metamorphosis - COnverted to Condition */
    AFF_HEALGLOW      = 64, /* Healing Glow */
    AFF_EARMOR        = 65, /* Ethereal Armor */
    AFF_ECHAINS       = 66, /* Ethereal Chains */
    AFF_WUNJO         = 67, /* Wunjo rune */
    AFF_POTENT        = 68, /* Purisaz rune */
    AFF_ASHED         = 69, /* Leaves ash */
    AFF_PUKED         = 70,
    AFF_LIQUEFIED     = 71,
    AFF_SHELL         = 72,
    AFF_IMMUNITY      = 73,
    AFF_SPIRITCONTROL = 74,
    AFF_KYODAIKA      = 75, /* Kyodaika - Converted to Condition */
    AFF_STARPHASE     = 76, /* Converted to Condition */
    AFF_SPECIAL_POSE  = 77, /* Converted to Condition */
    AFF_SHADOW_STITCH = 78,
} AffectFlags;
// End Enum: AffectFlags

#define NUM_AFF_FLAGS 79
#define AF_ARRAY_MAX 4

extern const char *affected_bits[NUM_AFF_FLAGS + 1];

#ifdef __cplusplus
}
#endif
