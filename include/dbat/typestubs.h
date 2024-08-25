#pragma once

class GameEntity;
struct room_direction_data;
struct zone_data;
struct reset_com;
struct char_data;
struct obj_data;
struct room_data;
struct shop_buy_data;
struct command_info;
struct descriptor_data;
struct account_data;
struct player_data;

class CharRef;
class ObjRef;
class RoomRef;
class Location;

namespace race {
    class Race;

    struct transform_bonus;
}

namespace sensei {
    class Sensei;
}

namespace net {
    class Connection;
}

namespace ang {
    class ASEvent;
    class ASEventPrototype;
}