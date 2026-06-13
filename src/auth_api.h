#pragma once
#include <stdbool.h>
#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

#define PASSWORD_HASH_LEN 256

bool password_is_hashed(const char *pass);
bool password_hash(const char *password, char *buf, size_t buf_len);
bool password_verify(const char *hash, const char *password);

#ifdef __cplusplus
}
#endif
