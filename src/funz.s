.section .text
.global esci                # make the name esci visible for other files
esci:
    movl $1, %eax           # syscall number for the exit server
    int  $0x80              # ask the kernel to execute the action

.global stampa_stringa
stampa_stringa:             # we already have the address and the length in ecx and edx
    pushl %eax              # i need to use eax and ebx but i dont want to overwrite it so
    pushl %ebx              # i put the two value on the top of the ecp register, top of the stack
    movl $4, %eax           # now i put 4 on eax and 1 on ebx to display on screen 
    movl $1, %ebx
    int  $0x80
    popl %ebx               # and then i pop the top value of esi in eax and ebx to return to the start
    popl %eax
    ret                     # return to main.s

# It check every character if is the same for the two words , if they are not he go tu cs_diverse, if they are he check all 
# And he stop when the last character is the 0.
.global confronta_stringhe
confronta_stringhe:         # inputs are esi= 8(%esp) and edi that is the word to compare
    pushl %esi              # we "save" the two inputs to not overwrite 
    pushl %edi
cs_ciclo:                   # start of the loop
    movb (%esi), %al        # we take the charcter of esi and we put it to %al 
    cmpb (%edi), %al        # we compare %al with edi 
    jne  cs_diverse         # if they are differ jump to cs_diverse
    cmpb $0, %al            # they are the same so if the last character to check is the 0 of the end of the word
    je   cs_uguali          # jump to cs_uguali
    incl %esi               # it was not the end so increase of 1 to the next character to check
    incl %edi
    jmp  cs_ciclo           # repeat from the start
cs_uguali:
    movl $1, %eax           # put 1 in eax
    jmp  cs_fine            # jump to cs_fine
cs_diverse:
    movl $0, %eax           # put 0 in eax
cs_fine:
    popl %edi               # take back edi and esi to their place
    popl %esi
    ret                     # return to main with 1 or 0 in eax

.global apri_lettura
apri_lettura:
    movl $5, %eax           # open a file with eax=5 that is open
    movl $0, %ecx           # ecx=0 only reading
    movl $0, %edx           # edx=0 file already exist
    int  $0x80
    ret

.global crea_file
crea_file:
    movl $5, %eax           # create a file, input ebx=filename, output eax=fd (file descriptor)
    movl $577, %ecx         # ecx=1+64+512, write, create if missin, reset contents
    movl $0644, %edx        # permissions of the file created
    int  $0x80
    ret

.global apri_aggiunta
apri_aggiunta:
    movl $5, %eax           # open
    movl $1089, %ecx        # ecx=1+64+1024, write, create if missing, append
    movl $0644, %edx        # permissions
    int  $0x80
    ret

.global leggi_file
leggi_file:
    movl $3, %eax           # eax=3 is read
    int  $0x80
    ret

.global scrivi_file
scrivi_file:
    movl $4, %eax           # eax=4 is write 
    int  $0x80
    ret

.global chiudi_file
chiudi_file:
    movl $6, %eax           # eax=6 is close
    int  $0x80
    ret

.global leggi_tastiera
leggi_tastiera:
    movl $3, %eax           # eax=3 is read
    movl $0, %ebx           # ebx=0 is fd=0,that is keyboard
    int  $0x80
    ret
    
