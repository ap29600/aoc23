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

Load_timer:
	move.l  a0,-(sp)
	lea     ($BFE000),a0

	move.b  ($B01,a0),d0
	lsl.l   #8,d0
	move.b  ($A01,a0),d0
	lsl.l   #8,d0
	move.b  ($901,a0),d0
	lsl.l   #8,d0
	move.b  ($801,a0),d0

	move.l (sp)+,a0
	rts

Tick:
	movem.l d0/a0,-(sp)
	lea     (.tick_message),a0
	jsr     Put_string

	jsr     Load_timer
	move.l  d0,(clock)
	movem.l (sp)+,d0/a0
	rts

.tick_message:
	dc.b    "Tick\n",0
	even

Tock:
	movem.l d0/d1/a0,-(sp)

	jsr     Load_timer
	sub.l   (clock),d0

	lea     (.tock_message),a0
	jsr     Put_string

	;; clock diff multiplied by 20,
	;; as it counts in increments of frame time (~20ms)
	add.l   d0,d0
	add.l   d0,d0 ;; 4x
	move.l  d0,d1
	add.l   d0,d0 ;; 8x
	add.l   d0,d0 ;; 16x
	add.l   d1,d0 ;; 20x

	jsr     Put_integer
	lea     (.tock_ms),a0
	jsr     Put_string

	movem.l (sp)+,d0/d1/a0
	rts
.tock_message:
	dc.b    "Tock: ",0
.tock_ms:
	dc.b    " ms\n",0
	even

	section BSS,BSS_C
clock:
	dcb.l 1
