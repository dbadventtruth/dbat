/************************************************************************
 * Generic OLC Library - Objects / genobj.c			v1.0	*
 * Original author: Levork						*
 * Copyright 1996 by Harvey Gilpin					*
 * Copyright 1997-2001 by George Greer (greerga@circlemud.org)		*
 ************************************************************************/

#include "dbat/genobj.h"

#include "dbat/class.h"
#include "dbat/genolc.h"
#include "dbat/genzon.h"
#include "dbat/utils.h"
#include "dbat/handler.h"
#include "dbat/dg_olc.h"
#include "dbat/shop.h"
#include "dbat/vehicles.h"

static int copy_object_main(struct obj_data *to, struct obj_data *from, int free_object);


obj_rnum add_object(struct obj_data *newobj, obj_vnum ovnum) {
    int found = NOTHING;
    zone_rnum rznum = real_zone_by_thing(ovnum);

    /*
     * Write object to internal tables.
     */
    if ((newobj->vn = real_object(ovnum)) != NOTHING) {
        copy_object(&obj_proto[newobj->vn], newobj);
        update_objects(&obj_proto[newobj->vn]);
        return newobj->vn;
    }

    found = insert_object(newobj, ovnum);

    auto &z = zone_table[rznum];
    z.objects.insert(ovnum);
    return found;
}

/* ------------------------------------------------------------------------------------------------------------------------------ */

/*
 * Fix all existing objects to have these values.
 * We need to run through each and every object currently in the
 * game to see which ones are pointing to this prototype.
 * if object is pointing to this prototype, then we need to replace it
 * with the new one.
 */
int update_objects(struct obj_data *refobj) {
    struct obj_data *obj, swap;
    int count = 0;

    return count;
}

/* ------------------------------------------------------------------------------------------------------------------------------ */

/* ------------------------------------------------------------------------------------------------------------------------------ */

/*
 * Function handle the insertion of an object within the prototype framework.  Note that this does not adjust internal values
 * of other objects, use add_object() for that.
 */
obj_rnum insert_object(struct obj_data *obj, obj_vnum ovnum) {

    auto exists = obj_proto.count(ovnum);
    auto &o = obj_proto[ovnum];
    o = *obj;
    editables[o.getSlug()] = &o;

    /* Not found, place at 0. */
    return false;
}


/* ------------------------------------------------------------------------------------------------------------------------------ */

int save_objects(zone_rnum zone_num) {
    return true;
}

/*
 * Free all, unconditionally.
 */
void free_object_strings(struct obj_data *obj) {
    if (obj->name)
        free(obj->name);
    if (obj->room_description)
        free(obj->room_description);
    if (obj->short_description)
        free(obj->short_description);
    if (obj->look_description)
        free(obj->look_description);
    if (obj->ex_description)
        free_ex_descriptions(obj->ex_description);
}

/*
 * For object instances that are not the prototype.
 */
void free_object_strings_proto(struct obj_data *obj) {
    int robj_num = GET_OBJ_RNUM(obj);

    if (obj->name && obj->name != obj_proto[robj_num].name)
        free(obj->name);
    if (obj->room_description && obj->room_description != obj_proto[robj_num].room_description)
        free(obj->room_description);
    if (obj->short_description && obj->short_description != obj_proto[robj_num].short_description)
        free(obj->short_description);
    if (obj->look_description && obj->look_description != obj_proto[robj_num].look_description)
        free(obj->look_description);
    if (obj->ex_description) {
        struct extra_descr_data *thised, *plist, *next_one; /* O(horrible) */
        int ok_key, ok_desc, ok_item;
        for (thised = obj->ex_description; thised; thised = next_one) {
            next_one = thised->next;
            for (ok_item = ok_key = ok_desc = 1, plist = obj_proto[robj_num].ex_description; plist; plist = plist->next) {
                if (plist->keyword == thised->keyword)
                    ok_key = 0;
                if (plist->description == thised->description)
                    ok_desc = 0;
                if (plist == thised)
                    ok_item = 0;
            }
            if (thised->keyword && ok_key)
                free(thised->keyword);
            if (thised->description && ok_desc)
                free(thised->description);
            if (ok_item)
                free(thised);
        }
    }
}

void copy_object_strings(struct obj_data *to, struct obj_data *from) {
    to->name = from->name ? strdup(from->name) : nullptr;
    to->room_description = from->room_description ? strdup(from->room_description) : nullptr;
    to->short_description = from->short_description ? strdup(from->short_description) : nullptr;
    to->look_description = from->look_description ? strdup(from->look_description) : nullptr;

    if (from->ex_description)
        copy_ex_descriptions(&to->ex_description, from->ex_description);
    else
        to->ex_description = nullptr;
}

int copy_object(struct obj_data *to, struct obj_data *from) {
    free_object_strings(to);
    return copy_object_main(to, from, true);
}

int copy_object_preserve(struct obj_data *to, struct obj_data *from) {
    return copy_object_main(to, from, false);
}

static int copy_object_main(struct obj_data *to, struct obj_data *from, int free_object) {
    *to = *from;
    copy_object_strings(to, from);
    return true;
}

int delete_object(obj_rnum rnum) {
    obj_rnum i;
    zone_rnum zrnum;
    struct obj_data *obj, *tmp;
    int shop, j, zone, cmd_no;

    if (!obj_proto.count(rnum))
        return NOTHING;

    obj = &obj_proto[rnum];
    editables.erase(obj->getSlug());

    zrnum = real_zone_by_thing(rnum);

    /* This is something you might want to read about in the logs. */
    basic_mud_log("GenOLC: delete_object: Deleting object #%d (%s).", GET_OBJ_VNUM(obj), obj->short_description);

    for (auto tmp : get_vnum_list(objectVnumIndex, obj->vn)) {
        if (tmp->vn != obj->vn)
            continue;

        /* extract_obj() will just axe contents. */
        if (auto cont = tmp->getContents(); !cont.empty()) {
            auto loc = tmp->getLocation();
            if(loc.type == LocationType::Equipped)
                loc.type == LocationType::Inventory;

            for(auto o : IterRef(cont))
                o->setLocation(loc);
        }
        /* Remove from object_list, etc. - handles weight changes, and similar. */
        extract_obj(tmp);
    }

    /* Make sure all are removed. */

    assert(get_vnum_count(objectVnumIndex, rnum) == 0);
    obj_proto.erase(rnum);
    obj_index.erase(rnum);
    save_objects(zrnum);

    return rnum;
}

nlohmann::json obj_data::serialize() {
    auto j = GameEntity::serialize();

    for(auto i = 0; i < NUM_OBJ_VAL_POSITIONS; i++) {
        if(value[i]) j["value"].push_back(std::make_pair(i, value[i]));
    }

    if(type_flag) j["type_flag"] = type_flag;
    if(level) j["level"] = level;

    for(auto i = 0; i < wear_flags.size(); i++)
        if(wear_flags.test(i)) j["wear_flags"].push_back(i);

    for(auto i = 0; i < extra_flags.size(); i++)
        if(extra_flags.test(i)) j["extra_flags"].push_back(i);

    for(auto i = 0; i < onlyAlignLawChaos.size(); i++)
        if(onlyAlignLawChaos.test(i)) j["onlyAlignLawChaos"].push_back(i);
    for(auto i = 0; i < antiAlignLawChaos.size(); i++)
        if(antiAlignLawChaos.test(i)) j["antiAlignLawChaos"].push_back(i);
    for(auto i = 0; i < onlyAlignGoodEvil.size(); i++)
        if(onlyAlignGoodEvil.test(i)) j["onlyAlignGoodEvil"].push_back(i);
    for(auto i = 0; i < antiAlignGoodEvil.size(); i++)
        if(antiAlignGoodEvil.test(i)) j["antiAlignGoodEvil"].push_back(i);
    for(auto i = 0; i < onlyClass.size(); i++)
        if(onlyClass.test(i)) j["onlyClass"].push_back(i);
    for(auto i = 0; i < antiClass.size(); i++)
        if(antiClass.test(i)) j["antiClass"].push_back(i);
    for(auto i = 0; i < onlyRace.size(); i++)
        if(onlyRace.test(i)) j["onlyRace"].push_back(i);
    for(auto i = 0; i < antiRace.size(); i++)
        if(antiRace.test(i)) j["antiRace"].push_back(i);

    if(weight != 0.0) j["weight"] = weight;
    if(cost) j["cost"] = cost;
    if(cost_per_day) j["cost_per_day"] = cost_per_day;

    for(auto i = 0; i < bitvector.size(); i++)
        if(bitvector.test(i)) j["bitvector"].push_back(i);

    for(auto & i : affected) {
        if(i.location == APPLY_NONE) continue;
        j["affected"].push_back(i.serialize());
    }

    if(type & ENT_PROTOTYPE) {
        
    } else {
        if(world.contains(room_loaded)) j["room_loaded"] = room_loaded;
    }

    return j;
}



void obj_data::deserialize(const nlohmann::json &j) {
    GameEntity::deserialize(j);

    if(j.contains("value")) {
        for(auto & i : j["value"]) {
            value[i[0].get<int>()] = i[1];
        }
    }

    if(j.contains("type_flag")) type_flag = j["type_flag"];
    if(j.contains("level")) level = j["level"];

    if(j.contains("wear_flags")) {
        for(auto & i : j["wear_flags"]) {
            wear_flags.set(i.get<int>());
        }
    }

    if(j.contains("extra_flags")) for(auto & i : j["extra_flags"]) extra_flags.set(i.get<int>());

    if(j.contains("onlyAlignLawChaos")) for(auto & i : j["onlyAlignLawChaos"]) onlyAlignLawChaos.set(i.get<int>());
    if(j.contains("antiAlignLawChaos")) for(auto & i : j["antiAlignLawChaos"]) antiAlignLawChaos.set(i.get<int>());
    if(j.contains("onlyAlignGoodEvil")) for(auto & i : j["onlyAlignGoodEvil"]) onlyAlignGoodEvil.set(i.get<int>());
    if(j.contains("antiAlignGoodEvil")) for(auto & i : j["antiAlignGoodEvil"]) antiAlignGoodEvil.set(i.get<int>());

    if(j.contains("onlyClass")) for(auto & i : j["onlyClass"]) onlyClass.set(i.get<int>());
    if(j.contains("antiClass")) for(auto & i : j["antiClass"]) antiClass.set(i.get<int>());
    if(j.contains("onlyRace")) for(auto & i : j["onlyRace"]) onlyRace.set(i.get<int>());
    if(j.contains("tiRace")) for(auto & i : j["tiRace"]) antiAlignGoodEvil.set(i.get<int>());

    if(j.contains("weight")) weight = j["weight"];
    if(j.contains("cost")) cost = j["cost"];
    if(j.contains("cost_per_day")) cost_per_day = j["cost_per_day"];

    if(j.contains("bitvector")) {
        for(auto & i : j["bitvector"]) {
            bitvector.set(i.get<int>());
        }
    }

    if(j.contains("affected")) {
        int counter = 0;
        for(auto & i : j["affected"]) {
            affected[counter].deserialize(i);
            counter++;
        }
    }

    if(type & ENT_PROTOTYPE) {

    } else {
        if(j.contains("room_loaded")) room_loaded = j["room_loaded"];
    }

}


obj_data::obj_data(const nlohmann::json &j) : obj_data() {
    deserialize(j);

    if ((GET_OBJ_TYPE(this) == ITEM_PORTAL || \
       GET_OBJ_TYPE(this) == ITEM_HATCH) && \
       (!GET_OBJ_VAL(this, VAL_DOOR_DCLOCK) || \
        !GET_OBJ_VAL(this, VAL_DOOR_DCHIDE))) {
        GET_OBJ_VAL(this, VAL_DOOR_DCLOCK) = 20;
        GET_OBJ_VAL(this, VAL_DOOR_DCHIDE) = 20;
    }

    GET_OBJ_SIZE(this) = SIZE_MEDIUM;

/* check to make sure that weight of containers exceeds curr. quantity */
    if (GET_OBJ_TYPE(this) == ITEM_DRINKCON ||
        GET_OBJ_TYPE(this) == ITEM_FOUNTAIN) {
        if (GET_OBJ_WEIGHT(this) < GET_OBJ_VAL(this, 1))
            GET_OBJ_WEIGHT(this) = GET_OBJ_VAL(this, 1) + 5;
    }
    /* *** make sure portal objects have their timer set correctly *** */
    if (GET_OBJ_TYPE(this) == ITEM_PORTAL) {
        GET_OBJ_TIMER(this) = -1;
    }
    
}


ObjRef obj_data::ref() {
    return ObjRef(this);
}

void obj_data::activate() {
    if(active) {
        basic_mud_log("Attempted to activate an already active item.");
        return;
    }
    active = true;

    if(obj_proto.contains(vn)) {
        insert_vnum(objectVnumIndex, this);
    }

    auto r = ref();
    if(!trig_list.empty()) {
        for(auto t : trig_list) t->activate();
        if(SCRIPT_TYPES(this) & OTRIG_RANDOM)
            objectSubscriptions.subscribe("randomTriggers", r);
        if(SCRIPT_TYPES(this) & OTRIG_TIME)
            objectSubscriptions.subscribe("timeTriggers", r);
    }
    activeObjects.insert(r);
    if(IS_CORPSE(this))
        objectSubscriptions.subscribe("corpseRotService", r);
    if(SCRIPT_TYPES(this) && OTRIG_RANDOM)
        objectSubscriptions.subscribe("randomTriggers", r);
    if(vn == 65)
        objectSubscriptions.subscribe("healTankService", r);

    activateContents();
}

void obj_data::deactivate() {
    if(!active) return;
    active = false;

    if(obj_proto.contains(vn)) {
        erase_vnum(objectVnumIndex, this);
    }

    for(auto t : trig_list) t->deactivate();
    
    objectSubscriptions.unsubscribeFromAll(ref());
    deactivateContents();
}


double obj_data::getAffectModifier(uint64_t location, uint64_t specific) {
    double modifier = 0;
    for(auto &aff : affected) {
        if(aff.match(location, specific)) {
            modifier += aff.modifier;
        }
    }
    return modifier;
}

weight_t obj_data::getWeight() {
    return weight;
}

weight_t obj_data::getTotalWeight() {
    return getWeight() + getInventoryWeight() + (sitting ? sitting->getTotalWeight() : 0);
}



bool obj_data::isActive() {
    return active;
}

constexpr int LOC_INVENTORY = 0;
void auto_equip(struct char_data *ch, struct obj_data *obj, int location) {
    int j;

    /* Lots of checks... */
    if (location > 0) {    /* Was wearing it. */
        switch (j = (location - 1)) {
            case WEAR_UNUSED0:
                j = WEAR_WIELD2;
                break;
            case WEAR_FINGER_R:
            case WEAR_FINGER_L:
                if (!CAN_WEAR(obj, ITEM_WEAR_FINGER)) /* not fitting :( */
                    location = LOC_INVENTORY;
                break;
            case WEAR_NECK_1:
            case WEAR_NECK_2:
                if (!CAN_WEAR(obj, ITEM_WEAR_NECK))
                    location = LOC_INVENTORY;
                break;
            case WEAR_BODY:
                if (!CAN_WEAR(obj, ITEM_WEAR_BODY))
                    location = LOC_INVENTORY;
                break;
            case WEAR_HEAD:
                if (!CAN_WEAR(obj, ITEM_WEAR_HEAD))
                    location = LOC_INVENTORY;
                break;
            case WEAR_LEGS:
                if (!CAN_WEAR(obj, ITEM_WEAR_LEGS))
                    location = LOC_INVENTORY;
                break;
            case WEAR_FEET:
                if (!CAN_WEAR(obj, ITEM_WEAR_FEET))
                    location = LOC_INVENTORY;
                break;
            case WEAR_HANDS:
                if (!CAN_WEAR(obj, ITEM_WEAR_HANDS))
                    location = LOC_INVENTORY;
                break;
            case WEAR_ARMS:
                if (!CAN_WEAR(obj, ITEM_WEAR_ARMS))
                    location = LOC_INVENTORY;
                break;
            case WEAR_UNUSED1:
                if (!CAN_WEAR(obj, ITEM_WEAR_SHIELD))
                    location = LOC_INVENTORY;
                j = WEAR_WIELD2;
                break;
            case WEAR_ABOUT:
                if (!CAN_WEAR(obj, ITEM_WEAR_ABOUT))
                    location = LOC_INVENTORY;
                break;
            case WEAR_WAIST:
                if (!CAN_WEAR(obj, ITEM_WEAR_WAIST))
                    location = LOC_INVENTORY;
                break;
            case WEAR_WRIST_R:
            case WEAR_WRIST_L:
                if (!CAN_WEAR(obj, ITEM_WEAR_WRIST))
                    location = LOC_INVENTORY;
                break;
            case WEAR_WIELD1:
                if (!CAN_WEAR(obj, ITEM_WEAR_WIELD))
                    location = LOC_INVENTORY;
                break;
            case WEAR_WIELD2:
                break;
            case WEAR_EYE:
                if (!CAN_WEAR(obj, ITEM_WEAR_EYE))
                    location = LOC_INVENTORY;
                break;
            case WEAR_BACKPACK:
                if (!CAN_WEAR(obj, ITEM_WEAR_PACK))
                    location = LOC_INVENTORY;
                break;
            case WEAR_SH:
                if (!CAN_WEAR(obj, ITEM_WEAR_SH))
                    location = LOC_INVENTORY;
                break;
            case WEAR_EAR_R:
            case WEAR_EAR_L:
                if (!CAN_WEAR(obj, ITEM_WEAR_EAR))
                    location = LOC_INVENTORY;
                break;
            default:
                location = LOC_INVENTORY;
        }

        if (location > 0) {        /* Wearable. */
            if (!GET_EQ(ch, j)) {
                /*
                 * Check the characters's alignment to prevent them from being
                 * zapped through the auto-equipping.
                     */
                if (invalid_align(ch, obj) || invalid_class(ch, obj))
                    location = LOC_INVENTORY;
                else
                    equip_char(ch, obj, j);
            } else {    /* Oops, saved a player with double equipment? */
                mudlog(BRF, ADMLVL_IMMORT, true, "SYSERR: autoeq: '%s' already equipped in position %d.", GET_NAME(ch),
                       location);
                location = LOC_INVENTORY;
            }
        }
    }

    if (location <= 0)    /* Inventory */
        obj_to_char(obj, ch);
}

nlohmann::json obj_data::serializeRelations() {
    auto j = GameEntity::serializeRelations();

    if(posted_to) j["posted_to"] = posted_to->getUID();
    if(fellow_wall) j["fellow_wall"] = fellow_wall->getUID();

    return j;
}


void obj_data::deserializeRelations(const nlohmann::json& j) {
    GameEntity::deserializeRelations(j);

    if(j.contains("posted_to")) {
        auto check = resolveUID(j["posted_to"]);
        if(check) posted_to = std::get<1>(*check);
    }
    if(j.contains("fellow_wall")) {
        auto check = resolveUID(j["fellow_wall"]);
        if(check) fellow_wall = std::get<1>(*check);
    }
}

bool obj_data::isProvidingLight() {
    return GET_OBJ_TYPE(this) == ITEM_LIGHT && GET_OBJ_VAL(this, VAL_LIGHT_HOURS);
}

struct room_data* GameEntity::getAbsoluteRoom() const {
    auto l = location;
    if(auto r = dynamic_cast<room_data*>(l.entity); r) {
        return r;
    }
    if(auto u = dynamic_cast<GameEntity*>(l.entity); u)
        return u->getAbsoluteRoom();
    
    return nullptr;
}

double obj_data::currentGravity() {
    if(auto room = getAbsoluteRoom(); room) {
        return room->getEnvironment(ENV_GRAVITY);
    }
    return 1.0;
}

bool obj_data::isWorking() {
    return !(OBJ_FLAGGED(this, ITEM_BROKEN) || OBJ_FLAGGED(this, ITEM_FORGED));
}

void obj_data::onAddedToLocation(const Location& newLoc) {
    if(auto c = dynamic_cast<char_data*>(newLoc.entity); c) {
        // we've been added to a character.

        if(newLoc.type == LocationType::Inventory) {
            // we've been added to the character's inventory.

            /* set flag for crash-save system, but not on mobs! */
            if (GET_OBJ_VAL(this, 0) != 0) {
                if (vn == 16705 || vn == 16706 || vn == 16707) {
                    level = GET_OBJ_VAL(this, 0);
                }
            }

        } else if(newLoc.type == LocationType::Equipped) {
            // we've been equipped by the character.
            int pos = newLoc.point.x;
            GET_EQ(c, pos) = this;
        }
    }

    else if(auto o = dynamic_cast<obj_data*>(newLoc.entity); o) {
        // we've been added to an object's inventory.

    }
    
    else if(auto r = dynamic_cast<room_data*>(newLoc.entity); r) {
        // we've been added to a room.
        if(type_flag == ITEM_PLANT && (r->room_flags.test(ROOM_GARDEN1) || r->room_flags.test(ROOM_GARDEN2)))
            objectSubscriptions.subscribe("growingPlants", ref());

        if(r->vn == 80) auc_load(this);

        GET_LAST_LOAD(this) = time(nullptr);

        auto &z = zone_table[r->zone];
        z.objectsInZone.insert(ref());

        auto otype = GET_OBJ_TYPE(this);
        auto ovn = GET_OBJ_VNUM(this);

        if (otype == ITEM_UNUSED_VEHICLE && !OBJ_FLAGGED(this, ITEM_UNBREAKABLE) &&
            GET_OBJ_VNUM(this) > 19199) {
            extra_flags.set(ITEM_UNBREAKABLE);
        }

        // This section is now only going to be called during migrations.
        if(isMigrating) {
            if (otype == ITEM_HATCH && ovn <= 19199) {
                if ((ovn <= 18999 && ovn >= 18800) ||
                    (ovn <= 19199 && ovn >= 19100)) {
                    int hnum = GET_OBJ_VAL(this, 0);
                    struct obj_data *house = read_object(hnum, VIRTUAL);
                    obj_to_room(house, real_room(GET_OBJ_VAL(this, 6)));
                    SET_BIT(GET_OBJ_VAL(this, VAL_CONTAINER_FLAGS), CONT_CLOSED);
                    SET_BIT(GET_OBJ_VAL(this, VAL_CONTAINER_FLAGS), CONT_LOCKED);
                }
            }
            struct obj_data* vehicle;
            if (otype == ITEM_HATCH && GET_OBJ_VAL(this, 0) > 1 && ovn > 19199) {
                if (!(vehicle = find_vehicle_by_vnum(GET_OBJ_VAL(this, VAL_HATCH_DEST)))) {
                    if (real_room(GET_OBJ_VAL(this, 3)) != NOWHERE) {
                        vehicle = read_object(GET_OBJ_VAL(this, 0), VIRTUAL);
                        if(!vehicle) {
                            basic_mud_log("SYSERR: Vehicle %d not found for hatch %d", GET_OBJ_VAL(this, 0), ovn);
                        }
                        obj_to_room(vehicle, real_room(GET_OBJ_VAL(this, 3)));
                        if (look_description) {
                            if (strlen(look_description)) {
                                char nick[MAX_INPUT_LENGTH], nick2[MAX_INPUT_LENGTH], nick3[MAX_INPUT_LENGTH];
                                if (GET_OBJ_VNUM(vehicle) <= 46099 && GET_OBJ_VNUM(vehicle) >= 46000) {
                                    sprintf(nick, "Saiyan Pod %s", look_description);
                                    sprintf(nick2, "@wA @Ys@ya@Yi@yy@Ya@yn @Dp@Wo@Dd@w named @D(@C%s@D)@w",
                                            look_description);
                                } else if (GET_OBJ_VNUM(vehicle) >= 46100 && GET_OBJ_VNUM(vehicle) <= 46199) {
                                    sprintf(nick, "EDI Xenofighter MK. II %s", look_description);
                                    sprintf(nick2,
                                            "@wAn @YE@yD@YI @CX@ce@Wn@Do@Cf@ci@Wg@Dh@Wt@ce@Cr @RMK. II @wnamed @D(@C%s@D)@w",
                                            look_description);
                                }
                                sprintf(nick3, "%s is resting here@w", nick2);
                                vehicle->name = strdup(nick);
                                vehicle->short_description = strdup(nick2);
                                vehicle->room_description = strdup(nick3);
                            }
                        }
                        SET_BIT(GET_OBJ_VAL(this, VAL_CONTAINER_FLAGS), CONT_CLOSED);
                        SET_BIT(GET_OBJ_VAL(this, VAL_CONTAINER_FLAGS), CONT_LOCKED);
                    } else {
                        basic_mud_log("Hatch load: Hatch with no vehicle load room: #%d!", ovn);
                    }
                }
            }
        }

        if (EXIT(this, 5) && (getLocationTileType() == SECT_UNDERWATER || getLocationTileType() == SECT_WATER_NOSWIM)) {
            act("$p @Bsinks to deeper waters.@n", true, nullptr, this, nullptr, TO_ROOM);
            int numb = GET_ROOM_VNUM(EXIT(this, 5)->to_room);
            obj_from_room(this);
            obj_to_room(this, real_room(numb));
        }
        if (EXIT(this, 5) && getLocationTileType() == SECT_FLYING &&
            (ovn < 80 || ovn > 83)) {
            act("$p @Cfalls down.@n", true, nullptr, this, nullptr, TO_ROOM);
            int numb = GET_ROOM_VNUM(EXIT(this, 5)->to_room);
            obj_from_room(this);
            obj_to_room(this, real_room(numb));
            if (getLocationTileType() != SECT_FLYING) {
                act("$p @Cfalls down and smacks the ground.@n", true, nullptr, this, nullptr, TO_ROOM);
            }
        }
        if (GET_OBJ_VAL(this, 0) != 0) {
            if (ovn == 16705 || ovn == 16706 || ovn == 16707) {
                level = GET_OBJ_VAL(this, 0);
            }
        }

    }

}

void obj_data::onRemovedFromLocation(const Location& oldLoc) {
    if(auto c = dynamic_cast<char_data*>(oldLoc.entity)) {
        // we've been removed from a character.
        if(oldLoc.type == LocationType::Inventory) {

            if (GET_OBJ_VAL(this, 0) != 0) {
                if (vn == 16705 || vn == 16706 || vn == 16707) {
                    level = GET_OBJ_VAL(this, 0);
                }
            }

        } else if(oldLoc.type == LocationType::Equipped) {
            int pos = oldLoc.point.x;
            GET_EQ(c, pos) = nullptr;
        }
    }

    else if(auto o = dynamic_cast<obj_data*>(oldLoc.entity); o) {
        // we've been removed from an object's inventory.

    }

    else if(auto r = dynamic_cast<room_data*>(oldLoc.entity); r) {
        // we've been removed from a room.

        struct obj_data *temp;

        if(type_flag == ITEM_PLANT) objectSubscriptions.unsubscribe("growingPlants", ref());

        auto &z = zone_table[r->zone];
        z.objectsInZone.erase(ref());

    }

}

void obj_data::onRelocatedWithinLocation(const Coordinates& oldCoord, const Coordinates& newCoord) {
    
}