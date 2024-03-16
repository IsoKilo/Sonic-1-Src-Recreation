		addsym
		nolist
		include	"EQU.LIB"
		include	"MACRO.LIB"
		list

		xref	ringpat,itempat,butapat,kanipat,hachipat,togepat
		xref	fishpat,fish2pat,mogurapat,shimapat2,jyamapat
		xref	musipat,sjumppat,kamerepat,arumapat,kagebpat,ballpat
		xref	firepat,fblockpat,signalpat,bobinpat,yoganpat,yogan2pat
		xref	usapat,yadopat,boxpat,bryukapat,daipat,break2pat,yogancpat
		xref	batpat,z5daipat,dai2pat,switch2pat,z4daipat
		xref	elevpat,pedalpat,steppat,funpat,sisoopat,hassyapat
		xref	brobopat,unipat,yaripat,udaipat,dai3pat,kazaripat,kassyapat
		xref	awapat,mizupat,boupat,benpat,fetamapat,mawarupat,hagurumapat
		xref	patapat,yukafpat,nokopat,dai4pat,doorpat,yukaepat,fire6pat
		xref	elepat,yukaipat,scolipat,imopat,savepat,bigringpat,btenpat
		xref	actionsub,actwkchk,frameout,playpat
		xref	flicpat,usagipat,pengpat,azarpat,fbutapat,niwapat,risupat

		xdef	edit

;------------------------------------------------------------------------------
edit:
		moveq	#0,d0
		move.b	editmode,d0
		move.w	edit_move_tbl(pc,d0.w),d1
		jmp		edit_move_tbl(pc,d1.w)
edit_move_tbl:
		dc.w	editinit-edit_move_tbl
		dc.w	editmove-edit_move_tbl
editinit:
		addq.b	#2,editmode
		move.w	scralim_up,editstack
		move.w	scralim_n_down,editstack2
		move.w	#$0000,scralim_up
		move.w	#$0720,scralim_n_down
		andi.w	#$07ff,playerwk+yposi
		andi.w	#$07ff,scra_v_posit
		andi.w	#$03ff,scrb_v_posit
		move.b	#0,patno(a0)
		move.b	#0,mstno(a0)
		cmpi.b	#spgamemd,gmmode
		bne.b	?jump0
*		move.b	#7-1,stageno
		move.w	#0,rotspd
		move.w	#0,rotdir
		moveq	#6,d0
		bra.b	?jump1
?jump0:
		moveq	#0,d0
		move.b	stageno,d0

?jump1:
		lea		edittbl,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		cmp.b	editno,d6
		bhi.b	?jump
		move.b	#0,editno

?jump:
		bsr.w	editpatchg
		move.b	#12,edittimer
		move.b	#1,edittimer+1

editmove:
		moveq	#7-1,d0
		cmpi.b	#spgamemd,gmmode
		beq.b	?jump
		moveq	#0,d0
		move.b	stageno,d0

?jump:
		lea		edittbl,a2
		add.w	d0,d0
		adda.w	(a2,d0.w),a2
		move.w	(a2)+,d6
		bsr.w	editwalk
*		bsr.w	dirsprset
		jmp	actionsub
editwalk:
		moveq	#0,d4
		move.w	#1,d1
		move.b	swdata1+1,d4
		andi.w	#$0f,d4
		bne.b	?jump0
		move.b	swdata1+0,d0
		andi.w	#$0f,d0
		bne.b	?jump
		move.b	#12,edittimer
		move.b	#$0f,edittimer+1
		bra.w	?lend
?jump:
		subq.b	#1,edittimer
		bne.b	?jump1
		move.b	#1,edittimer
		addq.b	#1,edittimer+1
*		cmpi.b	#255,edittimer+1
		bne.b	?jump0
		move.b	#255,edittimer+1

?jump0:
		move.b	swdata1+0,d4

?jump1:
		moveq	#0,d1
		move.b	edittimer+1,d1
		addq.w	#1,d1
		swap	d1
		asr.l	#4,d1
		move.l	yposi(a0),d2
		move.l	xposi(a0),d3
		btst.l	#0,d4						*swdata+0
		beq.b	?jump2
		sub.l	d1,d2						*yposi
		bcc.b	?jump2
		moveq	#0,d2

?jump2:
		btst.l	#1,d4						*swdata+0
		beq.b	?jump3
		add.l	d1,d2						*yposi
		cmpi.l	#$7ff0000,d2
		bcs.b	?jump3
		move.l	#$7ff0000,d2

?jump3:
		btst.l	#2,d4						*swdata+0
		beq.b	?jump4
		sub.l	d1,d3						*xposi
		bcc.b	?jump4
		moveq	#0,d3

?jump4:
		btst.l	#3,d4						*swdata+0
		beq.b	?jump5
		add.l	d1,d3						*xposi
?jump5:
		move.l	d2,yposi(a0)
		move.l	d3,xposi(a0)
?lend:
		btst.b	#6,swdata1+0
		beq.b	?jump7
		btst.b	#5,swdata1+1				* c button check
		beq.b	?jump77
		subq.b	#1,editno
		bcc.b	?jump6
		add.b	d6,editno
		bra.b	?jump6
?jump77:
		btst.b	#6,swdata1+1
		beq.b	?jump7
		addq.b	#1,editno
		cmp.b	editno,d6
		bhi.b	?jump6
		move.b	#0,editno
?jump6:
		bra.w	editpatchg
?jump7:
		btst.b	#5,swdata1+1				* c button check
		beq.b	?jump8
		jsr	actwkchk
		bne.b	?worknai					;z=0:ok z=1:no
		move.w	xposi(a0),xposi(a1)
		move.w	yposi(a0),yposi(a1)
		move.b	patbase(a0),actno(a1)
		move.b	actflg(a0),actflg(a1)
		move.b	actflg(a0),cddat(a1)
		andi.b	#$7f,cddat(a1)
		moveq	#0,d0
		move.b	editno,d0
		lsl.w	#3,d0
		move.b	4(a2,d0.w),userflag(a1)
		rts
?worknai:
?jump8:
		btst.b	#4,swdata1+1				* b button check
		beq.b	?jump9
		moveq	#0,d0
		move.w	d0,editmode
		move.l	#playpat,playerwk+patbase
		move.w	#$0780,playerwk+sproffset
		move.b	d0,playerwk+mstno
		move.w	d0,xposi+2(a0)
		move.w	d0,yposi+2(a0)
		move.w	editstack,scralim_up
		move.w	editstack2,scralim_n_down
		cmpi.b	#spgamemd,gmmode
		bne.b	?jump9
		clr.w	rotdir
		move.w	#$040,rotspd
		move.l	#playpat,playerwk+patbase
		move.w	#$0780,playerwk+sproffset
		move.b	#$02,playerwk+mstno
		bset.b	#cd_ball,playerwk+cddat
		bset.b	#cd_jump,playerwk+cddat
?jump9:
		rts	
editpatchg:
		moveq	#0,d0
		move.b	editno,d0
		lsl.w	#3,d0
		move.l	0(a2,d0.w),patbase(a0)
		move.w	6(a2,d0.w),sproffset(a0)
		move.b	5(a2,d0.w),patno(a0)
*		move.b	4(a2,d0.w),userflag(a0)
		rts	

dcblw	macro	\1,\2,\3,\4,\5
		dc.l	(\1)*$1000000+(\2)
		dc.w	(\4)+(\5)*$100
		dc.w	(\3)
		endm

edittbl:
		dc.w	edit1tbl-edittbl
		dc.w	edit2tbl-edittbl
		dc.w	edit3tbl-edittbl
		dc.w	edit4tbl-edittbl
		dc.w	edit5tbl-edittbl
		dc.w	edit6tbl-edittbl
		dc.w	edit7tbl-edittbl
edit1tbl:
		dc.w	16
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	kani_act,kanipat,$0400,0,$00		;3:
		dcblw	hachi_act,hachipat,$0444,0,$00		;4:
		dcblw	fish_act,Map_fish,$047b,0,$00		;5:
		dcblw	toge_act,togepat,$051b,0,$00		;6:
		dcblw	shima_act,shimapat2,$4000,0,$00		;7:
		dcblw	jyama_act,jyamapat,$63d0,0,$00		;8:
		dcblw	musi_act,musipat,$04f0,0,$00		;9:
		dcblw	sjump_act,sjumppat,$0523,0,$00		;10:
		dcblw	kamere_act,kamerepat,$249b,0,$00	;11:
		dcblw	kageb_act,kagebpat,$434c,0,$00		;12:
		dcblw	ball_act,ballpat,$43aa,0,$00		;13:
		dcblw	save_act,savepat,$07a0,0,$01		;14:
		dcblw	bigring_act,Map_obj4B,$0240,0,$00	;15:
		dcblw	bten_act,btenpat,$84B6,1,$01		;16:
edit2tbl:
		dc.w 25
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	sjump_act,sjumppat,$0523,0,$00		;3:
		dcblw	fish2_act,fish2pat,$2486,0,$08		;4:
		dcblw	mogura_act,mogurapat,$84a6,2,$00	;5:
		dcblw	yari_act,yaripat,$03cc,0,$00		;6:
		dcblw	yari_act,yaripat,$03cc,3,$02		;7:
		dcblw	box_act,boxpat,$43de,0,$00			;8:
		dcblw	switch2_act,switch2pat,$0513,0,$00	;9:
		dcblw	toge_act,togepat,$051b,0,$00		;10:
		dcblw	dai_act,udaipat,$43bc,0,$04			;11:
		dcblw	dai3_act,dai3pat,$43e6,0,$01		;12:
		dcblw	dai3_act,dai3pat,$43e6,1,$13		;13:
		dcblw	dai3_act,dai3pat,$43e6,0,$05		;14:
		dcblw	kazari_act,kazaripat,$443e,0,$00	;15:
		dcblw	dai3_act,dai3pat,$43e6,2,$27		;16:
		dcblw	dai3_act,dai3pat,$43e6,3,$30		;17:
		dcblw	kassya_act,kassyapat,$03f6,0,$7f	;18:
		dcblw	uni_act,unipat,$0467,0,$00			;19:
		dcblw	awa_act,awapat,$8348,19,$84			;20:
		dcblw	mizu_act,mizupat,$c259,2,$02		;21:
		dcblw	mizu_act,mizupat,$c259,9,$09		;22:
		dcblw	bou_act,boupat,$43de,0,$00			;23:
		dcblw	ben_act,benpat,$4328,0,$02			;24:
		dcblw	save_act,savepat,$07a0,0,$01		;25:
edit3tbl:
		dc.w 18
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	hachi_act,hachipat,$0444,0,$00		;3:
		dcblw	toge_act,togepat,$051b,0,$00		;4:
		dcblw	sjump_act,sjumppat,$0523,0,$00		;5:
		dcblw	mfire_act,firepat,$0345,0,$00		;6:
		dcblw	fblock_act,fblockpat,$4000,0,$00	;7:
		dcblw	myogan_act,yoganpat,$63a8,0,$00		;8:
		dcblw	yogan2_act,yogan2pat,$63a8,0,$00	;9:
		dcblw	box_act,boxpat,$42b8,0,$00			;10:
		dcblw	yado_act,yadopat,$247b,0,$00		;11:
		dcblw	bryuka_act,bryukapat,$42b8,0,$00	;12:
		dcblw	dai_act,daipat,$02b8,0,$00			;13:
		dcblw	break2_act,break2pat,$62b8,0,$00	;14:
		dcblw	yoganc_act,yogancpat,$8680,0,$00	;15:
		dcblw	bat_act,batpat,$04b8,0,$00			;16:
		dcblw	imo_act,imopat,$24ff,0,$00			;17:
		dcblw	save_act,savepat,$07a0,0,$01		;18:
edit4tbl:
		dc.w 15
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	elev_act,elevpat,$4000,0,$00		;3:
		dcblw	break2_act,break2pat,$44e0,2,$00	;4:
		dcblw	shima_act,z4daipat,$4000,0,$00		;5:
		dcblw	pedal_act,pedalpat,$4000,0,$00		;6:
		dcblw	step_act,steppat,$4000,0,$00		;7:
		dcblw	fun_act,funpat,$43a0,0,$00			;8:
		dcblw	sisoo_act,sisoopat,$0374,0,$00		;9:
		dcblw	sjump_act,sjumppat,$0523,0,$00		;10:
		dcblw	mfire_act,firepat,$0480,0,$00		;11:
		dcblw	bgspr_act,hassyapat,$44d8,0,$00		;12:
		dcblw	brobo_act,brobopat,$0400,0,$00		;13:
		dcblw	uni_act,unipat,$2429,0,$00			;14:
		dcblw	save_act,savepat,$07a0,0,$01		;15:

edit5tbl:
		dc.w 15
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	toge_act,togepat,$051b,0,$00		;3:
		dcblw	sjump_act,sjumppat,$0523,0,$00		;4:
		dcblw	aruma_act,arumapat,$04b8,0,$00		;5:
		dcblw	signal_act,signalpat,$0000,0,$00	;6:
		dcblw	bobin_act,bobinpat,$0380,0,$00		;7:
		dcblw	kani_act,kanipat,$0400,0,$00		;8:
		dcblw	hachi_act,hachipat,$0444,0,$00		;9:
		dcblw	yado_act,yadopat,$247b,0,$00		;10:
		dcblw	shima_act,z5daipat,$4000,0,$00		;11:
		dcblw	dai2_act,dai2pat,$4000,0,$00		;12:
		dcblw	switch2_act,switch2pat,$0513,0,$00	;13:
		dcblw	imo_act,imopat,$24ff,0,$00			;14:
		dcblw	save_act,savepat,$07a0,0,$01		;15:

edit6tbl:
		dc.w 29
		dcblw	ring_act,ringpat,$27b2,0,$00		;1:
		dcblw	item_act,itempat,$0680,0,$00		;2:
		dcblw	brobo_act,brobopat,$0400,0,$00		;3:
		dcblw	uni_act,unipat,$0429,0,$00			;4:
		dcblw	imo_act,imopat,$22b0,0,$00			;5:
		dcblw	buranko_act,fetamapat,$4391,2,$07	;6:
		dcblw	haguruma_act,hagurumapat,$c344,00,$e0;7:
		dcblw	dai_act,daipat,$22c0,2,$28			;8:
		dcblw	switch2_act,switch2pat,$0513,0,$00	;9:
		dcblw	pata_act,patapat,$4492,0,$03		;10:
		dcblw	pata_act,yukafpat,$04df,0,$83		;11:
		dcblw	noko_act,nokopat,$43b5,0,$02		;12:
		dcblw	break2_act,break2pat,$43f5,0,$00	;13:
		dcblw	dai_act,daipat,$4460,3,$39			;14:
		dcblw	dai4_act,dai4pat,$22c0,0,$00		;15:
		dcblw	door_act,doorpat,$42e8,0,$00		;16:
		dcblw	dai4_act,dai4pat,$22c0,1,$13		;17:
		dcblw	noko_act,nokopat,$43b5,0,$01		;18:
		dcblw	dai4_act,dai4pat,$22c0,1,$24		;19:
		dcblw	noko_act,nokopat,$43b5,2,$04		;20:
		dcblw	dai4_act,dai4pat,$22c0,1,$34		;21:
		dcblw	yukae_act,yukaepat,$44c3,0,$00		;22:
		dcblw	fire6_act,fire6pat,$83d9,0,$64		;23:
		dcblw	fire6_act,fire6pat,$83d9,11,$64		;24:
		dcblw	ele_act,elepat,$047e,0,$04			;25:
		dcblw	yukai_act,yukaipat,$42f0,0,$00		;26:
		dcblw	scoli_act,scolipat,$8680,0,$11		;27:
		dcblw	buta_act,butapat,$2302,0,$04		;28:
		dcblw	save_act,savepat,$07a0,0,$01

edit7tbl:
		dc.w 13
		dcblw	ring_act,ringpat,$27b2,0,$00		;1
		dcblw	bobin_act,bobinpat,$0380,0,$00		;2
		dcblw	usagi_act,flicpat,$05a0,0,$0a		;3
		dcblw	usagi_act,flicpat,$05a0,0,$0b		;4
		dcblw	usagi_act,flicpat,$05a0,0,$0c		;5
		dcblw	usagi_act,usagipat,$0553,0,$0d		;6
		dcblw	usagi_act,usagipat,$0553,0,$0e		;7
		dcblw	usagi_act,pengpat,$0573,0,$0f		;8
		dcblw	usagi_act,pengpat,$0573,0,$10		;9
		dcblw	usagi_act,azarpat,$0585,0,$11		;10
		dcblw	usagi_act,fbutapat,$0593,0,$12		;11
		dcblw	usagi_act,niwapat,$0565,0,$13		;12
		dcblw	usagi_act,risupat,$05b3,0,$14		;13

;------------------------------------------------------------------------------
		align
;------------------------------------------------------------------------------
		end