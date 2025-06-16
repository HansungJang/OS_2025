#include <stdio.h>
#include <pthread.h>
#include <semaphore.h>

int sum = 0;
sem_t sem;

void *counter(void *param)
{
    int k; 
    for(k = 0; k < 10000; k++){
        sem_wait(&sem);
        sum++;
        sem_post(&sem);
    }
    pthread_exit(0);
}

#if 0
int main(){
    pthread_t tid1, tid2; 
    sem_init(&sem, 0, 1); // binary semaphore initialized to 1 (mutex)
    pthread_create(&tid1, NULL, counter, NULL);
    pthread_create(&tid2, NULL, counter, NULL);
    pthread_join(tid1, NULL);
    pthread_join(tid2, NULL);
    printf("Final sum: %d\n", sum);
    sem_destroy(&sem); // clean up semaphore
    return 0;
}
#endif
int main(){
    pthread_t tid[5]; 
    sem_init(&sem, 0, 5); // counting semaphore initialized to 1 (mutex)
    
    for(int i = 0; i < 5; i++) {
        pthread_create(&tid[i], NULL, counter, NULL);
    }
    for(int i = 0; i < 5; i++) {
        pthread_join(tid[i], NULL);
    }
    printf("Final sum: %d\n", sum);
    sem_destroy(&sem); // clean up semaphore
    return 0;
}