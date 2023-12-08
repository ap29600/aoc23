; syntax M68k

;; =======================================================
;; common constants
;; =======================================================

Bits_per_byte equ 8

Byte equ 1
Word equ 2
Long equ 4
KiB  equ 1024
MiB  equ 1024 * 1024


SYS_REGISTER_BASE equ $00DFF000

;; =======================================================
;; relative to exec base
;; =======================================================

IRQ1 equ $64
IRQ2 equ $68
IRQ3 equ $6C
IRQ4 equ $70
IRQ5 equ $74
IRQ6 equ $78
IRQ7 equ $7C

;; =======================================================
;; relative to SYS_REGISTER_BASE
;; =======================================================

COLOR00 equ $180
COLOR01 equ $182
COLOR02 equ $184
COLOR03 equ $186
COLOR04 equ $188
COLOR05 equ $18A
COLOR06 equ $18C
COLOR07 equ $18E
COLOR08 equ $190
COLOR09 equ $192
COLOR10 equ $194
COLOR11 equ $196
COLOR12 equ $198
COLOR13 equ $19A
COLOR14 equ $19C
COLOR15 equ $19E
COLOR16 equ $1A0
COLOR17 equ $1A2
COLOR18 equ $1A4
COLOR19 equ $1A6
COLOR20 equ $1A8
COLOR21 equ $1AA
COLOR22 equ $1AC
COLOR23 equ $1AE
COLOR24 equ $1B0
COLOR25 equ $1B2
COLOR26 equ $1B4
COLOR27 equ $1B6
COLOR28 equ $1B8
COLOR29 equ $1BA
COLOR30 equ $1BC
COLOR31 equ $1BE

HWR_interrupt_enable  equ $01C
HWR_DMA_control       equ $002
DMA_S_blitter         equ 6
HWR_vertical_position equ $004
HWR_audio_disk_uart   equ $010

HL_copper_list_1 equ $080
HL_copper_list_2 equ $084
HW_copper_jump_1 equ $088
HW_copper_jump_2 equ $08A

HW_display_window_start equ $08E
HW_display_window_stop  equ $090
HW_display_fetch_start  equ $092
HW_display_fetch_stop   equ $094

HW_DMA_control equ $096
DMA_B_clr        equ 0
DMA_B_set        equ 1<<15
DMA_B_master     equ 1<<09
DMA_B_bitplane   equ 1<<08
DMA_B_copper     equ 1<<07
DMA_B_blitter    equ 1<<06
DMA_B_sprite     equ 1<<05
DMA_B_disk       equ 1<<04
DMA_B_audio3     equ 1<<03
DMA_B_audio2     equ 1<<02
DMA_B_audio1     equ 1<<01
DMA_B_audio0     equ 1<<00
DMA_B_everything equ $01ff

HW_interrupt_enable equ $09A
INT_B_clr        equ 0
INT_B_set        equ 1<<15
INT_B_master     equ 1<<14
INT_B_external   equ 1<<13
INT_B_disk_sync  equ 1<<12
INT_B_rx_buffer  equ 1<<11
INT_B_audio3     equ 1<<10
INT_B_audio2     equ 1<<09
INT_B_audio1     equ 1<<08
INT_B_audio0     equ 1<<07
INT_B_blitter    equ 1<<06
INT_B_vblank     equ 1<<05
INT_B_copper     equ 1<<04
INT_B_cia        equ 1<<03
INT_B_software   equ 1<<02
INT_B_disk_block equ 1<<01
INT_B_tx_buffer  equ 1<<00
INT_B_everything equ $3fff

HW_audio_disk_uart equ $09E

HL_bitplane_control equ $100
BPL_B_hi_res    equ 1<<31
BPL_S_number    equ 28
BPL_B_HAM_mode  equ 1<<27
BPL_B_double_pf equ 1<<26
BPL_B_color     equ 1<<25
BPL_B_super_res equ 1<<22
BPL_B_interlace equ 1<<18

HW_bitplane_modulo_1 equ $108
HW_bitplane_modulo_2 equ $10A

HL_bitplane_address_1 equ $0E0
HL_bitplane_address_2 equ $0E4

HL_blitter_control equ $040
BLT_S_shift_A     equ 28
BLT_B_use_A       equ 1<<27
BLT_B_use_B       equ 1<<26
BLT_B_use_C       equ 1<<25
BLT_B_use_D       equ 1<<24
BLT_S_formula     equ 16
BLT_S_shift_B     equ 12
BLT_B_excl_fill   equ 1<<04
BLT_B_incl_fill   equ 1<<03
BLT_B_fill_carry  equ 1<<02
BLT_B_descending  equ 1<<01
BLT_B_line_mode   equ 1<<01

BLT_B_formula_A equ $F0<<BLT_S_formula

HW_blitter_first_mask_A equ $044
HW_blitter_last_mask_A  equ $046

HL_blitter_address_A equ $050
HL_blitter_address_D equ $054

HW_blitter_size_start equ $058

HW_blitter_modulo_A equ $064
HW_blitter_modulo_D equ $066

HW_blitter_data_C equ $070
HW_blitter_data_B equ $072
HW_blitter_data_A equ $074

	macro WaitForBlitter
	btst    #DMA_S_blitter,(HWR_DMA_control,a6)
.\@:
	btst    #DMA_S_blitter,(HWR_DMA_control,a6)
	bne     .\@
	endm

	macro WaitForScreenLine
.\@:
	move.l    (HWR_vertical_position,a6),\2
	lsr.l     #1,\2
	lsr.w     #7,\2
	cmp.w     \1,\2
	bne       .\@
	endm

;; =======================================================
;; safestart routine
;; =======================================================

	section CODE,CODE_C
;APS00000000000000000000000000000000000000000000000000000000000000000000000000000000

; Copyright 2021 ing. E. Th. van den Oosterkamp
;
; Example software for the book "BareMetal Amiga Programming" (ISBN 9798561103261)
;
; Permission is hereby granted, free of charge, to any person obtaining a copy 
; of this software and associated files (the "Software"), to deal in the Software 
; without restriction, including without limitation the rights to use, copy,
; modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
; and to permit persons to whom the Software is furnished to do so,
; subject to the following conditions:
;
; The above copyright notice and this permission notice shall be included in 
; all copies or substantial portions of the Software.
;
; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
; INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A 
; PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
; HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION 
; OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE 
; SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

__SAFESTART_I equ 1

exec_AttnFlags    EQU    296

proc_MsgPort    EQU    92
proc_CLI    EQU    172

ExecSupervisor    EQU    -30
ExecForbid    EQU    -132
ExecPermit    EQU    -138
ExecFindTask    EQU    -294
ExecGetMsg    EQU    -372
ExecReplyMsg    EQU    -378
ExecWaitPort    EQU    -384
ExecOldOpenLib    EQU    -408
ExecCloseLib    EQU    -414

gfx_ActiView    EQU    $22
gfx_copinit    EQU    $26
gfx_LOFlist    EQU    $32

GfxLoadView    EQU    -222
GfxWaitTOF    EQU    -270


SafeStart:
	MOVE.L 4.w,a6              ; A6 = Exec base
	LEA.L  S_GraName(PC),a1    ; Name: Graphics library
	JSR    ExecOldOpenLib(a6)  ; Get library pointer
	MOVE.L d0,S_GraBase        ; Store for later use
	BEQ.W  .NoGraphics         ; No graphics? Unusual and strange

	SUB.L  a1,a1               ; A1 = NULL (find my own process)
	JSR    ExecFindTask(a6)    ; Get my task/process pointer
	MOVE.L d0,a5               ; A5 = Pointer to my process
	BEQ.W  .NoWBMsg            ; No pointer? Unusual and strange

	TST.L  proc_CLI(a5)        ; Check if started from Shell/CLI
	BNE.B  .FromCLI            ; From CLI! Skip Workbench stuff
	LEA.L  proc_MsgPort(a5),a0 ; A0 = Worbench MsgPort
	JSR    ExecWaitPort(a6)    ; Wait for workbench message
	LEA.L  proc_MsgPort(a5),a0 ; A0 = Worbench MsgPort
	JSR    ExecGetMsg(a6)      ; Get workbench message
	MOVE.L d0,_S_WBMsg         ; Store message pointer

.FromCLI
	JSR    ExecForbid(a6)      ; Do not run other tasks

	BTST.B #0,exec_AttnFlags+1(a6) ; Check if > 68000 processor
	BEQ.B  .NoVBR                  ; On 68000 no VBR (always zero)
	LEA.L  _S_GetVBR(PC),a5        ; Function to call as supervisor
	JSR    ExecSupervisor(a6)      ; Call supervisor function in A5
	MOVE.L d0,S_VBR                ; Store the returned VBR contents
.NoVBR
	MOVE.L S_GraBase(PC),a6        ; A6 = Graphics base
	MOVE.L gfx_ActiView(a6),-(a7)  ; Store current View pointer
	SUB.L  a1,a1                   ; NULL view = default settings
	JSR    GfxLoadView(a6)         ; Load the view
	JSR    GfxWaitTOF(a6)          ; Wait one screen refresh
	JSR    GfxWaitTOF(a6)          ; Wait a 2nd (in case of interlace)

	LEA.L  $DFF000,a5        ; A5 = Chipset registers base address
	MOVE.W #$8000,d0         ; Value
	MOVE.W HWR_DMA_control(a5),-(a7) ; Store system DMA channels
	OR.W   d0,(a7)           ; SET/CLR set to SET
	MOVE.W HWR_interrupt_enable(a5),-(a7) ; Store system enabled interrupts
	OR.W   d0,(a7)           ; SET/CLR set to SET
	MOVE.W HWR_audio_disk_uart(a5),-(a7) ; Audio, disk and UART
	OR.W   d0,(a7)           ; SET/CLR set to SET
	MOVE.W HWR_vertical_position(a5),d0      ; Vertical pos and Agnus ID
	BTST   #13,d0            ; When set: NTSC, when clear: PAL
	BNE.B  .NTSC             ; Leave value 0 for NTSC
	MOVE.W #$FFFF,S_PAL      ; Set all bits for PAL

.NTSC
	BTST.B #14-8,HWR_DMA_control(a5) ; Dummy read

.BltBusy
	BTST.B #14-8,HWR_DMA_control(a5) ; Blitter still busy?
	BNE.B  .BltBusy          ; If yes, wait a bit
	MOVE.W #$01FF,HW_DMA_control(a5) ; Disable all DMA
	MOVE.W #$3FFF,HW_interrupt_enable(a5) ; Disable all interrupts

	MOVE.L S_VBR(PC),a0      ; A0 = Pointer to vector base
	MOVE.L IRQ1(a0),-(a7)    ; Store IRQ1 vector
	MOVE.L IRQ3(a0),-(a7)    ; Store IRQ3 vector
	MOVE.L IRQ4(a0),-(a7)    ; Store IRQ4 vector

	BSR.W  Main              ; Jump to actual program

	LEA.L  $DFF000,a5     ; A5 = Chipset registers base address
	BTST.B    #14-8,HWR_DMA_control(a5)    ; Dummy read
.BltBusy2    BTST.B    #14-8,HWR_DMA_control(a5)    ; Blitter still busy?
	BNE.B    .BltBusy2        ; If yes, wait a bit
	MOVE.W    #$01FF,HW_DMA_control(a5)    ; Disable all DMA
	MOVE.W    #$3FFF,HW_interrupt_enable(a5)    ; Disable all interrupts

	MOVE.L    S_VBR(PC),a0        ; A0 = Pointer to vector base
	MOVE.L    (a7)+,IRQ4(a0)        ; Restore IRQ4 vector
	MOVE.L    (a7)+,IRQ3(a0)        ; Restore IRQ3 vector
	MOVE.L    (a7)+,IRQ1(a0)        ; Restore IRQ1 vector

	MOVE.L    S_GraBase(PC),a6    ; A6 = Graphics base
	MOVE.L    gfx_copinit(a6),HL_copper_list_1(a5)    ; Restore coplist pointer 1
	MOVE.L    gfx_LOFlist(a6),HL_copper_list_2(a5)    ; Restore coplist pointer 2
	CLR.W    HW_copper_jump_1(a5)        ; Make Copper use restored pointer

	MOVE.W    (a7)+,HW_audio_disk_uart(a5)    ; Restore audio, disk and UART
	MOVE.W    (a7)+,HW_interrupt_enable(a5)    ; Restore original interrupts
	MOVE.W    (a7)+,HW_DMA_control(a5)    ; Restore original DMA

	MOVE.L    (a7)+,a1        ; Get original view pointer
	JSR    GfxLoadView(a6)        ; Restore the original view
	JSR    GfxWaitTOF(a6)        ; Wait one screen refresh
	JSR    GfxWaitTOF(a6)        ; Wait a 2nd (in case of interlace)

	MOVE.L    4.w,a6            ; A6 = Exec base
	TST.L    _S_WBMsg        ; Was there a msg from Workbench?
	BEQ.B    .NoWBMsg        ; No. Nothing to do
	MOVE.L    _S_WBMsg(PC),a1        ; Pointer to Workbench message
	JSR    ExecReplyMsg(a6)    ; Reply message to Workbench

.NoWBMsg    MOVE.L    S_GraBase(PC),a1    ; APTR to graphics base
	JSR    ExecCloseLib(a6)    ; Close library 

.NoGraphics    MOVEQ    #0,d0            ; Return "no errors"
	RTS

_S_GetVBR:    DC.L    $4E7A0801        ; MOVEC VBR,d0
	RTE                ; Return from supervisor mode

_S_WBMsg:    DC.L    0
S_VBR:        DC.L    0
S_PAL:        DC.W    0
S_GraBase:    DC.L    0
S_GraName:    DC.B    "graphics.library",0
	EVEN

;; =======================================================
;; printer setup
;; =======================================================

Screen_width           equ 320
Screen_height          equ 200
Screen_memory_map_size equ Screen_width*Screen_height/Bits_per_byte
Text_line_bytes        equ Screen_width*Font_height/Bits_per_byte
Screen_line_bytes      equ Screen_width/Bits_per_byte

Initialize_printer:

	move.w  #(DMA_B_set|DMA_B_bitplane|DMA_B_copper|DMA_B_blitter),(HW_DMA_control,a6)
	;; bitplanes
	move.l  #((1<<BPL_S_number)|BPL_B_color),(HL_bitplane_control,a6)
	move.w  #$2c81,(HW_display_window_start,a6)
	move.w  #$f4c1,(HW_display_window_stop,a6)
	move.w  #$0038,(HW_display_fetch_start,a6)
	move.w  #$00d0,(HW_display_fetch_stop,a6)
	move.w  #0,(HW_bitplane_modulo_1,a6)

	;; patch copper list
	lea     (screen_memory_map),a0
	move.l  a0,d0
	move.w  d0,(bitplane_address_low)
	swap    d0
	move.w  d0,(bitplane_address_high)
	lea     (copper_list),a0
	move.l  a0,(HL_copper_list_1,a6)
	move.l  #0,(HW_copper_jump_1,a6)

	move.w  #0,(current_cursor)
	lea     (screen_memory_map),a0
	move.w  #(2*Screen_memory_map_size),d0
.clear_page_loop:
	move.b  #0,(a0)+
	sub.w   #1,d0
	bne     .clear_page_loop
	rts

Put_hexadecimal:
	movem.l d0-a6,-(sp)
	lea     (print_address_buffer),a0
	move.b  #48,(a0)+
	move.b  #120,(a0)+
	move.b  #8,d1
.next_nibble:
	rol.l   #4,d0
	move.b  d0,d2
	and.b   #$0f,d2
	cmp.b   #10,d2
	bge     .alpha
	add.b   #48,d2
	bra     .put
.alpha:
	add.b   #55,d2
.put:
	move.b  d2,(a0)+
	sub.b   #1,d1
	bne     .next_nibble
	move.b  #0,(a0)+
	lea     (print_address_buffer),a0
	jsr     Put_string
	movem.l (sp)+,d0-a6
	rts


Put_string:; (
	; a0.l: string base address
; ) -> ()
	movem.l d0-a6,-(sp)
	; a1 = screen base
	lea     (screen_memory_map),a1
	; d0 = cursor
	move.w  (current_cursor),d0
	and.l   #$0000ffff,d0
	; d1 = end of line
	move.l  d0,d1
	divu    #Screen_line_bytes,d1
	add.l   #1,d1
	mulu    #Screen_line_bytes,d1
	; a2 = font base
	lea     (font),a2

.next_char:
	move.b  (a0)+,d2
	and.w   #$ff,d2
	beq     .exit
	
	cmp.b   #10,d2
	beq     .newline

	cmp.b   #9,d2
	beq     .tab

	mulu    #Font_height,d2
	lea     (a1,d0),a3
	lea     (a2,d2),a4
	move.b  (0,a4),(0*Screen_line_bytes,a3)
	move.b  (1,a4),(1*Screen_line_bytes,a3)
	move.b  (2,a4),(2*Screen_line_bytes,a3)
	move.b  (3,a4),(3*Screen_line_bytes,a3)
	move.b  (4,a4),(4*Screen_line_bytes,a3)
	move.b  (5,a4),(5*Screen_line_bytes,a3)
	move.b  (6,a4),(6*Screen_line_bytes,a3)
	move.b  (7,a4),(7*Screen_line_bytes,a3)
	move.b  (8,a4),(8*Screen_line_bytes,a3)
	move.b  (9,a4),(9*Screen_line_bytes,a3)
	add.w   #1,d0
	cmp.w   d1,d0
	bge     .newline
	bra     .next_char

.tab:
	add.w   #4,d0
	and.w   #$fffc,d0
	cmp.w   d1,d0
	bge     .newline
	bra     .next_char

.newline:
	add.w   #Text_line_bytes,d1  ; new end of line
	move.w  d1,d0
	sub.w   #Screen_line_bytes,d0 ; new start of line

	cmp.w   #Screen_memory_map_size,d0 ; are we overflowing the screen?
	blt     .next_char ; otherwise, continue as usual

.soft_scroll:
	cmp.w   #2*Screen_memory_map_size,d0 ; are we overflowing the buffer?
	bge     .hard_scroll

	; move the screen by one text line
	move.w  (bitplane_address_high),d2
	swap    d2
	move.w  (bitplane_address_low),d2
	add.l   #Text_line_bytes,d2
	move.w  d2,(bitplane_address_low)
	swap    d2
	move.w  d2,(bitplane_address_high)
	
	bra     .next_char

.hard_scroll:
	; wait for vblank to avoid observable artifacts
	WaitForScreenLine #$FF,d0
	move.w  #(DMA_B_set|DMA_B_blitter),(HW_DMA_control,a6)
	move.l  #(BLT_B_formula_A|BLT_B_use_A|BLT_B_use_D),(HL_blitter_control,a6)
	; destination
	lea     (screen_memory_map),a3
	move.l  a3,(HL_blitter_address_D,a6)
	move.w  #0,(HW_blitter_modulo_D,a6)
	; source
	add.l   #Screen_memory_map_size+Text_line_bytes,a3
	move.l  a3,(HL_blitter_address_A,a6)
	move.w  #0,(HW_blitter_modulo_A,a6)
	move.w  #$ffff,(HW_blitter_first_mask_A,a6)
	move.w  #$ffff,(HW_blitter_last_mask_A,a6)

	; start blitter
	move.w  #((Screen_height-Font_height)<<6|(Screen_width/16)),(HW_blitter_size_start,a6)
	WaitForBlitter

	move.l  #(BLT_B_formula_A|BLT_B_use_D),(HL_blitter_control,a6)
	; destination
	lea     (screen_memory_map+Screen_memory_map_size-Text_line_bytes),a3
	move.l  a3,(HL_blitter_address_D,a6)
	move.w  #0,(HW_blitter_modulo_D,a6)
	; source
	move.w  #0,(HW_blitter_data_A,a6)

	; start blitter
	move.w  #((Screen_height+Font_height)<<6|(Screen_width/16)),(HW_blitter_size_start,a6)
	WaitForBlitter

	; reset cursor to the beginning of the last line
	move.w  #Screen_memory_map_size-Text_line_bytes,d0
	move.w  #Screen_memory_map_size-Text_line_bytes+Screen_line_bytes,d1
	; reset view
	lea     screen_memory_map,a3
	move.l  a3,d2
	move.w  d2,(bitplane_address_low)
	swap    d2
	move.w  d2,(bitplane_address_high)
	bra     .next_char

.exit:
	move.w  d0,(current_cursor)
	movem.l (sp)+,d0-a6
	rts

	SECTION BSS,BSS_C
print_address_buffer:
	dcb.b 16
current_cursor:
	dcb.w 1
screen_memory_map:
	dcb.b 2*Screen_memory_map_size
screen_memory_map_end:

	section DATA,DATA_C

copper_list:
	dc.w     COLOR00,$0fff
	dc.w     COLOR01,$0000
	dc.w     HL_bitplane_address_1+2
bitplane_address_low:
	dc.w     0
	dc.w     HL_bitplane_address_1+0
bitplane_address_high:
	dc.w     0
	dc.w     $ffff,$fffe
