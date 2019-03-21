%{
#include <stdio.h>
#include <stdlib.h>
#include "ilocEmitter.c"
#define YYERROR_VERBOSE

 int yylineno;
 int syntax_error = 0;

 extern int yylex(void); 
 int yywrap(void) {return 1;}
 char *yytext;
 char *lexeme;
 void yyerror( char *s );

%}
%token PROCEDURE
%token INT CHAR
%token LC RC
%token LB RB
%token LP RP
%token NAME
%token SEMI COMMA COLON ASSIGNOP
%token WHILE THEN
%token FOR
%token IF ELSE
%token TO BY
%token READ
%token WRITE
%token NOT OR AND
%token LT LE EQ NE GE GT
%token ADD MINUS MULTI DIVID
%token CHARCONST NUMBER
%token ENDOFFILE
%start  Procedure

%%
Procedure : PROCEDURE NAME 
               LC Decls Stmts RC
          | PROCEDURE NAME 
               LC Decls Stmts RC RC
               {yyerror("Unexpected '}'"); yyclearin; yyerrok;}
          | PROCEDURE NAME 
               LC Decls Stmts
               {yyerror("Unexpected '}'"); yyerrok;}

;           

Decls : Decls Decl SEMI
      | Decl SEMI
;

Decl : Type SpecList
;

Type : INT
     | CHAR
;

SpecList : SpecList COMMA Spec
         | Spec
;

Spec : NAME
     | NAME LB Bounds RB
;

Bounds : Bounds COMMA Bound
       | Bound
;

Bound : NUMBER COLON NUMBER
;

Stmts : Stmts Stmt
      | Stmt
;

Stmt : Reference ASSIGNOP Expr SEMI
     | Reference ADD ASSIGNOP Expr SEMI
         {yyerror("Do not use plus equal in demo"); yyerrok;}
     | Reference ASSIGNOP Expr SEMI SEMI
         {yyerror("Unexpected ';' "); yyclearin; yyerrok;}
     | WRITE ASSIGNOP Expr SEMI
         {yyerror("can't assign to write "); yyerrok;}
     | LC Stmts RC
     | LC RC
        {yyerror("Empty expression "); yyerrok;}
     | WHILE LP Bool RP LC Stmts RC
     | FOR NAME ASSIGNOP Expr TO
        Expr BY Expr LC Stmts RC 
     | IF LP Bool RP THEN Stmt
     | IF LP Bool RP THEN WithElse
                     ELSE Stmt
     | READ Reference SEMI
     | WRITE Expr SEMI
     | NAME NAME SEMI
       {yyerror("Invalid expression"); yyerrok;}
     | error
;

WithElse : IF LP Bool RP THEN WithElse 
                         ELSE WithElse
         | Reference ASSIGNOP Expr SEMI
         | Reference ADD ASSIGNOP Expr SEMI
            {yyerror("Do not use plus equal in demo"); yyerrok;}
         | Reference ASSIGNOP Expr SEMI SEMI
            {yyerror("Unexpected ';' "); yyerrok;}
         | WRITE ASSIGNOP Expr SEMI
            {yyerror("can't assign to write "); yyerrok;}
         | LC Stmts RC
         | LC RC
            {yyerror("Empty expression "); yyerrok;}
         | WHILE LP Bool RP LC Stmts RC
         | FOR NAME ASSIGNOP Expr TO
            Expr BY Expr LC Stmts RC
         | READ Reference SEMI
         | WRITE Expr SEMI
         | error ';' {yyerror("Redundent ';'"); yyclearin; yyerrok;}
         | error

Bool : NOT OrTerm
{ $$ = !$2; }
     | OrTerm
;

OrTerm : OrTerm OR AndTerm
{ $$ = $1 || $3; }
       | AndTerm
;

AndTerm : AndTerm AND RelExpr
{ $$ = $1 && $3; }
        | RelExpr
;

RelExpr : RelExpr LT Expr 
{ $$ = $1 < $3; }
        | RelExpr LE Expr 
{ $$ = $1 <= $3; }
        | RelExpr EQ Expr
{ $$ = $1 == $3; }        
        | RelExpr NE Expr 
{ $$ = $1 != $3; }
        | RelExpr GE Expr 
{ $$ = $1 >= $3; }
        | RelExpr GT Expr 
{ $$ = $1 > $3; }
        | Expr
;

Expr : Expr ADD Term
     | Expr MINUS Term
     | Term
;

Term : Term MULTI Factor
     | Term DIVID Factor   
     | Factor
;

Factor : LP Expr RP
{ $$ = $2; }
       | Reference
       | NUMBER 
{ $$ = atoi(lexeme); }
       | CHARCONST
;

Reference : NAME
          | NAME LB Exprs RB
;

Exprs : Expr COMMA Exprs
     | Expr
;

%%

void yyerror(char *s) {
   syntax_error ++;
   fprintf(stderr, "Parser: '%s' around line %d.\n", s, yylineno);
}