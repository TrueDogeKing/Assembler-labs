.386


code SEGMENT use16
ASSUME cs:code

old_int9      dd ?
last_scancode db ?
exit_flag     db 0

; Procedura obs³ugi przerwania klawiatury (INT 9)
handle_int9 PROC
    push ax
    push bx
    push cx
    push dx
    push es
    push ds

    ; odczyt kodu klawisza (make/break)
    in   al, 60h

    ; zapamiêtanie ostatniego kodu
    mov  cs:last_scancode, al

    ;  'k' - make code = 37d = 25h
    cmp  al, 25h
    jne  draw
    
    mov  cs:exit_flag, 1

draw:
    ; ES -> pamiêæ ekranu
    mov ax, 0B800h
    mov es, ax

    ; DS -> BIOS Data Area
    mov ax, 0040h
    mov ds, ax

    ; BX = offset w pamiêci BIOS
    mov bx, 001Eh

    ; CX = licznik (32 bajty)
    mov cx, 32
    ; offset ekranu – pierwszy wiersz
    mov di, 0

draw_loop:
    mov al, ds:[bx]        ; bajt z pamiêci
    call write_hex         ; wypisz w HEX

    
    add di, byte ptr 4              ; odstêp
    inc bx

    bt bx,0
    jc not_even
    sub di,word ptr 160d
    add di, byte ptr 4
    jmp dalej
    not_even:
    add di,word ptr 160d
    sub di, byte ptr 4
dalej:
    loop draw_loop

    pop ds
    pop es
    pop dx
    pop cx
    pop bx
    pop ax

    jmp dword ptr cs:old_int9
handle_int9 ENDP

; =====================================================
; write_hex: wypisuje w pamiêci ekranu wartoœæ w AL w formacie
; in: AL - bajt do wypisania
; out: pamiêæ ekranu pod ES:DI zawiera wartoœæ w formacie al 07h
; =====================================================
write_hex PROC
    push ax
    push bx

    mov bl, al
    shr bl, 4
    call hex_digit
    mov es:[di], al
    mov es:[di+1], byte ptr 07h


    mov bl, al
    and bl, 0Fh
    call hex_digit
    mov es:[di+2], al
    mov es:[di+3], byte ptr 07h

    pop bx
    pop ax
    ret
write_hex ENDP

hex_digit PROC
    add bl, '0'
    cmp bl, '9'
    jbe ok
    add bl, 7
ok:
    mov al, bl
    ret
hex_digit ENDP

;Main
start:
    ; tryb tekstowy
    mov ax, 3
    int 10h

    xor ax, ax
    mov ds, ax

    ; zapamiêtanie INT 9
    mov eax, ds:[9*4]
    mov cs:old_int9, eax

    cli
    mov word ptr ds:[9*4], OFFSET handle_int9
    mov word ptr ds:[9*4+2], SEG handle_int9
    sti

waitInt:
    cmp cs:exit_flag, 1
    jne waitInt

    ; przywrócenie INT 9
    cli
    mov eax, cs:old_int9
    mov ds:[9*4], eax
    sti

    mov ax, 4C00h
    int 21h

code ENDS

stack SEGMENT stack
db 128 dup (?)
stack ENDS

END start
