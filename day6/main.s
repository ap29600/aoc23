; syntax M68k

	include "include/baremetal_cli.i"
	include "include/string.i"
	include "include/numerics.i"
	include "include/font.i"
	include "include/debug.i"

	section CODE,CODE_C

Error:
	move.l  #$deadbeef,a5
	jsr     Debug_rule
	jsr     Debug_break
	trap    #0


Parse_number_list:
	move.l  (bump_allocator_top),a1
	clr.l   d1

.skip_whitespace:
	cmp.b   #' ',(a0)+
	bne     .parse_number
	bra     .skip_whitespace

.parse_number:
	sub.l   #1,a0 ;; overparse
	jsr     Read_integer
	bvs     .end_of_list
	move.l  d0,(a1,d1)
	add.l   #4,d1
	bra     .skip_whitespace

.end_of_list:
	add.l   d1,(bump_allocator_top) ;; commit memory
	lsr.l   #2,d1 ;; count = size / 4
	rts


Sqrt_64_to_32:
	movem.l d1-d6,-(sp)

	move.l  d0,d4
	move.l  d1,d5
	move.l  #1<<31,d2

	clr.l   d6
.loop:
	move.l  d6,d0
	add.l   d2,d0
	move.l  d0,d1
	jsr     Mul_32_to_64

	cmp.l   d5,d1
	bhi     .skip
	blo     .no_skip
	cmp.l   d4,d0
	bhi     .skip
	beq     .done
.no_skip:
	add.l   d2,d6
.skip:
	lsr.l   d2
	bne     .loop

.done:
	move.l  d6,d0
	movem.l (sp)+,d1-d6
	rts


; count evens in: [T - floor_sqrt((2T)^2 - 16z), T + floor_sqrt((2T)^2 - 16z)]
Race_accuracy_64:
	movem.l d1-d5,-(sp)

	tst.l   d1
	bne     Error ;; assert: the square will not overflow

	moveq.l #1,d4
	moveq.l #0,d5
	add.l   d4,d2 ;; z low
	addx.l  d5,d3 ;; z high
	add.l   d2,d2
	addx.l  d3,d3
	add.l   d2,d2 ;; 4z low
	addx.l  d3,d3 ;; 4z high

	move.l  d0,d1
	move.l  d0,d4 ;; T
	jsr     Mul_32_to_64 ;; T^2

	sub.l   d2,d0
	subx.l  d3,d1 ;; T^2 - 4z

	jsr     Sqrt_64_to_32 ;; sqrt(T^2 - 4z)

	move.l  d0,d1
	neg.l   d1

	add.l   d4,d0 ;; T + sqrt(...)
	add.l   d4,d1 ;; T - sqrt(...)

	;; count the even values included between d0 and d1:
	lsr.l   d0 ;; floor(d0 / 2)

	neg.l   d1
	asr.l   d1
	neg.l   d1 ;; ceil(d1 / 2)

	sub.l   d1,d0
	add.l   #1,d0

	movem.l (sp)+,d1-d5
	rts


Part_1:
	movem.l d0-a6,-(sp)
	move.l  a0,a1
	lea     (colon_separator_string),a2
	jsr     String_split ;; discard "Time:"

	move.l  a1,a0
	jsr     Parse_number_list
	move.l  a1,a3
	move.l  d1,d5

	move.l  a0,a1
	jsr     String_split ;; discard "Distance:"

	move.l  a1,a0
	jsr     Parse_number_list

	moveq.l #1,d4
.loop:
	sub.l   #1,d5
	blo     .done

	move.l  (a3)+,d0 ;; T
	clr.l   d1
	move.l  (a1)+,d2 ;; z - 1
	clr.l   d3

	jsr     Race_accuracy_64

	move.l  d4,d1
	jsr     Mul_32
	move.l  d0,d4
	bra     .loop

.done:

	jsr     Put_unsigned
	lea     (newline),a0
	jsr     Put_string

	movem.l (sp)+,d0-a6
	rts


Mul10_64:
	movem.l d2/d3,-(sp)

	add.l   d0,d0
	addx.l  d1,d1
	;; {d1|d0} = x * 2

	move.l  d0,d2
	move.l  d1,d3
	;; {d2|d3} = x * 2

	add.l   d0,d0
	addx.l  d1,d1
	add.l   d0,d0
	addx.l  d1,d1
	;; {d1|d0} = x * 8

	add.l   d2,d0
	addx.l  d3,d1
	;; {d1|d0} = x * 10

	movem.l (sp)+,d2/d3
	rts


Mul_32_to_64:
	movem.l d2-d4,-(sp)

	move.l  d0,d2 ;; {A,B}
	move.l  d1,d3
	move.l  d1,d4 ;; {C,D}

	mulu    d0,d1 ;; {B*D}
	swap    d0
	mulu    d0,d3 ;; {A*D}
	swap    d4
	mulu    d4,d0 ;; {A*C}
	mulu    d4,d2 ;; {C*B}

	exg     d0,d1 ;; d1 has the high bits

	swap    d3
	move.l  d3,d4
	and.l   #$ffff0000,d3
	and.l   #$0000ffff,d4
	add.l   d3,d0
	addx.l  d4,d1

	swap    d2
	move.l  d2,d4
	and.l   #$ffff0000,d2
	and.l   #$0000ffff,d4
	add.l   d2,d0
	addx.l  d4,d1

	movem.l (sp)+,d2-d4
	rts


Parse_line_as_number:
	movem.l d2/d3,-(sp)
	clr.l   d0
	clr.l   d1
	clr.l   d2
	clr.l   d3
.digits_loop:
	move.b  (a1)+,d2
	beq     .done
	cmp.b   #'\n',d2
	beq     .done
	cmp.b   #' ',d2
	beq     .digits_loop
	sub.b   #'0',d2
	blo     Error
	cmp.b   10,d2
	bhi     Error
	jsr     Mul10_64
	add.l   d2,d0
	addx.l  d3,d1

	bra     .digits_loop

.done:
	movem.l (sp)+,d2/d3
	rts


Part_2:
	movem.l d0-a6,-(sp)
	move.l  a0,a1
	lea     (colon_separator_string),a2
	jsr     String_split ;; discard "Time:"

	jsr     Parse_line_as_number
	move.l  d0,d4
	move.l  d1,d5

	jsr     String_split ;; discard "Distance:"
	jsr     Parse_line_as_number

	move.l  d0,d2
	move.l  d1,d3
	move.l  d4,d0
	move.l  d5,d1
	jsr     Race_accuracy_64

	jsr     Put_unsigned
	lea     (newline),a0
	jsr     Put_string
	
	movem.l (sp)+,d0-a6
	rts


Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer

	;; set up allocator with an aligned address
	lea     bump_allocator_mem,a0
	move.l  a0,d0
	add.l   #$100,d0
	and.l   #~$ff,d0
	move.l  d0,(bump_allocator_top)

	lea     (my_message),a0
	jsr     Tick
	jsr     Part_1
	jsr     Part_2
	jsr     Tock

	m_pause

	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C

newline:
	dc.b    "\n",0
colon_message:
	dc.b    ": ",0
comma_message:
	dc.b    ", ",0
space_message:
	dc.b    " ",0
colon_separator_string:
	dc.b    ":",0

my_message:
	incbin  "input.txt"
	dc.b    0

	section BSS,BSS_C
bump_allocator_base:
	dcb.l   1
bump_allocator_top:
	dcb.l   1
bump_allocator_mem:
	dcb.b   400 * KiB
