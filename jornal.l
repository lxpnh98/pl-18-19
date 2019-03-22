%{
#include <glib.h>
#include <stdio.h>
#include <stdlib.h>

enum init_sizes {
    ID_INIT_SIZE=20,
    TITLE_INIT_SIZE=100,
    CAT_INIT_SIZE=20,
    DATE_INIT_SIZE=100,
    TEXT_INIT_SIZE=200,
    TAGS_INIT_SIZE=10,
};

struct pub {
    GString *id;
    GString *title;
    GString *cat;
    GString *author_date;
    GString *text;
    GSequence *tags;
} *pub;

void destroy_tag(gpointer t) {
    g_string_free((GString *)t, TRUE);
}

void pub_new(void) {
    pub = malloc(sizeof(struct pub));
    if (!pub) {
        fprintf(stderr, "failure to allocate memory\n");
        abort();
    }
    pub->id    = g_string_new(NULL);
    pub->title = g_string_new(NULL);
    pub->cat   = g_string_new(NULL);
    pub->author_date  = g_string_new(NULL);
    pub->text  = g_string_new(NULL);
    pub->tags  = g_sequence_new(destroy_tag);
}

void pub_free(void) {
    g_string_free(pub->id, TRUE);
    g_string_free(pub->title, TRUE);
    g_string_free(pub->cat, TRUE);
    g_string_free(pub->author_date, TRUE);
    g_string_free(pub->text, TRUE);
    g_sequence_free(pub->tags);
    free(pub);
}

GString *prefix;
FILE *html;

void tag_print(gpointer data, gpointer user_data) {
    fprintf(html, "<tag>%s</tag>", ((GString *)data)->str);
}

int debug = 1;
int line_num;

GHashTable *posts;

GHashTable *tag_index;

void pub_print(void) {
    if (strlen(pub->id->str) == 0) {
        if (debug) {
            fprintf(stderr, "linha %d: post sem id\n", line_num);
        }
        return;
    }
    if (g_hash_table_contains(posts, pub->id)) {
        if (debug) {
            fprintf(stderr, "%s repetido\n", pub->id->str);
        }
        return;
    }

    // abrir ficheiro post-????.html
    GString *file = g_string_new(prefix->str);
    g_string_append(file, pub->id->str);
    g_string_append(file, ".html");
    html = fopen(file->str, "w");

    g_hash_table_add(posts, g_string_new(pub->id->str));
    if (debug) {
        gchar *line_num_str = g_strdup_printf("%i", line_num);
        fprintf(html, "<pub id=%s line=%s>\n", pub->id->str, line_num_str);
    } else {
        fprintf(html, "<pub id=%s>\n", pub->id->str);
    }
    fprintf(html, "<title>%s</title>\n", pub->title->str);
    fprintf(html, "<author_date>%s</author_date>\n", pub->author_date->str);
    fprintf(html, "<tags>\n");
    g_sequence_foreach(pub->tags, tag_print, NULL);
    fprintf(html, "\n</tags>\n");
    fprintf(html, "<category>%s</category>\n", pub->cat->str);
    fprintf(html, "<text>%s</text>\n", pub->text->str);
    fprintf(html, "</pub>\n");

    fclose(html);
}

//TODO: listar e contar tags (3.)

/*TODO:
    tag_a:
        <a href=post-????.html>titulo</a>
    tag_b:
        ...
    ...
*/

%}

%option yylineno

%x PUB
%x TAGS
%x ID
%x CAT
%x TITLE
%x SKIP
%x DATE

letter [_a-zA-Z\x80-\xf3]
punc   [-+!?,.;:"']

%%

\<pub\> {
    BEGIN PUB;
    line_num = yylineno;
    pub_new();
}

<PUB>\<\/pub\> {
    BEGIN INITIAL;
    pub_print();
    pub_free();
}
<PUB>\#TAG: {
    BEGIN TAGS;
}
<TAGS>\}\ ?\n {
    BEGIN PUB;
}
<TAGS>tag:\{({punc}|{letter}|\ |\n)+/\} {
    //TODO: retirar \n do meio da tag
    g_sequence_append(pub->tags, g_string_new(yytext+5));
}
<PUB>#ID:\{/p {
    BEGIN ID;
}
<ID>post\-[0-9]+ {
    g_string_assign(pub->id, yytext);
}
<ID>\n {
    BEGIN CAT;
}
<CAT>.+ {
    g_string_assign(pub->cat, yytext);
}
<CAT>\n\n {
    BEGIN TITLE;
}
<TITLE>\n {
    BEGIN SKIP;
}
<TITLE>.+ {
    g_string_assign(pub->title, yytext);
}
<SKIP>#DATE:\ \[.{5}]\ .+ {
    g_string_assign(pub->author_date, yytext+15);
    BEGIN DATE;
}
<DATE>\n\n {
    BEGIN PUB;
}
<PUB>.|\n {
    //TODO: retirar etiquetas (e outros) do fim do texto
    g_string_append(pub->text, yytext);
}
<*>.|\n {}

%%

guint pub_hash(gconstpointer key) {
    GString *id = (GString *)key;
    int r = atoi(id->str + 5);
    return (guint)r;
}

gboolean pub_equal(gconstpointer a, gconstpointer b) {
    GString *id_a = (GString *)a;
    GString *id_b = (GString *)b;
    return (gboolean)(strcmp(id_a->str, id_b->str) == 0);
}

int yywrap() {
    return 1;
}

int main(int argc, char **argv) {
    if (argc > 1) {
        prefix = g_string_new(argv[1]);
        if (prefix->str[strlen(prefix->str)-1] != '/') {
            g_string_append_c(prefix, '/');
        }
    } else {
        prefix = g_string_new("./");
    }
    posts = g_hash_table_new(pub_hash, pub_equal);
    tag_index = g_hash_table_new(g_str_hash, (GEqualFunc)g_string_equal);
    yylex();
    return 0;
}
