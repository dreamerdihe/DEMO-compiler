#include "symbolTable.h"


Variable * getVariable(char *name, int type, int registerNumber) {
    Variable * v = malloc(sizeof(Variable));
    v->name = name;
    v->type = type;
    v->isI = 0;
    v->registerNumber = registerNumber;
    return v;
}

unsigned int hash(char * key) {
	//这里必须是unsigned int 因为如果字符串很长的话 这里 int是不够的（重点）
	unsigned	int h = 0;
	for (; *key; key++)
		h = *key + h * 31; //特定公式生成整数 用于哈希表上分布均匀（核心）

	return h%HASHSIZE;
}

Variable * lookup(char * key) {
	//字符串求哈希
	unsigned int hashvalue = hash(key);
	//获取哈希表
	node * np = hashtable[hashvalue];
	//在链表上查找
	for (; np != NULL; np = np->next) {
		if (!strcmp(np->name, key)) {
			return np->value;
		}
	}

    return NULL;
}

node * malloc_node(char * key, Variable * value) {
	//分配堆内存
	node * np = (node*)malloc(sizeof(node));
	//分配失败
	if (np == NULL)return NULL;
	//设置键值
	np->name = key;
	np->value = value;
	np->next = NULL;
	return np;
}

int insert(char * key, Variable * value) {
    //这里必须是unsigned int 因为字符串太长的话  int是不够储存的
	unsigned int hashvalue = hash(key);
	//分配堆内存
	node * np = malloc_node(key, value);
	//分配失败就返回0
	if (np == NULL) return 0;
	//设置下一结点为 （每次插入在 链表头上，节约很多时间 ）
	np->next = hashtable[hashvalue];
	hashtable[hashvalue] = np;
	return 1;
}

void clearHashTable() {
	node * np; //马上释放的结点
	node *tmp;//下一个结点
	//遍历表
	for (int i = 0; i < HASHSIZE; i++)
	{
		//获取其中一个元素
		np = hashtable[i];
		if (np != NULL)
		{
			//赋值为空
			hashtable[i] = NULL;
		    //tmp
			tmp = np;
			tmp = tmp->next;
			//释放内存
			free(np);
			// 链表 释放
			while (tmp!=NULL)
			{
				np = tmp;
				free(np);
				tmp = tmp->next;
			}
		}
	}
}

void printHashTable() {
    printf("\n------------print symbol table--------------\n");
	//显示的结点指针
	node *np;
	//哈希值
	int hashvalue;
	//遍历表
	for (int i = 0; i < HASHSIZE; i++) {
		if (hashtable[i] != NULL) {
			np = hashtable[i];
			//链式表 遍历输出
			for (; np != NULL; np=np->next) {
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
				printf("%s,\t%s,\tr%d,\t%s,\t%d", np->value->name, type, np->value->registerNumber, isI, np->value->value);
			}
			printf("\n");
		}
	}

    printf("\n------------print symbol table--------------\n");
}