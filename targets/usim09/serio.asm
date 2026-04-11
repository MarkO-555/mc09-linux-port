*
* serio.asm - Serial I/O for usim09 (MC6850 ACIA at $C000)
*
* usim09 MC6850 register map:
*   $C000 = Status register  (read)  / Control register (write)
*           bit 0 = RDRF (RX data ready)
*           bit 1 = TDRE (TX data empty - ready to send)
*   $C001 = RX data register (read)  / TX data register (write)
*
* The 6551 in the default SERIO.ASM uses a different layout:
*   status at base+1, TX bit $10, RX bit $08, data at base+0
* We fix all four differences here.
*
?uart	EQU	$C000		MC6850 ACIA base address

* Write a string to the console: putstr(char *string)
putstr	LDX	2,S		Get string address
?putstr	LDB	,X+		Get character
	BEQ	?1		End of string, exit
	BSR	?putch		Write the character
	BRA	?putstr		And proceed

* Write character to console - translate LF to CR+LF: putch(char c)
putch	LDD	2,S		Get char to write
?putch	CMPB	#$0A		Newline?
	BNE	?putchr		No, write it raw
	BSR	?putchr		Yes: write LF first
	LDB	#$0D		Then write CR
	BRA	?putchr		And exit

* Write character raw to console: putchr(char c)
putchr	LDD	2,S		Get char to write
?putchr	LDA	?uart		Read MC6850 status register
	BITA	#$02		TDRE set? (bit 1 = TX empty/ready)
	BEQ	?putchr		No, wait
	STB	?uart+1		Write char to TX data register
?1	RTS

* Check for character (non-blocking): chkchr() -> -1 if none, char if ready
chkchr	LDA	?uart		Read status
	BITA	#$01		RDRF set? (bit 0 = RX data ready)
	BNE	getchr		Yes, go read it
	LDD	#-1		No char available
	RTS

* Check for character, return 0/non-zero: chkch()
chkch	LDA	?uart		Read status
	CLRB			Zero high
	ANDA	#$01		Isolate RDRF bit
	BEQ	?1		Not ready, return 0
	RTS

* Read character from console - translate CR to LF: getch()
getch	BSR	getchr		Get raw character
	CMPB	#$0D		CR?
	BNE	?1		No, return as-is
	LDB	#$0A		Convert to LF
?1	RTS

* Read character raw from console: getchr()
getchr	LDA	?uart		Read status register
	BITA	#$01		RDRF set?
	BEQ	getchr		No, wait
	LDB	?uart+1		Read RX data register
	CLRA			Zero high byte
	RTS

* Read a string (with editing) from console: getstr(buffer, length)
getstr	LDU	4,S		Get buffer pointer
	LDX	#0		Starting length = 0
?2	BSR	getch		Get a character
	CMPB	#$7F		DEL?
	BEQ	?3		Handle backspace
	CMPB	#$08		Backspace?
	BEQ	?3		Handle backspace
	CMPB	#$0A		Enter (LF)?
	BEQ	?4		Yes, done
	CMPX	2,S		Within length?
	BHS	?2		No, ignore
	STB	,U+		Store char in buffer
	LEAX	1,X		Advance length
	BSR	?putchr		Echo character
	BRA	?2		Loop
?3	CMPX	#0		Any data in buffer?
	BEQ	?2		No, ignore
	LDB	#$08		Backspace
	BSR	?putchr		Echo
	LDB	#' '		Space (erase)
	BSR	?putchr
	LDB	#$08		Backspace again
	BSR	?putchr
	LEAX	-1,X		Reduce count
	LEAU	-1,U		Back up in buffer
	BRA	?2		Loop
?4	CLR	,U		Null-terminate buffer
	BSR	?putch		Echo newline
	TFR	X,D		Return char count
	RTS
*50000 8/4/2026
