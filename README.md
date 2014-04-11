This is the minipas compiler for the book:
Compiler design: theory, tools and examples.

It is an quite old book. The author Bergmann has kindly published another two compiler
books with the same title but for C and Java.

I got the original paper books from an charity of book selling. It's is a complete compiler
book, from theory to practical, from lexer to code generation and simulation.

The original source code is not working very well under modern linux distribution. That's
what I am doing here. I re-engineering the code in a more modern way and compile the codes
under modern tools: gcc, bison, flex. All passed well. For those using other than linux
system, I think it's not hard to modify and pass the compiler stage and run the simulator.

Just go to the directory minipas and run make to get the minipas compiler and mini simualtor.
make test to run the sample cos.pas.

Detail steps can be seen in the makefile.

Changes:
I added some tokens to avoid using the string as tokens in minipas.l and minipas.y.

The shift/reduce conflicts haven't settle yet. Any suggestions are welcome.


Enjoy the compiling road!
