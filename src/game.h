#pragma once

#include <sys/socket.h>

#ifdef __cplusplus
extern "C" {
#endif

void game_loop(void);
void heartbeat(int heart_pulse);
void game_active_player_enter(void);
void game_active_player_leave(void);
int game_active_player_count(void);

void char_on_second(struct char_data *ch);
void char_on_mud_hour(struct char_data *ch);
void char_on_heartbeat(struct char_data *ch, int pulse);
void room_on_second(struct room_data *room);
void room_on_mud_hour(struct room_data *room);
void room_on_heartbeat(struct room_data *room, int pulse);
void obj_on_second(struct obj_data *obj);
void obj_on_mud_hour(struct obj_data *obj);
void obj_on_heartbeat(struct obj_data *obj, int pulse);

void heartbeat_legacy(int heart_pulse);
void game_legacy_process_commands(void);
void game_legacy_send_outputs(void);
void game_legacy_close_pending(void);
void game_legacy_post_tick(void);

#ifdef __cplusplus
}
#endif
