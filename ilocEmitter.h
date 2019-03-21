#include "stdio.h"

typedef enum {
    nop, add, addI, sub, subI, mult, multI, _div, divI, lshift, 
    lshiftI, rshift, rshiftI, and, andI, or, orI, not, loadI,
    load, loadAI, loadAO, cload, cloadAI, cloadAO, store, storeAI,
    storeAO, cstore, cstoreAI, cstoreAO, i2i, c2c, i2c, c2i, br,
    cbr, cmp_LT, cmp_LE, cmp_GT, cmp_GE, cmp_EQ, cmp_NE, halt, read,
    cread, output, coutput, write, cwrite
} OpCode;