%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "glib.h"

%}

%option noyywrap

let [_a-zA-Z\x80-\xf3]
num [0-9]
pont [\-.]

%%

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
[\(\):\[\],]        {return yytext[0];}
.|\n                {}

%%

#ifdef FLEX
int main() {
    yylex();
}
#endif