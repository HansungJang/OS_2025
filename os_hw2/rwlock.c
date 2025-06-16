#include "rwlock.h"

void rwlock_init(rwlock_t *rw) {
    sem_init(&rw->mutex, 0, 1);         // reader_count 보호용
    sem_init(&rw->writelock, 0, 1);     // writer 단독 접근 lock
    sem_init(&rw->queue, 0, 1);         // reader/writer 진입 순서 queue
    rw->reader_count = 0;
}

// rwlock.c 내부에 추가

// read-lock
void rwlock_acquire_readlock(rwlock_t *rw) {
    sem_wait(&rw->queue);           // queue 진입: 순서 보장
    sem_wait(&rw->mutex);           // reader_count 보호
    rw->reader_count++;
    if (rw->reader_count == 1) {
        sem_wait(&rw->writelock);   // 첫 reader만 writer 차단
    }
    sem_post(&rw->mutex);           // reader_count 해제
    sem_post(&rw->queue);           // 다음 reader/writer 진입 허용
}

void rwlock_release_readlock(rwlock_t *rw) {
    sem_wait(&rw->mutex);
    rw->reader_count--;
    if (rw->reader_count == 0) {
        sem_post(&rw->writelock);   // 마지막 reader → writer 허용
    }
    sem_post(&rw->mutex);
}

// write-lock
void rwlock_acquire_writelock(rwlock_t *rw) {
    sem_wait(&rw->queue);           // queue 진입
    sem_wait(&rw->writelock);       // writer는 단독 접근
    // queue를 여기서 잠시 유지
}

void rwlock_release_writelock(rwlock_t *rw) {
    sem_post(&rw->writelock);
    sem_post(&rw->queue);           // 다음 reader/writer 허용
}
