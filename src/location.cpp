#include "dbat/structs.h"
#include "dbat/db.h"
#include "dbat/utils.h"
#include "dbat/fight.h"
#include "dbat/vehicles.h"

// Coordinates stuff.

nlohmann::json HasCoordinates::serialize() {
    nlohmann::json j;
    j["type"] = static_cast<int>(type);
    j["x"] = x;
    j["y"] = y;
    j["z"] = z;
    return j;
}

void HasCoordinates::deserialize(const nlohmann::json& j) {
    if(j.contains("type")) type = static_cast<CoordinateType>(j.at("type").get<int>());
    if(j.contains("x")) x = j.at("x").get<int>();
    if(j.contains("y")) y = j.at("y").get<int>();
    if(j.contains("z")) z = j.at("z").get<int>();
}

HasCoordinates::HasCoordinates(const nlohmann::json& j) {
    deserialize(j);
}

// Coordinates stuff
bool Coordinates::operator==(const Coordinates& rhs) const {
    return type == rhs.type && x == rhs.x && y == rhs.y && z == rhs.z;
}


// Destination stuff.

Destination::Destination(room_direction_data* exit) {
    if(!exit) return;
    if(!world.contains(exit->to_room)) return;

    coords.type = CoordinateType::Room;
    auto &r = world.at(exit->to_room);
    location = &r;
    exit_flags = exit->exit_info;
    key = exit->key;

    if(exit->keyword && strlen(exit->keyword))
        keyword = exit->keyword;

    if(exit->general_description && strlen(exit->general_description))
        general_description = exit->general_description;

}

Destination::Destination(room_data *room) {
    if(!room) return;
    coords.type = CoordinateType::Room;
    location = room;
}

LocationStub Destination::getStub() {
    if(!location) return LocationStub();
    return LocationStub(location, coords);
}

// Location stuff.
void Location::addEntity(HasLocation* ent, const Coordinates &coords, uint64_t flags) {
    if(entities.contains(ent)) return;
    entities[ent] = coords;
    onAddEntity(ent, coords, flags);

}

void Location::onAddEntity(HasLocation* ent, const Coordinates &coords, uint64_t flags) {

}

void Location::removeEntity(HasLocation* ent, uint64_t flags) {
    if(!entities.contains(ent)) return;
    auto coord = entities.at(ent);
    entities.erase(ent);
    onRemoveEntity(ent, coord, flags);
}

void Location::onRemoveEntity(HasLocation* ent, const Coordinates& coords, uint64_t flags) {

}

void Location::relocateEntity(HasLocation* ent, const Coordinates &coords, uint64_t flags) {
    if(!entities.contains(ent)) return;
    auto oldCoords = entities.at(ent);
    entities[ent] = coords;
    onRelocateEntity(ent, oldCoords, coords, flags);
}

void Location::onRelocateEntity(HasLocation* ent, const Coordinates &oldCoords, const Coordinates &newCoords, uint64_t flags) {

}

std::vector<HasLocation*> Location::getEntitiesAt(const Coordinates& coords) {
    return {};
}

SpecialFunc Location::getSpecialFunction(const Coordinates& coord) {
    return nullptr;
}

int Location::getDamage(const Coordinates& coord) {
    return 0;
}

int Location::setDamage(const Coordinates& coord, int damage) {
    return 0;
}

int Location::modDamage(const Coordinates& coord, int damage) {
    return setDamage(coord, damage + getDamage(coord));
}


double Location::getEnvironment(const Coordinates& coord, uint64_t type) {
    return 0.0;
}

double Location::setEnvironment(const Coordinates& coord, uint64_t type, double value) {
    return 0.0;
}

double Location::modEnvironment(const Coordinates& coord, uint64_t type, double value) {
    return setEnvironment(coord, type, value + getEnvironment(coord, type));
}

void Location::clearEnvironment(const Coordinates& coord, uint64_t type) {
    return;
}

int Location::getTileType(const Coordinates& coord) {
    return 0;
}

std::string Location::printTileType(const Coordinates& coord) {
    return " ";
}

int Location::getGroundEffect(const Coordinates& coord) {
    return 0;
}

int Location::setGroundEffect(const Coordinates& coord, int val) {
    return 0;
}

int Location::modGroundEffect(const Coordinates& coord, int val) {
    return 0;
}

std::optional<Coordinates> Location::getCoordinatesForEntity(HasLocation *ent) {
    if(entities.contains(ent)) {
        return entities.at(ent);
    }
    return std::nullopt;
}

void Location::broadcastAt(const Coordinates& coord, const std::string& message) {
    return;
}

void Location::setRoomFlag(const Coordinates& coord, int flag, bool value) {
    return;
}

bool Location::getRoomFlag(const Coordinates& coord, int flag) {
    return false;
}

bool Location::toggleRoomFlag(const Coordinates& coord, int flag) {
    return false;
}

std::vector<ObjRef> Location::getContents() {
    std::vector<ObjRef> out;
    for(auto &[ent, coords] : entities) {
        if(auto obj = dynamic_cast<obj_data*>(ent); obj) {
            out.emplace_back(obj);
        }
    }
    return out;
}

std::vector<CharRef> Location::getPeople() {
    std::vector<CharRef> out;
    for(auto &[ent, coords] : entities) {
        if(auto ch = dynamic_cast<char_data*>(ent); ch) {
            out.emplace_back(ch);
        }
    }
    return out;
}

std::optional<Destination> Location::getDirectionalDestination(const Coordinates& coord, int dir) {
    return {};
}

std::map<int, Destination> Location::getDirectionalDestinations(const Coordinates& coord) {
    return {};
}

std::optional<Destination> Location::getLaunchDestination(const Coordinates& coord) {
    return {};
}

double Location::getModifiersForCharacter(char_data *ch, uint64_t location, uint64_t specific) {
    return 0.0;
}