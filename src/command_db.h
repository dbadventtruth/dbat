#pragma once
#include "consts/types.h"

#ifdef __cplusplus
extern "C" {
#endif

#define ALIAS_SIMPLE	0
#define ALIAS_COMPLEX	1

#define ALIAS_SEP_CHAR	';'
#define ALIAS_VAR_CHAR	'$'
#define ALIAS_GLOB_CHAR	'*'

void free_alias(struct alias_data *a);
struct alias_data *find_alias(struct alias_data *alias_list, char *str);

int find_command(const char *command);
extern struct command_info *complete_cmd_info;

#ifdef __cplusplus
}
#endif
