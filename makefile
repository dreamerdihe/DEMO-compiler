frontend: driver.c parser.tab.c lex.yy.c parser.tab.h ilocEmitter.c symbolTable.c
	gcc -o demo driver.c parser.tab.c lex.yy.c ilocEmitter.c symbolTable.c

parser.tab.c: parser.y
	bison -vd --debug parser.y

parser.tab.h: parser.y
	bison -vd --debug parser.y

lex.yy.c: parser.y parser.tab.h
	flex scanner.l



clean:
	rm -rf a.out.dSYM
	rm *.tab.c *.tab.h demo lex.yy.c *.output *.i
	