INT	[0-9]+
EXP	([eE][+-]?{INT})
NUM	{INT}\.?{INT}?{EXP}?

%{
#include <stdio.h>
#include <stdlib.h>
#include "mini.h"
#include "minipas.h"
#include "minipas.tab.h"
ADDRESS searchIdent(void);
ADDRESS searchNums(void);
ADDRESS alloc(int size);
/*extern int lineno;*/
extern int lineno;
extern ADDRESS avail;
extern ADDRESS end_data;
extern struct nums *numsBST;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;

/*#define YYERROR(X) yyerror(X)*/
#define YYERROR(X) printf(X)
%}

%%

program  return  PROGRAM;
var      return  VAR;
for      return  FOR;
to       return  TO;
do       return  DO;
while    return  WHILE;
if       return  IF;
then     return  THEN;
else     return  ELSE;
begin    return  BEGN;     /* BEGIN is reserved */
end      return  END;

integer	{ yylval.code = 2; return INTEGER; }
real		{ yylval.code = 3; return REAL; }

=    		{ yylval.code = 1; return COMPARISON; }
\<			{ yylval.code = 2; return COMPARISON; }
>				{ yylval.code = 3; return COMPARISON; }
"<="		{ yylval.code = 4; return COMPARISON; }
">="		{ yylval.code = 5; return COMPARISON; }
"<>"		{ yylval.code = 6; return COMPARISON; }
":="		return ASSIGN;

\+  return  PLUS;
\-  return  MINUS;
\*  return  TIMES;
\/  return  DIVIDE;
\.  return  DOT;
\(  return  LPAREN;
\)  return  RPAREN;
\;  return  SEMICOLON;
\:  return  COLON;
\,  return  COMMA;

[a-z][a-z0-9_]*	  { yylval.address = searchIdent(); return IDENTIFIER; }
{NUM}						  { yylval.address = searchNums(); return NUM; }
[ \t]							;  /* white space */
\{[^}]*\}				  ;  /* comments */

\n				        lineno++;	 /* free format */
.		              return yytext[0];	/* any other char */

%%

yywrap ()
{ 
		return 1;  /* terminate when reaching end of stdin */ 
}

ADDRESS searchIdent(void)
/* search the hash table for the identifier in yytext. insert if
necessary */
{ 
	struct Ident * ptr;
	int h;
	h = hash(yytext);
	ptr = HashTable[h];
	while ((ptr!=NULL) && (strcmp(ptr->name,yytext)!=0)) ptr = ptr->link;

	if (ptr==NULL) 
		 if (dcl)
			{ 
			ptr =  malloc (sizeof (struct Ident));
			 ptr->link = HashTable[h];
			 strcpy (ptr->name = malloc (yyleng+1), yytext);
			 HashTable[h] = ptr;
			 ptr->memloc = alloc(1);
			save_ident(ptr);
		 }
		 else 
		 {
			 printf ("%s \n", yytext);
			 YYERROR ("undeclared identifier");
			 return 0;
		 }
		 else if (dcl) 
		 {
			 printf("%s \n", yytext);
			 YYERROR ("multiply defined identifier");
		 }
		 return ptr->memloc;
}


int hash(char * str)
{ 
	int h=0, i;    
	for (i=0; i<yyleng; i++) h += str[i];
	return h % HashMax;
}

save_ident(struct Ident * hashptr)
/* save the identifiers in a declaration in a linked list so that the
type can be filled in when we know what it is */
{ 
	struct idptr * p;

	p = (struct idptr *) malloc (sizeof (struct idptr));
	p -> ptr = hashptr;
	p -> next = head;
	head = p;
} 
	
ADDRESS searchNums(void)
/*  search the binary search tree of numbers for the number in
		yytext.  Insert if not found. */
{ 
	struct nums * ptr;
	struct nums * parent;
	double val;

	sscanf (yytext,"%lf",&val);
	if (numsBST==NULL)
	 { numsBST = malloc (sizeof (struct nums));
		 memory[numsBST->memloc = alloc(1)].data = val;
		 numsBST->left = numsBST->right = NULL;
		 return numsBST->memloc;
	 }

	ptr = numsBST;
	while (ptr!=NULL)
	 { if (memory[ptr->memloc].data==val) return ptr->memloc; 
		 parent = ptr;
		 if (memory[ptr->memloc].data<val) ptr = ptr->left;
		 else ptr = ptr->right;
	 }

	ptr = malloc (sizeof (struct nums));
	memory[ptr->memloc = alloc(1)].data = val;
	ptr->left = ptr->right = NULL;
	if (memory[parent->memloc].data<val) parent->left = ptr;
		else parent->right = ptr;

	return ptr->memloc;
}


ADDRESS alloc (int size)
/* allocate words on the target machine memory */
{ 
	ADDRESS t;

	t = avail;
	avail += size;
	return t;
}
