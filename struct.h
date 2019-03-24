#include "stdio.h"

typedef struct{
    int label1;
    int label2;
    int exit;
} IfStmt;

typedef struct{
    int base;
    int dims[4][2]; // dims[i][0] -> lower, dims[i][1] -> upper
    int dim;
    int type; // 0 for int, 1 for char
} Array;

typedef struct{
    int index[4];
    int dim;
} Indices;

typedef struct{
    char *name;
    int value;
    int isI; // 0 false, 1 true;
    int type; // 0 for int, 1 for char
    int registerNumber;
    Array *array;
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

typedef struct{
    int lower; 
    int upper;
} Dim;

