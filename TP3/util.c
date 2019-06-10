#include <stdio.h>
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
    int *y = (int *)b;
    if (x == NULL || y == NULL) return 0;
    if (*x <  *y) return -1;
    if (*x == *y) return  0;
    else          return  1;
}

guint inthash(gconstpointer key) {
    int *i = (int *)key;
    return *i;
}

void tex_escape(char c) {
    switch (c) {
        case '&':
        case '%':
        case '$':
        case '#':
        case '_':
        case '{':
        case '}':
            printf("\\%c", c);
            break;
        case '~':
            printf("\\textasciitilde ");
            break;
        case '^':
            printf("\\textasciicircum ");
            break;
        case '\\':
            printf("\\textbackslash ");
            break;
        case '\n':
            printf("\n\n");
            break;
        default:
            printf("%c", c);
    }
}

void tex_escape_str(char *str) {
    for (char *p = str; *p; p++) {
        tex_escape(*p);
    }
}
