# Makefile for wspipe

# �����Ϸ� ����
CC = gcc
CFLAGS = -Wall -g

# Ÿ�� �̸�
TARGET = wspipe

# �ҽ� ����
SRC = wspipe.c

# ���� ���
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

# clean ���
clean:
	rm -f $(TARGET) *.o mail_body.txt

# ����
run:
	./$(TARGET) "cat wspipe.c" pipe
