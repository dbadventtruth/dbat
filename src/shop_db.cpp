#include "shop_db.h"
#include "shop_impl.h"

shop_vnum real_shop(shop_vnum vnum) {
  return shop_by_id(vnum) ? vnum : NOTHING;
}
