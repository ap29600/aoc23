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


Sort_3Longs:
	movem.l d0-d3/a0-a3,-(sp)

	move.l  a0,a2
	move.l  a0,a1

	move.l  d0,d2
	add.l   d0,d0
	add.l   d2,d0
	add.l   d0,d0
	add.l   d0,d0 ; size * 12

	add.l   d0,a2 ; end of array

	add.l   #12,a0 ; iterator

.elements_loop:
	cmp.l   a2,a0
	bhs     .done
	move.l  ( 0,a0),d0
	move.l  ( 4,a0),d1
	move.l  ( 8,a0),d2

	move.l  a0,a3

.positions_loop:
	sub.l   #12,a3
	cmp.l   a1,a3
	blo     .next_element
	cmp.l   (a3),d0
	bhs     .next_element

	move.l  ( 0,a3),(12,a3)
	move.l  ( 4,a3),(16,a3)
	move.l  ( 8,a3),(20,a3)

	bra     .positions_loop

.next_element:
	move.l  d0,(12,a3)
	move.l  d1,(16,a3)
	move.l  d2,(20,a3)

	add.l   #12,a0
	bra     .elements_loop

.done:
	movem.l (sp)+,d0-d3/a0-a3
	rts


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


Print_number_list:
	movem.l d0-a6,-(sp)
	tst.l   d1
.loop:
	ble     .done
	move.l  (a1)+,d0
	jsr     Put_unsigned
	lea     (comma_message),a0
	jsr     Put_string
	sub.l   #1,d1
	bra     .loop

.done:
	lea     (newline),a0
	jsr     Put_string
	movem.l (sp)+,d0-a6
	rts


Trim_whitespace:
.loop:
	move.b  (a0)+,d0
	beq     .exit
	cmp.b   #' ',d0
	beq     .loop
	cmp.b   #'\n',d0
	beq     .loop
	cmp.b   #'\t',d0
	beq     .loop
.exit:
	sub.l   #1,a0
	tst.b   d0
	rts


Print_3Longs_list:
	movem.l d0-a6,-(sp)
	tst.l   d1
.loop:
	ble     .done

	move.l  (a1)+,d0
	jsr     Put_unsigned
	lea     (comma_message),a0
	jsr     Put_string

	move.l  (a1)+,d0
	jsr     Put_unsigned
	lea     (comma_message),a0
	jsr     Put_string

	move.l  (a1)+,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	sub.l   #1,d1
	bra     .loop

.done:
	movem.l (sp)+,d0-a6
	rts


Binary_search_interval:
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
	lsr.l   d2    ;; mid

	move.l  d2,d3
	add.l   d3,d3
	add.l   d2,d3 ;; mid * 3
	add.l   d3,d3
	add.l   d3,d3 ;; mid * 12

	lea     (a1,d3),a0
	cmp.l   (a0),d4
	blo     .lower   ;; it < base[mid].begin
	bra     .higher  ;; it >= base[mid].begin

.lower:
	move.l  d2,d1 ;; high = mid
	bra     .binary_search_loop

.higher:
	move.l  d2,d0 ;; low = mid
	bra     .binary_search_loop

.exit
	move.l  d0,d3
	add.l   d3,d3
	add.l   d0,d3 ;; low * 3
	add.l   d3,d3
	add.l   d3,d3 ;; low * 12

	lea     (a1,d3),a0 ;; return address
	movem.l (sp)+,d0-d4
	rts


Apply_transformation_for_part_1:; (
;   a0: conditions base
;   d0: conditions count
;   a3: numbers base
;   d3: numbers count
; ) -> ()
	movem.l d0-a6,-(sp)

	move.l  a0,a1
	move.l  d0,d1

	sub.l   #4,a3
.values_loop:
	add.l   #4,a3
	sub.l   #1,d3
	blt     .done

	move.l  (a3),d0
	jsr     Binary_search_interval

	cmp.l   (a0),d0
	blo     .values_loop
	cmp.l   (4,a0),d0
	bhs     .values_loop
	add.l   (8,a0),d0
	move.l  d0,(a3)
	bra     .values_loop

.done:
	movem.l (sp)+,d0-a6
	rts


Parse_layer:; (
;   a1: stream
; ) -> (
;   a0: layer base
;   d0: layer count
; )
	movem.l d1/a2,-(sp)

	move.l  (bump_allocator_top),a2 ;; return value
	move.l  a1,a0

.loop:
	jsr     Trim_whitespace

	cmp.b   #'0',d0
	blt     .done
	cmp.b   #'9',d0
	bgt     .done

	jsr     Read_integer
	bvs     Error
	move.l  d0,(8,a2) ;; destination begin

	jsr     Trim_whitespace
	jsr     Read_integer
	bvs     Error
	move.l  d0,(0,a2) ;; source begin

	jsr     Trim_whitespace
	jsr     Read_integer
	bvs     Error
	move.l  d0,(4,a2) ;; range size

	move.l  (0,a2),d0
	sub.l   d0,(8,a2) ;; offset
	add.l   d0,(4,a2) ;; end

	move.l  (4,a2),d0
	tst.l   d0
	bne     .no_overflow_fix
	sub.l   #1,(4,a2)
.no_overflow_fix:

	add.w   #12,a2
	add.l   #1,d1
	;;  {begin, end, increment}

	bra     .loop

.done:
	move.l  a0,a1
	move.l  (bump_allocator_top),a0
	move.l  a2,(bump_allocator_top)
	move.l  d1,d0

	jsr     Sort_3Longs
	movem.l (sp)+,d1/a2
	rts


Evaluate_layer_for_part_1:; (
;   a1: stream
;   a3: numbers base
;   d3: numbers count
; ) -> (
;   a1: stream
; )
	movem.l d0-d7/a0/a2-a6,-(sp)
	jsr     Parse_layer
	jsr     Apply_transformation_for_part_1
	move.l  a0,(bump_allocator_top) ;; free the memory

.exit:
	movem.l (sp)+,d0-d7/a0/a2-a6
	rts


Apply_transformation_for_part_2:; (
;   a0: conditions base
;   d0: conditions count
;   a3: numbers base
;   d3: numbers count
; ) -> (
;   a2: new numbers base
;   d2: new numbers count
; )
	movem.l d0/d1/d3-d6/a0/a1/a3-a6,-(sp)

	move.l  a0,a1
	move.l  d0,d1

	move.l  (bump_allocator_top),a2 ;; output iterator
	move.l  #0,d2 ;; output count
	move.l  a2,a4 ;; conditions range guard

	sub.l   #8,a3
.values_loop:
	add.l   #8,a3
	sub.l   #1,d3
	blt     .done

	move.l  (a3),d0
	move.l  (4,a3),d5
	jsr     Binary_search_interval

.chunks_loop:
	cmp.l   a4,a0
	bhs     .emit_last_unmoved_chunk

	cmp.l   (a0),d0 ;; chunk start < interval mapping start
	bhs     .start_is_greater_or_equal

	;; emit a padding chunk
	cmp.l   (a0),d5
	;; if chunk end <= interval mapping start, this is the last sub-chunk
	bls     .emit_last_unmoved_chunk

	move.l  (a0),d4

	cmp.l   d0,d4
	bls     Error ;; don't emit zero-sized chunk

	add.l   #1,d2
	move.l  d0,(a2)+
	move.l  d4,(a2)+
	move.l  d4,d0 ;; advance start

.start_is_greater_or_equal:
	;; if chunk begin >= interval mapping end, try the next interval mapping
	cmp.l   (4,a0),d0
	bhs     .next_interval_mapping
	;; if chunk end <= interval mapping end, this is the last sub-chunk we'll emit
	cmp.l   (4,a0),d5
	bls     .emit_last_chunk_with_offset

	;; ASSUMED:
	;; interval mapping begin <= chunk begin < interval mapping end < chunk end
	move.l  (8,a0),d4 ;; offset
	
	add.l   #1,d2
	move.l  d0,(a2)
	add.l   d4,(a2)+
	move.l  (4,a0),d0 ;; chunk begin = interval mapping end
	move.l  d0,(a2)
	add.l   d4,(a2)+

	;; [fallthrough]
.next_interval_mapping:
	add.l   #12,a0
	bra     .chunks_loop

.emit_last_chunk_with_offset:
	add.l   (8,a0),d0
	add.l   (8,a0),d5
	;; [fallthrough]
.emit_last_unmoved_chunk:
	cmp.l   d0,d5
	bls     .values_loop

	add.l   #1,d2
	move.l  d0,(a2)+
	move.l  d5,(a2)+
	bra     .values_loop

.done:
	move.l  (bump_allocator_top),a3
	move.l  a2,(bump_allocator_top)
	move.l  a3,a2
	movem.l (sp)+,d0/d1/d3-d6/a0/a1/a3-a6
	rts


Evaluate_layer_for_part_2:; (
;   a1: stream
;   a3: numbers base
;   d3: numbers count
; ) -> (
;   a1: stream
; )
	movem.l d0-d2/d4-d7/a0/a2-a6,-(sp)
	jsr     Parse_layer

	jsr     Apply_transformation_for_part_2

	move.l  d2,d3 ;; new count
	move.l  a3,a0 ;; copy iterator
.copy_loop:
	sub.l   #1,d2
	blt     .exit
	move.l  (a2)+,(a0)+
	move.l  (a2)+,(a0)+
	bra     .copy_loop

.exit:
	move.l  a0,(bump_allocator_top) ;; deallocate unneeded memory
	movem.l (sp)+,d0-d2/d4-d7/a0/a2-a6
	rts


Range_minimum:
	move.l  a1,-(sp)

	add.l   d0,d0
	add.l   d0,d0 ;; d0 * 4
	move.l  a0,a1
	add.l   d0,a1 ;; end

	move.l  #$ffffffff,d0 ;; infinity
.loop:
	cmp.l   a1,a0
	beq     .done
	cmp.l   (a0),d0
	blo     .skip   ;; unsigned compare
	move.l  (a0),d0
.skip:
	add.w   #4,a0
	bra     .loop

.done:
	move.l  (sp)+,a1
	rts


Make_ranges:
	movem.l d0-a6,-(sp)
.loop:
	move.l  (a1),d0
	add.l   d0,(4,a1)
	add.l   #8,a1
	sub.l   #1,d1
	bhs     .loop

	movem.l (sp)+,d0-a6
	rts


Part_1:
	movem.l d0-a6,-(sp)
	move.l  a0,a1
	lea     (colon_separator_string),a2
	jsr     String_split ;; discard "seeds:"

	move.l  a1,a0
	jsr     Parse_number_list

	move.l  a1,a3
	move.l  d1,d3 ;; number list now in {a3,d3}

	move.l  a0,a1 ;; restore string pointer
.layers_loop:
	jsr     String_split ;; discard "<layer> map:"
	tst.b   d2
	beq     .done
	jsr     Evaluate_layer_for_part_1
	bra     .layers_loop

.done:
	move.l  a3,a0
	move.l  d3,d0
	jsr     Range_minimum
	jsr     Put_unsigned

	lea     (newline),a0
	jsr     Put_string

	movem.l (sp)+,d0-a6
	rts


Part_2:
	movem.l d0-a6,-(sp)
	move.l  a0,a1
	lea     (colon_separator_string),a2
	jsr     String_split ;; discard "seeds:"

	move.l  a1,a0
	jsr     Parse_number_list
	lsr.l   d1    ;; count / 2
	jsr     Make_ranges
	move.l  a1,a3
	move.l  d1,d3 ;; number list now in {a3,d3}

	move.l  a0,a1 ;; restore string pointer
.layers_loop:
	jsr     String_split ;; discard "<layer> map:"
	tst.b   d2
	beq     .done

	jsr     Evaluate_layer_for_part_2
	bra     .layers_loop

.done:

	move.l  a3,a0
	move.l  d3,d0
	jsr     Range_minimum
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
