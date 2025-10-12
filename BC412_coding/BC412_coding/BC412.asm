.686
.model flat

public _main
extern _MessageBoxW@16 : PROC
extern _MessageBoxA@16 : PROC
extern _ExitProcess@4 : PROC


; ------------------------------------------------------------
; Program: BC412 Character Encoder + Checksum Calculator
; File: bc412.asm
; Author: Doge_King
; Description:
;   This program takes an ASCII character ('0'-'9', 'A'-'Z' excluding 'O')
;   and converts it into its BC412 barcode representation.
;   The 12-bit pattern is written to memory at the address pointed to by EDI.
;   A bar is represented by bit '1', and a space by bit '0'.
;   The program also calculates a checksum for a given character string:
;   checksum = (sum of character values) mod 35.
;
; Environment: 32-bit x86 Assembly
; ------------------------------------------------------------

.data
	suma_kontrolna db ? ; miejsce na przechowanie sumy kontrolnej
	znaki db 1,1,1,5     ; '0'
    dw 0
    db 1,1,2,4     ; '1'
    dw 15
    db 1,1,3,3     ; '2'
    dw 17
    db 1,1,4,2     ; '3'
    dw 29
    db 1,1,5,1     ; '4'
    dw 11
    db 1,2,1,4     ; '5'
    dw 33
    db 1,2,2,3     ; '6'
    dw 19
    db 1,2,3,2     ; '7'
    dw 21
    db 1,2,4,1     ; '8'
    dw 8
    db 1,3,1,3     ; '9'
    dw 2

    ; Letters (A–Z, without 'O')
    db 1,3,2,2     ; 'A'
    dw 7
    db 1,3,3,1     ; 'B'
    dw 25
    db 1,4,1,2     ; 'C'
    dw 20
    db 1,4,2,1     ; 'D'
    dw 22
    db 1,5,1,1     ; 'E'
    dw 9
    db 2,1,1,4     ; 'F'
    dw 30
    db 2,1,2,3     ; 'G'
    dw 3
    db 2,1,3,2     ; 'H'
    dw 6
    db 2,1,4,1     ; 'I'
    dw 27
    db 2,2,1,3     ; 'J'
    dw 16
    db 2,2,2,2     ; 'K'
    dw 24
    db 2,2,3,1     ; 'L'
    dw 4
    db 2,3,1,2     ; 'M'
    dw 34
    db 2,3,2,1     ; 'N'
    dw 12
    db 2,4,1,1     ; 'P' (skips 'O')
    dw 32
    db 3,1,1,3     ; 'Q'
    dw 18
    db 3,1,2,2     ; 'R'
    dw 1
    db 3,1,2,2     ; 'S' (duplicate pattern per spec)
    dw 14
    db 3,2,1,2     ; 'T'
    dw 13
    db 3,2,2,1     ; 'U'
    dw 26
    db 3,3,1,1     ; 'V'
    dw 5
    db 4,1,1,2     ; 'W'
    dw 31
    db 4,1,2,1     ; 'X'
    dw 28
    db 4,2,1,1     ; 'Y'
    dw 23
    db 5,1,1,1     ; 'Z'
    dw 10

	result dd ? ; miejsce na przechowanie wyniku kodowania
    testString db "AZUX",0
    checksum   dd 0

.code
_main PROC  
	; Example usage of encode_bc412
    push edx
    xor eax,eax
	mov al, '0'          ; Example character
    lea edi, result       ; Where to store result
    lea edx,testString  ; Point to test string
string_loop:
    mov al, [edx]
    cmp al, 0
    je done
    call encode_bc412
    cmp eax, -1
    je invalid_input
    ;add edi,4
    inc edx
    jmp string_loop

	;mov bx, word ptr [edi]   ; load from memory pointed by EDI into AX
    ;mov result, bx           ; store AX into variable 'result'

invalid_input:
done:
	; Calculate checksum modulo 35
 	mov eax, checksum
	mov ebx, 35
	xor edx, edx
	div ebx
	mov suma_kontrolna, dl   ; store checksum in byte variable
    
    pop edx
	; Display result (for demonstration purposes)
	; Here you can add code to display the result or checksum if needed
	; Program exit
	push 0
	call _ExitProcess@4

_main ENDP

encode_bc412 PROC
	; Input: AL = character to encode
    ; ecx = temporary register used in AX=al*cl, cl=6 for table index
	; Output: 12-bit pattern stored at [EDI]
    push ecx
    push esi
    push edx
    mov ecx,6

	lea esi,znaki 

	; Validate input character
	cmp al, '0'
	jb invalid_char
	cmp al, '9'
	jbe valid_number
	cmp al, 'A'
	jb invalid_char
	cmp al, 'Z'
	ja invalid_char
	cmp al, 'O'
	je invalid_char
    ; valid character
    cmp al, 'O'
    ja valid_char_above
    ;valid character below 'O'
        sub al,'A'
        add al,10
        mul cl
        add esi, eax
        jmp store_result
    valid_char_above:
        sub al,'A'
        add al,9
		mul cl
		add esi, eax
		jmp store_result
    invalid_char:
		; Invalid character handling
		mov eax, -1
		jmp store_result
    valid_number:
    ; Calculate index in the table
        sub al, '0'
        mul cl
        add esi, eax
        jmp store_result

        store_result:
        push eax
        xor edx,edx
        xor eax,eax
        xor ecx,ecx
        add esi,4
        mov al,[esi]
        add checksum, eax
        dec esi
        xor eax,eax
    keep_encoding:
        mov dl,[esi]
        dec esi
        ; shl can be used instead of coding_loop
        coding_loop:
			inc cx
            dec dl
			jnz coding_loop
        cmp cx,12
        ja end_encoding

        bts ax,cx
        inc cx
		mov dl,[esi]
        jmp keep_encoding
    end_encoding:
        mov [edi],ax
        pop eax
        pop edx
        pop esi
        pop ecx
        ret
encode_bc412 ENDP




 END