.section .text
# He convert from the string to a digit value, lets take for example 15.
# He start reading 1 and he do 0*10+1=1.
# Then he read 5 and he do 1*10+5=15, the next character is 0 and he finish.
.global stringa_a_numero
stringa_a_numero:          # input is esi that points to the string 
    pushl %ebx             # i "save" ebx 
    movl $0, %eax          # output=0
    movl $0, %ebx          # ebx is 0 
san_ciclo:                 # start of the loop
    movb (%esi), %bl       # bl = first character of esi
    cmpb $'0', %bl         # if it's < '0' it's not a number -> go to san_fine
    jl   san_fine
    cmpb $'9', %bl         # if it's > '9' it's not a number -> go to san_fine
    jg   san_fine
    subb $'0', %bl         # bl = converted digit value from 0 to 9
    imull $10, %eax        # output = output * 10
    addl %ebx, %eax        # output = output + digit value stored in ebx (%bl)
    incl %esi              # increase esi and analyse the next character
    jmp  san_ciclo
san_fine:
    popl %ebx
    ret

# He convert from a digit value to a string, lets take for exmaple 15.
# He devides 15 by 10 -> quotient is 1 , remainder is 5 and he puts it in the stack.
# He devides 1 by 10 -> quotient is 0 , remainder is 1 and he do the same.
# The results are on the stack in reverse order , so he take it and write "15".
.global numero_a_stringa
numero_a_stringa:          # input is eax=number and edi=buffer
    pushl %ebx             # i save the registers used by the function
    pushl %ecx
    pushl %edx
    pushl %edi
    movl $10, %ebx         # the divisor that i am gonna use after
    movl $0, %ecx          # i put the digit counter = 0
    cmpl $0, %eax          # if eax is not 0 i jump to nas_estrai
    jne  nas_estrai
    pushl $'0'             # i put directly 0, i increment digit counter ecx , and i jump to nas_scrivi
    incl %ecx
    jmp  nas_scrivi
nas_estrai:
    movl $0, %edx          # set to zero edx
    divl %ebx              # eax / 10 -> quotient in eax, remainder in edx
    addb $'0', %dl         # digit value -> ASCII character
    pushl %edx             # store the remainder on the stack
    incl %ecx              # increment digit counter ecx
    cmpl $0, %eax          # if eax is different from 0 i jump to nas_estari, restart the loop
    jne  nas_estrai
nas_scrivi:
    movl %ecx, %eax        # output = digit counter
nas_ciclo_scrivi:
    cmpl $0, %ecx          # if ecx=0 i jump to nas_fine, no value remained
    je   nas_fine
    popl %edx              # retrieve the remainder from the stack
    movb %dl, (%edi)       # store the digit to the buffer
    incl %edi              # increment edi to write the next digit to the next position
    decl %ecx              # decrement ecx to understand how many digit i have to convert
    jmp  nas_ciclo_scrivi
nas_fine:
    popl %edi              # i take the registers to their place 
    popl %edx
    popl %ecx
    popl %ebx
    ret                    # i return to continue logic.s

    