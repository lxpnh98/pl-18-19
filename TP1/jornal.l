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
    pub->tags  = g_sequence_new(NULL);
}

void pub_free(void) {
    //g_string_free(pub->id, TRUE);
    //g_string_free(pub->title, TRUE);
    g_string_free(pub->cat, TRUE);
    g_string_free(pub->author_date, TRUE);
    g_string_free(pub->text, TRUE);
    g_sequence_free(pub->tags);
    free(pub);
}

GString *prefix;
FILE *html;
FILE *xml;

void tag_print_xml(gpointer tag, gpointer user_data) {
    fprintf(xml, "<tag>%s</tag>", ((GString *)tag)->str);
}

void tag_print_html(gpointer tag, gpointer user_data) {
    fprintf(html, "#%s ", ((GString *)tag)->str);
}

struct post_info {
    GString *id;
    GString *title;
};

int debug = 0;
int line_num;

GHashTable *posts;

GHashTable *tag_index;

void tag_add_post(gpointer tag, gpointer post) {
    GSequence *seq = (GSequence *)g_hash_table_lookup(tag_index, tag);
    if (seq == NULL) {
        seq = g_sequence_new(NULL);
    }
    g_sequence_append(seq, post);
    g_hash_table_replace(tag_index, tag, seq);
}

void print_xml(FILE *xml) {
    if (debug) {
        gchar *line_num_str = g_strdup_printf("%i", line_num);
        fprintf(xml, "<pub id=%s line=%s>\n", pub->id->str, line_num_str);
        free(line_num_str);
    } else {
        fprintf(xml, "<pub id=%s>\n", pub->id->str);
    }
    fprintf(xml, "<title>%s</title>\n", pub->title->str);
    fprintf(xml, "<author_date>%s</author_date>\n", pub->author_date->str);
    fprintf(xml, "<tags>\n");
    g_sequence_foreach(pub->tags, tag_print_xml, NULL);
    fprintf(xml, "\n</tags>\n");
    fprintf(xml, "<category>%s</category>\n", pub->cat->str);
    fprintf(xml, "<text>%s</text>\n", pub->text->str);
    fprintf(xml, "</pub>\n");
}

void print_html(FILE *html) {
    fprintf(html, "<!DOCTYPE html>\n<html>\n<body>\n<meta charset=\"UTF-8\">\n");

    fprintf(html, "<h1>%s</h1>\n", pub->title->str);

    gchar **paragraphs = g_strsplit(pub->text->str, "\n\n", 0);
    gchar **current = paragraphs;
    do {
        fprintf(html, "<p>%s</p>\n", *current);
    } while (*(++current));
    g_strfreev(paragraphs);
    fprintf(html, "<hr>\n");
    fprintf(html, "<p>");
    g_sequence_foreach(pub->tags, tag_print_html, NULL);
    fprintf(html, "</p>\n");
    fprintf(html, "<p>%s</p>\n", pub->author_date->str);
    fprintf(html, "<p>Category: %s</p>\n", pub->cat->str);

    fprintf(html, "</html>\n</body>\n");
}

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

    g_hash_table_add(posts, g_string_new(pub->id->str));

    struct post_info *post = malloc(sizeof(struct post_info));
    post->id = pub->id;
    post->title = pub->title;
    g_sequence_foreach(pub->tags, tag_add_post, post);

    // criar ficheiro post-????.html
    GString *file = g_string_new(prefix->str);
    g_string_append(file, pub->id->str);
    g_string_append(file, ".html");
    html = fopen(file->str, "w");
    g_string_free(file, TRUE);
    print_html(html);

    // criar ficheiro post-????.xml
    file = g_string_new(prefix->str);
    g_string_append(file, pub->id->str);
    g_string_append(file, ".xml");
    xml = fopen(file->str, "w");
    print_xml(xml);

    g_string_free(file, TRUE);
    fclose(html);
    fclose(xml);
}

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
    gchar **strv = g_strsplit(yytext+5, "\n", 0);
    gchar *tag = g_strjoinv(" ", strv);
    g_sequence_append(pub->tags, g_string_new(tag));
    g_strfreev(strv);
    free(tag);
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
<SKIP>#DATE:\ \[.{5}\]\ .+ {
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

void post_print(gpointer post, gpointer user_data) {
    struct post_info *p = ((struct post_info *)post);
    printf("\t<a href=%s%s.html>%s</a><br>\n", prefix->str, p->id->str, p->title->str);
}

FILE *tag_count;

void print_tag_info(gpointer tag, gpointer posts, gpointer user_data) {
    printf("<p><b>%s:</b></p>\n", ((GString *)tag)->str);

    fprintf(tag_count, "%s|%d\n", ((GString *)tag)->str, g_sequence_get_length((GSequence *)posts));

    g_sequence_foreach((GSequence *)posts, post_print, NULL);
}

guint str_hash(gconstpointer a) {
    guint h = 0;
    char *str = ((GString *)a)->str;
    do {
        h += (guint)*str;
    } while (*(++str));
    return h;
}

gboolean str_equal(gconstpointer a, gconstpointer b) {
    return strcmp(((GString *)a)->str, ((GString *)b)->str) == 0;
}

void str_free(gpointer str) {
    g_string_free((GString *)str, TRUE);
}

int main(int argc, char **argv) {
    // process commandline arguments
    if (argc > 1) {
        prefix = g_string_new(argv[1]);
        if (prefix->str[strlen(prefix->str)-1] != '/') {
            g_string_append_c(prefix, '/');
        }
    } else {
        prefix = g_string_new("./");
    }

    // initialize data structures
    posts = g_hash_table_new_full(pub_hash, pub_equal, str_free, NULL);
    tag_index = g_hash_table_new(str_hash, str_equal);

    yylex();

    // open tag_count file
    GString *file = g_string_new(prefix->str);
    g_string_append(file, "tag_count.txt");
    tag_count = fopen(file->str, "w");
    g_string_free(file, TRUE);

    // print tag index to stdout
    printf("<!DOCTYPE html>\n<html>\n<body>\n<meta charset=\"UTF-8\">\n");
    g_hash_table_foreach(tag_index, print_tag_info, NULL);
    printf("</html>\n</body>\n");

    // free data
    g_hash_table_destroy(posts);

    return 0;
}

int yywrap() {
    return 1;
}

