#include "stdio.h"
#include <string.h>
#include "ilocEmitter.h"

int NextRegister() {
    globalRg++;
    return globalRg;
}

int Nextlabel() {
    globalLabel++;
    return globalLabel;
}

void Emit(int labelId, OpCode opcode, int addr0, int addr1, int addr2) {
    extern FILE *oput;
    char* label = "";
    if(labelId > -1) {
        *label = sprintf(label, "L%d:", labelId);
    }
    
    switch (opcode)
    {
        case nop:
            fprintf(oput, "%s\t nop \n", label);
            break;
        case add:
            fprintf(oput, "%s\t add     r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case addI:
            fprintf(oput, "%s\t addI    r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case sub:
            fprintf(oput, "%s\t sub     r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case subI:
            fprintf(oput, "%s\t subI    r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case mult:
            fprintf(oput, "%s\t mult    r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case multI:
            fprintf(oput, "%s\t multI   r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case _div:
            fprintf(oput, "%s\t div     r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
         case divI:
            fprintf(oput, "%s\t divI    r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case lshift:
            fprintf(oput, "%s\t lshift  r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case lshiftI:
            fprintf(oput, "%s\t lshiftI r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case rshift:
            fprintf(oput, "%s\t rshift  r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case rshiftI:
            fprintf(oput, "%s\t rshiftI r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case and:
            fprintf(oput, "%s\t and     r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case andI:
            fprintf(oput, "%s\t andI    r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case or:
            fprintf(oput, "%s\t or      r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case orI:
            fprintf(oput, "%s\t orI     r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case not:
            fprintf(oput, "%s\t not     r%d      \t=> r%d \n", label, addr0, addr1);
            break;
        case loadI:
            fprintf(oput, "%s\t loadI   %d       \t=> r%d \n", label, addr0, addr1);
            break;
        case load:
            fprintf(oput, "%s\t load    r%d      \t=> r%d \n", label, addr0, addr1);
            break;
        case loadAI:
            fprintf(oput, "%s\t loadAI  r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case loadAO:
            fprintf(oput, "%s\t loadAO  r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case cload:
            fprintf(oput, "%s\t cload   r%d      \t=> r%d \n", label, addr0, addr1);
            break;
        case cloadAI:
            fprintf(oput, "%s\t cloadAI r%d, %d  \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case cloadAO:
            fprintf(oput, "%s\t cloadAO r%d, r%d \t=> r%d \n", label, addr0, addr1, addr2);
            break;
        case store:
            fprintf(oput, "%s\t store   r%d      \t=> r%d \n", label, addr0, addr1);
            break;
        case storeAI:
            fprintf(oput, "%s\t storeAI %d       \t=> r%d, %d \n", label, addr0, addr1, addr2);
            break; 
        case storeAO:
            fprintf(oput, "%s\t storeAO r%d      \t=> r%d, r%d \n", label, addr0, addr1, addr2);
            break;
        case cstore:
            fprintf(oput, "%s\t cstore  r%d      \t=> r%d \n", label, addr0, addr1);
            break;
        case cstoreAI:
            fprintf(oput, "%s\t cstoreAI r%d     \t=> r%d, %d \n", label, addr0, addr1, addr2);
            break;
        case cstoreAO:
            fprintf(oput, "%s\t cstoreAO r%d     \t=> r%d, r%d \n", label, addr0, addr1, addr2);
            break;
        case i2i:
            fprintf(oput, "%s\t i2i      r%d     \t=> r%d \n", label, addr0, addr1);
            break;
        case c2c:
            fprintf(oput, "%s\t c2c      r%d     \t=> r%d \n", label, addr0, addr1);
            break;
        case i2c:
            fprintf(oput, "%s\t i2c      r%d     \t=> r%d \n", label, addr0, addr1);
            break;
        case c2i:
            fprintf(oput, "%s\t c2i      r%d     \t=> r%d \n", label, addr0, addr1);
            break; 
        case br:
            fprintf(oput, "%s\t br               \t=> L%d \n", label, addr0);
            break;
        case cbr:
            fprintf(oput, "%s\t cbr      r%d     \t=> L%d, L%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_LT:
            fprintf(oput, "%s\t cmp_LT   r%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_LE:
            fprintf(oput, "%s\t cmp_LE   rr%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_GT:
            fprintf(oput, "%s\t cmp_GT   r%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_GE:
            fprintf(oput, "%s\t cmp_GE   r%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_EQ:
            fprintf(oput, "%s\t cmp_EQ   r%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;
        case cmp_NE:
            fprintf(oput, "%s\t cmp_NE   r%d, r%d \t=>  r%d \n", label, addr0, addr1, addr2);
            break;  
        case halt:
            fprintf(oput, "%s\t halt \n", label);
            break;  
        case read:
            fprintf(oput, "%s\t read             \t=> r%d \n", label, addr0);
            break;
        case cread:
            fprintf(oput, "%s\t cread            \t=> r%d \n", label, addr0);
            break;
        case output:
            fprintf(oput, "%s\t oput  %d   \n", label, addr0);
            break;
        case coutput:
            fprintf(oput, "%s\t coput %d   \n", label, addr0);
            break;
        case write:
            fprintf(oput, "%s\t write   r%d  \n", label, addr0);
            break;
        case cwrite:
            fprintf(oput, "%s\t cwrite  r%d  \n", label, addr0);
            break;
    }
}