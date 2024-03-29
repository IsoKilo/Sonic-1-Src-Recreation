align macro
	cnop 0,\1
	endm
	
		dc.l $FFFE00, START, Buserr, Addrerr
		dc.l IllegalInstr, ZeroDivide, ChkInstr, TrapvInstr
		dc.l PrivilegeViol, Trace, Line1010Emu,	Line1111Emu
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorExcept, ErrorExcept, ErrorExcept
		dc.l ErrorExcept, ErrorVect, ErrorVect,	ErrorVect
		dc.l Hint,	ErrorVect, Vblank, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect
		dc.l ErrorVect,	ErrorVect, ErrorVect, ErrorVect

*				 0        1         2         3         4         5
*				 12345678901234567890123456789012345678901234567890
		DC.B	'SEGA MEGA DRIVE '
		DC.B	'(C)SEGA 1991.APR'
		DC.B	'SONIC THE               '
		DC.B	'HEDGEHOG                '
		DC.B	'SONIC THE               '
		DC.B	'HEDGEHOG                '
		DC.B	'GM 00001009-00'
		DC.W	 0
		DC.B	'J               '
		DC.L	$00000000
		DC.L	$00200000
		DC.L	$00FF0000
		DC.L	$00FFFFFF
		DC.B	'            '
		DC.B	'            '
		DC.B	'                                        '
		DC.B	'JUE             '

; ===========================================================================

ErrorVect:
		nop	
		nop	
		bra.b	ErrorVect

*
*
*		MEGA DRIVE hard initial program
*
*				1990 6/6
*			R/D 5 
*
*	++++++++++++++++++++++++++++++++++++++++++++++++++
*	+	status of MEGA_DRIVE on program_finished +
*	++++++++++++++++++++++++++++++++++++++++++++++++++
*
*	****************** 68000 *******************
*	--------- CAUTION -----------
*	When program end
*	* 68000  set RESET to Z80 ($A11100=0,$A11200=$000)
*	* Z80 wait [ JP  (HL)  ] command ( HL=0000 )
*
*   *************************************************************
*   *								*
*   *	ICD_END is GAME_PROGRAM start_address			*
*   *  	ICD_END = START+$100					*
*   *	this program size is just 256 byte.			*
*   *								*
*   *************************************************************

;program start
START:
			tst.l	$a10008			; power on check cntl_A,cntl_B
			bne.b	h_s				; reset hot_start
			tst.w	$a1000c			; power on check cntl_C
h_s:		bne.b	hot_start		; reset hot_start

cold_start:						; power on (cold_start)
			lea		reg_set(pc),a5		;register set table
			movem.w	(a5)+,d5-d7		; d5/d6/d7
			movem.l	(a5)+,a0-a4		; a0-a5

security:							; ** a1=$a11100 **
			move.b	-$10ff(a1),d0	;-$1101(a1)=$a10000
			andi.b	#$000f,d0		;Ver.No check
			beq.b	japan
			move.l	#'SEGA',$2f00(a1)
* security part move "SEGA"
japan:								; $2F00(A1)=$A14000
reg_init:
			move	(a4),d0			;VDP STATUS DUMMY READ (D5=$8000)
			moveq	#0,d0			; D0 set   0
			move.l	d0,a6			; A6 $00000000
			move.l	a6,usp			; User Stack Pointer
			moveq	#23,d1			; D1 count VDP_command

r_ini1:
			move.b	(a5)+,d5		;REG 0-23 SET (DMA FILL SET)
			move.w	d5,(a4)			;
			add		d7,d5			; d7=$100
			dbra	d1,r_ini1

dma_fill:							;already set REG#18,19,23
			move.l	(a5)+,(a4)		;dma fill(VDP_VRAM CLEAR)
			move	d0,(a3)			;fill data set $0,$C00000

z80_clr:							;Z80 self_initial
			move	d7,(a1)			; Z80_BUSREQ ON
			move	d7,(a2)			; Z80_RESET  OFF
z801:		btst	d0,(a1)			; Z80_BGACK  CHECK ?
			bne.b	z801
			moveq	#37,d2			; D2 is Z80_program's size
z802:		move.b	(a5)+,(a0)+		; move.B (z80_prg)+,($a00000)+
			dbra	d2,z802
			move	d0,(a2)			; Z80_RESET  ON
			move	d0,(a1)			; Z80_BUSREQ OFF
			move	d7,(a2)			; Z80_RESET  OFF(Z80 start)

clr_wk:								;A6=$0 D0=$0 D6=$3FFF
c_wk1:		move.l	d0,-(a6)		;wrok ram clear
			dbra	d6,c_wk1		;

clr_col		move.l	(a5)+,(a4)		;VDP REG#1=04,#15=02
			move.l	(a5)+,(a4)		;a3=$c00000 a4=$c00004 d0=$0
			moveq	#$1f,d3			; d3 is color_ram's size/2(WORD)
c_col1:		move.l	d0,(a3)			;vdp_color clear
			dbra	d3,c_col1

clr_vsc:	move.l	(a5)+,(a4)		;a3=$c00000 a4=$c00004 d0=$0
			moveq	#19,d4			; d4 count Vscroll_ram
c_vsc1:		move.l	d0,(a3)			;vdp_vscroll clear
			dbra	d4,c_vsc1

clr_psg:	moveq	#3,d5			; d5 is byte_size of PSG init_DATA
c_psg1:		move.b	(a5)+,$11(a3)	;PSG_SOUND clear
			dbra	d5,c_psg1

			move	d0,(a2)			;Z80 RESET
			movem.l	(a6),d0-d7/a0-a6	;register all initial
			move	#$2700,sr		;68000 register initial
hot_start:
			bra.b	chk_vdp				;
init_end:

reg_set:
		dc.w	$008000,$003fff,$000100				;d5/d6/d7
		dc.l	$a00000,$a11100,$a11200,$c00000		;a0-a3
		dc.l	$c00004								;a4

vreg_dt:
		dc.b	$04,$14,$30,$3c,$07,$6c,$00,$00		;VDP REG #0-7
		dc.b	$00,$00,$ff,$00,$81,$37,$00,$01		;VDP_REG #8-15
		dc.b	$01,$00,$00,$ff,$ff,$00,$00,$80		;VDP_REG #16-23
dma_fill_data:
		dc.l	$40000080							;dma fill(VDP_VRAM clear)

z80_prg:
		DC.B	$AF									;XOR	A
		DC.B	$01,$D9,$1F							;LD		BC,1FD9H
		DC.B	$11,$27,$00							;LD		DE,0027H
		DC.B	$21,$26,$00							;LD		HL,0026H
		DC.B	$F9									;LD		SP,HL
		DC.B	$77									;LD		(HL),A
		DC.B	$ED,$B0								;LDIR
		DC.B	$DD,$E1								;POP	IX
		DC.B	$FD,$E1								;POP	IY
		DC.B	$ED,$47								;LD		I,A
		DC.B	$ED,$4F								;LD		R,A
		DC.B	$D1									;POP	DE
		DC.B	$E1									;POP	HL
		DC.B	$F1									;POP	AF
		DC.B	$08									;EX		AF,AF'
		DC.B	$D9									;EXX
		DC.B	$C1									;POP	BC
		DC.B	$D1									;POP	DE
		DC.B	$E1									;POP	HL
		DC.B	$F1									;POP	AF
		DC.B	$F9									;LD		SP,HL
		DC.B	$F3									;DI
		DC.B	$ED,$56								;IM1
		DC.B	$36,$E9								;LD		(HL),E9='JP (HL)'
		DC.B	$E9									;JP		(HL)
new_reg_data:
		dc.l	$81048f02							;VDP REG#1=04,#15=02
clr_col_data:
		dc.l	$c0000000							;color_ram address data
clr_vsc_data:
		dc.l	$40000010							;v_scroll ram address data

psg_dat:
		DC.B	$9F,$BF,$DF,$FF

chk_vdp:
		tst.w	($C00004).l
		btst	#6,($A1000D).l
		beq.b	CheckSumCheck
		cmpi.l	#'init',($FFFFFFFC).w ; has checksum routine already run?
		beq.w	GameInit	; if yes, branch

CheckSumCheck:
		movea.l	#ErrorVect,a0	; start	checking bytes after the header	($200)
		movea.l	#RomEndLoc,a1	; stop at end of ROM
		move.l	(a1),d0
		moveq	#0,d1

loc_32C:
		add.w	(a0)+,d1
		cmp.l	a0,d0
		bcc.b	loc_32C
		movea.l	#Checksum,a1	; read the checksum
		cmp.w	(a1),d1		; compare correct checksum to the one in ROM
		bne.w	CheckSumError	; if they don't match, branch
		lea	($FFFFFE00).w,a6
		moveq	#0,d7
		move.w	#$7F,d6

loc_348:
		move.l	d7,(a6)+
		dbra	d6,loc_348
		move.b	($A10001).l,d0
		andi.b	#$C0,d0
		move.b	d0,($FFFFFFF8).w
		move.l	#'init',($FFFFFFFC).w ; set flag so checksum won't be run again

GameInit:
		lea	($FF0000).l,a6
		moveq	#0,d7
		move.w	#$3F7F,d6

GameClrRAM:
		move.l	d7,(a6)+
		dbra	d6,GameClrRAM	; fill RAM ($0000-$FDFF) with $0
		bsr.w	VDPSetupGame
		bsr.w	SoundDriverLoad
		bsr.w	JoypadInit
		move.b	#0,gmmode ; set Game Mode to Sega Screen

MainGameLoop:
		move.b	gmmode,d0 ; load	Game Mode
		andi.w	#$1C,d0
		jsr	GameModeArray(pc,d0.w) ; jump to apt location in ROM
		bra.b	MainGameLoop
; ===========================================================================
; ---------------------------------------------------------------------------
; Main game mode array
; ---------------------------------------------------------------------------

GameModeArray:
		bra.w	SegaScreen
		bra.w	TitleScreen
		bra.w	game
		bra.w	game
		bra.w	SpecialStage
		bra.w	ContinueScreen
		bra.w	EndingSequence
		bra.w	Credits
		rts	

CheckSumError:
		bsr.w	VDPSetupGame
		move.l	#$C0000000,($C00004).l ; set VDP to CRAM write
		moveq	#$3F,d7

CheckSum_Red:
		move.w	#$E,($C00000).l	; fill screen with colour red
		dbra	d7,CheckSum_Red	; repeat $3F more times

CheckSum_Loop:
		bra.b	CheckSum_Loop
; ===========================================================================

Buserr:
		move.b	#2,($FFFFFC44).w
		bra.b	loc_43A
; ===========================================================================

Addrerr:
		move.b	#4,($FFFFFC44).w
		bra.b	loc_43A
; ===========================================================================

IllegalInstr:
		move.b	#6,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.b	loc_462
; ===========================================================================

ZeroDivide:
		move.b	#8,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

ChkInstr:
		move.b	#$A,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

TrapvInstr:
		move.b	#$C,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

PrivilegeViol:
		move.b	#$E,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

Trace:
		move.b	#$10,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

Line1010Emu:
		move.b	#$12,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.b	loc_462
; ===========================================================================

Line1111Emu:
		move.b	#$14,($FFFFFC44).w
		addq.l	#2,2(sp)
		bra.b	loc_462
; ===========================================================================

ErrorExcept:
		move.b	#0,($FFFFFC44).w
		bra.b	loc_462
; ===========================================================================

loc_43A:
		move	#$2700,sr
		addq.w	#2,sp
		move.l	(sp)+,($FFFFFC40).w
		addq.w	#2,sp
		movem.l	d0-a7,flagwork
		bsr.w	ShowErrorMsg
		move.l	2(sp),d0
		bsr.w	sub_5BA
		move.l	($FFFFFC40).w,d0
		bsr.w	sub_5BA
		bra.b	loc_478
; ===========================================================================

loc_462:
		move	#$2700,sr
		movem.l	d0-a7,flagwork
		bsr.w	ShowErrorMsg
		move.l	2(sp),d0
		bsr.w	sub_5BA

loc_478:
		bsr.w	ErrorWaitForC
		movem.l	flagwork,d0-a7
		move	#$2300,sr
		rte	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ShowErrorMsg:				; XREF: loc_43A; loc_462
		lea	($C00000).l,a6
		move.l	#$78000003,($C00004).l
		lea	(ascii).l,a0
		move.w	#$27F,d1

Error_LoadGfx:
		move.w	(a0)+,(a6)
		dbra	d1,Error_LoadGfx
		moveq	#0,d0		; clear	d0
		move.b	($FFFFFC44).w,d0 ; load	error code
		move.w	ErrorText(pc,d0.w),d0
		lea	ErrorText(pc,d0.w),a0
		move.l	#$46040003,($C00004).l ; position
		moveq	#$12,d1		; number of characters

Error_LoopChars:
		moveq	#0,d0
		move.b	(a0)+,d0
		addi.w	#$790,d0
		move.w	d0,(a6)
		dbra	d1,Error_LoopChars ; repeat for	number of characters
		rts	
; End of function ShowErrorMsg

; ===========================================================================
ErrorText:	dc.w asc_4E8-ErrorText,	asc_4FB-ErrorText ; XREF: ShowErrorMsg
		dc.w asc_50E-ErrorText,	asc_521-ErrorText
		dc.w asc_534-ErrorText,	asc_547-ErrorText
		dc.w asc_55A-ErrorText,	asc_56D-ErrorText
		dc.w asc_580-ErrorText,	asc_593-ErrorText
		dc.w asc_5A6-ErrorText
asc_4E8:	dc.b 'ERROR EXCEPTION    '
asc_4FB:	dc.b 'BUS ERROR          '
asc_50E:	dc.b 'ADDRESS ERROR      '
asc_521:	dc.b 'ILLEGAL INSTRUCTION'
asc_534:	dc.b '@ERO DIVIDE        '
asc_547:	dc.b 'CHK INSTRUCTION    '
asc_55A:	dc.b 'TRAPV INSTRUCTION  '
asc_56D:	dc.b 'PRIVILEGE VIOLATION'
asc_580:	dc.b 'TRACE              '
asc_593:	dc.b 'LINE 1010 EMULATOR '
asc_5A6:	dc.b 'LINE 1111 EMULATOR '
		even

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_5BA:				; XREF: loc_43A; loc_462
		move.w	#$7CA,(a6)
		moveq	#7,d2

loc_5C0:
		rol.l	#4,d0
		bsr.b	sub_5CA
		dbra	d2,loc_5C0
		rts	
; End of function sub_5BA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_5CA:				; XREF: sub_5BA
		move.w	d0,d1
		andi.w	#$F,d1
		cmpi.w	#$A,d1
		bcs.b	loc_5D8
		addq.w	#7,d1

loc_5D8:
		addi.w	#$7C0,d1
		move.w	d1,(a6)
		rts	
; End of function sub_5CA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ErrorWaitForC:				; XREF: loc_478
		bsr.w	ReadJoypads
		cmpi.b	#$20,swdata1+1 ; is	button C pressed?
		bne.w	ErrorWaitForC	; if not, branch
		rts	
; End of function ErrorWaitForC

; ===========================================================================

ascii:	incbin	artunc\menutext.bin	; text used in level select and debug mode
		even

; ===========================================================================

Vblank:				; XREF: Vectors
		movem.l	d0-a6,-(sp)
		tst.b	($FFFFF62A).w
		beq.b	loc_B88
		move.w	($C00004).l,d0
		move.l	#$40000010,($C00004).l
		move.l	($FFFFF616).w,($C00000).l
		btst	#6,($FFFFFFF8).w
		beq.b	loc_B42
		move.w	#$700,d0

loc_B3E:
		dbra	d0,loc_B3E

loc_B42:
		move.b	($FFFFF62A).w,d0
		move.b	#0,($FFFFF62A).w
		move.w	#1,($FFFFF644).w
		andi.w	#$3E,d0
		move.w	off_B6E(pc,d0.w),d0
		jsr	off_B6E(pc,d0.w)

loc_B5E:				; XREF: loc_B88
		jsr	sub_71B4C

loc_B64:				; XREF: loc_D50
		addq.l	#1,systemtimer
		movem.l	(sp)+,d0-a6
		rte	
; ===========================================================================
off_B6E:	dc.w loc_B88-off_B6E, loc_C32-off_B6E
		dc.w loc_C44-off_B6E, loc_C5E-off_B6E
		dc.w loc_C6E-off_B6E, loc_DA6-off_B6E
		dc.w loc_E72-off_B6E, loc_F8A-off_B6E
		dc.w loc_C64-off_B6E, loc_F9A-off_B6E
		dc.w loc_C36-off_B6E, loc_FA6-off_B6E
		dc.w loc_E72-off_B6E
; ===========================================================================

loc_B88:				; XREF: Vblank; off_B6E
		cmpi.b	#$8C,gmmode
		beq.b	loc_B9A
		cmpi.b	#$C,gmmode
		bne.w	loc_B5E

loc_B9A:
		cmpi.b	#1,stageno ; is level LZ ?
		bne.w	loc_B5E		; if not, branch
		move.w	($C00004).l,d0
		btst	#6,($FFFFFFF8).w
		beq.b	loc_BBA
		move.w	#$700,d0

loc_BB6:
		dbra	d0,loc_BB6

loc_BBA:
		move.w	#1,($FFFFF644).w
		move.w	#$100,($A11100).l

loc_BC8:
		btst	#0,($A11100).l
		bne.b	loc_BC8
		tst.b	waterflag
		bne.b	loc_BFE
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.b	loc_C22
; ===========================================================================

loc_BFE:				; XREF: loc_BC8
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_C22:				; XREF: loc_BC8
		move.w	hintposi,(a5)
		move.w	#0,($A11100).l
		bra.w	loc_B5E
; ===========================================================================

loc_C32:				; XREF: off_B6E
		bsr.w	sub_106E

loc_C36:				; XREF: off_B6E
		tst.w	($FFFFF614).w
		beq.w	locret_C42
		subq.w	#1,($FFFFF614).w

locret_C42:
		rts	
; ===========================================================================

loc_C44:				; XREF: off_B6E
		bsr.w	sub_106E
		bsr.w	sub_6886
		bsr.w	sub_1642
		tst.w	($FFFFF614).w
		beq.w	locret_C5C
		subq.w	#1,($FFFFF614).w

locret_C5C:
		rts	
; ===========================================================================

loc_C5E:				; XREF: off_B6E
		bsr.w	sub_106E
		rts	
; ===========================================================================

loc_C64:				; XREF: off_B6E
		cmpi.b	#$10,gmmode ; is	game mode = $10	(special stage)	?
		beq.w	loc_DA6		; if yes, branch

loc_C6E:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_C76:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.b	loc_C76		; if not, branch
		bsr.w	ReadJoypads
		tst.b	waterflag
		bne.b	loc_CB0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.b	loc_CD4
; ===========================================================================

loc_CB0:				; XREF: loc_C76
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_CD4:				; XREF: loc_C76
		move.w	hintposi,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		tst.b	($FFFFF767).w
		beq.b	loc_D50
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.b	#0,($FFFFF767).w

loc_D50:
		move.w	#0,($A11100).l
		movem.l	scra_h_posit,d0-d7
		movem.l	d0-d7,($FFFFFF10).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,($FFFFFF30).w
		cmpi.b	#$60,hintposi+1
		bcc.b	Demo_Time
		move.b	#1,($FFFFF64F).w
		addq.l	#4,sp
		bra.w	loc_B64

; ---------------------------------------------------------------------------
; Subroutine to	run a demo for an amount of time
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Demo_Time:
		bsr.w	scrollwrt
		jsr		efectwrt
		jsr		scoreset
		bsr.w	sub_165E
		tst.w	($FFFFF614).w	; is there time	left on	the demo?
		beq.w	Demo_TimeEnd	; if not, branch
		subq.w	#1,($FFFFF614).w ; subtract 1 from time	left

Demo_TimeEnd:
		rts

; ===========================================================================

loc_DA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_DAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.b	loc_DAE		; if not, branch
		bsr.w	ReadJoypads
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l
		bsr.w	PalCycle_SS
		tst.b	($FFFFF767).w
		beq.b	loc_E64
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.b	#0,($FFFFF767).w

loc_E64:
		tst.w	($FFFFF614).w
		beq.w	locret_E70
		subq.w	#1,($FFFFF614).w

locret_E70:
		rts	
; ===========================================================================

loc_E72:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_E7A:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.b	loc_E7A		; if not, branch
		bsr.w	ReadJoypads
		tst.b	waterflag
		bne.b	loc_EB4
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.b	loc_ED8
; ===========================================================================

loc_EB4:				; XREF: loc_E7A
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_ED8:				; XREF: loc_E7A
		move.w	hintposi,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)

loc_EEE:
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		tst.b	($FFFFF767).w
		beq.b	loc_F54
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.b	#0,($FFFFF767).w

loc_F54:
		move.w	#0,($A11100).l	; start	the Z80
		movem.l	scra_h_posit,d0-d7
		movem.l	d0-d7,($FFFFFF10).w
		movem.l	($FFFFF754).w,d0-d1
		movem.l	d0-d1,($FFFFFF30).w
		bsr.w	scrollwrt
		jsr	efectwrt
		jsr	scoreset
		bsr.w	sub_1642
		rts	
; ===========================================================================

loc_F8A:				; XREF: off_B6E
		bsr.w	sub_106E
		addq.b	#1,($FFFFF628).w
		move.b	#$E,($FFFFF62A).w
		rts	
; ===========================================================================

loc_F9A:				; XREF: off_B6E
		bsr.w	sub_106E
		move.w	hintposi,(a5)
		bra.w	sub_1642
; ===========================================================================

loc_FA6:				; XREF: off_B6E
		move.w	#$100,($A11100).l ; stop the Z80

loc_FAE:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.b	loc_FAE		; if not, branch
		bsr.w	ReadJoypads
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		tst.b	($FFFFF767).w
		beq.b	loc_1060
		lea	($C00004).l,a5
		move.l	#$94019370,(a5)
		move.l	#$96E49500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7000,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.b	#0,($FFFFF767).w

loc_1060:
		tst.w	($FFFFF614).w
		beq.w	locret_106C
		subq.w	#1,($FFFFF614).w

locret_106C:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_106E:				; XREF: loc_C32; et al
		move.w	#$100,($A11100).l ; stop the Z80

loc_1076:
		btst	#0,($A11100).l	; has Z80 stopped?
		bne.b	loc_1076	; if not, branch
		bsr.w	ReadJoypads
		tst.b	waterflag
		bne.b	loc_10B0
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9580,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		bra.b	loc_10D4
; ===========================================================================

loc_10B0:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94009340,(a5)
		move.l	#$96FD9540,(a5)
		move.w	#$977F,(a5)
		move.w	#$C000,(a5)
		move.w	#$80,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)

loc_10D4:				; XREF: sub_106E
		lea	($C00004).l,a5
		move.l	#$94019340,(a5)
		move.l	#$96FC9500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7800,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		lea	($C00004).l,a5
		move.l	#$940193C0,(a5)
		move.l	#$96E69500,(a5)
		move.w	#$977F,(a5)
		move.w	#$7C00,(a5)
		move.w	#$83,($FFFFF640).w
		move.w	($FFFFF640).w,(a5)
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function sub_106E

; ---------------------------------------------------------------------------
; Subroutine to	move pallets from the RAM to CRAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Hint:
		move	#$2700,sr
		tst.w	($FFFFF644).w
		beq.b	locret_119C
		move.w	#0,($FFFFF644).w
		movem.l	a0-a1,-(sp)
		lea	($C00000).l,a1
		lea	($FFFFFA80).w,a0 ; load	pallet from RAM
		move.l	#$C0000000,4(a1) ; set VDP to CRAM write
		move.l	(a0)+,(a1)	; move pallet to CRAM
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.l	(a0)+,(a1)
		move.w	#$8ADF,4(a1)
		movem.l	(sp)+,a0-a1
		tst.b	($FFFFF64F).w
		bne.b	loc_119E

locret_119C:
		rte	
; ===========================================================================

loc_119E:				; XREF: Hint
		clr.b	($FFFFF64F).w
		movem.l	d0-a6,-(sp)
		bsr.w	Demo_Time
		jsr	sub_71B4C
		movem.l	(sp)+,d0-a6
		rte	
; End of function Hint

; ---------------------------------------------------------------------------
; Subroutine to	initialise joypads
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


JoypadInit:				; XREF: GameClrRAM
		move.w	#$100,($A11100).l ; stop the Z80

Joypad_WaitZ80:
		btst	#0,($A11100).l	; has the Z80 stopped?
		bne.b	Joypad_WaitZ80	; if not, branch
		moveq	#$40,d0
		move.b	d0,($A10009).l	; init port 1 (joypad 1)
		move.b	d0,($A1000B).l	; init port 2 (joypad 2)
		move.b	d0,($A1000D).l	; init port 3 (extra)
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function JoypadInit

; ---------------------------------------------------------------------------
; Subroutine to	read joypad input, and send it to the RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ReadJoypads:
		lea	swdata1+0,a0 ; address where joypad	states are written
		lea	($A10003).l,a1	; first	joypad port
		bsr.b	Joypad_Read	; do the first joypad
		addq.w	#2,a1		; do the second	joypad

Joypad_Read:
		move.b	#0,(a1)
		nop	
		nop	
		move.b	(a1),d0
		lsl.b	#2,d0
		andi.b	#$C0,d0
		move.b	#$40,(a1)
		nop	
		nop	
		move.b	(a1),d1
		andi.b	#$3F,d1
		or.b	d1,d0
		not.b	d0
		move.b	(a0),d1
		eor.b	d0,d1
		move.b	d0,(a0)+
		and.b	d0,d1
		move.b	d1,(a0)+
		rts	
; End of function ReadJoypads


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


VDPSetupGame:				; XREF: GameClrRAM; ChecksumError
		lea	($C00004).l,a0
		lea	($C00000).l,a1
		lea	(VDPSetupArray).l,a2
		moveq	#$12,d7

VDP_Loop:
		move.w	(a2)+,(a0)
		dbra	d7,VDP_Loop	; set the VDP registers

		move.w	(VDPSetupArray+2).l,d0
		move.w	d0,($FFFFF60C).w
		move.w	#$8ADF,hintposi
		moveq	#0,d0
		move.l	#$C0000000,($C00004).l ; set VDP to CRAM write
		move.w	#$3F,d7

VDP_ClrCRAM:
		move.w	d0,(a1)
		dbra	d7,VDP_ClrCRAM	; clear	the CRAM

		clr.l	($FFFFF616).w
		clr.l	($FFFFF61A).w
		move.l	d1,-(sp)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$94FF93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000080,(a5)
		move.w	#0,($C00000).l	; clear	the screen

loc_128E:
		move.w	(a5),d1
		btst	#1,d1
		bne.b	loc_128E

		move.w	#$8F02,(a5)
		move.l	(sp)+,d1
		rts	
; End of function VDPSetupGame

; ===========================================================================
VDPSetupArray:	dc.w $8004, $8134, $8230, $8328	; XREF: VDPSetupGame
		dc.w $8407, $857C, $8600, $8700
		dc.w $8800, $8900, $8A00, $8B00
		dc.w $8C81, $8D3F, $8E00, $8F02
		dc.w $9001, $9100, $9200

; ---------------------------------------------------------------------------
; Subroutine to	clear the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


scrinit:
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$40000083,(a5)
		move.w	#0,($C00000).l

loc_12E6:
		move.w	(a5),d1
		btst	#1,d1
		bne.b	loc_12E6

		move.w	#$8F02,(a5)
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$940F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$60000083,(a5)
		move.w	#0,($C00000).l

loc_1314:
		move.w	(a5),d1
		btst	#1,d1
		bne.b	loc_1314

		move.w	#$8F02,(a5)
		move.l	#0,($FFFFF616).w
		move.l	#0,($FFFFF61A).w
		lea	($FFFFF800).w,a1
		moveq	#0,d0
		move.w	#$A0,d1

loc_133A:
		move.l	d0,(a1)+
		dbra	d1,loc_133A

		lea	($FFFFCC00).w,a1
		moveq	#0,d0
		move.w	#$100,d1

loc_134A:
		move.l	d0,(a1)+
		dbra	d1,loc_134A
		rts	
; End of function scrinit

; ---------------------------------------------------------------------------
; Subroutine to	load the sound driver
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SoundDriverLoad:			; XREF: GameClrRAM; TitleScreen
		nop	
		move.w	#$100,($A11100).l ; stop the Z80
		move.w	#$100,($A11200).l ; reset the Z80
		lea	(pcm_top).l,a0	; load sound driver
		lea	($A00000).l,a1
		bsr.w	KosDec		; decompress
		move.w	#0,($A11200).l
		nop	
		nop	
		nop	
		nop	
		move.w	#$100,($A11200).l ; reset the Z80
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function SoundDriverLoad

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


bgmset:
		move.b	d0,($FFFFF00A).w
		rts	
; End of function bgmset

; ---------------------------------------------------------------------------
; Subroutine to	play a special sound/music (E0-E4)
;
; E0 - Fade out
; E1 - Sega
; E2 - Speed up
; E3 - Normal speed
; E4 - Stop
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


soundset:
		move.b	d0,($FFFFF00B).w
		rts	
; End of function soundset

; ===========================================================================
; ---------------------------------------------------------------------------
; Unused sound/music subroutine
; ---------------------------------------------------------------------------

bgmset_Unk:
		move.b	d0,($FFFFF00C).w
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	pause the game
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PauseGame:				; XREF: Level_MainLoop; et al
		nop	
		tst.b	pl_suu	; do you have any lives	left?
		beq.b	Unpause		; if not, branch
		tst.w	pauseflag	; is game already paused?
		bne.b	loc_13BE	; if yes, branch
		btst	#7,swdata1+1 ; is Start button pressed?
		beq.b	Pause_DoNothing	; if not, branch

loc_13BE:
		move.w	#1,pauseflag ; freeze time
		move.b	#1,($FFFFF003).w ; pause music

loc_13CA:
		move.b	#$10,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.b	($FFFFFFE1).w	; is slow-motion cheat on?
		beq.b	Pause_ChkStart	; if not, branch
		btst	#6,swdata1+1 ; is button A pressed?
		beq.b	Pause_ChkBC	; if not, branch
		move.b	#4,gmmode ; set game mode to 4 (title screen)
		nop	
		bra.b	loc_1404
; ===========================================================================

Pause_ChkBC:				; XREF: PauseGame
		btst	#4,swdata1+0 ; is button B pressed?
		bne.b	Pause_SlowMo	; if yes, branch
		btst	#5,swdata1+1 ; is button C pressed?
		bne.b	Pause_SlowMo	; if yes, branch

Pause_ChkStart:				; XREF: PauseGame
		btst	#7,swdata1+1 ; is Start button pressed?
		beq.b	loc_13CA	; if not, branch

loc_1404:				; XREF: PauseGame
		move.b	#$80,($FFFFF003).w

Unpause:				; XREF: PauseGame
		move.w	#0,pauseflag ; unpause the game

Pause_DoNothing:			; XREF: PauseGame
		rts	
; ===========================================================================

Pause_SlowMo:				; XREF: PauseGame
		move.w	#1,pauseflag
		move.b	#$80,($FFFFF003).w
		rts	
; End of function PauseGame

; ---------------------------------------------------------------------------
; Subroutine to	display	patterns via the VDP
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ShowVDPGraphics:			; XREF: SegaScreen; TitleScreen; SS_BGLoad
		lea	($C00000).l,a6
		move.l	#$800000,d4

loc_142C:
		move.l	d0,4(a6)
		move.w	d1,d3

loc_1432:
		move.w	(a1)+,(a6)
		dbra	d3,loc_1432
		add.l	d4,d0
		dbra	d2,loc_142C
		rts	
; End of function ShowVDPGraphics

; ---------------------------------------------------------------------------
; Nemesis decompression	algorithm
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


NemDec:
		movem.l	d0-a1/a3-a5,-(sp)
		lea	(loc_1502).l,a3
		lea	($C00000).l,a4
		bra.b	loc_145C
; ===========================================================================
		movem.l	d0-a1/a3-a5,-(sp)
		lea	(loc_1518).l,a3

loc_145C:				; XREF: NemDec
		lea	($FFFFAA00).w,a1
		move.w	(a0)+,d2
		lsl.w	#1,d2
		bcc.b	loc_146A
		adda.w	#$A,a3

loc_146A:
		lsl.w	#2,d2
		movea.w	d2,a5
		moveq	#8,d3
		moveq	#0,d2
		moveq	#0,d4
		bsr.w	NemDec4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		move.w	#$10,d6
		bsr.b	NemDec2
		movem.l	(sp)+,d0-a1/a3-a5
		rts	
; End of function NemDec


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


NemDec2:				; XREF: NemDec
		move.w	d6,d7
		subq.w	#8,d7
		move.w	d5,d1
		lsr.w	d7,d1
		cmpi.b	#-4,d1
		bcc.b	loc_14D6
		andi.w	#$FF,d1
		add.w	d1,d1
		move.b	(a1,d1.w),d0
		ext.w	d0
		sub.w	d0,d6
		cmpi.w	#9,d6
		bcc.b	loc_14B2
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

loc_14B2:
		move.b	1(a1,d1.w),d1
		move.w	d1,d0
		andi.w	#$F,d1
		andi.w	#$F0,d0

loc_14C0:				; XREF: NemDec3
		lsr.w	#4,d0

loc_14C2:				; XREF: NemDec3
		lsl.l	#4,d4
		or.b	d1,d4
		subq.w	#1,d3
		bne.b	loc_14D0
		jmp	(a3)
; End of function NemDec2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


NemDec3:				; XREF: loc_1502
		moveq	#0,d4
		moveq	#8,d3

loc_14D0:				; XREF: NemDec2
		dbra	d0,loc_14C2
		bra.b	NemDec2
; ===========================================================================

loc_14D6:				; XREF: NemDec2
		subq.w	#6,d6
		cmpi.w	#9,d6
		bcc.b	loc_14E4
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

loc_14E4:				; XREF: NemDec3
		subq.w	#7,d6
		move.w	d5,d1
		lsr.w	d6,d1
		move.w	d1,d0
		andi.w	#$F,d1
		andi.w	#$70,d0
		cmpi.w	#9,d6
		bcc.b	loc_14C0
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5
		bra.b	loc_14C0
; End of function NemDec3

; ===========================================================================

loc_1502:				; XREF: NemDec
		move.l	d4,(a4)
		subq.w	#1,a5
		move.w	a5,d4
		bne.b	NemDec3
		rts	
; ===========================================================================
		eor.l	d4,d2
		move.l	d2,(a4)
		subq.w	#1,a5
		move.w	a5,d4
		bne.b	NemDec3
		rts	
; ===========================================================================

loc_1518:				; XREF: NemDec
		move.l	d4,(a4)+
		subq.w	#1,a5
		move.w	a5,d4
		bne.b	NemDec3
		rts	
; ===========================================================================
		eor.l	d4,d2
		move.l	d2,(a4)+
		subq.w	#1,a5
		move.w	a5,d4
		bne.b	NemDec3
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


NemDec4:				; XREF: NemDec
		move.b	(a0)+,d0

loc_1530:
		cmpi.b	#-1,d0
		bne.b	loc_1538
		rts	
; ===========================================================================

loc_1538:				; XREF: NemDec4
		move.w	d0,d7

loc_153A:
		move.b	(a0)+,d0
		cmpi.b	#$80,d0
		bcc.b	loc_1530
		move.b	d0,d1
		andi.w	#$F,d7
		andi.w	#$70,d1
		or.w	d1,d7
		andi.w	#$F,d0
		move.b	d0,d1
		lsl.w	#8,d1
		or.w	d1,d7
		moveq	#8,d1
		sub.w	d0,d1
		bne.b	loc_1568
		move.b	(a0)+,d0
		add.w	d0,d0
		move.w	d7,(a1,d0.w)
		bra.b	loc_153A
; ===========================================================================

loc_1568:				; XREF: NemDec4
		move.b	(a0)+,d0
		lsl.w	d1,d0
		add.w	d0,d0
		moveq	#1,d5
		lsl.w	d1,d5
		subq.w	#1,d5

loc_1574:
		move.w	d7,(a1,d0.w)
		addq.w	#2,d0
		dbra	d5,loc_1574
		bra.b	loc_153A
; End of function NemDec4

; ---------------------------------------------------------------------------
; Subroutine to	load pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC:
		movem.l	a1-a2,-(sp)
		lea	(divdevtbl).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		lea	($FFFFF680).w,a2

loc_1598:
		tst.l	(a2)
		beq.b	loc_15A0
		addq.w	#6,a2
		bra.b	loc_1598
; ===========================================================================

loc_15A0:				; XREF: LoadPLC
		move.w	(a1)+,d0
		bmi.b	loc_15AC

loc_15A4:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbra	d0,loc_15A4

loc_15AC:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadPLC2:
		movem.l	a1-a2,-(sp)
		lea	(divdevtbl).l,a1
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		bsr.b	ClearPLC
		lea	($FFFFF680).w,a2
		move.w	(a1)+,d0
		bmi.b	loc_15D8

loc_15D0:
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		dbra	d0,loc_15D0

loc_15D8:
		movem.l	(sp)+,a1-a2
		rts	
; End of function LoadPLC2

; ---------------------------------------------------------------------------
; Subroutine to	clear the pattern load cues
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ClearPLC:				; XREF: LoadPLC2
		lea	($FFFFF680).w,a2
		moveq	#$1F,d0

ClearPLC_Loop:
		clr.l	(a2)+
		dbra	d0,ClearPLC_Loop
		rts	
; End of function ClearPLC

; ---------------------------------------------------------------------------
; Subroutine to	use graphics listed in a pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_RAM:				; XREF: fadeout
		tst.l	($FFFFF680).w
		beq.b	locret_1640
		tst.w	($FFFFF6F8).w
		bne.b	locret_1640
		movea.l	($FFFFF680).w,a0
		lea	(loc_1502).l,a3
		lea	($FFFFAA00).w,a1
		move.w	(a0)+,d2
		bpl.b	loc_160E
		adda.w	#$A,a3

loc_160E:
		andi.w	#$7FFF,d2
		move.w	d2,($FFFFF6F8).w
		bsr.w	NemDec4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6
		moveq	#0,d0
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d0,($FFFFF6E8).w
		move.l	d0,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_1640:
		rts	
; End of function RunPLC_RAM


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1642:				; XREF: loc_C44; loc_F54; loc_F9A
		tst.w	($FFFFF6F8).w
		beq.w	locret_16DA
		move.w	#9,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$120,($FFFFF684).w
		bra.b	loc_1676
; End of function sub_1642


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_165E:				; XREF: Demo_Time
		tst.w	($FFFFF6F8).w
		beq.b	locret_16DA
		move.w	#3,($FFFFF6FA).w
		moveq	#0,d0
		move.w	($FFFFF684).w,d0
		addi.w	#$60,($FFFFF684).w

loc_1676:				; XREF: sub_1642
		lea	($C00004).l,a4
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,(a4)
		subq.w	#4,a4
		movea.l	($FFFFF680).w,a0
		movea.l	($FFFFF6E0).w,a3
		move.l	($FFFFF6E4).w,d0
		move.l	($FFFFF6E8).w,d1
		move.l	($FFFFF6EC).w,d2
		move.l	($FFFFF6F0).w,d5
		move.l	($FFFFF6F4).w,d6
		lea	($FFFFAA00).w,a1

loc_16AA:				; XREF: sub_165E
		movea.w	#8,a5
		bsr.w	NemDec3
		subq.w	#1,($FFFFF6F8).w
		beq.b	loc_16DC
		subq.w	#1,($FFFFF6FA).w
		bne.b	loc_16AA
		move.l	a0,($FFFFF680).w
		move.l	a3,($FFFFF6E0).w
		move.l	d0,($FFFFF6E4).w
		move.l	d1,($FFFFF6E8).w
		move.l	d2,($FFFFF6EC).w
		move.l	d5,($FFFFF6F0).w
		move.l	d6,($FFFFF6F4).w

locret_16DA:				; XREF: sub_1642
		rts	
; ===========================================================================

loc_16DC:				; XREF: sub_165E
		lea	($FFFFF680).w,a0
		moveq	#$15,d0

loc_16E2:				; XREF: sub_165E
		move.l	6(a0),(a0)+
		dbra	d0,loc_16E2
		rts	
; End of function sub_165E

; ---------------------------------------------------------------------------
; Subroutine to	execute	the pattern load cue
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


RunPLC_ROM:
		lea	(divdevtbl).l,a1 ; load the PLC index
		add.w	d0,d0
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		move.w	(a1)+,d1	; load number of entries in the	PLC

RunPLC_Loop:
		movea.l	(a1)+,a0	; get art pointer
		moveq	#0,d0
		move.w	(a1)+,d0	; get VRAM address
		lsl.l	#2,d0		; divide address by $20
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,($C00004).l	; put the VRAM address into VDP
		bsr.w	NemDec		; decompress
		dbra	d1,RunPLC_Loop	; loop for number of entries
		rts	
; End of function RunPLC_ROM

; ---------------------------------------------------------------------------
; Enigma decompression algorithm
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mapdevr:
		movem.l	d0-d7/a1-a5,-(sp)
		movea.w	d0,a3
		move.b	(a0)+,d0
		ext.w	d0
		movea.w	d0,a5
		move.b	(a0)+,d4
		lsl.b	#3,d4
		movea.w	(a0)+,a2
		adda.w	a3,a2
		movea.w	(a0)+,a4
		adda.w	a3,a4
		move.b	(a0)+,d5
		asl.w	#8,d5
		move.b	(a0)+,d5
		moveq	#$10,d6

loc_173E:				; XREF: loc_1768
		moveq	#7,d0
		move.w	d6,d7
		sub.w	d0,d7
		move.w	d5,d1
		lsr.w	d7,d1
		andi.w	#$7F,d1
		move.w	d1,d2
		cmpi.w	#$40,d1
		bcc.b	loc_1758
		moveq	#6,d0
		lsr.w	#1,d2

loc_1758:
		bsr.w	sub_188C
		andi.w	#$F,d2
		lsr.w	#4,d1
		add.w	d1,d1
		jmp	loc_17B4(pc,d1.w)
; End of function mapdevr

; ===========================================================================

loc_1768:				; XREF: loc_17B4
		move.w	a2,(a1)+
		addq.w	#1,a2
		dbra	d2,loc_1768
		bra.b	loc_173E
; ===========================================================================

loc_1772:				; XREF: loc_17B4
		move.w	a4,(a1)+
		dbra	d2,loc_1772
		bra.b	loc_173E
; ===========================================================================

loc_177A:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_177E:
		move.w	d1,(a1)+
		dbra	d2,loc_177E
		bra.b	loc_173E
; ===========================================================================

loc_1786:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_178A:
		move.w	d1,(a1)+
		addq.w	#1,d1
		dbra	d2,loc_178A
		bra.b	loc_173E
; ===========================================================================

loc_1794:				; XREF: loc_17B4
		bsr.w	loc_17DC

loc_1798:
		move.w	d1,(a1)+
		subq.w	#1,d1
		dbra	d2,loc_1798
		bra.b	loc_173E
; ===========================================================================

loc_17A2:				; XREF: loc_17B4
		cmpi.w	#$F,d2
		beq.b	loc_17C4

loc_17A8:
		bsr.w	loc_17DC
		move.w	d1,(a1)+
		dbra	d2,loc_17A8
		bra.b	loc_173E
; ===========================================================================

loc_17B4:				; XREF: mapdevr
		bra.b	loc_1768
; ===========================================================================
		bra.b	loc_1768
; ===========================================================================
		bra.b	loc_1772
; ===========================================================================
		bra.b	loc_1772
; ===========================================================================
		bra.b	loc_177A
; ===========================================================================
		bra.b	loc_1786
; ===========================================================================
		bra.b	loc_1794
; ===========================================================================
		bra.b	loc_17A2
; ===========================================================================

loc_17C4:				; XREF: loc_17A2
		subq.w	#1,a0
		cmpi.w	#$10,d6
		bne.b	loc_17CE
		subq.w	#1,a0

loc_17CE:
		move.w	a0,d0
		lsr.w	#1,d0
		bcc.b	loc_17D6
		addq.w	#1,a0

loc_17D6:
		movem.l	(sp)+,d0-d7/a1-a5
		rts	
; ===========================================================================

loc_17DC:				; XREF: loc_17A2
		move.w	a3,d3
		move.b	d4,d1
		add.b	d1,d1
		bcc.b	loc_17EE
		subq.w	#1,d6
		btst	d6,d5
		beq.b	loc_17EE
		ori.w	#-$8000,d3

loc_17EE:
		add.b	d1,d1
		bcc.b	loc_17FC
		subq.w	#1,d6
		btst	d6,d5
		beq.b	loc_17FC
		addi.w	#$4000,d3

loc_17FC:
		add.b	d1,d1
		bcc.b	loc_180A
		subq.w	#1,d6
		btst	d6,d5
		beq.b	loc_180A
		addi.w	#$2000,d3

loc_180A:
		add.b	d1,d1
		bcc.b	loc_1818
		subq.w	#1,d6
		btst	d6,d5
		beq.b	loc_1818
		ori.w	#$1000,d3

loc_1818:
		add.b	d1,d1
		bcc.b	loc_1826
		subq.w	#1,d6
		btst	d6,d5
		beq.b	loc_1826
		ori.w	#$800,d3

loc_1826:
		move.w	d5,d1
		move.w	d6,d7
		sub.w	a5,d7
		bcc.b	loc_1856
		move.w	d7,d6
		addi.w	#$10,d6
		neg.w	d7
		lsl.w	d7,d1
		move.b	(a0),d5
		rol.b	d7,d5
		add.w	d7,d7
		and.w	word_186C-2(pc,d7.w),d5
		add.w	d5,d1

loc_1844:				; XREF: loc_1868
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.b	(a0)+,d5
		lsl.w	#8,d5
		move.b	(a0)+,d5
		rts	
; ===========================================================================

loc_1856:				; XREF: loc_1826
		beq.b	loc_1868
		lsr.w	d7,d1
		move.w	a5,d0
		add.w	d0,d0
		and.w	word_186C-2(pc,d0.w),d1
		add.w	d3,d1
		move.w	a5,d0
		bra.b	sub_188C
; ===========================================================================

loc_1868:				; XREF: loc_1856
		moveq	#$10,d6

loc_186A:
		bra.b	loc_1844
; ===========================================================================
word_186C:	dc.w 1,	3, 7, $F, $1F, $3F, $7F, $FF, $1FF, $3FF, $7FF
		dc.w $FFF, $1FFF, $3FFF, $7FFF,	$FFFF	; XREF: loc_1856

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_188C:				; XREF: mapdevr
		sub.w	d0,d6
		cmpi.w	#9,d6
		bcc.b	locret_189A
		addq.w	#8,d6
		asl.w	#8,d5
		move.b	(a0)+,d5

locret_189A:
		rts	
; End of function sub_188C

; ---------------------------------------------------------------------------
; Kosinski decompression algorithm
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


KosDec:

var_2		= -2
var_1		= -1

		subq.l	#2,sp
		move.b	(a0)+,2+var_1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

loc_18A8:
		lsr.w	#1,d5
		move	sr,d6
		dbra	d4,loc_18BA
		move.b	(a0)+,2+var_1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

loc_18BA:
		move	d6,ccr
		bcc.b	loc_18C2
		move.b	(a0)+,(a1)+
		bra.b	loc_18A8
; ===========================================================================

loc_18C2:				; XREF: KosDec
		moveq	#0,d3
		lsr.w	#1,d5
		move	sr,d6
		dbra	d4,loc_18D6
		move.b	(a0)+,2+var_1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

loc_18D6:
		move	d6,ccr
		bcs.b	loc_1906
		lsr.w	#1,d5
		dbra	d4,loc_18EA
		move.b	(a0)+,2+var_1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

loc_18EA:
		roxl.w	#1,d3
		lsr.w	#1,d5
		dbra	d4,loc_18FC
		move.b	(a0)+,2+var_1(sp)
		move.b	(a0)+,(sp)
		move.w	(sp),d5
		moveq	#$F,d4

loc_18FC:
		roxl.w	#1,d3
		addq.w	#1,d3
		moveq	#-1,d2
		move.b	(a0)+,d2
		bra.b	loc_191C
; ===========================================================================

loc_1906:				; XREF: loc_18C2
		move.b	(a0)+,d0
		move.b	(a0)+,d1
		moveq	#-1,d2
		move.b	d1,d2
		lsl.w	#5,d2
		move.b	d0,d2
		andi.w	#7,d1
		beq.b	loc_1928
		move.b	d1,d3
		addq.w	#1,d3

loc_191C:
		move.b	(a1,d2.w),d0
		move.b	d0,(a1)+
		dbra	d3,loc_191C
		bra.b	loc_18A8
; ===========================================================================

loc_1928:				; XREF: loc_1906
		move.b	(a0)+,d1
		beq.b	loc_1938
		cmpi.b	#1,d1
		beq.w	loc_18A8
		move.b	d1,d3
		bra.b	loc_191C
; ===========================================================================

loc_1938:				; XREF: loc_1928
		addq.l	#2,sp
		rts	
; End of function KosDec

; ---------------------------------------------------------------------------
; Pallet cycling routine loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


clchgctr:				; XREF: Demo; Level_MainLoop; End_MainLoop
		moveq	#0,d2
		moveq	#0,d0
		move.b	stageno,d0 ; get level number
		add.w	d0,d0		; multiply by 2
		move.w	PalCycle(pc,d0.w),d0 ; load animated pallets offset index into d0
		jmp	PalCycle(pc,d0.w) ; jump to PalCycle + offset index
; End of function clchgctr

; ===========================================================================
; ---------------------------------------------------------------------------
; Pallet cycling routines
; ---------------------------------------------------------------------------
PalCycle:	dc.w PalCycle_GHZ-PalCycle
		dc.w PalCycle_LZ-PalCycle
		dc.w PalCycle_MZ-PalCycle
		dc.w PalCycle_SLZ-PalCycle
		dc.w PalCycle_SYZ-PalCycle
		dc.w PalCycle_SBZ-PalCycle
		dc.w PalCycle_GHZ-PalCycle

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Title:				; XREF: TitleScreen
		lea	(Pal_TitleCyc).l,a0
		bra.b	loc_196A
; ===========================================================================

PalCycle_GHZ:				; XREF: PalCycle
		lea	(zone1colorCyc).l,a0

loc_196A:				; XREF: PalCycle_Title
		subq.w	#1,($FFFFF634).w
		bpl.b	locret_1990
		move.w	#5,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#3,d0
		lsl.w	#3,d0
		lea	($FFFFFB50).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)

locret_1990:
		rts	
; End of function PalCycle_Title


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_LZ:				; XREF: PalCycle
		subq.w	#1,($FFFFF634).w
		bpl.b	loc_19D8
		move.w	#2,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#3,d0
		lsl.w	#3,d0
		lea	(zone2colorCyc1).l,a0
		cmpi.b	#3,stageno+1 ; check if level is SBZ3
		bne.b	loc_19C0
		lea	(zone24colorCyc1).l,a0 ; load SBZ3	pallet instead

loc_19C0:
		lea	($FFFFFB56).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)
		lea	($FFFFFAD6).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)

loc_19D8:
		move.w	gametimer,d0
		andi.w	#7,d0
		move.b	byte_1A3C(pc,d0.w),d0
		beq.b	locret_1A3A
		moveq	#1,d1
		tst.b	($FFFFF7C0).w
		beq.b	loc_19F0
		neg.w	d1

loc_19F0:
		move.w	($FFFFF650).w,d0
		andi.w	#3,d0
		add.w	d1,d0
		cmpi.w	#3,d0
		bcs.b	loc_1A0A
		move.w	d0,d1
		moveq	#0,d0
		tst.w	d1
		bpl.b	loc_1A0A
		moveq	#2,d0

loc_1A0A:
		move.w	d0,($FFFFF650).w
		add.w	d0,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	(zone2colorCyc2).l,a0
		lea	($FFFFFB76).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)
		lea	(zone2colorCyc3).l,a0
		lea	($FFFFFAF6).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)

locret_1A3A:
		rts	
; End of function PalCycle_LZ

; ===========================================================================
byte_1A3C:	dc.b 1,	0, 0, 1, 0, 0, 1, 0
; ===========================================================================

PalCycle_MZ:				; XREF: PalCycle
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_SLZ:				; XREF: PalCycle
		subq.w	#1,($FFFFF634).w
		bpl.b	locret_1A80
		move.w	#7,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,d0
		cmpi.w	#6,d0
		bcs.b	loc_1A60
		moveq	#0,d0

loc_1A60:
		move.w	d0,($FFFFF632).w
		move.w	d0,d1
		add.w	d1,d1
		add.w	d1,d0
		add.w	d0,d0
		lea	(zone4colorCyc).l,a0
		lea	($FFFFFB56).w,a1
		move.w	(a0,d0.w),(a1)
		move.l	2(a0,d0.w),4(a1)

locret_1A80:
		rts	
; End of function PalCycle_SLZ


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_SYZ:				; XREF: PalCycle
		subq.w	#1,($FFFFF634).w
		bpl.b	locret_1AC6
		move.w	#5,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addq.w	#1,($FFFFF632).w
		andi.w	#3,d0
		lsl.w	#2,d0
		move.w	d0,d1
		add.w	d0,d0
		lea	(zone5colorCyc1).l,a0
		lea	($FFFFFB6E).w,a1
		move.l	(a0,d0.w),(a1)+
		move.l	4(a0,d0.w),(a1)
		lea	(zone5colorCyc2).l,a0
		lea	($FFFFFB76).w,a1
		move.w	(a0,d1.w),(a1)
		move.w	2(a0,d1.w),4(a1)

locret_1AC6:
		rts	
; End of function PalCycle_SYZ


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_SBZ:				; XREF: PalCycle
		lea	(Pal_SBZCycList).l,a2
		tst.b	stageno+1
		beq.b	loc_1ADA
		lea	(Pal_SBZCycList2).l,a2

loc_1ADA:
		lea	($FFFFF650).w,a1
		move.w	(a2)+,d1

loc_1AE0:
		subq.b	#1,(a1)
		bmi.b	loc_1AEA
		addq.l	#2,a1
		addq.l	#6,a2
		bra.b	loc_1B06
; ===========================================================================

loc_1AEA:				; XREF: PalCycle_SBZ
		move.b	(a2)+,(a1)+
		move.b	(a1),d0
		addq.b	#1,d0
		cmp.b	(a2)+,d0
		bcs.b	loc_1AF6
		moveq	#0,d0

loc_1AF6:
		move.b	d0,(a1)+
		andi.w	#$F,d0
		add.w	d0,d0
		movea.w	(a2)+,a0
		movea.w	(a2)+,a3
		move.w	(a0,d0.w),(a3)

loc_1B06:				; XREF: PalCycle_SBZ
		dbra	d1,loc_1AE0
		subq.w	#1,($FFFFF634).w
		bpl.b	locret_1B64
		lea	(Pal_SBZCyc4).l,a0
		move.w	#1,($FFFFF634).w
		tst.b	stageno+1
		beq.b	loc_1B2E
		lea	(Pal_SBZCyc10).l,a0
		move.w	#0,($FFFFF634).w

loc_1B2E:
		moveq	#-1,d1
		tst.b	($FFFFF7C0).w
		beq.b	loc_1B38
		neg.w	d1

loc_1B38:
		move.w	($FFFFF632).w,d0
		andi.w	#3,d0
		add.w	d1,d0
		cmpi.w	#3,d0
		bcs.b	loc_1B52
		move.w	d0,d1
		moveq	#0,d0
		tst.w	d1
		bpl.b	loc_1B52
		moveq	#2,d0

loc_1B52:
		move.w	d0,($FFFFF632).w
		add.w	d0,d0
		lea	($FFFFFB58).w,a1
		move.l	(a0,d0.w),(a1)+
		move.w	4(a0,d0.w),(a1)

locret_1B64:
		rts	
; End of function PalCycle_SBZ

; ===========================================================================
Pal_TitleCyc:	incbin	pallet\c_title.bin
zone1colorCyc:	incbin	pallet\c_ghz.bin
zone2colorCyc1:	incbin	pallet\c_lz_wat.bin	; waterfalls pallet
zone2colorCyc2:	incbin	pallet\c_lz_bel.bin	; conveyor belt pallet
zone2colorCyc3:	incbin	pallet\c_lz_buw.bin	; conveyor belt (underwater) pallet
zone24colorCyc1:	incbin	pallet\c_sbz3_w.bin	; waterfalls pallet
zone4colorCyc:	incbin	pallet\c_slz.bin
zone5colorCyc1:	incbin	pallet\c_syz_1.bin
zone5colorCyc2:	incbin	pallet\c_syz_2.bin

Pal_SBZCycList:
	include "_inc\SBZ pallet script 1.asm"

Pal_SBZCycList2:
	include "_inc\SBZ pallet script 2.asm"

Pal_SBZCyc1:	incbin	pallet\c_sbz_1.bin
Pal_SBZCyc2:	incbin	pallet\c_sbz_2.bin
Pal_SBZCyc3:	incbin	pallet\c_sbz_3.bin
Pal_SBZCyc4:	incbin	pallet\c_sbz_4.bin
Pal_SBZCyc5:	incbin	pallet\c_sbz_5.bin
Pal_SBZCyc6:	incbin	pallet\c_sbz_6.bin
Pal_SBZCyc7:	incbin	pallet\c_sbz_7.bin
Pal_SBZCyc8:	incbin	pallet\c_sbz_8.bin
Pal_SBZCyc9:	incbin	pallet\c_sbz_9.bin
Pal_SBZCyc10:	incbin	pallet\c_sbz_10.bin
; ---------------------------------------------------------------------------
; Subroutine to	fade out and fade in
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


fadeout:
		move.w	#$3F,($FFFFF626).w

fadeout2:
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		moveq	#0,d1
		move.b	($FFFFF627).w,d0

Pal_ToBlack:
		move.w	d1,(a0)+
		dbra	d0,Pal_ToBlack	; fill pallet with $000	(black)

		move.w	#$15,d4

loc_1DCE:
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.b	Pal_FadeIn
		bsr.w	RunPLC_RAM
		dbra	d4,loc_1DCE
		rts	
; End of function fadeout

; ---------------------------------------------------------------------------
; Pallet fade-in subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeIn:				; XREF: fadeout
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		lea	($FFFFFB80).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1DFA:
		bsr.b	Pal_AddColor
		dbra	d0,loc_1DFA
		cmpi.b	#1,stageno
		bne.b	locret_1E24
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		lea	($FFFFFA00).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1E1E:
		bsr.b	Pal_AddColor
		dbra	d0,loc_1E1E

locret_1E24:
		rts	
; End of function Pal_FadeIn


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor:				; XREF: Pal_FadeIn
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.b	loc_1E4E
		move.w	d3,d1
		addi.w	#$200,d1	; increase blue	value
		cmp.w	d2,d1		; has blue reached threshold level?
		bhi.b	Pal_AddGreen	; if yes, branch
		move.w	d1,(a0)+	; update pallet
		rts	
; ===========================================================================

Pal_AddGreen:				; XREF: Pal_AddColor
		move.w	d3,d1
		addi.w	#$20,d1		; increase green value
		cmp.w	d2,d1
		bhi.b	Pal_AddRed
		move.w	d1,(a0)+	; update pallet
		rts	
; ===========================================================================

Pal_AddRed:				; XREF: Pal_AddGreen
		addq.w	#2,(a0)+	; increase red value
		rts	
; ===========================================================================

loc_1E4E:				; XREF: Pal_AddColor
		addq.w	#2,a0
		rts	
; End of function Pal_AddColor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


fadein:
		move.w	#$3F,($FFFFF626).w
		move.w	#$15,d4

loc_1E5C:
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.b	Pal_FadeOut
		bsr.w	RunPLC_RAM
		dbra	d4,loc_1E5C
		rts	
; End of function fadein

; ---------------------------------------------------------------------------
; Pallet fade-out subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_FadeOut:				; XREF: fadein
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1E82:
		bsr.b	Pal_DecColor
		dbra	d0,loc_1E82

		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1E98:
		bsr.b	Pal_DecColor
		dbra	d0,loc_1E98
		rts	
; End of function Pal_FadeOut


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor:				; XREF: Pal_FadeOut
		move.w	(a0),d2
		beq.b	loc_1ECC
		move.w	d2,d1
		andi.w	#$E,d1
		beq.b	Pal_DecGreen
		subq.w	#2,(a0)+	; decrease red value
		rts	
; ===========================================================================

Pal_DecGreen:				; XREF: Pal_DecColor
		move.w	d2,d1
		andi.w	#$E0,d1
		beq.b	Pal_DecBlue
		subi.w	#$20,(a0)+	; decrease green value
		rts	
; ===========================================================================

Pal_DecBlue:				; XREF: Pal_DecGreen
		move.w	d2,d1
		andi.w	#$E00,d1
		beq.b	loc_1ECC
		subi.w	#$200,(a0)+	; decrease blue	value
		rts	
; ===========================================================================

loc_1ECC:				; XREF: Pal_DecColor
		addq.w	#2,a0
		rts	
; End of function Pal_DecColor

; ---------------------------------------------------------------------------
; Subroutine to	fill the pallet	with white (special stage)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_MakeWhite:				; XREF: SpecialStage
		move.w	#$3F,($FFFFF626).w
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.w	#$EEE,d1
		move.b	($FFFFF627).w,d0

PalWhite_Loop:
		move.w	d1,(a0)+
		dbra	d0,PalWhite_Loop
		move.w	#$15,d4

loc_1EF4:
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.b	Pal_WhiteToBlack
		bsr.w	RunPLC_RAM
		dbra	d4,loc_1EF4
		rts	
; End of function Pal_MakeWhite


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_WhiteToBlack:			; XREF: Pal_MakeWhite
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		lea	($FFFFFB80).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1F20:
		bsr.b	Pal_DecColor2
		dbra	d0,loc_1F20

		cmpi.b	#1,stageno
		bne.b	locret_1F4A
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		lea	($FFFFFA00).w,a1
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		adda.w	d0,a1
		move.b	($FFFFF627).w,d0

loc_1F44:
		bsr.b	Pal_DecColor2
		dbra	d0,loc_1F44

locret_1F4A:
		rts	
; End of function Pal_WhiteToBlack


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_DecColor2:				; XREF: Pal_WhiteToBlack
		move.w	(a1)+,d2
		move.w	(a0),d3
		cmp.w	d2,d3
		beq.b	loc_1F78
		move.w	d3,d1
		subi.w	#$200,d1	; decrease blue	value
		bcs.b	loc_1F64
		cmp.w	d2,d1
		bcs.b	loc_1F64
		move.w	d1,(a0)+
		rts	
; ===========================================================================

loc_1F64:				; XREF: Pal_DecColor2
		move.w	d3,d1
		subi.w	#$20,d1		; decrease green value
		bcs.b	loc_1F74
		cmp.w	d2,d1
		bcs.b	loc_1F74
		move.w	d1,(a0)+
		rts	
; ===========================================================================

loc_1F74:				; XREF: loc_1F64
		subq.w	#2,(a0)+	; decrease red value
		rts	
; ===========================================================================

loc_1F78:				; XREF: Pal_DecColor2
		addq.w	#2,a0
		rts	
; End of function Pal_DecColor2

; ---------------------------------------------------------------------------
; Subroutine to	make a white flash when	you enter a special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_MakeFlash:				; XREF: SpecialStage
		move.w	#$3F,($FFFFF626).w
		move.w	#$15,d4

loc_1F86:
		move.b	#$12,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.b	flashout
		bsr.w	RunPLC_RAM
		dbra	d4,loc_1F86
		rts	
; End of function Pal_MakeFlash


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


flashout:				; XREF: Pal_MakeFlash
		moveq	#0,d0
		lea	($FFFFFB00).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1FAC:
		bsr.b	Pal_AddColor2
		dbra	d0,loc_1FAC
		moveq	#0,d0
		lea	($FFFFFA80).w,a0
		move.b	($FFFFF626).w,d0
		adda.w	d0,a0
		move.b	($FFFFF627).w,d0

loc_1FC2:
		bsr.b	Pal_AddColor2
		dbra	d0,loc_1FC2
		rts	
; End of function flashout


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Pal_AddColor2:				; XREF: flashout
		move.w	(a0),d2
		cmpi.w	#$EEE,d2
		beq.b	loc_2006
		move.w	d2,d1
		andi.w	#$E,d1
		cmpi.w	#$E,d1
		beq.b	loc_1FE2
		addq.w	#2,(a0)+	; increase red value
		rts	
; ===========================================================================

loc_1FE2:				; XREF: Pal_AddColor2
		move.w	d2,d1
		andi.w	#$E0,d1
		cmpi.w	#$E0,d1
		beq.b	loc_1FF4
		addi.w	#$20,(a0)+	; increase green value
		rts	
; ===========================================================================

loc_1FF4:				; XREF: loc_1FE2
		move.w	d2,d1
		andi.w	#$E00,d1
		cmpi.w	#$E00,d1
		beq.b	loc_2006
		addi.w	#$200,(a0)+	; increase blue	value
		rts	
; ===========================================================================

loc_2006:				; XREF: Pal_AddColor2
		addq.w	#2,a0
		rts	
; End of function Pal_AddColor2

; ---------------------------------------------------------------------------
; Pallet cycling routine - Sega	logo
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_Sega:				; XREF: SegaScreen
		tst.b	($FFFFF635).w
		bne.b	loc_206A
		lea	($FFFFFB20).w,a1
		lea	(Pal_Sega1).l,a0
		moveq	#5,d1
		move.w	($FFFFF632).w,d0

loc_2020:
		bpl.b	loc_202A
		addq.w	#2,a0
		subq.w	#1,d1
		addq.w	#2,d0
		bra.b	loc_2020
; ===========================================================================

loc_202A:				; XREF: PalCycle_Sega
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.b	loc_2034
		addq.w	#2,d0

loc_2034:
		cmpi.w	#$60,d0
		bcc.b	loc_203E
		move.w	(a0)+,(a1,d0.w)

loc_203E:
		addq.w	#2,d0
		dbra	d1,loc_202A
		move.w	($FFFFF632).w,d0
		addq.w	#2,d0
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.b	loc_2054
		addq.w	#2,d0

loc_2054:
		cmpi.w	#$64,d0
		blt.b	loc_2062
		move.w	#$401,($FFFFF634).w
		moveq	#-$C,d0

loc_2062:
		move.w	d0,($FFFFF632).w
		moveq	#1,d0
		rts	
; ===========================================================================

loc_206A:				; XREF: loc_202A
		subq.b	#1,($FFFFF634).w
		bpl.b	loc_20BC
		move.b	#4,($FFFFF634).w
		move.w	($FFFFF632).w,d0
		addi.w	#$C,d0
		cmpi.w	#$30,d0
		bcs.b	loc_2088
		moveq	#0,d0
		rts	
; ===========================================================================

loc_2088:				; XREF: loc_206A
		move.w	d0,($FFFFF632).w
		lea	(Pal_Sega2).l,a0
		lea	(a0,d0.w),a0
		lea	($FFFFFB04).w,a1
		move.l	(a0)+,(a1)+
		move.l	(a0)+,(a1)+
		move.w	(a0)+,(a1)
		lea	($FFFFFB20).w,a1
		moveq	#0,d0
		moveq	#$2C,d1

loc_20A8:
		move.w	d0,d2
		andi.w	#$1E,d2
		bne.b	loc_20B2
		addq.w	#2,d0

loc_20B2:
		move.w	(a0),(a1,d0.w)
		addq.w	#2,d0
		dbra	d1,loc_20A8

loc_20BC:
		moveq	#1,d0
		rts	
; End of function PalCycle_Sega

; ===========================================================================

Pal_Sega1:	incbin	pallet\sega1.bin
Pal_Sega2:	incbin	pallet\sega2.bin

; ---------------------------------------------------------------------------
; Subroutines to load pallets
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


colorset:
		lea	(colortbl).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		adda.w	#$80,a3
		move.w	(a1)+,d7

loc_2110:
		move.l	(a2)+,(a3)+
		dbra	d7,loc_2110
		rts	
; End of function colorset


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


colorset2:
		lea	(colortbl).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		move.w	(a1)+,d7

loc_2128:
		move.l	(a2)+,(a3)+
		dbra	d7,loc_2128
		rts	
; End of function colorset2

; ---------------------------------------------------------------------------
; Underwater pallet loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad3_Water:
		lea	(colortbl).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$80,a3
		move.w	(a1)+,d7

loc_2144:
		move.l	(a2)+,(a3)+
		dbra	d7,loc_2144
		rts	
; End of function PalLoad3_Water


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalLoad4_Water:
		lea	(colortbl).l,a1
		lsl.w	#3,d0
		adda.w	d0,a1
		movea.l	(a1)+,a2
		movea.w	(a1)+,a3
		suba.w	#$100,a3
		move.w	(a1)+,d7

loc_2160:
		move.l	(a2)+,(a3)+
		dbra	d7,loc_2160
		rts	
; End of function PalLoad4_Water

dclww	macro	\1,\2,\3
		dc.l	(\1)
		dc.w	(\2)
		dc.w	(\3)

colortbl:
		dclww	logobcolor,$FB00,31		;0:
		dclww	Pal_Title,$FB00,31		;1;
		dclww	Pal_LevelSel,$FB00,31	;2:
		dclww	gamecolor,$FB00,7		;3:
		dclww	zone1color,$FB20,23		;4:
		dclww	zone2color,$FB20,23		;5:
		dclww	zone3color,$FB20,23		;6:
		dclww	zone4color,$FB20,23		;7:
		dclww	zone5color,$FB20,23		;8:
		dclww	zone6color,$FB20,23		;9:
		dclww	Pal_Special,$FB00,31	;10:
		dclww	zone2color2,$FB00,31	;11:
		dclww	zone24color,$FB20,23	;12:
		dclww	zone24color2,$FB00,31	;13:
		dclww	zone6color2,$FB20,23	;14:
		dclww	gamecolor2,$FB00,7		;15:
		dclww	gamecolor3,$FB00,7		;16:
		dclww	Pal_SpeResult,$FB00,31	;17:
		dclww	continuecolor,$FB00,15	;18:
		dclww	endcolor,$FB00,31		;19:

logobcolor:
		dc.w	$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee
		dc.w	$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee
		dc.w	$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee
		dc.w	$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee,$eee
Pal_Title:	incbin	pallet\title.bin
Pal_LevelSel:	incbin	pallet\levelsel.bin
gamecolor:
*		dc.w	$000,$000,$c22,$e44,$e66,$e88,$eee,$aaa,$888,$444,$8ae,$46a,$00e,$008,$004,$0ee
		dc.w	$000,$000,$822,$a44,$c66,$e88,$eee,$aaa,$888,$444,$8ae,$46a,$00e,$008,$004,$0ee
zone1color:
		dc.w	$800,$000,$242,$464,$686,$8c8,$eee,$aaa,$888,$444,$8ea,$46a,$0ee,$088,$044,$00e
		dc.w	$e80,$002,$eee,$026,$048,$06c,$08e,$0ce,$a86,$e86,$ea8,$eca,$040,$060,$0a4,$0e8
		dc.w	$c82,$a02,$c42,$e86,$eca,$eec,$eee,$eac,$e8a,$e68,$0e8,$0a4,$002,$026,$06c,$0ce
zone2color:		incbin	pallet\lz.bin
zone2color2:	incbin	pallet\lz_uw.bin	; LZ underwater pallets
zone3color:		incbin	pallet\mz.bin
zone4color:	incbin	pallet\slz.bin
zone5color:	incbin	pallet\syz.bin
zone6color:	incbin	pallet\sbz_act1.bin	; SBZ act 1 pallets
zone6color2:	incbin	pallet\sbz_act2.bin	; SBZ act 2 & Final Zone pallets
Pal_Special:	incbin	pallet\special.bin	; special stage pallets
zone24color:	incbin	pallet\sbz_act3.bin	; SBZ act 3 pallets
zone24color2:	incbin	pallet\sbz_a3uw.bin	; SBZ act 3 (underwater) pallets
gamecolor2:	incbin	pallet\son_lzuw.bin	; Sonic (underwater in LZ) pallet
gamecolor3:	incbin	pallet\son_sbzu.bin	; Sonic (underwater in SBZ act 3) pallet
Pal_SpeResult:	incbin	pallet\ssresult.bin	; special stage results screen pallets
continuecolor:incbin	pallet\sscontin.bin	; special stage results screen continue pallet
endcolor:	incbin	pallet\ending.bin	; ending sequence pallets

; ---------------------------------------------------------------------------
; Subroutine to	delay the program by ($FFFFF62A) frames
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


DelayProgram:				; XREF: PauseGame
		move	#$2300,sr

loc_29AC:
		tst.b	($FFFFF62A).w
		bne.b	loc_29AC
		rts	
; End of function DelayProgram


random:
		move.l	ranum,d1
		bne.b	?jump
		move.l	#$2a6d365a,d1
?jump:
		move.l	d1,d0
		asl.l	#2,d1
		add.l	d0,d1
		asl.l	#3,d1
		add.l	d0,d1
		move.w	d1,d0
		swap	d1
		add.w	d1,d0
		move.w	d0,d1
		swap	d1
		move.l	d1,ranum
		rts

sinset:
		andi.w	#$FF,d0
		add.w	d0,d0
		addi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d1
		subi.w	#$80,d0
		move.w	Sine_Data(pc,d0.w),d0
		rts	

Sine_Data:	incbin	misc\sinewave.bin	; values for a 360º sine wave


		movem.l	d1-d2,-(sp)
		move.w	d0,d1
		swap	d1
		moveq	#0,d0
		move.w	d0,d1
		moveq	#7,d2

loc_2C80:
		rol.l	#2,d1
		add.w	d0,d0
		addq.w	#1,d0
		sub.w	d0,d1
		bcc.b	loc_2C9A
		add.w	d0,d1
		subq.w	#1,d0
		dbra	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	
; ===========================================================================

loc_2C9A:
		addq.w	#1,d0
		dbra	d2,loc_2C80
		lsr.w	#1,d0
		movem.l	(sp)+,d1-d2
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


atan:
		movem.l	d3-d4,-(sp)
		moveq	#0,d3
		moveq	#0,d4
		move.w	d1,d3
		move.w	d2,d4
		or.w	d3,d4
		beq.b	loc_2D04
		move.w	d2,d4
		tst.w	d3
		bpl.w	loc_2CC2
		neg.w	d3

loc_2CC2:
		tst.w	d4
		bpl.w	loc_2CCA
		neg.w	d4

loc_2CCA:
		cmp.w	d3,d4
		bcc.w	loc_2CDC
		lsl.l	#8,d4
		divu.w	d3,d4
		moveq	#0,d0
		move.b	Angle_Data(pc,d4.w),d0
		bra.b	loc_2CE6
; ===========================================================================

loc_2CDC:				; XREF: atan
		lsl.l	#8,d3
		divu.w	d4,d3
		moveq	#$40,d0
		sub.b	Angle_Data(pc,d3.w),d0

loc_2CE6:
		tst.w	d1
		bpl.w	loc_2CF2
		neg.w	d0
		addi.w	#$80,d0

loc_2CF2:
		tst.w	d2
		bpl.w	loc_2CFE
		neg.w	d0
		addi.w	#$100,d0

loc_2CFE:
		movem.l	(sp)+,d3-d4
		rts	
; ===========================================================================

loc_2D04:				; XREF: atan
		move.w	#$40,d0
		movem.l	(sp)+,d3-d4
		rts	
; End of function atan

; ===========================================================================

Angle_Data:	incbin	misc\angles.bin

; ===========================================================================

; ---------------------------------------------------------------------------
; Sega screen
; ---------------------------------------------------------------------------

SegaScreen:				; XREF: GameModeArray
		move.b	#$E4,d0
		bsr.w	soundset ; stop music
		bsr.w	ClearPLC
		bsr.w	fadein
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$8700,(a6)
		move.w	#$8B00,(a6)
		clr.b	waterflag
		move	#$2700,sr
		move.w	($FFFFF60C).w,d0
		andi.b	#$BF,d0
		move.w	d0,($C00004).l
		bsr.w	scrinit
		move.l	#$40000000,($C00004).l
		lea	(Nem_SegaLogo).l,a0 ; load Sega	logo patterns
		bsr.w	NemDec
		lea	($FF0000).l,a1
		lea	(Eni_SegaLogo).l,a0 ; load Sega	logo mappings
		move.w	#0,d0
		bsr.w	mapdevr
		lea	($FF0000).l,a1
		move.l	#$65100003,d0
		moveq	#$17,d1
		moveq	#7,d2
		bsr.w	ShowVDPGraphics
		lea	($FF0180).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		moveq	#0,d0
		bsr.w	colorset2	; load Sega logo pallet
		move.w	#-$A,($FFFFF632).w
		move.w	#0,($FFFFF634).w
		move.w	#0,($FFFFF662).w
		move.w	#0,($FFFFF660).w
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l

Sega_WaitPallet:
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	PalCycle_Sega
		bne.b	Sega_WaitPallet

		move.b	#$E1,d0
		bsr.w	soundset ; play "SEGA"	sound
		move.b	#$14,($FFFFF62A).w
		bsr.w	DelayProgram
		move.w	#$1E,($FFFFF614).w

Sega_WaitEnd:
		move.b	#2,($FFFFF62A).w
		bsr.w	DelayProgram
		tst.w	($FFFFF614).w
		beq.b	Sega_GotoTitle
		andi.b	#$80,swdata1+1 ; is	Start button pressed?
		beq.b	Sega_WaitEnd	; if not, branch

Sega_GotoTitle:
		move.b	#4,gmmode ; go to title screen
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Title	screen
; ---------------------------------------------------------------------------

TitleScreen:				; XREF: GameModeArray
		move.b	#$E4,d0
		bsr.w	soundset ; stop music
		bsr.w	ClearPLC
		bsr.w	fadein
		move	#$2700,sr
		bsr.w	SoundDriverLoad
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		move.w	#$9200,(a6)
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)
		clr.b	waterflag
		bsr.w	scrinit
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Title_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,Title_ClrObjRam ; fill object RAM ($D000-$EFFF) with	$0

		move.l	#$40000000,($C00004).l
		lea	(Nem_JapNames).l,a0 ; load Japanese credits
		bsr.w	NemDec
		move.l	#$54C00000,($C00004).l
		lea	(Nem_CreditText).l,a0 ;	load alphabet
		bsr.w	NemDec
		lea	($FF0000).l,a1
		lea	(Eni_JapNames).l,a0 ; load mappings for	Japanese credits
		move.w	#0,d0
		bsr.w	mapdevr
		lea	($FF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$27,d1
		moveq	#$1B,d2
		bsr.w	ShowVDPGraphics
		lea	($FFFFFB80).w,a1
		moveq	#0,d0
		move.w	#$1F,d1

Title_ClrPallet:
		move.l	d0,(a1)+
		dbra	d1,Title_ClrPallet ; fill pallet with 0	(black)

		moveq	#3,d0		; load Sonic's pallet
		bsr.w	colorset
		move.b	#$8A,($FFFFD080).w ; load "SONIC TEAM PRESENTS"	object
		jsr	action
		jsr	patset
		bsr.w	fadeout
		move	#$2700,sr
		move.l	#$40000001,($C00004).l
		lea	(Nem_TitleFg).l,a0 ; load title	screen patterns
		bsr.w	NemDec
		move.l	#$60000001,($C00004).l
		lea	(Nem_TitleSonic).l,a0 ;	load Sonic title screen	patterns
		bsr.w	NemDec
		move.l	#$62000002,($C00004).l
		lea	(Nem_TitleTM).l,a0 ; load "TM" patterns
		bsr.w	NemDec
		lea	($C00000).l,a6
		move.l	#$50000003,4(a6)
		lea	(ascii).l,a5
		move.w	#$28F,d1

Title_LoadText:
		move.w	(a5)+,(a6)
		dbra	d1,Title_LoadText ; load uncompressed text patterns

		move.b	#0,saveno ; clear lamppost counter
		move.w	#0,editmode ; disable debug item placement	mode
		move.w	#0,($FFFFFFF0).w ; disable debug mode
		move.w	#0,($FFFFFFEA).w
		move.w	#0,stageno ; set level to	GHZ (00)
		move.w	#0,($FFFFF634).w ; disable pallet cycling
		bsr.w	scr_set
		bsr.w	scroll
		lea	($FFFFB000).w,a1
		lea	(Blk16_GHZ).l,a0 ; load	GHZ 16x16 mappings
		move.w	#0,d0
		bsr.w	mapdevr
		lea	(Blk256_GHZ).l,a0 ; load GHZ 256x256 mappings
		lea	($FF0000).l,a1
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		bsr.w	fadein
		move	#$2700,sr
		bsr.w	scrinit
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	scrb_h_posit,a3
		lea	mapwkb,a4
		move.w	#$6000,d2
		bsr.w	mapwrt2
		lea	($FF0000).l,a1
		lea	(Eni_Title).l,a0 ; load	title screen mappings
		move.w	#0,d0
		bsr.w	mapdevr
		lea	($FF0000).l,a1
		move.l	#$42060003,d0
		moveq	#$21,d1
		moveq	#$15,d2
		bsr.w	ShowVDPGraphics
		move.l	#$40000000,($C00004).l
		lea	(Nem_GHZ_1st).l,a0 ; load GHZ patterns
		bsr.w	NemDec
		moveq	#1,d0		; load title screen pallet
		bsr.w	colorset
		move.b	#$8A,d0		; play title screen music
		bsr.w	soundset
		move.b	#0,debugflag ; disable debug mode
		move.w	#$178,($FFFFF614).w ; run title	screen for $178	frames
		lea	($FFFFD080).w,a1
		moveq	#0,d0
		move.w	#7,d1

Title_ClrObjRam2:
		move.l	d0,(a1)+
		dbra	d1,Title_ClrObjRam2

		move.b	#$E,($FFFFD040).w ; load big Sonic object
		move.b	#$F,($FFFFD080).w ; load "PRESS	START BUTTON" object
		move.b	#$F,($FFFFD0C0).w ; load "TM" object
		move.b	#3,($FFFFD0DA).w
		move.b	#$F,($FFFFD100).w
		move.b	#2,($FFFFD11A).w
		jsr	action
		bsr.w	scroll
		jsr	patset
		moveq	#0,d0
		bsr.w	LoadPLC2
		move.w	#0,($FFFFFFE4).w
		move.w	#0,($FFFFFFE6).w
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l
		bsr.w	fadeout

loc_317C:
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	action
		bsr.w	scroll
		jsr	patset
		bsr.w	PalCycle_Title
		bsr.w	RunPLC_RAM
		move.w	playerwk+xposi,d0
		addq.w	#2,d0
		move.w	d0,playerwk+xposi ; move	Sonic to the right
		cmpi.w	#$1C00,d0	; has Sonic object passed x-position $1C00?
		bcs.b	Title_ChkRegion	; if not, branch
		move.b	#0,gmmode ; go to Sega screen
		rts	
; ===========================================================================

Title_ChkRegion:
		tst.b	($FFFFFFF8).w	; check	if the machine is US or	Japanese
		bpl.b	Title_RegionJ	; if Japanese, branch
		lea	(LevelSelectCode_US).l,a0 ; load US code
		bra.b	Title_EnterCheat
; ===========================================================================

Title_RegionJ:				; XREF: Title_ChkRegion
		lea	(LevelSelectCode_J).l,a0 ; load	J code

Title_EnterCheat:			; XREF: Title_ChkRegion
		move.w	($FFFFFFE4).w,d0
		adda.w	d0,a0
		move.b	swdata1+1,d0 ; get button press
		andi.b	#$F,d0		; read only up/down/left/right buttons
		cmp.b	(a0),d0		; does button press match the cheat code?
		bne.b	loc_3210	; if not, branch
		addq.w	#1,($FFFFFFE4).w ; next	button press
		tst.b	d0
		bne.b	Title_CountC
		lea	($FFFFFFE0).w,a0
		move.w	($FFFFFFE6).w,d1
		lsr.w	#1,d1
		andi.w	#3,d1
		beq.b	Title_PlayRing
		tst.b	($FFFFFFF8).w
		bpl.b	Title_PlayRing
		moveq	#1,d1
		move.b	d1,1(a0,d1.w)

Title_PlayRing:
		move.b	#1,(a0,d1.w)	; activate cheat
		move.b	#$B5,d0		; play ring sound when code is entered
		bsr.w	soundset
		bra.b	Title_CountC
; ===========================================================================

loc_3210:				; XREF: Title_EnterCheat
		tst.b	d0
		beq.b	Title_CountC
		cmpi.w	#9,($FFFFFFE4).w
		beq.b	Title_CountC
		move.w	#0,($FFFFFFE4).w

Title_CountC:
		move.b	swdata1+1,d0
		andi.b	#$20,d0		; is C button pressed?
		beq.b	loc_3230	; if not, branch
		addq.w	#1,($FFFFFFE6).w ; increment C button counter

loc_3230:
		tst.w	($FFFFF614).w
		beq.w	Demo
		andi.b	#$80,swdata1+1 ; check if Start is pressed
		beq.w	loc_317C	; if not, branch

Title_ChkLevSel:
		tst.b	($FFFFFFE0).w	; check	if level select	code is	on
		beq.w	PlayLevel	; if not, play level
		btst	#6,swdata1+0 ; check if A is pressed
		beq.w	PlayLevel	; if not, play level
		moveq	#2,d0
		bsr.w	colorset2	; load level select pallet
		lea	($FFFFCC00).w,a1
		moveq	#0,d0
		move.w	#$DF,d1

Title_ClrScroll:
		move.l	d0,(a1)+
		dbra	d1,Title_ClrScroll ; fill scroll data with 0

		move.l	d0,($FFFFF616).w
		move	#$2700,sr
		lea	($C00000).l,a6
		move.l	#$60000003,($C00004).l
		move.w	#$3FF,d1

Title_ClrVram:
		move.l	d0,(a6)
		dbra	d1,Title_ClrVram ; fill	VRAM with 0

		bsr.w	LevSelTextLoad

; ---------------------------------------------------------------------------
; Level	Select
; ---------------------------------------------------------------------------

LevelSelect:
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	LevSelControls
		bsr.w	RunPLC_RAM
		tst.l	($FFFFF680).w
		bne.b	LevelSelect
		andi.b	#$F0,swdata1+1 ; is	A, B, C, or Start pressed?
		beq.b	LevelSelect	; if not, branch
		move.w	($FFFFFF82).w,d0
		cmpi.w	#$14,d0		; have you selected item $14 (sound test)?
		bne.b	LevSel_Level_SS	; if not, go to	Level/SS subroutine
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0
		tst.b	($FFFFFFE3).w	; is Japanese Credits cheat on?
		beq.b	LevSel_NoCheat	; if not, branch
		cmpi.w	#$9F,d0		; is sound $9F being played?
		beq.b	LevSel_Ending	; if yes, branch
		cmpi.w	#$9E,d0		; is sound $9E being played?
		beq.b	LevSel_Credits	; if yes, branch

LevSel_NoCheat:
		cmpi.w	#$94,d0		; is sound $80-$94 being played?
		bcs.b	LevSel_PlaySnd	; if yes, branch
		cmpi.w	#$A0,d0		; is sound $95-$A0 being played?
		bcs.b	LevelSelect	; if yes, branch

LevSel_PlaySnd:
		bsr.w	soundset
		bra.b	LevelSelect
; ===========================================================================

LevSel_Ending:				; XREF: LevelSelect
		move.b	#$18,gmmode ; set screen	mode to	$18 (Ending)
		move.w	#$600,stageno ; set level	to 0600	(Ending)
		rts	
; ===========================================================================

LevSel_Credits:				; XREF: LevelSelect
		move.b	#$1C,gmmode ; set screen	mode to	$1C (Credits)
		move.b	#$91,d0
		bsr.w	soundset ; play credits music
		move.w	#0,($FFFFFFF4).w
		rts	
; ===========================================================================

LevSel_Level_SS:			; XREF: LevelSelect
		add.w	d0,d0
		move.w	LSelectPointers(pc,d0.w),d0 ; load level number
		bmi.w	LevelSelect
		cmpi.w	#$700,d0	; check	if level is 0700 (Special Stage)
		bne.b	LevSel_Level	; if not, branch
		move.b	#$10,gmmode ; set screen	mode to	$10 (Special Stage)
		clr.w	stageno	; clear	level
		move.b	#3,pl_suu ; set lives to	3
		moveq	#0,d0
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.l	d0,plscore ; clear score
		rts	
; ===========================================================================

LevSel_Level:				; XREF: LevSel_Level_SS
		andi.w	#$3FFF,d0
		move.w	d0,stageno ; set level number

PlayLevel:				; XREF: ROM:00003246j ...
		move.b	#$C,gmmode ; set	screen mode to $0C (level)
		move.b	#3,pl_suu ; set lives to	3
		moveq	#0,d0
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.l	d0,plscore ; clear score
		move.b	d0,($FFFFFE16).w ; clear special stage number
		move.b	d0,($FFFFFE57).w ; clear emeralds
		move.l	d0,($FFFFFE58).w ; clear emeralds
		move.l	d0,($FFFFFE5C).w ; clear emeralds
		move.b	d0,($FFFFFE18).w ; clear continues
		move.b	#$E0,d0
		bsr.w	soundset ; fade out music
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select - level pointers
; ---------------------------------------------------------------------------
LSelectPointers:
		incbin	misc\ls_point.bin
		even
; ---------------------------------------------------------------------------
; Level	select codes
; ---------------------------------------------------------------------------
LevelSelectCode_J:
		incbin	misc\ls_jcode.bin
		even

LevelSelectCode_US:
		incbin	misc\ls_ucode.bin
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Demo mode
; ---------------------------------------------------------------------------

Demo:					; XREF: TitleScreen
		move.w	#$1E,($FFFFF614).w

loc_33B6:				; XREF: loc_33E4
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	scroll
		bsr.w	clchgctr
		bsr.w	RunPLC_RAM
		move.w	playerwk+xposi,d0
		addq.w	#2,d0
		move.w	d0,playerwk+xposi
		cmpi.w	#$1C00,d0
		bcs.b	loc_33E4
		move.b	#0,gmmode ; set screen mode to 00 (level)
		rts	
; ===========================================================================

loc_33E4:				; XREF: Demo
		andi.b	#$80,swdata1+1 ; is	Start button pressed?
		bne.w	Title_ChkLevSel	; if yes, branch
		tst.w	($FFFFF614).w
		bne.w	loc_33B6
		move.b	#$E0,d0
		bsr.w	soundset ; fade out music
		move.w	($FFFFFFF2).w,d0 ; load	demo number
		andi.w	#7,d0
		add.w	d0,d0
		move.w	Demo_Levels(pc,d0.w),d0	; load level number for	demo
		move.w	d0,stageno
		addq.w	#1,($FFFFFFF2).w ; add 1 to demo number
		cmpi.w	#4,($FFFFFFF2).w ; is demo number less than 4?
		bcs.b	loc_3422	; if yes, branch
		move.w	#0,($FFFFFFF2).w ; reset demo number to	0

loc_3422:
		move.w	#1,($FFFFFFF0).w ; turn	demo mode on
		move.b	#8,gmmode ; set screen mode to 08 (demo)
		cmpi.w	#$600,d0	; is level number 0600 (special	stage)?
		bne.b	Demo_Level	; if not, branch
		move.b	#$10,gmmode ; set screen	mode to	$10 (Special Stage)
		clr.w	stageno	; clear	level number
		clr.b	($FFFFFE16).w	; clear	special	stage number

Demo_Level:
		move.b	#3,pl_suu ; set lives to	3
		moveq	#0,d0
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.l	d0,plscore ; clear score
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in demos
; ---------------------------------------------------------------------------
Demo_Levels:	incbin	misc\dm_ord1.bin
		even

; ---------------------------------------------------------------------------
; Subroutine to	change what you're selecting in the level select
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelControls:				; XREF: LevelSelect
		move.b	swdata1+1,d1
		andi.b	#3,d1		; is up/down pressed and held?
		bne.b	LevSel_UpDown	; if yes, branch
		subq.w	#1,($FFFFFF80).w ; subtract 1 from time	to next	move
		bpl.b	LevSel_SndTest	; if time remains, branch

LevSel_UpDown:
		move.w	#$B,($FFFFFF80).w ; reset time delay
		move.b	swdata1+0,d1
		andi.b	#3,d1		; is up/down pressed?
		beq.b	LevSel_SndTest	; if not, branch
		move.w	($FFFFFF82).w,d0
		btst	#0,d1		; is up	pressed?
		beq.b	LevSel_Down	; if not, branch
		subq.w	#1,d0		; move up 1 selection
		bcc.b	LevSel_Down
		moveq	#$14,d0		; if selection moves below 0, jump to selection	$14

LevSel_Down:
		btst	#1,d1		; is down pressed?
		beq.b	LevSel_Refresh	; if not, branch
		addq.w	#1,d0		; move down 1 selection
		cmpi.w	#$15,d0
		bcs.b	LevSel_Refresh
		moveq	#0,d0		; if selection moves above $14,	jump to	selection 0

LevSel_Refresh:
		move.w	d0,($FFFFFF82).w ; set new selection
		bsr.w	LevSelTextLoad	; refresh text
		rts	
; ===========================================================================

LevSel_SndTest:				; XREF: LevSelControls
		cmpi.w	#$14,($FFFFFF82).w ; is	item $14 selected?
		bne.b	LevSel_NoMove	; if not, branch
		move.b	swdata1+1,d1
		andi.b	#$C,d1		; is left/right	pressed?
		beq.b	LevSel_NoMove	; if not, branch
		move.w	($FFFFFF84).w,d0
		btst	#2,d1		; is left pressed?
		beq.b	LevSel_Right	; if not, branch
		subq.w	#1,d0		; subtract 1 from sound	test
		bcc.b	LevSel_Right
		moveq	#$4F,d0		; if sound test	moves below 0, set to $4F

LevSel_Right:
		btst	#3,d1		; is right pressed?
		beq.b	LevSel_Refresh2	; if not, branch
		addq.w	#1,d0		; add 1	to sound test
		cmpi.w	#$50,d0
		bcs.b	LevSel_Refresh2
		moveq	#0,d0		; if sound test	moves above $4F, set to	0

LevSel_Refresh2:
		move.w	d0,($FFFFFF84).w ; set sound test number
		bsr.w	LevSelTextLoad	; refresh text

LevSel_NoMove:
		rts	
; End of function LevSelControls

; ---------------------------------------------------------------------------
; Subroutine to load level select text
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSelTextLoad:				; XREF: TitleScreen
		lea	(LevelMenuText).l,a1
		lea	($C00000).l,a6
		move.l	#$62100003,d4	; screen position (text)
		move.w	#$E680,d3	; VRAM setting
		moveq	#$14,d1		; number of lines of text

loc_34FE:				; XREF: LevSelTextLoad+26j
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine
		addi.l	#$800000,d4
		dbra	d1,loc_34FE
		moveq	#0,d0
		move.w	($FFFFFF82).w,d0
		move.w	d0,d1
		move.l	#$62100003,d4
		lsl.w	#7,d0
		swap	d0
		add.l	d0,d4
		lea	(LevelMenuText).l,a1
		lsl.w	#3,d1
		move.w	d1,d0
		add.w	d1,d1
		add.w	d0,d1
		adda.w	d1,a1
		move.w	#$C680,d3
		move.l	d4,4(a6)
		bsr.w	LevSel_ChgLine
		move.w	#$E680,d3
		cmpi.w	#$14,($FFFFFF82).w
		bne.b	loc_3550
		move.w	#$C680,d3

loc_3550:
		move.l	#$6C300003,($C00004).l ; screen	position (sound	test)
		move.w	($FFFFFF84).w,d0
		addi.w	#$80,d0
		move.b	d0,d2
		lsr.b	#4,d0
		bsr.w	LevSel_ChgSnd
		move.b	d2,d0
		bsr.w	LevSel_ChgSnd
		rts	
; End of function LevSelTextLoad


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgSnd:				; XREF: LevSelTextLoad
		andi.w	#$F,d0
		cmpi.b	#$A,d0
		bcs.b	loc_3580
		addi.b	#7,d0

loc_3580:
		add.w	d3,d0
		move.w	d0,(a6)
		rts	
; End of function LevSel_ChgSnd


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevSel_ChgLine:				; XREF: LevSelTextLoad
		moveq	#$17,d2		; number of characters per line

loc_3588:
		moveq	#0,d0
		move.b	(a1)+,d0
		bpl.b	loc_3598
		move.w	#0,(a6)
		dbra	d2,loc_3588
		rts	
; ===========================================================================

loc_3598:				; XREF: LevSel_ChgLine
		add.w	d3,d0
		move.w	d0,(a6)
		dbra	d2,loc_3588
		rts	
; End of function LevSel_ChgLine

; ===========================================================================
; ---------------------------------------------------------------------------
; Level	select menu text
; ---------------------------------------------------------------------------
LevelMenuText:	incbin	misc\menutext.bin
		even
; ---------------------------------------------------------------------------
; Music	playlist
; ---------------------------------------------------------------------------
MusicList:	incbin	misc\muslist1.bin
		even
; ===========================================================================

; ---------------------------------------------------------------------------
; Level
; ---------------------------------------------------------------------------

game:					; XREF: GameModeArray
		bset	#7,gmmode ; add $80 to screen mode (for pre level sequence)
		tst.w	($FFFFFFF0).w
		bmi.b	loc_37B6
		move.b	#$E0,d0
		bsr.w	soundset ; fade out music

loc_37B6:
		bsr.w	ClearPLC
		bsr.w	fadein
		tst.w	($FFFFFFF0).w
		bmi.b	Level_ClrRam
		move	#$2700,sr
		move.l	#$70000002,($C00004).l
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		move	#$2300,sr
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.b	loc_37FC
		bsr.w	LoadPLC		; load level patterns

loc_37FC:
		moveq	#1,d0
		bsr.w	LoadPLC		; load standard	patterns

Level_ClrRam:
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Level_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,Level_ClrObjRam ; clear object RAM

		lea	($FFFFF628).w,a1
		moveq	#0,d0
		move.w	#$15,d1

Level_ClrVars:
		move.l	d0,(a1)+
		dbra	d1,Level_ClrVars ; clear misc variables

		lea	scra_h_posit,a1
		moveq	#0,d0
		move.w	#$3F,d1

Level_ClrVars2:
		move.l	d0,(a1)+
		dbra	d1,Level_ClrVars2 ; clear misc variables

		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$47,d1

Level_ClrVars3:
		move.l	d0,(a1)+
		dbra	d1,Level_ClrVars3 ; clear object variables

		move	#$2700,sr
		bsr.w	scrinit
		lea	($C00004).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$857C,(a6)
		move.w	#$9001,(a6)
		move.w	#$8004,(a6)
		move.w	#$8720,(a6)
		move.w	#$8ADF,hintposi
		move.w	hintposi,(a6)
		cmpi.b	#1,stageno ; is level LZ?
		bne.b	Level_LoadPal	; if not, branch
		move.w	#$8014,(a6)
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		lea	(waterpositbl).l,a1 ; load water	height array
		move.w	(a1,d0.w),d0
		move.w	d0,waterposi ; set water heights
		move.w	d0,waterposi_m
		move.w	d0,watermoveposi
		clr.b	($FFFFF64D).w	; clear	water routine counter
		clr.b	waterflag	; clear	water movement
		move.b	#1,($FFFFF64C).w ; enable water

Level_LoadPal:
		move.w	#$1E,pl_air
		move	#$2300,sr
		moveq	#3,d0
		bsr.w	colorset2	; load Sonic's pallet line
		cmpi.b	#1,stageno ; is level LZ?
		bne.b	Level_GetBgm	; if not, branch
		moveq	#$F,d0		; pallet number	$0F (LZ)
		cmpi.b	#3,stageno+1 ; is act number 3?
		bne.b	Level_WaterPal	; if not, branch
		moveq	#$10,d0		; pallet number	$10 (SBZ3)

Level_WaterPal:
		bsr.w	PalLoad3_Water	; load underwater pallet (see d0)
		tst.b	saveno
		beq.b	Level_GetBgm
		move.b	waterflag_s,waterflag

Level_GetBgm:
		tst.w	($FFFFFFF0).w
		bmi.b	loc_3946
		moveq	#0,d0
		move.b	stageno,d0
		cmpi.w	#$103,stageno ; is level SBZ3?
		bne.b	Level_BgmNotLZ4	; if not, branch
		moveq	#5,d0		; move 5 to d0

Level_BgmNotLZ4:
		cmpi.w	#$502,stageno ; is level FZ?
		bne.b	Level_PlayBgm	; if not, branch
		moveq	#6,d0		; move 6 to d0

Level_PlayBgm:
		lea	(MusicList).l,a1 ; load	music playlist
		move.b	(a1,d0.w),d0	; add d0 to a1
		bsr.w	bgmset	; play music
		move.b	#$34,($FFFFD080).w ; load title	card object

Level_TtlCard:
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	action
		jsr	patset
		bsr.w	RunPLC_RAM
		move.w	($FFFFD108).w,d0
		cmp.w	($FFFFD130).w,d0 ; has title card sequence finished?
		bne.b	Level_TtlCard	; if not, branch
		tst.l	($FFFFF680).w	; are there any	items in the pattern load cue?
		bne.b	Level_TtlCard	; if yes, branch
		jsr	scoreinit

loc_3946:
		moveq	#3,d0
		bsr.w	colorset	; load Sonic's pallet line
		bsr.w	scr_set
		bsr.w	scroll
		bset	#2,($FFFFF754).w
		bsr.w	mapinit ; load block mappings	and pallets
		bsr.w	mapwrt
		jsr	scdcnv
		bsr.w	scdset
		bsr.w	LZWaterEffects
		move.b	#1,playerwk ; load	Sonic object
		tst.w	($FFFFFFF0).w
		bmi.b	Level_ChkDebug
		move.b	#$21,($FFFFD040).w ; load HUD object

Level_ChkDebug:
		tst.b	($FFFFFFE2).w	; has debug cheat been entered?
		beq.b	Level_ChkWater	; if not, branch
		btst	#6,swdata1+0 ; is A	button pressed?
		beq.b	Level_ChkWater	; if not, branch
		move.b	#1,debugflag ; enable debug	mode

Level_ChkWater:
		move.w	#0,swdata+0
		move.w	#0,swdata1+0
		cmpi.b	#1,stageno ; is level LZ?
		bne.b	Level_LoadObj	; if not, branch
		move.b	#$1B,($FFFFD780).w ; load water	surface	object
		move.w	#$60,($FFFFD788).w
		move.b	#$1B,($FFFFD7C0).w
		move.w	#$120,($FFFFD7C8).w

Level_LoadObj:
		jsr	ObjPosLoad
		jsr	action
		jsr	patset
		moveq	#0,d0
		tst.b	saveno	; are you starting from	a lamppost?
		bne.b	loc_39E8	; if yes, branch
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.b	d0,plring_f2 ; clear lives counter

loc_39E8:
		move.b	d0,pltimeover_f
		move.b	d0,plpower_b ; clear shield
		move.b	d0,plpower_m ; clear invincibility
		move.b	d0,plpower_s ; clear speed shoes
		move.b	d0,($FFFFFE2F).w
		move.w	d0,editmode
		move.w	d0,gameflag
		move.w	d0,gametimer
		bsr.w	OscillateNumInit
		move.b	#1,plscore_f ; update score	counter
		move.b	#1,plring_f ; update rings	counter
		move.b	#1,pltime_f ; update time counter
		move.w	#0,($FFFFF790).w
		lea	(Demo_Index).l,a1 ; load demo data
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		tst.w	($FFFFFFF0).w	; is demo mode on?
		bpl.b	Level_Demo	; if yes, branch
		lea	(Demo_EndIndex).l,a1 ; load ending demo	data
		move.w	($FFFFFFF4).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1

Level_Demo:
		move.b	1(a1),($FFFFF792).w ; load key press duration
		subq.b	#1,($FFFFF792).w ; subtract 1 from duration
		move.w	#1800,($FFFFF614).w
		tst.w	($FFFFFFF0).w
		bpl.b	Level_ChkWaterPal
		move.w	#540,($FFFFF614).w
		cmpi.w	#4,($FFFFFFF4).w
		bne.b	Level_ChkWaterPal
		move.w	#510,($FFFFF614).w

Level_ChkWaterPal:
		cmpi.b	#1,stageno ; is level LZ/SBZ3?
		bne.b	Level_Delay	; if not, branch
		moveq	#$B,d0		; pallet $0B (LZ underwater)
		cmpi.b	#3,stageno+1 ; is level SBZ3?
		bne.b	Level_WaterPal2	; if not, branch
		moveq	#$D,d0		; pallet $0D (SBZ3 underwater)

Level_WaterPal2:
		bsr.w	PalLoad4_Water

Level_Delay:
		move.w	#3,d1

Level_DelayLoop:
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		dbra	d1,Level_DelayLoop

		move.w	#$202F,($FFFFF626).w
		bsr.w	fadeout2
		tst.w	($FFFFFFF0).w
		bmi.b	Level_ClrCardArt
		addq.b	#2,($FFFFD0A4).w ; make	title card move
		addq.b	#4,($FFFFD0E4).w
		addq.b	#4,($FFFFD124).w
		addq.b	#4,($FFFFD164).w
		bra.b	Level_StartGame
; ===========================================================================

Level_ClrCardArt:
		moveq	#2,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	stageno,d0
		addi.w	#$15,d0
		jsr	(LoadPLC).l	; load animal patterns (level no. + $15)

Level_StartGame:
		bclr	#7,gmmode ; subtract 80 from screen mode

; ---------------------------------------------------------------------------
; Main level loop (when	all title card and loading sequences are finished)
; ---------------------------------------------------------------------------

Level_MainLoop:
		bsr.w	PauseGame
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		addq.w	#1,gametimer ; add 1 to level timer
		bsr.w	MoveSonicInDemo
		bsr.w	LZWaterEffects
		jsr	action
		tst.w	editmode
		bne.b	loc_3B10
		cmpi.b	#6,($FFFFD024).w
		bcc.b	loc_3B14

loc_3B10:
		bsr.w	scroll

loc_3B14:
		jsr	patset
		jsr	ObjPosLoad
		bsr.w	clchgctr
		bsr.w	RunPLC_RAM
		bsr.w	OscillateNumDo
		bsr.w	syspatchg
		bsr.w	SignpostArtLoad
		cmpi.b	#8,gmmode
		beq.b	Level_ChkDemo	; if screen mode is 08 (demo), branch
		tst.w	gameflag	; is the level set to restart?
		bne.w	Level		; if yes, branch
		cmpi.b	#$C,gmmode
		beq.w	Level_MainLoop	; if screen mode is $0C	(level), branch
		rts	
; ===========================================================================

Level_ChkDemo:				; XREF: Level_MainLoop
		tst.w	gameflag	; is level set to restart?
		bne.b	Level_EndDemo	; if yes, branch
		tst.w	($FFFFF614).w	; is there time	left on	the demo?
		beq.b	Level_EndDemo	; if not, branch
		cmpi.b	#8,gmmode
		beq.w	Level_MainLoop	; if screen mode is 08 (demo), branch
		move.b	#0,gmmode ; go to Sega screen
		rts	
; ===========================================================================

Level_EndDemo:				; XREF: Level_ChkDemo
		cmpi.b	#8,gmmode ; is screen mode 08 (demo)?
		bne.b	loc_3B88	; if not, branch
		move.b	#0,gmmode ; go to Sega screen
		tst.w	($FFFFFFF0).w	; is demo mode on?
		bpl.b	loc_3B88	; if yes, branch
		move.b	#$1C,gmmode ; go	to credits

loc_3B88:
		move.w	#$3C,($FFFFF614).w
		move.w	#$3F,($FFFFF626).w
		clr.w	($FFFFF794).w

loc_3B98:
		move.b	#8,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		jsr	action
		jsr	patset
		jsr	ObjPosLoad
		subq.w	#1,($FFFFF794).w
		bpl.b	loc_3BC8
		move.w	#2,($FFFFF794).w
		bsr.w	Pal_FadeOut

loc_3BC8:
		tst.w	($FFFFF614).w
		bne.b	loc_3B98
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Subroutine to	do special water effects in Labyrinth Zone
; ---------------------------------------------------------------------------

LZWaterEffects:				; XREF: Level
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	locret_3C28	; if not, branch
		cmpi.b	#6,($FFFFD024).w
		bcc.b	LZMoveWater
		bsr.w	LZWindTunnels
		bsr.w	LZWaterSlides
		bsr.w	LZDynamicWater

LZMoveWater:
		clr.b	waterflag
		moveq	#0,d0
		move.b	($FFFFFE60).w,d0
		lsr.w	#1,d0
		add.w	waterposi_m,d0
		move.w	d0,waterposi
		move.w	waterposi,d0
		sub.w	scra_v_posit,d0
		bcc.b	loc_3C1A
		tst.w	d0
		bpl.b	loc_3C1A
		move.b	#-$21,hintposi+1
		move.b	#1,waterflag

loc_3C1A:
		cmpi.w	#$DF,d0
		bcs.b	loc_3C24
		move.w	#$DF,d0

loc_3C24:
		move.b	d0,hintposi+1

locret_3C28:
		rts	

waterpositbl:
		dc.b	$00B8,$0328,$0900,$0228
		align

; ---------------------------------------------------------------------------
; Labyrinth dynamic water routines
; ---------------------------------------------------------------------------

LZDynamicWater:				; XREF: LZWaterEffects
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Dynwave_move_tbl(pc,d0.w),d0
		jsr	Dynwave_move_tbl(pc,d0.w)
		moveq	#0,d1
		move.b	($FFFFF64C).w,d1
		move.w	watermoveposi,d0
		sub.w	waterposi_m,d0
		beq.b	locret_3C5A
		bcc.b	loc_3C56
		neg.w	d1

loc_3C56:
		add.w	d1,waterposi_m

locret_3C5A:
		rts	
; ===========================================================================
Dynwave_move_tbl:	dc.w DynWater_LZ1-Dynwave_move_tbl
		dc.w DynWater_LZ2-Dynwave_move_tbl
		dc.w DynWater_LZ3-Dynwave_move_tbl
		dc.w DynWater_SBZ3-Dynwave_move_tbl
; ===========================================================================

DynWater_LZ1:				; XREF: Dynwave_move_tbl
		move.w	scra_h_posit,d0
		move.b	($FFFFF64D).w,d2
		bne.b	loc_3CD0
		move.w	#$B8,d1
		cmpi.w	#$600,d0
		bcs.b	loc_3CB4
		move.w	#$108,d1
		cmpi.w	#$200,playerwk+yposi
		bcs.b	loc_3CBA
		cmpi.w	#$C00,d0
		bcs.b	loc_3CB4
		move.w	#$318,d1
		cmpi.w	#$1080,d0
		bcs.b	loc_3CB4
		move.b	#-$80,($FFFFF7E5).w
		move.w	#$5C8,d1
		cmpi.w	#$1380,d0
		bcs.b	loc_3CB4
		move.w	#$3A8,d1
		cmp.w	waterposi_m,d1
		bne.b	loc_3CB4
		move.b	#1,($FFFFF64D).w

loc_3CB4:
		move.w	d1,watermoveposi
		rts	
; ===========================================================================

loc_3CBA:				; XREF: DynWater_LZ1
		cmpi.w	#$C80,d0
		bcs.b	loc_3CB4
		move.w	#$E8,d1
		cmpi.w	#$1500,d0
		bcs.b	loc_3CB4
		move.w	#$108,d1
		bra.b	loc_3CB4
; ===========================================================================

loc_3CD0:				; XREF: DynWater_LZ1
		subq.b	#1,d2
		bne.b	locret_3CF4
		cmpi.w	#$2E0,playerwk+yposi
		bcc.b	locret_3CF4
		move.w	#$3A8,d1
		cmpi.w	#$1300,d0
		bcs.b	loc_3CF0
		move.w	#$108,d1
		move.b	#2,($FFFFF64D).w

loc_3CF0:
		move.w	d1,watermoveposi

locret_3CF4:
		rts	
; ===========================================================================

DynWater_LZ2:				; XREF: Dynwave_move_tbl
		move.w	scra_h_posit,d0
		move.w	#$328,d1
		cmpi.w	#$500,d0
		bcs.b	loc_3D12
		move.w	#$3C8,d1
		cmpi.w	#$B00,d0
		bcs.b	loc_3D12
		move.w	#$428,d1

loc_3D12:
		move.w	d1,watermoveposi
		rts	
; ===========================================================================

DynWater_LZ3:				; XREF: Dynwave_move_tbl
		move.w	scra_h_posit,d0
		move.b	($FFFFF64D).w,d2
		bne.b	loc_3D5E
		move.w	#$900,d1
		cmpi.w	#$600,d0
		bcs.b	loc_3D54
		cmpi.w	#$3C0,playerwk+yposi
		bcs.b	loc_3D54
		cmpi.w	#$600,playerwk+yposi
		bcc.b	loc_3D54
		move.w	#$4C8,d1
		move.b	#$4B,($FFFFA506).w ; change level layout
		move.b	#1,($FFFFF64D).w
		move.w	#$B7,d0
		bsr.w	soundset ; play sound $B7 (rumbling)

loc_3D54:
		move.w	d1,watermoveposi
		move.w	d1,waterposi_m
		rts	
; ===========================================================================

loc_3D5E:				; XREF: DynWater_LZ3
		subq.b	#1,d2
		bne.b	loc_3DA8
		move.w	#$4C8,d1
		cmpi.w	#$770,d0
		bcs.b	loc_3DA2
		move.w	#$308,d1
		cmpi.w	#$1400,d0
		bcs.b	loc_3DA2
		cmpi.w	#$508,watermoveposi
		beq.b	loc_3D8E
		cmpi.w	#$600,playerwk+yposi
		bcc.b	loc_3D8E
		cmpi.w	#$280,playerwk+yposi
		bcc.b	loc_3DA2

loc_3D8E:
		move.w	#$508,d1
		move.w	d1,waterposi_m
		cmpi.w	#$1770,d0
		bcs.b	loc_3DA2
		move.b	#2,($FFFFF64D).w

loc_3DA2:
		move.w	d1,watermoveposi
		rts	
; ===========================================================================

loc_3DA8:
		subq.b	#1,d2
		bne.b	loc_3DD2
		move.w	#$508,d1
		cmpi.w	#$1860,d0
		bcs.b	loc_3DCC
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		bcc.b	loc_3DC6
		cmp.w	waterposi_m,d1
		bne.b	loc_3DCC

loc_3DC6:
		move.b	#3,($FFFFF64D).w

loc_3DCC:
		move.w	d1,watermoveposi
		rts	
; ===========================================================================

loc_3DD2:
		subq.b	#1,d2
		bne.b	loc_3E0E
		move.w	#$188,d1
		cmpi.w	#$1AF0,d0
		bcs.b	loc_3E04
		move.w	#$900,d1
		cmpi.w	#$1BC0,d0
		bcs.b	loc_3E04
		move.b	#4,($FFFFF64D).w
		move.w	#$608,watermoveposi
		move.w	#$7C0,waterposi_m
		move.b	#1,($FFFFF7E8).w
		rts	
; ===========================================================================

loc_3E04:
		move.w	d1,watermoveposi
		move.w	d1,waterposi_m
		rts	
; ===========================================================================

loc_3E0E:
		cmpi.w	#$1E00,d0
		bcs.b	locret_3E1A
		move.w	#$128,watermoveposi

locret_3E1A:
		rts	
; ===========================================================================

DynWater_SBZ3:				; XREF: Dynwave_move_tbl
		move.w	#$228,d1
		cmpi.w	#$F00,scra_h_posit
		bcs.b	loc_3E2C
		move.w	#$4C8,d1

loc_3E2C:
		move.w	d1,watermoveposi
		rts

; ---------------------------------------------------------------------------
; Labyrinth Zone "wind tunnels"	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LZWindTunnels:				; XREF: LZWaterEffects
		tst.w	editmode	; is debug mode	being used?
		bne.w	locret_3F0A	; if yes, branch
		lea	(LZWind_Data).l,a2
		moveq	#0,d0
		move.b	stageno+1,d0
		lsl.w	#3,d0
		adda.w	d0,a2
		moveq	#0,d1
		tst.b	stageno+1
		bne.b	loc_3E56
		moveq	#1,d1
		subq.w	#8,a2

loc_3E56:
		lea	playerwk,a1

LZWind_Loop:
		move.w	8(a1),d0
		cmp.w	(a2),d0
		bcs.w	loc_3EF4
		cmp.w	4(a2),d0
		bcc.w	loc_3EF4
		move.w	$C(a1),d2
		cmp.w	2(a2),d2
		bcs.b	loc_3EF4
		cmp.w	6(a2),d2
		bcc.b	loc_3EF4
		move.b	systemtimer+3,d0
		andi.b	#$3F,d0
		bne.b	loc_3E90
		move.w	#$D0,d0
		jsr	(soundset).l ;	play rushing water sound

loc_3E90:
		tst.b	($FFFFF7C9).w
		bne.w	locret_3F0A
		cmpi.b	#4,r_no0(a1)
		bcc.b	loc_3F06
		move.b	#1,watercoliflag
		subi.w	#$80,d0
		cmp.w	(a2),d0
		bcc.b	LZWind_Move
		moveq	#2,d0
		cmpi.b	#1,stageno+1
		bne.b	loc_3EBA
		neg.w	d0

loc_3EBA:
		add.w	d0,$C(a1)

LZWind_Move:
		addq.w	#4,8(a1)
		move.w	#$400,$10(a1)	; move Sonic horizontally
		move.w	#0,$12(a1)
		move.b	#$F,$1C(a1)	; use floating animation
		bset	#1,cddat(a1)
		btst	#0,swdata+0 ; is up pressed?
		beq.b	LZWind_MoveDown	; if not, branch
		subq.w	#1,$C(a1)	; move Sonic up

LZWind_MoveDown:
		btst	#1,swdata+0 ; is down being pressed?
		beq.b	locret_3EF2	; if not, branch
		addq.w	#1,$C(a1)	; move Sonic down

locret_3EF2:
		rts	
; ===========================================================================

loc_3EF4:				; XREF: LZWindTunnels
		addq.w	#8,a2
		dbra	d1,LZWind_Loop
		tst.b	watercoliflag
		beq.b	locret_3F0A
		move.b	#0,$1C(a1)

loc_3F06:
		clr.b	watercoliflag

locret_3F0A:
		rts	
; End of function LZWindTunnels

; ===========================================================================
		dc.w $A80, $300, $C10, $380
LZWind_Data:	dc.w $F80, $100, $1410,	$180, $460, $400, $710,	$480, $A20
		dc.w $600, $1610, $6E0,	$C80, $600, $13D0, $680
					; XREF: LZWindTunnels
		even

; ---------------------------------------------------------------------------
; Labyrinth Zone water slide subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LZWaterSlides:				; XREF: LZWaterEffects
		lea	playerwk,a1
		btst	#1,cddat(a1)
		bne.b	loc_3F6A
		move.w	$C(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.b	8(a1),d1
		andi.w	#$7F,d1
		add.w	d1,d0
		lea	mapwka,a2
		move.b	(a2,d0.w),d0
		lea	byte_3FCF(pc),a2
		moveq	#6,d1

loc_3F62:
		cmp.b	-(a2),d0
		dbeq	d1,loc_3F62
		beq.b	LZSlide_Move

loc_3F6A:
		tst.b	mizuflag
		beq.b	locret_3F7A
		move.w	#5,$3E(a1)
		clr.b	mizuflag

locret_3F7A:
		rts	
; ===========================================================================

LZSlide_Move:				; XREF: LZWaterSlides
		cmpi.w	#3,d1
		bcc.b	loc_3F84
		nop	

loc_3F84:
		bclr	#0,cddat(a1)
		move.b	byte_3FC0(pc,d1.w),d0
		move.b	d0,$14(a1)
		bpl.b	loc_3F9A
		bset	#0,cddat(a1)

loc_3F9A:
		clr.b	$15(a1)
		move.b	#$1B,$1C(a1)	; use Sonic's "sliding" animation
		move.b	#1,mizuflag ; lock	controls (except jumping)
		move.b	systemtimer+3,d0
		andi.b	#$1F,d0
		bne.b	locret_3FBE
		move.w	#$D0,d0
		jsr	(soundset).l ;	play water sound

locret_3FBE:
		rts	
; End of function LZWaterSlides

; ===========================================================================
byte_3FC0:	dc.b $A, $F5, $A, $F6, $F5, $F4, $B, 0,	2, 7, 3, $4C, $4B, 8, 4
byte_3FCF:	dc.b 0			; XREF: LZWaterSlides
		even

; ---------------------------------------------------------------------------
; Subroutine to	move Sonic in demo mode
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MoveSonicInDemo:			; XREF: Level_MainLoop; et al
		tst.w	($FFFFFFF0).w	; is demo mode on?
		bne.b	MoveDemo_On	; if yes, branch
		rts	
; ===========================================================================

; This is an unused subroutine for recording a demo

MoveDemo_Record:
		lea	($80000).l,a1
		move.w	($FFFFF790).w,d0
		adda.w	d0,a1
		move.b	swdata1+0,d0
		cmp.b	(a1),d0
		bne.b	loc_3FFA
		addq.b	#1,1(a1)
		cmpi.b	#$FF,1(a1)
		beq.b	loc_3FFA
		rts	
; ===========================================================================

loc_3FFA:				; XREF: MoveDemo_Record
		move.b	d0,2(a1)
		move.b	#0,3(a1)
		addq.w	#2,($FFFFF790).w
		andi.w	#$3FF,($FFFFF790).w
		rts	
; ===========================================================================

MoveDemo_On:				; XREF: MoveSonicInDemo
		tst.b	swdata1+0
		bpl.b	loc_4022
		tst.w	($FFFFFFF0).w
		bmi.b	loc_4022
		move.b	#4,gmmode

loc_4022:
		lea	(Demo_Index).l,a1
		moveq	#0,d0
		move.b	stageno,d0
		cmpi.b	#$10,gmmode
		bne.b	loc_4038
		moveq	#6,d0

loc_4038:
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		tst.w	($FFFFFFF0).w
		bpl.b	loc_4056
		lea	(Demo_EndIndex).l,a1
		move.w	($FFFFFFF4).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1

loc_4056:
		move.w	($FFFFF790).w,d0
		adda.w	d0,a1
		move.b	(a1),d0
		lea	swdata1+0,a0
		move.b	d0,d1
		move.b	(a0),d2
		eor.b	d2,d0
		move.b	d1,(a0)+
		and.b	d1,d0
		move.b	d0,(a0)+
		subq.b	#1,($FFFFF792).w
		bcc.b	locret_407E
		move.b	3(a1),($FFFFF792).w
		addq.w	#2,($FFFFF790).w

locret_407E:
		rts	
; End of function MoveSonicInDemo

; ===========================================================================
; ---------------------------------------------------------------------------
; Demo sequence	pointers
; ---------------------------------------------------------------------------
Demo_Index:
	include "_inc\Demo pointers for intro.asm"

Demo_EndIndex:
	include "_inc\Demo pointers for ending.asm"

		dc.b 0,	$8B, 8,	$37, 0,	$42, 8,	$5C, 0,	$6A, 8,	$5F, 0,	$2F, 8,	$2C
		dc.b 0,	$21, 8,	3, $28,	$30, 8,	8, 0, $2E, 8, $15, 0, $F, 8, $46
		dc.b 0,	$1A, 8,	$FF, 8,	$CA, 0,	0, 0, 0, 0, 0, 0, 0, 0,	0
		even

scdset:
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#word,d0
		move.l	scdtbl(pc,d0.w),scdadr
		rts

scdtbl:
		dc.l	zone1scd
		dc.l	zone2scd
		dc.l	zone3scd
		dc.l	zone4scd
		dc.l	zone5scd
		dc.l	zone6scd

; ---------------------------------------------------------------------------
; Oscillating number subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumInit:			; XREF: Level
		lea	($FFFFFE5E).w,a1
		lea	(Osc_Data).l,a2
		moveq	#$20,d1

Osc_Loop:
		move.w	(a2)+,(a1)+
		dbra	d1,Osc_Loop
		rts	
; End of function OscillateNumInit

; ===========================================================================
Osc_Data:	dc.w $7C, $80		; baseline values
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$80
		dc.w 0,	$50F0
		dc.w $11E, $2080
		dc.w $B4, $3080
		dc.w $10E, $5080
		dc.w $1C2, $7080
		dc.w $276, $80
		dc.w 0,	$80
		dc.w 0
		even

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


OscillateNumDo:				; XREF: Level
		cmpi.b	#6,($FFFFD024).w
		bcc.b	locret_41C4
		lea	($FFFFFE5E).w,a1
		lea	(Osc_Data2).l,a2
		move.w	(a1)+,d3
		moveq	#$F,d1

loc_4184:
		move.w	(a2)+,d2
		move.w	(a2)+,d4
		btst	d1,d3
		bne.b	loc_41A4
		move.w	2(a1),d0
		add.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bhi.b	loc_41BA
		bset	d1,d3
		bra.b	loc_41BA
; ===========================================================================

loc_41A4:				; XREF: OscillateNumDo
		move.w	2(a1),d0
		sub.w	d2,d0
		move.w	d0,2(a1)
		add.w	d0,0(a1)
		cmp.b	0(a1),d4
		bls.b	loc_41BA
		bclr	d1,d3

loc_41BA:
		addq.w	#4,a1
		dbra	d1,loc_4184
		move.w	d3,($FFFFFE5E).w

locret_41C4:
		rts	
; End of function OscillateNumDo

; ===========================================================================
Osc_Data2:	dc.w 2,	$10		; XREF: OscillateNumDo
		dc.w 2,	$18
		dc.w 2,	$20
		dc.w 2,	$30
		dc.w 4,	$20
		dc.w 8,	8
		dc.w 8,	$40
		dc.w 4,	$40
		dc.w 2,	$50
		dc.w 2,	$50
		dc.w 2,	$20
		dc.w 3,	$30
		dc.w 5,	$50
		dc.w 7,	$70
		dc.w 2,	$10
		dc.w 2,	$10
		even

; ---------------------------------------------------------------------------
; Subroutine to	change object animation	variables (rings, giant	rings)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


syspatchg:			; XREF: Level
		subq.b	#1,sys_pattim
		bpl.b	loc_421C
		move.b	#$B,sys_pattim
		subq.b	#1,sys_patno
		andi.b	#7,sys_patno

loc_421C:
		subq.b	#1,sys_pattim2
		bpl.b	loc_4232
		move.b	#7,sys_pattim2
		addq.b	#1,sys_patno2
		andi.b	#3,sys_patno2

loc_4232:
		subq.b	#1,sys_pattim3
		bpl.b	loc_4250
		move.b	#7,sys_pattim3
		addq.b	#1,sys_patno3
		cmpi.b	#6,sys_patno3
		bcs.b	loc_4250
		move.b	#0,sys_patno3

loc_4250:
		tst.b	sys_pattim4
		beq.b	locret_4272
		moveq	#0,d0
		move.b	sys_pattim4,d0
		add.w	sys_ringtimer,d0
		move.w	d0,sys_ringtimer
		rol.w	#7,d0
		andi.w	#3,d0
		move.b	d0,sys_patno4
		subq.b	#1,sys_pattim4

locret_4272:
		rts	
; End of function syspatchg

; ---------------------------------------------------------------------------
; End-of-act signpost pattern loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SignpostArtLoad:			; XREF: Level
		tst.w	editmode	; is debug mode	being used?
		bne.w	Signpost_Exit	; if yes, branch
		cmpi.b	#2,stageno+1 ; is act number 02 (act 3)?
		beq.b	Signpost_Exit	; if yes, branch
		move.w	scra_h_posit,d0
		move.w	scralim_right,d1
		subi.w	#$100,d1
		cmp.w	d1,d0		; has Sonic reached the	edge of	the level?
		blt.b	Signpost_Exit	; if not, branch
		tst.b	pltime_f
		beq.b	Signpost_Exit
		cmp.w	scralim_left,d1
		beq.b	Signpost_Exit
		move.w	d1,scralim_left ; move	left boundary to current screen	position
		moveq	#$12,d0
		bra.w	LoadPLC2	; load signpost	patterns
; ===========================================================================

Signpost_Exit:
		rts	
; End of function SignpostArtLoad

; ===========================================================================
Demo_GHZ:	incbin	demodata\i_ghz.bin
Demo_MZ:	incbin	demodata\i_mz.bin
Demo_SYZ:	incbin	demodata\i_syz.bin
Demo_SS:	incbin	demodata\i_ss.bin
; ===========================================================================

; ---------------------------------------------------------------------------
; Special Stage
; ---------------------------------------------------------------------------

SpecialStage:				; XREF: GameModeArray
		move.w	#$CA,d0
		bsr.w	soundset ; play special stage entry sound
		bsr.w	Pal_MakeFlash
		move	#$2700,sr
		lea	($C00004).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8004,(a6)
		move.w	#$8AAF,hintposi
		move.w	#$9011,(a6)
		move.w	($FFFFF60C).w,d0
		andi.b	#$BF,d0
		move.w	d0,($C00004).l
		bsr.w	scrinit
		move	#$2300,sr
		lea	($C00004).l,a5
		move.w	#$8F01,(a5)
		move.l	#$946F93FF,(a5)
		move.w	#$9780,(a5)
		move.l	#$50000081,(a5)
		move.w	#0,($C00000).l

loc_463C:
		move.w	(a5),d1
		btst	#1,d1
		bne.b	loc_463C
		move.w	#$8F02,(a5)
		bsr.w	SS_BGLoad
		moveq	#$14,d0
		bsr.w	RunPLC_ROM	; load special stage patterns
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

SS_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,SS_ClrObjRam	; clear	the object RAM

		lea	scra_h_posit,a1
		moveq	#0,d0
		move.w	#$3F,d1

SS_ClrRam:
		move.l	d0,(a1)+
		dbra	d1,SS_ClrRam	; clear	variables

		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$27,d1

SS_ClrRam2:
		move.l	d0,(a1)+
		dbra	d1,SS_ClrRam2	; clear	variables

		lea	($FFFFAA00).w,a1
		moveq	#0,d0
		move.w	#$7F,d1

SS_ClrNemRam:
		move.l	d0,(a1)+
		dbra	d1,SS_ClrNemRam	; clear	Nemesis	buffer

		clr.b	waterflag
		clr.w	gameflag
		moveq	#$A,d0
		bsr.w	colorset	; load special stage pallet
		jsr	SS_Load
		move.l	#0,scra_h_posit
		move.l	#0,scra_v_posit
		move.b	#9,playerwk ; load	special	stage Sonic object
		bsr.w	PalCycle_SS
		clr.w	rotdir	; set stage angle to "upright"
		move.w	#$40,rotspd ; set stage rotation	speed
		move.w	#$89,d0
		bsr.w	bgmset	; play special stage BG	music
		move.w	#0,($FFFFF790).w
		lea	(Demo_Index).l,a1
		moveq	#6,d0
		lsl.w	#2,d0
		movea.l	(a1,d0.w),a1
		move.b	1(a1),($FFFFF792).w
		subq.b	#1,($FFFFF792).w
		clr.w	plring
		clr.b	plring_f2
		move.w	#0,editmode
		move.w	#1800,($FFFFF614).w
		tst.b	($FFFFFFE2).w	; has debug cheat been entered?
		beq.b	SS_NoDebug	; if not, branch
		btst	#6,swdata1+0 ; is A	button pressed?
		beq.b	SS_NoDebug	; if not, branch
		move.b	#1,debugflag ; enable debug	mode

SS_NoDebug:
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l
		bsr.w	Pal_MakeWhite

; ---------------------------------------------------------------------------
; Main Special Stage loop
; ---------------------------------------------------------------------------

SS_MainLoop:
		bsr.w	PauseGame
		move.b	#$A,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		move.w	swdata1+0,swdata+0
		jsr	action
		jsr	patset
		jsr	SS_ShowLayout
		bsr.w	SS_BGAnimate
		tst.w	($FFFFFFF0).w	; is demo mode on?
		beq.b	SS_ChkEnd	; if not, branch
		tst.w	($FFFFF614).w	; is there time	left on	the demo?
		beq.w	SS_ToSegaScreen	; if not, branch

SS_ChkEnd:
		cmpi.b	#$10,gmmode ; is	game mode $10 (special stage)?
		beq.w	SS_MainLoop	; if yes, branch

		tst.w	($FFFFFFF0).w	; is demo mode on?
		bne.w	SS_ToSegaScreen	; if yes, branch
		move.b	#$C,gmmode ; set	screen mode to $0C (level)
		cmpi.w	#$503,stageno ; is level number higher than FZ?
		bcs.b	SS_End		; if not, branch
		clr.w	stageno	; set to GHZ1

SS_End:
		move.w	#60,($FFFFF614).w ; set	delay time to 1	second
		move.w	#$3F,($FFFFF626).w
		clr.w	($FFFFF794).w

SS_EndLoop:
		move.b	#$16,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	MoveSonicInDemo
		move.w	swdata1+0,swdata+0
		jsr	action
		jsr	patset
		jsr	SS_ShowLayout
		bsr.w	SS_BGAnimate
		subq.w	#1,($FFFFF794).w
		bpl.b	loc_47D4
		move.w	#2,($FFFFF794).w
		bsr.w	flashout

loc_47D4:
		tst.w	($FFFFF614).w
		bne.b	SS_EndLoop

		move	#$2700,sr
		lea	($C00004).l,a6
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		bsr.w	scrinit
		move.l	#$70000002,($C00004).l
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		jsr	scoreinit
		move	#$2300,sr
		moveq	#$11,d0
		bsr.w	colorset2	; load results screen pallet
		moveq	#0,d0
		bsr.w	LoadPLC2
		moveq	#$1B,d0
		bsr.w	LoadPLC		; load results screen patterns
		move.b	#1,plscore_f ; update score	counter
		move.b	#1,($FFFFF7D6).w ; update ring bonus counter
		move.w	plring,d0
		mulu.w	#10,d0		; multiply rings by 10
		move.w	d0,($FFFFF7D4).w ; set rings bonus
		move.w	#$8E,d0
		jsr	(soundset).l ;	play end-of-level music
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

SS_EndClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,SS_EndClrObjRam ; clear object RAM

		move.b	#$7E,($FFFFD5C0).w ; load results screen object

SS_NormalExit:
		bsr.w	PauseGame
		move.b	#$C,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	action
		jsr	patset
		bsr.w	RunPLC_RAM
		tst.w	gameflag
		beq.b	SS_NormalExit
		tst.l	($FFFFF680).w
		bne.b	SS_NormalExit
		move.w	#$CA,d0
		bsr.w	soundset ; play special stage exit sound
		bsr.w	Pal_MakeFlash
		rts	
; ===========================================================================

SS_ToSegaScreen:
		move.b	#0,gmmode ; set screen mode to 00 (Sega screen)
		rts

; ---------------------------------------------------------------------------
; Special stage	background loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_BGLoad:				; XREF: SpecialStage
		lea	($FF0000).l,a1
		lea	(Eni_SSBg1).l,a0 ; load	mappings for the birds and fish
		move.w	#$4051,d0
		bsr.w	mapdevr
		move.l	#$50000001,d3
		lea	($FF0080).l,a2
		moveq	#6,d7

loc_48BE:
		move.l	d3,d0
		moveq	#3,d6
		moveq	#0,d4
		cmpi.w	#3,d7
		bcc.b	loc_48CC
		moveq	#1,d4

loc_48CC:
		moveq	#7,d5

loc_48CE:
		movea.l	a2,a1
		eori.b	#1,d4
		bne.b	loc_48E2
		cmpi.w	#6,d7
		bne.b	loc_48F2
		lea	($FF0000).l,a1

loc_48E2:
		movem.l	d0-d4,-(sp)
		moveq	#7,d1
		moveq	#7,d2
		bsr.w	ShowVDPGraphics
		movem.l	(sp)+,d0-d4

loc_48F2:
		addi.l	#$100000,d0
		dbra	d5,loc_48CE
		addi.l	#$3800000,d0
		eori.b	#1,d4
		dbra	d6,loc_48CC
		addi.l	#$10000000,d3
		bpl.b	loc_491C
		swap	d3
		addi.l	#$C000,d3
		swap	d3

loc_491C:
		adda.w	#$80,a2
		dbra	d7,loc_48BE
		lea	($FF0000).l,a1
		lea	(Eni_SSBg2).l,a0 ; load	mappings for the clouds
		move.w	#$4000,d0
		bsr.w	mapdevr
		lea	($FF0000).l,a1
		move.l	#$40000003,d0
		moveq	#$3F,d1
		moveq	#$1F,d2
		bsr.w	ShowVDPGraphics
		lea	($FF0000).l,a1
		move.l	#$50000003,d0
		moveq	#$3F,d1
		moveq	#$3F,d2
		bsr.w	ShowVDPGraphics
		rts	
; End of function SS_BGLoad

; ---------------------------------------------------------------------------
; Pallet cycling routine - special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PalCycle_SS:				; XREF: loc_DA6; SpecialStage
		tst.w	pauseflag
		bne.b	locret_49E6
		subq.w	#1,($FFFFF79C).w
		bpl.b	locret_49E6
		lea	($C00004).l,a6
		move.w	($FFFFF79A).w,d0
		addq.w	#1,($FFFFF79A).w
		andi.w	#$1F,d0
		lsl.w	#2,d0
		lea	(byte_4A3C).l,a0
		adda.w	d0,a0
		move.b	(a0)+,d0
		bpl.b	loc_4992
		move.w	#$1FF,d0

loc_4992:
		move.w	d0,($FFFFF79C).w
		moveq	#0,d0
		move.b	(a0)+,d0
		move.w	d0,($FFFFF7A0).w
		lea	(byte_4ABC).l,a1
		lea	(a1,d0.w),a1
		move.w	#-$7E00,d0
		move.b	(a1)+,d0
		move.w	d0,(a6)
		move.b	(a1),($FFFFF616).w
		move.w	#-$7C00,d0
		move.b	(a0)+,d0
		move.w	d0,(a6)
		move.l	#$40000010,($C00004).l
		move.l	($FFFFF616).w,($C00000).l
		moveq	#0,d0
		move.b	(a0)+,d0
		bmi.b	loc_49E8
		lea	(Pal_SSCyc1).l,a1
		adda.w	d0,a1
		lea	($FFFFFB4E).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+

locret_49E6:
		rts	
; ===========================================================================

loc_49E8:				; XREF: PalCycle_SS
		move.w	($FFFFF79E).w,d1
		cmpi.w	#$8A,d0
		bcs.b	loc_49F4
		addq.w	#1,d1

loc_49F4:
		mulu.w	#$2A,d1
		lea	(Pal_SSCyc2).l,a1
		adda.w	d1,a1
		andi.w	#$7F,d0
		bclr	#0,d0
		beq.b	loc_4A18
		lea	($FFFFFB6E).w,a2
		move.l	(a1),(a2)+
		move.l	4(a1),(a2)+
		move.l	8(a1),(a2)+

loc_4A18:
		adda.w	#$C,a1
		lea	($FFFFFB5A).w,a2
		cmpi.w	#$A,d0
		bcs.b	loc_4A2E
		subi.w	#$A,d0
		lea	($FFFFFB7A).w,a2

loc_4A2E:
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		adda.w	d0,a1
		move.l	(a1)+,(a2)+
		move.w	(a1)+,(a2)+
		rts	
; End of function PalCycle_SS

; ===========================================================================
byte_4A3C:	dc.b 3,	0, 7, $92, 3, 0, 7, $90, 3, 0, 7, $8E, 3, 0, 7,	$8C
					; XREF: PalCycle_SS
		dc.b 3,	0, 7, $8B, 3, 0, 7, $80, 3, 0, 7, $82, 3, 0, 7,	$84
		dc.b 3,	0, 7, $86, 3, 0, 7, $88, 7, 8, 7, 0, 7,	$A, 7, $C
		dc.b $FF, $C, 7, $18, $FF, $C, 7, $18, 7, $A, 7, $C, 7,	8, 7, 0
		dc.b 3,	0, 6, $88, 3, 0, 6, $86, 3, 0, 6, $84, 3, 0, 6,	$82
		dc.b 3,	0, 6, $81, 3, 0, 6, $8A, 3, 0, 6, $8C, 3, 0, 6,	$8E
		dc.b 3,	0, 6, $90, 3, 0, 6, $92, 7, 2, 6, $24, 7, 4, 6,	$30
		dc.b $FF, 6, 6,	$3C, $FF, 6, 6,	$3C, 7,	4, 6, $30, 7, 2, 6, $24
		even
byte_4ABC:	dc.b $10, 1, $18, 0, $18, 1, $20, 0, $20, 1, $28, 0, $28, 1
					; XREF: PalCycle_SS
		even

Pal_SSCyc1:	incbin	pallet\c_rotmaptbl0.bin
		even
Pal_SSCyc2:	incbin	pallet\c_rotmaptbl1.bin
		even

; ---------------------------------------------------------------------------
; Subroutine to	make the special stage background animated
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_BGAnimate:				; XREF: SpecialStage
		move.w	($FFFFF7A0).w,d0
		bne.b	loc_4BF6
		move.w	#0,scrb_v_posit
		move.w	scrb_v_posit,($FFFFF618).w

loc_4BF6:
		cmpi.w	#8,d0
		bcc.b	loc_4C4E
		cmpi.w	#6,d0
		bne.b	loc_4C10
		addq.w	#1,scrz_h_posit
		addq.w	#1,scrb_v_posit
		move.w	scrb_v_posit,($FFFFF618).w

loc_4C10:
		moveq	#0,d0
		move.w	scrb_h_posit,d0
		neg.w	d0
		swap	d0
		lea	(byte_4CCC).l,a1
		lea	($FFFFAA00).w,a3
		moveq	#9,d3

loc_4C26:
		move.w	2(a3),d0
		bsr.w	sinset
		moveq	#0,d2
		move.b	(a1)+,d2
		muls.w	d2,d0
		asr.l	#8,d0
		move.w	d0,(a3)+
		move.b	(a1)+,d2
		ext.w	d2
		add.w	d2,(a3)+
		dbra	d3,loc_4C26
		lea	($FFFFAA00).w,a3
		lea	(byte_4CB8).l,a2
		bra.b	loc_4C7E
; ===========================================================================

loc_4C4E:				; XREF: SS_BGAnimate
		cmpi.w	#$C,d0
		bne.b	loc_4C74
		subq.w	#1,scrz_h_posit
		lea	($FFFFAB00).w,a3
		move.l	#$18000,d2
		moveq	#6,d1

loc_4C64:
		move.l	(a3),d0
		sub.l	d2,d0
		move.l	d0,(a3)+
		subi.l	#$2000,d2
		dbra	d1,loc_4C64

loc_4C74:
		lea	($FFFFAB00).w,a3
		lea	(byte_4CC4).l,a2

loc_4C7E:
		lea	($FFFFCC00).w,a1
		move.w	scrz_h_posit,d0
		neg.w	d0
		swap	d0
		moveq	#0,d3
		move.b	(a2)+,d3
		move.w	scrb_v_posit,d2
		neg.w	d2
		andi.w	#$FF,d2
		lsl.w	#2,d2

loc_4C9A:
		move.w	(a3)+,d0
		addq.w	#2,a3
		moveq	#0,d1
		move.b	(a2)+,d1
		subq.w	#1,d1

loc_4CA4:
		move.l	d0,(a1,d2.w)
		addq.w	#4,d2
		andi.w	#$3FC,d2
		dbra	d1,loc_4CA4
		dbra	d3,loc_4C9A
		rts	
; End of function SS_BGAnimate

; ===========================================================================
byte_4CB8:	dc.b 9,	$28, $18, $10, $28, $18, $10, $30, $18,	8, $10,	0
		even
byte_4CC4:	dc.b 6,	$30, $30, $30, $28, $18, $18, $18
		even
byte_4CCC:	dc.b 8,	2, 4, $FF, 2, 3, 8, $FF, 4, 2, 2, 3, 8,	$FD, 4,	2, 2, 3, 2, $FF
		even
					; XREF: SS_BGAnimate
; ===========================================================================

; ---------------------------------------------------------------------------
; Continue screen
; ---------------------------------------------------------------------------

ContinueScreen:				; XREF: GameModeArray
		bsr.w	fadein
		move	#$2700,sr
		move.w	($FFFFF60C).w,d0
		andi.b	#$BF,d0
		move.w	d0,($C00004).l
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8700,(a6)
		bsr.w	scrinit
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Cont_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,Cont_ClrObjRam ; clear object RAM

		move.l	#$70000002,($C00004).l
		lea	(Nem_TitleCard).l,a0 ; load title card patterns
		bsr.w	NemDec
		move.l	#$60000002,($C00004).l
		lea	(Nem_ContSonic).l,a0 ; load Sonic patterns
		bsr.w	NemDec
		move.l	#$6A200002,($C00004).l
		lea	(Nem_MiniSonic).l,a0 ; load continue screen patterns
		bsr.w	NemDec
		moveq	#10,d1
		jsr	contwrt	; run countdown	(start from 10)
		moveq	#$12,d0
		bsr.w	colorset	; load continue	screen pallet
		move.b	#$90,d0
		bsr.w	bgmset	; play continue	music
		move.w	#659,($FFFFF614).w ; set time delay to 11 seconds
		clr.l	scra_h_posit
		move.l	#$1000000,scra_v_posit
		move.b	#$81,playerwk ; load Sonic	object
		move.b	#$80,($FFFFD040).w ; load continue screen objects
		move.b	#$80,($FFFFD080).w
		move.b	#3,($FFFFD098).w
		move.b	#4,($FFFFD09A).w
		move.b	#$80,($FFFFD0C0).w
		move.b	#4,($FFFFD0E4).w
		jsr	action
		jsr	patset
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l
		bsr.w	fadeout

; ---------------------------------------------------------------------------
; Continue screen main loop
; ---------------------------------------------------------------------------

Cont_MainLoop:
		move.b	#$16,($FFFFF62A).w
		bsr.w	DelayProgram
		cmpi.b	#6,($FFFFD024).w
		bcc.b	loc_4DF2
		move	#$2700,sr
		move.w	($FFFFF614).w,d1
		divu.w	#$3C,d1
		andi.l	#$F,d1
		jsr	contwrt
		move	#$2300,sr

loc_4DF2:
		jsr	action
		jsr	patset
		cmpi.w	#$180,playerwk+xposi ; has Sonic	run off	screen?
		bcc.b	Cont_GotoLevel	; if yes, branch
		cmpi.b	#6,($FFFFD024).w
		bcc.b	Cont_MainLoop
		tst.w	($FFFFF614).w
		bne.w	Cont_MainLoop
		move.b	#0,gmmode ; go to Sega screen
		rts	
; ===========================================================================

Cont_GotoLevel:				; XREF: Cont_MainLoop
		move.b	#$C,gmmode ; set	screen mode to $0C (level)
		move.b	#3,pl_suu ; set lives to	3
		moveq	#0,d0
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.l	d0,plscore ; clear score
		move.b	d0,saveno ; clear lamppost count
		subq.b	#1,($FFFFFE18).w ; subtract 1 from continues
		rts	
; ===========================================================================

; ---------------------------------------------------------------------------
; Object 80 - Continue screen elements
; ---------------------------------------------------------------------------

Obj80:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj80_Index(pc,d0.w),d1
		jmp	Obj80_Index(pc,d1.w)
; ===========================================================================
Obj80_Index:	dc.w Obj80_Main-Obj80_Index
		dc.w Obj80_Display-Obj80_Index
		dc.w Obj80_MakeMiniSonic-Obj80_Index
		dc.w Obj80_ChkType-Obj80_Index
; ===========================================================================

Obj80_Main:				; XREF: Obj80_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj80,4(a0)
		move.w	#$8500,2(a0)
		move.b	#0,actflg(a0)
		move.b	#$3C,$19(a0)
		move.w	#$120,8(a0)
		move.w	#$C0,$A(a0)
		move.w	#0,plring ; clear rings

Obj80_Display:				; XREF: Obj80_Index
		jmp	actionsub
; ===========================================================================
Obj80_MiniSonicPos:
		dc.w $116, $12A, $102, $13E, $EE, $152, $DA, $166, $C6
		dc.w $17A, $B2,	$18E, $9E, $1A2, $8A
; ===========================================================================

Obj80_MakeMiniSonic:			; XREF: Obj80_Index
		movea.l	a0,a1
		lea	(Obj80_MiniSonicPos).l,a2
		moveq	#0,d1
		move.b	($FFFFFE18).w,d1
		subq.b	#2,d1
		bcc.b	loc_4EC4
		jmp	frameout
; ===========================================================================

loc_4EC4:				; XREF: Obj80_MakeMiniSonic
		moveq	#1,d3
		cmpi.b	#$E,d1
		bcs.b	loc_4ED0
		moveq	#0,d3
		moveq	#$E,d1

loc_4ED0:
		move.b	d1,d2
		andi.b	#1,d2

Obj80_MiniSonLoop:
		move.b	#$80,0(a1)	; load mini Sonic object
		move.w	(a2)+,8(a1)
		tst.b	d2
		beq.b	loc_4EEA
		subi.w	#$A,8(a1)

loc_4EEA:
		move.w	#$D0,$A(a1)
		move.b	#6,$1A(a1)
		move.b	#6,r_no0(a1)
		move.l	#Map_obj80,4(a1)
		move.w	#$8551,2(a1)
		move.b	#0,actflg(a1)
		lea	$40(a1),a1
		dbra	d1,Obj80_MiniSonLoop ; repeat for number of continues
		lea	-$40(a1),a1
		move.b	d3,userflag(a1)

Obj80_ChkType:				; XREF: Obj80_Index
		tst.b	userflag(a0)
		beq.b	loc_4F40
		cmpi.b	#6,($FFFFD024).w
		bcs.b	loc_4F40
		move.b	systemtimer+3,d0
		andi.b	#1,d0
		bne.b	loc_4F40
		tst.w	($FFFFD010).w
		bne.b	Obj80_Delete
		rts	
; ===========================================================================

loc_4F40:				; XREF: Obj80_ChkType
		move.b	systemtimer+3,d0
		andi.b	#$F,d0
		bne.b	Obj80_Display2
		bchg	#0,$1A(a0)

Obj80_Display2:
		jmp	actionsub
; ===========================================================================

Obj80_Delete:				; XREF: Obj80_ChkType
		jmp	frameout
; ===========================================================================

; ---------------------------------------------------------------------------
; Object 81 - Sonic on the continue screen
; ---------------------------------------------------------------------------

Obj81:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj81_Index(pc,d0.w),d1
		jsr	Obj81_Index(pc,d1.w)
		jmp	actionsub
; ===========================================================================
Obj81_Index:	dc.w Obj81_Main-Obj81_Index
		dc.w Obj81_ChkLand-Obj81_Index
		dc.w Obj81_Animate-Obj81_Index
		dc.w Obj81_Run-Obj81_Index
; ===========================================================================

Obj81_Main:				; XREF: Obj81_Index
		addq.b	#2,r_no0(a0)
		move.w	#$A0,8(a0)
		move.w	#$C0,$C(a0)
		move.l	#playpat,4(a0)
		move.w	#$780,2(a0)
		move.b	#4,actflg(a0)
		move.b	#2,$18(a0)
		move.b	#$1D,$1C(a0)	; use "floating" animation
		move.w	#$400,$12(a0)	; make Sonic fall from above

Obj81_ChkLand:				; XREF: Obj81_Index
		cmpi.w	#$1A0,$C(a0)	; has Sonic landed yet?
		bne.b	Obj81_ShowFall	; if not, branch
		addq.b	#2,r_no0(a0)
		clr.w	$12(a0)		; stop Sonic falling
		move.l	#Map_obj80,4(a0)
		move.w	#$8500,2(a0)
		move.b	#0,$1C(a0)
		bra.b	Obj81_Animate
; ===========================================================================

Obj81_ShowFall:				; XREF: Obj81_ChkLand
		jsr	speedset2
		jsr	spatset
		jmp	Loadplaywrtpat
; ===========================================================================

Obj81_Animate:				; XREF: Obj81_Index
		tst.b	swdata1+1	; is any button	pressed?
		bmi.b	Obj81_GetUp	; if yes, branch
		lea	(Ani_obj81).l,a1
		jmp	patchg
; ===========================================================================

Obj81_GetUp:				; XREF: Obj81_Animate
		addq.b	#2,r_no0(a0)
		move.l	#playpat,4(a0)
		move.w	#$780,2(a0)
		move.b	#$1E,$1C(a0)	; use "getting up" animation
		clr.w	$14(a0)
		subq.w	#8,$C(a0)
		move.b	#$E0,d0
		bsr.w	soundset ; fade out music

Obj81_Run:				; XREF: Obj81_Index
		cmpi.w	#$800,$14(a0)	; check	Sonic's "run speed" (not moving)
		bne.b	Obj81_AddSpeed	; if too low, branch
		move.w	#$1000,$10(a0)	; move Sonic to	the right
		bra.b	Obj81_ShowRun
; ===========================================================================

Obj81_AddSpeed:				; XREF: Obj81_Run
		addi.w	#$20,$14(a0)	; increase "run	speed"

Obj81_ShowRun:				; XREF: Obj81_Run
		jsr	speedset2
		jsr	spatset
		jmp	Loadplaywrtpat
; ===========================================================================
Ani_obj81:
	include "_anim\obj81.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Continue screen
; ---------------------------------------------------------------------------
Map_obj80:
	include "_maps\obj80.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Ending sequence in Green Hill	Zone
; ---------------------------------------------------------------------------

EndingSequence:				; XREF: GameModeArray
		move.b	#$E4,d0
		bsr.w	soundset ; stop music
		bsr.w	fadein
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

End_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,End_ClrObjRam ; clear object	RAM

		lea	($FFFFF628).w,a1
		moveq	#0,d0
		move.w	#$15,d1

End_ClrRam:
		move.l	d0,(a1)+
		dbra	d1,End_ClrRam	; clear	variables

		lea	scra_h_posit,a1
		moveq	#0,d0
		move.w	#$3F,d1

End_ClrRam2:
		move.l	d0,(a1)+
		dbra	d1,End_ClrRam2	; clear	variables

		lea	($FFFFFE60).w,a1
		moveq	#0,d0
		move.w	#$47,d1

End_ClrRam3:
		move.l	d0,(a1)+
		dbra	d1,End_ClrRam3	; clear	variables

		move	#$2700,sr
		move.w	($FFFFF60C).w,d0
		andi.b	#$BF,d0
		move.w	d0,($C00004).l
		bsr.w	scrinit
		lea	($C00004).l,a6
		move.w	#$8B03,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$857C,(a6)
		move.w	#$9001,(a6)
		move.w	#$8004,(a6)
		move.w	#$8720,(a6)
		move.w	#$8ADF,hintposi
		move.w	hintposi,(a6)
		move.w	#$1E,pl_air
		move.w	#$600,stageno ; set level	number to 0600 (extra flowers)
		cmpi.b	#6,($FFFFFE57).w ; do you have all 6 emeralds?
		beq.b	End_LoadData	; if yes, branch
		move.w	#$601,stageno ; set level	number to 0601 (no flowers)

End_LoadData:
		moveq	#$1C,d0
		bsr.w	RunPLC_ROM	; load ending sequence patterns
		jsr	scoreinit
		bsr.w	scr_set
		bsr.w	scroll
		bset	#2,($FFFFF754).w
		bsr.w	mapinit
		bsr.w	mapwrt
		move.l	#zone1scd,scdadr ; load collision	index
		move	#$2300,sr
		lea	(Kos_EndFlowers).l,a0 ;	load extra flower patterns
		lea	($FFFF9400).w,a1 ; RAM address to buffer the patterns
		bsr.w	KosDec
		moveq	#3,d0
		bsr.w	colorset	; load Sonic's pallet
		move.w	#$8B,d0
		bsr.w	bgmset	; play ending sequence music
		btst	#6,swdata1+0 ; is button A pressed?
		beq.b	End_LoadSonic	; if not, branch
		move.b	#1,debugflag ; enable debug	mode

End_LoadSonic:
		move.b	#1,playerwk ; load	Sonic object
		bset	#0,playerwk+cddat ; make	Sonic face left
		move.b	#1,plautoflag ; lock	controls
		move.w	#$400,swdata+0 ; move Sonic to the	left
		move.w	#$F800,playerwk+mspeed ; set Sonic's speed
		move.b	#$21,($FFFFD040).w ; load HUD object
		jsr	ObjPosLoad
		jsr	action
		jsr	patset
		moveq	#0,d0
		move.w	d0,plring
		move.l	d0,pltime
		move.b	d0,plring_f2
		move.b	d0,plpower_b
		move.b	d0,plpower_m
		move.b	d0,plpower_s
		move.b	d0,($FFFFFE2F).w
		move.w	d0,editmode
		move.w	d0,gameflag
		move.w	d0,gametimer
		bsr.w	OscillateNumInit
		move.b	#1,plscore_f
		move.b	#1,plring_f
		move.b	#0,pltime_f
		move.w	#1800,($FFFFF614).w
		move.b	#$18,($FFFFF62A).w
		bsr.w	DelayProgram
		move.w	($FFFFF60C).w,d0
		ori.b	#$40,d0
		move.w	d0,($C00004).l
		move.w	#$3F,($FFFFF626).w
		bsr.w	fadeout

; ---------------------------------------------------------------------------
; Main ending sequence loop
; ---------------------------------------------------------------------------

End_MainLoop:
		bsr.w	PauseGame
		move.b	#$18,($FFFFF62A).w
		bsr.w	DelayProgram
		addq.w	#1,gametimer
		bsr.w	End_MoveSonic
		jsr	action
		bsr.w	scroll
		jsr	patset
		jsr	ObjPosLoad
		bsr.w	clchgctr
		bsr.w	OscillateNumDo
		bsr.w	syspatchg
		cmpi.b	#$18,gmmode ; is	scene number $18 (ending)?
		beq.b	loc_52DA	; if yes, branch
		move.b	#$1C,gmmode ; set scene to $1C (credits)
		move.b	#$91,d0
		bsr.w	soundset ; play credits music
		move.w	#0,($FFFFFFF4).w ; set credits index number to 0
		rts	
; ===========================================================================

loc_52DA:
		tst.w	gameflag	; is level set to restart?
		beq.w	End_MainLoop	; if not, branch

		clr.w	gameflag
		move.w	#$3F,($FFFFF626).w
		clr.w	($FFFFF794).w

End_AllEmlds:				; XREF: loc_5334
		bsr.w	PauseGame
		move.b	#$18,($FFFFF62A).w
		bsr.w	DelayProgram
		addq.w	#1,gametimer
		bsr.w	End_MoveSonic
		jsr	action
		bsr.w	scroll
		jsr	patset
		jsr	ObjPosLoad
		bsr.w	OscillateNumDo
		bsr.w	syspatchg
		subq.w	#1,($FFFFF794).w
		bpl.b	loc_5334
		move.w	#2,($FFFFF794).w
		bsr.w	flashout

loc_5334:
		tst.w	gameflag
		beq.w	End_AllEmlds
		clr.w	gameflag
		move.w	#$2E2F,($FFFFA480).w ; modify level layout
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	scra_h_posit,a3
		lea	mapwka,a4
		move.w	#$4000,d2
		bsr.w	mapwrt2
		moveq	#$13,d0
		bsr.w	colorset	; load ending pallet
		bsr.w	Pal_MakeWhite
		bra.w	End_MainLoop

; ---------------------------------------------------------------------------
; Subroutine controlling Sonic on the ending sequence
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


End_MoveSonic:				; XREF: End_MainLoop
		move.b	($FFFFF7D7).w,d0
		bne.b	End_MoveSonic2
		cmpi.w	#$90,playerwk+xposi ; has Sonic passed $90 on y-axis?
		bcc.b	End_MoveSonExit	; if not, branch
		addq.b	#2,($FFFFF7D7).w
		move.b	#1,plautoflag ; lock	player's controls
		move.w	#$800,swdata+0 ; move Sonic to the	right
		rts	
; ===========================================================================

End_MoveSonic2:				; XREF: End_MoveSonic
		subq.b	#2,d0
		bne.b	End_MoveSonic3
		cmpi.w	#$A0,playerwk+xposi ; has Sonic passed $A0 on y-axis?
		bcs.b	End_MoveSonExit	; if not, branch
		addq.b	#2,($FFFFF7D7).w
		moveq	#0,d0
		move.b	d0,plautoflag
		move.w	d0,swdata+0 ; stop	Sonic moving
		move.w	d0,playerwk+mspeed
		move.b	#$81,($FFFFF7C8).w
		move.b	#3,($FFFFD01A).w
		move.w	#$505,playerwk+mstno ; use "standing" animation
		move.b	#3,($FFFFD01E).w
		rts	
; ===========================================================================

End_MoveSonic3:				; XREF: End_MoveSonic
		subq.b	#2,d0
		bne.b	End_MoveSonExit
		addq.b	#2,($FFFFF7D7).w
		move.w	#$A0,playerwk+xposi
		move.b	#$87,playerwk ; load Sonic	ending sequence	object
		clr.w	($FFFFD024).w

End_MoveSonExit:
		rts	
; End of function End_MoveSonic

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 87 - Sonic on ending sequence
; ---------------------------------------------------------------------------

Obj87:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj87_Index(pc,d0.w),d1
		jsr	Obj87_Index(pc,d1.w)
		jmp	actionsub
; ===========================================================================
Obj87_Index:	dc.w Obj87_Main-Obj87_Index, Obj87_MakeEmlds-Obj87_Index
		dc.w Obj87_Animate-Obj87_Index,	Obj87_LookUp-Obj87_Index
		dc.w Obj87_ClrObjRam-Obj87_Index, Obj87_Animate-Obj87_Index
		dc.w Obj87_MakeLogo-Obj87_Index, Obj87_Animate-Obj87_Index
		dc.w Obj87_Leap-Obj87_Index, Obj87_Animate-Obj87_Index
; ===========================================================================

Obj87_Main:				; XREF: Obj87_Index
		cmpi.b	#6,($FFFFFE57).w ; do you have all 6 emeralds?
		beq.b	Obj87_Main2	; if yes, branch
		addi.b	#$10,r_no1(a0)	; else,	skip emerald sequence
		move.w	#$D8,$30(a0)
		rts	
; ===========================================================================

Obj87_Main2:				; XREF: Obj87_Main
		addq.b	#2,r_no1(a0)
		move.l	#Map_obj87,4(a0)
		move.w	#$3E1,2(a0)
		move.b	#4,actflg(a0)
		clr.b	cddat(a0)
		move.b	#2,$18(a0)
		move.b	#0,$1A(a0)
		move.w	#$50,$30(a0)	; set duration for Sonic to pause

Obj87_MakeEmlds:			; XREF: Obj87_Index
		subq.w	#1,$30(a0)	; subtract 1 from duration
		bne.b	Obj87_Wait
		addq.b	#2,r_no1(a0)
		move.w	#1,$1C(a0)
		move.b	#$88,($FFFFD400).w ; load chaos	emeralds objects

Obj87_Wait:
		rts	
; ===========================================================================

Obj87_LookUp:				; XREF: Obj87_Index
		cmpi.w	#$2000,($FFD43C).l
		bne.b	locret_5480
		move.w	#1,gameflag ; set level to	restart	(causes	flash)
		move.w	#$5A,$30(a0)
		addq.b	#2,r_no1(a0)

locret_5480:
		rts	
; ===========================================================================

Obj87_ClrObjRam:			; XREF: Obj87_Index
		subq.w	#1,$30(a0)
		bne.b	Obj87_Wait2
		lea	($FFFFD400).w,a1
		move.w	#$FF,d1

Obj87_ClrLoop:
		clr.l	(a1)+
		dbra	d1,Obj87_ClrLoop ; clear the object RAM
		move.w	#1,gameflag
		addq.b	#2,r_no1(a0)
		move.b	#1,$1C(a0)
		move.w	#$3C,$30(a0)

Obj87_Wait2:
		rts	
; ===========================================================================

Obj87_MakeLogo:				; XREF: Obj87_Index
		subq.w	#1,$30(a0)
		bne.b	Obj87_Wait3
		addq.b	#2,r_no1(a0)
		move.w	#$B4,$30(a0)
		move.b	#2,$1C(a0)
		move.b	#$89,($FFFFD400).w ; load "SONIC THE HEDGEHOG" object

Obj87_Wait3:
		rts	
; ===========================================================================

Obj87_Animate:				; XREF: Obj87_Index
		lea	(Ani_obj87).l,a1
		jmp	patchg
; ===========================================================================

Obj87_Leap:				; XREF: Obj87_Index
		subq.w	#1,$30(a0)
		bne.b	Obj87_Wait4
		addq.b	#2,r_no1(a0)
		move.l	#Map_obj87,4(a0)
		move.w	#$3E1,2(a0)
		move.b	#4,actflg(a0)
		clr.b	cddat(a0)
		move.b	#2,$18(a0)
		move.b	#5,$1A(a0)
		move.b	#2,$1C(a0)	; use "leaping"	animation
		move.b	#$89,($FFFFD400).w ; load "SONIC THE HEDGEHOG" object
		bra.b	Obj87_Animate
; ===========================================================================

Obj87_Wait4:				; XREF: Obj87_Leap
		rts	
; ===========================================================================
Ani_obj87:
	include "_anim\obj87.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 88 - chaos emeralds on	the ending sequence
; ---------------------------------------------------------------------------

Obj88:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj88_Index(pc,d0.w),d1
		jsr	Obj88_Index(pc,d1.w)
		jmp	actionsub
; ===========================================================================
Obj88_Index:	dc.w Obj88_Main-Obj88_Index
		dc.w Obj88_Move-Obj88_Index
; ===========================================================================

Obj88_Main:				; XREF: Obj88_Index
		cmpi.b	#2,($FFFFD01A).w
		beq.b	Obj88_Main2
		addq.l	#4,sp
		rts	
; ===========================================================================

Obj88_Main2:				; XREF: Obj88_Main
		move.w	playerwk+xposi,8(a0) ; match X position with Sonic
		move.w	playerwk+yposi,$C(a0) ; match Y position	with Sonic
		movea.l	a0,a1
		moveq	#0,d3
		moveq	#1,d2
		moveq	#5,d1

Obj88_MainLoop:
		move.b	#$88,(a1)	; load chaos emerald object
		addq.b	#2,r_no0(a1)
		move.l	#Map_obj88,4(a1)
		move.w	#$3C5,2(a1)
		move.b	#4,actflg(a1)
		move.b	#1,$18(a1)
		move.w	8(a0),$38(a1)
		move.w	$C(a0),$3A(a1)
		move.b	d2,$1C(a1)
		move.b	d2,$1A(a1)
		addq.b	#1,d2
		move.b	d3,direc(a1)
		addi.b	#$2A,d3
		lea	$40(a1),a1
		dbra	d1,Obj88_MainLoop ; repeat 5 more times

Obj88_Move:				; XREF: Obj88_Index
		move.w	$3E(a0),d0
		add.w	d0,direc(a0)
		move.b	direc(a0),d0
		jsr	(sinset).l
		moveq	#0,d4
		move.b	$3C(a0),d4
		muls.w	d4,d1
		asr.l	#8,d1
		muls.w	d4,d0
		asr.l	#8,d0
		add.w	$38(a0),d1
		add.w	$3A(a0),d0
		move.w	d1,8(a0)
		move.w	d0,$C(a0)
		cmpi.w	#$2000,$3C(a0)
		beq.b	loc_55FA
		addi.w	#$20,$3C(a0)

loc_55FA:
		cmpi.w	#$2000,$3E(a0)
		beq.b	loc_5608
		addi.w	#$20,$3E(a0)

loc_5608:
		cmpi.w	#$140,$3A(a0)
		beq.b	locret_5614
		subq.w	#1,$3A(a0)

locret_5614:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 89 - "SONIC THE HEDGEHOG" text	on the ending sequence
; ---------------------------------------------------------------------------

Obj89:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj89_Index(pc,d0.w),d1
		jmp	Obj89_Index(pc,d1.w)
; ===========================================================================
Obj89_Index:	dc.w Obj89_Main-Obj89_Index
		dc.w Obj89_Move-Obj89_Index
		dc.w Obj89_GotoCredits-Obj89_Index
; ===========================================================================

Obj89_Main:				; XREF: Obj89_Index
		addq.b	#2,r_no0(a0)
		move.w	#-$20,8(a0)	; object starts	outside	the level boundary
		move.w	#$D8,$A(a0)
		move.l	#Map_obj89,4(a0)
		move.w	#$5C5,2(a0)
		move.b	#0,actflg(a0)
		move.b	#0,$18(a0)

Obj89_Move:				; XREF: Obj89_Index
		cmpi.w	#$C0,8(a0)	; has object reached $C0?
		beq.b	Obj89_Delay	; if yes, branch
		addi.w	#$10,8(a0)	; move object to the right
		bra.w	actionsub
; ===========================================================================

Obj89_Delay:				; XREF: Obj89_Move
		addq.b	#2,r_no0(a0)
		move.w	#120,$30(a0)	; set duration for delay (2 seconds)

Obj89_GotoCredits:			; XREF: Obj89_Index
		subq.w	#1,$30(a0)	; subtract 1 from duration
		bpl.b	Obj89_Display
		move.b	#$1C,gmmode ; exit to credits

Obj89_Display:
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - Sonic on the ending	sequence
; ---------------------------------------------------------------------------
Map_obj87:
	include "_maps\obj87.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - chaos emeralds on the ending sequence
; ---------------------------------------------------------------------------
Map_obj88:
	include "_maps\obj88.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - "SONIC THE HEDGEHOG" text on the ending sequence
; ---------------------------------------------------------------------------
Map_obj89:
	include "_maps\obj89.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Credits ending sequence
; ---------------------------------------------------------------------------

Credits:				; XREF: GameModeArray
		bsr.w	ClearPLC
		bsr.w	fadein
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		move.w	#$9200,(a6)
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)
		clr.b	waterflag
		bsr.w	scrinit
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

Cred_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,Cred_ClrObjRam ; clear object RAM

		move.l	#$74000002,($C00004).l
		lea	(Nem_CreditText).l,a0 ;	load credits alphabet patterns
		bsr.w	NemDec
		lea	($FFFFFB80).w,a1
		moveq	#0,d0
		move.w	#$1F,d1

Cred_ClrPallet:
		move.l	d0,(a1)+
		dbra	d1,Cred_ClrPallet ; fill pallet	with black ($0000)

		moveq	#3,d0
		bsr.w	colorset	; load Sonic's pallet
		move.b	#$8A,($FFFFD080).w ; load credits object
		jsr	action
		jsr	patset
		bsr.w	EndingDemoLoad
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2 ;	load block mappings etc
		lea	(a2,d0.w),a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.b	loc_5862
		bsr.w	LoadPLC		; load level patterns

loc_5862:
		moveq	#1,d0
		bsr.w	LoadPLC		; load standard	level patterns
		move.w	#120,($FFFFF614).w ; display a credit for 2 seconds
		bsr.w	fadeout

Cred_WaitLoop:
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		bsr.w	RunPLC_RAM
		tst.w	($FFFFF614).w	; have 2 seconds elapsed?
		bne.b	Cred_WaitLoop	; if not, branch
		tst.l	($FFFFF680).w	; have level gfx finished decompressing?
		bne.b	Cred_WaitLoop	; if not, branch
		cmpi.w	#9,($FFFFFFF4).w ; have	the credits finished?
		beq.w	TryAgainEnd	; if yes, branch
		rts	

; ---------------------------------------------------------------------------
; Ending sequence demo loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


EndingDemoLoad:				; XREF: Credits
		move.w	($FFFFFFF4).w,d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	EndDemo_Levels(pc,d0.w),d0 ; load level	array
		move.w	d0,stageno ; set level from level	array
		addq.w	#1,($FFFFFFF4).w
		cmpi.w	#9,($FFFFFFF4).w ; have	credits	finished?
		bcc.b	EndDemo_Exit	; if yes, branch
		move.w	#$8001,($FFFFFFF0).w ; force demo mode
		move.b	#8,gmmode ; set game mode to 08 (demo)
		move.b	#3,pl_suu ; set lives to	3
		moveq	#0,d0
		move.w	d0,plring ; clear rings
		move.l	d0,pltime ; clear time
		move.l	d0,plscore ; clear score
		move.b	d0,saveno ; clear lamppost counter
		cmpi.w	#4,($FFFFFFF4).w ; is SLZ demo running?
		bne.b	EndDemo_Exit	; if not, branch
		lea	(EndDemo_LampVar).l,a1 ; load lamppost variables
		lea	saveno,a2
		move.w	#8,d0

EndDemo_LampLoad:
		move.l	(a1)+,(a2)+
		dbra	d0,EndDemo_LampLoad

EndDemo_Exit:
		rts	
; End of function EndingDemoLoad

; ===========================================================================
; ---------------------------------------------------------------------------
; Levels used in the end sequence demos
; ---------------------------------------------------------------------------
EndDemo_Levels:	incbin	misc\dm_ord2.bin

; ---------------------------------------------------------------------------
; Lamppost variables in the end sequence demo (Star Light Zone)
; ---------------------------------------------------------------------------
EndDemo_LampVar:
		dc.b 1,	1		; XREF: EndingDemoLoad
		dc.w $A00, $62C, $D
		dc.l 0
		dc.b 0,	0
		dc.w $800, $957, $5CC, $4AB, $3A6, 0, $28C, 0, 0, $308
		dc.b 1,	1
; ===========================================================================
; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screens
; ---------------------------------------------------------------------------

TryAgainEnd:				; XREF: Credits
		bsr.w	ClearPLC
		bsr.w	fadein
		lea	($C00004).l,a6
		move.w	#$8004,(a6)
		move.w	#$8230,(a6)
		move.w	#$8407,(a6)
		move.w	#$9001,(a6)
		move.w	#$9200,(a6)
		move.w	#$8B03,(a6)
		move.w	#$8720,(a6)
		clr.b	waterflag
		bsr.w	scrinit
		lea	($FFFFD000).w,a1
		moveq	#0,d0
		move.w	#$7FF,d1

TryAg_ClrObjRam:
		move.l	d0,(a1)+
		dbra	d1,TryAg_ClrObjRam ; clear object RAM

		moveq	#$1D,d0
		bsr.w	RunPLC_ROM	; load "TRY AGAIN" or "END" patterns
		lea	($FFFFFB80).w,a1
		moveq	#0,d0
		move.w	#$1F,d1

TryAg_ClrPallet:
		move.l	d0,(a1)+
		dbra	d1,TryAg_ClrPallet ; fill pallet with black ($0000)

		moveq	#$13,d0
		bsr.w	colorset	; load ending pallet
		clr.w	($FFFFFBC0).w
		move.b	#$8B,($FFFFD080).w ; load Eggman object
		jsr	action
		jsr	patset
		move.w	#1800,($FFFFF614).w ; show screen for 30 seconds
		bsr.w	fadeout

; ---------------------------------------------------------------------------
; "TRY AGAIN" and "END"	screen main loop
; ---------------------------------------------------------------------------
TryAg_MainLoop:
		bsr.w	PauseGame
		move.b	#4,($FFFFF62A).w
		bsr.w	DelayProgram
		jsr	action
		jsr	patset
		andi.b	#$80,swdata1+1 ; is	Start button pressed?
		bne.b	TryAg_Exit	; if yes, branch
		tst.w	($FFFFF614).w	; has 30 seconds elapsed?
		beq.b	TryAg_Exit	; if yes, branch
		cmpi.b	#$1C,gmmode
		beq.b	TryAg_MainLoop

TryAg_Exit:
		move.b	#0,gmmode ; go to Sega screen
		rts	

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8B - Eggman on "TRY AGAIN" and "END"	screens
; ---------------------------------------------------------------------------

Obj8B:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj8B_Index(pc,d0.w),d1
		jsr	Obj8B_Index(pc,d1.w)
		jmp	actionsub
; ===========================================================================
Obj8B_Index:	dc.w Obj8B_Main-Obj8B_Index
		dc.w Obj8B_Animate-Obj8B_Index
		dc.w Obj8B_Juggle-Obj8B_Index
		dc.w loc_5A8E-Obj8B_Index
; ===========================================================================

Obj8B_Main:				; XREF: Obj8B_Index
		addq.b	#2,r_no0(a0)
		move.w	#$120,8(a0)
		move.w	#$F4,$A(a0)
		move.l	#Map_obj8B,4(a0)
		move.w	#$3E1,2(a0)
		move.b	#0,actflg(a0)
		move.b	#2,$18(a0)
		move.b	#2,$1C(a0)	; use "END" animation
		cmpi.b	#6,($FFFFFE57).w ; do you have all 6 emeralds?
		beq.b	Obj8B_Animate	; if yes, branch
		move.b	#$8A,($FFFFD0C0).w ; load credits object
		move.w	#9,($FFFFFFF4).w ; use "TRY AGAIN" text
		move.b	#$8C,($FFFFD800).w ; load emeralds object on "TRY AGAIN" screen
		move.b	#0,$1C(a0)	; use "TRY AGAIN" animation

Obj8B_Animate:				; XREF: Obj8B_Index
		lea	(Ani_obj8B).l,a1
		jmp	patchg
; ===========================================================================

Obj8B_Juggle:				; XREF: Obj8B_Index
		addq.b	#2,r_no0(a0)
		moveq	#2,d0
		btst	#0,$1C(a0)
		beq.b	loc_5A6A
		neg.w	d0

loc_5A6A:
		lea	($FFFFD800).w,a1
		moveq	#5,d1

loc_5A70:
		move.b	d0,$3E(a1)
		move.w	d0,d2
		asl.w	#3,d2
		add.b	d2,direc(a1)
		lea	$40(a1),a1
		dbra	d1,loc_5A70
		addq.b	#1,$1A(a0)
		move.w	#112,$30(a0)

loc_5A8E:				; XREF: Obj8B_Index
		subq.w	#1,$30(a0)
		bpl.b	locret_5AA0
		bchg	#0,$1C(a0)
		move.b	#2,r_no0(a0)

locret_5AA0:
		rts	
; ===========================================================================
Ani_obj8B:
	include "_anim\obj8B.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8C - chaos emeralds on	the "TRY AGAIN"	screen
; ---------------------------------------------------------------------------

Obj8C:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj8C_Index(pc,d0.w),d1
		jsr	Obj8C_Index(pc,d1.w)
		jmp	actionsub
; ===========================================================================
Obj8C_Index:	dc.w Obj8C_Main-Obj8C_Index
		dc.w Obj8C_Move-Obj8C_Index
; ===========================================================================

Obj8C_Main:				; XREF: Obj8C_Index
		movea.l	a0,a1
		moveq	#0,d2
		moveq	#0,d3
		moveq	#5,d1
		sub.b	($FFFFFE57).w,d1

Obj8C_MakeEms:				; XREF: loc_5B42
		move.b	#$8C,(a1)	; load emerald object
		addq.b	#2,r_no0(a1)
		move.l	#Map_obj88,4(a1)
		move.w	#$3C5,2(a1)
		move.b	#0,actflg(a1)
		move.b	#1,$18(a1)
		move.w	#$104,8(a1)
		move.w	#$120,$38(a1)
		move.w	#$EC,$A(a1)
		move.w	$A(a1),$3A(a1)
		move.b	#$1C,$3C(a1)
		lea	($FFFFFE58).w,a3

Obj8C_ChkEms:
		moveq	#0,d0
		move.b	($FFFFFE57).w,d0
		subq.w	#1,d0
		bcs.b	loc_5B42

Obj8C_ChkEmLoop:
		cmp.b	(a3,d0.w),d2
		bne.b	loc_5B3E
		addq.b	#1,d2
		bra.b	Obj8C_ChkEms
; ===========================================================================

loc_5B3E:
		dbra	d0,Obj8C_ChkEmLoop ; checks which emeralds you have

loc_5B42:
		move.b	d2,$1A(a1)
		addq.b	#1,$1A(a1)
		addq.b	#1,d2
		move.b	#$80,direc(a1)
		move.b	d3,$1E(a1)
		move.b	d3,$1F(a1)
		addi.w	#$A,d3
		lea	$40(a1),a1
		dbra	d1,Obj8C_MakeEms

Obj8C_Move:				; XREF: Obj8C_Index
		tst.w	$3E(a0)
		beq.b	locret_5BBA
		tst.b	$1E(a0)
		beq.b	loc_5B78
		subq.b	#1,$1E(a0)
		bne.b	loc_5B80

loc_5B78:
		move.w	$3E(a0),d0
		add.w	d0,direc(a0)

loc_5B80:
		move.b	direc(a0),d0
		beq.b	loc_5B8C
		cmpi.b	#$80,d0
		bne.b	loc_5B96

loc_5B8C:
		clr.w	$3E(a0)
		move.b	$1F(a0),$1E(a0)

loc_5B96:
		jsr	(sinset).l
		moveq	#0,d4
		move.b	$3C(a0),d4
		muls.w	d4,d1
		asr.l	#8,d1
		muls.w	d4,d0
		asr.l	#8,d0
		add.w	$38(a0),d1
		add.w	$3A(a0),d0
		move.w	d1,8(a0)
		move.w	d0,$A(a0)

locret_5BBA:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - Eggman on	the "TRY AGAIN"	and "END" screens
; ---------------------------------------------------------------------------
Map_obj8B:
	include "_maps\obj8B.asm"

; ---------------------------------------------------------------------------
; Ending sequence demos
; ---------------------------------------------------------------------------
Demo_EndGHZ1:	incbin	demodata\e_ghz1.bin
		even
Demo_EndMZ:	incbin	demodata\e_mz.bin
		even
Demo_EndSYZ:	incbin	demodata\e_syz.bin
		even
Demo_EndLZ:	incbin	demodata\e_lz.bin
		even
Demo_EndSLZ:	incbin	demodata\e_slz.bin
		even
Demo_EndSBZ1:	incbin	demodata\e_sbz1.bin
		even
Demo_EndSBZ2:	incbin	demodata\e_sbz2.bin
		even
Demo_EndGHZ2:	incbin	demodata\e_ghz2.bin
		even

scr_set:				; XREF: TitleScreen; Level; EndingSequence
		moveq	#0,d0
		move.b	d0,($FFFFF740).w
		move.b	d0,($FFFFF741).w
		move.b	d0,($FFFFF746).w
		move.b	d0,($FFFFF748).w
		move.b	d0,($FFFFF742).w
		move.w	stageno,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		lea	limittbl(pc,d0.w),a0 ; load level	boundaries
		move.w	(a0)+,d0
		move.w	d0,($FFFFF730).w
		move.l	(a0)+,d0
		move.l	d0,scralim_left
		move.l	d0,($FFFFF720).w
		move.l	(a0)+,d0
		move.l	d0,scralim_up
		move.l	d0,($FFFFF724).w
		move.w	scralim_left,d0
		addi.w	#$240,d0
		move.w	d0,($FFFFF732).w
		move.w	#$1010,($FFFFF74A).w
		move.w	(a0)+,d0
		move.w	d0,($FFFFF73E).w
		bra.w	LevSz_ChkLamp
; ===========================================================================
; ---------------------------------------------------------------------------
; Level size array and ending start location array
; ---------------------------------------------------------------------------
limittbl:	incbin	misc\lvl_size.bin
		even

EndingStLocArray:
		incbin	misc\sloc_end.bin
		even

; ===========================================================================

LevSz_ChkLamp:				; XREF: scr_set
		tst.b	saveno	; have any lampposts been hit?
		beq.b	LevSz_StartLoc	; if not, branch
		jsr	playload
		move.w	playerwk+xposi,d1
		move.w	playerwk+yposi,d0
		bra.b	loc_60D0
; ===========================================================================

LevSz_StartLoc:				; XREF: scr_set
		move.w	stageno,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	StartLocArray(pc,d0.w),a1 ; load Sonic's start location
		tst.w	($FFFFFFF0).w	; is demo mode on?
		bpl.b	LevSz_SonicPos	; if not, branch
		move.w	($FFFFFFF4).w,d0
		subq.w	#1,d0
		lsl.w	#2,d0
		lea	EndingStLocArray(pc,d0.w),a1 ; load Sonic's start location

LevSz_SonicPos:
		moveq	#0,d1
		move.w	(a1)+,d1
		move.w	d1,playerwk+xposi ; set Sonic's position on x-axis
		moveq	#0,d0
		move.w	(a1),d0
		move.w	d0,playerwk+yposi ; set Sonic's position on y-axis

loc_60D0:				; XREF: LevSz_ChkLamp
		subi.w	#$A0,d1
		bcc.b	loc_60D8
		moveq	#0,d1

loc_60D8:
		move.w	scralim_right,d2
		cmp.w	d2,d1
		bcs.b	loc_60E2
		move.w	d2,d1

loc_60E2:
		move.w	d1,scra_h_posit
		subi.w	#$60,d0
		bcc.b	loc_60EE
		moveq	#0,d0

loc_60EE:
		cmp.w	scralim_down,d0
		blt.b	loc_60F8
		move.w	scralim_down,d0

loc_60F8:
		move.w	d0,scra_v_posit
		bsr.w	BgScrollSpeed
		moveq	#0,d0
		move.b	stageno,d0
		lsl.b	#2,d0
		move.l	LoopTileNums(pc,d0.w),($FFFFF7AC).w
		bra.w	LevSz_Unk
; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	start location array
; ---------------------------------------------------------------------------
StartLocArray:	incbin	misc\sloc_lev.bin
		even

; ---------------------------------------------------------------------------
; Which	256x256	tiles contain loops or roll-tunnels
; ---------------------------------------------------------------------------
; Format - 4 bytes per zone, referring to which 256x256 evoke special events:
; loop,	loop, tunnel, tunnel
; ---------------------------------------------------------------------------
LoopTileNums:	incbin	misc\loopnums.bin
		even

; ===========================================================================

LevSz_Unk:				; XREF: scr_set
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#3,d0
		lea	dword_61B4(pc,d0.w),a1
		lea	($FFFFF7F0).w,a2
		move.l	(a1)+,(a2)+
		move.l	(a1)+,(a2)+
		rts	
; End of function scr_set

; ===========================================================================
dword_61B4:	dc.l $700100, $1000100
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $8000100, $1000000
		dc.l $700100, $1000100

; ---------------------------------------------------------------------------
; Subroutine to	set scroll speed of some backgrounds
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BgScrollSpeed:				; XREF: scr_set
		tst.b	saveno
		bne.b	loc_6206
		move.w	d0,scrb_v_posit
		move.w	d0,scrc_v_posit
		move.w	d1,scrb_h_posit
		move.w	d1,scrc_h_posit
		move.w	d1,scrz_h_posit

loc_6206:
		moveq	#0,d2
		move.b	stageno,d2
		add.w	d2,d2
		move.w	BgScroll_Index(pc,d2.w),d2
		jmp	BgScroll_Index(pc,d2.w)
; End of function BgScrollSpeed

; ===========================================================================
BgScroll_Index:	dc.w BgScroll_GHZ-BgScroll_Index, BgScroll_LZ-BgScroll_Index
		dc.w BgScroll_MZ-BgScroll_Index, BgScroll_SLZ-BgScroll_Index
		dc.w BgScroll_SYZ-BgScroll_Index, BgScroll_SBZ-BgScroll_Index
		dc.w BgScroll_End-BgScroll_Index
; ===========================================================================

BgScroll_GHZ:				; XREF: BgScroll_Index
		bra.w	Deform_GHZ
; ===========================================================================

BgScroll_LZ:				; XREF: BgScroll_Index
		asr.l	#1,d0
		move.w	d0,scrb_v_posit
		rts	
; ===========================================================================

BgScroll_MZ:				; XREF: BgScroll_Index
		rts	
; ===========================================================================

BgScroll_SLZ:				; XREF: BgScroll_Index
		asr.l	#1,d0
		addi.w	#$C0,d0
		move.w	d0,scrb_v_posit
		rts	
; ===========================================================================

BgScroll_SYZ:				; XREF: BgScroll_Index
		asl.l	#4,d0
		move.l	d0,d2
		asl.l	#1,d0
		add.l	d2,d0
		asr.l	#8,d0
		move.w	d0,scrb_v_posit
		move.w	d0,scrc_v_posit
		rts	
; ===========================================================================

BgScroll_SBZ:				; XREF: BgScroll_Index
		asl.l	#4,d0
		asl.l	#1,d0
		asr.l	#8,d0
		move.w	d0,scrb_v_posit
		rts	
; ===========================================================================

BgScroll_End:				; XREF: BgScroll_Index
		move.w	#$1E,scrb_v_posit
		move.w	#$1E,scrc_v_posit
		rts	
; ===========================================================================
		move.w	#$A8,scrb_h_posit
		move.w	#$1E,scrb_v_posit
		move.w	#-$40,scrc_h_posit
		move.w	#$1E,scrc_v_posit
		rts

; ---------------------------------------------------------------------------
; Background layer deformation subroutines
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


scroll:				; XREF: TitleScreen; Level; EndingSequence
		tst.b	($FFFFF744).w
		beq.b	loc_628E
		rts	
; ===========================================================================

loc_628E:
		clr.w	($FFFFF754).w
		clr.w	($FFFFF756).w
		clr.w	($FFFFF758).w
		clr.w	($FFFFF75A).w
		bsr.w	ScrollHoriz
		bsr.w	ScrollVertical
		bsr.w	scrchk
		move.w	scra_h_posit,($FFFFF61A).w
		move.w	scra_v_posit,($FFFFF616).w
		move.w	scrb_h_posit,($FFFFF61C).w
		move.w	scrb_v_posit,($FFFFF618).w
		move.w	scrz_h_posit,($FFFFF620).w
		move.w	scrz_v_posit,($FFFFF61E).w
		moveq	#0,d0
		move.b	stageno,d0
		add.w	d0,d0
		move.w	Deform_Index(pc,d0.w),d0
		jmp	Deform_Index(pc,d0.w)
; End of function scroll

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for background layer deformation	code
; ---------------------------------------------------------------------------
Deform_Index:	dc.w Deform_GHZ-Deform_Index, Deform_LZ-Deform_Index
		dc.w Deform_MZ-Deform_Index, Deform_SLZ-Deform_Index
		dc.w Deform_SYZ-Deform_Index, Deform_SBZ-Deform_Index
		dc.w Deform_GHZ-Deform_Index
; ---------------------------------------------------------------------------
; Green	Hill Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_GHZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#5,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d5
		bsr.w	ScrollBlock1
		bsr.w	ScrollBlock4
		lea	($FFFFCC00).w,a1
		move.w	scra_v_posit,d0
		andi.w	#$7FF,d0
		lsr.w	#5,d0
		neg.w	d0
		addi.w	#$26,d0
		move.w	d0,scrc_v_posit
		move.w	d0,d4
		bsr.w	ScrollBlock3
		move.w	scrb_v_posit,($FFFFF618).w
		move.w	#$6F,d1
		sub.w	d4,d1
		move.w	scra_h_posit,d0
		cmpi.b	#4,gmmode
		bne.b	loc_633C
		moveq	#0,d0

loc_633C:
		neg.w	d0
		swap	d0
		move.w	scrb_h_posit,d0
		neg.w	d0

loc_6346:
		move.l	d0,(a1)+
		dbra	d1,loc_6346
		move.w	#$27,d1
		move.w	scrc_h_posit,d0
		neg.w	d0

loc_6356:
		move.l	d0,(a1)+
		dbra	d1,loc_6356
		move.w	scrc_h_posit,d0
		addi.w	#0,d0
		move.w	scra_h_posit,d2
		addi.w	#-$200,d2
		sub.w	d0,d2
		ext.l	d2
		asl.l	#8,d2
		divs.w	#$68,d2
		ext.l	d2
		asl.l	#8,d2
		moveq	#0,d3
		move.w	d0,d3
		move.w	#$47,d1
		add.w	d4,d1

loc_6384:
		move.w	d3,d0
		neg.w	d0
		move.l	d0,(a1)+
		swap	d3
		add.l	d2,d3
		swap	d3
		dbra	d1,loc_6384
		rts	
; End of function Deform_GHZ

; ---------------------------------------------------------------------------
; Labyrinth Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_LZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#7,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	ScrollBlock1
		move.w	scrb_v_posit,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	scra_h_posit,d0
		neg.w	d0
		swap	d0
		move.w	scrb_h_posit,d0
		neg.w	d0

loc_63C6:
		move.l	d0,(a1)+
		dbra	d1,loc_63C6
		move.w	waterposi,d0
		sub.w	scra_v_posit,d0
		rts	
; End of function Deform_LZ

; ---------------------------------------------------------------------------
; Marble Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_MZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.l	d4,d1
		asl.l	#1,d4
		add.l	d1,d4
		moveq	#0,d5
		bsr.w	ScrollBlock1
		move.w	#$200,d0
		move.w	scra_v_posit,d1
		subi.w	#$1C8,d1
		bcs.b	loc_6402
		move.w	d1,d2
		add.w	d1,d1
		add.w	d2,d1
		asr.w	#2,d1
		add.w	d1,d0

loc_6402:
		move.w	d0,scrc_v_posit
		bsr.w	ScrollBlock3
		move.w	scrb_v_posit,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	scra_h_posit,d0
		neg.w	d0
		swap	d0
		move.w	scrb_h_posit,d0
		neg.w	d0

loc_6426:
		move.l	d0,(a1)+
		dbra	d1,loc_6426
		rts	
; End of function Deform_MZ

; ---------------------------------------------------------------------------
; Star Light Zone background layer deformation code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SLZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#7,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#7,d5
		bsr.w	ScrollBlock2
		move.w	scrb_v_posit,($FFFFF618).w
		bsr.w	Deform_SLZ_2
		lea	($FFFFA800).w,a2
		move.w	scrb_v_posit,d0
		move.w	d0,d2
		subi.w	#$C0,d0
		andi.w	#$3F0,d0
		lsr.w	#3,d0
		lea	(a2,d0.w),a2
		lea	($FFFFCC00).w,a1
		move.w	#$E,d1
		move.w	scra_h_posit,d0
		neg.w	d0
		swap	d0
		andi.w	#$F,d2
		add.w	d2,d2
		move.w	(a2)+,d0
		jmp	loc_6482(pc,d2.w)
; ===========================================================================

loc_6480:				; XREF: Deform_SLZ
		move.w	(a2)+,d0

loc_6482:
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		move.l	d0,(a1)+
		dbra	d1,loc_6480
		rts	
; End of function Deform_SLZ


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SLZ_2:				; XREF: Deform_SLZ
		lea	($FFFFA800).w,a1
		move.w	scra_h_posit,d2
		neg.w	d2
		move.w	d2,d0
		asr.w	#3,d0
		sub.w	d2,d0
		ext.l	d0
		asl.l	#4,d0
		divs.w	#$1C,d0
		ext.l	d0
		asl.l	#4,d0
		asl.l	#8,d0
		moveq	#0,d3
		move.w	d2,d3
		move.w	#$1B,d1

loc_64CE:
		move.w	d3,(a1)+
		swap	d3
		add.l	d0,d3
		swap	d3
		dbra	d1,loc_64CE
		move.w	d2,d0
		asr.w	#3,d0
		move.w	#4,d1

loc_64E2:
		move.w	d0,(a1)+
		dbra	d1,loc_64E2
		move.w	d2,d0
		asr.w	#2,d0
		move.w	#4,d1

loc_64F0:
		move.w	d0,(a1)+
		dbra	d1,loc_64F0
		move.w	d2,d0
		asr.w	#1,d0
		move.w	#$1D,d1

loc_64FE:
		move.w	d0,(a1)+
		dbra	d1,loc_64FE
		rts	
; End of function Deform_SLZ_2

; ---------------------------------------------------------------------------
; Spring Yard Zone background layer deformation	code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SYZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#4,d5
		move.l	d5,d1
		asl.l	#1,d5
		add.l	d1,d5
		bsr.w	ScrollBlock1
		move.w	scrb_v_posit,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	scra_h_posit,d0
		neg.w	d0
		swap	d0
		move.w	scrb_h_posit,d0
		neg.w	d0

loc_653C:
		move.l	d0,(a1)+
		dbra	d1,loc_653C
		rts	
; End of function Deform_SYZ

; ---------------------------------------------------------------------------
; Scrap	Brain Zone background layer deformation	code
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Deform_SBZ:				; XREF: Deform_Index
		move.w	($FFFFF73A).w,d4
		ext.l	d4
		asl.l	#6,d4
		move.w	($FFFFF73C).w,d5
		ext.l	d5
		asl.l	#4,d5
		asl.l	#1,d5
		bsr.w	ScrollBlock1
		move.w	scrb_v_posit,($FFFFF618).w
		lea	($FFFFCC00).w,a1
		move.w	#$DF,d1
		move.w	scra_h_posit,d0
		neg.w	d0
		swap	d0
		move.w	scrb_h_posit,d0
		neg.w	d0

loc_6576:
		move.l	d0,(a1)+
		dbra	d1,loc_6576
		rts	
; End of function Deform_SBZ

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level horizontally as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz:				; XREF: scroll
		move.w	scra_h_posit,d4
		bsr.b	ScrollHoriz2
		move.w	scra_h_posit,d0
		andi.w	#$10,d0
		move.b	($FFFFF74A).w,d1
		eor.b	d1,d0
		bne.b	locret_65B0
		eori.b	#$10,($FFFFF74A).w
		move.w	scra_h_posit,d0
		sub.w	d4,d0
		bpl.b	loc_65AA
		bset	#2,($FFFFF754).w
		rts	
; ===========================================================================

loc_65AA:
		bset	#3,($FFFFF754).w

locret_65B0:
		rts	
; End of function ScrollHoriz


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollHoriz2:				; XREF: ScrollHoriz
		move.w	playerwk+xposi,d0
		sub.w	scra_h_posit,d0
		subi.w	#$90,d0
		bcs.b	loc_65F6
		subi.w	#$10,d0
		bcc.b	loc_65CC
		clr.w	($FFFFF73A).w
		rts	
; ===========================================================================

loc_65CC:
		cmpi.w	#$10,d0
		bcs.b	loc_65D6
		move.w	#$10,d0

loc_65D6:
		add.w	scra_h_posit,d0
		cmp.w	scralim_right,d0
		blt.b	loc_65E4
		move.w	scralim_right,d0

loc_65E4:
		move.w	d0,d1
		sub.w	scra_h_posit,d1
		asl.w	#8,d1
		move.w	d0,scra_h_posit
		move.w	d1,($FFFFF73A).w
		rts	
; ===========================================================================

loc_65F6:				; XREF: ScrollHoriz2
		add.w	scra_h_posit,d0
		cmp.w	scralim_left,d0
		bgt.b	loc_65E4
		move.w	scralim_left,d0
		bra.b	loc_65E4
; End of function ScrollHoriz2

; ===========================================================================
		tst.w	d0
		bpl.b	loc_6610
		move.w	#-2,d0
		bra.b	loc_65F6
; ===========================================================================

loc_6610:
		move.w	#2,d0
		bra.b	loc_65CC

; ---------------------------------------------------------------------------
; Subroutine to	scroll the level vertically as Sonic moves
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollVertical:				; XREF: scroll
		moveq	#0,d1
		move.w	playerwk+yposi,d0
		sub.w	scra_v_posit,d0
		btst	#2,playerwk+cddat
		beq.b	loc_662A
		subq.w	#5,d0

loc_662A:
		btst	#1,playerwk+cddat
		beq.b	loc_664A
		addi.w	#$20,d0
		sub.w	($FFFFF73E).w,d0
		bcs.b	loc_6696
		subi.w	#$40,d0
		bcc.b	loc_6696
		tst.b	($FFFFF75C).w
		bne.b	loc_66A8
		bra.b	loc_6656
; ===========================================================================

loc_664A:
		sub.w	($FFFFF73E).w,d0
		bne.b	loc_665C
		tst.b	($FFFFF75C).w
		bne.b	loc_66A8

loc_6656:
		clr.w	($FFFFF73C).w
		rts	
; ===========================================================================

loc_665C:
		cmpi.w	#$60,($FFFFF73E).w
		bne.b	loc_6684
		move.w	playerwk+mspeed,d1
		bpl.b	loc_666C
		neg.w	d1

loc_666C:
		cmpi.w	#$800,d1
		bcc.b	loc_6696
		move.w	#$600,d1
		cmpi.w	#6,d0
		bgt.b	loc_66F6
		cmpi.w	#-6,d0
		blt.b	loc_66C0
		bra.b	loc_66AE
; ===========================================================================

loc_6684:
		move.w	#$200,d1
		cmpi.w	#2,d0
		bgt.b	loc_66F6
		cmpi.w	#-2,d0
		blt.b	loc_66C0
		bra.b	loc_66AE
; ===========================================================================

loc_6696:
		move.w	#$1000,d1
		cmpi.w	#$10,d0
		bgt.b	loc_66F6
		cmpi.w	#-$10,d0
		blt.b	loc_66C0
		bra.b	loc_66AE
; ===========================================================================

loc_66A8:
		moveq	#0,d0
		move.b	d0,($FFFFF75C).w

loc_66AE:
		moveq	#0,d1
		move.w	d0,d1
		add.w	scra_v_posit,d1
		tst.w	d0
		bpl.w	loc_6700
		bra.w	loc_66CC
; ===========================================================================

loc_66C0:
		neg.w	d1
		ext.l	d1
		asl.l	#8,d1
		add.l	scra_v_posit,d1
		swap	d1

loc_66CC:
		cmp.w	scralim_up,d1
		bgt.b	loc_6724
		cmpi.w	#-$100,d1
		bgt.b	loc_66F0
		andi.w	#$7FF,d1
		andi.w	#$7FF,playerwk+yposi
		andi.w	#$7FF,scra_v_posit
		andi.w	#$3FF,scrb_v_posit
		bra.b	loc_6724
; ===========================================================================

loc_66F0:
		move.w	scralim_up,d1
		bra.b	loc_6724
; ===========================================================================

loc_66F6:
		ext.l	d1
		asl.l	#8,d1
		add.l	scra_v_posit,d1
		swap	d1

loc_6700:
		cmp.w	scralim_down,d1
		blt.b	loc_6724
		subi.w	#$800,d1
		bcs.b	loc_6720
		andi.w	#$7FF,playerwk+yposi
		subi.w	#$800,scra_v_posit
		andi.w	#$3FF,scrb_v_posit
		bra.b	loc_6724
; ===========================================================================

loc_6720:
		move.w	scralim_down,d1

loc_6724:
		move.w	scra_v_posit,d4
		swap	d1
		move.l	d1,d3
		sub.l	scra_v_posit,d3
		ror.l	#8,d3
		move.w	d3,($FFFFF73C).w
		move.l	d1,scra_v_posit
		move.w	scra_v_posit,d0
		andi.w	#$10,d0
		move.b	($FFFFF74B).w,d1
		eor.b	d1,d0
		bne.b	locret_6766
		eori.b	#$10,($FFFFF74B).w
		move.w	scra_v_posit,d0
		sub.w	d4,d0
		bpl.b	loc_6760
		bset	#0,($FFFFF754).w
		rts	
; ===========================================================================

loc_6760:
		bset	#1,($FFFFF754).w

locret_6766:
		rts	
; End of function ScrollVertical


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock1:				; XREF: Deform_GHZ; et al
		move.l	scrb_h_posit,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,scrb_h_posit
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74C).w,d3
		eor.b	d3,d1
		bne.b	loc_679C
		eori.b	#$10,($FFFFF74C).w
		sub.l	d2,d0
		bpl.b	loc_6796
		bset	#2,($FFFFF756).w
		bra.b	loc_679C
; ===========================================================================

loc_6796:
		bset	#3,($FFFFF756).w

loc_679C:
		move.l	scrb_v_posit,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,scrb_v_posit
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.b	locret_67D0
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.b	loc_67CA
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_67CA:
		bset	#1,($FFFFF756).w

locret_67D0:
		rts	
; End of function ScrollBlock1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock2:				; XREF: Deform_SLZ
		move.l	scrb_h_posit,d2
		move.l	d2,d0
		add.l	d4,d0
		move.l	d0,scrb_h_posit
		move.l	scrb_v_posit,d3
		move.l	d3,d0
		add.l	d5,d0
		move.l	d0,scrb_v_posit
		move.l	d0,d1
		swap	d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.b	locret_6812
		eori.b	#$10,($FFFFF74D).w
		sub.l	d3,d0
		bpl.b	loc_680C
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_680C:
		bset	#1,($FFFFF756).w

locret_6812:
		rts	
; End of function ScrollBlock2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock3:				; XREF: Deform_GHZ; et al
		move.w	scrb_v_posit,d3
		move.w	d0,scrb_v_posit
		move.w	d0,d1
		andi.w	#$10,d1
		move.b	($FFFFF74D).w,d2
		eor.b	d2,d1
		bne.b	locret_6842
		eori.b	#$10,($FFFFF74D).w
		sub.w	d3,d0
		bpl.b	loc_683C
		bset	#0,($FFFFF756).w
		rts	
; ===========================================================================

loc_683C:
		bset	#1,($FFFFF756).w

locret_6842:
		rts	
; End of function ScrollBlock3


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ScrollBlock4:				; XREF: Deform_GHZ
		move.w	scrc_h_posit,d2
		move.w	scrc_v_posit,d3
		move.w	($FFFFF73A).w,d0
		ext.l	d0
		asl.l	#7,d0
		add.l	d0,scrc_h_posit
		move.w	scrc_h_posit,d0
		andi.w	#$10,d0
		move.b	($FFFFF74E).w,d1
		eor.b	d1,d0
		bne.b	locret_6884
		eori.b	#$10,($FFFFF74E).w
		move.w	scrc_h_posit,d0
		sub.w	d2,d0
		bpl.b	loc_687E
		bset	#2,($FFFFF758).w
		bra.b	locret_6884
; ===========================================================================

loc_687E:
		bset	#3,($FFFFF758).w

locret_6884:
		rts	
; End of function ScrollBlock4


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6886:				; XREF: loc_C44
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	($FFFFF756).w,a2
		lea	scrb_h_posit,a3
		lea	mapwkb,a4
		move.w	#$6000,d2
		bsr.w	sub_6954
		lea	($FFFFF758).w,a2
		lea	scrc_h_posit,a3
		bra.w	sub_69F4
; End of function sub_6886

; ---------------------------------------------------------------------------
; Subroutine to	display	correct	tiles as you move
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


scrollwrt:			; XREF: Demo_Time
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	($FFFFFF32).w,a2
		lea	($FFFFFF18).w,a3
		lea	mapwkb,a4
		move.w	#$6000,d2
		bsr.w	sub_6954
		lea	($FFFFFF34).w,a2
		lea	($FFFFFF20).w,a3
		bsr.w	sub_69F4
		lea	($FFFFFF30).w,a2
		lea	($FFFFFF10).w,a3
		lea	mapwka,a4
		move.w	#$4000,d2
		tst.b	(a2)
		beq.b	locret_6952
		bclr	#0,(a2)
		beq.b	loc_6908
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6AD8

loc_6908:
		bclr	#1,(a2)
		beq.b	loc_6922
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6AD8

loc_6922:
		bclr	#2,(a2)
		beq.b	loc_6938
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6B04

loc_6938:
		bclr	#3,(a2)
		beq.b	locret_6952
		moveq	#-$10,d4
		move.w	#$140,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		move.w	#$140,d5
		bsr.w	sub_6B04

locret_6952:
		rts	
; End of function scrollwrt


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6954:				; XREF: sub_6886; scrollwrt
		tst.b	(a2)
		beq.w	locret_69F2
		bclr	#0,(a2)
		beq.b	loc_6972
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA

loc_6972:
		bclr	#1,(a2)
		beq.b	loc_698E
		move.w	#$E0,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	#$E0,d4
		moveq	#-$10,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA

loc_698E:
		bclr	#2,(a2)
		beq.b	loc_69BE
		moveq	#-$10,d4
		moveq	#-$10,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		moveq	#-$10,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.b	loc_69BE
		lsr.w	#4,d6
		cmpi.w	#$F,d6
		bcs.b	loc_69BA
		moveq	#$F,d6

loc_69BA:
		bsr.w	sub_6B06

loc_69BE:
		bclr	#3,(a2)
		beq.b	locret_69F2
		moveq	#-$10,d4
		move.w	#$140,d5
		bsr.w	sub_6C20
		moveq	#-$10,d4
		move.w	#$140,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.b	locret_69F2
		lsr.w	#4,d6
		cmpi.w	#$F,d6
		bcs.b	loc_69EE
		moveq	#$F,d6

loc_69EE:
		bsr.w	sub_6B06

locret_69F2:
		rts	
; End of function sub_6954


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_69F4:				; XREF: sub_6886; scrollwrt
		tst.b	(a2)
		beq.w	locret_6A80
		bclr	#2,(a2)
		beq.b	loc_6A3E
		cmpi.w	#$10,(a3)
		bcs.b	loc_6A3E
		move.w	($FFFFF7F0).w,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		moveq	#-$10,d5
		bsr.w	sub_6C20
		move.w	(sp)+,d4
		moveq	#-$10,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.b	loc_6A3E
		lsr.w	#4,d6
		subi.w	#$E,d6
		bcc.b	loc_6A3E
		neg.w	d6
		bsr.w	sub_6B06

loc_6A3E:
		bclr	#3,(a2)
		beq.b	locret_6A80
		move.w	($FFFFF7F0).w,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		move.w	#$140,d5
		bsr.w	sub_6C20
		move.w	(sp)+,d4
		move.w	#$140,d5
		move.w	($FFFFF7F0).w,d6
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d6
		blt.b	locret_6A80
		lsr.w	#4,d6
		subi.w	#$E,d6
		bcc.b	locret_6A80
		neg.w	d6
		bsr.w	sub_6B06

locret_6A80:
		rts	
; End of function sub_69F4

; ===========================================================================
		tst.b	(a2)
		beq.b	locret_6AD6
		bclr	#2,(a2)
		beq.b	loc_6AAC
		move.w	#$D0,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		moveq	#-$10,d5
		bsr.w	sub_6C3C
		move.w	(sp)+,d4
		moveq	#-$10,d5
		moveq	#2,d6
		bsr.w	sub_6B06

loc_6AAC:
		bclr	#3,(a2)
		beq.b	locret_6AD6
		move.w	#$D0,d4
		move.w	4(a3),d1
		andi.w	#-$10,d1
		sub.w	d1,d4
		move.w	d4,-(sp)
		move.w	#$140,d5
		bsr.w	sub_6C3C
		move.w	(sp)+,d4
		move.w	#$140,d5
		moveq	#2,d6
		bsr.w	sub_6B06

locret_6AD6:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6AD8:				; XREF: scrollwrt
		moveq	#$15,d6
; End of function sub_6AD8


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6ADA:				; XREF: sub_6954; mapwrt2
		move.l	#$800000,d7
		move.l	d0,d1

loc_6AE2:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_6BD6
		move.l	d1,d0
		bsr.w	sub_6B32
		addq.b	#4,d1
		andi.b	#$7F,d1
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d5
		dbra	d6,loc_6AE2
		rts	
; End of function sub_6ADA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6B04:				; XREF: scrollwrt
		moveq	#$F,d6
; End of function sub_6B04


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6B06:				; XREF: sub_6954
		move.l	#$800000,d7
		move.l	d0,d1

loc_6B0E:
		movem.l	d4-d5,-(sp)
		bsr.w	sub_6BD6
		move.l	d1,d0
		bsr.w	sub_6B32
		addi.w	#$100,d1
		andi.w	#$FFF,d1
		movem.l	(sp)+,d4-d5
		addi.w	#$10,d4
		dbra	d6,loc_6B0E
		rts	
; End of function sub_6B06


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6B32:				; XREF: sub_6ADA; sub_6B06
		or.w	d2,d0
		swap	d0
		btst	#4,(a0)
		bne.b	loc_6B6E
		btst	#3,(a0)
		bne.b	loc_6B4E
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,(a6)
		rts	
; ===========================================================================

loc_6B4E:
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.l	(a1)+,d4
		eori.l	#$8000800,d4
		swap	d4
		move.l	d4,(a6)
		rts	
; ===========================================================================

loc_6B6E:
		btst	#3,(a0)
		bne.b	loc_6B90
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$10001000,d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$10001000,d5
		move.l	d5,(a6)
		rts	
; ===========================================================================

loc_6B90:
		move.l	d0,(a5)
		move.l	(a1)+,d5
		move.l	(a1)+,d4
		eori.l	#$18001800,d4
		swap	d4
		move.l	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		eori.l	#$18001800,d5
		swap	d5
		move.l	d5,(a6)
		rts	
; End of function sub_6B32

; ===========================================================================
		rts	
; ===========================================================================
		move.l	d0,(a5)
		move.w	#$2000,d5
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		add.l	d7,d0
		move.l	d0,(a5)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		move.w	(a1)+,d4
		add.w	d5,d4
		move.w	d4,(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6BD6:				; XREF: sub_6ADA; sub_6B06
		lea	($FFFFB000).w,a1
		add.w	4(a3),d4
		add.w	(a3),d5
		move.w	d4,d3
		lsr.w	#1,d3
		andi.w	#$380,d3
		lsr.w	#3,d5
		move.w	d5,d0
		lsr.w	#5,d0
		andi.w	#$7F,d0
		add.w	d3,d0
		moveq	#-1,d3
		move.b	(a4,d0.w),d3
		beq.b	locret_6C1E
		subq.b	#1,d3
		andi.w	#$7F,d3
		ror.w	#7,d3
		add.w	d4,d4
		andi.w	#$1E0,d4
		andi.w	#$1E,d5
		add.w	d4,d3
		add.w	d5,d3
		movea.l	d3,a0
		move.w	(a0),d3
		andi.w	#$3FF,d3
		lsl.w	#3,d3
		adda.w	d3,a1

locret_6C1E:
		rts	
; End of function sub_6BD6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_6C20:				; XREF: scrollwrt; et al
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#3,d0
		swap	d0
		move.w	d4,d0
		rts	
; End of function sub_6C20


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||
; not used


sub_6C3C:
		add.w	4(a3),d4
		add.w	(a3),d5
		andi.w	#$F0,d4
		andi.w	#$1F0,d5
		lsl.w	#4,d4
		lsr.w	#2,d5
		add.w	d5,d4
		moveq	#2,d0
		swap	d0
		move.w	d4,d0
		rts	
; End of function sub_6C3C

; ---------------------------------------------------------------------------
; Subroutine to	load tiles as soon as the level	appears
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mapwrt:			; XREF: Level; EndingSequence
		lea	($C00004).l,a5
		lea	($C00000).l,a6
		lea	scra_h_posit,a3
		lea	mapwka,a4
		move.w	#$4000,d2
		bsr.b	mapwrt2
		lea	scrb_h_posit,a3
		lea	mapwkb,a4
		move.w	#$6000,d2
; End of function mapwrt


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mapwrt2:			; XREF: mapwrt
		moveq	#-$10,d4
		moveq	#$F,d6

loc_6C82:
		movem.l	d4-d6,-(sp)
		moveq	#0,d5
		move.w	d4,d1
		bsr.w	sub_6C20
		move.w	d1,d4
		moveq	#0,d5
		moveq	#$1F,d6
		bsr.w	sub_6ADA
		movem.l	(sp)+,d4-d6
		addi.w	#$10,d4
		dbra	d6,loc_6C82
		rts	
; End of function mapwrt2

; ---------------------------------------------------------------------------
; Main Load Block loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mapinit:			; XREF: Level; EndingSequence
		moveq	#0,d0
		move.b	stageno,d0
		lsl.w	#4,d0
		lea	(MainLoadBlocks).l,a2
		lea	(a2,d0.w),a2
		move.l	a2,-(sp)
		addq.l	#4,a2
		movea.l	(a2)+,a0
		lea	($FFFFB000).w,a1 ; RAM address for 16x16 mappings
		move.w	#0,d0
		bsr.w	mapdevr
		movea.l	(a2)+,a0
		lea	($FF0000).l,a1	; RAM address for 256x256 mappings
		bsr.w	KosDec
		bsr.w	LevelLayoutLoad
		move.w	(a2)+,d0
		move.w	(a2),d0
		andi.w	#$FF,d0
		cmpi.w	#$103,stageno ; is level SBZ3 (LZ4) ?
		bne.b	MLB_ChkSBZPal	; if not, branch
		moveq	#$C,d0		; use SB3 pallet

MLB_ChkSBZPal:
		cmpi.w	#$501,stageno ; is level SBZ2?
		beq.b	MLB_UsePal0E	; if yes, branch
		cmpi.w	#$502,stageno ; is level FZ?
		bne.b	MLB_NormalPal	; if not, branch

MLB_UsePal0E:
		moveq	#$E,d0		; use SBZ2/FZ pallet

MLB_NormalPal:
		bsr.w	colorset	; load pallet (based on	d0)
		movea.l	(sp)+,a2
		addq.w	#4,a2
		moveq	#0,d0
		move.b	(a2),d0
		beq.b	locret_6D10
		bsr.w	LoadPLC		; load pattern load cues

locret_6D10:
		rts	
; End of function mapinit

; ---------------------------------------------------------------------------
; Level	layout loading subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelLayoutLoad:			; XREF: TitleScreen; mapinit
		lea	mapwka,a3
		move.w	#$1FF,d1
		moveq	#0,d0

LevLoad_ClrRam:
		move.l	d0,(a3)+
		dbra	d1,LevLoad_ClrRam ; clear the RAM ($FFFFA400-A7FF)

		lea	mapwka,a3 ; RAM address for level layout
		moveq	#0,d1
		bsr.w	LevelLayoutLoad2 ; load	level layout into RAM
		lea	mapwkb,a3 ; RAM address for background layout
		moveq	#2,d1
; End of function LevelLayoutLoad

; "LevelLayoutLoad2" is	run twice - for	the level and the background

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LevelLayoutLoad2:			; XREF: LevelLayoutLoad
		move.w	stageno,d0
		lsl.b	#6,d0
		lsr.w	#5,d0
		move.w	d0,d2
		add.w	d0,d0
		add.w	d2,d0
		add.w	d1,d0
		lea	(zonemaptbl).l,a1
		move.w	(a1,d0.w),d0
		lea	(a1,d0.w),a1
		moveq	#0,d1
		move.w	d1,d2
		move.b	(a1)+,d1	; load level width (in tiles)
		move.b	(a1)+,d2	; load level height (in	tiles)

LevLoad_NumRows:
		move.w	d1,d0
		movea.l	a3,a0

LevLoad_Row:
		move.b	(a1)+,(a0)+
		dbra	d0,LevLoad_Row	; load 1 row
		lea	$80(a3),a3	; do next row
		dbra	d2,LevLoad_NumRows ; repeat for	number of rows
		rts	
; End of function LevelLayoutLoad2

; ---------------------------------------------------------------------------
; Dynamic screen resize	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


scrchk:			; XREF: scroll
		moveq	#0,d0
		move.b	stageno,d0
		add.w	d0,d0
		move.w	Resize_Index(pc,d0.w),d0
		jsr	Resize_Index(pc,d0.w)
		moveq	#2,d1
		move.w	scralim_n_down,d0
		sub.w	scralim_down,d0
		beq.b	locret_6DAA
		bcc.b	loc_6DAC
		neg.w	d1
		move.w	scra_v_posit,d0
		cmp.w	scralim_n_down,d0
		bls.b	loc_6DA0
		move.w	d0,scralim_down
		andi.w	#-2,scralim_down

loc_6DA0:
		add.w	d1,scralim_down
		move.b	#1,($FFFFF75C).w

locret_6DAA:
		rts	
; ===========================================================================

loc_6DAC:				; XREF: scrchk
		move.w	scra_v_posit,d0
		addq.w	#8,d0
		cmp.w	scralim_down,d0
		bcs.b	loc_6DC4
		btst	#1,playerwk+cddat
		beq.b	loc_6DC4
		add.w	d1,d1
		add.w	d1,d1

loc_6DC4:
		add.w	d1,scralim_down
		move.b	#1,($FFFFF75C).w
		rts	
; End of function scrchk

; ===========================================================================
; ---------------------------------------------------------------------------
; Offset index for dynamic screen resizing
; ---------------------------------------------------------------------------
Resize_Index:	dc.w Resize_GHZ-Resize_Index, Resize_LZ-Resize_Index
		dc.w Resize_MZ-Resize_Index, Resize_SLZ-Resize_Index
		dc.w Resize_SYZ-Resize_Index, Resize_SBZ-Resize_Index
		dc.w Resize_Ending-Resize_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Green	Hill Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_GHZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_GHZx(pc,d0.w),d0
		jmp	Resize_GHZx(pc,d0.w)
; ===========================================================================
Resize_GHZx:	dc.w Resize_GHZ1-Resize_GHZx
		dc.w Resize_GHZ2-Resize_GHZx
		dc.w Resize_GHZ3-Resize_GHZx
; ===========================================================================

Resize_GHZ1:
		move.w	#$300,scralim_n_down ; set lower	y-boundary
		cmpi.w	#$1780,scra_h_posit ; has the camera reached $1780 on x-axis?
		bcs.b	locret_6E08	; if not, branch
		move.w	#$400,scralim_n_down ; set lower	y-boundary

locret_6E08:
		rts	
; ===========================================================================

Resize_GHZ2:
		move.w	#$300,scralim_n_down
		cmpi.w	#$ED0,scra_h_posit
		bcs.b	locret_6E3A
		move.w	#$200,scralim_n_down
		cmpi.w	#$1600,scra_h_posit
		bcs.b	locret_6E3A
		move.w	#$400,scralim_n_down
		cmpi.w	#$1D60,scra_h_posit
		bcs.b	locret_6E3A
		move.w	#$300,scralim_n_down

locret_6E3A:
		rts	
; ===========================================================================

Resize_GHZ3:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_6E4A(pc,d0.w),d0
		jmp	off_6E4A(pc,d0.w)
; ===========================================================================
off_6E4A:	dc.w Resize_GHZ3main-off_6E4A
		dc.w Resize_GHZ3boss-off_6E4A
		dc.w Resize_GHZ3end-off_6E4A
; ===========================================================================

Resize_GHZ3main:
		move.w	#$300,scralim_n_down
		cmpi.w	#$380,scra_h_posit
		bcs.b	locret_6E96
		move.w	#$310,scralim_n_down
		cmpi.w	#$960,scra_h_posit
		bcs.b	locret_6E96
		cmpi.w	#$280,scra_v_posit
		bcs.b	loc_6E98
		move.w	#$400,scralim_n_down
		cmpi.w	#$1380,scra_h_posit
		bcc.b	loc_6E8E
		move.w	#$4C0,scralim_n_down
		move.w	#$4C0,scralim_down

loc_6E8E:
		cmpi.w	#$1700,scra_h_posit
		bcc.b	loc_6E98

locret_6E96:
		rts	
; ===========================================================================

loc_6E98:
		move.w	#$300,scralim_n_down
		addq.b	#2,($FFFFF742).w
		rts	
; ===========================================================================

Resize_GHZ3boss:
		cmpi.w	#$960,scra_h_posit
		bcc.b	loc_6EB0
		subq.b	#2,($FFFFF742).w

loc_6EB0:
		cmpi.w	#$2960,scra_h_posit
		bcs.b	locret_6EE8
		bsr.w	actwkchk
		bne.b	loc_6ED0
		move.b	#$3D,0(a1)	; load GHZ boss	object
		move.w	#$2A60,8(a1)
		move.w	#$280,$C(a1)

loc_6ED0:
		move.w	#$8C,d0
		bsr.w	bgmset	; play boss music
		move.b	#1,($FFFFF7AA).w ; lock	screen
		addq.b	#2,($FFFFF742).w
		moveq	#$11,d0
		bra.w	LoadPLC		; load boss patterns
; ===========================================================================

locret_6EE8:
		rts	
; ===========================================================================

Resize_GHZ3end:
		move.w	scra_h_posit,scralim_left
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Labyrinth Zone dynamic screen	resizing
; ---------------------------------------------------------------------------

Resize_LZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_LZx(pc,d0.w),d0
		jmp	Resize_LZx(pc,d0.w)
; ===========================================================================
Resize_LZx:	dc.w Resize_LZ12-Resize_LZx
		dc.w Resize_LZ12-Resize_LZx
		dc.w Resize_LZ3-Resize_LZx
		dc.w Resize_SBZ3-Resize_LZx
; ===========================================================================

Resize_LZ12:
		rts	
; ===========================================================================

Resize_LZ3:
		tst.b	($FFFFF7EF).w	; has switch $F	been pressed?
		beq.b	loc_6F28	; if not, branch
		lea	($FFFFA506).w,a1
		cmpi.b	#7,(a1)
		beq.b	loc_6F28
		move.b	#7,(a1)		; modify level layout
		move.w	#$B7,d0
		bsr.w	soundset ; play rumbling sound

loc_6F28:
		tst.b	($FFFFF742).w
		bne.b	locret_6F64
		cmpi.w	#$1CA0,scra_h_posit
		bcs.b	locret_6F62
		cmpi.w	#$600,scra_v_posit
		bcc.b	locret_6F62
		bsr.w	actwkchk
		bne.b	loc_6F4A
		move.b	#$77,0(a1)	; load LZ boss object

loc_6F4A:
		move.w	#$8C,d0
		bsr.w	bgmset	; play boss music
		move.b	#1,($FFFFF7AA).w ; lock	screen
		addq.b	#2,($FFFFF742).w
		moveq	#$11,d0
		bra.w	LoadPLC		; load boss patterns
; ===========================================================================

locret_6F62:
		rts	
; ===========================================================================

locret_6F64:
		rts	
; ===========================================================================

Resize_SBZ3:
		cmpi.w	#$D00,scra_h_posit
		bcs.b	locret_6F8C
		cmpi.w	#$18,playerwk+yposi ; has Sonic reached the top of the level?
		bcc.b	locret_6F8C	; if not, branch
		clr.b	saveno
		move.w	#1,gameflag ; restart level
		move.w	#$502,stageno ; set level	number to 0502 (FZ)
		move.b	#1,($FFFFF7C8).w ; freeze Sonic

locret_6F8C:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Marble Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_MZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_MZx(pc,d0.w),d0
		jmp	Resize_MZx(pc,d0.w)
; ===========================================================================
Resize_MZx:	dc.w Resize_MZ1-Resize_MZx
		dc.w Resize_MZ2-Resize_MZx
		dc.w Resize_MZ3-Resize_MZx
; ===========================================================================

Resize_MZ1:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_6FB2(pc,d0.w),d0
		jmp	off_6FB2(pc,d0.w)
; ===========================================================================
off_6FB2:	dc.w loc_6FBA-off_6FB2
		dc.w loc_6FEA-off_6FB2
		dc.w loc_702E-off_6FB2
		dc.w loc_7050-off_6FB2
; ===========================================================================

loc_6FBA:
		move.w	#$1D0,scralim_n_down
		cmpi.w	#$700,scra_h_posit
		bcs.b	locret_6FE8
		move.w	#$220,scralim_n_down
		cmpi.w	#$D00,scra_h_posit
		bcs.b	locret_6FE8
		move.w	#$340,scralim_n_down
		cmpi.w	#$340,scra_v_posit
		bcs.b	locret_6FE8
		addq.b	#2,($FFFFF742).w

locret_6FE8:
		rts	
; ===========================================================================

loc_6FEA:
		cmpi.w	#$340,scra_v_posit
		bcc.b	loc_6FF8
		subq.b	#2,($FFFFF742).w
		rts	
; ===========================================================================

loc_6FF8:
		move.w	#0,scralim_up
		cmpi.w	#$E00,scra_h_posit
		bcc.b	locret_702C
		move.w	#$340,scralim_up
		move.w	#$340,scralim_n_down
		cmpi.w	#$A90,scra_h_posit
		bcc.b	locret_702C
		move.w	#$500,scralim_n_down
		cmpi.w	#$370,scra_v_posit
		bcs.b	locret_702C
		addq.b	#2,($FFFFF742).w

locret_702C:
		rts	
; ===========================================================================

loc_702E:
		cmpi.w	#$370,scra_v_posit
		bcc.b	loc_703C
		subq.b	#2,($FFFFF742).w
		rts	
; ===========================================================================

loc_703C:
		cmpi.w	#$500,scra_v_posit
		bcs.b	locret_704E
		move.w	#$500,scralim_up
		addq.b	#2,($FFFFF742).w

locret_704E:
		rts	
; ===========================================================================

loc_7050:
		cmpi.w	#$E70,scra_h_posit
		bcs.b	locret_7072
		move.w	#0,scralim_up
		move.w	#$500,scralim_n_down
		cmpi.w	#$1430,scra_h_posit
		bcs.b	locret_7072
		move.w	#$210,scralim_n_down

locret_7072:
		rts	
; ===========================================================================

Resize_MZ2:
		move.w	#$520,scralim_n_down
		cmpi.w	#$1700,scra_h_posit
		bcs.b	locret_7088
		move.w	#$200,scralim_n_down

locret_7088:
		rts	
; ===========================================================================

Resize_MZ3:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_7098(pc,d0.w),d0
		jmp	off_7098(pc,d0.w)
; ===========================================================================
off_7098:	dc.w Resize_MZ3boss-off_7098
		dc.w Resize_MZ3end-off_7098
; ===========================================================================

Resize_MZ3boss:
		move.w	#$720,scralim_n_down
		cmpi.w	#$1560,scra_h_posit
		bcs.b	locret_70E8
		move.w	#$210,scralim_n_down
		cmpi.w	#$17F0,scra_h_posit
		bcs.b	locret_70E8
		bsr.w	actwkchk
		bne.b	loc_70D0
		move.b	#$73,0(a1)	; load MZ boss object
		move.w	#$19F0,8(a1)
		move.w	#$22C,$C(a1)

loc_70D0:
		move.w	#$8C,d0
		bsr.w	bgmset	; play boss music
		move.b	#1,($FFFFF7AA).w ; lock	screen
		addq.b	#2,($FFFFF742).w
		moveq	#$11,d0
		bra.w	LoadPLC		; load boss patterns
; ===========================================================================

locret_70E8:
		rts	
; ===========================================================================

Resize_MZ3end:
		move.w	scra_h_posit,scralim_left
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Star Light Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_SLZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_SLZx(pc,d0.w),d0
		jmp	Resize_SLZx(pc,d0.w)
; ===========================================================================
Resize_SLZx:	dc.w Resize_SLZ12-Resize_SLZx
		dc.w Resize_SLZ12-Resize_SLZx
		dc.w Resize_SLZ3-Resize_SLZx
; ===========================================================================

Resize_SLZ12:
		rts	
; ===========================================================================

Resize_SLZ3:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_7118(pc,d0.w),d0
		jmp	off_7118(pc,d0.w)
; ===========================================================================
off_7118:	dc.w Resize_SLZ3main-off_7118
		dc.w Resize_SLZ3boss-off_7118
		dc.w Resize_SLZ3end-off_7118
; ===========================================================================

Resize_SLZ3main:
		cmpi.w	#$1E70,scra_h_posit
		bcs.b	locret_7130
		move.w	#$210,scralim_n_down
		addq.b	#2,($FFFFF742).w

locret_7130:
		rts	
; ===========================================================================

Resize_SLZ3boss:
		cmpi.w	#$2000,scra_h_posit
		bcs.b	locret_715C
		bsr.w	actwkchk
		bne.b	loc_7144
		move.b	#$7A,(a1)	; load SLZ boss	object

loc_7144:
		move.w	#$8C,d0
		bsr.w	bgmset	; play boss music
		move.b	#1,($FFFFF7AA).w ; lock	screen
		addq.b	#2,($FFFFF742).w
		moveq	#$11,d0
		bra.w	LoadPLC		; load boss patterns
; ===========================================================================

locret_715C:
		rts	
; ===========================================================================

Resize_SLZ3end:
		move.w	scra_h_posit,scralim_left
		rts
		rts
; ===========================================================================
; ---------------------------------------------------------------------------
; Spring Yard Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_SYZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_SYZx(pc,d0.w),d0
		jmp	Resize_SYZx(pc,d0.w)
; ===========================================================================
Resize_SYZx:	dc.w Resize_SYZ1-Resize_SYZx
		dc.w Resize_SYZ2-Resize_SYZx
		dc.w Resize_SYZ3-Resize_SYZx
; ===========================================================================

Resize_SYZ1:
		rts	
; ===========================================================================

Resize_SYZ2:
		move.w	#$520,scralim_n_down
		cmpi.w	#$25A0,scra_h_posit
		bcs.b	locret_71A2
		move.w	#$420,scralim_n_down
		cmpi.w	#$4D0,playerwk+yposi
		bcs.b	locret_71A2
		move.w	#$520,scralim_n_down

locret_71A2:
		rts	
; ===========================================================================

Resize_SYZ3:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_71B2(pc,d0.w),d0
		jmp	off_71B2(pc,d0.w)
; ===========================================================================
off_71B2:	dc.w Resize_SYZ3main-off_71B2
		dc.w Resize_SYZ3boss-off_71B2
		dc.w Resize_SYZ3end-off_71B2
; ===========================================================================

Resize_SYZ3main:
		cmpi.w	#$2AC0,scra_h_posit
		bcs.b	locret_71CE
		bsr.w	actwkchk
		bne.b	locret_71CE
		move.b	#$76,(a1)	; load blocks that boss	picks up
		addq.b	#2,($FFFFF742).w

locret_71CE:
		rts	
; ===========================================================================

Resize_SYZ3boss:
		cmpi.w	#$2C00,scra_h_posit
		bcs.b	locret_7200
		move.w	#$4CC,scralim_n_down
		bsr.w	actwkchk
		bne.b	loc_71EC
		move.b	#$75,(a1)	; load SYZ boss	object
		addq.b	#2,($FFFFF742).w

loc_71EC:
		move.w	#$8C,d0
		bsr.w	bgmset	; play boss music
		move.b	#1,($FFFFF7AA).w ; lock	screen
		moveq	#$11,d0
		bra.w	LoadPLC		; load boss patterns
; ===========================================================================

locret_7200:
		rts	
; ===========================================================================

Resize_SYZ3end:
		move.w	scra_h_posit,scralim_left
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Scrap	Brain Zone dynamic screen resizing
; ---------------------------------------------------------------------------

Resize_SBZ:				; XREF: Resize_Index
		moveq	#0,d0
		move.b	stageno+1,d0
		add.w	d0,d0
		move.w	Resize_SBZx(pc,d0.w),d0
		jmp	Resize_SBZx(pc,d0.w)
; ===========================================================================
Resize_SBZx:	dc.w Resize_SBZ1-Resize_SBZx
		dc.w Resize_SBZ2-Resize_SBZx
		dc.w Resize_FZ-Resize_SBZx
; ===========================================================================

Resize_SBZ1:
		move.w	#$720,scralim_n_down
		cmpi.w	#$1880,scra_h_posit
		bcs.b	locret_7242
		move.w	#$620,scralim_n_down
		cmpi.w	#$2000,scra_h_posit
		bcs.b	locret_7242
		move.w	#$2A0,scralim_n_down

locret_7242:
		rts	
; ===========================================================================

Resize_SBZ2:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_7252(pc,d0.w),d0
		jmp	off_7252(pc,d0.w)
; ===========================================================================
off_7252:	dc.w Resize_SBZ2main-off_7252
		dc.w Resize_SBZ2boss-off_7252
		dc.w Resize_SBZ2boss2-off_7252
		dc.w Resize_SBZ2end-off_7252
; ===========================================================================

Resize_SBZ2main:
		move.w	#$800,scralim_n_down
		cmpi.w	#$1800,scra_h_posit
		bcs.b	locret_727A
		move.w	#$510,scralim_n_down
		cmpi.w	#$1E00,scra_h_posit
		bcs.b	locret_727A
		addq.b	#2,($FFFFF742).w

locret_727A:
		rts	
; ===========================================================================

Resize_SBZ2boss:
		cmpi.w	#$1EB0,scra_h_posit
		bcs.b	locret_7298
		bsr.w	actwkchk
		bne.b	locret_7298
		move.b	#$83,(a1)	; load collapsing block	object
		addq.b	#2,($FFFFF742).w
		moveq	#$1E,d0
		bra.w	LoadPLC		; load SBZ2 Eggman patterns
; ===========================================================================

locret_7298:
		rts	
; ===========================================================================

Resize_SBZ2boss2:
		cmpi.w	#$1F60,scra_h_posit
		bcs.b	loc_72B6
		bsr.w	actwkchk
		bne.b	loc_72B0
		move.b	#$82,(a1)	; load SBZ2 Eggman object
		addq.b	#2,($FFFFF742).w

loc_72B0:
		move.b	#1,($FFFFF7AA).w ; lock	screen

loc_72B6:
		bra.b	loc_72C2
; ===========================================================================

Resize_SBZ2end:
		cmpi.w	#$2050,scra_h_posit
		bcs.b	loc_72C2
		rts	
; ===========================================================================

loc_72C2:
		move.w	scra_h_posit,scralim_left
		rts	
; ===========================================================================

Resize_FZ:
		moveq	#0,d0
		move.b	($FFFFF742).w,d0
		move.w	off_72D8(pc,d0.w),d0
		jmp	off_72D8(pc,d0.w)
; ===========================================================================
off_72D8:	dc.w Resize_FZmain-off_72D8, Resize_FZboss-off_72D8
		dc.w Resize_FZend-off_72D8, locret_7322-off_72D8
		dc.w Resize_FZend2-off_72D8
; ===========================================================================

Resize_FZmain:
		cmpi.w	#$2148,scra_h_posit
		bcs.b	loc_72F4
		addq.b	#2,($FFFFF742).w
		moveq	#$1F,d0
		bsr.w	LoadPLC		; load FZ boss patterns

loc_72F4:
		bra.b	loc_72C2
; ===========================================================================

Resize_FZboss:
		cmpi.w	#$2300,scra_h_posit
		bcs.b	loc_7312
		bsr.w	actwkchk
		bne.b	loc_7312
		move.b	#$85,(a1)	; load FZ boss object
		addq.b	#2,($FFFFF742).w
		move.b	#1,($FFFFF7AA).w ; lock	screen

loc_7312:
		bra.b	loc_72C2
; ===========================================================================

Resize_FZend:
		cmpi.w	#$2450,scra_h_posit
		bcs.b	loc_7320
		addq.b	#2,($FFFFF742).w

loc_7320:
		bra.b	loc_72C2
; ===========================================================================

locret_7322:
		rts	
; ===========================================================================

Resize_FZend2:
		bra.b	loc_72C2
; ===========================================================================
; ---------------------------------------------------------------------------
; Ending sequence dynamic screen resizing (empty)
; ---------------------------------------------------------------------------

Resize_Ending:				; XREF: Resize_Index
		rts	
; ===========================================================================
hashi:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	hashi_move_tbl(pc,d0.w),d1
		jmp		hashi_move_tbl(pc,d1.w)
hashi_move_tbl:
		dc.w	hashi_init-hashi_move_tbl
		dc.w	hash_move-hashi_move_tbl
		dc.w	hash_move2-hashi_move_tbl
		dc.w	hashi_Delete2-hashi_move_tbl
		dc.w	hashi_Delete2-hashi_move_tbl
		dc.w	hashi_Display2-hashi_move_tbl
hashi_init:
		addq.b	#word,r_no0(a0)
		move.l	#hashipat,patbase(a0)
		move.w	#$438e,sproffset(a0)
		move.b	#4,actflg(a0)
		move.b	#3,sprpri(a0)
		move.b	#128,sprhs(a0)
		move.w	yposi(a0),d2
		move.w	xposi(a0),d3
		move.b	actno(a0),d4
		lea		userflag(a0),a2
		moveq	#0,d1
		move.b	(a2),d1
		move.b	#0,(a2)+
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3
		subq.b	#2,d1
		bcs.b	hash_move

hashi_MakeBdg:
		bsr.w	actwkchk
		bne.b	hash_move
		addq.b	#1,userflag(a0)
		cmp.w	8(a0),d3
		bne.b	loc_73B8
		addi.w	#$10,d3
		move.w	d2,$C(a0)
		move.w	d2,$3C(a0)
		move.w	a0,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		addq.b	#1,userflag(a0)

loc_73B8:
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,r_no0(a1)
		move.b	d4,0(a1)
		move.w	d2,$C(a1)
		move.w	d2,$3C(a1)
		move.w	d3,8(a1)
		move.l	#hashipat,4(a1)
		move.w	#$438E,2(a1)
		move.b	#4,actflg(a1)
		move.b	#3,$18(a1)
		move.b	#8,$19(a1)
		addi.w	#$10,d3
		dbra	d1,hashi_MakeBdg ; repeat d1 times (length of bridge)

hash_move:				; XREF: hashi_move_tbl
		bsr.b	hashi_Solid
		tst.b	$3E(a0)
		beq.b	hashi_Display
		subq.b	#4,$3E(a0)
		bsr.w	hashi_Bend

hashi_Display:
		bsr.w	actionsub
		bra.w	hashi_ChkDel

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


hashi_Solid:				; XREF: hash_move
		moveq	#0,d1
		move.b	userflag(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		add.w	d2,d2
		lea	playerwk,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		cmp.w	d2,d0
		bcc.w	locret_751E
		bra.b	Platform2
; End of function hashi_Solid

; ---------------------------------------------------------------------------
; Platform subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


PlatformObject:
		lea	playerwk,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_751E

Platform2:
		move.w	$C(a0),d0
		subq.w	#8,d0

Platform3:
		move.w	$C(a1),d2
		move.b	$16(a1),d1
		ext.w	d1
		add.w	d2,d1
		addq.w	#4,d1
		sub.w	d1,d0
		bhi.w	locret_751E
		cmpi.w	#-$10,d0
		bcs.w	locret_751E
		tst.b	($FFFFF7C8).w
		bmi.w	locret_751E
		cmpi.b	#6,r_no0(a1)
		bcc.w	locret_751E
		add.w	d0,d2
		addq.w	#3,d2
		move.w	d2,$C(a1)
		addq.b	#2,r_no0(a0)

loc_74AE:
		btst	#3,cddat(a1)
		beq.b	loc_74DC
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,cddat(a2)
		clr.b	r_no1(a2)
		cmpi.b	#4,r_no0(a2)
		bne.b	loc_74DC
		subq.b	#2,r_no0(a2)

loc_74DC:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,direc(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),$14(a1)
		btst	#1,cddat(a1)
		beq.b	loc_7512
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	jumpcolsub
		movea.l	(sp)+,a0

loc_7512:
		bset	#3,cddat(a1)
		bset	#3,cddat(a0)

locret_751E:
		rts	
; End of function PlatformObject

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	SLZ seesaws)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject:				; XREF: break_Slope; sisoo_Slope
		lea	playerwk,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.b	locret_751E
		btst	#0,actflg(a0)
		beq.b	loc_754A
		not.w	d0
		add.w	d1,d0

loc_754A:
		lsr.w	#1,d0
		moveq	#0,d3
		move.b	(a2,d0.w),d3
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function SlopeObject


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


buranko_Solid:				; XREF: buranko_SetSolid
		lea	playerwk,a1
		tst.w	$12(a1)
		bmi.w	locret_751E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	locret_751E
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.w	locret_751E
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.w	Platform3
; End of function buranko_Solid

; ===========================================================================

hash_move2:				; XREF: hashi_move_tbl
		bsr.b	hashi_WalkOff
		bsr.w	actionsub
		bra.w	hashi_ChkDel

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk off a bridge
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


hashi_WalkOff:				; XREF: hash_move2
		moveq	#0,d1
		move.b	userflag(a0),d1
		lsl.w	#3,d1
		move.w	d1,d2
		addq.w	#8,d1
		bsr.b	ExitPlatform2
		bcc.b	locret_75BE
		lsr.w	#4,d0
		move.b	d0,$3F(a0)
		move.b	$3E(a0),d0
		cmpi.b	#$40,d0
		beq.b	loc_75B6
		addq.b	#4,$3E(a0)

loc_75B6:
		bsr.w	hashi_Bend
		bsr.w	hashi_MoveSonic

locret_75BE:
		rts	
; End of function hashi_WalkOff

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk or jump off	a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ExitPlatform:
		move.w	d1,d2

ExitPlatform2:
		add.w	d2,d2
		lea	playerwk,a1
		btst	#1,cddat(a1)
		bne.b	loc_75E0
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_75E0
		cmp.w	d2,d0
		bcs.b	locret_75F2

loc_75E0:
		bclr	#3,cddat(a1)
		move.b	#2,r_no0(a0)
		bclr	#3,cddat(a0)

locret_75F2:
		rts	
; End of function ExitPlatform


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


hashi_MoveSonic:			; XREF: hashi_WalkOff
		moveq	#0,d0
		move.b	$3F(a0),d0
		move.b	$29(a0,d0.w),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		lea	playerwk,a1
		move.w	$C(a2),d0
		subq.w	#8,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)	; change Sonic's position on y-axis
		rts	
; End of function hashi_MoveSonic


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


hashi_Bend:				; XREF: hash_move; hashi_WalkOff
		move.b	$3E(a0),d0
		bsr.w	sinset
		move.w	d0,d4
		lea	(hashi_BendData2).l,a4
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsl.w	#4,d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		move.w	d3,d2
		add.w	d0,d3
		moveq	#0,d5
		lea	(hashi_BendData).l,a5
		move.b	(a5,d3.w),d5
		andi.w	#$F,d3
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		lea	$29(a0),a2

loc_765C:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	(a3)+,d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,$C(a1)
		dbra	d2,loc_765C
		moveq	#0,d0
		move.b	userflag(a0),d0
		moveq	#0,d3
		move.b	$3F(a0),d3
		addq.b	#1,d3
		sub.b	d0,d3
		neg.b	d3
		bmi.b	locret_76CA
		move.w	d3,d2
		lsl.w	#4,d3
		lea	(a4,d3.w),a3
		adda.w	d2,a3
		subq.w	#1,d2
		bcs.b	locret_76CA

loc_76A4:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		moveq	#0,d0
		move.b	-(a3),d0
		addq.w	#1,d0
		mulu.w	d5,d0
		mulu.w	d4,d0
		swap	d0
		add.w	$3C(a1),d0
		move.w	d0,$C(a1)
		dbra	d2,loc_76A4

locret_76CA:
		rts	
; End of function hashi_Bend

; ===========================================================================
; ---------------------------------------------------------------------------
; GHZ bridge-bending data
; (Defines how the bridge bends	when Sonic walks across	it)
; ---------------------------------------------------------------------------
hashi_BendData:	incbin	misc\ghzbend1.bin
		even
hashi_BendData2:incbin	misc\ghzbend2.bin
		even

; ===========================================================================

hashi_ChkDel:				; XREF: hashi_Display; hash_move2
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	hashi_DelAll
		rts	
; ===========================================================================

hashi_DelAll:				; XREF: hashi_ChkDel
		moveq	#0,d2
		lea	userflag(a0),a2	; load bridge length
		move.b	(a2)+,d2	; move bridge length to	d2
		subq.b	#1,d2		; subtract 1
		bcs.b	hashi_Delete

hashi_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		cmp.w	a0,d0
		beq.b	loc_791E
		bsr.w	frameout2

loc_791E:
		dbra	d2,hashi_DelLoop ; repeat d2 times (bridge length)

hashi_Delete:
		bsr.w	frameout
		rts	
; ===========================================================================

hashi_Delete2:				; XREF: hashi_move_tbl
		bsr.w	frameout
		rts	
; ===========================================================================

hashi_Display2:				; XREF: hashi_move_tbl
		bsr.w	actionsub
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	bridge
; ---------------------------------------------------------------------------
hashipat:
	include "_maps\hashi.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 15 - swinging platforms (GHZ, MZ, SLZ)
;	    - spiked ball on a chain (SBZ)
; ---------------------------------------------------------------------------

buranko:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	buranko_Index(pc,d0.w),d1
		jmp	buranko_Index(pc,d1.w)
; ===========================================================================
buranko_Index:	dc.w buranko_Main-buranko_Index, buranko_SetSolid-buranko_Index
		dc.w buranko_Action2-buranko_Index,	buranko_Delete-buranko_Index
		dc.w buranko_Delete-buranko_Index, buranko_Display-buranko_Index
		dc.w buranko_Action-buranko_Index
; ===========================================================================

buranko_Main:				; XREF: buranko_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_buranko,4(a0) ; GHZ and MZ specific code
		move.w	#$4380,2(a0)
		move.b	#4,actflg(a0)
		move.b	#3,$18(a0)
		move.b	#$18,$19(a0)
		move.b	#8,$16(a0)
		move.w	$C(a0),$38(a0)
		move.w	8(a0),$3A(a0)
		cmpi.b	#3,stageno ; check if level is SLZ
		bne.b	buranko_NotSLZ
		move.l	#Map_burankoa,4(a0) ; SLZ	specific code
		move.w	#$43DC,2(a0)
		move.b	#$20,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#$99,colino(a0)

buranko_NotSLZ:
		cmpi.b	#5,stageno ; check if level is SBZ
		bne.b	buranko_SetLength
		move.l	#Map_burankob,4(a0) ; SBZ	specific code
		move.w	#$391,2(a0)
		move.b	#$18,$19(a0)
		move.b	#$18,$16(a0)
		move.b	#$86,colino(a0)
		move.b	#$C,r_no0(a0)

buranko_SetLength:
		move.b	0(a0),d4
		moveq	#0,d1
		lea	userflag(a0),a2	; move chain length to a2
		move.b	(a2),d1		; move a2 to d1
		move.w	d1,-(sp)
		andi.w	#$F,d1
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		addq.b	#8,d3
		move.b	d3,$3C(a0)
		subq.b	#8,d3
		tst.b	$1A(a0)
		beq.b	buranko_MakeChain
		addq.b	#8,d3
		subq.w	#1,d1

buranko_MakeChain:
		bsr.w	actwkchk
		bne.b	loc_7A92
		addq.b	#1,userflag(a0)
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#$A,r_no0(a1)
		move.b	d4,0(a1)	; load swinging	object
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		bclr	#6,2(a1)
		move.b	#4,actflg(a1)
		move.b	#4,$18(a1)
		move.b	#8,$19(a1)
		move.b	#1,$1A(a1)
		move.b	d3,$3C(a1)
		subi.b	#$10,d3
		bcc.b	loc_7A8E
		move.b	#2,$1A(a1)
		move.b	#3,$18(a1)
		bset	#6,2(a1)

loc_7A8E:
		dbra	d1,buranko_MakeChain ; repeat d1 times (chain length)

loc_7A92:
		move.w	a0,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.w	#$4080,direc(a0)
		move.w	#-$200,$3E(a0)
		move.w	(sp)+,d1
		btst	#4,d1		; is object type $8X ?
		beq.b	loc_7AD4	; if not, branch
		move.l	#Map_btama,4(a0) ; use GHZ ball	mappings
		move.w	#$43AA,2(a0)
		move.b	#1,$1A(a0)
		move.b	#2,$18(a0)
		move.b	#$81,colino(a0)	; make object hurt when	touched

loc_7AD4:
		cmpi.b	#5,stageno ; is zone SBZ?
		beq.b	buranko_Action	; if yes, branch

buranko_SetSolid:				; XREF: buranko_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		moveq	#0,d3
		move.b	$16(a0),d3
		bsr.w	buranko_Solid

buranko_Action:				; XREF: buranko_Index
		bsr.w	buranko_Move
		bsr.w	actionsub
		bra.w	buranko_ChkDel
; ===========================================================================

buranko_Action2:				; XREF: buranko_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		bsr.w	ExitPlatform
		move.w	8(a0),-(sp)
		bsr.w	buranko_Move
		move.w	(sp)+,d2
		moveq	#0,d3
		move.b	$16(a0),d3
		addq.b	#1,d3
		bsr.w	MvSonicOnPtfm
		bsr.w	actionsub
		bra.w	buranko_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm:
		lea	playerwk,a1
		move.w	$C(a0),d0
		sub.w	d3,d0
		bra.b	MvSonic2
; End of function MvSonicOnPtfm

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's position with a platform
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


MvSonicOnPtfm2:
		lea	playerwk,a1
		move.w	$C(a0),d0
		subi.w	#9,d0

MvSonic2:
		tst.b	($FFFFF7C8).w
		bmi.b	locret_7B62
		cmpi.b	#6,($FFFFD024).w
		bcc.b	locret_7B62
		tst.w	editmode
		bne.b	locret_7B62
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_7B62:
		rts	
; End of function MvSonicOnPtfm2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


buranko_Move:				; XREF: buranko_Action; buranko_Action2
		move.b	($FFFFFE78).w,d0
		move.w	#$80,d1
		btst	#0,cddat(a0)
		beq.b	loc_7B78
		neg.w	d0
		add.w	d1,d0

loc_7B78:
		bra.b	buranko_Move2
; End of function buranko_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


btama_Move:				; XREF: btama_Display2
		tst.b	$3D(a0)
		bne.b	loc_7B9C
		move.w	$3E(a0),d0
		addq.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,direc(a0)
		cmpi.w	#$200,d0
		bne.b	loc_7BB6
		move.b	#1,$3D(a0)
		bra.b	loc_7BB6
; ===========================================================================

loc_7B9C:
		move.w	$3E(a0),d0
		subq.w	#8,d0
		move.w	d0,$3E(a0)
		add.w	d0,direc(a0)
		cmpi.w	#-$200,d0
		bne.b	loc_7BB6
		move.b	#0,$3D(a0)

loc_7BB6:
		move.b	direc(a0),d0
; End of function btama_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


buranko_Move2:				; XREF: buranko_Move; btama_Display
		bsr.w	sinset
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		lea	userflag(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_7BCE:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#$FFD000,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	$3C(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a1)
		move.w	d5,8(a1)
		dbra	d6,loc_7BCE
		rts	
; End of function buranko_Move2

; ===========================================================================

buranko_ChkDel:				; XREF: buranko_Action; buranko_Action2
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	buranko_DelAll
		rts	
; ===========================================================================

buranko_DelAll:				; XREF: buranko_ChkDel
		moveq	#0,d2
		lea	userflag(a0),a2
		move.b	(a2)+,d2

buranko_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		bsr.w	frameout2
		dbra	d2,buranko_DelLoop ; repeat for length of	chain
		rts	
; ===========================================================================

buranko_Delete:				; XREF: buranko_Index
		bsr.w	frameout
		rts	
; ===========================================================================

buranko_Display:				; XREF: buranko_Index
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	and MZ swinging	platforms
; ---------------------------------------------------------------------------
Map_buranko:
	include "_maps\burankoghz.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - SLZ	swinging platforms
; ---------------------------------------------------------------------------
Map_burankoa:
	include "_maps\burankoslz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 17 - helix of spikes on a pole	(GHZ)
; ---------------------------------------------------------------------------

thashi:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	thashi_move_tbl(pc,d0.w),d1
		jmp	thashi_move_tbl(pc,d1.w)
; ===========================================================================
thashi_move_tbl:	dc.w thashi_init-thashi_move_tbl
		dc.w thash_move-thashi_move_tbl
		dc.w thash_move-thashi_move_tbl
		dc.w thashi_Delete-thashi_move_tbl
		dc.w thashi_Display-thashi_move_tbl
; ===========================================================================

thashi_init:				; XREF: thashi_move_tbl
		addq.b	#2,r_no0(a0)
		move.l	#Map_thashi,4(a0)
		move.w	#$4398,2(a0)
		move.b	#7,cddat(a0)
		move.b	#4,actflg(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		move.b	0(a0),d4
		lea	userflag(a0),a2	; move helix length to a2
		moveq	#0,d1
		move.b	(a2),d1		; move a2 to d1
		move.b	#0,(a2)+
		move.w	d1,d0
		lsr.w	#1,d0
		lsl.w	#4,d0
		sub.w	d0,d3
		subq.b	#2,d1
		bcs.b	thash_move
		moveq	#0,d6

thashi_MakeHelix:
		bsr.w	actwkchk
		bne.b	thash_move
		addq.b	#1,userflag(a0)
		move.w	a1,d5
		subi.w	#$D000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#8,r_no0(a1)
		move.b	d4,0(a1)
		move.w	d2,$C(a1)
		move.w	d3,8(a1)
		move.l	4(a0),4(a1)
		move.w	#$4398,2(a1)
		move.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#8,$19(a1)
		move.b	d6,$3E(a1)
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3
		cmp.w	8(a0),d3
		bne.b	loc_7D78
		move.b	d6,$3E(a0)
		addq.b	#1,d6
		andi.b	#7,d6
		addi.w	#$10,d3
		addq.b	#1,userflag(a0)

loc_7D78:
		dbra	d1,thashi_MakeHelix ; repeat d1 times (helix length)

thash_move:				; XREF: thashi_move_tbl
		bsr.w	thashi_RotateSpikes
		bsr.w	actionsub
		bra.w	thashi_ChkDel

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


thashi_RotateSpikes:			; XREF: thash_move; thashi_Display
		move.b	sys_patno,d0
		move.b	#0,colino(a0)	; make object harmless
		add.b	$3E(a0),d0
		andi.b	#7,d0
		move.b	d0,$1A(a0)	; change current frame
		bne.b	locret_7DA6
		move.b	#$84,colino(a0)	; make object harmful

locret_7DA6:
		rts	
; End of function thashi_RotateSpikes

; ===========================================================================

thashi_ChkDel:				; XREF: thash_move
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	thashi_DelAll
		rts	
; ===========================================================================

thashi_DelAll:				; XREF: thashi_ChkDel
		moveq	#0,d2
		lea	userflag(a0),a2	; move helix length to a2
		move.b	(a2)+,d2	; move a2 to d2
		subq.b	#2,d2
		bcs.b	thashi_Delete

thashi_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		bsr.w	frameout2	; delete object
		dbra	d2,thashi_DelLoop ; repeat d2 times (helix length)

thashi_Delete:				; XREF: thashi_move_tbl
		bsr.w	frameout
		rts	
; ===========================================================================

thashi_Display:				; XREF: thashi_move_tbl
		bsr.w	thashi_RotateSpikes
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - helix of spikes on a pole (GHZ)
; ---------------------------------------------------------------------------
Map_thashi:
	include "_maps\thashi.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 18 - platforms	(GHZ, SYZ, SLZ)
; ---------------------------------------------------------------------------

shima:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	shima_Index(pc,d0.w),d1
		jmp	shima_Index(pc,d1.w)
; ===========================================================================
shima_Index:	dc.w shima_Main-shima_Index
		dc.w shima_Solid-shima_Index
		dc.w shima_Action2-shima_Index
		dc.w shima_Delete-shima_Index
		dc.w shima_Action-shima_Index
; ===========================================================================

shima_Main:				; XREF: shima_Index
		addq.b	#2,r_no0(a0)
		move.w	#$4000,2(a0)
		move.l	#shimapat2,4(a0)
		move.b	#$20,$19(a0)
		cmpi.b	#4,stageno ; check if level is SYZ
		bne.b	shima_NotSYZ
		move.l	#shimapat3,4(a0) ; SYZ	specific code
		move.b	#$20,$19(a0)

shima_NotSYZ:
		cmpi.b	#3,stageno ; check if level is SLZ
		bne.b	shima_NotSLZ
		move.l	#shimapat4,4(a0) ; SLZ	specific code
		move.b	#$20,$19(a0)
		move.w	#$4000,2(a0)
		move.b	#3,userflag(a0)

shima_NotSLZ:
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.w	$C(a0),actfree(a0)
		move.w	$C(a0),$34(a0)
		move.w	8(a0),$32(a0)
		move.w	#$80,direc(a0)
		moveq	#0,d1
		move.b	userflag(a0),d0
		cmpi.b	#$A,d0		; is object type $A (large platform)?
		bne.b	shima_SetFrame	; if not, branch
		addq.b	#1,d1		; use frame #1
		move.b	#$20,$19(a0)	; set width

shima_SetFrame:
		move.b	d1,$1A(a0)	; set frame to d1

shima_Solid:				; XREF: shima_Index
		tst.b	$38(a0)
		beq.b	loc_7EE0
		subq.b	#4,$38(a0)

loc_7EE0:
		moveq	#0,d1
		move.b	$19(a0),d1
		bsr.w	PlatformObject

shima_Action:				; XREF: shima_Index
		bsr.w	shima_Move
		bsr.w	shima_Nudge
		bsr.w	actionsub
		bra.w	shima_ChkDel
; ===========================================================================

shima_Action2:				; XREF: shima_Index
		cmpi.b	#$40,$38(a0)
		beq.b	loc_7F06
		addq.b	#4,$38(a0)

loc_7F06:
		moveq	#0,d1
		move.b	$19(a0),d1
		bsr.w	ExitPlatform
		move.w	8(a0),-(sp)
		bsr.w	shima_Move
		bsr.w	shima_Nudge
		move.w	(sp)+,d2
		bsr.w	MvSonicOnPtfm2
		bsr.w	actionsub
		bra.w	shima_ChkDel

		rts

; ---------------------------------------------------------------------------
; Subroutine to	move platform slightly when you	stand on it
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


shima_Nudge:				; XREF: shima_Action; shima_Action2
		move.b	$38(a0),d0
		bsr.w	sinset
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	actfree(a0),d0
		move.w	d0,$C(a0)
		rts	
; End of function shima_Nudge

; ---------------------------------------------------------------------------
; Subroutine to	move platforms
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


shima_Move:				; XREF: shima_Action; shima_Action2
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	shima_TypeIndex(pc,d0.w),d1
		jmp	shima_TypeIndex(pc,d1.w)
; End of function shima_Move

; ===========================================================================
shima_TypeIndex:dc.w shima_Type00-shima_TypeIndex, shima_Type01-shima_TypeIndex
		dc.w shima_Type02-shima_TypeIndex, shima_Type03-shima_TypeIndex
		dc.w shima_Type04-shima_TypeIndex, shima_Type05-shima_TypeIndex
		dc.w shima_Type06-shima_TypeIndex, shima_Type07-shima_TypeIndex
		dc.w shima_Type08-shima_TypeIndex, shima_Type00-shima_TypeIndex
		dc.w shima_Type0A-shima_TypeIndex, shima_Type0B-shima_TypeIndex
		dc.w shima_Type0C-shima_TypeIndex
; ===========================================================================

shima_Type00:
		rts			; platform 00 doesn't move
; ===========================================================================

shima_Type05:
		move.w	$32(a0),d0
		move.b	direc(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.b	shima_01_Move
; ===========================================================================

shima_Type01:
		move.w	$32(a0),d0
		move.b	direc(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

shima_01_Move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,8(a0)	; change position on x-axis
		bra.w	shima_ChgMotion
; ===========================================================================

shima_Type0C:
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1 ; load	platform-motion	variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$30,d1
		bra.b	shima_02_Move
; ===========================================================================

shima_Type0B:
		move.w	$34(a0),d0
		move.b	($FFFFFE6C).w,d1 ; load	platform-motion	variable
		subi.b	#$30,d1
		bra.b	shima_02_Move
; ===========================================================================

shima_Type06:
		move.w	$34(a0),d0
		move.b	direc(a0),d1	; load platform-motion variable
		neg.b	d1		; reverse platform-motion
		addi.b	#$40,d1
		bra.b	shima_02_Move
; ===========================================================================

shima_Type02:
		move.w	$34(a0),d0
		move.b	direc(a0),d1	; load platform-motion variable
		subi.b	#$40,d1

shima_02_Move:
		ext.w	d1
		add.w	d1,d0
		move.w	d0,actfree(a0)	; change position on y-axis
		bra.w	shima_ChgMotion
; ===========================================================================

shima_Type03:
		tst.w	$3A(a0)		; is time delay	set?
		bne.b	shima_03_Wait	; if yes, branch
		btst	#3,cddat(a0)	; is Sonic standing on the platform?
		beq.b	shima_03_NoMove	; if not, branch
		move.w	#30,$3A(a0)	; set time delay to 0.5	seconds

shima_03_NoMove:
		rts	
; ===========================================================================

shima_03_Wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time
		bne.b	shima_03_NoMove	; if time is > 0, branch
		move.w	#32,$3A(a0)
		addq.b	#1,userflag(a0)	; change to type 04 (falling)
		rts	
; ===========================================================================

shima_Type04:
		tst.w	$3A(a0)
		beq.b	loc_8048
		subq.w	#1,$3A(a0)
		bne.b	loc_8048
		btst	#3,cddat(a0)
		beq.b	loc_8042
		bset	#1,cddat(a1)
		bclr	#3,cddat(a1)
		move.b	#2,r_no0(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		move.w	$12(a0),$12(a1)

loc_8042:
		move.b	#8,r_no0(a0)

loc_8048:
		move.l	actfree(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d3,actfree(a0)
		addi.w	#$38,$12(a0)
		move.w	scralim_down,d0
		addi.w	#$E0,d0
		cmp.w	actfree(a0),d0
		bcc.b	locret_8074
		move.b	#6,r_no0(a0)

locret_8074:
		rts	
; ===========================================================================

shima_Type07:
		tst.w	$3A(a0)		; is time delay	set?
		bne.b	shima_07_Wait	; if yes, branch
		lea	($FFFFF7E0).w,a2 ; load	switch statuses
		moveq	#0,d0
		move.b	userflag(a0),d0	; move object type ($x7) to d0
		lsr.w	#4,d0		; divide d0 by 8, round	down
		tst.b	(a2,d0.w)	; has switch no. d0 been pressed?
		beq.b	shima_07_NoMove	; if not, branch
		move.w	#60,$3A(a0)	; set time delay to 1 second

shima_07_NoMove:
		rts	
; ===========================================================================

shima_07_Wait:
		subq.w	#1,$3A(a0)	; subtract 1 from time delay
		bne.b	shima_07_NoMove	; if time is > 0, branch
		addq.b	#1,userflag(a0)	; change to type 08
		rts	
; ===========================================================================

shima_Type08:
		subq.w	#2,actfree(a0)	; move platform	up
		move.w	$34(a0),d0
		subi.w	#$200,d0
		cmp.w	actfree(a0),d0	; has platform moved $200 pixels?
		bne.b	shima_08_NoStop	; if not, branch
		clr.b	userflag(a0)		; change to type 00 (stop moving)

shima_08_NoStop:
		rts	
; ===========================================================================

shima_Type0A:
		move.w	$34(a0),d0
		move.b	direc(a0),d1	; load platform-motion variable
		subi.b	#$40,d1
		ext.w	d1
		asr.w	#1,d1
		add.w	d1,d0
		move.w	d0,actfree(a0)	; change position on y-axis

shima_ChgMotion:
		move.b	($FFFFFE78).w,direc(a0) ;	update platform-movement variable
		rts	
; ===========================================================================

shima_ChkDel:				; XREF: shima_Action; shima_Action2
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	shima_Delete
		rts	
; ===========================================================================

shima_Delete:				; XREF: shima_Index
		bra.w	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - unused
; ---------------------------------------------------------------------------
shimapat1:
	include "_maps\shimax.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	platforms
; ---------------------------------------------------------------------------
shimapat2:
	include "_maps\shimaghz.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - SYZ	platforms
; ---------------------------------------------------------------------------
shimapat3:
	include "_maps\shimasyz.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - SLZ	platforms
; ---------------------------------------------------------------------------
shimapat4:
	include "_maps\shimaslz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 19 - blank
; ---------------------------------------------------------------------------

Obj19:					; XREF: act_tbl
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - swinging ball on a chain from GHZ boss
; ---------------------------------------------------------------------------
Map_btama:
	include "_maps\btama.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1A - GHZ collapsing ledge
; ---------------------------------------------------------------------------

break:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	break_Index(pc,d0.w),d1
		jmp	break_Index(pc,d1.w)
; ===========================================================================
break_Index:	dc.w break_Main-break_Index, break_ChkTouch-break_Index
		dc.w break_Touch-break_Index, break_Display-break_Index
		dc.w break_Delete-break_Index, break_WalkOff-break_Index
; ===========================================================================

break_Main:				; XREF: break_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_break,4(a0)
		move.w	#$4000,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#7,$38(a0)	; set time delay for collapse
		move.b	#$64,$19(a0)
		move.b	userflag(a0),$1A(a0)
		move.b	#$38,$16(a0)
		bset	#4,1(a0)

break_ChkTouch:				; XREF: break_Index
		tst.b	$3A(a0)		; has Sonic touched the	platform?
		beq.b	break_Slope	; if not, branch
		tst.b	$38(a0)		; has time reached zero?
		beq.w	break_Collapse	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time

break_Slope:
		move.w	#$30,d1
		lea	(break_SlopeData).l,a2
		bsr.w	SlopeObject
		bra.w	frameoutchk
; ===========================================================================

break_Touch:				; XREF: break_Index
		tst.b	$38(a0)
		beq.w	loc_847A
		move.b	#1,$3A(a0)	; set object as	"touched"
		subq.b	#1,$38(a0)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


break_WalkOff:				; XREF: break_Index
		move.w	#$30,d1
		bsr.w	ExitPlatform
		move.w	#$30,d1
		lea	(break_SlopeData).l,a2
		move.w	8(a0),d2
		bsr.w	SlopeObject2
		bra.w	frameoutchk
; End of function break_WalkOff

; ===========================================================================

break_Display:				; XREF: break_Index
		tst.b	$38(a0)		; has time delay reached zero?
		beq.b	break_TimeZero	; if yes, branch
		tst.b	$3A(a0)		; has Sonic touched the	object?
		bne.w	loc_82D0	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time
		bra.w	actionsub
; ===========================================================================

loc_82D0:				; XREF: break_Display
		subq.b	#1,$38(a0)
		bsr.w	break_WalkOff
		lea	playerwk,a1
		btst	#3,cddat(a1)
		beq.b	loc_82FC
		tst.b	$38(a0)
		bne.b	locret_8308
		bclr	#3,cddat(a1)
		bclr	#5,cddat(a1)
		move.b	#1,$1D(a1)

loc_82FC:
		move.b	#0,$3A(a0)
		move.b	#6,r_no0(a0)	; run "break_Display" routine

locret_8308:
		rts	
; ===========================================================================

break_TimeZero:				; XREF: break_Display
		bsr.w	speedset
		bsr.w	actionsub
		tst.b	1(a0)
		bpl.b	break_Delete
		rts	
; ===========================================================================

break_Delete:				; XREF: break_Index
		bsr.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 53 - collapsing floors	(MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------

break2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	break2_Index(pc,d0.w),d1
		jmp	break2_Index(pc,d1.w)
; ===========================================================================
break2_Index:	dc.w break2_Main-break2_Index, break2_ChkTouch-break2_Index
		dc.w break2_Touch-break2_Index, break2_Display-break2_Index
		dc.w break2_Delete-break2_Index, break2_WalkOff-break2_Index
; ===========================================================================

break2_Main:				; XREF: break2_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_break2,4(a0)
		move.w	#$42B8,2(a0)
		cmpi.b	#3,stageno ; check if level is SLZ
		bne.b	break2_NotSLZ
		move.w	#$44E0,2(a0)	; SLZ specific code
		addq.b	#2,$1A(a0)

break2_NotSLZ:
		cmpi.b	#5,stageno ; check if level is SBZ
		bne.b	break2_NotSBZ
		move.w	#$43F5,2(a0)	; SBZ specific code

break2_NotSBZ:
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#7,$38(a0)
		move.b	#$44,$19(a0)

break2_ChkTouch:				; XREF: break2_Index
		tst.b	$3A(a0)		; has Sonic touched the	object?
		beq.b	break2_Solid	; if not, branch
		tst.b	$38(a0)		; has time delay reached zero?
		beq.w	break2_Collapse	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time

break2_Solid:
		move.w	#$20,d1
		bsr.w	PlatformObject
		tst.b	userflag(a0)
		bpl.b	break2_MarkAsGone
		btst	#3,cddat(a1)
		beq.b	break2_MarkAsGone
		bclr	#0,1(a0)
		move.w	8(a1),d0
		sub.w	8(a0),d0
		bcc.b	break2_MarkAsGone
		bset	#0,1(a0)

break2_MarkAsGone:
		bra.w	frameoutchk
; ===========================================================================

break2_Touch:				; XREF: break2_Index
		tst.b	$38(a0)
		beq.w	loc_8458
		move.b	#1,$3A(a0)	; set object as	"touched"
		subq.b	#1,$38(a0)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


break2_WalkOff:				; XREF: break2_Index
		move.w	#$20,d1
		bsr.w	ExitPlatform
		move.w	8(a0),d2
		bsr.w	MvSonicOnPtfm2
		bra.w	frameoutchk
; End of function break2_WalkOff

; ===========================================================================

break2_Display:				; XREF: break2_Index
		tst.b	$38(a0)		; has time delay reached zero?
		beq.b	break2_TimeZero	; if yes, branch
		tst.b	$3A(a0)		; has Sonic touched the	object?
		bne.w	loc_8402	; if yes, branch
		subq.b	#1,$38(a0)	; subtract 1 from time
		bra.w	actionsub
; ===========================================================================

loc_8402:
		subq.b	#1,$38(a0)
		bsr.w	break2_WalkOff
		lea	playerwk,a1
		btst	#3,cddat(a1)
		beq.b	loc_842E
		tst.b	$38(a0)
		bne.b	locret_843A
		bclr	#3,cddat(a1)
		bclr	#5,cddat(a1)
		move.b	#1,$1D(a1)

loc_842E:
		move.b	#0,$3A(a0)
		move.b	#6,r_no0(a0)	; run "break2_Display" routine

locret_843A:
		rts	
; ===========================================================================

break2_TimeZero:				; XREF: break2_Display
		bsr.w	speedset
		bsr.w	actionsub
		tst.b	1(a0)
		bpl.b	break2_Delete
		rts	
; ===========================================================================

break2_Delete:				; XREF: break2_Index
		bsr.w	frameout
		rts	
; ===========================================================================

break2_Collapse:				; XREF: break2_ChkTouch
		move.b	#0,$3A(a0)

loc_8458:				; XREF: break2_Touch
		lea	(break2_Data2).l,a4
		btst	#0,userflag(a0)
		beq.b	loc_846C
		lea	(break2_Data3).l,a4

loc_846C:
		moveq	#7,d1
		addq.b	#1,$1A(a0)
		bra.b	loc_8486
; ===========================================================================

break_Collapse:				; XREF: break_ChkTouch
		move.b	#0,$3A(a0)

loc_847A:				; XREF: break_Touch
		lea	(break2_Data1).l,a4
		moveq	#$18,d1
		addq.b	#2,$1A(a0)

loc_8486:				; XREF: break2_Collapse
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.b	loc_84B2
; ===========================================================================

loc_84AA:
		bsr.w	actwkchk
		bne.b	loc_84F2
		addq.w	#5,a3

loc_84B2:
		move.b	#6,r_no0(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.b	(a4)+,$38(a1)
		cmpa.l	a0,a1
		bcc.b	loc_84EE
		bsr.w	actionsub2

loc_84EE:
		dbra	d1,loc_84AA

loc_84F2:
		bsr.w	actionsub
		move.w	#$B9,d0
		jmp	(soundset).l ;	play collapsing	sound
; ===========================================================================
; ---------------------------------------------------------------------------
; Disintegration data for collapsing ledges (MZ, SLZ, SBZ)
; ---------------------------------------------------------------------------
break2_Data1:	dc.b $1C, $18, $14, $10, $1A, $16, $12,	$E, $A,	6, $18,	$14, $10, $C, 8, 4
		dc.b $16, $12, $E, $A, 6, 2, $14, $10, $C, 0
break2_Data2:	dc.b $1E, $16, $E, 6, $1A, $12,	$A, 2
break2_Data3:	dc.b $16, $1E, $1A, $12, 6, $E,	$A, 2

; ---------------------------------------------------------------------------
; Sloped platform subroutine (GHZ collapsing ledges and	MZ platforms)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SlopeObject2:				; XREF: break_WalkOff; et al
		lea	playerwk,a1
		btst	#3,cddat(a1)
		beq.b	locret_856E
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		lsr.w	#1,d0
		btst	#0,1(a0)
		beq.b	loc_854E
		not.w	d0
		add.w	d1,d0

loc_854E:
		moveq	#0,d1
		move.b	(a2,d0.w),d1
		move.w	$C(a0),d0
		sub.w	d1,d0
		moveq	#0,d1
		move.b	$16(a1),d1
		sub.w	d1,d0
		move.w	d0,$C(a1)
		sub.w	8(a0),d2
		sub.w	d2,8(a1)

locret_856E:
		rts	
; End of function SlopeObject2

; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for GHZ collapsing ledge
; ---------------------------------------------------------------------------
break_SlopeData:
		incbin	misc\ghzledge.bin
		even

; ---------------------------------------------------------------------------
; Sprite mappings - GHZ	collapsing ledge
; ---------------------------------------------------------------------------
Map_break:
	include "_maps\break.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - collapsing floors (MZ, SLZ,	SBZ)
; ---------------------------------------------------------------------------
Map_break2:
	include "_maps\break2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1C - scenery (GHZ bridge stump, SLZ lava thrower)
; ---------------------------------------------------------------------------

bgspr:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bgspr_Index(pc,d0.w),d1
		jmp	bgspr_Index(pc,d1.w)
; ===========================================================================
bgspr_Index:	dc.w bgspr_Main-bgspr_Index
		dc.w bgspr_ChkDel-bgspr_Index
; ===========================================================================

bgspr_Main:				; XREF: bgspr_Index
		addq.b	#2,r_no0(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; copy object type to d0
		mulu.w	#$A,d0		; multiply by $A
		lea	bgspr_Var(pc,d0.w),a1
		move.l	(a1)+,4(a0)
		move.w	(a1)+,2(a0)
		ori.b	#4,1(a0)
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,$19(a0)
		move.b	(a1)+,$18(a0)
		move.b	(a1)+,colino(a0)

bgspr_ChkDel:				; XREF: bgspr_Index
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Variables for	object $1C are stored in an array
; ---------------------------------------------------------------------------
bgspr_Var:	dc.l Map_bgspr		; mappings address
		dc.w $44D8		; VRAM setting
		dc.b 0,	8, 2, 0		; frame, width,	priority, collision response
		dc.l Map_bgspr
		dc.w $44D8
		dc.b 0,	8, 2, 0
		dc.l Map_bgspr
		dc.w $44D8
		dc.b 0,	8, 2, 0
		dc.l hashipat
		dc.w $438E
		dc.b 1,	$10, 1,	0
; ---------------------------------------------------------------------------
; Sprite mappings - SLZ	lava thrower
; ---------------------------------------------------------------------------
Map_bgspr:
	include "_maps\bgspr.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1D - switch that activates when Sonic touches it
; (this	is not used anywhere in	the game)
; ---------------------------------------------------------------------------

switch:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	switch_Index(pc,d0.w),d1
		jmp	switch_Index(pc,d1.w)
; ===========================================================================
switch_Index:	dc.w switch_Main-switch_Index
		dc.w switch_Action-switch_Index
		dc.w switch_Delete-switch_Index
; ===========================================================================

switch_Main:				; XREF: switch_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_switch,4(a0)
		move.w	#$4000,2(a0)
		move.b	#4,1(a0)
		move.w	$C(a0),$30(a0)	; save position	on y-axis
		move.b	#$10,$19(a0)
		move.b	#5,$18(a0)

switch_Action:				; XREF: switch_Index
		move.w	$30(a0),$C(a0)	; restore position on y-axis
		move.w	#$10,d1
		bsr.w	switch_ChkTouch
		beq.b	switch_ChkDel
		addq.w	#2,$C(a0)	; move object 2	pixels
		moveq	#1,d0
		move.w	d0,($FFFFF7E0).w ; set switch 0	as "pressed"

switch_ChkDel:
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	switch_Delete
		rts	
; ===========================================================================

switch_Delete:				; XREF: switch_Index
		bsr.w	frameout
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	check if Sonic touches the object
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


switch_ChkTouch:				; XREF: switch_Action
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_8918
		add.w	d1,d1
		cmp.w	d1,d0
		bcc.b	loc_8918
		move.w	$C(a1),d2
		move.b	$16(a1),d1
		ext.w	d1
		add.w	d2,d1
		move.w	$C(a0),d0
		subi.w	#$10,d0
		sub.w	d1,d0
		bhi.b	loc_8918
		cmpi.w	#-$10,d0
		bcs.b	loc_8918
		moveq	#-1,d0
		rts	
; ===========================================================================

loc_8918:
		moveq	#0,d0
		rts	
; End of function switch_ChkTouch

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - object 1D
; ---------------------------------------------------------------------------
Map_switch:
	include "_maps\switch.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2A - doors (SBZ)
; ---------------------------------------------------------------------------

door:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	door_Index(pc,d0.w),d1
		jmp	door_Index(pc,d1.w)
; ===========================================================================
door_Index:	dc.w door_Main-door_Index
		dc.w door_OpenShut-door_Index
; ===========================================================================

door_Main:				; XREF: door_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_door,4(a0)
		move.w	#$42E8,2(a0)
		ori.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#4,$18(a0)

door_OpenShut:				; XREF: door_Index
		move.w	#$40,d1
		clr.b	mstno(a0)		; use "closing"	animation
		move.w	playerwk+xposi,d0
		add.w	d1,d0
		cmp.w	8(a0),d0
		bcs.b	door_Animate
		sub.w	d1,d0
		sub.w	d1,d0
		cmp.w	8(a0),d0
		bcc.b	door_Animate
		add.w	d1,d0
		cmp.w	8(a0),d0
		bcc.b	loc_899A
		btst	#0,cddat(a0)
		bne.b	door_Animate
		bra.b	door_Open
; ===========================================================================

loc_899A:				; XREF: door_OpenShut
		btst	#0,cddat(a0)
		beq.b	door_Animate

door_Open:				; XREF: door_OpenShut
		move.b	#1,mstno(a0)	; use "opening"	animation

door_Animate:				; XREF: door_OpenShut; loc_899A
		lea	(Ani_door).l,a1
		bsr.w	patchg
		tst.b	$1A(a0)		; is the door open?
		bne.b	door_MarkAsUsed ; if yes, branch
		move.w	#$11,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk

door_MarkAsUsed:
		bra.w	frameoutchk
; ===========================================================================
Ani_door:
	include "_anim\door.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - doors (SBZ)
; ---------------------------------------------------------------------------
Map_door:
	include "_maps\door.asm"

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


kageb_SolidWall:			; XREF: kageb_Solid
		bsr.w	kageb_SolidWall2
		beq.b	loc_8AA8
		bmi.w	loc_8AC4
		tst.w	d0
		beq.w	loc_8A92
		bmi.b	loc_8A7C
		tst.w	$10(a1)
		bmi.b	loc_8A92
		bra.b	loc_8A82
; ===========================================================================

loc_8A7C:
		tst.w	$10(a1)
		bpl.b	loc_8A92

loc_8A82:
		sub.w	d0,8(a1)
		move.w	#0,$14(a1)
		move.w	#0,$10(a1)

loc_8A92:
		btst	#1,cddat(a1)
		bne.b	loc_8AB6
		bset	#5,cddat(a1)
		bset	#5,cddat(a0)
		rts	
; ===========================================================================

loc_8AA8:
		btst	#5,cddat(a0)
		beq.b	locret_8AC2
		move.w	#1,mstno(a1)

loc_8AB6:
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)

locret_8AC2:
		rts	
; ===========================================================================

loc_8AC4:
		tst.w	$12(a1)
		bpl.b	locret_8AD8
		tst.w	d3
		bpl.b	locret_8AD8
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)

locret_8AD8:
		rts	
; End of function kageb_SolidWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


kageb_SolidWall2:			; XREF: kageb_SolidWall
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_8B48
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.b	loc_8B48
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		add.w	d2,d3
		bmi.b	loc_8B48
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.b	loc_8B48
		tst.b	($FFFFF7C8).w
		bmi.b	loc_8B48
		cmpi.b	#6,($FFFFD024).w
		bcc.b	loc_8B48
		tst.w	editmode
		bne.b	loc_8B48
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.b	loc_8B30
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_8B30:
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.b	loc_8B3C
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_8B3C:
		cmp.w	d1,d5
		bhi.b	loc_8B44
		moveq	#1,d4
		rts	
; ===========================================================================

loc_8B44:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_8B48:
		moveq	#0,d4
		rts	
; End of function kageb_SolidWall2

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 1E - Ball Hog enemy (SBZ)
; ---------------------------------------------------------------------------

buta:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	buta_Index(pc,d0.w),d1
		jmp	buta_Index(pc,d1.w)
; ===========================================================================
buta_Index:	dc.w buta_Main-buta_Index
		dc.w buta_Action-buta_Index
; ===========================================================================

buta_Main:				; XREF: buta_Index
		move.b	#$13,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_buta,4(a0)
		move.w	#$2302,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#5,colino(a0)
		move.b	#$C,$19(a0)
		bsr.w	speedset
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_8BAC
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		addq.b	#2,r_no0(a0)

locret_8BAC:
		rts	
; ===========================================================================

buta_Action:				; XREF: buta_Index
		lea	(Ani_buta).l,a1
		bsr.w	patchg
		cmpi.b	#1,$1A(a0)	; is final frame (01) displayed?
		bne.b	buta_SetBall	; if not, branch
		tst.b	$32(a0)		; is it	set to launch cannonball?
		beq.b	buta_MakeBall	; if yes, branch
		bra.b	buta_MarkAsGone
; ===========================================================================

buta_SetBall:				; XREF: buta_Action
		clr.b	$32(a0)		; set to launch	cannonball

buta_MarkAsGone:			; XREF: buta_Action
		bra.w	frameoutchk
; ===========================================================================

buta_MakeBall:				; XREF: buta_Action
		move.b	#1,$32(a0)
		bsr.w	actwkchk
		bne.b	loc_8C1A
		move.b	#$20,0(a1)	; load cannonball object ($20)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#-$100,$10(a1)	; cannonball bounces to	the left
		move.w	#0,$12(a1)
		moveq	#-4,d0
		btst	#0,cddat(a0)	; is Ball Hog facing right?
		beq.b	loc_8C0A	; if not, branch
		neg.w	d0
		neg.w	$10(a1)		; cannonball bounces to	the right

loc_8C0A:
		add.w	d0,8(a1)
		addi.w	#$C,$C(a1)
		move.b	userflag(a0),userflag(a1)	; copy object type from	Ball Hog

loc_8C1A:
		bra.b	buta_MarkAsGone
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 20 - cannonball that Ball Hog throws (SBZ)
; ---------------------------------------------------------------------------

Obj20:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj20_Index(pc,d0.w),d1
		jmp	Obj20_Index(pc,d1.w)
; ===========================================================================
Obj20_Index:	dc.w Obj20_Main-Obj20_Index
		dc.w Obj20_Bounce-Obj20_Index
; ===========================================================================

Obj20_Main:				; XREF: Obj20_Index
		addq.b	#2,r_no0(a0)
		move.b	#7,$16(a0)
		move.l	#Map_buta,4(a0)
		move.w	#$2302,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$87,colino(a0)
		move.b	#8,$19(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; move object type to d0
		mulu.w	#60,d0		; multiply by 60 frames	(1 second)
		move.w	d0,$30(a0)	; set explosion	time
		move.b	#4,$1A(a0)

Obj20_Bounce:				; XREF: Obj20_Index
		jsr	speedset
		tst.w	$12(a0)
		bmi.b	Obj20_ChkExplode
		jsr	emycol_d
		tst.w	d1
		bpl.b	Obj20_ChkExplode
		add.w	d1,$C(a0)
		move.w	#-$300,$12(a0)
		tst.b	d3
		beq.b	Obj20_ChkExplode
		bmi.b	loc_8CA4
		tst.w	$10(a0)
		bpl.b	Obj20_ChkExplode
		neg.w	$10(a0)
		bra.b	Obj20_ChkExplode
; ===========================================================================

loc_8CA4:				; XREF: Obj20_Bounce
		tst.w	$10(a0)
		bmi.b	Obj20_ChkExplode
		neg.w	$10(a0)

Obj20_ChkExplode:			; XREF: Obj20_Bounce
		subq.w	#1,$30(a0)	; subtract 1 from explosion time
		bpl.b	Obj20_Animate	; if time is > 0, branch
		move.b	#$24,actno(a0)
		move.b	#$3F,actno(a0)	; change object	to an explosion	($3F)
		move.b	#0,r_no0(a0)	; reset	routine	counter
		bra.w	Obj3F		; jump to explosion code
; ===========================================================================

Obj20_Animate:				; XREF: Obj20_ChkExplode
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	Obj20_Display
		move.b	#5,$1E(a0)	; set frame duration to	5 frames
		bchg	#0,$1A(a0)	; change frame

Obj20_Display:
		bsr.w	actionsub
		move.w	scralim_down,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	; has object fallen off	the level?
		bcs.w	frameout	; if yes, branch
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 24 - explosion	from a destroyed monitor
; ---------------------------------------------------------------------------

Obj24:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj24_Index(pc,d0.w),d1
		jmp	Obj24_Index(pc,d1.w)
; ===========================================================================
Obj24_Index:	dc.w Obj24_Main-Obj24_Index
		dc.w Obj24_Animate-Obj24_Index
; ===========================================================================

Obj24_Main:				; XREF: Obj24_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj24,4(a0)
		move.w	#$41C,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,colino(a0)
		move.b	#$C,$19(a0)
		move.b	#9,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#$A5,d0
		jsr	(soundset).l ;	play explosion sound

Obj24_Animate:				; XREF: Obj24_Index
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	Obj24_Display
		move.b	#9,$1E(a0)	; set frame duration to	9 frames
		addq.b	#1,$1A(a0)	; next frame
		cmpi.b	#4,$1A(a0)	; is the final frame (04) displayed?
		beq.w	frameout	; if yes, branch

Obj24_Display:
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 27 - explosion	from a destroyed enemy
; ---------------------------------------------------------------------------

bakuhatu:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bakuhatu_Index(pc,d0.w),d1
		jmp	bakuhatu_Index(pc,d1.w)
; ===========================================================================
bakuhatu_Index:	dc.w bakuhatu_LoadAnimal-bakuhatu_Index
		dc.w bakuhatu_Main-bakuhatu_Index
		dc.w bakuhatu_Animate-bakuhatu_Index
; ===========================================================================

bakuhatu_LoadAnimal:			; XREF: bakuhatu_Index
		addq.b	#2,r_no0(a0)
		bsr.w	actwkchk
		bne.b	bakuhatu_Main
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),$3E(a1)

bakuhatu_Main:				; XREF: bakuhatu_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_bakuhatu,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,colino(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		move.b	#0,$1A(a0)
		move.w	#$C1,d0
		jsr	(soundset).l ;	play breaking enemy sound

bakuhatu_Animate:				; XREF: bakuhatu_Index
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	bakuhatu_Display
		move.b	#7,$1E(a0)	; set frame duration to	7 frames
		addq.b	#1,$1A(a0)	; next frame
		cmpi.b	#5,$1A(a0)	; is the final frame (05) displayed?
		beq.w	frameout	; if yes, branch

bakuhatu_Display:
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3F - explosion	from a destroyed boss, bomb or cannonball
; ---------------------------------------------------------------------------

Obj3F:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj3F_Index(pc,d0.w),d1
		jmp	Obj3F_Index(pc,d1.w)
; ===========================================================================
Obj3F_Index:	dc.w Obj3F_Main-Obj3F_Index
		dc.w bakuhatu_Animate-Obj3F_Index
; ===========================================================================

Obj3F_Main:				; XREF: Obj3F_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj3F,4(a0)
		move.w	#$5A0,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#0,colino(a0)
		move.b	#$C,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#0,$1A(a0)
		move.w	#$C4,d0
		jmp	(soundset).l ;	play exploding bomb sound
; ===========================================================================
Ani_buta:
	include "_anim\buta.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Ball Hog enemy (SBZ)
; ---------------------------------------------------------------------------
Map_buta:
	include "_maps\buta.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - explosion
; ---------------------------------------------------------------------------
Map_obj24:
	include "_maps\obj24.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - explosion
; ---------------------------------------------------------------------------
Map_bakuhatu:	dc.w byte_8ED0-Map_bakuhatu, byte_8ED6-Map_bakuhatu
		dc.w byte_8EDC-Map_bakuhatu, byte_8EE2-Map_bakuhatu
		dc.w byte_8EF7-Map_bakuhatu
byte_8ED0:	dc.b 1
		dc.b $F8, 9, 0,	0, $F4
byte_8ED6:	dc.b 1
		dc.b $F0, $F, 0, 6, $F0
byte_8EDC:	dc.b 1
		dc.b $F0, $F, 0, $16, $F0
byte_8EE2:	dc.b 4
		dc.b $EC, $A, 0, $26, $EC
		dc.b $EC, 5, 0,	$2F, 4
		dc.b 4,	5, $18,	$2F, $EC
		dc.b $FC, $A, $18, $26,	$FC
byte_8EF7:	dc.b 4
		dc.b $EC, $A, 0, $33, $EC
		dc.b $EC, 5, 0,	$3C, 4
		dc.b 4,	5, $18,	$3C, $EC
		dc.b $FC, $A, $18, $33,	$FC
		even
; ---------------------------------------------------------------------------
; Sprite mappings - explosion from when	a boss is destroyed
; ---------------------------------------------------------------------------
Map_obj3F:	dc.w byte_8ED0-Map_obj3F
		dc.w byte_8F16-Map_obj3F
		dc.w byte_8F1C-Map_obj3F
		dc.w byte_8EE2-Map_obj3F
		dc.w byte_8EF7-Map_obj3F
byte_8F16:	dc.b 1
		dc.b $F0, $F, 0, $40, $F0
byte_8F1C:	dc.b 1
		dc.b $F0, $F, 0, $50, $F0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 28 - animals
; ---------------------------------------------------------------------------

usagi:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	usagi_move_tbl(pc,d0.w),d1
		jmp		usagi_move_tbl(pc,d1.w)
usagi_move_tbl:
		dc.w	usagiinit-usagi_move_tbl
		dc.w	usagimove0-usagi_move_tbl
		dc.w	usagimove1-usagi_move_tbl
		dc.w	usagimove2-usagi_move_tbl
		dc.w	usagimove1-usagi_move_tbl
		dc.w	usagimove1-usagi_move_tbl
		dc.w	usagimove1-usagi_move_tbl
		dc.w	usagimove2-usagi_move_tbl
		dc.w	usagimove1-usagi_move_tbl
		dc.w	usagimove3-usagi_move_tbl
		dc.w	usagimove4-usagi_move_tbl
		dc.w	usagimove4-usagi_move_tbl
		dc.w	usagimove5-usagi_move_tbl
		dc.w	usagimove6-usagi_move_tbl
		dc.w	usagimove7-usagi_move_tbl
		dc.w	usagimove8-usagi_move_tbl
		dc.w	usagimove7-usagi_move_tbl
		dc.w	usagimove8-usagi_move_tbl
		dc.w	usagimove7-usagi_move_tbl
		dc.w	usagimove9-usagi_move_tbl
		dc.w	usagimove10-usagi_move_tbl

usagi_VarIndex:	dc.b 0,	5, 2, 3, 6, 3, 4, 5, 4,	1, 0, 1

usagi_Variables:dc.w $FE00, $FC00
		dc.l usagipat
		dc.w $FE00, $FD00	; horizontal speed, vertical speed
		dc.l flicpat		; mappings address
		dc.w $FE80, $FD00
		dc.l usagipat
		dc.w $FEC0, $FE80
		dc.l flicpat
		dc.w $FE40, $FD00
		dc.l fbutapat
		dc.w $FD00, $FC00
		dc.l flicpat
		dc.w $FD80, $FC80
		dc.l fbutapat

usagi_EndSpeed:	dc.w $FBC0, $FC00, $FBC0, $FC00, $FBC0,	$FC00, $FD00, $FC00
		dc.w $FD00, $FC00, $FE80, $FD00, $FE80,	$FD00, $FEC0, $FE80
		dc.w $FE40, $FD00, $FE00, $FD00, $FD80,	$FC80

usagi_EndMap:
		dc.l	flicpat,flicpat,flicpat,usagipat,usagipat
		dc.l	pengpat,pengpat,azarpat,fbutapat,niwapat
		dc.l	risupat

usagi_EndVram:
		dc.w	$05a5,$05a5,$05a5,$0553,$0553
		dc.w	$0573,$0573,$0585,$0593,$0565
		dc.w	$05b3
; ===========================================================================

usagiinit:				; XREF: usagi_move_tbl
		tst.b	userflag(a0)		; did animal come from a destroyed enemy?
		beq.w	usagi_FromEnemy	; if yes, branch
		moveq	#0,d0
		move.b	userflag(a0),d0	; move object type to d0
		add.w	d0,d0		; multiply d0 by 2
		move.b	d0,r_no0(a0)	; move d0 to routine counter
		subi.w	#$14,d0
		move.w	usagi_EndVram(pc,d0.w),2(a0)
		add.w	d0,d0
		move.l	usagi_EndMap(pc,d0.w),4(a0)
		lea	usagi_EndSpeed(pc),a1
		move.w	(a1,d0.w),$32(a0) ; load horizontal speed
		move.w	(a1,d0.w),$10(a0)
		move.w	2(a1,d0.w),$34(a0) ; load vertical speed
		move.w	2(a1,d0.w),$12(a0)
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		bra.w	actionsub
; ===========================================================================

usagi_FromEnemy:			; XREF: usagiinit
		addq.b	#2,r_no0(a0)
		bsr.w	random
		andi.w	#1,d0
		moveq	#0,d1
		move.b	stageno,d1
		add.w	d1,d1
		add.w	d0,d1
		lea	usagi_VarIndex(pc),a1
		move.b	(a1,d1.w),d0
		move.b	d0,$30(a0)
		lsl.w	#3,d0
		lea	usagi_Variables(pc),a1
		adda.w	d0,a1
		move.w	(a1)+,$32(a0)	; load horizontal speed
		move.w	(a1)+,$34(a0)	; load vertical	speed
		move.l	(a1)+,4(a0)	; load mappings
		move.w	#$580,2(a0)	; VRAM setting for 1st animal
		btst	#0,$30(a0)	; is 1st animal	used?
		beq.b	loc_90C0	; if yes, branch
		move.w	#$592,2(a0)	; VRAM setting for 2nd animal

loc_90C0:
		move.b	#$C,$16(a0)
		move.b	#4,1(a0)
		bset	#0,1(a0)
		move.b	#6,$18(a0)
		move.b	#8,$19(a0)
		move.b	#7,$1E(a0)
		move.b	#2,$1A(a0)
		move.w	#-$400,$12(a0)
		tst.b	($FFFFF7A7).w
		bne.b	loc_911C
		bsr.w	actwkchk
		bne.b	usagi_Display
		move.b	#$29,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$3E(a0),d0
		lsr.w	#1,d0
		move.b	d0,$1A(a1)

usagi_Display:
		bra.w	actionsub
; ===========================================================================

loc_911C:
		move.b	#$12,r_no0(a0)
		clr.w	$10(a0)
		bra.w	actionsub
; ===========================================================================

usagimove0:				; XREF: usagi_move_tbl
		tst.b	1(a0)
		bpl.w	frameout
		bsr.w	speedset
		tst.w	$12(a0)
		bmi.b	loc_9180
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_9180
		add.w	d1,$C(a0)
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#1,$1A(a0)
		move.b	$30(a0),d0
		add.b	d0,d0
		addq.b	#4,d0
		move.b	d0,r_no0(a0)
		tst.b	($FFFFF7A7).w
		beq.b	loc_9180
		btst	#4,systemtimer+3
		beq.b	loc_9180
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9180:
		bra.w	actionsub
; ===========================================================================

usagimove1:				; XREF: usagi_move_tbl
		bsr.w	speedset
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.b	loc_91AE
		move.b	#0,$1A(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_91AE
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_91AE:
		tst.b	userflag(a0)
		bne.b	loc_9224
		tst.b	1(a0)
		bpl.w	frameout
		bra.w	actionsub
; ===========================================================================

usagimove2:				; XREF: usagi_move_tbl
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.b	loc_91FC
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_91FC
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)
		tst.b	userflag(a0)
		beq.b	loc_91FC
		cmpi.b	#$A,userflag(a0)
		beq.b	loc_91FC
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_91FC:
		subq.b	#1,$1E(a0)
		bpl.b	loc_9212
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_9212:
		tst.b	userflag(a0)
		bne.b	loc_9224
		tst.b	1(a0)
		bpl.w	frameout
		bra.w	actionsub
; ===========================================================================

loc_9224:				; XREF: usagi_move_tbl
		move.w	8(a0),d0
		sub.w	playerwk+xposi,d0
		bcs.b	loc_923C
		subi.w	#$180,d0
		bpl.b	loc_923C
		tst.b	1(a0)
		bpl.w	frameout

loc_923C:
		bra.w	actionsub
; ===========================================================================

usagimove3:				; XREF: usagi_move_tbl
		tst.b	1(a0)
		bpl.w	frameout
		subq.w	#1,$36(a0)
		bne.w	loc_925C
		move.b	#2,r_no0(a0)
		move.b	#3,$18(a0)

loc_925C:
		bra.w	actionsub
; ===========================================================================

usagimove4:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bcc.b	loc_927C
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#$E,r_no0(a0)
		bra.w	usagimove2
; ===========================================================================

loc_927C:
		bra.w	loc_9224
; ===========================================================================

usagimove5:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bpl.b	loc_92B6
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		bsr.w	loc_93C4
		bsr.w	loc_93EC
		subq.b	#1,$1E(a0)
		bpl.b	loc_92B6
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_92B6:
		bra.w	loc_9224
; ===========================================================================

usagimove6:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bpl.b	loc_9310
		move.w	$32(a0),$10(a0)
		move.w	$34(a0),$12(a0)
		move.b	#4,r_no0(a0)
		bra.w	usagimove1
; ===========================================================================

usagimove10:				; XREF: usagi_move_tbl
		bsr.w	speedset
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.b	loc_9310
		move.b	#0,$1A(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_9310
		not.b	$29(a0)
		bne.b	loc_9306
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_9306:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_9310:
		bra.w	loc_9224
; ===========================================================================

usagimove7:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bpl.b	loc_932E
		clr.w	$10(a0)
		clr.w	$32(a0)
		bsr.w	speedset
		bsr.w	loc_93C4
		bsr.w	loc_93EC

loc_932E:
		bra.w	loc_9224
; ===========================================================================

usagimove8:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bpl.b	loc_936C
		bsr.w	speedset
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.b	loc_936C
		move.b	#0,$1A(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_936C
		neg.w	$10(a0)
		bchg	#0,1(a0)
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_936C:
		bra.w	loc_9224
; ===========================================================================

usagimove9:				; XREF: usagi_move_tbl
		bsr.w	sub_9404
		bpl.b	loc_93C0
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		tst.w	$12(a0)
		bmi.b	loc_93AA
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_93AA
		not.b	$29(a0)
		bne.b	loc_93A0
		neg.w	$10(a0)
		bchg	#0,1(a0)

loc_93A0:
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

loc_93AA:
		subq.b	#1,$1E(a0)
		bpl.b	loc_93C0
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		andi.b	#1,$1A(a0)

loc_93C0:
		bra.w	loc_9224
; ===========================================================================

loc_93C4:
		move.b	#1,$1A(a0)
		tst.w	$12(a0)
		bmi.b	locret_93EA
		move.b	#0,$1A(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_93EA
		add.w	d1,$C(a0)
		move.w	$34(a0),$12(a0)

locret_93EA:
		rts	
; ===========================================================================

loc_93EC:
		bset	#0,1(a0)
		move.w	8(a0),d0
		sub.w	playerwk+xposi,d0
		bcc.b	locret_9402
		bclr	#0,1(a0)

locret_9402:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_9404:
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		subi.w	#$B8,d0
		rts	
; End of function sub_9404

;------------------------------------------------------------------------------
ten:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	ten_move_tbl(pc,d0.w),d1
		jsr		ten_move_tbl(pc,d1.w)
		bra.w	actionsub

ten_move_tbl:
		dc.w	ten_init-ten_move_tbl
		dc.w	ten_move-ten_move_tbl

ten_init:
		addq.b	#word,r_no0(a0)
		move.l	#tenpat,patbase(a0)
		move.w	#$2797,sproffset(a0)
		move.b	#4,actflg(a0)
		move.b	#1,sprpri(a0)
		move.b	#8,sprhs(a0)
		move.w	#-768,yspeed(a0)

ten_move:
		tst.w	yspeed(a0)
		bpl.w	frameout
		bsr.w	speedset2
		addi.w	#24,yspeed(a0)
		rts	

usagipat:
pengpat:
		dc.w	usagisp0-usagipat
		dc.w	usagisp1-usagipat
		dc.w	usagisp2-usagipat
usagisp2:
		dc.b	1
		dc.b	$f4,$06,$00,$00,$f8	;1:
usagisp0:
		dc.b	1
		dc.b	$f4,$06,$00,$06,$f8	;1:
usagisp1:
		dc.b	1
		dc.b	$f4,$06,$00,$0c,$f8	;1:

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------

flicpat:
azarpat:
niwapat:
	include "_maps\usagia.asm"

fbutapat:
risupat:
	include "_maps\usagib.asm"

tenpat:
		dc.w	tenpat0-tenpat
		dc.w	tenpat1-tenpat
		dc.w	tenpat2-tenpat
		dc.w	tenpat3-tenpat
		dc.w	tenpat4-tenpat
		dc.w	tenpat5-tenpat
		dc.w	tenpat6-tenpat
tenpat0:
		dc.b	1
		dc.b	$fc,$04,$00,$00,$f8	;1:
tenpat1:
		dc.b	1
		dc.b	$fc,$04,$00,$02,$f8	;1:
tenpat2:
		dc.b	1
		dc.b	$fc,$04,$00,$04,$f8	;1:
tenpat3:
		dc.b	1
		dc.b	$fc,$08,$00,$06,$f8	;1:
tenpat4:
		dc.b	1
		dc.b	$fc,$00,$00,$06,$fc	;1:
tenpat5:
		dc.b	2
		dc.b	$fc,$08,$00,$06,$f4	;1:
		dc.b	$fc,$04,$00,$07,$01	;2:
tenpat6:
		dc.b	2
		dc.b	$fc,$08,$00,$06,$f4	;1:
		dc.b	$fc,$04,$00,$07,$06	;2:

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------

kani:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	kani_Index(pc,d0.w),d1
		jmp	kani_Index(pc,d1.w)
kani_Index:
		dc.w	kani_Main-kani_Index
		dc.w	kani_Action-kani_Index
		dc.w	kani_Delete-kani_Index
		dc.w	kani_BallMain-kani_Index
		dc.w	kani_BallMove-kani_Index
kani_Main:
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)
		move.l	#kanipat,4(a0)
		move.w	#$400,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#6,colino(a0)
		move.b	#$15,$19(a0)
		bsr.w	speedset
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_955A
		add.w	d1,$C(a0)
		move.b	d3,direc(a0)
		move.w	#0,$12(a0)
		addq.b	#2,r_no0(a0)

locret_955A:
		rts	
; ===========================================================================

kani_Action:				; XREF: kani_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	kani_Index2(pc,d0.w),d1
		jsr	kani_Index2(pc,d1.w)
		lea	(Ani_kani).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
kani_Index2:	dc.w kani_WaitFire-kani_Index2
		dc.w kani_WalkOnFloor-kani_Index2
; ===========================================================================

kani_WaitFire:				; XREF: kani_Index2
		subq.w	#1,$30(a0)	; subtract 1 from time delay
		bpl.b	locret_95B6
		tst.b	1(a0)
		bpl.b	kani_Move
		bchg	#1,$32(a0)
		bne.b	kani_MakeFire

kani_Move:
		addq.b	#2,r_no1(a0)
		move.w	#127,$30(a0)	; set time delay to approx 2 seconds
		move.w	#$80,$10(a0)	; move Crabmeat	to the right
		bsr.w	kani_SetAni
		addq.b	#3,d0
		move.b	d0,mstno(a0)
		bchg	#0,cddat(a0)
		bne.b	locret_95B6
		neg.w	$10(a0)		; change direction

locret_95B6:
		rts	
; ===========================================================================

kani_MakeFire:				; XREF: kani_WaitFire
		move.w	#$3B,$30(a0)
		move.b	#6,mstno(a0)	; use firing animation
		bsr.w	actwkchk
		bne.b	kani_MakeFire2
		move.b	#$1F,0(a1)	; load left fireball
		move.b	#6,r_no0(a1)
		move.w	8(a0),8(a1)
		subi.w	#$10,8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#-$100,$10(a1)

kani_MakeFire2:
		bsr.w	actwkchk
		bne.b	locret_9618
		move.b	#$1F,0(a1)	; load right fireball
		move.b	#6,r_no0(a1)
		move.w	8(a0),8(a1)
		addi.w	#$10,8(a1)
		move.w	$C(a0),$C(a1)
		move.w	#$100,$10(a1)

locret_9618:
		rts	
; ===========================================================================

kani_WalkOnFloor:			; XREF: kani_Index2
		subq.w	#1,$30(a0)
		bmi.b	loc_966E
		bsr.w	speedset2
		bchg	#0,$32(a0)
		bne.b	loc_9654
		move.w	8(a0),d3
		addi.w	#$10,d3
		btst	#0,cddat(a0)
		beq.b	loc_9640
		subi.w	#$20,d3

loc_9640:
		jsr	emycol_d2
		cmpi.w	#-8,d1
		blt.b	loc_966E
		cmpi.w	#$C,d1
		bge.b	loc_966E
		rts	
; ===========================================================================

loc_9654:				; XREF: kani_WalkOnFloor
		jsr	emycol_d
		add.w	d1,$C(a0)
		move.b	d3,direc(a0)
		bsr.w	kani_SetAni
		addq.b	#3,d0
		move.b	d0,mstno(a0)
		rts	
; ===========================================================================

loc_966E:				; XREF: kani_WalkOnFloor
		subq.b	#2,r_no1(a0)
		move.w	#59,$30(a0)
		move.w	#0,$10(a0)
		bsr.w	kani_SetAni
		move.b	d0,mstno(a0)
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	set the	correct	animation for a	Crabmeat
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


kani_SetAni:				; XREF: loc_966E
		moveq	#0,d0
		move.b	direc(a0),d3
		bmi.b	loc_96A4
		cmpi.b	#6,d3
		bcs.b	locret_96A2
		moveq	#1,d0
		btst	#0,cddat(a0)
		bne.b	locret_96A2
		moveq	#2,d0

locret_96A2:
		rts	
; ===========================================================================

loc_96A4:				; XREF: kani_SetAni
		cmpi.b	#-6,d3
		bhi.b	locret_96B6
		moveq	#2,d0
		btst	#0,cddat(a0)
		bne.b	locret_96B6
		moveq	#1,d0

locret_96B6:
		rts	
; End of function kani_SetAni

; ===========================================================================

kani_Delete:				; XREF: kani_Index
		bsr.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sub-object - missile that the	Crabmeat throws
; ---------------------------------------------------------------------------

kani_BallMain:				; XREF: kani_Index
		addq.b	#2,r_no0(a0)
		move.l	#kanipat,4(a0)
		move.w	#$400,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$87,colino(a0)
		move.b	#8,$19(a0)
		move.w	#-$400,$12(a0)
		move.b	#7,mstno(a0)

kani_BallMove:				; XREF: kani_Index
		lea	(Ani_kani).l,a1
		bsr.w	patchg
		bsr.w	speedset
		bsr.w	actionsub
		move.w	scralim_down,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	; has object moved below the level boundary?
		bcs.b	kani_Delete2	; if yes, branch
		rts	
; ===========================================================================

kani_Delete2:
		bra.w	frameout
; ===========================================================================
Ani_kani:
	include "_anim\kani.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Crabmeat enemy (GHZ, SYZ)
; ---------------------------------------------------------------------------
kanipat:
	include "_maps\kani.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 22 - Buzz Bomber enemy	(GHZ, MZ, SYZ)
; ---------------------------------------------------------------------------

hachi:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	hachi_Index(pc,d0.w),d1
		jmp	hachi_Index(pc,d1.w)
; ===========================================================================
hachi_Index:	dc.w hachi_Main-hachi_Index
		dc.w hachi_Action-hachi_Index
		dc.w hachi_Delete-hachi_Index
; ===========================================================================

hachi_Main:				; XREF: hachi_Index
		addq.b	#2,r_no0(a0)
		move.l	#hachipat,4(a0)
		move.w	#$444,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,colino(a0)
		move.b	#$18,$19(a0)

hachi_Action:				; XREF: hachi_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	hachi_Index2(pc,d0.w),d1
		jsr	hachi_Index2(pc,d1.w)
		lea	(Ani_hachi).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
hachi_Index2:	dc.w hachi_Move-hachi_Index2
		dc.w hachi_ChkNrSonic-hachi_Index2
; ===========================================================================

hachi_Move:				; XREF: hachi_Index2
		subq.w	#1,$32(a0)	; subtract 1 from time delay
		bpl.b	locret_986C	; if time remains, branch
		btst	#1,$34(a0)	; is Buzz Bomber near Sonic?
		bne.b	hachi_Fire	; if yes, branch
		addq.b	#2,r_no1(a0)
		move.w	#127,$32(a0)	; set time delay to just over 2	seconds
		move.w	#$400,$10(a0)	; move Buzz Bomber to the right
		move.b	#1,mstno(a0)	; use "flying" animation
		btst	#0,cddat(a0)	; is Buzz Bomber facing	left?
		bne.b	locret_986C	; if not, branch
		neg.w	$10(a0)		; move Buzz Bomber to the left

locret_986C:
		rts	
; ===========================================================================

hachi_Fire:				; XREF: hachi_Move
		bsr.w	actwkchk
		bne.b	locret_98D0
		move.b	#$23,0(a1)	; load missile object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$1C,$C(a1)
		move.w	#$200,$12(a1)	; move missile downwards
		move.w	#$200,$10(a1)	; move missile to the right
		move.w	#$18,d0
		btst	#0,cddat(a0)	; is Buzz Bomber facing	left?
		bne.b	loc_98AA	; if not, branch
		neg.w	d0
		neg.w	$10(a1)		; move missile to the left

loc_98AA:
		add.w	d0,8(a1)
		move.b	cddat(a0),cddat(a1)
		move.w	#$E,$32(a1)
		move.l	a0,$3C(a1)
		move.b	#1,$34(a0)	; set to "already fired" to prevent refiring
		move.w	#$3B,$32(a0)
		move.b	#2,mstno(a0)	; use "firing" animation

locret_98D0:
		rts	
; ===========================================================================

hachi_ChkNrSonic:			; XREF: hachi_Index2
		subq.w	#1,$32(a0)	; subtract 1 from time delay
		bmi.b	hachi_ChgDir
		bsr.w	speedset2
		tst.b	$34(a0)
		bne.b	locret_992A
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bpl.b	hachi_SetNrSonic
		neg.w	d0

hachi_SetNrSonic:
		cmpi.w	#$60,d0		; is Buzz Bomber within	$60 pixels of Sonic?
		bcc.b	locret_992A	; if not, branch
		tst.b	1(a0)
		bpl.b	locret_992A
		move.b	#2,$34(a0)	; set Buzz Bomber to "near Sonic"
		move.w	#29,$32(a0)	; set time delay to half a second
		bra.b	hachi_Stop
; ===========================================================================

hachi_ChgDir:				; XREF: hachi_ChkNrSonic
		move.b	#0,$34(a0)	; set Buzz Bomber to "normal"
		bchg	#0,cddat(a0)	; change direction
		move.w	#59,$32(a0)

hachi_Stop:				; XREF: hachi_SetNrSonic
		subq.b	#2,r_no1(a0)	; run "hachi_Fire" routine
		move.w	#0,$10(a0)	; stop Buzz Bomber moving
		move.b	#0,mstno(a0)	; use "hovering" animation

locret_992A:
		rts	
; ===========================================================================

hachi_Delete:				; XREF: hachi_Index
		bsr.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 23 - missile that Buzz	Bomber throws
; ---------------------------------------------------------------------------

Obj23:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj23_Index(pc,d0.w),d1
		jmp	Obj23_Index(pc,d1.w)
; ===========================================================================
Obj23_Index:	dc.w Obj23_Main-Obj23_Index
		dc.w Obj23_Animate-Obj23_Index
		dc.w Obj23_FromBuzz-Obj23_Index
		dc.w Obj23_Delete-Obj23_Index
		dc.w Obj23_FromNewt-Obj23_Index
; ===========================================================================

Obj23_Main:				; XREF: Obj23_Index
		subq.w	#1,$32(a0)
		bpl.b	Obj23_ChkCancel
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj23,4(a0)
		move.w	#$2444,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		andi.b	#3,cddat(a0)
		tst.b	userflag(a0)		; was object created by	a Newtron?
		beq.b	Obj23_Animate	; if not, branch
		move.b	#8,r_no0(a0)	; run "Obj23_FromNewt" routine
		move.b	#$87,colino(a0)
		move.b	#1,mstno(a0)
		bra.b	Obj23_Animate2
; ===========================================================================

Obj23_Animate:				; XREF: Obj23_Index
		bsr.b	Obj23_ChkCancel
		lea	(Ani_obj23).l,a1
		bsr.w	patchg
		bra.w	actionsub
; ---------------------------------------------------------------------------
; Subroutine to	check if the Buzz Bomber which fired the missile has been
; destroyed, and if it has, then cancel	the missile
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj23_ChkCancel:			; XREF: Obj23_Main
		movea.l	$3C(a0),a1
		cmpi.b	#$27,0(a1)	; has Buzz Bomber been destroyed?
		beq.b	Obj23_Delete	; if yes, branch
		rts	
; End of function Obj23_ChkCancel

; ===========================================================================

Obj23_FromBuzz:				; XREF: Obj23_Index
		btst	#7,cddat(a0)
		bne.b	Obj23_Explode
		move.b	#$87,colino(a0)
		move.b	#1,mstno(a0)
		bsr.w	speedset2
		lea	(Ani_obj23).l,a1
		bsr.w	patchg
		bsr.w	actionsub
		move.w	scralim_down,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	; has object moved below the level boundary?
		bcs.b	Obj23_Delete	; if yes, branch
		rts	
; ===========================================================================

Obj23_Explode:				; XREF: Obj23_FromBuzz
		move.b	#$24,actno(a0)	; change object	to an explosion	(Obj24)
		move.b	#0,r_no0(a0)
		bra.w	Obj24
; ===========================================================================

Obj23_Delete:				; XREF: Obj23_Index
		bsr.w	frameout
		rts	
; ===========================================================================

Obj23_FromNewt:				; XREF: Obj23_Index
		tst.b	1(a0)
		bpl.b	Obj23_Delete
		bsr.w	speedset2

Obj23_Animate2:				; XREF: Obj23_Main
		lea	(Ani_obj23).l,a1
		bsr.w	patchg
		bsr.w	actionsub
		rts	
; ===========================================================================
Ani_hachi:
	include "_anim\hachi.asm"

Ani_obj23:
	include "_anim\obj23.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Buzz Bomber	enemy
; ---------------------------------------------------------------------------
hachipat:
	include "_maps\hachi.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - missile that Buzz Bomber throws
; ---------------------------------------------------------------------------
Map_obj23:
	include "_maps\obj23.asm"

; ===========================================================================

ring:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	ring_move_tbl(pc,d0.w),d1
		jmp		ring_move_tbl(pc,d1.w)
ring_move_tbl:
		dc.w	ringinit-ring_move_tbl
		dc.w	ringmove-ring_move_tbl
		dc.w	ringget-ring_move_tbl
		dc.w	ringdie-ring_move_tbl
		dc.w	ringerase-ring_move_tbl
ringtbl:
		dc.b	16,0
		dc.b	24,0
		dc.b	32,0
		dc.b	0,16
		dc.b	0,24
		dc.b	0,32
		dc.b	16,16
		dc.b	24,24
		dc.b	32,32
		dc.b	-16,16
		dc.b	-24,24
		dc.b	-32,32
		dc.b	16,8
		dc.b	24,16
		dc.b	-16,8
		dc.b	-24,16
ringinit:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		lea	2(a2,d0.w),a2
		move.b	(a2),d4
		move.b	userflag(a0),d1
		move.b	d1,d0
		andi.w	#7,d1
		cmpi.w	#7,d1
		bne.b	?jump0
		moveq	#6,d1

?jump0:
		swap	d1
		move.w	#0,d1
		lsr.b	#4,d0
		add.w	d0,d0
		move.b	ringtbl(pc,d0.w),d5 ; load ring spacing data
		ext.w	d5
		move.b	ringtbl+1(pc,d0.w),d6
		ext.w	d6
		movea.l	a0,a1
		move.w	xposi(a0),d2
		move.w	yposi(a0),d3
		lsr.b	#1,d4
		bcs.b	?jump2
		bclr	#7,(a2)
		bra.b	?jump1

?loop:
		swap	d1
		lsr.b	#1,d4
		bcs.b	?jump2
		bclr	#7,(a2)
		bsr.w	actwkchk
		bne.b	?worknai

?jump1:				; XREF: ringinit
		move.b	#ring_act,actno(a1)	; load ring object
		addq.b	#word,r_no0(a1)
		move.w	d2,xposi(a1)	; set x-axis position based on d2
		move.w	xposi(a0),$32(a1)
		move.w	d3,yposi(a1)	; set y-axis position based on d3
		move.l	#ringpat,patbase(a1)
		move.w	#$27b2,sproffset(a1)
		move.b	#4,actflag(a1)
		move.b	#2,sprpri(a1)
		move.b	#$47,colino(a1)
		move.b	#8,sprhs(a1)
		move.b	cdsts(a0),cdsts(a1)
		move.b	d1,$34(a1)

?jump2:
		addq.w	#1,d1
		add.w	d5,d2		; add ring spacing value to d2
		add.w	d6,d3		; add ring spacing value to d3
		swap	d1
		dbra	d1,?loop ; repeat for	number of rings

?worknai:
		btst	#0,(a2)
		bne.w	frameout

ringmove:
		move.b	sys_patno2,patno(a0)
		bsr.w	actionsub
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	ringerase
		rts	
ringget:
		addq.b	#word,r_no0(a0)
		move.b	#0,colino(a0)
		move.b	#1,$18(a0)
		bsr.w	ringgetsub
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		move.b	$34(a0),d1
		bset	d1,2(a2,d0.w)

ringdie:
		lea	(ringchg).l,a1
		bsr.w	patchg
		bra.w	actionsub
ringerase:
		bra.w	frameout

ringgetsub:
		addq.w	#1,plring
		ori.b	#1,plring_f
		move.w	#$B5,d0
		cmpi.w	#100,plring
		bcs.b	?jump1
		bset	#1,plring_f2
		beq.b	?jump0
		cmpi.w	#200,plring 
		bcs.b	?jump1
		bset	#2,plring_f2
		bne.b	?jump1

?jump0:
		addq.b	#1,pl_suu
		addq.b	#1,pl_suu_f
		move.w	#$88,d0

?jump1:
		jmp		soundset

flyring:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	flyring_move_tbl(pc,d0.w),d1
		jmp		flyring_move_tbl(pc,d1.w)
flyring_move_tbl:
		dc.w	flyringinit-flyring_move_tbl
		dc.w	flyringmove-flyring_move_tbl
		dc.w	flyringget-flyring_move_tbl
		dc.w	flyringdie-flyring_move_tbl
		dc.w	flyringerase-flyring_move_tbl
flyringinit:
		movea.l	a0,a1
		moveq	#0,d5
		move.w	plring,d5
		moveq	#32,d0
		cmp.w	d0,d5
		bcs.b	?jump0
		move.w	d0,d5
?jump0:
		subq.w	#1,d5
		move.w	#$288,d4
		bra.b	?jump1
?loop:
		bsr.w	actwkchk
		bne.w	?jump3
?jump1:
		move.b	#flyring_act,actno(a1)
		addq.b	#word,r_no0(a1)
		move.b	#8,sprvsize(a1)
		move.b	#8,sprhsize(a1)
		move.w	xposi(a0),xposi(a1)
		move.w	yposi(a0),yposi(a1)
		move.l	#ringpat,patbase(a1)
		move.w	#$27b2,sproffset(a1)
		move.b	#4,actflg(a1)
		move.b	#3,sprpri(a1)
		move.b	#$47,colino(a1)
		move.b	#8,sprhs(a1)
		move.b	#-1,sys_pattim4
		tst.w	d4
		bmi.b	?jump2
		move.w	d4,d0
		bsr.w	sinset
		move.w	d4,d2
		lsr.w	#8,d2
		asl.w	d2,d0
		asl.w	d2,d1
		move.w	d0,d2
		move.w	d1,d3
		addi.b	#$10,d4
		bcc.b	?jump2
		subi.w	#$80,d4
		bcc.b	?jump2
		move.w	#$288,d4
?jump2:
		move.w	d2,xspeed(a1)
		move.w	d3,yspeed(a1)
		neg.w	d2
		neg.w	d4
		dbra	d5,?loop
?jump3:
		move.w	#0,plring
		move.b	#$80,plring_f
		move.b	#0,plring_f2
		move.w	#$C6,d0
		jsr		soundset
flyringmove:
		move.b	sys_patno4,patno(a0)
		bsr.w	speedset2
		addi.w	#24,yspeed(a0)
		bmi.b	?jump
		move.b	systemtimer+3,d0
		add.b	d7,d0
		andi.b	#3,d0
		bne.b	?jump
		jsr		emycol_d
		tst.w	d1
		bpl.b	?jump
		add.w	d1,yposi(a0)
		move.w	yspeed(a0),d0
		asr.w	#2,d0
		sub.w	d0,yspeed(a0)
		neg.w	yspeed(a0)
?jump:
		tst.b	sys_pattim4
		beq.b	flyringerase
		move.w	scralim_down,d0
		addi.w	#224,d0
		cmp.w	yposi(a0),d0
		bcs.b	flyringerase
		bra.w	actionsub
flyringget:
		addq.b	#word,r_no0(a0)
		move.b	#0,colino(a0)
		move.b	#1,sprpri(a0)
		bsr.w	ringgetsub
flyringdie:
		lea		ringchg,a1
		bsr.w	patchg
		bra.w	actionsub
flyringerase:
		bra.w	frameout

bigring:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bring_move_tbl(pc,d0.w),d1
		jmp	bring_move_tbl(pc,d1.w)

bring_move_tbl:
		dc.w	bring_init-bring_move_tbl
		dc.w	bring_move0-bring_move_tbl
		dc.w	bring_move1-bring_move_tbl
		dc.w	bring_move2-bring_move_tbl
bring_init:
		move.l	#bringpat,patbase(a0)
		move.w	#$2400,sproffset(a0)
		ori.b	#4,actflg(a0)
		move.b	#64,sprhs(a0)
		tst.b	actflg(a0)
		bpl.b	bring_move0
		cmpi.b	#6,($FFFFFE57).w ; do you have 6 emeralds?
		beq.w	bring_move2	; if yes, branch
		cmpi.w	#50,plring ; do you have	at least 50 rings?
		bcc.b	bigring_Okay	; if yes, branch
		rts

bigring_Okay:				; XREF: bring_init
		addq.b	#word,r_no0(a0)
		move.b	#2,sprpri(a0)
		move.b	#$52,colino(a0)
		move.w	#$C40,($FFFFF7BE).w

bring_move0:				; XREF: bring_move_tbl
		move.b	sys_patno2,patno(a0)
		move.w	xposi(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================

bring_move1:				; XREF: bring_move_tbl
		subq.b	#word,r_no0(a0)
		move.b	#0,colino(a0)
		bsr.w	actwkchk
		bne.w	?jump
		move.b	#bring2_act,actno(a1)
		move.w	xposi(a0),xposi(a1)
		move.w	yposi(a0),ypsoi(a1)
		move.l	a0,$3C(a1)
		move.w	playerwk+xposi,d0
		cmp.w	xposi(a0),D0
		bcs.b	?jump
		bset.b	#0,actflg(a1)

?jump:
		move.w	#$c3,d0
		jsr		soundset
		bra.b	bring_move0

bring_move2:
		bra.w	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7C - flash effect when	you collect the	giant ring
; ---------------------------------------------------------------------------

Obj7C:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj7C_Index(pc,d0.w),d1
		jmp	Obj7C_Index(pc,d1.w)
; ===========================================================================
Obj7C_Index:	dc.w Obj7C_Main-Obj7C_Index
		dc.w Obj7C_ChkDel-Obj7C_Index
		dc.w Obj7C_Delete-Obj7C_Index
; ===========================================================================

Obj7C_Main:				; XREF: Obj7C_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj7C,4(a0)
		move.w	#$2462,2(a0)
		ori.b	#4,1(a0)
		move.b	#0,$18(a0)
		move.b	#$20,$19(a0)
		move.b	#$FF,$1A(a0)

Obj7C_ChkDel:				; XREF: Obj7C_Index
		bsr.b	Obj7C_Collect
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj7C_Collect:				; XREF: Obj7C_ChkDel
		subq.b	#1,$1E(a0)
		bpl.b	locret_9F76
		move.b	#1,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#8,$1A(a0)	; has animation	finished?
		bcc.b	Obj7C_End	; if yes, branch
		cmpi.b	#3,$1A(a0)	; is 3rd frame displayed?
		bne.b	locret_9F76	; if not, branch
		movea.l	$3C(a0),a1
		move.b	#6,r_no0(a1)	; delete giant ring object (bigring)
		move.b	#$1C,playerwk+mstno ; make Sonic	invisible
		move.b	#1,special_flag ; stop	Sonic getting bonuses
		clr.b	plpower_m	; remove invincibility
		clr.b	plpower_b	; remove shield

locret_9F76:
		rts	
; ===========================================================================

Obj7C_End:				; XREF: Obj7C_Collect
		addq.b	#2,r_no0(a0)
		move.w	#0,playerwk ; remove Sonic	object
		addq.l	#4,sp
		rts	
; End of function Obj7C_Collect

; ===========================================================================

Obj7C_Delete:				; XREF: Obj7C_Index
		bra.w	frameout
; ===========================================================================
ringchg:
	include "_anim\ring.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - rings
; ---------------------------------------------------------------------------
ringpat:
	include "_maps\ring.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - giant ring
; ---------------------------------------------------------------------------
bringpat:
	include "_maps\obj4B.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - flash effect when you collect the giant ring
; ---------------------------------------------------------------------------
Map_obj7C:
	include "_maps\obj7C.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 26 - monitors
; ---------------------------------------------------------------------------

item:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	item_Index(pc,d0.w),d1
		jmp	item_Index(pc,d1.w)
; ===========================================================================
item_Index:	dc.w item_Main-item_Index
		dc.w item_Solid-item_Index
		dc.w item_BreakOpen-item_Index
		dc.w item_Animate-item_Index
		dc.w item_Display-item_Index
; ===========================================================================

item_Main:				; XREF: item_Index
		addq.b	#2,r_no0(a0)
		move.b	#$E,$16(a0)
		move.b	#$E,$17(a0)
		move.l	#itempat,4(a0)
		move.w	#$680,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$F,$19(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)	; has monitor been broken?
		beq.b	item_NotBroken	; if not, branch
		move.b	#8,r_no0(a0)	; run "item_Display" routine
		move.b	#$B,$1A(a0)	; use broken monitor frame
		rts	
; ===========================================================================

item_NotBroken:			; XREF: item_Main
		move.b	#$46,colino(a0)
		move.b	userflag(a0),mstno(a0)

item_Solid:				; XREF: item_Index
		move.b	r_no1(a0),d0	; is monitor set to fall?
		beq.b	loc_A1EC	; if not, branch
		subq.b	#2,d0
		bne.b	item_Fall
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,cddat(a1)
		bne.w	loc_A1BC
		clr.b	r_no1(a0)
		bra.w	item_Animate
; ===========================================================================

loc_A1BC:				; XREF: item_Solid
		move.w	#$10,d3
		move.w	8(a0),d2
		bsr.w	MvSonicOnPtfm
		bra.w	item_Animate
; ===========================================================================

item_Fall:				; XREF: item_Solid
		bsr.w	speedset
		jsr	emycol_d
		tst.w	d1
		bpl.w	item_Animate
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	r_no1(a0)
		bra.w	item_Animate
; ===========================================================================

loc_A1EC:				; XREF: item_Solid
		move.w	#$1A,d1
		move.w	#$F,d2
		bsr.w	item_SolidSides
		beq.w	loc_A25C
		tst.w	$12(a1)
		bmi.b	loc_A20A
		cmpi.b	#2,mstno(a1)	; is Sonic rolling?
		beq.b	loc_A25C	; if yes, branch

loc_A20A:
		tst.w	d1
		bpl.b	loc_A220
		sub.w	d3,$C(a1)
		bsr.w	loc_74AE
		move.b	#2,r_no1(a0)
		bra.w	item_Animate
; ===========================================================================

loc_A220:
		tst.w	d0
		beq.w	loc_A246
		bmi.b	loc_A230
		tst.w	$10(a1)
		bmi.b	loc_A246
		bra.b	loc_A236
; ===========================================================================

loc_A230:
		tst.w	$10(a1)
		bpl.b	loc_A246

loc_A236:
		sub.w	d0,8(a1)
		move.w	#0,$14(a1)
		move.w	#0,$10(a1)

loc_A246:
		btst	#1,cddat(a1)
		bne.b	loc_A26A
		bset	#5,cddat(a1)
		bset	#5,cddat(a0)
		bra.b	item_Animate
; ===========================================================================

loc_A25C:
		btst	#5,cddat(a0)
		beq.b	item_Animate
		move.w	#1,mstno(a1)

loc_A26A:
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)

item_Animate:				; XREF: item_Index
		lea	(Ani_item).l,a1
		bsr.w	patchg

item_Display:				; XREF: item_Index
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================

item_BreakOpen:			; XREF: item_Index
		addq.b	#2,r_no0(a0)
		move.b	#0,colino(a0)
		bsr.w	actwkchk
		bne.b	item_Explode
		move.b	#$2E,0(a1)	; load monitor contents	object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	mstno(a0),mstno(a1)

item_Explode:
		bsr.w	actwkchk
		bne.b	item_SetBroken
		move.b	#$27,0(a1)	; load explosion object
		addq.b	#2,r_no0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

item_SetBroken:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bset	#0,2(a2,d0.w)
		move.b	#9,mstno(a0)	; set monitor type to broken
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2E - contents of monitors
; ---------------------------------------------------------------------------

item2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	item2_Index(pc,d0.w),d1
		jsr	item2_Index(pc,d1.w)
		bra.w	actionsub
; ===========================================================================
item2_Index:	dc.w item2_Main-item2_Index
		dc.w item2_Move-item2_Index
		dc.w item2_Delete-item2_Index
; ===========================================================================

item2_Main:				; XREF: item2_Index
		addq.b	#2,r_no0(a0)
		move.w	#$680,2(a0)
		move.b	#$24,1(a0)
		move.b	#3,$18(a0)
		move.b	#8,$19(a0)
		move.w	#-$300,$12(a0)
		moveq	#0,d0
		move.b	mstno(a0),d0
		addq.b	#2,d0
		move.b	d0,$1A(a0)
		movea.l	#itempat,a1
		add.b	d0,d0
		adda.w	(a1,d0.w),a1
		addq.w	#1,a1
		move.l	a1,4(a0)

item2_Move:				; XREF: item2_Index
		tst.w	$12(a0)		; is object moving?
		bpl.w	item2_ChkEggman	; if not, branch
		bsr.w	speedset2
		addi.w	#$18,$12(a0)	; reduce object	speed
		rts	
; ===========================================================================

item2_ChkEggman:			; XREF: item2_Move
		addq.b	#2,r_no0(a0)
		move.w	#29,$1E(a0)
		move.b	mstno(a0),d0
		cmpi.b	#1,d0		; does monitor contain Eggman?
		bne.b	item2_ChkSonic
		rts			; Eggman monitor does nothing
; ===========================================================================

item2_ChkSonic:
		cmpi.b	#2,d0		; does monitor contain Sonic?
		bne.b	item2_ChkShoes

ExtraLife:
		addq.b	#1,pl_suu ; add 1 to the	number of lives	you have
		addq.b	#1,pl_suu_f ; add 1 to the	lives counter
		move.w	#$88,d0
		jmp	(bgmset).l	; play extra life music
; ===========================================================================

item2_ChkShoes:
		cmpi.b	#3,d0		; does monitor contain speed shoes?
		bne.b	item2_ChkShield
		move.b	#1,plpower_s ; speed up the	BG music
		move.w	#$4B0,($FFFFD034).w ; time limit for the power-up
		move.w	#$C00,plmaxspdwk ; change Sonic's top speed
		move.w	#$18,pladdspdwk
		move.w	#$80,plretspdwk
		move.w	#$E2,d0
		jmp	(bgmset).l	; Speed	up the music
; ===========================================================================

item2_ChkShield:
		cmpi.b	#4,d0		; does monitor contain a shield?
		bne.b	item2_ChkInvinc
		move.b	#1,plpower_b ; give	Sonic a	shield
		move.b	#$38,($FFFFD180).w ; load shield object	($38)
		move.w	#$AF,d0
		jmp	(bgmset).l	; play shield sound
; ===========================================================================

item2_ChkInvinc:
		cmpi.b	#5,d0		; does monitor contain invincibility?
		bne.b	item2_ChkRings
		move.b	#1,plpower_m ; make	Sonic invincible
		move.w	#$4B0,($FFFFD032).w ; time limit for the power-up
		move.b	#$38,($FFFFD200).w ; load stars	object ($3801)
		move.b	#1,($FFFFD21C).w
		move.b	#$38,($FFFFD240).w ; load stars	object ($3802)
		move.b	#2,($FFFFD25C).w
		move.b	#$38,($FFFFD280).w ; load stars	object ($3803)
		move.b	#3,($FFFFD29C).w
		move.b	#$38,($FFFFD2C0).w ; load stars	object ($3804)
		move.b	#4,($FFFFD2DC).w
		tst.b	($FFFFF7AA).w	; is boss mode on?
		bne.b	item2_NoMusic	; if yes, branch
		move.w	#$87,d0
		jmp	(bgmset).l	; play invincibility music
; ===========================================================================

item2_NoMusic:
		rts	
; ===========================================================================

item2_ChkRings:
		cmpi.b	#6,d0		; does monitor contain 10 rings?
		bne.b	item2_ChkS
		addi.w	#$A,plring ; add	10 rings to the	number of rings	you have
		ori.b	#1,plring_f ; update the ring counter
		cmpi.w	#100,plring ; check if you have 100 rings
		bcs.b	item2_RingSound
		bset	#1,plring_f2
		beq.w	ExtraLife
		cmpi.w	#200,plring ; check if you have 200 rings
		bcs.b	item2_RingSound
		bset	#2,plring_f2
		beq.w	ExtraLife

item2_RingSound:
		move.w	#$B5,d0
		jmp	(bgmset).l	; play ring sound
; ===========================================================================

item2_ChkS:
		cmpi.b	#7,d0		; does monitor contain 'S'
		bne.b	item2_ChkEnd
		nop	

item2_ChkEnd:
		rts			; 'S' and goggles monitors do nothing
; ===========================================================================

item2_Delete:				; XREF: item2_Index
		subq.w	#1,$1E(a0)
		bmi.w	frameout
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	make the sides of a monitor solid
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


item_SolidSides:			; XREF: loc_A1EC
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_A4E6
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.b	loc_A4E6
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		add.w	d2,d3
		bmi.b	loc_A4E6
		add.w	d2,d2
		cmp.w	d2,d3
		bcc.b	loc_A4E6
		tst.b	($FFFFF7C8).w
		bmi.b	loc_A4E6
		cmpi.b	#6,($FFFFD024).w
		bcc.b	loc_A4E6
		tst.w	editmode
		bne.b	loc_A4E6
		cmp.w	d0,d1
		bcc.b	loc_A4DC
		add.w	d1,d1
		sub.w	d1,d0

loc_A4DC:
		cmpi.w	#$10,d3
		bcs.b	loc_A4EA

loc_A4E2:
		moveq	#1,d1
		rts	
; ===========================================================================

loc_A4E6:
		moveq	#0,d1
		rts	
; ===========================================================================

loc_A4EA:
		moveq	#0,d1
		move.b	$19(a0),d1
		addq.w	#4,d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.b	loc_A4E2
		cmp.w	d2,d1
		bcc.b	loc_A4E2
		moveq	#-1,d1
		rts	
; End of function item_SolidSides

; ===========================================================================
Ani_item:
	include "_anim\item.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - monitors
; ---------------------------------------------------------------------------
itempat:
	include "_maps\item.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0E - Sonic on the title screen
; ---------------------------------------------------------------------------

Obj0E:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj0E_Index(pc,d0.w),d1
		jmp	Obj0E_Index(pc,d1.w)
; ===========================================================================
Obj0E_Index:	dc.w Obj0E_Main-Obj0E_Index
		dc.w Obj0E_Delay-Obj0E_Index
		dc.w Obj0E_Move-Obj0E_Index
		dc.w Obj0E_Animate-Obj0E_Index
; ===========================================================================

Obj0E_Main:				; XREF: Obj0E_Index
		addq.b	#2,r_no0(a0)
		move.w	#$F0,8(a0)
		move.w	#$DE,$A(a0)
		move.l	#Map_obj0E,4(a0)
		move.w	#$2300,2(a0)
		move.b	#1,$18(a0)
		move.b	#29,$1F(a0)	; set time delay to 0.5	seconds
		lea	(Ani_obj0E).l,a1
		bsr.w	patchg

Obj0E_Delay:				; XREF: Obj0E_Index
		subq.b	#1,$1F(a0)	; subtract 1 from time delay
		bpl.b	Obj0E_Wait	; if time remains, branch
		addq.b	#2,r_no0(a0)	; go to	next routine
		bra.w	actionsub
; ===========================================================================

Obj0E_Wait:				; XREF: Obj0E_Delay
		rts	
; ===========================================================================

Obj0E_Move:				; XREF: Obj0E_Index
		subq.w	#8,$A(a0)
		cmpi.w	#$96,$A(a0)
		bne.b	Obj0E_Display
		addq.b	#2,r_no0(a0)

Obj0E_Display:
		bra.w	actionsub
; ===========================================================================
		rts	
; ===========================================================================

Obj0E_Animate:				; XREF: Obj0E_Index
		lea	(Ani_obj0E).l,a1
		bsr.w	patchg
		bra.w	actionsub
; ===========================================================================
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0F - "PRESS START BUTTON" and "TM" from title screen
; ---------------------------------------------------------------------------

Obj0F:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj0F_Index(pc,d0.w),d1
		jsr	Obj0F_Index(pc,d1.w)
		bra.w	actionsub
; ===========================================================================
Obj0F_Index:	dc.w Obj0F_Main-Obj0F_Index
		dc.w Obj0F_PrsStart-Obj0F_Index
		dc.w locret_A6F8-Obj0F_Index
; ===========================================================================

Obj0F_Main:				; XREF: Obj0F_Index
		addq.b	#2,r_no0(a0)
		move.w	#$D0,8(a0)
		move.w	#$130,$A(a0)
		move.l	#Map_obj0F,4(a0)
		move.w	#$200,2(a0)
		cmpi.b	#2,$1A(a0)	; is object "PRESS START"?
		bcs.b	Obj0F_PrsStart	; if yes, branch
		addq.b	#2,r_no0(a0)
		cmpi.b	#3,$1A(a0)	; is the object	"TM"?
		bne.b	locret_A6F8	; if not, branch
		move.w	#$2510,2(a0)	; "TM" specific	code
		move.w	#$170,8(a0)
		move.w	#$F8,$A(a0)

locret_A6F8:				; XREF: Obj0F_Index
		rts	
; ===========================================================================

Obj0F_PrsStart:				; XREF: Obj0F_Index
		lea	(Ani_obj0F).l,a1
		bra.w	patchg
; ===========================================================================
Ani_obj0E:
	include "_anim\obj0E.asm"

Ani_obj0F:
	include "_anim\obj0F.asm"

; ---------------------------------------------------------------------------
; Subroutine to	animate	a sprite using an animation script
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


patchg:
		moveq	#0,d0
		move.b	mstno(a0),d0	; move animation number	to d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.b	Anim_Run	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

Anim_Run:
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	Anim_Wait	; if time remains, branch
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),$1E(a0)	; load frame duration
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		bmi.b	Anim_End_FF	; if animation is complete, branch

Anim_Next:
		move.b	d0,d1
		andi.b	#$1F,d0
		move.b	d0,$1A(a0)	; load sprite number
		move.b	cddat(a0),d0
		rol.b	#3,d1
		eor.b	d0,d1
		andi.b	#3,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		addq.b	#1,$1B(a0)	; next frame number

Anim_Wait:
		rts	
; ===========================================================================

Anim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.b	Anim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.b	Anim_Next
; ===========================================================================

Anim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.b	Anim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.b	Anim_Next
; ===========================================================================

Anim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.b	Anim_End_FC	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

Anim_End_FC:
		addq.b	#1,d0		; is the end flag = $FC	?
		bne.b	Anim_End_FB	; if not, branch
		addq.b	#2,r_no0(a0)	; jump to next routine

Anim_End_FB:
		addq.b	#1,d0		; is the end flag = $FB	?
		bne.b	Anim_End_FA	; if not, branch
		move.b	#0,$1B(a0)	; reset	animation
		clr.b	r_no1(a0)		; reset	2nd routine counter

Anim_End_FA:
		addq.b	#1,d0		; is the end flag = $FA	?
		bne.b	Anim_End	; if not, branch
		addq.b	#2,r_no1(a0)	; jump to next routine

Anim_End:
		rts	
; End of function patchg

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - "PRESS START BUTTON" and "TM" from title screen
; ---------------------------------------------------------------------------
Map_obj0F:
	include "_maps\obj0F.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Sonic on the title screen
; ---------------------------------------------------------------------------
Map_obj0E:
	include "_maps\obj0E.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2B - Chopper enemy (GHZ)
; ---------------------------------------------------------------------------

fish:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fish_Index(pc,d0.w),d1
		jsr	fish_Index(pc,d1.w)
		bra.w	frameoutchk
; ===========================================================================
fish_Index:	dc.w fish_Main-fish_Index
		dc.w fish_ChgSpeed-fish_Index
; ===========================================================================

fish_Main:				; XREF: fish_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_fish,4(a0)
		move.w	#$47B,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#9,colino(a0)
		move.b	#$10,$19(a0)
		move.w	#-$700,$12(a0)	; set vertical speed
		move.w	$C(a0),$30(a0)

fish_ChgSpeed:				; XREF: fish_Index
		lea	(Ani_fish).l,a1
		bsr.w	patchg
		bsr.w	speedset2
		addi.w	#$18,$12(a0)	; reduce speed
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0
		bcc.b	fish_ChgAni
		move.w	d0,$C(a0)
		move.w	#-$700,$12(a0)	; set vertical speed

fish_ChgAni:
		move.b	#1,$1C(a0)	; use fast animation
		subi.w	#$C0,d0
		cmp.w	$C(a0),d0
		bcc.b	locret_ABB6
		move.b	#0,$1C(a0)	; use slow animation
		tst.w	$12(a0)		; is Chopper at	its highest point?
		bmi.b	locret_ABB6	; if not, branch
		move.b	#2,$1C(a0)	; use stationary animation

locret_ABB6:
		rts	
; ===========================================================================
Ani_fish:
	include "_anim\fish.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Chopper enemy (GHZ)
; ---------------------------------------------------------------------------
Map_fish:
	include "_maps\fish.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2C - Jaws enemy (LZ)
; ---------------------------------------------------------------------------

fish2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fish2_Index(pc,d0.w),d1
		jmp	fish2_Index(pc,d1.w)
; ===========================================================================
fish2_Index:	dc.w fish2_Main-fish2_Index
		dc.w fish2_Turn-fish2_Index
; ===========================================================================

fish2_Main:				; XREF: fish2_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_fish2,4(a0)
		move.w	#$2486,2(a0)
		ori.b	#4,1(a0)
		move.b	#$A,colino(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; load object subtype number
		lsl.w	#6,d0		; multiply d0 by 64
		subq.w	#1,d0
		move.w	d0,$30(a0)	; set turn delay time
		move.w	d0,$32(a0)
		move.w	#-$40,$10(a0)	; move Jaws to the left
		btst	#0,cddat(a0)	; is Jaws facing left?
		beq.b	fish2_Turn	; if yes, branch
		neg.w	$10(a0)		; move Jaws to the right

fish2_Turn:				; XREF: fish2_Index
		subq.w	#1,$30(a0)	; subtract 1 from turn delay time
		bpl.b	fish2_Animate	; if time remains, branch
		move.w	$32(a0),$30(a0)	; reset	turn delay time
		neg.w	$10(a0)		; change speed direction
		bchg	#0,cddat(a0)	; change Jaws facing direction
		move.b	#1,$1D(a0)	; reset	animation

fish2_Animate:
		lea	(Ani_fish2).l,a1
		bsr.w	patchg
		bsr.w	speedset2
		bra.w	frameoutchk
; ===========================================================================
Ani_fish2:
	include "_anim\fish2.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Jaws enemy (LZ)
; ---------------------------------------------------------------------------
Map_fish2:
	include "_maps\fish2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2D - Burrobot enemy (LZ)
; ---------------------------------------------------------------------------

mogura:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	mogura_Index(pc,d0.w),d1
		jmp	mogura_Index(pc,d1.w)
; ===========================================================================
mogura_Index:	dc.w mogura_Main-mogura_Index
		dc.w mogura_Action-mogura_Index
; ===========================================================================

mogura_Main:				; XREF: mogura_Index
		addq.b	#2,r_no0(a0)
		move.b	#$13,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_mogura,4(a0)
		move.w	#$4A6,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#5,colino(a0)
		move.b	#$C,$19(a0)
		addq.b	#6,r_no1(a0)	; run "mogura_ChkSonic" routine
		move.b	#2,$1C(a0)

mogura_Action:				; XREF: mogura_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	mogura_Index2(pc,d0.w),d1
		jsr	mogura_Index2(pc,d1.w)
		lea	(Ani_mogura).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
mogura_Index2:	dc.w mogura_ChgDir-mogura_Index2
		dc.w mogura_Move-mogura_Index2
		dc.w mogura_Jump-mogura_Index2
		dc.w mogura_ChkSonic-mogura_Index2
; ===========================================================================

mogura_ChgDir:				; XREF: mogura_Index2
		subq.w	#1,$30(a0)
		bpl.b	locret_AD42
		addq.b	#2,r_no1(a0)
		move.w	#$FF,$30(a0)
		move.w	#$80,$10(a0)
		move.b	#1,$1C(a0)
		bchg	#0,cddat(a0)	; change direction the Burrobot	is facing
		beq.b	locret_AD42
		neg.w	$10(a0)		; change direction the Burrobot	is moving

locret_AD42:
		rts	
; ===========================================================================

mogura_Move:				; XREF: mogura_Index2
		subq.w	#1,$30(a0)
		bmi.b	loc_AD84
		bsr.w	speedset2
		bchg	#0,$32(a0)
		bne.b	loc_AD78
		move.w	8(a0),d3
		addi.w	#$C,d3
		btst	#0,cddat(a0)
		bne.b	loc_AD6A
		subi.w	#$18,d3

loc_AD6A:
		jsr	emycol_d2
		cmpi.w	#$C,d1
		bge.b	loc_AD84
		rts	
; ===========================================================================

loc_AD78:				; XREF: mogura_Move
		jsr	emycol_d
		add.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_AD84:				; XREF: mogura_Move
		btst	#2,systemtimer+3
		beq.b	loc_ADA4
		subq.b	#2,r_no1(a0)
		move.w	#$3B,$30(a0)
		move.w	#0,$10(a0)
		move.b	#0,$1C(a0)
		rts	
; ===========================================================================

loc_ADA4:
		addq.b	#2,r_no1(a0)
		move.w	#-$400,$12(a0)
		move.b	#2,$1C(a0)
		rts	
; ===========================================================================

mogura_Jump:				; XREF: mogura_Index2
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		bmi.b	locret_ADF0
		move.b	#3,$1C(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_ADF0
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)
		move.b	#1,$1C(a0)
		move.w	#$FF,$30(a0)
		subq.b	#2,r_no1(a0)
		bsr.w	mogura_ChkSonic2

locret_ADF0:
		rts	
; ===========================================================================

mogura_ChkSonic:				; XREF: mogura_Index2
		move.w	#$60,d2
		bsr.w	mogura_ChkSonic2
		bcc.b	locret_AE20
		move.w	playerwk+yposi,d0
		sub.w	$C(a0),d0
		bcc.b	locret_AE20
		cmpi.w	#-$80,d0
		bcs.b	locret_AE20
		tst.w	editmode
		bne.b	locret_AE20
		subq.b	#2,r_no1(a0)
		move.w	d1,$10(a0)
		move.w	#-$400,$12(a0)

locret_AE20:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mogura_ChkSonic2:			; XREF: mogura_ChkSonic
		move.w	#$80,d1
		bset	#0,cddat(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_AE40
		neg.w	d0
		neg.w	d1
		bclr	#0,cddat(a0)

loc_AE40:
		cmp.w	d2,d0
		rts	
; End of function mogura_ChkSonic2

; ===========================================================================
Ani_mogura:
	include "_anim\mogura.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Burrobot enemy (LZ)
; ---------------------------------------------------------------------------
Map_mogura:
	include "_maps\mogura.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 2F - large moving platforms (MZ)
; ---------------------------------------------------------------------------

yuka:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yuka_Index(pc,d0.w),d1
		jmp	yuka_Index(pc,d1.w)
; ===========================================================================
yuka_Index:	dc.w yuka_Main-yuka_Index
		dc.w yuka_Action-yuka_Index

yuka_Data:	dc.w yuka_Data1-yuka_Data 	; collision angle data
		dc.b 0,	$40			; frame	number,	platform width
		dc.w yuka_Data3-yuka_Data
		dc.b 1,	$40
		dc.w yuka_Data2-yuka_Data
		dc.b 2,	$20
; ===========================================================================

yuka_Main:				; XREF: yuka_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_yuka,4(a0)
		move.w	#$C000,2(a0)
		move.b	#4,1(a0)
		move.b	#5,$18(a0)
		move.w	$C(a0),actfree(a0)
		move.w	8(a0),$2A(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#2,d0
		andi.w	#$1C,d0
		lea	yuka_Data(pc,d0.w),a1
		move.w	(a1)+,d0
		lea	yuka_Data(pc,d0.w),a2
		move.l	a2,$30(a0)
		move.b	(a1)+,$1A(a0)
		move.b	(a1),$19(a0)
		andi.b	#$F,userflag(a0)
		move.b	#$40,$16(a0)
		bset	#4,1(a0)

yuka_Action:				; XREF: yuka_Index
		bsr.w	yuka_Types
		tst.b	r_no1(a0)
		beq.b	yuka_Solid
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		bsr.w	ExitPlatform
		btst	#3,cddat(a1)
		bne.w	yuka_Slope
		clr.b	r_no1(a0)
		bra.b	yuka_Display
; ===========================================================================

yuka_Slope:				; XREF: yuka_Action
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		movea.l	$30(a0),a2
		move.w	8(a0),d2
		bsr.w	SlopeObject2
		bra.b	yuka_Display
; ===========================================================================

yuka_Solid:				; XREF: yuka_Action
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$20,d2
		cmpi.b	#2,$1A(a0)
		bne.b	loc_AF8E
		move.w	#$30,d2

loc_AF8E:
		movea.l	$30(a0),a2
		bsr.w	hitchk2F

yuka_Display:				; XREF: yuka_Action
		bsr.w	actionsub
		bra.w	yuka_ChkDel

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


yuka_Types:				; XREF: yuka_Action
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	yuka_TypeIndex(pc,d0.w),d1
		jmp	yuka_TypeIndex(pc,d1.w)
; End of function yuka_Types

; ===========================================================================
yuka_TypeIndex:dc.w yuka_Type00-yuka_TypeIndex
		dc.w yuka_Type01-yuka_TypeIndex
		dc.w yuka_Type02-yuka_TypeIndex
		dc.w yuka_Type03-yuka_TypeIndex
		dc.w yuka_Type04-yuka_TypeIndex
		dc.w yuka_Type05-yuka_TypeIndex
; ===========================================================================

yuka_Type00:				; XREF: yuka_TypeIndex
		rts			; type 00 platform doesn't move
; ===========================================================================

yuka_Type01:				; XREF: yuka_TypeIndex
		move.b	($FFFFFE60).w,d0
		move.w	#$20,d1
		bra.b	yuka_Move
; ===========================================================================

yuka_Type02:				; XREF: yuka_TypeIndex
		move.b	($FFFFFE64).w,d0
		move.w	#$30,d1
		bra.b	yuka_Move
; ===========================================================================

yuka_Type03:				; XREF: yuka_TypeIndex
		move.b	($FFFFFE68).w,d0
		move.w	#$40,d1
		bra.b	yuka_Move
; ===========================================================================

yuka_Type04:				; XREF: yuka_TypeIndex
		move.b	($FFFFFE6C).w,d0
		move.w	#$60,d1

yuka_Move:
		btst	#3,userflag(a0)
		beq.b	loc_AFF2
		neg.w	d0
		add.w	d1,d0

loc_AFF2:
		move.w	actfree(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; update position on y-axis
		rts	
; ===========================================================================

yuka_Type05:				; XREF: yuka_TypeIndex
		move.b	$34(a0),d0
		tst.b	r_no1(a0)
		bne.b	loc_B010
		subq.b	#2,d0
		bcc.b	loc_B01C
		moveq	#0,d0
		bra.b	loc_B01C
; ===========================================================================

loc_B010:
		addq.b	#4,d0
		cmpi.b	#$40,d0
		bcs.b	loc_B01C
		move.b	#$40,d0

loc_B01C:
		move.b	d0,$34(a0)
		jsr	(sinset).l
		lsr.w	#4,d0
		move.w	d0,d1
		add.w	actfree(a0),d0
		move.w	d0,$C(a0)
		cmpi.b	#$20,$34(a0)
		bne.b	loc_B07A
		tst.b	$35(a0)
		bne.b	loc_B07A
		move.b	#1,$35(a0)
		bsr.w	actwkchk2
		bne.b	loc_B07A
		move.b	#$35,0(a1)	; load sitting flame object
		move.w	8(a0),8(a1)
		move.w	actfree(a0),actfree(a1)
		addq.w	#8,actfree(a1)
		subq.w	#3,actfree(a1)
		subi.w	#$40,8(a1)
		move.l	$30(a0),$30(a1)
		move.l	a0,$38(a1)
		movea.l	a0,a2
		bsr.b	sub_B09C

loc_B07A:
		moveq	#0,d2
		lea	$36(a0),a2
		move.b	(a2)+,d2
		subq.b	#1,d2
		bcs.b	locret_B09A

loc_B086:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.w	#-$3000,d0
		movea.w	d0,a1
		move.w	d1,$3C(a1)
		dbra	d2,loc_B086

locret_B09A:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_B09C:
		lea	$36(a2),a2
		moveq	#0,d0
		move.b	(a2),d0
		addq.b	#1,(a2)
		lea	1(a2,d0.w),a2
		move.w	a1,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,(a2)
		rts	
; End of function sub_B09C

; ===========================================================================

yuka_ChkDel:				; XREF: yuka_Display
		tst.b	$35(a0)
		beq.b	loc_B0C6
		tst.b	1(a0)
		bpl.b	yuka_DelFlames

loc_B0C6:
		move.w	$2A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================

yuka_DelFlames:			; XREF: yuka_ChkDel
		moveq	#0,d2

loc_B0E8:
		lea	$36(a0),a2
		move.b	(a2),d2
		clr.b	(a2)+
		subq.b	#1,d2
		bcs.b	locret_B116

loc_B0F4:
		moveq	#0,d0
		move.b	(a2),d0
		clr.b	(a2)+
		lsl.w	#6,d0
		addi.w	#-$3000,d0
		movea.w	d0,a1
		bsr.w	frameout2
		dbra	d2,loc_B0F4
		move.b	#0,$35(a0)
		move.b	#0,$34(a0)

locret_B116:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Collision data for large moving platforms (MZ)
; ---------------------------------------------------------------------------
yuka_Data1:	incbin	misc\mz_pfm1.bin
		even
yuka_Data2:	incbin	misc\mz_pfm2.bin
		even
yuka_Data3:	incbin	misc\mz_pfm3.bin
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 35 - fireball that sits on the	floor (MZ)
; (appears when	you walk on sinking platforms)
; ---------------------------------------------------------------------------

Obj35:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj35_Index(pc,d0.w),d1
		jmp	Obj35_Index(pc,d1.w)
; ===========================================================================
Obj35_Index:	dc.w Obj35_Main-Obj35_Index
		dc.w loc_B238-Obj35_Index
		dc.w Obj35_Move-Obj35_Index
; ===========================================================================

Obj35_Main:				; XREF: Obj35_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_fire,4(a0)
		move.w	#$345,2(a0)
		move.w	8(a0),$2A(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$8B,colino(a0)
		move.b	#8,$19(a0)
		move.w	#$C8,d0
		jsr	(soundset).l ;	play flame sound
		tst.b	userflag(a0)
		beq.b	loc_B238
		addq.b	#2,r_no0(a0)
		bra.w	Obj35_Move
; ===========================================================================

loc_B238:				; XREF: Obj35_Index
		movea.l	$30(a0),a1
		move.w	8(a0),d1
		sub.w	$2A(a0),d1
		addi.w	#$C,d1
		move.w	d1,d0
		lsr.w	#1,d0
		move.b	(a1,d0.w),d0
		neg.w	d0
		add.w	actfree(a0),d0
		move.w	d0,d2
		add.w	$3C(a0),d0
		move.w	d0,$C(a0)
		cmpi.w	#$84,d1
		bcc.b	loc_B2B0
		addi.l	#$10000,8(a0)
		cmpi.w	#$80,d1
		bcc.b	loc_B2B0
		move.l	8(a0),d0
		addi.l	#$80000,d0
		andi.l	#$FFFFF,d0
		bne.b	loc_B2B0
		bsr.w	actwkchk2
		bne.b	loc_B2B0
		move.b	#$35,0(a1)
		move.w	8(a0),8(a1)
		move.w	d2,actfree(a1)
		move.w	$3C(a0),$3C(a1)
		move.b	#1,userflag(a1)
		movea.l	$38(a0),a2
		bsr.w	sub_B09C

loc_B2B0:
		bra.b	Obj35_Animate
; ===========================================================================

Obj35_Move:				; XREF: Obj35_Index
		move.w	actfree(a0),d0
		add.w	$3C(a0),d0
		move.w	d0,$C(a0)

Obj35_Animate:				; XREF: loc_B238
		lea	(Ani_obj35).l,a1
		bsr.w	patchg
		bra.w	actionsub
; ===========================================================================
Ani_obj35:
	include "_anim\obj35.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - large moving platforms (MZ)
; ---------------------------------------------------------------------------
Map_yuka:
	include "_maps\yuka.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - lava balls (MZ, SLZ)
; ---------------------------------------------------------------------------
Map_fire:
	include "_maps\fire.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 30 - large green glassy blocks	(MZ)
; ---------------------------------------------------------------------------

ochi:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	ochi_Index(pc,d0.w),d1
		jsr	ochi_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	ochi_Delete
		bra.w	actionsub
; ===========================================================================

ochi_Delete:
		bra.w	frameout
; ===========================================================================
ochi_Index:	dc.w ochi_Main-ochi_Index
		dc.w ochi_Block012-ochi_Index
		dc.w ochi_Reflect012-ochi_Index
		dc.w ochi_Block34-ochi_Index
		dc.w ochi_Reflect34-ochi_Index

ochi_Vars1:	dc.b 2,	0, 0	; routine num, y-axis dist from	origin,	frame num
		dc.b 4,	0, 1
ochi_Vars2:	dc.b 6,	0, 2
		dc.b 8,	0, 1
; ===========================================================================

ochi_Main:				; XREF: ochi_Index
		lea	(ochi_Vars1).l,a2
		moveq	#1,d1
		move.b	#$48,$16(a0)
		cmpi.b	#3,userflag(a0)	; is object type 0/1/2 ?
		bcs.b	loc_B40C	; if yes, branch
		lea	(ochi_Vars2).l,a2
		moveq	#1,d1
		move.b	#$38,$16(a0)

loc_B40C:
		movea.l	a0,a1
		bra.b	ochi_Load	; load main object
; ===========================================================================

ochi_Loop:
		bsr.w	actwkchk2
		bne.b	loc_B480

ochi_Load:				; XREF: ochi_Main
		move.b	(a2)+,r_no0(a1)
		move.b	#$30,0(a1)
		move.w	8(a0),8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		move.l	#Map_ochi,4(a1)
		move.w	#$C38E,2(a1)
		move.b	#4,1(a1)
		move.w	$C(a1),$30(a1)
		move.b	userflag(a0),userflag(a1)
		move.b	#$20,$19(a1)
		move.b	#4,$18(a1)
		move.b	(a2)+,$1A(a1)
		move.l	a0,$3C(a1)
		dbra	d1,ochi_Loop	; repeat once to load "reflection object"

		move.b	#$10,$19(a1)
		move.b	#3,$18(a1)
		addq.b	#8,userflag(a1)
		andi.b	#$F,userflag(a1)

loc_B480:
		move.w	#$90,$32(a0)
		bset	#4,1(a0)

ochi_Block012:				; XREF: ochi_Index
		bsr.w	ochi_Types
		move.w	#$2B,d1
		move.w	#$48,d2
		move.w	#$49,d3
		move.w	8(a0),d4
		bra.w	hitchk
; ===========================================================================

ochi_Reflect012:			; XREF: ochi_Index
		movea.l	$3C(a0),a1
		move.w	$32(a1),$32(a0)
		bra.w	ochi_Types
; ===========================================================================

ochi_Block34:				; XREF: ochi_Index
		bsr.w	ochi_Types
		move.w	#$2B,d1
		move.w	#$38,d2
		move.w	#$39,d3
		move.w	8(a0),d4
		bra.w	hitchk
; ===========================================================================

ochi_Reflect34:			; XREF: ochi_Index
		movea.l	$3C(a0),a1
		move.w	$32(a1),$32(a0)
		move.w	$C(a1),$30(a0)
		bra.w	*+4

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ochi_Types:				; XREF: ochi_Block012; et al
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	ochi_TypeIndex(pc,d0.w),d1
		jmp	ochi_TypeIndex(pc,d1.w)
; End of function ochi_Types

; ===========================================================================
ochi_TypeIndex:dc.w ochi_Type00-ochi_TypeIndex
		dc.w ochi_Type01-ochi_TypeIndex
		dc.w ochi_Type02-ochi_TypeIndex
		dc.w ochi_Type03-ochi_TypeIndex
		dc.w ochi_Type04-ochi_TypeIndex
; ===========================================================================

ochi_Type00:				; XREF: ochi_TypeIndex
		rts	
; ===========================================================================

ochi_Type01:				; XREF: ochi_TypeIndex
		move.b	($FFFFFE70).w,d0
		move.w	#$40,d1
		bra.b	loc_B514
; ===========================================================================

ochi_Type02:				; XREF: ochi_TypeIndex
		move.b	($FFFFFE70).w,d0
		move.w	#$40,d1
		neg.w	d0
		add.w	d1,d0

loc_B514:				; XREF: ochi_Type01
		btst	#3,userflag(a0)
		beq.b	loc_B526
		neg.w	d0
		add.w	d1,d0
		lsr.b	#1,d0
		addi.w	#$20,d0

loc_B526:
		bra.w	loc_B5EE
; ===========================================================================

ochi_Type03:				; XREF: ochi_TypeIndex
		btst	#3,userflag(a0)
		beq.b	loc_B53E
		move.b	($FFFFFE70).w,d0
		subi.w	#$10,d0
		bra.w	loc_B5EE
; ===========================================================================

loc_B53E:
		btst	#3,cddat(a0)
		bne.b	loc_B54E
		bclr	#0,$34(a0)
		bra.b	loc_B582
; ===========================================================================

loc_B54E:
		tst.b	$34(a0)
		bne.b	loc_B582
		move.b	#1,$34(a0)
		bset	#0,$35(a0)
		beq.b	loc_B582
		bset	#7,$34(a0)
		move.w	#$10,$36(a0)
		move.b	#$A,$38(a0)
		cmpi.w	#$40,$32(a0)
		bne.b	loc_B582
		move.w	#$40,$36(a0)

loc_B582:
		tst.b	$34(a0)
		bpl.b	loc_B5AA
		tst.b	$38(a0)
		beq.b	loc_B594
		subq.b	#1,$38(a0)
		bne.b	loc_B5AA

loc_B594:
		tst.w	$32(a0)
		beq.b	loc_B5A4
		subq.w	#1,$32(a0)
		subq.w	#1,$36(a0)
		bne.b	loc_B5AA

loc_B5A4:
		bclr	#7,$34(a0)

loc_B5AA:
		move.w	$32(a0),d0
		bra.b	loc_B5EE
; ===========================================================================

ochi_Type04:				; XREF: ochi_TypeIndex
		btst	#3,userflag(a0)
		beq.b	ochi_ChkSwitch
		move.b	($FFFFFE70).w,d0
		subi.w	#$10,d0
		bra.b	loc_B5EE
; ===========================================================================

ochi_ChkSwitch:			; XREF: ochi_Type04
		tst.b	$34(a0)
		bne.b	loc_B5E0
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	userflag(a0),d0	; load object type number
		lsr.w	#4,d0		; read only the	first nybble
		tst.b	(a2,d0.w)	; has switch number d0 been pressed?
		beq.b	loc_B5EA	; if not, branch
		move.b	#1,$34(a0)

loc_B5E0:
		tst.w	$32(a0)
		beq.b	loc_B5EA
		subq.w	#2,$32(a0)

loc_B5EA:
		move.w	$32(a0),d0

loc_B5EE:
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - large green	glassy blocks (MZ)
; ---------------------------------------------------------------------------
Map_ochi:
	include "_maps\ochi.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 31 - stomping metal blocks on chains (MZ)
; ---------------------------------------------------------------------------

turi:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	turi_Index(pc,d0.w),d1
		jmp	turi_Index(pc,d1.w)
; ===========================================================================
turi_Index:	dc.w turi_Main-turi_Index
		dc.w loc_B798-turi_Index
		dc.w loc_B7FE-turi_Index
		dc.w turi_Display2-turi_Index
		dc.w loc_B7E2-turi_Index

turi_SwchNums:	dc.b 0,	0		; switch number, obj number
		dc.b 1,	0

turi_Var:	dc.b 2,	0, 0		; XREF: ROM:0000B6E0o
		dc.b 4,	$1C, 1		; routine number, y-position, frame number
		dc.b 8,	$CC, 3
		dc.b 6,	$F0, 2

word_B6A4:	dc.w $7000, $A000
		dc.w $5000, $7800
		dc.w $3800, $5800
		dc.w $B800
; ===========================================================================

turi_Main:				; XREF: turi_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		bpl.b	loc_B6CE
		andi.w	#$7F,d0
		add.w	d0,d0
		lea	turi_SwchNums(pc,d0.w),a2
		move.b	(a2)+,$3A(a0)
		move.b	(a2)+,d0
		move.b	d0,userflag(a0)

loc_B6CE:
		andi.b	#$F,d0
		add.w	d0,d0
		move.w	word_B6A4(pc,d0.w),d2
		tst.w	d0
		bne.b	loc_B6E0
		move.w	d2,$32(a0)

loc_B6E0:
		lea	(turi_Var).l,a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	turi_MakeStomper
; ===========================================================================

turi_Loop:
		bsr.w	actwkchk2
		bne.w	turi_SetSize

turi_MakeStomper:			; XREF: turi_Main
		move.b	(a2)+,r_no0(a1)
		move.b	#$31,0(a1)
		move.w	8(a0),8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		move.l	#Map_turi,4(a1)
		move.w	#$300,2(a1)
		move.b	#4,1(a1)
		move.w	$C(a1),$30(a1)
		move.b	userflag(a0),userflag(a1)
		move.b	#$10,$19(a1)
		move.w	d2,$34(a1)
		move.b	#4,$18(a1)
		move.b	(a2)+,$1A(a1)
		cmpi.b	#1,$1A(a1)
		bne.b	loc_B76A
		subq.w	#1,d1
		move.b	userflag(a0),d0
		andi.w	#$F0,d0
		cmpi.w	#$20,d0
		beq.b	turi_MakeStomper
		move.b	#$38,$19(a1)
		move.b	#$90,colino(a1)
		addq.w	#1,d1

loc_B76A:
		move.l	a0,$3C(a1)
		dbra	d1,turi_Loop

		move.b	#3,$18(a1)

turi_SetSize:
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#3,d0
		andi.b	#$E,d0
		lea	turi_Var2(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		bra.b	loc_B798
; ===========================================================================
turi_Var2:	dc.b $38, 0		; width, frame number
		dc.b $30, 9
		dc.b $10, $A
; ===========================================================================

loc_B798:				; XREF: turi_Index
		bsr.w	turi_Types
		move.w	$C(a0),($FFFFF7A4).w
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$C,d2
		move.w	#$D,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#3,cddat(a0)
		beq.b	turi_Display
		cmpi.b	#$10,$32(a0)
		bcc.b	turi_Display
		movea.l	a0,a2
		lea	playerwk,a0
		jsr	playdieset
		movea.l	a2,a0

turi_Display:
		bsr.w	actionsub
		bra.w	turi_ChkDel
; ===========================================================================

loc_B7E2:				; XREF: turi_Index
		move.b	#$80,$16(a0)
		bset	#4,1(a0)
		movea.l	$3C(a0),a1
		move.b	$32(a1),d0
		lsr.b	#5,d0
		addq.b	#3,d0
		move.b	d0,$1A(a0)

loc_B7FE:				; XREF: turi_Index
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$32(a1),d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)

turi_Display2:				; XREF: turi_Index
		bsr.w	actionsub

turi_ChkDel:				; XREF: turi_Display
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================

turi_Types:				; XREF: loc_B798
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	turi_TypeIndex(pc,d0.w),d1
		jmp	turi_TypeIndex(pc,d1.w)
; ===========================================================================
turi_TypeIndex:dc.w turi_Type00-turi_TypeIndex
		dc.w turi_Type01-turi_TypeIndex
		dc.w turi_Type01-turi_TypeIndex
		dc.w turi_Type03-turi_TypeIndex
		dc.w turi_Type01-turi_TypeIndex
		dc.w turi_Type03-turi_TypeIndex
		dc.w turi_Type01-turi_TypeIndex
; ===========================================================================

turi_Type00:				; XREF: turi_TypeIndex
		lea	($FFFFF7E0).w,a2 ; load	switch statuses
		moveq	#0,d0
		move.b	$3A(a0),d0	; move number 0	or 1 to	d0
		tst.b	(a2,d0.w)	; has switch (d0) been pressed?
		beq.b	loc_B8A8	; if not, branch
		tst.w	($FFFFF7A4).w
		bpl.b	loc_B872
		cmpi.b	#$10,$32(a0)
		beq.b	loc_B8A0

loc_B872:
		tst.w	$32(a0)
		beq.b	loc_B8A0
		move.b	systemtimer+3,d0
		andi.b	#$F,d0
		bne.b	loc_B892
		tst.b	1(a0)
		bpl.b	loc_B892
		move.w	#$C7,d0
		jsr	(soundset).l ;	play rising chain sound

loc_B892:
		subi.w	#$80,$32(a0)
		bcc.b	turi_Restart
		move.w	#0,$32(a0)

loc_B8A0:
		move.w	#0,$12(a0)
		bra.b	turi_Restart
; ===========================================================================

loc_B8A8:				; XREF: turi_Type00
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.b	turi_Restart
		move.w	$12(a0),d0
		addi.w	#$70,$12(a0)	; make object fall
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.b	turi_Restart
		move.w	d1,$32(a0)
		move.w	#0,$12(a0)	; stop object falling
		tst.b	1(a0)
		bpl.b	turi_Restart
		move.w	#$BD,d0
		jsr	(soundset).l ;	play stomping sound

turi_Restart:
		moveq	#0,d0
		move.b	$32(a0),d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		rts	
; ===========================================================================

turi_Type01:				; XREF: turi_TypeIndex
		tst.w	$36(a0)
		beq.b	loc_B938
		tst.w	$38(a0)
		beq.b	loc_B902
		subq.w	#1,$38(a0)
		bra.b	loc_B97C
; ===========================================================================

loc_B902:
		move.b	systemtimer+3,d0
		andi.b	#$F,d0
		bne.b	loc_B91C
		tst.b	1(a0)
		bpl.b	loc_B91C
		move.w	#$C7,d0
		jsr	(soundset).l ;	play rising chain sound

loc_B91C:
		subi.w	#$80,$32(a0)
		bcc.b	loc_B97C
		move.w	#0,$32(a0)
		move.w	#0,$12(a0)
		move.w	#0,$36(a0)
		bra.b	loc_B97C
; ===========================================================================

loc_B938:				; XREF: turi_Type01
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.b	loc_B97C
		move.w	$12(a0),d0
		addi.w	#$70,$12(a0)	; make object fall
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.b	loc_B97C
		move.w	d1,$32(a0)
		move.w	#0,$12(a0)	; stop object falling
		move.w	#1,$36(a0)
		move.w	#$3C,$38(a0)
		tst.b	1(a0)
		bpl.b	loc_B97C
		move.w	#$BD,d0
		jsr	(soundset).l ;	play stomping sound

loc_B97C:
		bra.w	turi_Restart
; ===========================================================================

turi_Type03:				; XREF: turi_TypeIndex
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_B98C
		neg.w	d0

loc_B98C:
		cmpi.w	#$90,d0
		bcc.b	loc_B996
		addq.b	#1,userflag(a0)

loc_B996:
		bra.w	turi_Restart
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 45 - spiked metal block from beta version (MZ)
; ---------------------------------------------------------------------------

Obj45:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj45_Index(pc,d0.w),d1
		jmp	Obj45_Index(pc,d1.w)
; ===========================================================================
Obj45_Index:	dc.w Obj45_Main-Obj45_Index
		dc.w Obj45_Solid-Obj45_Index
		dc.w loc_BA8E-Obj45_Index
		dc.w Obj45_Display-Obj45_Index
		dc.w loc_BA7A-Obj45_Index

Obj45_Var:	dc.b	2,   4,	  0	; routine number, x-position, frame number
		dc.b	4, $E4,	  1
		dc.b	8, $34,	  3
		dc.b	6, $28,	  2

word_B9BE:	dc.w $3800
		dc.w -$6000
		dc.w $5000
; ===========================================================================

Obj45_Main:				; XREF: Obj45_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	word_B9BE(pc,d0.w),d2
		lea	(Obj45_Var).l,a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	Obj45_Load
; ===========================================================================

Obj45_Loop:
		bsr.w	actwkchk2
		bne.b	loc_BA52

Obj45_Load:				; XREF: Obj45_Main
		move.b	(a2)+,r_no0(a1)
		move.b	#$45,0(a1)
		move.w	$C(a0),$C(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	8(a0),d0
		move.w	d0,8(a1)
		move.l	#Map_obj45,4(a1)
		move.w	#$300,2(a1)
		move.b	#4,1(a1)
		move.w	8(a1),$30(a1)
		move.w	8(a0),$3A(a1)
		move.b	userflag(a0),userflag(a1)
		move.b	#$20,$19(a1)
		move.w	d2,$34(a1)
		move.b	#4,$18(a1)
		cmpi.b	#1,(a2)
		bne.b	loc_BA40
		move.b	#$91,colino(a1)

loc_BA40:
		move.b	(a2)+,$1A(a1)
		move.l	a0,$3C(a1)
		dbra	d1,Obj45_Loop	; repeat 3 times

		move.b	#3,$18(a1)

loc_BA52:
		move.b	#$10,$19(a0)

Obj45_Solid:				; XREF: Obj45_Index
		move.w	8(a0),-(sp)
		bsr.w	Obj45_Move
		move.w	#$17,d1
		move.w	#$20,d2
		move.w	#$20,d3
		move.w	(sp)+,d4
		bsr.w	hitchk
		bsr.w	actionsub
		bra.w	Obj45_ChkDel
; ===========================================================================

loc_BA7A:				; XREF: Obj45_Index
		movea.l	$3C(a0),a1
		move.b	$32(a1),d0
		addi.b	#$10,d0
		lsr.b	#5,d0
		addq.b	#3,d0
		move.b	d0,$1A(a0)

loc_BA8E:				; XREF: Obj45_Index
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$32(a1),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)

Obj45_Display:				; XREF: Obj45_Index
		bsr.w	actionsub

Obj45_ChkDel:				; XREF: Obj45_Solid
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj45_Move:				; XREF: Obj45_Solid
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	off_BAD6(pc,d0.w),d1
		jmp	off_BAD6(pc,d1.w)
; End of function Obj45_Move

; ===========================================================================
off_BAD6:	dc.w loc_BADA-off_BAD6
		dc.w loc_BADA-off_BAD6
; ===========================================================================

loc_BADA:				; XREF: off_BAD6
		tst.w	$36(a0)
		beq.b	loc_BB08
		tst.w	$38(a0)
		beq.b	loc_BAEC
		subq.w	#1,$38(a0)
		bra.b	loc_BB3C
; ===========================================================================

loc_BAEC:
		subi.w	#$80,$32(a0)
		bcc.b	loc_BB3C
		move.w	#0,$32(a0)
		move.w	#0,$10(a0)
		move.w	#0,$36(a0)
		bra.b	loc_BB3C
; ===========================================================================

loc_BB08:				; XREF: loc_BADA
		move.w	$34(a0),d1
		cmp.w	$32(a0),d1
		beq.b	loc_BB3C
		move.w	$10(a0),d0
		addi.w	#$70,$10(a0)
		add.w	d0,$32(a0)
		cmp.w	$32(a0),d1
		bhi.b	loc_BB3C
		move.w	d1,$32(a0)
		move.w	#0,$10(a0)
		move.w	#1,$36(a0)
		move.w	#$3C,$38(a0)

loc_BB3C:
		moveq	#0,d0
		move.b	$32(a0),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - metal stomping blocks on chains (MZ)
; ---------------------------------------------------------------------------
Map_turi:
	include "_maps\turi.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - spiked metal block from beta version (MZ)
; ---------------------------------------------------------------------------
Map_obj45:
	include "_maps\obj45.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 32 - switches (MZ, SYZ, LZ, SBZ)
; ---------------------------------------------------------------------------

switch2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	switch2_Index(pc,d0.w),d1
		jmp	switch2_Index(pc,d1.w)
; ===========================================================================
switch2_Index:	dc.w switch2_Main-switch2_Index
		dc.w switch2_Pressed-switch2_Index
; ===========================================================================

switch2_Main:				; XREF: switch2_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_switch2,4(a0)
		move.w	#$4513,2(a0)	; MZ specific code
		cmpi.b	#2,stageno
		beq.b	loc_BD60
		move.w	#$513,2(a0)	; SYZ, LZ and SBZ specific code

loc_BD60:
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		addq.w	#3,$C(a0)

switch2_Pressed:				; XREF: switch2_Index
		tst.b	1(a0)
		bpl.b	switch2_Display
		move.w	#$1B,d1
		move.w	#5,d2
		move.w	#5,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		bclr	#0,$1A(a0)	; use "unpressed" frame
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		lea	($FFFFF7E0).w,a3
		lea	(a3,d0.w),a3
		moveq	#0,d3
		btst	#6,userflag(a0)
		beq.b	loc_BDB2
		moveq	#7,d3

loc_BDB2:
		tst.b	userflag(a0)
		bpl.b	loc_BDBE
		bsr.w	switch2_MZBlock
		bne.b	loc_BDC8

loc_BDBE:
		tst.b	r_no1(a0)
		bne.b	loc_BDC8
		bclr	d3,(a3)
		bra.b	loc_BDDE
; ===========================================================================

loc_BDC8:
		tst.b	(a3)
		bne.b	loc_BDD6
		move.w	#$CD,d0
		jsr	(soundset).l ;	play switch sound

loc_BDD6:
		bset	d3,(a3)
		bset	#0,$1A(a0)	; use "pressed"	frame

loc_BDDE:
		btst	#5,userflag(a0)
		beq.b	switch2_Display
		subq.b	#1,$1E(a0)
		bpl.b	switch2_Display
		move.b	#7,$1E(a0)
		bchg	#1,$1A(a0)

switch2_Display:
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	switch2_Delete
		rts	
; ===========================================================================

switch2_Delete:
		bsr.w	frameout
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


switch2_MZBlock:				; XREF: switch2_Pressed
		move.w	d3,-(sp)
		move.w	8(a0),d2
		move.w	$C(a0),d3
		subi.w	#$10,d2
		subq.w	#8,d3
		move.w	#$20,d4
		move.w	#$10,d5
		lea	($FFFFD800).w,a1 ; begin checking object RAM
		move.w	#$5F,d6

switch2_MZLoop:
		tst.b	1(a1)
		bpl.b	loc_BE4E
		cmpi.b	#$33,(a1)	; is the object	a green	MZ block?
		beq.b	loc_BE5E	; if yes, branch

loc_BE4E:
		lea	$40(a1),a1	; check	next object
		dbra	d6,switch2_MZLoop	; repeat $5F times

		move.w	(sp)+,d3
		moveq	#0,d0

locret_BE5A:
		rts	
; ===========================================================================
switch2_MZData:	dc.b $10, $10
; ===========================================================================

loc_BE5E:				; XREF: switch2_MZBlock
		moveq	#1,d0
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	switch2_MZData-2(pc,d0.w),a2
		move.b	(a2)+,d1
		ext.w	d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.b	loc_BE80
		add.w	d1,d1
		add.w	d1,d0
		bcs.b	loc_BE84
		bra.b	loc_BE4E
; ===========================================================================

loc_BE80:
		cmp.w	d4,d0
		bhi.b	loc_BE4E

loc_BE84:
		move.b	(a2)+,d1
		ext.w	d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.b	loc_BE9A
		add.w	d1,d1
		add.w	d1,d0
		bcs.b	loc_BE9E
		bra.b	loc_BE4E
; ===========================================================================

loc_BE9A:
		cmp.w	d5,d0
		bhi.b	loc_BE4E

loc_BE9E:
		move.w	(sp)+,d3
		moveq	#1,d0
		rts	
; End of function switch2_MZBlock

; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - switches (MZ, SYZ, LZ, SBZ)
; ---------------------------------------------------------------------------
Map_switch2:
	include "_maps\switch2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 33 - pushable blocks (MZ, LZ)
; ---------------------------------------------------------------------------

box:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	box_Index(pc,d0.w),d1
		jmp	box_Index(pc,d1.w)
; ===========================================================================
box_Index:	dc.w box_Main-box_Index
		dc.w loc_BF6E-box_Index
		dc.w loc_C02C-box_Index

box_Var:	dc.b $10, 0	; object width,	frame number
		dc.b $40, 1
; ===========================================================================

box_Main:				; XREF: box_Index
		addq.b	#2,r_no0(a0)
		move.b	#$F,$16(a0)
		move.b	#$F,$17(a0)
		move.l	#Map_box,4(a0)
		move.w	#$42B8,2(a0)	; MZ specific code
		cmpi.b	#1,stageno
		bne.b	loc_BF16
		move.w	#$43DE,2(a0)	; LZ specific code

loc_BF16:
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.w	8(a0),$34(a0)
		move.w	$C(a0),$36(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		andi.w	#$E,d0
		lea	box_Var(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		tst.b	userflag(a0)
		beq.b	box_ChkGone
		move.w	#$C2B8,2(a0)

box_ChkGone:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_BF6E
		bclr	#7,2(a2,d0.w)
		bset	#0,2(a2,d0.w)
		bne.w	frameout

loc_BF6E:				; XREF: box_Index
		tst.b	$32(a0)
		bne.w	loc_C046
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	loc_C186
		cmpi.w	#$200,stageno ; is the level MZ act 1?
		bne.b	loc_BFC6	; if not, branch
		bclr	#7,userflag(a0)
		move.w	8(a0),d0
		cmpi.w	#$A20,d0
		bcs.b	loc_BFC6
		cmpi.w	#$AA1,d0
		bcc.b	loc_BFC6
		move.w	($FFFFF7A4).w,d0
		subi.w	#$1C,d0
		move.w	d0,$C(a0)
		bset	#7,($FFFFF7A4).w
		bset	#7,userflag(a0)

loc_BFC6:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	loc_BFE6
		bra.w	actionsub
; ===========================================================================

loc_BFE6:
		move.w	$34(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	loc_C016
		move.w	$34(a0),8(a0)
		move.w	$36(a0),$C(a0)
		move.b	#4,r_no0(a0)
		bra.b	loc_C02C
; ===========================================================================

loc_C016:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_C028
		bclr	#0,2(a2,d0.w)

loc_C028:
		bra.w	frameout
; ===========================================================================

loc_C02C:				; XREF: box_Index
		bsr.w	ChkObjOnScreen2
		beq.b	locret_C044
		move.b	#2,r_no0(a0)
		clr.b	$32(a0)
		clr.w	$10(a0)
		clr.w	$12(a0)

locret_C044:
		rts	
; ===========================================================================

loc_C046:				; XREF: loc_BF6E
		move.w	8(a0),-(sp)
		cmpi.b	#4,r_no1(a0)
		bcc.b	loc_C056
		bsr.w	speedset2

loc_C056:
		btst	#1,cddat(a0)
		beq.b	loc_C0A0
		addi.w	#$18,$12(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.w	loc_C09E
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		bclr	#1,cddat(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		bcs.b	loc_C09E
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,$10(a0)
		move.b	#1,$32(a0)
		clr.w	$E(a0)

loc_C09E:
		bra.b	loc_C0E6
; ===========================================================================

loc_C0A0:
		tst.w	$10(a0)
		beq.w	loc_C0D6
		bmi.b	loc_C0BC
		moveq	#0,d3
		move.b	$19(a0),d3
		jsr	ObjHitWallRight
		tst.w	d1		; has block touched a wall?
		bmi.b	box_StopPush	; if yes, branch
		bra.b	loc_C0E6
; ===========================================================================

loc_C0BC:
		moveq	#0,d3
		move.b	$19(a0),d3
		not.w	d3
		jsr	ObjHitWallLeft
		tst.w	d1		; has block touched a wall?
		bmi.b	box_StopPush	; if yes, branch
		bra.b	loc_C0E6
; ===========================================================================

box_StopPush:
		clr.w	$10(a0)		; stop block moving
		bra.b	loc_C0E6
; ===========================================================================

loc_C0D6:
		addi.l	#$2001,$C(a0)
		cmpi.b	#-$60,$F(a0)
		bcc.b	loc_C104

loc_C0E6:
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	(sp)+,d4
		bsr.w	loc_C186
		bsr.b	box_ChkLava
		bra.w	loc_BFC6
; ===========================================================================

loc_C104:
		move.w	(sp)+,d4
		lea	playerwk,a1
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		bra.w	loc_BFE6
; ===========================================================================

box_ChkLava:
		cmpi.w	#$201,stageno ; is the level MZ act 2?
		bne.b	box_ChkLava2	; if not, branch
		move.w	#-$20,d2
		cmpi.w	#$DD0,8(a0)
		beq.b	box_LoadLava
		cmpi.w	#$CC0,8(a0)
		beq.b	box_LoadLava
		cmpi.w	#$BA0,8(a0)
		beq.b	box_LoadLava
		rts	
; ===========================================================================

box_ChkLava2:
		cmpi.w	#$202,stageno ; is the level MZ act 3?
		bne.b	box_NoLava	; if not, branch
		move.w	#$20,d2
		cmpi.w	#$560,8(a0)
		beq.b	box_LoadLava
		cmpi.w	#$5C0,8(a0)
		beq.b	box_LoadLava

box_NoLava:
		rts	
; ===========================================================================

box_LoadLava:
		bsr.w	actwkchk
		bne.b	locret_C184
		move.b	#$4C,0(a1)	; load lava geyser object
		move.w	8(a0),8(a1)
		add.w	d2,8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$10,$C(a1)
		move.l	a0,$3C(a1)

locret_C184:
		rts	
; ===========================================================================

loc_C186:				; XREF: loc_BF6E
		move.b	r_no1(a0),d0
		beq.w	loc_C218
		subq.b	#2,d0
		bne.b	loc_C1AA
		bsr.w	ExitPlatform
		btst	#3,cddat(a1)
		bne.b	loc_C1A4
		clr.b	r_no1(a0)
		rts	
; ===========================================================================

loc_C1A4:
		move.w	d4,d2
		bra.w	MvSonicOnPtfm
; ===========================================================================

loc_C1AA:
		subq.b	#2,d0
		bne.b	loc_C1F2
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		jsr	emycol_d
		tst.w	d1
		bpl.w	locret_C1F0
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		clr.b	r_no1(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$16A,d0
		bcs.b	locret_C1F0
		move.w	$30(a0),d0
		asr.w	#3,d0
		move.w	d0,$10(a0)
		move.b	#1,$32(a0)
		clr.w	$E(a0)

locret_C1F0:
		rts	
; ===========================================================================

loc_C1F2:
		bsr.w	speedset2
		move.w	8(a0),d0
		andi.w	#$C,d0
		bne.w	locret_C2E4
		andi.w	#-$10,8(a0)
		move.w	$10(a0),$30(a0)
		clr.w	$10(a0)
		subq.b	#2,r_no1(a0)
		rts	
; ===========================================================================

loc_C218:
		bsr.w	loc_FAC8
		tst.w	d4
		beq.w	locret_C2E4
		bmi.w	locret_C2E4
		tst.b	$32(a0)
		beq.b	loc_C230
		bra.w	locret_C2E4
; ===========================================================================

loc_C230:
		tst.w	d0
		beq.w	locret_C2E4
		bmi.b	loc_C268
		btst	#0,cddat(a1)
		bne.w	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	$19(a0),d3
		jsr	ObjHitWallRight
		move.w	(sp)+,d0
		tst.w	d1
		bmi.w	locret_C2E4
		addi.l	#$10000,8(a0)
		moveq	#1,d0
		move.w	#$40,d1
		bra.b	loc_C294
; ===========================================================================

loc_C268:
		btst	#0,cddat(a1)
		beq.b	locret_C2E4
		move.w	d0,-(sp)
		moveq	#0,d3
		move.b	$19(a0),d3
		not.w	d3
		jsr	ObjHitWallLeft
		move.w	(sp)+,d0
		tst.w	d1
		bmi.b	locret_C2E4
		subi.l	#$10000,8(a0)
		moveq	#-1,d0
		move.w	#-$40,d1

loc_C294:
		lea	playerwk,a1
		add.w	d0,8(a1)
		move.w	d1,$14(a1)
		move.w	#0,$10(a1)
		move.w	d0,-(sp)
		move.w	#$A7,d0
		jsr	(soundset).l ;	play pushing sound
		move.w	(sp)+,d0
		tst.b	userflag(a0)
		bmi.b	locret_C2E4
		move.w	d0,-(sp)
		jsr	emycol_d
		move.w	(sp)+,d0
		cmpi.w	#4,d1
		ble.b	loc_C2E0
		move.w	#$400,$10(a0)
		tst.w	d0
		bpl.b	loc_C2D8
		neg.w	$10(a0)

loc_C2D8:
		move.b	#6,r_no1(a0)
		bra.b	locret_C2E4
; ===========================================================================

loc_C2E0:
		add.w	d1,$C(a0)

locret_C2E4:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - pushable blocks (MZ, LZ)
; ---------------------------------------------------------------------------
Map_box:
	include "_maps\box.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 34 - zone title cards
; ---------------------------------------------------------------------------

Obj34:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj34_Index(pc,d0.w),d1
		jmp	Obj34_Index(pc,d1.w)
; ===========================================================================
Obj34_Index:	dc.w Obj34_CheckSBZ3-Obj34_Index
		dc.w Obj34_ChkPos-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
		dc.w Obj34_Wait-Obj34_Index
; ===========================================================================

Obj34_CheckSBZ3:			; XREF: Obj34_Index
		movea.l	a0,a1
		moveq	#0,d0
		move.b	stageno,d0
		cmpi.w	#$103,stageno ; check if level is	SBZ 3
		bne.b	Obj34_CheckFZ
		moveq	#5,d0		; load title card number 5 (SBZ)

Obj34_CheckFZ:
		move.w	d0,d2
		cmpi.w	#$502,stageno ; check if level is	FZ
		bne.b	Obj34_LoadConfig
		moveq	#6,d0		; load title card number 6 (FZ)
		moveq	#$B,d2		; use "FINAL" mappings

Obj34_LoadConfig:
		lea	(Obj34_ConData).l,a3
		lsl.w	#4,d0
		adda.w	d0,a3
		lea	(Obj34_ItemData).l,a2
		moveq	#3,d1

Obj34_Loop:
		move.b	#$34,0(a1)
		move.w	(a3),8(a1)	; load start x-position
		move.w	(a3)+,$32(a1)	; load finish x-position (same as start)
		move.w	(a3)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,d0
		bne.b	Obj34_ActNumber
		move.b	d2,d0

Obj34_ActNumber:
		cmpi.b	#7,d0
		bne.b	Obj34_MakeSprite
		add.b	stageno+1,d0
		cmpi.b	#3,stageno+1
		bne.b	Obj34_MakeSprite
		subq.b	#1,d0

Obj34_MakeSprite:
		move.b	d0,$1A(a1)	; display frame	number d0
		move.l	#Map_obj34,4(a1)
		move.w	#$8580,2(a1)
		move.b	#$78,$19(a1)
		move.b	#0,1(a1)
		move.b	#0,$18(a1)
		move.w	#60,$1E(a1)	; set time delay to 1 second
		lea	$40(a1),a1	; next object
		dbra	d1,Obj34_Loop	; repeat sequence another 3 times

Obj34_ChkPos:				; XREF: Obj34_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached the target position?
		beq.b	loc_C3C8	; if yes, branch
		bge.b	Obj34_Move
		neg.w	d1

Obj34_Move:
		add.w	d1,8(a0)	; change item's position

loc_C3C8:
		move.w	8(a0),d0
		bmi.b	locret_C3D8
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.b	locret_C3D8	; if yes, branch
		bra.w	actionsub
; ===========================================================================

locret_C3D8:
		rts	
; ===========================================================================

Obj34_Wait:				; XREF: Obj34_Index
		tst.w	$1E(a0)		; is time remaining zero?
		beq.b	Obj34_ChkPos2	; if yes, branch
		subq.w	#1,$1E(a0)	; subtract 1 from time
		bra.w	actionsub
; ===========================================================================

Obj34_ChkPos2:				; XREF: Obj34_Wait
		tst.b	1(a0)
		bpl.b	Obj34_ChangeArt
		moveq	#$20,d1
		move.w	$32(a0),d0
		cmp.w	8(a0),d0	; has item reached the finish position?
		beq.b	Obj34_ChangeArt	; if yes, branch
		bge.b	Obj34_Move2
		neg.w	d1

Obj34_Move2:
		add.w	d1,8(a0)	; change item's position
		move.w	8(a0),d0
		bmi.b	locret_C412
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.b	locret_C412	; if yes, branch
		bra.w	actionsub
; ===========================================================================

locret_C412:
		rts	
; ===========================================================================

Obj34_ChangeArt:			; XREF: Obj34_ChkPos2
		cmpi.b	#4,r_no0(a0)
		bne.b	Obj34_Delete
		moveq	#2,d0
		jsr	(LoadPLC).l	; load explosion patterns
		moveq	#0,d0
		move.b	stageno,d0
		addi.w	#$15,d0
		jsr	(LoadPLC).l	; load animal patterns

Obj34_Delete:
		bra.w	frameout
; ===========================================================================
Obj34_ItemData:	dc.w $D0	; y-axis position
		dc.b 2,	0	; routine number, frame	number (changes)
		dc.w $E4
		dc.b 2,	6
		dc.w $EA
		dc.b 2,	7
		dc.w $E0
		dc.b 2,	$A
; ---------------------------------------------------------------------------
; Title	card configuration data
; Format:
; 4 bytes per item (YYYY XXXX)
; 4 items per level (GREEN HILL, ZONE, ACT X, oval)
; ---------------------------------------------------------------------------
Obj34_ConData:	dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; GHZ
		dc.w 0,	$120, $FEF4, $134, $40C, $14C, $20C, $14C ; LZ
		dc.w 0,	$120, $FEE0, $120, $3F8, $138, $1F8, $138 ; MZ
		dc.w 0,	$120, $FEFC, $13C, $414, $154, $214, $154 ; SLZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SYZ
		dc.w 0,	$120, $FF04, $144, $41C, $15C, $21C, $15C ; SBZ
		dc.w 0,	$120, $FEE4, $124, $3EC, $3EC, $1EC, $12C ; FZ
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 39 - "GAME OVER" and "TIME OVER"
; ---------------------------------------------------------------------------

Obj39:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj39_Index(pc,d0.w),d1
		jmp	Obj39_Index(pc,d1.w)
; ===========================================================================
Obj39_Index:	dc.w Obj39_ChkPLC-Obj39_Index
		dc.w loc_C50C-Obj39_Index
		dc.w Obj39_Wait-Obj39_Index
; ===========================================================================

Obj39_ChkPLC:				; XREF: Obj39_Index
		tst.l	($FFFFF680).w	; are the pattern load cues empty?
		beq.b	Obj39_Main	; if yes, branch
		rts	
; ===========================================================================

Obj39_Main:
		addq.b	#2,r_no0(a0)
		move.w	#$50,8(a0)	; set x-position
		btst	#0,$1A(a0)	; is the object	"OVER"?
		beq.b	loc_C4EC	; if not, branch
		move.w	#$1F0,8(a0)	; set x-position for "OVER"

loc_C4EC:
		move.w	#$F0,$A(a0)
		move.l	#Map_obj39,4(a0)
		move.w	#$855E,2(a0)
		move.b	#0,1(a0)
		move.b	#0,$18(a0)

loc_C50C:				; XREF: Obj39_Index
		moveq	#$10,d1		; set horizontal speed
		cmpi.w	#$120,8(a0)	; has item reached its target position?
		beq.b	Obj39_SetWait	; if yes, branch
		bcs.b	Obj39_Move
		neg.w	d1

Obj39_Move:
		add.w	d1,8(a0)	; change item's position
		bra.w	actionsub
; ===========================================================================

Obj39_SetWait:				; XREF: Obj39_Main
		move.w	#720,$1E(a0)	; set time delay to 12 seconds
		addq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

Obj39_Wait:				; XREF: Obj39_Index
		move.b	swdata1+1,d0
		andi.b	#$70,d0		; is button A, B or C pressed?
		bne.b	Obj39_ChgMode	; if yes, branch
		btst	#0,$1A(a0)
		bne.b	Obj39_Display
		tst.w	$1E(a0)		; has time delay reached zero?
		beq.b	Obj39_ChgMode	; if yes, branch
		subq.w	#1,$1E(a0)	; subtract 1 from time delay
		bra.w	actionsub
; ===========================================================================

Obj39_ChgMode:				; XREF: Obj39_Wait
		tst.b	pltimeover_f	; is time over flag set?
		bne.b	Obj39_ResetLvl	; if yes, branch
		move.b	#$14,gmmode ; set mode to $14 (continue screen)
		tst.b	($FFFFFE18).w	; do you have any continues?
		bne.b	Obj39_Display	; if yes, branch
		move.b	#0,gmmode ; set mode to 0 (Sega screen)
		bra.b	Obj39_Display
; ===========================================================================

Obj39_ResetLvl:				; XREF: Obj39_ChgMode
		move.w	#1,gameflag ; restart level

Obj39_Display:				; XREF: Obj39_ChgMode
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3A - "SONIC GOT THROUGH" title	card
; ---------------------------------------------------------------------------

Obj3A:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj3A_Index(pc,d0.w),d1
		jmp	Obj3A_Index(pc,d1.w)
; ===========================================================================
Obj3A_Index:	dc.w Obj3A_ChkPLC-Obj3A_Index
		dc.w Obj3A_ChkPos-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_TimeBonus-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_NextLevel-Obj3A_Index
		dc.w Obj3A_Wait-Obj3A_Index
		dc.w Obj3A_ChkPos2-Obj3A_Index
		dc.w loc_C766-Obj3A_Index
; ===========================================================================

Obj3A_ChkPLC:				; XREF: Obj3A_Index
		tst.l	($FFFFF680).w	; are the pattern load cues empty?
		beq.b	Obj3A_Main	; if yes, branch
		rts	
; ===========================================================================

Obj3A_Main:
		movea.l	a0,a1
		lea	(Obj3A_Config).l,a2
		moveq	#6,d1

Obj3A_Loop:
		move.b	#$3A,0(a1)
		move.w	(a2),8(a1)	; load start x-position
		move.w	(a2)+,$32(a1)	; load finish x-position (same as start)
		move.w	(a2)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)	; load y-position
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,d0
		cmpi.b	#6,d0
		bne.b	loc_C5CA
		add.b	stageno+1,d0 ; add act number to frame number

loc_C5CA:
		move.b	d0,$1A(a1)
		move.l	#Map_obj3A,4(a1)
		move.w	#$8580,2(a1)
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbra	d1,Obj3A_Loop	; repeat 6 times

Obj3A_ChkPos:				; XREF: Obj3A_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached its target position?
		beq.b	loc_C61A	; if yes, branch
		bge.b	Obj3A_Move
		neg.w	d1

Obj3A_Move:
		add.w	d1,8(a0)	; change item's position

loc_C5FE:				; XREF: loc_C61A
		move.w	8(a0),d0
		bmi.b	locret_C60E
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.b	locret_C60E	; if yes, branch
		bra.w	actionsub
; ===========================================================================

locret_C60E:
		rts	
; ===========================================================================

loc_C610:				; XREF: loc_C61A
		move.b	#$E,r_no0(a0)
		bra.w	Obj3A_ChkPos2
; ===========================================================================

loc_C61A:				; XREF: Obj3A_ChkPos
		cmpi.b	#$E,($FFFFD724).w
		beq.b	loc_C610
		cmpi.b	#4,$1A(a0)
		bne.b	loc_C5FE
		addq.b	#2,r_no0(a0)
		move.w	#180,$1E(a0)	; set time delay to 3 seconds

Obj3A_Wait:				; XREF: Obj3A_Index
		subq.w	#1,$1E(a0)	; subtract 1 from time delay
		bne.b	Obj3A_Display
		addq.b	#2,r_no0(a0)

Obj3A_Display:
		bra.w	actionsub
; ===========================================================================

Obj3A_TimeBonus:			; XREF: Obj3A_Index
		bsr.w	actionsub
		move.b	#1,($FFFFF7D6).w ; set time/ring bonus update flag
		moveq	#0,d0
		tst.w	($FFFFF7D2).w	; is time bonus	= zero?
		beq.b	Obj3A_RingBonus	; if yes, branch
		addi.w	#10,d0		; add 10 to score
		subi.w	#10,($FFFFF7D2).w ; subtract 10	from time bonus

Obj3A_RingBonus:
		tst.w	($FFFFF7D4).w	; is ring bonus	= zero?
		beq.b	Obj3A_ChkBonus	; if yes, branch
		addi.w	#10,d0		; add 10 to score
		subi.w	#10,($FFFFF7D4).w ; subtract 10	from ring bonus

Obj3A_ChkBonus:
		tst.w	d0		; is there any bonus?
		bne.b	Obj3A_AddBonus	; if yes, branch
		move.w	#$C5,d0
		jsr	(soundset).l ;	play "ker-ching" sound
		addq.b	#2,r_no0(a0)
		cmpi.w	#$501,stageno
		bne.b	Obj3A_SetDelay
		addq.b	#4,r_no0(a0)

Obj3A_SetDelay:
		move.w	#180,$1E(a0)	; set time delay to 3 seconds

locret_C692:
		rts	
; ===========================================================================

Obj3A_AddBonus:				; XREF: Obj3A_ChkBonus
		jsr	scoreup
		move.b	systemtimer+3,d0
		andi.b	#3,d0
		bne.b	locret_C692
		move.w	#$CD,d0
		jmp	(soundset).l ;	play "blip" sound
; ===========================================================================

Obj3A_NextLevel:			; XREF: Obj3A_Index
		move.b	stageno,d0
		andi.w	#7,d0
		lsl.w	#3,d0
		move.b	stageno+1,d1
		andi.w	#3,d1
		add.w	d1,d1
		add.w	d1,d0
		move.w	LevelOrder(pc,d0.w),d0 ; load level from level order array
		move.w	d0,stageno ; set level number
		tst.w	d0
		bne.b	Obj3A_ChkSS
		move.b	#0,gmmode ; set game mode to level (00)
		bra.b	Obj3A_Display2
; ===========================================================================

Obj3A_ChkSS:				; XREF: Obj3A_NextLevel
		clr.b	saveno	; clear	lamppost counter
		tst.b	special_flag	; has Sonic jumped into	a giant	ring?
		beq.b	loc_C6EA	; if not, branch
		move.b	#$10,gmmode ; set game mode to Special Stage (10)
		bra.b	Obj3A_Display2
; ===========================================================================

loc_C6EA:				; XREF: Obj3A_ChkSS
		move.w	#1,gameflag ; restart level

Obj3A_Display2:				; XREF: Obj3A_NextLevel, Obj3A_ChkSS
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Level	order array
; ---------------------------------------------------------------------------
LevelOrder:	incbin	misc\lvl_ord.bin
		even
; ===========================================================================

Obj3A_ChkPos2:				; XREF: Obj3A_Index
		moveq	#$20,d1		; set horizontal speed
		move.w	$32(a0),d0
		cmp.w	8(a0),d0	; has item reached its finish position?
		beq.b	Obj3A_SBZ2	; if yes, branch
		bge.b	Obj3A_Move2
		neg.w	d1

Obj3A_Move2:
		add.w	d1,8(a0)	; change item's position
		move.w	8(a0),d0
		bmi.b	locret_C748
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.b	locret_C748	; if yes, branch
		bra.w	actionsub
; ===========================================================================

locret_C748:
		rts	
; ===========================================================================

Obj3A_SBZ2:				; XREF: Obj3A_ChkPos2
		cmpi.b	#4,$1A(a0)
		bne.w	frameout
		addq.b	#2,r_no0(a0)
		clr.b	plautoflag	; unlock controls
		move.w	#$8D,d0
		jmp	(bgmset).l	; play FZ music
; ===========================================================================

loc_C766:				; XREF: Obj3A_Index
		addq.w	#2,scralim_right
		cmpi.w	#$2100,scralim_right
		beq.w	frameout
		rts	
; ===========================================================================
Obj3A_Config:	dc.w 4,	$124, $BC	; x-start, x-main, y-main
		dc.b 2,	0		; routine number, frame	number (changes)
		dc.w $FEE0, $120, $D0
		dc.b 2,	1
		dc.w $40C, $14C, $D6
		dc.b 2,	6
		dc.w $520, $120, $EC
		dc.b 2,	2
		dc.w $540, $120, $FC
		dc.b 2,	3
		dc.w $560, $120, $10C
		dc.b 2,	4
		dc.w $20C, $14C, $CC
		dc.b 2,	5
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7E - special stage results screen
; ---------------------------------------------------------------------------

Obj7E:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj7E_Index(pc,d0.w),d1
		jmp	Obj7E_Index(pc,d1.w)
; ===========================================================================
Obj7E_Index:	dc.w Obj7E_ChkPLC-Obj7E_Index
		dc.w Obj7E_ChkPos-Obj7E_Index
		dc.w Obj7E_Wait-Obj7E_Index
		dc.w Obj7E_RingBonus-Obj7E_Index
		dc.w Obj7E_Wait-Obj7E_Index
		dc.w Obj7E_Exit-Obj7E_Index
		dc.w Obj7E_Wait-Obj7E_Index
		dc.w Obj7E_Continue-Obj7E_Index
		dc.w Obj7E_Wait-Obj7E_Index
		dc.w Obj7E_Exit-Obj7E_Index
		dc.w loc_C91A-Obj7E_Index
; ===========================================================================

Obj7E_ChkPLC:				; XREF: Obj7E_Index
		tst.l	($FFFFF680).w	; are the pattern load cues empty?
		beq.b	Obj7E_Main	; if yes, branch
		rts	
; ===========================================================================

Obj7E_Main:
		movea.l	a0,a1
		lea	(Obj7E_Config).l,a2
		moveq	#3,d1
		cmpi.w	#50,plring ; do you have	50 or more rings?
		bcs.b	Obj7E_Loop	; if no, branch
		addq.w	#1,d1		; if yes, add 1	to d1 (number of sprites)

Obj7E_Loop:
		move.b	#$7E,0(a1)
		move.w	(a2)+,8(a1)	; load start x-position
		move.w	(a2)+,$30(a1)	; load main x-position
		move.w	(a2)+,$A(a1)	; load y-position
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1A(a1)
		move.l	#Map_obj7E,4(a1)
		move.w	#$8580,2(a1)
		move.b	#0,1(a1)
		lea	$40(a1),a1
		dbra	d1,Obj7E_Loop	; repeat sequence 3 or 4 times

		moveq	#7,d0
		move.b	($FFFFFE57).w,d1
		beq.b	loc_C842
		moveq	#0,d0
		cmpi.b	#6,d1		; do you have all chaos	emeralds?
		bne.b	loc_C842	; if not, branch
		moveq	#8,d0		; load "Sonic got them all" text
		move.w	#$18,8(a0)
		move.w	#$118,$30(a0)	; change position of text

loc_C842:
		move.b	d0,$1A(a0)

Obj7E_ChkPos:				; XREF: Obj7E_Index
		moveq	#$10,d1		; set horizontal speed
		move.w	$30(a0),d0
		cmp.w	8(a0),d0	; has item reached its target position?
		beq.b	loc_C86C	; if yes, branch
		bge.b	Obj7E_Move
		neg.w	d1

Obj7E_Move:
		add.w	d1,8(a0)	; change item's position

loc_C85A:				; XREF: loc_C86C
		move.w	8(a0),d0
		bmi.b	locret_C86A
		cmpi.w	#$200,d0	; has item moved beyond	$200 on	x-axis?
		bcc.b	locret_C86A	; if yes, branch
		bra.w	actionsub
; ===========================================================================

locret_C86A:
		rts	
; ===========================================================================

loc_C86C:				; XREF: Obj7E_ChkPos
		cmpi.b	#2,$1A(a0)
		bne.b	loc_C85A
		addq.b	#2,r_no0(a0)
		move.w	#180,$1E(a0)	; set time delay to 3 seconds
		move.b	#$7F,($FFFFD800).w ; load chaos	emerald	object

Obj7E_Wait:				; XREF: Obj7E_Index
		subq.w	#1,$1E(a0)	; subtract 1 from time delay
		bne.b	Obj7E_Display
		addq.b	#2,r_no0(a0)

Obj7E_Display:
		bra.w	actionsub
; ===========================================================================

Obj7E_RingBonus:			; XREF: Obj7E_Index
		bsr.w	actionsub
		move.b	#1,($FFFFF7D6).w ; set ring bonus update flag
		tst.w	($FFFFF7D4).w	; is ring bonus	= zero?
		beq.b	loc_C8C4	; if yes, branch
		subi.w	#10,($FFFFF7D4).w ; subtract 10	from ring bonus
		moveq	#10,d0		; add 10 to score
		jsr	scoreup
		move.b	systemtimer+3,d0
		andi.b	#3,d0
		bne.b	locret_C8EA
		move.w	#$CD,d0
		jmp	(soundset).l ;	play "blip" sound
; ===========================================================================

loc_C8C4:				; XREF: Obj7E_RingBonus
		move.w	#$C5,d0
		jsr	(soundset).l ;	play "ker-ching" sound
		addq.b	#2,r_no0(a0)
		move.w	#180,$1E(a0)	; set time delay to 3 seconds
		cmpi.w	#50,plring ; do you have	at least 50 rings?
		bcs.b	locret_C8EA	; if not, branch
		move.w	#60,$1E(a0)	; set time delay to 1 second
		addq.b	#4,r_no0(a0)	; goto "Obj7E_Continue"	routine

locret_C8EA:
		rts	
; ===========================================================================

Obj7E_Exit:				; XREF: Obj7E_Index
		move.w	#1,gameflag ; restart level
		bra.w	actionsub
; ===========================================================================

Obj7E_Continue:				; XREF: Obj7E_Index
		move.b	#4,($FFFFD6DA).w
		move.b	#$14,($FFFFD6E4).w
		move.w	#$BF,d0
		jsr	(soundset).l ;	play continues music
		addq.b	#2,r_no0(a0)
		move.w	#360,$1E(a0)	; set time delay to 6 seconds
		bra.w	actionsub
; ===========================================================================

loc_C91A:				; XREF: Obj7E_Index
		move.b	systemtimer+3,d0
		andi.b	#$F,d0
		bne.b	Obj7E_Display2
		bchg	#0,$1A(a0)

Obj7E_Display2:
		bra.w	actionsub
; ===========================================================================
Obj7E_Config:	dc.w $20, $120,	$C4	; start	x-pos, main x-pos, y-pos
		dc.b 2,	0		; rountine number, frame number
		dc.w $320, $120, $118
		dc.b 2,	1
		dc.w $360, $120, $128
		dc.b 2,	2
		dc.w $1EC, $11C, $C4
		dc.b 2,	3
		dc.w $3A0, $120, $138
		dc.b 2,	6
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7F - chaos emeralds from the special stage results screen
; ---------------------------------------------------------------------------

Obj7F:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj7F_Index(pc,d0.w),d1
		jmp	Obj7F_Index(pc,d1.w)
; ===========================================================================
Obj7F_Index:	dc.w Obj7F_Main-Obj7F_Index
		dc.w Obj7F_Flash-Obj7F_Index

; ---------------------------------------------------------------------------
; X-axis positions for chaos emeralds
; ---------------------------------------------------------------------------
Obj7F_PosData:	dc.w $110, $128, $F8, $140, $E0, $158
; ===========================================================================

Obj7F_Main:				; XREF: Obj7F_Index
		movea.l	a0,a1
		lea	(Obj7F_PosData).l,a2
		moveq	#0,d2
		moveq	#0,d1
		move.b	($FFFFFE57).w,d1 ; d1 is number	of emeralds
		subq.b	#1,d1		; subtract 1 from d1
		bcs.w	frameout	; if you have 0	emeralds, branch

Obj7F_Loop:
		move.b	#$7F,0(a1)
		move.w	(a2)+,8(a1)	; set x-position
		move.w	#$F0,$A(a1)	; set y-position
		lea	($FFFFFE58).w,a3 ; check which emeralds	you have
		move.b	(a3,d2.w),d3
		move.b	d3,$1A(a1)
		move.b	d3,$1C(a1)
		addq.b	#1,d2
		addq.b	#2,r_no0(a1)
		move.l	#Map_obj7F,4(a1)
		move.w	#$8541,2(a1)
		move.b	#0,1(a1)
		lea	$40(a1),a1	; next object
		dbra	d1,Obj7F_Loop	; loop for d1 number of	emeralds

Obj7F_Flash:				; XREF: Obj7F_Index
		move.b	$1A(a0),d0
		move.b	#6,$1A(a0)	; load 6th frame (blank)
		cmpi.b	#6,d0
		bne.b	Obj7F_Display
		move.b	$1C(a0),$1A(a0)	; load visible frame

Obj7F_Display:
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - zone title cards
; ---------------------------------------------------------------------------
Map_obj34:	dc.w byte_C9FE-Map_obj34
		dc.w byte_CA2C-Map_obj34
		dc.w byte_CA5A-Map_obj34
		dc.w byte_CA7A-Map_obj34
		dc.w byte_CAA8-Map_obj34
		dc.w byte_CADC-Map_obj34
		dc.w byte_CB10-Map_obj34
		dc.w byte_CB26-Map_obj34
		dc.w byte_CB31-Map_obj34
		dc.w byte_CB3C-Map_obj34
		dc.w byte_CB47-Map_obj34
		dc.w byte_CB8A-Map_obj34
byte_C9FE:	dc.b 9 			; GREEN HILL
		dc.b $F8, 5, 0,	$18, $B4
		dc.b $F8, 5, 0,	$3A, $C4
		dc.b $F8, 5, 0,	$10, $D4
		dc.b $F8, 5, 0,	$10, $E4
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	$1C, $14
		dc.b $F8, 1, 0,	$20, $24
		dc.b $F8, 5, 0,	$26, $2C
		dc.b $F8, 5, 0,	$26, $3C
byte_CA2C:	dc.b 9			; LABYRINTH
		dc.b $F8, 5, 0,	$26, $BC
		dc.b $F8, 5, 0,	0, $CC
		dc.b $F8, 5, 0,	4, $DC
		dc.b $F8, 5, 0,	$4A, $EC
		dc.b $F8, 5, 0,	$3A, $FC
		dc.b $F8, 1, 0,	$20, $C
		dc.b $F8, 5, 0,	$2E, $14
		dc.b $F8, 5, 0,	$42, $24
		dc.b $F8, 5, 0,	$1C, $34
byte_CA5A:	dc.b 6			; MARBLE
		dc.b $F8, 5, 0,	$2A, $CF
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3A, $F0
		dc.b $F8, 5, 0,	4, 0
		dc.b $F8, 5, 0,	$26, $10
		dc.b $F8, 5, 0,	$10, $20
		dc.b 0
byte_CA7A:	dc.b 9			; STAR	LIGHT
		dc.b $F8, 5, 0,	$3E, $B4
		dc.b $F8, 5, 0,	$42, $C4
		dc.b $F8, 5, 0,	0, $D4
		dc.b $F8, 5, 0,	$3A, $E4
		dc.b $F8, 5, 0,	$26, 4
		dc.b $F8, 1, 0,	$20, $14
		dc.b $F8, 5, 0,	$18, $1C
		dc.b $F8, 5, 0,	$1C, $2C
		dc.b $F8, 5, 0,	$42, $3C
byte_CAA8:	dc.b $A			; SPRING YARD
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	$36, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 1, 0,	$20, $DC
		dc.b $F8, 5, 0,	$2E, $E4
		dc.b $F8, 5, 0,	$18, $F4
		dc.b $F8, 5, 0,	$4A, $14
		dc.b $F8, 5, 0,	0, $24
		dc.b $F8, 5, 0,	$3A, $34
		dc.b $F8, 5, 0,	$C, $44
		dc.b 0
byte_CADC:	dc.b $A			; SCRAP BRAIN
		dc.b $F8, 5, 0,	$3E, $AC
		dc.b $F8, 5, 0,	8, $BC
		dc.b $F8, 5, 0,	$3A, $CC
		dc.b $F8, 5, 0,	0, $DC
		dc.b $F8, 5, 0,	$36, $EC
		dc.b $F8, 5, 0,	4, $C
		dc.b $F8, 5, 0,	$3A, $1C
		dc.b $F8, 5, 0,	0, $2C
		dc.b $F8, 1, 0,	$20, $3C
		dc.b $F8, 5, 0,	$2E, $44
		dc.b 0
byte_CB10:	dc.b 4			; ZONE
		dc.b $F8, 5, 0,	$4E, $E0
		dc.b $F8, 5, 0,	$32, $F0
		dc.b $F8, 5, 0,	$2E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b 0
byte_CB26:	dc.b 2			; ACT 1
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 2, 0,	$57, $C
byte_CB31:	dc.b 2			; ACT 2
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$5A, 8
byte_CB3C:	dc.b 2			; ACT 3
		dc.b 4,	$C, 0, $53, $EC
		dc.b $F4, 6, 0,	$60, 8
byte_CB47:	dc.b $D			; Oval
		dc.b $E4, $C, 0, $70, $F4
		dc.b $E4, 2, 0,	$74, $14
		dc.b $EC, 4, 0,	$77, $EC
		dc.b $F4, 5, 0,	$79, $E4
		dc.b $14, $C, $18, $70,	$EC
		dc.b 4,	2, $18,	$74, $E4
		dc.b $C, 4, $18, $77, 4
		dc.b $FC, 5, $18, $79, $C
		dc.b $EC, 8, 0,	$7D, $FC
		dc.b $F4, $C, 0, $7C, $F4
		dc.b $FC, 8, 0,	$7C, $F4
		dc.b 4,	$C, 0, $7C, $EC
		dc.b $C, 8, 0, $7C, $EC
		dc.b 0
byte_CB8A:	dc.b 5			; FINAL
		dc.b $F8, 5, 0,	$14, $DC
		dc.b $F8, 1, 0,	$20, $EC
		dc.b $F8, 5, 0,	$2E, $F4
		dc.b $F8, 5, 0,	0, 4
		dc.b $F8, 5, 0,	$26, $14
		even
; ---------------------------------------------------------------------------
; Sprite mappings - "GAME OVER"	and "TIME OVER"
; ---------------------------------------------------------------------------
Map_obj39:
	include "_maps\obj39.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - "SONIC HAS PASSED" title card
; ---------------------------------------------------------------------------
Map_obj3A:	dc.w byte_CBEA-Map_obj3A
		dc.w byte_CC13-Map_obj3A
		dc.w byte_CC32-Map_obj3A
		dc.w byte_CC51-Map_obj3A
		dc.w byte_CC75-Map_obj3A
		dc.w byte_CB47-Map_obj3A
		dc.w byte_CB26-Map_obj3A
		dc.w byte_CB31-Map_obj3A
		dc.w byte_CB3C-Map_obj3A
byte_CBEA:	dc.b 8			; SONIC HAS
		dc.b $F8, 5, 0,	$3E, $B8
		dc.b $F8, 5, 0,	$32, $C8
		dc.b $F8, 5, 0,	$2E, $D8
		dc.b $F8, 1, 0,	$20, $E8
		dc.b $F8, 5, 0,	8, $F0
		dc.b $F8, 5, 0,	$1C, $10
		dc.b $F8, 5, 0,	0, $20
		dc.b $F8, 5, 0,	$3E, $30
byte_CC13:	dc.b 6			; PASSED
		dc.b $F8, 5, 0,	$36, $D0
		dc.b $F8, 5, 0,	0, $E0
		dc.b $F8, 5, 0,	$3E, $F0
		dc.b $F8, 5, 0,	$3E, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b $F8, 5, 0,	$C, $20
byte_CC32:	dc.b 6			; SCORE
		dc.b $F8, $D, 1, $4A, $B0
		dc.b $F8, 1, 1,	$62, $D0
		dc.b $F8, 9, 1,	$64, $18
		dc.b $F8, $D, 1, $6A, $30
		dc.b $F7, 4, 0,	$6E, $CD
		dc.b $FF, 4, $18, $6E, $CD
byte_CC51:	dc.b 7			; TIME BONUS
		dc.b $F8, $D, 1, $5A, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F0,	$28
		dc.b $F8, 1, 1,	$70, $48
byte_CC75:	dc.b 7			; RING BONUS
		dc.b $F8, $D, 1, $52, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F8,	$28
		dc.b $F8, 1, 1,	$70, $48
		even
; ---------------------------------------------------------------------------
; Sprite mappings - special stage results screen
; ---------------------------------------------------------------------------
Map_obj7E:	dc.w byte_CCAC-Map_obj7E
		dc.w byte_CCEE-Map_obj7E
		dc.w byte_CD0D-Map_obj7E
		dc.w byte_CB47-Map_obj7E
		dc.w byte_CD31-Map_obj7E
		dc.w byte_CD46-Map_obj7E
		dc.w byte_CD5B-Map_obj7E
		dc.w byte_CD6B-Map_obj7E
		dc.w byte_CDA8-Map_obj7E
byte_CCAC:	dc.b $D			; "CHAOS EMERALDS"
		dc.b $F8, 5, 0,	8, $90
		dc.b $F8, 5, 0,	$1C, $A0
		dc.b $F8, 5, 0,	0, $B0
		dc.b $F8, 5, 0,	$32, $C0
		dc.b $F8, 5, 0,	$3E, $D0
		dc.b $F8, 5, 0,	$10, $F0
		dc.b $F8, 5, 0,	$2A, 0
		dc.b $F8, 5, 0,	$10, $10
		dc.b $F8, 5, 0,	$3A, $20
		dc.b $F8, 5, 0,	0, $30
		dc.b $F8, 5, 0,	$26, $40
		dc.b $F8, 5, 0,	$C, $50
		dc.b $F8, 5, 0,	$3E, $60
byte_CCEE:	dc.b 6			; "SCORE"
		dc.b $F8, $D, 1, $4A, $B0
		dc.b $F8, 1, 1,	$62, $D0
		dc.b $F8, 9, 1,	$64, $18
		dc.b $F8, $D, 1, $6A, $30
		dc.b $F7, 4, 0,	$6E, $CD
		dc.b $FF, 4, $18, $6E, $CD
byte_CD0D:	dc.b 7
		dc.b $F8, $D, 1, $52, $B0
		dc.b $F8, $D, 0, $66, $D9
		dc.b $F8, 1, 1,	$4A, $F9
		dc.b $F7, 4, 0,	$6E, $F6
		dc.b $FF, 4, $18, $6E, $F6
		dc.b $F8, $D, $FF, $F8,	$28
		dc.b $F8, 1, 1,	$70, $48
byte_CD31:	dc.b 4
		dc.b $F8, $D, $FF, $D1,	$B0
		dc.b $F8, $D, $FF, $D9,	$D0
		dc.b $F8, 1, $FF, $E1, $F0
		dc.b $F8, 6, $1F, $E3, $40
byte_CD46:	dc.b 4
		dc.b $F8, $D, $FF, $D1,	$B0
		dc.b $F8, $D, $FF, $D9,	$D0
		dc.b $F8, 1, $FF, $E1, $F0
		dc.b $F8, 6, $1F, $E9, $40
byte_CD5B:	dc.b 3
		dc.b $F8, $D, $FF, $D1,	$B0
		dc.b $F8, $D, $FF, $D9,	$D0
		dc.b $F8, 1, $FF, $E1, $F0
byte_CD6B:	dc.b $C			; "SPECIAL STAGE"
		dc.b $F8, 5, 0,	$3E, $9C
		dc.b $F8, 5, 0,	$36, $AC
		dc.b $F8, 5, 0,	$10, $BC
		dc.b $F8, 5, 0,	8, $CC
		dc.b $F8, 1, 0,	$20, $DC
		dc.b $F8, 5, 0,	0, $E4
		dc.b $F8, 5, 0,	$26, $F4
		dc.b $F8, 5, 0,	$3E, $14
		dc.b $F8, 5, 0,	$42, $24
		dc.b $F8, 5, 0,	0, $34
		dc.b $F8, 5, 0,	$18, $44
		dc.b $F8, 5, 0,	$10, $54
byte_CDA8:	dc.b $F			; "SONIC GOT THEM ALL"
		dc.b $F8, 5, 0,	$3E, $88
		dc.b $F8, 5, 0,	$32, $98
		dc.b $F8, 5, 0,	$2E, $A8
		dc.b $F8, 1, 0,	$20, $B8
		dc.b $F8, 5, 0,	8, $C0
		dc.b $F8, 5, 0,	$18, $D8
		dc.b $F8, 5, 0,	$32, $E8
		dc.b $F8, 5, 0,	$42, $F8
		dc.b $F8, 5, 0,	$42, $10
		dc.b $F8, 5, 0,	$1C, $20
		dc.b $F8, 5, 0,	$10, $30
		dc.b $F8, 5, 0,	$2A, $40
		dc.b $F8, 5, 0,	0, $58
		dc.b $F8, 5, 0,	$26, $68
		dc.b $F8, 5, 0,	$26, $78
		even
; ---------------------------------------------------------------------------
; Sprite mappings - chaos emeralds from	the special stage results screen
; ---------------------------------------------------------------------------
Map_obj7F:
	include "_maps\obj7F.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 36 - spikes
; ---------------------------------------------------------------------------

toge:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	toge_Index(pc,d0.w),d1
		jmp	toge_Index(pc,d1.w)
; ===========================================================================
toge_Index:	dc.w toge_Main-toge_Index
		dc.w toge_Solid-toge_Index

toge_Var:	dc.b 0,	$14		; frame	number,	object width
		dc.b 1,	$10
		dc.b 2,	4
		dc.b 3,	$1C
		dc.b 4,	$40
		dc.b 5,	$10
; ===========================================================================

toge_Main:				; XREF: toge_Index
		addq.b	#2,r_no0(a0)
		move.l	#togepat,4(a0)
		move.w	#$51B,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	userflag(a0),d0
		andi.b	#$F,userflag(a0)
		andi.w	#$F0,d0
		lea	(toge_Var).l,a1
		lsr.w	#3,d0
		adda.w	d0,a1
		move.b	(a1)+,$1A(a0)
		move.b	(a1)+,$19(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)

toge_Solid:				; XREF: toge_Index
		bsr.w	toge_Type0x	; make the object move
		move.w	#4,d2
		cmpi.b	#5,$1A(a0)	; is object type $5x ?
		beq.b	toge_SideWays	; if yes, branch
		cmpi.b	#1,$1A(a0)	; is object type $1x ?
		bne.b	toge_Upright	; if not, branch
		move.w	#$14,d2

; Spikes types $1x and $5x face	sideways

toge_SideWays:				; XREF: toge_Solid
		move.w	#$1B,d1
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#3,cddat(a0)
		bne.b	toge_Display
		cmpi.w	#1,d4
		beq.b	toge_Hurt
		bra.b	toge_Display
; ===========================================================================

; Spikes types $0x, $2x, $3x and $4x face up or	down

toge_Upright:				; XREF: toge_Solid
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#3,cddat(a0)
		bne.b	toge_Hurt
		tst.w	d4
		bpl.b	toge_Display

toge_Hurt:				; XREF: toge_SideWays; toge_Upright
		tst.b	plpower_m	; is Sonic invincible?
		bne.b	toge_Display	; if yes, branch
		move.l	a0,-(sp)
		movea.l	a0,a2
		lea	playerwk,a0
		cmpi.b	#4,r_no0(a0)
		bcc.b	loc_CF20
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		jsr	playdamageset

loc_CF20:
		movea.l	(sp)+,a0

toge_Display:
		bsr.w	actionsub
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================

toge_Type0x:				; XREF: toge_Solid
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	toge_TypeIndex(pc,d0.w),d1
		jmp	toge_TypeIndex(pc,d1.w)
; ===========================================================================
toge_TypeIndex:dc.w toge_Type00-toge_TypeIndex
		dc.w toge_Type01-toge_TypeIndex
		dc.w toge_Type02-toge_TypeIndex
; ===========================================================================

toge_Type00:				; XREF: toge_TypeIndex
		rts			; don't move the object
; ===========================================================================

toge_Type01:				; XREF: toge_TypeIndex
		bsr.w	toge_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)	; move the object vertically
		rts	
; ===========================================================================

toge_Type02:				; XREF: toge_TypeIndex
		bsr.w	toge_Wait
		moveq	#0,d0
		move.b	$34(a0),d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; move the object horizontally
		rts	
; ===========================================================================

toge_Wait:
		tst.w	$38(a0)		; is time delay	= zero?
		beq.b	loc_CFA4	; if yes, branch
		subq.w	#1,$38(a0)	; subtract 1 from time delay
		bne.b	locret_CFE6
		tst.b	1(a0)
		bpl.b	locret_CFE6
		move.w	#$B6,d0
		jsr	(soundset).l ;	play "spikes moving" sound
		bra.b	locret_CFE6
; ===========================================================================

loc_CFA4:
		tst.w	$36(a0)
		beq.b	loc_CFC6
		subi.w	#$800,$34(a0)
		bcc.b	locret_CFE6
		move.w	#0,$34(a0)
		move.w	#0,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second
		bra.b	locret_CFE6
; ===========================================================================

loc_CFC6:
		addi.w	#$800,$34(a0)
		cmpi.w	#$2000,$34(a0)
		bcs.b	locret_CFE6
		move.w	#$2000,$34(a0)
		move.w	#1,$36(a0)
		move.w	#60,$38(a0)	; set time delay to 1 second

locret_CFE6:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - spikes
; ---------------------------------------------------------------------------
togepat:
	include "_maps\toge.asm"

; ===========================================================================

jyama:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	jyama_move_tbl(pc,d0.w),d1
		jmp		jyama_move_tbl(pc,d1.w)
jyama_move_tbl:
		dc.w	jyama_init-jyama_move_tbl
		dc.w	jyama_main-jyama_move_tbl
jyama_init:
		addq.b	#word,r_no0(a0)
		move.l	#jyamapat,patbase(a0)
		move.w	#$63d0,sproffset(a0)
		move.b	#4,actflg(a0)
		move.b	#19,sprhs(a0)
		move.b	#4,sprpri(a0)
jyama_main:
		move.w	#27,d1
		move.w	#16,d2
		move.w	#16,d3
		move.w	xposi(a0),d4
		bsr.w	hitchk
		bsr.w	actionsub
		move.w	xposi(a0),d0
		andi.w	#-128,d0
		move.w	scra_h_posit,d1
		subi.w	#128,d1
		andi.w	#-128,d1
		sub.w	d1,d0
		cmpi.w	#640,d0
		bhi.w	frameout
		rts	

taki:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	taki_move_tbl(pc,d0.w),d1
		jmp		taki_move_tbl(pc,d1.w)
taki_move_tbl:
		dc.w	taki_init-taki_move_tbl
		dc.w	taki_move-taki_move_tbl
taki_init:
		addq.b	#word,r_no0(a0)
		move.b	#4,actflg(a0)
taki_move:
		move.b	systemtimer+3,d0
		andi.b	#63,d0
		bne.b	?jump
		move.w	#$d0,d0
		jsr		soundset
?jump:
		move.w	xposi(a0),d0
		andi.w	#-128,d0
		move.w	scra_h_posit,d1
		subi.w	#128,d1
		andi.w	#-128,d1
		sub.w	d1,d0
		cmpi.w	#640,d0
		bhi.w	frameout
		rts

jyamapat:
		dc.w	jyamasp0-jyamapat
jyamasp0:
		dc.b	2
		dc.b	$f0,$0b,$00,$00,$e8
		dc.b	$f0,$0b,$00,$0c,$00

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------

brkabe:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	brkabe_move_tbl(pc,d0.w),d1
		jsr		brkabe_move_tbl(pc,d1.w)
		bra.w	frameoutchk
brkabe_move_tbl:
		dc.w	brkabe_init-brkabe_move_tbl
		dc.w	brkabe_move-brkabe_move_tbl
		dc.w	brkabe_move2-brkabe_move_tbl
brkabe_init:
		addq.b	#2,r_no0(a0)
		move.l	#Map_brkabe,4(a0)
		move.w	#$450F,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	userflag(a0),$1A(a0)

brkabe_move:				; XREF: brkabe_move_tbl
		move.w	($FFFFD010).w,$30(a0) ;	load Sonic's horizontal speed
		move.w	#$1B,d1
		move.w	#$20,d2
		move.w	#$20,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#5,cddat(a0)
		bne.b	brkabe_ChkRoll

locret_D180:
		rts	
; ===========================================================================

brkabe_ChkRoll:				; XREF: brkabe_move
		cmpi.b	#2,$1C(a1)	; is Sonic rolling?
		bne.b	locret_D180	; if not, branch
		move.w	$30(a0),d0
		bpl.b	brkabe_ChkSpeed
		neg.w	d0

brkabe_ChkSpeed:
		cmpi.w	#$480,d0	; is Sonic's speed $480 or higher?
		bcs.b	locret_D180	; if not, branch
		move.w	$30(a0),$10(a1)
		addq.w	#4,8(a1)
		lea	(brkabe_FragSpd1).l,a4 ;	use fragments that move	right
		move.w	8(a0),d0
		cmp.w	8(a1),d0	; is Sonic to the right	of the block?
		bcs.b	brkabe_Smash	; if yes, branch
		subq.w	#8,8(a1)
		lea	(brkabe_FragSpd2).l,a4 ;	use fragments that move	left

brkabe_Smash:
		move.w	$10(a1),$14(a1)
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)
		moveq	#7,d1		; load 8 fragments
		move.w	#$70,d2
		bsr.b	SmashObject

brkabe_move2:				; XREF: brkabe_move_tbl
		bsr.w	speedset2
		addi.w	#$70,$12(a0)	; make fragment	fall faster
		bsr.w	actionsub
		tst.b	1(a0)
		bpl.w	frameout
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	smash a	block (GHZ walls and MZ	blocks)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SmashObject:				; XREF: brkabe_Smash
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		movea.l	4(a0),a3
		adda.w	(a3,d0.w),a3
		addq.w	#1,a3
		bset	#5,1(a0)
		move.b	0(a0),d4
		move.b	1(a0),d5
		movea.l	a0,a1
		bra.b	Smash_LoadFrag
; ===========================================================================

Smash_Loop:
		bsr.w	actwkchk
		bne.b	Smash_PlaySnd
		addq.w	#5,a3

Smash_LoadFrag:				; XREF: SmashObject
		move.b	#4,r_no0(a1)
		move.b	d4,0(a1)
		move.l	a3,4(a1)
		move.b	d5,1(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	2(a0),2(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.w	(a4)+,$10(a1)
		move.w	(a4)+,$12(a1)
		cmpa.l	a0,a1
		bcc.b	loc_D268
		move.l	a0,-(sp)
		movea.l	a1,a0
		bsr.w	speedset2
		add.w	d2,$12(a0)
		movea.l	(sp)+,a0
		bsr.w	actionsub2

loc_D268:
		dbra	d1,Smash_Loop

Smash_PlaySnd:
		move.w	#$CB,d0
		jmp	(soundset).l ;	play smashing sound
; End of function SmashObject

; ===========================================================================
; Smashed block	fragment speeds
;
brkabe_FragSpd1:	dc.w $400, $FB00	; x-move speed,	y-move speed
		dc.w $600, $FF00
		dc.w $600, $100
		dc.w $400, $500
		dc.w $600, $FA00
		dc.w $800, $FE00
		dc.w $800, $200
		dc.w $600, $600

brkabe_FragSpd2:	dc.w $FA00, $FA00
		dc.w $F800, $FE00
		dc.w $F800, $200
		dc.w $FA00, $600
		dc.w $FC00, $FB00
		dc.w $FA00, $FF00
		dc.w $FA00, $100
		dc.w $FC00, $500
; ---------------------------------------------------------------------------
; Sprite mappings - smashable walls (GHZ, SLZ)
; ---------------------------------------------------------------------------
Map_brkabe:
	include "_maps\brkabe.asm"

action:
		lea		actwk,a0
		moveq	#$7F,d7
		moveq	#0,d0
		cmpi.b	#6,playerwk+r_no0
		bcc.b	loc_D362

actloop:
		move.b	(a0),d0
		beq.b	loc_D358
		add.w	d0,d0
		add.w	d0,d0
		movea.l	act_tbl-4(pc,d0.w),a1
		jsr		(a1)
		moveq	#0,d0

loc_D358:
		lea		$40(a0),a0
		dbra	d7,actloop
		rts

loc_D362:
		moveq	#$1F,d7
		bsr.b	actloop
		moveq	#$5F,d7

loc_D368:
		moveq	#0,d0
		move.b	(a0),d0
		beq.b	loc_D378
		tst.b	1(a0)
		bpl.b	loc_D378
		bsr.w	actionsub

loc_D378:
		lea		$40(a0),a0

loc_D37C:
		dbra	d7,loc_D368
		rts

act_tbl:
		dc.l	play00,speedset,speedset,speedset,speedset,speedset
		dc.l	speedset,Obj08,play01,plawa,bou,ben
		dc.l	gole,Obj0E,Obj0F,play02,hashi,signal
		dc.l	mfire,fire,buranko,yari,thashi,shima
		dc.l	Obj19,break,wave,bgspr,switch,buta
		dc.l	kani,Obj20,score,hachi,Obj23,Obj24
		dc.l	ring,item,bakuhatu,usagi,ten,door
		dc.l	fish,fish2,mogura,item2,yuka,ochi
		dc.l	turi,switch2,box,Obj34,Obj35,toge,flyring,effect
		dc.l	Obj39,Obj3A,jyama,brkabe,boss1,masin,Obj3F,musi
		dc.l	sjump,kamere,aruma,kageb,Obj45,fblock,bobin,btama
		dc.l	taki,Obj4A,bigring,myogan,yogan,yogan2,usa,yado
		dc.l	bryuka,dai,break2,yoganc,bat,dai2,Obj57,Obj58
		dc.l	elev,pedal,step,Obj5C,fun,sisoo,brobo,uni
		dc.l	dai3,kazari,kassya,awa,mizu,mawaru,haguruma,beltcon
		dc.l	pata,noko,dai4,yukae,fire6,ele,beltc,yukai
		dc.l	scoli,Obj72,Obj73,Obj74,Obj75,Obj76,Obj77,imo
		dc.l	save,Obj7A,Obj7B,Obj7C,bten,Obj7E,Obj7F,Obj80
		dc.l	Obj81,Obj82,Obj83,Obj84,Obj85,Obj86,Obj87,Obj88
		dc.l	Obj89,staff,Obj8B,Obj8C

speedset:
		move.l	xposi(a0),d2
		move.l	yposi(a0),d3
		move.w	xspeed(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	yspeed(a0),d0
		addi.w	#56,yspeed(a0)
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,xposi(a0)
		move.l	d3,yposi(a0)
		rts

speedset2:
		move.l	xposi(a0),d2
		move.l	yposi(a0),d3
		move.w	xspeed(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	yspeed(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,xposi(a0)
		move.l	d3,yposi(a0)
		rts	

actionsub:
		lea	($FFFFAC00).w,a1
		move.w	$18(a0),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a1
		cmpi.w	#$7E,(a1)
		bcc.b	?end
		addq.w	#2,(a1)
		adda.w	(a1),a1
		move.w	a0,(a1)
?end:
		rts

actionsub2:
		lea	($FFFFAC00).w,a2
		move.w	$18(a1),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		adda.w	d0,a2
		cmpi.w	#$7E,(a2)
		bcc.b	?end
		addq.w	#2,(a2)
		adda.w	(a2),a2
		move.w	a1,(a2)
?end:
		rts

frameout:
		movea.l	a0,a1
frameout2:
		moveq	#0,d1
		moveq	#$F,d0
loc_D646:
		move.l	d1,(a1)+
		dbra	d0,loc_D646
		rts

BldSpr_ScrPos:	dc.l 0
		dc.l scra_h_posit
		dc.l scrb_h_posit
		dc.l scrz_h_posit
; ---------------------------------------------------------------------------
; Subroutine to	convert	mappings (etc) to proper Megadrive sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


patset:				; XREF: TitleScreen; et al
		lea	($FFFFF800).w,a2 ; set address for sprite table
		moveq	#0,d5
		lea	($FFFFAC00).w,a4
		moveq	#7,d7

loc_D66A:
		tst.w	(a4)
		beq.w	loc_D72E
		moveq	#2,d6

loc_D672:
		movea.w	(a4,d6.w),a0
		tst.b	(a0)
		beq.w	loc_D726
		bclr	#7,1(a0)
		move.b	1(a0),d0
		move.b	d0,d4
		andi.w	#$C,d0
		beq.b	loc_D6DE
		movea.l	BldSpr_ScrPos(pc,d0.w),a1
		moveq	#0,d0
		move.b	$19(a0),d0
		move.w	8(a0),d3
		sub.w	(a1),d3
		move.w	d3,d1
		add.w	d0,d1
		bmi.w	loc_D726
		move.w	d3,d1
		sub.w	d0,d1
		cmpi.w	#$140,d1
		bge.b	loc_D726
		addi.w	#$80,d3
		btst	#4,d4
		beq.b	loc_D6E8
		moveq	#0,d0
		move.b	$16(a0),d0
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		move.w	d2,d1
		add.w	d0,d1
		bmi.b	loc_D726
		move.w	d2,d1
		sub.w	d0,d1
		cmpi.w	#$E0,d1
		bge.b	loc_D726
		addi.w	#$80,d2
		bra.b	loc_D700
; ===========================================================================

loc_D6DE:
		move.w	$A(a0),d2
		move.w	8(a0),d3
		bra.b	loc_D700
; ===========================================================================

loc_D6E8:
		move.w	$C(a0),d2
		sub.w	4(a1),d2
		addi.w	#$80,d2
		cmpi.w	#$60,d2
		bcs.b	loc_D726
		cmpi.w	#$180,d2
		bcc.b	loc_D726

loc_D700:
		movea.l	4(a0),a1
		moveq	#0,d1
		btst	#5,d4
		bne.b	loc_D71C
		move.b	$1A(a0),d1
		add.b	d1,d1
		adda.w	(a1,d1.w),a1
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.b	loc_D720

loc_D71C:
		bsr.w	sub_D750

loc_D720:
		bset	#7,1(a0)

loc_D726:
		addq.w	#2,d6
		subq.w	#2,(a4)
		bne.w	loc_D672

loc_D72E:
		lea	$80(a4),a4
		dbra	d7,loc_D66A
		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5
		beq.b	loc_D748
		move.l	#0,(a2)
		rts	
; ===========================================================================

loc_D748:
		move.b	#0,-5(a2)
		rts	
; End of function patset


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D750:				; XREF: patset
		movea.w	2(a0),a3
		btst	#0,d4
		bne.b	loc_D796
		btst	#1,d4
		bne.w	loc_D7E4
; End of function sub_D750


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_D762:				; XREF: sub_D762; SS_ShowLayout
		cmpi.b	#$50,d5
		beq.b	locret_D794
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.b	loc_D78E
		addq.w	#1,d0

loc_D78E:
		move.w	d0,(a2)+
		dbra	d1,sub_D762

locret_D794:
		rts	
; End of function sub_D762

; ===========================================================================

loc_D796:
		btst	#1,d4
		bne.w	loc_D82A

loc_D79E:
		cmpi.b	#$50,d5
		beq.b	locret_D7E2
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.b	loc_D7DC
		addq.w	#1,d0

loc_D7DC:
		move.w	d0,(a2)+
		dbra	d1,loc_D79E

locret_D7E2:
		rts	
; ===========================================================================

loc_D7E4:				; XREF: sub_D750
		cmpi.b	#$50,d5
		beq.b	locret_D828
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1000,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.b	loc_D822
		addq.w	#1,d0

loc_D822:
		move.w	d0,(a2)+
		dbra	d1,loc_D7E4

locret_D828:
		rts	
; ===========================================================================

loc_D82A:
		cmpi.b	#$50,d5
		beq.b	locret_D87C
		move.b	(a1)+,d0
		move.b	(a1),d4
		ext.w	d0
		neg.w	d0
		lsl.b	#3,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d2,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d4
		move.b	d4,(a2)+
		addq.b	#1,d5
		move.b	d5,(a2)+
		move.b	(a1)+,d0
		lsl.w	#8,d0
		move.b	(a1)+,d0
		add.w	a3,d0
		eori.w	#$1800,d0
		move.w	d0,(a2)+
		move.b	(a1)+,d0
		ext.w	d0
		neg.w	d0
		add.b	d4,d4
		andi.w	#$18,d4
		addq.w	#8,d4
		sub.w	d4,d0
		add.w	d3,d0
		andi.w	#$1FF,d0
		bne.b	loc_D876
		addq.w	#1,d0

loc_D876:
		move.w	d0,(a2)+
		dbra	d1,loc_D82A

locret_D87C:
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	check if an object is on the screen
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen:
		move.w	8(a0),d0	; get object x-position
		sub.w	scra_h_posit,d0 ; subtract screen x-position
		bmi.b	NotOnScreen
		cmpi.w	#320,d0		; is object on the screen?
		bge.b	NotOnScreen	; if not, branch

		move.w	$C(a0),d1	; get object y-position
		sub.w	scra_v_posit,d1 ; subtract screen y-position
		bmi.b	NotOnScreen
		cmpi.w	#224,d1		; is object on the screen?
		bge.b	NotOnScreen	; if not, branch

		moveq	#0,d0		; set flag to 0
		rts	
; ===========================================================================

NotOnScreen:				; XREF: ChkObjOnScreen
		moveq	#1,d0		; set flag to 1
		rts	
; End of function ChkObjOnScreen


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ChkObjOnScreen2:
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	8(a0),d0
		sub.w	scra_h_posit,d0
		add.w	d1,d0
		bmi.b	NotOnScreen2
		add.w	d1,d1
		sub.w	d1,d0
		cmpi.w	#320,d0
		bge.b	NotOnScreen2

		move.w	$C(a0),d1
		sub.w	scra_v_posit,d1
		bmi.b	NotOnScreen2
		cmpi.w	#224,d1
		bge.b	NotOnScreen2

		moveq	#0,d0
		rts	
; ===========================================================================

NotOnScreen2:				; XREF: ChkObjOnScreen2
		moveq	#1,d0
		rts	
; End of function ChkObjOnScreen2

; ---------------------------------------------------------------------------
; Subroutine to	load a level's objects
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjPosLoad:				; XREF: Level; et al
		moveq	#0,d0
		move.b	($FFFFF76C).w,d0
		move.w	OPL_Index(pc,d0.w),d0
		jmp	OPL_Index(pc,d0.w)
; End of function ObjPosLoad

; ===========================================================================
OPL_Index:	dc.w OPL_Main-OPL_Index
		dc.w OPL_Next-OPL_Index
; ===========================================================================

OPL_Main:				; XREF: OPL_Index
		addq.b	#2,($FFFFF76C).w
		move.w	stageno,d0
		lsl.b	#6,d0
		lsr.w	#4,d0
		lea	(ObjPos_Index).l,a0
		movea.l	a0,a1
		adda.w	(a0,d0.w),a0
		move.l	a0,($FFFFF770).w
		move.l	a0,($FFFFF774).w
		adda.w	2(a1,d0.w),a1
		move.l	a1,($FFFFF778).w
		move.l	a1,($FFFFF77C).w
		lea	flagwork,a2
		move.w	#$101,(a2)+
		move.w	#$5E,d0

OPL_ClrList:
		clr.l	(a2)+
		dbra	d0,OPL_ClrList	; clear	pre-destroyed object list

		lea	flagwork,a2
		moveq	#0,d2
		move.w	scra_h_posit,d6
		subi.w	#$80,d6
		bcc.b	loc_D93C
		moveq	#0,d6

loc_D93C:
		andi.w	#$FF80,d6
		movea.l	($FFFFF770).w,a0

loc_D944:
		cmp.w	(a0),d6
		bls.b	loc_D956
		tst.b	4(a0)
		bpl.b	loc_D952
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_D952:
		addq.w	#6,a0
		bra.b	loc_D944
; ===========================================================================

loc_D956:
		move.l	a0,($FFFFF770).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6
		bcs.b	loc_D976

loc_D964:
		cmp.w	(a0),d6
		bls.b	loc_D976
		tst.b	4(a0)
		bpl.b	loc_D972
		addq.b	#1,1(a2)

loc_D972:
		addq.w	#6,a0
		bra.b	loc_D964
; ===========================================================================

loc_D976:
		move.l	a0,($FFFFF774).w
		move.w	#-1,($FFFFF76E).w

OPL_Next:				; XREF: OPL_Index
		lea	flagwork,a2
		moveq	#0,d2
		move.w	scra_h_posit,d6
		andi.w	#$FF80,d6
		cmp.w	($FFFFF76E).w,d6
		beq.w	locret_DA3A
		bge.b	loc_D9F6
		move.w	d6,($FFFFF76E).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$80,d6
		bcs.b	loc_D9D2

loc_D9A6:
		cmp.w	-6(a0),d6
		bge.b	loc_D9D2
		subq.w	#6,a0
		tst.b	4(a0)
		bpl.b	loc_D9BC
		subq.b	#1,1(a2)
		move.b	1(a2),d2

loc_D9BC:
		bsr.w	loc_DA3C
		bne.b	loc_D9C6
		subq.w	#6,a0
		bra.b	loc_D9A6
; ===========================================================================

loc_D9C6:
		tst.b	4(a0)
		bpl.b	loc_D9D0
		addq.b	#1,1(a2)

loc_D9D0:
		addq.w	#6,a0

loc_D9D2:
		move.l	a0,($FFFFF774).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$300,d6

loc_D9DE:
		cmp.w	-6(a0),d6
		bgt.b	loc_D9F0
		tst.b	-2(a0)
		bpl.b	loc_D9EC
		subq.b	#1,(a2)

loc_D9EC:
		subq.w	#6,a0
		bra.b	loc_D9DE
; ===========================================================================

loc_D9F0:
		move.l	a0,($FFFFF770).w
		rts	
; ===========================================================================

loc_D9F6:
		move.w	d6,($FFFFF76E).w
		movea.l	($FFFFF770).w,a0
		addi.w	#$280,d6

loc_DA02:
		cmp.w	(a0),d6
		bls.b	loc_DA16
		tst.b	4(a0)
		bpl.b	loc_DA10
		move.b	(a2),d2
		addq.b	#1,(a2)

loc_DA10:
		bsr.w	loc_DA3C
		beq.b	loc_DA02

loc_DA16:
		move.l	a0,($FFFFF770).w
		movea.l	($FFFFF774).w,a0
		subi.w	#$300,d6
		bcs.b	loc_DA36

loc_DA24:
		cmp.w	(a0),d6
		bls.b	loc_DA36
		tst.b	4(a0)
		bpl.b	loc_DA32
		addq.b	#1,1(a2)

loc_DA32:
		addq.w	#6,a0
		bra.b	loc_DA24
; ===========================================================================

loc_DA36:
		move.l	a0,($FFFFF774).w

locret_DA3A:
		rts	
; ===========================================================================

loc_DA3C:
		tst.b	4(a0)
		bpl.b	OPL_MakeItem
		bset	#7,2(a2,d2.w)
		beq.b	OPL_MakeItem
		addq.w	#6,a0
		moveq	#0,d0
		rts	
; ===========================================================================

OPL_MakeItem:
		bsr.w	actwkchk
		bne.b	locret_DA8A
		move.w	(a0)+,8(a1)
		move.w	(a0)+,d0
		move.w	d0,d1
		andi.w	#$FFF,d0
		move.w	d0,$C(a1)
		rol.w	#2,d1
		andi.b	#3,d1
		move.b	d1,1(a1)
		move.b	d1,cddat(a1)
		move.b	(a0)+,d0
		bpl.b	loc_DA80
		andi.b	#$7F,d0
		move.b	d2,cdsts(a1)

loc_DA80:
		move.b	d0,0(a1)
		move.b	(a0)+,userflag(a1)
		moveq	#0,d0

locret_DA8A:
		rts	
; ---------------------------------------------------------------------------
; Single object	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


actwkchk:
		lea	($FFFFD800).w,a1 ; start address for object RAM
		move.w	#$5F,d0

loc_DA94:
		tst.b	(a1)		; is object RAM	slot empty?
		beq.b	locret_DAA0	; if yes, branch
		lea	$40(a1),a1	; goto next object RAM slot
		dbra	d0,loc_DA94	; repeat $5F times

locret_DAA0:
		rts	
; End of function actwkchk


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


actwkchk2:
		movea.l	a0,a1
		move.w	#-$1000,d0
		sub.w	a0,d0
		lsr.w	#6,d0
		subq.w	#1,d0
		bcs.b	locret_DABC

loc_DAB0:
		tst.b	(a1)
		beq.b	locret_DABC
		lea	$40(a1),a1
		dbra	d0,loc_DAB0

locret_DABC:
		rts	
; End of function actwkchk2

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 41 - springs
; ---------------------------------------------------------------------------

sjump:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	sjump_Index(pc,d0.w),d1
		jsr	sjump_Index(pc,d1.w)
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
sjump_Index:	dc.w sjump_Main-sjump_Index
		dc.w sjump_Up-sjump_Index
		dc.w sjump_AniUp-sjump_Index
		dc.w sjump_ResetUp-sjump_Index
		dc.w sjump_LR-sjump_Index
		dc.w sjump_AniLR-sjump_Index
		dc.w sjump_ResetLR-sjump_Index
		dc.w sjump_Dwn-sjump_Index
		dc.w sjump_AniDwn-sjump_Index
		dc.w sjump_ResetDwn-sjump_Index

sjump_Powers:	dc.w -$1000		; power	of red spring
		dc.w -$A00		; power	of yellow spring
; ===========================================================================

sjump_Main:				; XREF: sjump_Index
		addq.b	#2,r_no0(a0)
		move.l	#sjumppat,4(a0)
		move.w	#$523,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	userflag(a0),d0
		btst	#4,d0		; does the spring face left/right?
		beq.b	loc_DB54	; if not, branch
		move.b	#8,r_no0(a0)	; use "sjump_LR" routine
		move.b	#1,$1C(a0)
		move.b	#3,$1A(a0)
		move.w	#$533,2(a0)
		move.b	#8,$19(a0)

loc_DB54:
		btst	#5,d0		; does the spring face downwards?
		beq.b	loc_DB66	; if not, branch
		move.b	#$E,r_no0(a0)	; use "sjump_Dwn" routine
		bset	#1,cddat(a0)

loc_DB66:
		btst	#1,d0
		beq.b	loc_DB72
		bset	#5,2(a0)

loc_DB72:
		andi.w	#$F,d0
		move.w	sjump_Powers(pc,d0.w),$30(a0)
		rts	
; ===========================================================================

sjump_Up:				; XREF: sjump_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		tst.b	r_no1(a0)		; is Sonic on top of the spring?
		bne.b	sjump_BounceUp	; if yes, branch
		rts	
; ===========================================================================

sjump_BounceUp:				; XREF: sjump_Up
		addq.b	#2,r_no0(a0)
		addq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)	; move Sonic upwards
		bset	#1,cddat(a1)
		bclr	#3,cddat(a1)
		move.b	#$10,$1C(a1)	; use "bouncing" animation
		move.b	#2,r_no0(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		move.w	#$CC,d0
		jsr	(soundset).l ;	play spring sound

sjump_AniUp:				; XREF: sjump_Index
		lea	(Ani_sjump).l,a1
		bra.w	patchg
; ===========================================================================

sjump_ResetUp:				; XREF: sjump_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,r_no0(a0)	; goto "sjump_Up" routine
		rts	
; ===========================================================================

sjump_LR:				; XREF: sjump_Index
		move.w	#$13,d1
		move.w	#$E,d2
		move.w	#$F,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		cmpi.b	#2,r_no0(a0)
		bne.b	loc_DC0C
		move.b	#8,r_no0(a0)

loc_DC0C:
		btst	#5,cddat(a0)
		bne.b	sjump_BounceLR
		rts	
; ===========================================================================

sjump_BounceLR:				; XREF: sjump_LR
		addq.b	#2,r_no0(a0)
		move.w	$30(a0),$10(a1)	; move Sonic to	the left
		addq.w	#8,8(a1)
		btst	#0,cddat(a0)	; is object flipped?
		bne.b	loc_DC36	; if yes, branch
		subi.w	#$10,8(a1)
		neg.w	$10(a1)		; move Sonic to	the right

loc_DC36:
		move.w	#$F,$3E(a1)
		move.w	$10(a1),$14(a1)
		bchg	#0,cddat(a1)
		btst	#2,cddat(a1)
		bne.b	loc_DC56
		move.b	#0,$1C(a1)	; use running animation

loc_DC56:
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)
		move.w	#$CC,d0
		jsr	(soundset).l ;	play spring sound

sjump_AniLR:				; XREF: sjump_Index
		lea	(Ani_sjump).l,a1
		bra.w	patchg
; ===========================================================================

sjump_ResetLR:				; XREF: sjump_Index
		move.b	#2,$1D(a0)	; reset	animation
		subq.b	#4,r_no0(a0)	; goto "sjump_LR" routine
		rts	
; ===========================================================================

sjump_Dwn:				; XREF: sjump_Index
		move.w	#$1B,d1
		move.w	#8,d2
		move.w	#$10,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		cmpi.b	#2,r_no0(a0)
		bne.b	loc_DCA4
		move.b	#$E,r_no0(a0)

loc_DCA4:
		tst.b	r_no1(a0)
		bne.b	locret_DCAE
		tst.w	d4
		bmi.b	sjump_BounceDwn

locret_DCAE:
		rts	
; ===========================================================================

sjump_BounceDwn:			; XREF: sjump_Dwn
		addq.b	#2,r_no0(a0)
		subq.w	#8,$C(a1)
		move.w	$30(a0),$12(a1)
		neg.w	$12(a1)		; move Sonic downwards
		bset	#1,cddat(a1)
		bclr	#3,cddat(a1)
		move.b	#2,r_no0(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		move.w	#$CC,d0
		jsr	(soundset).l ;	play spring sound

sjump_AniDwn:				; XREF: sjump_Index
		lea	(Ani_sjump).l,a1
		bra.w	patchg
; ===========================================================================

sjump_ResetDwn:				; XREF: sjump_Index
		move.b	#1,$1D(a0)	; reset	animation
		subq.b	#4,r_no0(a0)	; goto "sjump_Dwn" routine
		rts	
; ===========================================================================
Ani_sjump:
	include "_anim\sjump.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - springs
; ---------------------------------------------------------------------------
sjumppat:
	include "_maps\sjump.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 42 - Newtron enemy (GHZ)
; ---------------------------------------------------------------------------

kamere:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	kamere_Index(pc,d0.w),d1
		jmp	kamere_Index(pc,d1.w)
; ===========================================================================
kamere_Index:	dc.w kamere_Main-kamere_Index
		dc.w kamere_Action-kamere_Index
		dc.w kamere_Delete-kamere_Index
; ===========================================================================

kamere_Main:				; XREF: kamere_Index
		addq.b	#2,r_no0(a0)
		move.l	#kamerepat,4(a0)
		move.w	#$49B,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$14,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#8,$17(a0)

kamere_Action:				; XREF: kamere_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	kamere_Index2(pc,d0.w),d1
		jsr	kamere_Index2(pc,d1.w)
		lea	(Ani_kamere).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
kamere_Index2:	dc.w kamere_ChkDist-kamere_Index2
		dc.w kamere_Type00-kamere_Index2
		dc.w kamere_MatchFloor-kamere_Index2
		dc.w kamere_Speed-kamere_Index2
		dc.w kamere_Type01-kamere_Index2
; ===========================================================================

kamere_ChkDist:				; XREF: kamere_Index2
		bset	#0,cddat(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_DDEA
		neg.w	d0
		bclr	#0,cddat(a0)

loc_DDEA:
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of	the newtron?
		bcc.b	locret_DE12	; if not, branch
		addq.b	#2,r_no1(a0)
		move.b	#1,$1C(a0)
		tst.b	userflag(a0)		; check	object type
		beq.b	locret_DE12	; if type is 00, branch
		move.w	#$249B,2(a0)
		move.b	#8,r_no1(a0)	; run type 01 newtron subroutine
		move.b	#4,$1C(a0)	; use different	animation

locret_DE12:
		rts	
; ===========================================================================

kamere_Type00:				; XREF: kamere_Index2
		cmpi.b	#4,$1A(a0)	; has "appearing" animation finished?
		bcc.b	kamere_Fall	; is yes, branch
		bset	#0,cddat(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	locret_DE32
		bclr	#0,cddat(a0)

locret_DE32:
		rts	
; ===========================================================================

kamere_Fall:				; XREF: kamere_Type00
		cmpi.b	#1,$1A(a0)
		bne.b	loc_DE42
		move.b	#$C,colino(a0)

loc_DE42:
		bsr.w	speedset
		bsr.w	emycol_d
		tst.w	d1		; has newtron hit the floor?
		bpl.b	locret_DE86	; if not, branch
		add.w	d1,$C(a0)
		move.w	#0,$12(a0)	; stop newtron falling
		addq.b	#2,r_no1(a0)
		move.b	#2,$1C(a0)
		btst	#5,2(a0)
		beq.b	kamere_Move
		addq.b	#1,$1C(a0)

kamere_Move:
		move.b	#$D,colino(a0)
		move.w	#$200,$10(a0)	; move newtron horizontally
		btst	#0,cddat(a0)
		bne.b	locret_DE86
		neg.w	$10(a0)

locret_DE86:
		rts	
; ===========================================================================

kamere_MatchFloor:			; XREF: kamere_Index2
		bsr.w	speedset2
		bsr.w	emycol_d
		cmpi.w	#-8,d1
		blt.b	loc_DEA2
		cmpi.w	#$C,d1
		bge.b	loc_DEA2
		add.w	d1,$C(a0)	; match	newtron's position with floor
		rts	
; ===========================================================================

loc_DEA2:
		addq.b	#2,r_no1(a0)
		rts	
; ===========================================================================

kamere_Speed:				; XREF: kamere_Index2
		bsr.w	speedset2
		rts	
; ===========================================================================

kamere_Type01:				; XREF: kamere_Index2
		cmpi.b	#1,$1A(a0)
		bne.b	kamere_FireMissile
		move.b	#$C,colino(a0)

kamere_FireMissile:
		cmpi.b	#2,$1A(a0)
		bne.b	locret_DF14
		tst.b	$32(a0)
		bne.b	locret_DF14
		move.b	#1,$32(a0)
		bsr.w	actwkchk
		bne.b	locret_DF14
		move.b	#$23,0(a1)	; load missile object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		subq.w	#8,$C(a1)
		move.w	#$200,$10(a1)
		move.w	#$14,d0
		btst	#0,cddat(a0)
		bne.b	loc_DF04
		neg.w	d0
		neg.w	$10(a1)

loc_DF04:
		add.w	d0,8(a1)
		move.b	cddat(a0),cddat(a1)
		move.b	#1,userflag(a1)

locret_DF14:
		rts	
; ===========================================================================

kamere_Delete:				; XREF: kamere_Index
		bra.w	frameout
; ===========================================================================
Ani_kamere:
	include "_anim\kamere.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Newtron enemy (GHZ)
; ---------------------------------------------------------------------------
kamerepat:
	include "_maps\kamere.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 43 - Roller enemy (SYZ)
; ---------------------------------------------------------------------------

aruma:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	aruma_Index(pc,d0.w),d1
		jmp	aruma_Index(pc,d1.w)
; ===========================================================================
aruma_Index:	dc.w aruma_Main-aruma_Index
		dc.w aruma_Action-aruma_Index
; ===========================================================================

aruma_Main:				; XREF: aruma_Index
		move.b	#$E,$16(a0)
		move.b	#8,$17(a0)
		bsr.w	speedset
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_E052
		add.w	d1,$C(a0)	; match	roller's position with the floor
		move.w	#0,$12(a0)
		addq.b	#2,r_no0(a0)
		move.l	#Map_aruma,4(a0)
		move.w	#$4B8,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$10,$19(a0)

locret_E052:
		rts	
; ===========================================================================

aruma_Action:				; XREF: aruma_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	aruma_Index2(pc,d0.w),d1
		jsr	aruma_Index2(pc,d1.w)
		lea	(Ani_aruma).l,a1
		bsr.w	patchg
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bgt.w	aruma_ChkGone
		bra.w	actionsub
; ===========================================================================

aruma_ChkGone:				; XREF: aruma_Action
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	aruma_Delete
		bclr	#7,2(a2,d0.w)

aruma_Delete:
		bra.w	frameout
; ===========================================================================
aruma_Index2:	dc.w aruma_RollChk-aruma_Index2
		dc.w aruma_RollNoChk-aruma_Index2
		dc.w aruma_ChkJump-aruma_Index2
		dc.w aruma_MatchFloor-aruma_Index2
; ===========================================================================

aruma_RollChk:				; XREF: aruma_Index2
		move.w	playerwk+xposi,d0
		subi.w	#$100,d0
		bcs.b	loc_E0D2
		sub.w	8(a0),d0	; check	distance between Roller	and Sonic
		bcs.b	loc_E0D2
		addq.b	#4,r_no1(a0)
		move.b	#2,$1C(a0)
		move.w	#$700,$10(a0)	; move Roller horizontally
		move.b	#$8E,colino(a0)	; make Roller invincible

loc_E0D2:
		addq.l	#4,sp
		rts	
; ===========================================================================

aruma_RollNoChk:			; XREF: aruma_Index2
		cmpi.b	#2,$1C(a0)
		beq.b	loc_E0F8
		subq.w	#1,$30(a0)
		bpl.b	locret_E0F6
		move.b	#1,$1C(a0)
		move.w	#$700,$10(a0)
		move.b	#$8E,colino(a0)

locret_E0F6:
		rts	
; ===========================================================================

loc_E0F8:
		addq.b	#2,r_no1(a0)
		rts	
; ===========================================================================

aruma_ChkJump:				; XREF: aruma_Index2
		bsr.w	aruma_Stop
		bsr.w	speedset2
		bsr.w	emycol_d
		cmpi.w	#-8,d1
		blt.b	aruma_Jump
		cmpi.w	#$C,d1
		bge.b	aruma_Jump
		add.w	d1,$C(a0)
		rts	
; ===========================================================================

aruma_Jump:
		addq.b	#2,r_no1(a0)
		bset	#0,$32(a0)
		beq.b	locret_E12E
		move.w	#-$600,$12(a0)	; move Roller vertically

locret_E12E:
		rts	
; ===========================================================================

aruma_MatchFloor:			; XREF: aruma_Index2
		bsr.w	speedset
		tst.w	$12(a0)
		bmi.b	locret_E150
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_E150
		add.w	d1,$C(a0)	; match	Roller's position with the floor
		subq.b	#2,r_no1(a0)
		move.w	#0,$12(a0)

locret_E150:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


aruma_Stop:				; XREF: aruma_ChkJump
		tst.b	$32(a0)
		bmi.b	locret_E188
		move.w	playerwk+xposi,d0
		subi.w	#$30,d0
		sub.w	8(a0),d0
		bcc.b	locret_E188
		move.b	#0,$1C(a0)
		move.b	#$E,colino(a0)
		clr.w	$10(a0)
		move.w	#120,$30(a0)	; set waiting time to 2	seconds
		move.b	#2,r_no1(a0)
		bset	#7,$32(a0)

locret_E188:
		rts	
; End of function aruma_Stop

; ===========================================================================
Ani_aruma:
	include "_anim\aruma.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Roller enemy (SYZ)
; ---------------------------------------------------------------------------
Map_aruma:
	include "_maps\aruma.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 44 - walls (GHZ)
; ---------------------------------------------------------------------------

kageb:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	kageb_Index(pc,d0.w),d1
		jmp	kageb_Index(pc,d1.w)
; ===========================================================================
kageb_Index:	dc.w kageb_Main-kageb_Index
		dc.w kageb_Solid-kageb_Index
		dc.w kageb_Display-kageb_Index
; ===========================================================================

kageb_Main:				; XREF: kageb_Index
		addq.b	#2,r_no0(a0)
		move.l	#kagebpat,4(a0)
		move.w	#$434C,2(a0)
		ori.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#6,$18(a0)
		move.b	userflag(a0),$1A(a0)	; copy object type number to frame number
		bclr	#4,$1A(a0)	; clear	4th bit	(deduct	$10)
		beq.b	kageb_Solid	; make object solid if 4th bit = 0
		addq.b	#2,r_no0(a0)
		bra.b	kageb_Display	; don't make it solid if 4th bit = 1
; ===========================================================================

kageb_Solid:				; XREF: kageb_Index
		move.w	#$13,d1
		move.w	#$28,d2
		bsr.w	kageb_SolidWall

kageb_Display:				; XREF: kageb_Index
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - walls (GHZ)
; ---------------------------------------------------------------------------
kagebpat:
	include "_maps\kageb.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 13 - lava ball	producer (MZ, SLZ)
; ---------------------------------------------------------------------------

mfire:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	mfire_Index(pc,d0.w),d1
		jsr	mfire_Index(pc,d1.w)
		bra.w	fire_ChkDel
; ===========================================================================
mfire_Index:	dc.w mfire_Main-mfire_Index
		dc.w mfire_MakeLava-mfire_Index
; ---------------------------------------------------------------------------
;
; Lava ball production rates
;
mfire_Rates:	dc.b 30, 60, 90, 120, 150, 180
; ===========================================================================

mfire_Main:				; XREF: mfire_Index
		addq.b	#2,r_no0(a0)
		move.b	userflag(a0),d0
		lsr.w	#4,d0
		andi.w	#$F,d0
		move.b	mfire_Rates(pc,d0.w),$1F(a0)
		move.b	$1F(a0),$1E(a0)	; set time delay for lava balls
		andi.b	#$F,userflag(a0)

mfire_MakeLava:				; XREF: mfire_Index
		subq.b	#1,$1E(a0)	; subtract 1 from time delay
		bne.b	locret_E302	; if time still	remains, branch
		move.b	$1F(a0),$1E(a0)	; reset	time delay
		bsr.w	ChkObjOnScreen
		bne.b	locret_E302
		bsr.w	actwkchk
		bne.b	locret_E302
		move.b	#$14,0(a1)	; load lava ball object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	userflag(a0),userflag(a1)

locret_E302:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 14 - lava balls (MZ, SLZ)
; ---------------------------------------------------------------------------

fire:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fire_Index(pc,d0.w),d1
		jsr	fire_Index(pc,d1.w)
		bra.w	actionsub
; ===========================================================================
fire_Index:	dc.w fire_Main-fire_Index
		dc.w fire_Action-fire_Index
		dc.w fire_Delete-fire_Index

fire_Speeds:	dc.w $FC00, $FB00, $FA00, $F900, $FE00
		dc.w $200, $FE00, $200,	0
; ===========================================================================

fire_Main:				; XREF: fire_Index
		addq.b	#2,r_no0(a0)
		move.b	#8,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_fire,4(a0)
		move.w	#$345,2(a0)
		cmpi.b	#3,stageno ; check if level is SLZ
		bne.b	loc_E35A
		move.w	#$480,2(a0)	; SLZ specific code

loc_E35A:
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$8B,colino(a0)
		move.w	$C(a0),$30(a0)
		tst.b	$29(a0)
		beq.b	fire_SetSpeed
		addq.b	#2,$18(a0)

fire_SetSpeed:
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	fire_Speeds(pc,d0.w),$12(a0) ;	load object speed (vertical)
		move.b	#8,$19(a0)
		cmpi.b	#6,userflag(a0)	; is object type below $6 ?
		bcs.b	fire_PlaySnd	; if yes, branch
		move.b	#$10,$19(a0)
		move.b	#2,$1C(a0)	; use horizontal animation
		move.w	$12(a0),$10(a0)	; set horizontal speed
		move.w	#0,$12(a0)	; delete vertical speed

fire_PlaySnd:
		move.w	#$AE,d0
		jsr	(soundset).l ;	play lava ball sound

fire_Action:				; XREF: fire_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	fire_TypeIndex(pc,d0.w),d1
		jsr	fire_TypeIndex(pc,d1.w)
		bsr.w	speedset2
		lea	(Ani_fire).l,a1
		bsr.w	patchg

fire_ChkDel:				; XREF: mfire
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
fire_TypeIndex:dc.w fire_Type00-fire_TypeIndex, fire_Type00-fire_TypeIndex
		dc.w fire_Type00-fire_TypeIndex, fire_Type00-fire_TypeIndex
		dc.w fire_Type04-fire_TypeIndex, fire_Type05-fire_TypeIndex
		dc.w fire_Type06-fire_TypeIndex, fire_Type07-fire_TypeIndex
		dc.w fire_Type08-fire_TypeIndex
; ===========================================================================
; lavaball types 00-03 fly up and fall back down

fire_Type00:				; XREF: fire_TypeIndex
		addi.w	#$18,$12(a0)	; increase object's downward speed
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0	; has object fallen back to its	original position?
		bcc.b	loc_E41E	; if not, branch
		addq.b	#2,r_no0(a0)	; goto "fire_Delete" routine

loc_E41E:
		bclr	#1,cddat(a0)
		tst.w	$12(a0)
		bpl.b	locret_E430
		bset	#1,cddat(a0)

locret_E430:
		rts	
; ===========================================================================
; lavaball type	04 flies up until it hits the ceiling

fire_Type04:				; XREF: fire_TypeIndex
		bset	#1,cddat(a0)
		bsr.w	ObjHitCeiling
		tst.w	d1
		bpl.b	locret_E452
		move.b	#8,userflag(a0)
		move.b	#1,$1C(a0)
		move.w	#0,$12(a0)	; stop the object when it touches the ceiling

locret_E452:
		rts	
; ===========================================================================
; lavaball type	05 falls down until it hits the	floor

fire_Type05:				; XREF: fire_TypeIndex
		bclr	#1,cddat(a0)
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_E474
		move.b	#8,userflag(a0)
		move.b	#1,$1C(a0)
		move.w	#0,$12(a0)	; stop the object when it touches the floor

locret_E474:
		rts	
; ===========================================================================
; lavaball types 06-07 move sideways

fire_Type06:				; XREF: fire_TypeIndex
		bset	#0,cddat(a0)
		moveq	#-8,d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bpl.b	locret_E498
		move.b	#8,userflag(a0)
		move.b	#3,$1C(a0)
		move.w	#0,$10(a0)	; stop object when it touches a	wall

locret_E498:
		rts	
; ===========================================================================

fire_Type07:				; XREF: fire_TypeIndex
		bclr	#0,cddat(a0)
		moveq	#8,d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bpl.b	locret_E4BC
		move.b	#8,userflag(a0)
		move.b	#3,$1C(a0)
		move.w	#0,$10(a0)	; stop object when it touches a	wall

locret_E4BC:
		rts	
; ===========================================================================

fire_Type08:				; XREF: fire_TypeIndex
		rts	
; ===========================================================================

fire_Delete:				; XREF: fire_Index
		bra.w	frameout
; ===========================================================================
Ani_fire:
	include "_anim\fire.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6D - flame thrower (SBZ)
; ---------------------------------------------------------------------------

fire6:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fire6_Index(pc,d0.w),d1
		jmp	fire6_Index(pc,d1.w)
; ===========================================================================
fire6_Index:	dc.w fire6_Main-fire6_Index
		dc.w fire6_Action-fire6_Index
; ===========================================================================

fire6_Main:				; XREF: fire6_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_fire6,4(a0)
		move.w	#$83D9,2(a0)
		ori.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.w	$C(a0),$30(a0)
		move.b	#$C,$19(a0)
		move.b	userflag(a0),d0
		andi.w	#$F0,d0		; read 1st digit of object type
		add.w	d0,d0		; multiply by 2
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)	; set flaming time
		move.b	userflag(a0),d0
		andi.w	#$F,d0		; read 2nd digit of object type
		lsl.w	#5,d0		; multiply by $20
		move.w	d0,$34(a0)	; set pause time
		move.b	#$A,$36(a0)
		btst	#1,cddat(a0)
		beq.b	fire6_Action
		move.b	#2,$1C(a0)
		move.b	#$15,$36(a0)

fire6_Action:				; XREF: fire6_Index
		subq.w	#1,$30(a0)	; subtract 1 from time
		bpl.b	loc_E57A	; if time remains, branch
		move.w	$34(a0),$30(a0)	; begin	pause time
		bchg	#0,$1C(a0)
		beq.b	loc_E57A
		move.w	$32(a0),$30(a0)	; begin	flaming	time
		move.w	#$B3,d0
		jsr	(soundset).l ;	play flame sound

loc_E57A:
		lea	(Ani_fire6).l,a1
		bsr.w	patchg
		move.b	#0,colino(a0)
		move.b	$36(a0),d0
		cmp.b	$1A(a0),d0
		bne.b	fire6_ChkDel
		move.b	#$A3,colino(a0)

fire6_ChkDel:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
Ani_fire6:
	include "_anim\fire6.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - flame thrower (SBZ)
; ---------------------------------------------------------------------------
Map_fire6:
	include "_maps\fire6.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 46 - solid blocks and blocks that fall	from the ceiling (MZ)
; ---------------------------------------------------------------------------

fblock:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fblock_Index(pc,d0.w),d1
		jmp	fblock_Index(pc,d1.w)
; ===========================================================================
fblock_Index:	dc.w fblock_Main-fblock_Index
		dc.w fblock_Action-fblock_Index
; ===========================================================================

fblock_Main:				; XREF: fblock_Index
		addq.b	#2,r_no0(a0)
		move.b	#$F,$16(a0)
		move.b	#$F,$17(a0)
		move.l	#Map_fblock,4(a0)
		move.w	#$4000,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$10,$19(a0)
		move.w	$C(a0),$30(a0)
		move.w	#$5C0,$32(a0)

fblock_Action:				; XREF: fblock_Index
		tst.b	1(a0)
		bpl.b	fblock_ChkDel
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		andi.w	#7,d0		; read only the	1st digit
		add.w	d0,d0
		move.w	fblock_TypeIndex(pc,d0.w),d1
		jsr	fblock_TypeIndex(pc,d1.w)
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	hitchk

fblock_ChkDel:
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
fblock_TypeIndex:dc.w fblock_Type00-fblock_TypeIndex
		dc.w fblock_Type01-fblock_TypeIndex
		dc.w fblock_Type02-fblock_TypeIndex
		dc.w fblock_Type03-fblock_TypeIndex
		dc.w fblock_Type04-fblock_TypeIndex
; ===========================================================================

fblock_Type00:				; XREF: fblock_TypeIndex
		rts	
; ===========================================================================

fblock_Type02:				; XREF: fblock_TypeIndex
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_E888
		neg.w	d0

loc_E888:
		cmpi.w	#$90,d0		; is Sonic within $90 pixels of	the block?
		bcc.b	fblock_Type01	; if not, resume wobbling
		move.b	#3,userflag(a0)	; if yes, make the block fall

fblock_Type01:				; XREF: fblock_TypeIndex
		moveq	#0,d0
		move.b	($FFFFFE74).w,d0
		btst	#3,userflag(a0)
		beq.b	loc_E8A8
		neg.w	d0
		addi.w	#$10,d0

loc_E8A8:
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; update the block's position to make it wobble
		rts	
; ===========================================================================

fblock_Type03:				; XREF: fblock_TypeIndex
		bsr.w	speedset2
		addi.w	#$18,$12(a0)	; increase falling speed
		bsr.w	emycol_d
		tst.w	d1		; has the block	hit the	floor?
		bpl.w	locret_E8EE	; if not, branch
		add.w	d1,$C(a0)
		clr.w	$12(a0)		; stop the block falling
		move.w	$C(a0),$30(a0)
		move.b	#4,userflag(a0)
		move.w	(a1),d0
		andi.w	#$3FF,d0
		cmpi.w	#$2E8,d0
		bcc.b	locret_E8EE
		move.b	#0,userflag(a0)

locret_E8EE:
		rts	
; ===========================================================================

fblock_Type04:				; XREF: fblock_TypeIndex
		moveq	#0,d0
		move.b	($FFFFFE70).w,d0
		lsr.w	#3,d0
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; make the block wobble
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - solid blocks and blocks that fall from the ceiling (MZ)
; ---------------------------------------------------------------------------
Map_fblock:
	include "_maps\fblock.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 12 - lamp (SYZ)
; ---------------------------------------------------------------------------

signal:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	signal_Index(pc,d0.w),d1
		jmp	signal_Index(pc,d1.w)
; ===========================================================================
signal_Index:	dc.w signal_Main-signal_Index
		dc.w signal_Animate-signal_Index
; ===========================================================================

signal_Main:				; XREF: signal_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_signal,4(a0)
		move.w	#0,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#6,$18(a0)

signal_Animate:				; XREF: signal_Index
		subq.b	#1,$1E(a0)
		bpl.b	signal_ChkDel
		move.b	#7,$1E(a0)
		addq.b	#1,$1A(a0)
		cmpi.b	#6,$1A(a0)
		bcs.b	signal_ChkDel
		move.b	#0,$1A(a0)

signal_ChkDel:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - lamp (SYZ)
; ---------------------------------------------------------------------------
Map_signal:
	include "_maps\signal.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 47 - pinball bumper (SYZ)
; ---------------------------------------------------------------------------

bobin:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bobin_Index(pc,d0.w),d1
		jmp	bobin_Index(pc,d1.w)
; ===========================================================================
bobin_Index:	dc.w bobin_Main-bobin_Index
		dc.w bobin_Hit-bobin_Index
; ===========================================================================

bobin_Main:				; XREF: bobin_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_bobin,4(a0)
		move.w	#$380,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	#$D7,colino(a0)

bobin_Hit:				; XREF: bobin_Index
		tst.b	colicnt(a0)		; has Sonic touched the	bumper?
		beq.w	bobin_Display	; if not, branch
		clr.b	colicnt(a0)
		lea	playerwk,a1
		move.w	8(a0),d1
		move.w	$C(a0),d2
		sub.w	8(a1),d1
		sub.w	$C(a1),d2
		jsr	(atan).l
		jsr	(sinset).l
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,$10(a1)	; bounce Sonic away
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,$12(a1)	; bounce Sonic away
		bset	#1,cddat(a1)
		bclr	#4,cddat(a1)
		bclr	#5,cddat(a1)
		clr.b	$3C(a1)
		move.b	#1,$1C(a0)
		move.w	#$B4,d0
		jsr	(soundset).l ;	play bumper sound
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	bobin_Score
		cmpi.b	#$8A,2(a2,d0.w)	; has bumper been hit $8A times?
		bcc.b	bobin_Display	; if yes, Sonic	gets no	points
		addq.b	#1,2(a2,d0.w)

bobin_Score:
		moveq	#1,d0
		jsr	scoreup	; add 10 to score
		bsr.w	actwkchk
		bne.b	bobin_Display
		move.b	#$29,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#4,$1A(a1)

bobin_Display:
		lea	(Ani_bobin).l,a1
		bsr.w	patchg
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	bobin_ChkHit
		bra.w	actionsub
; ===========================================================================

bobin_ChkHit:				; XREF: bobin_Display
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	bobin_Delete
		bclr	#7,2(a2,d0.w)

bobin_Delete:
		bra.w	frameout
; ===========================================================================
Ani_bobin:
	include "_anim\bobin.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - pinball bumper (SYZ)
; ---------------------------------------------------------------------------
Map_bobin:
	include "_maps\bobin.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0D - signpost at the end of a level
; ---------------------------------------------------------------------------

gole:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	gole_Index(pc,d0.w),d1
		jsr	gole_Index(pc,d1.w)
		lea	(Ani_gole).l,a1
		bsr.w	patchg
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
gole_Index:	dc.w gole_Main-gole_Index
		dc.w gole_Touch-gole_Index
		dc.w gole_Spin-gole_Index
		dc.w gole_SonicRun-gole_Index
		dc.w locret_ED1A-gole_Index
; ===========================================================================

gole_Main:				; XREF: gole_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_gole,4(a0)
		move.w	#$680,2(a0)
		move.b	#4,1(a0)
		move.b	#$18,$19(a0)
		move.b	#4,$18(a0)

gole_Touch:				; XREF: gole_Index
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcs.b	locret_EBBA
		cmpi.w	#$20,d0		; is Sonic within $20 pixels of	the signpost?
		bcc.b	locret_EBBA	; if not, branch
		move.w	#$CF,d0
		jsr	(bgmset).l	; play signpost	sound
		clr.b	pltime_f	; stop time counter
		move.w	scralim_right,scralim_left ; lock screen position
		addq.b	#2,r_no0(a0)

locret_EBBA:
		rts	
; ===========================================================================

gole_Spin:				; XREF: gole_Index
		subq.w	#1,$30(a0)	; subtract 1 from spin time
		bpl.b	gole_Sparkle	; if time remains, branch
		move.w	#60,$30(a0)	; set spin cycle time to 1 second
		addq.b	#1,$1C(a0)	; next spin cycle
		cmpi.b	#3,$1C(a0)	; have 3 spin cycles completed?
		bne.b	gole_Sparkle	; if not, branch
		addq.b	#2,r_no0(a0)

gole_Sparkle:
		subq.w	#1,$32(a0)	; subtract 1 from time delay
		bpl.b	locret_EC42	; if time remains, branch
		move.w	#$B,$32(a0)	; set time between sparkles to $B frames
		moveq	#0,d0
		move.b	$34(a0),d0
		addq.b	#2,$34(a0)
		andi.b	#$E,$34(a0)
		lea	gole_SparkPos(pc,d0.w),a2 ; load sparkle position data
		bsr.w	actwkchk
		bne.b	locret_EC42
		move.b	#$25,0(a1)	; load rings object
		move.b	#6,r_no0(a1)	; jump to ring sparkle subroutine
		move.b	(a2)+,d0
		ext.w	d0
		add.w	8(a0),d0
		move.w	d0,8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		move.l	#ringpat,4(a1)
		move.w	#$27B2,2(a1)
		move.b	#4,1(a1)
		move.b	#2,$18(a1)
		move.b	#8,$19(a1)

locret_EC42:
		rts	
; ===========================================================================
gole_SparkPos:	dc.b -$18,-$10		; x-position, y-position
		dc.b	8,   8
		dc.b -$10,   0
		dc.b  $18,  -8
		dc.b	0,  -8
		dc.b  $10,   0
		dc.b -$18,   8
		dc.b  $18, $10
; ===========================================================================

gole_SonicRun:				; XREF: gole_Index
		tst.w	editmode	; is debug mode	on?
		bne.w	locret_ECEE	; if yes, branch
		btst	#1,playerwk+cddat
		bne.b	loc_EC70
		move.b	#1,plautoflag ; lock	controls
		move.w	#$800,swdata+0 ; make Sonic run to	the right

loc_EC70:
		tst.b	playerwk
		beq.b	loc_EC86
		move.w	playerwk+xposi,d0
		move.w	scralim_right,d1
		addi.w	#$128,d1
		cmp.w	d1,d0
		bcs.b	locret_ECEE

loc_EC86:
		addq.b	#2,r_no0(a0)

; ---------------------------------------------------------------------------
; Subroutine to	set up bonuses at the end of an	act
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


GotThroughAct:				; XREF: masin_EndAct
		tst.b	($FFFFD5C0).w
		bne.b	locret_ECEE
		move.w	scralim_right,scralim_left
		clr.b	plpower_m	; disable invincibility
		clr.b	pltime_f	; stop time counter
		move.b	#$3A,($FFFFD5C0).w
		moveq	#$10,d0
		jsr	(LoadPLC2).l	; load title card patterns
		move.b	#1,($FFFFF7D6).w
		moveq	#0,d0
		move.b	($FFFFFE23).w,d0
		mulu.w	#60,d0		; convert minutes to seconds
		moveq	#0,d1
		move.b	pltime+2,d1
		add.w	d1,d0		; add up your time
		divu.w	#15,d0		; divide by 15
		moveq	#$14,d1
		cmp.w	d1,d0		; is time 5 minutes or higher?
		bcs.b	loc_ECD0	; if not, branch
		move.w	d1,d0		; use minimum time bonus (0)

loc_ECD0:
		add.w	d0,d0
		move.w	TimeBonuses(pc,d0.w),($FFFFF7D2).w ; set time bonus
		move.w	plring,d0 ; load	number of rings
		mulu.w	#10,d0		; multiply by 10
		move.w	d0,($FFFFF7D4).w ; set ring bonus
		move.w	#$8E,d0
		jsr	(soundset).l ;	play "Sonic got	through" music

locret_ECEE:
		rts	
; End of function GotThroughAct

; ===========================================================================
TimeBonuses:	dc.w 5000, 5000, 1000, 500, 400, 400, 300, 300,	200, 200
		dc.w 200, 200, 100, 100, 100, 100, 50, 50, 50, 50, 0
; ===========================================================================

locret_ED1A:				; XREF: gole_Index
		rts	
; ===========================================================================
Ani_gole:
	include "_anim\gole.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - signpost
; ---------------------------------------------------------------------------
Map_gole:
	include "_maps\gole.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4C - lava geyser / lavafall producer (MZ)
; ---------------------------------------------------------------------------

myogan:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	myogan_Index(pc,d0.w),d1
		jsr	myogan_Index(pc,d1.w)
		bra.w	yogan_ChkDel
; ===========================================================================
myogan_Index:	dc.w myogan_Main-myogan_Index
		dc.w loc_EDCC-myogan_Index
		dc.w loc_EE3E-myogan_Index
		dc.w myogan_MakeLava-myogan_Index
		dc.w myogan_Display-myogan_Index
		dc.w myogan_Delete-myogan_Index
; ===========================================================================

myogan_Main:				; XREF: myogan_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_myogan,4(a0)
		move.w	#$E3A8,2(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$38,$19(a0)
		move.w	#120,$34(a0)	; set time delay to 2 seconds

loc_EDCC:				; XREF: myogan_Index
		subq.w	#1,$32(a0)
		bpl.b	locret_EDF0
		move.w	$34(a0),$32(a0)
		move.w	playerwk+yposi,d0
		move.w	$C(a0),d1
		cmp.w	d1,d0
		bcc.b	locret_EDF0
		subi.w	#$170,d1
		cmp.w	d1,d0
		bcs.b	locret_EDF0
		addq.b	#2,r_no0(a0)

locret_EDF0:
		rts	
; ===========================================================================

myogan_MakeLava:				; XREF: myogan_Index
		addq.b	#2,r_no0(a0)
		bsr.w	actwkchk2
		bne.b	loc_EE18
		move.b	#$4D,0(a1)	; load lavafall	object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	userflag(a0),userflag(a1)
		move.l	a0,$3C(a1)

loc_EE18:
		move.b	#1,$1C(a0)
		tst.b	userflag(a0)		; is object type 00 (geyser) ?
		beq.b	myogan_Type00	; if yes, branch
		move.b	#4,$1C(a0)
		bra.b	myogan_Display
; ===========================================================================

myogan_Type00:				; XREF: myogan_MakeLava
		movea.l	$3C(a0),a1	; load geyser object
		bset	#1,cddat(a1)
		move.w	#-$580,$12(a1)
		bra.b	myogan_Display
; ===========================================================================

loc_EE3E:				; XREF: myogan_Index
		tst.b	userflag(a0)		; is object type 00 (geyser) ?
		beq.b	myogan_Display	; if yes, branch
		addq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

myogan_Display:				; XREF: myogan_Index
		lea	(Ani_myogan).l,a1
		bsr.w	patchg
		bsr.w	actionsub
		rts	
; ===========================================================================

myogan_Delete:				; XREF: myogan_Index
		move.b	#0,$1C(a0)
		move.b	#2,r_no0(a0)
		tst.b	userflag(a0)
		beq.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4D - lava geyser / lavafall (MZ)
; ---------------------------------------------------------------------------

yogan:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yogan_Index(pc,d0.w),d1
		jsr	yogan_Index(pc,d1.w)
		bra.w	actionsub
; ===========================================================================
yogan_Index:	dc.w yogan_Main-yogan_Index
		dc.w yogan_Action-yogan_Index
		dc.w loc_EFFC-yogan_Index
		dc.w yogan_Delete-yogan_Index

yogan_Speeds:	dc.w $FB00, 0
; ===========================================================================

yogan_Main:				; XREF: yogan_Index
		addq.b	#2,r_no0(a0)
		move.w	$C(a0),$30(a0)
		tst.b	userflag(a0)
		beq.b	loc_EEA4
		subi.w	#$250,$C(a0)

loc_EEA4:
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	yogan_Speeds(pc,d0.w),$12(a0)
		movea.l	a0,a1
		moveq	#1,d1
		bsr.b	yogan_MakeLava
		bra.b	loc_EF10
; ===========================================================================

yogan_Loop:
		bsr.w	actwkchk2
		bne.b	loc_EF0A

yogan_MakeLava:				; XREF: yogan_Main
		move.b	#$4D,0(a1)
		move.l	#Map_myogan,4(a1)
		move.w	#$63A8,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	userflag(a0),userflag(a1)
		move.b	#1,$18(a1)
		move.b	#5,$1C(a1)
		tst.b	userflag(a0)
		beq.b	loc_EF0A
		move.b	#2,$1C(a1)

loc_EF0A:
		dbra	d1,yogan_Loop
		rts	
; ===========================================================================

loc_EF10:				; XREF: yogan_Main
		addi.w	#$60,$C(a1)
		move.w	$30(a0),$30(a1)
		addi.w	#$60,$30(a1)
		move.b	#$93,colino(a1)
		move.b	#$80,$16(a1)
		bset	#4,1(a1)
		addq.b	#4,r_no0(a1)
		move.l	a0,$3C(a1)
		tst.b	userflag(a0)
		beq.b	yogan_PlaySnd
		moveq	#0,d1
		bsr.w	yogan_Loop
		addq.b	#2,r_no0(a1)
		bset	#4,2(a1)
		addi.w	#$100,$C(a1)
		move.b	#0,$18(a1)
		move.w	$30(a0),$30(a1)
		move.l	$3C(a0),$3C(a1)
		move.b	#0,userflag(a0)

yogan_PlaySnd:
		move.w	#$C8,d0
		jsr	(soundset).l ;	play flame sound

yogan_Action:				; XREF: yogan_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	yogan_TypeIndex(pc,d0.w),d1
		jsr	yogan_TypeIndex(pc,d1.w)
		bsr.w	speedset2
		lea	(Ani_myogan).l,a1
		bsr.w	patchg

yogan_ChkDel:				; XREF: myogan
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
yogan_TypeIndex:dc.w yogan_Type00-yogan_TypeIndex
		dc.w yogan_Type01-yogan_TypeIndex
; ===========================================================================

yogan_Type00:				; XREF: yogan_TypeIndex
		addi.w	#$18,$12(a0)	; increase object's falling speed
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0
		bcc.b	locret_EFDA
		addq.b	#4,r_no0(a0)
		movea.l	$3C(a0),a1
		move.b	#3,$1C(a1)

locret_EFDA:
		rts	
; ===========================================================================

yogan_Type01:				; XREF: yogan_TypeIndex
		addi.w	#$18,$12(a0)	; increase object's falling speed
		move.w	$30(a0),d0
		cmp.w	$C(a0),d0
		bcc.b	locret_EFFA
		addq.b	#4,r_no0(a0)
		movea.l	$3C(a0),a1
		move.b	#1,$1C(a1)

locret_EFFA:
		rts	
; ===========================================================================

loc_EFFC:				; XREF: yogan_Index
		movea.l	$3C(a0),a1
		cmpi.b	#6,r_no0(a1)
		beq.w	yogan_Delete
		move.w	$C(a1),d0
		addi.w	#$60,d0
		move.w	d0,$C(a0)
		sub.w	$30(a0),d0
		neg.w	d0
		moveq	#8,d1
		cmpi.w	#$40,d0
		bge.b	loc_F026
		moveq	#$B,d1

loc_F026:
		cmpi.w	#$80,d0
		ble.b	loc_F02E
		moveq	#$E,d1

loc_F02E:
		subq.b	#1,$1E(a0)
		bpl.b	loc_F04C
		move.b	#7,$1E(a0)
		addq.b	#1,$1B(a0)
		cmpi.b	#2,$1B(a0)
		bcs.b	loc_F04C
		move.b	#0,$1B(a0)

loc_F04C:
		move.b	$1B(a0),d0
		add.b	d1,d0
		move.b	d0,$1A(a0)
		bra.w	yogan_ChkDel
; ===========================================================================

yogan_Delete:				; XREF: yogan_Index
		bra.w	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4E - advancing	wall of	lava (MZ)
; ---------------------------------------------------------------------------

yogan2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yogan2_Index(pc,d0.w),d1
		jmp	yogan2_Index(pc,d1.w)
; ===========================================================================
yogan2_Index:	dc.w yogan2_Main-yogan2_Index
		dc.w yogan2_Solid-yogan2_Index
		dc.w yogan2_Action-yogan2_Index
		dc.w yogan2_Move2-yogan2_Index
		dc.w yogan2_Delete-yogan2_Index
; ===========================================================================

yogan2_Main:				; XREF: yogan2_Index
		addq.b	#4,r_no0(a0)
		movea.l	a0,a1
		moveq	#1,d1
		bra.b	yogan2_Main2
; ===========================================================================

yogan2_Loop:
		bsr.w	actwkchk2
		bne.b	loc_F0C8

yogan2_Main2:				; XREF: yogan2_Main
		move.b	#$4E,0(a1)	; load object
		move.l	#Map_yogan2,4(a1)
		move.w	#$63A8,2(a1)
		move.b	#4,1(a1)
		move.b	#$50,$19(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#1,$18(a1)
		move.b	#0,$1C(a1)
		move.b	#$94,colino(a1)
		move.l	a0,$3C(a1)

loc_F0C8:
		dbra	d1,yogan2_Loop	; repeat sequence once

		addq.b	#6,r_no0(a1)
		move.b	#4,$1A(a1)

yogan2_Action:				; XREF: yogan2_Index
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	yogan2_ChkSonic
		neg.w	d0

yogan2_ChkSonic:
		cmpi.w	#$C0,d0		; is Sonic within $C0 pixels (x-axis)?
		bcc.b	yogan2_Move	; if not, branch
		move.w	playerwk+yposi,d0
		sub.w	$C(a0),d0
		bcc.b	loc_F0F4
		neg.w	d0

loc_F0F4:
		cmpi.w	#$60,d0		; is Sonic within $60 pixels (y-axis)?
		bcc.b	yogan2_Move	; if not, branch
		move.b	#1,$36(a0)	; set object to	move
		bra.b	yogan2_Solid
; ===========================================================================

yogan2_Move:				; XREF: yogan2_ChkSonic
		tst.b	$36(a0)		; is object set	to move?
		beq.b	yogan2_Solid	; if not, branch
		move.w	#$180,$10(a0)	; set object speed
		subq.b	#2,r_no0(a0)

yogan2_Solid:				; XREF: yogan2_Index
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		move.b	r_no0(a0),d0
		move.w	d0,-(sp)
		bsr.w	hitchk
		move.w	(sp)+,d0
		move.b	d0,r_no0(a0)
		cmpi.w	#$6A0,8(a0)	; has object reached $6A0 on the x-axis?
		bne.b	yogan2_Animate	; if not, branch
		clr.w	$10(a0)		; stop object moving
		clr.b	$36(a0)

yogan2_Animate:
		lea	(Ani_yogan2).l,a1
		bsr.w	patchg
		cmpi.b	#4,($FFFFD024).w
		bcc.b	yogan2_ChkDel
		bsr.w	speedset2

yogan2_ChkDel:
		bsr.w	actionsub
		tst.b	$36(a0)
		bne.b	locret_F17E
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	yogan2_ChkGone

locret_F17E:
		rts	
; ===========================================================================

yogan2_ChkGone:				; XREF: yogan2_ChkDel
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bclr	#7,2(a2,d0.w)
		move.b	#8,r_no0(a0)
		rts	
; ===========================================================================

yogan2_Move2:				; XREF: yogan2_Index
		movea.l	$3C(a0),a1
		cmpi.b	#8,r_no0(a1)
		beq.b	yogan2_Delete
		move.w	8(a1),8(a0)	; move rest of lava wall
		subi.w	#$80,8(a0)
		bra.w	actionsub
; ===========================================================================

yogan2_Delete:				; XREF: yogan2_Index
		bra.w	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 54 - invisible	lava tag (MZ)
; ---------------------------------------------------------------------------

yoganc:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yoganc_Index(pc,d0.w),d1
		jmp	yoganc_Index(pc,d1.w)
; ===========================================================================
yoganc_Index:	dc.w yoganc_Main-yoganc_Index
		dc.w yoganc_ChkDel-yoganc_Index

yoganc_Sizes:	dc.b $96, $94, $95, 0
; ===========================================================================

yoganc_Main:				; XREF: yoganc_Index
		addq.b	#2,r_no0(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.b	yoganc_Sizes(pc,d0.w),colino(a0)
		move.l	#Map_yoganc,4(a0)
		move.b	#$84,1(a0)

yoganc_ChkDel:				; XREF: yoganc_Index
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	frameout
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - invisible lava tag (MZ)
; ---------------------------------------------------------------------------
Map_yoganc:
	include "_maps\yoganc.asm"

Ani_myogan:
	include "_anim\myogan.asm"

Ani_yogan2:
	include "_anim\yogan2.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - lava geyser / lava that falls from the ceiling (MZ)
; ---------------------------------------------------------------------------
Map_myogan:
	include "_maps\myogan.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - advancing wall of lava (MZ)
; ---------------------------------------------------------------------------
Map_yogan2:
	include "_maps\yogan2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 40 - Moto Bug enemy (GHZ)
; ---------------------------------------------------------------------------

musi:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	musi_Index(pc,d0.w),d1
		jmp	musi_Index(pc,d1.w)
; ===========================================================================
musi_Index:	dc.w musi_Main-musi_Index
		dc.w musi_Action-musi_Index
		dc.w musi_Animate-musi_Index
		dc.w musi_Delete-musi_Index
; ===========================================================================

musi_Main:				; XREF: musi_Index
		move.l	#musipat,4(a0)
		move.w	#$4F0,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$14,$19(a0)
		tst.b	$1C(a0)		; is object a smoke trail?
		bne.b	musi_SetSmoke	; if yes, branch
		move.b	#$E,$16(a0)
		move.b	#8,$17(a0)
		move.b	#$C,colino(a0)
		bsr.w	speedset
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_F68A
		add.w	d1,$C(a0)	; match	object's position with the floor
		move.w	#0,$12(a0)
		addq.b	#2,r_no0(a0)
		bchg	#0,cddat(a0)

locret_F68A:
		rts	
; ===========================================================================

musi_SetSmoke:				; XREF: musi_Main
		addq.b	#4,r_no0(a0)
		bra.w	musi_Animate
; ===========================================================================

musi_Action:				; XREF: musi_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	musi_Index2(pc,d0.w),d1
		jsr	musi_Index2(pc,d1.w)
		lea	(Ani_musi).l,a1
		bsr.w	patchg

; ---------------------------------------------------------------------------
; Routine to mark an enemy/monitor/ring	as destroyed
; ---------------------------------------------------------------------------

frameoutchk:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	Mark_ChkGone
		bra.w	actionsub
; ===========================================================================

Mark_ChkGone:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	Mark_Delete
		bclr	#7,2(a2,d0.w)

Mark_Delete:
		bra.w	frameout

; ===========================================================================
musi_Index2:	dc.w musi_Move-musi_Index2
		dc.w musi_FixToFloor-musi_Index2
; ===========================================================================

musi_Move:				; XREF: musi_Index2
		subq.w	#1,$30(a0)	; subtract 1 from pause	time
		bpl.b	locret_F70A	; if time remains, branch
		addq.b	#2,r_no1(a0)
		move.w	#-$100,$10(a0)	; move object to the left
		move.b	#1,$1C(a0)
		bchg	#0,cddat(a0)
		bne.b	locret_F70A
		neg.w	$10(a0)		; change direction

locret_F70A:
		rts	
; ===========================================================================

musi_FixToFloor:			; XREF: musi_Index2
		bsr.w	speedset2
		jsr	emycol_d
		cmpi.w	#-8,d1
		blt.b	musi_Pause
		cmpi.w	#$C,d1
		bge.b	musi_Pause
		add.w	d1,$C(a0)	; match	object's position with the floor
		subq.b	#1,$33(a0)
		bpl.b	locret_F756
		move.b	#$F,$33(a0)
		bsr.w	actwkchk
		bne.b	locret_F756
		move.b	#$40,0(a1)	; load exhaust smoke object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	cddat(a0),cddat(a1)
		move.b	#2,$1C(a1)

locret_F756:
		rts	
; ===========================================================================

musi_Pause:				; XREF: musi_FixToFloor
		subq.b	#2,r_no1(a0)
		move.w	#59,$30(a0)	; set pause time to 1 second
		move.w	#0,$10(a0)	; stop the object moving
		move.b	#0,$1C(a0)
		rts	
; ===========================================================================

musi_Animate:				; XREF: musi_Index
		lea	(Ani_musi).l,a1
		bsr.w	patchg
		bra.w	actionsub
; ===========================================================================

musi_Delete:				; XREF: musi_Index
		bra.w	frameout
; ===========================================================================
Ani_musi:
	include "_anim\musi.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Moto Bug enemy (GHZ)
; ---------------------------------------------------------------------------
musipat:
	include "_maps\musi.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4F - blank
; ---------------------------------------------------------------------------

usa:					; XREF: act_tbl
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


yado_ChkWall:				; XREF: yado_FixToFloor
		move.w	gametimer,d0
		add.w	d7,d0
		andi.w	#3,d0
		bne.b	loc_F836
		moveq	#0,d3
		move.b	$19(a0),d3
		tst.w	$10(a0)
		bmi.b	loc_F82C
		bsr.w	ObjHitWallRight
		tst.w	d1
		bpl.b	loc_F836

loc_F828:
		moveq	#1,d0
		rts	
; ===========================================================================

loc_F82C:
		not.w	d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bmi.b	loc_F828

loc_F836:
		moveq	#0,d0
		rts	
; End of function yado_ChkWall

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 50 - Yadrin enemy (SYZ)
; ---------------------------------------------------------------------------

yado:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yado_Index(pc,d0.w),d1
		jmp	yado_Index(pc,d1.w)
; ===========================================================================
yado_Index:	dc.w yado_Main-yado_Index
		dc.w yado_Action-yado_Index
; ===========================================================================

yado_Main:				; XREF: yado_Index
		move.l	#Map_yado,4(a0)
		move.w	#$247B,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$14,$19(a0)
		move.b	#$11,$16(a0)
		move.b	#8,$17(a0)
		move.b	#$CC,colino(a0)
		bsr.w	speedset
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_F89E
		add.w	d1,$C(a0)	; match	object's position with the floor
		move.w	#0,$12(a0)
		addq.b	#2,r_no0(a0)
		bchg	#0,cddat(a0)

locret_F89E:
		rts	
; ===========================================================================

yado_Action:				; XREF: yado_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	yado_Index2(pc,d0.w),d1
		jsr	yado_Index2(pc,d1.w)
		lea	(Ani_yado).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
yado_Index2:	dc.w yado_Move-yado_Index2
		dc.w yado_FixToFloor-yado_Index2
; ===========================================================================

yado_Move:				; XREF: yado_Index2
		subq.w	#1,$30(a0)	; subtract 1 from pause	time
		bpl.b	locret_F8E2	; if time remains, branch
		addq.b	#2,r_no1(a0)
		move.w	#-$100,$10(a0)	; move object
		move.b	#1,$1C(a0)
		bchg	#0,cddat(a0)
		bne.b	locret_F8E2
		neg.w	$10(a0)		; change direction

locret_F8E2:
		rts	
; ===========================================================================

yado_FixToFloor:			; XREF: yado_Index2
		bsr.w	speedset2
		bsr.w	emycol_d
		cmpi.w	#-8,d1
		blt.b	yado_Pause
		cmpi.w	#$C,d1
		bge.b	yado_Pause
		add.w	d1,$C(a0)	; match	object's position to the floor
		bsr.w	yado_ChkWall
		bne.b	yado_Pause
		rts	
; ===========================================================================

yado_Pause:				; XREF: yado_FixToFloor
		subq.b	#2,r_no1(a0)
		move.w	#59,$30(a0)	; set pause time to 1 second
		move.w	#0,$10(a0)
		move.b	#0,$1C(a0)
		rts	
; ===========================================================================
Ani_yado:
	include "_anim\yado.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Yadrin enemy (SYZ)
; ---------------------------------------------------------------------------
Map_yado:
	include "_maps\yado.asm"

; ---------------------------------------------------------------------------
; Solid	object subroutine (includes spikes, blocks, rocks etc)
;
; variables:
; d1 = width
; d2 = height /	2 (when	jumping)
; d3 = height /	2 (when	walking)
; d4 = x-axis position
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


hitchk:
		tst.b	r_no1(a0)
		beq.w	loc_FAC8
		move.w	d1,d2
		add.w	d2,d2
		lea	playerwk,a1
		btst	#1,cddat(a1)
		bne.b	loc_F9FE
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_F9FE
		cmp.w	d2,d0
		bcs.b	loc_FA12

loc_F9FE:
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA12:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

hitchk71:				; XREF: scoli_Solid
		tst.b	r_no1(a0)
		beq.w	loc_FAD0
		move.w	d1,d2
		add.w	d2,d2
		lea	playerwk,a1
		btst	#1,cddat(a1)
		bne.b	loc_FA44
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.b	loc_FA44
		cmp.w	d2,d0
		bcs.b	loc_FA58

loc_FA44:
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FA58:
		move.w	d4,d2
		bsr.w	MvSonicOnPtfm
		moveq	#0,d4
		rts	
; ===========================================================================

hitchk2F:				; XREF: yuka_Solid
		lea	playerwk,a1
		tst.b	1(a0)
		bpl.w	loc_FB92
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.w	d0,d5
		btst	#0,1(a0)
		beq.b	loc_FA94
		not.w	d5
		add.w	d3,d5

loc_FA94:
		lsr.w	#1,d5
		moveq	#0,d3
		move.b	(a2,d5.w),d3
		sub.b	(a2),d3
		move.w	$C(a0),d5
		sub.w	d3,d5
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	d5,d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92
		bra.w	loc_FB0E
; ===========================================================================

loc_FAC8:
		tst.b	1(a0)
		bpl.w	loc_FB92

loc_FAD0:
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d1,d0
		bmi.w	loc_FB92
		move.w	d1,d3
		add.w	d3,d3
		cmp.w	d3,d0
		bhi.w	loc_FB92
		move.b	$16(a1),d3
		ext.w	d3
		add.w	d3,d2
		move.w	$C(a1),d3
		sub.w	$C(a0),d3
		addq.w	#4,d3
		add.w	d2,d3
		bmi.w	loc_FB92
		move.w	d2,d4
		add.w	d4,d4
		cmp.w	d4,d3
		bcc.w	loc_FB92

loc_FB0E:
		tst.b	($FFFFF7C8).w
		bmi.w	loc_FB92
		cmpi.b	#6,($FFFFD024).w
		bcc.w	loc_FB92
		tst.w	editmode
		bne.w	loc_FBAC
		move.w	d0,d5
		cmp.w	d0,d1
		bcc.b	loc_FB36
		add.w	d1,d1
		sub.w	d1,d0
		move.w	d0,d5
		neg.w	d5

loc_FB36:
		move.w	d3,d1
		cmp.w	d3,d2
		bcc.b	loc_FB44
		subq.w	#4,d3
		sub.w	d4,d3
		move.w	d3,d1
		neg.w	d1

loc_FB44:
		cmp.w	d1,d5
		bhi.w	loc_FBB0
		cmpi.w	#4,d1
		bls.b	loc_FB8C
		tst.w	d0
		beq.b	loc_FB70
		bmi.b	loc_FB5E
		tst.w	$10(a1)
		bmi.b	loc_FB70
		bra.b	loc_FB64
; ===========================================================================

loc_FB5E:
		tst.w	$10(a1)
		bpl.b	loc_FB70

loc_FB64:
		move.w	#0,$14(a1)	; stop Sonic moving
		move.w	#0,$10(a1)

loc_FB70:
		sub.w	d0,8(a1)
		btst	#1,cddat(a1)
		bne.b	loc_FB8C
		bset	#5,cddat(a1)
		bset	#5,cddat(a0)
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB8C:
		bsr.b	loc_FBA0
		moveq	#1,d4
		rts	
; ===========================================================================

loc_FB92:
		btst	#5,cddat(a0)
		beq.b	loc_FBAC
		move.w	#1,$1C(a1)	; use walking animation

loc_FBA0:
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)

loc_FBAC:
		moveq	#0,d4
		rts	
; ===========================================================================

loc_FBB0:
		tst.w	d3
		bmi.b	loc_FBBC
		cmpi.w	#$10,d3
		bcs.b	loc_FBEE
		bra.b	loc_FB92
; ===========================================================================

loc_FBBC:
		tst.w	$12(a1)
		beq.b	loc_FBD6
		bpl.b	loc_FBD2
		tst.w	d3
		bpl.b	loc_FBD2
		sub.w	d3,$C(a1)
		move.w	#0,$12(a1)	; stop Sonic moving

loc_FBD2:
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBD6:
		btst	#1,cddat(a1)
		bne.b	loc_FBD2
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	playdieset
		movea.l	(sp)+,a0
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FBEE:
		subq.w	#4,d3
		moveq	#0,d1
		move.b	$19(a0),d1
		move.w	d1,d2
		add.w	d2,d2
		add.w	8(a1),d1
		sub.w	8(a0),d1
		bmi.b	loc_FC28
		cmp.w	d2,d1
		bcc.b	loc_FC28
		tst.w	$12(a1)
		bmi.b	loc_FC28
		sub.w	d3,$C(a1)
		subq.w	#1,$C(a1)
		bsr.b	sub_FC2C
		move.b	#2,r_no1(a0)
		bset	#3,cddat(a0)
		moveq	#-1,d4
		rts	
; ===========================================================================

loc_FC28:
		moveq	#0,d4
		rts	
; End of function hitchk


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_FC2C:				; XREF: hitchk
		btst	#3,cddat(a1)
		beq.b	loc_FC4E
		moveq	#0,d0
		move.b	$3D(a1),d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a2
		bclr	#3,cddat(a2)
		clr.b	r_no1(a2)

loc_FC4E:
		move.w	a0,d0
		subi.w	#-$3000,d0
		lsr.w	#6,d0
		andi.w	#$7F,d0
		move.b	d0,$3D(a1)
		move.b	#0,direc(a1)
		move.w	#0,$12(a1)
		move.w	$10(a1),$14(a1)
		btst	#1,cddat(a1)
		beq.b	loc_FC84
		move.l	a0,-(sp)
		movea.l	a1,a0
		jsr	jumpcolsub
		movea.l	(sp)+,a0

loc_FC84:
		bset	#3,cddat(a1)
		bset	#3,cddat(a0)
		rts	
; End of function sub_FC2C

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 51 - smashable	green block (MZ)
; ---------------------------------------------------------------------------

bryuka:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bryuka_Index(pc,d0.w),d1
		jsr	bryuka_Index(pc,d1.w)
		bra.w	frameoutchk
; ===========================================================================
bryuka_Index:	dc.w bryuka_Main-bryuka_Index
		dc.w bryuka_Solid-bryuka_Index
		dc.w bryuka_Display-bryuka_Index
; ===========================================================================

bryuka_Main:				; XREF: bryuka_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_bryuka,4(a0)
		move.w	#$42B8,2(a0)
		move.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		move.b	userflag(a0),$1A(a0)

bryuka_Solid:				; XREF: bryuka_Index
		move.w	emyscorecnt,$34(a0)
		move.b	playerwk+mstno,$32(a0) ;	load Sonic's animation number
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#3,cddat(a0)
		bne.b	bryuka_Smash

locret_FCFC:
		rts	
; ===========================================================================

bryuka_Smash:				; XREF: bryuka_Solid
		cmpi.b	#2,$32(a0)	; is Sonic rolling/jumping?
		bne.b	locret_FCFC	; if not, branch
		move.w	$34(a0),emyscorecnt
		bset	#2,cddat(a1)
		move.b	#$E,$16(a1)
		move.b	#7,$17(a1)
		move.b	#2,$1C(a1)
		move.w	#-$300,$12(a1)	; bounce Sonic upwards
		bset	#1,cddat(a1)
		bclr	#3,cddat(a1)
		move.b	#2,r_no0(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)
		move.b	#1,$1A(a0)
		lea	(bryuka_Speeds).l,a4 ; load broken	fragment speed data
		moveq	#3,d1		; set number of	fragments to 4
		move.w	#$38,d2
		bsr.w	SmashObject
		bsr.w	actwkchk
		bne.b	bryuka_Display
		move.b	#ten_act,0(a1)	; load points object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	emyscorecnt,d2
		addq.w	#2,emyscorecnt
		cmpi.w	#6,d2
		bcs.b	bryuka_Bonus
		moveq	#6,d2

bryuka_Bonus:
		moveq	#0,d0
		move.w	bryuka_Points(pc,d2.w),d0
		cmpi.w	#$20,emyscorecnt ; have 16 blocks been smashed?
		bcs.b	loc_FD98	; if not, branch
		move.w	#1000,d0	; give higher points for 16th block
		moveq	#10,d2

loc_FD98:
		jsr	scoreup
		lsr.w	#1,d2
		move.b	d2,$1A(a1)

bryuka_Display:				; XREF: bryuka_Index
		bsr.w	speedset2
		addi.w	#$38,$12(a0)
		bsr.w	actionsub
		tst.b	1(a0)
		bpl.w	frameout
		rts	
; ===========================================================================
bryuka_Speeds:	dc.w $FE00, $FE00	; x-speed, y-speed
		dc.w $FF00, $FF00
		dc.w $200, $FE00
		dc.w $100, $FF00

bryuka_Points:	dc.w 10, 20, 50, 100
; ---------------------------------------------------------------------------
; Sprite mappings - smashable green block (MZ)
; ---------------------------------------------------------------------------
Map_bryuka:
	include "_maps\bryuka.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 52 - moving platform blocks (MZ, LZ, SBZ)
; ---------------------------------------------------------------------------

dai:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	dai_Index(pc,d0.w),d1
		jmp	dai_Index(pc,d1.w)
; ===========================================================================
dai_Index:	dc.w dai_Main-dai_Index
		dc.w dai_Platform-dai_Index
		dc.w dai_StandOn-dai_Index

dai_Var:	dc.b $10, 0		; object width,	frame number
		dc.b $20, 1
		dc.b $20, 2
		dc.b $40, 3
		dc.b $30, 4
; ===========================================================================

dai_Main:				; XREF: dai_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_dai,4(a0)
		move.w	#$42B8,2(a0)
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	loc_FE44
		move.l	#Map_daia,4(a0) ; LZ specific	code
		move.w	#$43BC,2(a0)
		move.b	#7,$16(a0)

loc_FE44:
		cmpi.b	#5,stageno ; check if level is SBZ
		bne.b	loc_FE60
		move.w	#$22C0,2(a0)	; SBZ specific code (object 5228)
		cmpi.b	#$28,userflag(a0)	; is object 5228 ?
		beq.b	loc_FE60	; if yes, branch
		move.w	#$4460,2(a0)	; SBZ specific code (object 523x)

loc_FE60:
		move.b	#4,1(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	dai_Var(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		move.b	#4,$18(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$32(a0)
		andi.b	#$F,userflag(a0)

dai_Platform:				; XREF: dai_Index
		bsr.w	dai_Move
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(PlatformObject).l
		bra.b	dai_ChkDel
; ===========================================================================

dai_StandOn:				; XREF: dai_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(ExitPlatform).l
		move.w	8(a0),-(sp)
		bsr.w	dai_Move
		move.w	(sp)+,d2
		jsr	(MvSonicOnPtfm2).l

dai_ChkDel:				; XREF: dai_Platform
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================

dai_Move:				; XREF: dai_Platform; dai_StandOn
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	dai_TypeIndex(pc,d0.w),d1
		jmp	dai_TypeIndex(pc,d1.w)
; ===========================================================================
dai_TypeIndex:dc.w dai_Type00-dai_TypeIndex, dai_Type01-dai_TypeIndex
		dc.w dai_Type02-dai_TypeIndex, dai_Type03-dai_TypeIndex
		dc.w dai_Type02-dai_TypeIndex, dai_Type05-dai_TypeIndex
		dc.w dai_Type06-dai_TypeIndex, dai_Type07-dai_TypeIndex
		dc.w dai_Type08-dai_TypeIndex, dai_Type02-dai_TypeIndex
		dc.w dai_Type0A-dai_TypeIndex
; ===========================================================================

dai_Type00:				; XREF: dai_TypeIndex
		rts	
; ===========================================================================

dai_Type01:				; XREF: dai_TypeIndex
		move.b	($FFFFFE6C).w,d0
		move.w	#$60,d1
		btst	#0,cddat(a0)
		beq.b	loc_FF26
		neg.w	d0
		add.w	d1,d0

loc_FF26:
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

dai_Type02:				; XREF: dai_TypeIndex
		cmpi.b	#4,r_no0(a0)	; is Sonic standing on the platform?
		bne.b	dai_02_Wait
		addq.b	#1,userflag(a0)	; if yes, add 1	to type

dai_02_Wait:
		rts	
; ===========================================================================

dai_Type03:				; XREF: dai_TypeIndex
		moveq	#0,d3
		move.b	$19(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1		; has the platform hit a wall?
		bmi.b	dai_03_End	; if yes, branch
		addq.w	#1,8(a0)	; move platform	to the right
		move.w	8(a0),$30(a0)
		rts	
; ===========================================================================

dai_03_End:
		clr.b	userflag(a0)		; change to type 00 (non-moving	type)
		rts	
; ===========================================================================

dai_Type05:				; XREF: dai_TypeIndex
		moveq	#0,d3
		move.b	$19(a0),d3
		bsr.w	ObjHitWallRight
		tst.w	d1		; has the platform hit a wall?
		bmi.b	dai_05_End	; if yes, branch
		addq.w	#1,8(a0)	; move platform	to the right
		move.w	8(a0),$30(a0)
		rts	
; ===========================================================================

dai_05_End:
		addq.b	#1,userflag(a0)	; change to type 06 (falling)
		rts	
; ===========================================================================

dai_Type06:				; XREF: dai_TypeIndex
		bsr.w	speedset2
		addi.w	#$18,$12(a0)	; make the platform fall
		bsr.w	emycol_d
		tst.w	d1		; has platform hit the floor?
		bpl.w	locret_FFA0	; if not, branch
		add.w	d1,$C(a0)
		clr.w	$12(a0)		; stop platform	falling
		clr.b	userflag(a0)		; change to type 00 (non-moving)

locret_FFA0:
		rts	
; ===========================================================================

dai_Type07:				; XREF: dai_TypeIndex
		tst.b	($FFFFF7E2).w	; has switch number 02 been pressed?
		beq.b	dai_07_ChkDel
		subq.b	#3,userflag(a0)	; if yes, change object	type to	04

dai_07_ChkDel:
		addq.l	#4,sp
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================

dai_Type08:				; XREF: dai_TypeIndex
		move.b	($FFFFFE7C).w,d0
		move.w	#$80,d1
		btst	#0,cddat(a0)
		beq.b	loc_FFE2
		neg.w	d0
		add.w	d1,d0

loc_FFE2:
		move.w	$32(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

dai_Type0A:				; XREF: dai_TypeIndex
		moveq	#0,d3
		move.b	$19(a0),d3
		add.w	d3,d3
		moveq	#8,d1
		btst	#0,cddat(a0)
		beq.b	loc_10004
		neg.w	d1
		neg.w	d3

loc_10004:
		tst.w	$36(a0)		; is platform set to move back?
		bne.b	dai_0A_Back	; if yes, branch
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		cmp.w	d3,d0
		beq.b	dai_0A_Wait
		add.w	d1,8(a0)	; move platform
		move.w	#300,$34(a0)	; set time delay to 5 seconds
		rts	
; ===========================================================================

dai_0A_Wait:
		subq.w	#1,$34(a0)	; subtract 1 from time delay
		bne.b	locret_1002E	; if time remains, branch
		move.w	#1,$36(a0)	; set platform to move back to its original position

locret_1002E:
		rts	
; ===========================================================================

dai_0A_Back:
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		beq.b	dai_0A_Reset
		sub.w	d1,8(a0)	; return platform to its original position
		rts	
; ===========================================================================

dai_0A_Reset:
		clr.w	$36(a0)
		subq.b	#1,userflag(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - moving blocks (MZ, SBZ)
; ---------------------------------------------------------------------------
Map_dai:
	include "_maps\daimz.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - moving block (LZ)
; ---------------------------------------------------------------------------
Map_daia:
	include "_maps\dailz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 55 - Basaran enemy (MZ)
; ---------------------------------------------------------------------------

bat:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bat_Index(pc,d0.w),d1
		jmp	bat_Index(pc,d1.w)
; ===========================================================================
bat_Index:	dc.w bat_Main-bat_Index
		dc.w bat_Action-bat_Index
; ===========================================================================

bat_Main:				; XREF: bat_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_bat,4(a0)
		move.w	#$84B8,2(a0)
		move.b	#4,1(a0)
		move.b	#$C,$16(a0)
		move.b	#2,$18(a0)
		move.b	#$B,colino(a0)
		move.b	#$10,$19(a0)

bat_Action:				; XREF: bat_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	bat_Index2(pc,d0.w),d1
		jsr	bat_Index2(pc,d1.w)
		lea	(Ani_bat).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
bat_Index2:	dc.w bat_ChkDrop-bat_Index2
		dc.w bat_DropFly-bat_Index2
		dc.w bat_PlaySnd-bat_Index2
		dc.w bat_FlyUp-bat_Index2
; ===========================================================================

bat_ChkDrop:				; XREF: bat_Index2
		move.w	#$80,d2
		bsr.w	bat_ChkSonic
		bcc.b	bat_NoDrop
		move.w	playerwk+yposi,d0
		move.w	d0,$36(a0)
		sub.w	$C(a0),d0
		bcs.b	bat_NoDrop
		cmpi.w	#$80,d0		; is Sonic within $80 pixels of	basaran?
		bcc.b	bat_NoDrop	; if not, branch
		tst.w	editmode	; is debug mode	on?
		bne.b	bat_NoDrop	; if yes, branch
		move.b	systemtimer+3,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.b	bat_NoDrop
		move.b	#1,$1C(a0)
		addq.b	#2,r_no1(a0)

bat_NoDrop:
		rts	
; ===========================================================================

bat_DropFly:				; XREF: bat_Index2
		bsr.w	speedset2
		addi.w	#$18,$12(a0)	; make basaran fall
		move.w	#$80,d2
		bsr.w	bat_ChkSonic
		move.w	$36(a0),d0
		sub.w	$C(a0),d0
		bcs.b	bat_ChkDel
		cmpi.w	#$10,d0
		bcc.b	locret_10180
		move.w	d1,$10(a0)	; make basaran fly horizontally
		move.w	#0,$12(a0)	; stop basaran falling
		move.b	#2,$1C(a0)
		addq.b	#2,r_no1(a0)

locret_10180:
		rts	
; ===========================================================================

bat_ChkDel:				; XREF: bat_DropFly
		tst.b	1(a0)
		bpl.w	frameout
		rts	
; ===========================================================================

bat_PlaySnd:				; XREF: bat_Index2
		move.b	systemtimer+3,d0
		andi.b	#$F,d0
		bne.b	loc_101A0
		move.w	#$C0,d0
		jsr	(soundset).l ;	play flapping sound

loc_101A0:
		bsr.w	speedset2
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_101B0
		neg.w	d0

loc_101B0:
		cmpi.w	#$80,d0
		bcs.b	locret_101C6
		move.b	systemtimer+3,d0
		add.b	d7,d0
		andi.b	#7,d0
		bne.b	locret_101C6
		addq.b	#2,r_no1(a0)

locret_101C6:
		rts	
; ===========================================================================

bat_FlyUp:				; XREF: bat_Index2
		bsr.w	speedset2
		subi.w	#$18,$12(a0)	; make basaran fly upwards
		bsr.w	ObjHitCeiling
		tst.w	d1		; has basaran hit the ceiling?
		bpl.b	locret_101F4	; if not, branch
		sub.w	d1,$C(a0)
		andi.w	#$FFF8,8(a0)
		clr.w	$10(a0)		; stop basaran moving
		clr.w	$12(a0)
		clr.b	$1C(a0)
		clr.b	r_no1(a0)

locret_101F4:
		rts	
; ===========================================================================

bat_ChkSonic:				; XREF: bat_ChkDrop
		move.w	#$100,d1
		bset	#0,cddat(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_10214
		neg.w	d0
		neg.w	d1
		bclr	#0,cddat(a0)

loc_10214:
		cmp.w	d2,d0
		rts	
; ===========================================================================
		bsr.w	speedset2
		bsr.w	actionsub
		tst.b	1(a0)
		bpl.w	frameout
		rts	
; ===========================================================================
Ani_bat:
	include "_anim\bat.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Basaran enemy (MZ)
; ---------------------------------------------------------------------------
Map_bat:
	include "_maps\bat.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 56 - moving blocks (SYZ/SLZ), large doors (LZ)
; ---------------------------------------------------------------------------

dai2:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	dai2_Index(pc,d0.w),d1
		jmp	dai2_Index(pc,d1.w)
; ===========================================================================
dai2_Index:	dc.w dai2_Main-dai2_Index
		dc.w dai2_Action-dai2_Index

dai2_Var:	dc.b  $10, $10		; width, height
		dc.b  $20, $20
		dc.b  $10, $20
		dc.b  $20, $1A
		dc.b  $10, $27
		dc.b  $10, $10
		dc.b	8, $20
		dc.b  $40, $10
; ===========================================================================

dai2_Main:				; XREF: dai2_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_dai2,4(a0)
		move.w	#$4000,2(a0)
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	loc_102C8
		move.w	#$43C4,2(a0)	; LZ specific code

loc_102C8:
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#3,d0
		andi.w	#$E,d0
		lea	dai2_Var(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2),$16(a0)
		lsr.w	#1,d0
		move.b	d0,$1A(a0)
		move.w	8(a0),$34(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	(a2),d0
		add.w	d0,d0
		move.w	d0,$3A(a0)
		moveq	#0,d0
		cmpi.b	#1,stageno ; check if level is LZ
		beq.b	loc_10332
		move.b	userflag(a0),d0	; SYZ/SLZ specific code
		andi.w	#$F,d0
		subq.w	#8,d0
		bcs.b	loc_10332
		lsl.w	#2,d0
		lea	($FFFFFE8A).w,a2
		lea	(a2,d0.w),a2
		tst.w	(a2)
		bpl.b	loc_10332
		bchg	#0,cddat(a0)

loc_10332:
		move.b	userflag(a0),d0
		bpl.b	dai2_Action
		andi.b	#$F,d0
		move.b	d0,$3C(a0)
		move.b	#5,userflag(a0)
		cmpi.b	#7,$1A(a0)
		bne.b	dai2_ChkGone
		move.b	#$C,userflag(a0)
		move.w	#$80,$3A(a0)

dai2_ChkGone:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	dai2_Action
		bclr	#7,2(a2,d0.w)
		btst	#0,2(a2,d0.w)
		beq.b	dai2_Action
		addq.b	#1,userflag(a0)
		clr.w	$3A(a0)

dai2_Action:				; XREF: dai2_Index
		move.w	8(a0),-(sp)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		andi.w	#$F,d0		; read only the	2nd digit
		add.w	d0,d0
		move.w	dai2_TypeIndex(pc,d0.w),d1
		jsr	dai2_TypeIndex(pc,d1.w)
		move.w	(sp)+,d4
		tst.b	1(a0)
		bpl.b	dai2_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	hitchk

dai2_ChkDel:
		move.w	$34(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
dai2_TypeIndex:dc.w dai2_Type00-dai2_TypeIndex, dai2_Type01-dai2_TypeIndex
		dc.w dai2_Type02-dai2_TypeIndex, dai2_Type03-dai2_TypeIndex
		dc.w dai2_Type04-dai2_TypeIndex, dai2_Type05-dai2_TypeIndex
		dc.w dai2_Type06-dai2_TypeIndex, dai2_Type07-dai2_TypeIndex
		dc.w dai2_Type08-dai2_TypeIndex, dai2_Type09-dai2_TypeIndex
		dc.w dai2_Type0A-dai2_TypeIndex, dai2_Type0B-dai2_TypeIndex
		dc.w dai2_Type0C-dai2_TypeIndex, dai2_Type0D-dai2_TypeIndex
; ===========================================================================

dai2_Type00:				; XREF: dai2_TypeIndex
		rts	
; ===========================================================================

dai2_Type01:				; XREF: dai2_TypeIndex
		move.w	#$40,d1
		moveq	#0,d0
		move.b	($FFFFFE68).w,d0
		bra.b	dai2_Move_LR
; ===========================================================================

dai2_Type02:				; XREF: dai2_TypeIndex
		move.w	#$80,d1
		moveq	#0,d0
		move.b	($FFFFFE7C).w,d0

dai2_Move_LR:
		btst	#0,cddat(a0)
		beq.b	loc_10416
		neg.w	d0
		add.w	d1,d0

loc_10416:
		move.w	$34(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)	; move object horizontally
		rts	
; ===========================================================================

dai2_Type03:				; XREF: dai2_TypeIndex
		move.w	#$40,d1
		moveq	#0,d0
		move.b	($FFFFFE68).w,d0
		bra.b	dai2_Move_UD
; ===========================================================================

dai2_Type04:				; XREF: dai2_TypeIndex
		move.w	#$80,d1
		moveq	#0,d0
		move.b	($FFFFFE7C).w,d0

dai2_Move_UD:
		btst	#0,cddat(a0)
		beq.b	loc_10444
		neg.w	d0
		add.w	d1,d0

loc_10444:
		move.w	$30(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; move object vertically
		rts	
; ===========================================================================

dai2_Type05:				; XREF: dai2_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_104A4
		cmpi.w	#$100,stageno ; is level LZ1 ?
		bne.b	loc_1047A	; if not, branch
		cmpi.b	#3,$3C(a0)
		bne.b	loc_1047A
		clr.b	($FFFFF7C9).w
		move.w	playerwk+xposi,d0
		cmp.w	8(a0),d0
		bcc.b	loc_1047A
		move.b	#1,($FFFFF7C9).w

loc_1047A:
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3C(a0),d0
		btst	#0,(a2,d0.w)
		beq.b	loc_104AE
		cmpi.w	#$100,stageno ; is level LZ1 ?
		bne.b	loc_1049E	; if not, branch
		cmpi.b	#3,d0
		bne.b	loc_1049E
		clr.b	($FFFFF7C9).w

loc_1049E:
		move.b	#1,$38(a0)

loc_104A4:
		tst.w	$3A(a0)
		beq.b	loc_104C8
		subq.w	#2,$3A(a0)

loc_104AE:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_104BC
		neg.w	d0

loc_104BC:
		move.w	$30(a0),d1
		add.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_104C8:
		addq.b	#1,userflag(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_104AE
		bset	#0,2(a2,d0.w)
		bra.b	loc_104AE
; ===========================================================================

dai2_Type06:				; XREF: dai2_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_10500
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3C(a0),d0
		tst.b	(a2,d0.w)
		bpl.b	loc_10512
		move.b	#1,$38(a0)

loc_10500:
		moveq	#0,d0
		move.b	$16(a0),d0
		add.w	d0,d0
		cmp.w	$3A(a0),d0
		beq.b	loc_1052C
		addq.w	#2,$3A(a0)

loc_10512:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_10520
		neg.w	d0

loc_10520:
		move.w	$30(a0),d1
		add.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_1052C:
		subq.b	#1,userflag(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_10512
		bclr	#0,2(a2,d0.w)
		bra.b	loc_10512
; ===========================================================================

dai2_Type07:				; XREF: dai2_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_1055E
		tst.b	($FFFFF7EF).w	; has switch number $F been pressed?
		beq.b	locret_10578
		move.b	#1,$38(a0)
		clr.w	$3A(a0)

loc_1055E:
		addq.w	#1,8(a0)
		move.w	8(a0),$34(a0)
		addq.w	#1,$3A(a0)
		cmpi.w	#$380,$3A(a0)
		bne.b	locret_10578
		clr.b	userflag(a0)

locret_10578:
		rts	
; ===========================================================================

dai2_Type0C:				; XREF: dai2_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_10598
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3C(a0),d0
		btst	#0,(a2,d0.w)
		beq.b	loc_105A2
		move.b	#1,$38(a0)

loc_10598:
		tst.w	$3A(a0)
		beq.b	loc_105C0
		subq.w	#2,$3A(a0)

loc_105A2:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_105B4
		neg.w	d0
		addi.w	#$80,d0

loc_105B4:
		move.w	$34(a0),d1
		add.w	d0,d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

loc_105C0:
		addq.b	#1,userflag(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_105A2
		bset	#0,2(a2,d0.w)
		bra.b	loc_105A2
; ===========================================================================

dai2_Type0D:				; XREF: dai2_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_105F8
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3C(a0),d0
		tst.b	(a2,d0.w)
		bpl.b	loc_10606
		move.b	#1,$38(a0)

loc_105F8:
		move.w	#$80,d0
		cmp.w	$3A(a0),d0
		beq.b	loc_10624
		addq.w	#2,$3A(a0)

loc_10606:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_10618
		neg.w	d0
		addi.w	#$80,d0

loc_10618:
		move.w	$34(a0),d1
		add.w	d0,d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

loc_10624:
		subq.b	#1,userflag(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_10606
		bclr	#0,2(a2,d0.w)
		bra.b	loc_10606
; ===========================================================================

dai2_Type08:				; XREF: dai2_TypeIndex
		move.w	#$10,d1
		moveq	#0,d0
		move.b	($FFFFFE88).w,d0
		lsr.w	#1,d0
		move.w	($FFFFFE8A).w,d3
		bra.b	dai2_Move_Sqr
; ===========================================================================

dai2_Type09:				; XREF: dai2_TypeIndex
		move.w	#$30,d1
		moveq	#0,d0
		move.b	($FFFFFE8C).w,d0
		move.w	($FFFFFE8E).w,d3
		bra.b	dai2_Move_Sqr
; ===========================================================================

dai2_Type0A:				; XREF: dai2_TypeIndex
		move.w	#$50,d1
		moveq	#0,d0
		move.b	($FFFFFE90).w,d0
		move.w	($FFFFFE92).w,d3
		bra.b	dai2_Move_Sqr
; ===========================================================================

dai2_Type0B:				; XREF: dai2_TypeIndex
		move.w	#$70,d1
		moveq	#0,d0
		move.b	($FFFFFE94).w,d0
		move.w	($FFFFFE96).w,d3

dai2_Move_Sqr:
		tst.w	d3
		bne.b	loc_1068E
		addq.b	#1,cddat(a0)
		andi.b	#3,cddat(a0)

loc_1068E:
		move.b	cddat(a0),d2
		andi.b	#3,d2
		bne.b	loc_106AE
		sub.w	d1,d0
		add.w	$34(a0),d0
		move.w	d0,8(a0)
		neg.w	d1
		add.w	$30(a0),d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_106AE:
		subq.b	#1,d2
		bne.b	loc_106CC
		subq.w	#1,d1
		sub.w	d1,d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		addq.w	#1,d1
		add.w	$34(a0),d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

loc_106CC:
		subq.b	#1,d2
		bne.b	loc_106EA
		subq.w	#1,d1
		sub.w	d1,d0
		neg.w	d0
		add.w	$34(a0),d0
		move.w	d0,8(a0)
		addq.w	#1,d1
		add.w	$30(a0),d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_106EA:
		sub.w	d1,d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		neg.w	d1
		add.w	$34(a0),d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - moving blocks (SYZ/SLZ/LZ)
; ---------------------------------------------------------------------------
Map_dai2:
	include "_maps\dai2.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 57 - spiked balls (SYZ, LZ)
; ---------------------------------------------------------------------------

Obj57:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj57_Index(pc,d0.w),d1
		jmp	Obj57_Index(pc,d1.w)
; ===========================================================================
Obj57_Index:	dc.w Obj57_Main-Obj57_Index
		dc.w Obj57_Move-Obj57_Index
		dc.w Obj57_Display-Obj57_Index
; ===========================================================================

Obj57_Main:				; XREF: Obj57_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj57,4(a0)
		move.w	#$3BA,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#8,$19(a0)
		move.w	8(a0),$3A(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$98,colino(a0)	; SYZ specific code (chain hurts Sonic)
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	loc_107E8
		move.b	#0,colino(a0)	; LZ specific code (chain doesn't hurt)
		move.w	#$310,2(a0)
		move.l	#Map_obj57a,4(a0)

loc_107E8:
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F0,d1		; read only the	1st digit
		ext.w	d1
		asl.w	#3,d1		; multiply by 8
		move.w	d1,$3E(a0)	; set object twirl speed
		move.b	cddat(a0),d0
		ror.b	#2,d0
		andi.b	#-$40,d0
		move.b	d0,direc(a0)
		lea	$29(a0),a2
		move.b	userflag(a0),d1	; get object type
		andi.w	#7,d1		; read only the	2nd digit
		move.b	#0,(a2)+
		move.w	d1,d3
		lsl.w	#4,d3
		move.b	d3,$3C(a0)
		subq.w	#1,d1		; set chain length (type-1)
		bcs.b	loc_10894
		btst	#3,userflag(a0)
		beq.b	Obj57_MakeChain
		subq.w	#1,d1
		bcs.b	loc_10894

Obj57_MakeChain:
		bsr.w	actwkchk
		bne.b	loc_10894
		addq.b	#1,$29(a0)
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#4,r_no0(a1)
		move.b	0(a0),0(a1)
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		move.b	1(a0),1(a1)
		move.b	$18(a0),$18(a1)
		move.b	$19(a0),$19(a1)
		move.b	colino(a0),colino(a1)
		subi.b	#$10,d3
		move.b	d3,$3C(a1)
		cmpi.b	#1,stageno
		bne.b	loc_10890
		tst.b	d3
		bne.b	loc_10890
		move.b	#2,$1A(a1)

loc_10890:
		dbra	d1,Obj57_MakeChain ; repeat for	length of chain

loc_10894:
		move.w	a0,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	Obj57_Move
		move.b	#$8B,colino(a0)	; if yes, make last spikeball larger
		move.b	#1,$1A(a0)	; use different	frame

Obj57_Move:				; XREF: Obj57_Index
		bsr.w	Obj57_MoveSub
		bra.w	Obj57_ChkDel
; ===========================================================================

Obj57_MoveSub:				; XREF: Obj57_Move
		move.w	$3E(a0),d0
		add.w	d0,direc(a0)
		move.b	direc(a0),d0
		jsr	(sinset).l
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		lea	$29(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

Obj57_MoveLoop:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#$FFD000,d4
		movea.l	d4,a1
		moveq	#0,d4
		move.b	$3C(a1),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a1)
		move.w	d5,8(a1)
		dbra	d6,Obj57_MoveLoop
		rts	
; ===========================================================================

Obj57_ChkDel:				; XREF: Obj57_Move
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	Obj57_Delete
		bra.w	actionsub
; ===========================================================================

Obj57_Delete:				; XREF: Obj57_ChkDel
		moveq	#0,d2
		lea	$29(a0),a2
		move.b	(a2)+,d2

Obj57_DelLoop:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		bsr.w	frameout2
		dbra	d2,Obj57_DelLoop ; delete all pieces of	chain

		rts	
; ===========================================================================

Obj57_Display:				; XREF: Obj57_Index
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - chain of spiked balls (SYZ)
; ---------------------------------------------------------------------------
Map_obj57:
	include "_maps\obj57syz.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - spiked ball	on a chain (LZ)
; ---------------------------------------------------------------------------
Map_obj57a:
	include "_maps\obj57lz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 58 - giant spiked balls (SYZ)
; ---------------------------------------------------------------------------

Obj58:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj58_Index(pc,d0.w),d1
		jmp	Obj58_Index(pc,d1.w)
; ===========================================================================
Obj58_Index:	dc.w Obj58_Main-Obj58_Index
		dc.w Obj58_Move-Obj58_Index
; ===========================================================================

Obj58_Main:				; XREF: Obj58_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_burankob,4(a0)
		move.w	#$396,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$18,$19(a0)
		move.w	8(a0),$3A(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$86,colino(a0)
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F0,d1		; read only the	1st digit
		ext.w	d1
		asl.w	#3,d1		; multiply by 8
		move.w	d1,$3E(a0)	; set object speed
		move.b	cddat(a0),d0
		ror.b	#2,d0
		andi.b	#$C0,d0
		move.b	d0,direc(a0)
		move.b	#$50,$3C(a0)	; set diameter of circle of rotation

Obj58_Move:				; XREF: Obj58_Index
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		andi.w	#7,d0		; read only the	2nd digit
		add.w	d0,d0
		move.w	Obj58_TypeIndex(pc,d0.w),d1
		jsr	Obj58_TypeIndex(pc,d1.w)
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
Obj58_TypeIndex:dc.w Obj58_Type00-Obj58_TypeIndex
		dc.w Obj58_Type01-Obj58_TypeIndex
		dc.w Obj58_Type02-Obj58_TypeIndex
		dc.w Obj58_Type03-Obj58_TypeIndex
; ===========================================================================

Obj58_Type00:				; XREF: Obj58_TypeIndex
		rts	
; ===========================================================================

Obj58_Type01:				; XREF: Obj58_TypeIndex
		move.w	#$60,d1
		moveq	#0,d0
		move.b	($FFFFFE6C).w,d0
		btst	#0,cddat(a0)
		beq.b	loc_10A38
		neg.w	d0
		add.w	d1,d0

loc_10A38:
		move.w	$3A(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)	; move object horizontally
		rts	
; ===========================================================================

Obj58_Type02:				; XREF: Obj58_TypeIndex
		move.w	#$60,d1
		moveq	#0,d0
		move.b	($FFFFFE6C).w,d0
		btst	#0,cddat(a0)
		beq.b	loc_10A5C
		neg.w	d0
		addi.w	#$80,d0

loc_10A5C:
		move.w	$38(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; move object vertically
		rts	
; ===========================================================================

Obj58_Type03:				; XREF: Obj58_TypeIndex
		move.w	$3E(a0),d0
		add.w	d0,direc(a0)
		move.b	direc(a0),d0
		jsr	(sinset).l
		move.w	$38(a0),d2
		move.w	$3A(a0),d3
		moveq	#0,d4
		move.b	$3C(a0),d4
		move.l	d4,d5
		muls.w	d0,d4
		asr.l	#8,d4
		muls.w	d1,d5
		asr.l	#8,d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a0)
		move.w	d5,8(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - SBZ	spiked ball on a chain
; ---------------------------------------------------------------------------
Map_burankob:
	include "_maps\burankosbz.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 59 - platforms	that move when you stand on them (SLZ)
; ---------------------------------------------------------------------------

elev:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	elev_Index(pc,d0.w),d1
		jsr	elev_Index(pc,d1.w)
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
elev_Index:	dc.w elev_Main-elev_Index
		dc.w elev_Platform-elev_Index
		dc.w elev_Action-elev_Index
		dc.w elev_MakeMulti-elev_Index

elev_Var1:	dc.b $28, 0		; width, frame number

elev_Var2:	dc.b $10, 1		; width, action	type
		dc.b $20, 1
		dc.b $34, 1
		dc.b $10, 3
		dc.b $20, 3
		dc.b $34, 3
		dc.b $14, 1
		dc.b $24, 1
		dc.b $2C, 1
		dc.b $14, 3
		dc.b $24, 3
		dc.b $2C, 3
		dc.b $20, 5
		dc.b $20, 7
		dc.b $30, 9
; ===========================================================================

elev_Main:				; XREF: elev_Index
		addq.b	#2,r_no0(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		bpl.b	elev_Main2
		addq.b	#4,r_no0(a0)
		andi.w	#$7F,d0
		mulu.w	#6,d0
		move.w	d0,$3C(a0)
		move.w	d0,$3E(a0)
		addq.l	#4,sp
		rts	
; ===========================================================================

elev_Main2:
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	elev_Var1(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2)+,$1A(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	elev_Var2(pc,d0.w),a2
		move.b	(a2)+,d0
		lsl.w	#2,d0
		move.w	d0,$3C(a0)
		move.b	(a2)+,userflag(a0)
		move.l	#Map_elev,4(a0)
		move.w	#$4000,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.w	8(a0),$32(a0)
		move.w	$C(a0),$30(a0)

elev_Platform:				; XREF: elev_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(PlatformObject).l
		bra.w	elev_Types
; ===========================================================================

elev_Action:				; XREF: elev_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(ExitPlatform).l
		move.w	8(a0),-(sp)
		bsr.w	elev_Types
		move.w	(sp)+,d2
		tst.b	0(a0)
		beq.b	locret_10BD4
		jmp	(MvSonicOnPtfm2).l
; ===========================================================================

locret_10BD4:
		rts	
; ===========================================================================

elev_Types:
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	elev_TypeIndex(pc,d0.w),d1
		jmp	elev_TypeIndex(pc,d1.w)
; ===========================================================================
elev_TypeIndex:dc.w elev_Type00-elev_TypeIndex, elev_Type01-elev_TypeIndex
		dc.w elev_Type02-elev_TypeIndex, elev_Type01-elev_TypeIndex
		dc.w elev_Type04-elev_TypeIndex, elev_Type01-elev_TypeIndex
		dc.w elev_Type06-elev_TypeIndex, elev_Type01-elev_TypeIndex
		dc.w elev_Type08-elev_TypeIndex, elev_Type09-elev_TypeIndex
; ===========================================================================

elev_Type00:				; XREF: elev_TypeIndex
		rts	
; ===========================================================================

elev_Type01:				; XREF: elev_TypeIndex
		cmpi.b	#4,r_no0(a0)	; check	if Sonic is standing on	the object
		bne.b	locret_10C0C
		addq.b	#1,userflag(a0)	; if yes, add 1	to type

locret_10C0C:
		rts	
; ===========================================================================

elev_Type02:				; XREF: elev_TypeIndex
		bsr.w	elev_Move
		move.w	$34(a0),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		rts	
; ===========================================================================

elev_Type04:				; XREF: elev_TypeIndex
		bsr.w	elev_Move
		move.w	$34(a0),d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		rts	
; ===========================================================================

elev_Type06:				; XREF: elev_TypeIndex
		bsr.w	elev_Move
		move.w	$34(a0),d0
		asr.w	#1,d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		move.w	$34(a0),d0
		add.w	$32(a0),d0
		move.w	d0,8(a0)
		rts	
; ===========================================================================

elev_Type08:				; XREF: elev_TypeIndex
		bsr.w	elev_Move
		move.w	$34(a0),d0
		asr.w	#1,d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		move.w	$34(a0),d0
		neg.w	d0
		add.w	$32(a0),d0
		move.w	d0,8(a0)
		rts	
; ===========================================================================

elev_Type09:				; XREF: elev_TypeIndex
		bsr.w	elev_Move
		move.w	$34(a0),d0
		neg.w	d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)
		tst.b	userflag(a0)
		beq.w	loc_10C94
		rts	
; ===========================================================================

loc_10C94:
		btst	#3,cddat(a0)
		beq.b	elev_Delete
		bset	#1,cddat(a1)
		bclr	#3,cddat(a1)
		move.b	#2,r_no0(a1)

elev_Delete:
		bra.w	frameout

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


elev_Move:				; XREF: elev_Type02; et al
		move.w	$38(a0),d0
		tst.b	$3A(a0)
		bne.b	loc_10CC8
		cmpi.w	#$800,d0
		bcc.b	loc_10CD0
		addi.w	#$10,d0
		bra.b	loc_10CD0
; ===========================================================================

loc_10CC8:
		tst.w	d0
		beq.b	loc_10CD0
		subi.w	#$10,d0

loc_10CD0:
		move.w	d0,$38(a0)
		ext.l	d0
		asl.l	#8,d0
		add.l	$34(a0),d0
		move.l	d0,$34(a0)
		swap	d0
		move.w	$3C(a0),d2
		cmp.w	d2,d0
		bls.b	loc_10CF0
		move.b	#1,$3A(a0)

loc_10CF0:
		add.w	d2,d2
		cmp.w	d2,d0
		bne.b	locret_10CFA
		clr.b	userflag(a0)

locret_10CFA:
		rts	
; End of function elev_Move

; ===========================================================================

elev_MakeMulti:			; XREF: elev_Index
		subq.w	#1,$3C(a0)
		bne.b	elev_ChkDel
		move.w	$3E(a0),$3C(a0)
		bsr.w	actwkchk
		bne.b	elev_ChkDel
		move.b	#$59,0(a1)	; duplicate the	object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#$E,userflag(a1)

elev_ChkDel:
		addq.l	#4,sp
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - platforms that move	when you stand on them (SLZ)
; ---------------------------------------------------------------------------
Map_elev:
	include "_maps\elev.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5A - platforms	moving in circles (SLZ)
; ---------------------------------------------------------------------------

pedal:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	pedal_Index(pc,d0.w),d1
		jsr	pedal_Index(pc,d1.w)
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
pedal_Index:	dc.w pedal_Main-pedal_Index
		dc.w pedal_Platform-pedal_Index
		dc.w pedal_Action-pedal_Index
; ===========================================================================

pedal_Main:				; XREF: pedal_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_pedal,4(a0)
		move.w	#$4000,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$18,$19(a0)
		move.w	8(a0),$32(a0)
		move.w	$C(a0),$30(a0)

pedal_Platform:				; XREF: pedal_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(PlatformObject).l
		bra.w	pedal_Types
; ===========================================================================

pedal_Action:				; XREF: pedal_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(ExitPlatform).l
		move.w	8(a0),-(sp)
		bsr.w	pedal_Types
		move.w	(sp)+,d2
		jmp	(MvSonicOnPtfm2).l
; ===========================================================================

pedal_Types:
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$C,d0
		lsr.w	#1,d0
		move.w	pedal_TypeIndex(pc,d0.w),d1
		jmp	pedal_TypeIndex(pc,d1.w)
; ===========================================================================
pedal_TypeIndex:dc.w pedal_Type00-pedal_TypeIndex
		dc.w pedal_Type04-pedal_TypeIndex
; ===========================================================================

pedal_Type00:				; XREF: pedal_TypeIndex
		move.b	($FFFFFE80).w,d1
		subi.b	#$50,d1
		ext.w	d1
		move.b	($FFFFFE84).w,d2
		subi.b	#$50,d2
		ext.w	d2
		btst	#0,userflag(a0)
		beq.b	loc_10E24
		neg.w	d1
		neg.w	d2

loc_10E24:
		btst	#1,userflag(a0)
		beq.b	loc_10E30
		neg.w	d1
		exg	d1,d2

loc_10E30:
		add.w	$32(a0),d1
		move.w	d1,8(a0)
		add.w	$30(a0),d2
		move.w	d2,$C(a0)
		rts	
; ===========================================================================

pedal_Type04:				; XREF: pedal_TypeIndex
		move.b	($FFFFFE80).w,d1
		subi.b	#$50,d1
		ext.w	d1
		move.b	($FFFFFE84).w,d2
		subi.b	#$50,d2
		ext.w	d2
		btst	#0,userflag(a0)
		beq.b	loc_10E62
		neg.w	d1
		neg.w	d2

loc_10E62:
		btst	#1,userflag(a0)
		beq.b	loc_10E6E
		neg.w	d1
		exg	d1,d2

loc_10E6E:
		neg.w	d1
		add.w	$32(a0),d1
		move.w	d1,8(a0)
		add.w	$30(a0),d2
		move.w	d2,$C(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - platforms that move	in circles (SLZ)
; ---------------------------------------------------------------------------
Map_pedal:
	include "_maps\pedal.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5B - blocks that form a staircase (SLZ)
; ---------------------------------------------------------------------------

step:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	step_Index(pc,d0.w),d1
		jsr	step_Index(pc,d1.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
step_Index:	dc.w step_Main-step_Index
		dc.w step_Move-step_Index
		dc.w step_Solid-step_Index
; ===========================================================================

step_Main:				; XREF: step_Index
		addq.b	#2,r_no0(a0)
		moveq	#$38,d3
		moveq	#1,d4
		btst	#0,cddat(a0)
		beq.b	loc_10EDA
		moveq	#$3B,d3
		moveq	#-1,d4

loc_10EDA:
		move.w	8(a0),d2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	step_MakeBlocks
; ===========================================================================

step_Loop:
		bsr.w	actwkchk2
		bne.w	step_Move
		move.b	#4,r_no0(a1)

step_MakeBlocks:			; XREF: step_Main
		move.b	#$5B,0(a1)	; load another block object
		move.l	#Map_step,4(a1)
		move.w	#$4000,2(a1)
		move.b	#4,1(a1)
		move.b	#3,$18(a1)
		move.b	#$10,$19(a1)
		move.b	userflag(a0),userflag(a1)
		move.w	d2,8(a1)
		move.w	$C(a0),$C(a1)
		move.w	8(a0),$30(a1)
		move.w	$C(a1),$32(a1)
		addi.w	#$20,d2
		move.b	d3,$37(a1)
		move.l	a0,$3C(a1)
		add.b	d4,d3
		dbra	d1,step_Loop	; repeat sequence 3 times

step_Move:				; XREF: step_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	step_TypeIndex(pc,d0.w),d1
		jsr	step_TypeIndex(pc,d1.w)

step_Solid:				; XREF: step_Index
		movea.l	$3C(a0),a2
		moveq	#0,d0
		move.b	$37(a0),d0
		move.b	(a2,d0.w),d0
		add.w	$32(a0),d0
		move.w	d0,$C(a0)
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		tst.b	d4
		bpl.b	loc_10F92
		move.b	d4,$36(a2)

loc_10F92:
		btst	#3,cddat(a0)
		beq.b	locret_10FA0
		move.b	#1,$36(a2)

locret_10FA0:
		rts	
; ===========================================================================
step_TypeIndex:dc.w step_Type00-step_TypeIndex
		dc.w step_Type01-step_TypeIndex
		dc.w step_Type02-step_TypeIndex
		dc.w step_Type01-step_TypeIndex
; ===========================================================================

step_Type00:				; XREF: step_TypeIndex
		tst.w	$34(a0)
		bne.b	loc_10FC0
		cmpi.b	#1,$36(a0)
		bne.b	locret_10FBE
		move.w	#$1E,$34(a0)

locret_10FBE:
		rts	
; ===========================================================================

loc_10FC0:
		subq.w	#1,$34(a0)
		bne.b	locret_10FBE
		addq.b	#1,userflag(a0)	; add 1	to type
		rts	
; ===========================================================================

step_Type02:				; XREF: step_TypeIndex
		tst.w	$34(a0)
		bne.b	loc_10FE0
		tst.b	$36(a0)
		bpl.b	locret_10FDE
		move.w	#$3C,$34(a0)

locret_10FDE:
		rts	
; ===========================================================================

loc_10FE0:
		subq.w	#1,$34(a0)
		bne.b	loc_10FEC
		addq.b	#1,userflag(a0)	; add 1	to type
		rts	
; ===========================================================================

loc_10FEC:
		lea	$38(a0),a1
		move.w	$34(a0),d0
		lsr.b	#2,d0
		andi.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		eori.b	#1,d0
		move.b	d0,(a1)+
		rts	
; ===========================================================================

step_Type01:				; XREF: step_TypeIndex
		lea	$38(a0),a1
		cmpi.b	#$80,(a1)
		beq.b	locret_11038
		addq.b	#1,(a1)
		moveq	#0,d1
		move.b	(a1)+,d1
		swap	d1
		lsr.l	#1,d1
		move.l	d1,d2
		lsr.l	#1,d1
		move.l	d1,d3
		add.l	d2,d3
		swap	d1
		swap	d2
		swap	d3
		move.b	d3,(a1)+
		move.b	d2,(a1)+
		move.b	d1,(a1)+

locret_11038:
		rts	
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - blocks that	form a staircase (SLZ)
; ---------------------------------------------------------------------------
Map_step:
	include "_maps\step.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5C - metal girders in foreground (SLZ)
; ---------------------------------------------------------------------------

Obj5C:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj5C_Index(pc,d0.w),d1
		jmp	Obj5C_Index(pc,d1.w)
; ===========================================================================
Obj5C_Index:	dc.w Obj5C_Main-Obj5C_Index
		dc.w Obj5C_Display-Obj5C_Index
; ===========================================================================

Obj5C_Main:				; XREF: Obj5C_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj5C,4(a0)
		move.w	#$83CC,2(a0)
		move.b	#$10,$19(a0)

Obj5C_Display:				; XREF: Obj5C_Index
		move.l	scra_h_posit,d1
		add.l	d1,d1
		swap	d1
		neg.w	d1
		move.w	d1,8(a0)
		move.l	scra_v_posit,d1
		add.l	d1,d1
		swap	d1
		andi.w	#$3F,d1
		neg.w	d1
		addi.w	#$100,d1
		move.w	d1,$A(a0)
		bra.w	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - metal girders in foreground	(SLZ)
; ---------------------------------------------------------------------------
Map_obj5C:
	include "_maps\obj5C.asm"

		include	'WAVE.ASM'

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0B - pole that	breaks (LZ)
; ---------------------------------------------------------------------------

bou:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bou_Index(pc,d0.w),d1
		jmp	bou_Index(pc,d1.w)
; ===========================================================================
bou_Index:	dc.w bou_Main-bou_Index
		dc.w bou_Action-bou_Index
		dc.w bou_Display-bou_Index
; ===========================================================================

bou_Main:				; XREF: bou_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_bou,4(a0)
		move.w	#$43DE,2(a0)
		move.b	#4,1(a0)
		move.b	#8,$19(a0)
		move.b	#4,$18(a0)
		move.b	#$E1,colino(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		mulu.w	#60,d0		; multiply by 60 (1 second)
		move.w	d0,$30(a0)	; set breakage time

bou_Action:				; XREF: bou_Index
		tst.b	$32(a0)
		beq.b	bou_Grab
		tst.w	$30(a0)
		beq.b	bou_MoveUp
		subq.w	#1,$30(a0)
		bne.b	bou_MoveUp
		move.b	#1,$1A(a0)	; break	the pole
		bra.b	bou_Release
; ===========================================================================

bou_MoveUp:				; XREF: bou_Action
		lea	playerwk,a1
		move.w	$C(a0),d0
		subi.w	#$18,d0
		btst	#0,swdata1+0 ; check if "up" is pressed
		beq.b	bou_MoveDown
		subq.w	#1,$C(a1)	; move Sonic up
		cmp.w	$C(a1),d0
		bcs.b	bou_MoveDown
		move.w	d0,$C(a1)

bou_MoveDown:
		addi.w	#$24,d0
		btst	#1,swdata1+0 ; check if "down" is pressed
		beq.b	bou_LetGo
		addq.w	#1,$C(a1)	; move Sonic down
		cmp.w	$C(a1),d0
		bcc.b	bou_LetGo
		move.w	d0,$C(a1)

bou_LetGo:
		move.b	swdata+1,d0
		andi.w	#$70,d0
		beq.b	bou_Display

bou_Release:				; XREF: bou_Action
		clr.b	colino(a0)
		addq.b	#2,r_no0(a0)
		clr.b	($FFFFF7C8).w
		clr.b	($FFFFF7C9).w
		clr.b	$32(a0)
		bra.b	bou_Display
; ===========================================================================

bou_Grab:				; XREF: bou_Action
		tst.b	colicnt(a0)		; has Sonic touched the	pole?
		beq.b	bou_Display	; if not, branch
		lea	playerwk,a1
		move.w	8(a0),d0
		addi.w	#$14,d0
		cmp.w	8(a1),d0
		bcc.b	bou_Display
		clr.b	colicnt(a0)
		cmpi.b	#4,r_no0(a1)
		bcc.b	bou_Display
		clr.w	$10(a1)		; stop Sonic moving
		clr.w	$12(a1)		; stop Sonic moving
		move.w	8(a0),d0
		addi.w	#$14,d0
		move.w	d0,8(a1)
		bclr	#0,cddat(a1)
		move.b	#$11,$1C(a1)	; set Sonic's animation to "hanging" ($11)
		move.b	#1,($FFFFF7C8).w ; lock	controls
		move.b	#1,($FFFFF7C9).w ; disable wind	tunnel
		move.b	#1,$32(a0)	; begin	countdown to breakage

bou_Display:				; XREF: bou_Index
		bra.w	frameoutchk
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - pole that breaks (LZ)
; ---------------------------------------------------------------------------
Map_bou:
	include "_maps\bou.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0C - flapping door (LZ)
; ---------------------------------------------------------------------------

ben:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	ben_Index(pc,d0.w),d1
		jmp	ben_Index(pc,d1.w)
; ===========================================================================
ben_Index:	dc.w ben_Main-ben_Index
		dc.w ben_OpenClose-ben_Index
; ===========================================================================

ben_Main:				; XREF: ben_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_ben,4(a0)
		move.w	#$4328,2(a0)
		ori.b	#4,1(a0)
		move.b	#$28,$19(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		mulu.w	#60,d0		; multiply by 60 (1 second)
		move.w	d0,$32(a0)	; set flap delay time

ben_OpenClose:			; XREF: ben_Index
		subq.w	#1,$30(a0)	; subtract 1 from time delay
		bpl.b	ben_Solid	; if time remains, branch
		move.w	$32(a0),$30(a0)	; reset	time delay
		bchg	#0,$1C(a0)	; open/close door
		tst.b	1(a0)
		bpl.b	ben_Solid
		move.w	#$BB,d0
		jsr	(soundset).l ;	play door sound

ben_Solid:
		lea	(Ani_ben).l,a1
		bsr.w	patchg
		clr.b	($FFFFF7C9).w	; enable wind tunnel
		tst.b	$1A(a0)		; is the door open?
		bne.b	ben_Display	; if yes, branch
		move.w	playerwk+xposi,d0
		cmp.w	8(a0),d0	; is Sonic in front of the door?
		bcc.b	ben_Display	; if yes, branch
		move.b	#1,($FFFFF7C9).w ; disable wind	tunnel
		move.w	#$13,d1
		move.w	#$20,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk	; make the door	solid

ben_Display:
		bra.w	frameoutchk
; ===========================================================================
Ani_ben:
	include "_anim\ben.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - flapping door (LZ)
; ---------------------------------------------------------------------------
Map_ben:
	include "_maps\ben.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 71 - invisible	solid blocks
; ---------------------------------------------------------------------------

scoli:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	scoli_Index(pc,d0.w),d1
		jmp	scoli_Index(pc,d1.w)
; ===========================================================================
scoli_Index:	dc.w scoli_Main-scoli_Index
		dc.w scoli_Solid-scoli_Index
; ===========================================================================

scoli_Main:				; XREF: scoli_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_scoli,4(a0)
		move.w	#$8680,2(a0)
		ori.b	#4,1(a0)
		move.b	userflag(a0),d0	; get object type
		move.b	d0,d1
		andi.w	#$F0,d0		; read only the	1st byte
		addi.w	#$10,d0
		lsr.w	#1,d0
		move.b	d0,$19(a0)	; set object width
		andi.w	#$F,d1		; read only the	2nd byte
		addq.w	#1,d1
		lsl.w	#3,d1
		move.b	d1,$16(a0)	; set object height

scoli_Solid:				; XREF: scoli_Index
		bsr.w	ChkObjOnScreen
		bne.b	scoli_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk71

scoli_ChkDel:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	scoli_Delete
		tst.w	editmode	; are you using	debug mode?
		beq.b	scoli_NoDisplay	; if not, branch
		jmp	actionsub	; if yes, display the object
; ===========================================================================

scoli_NoDisplay:
		rts	
; ===========================================================================

scoli_Delete:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - invisible solid blocks
; ---------------------------------------------------------------------------
Map_scoli:
	include "_maps\scoli.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5D - fans (SLZ)
; ---------------------------------------------------------------------------

fun:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	fun_Index(pc,d0.w),d1
		jmp	fun_Index(pc,d1.w)
; ===========================================================================
fun_Index:	dc.w fun_Main-fun_Index
		dc.w fun_Delay-fun_Index
; ===========================================================================

fun_Main:				; XREF: fun_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_fun,4(a0)
		move.w	#$43A0,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)

fun_Delay:				; XREF: fun_Index
		btst	#1,userflag(a0)	; is object type 02/03?
		bne.b	fun_Blow	; if yes, branch
		subq.w	#1,$30(a0)	; subtract 1 from time delay
		bpl.b	fun_Blow	; if time remains, branch
		move.w	#120,$30(a0)	; set delay to 2 seconds
		bchg	#0,$32(a0)	; switch fan on/off
		beq.b	fun_Blow	; if fan is off, branch
		move.w	#180,$30(a0)	; set delay to 3 seconds

fun_Blow:
		tst.b	$32(a0)		; is fan switched on?
		bne.w	fun_ChkDel	; if not, branch
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		btst	#0,cddat(a0)
		bne.b	fun_ChkSonic
		neg.w	d0

fun_ChkSonic:
		addi.w	#$50,d0
		cmpi.w	#$F0,d0		; is Sonic more	than $A0 pixels	from the fan?
		bcc.b	fun_Animate	; if yes, branch
		move.w	$C(a1),d1
		addi.w	#$60,d1
		sub.w	$C(a0),d1
		bcs.b	fun_Animate
		cmpi.w	#$70,d1
		bcc.b	fun_Animate
		subi.w	#$50,d0
		bcc.b	loc_1159A
		not.w	d0
		add.w	d0,d0

loc_1159A:
		addi.w	#$60,d0
		btst	#0,cddat(a0)
		bne.b	loc_115A8
		neg.w	d0

loc_115A8:
		neg.b	d0
		asr.w	#4,d0
		btst	#0,userflag(a0)
		beq.b	fun_MoveSonic
		neg.w	d0

fun_MoveSonic:
		add.w	d0,8(a1)	; push Sonic away from the fan

fun_Animate:				; XREF: fun_ChkSonic
		subq.b	#1,$1E(a0)
		bpl.b	fun_ChkDel
		move.b	#0,$1E(a0)
		addq.b	#1,$1B(a0)
		cmpi.b	#3,$1B(a0)
		bcs.b	loc_115D8
		move.b	#0,$1B(a0)

loc_115D8:
		moveq	#0,d0
		btst	#0,userflag(a0)
		beq.b	loc_115E4
		moveq	#2,d0

loc_115E4:
		add.b	$1B(a0),d0
		move.b	d0,$1A(a0)

fun_ChkDel:				; XREF: fun_Animate
		bsr.w	actionsub
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - fans (SLZ)
; ---------------------------------------------------------------------------
Map_fun:
	include "_maps\fun.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5E - seesaws (SLZ)
; ---------------------------------------------------------------------------

sisoo:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	sisoo_Index(pc,d0.w),d1
		jsr	sisoo_Index(pc,d1.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	frameout
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
sisoo_Index:	dc.w sisoo_Main-sisoo_Index
		dc.w sisoo_Slope-sisoo_Index
		dc.w sisoo_Slope2-sisoo_Index
		dc.w sisoo_Spikeball-sisoo_Index
		dc.w sisoo_MoveSpike-sisoo_Index
		dc.w sisoo_SpikeFall-sisoo_Index
; ===========================================================================

sisoo_Main:				; XREF: sisoo_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_sisoo,4(a0)
		move.w	#$374,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$30,$19(a0)
		move.w	8(a0),$30(a0)
		tst.b	userflag(a0)		; is object type 00 ?
		bne.b	loc_116D2	; if not, branch
		bsr.w	actwkchk2
		bne.b	loc_116D2
		move.b	#$5E,0(a1)	; load spikeball object
		addq.b	#6,r_no0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	cddat(a0),cddat(a1)
		move.l	a0,$3C(a1)

loc_116D2:
		btst	#0,cddat(a0)
		beq.b	loc_116E0
		move.b	#2,$1A(a0)

loc_116E0:
		move.b	$1A(a0),$3A(a0)

sisoo_Slope:				; XREF: sisoo_Index
		move.b	$3A(a0),d1
		bsr.w	loc_11766
		lea	(sisoo_Data1).l,a2
		btst	#0,$1A(a0)
		beq.b	loc_11702
		lea	(sisoo_Data2).l,a2

loc_11702:
		lea	playerwk,a1
		move.w	$12(a1),$38(a0)
		move.w	#$30,d1
		jsr	(SlopeObject).l
		rts	
; ===========================================================================

sisoo_Slope2:				; XREF: sisoo_Index
		bsr.w	loc_1174A
		lea	(sisoo_Data1).l,a2
		btst	#0,$1A(a0)
		beq.b	loc_11730
		lea	(sisoo_Data2).l,a2

loc_11730:
		move.w	#$30,d1
		jsr	(ExitPlatform).l
		move.w	#$30,d1
		move.w	8(a0),d2
		jsr	SlopeObject2
		rts	
; ===========================================================================

loc_1174A:				; XREF: sisoo_Slope2
		moveq	#2,d1
		lea	playerwk,a1
		move.w	8(a0),d0
		sub.w	8(a1),d0
		bcc.b	loc_1175E
		neg.w	d0
		moveq	#0,d1

loc_1175E:
		cmpi.w	#8,d0
		bcc.b	loc_11766
		moveq	#1,d1

loc_11766:
		move.b	$1A(a0),d0
		cmp.b	d1,d0
		beq.b	locret_11790
		bcc.b	loc_11772
		addq.b	#2,d0

loc_11772:
		subq.b	#1,d0
		move.b	d0,$1A(a0)
		move.b	d1,$3A(a0)
		bclr	#0,1(a0)
		btst	#1,$1A(a0)
		beq.b	locret_11790
		bset	#0,1(a0)

locret_11790:
		rts	
; ===========================================================================

sisoo_Spikeball:			; XREF: sisoo_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_sisooa,4(a0)
		move.w	#$4F0,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$8B,colino(a0)
		move.b	#$C,$19(a0)
		move.w	8(a0),$30(a0)
		addi.w	#$28,8(a0)
		move.w	$C(a0),$34(a0)
		move.b	#1,$1A(a0)
		btst	#0,cddat(a0)
		beq.b	sisoo_MoveSpike
		subi.w	#$50,8(a0)
		move.b	#2,$3A(a0)

sisoo_MoveSpike:			; XREF: sisoo_Index
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$3A(a0),d0
		sub.b	$3A(a1),d0
		beq.b	loc_1183E
		bcc.b	loc_117FC
		neg.b	d0

loc_117FC:
		move.w	#-$818,d1
		move.w	#-$114,d2
		cmpi.b	#1,d0
		beq.b	loc_11822
		move.w	#-$AF0,d1
		move.w	#-$CC,d2
		cmpi.w	#$A00,$38(a1)
		blt.b	loc_11822
		move.w	#-$E00,d1
		move.w	#-$A0,d2

loc_11822:
		move.w	d1,$12(a0)
		move.w	d2,$10(a0)
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		bcc.b	loc_11838
		neg.w	$10(a0)

loc_11838:
		addq.b	#2,r_no0(a0)
		bra.b	sisoo_SpikeFall
; ===========================================================================

loc_1183E:				; XREF: sisoo_MoveSpike
		lea	(sisoo_Speeds).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	#$28,d2
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.b	loc_1185C
		neg.w	d2
		addq.w	#2,d0

loc_1185C:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,$C(a0)
		add.w	$30(a0),d2
		move.w	d2,8(a0)
		clr.w	$E(a0)
		clr.w	$A(a0)
		rts	
; ===========================================================================

sisoo_SpikeFall:			; XREF: sisoo_Index
		tst.w	$12(a0)
		bpl.b	loc_1189A
		bsr.w	speedset
		move.w	$34(a0),d0
		subi.w	#$2F,d0
		cmp.w	$C(a0),d0
		bgt.b	locret_11898
		bsr.w	speedset

locret_11898:
		rts	
; ===========================================================================

loc_1189A:				; XREF: sisoo_SpikeFall
		bsr.w	speedset
		movea.l	$3C(a0),a1
		lea	(sisoo_Speeds).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.b	loc_118BA
		addq.w	#2,d0

loc_118BA:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	$C(a0),d1
		bgt.b	locret_11938
		movea.l	$3C(a0),a1
		moveq	#2,d1
		tst.w	$10(a0)
		bmi.b	sisoo_Spring
		moveq	#0,d1

sisoo_Spring:
		move.b	d1,$3A(a1)
		move.b	d1,$3A(a0)
		cmp.b	$1A(a1),d1
		beq.b	loc_1192C
		bclr	#3,cddat(a1)
		beq.b	loc_1192C
		clr.b	r_no1(a1)
		move.b	#2,r_no0(a1)
		lea	playerwk,a2
		move.w	$12(a0),$12(a2)
		neg.w	$12(a2)
		bset	#1,cddat(a2)
		bclr	#3,cddat(a2)
		clr.b	$3C(a2)
		move.b	#$10,$1C(a2)	; change Sonic's animation to "spring" ($10)
		move.b	#2,r_no0(a2)
		move.w	#$CC,d0
		jsr	(soundset).l ;	play spring sound

loc_1192C:
		clr.w	$10(a0)
		clr.w	$12(a0)
		subq.b	#2,r_no0(a0)

locret_11938:
		rts	
; ===========================================================================
sisoo_Speeds:	dc.w $FFF8, $FFE4, $FFD1, $FFE4, $FFF8

sisoo_Data1:	incbin	misc\slzssaw1.bin
		even
sisoo_Data2:	incbin	misc\slzssaw2.bin
		even
; ---------------------------------------------------------------------------
; Sprite mappings - seesaws (SLZ)
; ---------------------------------------------------------------------------
Map_sisoo:
	include "_maps\sisoo.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - spiked balls on the	seesaws	(SLZ)
; ---------------------------------------------------------------------------
Map_sisooa:
	include "_maps\sisooballs.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 5F - walking bomb enemy (SLZ, SBZ)
; ---------------------------------------------------------------------------

brobo:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	brobo_Index(pc,d0.w),d1
		jmp	brobo_Index(pc,d1.w)
; ===========================================================================
brobo_Index:	dc.w brobo_Main-brobo_Index
		dc.w brobo_Action-brobo_Index
		dc.w brobo_Display-brobo_Index
		dc.w brobo_End-brobo_Index
; ===========================================================================

brobo_Main:				; XREF: brobo_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_brobo,4(a0)
		move.w	#$400,2(a0)
		ori.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$C,$19(a0)
		move.b	userflag(a0),d0
		beq.b	loc_11A3C
		move.b	d0,r_no0(a0)
		rts	
; ===========================================================================

loc_11A3C:
		move.b	#$9A,colino(a0)
		bchg	#0,cddat(a0)

brobo_Action:				; XREF: brobo_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	brobo_Index2(pc,d0.w),d1
		jsr	brobo_Index2(pc,d1.w)
		lea	(Ani_brobo).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================
brobo_Index2:	dc.w brobo_Walk-brobo_Index2
		dc.w brobo_Wait-brobo_Index2
		dc.w brobo_Explode-brobo_Index2
; ===========================================================================

brobo_Walk:				; XREF: brobo_Index2
		bsr.w	brobo_ChkSonic
		subq.w	#1,$30(a0)	; subtract 1 from time delay
		bpl.b	locret_11A96	; if time remains, branch
		addq.b	#2,r_no1(a0)
		move.w	#1535,$30(a0)	; set time delay to 25 seconds
		move.w	#$10,$10(a0)
		move.b	#1,$1C(a0)
		bchg	#0,cddat(a0)
		beq.b	locret_11A96
		neg.w	$10(a0)		; change direction

locret_11A96:
		rts	
; ===========================================================================

brobo_Wait:				; XREF: brobo_Index2
		bsr.w	brobo_ChkSonic
		subq.w	#1,$30(a0)	; subtract 1 from time delay
		bmi.b	loc_11AA8
		bsr.w	speedset2
		rts	
; ===========================================================================

loc_11AA8:
		subq.b	#2,r_no1(a0)
		move.w	#179,$30(a0)	; set time delay to 3 seconds
		clr.w	$10(a0)		; stop walking
		move.b	#0,$1C(a0)	; stop animation
		rts	
; ===========================================================================

brobo_Explode:				; XREF: brobo_Index2
		subq.w	#1,$30(a0)
		bpl.b	locret_11AD0
		move.b	#$3F,actno(a0)	; change bomb into an explosion
		move.b	#0,r_no0(a0)

locret_11AD0:
		rts	
; ===========================================================================

brobo_ChkSonic:				; XREF: brobo_Walk; brobo_Wait
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_11ADE
		neg.w	d0

loc_11ADE:
		cmpi.w	#$60,d0
		bcc.b	locret_11B5E
		move.w	playerwk+yposi,d0
		sub.w	$C(a0),d0
		bcc.b	brobo_MakeFuse
		neg.w	d0

brobo_MakeFuse:
		cmpi.w	#$60,d0
		bcc.b	locret_11B5E
		tst.w	editmode
		bne.b	locret_11B5E
		move.b	#4,r_no1(a0)
		move.w	#143,$30(a0)	; set fuse time
		clr.w	$10(a0)
		move.b	#2,$1C(a0)
		bsr.w	actwkchk2
		bne.b	locret_11B5E
		move.b	#$5F,actno(a1)	; load fuse object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	$C(a0),$34(a1)
		move.b	cddat(a0),cddat(a1)
		move.b	#4,userflag(a1)
		move.b	#3,$1C(a1)
		move.w	#$10,$12(a1)
		btst	#1,cddat(a0)
		beq.b	loc_11B54
		neg.w	$12(a1)

loc_11B54:
		move.w	#143,$30(a1)	; set fuse time
		move.l	a0,$3C(a1)

locret_11B5E:
		rts	
; ===========================================================================

brobo_Display:				; XREF: brobo_Index
		bsr.b	loc_11B70
		lea	(Ani_brobo).l,a1
		bsr.w	patchg
		bra.w	frameoutchk
; ===========================================================================

loc_11B70:
		subq.w	#1,$30(a0)
		bmi.b	loc_11B7C
		bsr.w	speedset2
		rts	
; ===========================================================================

loc_11B7C:
		clr.w	$30(a0)
		clr.b	r_no0(a0)
		move.w	$34(a0),$C(a0)
		moveq	#3,d1
		movea.l	a0,a1
		lea	(brobo_ShrSpeed).l,a2 ;	load shrapnel speed data
		bra.b	brobo_MakeShrap
; ===========================================================================

brobo_Loop:
		bsr.w	actwkchk2
		bne.b	loc_11BCE

brobo_MakeShrap:			; XREF: loc_11B7C
		move.b	#$5F,actno(a1)	; load shrapnel	object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#6,userflag(a1)
		move.b	#4,$1C(a1)
		move.w	(a2)+,$10(a1)
		move.w	(a2)+,$12(a1)
		move.b	#$98,colino(a1)
		bset	#7,1(a1)

loc_11BCE:
		dbra	d1,brobo_Loop	; repeat 3 more	times

		move.b	#6,r_no0(a0)

brobo_End:				; XREF: brobo_Index
		bsr.w	speedset2
		addi.w	#$18,$12(a0)
		lea	(Ani_brobo).l,a1
		bsr.w	patchg
		tst.b	1(a0)
		bpl.w	frameout
		bra.w	actionsub
; ===========================================================================
brobo_ShrSpeed:	dc.w $FE00, $FD00, $FF00, $FE00, $200, $FD00, $100, $FE00

Ani_brobo:
	include "_anim\brobo.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - walking bomb enemy (SLZ, SBZ)
; ---------------------------------------------------------------------------
Map_brobo:
	include "_maps\brobo.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 60 - Orbinaut enemy (LZ, SLZ, SBZ)
; ---------------------------------------------------------------------------

uni:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	uni_Index(pc,d0.w),d1
		jmp	uni_Index(pc,d1.w)
; ===========================================================================
uni_Index:	dc.w uni_Main-uni_Index
		dc.w uni_ChkSonic-uni_Index
		dc.w uni_Display-uni_Index
		dc.w uni_MoveOrb-uni_Index
		dc.w uni_ChkDel2-uni_Index
; ===========================================================================

uni_Main:				; XREF: uni_Index
		move.l	#Map_uni,4(a0)
		move.w	#$429,2(a0)	; SBZ specific code
		cmpi.b	#5,stageno ; check if level is SBZ
		beq.b	loc_11D02
		move.w	#$2429,2(a0)	; SLZ specific code

loc_11D02:
		cmpi.b	#1,stageno ; check if level is LZ
		bne.b	loc_11D10
		move.w	#$467,2(a0)	; LZ specific code

loc_11D10:
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$B,colino(a0)
		move.b	#$C,$19(a0)
		moveq	#0,d2
		lea	$37(a0),a2
		movea.l	a2,a3
		addq.w	#1,a2
		moveq	#3,d1

uni_MakeOrbs:
		bsr.w	actwkchk2
		bne.b	loc_11D90
		addq.b	#1,(a3)
		move.w	a1,d5
		subi.w	#-$3000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	actno(a0),actno(a1)	; load spiked orb object
		move.b	#6,r_no0(a1)
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		ori.b	#4,1(a1)
		move.b	#4,$18(a1)
		move.b	#8,$19(a1)
		move.b	#3,$1A(a1)
		move.b	#$98,colino(a1)
		move.b	d2,direc(a1)
		addi.b	#$40,d2
		move.l	a0,$3C(a1)
		dbra	d1,uni_MakeOrbs ; repeat sequence 3 more times

loc_11D90:
		moveq	#1,d0
		btst	#0,cddat(a0)
		beq.b	uni_Move
		neg.w	d0

uni_Move:
		move.b	d0,$36(a0)
		move.b	userflag(a0),r_no0(a0)	; if type is 02, skip the firing rountine
		addq.b	#2,r_no0(a0)
		move.w	#-$40,$10(a0)	; move orbinaut	to the left
		btst	#0,cddat(a0)	; is orbinaut reversed?
		beq.b	locret_11DBC	; if not, branch
		neg.w	$10(a0)		; move orbinaut	to the right

locret_11DBC:
		rts	
; ===========================================================================

uni_ChkSonic:				; XREF: uni_Index
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcc.b	loc_11DCA
		neg.w	d0

loc_11DCA:
		cmpi.w	#$A0,d0		; is Sonic within $A0 pixels of	orbinaut?
		bcc.b	uni_Animate	; if not, branch
		move.w	playerwk+yposi,d0
		sub.w	$C(a0),d0
		bcc.b	loc_11DDC
		neg.w	d0

loc_11DDC:
		cmpi.w	#$50,d0		; is Sonic within $50 pixels of	orbinaut?
		bcc.b	uni_Animate	; if not, branch
		tst.w	editmode	; is debug mode	on?
		bne.b	uni_Animate	; if yes, branch
		move.b	#1,$1C(a0)	; use "angry" animation

uni_Animate:
		lea	(Ani_uni).l,a1
		bsr.w	patchg
		bra.w	uni_ChkDel
; ===========================================================================

uni_Display:				; XREF: uni_Index
		bsr.w	speedset2

uni_ChkDel:				; XREF: uni_Animate
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	uni_ChkGone
		bra.w	actionsub
; ===========================================================================

uni_ChkGone:				; XREF: uni_ChkDel
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_11E34
		bclr	#7,2(a2,d0.w)

loc_11E34:
		lea	$37(a0),a2
		moveq	#0,d2
		move.b	(a2)+,d2
		subq.w	#1,d2
		bcs.b	uni_Delete

loc_11E40:
		moveq	#0,d0
		move.b	(a2)+,d0
		lsl.w	#6,d0
		addi.l	#$FFD000,d0
		movea.l	d0,a1
		bsr.w	frameout2
		dbra	d2,loc_11E40

uni_Delete:
		bra.w	frameout
; ===========================================================================

uni_MoveOrb:				; XREF: uni_Index
		movea.l	$3C(a0),a1
		cmpi.b	#$60,actno(a1)
		bne.w	frameout
		cmpi.b	#2,$1A(a1)
		bne.b	uni_Circle
		cmpi.b	#$40,direc(a0)
		bne.b	uni_Circle
		addq.b	#2,r_no0(a0)
		subq.b	#1,$37(a1)
		bne.b	uni_FireOrb
		addq.b	#2,r_no0(a1)

uni_FireOrb:
		move.w	#-$200,$10(a0)	; move orb to the left (quickly)
		btst	#0,cddat(a1)
		beq.b	uni_Display2
		neg.w	$10(a0)

uni_Display2:
		bra.w	actionsub
; ===========================================================================

uni_Circle:				; XREF: uni_MoveOrb
		move.b	direc(a0),d0
		jsr	(sinset).l
		asr.w	#4,d1
		add.w	8(a1),d1
		move.w	d1,8(a0)
		asr.w	#4,d0
		add.w	$C(a1),d0
		move.w	d0,$C(a0)
		move.b	$36(a1),d0
		add.b	d0,direc(a0)
		bra.w	actionsub
; ===========================================================================

uni_ChkDel2:				; XREF: uni_Index
		bsr.w	speedset2
		tst.b	1(a0)
		bpl.w	frameout
		bra.w	actionsub
; ===========================================================================
Ani_uni:
	include "_anim\uni.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Orbinaut enemy (LZ,	SLZ, SBZ)
; ---------------------------------------------------------------------------
Map_uni:
	include "_maps\uni.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 16 - harpoon (LZ)
; ---------------------------------------------------------------------------

yari:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yari_Index(pc,d0.w),d1
		jmp	yari_Index(pc,d1.w)
; ===========================================================================
yari_Index:	dc.w yari_Main-yari_Index
		dc.w yari_Move-yari_Index
		dc.w yari_Wait-yari_Index
; ===========================================================================

yari_Main:				; XREF: yari_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_yari,4(a0)
		move.w	#$3CC,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	userflag(a0),$1C(a0)
		move.b	#$14,$19(a0)
		move.w	#60,$30(a0)

yari_Move:				; XREF: yari_Index
		lea	(Ani_yari).l,a1
		bsr.w	patchg
		moveq	#0,d0
		move.b	$1A(a0),d0	; move frame number to d0
		move.b	yari_Data(pc,d0.w),colino(a0) ; load collision response (based on	d0)
		bra.w	frameoutchk
; ===========================================================================
yari_Data:	dc.b $9B, $9C, $9D, $9E, $9F, $A0
; ===========================================================================

yari_Wait:				; XREF: yari_Index
		subq.w	#1,$30(a0)
		bpl.b	yari_ChkDel
		move.w	#60,$30(a0)
		subq.b	#2,r_no0(a0)	; run "yari_Move" subroutine
		bchg	#0,$1C(a0)	; reverse animation

yari_ChkDel:
		bra.w	frameoutchk
; ===========================================================================
Ani_yari:
	include "_anim\yari.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - harpoon (LZ)
; ---------------------------------------------------------------------------
Map_yari:
	include "_maps\yari.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 61 - blocks (LZ)
; ---------------------------------------------------------------------------

dai3:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	dai3_Index(pc,d0.w),d1
		jmp	dai3_Index(pc,d1.w)
; ===========================================================================
dai3_Index:	dc.w dai3_Main-dai3_Index
		dc.w dai3_Action-dai3_Index

dai3_Var:	dc.b $10, $10		; width, height
		dc.b $20, $C
		dc.b $10, $10
		dc.b $10, $10
; ===========================================================================

dai3_Main:				; XREF: dai3_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_dai3,4(a0)
		move.w	#$43E6,2(a0)
		move.b	#4,1(a0)
		move.b	#3,$18(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#3,d0
		andi.w	#$E,d0
		lea	dai3_Var(pc,d0.w),a2
		move.b	(a2)+,$19(a0)
		move.b	(a2),$16(a0)
		lsr.w	#1,d0
		move.b	d0,$1A(a0)
		move.w	8(a0),$34(a0)
		move.w	$C(a0),$30(a0)
		move.b	userflag(a0),d0
		andi.b	#$F,d0
		beq.b	dai3_Action
		cmpi.b	#7,d0
		beq.b	dai3_Action
		move.b	#1,$38(a0)

dai3_Action:				; XREF: dai3_Index
		move.w	8(a0),-(sp)
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	dai3_TypeIndex(pc,d0.w),d1
		jsr	dai3_TypeIndex(pc,d1.w)
		move.w	(sp)+,d4
		tst.b	1(a0)
		bpl.b	dai3_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	hitchk
		move.b	d4,$3F(a0)
		bsr.w	loc_12180

dai3_ChkDel:
		move.w	$34(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		bra.w	actionsub
; ===========================================================================
dai3_TypeIndex:dc.w dai3_Type00-dai3_TypeIndex, dai3_Type01-dai3_TypeIndex
		dc.w dai3_Type02-dai3_TypeIndex, dai3_Type01-dai3_TypeIndex
		dc.w dai3_Type04-dai3_TypeIndex, dai3_Type05-dai3_TypeIndex
		dc.w dai3_Type02-dai3_TypeIndex, dai3_Type07-dai3_TypeIndex
; ===========================================================================

dai3_Type00:				; XREF: dai3_TypeIndex
		rts	
; ===========================================================================

dai3_Type01:				; XREF: dai3_TypeIndex
		tst.w	$36(a0)		; is Sonic standing on the object?
		bne.b	loc_120D6	; if yes, branch
		btst	#3,cddat(a0)
		beq.b	locret_120D4
		move.w	#30,$36(a0)	; wait for « second

locret_120D4:
		rts	
; ===========================================================================

loc_120D6:
		subq.w	#1,$36(a0)	; subtract 1 from waiting time
		bne.b	locret_120D4	; if time remains, branch
		addq.b	#1,userflag(a0)	; add 1	to type
		clr.b	$38(a0)
		rts	
; ===========================================================================

dai3_Type02:				; XREF: dai3_TypeIndex
		bsr.w	speedset2
		addq.w	#8,$12(a0)	; make object fall
		bsr.w	emycol_d
		tst.w	d1
		bpl.w	locret_12106
		addq.w	#1,d1
		add.w	d1,$C(a0)
		clr.w	$12(a0)		; stop when it touches the floor
		clr.b	userflag(a0)		; set type to 00 (non-moving type)

locret_12106:
		rts	
; ===========================================================================

dai3_Type04:				; XREF: dai3_TypeIndex
		bsr.w	speedset2
		subq.w	#8,$12(a0)	; make object rise
		bsr.w	ObjHitCeiling
		tst.w	d1
		bpl.w	locret_12126
		sub.w	d1,$C(a0)
		clr.w	$12(a0)		; stop when it touches the ceiling
		clr.b	userflag(a0)		; set type to 00 (non-moving type)

locret_12126:
		rts	
; ===========================================================================

dai3_Type05:				; XREF: dai3_TypeIndex
		cmpi.b	#1,$3F(a0)	; is Sonic touching the	object?
		bne.b	locret_12138	; if not, branch
		addq.b	#1,userflag(a0)	; if yes, add 1	to type
		clr.b	$38(a0)

locret_12138:
		rts	
; ===========================================================================

dai3_Type07:				; XREF: dai3_TypeIndex
		move.w	waterposi,d0
		sub.w	$C(a0),d0
		beq.b	locret_1217E
		bcc.b	loc_12162
		cmpi.w	#-2,d0
		bge.b	loc_1214E
		moveq	#-2,d0

loc_1214E:
		add.w	d0,$C(a0)	; make the block rise with water level
		bsr.w	ObjHitCeiling
		tst.w	d1
		bpl.w	locret_12160
		sub.w	d1,$C(a0)

locret_12160:
		rts	
; ===========================================================================

loc_12162:				; XREF: dai3_Type07
		cmpi.w	#2,d0
		ble.b	loc_1216A
		moveq	#2,d0

loc_1216A:
		add.w	d0,$C(a0)	; make the block sink with water level
		bsr.w	emycol_d
		tst.w	d1
		bpl.w	locret_1217E
		addq.w	#1,d1
		add.w	d1,$C(a0)

locret_1217E:
		rts	
; ===========================================================================

loc_12180:				; XREF: dai3_Action
		tst.b	$38(a0)
		beq.b	locret_121C0
		btst	#3,cddat(a0)
		bne.b	loc_1219A
		tst.b	$3E(a0)
		beq.b	locret_121C0
		subq.b	#4,$3E(a0)
		bra.b	loc_121A6
; ===========================================================================

loc_1219A:
		cmpi.b	#$40,$3E(a0)
		beq.b	locret_121C0
		addq.b	#4,$3E(a0)

loc_121A6:
		move.b	$3E(a0),d0
		jsr	(sinset).l
		move.w	#$400,d1
		muls.w	d1,d0
		swap	d0
		add.w	$30(a0),d0
		move.w	d0,$C(a0)

locret_121C0:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - blocks (LZ)
; ---------------------------------------------------------------------------
Map_dai3:
	include "_maps\dai3.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 62 - gargoyle head (LZ)
; ---------------------------------------------------------------------------

kazari:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	kazari_Index(pc,d0.w),d1
		jsr	kazari_Index(pc,d1.w)
		bra.w	frameoutchk
; ===========================================================================
kazari_Index:	dc.w kazari_Main-kazari_Index
		dc.w kazari_MakeFire-kazari_Index
		dc.w kazari_FireBall-kazari_Index
		dc.w kazari_AniFire-kazari_Index

kazari_SpitRate:	dc.b 30, 60, 90, 120, 150, 180,	210, 240
; ===========================================================================

kazari_Main:				; XREF: kazari_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_kazari,4(a0)
		move.w	#$42E9,2(a0)
		ori.b	#4,1(a0)
		move.b	#3,$18(a0)
		move.b	#$10,$19(a0)
		move.b	userflag(a0),d0	; get object type
		andi.w	#$F,d0		; read only the	2nd digit
		move.b	kazari_SpitRate(pc,d0.w),$1F(a0)	; set fireball spit rate
		move.b	$1F(a0),$1E(a0)
		andi.b	#$F,userflag(a0)

kazari_MakeFire:				; XREF: kazari_Index
		subq.b	#1,$1E(a0)
		bne.b	kazari_NoFire
		move.b	$1F(a0),$1E(a0)
		bsr.w	ChkObjOnScreen
		bne.b	kazari_NoFire
		bsr.w	actwkchk
		bne.b	kazari_NoFire
		move.b	#$62,actno(a1)	; load fireball	object
		addq.b	#4,r_no0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	1(a0),1(a1)
		move.b	cddat(a0),cddat(a1)

kazari_NoFire:
		rts	
; ===========================================================================

kazari_FireBall:				; XREF: kazari_Index
		addq.b	#2,r_no0(a0)
		move.b	#8,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_kazari,4(a0)
		move.w	#$2E9,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$98,colino(a0)
		move.b	#8,$19(a0)
		move.b	#2,$1A(a0)
		addq.w	#8,$C(a0)
		move.w	#$200,$10(a0)
		btst	#0,cddat(a0)
		bne.b	kazari_Sound
		neg.w	$10(a0)

kazari_Sound:
		move.w	#$AE,d0
		jsr	(soundset).l ;	play lava ball sound

kazari_AniFire:				; XREF: kazari_Index
		move.b	gametimer+1,d0
		andi.b	#7,d0
		bne.b	kazari_StopFire
		bchg	#0,$1A(a0)	; switch between frame 01 and 02

kazari_StopFire:
		bsr.w	speedset2
		btst	#0,cddat(a0)
		bne.b	kazari_StopFire2
		moveq	#-8,d3
		bsr.w	ObjHitWallLeft
		tst.w	d1
		bmi.w	frameout	; delete if the	fireball hits a	wall
		rts	
; ===========================================================================

kazari_StopFire2:
		moveq	#8,d3
		bsr.w	ObjHitWallRight
		tst.w	d1
		bmi.w	frameout
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - gargoyle head (LZ)
; ---------------------------------------------------------------------------
Map_kazari:
	include "_maps\kazari.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 63 - platforms	on a conveyor belt (LZ)
; ---------------------------------------------------------------------------

kassya:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	kassya_Index(pc,d0.w),d1
		jsr	kassya_Index(pc,d1.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	loc_1236A

kassya_Display:				; XREF: loc_1236A
		bra.w	actionsub
; ===========================================================================

loc_1236A:				; XREF: kassya
		cmpi.b	#2,stageno+1
		bne.b	loc_12378
		cmpi.w	#-$80,d0
		bcc.b	kassya_Display

loc_12378:
		move.b	$2F(a0),d0
		bpl.w	frameout
		andi.w	#$7F,d0
		lea	($FFFFF7C1).w,a2
		bclr	#0,(a2,d0.w)
		bra.w	frameout
; ===========================================================================
kassya_Index:	dc.w kassya_Main-kassya_Index
		dc.w loc_124B2-kassya_Index
		dc.w loc_124C2-kassya_Index
		dc.w loc_124DE-kassya_Index
; ===========================================================================

kassya_Main:				; XREF: kassya_Index
		move.b	userflag(a0),d0
		bmi.w	loc_12460
		addq.b	#2,r_no0(a0)
		move.l	#Map_kassya,4(a0)
		move.w	#$43F6,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		cmpi.b	#$7F,userflag(a0)
		bne.b	loc_123E2
		addq.b	#4,r_no0(a0)
		move.w	#$3F6,2(a0)
		move.b	#1,$18(a0)
		bra.w	loc_124DE
; ===========================================================================

loc_123E2:
		move.b	#4,$1A(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.w	d0,d1
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	kassya_Data(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$38(a0)
		move.w	(a2)+,$30(a0)
		move.l	a2,$3C(a0)
		andi.w	#$F,d1
		lsl.w	#2,d1
		move.b	d1,$38(a0)
		move.b	#4,$3A(a0)
		tst.b	($FFFFF7C0).w
		beq.b	loc_1244C
		move.b	#1,$3B(a0)
		neg.b	$3A(a0)
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		bcs.b	loc_12448
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.b	loc_12448
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_12448:
		move.b	d1,$38(a0)

loc_1244C:
		move.w	(a2,d1.w),$34(a0)
		move.w	2(a2,d1.w),$36(a0)
		bsr.w	kassya_ChangeDir
		bra.w	loc_124B2
; ===========================================================================

loc_12460:				; XREF: kassya_Main
		move.b	d0,$2F(a0)
		andi.w	#$7F,d0
		lea	($FFFFF7C1).w,a2
		bset	#0,(a2,d0.w)
		bne.w	frameout
		add.w	d0,d0
		andi.w	#$1E,d0
		addi.w	#$70,d0
		lea	(ObjPos_Index).l,a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d1
		movea.l	a0,a1
		bra.b	kassya_MakePtfms
; ===========================================================================

kassya_Loop:
		bsr.w	actwkchk
		bne.b	loc_124AA

kassya_MakePtfms:			; XREF: loc_12460
		move.b	#$63,actno(a1)
		move.w	(a2)+,8(a1)
		move.w	(a2)+,$C(a1)
		move.w	(a2)+,d0
		move.b	d0,userflag(a1)

loc_124AA:
		dbra	d1,kassya_Loop

		addq.l	#4,sp
		rts	
; ===========================================================================

loc_124B2:				; XREF: kassya_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(PlatformObject).l
		bra.w	sub_12502
; ===========================================================================

loc_124C2:				; XREF: kassya_Index
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(ExitPlatform).l
		move.w	8(a0),-(sp)
		bsr.w	sub_12502
		move.w	(sp)+,d2
		jmp	(MvSonicOnPtfm2).l
; ===========================================================================

loc_124DE:				; XREF: kassya_Index
		move.w	gametimer,d0
		andi.w	#3,d0
		bne.b	loc_124FC
		moveq	#1,d1
		tst.b	($FFFFF7C0).w
		beq.b	loc_124F2
		neg.b	d1

loc_124F2:
		add.b	d1,$1A(a0)
		andi.b	#3,$1A(a0)

loc_124FC:
		addq.l	#4,sp
		bra.w	frameoutchk

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_12502:				; XREF: loc_124B2; loc_124C2
		tst.b	($FFFFF7EE).w
		beq.b	loc_12520
		tst.b	$3B(a0)
		bne.b	loc_12520
		move.b	#1,$3B(a0)
		move.b	#1,($FFFFF7C0).w
		neg.b	$3A(a0)
		bra.b	loc_12534
; ===========================================================================

loc_12520:
		move.w	8(a0),d0
		cmp.w	$34(a0),d0
		bne.b	loc_1256A
		move.w	$C(a0),d0
		cmp.w	$36(a0),d0
		bne.b	loc_1256A

loc_12534:
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		bcs.b	loc_12552
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.b	loc_12552
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_12552:
		move.b	d1,$38(a0)
		movea.l	$3C(a0),a1
		move.w	(a1,d1.w),$34(a0)
		move.w	2(a1,d1.w),$36(a0)
		bsr.w	kassya_ChangeDir

loc_1256A:
		bsr.w	speedset2
		rts	
; End of function sub_12502


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


kassya_ChangeDir:			; XREF: loc_123E2; sub_12502
		moveq	#0,d0
		move.w	#-$100,d2
		move.w	8(a0),d0
		sub.w	$34(a0),d0
		bcc.b	loc_12584
		neg.w	d0
		neg.w	d2

loc_12584:
		moveq	#0,d1
		move.w	#-$100,d3
		move.w	$C(a0),d1
		sub.w	$36(a0),d1
		bcc.b	loc_12598
		neg.w	d1
		neg.w	d3

loc_12598:
		cmp.w	d0,d1
		bcs.b	loc_125C2
		move.w	8(a0),d0
		sub.w	$34(a0),d0
		beq.b	loc_125AE
		ext.l	d0
		asl.l	#8,d0
		divs.w	d1,d0
		neg.w	d0

loc_125AE:
		move.w	d0,$10(a0)
		move.w	d3,$12(a0)
		swap	d0
		move.w	d0,$A(a0)
		clr.w	$E(a0)
		rts	
; ===========================================================================

loc_125C2:				; XREF: kassya_ChangeDir
		move.w	$C(a0),d1
		sub.w	$36(a0),d1
		beq.b	loc_125D4
		ext.l	d1
		asl.l	#8,d1
		divs.w	d0,d1
		neg.w	d1

loc_125D4:
		move.w	d1,$12(a0)
		move.w	d2,$10(a0)
		swap	d1
		move.w	d1,$E(a0)
		clr.w	$A(a0)
		rts	
; End of function kassya_ChangeDir

; ===========================================================================
kassya_Data:	dc.w word_125F4-kassya_Data
		dc.w word_12610-kassya_Data
		dc.w word_12628-kassya_Data
		dc.w word_1263C-kassya_Data
		dc.w word_12650-kassya_Data
		dc.w word_12668-kassya_Data
word_125F4:	dc.w $18, $1070, $1078,	$21A, $10BE, $260, $10BE, $393
		dc.w $108C, $3C5, $1022, $390, $1022, $244
word_12610:	dc.w $14, $1280, $127E,	$280, $12CE, $2D0, $12CE, $46E
		dc.w $1232, $420, $1232, $2CC
word_12628:	dc.w $10, $D68,	$D22, $482, $D22, $5DE,	$DAE, $5DE, $DAE, $482
word_1263C:	dc.w $10, $DA0,	$D62, $3A2, $DEE, $3A2,	$DEE, $4DE, $D62, $4DE
word_12650:	dc.w $14, $D00,	$CAC, $242, $DDE, $242,	$DDE, $3DE, $C52, $3DE,	$C52, $29C
word_12668:	dc.w $10, $1300, $1252,	$20A, $13DE, $20A, $13DE, $2BE,	$1252, $2BE

; ---------------------------------------------------------------------------
; Sprite mappings - platforms on a conveyor belt (LZ)
; ---------------------------------------------------------------------------
Map_kassya:
	include "_maps\kassya.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 64 - bubbles (LZ)
; ---------------------------------------------------------------------------

awa:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	awa_Index(pc,d0.w),d1
		jmp	awa_Index(pc,d1.w)
; ===========================================================================
awa_Index:	dc.w awa_Main-awa_Index
		dc.w awa_Animate-awa_Index
		dc.w awa_ChkWater-awa_Index
		dc.w awa_Display2-awa_Index
		dc.w awa_Delete3-awa_Index
		dc.w awa_BblMaker-awa_Index
; ===========================================================================

awa_Main:				; XREF: awa_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_awa,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	userflag(a0),d0	; get object type
		bpl.b	awa_Bubble	; if type is $0-$7F, branch
		addq.b	#8,r_no0(a0)
		andi.w	#$7F,d0		; read only last 7 bits	(deduct	$80)
		move.b	d0,$32(a0)
		move.b	d0,$33(a0)
		move.b	#6,$1C(a0)
		bra.w	awa_BblMaker
; ===========================================================================

awa_Bubble:				; XREF: awa_Main
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)	; float	bubble upwards
		jsr	(random).l
		move.b	d0,direc(a0)

awa_Animate:				; XREF: awa_Index
		lea	(Ani_awa).l,a1
		jsr	patchg
		cmpi.b	#6,$1A(a0)
		bne.b	awa_ChkWater
		move.b	#1,$2E(a0)

awa_ChkWater:				; XREF: awa_Index
		move.w	waterposi,d0
		cmp.w	$C(a0),d0	; is bubble underwater?
		bcs.b	awa_Wobble	; if yes, branch

awa_Burst:				; XREF: awa_Wobble
		move.b	#6,r_no0(a0)
		addq.b	#3,$1C(a0)	; run "bursting" animation
		bra.w	awa_Display2
; ===========================================================================

awa_Wobble:				; XREF: awa_ChkWater
		move.b	direc(a0),d0
		addq.b	#1,direc(a0)
		andi.w	#$7F,d0
		lea	(plawa_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)	; change bubble's horizontal position
		tst.b	$2E(a0)
		beq.b	awa_Display
		bsr.w	awa_ChkSonic	; has Sonic touched the	bubble?
		beq.b	awa_Display	; if not, branch

		bsr.w	plairset	; cancel countdown music
		move.w	#$AD,d0
		jsr	(soundset).l ;	play collecting	bubble sound
		lea	playerwk,a1
		clr.w	$10(a1)
		clr.w	$12(a1)
		clr.w	$14(a1)
		move.b	#$15,$1C(a1)
		move.w	#$23,$3E(a1)
		move.b	#0,$3C(a1)
		bclr	#5,cddat(a1)
		bclr	#4,cddat(a1)
		btst	#2,cddat(a1)
		beq.w	awa_Burst
		bclr	#2,cddat(a1)
		move.b	#$13,$16(a1)
		move.b	#9,$17(a1)
		subq.w	#5,$C(a1)
		bra.w	awa_Burst
; ===========================================================================

awa_Display:				; XREF: awa_Wobble
		bsr.w	speedset2
		tst.b	1(a0)
		bpl.b	awa_Delete
		jmp	actionsub
; ===========================================================================

awa_Delete:
		jmp	frameout
; ===========================================================================

awa_Display2:				; XREF: awa_Index
		lea	(Ani_awa).l,a1
		jsr	patchg
		tst.b	1(a0)
		bpl.b	awa_Delete2
		jmp	actionsub
; ===========================================================================

awa_Delete2:
		jmp	frameout
; ===========================================================================

awa_Delete3:				; XREF: awa_Index
		bra.w	frameout
; ===========================================================================

awa_BblMaker:				; XREF: awa_Index
		tst.w	$36(a0)
		bne.b	loc_12874
		move.w	waterposi,d0
		cmp.w	$C(a0),d0	; is bubble maker underwater?
		bcc.w	awa_ChkDel	; if not, branch
		tst.b	1(a0)
		bpl.w	awa_ChkDel
		subq.w	#1,$38(a0)
		bpl.w	loc_12914
		move.w	#1,$36(a0)

loc_1283A:
		jsr	(random).l
		move.w	d0,d1
		andi.w	#7,d0
		cmpi.w	#6,d0
		bcc.b	loc_1283A

		move.b	d0,$34(a0)
		andi.w	#$C,d1
		lea	(awa_BblTypes).l,a1
		adda.w	d1,a1
		move.l	a1,$3C(a0)
		subq.b	#1,$32(a0)
		bpl.b	loc_12872
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)

loc_12872:
		bra.b	loc_1287C
; ===========================================================================

loc_12874:				; XREF: awa_BblMaker
		subq.w	#1,$38(a0)
		bpl.w	loc_12914

loc_1287C:
		jsr	(random).l
		andi.w	#$1F,d0
		move.w	d0,$38(a0)
		bsr.w	actwkchk
		bne.b	loc_128F8
		move.b	#$64,actno(a1)	; load bubble object
		move.w	8(a0),8(a1)
		jsr	(random).l
		andi.w	#$F,d0
		subq.w	#8,d0
		add.w	d0,8(a1)
		move.w	$C(a0),$C(a1)
		moveq	#0,d0
		move.b	$34(a0),d0
		movea.l	$3C(a0),a2
		move.b	(a2,d0.w),userflag(a1)
		btst	#7,$36(a0)
		beq.b	loc_128F8
		jsr	(random).l
		andi.w	#3,d0
		bne.b	loc_128E4
		bset	#6,$36(a0)
		bne.b	loc_128F8
		move.b	#2,userflag(a1)

loc_128E4:
		tst.b	$34(a0)
		bne.b	loc_128F8
		bset	#6,$36(a0)
		bne.b	loc_128F8
		move.b	#2,userflag(a1)

loc_128F8:
		subq.b	#1,$34(a0)
		bpl.b	loc_12914
		jsr	(random).l
		andi.w	#$7F,d0
		addi.w	#$80,d0
		add.w	d0,$38(a0)
		clr.w	$36(a0)

loc_12914:
		lea	(Ani_awa).l,a1
		jsr	patchg

awa_ChkDel:				; XREF: awa_BblMaker
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	frameout
		move.w	waterposi,d0
		cmp.w	$C(a0),d0
		bcs.w	actionsub
		rts	
; ===========================================================================
; bubble production sequence

; 0 = small bubble, 1 =	large bubble

awa_BblTypes:	dc.b 0,	1, 0, 0, 0, 0, 1, 0, 0,	0, 0, 1, 0, 1, 0, 0, 1,	0

; ===========================================================================

awa_ChkSonic:				; XREF: awa_Wobble
		tst.b	($FFFFF7C8).w
		bmi.b	loc_12998
		lea	playerwk,a1
		move.w	8(a1),d0
		move.w	8(a0),d1
		subi.w	#$10,d1
		cmp.w	d0,d1
		bcc.b	loc_12998
		addi.w	#$20,d1
		cmp.w	d0,d1
		bcs.b	loc_12998
		move.w	$C(a1),d0
		move.w	$C(a0),d1
		cmp.w	d0,d1
		bcc.b	loc_12998
		addi.w	#$10,d1
		cmp.w	d0,d1
		bcs.b	loc_12998
		moveq	#1,d0
		rts	
; ===========================================================================

loc_12998:
		moveq	#0,d0
		rts	
; ===========================================================================
Ani_awa:
	include "_anim\awa.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - bubbles (LZ)
; ---------------------------------------------------------------------------
Map_awa:
	include "_maps\awa.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 65 - waterfalls (LZ)
; ---------------------------------------------------------------------------

mizu:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	mizu_Index(pc,d0.w),d1
		jmp	mizu_Index(pc,d1.w)
; ===========================================================================
mizu_Index:	dc.w mizu_Main-mizu_Index
		dc.w mizu_Animate-mizu_Index
		dc.w mizu_ChkDel-mizu_Index
		dc.w mizu_FixHeight-mizu_Index
		dc.w loc_12B36-mizu_Index
; ===========================================================================

mizu_Main:				; XREF: mizu_Index
		addq.b	#4,r_no0(a0)
		move.l	#Map_mizu,4(a0)
		move.w	#$4259,2(a0)
		ori.b	#4,1(a0)
		move.b	#$18,$19(a0)
		move.b	#1,$18(a0)
		move.b	userflag(a0),d0	; get object type
		bpl.b	loc_12AE6
		bset	#7,2(a0)

loc_12AE6:
		andi.b	#$F,d0		; read only the	2nd byte
		move.b	d0,$1A(a0)	; set frame number
		cmpi.b	#9,d0		; is object type $x9 ?
		bne.b	mizu_ChkDel	; if not, branch
		clr.b	$18(a0)
		subq.b	#2,r_no0(a0)
		btst	#6,userflag(a0)	; is object type $4x ?
		beq.b	loc_12B0A	; if not, branch
		move.b	#6,r_no0(a0)

loc_12B0A:
		btst	#5,userflag(a0)	; is object type $Ax ?
		beq.b	mizu_Animate	; if not, branch
		move.b	#8,r_no0(a0)

mizu_Animate:				; XREF: mizu_Index
		lea	(Ani_mizu).l,a1
		jsr	patchg

mizu_ChkDel:				; XREF: mizu_Index
		bra.w	frameoutchk
; ===========================================================================

mizu_FixHeight:			; XREF: mizu_Index
		move.w	waterposi,d0
		subi.w	#$10,d0
		move.w	d0,$C(a0)	; match	object position	to water height
		bra.b	mizu_Animate
; ===========================================================================

loc_12B36:				; XREF: mizu_Index
		bclr	#7,2(a0)
		cmpi.b	#7,($FFFFA506).w
		bne.b	mizu_Animate2
		bset	#7,2(a0)

mizu_Animate2:
		bra.b	mizu_Animate
; ===========================================================================
Ani_mizu:
	include "_anim\mizu.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - waterfalls (LZ)
; ---------------------------------------------------------------------------
Map_mizu:
	include "_maps\mizu.asm"

; ===========================================================================

play00:
		tst.w	editmode
		beq.b	?jump
		jmp		edit

?jump:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	play00_move_tbl(pc,d0.w),d1
		jmp		play00_move_tbl(pc,d1.w)

play00_move_tbl:
		dc.w	play00init-play00_move_tbl
		dc.w	play00move-play00_move_tbl
		dc.w	play00damage-play00_move_tbl
		dc.w	play00die-play00_move_tbl
		dc.w	play00erase-play00_move_tbl
play00init:
		addq.b	#word,r_no0(a0)
		move.b	#19,sprvsize(a0)
		move.b	#9,sprhsize(a0)
		move.l	#playpat,patbase(a0)
		move.w	#$780,sproffset(a0)
		move.b	#2,sprpri(a0)
		move.b	#24,sprhs(a0)
		move.b	#4,actflg(a0)
		move.w	#$0600,plmaxspdwk
		move.w	#$000c,pladdspdwk
		move.w	#$0080,plretspdwk
play00move:
		tst.w	debugflag
		beq.b	?jump0
		btst.b	#4,swdata1+1
		beq.b	?jump0
		move.w	#1,editmode
		clr.b	plautoflag
		rts

?jump0:
		tst.b	plautoflag
		bne.b	?jump1
		move.w	swdata1+0,swdata+0
?jump1:
		btst.b	#0,($FFFFF7C8).w
		bne.b	?jump2
		moveq	#0,d0
		move.b	cddat(a0),d0
		andi.w	#6,d0
		move.w	play00_move_tbl2(pc,d0.w),d1
		jsr		play00_move_tbl2(pc,d1.w)
?jump2:
		bsr.b	playpowercnt
		bsr.w	playposiwkset
		bsr.w	plwaterchk
		move.b	dirstk,actfree+10(a0)
		move.b	dirstk+2,actfree+11(a0)
		tst.b	watercoliflag
		beq.b	?jump3
		tst.b	mstno(a0)
		bne.b	?jump3
		move.b	mstno+1(a0),mstno(a0)
?jump3:
		bsr.w	spatset
		tst.b	($FFFFF7C8).w
		bmi.b	?jump4
		jsr		pcol

?jump4:
		bsr.w	loopchk
		bsr.w	Loadplaywrtpat
		rts	

play00_move_tbl2:
		dc.w	play00walk-play00_move_tbl2
		dc.w	play00jump-play00_move_tbl2
		dc.w	ball00walk-play00_move_tbl2
		dc.w	ball00jump-play00_move_tbl2

mustbl:
		dc.b	$81,$82,$83,$84,$85,$86
		align

playpowercnt:
		move.w	$30(a0),d0
		beq.b	?jump0
		subq.w	#1,$30(a0)
		lsr.w	#3,d0
		bcc.b	?jump1

?jump0:
		jsr	actionsub

?jump1:
		tst.b	plpower_m
		beq.b	?jump4
		tst.w	$32(a0)
		beq.b	?jump4
		subq.w	#1,$32(a0)
		bne.b	?jump4
		tst.b	($FFFFF7AA).w
		bne.b	?jump3
		cmpi.w	#$C,pl_air
		bcs.b	?jump3
		moveq	#0,d0
		move.b	stageno,d0
		cmpi.w	#$0103,stageno
		bne.b	?jump2
		moveq	#5,d0
?jump2:
		lea	(mustbl).l,a1
		move.b	(a1,d0.w),d0
		jsr		bgmset
?jump3:
		move.b	#0,plpower_m
?jump4:
		tst.b	plpower_s
		beq.b	?jump5
		tst.w	$34(a0)
		beq.b	?jump5
		subq.w	#1,$34(a0)
		bne.b	?jump5
		move.w	#$600,plmaxspdwk
		move.w	#$C,pladdspdwk
		move.w	#$80,plretspdwk
		move.b	#0,plpower_s
		move.w	#$E3,d0
		jmp		bgmset
?jump5:
		rts	

playposiwkset:
		move.w	plposiwkadr,d0
		lea		playposiwk,a1
		lea		(a1,d0.w),a1
		move.w	xposi(a0),(a1)+
		move.w	yposi(a0),(a1)+
		addq.b	#long,plposiwkadr+1
		rts

plwaterchk:
		cmpi.b	#1,stageno
		beq.b	?jump0

?end:
		rts

?jump0:
		move.w	waterposi,d0
		cmp.w	$C(a0),d0
		bge.b	?jump1	
		bset	#6,cddat(a0)
		bne.b	?end
		bsr.w	plairset
		move.b	#$A,($FFFFD340).w
		move.b	#$81,($FFFFD368).w
		move.w	#$300,plmaxspdwk
		move.w	#6,pladdspdwk
		move.w	#$40,plretspdwk
		asr	xspeed(a0)
		asr	$12(a0)
		asr	$12(a0)
		beq.b	?end
		move.b	#8,($FFFFD300).w
		move.w	#$aa,d0
		jmp		soundset

?jump1:
		bclr	#6,cddat(a0)
		beq.b	?end
		bsr.w	plairset
		move.w	#$600,plmaxspdwk ; restore Sonic's speed
		move.w	#$C,pladdspdwk ; restore Sonic's acceleration
		move.w	#$80,plretspdwk ; restore Sonic's deceleration
		asl	$12(a0)
		beq.w	?end
		move.b	#8,($FFFFD300).w ; load	splash object
		cmpi.w	#-$1000,$12(a0)
		bgt.b	?jump2
		move.w	#-$1000,$12(a0)	; set maximum speed on leaving water

?jump2:
		move.w	#$aa,d0
		jmp		soundset

play00walk:
		bsr.w	jumpchk
		bsr.w	keispd
		bsr.w	levermove
		bsr.w	ballchk
		bsr.w	limitchk
		jsr		speedset2
		bsr.w	fcol
		bsr.w	fallchk
		rts

play00jump:
		bsr.w	jumpchk2
		bsr.w	jumpmove
		bsr.w	limitchk
		jsr		speedset
		btst.b	#cd_water,cddat(a0)
		beq.b	?jump
		subi.w	#40,yspeed(a0)
?jump:
		bsr.w	direcchg
		bsr.w	jumpcolchk
		rts	

ball00walk:
		bsr.w	jumpchk
		bsr.w	keispd2
		bsr.w	balllmove
		bsr.w	limitchk
		jsr		speedset2
		bsr.w	fcol
		bsr.w	fallchk
		rts	
; ===========================================================================

ball00jump:				; XREF: play00_move_tbl2
		bsr.w	jumpchk2
		bsr.w	jumpmove
		bsr.w	limitchk
		jsr	speedset
		btst	#6,cddat(a0)
		beq.b	loc_12EA6
		subi.w	#$28,$12(a0)

loc_12EA6:
		bsr.w	direcchg
		bsr.w	jumpcolchk
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	make Sonic walk/run
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


levermove:				; XREF: play00walk
		move.w	plmaxspdwk,d6
		move.w	pladdspdwk,d5
		move.w	plretspdwk,d4
		tst.b	mizuflag
		bne.w	loc_12FEE
		tst.w	$3E(a0)
		bne.w	play00_ResetScr
		btst	#2,swdata+0 ; is left being pressed?
		beq.b	play00_NotLeft	; if not, branch
		bsr.w	plwalk_l

play00_NotLeft:
		btst	#3,swdata+0 ; is right being pressed?
		beq.b	play00_NotRight	; if not, branch
		bsr.w	plwalk_r

play00_NotRight:
		move.b	direc(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0		; is Sonic on a	slope?
		bne.w	play00_ResetScr	; if yes, branch
		tst.w	$14(a0)		; is Sonic moving?
		bne.w	play00_ResetScr	; if yes, branch
		bclr	#5,cddat(a0)
		move.b	#5,$1C(a0)	; use "standing" animation
		btst	#3,cddat(a0)
		beq.b	Sonic_Balance
		moveq	#0,d0
		move.b	$3D(a0),d0
		lsl.w	#6,d0
		lea	playerwk,a1
		lea	(a1,d0.w),a1
		tst.b	cddat(a1)
		bmi.b	Sonic_LookUp
		moveq	#0,d1
		move.b	$19(a1),d1
		move.w	d1,d2
		add.w	d2,d2
		subq.w	#4,d2
		add.w	8(a0),d1
		sub.w	8(a1),d1
		cmpi.w	#4,d1
		blt.b	loc_12F6A
		cmp.w	d2,d1
		bge.b	loc_12F5A
		bra.b	Sonic_LookUp
; ===========================================================================

Sonic_Balance:
		jsr	emycol_d
		cmpi.w	#$C,d1
		blt.b	Sonic_LookUp
		cmpi.b	#3,$36(a0)
		bne.b	loc_12F62

loc_12F5A:
		bclr	#0,cddat(a0)
		bra.b	loc_12F70
; ===========================================================================

loc_12F62:
		cmpi.b	#3,$37(a0)
		bne.b	Sonic_LookUp

loc_12F6A:
		bset	#0,cddat(a0)

loc_12F70:
		move.b	#6,$1C(a0)	; use "balancing" animation
		bra.b	play00_ResetScr
; ===========================================================================

Sonic_LookUp:
		btst	#0,swdata+0 ; is up being pressed?
		beq.b	Sonic_Duck	; if not, branch
		move.b	#7,$1C(a0)	; use "looking up" animation
		cmpi.w	#$C8,($FFFFF73E).w
		beq.b	loc_12FC2
		addq.w	#2,($FFFFF73E).w
		bra.b	loc_12FC2
; ===========================================================================

Sonic_Duck:
		btst	#1,swdata+0 ; is down being pressed?
		beq.b	play00_ResetScr	; if not, branch
		move.b	#8,$1C(a0)	; use "ducking"	animation
		cmpi.w	#8,($FFFFF73E).w
		beq.b	loc_12FC2
		subq.w	#2,($FFFFF73E).w
		bra.b	loc_12FC2
; ===========================================================================

play00_ResetScr:
		cmpi.w	#$60,($FFFFF73E).w ; is	screen in its default position?
		beq.b	loc_12FC2	; if yes, branch
		bcc.b	loc_12FBE
		addq.w	#4,($FFFFF73E).w ; move	screen back to default

loc_12FBE:
		subq.w	#2,($FFFFF73E).w ; move	screen back to default

loc_12FC2:
		move.b	swdata+0,d0
		andi.b	#$C,d0		; is left/right	pressed?
		bne.b	loc_12FEE	; if yes, branch
		move.w	$14(a0),d0
		beq.b	loc_12FEE
		bmi.b	loc_12FE2
		sub.w	d5,d0
		bcc.b	loc_12FDC
		move.w	#0,d0

loc_12FDC:
		move.w	d0,$14(a0)
		bra.b	loc_12FEE
; ===========================================================================

loc_12FE2:
		add.w	d5,d0
		bcc.b	loc_12FEA
		move.w	#0,d0

loc_12FEA:
		move.w	d0,$14(a0)

loc_12FEE:
		move.b	direc(a0),d0
		jsr	(sinset).l
		muls.w	$14(a0),d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)

loc_1300C:
		move.b	direc(a0),d0
		addi.b	#$40,d0
		bmi.b	locret_1307C
		move.b	#$40,d1
		tst.w	$14(a0)
		beq.b	locret_1307C
		bmi.b	loc_13024
		neg.w	d1

loc_13024:
		move.b	direc(a0),d0
		add.b	d1,d0
		move.w	d0,-(sp)
		bsr.w	Sonic_WalkSpeed
		move.w	(sp)+,d0
		tst.w	d1
		bpl.b	locret_1307C
		asl.w	#8,d1
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.b	loc_13078
		cmpi.b	#$40,d0
		beq.b	loc_13066
		cmpi.b	#$80,d0
		beq.b	loc_13060
		add.w	d1,$10(a0)
		bset	#5,cddat(a0)
		move.w	#0,$14(a0)
		rts	
; ===========================================================================

loc_13060:
		sub.w	d1,$12(a0)
		rts	
; ===========================================================================

loc_13066:
		sub.w	d1,$10(a0)
		bset	#5,cddat(a0)
		move.w	#0,$14(a0)
		rts	
; ===========================================================================

loc_13078:
		add.w	d1,$12(a0)

locret_1307C:
		rts	
; End of function levermove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


plwalk_l:				; XREF: levermove
		move.w	$14(a0),d0
		beq.b	loc_13086
		bpl.b	loc_130B2

loc_13086:
		bset	#0,cddat(a0)
		bne.b	loc_1309A
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)

loc_1309A:
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.b	loc_130A6
		move.w	d1,d0

loc_130A6:
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)	; use walking animation
		rts	
; ===========================================================================

loc_130B2:				; XREF: plwalk_l
		sub.w	d4,d0
		bcc.b	loc_130BA
		move.w	#-$80,d0

loc_130BA:
		move.w	d0,$14(a0)
		move.b	direc(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.b	locret_130E8
		cmpi.w	#$400,d0
		blt.b	locret_130E8
		move.b	#$D,$1C(a0)	; use "stopping" animation
		bclr	#0,cddat(a0)
		move.w	#$A4,d0
		jsr	(soundset).l ;	play stopping sound

locret_130E8:
		rts	
; End of function plwalk_l


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


plwalk_r:			; XREF: levermove
		move.w	$14(a0),d0
		bmi.b	loc_13118
		bclr	#0,cddat(a0)
		beq.b	loc_13104
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)

loc_13104:
		add.w	d5,d0
		cmp.w	d6,d0
		blt.b	loc_1310C
		move.w	d6,d0

loc_1310C:
		move.w	d0,$14(a0)
		move.b	#0,$1C(a0)	; use walking animation
		rts	
; ===========================================================================

loc_13118:				; XREF: plwalk_r
		add.w	d4,d0
		bcc.b	loc_13120
		move.w	#$80,d0

loc_13120:
		move.w	d0,$14(a0)
		move.b	direc(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.b	locret_1314E
		cmpi.w	#-$400,d0
		bgt.b	locret_1314E
		move.b	#$D,$1C(a0)	; use "stopping" animation
		bset	#0,cddat(a0)
		move.w	#$A4,d0
		jsr	(soundset).l ;	play stopping sound

locret_1314E:
		rts	
; End of function plwalk_r

balllmove:
		move.w	plmaxspdwk,d6
		asl.w	#1,d6
		move.w	pladdspdwk,d5
		asr.w	#1,d5
		move.w	plretspdwk,d4
		asr.w	#2,d4
		tst.b	mizuflag
		bne.w	loc_131CC
		tst.w	$3E(a0)
		bne.b	loc_13188
		btst	#2,swdata+0
		beq.b	loc_1317C
		bsr.w	ballwalk_l

loc_1317C:
		btst	#3,swdata+0
		beq.b	loc_13188
		bsr.w	ballwalk_r

loc_13188:
		move.w	$14(a0),d0
		beq.b	loc_131AA
		bmi.b	loc_1319E
		sub.w	d5,d0
		bcc.b	loc_13198
		move.w	#0,d0

loc_13198:
		move.w	d0,$14(a0)
		bra.b	loc_131AA
; ===========================================================================

loc_1319E:				; XREF: balllmove
		add.w	d5,d0
		bcc.b	loc_131A6
		move.w	#0,d0

loc_131A6:
		move.w	d0,$14(a0)

loc_131AA:
		tst.w	$14(a0)		; is Sonic moving?
		bne.b	loc_131CC	; if yes, branch
		bclr	#2,cddat(a0)
		move.b	#$13,$16(a0)
		move.b	#9,$17(a0)
		move.b	#5,$1C(a0)	; use "standing" animation
		subq.w	#5,$C(a0)

loc_131CC:
		move.b	direc(a0),d0
		jsr	(sinset).l
		muls.w	$14(a0),d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		muls.w	$14(a0),d1
		asr.l	#8,d1
		cmpi.w	#$1000,d1
		ble.b	loc_131F0
		move.w	#$1000,d1

loc_131F0:
		cmpi.w	#-$1000,d1
		bge.b	loc_131FA
		move.w	#-$1000,d1

loc_131FA:
		move.w	d1,$10(a0)
		bra.w	loc_1300C
; End of function balllmove


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ballwalk_l:				; XREF: balllmove
		move.w	$14(a0),d0
		beq.b	loc_1320A
		bpl.b	loc_13218

loc_1320A:
		bset	#0,cddat(a0)
		move.b	#2,$1C(a0)	; use "rolling"	animation
		rts	
; ===========================================================================

loc_13218:
		sub.w	d4,d0
		bcc.b	loc_13220
		move.w	#-$80,d0

loc_13220:
		move.w	d0,$14(a0)
		rts	
; End of function ballwalk_l


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ballwalk_r:			; XREF: balllmove
		move.w	$14(a0),d0
		bmi.b	loc_1323A
		bclr	#0,cddat(a0)
		move.b	#2,mstno(a0)
		rts	
; ===========================================================================

loc_1323A:
		add.w	d4,d0
		bcc.b	loc_13242
		move.w	#$80,d0

loc_13242:
		move.w	d0,mspeed(a0)
		rts	

jumpmove:			; XREF: play00jump; ball00jump
		move.w	plmaxspdwk,d6
		move.w	pladdspdwk,d5
		asl.w	#1,d5
		btst	#4,cddat(a0)
		bne.b	play00_ResetScr2
		move.w	$10(a0),d0
		btst	#2,swdata+0 ; is left being pressed?
		beq.b	loc_13278	; if not, branch
		bset	#0,cddat(a0)
		sub.w	d5,d0
		move.w	d6,d1
		neg.w	d1
		cmp.w	d1,d0
		bgt.b	loc_13278
		move.w	d1,d0

loc_13278:
		btst	#3,swdata+0 ; is right being pressed?
		beq.b	play00_JumpMove	; if not, branch
		bclr	#0,cddat(a0)
		add.w	d5,d0
		cmp.w	d6,d0
		blt.b	play00_JumpMove
		move.w	d6,d0

play00_JumpMove:
		move.w	d0,$10(a0)	; change Sonic's horizontal speed

play00_ResetScr2:
		cmpi.w	#$60,($FFFFF73E).w ; is	the screen in its default position?
		beq.b	loc_132A4	; if yes, branch
		bcc.b	loc_132A0
		addq.w	#4,($FFFFF73E).w

loc_132A0:
		subq.w	#2,($FFFFF73E).w

loc_132A4:
		cmpi.w	#-$400,$12(a0)	; is Sonic moving faster than -$400 upwards?
		bcs.b	locret_132D2	; if yes, branch
		move.w	$10(a0),d0
		move.w	d0,d1
		asr.w	#5,d1
		beq.b	locret_132D2
		bmi.b	loc_132C6
		sub.w	d1,d0
		bcc.b	loc_132C0
		move.w	#0,d0

loc_132C0:
		move.w	d0,$10(a0)
		rts	
; ===========================================================================

loc_132C6:
		sub.w	d1,d0
		bcs.b	loc_132CE
		move.w	#0,d0

loc_132CE:
		move.w	d0,$10(a0)

locret_132D2:
		rts	
; End of function jumpmove

; ===========================================================================
; ---------------------------------------------------------------------------
; Unused subroutine to squash Sonic
; ---------------------------------------------------------------------------
		move.b	direc(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		bne.b	locret_13302
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.b	locret_13302
		move.w	#0,$14(a0)	; stop Sonic moving
		move.w	#0,$10(a0)
		move.w	#0,$12(a0)
		move.b	#$B,$1C(a0)	; use "warping"	animation

locret_13302:
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	prevent	Sonic leaving the boundaries of	a level
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


limitchk:			; XREF: play00walk; et al
		move.l	8(a0),d1
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d1
		swap	d1
		move.w	scralim_left,d0
		addi.w	#$10,d0
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bhi.b	Boundary_Sides	; if yes, branch
		move.w	scralim_right,d0
		addi.w	#$128,d0
		tst.b	($FFFFF7AA).w
		bne.b	loc_13332
		addi.w	#$40,d0

loc_13332:
		cmp.w	d1,d0		; has Sonic touched the	side boundary?
		bls.b	Boundary_Sides	; if yes, branch

loc_13336:
		move.w	scralim_down,d0
		addi.w	#$E0,d0
		cmp.w	$C(a0),d0	; has Sonic touched the	bottom boundary?
		blt.b	Boundary_Bottom	; if yes, branch
		rts	
; ===========================================================================

Boundary_Bottom:
		cmpi.w	#$501,stageno ; is level SBZ2 ?
		bne.w	playdieset	; if not, kill Sonic
		cmpi.w	#$2000,playerwk+xposi
		bcs.w	playdieset
		clr.b	saveno	; clear	lamppost counter
		move.w	#1,gameflag ; restart the level
		move.w	#$103,stageno ; set level	to SBZ3	(LZ4)
		rts	
; ===========================================================================

Boundary_Sides:
		move.w	d0,8(a0)
		move.w	#0,$A(a0)
		move.w	#0,$10(a0)	; stop Sonic moving
		move.w	#0,$14(a0)
		bra.b	loc_13336
; End of function limitchk

ballchk:
		tst.b	mizuflag
		bne.b	?jump1
		move.w	mspeed(a0),d0
		bpl.b	?jump
		neg.w	d0
?jump:
		cmpi.w	#$80,d0
		bcs.b	?jump1
		move.b	swdata+0,d0
		andi.b	#$C,d0
		bne.b	?jump1
		btst.b	#1,swdata+0
		bne.b	ballset
?jump1:
		rts	

ballset:
		btst.b	#cd_ball,cddat(a0)
		beq.b	?jump
		rts
?jump:
		bset.b	#cd_ball,cddat(a0)
		move.b	#14,sprvsize(a0)
		move.b	#7,sprhsize(a0)
		move.b	#2,mstno(a0)
		addq.w	#5,yposi(a0)
		move.w	#$BE,d0
		jsr		soundset
		tst.w	mspeed(a0)
		bne.b	?jump2
		move.w	#$0200,mspeed(a0)
?jump2:
		rts

jumpchk:
		move.b	swdata+1,d0
		andi.b	#$70,d0
		beq.w	locret_1348E
		moveq	#0,d0
		move.b	direc(a0),d0
		addi.b	#$80,d0
		bsr.w	sub_14D48
		cmpi.w	#6,d1
		blt.w	locret_1348E
		move.w	#$0680,d2
		btst.b	#cd_water,cddat(a0)
		beq.b	loc_1341C
		move.w	#$0380,d2
loc_1341C:
		moveq	#0,d0
		move.b	direc(a0),d0
		subi.b	#$40,d0
		jsr		sinset
		muls.w	d2,d1
		asr.l	#8,d1
		add.w	d1,xpeed(a0)
		muls.w	d2,d0
		asr.l	#8,d0
		add.w	d0,yspeed(a0)
		bset	#cd_jump,cddat(a0)
		bclr	#cd_push,cddat(a0)
		addq.l	#4,sp
		move.b	#1,actfree+16(a0)
		clr.b	$38(a0)
		move.w	#$A0,d0
		jsr		soundset
		move.b	#$13,sprvsize(a0)
		move.b	#9,sprhsize(a0)
		btst	#2,cddat(a0)
		bne.b	loc_13490
		move.b	#$E,sprvsize(a0)
		move.b	#7,sprhsize(a0)
		move.b	#2,mstno(a0)
		bset	#cd_ball,cddat(a0)
		addq.w	#5,yposi(a0)

locret_1348E:
		rts	
; ===========================================================================

loc_13490:
		bset	#4,cddat(a0)
		rts	
; End of function jumpchk


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


jumpchk2:			; XREF: play00jump; ball00jump
		tst.b	$3C(a0)
		beq.b	loc_134C4
		move.w	#-$400,d1
		btst	#6,cddat(a0)
		beq.b	loc_134AE
		move.w	#-$200,d1

loc_134AE:
		cmp.w	$12(a0),d1
		ble.b	locret_134C2
		move.b	swdata+0,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		bne.b	locret_134C2	; if yes, branch
		move.w	d1,$12(a0)

locret_134C2:
		rts	
; ===========================================================================

loc_134C4:
		cmpi.w	#-$FC0,$12(a0)
		bge.b	locret_134D2
		move.w	#-$FC0,$12(a0)

locret_134D2:
		rts	
; End of function jumpchk2

; ---------------------------------------------------------------------------
; Subroutine to	slow Sonic walking up a	slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


keispd:			; XREF: play00walk
		move.b	direc(a0),d0
		addi.b	#$60,d0
		cmpi.b	#$C0,d0
		bcc.b	locret_13508
		move.b	direc(a0),d0
		jsr	(sinset).l
		muls.w	#$20,d0
		asr.l	#8,d0
		tst.w	$14(a0)
		beq.b	locret_13508
		bmi.b	loc_13504
		tst.w	d0
		beq.b	locret_13502
		add.w	d0,$14(a0)	; change Sonic's inertia

locret_13502:
		rts	
; ===========================================================================

loc_13504:
		add.w	d0,$14(a0)

locret_13508:
		rts	
; End of function keispd

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope	while he's rolling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


keispd2:			; XREF: ball00walk
		move.b	direc(a0),d0
		addi.b	#$60,d0
		cmpi.b	#-$40,d0
		bcc.b	locret_13544
		move.b	direc(a0),d0
		jsr	(sinset).l
		muls.w	#$50,d0
		asr.l	#8,d0
		tst.w	$14(a0)
		bmi.b	loc_1353A
		tst.w	d0
		bpl.b	loc_13534
		asr.l	#2,d0

loc_13534:
		add.w	d0,$14(a0)
		rts	
; ===========================================================================

loc_1353A:
		tst.w	d0
		bmi.b	loc_13540
		asr.l	#2,d0

loc_13540:
		add.w	d0,$14(a0)

locret_13544:
		rts	
; End of function keispd2

; ---------------------------------------------------------------------------
; Subroutine to	push Sonic down	a slope
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


fallchk:			; XREF: play00walk; ball00walk
		nop	
		tst.b	$38(a0)
		bne.b	locret_13580
		tst.w	$3E(a0)
		bne.b	loc_13582
		move.b	direc(a0),d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		beq.b	locret_13580
		move.w	$14(a0),d0
		bpl.b	loc_1356A
		neg.w	d0

loc_1356A:
		cmpi.w	#$280,d0
		bcc.b	locret_13580
		clr.w	$14(a0)
		bset	#1,cddat(a0)
		move.w	#$1E,$3E(a0)

locret_13580:
		rts	
; ===========================================================================

loc_13582:
		subq.w	#1,$3E(a0)
		rts	
; End of function fallchk

; ---------------------------------------------------------------------------
; Subroutine to	return Sonic's angle to 0 as he jumps
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


direcchg:			; XREF: play00jump; ball00jump
		move.b	direc(a0),d0	; get Sonic's angle
		beq.b	locret_135A2	; if already 0,	branch
		bpl.b	loc_13598	; if higher than 0, branch

		addq.b	#2,d0		; increase angle
		bcc.b	loc_13596
		moveq	#0,d0

loc_13596:
		bra.b	loc_1359E
; ===========================================================================

loc_13598:
		subq.b	#2,d0		; decrease angle
		bcc.b	loc_1359E
		moveq	#0,d0

loc_1359E:
		move.b	d0,direc(a0)

locret_135A2:
		rts	
; End of function direcchg

; ---------------------------------------------------------------------------
; Subroutine for Sonic to interact with	the floor after	jumping/falling
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


jumpcolchk:				; XREF: play00jump; ball00jump
		move.w	xspeed(a0),d1
		move.w	yspeed(a0),d2
		jsr		atan
		move.b	d0,debugwork
		subi.b	#$20,d0
		move.b	d0,debugwork+1
		andi.b	#$C0,d0
		move.b	d0,debugwork+2
		cmpi.b	#$40,d0
		beq.w	loc_13680
		cmpi.b	#$80,d0
		beq.w	loc_136E2
		cmpi.b	#-$40,d0
		beq.w	loc_1373E
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.b	loc_135F0
		sub.w	d1,xposi(a0)
		move.w	#0,xspeed(a0)

loc_135F0:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.b	loc_13602
		add.w	d1,xposi(a0)
		move.w	#0,xspeed(a0)

loc_13602:
		bsr.w	Sonic_HitFloor
		move.b	d1,debugwork+3
		tst.w	d1
		bpl.b	locret_1367E
		move.b	yspeed(a0),d2
		addq.b	#8,d2
		neg.b	d2
		cmp.b	d2,d1
		bge.b	loc_1361E
		cmp.b	d2,d0
		blt.b	locret_1367E

loc_1361E:
		add.w	d1,yposi(a0)
		move.b	d3,direc(a0)
		bsr.w	jumpcolsub
		move.b	#0,mstno(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.b	loc_1365C
		move.b	d3,d0
		addi.b	#$10,d0
		andi.b	#$20,d0
		beq.b	loc_1364E
		asr		yspeed(a0)
		bra.b	loc_13670

loc_1364E:
		move.w	#0,yspeed(a0)
		move.w	xspeed(a0),mspeed(a0)
		rts	
; ===========================================================================

loc_1365C:
		move.w	#0,xspeed(a0)
		cmpi.w	#$FC0,yspeed(a0)
		ble.b	loc_13670
		move.w	#$FC0,yspeed(a0)

loc_13670:
		move.w	yspeed(a0),mspeed(a0)
		tst.b	d3
		bpl.b	locret_1367E
		neg.w	mspeed(a0)

locret_1367E:
		rts	
; ===========================================================================

loc_13680:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.b	loc_1369A
		sub.w	d1,xposi(a0)
		move.w	#0,xspeed(a0)
		move.w	yspeed(a0),mspeed(a0)
		rts	
; ===========================================================================

loc_1369A:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.b	loc_136B4
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.b	locret_136B2
		move.w	#0,$12(a0)

locret_136B2:
		rts	
; ===========================================================================

loc_136B4:
		tst.w	$12(a0)
		bmi.b	locret_136E0
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.b	locret_136E0
		add.w	d1,$C(a0)
		move.b	d3,direc(a0)
		bsr.w	jumpcolsub
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)

locret_136E0:
		rts	
; ===========================================================================

loc_136E2:
		bsr.w	Sonic_HitWall
		tst.w	d1
		bpl.b	loc_136F4
		sub.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_136F4:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.b	loc_13706
		add.w	d1,8(a0)
		move.w	#0,$10(a0)

loc_13706:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.b	locret_1373C
		sub.w	d1,$C(a0)
		move.b	d3,d0
		addi.b	#$20,d0
		andi.b	#$40,d0
		bne.b	loc_13726
		move.w	#0,$12(a0)
		rts	
; ===========================================================================

loc_13726:
		move.b	d3,direc(a0)
		bsr.w	jumpcolsub
		move.w	$12(a0),$14(a0)
		tst.b	d3
		bpl.b	locret_1373C
		neg.w	$14(a0)

locret_1373C:
		rts	
; ===========================================================================

loc_1373E:
		bsr.w	sub_14EB4
		tst.w	d1
		bpl.b	loc_13758
		add.w	d1,8(a0)
		move.w	#0,$10(a0)
		move.w	$12(a0),$14(a0)
		rts	
; ===========================================================================

loc_13758:
		bsr.w	Sonic_DontRunOnWalls
		tst.w	d1
		bpl.b	loc_13772
		sub.w	d1,$C(a0)
		tst.w	$12(a0)
		bpl.b	locret_13770
		move.w	#0,$12(a0)
locret_13770:
		rts	

loc_13772:
		tst.w	$12(a0)
		bmi.b	locret_1379E
		bsr.w	Sonic_HitFloor
		tst.w	d1
		bpl.b	locret_1379E
		add.w	d1,$C(a0)
		move.b	d3,direc(a0)
		bsr.w	jumpcolsub
		move.b	#0,$1C(a0)
		move.w	#0,$12(a0)
		move.w	$10(a0),$14(a0)
locret_1379E:
		rts

jumpcolsub:
		btst.b	#4,cddat(a0)
		beq.b	?jump0
		nop	
		nop	
		nop	

?jump0:
		bclr.b	#cd_push,cddat(a0)
		bclr.b	#cd_jump,cddat(a0)
		bclr.b	#4,cddat(a0)
		btst.b	#cd_ball,cddat(a0)
		beq.b	?jump1
		bclr.b	#cd_ball,cddat(a0)
		move.b	#19,sprvsize(a0)
		move.b	#9,sprhsize(a0)
		move.b	#0,mstno(a0)
		subq.w	#5,yposi(a0)
?jump1:
		move.b	#0,$3C(a0)
		move.w	#0,emyscorecnt
		rts

play00damage:
		jsr	speedset2
		addi.w	#48,yspeed(a0)
		btst	#cd_water,cddat(a0)
		beq.b	?jump
		subi.w	#32,yspeed(a0)

?jump:
		bsr.w	play00damage_sub
		bsr.w	limitchk
		bsr.w	playposiwkset
		bsr.w	spatset
		bsr.w	Loadplaywrtpat
		jmp		actionsub

play00damage_sub:
		move.w	scralim_down,d0
		addi.w	#224,d0
		cmp.w	yposi(a0),d0
		bcs.w	playdieset
		bsr.w	jumpcolchk
		btst.b	#cd_jump,cddat(a0)
		bne.b	?end
		moveq	#0,d0
		move.w	d0,yspeed(a0)
		move.w	d0,xspeed(a0)
		move.w	d0,mspeed(a0)
		move.b	#0,mstno(a0)
		subq.b	#word,r_no0(a0)
		move.w	#$78,$30(a0)

?end:
		rts	
; End of function play00damage_sub

; ===========================================================================
; ---------------------------------------------------------------------------
; Sonic	when he	dies
; ---------------------------------------------------------------------------

play00die:				; XREF: play00_move_tbl
		bsr.w	GameOver
		jsr	speedset
		bsr.w	playposiwkset
		bsr.w	spatset
		bsr.w	Loadplaywrtpat
		jmp	actionsub

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


GameOver:				; XREF: play00die
		move.w	scralim_down,d0
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bcc.w	locret_13900
		move.w	#-$38,$12(a0)
		addq.b	#2,r_no0(a0)
		clr.b	pltime_f	; stop time counter
		addq.b	#1,pl_suu_f ; update lives	counter
		subq.b	#1,pl_suu ; subtract 1 from number of lives
		bne.b	loc_138D4
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load GAME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#1,($FFFFD0DA).w ; set OVER object to correct frame
		clr.b	pltimeover_f

loc_138C2:
		move.w	#$8F,d0
		jsr	(bgmset).l	; play game over music
		moveq	#3,d0
		jmp	(LoadPLC).l	; load game over patterns
; ===========================================================================

loc_138D4:
		move.w	#60,$3A(a0)	; set time delay to 1 second
		tst.b	pltimeover_f	; is TIME OVER tag set?
		beq.b	locret_13900	; if not, branch
		move.w	#0,$3A(a0)
		move.b	#$39,($FFFFD080).w ; load TIME object
		move.b	#$39,($FFFFD0C0).w ; load OVER object
		move.b	#2,($FFFFD09A).w
		move.b	#3,($FFFFD0DA).w
		bra.b	loc_138C2
; ===========================================================================

locret_13900:
		rts	
; End of function GameOver

; ===========================================================================

play00erase:
		tst.w	actfree+14(a0)
		beq.b	?jump
		subq.w	#1,actfree+14(a0)
		bne.b	?jump
		move.w	#1,gameflag

?jump:
		rts	

loopchk:
		cmpi.b	#3,stageno
		beq.b	?jump0
		tst.b	stageno
		bne.w	locret_139C2

?jump0:
		move.w	$C(a0),d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.b	8(a0),d1
		andi.w	#$7F,d1
		add.w	d1,d0
		lea	mapwka,a1
		move.b	(a1,d0.w),d1
		cmp.b	($FFFFF7AE).w,d1
		beq.w	ballset
		cmp.b	($FFFFF7AF).w,d1
		beq.w	ballset
		cmp.b	($FFFFF7AC).w,d1
		beq.b	loc_13976
		cmp.b	($FFFFF7AD).w,d1
		beq.b	loc_13966
		bclr	#6,1(a0)
		rts	

loc_13966:
		btst	#1,cddat(a0)
		beq.b	loc_13976
		bclr	#6,1(a0)
		rts
loc_13976:
		move.w	8(a0),d2
		cmpi.b	#$2C,d2
		bcc.b	loc_13988
		bclr	#6,1(a0)
		rts	
loc_13988:
		cmpi.b	#-$20,d2
		bcs.b	loc_13996
		bset	#6,1(a0)
		rts	
loc_13996:
		btst	#6,1(a0)
		bne.b	loc_139B2
		move.b	direc(a0),d1
		beq.b	locret_139C2
		cmpi.b	#-$80,d1
		bhi.b	locret_139C2
		bset	#6,1(a0)
		rts	
loc_139B2:
		move.b	direc(a0),d1
		cmpi.b	#-$80,d1
		bls.b	locret_139C2
		bclr	#6,1(a0)
locret_139C2:
		rts

; ---------------------------------------------------------------------------
; Subroutine to	animate	Sonic's sprites
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


spatset:				; XREF: play00move; et al
		lea	(SonicAniData).l,a1
		moveq	#0,d0
		move.b	$1C(a0),d0
		cmp.b	$1D(a0),d0	; is animation set to restart?
		beq.b	SAnim_Do	; if not, branch
		move.b	d0,$1D(a0)	; set to "no restart"
		move.b	#0,$1B(a0)	; reset	animation
		move.b	#0,$1E(a0)	; reset	frame duration

SAnim_Do:
		add.w	d0,d0
		adda.w	(a1,d0.w),a1	; jump to appropriate animation	script
		move.b	(a1),d0
		bmi.b	SAnim_WalkRun	; if animation is walk/run/roll/jump, branch
		move.b	cddat(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	SAnim_Delay	; if time remains, branch
		move.b	d0,$1E(a0)	; load frame duration

SAnim_Do2:
		moveq	#0,d1
		move.b	$1B(a0),d1	; load current frame number
		move.b	1(a1,d1.w),d0	; read sprite number from script
		bmi.b	SAnim_End_FF	; if animation is complete, branch

SAnim_Next:
		move.b	d0,$1A(a0)	; load sprite number
		addq.b	#1,$1B(a0)	; next frame number

SAnim_Delay:
		rts	
; ===========================================================================

SAnim_End_FF:
		addq.b	#1,d0		; is the end flag = $FF	?
		bne.b	SAnim_End_FE	; if not, branch
		move.b	#0,$1B(a0)	; restart the animation
		move.b	1(a1),d0	; read sprite number
		bra.b	SAnim_Next
; ===========================================================================

SAnim_End_FE:
		addq.b	#1,d0		; is the end flag = $FE	?
		bne.b	SAnim_End_FD	; if not, branch
		move.b	2(a1,d1.w),d0	; read the next	byte in	the script
		sub.b	d0,$1B(a0)	; jump back d0 bytes in	the script
		sub.b	d0,d1
		move.b	1(a1,d1.w),d0	; read sprite number
		bra.b	SAnim_Next
; ===========================================================================

SAnim_End_FD:
		addq.b	#1,d0		; is the end flag = $FD	?
		bne.b	SAnim_End	; if not, branch
		move.b	2(a1,d1.w),$1C(a0) ; read next byte, run that animation

SAnim_End:
		rts	
; ===========================================================================

SAnim_WalkRun:				; XREF: SAnim_Do
		subq.b	#1,$1E(a0)	; subtract 1 from frame	duration
		bpl.b	SAnim_Delay	; if time remains, branch
		addq.b	#1,d0		; is animation walking/running?
		bne.w	SAnim_RollJump	; if not, branch
		moveq	#0,d1
		move.b	direc(a0),d0	; get Sonic's angle
		move.b	cddat(a0),d2
		andi.b	#1,d2		; is Sonic mirrored horizontally?
		bne.b	loc_13A70	; if yes, branch
		not.b	d0		; reverse angle

loc_13A70:
		addi.b	#$10,d0		; add $10 to angle
		bpl.b	loc_13A78	; if angle is $0-$7F, branch
		moveq	#3,d1

loc_13A78:
		andi.b	#$FC,1(a0)
		eor.b	d1,d2
		or.b	d2,1(a0)
		btst	#5,cddat(a0)
		bne.w	SAnim_Push
		lsr.b	#4,d0		; divide angle by $10
		andi.b	#6,d0		; angle	must be	0, 2, 4	or 6
		move.w	$14(a0),d2	; get Sonic's speed
		bpl.b	loc_13A9C
		neg.w	d2

loc_13A9C:
		lea	(SonAni_Run).l,a1 ; use	running	animation
		cmpi.w	#$600,d2	; is Sonic at running speed?
		bcc.b	loc_13AB4	; if yes, branch
		lea	(SonAni_Walk).l,a1 ; use walking animation
		move.b	d0,d1
		lsr.b	#1,d1
		add.b	d1,d0

loc_13AB4:
		add.b	d0,d0
		move.b	d0,d3
		neg.w	d2
		addi.w	#$800,d2
		bpl.b	loc_13AC2
		moveq	#0,d2

loc_13AC2:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		bsr.w	SAnim_Do2
		add.b	d3,$1A(a0)	; modify frame number
		rts	
; ===========================================================================

SAnim_RollJump:				; XREF: SAnim_WalkRun
		addq.b	#1,d0		; is animation rolling/jumping?
		bne.b	SAnim_Push	; if not, branch
		move.w	$14(a0),d2	; get Sonic's speed
		bpl.b	loc_13ADE
		neg.w	d2

loc_13ADE:
		lea	(SonAni_Roll2).l,a1 ; use fast animation
		cmpi.w	#$600,d2	; is Sonic moving fast?
		bcc.b	loc_13AF0	; if yes, branch
		lea	(SonAni_Roll).l,a1 ; use slower	animation

loc_13AF0:
		neg.w	d2
		addi.w	#$400,d2
		bpl.b	loc_13AFA
		moveq	#0,d2

loc_13AFA:
		lsr.w	#8,d2
		move.b	d2,$1E(a0)	; modify frame duration
		move.b	cddat(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; ===========================================================================

SAnim_Push:				; XREF: SAnim_RollJump
		move.w	$14(a0),d2	; get Sonic's speed
		bmi.b	loc_13B1E
		neg.w	d2

loc_13B1E:
		addi.w	#$800,d2
		bpl.b	loc_13B26
		moveq	#0,d2

loc_13B26:
		lsr.w	#6,d2
		move.b	d2,$1E(a0)	; modify frame duration
		lea	(SonAni_Push).l,a1
		move.b	cddat(a0),d1
		andi.b	#1,d1
		andi.b	#$FC,1(a0)
		or.b	d1,1(a0)
		bra.w	SAnim_Do2
; End of function spatset

; ===========================================================================
SonicAniData:
	include "_anim\Sonic.asm"

; ---------------------------------------------------------------------------
; Sonic	pattern	loading	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Loadplaywrtpat:			; XREF: play00move; et al
		moveq	#0,d0
		move.b	$1A(a0),d0	; load frame number
		cmp.b	($FFFFF766).w,d0
		beq.b	locret_13C96
		move.b	d0,($FFFFF766).w
		lea	(playwrtpat).l,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1	; read "number of entries" value
		subq.b	#1,d1
		bmi.b	locret_13C96
		lea	($FFFFC800).w,a3
		move.b	#1,($FFFFF767).w

SPLC_ReadEntry:
		moveq	#0,d2
		move.b	(a2)+,d2
		move.w	d2,d0
		lsr.b	#4,d0
		lsl.w	#8,d2
		move.b	(a2)+,d2
		lsl.w	#5,d2
		lea	(playcg).l,a1
		adda.l	d2,a1

SPLC_LoadTile:
		movem.l	(a1)+,d2-d6/a4-a6
		movem.l	d2-d6/a4-a6,(a3)
		lea	$20(a3),a3	; next tile
		dbra	d0,SPLC_LoadTile ; repeat for number of	tiles

		dbra	d1,SPLC_ReadEntry ; repeat for number of entries

locret_13C96:
		rts	
; End of function Loadplaywrtpat

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 0A - drowning countdown numbers and small bubbles (LZ)
; ---------------------------------------------------------------------------

plawa:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	plawa_Index(pc,d0.w),d1
		jmp	plawa_Index(pc,d1.w)
; ===========================================================================
plawa_Index:	dc.w plawa_Main-plawa_Index, plawa_Animate-plawa_Index
		dc.w plawa_ChkWater-plawa_Index, plawa_Display-plawa_Index
		dc.w plawa_Delete2-plawa_Index,	plawa_Countdown-plawa_Index
		dc.w plawa_AirLeft-plawa_Index,	plawa_Display-plawa_Index
		dc.w plawa_Delete2-plawa_Index
; ===========================================================================

plawa_Main:				; XREF: plawa_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_awa,4(a0)
		move.w	#$8348,2(a0)
		move.b	#$84,1(a0)
		move.b	#$10,$19(a0)
		move.b	#1,$18(a0)
		move.b	userflag(a0),d0
		bpl.b	loc_13D00
		addq.b	#8,r_no0(a0)
		move.l	#Map_plawa,4(a0)
		move.w	#$440,2(a0)
		andi.w	#$7F,d0
		move.b	d0,$33(a0)
		bra.w	plawa_Countdown
; ===========================================================================

loc_13D00:
		move.b	d0,$1C(a0)
		move.w	8(a0),$30(a0)
		move.w	#-$88,$12(a0)

plawa_Animate:				; XREF: plawa_Index
		lea	(Ani_plawa).l,a1
		jsr	patchg

plawa_ChkWater:				; XREF: plawa_Index
		move.w	waterposi,d0
		cmp.w	$C(a0),d0	; has bubble reached the water surface?
		bcs.b	plawa_Wobble	; if not, branch
		move.b	#6,r_no0(a0)
		addq.b	#7,$1C(a0)
		cmpi.b	#$D,$1C(a0)
		beq.b	plawa_Display
		bra.b	plawa_Display
; ===========================================================================

plawa_Wobble:
		tst.b	watercoliflag
		beq.b	loc_13D44
		addq.w	#4,$30(a0)

loc_13D44:
		move.b	direc(a0),d0
		addq.b	#1,direc(a0)
		andi.w	#$7F,d0
		lea	(plawa_WobbleData).l,a1
		move.b	(a1,d0.w),d0
		ext.w	d0
		add.w	$30(a0),d0
		move.w	d0,8(a0)
		bsr.b	plawa_ShowNumber
		jsr	speedset2
		tst.b	1(a0)
		bpl.b	plawa_Delete
		jmp	actionsub
; ===========================================================================

plawa_Delete:
		jmp	frameout
; ===========================================================================

plawa_Display:				; XREF: plawa_Index
		bsr.b	plawa_ShowNumber
		lea	(Ani_plawa).l,a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================

plawa_Delete2:				; XREF: plawa_Index
		jmp	frameout
; ===========================================================================

plawa_AirLeft:				; XREF: plawa_Index
		cmpi.w	#$C,pl_air ; check air remaining
		bhi.b	plawa_Delete3	; if higher than $C, branch
		subq.w	#1,$38(a0)
		bne.b	plawa_Display2
		move.b	#$E,r_no0(a0)
		addq.b	#7,$1C(a0)
		bra.b	plawa_Display
; ===========================================================================

plawa_Display2:
		lea	(Ani_plawa).l,a1
		jsr	patchg
		tst.b	1(a0)
		bpl.b	plawa_Delete3
		jmp	actionsub
; ===========================================================================

plawa_Delete3:
		jmp	frameout
; ===========================================================================

plawa_ShowNumber:			; XREF: plawa_Wobble; plawa_Display
		tst.w	$38(a0)
		beq.b	locret_13E1A
		subq.w	#1,$38(a0)
		bne.b	locret_13E1A
		cmpi.b	#7,$1C(a0)
		bcc.b	locret_13E1A
		move.w	#$F,$38(a0)
		clr.w	$12(a0)
		move.b	#$80,1(a0)
		move.w	8(a0),d0
		sub.w	scra_h_posit,d0
		addi.w	#$80,d0
		move.w	d0,8(a0)
		move.w	$C(a0),d0
		sub.w	scra_v_posit,d0
		addi.w	#$80,d0
		move.w	d0,$A(a0)
		move.b	#$C,r_no0(a0)

locret_13E1A:
		rts	
; ===========================================================================
plawa_WobbleData:
		dc.b 0, 0, 0, 0, 0, 0,	1, 1, 1, 1, 1, 2, 2, 2,	2, 2, 2
		dc.b 2,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 3, 3, 4, 3
		dc.b 3,	3, 3, 3, 3, 3, 3, 3, 3,	3, 3, 3, 3, 2, 2, 2, 2
		dc.b 2,	2, 2, 1, 1, 1, 1, 1, 0,	0, 0, 0, 0, 0, -1, -1
		dc.b -1, -1, -1, -2, -2, -2, -2, -2, -3, -3, -3, -3, -3
		dc.b -3, -3, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4, -4
		dc.b -4, -4, -4, -4, -4, -3, -3, -3, -3, -3, -3, -3, -2
		dc.b -2, -2, -2, -2, -1, -1, -1, -1, -1
; ===========================================================================

plawa_Countdown:			; XREF: plawa_Index
		tst.w	actfree(a0)
		bne.w	loc_13F86
		cmpi.b	#6,($FFFFD024).w
		bcc.w	locret_1408C
		btst	#6,playerwk+cddat
		beq.w	locret_1408C
		subq.w	#1,$38(a0)
		bpl.w	loc_13FAC
		move.w	#59,$38(a0)
		move.w	#1,$36(a0)
		jsr	(random).l
		andi.w	#1,d0
		move.b	d0,$34(a0)
		move.w	pl_air,d0 ; check air remaining
		cmpi.w	#$19,d0
		beq.b	plawa_WarnSound	; play sound if	air is $19
		cmpi.w	#$14,d0
		beq.b	plawa_WarnSound
		cmpi.w	#$F,d0
		beq.b	plawa_WarnSound
		cmpi.w	#$C,d0
		bhi.b	plawa_ReduceAir	; if air is above $C, branch
		bne.b	loc_13F02
		move.w	#$92,d0
		jsr	(bgmset).l	; play countdown music

loc_13F02:
		subq.b	#1,$32(a0)
		bpl.b	plawa_ReduceAir
		move.b	$33(a0),$32(a0)
		bset	#7,$36(a0)
		bra.b	plawa_ReduceAir
; ===========================================================================

plawa_WarnSound:			; XREF: plawa_Countdown
		move.w	#$C2,d0
		jsr	(soundset).l ;	play "ding-ding" warning sound

plawa_ReduceAir:
		subq.w	#1,pl_air ; subtract 1 from air remaining
		bcc.w	plawa_GoMakeItem ; if air is above 0, branch
		bsr.w	plairset
		move.b	#$81,($FFFFF7C8).w ; lock controls
		move.w	#$B2,d0
		jsr	(soundset).l ;	play drowning sound
		move.b	#$A,$34(a0)
		move.w	#1,$36(a0)
		move.w	#$78,actfree(a0)
		move.l	a0,-(sp)
		lea	playerwk,a0
		bsr.w	jumpcolsub
		move.b	#$17,$1C(a0)	; use Sonic's drowning animation
		bset	#1,cddat(a0)
		bset	#7,2(a0)
		move.w	#0,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.b	#1,($FFFFF744).w
		movea.l	(sp)+,a0
		rts	
; ===========================================================================

loc_13F86:
		subq.w	#1,actfree(a0)
		bne.b	loc_13F94
		move.b	#6,($FFFFD024).w
		rts	
; ===========================================================================

loc_13F94:
		move.l	a0,-(sp)
		lea	playerwk,a0
		jsr	speedset2
		addi.w	#$10,$12(a0)
		movea.l	(sp)+,a0
		bra.b	loc_13FAC
; ===========================================================================

plawa_GoMakeItem:			; XREF: plawa_ReduceAir
		bra.b	plawa_MakeItem
; ===========================================================================

loc_13FAC:
		tst.w	$36(a0)
		beq.w	locret_1408C
		subq.w	#1,$3A(a0)
		bpl.w	locret_1408C

plawa_MakeItem:
		jsr	(random).l
		andi.w	#$F,d0
		move.w	d0,$3A(a0)
		jsr	actwkchk
		bne.w	locret_1408C
		move.b	#$A,0(a1)	; load object
		move.w	playerwk+xposi,8(a1) ; match X position to Sonic
		moveq	#6,d0
		btst	#0,playerwk+cddat
		beq.b	loc_13FF2
		neg.w	d0
		move.b	#$40,direc(a1)

loc_13FF2:
		add.w	d0,8(a1)
		move.w	playerwk+yposi,$C(a1)
		move.b	#6,userflag(a1)
		tst.w	actfree(a0)
		beq.w	loc_1403E
		andi.w	#7,$3A(a0)
		addi.w	#0,$3A(a0)
		move.w	playerwk+yposi,d0
		subi.w	#$C,d0
		move.w	d0,$C(a1)
		jsr	(random).l
		move.b	d0,direc(a1)
		move.w	gametimer,d0
		andi.b	#3,d0
		bne.b	loc_14082
		move.b	#$E,userflag(a1)
		bra.b	loc_14082

loc_1403E:
		btst	#7,$36(a0)
		beq.b	loc_14082
		move.w	pl_air,d2
		lsr.w	#1,d2
		jsr	(random).l
		andi.w	#3,d0
		bne.b	loc_1406A
		bset	#6,$36(a0)
		bne.b	loc_14082
		move.b	d2,userflag(a1)
		move.w	#$1C,$38(a1)

loc_1406A:
		tst.b	$34(a0)
		bne.b	loc_14082
		bset	#6,$36(a0)
		bne.b	loc_14082
		move.b	d2,userflag(a1)
		move.w	#$1C,$38(a1)

loc_14082:
		subq.b	#1,$34(a0)
		bpl.b	locret_1408C
		clr.w	$36(a0)

locret_1408C:
		rts	

plairset:
		cmpi.w	#12,pl_air
		bhi.b	?jump1
		move.w	#$82,d0
		cmpi.w	#$0103,stageno
		bne.b	?jump0
		move.w	#$86,d0

?jump0:
		jsr		bgmset

?jump1:
		move.w	#30,pl_air
		clr.b	($FFFFD372).w
		rts

; ===========================================================================
Ani_plawa:
	include "_anim\plawa.asm"

Map_plawa:
	include "_maps\plawa.asm"

effect:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	effect_Index(pc,d0.w),d1
		jmp	effect_Index(pc,d1.w)
; ===========================================================================
effect_Index:	dc.w effect_Main-effect_Index
		dc.w effect_Shield-effect_Index
		dc.w effect_Stars-effect_Index
; ===========================================================================

effect_Main:				; XREF: effect_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_effect,4(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$10,$19(a0)
		tst.b	$1C(a0)		; is object a shield?
		bne.b	effect_DoStars	; if not, branch
		move.w	#$541,2(a0)	; shield specific code
		rts	
; ===========================================================================

effect_DoStars:
		addq.b	#2,r_no0(a0)	; stars	specific code
		move.w	#$55C,2(a0)
		rts	
; ===========================================================================

effect_Shield:				; XREF: effect_Index
		tst.b	plpower_m	; does Sonic have invincibility?
		bne.b	effect_RmvShield	; if yes, branch
		tst.b	plpower_b	; does Sonic have shield?
		beq.b	effect_Delete	; if not, branch
		move.w	playerwk+xposi,8(a0)
		move.w	playerwk+yposi,$C(a0)
		move.b	playerwk+cddat,cddat(a0)
		lea	(Ani_effect).l,a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================

effect_RmvShield:
		rts	
; ===========================================================================

effect_Delete:
		jmp	frameout
; ===========================================================================

effect_Stars:				; XREF: effect_Index
		tst.b	plpower_m	; does Sonic have invincibility?
		beq.b	effect_Delete2	; if not, branch
		move.w	plposiwkadr,d0
		move.b	$1C(a0),d1
		subq.b	#1,d1
		bra.b	effect_StarTrail
; ===========================================================================
		lsl.b	#4,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		andi.b	#$F,d1
		move.b	d1,$30(a0)
		bra.b	effect_StarTrail2a
; ===========================================================================

effect_StarTrail:			; XREF: effect_Stars
		lsl.b	#3,d1
		move.b	d1,d2
		add.b	d1,d1
		add.b	d2,d1
		addq.b	#4,d1
		sub.b	d1,d0
		move.b	$30(a0),d1
		sub.b	d1,d0
		addq.b	#4,d1
		cmpi.b	#$18,d1
		bcs.b	effect_StarTrail2
		moveq	#0,d1

effect_StarTrail2:
		move.b	d1,$30(a0)

effect_StarTrail2a:
		lea	playposiwk,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,8(a0)
		move.w	(a1)+,$C(a0)
		move.b	playerwk+cddat,cddat(a0)
		lea	(Ani_effect).l,a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================

effect_Delete2:				; XREF: effect_Stars
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 4A - special stage entry from beta
; ---------------------------------------------------------------------------

Obj4A:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj4A_Index(pc,d0.w),d1
		jmp	Obj4A_Index(pc,d1.w)
; ===========================================================================
Obj4A_Index:	dc.w Obj4A_Main-Obj4A_Index
		dc.w Obj4A_RmvSonic-Obj4A_Index
		dc.w Obj4A_LoadSonic-Obj4A_Index
; ===========================================================================

Obj4A_Main:				; XREF: Obj4A_Index
		tst.l	($FFFFF680).w	; are pattern load cues	empty?
		beq.b	Obj4A_Main2	; if yes, branch
		rts	
; ===========================================================================

Obj4A_Main2:
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj4A,4(a0)
		move.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$38,$19(a0)
		move.w	#$541,2(a0)
		move.w	#120,$30(a0)	; set time for Sonic's disappearance to 2 seconds

Obj4A_RmvSonic:				; XREF: Obj4A_Index
		move.w	playerwk+xposi,8(a0)
		move.w	playerwk+yposi,$C(a0)
		move.b	playerwk+cddat,cddat(a0)
		lea	(Ani_obj4A).l,a1
		jsr	patchg
		cmpi.b	#2,$1A(a0)
		bne.b	Obj4A_Display
		tst.b	playerwk
		beq.b	Obj4A_Display
		move.b	#0,playerwk ; remove Sonic
		move.w	#$A8,d0
		jsr	(soundset).l ;	play Special Stage "GOAL" sound

Obj4A_Display:
		jmp	actionsub
; ===========================================================================

Obj4A_LoadSonic:			; XREF: Obj4A_Index
		subq.w	#1,$30(a0)	; subtract 1 from time
		bne.b	Obj4A_Wait	; if time remains, branch
		move.b	#1,playerwk ; load	Sonic object
		jmp	frameout
; ===========================================================================

Obj4A_Wait:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 08 - water splash (LZ)
; ---------------------------------------------------------------------------

Obj08:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj08_Index(pc,d0.w),d1
		jmp	Obj08_Index(pc,d1.w)
; ===========================================================================
Obj08_Index:	dc.w Obj08_Main-Obj08_Index
		dc.w Obj08_Display-Obj08_Index
		dc.w Obj08_Delete-Obj08_Index
; ===========================================================================

Obj08_Main:				; XREF: Obj08_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_obj08,4(a0)
		ori.b	#4,1(a0)
		move.b	#1,$18(a0)
		move.b	#$10,$19(a0)
		move.w	#$4259,2(a0)
		move.w	playerwk+xposi,8(a0) ; copy x-position from Sonic

Obj08_Display:				; XREF: Obj08_Index
		move.w	waterposi,$C(a0) ; copy y-position from water height
		lea	(Ani_obj08).l,a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================

Obj08_Delete:				; XREF: Obj08_Index
		jmp	frameout	; delete when animation	is complete
; ===========================================================================
Ani_effect:
	include "_anim\effect.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - shield and invincibility stars
; ---------------------------------------------------------------------------
Map_effect:
	include "_maps\effect.asm"

Ani_obj4A:
	include "_anim\obj4A.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage entry	from beta
; ---------------------------------------------------------------------------
Map_obj4A:
	include "_maps\obj4A.asm"

Ani_obj08:
	include "_anim\obj08.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - water splash (LZ)
; ---------------------------------------------------------------------------
Map_obj08:
	include "_maps\obj08.asm"

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle & position as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


fcol:				; XREF: play00walk; ball00walk
		btst	#3,cddat(a0)
		beq.b	loc_14602
		moveq	#0,d0
		move.b	d0,dirstk
		move.b	d0,dirstk+2
		rts	
; ===========================================================================

loc_14602:
		moveq	#3,d0
		move.b	d0,dirstk
		move.b	d0,dirstk+2
		move.b	direc(a0),d0
		addi.b	#$20,d0
		bpl.b	loc_14624
		move.b	direc(a0),d0
		bpl.b	loc_1461E
		subq.b	#1,d0

loc_1461E:
		addi.b	#$20,d0
		bra.b	loc_14630
; ===========================================================================

loc_14624:
		move.b	direc(a0),d0
		bpl.b	loc_1462C
		addq.b	#1,d0

loc_1462C:
		addi.b	#$1F,d0

loc_14630:
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	Sonic_WalkVertL
		cmpi.b	#$80,d0
		beq.w	Sonic_WalkCeiling
		cmpi.b	#$C0,d0
		beq.w	Sonic_WalkVertR
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.b	locret_146BE
		bpl.b	loc_146C0
		cmpi.w	#-$E,d1
		blt.b	locret_146E6
		add.w	d1,$C(a0)

locret_146BE:
		rts	
; ===========================================================================

loc_146C0:
		cmpi.w	#$E,d1
		bgt.b	loc_146CC

loc_146C6:
		add.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_146CC:
		tst.b	$38(a0)
		bne.b	loc_146C6
		bset	#1,cddat(a0)
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)
		rts	
; ===========================================================================

locret_146E6:
		rts	
; End of function fcol

; ===========================================================================
		move.l	8(a0),d2
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.l	d2,8(a0)
		move.w	#$38,d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts	
; ===========================================================================

locret_1470A:
		rts	
; ===========================================================================
		move.l	$C(a0),d3
		move.w	$12(a0),d0
		subi.w	#$38,d0
		move.w	d0,$12(a0)
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d3,$C(a0)
		rts	
		rts	
; ===========================================================================
		move.l	8(a0),d2
		move.l	$C(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		sub.l	d0,d3
		move.l	d2,8(a0)
		move.l	d3,$C(a0)
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	change Sonic's angle as he walks along the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_Angle:				; XREF: fcol; et al
		move.b	dirstk+2,d2
		cmp.w	d0,d1
		ble.b	loc_1475E
		move.b	dirstk,d2
		move.w	d0,d1

loc_1475E:
		btst	#0,d2
		bne.b	loc_1476A
		move.b	d2,direc(a0)
		rts	
; ===========================================================================

loc_1476A:
		move.b	direc(a0),d2
		addi.b	#$20,d2
		andi.b	#$C0,d2
		move.b	d2,direc(a0)
		rts	
; End of function Sonic_Angle

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertR:			; XREF: fcol
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		neg.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.b	locret_147F0
		bpl.b	loc_147F2
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		add.w	d1,8(a0)

locret_147F0:
		rts	
; ===========================================================================

loc_147F2:
		cmpi.w	#$E,d1
		bgt.b	loc_147FE

loc_147F8:
		add.w	d1,8(a0)
		rts	
; ===========================================================================

loc_147FE:
		tst.b	$38(a0)
		bne.b	loc_147F8
		bset	#1,cddat(a0)
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertR

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk upside-down
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkCeiling:			; XREF: fcol
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.b	locret_14892
		bpl.b	loc_14894
		cmpi.w	#-$E,d1
		blt.w	locret_146E6
		sub.w	d1,$C(a0)

locret_14892:
		rts	
; ===========================================================================

loc_14894:
		cmpi.w	#$E,d1
		bgt.b	loc_148A0

loc_1489A:
		sub.w	d1,$C(a0)
		rts	
; ===========================================================================

loc_148A0:
		tst.b	$38(a0)
		bne.b	loc_1489A
		bset	#1,cddat(a0)
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkCeiling

; ---------------------------------------------------------------------------
; Subroutine allowing Sonic to walk up a vertical slope/wall to	his left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkVertL:			; XREF: fcol
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	dirstk+2,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$D,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		bsr.w	Sonic_Angle
		tst.w	d1
		beq.b	locret_14934
		bpl.b	loc_14936
		cmpi.w	#-$E,d1
		blt.w	locret_1470A
		sub.w	d1,8(a0)

locret_14934:
		rts	
; ===========================================================================

loc_14936:
		cmpi.w	#$E,d1
		bgt.b	loc_14942

loc_1493C:
		sub.w	d1,8(a0)
		rts	
; ===========================================================================

loc_14942:
		tst.b	$38(a0)
		bne.b	loc_1493C
		bset	#1,cddat(a0)
		bclr	#5,cddat(a0)
		move.b	#1,$1D(a0)
		rts	
; End of function Sonic_WalkVertL

; ---------------------------------------------------------------------------
; Subroutine to	find which tile	the object is standing on
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Floor_ChkTile:				; XREF: FindFloor; et al
		move.w	d2,d0
		lsr.w	#1,d0
		andi.w	#$380,d0
		move.w	d3,d1
		lsr.w	#8,d1
		andi.w	#$7F,d1
		add.w	d1,d0
		moveq	#-1,d1
		lea	mapwka,a1
		move.b	(a1,d0.w),d1
		beq.b	loc_14996
		bmi.b	loc_1499A
		subq.b	#1,d1
		ext.w	d1
		ror.w	#7,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$1E0,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		add.w	d0,d1

loc_14996:
		movea.l	d1,a1
		rts	
; ===========================================================================

loc_1499A:
		andi.w	#$7F,d1
		btst	#6,1(a0)
		beq.b	loc_149B2
		addq.w	#1,d1
		cmpi.w	#$29,d1
		bne.b	loc_149B2
		move.w	#$51,d1

loc_149B2:
		subq.b	#1,d1
		ror.w	#7,d1
		move.w	d2,d0
		add.w	d0,d0
		andi.w	#$1E0,d0
		add.w	d0,d1
		move.w	d3,d0
		lsr.w	#3,d0
		andi.w	#$1E,d0
		add.w	d0,d1
		movea.l	d1,a1
		rts	
; End of function Floor_ChkTile


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindFloor:				; XREF: fcol; et al
		bsr.b	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.b	loc_149DE
		btst	d5,d4
		bne.b	loc_149EC

loc_149DE:
		add.w	a3,d2
		bsr.w	FindFloor2
		sub.w	a3,d2
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_149EC:
		movea.l	scdadr,a2 ; load	collision index
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.b	loc_149DE
		lea	(scddirtbl).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$B,d4
		beq.b	loc_14A12
		not.w	d1
		neg.b	(a4)

loc_14A12:
		btst	#$C,d4
		beq.b	loc_14A22
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14A22:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(scdtbl1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$C,d4
		beq.b	loc_14A3E
		neg.w	d0

loc_14A3E:
		tst.w	d0
		beq.b	loc_149DE
		bmi.b	loc_14A5A
		cmpi.b	#$10,d0
		beq.b	loc_14A66
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14A5A:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_149DE

loc_14A66:
		sub.w	a3,d2
		bsr.w	FindFloor2
		add.w	a3,d2
		subi.w	#$10,d1
		rts	
; End of function FindFloor


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindFloor2:				; XREF: FindFloor
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.b	loc_14A86
		btst	d5,d4
		bne.b	loc_14A94

loc_14A86:
		move.w	#$F,d1
		move.w	d2,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14A94:
		movea.l	scdadr,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.b	loc_14A86
		lea	(scddirtbl).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d3,d1
		btst	#$B,d4
		beq.b	loc_14ABA
		not.w	d1
		neg.b	(a4)

loc_14ABA:
		btst	#$C,d4
		beq.b	loc_14ACA
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14ACA:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(scdtbl1).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$C,d4
		beq.b	loc_14AE6
		neg.w	d0

loc_14AE6:
		tst.w	d0
		beq.b	loc_14A86
		bmi.b	loc_14AFC
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14AFC:
		move.w	d2,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14A86
		not.w	d1
		rts	
; End of function FindFloor2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall:				; XREF: Sonic_WalkVertR; et al
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.b	loc_14B1E
		btst	d5,d4
		bne.b	loc_14B2C

loc_14B1E:
		add.w	a3,d3
		bsr.w	FindWall2
		sub.w	a3,d3
		addi.w	#$10,d1
		rts	
; ===========================================================================

loc_14B2C:
		movea.l	scdadr,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.b	loc_14B1E
		lea	(scddirtbl).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$C,d4
		beq.b	loc_14B5A
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14B5A:
		btst	#$B,d4
		beq.b	loc_14B62
		neg.b	(a4)

loc_14B62:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(scdtbl2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.b	loc_14B7E
		neg.w	d0

loc_14B7E:
		tst.w	d0
		beq.b	loc_14B1E
		bmi.b	loc_14B9A
		cmpi.b	#$10,d0
		beq.b	loc_14BA6
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14B9A:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14B1E

loc_14BA6:
		sub.w	a3,d3
		bsr.w	FindWall2
		add.w	a3,d3
		subi.w	#$10,d1
		rts	
; End of function FindWall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


FindWall2:				; XREF: FindWall
		bsr.w	Floor_ChkTile
		move.w	(a1),d0
		move.w	d0,d4
		andi.w	#$7FF,d0
		beq.b	loc_14BC6
		btst	d5,d4
		bne.b	loc_14BD4

loc_14BC6:
		move.w	#$F,d1
		move.w	d3,d0
		andi.w	#$F,d0
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14BD4:
		movea.l	scdadr,a2
		move.b	(a2,d0.w),d0
		andi.w	#$FF,d0
		beq.b	loc_14BC6
		lea	(scddirtbl).l,a2
		move.b	(a2,d0.w),(a4)
		lsl.w	#4,d0
		move.w	d2,d1
		btst	#$C,d4
		beq.b	loc_14C02
		not.w	d1
		addi.b	#$40,(a4)
		neg.b	(a4)
		subi.b	#$40,(a4)

loc_14C02:
		btst	#$B,d4
		beq.b	loc_14C0A
		neg.b	(a4)

loc_14C0A:
		andi.w	#$F,d1
		add.w	d0,d1
		lea	(scdtbl2).l,a2
		move.b	(a2,d1.w),d0
		ext.w	d0
		eor.w	d6,d4
		btst	#$B,d4
		beq.b	loc_14C26
		neg.w	d0

loc_14C26:
		tst.w	d0
		beq.b	loc_14BC6
		bmi.b	loc_14C3C
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		move.w	#$F,d1
		sub.w	d0,d1
		rts	
; ===========================================================================

loc_14C3C:
		move.w	d3,d1
		andi.w	#$F,d1
		add.w	d1,d0
		bpl.w	loc_14BC6
		not.w	d1
		rts	
; End of function FindWall2

scdcnv:
		rts	

		lea	(scdtbl1).l,a1
		lea	(scdtbl1).l,a2
		move.w	#$FF,d3

loc_14C5E:
		moveq	#$10,d5
		move.w	#$F,d2

loc_14C64:
		moveq	#0,d4
		move.w	#$F,d1

loc_14C6A:
		move.w	(a1)+,d0
		lsr.l	d5,d0
		addx.w	d4,d4
		dbra	d1,loc_14C6A

		move.w	d4,(a2)+
		suba.w	#$20,a1
		subq.w	#1,d5
		dbra	d2,loc_14C64

		adda.w	#$20,a1
		dbra	d3,loc_14C5E

		lea	(scdtbl1).l,a1
		lea	(scdtbl2).l,a2
		bsr.b	scdcnv2
		lea	(scdtbl1).l,a1
		lea	(scdtbl1).l,a2

; End of function scdcnv

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


scdcnv2:				; XREF: scdcnv
		move.w	#$FFF,d3

loc_14CA6:
		moveq	#0,d2
		move.w	#$F,d1
		move.w	(a1)+,d0
		beq.b	loc_14CD4
		bmi.b	loc_14CBE

loc_14CB2:
		lsr.w	#1,d0
		bcc.b	loc_14CB8
		addq.b	#1,d2

loc_14CB8:
		dbra	d1,loc_14CB2

		bra.b	loc_14CD6
; ===========================================================================

loc_14CBE:
		cmpi.w	#-1,d0
		beq.b	loc_14CD0

loc_14CC4:
		lsl.w	#1,d0
		bcc.b	loc_14CCA
		subq.b	#1,d2

loc_14CCA:
		dbra	d1,loc_14CC4

		bra.b	loc_14CD6
; ===========================================================================

loc_14CD0:
		move.w	#$10,d0

loc_14CD4:
		move.w	d0,d2

loc_14CD6:
		move.b	d2,(a2)+
		dbra	d3,loc_14CA6

		rts	

; End of function scdcnv2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_WalkSpeed:			; XREF: levermove
		move.l	8(a0),d3
		move.l	$C(a0),d2
		move.w	$10(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d3
		move.w	$12(a0),d1
		ext.l	d1
		asl.l	#8,d1
		add.l	d1,d2
		swap	d2
		swap	d3
		move.b	d0,dirstk
		move.b	d0,dirstk+2
		move.b	d0,d1
		addi.b	#$20,d0
		bpl.b	loc_14D1A
		move.b	d1,d0
		bpl.b	loc_14D14
		subq.b	#1,d0

loc_14D14:
		addi.b	#$20,d0
		bra.b	loc_14D24
; ===========================================================================

loc_14D1A:
		move.b	d1,d0
		bpl.b	loc_14D20
		addq.b	#1,d0

loc_14D20:
		addi.b	#$1F,d0

loc_14D24:
		andi.b	#$C0,d0
		beq.w	loc_14DF0
		cmpi.b	#$80,d0
		beq.w	loc_14F7C
		andi.b	#$38,d1
		bne.b	loc_14D3C
		addq.w	#8,d2

loc_14D3C:
		cmpi.b	#$40,d0
		beq.w	loc_1504A
		bra.w	loc_14EBC

; End of function Sonic_WalkSpeed


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14D48:				; XREF: jumpchk
		move.b	d0,dirstk
		move.b	d0,dirstk+2
		addi.b	#$20,d0
		andi.b	#$C0,d0
		cmpi.b	#$40,d0
		beq.w	loc_14FD6
		cmpi.b	#$80,d0
		beq.w	Sonic_DontRunOnWalls
		cmpi.b	#$C0,d0
		beq.w	sub_14E50

; End of function sub_14D48

; ---------------------------------------------------------------------------
; Subroutine to	make Sonic land	on the floor after jumping
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitFloor:				; XREF: jumpcolchk
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#0,d2

loc_14DD0:
		move.b	dirstk+2,d3
		cmp.w	d0,d1
		ble.b	loc_14DDE
		move.b	dirstk,d3
		exg	d0,d1

loc_14DDE:
		btst	#0,d3
		beq.b	locret_14DE6
		move.b	d2,d3

locret_14DE6:
		rts	

; End of function Sonic_HitFloor

; ===========================================================================
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14DF0:				; XREF: Sonic_WalkSpeed
		addi.w	#$A,d2
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#0,d2

loc_14E0A:				; XREF: sub_14EB4
		move.b	dirstk,d3
		btst	#0,d3
		beq.b	locret_14E16
		move.b	d2,d3

locret_14E16:
		rts	

; ---------------------------------------------------------------------------
; Subroutine allowing objects to interact with the floor
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


emycol_d:
		move.w	8(a0),d3

; End of function emycol_d


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


emycol_d2:
		move.w	$C(a0),d2
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d2
		lea	dirstk,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$D,d5
		bsr.w	FindFloor
		move.b	dirstk,d3
		btst	#0,d3
		beq.b	locret_14E4E
		move.b	#0,d3

locret_14E4E:
		rts	
; End of function emycol_d2


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14E50:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#-$40,d2
		bra.w	loc_14DD0

; End of function sub_14E50


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_14EB4:				; XREF: jumpcolchk
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14EBC:
		addi.w	#$A,d3
		lea	dirstk,a4
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#-$40,d2
		bra.w	loc_14E0A

; End of function sub_14EB4

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its right
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallRight:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	dirstk,a4
		move.b	#0,(a4)
		movea.w	#$10,a3
		move.w	#0,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	dirstk,d3
		btst	#0,d3
		beq.b	locret_14F06
		move.b	#-$40,d3

locret_14F06:
		rts	

; End of function ObjHitWallRight

; ---------------------------------------------------------------------------
; Subroutine preventing	Sonic from running on walls and	ceilings when he
; touches them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_DontRunOnWalls:			; XREF: jumpcolchk; et al
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d3
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d3
		lea	dirstk+2,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.w	(sp)+,d0
		move.b	#-$80,d2
		bra.w	loc_14DD0
; End of function Sonic_DontRunOnWalls

; ===========================================================================
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_14F7C:
		subi.w	#$A,d2
		eori.w	#$F,d2
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	#-$80,d2
		bra.w	loc_14E0A

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitCeiling:
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d2
		eori.w	#$F,d2
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$1000,d6
		moveq	#$E,d5
		bsr.w	FindFloor
		move.b	dirstk,d3
		btst	#0,d3
		beq.b	locret_14FD4
		move.b	#-$80,d3

locret_14FD4:
		rts	
; End of function ObjHitCeiling

; ===========================================================================

loc_14FD6:				; XREF: sub_14D48
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		sub.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	d1,-(sp)
		move.w	$C(a0),d2
		move.w	8(a0),d3
		moveq	#0,d0
		move.b	$17(a0),d0
		ext.w	d0
		add.w	d0,d2
		move.b	$16(a0),d0
		ext.w	d0
		sub.w	d0,d3
		eori.w	#$F,d3
		lea	dirstk+2,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.w	(sp)+,d0
		move.b	#$40,d2
		bra.w	loc_14DD0

; ---------------------------------------------------------------------------
; Subroutine to	stop Sonic when	he jumps at a wall
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sonic_HitWall:				; XREF: jumpcolchk
		move.w	$C(a0),d2
		move.w	8(a0),d3

loc_1504A:
		subi.w	#$A,d3
		eori.w	#$F,d3
		lea	dirstk,a4
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	#$40,d2
		bra.w	loc_14E0A
; End of function Sonic_HitWall

; ---------------------------------------------------------------------------
; Subroutine to	detect when an object hits a wall to its left
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


ObjHitWallLeft:
		add.w	8(a0),d3
		move.w	$C(a0),d2
		lea	dirstk,a4
		move.b	#0,(a4)
		movea.w	#-$10,a3
		move.w	#$800,d6
		moveq	#$E,d5
		bsr.w	FindWall
		move.b	dirstk,d3
		btst	#0,d3
		beq.b	locret_15098
		move.b	#$40,d3

locret_15098:
		rts	
; End of function ObjHitWallLeft

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 66 - rotating disc that grabs Sonic (SBZ)
; ---------------------------------------------------------------------------

mawaru:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	mawaru_Index(pc,d0.w),d1
		jmp	mawaru_Index(pc,d1.w)
; ===========================================================================
mawaru_Index:	dc.w mawaru_Main-mawaru_Index
		dc.w mawaru_Action-mawaru_Index
		dc.w mawaru_Display-mawaru_Index
		dc.w mawaru_Release-mawaru_Index
; ===========================================================================

mawaru_Main:				; XREF: mawaru_Index
		addq.b	#2,r_no0(a0)
		move.w	#1,d1
		movea.l	a0,a1
		bra.b	mawaru_MakeItem
; ===========================================================================

mawaru_Loop:
		bsr.w	actwkchk
		bne.b	loc_150FE
		move.b	#$66,0(a1)
		addq.b	#4,r_no0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#3,$18(a1)
		move.b	#$10,$1A(a1)

mawaru_MakeItem:				; XREF: mawaru_Main
		move.l	#Map_mawaru,4(a1)
		move.w	#$4348,2(a1)
		ori.b	#4,1(a1)
		move.b	#$38,$19(a1)

loc_150FE:
		dbra	d1,mawaru_Loop

		move.b	#$30,$19(a0)
		move.b	#4,$18(a0)
		move.w	#$3C,$30(a0)
		move.b	#1,$34(a0)
		move.b	userflag(a0),$38(a0)

mawaru_Action:				; XREF: mawaru_Index
		bsr.w	mawaru_ChkSwitch
		tst.b	1(a0)
		bpl.w	mawaru_Display
		move.w	#$30,d1
		move.w	d1,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		btst	#5,cddat(a0)
		beq.w	mawaru_Display
		lea	playerwk,a1
		moveq	#$E,d1
		move.w	8(a1),d0
		cmp.w	8(a0),d0
		bcs.b	mawaru_GrabSonic
		moveq	#7,d1

mawaru_GrabSonic:
		cmp.b	$1A(a0),d1
		bne.b	mawaru_Display
		move.b	d1,$32(a0)
		addq.b	#4,r_no0(a0)
		move.b	#1,($FFFFF7C8).w ; lock	controls
		move.b	#2,$1C(a1)	; make Sonic use "rolling" animation
		move.w	#$800,$14(a1)
		move.w	#0,$10(a1)
		move.w	#0,$12(a1)
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)
		bset	#1,cddat(a1)
		move.w	8(a1),d2
		move.w	$C(a1),d3
		bsr.w	mawaru_ChgPos
		add.w	d2,8(a1)
		add.w	d3,$C(a1)
		asr	8(a1)
		asr	$C(a1)

mawaru_Display:				; XREF: mawaru_Index
		bra.w	frameoutchk
; ===========================================================================

mawaru_Release:				; XREF: mawaru_Index
		move.b	$1A(a0),d0
		cmpi.b	#4,d0
		beq.b	loc_151C8
		cmpi.b	#7,d0
		bne.b	loc_151F8

loc_151C8:
		cmp.b	$32(a0),d0
		beq.b	loc_151F8
		lea	playerwk,a1
		move.w	#0,$10(a1)
		move.w	#$800,$12(a1)
		cmpi.b	#4,d0
		beq.b	loc_151F0
		move.w	#$800,$10(a1)
		move.w	#$800,$12(a1)

loc_151F0:
		clr.b	($FFFFF7C8).w	; unlock controls
		subq.b	#4,r_no0(a0)

loc_151F8:
		bsr.b	mawaru_ChkSwitch
		bsr.b	mawaru_ChgPos
		bra.w	frameoutchk

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mawaru_ChkSwitch:			; XREF: mawaru_Action
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$38(a0),d0
		btst	#0,(a2,d0.w)	; is switch pressed?
		beq.b	loc_15224	; if not, branch
		tst.b	$36(a0)		; has switch previously	been pressed?
		bne.b	mawaru_Animate	; if yes, branch
		neg.b	$34(a0)
		move.b	#1,$36(a0)	; set to "previously pressed"
		bra.b	mawaru_Animate
; ===========================================================================

loc_15224:
		clr.b	$36(a0)		; set to "not yet pressed"

mawaru_Animate:
		subq.b	#1,$1E(a0)
		bpl.b	locret_15246
		move.b	#7,$1E(a0)
		move.b	$34(a0),d1
		move.b	$1A(a0),d0
		add.b	d1,d0
		andi.b	#$F,d0
		move.b	d0,$1A(a0)

locret_15246:
		rts	
; End of function mawaru_ChkSwitch


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


mawaru_ChgPos:				; XREF: mawaru_GrabSonic
		lea	playerwk,a1
		moveq	#0,d0
		move.b	$1A(a0),d0
		add.w	d0,d0
		lea	mawaru_PosData(pc,d0.w),a2
		move.b	(a2)+,d0
		ext.w	d0
		add.w	8(a0),d0
		move.w	d0,8(a1)
		move.b	(a2)+,d0
		ext.w	d0
		add.w	$C(a0),d0
		move.w	d0,$C(a1)
		rts	
; End of function mawaru_ChgPos

; ===========================================================================
mawaru_PosData:	dc.b  $E0,   0,	$E2,  $E ; disc	x-pos, Sonic x-pos, disc y-pos,	Sonic y-pos
		dc.b  $E8, $18,	$F2, $1E
		dc.b	0, $20,	 $E, $1E
		dc.b  $18, $18,	$1E,  $E
		dc.b  $20,   0,	$1E, $F2
		dc.b  $18, $E8,	 $E, $E2
		dc.b	0, $E0,	$F2, $E2
		dc.b  $E8, $E8,	$E2, $F2
; ---------------------------------------------------------------------------
; Sprite mappings - rotating disc that grabs Sonic (SBZ)
; ---------------------------------------------------------------------------
Map_mawaru:
	include "_maps\mawaru.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 67 - disc that	you run	around (SBZ)
; ---------------------------------------------------------------------------

haguruma:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	haguruma_Index(pc,d0.w),d1
		jmp	haguruma_Index(pc,d1.w)
; ===========================================================================
haguruma_Index:	dc.w haguruma_Main-haguruma_Index
		dc.w haguruma_Action-haguruma_Index
; ===========================================================================

haguruma_Main:				; XREF: haguruma_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_haguruma,4(a0)
		move.w	#$C344,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#8,$19(a0)
		move.w	8(a0),$32(a0)
		move.w	$C(a0),$30(a0)
		move.b	#$18,$34(a0)
		move.b	#$48,$38(a0)
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F,d1		; read only the	2nd digit
		beq.b	loc_15546
		move.b	#$10,$34(a0)
		move.b	#$38,$38(a0)

loc_15546:
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F0,d1		; read only the	1st digit
		ext.w	d1
		asl.w	#3,d1
		move.w	d1,$36(a0)
		move.b	cddat(a0),d0
		ror.b	#2,d0
		andi.b	#-$40,d0
		move.b	d0,direc(a0)

haguruma_Action:				; XREF: haguruma_Index
		bsr.w	haguruma_MoveSonic
		bsr.w	haguruma_MoveSpot
		bra.w	haguruma_ChkDel
; ===========================================================================

haguruma_MoveSonic:			; XREF: haguruma_Action
		moveq	#0,d2
		move.b	$38(a0),d2
		move.w	d2,d3
		add.w	d3,d3
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	$32(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.b	loc_155A8
		move.w	$C(a1),d1
		sub.w	$30(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.b	loc_155A8
		btst	#1,cddat(a1)
		beq.b	loc_155B8
		clr.b	$3A(a0)
		rts	
; ===========================================================================

loc_155A8:
		tst.b	$3A(a0)
		beq.b	locret_155B6
		clr.b	$38(a1)
		clr.b	$3A(a0)

locret_155B6:
		rts	
; ===========================================================================

loc_155B8:
		tst.b	$3A(a0)
		bne.b	loc_155E2
		move.b	#1,$3A(a0)
		btst	#2,cddat(a1)
		bne.b	loc_155D0
		clr.b	$1C(a1)

loc_155D0:
		bclr	#5,cddat(a1)
		move.b	#1,$1D(a1)
		move.b	#1,$38(a1)

loc_155E2:
		move.w	$14(a1),d0
		tst.w	$36(a0)
		bpl.b	loc_15608
		cmpi.w	#-$400,d0
		ble.b	loc_155FA
		move.w	#-$400,$14(a1)
		rts	
; ===========================================================================

loc_155FA:
		cmpi.w	#-$F00,d0
		bge.b	locret_15606
		move.w	#-$F00,$14(a1)

locret_15606:
		rts	
; ===========================================================================

loc_15608:
		cmpi.w	#$400,d0
		bge.b	loc_15616
		move.w	#$400,$14(a1)
		rts	
; ===========================================================================

loc_15616:
		cmpi.w	#$F00,d0
		ble.b	locret_15622
		move.w	#$F00,$14(a1)

locret_15622:
		rts	
; ===========================================================================

haguruma_MoveSpot:				; XREF: haguruma_Action
		move.w	$36(a0),d0
		add.w	d0,direc(a0)
		move.b	direc(a0),d0
		jsr	(sinset).l
		move.w	$30(a0),d2
		move.w	$32(a0),d3
		moveq	#0,d4
		move.b	$34(a0),d4
		lsl.w	#8,d4
		move.l	d4,d5
		muls.w	d0,d4
		swap	d4
		muls.w	d1,d5
		swap	d5
		add.w	d2,d4
		add.w	d3,d5
		move.w	d4,$C(a0)
		move.w	d5,8(a0)
		rts	
; ===========================================================================

haguruma_ChkDel:				; XREF: haguruma_Action
		move.w	$32(a0),d0
		andi.w	#-$80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#-$80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	haguruma_Delete
		jmp	actionsub
; ===========================================================================

haguruma_Delete:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - disc that you run around (SBZ)
; (It's just a small blob that moves around in a circle. The disc itself is
; part of the level tiles.)
; ---------------------------------------------------------------------------
Map_haguruma:
	include "_maps\haguruma.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 68 - conveyor belts (SBZ)
; ---------------------------------------------------------------------------

beltcon:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	beltcon_Index(pc,d0.w),d1
		jmp	beltcon_Index(pc,d1.w)
; ===========================================================================
beltcon_Index:	dc.w beltcon_Main-beltcon_Index
		dc.w beltcon_Action-beltcon_Index
; ===========================================================================

beltcon_Main:				; XREF: beltcon_Index
		addq.b	#2,r_no0(a0)
		move.b	#128,$38(a0)	; set width to 128 pixels
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F,d1		; read only the	2nd digit
		beq.b	loc_156BA	; if zero, branch
		move.b	#56,$38(a0)	; set width to 56 pixels

loc_156BA:
		move.b	userflag(a0),d1	; get object type
		andi.b	#$F0,d1		; read only the	1st digit
		ext.w	d1
		asr.w	#4,d1
		move.w	d1,$36(a0)	; set belt speed

beltcon_Action:				; XREF: beltcon_Index
		bsr.b	beltcon_MoveSonic
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	beltcon_Delete
		rts	
; ===========================================================================

beltcon_Delete:
		jmp	frameout
; ===========================================================================

beltcon_MoveSonic:			; XREF: beltcon_Action
		moveq	#0,d2
		move.b	$38(a0),d2
		move.w	d2,d3
		add.w	d3,d3
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.b	locret_1572E
		move.w	$C(a1),d1
		sub.w	$C(a0),d1
		addi.w	#$30,d1
		cmpi.w	#$30,d1
		bcc.b	locret_1572E
		btst	#1,cddat(a1)
		bne.b	locret_1572E
		move.w	$36(a0),d0
		add.w	d0,8(a1)

locret_1572E:
		rts	

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 69 - spinning platforms and trapdoors (SBZ)
; ---------------------------------------------------------------------------

pata:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	pata_Index(pc,d0.w),d1
		jmp	pata_Index(pc,d1.w)
; ===========================================================================
pata_Index:	dc.w pata_Main-pata_Index
		dc.w pata_Trapdoor-pata_Index
		dc.w pata_Spinner-pata_Index
; ===========================================================================

pata_Main:				; XREF: pata_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_pata,4(a0)
		move.w	#$4492,2(a0)
		ori.b	#4,1(a0)
		move.b	#$80,$19(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		mulu.w	#$3C,d0
		move.w	d0,$32(a0)
		tst.b	userflag(a0)
		bpl.b	pata_Trapdoor
		addq.b	#2,r_no0(a0)
		move.l	#Map_pataa,4(a0)
		move.w	#$4DF,2(a0)
		move.b	#$10,$19(a0)
		move.b	#2,$1C(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		move.w	d0,d1
		andi.w	#$F,d0		; read only the	2nd digit
		mulu.w	#6,d0		; multiply by 6
		move.w	d0,$30(a0)	; set time delay
		move.w	d0,$32(a0)
		andi.w	#$70,d1
		addi.w	#$10,d1
		lsl.w	#2,d1
		subq.w	#1,d1
		move.w	d1,$36(a0)
		bra.b	pata_Spinner
; ===========================================================================

pata_Trapdoor:				; XREF: pata_Index
		subq.w	#1,$30(a0)
		bpl.b	pata_Animate
		move.w	$32(a0),$30(a0)
		bchg	#0,$1C(a0)
		tst.b	1(a0)
		bpl.b	pata_Animate
		move.w	#$BB,d0
		jsr	(soundset).l ;	play door sound

pata_Animate:
		lea	(Ani_pata).l,a1
		jsr	patchg
		tst.b	$1A(a0)		; is frame number 0 displayed?
		bne.b	pata_NotSolid	; if not, branch
		move.w	#$4B,d1
		move.w	#$C,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		bra.w	frameoutchk
; ===========================================================================

pata_NotSolid:
		btst	#3,cddat(a0)
		beq.b	pata_Display
		lea	playerwk,a1
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)

pata_Display:
		bra.w	frameoutchk
; ===========================================================================

pata_Spinner:				; XREF: pata_Index
		move.w	gametimer,d0
		and.w	$36(a0),d0
		bne.b	pata_Delay
		move.b	#1,$34(a0)

pata_Delay:
		tst.b	$34(a0)
		beq.b	pata_Animate2
		subq.w	#1,$30(a0)
		bpl.b	pata_Animate2
		move.w	$32(a0),$30(a0)
		clr.b	$34(a0)
		bchg	#0,$1C(a0)

pata_Animate2:
		lea	(Ani_pata).l,a1
		jsr	patchg
		tst.b	$1A(a0)		; check	if frame number	0 is displayed
		bne.b	pata_NotSolid2	; if not, branch
		move.w	#$1B,d1
		move.w	#7,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	8(a0),d4
		bsr.w	hitchk
		bra.w	frameoutchk
; ===========================================================================

pata_NotSolid2:
		btst	#3,cddat(a0)
		beq.b	pata_Display2
		lea	playerwk,a1
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)

pata_Display2:
		bra.w	frameoutchk
; ===========================================================================
Ani_pata:
	include "_anim\pata.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - trapdoor (SBZ)
; ---------------------------------------------------------------------------
Map_pata:
	include "_maps\pata.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - spinning platforms (SBZ)
; ---------------------------------------------------------------------------
Map_pataa:
	include "_maps\pataa.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6A - ground saws and pizza cutters (SBZ)
; ---------------------------------------------------------------------------

noko:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	noko_Index(pc,d0.w),d1
		jmp	noko_Index(pc,d1.w)
; ===========================================================================
noko_Index:	dc.w noko_Main-noko_Index
		dc.w noko_Action-noko_Index
; ===========================================================================

noko_Main:				; XREF: noko_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_noko,4(a0)
		move.w	#$43B5,2(a0)
		move.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$20,$19(a0)
		move.w	8(a0),$3A(a0)
		move.w	$C(a0),$38(a0)
		cmpi.b	#3,userflag(a0)
		bcc.b	noko_Action
		move.b	#$A2,colino(a0)

noko_Action:				; XREF: noko_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#7,d0
		add.w	d0,d0
		move.w	noko_TypeIndex(pc,d0.w),d1
		jsr	noko_TypeIndex(pc,d1.w)
		move.w	$3A(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	noko_Delete
		jmp	actionsub
; ===========================================================================

noko_Delete:
		jmp	frameout
; ===========================================================================
noko_TypeIndex:dc.w noko_Type00-noko_TypeIndex, noko_Type01-noko_TypeIndex
		dc.w noko_Type02-noko_TypeIndex, noko_Type03-noko_TypeIndex
		dc.w noko_Type04-noko_TypeIndex
; ===========================================================================

noko_Type00:				; XREF: noko_TypeIndex
		rts	
; ===========================================================================

noko_Type01:				; XREF: noko_TypeIndex
		move.w	#$60,d1
		moveq	#0,d0
		move.b	($FFFFFE6C).w,d0
		btst	#0,cddat(a0)
		beq.b	noko_Animate01
		neg.w	d0
		add.w	d1,d0

noko_Animate01:
		move.w	$3A(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)	; move saw sideways
		subq.b	#1,$1E(a0)
		bpl.b	loc_15A46
		move.b	#2,$1E(a0)	; time between frame changes
		bchg	#0,$1A(a0)	; change frame

loc_15A46:
		tst.b	1(a0)
		bpl.b	locret_15A60
		move.w	gametimer,d0
		andi.w	#$F,d0
		bne.b	locret_15A60
		move.w	#$B0,d0
		jsr	(soundset).l ;	play saw sound

locret_15A60:
		rts	
; ===========================================================================

noko_Type02:				; XREF: noko_TypeIndex
		move.w	#$30,d1
		moveq	#0,d0
		move.b	($FFFFFE64).w,d0
		btst	#0,cddat(a0)
		beq.b	noko_Animate02
		neg.w	d0
		addi.w	#$80,d0

noko_Animate02:
		move.w	$38(a0),d1
		sub.w	d0,d1
		move.w	d1,$C(a0)	; move saw vertically
		subq.b	#1,$1E(a0)
		bpl.b	loc_15A96
		move.b	#2,$1E(a0)
		bchg	#0,$1A(a0)

loc_15A96:
		tst.b	1(a0)
		bpl.b	locret_15AB0
		move.b	($FFFFFE64).w,d0
		cmpi.b	#$18,d0
		bne.b	locret_15AB0
		move.w	#$B0,d0
		jsr	(soundset).l ;	play saw sound

locret_15AB0:
		rts	
; ===========================================================================

noko_Type03:				; XREF: noko_TypeIndex
		tst.b	$3D(a0)
		bne.b	noko_Animate03
		move.w	playerwk+xposi,d0
		subi.w	#$C0,d0
		bcs.b	loc_15B02
		sub.w	8(a0),d0
		bcs.b	loc_15B02
		move.w	playerwk+yposi,d0
		subi.w	#$80,d0
		cmp.w	$C(a0),d0
		bcc.b	locret_15B04
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bcs.b	locret_15B04
		move.b	#1,$3D(a0)
		move.w	#$600,$10(a0)	; move object to the right
		move.b	#$A2,colino(a0)
		move.b	#2,$1A(a0)
		move.w	#$B0,d0
		jsr	(soundset).l ;	play saw sound

loc_15B02:
		addq.l	#4,sp

locret_15B04:
		rts	
; ===========================================================================

noko_Animate03:			; XREF: ROM:00015AB6j
		jsr	speedset2
		move.w	8(a0),$3A(a0)
		subq.b	#1,$1E(a0)
		bpl.b	locret_15B24
		move.b	#2,$1E(a0)
		bchg	#0,$1A(a0)

locret_15B24:
		rts	
; ===========================================================================

noko_Type04:				; XREF: noko_TypeIndex
		tst.b	$3D(a0)
		bne.b	noko_Animate04
		move.w	playerwk+xposi,d0
		addi.w	#$E0,d0
		sub.w	8(a0),d0
		bcc.b	loc_15B74
		move.w	playerwk+yposi,d0
		subi.w	#$80,d0
		cmp.w	$C(a0),d0
		bcc.b	locret_15B76
		addi.w	#$100,d0
		cmp.w	$C(a0),d0
		bcs.b	locret_15B76
		move.b	#1,$3D(a0)
		move.w	#-$600,$10(a0)	; move object to the left
		move.b	#$A2,colino(a0)
		move.b	#2,$1A(a0)
		move.w	#$B0,d0
		jsr	(soundset).l ;	play saw sound

loc_15B74:
		addq.l	#4,sp

locret_15B76:
		rts	
; ===========================================================================

noko_Animate04:
		jsr	speedset2
		move.w	8(a0),$3A(a0)
		subq.b	#1,$1E(a0)
		bpl.b	locret_15B96
		move.b	#2,$1E(a0)
		bchg	#0,$1A(a0)

locret_15B96:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - ground saws	and pizza cutters (SBZ)
; ---------------------------------------------------------------------------
Map_noko:
	include "_maps\noko.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6B - stomper (SBZ)
; ---------------------------------------------------------------------------

dai4:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	dai4_Index(pc,d0.w),d1
		jmp	dai4_Index(pc,d1.w)
; ===========================================================================
dai4_Index:	dc.w dai4_Main-dai4_Index
		dc.w dai4_Action-dai4_Index

dai4_Var:	dc.b  $40,  $C,	$80,   1 ; width, height, ????,	type number
		dc.b  $1C, $20,	$38,   3
		dc.b  $1C, $20,	$40,   4
		dc.b  $1C, $20,	$60,   4
		dc.b  $80, $40,	  0,   5
; ===========================================================================

dai4_Main:				; XREF: dai4_Index
		addq.b	#2,r_no0(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsr.w	#2,d0
		andi.w	#$1C,d0
		lea	dai4_Var(pc,d0.w),a3
		move.b	(a3)+,$19(a0)
		move.b	(a3)+,$16(a0)
		lsr.w	#2,d0
		move.b	d0,$1A(a0)
		move.l	#Map_dai4,4(a0)
		move.w	#$22C0,2(a0)
		cmpi.b	#1,stageno ; check if level is LZ/SBZ3
		bne.b	dai4_SBZ12	; if not, branch
		bset	#0,($FFFFF7CB).w
		beq.b	dai4_SBZ3

dai4_ChkGone:				; XREF: dai4_SBZ3
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	dai4_Delete
		bclr	#7,2(a2,d0.w)

dai4_Delete:
		jmp	frameout
; ===========================================================================

dai4_SBZ3:				; XREF: dai4_Main
		move.w	#$41F0,2(a0)
		cmpi.w	#$A80,8(a0)
		bne.b	dai4_SBZ12
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	dai4_SBZ12
		btst	#0,2(a2,d0.w)
		beq.b	dai4_SBZ12
		clr.b	($FFFFF7CB).w
		bra.b	dai4_ChkGone
; ===========================================================================

dai4_SBZ12:				; XREF: dai4_Main
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.w	8(a0),$34(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	(a3)+,d0
		move.w	d0,$3C(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		bpl.b	dai4_Action
		andi.b	#$F,d0
		move.b	d0,$3E(a0)
		move.b	(a3),userflag(a0)
		cmpi.b	#5,(a3)
		bne.b	dai4_ChkGone2
		bset	#4,1(a0)

dai4_ChkGone2:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	dai4_Action
		bclr	#7,2(a2,d0.w)

dai4_Action:				; XREF: dai4_Index
		move.w	8(a0),-(sp)
		moveq	#0,d0
		move.b	userflag(a0),d0
		andi.w	#$F,d0
		add.w	d0,d0
		move.w	dai4_TypeIndex(pc,d0.w),d1
		jsr	dai4_TypeIndex(pc,d1.w)
		move.w	(sp)+,d4
		tst.b	1(a0)
		bpl.b	dai4_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	hitchk

dai4_ChkDel:
		move.w	$34(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	loc_15D64
		jmp	actionsub
; ===========================================================================

loc_15D64:
		cmpi.b	#1,stageno
		bne.b	dai4_Delete2
		clr.b	($FFFFF7CB).w
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	dai4_Delete2
		bclr	#7,2(a2,d0.w)

dai4_Delete2:
		jmp	frameout
; ===========================================================================
dai4_TypeIndex:dc.w dai4_Type00-dai4_TypeIndex, dai4_Type01-dai4_TypeIndex
		dc.w dai4_Type02-dai4_TypeIndex, dai4_Type03-dai4_TypeIndex
		dc.w dai4_Type04-dai4_TypeIndex, dai4_Type05-dai4_TypeIndex
; ===========================================================================

dai4_Type00:				; XREF: dai4_TypeIndex
		rts	
; ===========================================================================

dai4_Type01:				; XREF: dai4_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_15DB4
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3E(a0),d0
		btst	#0,(a2,d0.w)
		beq.b	loc_15DC2
		move.b	#1,$38(a0)

loc_15DB4:
		move.w	$3C(a0),d0
		cmp.w	$3A(a0),d0
		beq.b	loc_15DE0
		addq.w	#2,$3A(a0)

loc_15DC2:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_15DD4
		neg.w	d0
		addi.w	#$80,d0

loc_15DD4:
		move.w	$34(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

loc_15DE0:
		addq.b	#1,userflag(a0)
		move.w	#$B4,$36(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_15DC2
		bset	#0,2(a2,d0.w)
		bra.b	loc_15DC2
; ===========================================================================

dai4_Type02:				; XREF: dai4_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_15E14
		subq.w	#1,$36(a0)
		bne.b	loc_15E1E
		move.b	#1,$38(a0)

loc_15E14:
		tst.w	$3A(a0)
		beq.b	loc_15E3C
		subq.w	#2,$3A(a0)

loc_15E1E:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_15E30
		neg.w	d0
		addi.w	#$80,d0

loc_15E30:
		move.w	$34(a0),d1
		sub.w	d0,d1
		move.w	d1,8(a0)
		rts	
; ===========================================================================

loc_15E3C:
		subq.b	#1,userflag(a0)
		clr.b	$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_15E1E
		bclr	#0,2(a2,d0.w)
		bra.b	loc_15E1E
; ===========================================================================

dai4_Type03:				; XREF: dai4_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_15E7C
		tst.w	$3A(a0)
		beq.b	loc_15E6A
		subq.w	#1,$3A(a0)
		bra.b	loc_15E8E
; ===========================================================================

loc_15E6A:
		subq.w	#1,$36(a0)
		bpl.b	loc_15E8E
		move.w	#$3C,$36(a0)
		move.b	#1,$38(a0)

loc_15E7C:
		addq.w	#8,$3A(a0)
		move.w	$3A(a0),d0
		cmp.w	$3C(a0),d0
		bne.b	loc_15E8E
		clr.b	$38(a0)

loc_15E8E:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_15EA0
		neg.w	d0
		addi.w	#$38,d0

loc_15EA0:
		move.w	$30(a0),d1
		add.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

dai4_Type04:				; XREF: dai4_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_15ED0
		tst.w	$3A(a0)
		beq.b	loc_15EBE
		subq.w	#8,$3A(a0)
		bra.b	loc_15EF0
; ===========================================================================

loc_15EBE:
		subq.w	#1,$36(a0)
		bpl.b	loc_15EF0
		move.w	#$3C,$36(a0)
		move.b	#1,$38(a0)

loc_15ED0:
		move.w	$3A(a0),d0
		cmp.w	$3C(a0),d0
		beq.b	loc_15EE0
		addq.w	#8,$3A(a0)
		bra.b	loc_15EF0
; ===========================================================================

loc_15EE0:
		subq.w	#1,$36(a0)
		bpl.b	loc_15EF0
		move.w	#$3C,$36(a0)
		clr.b	$38(a0)

loc_15EF0:
		move.w	$3A(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_15F02
		neg.w	d0
		addi.w	#$38,d0

loc_15F02:
		move.w	$30(a0),d1
		add.w	d0,d1
		move.w	d1,$C(a0)
		rts	
; ===========================================================================

dai4_Type05:				; XREF: dai4_TypeIndex
		tst.b	$38(a0)
		bne.b	loc_15F3E
		lea	($FFFFF7E0).w,a2
		moveq	#0,d0
		move.b	$3E(a0),d0
		btst	#0,(a2,d0.w)
		beq.b	locret_15F5C
		move.b	#1,$38(a0)
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_15F3E
		bset	#0,2(a2,d0.w)

loc_15F3E:
		subi.l	#$10000,8(a0)
		addi.l	#$8000,$C(a0)
		move.w	8(a0),$34(a0)
		cmpi.w	#$980,8(a0)
		beq.b	loc_15F5E

locret_15F5C:
		rts	
; ===========================================================================

loc_15F5E:
		clr.b	userflag(a0)
		clr.b	$38(a0)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - stomper and	platforms (SBZ)
; ---------------------------------------------------------------------------
Map_dai4:
	include "_maps\dai4.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6C - vanishing	platforms (SBZ)
; ---------------------------------------------------------------------------

yukae:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yukae_Index(pc,d0.w),d1
		jmp	yukae_Index(pc,d1.w)
; ===========================================================================
yukae_Index:	dc.w yukae_Main-yukae_Index
		dc.w yukae_Vanish-yukae_Index
		dc.w yukae_Vanish-yukae_Index
		dc.w loc_16068-yukae_Index
; ===========================================================================

yukae_Main:				; XREF: yukae_Index
		addq.b	#6,r_no0(a0)
		move.l	#Map_yukae,4(a0)
		move.w	#$44C3,2(a0)
		ori.b	#4,1(a0)
		move.b	#$10,$19(a0)
		move.b	#4,$18(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		andi.w	#$F,d0		; read only the	2nd digit
		addq.w	#1,d0		; add 1
		lsl.w	#7,d0		; multiply by $80
		move.w	d0,d1
		subq.w	#1,d0
		move.w	d0,$30(a0)
		move.w	d0,$32(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; get object type
		andi.w	#$F0,d0		; read only the	1st digit
		addi.w	#$80,d1
		mulu.w	d1,d0
		lsr.l	#8,d0
		move.w	d0,$36(a0)
		subq.w	#1,d1
		move.w	d1,$38(a0)

loc_16068:				; XREF: yukae_Index
		move.w	gametimer,d0
		sub.w	$36(a0),d0
		and.w	$38(a0),d0
		bne.b	yukae_Animate
		subq.b	#4,r_no0(a0)
		bra.b	yukae_Vanish
; ===========================================================================

yukae_Animate:
		lea	(Ani_yukae).l,a1
		jsr	patchg
		bra.w	frameoutchk
; ===========================================================================

yukae_Vanish:				; XREF: yukae_Index
		subq.w	#1,$30(a0)
		bpl.b	loc_160AA
		move.w	#127,$30(a0)
		tst.b	$1C(a0)
		beq.b	loc_160A4
		move.w	$32(a0),$30(a0)

loc_160A4:
		bchg	#0,$1C(a0)

loc_160AA:
		lea	(Ani_yukae).l,a1
		jsr	patchg
		btst	#1,$1A(a0)	; has platform vanished?
		bne.b	yukae_NotSolid	; if yes, branch
		cmpi.b	#2,r_no0(a0)
		bne.b	loc_160D6
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(PlatformObject).l
		bra.w	frameoutchk
; ===========================================================================

loc_160D6:
		moveq	#0,d1
		move.b	$19(a0),d1
		jsr	(ExitPlatform).l
		move.w	8(a0),d2
		jsr	(MvSonicOnPtfm2).l
		bra.w	frameoutchk
; ===========================================================================

yukae_NotSolid:				; XREF: yukae_Vanish
		btst	#3,cddat(a0)
		beq.b	yukae_Display
		lea	playerwk,a1
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		move.b	#2,r_no0(a0)
		clr.b	r_no1(a0)

yukae_Display:
		bra.w	frameoutchk
; ===========================================================================
Ani_yukae:
	include "_anim\yukae.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - vanishing platforms	(SBZ)
; ---------------------------------------------------------------------------
Map_yukae:
	include "_maps\yukae.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6E - electrocution orbs (SBZ)
; ---------------------------------------------------------------------------

ele:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	ele_Index(pc,d0.w),d1
		jmp	ele_Index(pc,d1.w)
; ===========================================================================
ele_Index:	dc.w ele_Main-ele_Index
		dc.w ele_Shock-ele_Index
; ===========================================================================

ele_Main:				; XREF: ele_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_ele,4(a0)
		move.w	#$47E,2(a0)
		ori.b	#4,1(a0)
		move.b	#$28,$19(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0	; read object type
		lsl.w	#4,d0		; multiply by $10
		subq.w	#1,d0
		move.w	d0,$34(a0)

ele_Shock:				; XREF: ele_Index
		move.w	gametimer,d0
		and.w	$34(a0),d0
		bne.b	ele_Animate
		move.b	#1,$1C(a0)	; run "shocking" animation
		tst.b	1(a0)
		bpl.b	ele_Animate
		move.w	#$B1,d0
		jsr	(soundset).l ;	play electricity sound

ele_Animate:
		lea	(Ani_ele).l,a1
		jsr	patchg
		move.b	#0,colino(a0)
		cmpi.b	#4,$1A(a0)	; is frame number 4 displayed?
		bne.b	ele_Display	; if not, branch
		move.b	#$A4,colino(a0)	; if yes, make object hurt Sonic

ele_Display:
		bra.w	frameoutchk
; ===========================================================================
Ani_ele:
	include "_anim\ele.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - electrocution orbs (SBZ)
; ---------------------------------------------------------------------------
Map_ele:
	include "_maps\ele.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 6F - spinning platforms that move around a conveyor belt (SBZ)
; ---------------------------------------------------------------------------

beltc:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	beltc_Index(pc,d0.w),d1
		jsr	beltc_Index(pc,d1.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	loc_1629A

beltc_Display:
		jmp	actionsub
; ===========================================================================

loc_1629A:
		cmpi.b	#2,stageno+1 ; check if act	is 3
		bne.b	beltc_Act1or2	; if not, branch
		cmpi.w	#-$80,d0
		bcc.b	beltc_Display

beltc_Act1or2:
		move.b	$2F(a0),d0
		bpl.b	beltc_Delete
		andi.w	#$7F,d0
		lea	($FFFFF7C1).w,a2
		bclr	#0,(a2,d0.w)

beltc_Delete:
		jmp	frameout
; ===========================================================================
beltc_Index:	dc.w beltc_Main-beltc_Index
		dc.w loc_163D8-beltc_Index
; ===========================================================================

beltc_Main:				; XREF: beltc_Index
		move.b	userflag(a0),d0
		bmi.w	loc_16380
		addq.b	#2,r_no0(a0)
		move.l	#Map_pataa,4(a0)
		move.w	#$4DF,2(a0)
		move.b	#$10,$19(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.w	d0,d1
		lsr.w	#3,d0
		andi.w	#$1E,d0
		lea	off_164A6(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$38(a0)
		move.w	(a2)+,$30(a0)
		move.l	a2,$3C(a0)
		andi.w	#$F,d1
		lsl.w	#2,d1
		move.b	d1,$38(a0)
		move.b	#4,$3A(a0)
		tst.b	($FFFFF7C0).w
		beq.b	loc_16356
		move.b	#1,$3B(a0)
		neg.b	$3A(a0)
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		bcs.b	loc_16352
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.b	loc_16352
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_16352:
		move.b	d1,$38(a0)

loc_16356:
		move.w	(a2,d1.w),$34(a0)
		move.w	2(a2,d1.w),$36(a0)
		tst.w	d1
		bne.b	loc_1636C
		move.b	#1,$1C(a0)

loc_1636C:
		cmpi.w	#8,d1
		bne.b	loc_16378
		move.b	#0,$1C(a0)

loc_16378:
		bsr.w	kassya_ChangeDir
		bra.w	loc_163D8
; ===========================================================================

loc_16380:				; XREF: beltc_Main
		move.b	d0,$2F(a0)
		andi.w	#$7F,d0
		lea	($FFFFF7C1).w,a2
		bset	#0,(a2,d0.w)
		beq.b	loc_1639A
		jmp	frameout
; ===========================================================================

loc_1639A:
		add.w	d0,d0
		andi.w	#$1E,d0
		addi.w	#$80,d0
		lea	(ObjPos_Index).l,a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d1
		movea.l	a0,a1
		bra.b	beltc_LoadPform
; ===========================================================================

beltc_Loop:
		jsr	actwkchk
		bne.b	loc_163D0

beltc_LoadPform:			; XREF: loc_1639A
		move.b	#$6F,0(a1)
		move.w	(a2)+,8(a1)
		move.w	(a2)+,$C(a1)
		move.w	(a2)+,d0
		move.b	d0,userflag(a1)

loc_163D0:
		dbra	d1,beltc_Loop

		addq.l	#4,sp
		rts	
; ===========================================================================

loc_163D8:				; XREF: beltc_Index
		lea	(Ani_beltc).l,a1
		jsr	patchg
		tst.b	$1A(a0)
		bne.b	loc_16404
		move.w	8(a0),-(sp)
		bsr.w	loc_16424
		move.w	#$1B,d1
		move.w	#7,d2
		move.w	d2,d3
		addq.w	#1,d3
		move.w	(sp)+,d4
		bra.w	hitchk
; ===========================================================================

loc_16404:
		btst	#3,cddat(a0)
		beq.b	loc_16420
		lea	playerwk,a1
		bclr	#3,cddat(a1)
		bclr	#3,cddat(a0)
		clr.b	r_no1(a0)

loc_16420:
		bra.w	*+4

loc_16424:
		move.w	8(a0),d0
		cmp.w	$34(a0),d0
		bne.b	loc_16484
		move.w	$C(a0),d0
		cmp.w	$36(a0),d0
		bne.b	loc_16484
		moveq	#0,d1
		move.b	$38(a0),d1
		add.b	$3A(a0),d1
		cmp.b	$39(a0),d1
		bcs.b	loc_16456
		move.b	d1,d0
		moveq	#0,d1
		tst.b	d0
		bpl.b	loc_16456
		move.b	$39(a0),d1
		subq.b	#4,d1

loc_16456:
		move.b	d1,$38(a0)
		movea.l	$3C(a0),a1
		move.w	(a1,d1.w),$34(a0)
		move.w	2(a1,d1.w),$36(a0)
		tst.w	d1
		bne.b	loc_16474
		move.b	#1,$1C(a0)

loc_16474:
		cmpi.w	#8,d1
		bne.b	loc_16480
		move.b	#0,$1C(a0)

loc_16480:
		bsr.w	kassya_ChangeDir

loc_16484:
		jmp	speedset2
; ===========================================================================
Ani_beltc:
	include "_anim\beltc.asm"

off_164A6:	dc.w word_164B2-off_164A6, word_164C6-off_164A6, word_164DA-off_164A6
		dc.w word_164EE-off_164A6, word_16502-off_164A6, word_16516-off_164A6
word_164B2:	dc.w $10, $E80,	$E14, $370, $EEF, $302,	$EEF, $340, $E14, $3AE
word_164C6:	dc.w $10, $F80,	$F14, $2E0, $FEF, $272,	$FEF, $2B0, $F14, $31E
word_164DA:	dc.w $10, $1080, $1014,	$270, $10EF, $202, $10EF, $240,	$1014, $2AE
word_164EE:	dc.w $10, $F80,	$F14, $570, $FEF, $502,	$FEF, $540, $F14, $5AE
word_16502:	dc.w $10, $1B80, $1B14,	$670, $1BEF, $602, $1BEF, $640,	$1B14, $6AE
word_16516:	dc.w $10, $1C80, $1C14,	$5E0, $1CEF, $572, $1CEF, $5B0,	$1C14, $61E
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 70 - large girder block (SBZ)
; ---------------------------------------------------------------------------

yukai:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	yukai_Index(pc,d0.w),d1
		jmp	yukai_Index(pc,d1.w)
; ===========================================================================
yukai_Index:	dc.w yukai_Main-yukai_Index
		dc.w yukai_Action-yukai_Index
; ===========================================================================

yukai_Main:				; XREF: yukai_Index
		addq.b	#2,r_no0(a0)
		move.l	#Map_yukai,4(a0)
		move.w	#$42F0,2(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$60,$19(a0)
		move.b	#$18,$16(a0)
		move.w	8(a0),$32(a0)
		move.w	$C(a0),$30(a0)
		bsr.w	yukai_Move2

yukai_Action:				; XREF: yukai_Index
		move.w	8(a0),-(sp)
		tst.w	$3A(a0)
		beq.b	yukai_Move
		subq.w	#1,$3A(a0)
		bne.b	yukai_Solid

yukai_Move:
		jsr	speedset2
		subq.w	#1,$34(a0)	; subtract 1 from movement duration
		bne.b	yukai_Solid	; if time remains, branch
		bsr.w	yukai_Move2	; if time is zero, branch

yukai_Solid:
		move.w	(sp)+,d4
		tst.b	1(a0)
		bpl.b	yukai_ChkDel
		moveq	#0,d1
		move.b	$19(a0),d1
		addi.w	#$B,d1
		moveq	#0,d2
		move.b	$16(a0),d2
		move.w	d2,d3
		addq.w	#1,d3
		bsr.w	hitchk

yukai_ChkDel:
		move.w	$32(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	yukai_Delete
		jmp	actionsub
; ===========================================================================

yukai_Delete:
		jmp	frameout
; ===========================================================================

yukai_Move2:				; XREF: yukai_Main
		move.b	$38(a0),d0
		andi.w	#$18,d0
		lea	(yukai_MoveData).l,a1
		lea	(a1,d0.w),a1
		move.w	(a1)+,$10(a0)
		move.w	(a1)+,$12(a0)
		move.w	(a1)+,$34(a0)
		addq.b	#8,$38(a0)	; use next movedata set
		move.w	#7,$3A(a0)
		rts	
; ===========================================================================
yukai_MoveData:	dc.w   $100,	 0,   $60,     0 ; x-speed, y-speed, duration, blank
		dc.w	  0,  $100,   $30,     0
		dc.w  $FF00, $FFC0,   $60,     0
		dc.w	  0, $FF00,   $18,     0
; ---------------------------------------------------------------------------
; Sprite mappings - large girder block (SBZ)
; ---------------------------------------------------------------------------
Map_yukai:
	include "_maps\yukai.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 72 - teleporter (SBZ)
; ---------------------------------------------------------------------------

Obj72:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj72_Index(pc,d0.w),d1
		jsr	Obj72_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	Obj72_Delete
		rts	
; ===========================================================================

Obj72_Delete:
		jmp	frameout
; ===========================================================================
Obj72_Index:	dc.w Obj72_Main-Obj72_Index
		dc.w loc_166C8-Obj72_Index
		dc.w loc_1675E-Obj72_Index
		dc.w loc_16798-Obj72_Index
; ===========================================================================

Obj72_Main:				; XREF: Obj72_Index
		addq.b	#2,r_no0(a0)
		move.b	userflag(a0),d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	Obj72_Data(pc),a2
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,$3A(a0)
		move.l	a2,$3C(a0)
		move.w	(a2)+,$36(a0)
		move.w	(a2)+,$38(a0)

loc_166C8:				; XREF: Obj72_Index
		lea	playerwk,a1
		move.w	8(a1),d0
		sub.w	8(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_166E0
		addi.w	#$F,d0

loc_166E0:
		cmpi.w	#$10,d0
		bcc.b	locret_1675C
		move.w	$C(a1),d1
		sub.w	$C(a0),d1
		addi.w	#$20,d1
		cmpi.w	#$40,d1
		bcc.b	locret_1675C
		tst.b	($FFFFF7C8).w
		bne.b	locret_1675C
		cmpi.b	#7,userflag(a0)
		bne.b	loc_1670E
		cmpi.w	#50,plring
		bcs.b	locret_1675C

loc_1670E:
		addq.b	#2,r_no0(a0)
		move.b	#$81,($FFFFF7C8).w ; lock controls
		move.b	#2,$1C(a1)	; use Sonic's rolling animation
		move.w	#$800,$14(a1)
		move.w	#0,$10(a1)
		move.w	#0,$12(a1)
		bclr	#5,cddat(a0)
		bclr	#5,cddat(a1)
		bset	#1,cddat(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		clr.b	$32(a0)
		move.w	#$BE,d0
		jsr	(soundset).l ;	play Sonic rolling sound

locret_1675C:
		rts	
; ===========================================================================

loc_1675E:				; XREF: Obj72_Index
		lea	playerwk,a1
		move.b	$32(a0),d0
		addq.b	#2,$32(a0)
		jsr	(sinset).l
		asr.w	#5,d0
		move.w	$C(a0),d2
		sub.w	d0,d2
		move.w	d2,$C(a1)
		cmpi.b	#$80,$32(a0)
		bne.b	locret_16796
		bsr.w	sub_1681C
		addq.b	#2,r_no0(a0)
		move.w	#$BC,d0
		jsr	(soundset).l ;	play teleport sound

locret_16796:
		rts	
; ===========================================================================

loc_16798:				; XREF: Obj72_Index
		addq.l	#4,sp
		lea	playerwk,a1
		subq.b	#1,$2E(a0)
		bpl.b	loc_167DA
		move.w	$36(a0),8(a1)
		move.w	$38(a0),$C(a1)
		moveq	#0,d1
		move.b	$3A(a0),d1
		addq.b	#4,d1
		cmp.b	$3B(a0),d1
		bcs.b	loc_167C2
		moveq	#0,d1
		bra.b	loc_16800
; ===========================================================================

loc_167C2:
		move.b	d1,$3A(a0)
		movea.l	$3C(a0),a2
		move.w	(a2,d1.w),$36(a0)
		move.w	2(a2,d1.w),$38(a0)
		bra.w	sub_1681C
; ===========================================================================

loc_167DA:
		move.l	8(a1),d2
		move.l	$C(a1),d3
		move.w	$10(a1),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a1),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,8(a1)
		move.l	d3,$C(a1)
		rts	
; ===========================================================================

loc_16800:
		andi.w	#$7FF,$C(a1)
		clr.b	r_no0(a0)
		clr.b	($FFFFF7C8).w
		move.w	#0,$10(a1)
		move.w	#$200,$12(a1)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1681C:
		moveq	#0,d0
		move.w	#$1000,d2
		move.w	$36(a0),d0
		sub.w	8(a1),d0
		bge.b	loc_16830
		neg.w	d0
		neg.w	d2

loc_16830:
		moveq	#0,d1
		move.w	#$1000,d3
		move.w	$38(a0),d1
		sub.w	$C(a1),d1
		bge.b	loc_16844
		neg.w	d1
		neg.w	d3

loc_16844:
		cmp.w	d0,d1
		bcs.b	loc_1687A
		moveq	#0,d1
		move.w	$38(a0),d1
		sub.w	$C(a1),d1
		swap	d1
		divs.w	d3,d1
		moveq	#0,d0
		move.w	$36(a0),d0
		sub.w	8(a1),d0
		beq.b	loc_16866
		swap	d0
		divs.w	d1,d0

loc_16866:
		move.w	d0,$10(a1)
		move.w	d3,$12(a1)
		tst.w	d1
		bpl.b	loc_16874
		neg.w	d1

loc_16874:
		move.w	d1,$2E(a0)
		rts	
; ===========================================================================

loc_1687A:
		moveq	#0,d0
		move.w	$36(a0),d0
		sub.w	8(a1),d0
		swap	d0
		divs.w	d2,d0
		moveq	#0,d1
		move.w	$38(a0),d1
		sub.w	$C(a1),d1
		beq.b	loc_16898
		swap	d1
		divs.w	d0,d1

loc_16898:
		move.w	d1,$12(a1)
		move.w	d2,$10(a1)
		tst.w	d0
		bpl.b	loc_168A6
		neg.w	d0

loc_168A6:
		move.w	d0,$2E(a0)
		rts	
; End of function sub_1681C

; ===========================================================================
Obj72_Data:	dc.w word_168BC-Obj72_Data, word_168C2-Obj72_Data, word_168C8-Obj72_Data
		dc.w word_168E6-Obj72_Data, word_168EC-Obj72_Data, word_1690A-Obj72_Data
		dc.w word_16910-Obj72_Data, word_1692E-Obj72_Data
word_168BC:	dc.w 4,	$794, $98C
word_168C2:	dc.w 4,	$94, $38C
word_168C8:	dc.w $1C, $794,	$2E8
		dc.w $7A4, $2C0, $7D0
		dc.w $2AC, $858, $2AC
		dc.w $884, $298, $894
		dc.w $270, $894, $190
word_168E6:	dc.w 4,	$894, $690
word_168EC:	dc.w $1C, $1194, $470
		dc.w $1184, $498, $1158
		dc.w $4AC, $FD0, $4AC
		dc.w $FA4, $4C0, $F94
		dc.w $4E8, $F94, $590
word_1690A:	dc.w 4,	$1294, $490
word_16910:	dc.w $1C, $1594, $FFE8
		dc.w $1584, $FFC0, $1560
		dc.w $FFAC, $14D0, $FFAC
		dc.w $14A4, $FF98, $1494
		dc.w $FF70, $1494, $FD90
word_1692E:	dc.w 4,	$894, $90
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 78 - Caterkiller enemy	(MZ, SBZ)
; ---------------------------------------------------------------------------

imo:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	imo_Index(pc,d0.w),d1
		jmp	imo_Index(pc,d1.w)
; ===========================================================================
imo_Index:	dc.w imo_Main-imo_Index
		dc.w imo_Action-imo_Index
		dc.w imo_BodySeg1-imo_Index
		dc.w imo_BodySeg2-imo_Index
		dc.w imo_BodySeg1-imo_Index
		dc.w imo_Delete-imo_Index
		dc.w loc_16CC0-imo_Index
; ===========================================================================

locret_16950:
		rts	
; ===========================================================================

imo_Main:				; XREF: imo_Index
		move.b	#7,$16(a0)
		move.b	#8,$17(a0)
		jsr	speedset
		jsr	emycol_d
		tst.w	d1
		bpl.b	locret_16950
		add.w	d1,$C(a0)
		clr.w	$12(a0)
		addq.b	#2,r_no0(a0)
		move.l	#Map_imo,4(a0)
		move.w	#$22B0,2(a0)
		cmpi.b	#5,stageno ; if level is SBZ, branch
		beq.b	loc_16996
		move.w	#$24FF,2(a0)	; MZ specific code

loc_16996:
		andi.b	#3,1(a0)
		ori.b	#4,1(a0)
		move.b	1(a0),cddat(a0)
		move.b	#4,$18(a0)
		move.b	#8,$19(a0)
		move.b	#$B,colino(a0)
		move.w	8(a0),d2
		moveq	#$C,d5
		btst	#0,cddat(a0)
		beq.b	loc_169CA
		neg.w	d5

loc_169CA:
		move.b	#4,d6
		moveq	#0,d3
		moveq	#4,d4
		movea.l	a0,a2
		moveq	#2,d1

imo_LoadBody:
		jsr	actwkchk2
		bne.b	imo_QuitLoad
		move.b	#$78,0(a1)	; load body segment object
		move.b	d6,r_no0(a1)
		addq.b	#2,d6
		move.l	4(a0),4(a1)
		move.w	2(a0),2(a1)
		move.b	#5,$18(a1)
		move.b	#8,$19(a1)
		move.b	#$CB,colino(a1)
		add.w	d5,d2
		move.w	d2,8(a1)
		move.w	$C(a0),$C(a1)
		move.b	cddat(a0),cddat(a1)
		move.b	cddat(a0),1(a1)
		move.b	#8,$1A(a1)
		move.l	a2,$3C(a1)
		move.b	d4,$3C(a1)
		addq.b	#4,d4
		movea.l	a1,a2

imo_QuitLoad:
		dbra	d1,imo_LoadBody ; repeat sequence 2 more times

		move.b	#7,$2A(a0)
		clr.b	$3C(a0)

imo_Action:				; XREF: imo_Index
		tst.b	cddat(a0)
		bmi.w	loc_16C96
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	imo_Index2(pc,d0.w),d1
		jsr	imo_Index2(pc,d1.w)
		move.b	$2B(a0),d1
		bpl.b	imo_Display
		lea	(Ani_imo).l,a1
		move.b	direc(a0),d0
		andi.w	#$7F,d0
		addq.b	#4,direc(a0)
		move.b	(a1,d0.w),d0
		bpl.b	imo_AniHead
		bclr	#7,$2B(a0)
		bra.b	imo_Display
; ===========================================================================

imo_AniHead:
		andi.b	#$10,d1
		add.b	d1,d0
		move.b	d0,$1A(a0)

imo_Display:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.w	imo_ChkGone
		jmp	actionsub
; ===========================================================================

imo_ChkGone:
		lea	flagwork,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		beq.b	loc_16ABC
		bclr	#7,2(a2,d0.w)

loc_16ABC:
		move.b	#$A,r_no0(a0)	; run "imo_Delete" routine
		rts	
; ===========================================================================

imo_Delete:				; XREF: imo_Index
		jmp	frameout
; ===========================================================================
imo_Index2:	dc.w imo_Move-imo_Index2
		dc.w loc_16B02-imo_Index2
; ===========================================================================

imo_Move:				; XREF: imo_Index2
		subq.b	#1,$2A(a0)
		bmi.b	imo_Move2
		rts	
; ===========================================================================

imo_Move2:
		addq.b	#2,r_no1(a0)
		move.b	#$10,$2A(a0)
		move.w	#-$C0,$10(a0)
		move.w	#$40,$14(a0)
		bchg	#4,$2B(a0)
		bne.b	loc_16AFC
		clr.w	$10(a0)
		neg.w	$14(a0)

loc_16AFC:
		bset	#7,$2B(a0)

loc_16B02:				; XREF: imo_Index2
		subq.b	#1,$2A(a0)
		bmi.b	loc_16B5E
		move.l	8(a0),-(sp)
		move.l	8(a0),d2
		move.w	$10(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_16B1E
		neg.w	d0

loc_16B1E:
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.l	d2,8(a0)
		jsr	emycol_d
		move.l	(sp)+,d2
		cmpi.w	#-8,d1
		blt.b	loc_16B70
		cmpi.w	#$C,d1
		bge.b	loc_16B70
		add.w	d1,$C(a0)
		swap	d2
		cmp.w	8(a0),d2
		beq.b	locret_16B5C
		moveq	#0,d0
		move.b	$3C(a0),d0
		addq.b	#1,$3C(a0)
		andi.b	#$F,$3C(a0)
		move.b	d1,actfree(a0,d0.w)

locret_16B5C:
		rts	
; ===========================================================================

loc_16B5E:
		subq.b	#2,r_no1(a0)
		move.b	#7,$2A(a0)
		move.w	#0,$10(a0)
		rts	
; ===========================================================================

loc_16B70:
		move.l	d2,8(a0)
		bchg	#0,cddat(a0)
		move.b	cddat(a0),1(a0)
		moveq	#0,d0
		move.b	$3C(a0),d0
		move.b	#$80,actfree(a0,d0.w)
		addq.b	#1,$3C(a0)
		andi.b	#$F,$3C(a0)
		rts	
; ===========================================================================

imo_BodySeg2:				; XREF: imo_Index
		movea.l	$3C(a0),a1
		move.b	$2B(a1),$2B(a0)
		bpl.b	imo_BodySeg1
		lea	(Ani_imo).l,a1
		move.b	direc(a0),d0
		andi.w	#$7F,d0
		addq.b	#4,direc(a0)
		tst.b	4(a1,d0.w)
		bpl.b	imo_AniBody
		addq.b	#4,direc(a0)

imo_AniBody:
		move.b	(a1,d0.w),d0
		addq.b	#8,d0
		move.b	d0,$1A(a0)

imo_BodySeg1:				; XREF: imo_Index
		movea.l	$3C(a0),a1
		tst.b	cddat(a0)
		bmi.w	loc_16C90
		move.b	$2B(a1),$2B(a0)
		move.b	r_no1(a1),r_no1(a0)
		beq.w	loc_16C64
		move.w	$14(a1),$14(a0)
		move.w	$10(a1),d0
		add.w	$14(a1),d0
		move.w	d0,$10(a0)
		move.l	8(a0),d2
		move.l	d2,d3
		move.w	$10(a0),d0
		btst	#0,cddat(a0)
		beq.b	loc_16C0C
		neg.w	d0

loc_16C0C:
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.l	d2,8(a0)
		swap	d3
		cmp.w	8(a0),d3
		beq.b	loc_16C64
		moveq	#0,d0
		move.b	$3C(a0),d0
		move.b	actfree(a1,d0.w),d1
		cmpi.b	#-$80,d1
		bne.b	loc_16C50
		swap	d3
		move.l	d3,8(a0)
		move.b	d1,actfree(a0,d0.w)
		bchg	#0,cddat(a0)
		move.b	cddat(a0),1(a0)
		addq.b	#1,$3C(a0)
		andi.b	#$F,$3C(a0)
		bra.b	loc_16C64
; ===========================================================================

loc_16C50:
		ext.w	d1
		add.w	d1,$C(a0)
		addq.b	#1,$3C(a0)
		andi.b	#$F,$3C(a0)
		move.b	d1,actfree(a0,d0.w)

loc_16C64:
		cmpi.b	#$C,r_no0(a1)
		beq.b	loc_16C90
		cmpi.b	#$27,0(a1)
		beq.b	loc_16C7C
		cmpi.b	#$A,r_no0(a1)
		bne.b	loc_16C82

loc_16C7C:
		move.b	#$A,r_no0(a0)

loc_16C82:
		jmp	actionsub

; ===========================================================================
imo_FragSpeed:dc.w $FE00, $FE80, $180, $200
; ===========================================================================

loc_16C90:
		bset	#7,cddat(a1)

loc_16C96:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	imo_FragSpeed-2(pc,d0.w),d0
		btst	#0,cddat(a0)
		beq.b	loc_16CAA
		neg.w	d0

loc_16CAA:
		move.w	d0,$10(a0)
		move.w	#-$400,$12(a0)
		move.b	#$C,r_no0(a0)
		andi.b	#-8,$1A(a0)

loc_16CC0:				; XREF: imo_Index
		jsr	speedset
		tst.w	$12(a0)
		bmi.b	loc_16CE0
		jsr	emycol_d
		tst.w	d1
		bpl.b	loc_16CE0
		add.w	d1,$C(a0)
		move.w	#-$400,$12(a0)

loc_16CE0:
		tst.b	1(a0)
		bpl.w	imo_ChkGone
		jmp	actionsub
; ===========================================================================
Ani_imo:
	include "_anim\imo.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Caterkiller	enemy (MZ, SBZ)
; ---------------------------------------------------------------------------
Map_imo:
	include "_maps\imo.asm"

; ===========================================================================

		include	"SAVE.ASM"

bten:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	bten_move_tbl(pc,d0.w),d1
		jmp		bten_move_tbl(pc,d1.w)
bten_move_tbl:
		dc.w	bten_init-bten_move_tbl
		dc.w	bten_erase-bten_move_tbl
bten_init:
		moveq	#$10,d2
		move.w	d2,d3
		add.w	d3,d3
		lea	playerwk,a1
		move.w	xposi(a1),d0
		sub.w	xposi(a0),d0
		add.w	d2,d0
		cmp.w	d3,d0
		bcc.b	?jump
		move.w	yposi(a1),d1
		sub.w	yposi(a0),d1
		add.w	d2,d1
		cmp.w	d3,d1
		bcc.b	?jump
		tst.w	editmode
		bne.b	?jump
		tst.b	special_flag
		bne.b	?jump
		addq.b	#word,r_no0(a0)
		move.l	#btenpat,patbase(a0)
		move.w	#$84b6,sproffset(a0)
		ori.b	#4,actflg(a0)
		move.b	#0,sprpri(a0)
		move.b	#$10,sprhs(a0)
		move.b	userflag(a0),patno(a0)
		move.w	#119,$30(a0)
		move.w	#$c9,d0
		jsr		soundset
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		move.w	btentbl(pc,d0.w),d0
		jsr	scoreup

?jump:
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	bten_Delete
		rts

bten_Delete:
		jmp	frameout

btentbl:
		dc.w	0
		dc.w	1000
		dc.w	100
		dc.w	1

bten_erase:
		subq.w	#1,$30(a0)
		bmi.b	?jump
		move.w	xposi(a0),d0
		andi.w	#-$80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#-$80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	?jump
		jmp	actionsub
?jump:
		jmp	frameout

; ---------------------------------------------------------------------------
; Sprite mappings - hidden points at the end of	a level
; ---------------------------------------------------------------------------
btenpat:
	include "_maps\bten.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 8A - "SONIC TEAM PRESENTS" and	credits
; ---------------------------------------------------------------------------

staff:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	staff_Index(pc,d0.w),d1
		jmp	staff_Index(pc,d1.w)
; ===========================================================================
staff_Index:	dc.w staff_Main-staff_Index
		dc.w staff_Display-staff_Index
; ===========================================================================

staff_Main:				; XREF: staff_Index
		addq.b	#2,r_no0(a0)
		move.w	#$120,8(a0)
		move.w	#$F0,$A(a0)
		move.l	#Map_staff,4(a0)
		move.w	#$5A0,2(a0)
		move.w	($FFFFFFF4).w,d0 ; load	credits	index number
		move.b	d0,$1A(a0)	; display appropriate sprite
		move.b	#0,1(a0)
		move.b	#0,$18(a0)
		cmpi.b	#4,gmmode ; is the scene	number 04 (title screen)?
		bne.b	staff_Display	; if not, branch
		move.w	#$A6,2(a0)
		move.b	#$A,$1A(a0)	; display "SONIC TEAM PRESENTS"
		tst.b	($FFFFFFE3).w	; is hidden credits cheat on?
		beq.b	staff_Display	; if not, branch
		cmpi.b	#$72,swdata1+0 ; is	Start+A+C+Down being pressed?
		bne.b	staff_Display	; if not, branch
		move.w	#$EEE,($FFFFFBC0).w ; 3rd pallet, 1st entry = white
		move.w	#$880,($FFFFFBC2).w ; 3rd pallet, 2nd entry = cyan
		jmp	frameout
; ===========================================================================

staff_Display:				; XREF: staff_Index
		jmp	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - "SONIC TEAM	PRESENTS" and credits
; ---------------------------------------------------------------------------
Map_staff:
	include "_maps\staff.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3D - Eggman (GHZ)
; ---------------------------------------------------------------------------

boss1:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	boss1_Index(pc,d0.w),d1
		jmp	boss1_Index(pc,d1.w)
; ===========================================================================
boss1_Index:	dc.w boss1_Main-boss1_Index
		dc.w boss1_ShipMain-boss1_Index
		dc.w boss1_FaceMain-boss1_Index
		dc.w boss1_FlameMain-boss1_Index

boss1_ObjData:	dc.b 2,	0		; routine counter, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

boss1_Main:				; XREF: boss1_Index
		lea	(boss1_ObjData).l,a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.b	boss1_LoadBoss
; ===========================================================================

boss1_Loop:
		jsr	actwkchk2
		bne.b	loc_17772

boss1_LoadBoss:				; XREF: boss1_Main
		move.b	(a2)+,r_no0(a1)
		move.b	#$3D,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.b	#3,$18(a1)
		move.b	(a2)+,$1C(a1)
		move.l	a0,$34(a1)
		dbra	d1,boss1_Loop	; repeat sequence 2 more times

loc_17772:
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,colino(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8

boss1_ShipMain:				; XREF: boss1_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	boss1_ShipIndex(pc,d0.w),d1
		jsr	boss1_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		move.b	cddat(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
boss1_ShipIndex:dc.w boss1_ShipStart-boss1_ShipIndex
		dc.w boss1_MakeBall-boss1_ShipIndex
		dc.w boss1_ShipMove-boss1_ShipIndex
		dc.w loc_17954-boss1_ShipIndex
		dc.w loc_1797A-boss1_ShipIndex
		dc.w loc_179AC-boss1_ShipIndex
		dc.w loc_179F6-boss1_ShipIndex
; ===========================================================================

boss1_ShipStart:			; XREF: boss1_ShipIndex
		move.w	#$100,$12(a0)	; move ship down
		bsr.w	BossMove
		cmpi.w	#$338,$38(a0)
		bne.b	loc_177E6
		move.w	#0,$12(a0)	; stop ship
		addq.b	#2,r_no1(a0)	; goto next routine

loc_177E6:
		move.b	$3F(a0),d0
		jsr	(sinset).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)
		addq.b	#2,$3F(a0)
		cmpi.b	#8,r_no1(a0)
		bcc.b	locret_1784A
		tst.b	cddat(a0)
		bmi.b	loc_1784C
		tst.b	colino(a0)
		bne.b	locret_1784A
		tst.b	$3E(a0)
		bne.b	boss1_ShipFlash
		move.b	#$20,$3E(a0)	; set number of	times for ship to flash
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

boss1_ShipFlash:
		lea	($FFFFFB22).w,a1 ; load	2nd pallet, 2nd	entry
		moveq	#0,d0		; move 0 (black) to d0
		tst.w	(a1)
		bne.b	loc_1783C
		move.w	#$EEE,d0	; move 0EEE (white) to d0

loc_1783C:
		move.w	d0,(a1)		; load colour stored in	d0
		subq.b	#1,$3E(a0)
		bne.b	locret_1784A
		move.b	#$F,colino(a0)

locret_1784A:
		rts	
; ===========================================================================

loc_1784C:				; XREF: loc_177E6
		moveq	#100,d0
		bsr.w	scoreup
		move.b	#8,r_no1(a0)
		move.w	#$B3,$3C(a0)
		rts	

; ---------------------------------------------------------------------------
; Defeated boss	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossDefeated:
		move.b	systemtimer+3,d0
		andi.b	#7,d0
		bne.b	locret_178A2
		jsr	actwkchk
		bne.b	locret_178A2
		move.b	#$3F,0(a1)	; load explosion object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(random).l
		move.w	d0,d1
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

locret_178A2:
		rts	
; End of function BossDefeated

; ---------------------------------------------------------------------------
; Subroutine to	move a boss
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


BossMove:
		move.l	$30(a0),d2
		move.l	$38(a0),d3
		move.w	$10(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d2
		move.w	$12(a0),d0
		ext.l	d0
		asl.l	#8,d0
		add.l	d0,d3
		move.l	d2,$30(a0)
		move.l	d3,$38(a0)
		rts	
; End of function BossMove

; ===========================================================================

boss1_MakeBall:				; XREF: boss1_ShipIndex
		move.w	#-$100,$10(a0)
		move.w	#-$40,$12(a0)
		bsr.w	BossMove
		cmpi.w	#$2A00,$30(a0)
		bne.b	loc_17916
		move.w	#0,$10(a0)
		move.w	#0,$12(a0)
		addq.b	#2,r_no1(a0)
		jsr	actwkchk2
		bne.b	loc_17910
		move.b	#$48,0(a1)	; load swinging	ball object
		move.w	$30(a0),8(a1)
		move.w	$38(a0),$C(a1)
		move.l	a0,$34(a1)

loc_17910:
		move.w	#$77,$3C(a0)

loc_17916:
		bra.w	loc_177E6
; ===========================================================================

boss1_ShipMove:				; XREF: boss1_ShipIndex
		subq.w	#1,$3C(a0)
		bpl.b	boss1_Reverse
		addq.b	#2,r_no1(a0)
		move.w	#$3F,$3C(a0)
		move.w	#$100,$10(a0)	; move the ship	sideways
		cmpi.w	#$2A00,$30(a0)
		bne.b	boss1_Reverse
		move.w	#$7F,$3C(a0)
		move.w	#$40,$10(a0)

boss1_Reverse:
		btst	#0,cddat(a0)
		bne.b	loc_17950
		neg.w	$10(a0)		; reverse direction of the ship

loc_17950:
		bra.w	loc_177E6
; ===========================================================================

loc_17954:				; XREF: boss1_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.b	loc_17960
		bsr.w	BossMove
		bra.b	loc_17976
; ===========================================================================

loc_17960:
		bchg	#0,cddat(a0)
		move.w	#$3F,$3C(a0)
		subq.b	#2,r_no1(a0)
		move.w	#0,$10(a0)

loc_17976:
		bra.w	loc_177E6
; ===========================================================================

loc_1797A:				; XREF: boss1_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.b	loc_17984
		bra.w	BossDefeated
; ===========================================================================

loc_17984:
		bset	#0,cddat(a0)
		bclr	#7,cddat(a0)
		clr.w	$10(a0)
		addq.b	#2,r_no1(a0)
		move.w	#-$26,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.b	locret_179AA
		move.b	#1,($FFFFF7A7).w

locret_179AA:
		rts	
; ===========================================================================

loc_179AC:				; XREF: boss1_ShipIndex
		addq.w	#1,$3C(a0)
		beq.b	loc_179BC
		bpl.b	loc_179C2
		addi.w	#$18,$12(a0)
		bra.b	loc_179EE
; ===========================================================================

loc_179BC:
		clr.w	$12(a0)
		bra.b	loc_179EE
; ===========================================================================

loc_179C2:
		cmpi.w	#$30,$3C(a0)
		bcs.b	loc_179DA
		beq.b	loc_179E0
		cmpi.w	#$38,$3C(a0)
		bcs.b	loc_179EE
		addq.b	#2,r_no1(a0)
		bra.b	loc_179EE
; ===========================================================================

loc_179DA:
		subq.w	#8,$12(a0)
		bra.b	loc_179EE
; ===========================================================================

loc_179E0:
		clr.w	$12(a0)
		move.w	#$81,d0
		jsr	(bgmset).l	; play GHZ music

loc_179EE:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

loc_179F6:				; XREF: boss1_ShipIndex
		move.w	#$400,$10(a0)
		move.w	#-$40,$12(a0)
		cmpi.w	#$2AC0,scralim_right
		beq.b	loc_17A10
		addq.w	#2,scralim_right
		bra.b	loc_17A16
; ===========================================================================

loc_17A10:
		tst.b	1(a0)
		bpl.b	boss1_ShipDel

loc_17A16:
		bsr.w	BossMove
		bra.w	loc_177E6
; ===========================================================================

boss1_ShipDel:
		jmp	frameout
; ===========================================================================

boss1_FaceMain:				; XREF: boss1_Index
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	r_no1(a1),d0
		subq.b	#4,d0
		bne.b	loc_17A3E
		cmpi.w	#$2A00,$30(a1)
		bne.b	loc_17A46
		moveq	#4,d1

loc_17A3E:
		subq.b	#6,d0
		bmi.b	loc_17A46
		moveq	#$A,d1
		bra.b	loc_17A5A
; ===========================================================================

loc_17A46:
		tst.b	colino(a1)
		bne.b	loc_17A50
		moveq	#5,d1
		bra.b	loc_17A5A
; ===========================================================================

loc_17A50:
		cmpi.b	#4,($FFFFD024).w
		bcs.b	loc_17A5A
		moveq	#4,d1

loc_17A5A:
		move.b	d1,$1C(a0)
		subq.b	#2,d0
		bne.b	boss1_FaceDisp
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.b	boss1_FaceDel

boss1_FaceDisp:
		bra.b	boss1_Display
; ===========================================================================

boss1_FaceDel:
		jmp	frameout
; ===========================================================================

boss1_FlameMain:			; XREF: boss1_Index
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,r_no1(a1)
		bne.b	loc_17A96
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.b	boss1_FlameDel
		bra.b	boss1_FlameDisp
; ===========================================================================

loc_17A96:
		move.w	$10(a1),d0
		beq.b	boss1_FlameDisp
		move.b	#8,$1C(a0)

boss1_FlameDisp:
		bra.b	boss1_Display
; ===========================================================================

boss1_FlameDel:
		jmp	frameout
; ===========================================================================

boss1_Display:				; XREF: boss1_FaceDisp; boss1_FlameDisp
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	cddat(a1),cddat(a0)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		move.b	cddat(a0),d0
		andi.b	#3,d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 48 - ball on a	chain that Eggman swings (GHZ)
; ---------------------------------------------------------------------------

btama:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	btama_Index(pc,d0.w),d1
		jmp	btama_Index(pc,d1.w)
; ===========================================================================
btama_Index:	dc.w btama_Main-btama_Index
		dc.w btama_Base-btama_Index
		dc.w btama_Display2-btama_Index
		dc.w loc_17C68-btama_Index
		dc.w btama_ChkVanish-btama_Index
; ===========================================================================

btama_Main:				; XREF: btama_Index
		addq.b	#2,r_no0(a0)
		move.w	#$4080,direc(a0)
		move.w	#-$200,$3E(a0)
		move.l	#Map_BossItems,4(a0)
		move.w	#$46C,2(a0)
		lea	userflag(a0),a2
		move.b	#0,(a2)+
		moveq	#5,d1
		movea.l	a0,a1
		bra.b	loc_17B60
; ===========================================================================

btama_MakeLinks:
		jsr	actwkchk2
		bne.b	btama_MakeBall
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#$48,0(a1)	; load chain link object
		move.b	#6,r_no0(a1)
		move.l	#Map_buranko,4(a1)
		move.w	#$380,2(a1)
		move.b	#1,$1A(a1)
		addq.b	#1,userflag(a0)

loc_17B60:				; XREF: btama_Main
		move.w	a1,d5
		subi.w	#$D000,d5
		lsr.w	#6,d5
		andi.w	#$7F,d5
		move.b	d5,(a2)+
		move.b	#4,1(a1)
		move.b	#8,$19(a1)
		move.b	#6,$18(a1)
		move.l	$34(a0),$34(a1)
		dbra	d1,btama_MakeLinks ; repeat sequence 5 more times

btama_MakeBall:
		move.b	#8,r_no0(a1)
		move.l	#Map_btama,4(a1) ; load	different mappings for final link
		move.w	#$43AA,2(a1)	; use different	graphics
		move.b	#1,$1A(a1)
		move.b	#5,$18(a1)
		move.b	#$81,colino(a1)	; make object hurt Sonic
		rts	
; ===========================================================================

btama_PosData:	dc.b 0,	$10, $20, $30, $40, $60	; y-position data for links and	giant ball

; ===========================================================================

btama_Base:				; XREF: btama_Index
		lea	(btama_PosData).l,a3
		lea	userflag(a0),a2
		moveq	#0,d6
		move.b	(a2)+,d6

loc_17BC6:
		moveq	#0,d4
		move.b	(a2)+,d4
		lsl.w	#6,d4
		addi.l	#$FFD000,d4
		movea.l	d4,a1
		move.b	(a3)+,d0
		cmp.b	$3C(a1),d0
		beq.b	loc_17BE0
		addq.b	#1,$3C(a1)

loc_17BE0:
		dbra	d6,loc_17BC6

		cmp.b	$3C(a1),d0
		bne.b	loc_17BFA
		movea.l	$34(a0),a1
		cmpi.b	#6,r_no1(a1)
		bne.b	loc_17BFA
		addq.b	#2,r_no0(a0)

loc_17BFA:
		cmpi.w	#$20,$32(a0)
		beq.b	btama_Display
		addq.w	#1,$32(a0)

btama_Display:
		bsr.w	sub_17C2A
		move.b	direc(a0),d0
		jsr	(buranko_Move2).l
		jmp	actionsub
; ===========================================================================

btama_Display2:				; XREF: btama_Index
		bsr.w	sub_17C2A
		jsr	(btama_Move).l
		jmp	actionsub

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_17C2A:				; XREF: btama_Display; btama_Display2
		movea.l	$34(a0),a1
		addi.b	#$20,$1B(a0)
		bcc.b	loc_17C3C
		bchg	#0,$1A(a0)

loc_17C3C:
		move.w	8(a1),$3A(a0)
		move.w	$C(a1),d0
		add.w	$32(a0),d0
		move.w	d0,$38(a0)
		move.b	cddat(a1),cddat(a0)
		tst.b	cddat(a1)
		bpl.b	locret_17C66
		move.b	#$3F,actno(a0)
		move.b	#0,r_no0(a0)

locret_17C66:
		rts	
; End of function sub_17C2A

; ===========================================================================

loc_17C68:				; XREF: btama_Index
		movea.l	$34(a0),a1
		tst.b	cddat(a1)
		bpl.b	btama_Display3
		move.b	#$3F,actno(a0)
		move.b	#0,r_no0(a0)

btama_Display3:
		jmp	actionsub
; ===========================================================================

btama_ChkVanish:			; XREF: btama_Index
		moveq	#0,d0
		tst.b	$1A(a0)
		bne.b	btama_Vanish
		addq.b	#1,d0

btama_Vanish:
		move.b	d0,$1A(a0)
		movea.l	$34(a0),a1
		tst.b	cddat(a1)
		bpl.b	btama_Display4
		move.b	#0,colino(a0)
		bsr.w	BossDefeated
		subq.b	#1,$3C(a0)
		bpl.b	btama_Display4
		move.b	#$3F,(a0)
		move.b	#0,r_no0(a0)

btama_Display4:
		jmp	actionsub
; ===========================================================================
Ani_Eggman:
	include "_anim\Eggman.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Eggman (boss levels)
; ---------------------------------------------------------------------------
Map_Eggman:
	include "_maps\Eggman.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - extra boss items (e.g. swinging ball on a chain in GHZ)
; ---------------------------------------------------------------------------
Map_BossItems:
	include "_maps\Boss items.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 77 - Eggman (LZ)
; ---------------------------------------------------------------------------

Obj77:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj77_Index(pc,d0.w),d1
		jmp	Obj77_Index(pc,d1.w)
; ===========================================================================
Obj77_Index:	dc.w Obj77_Main-Obj77_Index
		dc.w Obj77_ShipMain-Obj77_Index
		dc.w Obj77_FaceMain-Obj77_Index
		dc.w Obj77_FlameMain-Obj77_Index

Obj77_ObjData:	dc.b 2,	0		; routine number, animation
		dc.b 4,	1
		dc.b 6,	7
; ===========================================================================

Obj77_Main:				; XREF: Obj77_Index
		move.w	#$1E10,8(a0)
		move.w	#$5C0,$C(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,colino(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8
		move.b	#4,$18(a0)
		lea	Obj77_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#2,d1
		bra.b	Obj77_LoadBoss
; ===========================================================================

Obj77_Loop:
		jsr	actwkchk2
		bne.b	Obj77_ShipMain
		move.b	#$77,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Obj77_LoadBoss:				; XREF: Obj77_Main
		bclr	#0,cddat(a0)
		clr.b	r_no1(a1)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1C(a1)
		move.b	$18(a0),$18(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.l	a0,$34(a1)
		dbra	d1,Obj77_Loop

Obj77_ShipMain:
		lea	playerwk,a1
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj77_ShipIndex(pc,d0.w),d1
		jsr	Obj77_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
Obj77_ShipIndex:dc.w loc_17F1E-Obj77_ShipIndex,	loc_17FA0-Obj77_ShipIndex
		dc.w loc_17FE0-Obj77_ShipIndex,	loc_1801E-Obj77_ShipIndex
		dc.w loc_180BC-Obj77_ShipIndex,	loc_180F6-Obj77_ShipIndex
		dc.w loc_1812A-Obj77_ShipIndex,	loc_18152-Obj77_ShipIndex
; ===========================================================================

loc_17F1E:				; XREF: Obj77_ShipIndex
		move.w	8(a1),d0
		cmpi.w	#$1DA0,d0
		bcs.b	loc_17F38
		move.w	#-$180,$12(a0)
		move.w	#$60,$10(a0)
		addq.b	#2,r_no1(a0)

loc_17F38:
		bsr.w	BossMove
		move.w	$38(a0),$C(a0)
		move.w	$30(a0),8(a0)

loc_17F48:
		tst.b	$3D(a0)
		bne.b	loc_17F8E
		tst.b	cddat(a0)
		bmi.b	loc_17F92
		tst.b	colino(a0)
		bne.b	locret_17F8C
		tst.b	$3E(a0)
		bne.b	loc_17F70
		move.b	#$20,$3E(a0)
		move.w	#$AC,d0
		jsr	(soundset).l

loc_17F70:
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.b	loc_17F7E
		move.w	#$EEE,d0

loc_17F7E:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.b	locret_17F8C
		move.b	#$F,colino(a0)

locret_17F8C:
		rts	
; ===========================================================================

loc_17F8E:				; XREF: loc_17F48
		bra.w	BossDefeated
; ===========================================================================

loc_17F92:				; XREF: loc_17F48
		moveq	#100,d0
		bsr.w	scoreup
		move.b	#-1,$3D(a0)
		rts	
; ===========================================================================

loc_17FA0:				; XREF: Obj77_ShipIndex
		moveq	#-2,d0
		cmpi.w	#$1E48,$30(a0)
		bcs.b	loc_17FB6
		move.w	#$1E48,$30(a0)
		clr.w	$10(a0)
		addq.w	#1,d0

loc_17FB6:
		cmpi.w	#$500,$38(a0)
		bgt.b	loc_17FCA
		move.w	#$500,$38(a0)
		clr.w	$12(a0)
		addq.w	#1,d0

loc_17FCA:
		bne.b	loc_17FDC
		move.w	#$140,$10(a0)
		move.w	#-$200,$12(a0)
		addq.b	#2,r_no1(a0)

loc_17FDC:
		bra.w	loc_17F38
; ===========================================================================

loc_17FE0:				; XREF: Obj77_ShipIndex
		moveq	#-2,d0
		cmpi.w	#$1E70,$30(a0)
		bcs.b	loc_17FF6
		move.w	#$1E70,$30(a0)
		clr.w	$10(a0)
		addq.w	#1,d0

loc_17FF6:
		cmpi.w	#$4C0,$38(a0)
		bgt.b	loc_1800A
		move.w	#$4C0,$38(a0)
		clr.w	$12(a0)
		addq.w	#1,d0

loc_1800A:
		bne.b	loc_1801A
		move.w	#-$180,$12(a0)
		addq.b	#2,r_no1(a0)
		clr.b	$3F(a0)

loc_1801A:
		bra.w	loc_17F38
; ===========================================================================

loc_1801E:				; XREF: Obj77_ShipIndex
		cmpi.w	#$100,$38(a0)
		bgt.b	loc_1804E
		move.w	#$100,$38(a0)
		move.w	#$140,$10(a0)
		move.w	#-$80,$12(a0)
		tst.b	$3D(a0)
		beq.b	loc_18046
		asl	$10(a0)
		asl	$12(a0)

loc_18046:
		addq.b	#2,r_no1(a0)
		bra.w	loc_17F38
; ===========================================================================

loc_1804E:
		bset	#0,cddat(a0)
		addq.b	#2,$3F(a0)
		move.b	$3F(a0),d0
		jsr	(sinset).l
		tst.w	d1
		bpl.b	loc_1806C
		bclr	#0,cddat(a0)

loc_1806C:
		asr.w	#4,d0
		swap	d0
		clr.w	d0
		add.l	$30(a0),d0
		swap	d0
		move.w	d0,8(a0)
		move.w	$12(a0),d0
		move.w	playerwk+yposi,d1
		sub.w	$C(a0),d1
		bcs.b	loc_180A2
		subi.w	#$48,d1
		bcs.b	loc_180A2
		asr.w	#1,d0
		subi.w	#$28,d1
		bcs.b	loc_180A2
		asr.w	#1,d0
		subi.w	#$28,d1
		bcs.b	loc_180A2
		moveq	#0,d0

loc_180A2:
		ext.l	d0
		asl.l	#8,d0
		tst.b	$3D(a0)
		beq.b	loc_180AE
		add.l	d0,d0

loc_180AE:
		add.l	d0,$38(a0)
		move.w	$38(a0),$C(a0)
		bra.w	loc_17F48
; ===========================================================================

loc_180BC:				; XREF: Obj77_ShipIndex
		moveq	#-2,d0
		cmpi.w	#$1F4C,$30(a0)
		bcs.b	loc_180D2
		move.w	#$1F4C,$30(a0)
		clr.w	$10(a0)
		addq.w	#1,d0

loc_180D2:
		cmpi.w	#$C0,$38(a0)
		bgt.b	loc_180E6
		move.w	#$C0,$38(a0)
		clr.w	$12(a0)
		addq.w	#1,d0

loc_180E6:
		bne.b	loc_180F2
		addq.b	#2,r_no1(a0)
		bclr	#0,cddat(a0)

loc_180F2:
		bra.w	loc_17F38
; ===========================================================================

loc_180F6:				; XREF: Obj77_ShipIndex
		tst.b	$3D(a0)
		bne.b	loc_18112
		cmpi.w	#$1EC8,8(a1)
		blt.b	loc_18126
		cmpi.w	#$F0,$C(a1)
		bgt.b	loc_18126
		move.b	#$32,$3C(a0)

loc_18112:
		move.w	#$82,d0
		jsr	(bgmset).l	; play LZ music
		bset	#0,cddat(a0)
		addq.b	#2,r_no1(a0)

loc_18126:
		bra.w	loc_17F38
; ===========================================================================

loc_1812A:				; XREF: Obj77_ShipIndex
		tst.b	$3D(a0)
		bne.b	loc_18136
		subq.b	#1,$3C(a0)
		bne.b	loc_1814E

loc_18136:
		clr.b	$3C(a0)
		move.w	#$400,$10(a0)
		move.w	#-$40,$12(a0)
		clr.b	$3D(a0)
		addq.b	#2,r_no1(a0)

loc_1814E:
		bra.w	loc_17F38
; ===========================================================================

loc_18152:				; XREF: Obj77_ShipIndex
		cmpi.w	#$2030,scralim_right
		bcc.b	loc_18160
		addq.w	#2,scralim_right
		bra.b	loc_18166
; ===========================================================================

loc_18160:
		tst.b	1(a0)
		bpl.b	Obj77_ShipDel

loc_18166:
		bra.w	loc_17F38
; ===========================================================================

Obj77_ShipDel:
		jmp	frameout
; ===========================================================================

Obj77_FaceMain:				; XREF: Obj77_Index
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.b	Obj77_FaceDel
		moveq	#0,d0
		move.b	r_no1(a1),d0
		moveq	#1,d1
		tst.b	$3D(a0)
		beq.b	loc_1818C
		moveq	#$A,d1
		bra.b	loc_181A0
; ===========================================================================

loc_1818C:
		tst.b	colino(a1)
		bne.b	loc_18196
		moveq	#5,d1
		bra.b	loc_181A0
; ===========================================================================

loc_18196:
		cmpi.b	#4,($FFFFD024).w
		bcs.b	loc_181A0
		moveq	#4,d1

loc_181A0:
		move.b	d1,$1C(a0)
		cmpi.b	#$E,d0
		bne.b	loc_181B6
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.b	Obj77_FaceDel

loc_181B6:
		bra.b	Obj77_Display
; ===========================================================================

Obj77_FaceDel:
		jmp	frameout
; ===========================================================================

Obj77_FlameMain:			; XREF: Obj77_Index
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.b	Obj77_FlameDel
		cmpi.b	#$E,r_no1(a1)
		bne.b	loc_181F0
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.b	Obj77_FlameDel
		bra.b	loc_181F0
; ===========================================================================
		tst.w	$10(a1)
		beq.b	loc_181F0
		move.b	#8,$1C(a0)

loc_181F0:
		bra.b	Obj77_Display
; ===========================================================================

Obj77_FlameDel:				; XREF: Obj77_FlameMain
		jmp	frameout
; ===========================================================================

Obj77_Display:
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	cddat(a1),cddat(a0)
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#-4,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 73 - Eggman (MZ)
; ---------------------------------------------------------------------------

Obj73:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj73_Index(pc,d0.w),d1
		jmp	Obj73_Index(pc,d1.w)
; ===========================================================================
Obj73_Index:	dc.w Obj73_Main-Obj73_Index
		dc.w Obj73_ShipMain-Obj73_Index
		dc.w Obj73_FaceMain-Obj73_Index
		dc.w Obj73_FlameMain-Obj73_Index
		dc.w Obj73_TubeMain-Obj73_Index

Obj73_ObjData:	dc.b 2,	0, 4		; routine number, animation, priority
		dc.b 4,	1, 4
		dc.b 6,	7, 4
		dc.b 8,	0, 3
; ===========================================================================

Obj73_Main:				; XREF: Obj73_Index
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,colino(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8
		lea	Obj73_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	Obj73_LoadBoss
; ===========================================================================

Obj73_Loop:
		jsr	actwkchk2
		bne.b	Obj73_ShipMain
		move.b	#$73,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Obj73_LoadBoss:				; XREF: Obj73_Main
		bclr	#0,cddat(a0)
		clr.b	r_no1(a1)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1C(a1)
		move.b	(a2)+,$18(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.l	a0,$34(a1)
		dbra	d1,Obj73_Loop	; repeat sequence 3 more times

Obj73_ShipMain:
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj73_ShipIndex(pc,d0.w),d1
		jsr	Obj73_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
Obj73_ShipIndex:dc.w loc_18302-Obj73_ShipIndex
		dc.w loc_183AA-Obj73_ShipIndex
		dc.w loc_184F6-Obj73_ShipIndex
		dc.w loc_1852C-Obj73_ShipIndex
		dc.w loc_18582-Obj73_ShipIndex
; ===========================================================================

loc_18302:				; XREF: Obj73_ShipIndex
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(sinset).l
		asr.w	#2,d0
		move.w	d0,$12(a0)
		move.w	#-$100,$10(a0)
		bsr.w	BossMove
		cmpi.w	#$1910,$30(a0)
		bne.b	loc_18334
		addq.b	#2,r_no1(a0)
		clr.b	userflag(a0)
		clr.l	$10(a0)

loc_18334:
		jsr	(random).l
		move.b	d0,$34(a0)

loc_1833E:
		move.w	$38(a0),$C(a0)
		move.w	$30(a0),8(a0)
		cmpi.b	#4,r_no1(a0)
		bcc.b	locret_18390
		tst.b	cddat(a0)
		bmi.b	loc_18392
		tst.b	colino(a0)
		bne.b	locret_18390
		tst.b	$3E(a0)
		bne.b	loc_18374
		move.b	#$28,$3E(a0)
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

loc_18374:
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.b	loc_18382
		move.w	#$EEE,d0

loc_18382:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.b	locret_18390
		move.b	#$F,colino(a0)

locret_18390:
		rts	
; ===========================================================================

loc_18392:				; XREF: loc_1833E
		moveq	#100,d0
		bsr.w	scoreup
		move.b	#4,r_no1(a0)
		move.w	#$B4,$3C(a0)
		clr.w	$10(a0)
		rts	
; ===========================================================================

loc_183AA:				; XREF: Obj73_ShipIndex
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.w	off_183C2(pc,d0.w),d0
		jsr	off_183C2(pc,d0.w)
		andi.b	#6,userflag(a0)
		bra.w	loc_1833E
; ===========================================================================
off_183C2:	dc.w loc_183CA-off_183C2
		dc.w Obj73_MakeLava2-off_183C2
		dc.w loc_183CA-off_183C2
		dc.w Obj73_MakeLava2-off_183C2
; ===========================================================================

loc_183CA:				; XREF: off_183C2
		tst.w	$10(a0)
		bne.b	loc_183FE
		moveq	#$40,d0
		cmpi.w	#$22C,$38(a0)
		beq.b	loc_183E6
		bcs.b	loc_183DE
		neg.w	d0

loc_183DE:
		move.w	d0,$12(a0)
		bra.w	BossMove
; ===========================================================================

loc_183E6:
		move.w	#$200,$10(a0)
		move.w	#$100,$12(a0)
		btst	#0,cddat(a0)
		bne.b	loc_183FE
		neg.w	$10(a0)

loc_183FE:
		cmpi.b	#$18,$3E(a0)
		bcc.b	Obj73_MakeLava
		bsr.w	BossMove
		subq.w	#4,$12(a0)

Obj73_MakeLava:
		subq.b	#1,$34(a0)
		bcc.b	loc_1845C
		jsr	actwkchk
		bne.b	loc_1844A
		move.b	#$14,0(a1)	; load lava ball object
		move.w	#$2E8,$C(a1)	; set Y	position
		jsr	(random).l
		andi.l	#$FFFF,d0
		divu.w	#$50,d0
		swap	d0
		addi.w	#$1878,d0
		move.w	d0,8(a1)
		lsr.b	#7,d1
		move.w	#$FF,userflag(a1)

loc_1844A:
		jsr	(random).l
		andi.b	#$1F,d0
		addi.b	#$40,d0
		move.b	d0,$34(a0)

loc_1845C:
		btst	#0,cddat(a0)
		beq.b	loc_18474
		cmpi.w	#$1910,$30(a0)
		blt.b	locret_1849C
		move.w	#$1910,$30(a0)
		bra.b	loc_18482
; ===========================================================================

loc_18474:
		cmpi.w	#$1830,$30(a0)
		bgt.b	locret_1849C
		move.w	#$1830,$30(a0)

loc_18482:
		clr.w	$10(a0)
		move.w	#-$180,$12(a0)
		cmpi.w	#$22C,$38(a0)
		bcc.b	loc_18498
		neg.w	$12(a0)

loc_18498:
		addq.b	#2,userflag(a0)

locret_1849C:
		rts	
; ===========================================================================

Obj73_MakeLava2:			; XREF: off_183C2
		bsr.w	BossMove
		move.w	$38(a0),d0
		subi.w	#$22C,d0
		bgt.b	locret_184F4
		move.w	#$22C,d0
		tst.w	$12(a0)
		beq.b	loc_184EA
		clr.w	$12(a0)
		move.w	#$50,$3C(a0)
		bchg	#0,cddat(a0)
		jsr	actwkchk
		bne.b	loc_184EA
		move.w	$30(a0),8(a1)
		move.w	$38(a0),$C(a1)
		addi.w	#$18,$C(a1)
		move.b	#$74,(a1)	; load lava ball object
		move.b	#1,userflag(a1)

loc_184EA:
		subq.w	#1,$3C(a0)
		bne.b	locret_184F4
		addq.b	#2,userflag(a0)

locret_184F4:
		rts	
; ===========================================================================

loc_184F6:				; XREF: Obj73_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.b	loc_18500
		bra.w	BossDefeated
; ===========================================================================

loc_18500:
		bset	#0,cddat(a0)
		bclr	#7,cddat(a0)
		clr.w	$10(a0)
		addq.b	#2,r_no1(a0)
		move.w	#-$26,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.b	locret_1852A
		move.b	#1,($FFFFF7A7).w
		clr.w	$12(a0)

locret_1852A:
		rts	
; ===========================================================================

loc_1852C:				; XREF: Obj73_ShipIndex
		addq.w	#1,$3C(a0)
		beq.b	loc_18544
		bpl.b	loc_1854E
		cmpi.w	#$270,$38(a0)
		bcc.b	loc_18544
		addi.w	#$18,$12(a0)
		bra.b	loc_1857A
; ===========================================================================

loc_18544:
		clr.w	$12(a0)
		clr.w	$3C(a0)
		bra.b	loc_1857A
; ===========================================================================

loc_1854E:
		cmpi.w	#$30,$3C(a0)
		bcs.b	loc_18566
		beq.b	loc_1856C
		cmpi.w	#$38,$3C(a0)
		bcs.b	loc_1857A
		addq.b	#2,r_no1(a0)
		bra.b	loc_1857A
; ===========================================================================

loc_18566:
		subq.w	#8,$12(a0)
		bra.b	loc_1857A
; ===========================================================================

loc_1856C:
		clr.w	$12(a0)
		move.w	#$83,d0
		jsr	(bgmset).l	; play MZ music

loc_1857A:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

loc_18582:				; XREF: Obj73_ShipIndex
		move.w	#$500,$10(a0)
		move.w	#-$40,$12(a0)
		cmpi.w	#$1960,scralim_right
		bcc.b	loc_1859C
		addq.w	#2,scralim_right
		bra.b	loc_185A2
; ===========================================================================

loc_1859C:
		tst.b	1(a0)
		bpl.b	Obj73_ShipDel

loc_185A2:
		bsr.w	BossMove
		bra.w	loc_1833E
; ===========================================================================

Obj73_ShipDel:
		jmp	frameout
; ===========================================================================

Obj73_FaceMain:				; XREF: Obj73_Index
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	r_no1(a1),d0
		subq.w	#2,d0
		bne.b	loc_185D2
		btst	#1,userflag(a1)
		beq.b	loc_185DA
		tst.w	$12(a1)
		bne.b	loc_185DA
		moveq	#4,d1
		bra.b	loc_185EE
; ===========================================================================

loc_185D2:
		subq.b	#2,d0
		bmi.b	loc_185DA
		moveq	#$A,d1
		bra.b	loc_185EE
; ===========================================================================

loc_185DA:
		tst.b	colino(a1)
		bne.b	loc_185E4
		moveq	#5,d1
		bra.b	loc_185EE
; ===========================================================================

loc_185E4:
		cmpi.b	#4,($FFFFD024).w
		bcs.b	loc_185EE
		moveq	#4,d1

loc_185EE:
		move.b	d1,$1C(a0)
		subq.b	#4,d0
		bne.b	loc_18602
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.b	Obj73_FaceDel

loc_18602:
		bra.b	Obj73_Display
; ===========================================================================

Obj73_FaceDel:
		jmp	frameout
; ===========================================================================

Obj73_FlameMain:			; XREF: Obj73_Index
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#8,r_no1(a1)
		blt.b	loc_1862A
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.b	Obj73_FlameDel
		bra.b	loc_18636
; ===========================================================================

loc_1862A:
		tst.w	$10(a1)
		beq.b	loc_18636
		move.b	#8,$1C(a0)

loc_18636:
		bra.b	Obj73_Display
; ===========================================================================

Obj73_FlameDel:				; XREF: Obj73_FlameMain
		jmp	frameout
; ===========================================================================

Obj73_Display:
		lea	(Ani_Eggman).l,a1
		jsr	patchg

loc_1864A:
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	cddat(a1),cddat(a0)
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#-4,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================

Obj73_TubeMain:				; XREF: Obj73_Index
		movea.l	$34(a0),a1
		cmpi.b	#8,r_no1(a1)
		bne.b	loc_18688
		tst.b	1(a0)
		bpl.b	Obj73_TubeDel

loc_18688:
		move.l	#Map_BossItems,4(a0)
		move.w	#$246C,2(a0)
		move.b	#4,$1A(a0)
		bra.b	loc_1864A
; ===========================================================================

Obj73_TubeDel:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 74 - lava that	Eggman drops (MZ)
; ---------------------------------------------------------------------------

Obj74:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj74_Index(pc,d0.w),d0
		jsr	Obj74_Index(pc,d0.w)
		jmp	actionsub
; ===========================================================================
Obj74_Index:	dc.w Obj74_Main-Obj74_Index
		dc.w Obj74_Action-Obj74_Index
		dc.w loc_18886-Obj74_Index
		dc.w Obj74_Delete3-Obj74_Index
; ===========================================================================

Obj74_Main:				; XREF: Obj74_Index
		move.b	#8,$16(a0)
		move.b	#8,$17(a0)
		move.l	#Map_fire,4(a0)
		move.w	#$345,2(a0)
		move.b	#4,1(a0)
		move.b	#5,$18(a0)
		move.w	$C(a0),$38(a0)
		move.b	#8,$19(a0)
		addq.b	#2,r_no0(a0)
		tst.b	userflag(a0)
		bne.b	loc_1870A
		move.b	#$8B,colino(a0)
		addq.b	#2,r_no0(a0)
		bra.w	loc_18886
; ===========================================================================

loc_1870A:
		move.b	#$1E,$29(a0)
		move.w	#$AE,d0
		jsr	(soundset).l ;	play lava sound

Obj74_Action:				; XREF: Obj74_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj74_Index2(pc,d0.w),d0
		jsr	Obj74_Index2(pc,d0.w)
		jsr	speedset2
		lea	(Ani_fire).l,a1
		jsr	patchg
		cmpi.w	#$2E8,$C(a0)
		bhi.b	Obj74_Delete
		rts	
; ===========================================================================

Obj74_Delete:
		jmp	frameout
; ===========================================================================
Obj74_Index2:	dc.w Obj74_Drop-Obj74_Index2
		dc.w Obj74_MakeFlame-Obj74_Index2
		dc.w Obj74_Duplicate-Obj74_Index2
		dc.w Obj74_FallEdge-Obj74_Index2
; ===========================================================================

Obj74_Drop:				; XREF: Obj74_Index2
		bset	#1,cddat(a0)
		subq.b	#1,$29(a0)
		bpl.b	locret_18780
		move.b	#$8B,colino(a0)
		clr.b	userflag(a0)
		addi.w	#$18,$12(a0)
		bclr	#1,cddat(a0)
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_18780
		addq.b	#2,r_no1(a0)

locret_18780:
		rts	
; ===========================================================================

Obj74_MakeFlame:			; XREF: Obj74_Index2
		subq.w	#2,$C(a0)
		bset	#7,2(a0)
		move.w	#$A0,$10(a0)
		clr.w	$12(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#3,$29(a0)
		jsr	actwkchk2
		bne.b	loc_187CA
		lea	(a1),a3
		lea	(a0),a2
		moveq	#3,d0

Obj74_Loop:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbra	d0,Obj74_Loop

		neg.w	$10(a1)
		addq.b	#2,r_no1(a1)

loc_187CA:
		addq.b	#2,r_no1(a0)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj74_Duplicate2:			; XREF: Obj74_Duplicate
		jsr	actwkchk2
		bne.b	locret_187EE
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.b	#$74,(a1)
		move.w	#$67,userflag(a1)

locret_187EE:
		rts	
; End of function Obj74_Duplicate2

; ===========================================================================

Obj74_Duplicate:			; XREF: Obj74_Index2
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	loc_18826
		move.w	8(a0),d0
		cmpi.w	#$1940,d0
		bgt.b	loc_1882C
		move.w	$30(a0),d1
		cmp.w	d0,d1
		beq.b	loc_1881E
		andi.w	#$10,d0
		andi.w	#$10,d1
		cmp.w	d0,d1
		beq.b	loc_1881E
		bsr.b	Obj74_Duplicate2
		move.w	8(a0),$32(a0)

loc_1881E:
		move.w	8(a0),$30(a0)
		rts	
; ===========================================================================

loc_18826:
		addq.b	#2,r_no1(a0)
		rts	
; ===========================================================================

loc_1882C:
		addq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

Obj74_FallEdge:				; XREF: Obj74_Index2
		bclr	#1,cddat(a0)
		addi.w	#$24,$12(a0)	; make flame fall
		move.w	8(a0),d0
		sub.w	$32(a0),d0
		bpl.b	loc_1884A
		neg.w	d0

loc_1884A:
		cmpi.w	#$12,d0
		bne.b	loc_18856
		bclr	#7,2(a0)

loc_18856:
		bsr.w	emycol_d
		tst.w	d1
		bpl.b	locret_1887E
		subq.b	#1,$29(a0)
		beq.b	Obj74_Delete2
		clr.w	$12(a0)
		move.w	$32(a0),8(a0)
		move.w	$38(a0),$C(a0)
		bset	#7,2(a0)
		subq.b	#2,r_no1(a0)

locret_1887E:
		rts	
; ===========================================================================

Obj74_Delete2:
		jmp	frameout
; ===========================================================================

loc_18886:				; XREF: Obj74_Index
		bset	#7,2(a0)
		subq.b	#1,$29(a0)
		bne.b	Obj74_Animate
		move.b	#1,$1C(a0)
		subq.w	#4,$C(a0)
		clr.b	colino(a0)

Obj74_Animate:
		lea	(Ani_fire).l,a1
		jmp	patchg
; ===========================================================================

Obj74_Delete3:				; XREF: Obj74_Index
		jmp	frameout
; ===========================================================================

Obj7A_Delete:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7A - Eggman (SLZ)
; ---------------------------------------------------------------------------

Obj7A:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj7A_Index(pc,d0.w),d1
		jmp	Obj7A_Index(pc,d1.w)
; ===========================================================================
Obj7A_Index:	dc.w Obj7A_Main-Obj7A_Index
		dc.w Obj7A_ShipMain-Obj7A_Index
		dc.w Obj7A_FaceMain-Obj7A_Index
		dc.w Obj7A_FlameMain-Obj7A_Index
		dc.w Obj7A_TubeMain-Obj7A_Index

Obj7A_ObjData:	dc.b 2,	0, 4		; routine number, animation, priority
		dc.b 4,	1, 4
		dc.b 6,	7, 4
		dc.b 8,	0, 3
; ===========================================================================

Obj7A_Main:				; XREF: Obj7A_Index
		move.w	#$2188,8(a0)
		move.w	#$228,$C(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,colino(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8
		lea	Obj7A_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	Obj7A_LoadBoss
; ===========================================================================

Obj7A_Loop:
		jsr	actwkchk2
		bne.b	loc_1895C
		move.b	#$7A,0(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Obj7A_LoadBoss:				; XREF: Obj7A_Main
		bclr	#0,cddat(a0)
		clr.b	r_no1(a1)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1C(a1)
		move.b	(a2)+,$18(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.l	a0,$34(a1)
		dbra	d1,Obj7A_Loop	; repeat sequence 3 more times

loc_1895C:
		lea	($FFFFD040).w,a1
		lea	$2A(a0),a2
		moveq	#$5E,d0
		moveq	#$3E,d1

loc_18968:
		cmp.b	(a1),d0
		bne.b	loc_18974
		tst.b	userflag(a1)
		beq.b	loc_18974
		move.w	a1,(a2)+

loc_18974:
		adda.w	#$40,a1
		dbra	d1,loc_18968

Obj7A_ShipMain:				; XREF: Obj7A_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj7A_ShipIndex(pc,d0.w),d0
		jsr	Obj7A_ShipIndex(pc,d0.w)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
Obj7A_ShipIndex:dc.w loc_189B8-Obj7A_ShipIndex
		dc.w loc_18A5E-Obj7A_ShipIndex
		dc.w Obj7A_MakeBall-Obj7A_ShipIndex
		dc.w loc_18B48-Obj7A_ShipIndex
		dc.w loc_18B80-Obj7A_ShipIndex
		dc.w loc_18BC6-Obj7A_ShipIndex
; ===========================================================================

loc_189B8:				; XREF: Obj7A_ShipIndex
		move.w	#-$100,$10(a0)
		cmpi.w	#$2120,$30(a0)
		bcc.b	loc_189CA
		addq.b	#2,r_no1(a0)

loc_189CA:
		bsr.w	BossMove
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(sinset).l
		asr.w	#6,d0
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)
		bra.b	loc_189FE
; ===========================================================================

loc_189EE:
		bsr.w	BossMove
		move.w	$38(a0),$C(a0)
		move.w	$30(a0),8(a0)

loc_189FE:
		cmpi.b	#6,r_no1(a0)
		bcc.b	locret_18A44
		tst.b	cddat(a0)
		bmi.b	loc_18A46
		tst.b	colino(a0)
		bne.b	locret_18A44
		tst.b	$3E(a0)
		bne.b	loc_18A28
		move.b	#$20,$3E(a0)
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

loc_18A28:
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.b	loc_18A36
		move.w	#$EEE,d0

loc_18A36:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.b	locret_18A44
		move.b	#$F,colino(a0)

locret_18A44:
		rts	
; ===========================================================================

loc_18A46:
		moveq	#100,d0
		bsr.w	scoreup
		move.b	#6,r_no1(a0)
		move.b	#$78,$3C(a0)
		clr.w	$10(a0)
		rts	
; ===========================================================================

loc_18A5E:				; XREF: Obj7A_ShipIndex
		move.w	$30(a0),d0
		move.w	#$200,$10(a0)
		btst	#0,cddat(a0)
		bne.b	loc_18A7C
		neg.w	$10(a0)
		cmpi.w	#$2008,d0
		bgt.b	loc_18A88
		bra.b	loc_18A82
; ===========================================================================

loc_18A7C:
		cmpi.w	#$2138,d0
		blt.b	loc_18A88

loc_18A82:
		bchg	#0,cddat(a0)

loc_18A88:
		move.w	8(a0),d0
		moveq	#-1,d1
		moveq	#2,d2
		lea	$2A(a0),a2
		moveq	#$28,d4
		tst.w	$10(a0)
		bpl.b	loc_18A9E
		neg.w	d4

loc_18A9E:
		move.w	(a2)+,d1
		movea.l	d1,a3
		btst	#3,$22(a3)
		bne.b	loc_18AB4
		move.w	8(a3),d3
		add.w	d4,d3
		sub.w	d0,d3
		beq.b	loc_18AC0

loc_18AB4:
		dbra	d2,loc_18A9E

		move.b	d2,userflag(a0)
		bra.w	loc_189CA
; ===========================================================================

loc_18AC0:
		move.b	d2,userflag(a0)
		addq.b	#2,r_no1(a0)
		move.b	#$28,$3C(a0)
		bra.w	loc_189CA
; ===========================================================================

Obj7A_MakeBall:				; XREF: Obj7A_ShipIndex
		cmpi.b	#$28,$3C(a0)
		bne.b	loc_18B36
		moveq	#-1,d0
		move.b	userflag(a0),d0
		ext.w	d0
		bmi.b	loc_18B40
		subq.w	#2,d0
		neg.w	d0
		add.w	d0,d0
		lea	$2A(a0),a1
		move.w	(a1,d0.w),d0
		movea.l	d0,a2
		lea	($FFFFD040).w,a1
		moveq	#$3E,d1

loc_18AFA:
		cmp.l	$3C(a1),d0
		beq.b	loc_18B40
		adda.w	#$40,a1
		dbra	d1,loc_18AFA

		move.l	a0,-(sp)
		lea	(a2),a0
		jsr	actwkchk2
		movea.l	(sp)+,a0
		bne.b	loc_18B40
		move.b	#$7B,(a1)	; load spiked ball object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		addi.w	#$20,$C(a1)
		move.b	cddat(a2),cddat(a1)
		move.l	a2,$3C(a1)

loc_18B36:
		subq.b	#1,$3C(a0)
		beq.b	loc_18B40
		bra.w	loc_189FE
; ===========================================================================

loc_18B40:
		subq.b	#2,r_no1(a0)
		bra.w	loc_189CA
; ===========================================================================

loc_18B48:				; XREF: Obj7A_ShipIndex
		subq.b	#1,$3C(a0)
		bmi.b	loc_18B52
		bra.w	BossDefeated
; ===========================================================================

loc_18B52:
		addq.b	#2,r_no1(a0)
		clr.w	$12(a0)
		bset	#0,cddat(a0)
		bclr	#7,cddat(a0)
		clr.w	$10(a0)
		move.b	#-$18,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.b	loc_18B7C
		move.b	#1,($FFFFF7A7).w

loc_18B7C:
		bra.w	loc_189FE
; ===========================================================================

loc_18B80:				; XREF: Obj7A_ShipIndex
		addq.b	#1,$3C(a0)
		beq.b	loc_18B90
		bpl.b	loc_18B96
		addi.w	#$18,$12(a0)
		bra.b	loc_18BC2
; ===========================================================================

loc_18B90:
		clr.w	$12(a0)
		bra.b	loc_18BC2
; ===========================================================================

loc_18B96:
		cmpi.b	#$20,$3C(a0)
		bcs.b	loc_18BAE
		beq.b	loc_18BB4
		cmpi.b	#$2A,$3C(a0)
		bcs.b	loc_18BC2
		addq.b	#2,r_no1(a0)
		bra.b	loc_18BC2
; ===========================================================================

loc_18BAE:
		subq.w	#8,$12(a0)
		bra.b	loc_18BC2
; ===========================================================================

loc_18BB4:
		clr.w	$12(a0)
		move.w	#$84,d0
		jsr	(bgmset).l	; play SLZ music

loc_18BC2:
		bra.w	loc_189EE
; ===========================================================================

loc_18BC6:				; XREF: Obj7A_ShipIndex
		move.w	#$400,$10(a0)
		move.w	#-$40,$12(a0)
		cmpi.w	#$2160,scralim_right
		bcc.b	loc_18BE0
		addq.w	#2,scralim_right
		bra.b	loc_18BE8
; ===========================================================================

loc_18BE0:
		tst.b	1(a0)
		bpl.w	Obj7A_Delete

loc_18BE8:
		bsr.w	BossMove
		bra.w	loc_189CA
; ===========================================================================

Obj7A_FaceMain:				; XREF: Obj7A_Index
		moveq	#0,d0
		moveq	#1,d1
		movea.l	$34(a0),a1
		move.b	r_no1(a1),d0
		cmpi.b	#6,d0
		bmi.b	loc_18C06
		moveq	#$A,d1
		bra.b	loc_18C1A
; ===========================================================================

loc_18C06:
		tst.b	colino(a1)
		bne.b	loc_18C10
		moveq	#5,d1
		bra.b	loc_18C1A
; ===========================================================================

loc_18C10:
		cmpi.b	#4,($FFFFD024).w
		bcs.b	loc_18C1A
		moveq	#4,d1

loc_18C1A:
		move.b	d1,$1C(a0)
		cmpi.b	#$A,d0
		bne.b	loc_18C32
		move.b	#6,$1C(a0)
		tst.b	1(a0)
		bpl.w	Obj7A_Delete

loc_18C32:
		bra.b	loc_18C6C
; ===========================================================================

Obj7A_FlameMain:			; XREF: Obj7A_Index
		move.b	#8,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,r_no1(a1)
		bne.b	loc_18C56
		tst.b	1(a0)
		bpl.w	Obj7A_Delete
		move.b	#$B,$1C(a0)
		bra.b	loc_18C6C
; ===========================================================================

loc_18C56:
		cmpi.b	#8,r_no1(a1)
		bgt.b	loc_18C6C
		cmpi.b	#4,r_no1(a1)
		blt.b	loc_18C6C
		move.b	#7,$1C(a0)

loc_18C6C:
		lea	(Ani_Eggman).l,a1
		jsr	patchg

loc_18C78:
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.b	cddat(a1),cddat(a0)
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#-4,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================

Obj7A_TubeMain:				; XREF: Obj7A_Index
		movea.l	$34(a0),a1
		cmpi.b	#$A,r_no1(a1)
		bne.b	loc_18CB8
		tst.b	1(a0)
		bpl.w	Obj7A_Delete

loc_18CB8:
		move.l	#Map_BossItems,4(a0)
		move.w	#$246C,2(a0)
		move.b	#3,$1A(a0)
		bra.b	loc_18C78
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 7B - exploding	spikeys	that Eggman drops (SLZ)
; ---------------------------------------------------------------------------

Obj7B:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj7B_Index(pc,d0.w),d0
		jsr	Obj7B_Index(pc,d0.w)
		move.w	$30(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		bmi.w	Obj7A_Delete
		cmpi.w	#$280,d0
		bhi.w	Obj7A_Delete
		jmp	actionsub
; ===========================================================================
Obj7B_Index:	dc.w Obj7B_Main-Obj7B_Index
		dc.w Obj7B_Fall-Obj7B_Index
		dc.w loc_18DC6-Obj7B_Index
		dc.w loc_18EAA-Obj7B_Index
		dc.w Obj7B_Explode-Obj7B_Index
		dc.w Obj7B_MoveFrag-Obj7B_Index
; ===========================================================================

Obj7B_Main:				; XREF: Obj7B_Index
		move.l	#Map_sisooa,4(a0)
		move.w	#$518,2(a0)
		move.b	#1,$1A(a0)
		ori.b	#4,1(a0)
		move.b	#4,$18(a0)
		move.b	#$8B,colino(a0)
		move.b	#$C,$19(a0)
		movea.l	$3C(a0),a1
		move.w	8(a1),$30(a0)
		move.w	$C(a1),$34(a0)
		bset	#0,cddat(a0)
		move.w	8(a0),d0
		cmp.w	8(a1),d0
		bgt.b	loc_18D68
		bclr	#0,cddat(a0)
		move.b	#2,$3A(a0)

loc_18D68:
		addq.b	#2,r_no0(a0)

Obj7B_Fall:				; XREF: Obj7B_Index
		jsr	speedset
		movea.l	$3C(a0),a1
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.b	loc_18D8E
		addq.w	#2,d0

loc_18D8E:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	$C(a0),d1
		bgt.b	locret_18DC4
		movea.l	$3C(a0),a1
		moveq	#2,d1
		btst	#0,cddat(a0)
		beq.b	loc_18DAE
		moveq	#0,d1

loc_18DAE:
		move.w	#$F0,userflag(a0)
		move.b	#10,$1F(a0)	; set frame duration to	10 frames
		move.b	$1F(a0),$1E(a0)
		bra.w	loc_18FA2
; ===========================================================================

locret_18DC4:
		rts	
; ===========================================================================

loc_18DC6:				; XREF: Obj7B_Index
		movea.l	$3C(a0),a1
		moveq	#0,d0
		move.b	$3A(a0),d0
		sub.b	$3A(a1),d0
		beq.b	loc_18E2A
		bcc.b	loc_18DDA
		neg.b	d0

loc_18DDA:
		move.w	#-$818,d1
		move.w	#-$114,d2
		cmpi.b	#1,d0
		beq.b	loc_18E00
		move.w	#-$960,d1
		move.w	#-$F4,d2
		cmpi.w	#$9C0,$38(a1)
		blt.b	loc_18E00
		move.w	#-$A20,d1
		move.w	#-$80,d2

loc_18E00:
		move.w	d1,$12(a0)
		move.w	d2,$10(a0)
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		bcc.b	loc_18E16
		neg.w	$10(a0)

loc_18E16:
		move.b	#1,$1A(a0)
		move.w	#$20,userflag(a0)
		addq.b	#2,r_no0(a0)
		bra.w	loc_18EAA
; ===========================================================================

loc_18E2A:				; XREF: loc_18DC6
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	#$28,d2
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.b	loc_18E48
		neg.w	d2
		addq.w	#2,d0

loc_18E48:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		move.w	d1,$C(a0)
		add.w	$30(a0),d2
		move.w	d2,8(a0)
		clr.w	$E(a0)
		clr.w	$A(a0)
		subq.w	#1,userflag(a0)
		bne.b	loc_18E7A
		move.w	#$20,userflag(a0)
		move.b	#8,r_no0(a0)
		rts	
; ===========================================================================

loc_18E7A:
		cmpi.w	#$78,userflag(a0)
		bne.b	loc_18E88
		move.b	#5,$1F(a0)

loc_18E88:
		cmpi.w	#$3C,userflag(a0)
		bne.b	loc_18E96
		move.b	#2,$1F(a0)

loc_18E96:
		subq.b	#1,$1E(a0)
		bgt.b	locret_18EA8
		bchg	#0,$1A(a0)
		move.b	$1F(a0),$1E(a0)

locret_18EA8:
		rts	
; ===========================================================================

loc_18EAA:				; XREF: Obj7B_Index
		lea	($FFFFD040).w,a1
		moveq	#$7A,d0
		moveq	#$40,d1
		moveq	#$3E,d2

loc_18EB4:
		cmp.b	(a1),d0
		beq.b	loc_18EC0
		adda.w	d1,a1
		dbra	d2,loc_18EB4

		bra.b	loc_18F38
; ===========================================================================

loc_18EC0:
		move.w	8(a1),d0
		move.w	$C(a1),d1
		move.w	8(a0),d2
		move.w	$C(a0),d3
		lea	byte_19022(pc),a2
		lea	byte_19026(pc),a3
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d0
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d2
		cmp.w	d0,d2
		bcs.b	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d0
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d2
		cmp.w	d2,d0
		bcs.b	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d1
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d3
		cmp.w	d1,d3
		bcs.b	loc_18F38
		move.b	(a2)+,d4
		ext.w	d4
		add.w	d4,d1
		move.b	(a3)+,d4
		ext.w	d4
		add.w	d4,d3
		cmp.w	d3,d1
		bcs.b	loc_18F38
		addq.b	#2,r_no0(a0)
		clr.w	userflag(a0)
		clr.b	colino(a1)
		subq.b	#1,colicnt(a1)
		bne.b	loc_18F38
		bset	#7,cddat(a1)
		clr.w	$10(a0)
		clr.w	$12(a0)

loc_18F38:
		tst.w	$12(a0)
		bpl.b	loc_18F5C
		jsr	speedset
		move.w	$34(a0),d0
		subi.w	#$2F,d0
		cmp.w	$C(a0),d0
		bgt.b	loc_18F58
		jsr	speedset

loc_18F58:
		bra.w	loc_18E7A
; ===========================================================================

loc_18F5C:
		jsr	speedset
		movea.l	$3C(a0),a1
		lea	(word_19018).l,a2
		moveq	#0,d0
		move.b	$1A(a1),d0
		move.w	8(a0),d1
		sub.w	$30(a0),d1
		bcc.b	loc_18F7E
		addq.w	#2,d0

loc_18F7E:
		add.w	d0,d0
		move.w	$34(a0),d1
		add.w	(a2,d0.w),d1
		cmp.w	$C(a0),d1
		bgt.b	loc_18F58
		movea.l	$3C(a0),a1
		moveq	#2,d1
		tst.w	$10(a0)
		bmi.b	loc_18F9C
		moveq	#0,d1

loc_18F9C:
		move.w	#0,userflag(a0)

loc_18FA2:
		move.b	d1,$3A(a1)
		move.b	d1,$3A(a0)
		cmp.b	$1A(a1),d1
		beq.b	loc_19008
		bclr	#3,cddat(a1)
		beq.b	loc_19008
		clr.b	r_no1(a1)
		move.b	#2,r_no0(a1)
		lea	playerwk,a2
		move.w	$12(a0),$12(a2)
		neg.w	$12(a2)
		cmpi.b	#1,$1A(a1)
		bne.b	loc_18FDC
		asr	$12(a2)

loc_18FDC:
		bset	#1,cddat(a2)
		bclr	#3,cddat(a2)
		clr.b	$3C(a2)
		move.l	a0,-(sp)
		lea	(a2),a0
		jsr	ballset
		movea.l	(sp)+,a0
		move.b	#2,r_no0(a2)
		move.w	#$CC,d0
		jsr	(soundset).l ;	play "spring" sound

loc_19008:
		clr.w	$10(a0)
		clr.w	$12(a0)
		addq.b	#2,r_no0(a0)
		bra.w	loc_18E7A
; ===========================================================================
word_19018:	dc.w $FFF8, $FFE4, $FFD1, $FFE4, $FFF8
		even
byte_19022:	dc.b $E8, $30, $E8, $30
		even
byte_19026:	dc.b 8,	$F0, 8,	$F0
		even
; ===========================================================================

Obj7B_Explode:				; XREF: Obj7B_Index
		move.b	#$3F,(a0)
		clr.b	r_no0(a0)
		cmpi.w	#$20,userflag(a0)
		beq.b	Obj7B_MakeFrag
		rts	
; ===========================================================================

Obj7B_MakeFrag:
		move.w	$34(a0),$C(a0)
		moveq	#3,d1
		lea	Obj7B_FragSpeed(pc),a2

Obj7B_Loop:
		jsr	actwkchk
		bne.b	loc_1909A
		move.b	#$7B,(a1)	; load shrapnel	object
		move.b	#$A,r_no0(a1)
		move.l	#Map_obj7B,4(a1)
		move.b	#3,$18(a1)
		move.w	#$518,2(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		move.w	(a2)+,$10(a1)
		move.w	(a2)+,$12(a1)
		move.b	#$98,colino(a1)
		ori.b	#4,1(a1)
		bset	#7,1(a1)
		move.b	#$C,$19(a1)

loc_1909A:
		dbra	d1,Obj7B_Loop	; repeat sequence 3 more times

		rts	
; ===========================================================================
Obj7B_FragSpeed:dc.w $FF00, $FCC0	; horizontal, vertical
		dc.w $FF60, $FDC0
		dc.w $100, $FCC0
		dc.w $A0, $FDC0
; ===========================================================================

Obj7B_MoveFrag:				; XREF: Obj7B_Index
		jsr	speedset2
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$34(a0)
		addi.w	#$18,$12(a0)
		moveq	#4,d0
		and.w	systemtimer+2,d0
		lsr.w	#2,d0
		move.b	d0,$1A(a0)
		tst.b	1(a0)
		bpl.w	Obj7A_Delete
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - exploding spikeys that the SLZ boss	drops
; ---------------------------------------------------------------------------
Map_obj7B:
	include "_maps\obj7B.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 75 - Eggman (SYZ)
; ---------------------------------------------------------------------------

Obj75:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj75_Index(pc,d0.w),d1
		jmp	Obj75_Index(pc,d1.w)
; ===========================================================================
Obj75_Index:	dc.w Obj75_Main-Obj75_Index
		dc.w Obj75_ShipMain-Obj75_Index
		dc.w Obj75_FaceMain-Obj75_Index
		dc.w Obj75_FlameMain-Obj75_Index
		dc.w Obj75_SpikeMain-Obj75_Index

Obj75_ObjData:	dc.b 2,	0, 5		; routine number, animation, priority
		dc.b 4,	1, 5
		dc.b 6,	7, 5
		dc.b 8,	0, 5
; ===========================================================================

Obj75_Main:				; XREF: Obj75_Index
		move.w	#$2DB0,8(a0)
		move.w	#$4DA,$C(a0)
		move.w	8(a0),$30(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$F,colino(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8
		lea	Obj75_ObjData(pc),a2
		movea.l	a0,a1
		moveq	#3,d1
		bra.b	Obj75_LoadBoss
; ===========================================================================

Obj75_Loop:
		jsr	actwkchk2
		bne.b	Obj75_ShipMain
		move.b	#$75,(a1)
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Obj75_LoadBoss:				; XREF: Obj75_Main
		bclr	#0,cddat(a0)
		clr.b	r_no1(a1)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1C(a1)
		move.b	(a2)+,$18(a1)
		move.l	#Map_Eggman,4(a1)
		move.w	#$400,2(a1)
		move.b	#4,1(a1)
		move.b	#$20,$19(a1)
		move.l	a0,$34(a1)
		dbra	d1,Obj75_Loop	; repeat sequence 3 more times

Obj75_ShipMain:				; XREF: Obj75_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj75_ShipIndex(pc,d0.w),d1
		jsr	Obj75_ShipIndex(pc,d1.w)
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================
Obj75_ShipIndex:dc.w loc_191CC-Obj75_ShipIndex,	loc_19270-Obj75_ShipIndex
		dc.w loc_192EC-Obj75_ShipIndex,	loc_19474-Obj75_ShipIndex
		dc.w loc_194AC-Obj75_ShipIndex,	loc_194F2-Obj75_ShipIndex
; ===========================================================================

loc_191CC:				; XREF: Obj75_ShipIndex
		move.w	#-$100,$10(a0)
		cmpi.w	#$2D38,$30(a0)
		bcc.b	loc_191DE
		addq.b	#2,r_no1(a0)

loc_191DE:
		move.b	$3F(a0),d0
		addq.b	#2,$3F(a0)
		jsr	(sinset).l
		asr.w	#2,d0
		move.w	d0,$12(a0)

loc_191F2:
		bsr.w	BossMove
		move.w	$38(a0),$C(a0)
		move.w	$30(a0),8(a0)

loc_19202:
		move.w	8(a0),d0
		subi.w	#$2C00,d0
		lsr.w	#5,d0
		move.b	d0,$34(a0)
		cmpi.b	#6,r_no1(a0)
		bcc.b	locret_19256
		tst.b	cddat(a0)
		bmi.b	loc_19258
		tst.b	colino(a0)
		bne.b	locret_19256
		tst.b	$3E(a0)
		bne.b	loc_1923A
		move.b	#$20,$3E(a0)
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

loc_1923A:
		lea	($FFFFFB22).w,a1
		moveq	#0,d0
		tst.w	(a1)
		bne.b	loc_19248
		move.w	#$EEE,d0

loc_19248:
		move.w	d0,(a1)
		subq.b	#1,$3E(a0)
		bne.b	locret_19256
		move.b	#$F,colino(a0)

locret_19256:
		rts	
; ===========================================================================

loc_19258:				; XREF: loc_19202
		moveq	#100,d0
		bsr.w	scoreup
		move.b	#6,r_no1(a0)
		move.w	#$B4,$3C(a0)
		clr.w	$10(a0)
		rts	
; ===========================================================================

loc_19270:				; XREF: Obj75_ShipIndex
		move.w	$30(a0),d0
		move.w	#$140,$10(a0)
		btst	#0,cddat(a0)
		bne.b	loc_1928E
		neg.w	$10(a0)
		cmpi.w	#$2C08,d0
		bgt.b	loc_1929E
		bra.b	loc_19294
; ===========================================================================

loc_1928E:
		cmpi.w	#$2D38,d0
		blt.b	loc_1929E

loc_19294:
		bchg	#0,cddat(a0)
		clr.b	$3D(a0)

loc_1929E:
		subi.w	#$2C10,d0
		andi.w	#$1F,d0
		subi.w	#$1F,d0
		bpl.b	loc_192AE
		neg.w	d0

loc_192AE:
		subq.w	#1,d0
		bgt.b	loc_192E8
		tst.b	$3D(a0)
		bne.b	loc_192E8
		move.w	playerwk+xposi,d1
		subi.w	#$2C00,d1
		asr.w	#5,d1
		cmp.b	$34(a0),d1
		bne.b	loc_192E8
		moveq	#0,d0
		move.b	$34(a0),d0
		asl.w	#5,d0
		addi.w	#$2C10,d0
		move.w	d0,$30(a0)
		bsr.w	Obj75_FindBlocks
		addq.b	#2,r_no1(a0)
		clr.w	userflag(a0)
		clr.w	$10(a0)

loc_192E8:
		bra.w	loc_191DE
; ===========================================================================

loc_192EC:				; XREF: Obj75_ShipIndex
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.w	off_192FA(pc,d0.w),d0
		jmp	off_192FA(pc,d0.w)
; ===========================================================================
off_192FA:	dc.w loc_19302-off_192FA
		dc.w loc_19348-off_192FA
		dc.w loc_1938E-off_192FA
		dc.w loc_193D0-off_192FA
; ===========================================================================

loc_19302:				; XREF: off_192FA
		move.w	#$180,$12(a0)
		move.w	$38(a0),d0
		cmpi.w	#$556,d0
		bcs.b	loc_19344
		move.w	#$556,$38(a0)
		clr.w	$3C(a0)
		moveq	#-1,d0
		move.w	$36(a0),d0
		beq.b	loc_1933C
		movea.l	d0,a1
		move.b	#-1,$29(a1)
		move.b	#-1,$29(a0)
		move.l	a0,$34(a1)
		move.w	#$32,$3C(a0)

loc_1933C:
		clr.w	$12(a0)
		addq.b	#2,userflag(a0)

loc_19344:
		bra.w	loc_191F2
; ===========================================================================

loc_19348:				; XREF: off_192FA
		subq.w	#1,$3C(a0)
		bpl.b	loc_19366
		addq.b	#2,userflag(a0)
		move.w	#-$800,$12(a0)
		tst.w	$36(a0)
		bne.b	loc_19362
		asr	$12(a0)

loc_19362:
		moveq	#0,d0
		bra.b	loc_1937C
; ===========================================================================

loc_19366:
		moveq	#0,d0
		cmpi.w	#$1E,$3C(a0)
		bgt.b	loc_1937C
		moveq	#2,d0
		btst	#1,$3D(a0)
		beq.b	loc_1937C
		neg.w	d0

loc_1937C:
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)
		bra.w	loc_19202
; ===========================================================================

loc_1938E:				; XREF: off_192FA
		move.w	#$4DA,d0
		tst.w	$36(a0)
		beq.b	loc_1939C
		subi.w	#$18,d0

loc_1939C:
		cmp.w	$38(a0),d0
		blt.b	loc_193BE
		move.w	#8,$3C(a0)
		tst.w	$36(a0)
		beq.b	loc_193B4
		move.w	#$2D,$3C(a0)

loc_193B4:
		addq.b	#2,userflag(a0)
		clr.w	$12(a0)
		bra.b	loc_193CC
; ===========================================================================

loc_193BE:
		cmpi.w	#-$40,$12(a0)
		bge.b	loc_193CC
		addi.w	#$C,$12(a0)

loc_193CC:
		bra.w	loc_191F2
; ===========================================================================

loc_193D0:				; XREF: off_192FA
		subq.w	#1,$3C(a0)
		bgt.b	loc_19406
		bmi.b	loc_193EE
		moveq	#-1,d0
		move.w	$36(a0),d0
		beq.b	loc_193E8
		movea.l	d0,a1
		move.b	#$A,$29(a1)

loc_193E8:
		clr.w	$36(a0)
		bra.b	loc_19406
; ===========================================================================

loc_193EE:
		cmpi.w	#-$1E,$3C(a0)
		bne.b	loc_19406
		clr.b	$29(a0)
		subq.b	#2,r_no1(a0)
		move.b	#-1,$3D(a0)
		bra.b	loc_19446
; ===========================================================================

loc_19406:
		moveq	#1,d0
		tst.w	$36(a0)
		beq.b	loc_19410
		moveq	#2,d0

loc_19410:
		cmpi.w	#$4DA,$38(a0)
		beq.b	loc_19424
		blt.b	loc_1941C
		neg.w	d0

loc_1941C:
		tst.w	$36(a0)
		add.w	d0,$38(a0)

loc_19424:
		moveq	#0,d0
		tst.w	$36(a0)
		beq.b	loc_19438
		moveq	#2,d0
		btst	#0,$3D(a0)
		beq.b	loc_19438
		neg.w	d0

loc_19438:
		add.w	$38(a0),d0
		move.w	d0,$C(a0)
		move.w	$30(a0),8(a0)

loc_19446:
		bra.w	loc_19202

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj75_FindBlocks:			; XREF: loc_192AE
		clr.w	$36(a0)
		lea	($FFFFD040).w,a1
		moveq	#$3E,d0
		moveq	#$76,d1
		move.b	$34(a0),d2

Obj75_FindLoop:
		cmp.b	(a1),d1		; is object a SYZ boss block?
		bne.b	loc_1946A	; if not, branch
		cmp.b	userflag(a1),d2
		bne.b	loc_1946A
		move.w	a1,$36(a0)
		bra.b	locret_19472
; ===========================================================================

loc_1946A:
		lea	$40(a1),a1	; next object RAM entry
		dbra	d0,Obj75_FindLoop

locret_19472:
		rts	
; End of function Obj75_FindBlocks

; ===========================================================================

loc_19474:				; XREF: Obj75_ShipIndex
		subq.w	#1,$3C(a0)
		bmi.b	loc_1947E
		bra.w	BossDefeated
; ===========================================================================

loc_1947E:
		addq.b	#2,r_no1(a0)
		clr.w	$12(a0)
		bset	#0,cddat(a0)
		bclr	#7,cddat(a0)
		clr.w	$10(a0)
		move.w	#-1,$3C(a0)
		tst.b	($FFFFF7A7).w
		bne.b	loc_194A8
		move.b	#1,($FFFFF7A7).w

loc_194A8:
		bra.w	loc_19202
; ===========================================================================

loc_194AC:				; XREF: Obj75_ShipIndex
		addq.w	#1,$3C(a0)
		beq.b	loc_194BC
		bpl.b	loc_194C2
		addi.w	#$18,$12(a0)
		bra.b	loc_194EE
; ===========================================================================

loc_194BC:
		clr.w	$12(a0)
		bra.b	loc_194EE
; ===========================================================================

loc_194C2:
		cmpi.w	#$20,$3C(a0)
		bcs.b	loc_194DA
		beq.b	loc_194E0
		cmpi.w	#$2A,$3C(a0)
		bcs.b	loc_194EE
		addq.b	#2,r_no1(a0)
		bra.b	loc_194EE
; ===========================================================================

loc_194DA:
		subq.w	#8,$12(a0)
		bra.b	loc_194EE
; ===========================================================================

loc_194E0:
		clr.w	$12(a0)
		move.w	#$85,d0
		jsr	(bgmset).l	; play SYZ music

loc_194EE:
		bra.w	loc_191F2
; ===========================================================================

loc_194F2:				; XREF: Obj75_ShipIndex
		move.w	#$400,$10(a0)
		move.w	#-$40,$12(a0)
		cmpi.w	#$2D40,scralim_right
		bcc.b	loc_1950C
		addq.w	#2,scralim_right
		bra.b	loc_19512
; ===========================================================================

loc_1950C:
		tst.b	1(a0)
		bpl.b	Obj75_ShipDelete

loc_19512:
		bsr.w	BossMove
		bra.w	loc_191DE
; ===========================================================================

Obj75_ShipDelete:
		jmp	frameout
; ===========================================================================

Obj75_FaceMain:				; XREF: Obj75_Index
		moveq	#1,d1
		movea.l	$34(a0),a1
		moveq	#0,d0
		move.b	r_no1(a1),d0
		move.w	off_19546(pc,d0.w),d0
		jsr	off_19546(pc,d0.w)
		move.b	d1,$1C(a0)
		move.b	(a0),d0
		cmp.b	(a1),d0
		bne.b	Obj75_FaceDelete
		bra.b	loc_195BE
; ===========================================================================

Obj75_FaceDelete:
		jmp	frameout
; ===========================================================================
off_19546:	dc.w loc_19574-off_19546, loc_19574-off_19546
		dc.w loc_1955A-off_19546, loc_19552-off_19546
		dc.w loc_19552-off_19546, loc_19556-off_19546
; ===========================================================================

loc_19552:				; XREF: off_19546
		moveq	#$A,d1
		rts	
; ===========================================================================

loc_19556:				; XREF: off_19546
		moveq	#6,d1
		rts	
; ===========================================================================

loc_1955A:				; XREF: off_19546
		moveq	#0,d0
		move.b	userflag(a1),d0
		move.w	off_19568(pc,d0.w),d0
		jmp	off_19568(pc,d0.w)
; ===========================================================================
off_19568:	dc.w loc_19570-off_19568, loc_19572-off_19568
		dc.w loc_19570-off_19568, loc_19570-off_19568
; ===========================================================================

loc_19570:				; XREF: off_19568
		bra.b	loc_19574
; ===========================================================================

loc_19572:				; XREF: off_19568
		moveq	#6,d1

loc_19574:				; XREF: off_19546
		tst.b	colino(a1)
		bne.b	loc_1957E
		moveq	#5,d1
		rts	
; ===========================================================================

loc_1957E:
		cmpi.b	#4,($FFFFD024).w
		bcs.b	locret_19588
		moveq	#4,d1

locret_19588:
		rts	
; ===========================================================================

Obj75_FlameMain:			; XREF: Obj75_Index
		move.b	#7,$1C(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,r_no1(a1)
		bne.b	loc_195AA
		move.b	#$B,$1C(a0)
		tst.b	1(a0)
		bpl.b	Obj75_FlameDelete
		bra.b	loc_195B6
; ===========================================================================

loc_195AA:
		tst.w	$10(a1)
		beq.b	loc_195B6
		move.b	#8,$1C(a0)

loc_195B6:
		bra.b	loc_195BE
; ===========================================================================

Obj75_FlameDelete:
		jmp	frameout
; ===========================================================================

loc_195BE:
		lea	(Ani_Eggman).l,a1
		jsr	patchg
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)

loc_195DA:
		move.b	cddat(a1),cddat(a0)
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#$FC,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================

Obj75_SpikeMain:			; XREF: Obj75_Index
		move.l	#Map_BossItems,4(a0)
		move.w	#$246C,2(a0)
		move.b	#5,$1A(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$A,r_no1(a1)
		bne.b	loc_1961C
		tst.b	1(a0)
		bpl.b	Obj75_SpikeDelete

loc_1961C:
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		move.w	$3C(a0),d0
		cmpi.b	#4,r_no1(a1)
		bne.b	loc_19652
		cmpi.b	#6,userflag(a1)
		beq.b	loc_1964C
		tst.b	userflag(a1)
		bne.b	loc_19658
		cmpi.w	#$94,d0
		bge.b	loc_19658
		addq.w	#7,d0
		bra.b	loc_19658
; ===========================================================================

loc_1964C:
		tst.w	$3C(a1)
		bpl.b	loc_19658

loc_19652:
		tst.w	d0
		ble.b	loc_19658
		subq.w	#5,d0

loc_19658:
		move.w	d0,$3C(a0)
		asr.w	#2,d0
		add.w	d0,$C(a0)
		move.b	#8,$19(a0)
		move.b	#$C,$16(a0)
		clr.b	colino(a0)
		movea.l	$34(a0),a1
		tst.b	colino(a1)
		beq.b	loc_19688
		tst.b	$29(a1)
		bne.b	loc_19688
		move.b	#$84,colino(a0)

loc_19688:
		bra.w	loc_195DA
; ===========================================================================

Obj75_SpikeDelete:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 76 - blocks that Eggman picks up (SYZ)
; ---------------------------------------------------------------------------

Obj76:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj76_Index(pc,d0.w),d1
		jmp	Obj76_Index(pc,d1.w)
; ===========================================================================
Obj76_Index:	dc.w Obj76_Main-Obj76_Index
		dc.w Obj76_Action-Obj76_Index
		dc.w loc_19762-Obj76_Index
; ===========================================================================

Obj76_Main:				; XREF: Obj76_Index
		moveq	#0,d4
		move.w	#$2C10,d5
		moveq	#9,d6
		lea	(a0),a1
		bra.b	Obj76_MakeBlock
; ===========================================================================

Obj76_Loop:
		jsr	actwkchk
		bne.b	Obj76_ExitLoop

Obj76_MakeBlock:			; XREF: Obj76_Main
		move.b	#$76,(a1)
		move.l	#Map_obj76,4(a1)
		move.w	#$4000,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#$10,$16(a1)
		move.b	#3,$18(a1)
		move.w	d5,8(a1)	; set x-position
		move.w	#$582,$C(a1)
		move.w	d4,userflag(a1)
		addi.w	#$101,d4
		addi.w	#$20,d5		; add $20 to next x-position
		addq.b	#2,r_no0(a1)
		dbra	d6,Obj76_Loop	; repeat sequence 9 more times

Obj76_ExitLoop:
		rts	
; ===========================================================================

Obj76_Action:				; XREF: Obj76_Index
		move.b	$29(a0),d0
		cmp.b	userflag(a0),d0
		beq.b	Obj76_Solid
		tst.b	d0
		bmi.b	loc_19718

loc_19712:
		bsr.w	Obj76_Break
		bra.b	Obj76_Display
; ===========================================================================

loc_19718:
		movea.l	$34(a0),a1
		tst.b	colicnt(a1)
		beq.b	loc_19712
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		addi.w	#$2C,$C(a0)
		cmpa.w	a0,a1
		bcs.b	Obj76_Display
		move.w	$12(a1),d0
		ext.l	d0
		asr.l	#8,d0
		add.w	d0,$C(a0)
		bra.b	Obj76_Display
; ===========================================================================

Obj76_Solid:				; XREF: Obj76_Action
		move.w	#$1B,d1
		move.w	#$10,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		jsr	hitchk

Obj76_Display:				; XREF: Obj76_Action
		jmp	actionsub
; ===========================================================================

loc_19762:				; XREF: Obj76_Index
		tst.b	1(a0)
		bpl.b	Obj76_Delete
		jsr	speedset
		jmp	actionsub
; ===========================================================================

Obj76_Delete:
		jmp	frameout

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Obj76_Break:				; XREF: Obj76_Action
		lea	Obj76_FragSpeed(pc),a4
		lea	Obj76_FragPos(pc),a5
		moveq	#1,d4
		moveq	#3,d1
		moveq	#$38,d2
		addq.b	#2,r_no0(a0)
		move.b	#8,$19(a0)
		move.b	#8,$16(a0)
		lea	(a0),a1
		bra.b	Obj76_MakeFrag
; ===========================================================================

Obj76_LoopFrag:
		jsr	actwkchk2
		bne.b	loc_197D4

Obj76_MakeFrag:
		lea	(a0),a2
		lea	(a1),a3
		moveq	#3,d3

loc_197AA:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbra	d3,loc_197AA

		move.w	(a4)+,$10(a1)
		move.w	(a4)+,$12(a1)
		move.w	(a5)+,d3
		add.w	d3,8(a1)
		move.w	(a5)+,d3
		add.w	d3,$C(a1)
		move.b	d4,$1A(a1)
		addq.w	#1,d4
		dbra	d1,Obj76_LoopFrag ; repeat sequence 3 more times

loc_197D4:
		move.w	#$CB,d0
		jmp	(soundset).l ;	play smashing sound
; End of function Obj76_Break

; ===========================================================================
Obj76_FragSpeed:dc.w $FE80, $FE00
		dc.w $180, $FE00
		dc.w $FF00, $FF00
		dc.w $100, $FF00
Obj76_FragPos:	dc.w $FFF8, $FFF8
		dc.w $10, 0
		dc.w 0,	$10
		dc.w $10, $10
; ---------------------------------------------------------------------------
; Sprite mappings - blocks that	Eggman picks up (SYZ)
; ---------------------------------------------------------------------------
Map_obj76:
	include "_maps\obj76.asm"

; ===========================================================================

loc_1982C:				; XREF: loc_19C62; loc_19C80
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 82 - Eggman (SBZ2)
; ---------------------------------------------------------------------------

Obj82:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj82_Index(pc,d0.w),d1
		jmp	Obj82_Index(pc,d1.w)
; ===========================================================================
Obj82_Index:	dc.w Obj82_Main-Obj82_Index
		dc.w Obj82_Eggman-Obj82_Index
		dc.w Obj82_Switch-Obj82_Index

Obj82_ObjData:	dc.b 2,	0, 3		; routine number, animation, priority
		dc.b 4,	0, 3
; ===========================================================================

Obj82_Main:				; XREF: Obj82_Index
		lea	Obj82_ObjData(pc),a2
		move.w	#$2160,8(a0)
		move.w	#$5A4,$C(a0)
		move.b	#$F,colino(a0)
		move.b	#$10,colicnt(a0)
		bclr	#0,cddat(a0)
		clr.b	r_no1(a0)
		move.b	(a2)+,r_no0(a0)
		move.b	(a2)+,$1C(a0)
		move.b	(a2)+,$18(a0)
		move.l	#Map_obj82,4(a0)
		move.w	#$400,2(a0)
		move.b	#4,1(a0)
		bset	#7,1(a0)
		move.b	#$20,$19(a0)
		jsr	actwkchk2
		bne.b	Obj82_Eggman
		move.l	a0,$34(a1)
		move.b	#$82,(a1)	; load switch object
		move.w	#$2130,8(a1)
		move.w	#$5BC,$C(a1)
		clr.b	r_no1(a0)
		move.b	(a2)+,r_no0(a1)
		move.b	(a2)+,$1C(a1)
		move.b	(a2)+,$18(a1)
		move.l	#Map_switch2,4(a1)
		move.w	#$4A4,2(a1)
		move.b	#4,1(a1)
		bset	#7,1(a1)
		move.b	#$10,$19(a1)
		move.b	#0,$1A(a1)

Obj82_Eggman:				; XREF: Obj82_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj82_EggIndex(pc,d0.w),d1
		jsr	Obj82_EggIndex(pc,d1.w)
		lea	Ani_obj82(pc),a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================
Obj82_EggIndex:	dc.w Obj82_ChkSonic-Obj82_EggIndex
		dc.w Obj82_PreLeap-Obj82_EggIndex
		dc.w Obj82_Leap-Obj82_EggIndex
		dc.w loc_19934-Obj82_EggIndex
; ===========================================================================

Obj82_ChkSonic:				; XREF: Obj82_EggIndex
		move.w	8(a0),d0
		sub.w	playerwk+xposi,d0
		cmpi.w	#128,d0		; is Sonic within 128 pixels of	Eggman?
		bcc.b	loc_19934	; if not, branch
		addq.b	#2,r_no1(a0)
		move.w	#180,$3C(a0)	; set delay to 3 seconds
		move.b	#1,$1C(a0)

loc_19934:				; XREF: Obj82_EggIndex
		jmp	speedset2
; ===========================================================================

Obj82_PreLeap:				; XREF: Obj82_EggIndex
		subq.w	#1,$3C(a0)	; subtract 1 from time delay
		bne.b	loc_19954	; if time remains, branch
		addq.b	#2,r_no1(a0)
		move.b	#2,$1C(a0)
		addq.w	#4,$C(a0)
		move.w	#15,$3C(a0)

loc_19954:
		bra.b	loc_19934
; ===========================================================================

Obj82_Leap:				; XREF: Obj82_EggIndex
		subq.w	#1,$3C(a0)
		bgt.b	loc_199D0
		bne.b	loc_1996A
		move.w	#-$FC,$10(a0)	; make Eggman leap
		move.w	#-$3C0,$12(a0)

loc_1996A:
		cmpi.w	#$2132,8(a0)
		bgt.b	loc_19976
		clr.w	$10(a0)

loc_19976:
		addi.w	#$24,$12(a0)
		tst.w	$12(a0)
		bmi.b	Obj82_FindBlocks
		cmpi.w	#$595,$C(a0)
		bcs.b	Obj82_FindBlocks
		move.w	#$5357,userflag(a0)
		cmpi.w	#$59B,$C(a0)
		bcs.b	Obj82_FindBlocks
		move.w	#$59B,$C(a0)
		clr.w	$12(a0)

Obj82_FindBlocks:
		move.w	$10(a0),d0
		or.w	$12(a0),d0
		bne.b	loc_199D0
		lea	playerwk,a1 ; start at the	first object RAM
		moveq	#$3E,d0
		moveq	#$40,d1

Obj82_FindLoop:	
		adda.w	d1,a1		; jump to next object RAM
		cmpi.b	#$83,(a1)	; is object a block? (object $83)
		dbeq	d0,Obj82_FindLoop ; if not, repeat (max	$3E times)

		bne.b	loc_199D0
		move.w	#$474F,userflag(a1)	; set block to disintegrate
		addq.b	#2,r_no1(a0)
		move.b	#1,$1C(a0)

loc_199D0:
		bra.w	loc_19934
; ===========================================================================

Obj82_Switch:				; XREF: Obj82_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj82_SwIndex(pc,d0.w),d0
		jmp	Obj82_SwIndex(pc,d0.w)
; ===========================================================================
Obj82_SwIndex:	dc.w loc_199E6-Obj82_SwIndex
		dc.w Obj82_SwDisplay-Obj82_SwIndex
; ===========================================================================

loc_199E6:				; XREF: Obj82_SwIndex
		movea.l	$34(a0),a1
		cmpi.w	#$5357,userflag(a1)
		bne.b	Obj82_SwDisplay
		move.b	#1,$1A(a0)
		addq.b	#2,r_no1(a0)

Obj82_SwDisplay:			; XREF: Obj82_SwIndex
		jmp	actionsub
; ===========================================================================
Ani_obj82:
	include "_anim\obj82.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - Eggman (SBZ2)
; ---------------------------------------------------------------------------
Map_obj82:
	include "_maps\obj82.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 83 - blocks that disintegrate Eggman	presses	a switch (SBZ2)
; ---------------------------------------------------------------------------

Obj83:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj83_Index(pc,d0.w),d1
		jmp	Obj83_Index(pc,d1.w)
; ===========================================================================
Obj83_Index:	dc.w Obj83_Main-Obj83_Index
		dc.w Obj83_ChkBreak-Obj83_Index
		dc.w loc_19C36-Obj83_Index
		dc.w loc_19C62-Obj83_Index
		dc.w loc_19C72-Obj83_Index
		dc.w loc_19C80-Obj83_Index
; ===========================================================================

Obj83_Main:				; XREF: Obj83_Index
		move.w	#$2080,8(a0)
		move.w	#$5D0,$C(a0)
		move.b	#$80,$19(a0)
		move.b	#$10,$16(a0)
		move.b	#4,1(a0)
		bset	#7,1(a0)
		moveq	#0,d4
		move.w	#$2010,d5
		moveq	#7,d6
		lea	$30(a0),a2

Obj83_MakeBlock:
		jsr	actwkchk
		bne.b	Obj83_ExitMake
		move.w	a1,(a2)+
		move.b	#$83,(a1)	; load block object
		move.l	#Map_obj83,4(a1)
		move.w	#$4518,2(a1)
		move.b	#4,1(a1)
		move.b	#$10,$19(a1)
		move.b	#$10,$16(a1)
		move.b	#3,$18(a1)
		move.w	d5,8(a1)	; set X	position
		move.w	#$5D0,$C(a1)
		addi.w	#$20,d5		; add $20 for next X position
		move.b	#8,r_no0(a1)
		dbra	d6,Obj83_MakeBlock ; repeat sequence 7 more times

Obj83_ExitMake:
		addq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

Obj83_ChkBreak:				; XREF: Obj83_Index
		cmpi.w	#$474F,userflag(a0)	; is object set	to disintegrate?
		bne.b	Obj83_Solid	; if not, branch
		clr.b	$1A(a0)
		addq.b	#2,r_no0(a0)	; next subroutine

Obj83_Solid:
		moveq	#0,d0
		move.b	$1A(a0),d0
		neg.b	d0
		ext.w	d0
		addq.w	#8,d0
		asl.w	#4,d0
		move.w	#$2100,d4
		sub.w	d0,d4
		move.b	d0,$19(a0)
		move.w	d4,8(a0)
		moveq	#$B,d1
		add.w	d0,d1
		moveq	#$10,d2
		moveq	#$11,d3
		jmp	hitchk
; ===========================================================================

loc_19C36:				; XREF: Obj83_Index
		subi.b	#$E,$1E(a0)
		bcc.b	Obj83_Solid2
		moveq	#-1,d0
		move.b	$1A(a0),d0
		ext.w	d0
		add.w	d0,d0
		move.w	$30(a0,d0.w),d0
		movea.l	d0,a1
		move.w	#$474F,userflag(a1)
		addq.b	#1,$1A(a0)
		cmpi.b	#8,$1A(a0)
		beq.b	loc_19C62

Obj83_Solid2:
		bra.b	Obj83_Solid
; ===========================================================================

loc_19C62:				; XREF: Obj83_Index
		bclr	#3,cddat(a0)
		bclr	#3,playerwk+cddat
		bra.w	loc_1982C
; ===========================================================================

loc_19C72:				; XREF: Obj83_Index
		cmpi.w	#$474F,userflag(a0)	; is object set	to disintegrate?
		beq.b	Obj83_Break	; if yes, branch
		jmp	actionsub
; ===========================================================================

loc_19C80:				; XREF: Obj83_Index
		tst.b	1(a0)
		bpl.w	loc_1982C
		jsr	speedset
		jmp	actionsub
; ===========================================================================

Obj83_Break:				; XREF: loc_19C72
		lea	Obj83_FragSpeed(pc),a4
		lea	Obj83_FragPos(pc),a5
		moveq	#1,d4
		moveq	#3,d1
		moveq	#$38,d2
		addq.b	#2,r_no0(a0)
		move.b	#8,$19(a0)
		move.b	#8,$16(a0)
		lea	(a0),a1
		bra.b	Obj83_MakeFrag
; ===========================================================================

Obj83_LoopFrag:
		jsr	actwkchk2
		bne.b	Obj83_BreakSnd

Obj83_MakeFrag:				; XREF: Obj83_Break
		lea	(a0),a2
		lea	(a1),a3
		moveq	#3,d3

loc_19CC4:
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		move.l	(a2)+,(a3)+
		dbra	d3,loc_19CC4

		move.w	(a4)+,$12(a1)
		move.w	(a5)+,d3
		add.w	d3,8(a1)
		move.w	(a5)+,d3
		add.w	d3,$C(a1)
		move.b	d4,$1A(a1)
		addq.w	#1,d4
		dbra	d1,Obj83_LoopFrag ; repeat sequence 3 more times

Obj83_BreakSnd:
		move.w	#$CB,d0
		jsr	(soundset).l ;	play smashing sound
		jmp	actionsub
; ===========================================================================
Obj83_FragSpeed:dc.w $80, 0
		dc.w $120, $C0
Obj83_FragPos:	dc.w $FFF8, $FFF8
		dc.w $10, 0
		dc.w 0,	$10
		dc.w $10, $10
; ---------------------------------------------------------------------------
; Sprite mappings - blocks that	disintegrate when Eggman presses a switch
; ---------------------------------------------------------------------------
Map_obj83:
	include "_maps\obj83.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 85 - Eggman (FZ)
; ---------------------------------------------------------------------------

Obj85_Delete:
		jmp	frameout
; ===========================================================================

Obj85:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj85_Index(pc,d0.w),d0
		jmp	Obj85_Index(pc,d0.w)
; ===========================================================================
Obj85_Index:	dc.w Obj85_Main-Obj85_Index
		dc.w Obj85_Eggman-Obj85_Index
		dc.w loc_1A38E-Obj85_Index
		dc.w loc_1A346-Obj85_Index
		dc.w loc_1A2C6-Obj85_Index
		dc.w loc_1A3AC-Obj85_Index
		dc.w loc_1A264-Obj85_Index

Obj85_ObjData:	dc.w $100, $100, $470	; X pos, Y pos,	VRAM setting
		dc.l Map_obj82		; mappings pointer
		dc.w $25B0, $590, $300
		dc.l Map_obj84
		dc.w $26E0, $596, $3A0
		dc.l Map_FZBoss
		dc.w $26E0, $596, $470
		dc.l Map_obj82
		dc.w $26E0, $596, $400
		dc.l Map_Eggman
		dc.w $26E0, $596, $400
		dc.l Map_Eggman

Obj85_ObjData2:	dc.b 2,	0, 4, $20, $19	; routine num, animation, sprite priority, width, height
		dc.b 4,	0, 1, $12, 8
		dc.b 6,	0, 3, 0, 0
		dc.b 8,	0, 3, 0, 0
		dc.b $A, 0, 3, $20, $20
		dc.b $C, 0, 3, 0, 0
; ===========================================================================

Obj85_Main:				; XREF: Obj85_Index
		lea	Obj85_ObjData(pc),a2
		lea	Obj85_ObjData2(pc),a3
		movea.l	a0,a1
		moveq	#5,d1
		bra.b	Obj85_LoadBoss
; ===========================================================================

Obj85_Loop:
		jsr	actwkchk2
		bne.b	loc_19E20

Obj85_LoadBoss:				; XREF: Obj85_Main
		move.b	#$85,(a1)
		move.w	(a2)+,8(a1)
		move.w	(a2)+,$C(a1)
		move.w	(a2)+,2(a1)
		move.l	(a2)+,4(a1)
		move.b	(a3)+,r_no0(a1)
		move.b	(a3)+,$1C(a1)
		move.b	(a3)+,$18(a1)
		move.b	(a3)+,$17(a1)
		move.b	(a3)+,$16(a1)
		move.b	#4,1(a1)
		bset	#7,1(a0)
		move.l	a0,$34(a1)
		dbra	d1,Obj85_Loop

loc_19E20:
		lea	$36(a0),a2
		jsr	actwkchk
		bne.b	loc_19E5A
		move.b	#$86,(a1)	; load energy ball object
		move.w	a1,(a2)
		move.l	a0,$34(a1)
		lea	$38(a0),a2
		moveq	#0,d2
		moveq	#3,d1

loc_19E3E:
		jsr	actwkchk2
		bne.b	loc_19E5A
		move.w	a1,(a2)+
		move.b	#$84,(a1)	; load crushing	cylinder object
		move.l	a0,$34(a1)
		move.b	d2,userflag(a1)
		addq.w	#2,d2
		dbra	d1,loc_19E3E

loc_19E5A:
		move.w	#0,$34(a0)
		move.b	#8,colicnt(a0)	; set number of	hits to	8
		move.w	#-1,$30(a0)

Obj85_Eggman:				; XREF: Obj85_Index
		moveq	#0,d0
		move.b	$34(a0),d0
		move.w	off_19E80(pc,d0.w),d0
		jsr	off_19E80(pc,d0.w)
		jmp	actionsub
; ===========================================================================
off_19E80:	dc.w loc_19E90-off_19E80, loc_19EA8-off_19E80
		dc.w loc_19FE6-off_19E80, loc_1A02A-off_19E80
		dc.w loc_1A074-off_19E80, loc_1A112-off_19E80
		dc.w loc_1A192-off_19E80, loc_1A1D4-off_19E80
; ===========================================================================

loc_19E90:				; XREF: off_19E80
		tst.l	($FFFFF680).w
		bne.b	loc_19EA2
		cmpi.w	#$2450,scra_h_posit
		bcs.b	loc_19EA2
		addq.b	#2,$34(a0)

loc_19EA2:
		addq.l	#1,ranum
		rts	
; ===========================================================================

loc_19EA8:				; XREF: off_19E80
		tst.w	$30(a0)
		bpl.b	loc_19F10
		clr.w	$30(a0)
		jsr	(random).l
		andi.w	#$C,d0
		move.w	d0,d1
		addq.w	#2,d1
		tst.l	d0
		bpl.b	loc_19EC6
		exg	d1,d0

loc_19EC6:
		lea	word_19FD6(pc),a1
		move.w	(a1,d0.w),d0
		move.w	(a1,d1.w),d1
		move.w	d0,$30(a0)
		moveq	#-1,d2
		move.w	$38(a0,d0.w),d2
		movea.l	d2,a1
		move.b	#-1,$29(a1)
		move.w	#-1,$30(a1)
		move.w	$38(a0,d1.w),d2
		movea.l	d2,a1
		move.b	#1,$29(a1)
		move.w	#0,$30(a1)
		move.w	#1,$32(a0)
		clr.b	$35(a0)
		move.w	#$B7,d0
		jsr	(soundset).l ;	play rumbling sound

loc_19F10:
		tst.w	$32(a0)
		bmi.w	loc_19FA6
		bclr	#0,cddat(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcs.b	loc_19F2E
		bset	#0,cddat(a0)

loc_19F2E:
		move.w	#$2B,d1
		move.w	#$14,d2
		move.w	#$14,d3
		move.w	8(a0),d4
		jsr	hitchk
		tst.w	d4
		bgt.b	loc_19F50

loc_19F48:
		tst.b	$35(a0)
		bne.b	loc_19F88
		bra.b	loc_19F96
; ===========================================================================

loc_19F50:
		addq.w	#7,ranum
		cmpi.b	#2,playerwk+mstno
		bne.b	loc_19F48
		move.w	#$300,d0
		btst	#0,cddat(a0)
		bne.b	loc_19F6A
		neg.w	d0

loc_19F6A:
		move.w	d0,($FFFFD010).w
		tst.b	$35(a0)
		bne.b	loc_19F88
		subq.b	#1,colicnt(a0)
		move.b	#$64,$35(a0)
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

loc_19F88:
		subq.b	#1,$35(a0)
		beq.b	loc_19F96
		move.b	#3,$1C(a0)
		bra.b	loc_19F9C
; ===========================================================================

loc_19F96:
		move.b	#1,$1C(a0)

loc_19F9C:
		lea	Ani_obj82(pc),a1
		jmp	patchg
; ===========================================================================

loc_19FA6:
		tst.b	colicnt(a0)
		beq.b	loc_19FBC
		addq.b	#2,$34(a0)
		move.w	#-1,$30(a0)
		clr.w	$32(a0)
		rts	
; ===========================================================================

loc_19FBC:
		move.b	#6,$34(a0)
		move.w	#$25C0,8(a0)
		move.w	#$53C,$C(a0)
		move.b	#$14,$16(a0)
		rts	
; ===========================================================================
word_19FD6:	dc.w 0,	2, 2, 4, 4, 6, 6, 0
; ===========================================================================

loc_19FE6:				; XREF: off_19E80
		moveq	#-1,d0
		move.w	$36(a0),d0
		movea.l	d0,a1
		tst.w	$30(a0)
		bpl.b	loc_1A000
		clr.w	$30(a0)
		move.b	#-1,$29(a1)
		bsr.b	loc_1A020

loc_1A000:
		moveq	#$F,d0
		and.w	systemtimer+2,d0
		bne.b	loc_1A00A
		bsr.b	loc_1A020

loc_1A00A:
		tst.w	$32(a0)
		beq.b	locret_1A01E
		subq.b	#2,$34(a0)
		move.w	#-1,$30(a0)
		clr.w	$32(a0)

locret_1A01E:
		rts	
; ===========================================================================

loc_1A020:
		move.w	#$B1,d0
		jmp	(soundset).l ;	play electricity sound
; ===========================================================================

loc_1A02A:				; XREF: off_19E80
		move.b	#$30,$17(a0)
		bset	#0,cddat(a0)
		jsr	speedset2
		move.b	#6,$1A(a0)
		addi.w	#$10,$12(a0)
		cmpi.w	#$59C,$C(a0)
		bcs.b	loc_1A070
		move.w	#$59C,$C(a0)
		addq.b	#2,$34(a0)
		move.b	#$20,$17(a0)
		move.w	#$100,$10(a0)
		move.w	#-$100,$12(a0)
		addq.b	#2,($FFFFF742).w

loc_1A070:
		bra.w	loc_1A166
; ===========================================================================

loc_1A074:				; XREF: off_19E80
		bset	#0,cddat(a0)
		move.b	#4,$1C(a0)
		jsr	speedset2
		addi.w	#$10,$12(a0)
		cmpi.w	#$5A3,$C(a0)
		bcs.b	loc_1A09A
		move.w	#-$40,$12(a0)

loc_1A09A:
		move.w	#$400,$10(a0)
		move.w	8(a0),d0
		sub.w	playerwk+xposi,d0
		bpl.b	loc_1A0B4
		move.w	#$500,$10(a0)
		bra.w	loc_1A0F2
; ===========================================================================

loc_1A0B4:
		subi.w	#$70,d0
		bcs.b	loc_1A0F2
		subi.w	#$100,$10(a0)
		subq.w	#8,d0
		bcs.b	loc_1A0F2
		subi.w	#$100,$10(a0)
		subq.w	#8,d0
		bcs.b	loc_1A0F2
		subi.w	#$80,$10(a0)
		subq.w	#8,d0
		bcs.b	loc_1A0F2
		subi.w	#$80,$10(a0)
		subq.w	#8,d0
		bcs.b	loc_1A0F2
		subi.w	#$80,$10(a0)
		subi.w	#$38,d0
		bcs.b	loc_1A0F2
		clr.w	$10(a0)

loc_1A0F2:
		cmpi.w	#$26A0,8(a0)
		bcs.b	loc_1A110
		move.w	#$26A0,8(a0)
		move.w	#$240,$10(a0)
		move.w	#-$4C0,$12(a0)
		addq.b	#2,$34(a0)

loc_1A110:
		bra.b	loc_1A15C
; ===========================================================================

loc_1A112:				; XREF: off_19E80
		jsr	speedset2
		cmpi.w	#$26E0,8(a0)
		bcs.b	loc_1A124
		clr.w	$10(a0)

loc_1A124:
		addi.w	#$34,$12(a0)
		tst.w	$12(a0)
		bmi.b	loc_1A142
		cmpi.w	#$592,$C(a0)
		bcs.b	loc_1A142
		move.w	#$592,$C(a0)
		clr.w	$12(a0)

loc_1A142:
		move.w	$10(a0),d0
		or.w	$12(a0),d0
		bne.b	loc_1A15C
		addq.b	#2,$34(a0)
		move.w	#-$180,$12(a0)
		move.b	#1,colicnt(a0)

loc_1A15C:
		lea	Ani_obj82(pc),a1
		jsr	patchg

loc_1A166:
		cmpi.w	#$2700,scralim_right
		bge.b	loc_1A172
		addq.w	#2,scralim_right

loc_1A172:
		cmpi.b	#$C,$34(a0)
		bge.b	locret_1A190
		move.w	#$1B,d1
		move.w	#$70,d2
		move.w	#$71,d3
		move.w	8(a0),d4
		jmp	hitchk
; ===========================================================================

locret_1A190:
		rts	
; ===========================================================================

loc_1A192:				; XREF: off_19E80
		move.l	#Map_Eggman,4(a0)
		move.w	#$400,2(a0)
		move.b	#0,$1C(a0)
		bset	#0,cddat(a0)
		jsr	speedset2
		cmpi.w	#$544,$C(a0)
		bcc.b	loc_1A1D0
		move.w	#$180,$10(a0)
		move.w	#-$18,$12(a0)
		move.b	#$F,colino(a0)
		addq.b	#2,$34(a0)

loc_1A1D0:
		bra.w	loc_1A15C
; ===========================================================================

loc_1A1D4:				; XREF: off_19E80
		bset	#0,cddat(a0)
		jsr	speedset2
		tst.w	$30(a0)
		bne.b	loc_1A1FC
		tst.b	colino(a0)
		bne.b	loc_1A216
		move.w	#$1E,$30(a0)
		move.w	#$AC,d0
		jsr	(soundset).l ;	play boss damage sound

loc_1A1FC:
		subq.w	#1,$30(a0)
		bne.b	loc_1A216
		tst.b	cddat(a0)
		bpl.b	loc_1A210
		move.w	#$60,$12(a0)
		bra.b	loc_1A216
; ===========================================================================

loc_1A210:
		move.b	#$F,colino(a0)

loc_1A216:
		cmpi.w	#$2790,playerwk+xposi
		blt.b	loc_1A23A
		move.b	#1,plautoflag
		move.w	#0,swdata+0
		clr.w	playerwk+mspeed
		tst.w	$12(a0)
		bpl.b	loc_1A248
		move.w	#$100,swdata+0

loc_1A23A:
		cmpi.w	#$27E0,playerwk+xposi
		blt.b	loc_1A248
		move.w	#$27E0,playerwk+xposi

loc_1A248:
		cmpi.w	#$2900,8(a0)
		bcs.b	loc_1A260
		tst.b	1(a0)
		bmi.b	loc_1A260
		move.b	#$18,gmmode
		bra.w	Obj85_Delete
; ===========================================================================

loc_1A260:
		bra.w	loc_1A15C
; ===========================================================================

loc_1A264:				; XREF: Obj85_Index
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.w	Obj85_Delete
		move.b	#7,$1C(a0)
		cmpi.b	#$C,$34(a1)
		bge.b	loc_1A280
		bra.b	loc_1A2A6
; ===========================================================================

loc_1A280:
		tst.w	$10(a1)
		beq.b	loc_1A28C
		move.b	#$B,$1C(a0)

loc_1A28C:
		lea	Ani_Eggman(pc),a1
		jsr	patchg

loc_1A296:
		movea.l	$34(a0),a1
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)

loc_1A2A6:
		movea.l	$34(a0),a1
		move.b	cddat(a1),cddat(a0)
		moveq	#3,d0
		and.b	cddat(a0),d0
		andi.b	#-4,1(a0)
		or.b	d0,1(a0)
		jmp	actionsub
; ===========================================================================

loc_1A2C6:				; XREF: Obj85_Index
		movea.l	$34(a0),a1
		move.b	(a1),d0
		cmp.b	(a0),d0
		bne.w	Obj85_Delete
		cmpi.l	#Map_Eggman,4(a1)
		beq.b	loc_1A2E4
		move.b	#$A,$1A(a0)
		bra.b	loc_1A2A6
; ===========================================================================

loc_1A2E4:
		move.b	#1,$1C(a0)
		tst.b	colicnt(a1)
		ble.b	loc_1A312
		move.b	#6,$1C(a0)
		move.l	#Map_Eggman,4(a0)
		move.w	#$400,2(a0)
		lea	Ani_Eggman(pc),a1
		jsr	patchg
		bra.w	loc_1A296
; ===========================================================================

loc_1A312:
		tst.b	1(a0)
		bpl.w	Obj85_Delete
		bsr.w	BossDefeated
		move.b	#2,$18(a0)
		move.b	#0,$1C(a0)
		move.l	#Map_Eggman2,4(a0)
		move.w	#$3A0,2(a0)
		lea	Ani_obj85(pc),a1
		jsr	patchg
		bra.w	loc_1A296
; ===========================================================================

loc_1A346:				; XREF: Obj85_Index
		bset	#0,cddat(a0)
		movea.l	$34(a0),a1
		cmpi.l	#Map_Eggman,4(a1)
		beq.b	loc_1A35E
		bra.w	loc_1A2A6
; ===========================================================================

loc_1A35E:
		move.w	8(a1),8(a0)
		move.w	$C(a1),$C(a0)
		tst.b	$1E(a0)
		bne.b	loc_1A376
		move.b	#$14,$1E(a0)

loc_1A376:
		subq.b	#1,$1E(a0)
		bgt.b	loc_1A38A
		addq.b	#1,$1A(a0)
		cmpi.b	#2,$1A(a0)
		bgt.w	Obj85_Delete

loc_1A38A:
		bra.w	loc_1A296
; ===========================================================================

loc_1A38E:				; XREF: Obj85_Index
		move.b	#$B,$1A(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bcs.b	loc_1A3A6
		tst.b	1(a0)
		bpl.w	Obj85_Delete

loc_1A3A6:
		jmp	actionsub
; ===========================================================================

loc_1A3AC:				; XREF: Obj85_Index
		move.b	#0,$1A(a0)
		bset	#0,cddat(a0)
		movea.l	$34(a0),a1
		cmpi.b	#$C,$34(a1)
		bne.b	loc_1A3D0
		cmpi.l	#Map_Eggman,4(a1)
		beq.w	Obj85_Delete

loc_1A3D0:
		bra.w	loc_1A2A6
; ===========================================================================
Ani_obj85:
	include "_anim\obj85.asm"

Map_Eggman2:
	include "_maps\Eggman2.asm"

Map_FZBoss:
	include "_maps\FZ boss.asm"

; ===========================================================================

Obj84_Delete:
		jmp	frameout
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 84 - cylinder Eggman	hides in (FZ)
; ---------------------------------------------------------------------------

Obj84:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj84_Index(pc,d0.w),d0
		jmp	Obj84_Index(pc,d0.w)
; ===========================================================================
Obj84_Index:	dc.w Obj84_Main-Obj84_Index
		dc.w loc_1A4CE-Obj84_Index
		dc.w loc_1A57E-Obj84_Index

Obj84_PosData:	dc.w $24D0, $620
		dc.w $2550, $620
		dc.w $2490, $4C0
		dc.w $2510, $4C0
; ===========================================================================

Obj84_Main:				; XREF: Obj84_Index
		lea	Obj84_PosData(pc),a1
		moveq	#0,d0
		move.b	userflag(a0),d0
		add.w	d0,d0
		adda.w	d0,a1
		move.b	#4,1(a0)
		bset	#7,1(a0)
		bset	#4,1(a0)
		move.w	#$300,2(a0)
		move.l	#Map_obj84,4(a0)
		move.w	(a1)+,8(a0)
		move.w	(a1),$C(a0)
		move.w	(a1)+,$38(a0)
		move.b	#$20,$16(a0)
		move.b	#$60,$17(a0)
		move.b	#$20,$19(a0)
		move.b	#$60,$16(a0)
		move.b	#3,$18(a0)
		addq.b	#2,r_no0(a0)

loc_1A4CE:				; XREF: Obj84_Index
		cmpi.b	#2,userflag(a0)
		ble.b	loc_1A4DC
		bset	#1,1(a0)

loc_1A4DC:
		clr.l	$3C(a0)
		tst.b	$29(a0)
		beq.b	loc_1A4EA
		addq.b	#2,r_no0(a0)

loc_1A4EA:
		move.l	$3C(a0),d0
		move.l	$38(a0),d1
		add.l	d0,d1
		swap	d1
		move.w	d1,$C(a0)
		cmpi.b	#4,r_no0(a0)
		bne.b	loc_1A524
		tst.w	$30(a0)
		bpl.b	loc_1A524
		moveq	#-$A,d0
		cmpi.b	#2,userflag(a0)
		ble.b	loc_1A514
		moveq	#$E,d0

loc_1A514:
		add.w	d0,d1
		movea.l	$34(a0),a1
		move.w	d1,$C(a1)
		move.w	8(a0),8(a1)

loc_1A524:
		move.w	#$2B,d1
		move.w	#$60,d2
		move.w	#$61,d3
		move.w	8(a0),d4
		jsr	hitchk
		moveq	#0,d0
		move.w	$3C(a0),d1
		bpl.b	loc_1A550
		neg.w	d1
		subq.w	#8,d1
		bcs.b	loc_1A55C
		addq.b	#1,d0
		asr.w	#4,d1
		add.w	d1,d0
		bra.b	loc_1A55C
; ===========================================================================

loc_1A550:
		subi.w	#$27,d1
		bcs.b	loc_1A55C
		addq.b	#1,d0
		asr.w	#4,d1
		add.w	d1,d0

loc_1A55C:
		move.b	d0,$1A(a0)
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bmi.b	loc_1A578
		subi.w	#$140,d0
		bmi.b	loc_1A578
		tst.b	1(a0)
		bpl.w	Obj84_Delete

loc_1A578:
		jmp	actionsub
; ===========================================================================

loc_1A57E:				; XREF: Obj84_Index
		moveq	#0,d0
		move.b	userflag(a0),d0
		move.w	off_1A590(pc,d0.w),d0
		jsr	off_1A590(pc,d0.w)
		bra.w	loc_1A4EA
; ===========================================================================
off_1A590:	dc.w loc_1A598-off_1A590
		dc.w loc_1A598-off_1A590
		dc.w loc_1A604-off_1A590
		dc.w loc_1A604-off_1A590
; ===========================================================================

loc_1A598:				; XREF: off_1A590
		tst.b	$29(a0)
		bne.b	loc_1A5D4
		movea.l	$34(a0),a1
		tst.b	colicnt(a1)
		bne.b	loc_1A5B4
		bsr.w	BossDefeated
		subi.l	#$10000,$3C(a0)

loc_1A5B4:
		addi.l	#$20000,$3C(a0)
		bcc.b	locret_1A602
		clr.l	$3C(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)
		clr.w	$30(a1)
		subq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

loc_1A5D4:
		cmpi.w	#-$10,$3C(a0)
		bge.b	loc_1A5E4
		subi.l	#$28000,$3C(a0)

loc_1A5E4:
		subi.l	#$8000,$3C(a0)
		cmpi.w	#-$A0,$3C(a0)
		bgt.b	locret_1A602
		clr.w	$3E(a0)
		move.w	#-$A0,$3C(a0)
		clr.b	$29(a0)

locret_1A602:
		rts	
; ===========================================================================

loc_1A604:				; XREF: off_1A590
		bset	#1,1(a0)
		tst.b	$29(a0)
		bne.b	loc_1A646
		movea.l	$34(a0),a1
		tst.b	colicnt(a1)
		bne.b	loc_1A626
		bsr.w	BossDefeated
		addi.l	#$10000,$3C(a0)

loc_1A626:
		subi.l	#$20000,$3C(a0)
		bcc.b	locret_1A674
		clr.l	$3C(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)
		clr.w	$30(a1)
		subq.b	#2,r_no0(a0)
		rts	
; ===========================================================================

loc_1A646:
		cmpi.w	#$10,$3C(a0)
		blt.b	loc_1A656
		addi.l	#$28000,$3C(a0)

loc_1A656:
		addi.l	#$8000,$3C(a0)
		cmpi.w	#$A0,$3C(a0)
		blt.b	locret_1A674
		clr.w	$3E(a0)
		move.w	#$A0,$3C(a0)
		clr.b	$29(a0)

locret_1A674:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Sprite mappings - cylinders Eggman hides in (FZ)
; ---------------------------------------------------------------------------
Map_obj84:
	include "_maps\obj84.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 86 - energy balls (FZ)
; ---------------------------------------------------------------------------

Obj86:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	Obj86_Index(pc,d0.w),d0
		jmp	Obj86_Index(pc,d0.w)
; ===========================================================================
Obj86_Index:	dc.w Obj86_Main-Obj86_Index
		dc.w Obj86_Generator-Obj86_Index
		dc.w Obj86_MakeBalls-Obj86_Index
		dc.w loc_1A962-Obj86_Index
		dc.w loc_1A982-Obj86_Index
; ===========================================================================

Obj86_Main:				; XREF: Obj86_Index
		move.w	#$2588,8(a0)
		move.w	#$53C,$C(a0)
		move.w	#$300,2(a0)
		move.l	#Map_obj86,4(a0)
		move.b	#0,$1C(a0)
		move.b	#3,$18(a0)
		move.b	#8,$17(a0)
		move.b	#8,$16(a0)
		move.b	#4,1(a0)
		bset	#7,1(a0)
		addq.b	#2,r_no0(a0)

Obj86_Generator:			; XREF: Obj86_Index
		movea.l	$34(a0),a1
		cmpi.b	#6,$34(a1)
		bne.b	loc_1A850
		move.b	#$3F,(a0)
		move.b	#0,r_no0(a0)
		jmp	actionsub
; ===========================================================================

loc_1A850:
		move.b	#0,$1C(a0)
		tst.b	$29(a0)
		beq.b	loc_1A86C
		addq.b	#2,r_no0(a0)
		move.b	#1,$1C(a0)
		move.b	#$3E,userflag(a0)

loc_1A86C:
		move.w	#$13,d1
		move.w	#8,d2
		move.w	#$11,d3
		move.w	8(a0),d4
		jsr	hitchk
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		bmi.b	loc_1A89A
		subi.w	#$140,d0
		bmi.b	loc_1A89A
		tst.b	1(a0)
		bpl.w	Obj84_Delete

loc_1A89A:
		lea	Ani_obj86(pc),a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================

Obj86_MakeBalls:			; XREF: Obj86_Index
		tst.b	$29(a0)
		beq.w	loc_1A954
		clr.b	$29(a0)
		add.w	$30(a0),d0
		andi.w	#$1E,d0
		adda.w	d0,a2
		addq.w	#4,$30(a0)
		clr.w	$32(a0)
		moveq	#3,d2

Obj86_Loop:
		jsr	actwkchk2
		bne.w	loc_1A954
		move.b	#$86,(a1)
		move.w	8(a0),8(a1)
		move.w	#$53C,$C(a1)
		move.b	#8,r_no0(a1)
		move.w	#$2300,2(a1)
		move.l	#Map_obj86a,4(a1)
		move.b	#$C,$16(a1)
		move.b	#$C,$17(a1)
		move.b	#0,colino(a1)
		move.b	#3,$18(a1)
		move.w	#$3E,userflag(a1)
		move.b	#4,1(a1)
		bset	#7,1(a1)
		move.l	a0,$34(a1)
		jsr	(random).l
		move.w	$32(a0),d1
		muls.w	#-$4F,d1
		addi.w	#$2578,d1
		andi.w	#$1F,d0
		subi.w	#$10,d0
		add.w	d1,d0
		move.w	d0,$30(a1)
		addq.w	#1,$32(a0)
		move.w	$32(a0),$38(a0)
		dbra	d2,Obj86_Loop	; repeat sequence 3 more times

loc_1A954:
		tst.w	$32(a0)
		bne.b	loc_1A95E
		addq.b	#2,r_no0(a0)

loc_1A95E:
		bra.w	loc_1A86C
; ===========================================================================

loc_1A962:				; XREF: Obj86_Index
		move.b	#2,$1C(a0)
		tst.w	$38(a0)
		bne.b	loc_1A97E
		move.b	#2,r_no0(a0)
		movea.l	$34(a0),a1
		move.w	#-1,$32(a1)

loc_1A97E:
		bra.w	loc_1A86C
; ===========================================================================

loc_1A982:				; XREF: Obj86_Index
		moveq	#0,d0
		move.b	r_no1(a0),d0
		move.w	Obj86_Index2(pc,d0.w),d0
		jsr	Obj86_Index2(pc,d0.w)
		lea	Ani_obj86a(pc),a1
		jsr	patchg
		jmp	actionsub
; ===========================================================================
Obj86_Index2:	dc.w loc_1A9A6-Obj86_Index2
		dc.w loc_1A9C0-Obj86_Index2
		dc.w loc_1AA1E-Obj86_Index2
; ===========================================================================

loc_1A9A6:				; XREF: Obj86_Index2
		move.w	$30(a0),d0
		sub.w	8(a0),d0
		asl.w	#4,d0
		move.w	d0,$10(a0)
		move.w	#$B4,userflag(a0)
		addq.b	#2,r_no1(a0)
		rts	
; ===========================================================================

loc_1A9C0:				; XREF: Obj86_Index2
		tst.w	$10(a0)
		beq.b	loc_1A9E6
		jsr	speedset2
		move.w	8(a0),d0
		sub.w	$30(a0),d0
		bcc.b	loc_1A9E6
		clr.w	$10(a0)
		add.w	d0,8(a0)
		movea.l	$34(a0),a1
		subq.w	#1,$32(a1)

loc_1A9E6:
		move.b	#0,$1C(a0)
		subq.w	#1,userflag(a0)
		bne.b	locret_1AA1C
		addq.b	#2,r_no1(a0)
		move.b	#1,$1C(a0)
		move.b	#$9A,colino(a0)
		move.w	#$B4,userflag(a0)
		moveq	#0,d0
		move.w	playerwk+xposi,d0
		sub.w	8(a0),d0
		move.w	d0,$10(a0)
		move.w	#$140,$12(a0)

locret_1AA1C:
		rts	
; ===========================================================================

loc_1AA1E:				; XREF: Obj86_Index2
		jsr	speedset2
		cmpi.w	#$5E0,$C(a0)
		bcc.b	loc_1AA34
		subq.w	#1,userflag(a0)
		beq.b	loc_1AA34
		rts	
; ===========================================================================

loc_1AA34:
		movea.l	$34(a0),a1
		subq.w	#1,$38(a1)
		bra.w	Obj84_Delete
; ===========================================================================
Ani_obj86:
	include "_anim\obj86.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - energy ball	launcher (FZ)
; ---------------------------------------------------------------------------
Map_obj86:
	include "_maps\obj86.asm"

Ani_obj86a:
	include "_anim\obj86a.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - energy balls (FZ)
; ---------------------------------------------------------------------------
Map_obj86a:
	include "_maps\obj86a.asm"

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 3E - prison capsule
; ---------------------------------------------------------------------------

masin:					; XREF: act_tbl
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	masin_Index(pc,d0.w),d1
		jsr	masin_Index(pc,d1.w)
		move.w	8(a0),d0
		andi.w	#$FF80,d0
		move.w	scra_h_posit,d1
		subi.w	#$80,d1
		andi.w	#$FF80,d1
		sub.w	d1,d0
		cmpi.w	#$280,d0
		bhi.b	masin_Delete
		jmp	actionsub
; ===========================================================================

masin_Delete:
		jmp	frameout
; ===========================================================================
masin_Index:	dc.w masin_Main-masin_Index
		dc.w masin_BodyMain-masin_Index
		dc.w masin_Switched-masin_Index
		dc.w masin_Explosion-masin_Index
		dc.w masin_Explosion-masin_Index
		dc.w masin_Explosion-masin_Index
		dc.w masin_Animals-masin_Index
		dc.w masin_EndAct-masin_Index

masin_Var:	dc.b 2,	$20, 4,	0	; routine, width, priority, frame
		dc.b 4,	$C, 5, 1
		dc.b 6,	$10, 4,	3
		dc.b 8,	$10, 3,	5
; ===========================================================================

masin_Main:				; XREF: masin_Index
		move.l	#Map_masin,4(a0)
		move.w	#$49D,2(a0)
		move.b	#4,1(a0)
		move.w	$C(a0),$30(a0)
		moveq	#0,d0
		move.b	userflag(a0),d0
		lsl.w	#2,d0
		lea	masin_Var(pc,d0.w),a1
		move.b	(a1)+,r_no0(a0)
		move.b	(a1)+,$19(a0)
		move.b	(a1)+,$18(a0)
		move.b	(a1)+,$1A(a0)
		cmpi.w	#8,d0		; is object type number	02?
		bne.b	masin_Not02	; if not, branch
		move.b	#6,colino(a0)
		move.b	#8,colicnt(a0)

masin_Not02:
		rts	
; ===========================================================================

masin_BodyMain:				; XREF: masin_Index
		cmpi.b	#2,($FFFFF7A7).w
		beq.b	masin_ChkOpened
		move.w	#$2B,d1
		move.w	#$18,d2
		move.w	#$18,d3
		move.w	8(a0),d4
		jmp	hitchk
; ===========================================================================

masin_ChkOpened:
		tst.b	r_no1(a0)		; has the prison been opened?
		beq.b	masin_DoOpen	; if yes, branch
		clr.b	r_no1(a0)
		bclr	#3,playerwk+cddat
		bset	#1,playerwk+cddat

masin_DoOpen:
		move.b	#2,$1A(a0)	; use frame number 2 (destroyed	prison)
		rts	
; ===========================================================================

masin_Switched:				; XREF: masin_Index
		move.w	#$17,d1
		move.w	#8,d2
		move.w	#8,d3
		move.w	8(a0),d4
		jsr	hitchk
		lea	(Ani_masin).l,a1
		jsr	patchg
		move.w	$30(a0),$C(a0)
		tst.b	r_no1(a0)
		beq.b	locret_1AC60
		addq.w	#8,$C(a0)
		move.b	#$A,r_no0(a0)
		move.w	#$3C,$1E(a0)
		clr.b	pltime_f	; stop time counter
		clr.b	($FFFFF7AA).w	; lock screen position
		move.b	#1,plautoflag ; lock	controls
		move.w	#$800,swdata+0 ; make Sonic run to	the right
		clr.b	r_no1(a0)
		bclr	#3,playerwk+cddat
		bset	#1,playerwk+cddat

locret_1AC60:
		rts	
; ===========================================================================

masin_Explosion:			; XREF: masin_Index
		moveq	#7,d0
		and.b	systemtimer+3,d0
		bne.b	loc_1ACA0
		jsr	actwkchk
		bne.b	loc_1ACA0
		move.b	#$3F,0(a1)	; load explosion object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(random).l
		moveq	#0,d1
		move.b	d0,d1
		lsr.b	#2,d1
		subi.w	#$20,d1
		add.w	d1,8(a1)
		lsr.w	#8,d0
		lsr.b	#3,d0
		add.w	d0,$C(a1)

loc_1ACA0:
		subq.w	#1,$1E(a0)
		beq.b	masin_MakeAnimal
		rts	
; ===========================================================================

masin_MakeAnimal:
		move.b	#2,($FFFFF7A7).w
		move.b	#$C,r_no0(a0)	; replace explosions with animals
		move.b	#6,$1A(a0)
		move.w	#$96,$1E(a0)
		addi.w	#$20,$C(a0)
		moveq	#7,d6
		move.w	#$9A,d5
		moveq	#-$1C,d4

masin_Loop:
		jsr	actwkchk
		bne.b	locret_1ACF8
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		add.w	d4,8(a1)
		addq.w	#7,d4
		move.w	d5,$36(a1)
		subq.w	#8,d5
		dbra	d6,masin_Loop	; repeat 7 more	times

locret_1ACF8:
		rts	
; ===========================================================================

masin_Animals:				; XREF: masin_Index
		moveq	#7,d0
		and.b	systemtimer+3,d0
		bne.b	loc_1AD38
		jsr	actwkchk
		bne.b	loc_1AD38
		move.b	#$28,0(a1)	; load animal object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)
		jsr	(random).l
		andi.w	#$1F,d0
		subq.w	#6,d0
		tst.w	d1
		bpl.b	loc_1AD2E
		neg.w	d0

loc_1AD2E:
		add.w	d0,8(a1)
		move.w	#$C,$36(a1)

loc_1AD38:
		subq.w	#1,$1E(a0)
		bne.b	locret_1AD48
		addq.b	#2,r_no0(a0)
		move.w	#180,$1E(a0)

locret_1AD48:
		rts	
; ===========================================================================

masin_EndAct:				; XREF: masin_Index
		moveq	#$3E,d0
		moveq	#$28,d1
		moveq	#$40,d2
		lea	($FFFFD040).w,a1 ; load	object RAM

masin_Findusagi:
		cmp.b	(a1),d1		; is object $28	(animal) loaded?
		beq.b	masin_usagiFound ; if yes, branch
		adda.w	d2,a1		; next object RAM
		dbra	d0,masin_Findusagi ; repeat $3E	times

		jsr	GotThroughAct
		jmp	frameout
; ===========================================================================

masin_usagiFound:
		rts	
; ===========================================================================
Ani_masin:
	include "_anim\masin.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - prison capsule
; ---------------------------------------------------------------------------
Map_masin:
	include "_maps\masin.asm"

; ---------------------------------------------------------------------------
; Object touch response	subroutine - colino(a0) in	the object RAM
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


pcol:				; XREF: play00
		nop	
		move.w	8(a0),d2	; load Sonic's x-axis value
		move.w	$C(a0),d3	; load Sonic's y-axis value
		subq.w	#8,d2
		moveq	#0,d5
		move.b	$16(a0),d5	; load Sonic's height
		subq.b	#3,d5
		sub.w	d5,d3
		cmpi.b	#$39,$1A(a0)	; is Sonic ducking?
		bne.b	Touch_NoDuck	; if not, branch
		addi.w	#$C,d3
		moveq	#$A,d5

Touch_NoDuck:
		move.w	#$10,d4
		add.w	d5,d5
		lea	($FFFFD800).w,a1 ; begin checking the object RAM
		move.w	#$5F,d6

Touch_Loop:
		tst.b	1(a1)
		bpl.b	Touch_NextObj
		move.b	colino(a1),d0	; load touch response number
		bne.b	Touch_Height	; if touch response is not 0, branch

Touch_NextObj:
		lea	$40(a1),a1	; next object RAM
		dbra	d6,Touch_Loop	; repeat $5F more times

		moveq	#0,d0
		rts	
; ===========================================================================
Touch_Sizes:	dc.b  $14, $14		; width, height
		dc.b   $C, $14
		dc.b  $14,  $C
		dc.b	4, $10
		dc.b   $C, $12
		dc.b  $10, $10
		dc.b	6,   6
		dc.b  $18,  $C
		dc.b   $C, $10
		dc.b  $10,  $C
		dc.b	8,   8
		dc.b  $14, $10
		dc.b  $14,   8
		dc.b   $E,  $E
		dc.b  $18, $18
		dc.b  $28, $10
		dc.b  $10, $18
		dc.b	8, $10
		dc.b  $20, $70
		dc.b  $40, $20
		dc.b  $80, $20
		dc.b  $20, $20
		dc.b	8,   8
		dc.b	4,   4
		dc.b  $20,   8
		dc.b   $C,  $C
		dc.b	8,   4
		dc.b  $18,   4
		dc.b  $28,   4
		dc.b	4,   8
		dc.b	4, $18
		dc.b	4, $28
		dc.b	4, $20
		dc.b  $18, $18
		dc.b   $C, $18
		dc.b  $48,   8
; ===========================================================================

Touch_Height:				; XREF: pcol
		andi.w	#$3F,d0
		add.w	d0,d0
		lea	Touch_Sizes-2(pc,d0.w),a2
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	8(a1),d0
		sub.w	d1,d0
		sub.w	d2,d0
		bcc.b	loc_1AE98
		add.w	d1,d1
		add.w	d1,d0
		bcs.b	Touch_Width
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AE98:
		cmp.w	d4,d0
		bhi.w	Touch_NextObj

Touch_Width:
		moveq	#0,d1
		move.b	(a2)+,d1
		move.w	$C(a1),d0
		sub.w	d1,d0
		sub.w	d3,d0
		bcc.b	loc_1AEB6
		add.w	d1,d1
		add.w	d0,d1
		bcs.b	Touch_ChkValue
		bra.w	Touch_NextObj
; ===========================================================================

loc_1AEB6:
		cmp.w	d5,d0
		bhi.w	Touch_NextObj

Touch_ChkValue:
		move.b	colino(a1),d1	; load touch response number
		andi.b	#$C0,d1		; is touch response $40	or higher?
		beq.w	Touch_Enemy	; if not, branch
		cmpi.b	#$C0,d1		; is touch response $C0	or higher?
		beq.w	Touch_Special	; if yes, branch
		tst.b	d1		; is touch response $80-$BF ?
		bmi.w	Touch_ChkHurt	; if yes, branch

; touch	response is $40-$7F

		move.b	colino(a1),d0
		andi.b	#$3F,d0
		cmpi.b	#6,d0		; is touch response $46	?
		beq.b	Touch_Monitor	; if yes, branch
		cmpi.w	#$5A,$30(a0)
		bcc.w	locret_1AEF2
		addq.b	#2,r_no0(a1)	; advance the object's routine counter

locret_1AEF2:
		rts	
; ===========================================================================

Touch_Monitor:
		tst.w	$12(a0)		; is Sonic moving upwards?
		bpl.b	loc_1AF1E	; if not, branch
		move.w	$C(a0),d0
		subi.w	#$10,d0
		cmp.w	$C(a1),d0
		bcs.b	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		move.w	#-$180,$12(a1)
		tst.b	r_no1(a1)
		bne.b	locret_1AF2E
		addq.b	#4,r_no1(a1)	; advance the monitor's routine counter
		rts	
; ===========================================================================

loc_1AF1E:
		cmpi.b	#2,$1C(a0)	; is Sonic rolling/jumping?
		bne.b	locret_1AF2E
		neg.w	$12(a0)		; reverse Sonic's y-motion
		addq.b	#2,r_no0(a1)	; advance the monitor's routine counter

locret_1AF2E:
		rts	
; ===========================================================================

Touch_Enemy:				; XREF: Touch_ChkValue
		tst.b	plpower_m	; is Sonic invincible?
		bne.b	loc_1AF40	; if yes, branch
		cmpi.b	#2,$1C(a0)	; is Sonic rolling?
		bne.w	Touch_ChkHurt	; if not, branch

loc_1AF40:
		tst.b	colicnt(a1)
		beq.b	Touch_KillEnemy
		neg.w	$10(a0)
		neg.w	$12(a0)
		asr	$10(a0)
		asr	$12(a0)
		move.b	#0,colino(a1)
		subq.b	#1,colicnt(a1)
		bne.b	locret_1AF68
		bset	#7,cddat(a1)

locret_1AF68:
		rts	
; ===========================================================================

Touch_KillEnemy:
		bset	#7,cddat(a1)
		moveq	#0,d0
		move.w	emyscorecnt,d0
		addq.w	#2,emyscorecnt ; add 2 to item bonus counter
		cmpi.w	#6,d0
		bcs.b	loc_1AF82
		moveq	#6,d0

loc_1AF82:
		move.w	d0,$3E(a1)
		move.w	Enemy_Points(pc,d0.w),d0
		cmpi.w	#$20,emyscorecnt ; have 16 enemies been destroyed?
		bcs.b	loc_1AF9C	; if not, branch
		move.w	#1000,d0	; fix bonus to 10000
		move.w	#$A,$3E(a1)

loc_1AF9C:
		bsr.w	scoreup
		move.b	#$27,0(a1)	; change object	to points
		move.b	#0,r_no0(a1)
		tst.w	$12(a0)
		bmi.b	loc_1AFC2
		move.w	$C(a0),d0
		cmp.w	$C(a1),d0
		bcc.b	loc_1AFCA
		neg.w	$12(a0)
		rts	
; ===========================================================================

loc_1AFC2:
		addi.w	#$100,$12(a0)
		rts	
; ===========================================================================

loc_1AFCA:
		subi.w	#$100,$12(a0)
		rts	
; ===========================================================================
Enemy_Points:	dc.w 10, 20, 50, 100
; ===========================================================================

loc_1AFDA:				; XREF: Touch_CatKiller
		bset	#7,cddat(a1)

Touch_ChkHurt:				; XREF: Touch_ChkValue
		tst.b	plpower_m	; is Sonic invincible?
		beq.b	Touch_Hurt	; if not, branch

loc_1AFE6:				; XREF: Touch_Hurt
		moveq	#-1,d0
		rts	
; ===========================================================================

Touch_Hurt:				; XREF: Touch_ChkHurt
		nop	
		tst.w	$30(a0)
		bne.b	loc_1AFE6
		movea.l	a1,a2

; End of function pcol
; continue straight to playdamageset

; ---------------------------------------------------------------------------
; Hurting Sonic	subroutine
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


playdamageset:
		tst.b	plpower_b	; does Sonic have a shield?
		bne.b	Hurt_Shield	; if yes, branch
		tst.w	plring	; does Sonic have any rings?
		beq.w	Hurt_NoRings	; if not, branch
		jsr	actwkchk
		bne.b	Hurt_Shield
		move.b	#$37,0(a1)	; load bouncing	multi rings object
		move.w	8(a0),8(a1)
		move.w	$C(a0),$C(a1)

Hurt_Shield:
		move.b	#0,plpower_b ; remove shield
		move.b	#4,r_no0(a0)
		bsr.w	jumpcolsub
		bset	#1,cddat(a0)
		move.w	#-$400,$12(a0)	; make Sonic bounce away from the object
		move.w	#-$200,$10(a0)
		btst	#6,cddat(a0)
		beq.b	Hurt_Reverse
		move.w	#-$200,$12(a0)
		move.w	#-$100,$10(a0)

Hurt_Reverse:
		move.w	8(a0),d0
		cmp.w	8(a2),d0
		bcs.b	Hurt_ChkSpikes	; if Sonic is left of the object, branch
		neg.w	$10(a0)		; if Sonic is right of the object, reverse

Hurt_ChkSpikes:
		move.w	#0,$14(a0)
		move.b	#$1A,$1C(a0)
		move.w	#$78,$30(a0)
		move.w	#$A3,d0		; load normal damage sound
		cmpi.b	#$36,(a2)	; was damage caused by spikes?
		bne.b	Hurt_Sound	; if not, branch
		cmpi.b	#$16,(a2)	; was damage caused by LZ harpoon?
		bne.b	Hurt_Sound	; if not, branch
		move.w	#$A6,d0		; load spikes damage sound

Hurt_Sound:
		jsr	(soundset).l
		moveq	#-1,d0
		rts	
; ===========================================================================

Hurt_NoRings:
		tst.w	debugflag	; is debug mode	cheat on?
		bne.w	Hurt_Shield	; if yes, branch
; End of function playdamageset

; ---------------------------------------------------------------------------
; Subroutine to	kill Sonic
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


playdieset:
		tst.w	editmode	; is debug mode	active?
		bne.b	Kill_NoDeath	; if yes, branch
		move.b	#0,plpower_m ; remove invincibility
		move.b	#6,r_no0(a0)
		bsr.w	jumpcolsub
		bset	#1,cddat(a0)
		move.w	#-$700,$12(a0)
		move.w	#0,$10(a0)
		move.w	#0,$14(a0)
		move.w	$C(a0),$38(a0)
		move.b	#$18,$1C(a0)
		bset	#7,2(a0)
		move.w	#$A3,d0		; play normal death sound
		cmpi.b	#$36,(a2)	; check	if you were killed by spikes
		bne.b	Kill_Sound
		move.w	#$A6,d0		; play spikes death sound

Kill_Sound:
		jsr	(soundset).l

Kill_NoDeath:
		moveq	#-1,d0
		rts	
; End of function playdieset


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Touch_Special:				; XREF: Touch_ChkValue
		move.b	colino(a1),d1
		andi.b	#$3F,d1
		cmpi.b	#$B,d1		; is touch response $CB	?
		beq.b	Touch_CatKiller	; if yes, branch
		cmpi.b	#$C,d1		; is touch response $CC	?
		beq.b	Touch_Yadrin	; if yes, branch
		cmpi.b	#$17,d1		; is touch response $D7	?
		beq.b	Touch_D7orE1	; if yes, branch
		cmpi.b	#$21,d1		; is touch response $E1	?
		beq.b	Touch_D7orE1	; if yes, branch
		rts	
; ===========================================================================

Touch_CatKiller:			; XREF: Touch_Special
		bra.w	loc_1AFDA
; ===========================================================================

Touch_Yadrin:				; XREF: Touch_Special
		sub.w	d0,d5
		cmpi.w	#8,d5
		bcc.b	loc_1B144
		move.w	8(a1),d0
		subq.w	#4,d0
		btst	#0,cddat(a1)
		beq.b	loc_1B130
		subi.w	#$10,d0

loc_1B130:
		sub.w	d2,d0
		bcc.b	loc_1B13C
		addi.w	#$18,d0
		bcs.b	loc_1B140
		bra.b	loc_1B144
; ===========================================================================

loc_1B13C:
		cmp.w	d4,d0
		bhi.b	loc_1B144

loc_1B140:
		bra.w	Touch_ChkHurt
; ===========================================================================

loc_1B144:
		bra.w	Touch_Enemy
; ===========================================================================

Touch_D7orE1:				; XREF: Touch_Special
		addq.b	#1,colicnt(a1)
		rts	
; End of function Touch_Special

; ---------------------------------------------------------------------------
; Subroutine to	show the special stage layout
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_ShowLayout:				; XREF: SpecialStage
		bsr.w	SS_AniWallsRings
		bsr.w	SS_AniItems
		move.w	d5,-(sp)
		lea	($FFFF8000).w,a1
		move.b	rotdir,d0
		andi.b	#$FC,d0
		jsr	(sinset).l
		move.w	d0,d4
		move.w	d1,d5
		muls.w	#$18,d4
		muls.w	#$18,d5
		moveq	#0,d2
		move.w	scra_h_posit,d2
		divu.w	#$18,d2
		swap	d2
		neg.w	d2
		addi.w	#-$B4,d2
		moveq	#0,d3
		move.w	scra_v_posit,d3
		divu.w	#$18,d3
		swap	d3
		neg.w	d3
		addi.w	#-$B4,d3
		move.w	#$F,d7

loc_1B19E:
		movem.w	d0-d2,-(sp)
		movem.w	d0-d1,-(sp)
		neg.w	d0
		muls.w	d2,d1
		muls.w	d3,d0
		move.l	d0,d6
		add.l	d1,d6
		movem.w	(sp)+,d0-d1
		muls.w	d2,d0
		muls.w	d3,d1
		add.l	d0,d1
		move.l	d6,d2
		move.w	#$F,d6

loc_1B1C0:
		move.l	d2,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		move.l	d1,d0
		asr.l	#8,d0
		move.w	d0,(a1)+
		add.l	d5,d2
		add.l	d4,d1
		dbra	d6,loc_1B1C0

		movem.w	(sp)+,d0-d2
		addi.w	#$18,d3
		dbra	d7,loc_1B19E

		move.w	(sp)+,d5
		lea	($FF0000).l,a0
		moveq	#0,d0
		move.w	scra_v_posit,d0
		divu.w	#$18,d0
		mulu.w	#$80,d0
		adda.l	d0,a0
		moveq	#0,d0
		move.w	scra_h_posit,d0
		divu.w	#$18,d0
		adda.w	d0,a0
		lea	($FFFF8000).w,a4
		move.w	#$F,d7

loc_1B20C:
		move.w	#$F,d6

loc_1B210:
		moveq	#0,d0
		move.b	(a0)+,d0
		beq.b	loc_1B268
		cmpi.b	#$4E,d0
		bhi.b	loc_1B268
		move.w	(a4),d3
		addi.w	#$120,d3
		cmpi.w	#$70,d3
		bcs.b	loc_1B268
		cmpi.w	#$1D0,d3
		bcc.b	loc_1B268
		move.w	2(a4),d2
		addi.w	#$F0,d2
		cmpi.w	#$70,d2
		bcs.b	loc_1B268
		cmpi.w	#$170,d2
		bcc.b	loc_1B268
		lea	($FF4000).l,a5
		lsl.w	#3,d0
		lea	(a5,d0.w),a5
		movea.l	(a5)+,a1
		move.w	(a5)+,d1
		add.w	d1,d1
		adda.w	(a1,d1.w),a1
		movea.w	(a5)+,a3
		moveq	#0,d1
		move.b	(a1)+,d1
		subq.b	#1,d1
		bmi.b	loc_1B268
		jsr	sub_D762

loc_1B268:
		addq.w	#4,a4
		dbra	d6,loc_1B210

		lea	$70(a0),a0
		dbra	d7,loc_1B20C

		move.b	d5,($FFFFF62C).w
		cmpi.b	#$50,d5
		beq.b	loc_1B288
		move.l	#0,(a2)
		rts	
; ===========================================================================

loc_1B288:
		move.b	#0,-5(a2)
		rts	
; End of function SS_ShowLayout

; ---------------------------------------------------------------------------
; Subroutine to	animate	walls and rings	in the special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_AniWallsRings:			; XREF: SS_ShowLayout
		lea	($FF400C).l,a1
		moveq	#0,d0
		move.b	rotdir,d0
		lsr.b	#2,d0
		andi.w	#$F,d0
		moveq	#$23,d1

loc_1B2A4:
		move.w	d0,(a1)
		addq.w	#8,a1
		dbra	d1,loc_1B2A4

		lea	($FF4005).l,a1
		subq.b	#1,sys_pattim2
		bpl.b	loc_1B2C8
		move.b	#7,sys_pattim2
		addq.b	#1,sys_patno2
		andi.b	#3,sys_patno2

loc_1B2C8:
		move.b	sys_patno2,$1D0(a1)
		subq.b	#1,sys_pattim3
		bpl.b	loc_1B2E4
		move.b	#7,sys_pattim3
		addq.b	#1,sys_patno3
		andi.b	#1,sys_patno3

loc_1B2E4:
		move.b	sys_patno3,d0
		move.b	d0,$138(a1)
		move.b	d0,$160(a1)
		move.b	d0,$148(a1)
		move.b	d0,$150(a1)
		move.b	d0,$1D8(a1)
		move.b	d0,$1E0(a1)
		move.b	d0,$1E8(a1)
		move.b	d0,$1F0(a1)
		move.b	d0,$1F8(a1)
		move.b	d0,$200(a1)
		subq.b	#1,sys_pattim4
		bpl.b	loc_1B326
		move.b	#4,sys_pattim4
		addq.b	#1,sys_patno4
		andi.b	#3,sys_patno4

loc_1B326:
		move.b	sys_patno4,d0
		move.b	d0,$168(a1)
		move.b	d0,$170(a1)
		move.b	d0,$178(a1)
		move.b	d0,$180(a1)
		subq.b	#1,sys_pattim
		bpl.b	loc_1B350
		move.b	#7,sys_pattim
		subq.b	#1,sys_patno
		andi.b	#7,sys_patno

loc_1B350:
		lea	($FF4016).l,a1
		lea	(SS_WaRiVramSet).l,a0
		moveq	#0,d0
		move.b	sys_patno,d0
		add.w	d0,d0
		lea	(a0,d0.w),a0
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),colino(a1)
		move.w	$A(a0),userflag(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),colino(a1)
		move.w	$A(a0),userflag(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),colino(a1)
		move.w	$A(a0),userflag(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		move.w	(a0),(a1)
		move.w	2(a0),8(a1)
		move.w	4(a0),$10(a1)
		move.w	6(a0),$18(a1)
		move.w	8(a0),colino(a1)
		move.w	$A(a0),userflag(a1)
		move.w	$C(a0),$30(a1)
		move.w	$E(a0),$38(a1)
		adda.w	#$20,a0
		adda.w	#$48,a1
		rts	
; End of function SS_AniWallsRings

; ===========================================================================
SS_WaRiVramSet:	dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $142, $6142, $142,	$142, $142, $142, $142,	$6142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $2142, $142, $2142, $2142,	$2142, $2142, $2142, $142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $4142, $2142, $4142, $4142, $4142,	$4142, $4142, $2142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
		dc.w $6142, $4142, $6142, $6142, $6142,	$6142, $6142, $4142
; ---------------------------------------------------------------------------
; Subroutine to	remove items when you collect them in the special stage
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_RemoveCollectedItem:			; XREF: play01_ChkItems
		lea	($FF4400).l,a2
		move.w	#$1F,d0

loc_1B4C4:
		tst.b	(a2)
		beq.b	locret_1B4CE
		addq.w	#8,a2
		dbra	d0,loc_1B4C4

locret_1B4CE:
		rts	
; End of function SS_RemoveCollectedItem

; ---------------------------------------------------------------------------
; Subroutine to	animate	special	stage items when you touch them
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_AniItems:				; XREF: SS_ShowLayout
		lea	($FF4400).l,a0
		move.w	#$1F,d7

loc_1B4DA:
		moveq	#0,d0
		move.b	(a0),d0
		beq.b	loc_1B4E8
		lsl.w	#2,d0
		movea.l	SS_AniIndex-4(pc,d0.w),a1
		jsr	(a1)

loc_1B4E8:
		addq.w	#8,a0

loc_1B4EA:
		dbra	d7,loc_1B4DA

		rts	
; End of function SS_AniItems

; ===========================================================================
SS_AniIndex:	dc.l SS_AniRingSparks
		dc.l SS_AniBumper
		dc.l SS_Ani1Up
		dc.l SS_AniReverse
		dc.l SS_AniEmeraldSparks
		dc.l SS_AniGlassBlock
; ===========================================================================

SS_AniRingSparks:			; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B530
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRingData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.b	locret_1B530
		clr.l	(a0)
		clr.l	4(a0)

locret_1B530:
		rts	
; ===========================================================================
SS_AniRingData:	dc.b $42, $43, $44, $45, 0, 0
; ===========================================================================

SS_AniBumper:				; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B566
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniBumpData(pc,d0.w),d0
		bne.b	loc_1B564
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$25,(a1)
		rts	
; ===========================================================================

loc_1B564:
		move.b	d0,(a1)

locret_1B566:
		rts	
; ===========================================================================
SS_AniBumpData:	dc.b $32, $33, $32, $33, 0, 0
; ===========================================================================

SS_Ani1Up:				; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B596
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_Ani1UpData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.b	locret_1B596
		clr.l	(a0)
		clr.l	4(a0)

locret_1B596:
		rts	
; ===========================================================================
SS_Ani1UpData:	dc.b $46, $47, $48, $49, 0, 0
; ===========================================================================

SS_AniReverse:				; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B5CC
		move.b	#7,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniRevData(pc,d0.w),d0
		bne.b	loc_1B5CA
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#$2B,(a1)
		rts	
; ===========================================================================

loc_1B5CA:
		move.b	d0,(a1)

locret_1B5CC:
		rts	
; ===========================================================================
SS_AniRevData:	dc.b $2B, $31, $2B, $31, 0, 0
; ===========================================================================

SS_AniEmeraldSparks:			; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B60C
		move.b	#5,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniEmerData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.b	locret_1B60C
		clr.l	(a0)
		clr.l	4(a0)
		move.b	#4,($FFFFD024).w
		move.w	#$A8,d0
		jsr	(soundset).l ;	play special stage GOAL	sound

locret_1B60C:
		rts	
; ===========================================================================
SS_AniEmerData:	dc.b $46, $47, $48, $49, 0, 0
; ===========================================================================

SS_AniGlassBlock:			; XREF: SS_AniIndex
		subq.b	#1,2(a0)
		bpl.b	locret_1B640
		move.b	#1,2(a0)
		moveq	#0,d0
		move.b	3(a0),d0
		addq.b	#1,3(a0)
		movea.l	4(a0),a1
		move.b	SS_AniGlassData(pc,d0.w),d0
		move.b	d0,(a1)
		bne.b	locret_1B640
		move.b	4(a0),(a1)
		clr.l	(a0)
		clr.l	4(a0)

locret_1B640:
		rts	
; ===========================================================================
SS_AniGlassData:dc.b $4B, $4C, $4D, $4E, $4B, $4C, $4D,	$4E, 0,	0
; ---------------------------------------------------------------------------
; Special stage	layout pointers
; ---------------------------------------------------------------------------
SS_LayoutIndex:
		dc.l	rotmaptbl0
		dc.l	rotmaptbl1
		dc.l	rotmaptbl2
		dc.l	rotmaptbl3
		dc.l	rotmaptbl4
		dc.l	rotmaptbl5
		align

; ---------------------------------------------------------------------------
; Special stage	start locations
; ---------------------------------------------------------------------------
SS_StartLoc:	incbin	misc\sloc_ss.bin
		even

; ---------------------------------------------------------------------------
; Subroutine to	load special stage layout
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_Load:				; XREF: SpecialStage
		moveq	#0,d0
		move.b	($FFFFFE16).w,d0 ; load	number of last special stage entered
		addq.b	#1,($FFFFFE16).w
		cmpi.b	#6,($FFFFFE16).w
		bcs.b	SS_ChkEmldNum
		move.b	#0,($FFFFFE16).w ; reset if higher than	6

SS_ChkEmldNum:
		cmpi.b	#6,($FFFFFE57).w ; do you have all emeralds?
		beq.b	SS_LoadData	; if yes, branch
		moveq	#0,d1
		move.b	($FFFFFE57).w,d1
		subq.b	#1,d1
		bcs.b	SS_LoadData
		lea	($FFFFFE58).w,a3 ; check which emeralds	you have

SS_ChkEmldLoop:	
		cmp.b	(a3,d1.w),d0
		bne.b	SS_ChkEmldRepeat
		bra.b	SS_Load
; ===========================================================================

SS_ChkEmldRepeat:
		dbra	d1,SS_ChkEmldLoop

SS_LoadData:
		lsl.w	#2,d0
		lea	SS_StartLoc(pc,d0.w),a1
		move.w	(a1)+,playerwk+xposi
		move.w	(a1)+,playerwk+yposi
		movea.l	SS_LayoutIndex(pc,d0.w),a0
		lea	($FF4000).l,a1
		move.w	#0,d0
		jsr	(mapdevr).l
		lea	($FF0000).l,a1
		move.w	#$FFF,d0

SS_ClrRAM3:
		clr.l	(a1)+
		dbra	d0,SS_ClrRAM3

		lea	($FF1020).l,a1
		lea	($FF4000).l,a0
		moveq	#$3F,d1

loc_1B6F6:
		moveq	#$3F,d2

loc_1B6F8:
		move.b	(a0)+,(a1)+
		dbra	d2,loc_1B6F8

		lea	$40(a1),a1
		dbra	d1,loc_1B6F6

		lea	($FF4008).l,a1
		lea	(SS_MapIndex).l,a0
		moveq	#$4D,d1

loc_1B714:
		move.l	(a0)+,(a1)+
		move.w	#0,(a1)+
		move.b	-4(a0),-1(a1)
		move.w	(a0)+,(a1)+
		dbra	d1,loc_1B714

		lea	($FF4400).l,a1
		move.w	#$3F,d1

loc_1B730:

		clr.l	(a1)+
		dbra	d1,loc_1B730

		rts	
; End of function SS_Load

; ===========================================================================
; ---------------------------------------------------------------------------
; Special stage	mappings and VRAM pointers
; ---------------------------------------------------------------------------
SS_MapIndex:
	include "_inc\Special stage mappings and VRAM pointers.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage "R" block
; ---------------------------------------------------------------------------
Map_SS_R:
	include "_maps\SSRblock.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage breakable glass blocks and red-white blocks
; ---------------------------------------------------------------------------
Map_SS_Glass:
	include "_maps\SSglassblock.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage "UP" block
; ---------------------------------------------------------------------------
Map_SS_Up:
	include "_maps\SSUPblock.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage "DOWN" block
; ---------------------------------------------------------------------------
Map_SS_Down:
	include "_maps\SSDOWNblock.asm"

; ---------------------------------------------------------------------------
; Sprite mappings - special stage chaos	emeralds
; ---------------------------------------------------------------------------
Map_SS_Chaos1:	dc.w byte_1B96C-Map_SS_Chaos1
		dc.w byte_1B97E-Map_SS_Chaos1
Map_SS_Chaos2:	dc.w byte_1B972-Map_SS_Chaos2
		dc.w byte_1B97E-Map_SS_Chaos2
Map_SS_Chaos3:	dc.w byte_1B978-Map_SS_Chaos3
		dc.w byte_1B97E-Map_SS_Chaos3
byte_1B96C:	dc.b 1
		dc.b $F8, 5, 0,	0, $F8
byte_1B972:	dc.b 1
		dc.b $F8, 5, 0,	4, $F8
byte_1B978:	dc.b 1
		dc.b $F8, 5, 0,	8, $F8
byte_1B97E:	dc.b 1
		dc.b $F8, 5, 0,	$C, $F8
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Object 09 - Sonic (special stage)
; ---------------------------------------------------------------------------

play01:					; XREF: act_tbl
		tst.w	editmode	; is debug mode	being used?
		beq.b	play01_Normal	; if not, branch
		bsr.w	SS_FixCamera
		bra.w	edit
; ===========================================================================

play01_Normal:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	play01_Index(pc,d0.w),d1
		jmp	play01_Index(pc,d1.w)
; ===========================================================================
play01_Index:	dc.w play01_Main-play01_Index
		dc.w play01_ChkDebug-play01_Index
		dc.w play01_ExitStage-play01_Index
		dc.w play01_Exit2-play01_Index
; ===========================================================================

play01_Main:				; XREF: play01_Index
		addq.b	#2,r_no0(a0)
		move.b	#$E,$16(a0)
		move.b	#7,$17(a0)
		move.l	#playpat,4(a0)
		move.w	#$780,2(a0)
		move.b	#4,1(a0)
		move.b	#0,$18(a0)
		move.b	#2,$1C(a0)
		bset	#2,cddat(a0)
		bset	#1,cddat(a0)

play01_ChkDebug:				; XREF: play01_Index
		tst.w	debugflag	; is debug mode	cheat enabled?
		beq.b	play01_NoDebug	; if not, branch
		btst	#4,swdata1+1 ; is button B pressed?
		beq.b	play01_NoDebug	; if not, branch
		move.w	#1,editmode ; change Sonic	into a ring

play01_NoDebug:
		move.b	#0,$30(a0)
		moveq	#0,d0
		move.b	cddat(a0),d0
		andi.w	#2,d0
		move.w	play01_Modes(pc,d0.w),d1
		jsr	play01_Modes(pc,d1.w)
		jsr	Loadplaywrtpat
		jmp	actionsub
; ===========================================================================
play01_Modes:	dc.w play01_OnWall-play01_Modes
		dc.w play01_InAir-play01_Modes
; ===========================================================================

play01_OnWall:				; XREF: play01_Modes
		bsr.w	play01_Jump
		bsr.w	play01_Move
		bsr.w	play01_Fall
		bra.b	play01_Display
; ===========================================================================

play01_InAir:				; XREF: play01_Modes
		bsr.w	nullsub_2
		bsr.w	play01_Move
		bsr.w	play01_Fall

play01_Display:				; XREF: play01_OnWall
		bsr.w	play01_ChkItems
		bsr.w	play01_ChkItems2
		jsr	speedset2
		bsr.w	SS_FixCamera
		move.w	rotdir,d0
		add.w	rotspd,d0
		move.w	d0,rotdir
		jsr	spatset
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_Move:				; XREF: play01_OnWall; play01_InAir
		btst	#2,swdata+0 ; is left being pressed?
		beq.b	play01_ChkRight	; if not, branch
		bsr.w	play01_MoveLeft

play01_ChkRight:
		btst	#3,swdata+0 ; is right being pressed?
		beq.b	loc_1BA78	; if not, branch
		bsr.w	play01_MoveRight

loc_1BA78:
		move.b	swdata+0,d0
		andi.b	#$C,d0
		bne.b	loc_1BAA8
		move.w	$14(a0),d0
		beq.b	loc_1BAA8
		bmi.b	loc_1BA9A
		subi.w	#$C,d0
		bcc.b	loc_1BA94
		move.w	#0,d0

loc_1BA94:
		move.w	d0,$14(a0)
		bra.b	loc_1BAA8
; ===========================================================================

loc_1BA9A:
		addi.w	#$C,d0
		bcc.b	loc_1BAA4
		move.w	#0,d0

loc_1BAA4:
		move.w	d0,$14(a0)

loc_1BAA8:
		move.b	rotdir,d0
		addi.b	#$20,d0
		andi.b	#$C0,d0
		neg.b	d0
		jsr	(sinset).l
		muls.w	$14(a0),d1
		add.l	d1,8(a0)
		muls.w	$14(a0),d0
		add.l	d0,$C(a0)
		movem.l	d0-d1,-(sp)
		move.l	$C(a0),d2
		move.l	8(a0),d3
		bsr.w	sub_1BCE8
		beq.b	loc_1BAF2
		movem.l	(sp)+,d0-d1
		sub.l	d1,8(a0)
		sub.l	d0,$C(a0)
		move.w	#0,$14(a0)
		rts	
; ===========================================================================

loc_1BAF2:
		movem.l	(sp)+,d0-d1
		rts	
; End of function play01_Move


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_MoveLeft:				; XREF: play01_Move
		bset	#0,cddat(a0)
		move.w	$14(a0),d0
		beq.b	loc_1BB06
		bpl.b	loc_1BB1A

loc_1BB06:
		subi.w	#$C,d0
		cmpi.w	#-$800,d0
		bgt.b	loc_1BB14
		move.w	#-$800,d0

loc_1BB14:
		move.w	d0,$14(a0)
		rts	
; ===========================================================================

loc_1BB1A:
		subi.w	#$40,d0
		bcc.b	loc_1BB22
		nop	

loc_1BB22:
		move.w	d0,$14(a0)
		rts	
; End of function play01_MoveLeft


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_MoveRight:			; XREF: play01_Move
		bclr	#0,cddat(a0)
		move.w	$14(a0),d0
		bmi.b	loc_1BB48
		addi.w	#$C,d0
		cmpi.w	#$800,d0
		blt.b	loc_1BB42
		move.w	#$800,d0

loc_1BB42:
		move.w	d0,$14(a0)
		bra.b	locret_1BB54
; ===========================================================================

loc_1BB48:
		addi.w	#$40,d0
		bcc.b	loc_1BB50
		nop	

loc_1BB50:
		move.w	d0,$14(a0)

locret_1BB54:
		rts	
; End of function play01_MoveRight


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_Jump:				; XREF: play01_OnWall
		move.b	swdata+1,d0
		andi.b	#$70,d0		; is A,	B or C pressed?
		beq.b	play01_NoJump	; if not, branch
		move.b	rotdir,d0
		andi.b	#$FC,d0
		neg.b	d0
		subi.b	#$40,d0
		jsr	(sinset).l
		muls.w	#$680,d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	#$680,d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		bset	#1,cddat(a0)
		move.w	#$A0,d0
		jsr	(soundset).l ;	play jumping sound

play01_NoJump:
		rts	
; End of function play01_Jump


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


nullsub_2:				; XREF: play01_InAir
		rts	
; End of function nullsub_2

; ===========================================================================
; ---------------------------------------------------------------------------
; unused subroutine to limit Sonic's upward vertical speed
; ---------------------------------------------------------------------------
		move.w	#-$400,d1
		cmp.w	$12(a0),d1
		ble.b	locret_1BBB4
		move.b	swdata+0,d0
		andi.b	#$70,d0
		bne.b	locret_1BBB4
		move.w	d1,$12(a0)

locret_1BBB4:
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	fix the	camera on Sonic's position (special stage)
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


SS_FixCamera:				; XREF: play01
		move.w	$C(a0),d2
		move.w	8(a0),d3
		move.w	scra_h_posit,d0
		subi.w	#$A0,d3
		bcs.b	loc_1BBCE
		sub.w	d3,d0
		sub.w	d0,scra_h_posit

loc_1BBCE:
		move.w	scra_v_posit,d0
		subi.w	#$70,d2
		bcs.b	locret_1BBDE
		sub.w	d2,d0
		sub.w	d0,scra_v_posit

locret_1BBDE:
		rts	
; End of function SS_FixCamera

; ===========================================================================

play01_ExitStage:			; XREF: play01_Index
		addi.w	#$40,rotspd
		cmpi.w	#$1800,rotspd
		bne.b	loc_1BBF4
		move.b	#$C,gmmode

loc_1BBF4:
		cmpi.w	#$3000,rotspd
		blt.b	loc_1BC12
		move.w	#0,rotspd
		move.w	#$4000,rotdir
		addq.b	#2,r_no0(a0)
		move.w	#$3C,$38(a0)

loc_1BC12:
		move.w	rotdir,d0
		add.w	rotspd,d0
		move.w	d0,rotdir
		jsr	spatset
		jsr	Loadplaywrtpat
		bsr.w	SS_FixCamera
		jmp	actionsub
; ===========================================================================

play01_Exit2:				; XREF: play01_Index
		subq.w	#1,$38(a0)
		bne.b	loc_1BC40
		move.b	#$C,gmmode

loc_1BC40:
		jsr	spatset
		jsr	Loadplaywrtpat
		bsr.w	SS_FixCamera
		jmp	actionsub

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_Fall:				; XREF: play01_OnWall; play01_InAir
		move.l	$C(a0),d2
		move.l	8(a0),d3
		move.b	rotdir,d0
		andi.b	#$FC,d0
		jsr	(sinset).l
		move.w	$10(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d0
		add.l	d4,d0
		move.w	$12(a0),d4
		ext.l	d4
		asl.l	#8,d4
		muls.w	#$2A,d1
		add.l	d4,d1
		add.l	d0,d3
		bsr.w	sub_1BCE8
		beq.b	loc_1BCB0
		sub.l	d0,d3
		moveq	#0,d0
		move.w	d0,$10(a0)
		bclr	#1,cddat(a0)
		add.l	d1,d2
		bsr.w	sub_1BCE8
		beq.b	loc_1BCC6
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,$12(a0)
		rts	
; ===========================================================================

loc_1BCB0:
		add.l	d1,d2
		bsr.w	sub_1BCE8
		beq.b	loc_1BCD4
		sub.l	d1,d2
		moveq	#0,d1
		move.w	d1,$12(a0)
		bclr	#1,cddat(a0)

loc_1BCC6:
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,$10(a0)
		move.w	d1,$12(a0)
		rts	
; ===========================================================================

loc_1BCD4:
		asr.l	#8,d0
		asr.l	#8,d1
		move.w	d0,$10(a0)
		move.w	d1,$12(a0)
		bset	#1,cddat(a0)
		rts	
; End of function play01_Fall


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1BCE8:				; XREF: play01_Move; play01_Fall
		lea	($FF0000).l,a1
		moveq	#0,d4
		swap	d2
		move.w	d2,d4
		swap	d2
		addi.w	#$44,d4
		divu.w	#$18,d4
		mulu.w	#$80,d4
		adda.l	d4,a1
		moveq	#0,d4
		swap	d3
		move.w	d3,d4
		swap	d3
		addi.w	#$14,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		moveq	#0,d5
		move.b	(a1)+,d4
		bsr.b	sub_1BD30
		move.b	(a1)+,d4
		bsr.b	sub_1BD30
		adda.w	#$7E,a1
		move.b	(a1)+,d4
		bsr.b	sub_1BD30
		move.b	(a1)+,d4
		bsr.b	sub_1BD30
		tst.b	d5
		rts	
; End of function sub_1BCE8


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_1BD30:				; XREF: sub_1BCE8
		beq.b	locret_1BD44
		cmpi.b	#$28,d4
		beq.b	locret_1BD44
		cmpi.b	#$3A,d4
		bcs.b	loc_1BD46
		cmpi.b	#$4B,d4
		bcc.b	loc_1BD46

locret_1BD44:
		rts	
; ===========================================================================

loc_1BD46:
		move.b	d4,$30(a0)
		move.l	a1,$32(a0)
		moveq	#-1,d5
		rts	
; End of function sub_1BD30


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_ChkItems:				; XREF: play01_Display
		lea	($FF0000).l,a1
		moveq	#0,d4
		move.w	$C(a0),d4
		addi.w	#$50,d4
		divu.w	#$18,d4
		mulu.w	#$80,d4
		adda.l	d4,a1
		moveq	#0,d4
		move.w	8(a0),d4
		addi.w	#$20,d4
		divu.w	#$18,d4
		adda.w	d4,a1
		move.b	(a1),d4
		bne.b	play01_ChkCont
		tst.b	$3A(a0)
		bne.w	play01_MakeGhostSolid
		moveq	#0,d4
		rts	
; ===========================================================================

play01_ChkCont:
		cmpi.b	#$3A,d4		; is the item a	ring?
		bne.b	play01_Chk1Up
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_GetCont
		move.b	#1,(a2)
		move.l	a1,4(a2)

play01_GetCont:
		jsr	ringgetsub
		cmpi.w	#50,plring ; check if you have 50 rings
		bcs.b	play01_NoCont
		bset	#0,plring_f2
		bne.b	play01_NoCont
		addq.b	#1,($FFFFFE18).w ; add 1 to number of continues
		move.w	#$BF,d0
		jsr	(bgmset).l	; play extra continue sound

play01_NoCont:
		moveq	#0,d4
		rts	
; ===========================================================================

play01_Chk1Up:
		cmpi.b	#$28,d4		; is the item an extra life?
		bne.b	play01_ChkEmer
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_Get1Up
		move.b	#3,(a2)
		move.l	a1,4(a2)

play01_Get1Up:
		addq.b	#1,pl_suu ; add 1 to number of lives
		addq.b	#1,pl_suu_f ; add 1 to lives counter
		move.w	#$88,d0
		jsr	(bgmset).l	; play extra life music
		moveq	#0,d4
		rts	
; ===========================================================================

play01_ChkEmer:
		cmpi.b	#$3B,d4		; is the item an emerald?
		bcs.b	play01_ChkGhost
		cmpi.b	#$40,d4
		bhi.b	play01_ChkGhost
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_GetEmer
		move.b	#5,(a2)
		move.l	a1,4(a2)

play01_GetEmer:
		cmpi.b	#6,($FFFFFE57).w ; do you have all the emeralds?
		beq.b	play01_NoEmer	; if yes, branch
		subi.b	#$3B,d4
		moveq	#0,d0
		move.b	($FFFFFE57).w,d0
		lea	($FFFFFE58).w,a2
		move.b	d4,(a2,d0.w)
		addq.b	#1,($FFFFFE57).w ; add 1 to number of emeralds

play01_NoEmer:
		move.w	#$93,d0
		jsr	(soundset).l ;	play emerald music
		moveq	#0,d4
		rts	
; ===========================================================================

play01_ChkGhost:
		cmpi.b	#$41,d4		; is the item a	ghost block?
		bne.b	play01_ChkGhostTag
		move.b	#1,$3A(a0)	; mark the ghost block as "passed"

play01_ChkGhostTag:
		cmpi.b	#$4A,d4		; is the item a	switch for ghost blocks?
		bne.b	play01_NoGhost
		cmpi.b	#1,$3A(a0)	; have the ghost blocks	been passed?
		bne.b	play01_NoGhost	; if not, branch
		move.b	#2,$3A(a0)	; mark the ghost blocks	as "solid"

play01_NoGhost:
		moveq	#-1,d4
		rts	
; ===========================================================================

play01_MakeGhostSolid:
		cmpi.b	#2,$3A(a0)	; is the ghost marked as "solid"?
		bne.b	play01_GhostNotSolid ; if not, branch
		lea	($FF1020).l,a1
		moveq	#$3F,d1

play01_GhostLoop2:
		moveq	#$3F,d2

play01_GhostLoop:
		cmpi.b	#$41,(a1)	; is the item a	ghost block?
		bne.b	play01_NoReplace	; if not, branch
		move.b	#$2C,(a1)	; replace ghost	block with a solid block

play01_NoReplace:
		addq.w	#1,a1
		dbra	d2,play01_GhostLoop
		lea	$40(a1),a1
		dbra	d1,play01_GhostLoop2

play01_GhostNotSolid:
		clr.b	$3A(a0)
		moveq	#0,d4
		rts	
; End of function play01_ChkItems


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


play01_ChkItems2:			; XREF: play01_Display
		move.b	$30(a0),d0
		bne.b	play01_ChkBumper
		subq.b	#1,$36(a0)
		bpl.b	loc_1BEA0
		move.b	#0,$36(a0)

loc_1BEA0:
		subq.b	#1,$37(a0)
		bpl.b	locret_1BEAC
		move.b	#0,$37(a0)

locret_1BEAC:
		rts	
; ===========================================================================

play01_ChkBumper:
		cmpi.b	#$25,d0		; is the item a	bumper?
		bne.b	play01_GOAL
		move.l	$32(a0),d1
		subi.l	#$FF0001,d1
		move.w	d1,d2
		andi.w	#$7F,d1
		mulu.w	#$18,d1
		subi.w	#$14,d1
		lsr.w	#7,d2
		andi.w	#$7F,d2
		mulu.w	#$18,d2
		subi.w	#$44,d2
		sub.w	8(a0),d1
		sub.w	$C(a0),d2
		jsr	(atan).l
		jsr	(sinset).l
		muls.w	#-$700,d1
		asr.l	#8,d1
		move.w	d1,$10(a0)
		muls.w	#-$700,d0
		asr.l	#8,d0
		move.w	d0,$12(a0)
		bset	#1,cddat(a0)
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_BumpSnd
		move.b	#2,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

play01_BumpSnd:
		move.w	#$B4,d0
		jmp	(soundset).l ;	play bumper sound
; ===========================================================================

play01_GOAL:
		cmpi.b	#$27,d0		; is the item a	"GOAL"?
		bne.b	play01_UPblock
		addq.b	#2,r_no0(a0)	; run routine "play01_ExitStage"
		move.w	#$A8,d0		; change item
		jsr	(soundset).l ;	play "GOAL" sound
		rts	
; ===========================================================================

play01_UPblock:
		cmpi.b	#$29,d0		; is the item an "UP" block?
		bne.b	play01_DOWNblock
		tst.b	$36(a0)
		bne.w	play01_NoGlass
		move.b	#$1E,$36(a0)
		btst	#6,($FFFFF783).w
		beq.b	play01_UPsnd
		asl	rotspd	; increase stage rotation speed
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$2A,(a1)	; change item to a "DOWN" block

play01_UPsnd:
		move.w	#$A9,d0
		jmp	(soundset).l ;	play up/down sound
; ===========================================================================

play01_DOWNblock:
		cmpi.b	#$2A,d0		; is the item a	"DOWN" block?
		bne.b	play01_Rblock
		tst.b	$36(a0)
		bne.w	play01_NoGlass
		move.b	#$1E,$36(a0)
		btst	#6,($FFFFF783).w
		bne.b	play01_DOWNsnd
		asr	rotspd	; reduce stage rotation	speed
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.b	#$29,(a1)	; change item to an "UP" block

play01_DOWNsnd:
		move.w	#$A9,d0
		jmp	(soundset).l ;	play up/down sound
; ===========================================================================

play01_Rblock:
		cmpi.b	#$2B,d0		; is the item an "R" block?
		bne.b	play01_ChkGlass
		tst.b	$37(a0)
		bne.w	play01_NoGlass
		move.b	#$1E,$37(a0)
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_RevStage
		move.b	#4,(a2)
		move.l	$32(a0),d0
		subq.l	#1,d0
		move.l	d0,4(a2)

play01_RevStage:
		neg.w	rotspd	; reverse stage	rotation
		move.w	#$A9,d0
		jmp	(soundset).l ;	play sound
; ===========================================================================

play01_ChkGlass:
		cmpi.b	#$2D,d0		; is the item a	glass block?
		beq.b	play01_Glass	; if yes, branch
		cmpi.b	#$2E,d0
		beq.b	play01_Glass
		cmpi.b	#$2F,d0
		beq.b	play01_Glass
		cmpi.b	#$30,d0
		bne.b	play01_NoGlass	; if not, branch

play01_Glass:
		bsr.w	SS_RemoveCollectedItem
		bne.b	play01_GlassSnd
		move.b	#6,(a2)
		movea.l	$32(a0),a1
		subq.l	#1,a1
		move.l	a1,4(a2)
		move.b	(a1),d0
		addq.b	#1,d0		; change glass type when touched
		cmpi.b	#$30,d0
		bls.b	play01_GlassUpdate ; if glass is	still there, branch
		clr.b	d0		; remove the glass block when it's destroyed

play01_GlassUpdate:
		move.b	d0,4(a2)	; update the stage layout

play01_GlassSnd:
		move.w	#$BA,d0
		jmp	(soundset).l ;	play glass block sound
; ===========================================================================

play01_NoGlass:
		rts	
; End of function play01_ChkItems2

; ===========================================================================
; ---------------------------------------------------------------------------
; Object 10 - blank
; ---------------------------------------------------------------------------

play02:					; XREF: act_tbl
		rts	
; ---------------------------------------------------------------------------
; Subroutine to	animate	level graphics
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


efectwrt:				; XREF: Demo_Time; loc_F54
		tst.w	pauseflag	; is the game paused?
		bne.b	AniArt_Pause	; if yes, branch
		lea	($C00000).l,a6
		bsr.w	AniArt_GiantRing
		moveq	#0,d0
		move.b	stageno,d0
		add.w	d0,d0
		move.w	AniArt_Index(pc,d0.w),d0
		jmp	AniArt_Index(pc,d0.w)
; ===========================================================================

AniArt_Pause:
		rts	
; End of function efectwrt

; ===========================================================================
AniArt_Index:	dc.w AniArt_GHZ-AniArt_Index, AniArt_none-AniArt_Index
		dc.w AniArt_MZ-AniArt_Index, AniArt_none-AniArt_Index
		dc.w AniArt_none-AniArt_Index, AniArt_SBZ-AniArt_Index
		dc.w AniArt_Ending-AniArt_Index
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Green Hill
; ---------------------------------------------------------------------------

AniArt_GHZ:				; XREF: AniArt_Index
		subq.b	#1,($FFFFF7B1).w
		bpl.b	loc_1C08A
		move.b	#5,($FFFFF7B1).w ; time	to display each	frame for
		lea	(Art_GhzWater).l,a1 ; load waterfall patterns
		move.b	($FFFFF7B0).w,d0
		addq.b	#1,($FFFFF7B0).w
		andi.w	#1,d0
		beq.b	loc_1C078
		lea	$100(a1),a1	; load next frame

loc_1C078:
		move.l	#$6F000001,($C00004).l ; VRAM address
		move.w	#7,d1		; number of 8x8	tiles
		bra.w	LoadTiles
; ===========================================================================

loc_1C08A:
		subq.b	#1,($FFFFF7B3).w
		bpl.b	loc_1C0C0
		move.b	#$F,($FFFFF7B3).w
		lea	(Art_GhzFlower1).l,a1 ;	load big flower	patterns
		move.b	($FFFFF7B2).w,d0
		addq.b	#1,($FFFFF7B2).w
		andi.w	#1,d0
		beq.b	loc_1C0AE
		lea	$200(a1),a1

loc_1C0AE:
		move.l	#$6B800001,($C00004).l
		move.w	#$F,d1
		bra.w	LoadTiles
; ===========================================================================

loc_1C0C0:
		subq.b	#1,($FFFFF7B5).w
		bpl.b	locret_1C10C
		move.b	#7,($FFFFF7B5).w
		move.b	($FFFFF7B4).w,d0
		addq.b	#1,($FFFFF7B4).w
		andi.w	#3,d0
		move.b	byte_1C10E(pc,d0.w),d0
		btst	#0,d0
		bne.b	loc_1C0E8
		move.b	#$7F,($FFFFF7B5).w

loc_1C0E8:
		lsl.w	#7,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		move.l	#$6D800001,($C00004).l
		lea	(Art_GhzFlower2).l,a1 ;	load small flower patterns
		lea	(a1,d0.w),a1
		move.w	#$B,d1
		bsr.w	LoadTiles

locret_1C10C:
		rts	
; ===========================================================================
byte_1C10E:	dc.b 0,	1, 2, 1
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Marble
; ---------------------------------------------------------------------------

AniArt_MZ:				; XREF: AniArt_Index
		subq.b	#1,($FFFFF7B1).w
		bpl.b	loc_1C150
		move.b	#$13,($FFFFF7B1).w
		lea	(Art_MzLava1).l,a1 ; load lava surface patterns
		moveq	#0,d0
		move.b	($FFFFF7B0).w,d0
		addq.b	#1,d0
		cmpi.b	#3,d0
		bne.b	loc_1C134
		moveq	#0,d0

loc_1C134:
		move.b	d0,($FFFFF7B0).w
		mulu.w	#$100,d0
		adda.w	d0,a1
		move.l	#$5C400001,($C00004).l
		move.w	#7,d1
		bsr.w	LoadTiles

loc_1C150:
		subq.b	#1,($FFFFF7B3).w
		bpl.b	loc_1C1AE
		move.b	#1,($FFFFF7B3).w
		moveq	#0,d0
		move.b	($FFFFF7B0).w,d0
		lea	(Art_MzLava2).l,a4 ; load lava patterns
		ror.w	#7,d0
		adda.w	d0,a4
		move.l	#$5A400001,($C00004).l
		moveq	#0,d3
		move.b	($FFFFF7B2).w,d3
		addq.b	#1,($FFFFF7B2).w
		move.b	($FFFFFE68).w,d3
		move.w	#3,d2

loc_1C188:
		move.w	d3,d0
		add.w	d0,d0
		andi.w	#$1E,d0
		lea	(AniArt_MZextra).l,a3
		move.w	(a3,d0.w),d0
		lea	(a3,d0.w),a3
		movea.l	a4,a1
		move.w	#$1F,d1
		jsr	(a3)
		addq.w	#4,d3
		dbra	d2,loc_1C188
		rts	
; ===========================================================================

loc_1C1AE:
		subq.b	#1,($FFFFF7B5).w
		bpl.w	locret_1C1EA
		move.b	#7,($FFFFF7B5).w
		lea	(Art_MzTorch).l,a1 ; load torch	patterns
		moveq	#0,d0
		move.b	($FFFFF7B6).w,d0
		addq.b	#1,($FFFFF7B6).w
		andi.b	#3,($FFFFF7B6).w
		mulu.w	#$C0,d0
		adda.w	d0,a1
		move.l	#$5E400001,($C00004).l
		move.w	#5,d1
		bra.w	LoadTiles
; ===========================================================================

locret_1C1EA:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - Scrap Brain
; ---------------------------------------------------------------------------

AniArt_SBZ:				; XREF: AniArt_Index
		tst.b	($FFFFF7B4).w
		beq.b	loc_1C1F8
		subq.b	#1,($FFFFF7B4).w
		bra.b	loc_1C250
; ===========================================================================

loc_1C1F8:
		subq.b	#1,($FFFFF7B1).w
		bpl.b	loc_1C250
		move.b	#7,($FFFFF7B1).w
		lea	(Art_SbzSmoke).l,a1 ; load smoke patterns
		move.l	#$49000002,($C00004).l
		move.b	($FFFFF7B0).w,d0
		addq.b	#1,($FFFFF7B0).w
		andi.w	#7,d0
		beq.b	loc_1C234
		subq.w	#1,d0
		mulu.w	#$180,d0
		lea	(a1,d0.w),a1
		move.w	#$B,d1
		bra.w	LoadTiles
; ===========================================================================

loc_1C234:
		move.b	#$B4,($FFFFF7B4).w

loc_1C23A:
		move.w	#5,d1
		bsr.w	LoadTiles
		lea	(Art_SbzSmoke).l,a1
		move.w	#5,d1
		bra.w	LoadTiles
; ===========================================================================

loc_1C250:
		tst.b	($FFFFF7B5).w
		beq.b	loc_1C25C
		subq.b	#1,($FFFFF7B5).w
		bra.b	locret_1C2A0
; ===========================================================================

loc_1C25C:
		subq.b	#1,($FFFFF7B3).w
		bpl.b	locret_1C2A0
		move.b	#7,($FFFFF7B3).w
		lea	(Art_SbzSmoke).l,a1
		move.l	#$4A800002,($C00004).l
		move.b	($FFFFF7B2).w,d0
		addq.b	#1,($FFFFF7B2).w
		andi.w	#7,d0
		beq.b	loc_1C298
		subq.w	#1,d0
		mulu.w	#$180,d0
		lea	(a1,d0.w),a1
		move.w	#$B,d1
		bra.w	LoadTiles
; ===========================================================================

loc_1C298:
		move.b	#$78,($FFFFF7B5).w
		bra.b	loc_1C23A
; ===========================================================================

locret_1C2A0:
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - ending sequence
; ---------------------------------------------------------------------------

AniArt_Ending:				; XREF: AniArt_Index
		subq.b	#1,($FFFFF7B3).w
		bpl.b	loc_1C2F4
		move.b	#7,($FFFFF7B3).w
		lea	(Art_GhzFlower1).l,a1 ;	load big flower	patterns
		lea	($FFFF9400).w,a2
		move.b	($FFFFF7B2).w,d0
		addq.b	#1,($FFFFF7B2).w
		andi.w	#1,d0
		beq.b	loc_1C2CE
		lea	$200(a1),a1
		lea	$200(a2),a2

loc_1C2CE:
		move.l	#$6B800001,($C00004).l
		move.w	#$F,d1
		bsr.w	LoadTiles
		movea.l	a2,a1
		move.l	#$72000001,($C00004).l
		move.w	#$F,d1
		bra.w	LoadTiles
; ===========================================================================

loc_1C2F4:
		subq.b	#1,($FFFFF7B5).w
		bpl.b	loc_1C33C
		move.b	#7,($FFFFF7B5).w
		move.b	($FFFFF7B4).w,d0
		addq.b	#1,($FFFFF7B4).w
		andi.w	#7,d0
		move.b	byte_1C334(pc,d0.w),d0
		lsl.w	#7,d0
		move.w	d0,d1
		add.w	d0,d0
		add.w	d1,d0
		move.l	#$6D800001,($C00004).l
		lea	(Art_GhzFlower2).l,a1 ;	load small flower patterns
		lea	(a1,d0.w),a1
		move.w	#$B,d1
		bra.w	LoadTiles
; ===========================================================================
byte_1C334:	dc.b 0,	0, 0, 1, 2, 2, 2, 1
; ===========================================================================

loc_1C33C:
		subq.b	#1,($FFFFF7B9).w
		bpl.b	loc_1C37A
		move.b	#$E,($FFFFF7B9).w
		move.b	($FFFFF7B8).w,d0
		addq.b	#1,($FFFFF7B8).w
		andi.w	#3,d0
		move.b	byte_1C376(pc,d0.w),d0
		lsl.w	#8,d0
		add.w	d0,d0
		move.l	#$70000001,($C00004).l
		lea	($FFFF9800).w,a1 ; load	special	flower patterns	(from RAM)
		lea	(a1,d0.w),a1
		move.w	#$F,d1
		bra.w	LoadTiles
; ===========================================================================
byte_1C376:	dc.b 0,	1, 2, 1
; ===========================================================================

loc_1C37A:
		subq.b	#1,($FFFFF7BB).w
		bpl.b	locret_1C3B4
		move.b	#$B,($FFFFF7BB).w
		move.b	($FFFFF7BA).w,d0
		addq.b	#1,($FFFFF7BA).w
		andi.w	#3,d0
		move.b	byte_1C376(pc,d0.w),d0
		lsl.w	#8,d0
		add.w	d0,d0
		move.l	#$68000001,($C00004).l
		lea	($FFFF9E00).w,a1 ; load	special	flower patterns	(from RAM)
		lea	(a1,d0.w),a1
		move.w	#$F,d1
		bra.w	LoadTiles
; ===========================================================================

locret_1C3B4:
		rts	
; ===========================================================================

AniArt_none:				; XREF: AniArt_Index
		rts	

; ---------------------------------------------------------------------------
; Subroutine to	load (d1 - 1) 8x8 tiles
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


LoadTiles:
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		move.l	(a1)+,(a6)
		dbra	d1,LoadTiles
		rts	
; End of function LoadTiles

; ===========================================================================
; ---------------------------------------------------------------------------
; Animated pattern routine - more Marble Zone
; ---------------------------------------------------------------------------
AniArt_MZextra:	dc.w loc_1C3EE-AniArt_MZextra, loc_1C3FA-AniArt_MZextra
		dc.w loc_1C410-AniArt_MZextra, loc_1C41E-AniArt_MZextra
		dc.w loc_1C434-AniArt_MZextra, loc_1C442-AniArt_MZextra
		dc.w loc_1C458-AniArt_MZextra, loc_1C466-AniArt_MZextra
		dc.w loc_1C47C-AniArt_MZextra, loc_1C48A-AniArt_MZextra
		dc.w loc_1C4A0-AniArt_MZextra, loc_1C4AE-AniArt_MZextra
		dc.w loc_1C4C4-AniArt_MZextra, loc_1C4D2-AniArt_MZextra
		dc.w loc_1C4E8-AniArt_MZextra, loc_1C4FA-AniArt_MZextra
; ===========================================================================

loc_1C3EE:				; XREF: AniArt_MZextra
		move.l	(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C3EE
		rts	
; ===========================================================================

loc_1C3FA:				; XREF: AniArt_MZextra
		move.l	2(a1),d0
		move.b	1(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C3FA
		rts	
; ===========================================================================

loc_1C410:				; XREF: AniArt_MZextra
		move.l	2(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C410
		rts	
; ===========================================================================

loc_1C41E:				; XREF: AniArt_MZextra
		move.l	4(a1),d0
		move.b	3(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C41E
		rts	
; ===========================================================================

loc_1C434:				; XREF: AniArt_MZextra
		move.l	4(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C434
		rts	
; ===========================================================================

loc_1C442:				; XREF: AniArt_MZextra
		move.l	6(a1),d0
		move.b	5(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C442
		rts	
; ===========================================================================

loc_1C458:				; XREF: AniArt_MZextra
		move.l	6(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C458
		rts	
; ===========================================================================

loc_1C466:				; XREF: AniArt_MZextra
		move.l	8(a1),d0
		move.b	7(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C466
		rts	
; ===========================================================================

loc_1C47C:				; XREF: AniArt_MZextra
		move.l	8(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C47C
		rts	
; ===========================================================================

loc_1C48A:				; XREF: AniArt_MZextra
		move.l	$A(a1),d0
		move.b	9(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C48A
		rts	
; ===========================================================================

loc_1C4A0:				; XREF: AniArt_MZextra
		move.l	$A(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4A0
		rts	
; ===========================================================================

loc_1C4AE:				; XREF: AniArt_MZextra
		move.l	$C(a1),d0
		move.b	$B(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4AE
		rts	
; ===========================================================================

loc_1C4C4:				; XREF: AniArt_MZextra
		move.l	$C(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4C4
		rts	
; ===========================================================================

loc_1C4D2:				; XREF: AniArt_MZextra
		move.l	$C(a1),d0
		rol.l	#8,d0
		move.b	0(a1),d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4D2
		rts	
; ===========================================================================

loc_1C4E8:				; XREF: AniArt_MZextra
		move.w	$E(a1),(a6)
		move.w	0(a1),(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4E8
		rts	
; ===========================================================================

loc_1C4FA:				; XREF: AniArt_MZextra
		move.l	0(a1),d0
		move.b	$F(a1),d0
		ror.l	#8,d0
		move.l	d0,(a6)
		lea	$10(a1),a1
		dbra	d1,loc_1C4FA
		rts	

; ---------------------------------------------------------------------------
; Animated pattern routine - giant ring
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


AniArt_GiantRing:			; XREF: efectwrt
		tst.w	($FFFFF7BE).w
		bne.b	loc_1C518
		rts	
; ===========================================================================

loc_1C518:
		subi.w	#$1C0,($FFFFF7BE).w
		lea	(bigringcg).l,a1 ; load giant	ring patterns
		moveq	#0,d0
		move.w	($FFFFF7BE).w,d0
		lea	(a1,d0.w),a1
		addi.w	#$8000,d0
		lsl.l	#2,d0
		lsr.w	#2,d0
		ori.w	#$4000,d0
		swap	d0
		move.l	d0,4(a6)
		move.w	#$D,d1
		bra.w	LoadTiles
; End of function AniArt_GiantRing

; ===========================================================================

		include	"SCORE.ASM"
		include	"EDIT.ASM"

; ---------------------------------------------------------------------------
; Main level load blocks
; ---------------------------------------------------------------------------
MainLoadBlocks:
	include "_inc\Main level load blocks.asm"

divdevtbl:
		dc.w	ddev00-divdevtbl
		dc.w	ddev01-divdevtbl
		dc.w	ddev02-divdevtbl
		dc.w	ddev03-divdevtbl
		dc.w	ddev04-divdevtbl
		dc.w	ddev05-divdevtbl
		dc.w	ddev06-divdevtbl
		dc.w	ddev07-divdevtbl
		dc.w	ddev08-divdevtbl
		dc.w	ddev09-divdevtbl
		dc.w	ddev10-divdevtbl
		dc.w	ddev11-divdevtbl
		dc.w	ddev12-divdevtbl
		dc.w	ddev13-divdevtbl
		dc.w	ddev14-divdevtbl
		dc.w	ddev15-divdevtbl
		dc.w	ddev16-divdevtbl
		dc.w	ddev17-divdevtbl
		dc.w	ddev18-divdevtbl
		dc.w	ddev19-divdevtbl
		dc.w	ddev20-divdevtbl
		dc.w	ddev21-divdevtbl
		dc.w	ddev22-divdevtbl
		dc.w	ddev23-divdevtbl
		dc.w	ddev24-divdevtbl
		dc.w	ddev25-divdevtbl
		dc.w	ddev26-divdevtbl
		dc.w	ddev27-divdevtbl
		dc.w	ddev28-divdevtbl
		dc.w	ddev29-divdevtbl
		dc.w	ddev30-divdevtbl
		dc.w	ddev31-divdevtbl
ddev00:
		dc.w 4
		dc.l savecg
		dc.w $F400
		dc.l scorecg
		dc.w $D940
		dc.l playnocg
		dc.w $FA80
		dc.l ringcg
		dc.w $F640
		dc.l tencg
		dc.w $F2E0

ddev01:	dc.w 2
		dc.l itemcg
		dc.w $D000
		dc.l Nem_Shield
		dc.w $A820
		dc.l Nem_Stars
		dc.w $AB80

ddev02:	dc.w 0
		dc.l Nem_Explode
		dc.w $B400

ddev03:	dc.w 0
		dc.l overcg
		dc.w $ABC0

ddev04:	dc.w $B
		dc.l Nem_GHZ_1st	; GHZ main patterns
		dc.w 0
		dc.l Nem_GHZ_2nd	; GHZ secondary	patterns
		dc.w $39A0
		dc.l Nem_Stalk		; flower stalk
		dc.w $6B00
		dc.l Nem_PplRock	; purple rock
		dc.w $7A00
		dc.l Nem_Crabmeat	; crabmeat enemy
		dc.w $8000
		dc.l Nem_Buzz		; buzz bomber enemy
		dc.w $8880
		dc.l Nem_Chopper	; chopper enemy
		dc.w $8F60
		dc.l Nem_Newtron	; newtron enemy
		dc.w $9360
		dc.l Nem_Motobug	; motobug enemy
		dc.w $9E00
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660

ddev05:	dc.w 5
		dc.l Nem_Swing		; swinging platform
		dc.w $7000
		dc.l Nem_Bridge		; bridge
		dc.w $71C0
		dc.l Nem_SpikePole	; spiked pole
		dc.w $7300
		dc.l Nem_Ball		; giant	ball
		dc.w $7540
		dc.l Nem_GhzWall1	; breakable wall
		dc.w $A1E0
		dc.l Nem_GhzWall2	; normal wall
		dc.w $6980

ddev06:		dc.w $B
		dc.l Nem_LZ		; LZ main patterns
		dc.w 0
		dc.l Nem_LzBlock1	; block
		dc.w $3C00
		dc.l Nem_LzBlock2	; blocks
		dc.w $3E00
		dc.l Nem_Splash		; waterfalls and splash
		dc.w $4B20
		dc.l Nem_Water		; water	surface
		dc.w $6000
		dc.l Nem_LzSpikeBall	; spiked ball
		dc.w $6200
		dc.l Nem_FlapDoor	; flapping door
		dc.w $6500
		dc.l Nem_Bubbles	; bubbles and numbers
		dc.w $6900
		dc.l Nem_LzBlock3	; block
		dc.w $7780
		dc.l Nem_LzDoor1	; vertical door
		dc.w $7880
		dc.l Nem_Harpoon	; harpoon
		dc.w $7980
		dc.l Nem_Burrobot	; burrobot enemy
		dc.w $94C0

ddev07:	dc.w $C
		dc.l Nem_LzPole		; pole that breaks
		dc.w $7BC0
		dc.l Nem_LzDoor2	; large	horizontal door
		dc.w $7CC0
		dc.l Nem_LzWheel	; wheel
		dc.w $7EC0
		dc.l Nem_Gargoyle	; gargoyle head
		dc.w $5D20
		dc.l Nem_LzSonic	; Sonic	holding	his breath
		dc.w $8800
		dc.l Nem_LzPlatfm	; rising platform
		dc.w $89E0
		dc.l Nem_Orbinaut	; orbinaut enemy
		dc.w $8CE0
		dc.l Nem_Jaws		; jaws enemy
		dc.w $90C0
		dc.l Nem_LzSwitch	; switch
		dc.w $A1E0
		dc.l Nem_Cork		; cork block
		dc.w $A000
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660

ddev08:		dc.w 9
		dc.l Nem_MZ		; MZ main patterns
		dc.w 0
		dc.l Nem_MzMetal	; metal	blocks
		dc.w $6000
		dc.l Nem_MzFire		; fireballs
		dc.w $68A0
		dc.l Nem_Swing		; swinging platform
		dc.w $7000
		dc.l Nem_MzGlass	; green	glassy block
		dc.w $71C0
		dc.l Nem_Lava		; lava
		dc.w $7500
		dc.l Nem_Buzz		; buzz bomber enemy
		dc.w $8880
		dc.l Nem_Yadrin		; yadrin enemy
		dc.w $8F60
		dc.l Nem_Basaran	; basaran enemy
		dc.w $9700
		dc.l Nem_Cater		; caterkiller enemy
		dc.w $9FE0
ddev09:	dc.w 4
		dc.l Nem_MzSwitch	; switch
		dc.w $A260
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660
		dc.l Nem_MzBlock	; green	stone block
		dc.w $5700

ddev10:	dc.w 8
		dc.l Nem_SLZ		; SLZ main patterns
		dc.w 0
		dc.l Nem_Bomb		; bomb enemy
		dc.w $8000
		dc.l Nem_Orbinaut	; orbinaut enemy
		dc.w $8520
		dc.l Nem_MzFire		; fireballs
		dc.w $9000
		dc.l Nem_SlzBlock	; block
		dc.w $9C00
		dc.l Nem_SlzWall	; breakable wall
		dc.w $A260
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660

ddev11:	dc.w 5
		dc.l Nem_Seesaw		; seesaw
		dc.w $6E80
		dc.l Nem_Fan		; fan
		dc.w $7400
		dc.l Nem_Pylon		; foreground pylon
		dc.w $7980
		dc.l Nem_SlzSwing	; swinging platform
		dc.w $7B80
		dc.l Nem_SlzCannon	; fireball launcher
		dc.w $9B00
		dc.l Nem_SlzSpike	; spikeball
		dc.w $9E00

ddev12:	dc.w 4
		dc.l Nem_SYZ		; SYZ main patterns
		dc.w 0
		dc.l Nem_Crabmeat	; crabmeat enemy
		dc.w $8000
		dc.l Nem_Buzz		; buzz bomber enemy
		dc.w $8880
		dc.l Nem_Yadrin		; yadrin enemy
		dc.w $8F60
		dc.l Nem_Roller		; roller enemy
		dc.w $9700

ddev13:	dc.w 7
		dc.l Nem_Bumper		; bumper
		dc.w $7000
		dc.l Nem_SyzSpike1	; large	spikeball
		dc.w $72C0
		dc.l Nem_SyzSpike2	; small	spikeball
		dc.w $7740
		dc.l Nem_Cater		; caterkiller enemy
		dc.w $9FE0
		dc.l Nem_LzSwitch	; switch
		dc.w $A1E0
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660

ddev14:	dc.w $B
		dc.l Nem_SBZ		; SBZ main patterns
		dc.w 0
		dc.l Nem_Stomper	; moving platform and stomper
		dc.w $5800
		dc.l Nem_SbzDoor1	; door
		dc.w $5D00
		dc.l Nem_Girder		; girder
		dc.w $5E00
		dc.l Nem_BallHog	; ball hog enemy
		dc.w $6040
		dc.l Nem_SbzWheel1	; spot on large	wheel
		dc.w $6880
		dc.l Nem_SbzWheel2	; wheel	that grabs Sonic
		dc.w $6900
		dc.l Nem_SyzSpike1	; large	spikeball
		dc.w $7220
		dc.l Nem_Cutter		; pizza	cutter
		dc.w $76A0
		dc.l Nem_FlamePipe	; flaming pipe
		dc.w $7B20
		dc.l Nem_SbzFloor	; collapsing floor
		dc.w $7EA0
		dc.l Nem_SbzBlock	; vanishing block
		dc.w $9860

ddev15:	dc.w $C
		dc.l Nem_Cater		; caterkiller enemy
		dc.w $5600
		dc.l Nem_Bomb		; bomb enemy
		dc.w $8000
		dc.l Nem_Orbinaut	; orbinaut enemy
		dc.w $8520
		dc.l Nem_SlideFloor	; floor	that slides away
		dc.w $8C00
		dc.l Nem_SbzDoor2	; horizontal door
		dc.w $8DE0
		dc.l Nem_Electric	; electric orb
		dc.w $8FC0
		dc.l Nem_TrapDoor	; trapdoor
		dc.w $9240
		dc.l Nem_SbzFloor	; collapsing floor
		dc.w $7F20
		dc.l Nem_SpinPform	; small	spinning platform
		dc.w $9BE0
		dc.l Nem_LzSwitch	; switch
		dc.w $A1E0
		dc.l Nem_Spikes		; spikes
		dc.w $A360
		dc.l jumpcg	; horizontal spring
		dc.w $A460
		dc.l jump2cg	; vertical spring
		dc.w $A660

ddev16:	dc.w 0
		dc.l Nem_TitleCard
		dc.w $B000

ddev17:	dc.w 5
		dc.l Nem_Eggman		; Eggman main patterns
		dc.w $8000
		dc.l Nem_Weapons	; Eggman's weapons
		dc.w $8D80
		dc.l Nem_Prison		; prison capsule
		dc.w $93A0
		dc.l Nem_Bomb		; bomb enemy (gets overwritten)
		dc.w $A300
		dc.l Nem_SlzSpike	; spikeball (SLZ boss)
		dc.w $A300
		dc.l Nem_Exhaust	; exhaust flame
		dc.w $A540

ddev18:	dc.w 2
		dc.l golecg	; signpost
		dc.w $D000
		dc.l btencg		; hidden bonus points
		dc.w $96C0
		dc.l bigring2cg	; giant	ring flash effect
		dc.w $8C40

ddev19:	dc.w 0
		dc.l Nem_Warp
		dc.w $A820

ddev20:	dc.w $10
		dc.l Nem_SSBgCloud	; bubble and cloud background
		dc.w 0
		dc.l Nem_SSBgFish	; bird and fish	background
		dc.w $A20
		dc.l Nem_SSWalls	; walls
		dc.w $2840
		dc.l Nem_Bumper		; bumper
		dc.w $4760
		dc.l Nem_SSGOAL		; GOAL block
		dc.w $4A20
		dc.l Nem_SSUpDown	; UP and DOWN blocks
		dc.w $4C60
		dc.l Nem_SSRBlock	; R block
		dc.w $5E00
		dc.l Nem_SS1UpBlock	; 1UP block
		dc.w $6E00
		dc.l Nem_SSEmStars	; emerald collection stars
		dc.w $7E00
		dc.l Nem_SSRedWhite	; red and white	block
		dc.w $8E00
		dc.l Nem_SSGhost	; ghost	block
		dc.w $9E00
		dc.l Nem_SSWBlock	; W block
		dc.w $AE00
		dc.l Nem_SSGlass	; glass	block
		dc.w $BE00
		dc.l Nem_SSEmerald	; emeralds
		dc.w $EE00
		dc.l Nem_SSZone1	; ZONE 1 block
		dc.w $F2E0
		dc.l Nem_SSZone2	; ZONE 2 block
		dc.w $F400
		dc.l Nem_SSZone3	; ZONE 3 block
		dc.w $F520
		dc.l Nem_SSZone4	; ZONE 4 block
		dc.w $F2E0
		dc.l Nem_SSZone5	; ZONE 5 block
		dc.w $F400
		dc.l Nem_SSZone6	; ZONE 6 block
		dc.w $F520

ddev21:	dc.w 1
		dc.l Nem_Rabbit		; rabbit
		dc.w $B000
		dc.l Nem_Flicky		; flicky
		dc.w $B240

ddev22:	dc.w 1
		dc.l Nem_BlackBird	; blackbird
		dc.w $B000
		dc.l Nem_Seal		; seal
		dc.w $B240

ddev23:	dc.w 1
		dc.l Nem_Squirrel	; squirrel
		dc.w $B000
		dc.l Nem_Seal		; seal
		dc.w $B240

ddev24:	dc.w 1
		dc.l Nem_Pig		; pig
		dc.w $B000
		dc.l Nem_Flicky		; flicky
		dc.w $B240

ddev25:	dc.w 1
		dc.l Nem_Pig		; pig
		dc.w $B000
		dc.l Nem_Chicken	; chicken
		dc.w $B240

ddev26:	dc.w 1
		dc.l Nem_Rabbit		; rabbit
		dc.w $B000
		dc.l Nem_Chicken	; chicken
		dc.w $B240

ddev27:dc.w 1
		dc.l Nem_ResultEm	; emeralds
		dc.w $A820
		dc.l Nem_MiniSonic	; mini Sonic
		dc.w $AA20

ddev28:	dc.w $E
		dc.l Nem_GHZ_1st	; GHZ main patterns
		dc.w 0
		dc.l Nem_GHZ_2nd	; GHZ secondary	patterns
		dc.w $39A0
		dc.l Nem_Stalk		; flower stalk
		dc.w $6B00
		dc.l Nem_EndFlower	; flowers
		dc.w $7400
		dc.l Nem_EndEm		; emeralds
		dc.w $78A0
		dc.l Nem_EndSonic	; Sonic
		dc.w $7C20
		dc.l Nem_EndEggman	; Eggman's death (unused)
		dc.w $A480
		dc.l Nem_Rabbit		; rabbit
		dc.w $AA60
		dc.l Nem_Chicken	; chicken
		dc.w $ACA0
		dc.l Nem_BlackBird	; blackbird
		dc.w $AE60
		dc.l Nem_Seal		; seal
		dc.w $B0A0
		dc.l Nem_Pig		; pig
		dc.w $B260
		dc.l Nem_Flicky		; flicky
		dc.w $B4A0
		dc.l Nem_Squirrel	; squirrel
		dc.w $B660
		dc.l Nem_EndStH		; "SONIC THE HEDGEHOG"
		dc.w $B8A0

ddev29:	dc.w 2
		dc.l Nem_EndEm		; emeralds
		dc.w $78A0
		dc.l Nem_TryAgain	; Eggman
		dc.w $7C20
		dc.l Nem_CreditText	; credits alphabet
		dc.w $B400

ddev30:	dc.w 2
		dc.l Nem_SbzBlock	; block
		dc.w $A300
		dc.l Nem_Sbz2Eggman	; Eggman
		dc.w $8000
		dc.l Nem_LzSwitch	; switch
		dc.w $9400

ddev31:	dc.w 4
		dc.l Nem_FzEggman	; Eggman after boss
		dc.w $7400
		dc.l Nem_FzBoss		; FZ boss
		dc.w $6000
		dc.l Nem_Eggman		; Eggman main patterns
		dc.w $8000
		dc.l Nem_Sbz2Eggman	; Eggman without ship
		dc.w $8E00
		dc.l Nem_Exhaust	; exhaust flame
		dc.w $A540

		incbin	misc\padding.bin
		even
Nem_SegaLogo:	incbin	artnem\segalogo.bin	; large Sega logo
		even
Eni_SegaLogo:	incbin	mapeni\segalogo.bin	; large Sega logo (mappings)
		even
Eni_Title:	incbin	mapeni\titlescr.bin	; title screen foreground (mappings)
		even
Nem_TitleFg:	incbin	artnem\titlefor.bin	; title screen foreground
		even
Nem_TitleSonic:	incbin	artnem\titleson.bin	; Sonic on title screen
		even
Nem_TitleTM:	incbin	artnem\titletm.bin	; TM on title screen
		even
Eni_JapNames:	incbin	mapeni\japcreds.bin	; Japanese credits (mappings)
		even
Nem_JapNames:	incbin	artnem\japcreds.bin	; Japanese credits
		even
; ---------------------------------------------------------------------------
; Sprite mappings - Sonic
; ---------------------------------------------------------------------------
playpat:
		dc.w	playsp0-playpat
		dc.w	playsp1-playpat
		dc.w	playsp2-playpat
		dc.w	playsp3-playpat
		dc.w	playsp4-playpat
		dc.w	playsp5-playpat
		dc.w	playsp6-playpat
		dc.w	playsp7-playpat
		dc.w	playsp8-playpat
		dc.w	playsp9-playpat
		dc.w	playsp10-playpat
		dc.w	playsp11-playpat
		dc.w	playsp12-playpat
		dc.w	playsp13-playpat
		dc.w	playsp14-playpat
		dc.w	byte_21391-playpat
		dc.w	byte_213AB-playpat
		dc.w	byte_213C0-playpat
		dc.w	byte_213DA-playpat
		dc.w	byte_213EF-playpat
		dc.w	byte_213FA-playpat
		dc.w	byte_21405-playpat
		dc.w	byte_2141A-playpat
		dc.w	byte_21425-playpat
		dc.w	byte_21435-playpat, byte_21454-playpat
		dc.w	byte_21473-playpat, byte_21488-playpat
		dc.w	byte_214A2-playpat, byte_214B7-playpat
		dc.w	byte_214D1-playpat, byte_214DC-playpat
		dc.w	byte_214E7-playpat, byte_214F2-playpat
		dc.w	byte_214FD-playpat, byte_21512-playpat
		dc.w	byte_21522-playpat, byte_21537-playpat
		dc.w	byte_21547-playpat, byte_21552-playpat
		dc.w	byte_2155D-playpat, byte_21568-playpat
		dc.w	byte_21573-playpat, byte_21588-playpat
		dc.w	byte_21593-playpat, byte_215A8-playpat
		dc.w	byte_215B3-playpat, byte_215B9-playpat
		dc.w	byte_215BF-playpat, byte_215C5-playpat
		dc.w	byte_215CB-playpat, byte_215D1-playpat
		dc.w	byte_215DC-playpat, byte_215E2-playpat
		dc.w	byte_215ED-playpat, byte_215F3-playpat
		dc.w	byte_215FE-playpat, byte_21613-playpat
		dc.w	byte_21628-playpat
		dc.w	byte_21638-playpat
		dc.w	byte_21648-playpat
		dc.w	byte_21658-playpat
		dc.w	byte_21663-playpat
		dc.w	byte_21673-playpat
		dc.w	byte_21683-playpat
		dc.w	byte_21693-playpat
		dc.w	byte_216A8-playpat
		dc.w	byte_216BD-playpat
		dc.w	byte_216D7-playpat
		dc.w	byte_216F1-playpat
		dc.w	byte_216FC-playpat
		dc.w	byte_2170C-playpat
		dc.w	byte_21717-playpat
		dc.w	byte_21727-playpat
		dc.w	byte_21732-playpat
		dc.w	byte_21742-playpat
		dc.w	byte_21752-playpat
		dc.w	byte_2176C-playpat
		dc.w	byte_21786-playpat
		dc.w	byte_21791-playpat
		dc.w	byte_217A1-playpat
		dc.w	byte_217A7-playpat
		dc.w	byte_217AD-playpat
		dc.w	byte_217B3-playpat
		dc.w	byte_217C3-playpat
		dc.w	byte_217D3-playpat
		dc.w	byte_217E3-playpat
		dc.w	byte_217F3-playpat
playsp0:	dc.b 0
playsp1:	dc.b 4			; standing
		dc.b $EC, 8, 0,	0, $F0
		dc.b $F4, $D, 0, 3, $F0
		dc.b 4,	8, 0, $B, $F0
		dc.b $C, 8, 0, $E, $F8
playsp2:	dc.b 3			; waiting 1
		dc.b $EC, 9, 0,	0, $F0
		dc.b $FC, 9, 0,	6, $F0
		dc.b $C, 8, 0, $C, $F8
playsp3:	dc.b 3			; waiting 2
		dc.b $EC, 9, 0,	0, $F0
		dc.b $FC, 9, 0,	6, $F0
		dc.b $C, 8, 0, $C, $F8
playsp4:	dc.b 3			; waiting 3
		dc.b $EC, 9, 0,	0, $F0
		dc.b $FC, 9, 0,	6, $F0
		dc.b $C, 8, 0, $C, $F8
playsp5:	dc.b 3			; looking up
		dc.b $EC, $A, 0, 0, $F0
		dc.b 4,	8, 0, 9, $F0
		dc.b $C, 8, 0, $C, $F8
playsp6:	dc.b 4			; walking 1-1
		dc.b $EB, $D, 0, 0, $EC
		dc.b $FB, 9, 0,	8, $EC
		dc.b $FB, 6, 0,	$E, 4
		dc.b $B, 4, 0, $14, $EC
playsp7:	dc.b 2			; walking 1-2
		dc.b $EC, $D, 0, 0, $ED
		dc.b $FC, $E, 0, 8, $F5
playsp8:	dc.b 2			; walking 1-3
		dc.b $ED, 9, 0,	0, $F3
		dc.b $FD, $A, 0, 6, $F3
playsp9:	dc.b 4			; walking 1-4
		dc.b $EB, 9, 0,	0, $F4
		dc.b $FB, 9, 0,	6, $EC
		dc.b $FB, 6, 0,	$C, 4
		dc.b $B, 4, 0, $12, $EC
playsp10:	dc.b 2			; walking 1-5
		dc.b $EC, 9, 0,	0, $F3
		dc.b $FC, $E, 0, 6, $EB
playsp11:	dc.b 3			; walking 1-6
		dc.b $ED, $D, 0, 0, $EC
		dc.b $FD, $C, 0, 8, $F4
		dc.b 5,	9, 0, $C, $F4
playsp12:	dc.b 5			; walking 2-1
		dc.b $EB, 9, 0,	0, $EB
		dc.b $EB, 6, 0,	6, 3
		dc.b $FB, 8, 0,	$C, $EB
		dc.b 3,	9, 0, $F, $F3
		dc.b $13, 0, 0,	$15, $FB
playsp13:	dc.b 6			; walking 2-2
		dc.b $EC, 9, 0,	0, $EC
		dc.b $EC, 1, 0,	6, 4
		dc.b $FC, $C, 0, 8, $EC
		dc.b 4,	9, 0, $C, $F4
		dc.b $FC, 5, 0,	$12, $C
		dc.b $F4, 0, 0,	$16, $14
playsp14:	dc.b 4			; walking 2-3
		dc.b $ED, 9, 0,	0, $ED
		dc.b $ED, 1, 0,	6, 5
		dc.b $FD, $D, 0, 8, $F5
		dc.b $D, 8, 0, $10, $FD
byte_21391:	dc.b 5			; walking 2-4
		dc.b $EB, 9, 0,	0, $EB
		dc.b $EB, 5, 0,	6, 3
		dc.b $FB, $D, 0, $A, $F3
		dc.b $B, 8, 0, $12, $F3
		dc.b $13, 4, 0,	$15, $FB
byte_213AB:	dc.b 4			; walking 2-5
		dc.b $EC, 9, 0,	0, $EC
		dc.b $EC, 1, 0,	6, 4
		dc.b $FC, $D, 0, 8, $F4
		dc.b $C, 8, 0, $10, $FC
byte_213C0:	dc.b 5			; walking 2-6
		dc.b $ED, 9, 0,	0, $ED
		dc.b $ED, 1, 0,	6, 5
		dc.b $FD, 0, 0,	8, $ED
		dc.b $FD, $D, 0, 9, $F5
		dc.b $D, 8, 0, $11, $FD
byte_213DA:	dc.b 4			; walking 3-1
		dc.b $F4, 7, 0,	0, $EB
		dc.b $EC, 9, 0,	8, $FB
		dc.b $FC, 4, 0,	$E, $FB
		dc.b 4,	9, 0, $10, $FB
byte_213EF:	dc.b 2			; walking 3-2
		dc.b $F4, 7, 0,	0, $EC
		dc.b $EC, $B, 0, 8, $FC
byte_213FA:	dc.b 2			; walking 3-3
		dc.b $F4, 6, 0,	0, $ED
		dc.b $F4, $A, 0, 6, $FD
byte_21405:	dc.b 4			; walking 3-4
		dc.b $F4, 6, 0,	0, $EB
		dc.b $EC, 9, 0,	6, $FB
		dc.b $FC, 4, 0,	$C, $FB
		dc.b 4,	9, 0, $E, $FB
byte_2141A:	dc.b 2			; walking 3-5
		dc.b $F4, 6, 0,	0, $EC
		dc.b $F4, $B, 0, 6, $FC
byte_21425:	dc.b 3			; walking 3-6
		dc.b $F4, 7, 0,	0, $ED
		dc.b $EC, 0, 0,	8, $FD
		dc.b $F4, $A, 0, 9, $FD
byte_21435:	dc.b 6			; walking 4-1
		dc.b $FD, 6, 0,	0, $EB
		dc.b $ED, 4, 0,	6, $F3
		dc.b $F5, 4, 0,	8, $EB
		dc.b $F5, $A, 0, $A, $FB
		dc.b $D, 0, 0, $13, $FB
		dc.b $FD, 0, 0,	$14, $13
byte_21454:	dc.b 6			; walking 4-2
		dc.b $FC, 6, 0,	0, $EC
		dc.b $E4, 8, 0,	6, $F4
		dc.b $EC, 4, 0,	9, $FC
		dc.b $F4, 4, 0,	$B, $EC
		dc.b $F4, $A, 0, $D, $FC
		dc.b $C, 0, 0, $16, $FC
byte_21473:	dc.b 4			; walking 4-3
		dc.b $FB, 6, 0,	0, $ED
		dc.b $F3, 4, 0,	6, $ED
		dc.b $EB, $A, 0, 8, $FD
		dc.b 3,	4, 0, $11, $FD
byte_21488:	dc.b 5			; walking 4-4
		dc.b $FD, 6, 0,	0, $EB
		dc.b $ED, 8, 0,	6, $F3
		dc.b $F5, 4, 0,	9, $EB
		dc.b $F5, $D, 0, $B, $FB
		dc.b 5,	8, 0, $13, $FB
byte_214A2:	dc.b 4			; walking 4-5
		dc.b $FC, 6, 0,	0, $EC
		dc.b $F4, 4, 0,	6, $EC
		dc.b $EC, $A, 0, 8, $FC
		dc.b 4,	4, 0, $11, $FC
byte_214B7:	dc.b 5			; walking 4-6
		dc.b $FB, 6, 0,	0, $ED
		dc.b $EB, $A, 0, 6, $FD
		dc.b $F3, 4, 0,	$F, $ED
		dc.b 3,	4, 0, $11, $FD
		dc.b $B, 0, 0, $13, $FD
byte_214D1:	dc.b 2			; running 1-1
		dc.b $EE, 9, 0,	0, $F4
		dc.b $FE, $E, 0, 6, $EC
byte_214DC:	dc.b 2			; running 1-2
		dc.b $EE, 9, 0,	0, $F4
		dc.b $FE, $E, 0, 6, $EC
byte_214E7:	dc.b 2			; running 1-3
		dc.b $EE, 9, 0,	0, $F4
		dc.b $FE, $E, 0, 6, $EC
byte_214F2:	dc.b 2			; running 1-4
		dc.b $EE, 9, 0,	0, $F4
		dc.b $FE, $E, 0, 6, $EC
byte_214FD:	dc.b 4			; running 2-1
		dc.b $EE, 9, 0,	0, $EE
		dc.b $EE, 1, 0,	6, 6
		dc.b $FE, $E, 0, 8, $F6
		dc.b $FE, 0, 0,	$14, $EE
byte_21512:	dc.b 3			; running 2-2
		dc.b $EE, 9, 0,	0, $EE
		dc.b $EE, 1, 0,	6, 6
		dc.b $FE, $E, 0, 8, $F6
byte_21522:	dc.b 4			; running 2-3
		dc.b $EE, 9, 0,	0, $EE
		dc.b $EE, 1, 0,	6, 6
		dc.b $FE, $E, 0, 8, $F6
		dc.b $FE, 0, 0,	$14, $EE
byte_21537:	dc.b 3			; running 2-4
		dc.b $EE, 9, 0,	0, $EE
		dc.b $EE, 1, 0,	6, 6
		dc.b $FE, $E, 0, 8, $F6
byte_21547:	dc.b 2			; running 3-1
		dc.b $F4, 6, 0,	0, $EE
		dc.b $F4, $B, 0, 6, $FE
byte_21552:	dc.b 2			; running 3-2
		dc.b $F4, 6, 0,	0, $EE
		dc.b $F4, $B, 0, 6, $FE
byte_2155D:	dc.b 2			; running 3-3
		dc.b $F4, 6, 0,	0, $EE
		dc.b $F4, $B, 0, 6, $FE
byte_21568:	dc.b 2			; running 3-4
		dc.b $F4, 6, 0,	0, $EE
		dc.b $F4, $B, 0, 6, $FE
byte_21573:	dc.b 4			; running 4-1
		dc.b $FA, 6, 0,	0, $EE
		dc.b $F2, 4, 0,	6, $EE
		dc.b $EA, $B, 0, 8, $FE
		dc.b $A, 0, 0, $14, $FE
byte_21588:	dc.b 2			; running 4-2
		dc.b $F2, 7, 0,	0, $EE
		dc.b $EA, $B, 0, 8, $FE
byte_21593:	dc.b 4			; running 4-3
		dc.b $FA, 6, 0,	0, $EE
		dc.b $F2, 4, 0,	6, $EE
		dc.b $EA, $B, 0, 8, $FE
		dc.b $A, 0, 0, $14, $FE
byte_215A8:	dc.b 2			; running 4-4
		dc.b $F2, 7, 0,	0, $EE
		dc.b $EA, $B, 0, 8, $FE
byte_215B3:	dc.b 1			; rolling 1
		dc.b $F0, $F, 0, 0, $F0
byte_215B9:	dc.b 1			; rolling 2
		dc.b $F0, $F, 0, 0, $F0
byte_215BF:	dc.b 1			; rolling 3
		dc.b $F0, $F, 0, 0, $F0
byte_215C5:	dc.b 1			; rolling 4
		dc.b $F0, $F, 0, 0, $F0
byte_215CB:	dc.b 1			; rolling 5
		dc.b $F0, $F, 0, 0, $F0
byte_215D1:	dc.b 2			; warped 1 (unused)
		dc.b $F4, $E, 0, 0, $EC
		dc.b $F4, 2, 0,	$C, $C
byte_215DC:	dc.b 1			; warped 2 (unused)
		dc.b $F0, $F, 0, 0, $F0
byte_215E2:	dc.b 2			; warped 3 (unused)
		dc.b $EC, $B, 0, 0, $F4
		dc.b $C, 8, 0, $C, $F4
byte_215ED:	dc.b 1			; warped 4 (unused)
		dc.b $F0, $F, 0, 0, $F0
byte_215F3:	dc.b 2			; stopping 1
		dc.b $ED, 9, 0,	0, $F0
		dc.b $FD, $E, 0, 6, $F0
byte_215FE:	dc.b 4			; stopping 2
		dc.b $ED, 9, 0,	0, $F0
		dc.b $FD, $D, 0, 6, $F0
		dc.b $D, 4, 0, $E, 0
		dc.b 5,	0, 0, $10, $E8
byte_21613:	dc.b 4			; ducking
		dc.b $F4, 4, 0,	0, $FC
		dc.b $FC, $D, 0, 2, $F4
		dc.b $C, 8, 0, $A, $F4
		dc.b 4,	0, 0, $D, $EC
byte_21628:	dc.b 3			; balancing 1
		dc.b $EC, 8, 8,	0, $E8
		dc.b $F4, 2, 8,	3, 0
		dc.b $F4, $F, 8, 6, $E0
byte_21638:	dc.b 3			; balancing 2
		dc.b $EC, $E, 8, 0, $E8
		dc.b 4,	$D, 8, $C, $E0
		dc.b $C, 0, $18, $14, 0
byte_21648:	dc.b 3
		dc.b $F4, $D, 0, 0, $FC
		dc.b $FC, 5, 0,	8, $EC
		dc.b 4,	8, 0, $C, $FC
byte_21658:	dc.b 2
		dc.b $F4, $A, 0, 0, $E8
		dc.b $F4, $A, 8, 0, 0
byte_21663:	dc.b 3
		dc.b $F4, $D, 0, 0, $E4
		dc.b $FC, 0, 0,	8, 4
		dc.b 4,	$C, 0, 9, $EC
byte_21673:	dc.b 3
		dc.b $F4, $D, 0, 0, $FC
		dc.b $FC, 5, 0,	8, $EC
		dc.b 4,	8, 0, $C, $FC
byte_21683:	dc.b 3
		dc.b $E8, $B, 0, 0, $F0
		dc.b 8,	4, 0, $C, $F8
		dc.b $10, 0, 0,	$E, $F8
byte_21693:	dc.b 4
		dc.b $F8, $E, 0, 0, $E8
		dc.b 0,	5, 0, $C, 8
		dc.b $F8, 0, 0,	$10, 8
		dc.b $F0, 0, 0,	$11, $F8
byte_216A8:	dc.b 4
		dc.b $F8, $E, 0, 0, $E8
		dc.b 0,	5, 0, $C, 8
		dc.b $F8, 0, 0,	$10, 8
		dc.b $F0, 0, 0,	$11, $F8
byte_216BD:	dc.b 5
		dc.b $E8, $A, 0, 0, $F4
		dc.b $F0, 1, 0,	9, $C
		dc.b 0,	9, 0, $B, $F4
		dc.b $10, 4, 0,	$11, $F4
		dc.b 0,	0, 0, $13, $EC
byte_216D7:	dc.b 5
		dc.b $E8, $A, 0, 0, $F4
		dc.b $E8, 1, 0,	9, $C
		dc.b 0,	9, 0, $B, $F4
		dc.b $10, 4, 0,	$11, $F4
		dc.b 0,	0, 0, $13, $EC
byte_216F1:	dc.b 2
		dc.b $ED, $A, 0, 0, $F3
		dc.b 5,	$D, 0, 9, $EB
byte_216FC:	dc.b 3
		dc.b $EC, $A, 0, 0, $F3
		dc.b 4,	8, 0, 9, $F3
		dc.b $C, 4, 0, $C, $F3
byte_2170C:	dc.b 2
		dc.b $ED, $A, 0, 0, $F3
		dc.b 5,	$D, 0, 9, $EB
byte_21717:	dc.b 3
		dc.b $EC, $A, 0, 0, $F3
		dc.b 4,	8, 0, 9, $F3
		dc.b $C, 4, 0, $C, $F3
byte_21727:	dc.b 2
		dc.b $EC, 9, 0,	0, $F0
		dc.b $FC, $E, 0, 6, $F0
byte_21732:	dc.b 3
		dc.b $EC, $A, 0, 0, $F0
		dc.b 4,	5, 0, 9, $F8
		dc.b $E4, 0, 0,	$D, $F8
byte_21742:	dc.b 3
		dc.b $E8, $D, 0, 0, $EC
		dc.b $E8, 1, 0,	8, $C
		dc.b $F8, $B, 0, $A, $F4
byte_21752:	dc.b 5
		dc.b $E8, $D, 0, 0, $EC
		dc.b $E8, 1, 0,	8, $C
		dc.b $F8, 9, 0,	$A, $F4
		dc.b 8,	$C, 0, $10, $F4
		dc.b $10, 0, 0,	$14, $F4
byte_2176C:	dc.b 5
		dc.b $E8, $D, 0, 0, $EC
		dc.b $E8, 1, 0,	8, $C
		dc.b $F8, 9, 0,	$A, $F4
		dc.b 8,	$C, 0, $10, $F4
		dc.b $10, 0, 0,	$14, $F4
byte_21786:	dc.b 2
		dc.b $EC, 8, 0,	0, $F0
		dc.b $F4, $F, 0, 3, $F0
byte_21791:	dc.b 3
		dc.b $EC, 8, 0,	0, $F0
		dc.b $F4, $E, 0, 3, $F0
		dc.b $C, 8, 0, $F, $F8
byte_217A1:	dc.b 1
		dc.b $F0, $B, 0, 0, $F4
byte_217A7:	dc.b 1
		dc.b $F4, 6, 0,	0, $F8
byte_217AD:	dc.b 1
		dc.b $F8, 1, 0,	0, $FC
byte_217B3:	dc.b 3
		dc.b $F4, $D, 8, 0, $E4
		dc.b $FC, 5, 8,	8, 4
		dc.b 4,	8, 8, $C, $EC
byte_217C3:	dc.b 3
		dc.b $F4, $D, 8, 0, $FC
		dc.b $FC, 0, 8,	8, $F4
		dc.b 4,	$C, 8, 9, $F4
byte_217D3:	dc.b 3
		dc.b $F0, $E, 0, 0, $EC
		dc.b $F8, 1, 0,	$C, $C
		dc.b 8,	$C, 0, $E, $F4
byte_217E3:	dc.b 3
		dc.b $EB, 9, 0,	0, $F4
		dc.b $FB, $E, 0, 6, $EC
		dc.b 3,	1, 0, $12, $C
byte_217F3:	dc.b 2
		dc.b $F0, $F, 0, 0, $EC
		dc.b $F8, 2, 0,	$10, $C
;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------

; ---------------------------------------------------------------------------
; Uncompressed graphics	loading	array for Sonic
; ---------------------------------------------------------------------------
playwrtpat:
	include "_inc\Sonic dynamic pattern load cues.asm"

; ---------------------------------------------------------------------------
; Uncompressed graphics	- Sonic
; ---------------------------------------------------------------------------
playcg:	incbin	artunc\sonic.bin	; Sonic
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_Smoke:	incbin	artnem\xxxsmoke.bin	; unused smoke
		even
Nem_SyzSparkle:	incbin	artnem\xxxstars.bin	; unused stars
		even
Nem_Shield:	incbin	artnem\shield.bin	; shield
		even
Nem_Stars:	incbin	artnem\invstars.bin	; invincibility stars
		even
Nem_LzSonic:	incbin	artnem\xxxlzson.bin	; unused LZ Sonic holding his breath
		even
Nem_UnkFire:	incbin	artnem\xxxfire.bin	; unused fireball
		even
Nem_Warp:	incbin	artnem\xxxflash.bin	; unused entry to special stage flash
		even
Nem_Goggle:	incbin	artnem\xxxgoggl.bin	; unused goggles
		even
; ---------------------------------------------------------------------------
; Sprite mappings - walls of the special stage
; ---------------------------------------------------------------------------
Map_SSWalls:
	include "_maps\SSwalls.asm"
; ---------------------------------------------------------------------------
; Compressed graphics - special stage
; ---------------------------------------------------------------------------
Nem_SSWalls:	incbin	artnem\sswalls.bin	; special stage walls
		even
Eni_SSBg1:	incbin	mapeni\ssbg1.bin	; special stage background (mappings)
		even
Nem_SSBgFish:	incbin	artnem\ssbg1.bin	; special stage birds and fish background
		even
Eni_SSBg2:	incbin	mapeni\ssbg2.bin	; special stage background (mappings)
		even
Nem_SSBgCloud:	incbin	artnem\ssbg2.bin	; special stage clouds background
		even
Nem_SSGOAL:	incbin	artnem\ssgoal.bin	; special stage GOAL block
		even
Nem_SSRBlock:	incbin	artnem\ssr.bin		; special stage R block
		even
Nem_SS1UpBlock:	incbin	artnem\ss1up.bin	; special stage 1UP block
		even
Nem_SSEmStars:	incbin	artnem\ssemstar.bin	; special stage stars from a collected emerald
		even
Nem_SSRedWhite:	incbin	artnem\ssredwhi.bin	; special stage red/white block
		even
Nem_SSZone1:	incbin	artnem\sszone1.bin	; special stage ZONE1 block
		even
Nem_SSZone2:	incbin	artnem\sszone2.bin	; ZONE2 block
		even
Nem_SSZone3:	incbin	artnem\sszone3.bin	; ZONE3 block
		even
Nem_SSZone4:	incbin	artnem\sszone4.bin	; ZONE4 block
		even
Nem_SSZone5:	incbin	artnem\sszone5.bin	; ZONE5 block
		even
Nem_SSZone6:	incbin	artnem\sszone6.bin	; ZONE6 block
		even
Nem_SSUpDown:	incbin	artnem\ssupdown.bin	; special stage UP/DOWN block
		even
Nem_SSEmerald:	incbin	artnem\ssemeral.bin	; special stage chaos emeralds
		even
Nem_SSGhost:	incbin	artnem\ssghost.bin	; special stage ghost block
		even
Nem_SSWBlock:	incbin	artnem\ssw.bin		; special stage W block
		even
Nem_SSGlass:	incbin	artnem\ssglass.bin	; special stage destroyable glass block
		even
Nem_ResultEm:	incbin	artnem\ssresems.bin	; chaos emeralds on special stage results screen
		even
; ---------------------------------------------------------------------------
; Compressed graphics - GHZ stuff
; ---------------------------------------------------------------------------
Nem_Stalk:	incbin	artnem\ghzstalk.bin	; GHZ flower stalk
		even
Nem_Swing:	incbin	artnem\ghzswing.bin	; GHZ swinging platform
		even
Nem_Bridge:	incbin	artnem\ghzbridg.bin	; GHZ bridge
		even
Nem_GhzUnkBlock:incbin	artnem\xxxghzbl.bin	; unused GHZ block
		even
Nem_Ball:	incbin	artnem\ghzball.bin	; GHZ giant ball
		even
Nem_Spikes:	incbin	artnem\spikes.bin	; spikes
		even
Nem_GhzLog:	incbin	artnem\xxxghzlo.bin	; unused GHZ log
		even
Nem_SpikePole:	incbin	artnem\ghzlog.bin	; GHZ spiked log
		even
Nem_PplRock:	incbin	artnem\ghzrock.bin	; GHZ purple rock
		even
Nem_GhzWall1:	incbin	artnem\ghzwall1.bin	; GHZ destroyable wall
		even
Nem_GhzWall2:	incbin	artnem\ghzwall2.bin	; GHZ normal wall
		even
; ---------------------------------------------------------------------------
; Compressed graphics - LZ stuff
; ---------------------------------------------------------------------------
Nem_Water:	incbin	artnem\lzwater.bin	; LZ water surface
		even
Nem_Splash:	incbin	artnem\lzsplash.bin	; LZ waterfalls and splashes
		even
Nem_LzSpikeBall:incbin	artnem\lzspball.bin	; LZ spiked ball on chain
		even
Nem_FlapDoor:	incbin	artnem\lzflapdo.bin	; LZ flapping door
		even
Nem_Bubbles:	incbin	artnem\lzbubble.bin	; LZ bubbles and countdown numbers
		even
Nem_LzBlock3:	incbin	artnem\lzblock3.bin	; LZ 32x16 block
		even
Nem_LzDoor1:	incbin	artnem\lzvdoor.bin	; LZ vertical door
		even
Nem_Harpoon:	incbin	artnem\lzharpoo.bin	; LZ harpoon
		even
Nem_LzPole:	incbin	artnem\lzpole.bin	; LZ pole that breaks
		even
Nem_LzDoor2:	incbin	artnem\lzhdoor.bin	; LZ large horizontal door
		even
Nem_LzWheel:	incbin	artnem\lzwheel.bin	; LZ wheel from corner of conveyor belt
		even
Nem_Gargoyle:	incbin	artnem\lzgargoy.bin	; LZ gargoyle head and spitting fire
		even
Nem_LzBlock2:	incbin	artnem\lzblock2.bin	; LZ blocks
		even
Nem_LzPlatfm:	incbin	artnem\lzptform.bin	; LZ rising platforms
		even
Nem_Cork:	incbin	artnem\lzcork.bin	; LZ cork block
		even
Nem_LzBlock1:	incbin	artnem\lzblock1.bin	; LZ 32x32 block
		even
; ---------------------------------------------------------------------------
; Compressed graphics - MZ stuff
; ---------------------------------------------------------------------------
Nem_MzMetal:	incbin	artnem\mzmetal.bin	; MZ metal blocks
		even
Nem_MzSwitch:	incbin	artnem\mzswitch.bin	; MZ switch
		even
Nem_MzGlass:	incbin	artnem\mzglassy.bin	; MZ green glassy block
		even
Nem_GhzGrass:	incbin	artnem\xxxgrass.bin	; unused grass (GHZ or MZ?)
		even
Nem_MzFire:	incbin	artnem\mzfire.bin	; MZ fireballs
		even
Nem_Lava:	incbin	artnem\mzlava.bin	; MZ lava
		even
Nem_MzBlock:	incbin	artnem\mzblock.bin	; MZ green pushable block
		even
Nem_MzUnkBlock:	incbin	artnem\xxxmzblo.bin	; MZ unused background block
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SLZ stuff
; ---------------------------------------------------------------------------
Nem_Seesaw:	incbin	artnem\slzseesa.bin	; SLZ seesaw
		even
Nem_SlzSpike:	incbin	artnem\slzspike.bin	; SLZ spikeball that sits on a seesaw
		even
Nem_Fan:	incbin	artnem\slzfan.bin	; SLZ fan
		even
Nem_SlzWall:	incbin	artnem\slzwall.bin	; SLZ smashable wall
		even
Nem_Pylon:	incbin	artnem\slzpylon.bin	; SLZ foreground pylon
		even
Nem_SlzSwing:	incbin	artnem\slzswing.bin	; SLZ swinging platform
		even
Nem_SlzBlock:	incbin	artnem\slzblock.bin	; SLZ 32x32 block
		even
Nem_SlzCannon:	incbin	artnem\slzcanno.bin	; SLZ fireball launcher cannon
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SYZ stuff
; ---------------------------------------------------------------------------
Nem_Bumper:	incbin	artnem\syzbumpe.bin	; SYZ bumper
		even
Nem_SyzSpike2:	incbin	artnem\syzsspik.bin	; SYZ small spikeball
		even
Nem_LzSwitch:	incbin	artnem\switch.bin	; LZ/SYZ/SBZ switch
		even
Nem_SyzSpike1:	incbin	artnem\syzlspik.bin	; SYZ/SBZ large spikeball
		even
; ---------------------------------------------------------------------------
; Compressed graphics - SBZ stuff
; ---------------------------------------------------------------------------
Nem_SbzWheel1:	incbin	artnem\sbzwhee1.bin	; SBZ spot on rotating wheel that Sonic runs around
		even
Nem_SbzWheel2:	incbin	artnem\sbzwhee2.bin	; SBZ wheel that grabs Sonic
		even
Nem_Cutter:	incbin	artnem\sbzcutte.bin	; SBZ pizza cutter
		even
Nem_Stomper:	incbin	artnem\sbzstomp.bin	; SBZ stomper
		even
Nem_SpinPform:	incbin	artnem\sbzpform.bin	; SBZ spinning platform
		even
Nem_TrapDoor:	incbin	artnem\sbztrapd.bin	; SBZ trapdoor
		even
Nem_SbzFloor:	incbin	artnem\sbzfloor.bin	; SBZ collapsing floor
		even
Nem_Electric:	incbin	artnem\sbzshock.bin	; SBZ electric shock orb
		even
Nem_SbzBlock:	incbin	artnem\sbzvanis.bin	; SBZ vanishing block
		even
Nem_FlamePipe:	incbin	artnem\sbzflame.bin	; SBZ flaming pipe
		even
Nem_SbzDoor1:	incbin	artnem\sbzvdoor.bin	; SBZ small vertical door
		even
Nem_SlideFloor:	incbin	artnem\sbzslide.bin	; SBZ floor that slides away
		even
Nem_SbzDoor2:	incbin	artnem\sbzhdoor.bin	; SBZ large horizontal door
		even
Nem_Girder:	incbin	artnem\sbzgirde.bin	; SBZ crushing girder
		even
; ---------------------------------------------------------------------------
; Compressed graphics - enemies
; ---------------------------------------------------------------------------
Nem_BallHog:	incbin	artnem\ballhog.bin	; ball hog
		even
Nem_Crabmeat:	incbin	artnem\crabmeat.bin	; crabmeat
		even
Nem_Buzz:	incbin	artnem\buzzbomb.bin	; buzz bomber
		even
Nem_UnkExplode:	incbin	artnem\xxxexplo.bin	; unused explosion
		even
Nem_Burrobot:	incbin	artnem\burrobot.bin	; burrobot
		even
Nem_Chopper:	incbin	artnem\chopper.bin	; chopper
		even
Nem_Jaws:	incbin	artnem\jaws.bin		; jaws
		even
Nem_Roller:	incbin	artnem\roller.bin	; roller
		even
Nem_Motobug:	incbin	artnem\motobug.bin	; moto bug
		even
Nem_Newtron:	incbin	artnem\newtron.bin	; newtron
		even
Nem_Yadrin:	incbin	artnem\yadrin.bin	; yadrin
		even
Nem_Basaran:	incbin	artnem\basaran.bin	; basaran
		even
Nem_Splats:	incbin	artnem\splats.bin	; splats
		even
Nem_Bomb:	incbin	artnem\bomb.bin		; bomb
		even
Nem_Orbinaut:	incbin	artnem\orbinaut.bin	; orbinaut
		even
Nem_Cater:	incbin	artnem\caterkil.bin	; caterkiller
		even
; ---------------------------------------------------------------------------
; Compressed graphics - various
; ---------------------------------------------------------------------------
Nem_TitleCard:	incbin	artnem\ttlcards.bin	; title cards
		even
scorecg:	incbin	artnem\hud.bin		; HUD (rings, time, score)
		even
playnocg:	incbin	artnem\lifeicon.bin	; life counter icon
		even
ringcg:	incbin	artnem\rings.bin	; rings
		even
itemcg:	incbin	artnem\monitors.bin	; monitors
		even
Nem_Explode:	incbin	artnem\explosio.bin	; explosion
		even
tencg:	incbin	artnem\points.bin	; points from destroyed enemy or object
		even
overcg:	incbin	artnem\gameover.bin	; game over / time over
		even
jumpcg:	incbin	artnem\springh.bin	; horizontal spring
		even
jump2cg:	incbin	artnem\springv.bin	; vertical spring
		even
golecg:	incbin	artnem\signpost.bin	; end of level signpost
		even
savecg:	incbin	artnem\lamppost.bin	; lamppost
		even
bigring2cg:	incbin	artnem\rngflash.bin	; flash from giant ring
		even
btencg:	incbin	artnem\bonus.bin	; hidden bonuses at end of a level
		even
; ---------------------------------------------------------------------------
; Compressed graphics - continue screen
; ---------------------------------------------------------------------------
Nem_ContSonic:	incbin	artnem\cntsonic.bin	; Sonic on continue screen
		even
Nem_MiniSonic:	incbin	artnem\cntother.bin	; mini Sonic and text on continue screen
		even
; ---------------------------------------------------------------------------
; Compressed graphics - animals
; ---------------------------------------------------------------------------
Nem_Rabbit:	incbin	artnem\rabbit.bin	; rabbit
		even
Nem_Chicken:	incbin	artnem\chicken.bin	; chicken
		even
Nem_BlackBird:	incbin	artnem\blackbrd.bin	; blackbird
		even
Nem_Seal:	incbin	artnem\seal.bin		; seal
		even
Nem_Pig:	incbin	artnem\pig.bin		; pig
		even
Nem_Flicky:	incbin	artnem\flicky.bin	; flicky
		even
Nem_Squirrel:	incbin	artnem\squirrel.bin	; squirrel
		even
; ---------------------------------------------------------------------------
; Compressed graphics - primary patterns and block mappings
; ---------------------------------------------------------------------------
Blk16_GHZ:	incbin	map16\ghz.bin
		even
Nem_GHZ_1st:	incbin	artnem\8x8ghz1.bin	; GHZ primary patterns
		even
Nem_GHZ_2nd:	incbin	artnem\8x8ghz2.bin	; GHZ secondary patterns
		even
Blk256_GHZ:	incbin	map256\ghz.bin
		even
Blk16_LZ:	incbin	map16\lz.bin
		even
Nem_LZ:		incbin	artnem\8x8lz.bin	; LZ primary patterns
		even
Blk256_LZ:	incbin	map256\lz.bin
		even
Blk16_MZ:	incbin	map16\mz.bin
		even
Nem_MZ:		incbin	artnem\8x8mz.bin	; MZ primary patterns
		even
Blk256_MZ:	incbin	map256\mz.bin
		even
Blk16_SLZ:	incbin	map16\slz.bin
		even
Nem_SLZ:	incbin	artnem\8x8slz.bin	; SLZ primary patterns
		even
Blk256_SLZ:	incbin	map256\slz.bin
		even
Blk16_SYZ:	incbin	map16\syz.bin
		even
Nem_SYZ:	incbin	artnem\8x8syz.bin	; SYZ primary patterns
		even
Blk256_SYZ:	incbin	map256\syz.bin
		even
Blk16_SBZ:	incbin	map16\sbz.bin
		even
Nem_SBZ:	incbin	artnem\8x8sbz.bin	; SBZ primary patterns
		even
Blk256_SBZ:	incbin	map256\sbz.bin
		even
; ---------------------------------------------------------------------------
; Compressed graphics - bosses and ending sequence
; ---------------------------------------------------------------------------
Nem_Eggman:	incbin	artnem\bossmain.bin	; boss main patterns
		even
Nem_Weapons:	incbin	artnem\bossxtra.bin	; boss add-ons and weapons
		even
Nem_Prison:	incbin	artnem\prison.bin	; prison capsule
		even
Nem_Sbz2Eggman:	incbin	artnem\sbz2boss.bin	; Eggman in SBZ2 and FZ
		even
Nem_FzBoss:	incbin	artnem\fzboss.bin	; FZ boss
		even
Nem_FzEggman:	incbin	artnem\fzboss2.bin	; Eggman after the FZ boss
		even
Nem_Exhaust:	incbin	artnem\bossflam.bin	; boss exhaust flame
		even
Nem_EndEm:	incbin	artnem\endemera.bin	; ending sequence chaos emeralds
		even
Nem_EndSonic:	incbin	artnem\endsonic.bin	; ending sequence Sonic
		even
Nem_TryAgain:	incbin	artnem\tryagain.bin	; ending "try again" screen
		even
Nem_EndEggman:	incbin	artnem\xxxend.bin	; unused boss sequence on ending
		even
Kos_EndFlowers:	incbin	artkos\flowers.bin	; ending sequence animated flowers
		even
Nem_EndFlower:	incbin	artnem\endflowe.bin	; ending sequence flowers
		even
Nem_CreditText:	incbin	artnem\credits.bin	; credits alphabet
		even
Nem_EndStH:	incbin	artnem\endtext.bin	; ending sequence "Sonic the Hedgehog" text
		even
		incbin	misc\padding2.bin
		even

scddirtbl:
		incbin	'SCDDIRTBL.BLT'
		align
scdtbl1:
		incbin	'SCDTBLWK.SCD'
		align
scdtbl2:
		incbin	'SCDTBLWK2.SCD'
		align
zone1scd:
		incbin	'ZONE1.BLT'
		align
zone2scd:
		incbin	'ZONE2.BLT'
		align
zone3scd:
		incbin	'ZONE3.BLT'
		align
zone4scd:
		incbin	'ZONE4.BLT'
		align
zone5scd:
		incbin	'ZONE5.BLT'
		align
zone6scd:
		incbin	'ZONE6.BLT'
		align
; ---------------------------------------------------------------------------
; Special layouts
; ---------------------------------------------------------------------------
rotmaptbl0:		incbin	sslayout\1.bin
		even
rotmaptbl1:		incbin	sslayout\2.bin
		even
rotmaptbl2:		incbin	sslayout\3.bin
		even
rotmaptbl3:		incbin	sslayout\4.bin
		even
rotmaptbl4:		incbin	sslayout\5.bin
		even
rotmaptbl5:		incbin	sslayout\6.bin
		even
; ---------------------------------------------------------------------------
; Animated uncompressed graphics
; ---------------------------------------------------------------------------
Art_GhzWater:	incbin	artunc\ghzwater.bin	; GHZ waterfall
		even
Art_GhzFlower1:	incbin	artunc\ghzflowl.bin	; GHZ large flower
		even
Art_GhzFlower2:	incbin	artunc\ghzflows.bin	; GHZ small flower
		even
Art_MzLava1:	incbin	artunc\mzlava1.bin	; MZ lava surface
		even
Art_MzLava2:	incbin	artunc\mzlava2.bin	; MZ lava
		even
Art_MzTorch:	incbin	artunc\mztorch.bin	; MZ torch in background
		even
Art_SbzSmoke:	incbin	artunc\sbzsmoke.bin	; SBZ smoke in background
		even

; ---------------------------------------------------------------------------
; Level	layout index
; ---------------------------------------------------------------------------
zonemaptbl:	dc.w Level_GHZ1-zonemaptbl, Level_GHZbg-zonemaptbl, byte_68D70-zonemaptbl
		dc.w Level_GHZ2-zonemaptbl, Level_GHZbg-zonemaptbl, byte_68E3C-zonemaptbl
		dc.w Level_GHZ3-zonemaptbl, Level_GHZbg-zonemaptbl, byte_68F84-zonemaptbl
		dc.w byte_68F88-zonemaptbl, byte_68F88-zonemaptbl, byte_68F88-zonemaptbl
		dc.w Level_LZ1-zonemaptbl, Level_LZbg-zonemaptbl, byte_69190-zonemaptbl
		dc.w Level_LZ2-zonemaptbl, Level_LZbg-zonemaptbl, byte_6922E-zonemaptbl
		dc.w Level_LZ3-zonemaptbl, Level_LZbg-zonemaptbl, byte_6934C-zonemaptbl
		dc.w Level_SBZ3-zonemaptbl, Level_LZbg-zonemaptbl, byte_6940A-zonemaptbl
		dc.w Level_MZ1-zonemaptbl, Level_MZ1bg-zonemaptbl, Level_MZ1-zonemaptbl
		dc.w Level_MZ2-zonemaptbl, Level_MZ2bg-zonemaptbl, byte_6965C-zonemaptbl
		dc.w Level_MZ3-zonemaptbl, Level_MZ3bg-zonemaptbl, byte_697E6-zonemaptbl
		dc.w byte_697EA-zonemaptbl, byte_697EA-zonemaptbl, byte_697EA-zonemaptbl
		dc.w Level_SLZ1-zonemaptbl, Level_SLZbg-zonemaptbl, byte_69B84-zonemaptbl
		dc.w Level_SLZ2-zonemaptbl, Level_SLZbg-zonemaptbl, byte_69B84-zonemaptbl
		dc.w Level_SLZ3-zonemaptbl, Level_SLZbg-zonemaptbl, byte_69B84-zonemaptbl
		dc.w byte_69B84-zonemaptbl, byte_69B84-zonemaptbl, byte_69B84-zonemaptbl
		dc.w Level_SYZ1-zonemaptbl, Level_SYZbg-zonemaptbl, byte_69C7E-zonemaptbl
		dc.w Level_SYZ2-zonemaptbl, Level_SYZbg-zonemaptbl, byte_69D86-zonemaptbl
		dc.w Level_SYZ3-zonemaptbl, Level_SYZbg-zonemaptbl, byte_69EE4-zonemaptbl
		dc.w byte_69EE8-zonemaptbl, byte_69EE8-zonemaptbl, byte_69EE8-zonemaptbl
		dc.w Level_SBZ1-zonemaptbl, Level_SBZ1bg-zonemaptbl, Level_SBZ1bg-zonemaptbl
		dc.w Level_SBZ2-zonemaptbl, Level_SBZ2bg-zonemaptbl, Level_SBZ2bg-zonemaptbl
		dc.w Level_SBZ2-zonemaptbl, Level_SBZ2bg-zonemaptbl, byte_6A2F8-zonemaptbl
		dc.w byte_6A2FC-zonemaptbl, byte_6A2FC-zonemaptbl, byte_6A2FC-zonemaptbl
		dc.w Level_End-zonemaptbl, Level_GHZbg-zonemaptbl, byte_6A320-zonemaptbl
		dc.w Level_End-zonemaptbl, Level_GHZbg-zonemaptbl, byte_6A320-zonemaptbl
		dc.w byte_6A320-zonemaptbl, byte_6A320-zonemaptbl, byte_6A320-zonemaptbl
		dc.w byte_6A320-zonemaptbl, byte_6A320-zonemaptbl, byte_6A320-zonemaptbl

Level_GHZ1:	incbin	levels\ghz1.bin
		even
byte_68D70:	dc.b 0,	0, 0, 0
Level_GHZ2:	incbin	levels\ghz2.bin
		even
byte_68E3C:	dc.b 0,	0, 0, 0
Level_GHZ3:	incbin	levels\ghz3.bin
		even
Level_GHZbg:	incbin	levels\ghzbg.bin
		even
byte_68F84:	dc.b 0,	0, 0, 0
byte_68F88:	dc.b 0,	0, 0, 0

Level_LZ1:	incbin	levels\lz1.bin
		even
Level_LZbg:	incbin	levels\lzbg.bin
		even
byte_69190:	dc.b 0,	0, 0, 0
Level_LZ2:	incbin	levels\lz2.bin
		even
byte_6922E:	dc.b 0,	0, 0, 0
Level_LZ3:	incbin	levels\lz3.bin
		even
byte_6934C:	dc.b 0,	0, 0, 0
Level_SBZ3:	incbin	levels\sbz3.bin
		even
byte_6940A:	dc.b 0,	0, 0, 0

Level_MZ1:	incbin	levels\mz1.bin
		even
Level_MZ1bg:	incbin	levels\mz1bg.bin
		even
Level_MZ2:	incbin	levels\mz2.bin
		even
Level_MZ2bg:	incbin	levels\mz2bg.bin
		even
byte_6965C:	dc.b 0,	0, 0, 0
Level_MZ3:	incbin	levels\mz3.bin
		even
Level_MZ3bg:	incbin	levels\mz3bg.bin
		even
byte_697E6:	dc.b 0,	0, 0, 0
byte_697EA:	dc.b 0,	0, 0, 0

Level_SLZ1:	incbin	levels\slz1.bin
		even
Level_SLZbg:	incbin	levels\slzbg.bin
		even
Level_SLZ2:	incbin	levels\slz2.bin
		even
Level_SLZ3:	incbin	levels\slz3.bin
		even
byte_69B84:	dc.b 0,	0, 0, 0

Level_SYZ1:	incbin	levels\syz1.bin
		even
Level_SYZbg:	incbin	levels\syzbg.bin
		even
byte_69C7E:	dc.b 0,	0, 0, 0
Level_SYZ2:	incbin	levels\syz2.bin
		even
byte_69D86:	dc.b 0,	0, 0, 0
Level_SYZ3:	incbin	levels\syz3.bin
		even
byte_69EE4:	dc.b 0,	0, 0, 0
byte_69EE8:	dc.b 0,	0, 0, 0

Level_SBZ1:	incbin	levels\sbz1.bin
		even
Level_SBZ1bg:	incbin	levels\sbz1bg.bin
		even
Level_SBZ2:	incbin	levels\sbz2.bin
		even
Level_SBZ2bg:	incbin	levels\sbz2bg.bin
		even
byte_6A2F8:	dc.b 0,	0, 0, 0
byte_6A2FC:	dc.b 0,	0, 0, 0
Level_End:	incbin	levels\ending.bin
		even
byte_6A320:	dc.b 0,	0, 0, 0

; ---------------------------------------------------------------------------
; Animated uncompressed giant ring graphics
; ---------------------------------------------------------------------------
bigringcg:	incbin	artunc\bigring.bin
		even

		incbin	misc\padding3.bin
		even

; ---------------------------------------------------------------------------
; Sprite locations index
; ---------------------------------------------------------------------------
ObjPos_Index:	dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_GHZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_MZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SLZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ3-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SYZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ2-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_FZ-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_SBZ1-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_End-ObjPos_Index, ObjPos_Null-ObjPos_Index
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
		dc.w ObjPos_LZ2pf1-ObjPos_Index, ObjPos_LZ2pf2-ObjPos_Index
		dc.w ObjPos_LZ3pf1-ObjPos_Index, ObjPos_LZ3pf2-ObjPos_Index
		dc.w ObjPos_LZ1pf1-ObjPos_Index, ObjPos_LZ1pf2-ObjPos_Index
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.w ObjPos_SBZ1pf3-ObjPos_Index, ObjPos_SBZ1pf4-ObjPos_Index
		dc.w ObjPos_SBZ1pf5-ObjPos_Index, ObjPos_SBZ1pf6-ObjPos_Index
		dc.w ObjPos_SBZ1pf1-ObjPos_Index, ObjPos_SBZ1pf2-ObjPos_Index
		dc.b $FF, $FF, 0, 0, 0,	0
ObjPos_GHZ1:	incbin	objpos\ghz1.bin
		even
ObjPos_GHZ2:	incbin	objpos\ghz2.bin
		even
ObjPos_GHZ3:	incbin	objpos\ghz3.bin
		even
ObjPos_LZ1:	incbin	objpos\lz1.bin
		even
ObjPos_LZ2:	incbin	objpos\lz2.bin
		even
ObjPos_LZ3:	incbin	objpos\lz3.bin
		even
ObjPos_SBZ3:	incbin	objpos\sbz3.bin
		even
ObjPos_LZ1pf1:	incbin	objpos\lz1pf1.bin
		even
ObjPos_LZ1pf2:	incbin	objpos\lz1pf2.bin
		even
ObjPos_LZ2pf1:	incbin	objpos\lz2pf1.bin
		even
ObjPos_LZ2pf2:	incbin	objpos\lz2pf2.bin
		even
ObjPos_LZ3pf1:	incbin	objpos\lz3pf1.bin
		even
ObjPos_LZ3pf2:	incbin	objpos\lz3pf2.bin
		even
ObjPos_MZ1:	incbin	objpos\mz1.bin
		even
ObjPos_MZ2:	incbin	objpos\mz2.bin
		even
ObjPos_MZ3:	incbin	objpos\mz3.bin
		even
ObjPos_SLZ1:	incbin	objpos\slz1.bin
		even
ObjPos_SLZ2:	incbin	objpos\slz2.bin
		even
ObjPos_SLZ3:	incbin	objpos\slz3.bin
		even
ObjPos_SYZ1:	incbin	objpos\syz1.bin
		even
ObjPos_SYZ2:	incbin	objpos\syz2.bin
		even
ObjPos_SYZ3:	incbin	objpos\syz3.bin
		even
ObjPos_SBZ1:	incbin	objpos\sbz1.bin
		even
ObjPos_SBZ2:	incbin	objpos\sbz2.bin
		even
ObjPos_FZ:	incbin	objpos\fz.bin
		even
ObjPos_SBZ1pf1:	incbin	objpos\sbz1pf1.bin
		even
ObjPos_SBZ1pf2:	incbin	objpos\sbz1pf2.bin
		even
ObjPos_SBZ1pf3:	incbin	objpos\sbz1pf3.bin
		even
ObjPos_SBZ1pf4:	incbin	objpos\sbz1pf4.bin
		even
ObjPos_SBZ1pf5:	incbin	objpos\sbz1pf5.bin
		even
ObjPos_SBZ1pf6:	incbin	objpos\sbz1pf6.bin
		even
ObjPos_End:	incbin	objpos\ending.bin
		even
ObjPos_Null:	dc.b $FF, $FF, 0, 0, 0,	0
; ---------------------------------------------------------------------------
		incbin	misc\padding4.bin
		even

Go_SoundTypes:	dc.l SoundTypes		; XREF: Sound_Play
Go_SoundD0:	dc.l SoundD0Index	; XREF: Sound_D0toDF
Go_MusicIndex:	dc.l MusicIndex		; XREF: Sound_81to9F
Go_SoundIndex:	dc.l SoundIndex		; XREF: Sound_A0toCF
off_719A0:	dc.l byte_71A94		; XREF: Sound_81to9F
Go_PSGIndex:	dc.l PSG_Index		; XREF: sub_72926
; ---------------------------------------------------------------------------
; PSG instruments used in music
; ---------------------------------------------------------------------------
PSG_Index:	dc.l PSG1, PSG2, PSG3
		dc.l PSG4, PSG5, PSG6
		dc.l PSG7, PSG8, PSG9
PSG1:		incbin	sound\psg1.bin
PSG2:		incbin	sound\psg2.bin
PSG3:		incbin	sound\psg3.bin
PSG4:		incbin	sound\psg4.bin
PSG6:		incbin	sound\psg6.bin
PSG5:		incbin	sound\psg5.bin
PSG7:		incbin	sound\psg7.bin
PSG8:		incbin	sound\psg8.bin
PSG9:		incbin	sound\psg9.bin

byte_71A94:	dc.b 7,	$72, $73, $26, $15, 8, $FF, 5
; ---------------------------------------------------------------------------
; Music	Pointers
; ---------------------------------------------------------------------------
MusicIndex:	dc.l Music81, Music82
		dc.l Music83, Music84
		dc.l Music85, Music86
		dc.l Music87, Music88
		dc.l Music89, Music8A
		dc.l Music8B, Music8C
		dc.l Music8D, Music8E
		dc.l Music8F, Music90
		dc.l Music91, Music92
		dc.l Music93
; ---------------------------------------------------------------------------
; Type of sound	being played ($90 = music; $70 = normal	sound effect)
; ---------------------------------------------------------------------------
SoundTypes:	dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$90
		dc.b $90, $90, $90, $90, $90, $90, $90,	$90, $90, $90, $90, $90, $90, $90, $90,	$80
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $68, $70, $70, $70, $60, $70,	$70
		dc.b $60, $70, $60, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $7F,	$60
		dc.b $70, $70, $70, $70, $70, $70, $70,	$70, $70, $70, $70, $70, $70, $70, $70,	$80
		dc.b $80, $80, $80, $80, $80, $80, $80,	$80, $80, $80, $80, $80, $80, $80, $80,	$90
		dc.b $90, $90, $90, $90

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71B4C:				; XREF: Vblank; Hint
		move.w	#$100,($A11100).l ; stop the Z80
		nop	
		nop	
		nop	

loc_71B5A:
		btst	#0,($A11100).l
		bne.b	loc_71B5A

		btst	#7,($A01FFD).l
		beq.b	loc_71B82
		move.w	#0,($A11100).l	; start	the Z80
		nop	
		nop	
		nop	
		nop	
		nop	
		bra.b	sub_71B4C
; ===========================================================================

loc_71B82:
		lea	($FFF000).l,a6
		clr.b	$E(a6)
		tst.b	3(a6)		; is music paused?
		bne.w	loc_71E50	; if yes, branch
		subq.b	#1,1(a6)
		bne.b	loc_71B9E
		jsr	sub_7260C(pc)

loc_71B9E:
		move.b	4(a6),d0
		beq.b	loc_71BA8
		jsr	sub_72504(pc)

loc_71BA8:
		tst.b	$24(a6)
		beq.b	loc_71BB2
		jsr	sub_7267C(pc)

loc_71BB2:
		tst.w	$A(a6)		; is music or sound being played?
		beq.b	loc_71BBC	; if not, branch
		jsr	Sound_Play(pc)

loc_71BBC:
		cmpi.b	#$80,9(a6)
		beq.b	loc_71BC8
		jsr	Sound_ChkValue(pc)

loc_71BC8:
		lea	$40(a6),a5
		tst.b	(a5)
		bpl.b	loc_71BD4
		jsr	sub_71C4E(pc)

loc_71BD4:
		clr.b	8(a6)
		moveq	#5,d7

loc_71BDA:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71BE6
		jsr	sub_71CCA(pc)

loc_71BE6:
		dbra	d7,loc_71BDA

		moveq	#2,d7

loc_71BEC:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71BF8
		jsr	sub_72850(pc)

loc_71BF8:
		dbra	d7,loc_71BEC

		move.b	#$80,$E(a6)
		moveq	#2,d7

loc_71C04:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71C10
		jsr	sub_71CCA(pc)

loc_71C10:
		dbra	d7,loc_71C04

		moveq	#2,d7

loc_71C16:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71C22
		jsr	sub_72850(pc)

loc_71C22:
		dbra	d7,loc_71C16
		move.b	#$40,$E(a6)
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71C38
		jsr	sub_71CCA(pc)

loc_71C38:
		adda.w	#$30,a5
		tst.b	(a5)
		bpl.b	loc_71C44
		jsr	sub_72850(pc)

loc_71C44:
		move.w	#0,($A11100).l	; start	the Z80
		rts	
; End of function sub_71B4C


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71C4E:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.b	locret_71CAA
		move.b	#$80,8(a6)
		movea.l	4(a5),a4

loc_71C5E:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.b	loc_71C6E
		jsr	sub_72A5A(pc)
		bra.b	loc_71C5E
; ===========================================================================

loc_71C6E:
		tst.b	d5
		bpl.b	loc_71C84
		move.b	d5,$10(a5)
		move.b	(a4)+,d5
		bpl.b	loc_71C84
		subq.w	#1,a4
		move.b	$F(a5),$E(a5)
		bra.b	loc_71C88
; ===========================================================================

loc_71C84:
		jsr	sub_71D40(pc)

loc_71C88:
		move.l	a4,4(a5)
		btst	#2,(a5)
		bne.b	locret_71CAA
		moveq	#0,d0
		move.b	$10(a5),d0
		cmpi.b	#$80,d0
		beq.b	locret_71CAA
		btst	#3,d0
		bne.b	loc_71CAC
		move.b	d0,($A01FFF).l

locret_71CAA:
		rts	
; ===========================================================================

loc_71CAC:
		subi.b	#$88,d0
		move.b	byte_71CC4(pc,d0.w),d0
		move.b	d0,($A000EA).l
		move.b	#$83,($A01FFF).l
		rts	
; End of function sub_71C4E

; ===========================================================================
byte_71CC4:	dc.b $12, $15, $1C, $1D, $FF, $FF

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CCA:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.b	loc_71CE0
		bclr	#4,(a5)
		jsr	sub_71CEC(pc)
		jsr	sub_71E18(pc)
		bra.w	loc_726E2
; ===========================================================================

loc_71CE0:
		jsr	sub_71D9E(pc)
		jsr	sub_71DC6(pc)
		bra.w	loc_71E24
; End of function sub_71CCA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71CEC:				; XREF: sub_71CCA
		movea.l	4(a5),a4
		bclr	#1,(a5)

loc_71CF4:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#-$20,d5
		bcs.b	loc_71D04
		jsr	sub_72A5A(pc)
		bra.b	loc_71CF4
; ===========================================================================

loc_71D04:
		jsr	sub_726FE(pc)
		tst.b	d5
		bpl.b	loc_71D1A
		jsr	sub_71D22(pc)
		move.b	(a4)+,d5
		bpl.b	loc_71D1A
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_71D1A:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_71CEC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D22:				; XREF: sub_71CEC
		subi.b	#$80,d5
		beq.b	loc_71D58
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_72790(pc),a0
		move.w	(a0,d5.w),d6
		move.w	d6,$10(a5)
		rts	
; End of function sub_71D22


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D40:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		move.b	d5,d0
		move.b	2(a5),d1

loc_71D46:
		subq.b	#1,d1
		beq.b	loc_71D4E
		add.b	d5,d0
		bra.b	loc_71D46
; ===========================================================================

loc_71D4E:
		move.b	d0,$F(a5)
		move.b	d0,$E(a5)
		rts	
; End of function sub_71D40

; ===========================================================================

loc_71D58:				; XREF: sub_71D22
		bset	#1,(a5)
		clr.w	$10(a5)

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D60:				; XREF: sub_71CEC; sub_72878; sub_728AC
		move.l	a4,4(a5)
		move.b	$F(a5),$E(a5)
		btst	#4,(a5)
		bne.b	locret_71D9C
		move.b	$13(a5),$12(a5)
		clr.b	$C(a5)
		btst	#3,(a5)
		beq.b	locret_71D9C
		movea.l	$14(a5),a0
		move.b	(a0)+,$18(a5)
		move.b	(a0)+,$19(a5)
		move.b	(a0)+,$1A(a5)
		move.b	(a0)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)

locret_71D9C:
		rts	
; End of function sub_71D60


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71D9E:				; XREF: sub_71CCA; sub_72850
		tst.b	$12(a5)
		beq.b	locret_71DC4
		subq.b	#1,$12(a5)
		bne.b	locret_71DC4
		bset	#1,(a5)
		tst.b	1(a5)
		bmi.w	loc_71DBE
		jsr	sub_726FE(pc)
		addq.w	#4,sp
		rts	
; ===========================================================================

loc_71DBE:
		jsr	sub_729A0(pc)
		addq.w	#4,sp

locret_71DC4:
		rts	
; End of function sub_71D9E


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71DC6:				; XREF: sub_71CCA; sub_72850
		addq.w	#4,sp
		btst	#3,(a5)
		beq.b	locret_71E16
		tst.b	$18(a5)
		beq.b	loc_71DDA
		subq.b	#1,$18(a5)
		rts	
; ===========================================================================

loc_71DDA:
		subq.b	#1,$19(a5)
		beq.b	loc_71DE2
		rts	
; ===========================================================================

loc_71DE2:
		movea.l	$14(a5),a0
		move.b	1(a0),$19(a5)
		tst.b	$1B(a5)
		bne.b	loc_71DFE
		move.b	3(a0),$1B(a5)
		neg.b	$1A(a5)
		rts	
; ===========================================================================

loc_71DFE:
		subq.b	#1,$1B(a5)
		move.b	$1A(a5),d6
		ext.w	d6
		add.w	$1C(a5),d6
		move.w	d6,$1C(a5)
		add.w	$10(a5),d6
		subq.w	#4,sp

locret_71E16:
		rts	
; End of function sub_71DC6


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_71E18:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.b	locret_71E48
		move.w	$10(a5),d6
		beq.b	loc_71E4A

loc_71E24:				; XREF: sub_71CCA
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.b	locret_71E48
		move.w	d6,d1
		lsr.w	#8,d1
		move.b	#-$5C,d0
		jsr	sub_72722(pc)
		move.b	d6,d1
		move.b	#-$60,d0
		jsr	sub_72722(pc)

locret_71E48:
		rts	
; ===========================================================================

loc_71E4A:
		bset	#1,(a5)
		rts	
; End of function sub_71E18

; ===========================================================================

loc_71E50:				; XREF: sub_71B4C
		bmi.b	loc_71E94
		cmpi.b	#2,3(a6)
		beq.w	loc_71EFE
		move.b	#2,3(a6)
		moveq	#2,d3
		move.b	#-$4C,d0
		moveq	#0,d1

loc_71E6A:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.b	#1,d0
		dbra	d3,loc_71E6A

		moveq	#2,d3
		moveq	#$28,d0

loc_71E7C:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbra	d3,loc_71E7C

		jsr	sub_729B6(pc)
		bra.w	loc_71C44
; ===========================================================================

loc_71E94:				; XREF: loc_71E50
		clr.b	3(a6)
		moveq	#$30,d3
		lea	$40(a6),a5
		moveq	#6,d4

loc_71EA0:
		btst	#7,(a5)
		beq.b	loc_71EB8
		btst	#2,(a5)
		bne.b	loc_71EB8
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EB8:
		adda.w	d3,a5
		dbra	d4,loc_71EA0

		lea	$220(a6),a5
		moveq	#2,d4

loc_71EC4:
		btst	#7,(a5)
		beq.b	loc_71EDC
		btst	#2,(a5)
		bne.b	loc_71EDC
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EDC:
		adda.w	d3,a5
		dbra	d4,loc_71EC4

		lea	$340(a6),a5
		btst	#7,(a5)
		beq.b	loc_71EFE
		btst	#2,(a5)
		bne.b	loc_71EFE
		move.b	#-$4C,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

loc_71EFE:
		bra.w	loc_71C44

; ---------------------------------------------------------------------------
; Subroutine to	play a sound or	music track
; ---------------------------------------------------------------------------

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_Play:				; XREF: sub_71B4C
		movea.l	(Go_SoundTypes).l,a0
		lea	$A(a6),a1	; load music track number
		move.b	0(a6),d3
		moveq	#2,d4

loc_71F12:
		move.b	(a1),d0		; move track number to d0
		move.b	d0,d1
		clr.b	(a1)+
		subi.b	#$81,d0
		bcs.b	loc_71F3E
		cmpi.b	#$80,9(a6)
		beq.b	loc_71F2C
		move.b	d1,$A(a6)
		bra.b	loc_71F3E
; ===========================================================================

loc_71F2C:
		andi.w	#$7F,d0
		move.b	(a0,d0.w),d2
		cmp.b	d3,d2
		bcs.b	loc_71F3E
		move.b	d2,d3
		move.b	d1,9(a6)	; set music flag

loc_71F3E:
		dbra	d4,loc_71F12

		tst.b	d3
		bmi.b	locret_71F4A
		move.b	d3,0(a6)

locret_71F4A:
		rts	
; End of function Sound_Play


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Sound_ChkValue:				; XREF: sub_71B4C
		moveq	#0,d7
		move.b	9(a6),d7
		beq.w	Sound_E4
		bpl.b	locret_71F8C
		move.b	#$80,9(a6)	; reset	music flag
		cmpi.b	#$9F,d7
		bls.w	Sound_81to9F	; music	$81-$9F
		cmpi.b	#$A0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$CF,d7
		bls.w	Sound_A0toCF	; sound	$A0-$CF
		cmpi.b	#$D0,d7
		bcs.w	locret_71F8C
		cmpi.b	#$E0,d7
		bcs.w	Sound_D0toDF	; sound	$D0-$DF
		cmpi.b	#$E4,d7
		bls.b	Sound_E0toE4	; sound	$E0-$E4

locret_71F8C:
		rts	
; ===========================================================================

Sound_E0toE4:				; XREF: Sound_ChkValue
		subi.b	#$E0,d7
		lsl.w	#2,d7
		jmp	Sound_ExIndex(pc,d7.w)
; ===========================================================================

Sound_ExIndex:
		bra.w	Sound_E0
; ===========================================================================
		bra.w	Sound_E1
; ===========================================================================
		bra.w	Sound_E2
; ===========================================================================
		bra.w	Sound_E3
; ===========================================================================
		bra.w	Sound_E4
; ===========================================================================
; ---------------------------------------------------------------------------
; Play "Say-gaa" PCM sound
; ---------------------------------------------------------------------------

Sound_E1:				; XREF: Sound_ExIndex
		move.b	#$88,($A01FFF).l
		move.w	#0,($A11100).l	; start	the Z80
		move.w	#$11,d1

loc_71FC0:
		move.w	#-1,d0

loc_71FC4:
		nop	
		dbra	d0,loc_71FC4

		dbra	d1,loc_71FC0

		addq.w	#4,sp
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Play music track $81-$9F
; ---------------------------------------------------------------------------

Sound_81to9F:				; XREF: Sound_ChkValue
		cmpi.b	#$88,d7		; is "extra life" music	played?
		bne.b	loc_72024	; if not, branch
		tst.b	$27(a6)
		bne.w	loc_721B6
		lea	$40(a6),a5
		moveq	#9,d0

loc_71FE6:
		bclr	#2,(a5)
		adda.w	#$30,a5
		dbra	d0,loc_71FE6

		lea	$220(a6),a5
		moveq	#5,d0

loc_71FF8:
		bclr	#7,(a5)
		adda.w	#$30,a5
		dbra	d0,loc_71FF8
		clr.b	0(a6)
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72012:
		move.l	(a0)+,(a1)+
		dbra	d0,loc_72012

		move.b	#$80,$27(a6)
		clr.b	0(a6)
		bra.b	loc_7202C
; ===========================================================================

loc_72024:
		clr.b	$27(a6)
		clr.b	$26(a6)

loc_7202C:
		jsr	sub_725CA(pc)
		movea.l	(off_719A0).l,a4
		subi.b	#$81,d7
		move.b	(a4,d7.w),$29(a6)
		movea.l	(Go_MusicIndex).l,a4
		lsl.w	#2,d7
		movea.l	(a4,d7.w),a4
		moveq	#0,d0
		move.w	(a4),d0
		add.l	a4,d0
		move.l	d0,$18(a6)
		move.b	5(a4),d0
		move.b	d0,$28(a6)
		tst.b	$2A(a6)
		beq.b	loc_72068
		move.b	$29(a6),d0

loc_72068:
		move.b	d0,2(a6)
		move.b	d0,1(a6)
		moveq	#0,d1
		movea.l	a4,a3
		addq.w	#6,a4
		moveq	#0,d7
		move.b	2(a3),d7
		beq.w	loc_72114
		subq.b	#1,d7
		move.b	#-$40,d1
		move.b	4(a3),d4
		moveq	#$30,d6
		move.b	#1,d5
		lea	$40(a6),a1
		lea	byte_721BA(pc),a2

loc_72098:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d1,$A(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		adda.w	d6,a1
		dbra	d7,loc_72098
		cmpi.b	#7,2(a3)
		bne.b	loc_720D8
		moveq	#$2B,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		bra.w	loc_72114
; ===========================================================================

loc_720D8:
		moveq	#$28,d0
		moveq	#6,d1
		jsr	sub_7272E(pc)
		move.b	#$42,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4A,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$46,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#$4E,d0
		moveq	#$7F,d1
		jsr	sub_72764(pc)
		move.b	#-$4A,d0
		move.b	#-$40,d1
		jsr	sub_72764(pc)

loc_72114:
		moveq	#0,d7
		move.b	3(a3),d7
		beq.b	loc_72154
		subq.b	#1,d7
		lea	$190(a6),a1
		lea	byte_721C2(pc),a2

loc_72126:
		bset	#7,(a1)
		move.b	(a2)+,1(a1)
		move.b	d4,2(a1)
		move.b	d6,$D(a1)
		move.b	d5,$E(a1)
		moveq	#0,d0
		move.w	(a4)+,d0
		add.l	a3,d0
		move.l	d0,4(a1)
		move.w	(a4)+,8(a1)
		move.b	(a4)+,d0
		move.b	(a4)+,$B(a1)
		adda.w	d6,a1
		dbra	d7,loc_72126

loc_72154:
		lea	$220(a6),a1
		moveq	#5,d7

loc_7215A:
		tst.b	(a1)
		bpl.w	loc_7217C
		moveq	#0,d0
		move.b	1(a1),d0
		bmi.b	loc_7216E
		subq.b	#2,d0
		lsl.b	#2,d0
		bra.b	loc_72170
; ===========================================================================

loc_7216E:
		lsr.b	#3,d0

loc_72170:
		lea	dword_722CC(pc),a0
		movea.l	(a0,d0.w),a0
		bset	#2,(a0)

loc_7217C:
		adda.w	d6,a1
		dbra	d7,loc_7215A

		tst.w	$340(a6)
		bpl.b	loc_7218E
		bset	#2,$100(a6)

loc_7218E:
		tst.w	$370(a6)
		bpl.b	loc_7219A
		bset	#2,$1F0(a6)

loc_7219A:
		lea	$70(a6),a5
		moveq	#5,d4

loc_721A0:
		jsr	sub_726FE(pc)
		adda.w	d6,a5
		dbra	d4,loc_721A0
		moveq	#2,d4

loc_721AC:
		jsr	sub_729A0(pc)
		adda.w	d6,a5
		dbra	d4,loc_721AC

loc_721B6:
		addq.w	#4,sp
		rts	
; ===========================================================================
byte_721BA:	dc.b 6,	0, 1, 2, 4, 5, 6, 0
		even
byte_721C2:	dc.b $80, $A0, $C0, 0
		even
; ===========================================================================
; ---------------------------------------------------------------------------
; Play normal sound effect
; ---------------------------------------------------------------------------

Sound_A0toCF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	loc_722C6
		tst.b	4(a6)
		bne.w	loc_722C6
		tst.b	$24(a6)
		bne.w	loc_722C6
		cmpi.b	#$B5,d7		; is ring sound	effect played?
		bne.b	Sound_notB5	; if not, branch
		tst.b	$2B(a6)
		bne.b	loc_721EE
		move.b	#$CE,d7		; play ring sound in left speaker

loc_721EE:
		bchg	#0,$2B(a6)	; change speaker

Sound_notB5:
		cmpi.b	#$A7,d7		; is "pushing" sound played?
		bne.b	Sound_notA7	; if not, branch
		tst.b	$2C(a6)
		bne.w	locret_722C4
		move.b	#$80,$2C(a6)

Sound_notA7:
		movea.l	(Go_SoundIndex).l,a0
		subi.b	#$A0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d1
		move.w	(a1)+,d1
		add.l	a3,d1
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72228:
		moveq	#0,d3
		move.b	1(a1),d3
		move.b	d3,d4
		bmi.b	loc_72244
		subq.w	#2,d3
		lsl.w	#2,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		bra.b	loc_7226E
; ===========================================================================

loc_72244:
		lsr.w	#3,d3
		lea	dword_722CC(pc),a5
		movea.l	(a5,d3.w),a5
		bset	#2,(a5)
		cmpi.b	#$C0,d4
		bne.b	loc_7226E
		move.b	d4,d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l
		bchg	#5,d0
		move.b	d0,($C00011).l

loc_7226E:
		movea.l	dword_722EC(pc,d3.w),a5
		movea.l	a5,a2
		moveq	#$B,d0

loc_72276:
		clr.l	(a2)+
		dbra	d0,loc_72276

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.b	loc_722A8
		move.b	#$C0,$A(a5)
		move.l	d1,$20(a5)

loc_722A8:
		dbra	d7,loc_72228

		tst.b	$250(a6)
		bpl.b	loc_722B8
		bset	#2,$340(a6)

loc_722B8:
		tst.b	$310(a6)
		bpl.b	locret_722C4
		bset	#2,$370(a6)

locret_722C4:
		rts	
; ===========================================================================

loc_722C6:
		clr.b	0(a6)
		rts	
; ===========================================================================
dword_722CC:	dc.l $FFF0D0
		dc.l 0
		dc.l $FFF100
		dc.l $FFF130
		dc.l $FFF190
		dc.l $FFF1C0
		dc.l $FFF1F0
		dc.l $FFF1F0
dword_722EC:	dc.l $FFF220
		dc.l 0
		dc.l $FFF250
		dc.l $FFF280
		dc.l $FFF2B0
		dc.l $FFF2E0
		dc.l $FFF310
		dc.l $FFF310
; ===========================================================================
; ---------------------------------------------------------------------------
; Play GHZ waterfall sound
; ---------------------------------------------------------------------------

Sound_D0toDF:				; XREF: Sound_ChkValue
		tst.b	$27(a6)
		bne.w	locret_723C6
		tst.b	4(a6)
		bne.w	locret_723C6
		tst.b	$24(a6)
		bne.w	locret_723C6
		movea.l	(Go_SoundD0).l,a0
		subi.b	#$D0,d7
		lsl.w	#2,d7
		movea.l	(a0,d7.w),a3
		movea.l	a3,a1
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,$20(a6)
		move.b	(a1)+,d5
		move.b	(a1)+,d7
		subq.b	#1,d7
		moveq	#$30,d6

loc_72348:
		move.b	1(a1),d4
		bmi.b	loc_7235A
		bset	#2,$100(a6)
		lea	$340(a6),a5
		bra.b	loc_72364
; ===========================================================================

loc_7235A:
		bset	#2,$1F0(a6)
		lea	$370(a6),a5

loc_72364:
		movea.l	a5,a2
		moveq	#$B,d0

loc_72368:
		clr.l	(a2)+
		dbra	d0,loc_72368

		move.w	(a1)+,(a5)
		move.b	d5,2(a5)
		moveq	#0,d0
		move.w	(a1)+,d0
		add.l	a3,d0
		move.l	d0,4(a5)
		move.w	(a1)+,8(a5)
		move.b	#1,$E(a5)
		move.b	d6,$D(a5)
		tst.b	d4
		bmi.b	loc_72396
		move.b	#$C0,$A(a5)

loc_72396:
		dbra	d7,loc_72348

		tst.b	$250(a6)
		bpl.b	loc_723A6
		bset	#2,$340(a6)

loc_723A6:
		tst.b	$310(a6)
		bpl.b	locret_723C6
		bset	#2,$370(a6)
		ori.b	#$1F,d4
		move.b	d4,($C00011).l
		bchg	#5,d4
		move.b	d4,($C00011).l

locret_723C6:
		rts	
; End of function Sound_ChkValue

; ===========================================================================
		dc.l $FFF100
		dc.l $FFF1F0
		dc.l $FFF250
		dc.l $FFF310
		dc.l $FFF340
		dc.l $FFF370

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut1:				; XREF: Sound_E0
		clr.b	0(a6)
		lea	$220(a6),a5
		moveq	#5,d7

loc_723EA:
		tst.b	(a5)
		bpl.w	loc_72472
		bclr	#7,(a5)
		moveq	#0,d3
		move.b	1(a5),d3
		bmi.b	loc_7243C
		jsr	sub_726FE(pc)
		cmpi.b	#4,d3
		bne.b	loc_72416
		tst.b	$340(a6)
		bpl.b	loc_72416
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.b	loc_72428
; ===========================================================================

loc_72416:
		subq.b	#2,d3
		lsl.b	#2,d3
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		movea.l	(a0,d3.w),a5
		movea.l	$18(a6),a1

loc_72428:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5
		bra.b	loc_72472
; ===========================================================================

loc_7243C:
		jsr	sub_729A0(pc)
		lea	$370(a6),a0
		cmpi.b	#$E0,d3
		beq.b	loc_7245A
		cmpi.b	#$C0,d3
		beq.b	loc_7245A
		lsr.b	#3,d3
		lea	dword_722CC(pc),a0
		movea.l	(a0,d3.w),a0

loc_7245A:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.b	loc_72472
		move.b	$1F(a0),($C00011).l

loc_72472:
		adda.w	#$30,a5
		dbra	d7,loc_723EA

		rts	
; End of function Snd_FadeOut1


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


Snd_FadeOut2:				; XREF: Sound_E0
		lea	$340(a6),a5
		tst.b	(a5)
		bpl.b	loc_724AE
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.b	loc_724AE
		jsr	loc_7270A(pc)
		lea	$100(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.b	loc_724AE
		movea.l	$18(a6),a1
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_724AE:
		lea	$370(a6),a5
		tst.b	(a5)
		bpl.b	locret_724E4
		bclr	#7,(a5)
		btst	#2,(a5)
		bne.b	locret_724E4
		jsr	loc_729A6(pc)
		lea	$1F0(a6),a5
		bclr	#2,(a5)
		bset	#1,(a5)
		tst.b	(a5)
		bpl.b	locret_724E4
		cmpi.b	#-$20,1(a5)
		bne.b	locret_724E4
		move.b	$1F(a5),($C00011).l

locret_724E4:
		rts	
; End of function Snd_FadeOut2

; ===========================================================================
; ---------------------------------------------------------------------------
; Fade out music
; ---------------------------------------------------------------------------

Sound_E0:				; XREF: Sound_ExIndex
		jsr	Snd_FadeOut1(pc)
		jsr	Snd_FadeOut2(pc)
		move.b	#3,6(a6)
		move.b	#$28,4(a6)
		clr.b	$40(a6)
		clr.b	$2A(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72504:				; XREF: sub_71B4C
		move.b	6(a6),d0
		beq.b	loc_72510
		subq.b	#1,6(a6)
		rts	
; ===========================================================================

loc_72510:
		subq.b	#1,4(a6)
		beq.w	Sound_E4
		move.b	#3,6(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_72524:
		tst.b	(a5)
		bpl.b	loc_72538
		addq.b	#1,9(a5)
		bpl.b	loc_72534
		bclr	#7,(a5)
		bra.b	loc_72538
; ===========================================================================

loc_72534:
		jsr	sub_72CB4(pc)

loc_72538:
		adda.w	#$30,a5
		dbra	d7,loc_72524

		moveq	#2,d7

loc_72542:
		tst.b	(a5)
		bpl.b	loc_72560
		addq.b	#1,9(a5)
		cmpi.b	#$10,9(a5)
		bcs.b	loc_72558
		bclr	#7,(a5)
		bra.b	loc_72560
; ===========================================================================

loc_72558:
		move.b	9(a5),d6
		jsr	sub_7296A(pc)

loc_72560:
		adda.w	#$30,a5
		dbra	d7,loc_72542

		rts	
; End of function sub_72504


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7256A:				; XREF: Sound_E4; sub_725CA
		moveq	#2,d3
		moveq	#$28,d0

loc_7256E:
		move.b	d3,d1
		jsr	sub_7272E(pc)
		addq.b	#4,d1
		jsr	sub_7272E(pc)
		dbra	d3,loc_7256E

		moveq	#$40,d0
		moveq	#$7F,d1
		moveq	#2,d4

loc_72584:
		moveq	#3,d3

loc_72586:
		jsr	sub_7272E(pc)
		jsr	sub_72764(pc)
		addq.w	#4,d0
		dbra	d3,loc_72586

		subi.b	#$F,d0
		dbra	d4,loc_72584

		rts	
; End of function sub_7256A

; ===========================================================================
; ---------------------------------------------------------------------------
; Stop music
; ---------------------------------------------------------------------------

Sound_E4:				; XREF: Sound_ChkValue; Sound_ExIndex; sub_72504
		moveq	#$2B,d0
		move.b	#$80,d1
		jsr	sub_7272E(pc)
		moveq	#$27,d0
		moveq	#0,d1
		jsr	sub_7272E(pc)
		movea.l	a6,a0
		move.w	#$E3,d0

loc_725B6:
		clr.l	(a0)+
		dbra	d0,loc_725B6

		move.b	#$80,9(a6)	; set music to $80 (silence)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_725CA:				; XREF: Sound_ChkValue
		movea.l	a6,a0
		move.b	0(a6),d1
		move.b	$27(a6),d2
		move.b	$2A(a6),d3
		move.b	$26(a6),d4
		move.w	$A(a6),d5
		move.w	#$87,d0

loc_725E4:
		clr.l	(a0)+
		dbra	d0,loc_725E4

		move.b	d1,0(a6)
		move.b	d2,$27(a6)
		move.b	d3,$2A(a6)
		move.b	d4,$26(a6)
		move.w	d5,$A(a6)
		move.b	#$80,9(a6)
		jsr	sub_7256A(pc)
		bra.w	sub_729B6
; End of function sub_725CA


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7260C:				; XREF: sub_71B4C
		move.b	2(a6),1(a6)
		lea	$4E(a6),a0
		moveq	#$30,d0
		moveq	#9,d1

loc_7261A:
		addq.b	#1,(a0)
		adda.w	d0,a0
		dbra	d1,loc_7261A

		rts	
; End of function sub_7260C

; ===========================================================================
; ---------------------------------------------------------------------------
; Speed	up music
; ---------------------------------------------------------------------------

Sound_E2:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.b	loc_7263E
		move.b	$29(a6),2(a6)
		move.b	$29(a6),1(a6)
		move.b	#$80,$2A(a6)
		rts	
; ===========================================================================

loc_7263E:
		move.b	$3C9(a6),$3A2(a6)
		move.b	$3C9(a6),$3A1(a6)
		move.b	#$80,$3CA(a6)
		rts	
; ===========================================================================
; ---------------------------------------------------------------------------
; Change music back to normal speed
; ---------------------------------------------------------------------------

Sound_E3:				; XREF: Sound_ExIndex
		tst.b	$27(a6)
		bne.b	loc_7266A
		move.b	$28(a6),2(a6)
		move.b	$28(a6),1(a6)
		clr.b	$2A(a6)
		rts	
; ===========================================================================

loc_7266A:
		move.b	$3C8(a6),$3A2(a6)
		move.b	$3C8(a6),$3A1(a6)
		clr.b	$3CA(a6)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7267C:				; XREF: sub_71B4C
		tst.b	$25(a6)
		beq.b	loc_72688
		subq.b	#1,$25(a6)
		rts	
; ===========================================================================

loc_72688:
		tst.b	$26(a6)
		beq.b	loc_726D6
		subq.b	#1,$26(a6)
		move.b	#2,$25(a6)
		lea	$70(a6),a5
		moveq	#5,d7

loc_7269E:
		tst.b	(a5)
		bpl.b	loc_726AA
		subq.b	#1,9(a5)
		jsr	sub_72CB4(pc)

loc_726AA:
		adda.w	#$30,a5
		dbra	d7,loc_7269E
		moveq	#2,d7

loc_726B4:
		tst.b	(a5)
		bpl.b	loc_726CC
		subq.b	#1,9(a5)
		move.b	9(a5),d6
		cmpi.b	#$10,d6
		bcs.b	loc_726C8
		moveq	#$F,d6

loc_726C8:
		jsr	sub_7296A(pc)

loc_726CC:
		adda.w	#$30,a5
		dbra	d7,loc_726B4
		rts	
; ===========================================================================

loc_726D6:
		bclr	#2,$40(a6)
		clr.b	$24(a6)
		rts	
; End of function sub_7267C

; ===========================================================================

loc_726E2:				; XREF: sub_71CCA
		btst	#1,(a5)
		bne.b	locret_726FC
		btst	#2,(a5)
		bne.b	locret_726FC
		moveq	#$28,d0
		move.b	1(a5),d1
		ori.b	#-$10,d1
		bra.w	sub_7272E
; ===========================================================================

locret_726FC:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_726FE:				; XREF: sub_71CEC; sub_71D9E; Sound_ChkValue; Snd_FadeOut1
		btst	#4,(a5)
		bne.b	locret_72714
		btst	#2,(a5)
		bne.b	locret_72714

loc_7270A:				; XREF: Snd_FadeOut2
		moveq	#$28,d0
		move.b	1(a5),d1
		bra.w	sub_7272E
; ===========================================================================

locret_72714:
		rts	
; End of function sub_726FE

; ===========================================================================

loc_72716:				; XREF: sub_72A5A
		btst	#2,(a5)
		bne.b	locret_72720
		bra.w	sub_72722
; ===========================================================================

locret_72720:
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72722:				; XREF: sub_71E18; sub_72C4E; sub_72CB4
		btst	#2,1(a5)
		bne.b	loc_7275A
		add.b	1(a5),d0
; End of function sub_72722


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7272E:				; XREF: loc_71E6A
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.b	sub_7272E
		move.b	d0,($A04000).l
		nop	
		nop	
		nop	

loc_72746:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.b	loc_72746

		move.b	d1,($A04001).l
		rts	
; End of function sub_7272E

; ===========================================================================

loc_7275A:				; XREF: sub_72722
		move.b	1(a5),d2
		bclr	#2,d2
		add.b	d2,d0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72764:				; XREF: loc_71E6A; Sound_ChkValue; sub_7256A; sub_72764
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.b	sub_72764
		move.b	d0,($A04002).l
		nop	
		nop	
		nop	

loc_7277C:
		move.b	($A04000).l,d2
		btst	#7,d2
		bne.b	loc_7277C

		move.b	d1,($A04003).l
		rts	
; End of function sub_72764

; ===========================================================================
word_72790:	dc.w $25E, $284, $2AB, $2D3, $2FE, $32D, $35C, $38F, $3C5
		dc.w $3FF, $43C, $47C, $A5E, $A84, $AAB, $AD3, $AFE, $B2D
		dc.w $B5C, $B8F, $BC5, $BFF, $C3C, $C7C, $125E,	$1284
		dc.w $12AB, $12D3, $12FE, $132D, $135C,	$138F, $13C5, $13FF
		dc.w $143C, $147C, $1A5E, $1A84, $1AAB,	$1AD3, $1AFE, $1B2D
		dc.w $1B5C, $1B8F, $1BC5, $1BFF, $1C3C,	$1C7C, $225E, $2284
		dc.w $22AB, $22D3, $22FE, $232D, $235C,	$238F, $23C5, $23FF
		dc.w $243C, $247C, $2A5E, $2A84, $2AAB,	$2AD3, $2AFE, $2B2D
		dc.w $2B5C, $2B8F, $2BC5, $2BFF, $2C3C,	$2C7C, $325E, $3284
		dc.w $32AB, $32D3, $32FE, $332D, $335C,	$338F, $33C5, $33FF
		dc.w $343C, $347C, $3A5E, $3A84, $3AAB,	$3AD3, $3AFE, $3B2D
		dc.w $3B5C, $3B8F, $3BC5, $3BFF, $3C3C,	$3C7C

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72850:				; XREF: sub_71B4C
		subq.b	#1,$E(a5)
		bne.b	loc_72866
		bclr	#4,(a5)
		jsr	sub_72878(pc)
		jsr	sub_728DC(pc)
		bra.w	loc_7292E
; ===========================================================================

loc_72866:
		jsr	sub_71D9E(pc)
		jsr	sub_72926(pc)
		jsr	sub_71DC6(pc)
		jsr	sub_728E2(pc)
		rts	
; End of function sub_72850


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72878:				; XREF: sub_72850
		bclr	#1,(a5)
		movea.l	4(a5),a4

loc_72880:
		moveq	#0,d5
		move.b	(a4)+,d5
		cmpi.b	#$E0,d5
		bcs.b	loc_72890
		jsr	sub_72A5A(pc)
		bra.b	loc_72880
; ===========================================================================

loc_72890:
		tst.b	d5
		bpl.b	loc_728A4
		jsr	sub_728AC(pc)
		move.b	(a4)+,d5
		tst.b	d5
		bpl.b	loc_728A4
		subq.w	#1,a4
		bra.w	sub_71D60
; ===========================================================================

loc_728A4:
		jsr	sub_71D40(pc)
		bra.w	sub_71D60
; End of function sub_72878


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728AC:				; XREF: sub_72878
		subi.b	#$81,d5
		bcs.b	loc_728CA
		add.b	8(a5),d5
		andi.w	#$7F,d5
		lsl.w	#1,d5
		lea	word_729CE(pc),a0
		move.w	(a0,d5.w),$10(a5)
		bra.w	sub_71D60
; ===========================================================================

loc_728CA:
		bset	#1,(a5)
		move.w	#-1,$10(a5)
		jsr	sub_71D60(pc)
		bra.w	sub_729A0
; End of function sub_728AC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728DC:				; XREF: sub_72850
		move.w	$10(a5),d6
		bmi.b	loc_72920
; End of function sub_728DC


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_728E2:				; XREF: sub_72850
		move.b	$1E(a5),d0
		ext.w	d0
		add.w	d0,d6
		btst	#2,(a5)
		bne.b	locret_7291E
		btst	#1,(a5)
		bne.b	locret_7291E
		move.b	1(a5),d0
		cmpi.b	#$E0,d0
		bne.b	loc_72904
		move.b	#$C0,d0

loc_72904:
		move.w	d6,d1
		andi.b	#$F,d1
		or.b	d1,d0
		lsr.w	#4,d6
		andi.b	#$3F,d6
		move.b	d0,($C00011).l
		move.b	d6,($C00011).l

locret_7291E:
		rts	
; End of function sub_728E2

; ===========================================================================

loc_72920:				; XREF: sub_728DC
		bset	#1,(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72926:				; XREF: sub_72850
		tst.b	$B(a5)
		beq.w	locret_7298A

loc_7292E:				; XREF: sub_72850
		move.b	9(a5),d6
		moveq	#0,d0
		move.b	$B(a5),d0
		beq.b	sub_7296A
		movea.l	(Go_PSGIndex).l,a0
		subq.w	#1,d0
		lsl.w	#2,d0
		movea.l	(a0,d0.w),a0
		move.b	$C(a5),d0
		move.b	(a0,d0.w),d0
		addq.b	#1,$C(a5)
		btst	#7,d0
		beq.b	loc_72960
		cmpi.b	#$80,d0
		beq.b	loc_7299A

loc_72960:
		add.w	d0,d6
		cmpi.b	#$10,d6
		bcs.b	sub_7296A
		moveq	#$F,d6
; End of function sub_72926


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_7296A:				; XREF: sub_72504; sub_7267C; sub_72926
		btst	#1,(a5)
		bne.b	locret_7298A
		btst	#2,(a5)
		bne.b	locret_7298A
		btst	#4,(a5)
		bne.b	loc_7298C

loc_7297C:
		or.b	1(a5),d6
		addi.b	#$10,d6
		move.b	d6,($C00011).l

locret_7298A:
		rts	
; ===========================================================================

loc_7298C:
		tst.b	$13(a5)
		beq.b	loc_7297C
		tst.b	$12(a5)
		bne.b	loc_7297C
		rts	
; End of function sub_7296A

; ===========================================================================

loc_7299A:				; XREF: sub_72926
		subq.b	#1,$C(a5)
		rts	

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729A0:				; XREF: sub_71D9E; Sound_ChkValue; Snd_FadeOut1; sub_728AC
		btst	#2,(a5)
		bne.b	locret_729B4

loc_729A6:				; XREF: Snd_FadeOut2
		move.b	1(a5),d0
		ori.b	#$1F,d0
		move.b	d0,($C00011).l

locret_729B4:
		rts	
; End of function sub_729A0


; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_729B6:				; XREF: loc_71E7C
		lea	($C00011).l,a0
		move.b	#$9F,(a0)
		move.b	#$BF,(a0)
		move.b	#$DF,(a0)
		move.b	#$FF,(a0)
		rts	
; End of function sub_729B6

; ===========================================================================
word_729CE:	dc.w $356, $326, $2F9, $2CE, $2A5, $280, $25C, $23A, $21A
		dc.w $1FB, $1DF, $1C4, $1AB, $193, $17D, $167, $153, $140
		dc.w $12E, $11D, $10D, $FE, $EF, $E2, $D6, $C9,	$BE, $B4
		dc.w $A9, $A0, $97, $8F, $87, $7F, $78,	$71, $6B, $65
		dc.w $5F, $5A, $55, $50, $4B, $47, $43,	$40, $3C, $39
		dc.w $36, $33, $30, $2D, $2B, $28, $26,	$24, $22, $20
		dc.w $1F, $1D, $1B, $1A, $18, $17, $16,	$15, $13, $12
		dc.w $11, 0

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72A5A:				; XREF: sub_71C4E; sub_71CEC; sub_72878
		subi.w	#$E0,d5
		lsl.w	#2,d5
		jmp	loc_72A64(pc,d5.w)
; End of function sub_72A5A

; ===========================================================================

loc_72A64:
		bra.w	loc_72ACC
; ===========================================================================
		bra.w	loc_72AEC
; ===========================================================================
		bra.w	loc_72AF2
; ===========================================================================
		bra.w	loc_72AF8
; ===========================================================================
		bra.w	loc_72B14
; ===========================================================================
		bra.w	loc_72B9E
; ===========================================================================
		bra.w	loc_72BA4
; ===========================================================================
		bra.w	loc_72BAE
; ===========================================================================
		bra.w	loc_72BB4
; ===========================================================================
		bra.w	loc_72BBE
; ===========================================================================
		bra.w	loc_72BC6
; ===========================================================================
		bra.w	loc_72BD0
; ===========================================================================
		bra.w	loc_72BE6
; ===========================================================================
		bra.w	loc_72BEE
; ===========================================================================
		bra.w	loc_72BF4
; ===========================================================================
		bra.w	loc_72C26
; ===========================================================================
		bra.w	loc_72D30
; ===========================================================================
		bra.w	loc_72D52
; ===========================================================================
		bra.w	loc_72D58
; ===========================================================================
		bra.w	loc_72E06
; ===========================================================================
		bra.w	loc_72E20
; ===========================================================================
		bra.w	loc_72E26
; ===========================================================================
		bra.w	loc_72E2C
; ===========================================================================
		bra.w	loc_72E38
; ===========================================================================
		bra.w	loc_72E52
; ===========================================================================
		bra.w	loc_72E64
; ===========================================================================

loc_72ACC:				; XREF: loc_72A64
		move.b	(a4)+,d1
		tst.b	1(a5)
		bmi.b	locret_72AEA
		move.b	$A(a5),d0
		andi.b	#$37,d0
		or.b	d0,d1
		move.b	d1,$A(a5)
		move.b	#$B4,d0
		bra.w	loc_72716
; ===========================================================================

locret_72AEA:
		rts	
; ===========================================================================

loc_72AEC:				; XREF: loc_72A64
		move.b	(a4)+,$1E(a5)
		rts	
; ===========================================================================

loc_72AF2:				; XREF: loc_72A64
		move.b	(a4)+,7(a6)
		rts	
; ===========================================================================

loc_72AF8:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		movea.l	(a5,d0.w),a4
		move.l	#0,(a5,d0.w)
		addq.w	#2,a4
		addq.b	#4,d0
		move.b	d0,$D(a5)
		rts	
; ===========================================================================

loc_72B14:				; XREF: loc_72A64
		movea.l	a6,a0
		lea	$3A0(a6),a1
		move.w	#$87,d0

loc_72B1E:
		move.l	(a1)+,(a0)+
		dbra	d0,loc_72B1E

		bset	#2,$40(a6)
		movea.l	a5,a3
		move.b	#$28,d6
		sub.b	$26(a6),d6
		moveq	#5,d7
		lea	$70(a6),a5

loc_72B3A:
		btst	#7,(a5)
		beq.b	loc_72B5C
		bset	#1,(a5)
		add.b	d6,9(a5)
		btst	#2,(a5)
		bne.b	loc_72B5C
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		jsr	sub_72C4E(pc)

loc_72B5C:
		adda.w	#$30,a5
		dbra	d7,loc_72B3A

		moveq	#2,d7

loc_72B66:
		btst	#7,(a5)
		beq.b	loc_72B78
		bset	#1,(a5)
		jsr	sub_729A0(pc)
		add.b	d6,9(a5)

loc_72B78:
		adda.w	#$30,a5
		dbra	d7,loc_72B66
		movea.l	a3,a5
		move.b	#$80,$24(a6)
		move.b	#$28,$26(a6)
		clr.b	$27(a6)
		move.w	#0,($A11100).l
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72B9E:				; XREF: loc_72A64
		move.b	(a4)+,2(a5)
		rts	
; ===========================================================================

loc_72BA4:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		bra.w	sub_72CB4
; ===========================================================================

loc_72BAE:				; XREF: loc_72A64
		bset	#4,(a5)
		rts	
; ===========================================================================

loc_72BB4:				; XREF: loc_72A64
		move.b	(a4),$12(a5)
		move.b	(a4)+,$13(a5)
		rts	
; ===========================================================================

loc_72BBE:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,8(a5)
		rts	
; ===========================================================================

loc_72BC6:				; XREF: loc_72A64
		move.b	(a4),2(a6)
		move.b	(a4)+,1(a6)
		rts	
; ===========================================================================

loc_72BD0:				; XREF: loc_72A64
		lea	$40(a6),a0
		move.b	(a4)+,d0
		moveq	#$30,d1
		moveq	#9,d2

loc_72BDA:
		move.b	d0,2(a0)
		adda.w	d1,a0
		dbra	d2,loc_72BDA

		rts	
; ===========================================================================

loc_72BE6:				; XREF: loc_72A64
		move.b	(a4)+,d0
		add.b	d0,9(a5)
		rts	
; ===========================================================================

loc_72BEE:				; XREF: loc_72A64
		clr.b	$2C(a6)
		rts	
; ===========================================================================

loc_72BF4:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		jsr	sub_726FE(pc)
		tst.b	$250(a6)
		bmi.b	loc_72C22
		movea.l	a5,a3
		lea	$100(a6),a5
		movea.l	$18(a6),a1
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)
		movea.l	a3,a5

loc_72C22:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72C26:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	d0,$B(a5)
		btst	#2,(a5)
		bne.w	locret_72CAA
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.b	sub_72C4E
		movea.l	$20(a5),a1
		tst.b	$E(a6)
		bmi.b	sub_72C4E
		movea.l	$20(a6),a1

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72C4E:				; XREF: Snd_FadeOut1; et al
		subq.w	#1,d0
		bmi.b	loc_72C5C
		move.w	#$19,d1

loc_72C56:
		adda.w	d1,a1
		dbra	d0,loc_72C56

loc_72C5C:
		move.b	(a1)+,d1
		move.b	d1,$1F(a5)
		move.b	d1,d4
		move.b	#$B0,d0
		jsr	sub_72722(pc)
		lea	byte_72D18(pc),a2
		moveq	#$13,d3

loc_72C72:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		jsr	sub_72722(pc)
		dbra	d3,loc_72C72
		moveq	#3,d5
		andi.w	#7,d4
		move.b	byte_72CAC(pc,d4.w),d4
		move.b	9(a5),d3

loc_72C8C:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.b	loc_72C96
		add.b	d3,d1

loc_72C96:
		jsr	sub_72722(pc)
		dbra	d5,loc_72C8C
		move.b	#$B4,d0
		move.b	$A(a5),d1
		jsr	sub_72722(pc)

locret_72CAA:
		rts	
; End of function sub_72C4E

; ===========================================================================
byte_72CAC:	dc.b 8,	8, 8, 8, $A, $E, $E, $F

; ||||||||||||||| S U B	R O U T	I N E |||||||||||||||||||||||||||||||||||||||


sub_72CB4:				; XREF: sub_72504; sub_7267C; loc_72BA4
		btst	#2,(a5)
		bne.b	locret_72D16
		moveq	#0,d0
		move.b	$B(a5),d0
		movea.l	$18(a6),a1
		tst.b	$E(a6)
		beq.b	loc_72CD8
		movea.l	$20(a6),a1
		tst.b	$E(a6)
		bmi.b	loc_72CD8
		movea.l	$20(a6),a1

loc_72CD8:
		subq.w	#1,d0
		bmi.b	loc_72CE6
		move.w	#$19,d1

loc_72CE0:
		adda.w	d1,a1
		dbra	d0,loc_72CE0

loc_72CE6:
		adda.w	#$15,a1
		lea	byte_72D2C(pc),a2
		move.b	$1F(a5),d0
		andi.w	#7,d0
		move.b	byte_72CAC(pc,d0.w),d4
		move.b	9(a5),d3
		bmi.b	locret_72D16
		moveq	#3,d5

loc_72D02:
		move.b	(a2)+,d0
		move.b	(a1)+,d1
		lsr.b	#1,d4
		bcc.b	loc_72D12
		add.b	d3,d1
		bcs.b	loc_72D12
		jsr	sub_72722(pc)

loc_72D12:
		dbra	d5,loc_72D02

locret_72D16:
		rts	
; End of function sub_72CB4

; ===========================================================================
byte_72D18:	dc.b $30, $38, $34, $3C, $50, $58, $54,	$5C, $60, $68
		dc.b $64, $6C, $70, $78, $74, $7C, $80,	$88, $84, $8C
byte_72D2C:	dc.b $40, $48, $44, $4C
; ===========================================================================

loc_72D30:				; XREF: loc_72A64
		bset	#3,(a5)
		move.l	a4,$14(a5)
		move.b	(a4)+,$18(a5)
		move.b	(a4)+,$19(a5)
		move.b	(a4)+,$1A(a5)
		move.b	(a4)+,d0
		lsr.b	#1,d0
		move.b	d0,$1B(a5)
		clr.w	$1C(a5)
		rts	
; ===========================================================================

loc_72D52:				; XREF: loc_72A64
		bset	#3,(a5)
		rts	
; ===========================================================================

loc_72D58:				; XREF: loc_72A64
		bclr	#7,(a5)
		bclr	#4,(a5)
		tst.b	1(a5)
		bmi.b	loc_72D74
		tst.b	8(a6)
		bmi.w	loc_72E02
		jsr	sub_726FE(pc)
		bra.b	loc_72D78
; ===========================================================================

loc_72D74:
		jsr	sub_729A0(pc)

loc_72D78:
		tst.b	$E(a6)
		bpl.w	loc_72E02
		clr.b	0(a6)
		moveq	#0,d0
		move.b	1(a5),d0
		bmi.b	loc_72DCC
		lea	dword_722CC(pc),a0
		movea.l	a5,a3
		cmpi.b	#4,d0
		bne.b	loc_72DA8
		tst.b	$340(a6)
		bpl.b	loc_72DA8
		lea	$340(a6),a5
		movea.l	$20(a6),a1
		bra.b	loc_72DB8
; ===========================================================================

loc_72DA8:
		subq.b	#2,d0
		lsl.b	#2,d0
		movea.l	(a0,d0.w),a5
		tst.b	(a5)
		bpl.b	loc_72DC8
		movea.l	$18(a6),a1

loc_72DB8:
		bclr	#2,(a5)
		bset	#1,(a5)
		move.b	$B(a5),d0
		jsr	sub_72C4E(pc)

loc_72DC8:
		movea.l	a3,a5
		bra.b	loc_72E02
; ===========================================================================

loc_72DCC:
		lea	$370(a6),a0
		tst.b	(a0)
		bpl.b	loc_72DE0
		cmpi.b	#$E0,d0
		beq.b	loc_72DEA
		cmpi.b	#$C0,d0
		beq.b	loc_72DEA

loc_72DE0:
		lea	dword_722CC(pc),a0
		lsr.b	#3,d0
		movea.l	(a0,d0.w),a0

loc_72DEA:
		bclr	#2,(a0)
		bset	#1,(a0)
		cmpi.b	#$E0,1(a0)
		bne.b	loc_72E02
		move.b	$1F(a0),($C00011).l

loc_72E02:
		addq.w	#8,sp
		rts	
; ===========================================================================

loc_72E06:				; XREF: loc_72A64
		move.b	#$E0,1(a5)
		move.b	(a4)+,$1F(a5)
		btst	#2,(a5)
		bne.b	locret_72E1E
		move.b	-1(a4),($C00011).l

locret_72E1E:
		rts	
; ===========================================================================

loc_72E20:				; XREF: loc_72A64
		bclr	#3,(a5)
		rts	
; ===========================================================================

loc_72E26:				; XREF: loc_72A64
		move.b	(a4)+,$B(a5)
		rts	
; ===========================================================================

loc_72E2C:				; XREF: loc_72A64
		move.b	(a4)+,d0
		lsl.w	#8,d0
		move.b	(a4)+,d0
		adda.w	d0,a4
		subq.w	#1,a4
		rts	
; ===========================================================================

loc_72E38:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	(a4)+,d0
		move.b	(a4)+,d1
		tst.b	$24(a5,d0.w)
		bne.b	loc_72E48
		move.b	d1,$24(a5,d0.w)

loc_72E48:
		subq.b	#1,$24(a5,d0.w)
		bne.b	loc_72E2C
		addq.w	#2,a4
		rts	
; ===========================================================================

loc_72E52:				; XREF: loc_72A64
		moveq	#0,d0
		move.b	$D(a5),d0
		subq.b	#4,d0
		move.l	a4,(a5,d0.w)
		move.b	d0,$D(a5)
		bra.b	loc_72E2C
; ===========================================================================

loc_72E64:				; XREF: loc_72A64
		move.b	#$88,d0
		move.b	#$F,d1
		jsr	sub_7272E(pc)
		move.b	#$8C,d0
		move.b	#$F,d1
		bra.w	sub_7272E
; ===========================================================================
pcm_top:	incbin	sound\z80_1.bin
		dc.w ((SegaPCM&$FF)<<8)+((SegaPCM&$FF00)>>8)
		dc.b $21
		dc.w (((EndOfRom-SegaPCM)&$FF)<<8)+(((EndOfRom-SegaPCM)&$FF00)>>8)
		incbin	sound\z80_2.bin
		even
Music81:	incbin	sound\music81.bin
		even
Music82:	incbin	sound\music82.bin
		even
Music83:	incbin	sound\music83.bin
		even
Music84:	incbin	sound\music84.bin
		even
Music85:	incbin	sound\music85.bin
		even
Music86:	incbin	sound\music86.bin
		even
Music87:	incbin	sound\music87.bin
		even
Music88:	incbin	sound\music88.bin
		even
Music89:	incbin	sound\music89.bin
		even
Music8A:	incbin	sound\music8A.bin
		even
Music8B:	incbin	sound\music8B.bin
		even
Music8C:	incbin	sound\music8C.bin
		even
Music8D:	incbin	sound\music8D.bin
		even
Music8E:	incbin	sound\music8E.bin
		even
Music8F:	incbin	sound\music8F.bin
		even
Music90:	incbin	sound\music90.bin
		even
Music91:	incbin	sound\music91.bin
		even
Music92:	incbin	sound\music92.bin
		even
Music93:	incbin	sound\music93.bin
		even
; ---------------------------------------------------------------------------
; Sound	effect pointers
; ---------------------------------------------------------------------------
SoundIndex:	dc.l SoundA0, SoundA1, SoundA2
		dc.l SoundA3, SoundA4, SoundA5
		dc.l SoundA6, SoundA7, SoundA8
		dc.l SoundA9, SoundAA, SoundAB
		dc.l SoundAC, SoundAD, SoundAE
		dc.l SoundAF, SoundB0, SoundB1
		dc.l SoundB2, SoundB3, SoundB4
		dc.l SoundB5, SoundB6, SoundB7
		dc.l SoundB8, SoundB9, SoundBA
		dc.l SoundBB, SoundBC, SoundBD
		dc.l SoundBE, Soundbra, SoundC0
		dc.l SoundC1, SoundC2, SoundC3
		dc.l SoundC4, SoundC5, SoundC6
		dc.l SoundC7, SoundC8, SoundC9
		dc.l SoundCA, SoundCB, SoundCC
		dc.l SoundCD, SoundCE, SoundCF
SoundD0Index:	dc.l SoundD0
SoundA0:	incbin	sound\soundA0.bin
		even
SoundA1:	incbin	sound\soundA1.bin
		even
SoundA2:	incbin	sound\soundA2.bin
		even
SoundA3:	incbin	sound\soundA3.bin
		even
SoundA4:	incbin	sound\soundA4.bin
		even
SoundA5:	incbin	sound\soundA5.bin
		even
SoundA6:	incbin	sound\soundA6.bin
		even
SoundA7:	incbin	sound\soundA7.bin
		even
SoundA8:	incbin	sound\soundA8.bin
		even
SoundA9:	incbin	sound\soundA9.bin
		even
SoundAA:	incbin	sound\soundAA.bin
		even
SoundAB:	incbin	sound\soundAB.bin
		even
SoundAC:	incbin	sound\soundAC.bin
		even
SoundAD:	incbin	sound\soundAD.bin
		even
SoundAE:	incbin	sound\soundAE.bin
		even
SoundAF:	incbin	sound\soundAF.bin
		even
SoundB0:	incbin	sound\soundB0.bin
		even
SoundB1:	incbin	sound\soundB1.bin
		even
SoundB2:	incbin	sound\soundB2.bin
		even
SoundB3:	incbin	sound\soundB3.bin
		even
SoundB4:	incbin	sound\soundB4.bin
		even
SoundB5:	incbin	sound\soundB5.bin
		even
SoundB6:	incbin	sound\soundB6.bin
		even
SoundB7:	incbin	sound\soundB7.bin
		even
SoundB8:	incbin	sound\soundB8.bin
		even
SoundB9:	incbin	sound\soundB9.bin
		even
SoundBA:	incbin	sound\soundBA.bin
		even
SoundBB:	incbin	sound\soundBB.bin
		even
SoundBC:	incbin	sound\soundBC.bin
		even
SoundBD:	incbin	sound\soundBD.bin
		even
SoundBE:	incbin	sound\soundBE.bin
		even
Soundbra:	incbin	sound\soundbra.bin
		even
SoundC0:	incbin	sound\soundC0.bin
		even
SoundC1:	incbin	sound\soundC1.bin
		even
SoundC2:	incbin	sound\soundC2.bin
		even
SoundC3:	incbin	sound\soundC3.bin
		even
SoundC4:	incbin	sound\soundC4.bin
		even
SoundC5:	incbin	sound\soundC5.bin
		even
SoundC6:	incbin	sound\soundC6.bin
		even
SoundC7:	incbin	sound\soundC7.bin
		even
SoundC8:	incbin	sound\soundC8.bin
		even
SoundC9:	incbin	sound\soundC9.bin
		even
SoundCA:	incbin	sound\soundCA.bin
		even
SoundCB:	incbin	sound\soundCB.bin
		even
SoundCC:	incbin	sound\soundCC.bin
		even
SoundCD:	incbin	sound\soundCD.bin
		even
SoundCE:	incbin	sound\soundCE.bin
		even
SoundCF:	incbin	sound\soundCF.bin
		even
SoundD0:	incbin	sound\soundD0.bin
		even
SegaPCM:	incbin	sound\segapcm.bin
		even

; end of 'ROM'
EndOfRom:


		END
