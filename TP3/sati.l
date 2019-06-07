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
    ECHO;
    yytext[yyleng-1]='\0';
    #ifdef FLEX
    char *s=strdup(yytext+1);
    #else
    yylval.s=yytext+1;
    return TERMO;
    #endif
}
\"(\n|[^"]|\\\")*\" {
    ECHO;
    yytext[yyleng-1]='\0';
    #ifdef FLEX
    char *s=strdup(yytext+1);
    #else
    yylval.s=yytext+1;
    return DESC;
    #endif
}
[\(\):\[\],]        {ECHO; return yytext[0];}
.|\n                {ECHO; }

%%

#ifdef FLEX
int main() {
    yylex();
}
#endif
