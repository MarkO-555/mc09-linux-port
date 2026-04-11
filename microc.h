#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/*
 * This file contains definitions which compensate for minor differences
 * between MICRO-C's library, and the libraries which are supplied with
 * many commercial compilers:
 *
 * delete()	- Redefined as 'unlink'.
 * fgets()	- Removes NEWLINE from end of input line.
 * abort()	- Outputs message before terminating.
 *
 * DO NOT USE THIS FILE IF COMPILING WITH MICRO-C.
 */

#define	delete		unlink
#define fgets		MC_fgets
#define abort		MC_abort

/*
 * Function to read a line from the input file without
 * placing a newline character at the end.
 */
char *MC_fgets(dest, size, fp)
	char *dest;
	int size;
	FILE *fp;
{
	register int chr;
	register char *ptr;

	ptr = dest;
	while(--size) {
		if((chr = getc(fp)) < 0) {		/* end of file */
			if(ptr == dest)
				dest = 0;				/* no last line, indicate end */
			break; }
		if(chr == '\n')					/* end of line */
			break;
		if(chr == '\r')					/* strip CR from CRLF */
			continue;
		*ptr++ = chr; }
	*ptr = 0;
	return dest;
}

/*
 * Function to abort with an error message
 */
MC_abort(ptr)
	char *ptr;
{
	fputs(ptr, stderr);
	exit(-1);
}

/*
 * strbeg() - test if string s begins with prefix p.
 * Dunfield Micro-C built-in, not present in standard C libraries.
 */
static int strbeg(char *s, char *p) {
    while(*p)
        if(*s++ != *p++) return 0;
    return 1;
}
