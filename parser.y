%{

#include <strings.h>
#define INTEGER 0
#define BOOLEAN 1
#define REAL    2
#define INV     3
#define MAXDIM 10
#define MAXRECFIELDS 15
#define MAXIDLENGTH 20
#define NSYMS 1000
#define MAXNESTING 20
#define LOCAL 3
#define TRUE 1
#define FALSE 0 
#define VAR_PARAM 0
#define VAL_PARAM 1

extern line_no;
extern yytext;

struct rangeType {
	int hi;
	int lo;
};

struct rangeListType {
	struct rangeType range;
	int dim;
	int no_entries;
	struct rangeListType *next;
};

struct arrayType {
  struct rangeListType *rangeList;
  struct typeDenoter *elementType;
  int size;
};

struct recElementType {
  struct idListType * fields;
  int	fieldCount;
  struct typeDenoter *fieldType; 
  struct recElementType *next;
  int tag;
  int size;
};


struct funcType {
	char *identifier;
	struct typeDenoter    * returnType;
	struct recElementType * params;
	struct typeListType   * typeList;
	struct recElementType * localVariables;
	struct funcType       * parent;
        struct funcType       * siblings; /* all functions at the same
					     level are connected in
				 	     a unidirectional list */
	struct funcType       * children; /* one child is linked to the
					     others through siblings */
	struct idListType     * idList;  /* hack only for program */
};

struct typeDenoter {
   int typeClass;
   struct arrayType * array;
   struct recElementType *record;
   int size;
};  


struct typeListType {
  char *name;
  int typeId;
  struct typeDenoter *type; 
  struct typeListType * next;
  int line_no;
};

struct idListType {
	char * identifier;
	int elementCount; /* count of elements from this node to end */
	struct idListType *next;
	int line_no; /* line in which the identifier appears */
	int size;
	int offset;
};

struct funcType *symbolTree;

struct arrayType tarr;
struct rangeType tempRange;

int typeCounter;
int i;
int offset;
struct typeDenoter integerType = {INTEGER,NULL,NULL,2};
struct typeDenoter booleanType = {BOOLEAN,NULL,NULL,1};
struct typeDenoter realType = {REAL,NULL,NULL,4};
struct typeDenoter INVALID = {INV,NULL,NULL,0};

struct funcType * currentScope;
struct funcType * scope;
struct typeListType * foundType;
struct idListType *field;
struct idListType *idList;
%}


%union{
   char *identifier;
   int  tok;
   int ival;
   float fval;
   struct rangeType *range;
   struct rangeListType *range_list;
   struct typeDenoter *type_denoter;
   struct recElementType *record_section;
   struct recElementType *record_section_list;
   struct recElementType *variable_declaration;
   struct recElementType *variable_declaration_list;
   struct recElementType *variable_declaration_part;
   struct typeListType *type_definition;
   struct typeListType *type_definition_list;
   struct typeListType *type_definition_part;
   struct recElementType *variable_parameter_specification;
   struct recElementType *value_parameter_specification;
   struct recElementType *formal_parameter_section;
   struct recElementType *formal_parameter_section_list;
   struct recElementType *formal_parameter_list;
   struct funcType  *function_heading;
   char * result_type;
   struct idListType *identifier_list;
   struct un {
	int ival;
	float fval;
   } unsigned_number;
} 

%token <tok> AND ARRAY ASSIGNMENT CASE CHARACTER_STRING COLON 
%token <tok> COMMA CONST DIGSEQ
%token <tok> DIV DO DOT DOTDOT DOWNTO ELSE END EQUAL EXTERNAL 
%token <tok> FOR FORWARD FUNCTION
%token <tok> GE GOTO GT IDENTIFIER IF IN LABEL LBRAC LE LPAREN LT 
%token <tok> MINUS MOD NIL NOT
%token <tok> NOTEQUAL OF OR OTHERWISE PACKED PBEGIN PFILE PLUS 
%token <tok> PROCEDURE PROGRAM RBRAC
%token <tok> REALNUMBER RECORD REPEAT RPAREN SEMICOLON SET SLASH 
%token <tok> STAR STARSTAR THEN
%token <tok> TO TYPE UNTIL UPARROW VAR WHILE WITH

%type <ival> unsigned_integer
%type <fval> unsigned_real
%type <unsigned_number> unsigned_number
%type <range> range
%type <range_list> range_list
%type <type_denoter> type_denoter
%type <type_denoter> array_type
%type <type_denoter> record_type
%type <identifier> identifier
%type <identifier_list> identifier_list
%type <record_section> record_section
%type <record_section_list> record_section_list
%type <type_definition> type_definition
%type <type_definition_list> type_definition_list
%type <type_definition_part> type_definition_part
%type <variable_declaration> variable_declaration
%type <variable_declaration_list> variable_declaration_list
%type <value_parameter_specification> value_parameter_specification
%type <variable_parameter_specification> variable_parameter_specification
%type <formal_parameter_list> formal_parameter_list
%type <formal_parameter_section_list> formal_parameter_section_list
%type <formal_parameter_section> formal_parameter_section
%type <function_heading> function_heading
%type <result_type> result_type

%%

program : program_heading semicolon block DOT 
 ;

program_heading : PROGRAM identifier
	{
		currentScope->identifier = $2;
	}
 | PROGRAM identifier LPAREN identifier_list RPAREN
	{
		currentScope->identifier = $2;
		currentScope->idList = $4;
	}
 ;

identifier_list : identifier_list comma identifier
	{
	   $$ = (struct idListType *) malloc(sizeof(struct idListType));
	   $$->identifier = $3;
	   $$->line_no = line_no;
	   $$->next = $1;       /* this creates a backward list */
	   $$->elementCount = $1->elementCount+1;
	   if (InList($3,$1))
		printf("multiple occurence of %s in line %d\n",
			$3, line_no);
	}
 | identifier 
	{
	  $$ = (struct idListType *) malloc(sizeof(struct idListType));
	  $$->identifier = $1;
	  $$->next = NULL;
	  $$->line_no = line_no;
	  $$->elementCount = 1;
	}
 ;

block : 
 type_definition_part
 variable_declaration_part
 func_declaration_list
 statement_part
 ;

type_definition_part : TYPE type_definition_list
	{
	  currentScope->typeList = $2;
	}
 |
	{
	  currentScope->typeList = NULL;
	}
 ;

type_definition_list : type_definition_list type_definition
	{
          $$ = $2;       /* list is assembled in reverse order */
          $$->next = $1;

	  findIdInRecord($2->name,currentScope->params,line_no,
			"type","parameter list");
	  if (strcasecmp($2->name,currentScope->identifier)==0)
		printf("%s in line % d is same as scope name\n", $1, line_no);  		/* note that this line number is not always accurate */
          CheckDuplicateType($2,$1); /* checks duplicates in
					local scope */
	  currentScope->typeList = $$;
        }
 | type_definition
	{
	  $$ = $1;
        }
 ;

type_definition : identifier EQUAL type_denoter semicolon
	{ 
	  $$ = (struct typeListType *) malloc(sizeof(struct typeListType)); 
	  typeCounter++;
	  $$->name = $1;
	  $$->typeId = typeCounter;
	  $$->type = $3;
	  $$->next = NULL;
	  $$ ->line_no = line_no;
	  printf("size of %s is %d\n", $1, $3->size);
	}
 ;

type_denoter : array_type
	{ 
	  $$ = $1;
	  $$->size = $1->size;
	} 
 | record_type
	{
	  $$ = $1;
	  $$->size = $1->size;
	}
 | identifier 
	{  
	  $$ = checkIdentifierType($1,currentScope); 
          /* here we do not need to check against other declarations.
	  We only need to make sure it is a valid type */
	  printf("Type denoter id %s size %d\n",$1, $$->size);
	}
 ;

array_type : ARRAY LBRAC range_list RBRAC OF type_denoter
	{
	  $$ = (struct typeDenoter *) malloc(sizeof(struct typeDenoter));
	  $$->typeClass = ARRAY;
	  $$->array = (struct arrayType *) malloc(sizeof(struct arrayType));
	  $$->array->elementType = $6; 
	  $$->array->rangeList = $3;

	  printf("%d entries in array line %d\n", $3->no_entries,line_no);
	  $$->size = $3->no_entries*$6->size;
	  printf("SIZE %d NOENTRIES %d TYPEDENOTER %d\n", $$->size,
			$3->no_entries, $6->size);
	}
 ;

range_list : range_list comma range
	{
	  $$ = (struct rangeListType *) malloc(sizeof(struct rangeListType));
	  $$->range.hi = $3->hi;
	  $$->range.lo = $3->lo;
	  $$->dim = $1->dim+1;
	  $$->next = $1;
	  $$->no_entries = $1->no_entries*($3->hi - $3->lo+1);
	}
 | range 
	{ 
	  $$ = (struct rangeListType *) malloc(sizeof(struct rangeListType));
	  $$->next = NULL;
	  $$->dim = 1;
	  $$->range.lo = $1->lo;	
	  $$->range.hi = $1->hi;	
	  if ($1->hi < $1->lo)
		printf("range error in line %d\n", line_no);
	  $$->no_entries = $1->hi - $1->lo + 1;
	}
 ;

range : unsigned_integer DOTDOT unsigned_integer 
	{ 
	  $$ = &tempRange;
	  $$->hi = $3; $$->lo = $1; 
	}
 ;

record_type : RECORD record_section_list END
	{
	  $$ = (struct typeDenoter *) malloc(sizeof(struct typeDenoter));
	  $$->record = $2;
	  $$->typeClass = RECORD;
	  $$->size = $2->size;
	}
 ;

record_section_list : record_section_list semicolon record_section
   {
	  $$ = $3;       /* list is assembled in reverse order */
	  $$->next = $1; 
	  $$->fieldCount = $1->fieldCount+1;
          CheckCommonRS($3->fields,$1,"field", "record");
	  $$->size = $1->size+$3->size;
   }
 | record_section
	{
	  $$ = $1;
	}
 ;

record_section : identifier_list COLON type_denoter
	{
	  $$ = (struct recElementType *) malloc(sizeof(struct recElementType));
	  $$->fields = $1;
	  $$->fieldType = $3;			
	  $$->next = NULL;
	  $$->fieldCount = 1;
	  $$->size = $1->elementCount*$3->size;
	}
 ;

variable_declaration_part : VAR variable_declaration_list semicolon
 |
 ;

variable_declaration_list :
   variable_declaration_list semicolon variable_declaration
   {
	$$ = $3;
	$3->next = $1;

	CheckCommonRS($3->fields,currentScope->params, "variable",
		  "Already appears as a parameter");
	CheckCommonRS($3->fields,$1,"variable",
		  "Already Declared Locally");

	 /* Need to check against local types and against function name
	    CheckIfDeclaredAsType($1);
	    CheckIfDeclaredAsFunction($1); */

   }
 | variable_declaration
   {
	$$ = $1;
   }
 ;

variable_declaration : identifier_list COLON type_denoter
   {
	  $$ = (struct recElementType *) malloc(sizeof(struct recElementType));
	  $$->fields = $1;
	  $$->fieldType = $3;			
   }
 ;

func_declaration_list :
   func_declaration_list semicolon function_declaration
 | function_declaration
 |
 ;

directive : FORWARD
 ;

formal_parameter_list : LPAREN formal_parameter_section_list RPAREN 
	{ $$ = $2; }

formal_parameter_section_list : 
   formal_parameter_section_list semicolon formal_parameter_section
	{ 
	     $3->next = $1;
	     $$ = $3;
	     idList = $3->fields;
	     CheckCommonRS(idList,$$, "parameter", "function");
	}
 | formal_parameter_section
	{ $$ = $1; }
 ;

formal_parameter_section : value_parameter_specification
	{ $$ = $1; }
 | variable_parameter_specification
	{ $$ = $1; }
 ;

value_parameter_specification : identifier_list COLON identifier
	{
	  $$ = (struct recElementType *) malloc(sizeof(struct recElementType));
	  $$->fields = $1;
	  $$->fieldType = checkIdentifierType($3,currentScope);			
	  $$->next = NULL;
	}
 ;

variable_parameter_specification : VAR identifier_list COLON identifier
	{
	  $$ = (struct recElementType *) malloc(sizeof(struct recElementType));
	  $$->fields = $2;
	  $$->fieldType = checkIdentifierType($4,currentScope);			
	  $$->tag = VAR_PARAM;
	  $$->next = NULL;
	}
 ;

function_declaration : function_heading semicolon directive
    { /* not handled */ }
 | function_identification semicolon function_block
    { /* not handled */ }
 | function_heading semicolon function_block
    { restoreScope($1,&currentScope); }
 ;

function_heading : FUNCTION identifier COLON result_type
    { /* not handled */ }
 | FUNCTION identifier formal_parameter_list COLON result_type
	{
		$$ = (struct funcType *) malloc(sizeof(struct funcType));
		$$->returnType = checkIdentifierType($5,currentScope);
		$$->params = $3;
		$$->identifier = $2;
		$$->typeList = NULL;
		$$->localVariables = NULL;
		updateScope($$,&currentScope);
	}
 ;

result_type : identifier
	{ $$ = $1;}
;

function_identification : FUNCTION identifier 
    { /* not handled */ }

function_block : block ;

statement_part : compound_statement ;

compound_statement : PBEGIN statement_sequence END ;

statement_sequence : statement_sequence semicolon statement
 | statement
 ;

statement : assignment_statement
 | compound_statement
 | if_statement
 | while_statement
 ;

while_statement : WHILE boolean_expression DO statement
 ;

if_statement : IF boolean_expression THEN statement
   ELSE statement
 ;

assignment_statement : variable_access ASSIGNMENT expression
 ;

variable_access : identifier
 | indexed_variable
 | field_designator
 ;

indexed_variable : variable_access LBRAC index_expression_list RBRAC
 ;

index_expression_list : index_expression_list comma index_expression
 | index_expression
 ;

index_expression : expression ;

field_designator : variable_access DOT identifier
 ;

params : LPAREN actual_parameter_list RPAREN ;

actual_parameter_list : actual_parameter_list comma actual_parameter
 | actual_parameter
 ;

/*
 * this forces you to check all this to be sure that only write and
 * writeln use the 2nd and 3rd forms, you really can't do it easily in
 * the grammar, especially since write and writeln aren't reserved
 */
actual_parameter : expression
 | expression COLON expression
 | expression COLON expression COLON expression
 ;

boolean_expression : expression ;

expression : simple_expression
 | simple_expression relop simple_expression
 ;

simple_expression : term
 | simple_expression addop term
 ;

term : factor
 | term mulop factor
 ;

sign : PLUS
 | MINUS
 ;

factor : sign factor
 | primary 
 ;

primary : variable_access
 | unsigned_constant
 | function_designator
 | LPAREN expression RPAREN
 | NOT primary
 ;

unsigned_constant : unsigned_number
 | NIL
 ;

unsigned_number : unsigned_integer 
			{$$.ival = $1;}
                 | unsigned_real 
			{$$.fval = $1;}
 ;

unsigned_integer : DIGSEQ 
	{ $$ = yylval.unsigned_number.ival;}
 ;

unsigned_real : REALNUMBER
	{ $$ = yylval.unsigned_number.fval;}
 ;

/* functions with no params will be handled by plain identifier */
function_designator : identifier params
 ;

addop: PLUS
 | MINUS
 | OR
 ;

mulop : STAR
 | SLASH
 | DIV
 | MOD
 | AND
 ;

relop : EQUAL
 | NOTEQUAL
 | LT
 | GT
 | LE
 | GE
 ;

identifier : IDENTIFIER 
	{
	  $$ = yylval.identifier;
	}
 ;

semicolon : SEMICOLON
 ;

comma : COMMA
 ;

%%


void yyerror(char *s)
{
   printf("%d: %s at %s\n", line_no, s, yytext);
}

int notInList(char * id, struct idListType * idl)
{
   while (idl != NULL)
   {
	if (strcasecmp(idl->identifier,id)==0)
		return 0;
	idl = idl->next;
   }
   return 1;
}

int InList(char *id, struct idListType * idl)
{
   return !notInList(id,idl);
}


struct typeListType *searchType(char *typeName, struct funcType *scope)
{
	struct typeListType *type = scope->typeList;

	while (type != NULL)
	{
	   if (strcasecmp(typeName,type->name)==0)
		return type;
	   type = type->next;
	}

	return NULL;
}

void CheckDuplicateType(struct typeListType *tNode, struct typeListType *tl)
{
    while (tl != NULL)
    {
	if (strcasecmp(tNode->name, tl->name)==0)
	{
	   printf("Type name %s in line %d already declared in line %d\n",
		tNode->name,tNode->line_no,tl->line_no);
	   break; 
	}
 	tl = tl->next;
    }
}



void CheckCommon(struct idListType * l1, struct idListType * l2, 
		char * object, char * context)
{
   char * id;
   
   while (l1 != NULL)
   {
	if (InList(l1->identifier,l2))
	     printf("%s  %s in line %d %s\n", 
	             object,l1->identifier,l1->line_no,context);
	l1 = l1->next;
   }
  
}

void findIdInRecord(char * id, struct recElementType *RS, int line_no,
		char *object, char *context)
{
     while (RS != NULL)
     {
	if (InList(id,RS->fields))
	     printf("%s  %s in line %d  %s\n", 
	             object,id,line_no,context);
	RS = RS->next;
     }
	
}

void CheckCommonRS(struct idListType *l1, struct recElementType *RS,
		char *object, char *context)
{
    while (RS != NULL)
    {
       CheckCommon(l1, RS->fields, object, context);
       RS = RS->next;
    }
}

struct typeDenoter * checkIdentifierType(char *id, 
		struct funcType *currentScope)
{
          /* need to search all levels up to the highest
             level for "identifier" */
	  struct funcType *scope;

          if (strcasecmp(id, "integer")==0)
                return &integerType;
          if (strcasecmp(id, "boolean")==0)
                return &booleanType;
          if (strcasecmp(id, "real")==0)
                return &realType;

          foundType = NULL; scope = currentScope;
          while ((foundType == NULL) && (scope != NULL))
          {
              foundType = searchType(id,scope);
               scope = scope->parent;
          };

          if (foundType == NULL)
          {
              printf("line %d: .%s. invalid type denoter name\n", line_no,id);
              return  &INVALID;
          }
          else
              return foundType->type;
}

void restoreScope(struct funcType *childScope, struct funcType **parentScope)
{
	*parentScope = childScope->parent;
}

void updateScope(struct funcType *childScope, struct funcType **parentScope)
{
	childScope->siblings = (*parentScope)->children;
	(*parentScope)->children = childScope;
	childScope->parent = *parentScope;
	*parentScope = childScope;
	offset = 0; /* start a new offset for the new scope */
}

main()
{
   typeCounter = 0;

   /* initialize top most scope */
   currentScope = (struct funcType *) malloc(sizeof(struct funcType));
   currentScope->returnType = NULL;    /* this is null for the top scope */ 
   currentScope->params = NULL;    /* this is null for the top scope */
   currentScope->typeList = NULL;      /* this will be change if there
					are globally declared types */
   currentScope->localVariables = NULL; /* same as types */
   currentScope->parent = NULL; /* top scope has no parents */
   currentScope->siblings = NULL;       /* same as enclosing Scope */
   currentScope->children = NULL;       /* list of globally declared
					  functions */
   printf("done initializing\n .... ");


   yyparse();
}
