#include "dbat/structs.h"
#include "dbat/dg_scripts.h"
#include "dbat/utils.h"


std::string unit_data::getName() const {
    return name ? name : "";
}

std::string unit_data::getShortDescription() const {
    return short_description ? short_description : "";
}

std::string unit_data::getRoomDescription() const {
    return room_description ? room_description : "";
}

std::string unit_data::getLookDescription() const {
    return look_description ? look_description : "";
}


nlohmann::json unit_data::serializeUnit() {
    nlohmann::json j;

    if(vn != NOTHING) j["vn"] = vn;

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

    if(id != NOTHING) j["id"] = id;
    if(zone != NOTHING) j["zone"] = zone;

    for(auto t : trig_list) {
        auto tr = TrigRef(t);
        j["dgscripts"].push_back(tr.serialize());
    }

    return j;
}


void unit_data::deserializeUnit(const nlohmann::json& j) {
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

    if(j.contains("id")) id = j["id"];
    if(j.contains("zone")) zone = j["zone"];

}

void unit_data::deserializedgScripts(const nlohmann::json &j) {
    // iterate through the sequence of pairs.
    for(auto pair : j) {
        TrigRef ref(pair);
        if(auto t = ref.get(); t) {
            t->owner = this;
            trig_list.emplace_back(t);
        }
    }
}

void unit_data::activateContents() {
    for(auto obj : IterRef(getContents())) {
        obj->activate();
    }
}

void unit_data::deactivateContents() {
    for(auto obj : IterRef(getContents())) {
        obj->deactivate();
    }
}

double unit_data::getInventoryWeight() {
    double weight = 0;
    for(auto obj : IterRef(getContents())) {
        weight += obj->getTotalWeight();
    }
    return weight;
}

int64_t unit_data::getInventoryCount() {
    int64_t total = 0;
    for(auto obj : IterRef(getContents())) {
        total++;
    }
    return total;
}

struct obj_data* unit_data::findObject(const std::function<bool(struct obj_data*)> &func, bool working) {
    for(auto obj : IterRef(getContents())) {
        if(func(obj)) {
            if(working && !obj->isWorking()) continue;
            return obj;
        }
        if(auto p = obj->findObject(func, working); p) return p;
    }
    return nullptr;
}

struct obj_data* unit_data::findObjectVnum(obj_vnum objVnum, bool working) {
    return findObject([objVnum](auto o) {return o->vn == objVnum;}, working);
}

std::unordered_set<struct obj_data*> unit_data::gatherObjects(const std::function<bool(struct obj_data*)> &func, bool working) {
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

std::vector<std::string> unit_data::getKeywordsFor(char_data *viewer) {
    std::vector<std::string> out;
    boost::split(out, name, boost::is_space(), boost::token_compress_on);
    return;
}

std::string unit_data::getDisplayNameFor(char_data *viewer, int ana) {
    return getName();
}

std::string unit_data::getShortDescFor(char_data *viewer) {
    return getDisplayNameFor(viewer, 2);
}

std::vector<std::string> unit_data::getListPrefixesFor(char_data *viewer) {
    std::vector<std::string> out;

    if(GET_ADMLEVEL(viewer) >= ADMLVL_IMMORT) {
        out.emplace_back(fmt::format("@G[{}]@n", getUID()));
        if(vn != NOTHING) out.emplace_back(fmt::format("@G[VN:{}]@n", vn));
        if(!proto_script.empty()) out.emplace_back(fmt::format("@G[DG:{}]@n", fmt::join(proto_script, ",")));
    }

    return out;
}

std::string unit_data::getRoomPostureFor(char_data *viewer) {
    return getDisplayNameFor(viewer, 2);
}

std::string unit_data::renderRoomLineFor(char_data *viewer, bool affectLines) {
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

std::vector<std::string> unit_data::renderStatusLinesFor(char_data *viewer) {
    return {};
}

std::string unit_data::renderListLineFor(char_data* viewer) {
    auto mainLines = getListPrefixesFor(viewer);
    mainLines.emplace_back(getDisplayNameFor(viewer, 2));
    auto suffixes = getListSuffixesFor(viewer);
    // Add suffixes to the mainLines vector.
    mainLines.insert(mainLines.end(), suffixes.begin(), suffixes.end());

    // Join them.
    auto mainLine = boost::join(mainLines, " ");
}

std::vector<std::string> unit_data::getListSuffixesFor(char_data *viewer) {
    return {};
}

int unit_data::getApparentSexFor(char_data *viewer) {
    return 0;
}

std::string unit_data::getPostureString(char_data *viewer) {
    return "is here.";
}

std::string unit_data::getLocationName(const Coordinates& coords) {
    return getName();
}