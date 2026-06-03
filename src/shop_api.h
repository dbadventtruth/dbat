#pragma once
#include "consts/types.h"
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

// Shop API functions, implemented in shops_api.zig
shop_vnum shop_id_get(struct shop_data *shop);
void shop_id_set(struct shop_data *shop, shop_vnum id);
float shop_profit_buy_get(struct shop_data *shop);
void shop_profit_buy_set(struct shop_data *shop, float value);
float shop_profit_sell_get(struct shop_data *shop);
void shop_profit_sell_set(struct shop_data *shop, float value);
const char *shop_no_such_item1_get(struct shop_data *shop);
void shop_no_such_item1_set(struct shop_data *shop, const char *value);
const char *shop_no_such_item2_get(struct shop_data *shop);
void shop_no_such_item2_set(struct shop_data *shop, const char *value);
const char *shop_missing_cash1_get(struct shop_data *shop);
void shop_missing_cash1_set(struct shop_data *shop, const char *value);
const char *shop_missing_cash2_get(struct shop_data *shop);
void shop_missing_cash2_set(struct shop_data *shop, const char *value);
const char *shop_do_not_buy_get(struct shop_data *shop);
void shop_do_not_buy_set(struct shop_data *shop, const char *value);
const char *shop_message_buy_get(struct shop_data *shop);
void shop_message_buy_set(struct shop_data *shop, const char *value);
const char *shop_message_sell_get(struct shop_data *shop);
void shop_message_sell_set(struct shop_data *shop, const char *value);
int shop_temper_get(struct shop_data *shop);
void shop_temper_set(struct shop_data *shop, int temper);
bool shop_flagged(struct shop_data *shop, int pos);
bool shop_flag_toggle(struct shop_data *shop, int pos);
void shop_flag_set(struct shop_data *shop, int pos, bool value);
mob_vnum shop_keeper_get(struct shop_data *shop);
void shop_keeper_set(struct shop_data *shop, mob_vnum vnum);
bool shop_trade_flagged(struct shop_data *shop, int pos);
bool shop_trade_flag_toggle(struct shop_data *shop, int pos);
void shop_trade_flag_set(struct shop_data *shop, int pos, bool value);
int shop_open1_get(struct shop_data *shop);
void shop_open1_set(struct shop_data *shop, int value);
int shop_open2_get(struct shop_data *shop);
void shop_open2_set(struct shop_data *shop, int value);
int shop_close1_get(struct shop_data *shop);
void shop_close1_set(struct shop_data *shop, int value);
int shop_close2_get(struct shop_data *shop);
void shop_close2_set(struct shop_data *shop, int value);
int shop_bank_get(struct shop_data *shop);
void shop_bank_set(struct shop_data *shop, int value);
int shop_lastsort_get(struct shop_data *shop);
void shop_lastsort_set(struct shop_data *shop, int value);
SpecialFunc shop_func_get(struct shop_data *shop);
void shop_func_set(struct shop_data *shop, SpecialFunc func);
obj_vnum shop_product_get(struct shop_data *shop, size_t index);
void shop_product_set(struct shop_data *shop, size_t index, obj_vnum vnum);
room_vnum shop_room_get(struct shop_data *shop, size_t index);
void shop_room_set(struct shop_data *shop, size_t index, room_vnum vnum);
struct shop_buy_data *shop_buy_type_get(struct shop_data *shop, size_t index);

int shop_buy_data_type_get(struct shop_buy_data *data);
void shop_buy_data_type_set(struct shop_buy_data *data, int type);
const char *shop_buy_data_keywords_get(struct shop_buy_data *data);
void shop_buy_data_keywords_set(struct shop_buy_data *data,
                                const char *keywords);

#ifdef __cplusplus
}
#endif
