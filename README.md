# Distributore automatico in Assembly x86

Progetto d'esame di Calcolatori Elettronici, del corso di Laboratorio di Reti Logiche e Calcolatori Elettronici (Università di Verona, A.A. 2025/2026).

È il software di controllo di un distributore automatico, scritto in **Assembly x86 a 32 bit con sintassi AT&T**. Non usa la libreria C: tutto passa dalle chiamate di sistema Linux (`int $0x80`), quindi l'eseguibile non dipende da nient'altro.

> Il progetto era pensato per un gruppo di due persone. La mia compagna ha cambiato università durante il lavoro, quindi l'ho portato a termine da solo. Questo README riprende i contenuti della relazione consegnata. Il progetto l'ho poi presentato all'esame orale.

## Cosa fa

Il programma si usa da riga di comando e ha quattro modalità:

| Comando | Cosa fa |
|---|---|
| `bin/distributore.x init` | procedura guidata: chiede prezzo e numero di pezzi per ognuno dei 4 prodotti, poi quante monete ci sono per ogni taglio, e riscrive `prodotti.txt` e `stato.txt` |
| `bin/distributore.x stato` | mostra per ogni prodotto prezzo e pezzi disponibili, e i soldi presenti nella cassa |
| `bin/distributore.x storia <numero>` | mostra le ultime `<numero>` righe di `storico.txt` (tutte, se sono di meno) |
| `bin/distributore.x <prodotto> <10c> <20c> <50c> <1€>` | acquisto: codice del prodotto e numero di monete inserite per ogni taglio |

Durante un acquisto il programma controlla, nell'ordine:

1. che il numero di parametri sia giusto
2. che il prodotto sia compreso tra 1 e 4
3. che il prodotto sia disponibile
4. che il credito basti

Se un controllo fallisce, stampa un messaggio di errore preciso ed esce con codice 1. Se lanciato senza parametri o con parametri sbagliati, stampa anche come usarlo.

Se è tutto a posto, chiede conferma: **0** annulla senza modificare nessun file, una cifra da **1 a 9** conferma. Dopo la conferma aggiorna i file, stampa il messaggio di erogazione e l'eventuale resto.

Tutti gli importi sono interi in **decimi di euro**: 15 vuol dire 1,50 €. Così non serve mai lavorare con la virgola.

## Esempio

```bash
bin/distributore.x init       # imposto prezzi e quantità
bin/distributore.x stato      # controllo cosa c'è nel distributore
bin/distributore.x 2 0 1 1 1  # compro il prodotto 2 con 0,20 + 0,50 + 1 € = 1,70 €
bin/distributore.x storia 3   # rivedo gli ultimi 3 comandi
```

## Come è organizzato il codice

Il codice è diviso in quattro moduli dentro `src/`, ognuno con un compito preciso:

| File | Compito |
|---|---|
| `main.s` | punto di ingresso (`_start`): legge `argc` e `argv`, riconosce il comando e chiama l'azione giusta |
| `logic.s` | le azioni vere e proprie: `init`, `stato`, `storia`, acquisto, salvataggio dello storico |
| `funz.s` | stampa a video, uscita dal programma, confronto tra stringhe, apertura/lettura/scrittura/chiusura dei file, lettura da tastiera |
| `trad.s` | conversioni tra testo e numeri: `stringa_a_numero`, `numero_a_stringa`, `stampa_euro`, `leggi_numero` |

`logic.s` si appoggia a `funz.s` e a `trad.s` per l'input/output e per le conversioni.

### Dati in memoria

- **`.data`**: tutto quello che è già pronto. Ci sono i nomi dei comandi (`init`, `stato`, `storia`) come stringhe terminate da zero e i messaggi a video, con la lunghezza calcolata in fase di assemblaggio (posizione attuale − inizio).
- **`.bss`**: spazi di lavoro vuoti, che si riempiono mentre il programma gira:
  - `buffer` (4096 byte): contenuto dei file
  - `riga` (256 byte): una riga da scrivere
  - `ingresso` (32 byte): quello che digita l'utente
  - `numero` (12 byte): le cifre di un numero
  - variabili intere `prezzo`, `pezzi`, `credito`, `totale`, `scelto`, `letti`, e `punt_argomenti` (puntatore agli argomenti della riga di comando)

### Convenzione sui registri

| Registro | Uso |
|---|---|
| `esi` | puntatore di lettura |
| `edi` | puntatore di scrittura |
| `ebx` | contatore dei cicli |
| `eax` | valore di ritorno |

## File di dati

I file stanno in `data/` e vengono sempre gestiti con lo stesso schema: apri → leggi o scrivi → chiudi.

| File | Contenuto | Come viene usato |
|---|---|---|
| `prodotti.txt` | 4 righe `id,prezzo,quantità` | letto in sola lettura, riscritto da zero dopo un acquisto o un `init` |
| `stato.txt` | una riga con il totale della cassa in decimi di euro | riscritto da zero dopo un acquisto o un `init` |
| `storico.txt` | un comando per riga, parametri separati da virgola | aperto sempre in aggiunta, non viene mai cancellato |

In lettura il programma carica tutto il file nel buffer e lo scompone campo per campo, saltando le virgole. Per modificarlo ricostruisce il testo completo in memoria e riscrive il file da zero: è più semplice e più sicuro che modificarlo sul posto.

## Alcune scelte

- **Lettura da tastiera un carattere alla volta** fino all'a capo, così il programma funziona anche quando l'input non arriva da un terminale (per esempio da una pipe).
- **Resto come importo totale**: per i gruppi da due la consegna non chiedeva il dettaglio delle monete per taglio.
- **La cassa aumenta solo del prezzo**: la macchina incassa il credito e restituisce il resto, quindi quello che le rimane è credito − resto = prezzo. Il nuovo totale è quindi totale precedente + prezzo.

## Come compilare ed eseguire

Serve Linux con `make` e binutils (`as`, `ld`). Su Ubuntu:

```bash
sudo apt install make binutils
```

Poi, dalla cartella del progetto:

```bash
mkdir -p obj bin   # git non salva le cartelle vuote
make
bin/distributore.x stato
```

Il Makefile assembla ogni file di `src/` con `as --32` e collega i quattro file oggetto con `ld -m elf_i386`:

```
src/*.s  --as --32-->  obj/*.o  --ld -m elf_i386-->  bin/distributore.x
```

Per cancellare i file generati:

```bash
make clean
```

## Struttura della cartella

```
src/        main.s, logic.s, funz.s, trad.s
obj/        file oggetto (generati da make)
bin/        eseguibile distributore.x (generato da make)
data/       prodotti.txt, stato.txt, storico.txt
Makefile
```