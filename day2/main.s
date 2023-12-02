; syntax M68k

	include "include/baremetal_cli.i"
	include "include/numerics.i"
	include "include/font.i"
	include "include/debug.i"

	section CODE,CODE_C

Mul_32:
	movem.l d1-a6,-(sp)

	move.w  d0,d3 ;; l1
	swap    d0    ;; h1

	move.w  d1,d2 ;; l2
	swap    d1    ;; h2

	mulu    d2,d0 ;; h1 * l2
	mulu    d3,d1 ;; h2 * l1
	mulu    d2,d3 ;; l2 * l1

	add.l   d1,d0  ;; h2 * l1 + h1 * l2
	swap    d0
	and.l   #$ffff0000,d0 ;; ^^^ << 16
	add.l   d3,d0  ;; ^^^ + l2 * l1

	movem.l (sp)+,d1-a6
	rts

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

Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer

	lea     (my_message),a1
	lea     (separators),a2
	moveq.l #0,d3  ;; line number.
	moveq.l #0,d5  ;; final score for part 1.
	moveq.l #0,d6  ;; final score for part 2.

.line_begin:
	move.l  #0,(.red_maximum)
	move.l  #0,(.green_maximum)
	move.l  #0,(.blue_maximum)

	jsr     String_split ;; keyword "Game"
	tst.b   d2
	beq     .end_of_file

	jsr     String_split ;; game number + ':' + ' '
	cmp.b   #' ',d2
	bne     .error
	addq.l  #1,d3
	
.scores:
	jsr     String_split  ;; count + ' '
	cmp.b   #' ',d2
	bne     .error

	jsr     Read_integer
	bvs     .error

	move.l  d0,d4
	jsr     String_split  ;; color + '\n' | ';' | ','
	cmp.l   #1,d1
	blt     .error

	cmp.b   #'r',(a0)
	beq     .red
	cmp.b   #'g',(a0)
	beq     .green
	cmp.b   #'b',(a0)
	beq     .blue
	bra     .error

.red:
	lea     (.red_maximum),a0
	bra     .score_end
.green:
	lea     (.green_maximum),a0
	bra     .score_end
.blue:
	lea     (.blue_maximum),a0
	bra     .score_end

.red_maximum:
	dc.l    0
.blue_maximum:
	dc.l    0
.green_maximum:
	dc.l    0

.score_end:
	cmp.l   (a0),d4
	ble     .no_substitute
	move.l  d4,(a0)
.no_substitute:
	cmp.b   #'\n',d2     ;; if we didn't split on newline, keep going
	beq     .line_end
	jsr     String_split ;; consume space after ',' | ';'
	bra     .scores

.line_end:
	move.l  (.red_maximum),d0
	move.l  (.green_maximum),d1
	jsr     Mul_32
	move.l  (.blue_maximum),d1
	jsr     Mul_32
	add.l   d0,d6

	cmp.l   #12,(.red_maximum)
	bgt     .line_begin

	cmp.l   #13,(.green_maximum)
	bgt     .line_begin

	cmp.l   #14,(.blue_maximum)
	bgt     .line_begin

	add.l   d3,d5
	bra     .line_begin

.error:
	move.l  #$deadbeef,a6
	jsr     Debug_rule
	jsr     Debug_break
	bra     .exit

.end_of_file:
	move.l  d5,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	move.l  d6,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

.exit:
	m_pause
	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C

separators:
	dc.b    " ,;\n",0
newline:
	dc.b    "\n",0

skip_line_message:
	dc.b    "skipped line\n",0

colon_string:
	dc.b    ":",0
comma_string:
	dc.b    ",",0
yes_string:
	dc.b    "yes\n",0
no_string:
	dc.b    "no\n",0

my_message:
	incbin  "input.txt"
	dc.b    0
part1_prompt:
	dc.b    "Part 1:\t",0
part2_prompt:
	dc.b    "Part 2:\t",0
