#include "mtws_func.h" // 위에서 정의한 헤더 파일 포함

// 전역 변수 정의 (mtws_func.h에서 extern으로 선언된 것들을 여기서 정의)
int buffer_size = 0;
int num_threads = 0;
char *search_directory = NULL;
char *search_word = NULL;

long long total_found_words = 0;
pthread_mutex_t total_count_mutex;

char *search_word_lower = NULL;
int search_word_len = 0;

bounded_buffer_t file_buffer; 

// 바운디드 버퍼 초기화
void buffer_init(bounded_buffer_t *buf, int size) {
    buf->buffer = (char **)malloc(sizeof(char *) * size);
    if (buf->buffer == NULL) {
        perror("Failed to allocate buffer");
        exit(EXIT_FAILURE);
    }
    buf->size = size;
    buf->count = 0;
    buf->fill = 0;
    buf->use = 0;
    buf->producer_done = false; // 초기에는 생산자가 완료되지 않음

    pthread_mutex_init(&buf->mutex, NULL); // 뮤텍스 초기화 
    pthread_cond_init(&buf->empty, NULL);  // empty 조건 변수 초기화 
    pthread_cond_init(&buf->full, NULL);   // full 조건 변수 초기화 
}

// 바운디드 버퍼에 항목 추가 (생산자)
void buffer_put(bounded_buffer_t *buf, char *filepath) {
    pthread_mutex_lock(&buf->mutex); // 뮤텍스 잠금 

    // 버퍼가 가득 찼으면 empty 조건 변수에서 대기 
    // while 루프를 사용하여 Mesa semantics를 처리 
    while (buf->count == buf->size) {
        pthread_cond_wait(&buf->empty, &buf->mutex); // 잠금을 해제하고 대기 
    }

    // 파일 경로를 버퍼에 복사 (깊은 복사)
    buf->buffer[buf->fill] = strdup(filepath); // 동적 할당된 메모리를 복사
    if (buf->buffer[buf->fill] == NULL) {
        perror("Failed to strdup filepath");
        pthread_mutex_unlock(&buf->mutex);
        exit(EXIT_FAILURE);
    }

    buf->fill = (buf->fill + 1) % buf->size; // 다음 fill 인덱스 업데이트 
    buf->count++;                            // 항목 개수 증가

    pthread_cond_signal(&buf->full);   // full 조건 변수에 신호 (소비자 깨우기) 
    pthread_mutex_unlock(&buf->mutex); // 뮤텍스 잠금 해제 
}

// 바운디드 버퍼에서 항목 가져오기 (소비자)
char *buffer_get(bounded_buffer_t *buf) {
    char *filepath = NULL;

    pthread_mutex_lock(&buf->mutex); // 뮤텍스 잠금 

    // 버퍼가 비어있고 생산자가 아직 완료되지 않았으면 full 조건 변수에서 대기 
    // producer_done 플래그를 추가하여 생산자가 더 이상 파일을 추가하지 않을 때
    // 소비자가 무한정 기다리지 않도록 합니다.
    while (buf->count == 0 && !buf->producer_done) {
        pthread_cond_wait(&buf->full, &buf->mutex); // 잠금을 해제하고 대기 
    }

    // 버퍼가 비어있고 생산자도 완료되었다면 NULL 반환 (종료 신호)
    if (buf->count == 0 && buf->producer_done) {
        pthread_mutex_unlock(&buf->mutex);
        return NULL;
    }

    filepath = buf->buffer[buf->use]; // 항목 가져오기
    buf->buffer[buf->use] = NULL; // 가져간 위치는 NULL로 설정 (나중에 free를 위해)
    buf->use = (buf->use + 1) % buf->size; // 다음 use 인덱스 업데이트 
    buf->count--;                           // 항목 개수 감소

    pthread_cond_signal(&buf->empty);  // empty 조건 변수에 신호 (생산자 깨우기) 
    pthread_mutex_unlock(&buf->mutex); // 뮤텍스 잠금 해제 

    return filepath;
}

// 바운디드 버퍼 자원 해제
void buffer_destroy(bounded_buffer_t *buf) {
    // 버퍼에 남아있는 파일 경로 문자열 메모리 해제
    // 이 부분은 모든 소비 스레드가 종료된 후 호출되어야 안전합니다.
    // 만약 버퍼에 남은 요소가 있다면 (예외 상황) 해당 메모리를 해제합니다.
    for (int i = 0; i < buf->size; i++) {
        if (buf->buffer[i] != NULL) {
            free(buf->buffer[i]);
            buf->buffer[i] = NULL;
        }
    }
    free(buf->buffer);
    pthread_mutex_destroy(&buf->mutex); // 뮤텍스 파괴
    pthread_cond_destroy(&buf->empty);  // empty 조건 변수 파괴
    pthread_cond_destroy(&buf->full);   // full 조건 변수 파괴
}

bool is_text_file(const char *filename) {
    const char *dot = strrchr(filename, '.'); // 마지막 '.' 찾기
    if (!dot || dot == filename) return false; // '.'이 없거나 파일명 맨 앞에 있으면 확장자 아님

    // 일반적인 텍스트 파일 확장자들
    if (strcasecmp(dot, ".txt") == 0 ||
        strcasecmp(dot, ".c") == 0 ||
        strcasecmp(dot, ".h") == 0 ||
        strcasecmp(dot, ".sql") == 0 ||
        strcasecmp(dot, ".dart") == 0 ||
        strcasecmp(dot, ".java") == 0 ||
        strcasecmp(dot, ".py") == 0 ||
        strcasecmp(dot, ".md") == 0 ||
        strcasecmp(dot, ".log") == 0) {
        return true;
    }
    return false;
}


void traverse_directory(const char *dir_path, bounded_buffer_t *buf) {
    DIR *dir;
    struct dirent *entry;
    struct stat filestat;
    char full_path[MAX_PATH_LENGTH];

    // 디렉토리를 엽니다.
    dir = opendir(dir_path);
    if (dir == NULL) {
        fprintf(stderr, "Error: Could not open directory %s: %s\n", dir_path, strerror(errno));
        // 에러 발생 시 생산자 스레드를 종료하기 위해 producer_done 플래그를 설정하고 반환합니다.
        // 이 부분은 에러 처리 정책에 따라 달라질 수 있습니다.
        pthread_mutex_lock(&buf->mutex);
        buf->producer_done = true; // 생산자가 더 이상 파일을 생성할 수 없음을 알립니다.
        pthread_cond_broadcast(&buf->full); // 대기 중인 소비자 스레드에게 신호를 보내 깨웁니다.
        pthread_mutex_unlock(&buf->mutex);
        return;
    }

    // 디렉토리 항목들을 읽습니다.
    while ((entry = readdir(dir)) != NULL) {
        // 현재 디렉토리(".")와 상위 디렉토리("..")는 건너뜁니다.
        if (strcmp(entry->d_name, ".") == 0 || strcmp(entry->d_name, "..") == 0) {
            continue;
        }

        // 전체 경로를 구성합니다.
        snprintf(full_path, sizeof(full_path), "%s/%s", dir_path, entry->d_name);
        full_path[sizeof(full_path) - 1] = '\0'; // 안전을 위해 NULL 종료 확인

        // 파일의 상태 정보를 가져옵니다.
        if (stat(full_path, &filestat) == -1) {
            fprintf(stderr, "Error: Could not get stat for %s: %s\n", full_path, strerror(errno));
            continue; // 다음 항목으로 넘어갑니다.
        }

        // 디렉토리인 경우 재귀적으로 탐색합니다.
        if (S_ISDIR(filestat.st_mode)) { // S_ISDIR은 파일 타입이 디렉토리인지 확인 
            traverse_directory(full_path, buf); // 재귀 호출
        }
        // 일반 파일인 경우 (텍스트 파일인지 확인 후) 버퍼에 추가합니다.
        else if (S_ISREG(filestat.st_mode)) { // S_ISREG은 파일 타입이 일반 파일인지 확인 
            // 여기서는 단순 확장자로 텍스트 파일을 판별하지만, 더 복잡한 로직이 필요할 수도 있습니다.
            if (is_text_file(entry->d_name)) {
                buffer_put(buf, full_path); // 파일 경로를 버퍼에 추가
            }
        }
    }

    closedir(dir); // 디렉토리를 닫습니다. 
}

void *producer_thread(void *arg) {
    bounded_buffer_t *buf = (bounded_buffer_t *)arg;
    
    printf("[Producer Thread] Started searching in directory: %s\n", search_directory);

    // 디렉토리 탐색 시작
    traverse_directory(search_directory, buf);

    // 모든 파일 탐색 및 버퍼 추가가 완료되었음을 알립니다.
    pthread_mutex_lock(&buf->mutex);
    buf->producer_done = true; // 생산자가 완료되었음을 플래그로 설정
    pthread_cond_broadcast(&buf->full); // 대기 중인 모든 소비자 스레드에게 신호를 보내 깨웁니다.
                                        // (더 이상 생산될 파일이 없음을 알림)
    pthread_mutex_unlock(&buf->mutex);

    printf("[Producer Thread] Finished searching all files.\n");
    return NULL;
}

// 파일에서 특정 단어를 검색하는 함수
int search_word_in_file(const char *filepath, const char *word_to_find_lower, int word_len) {
    FILE *fp;
    char *line = NULL;
    size_t len = 0;
    ssize_t read;
    int found_count = 0;
    
    // 파일을 엽니다.
    fp = fopen(filepath, "r");
    if (fp == NULL) {
        fprintf(stderr, "Error: Could not open file %s: %s\n", filepath, strerror(errno));
        return 0; // 파일을 열 수 없으면 0을 반환합니다.
    }

    // 파일 내용을 한 줄씩 읽으면서 단어를 검색합니다.
    while ((read = getline(&line, &len, fp)) != -1) {
        char *temp_line = line;
        while ((temp_line = strcasestr(temp_line, word_to_find_lower)) != NULL) {
            found_count++;
            temp_line += word_len; // 찾은 단어 다음 위치부터 다시 검색
        }
    }

    // getline이 내부적으로 할당한 메모리를 해제합니다.
    if (line) {
        free(line);
    }
    fclose(fp); // 파일을 닫습니다.

    return found_count;
}

// 소비자 스레드 함수
void *consumer_thread(void *arg) {
    consumer_thread_arg_t *thread_args = (consumer_thread_arg_t *)arg;
    int thread_idx = thread_args->thread_idx;
    char *filepath = NULL;
    int files_processed_by_this_thread = 0; // 이 스레드가 처리한 파일 수 (출력 예시를 위해)

    printf("[Thread#%d] started searching '%s'...\n", thread_idx, search_word);

    while (1) {
        filepath = buffer_get(&file_buffer); // 버퍼에서 파일 경로를 가져옵니다.

        // 생산자가 모든 파일을 찾았고 버퍼가 비어있으면 종료 신호이므로 루프를 종료합니다.
        if (filepath == NULL) {
            break;
        }

        // 파일에서 단어를 검색합니다.
        int current_found_count = search_word_in_file(filepath, search_word_lower, search_word_len);
        
        // 검색 결과를 출력합니다.
        printf("[Thread#%d-%d] %s: %d found\n", 
               thread_idx, files_processed_by_this_thread, filepath, current_found_count);
        
        // 총 단어 수에 추가하고 뮤텍스로 보호합니다.
        pthread_mutex_lock(&total_count_mutex);
        total_found_words += current_found_count;
        pthread_mutex_unlock(&total_count_mutex);

        files_processed_by_this_thread++; // 이 스레드가 처리한 파일 수 증가
        free(filepath); // buffer_get에서 strdup으로 할당된 메모리를 해제합니다.
    }

    printf("[Thread#%d] finished searching.\n", thread_idx);
    // 스레드 인수를 위해 동적으로 할당한 메모리 해제
    free(thread_args); 
    return NULL;
}
