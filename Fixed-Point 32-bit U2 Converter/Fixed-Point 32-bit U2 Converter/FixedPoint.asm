.686
.model flat

public _main
extern _MessageBoxA@16 : PROC
extern _ExitProcess@4 : PROC


; ============================================================
; Project: Fixed-Point 32-bit U2 Converter
; Function: Reads a 32-bit signed fixed-point (Q24.8 format) number,
;           and prints decimal number with two digits after the dot on messagebox.
; ============================================================


.data
text db 12 dup(?)

	
.code
_main PROC  
	mov eax,7FFFFFFFh
	
	mov esi,offset text
	call encode_dc_to_ascii


	; Example MessageBoxA call
	push 0
	push esi
	push esi
	push 0
  	call _MessageBoxA@16

	push 0
	call _ExitProcess@4

_main ENDP

encode_dc_to_ascii PROC
		push ebp
		mov ebp, esp
		sub esp,4
		push ebx
		push edx
		push esi
		push ecx


		; check sign and delete it after converting the sign into char
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
		; now eax holds the integer part, bl - the decimal part
		mov [ebp-4],ebx  ; save dacimal part in stack

		; encode integer part
		mov ecx,7
	next_char:
		call one_char
		mov [esi+ecx],dl
		loop next_char

		; now the decimal point
		add esi,8 ; skip the integer part
		mov byte ptr [esi],'.'


		mov eax,[ebp-4] ; load decimal part

		; eax*100/256= decimal decimal within two digits in al
		; multiply by 100 allows us to get two digits after decimal point after division by 256 sth lesser than 256
		mov ebx,100d
		mov edx,0
		mul ebx
		mov ebx,256
		div ebx

		; now al holds the decimal part within two digits
		mov ecx,2
		mov byte ptr [esi+ecx+1],0 ; null-terminator for string
	decimal_to_ascii_loop:
		call one_char
		mov [esi+ecx],dl
		loop decimal_to_ascii_loop

		;  remove leading zeros in the text string
		call cut_zeros
		
		pop ecx
		pop esi
		pop edx
		pop ebx
		add esp,4
		pop ebp
        ret
encode_dc_to_ascii ENDP


; in: eax - number, edx will be overwritten
; out: dl - ASCII character of the last digit
one_char PROC
		push ebx
		xor edx,edx

		mov ebx,10d
		div ebx
		add dl,'0'

		pop ebx
		ret
one_char ENDP

; in: none
; out: remove leading zeros in the decimal part
cut_zeros PROC
		push ecx
		push esi
		push edi

		cld ;movsb going up

	check_if_zero:
		mov esi,offset text
		inc esi

		cmp byte ptr [esi], '0'
		jne done_checking

		mov edi,esi
		inc esi

		;mov ecx,0
		;next_check:
		;mov al, [esi+ecx+1]
		;mov [esi+ecx], al
		;inc ecx
		;cmp ecx,10
		;jb next_check
		;loop next_check

		mov ecx,10
		rep movsb
		jmp check_if_zero

	done_checking:

		pop edi
		pop esi
		pop ecx
		ret
cut_zeros ENDP




 END