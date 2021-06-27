name	daccha
title	らむ変換ユーティリティ

;	『らむ言葉にするだっちゃ』　[ daccha.asm ]    Ver. 0.23
;

INT29H	equ	29h
LF	equ	0ah
CR	equ	0dh
;

CODE	segment
	assume	cs:CODE,ds:CODE
;
;	PSP領域 (0ch～0ffh)
;
	org	2ch
envseg	dw	?
	org	80h
argc	db	?
argv	db	127 dup (?)

stktop	label	word

	org	100h
start:	jmp	initial

;
;	キー割り込み処理（常駐本体）
;

n_flg	db	0
trn$	db	"っちゃ",0

new29	proc
	sti
	cmp	[n_flg],0	;1byte目が別の何かだったら
	jne	nest_pro
	cmp	al,'.'		;'.'だったら
	je	chk_1
	cmp	al,81h		;1byte目だったら
	je	chk_2
not_lum:
	cli
jmpold:	db	0eah
old29h	dd	?

;半角ピリオドの場合
chk_1:
	lea	di,trn$
daccha_p:
	mov	al,cs:[di]
	inc	di
	or	al,al
	jz	out_p
	pushf
	cli
	call	cs:[old29h]
	jmp	daccha_p
out_p:	mov	al,02eh		;'.'
	pushf
	cli
	call	cs:[old29h]
	iret

;漢字パターンの場合
chk_2:
	mov	[n_flg],al
	iret

;もしかしてらむ
nest_pro:
	push	ax
	push	di
	mov	[n_flg],0
	cmp	al,42h		;。
	je	lum_z
	cmp	al,44h		;．
	je	lum_z
	cmp	al,49h		;！
	je	lum_z
	
	mov	al,81h		;どうやら違うようだ
	pushf
	cli
	call	cs:[old29h]
	pop	di
	pop	ax
	jmp	not_lum

;ほんとにらむ
lum_z:
	lea	di,trn$
daccha_z:
	mov	al,cs:[di]
	inc	di
	or	al,al
	jz	out_z
	pushf
	cli
	call	cs:[old29h]
	jmp	daccha_z
out_z:	mov	al,81h		;語尾１
	pushf
	cli
	call	cs:[old29h]
	pop	di
	pop	ax
	jmp	not_lum
new29	endp

breakadr label	byte
;

;
;	初期化部分
;

initial:
	cmp	[argc],0
	jz	argend
	mov	si,offset argv
arglp:	call	getarg
	cmp	al,CR
	je	argend
	cmp	al,'R'
	je	argr
	mov	dx,offset unk$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
	;
argend:
	mov	ax,3500h+INT29H
	int	21h
	call	chkmem
	jz	exist
	mov	word ptr cs:[old29h],bx
	mov	word ptr cs:[old29h+2],es
	mov	ax,2500h+INT29H
	mov	dx,offset new29
	int	21h
;
;	環境変数の解放
;
	mov	es,[envseg]
	mov	ah,49h
	int	21h
	mov	[envseg],0
;
;	常駐処理
;
	mov	dx,offset reside$
	mov	ah,09h
	int	21h
	lea	dx,[breakadr+0fh]
	mov	cl,4
	shr	dx,cl
	mov	ax,3100h
	int	21h
;実は既に常駐していた
exist:	mov	dx,offset exist$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;
;	常駐解放
;
argr:
	mov	ax,3500h+INT29H
	int	21h
	call	chkmem
	jnz	notexist
	push	ds
	lds	dx,es:[old29h]
	mov	ax,2500h+INT29H
	int	21h
	pop	ds
	mov	ah,49h
	int	21h
	jc	relerr
	mov	dx,offset rel$
	mov	ah,09h
	int	21h
	mov	ax,4c00h
	int	21h
;解放失敗
relerr:
	mov	dx,offset relerr$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;実は常駐していなかった
notexist:
	mov	dx,offset notex$
	mov	ah,09h
	int	21h
	mov	ax,4c01h
	int	21h
;
;	メモリ常駐確認
;
chkmem	proc
	mov	si,offset new29
	mov	di,offset new29
	mov	cx,(offset jmpold - offset new29 + 3)
	cld
	repe	cmpsb
	ret
chkmem	endp

;
;	引数取得
;
getarg	proc
	lodsb
	cmp	al,' '
	jz	getarg
	cmp	al,09h
	jz	getarg
	cmp	al,','
	jz	getarg
	cmp	al,'-'
	jz	getarg
	cmp	al,'/'
	jz	getarg
	cmp	al,'a'
	jb	getarge
	cmp	al,'z'
	ja	getarge
	sub	al,'a'-'A'
getarge:
	ret
getarg	endp

unk$	db	"そういうオプションはないっちゃ",CR,LF,"$"
reside$	db	"らむが常駐したっちゃ",CR,LF,"$"
exist$	db	"既に常駐しているっちゃ",CR,LF,"$"
rel$	db	"らむを解除しましたっちゃ",CR,LF,"$"
relerr$	db	"逃げることはできないっちゃ",CR,LF,"$"
notex$	db	"らむはいないっちゃ",CR,LF,"$"

CODE	ends
	end	start
