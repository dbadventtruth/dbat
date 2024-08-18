#pragma once

#include "dbat/structs.h"
#include "dbat/utils.h"
#include "dbat/constants.h"

LocationStub HasLocation::getLocation() {
    return loc;
}

LocationStub HasLocation::clearLocation() {
    auto old = loc;
    if(loc.first) loc.first->removeEntity(this, 0);
    loc = LocationStub();
    onRemovedFromLocation(old);
    return old;
}

void HasLocation::setLocation(const LocationStub& newLoc) {
    auto old = loc;
    // This really shouldn't be used this way, 
    // but we'll handle it just in case.
    if(old.first && old.first != newLoc.first) {
        clearLocation();
        loc = newLoc;
        newLoc.first->addEntity(this, newLoc.second, 0);
        onAddedToLocation(newLoc);
    } else {
        loc = newLoc;
        newLoc.first->relocateEntity(this, newLoc.second, 0);
        onRelocatedWithinLocation(old.second, newLoc.second);
    }
}

struct room_data* HasLocation::getRoom() const {
    if(auto r = dynamic_cast<room_data*>(loc.first); r)
        return r;
    return nullptr;
}

room_vnum HasLocation::getRoomVnum() const {
    if(auto r = getRoom(); r)
        return r->vn;
    return NOWHERE;
}

std::string HasLocation::getLocationName() const {
    if(loc.first) return loc.first->getLocationName(loc.second);
    return "Unknown";
}

std::optional<Destination> HasLocation::getDirection(int dir) const {
    if(loc.first) return loc.first->getDirectionalDestination(loc.second, dir);
    return {};
}

std::map<int, Destination> HasLocation::getDirections() const {
    if(loc.first) return loc.first->getDirectionalDestinations(loc.second);
    return {};
}

double HasLocation::getLocationEnvironment(int type) const {
    if(loc.first) return loc.first->getEnvironment(loc.second, type);
    return 0.0;
}

double HasLocation::setLocationEnvironment(int type, double value) const {
    if(loc.first) return loc.first->setEnvironment(loc.second, type, value);
    return 0.0;
}

double HasLocation::modLocationEnvironment(int type, double value) const {
    if(loc.first) return loc.first->modEnvironment(loc.second, type, value);
    return 0.0;
}

void HasLocation::clearLocationEnvironment(int type) const {
    if(loc.first) return loc.first->clearEnvironment(loc.second, type);
}

void HasLocation::setLocationRoomFlag(int flag, bool value) const {
    if(loc.first) loc.first->setRoomFlag(loc.second, flag, value);
}

bool HasLocation::toggleLocationRoomFlag(int flag) const {
    if(loc.first) return loc.first->toggleRoomFlag(loc.second, flag);
    return false;
}

bool HasLocation::getLocationRoomFlag(int flag) const {
    if(loc.first) return loc.first->getRoomFlag(loc.second, flag);
    return false;
}

void HasLocation::broadcastAtLocation(const std::string& message) const {
    if(loc.first) loc.first->broadcastAt(loc.second, message);
}

std::vector<ObjRef> HasLocation::getLocationObjects() const {
    if(loc.first) return loc.first->gatherEntities<obj_data, ObjRef>(loc.second);
    return {};
}

std::vector<CharRef> HasLocation::getLocationPeople() const {
    if(loc.first) return loc.first->gatherEntities<char_data, CharRef>(loc.second);
    return {};
}

int HasLocation::getLocationDamage() const {
    if(loc.first) return loc.first->getDamage(loc.second);
    return 0;
}

int HasLocation::setLocationDamage(int value) const {
    if(loc.first) return loc.first->setDamage(loc.second, value);
    return 0;
}

int HasLocation::modLocationDamage(int value) const {
    if(loc.first) return loc.first->modDamage(loc.second, value);
    return 0;
}

int HasLocation::getLocationTileType() const {
    if(loc.first) return loc.first->getTileType(loc.second);
    return 0;
}

int HasLocation::getLocationGroundEffect() const {
    if(loc.first) return loc.first->getGroundEffect(loc.second);
    return 0;
}

int HasLocation::setLocationGroundEffect(int value) const {
    if(loc.first) return loc.first->setGroundEffect(loc.second, value);
    return 0;
}

int HasLocation::modLocationGroundEffect(int value) const {
    if(loc.first) return loc.first->modGroundEffect(loc.second, value);
    return 0;
}

SpecialFunc HasLocation::getLocationSpecialFunc() const {
    if(loc.first) return loc.first->getSpecialFunction(loc.second);
    return nullptr;
}

std::pair<uint16_t, uint16_t> HasLocation::getCompassBitmasks() {
    if(!loc.first)
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
        if(!dest.location) continue;
        auto rev = rev_dir[dir];
        if(auto rev_dest = dest.location->getDirectionalDestination(dest.coords, rev); rev_dest) {
            if(rev_dest->exit_flags & EX_LOCKED)
                locked |= (1 << rev);
        }
    }

    return {doors, locked};
}