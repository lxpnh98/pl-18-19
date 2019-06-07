CFLAGS=-g `pkg-config --libs glib-2.0` `pkg-config --cflags glib-2.0`

all:
	flex sati.l
	yacc -d sati.y
	cc -o sati y.tab.c $(CFLAGS)

flex:
	flex sati.l
	cc -o sati lex.yy.c -DFLEX $(CFLAGS)

clean:
	rm -f lex.yy.c sati y.tab.*
