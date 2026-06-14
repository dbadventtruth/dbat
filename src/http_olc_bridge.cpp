#include "http_olc_bridge.h"
#include "dg_olc.h"
#include "genwld.h"
#include "genobj.h"
#include "genmob.h"
#include "genshp.h"
#include "gengld.h"
#include "genzon.h"
#include "zone_db.h"

int olc_save_rooms(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_rooms(zone);
}

int olc_save_objects(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_objects(zone);
}

int olc_save_mobs(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_mobiles(zone);
}

int olc_save_shops(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_shops(zone);
}

int olc_save_guilds(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_guilds(zone);
}

int olc_save_zone(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  return save_zone(zone);
}

int olc_save_triggers(zone_vnum zvnum) {
  struct zone_data *zone = zone_by_id(zvnum);
  if (!zone) return -1;
  trigedit_save_zone(zone);
  return 0;
}
