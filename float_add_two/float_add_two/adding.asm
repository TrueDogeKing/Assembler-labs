.686
.model flat


.code

; ============================================================
; _add_two: Main function - adds two to double 
; input: double in [ebp + 8]
; output: double in st(0)
; ============================================================
_add_two proc
    push ebp
    mov ebp, esp
    sub esp, 8
    pusha

    mov eax, [ebp + 8]  ; lower part of double
    mov edx, [ebp + 12] ; higher part of double
    mov ecx,edx
    shr ecx,20
    and ecx,7FFh    ; ecx - wyk³adnik +1023
    and edx,000FFFFFh ; edx - mantysa
    
    cmp ecx,1024d
    jb small_number
    sub ecx,1023d
    mov ebx,00200000h
    cmp cl,21
    ja bigg_number
    shr ebx,cl
    add edx,ebx
    jmp check_mantis_overflow

bigg_number:
	sub ecx,22
    mov ebx,80000000h
    shr ebx,cl
    add eax,ebx
    adc edx,0
    add ecx,22

check_mantis_overflow:
    btr edx,20
    jnc finnish
    inc ecx
    shr edx,1
    jmp finnish

small_number:
    bts edx,20
    shr edx,1
    rcr eax,1

    sub ecx,1023d
    neg ecx
    rotation:
        shr edx,1
        rcr eax,1
    loop rotation
    mov ecx,1
    shl ecx,20
    add edx,ecx


finnish:
    mov ebx,[ebp+12]
    and ebx,80000000h
    or edx,ebx          ; set the sign bit

    add ecx,1023d       ; restore exponent
    shl ecx,20
    add edx,ecx
    mov [ebp-4],edx
    mov [ebp-8],eax
    lea esi,[ebp-8]
    fld qword ptr [esi]

    popa
    add esp, 8
    mov esp, ebp
    pop ebp
    ret
_add_two endp
end