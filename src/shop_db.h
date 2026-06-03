#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

shop_rnum real_shop(shop_vnum vnum);
struct shop_data *shop_by_id(shop_vnum vnum);

void *shop_iterator_create();
struct shop_data *shop_next(void *iterator);
void shop_iterator_free(void *iterator);

void shop_put(shop_vnum vnum, struct shop_data *shop);
void shop_delete(shop_vnum vnum);
size_t shop_count();

#ifdef __cplusplus
}
#endif
