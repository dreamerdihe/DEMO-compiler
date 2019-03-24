#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include "struct.h"

#define HASHSIZE 200

typedef struct node{
	char * name;
	Variable * value;
	struct node * next;
}node;

extern int globalBase;

int nextBase(Array *);

static node * hashtable[HASHSIZE];

Variable * getVariable(char *, int, int);

unsigned int hash(char *); 

Variable * lookup(char *);

node * malloc_node(char *, Variable *);

int insert(char *, Variable *);

void clearHashTable(void);

void printHashTable(void);