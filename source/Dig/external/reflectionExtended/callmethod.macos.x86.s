

.global _bbCallMethod
.extern _memcpy

.text
	
_bbCallMethod:
	push %ebp
	mov %esp, %ebp
	sub 16(%ebp), %esp
	push 16(%ebp)
	push 12(%ebp)
	push %esp
	call _memcpy
	add 4, %esp
	call *8(%ebp)
	mov %ebp, %esp
	pop %ebp
	ret
