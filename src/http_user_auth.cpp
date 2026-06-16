#include "http_user_auth.h"
#include "auth_api.h"
#include "fileop.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int http_authenticate_user(const char *account, const char *password) {
    char filename[256];
    if (!get_filename(filename, sizeof(filename), USER_FILE, account))
        return -1;

    FILE *fl = fopen(filename, "r");
    if (!fl)
        return -1;

    char buf[256];
    char pass_hash[256] = {0};
    int level = 0;

    for (int line = 1; line <= 11; line++) {
        if (!get_line(fl, buf))
            break;
        if (line == 3)
            strncpy(pass_hash, buf, sizeof(pass_hash) - 1);
        else if (line == 11)
            level = atoi(buf);
    }
    fclose(fl);

    if (!pass_hash[0])
        return -1;

    if (!password_verify(pass_hash, password))
        return -2;

    return level;
}
