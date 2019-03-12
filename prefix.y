%{
// Benjamin Steenkamer
// CPEG 621 - Lab 1, part 2
#include <stdio.h>
#include <string.h>
#include <math.h>
#define MAX_NUM_VARS 30			// Max number of declared variables allowed
#define MAX_VAR_NAME_LEN 20 	// How long a variable name can be
#define MAX_FIX_SIZE 1000	// Max size of postfix and prefix buffer
#define POSTFIX 1
#define PREFIX 0
#define UNARY 2
#define OPERAND 1
#define OPERATOR 0


int yylex(void);				// Will be generated in lex.yy.c by flex

// Following are defined below in sub-routines section
void yyerror(char *);
//Used for infix calculator
int var_assignemnt(char *, int);
int get_var_value(char *);
int create_var(char *);
void print_var_create_error(int);


// Push and pop values to postfix and prefix stacks
void push_int(int, int);
void push_str(int, char *);
void pop(char*);
int idenify_type(char *c);
void print_prefix();

struct variable {						// Structure to hold a declared variable's data
	char name[MAX_VAR_NAME_LEN + 1];	// Allocate space for max var name + \0
	int value;
};

struct variable vars[MAX_NUM_VARS];		// Holds declared variables
int num_vars = 0;						// Current amount of variables declared
int lineNum = 1;						// Used for debugging

char postfix_buf[MAX_FIX_SIZE][MAX_VAR_NAME_LEN + 1];
int postfix_size = 0;
char prefix_buf[MAX_FIX_SIZE][MAX_VAR_NAME_LEN + 2]; // Can have unary ! + var name
int prefix_size = 0;

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
	expr					{ print_prefix(); printf("=%d\n", $1); }
	| VARIABLE '=' expr		{
							  push_str(POSTFIX, "=");
							  printf("=%d\n", var_assignemnt($1, $3));
							  free($1); // Must free the strdup string
							}
	;

expr :
	INTEGER			  { $$ = $1; push_int(POSTFIX, $1); }
	| VARIABLE        { $$ = get_var_value($1); push_str(POSTFIX, $1); free($1); }
	| expr '+' expr   { $$ = $1 + $3; push_str(POSTFIX, "+"); }
	| expr '-' expr   { $$ = $1 - $3; push_str(POSTFIX, "-"); }
	| expr '*' expr   { $$ = $1 * $3; push_str(POSTFIX, "*"); }
	| expr '/' expr   { $$ = $1 / $3; push_str(POSTFIX, "/"); }
	| expr POWER expr { $$ = (int)pow($1, $3); push_str(POSTFIX, "**"); }
	| '!' expr		  { $$ = ~$2; push_str(POSTFIX, "!"); }
	| '(' expr ')'    { $$ = $2; }	// Will give syntax error for unmatched parens
	;

%%

// Called for var_name = value operations
// Searches the array of vars for var_name; if found, assigns value to it and returns assigned value
// If var_name doesn't exist, create var_name in array, assign new value, return assigned value
int var_assignemnt(char* var_name, int value)
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


// Push integer (converted to string) to the selected buffer
// DO RANGE CHECK
void push_int(int buf_id, int i)
{
	if (buf_id == POSTFIX){
		sprintf(postfix_buf[postfix_size], "%d", i);
		postfix_size++;
	}
	else
	{
		sprintf(prefix_buf[prefix_size], "%d", i);
		prefix_size++;
	}

}

// Add string to selected buffer
// DO RANGE CHECK
void push_str(int buf_id, char *c)
{
	if (buf_id == POSTFIX){
		strncpy(postfix_buf[postfix_size], c, MAX_VAR_NAME_LEN + 1);
		postfix_size++;
	}
	else
	{
		strncpy(prefix_buf[prefix_size], c, MAX_VAR_NAME_LEN + 2);
		prefix_size++;
	}
}

// Saves top value and type popped off prefix stack
// Only works on prefix buffer; postfix won't need this function
// DO RANGE CHECK
void pop(char *top_value){
	strncpy(top_value, prefix_buf[prefix_size], MAX_VAR_NAME_LEN + 2);
	prefix_size--;
}

// Identify whether string is an operator, unary operator, operand
int idenify_type(char *c)
{	
	if(strcmp(top_value, "+") == 0
		|| strcmp(top_value, "-") == 0
		|| strcmp(top_value, "*") == 0
		|| strcmp(top_value, "/") == 0
		|| strcmp(top_value, "**") == 0)
	{
		return OPERATOR;
	}
	else if(strcmp(top_value, "!") == 0)
	{
		return UNARY;
	}
	else
	{
		return OPERAND;	// an integer or variable
	}
}

// Takes the postfix_buf and converts it to prefix notation
void print_prefix()
{
	int i;
	printf("POSTFIX: ");
	for(i = 0; i < postfix_size; i++)
	{
		printf("%s ", postfix_buf[i]);
	}
	printf("\n");

	char pof_temp[MAX_VAR_NAME_LEN + 1];
	char prf_temp1[MAX_VAR_NAME_LEN + 2];
	char prf_temp2[MAX_VAR_NAME_LEN + 2];
	int type;
	
	for(i = 0; i < postfix_size; i++)
	{
		pof_temp = postfix_buf[i];
		type = idenify_type(pof_temp);
		printf("%d %s\n", type, pof_temp);
		
		if(type == OPERATOR)
		{
			pop(prf_temp1);			// Will be operand
			pop(prf_temp2);			// Will be also operand			
			push_str(PREFIX, pof_temp);		// Push operator
			push_str(PREFIX, prf_temp2);	// Push back 2 operands in reverse order
			push_str(PREFIX, prf_temp1);
		}
		else if (type == UNARY)
		{
			pop(prf_temp1);
			push_str(PREFIX, '!' + prf_temp1); // MAX_VAR_NAME_LEN + 2 is needed here
		}
		else	// type == OPERAND
		{
			push_str(PREFIX, prf_temp1);
		}
	}

	printf("PREFIX: ");
	for(i = 0; i < prefix_size; i++)
	{
		printf("%s ", prefix_buf[i]);
	}
	printf("\n");

	// Reset buffers for next operation
	postfix_size = 0;
	prefix_size = 0;

	return;
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