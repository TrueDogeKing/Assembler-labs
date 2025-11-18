.686
.model flat

; Importowane funkcje
extern _GetDiskFreeSpaceExA@16: proc
extern _putchar: proc

.data
text db 30 dup(0)

.code

; ============================================================
; rozmiar_dysku: Main function - gets disk size and displays it
; ============================================================
_rozmiar_dysku proc
    push ebp
    mov ebp, esp
    sub esp, 16
    push ebx
    push esi
    push edi
    
    
    ; Pobranie parametru (wskaŸnik do nazwy dysku)
    mov ebx, [ebp+8]

    lea esi,[ebp-8]
    
    ; Wywo³anie GetDiskFreeSpaceEx
    push esi           ; lpTotalNumberOfFreeBytes
    lea esi,[esi-8]
    push esi           ; lpTotalNumberOfBytes
    push 0             ; lpFreeBytesAvailableToCaller
    push ebx           ; lpDirectoryName
    
    call _GetDiskFreeSpaceExA@16
    
    ; Pobranie rozmiaru dysku (64-bit)
    mov eax, [esi]   ; m³odsze 32 bity
    mov edx, [esi+4]   ; starsze 32 bity
    
    ; Wyœwietlenie rozmiaru u¿ywaj¹c Twojej funkcji display
    call display_64bit
    
    mov eax, [esi]   ; zwróæ m³odsze 32 bity

koniec:
    pop edi
    pop esi
    pop ebx
    add esp, 16
    mov esp, ebp
    pop ebp
    ret
_rozmiar_dysku endp

; ============================================================
; display_64bit: Displays 64-bit number using your algorithm
; Input: EDX:EAX = 64-bit number to display
; ============================================================
display_64bit PROC
    push ebp
    mov ebp, esp
    push ebx
    push edx
    push esi
    push ecx
    push eax

    mov esi, offset text
    
    
    ; Konwersja 64-bit liczby na string
    mov ecx, 21  ; maksymalna liczba cyfr
    mov byte ptr [esi+ecx+1], 0 ; null terminator
    
next_char:
    call one_char_2registers  ; Twoja funkcja do dzielenia 64-bit
    mov [esi+ecx-1], bl        ; zapisz cyfrê
    loop next_char

    ; Usuñ wiod¹ce zera
    call cut_zeros
    
    ; Wyœwietl wynik u¿ywaj¹c putchar zamiast __write
    mov esi, offset text
display_loop:
    mov al, [esi]
    test al, al
    jz display_done
    
    push eax
    call _putchar
    add esp, 4
    
    inc esi
    jmp display_loop

display_done:
    ; Dodaj znak nowej linii dla czytelnoœci
    push 10  ; '\n'
    call _putchar
    add esp, 4
    
    pop eax
    pop ecx
    pop esi
    pop edx
    pop ebx
    mov esp, ebp
    pop ebp
    ret
display_64bit ENDP

; ============================================================
; one_char_2registers - bez zmian (Twoja funkcja)
; Divide 64-bit unsigned integer (EDX:EAX) by 10
; Outputs:
;   EDX:EAX = quotient (64-bit)
;   EBX     = remainder (mod 10) as ASCII
; ============================================================
one_char_2registers PROC
    push esi
    push edi
    push ecx

    mov esi, eax        ; save low part
    mov edi, edx        ; save high part

    ; --- Step 1: divide high part by 10 ---
    mov eax, edi
    xor edx, edx
    mov ecx, 10d
    div ecx             ; EAX = high_quotient, EDX = high_remainder
    
    mov edi, edx        ; edi = high_remainder
    mov ebx, eax        ; ebx = high_quotient

    ; --- Step 2: combine remainder from high with low part ---
    mov eax, esi        ; low part
    mov edx, edi        ; high_remainder
    div ecx             ; divide by 10 again
                        ; EAX = low_quotient, EDX = final_remainder
    
    ; --- Step 3: combine quotients into 64-bit result ---
    mov ecx, edx
    mov edx, ebx
    mov ebx, ecx
    add ebx, '0'        ; convert remainder to ASCII
    
    pop ecx
    pop edi
    pop esi
    ret
one_char_2registers ENDP

; ============================================================
; cut_zeros - bez zmian (Twoja funkcja)
; remove leading zeros in the text
; ============================================================
cut_zeros PROC
    push ecx
    push esi
    push edi

    cld ; movsb going up

check_if_zero:
    mov esi, offset text
    cmp byte ptr [esi+1], 0  ; sprawdŸ koniec stringa
    je done_checking
    cmp byte ptr [esi], '0'
    jne done_checking

    mov edi, esi
    inc esi
    mov ecx, 22
    rep movsb
    jmp check_if_zero

done_checking:
    pop edi
    pop esi
    pop ecx
    ret
cut_zeros ENDP

end