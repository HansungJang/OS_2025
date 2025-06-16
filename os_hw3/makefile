CC = gcc
CFLAGS = -Wall -pthread
TARGET = mtws
OBJS = mtws.o mtws_func.o

all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $@ $^

mtws.o: mtws.c mtws_func.h
	$(CC) $(CFLAGS) -c mtws.c

mtws_func.o: mtws_func.c mtws_func.h
	$(CC) $(CFLAGS) -c mtws_func.c

clean:
	rm -f $(OBJS) $(TARGET)
