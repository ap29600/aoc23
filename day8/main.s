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


Binary_search_node:
	movem.l d0-d4,-(sp)
	move.l  d0,d4   ;; needle
	move.l  #0,d0   ;; low
	                ;; d1 = high
.binary_search_loop:
	move.l  d1,d2
	sub.l   #1,d2
	cmp.l   d0,d2
	ble     .exit

	move.l  d0,d2
	add.l   d1,d2
	lsr.l   d2      ;; mid

	move.l  d2,d3
	lsl.l   #3,d3

	lea     (a1,d3),a0
	cmp.l   (a0),d4
	blo     .lower ;; it < base[mid]
;	[fallthrough]  ;; it >= base[mid]
	move.l  d2,d0 ;; low = mid
	bra     .binary_search_loop

.lower:
	move.l  d2,d1 ;; high = mid
	bra     .binary_search_loop

.exit
	lsl.l   #3,d0
	lea     (a1,d0),a0 ;; return address
	movem.l (sp)+,d0-d4
	rts


Traverse:
	movem.l d3/a0,-(sp)
	move.l  a1,a0 ;; initial node
	clr.l   d3    ;; counter
	clr.l   d4    ;; path index
.traversal_loop:
	cmp.w   #(25*26*26 + 25*26 + 25),(2,a0)
	beq     .done
	move.l  (4,a0),d0
	cmp.b   #'R',(a2,d4)
	beq     .turn_right
	swap    d0
.turn_right:
	and.l   #$0000ffff,d0
	jsr     Binary_search_node

;	movem.l d0-d6,-(sp)
;	move.l  (0,a0),d4
;	move.l  (4,a0),d5
;	jsr     Debug_break
;	movem.l (sp)+,d0-d6

	add.l   #1,d3
	add.l   #1,d4
	cmp.l   d2,d4
	blo     .traversal_loop
	clr.l   d4
	bra     .traversal_loop

.done:
	move.l  d3,d0
	movem.l (sp)+,d3/a0
	rts


Part_1:
	movem.l d0-a6,-(sp)
	lea     (newline),a2
	jsr     String_split
	move.l  a0,a4
	move.l  d0,d4 ;; {a4, d4} is the directions list

	move.l  (bump_allocator_top),a3

	add.l   #1,a1
.nodes_loop:
	jsr     String_split
	tst.b   d2
	beq     .done_parsing_graph

	clr.l   d3
	;; source
	clr.l   d0
	move.b  (0,a0),d0
	sub.l   #'A',d0
	mulu    #26,d0
	move.b  (1,a0),d3
	add.l   d3,d0
	sub.l   #'A',d0
	mulu    #26,d0
	move.b  (2,a0),d3
	add.l   d3,d0
	sub.l   #'A',d0

	;; left
	clr.l   d1
	move.b  (7,a0),d1
	sub.l   #'A',d1
	mulu    #26,d1
	move.b  (8,a0),d3
	add.l   d3,d1
	sub.l   #'A',d1
	mulu    #26,d1
	move.b  (9,a0),d3
	add.l   d3,d1
	sub.l   #'A',d1
	
	;; right
	clr.l   d2
	move.b  (12,a0),d2
	sub.l   #'A',d2
	mulu    #26,d2
	move.b  (13,a0),d3
	add.l   d3,d2
	sub.l   #'A',d2
	mulu    #26,d2
	move.b  (14,a0),d3
	add.l   d3,d2
	sub.l   #'A',d2
	
	move.l  d0,(a3)+
	swap    d1
	or.l    d2,d1   ;; [left|right]
	move.l  d1,(a3)+
	bra     .nodes_loop

.done_parsing_graph:
	move.l  (bump_allocator_top),a0
	move.l  a3,(bump_allocator_top)

	move.l  a3,d0
	sub.l   a0,d0
	lsr.l   #3,d0 ;; length
	
	jsr     Sort_64

	move.l  a0,a1 ;; graph
	move.l  d0,d1

	move.l  a4,a2 ;; path
	move.l  d4,d2
	jsr     Traverse
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	move.l  a1,(bump_allocator_top)
	movem.l (sp)+,d0-a6
	rts


Part_2:
	movem.l d0-a6,-(sp)
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
