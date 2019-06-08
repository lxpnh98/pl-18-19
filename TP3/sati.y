%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

#include "glib.h"

int yylex();
int yyerror();

typedef struct termo {
    char *termo;
    char *designacao_ingles;
    char *significado;
    GSequence *sinonimos;
} *Termo;

GHashTable *dicionario;

Termo termo_new(char *termo, char* designacao_ingles, char *significado, GSequence *sinonimos) {
    Termo new = (Termo)malloc(sizeof(struct termo));
    new->termo = strdup(termo);
    new->significado = strdup(significado);
    new->designacao_ingles = strdup(designacao_ingles);
    new->sinonimos = g_sequence_new(NULL);
    // iterar por sequência de sinonimos
    GSequenceIter *iter = g_sequence_get_begin_iter(sinonimos);
    while (!g_sequence_iter_is_end(iter)) {
        char *s = (char *)g_sequence_get(iter);
        g_sequence_append(new->sinonimos, strdup(s));
        iter = g_sequence_iter_next(iter);
    }
    return new;
}

void termo_print(Termo t) {
    fprintf(stderr, "'%s' ('%s'): \"%s\"\n", t->termo, t->designacao_ingles, t->significado);
    GSequenceIter *iter = g_sequence_get_begin_iter(t->sinonimos);
    fprintf(stderr, "[ ");
    while (!g_sequence_iter_is_end(iter)) {
        char *s = (char *)g_sequence_get(iter);
        fprintf(stderr, "%s, ", s);
        iter = g_sequence_iter_next(iter);
    }
    fprintf(stderr, " ]\n");
}

void _termo_print(gpointer key, gpointer value, gpointer user_data) {
    Termo t = (Termo)value;
    termo_print(t);
}

void dicionario_print() {
    g_hash_table_foreach(dicionario, _termo_print, NULL);
}

%}

%union {char *s; GSequence *seq; Termo t;};

%token <s> TERMO
%token <s> DESC

%type <seq> Sinonimos
%type <t> Def

%%

DicI : Def DicI {Termo t=$1; g_hash_table_insert(dicionario, t->termo, t); }
     |
     ;

Def : TERMO '(' TERMO ')' ':' DESC '[' Sinonimos ']' {$$ = termo_new($1, $3, $6, $8);}


Sinonimos : TERMO ',' Sinonimos     {$$ = $3; g_sequence_prepend($$, $1);}
          | TERMO                   {$$ = g_sequence_new(NULL); g_sequence_prepend($$, $1);}
          |                         {$$ = g_sequence_new(NULL); }
          ;

%%

#include "lex.yy.c"

int yyerror(char *s) {
    printf("sati: %s\n", s);
    return 1;
}

guint strhash(gconstpointer key) {
    GString *s = g_string_new((char *)key);
    return g_string_hash(s);
}

gboolean mystrcmp (gconstpointer a, gconstpointer b) {
    GString *s1 = g_string_new((char *)a);
    GString *s2 = g_string_new((char *)b);
    return g_string_equal(s1, s2);
}

void init() {
    dicionario = g_hash_table_new(strhash, mystrcmp);
}

int main() {
    init();
    yyparse();
    dicionario_print();
}

