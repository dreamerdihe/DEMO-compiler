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
   struct Array *array;
   struct Dim *dim; 
   struct Indices *index;
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

%type<variable> Factor Term Stmt Expr Stmts Reference 
%type<variable> Bool OrTerm AndTerm RelExpr
%type<ifStmt> IfStmt WithElse IfStmtElse
%type<forStmt> ForStmt
%type<whileStmt> WhileStmt WhileHead
%type<dim> Bound
%type<array> Bounds
%type<index> Exprs

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
         Variable *vari = getVariable($1, type, registerNumber);
         vari->array = NULL;
         insert($1, vari);
      }
     | NAME LB Bounds RB
      {
         Array *array = (Array *)$3;
         array->type = type;
         array->base = nextBase(array);// upadte the base for next
         Variable *vari = getVariable($1, type, array->base);
         vari->array = array;
         insert($1, vari);
      }   
;

Bounds : Bounds COMMA Bound
         {
            Array *array = (Array *)$1;
            Dim *dim = (Dim *)$3;
            array->dim++;
            array->dims[array->dim - 1][0] = dim->lower;
            array->dims[array->dim - 1][1] = dim->upper;  
            $$ = (struct Array *)array;  
         }
       | Bound 
       {
         Array *array = malloc(sizeof(Array));
         Dim *dim = (Dim *)$1;
         array->dim = 1;
         array->dims[array->dim - 1][0] = dim->lower;
         array->dims[array->dim - 1][1] = dim->upper;
         $$ = (struct Array *)array;
       }
;

Bound : NUMBER COLON NUMBER
      {
         Dim *dim = malloc(sizeof(Dim));
         dim->lower = atoi($1);
         dim->upper = atoi($3);
         $$ = (struct Dim *)dim;
      }
;

Stmts : Stmts Stmt
      | Stmt
;

IfStmt : IF LP Bool RP
         {
            IfStmt *ifstmt = malloc(sizeof(IfStmt));
            ifstmt->label1 = Nextlabel();
            ifstmt->label2 = Nextlabel();
            ifstmt->exit = Nextlabel();

            $$ = (struct IfStmt*)ifstmt;
            Variable *bool = (Variable *)$3;
            Emit(-1, cbr, bool->registerNumber, ifstmt->label1, ifstmt->label2);
            Emit(ifstmt->label1, nop, -1, -1, -1);
         }
;

ForStmt : FOR NAME ASSIGNOP Expr TO
            Expr BY Expr 
            {  
               Variable *vari = lookup($2);
               if(vari == NULL) {
                  yyerror("need declare first\n");
               } 
               if(vari->array != NULL) {
                  yyerror("Using an array reference in for loop\n");
               }
               ForStmt *forstmt = malloc(sizeof(ForStmt));
               forstmt->label = Nextlabel();
               forstmt->exit = Nextlabel();
               forstmt->addr = vari->registerNumber;
               
               Variable *lower = (Variable *)$4;
               if(lower->isI == 1) {
                  Emit(-1, loadI, lower->value, vari->registerNumber, -1);
               } else {
                  if(lower->type == 0) { // int
                     Emit(-1, i2i, lower->registerNumber, vari->registerNumber, -1);
                  } else { // char
                     Emit(-1, c2c, lower->registerNumber, vari->registerNumber, -1);
                  }
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
;

WhileHead : WHILE LP
             {
               WhileStmt *whilestmt = malloc(sizeof(WhileStmt));
               whilestmt->boolLabel = Nextlabel();
               Emit(whilestmt->boolLabel, nop, -1, -1, -1);
               $$ = (struct WhileStmt *)whilestmt;
            }
;

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
;

IfStmtElse : IfStmt THEN WithElse ELSE 
            {
               IfStmt *ifstmt = (IfStmt *)$1;
               Emit(-1, br, ifstmt->exit, -1, -1);
               Emit(ifstmt->label2, nop, -1, -1, -1);
               $$ = (struct IfStmt *)ifstmt;
            }
;

Stmt : Reference ASSIGNOP Expr SEMI 
      {
         Variable* result = (Variable*)$1;
         Variable* value = (Variable*)$3;

         if(result->array == NULL) {
            if(value->isI == 0) {
                  if(value->type == 0) { // int
                     Emit(-1, i2i, value->registerNumber, result->registerNumber, -1);
                  } else { // char
                     Emit(-1, c2c, value->registerNumber, result->registerNumber, -1);
                  }
            } else {
               if(value->type == 0) {
                  Emit(-1, loadI, value->value, result->registerNumber, -1);
                  result->value = value->value;
               } else {
                  Emit(-1, loadI, value->value, result->registerNumber, -1);
                  int newAddr = NextRegister();
                  Emit(-1, i2c, result->registerNumber, newAddr, -1);
                  result->registerNumber = newAddr;
               }
            }
         } else {
            if(value->isI == 0) {
               Emit(-1, store, value->registerNumber, result->registerNumber, -1);
            } else {
               if(value->type == 0) { // int
                  int tempReg = NextRegister();
                  Emit(-1, loadI, value->value, tempReg, -1);
                  Emit(-1, store, tempReg, result->registerNumber, -1);
               } else { // char
                  int tempReg = NextRegister();
                  int temptempReg = NextRegister();
                  Emit(-1, loadI, value->value, temptempReg, -1);
                  Emit(-1, i2c, temptempReg, tempReg, -1);
                  Emit(-1, cstore, tempReg, result->registerNumber, -1);
               }
            }
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
     | IfStmtElse WithElse 
     {
        IfStmt *ifstmt = (IfStmt *)$1;
        Emit(-1, br, ifstmt->exit, -1, -1);
        Emit(ifstmt->exit, nop, -1, -1, -1);
     }
     | READ Reference SEMI
     {
        Variable *target = (Variable *)$2;
        if(target->array == NULL) { // not array
            if(target->type == 0) { // int
               Emit(-1, read, target->registerNumber, -1, -1);
            } else {
               Emit(-1, cread, target->registerNumber, -1, -1);
            }
        } else {
           if(target->type == 0) { // int
               int intAddr = NextRegister();
               Emit(-1, read, intAddr, -1 ,-1);
               Emit(-1, store, intAddr, target->registerNumber, -1);
           } else { // char
               int charAddr = NextRegister();
               Emit(-1, cread, charAddr, -1, -1);
               Emit(-1, cstore, charAddr, target->registerNumber, -1);
           }
        }
     }
     | WRITE Expr SEMI
     {
         Variable *node = (Variable *)$2;
         if(node->array == NULL) {
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
         } else { // array
            if(node->array->type == 0) { // int 
               int result = NextRegister();
               Emit(-1, load, node->registerNumber, result, -1);
               Emit(-1, write, result, -1, -1);
            } else { // char
               int result = NextRegister();
               Emit(-1, cload, node->registerNumber, result, -1);
               Emit(-1, cwrite, result, -1, -1);
            }
            
         }
     }
     | NAME NAME SEMI
       {yyerror("Invalid expression"); yyerrok;}
     | error
;

WithElse : IfStmtElse WithElse
         | Reference ASSIGNOP Expr SEMI
         {
            Variable* result = (Variable*)$1;
            Variable* value = (Variable*)$3;

            if(result->array == NULL) { //not array
               if(value->isI == 0) {
                  if(value->type == 0) { // int
                     Emit(-1, i2i, value->registerNumber, result->registerNumber, -1);
                  } else { // char
                     Emit(-1, c2c, value->registerNumber, result->registerNumber, -1);
                  }
               } else {
                  if(value->type == 0) {
                     Emit(-1, loadI, value->value, result->registerNumber, -1);
                     result->value = value->value;
                  } else {
                     Emit(-1, loadI, value->value, result->registerNumber, -1);
                     int newAddr = NextRegister();
                     Emit(-1, i2c, result->registerNumber, newAddr, -1);
                     result->registerNumber = newAddr;
                  }
               }
            } else { // array
               if(value->isI == 0) {
                  Emit(-1, store, value->registerNumber, result->registerNumber, -1);
               } else {
                  if(value->type == 0) { // int
                     int tempReg = NextRegister();
                     Emit(-1, loadI, value->value, tempReg, -1);
                     Emit(-1, store, tempReg, result->registerNumber, -1);
                  } else { // char
                     int tempReg = NextRegister();
                     int temptempReg = NextRegister();
                     Emit(-1, loadI, value->value, temptempReg, -1);
                     Emit(-1, i2c, temptempReg, tempReg, -1);
                     Emit(-1, cstore, tempReg, result->registerNumber, -1);
                  }
               }
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
         | READ Reference SEMI
         | WRITE Expr SEMI
         {
            Variable *node = (Variable *)$2;
            if(node->array == NULL) {
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
            } else { // is an array
               if(node->array->type == 0) { // int 
                  int result = NextRegister();
                  Emit(-1, load, node->registerNumber, result, -1);
                  Emit(-1, write, result, -1, -1);
               } else { // char
                  int result = NextRegister();
                  Emit(-1, cload, node->registerNumber, result, -1);
                  Emit(-1, cwrite, result, -1, -1);
               }
               
            }
      }
         | error ';' {yyerror("Redundent ';'"); yyclearin; yyerrok;}
         | error
;

Bool : NOT OrTerm
      {
         Variable *bool = (Variable *)$2;
         Variable *result = malloc(sizeof(Variable));
         result->registerNumber = NextRegister();

         if(bool->isI == 1) {
            bool->registerNumber = NextRegister();
            Emit(-1, loadI, bool->value, bool->registerNumber, -1);
         }

         Emit(-1, not, bool->registerNumber, result->registerNumber, -1);
         $$ = (struct Variable*)result;
      }
     | OrTerm
      {
         $$ = $1;
      }
;

OrTerm : OrTerm OR AndTerm
         {
            Variable *left = (Variable *)$1;
            Variable *right = (Variable *)$3;
            Variable *result = malloc(sizeof(Variable));
            result->registerNumber = NextRegister();

            if(left->isI == 1) {
               left->registerNumber = NextRegister();
               Emit(-1, loadI, left->value, left->registerNumber, -1);
            }

            if(right->isI == 1) {
               right->registerNumber = NextRegister();
               Emit(-1, loadI, right->value, right->registerNumber, -1);
            }

            Emit(-1, or, left->registerNumber, right->registerNumber, result->registerNumber);
            $$ = (struct Variable*)result;
         
         }
       | AndTerm
       {
          $$ = $1;
       }
;

AndTerm : AndTerm AND RelExpr
         {
            Variable *left = (Variable *)$1;
            Variable *right = (Variable *)$3;
            Variable *result = malloc(sizeof(Variable));
            result->registerNumber = NextRegister();

            if(left->isI == 1) {
               left->registerNumber = NextRegister();
               Emit(-1, loadI, left->value, left->registerNumber, -1);
            }

            if(right->isI == 1) {
               right->registerNumber = NextRegister();
               Emit(-1, loadI, right->value, right->registerNumber, -1);
            }

            Emit(-1, and, left->registerNumber, right->registerNumber, result->registerNumber);
            $$ = (struct Variable*)result;
         }
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
        if(right->array != NULL && left->array != NULL) {
            int leftAddr = NextRegister();
            Emit(-1, load, left->registerNumber, leftAddr, -1);
            int rightAddr = NextRegister();
            Emit(-1, load, right->registerNumber, rightAddr, -1);
            result->registerNumber = NextRegister();
            Emit(-1, add, leftAddr, rightAddr, result->registerNumber);
         } else if(right->array != NULL){
            int addr = NextRegister();
            Emit(-1, load, right->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(left->isI == 1) {
               Emit(-1, addI, addr, left->value, result->registerNumber);
            } else {
               Emit(-1, add, left->registerNumber, addr, result->registerNumber);
            }
         } else if(left->array != NULL) {
            int addr = NextRegister();
            Emit(-1, load, left->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(right->isI == 1) {
               Emit(-1, addI, addr, right->value, result->registerNumber);
            } else {
               Emit(-1, add, right->registerNumber, addr, result->registerNumber);
            }
         } else {
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
         }
         
         $$ = (struct Variable*)result;
      }
     | Expr MINUS Term
     {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(right->array != NULL && left->array != NULL) {
            int leftAddr = NextRegister();
            Emit(-1, load, left->registerNumber, leftAddr, -1);
            int rightAddr = NextRegister();
            Emit(-1, load, right->registerNumber, rightAddr, -1);
            result->registerNumber = NextRegister();
            Emit(-1, sub, leftAddr, rightAddr, result->registerNumber);
         } else if(right->array != NULL){
            int addr = NextRegister();
            Emit(-1, load, right->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(left->isI == 1) {
               int tempReg = NextRegister();
               Emit(-1, loadI, left->value, tempReg, -1);
               Emit(-1, sub, tempReg, addr, result->registerNumber);
            } else {
               Emit(-1, sub, left->registerNumber, addr, result->registerNumber);
            }
         } else if(left->array != NULL) {
            int addr = NextRegister();
            Emit(-1, load, left->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(right->isI == 1) {
               Emit(-1, subI, addr, right->value, result->registerNumber);
            } else {
               Emit(-1, sub, right->registerNumber, addr, result->registerNumber);
            }
         } else {
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
         if(right->array != NULL && left->array != NULL) {
            int leftAddr = NextRegister();
            Emit(-1, load, left->registerNumber, leftAddr, -1);
            int rightAddr = NextRegister();
            Emit(-1, load, right->registerNumber, rightAddr, -1);
            result->registerNumber = NextRegister();
            Emit(-1, mult, leftAddr, rightAddr, result->registerNumber);
         } else if(right->array != NULL){
            int addr = NextRegister();
            Emit(-1, load, right->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(left->isI == 1) {
               Emit(-1, multI, addr, left->value, result->registerNumber);
            } else {
               Emit(-1, mult, left->registerNumber, addr, result->registerNumber);
            }
         } else if(left->array != NULL) {
            int addr = NextRegister();
            Emit(-1, load, left->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(right->isI == 1) {
               Emit(-1, multI, addr, right->value, result->registerNumber);
            } else {
               Emit(-1, mult, right->registerNumber, addr, result->registerNumber);
            }
         } else {
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
         }

         $$ = (struct Variable*)result;
      }
     | Term DIVID Factor
     {
         Variable *result = malloc(sizeof(Variable));
         Variable *left = (Variable *)$1;
         Variable *right = (Variable *)$3;
         if(right->array != NULL && left->array != NULL) {
            int leftAddr = NextRegister();
            Emit(-1, load, left->registerNumber, leftAddr, -1);
            int rightAddr = NextRegister();
            Emit(-1, load, right->registerNumber, rightAddr, -1);
            result->registerNumber = NextRegister();
            Emit(-1, _div, leftAddr, rightAddr, result->registerNumber);
         } else if(right->array != NULL){
            int addr = NextRegister();
            Emit(-1, load, right->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(left->isI == 1) {
               int tempReg = NextRegister();
               Emit(-1, loadI, left->value, tempReg, -1);
               Emit(-1, _div, tempReg, addr, result->registerNumber);
            } else {
               Emit(-1, _div, left->registerNumber, addr, result->registerNumber);
            }
         } else if(left->array != NULL) {
            int addr = NextRegister();
            Emit(-1, load, left->registerNumber, addr, -1);
            result->registerNumber = NextRegister();
            if(right->isI == 1) {
               Emit(-1, divI, addr, right->value, result->registerNumber);
            } else {
               Emit(-1, _div, right->registerNumber, addr, result->registerNumber);
            }
         } else {
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
         }

         $$ = (struct Variable*)result;
     } 
     | Factor
       {$$ = $1;}
;

Factor : LP Expr RP
       | Reference 
         {  
            $$ = $1;
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
                  yyerror("need declare first\n");
               } else {
                  $$ = vari;
               }
            }
          | NAME LB Exprs RB
            {
               Variable *array = lookup($1);
               if(array == NULL) {
                  yyerror("need declare first\n");
               }
               if(array->array == NULL) {
                  yyerror("not refered an array");
               }
               Indices *index = (Indices *)$3;
               int bytes = array->array->type == 0? 4 : 1;
               
               int indexAddr = NextRegister(); // base
               Emit(-1, loadI, array->array->base, indexAddr, -1);

               int offset = NextRegister();
               Emit(-1, loadI, 0, offset, -1);
               int by = 1;
               int dims = array->array->dim;
               int bounds[4];
               for(int dim = 0; dim < dims; dim++) {
                  bounds[dim] = array->array->dims[dim][1] - array->array->dims[dim][0];
                  by *= bounds[dim];
               }
               for(int dim = 0; dim < dims - 1; dim++) {
                  int tempReg = NextRegister();
                  Emit(-1, multI, index->index[dim], by, tempReg);
                  Emit(-1, add, offset, tempReg, offset);
                  by /= bounds[dim];
               }
               
               Emit(-1, add, offset, index->index[dims - 1], offset);
               
               // times sizeof(int/char)
               Emit(-1, multI, offset, bytes, offset);
               // base + offset
               Emit(-1, add, indexAddr, offset, indexAddr);
               
               array->registerNumber = indexAddr;
               $$ = (struct Variable *)array;
            }
;

Exprs : Exprs COMMA Expr
      {
         Indices *index = (Indices *)$1;
         if(index == NULL) {
            index = malloc(sizeof(Indices));
            index->dim = 0;
         }

         Variable *temp = (Variable *)$3;
         index->index[index->dim] = temp->registerNumber;
         index->dim++;
         $$ = (struct Indices *)index;
      }
      | Expr
      {  
         Variable *vari = (Variable *)$1;
         if(vari->isI) {
            vari->registerNumber = NextRegister();
            Emit(-1, loadI, vari->value, vari->registerNumber, -1);
         }
         Indices *index = malloc(sizeof(Indices));
         index->index[0] = vari->registerNumber;
         index->dim = 1;
         $$ = (struct Indices *)index;
      }
;

%%

void yyerror(char *s) {
   syntax_error ++;
   fprintf(stderr, "Parser: '%s' around line %d.\n", s, yylineno);
}