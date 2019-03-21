%{
#include <stdio.h>
#include <stdlib.h>
#include "ilocEmitter.h"
#include "symbolTable.h"
#define YYERROR_VERBOSE

int yylineno;
int type; // 0 for int, 1 for char
int syntax_error = 0;

extern int yylex(void); 

int yywrap(void) {return 1;}
char *yytext;
char *lexeme;
void yyerror( char *s );

%}
%union {
   char *string;
   struct Variable *variable;
}

%token PROCEDURE
%token INT CHAR
%token LC RC
%token LB RB
%token LP RP
%token<string> NAME
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
%token <string> CHARCONST NUMBER
%token ENDOFFILE
%start Procedure

%type<variable> Factor Term Expr Stmt Stmts Reference

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

Type : INT {type = 0;}
     | CHAR {type = 1;}
;

SpecList : SpecList COMMA Spec
         | Spec
;

Spec : NAME
      {
         int registerNumber = NextRegister();  
         insert($1, getVariable($1, type, registerNumber));
      }
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
      {
         Variable* node1 = (Variable*)$1;
         Variable* node3 = (Variable*)$3;

         int addr1 = node1->registerNumber;
         int value = node3->value;
         Emit(-1, loadI, value, addr1, -1);
      }
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
     | OrTerm
;

OrTerm : OrTerm OR AndTerm
       | AndTerm
;

AndTerm : AndTerm AND RelExpr
        | RelExpr
;

RelExpr : RelExpr LT Expr 
        | RelExpr LE Expr 
        | RelExpr EQ Expr     
        | RelExpr NE Expr 
        | RelExpr GE Expr 
        | RelExpr GT Expr 
        | Expr
;

Expr : Expr ADD Term
      {
         
      }
     | Expr MINUS Term
     | Term
       {$$ = $1;}
;

Term : Term MULTI Factor
     | Term DIVID Factor   
     | Factor
       {$$ = $1;}
;

Factor : LP Expr RP
       | Reference
       | NUMBER 
         {
            Variable *v = malloc(sizeof(Variable));
            v->value = atoi($1);
            $$ = (struct Variable*)v;
         }
       | CHARCONST
         {
            Variable *v = malloc(sizeof(Variable));
            v->value = (int)$1;
            $$ = (struct Variable*)v;
         }
;

Reference : NAME
            {
               struct Variable *vari = (struct Variable *)lookup($1);
               if(vari == NULL) {
                  yyerror("need declare firt\n");
               } else {
                  $$ = vari;
               }
            }
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