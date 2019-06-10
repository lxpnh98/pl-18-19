#ifndef __UTIL__
#define __UTIL__

#include "glib.h"

typedef void *unused;

guint strhash(gconstpointer key);
gboolean mystrcmp (gconstpointer a, gconstpointer b);
gint intcmp(gconstpointer a, gconstpointer b);
guint inthash(gconstpointer key);

void tex_escape(char c);
void tex_escape_str(char *str);

#endif//__UTIL__
