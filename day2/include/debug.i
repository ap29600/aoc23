; syntax M68k

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
