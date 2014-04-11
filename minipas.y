%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "mini.h" 
#include "minipas.h"

ADDRESS save;
ADDRESS one;   
ADDRESS alloc(int);   
extern char *yytext;

/* global variables */
char *progname;
char * op_text();
int lineno = 1;
int nextlabel = 1;
int err_flag = FALSE;
struct idptr *head = NULL;
int dcl = TRUE;
ADDRESS avail = 0, end_data = 0;
struct nums *numsBST = NULL;

%}

%union {
	ADDRESS  address;
	int code;	/* comparison code 1-6 */
	struct 	{int L1;
		 int L2;
		 int L3;} labels;
}

%token PROGRAM
%token VAR
%token FOR
%token TO
%token DO 
%token WHILE
%token ASSIGN
%token IF
%token THEN
%token ELSE
%token BEGN
%token END
%token COLON
%token COMMA
%token SEMICOLON
%token DOT
%token PLUS
%token MINUS
%token TIMES
%token DIVIDE
%token LPAREN
%token RPAREN

%token  <address>  IDENTIFIER
%token  <address>  NUM
%token  <code>     COMPARISON
%token  <code>     INTEGER
%token  <code>     REAL

/* nonterminal types are: */  

%type  <code>     Type
%type  <address>  Expr
%type  <labels>   WhileStmt
%type  <labels>   ForStmt
%type  <labels>   IfStmt
%type  <labels>   Comparison

%left '+' '-'
%left '*' '/'
%left UMINUS UPLUS   /* precedence of unary operators */

%%

Program:	PROGRAM IDENTIFIER SEMICOLON  Declarations CompoundStmt DOT
		;
IdentList:	IDENTIFIER	
		| IdentList COMMA IDENTIFIER 
		;
Declarations:	VAR 					{dcl = TRUE;}
		DecList					{dcl = FALSE;}
		;
DecList:	IdentList COLON Type SEMICOLON			{st_type($3);}
		| DecList IdentList COLON Type SEMICOLON 	{st_type($4);}
		;
Type:		INTEGER					{$$ = $1;}
		| REAL					{$$ = $1;}
		;
Stmt:				/* Null Stmt */
		| ForStmt
		| WhileStmt
		| AssignStmt
		| IfStmt
		| CompoundStmt
		;
ForStmt:	FOR IDENTIFIER ASSIGN Expr 	{atom (MOV, $4,NULL,$2,0,0);}
		TO Expr 		{atom (MOV,$7,NULL,save=alloc(1),0,0);
					 $<labels>$.L1 = newlabel();
					 atom (LBL,NULL,NULL,NULL,0,$<labels>$.L1);
					 $<labels>$.L2 = newlabel();
				  	 atom (TST,$2,save,NULL,3,$<labels>$.L2);}
		DO Stmt			{atom (ADD, $2, one, $2,0,0);
					 atom (JMP,NULL,NULL,NULL,0,
						$<labels>8.L1);
					 atom (LBL,NULL,NULL,NULL,0,
						$<labels>8.L2);} 
		;	
WhileStmt:	WHILE 			{$<labels>$.L2 = newlabel(); /*  here!*/
					 atom (LBL,NULL,NULL,NULL,0,$<labels>$.L2);}
		Comparison 		{$<labels>$.L3 = newlabel();
					 atom (JMP,NULL,NULL,NULL,0,$<labels>$.L3);
					 atom (LBL,NULL,NULL,NULL,0,$3.L1);}
		DO Stmt			{atom (JMP,NULL,NULL,NULL,0,
						$<labels>2.L2);
					 atom (LBL,NULL,NULL,NULL,0,
						$<labels>4.L3);}
		;
Comparison:	Expr COMPARISON Expr	{$$.L1 = newlabel();
					 atom (TST, $1, $3,NULL,$2,$$.L1);}
		;
AssignStmt:	IDENTIFIER ASSIGN Expr {atom (MOV, $3,NULL,$1,0,0);}
		;
IfStmt:		IF Comparison 		{$<labels>$.L2 = newlabel();
					 atom (JMP,NULL,NULL,NULL,0,$<labels>$.L2);
					 atom (LBL,NULL,NULL,NULL,0,$2.L1);}
		THEN Stmt 		{$<labels>$.L3 = newlabel();
					 atom (JMP,NULL,NULL,NULL,0,$<labels>$.L3);
					 atom (LBL,NULL,NULL,NULL,0,
						$<labels>3.L2);}
		ElsePart		{atom (LBL,NULL,NULL,NULL,0,
						$<labels>6.L3);} 
		;
ElsePart:	
		| ELSE Stmt
		;
CompoundStmt:	BEGN StmtList END
		;
StmtList:	Stmt   	
		| StmtList SEMICOLON Stmt
		; 
Expr:		PLUS Expr %prec UPLUS	{$$ = $2;}
		| MINUS Expr  %prec UMINUS	{ $$ = alloc(1);
					 atom (NEG, $2,NULL,$$,0,0); } 
		| Expr PLUS Expr 	{$$ = alloc(1); 
					 atom (ADD, $1, $3,$$,0,0); }
		| Expr MINUS Expr		{$$ = alloc(1);
					 atom (SUB, $1, $3, $$,0,0); }
		| Expr TIMES Expr		{$$ = alloc(1);
					 atom (MUL, $1, $3, $$,0,0); }
		| Expr DIVIDE Expr		{$$ = alloc(1);
					 atom (DIV, $1, $3, $$,0,0); }
		| LPAREN Expr RPAREN	{$$ = $2;}
		| IDENTIFIER		{$$ = $1;}
		| NUM   		{$$ = $1;}
		;

%%

/*#include "lex.yy.c"*/
/*#include "gen.c"*/
#define BUFSIZE 256

main (int argc, char *argv[])
{
  progname = argv[0];
  atom_file_ptr = fopen ("atoms", "wb");
	yytext = (char *)malloc(BUFSIZE);
	if (!yytext) {
		fprintf(stderr, "malloc error!");
		return 0;
	}
  strcpy (yytext,"1.0");
  one = searchNums();	/* install the constant 1.0 in table */
  yyparse();
  fclose (atom_file_ptr);
  if (!err_flag) code_gen();
}

yyerror (char * s)
{
  fprintf(stderr, "%s[%d]: %s\n", progname, lineno, s);
  err_flag = TRUE;
}

newlabel (void)
{ return nextlabel++;}

atom (int operation, ADDRESS operand1, ADDRESS operand2, 
		     ADDRESS result, int comparison, int dest)
/* put out an atom. destination will be a label number. */
{ 
  struct atom outp;
  
  outp.op = operation;
  outp.left = operand1;
  outp.right = operand2;
  outp.result = result;
  outp.cmp = comparison;
  outp.dest = dest;
  
  fwrite (&outp, sizeof (struct atom), 1, atom_file_ptr);
} 

st_type(int type)
/* fill in the type of the variables declared */
{ 
  struct idptr * p;

  while (head)
    { head->ptr->type = type;
      p = head;
      head = head->next;
      free (p);
    }
}
