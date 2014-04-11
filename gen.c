#include <stdio.h>
#include "mini.h"
#include "minipas.h"

struct atom inp;
long labels[MAXL];
ADDRESS pc=0;
int ok = TRUE;
long lookup (int);

char * op_text(int operation);
void out_mem(void);
void get_atom(void);
void build_labels(void);

void
code_gen (void)
{ 
	int r;
 
  /* send target machine memory containing constants to stdout */
  end_data = alloc(0);			/* constants precede instructions */
  out_mem();

  atom_file_ptr = fopen ("atoms","rb");  /* open file of atoms */
  pc = end_data;			/* starting address of instructions */
  build_labels();			/* first pass */
  fclose (atom_file_ptr);

  atom_file_ptr = fopen ("atoms","rb");	/* open file of atoms for */
  get_atom();				/* second pass */
  pc = end_data;
  ok = TRUE;
 while (ok)				
  {
 /*  dump_atom();  */ 
 
  switch (inp.op)			/* check atom class */
	{ case ADD:  gen (LOD, r=regalloc(),inp.left);
	             gen (ADD, r, inp.right);
	             gen (STO, r, inp.result);
		break;
	case SUB:    gen (LOD, r=regalloc(), inp.left);
	             gen (SUB, r, inp.right);
	             gen (STO, r, inp.result);
		break;
	case NEG:    gen (CLR, r=regalloc());
		     gen (SUB, r, inp.left);
		     gen (STO, r, inp.result);
		break;
	case MUL:    gen (LOD, r=regalloc(), inp.left);
		     gen (MUL, r, inp.right);
		     gen (STO, r, inp.result);
		break;
	case DIV:    gen (LOD, r=regalloc(), inp.left);
		     gen (DIV, r, inp.right);
		     gen (STO, r, inp.result);
		break;
	case JMP:    gen (CMP, 0, 0, 0);
		     gen (JMP);
		break;
	case TST:     gen (LOD, r=regalloc(), inp.left);
		      gen (CMP, r, inp.right, inp.cmp);
		      gen (JMP);
		break;
	case MOV:     gen (LOD, r=regalloc(), inp.left);
		      gen (STO, r, inp.result);
		break;
	}
  get_atom();
 }
  gen (HLT);
}

void
get_atom(void)
/* read an atom from the file of atoms into inp */
/* ok indicates that an atom was actually read */
{ 
	int n;

  n = fread (&inp, sizeof (struct atom), 1, atom_file_ptr);
  if (n==0) ok = FALSE;
}

void
dump_atom(void)
{ 
	printf ("op: %d  left: %04x  right: %04x  result: %04x  cmp: %d  dest: %d\n",
           inp.op, inp.left, inp.right, inp.result, inp.cmp, inp.dest); 
}
 
gen (int op, int r, ADDRESS add, int cmp)
/* generate an instruction to stdout 
   op is the simulated machine operation code
   r is the first operand register
   add is the second operand address
   cmp is the comparison code for compare instructions	1 is =
							2 is <
							3 is >
							4 is <=
							5 is >=
							6 is <>
   jump destination is taken from the atom inp.dest
*/
{
	union {
		struct fmt instr;
	  unsigned long word;
  } outp;

 outp.word = 0;

 outp.instr.op = op;				/* op code */
 if (op!=JMP)
   { outp.instr.r1 = r;				/* first operand */
     outp.instr.s2 = add;			/* second operand */
   }
  else outp.instr.s2 = lookup (inp.dest);	/* jump destination */
 if (op==CMP) outp.instr.cmp = cmp;  		/* comparison code 1-6 */

 printf ("%08x\t%04x\t%s\n", outp.word, pc, op_text(op));
 pc++;
}


int regalloc (void)
/* allocate a register for use in an instruction */
{ 
	return 1; 
}

void
build_labels(void)
/* Build a table of label values on the first pass */
{ 
  get_atom();
  while (ok)
  {
    if (inp.op==LBL) 
      	labels[inp.dest] = pc;

	/* MOV and JMP atoms require two instructions,
	   all other atoms require three instructions. */
	  else if (inp.op==MOV || inp.op==JMP) pc += 2;
		else pc += 3;
    get_atom();
  }
}


long lookup (int label_num)
/* look up a label in the table and return it's memory address */
{ 
	return labels[label_num];
}

void
out_mem(void)
/* send target machine memory contents to stdout.  this is the beginning
of the object file, to be followed by the instructions.  the first word
in the object file is the starting address of the program; the next word
is memory location 0. */
{
  ADDRESS i;

  printf ("%08x\tLoc\tDisassembled Contents\n", end_data);
		/* starting address of instructions */
  for (i=0; i<end_data; i++)
	printf ("%08x\t%04x\t%8lf\n", memory[i].instr, i,
		memory[i].data);
}



char * op_text(int operation)
/* convert op_codes to mnemonics */
{
  switch (operation)
	{ 
		case CLR: return "CLR";
	  case ADD: return "ADD";
	  case SUB: return "SUB";
	  case MUL: return "MUL";
	  case DIV: return "DIV";
	  case JMP: return "JMP";
	  case CMP: return "CMP";
	  case LOD: return "LOD";
	  case STO: return "STO";
	  case HLT: return "HLT";
	}
}
