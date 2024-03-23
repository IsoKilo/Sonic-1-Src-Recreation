addsym
nolist
include	"EQU.LIB"
include	"MACRO.LIB"
list

xref	actionsub

xdef	wave

xdef	wavepat

;------------------------------------------------------------------------------wave:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	wave_move_tbl(pc,d0.w),d1
		jmp		wave_move_tbl(pc,d1.w)
wave_move_tbl:
		dc.w wave_init-wave_move_tbl
		dc.w wave_move-wave_move_tbl
wave_init:
		addq.b	#word,r_no0(a0)
		move.l	#wavepat,patbase(a0)
		move.w	#$c300,sproffset(a0)
		move.b	#4,actflg(a0)
		move.b	#128,sprhs(a0)
		move.w	xposi(a0),actfree+4(a0)
wave_move:
		move.w	scra_h_posit,d1
		andi.w	#-32,d1
		add.w	actfree+4(a0),d1
		btst.b	#0,gametimer+1
		beq.b	?jump0
		addi.w	#32,d1
?jump0:
		move.w	d1,xposi(a0)
		move.w	waterposi,d1
		move.w	d1,yposi(a0)
		tst.b	actfree+6(a0)
		bne.b	?jump1
		btst.b	#7,swdata1+1
		beq.b	?jump2
		addq.b	#3,patno(a0)
		move.b	#1,actfree+6(a0)
		bra.b	?jump4

?jump1:
		tst.w	pauseflag
		bne.b	?jump4
		move.b	#0,actfree+6(a0)
		subq.b	#3,patno(a0)
?jump2:
		subq.b	#1,pattim(a0)
		bpl.b	?jump4
		move.b	#7,pattim(a0)
		addq.b	#1,patno(a0)
		cmpi.b	#3,patno(a0)
		bcs.b	?jump4
		move.b	#0,patno(a0)
?jump4:
		bra.w	actionsub

wavepat:
		dc.w	wavesp0-wavepat
		dc.w	wavesp1-wavepat
		dc.w	wavesp2-wavepat
		dc.w	wavesp3-wavepat
		dc.w	wavesp4-wavepat
		dc.w	wavesp5-wavepat
wavesp0:
		dc.b	3
		dc.b	$fd,$0d,$00,$00,$a0
		dc.b	$fd,$0d,$00,$00,$e0
		dc.b	$fd,$0d,$00,$00,$20
wavesp1:
		dc.b	3
		dc.b	$fd,$0d,$00,$08,$a0
		dc.b	$fd,$0d,$00,$08,$e0
		dc.b	$fd,$0d,$00,$08,$20
wavesp2:
		dc.b	3
		dc.b	$fd,$0d,$08,$00,$a0
		dc.b	$fd,$0d,$08,$00,$e0
		dc.b	$fd,$0d,$08,$00,$20
wavesp3:
		dc.b	6
		dc.b	$fd,$0d,$00,$00,$a0
		dc.b	$fd,$0d,$00,$00,$c0
		dc.b	$fd,$0d,$00,$00,$e0
		dc.b	$fd,$0d,$00,$00,$00
		dc.b	$fd,$0d,$00,$00,$20
		dc.b	$fd,$0d,$00,$00,$40
wavesp4:
		dc.b	6
		dc.b	$fd,$0d,$00,$08,$a0
		dc.b	$fd,$0d,$00,$08,$c0
		dc.b	$fd,$0d,$00,$08,$e0
		dc.b	$fd,$0d,$00,$08,$00
		dc.b	$fd,$0d,$00,$08,$20
		dc.b	$fd,$0d,$00,$08,$40
wavesp5:
		dc.b	6
		dc.b	$fd,$0d,$08,$00,$a0
		dc.b	$fd,$0d,$08,$00,$c0
		dc.b	$fd,$0d,$08,$00,$e0
		dc.b	$fd,$0d,$08,$00,$00
		dc.b	$fd,$0d,$08,$00,$20
		dc.b	$fd,$0d,$08,$00,$40
;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------
		end