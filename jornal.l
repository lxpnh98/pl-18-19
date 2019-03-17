%{
#include <stdio.h>
#include <stdlib.h>
%}

%x PUB
%x TAGS
%x CAT
%x TITLE

%%

\<pub\>                     {BEGIN PUB; printf("<pub>\n");}
<PUB>\<\/pub\>              {BEGIN INITIAL; printf("</pub>\n");}
<PUB>\#TAG:                 {BEGIN TAGS;printf("<tags>\n");}
<TAGS>\n                    {BEGIN CAT;printf("\n</tags>\n<categoria>");}
<TAGS>tag:\{[_a-zA-Z]+\}    {yytext[yyleng-1]='\0'; printf("<tag>%s</tag>", yytext+5);}
<CAT>.+                     {ECHO;}
<CAT>\n                     {BEGIN TITLE; printf("</categoria>\n<title>");}
<TITLE>\n                   {BEGIN PUB; printf("</title>\n");}
<PUB>.|\n                   {ECHO;}
<INITIAL>.|\n               {}

%%

int yywrap() {
    return 1;
}

int main() {
    yylex();
    return 0;
}
