#ifndef MTWS_H
#define MTWS_H

#include <pthread.h>
#include <stdbool.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <sys/stat.h>
#include <dirent.h>
#include <libgen.h>
#include <errno.h>

#define MAX_PATH_LENGTH 1024

// 전역 변수 선언 (extern 추가)
extern int buffer_size;
extern int num_threads;
extern char *search_directory;
extern char *search_word;

extern long long total_found_words;
extern pthread_mutex_t total_count_mutex;

extern char *search_word_lower;
extern int search_word_len;

// 소비자 스레드 인자 구조체는 정의로 유지
typedef struct {
    int thread_idx;
} consumer_thread_arg_t;

// 바운디드 버퍼 구조체는 정의로 유지
typedef struct {
    char **buffer;
    int size;
    int count;
    int fill;
    int use;
    pthread_mutex_t mutex;
    pthread_cond_t empty;
    pthread_cond_t full;
    bool producer_done;
} bounded_buffer_t;

// bounded_buffer_t file_buffer; // 이 부분도 제거합니다. 아래 mtws_func.c에서 정의합니다.
extern bounded_buffer_t file_buffer; // 이렇게 선언만 남깁니다.

// 함수 선언은 그대로 유지
void buffer_init(bounded_buffer_t *buf, int size);
void buffer_put(bounded_buffer_t *buf, char *filepath);
char *buffer_get(bounded_buffer_t *buf);
void buffer_destroy(bounded_buffer_t *buf);
bool is_text_file(const char *filename);
void traverse_directory(const char *dir_path, bounded_buffer_t *buf);
void *producer_thread(void *arg);
int search_word_in_file(const char *filepath, const char *word_to_find_lower, int word_len);
void *consumer_thread(void *arg);

#endif // MTWS_H