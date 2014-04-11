all: minipas mini

minipas:minipas.tab.o	lex.yy.o gen.o
	cc -g  $^ -o minipas -ly -lfl

lex.yy.o:lex.yy.c
	gcc -c $<

lex.yy.c:	minipas.l 
	flex minipas.l

minipas.tab.o:minipas.tab.c
	gcc -c $<

minipas.tab.c:	minipas.y
	bison -d minipas.y

gen.o:gen.c
	gcc -c $<

mini: mini.c
	gcc -o $@ $<

test: minipas mini
	-./minipas < cos.pas > cos.asm
	-./mini < cos.asm

clean:
	rm -f minipas *.o *.tab.? lex.yy.c mini cos.asm
