%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>
%}

%option noyywrap

let [_a-zA-Z\x80-\xf3]
num [0-9]

%%

[\(\):\[\],]    {ECHO;/*return yytext[0];*/}
({let}|{num})+        {ECHO; char *s=strdup(yytext); /*return TERMO;*/}
\"(\n|[^"]|\\\")*\" {yytext[yyleng-1]='\0'; char *s=strdup(yytext+1); printf("%s", s);/*return DESC;*/}
.|\n            {}

%%

int main() {
    yylex();
}
