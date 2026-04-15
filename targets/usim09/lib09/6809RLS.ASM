*
* 6809RLS.ASM - Runtime suffix for usim09
*
* Heap starts immediately after code/data.
* Reset vector points to startup code (?begin in 6809RLP.ASM).
*
?heap	EQU	*		Heap starts here

* usim09 6809 vector table at top of ROM ($FFF0-$FFFF)
	ORG	$FFF0
	FDB	$FFFF		UNDEF  (unused)
	FDB	$FFFF		SWI3   (unused)
	FDB	$FFFF		SWI2   (unused)
	FDB	$FFFF		FIRQ   (unused)
	FDB	$FFFF		IRQ    (unused)
	FDB	$FFFF		SWI    (unused)
	FDB	$FFFF		NMI    (unused)
	FDB	?begin		RESET  -> startup
