#pragma once
#include "consts/types.h"

extern "C" {
    void db_init();
    void db_cleanup();

    void db_load_counters();
    void db_save_counters();

    // Characters section.
    struct char_data* char_game_create();
    void char_game_destroy(struct char_data *ch);
    int64_t char_game_nextid();

    void char_game_activate(struct char_data *ch);
    void char_game_deactivate(struct char_data *ch);

    struct char_data* char_by_id(int64_t id);

    size_t mob_vnum_count(mob_vnum vnum);

    // Objects section.
    struct obj_data* obj_game_create();
    void obj_game_destroy(struct obj_data *obj);
    int64_t obj_game_nextid();
    void obj_game_activate(struct obj_data *obj);
    void obj_game_deactivate(struct obj_data *obj);

    struct obj_data* obj_by_id(int64_t id);

    size_t obj_vnum_count(obj_vnum vnum);

    // Rooms section
    void room_game_activate(struct room_data *room, room_vnum vnum);
    struct room_data* room_by_id(room_vnum vnum);
}