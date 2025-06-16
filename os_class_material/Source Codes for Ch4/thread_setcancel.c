#include <pthread.h>
#include <stdio.h>
#include <unistd.h>
#include <limits.h>

unsigned int counter;

void* threadFunction(void* arg) {
    pthread_setcanceltype(*(int*)arg, NULL);
    counter = 0;
    while (1) {
        printf("Running... %u \n", counter);
        while (counter < 4000000000) {
            counter++;
            // if (counter % 500000000 == 0)
            //     pthread_testcancel();
        }
    }
    return NULL;
}

int main() {
    pthread_t thread;
    int async = PTHREAD_CANCEL_ASYNCHRONOUS;
    int deferred = PTHREAD_CANCEL_DEFERRED;
    printf("Maximum Value of Unsigned Long=%u \n", UINT_MAX);

    // Asynchronous cancellation
    pthread_create(&thread, NULL, threadFunction, &async);
    sleep(3);  
    pthread_cancel(thread); 
    pthread_join(thread, NULL);
    printf("Thread with asynchronous cancellation stopped. "                         
           "counter=%u \n", counter);

    // Deferred cancellation
    pthread_create(&thread, NULL, threadFunction, &deferred);
    sleep(3);  
    pthread_cancel(thread); 
    pthread_join(thread, NULL);
    printf("Thread with deferred cancellation stopped. "
           "counter=%u \n", counter);
    return 0;
}
