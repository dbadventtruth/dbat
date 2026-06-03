#pragma once
#include "consts/types.h"
#include <time.h>

#ifdef __cplusplus
extern "C" {
#endif

struct player_index_element {
  char *name;
  long id;
  int level;
  int admlevel;
  int flags;
  time_t last;
  int ship;
  int shiproom;
  time_t played;
  char *clan;
};

#ifdef __cplusplus
}
#endif
