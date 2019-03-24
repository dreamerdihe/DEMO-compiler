#include "symbolTable.h"

int nextBase(Array *array) {
	int base = globalBase;
	int dims = array->dim;
    int bytes = (array->type == 0)? 4 : 1;
	int elements = 1;
    for(int i = 0; i < dims; i++) {
        elements *= (array->dims[i][1] - array->dims[i][0]);
    }
	globalBase += elements * bytes;
    return base;
}

Variable * getVariable(char *name, int type, int registerNumber) {
    Variable * v = malloc(sizeof(Variable));
    v->name = name;
    v->type = type;
    v->isI = 0;
    v->registerNumber = registerNumber;
    return v;
}

unsigned int hash(char * key) {
	
	unsigned	int h = 0;
	for (; *key; key++)
		h = *key + h * 31;

	return h%HASHSIZE;
}

Variable * lookup(char * key) {
	unsigned int hashvalue = hash(key);
	node * np = hashtable[hashvalue];

	for (; np != NULL; np = np->next) {
		if (!strcmp(np->name, key)) {
			return np->value;
		}
	}

    return NULL;
}

node * malloc_node(char * key, Variable * value) {
	node * np = (node*)malloc(sizeof(node));
	if (np == NULL)return NULL;

	np->name = key;
	np->value = value;
	np->next = NULL;
	return np;
}

int insert(char * key, Variable * value) {
	unsigned int hashvalue = hash(key);
	node * np = malloc_node(key, value);
	if (np == NULL) return 0;

	np->next = hashtable[hashvalue];
	hashtable[hashvalue] = np;
	return 1;
}

void clearHashTable() {
	node * np; 
	node *tmp;

	for (int i = 0; i < HASHSIZE; i++) {
		np = hashtable[i];
		if (np != NULL) {

			hashtable[i] = NULL;
			tmp = np;
			tmp = tmp->next;
			free(np);
			while (tmp!=NULL) {
				np = tmp;
				free(np);
				tmp = tmp->next;
			}
		}
	}
}

void printHashTable() {
    printf("\n------------print symbol table--------------\n");
	node *np;
	int hashvalue;
	for (int i = 0; i < HASHSIZE; i++) {
		if (hashtable[i] != NULL) {
			np = hashtable[i];
			for (; np != NULL; np=np->next) {
				char isArray[20] = "";
				if(np->value->array != NULL) {
					strcpy(isArray, "Array");
				}

                char* type;
                if(np->value->type == 0) {
                    type = "int";
                } else if(np->value->type == 1) {
                    type = "char";
                }
                char* isI;
                if(np->value->isI == 0) {
                    isI = "not immediate";
                } else {
                    isI = "is immediate";
                }

				if(np->value->array != NULL) {
					printf("%s,\t%s,\tbase%d,\t%d dims,\t%s", np->value->name, type, np->value->array->base, np->value->array->dim, isArray);
				} else {
					printf("%s,\t%s,\tr%d,\t%s,\t%d,\t%s", np->value->name, type, np->value->registerNumber, isI, np->value->value, isArray);
				}
				
			}
			printf("\n");
		}
	}

    printf("\n------------print symbol table--------------\n");
}