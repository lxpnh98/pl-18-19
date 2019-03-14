PROGRAM=jornal

build:
	flex $(PROGRAM).l
	gcc lex.yy.c -o $(PROGRAM)

clean:
	rm -f $(PROGRAM) lex.yy.c
