%{
#include <stdlib.h> // for atoi call
#include "infix.tab.h"

//#define DEBUG 		// for debugging: print tokens and their line numbers

extern int lineNum; 	// line number from cal.tab.c
void yyerror(char *);	// Defined in infix.y
%}

%%

[a-z] {
	#ifdef DEBUG
	printf("token %s at line %d\n", yytext, lineNum);
	#endif

	yylval = *yytext - 'a';
	return VARIABLE;
	}

[0-9]+ {
	#ifdef DEBUG
	printf("token %s at line %d\n", yytext, lineNum);
	#endif

	yylval = atoi(yytext);
	return INTEGER;
	}

"**" {
	#ifdef DEBUG
	printf("token ** at line %d\n", lineNum);
	#endif

	return POWER;
	}

[-+()=/*!] {
		#ifdef DEBUG
		printf("token %s at line %d\n", yytext, lineNum);
		#endif

		return *yytext;
	}

"\n" {
	#ifdef DEBUG
	printf("token \\n at line %d\n", lineNum);
	#endif

	lineNum++;
	return *yytext;
	}

[ \t]+ {
	#ifdef DEBUG
	printf("token is whitespace(s) at line %d\n", lineNum);
	#endif
	// Ignore whitespaces
	}

.	{ yyerror("invalid character"); }

%%

int yywrap() { /* need this to avoid link problem */
	return 1;
}