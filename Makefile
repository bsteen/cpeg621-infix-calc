# Benjamin Steenkamer
# CPEG 621, Lab 1

default: prefix

# For making part 1, infix calculator
infix: infix.l infix.y
	bison -d infix.y
	flex infix.l
	gcc lex.yy.c infix.tab.c -o infix -lm
	
# For making part 2, prefix generator
prefix: prefix.l prefix.y
	bison -d prefix.y
	flex prefix.l
	gcc lex.yy.c prefix.tab.c -o prefix -lm
	
# Make provided, basic calculator
cal: lex.yy.o cal.tab.o
	gcc -o cal lex.yy.o cal.tab.o

lex.yy.o: cal.l
	flex cal.l; gcc -c lex.yy.c

cal.tab.o: cal.y
	bison -d cal.y; gcc -c cal.tab.c

clean:
	rm -f *.o *.c *.h cal infix prefix
