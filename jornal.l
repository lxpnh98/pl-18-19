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

void tag_print(gpointer data, gpointer user_data) {
    printf("<tag>%s</tag>", ((GString *)data)->str);
}

int line_num;

void pub_print(void) {
    if (strlen(pub->id->str) == 0) {
        fprintf(stderr, "linha %d: post sem id\n", line_num);
        return;
    }
    gchar *line_num_str = g_strdup_printf("%i", line_num);
    printf("<pub id=%s line=%s>\n", pub->id->str, line_num_str);
    printf("<title>%s</title>\n", pub->title->str);
    printf("<author_date>%s</author_date>\n", pub->author_date->str);
    printf("<tags>\n");
    g_sequence_foreach(pub->tags, tag_print, NULL);
    printf("\n</tags>\n");
    printf("<category>%s</category>\n", pub->cat->str);
    printf("<text>%s</text>\n", pub->text->str);
    printf("</pub>\n");
}

//TODO: opção debug (ativa line_num)

//TODO: não incluir noticias repetidas

//TODO: listar e contar tags (3.)

/*TODO:
    tag:
        <a href=post-????.html>titulo</a>
    tag2:
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

int yywrap() {
    return 1;
}

int main() {
    yylex();
    return 0;
}
