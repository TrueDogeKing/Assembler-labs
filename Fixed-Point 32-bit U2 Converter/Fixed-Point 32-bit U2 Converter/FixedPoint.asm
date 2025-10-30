.686
.model flat

public _main
extern _ExitProcess@4 : PROC
extern __read:proc
extern __write:proc

; ============================================================
; Project: Fixed-Point 64-bit U2 Converter
; Function: Reads a 64-bit signed fixed-point (Q24.8 format) number,
;           and prints decimal number with two digits after the dot on console.
; ============================================================


.data
text db 30 dup(0)
buffer db 25 dup(0)

	
.code


_main PROC  


    push 24         ; max characters to read
    push offset buffer ; where to store the input
    push 0            ; stdin (keyboard)
    call __read
    add esp, 12

	mov esi, offset buffer
	call atoi_hex ; convert string to integer in eax
	mov edx,eax
	call atoi_hex



	call display




	push 0
	call _ExitProcess@4

_main ENDP


; ============================================================
; atoi_hex: Converts hexadecimal string to integer
; Input: ESI = pointer to null-terminated hex string
; Output: EAX = converted integer value, ESI increased 
; ============================================================
atoi_hex PROC
		push ebx
		push ecx
		push edx
    
		xor eax, eax            
		xor ebx, ebx   
		mov ecx,8;
    
	convert_loop:
		mov bl, [esi]           ; Get current character
		inc esi
    
		; Check for null terminator
		cmp bl, 0
		je done
    
		; Check for carriage return or newline (common in console input)
		cmp bl, 13              ; CR
		je done
		cmp bl, 10              ; LF  
		je done
    
		; Skip spaces
		cmp bl, ' '
		je convert_loop
    
		; Convert character to value
		call char_to_hex_value
    
		; Shift and add (EAX = EAX * 16 + value)
		shl eax, 4              ; Multiply by 16
		add eax, edx            ; Add new digit
    
		loop convert_loop

	done:
		pop edx
		pop ecx
		pop ebx
		ret
atoi_hex ENDP

; ============================================================
; char_to_hex_value: Converts ASCII char to hex value
; Input: BL = ASCII character
; Output: EDX = hex value (0-15)
; ============================================================
char_to_hex_value PROC
		; Check if it's a digit '0'-'9'
		cmp bl, '0'
		jb invalid_char
		cmp bl, '9'
		ja check_upper
    
		; It's a digit 0-9
		sub bl, '0'
		movzx edx, bl
		jmp valid_char
    
	check_upper:
		; Check if it's uppercase 'A'-'F'
		cmp bl, 'A'
		jb invalid_char
		cmp bl, 'F'
		ja check_lower
    
		; It's uppercase A-F
		sub bl, 'A' - 10
		movzx edx, bl
		jmp valid_char
    
	check_lower:
		; Check if it's lowercase 'a'-'f'
		cmp bl, 'a'
		jb invalid_char
		cmp bl, 'f'
		ja invalid_char
    
		; It's lowercase a-f
		sub bl, 'a' - 10
		movzx edx, bl
    
	valid_char:
		ret

	invalid_char:
		; If invalid character, treat as 0
		xor edx, edx
		ret
char_to_hex_value ENDP


; ============================================================
; display: Converts EAX to ASCII string with two decimal places
;		   and displays it with __write
; Input:  EAX - number to convert
; Output: none
; ============================================================
display PROC
		push ebp
		mov ebp, esp
		sub esp,4
		push ebx
		push edx
		push esi
		push ecx
		push eax

		xor ebx,ebx
		
		mov esi,offset text
		; check sign and delete it after converting the sign into char
		bt edx,31
		jc  negative_number
		mov [esi], byte ptr '+'
		jmp continue_encoding
	negative_number:
		mov [esi],byte ptr '-'
		mov bl,al
		neg eax
		neg edx
		dec edx
		dec eax
		add eax,100h
		adc edx,0

		mov al,bl
	continue_encoding:
		mov ecx,8
	decimal_loop:
		shr edx,1
		rcr eax,1
		rcr bl,1
		loop decimal_loop
		; now eax holds the integer part, bl - the decimal part
		mov [ebp-4],ebx  ; save dacimal part in stack

		; encode integer part
		mov ecx,17
	next_char:
		call one_char_2registers
		mov [esi+ecx],bl
		loop next_char

		; now the decimal point
		add esi,18 ; skip the integer part
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
		
		push 30
		push offset text
		push 1
		call __write
		add esp,12
		
		pop eax
		pop ecx
		pop esi
		pop edx
		pop ebx
		add esp,4
		pop ebp
        ret
display ENDP



; ============================================================
; one_char: convert last digit of EAX to ASCII character
; Input:  EAX - number, EDX will be overwritten
; Output: DL - ASCII character of the last digit
; ============================================================
one_char PROC
		push ebx
		xor edx,edx

		mov ebx,10d
		div ebx
		add dl,'0'

		pop ebx
		ret
one_char ENDP


; ============================================================
; one_char_2registers
; Divide 64-bit unsigned integer (EBX:EAX) by 10
; Outputs:
;   EBX:EAX = quotient (64-bit)
;   EBX     = remainder (mod 10)
; ============================================================

one_char_2registers PROC
    push esi
    push edi
	push ecx

    mov esi,eax        ; save low part
    mov edi,edx        ; save high part

    ; --- Step 1: divide high part by 10 ---
    mov eax,edi
    xor edx,edx
    mov ecx,10d
    div ecx             ; EAX = high_quotient, EDX = high_remainder
	
    mov edi,edx        ; edi = high_remainder
    mov ebx,eax        ; ebx = high_quotient

    ; --- Step 2: combine remainder from high with low part ---
    ; numerator = (high_remainder << 32) | low
    mov eax,esi        ; low part
    mov edx,edi        ; high_remainder
    div ecx             ; divide by 10 again
                            ; EAX = low_quotient, EDX = final_remainder
	
    ; --- Step 3: combine quotients into 64-bit result ---
    mov ecx,edx
	mov edx,ebx
	mov ebx,ecx
	add ebx,'0'  ; convert remainder to ASCII
    ; eax already holds low_quotient
	pop ecx
    pop edi
    pop esi
    ret
one_char_2registers ENDP

; ============================================================
; cut_zeros: remove leading zeros in the text (data segment)
; Input:  none
; Output: adjusted given string 
; ============================================================
cut_zeros PROC
		push ecx
		push esi
		push edi

		cld ;movsb going up

	check_if_zero:
		mov esi,offset text
		inc esi ;skip sign
		cmp byte ptr [esi+1], '.'
		je done_checking
		cmp byte ptr [esi], '0'
		jne done_checking

		mov edi,esi
		inc esi

		mov ecx,20
		rep movsb
		jmp check_if_zero

	done_checking:

		pop edi
		pop esi
		pop ecx
		ret
cut_zeros ENDP




 END