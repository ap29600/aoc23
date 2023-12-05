; syntax M68k

String_split:; (
; a1: string to be split
; a2: split characters (null terminated)
; ) -> (
; a0: start of first split (unmodified)
; d0: length of first split (excluding separator)
; a1: rest of string
; d1: index of matching separator
; a2: <unmodified>
; d2.b: byte separator matched
; )
	move.l  a1,a0
.haystack_next:
	move.b  (a1)+,d2
	beq     .end_of_haystack
	moveq.l #0,d1
.compare_needles_loop:
	tst.b   (a2,d1.w)
	beq     .haystack_next ;; no more needles
	cmp.b   (a2,d1.w),d2
	beq     .found_needle
	addq.l  #1,d1
	bra     .compare_needles_loop
	
.end_of_haystack:
	sub.l   #1,a1  ;; over-read
	move.l  a1,d0
	sub.l   a0,d0  ;; length of split
	move.l  #-1,d1 ;; no match
	rts

.found_needle:
	move.l  a1,d0
	sub.l   a0,d0
	sub.l   #1,d0  ;; length of split
	rts

String_len:; (
;     a0: string address
; ) -> (
;     d0: string length
; )
	move.l  a0,-(sp)
	moveq.l #0,d0
	cmp.l   #0,a0   ;; null string has length 0.
	beq     .exit
.loop:
	tst.b   (a0)+
	beq     .exit
	add.l   #1,d0
	bra     .loop

.exit:
	move.l  (sp)+,a0
	rts

