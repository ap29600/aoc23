; syntax M68k

COND_B_extend   equ 1<<4
COND_B_negative equ 1<<3
COND_B_zero     equ 1<<2
COND_B_overflow equ 1<<1
COND_B_carry    equ 1<<0

    section CODE,CODE_C

    macro m_pause
.\@_press:
	btst    #6,$BFE001
	bne     .\@_press
.\@_release:
	btst    #6,$BFE001
	beq     .\@_release
    endm

    macro m_debug_register
    movem.l  d0-a6,-(sp)
    move.l   \1,d0
    jsr      Put_hexadecimal
    lea      (__debug_newline),a0
    jsr      Put_string
    movem.l  (sp)+,d0-a6
    endm

    macro m_debug_separator
    movem.l  d0-a6,-(sp)
    lea      (__debug_separator),a0
    jsr      Put_string
    movem.l  (sp)+,d0-a6
    endm

	macro m_mulu_10
	move.l   \1,\2
	add.l    \2,\2
	add.l    \2,\2
	add.l    \1,\2
	add.l    \2,\2
	endm

Divu_10:
    move.l   d2,-(sp)
    move.l   d0,d2
    and.l    #$0000ffff,d2
    swap     d0
    and.l    #$ffff,d0
    divu     #10,d0
    move.w   d0,d1
    and.l    #$ffff0000,d0
    or.l     d2,d0
    divu     #10,d0
    swap     d1
    and.l    #$ffff0000,d1
    move.w   d0,d1
    swap     d0
    and.l    #$ff,d0
    exg      d0,d1
    move.l   (sp)+,d2
    rts

    macro m_exlt
    cmp.l    \1,\2
    bge      .\@_no_exchange
    exg      \1,\2
.\@_no_exchange:
    endm

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


Read_integer:
    movem.l   d1-d6/a1-a6,-(sp)
    move.l    a0,a1 ;; for restoring in case of no parse
    moveq.l   #0,d1 ;; clear top bits for long addition
    moveq.l   #0,d3 ;; sign
    moveq.l   #0,d0 ;; result
;; state 0: no sign parsed yet.
.sign:
    move.b    (a0)+,d1
    cmp.b     #43,d1
    beq       .consume_sign_positive
    cmp.b     #45,d1
    beq       .consume_sign_negative
    bra       .first_digit

.consume_sign_negative:
    move.b    #1,d3
.consume_sign_positive:
    addq.l    #1,a0
;; state 1: sign parsed, no first digit yet.
.first_digit:
    sub.b     #48,d1
    blt       .parse_fail
    cmp.b     #10,d1
    bge       .parse_fail
    bra       .update_value

;; state 2: some digits parsed, waiting for next.
.next_digit:
    move.b    (a0)+,d1
    sub.b     #48,d1
    blt       .parse_success
    cmp.b     #10,d1
    bge       .parse_success
.update_value:
    m_mulu_10   d0,d2
    move.l    d2,d0
    add.l     d1,d0
    bra       .next_digit

;; abort: restore pointer to start of parse
.parse_fail:
    move.l    a1,a0
    move.l    #$DEADBEEF,d0
    ;; set the overflow flag
    or.b      #COND_B_overflow,ccr
    bra       .exit

;; finalize sign and return
.parse_success:
    subq.l    #1,a0
    cmp.b     #0,d3
    move.b    #0,d1
    beq       .exit
    neg.l     d0
.exit:
    movem.l   (sp)+,d1-d6/a1-a6
    rts

Put_integer:
    movem.l  d0-a6,-(sp)
    lea      (.scratch_buffer_end),a0
    move.b   #0,d3 ;; positive
    tst.l    d0
    bge      .digits
    move.b   #1,d3 ;; negative
    neg.l    d0

.digits:
    jsr      Divu_10
    add.b    #'0',d1
    move.b   d1,-(a0)
    tst.l    d0
    bne      .digits

    tst.b    d3
    beq      .exit
    move.b   #'-',-(a0)
.exit:
    jsr      Put_string
    movem.l  (sp)+,d0-a6
    rts

.scratch_buffer:
    dcb.b 20
.scratch_buffer_end:
    dc.b 0
    even


Put_unsigned:
    movem.l  d0-a6,-(sp)
    lea      (.scratch_buffer_end),a0
.digits:
    jsr      Divu_10
    add.b    #'0',d1
    move.b   d1,-(a0)
    tst.l    d0
    bne      .digits
.exit:
    jsr      Put_string
    movem.l  (sp)+,d0-a6
    rts

.scratch_buffer:
    dcb.b 20
.scratch_buffer_end:
    dc.b 0
    even

    section DATA,DATA_C
__debug_newline:
    dc.b    "\n",0
__debug_separator:
    dc.b    "------------\n",0

