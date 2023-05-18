section .data
dtwo                dq 2.0
donehalf            dq 1.5
dhalf               dq 0.5
zero                dq 0.0
usmask              dq 0x7FFFFFFFFFFFFFFF
pi                  dq 3.14159265358979323846


section .text
global  swirl_prologue

; rdi - pointer to the origin pixel array
; rsi - poitner to the copy pixel array
; rdx - width
; rcx - height
; xmm0 - factor


swirl_prologue:
        push        rbp
        mov         rbp, rsp
        push        xmm6
        push        xmm7
        push        xmm8
        push        xmm9
        push        xmm10
        push        xmm11
        push        xmm12
        push        xmm13
        push        xmm14
        push        xmm15

; for this algorithm these registers are going to contain following values:
; xmm1 - operation register for double precision float values, something like RAX
; xmm2 - width/2 in double
; xmm3 - height/2 in double
; xmm4 - distance from current row to center (height/2)
; xmm5 - distance from current pixel in row to center (width/2)
; xmm6 - original angle value (result of arcus tangens)



swirl:
        cvtsi2sd    rdx, xmm1
        divsd       xmm1, qword [dtwo]
        movsd       xmm2, xmm1              ; now xmm2 contains width/2

        cvtsi2sd    rcx, xmm1
        divsd       xmm1, qword [dtwo]
        movsd       xmm3, xmm1              ; now xmm3 contains height/2

        mov         r8, 0                   ; r8 is iterator, if r8 equals height - > the loop ends

height_loop:
        cmp         r8, rcx
        je          finish

        cvtsi2sd    r8, xmm4
        subsd       xmm4, xmm3              ; xmm4 is now distance from pixel's y to center (height/2)

        mov         r9, 0                   ; r9 is iterator, if r9 equals width - > the loop ends


width_loop:
        cmp         r9, rdx
        je          height_loop

        cvtsi2sd    r9, xmm5
        subsd       xmm5, xmm2              ; xmm5 is now distance from pixel's x to center (width/2)

        movsd       xmm1, qword [zero]
        comisd      xmm5, 0                 ; if distance from column to center is 0, we have to make different label for that case - we stay in this label, better code
        jnz         not_zero_case           ; if not zero then jump to regular case

        movsd       xmm6, qword [pi]        ; move pi value to xmm6 cause we will make angle pi * 0.5 or pi * 1.5

        comisd      xmm4, xmm1              ; this is zero case so zero case distance from column to center lesser than 0 so its down side
        jl          zerocyltz

        mulsd       xmm6, qword [donehalf]  ; we create pi/2 and pass it to original angle

        jmp         width_loop_continue     ; continue the loop

zerocyltz:

        mulsd       xmm6, qword [dhalf]     ; we create 3pi/2 and pass it to original angle

        jmp         width_loop_continue     ; continue the loop

not_zero_case:
        movsd       xmm6, xmm4              ; move xmm4, xmm5 to xmm6, xmm7 cause we have to make absolute values so we can pass it to arctan
        movsd       xmm7, xmm5

        andpd       xmm6, qword [usmask]    ; we take absolute value of the xmm4 and xmm5
        andpd       xmm7, qword [usmask]

        push        xmm6                    ; we push absolute height/2 and absolute width/2 so we can copy theirs values to register stack
        push        xmm7

        fld         [rsp + 8]               ; we load height/2 and width/2 to the register stack so we can perform fpatan
        fld         [rsp + 16]

        fpatan                              ; function that is responsible for counting the arcus tangens

        fstp        qword [rsp]             ; we push the value from ST(0) that is the result of FPATAN

        movsd       xmm6, [rsp]             ; now we have the original angle value in radians in xmm6

        pop         xmm7
        pop         xmm6                    ; we delete the xmm7 and xmm6 values from the stack

        comisd      xmm5, xmm1              ; if distance from pixel's x to center is greater than 0 it will be 1st and 4th quarters of UV space

        jg          relxgtz

        comisd      xmm4, xmm1              ; if distance from pixel's y to center is lesser than 0 it will be the 3rd quarter of UV space

        jl          relyltz

        movsd       xmm1, xmm6              ; the case that is left is the 2nd quarter of UV space
        movsd       xmm6, qword [pi]        ; distance from pixel's x to center is lesser than zero and from pixel's y to center is bigger than zero
        subsd       xmm6, xmm1              ; we make pi - angle operation

        jmp         width_loop_continue

relxgtz:
        comisd      xmm4, xmm1              ; if the pixel is in the 1st quarter of UV space we leave the angle
        jge         width_loop_continue
        jz          width_loop_continue

        movsd       xmm1, xmm6              ; in this case the pixel is in the 4th quarter of UV space so we make 2 pi - angle
        movsd       xmm6, qword [pi]
        mulsd       xmm6, qword [dtwo]
        subsd       xmm6, xmm1

        jmp         width_loop_continue

relyltz:
        addsd       xmm6, qword [pi]

width_loop_continue:




finish:

swirl_epilogue:
        pop         r15
        pop         r14
        pop         r13
        pop         r12
        pop         rbx
        mov         rsp, rbp
        pop         rbp
        ret

