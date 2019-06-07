; AS configuration and original binary file to patch over
	CPU 68000
	PADDING OFF
	ORG		$000000
	BINCLUDE	"prg.orig"

; Byte wide input copies
INPUT_P1 = $100000
INPUT_P2 = $100001

; $0100 when not in free play
DIP_FREE = $100006

ROM_FREE = $0BFD34

FREEPLAY macro
	move.w	d1, -(sp)
	move.w	(DIP_FREE).l, d1
	andi.w	#$0100, d1
	beq	.freeplay_is_enabled
	bra	+

.freeplay_is_enabled:
	move.w	(sp)+, d1
	ENDM

STANDARD macro
	move.w	(sp)+, d1
	ENDM

; A subroutine at 10114 reads inputs and dumps them at $100000
; Coins are on $100008

; Free play ===================================================================

; Start buttons jump to Press Start screen
	ORG	$01BD42
	jmp	alt_coin_check_loop

; Alternate Press Start message during attract
	ORG	$01A25A
	jmp	attract_press_start_message

; Allow join-in without credits
	ORG	$01CB08
	jmp	coin_join_check_1
	ORG	$01CB7C
	jmp	coin_join_check_2
; Allow continue without credits?
	ORG	$01C062
	jmp	coin_continue_check_1
	ORG	$01C0B8
	jmp	coin_continue_check_2
	ORG	$01C0C6
	jmp	coin_continue_check_3
; In-game press start labels
	ORG	$01C67C
	jmp	ingame_start_label_1
	ORG	$01C6C8
	jmp	ingame_start_label_2

; Autofire ====================================================================

; Filter buttons ($10 == main shot)
	ORG	$01012C
	jmp	button_filter

; --------------------------------------------------------------
	ORG	ROM_FREE
	ALIGN	2

button_filter:
	move.w	d0, -(sp)
	move.w	d1, -(sp)
	move.b	($800007).l, d0
	move.b	d0, d1
	; Mask button 3
	andi.b	#$40, d0
	beq	.btn3_pressed

	; Mask button 1 in d0
	move.b	d1, d0
	andi.w	#$10, d0
	beq	.btn1_press
	bra	.btn1_not_pressed

.btn3_pressed:
	andi.b	#$EF, d1

.btn1_not_pressed:
	move.b	d1, -$8000(a5)
	clr.b	(a5)
	bra	.p2_inputs

.btn1_press:
	move.b	d1, d0
	or.b	(a5), d0
	addi.b	#$10, (a5)
	move.b	d0, -$8000(a5)

.p2_inputs:
	move.b	($800005).l, d0
	move.b	d0, d1
	; Mask button 3
	andi.b	#$40, d0
	beq	.p2_btn3_pressed

	; Mask button 1 in d0
	move.b	d1, d0
	andi.w	#$10, d0
	beq	.p2_btn1_press
	bra	.p2_btn1_not_pressed

.p2_btn3_pressed:
	andi.b	#$EF, d1

.p2_btn1_not_pressed:
	move.b	d1, -$7FFF(a5)
	clr.b	$1(a5)
	bra	.done

.p2_btn1_press:
	move.b	d1, d0
	or.b	$1(a5), d0
	addi.b	#$10, $1(a5)
	move.b	d0, -$7FFF(a5)

.done:
	move.w	d0, (sp)+
	move.w	d1, (sp)+
	jmp	($1013C).l


ingame_start_label_1:
	FREEPLAY
	jmp	($01C68A).l

/	STANDARD
	tst.w	-$7F0A(a5)
	bne	.coins_in
	lea	($069C76).l, a0
.coins_in:
	jmp	($01C68A).l

ingame_start_label_2:
	FREEPLAY
	jmp	($01C6D6).l

/	STANDARD
	tst.w	-$7F0A(a5)
	bne	.coins_in
	lea	($069C76).l, a0
.coins_in:
	jmp	($01C6D6).l

coin_continue_check_1:
	FREEPLAY
	jmp	($01C07C).l

/	STANDARD
	tst.w	-$7F0A(a5)
	bgt	.coins_in
	jmp	($01C068).l
.coins_in:
	jmp	($01C07C).l

coin_continue_check_2:
	FREEPLAY
	sub.w	-$7F06(a5), d2
	jmp	($01C0C0).l

/	STANDARD
	subq.w	#1, -$7F0A(a5)
	sub.w	-$7F06(a5), d2
	jmp	($01C0C0).l

coin_continue_check_3:
	FREEPLAY
	jmp	($01C0D2).l

/	STANDARD
	tst.w	-$7F0A(a5)
	beq	.no_coins
	subq.w	#1, -$7F0A(a5)
	jmp	($01C0D2).l

.no_coins:
	jmp	($01C128).l

coin_join_check_1:
	FREEPLAY
	jmp	($01CB22).l

/	STANDARD
	tst.w	-$7F0A(a5)
	bgt	.coins_in
	jmp	($01CB0E).l
.coins_in:
	jmp	($01CB22).l

coin_join_check_2:
	FREEPLAY
	jmp	($01CB86).l

/	STANDARD
	tst.w	-$7F0A(a5)
	beq	.no_coins
	subq.w	#1, -$7F0A(a5)
	jmp	($01CB86).l

.no_coins:
	rts

attract_press_start_message:
	addq.b	#1, -$32C2(a5)
	btst	#6, -$32C2(a5)
	bne	.show_insert_coin
	jmp	($01A266).l

.show_insert_coin:
	FREEPLAY
	lea	a_press_start_string, a0
	jmp	($01A2AA).l

/	STANDARD
	jmp	($01A282).l

a_press_start_string:
	dc.b	"              PRESS START               ", 0
	ALIGN	2

alt_coin_check_loop:
	FREEPLAY
.free_check_top:
	btst	#7, -$8000(a5)
	beq	.start1
	btst	#7, -$7FFF(a5)
	beq	.start2
	trap	#5
	bra	.free_check_top
.start1:
	moveq	#1, d0
	bra	.start_final
.start2:
	moveq	#2, d0
.start_final:
	; Clear the credit count, for good measure.
	clr.w	($100108).l
	clr.w	($10010A).l
	clr.w	($1000F6).l
	move.w	d0, -(sp)
	move.w	#$3FFF, -(sp)
	trap	#2
	addq.l	#2, sp
	jsr	($01C9DA).l
	trap	#5
	move.w	(sp)+, d0
	jmp	($01BDE0).l ; Start of game.

/	STANDARD
.standard_check_top:
	tst.w	-$7F0A(a5)
	bne	.coins_in
	tst.w	-$7F08(a5)
	bne	.skip_chk
	tst.w	-$7EF8(a5)
	bne	.coins_in
	bra	.skip_chk

.coins_in:
	jmp	($01BD58).l
	

.skip_chk:
	trap	#5
	bra	.standard_check_top


	dc.b	"Free play and autofire hack by Michael Moffitt\nmikejmoffitt@gmail.com",0
	ALIGN	2
