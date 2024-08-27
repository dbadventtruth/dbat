#include "dbat/structs.h"
#include "dbat/db.h"
#include "dbat/utils.h"
#include "dbat/fight.h"
#include "dbat/vehicles.h"

// Coordinates stuff.

nlohmann::json Point::serialize() const {
    nlohmann::json j;
    j["x"] = x;
    j["y"] = y;
    j["z"] = z;
    return j;
}

void Point::deserialize(const nlohmann::json& j) {
    if(j.contains("x")) x = j.at("x").get<int>();
    if(j.contains("y")) y = j.at("y").get<int>();
    if(j.contains("z")) z = j.at("z").get<int>();
}

Point::Point(const nlohmann::json& j) {
    deserialize(j);
}

bool Point::operator==(const Point& other) const {
    return x == other.x && y == other.y && z == other.z;
}


nlohmann::json Location::serialize() const {
    nlohmann::json j;
    j["type"] = static_cast<int>(type);
    if(entity) j["entity"] = entity->getID();
    j["point"] = point.serialize();
    return j;
}

Location::Location(const nlohmann::json& j) {
    deserialize(j);
}

void Location::deserialize(const nlohmann::json& j) {
    if(j.contains("type")) type = static_cast<LocationType>(j.at("type").get<int>());
    
    if(j.contains("entity")) {
        auto entityID = j.at("entity").get<int64_t>();
        if(GameEntity::instances.contains(entityID))
            entity = GameEntity::instances.at(entityID);
        else {
            basic_mud_log("Location::deserialize: entity not found for ID %ld", entityID);
        }
    }
    if(j.contains("point")) point.deserialize(j.at("point"));
}

bool Location::operator==(const Location& other) const {
    return type == other.type && entity == other.entity && point == other.point;
}

Location::operator bool() const {
    return entity != nullptr;
}

Coordinates Location::getCoordinates() const {
    return {type, point};
}

bool Coordinates::operator==(const Coordinates& other) const {
    return type == other.type && point == other.point;
}

// Destination stuff.

Destination::Destination(room_direction_data* exit) {
    if(!exit) return;
    if(!world.contains(exit->to_room)) return;

    location.type = LocationType::Room;
    auto &r = world.at(exit->to_room);
    location.entity = &r;
    exit_flags = exit->exit_info;
    key = exit->key;
    dcskill = exit->dcskill;
    dcmove = exit->dcmove;

    if(exit->keyword && strlen(exit->keyword))
        keyword = exit->keyword;

    if(exit->general_description && strlen(exit->general_description))
        general_description = exit->general_description;

}

Destination::Destination(room_data *room) {
    if(!room) return;
    location.type = LocationType::Room;
    location.entity = room;
}


// Location stuff.
void GameEntity::addEntity(GameEntity* ent, const Coordinates &coords, uint64_t flags) {
    if(entities.contains(ent)) return;
    entities[ent] = coords;
    auto &grid = entityGrid[coords];
    grid.push_back(ent);
    onAddEntity(ent, coords, flags);
}

void GameEntity::onAddEntity(GameEntity* ent, const Coordinates &coords, uint64_t flags) {

}

void GameEntity::removeEntity(GameEntity* ent, uint64_t flags) {
    auto it = entities.find(ent);
    if(it == entities.end()) return; // Entity not found, nothing to do

    auto coord = it->second;
    entities.erase(it);

    auto gridIt = entityGrid.find(coord);
    if(gridIt != entityGrid.end()) {
        auto& vec = gridIt->second;
        auto found = std::find(vec.begin(), vec.end(), ent);
        if(found != vec.end()) {
            vec.erase(found);
            if(vec.empty()) {
                entityGrid.erase(gridIt);
            }
        }
    }

    onRemoveEntity(ent, coord, flags);
}

void GameEntity::onRemoveEntity(GameEntity* ent, const Coordinates& coords, uint64_t flags) {

}

void GameEntity::relocateEntity(GameEntity* ent, const Coordinates &coords, uint64_t flags) {
    if(!entities.contains(ent)) return;
    auto oldCoords = entities.at(ent);
    if(oldCoords == coords) return;
    entities[ent] = coords;

    auto gridIt = entityGrid.find(oldCoords);
    if(gridIt != entityGrid.end()) {
        auto& vec = gridIt->second;
        auto found = std::find(vec.begin(), vec.end(), ent);
        if(found != vec.end()) {
            vec.erase(found);
            if(vec.empty()) {
                entityGrid.erase(gridIt);
            }
        }
    }
    auto &grid = entityGrid[coords];
    grid.push_back(ent);

    onRelocateEntity(ent, oldCoords, coords, flags);
}

void GameEntity::onRelocateEntity(GameEntity* ent, const Coordinates &oldCoords, const Coordinates &newCoords, uint64_t flags) {

}


// hooks for hasLocation
void GameEntity::onAddedToLocation(const Location& loc) {

}

void GameEntity::onRemovedFromLocation(const Location& loc) {

}

void GameEntity::onRelocatedWithinLocation(const Coordinates& oldLoc, const Coordinates& newLoc) {

}



std::vector<GameEntity*> GameEntity::getEntitiesAt(const Coordinates& coords) {
    return {};
}

SpecialFunc GameEntity::getSpecialFunction(const Coordinates& coord) {
    return nullptr;
}

int GameEntity::getDamage(const Coordinates& coord) {
    return 0;
}

int GameEntity::setDamage(const Coordinates& coord, int damage) {
    return 0;
}

int GameEntity::modDamage(const Coordinates& coord, int damage) {
    return setDamage(coord, damage + getDamage(coord));
}


double GameEntity::getEnvironment(const Coordinates& coord, uint64_t type) {
    return 0.0;
}

double GameEntity::setEnvironment(const Coordinates& coord, uint64_t type, double value) {
    return 0.0;
}

double GameEntity::modEnvironment(const Coordinates& coord, uint64_t type, double value) {
    return setEnvironment(coord, type, value + getEnvironment(coord, type));
}

void GameEntity::clearEnvironment(const Coordinates& coord, uint64_t type) {
    return;
}

int GameEntity::getTileType(const Coordinates& coord) {
    return 0;
}

std::string GameEntity::printTileType(const Coordinates& coord) {
    return " ";
}

int GameEntity::getGroundEffect(const Coordinates& coord) {
    return 0;
}

int GameEntity::setGroundEffect(const Coordinates& coord, int val) {
    return 0;
}

int GameEntity::modGroundEffect(const Coordinates& coord, int val) {
    return 0;
}

std::optional<Coordinates> GameEntity::getCoordinatesForEntity(GameEntity *ent) {
    if(entities.contains(ent)) {
        return entities.at(ent);
    }
    return std::nullopt;
}

void GameEntity::broadcastAt(const Coordinates& coord, const std::string& message) {
    return;
}

void GameEntity::setRoomFlag(const Coordinates& coord, int flag, bool value) {
    return;
}

bool GameEntity::getRoomFlag(const Coordinates& coord, int flag) {
    return false;
}

bool GameEntity::toggleRoomFlag(const Coordinates& coord, int flag) {
    return false;
}

std::vector<ObjRef> GameEntity::getContents() {
    std::vector<ObjRef> out;
    for(auto &[ent, coords] : entities) {
        if(auto obj = dynamic_cast<obj_data*>(ent); obj) {
            out.emplace_back(obj);
        }
    }
    return out;
}

std::vector<CharRef> GameEntity::getPeople() {
    std::vector<CharRef> out;
    for(auto &[ent, coords] : entities) {
        if(auto ch = dynamic_cast<char_data*>(ent); ch) {
            out.emplace_back(ch);
        }
    }
    return out;
}

std::optional<Destination> GameEntity::getDirectionalDestination(const Coordinates& coord, int dir) {
    return {};
}

std::map<int, Destination> GameEntity::getDirectionalDestinations(const Coordinates& coord) {
    return {};
}

std::optional<Destination> GameEntity::getLaunchDestination(const Coordinates& coord) {
    return {};
}

double GameEntity::getModifiersForCharacter(char_data *ch, uint64_t location, uint64_t specific) {
    return 0.0;
}

std::map<int, ObjRef> GameEntity::getEquipment() {
    std::map<int, ObjRef> out;
    for(auto [e, coord] : entities) {
        if(coord.type != LocationType::Equipped) continue;
        auto o = dynamic_cast<obj_data*>(e);
        if(!o) continue;
        out[coord.point.x] = o;
    }
    return out;
}