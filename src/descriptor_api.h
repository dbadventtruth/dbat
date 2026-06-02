#pragma once
#include "consts/types.h"

#ifdef __cplusplus
extern "C" {
#endif

void desc_send_text(struct descriptor_data *d, const char *text);
void desc_send_textf(struct descriptor_data *d, const char *format, ...) __attribute__((format(printf, 2, 3)));

#ifdef __cplusplus
}
#endif
