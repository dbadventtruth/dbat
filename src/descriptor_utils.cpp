#include "descriptor_utils.h"
#include "character_impl.h"
#include "character_macros.h"
#include "consts/applies.h"
#include "consts/mobflags.h"
#include "consts/positions.h"
#include "consts/races.h"
#include "descriptor_impl.h"
#include "flags.h"

#include <strings.h>

#include <cstring>

#include "comm.h"
#include "db.h"
#include "fileop.h"
#include "log.h"
#include "object_impl.h"

void customWrite(struct char_data *ch, struct obj_data *obj) {

  if (IS_NPC(ch))
    return;

  char fname[40], line[256], prev[256];
  char buf[MAX_STRING_LENGTH];
  FILE *fl, *file;

  if (!get_filename(fname, sizeof(fname), CUSTOME_FILE, ch->desc->user)) {
    mud_log("ERROR: Custom unable to be saved to user file!");
    return;
  }

  if (!(file = fopen(fname, "r"))) {
    mud_log("ERROR: Custom unable to be saved to user file!");
    return;
  }

  while (!feof(file)) {
    get_line(file, line);
    if (strcasecmp(prev, line))
      sprintf(buf + strlen(buf), "%s\n", line);
    *prev = '\0';
    sprintf(prev, line);
  }

  fclose(file);

  if (!get_filename(fname, sizeof(fname), CUSTOME_FILE, ch->desc->user)) {
    mud_log("ERROR: Custom unable to be saved to user file!");
    return;
  }

  if (!(fl = fopen(fname, "w"))) {
    mud_log("ERROR: Custom unable to be saved to user file!");
    return;
  }

  sprintf(buf + strlen(buf), "%s\n", obj->short_description);
  fprintf(fl, "%s\n", buf);

  fclose(fl);
}

void customRead(struct descriptor_data *d, int type, char *name) {

  char fname[40], line[256], filler[256];
  FILE *fl;
  char buf[MAX_STRING_LENGTH];

  if (type == 1) {

    if (!get_filename(fname, sizeof(fname), CUSTOME_FILE, name)) {
      mud_log("ERROR: Custom unable to be read from user file!");
      return;
    }

    if (!(fl = fopen(fname, "r"))) {
      mud_log("ERROR: Custom file unable to be read!");
      return;
    }

    char buf[MAX_STRING_LENGTH];

    while (!feof(fl)) {
      get_line(fl, line);
      if (strcasecmp(filler, line))
        sprintf(buf + strlen(buf), "%s\n", line);
      *filler = '\0';
      *line = '\0';
      sprintf(filler, line);
    }

    send_to_char(d->character, buf);

    fclose(fl);
    return;
  } else {

    if (!get_filename(fname, sizeof(fname), CUSTOME_FILE, d->user)) {
      mud_log("ERROR: Custom unable to be read from user file!");
      return;
    }

    if (!(fl = fopen(fname, "r"))) {
      mud_log("ERROR: Custom file unable to be read!");
      return;
    }

    while (!feof(fl)) {
      get_line(fl, line);
      if (strcasecmp(filler, line))
        sprintf(buf + strlen(buf), "%s\n", line);
      *filler = '\0';
      sprintf(filler, line);
    }

    write_to_output(d, buf);

    fclose(fl);
  }
}

void customCreate(struct descriptor_data *d) {

  if (!d)
    return;

  if (d->customfile == 1)
    return;

  char fname[40];
  FILE *fl;

  /* Create Their Custom File */

  if (!get_filename(fname, sizeof(fname), CUSTOME_FILE, d->user))
    return;

  if (!(fl = fopen(fname, "w"))) {
    mud_log("ERROR: could not create custom file.");
    return;
  }

  fprintf(fl, "@D--@RUser @GC@gustom@Gs@D--@n\n");
  d->customfile = 1;

  fclose(fl);
}