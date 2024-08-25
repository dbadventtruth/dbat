/************************************************************************
 * Generic OLC Library - Rooms / genwld.c			v1.0	*
 * Original author: Levork						*
 * Copyright 1996 by Harvey Gilpin					*
 * Copyright 1997-2001 by George Greer (greerga@circlemud.org)		*
 ************************************************************************/

#include "dbat/genwld.h"
#include "dbat/utils.h"
#include "dbat/db.h"
#include "dbat/handler.h"
#include "dbat/genolc.h"
#include "dbat/shop.h"
#include "dbat/dg_olc.h"
#include "dbat/constants.h"


/*
 * This function will copy the strings so be sure you free your own
 * copies of the description, title, and such.
 */
RoomRef room_data::ref() {
    return RoomRef(this);
}

room_rnum add_room(struct room_data *room) {
    struct char_data *tch;
    struct obj_data *tobj;
    vnum j, found = false;
    room_rnum i;

    if (!room)
        return NOWHERE;

    if (world.contains(room->vn)) {
        auto &ro = world[room->vn];
            extract_script(&ro, WLD_TRIGGER);
        // TODO: update this for new location handling somehow...
        copy_room(&ro, room);

        basic_mud_log("GenOLC: add_room: Updated existing room #%d.", room->vn);
        return i;
    }

    auto &r = world[room->vn];
    r = *room;
    basic_mud_log("GenOLC: add_room: Added room %d.", room->vn);

    /*
     * Return what array entry we placed the new room in.
     */
    return found;
}

/* -------------------------------------------------------------------------- */

int delete_room(room_rnum rnum) {
    room_rnum i;
    int j;
    struct char_data *ppl, *next_ppl;
    struct obj_data *obj, *next_obj;
    struct room_data *room;

    if (!world.count(rnum))    /* Can't delete void yet. */
        return false;

    room = &world.at(rnum);

    /* This is something you might want to read about in the logs. */
    basic_mud_log("GenOLC: delete_room: Deleting room #%d (%s).", room->vn, room->name);

    if (r_mortal_start_room == rnum) {
        basic_mud_log("WARNING: GenOLC: delete_room: Deleting mortal start room!");
        r_mortal_start_room = 0;    /* The Void */
    }
    if (r_immort_start_room == rnum) {
        basic_mud_log("WARNING: GenOLC: delete_room: Deleting immortal start room!");
        r_immort_start_room = 0;    /* The Void */
    }
    if (r_frozen_start_room == rnum) {
        basic_mud_log("WARNING: GenOLC: delete_room: Deleting frozen start room!");
        r_frozen_start_room = 0;    /* The Void */
    }

    /*
     * Dump the contents of this room into the Void.  We could also just
     * extract the people, mobs, and objects here.
     */
    for (auto obj : IterRef(room->getContents())) {
        obj_from_room(obj);
        obj_to_room(obj, 0);
    }
    for (auto ppl : IterRef(room->getPeople())) {
        char_from_room(ppl);
        char_to_room(ppl, 0);
    }

        extract_script(room, WLD_TRIGGER);
    free_proto_script(room, WLD_TRIGGER);

    /*
     * Change any exit going to this room to go the void.
     * Also fix all the exits pointing to rooms above this.
     */

    for(auto &r : world) {
        for (j = 0; j < NUM_OF_DIRS; j++) {
            auto &e = r.second.dir_option[j];
            if (!e || e->to_room != rnum)
                continue;
            if ((!e->keyword || !*e->keyword) &&
                (!e->general_description || !*e->general_description)) {
                /* no description, remove exit completely */
                if (e->keyword)
                    free(e->keyword);
                if (e->general_description)
                    free(e->general_description);
                free(e);
                e = nullptr;
            } else {
                /* description is set, just point to nowhere */
                e->to_room = NOWHERE;
            }
        }

    };

    /*
     * Remove this room from all shop lists.
     */
    for (auto &[i, sh] : shop_index) {
        sh.in_room.erase(rnum);
    }

    world.erase(rnum);
    return true;
}


int save_rooms(zone_rnum zone_num) {
    return true;
}

int copy_room(struct room_data *to, struct room_data *from) {
    free_room_strings(to);
    *to = *from;
    copy_room_strings(to, from);

    return true;
}

/* -------------------------------------------------------------------------- */

/*
 * Copy strings over so bad things don't happen.  We do not free the
 * existing strings here because copy_room() did a shallow copy previously
 * and we'd be freeing the very strings we're copying.  If this function
 * is used elsewhere, be sure to free_room_strings() the 'dest' room first.
 */
int copy_room_strings(struct room_data *dest, struct room_data *source) {
    int i;

    if (dest == nullptr || source == nullptr) {
        basic_mud_log("SYSERR: GenOLC: copy_room_strings: nullptr values passed.");
        return false;
    }

    dest->look_description = str_udup(source->look_description);
    dest->name = str_udup(source->name);

    for (i = 0; i < NUM_OF_DIRS; i++) {
        if (!R_EXIT(source, i))
            continue;

        CREATE(R_EXIT(dest, i), struct room_direction_data, 1);
        *R_EXIT(dest, i) = *R_EXIT(source, i);
        if (R_EXIT(source, i)->general_description)
            R_EXIT(dest, i)->general_description = strdup(R_EXIT(source, i)->general_description);
        if (R_EXIT(source, i)->keyword)
            R_EXIT(dest, i)->keyword = strdup(R_EXIT(source, i)->keyword);
    }

    if (source->ex_description)
        copy_ex_descriptions(&dest->ex_description, source->ex_description);

    return true;
}

int free_room_strings(struct room_data *room) {
    int i;

    /* Free descriptions. */
    if (room->name)
        free(room->name);
    if (room->look_description)
        free(room->look_description);
    if (room->ex_description)
        free_ex_descriptions(room->ex_description);

    /* Free exits. */
    for (i = 0; i < NUM_OF_DIRS; i++) {
        if (room->dir_option[i]) {
            if (room->dir_option[i]->general_description)
                free(room->dir_option[i]->general_description);
            if (room->dir_option[i]->keyword)
                free(room->dir_option[i]->keyword);
            free(room->dir_option[i]);
            room->dir_option[i] = nullptr;
        }
    }

    return true;
}

room_direction_data::~room_direction_data() {
    if (general_description)
        free(general_description);
    if (keyword)
        free(keyword);
}

nlohmann::json room_direction_data::serialize() {
    nlohmann::json j;

    if(general_description && strlen(general_description)) j["general_description"] = general_description;
    if(keyword && strlen(keyword)) j["keyword"] = keyword;
    if(exit_info) j["exit_info"] = exit_info;
    if(key > 0) j["key"] = key;
	if(to_room != NOWHERE) j["to_room"] = to_room;
    if(dclock) j["dclock"] = dclock;
    if(dchide) j["dchide"] = dchide;
    if(dcskill) j["dcskill"] = dcskill;
    if(dcmove) j["dcmove"] = dcmove;
    if(failsavetype) j["failsavetype"] = failsavetype;
    if(dcfailsave) j["dcfailsave"] = dcfailsave;
    if(failroom > 0) j["failroom"] = failroom;
    if(totalfailroom > 0) j["totalfailroom"] = totalfailroom;

    return j;
}

room_direction_data::room_direction_data(const nlohmann::json &j) : room_direction_data() {
    if(j.contains("general_description")) general_description = strdup(j["general_description"].get<std::string>().c_str());
    if(j.contains("keyword")) keyword = strdup(j["keyword"].get<std::string>().c_str());
    if(j.contains("exit_info")) exit_info = j["exit_info"].get<int16_t>();
    if(j.contains("key")) key = j["key"];
    if(j.contains("to_room")) to_room = j["to_room"];
    if(j.contains("dclock")) dclock = j["dclock"];
    if(j.contains("dchide")) dchide = j["dchide"];
    if(j.contains("dcskill")) dcskill = j["dcskill"];
    if(j.contains("dcmove")) dcmove = j["dcmove"];
    if(j.contains("failsavetype")) failsavetype = j["failsavetype"];
    if(j.contains("dcfailsave")) dcfailsave = j["dcfailsave"];
    if(j.contains("failroom")) failroom = j["failroom"];
    if(j.contains("totalfailroom")) totalfailroom = j["totalfailroom"];
}


nlohmann::json room_data::serialize() {
    auto j = serialize();

    if(sector_type) j["sector_type"] = sector_type;

    for (size_t i = 0; i < room_flags.size(); ++i) {
        if (room_flags[i]) {
            j["room_flags"].push_back(i);
        }
    }

    for(auto p :proto_script) {
        if(trig_index.contains(p)) j["proto_script"].push_back(p);
    }

    return j;
}

void room_data::deserialize(const nlohmann::json& j) {
    GameEntity::deserialize(j);

    if(j.contains("sector_type")) sector_type = j["sector_type"];

    if(j.contains("dir_option")) {
        // this is an array of (<number>, <json>) pairs, with number matching the dir_option array index.
        // Thankfully we can pass the json straight into the room_direction_data constructor...
        for(auto &d : j["dir_option"]) {
            dir_option[d[0]] = new room_direction_data(d[1]);
        }
    }

    if(j.contains("room_flags")) {
        for(auto &f : j["room_flags"]) {
            room_flags.set(f.get<int>());
        }
    }

    if(j.contains("proto_script")) {
        for(auto p : j["proto_script"]) proto_script.emplace_back(p.get<trig_vnum>());
    }

    if(j.contains("dgvariables")) {
        deserializeVars(&global_vars, j["dgvariables"]);
    }
}

room_data::room_data(const nlohmann::json &j) {
    deserialize(j);
}

room_data::~room_data() {
    // fields like name are handled by the base destructor...
    // we just need to clean up exits.
    for(auto d : dir_option) {
        delete d;
    }
}


bool room_data::isActive() {
    return world.contains(vn);
}


int room_data::getDamage() {
    return dmg;
}

void room_data::activate() {
    assign_triggers(this, WLD_TRIGGER);
    for(auto t : trig_list) t->activate();

    auto r = ref();
    if(!trig_list.empty()) {
        for(auto t : trig_list) t->activate();
        if(SCRIPT_TYPES(this) & OTRIG_RANDOM)
            roomSubscriptions.subscribe("randomTriggers", r);
        if(SCRIPT_TYPES(this) & OTRIG_TIME)
            roomSubscriptions.subscribe("timeTriggers", r);
    }
    if(dmg != 0)
        roomSubscriptions.subscribe("roomRepairDamage", r);

    activateContents();
    for(auto c : IterRef(getPeople())) if(IS_NPC(c)) c->activate();
}

void room_data::deactivate() {
    roomSubscriptions.unsubscribeFromAll(ref());
}

int room_data::setDamage(int amount) {
    auto before = dmg;
    dmg = std::clamp<int>(amount, 0, 100);
    // if(dmg != before) save();
    if(dmg == 0) {
        roomSubscriptions.unsubscribe("roomRepairDamage", ref());
    } else {
        roomSubscriptions.subscribe("roomRepairDamage", ref());
    }
    return dmg;
}

int room_data::modDamage(int amount) {
    return setDamage(dmg + amount);
}

struct room_data* room_direction_data::getDestination() {
    auto found = world.find(to_room);
    if(found != world.end()) return &found->second;
    return nullptr;
}

static const std::unordered_set<int> inside_sectors = {SECT_INSIDE, SECT_UNDERWATER, SECT_IMPORTANT, SECT_SHOP, SECT_SPACE};

static const std::map<std::string, int> _dirNames = {
    {"north", NORTH},
    {"east", EAST},
    {"south", SOUTH},
    {"west", WEST},
    {"up", UP},
    {"down", DOWN},
    {"northwest", NORTHWEST},
    {"northeast", NORTHEAST},
    {"southwest", SOUTHWEST},
    {"southeast", SOUTHEAST},
    {"inside", INDIR},
    {"outside", OUTDIR}

};

std::optional<std::string> room_data::dgCallMember(const std::string& member, const std::string& arg) {
    std::string lmember = member;
    boost::to_lower(lmember);
    boost::trim(lmember);
    char bitholder[MAX_STRING_LENGTH];

    if(auto d = _dirNames.find(lmember); d != _dirNames.end()) {
        auto ex = dir_option[d->second];
        if(!ex) {
            return "";
        }
        if (!arg.empty()) {
            if (!strcasecmp(arg.c_str(), "vnum"))
                return fmt::format("{}", ex->to_room);
            else if (!strcasecmp(arg.c_str(), "key"))
                return fmt::format("{}", ex->key);
            else if (!strcasecmp(arg.c_str(), "bits")) {
                sprintbit(ex->exit_info, exit_bits, bitholder, MAX_STRING_LENGTH);
                return bitholder;
            }
            else if (!strcasecmp(arg.c_str(), "room")) {
                if (auto roomFound = world.find(ex->to_room); roomFound != world.end())
                    return fmt::format("{}", roomFound->second.getUID());
                else
                    return "";
            }
        } else /* no subfield - default to bits */
            {
                sprintbit(ex->exit_info, exit_bits, bitholder, MAX_STRING_LENGTH);
                return bitholder;
            }
    }

    return {};
}

double room_data::setEnvironment(int type, double value) {
    environment[type] = value;
    return value;
}

double room_data::modEnvironment(int type, double value) {
    environment[type] += value;
    return environment[type];
}

void room_data::clearEnvironment(int type) {
    environment.erase(type);
}

double room_data::getEnvironment(int type) {
    switch(type) {
        case ENV_GRAVITY: {
            // check for a gravity generator...
            for(auto c : IterRef(getContents())) {
                if(auto find = c->dvalue.find("gravity"); find != c->dvalue.end()) return find->second;
            }

            // what about area rules?
            if(auto env = getMatchingParentStructure(ITEM_ENVIRONMENT); env) {
                return env->getEnvironment(Coordinates{LocationType::Internal, {0,0,0}}, ENV_GRAVITY);
            }

            // special cases here..
            if (vn >= 64000 && vn <= 64006) {
                return 100.0;
            }
            if (vn >= 64007 && vn <= 64016) {
                return 300.0;
            }
            if (vn >= 64017 && vn <= 64030) {
                return 500.0;
            }
            if (vn >= 64031 && vn <= 64048) {
                return 1000.0;
            }
            if (vn >= 64049 && vn <= 64070) {
                return 5000.0;
            }
            if (vn >= 64071 && vn <= 64096) {
                return 10000.0;
            }
            if (vn == 64097) {
                return 1000.0;
            }

            return 1.0;
        }

        case ENV_WATER:
            if(geffect < 0) 
                return 100.0;
            switch(sector_type) {
                case SECT_WATER_SWIM:
                    return 50.0;
                case SECT_WATER_NOSWIM:
                    return 75.0;
                case SECT_UNDERWATER:
                    return 100.0;
            }
            break;
        case ENV_MOONLIGHT: {
            for(auto f : {ROOM_INDOORS, ROOM_UNDERGROUND, ROOM_SPACE}) if(room_flags.test(f)) return -1;
            if(inside_sectors.contains(sector_type)) return -1;
            auto planet = getMatchingParentStructure(ITEM_ENVIRONMENT);
            if(!planet || !planet->extra_flags.test(ITEM_HASMOON)) return -1;

            return MOON_TIMECHECK() ? 100.0 : 0.0;
        }
    }
    if(environment.contains(type))
        return environment[type];

    return 0.0;
}


// Location Implementation
std::string room_data::getNameAt(const Coordinates& coord) {
    if(name && strlen(name)) {
        return std::string(name);
    }
    return getUID();
}

std::optional<Destination> room_data::getDirectionalDestination(const Coordinates& coord, int dir) {
    if(!dir_option[dir]) return std::nullopt;
    return Destination(dir_option[dir]);
}

std::map<int, Destination> room_data::getDirectionalDestinations(const Coordinates& coord) {
    std::map<int, Destination> destinations;
    for(int i = 0; i < NUM_OF_DIRS; i++) {
        if(dir_option[i]) {
            destinations[i] = Destination(dir_option[i]);
        }
    }
    return destinations;
}

static std::vector<std::pair<std::pair<room_vnum, room_vnum>, std::vector<character_affect_type>>> roomRangeModifiers = {

};

static std::unordered_map<int, std::vector<character_affect_type>> roomFlagModifiers = {
    {ROOM_REGEN, {
        {APPLY_CVIT_REGEN_MULT, 2.0, ~0},
        }
    },
    {ROOM_BEDROOM, {
        {APPLY_CVIT_REGEN_MULT, 0.25, ~0},
        }
    }
};

double room_data::getModifiersForCharacter(char_data *ch, uint64_t location, uint64_t specific) {
    if(!ch) return 0.0;
    
    double total = 0.0;

    auto handleModifiers = [&](auto& modifiers) {
        for(auto& aff : modifiers) {
            if(!aff.match(location, specific)) continue;
            total += aff.modifier;
            if(aff.func) total += aff.func(ch);
        }
    };

    for(auto&[range, mod] : roomRangeModifiers) {
        if(!(vn >= range.first && vn <= range.second)) continue;
        handleModifiers(mod);
        
    }

    for(auto&[flag, mod] : roomFlagModifiers) {
        if(!room_flags.test(flag)) continue;
        handleModifiers(mod);
    }

    return total;
}


int room_data::getDamage(const Coordinates& coord) {
    return getDamage();
}

int room_data::setDamage(const Coordinates& coord, int damage) {
    return setDamage(damage);
}

int room_data::modDamage(const Coordinates& coord, int damage) {
    return modDamage(damage);
}

int room_data::getTileType(const Coordinates& coord) {
    return sector_type;
}

int room_data::getGroundEffect(const Coordinates& coord) {
    return geffect;
}

int room_data::setGroundEffect(const Coordinates& coord, int val) {
    geffect = val;
    return geffect;
}

int room_data::modGroundEffect(const Coordinates& coord, int val) {
    setGroundEffect(coord, val + getGroundEffect(coord));
    return getGroundEffect(coord);
}

SpecialFunc room_data::getSpecialFunction(const Coordinates& coord) {
    return func;
}

double room_data::getEnvironment(const Coordinates& coord, uint64_t type) {
    return 0.0;
}

double room_data::setEnvironment(const Coordinates& coord, uint64_t type, double value) {
    return 0.0;
}

void room_data::broadcastAt(const Coordinates& coord, const std::string& message) {
    for(const auto &ref : getPeople()) {
        auto ch = ref.get();
        if(!ch) continue;
        send_to_char(ch, message);
    }
}

std::vector<GameEntity*> room_data::getEntitiesAt(const Coordinates& coords) {
    std::vector<GameEntity*> out;
    for(auto [ent, _] : entities) {
        out.push_back(ent);
    }
    return out;
}

void room_data::setRoomFlag(const Coordinates& coord, int flag, bool value) {
    room_flags.set(flag, value);
}

bool room_data::getRoomFlag(const Coordinates& coord, int flag) {
    return room_flags.test(flag);
}

bool room_data::toggleRoomFlag(const Coordinates& coord, int flag) {
    room_flags.flip(flag);
    return room_flags.test(flag);
}