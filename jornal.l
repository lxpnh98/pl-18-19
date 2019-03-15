%{
#include <stdio.h>
#include <stdlib.h>
%}

%x PUB
%x TAGS

%%

\<pub\>         {BEGIN PUB; printf("<pub>\n");}
<PUB>\<\/pub\>  {BEGIN INITIAL; printf("<\\pub>\n");}
<PUB>\#TAG:     {BEGIN TAGS;printf("<tags>\n");}
<TAGS>\n        {BEGIN PUB;printf("\n<\\tags>\n");}
<PUB>.          {printf("text: '''%s'''\n", yytext);}
<PUB>\n         {}
<INITIAL>.|\n   {}

%%

int yywrap() {
    return 1;
}

int main() {
    yylex();
    return 0;
}
