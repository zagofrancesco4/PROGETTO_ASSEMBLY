.section .data
# names of the files that the program opens, they finish with a zero
file_prodotti: .asciz "data/prodotti.txt"
file_stato:    .asciz "data/stato.txt"
file_storico:  .asciz "data/storico.txt"

# is for the messages to the user, output strings
txt_prodotto: .ascii "Prodotto "
len_prodotto = . - txt_prodotto
txt_prezzo:   .ascii " - prezzo: "
len_prezzo = . - txt_prezzo
txt_pezzi:    .ascii " euro - pezzi disponibili: "
len_pezzi = . - txt_pezzi
txt_soldi:    .ascii "Soldi nel distributore: "
len_soldi = . - txt_soldi
txt_euro:     .ascii " euro\n"
len_euro = . - txt_euro
txt_punto:    .ascii "."
txt_acapo:    .ascii "\n"
msg_stato:    .ascii "Uso: bin/distributore.x stato\n"
len_stato = . - msg_stato
msg_storia:   .ascii "Uso: bin/distributore.x storia <numero>\n"
len_storia = . - msg_storia
msg_init:     .ascii "Uso: bin/distributore.x init\n"
len_init = . - msg_init
txt_chiedi_prezzo: .ascii " - prezzo in decimi di euro: "
len_chiedi_prezzo = . - txt_chiedi_prezzo
txt_chiedi_pezzi:  .ascii " - numero di pezzi: "
len_chiedi_pezzi = . - txt_chiedi_pezzi
txt_m10: .ascii "Numero di monete da 0.10 euro: "
len_m10 = . - txt_m10
txt_m20: .ascii "Numero di monete da 0.20 euro: "
len_m20 = . - txt_m20
txt_m50: .ascii "Numero di monete da 0.50 euro: "
len_m50 = . - txt_m50
txt_m1e: .ascii "Numero di monete da 1.00 euro: "
len_m1e = . - txt_m1e
txt_fatto: .ascii "Inizializzazione completata.\n"
len_fatto = . - txt_fatto

# is for the messages of the acquisto and for the errors
txt_scelto:   .ascii "Hai scelto il prodotto "
len_scelto = . - txt_scelto
txt_costa:    .ascii " che costa "
len_costa = . - txt_costa
txt_credito:  .ascii "Credito inserito: "
len_credito = . - txt_credito
txt_conferma: .ascii "Confermi l'acquisto? (0 = annulla, 1-9 = conferma): "
len_conferma = . - txt_conferma
txt_erogo:    .ascii "Erogazione del prodotto "
len_erogo = . - txt_erogo
txt_resto:    .ascii "Resto: "
len_resto = . - txt_resto
msg_non_valido: .ascii "Errore: prodotto non valido.\n"
len_non_valido = . - msg_non_valido
msg_esaurito:   .ascii "Errore: prodotto esaurito.\n"
len_esaurito = . - msg_esaurito
msg_insuff:     .ascii "Errore: credito insufficiente.\n"
len_insuff = . - msg_insuff
msg_annullato:  .ascii "Operazione annullata.\n"
len_annullato = . - msg_annullato

quante: .long 0                   # number of story request from the user
letti:  .long 0                   # how many bytes i read from the file
scelto:  .long 0                  # the number of the product chosen by the user
credito: .long 0                  # money inserted by the user, in tenths
prezzo:  .long 0                  # price of the chosen product, in tenths
pezzi:   .long 0                  # how many pieces are left of that product
totale:  .long 0                  # money inside the machine, in tenths
lungh:   .long 0                  # length of the text i built in the buffer

.section .bss
buffer: .space 4096               # empty storage reserved for the program 
riga:   .space 256                # here i build one line before writing it
numero: .space 12                 # here numero_a_stringa writes the digits
ingresso: .space 32               # here i put what the user types

.section .text

stampa_numero:
    pushl %edi
    movl $numero, %edi            # i said where to write the number
    call numero_a_stringa         # convert the number in string
    movl $numero, %ecx            # address of numero in ecx
    movl %eax, %edx               # lenght of numero in edx
    call stampa_stringa           # print and return
    popl %edi
    ret

leggi_numero:                     # read a number typed by the user
    pushl %ebx                    # i save ebx because leggi_tastiera changes it
    pushl %edi
    movl $ingresso, %edi          # edi is where i write the characters
ln_ciclo:
    movl %edi, %ecx               # i read only one character at a time
    movl $1, %edx
    call leggi_tastiera
    cmpl $0, %eax                 # if there is nothing more i stop
    je   ln_fine
    cmpb $'\n', (%edi)            # if it is a carriage return the number is finished
    je   ln_fine
    incl %edi                     # i move to the next position
    jmp  ln_ciclo
ln_fine:
    movb $0, (%edi)               # i close the string with a final zero
    movl $ingresso, %esi          # esi points to what he typed
    call stringa_a_numero         # i convert it in a number in eax
    popl %edi                     # i put the registers back and return
    popl %ebx
    ret

stampa_euro:                      # print eax(tenths) like "X.Y"
    pushl %ebx                    # i save ebx to use it for divisor
    movl $0, %edx                 # reset edx
    movl $10, %ebx                # divisor is 10
    divl %ebx                     # divide eax for ebx and the rest is edx
    pushl %edx                    # i save edx at the top of the stack
    call stampa_numero            # i print the part on euro
    movl $txt_punto, %ecx         # print punto
    movl $1, %edx
    call stampa_stringa
    popl %eax                     # take tenths to put it in the top of the stack
    call stampa_numero            # print the number
    popl %ebx                     # put ebx in their place and return
    ret

salva_storico:                    # write the input of the use in storico
    movl punt_argomenti, %ebx     # ebx is where start argoment area 
    movl (%ebx), %ecx             # ecx= argc (how many arguments)
    decl %ecx                     # decrement ecx so the name of the program is not written
    addl $8, %ebx                 # add 8 byte so ebx is on argv[1]
    movl $riga, %edi              # edi is where i am building riga
ss_argomento:                     # one loop for every argument
    cmpl $0, %ecx
    je   ss_scrivi                # if there is no argument i jump to scrivi
    movl (%ebx), %esi             # esi= adress of the current argument
ss_copia:
    movb (%esi), %al              # he read one character(b is for single byte)
    cmpb $0, %al                  # if is the final zero the argument is finished and jump
    je   ss_finito
    movb %al, (%edi)              # i copy the character in riga
    incl %esi                     # i increment esi and edi and i restart the loop
    incl %edi
    jmp  ss_copia
ss_finito:
    addl $4, %ebx                 # i move to the next argument
    decl %ecx                     # counter of argument minus one
    cmpl $0, %ecx                 # if it was the last argument no comma
    je   ss_scrivi
    movb $',', (%edi)             # i divide whith the comma and i jump
    incl %edi
    jmp  ss_argomento
ss_scrivi:
    movb $'\n', (%edi)            # i finish the riga(line) whith a carriage return
    incl %edi 
    movl %edi, %edx               # i calculate the legngth of the line
    subl $riga, %edx
    pushl %edx                    # and i save it 
    movl $file_storico, %ebx      # i open the aggiunta(additional) file
    call apri_aggiunta
    movl %eax, %ebx               # and i put the fd in ebx
    movl $riga, %ecx              # adress and length of the line
    popl %edx
    call scrivi_file              # i write, close and return
    call chiudi_file
    ret

# He print to screen the status of the machine.How?, he read prodotti.txt 
# and for every product he print number, price and pieces (quantity).
# Then he read stato.txt and he print the money available .
.global azione_stato
azione_stato:
    call salva_storico            # i save the storico command
    movl punt_argomenti, %ebx     # i read argc
    movl (%ebx), %eax             
    cmpl $2, %eax                 # if eax is not 2 then jump to errore
    jne  sta_errore
    movl $file_prodotti, %ebx     # i open prodotti.txt
    call apri_lettura
    movl %eax, %ebx               # the fd goes to ebx
    movl $buffer, %ecx            # i read the file in the buffer
    movl $1024, %edx
    call leggi_file
    call chiudi_file              # i close the file, fd is still in ebx
    movl $buffer, %esi            # where i start to scan the text
    movl $1, %ebx                 # product counter=1
sta_ciclo:
    cmpl $4, %ebx                 # after the 4th product i jump to money
    jg   sta_soldi
    movl $txt_prodotto, %ecx      # i print "Prodotto"
    movl $len_prodotto, %edx
    call stampa_stringa
    call stringa_a_numero         # this call read the string after(1,2,3,ecc) after and he covert in number
    call stampa_numero            # then i print it
    incl %esi                     # i skip the comma
    movl $txt_prezzo, %ecx        # i print "-prezzo:"
    movl $len_prezzo, %edx
    call stampa_stringa
    call stringa_a_numero         # i read the price, print in euro, and i skip the comma
    call stampa_euro
    incl %esi
    movl $txt_pezzi, %ecx         # i print "euro-pezzi disponibili:"
    movl $len_pezzi, %edx
    call stampa_stringa
    call stringa_a_numero         # i read the quantity, i print it, and i carriage to return
    call stampa_numero
    incl %esi
    movl $txt_acapo, %ecx         # i go to a new line in the command line of the user
    movl $1, %edx
    call stampa_stringa
    incl %ebx                     # next product
    jmp  sta_ciclo
sta_soldi:
    movl $file_stato, %ebx        # i open stato.txt
    call apri_lettura
    movl %eax, %ebx
    movl $buffer, %ecx            # i read it and i close it
    movl $64, %edx
    call leggi_file
    call chiudi_file
    movl $txt_soldi, %ecx         # i print "Soldi nel distributore:"
    movl $len_soldi, %edx
    call stampa_stringa
    movl $buffer, %esi            # i read the total and print it in euro
    call stringa_a_numero
    call stampa_euro
    movl $txt_euro, %ecx          # i print "euro" and i return
    movl $len_euro, %edx
    call stampa_stringa
    ret
sta_errore:
    movl $msg_stato, %ecx         # i print the right usage ed quit with code 1
    movl $len_stato, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci

# He print a certain number of lines of storico.txt. How?, he open and read storico.txt
# he count all the lines, he skip the request one (total minus request) and print the rest.
.global azione_storia
azione_storia:
    call salva_storico            # i register the command 
    movl punt_argomenti, %ebx     # if there is not 3 argument jump to error(distributore.x storia+numer)
    movl (%ebx), %eax
    cmpl $3, %eax
    jne  sto_errore
    
    movl punt_argomenti, %ebx     # esi=argv[2] so the request number
    movl 12(%ebx), %esi
    call stringa_a_numero         # i convert it and i save it 
    movl %eax, quante
    movl $file_storico, %ebx      # i open storico
    call apri_lettura             
    movl %eax, %ebx
    movl $buffer, %ecx            # i read it all
    movl $4096, %edx
    call leggi_file
    movl %eax, letti              # i save ho many bytes i read
    call chiudi_file              # i close the file
    movl $buffer, %esi            # esi=start
    movl letti, %ecx              # ecx=bytes to examynate 
    movl $0, %edx                 # edx=line counter
sto_conta:
    cmpl $0, %ecx                 # finished the bytes i jump to calculate
    je   sto_calcola
    movb (%esi), %al              # if the character is a carriage i found a line
    cmpb $'\n', %al
    jne  sto_avanti
    incl %edx
sto_avanti:
    incl %esi                     # i increment the byte and i repeat
    decl %ecx
    jmp  sto_conta
sto_calcola:
    movl %edx, %eax               # total lines - request lines = lines to skip
    subl quante, %eax
    cmpl $0, %eax                 # if the result is <= 0 i dont skip
    jg   sto_prepara
    movl $0, %eax
sto_prepara:
    movl %eax, %ecx               # ecx=lines to skip
    movl $buffer, %esi
sto_salta:
    cmpl $0, %ecx                 # after skipping all i go to print
    je   sto_stampa
    movb (%esi), %al              # i go through each new line 
    incl %esi
    cmpb $'\n', %al
    jne  sto_salta
    decl %ecx                     # and i decrement the skipped lines
    jmp  sto_salta
sto_stampa:
    movl $buffer, %eax            # remain length = finish of the file - current position
    addl letti, %eax
    subl %esi, %eax
    movl %esi, %ecx               # i print from here to the end 
    movl %eax, %edx
    call stampa_stringa
    ret
sto_errore:
    movl $msg_storia, %ecx        # i print the right usage and i quit with code 1 
    movl $len_storia, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci

# Initialization of the machine, he ask everything about the products (price, quantity) and money in coins.
# And then he write from zero prodotti.txt and stato.txt.
.global azione_init
azione_init:
    call salva_storico            # i save the command in storico
    movl punt_argomenti, %ebx     # i read argc
    movl (%ebx), %eax
    cmpl $2, %eax                 # init wants no other parameter
    jne  ini_errore               # if eax is not 2 then jump to errore
    movl $buffer, %edi            # edi is the pen, here i build prodotti.txt
    movl $1, %ebx                 # product counter=1
ini_ciclo:
    cmpl $4, %ebx                 # after the 4th product i jump to monete
    jg   ini_monete
    movl $txt_prodotto, %ecx      # i print "Prodotto"
    movl $len_prodotto, %edx
    call stampa_stringa
    movl %ebx, %eax               # i print the number of the product
    call stampa_numero
    movl $txt_chiedi_prezzo, %ecx # i print "- prezzo in decimi di euro:"
    movl $len_chiedi_prezzo, %edx
    call stampa_stringa
    call leggi_numero             # i read the price typed by the user
    movl %eax, prezzo             # and i save it in prezzo
    movl $txt_prodotto, %ecx      # i print "Prodotto" again
    movl $len_prodotto, %edx
    call stampa_stringa
    movl %ebx, %eax               # with the number of the product
    call stampa_numero
    movl $txt_chiedi_pezzi, %ecx  # i print "- numero di pezzi:"
    movl $len_chiedi_pezzi, %edx
    call stampa_stringa
    call leggi_numero             # i read the quantity
    movl %eax, pezzi              # and i save it in pezzi
    movl %ebx, %eax               # now i build the line "id,prezzo,pezzi"
    call numero_a_stringa         # i write the id where the pen is
    addl %eax, %edi               # and i move the pen after the digits
    movb $',', (%edi)             # i write the comma
    incl %edi
    movl prezzo, %eax             # i write the price
    call numero_a_stringa
    addl %eax, %edi
    movb $',', (%edi)             # i write the second comma
    incl %edi
    movl pezzi, %eax              # i write the quantity
    call numero_a_stringa
    addl %eax, %edi
    movb $'\n', (%edi)            # i close the line with a carriage return
    incl %edi
    incl %ebx                     # next product
    jmp  ini_ciclo
ini_monete:
    movl %edi, %edx               # length of the text = pen position - start
    subl $buffer, %edx
    movl %edx, lungh              # i save the length for later
    movl $0, totale               # the money of the machine starts from zero
    movl $txt_m10, %ecx           # i ask how many coins of 0.10 euro
    movl $len_m10, %edx
    call stampa_stringa
    call leggi_numero             # i read the answer
    addl %eax, totale             # one coin of 0.10 is 1 tenth
    movl $txt_m20, %ecx           # i ask how many coins of 0.20 euro
    movl $len_m20, %edx
    call stampa_stringa
    call leggi_numero
    imull $2, %eax                # one coin of 0.20 is 2 tenths
    addl %eax, totale
    movl $txt_m50, %ecx           # i ask how many coins of 0.50 euro
    movl $len_m50, %edx
    call stampa_stringa
    call leggi_numero
    imull $5, %eax                # one coin of 0.50 is 5 tenths
    addl %eax, totale
    movl $txt_m1e, %ecx           # i ask how many coins of 1.00 euro
    movl $len_m1e, %edx
    call stampa_stringa
    call leggi_numero
    imull $10, %eax               # one coin of 1.00 is 10 tenths
    addl %eax, totale
    movl $file_prodotti, %ebx     # i create prodotti.txt from zero
    call crea_file
    movl %eax, %ebx               # the fd goes to ebx
    movl $buffer, %ecx            # i write the text i built
    movl lungh, %edx
    call scrivi_file
    call chiudi_file              # i close the file
    movl $riga, %edi              # now the pen writes on riga
    movl totale, %eax             # i write the total of the money
    call numero_a_stringa
    addl %eax, %edi
    movb $'\n', (%edi)            # i finish the line with a carriage return
    incl %edi
    movl %edi, %edx               # i calculate the length of the line
    subl $riga, %edx
    pushl %edx                    # and i save it
    movl $file_stato, %ebx        # i create stato.txt from zero
    call crea_file
    movl %eax, %ebx               # and i put the fd in ebx
    movl $riga, %ecx              # address and length of the line
    popl %edx
    call scrivi_file              # i write and i close
    call chiudi_file
    movl $txt_fatto, %ecx         # i print "Inizializzazione completata"
    movl $len_fatto, %edx
    call stampa_stringa
    ret
ini_errore:
    movl $msg_init, %ecx          # i print the right usage and quit with code 1
    movl $len_init, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci

# Is the effective purchasing action, he read the parameters in input from the user so he haveproduct and insert coin.
# Then he calculate the credit in tenths and he search on prodotti.txt price and availability.
# If evrything is okay he updates the two files and display the dispensed product and the change. 
.global azione_acquisto
azione_acquisto:
    call salva_storico            # i save the command in storico
    movl punt_argomenti, %ebx     # ebx is where start argoment area
    movl 8(%ebx), %esi            # esi=argv[1] so the chosen product
    call stringa_a_numero         # i convert it in a number
    movl %eax, scelto             # and i save it in scelto
    cmpl $1, %eax                 # if it is less than 1 it does not exist
    jl   acq_non_valido
    cmpl $4, %eax                 # if it is more than 4 it does not exist
    jg   acq_non_valido
    movl 12(%ebx), %esi           # esi=argv[2] so the coins of 0.10 euro
    call stringa_a_numero
    movl %eax, credito            # one coin of 0.10 is 1 tenth
    movl 16(%ebx), %esi           # esi=argv[3] so the coins of 0.20 euro
    call stringa_a_numero
    imull $2, %eax                # one coin of 0.20 is 2 tenths
    addl %eax, credito
    movl 20(%ebx), %esi           # esi=argv[4] so the coins of 0.50 euro
    call stringa_a_numero
    imull $5, %eax                # one coin of 0.50 is 5 tenths
    addl %eax, credito
    movl 24(%ebx), %esi           # esi=argv[5] so the coins of 1.00 euro
    call stringa_a_numero
    imull $10, %eax               # one coin of 1.00 is 10 tenths
    addl %eax, credito
    movl $file_prodotti, %ebx     # i open prodotti.txt
    call apri_lettura
    movl %eax, %ebx               # the fd goes to ebx
    movl $buffer, %ecx            # i read the file in the buffer
    movl $1024, %edx
    call leggi_file
    call chiudi_file              # i close the file
    movl $buffer, %esi            # where i start to scan the text
    movl $1, %ebx                 # line counter=1
acq_cerca:
    cmpl $4, %ebx                 # after the 4th line i jump to controlla
    jg   acq_controlla
    call stringa_a_numero         # i read the id and i skip the comma
    incl %esi
    call stringa_a_numero         # i read the price
    pushl %eax                    # i save it on the stack
    incl %esi                     # i skip the comma
    call stringa_a_numero         # i read the quantity
    incl %esi                     # i skip the carriage return
    popl %edx                     # edx=the price i saved
    cmpl %ebx, scelto             # is this line the product he chose?
    jne  acq_prossima             # if not i throw the line away
    movl %edx, prezzo             # if yes i save price and quantity
    movl %eax, pezzi
acq_prossima:
    incl %ebx                     # next line
    jmp  acq_cerca
acq_controlla:
    cmpl $0, pezzi                # if there are no pieces the product is over
    je   acq_esaurito
    movl credito, %eax            # if the credit is less than the price
    cmpl prezzo, %eax
    jl   acq_insufficiente        # the user cannot buy
    movl $txt_scelto, %ecx        # i print "Hai scelto il prodotto"
    movl $len_scelto, %edx
    call stampa_stringa
    movl scelto, %eax             # with the number of the product
    call stampa_numero
    movl $txt_costa, %ecx         # i print "che costa"
    movl $len_costa, %edx
    call stampa_stringa
    movl prezzo, %eax             # i print the price in euro
    call stampa_euro
    movl $txt_euro, %ecx          # i print "euro"
    movl $len_euro, %edx
    call stampa_stringa
    movl $txt_credito, %ecx       # i print "Credito inserito:"
    movl $len_credito, %edx
    call stampa_stringa
    movl credito, %eax            # i print the credit in euro
    call stampa_euro
    movl $txt_euro, %ecx          # i print "euro"
    movl $len_euro, %edx
    call stampa_stringa
    movl $txt_conferma, %ecx      # i ask the confirmation
    movl $len_conferma, %edx
    call stampa_stringa
    call leggi_numero             # i read the digit he types
    cmpl $0, %eax                 # if it is 0 i jump to annullato
    je   acq_annullato
    movl $buffer, %esi            # i read again the old text from the start
    movl $riga, %edi              # the pen builds the new text on riga
    movl $1, %ebx                 # line counter=1
acq_riscrivi:
    cmpl $4, %ebx                 # after the 4th line i jump to salva
    jg   acq_salva
    call stringa_a_numero         # i read the id and i skip the comma
    incl %esi
    call numero_a_stringa         # i write the same id in the new text
    addl %eax, %edi               # and i move the pen after the digits
    movb $',', (%edi)             # i write the comma
    incl %edi
    call stringa_a_numero         # i read the price and i skip the comma
    incl %esi
    call numero_a_stringa         # i write the same price
    addl %eax, %edi
    movb $',', (%edi)             # i write the second comma
    incl %edi
    call stringa_a_numero         # i read the quantity
    incl %esi                     # i skip the carriage return
    cmpl %ebx, scelto             # is this line the product he bought?
    jne  acq_scrivi_pezzi         # if not the quantity stays the same
    decl %eax                     # if yes one piece less
acq_scrivi_pezzi:
    call numero_a_stringa         # i write the quantity
    addl %eax, %edi
    movb $'\n', (%edi)            # i close the line with a carriage return
    incl %edi
    incl %ebx                     # next line
    jmp  acq_riscrivi
acq_salva:
    movl %edi, %edx               # length of the new text = pen - start
    subl $riga, %edx
    pushl %edx                    # and i save it
    movl $file_prodotti, %ebx     # i create prodotti.txt from zero
    call crea_file
    movl %eax, %ebx               # the fd goes to ebx
    movl $riga, %ecx              # address and length of the new text
    popl %edx
    call scrivi_file              # i write and i close
    call chiudi_file
    movl $file_stato, %ebx        # now the money, i open stato.txt
    call apri_lettura
    movl %eax, %ebx
    movl $buffer, %ecx            # i read it and i close it
    movl $64, %edx
    call leggi_file
    call chiudi_file
    movl $buffer, %esi            # i convert the total in a number
    call stringa_a_numero
    addl prezzo, %eax             # the machine keeps only the price
    movl $riga, %edi              # the pen writes the new total on riga
    call numero_a_stringa
    addl %eax, %edi
    movb $'\n', (%edi)            # i finish the line with a carriage return
    incl %edi
    movl %edi, %edx               # i calculate the length of the line
    subl $riga, %edx
    pushl %edx                    # and i save it
    movl $file_stato, %ebx        # i create stato.txt from zero
    call crea_file
    movl %eax, %ebx               # and i put the fd in ebx
    movl $riga, %ecx              # address and length of the line
    popl %edx
    call scrivi_file              # i write and i close
    call chiudi_file
    movl $txt_erogo, %ecx         # i print "Erogazione del prodotto"
    movl $len_erogo, %edx
    call stampa_stringa
    movl scelto, %eax             # with the number of the product
    call stampa_numero
    movl $txt_acapo, %ecx         # i go to a new line
    movl $1, %edx
    call stampa_stringa
    movl $txt_resto, %ecx         # i print "Resto:"
    movl $len_resto, %edx
    call stampa_stringa
    movl credito, %eax            # the change is credit - price
    subl prezzo, %eax
    call stampa_euro              # i print it in euro
    movl $txt_euro, %ecx          # i print "euro" and i return
    movl $len_euro, %edx
    call stampa_stringa
    ret
acq_non_valido:
    movl $msg_non_valido, %ecx    # i print the error and quit with code 1
    movl $len_non_valido, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci
acq_esaurito:
    movl $msg_esaurito, %ecx      # i print the error and quit with code 1
    movl $len_esaurito, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci
acq_insufficiente:
    movl $msg_insuff, %ecx        # i print the error and quit with code 1
    movl $len_insuff, %edx
    call stampa_stringa
    movl $1, %ebx
    call esci
acq_annullato:
    movl $msg_annullato, %ecx     # i print "Operazione annullata" and return
    movl $len_annullato, %edx
    call stampa_stringa
    ret                           # no file was changed
