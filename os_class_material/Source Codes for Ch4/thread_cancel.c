#include <stdio.h>
#include <unistd.h>
#include <sys/types.h>
#include <pthread.h>
  
int counter = 0;        // Counter
pthread_t tmp_thread;   // Thread ID for func2
  
void* func1(void* arg) {
    while (1) {
        printf("Thread #1 (counter=%d)\n", counter);       
        if (counter == 5) { 
            // for cancel thread_two
            pthread_cancel(tmp_thread); 
            // for exit from thread_one 
            pthread_exit(NULL);  
        }
        sleep(1);   // sleep 1 second
    }
}

void* func2(void* arg) {
    // get thread ID 
    tmp_thread = pthread_self(); 
    while (1) {
        printf("Thread #2 (counter=%d)\n", counter);
        counter++;
        sleep(1); // sleep 1 second
    }
}  

int main() {
     pthread_t thread_one, thread_two; 
  
    // create thread_one and thread_two
    pthread_create(&thread_one, NULL, func1, NULL);
    pthread_create(&thread_two, NULL, func2, NULL); 
  
    // waiting for when threads are completed
    pthread_join(thread_one, NULL); 
    pthread_join(thread_two, NULL); 

    return 0;
}
