CC = gcc
CFLAGS = -Wall -g -I/usr/include/SDL2
LDFLAGS = -lSDL2


all: main.o swirl.o
	$(CC) $(CFLAGS) main.o swirl.o $(LDFLAGS) -o swirl


main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o


swirl.o: swirl.s
	nasm -f elf64 swirl.s -o swirl.o

clean:
	rm -rf *.o swirl