#pragma once

#undef ADD_UID_VAR
#define ADD_UID_VAR(buf, trig, go, name, context, type_char)                   \
  do {                                                                         \
    sprintf(buf, "%c%c%d", UID_CHAR, type_char, GET_ID(go));                  \
    add_var(&GET_TRIG_VARS(trig), name, buf, context);                         \
  } while (0)
