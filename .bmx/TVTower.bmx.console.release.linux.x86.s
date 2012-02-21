	format	ELF
	extrn	__bb_blitz_blitz
	extrn	__bb_source_main
	extrn	bbIncbinAdd
	extrn	bbStringClass
	public	_bb_main
	section	"code" executable
_bb_main:
	push	ebp
	mov	ebp,esp
	cmp	dword [_23],0
	je	_24
	mov	eax,0
	mov	esp,ebp
	pop	ebp
	ret
_24:
	mov	dword [_23],1
	mov	eax,_22
	sub	eax,_21
	push	eax
	push	_21
	push	_20
	call	bbIncbinAdd
	add	esp,12
	call	__bb_blitz_blitz
	call	__bb_source_main
	mov	eax,0
	jmp	_18
_18:
	mov	esp,ebp
	pop	ebp
	ret
	section	"data" writeable align 8
	align	4
_23:
	dd	0
	align	4
_21:
	file	"/home/ronny/Arbeit/Programmieren/Projekte/Apps/TVTower/source/version.txt"
_22:
	align	4
_20:
	dd	bbStringClass
	dd	2147483647
	dd	18
	dw	115,111,117,114,99,101,47,118,101,114,115,105,111,110,46,116
	dw	120,116
