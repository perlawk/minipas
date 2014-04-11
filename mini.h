#define MaxMem 0xffff
#define TRUE 1
#define FALSE 0

/* Op codes are defined here: */
#define CLR 0
#define ADD 1
#define SUB 2
#define MUL 3
#define DIV 4
#define JMP 5
#define CMP 6
#define LOD 7
#define STO 8
#define HLT 9

/* Memory word on the simulated machine may be treated as numeric data
   or as an instruction */
union { float data;
	unsigned long instr;
	} memory [MaxMem];


/* careful!  this structure is machine dependent! */
struct fmt 
  { unsigned int s2:   20;
    unsigned int r1:	4;
    unsigned int cmp:   3;
    unsigned int mode:  1;
    unsigned int op:	4;
   }
   ;

union {
	struct fmt instr;
	unsigned long full32;
      } ir; 

unsigned long reg[8];
union {	float data;
	unsigned long instr;
      } fpreg[8];
