%{
/*
 * grammar.y
 *
 * Pascal grammar in Yacc format, based originally on BNF given
 * in "Standard Pascal -- User Reference Manual", by Doug Cooper.
 * This in turn is the BNF given by the ANSI and ISO Pascal standards,
 * and so, is PUBLIC DOMAIN. The grammar is for ISO Level 0 Pascal.
 * The grammar has been massaged somewhat to make it LALR.
 */

#include "shared.h"
#include "rulefuncs.h"

  int yylex(void);
  void yyerror(const char *error);

  extern char *yytext;          /* yacc text variable */
  extern int line_number;       /* Holds the current line number; specified
				   in the lexer */
  struct program_t *program;    /* points to our program */
%}

%token AND ARRAY ASSIGNMENT CLASS COLON COMMA DIGSEQ
%token DO DOT DOTDOT ELSE END EQUAL EXTENDS FUNCTION
%token GE GT IDENTIFIER IF LBRAC LE LPAREN LT MINUS MOD NEW NOT
%token NOTEQUAL OF OR PBEGIN PLUS PRINT PROGRAM RBRAC
%token RPAREN SEMICOLON SLASH STAR THEN
%token VAR WHILE

%type <tden> type_denoter
%type <id> result_type
%type <id> identifier
%type <idl> identifier_list
%type <fdes> function_designator
%type <apl> actual_parameter_list
%type <apl> params
%type <ap> actual_parameter
%type <vd> variable_declaration
%type <vdl> variable_declaration_list
%type <r> range
%type <un> unsigned_integer
%type <fpsl> formal_parameter_section_list
%type <fps> formal_parameter_section
%type <fps> value_parameter_specification
%type <fps> variable_parameter_specification
%type <va> variable_access
%type <as> assignment_statement
%type <os> object_instantiation
%type <ps> print_statement
%type <e> expression
%type <s> statement
%type <ss> compound_statement
%type <ss> statement_sequence
%type <ss> statement_part
%type <is> if_statement
%type <ws> while_statement
%type <e> boolean_expression
%type <iv> indexed_variable
%type <ad> attribute_designator
%type <md> method_designator
%type <iel> index_expression_list
%type <e> index_expression
%type <se> simple_expression
%type <t> term
%type <f> factor
%type <i> sign
%type <p> primary
%type <un> unsigned_constant
%type <un> unsigned_number
%type <at> array_type
%type <cb> class_block
%type <vdl> variable_declaration_part
%type <fdl> func_declaration_list
%type <funcd> function_declaration
%type <fb> function_block
%type <fh> function_heading
%type <id> function_identification
%type <fpsl> formal_parameter_list
%type <cl> class_list
%type <ci> class_identification
%type <program> program
%type <ph> program_heading
%type <op> relop
%type <op> addop
%type <op> mulop

%union {
  struct type_denoter_t *tden;
  char *id;
  struct identifier_list_t *idl;
  struct function_designator_t *fdes;
  struct actual_parameter_list_t *apl;
  struct actual_parameter_t *ap;
  struct variable_declaration_list_t *vdl;
  struct variable_declaration_t *vd;
  struct range_t *r;
  struct unsigned_number_t *un;
  struct formal_parameter_section_list_t *fpsl;
  struct formal_parameter_section_t *fps;
  struct variable_access_t *va;
  struct assignment_statement_t *as;
  struct object_instantiation_t *os;
  struct print_statement_t *ps;
  struct expression_t *e;
  struct statement_t *s;
  struct statement_sequence_t *ss;
  struct if_statement_t *is;
  struct while_statement_t *ws;
  struct indexed_variable_t *iv;
  struct attribute_designator_t *ad;
  struct method_designator_t *md;
  struct index_expression_list_t *iel;
  struct simple_expression_t *se;
  struct term_t *t;
  struct factor_t *f;
  int *i;
  struct primary_t *p;
  struct array_type_t *at;
  struct class_block_t *cb;
  struct func_declaration_list_t *fdl;
  struct function_declaration_t *funcd;
  struct function_block_t *fb;
  struct function_heading_t *fh;
  struct class_identification_t *ci;
  struct class_list_t *cl;
  struct program_t *program;
  struct program_heading_t *ph;
  int op;
}

%%

program : program_heading semicolon class_list DOT
	{
		struct program_t* ret = malloc( sizeof(struct program_t) );
		ret.ph = $1;
		cl = $3;
		$$ = ret;
	}
 ;

program_heading : PROGRAM identifier
	{
		struct program_heading_t* ret = malloc( sizeof(struct program_heading_t) );
		ret.id = $2;
		ret.il = NULL;
		$$ = ret;
			//build program heading node
			// assign to global prog_heading variable
			// initialize all fields that need to be initialized
	}
 | PROGRAM identifier LPAREN identifier_list RPAREN
	{
		struct program_heading_t* ret = malloc( sizeof(struct program_heading_t) );
		ret.id = $2;
		ret.il = $4;
		$$ = ret;
			//build program heading node
			// assign to global prog_heading variable
			// add identifier ($2) to prog heading node
			// add identifier list ($4) to prog heading node
			// initialize all fields that need to be initialized
	}
 ;

identifier_list : identifier_list comma identifier
					
        {
			struct identifier_list_t* ret = malloc( sizeof(struct identifier_list_t) );
			ret.next = NULL;
			ret.id = $3;
			$1.next = ret;
			$$ = $1;
			// create node for identifier
			// add node to $1
			// assign resulting list to $$
        }
 | identifier
        {
			struct identifier_list_t* ret = malloc( sizeof(struct identifier_list_t) );
			ret.next = NULL;
			ret.id = $1;
			$$ = ret;
			// create node for identifier
			// $$ = created node
        }
 ;

class_list: class_list class_identification PBEGIN class_block END
	{
		struct class_list_t* ret = malloc( sizeof(struct class_list_t) );
		ret.ci = $2;
		ret.cb = $4;
		ret.next = $1;

		$$ = ret;
	}
 | class_identification PBEGIN class_block END
	{
		struct class_list_t* ret = malloc( sizeof(struct class_list_t) );
		ret.ci = $1;
		ret.cb = $3;
		ret.next = NULL;

		$$ = ret;

	}
 ;

class_identification : CLASS identifier
	{
		struct class_identification_t* ret = malloc( sizeof(struct class_identification_t) );
		ret.id = $2;
		ret.extend = NULL;
		ret.line_number = -1; //TODO fix this for error
		//TODO run check and throw error
		//and finish this
		
		$$ = ret;
		// create new class node
		// initialize all fields that need to be initialized
		// check if a class with the same name is not in the class 
		// list already
		// add created node to class list in global pro-heading node
		// set global ìcurrent classî pointer
	}
| CLASS identifier EXTENDS identifier
	{
		struct class_identification_t* ret = malloc( sizeof(struct class_identification_t) );
		ret.id = $2;
		ret.extend = $4;
		ret.line_number = -1; //TODO fix this for error
		//TODO run check and throw error
		//and finish this
		
		$$ = ret;

		// create new class node
		// initialize all fields that need to be initialized
		// check if a class with the same name is not in the class 
		// list already
		// add created node to class list in global pro-heading node
		// set global ìcurrent classî pointer

		// lookup identifier ($4) in class list
		// if found
			//Add pointer to parent class
		// else
			//error

	}
;

class_block:
 variable_declaration_part
 func_declaration_list
	{
		struct class_block_t* ret = malloc( sizeof(struct class_block_t) );
		ret.vdl = $1;
		ret.fdl = $2;

		$$ = ret;
	}
 ;

type_denoter : array_type
	{
		//TODO figure out what to do
	}
 | identifier
	{

	}
 ;

array_type : ARRAY LBRAC range RBRAC OF type_denoter
	{
		struct array_type_t* ret = malloc( sizeof(struct array_type_t) );
		ret.r = $3;
		ret.td = $6;

		$$ = ret;
	}
 ;

range : unsigned_integer DOTDOT unsigned_integer
	{
		struct range_t* ret = malloc( sizeof(struct range_t) );
		ret.min = $1;
		ret.max = $3;

		$$ = ret;
	}
 ;

variable_declaration_part : VAR variable_declaration_list semicolon
	{
		struct variable_declaration_list_t* ret = malloc( sizeof(variable_declaration_list_t) );
		//ret.vd = $2;
		//ret.next = NULL;
		//TODO finish and question missing second part
		$$ = ret;
	}
 |
	{

	}
 ;

variable_declaration_list : variable_declaration_list semicolon variable_declaration
	{
		struct variable_declaration_list_t* ret = malloc( sizeof(variable_declaration_list_t) );
		ret.vd = $3;
		ret.next = $1;
		
		$$ = ret;
	}
 | variable_declaration
	{
		struct variable_declaration_list_t* ret = malloc( sizeof(variable_declaration_list_t) );
		ret.vd = $1;
		ret.next = NULL;
		
		$$ = ret;

	}

 ;

variable_declaration : identifier_list COLON type_denoter
	{
		ret = struct variable_declaration_t = malloc( sizeof(struct variable_declaration_t) );
		ret.il = $1;
		ret.tden = $3;
		// create node for variable declaration
		// add $1 to node created
		// add $3 to created node

		//// Confused what he wants here
		// check identifier in identifier list against
		// variable declaration list of current class

		////
		// lookup type_denoter in class_list (global)
		// add to variable declaration list of current class
		 

	}
 ;

func_declaration_list : func_declaration_list semicolon function_declaration
	{
		struct func_declaration_list_t* ret = malloc( sizeof(func_declaration_list_t) );
		ret.fd = $3;
		ret.next = $1;

		$$ = ret;
	}
 | function_declaration
	{
		struct func_declaration_list_t* ret = malloc( sizeof(func_declaration_list_t) );
		ret.fd = $1;
		ret.next = NULL;

		$$ = ret;
	}
 |
	{
		//TODO ask why empty?
	}
 ;

formal_parameter_list : LPAREN formal_parameter_section_list RPAREN 
	{
		
	}
;
formal_parameter_section_list : formal_parameter_section_list semicolon formal_parameter_section
	{
		struct formal_parameter_section_list_t* ret = malloc( sizeof(formal_parameter_section_list_t) );
		ret.fps = $3;
		ret.next = $1;

		$$ = ret;
	}
 | formal_parameter_section
	{
		struct formal_parameter_section_list_t* ret = malloc( sizeof(formal_parameter_section_list_t) );
		ret.fps = $1;
		ret.next = NULL;

		$$ = ret;
	}
 ;

formal_parameter_section : value_parameter_specification
 | variable_parameter_specification
 ;

value_parameter_specification : identifier_list COLON identifier
	{

	}
 ;

variable_parameter_specification : VAR identifier_list COLON identifier
	{

	}
 ;

function_declaration : function_identification semicolon function_block
	{
		struct function_declaration_t* ret = malloc( sizeof(struct function_declaration_t) );
		//ret.fh = 
		//TODO struct requires function_heading_t not function_identification
		ret.fb = $3;

		$$ = ret;
	}
 | function_heading semicolon function_block
	{
		struct function_declaration_t* ret = malloc( sizeof(struct function_declaration_t) );
		ret.fh = $1;
		ret.fb = $3;

		$$ = ret;
	}
 ;

function_heading : FUNCTION identifier COLON result_type
	{
		struct function_heading_t* ret = malloc( sizeof(struct function_heading_t) );
		ret.id = $2;
		ret.res = $4;
		fpsl = NULL;
		$$ = ret;
		// create node for function
		// add to function list in current class
	}
 | FUNCTION identifier formal_parameter_list COLON result_type
	{
		struct function_heading_t* ret = malloc( sizeof(struct function_heading_t) );
		ret.id = $2;
		ret.res = $5;
		fpsl = $3;
		$$ = ret;
	}
 ;

result_type : identifier ;

function_identification : FUNCTION identifier
	{
		
	}
;

function_block : 
  variable_declaration_part
  statement_part
	{
		struct function_block_t* ret = malloc( sizeof(struct function_block_t) );
		ret.vdl = $1;
		ret.ss = $2;
		$$ = ret;
	}
;

statement_part : compound_statement
 ;

compound_statement : PBEGIN statement_sequence END
	{

	}
 ;

statement_sequence : statement
	{

	}
 | statement_sequence semicolon statement
	{

	}
 ;

statement : assignment_statement
	{

	}
 | compound_statement
	{

	}
 | if_statement
	{

	}
 | while_statement
	{

	}
 | print_statement
        {

        }
 ;

while_statement : WHILE boolean_expression DO statement
	{

	}
 ;

if_statement : IF boolean_expression THEN statement ELSE statement
	{

	}
 ;

assignment_statement : variable_access ASSIGNMENT expression
	{

	}
 | variable_access ASSIGNMENT object_instantiation
	{

	}
 ;

object_instantiation: NEW identifier
	{

	}
 | NEW identifier params
	{

	}
;

print_statement : PRINT variable_access
        {
			struct print_statement_t* ret = malloc( sizeof(struct print_statement_t) );
			ret.va = $2;
			$$ = ret;
        }
;

variable_access : identifier
	{

	}
 | indexed_variable
	{

	}
 | attribute_designator
	{

	}
 | method_designator
	{

	}
 ;

indexed_variable : variable_access LBRAC index_expression_list RBRAC
	{

	}
 ;

index_expression_list : index_expression_list comma index_expression
	{

	}
 | index_expression
	{

	}
 ;

index_expression : expression ;

attribute_designator : variable_access DOT identifier
	{

	}
;

method_designator: variable_access DOT function_designator
	{

	}
 ;


params : LPAREN actual_parameter_list RPAREN 
	{

	}
 ;

actual_parameter_list : actual_parameter_list comma actual_parameter
	{

	}
 | actual_parameter 
	{

	}
 ;

actual_parameter : expression
	{

	}
 | expression COLON expression
	{

	}
 | expression COLON expression COLON expression
	{

	}
 ;

boolean_expression : expression ;

expression : simple_expression
	{

	}
 | simple_expression relop simple_expression
	{

	}
 ;

simple_expression : term
	{

	}
 | simple_expression addop term
	{

	}
 ;

term : factor
	{

	}
 | term mulop factor
	{

	}
 ;

sign : PLUS
	{

	}
 | MINUS
	{

	}
 ;

factor : sign factor
	{

	}
 | primary 
	{

	}
 ;

primary : variable_access
	{

	}
 | unsigned_constant
	{

	}
 | function_designator
	{

	}
 | LPAREN expression RPAREN
	{

	}
 | NOT primary
	{

	}
 ;

unsigned_constant : unsigned_number
 ;

unsigned_number : unsigned_integer ;

unsigned_integer : DIGSEQ
	{

	}
 ;

/* functions with no params will be handled by plain identifier */
function_designator : identifier params
	{

	}
 ;

addop: PLUS
	{

	}
 | MINUS
	{

	}
 | OR
	{

	}
 ;

mulop : STAR
	{

	}
 | SLASH
	{

	}
 | MOD
	{

	}
 | AND
	{

	}
 ;

relop : EQUAL
	{

	}
 | NOTEQUAL
	{

	}
 | LT
	{

	}
 | GT
	{

	}
 | LE
	{

	}
 | GE
	{

	}
 ;

identifier : IDENTIFIER
	{

	}
 ;

semicolon : SEMICOLON
 ;

comma : COMMA
 ;

%%


