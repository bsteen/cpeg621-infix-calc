%{
// Benjamin Steenkamer
// CPEG 621 - Lab 1, part 2
#include <stdio.h>
#include <string.h>
#include <math.h>

#define MAX_NUM_VARS 30			// Max number of declared variables allowed in calculator
#define MAX_VAR_NAME_LEN 20 	// How long a variable name can be; must be at least 10
#define MAX_FIX_SIZE 200		// Max size of postfix buf and prefix stack; must be >> MAX_VAR_NAME_LEN

// Identifiers
#define POSTFIX 1
#define PREFIX 0
#define UNARY 2
#define EQUALS 3
#define OPERAND 1
#define OPERATOR 0

int yylex(void);				// Will be generated in lex.yy.c by flex

// Following are defined below in sub-routines section
void yyerror(char *);
//Used for infix calculator
int var_assignment(char *, int);
int get_var_value(char *);
int create_var(char *);
void print_var_create_error(int);

// Push and pop values to postfix and prefix stacks
void push_int(int, int);
void push_str(int, char *);
int pop(char*);
// For creating prefix output
int idenify_type(char *);
void strncat_check(char *, char*);
void print_prefix();

struct variable {						// Structure to hold a declared variable's data
	char name[MAX_VAR_NAME_LEN + 1];	// Allocate space for max var name + \0
	int value;
};

struct variable vars[MAX_NUM_VARS];		// Holds declared variables
int num_vars = 0;						// Current amount of variables declared
int lineNum = 1;						// Used for debugging

char postfix_buf[MAX_FIX_SIZE][MAX_VAR_NAME_LEN + 1]; 	// Element must hold symbol, integer, or var name
int postfix_size = 0;						// Number of elements in postfix buffer
char prefix_stack[MAX_FIX_SIZE][MAX_FIX_SIZE];
int prefix_sp = 0;							// Points to the top the stack (one index above top element)

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

%start prefix

%%

prefix :
	prefix statement '\n'
	|
	;

statement:
	expr					{ print_prefix(); printf("=%d\n", $1); }
	| VARIABLE '=' expr		{
							  push_str(POSTFIX, $1);
							  push_str(POSTFIX, "=");
							  print_prefix();
							  printf("=%d\n", var_assignment($1, $3));
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
	| '!' expr		  { $$ = ~$2; push_str(POSTFIX, "!"); }
	| expr POWER expr { $$ = (int)pow($1, $3); push_str(POSTFIX, "**"); }
	| '(' expr ')'    { $$ = $2; }	// Will give syntax error for unmatched parens
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

// Helper function to decode errors and print error message
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
	return;
}


// Push integer (converted to string) to the selected buffer
void push_int(int buf_id, int i)
{
	if (buf_id == POSTFIX)
	{
		if(postfix_size >= MAX_FIX_SIZE)
		{
			yyerror("push_int: postfix_buf is full (MAX_FIX_SIZE elements)");
			return;
		}

		sprintf(postfix_buf[postfix_size], "%d", i);	// signed 32-bit int is max 10 characters
		postfix_size++;
		return;
	}
	else	// Push to prefix stack
	{
		if(prefix_sp >= MAX_FIX_SIZE)
		{
			yyerror("push_int: prefix_stack is full (MAX_FIX_SIZE elements)");
			return;
		}

		sprintf(prefix_stack[prefix_sp], "%d", i); // signed 32-bit int is max 10 characters
		prefix_sp++;
		return;
	}
}

// Add string to top of selected buffer
void push_str(int buf_id, char *str)
{
	if (buf_id == POSTFIX){
		if(postfix_size >= MAX_FIX_SIZE)
		{
			yyerror("push_str: postfix_buf is full (MAX_FIX_SIZE elements)");
			return;
		}

		strncpy(postfix_buf[postfix_size], str, MAX_VAR_NAME_LEN + 1);
		postfix_size++;
		return;
	}
	else
	{
		if(prefix_sp >= MAX_FIX_SIZE)
		{
			yyerror("push_str: prefix_stack is full (MAX_FIX_SIZE elements)");
			return;
		}


		strncpy(prefix_stack[prefix_sp], str, MAX_FIX_SIZE);
		prefix_sp++;
		return;
	}
}

// Stores top value popped off prefix stack to top_value
// Only works on prefix stack; postfix won't need this function
// Returns 1 if success, 0 if there is no more data to pop.
int pop(char *top_value){
	if(prefix_sp <= 0)
	{
		return 0;
	}

	strncpy(top_value, prefix_stack[prefix_sp - 1], MAX_FIX_SIZE);
	prefix_sp--;
	return 1;
}

// Identify whether string is an operator, unary operator, or operand
int idenify_type(char *c)
{
	if(strcmp(c, "+") == 0
		|| strcmp(c, "-") == 0
		|| strcmp(c, "*") == 0
		|| strcmp(c, "/") == 0
		|| strcmp(c, "**") == 0)
	{
		return OPERATOR;
	}
	else if(strcmp(c, "!") == 0)
	{
		return UNARY;
	}
	else if(strcmp(c, "=") == 0)
		return EQUALS;
	else
	{
		return OPERAND;	// an integer or variable
	}
}


// Concatenates two strings, but gives warning if the new string is too long
void strncat_check(char *dest, char *src)
{
	int len_dest = strlen(dest);
	int len_src = strlen(src);
	int space_left = MAX_FIX_SIZE - len_dest - 1; // account for null term that will be added last
	int chars_to_copy = space_left; // Amount of space left to copy src into

	if (len_src > space_left)
	{
		yyerror("strncat_check: new stack element too large for buffer, symbols will be lost");
		// During the conversion between postfix to prefix, elements on the
		// stack are popped, concatenated, and then push back onto the stack. If this
		// newly created element is larger than the fixed stack element size,
		// strncat will cut off data to prevent buffer overflow.
	}

	strncat(dest, src, chars_to_copy);
	return;
}
// Takes the postfix_buf and prints out converted prefix notation
// Uses a stack and concatenation method for the conversion
void print_prefix()
{
	int i;

	// Print of Postfix buffer; useful for debugging
	// printf("POSTFIX: ");
	// for(i = 0; i < postfix_size; i++)
	// {
		// printf("%s ", postfix_buf[i]);
	// }
	// printf("\n");

 	char prf_temp1[MAX_FIX_SIZE];
	char prf_temp2[MAX_FIX_SIZE];
	char prf_temp3[MAX_FIX_SIZE];
	int type;

	// Loop through postfix data, left to right
	for(i = 0; i < postfix_size; i++)
	{
		// Determine the type of value from postfix
		type = idenify_type(postfix_buf[i]);

		if(type == OPERATOR)
		{
			// Pop top 2 values from prefix stack
			pop(prf_temp1);
			pop(prf_temp2);

			// Concatenate operator + 2nd value + first value
			sprintf(prf_temp3, "%s ", postfix_buf[i]);	// Don't need to bounds check on these
			strncat_check(prf_temp3, prf_temp2);		// sprintfs b/c postfix_buf[] have smaller size
			strncat_check(prf_temp3, prf_temp1);

			// Push new string to stack
			push_str(PREFIX, prf_temp3);
		}
		else if (type == UNARY)		// Determine if space or no space between ! and next value
		{
			pop(prf_temp1);									// Get prefix stack element
			sprintf(prf_temp2, "%c", prf_temp1[0]); 		// Get the first value from stack element

			if (idenify_type(prf_temp2) == OPERAND)			// Determine first value's type
			{
				sprintf(prf_temp3, "%s", postfix_buf[i]);	// Makes unary appear as: !x
			}
			else
			{
				sprintf(prf_temp3, "%s ", postfix_buf[i]); // Makes unary appear as: ! +
			}

			strncat_check(prf_temp3, prf_temp1);
			push_str(PREFIX, prf_temp3);
		}
		else if(type == EQUALS)
		{
			// Pop top 2 values from prefix stack
			pop(prf_temp1);
			pop(prf_temp2);

			// Concatenate operator + first value + second value
			sprintf(prf_temp3, "%s ", postfix_buf[i]);
			strncat_check(prf_temp3, prf_temp1);
			strncat_check(prf_temp3, prf_temp2);

			// Push new string back to stack
			push_str(PREFIX, prf_temp3);

		}
		else	// type == OPERAND, push value to prefix stack
		{
			sprintf(prf_temp1, "%s ", postfix_buf[i]);
			push_str(PREFIX, prf_temp1);
		}
	}

	// printf("PREFIX : ");
	pop(prf_temp1); 		// Pop last element, should be entire prefix notation
	printf("%s\n", prf_temp1);

	// Reset buffers for next operation
	postfix_size = 0;
	prefix_sp = 0;

	return;
}

void yyerror(char *s)
{
	printf("%s\n", s);
}

int main()
{
	memset(vars, 0, sizeof(int) * MAX_NUM_VARS);	// Initialize variables to zero

	if(MAX_FIX_SIZE <= MAX_VAR_NAME_LEN)
	{
		yyerror("Error: To prevent buffer copy overflow, MAX_FIX_SIZE must be > MAX_VAR_NAME_LEN");
		// If not caught, this overflow would happen when variable names are pushed to prefix stack,
		// and when long prefix stack elements are created via concatenation
		return 0;
	}

	if (MAX_VAR_NAME_LEN < 10)
	{
		yyerror("Error: Variables should be allowed to be AT LEAST 10 characters long (MAX_VAR_NAME_LEN)");
		return 0;
		// The postfix buffer stores symbols, var names, and ints in a buffer.
		// The buffer needs to be at least 10 + null characters long to store 32-bit signed ints as strings.
		// To simplify the logic, the buffer indexes therefore need to be at least 10,
		// so var names might as well be be a minimum of 10 + null characters long.
		// The extra space for '\0' is accounted for in the allocation.
	}

	yyparse();
	return 0;
}
