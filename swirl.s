section .data
half    dq 2.0

section .text
global  swirl_prologue
swirl_prologue:
        push        rbp
        mov         rbp, rsp
        push        rbx
        push        r12
        push        r13
        push        r14
        push        r15

swirl:
        cvtsi2sd    rsi, xmm1
        divsd       xmm1, qword [half]
        movsd       xmm2, xmm1

        cvtsi2sd


swirl_epilogue:
        pop         r15
        pop         r14
        pop         r13
        pop         r12
        pop         rbx
        mov         rsp, rbp
        pop         rbp
        ret