*
* SERIO.ASM - Serial I/O for usim09 (MC6850 ACIA at $C000)
* Processed with unique local labels for slink compatibility.
*
* MC6850 register map (usim09):
*   $C000+0 = Status (R) / Control (W): bit0=RDRF, bit1=TDRE
*   $C000+1 = RX data (R) / TX data (W)
*
?uart	EQU	$C000
* putstr(char *string) - write null-terminated string
putstr	LDX	2,S
?1	LDB	,X+
	BEQ	?2
	BSR	?putch
	BRA	?1
?2	RTS
* putch(char c) - write char, translating LF->CRLF
putch	LDD	2,S
?putch	CMPB	#$0A
	BNE	?putchr
	BSR	?putchr
	LDB	#$0D
	BRA	?putchr
* putchr(char c) - write char raw
putchr	LDD	2,S
?putchr	LDA	?uart
	BITA	#$02
	BEQ	?putchr
	STB	?uart+1
	RTS
* chkchr() - non-blocking check: return char or -1
chkchr	LDA	?uart
	BITA	#$01
	BNE	getchr
	LDD	#-1
	RTS
* chkch() - non-blocking check: return 0 or non-zero
chkch	LDA	?uart
	CLRB
	ANDA	#$01
	RTS
* getch() - read char, translating CR->LF
getch	BSR	getchr
	CMPB	#$0D
	BNE	?3
	LDB	#$0A
?3	RTS
* getchr() - read char raw
getchr	LDA	?uart
	BITA	#$01
	BEQ	getchr
	LDB	?uart+1
	CLRA
	RTS
* getstr(buffer, length) - read line with editing
getstr	LDU	4,S
	LDX	#0
?4	BSR	getch
	CMPB	#$7F
	BEQ	?5
	CMPB	#$08
	BEQ	?5
	CMPB	#$0A
	BEQ	?6
	CMPX	2,S
	BHS	?4
	STB	,U+
	LEAX	1,X
	BSR	?putchr
	BRA	?4
?5	CMPX	#0
	BEQ	?4
	LDB	#$08
	BSR	?putchr
	LDB	#' '
	BSR	?putchr
	LDB	#$08
	BSR	?putchr
	LEAX	-1,X
	LEAU	-1,U
	BRA	?4
?6	CLR	,U
	BSR	?putch
	TFR	X,D
	RTS
