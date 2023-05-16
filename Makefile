CC = gcc
CFLAGS = -m32 -Wall
all: main.o swirl.o
	$(CC) $(CFLAGS) main.o swirl.o -o swirl
main.o: main.c
	$(CC) $(CFLAGS) -c main.c -o main.o
swirl.o: swirl.s
	nasm -f elf swirl.s
clean:
	rm -rf *.o swirl