?0 EQU $C000
putstr LDX 2,S
?1 LDB ,X+
 BEQ ?4
 BSR ?2
 BRA ?1
putch LDD 2,S
?2 CMPB #$0A
 BNE ?3
 BSR ?3
 LDB #$0D
 BRA ?3
putchr LDD 2,S
?3 LDA ?0
 BITA #$02
 BEQ ?3
 STB ?0+1
?4 RTS
chkchr LDA ?0
 BITA #$01
 BNE getchr
 LDD #-1
 RTS
chkch LDA ?0
 CLRB Zero
 ANDA #$01
 BEQ ?4
 RTS
getch BSR getchr
 CMPB #$0D
 BNE ?4
 LDB #$0A
?4 RTS
getchr LDA ?0
 BITA #$01
 BEQ getchr
 LDB ?0+1
 CLRA Zero
 RTS
getstr LDU 4,S
 LDX #0
?6 BSR getch
 CMPB #$7F
 BEQ ?7
 CMPB #$08
 BEQ ?7
 CMPB #$0A
 BEQ ?8
 CMPX 2,S
 BHS ?6
 STB ,U+
 LEAX 1,X
 BSR ?3
 BRA ?6
?7 CMPX #0
 BEQ ?6
 LDB #$08
 BSR ?3
 LDB #' '
 BSR ?3
 LDB #$08
 BSR ?3
 LEAX -1,X
 LEAU -1,U
 BRA ?6
?8 CLR ,U
 BSR ?2
 TFR X,D
 RTS
