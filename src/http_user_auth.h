#pragma once
#include "consts/types.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Reads data/user/<range>/<account>.usr, verifies password with Argon2.
 * Returns the account's level field (>0 means privileged/staff) on success.
 * Returns -1 if account file not found, -2 if password wrong.
 */
int http_authenticate_user(const char *account, const char *password);

#ifdef __cplusplus
}
#endif
