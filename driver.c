#include "stdio.h"
#include "string.h"
#include <stdlib.h>
#include <dirent.h>
#include <sys/stat.h>
#include <libgen.h> 
#include <unistd.h>
#include "symbolTable.h"

int yyparse( );
int syntax_error;
extern FILE *yyin;
FILE *oput;
int globalRg = -1;
int globalLabel = -1;
int globalBase = 0;

char* getName(char *name) {
  char* filename = basename(name);
  int i = strlen(filename);
  char* c = filename + i;

  while(c > filename){
    if(*c == '.') {
      *c = 0;
      break;
    }
      c--;
  }
  strcat(filename, ".i");
  return filename;
}


int main( int argc, char *argv[] ) {
  
  if(argc == 3) {
      if(strcmp(argv[1], "-h") == 0) {
          yyin = fopen(argv[2], "r");
          oput = fopen("result.i", "w");
          printf("read from file\n");
          yyparse();
          fclose(oput);
      } else if(strcmp(argv[1], "-s") == 0) {
          yyin = fopen(argv[2], "r");
          char *name = argv[2];
          char *filename = getName(name);
          oput = fopen(filename , "w");
          printf("read from file\n");
          yyparse();
          printHashTable();
          fclose(oput);
      }
      else {
          printf("now the programme only support -h option.\n");
          return 0;
      }
  } else {
      yyin = stdin;
      yyparse();      
  }

  if (syntax_error == 0) {
    fprintf(stderr,"Parser succeeds.\n");
  }
  else { /* first, complain */
    fprintf(stderr,"\nParser fails with %d error messages.\nExecution halts.\n",
	    syntax_error);
  }
}

