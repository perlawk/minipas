/* Size of hash table for identifier symbol table */
#define HashMax 100

/* Size of table of compiler generated address labels */
#define MAXL 1024

/* memory address type on the simulated machine */
typedef unsigned long ADDRESS;  	

/* Symbol table entry */
struct Ident 
	{char * name;
	struct Ident * link;
	int type; /* program name = 1,
		     integer = 2,
		     real = 3 */
	ADDRESS memloc;};

/* Symbol table */
struct Ident * HashTable[HashMax];

/* Linked list for declared identifiers */
struct idptr
	{struct Ident * ptr;
	 struct idptr * next;
	};
extern struct idptr * head;
extern int dcl;	/* processing the declarations section */

/* Binary search tree for numeric constants */
struct nums 
{
	ADDRESS memloc;
	struct nums * left;
	struct nums * right;
};

extern struct nums *  numsBST;

/* Record for file of atoms */
struct atom
{
	int op;		/* atom classes are shown below */
	ADDRESS left;
	ADDRESS right;
	ADDRESS result;
	int cmp;		/* comparison codes are 1-6 */
	int dest;
};
	
/* ADD, SUB, MUL, DIV, and JMP are also atom classes */
/* The following atom classes are not op codes */
#define NEG 10
#define LBL 11
#define TST 12
#define MOV 13

FILE * atom_file_ptr;
extern ADDRESS avail; 
extern ADDRESS end_data;
extern int err_flag;		/* has an error been detected? */

