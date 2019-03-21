#include<stdio.h>
#include<string.h>
#include<stdlib.h>

#define HASHSIZE 200
typedef struct{
    char *name;
    int value;
    int type;
    int registerNumber;
} Variable;

typedef struct node{
	char * name;
	Variable * value;
	struct node * next;
}node;

static node * hashtable[HASHSIZE];

Variable * getVariable(char *, int, int);

unsigned int hash(char *); 

Variable * lookup(char *);

node * malloc_node(char *, Variable *);

int insert(char *, Variable *);

void clearHashTable(void);

void printHashTable(void);