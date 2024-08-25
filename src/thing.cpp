#pragma once

#include "dbat/structs.h"
#include "dbat/utils.h"
#include "dbat/constants.h"

Location GameEntity::getLocation() {
    return location;
}

Location GameEntity::clearLocation() {
    auto old = location;
    if(location.entity) location.entity->removeEntity(this, 0);
    location = Location();
    onRemovedFromLocation(old);
    return old;
}

void GameEntity::setLocation(const Location& newLoc) {
    auto old = location;

    // We are being moved within the same location.
    // So we just call the relocate routines.
    if(old.entity && old.entity == newLoc.entity) {
        newLoc.entity->relocateEntity(this, newLoc.getCoordinates(), 0);
        onRelocatedWithinLocation(old.getCoordinates(), newLoc.getCoordinates());
        return;
    }

    // They are not the same.
    if(old.entity) {
        clearLocation();
    }

    location = newLoc;
    newLoc.entity->addEntity(this, newLoc.getCoordinates(), 0);
    onAddedToLocation(newLoc);
}

struct room_data* GameEntity::getRoom() const {
    if(auto r = dynamic_cast<room_data*>(location.entity); r)
        return r;
    return nullptr;
}

room_vnum GameEntity::getRoomVnum() const {
    if(auto r = getRoom(); r)
        return r->vn;
    return NOWHERE;
}

std::string GameEntity::getLocationName() const {
    if(location.entity) return location.entity->getNameAt(location.getCoordinates());
    return "Unknown";
}

std::optional<Destination> GameEntity::getDirection(int dir) const {
    if(location.entity) return location.entity->getDirectionalDestination(location.getCoordinates(), dir);
    return {};
}

std::map<int, Destination> GameEntity::getDirections() const {
    if(location.entity) return location.entity->getDirectionalDestinations(location.getCoordinates());
    return {};
}

double GameEntity::getLocationEnvironment(int type) const {
    if(location.entity) return location.entity->getEnvironment(location.getCoordinates(), type);
    return 0.0;
}

double GameEntity::setLocationEnvironment(int type, double value) const {
    if(location.entity) return location.entity->setEnvironment(location.getCoordinates(), type, value);
    return 0.0;
}

double GameEntity::modLocationEnvironment(int type, double value) const {
    if(location.entity) return location.entity->modEnvironment(location.getCoordinates(), type, value);
    return 0.0;
}

void GameEntity::clearLocationEnvironment(int type) const {
    if(location.entity) return location.entity->clearEnvironment(location.getCoordinates(), type);
}

void GameEntity::setLocationRoomFlag(int flag, bool value) const {
    if(location.entity) location.entity->setRoomFlag(location.getCoordinates(), flag, value);
}

bool GameEntity::toggleLocationRoomFlag(int flag) const {
    if(location.entity) return location.entity->toggleRoomFlag(location.getCoordinates(), flag);
    return false;
}

bool GameEntity::getLocationRoomFlag(int flag) const {
    if(location.entity) return location.entity->getRoomFlag(location.getCoordinates(), flag);
    return false;
}

void GameEntity::broadcastAtLocation(const std::string& message) const {
    if(location.entity) location.entity->broadcastAt(location.getCoordinates(), message);
}

std::vector<ObjRef> GameEntity::getLocationObjects() const {
    if(location.entity) return location.entity->gatherEntities<obj_data, ObjRef>(location.getCoordinates());
    return {};
}

std::vector<CharRef> GameEntity::getLocationPeople() const {
    if(location.entity) return location.entity->gatherEntities<char_data, CharRef>(location.getCoordinates());
    return {};
}

int GameEntity::getLocationDamage() const {
    if(location.entity) return location.entity->getDamage(location.getCoordinates());
    return 0;
}

int GameEntity::setLocationDamage(int value) const {
    if(location.entity) return location.entity->setDamage(location.getCoordinates(), value);
    return 0;
}

int GameEntity::modLocationDamage(int value) const {
    if(location.entity) return location.entity->modDamage(location.getCoordinates(), value);
    return 0;
}

int GameEntity::getLocationTileType() const {
    if(location.entity) return location.entity->getTileType(location.getCoordinates());
    return 0;
}

int GameEntity::getLocationGroundEffect() const {
    if(location.entity) return location.entity->getGroundEffect(location.getCoordinates());
    return 0;
}

int GameEntity::setLocationGroundEffect(int value) const {
    if(location.entity) return location.entity->setGroundEffect(location.getCoordinates(), value);
    return 0;
}

int GameEntity::modLocationGroundEffect(int value) const {
    if(location.entity) return location.entity->modGroundEffect(location.getCoordinates(), value);
    return 0;
}

SpecialFunc GameEntity::getLocationSpecialFunc() const {
    if(location.entity) return location.entity->getSpecialFunction(location.getCoordinates());
    return nullptr;
}

std::pair<uint16_t, uint16_t> GameEntity::getCompassBitmasks() {
    if(!location.entity)
        return {0, 0};
    uint16_t doors = 0, locked = 0;

    for(auto [dir, dest] : getDirections()) {

        if(dest.exit_flags & EX_SECRET) continue;
        // Direction is available.
        doors |= (1 << dir);
        // Check if the door is locked.
        if(dest.exit_flags & EX_LOCKED)
            locked |= (1 << dir);
        // but wait, there's more. we need to check for the door on the other side.
        if(!dest.location.entity) continue;
        auto rev = rev_dir[dir];
        if(auto rev_dest = dest.location.entity->getDirectionalDestination(dest.location.getCoordinates(), rev); rev_dest) {
            if(rev_dest->exit_flags & EX_LOCKED)
                locked |= (1 << rev);
        }
    }

    return {doors, locked};
}