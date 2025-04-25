# Makefile for wspipe

# 컴파일러 설정
CC = gcc
CFLAGS = -Wall -g

# 타겟 이름
TARGET = wspipe

# 소스 파일
SRC = wspipe.c

# 빌드 대상
$(TARGET): $(SRC)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRC)

# clean 명령
clean:
	rm -f $(TARGET) *.o mail_body.txt

# 실행
run:
	./$(TARGET) "cat wspipe.c" pipe
