#include "stdio.h"

typedef struct{
    int label1;
    int label2;
    int exit;
} IfStmt;

typedef struct{
    char *name;
    int value;
    int isI; // 0 false, 1 true;
    int type; // 0 for int, 1 for char
    int registerNumber;
} Variable;

typedef struct{
    int label;
    int exit;
    int addr;
    int addrUpper;
    Variable *byExpr;
} ForStmt;

typedef struct{
    int label;
    int exit;
    int addr;
    int boolLabel;
} WhileStmt;

