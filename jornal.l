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
    GString *date;
    GString *text;
    GSequence *tags;
} *pub;

void destroy_tag(gpointer t) {
    g_string_free((GString *)t, TRUE);
}

void pub_new() {
    pub = malloc(sizeof(struct pub));
    if (!pub) {
        fprintf(stderr, "failure to allocate memory\n");
        abort();
    }
    pub->id    = g_string_new(NULL);
    pub->title = g_string_new(NULL);
    pub->cat   = g_string_new(NULL);
    pub->date  = g_string_new(NULL);
    pub->text  = g_string_new(NULL);
    pub->tags  = g_sequence_new(destroy_tag);
}

void pub_free() {
    g_string_free(pub->id, TRUE);
    g_string_free(pub->title, TRUE);
    g_string_free(pub->cat, TRUE);
    g_string_free(pub->date, TRUE);
    g_string_free(pub->text, TRUE);
    g_sequence_free(pub->tags);
    free(pub);
}

%}

%x PUB
%x TAGS
%x CAT
%x TITLE

%%

\<pub\> {
    BEGIN PUB;
    printf("<pub>\n");
}

<PUB>\<\/pub\> {
    BEGIN INITIAL;
    printf("</pub>\n");
}
<PUB>\#TAG: {
    BEGIN TAGS;
    printf("<tags>\n");
}
<TAGS>\n {
    BEGIN CAT;
    printf("\n</tags>\n<categoria>");
}
<TAGS>tag:\{[_a-zA-Z]+\} {
    yytext[yyleng-1]='\0';
    printf("<tag>%s</tag>", yytext+5);
}
<CAT>.+ {
    ECHO;
}
<CAT>\n {
    BEGIN TITLE;
    printf("</categoria>\n<title>");
}
<TITLE>\n {
    BEGIN PUB;
    printf("</title>\n");
}
<PUB>.|\n {
    ECHO;
}
<INITIAL>.|\n {}

%%

int yywrap() {
    return 1;
}

int main() {
    pub_new();
    yylex();
    return 0;
}
