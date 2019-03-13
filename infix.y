%{
// Benjamin Steenkamer
// CPEG 621 - Lab 1, part 1
#include <stdio.h>
#include <string.h>
#include <math.h>
#define MAX_NUM_VARS 30			// Max number of declared variables allowed
#define MAX_VAR_NAME_LEN 20 	// How long a variable name can be

int yylex(void);						// Will be generated in lex.yy.c by flex

// Following are defined below in sub-routines section
void yyerror(char *);					// Following are defined below in sub-routines section
int var_assignment(char *, int);
int get_var_value(char *);
int create_var(char *);
void print_var_create_error(int);

struct variable {
	char name[MAX_VAR_NAME_LEN + 1];	// Allocate space for max var name + \0
	int value;
};

struct variable vars[MAX_NUM_VARS];		// Holds declared variables
int num_vars = 0;						// Current amount of variables declared
int lineNum = 1;						// Used for debugging
%}

%token INTEGER POWER VARIABLE	// bison adds these #defines in infix.tab.h for use in flex

// Union defines all possible values a token can have associated with it
// Allow yylval to hold either an integer or a string (for variable name)
%union
{
	int val;
	char *str;
}

// When %union is used to specify multiple value types, must declare the 
// value type of each symbol for which values are used 
%type <val> expr INTEGER
%type <str> VARIABLE

// Make grammar unambiguous
// Low to high precedence and associativity within a precedent rank
// https://en.cppreference.com/w/c/language/operator_precedence
%left '+' '-'
%left '*' '/'
%precedence  '!'		// Unary bitwise not; No associativity b/c it is unary
%right POWER			// ** exponent operator

%start infix

%%

infix :
	infix statement '\n'
	|
	;

statement:
	expr					{ printf("=%d\n", $1); }
	| VARIABLE '=' expr		{
							  printf("=%d\n", var_assignment($1, $3));
							  free($1); // Must free the strdup string
							}
	;

expr :
	INTEGER			  { $$ = $1; }	   // Default action; don't really need this
	| VARIABLE        { $$ = get_var_value($1); free($1); }
	| expr '+' expr   { $$ = $1 + $3; }
	| expr '-' expr   { $$ = $1 - $3; }
	| expr '*' expr   { $$ = $1 * $3; }
	| expr '/' expr   { $$ = $1 / $3; }
	| '!' expr		  { $$ = ~$2; }
	| expr POWER expr { $$ = (int)pow($1, $3); }
	| '(' expr ')'    { $$ = $2; }		// Will give syntax error for unmatched parens
	;

%%

// Called for var_name = value operations
// Searches the array of vars for var_name; if found, assigns value to it and returns assigned value
// If var_name doesn't exist, create var_name in array, assign new value, return assigned value
int var_assignment(char* var_name, int value)
{
	// Search vars to see if var_name was already created
	int i = 0;
	for(i = 0; i < num_vars; i++)
	{
		if (strcmp(vars[i].name, var_name) == 0)
		{
			vars[i].value = value;
			return vars[i].value;	// Return newly assigned value
		}
	}

	// Try to add new var_name to the array
	i = create_var(var_name);
	if (i >= 0)
	{
		vars[i].value = value;
		return vars[i].value;
	}

	print_var_create_error(i);
	return 0;
}

// Returns the value of the variable
// If variable wasn't declared previously, create it with a value of zero
int get_var_value(char *var_name)
{
	int i = 0;
	for(i = 0; i < num_vars; i++)
	{
		if (strcmp(vars[i].name, var_name) == 0)
		{
			return vars[i].value;
		}
	}

	i = create_var(var_name);
	if (i >= 0)
	{
		return vars[i].value;	// This should always be zero
	}

	print_var_create_error(i);
	return 0;	// Return 0 even if a new var couldn't be made
}

// Attempts to add a new variable to the vars array
// Returns index of new variable in array if successful
// Returns negative number if there was an error
int create_var(char *var_name)
{
	if (num_vars >= MAX_NUM_VARS)
	{
		return -1;
	}

	int len = strlen(var_name);

	if(len > MAX_VAR_NAME_LEN)
	{
		return -2;
	}

	strncpy(vars[num_vars].name, var_name, len);
	vars[num_vars].value = 0;	// Initialize variable with a value of zero
	num_vars++;

	return num_vars - 1;
}

// Handle to decode errors and print error message
void print_var_create_error(int error)
{
	switch(error)
	{
		case -1:
			yyerror("Max number of variables already declared");
			break;
		case -2:
			yyerror("Variable name exceeds max length");
			break;
		default:
			yyerror("Unknown error code");
	}
}

void yyerror(char *s)
{
	printf("%s\n", s);
}

int main()
{
	memset(vars, 0, sizeof(int) * MAX_NUM_VARS);	// Initialize variables to zero
	yyparse();
	return 0;
}