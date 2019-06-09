#ifndef __UTIL__
#define __UTIL__

#include "glib.h"

guint strhash(gconstpointer key);
gboolean mystrcmp (gconstpointer a, gconstpointer b);
gint intcmp(gconstpointer a, gconstpointer b);
guint inthash(gconstpointer key);

#endif//__UTIL__
