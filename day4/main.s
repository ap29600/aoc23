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


Sort_bytes:
	movem.l d0-d2/a0-a3,-(sp)

	move.l  a1,a2
	add.l   d1,a2 ; guard

	move.l  a1,a0
	add.l   #1,a0 ; iterator

.elements_loop:
	cmp.l   a2,a0
	bge     .done
	move.b  (a0),d0
	move.l  a0,a3

.positions_loop:
	sub.l   #1,a3
	cmp.l   a1,a3
	blt     .next_element
	cmp.b   (a3),d0
	bge     .next_element
	move.b  (a3),(1,a3)
	bra     .positions_loop

.next_element:
	move.b  d0,(1,a3)
	add.l   #1,a0
	bra     .elements_loop

.done:
	movem.l (sp)+,d0-d2/a0-a3
	rts


Parse_number_list:
	move.l  (bump_allocator_base),a1
	add.l   (bump_allocator_size),a1
	clr.l   d1

.skip_whitespace:
	cmp.b   #' ',(a0)+
	bne     .parse_number
	bra     .skip_whitespace

.parse_number:
	sub.l   #1,a0 ;; overparse
	jsr     Read_integer
	bvs     .end_of_list
	move.b  d0,(a1,d1)
	add.l   #1,d1
	bra     .skip_whitespace

.end_of_list:
	add.l   d1,(bump_allocator_size) ;; commit memory
	rts


Intersection_count:
	movem.l d1-d4/a1-a2,-(sp)
	jsr     Sort_bytes ;; sort first set

	exg     a1,a2
	exg     d1,d2
	jsr     Sort_bytes ;; sort second set
	
	clr.l   d0
.compare_loop:
	tst.l   d1
	beq     .done ;; left set empty
	tst.l   d2
	beq     .done ;; right set empty

	move.b  (-1,a1,d1),d3
	move.b  (-1,a2,d2),d4

	cmp.b   d4,d3 ;; a1[end] <=> a2[end]
	blt     .remove_right
	bgt     .remove_left
;;  [fallthrough]
;;  element is in the intersection
	add.l   #1,d0
	sub.l   #1,d1
	sub.l   #1,d2
	bra     .compare_loop

.remove_left:
	sub.l   #1,d1
	bra     .compare_loop

.remove_right:
	sub.l   #1,d2
	bra     .compare_loop

.done:
	movem.l (sp)+,d1-d4/a1-a2
	rts


Process_line:
	movem.l d1-d3/a1/a2,-(sp)
	move.l  (bump_allocator_size),d3 ;; save allocator size

.wait_for_colon:
	move.b  (a0)+,d0
	beq     Error
	cmp.b   #':',d0
	beq     .parse_own_numbers
	bra     .wait_for_colon


.parse_own_numbers:
	jsr     Parse_number_list
	move.l  a1,a2
	move.l  d1,d2

	cmp.b   #'|',(a0)+
	bne     Error

;; parse_winning_numbers
	jsr     Parse_number_list
	cmp.b   #'\n',(a0)+
	bne     Error

	jsr     Intersection_count

	move.l  d3,(bump_allocator_size) ;; deallocate memory
	movem.l (sp)+,d1-d3/a1/a2
	rts


;; a[i]  = number of additional tickets won by ticket a

;; a'[i] = total count of tickets [i..n-1] and their descendants.

;; a'[i] = a'[i + 1] - a'[i + 1 + a[i]]    (additional tickets won by this ticket)
;;       + a'[i + 1]                       (tickets from later sources)
;;       + 1                               (this ticket)

;; a'[i] = 2 * a'[i + 1] - a'[i + 1 + a[i]] + 1

Calculate_part_2_score:
	movem.l d1/a0-a3,-(sp)
	move.l  (bump_allocator_base),a0 ;; low guard
	move.l  a0,a1
	add.l   (bump_allocator_size),a1
	move.l  #0,(a1) ;; seed value
	sub.l   #4,a1

.turns_loop:
	cmp.l   a0,a1
	blt     .exit
	move.l  (a1),d0 ;; number of won tickets

	add.l   #1,d0
	add.l   d0,d0
	add.l   d0,d0   ;; (a[i] + 1) * sizeof(Long)

	move.l  (4,a1),d1
	add.l   d1,d1      ;; 2 * a'[i + 1]
	sub.l   (a1,d0),d1 ;; ^__ - a'[i + 1 + a[i]]
	add.l   #1,d1      ;; ^__ + 1

	move.l  d1,(a1)
	sub.l   #4,a1
	bra     .turns_loop

.exit:
	move.l  (a0),d0
	movem.l (sp)+,d1/a0-a3
	rts


Solve:
	movem.l d0-a6,-(sp)
	clr.l   d2
.lines_loop:
	tst.b   (a0)
	beq     .done
	jsr     Process_line

	;; allocate space for the part 2 score
	move.l  (bump_allocator_base),a1
	add.l   (bump_allocator_size),a1
	move.l  d0,(a1)
	add.l   #4,(bump_allocator_size)

	;; calculate part 1 score
	move.l  #0,d1
	or.b    #%10000,ccr ;; set extend bit
	roxl.l  d0,d1       ;; floor(2^(d0 - 1))
	move.l  d1,d0

	add.l   d0,d2
	bra     .lines_loop

.done:
	move.l  d2,d0
	jsr     Put_integer
	lea     (newline),a0
	jsr     Put_string

	jsr     Calculate_part_2_score
	jsr     Put_integer
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
	move.l  d0,(bump_allocator_base)

	lea     (my_message),a0
	jsr     Tick
	jsr     Solve
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

my_message:
	incbin  "input.txt"
	dc.b    0

	section BSS,BSS_C
bump_allocator_size:
	dcb.l   1
bump_allocator_base:
	dcb.l   1
bump_allocator_mem:
	dcb.b   400 * KiB
