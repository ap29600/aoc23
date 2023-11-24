; syntax M68k

	include "baremetal_cli.i"
	section CODE,CODE_C

	macro mul10
	move.l \1,\2
	add.l  \2,\2
	add.l  \2,\2
	add.l  \1,\2
	add.l  \2,\2
	endm

Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer

	lea     (my_message),a0

	moveq.l #0,d4 ;; max so far
	moveq.l #0,d3
.new_elf:
	cmp.l   d4,d3
	blt     .skip
	move.l  d3,d4
	moveq.l #0,d3
.skip:
	moveq.l #0,d3
	cmp.b   #0,(a0)
	beq     .exit
.new_value:
	jsr     Read_integer
	add.l   d0,d3
	add.l   #1,a0
	cmp.b   #0,(a0)
	beq     .new_elf
	cmp.b   #10,(a0)
	beq     .new_elf
	bra     .new_value

.exit:
	move.l  d4,d0
	jsr     Put_hexadecimal

.loop2:
	btst    #6,$BFE001
	bne     .loop2
	movem.l (sp)+,d0-a6
	rts

Read_integer:
	moveq.l #0,d0
.next_digit
	move.b  (a0)+,d1
	sub.b   #48,d1
	blt     .exit
	cmp.b   #10,d1
	bge     .exit
	and.l   #$ff,d1
	mul10   d0,d2
	exg     d0,d2
	add.l   d1,d0
	bra     .next_digit
.exit:
	sub.l   #1,a0
	rts

	section DATA,DATA_C
my_message:
	incbin  "input.txt"
	dc.b    0
newline:
	dc.b    "\n",0
	even
