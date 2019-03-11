%{
#include <stdio.h>
#include <string.h>
#include <math.h>
#define MAX_NUM_VARS 26		// Max number of variables allowed
#define MAX_VAR_NAME_LEN 25 // How long a variable name can be

void yyerror(char *);	// Defined below in sub-routines
int yylex(void);		// Will be generated in lex.yy.c

/* struct variable {
	char *name[MAX_VAR_NAME_LEN + 1];	// Allocate space for max var name + \0	
	int value;
};
 */
//struct variable vars[MAX_NUM_VARS];

int vars[MAX_NUM_VARS];	
int num_vars = 0;

int lineNum = 1;
%}

%token INTEGER VARIABLE POWER	// bison create #defines in infix.tab.h for use in flex

// Make grammar unambiguous
// Low down to high precedence and left(to right) associativity within a precedent rank
// https://en.cppreference.com/w/c/language/operator_precedence
%left '+' '-'
%left '*' '/'
%right '!'		// Unary bitwise not
%right POWER

// Highest precedence is last line
%start infix

%%

infix :
	infix statement '\n'
	|
	;

statement:
	expr					{ printf("=%d\n", $1); }
	| VARIABLE '=' expr		{ 
							  vars[$1] = $3; 
							  printf("=%d\n", vars[$1]);
							}
	;

expr :
	INTEGER			  { $$ = $1; }	   // Default action; don't really need this
	| VARIABLE        { $$ = vars[$1]; }
	| expr '+' expr   { $$ = $1 + $3; }
	| expr '-' expr   { $$ = $1 - $3; }
	| expr '*' expr   { $$ = $1 * $3; }
	| expr '/' expr   { $$ = $1 / $3; }
	| expr POWER expr { $$ = (int)pow($1, $3); }
	| '!' expr		  { $$ = ~$2; }
	| '(' expr ')'    { $$ = $2; }
	;

%%

void yyerror(char *s)
{
	printf("%s\n", s);
}

/* // If not found, create new variable in array set
// Search array of variables for name; if found, set its value
void assign_var_value(char* var_name, int value)
{
	int i = 0;
	for(i = 0; i < MAX_NUM_VARS; i++)
	{
		if (strcmp(vars[i].name, var_name) == 0)
		{
			vars[i] = value;
			return;
		}
	}
	
	i = create_var(var_name)
	if (i != -1)
	{
		vars[i] = value;
	}
	
	return;
}

// Get the value of the variable
// If variable doesn't exist, create it
int get_var_value(char *var_name)
{
	int i = 0;
	for(i = 0; i < MAX_NUM_VARS; i++)
	{
		if (strcmp(vars[i].name, var_name) == 0)
		{
			return vars[i].value;
		}
	}
	
	i = create_var(var_name)
	if (i != -1)
	{
		vars[i] = value;
	}
	
	return 0; 
}

// Attempt to add a new variable to the var array
// Returns the index of the new variable in the array if successful
// Returns -1 if there was an error
int create_var(char *var_name)
{
	if (num_vars >= MAX_NUM_VARS)
	{
		yyerror("Max number of variables allocated!");
		return -1;
	}
	else
	{
		int len = strln(var_name);
		if(len > MAX_VAR_NAME_LEN) 
		{
			// Include length in error msg?
			yyerror("Variable name exceeds max allowed length.");
			return -1;
		}
			
		strncpy(vars[num_vars].name, var_name, len);
		vars[num_vars].value = 0;
		num_vars++;
		
		return num_vars - 1;
	}
}
 */
 
int main()
{
	memset(vars, 0, sizeof(int) * MAX_NUM_VARS);	// Initialize variables to zero
	yyparse();
	return 0;
}