section .data
dtwo                dq 2.0
donehalf            dq 1.5
done                dq 1.0
dhalf               dq 0.5
zero                dq 0.0
usmask              dq 0x7FFFFFFFFFFFFFFF
pi                  dq 3.14159265358979323846


section .text
global swirl

; rdi - pointer to the origin pixel array
; rsi - poitner to the copy pixel array
; rdx - width
; rcx - height
; xmm0 - factor


swirl:
        push        rbp
        mov         rbp, rsp
        push        r12
        push        r13
        sub         rsp, 16
        movaps      [rsp], xmm6
        sub         rsp, 16
        movaps      [rsp], xmm7
        sub         rsp, 16
        movaps      [rsp], xmm8

; for this algorithm these registers are going to contain following values:
; xmm1 - operation register for double precision float values, something like RAX
; xmm2 - width/2 in double
; xmm3 - height/2 in double
; xmm4 - relY 
; xmm5 - relX
; xmm6 - original angle value (result of arcus tangens)


swirl_continue:
        cvtsi2sd    xmm1, rdx
        divsd       xmm1, qword [rel dtwo]
        movsd       xmm2, xmm1              ; now xmm2 contains width/2

        cvtsi2sd    xmm1, rcx
        divsd       xmm1, qword [rel dtwo]
        movsd       xmm3, xmm1              ; now xmm3 contains centerY

        mov         r8, 0                   ; r8 is iterator, if r8 equals height - > the loop ends

height_loop:
        cmp         r8, rcx
        je          swirl_epilogue

        cvtsi2sd    xmm8, r8
        movsd       xmm4, xmm3
        subsd       xmm4, xmm8              ; xmm4 is now rely (centerY)

        mov         r9, 0                   ; r9 is iterator, if r9 equals width - > the loop ends


width_loop:
        cmp         r9, rdx
        je          height_loop_finish

        cvtsi2sd    xmm5, r9
        subsd       xmm5, xmm2              ; xmm5 is now relx (width/2)

        movsd       xmm1, qword [rel zero]      ; if distance from column to center is 0, we have to make different label for that case - we stay in this label, better code
        jnz         not_zero_case           ; if not zero then jump to regular case

        movsd       xmm6, qword [rel pi]        ; move pi value to xmm6 cause we will make angle pi * 0.5 or pi * 1.5

        comisd      xmm4, xmm1              ; this is zero case so zero case distance from column to center lesser than 0 so its down side
        jb          zerocyltz

        mulsd       xmm6, qword [rel dhalf]  ; we create pi/2 and pass it to original angle

        jmp         width_loop_continue     ; continue the loop

zerocyltz:

        mulsd       xmm6, qword [rel donehalf]     ; we create 3pi/2 and pass it to original angle

        jmp         width_loop_continue     ; continue the loop

not_zero_case:
        movsd       xmm6, xmm4              ; move xmm5, xmm4 to xmm6, xmm7 cause we have to make absolute values so we can pass it to arctan
        movsd       xmm7, xmm5

        movsd       xmm8, qword [rel usmask]

        subsd       xmm8, qword [rel done]

        andpd       xmm6, xmm8    ; we take absolute value of the xmm4 and xmm5
        andpd       xmm7, xmm8

        sub         rsp, 32

        movsd       qword [rsp], xmm6
        movsd       qword [rsp + 16], xmm7

        fld         qword [rsp]               ; we load centerY and width/2 to the register stack so we can perform fpatan
        fld         qword [rsp + 16]

        fpatan                              ; function that is responsible for counting the arcus tangens

        fstp        qword [rsp]             ; we push the value from ST(0) that is the result of FPATAN

        movsd       xmm6, qword [rsp]       ; now we have the original angle value in radians in xmm6

        add         rsp, 32

        comisd      xmm5, xmm1              ; if relx is greater than 0 it will be 1st and 4th quarters of UV space

        ja          relxgtz

        comisd      xmm4, xmm1              ; if rely is lesser than 0 it will be the 3rd quarter of UV space

        jb          relyltz

        movsd       xmm1, xmm6              ; the case that is left is the 2nd quarter of UV space
        movsd       xmm6, qword [rel pi]        ; relx is lesser than zero and from pixel's y to center is bigger than zero
        subsd       xmm6, xmm1              ; we make pi - angle operation

        jmp         width_loop_continue

relxgtz:
        comisd      xmm4, xmm1              ; if the pixel is in the 1st quarter of UV space we leave the angle
        jae         width_loop_continue
        jz          width_loop_continue

        movsd       xmm1, xmm6              ; in this case the pixel is in the 4th quarter of UV space so we make 2 pi - angle
        movsd       xmm6, qword [rel pi]
        mulsd       xmm6, qword [rel dtwo]
        subsd       xmm6, xmm1

        jmp         width_loop_continue

relyltz:
        addsd       xmm6, qword [rel pi]

width_loop_continue:
        mulsd       xmm4, xmm4              ; we perform sqrt[(centerY)^2 + (width/2)^2)
        mulsd       xmm5, xmm5
        addsd       xmm4, xmm5
        sqrtsd      xmm4, xmm4

        movsd       xmm5, qword [rel dtwo]
        mulsd       xmm5, xmm5
        divsd       xmm5, qword [rel pi]
        movsd       xmm8, xmm4
        mulsd       xmm8, xmm0
        addsd       xmm8, xmm5
        movsd       xmm7, qword [rel done]
        divsd       xmm7, xmm8
        addsd       xmm6, xmm7

        sub         rsp, 16                  ; calculate the cos of the new angle
        movsd       [rsp], xmm6
        fld         qword [rsp]
        fcos
        fstp        qword [rsp]
        movsd       xmm7, qword [rsp]
        add         rsp, 16

        mulsd       xmm7, xmm4
        addsd       xmm7, qword [rel dhalf]
        roundsd     xmm7, xmm7, 1           ; we store the integer value of src x in the r10
        cvttsd2si   r10, xmm7

        sub         rsp, 16                 ; calculate the sin of the new angle
        movsd       [rsp], xmm6
        fld         qword [rsp]
        fsin
        fstp        qword [rsp]
        movsd       xmm7, qword [rsp]
        add         rsp, 16

        mulsd       xmm7, xmm4
        addsd       xmm7, qword [rel dhalf]
        roundsd     xmm7, xmm7, 1
        cvttsd2si   r11, xmm7

        cvttsd2si   r12, xmm2
        cvttsd2si   r13, xmm3

        add         r10, r12
        add         r11, r13
        mov         r12, r11
        mov         r11, rcx
        sub         r11, r12

        cmp         r10, 0
        jl          srcxltz

        cmp         r10, rdx
        jge         srcxgetw

        jmp         srcycond

srcxltz:
        mov         r10, 0
        jmp         srcycond

srcxgetw:
        mov         r10, rdx
        sub         r10, 1

srcycond:
        cmp         r11, 0
        jl          srcyltz

        cmp         r11, rcx
        jge         srcygeth

        jmp         width_loop_finish

srcyltz:
        mov         r11, 0
        jmp         width_loop_finish

srcygeth:
        mov         r11, rcx
        sub         r11, 1

width_loop_finish:
        mov         rax, r11
        imul        rax, rdx
        add         rax, r10
        imul        rax, 3

        mov         r10, rax

        mov         ax, word [rdi + r10]
        mov         r11b, byte [rdi + r10 + 2]

        mov         word [rsi], ax
        mov         byte [rsi + 2], r11b
        add         rsi, 3

        add         r9, 1
        jmp         width_loop

height_loop_finish:
        add         r8, 1
        jmp         height_loop

swirl_epilogue:
        movaps      xmm8, [rsp]
        add         rsp, 16
        movaps      xmm7, [rsp]
        add         rsp, 16
        movaps      xmm6, [rsp]
        pop         r13
        pop         r12
        pop         rbx
        mov         rsp, rbp
        pop         rbp
        ret
