%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "glib.h"

// para ignorar os warnings do lex
#pragma GCC diagnostic ignored "-Wunused-function"

%}

%option noyywrap

let [_a-zA-Z\x80-\xf3]
num [0-9]
pont [\-.]

%%

[\(\):\[\],]        {return yytext[0];}
'([^']|(\\'))*' {
    yytext[yyleng-1]='\0';
    #ifdef FLEX
    char *s=strdup(yytext+1);
    #else
    yylval.s=yytext+1;
    return TERMO;
    #endif
}
\"(\n|[^"]|\\\")*\" {
    yytext[yyleng-1]='\0';
    #ifdef FLEX
    char *s=strdup(yytext+1);
    #else
    yylval.s=yytext+1;
    return DESC;
    #endif
}
[ \t\n]         {}
.               {fprintf(stderr, "sati: syntax error on dictionary file\n"); exit(1);}


%%

#ifdef FLEX
int main() {
    yylex();
}
#endif
