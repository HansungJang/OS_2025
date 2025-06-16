CC = gcc
CFLAGS = -Wall -pthread
TARGET = hw2
OBJS = hw2.o rwlock.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

hw2.o: hw2.c rwlock.h
	$(CC) $(CFLAGS) -c hw2.c

rwlock.o: rwlock.c rwlock.h
	$(CC) $(CFLAGS) -c rwlock.c

clean:
	rm -f $(OBJS) $(TARGET)
