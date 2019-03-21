PROGRAM=jornal

build:
	flex $(PROGRAM).l
	gcc lex.yy.c -o $(PROGRAM) `pkg-config --libs glib-2.0` `pkg-config --cflags glib-2.0`

clean:
	rm -f $(PROGRAM) lex.yy.c
