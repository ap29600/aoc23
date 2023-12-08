; syntax M68k

	include "include/baremetal_cli.i"
	include "include/string.i"
	include "include/numerics.i"
	include "include/font.i"
	include "include/debug.i"

	section CODE,CODE_C

	macro   m_make_error
\1:
	move.l  a0,-(sp)
	lea     (.\@_message),a0
	jsr     Put_string
	move.l  (sp)+,a0
	jsr     Debug_break
	trap    #0
.\@_message:
	dc.b    \2,0
	even
	endm


	m_make_error Error,         "TRAP:\n"
	m_make_error Unimplemented, "TRAP: unimplemented code reached\n"
	m_make_error Invalid_Char,  "TRAP: invalid character\n"
	m_make_error Invalid_Digit, "TRAP: invalid digit\n"


	macro m_max_exg_b
	cmp.b   \2,\1
	bls     .\@_no_exg
	move.b  \1,-(sp)
	move.b  \2,\1
	move.b  (sp)+,\2
.\@_no_exg:
	endm


Char_to_nibble:
	cmp.b   #'9',d0
	bls     .digit
	cmp.b   #'A',d0
	beq     .A
	cmp.b   #'K',d0
	beq     .K
	cmp.b   #'Q',d0
	beq     .Q
	cmp.b   #'J',d0
	beq     .J
	cmp.b   #'T',d0
	beq     .T
	bra     Invalid_Char

.A: move.b  #12,d0
	rts
.K: move.b  #11,d0
	rts
.Q: move.b  #10,d0
	rts
.J: move.b  #9,d0
	rts
.T: move.b  #8,d0
	rts

.digit:
	sub.b   #'2',d0
	blo     Invalid_Digit
	rts


Char_to_nibble_with_jokers:
	cmp.b   #'9',d0
	bls     .digit
	cmp.b   #'A',d0
	beq     .A
	cmp.b   #'K',d0
	beq     .K
	cmp.b   #'Q',d0
	beq     .Q
	cmp.b   #'J',d0
	beq     .J
	cmp.b   #'T',d0
	beq     .T
	bra     Invalid_Char

.A: move.b  #12,d0
	rts
.K: move.b  #11,d0
	rts
.Q: move.b  #10,d0
	rts
.J: move.b  #0,d0
	rts
.T: move.b  #9,d0
	rts

.digit:
	sub.b   #'2',d0
	blo     Invalid_Digit
	add.b   #1,d0
	rts


Calculate_hand_type:
	movem.l d1-d3/a0,-(sp)

	lea     (.locals),a0
	move.l  #0,( 0,a0) ;; reset counters
	move.l  #0,( 4,a0)
	move.l  #0,( 8,a0)
	move.l  #0,(12,a0)

	move.l  d0,d1
	move.b  #5,d3
	clr.l   d2
.nibbles_loop:
	move.b  d1,d2
	and.b   #$f,d2
	add.b   #1,(a0,d2.w)
	lsr.l   #4,d1 ;; next nibble
	sub.b   #1,d3
	bne     .nibbles_loop

	move.w  #13,d3
.counts_loop:
	move.b  (-1,a0,d3),d1
	m_max_exg_b d1,(.best - .locals,a0)
	m_max_exg_b d1,(.second_best - .locals,a0)
	sub.b   #1,d3
	bne     .counts_loop

	cmp.b   #5,(.best - .locals,a0)
	beq     .five_of_a_kind
	cmp.b   #4,(.best - .locals,a0)
	beq     .four_of_a_kind
	cmp.b   #3,(.best - .locals,a0)
	beq     .full_house_or_three_of_a_kind
	cmp.b   #2,(.best - .locals,a0)
	beq     .two_pairs_or_one_pair
	bra     .high_card

.full_house_or_three_of_a_kind:
	cmp.b   #2,(.second_best - .locals,a0)
	beq     .full_house
	bra     .three_of_a_kind

.two_pairs_or_one_pair:
	cmp.b   #2,(.second_best - .locals,a0)
	beq     .two_pairs
	bra     .one_pair

.high_card:
	or.l    #0<<20,d0
	bra     .exit
.one_pair:
	or.l    #1<<20,d0
	bra     .exit
.two_pairs:
	or.l    #2<<20,d0
	bra     .exit
.three_of_a_kind:
	or.l    #3<<20,d0
	bra     .exit
.full_house:
	or.l    #4<<20,d0
	bra     .exit
.four_of_a_kind:
	or.l    #5<<20,d0
	bra     .exit
.five_of_a_kind:
	or.l    #6<<20,d0
	bra     .exit
.exit:
	movem.l (sp)+,d1-d3/a0
	rts
.locals:
.symbol_counts:
	dcb.b   13
.best:
	dc.b    0
.second_best:
	dc.b    0
	dc.b    0
	even


Calculate_hand_type_with_jokers:
	movem.l d1-d3/a0,-(sp)

	lea     (.locals),a0
	move.l  #0,( 0,a0) ;; reset counters
	move.l  #0,( 4,a0)
	move.l  #0,( 8,a0)
	move.l  #0,(12,a0)

	move.l  d0,d1
	move.b  #5,d3
	clr.l   d2
.nibbles_loop:
	move.b  d1,d2
	and.b   #$f,d2
	add.b   #1,(a0,d2.w)
	lsr.l   #4,d1 ;; next nibble
	sub.b   #1,d3
	bne     .nibbles_loop

	move.w  #12,d3
.counts_loop:
	move.b  (a0,d3),d1
	m_max_exg_b d1,(.best - .locals,a0)
	m_max_exg_b d1,(.second_best - .locals,a0)
	sub.b   #1,d3
	bne     .counts_loop

	;; it is always advantageous to use the joker
	;; as the most common card in your hand
	move.b  (a0),d1
	add.b   d1,(.best - .locals,a0)

	cmp.b   #5,(.best - .locals,a0)
	beq     .five_of_a_kind
	cmp.b   #4,(.best - .locals,a0)
	beq     .four_of_a_kind
	cmp.b   #3,(.best - .locals,a0)
	beq     .full_house_or_three_of_a_kind
	cmp.b   #2,(.best - .locals,a0)
	beq     .two_pairs_or_one_pair
	bra     .high_card

.full_house_or_three_of_a_kind:
	cmp.b   #2,(.second_best - .locals,a0)
	beq     .full_house
	bra     .three_of_a_kind

.two_pairs_or_one_pair:
	cmp.b   #2,(.second_best - .locals,a0)
	beq     .two_pairs
	bra     .one_pair

.high_card:
	or.l    #0<<20,d0
	bra     .exit
.one_pair:
	or.l    #1<<20,d0
	bra     .exit
.two_pairs:
	or.l    #2<<20,d0
	bra     .exit
.three_of_a_kind:
	or.l    #3<<20,d0
	bra     .exit
.full_house:
	or.l    #4<<20,d0
	bra     .exit
.four_of_a_kind:
	or.l    #5<<20,d0
	bra     .exit
.five_of_a_kind:
	or.l    #6<<20,d0
	bra     .exit
.exit:
	movem.l (sp)+,d1-d3/a0
	rts
.locals:
.symbol_counts:
	dcb.b   13
.best:
	dc.b    0
.second_best:
	dc.b    0
	dc.b    0
	even


Sort_64:
	movem.l d0-d1/a0-a3,-(sp)

	move.l  a0,a2
	move.l  a0,a1
	lsl.l   #3,d0 ; size * 8
	add.l   d0,a2 ; end of array
	add.l   #8,a0 ; iterator

.elements_loop:
	cmp.l   a2,a0
	bhs     .done
	move.l  ( 0,a0),d0
	move.l  ( 4,a0),d1
	move.l  a0,a3
.positions_loop:
	sub.l   #8,a3
	cmp.l   a1,a3
	blo     .next_element
	cmp.l   (a3),d0
	bhs     .next_element
	move.l  ( 0,a3),( 8,a3)
	move.l  ( 4,a3),(12,a3)
	bra     .positions_loop

.next_element:
	move.l  d0,( 8,a3)
	move.l  d1,(12,a3)
	add.l   #8,a0
	bra     .elements_loop

.done:
	movem.l (sp)+,d0-d1/a0-a3
	rts


Print_list_64:
	movem.l d0-a6,-(sp)
	move.l  a0,a1
	move.l  d0,d1
	jsr     Debug_break
.loop:
	tst.l   d1
	beq     .exit
	move.l  (a1)+,d0
	jsr     Put_hexadecimal
	lea     (comma_message),a0
	jsr     Put_string
	move.l  (a1)+,d0
	jsr     Put_hexadecimal
	lea     (newline),a0
	jsr     Put_string
	sub.l   #1,d1
	bra     .loop

.exit:
	movem.l (sp)+,d0-a6
	rts


Part_1:
	movem.l d0-a6,-(sp)
	lea     (newline),a2
	move.l  (bump_allocator_top),a3

.lines_loop:
	jsr     String_split
	tst.b   d2
	beq     .done_parsing_input
	clr.l   d0
	clr.l   d1
	move.b  #5,d2
.chars_loop:
	move.b  (a0)+,d0
	jsr     Char_to_nibble
	lsl.l   #4,d1
	add.l   d0,d1 ; add encoded nibble
	sub.b   #1,d2
	bhi     .chars_loop

	move.l  d1,d0
	jsr     Calculate_hand_type
	move.l  d0,d1

	add.w   #1,a0
	jsr     Read_integer

	move.l  d1,(a3)+
	move.l  d0,(a3)+
	bra     .lines_loop

.done_parsing_input:

	move.l  a3,d0
	move.l  (bump_allocator_top),a3
	move.l  a3,a0

	move.l  d0,(bump_allocator_top)
	sub.l   a3,d0
	lsr.l   #3,d0 ;; length

	jsr     Sort_64
;	jsr     Print_list_64

	clr.l   d3    ;; total
	moveq.l #1,d1 ;; rank

.sum_scores_loop:
	add.l   #4,a0
	move.l  (a0)+,d2
	mulu    d1,d2
	add.l   d2,d3

	add.l   #1,d1
	sub.l   #1,d0
	bne     .sum_scores_loop

	move.l  d3,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

.exit:
	move.l  a3,(bump_allocator_top)
	movem.l (sp)+,d0-a6
	rts


Part_2:
	movem.l d0-a6,-(sp)
	lea     (newline),a2
	move.l  (bump_allocator_top),a3

.lines_loop:
	jsr     String_split
	tst.b   d2
	beq     .done_parsing_input
	clr.l   d0
	clr.l   d1
	move.b  #5,d2
.chars_loop:
	move.b  (a0)+,d0
	jsr     Char_to_nibble_with_jokers
	lsl.l   #4,d1
	add.l   d0,d1 ; add encoded nibble
	sub.b   #1,d2
	bhi     .chars_loop

	move.l  d1,d0
	jsr     Calculate_hand_type_with_jokers
	move.l  d0,d1

	add.w   #1,a0
	jsr     Read_integer

	move.l  d1,(a3)+
	move.l  d0,(a3)+
	bra     .lines_loop

.done_parsing_input:

	move.l  a3,d0
	move.l  (bump_allocator_top),a3
	move.l  a3,a0

	move.l  d0,(bump_allocator_top)
	sub.l   a3,d0
	lsr.l   #3,d0 ;; length

	jsr     Sort_64
;	jsr     Print_list_64

	clr.l   d3    ;; total
	moveq.l #1,d1 ;; rank

.sum_scores_loop:
	add.l   #4,a0
	move.l  (a0)+,d2
	mulu    d1,d2
	add.l   d2,d3

	add.l   #1,d1
	sub.l   #1,d0
	bne     .sum_scores_loop

	move.l  d3,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

.exit:
	move.l  a3,(bump_allocator_top)
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

	lea     (my_message),a1
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
