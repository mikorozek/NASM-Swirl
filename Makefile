CC = gcc
CFLAGS = -Wall -I/usr/include/SDL2
LDFLAGS = -lSDL2


all: main.o
	$(CC) $(CFLAGS) main.o $(LDFLAGS) -o swirl


main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o


swirl.o: swirl.s
	nasm -f elf swirl.s

clean:
	rm -rf *.o swirl