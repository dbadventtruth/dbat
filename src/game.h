#pragma once

#include <sys/socket.h>

#ifdef __cplusplus
extern "C" {
#endif

void game_loop(void);
void game_active_player_enter(void);
void game_active_player_leave(void);
int game_active_player_count(void);

void game_legacy_process_commands(void);
void game_legacy_send_outputs(void);
void game_legacy_close_pending(void);
void game_legacy_post_tick(void);

#ifdef __cplusplus
}
#endif
