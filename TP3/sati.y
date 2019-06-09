%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

#include "glib.h"
#include "util.h"

int yylex();
int yyerror();

typedef struct termo {
    char *termo;
    char *designacao_ingles;
    char *significado;
    GSequence *sinonimos;
} *Termo;

// termo -> Termo
GHashTable *dicionario;
// posicao_inicial -> termo
GHashTable *apendice_por_posicao;

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
        fprintf(stderr, "'%s', ", s);
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

void dicionario_parse() {
    dicionario = g_hash_table_new(strhash, mystrcmp);
    yyparse();
}

typedef struct procura {
    int posicao_inicial;
    char *termo;
    int posicao;
    int ignorar;
} *Procura;

Procura procura_new(char *termo, int posicao_inicial) {
    Procura new = (Procura)malloc(sizeof(struct procura));
    new->termo = strdup(termo);
    new->posicao_inicial = posicao_inicial;
    new->posicao = 0;
    new->ignorar = 0;
    return new;
}

gint procura_cmp(gconstpointer a, gconstpointer b, void *data) {
    Procura p1 = (Procura)a;
    Procura p2 = (Procura)b;
    if (p1 == NULL || p2 == NULL) return 0;
    return strcmp(p1->termo, p2->termo);
}

void procura_free(gpointer data) {
    Procura p = (Procura)data;
    free(p->termo);
    free(p);
}

typedef struct context {
    int pos_procura;
    GSequence *matches;
} Context;

gboolean identificar_matches(gpointer key, gpointer value, gpointer data) {
    uint64_t *posicao = key;
    Procura p = (Procura)value;
    Context *c = (Context *)data;

    if (*posicao < c->pos_procura) {
        Termo t = (Termo)g_hash_table_lookup(dicionario, p->termo);
        //termo_print(t);
        g_sequence_append(c->matches, posicao);
        g_hash_table_insert(apendice_por_posicao, (gpointer)*posicao, p->termo);
        return FALSE;
    } else {
        return TRUE; // para travessia
    }
}

void dicionario_apply(char *input) {
    
    GSequence *procura_atual = g_sequence_new(NULL/*procura_free*/);
    GTree *matches = g_tree_new(intcmp);
    for (int i = 0; input[i] != '\0'; i++) {
        int pos_procura = INT_MAX;

        // processar próximo catactere do input para as matches imcompletas
        {
        GSequenceIter *iter = g_sequence_get_begin_iter(procura_atual);
        while (!g_sequence_iter_is_end(iter)) {
            Procura p = (Procura)g_sequence_get(iter);
            if (p->ignorar) {
                iter = g_sequence_iter_next(iter);
                continue;
            }
            pos_procura = (pos_procura <= p->posicao_inicial ? pos_procura : p->posicao_inicial);
            if (p->termo[p->posicao] != '\0' && p->termo[p->posicao] == input[i]) { // ir para próximo caractere
                p->posicao++;
                if (p->termo[p->posicao] == '\0') {
                    Procura p2 = procura_new(p->termo, p->posicao_inicial);
                    g_tree_insert(matches, &(p2->posicao_inicial), p2);
                    p->ignorar = 1;
                    //g_sequence_remove(iter);
                }
            } else if (p->termo[p->posicao] != '\0') { // remover da lista 
                p->ignorar = 1;
                //g_sequence_remove(iter);
            }
            iter = g_sequence_iter_next(iter);
        }
        }

        {
        GSequenceIter *iter = g_sequence_get_begin_iter(procura_atual);
        while (!g_sequence_iter_is_end(iter)) {
            Procura p = (Procura)g_sequence_get(iter);
            if (p->ignorar) {
                g_sequence_remove(iter);
            }
            iter = g_sequence_iter_next(iter);
        }
        }

        // procurar novas matches
        {
        GHashTableIter iter;
        gpointer termo, match;
        g_hash_table_iter_init(&iter, dicionario);
        while (g_hash_table_iter_next(&iter, &termo, &match)) {
            if (((char *)termo)[0] == input[i]) {
                Procura p = procura_new((char *)termo, i);
                p->posicao++;
                g_sequence_append(procura_atual, p);
            }
        }
        }

        Context c = {.pos_procura=pos_procura, .matches=g_sequence_new(NULL)};
        g_tree_foreach(matches, identificar_matches, &c);

        GSequenceIter *iter = g_sequence_get_begin_iter(c.matches);
        while (!g_sequence_iter_is_end(iter)) {
            int *key = (int *)g_sequence_get(iter);
            g_tree_remove(matches, key);
            iter = g_sequence_iter_next(iter);
        }

        //fprintf(stdout, "%c", input[i]);
    }
    g_sequence_free(procura_atual);
}

void print_output(char *input) {
    printf("\\documentclass[12pt]{article}\n\\begin{document}\n");
    for (uint64_t i = 0; input[i] != '\0'; i++) {
        char *termo = g_hash_table_lookup(apendice_por_posicao, (gpointer)i);
        if (termo) {
            Termo t = g_hash_table_lookup(dicionario, termo);
            printf("\\underline{%s}\\footnote{%s}", termo, t->designacao_ingles);
            i += strlen(termo) - 1;
        } else {
            printf("%c", input[i]);
        }
    }
    printf("\\end{document}\n");
}

int main(int argc, char **argv) {
    if (argc < 3) {
        fprintf(stderr, "Número de argumentos insuficiente.\n"
                        "Utilização: sati <dicionario> <ficheiro>...\n");
        return 1;
    }

    // dicionario
    if ( (yyin = fopen(argv[1], "r")) == NULL) {
        fprintf(stderr, "sati: dictionary file %s not found\n", argv[1]);
        return 2;
    }

    dicionario_parse();
    //dicionario_print();

    int num_files = argc-2;
    char *files[num_files];
    for (int i = 0; i < num_files; i++) {
        if (!g_file_get_contents(argv[i+2], &files[i], NULL, NULL)) {
            fprintf(stderr, "sati: file %s not found\n", argv[i+2]);
            return 3;
        }
    }

    apendice_por_posicao = g_hash_table_new(g_direct_hash, g_direct_equal/*inthash, intcmp*/);
    for (int i = 0; i < num_files; i++) {
        dicionario_apply(files[i]);
        print_output(files[i]);
    }
    

    return 0;
}

