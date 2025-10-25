.686
.model flat

public _main
extern _MessageBoxW@16 : PROC
extern _MessageBoxA@16 : PROC
extern _ExitProcess@4 : PROC


; ============================================================
; Project: Fixed-Point 32-bit U2 Converter
; Function: Reads a hexadecimal string, converts to 32-bit signed
;           integer, interprets it as fixed-point (Q24.8 format),
;           and prints decimal number with two digits after the dot.
; ============================================================


.data
text db 64 dup(?)

	
.code
_main PROC  
	mov eax,0000FFFFh
	
	mov esi,offset text
	call encode_dc_to_ascii


	; Example MessageBoxA call
	push 0
	push offset text
	push offset text
	push 0
	call _MessageBoxA@16

	push 0
	call _ExitProcess@4

_main ENDP

encode_dc_to_ascii PROC
		push ebx
		push edx



		bt eax,31
		jc  negative_number
		mov [esi], byte ptr '+'
		jmp continue_encoding
	negative_number:
		mov [esi],byte ptr '-'
		btr eax,31

	continue_encoding:
		mov ecx,8
	decimal_loop:
		shr eax,1
		rcr bl,1
		loop decimal_loop

		mov ecx,7
	next_char:
		call one_char
		mov [esi+ecx],dl
		loop next_char

		; now the decimal point
		add esi,8
		mov byte ptr [esi],'.'

		mov eax,ebx

		mov ecx,100d
		mov edx,0
		mul ecx
		mov ecx,256
		div ecx

		mov ecx,2
		mov byte ptr [esi+ecx+1],0
	fraction_loop:
		call one_char
		mov [esi+ecx],dl
		loop fraction_loop


		call cut_zeros
		
		pop edx
		pop ebx
        ret
encode_dc_to_ascii ENDP

one_char PROC
		push ecx
		mov edx,0

		mov ecx,10d
		div ecx
		add dl,'0'

		pop ecx
		ret
one_char ENDP


cut_zeros PROC
		push ecx
		push ebx

		mov esi,offset text
		inc esi
	check_fraction:
		mov ecx,10
		cmp byte ptr [esi], '0'
		jne done_checking

		mov edi,0
	next_check:
		mov al, [esi+edi+1]
		mov [esi+edi], al
		inc edi
		loop next_check
		jmp check_fraction

	done_checking:

		pop ebx
		pop ecx
		ret
cut_zeros ENDP




 END