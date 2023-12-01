; syntax M68k

	include "baremetal_cli.i"
	include "numerics.i"

	section CODE,CODE_C

Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer

	lea     (puzzle_input),a0
	lea     (part1_matrix),a3
	lea     (part2_matrix),a4
	clr.l   d3
	clr.l   d4
	
.loop:
	clr.l   d0
	clr.l   d1
	clr.w   d2
	move.b  0(a0),d0
	beq     .done
	move.b  2(a0),d1
	add.l   #4,a0

	sub.b   #'A',d0
	move.b  d0,d2
	add.b   d2,d2
	add.b   d0,d2
	sub.b   #'X',d1
	add.b   d1,d2
	
	move.b  (a3,d2.w),d0
	and.l   #$ff,d0
	add.l   d0,d3

	move.b  (a4,d2.w),d0
	and.l   #$ff,d0
	add.l   d0,d4

	bra     .loop
.done:

	lea     (part1_prompt),a0
	jsr     Put_string
	move.l  d3,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	lea     (part2_prompt),a0
	jsr     Put_string
	move.l  d4,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string
	m_pause

	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C
part1_matrix:
	dc.b    3+1,6+2,0+3
	dc.b    0+1,3+2,6+3
	dc.b    6+1,0+2,3+3

part2_matrix:
	dc.b    0+3,3+1,6+2
	dc.b    0+1,3+2,6+3
	dc.b    0+2,3+3,6+1
	even

puzzle_input:
	incbin  "input.txt"
	dc.b    0
newline:
	dc.b    "\n",0
	even
part1_prompt:
	dc.b    "Part 1:\t",0
part2_prompt:
	dc.b    "Part 2:\t",0
	even
