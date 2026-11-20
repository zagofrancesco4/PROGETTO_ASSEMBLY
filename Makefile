# Makefile of the machine
# Assembles the .s files into .o files and link them into one machine-language executable .x

# Command 1: creates the executable by linking the four object files in 32-bit (-m elf_i386)
bin/distributore.x: obj/main.o obj/funz.o obj/trad.o obj/logic.o
	ld -m elf_i386 -o bin/distributore.x obj/main.o obj/funz.o obj/trad.o obj/logic.o

# Command 2: assembles each source file into its object file, always in 32-bit (--32)
obj/main.o: src/main.s
	as --32 -o obj/main.o src/main.s

obj/funz.o: src/funz.s
	as --32 -o obj/funz.o src/funz.s

obj/trad.o: src/trad.s
	as --32 -o obj/trad.o src/trad.s

obj/logic.o: src/logic.s
	as --32 -o obj/logic.o src/logic.s

# Command 3: deletes the generated files with the "make clean" command so the obj and bin folders are empty
clean:
	rm -f obj/*.o bin/distributore.x