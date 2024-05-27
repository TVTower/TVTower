format ELF

public bbCallMethod
extrn memcpy

section	"code"

bbCallMethod:
	push ebp
	mov ebp, esp
	sub esp, dword [ebp+16]
	push dword [ebp+16]
	push dword [ebp+12]
	push esp
	call memcpy
	add esp, 4
	call dword [ebp+8]
	mov esp, ebp
	pop ebp
	ret
