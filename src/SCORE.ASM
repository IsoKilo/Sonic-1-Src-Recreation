		addsym
		nolist
		include	"EQU.LIB"
		include	"MACRO.LIB"
		list

		xref	actionsub,playdieset
		xref	ascii

		xdef	score,scoreup,scoreset,scoreinit,contwrt

		xdef	scorepat

;------------------------------------------------------------------------------
score:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	score_move_tbl(pc,d0.w),d1
		jmp		score_move_tbl(pc,d1.w)
score_move_tbl:
		dc.w	score_init-score_move_tbl
		dc.w	score_move-score_move_tbl
score_init:
		addq.b	#word,r_no0(a0)
		move.w	#$0090,xposi(a0)
		move.w	#$0108,xposi+2(a0)
		move.l	#scorepat,patbase(a0)
		move.w	#$06ca,sproffset(a0)
		move.b	#0,actflg(a0)
		move.b	#0,sprhs(a0)
score_move:
		tst.w	plring
		beq.b	?jump
		clr.b	patno(a0)
		jmp		actionsub
?jump:
		moveq	#0,d0
		btst.b	#3,$fffe05
		bne.b	?jump0
		addq.w	#1,d0
		cmpi.b	#9,$fffe23
		bne.b	?jump0
		addq.w	#2,d0
?jump0:
		move.b	d0,patno(a0)
		jmp	actionsub

scorepat:
		dc.w	scorepat0-scorepat
		dc.w	scorepat1-scorepat
		dc.w	scorepat2-scorepat
		dc.w	scorepat3-scorepat
scorepat0:
		dc.b	10
		dc.b	$80,$0d,$80,$00,$00	;1:
		dc.b	$80,$0d,$80,$18,$20	;2:
		dc.b	$80,$0d,$80,$20,$40	;3:
		dc.b	$90,$0d,$80,$10,$00	;4:
		dc.b	$90,$0d,$80,$28,$28	;5:
		dc.b	$a0,$0d,$80,$08,$00	;6:
		dc.b	$a0,$01,$80,$00,$20	;7:
		dc.b	$a0,$09,$80,$30,$30	;8:
		dc.b	$40,$05,$81,$0a,$00	;9:
		dc.b	$40,$0d,$81,$0e,$10	;10:
		dc.b	0
scorepat1:
		dc.b	10
		dc.b	$80,$0d,$80,$00,$00	;1:
		dc.b	$80,$0d,$80,$18,$20	;2:
		dc.b	$80,$0d,$80,$20,$40	;3:
		dc.b	$90,$0d,$80,$10,$00	;4:
		dc.b	$90,$0d,$80,$28,$28	;5:
		dc.b	$a0,$0d,$a0,$08,$00	;6:
		dc.b	$a0,$01,$a0,$00,$20	;7:
		dc.b	$a0,$09,$80,$30,$30	;8:
		dc.b	$40,$05,$81,$0a,$00	;9:
		dc.b	$40,$0d,$81,$0e,$10	;10:
		dc.b	0
scorepat2:
		dc.b	10
		dc.b	$80,$0d,$80,$00,$00	;1:
		dc.b	$80,$0d,$80,$18,$20	;2:
		dc.b	$80,$0d,$80,$20,$40	;3:
		dc.b	$90,$0d,$a0,$10,$00	;4:
		dc.b	$90,$0d,$80,$28,$28	;5:
		dc.b	$a0,$0d,$80,$08,$00	;6:
		dc.b	$a0,$01,$80,$00,$20	;7:
		dc.b	$a0,$09,$80,$30,$30	;8:
		dc.b	$40,$05,$81,$0a,$00	;9:
		dc.b	$40,$0d,$81,$0e,$10	;10:
		dc.b	0
scorepat3:
		dc.b	10
		dc.b	$80,$0d,$80,$00,$00	;1:
		dc.b	$80,$0d,$80,$18,$20	;2:
		dc.b	$80,$0d,$80,$20,$40	;3:
		dc.b	$90,$0d,$a0,$10,$00	;4:
		dc.b	$90,$0d,$80,$28,$28	;5:
		dc.b	$a0,$0d,$a0,$08,$00	;6:
		dc.b	$a0,$01,$a0,$00,$20	;7:
		dc.b	$a0,$09,$80,$30,$30	;8:
		dc.b	$40,$05,$81,$0a,$00	;9:
		dc.b	$40,$0d,$81,$0e,$10	;10:

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------

scoreup:
		move.b	#1,plscore_f
		lea		extrascore,a2
		lea		plscore,a3
		add.l	d0,(a3)
		move.l	#999999,d1
		cmp.l	(a3),d1
		bhi.w	?jump
		move.l	d1,(a3)
		move.l	d1,(a2)
?jump:
		move.l	(a3),d0
		cmp.l	(a2),d0
		bcs.w	?jumpus
		move.l	d0,(a2)
?jumpus:
?jump0:
		rts

scoreset:
		tst.w	debugflag
		bne.w	scoreset2
		tst.b	plscore_f
		beq.b	?jump
		clr.b	plscore_f
		move.l	#$5c800003,d0
		move.l	plscore,d1
		bsr.w	scorewrt
?jump:
		tst.b	plring_f
		beq.b	?jump2
		bpl.b	?jump1
		bsr.w	ringinit
?jump1:
		clr.b	plring_f
		move.l	#$5f400003,d0
		moveq	#0,d1
		move.w	plring,d1
		bsr.w	ringwrt
?jump2:
		tst.b	pltime_f
		beq.b	?jump4
		tst.w	pauseflag
		bne.b	?jump4
		lea		$fffe22,a1
		cmpi.l	#$93b3b,(a1)+
		beq.b	?timeover
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.b	?jump4
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#60,(a1)
		bcs.b	?jump3
		move.b	#0,(a1)
		addq.b	#1,-(a1)
		cmpi.b	#9,(a1)
		bcs.b	?jump3
		move.b	#9,(a1)
?jump3:
		move.l	#$5e400003,d0
		moveq	#0,d1
		move.b	$fffe23,d1
		bsr.w	timewrt
		move.l	#$5ec00003,d0
		moveq	#0,d1
		move.b	$fffe24,d1
		bsr.w	timewrt0
?jump4:
		tst.b	pl_suu_f
		beq.b	?jump5
		clr.b	pl_suu_f
		bsr.w	playsuuwrt
?jump5:
		tst.b	$fff7d6
		beq.b	?jump6
		clr.b	$fff7d6
		move.l	#$6e000002,$c00004
		moveq	#0,d1
		move.w	$fff7d2,d1
		bsr.w	bonuswrt
		moveq	#0,d1
		move.w	$fff7d4,d1
		bsr.w	bonuswrt
?jump6:
		rts	

?timeover:
		clr.b	pltime_f
		lea		playerwk,a0
		movea.l	a0,a2
		bsr.w	playdieset
		move.b	#1,pltimeover_f
		rts

scoreset2:
		bsr.w	posiwrt
		tst.b	plring_f
		beq.b	?jump2
		bpl.b	?jump1
		bsr.w	ringinit
?jump1:
		clr.b	plring_f
		move.l	#$5f400003,d0
		moveq	#0,d1
		move.w	plring,d1
		bsr.w	ringwrt
?jump2:
		move.l	#$5ec00003,d0
		moveq	#0,d1
		move.b	$fff62c,d1
		bsr.w	timewrt0
		tst.b	pl_suu_f
		beq.b	?jump3
		clr.b	pl_suu_f
		bsr.w	playsuuwrt
?jump3:
		tst.b	$fff7d6
		beq.b	?jump4
		clr.b	$fff7d6
		move.l	#$6e000002,$c00004
		moveq	#0,d1
		move.w	$fff7d2,d1
		bsr.w	bonuswrt
		moveq	#0,d1
		move.w	$fff7d4,d1
		bsr.w	bonuswrt
?jump4:
		rts	

ringinit:
		move.l	#$5f400003,$c00004
		lea		ringinittbl(pc),a2
		move.w	#2,d2
		bra.b	scoreinitsub

scoreinit:
		lea		$c00000,a6
		bsr.w	playsuuwrt
		move.l	#$5c400003,$c00004
		lea		scoreinittbl(pc),a2
		move.w	#14,d2
scoreinitsub:
		lea		scorewrtcg(pc),a1
?loop:
		move.w	#15,d1
		move.b	(a2)+,d0
		bmi.b	?spaceset
		ext.w	d0
		lsl.w	#5,d0
		lea	(a1,d0.w),a3
?loop1:
		move.l	(a3)+,(a6)
		dbra	d1,?loop1
?jump:
		dbra	d2,?loop
		rts

?loop2:
?spaceset:
		move.l	#0,(a6)
		dbra	d1,?loop2
		bra.b	?jump

scoreinittbl:	dc.b 22,$ff,$ff,$ff,$ff,$ff,$ff,0,0,20,0,0
ringinittbl:	dc.b $ff,$ff,0,0

posiwrt:
		move.l	#$5c400003,$c00004
		move.w	scra_h_posit,d1
		swap	d1
		move.w	playerwk+xposi,d1
		bsr.b	hexwrtw
		move.w	scra_v_posit,d1
		swap	d1
		move.w	playerwk+yposi,d1
hexwrtw:
		moveq	#7,d6
		lea		ascii,a1
?loop:
		rol.w	#4,d1
		move.w	d1,d2
		andi.w	#$f,d2
		cmpi.w	#$a,d2
		bcs.b	?jump
		addq.w	#7,d2
?jump:
		lsl.w	#5,d2
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		swap	d1
		dbra	d6,?loop
		rts

ringwrt:
		lea		subtbl2,a2
		moveq	#2,d6
		bra.b	scorewrt2
scorewrt:
		lea		subtbl,a2
		moveq	#5,d6
scorewrt2:
		moveq	#0,d4
		lea		scorewrtcg(pc),a1
?loop:
		moveq	#0,d2
		move.l	(a2)+,d3
?jump2:
		sub.l	d3,d1
		bcs.b	?jump3
		addq.w	#1,d2
		bra.b	?jump2
?jump3:
		add.l	d3,d1
		tst.w	d2
		beq.b	?jump4
		move.w	#1,d4
?jump4:
		tst.w	d4
		beq.b	?jump5
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
?jump5:
		addi.l	#$400000,d0
		dbra	d6,?loop
		rts

contwrt:
		move.l	#$5f800003,$c00004
		lea		$c00000,a6
		lea		subtbl1,a2
		moveq	#1,d6
		moveq	#0,d4
		lea		scorewrtcg(pc),a1
?loop:
		moveq	#0,d2
		move.l	(a2)+,d3
?jump2:
		sub.l	d3,d1
		bcs.b	?jump3
		addq.w	#1,d2
		bra.b	?jump2
?jump3:
		add.l	d3,d1
		lsl.w	#6,d2
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		dbra	d6,?loop
		rts

subtbl:		dc.l	100000
subtbl4:	dc.l	10000
subtbl3:	dc.l	1000
subtbl2:	dc.l	100
subtbl1:	dc.l	10
timewrt1:	dc.l	1

timewrt:
		lea		timewrt1,a2
		moveq	#0,d6
		bra.b	?jump
timewrt0:
		lea		subtbl1,a2
		moveq	#1,d6
?jump:
		moveq	#0,d4
		lea		scorewrtcg(pc),a1
?loop:
		moveq	#0,d2
		move.l	(a2)+,d3
?jump2:
		sub.l	d3,d1
		bcs.b	?jump3
		addq.w	#1,d2
		bra.b	?jump2
?jump3:
		add.l	d3,d1
		tst.w	d2
		beq.b	?jump4
		move.w	#1,d4
?jump4:
		lsl.w	#6,d2
		move.l	d0,4(a6)
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		addi.l	#$400000,d0
		dbra	d6,?loop
		rts

bonuswrt:
		lea		subtbl3,a2
		moveq	#3,d6
		moveq	#0,d4
		lea		scorewrtcg(pc),a1
?loop:
		moveq	#0,d2
		move.l	(a2)+,d3
?jump2:
		sub.l	d3,d1
		bcs.b	?jump3
		addq.w	#1,d2
		bra.b	?jump2
?jump3:
		add.l	d3,d1
		tst.w	d2
		beq.b	?jump4
		move.w	#1,d4
?jump4:
		tst.w	d4
		beq.b	?jump7
		lsl.w	#6,d2
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
?jump5:
		dbra	d6,?loop
*?jump6:
		rts	
?jump7:
		moveq	#15,d5
?loop2:
		move.l	#0,(a6)
		dbra	d5,?loop2
		bra.b	?jump5

playsuuwrt:
		move.l	#$7ba00003,d0
		moveq	#0,d1
		move.b	pl_suu,d1
		lea		subtbl1,a2
		moveq	#1,d6
		moveq	#0,d4
		lea		playsuucg(pc),a1
?loop:
		move.l	d0,4(a6)
		moveq	#0,d2
		move.l	(a2)+,d3
?jump2:
		sub.l	d3,d1
		bcs.b	?jump3
		addq.w	#1,d2
		bra.b	?jump2
?jump3:
		add.l	d3,d1
		tst.w	d2
		beq.b	?jump4
		move.w	#1,d4
?jump4:
		tst.w	d4
		beq.b	?jump7
?jump5:
		lsl.w	#5,d2
		lea		(a1,d2.w),a3
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
		move.l	(a3)+,(a6)
?jump6:
		addi.l	#$400000,d0
		dbra	d6,?loop
		rts	

?jump7:
		tst.w	d6
		beq.b	?jump5
		moveq	#7,d5
?loop2:
		move.l	#0,(a6)
		dbra	d5,?loop2
		bra.b	?jump6

scorewrtcg:
		incbin	'ART\SCOREWRT.CGX'
playsuucg:
		incbin	'ART\PLAYSUU.CGX'

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------
		end