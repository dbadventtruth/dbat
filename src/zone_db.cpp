#include "iterate.hpp"
#include "zone_impl.h"

struct reset_q_type reset_q; /* queue of zones to be reset	 */

/* returns the real number of the zone with given virtual number */
zone_vnum real_zone(zone_vnum vnum) {
  return zone_by_id(vnum) ? vnum : NOTHING;
}

struct zone_data *zone_by_id(zone_vnum vnum) { return zone_get(vnum); }

zone_vnum virtual_zone_by_thing(room_vnum vznum) {

  zone_vnum found = NOTHING;
  zone_iterate([&](auto z) {
    if (z->bot <= vznum && z->top >= vznum) {
      found = z->id;
      return false; // break
    }
    return true; // continue
  });
  return found;
}
