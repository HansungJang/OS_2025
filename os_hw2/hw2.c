#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>     // usleep
#include <pthread.h>
#include <sys/time.h>
#include "rwlock.h"

#define MAX_THREADS 100

typedef struct thread_arg {
    int id;  // count
    int processing_time;   // milliseconds
} thread_arg_t;

struct timeval  program_start;

double get_current_time() {
    struct timeval now;
    gettimeofday(&now, NULL);
    return (now.tv_sec - program_start.tv_sec) +
           (now.tv_usec - program_start.tv_usec) / 1000000.0;
}

rwlock_t rw;  // 외부에서 선언될 전역 reader-writer lock

void *reader(void *arg) {
    thread_arg_t *targ = (thread_arg_t *)arg;
    
    printf("[%.4f] Reader #%d: Created! \n",  get_current_time(), targ->id);
    
    rwlock_acquire_readlock(&rw);
    printf("[%.4f] Reader #%d: Read started! (reading %d ms)\n", get_current_time(), targ->id, targ->processing_time );
    usleep(targ->processing_time * 1000);  // ms → us , 작업실행에 필요한 buffer 시간
    
     rwlock_release_readlock(&rw);
    printf("[%.4f] Reader #%d: Terminated\n",  get_current_time(), targ->id );


    free(targ);
    pthread_exit(NULL);
}

void *writer(void *arg) {
    thread_arg_t *targ = (thread_arg_t *)arg;
    
    printf("[%.4f] Writer #%d: Created! \n", get_current_time(), targ->id);

     rwlock_acquire_writelock(&rw);
    printf("[%.4f] Writer #%d: Write started! (writing %d ms)\n",  get_current_time(), targ->id, targ->processing_time );
    usleep(targ->processing_time * 1000);
    
     rwlock_release_writelock(&rw);
    printf("[%.4f] Writer #%d: Terminated! \n", get_current_time(),targ->id);

    free(targ);
    pthread_exit(NULL);
}



int main(int argc, char *argv[]) {
    gettimeofday(&program_start, NULL);
    
    if (argc != 2) {
        fprintf(stderr, "Usage: %s <sequence file>\n", argv[0]);
        exit(EXIT_FAILURE);
    }

    FILE *fp = fopen(argv[1], "r");
    if (!fp) {
        perror("fopen");
        exit(EXIT_FAILURE);
    }

    rwlock_init(&rw);

    pthread_t threads[MAX_THREADS];
    int thread_count = 0;
    char line[128];
    int reader_id = 0, writer_id = 0;

    while (fgets(line, sizeof(line), fp) && thread_count < MAX_THREADS) {
        char type;
        int time;

        if (sscanf(line, "%c %d", &type, &time) != 2) {
            continue;  // skip malformed lines
        }

        thread_arg_t *arg = malloc(sizeof(thread_arg_t));
        arg->processing_time = time;

        if (type == 'R') {
            arg->id = ++reader_id;
            
             pthread_create(&threads[thread_count], NULL, reader, arg);
        } else if (type == 'W') {
            arg->id = ++writer_id;
            
             pthread_create(&threads[thread_count], NULL, writer, arg);
        } else {
            free(arg);  // invalid type
            continue;
        }

        thread_count++;
        usleep(100000); // 100ms
    }

    // 모든 thread가 끝날 때까지 대기
    for (int i = 0; i < thread_count; i++) {
        pthread_join(threads[i], NULL);
    }

    fclose(fp);
    return 0;
}