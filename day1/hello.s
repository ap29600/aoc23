; syntax M68k

	include "../include/baremetal_cli.i"
	include "../include/numerics.i"
	include "../include/font.i"

	section CODE,CODE_C

Debug_rule:
	movem.l d0-a6,-(sp)
	lea     (.rule),a0
	jsr     Put_string
	movem.l (sp)+,d0-a6
	rts
.rule:
	dc.b    "++++++++++++++++++\n",0
	even

Debug_break:
	movem.l d0-a6,-(sp)
	lea     (.debug_begin_label),a0
	jsr     Put_string

	lea     (.a0_label),a0
	jsr     Put_string
	move.l  (8*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d0_label),a0
	jsr     Put_string
	move.l  (0*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a1_label),a0
	jsr     Put_string
	move.l  (9*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d1_label),a0
	jsr     Put_string
	move.l  (1*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a2_label),a0
	jsr     Put_string
	move.l  (10*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d2_label),a0
	jsr     Put_string
	move.l  (2*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a3_label),a0
	jsr     Put_string
	move.l  (11*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d3_label),a0
	jsr     Put_string
	move.l  (3*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a4_label),a0
	jsr     Put_string
	move.l  (12*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d4_label),a0
	jsr     Put_string
	move.l  (4*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a5_label),a0
	jsr     Put_string
	move.l  (13*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d5_label),a0
	jsr     Put_string
	move.l  (5*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.a6_label),a0
	jsr     Put_string
	move.l  (14*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.d6_label),a0
	jsr     Put_string
	move.l  (6*4,sp),d0
	jsr     Put_hexadecimal

	lea     (.debug_end_label),a0
	jsr     Put_string

	m_pause

	movem.l (sp)+,d0-a6
	rts

.debug_begin_label:
	dc.b    "=== DEBUG BREAK ===",0
.a0_label:
	dc.b    "\na0: ",0
.d0_label:
	dc.b    "\td0: ",0
.a1_label:
	dc.b    "\na1: ",0
.d1_label:
	dc.b    "\td1: ",0
.a2_label:
	dc.b    "\na2: ",0
.d2_label:
	dc.b    "\td2: ",0
.a3_label:
	dc.b    "\na3: ",0
.d3_label:
	dc.b    "\td3: ",0
.a4_label:
	dc.b    "\na4: ",0
.d4_label:
	dc.b    "\td4: ",0
.a5_label:
	dc.b    "\na5: ",0
.d5_label:
	dc.b    "\td5: ",0
.a6_label:
	dc.b    "\na6: ",0
.d6_label:
	dc.b    "\td6: ",0
.debug_end_label:
	dc.b    "\n===================\n",0

Parse_digit: ;(
;  a0.l : string begin
;  d0.l : strict mode
;) -> (
;  d0.l : digit value
;) sets overflow flag on parse error

	;; first char.
	move.b    (a0)+,d1
	beq       .parse_fail
	and.l     #$ff,d1
	cmp.b     #'0',d1
	blt       .literal
	cmp.b     #'9',d1
	bgt       .literal
	sub.b     #'0',d1
	move.l    d1,d0
	bra       .parse_success

	;; we encountered something other than a digit, try
	;; to match it against the known digit names, switching
	;; on the first two bytes.
.literal:
	;; only allow single digits in strict mode.
	tst.l     d0
	bne       .parse_fail

	;; take the first two chars(we know the first is not 0)
	sub.b     #'a',d1
	blt       .parse_fail
	cmp.b     #26,d1
	bgt       .parse_fail

	move.b    (a0)+,d0
	sub.b     #'a',d0
	blt       .parse_fail
	cmp.b     #26,d0
	bgt       .parse_fail

	mulu.w    #26,d1          ; compute table offset
	add.l     d0,d1
	lsl.l     #2,d1

	lea       digits_table,a1 ; retrieve table entry
	move.l    (a1,d1.w),d0
	beq       .parse_fail     ; if table doesn't have this combination, fail.
	move.l    d0,a1
	move.b    (a1)+,d0        ; if it did and we match, this is the return value
	and.l     #$ff,d0

	;; check that the string actually matches
	add.l     #2,a1           ; we know the first two bytes match.
.cmp_loop:
	move.b    (a0)+,d1
	move.b    (a1)+,d2
	beq       .parse_success  ; end of needle
	cmp.b     d1,d2
	bne       .parse_fail     ; mismatch
	bra       .cmp_loop

.parse_success:
	rts

.parse_fail:
	or.b      #COND_B_overflow,ccr
	rts

digits_table:
	dcb.l    26*26,$00000000

Fill_digits_table:
	lea      digits_table,a0
	lea      .digit_name_zero,a1
	move.l   a1,(4*(('z'-'a')*26+('e'-'a')),a0)
	lea      .digit_name_one,a1
	move.l   a1,(4*(('o'-'a')*26+('n'-'a')),a0)
	lea      .digit_name_two,a1
	move.l   a1,(4*(('t'-'a')*26+('w'-'a')),a0)
	lea      .digit_name_three,a1
	move.l   a1,(4*(('t'-'a')*26+('h'-'a')),a0)
	lea      .digit_name_four,a1
	move.l   a1,(4*(('f'-'a')*26+('o'-'a')),a0)
	lea      .digit_name_five,a1
	move.l   a1,(4*(('f'-'a')*26+('i'-'a')),a0)
	lea      .digit_name_six,a1
	move.l   a1,(4*(('s'-'a')*26+('i'-'a')),a0)
	lea      .digit_name_seven,a1
	move.l   a1,(4*(('s'-'a')*26+('e'-'a')),a0)
	lea      .digit_name_eight,a1
	move.l   a1,(4*(('e'-'a')*26+('i'-'a')),a0)
	lea      .digit_name_nine,a1
	move.l   a1,(4*(('n'-'a')*26+('i'-'a')),a0)
	rts

.digit_name_zero:
	dc.b     0,"zero",0
.digit_name_one:
	dc.b     1,"one",0
.digit_name_two:
	dc.b     2,"two",0
.digit_name_three:
	dc.b     3,"three",0
.digit_name_four:
	dc.b     4,"four",0
.digit_name_five:
	dc.b     5,"five",0
.digit_name_six:
	dc.b     6,"six",0
.digit_name_seven:
	dc.b     7,"seven",0
.digit_name_eight:
	dc.b     8,"eight",0
.digit_name_nine:
	dc.b     9,"nine",0

	even

Solve:
	movem.l d0-a6,-(sp)

	move.l  a0,a3
	move.l  d0,d6

	clr.l   d5
.new_line:
	clr.l   d3
	clr.l   d4
.wait_first:
	move.l  a3,a0
	move.b  (a3)+,d0
	beq     .end_of_file
	cmp.b   #'\n',d0
	beq     .wait_first

	move.l  d6,d0 ; strictness
	jsr     Parse_digit
	bvc     .found_first
	bra     .wait_first
	
	;; found the first char
.found_first:
	move.b  d0,d3
	move.b  d0,d4

.wait_more:
	move.l  a3,a0
	add.l   #1,a3

	move.b  (a0),d0
	tst.b   d0
	beq     .end_of_line
	cmp.b   #'\n',d0
	beq     .end_of_line

	move.l  d6,d0      ; strictness
	jsr     Parse_digit
	bvc     .found_more
	bra     .wait_more ; keep looking

.found_more:
	move.b  d0,d4
	bra     .wait_more

.end_of_line:
	mulu    #10,d3
	add.l   d4,d3
	add.l   d3,d5
	bra     .new_line

.end_of_file:
	move.l  d5,d0
	jsr     Put_integer
	lea     (.newline_const_string),a0
	jsr     Put_string

	movem.l (sp)+,d0-a6
	rts

.newline_const_string:
	dc.b    "\n",0
	even

Main:
	movem.l d0-a6,-(sp)
	lea     SYS_REGISTER_BASE,a6
	move.w  #(DMA_B_clr|DMA_B_everything),(HW_DMA_control,a6)
	jsr     Initialize_printer
	jsr     Fill_digits_table

	lea     (my_message),a0
	move.l  #1,d0
	jsr     Solve

	move.l  #0,d0
	jsr     Solve

	m_pause

	movem.l (sp)+,d0-a6
	rts

	section DATA,DATA_C
my_message:
	incbin  "input.txt"
	dc.b    0
part1_prompt:
	dc.b    "Part 1:\t",0
part2_prompt:
	dc.b    "Part 2:\t",0
