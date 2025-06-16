// rwlock.h
#ifndef RWLOCK_H
#define RWLOCK_H

#include <semaphore.h>

// Reader-Writer lock 구조체
typedef struct _rwlock_t {
    sem_t mutex;        // reader count 보호용
    sem_t writelock;    // writer 단독 접근
    sem_t queue;        // fairness를 위한 진입 queue
    int reader_count;
} rwlock_t;

void rwlock_init(rwlock_t *rw);
void rwlock_acquire_readlock(rwlock_t *rw);
void rwlock_release_readlock(rwlock_t *rw);
void rwlock_acquire_writelock(rwlock_t *rw);
void rwlock_release_writelock(rwlock_t *rw);

#endif
