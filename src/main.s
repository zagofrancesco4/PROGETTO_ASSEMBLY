.section .data

# we put the words with a final zero(asci with the z) in the memory using tags
cmd_init:   .asciz "init"
cmd_stato:  .asciz "stato"
cmd_storia: .asciz "storia"

# when someone write something wrong this message that is write here will appear on the console
msg_uso:
    .ascii "Uso:\n"
    .ascii "  bin/distributore.x init\n"
    .ascii "  bin/distributore.x storia <numero>\n"
    .ascii "  bin/distributore.x stato\n"
    .ascii "  bin/distributore.x <prodotto> <10c> <20c> <50c> <1e>\n"
len_uso = . - msg_uso          # length of the message = the position where you are - the top (msg_uso)

.global punt_argomenti
punt_argomenti: .long 0

.section .text
.global _start

_start:
    movl %esp, punt_argomenti  # i save the adress of the arguments before the stack moves
    movl (%esp), %eax          # I copy argc("number of word") in eax so eax=2
    cmpl $2, %eax              # If eax is 2 then there is a word after distributore.x so he jump the next command and we can start
    jl   uso_errato            # If eax<2 then we jump to the error message 

    movl 8(%esp), %esi         
    # We have another word after the first, so we copy on esi the address of second word = 8(%esp)
    # because 4 byte after the argc we have argv[0] that is the first word and then after 4 byte 
    # So 8 after the top of the register that is esp ( 8(%esp) ) we have the second word that choose wich action we're gonna do.

    movl $cmd_init, %edi       # we put the address of the word init (declared in the 5 line of code) in edi
    call confronta_stringhe    # function that put 1 in eax if esi and edi are the same, then 0
    cmpl $1, %eax              # if eax is 1
    je   esegui_init           # jump to esegui_init 

    movl $cmd_stato, %edi      # we do the same as init so we can check if the word is stato
    call confronta_stringhe
    cmpl $1, %eax
    je   esegui_stato

    movl $cmd_storia, %edi     # we do the same as init for storia
    call confronta_stringhe
    cmpl $1, %eax
    je   esegui_storia         


    movl (%esp), %eax          # we put the number of word in eax 
    cmpl $6, %eax              # if eax is 6(so distibutore.x and 5 numers)
    je   esegui_acquisto       # we jump to the function

    jmp  uso_errato            # if no one of this cases where right we jump to error

esegui_init:                   
    call azione_init
    jmp  esci_ok
esegui_stato: 
    call azione_stato
    jmp  esci_ok
esegui_storia:
    call azione_storia
    jmp  esci_ok
esegui_acquisto:
    call azione_acquisto
    jmp  esci_ok

esci_ok:
    movl $0, %ebx              # if is evrything all right ebx is 0
    call esci                  # the function that end the program 

uso_errato:
    movl $msg_uso, %ecx        # we put the addres of the message on ecx
    movl $len_uso, %edx        # we put the length of the message on edx
    call stampa_stringa
    movl $1, %ebx              # there is something wrong so ebx is 1
    call esci
    