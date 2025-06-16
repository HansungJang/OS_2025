#include <unistd.h> // getopt() 함수를 위해 필요
#include <stdio.h>  // printf(), fprintf() 등을 위해 필요
#include <stdlib.h> // exit()를 위해 필요
#include "mtws_func.h" // 위에서 정의한 헤더 파일 포함
#include <ctype.h>
#include <bits/getopt_core.h>
 
void print_usage() {
    fprintf(stderr, "Usage: ./mtws -b <bounded buffer size> -t <num threads> -d <search directory> -w <search word>\n");
    fprintf(stderr, "  -b: bounded buffer size\n");
    fprintf(stderr, "  -t: number of threads searching word (except for main thread)\n");
    fprintf(stderr, "  -d: search directory\n");
    fprintf(stderr, "  -w: search word\n");
}

int main(int argc, char *argv[]) {
    int opt;

    // "b:t:d:w:"는 getopt()에 전달되는 옵션 문자열입니다.
    // 각 콜론(:)은 해당 옵션이 인수를 필요로 한다는 것을 의미합니다.
    // 예를 들어, -b 다음에 <buffer size>가 와야 합니다.
    while ((opt = getopt(argc, argv, "b:t:d:w:")) != -1) {
        switch (opt) {
            case 'b':
                buffer_size = atoi(optarg); // optarg는 -b 뒤의 인수를 가리킴
                if (buffer_size <= 0) {
                    fprintf(stderr, "Error: Buffer size must be a positive integer.\n");
                    print_usage();
                    exit(EXIT_FAILURE);
                }
                break;
            case 't':
                num_threads = atoi(optarg); // optarg는 -t 뒤의 인수를 가리킴
                if (num_threads <= 0) {
                    fprintf(stderr, "Error: Number of threads must be a positive integer.\n");
                    print_usage();
                    exit(EXIT_FAILURE);
                }
                break;
            case 'd':
                search_directory = optarg; // optarg는 -d 뒤의 인수를 가리킴
                break;
            case 'w':
                search_word = optarg; // optarg는 -w 뒤의 인수를 가리킴
                break;
            case '?': // 알 수 없는 옵션이거나 인수가 누락된 경우
                print_usage();
                exit(EXIT_FAILURE);
            default:
                print_usage();
                exit(EXIT_FAILURE);
        }
    }

    // 모든 필수 인수가 제공되었는지 확인
    if (buffer_size == 0 || num_threads == 0 || search_directory == NULL || search_word == NULL) {
        fprintf(stderr, "Error: All arguments (-b, -t, -d, -w) are required.\n");
        print_usage();
        exit(EXIT_FAILURE);
    }

    // 1. 뮤텍스 초기화
    pthread_mutex_init(&total_count_mutex, NULL);

    // 2. 검색 단어 소문자 변환 및 길이 저장
    search_word_len = strlen(search_word);
    search_word_lower = (char *)malloc(sizeof(char) * (search_word_len + 1));
    if (search_word_lower == NULL) {
        perror("Failed to allocate memory for search_word_lower");
        exit(EXIT_FAILURE);
    }
    for (int i = 0; i <= search_word_len; i++) {
        search_word_lower[i] = tolower((unsigned char)search_word[i]);
    }

    // 3. 바운디드 버퍼 초기화
    buffer_init(&file_buffer, buffer_size);

    pthread_t producer_tid;
    pthread_t *consumer_tids; // 소비자 스레드 ID 저장을 위한 배열
    consumer_thread_arg_t *consumer_args; // 소비자 스레드 인자 저장을 위한 배열

    consumer_tids = (pthread_t *)malloc(sizeof(pthread_t) * num_threads);
    if (consumer_tids == NULL) {
        perror("Failed to allocate memory for consumer_tids");
        exit(EXIT_FAILURE);
    }

    // 4. 생산자 스레드 생성
    if (pthread_create(&producer_tid, NULL, producer_thread, (void *)&file_buffer) != 0) {
        perror("Failed to create producer thread");
        exit(EXIT_FAILURE);
    }

    // 5. 소비자 스레드 생성
    for (int i = 0; i < num_threads; i++) {
        consumer_args = (consumer_thread_arg_t *)malloc(sizeof(consumer_thread_arg_t));
        if (consumer_args == NULL) {
            perror("Failed to allocate memory for consumer_args");
            exit(EXIT_FAILURE);
        }
        consumer_args->thread_idx = i; // 스레드 인덱스 전달

        if (pthread_create(&consumer_tids[i], NULL, consumer_thread, (void *)consumer_args) != 0) {
            perror("Failed to create consumer thread");
            exit(EXIT_FAILURE); 
        }
    }

    // 6. 모든 스레드 종료 대기
    pthread_join(producer_tid, NULL); // 생산자 스레드 종료 대기

    // 모든 소비자 스레드 종료 대기
    for (int i = 0; i < num_threads; i++) {
        pthread_join(consumer_tids[i], NULL);
    }

    // 7. 최종 결과 출력
    printf("Total found = %lld\n", total_found_words); // 총 찾은 단어 수 출력 (Num files=는 생략 또는 추가 구현)

    // 8. 자원 해제
    buffer_destroy(&file_buffer); // 바운디드 버퍼 자원 해제
    pthread_mutex_destroy(&total_count_mutex); // 총 단어 수 뮤텍스 파괴
    free(search_word_lower); // 소문자로 변환된 검색 단어 메모리 해제
    free(consumer_tids); // 소비자 스레드 ID 배열 메모리 해제
    // consumer_args는 각 스레드에서 free됩니다.
    return 0;
}