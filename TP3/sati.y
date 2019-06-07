%{
#define _GNU_SOURCE
#include <stdio.h>
#include <stdlib.h>

int yylex();
int yyerror();

int tabid[26];
int var_count = 0;

int label = 0;

int lookup(char var) {
    return var_count > (var-'a');
}

%}

%union {char c; char *s; int i;};
%token <i> INT
%token <i> VAR
%token VARS CODE END
%token INTEGER READ PRINT IF THEN ELSE

%type <s> VARLIST SLIST DEC S EXP T F L CONDITION COND

%%

L   : VARS VARLIST CODE SLIST END {printf("%s\tstart\n%s\tstop\n", $2, $4);}

VARLIST : DEC               {asprintf(&$$, "%s", $1);}
        | DEC';' VARLIST    {asprintf(&$$, "%s%s", $1, $3);}
        ;

DEC     : VAR ':' TYPE      {asprintf(&$$, "\tpushi 0\n"); if (!lookup($1)) {tabid[$1-'a'] = var_count++;} else {yyerror("variável já declarada"); exit(1);}}
        ;

TYPE    : INTEGER
        ;

SLIST   : S                 {asprintf(&$$, "%s", $1);}
        | S ';' SLIST       {asprintf(&$$, "%s%s", $1, $3);}
        ;

S   : READ '(' VAR ')'      {if (lookup($3)) {asprintf(&$$, "\tread\n\tatoi\n\tstoreg %d\n", $3-'a');} else {yyerror("variável não existe"); exit(1);}}
    | PRINT '(' EXP ')'     {asprintf(&$$, "%s\twritei\n\tpushs \"\\n\"\n\twrites\n", $3);}
    | VAR '=' EXP           {if (lookup($1)) {asprintf(&$$, "%s\tstoreg %d\n", $3, $1-'a');} else {yyerror("variável não existe"); exit(1);} }
    | CONDITION             {asprintf(&$$, "%s", $1);}
    ;

CONDITION : IF '(' COND ')' '{' SLIST '}' ELSE '{' SLIST '}' {
    asprintf(&$$, "%s"
                 "\tjz L%d\n"
                 "%s"
                 "\tjump L%d\n"
                 "L%d: nop\n"
                 "%s"
                 "L%d: nop\n", $3, label, $6, label+1, label, $10, label+1); label += 2;}

COND : EXP     {asprintf(&$$, "%s", $1);}
     ;

EXP : EXP '+' T             {asprintf(&$$, "%s%s\tadd\n", $1, $3);}
    | EXP '-' T             {asprintf(&$$, "%s%s\tsub\n", $1, $3);}
    | T                     {asprintf(&$$, "%s", $1);}
    ;

T   : T '*' F               {asprintf(&$$, "%s%s\tmul\n", $1, $3);}
    | T '/' F               {asprintf(&$$, "%s%s\tdiv\n", $1, $3);}
    | F                     {asprintf(&$$, "%s", $1);}
    ;

F   : INT                   {asprintf(&$$, "\tpushi %d\n", $1);}
    | VAR                   {if (lookup($1)) {asprintf(&$$, "\tpushg %d\n", tabid[$1-'a']);} else {yyerror("variável não existe"); exit(1);}}
    | '(' EXP ')'           {asprintf(&$$, "%s", $2);}
    ;

%%

#include "lex.yy.c"

int yyerror(char *s) {
    printf("lpis: %s\n", s);
    return 1;
}

int main() {
    yyparse();
}
