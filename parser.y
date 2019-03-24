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
   struct IfStmt *ifStmt;
   struct ForStmt *forStmt;
   struct WhileStmt *whileStmt;
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
%token <string>  NUMBER
%token <string> CHARCONST
%token ENDOFFILE
%start Procedure

%type<variable> Factor Term Expr Stmt Stmts Reference
%type<variable> Bool OrTerm AndTerm RelExpr
%type<ifStmt> IfStmt WithElse
%type<forStmt> ForStmt
%type<whileStmt> WhileStmt WhileHead

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

IfStmt : IF LP Bool RP
         {
            IfStmt *ifstmt = malloc(sizeof(IfStmt));
            ifstmt->label1 = Nextlabel();
            ifstmt->label2 = Nextlabel();
            ifstmt->label3 = Nextlabel();

            $$ = (struct IfStmt*)ifstmt;
            Variable *bool = (Variable *)$3;
            Emit(-1, cbr, bool->registerNumber, ifstmt->label1, ifstmt->label2);
            Emit(ifstmt->label1, nop, -1, -1, -1);
         }

ForStmt : FOR NAME ASSIGNOP Expr TO
            Expr BY Expr 
            {
               Variable *vari = lookup($2);
               if(vari == NULL) {
                  yyerror("need declare firt\n");
               } 

               ForStmt *forstmt = malloc(sizeof(ForStmt));
               forstmt->label = Nextlabel();
               forstmt->exit = Nextlabel();
               forstmt->addr = vari->registerNumber;
               
               Variable *lower = (Variable *)$4;
               if(lower->isI == 1) {
                  Emit(-1, loadI, lower->value, vari->registerNumber, -1);
               } else {
                  Emit(-1, load, lower->registerNumber, vari->registerNumber, -1);
               }

               Variable *upper = (Variable *)$6;
               
               if(upper->isI == 1) {
                  int addrUpper = NextRegister();
                  Emit(-1, loadI, upper->value, addrUpper, -1);
                  forstmt->addrUpper = addrUpper;
               } else {
                  forstmt->addrUpper = upper->registerNumber;
               }

               int addrBool = NextRegister();
               Emit(-1, cmp_LE, vari->registerNumber, forstmt->addrUpper, addrBool);

               
               Emit(-1, cbr, addrBool, forstmt->label, forstmt->exit);
               Emit(forstmt->label, nop, -1, -1, -1);

               Variable *byExpr = (Variable *)$8;
               forstmt->byExpr = byExpr;
               $$ = (struct ForStmt*)forstmt;
            }
WhileHead : WHILE LP
             {
               WhileStmt *whilestmt = malloc(sizeof(WhileStmt));
               whilestmt->boolLabel = Nextlabel();
               Emit(whilestmt->boolLabel, nop, -1, -1, -1);
               $$ = (struct WhileStmt *)whilestmt;
            }

WhileStmt : WhileHead Bool RP 
            {
               WhileStmt *whilehead = (WhileStmt *)$1;
               WhileStmt *whilestmt = malloc(sizeof(WhileStmt));
               Variable *bool = (Variable *)$2;

               whilestmt->label = Nextlabel();
               whilestmt->exit = Nextlabel();
               whilestmt->addr = bool->registerNumber;
               whilestmt->boolLabel = whilehead->boolLabel;
               $$ = (struct WhileStmt *)whilestmt;
               Emit(-1, cbr, whilestmt->addr, whilestmt->label, whilestmt->exit);
               Emit(whilestmt->label, nop, -1, -1, -1);
            }

Stmt : Reference ASSIGNOP Expr SEMI 
      {
         Variable* node1 = (Variable*)$1;
         Variable* node3 = (Variable*)$3;

         if(node1->type == 0) { // it is an int
            int addr1 = node1->registerNumber;
            if(node3->isI == 1) {
               int value = node3->value;
               Emit(-1, loadI, value, addr1, -1);
               node1->value = value;
            } else {
               int addr0 = node3->registerNumber;
               Emit(-1, i2i, addr0, addr1, -1);
            }
         } else if(node1->type == 1) {// it is a char
            int addr0 = NextRegister();
            int value = node3->value;
            Emit(-1, loadI, value, addr0, -1);
            int addr1 = node1->registerNumber;
            Emit(-1, i2c, addr0, addr1, -1);
         }
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
     | WhileStmt LC Stmts RC
     {
        WhileStmt * whilestmt = (WhileStmt *)$1;
        Emit(-1, br, whilestmt->boolLabel, -1, -1);
        Emit(whilestmt->exit, nop, -1, -1, -1);
     }
     | ForStmt LC Stmts RC
     {
         ForStmt *forstmt = (ForStmt *)$1;
         if(forstmt->byExpr->isI == 1) {
            Emit(-1, addI, forstmt->addr, forstmt->byExpr->value, forstmt->addr);
         } else {
            Emit(-1, add, forstmt->addr, forstmt->byExpr->registerNumber, forstmt->addr);
         }

         int addrBool = NextRegister();
         Emit(-1, cmp_LE, forstmt->addr, forstmt->addrUpper, addrBool);
         Emit(-1, cbr, addrBool, forstmt->label, forstmt->exit);
         Emit(forstmt->exit, nop, -1, -1, -1);
     }
     | IfStmt THEN Stmt
      {
         IfStmt *ifstmt = (IfStmt *)$1;
         Emit(ifstmt->label2, nop, -1, -1, -1);
      }
     | IfStmt THEN WithElse
                     ELSE Stmt
     | READ Reference SEMI
     | WRITE Expr SEMI
     {
        Variable *node = (Variable *)$2;
        if(node->isI == 1) { 
           int addr1 = NextRegister();
           if(node->type == 0) {
              Emit(-1, loadI, node->value, addr1, -1);
              Emit(-1, write, addr1, -1, -1);
           } else {
              int addr = NextRegister();
              Emit(-1, loadI, node->value, addr, -1);
              Emit(-1, i2c, addr, addr1, -1);
              Emit(-1, cwrite, addr1, -1, -1);
           }
        } else {
            int addr0 = node->registerNumber;
            if(node->type == 0) {
               Emit(-1, write, addr0, -1, -1);
            } else if(node->type == 1) {
               Emit(-1, cwrite, addr0, -1, -1);
            }
        }
     }
     | NAME NAME SEMI
       {yyerror("Invalid expression"); yyerrok;}
     | error
;

WithElse : IfStmt THEN WithElse 
                         ELSE WithElse
         | Reference ASSIGNOP Expr SEMI
         {
            Variable* node1 = (Variable*)$1;
            Variable* node3 = (Variable*)$3;

            if(node1->type == 0) { // it is an int
               int addr1 = node1->registerNumber;
               if(node3->isI == 1) {
                  int value = node3->value;
                  Emit(-1, loadI, value, addr1, -1);
                  node1->value = value;
               } else {
                  int addr0 = node3->registerNumber;
                  Emit(-1, i2i, addr0, addr1, -1);
               }
            } else if(node1->type == 1) {// it is a char
               int addr0 = NextRegister();
               int value = node3->value;
               Emit(-1, loadI, value, addr0, -1);
               int addr1 = node1->registerNumber;
               Emit(-1, i2c, addr0, addr1, -1);
            }
         }
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
         {
            Variable *node = (Variable *)$2;
            if(node->isI == 1) { 
               int addr1 = NextRegister();
               if(node->type == 0) {
                  Emit(-1, loadI, node->value, addr1, -1);
                  Emit(-1, write, addr1, -1, -1);
               } else {
                  int addr = NextRegister();
                  Emit(-1, loadI, node->value, addr, -1);
                  Emit(-1, i2c, addr, addr1, -1);
                  Emit(-1, cwrite, addr1, -1, -1);
               }
            } else {
                  int addr0 = node->registerNumber;
                  if(node->type == 0) {
                     Emit(-1, write, addr0, -1, -1);
                  } else if(node->type == 1) {
                     Emit(-1, cwrite, addr0, -1, -1);
                  }
            }
         }
         | error ';' {yyerror("Redundent ';'"); yyclearin; yyerrok;}
         | error

Bool : NOT OrTerm
     | OrTerm
      {
         $$ = $1;
      }
;

OrTerm : OrTerm OR AndTerm
       | AndTerm
       {
          $$ = $1;
       }
;

AndTerm : AndTerm AND RelExpr
        | RelExpr
        {
           $$ = $1;
        }
;

RelExpr : RelExpr LT Expr 
         {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LT, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LT, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LT, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LT, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }
        | RelExpr LE Expr 
         {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LE, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LE, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LE, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_LE, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }
        | RelExpr EQ Expr 
         {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_EQ, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_EQ, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_EQ, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_EQ, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }    
        | RelExpr NE Expr 
         {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_NE, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_NE, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_NE, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_NE, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }
        | RelExpr GE Expr
         {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GE, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GE, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GE, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GE, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }
        | RelExpr GT Expr 
        {
            Variable *node = malloc(sizeof(Variable));
            Variable *left = (Variable*)$1;
            Variable *right = (Variable*)$3;
            if(left->isI == 1 && right->isI == 1) {
               int addr1 = NextRegister();
               int addr2 = NextRegister();
               Emit(-1, loadI, left->value, addr1, -1);
               if(left->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               Emit(-1, loadI, right->value, addr2, -1);
               if(right->type == 1) {
                  int addr = NextRegister();
                  Emit(-1, i2c, addr2, addr, -1);
               }
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GT, addr1, addr2, node->registerNumber);
            } else if(left->isI == 0 && right->isI == 1) {
               int addr1 = NextRegister();
               Emit(-1, loadI, right->value, addr1, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr1, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GT, left->registerNumber, addr1, node->registerNumber);
            } else if(left->isI == 1 && right->isI == 0) {
               int addr0 = NextRegister();
               Emit(-1, loadI, left->value, addr0, -1);
               if(right->type == 1) {// left is a char
                  int addr = NextRegister();
                  Emit(-1, i2c, addr0, addr, -1);
                  
               } 
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GT, addr0, left->registerNumber, node->registerNumber);
            } else {
               node->registerNumber = NextRegister();
               Emit(-1, cmp_GT, left->registerNumber, right->registerNumber, node->registerNumber);
            }
            
            $$ = (struct Variable*)node;
         }
        | Expr
          {
             $$ = $1;
          }
;

Expr : Expr ADD Term
      {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(left->isI == 1 && right->isI == 1) {
            int immd = left->value + right->value;
            result->value = immd;
            result->isI = 1;
            $$ = (struct Variable*)result;   
         } else if(left->isI == 1 && right->isI == 0) {
            int addr0 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, addI, addr0, left->value, result->registerNumber);
         } else if(left->isI == 0 && right->isI == 1) {
            int addr0 = left->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, addI, addr0, right->value, result->registerNumber);
         } else {
            int addr0 = left->registerNumber;
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, add, addr0, addr1, result->registerNumber);
         }

         $$ = (struct Variable*)result;
      }
     | Expr MINUS Term
     {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(left->isI == 1 && right->isI == 1) {
            int immd = left->value - right->value;
            result->value = immd;
            result->isI = 1;
            $$ = (struct Variable*)result;   
         }  else if(left->isI == 0 && right->isI == 1) {
            int addr0 = left->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, subI, addr0, right->value, result->registerNumber);
         }  else if(left->isI == 1 && right->isI == 0) {
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            int newRegister = NextRegister();
            Emit(-1, loadI, left->value, newRegister, -1);
            Emit(-1, sub, newRegister, addr1, result->registerNumber);
         }  else {
            int addr0 = left->registerNumber;
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, sub, addr0, addr1, result->registerNumber);
         }

         $$ = (struct Variable*)result;
     }
     | Term
       {$$ = $1;}
;

Term : Term MULTI Factor
      {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(left->isI == 1 && right->isI == 1) {
            int immd = left->value * right->value;
            result->value = immd;
            result->isI = 1;
            $$ = (struct Variable*)result;   
         } else if(left->isI == 1 && right->isI == 0) {
            int addr0 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, multI, addr0, left->value, result->registerNumber);
         } else if(left->isI == 0 && right->isI == 1) {
            int addr0 = left->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, multI, addr0, right->value, result->registerNumber);
         } else {
            int addr0 = left->registerNumber;
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, mult, addr0, addr1, result->registerNumber);
         }

         $$ = (struct Variable*)result;
      }
     | Term DIVID Factor
     {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(left->isI == 1 && right->isI == 1) {
            int immd = left->value / right->value;
            result->value = immd;
            result->isI = 1;
            $$ = (struct Variable*)result;   
         }  else if(left->isI == 0 && right->isI == 1) {
            int addr0 = left->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, divI, addr0, right->value, result->registerNumber);
         }  else if(left->isI == 1 && right->isI == 0) {
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            int newRegister = NextRegister();
            Emit(-1, loadI, left->value, newRegister, -1);
            Emit(-1, _div, newRegister, addr1, result->registerNumber);
         }  else {
            int addr0 = left->registerNumber;
            int addr1 = right->registerNumber;
            result->registerNumber = NextRegister();
            Emit(-1, _div, addr0, addr1, result->registerNumber);
         }

         $$ = (struct Variable*)result;
     } 
     | Factor
       {$$ = $1;}
;

Factor : LP Expr RP
       | Reference {
          {$$ = $1;}
       }
       | NUMBER 
         {
            Variable *v = malloc(sizeof(Variable));
            v->value = atoi($1);
            v->isI = 1;
            v->type = 0;
            $$ = (struct Variable*)v;
         }
       | CHARCONST
         {
            Variable *v = malloc(sizeof(Variable));
            v->value = (int)$1[1];
            v->isI = 1;
            v->type = 1;
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