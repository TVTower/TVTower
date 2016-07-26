format MS COFF

public _bbCallMethod
extrn _memcpy

section	"code" code

_bbCallMethod:
	push ebp
	mov ebp, esp
	sub esp, dword [ebp+16]
	push dword [ebp+16]
	push dword [ebp+12]
	push esp
	call _memcpy
	add esp, 4
	call dword [ebp+8]
	mov esp, ebp
	pop ebp
	ret
