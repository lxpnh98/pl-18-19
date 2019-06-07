all:
	flex sati.l
	yacc -d sati.y
	cc -o sati y.tab.c

flex:
	flex sati.l
	cc -o sati lex.yy.c

clean:
	rm -f lex.yy.c sati y.tab.*
