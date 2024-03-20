		addsym
		nolist
		include	"EQU.LIB"
		include	"MACRO.LIB"
		list

		xref	frameoutchk,soundset,actwkchk,sinset

		xdef	save,playsave,playload

		xdef	savepat

;------------------------------------------------------------------------------
save:
		moveq	#0,d0
		move.b	r_no0(a0),d0
		move.w	save_move_tbl(pc,d0.w),d1
		jsr		save_move_tbl(pc,d1.w)
		jmp		frameoutchk
save_move_tbl:
		dc.w	save_init-save_move_tbl
		dc.w	save_move0-save_move_tbl
		dc.w	save_move1-save_move_tbl
		dc.w	save_move2-save_move_tbl
save_init:
		addq.b	#word,r_no0(a0)
		move.l	#savepat,patbase(a0)
		move.w	#$07a0,sproffset(a0)
		move.b	#4,actflg(a0)
		move.b	#8,sprhs(a0)
		move.b	#5,sprpri(a0)
		lea		$fffc00,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bclr.b	#7,2(a2,d0.w)
		btst.b	#0,2(a2,d0.w)
		bne.b	?jump
		move.b	saveno,d1
		andi.b	#$7f,d1
		move.b	userflag(a0),d2
		andi.b	#$7f,d2
		cmp.b	d2,d1
		bcs.b	save_move0
?jump:
		bset.b	#0,2(a2,d0.w)
		move.b	#4,r_no0(a0)
		move.b	#3,patno(a0)
		rts	
save_move0:
		tst.w	editmode
		bne.w	?jump2
		tst.b	$fff7c8
		bmi.w	?jump2
		move.b	saveno,d1
		andi.b	#$7f,d1
		move.b	userflag(a0),d2
		andi.b	#$7f,d2
		cmp.b	d2,d1
		bcs.b	?jump0
		lea		$fffc00,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bset.b	#0,2(a2,d0.w)
		move.b	#4,r_no0(a0)
		move.b	#3,patno(a0)
		bra.w	?jump2
?jump0:
		*colition
		move.w	playerwk+xposi,d0
		sub.w	xposi(a0),d0
		addq.w	#8,d0
		cmpi.w	#16,d0
		bcc.w	?jump2
		move.w	playerwk+yposi,d0
		sub.w	yposi(a0),d0
		addi.w	#64,d0
		cmpi.w	#104,d0
		bcc.b	?jump2
		move.w	#$a1,d0
		jsr		soundset
		addq.b	#word,r_no0(a0)
		jsr		actwkchk
		bne.b	?jump1
		move.b	#save_act,actno(a1)
		move.b	#6,r_no0(a1)
		move.w	xposi(a0),actfree+4(a1)
		move.w	yposi(a0),actfree+6(a1)
		subi.w	#24,actfree+6(a1)
		move.l	#savepat,patbase(a1)
		move.w	#$07a0,sproffset(a1)
		move.b	#4,actflag(a1)
		move.b	#8,sprhs(a1)
		move.b	#4,sprpri(a1)
		move.b	#2,patno(a1)
		move.w	#32,actfree+10(a1)
?jump1:
		move.b	#1,patno(a0)
		bsr.w	playsave
		lea		$fffc00,a2
		moveq	#0,d0
		move.b	cdsts(a0),d0
		bset.b	#0,2(a2,d0.w)
?jump2:
		rts	
save_move1:
		rts	
save_move2:
		subq.w	#1,actfree+10(a0)
		bpl.b	?jump
		move.b	#4,r_no0(a0)
?jump:
		move.b	direc(a0),d0
		subi.b	#$10,direc(a0)
		subi.b	#$40,d0
		jsr		sinset
		muls.w	#$0c00,d1
		swap	d1
		add.w	actfree+4(a0),d1
		move.w	d1,xposi(a0)
		muls.w	#$0c00,d0
		swap	d0
		add.w	actfree+6(a0),d0
		move.w	d0,yposi(a0)
		rts	

playsave:
		move.b	userflag(a0),saveno
		move.b	saveno,saveno_sb
		move.w	xposi(a0),plxposi_sb
		move.w	yposi(a0),plyposi_sb
		move.w	plring,plring_s
		move.b	plring_f2,plring_f2_s
		move.l	pltime,pltime_sb
		move.b	$fff742,$fffe3c
		move.w	scralim_down,scralim_down_sb
		move.w	scra_h_posit,scra_h_posit_sb
		move.w	scra_v_posit,scra_v_posit_sb
		move.w	scrb_h_posit,scrb_h_posit_sb
		move.w	scrb_v_posit,scrb_v_posit_sb
		move.w	scrc_h_posit,scrc_h_posit_sb
		move.w	scrc_v_posit,scrc_v_posit_sb
		move.w	scrz_h_posit,scrz_h_posit_sb
		move.w	scrz_v_posit,scrz_v_posit_sb
		move.w	waterposi_m,waterposi_m_sb
		move.b	$fff64d,$fffe52
		move.b	waterflag,waterflag_s
		rts	

playload:
		move.b	saveno_sb,saveno
		move.w	plxposi_sb,playerwk+xposi
		move.w	plyposi_sb,playerwk+yposi
		move.w	plring_s,plring
		move.b	plring_f2_s,plring_f2
		clr.w	plring
		clr.b	plring_f2
		move.l	pltime_sb,pltime
		move.b	#59,pltime+3
		subq.b	#1,pltime+2
		move.b	$fffe3c,$fff742
		move.b	$fffe52,$fff64d
		move.w	scralim_down_sb,scralim_down
		move.w	scralim_down_sb,scralim_n_down
		move.w	scra_h_posit_sb,scra_h_posit
		move.w	scra_v_posit_sb,scra_v_posit
		move.w	scrb_h_posit_sb,scrb_h_posit
		move.w	scrb_v_posit_sb,scrb_v_posit
		move.w	scrc_h_posit_sb,scrc_h_posit
		move.w	scrc_v_posit_sb,scrc_v_posit
		move.w	scrz_h_posit_sb,scrz_h_posit
		move.w	scrz_v_posit_sb,scrz_v_posit
		cmpi.b	#1,stageno
		bne.b	?jump
		move.w	waterposi_m_sb,waterposi_m
		move.b	$fffe52,$fff64d
		move.b	waterflag_s,waterflag
?jump:
		tst.b	saveno
		bpl.b	?jump1
		move.w	plxposi_sb,d0
		subi.w	#0160,d0
		move.w	d0,scralim_left
?jump1:
		rts

savepat:
		dc.w	savepat0-savepat
		dc.w	savepat1-savepat
		dc.w	savepat2-savepat
		dc.w	savepat3-savepat
savepat0:
		dc.b	6
		dc.b	$e4,$01,$00,$00,$f8	;1:
		dc.b	$e4,$01,$08,$00,$00	;2:
		dc.b	$e4,$03,$20,$02,$f8	;3:
		dc.b	$f4,$03,$28,$02,$00	;4:
		dc.b	$d4,$01,$00,$06,$f8	;5:
		dc.b	$d4,$01,$08,$06,$00	;6:
savepat1:
		dc.b	4
		dc.b	$e4,$01,$00,$00,$f8	;1:
		dc.b	$e4,$01,$08,$00,$00	;2:
		dc.b	$f4,$03,$20,$02,$f8	;3:
		dc.b	$f4,$03,$28,$02,$00	;4:
savepat2:
		dc.b	2
		dc.b	$f8,$01,$00,$08,$f8	;1:
		dc.b	$f8,$01,$08,$08,$00	;2:
savepat3:
		dc.b	6
		dc.b	$e4,$01,$00,$00,$f8	;1:
		dc.b	$e4,$01,$08,$00,$00	;2:
		dc.b	$f4,$03,$20,$02,$f8	;3:
		dc.b	$f4,$03,$28,$02,$00	;4:
		dc.b	$d4,$01,$00,$08,$f8	;5:
		dc.b	$d4,$01,$08,$08,$00	;6:

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------