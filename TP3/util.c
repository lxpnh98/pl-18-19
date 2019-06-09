#include "glib.h"

#include "util.h"

guint strhash(gconstpointer key) {
    GString *s = g_string_new((char *)key);
    return g_string_hash(s);
}

gboolean mystrcmp (gconstpointer a, gconstpointer b) {
    GString *s1 = g_string_new((char *)a);
    GString *s2 = g_string_new((char *)b);
    return g_string_equal(s1, s2);
}

gint intcmp(gconstpointer a, gconstpointer b) {
    int *x = (int *)a;
    int *y = (int *)y;
    if (x == NULL || y == NULL) return 0;
    if (*x <  *y) return -1;
    if (*x == *y) return  0;
    else          return  1;
}

guint inthash(gconstpointer key) {
    int *i = (int *)i;
    return *i;
}

