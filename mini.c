/* simulate the mini architecture */
/* 32-bit word addressable machine, with 16 registers.
   r1:  program counter
   ir:	instruction register
   r0-r15:	general registers (32 bits)
   fpr0-fpr15:	floating point registers (32 bits)
  
   instruction format:
	bits	function
	0-3	opcode	1	r1 = r1+s2
			2	r1 = r1-s2
			4	r1 = r1*s2
			5	r1 = r1/s2
			7	pc = S2 if flag		JMP
			8	flag = r1 cmp s2	CMP
			9	r1 = s2			Load
			10	s2 = r1			Store
			11	r1 = 0			Clear

	4	mode	0	s2 is 20 bit address
			1	s2 is 4 bit reg (r2) and 16 bit offset (o2)

	5-7	cmp	0	<=>	always true
			1	=
			2	<
			3	>
			4	<=
			5	>=
			6	<>

	8-11	r1		register address for first operand
	12-31	s2		storage adress if mode=0
	12-15	r2		part of storage address if mode=1
	16-31	o2		rest of storage address if mode=1
				if mode=1, s2 = c(r2) + o2 */

#include <stdio.h>
#include "mini.h"
#define PC reg[1]

FILE * tty;			/* read from keyboard */


unsigned long addr;
unsigned int flag, r2, o2;

void dump (void);
void dumpmem(int low, int high);
void dumpregs (void);
void boot(void);

int
main (void)
{

	int n = 1, count;

	boot(); /* load memory from stdin */

	tty = fopen ("/dev/tty", "r");	/* read from keyboard even if stdin is
																		 redirected */
	while (n>0)
	{
		for (count = 1; count<=n; count++)
		{	/* fetch */
			ir.full32 = memory[PC++].instr;
			if (ir.instr.mode==1) 
			{  o2 = ir.instr.s2 & 0x0ffff;
				r2 = ir.instr.s2 & 0xf0000;	
				addr = reg[r2] + o2;}
			else  addr = ir.instr.s2;

			switch (ir.instr.op)
			{ 
				case ADD:	fpreg[ir.instr.r1].data = fpreg[ir.instr.r1].data + 
				memory[addr].data;
				break;
				case SUB:	fpreg[ir.instr.r1].data = fpreg[ir.instr.r1].data - 
									memory[addr].data;
									break;
				case MUL:	fpreg[ir.instr.r1].data = fpreg[ir.instr.r1].data * 
									memory[addr].data;
									break;
				case DIV:	fpreg[ir.instr.r1].data = fpreg[ir.instr.r1].data /
									memory[addr].data;
									break;
				case JMP:	if (flag) PC = addr;  /* conditional jump */
										break;
				case CMP:	switch (ir.instr.cmp)
									{
										case 0:	flag = TRUE;	/* unconditional */
														break;
										case 1:	flag = fpreg[ir.instr.r1].data == 
														memory[addr].data;
														break;
										case 2:	flag = fpreg[ir.instr.r1].data <
													 	memory[addr].data;
														break;
										case 3:	flag = fpreg[ir.instr.r1].data > 
														memory[addr].data;
														break;
										case 4:	flag = fpreg[ir.instr.r1].data <= 
														memory[addr].data;
														break;
										case 5:	flag = fpreg[ir.instr.r1].data >= 
														memory[addr].data;
														break;
										case 6:	flag = fpreg[ir.instr.r1].data != 
														memory[addr].data;
									}
				case LOD:	fpreg[ir.instr.r1].data = memory[addr].data;
									break;
				case STO: memory[addr].data = fpreg[ir.instr.r1].data;
									break;
				case CLR: fpreg[ir.instr.r1].data = 0.0;
									break;
				case HLT:  n = -1;
			}
		}
		dump ();
		printf ("Enter number of instruction cycles, 0 for no change, or -1 to quit\n");
		/* read from keyboard if stdin is redirected */
		fscanf (tty,"%d", &count);
		if (count!=0 && n>0) n = count;
	}

	return 0;
}

	void
dump (void)
{ 
	dumpregs();
	dumpmem(0,15);
}

	void
dumpregs (void)
{
	int i;
	char * pstr;

	printf ("ir = %08x\n", ir.full32);
	for (i=0; i<8; i++)
	{ 
		if (i==1) pstr = "PC = "; else pstr = "     ";
		printf ("%s reg[%d] = %08x = %d\tfpreg[%d] = %08x = %e\n",
				pstr,i,reg[i],reg[i],i,fpreg[i].instr,fpreg[i].data);
	}
}

	void
dumpmem(int low, int high)
{
	int i;
	char * f;
	low = low/4*4;
	high = (high+4)/4*4 - 1; 
	if (flag) f = "TRUE"; else f = "FALSE";
	printf ("memory\t\t\t\t\tflag = %s\naddress\t\tcontents\n",f);
	for (i=low; i<=high; i+=4)
		printf ("%08x\t%08x     %08x     %08x     %08x\n\t\t%8e %8e %8e %8e\n",
				i,memory[i].instr,
				memory[i+1].instr,memory[i+2].instr,memory[i+3].instr,
				memory[i].data,memory[i+1].data,memory[i+2].data,memory[i+3].data);
}

	void
boot(void)
	/* load memory from stdin */
{ 
	int i = 0;

	scanf ("%8lx%*[^\n]\n", &PC);		/* starting address of instructions */

	while (EOF!=scanf ("%8lx%*[^\n]\n", &memory[i++].instr));
}
