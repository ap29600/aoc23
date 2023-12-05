; syntax M68k

	include "include/baremetal_cli.i"
	include "include/string.i"
	include "include/numerics.i"
	include "include/font.i"
	include "include/debug.i"

	section CODE,CODE_C

Matrix_size:
	movem.l d3-a6,-(sp)
	;; total string length
	jsr     String_len
	move.l  d0,d3

	;; line length
	move.l  a0,a1
	lea     (newline),a2
	jsr     String_split
	move.l  d0,d1


	move.l  d3,d0
	;; line count
	add.l   #1,d1
	divu    d1,d0
	cmp.l   #$ffff,d0
	bgt     .error

	move.l  d3,d2
.exit:
	movem.l (sp)+,d3-a6
	rts

.error:
	move.l  #$deadbeef,a5
	jsr     Debug_rule
	jsr     Debug_break
	jmp     .exit

Offset_to_indices:; (
;     a0: position
;     a1: base
; ) -> (
;     d0: row
;     d1: col
; )
	move.l  a0,d0
	sub.l   a1,d0
	divu    (cols+2),d0
	move.l  d0,d1
	swap    d1
	and.l   #$ffff,d0
	and.l   #$ffff,d1
	rts

Check_symbol_and_assign_gear:
	movem.l d1/a0,-(sp)

	move.b  (a0),d0
	cmp.b   #'.',d0
	beq     .not_symbol
	cmp.b   #'\n',d0
	beq     .not_symbol
	cmp.b   #'*',d0
	beq     .gear
	cmp.b   #'0',d0
	blt     .symbol
	cmp.b   #'9',d0
	bgt     .symbol
	
.not_symbol:
	clr.b   d0
	movem.l (sp)+,d1/a0
	rts

.gear:
	jsr     Binary_search_gears
	beq     .error ;; assert that we should find the gear
	move.l  (4,a0),d0
	cmp.l   #2,d0
	bge     .overfull
	mulu    #4,d0
	move.l  d3,(8,a0,d0.w) ;; insert
.overfull:
	add.l   #1,(4,a0)
;;  [fallthrough]
.symbol:
	move.b  #1,d0
	movem.l (sp)+,d1/a0
	rts

.error:
	move.l  #$deadbeef,a5
	jsr     Debug_rule
	jsr     Debug_break
	movem.l (sp)+,d1-a6
	rts

Scan_perimeter_and_assign_gears:;(
;   a1:     base
;   d0:     row
;   d1:     start col
;   d2:     end   col
;   d3:     number value
; ) -> (
;   d0:     symbol found?
; )
	movem.l d1-d5/a0/a1,-(sp)

	sub.l   #1,d1 ;; widen left
	sub.l   d1,d2 ;; set count

	;; prepare base address
	move.l  d0,d5
	move.l  (cols),d4
	mulu    d4,d0
	add.l   d1,d0
	add.l   d0,a1
	clr.l   d4 ;; return value

;;  left side
	move.l  a1,a0
	jsr     Check_symbol_and_assign_gear
	or.b    d0,d4

;;  right side
	lea     (a1,d2),a0
	jsr     Check_symbol_and_assign_gear
	or.b    d0,d4

	tst.l   d5
	beq     .below
	sub.l   (cols),a1

;;  check row above
	moveq.l #0,d1
.above_loop:
	lea     (a1,d1.w),a0
	jsr     Check_symbol_and_assign_gear
	or.b    d0,d4

	add.l   #1,d1
	cmp.l   d2,d1
	ble     .above_loop

	add.l   (cols),a1
	add.l   #1,d5
	cmp.l   (rows),d5
	bge     .exit

;;  check row below
.below:
	add.l   (cols),a1

	move.l  #0,d1
.below_loop:
	lea     (a1,d1.w),a0
	jsr     Check_symbol_and_assign_gear
	or.b    d0,d4

	add.l   #1,d1
	cmp.l   d2,d1
	ble     .below_loop

.exit:
	move.l  d4,d0
	movem.l (sp)+,d1-d5/a0/a1
	rts

Sum_gear_ratios:
	movem.l d1-a6,-(sp)
	move.l  (bump_allocator_base),a0
	move.l  a0,a1
	add.l   (bump_allocator_size),a1
	clr.l   d0

.loop:
	cmp.l   a1,a0
	bge     .exit
	cmp.l   #2,(4,a0)
	bne     .loop_next

	move.l  (8,a0),d1
	move.l  (12,a0),d2
	mulu    d1,d2
	add.l   d2,d0
.loop_next:
	add.l   #(4*Long),a0
	bra     .loop

.exit:
	movem.l (sp)+,d1-a6
	rts

Solve:
	movem.l d0-a6,-(sp)

	jsr     Matrix_size
	move.l  d0,(rows)
	move.l  d1,(cols)

	move.l  a0,a1
	move.l  #0,d0
.find_gears:
	move.b  (a0),d1
	tst.b   d1
	beq     .done_counting
	cmp.b   #'*',d1
	bne     .skip

	move.l  (bump_allocator_base),a2
	add.l   (bump_allocator_size),a2
	add.l   #(4 * Long),(bump_allocator_size) ;; {position, count, N1, N2}
	moveq.l #0,d0
	move.l  a0,(a2)+ ;; position
	move.l  d0,(a2)+ ;; count
	move.l  d0,(a2)+ ;; N1 = 0
	move.l  d0,(a2)+ ;; N2 = 0

.skip:
	add.l   #1,a0
	add.l   #1,d0
	bra     .find_gears

.done_counting:

	move.l  a1,a0
	clr.l   d5 ;; sum of part numbers

.positions_loop:
	move.b  (a0),d0
	tst.b   d0
	beq     .exit
	sub.b   #'0',d0
	blt     .next_position
	cmp.b   #10,d0
	bge     .next_position

	jsr     Offset_to_indices
	move.w  d0,(.row)
	move.w  d1,(.start_col)

	jsr     Read_integer
	bvs     .error
	move.l  d0,(.part_number)
	
	jsr     Offset_to_indices
	cmp.w   (.row),d0
	bne     .error ;; we should still be on the same row.
	move.w  d1,(.end_col)

	move.w  (.row),d0
	move.w  (.start_col),d1
	move.w  (.end_col),d2
	move.l  (.part_number),d3

	;; a1 = base
	jsr     Scan_perimeter_and_assign_gears
	beq     .next_position

	add.l   (.part_number),d5

.next_position:
	add.l   #1,a0
	bra     .positions_loop

.part_number:
	dc.l    0
.row:
	dc.w    0
.start_col:
	dc.w    0
.end_col:
	dc.w    0

.exit:

	move.l  d5,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	jsr     Sum_gear_ratios
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	movem.l (sp)+,d0-a6
	rts

.error:
	move.l  #$deadbeef,a5
	jsr     Debug_rule
	jsr     Debug_break
	jmp     .exit


Binary_search_gears:
;; a0: gear position -> ?a0: gear structure
	movem.l d0/d1/a1/a2,-(sp)
	move.l  a0,d0
	move.l  (bump_allocator_base),a0
	move.l  a0,a1
	add.l   (bump_allocator_size),a1

	;; a0 = low
	;; a1 = high
.loop:
	cmp.l   a1,a0
	bge     .not_found

	move.l  a1,d1
	add.l   a0,d1

	lsr.l   #5,d1
	lsl.l   #4,d1

	move.l  d1,a2
	move.l  (a2),d1

	cmp.l   d1,d0
	beq     .found
	bgt     .greater
;   [[fallthrough]]   .smaller

.smaller:
	move.l  a2,a1 ;; hi = mid
	bra     .loop

.greater:
	move.l  a2,a0
	add.l   #(4 * Long),a0 ;; lo = mid + 1
	bra     .loop

.found:
	move.l  a2,a0
.exit:
	cmp.l   #0,a0
	movem.l (sp)+,d0/d1/a1/a2
	rts

.not_found:
	move.l  #0,a0
	bra     .exit


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
	move.l  d0,(bump_allocator_base)

	lea     (my_message),a0
	jsr     Tick
	jsr     Solve
	jsr     Tock

	m_pause

	movem.l (sp)+,d0-a6
	rts

.error:
	move.l  #$deadbeef,a5
	jsr     Debug_rule
	jsr     Debug_break
	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C

newline:
	dc.b    "\n",0
colon_message:
	dc.b    ": ",0
comma_message:
	dc.b    ", ",0

	;; required for parsing the input
	dc.b    "\n"
my_message:
	incbin  "input.txt"
	dc.b    0

	section BSS,BSS_C
rows:
	dcb.l   1
cols:
	dcb.l   1
bump_allocator_size:
	dcb.l   1
bump_allocator_base:
	dcb.l   1
bump_allocator_mem:
	dcb.b   400 * KiB
