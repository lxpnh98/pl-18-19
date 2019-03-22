CC=gcc
CFLAGS=-g -Wall -pedantic -Wno-unused-function
PROGRAM=jornal

build:
	flex $(PROGRAM).l
	$(CC) $(CFLAGS) lex.yy.c -o $(PROGRAM) `pkg-config --libs glib-2.0` `pkg-config --cflags glib-2.0`

clean:
	rm -f $(PROGRAM) lex.yy.c
