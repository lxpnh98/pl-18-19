%{
#include <stdio.h>
#include <stdlib.h>
%}

%option yywrap

%%

.|\n {ECHO;}

%%

int yywrap() {
    return 1;
}

int main() {
    yylex();
    return 0;
}
