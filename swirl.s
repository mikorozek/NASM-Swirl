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

swirl:
        movsd       xmm0
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

        fabs        xmm6
        fabs        xmm7

        divsd       xmm6, xmm7

        sub         rsp, 8


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

