*
* putnum(n) - print unsigned decimal integer
*
* Entry: 2,S = n (unsigned 16-bit), 0,S = return address
* Uses: ?mod (runtime), ?putchr (serio internal entry point)
*
* Stack layout at entry to digit loop (after PSHS U, LEAS -6,S):
*   0,S .. 5,S = 6-byte digit buffer  (LSD stored first)
*   6,S .. 7,S = saved U
*   8,S .. 9,S = return address
*  10,S ..11,S = n (argument)
*
* U = buffer write pointer (starts at buf[0], grows right each digit)
* X = scratch (quotient from ?mod)
*
putnum	PSHS	U		Save U
	LEAS	-6,S		Allocate 6-byte digit buffer
	LEAU	,S		U -> buf[0] (will advance right)
*
	LDD	10,S		Get n from stack
	BNE	?1		Non-zero: divide out digits
	LDB	#'0'		Zero: print single '0' and return
	LBSR	?putchr
	BRA	?3
*
* Digit extraction loop: ?mod(X=value, D=10) -> D=digit, X=quotient
?1	TFR	D,X		X = current value (dividend)
	LDD	#10		D = 10 (divisor)
	JSR	?mod		D = value MOD 10 (digit), X = value DIV 10
	ADDB	#'0'		digit to ASCII
	STB	,U+		store in buffer, advance U
	TFR	X,D		D = quotient
	BNE	?1		more digits?
*
* Print digits MSD-first: walk U back to buf[0] printing each char
* U now points one past the last (MSD) digit.
* S still points to buf[0]. Compare U to S to know when done.
?2	CMPU	10,S		U <= S? (10,S is still n, reuse as: NO)
*
* We need buf_start address. Save it. Use 10,S slot (n already used).
* Actually: simpler - save buf start into 10,S (overwrite n, done with it).
	STU	12,S		Save end pointer past buf into spare slot
*
* Cleaner: use a saved copy of S (buf start) in the unused arg slot.
* Even simpler: LEAS 6,S first to undo buf, keep U as end, S as start.
*
* Actually the simplest correct approach: save buf start in X.
* But X is clobbered. Save in a local.
*
* Let's use: TFR S,X = buf start address, then count down U to X.
	TFR	S,X		X = buf start address
?2a	CMPU	,X		U == buf start? (compare U to address in X = S)
* NO: CMPU ,X dereferences X to get a word, not compare to X itself.
* 6809 has no "compare register to register" for U/S/X directly.
* Closest: LEAX -1,X and compare the address byte by byte? 
* Or: use PSHU X to push X then CMPU ,S++ ?
* 
* Simplest solution: use a decremented counter. 
* Before loop: STU end_ptr. At ?2: reload, decrement, compare to buf start.
* Use Y register (save/restore).
	PSHS	X		Save buf start temporarily
*
?2b	LEAU	-1,U		Back up one digit (toward MSD)
	LDB	,U		Load digit character
	LBSR	?putchr		Print it
	CMPU	,S		U now equals saved buf start?
* ,S = top of S stack = the value we PSHSed (buf start address)
* CMPU ,S: compare U to the 16-bit value AT address S.
* That value IS the buf start address we pushed. Correct!
	BNE	?2b		Not yet, keep going
*
	PULS	X		Discard saved buf start
?3	LEAS	6,S		Remove digit buffer
	PULS	U		Restore U
	RTS
*
$EX:?mod
$EX:?putchr
