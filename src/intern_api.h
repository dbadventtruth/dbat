#pragma once
#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t InternedId;

InternedId intern_string(const char *name);
int64_t lookup_string(const char *name);

#ifdef __cplusplus
}
#endif
