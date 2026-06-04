#pragma once
#include "consts/types.h"
#include "consts/roomflags.h"

#ifdef __cplusplus
extern "C" {
#endif

// Exit API implemented in rooms_api.zig
struct room_data *exit_dest_get(struct room_direction_data *exit);
const char *exit_general_description_get(struct room_direction_data *exit);
void exit_general_description_set(struct room_direction_data *exit,
                                  const char *desc);
const char *exit_keyword_get(struct room_direction_data *exit);
void exit_keyword_set(struct room_direction_data *exit, const char *keyword);
int16_t exit_info_get(struct room_direction_data *exit);
void exit_info_set(struct room_direction_data *exit, int16_t info);
obj_vnum exit_key_get(struct room_direction_data *exit);
void exit_key_set(struct room_direction_data *exit, obj_vnum key);
room_vnum exit_to_room_vnum_get(struct room_direction_data *exit);
void exit_to_room_vnum_set(struct room_direction_data *exit, room_vnum to_room);
int exit_dclock_get(struct room_direction_data *exit);
void exit_dclock_set(struct room_direction_data *exit, int dclock);
int exit_dchide_get(struct room_direction_data *exit);
void exit_dchide_set(struct room_direction_data *exit, int dchide);
int exit_dcskill_get(struct room_direction_data *exit);
void exit_dcskill_set(struct room_direction_data *exit, int dcskill);
int exit_dcmove_get(struct room_direction_data *exit);
void exit_dcmove_set(struct room_direction_data *exit, int dcmove);
int exit_failsavetype_get(struct room_direction_data *exit);
void exit_failsavetype_set(struct room_direction_data *exit, int failsavetype);
int exit_dcfailsave_get(struct room_direction_data *exit);
void exit_dcfailsave_set(struct room_direction_data *exit, int dcfailsave);
int exit_failroom_get(struct room_direction_data *exit);
void exit_failroom_set(struct room_direction_data *exit, room_vnum failroom);
int exit_totalfailroom_get(struct room_direction_data *exit);
void exit_totalfailroom_set(struct room_direction_data *exit,
                            room_vnum totalfailroom);
bool exit_flagged(struct room_direction_data *exit, int pos);
bool exit_flag_toggle(struct room_direction_data *exit, int pos);
void exit_flag_set(struct room_direction_data *exit, int pos, bool value);

// Rooms API functions, implemented in rooms_api.zig
room_vnum room_id_get(struct room_data *room);
void room_id_set(struct room_data *room, room_vnum id);
room_vnum room_vnum_get(struct room_data *room);
void room_vnum_set(struct room_data *room, room_vnum vnum);

zone_vnum room_zone_vnum_get(struct room_data *room);
struct zone_data *room_zone_get(struct room_data *room);
void room_zone_set(struct room_data *room, zone_vnum vnum);
int room_sector_type_get(struct room_data *room);
void room_sector_type_set(struct room_data *room, int sector_type);
const char *room_name_get(struct room_data *room);
void room_name_set(struct room_data *room, const char *name);
const char *room_description_get(struct room_data *room);
void room_description_set(struct room_data *room, const char *description);
struct extra_descr_data *room_ex_description_get(struct room_data *room);
int room_flagged(struct room_data *room, int pos);
bool room_flag_toggle(struct room_data *room, int pos);
void room_flag_set(struct room_data *room, int pos, bool value);
uint16_t room_light_get(struct room_data *room);
void room_light_mod(struct room_data *room, int16_t delta);
void room_light_set(struct room_data *room, uint16_t light);
SpecialFunc room_func_get(struct room_data *room);
void room_func_set(struct room_data *room, SpecialFunc func);
int room_timed_get(struct room_data *room);
void room_timed_mod(struct room_data *room, int delta);
void room_timed_set(struct room_data *room, int timed);
int room_dmg_get(struct room_data *room);
void room_dmg_mod(struct room_data *room, int delta);
void room_dmg_set(struct room_data *room, int dmg);
int room_gravity_get(struct room_data *room);
void room_gravity_mod(struct room_data *room, int delta);
void room_gravity_set(struct room_data *room, int gravity);
int room_geffect_get(struct room_data *room);
void room_geffect_mod(struct room_data *room, int delta);
void room_geffect_set(struct room_data *room, int geffect);
struct trig_proto_list* room_proto_script_get(struct room_data *room);

void room_send_text(struct room_data *room, const char *text);
void room_send_textf(struct room_data *room, const char *format, ...);

// Return true to continue iteration. Return false to stop.

struct room_direction_data *room_dir_option_get(struct room_data *room,
                                                int dir);
struct char_data *room_people_get(struct room_data *room);
struct obj_data *room_contents_get(struct room_data *room);
struct script_data *room_script_get(struct room_data *room);
struct script_data *room_script_ensure(struct room_data *room);
void room_script_set(struct room_data *room, struct script_data *script);

#ifdef __cplusplus
}
#endif
