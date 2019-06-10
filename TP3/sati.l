%{
#include <stdlib.h>
#include <string.h>
#include <ctype.h>

#include "glib.h"

// para ignorar os warnings do lex
#pragma GCC diagnostic ignored "-Wunused-function"

char *escape(char *s) {
    char *r = (char *)malloc(sizeof(char)*(strlen(s)+1));
    int j = 0;
    for (uint32_t i = 0; i < strlen(s)+1; i++) {
        int backslash = yytext[i] == '\\';
        int last_backslash = (i != 0 && yytext[i-1] == '\\');
        if (!backslash) {
            r[j++] = yytext[i];
        } else if (last_backslash) {
            r[j++] = yytext[i];
            s[i] = 'X';
        }
    }
    r[j - 2] = '\0';
    return r + 1;
}

%}

%option noyywrap

let [_a-zA-Z\x80-\xf3]
num [0-9]
pont [\-.]

%%

[\(\):\[\],]        {return yytext[0];}
'([^']|(\\'))*' {
    //yytext[yyleng-1]='\0';
    char *r = escape(yytext);
    #ifdef FLEX
    printf("%s\n", r);
    #else
    yylval.s = r;
    return TERMO;
    #endif
}
\"(\n|[^"]|\\\")*\" {
    //yytext[yyleng-1]='\0';
    char *r = escape(yytext);
    #ifdef FLEX
    printf("%s\n", r);
    #else
    yylval.s = r;
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
