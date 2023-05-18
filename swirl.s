section .data
half    dq 2.0
usmask  dq 0x7FFFFFFFFFFFFFFF
pi      dq 3.14159265358979323846


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
        push        rbx
        push        r12
        push        r13
        push        r14
        push        r15
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
        divsd       xmm1, qword [half]
        movsd       xmm2, xmm1              ; now xmm2 contains width/2

        cvtsi2sd    rcx, xmm1
        divsd       xmm1, qword [half]
        movsd       xmm3, xmm1              ; now xmm3 contains height/2

        mov         r8, 0                   ; r8 is iterator, if r8 equals height - > the loop ends

height_loop:
        cmp         r8, rcx
        je          finish

        cvtsi2sd    r8, xmm4
        subsd       xmm4, xmm3              ; xmm4 is now distance from row to center (height/2)

        mov         r9, 0                   ; r9 is iterator, if r9 equals width - > the loop ends


width_loop:
        cmp         r9, rdx
        je          height_loop

        cvtsi2sd    r9, xmm5
        subsd       xmm5, xmm2              ; xmm5 is now distance from column to center (width/2)

        cmp         xmm5, 0                 ; if distance from column to center is 0, we have to make different label for that case
        jz          zero_dist

        movsd       xmm6, xmm4
        movsd       xmm7, xmm5

        andpd       xmm6, qword [usmask]    ; we take absolute value of the xmm4 and xmm5
        andpd       xmm7, qword [usmask]

        push        xmm6                    ; we push height/2 and width/2 so we can copy theirs values to register stack
        push        xmm7

        fld         [rsp + 8]               ; we load height/2 and width/2 to the register stack so we can perform fpatan
        fld         [rsp + 16]

        fpatan                              ; function that is respinsible for counting the arcus tangens

        fstp        qword [rsp]                   ; we push the value from ST(0) that is the result of FPATAN

        movsd       xmm6, [rsp]             ; now we have the original angle value in the xmm6

        pop         xmm7
        pop         xmm6                    ; we delete the xmm7 and xmm6 values from the stack



zero_dist:


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

