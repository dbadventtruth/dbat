#include "dbat/structs.h"
#include "dbat/dg_scripts.h"
#include "dbat/utils.h"


std::string GameEntity::getName() const {
    return name ? name : "";
}

std::string GameEntity::getShortDescription() const {
    return short_description ? short_description : "";
}

std::string GameEntity::getRoomDescription() const {
    return room_description ? room_description : "";
}

std::string GameEntity::getLookDescription() const {
    return look_description ? look_description : "";
}


nlohmann::json GameEntity::serialize() {
    nlohmann::json j;

    if(vn != NOTHING) j["vn"] = vn;
    j["type"] = type;

    if(!slug.empty()) j["slug"] = slug;

    if(!(type & ENT_PROTOTYPE)) {
        j["id"] = id;
        j["creationTime"] = creationTime;
    }

    if(zone != NOTHING) j["zone"] = zone;

    if(name && strlen(name)) j["name"] = name;
    if(room_description && strlen(room_description)) j["room_description"] = room_description;
    if(look_description && strlen(look_description)) j["look_description"] = look_description;
    if(short_description && strlen(short_description)) j["short_description"] = short_description;

    for(auto ex = ex_description; ex; ex = ex->next) {
        if(ex->keyword && strlen(ex->keyword) && ex->description && strlen(ex->description)) {
            nlohmann::json p;
            p.push_back(ex->keyword);
            p.push_back(ex->description);
            j["ex_description"].push_back(p);
        }
    }

    for(auto t : trig_list) {
        j["dgscripts"].push_back(t->id);
    }

    if(global_vars)
        j["dgvariables"] = serializeVars(global_vars);

    return j;
}


void GameEntity::deserialize(const nlohmann::json& j) {
    if(j.contains("type")) type = j["type"];

    if(j.contains("id")) id = j["id"];
    if(j.contains("creationTime")) creationTime = j["creationTime"];
    if(j.contains("zone")) zone = j["zone"];
    if(j.contains("vn")) vn = j["vn"];

    if(j.contains("name")) {
        if(name) free(name);
        name = strdup(j["name"].get<std::string>().c_str());
    }
    if(j.contains("room_description")) {
        if(room_description) free(room_description);
        room_description = strdup(j["room_description"].get<std::string>().c_str());
    }
    if(j.contains("look_description")) {
        if(look_description) free(look_description);
        look_description = strdup(j["look_description"].get<std::string>().c_str());
    }
    if(j.contains("short_description")) {
        if(short_description) free(short_description);
        short_description = strdup(j["short_description"].get<std::string>().c_str());
    }

    if(j.contains("ex_description")) {
        auto &e = j["ex_description"];
        for(auto ex = e.rbegin(); ex != e.rend(); ex++) {
            auto new_ex = new extra_descr_data();
            new_ex->keyword = strdup((*ex)[0].get<std::string>().c_str());
            new_ex->description = strdup((*ex)[1].get<std::string>().c_str());
            new_ex->next = ex_description;
            ex_description = new_ex;
        }
    }

    if(type & ENT_PROTOTYPE || type & ENT_ROOM) {
        if(j.contains("proto_script")) {
            for(auto p : j["proto_script"]) proto_script.emplace_back(p.get<trig_vnum>());
        }
    } else {
        if(j.contains("dgvariables")) {
            deserializeVars(&global_vars, j["dgvariables"]);
        }
    }

}

void GameEntity::deserializedgScripts(const nlohmann::json &j) {
    // iterate through the sequence of pairs.
    for(auto tid : j) {
        if(auto find  = trig_data::instances.find(tid); find != trig_data::instances.end()) {
            auto t = *find;
            t.second->owner = this;
            trig_list.emplace_back(t.second);
        }
    }
}

void GameEntity::deserializeRelations(const nlohmann::json& j) {

}

nlohmann::json GameEntity::serializeRelations() {
    nlohmann::json j;
    return j;
}

void GameEntity::activateContents() {
    for(auto obj : IterRef(getContents())) {
        obj->activate();
    }
}

void GameEntity::deactivateContents() {
    for(auto obj : IterRef(getContents())) {
        obj->deactivate();
    }
}

double GameEntity::getInventoryWeight() {
    double weight = 0;
    for(auto obj : IterRef(getContents())) {
        weight += obj->getTotalWeight();
    }
    return weight;
}

int64_t GameEntity::getInventoryCount() {
    int64_t total = 0;
    for(auto obj : IterRef(getContents())) {
        total++;
    }
    return total;
}

struct obj_data* GameEntity::findObject(const std::function<bool(struct obj_data*)> &func, bool working) {
    for(auto obj : IterRef(getContents())) {
        if(func(obj)) {
            if(working && !obj->isWorking()) continue;
            return obj;
        }
        if(auto p = obj->findObject(func, working); p) return p;
    }
    return nullptr;
}

struct obj_data* GameEntity::findObjectVnum(obj_vnum objVnum, bool working) {
    return findObject([objVnum](auto o) {return o->vn == objVnum;}, working);
}

std::unordered_set<struct obj_data*> GameEntity::gatherObjects(const std::function<bool(struct obj_data*)> &func, bool working) {
    std::unordered_set<struct obj_data*> out;
    for(auto obj : IterRef(getContents())) {
        if(func(obj)) {
            if(working && !obj->isWorking()) continue;
            out.insert(obj);
        }
        auto contents = obj->gatherObjects(func, working);
        out.insert(contents.begin(), contents.end());
    }
    return out;
}

// ASEventVariables implementation
void EventVariables::setCharacter(const std::string &name, CharRef character) {
    characters[name] = character;
}

CharRef EventVariables::getCharacter(const std::string &name) const {
    auto it = characters.find(name);
    if(it == characters.end()) return {};
    return it->second;
}

void EventVariables::clearCharacter(const std::string &name) {
    characters.erase(name);
}

void EventVariables::setObject(const std::string &name, ObjRef object) {
    objects[name] = object;
}

ObjRef EventVariables::getObject(const std::string &name) const {
    auto it = objects.find(name);
    if(it == objects.end()) return {};
    return it->second;
}

void EventVariables::clearObject(const std::string &name) {
    objects.erase(name);
}

void EventVariables::setRoom(const std::string &name, RoomRef room) {
    rooms[name] = room;
}

RoomRef EventVariables::getRoom(const std::string &name) const {
    auto it = rooms.find(name);
    if(it == rooms.end()) return {};
    return it->second;
}

void EventVariables::clearRoom(const std::string &name) {
    rooms.erase(name);
}

void EventVariables::setString(const std::string &name, const std::string &value) {
    strings[name] = value;
}

std::string EventVariables::getString(const std::string &name) const {
    auto it = strings.find(name);
    if(it == strings.end()) return "";
    return it->second;
}

void EventVariables::clearString(const std::string &name) {
    strings.erase(name);
}

void EventVariables::setInt(const std::string &name, int64_t value) {
    ints[name] = value;
}

int64_t EventVariables::getInt(const std::string &name) const {
    auto it = ints.find(name);
    if(it == ints.end()) return 0;
    return it->second;
}

void EventVariables::clearInt(const std::string &name) {
    ints.erase(name);
}

void EventVariables::setDouble(const std::string &name, double value) {
    doubles[name] = value;
}

double EventVariables::getDouble(const std::string &name) const {
    auto it = doubles.find(name);
    if(it == doubles.end()) return 0.0;
    return it->second;
}

void EventVariables::clearDouble(const std::string &name) {
    doubles.erase(name);
}

void EventVariables::clear() {
    characters.clear();
    objects.clear();
    rooms.clear();
    strings.clear();
    ints.clear();
    doubles.clear();
}

std::vector<std::string> GameEntity::getKeywordsFor(char_data *viewer) {
    std::vector<std::string> out;
    boost::split(out, name, boost::is_space(), boost::token_compress_on);
    return;
}

std::string GameEntity::getDisplayNameFor(char_data *viewer, int ana) {
    return getName();
}

std::string GameEntity::getShortDescFor(char_data *viewer) {
    return getDisplayNameFor(viewer, 2);
}

std::vector<std::string> GameEntity::getListPrefixesFor(char_data *viewer) {
    std::vector<std::string> out;

    if(GET_ADMLEVEL(viewer) >= ADMLVL_IMMORT) {
        out.emplace_back(fmt::format("@G[{}]@n", getUID()));
        if(vn != NOTHING) out.emplace_back(fmt::format("@G[VN:{}]@n", vn));
        if(!proto_script.empty()) out.emplace_back(fmt::format("@G[DG:{}]@n", fmt::join(proto_script, ",")));
    }

    return out;
}

std::string GameEntity::getRoomPostureFor(char_data *viewer) {
    return getDisplayNameFor(viewer, 2);
}

std::string GameEntity::renderRoomLineFor(char_data *viewer, bool affectLines) {
    auto mainLines = getListPrefixesFor(viewer);
    mainLines.emplace_back(getRoomPostureFor(viewer));
    auto suffixes = getListSuffixesFor(viewer);
    // Add suffixes to the mainLines vector.
    mainLines.insert(mainLines.end(), suffixes.begin(), suffixes.end());

    // Join them.
    auto mainLine = boost::join(mainLines, " ");

    if(!affectLines)
        return mainLine;

    auto affLines = renderStatusLinesFor(viewer);
    return boost::join(mainLines, " ") + "\r\n" + boost::join(affLines, "\r\n");
}

std::vector<std::string> GameEntity::renderStatusLinesFor(char_data *viewer) {
    return {};
}

std::string GameEntity::renderListLineFor(char_data* viewer) {
    auto mainLines = getListPrefixesFor(viewer);
    mainLines.emplace_back(getDisplayNameFor(viewer, 2));
    auto suffixes = getListSuffixesFor(viewer);
    // Add suffixes to the mainLines vector.
    mainLines.insert(mainLines.end(), suffixes.begin(), suffixes.end());

    // Join them.
    auto mainLine = boost::join(mainLines, " ");
}

std::vector<std::string> GameEntity::getListSuffixesFor(char_data *viewer) {
    return {};
}

int GameEntity::getApparentSexFor(char_data *viewer) {
    return 0;
}

std::string GameEntity::getPostureString(char_data *viewer) {
    return "is here.";
}

std::string GameEntity::getNameAt(const Coordinates& coords) {
    return getName();
}

int64_t GameEntity::getID() const {
    return id;
}

void GameEntity::setID(int64_t newID) {
    id = newID;
}

std::string GameEntity::getUID() const {
    return fmt::format("{}{}", UID_CHAR, id);
}

int GameEntity::getType() const {
    return type;
}

void GameEntity::setType(int newType) {
    type = newType;
}

std::string GameEntity::getSlug() const {
    if(type & ENT_PROTOTYPE) {
        if(type & ENT_CHARACTER)
            return fmt::format("mob_proto_{}", vn);
        else if(type & ENT_OBJECT)
            return fmt::format("obj_proto_{}", vn);
    }
    return fmt::format("entity_{}", id);
}

time_t GameEntity::getCreationTime() const {
    return creationTime;
}

void GameEntity::setCreationTime(time_t newTime) {
    creationTime = newTime;
}

GameEntity* GameEntity::getMatchingParentLocation(const std::function<bool(GameEntity*)>& f) {
    std::set<GameEntity*> seen;
    auto loc = getLocation();
    while(loc.entity) {
        if(seen.count(loc.entity)) break;
        seen.insert(loc.entity);
        if(f(loc.entity)) return loc.entity;
        loc = loc.entity->getLocation();
    }
    return nullptr;
}

obj_data* GameEntity::getMatchingParentStructure(int flag) {
    auto isCorrect = [flag](GameEntity* ent) {
        if(auto o = dynamic_cast<obj_data*>(ent); o) {
            if(o->type_flag == ITEM_STRUCTURE && o->extra_flags.test(flag))
            return true;
        } else 
            return false;
    };
    return dynamic_cast<obj_data*>(getMatchingParentLocation(isCorrect));
}