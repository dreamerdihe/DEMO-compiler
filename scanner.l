%{
#include "stdio.h"
#include "stdlib.h"
#include "parser.tab.h"
#include "string.h"
#ifdef FLEX_SCANNER

extern int yylineno;
#define YYINCR(n) yylineno += n
#else
#define YYINCR(n)
#endif

char *lexeme;
char *ssave( char *s );

%}
COMMENT \/\/[^\n]*
AND and
BY by
ELSE else
FOR for
IF if
INT int
CHAR char
NOT not
OR or
PROCEDURE procedure
READ read
THEN then
TO to
WHILE while
WRITE write
PLUS [+]
MINUS [-]
MULTI [*]
DIVID [/]
LT [<]
LE <=
EQ ==
NE !=
GT [>]
GE >=
COLON [:]
SEMI [;]
COMMA [,]
ASSIGN [=]
LC \{
RC \}
LB \[
RB \]
LP \(
RP \)
NUMBER [0-9]+|[0-9][0-9]*
NAME [A-Za-z][A-Za-z0-9]*
CHARCONST ['][A-Za-z0-9]+[']
%%
{COMMENT} 

{AND} { return AND; }

{BY} { return BY; }

{ELSE} { return ELSE; }

{FOR} { return FOR; }

{IF} { return IF; }

{INT} { return INT; }

{CHAR} { return CHAR; }

{NOT} { return NOT; }

{OR} { return OR; }

{ASSIGN} { return ASSIGNOP; }

{PROCEDURE} { return PROCEDURE; }

{READ} { return READ; }

{WRITE} { return WRITE;}

{THEN} { return THEN; }

{TO} { return TO; }

{WHILE} { return WHILE; }

{PLUS} { return ADD; } 

{MINUS} { return MINUS; }

{MULTI} { return MULTI; }

{DIVID} { return DIVID; }

{LT} { return LT; }

{LE} { return LE; }

{EQ} { return EQ; }

{NE} { return NE; }

{GT} { return GT; }

{GE} { return GE; }

{COLON} { return COLON; }

{SEMI} { return SEMI; }

{COMMA} { return COMMA; }

{LC} { return LC; }

{RC} { return RC; }

{LB} { return LB; }

{RB} { return RB; }

{LP} { return LP; }

{RP} { return RP; }

{NUMBER} { yylval.string = ssave(yytext); return NUMBER; }

{NAME} { yylval.string = ssave(yytext); return NAME; }

{CHARCONST} { yylval.string = ssave(yytext); return CHARCONST; }

[\n] { YYINCR(1); }
%%
char *ssave( char *s ) {
  char *p;
  p = malloc(sizeof(s));
  return strcpy(p,yytext);
}



