; syntax M68k

	include "baremetal_cli.i"
	include "numerics.i"

	section CODE,CODE_C

Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer

	lea     (my_message),a0

	moveq.l  #0,d4  ;; third greatest
	moveq.l  #0,d5  ;; second greatest
	moveq.l  #0,d6  ;; greatest
	moveq.l  #0,d3
.new_number:
	jsr     Read_integer
	bvs     .end_elf
	add.l   d0,d3
	addq.l  #1,a0
	bra     .new_number

.end_elf:
	m_exlt  d3,d4
	bge     .swap_done
	m_exlt  d4,d5
	bge     .swap_done
	m_exlt  d5,d6
.swap_done:
	tst.b   (a0)+
	beq     .done
	move.l  #0,d3
	bra     .new_number

.done:
	lea     (part1_prompt),a0
	jsr     Put_string
	move.l  d6,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	lea     (part2_prompt),a0
	jsr     Put_string
	add.l   d4,d5
	add.l   d5,d6
	move.l  d6,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	m_pause

	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C
my_message:
	incbin  "input.txt"
	dc.b    0
newline:
	dc.b    "\n",0
	even
part1_prompt:
	dc.b    "Part 1:\t",0
part2_prompt:
	dc.b    "Part 2:\t",0
