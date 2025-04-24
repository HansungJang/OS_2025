#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/wait.h>
#include <string.h>

#include <fcntl.h> // email ������ ����
#include <stdbool.h>

#define READ_END 0
#define WRITE_END 1
#define BUFFER_SIZE 1024

#define AC_RED "\x1b[31m"
#define AC_RESET "\x1b[0m"
#define AC_Green "\x1b[32m"

ssize_t read_line(int fd, char *buffer, size_t max_length);


typedef struct {
    char **lines;
    int size;
    int capacity;
} StringVector;


char *my_strstr(const char *haystack, const char *needle);

// �̸��� ������ 
void save_report_to_file(const char *filename, const char *word, int total_count, StringVector *lines);
void send_report_email(const char *filename, const char *email);
bool ask_user_to_send_email();


void init_vector(StringVector *vec);
void push_line(StringVector *vec, const char *line);
void free_vector(StringVector *vec); 

// ./swpipe "cat test.txt" word
int main(int argc, char *argv[]) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <command> <word>\n", argv[0]);
        return 1;
    }

    char *command = argv[1];
    char *word = argv[2];
    int pipe_fd[2];
    char buffer[BUFFER_SIZE];
    int total_count = 0;

    int total_line  = 1; 


    pipe(pipe_fd);
    pid_t pid = fork();

    if (pid == 0) {
        // �ڽ�: stdout �� pipe[WRITE_END]
        close(pipe_fd[READ_END]);
        dup2(pipe_fd[WRITE_END], STDOUT_FILENO);
        close(pipe_fd[WRITE_END]);
        execl("/bin/sh", "sh", "-c", command, NULL);
        perror("exec failed");
        exit(1);
    } else {

        //email�� ������ ���ڿ� ����
        StringVector report_lines;
        init_vector(&report_lines);

        // �θ�: pipe���� �б�
        close(pipe_fd[WRITE_END]);
        while (read_line(pipe_fd[READ_END], buffer, BUFFER_SIZE - 1) > 0) {
            char *cur = buffer;
            char *ptr;

            char temp_line[BUFFER_SIZE * 2] = {0}; // �� ��¿�

            while ((ptr = my_strstr(cur, word)) != NULL) {
                total_count++;

                // terminal ��� (fins word)
                printf("%s", AC_Green);
                printf("[%d]:\t", total_line);
                printf("%s", AC_RESET);
                fwrite(cur, 1, ptr - cur, stdout);
                printf("%s", AC_RED);
                fwrite(ptr, 1, strlen(word), stdout);
                printf("%s", AC_RESET);
                printf("%s", ptr+strlen(word));
                
                snprintf(temp_line, sizeof(temp_line), "[%d]:\t%s", total_line, cur);            
                push_line(&report_lines, temp_line);    

                cur = ptr + strlen(word);
            }
 
            total_line++; 
        }
// Creativity (email - share ���)
save_report_to_file("mail_body.txt", word, total_count, &report_lines);
free_vector(&report_lines);

if (ask_user_to_send_email()) {
    send_report_email("mail_body.txt", "hansung.j1106@gmail.com");
} else {
    printf("okay! bye;)\n");
}

        wait(NULL);
     }

    return 0;
}

// �� ������ pipe���� �б�
ssize_t read_line(int fd, char *buffer, size_t max_length) {
    ssize_t num_read = 0;
    char c;
    while (num_read < max_length && read(fd, &c, 1) == 1) {
        buffer[num_read++] = c;
        if (c == '\n') break;
    }
    buffer[num_read] = '\0';
    return num_read;
}

char *my_strstr(const char *haystack, const char *needle) {
    if (!*needle) return (char *)haystack;

    for (int i = 0; haystack[i] != '\0'; i++) {
        int j = 0;
        while (needle[j] != '\0' && haystack[i + j] == needle[j]) {
            j++;
        }
        if (needle[j] == '\0') {
            return (char *)&haystack[i];
        }
    }
    return NULL;
}

void save_report_to_file(const char *filename, const char *word, int total_count, StringVector *lines)
{
    FILE *fp = fopen(filename, "w");
    if (!fp) {
        perror("���� ���� ����");
        return;
    }

    fprintf(fp, "To: hansung.j1106@gmail.com\n");
    fprintf(fp, "Subject: %s Ű���� �˻� ���\n", word);
    fprintf(fp, "\n"); // RFC 822 format (������ for-loop ���� �׸� ���õ�)

    fprintf(fp, "�˻��� Ű����: %s\n", word);
    fprintf(fp, "�� ���� Ƚ��: %dȸ\n\n", total_count);

    fprintf(fp, "[Ű���� ���� line]\n");
    for (int i = 0; i < lines->size; i++) {
        fprintf(fp, "%s", lines->lines[i]);
    }

    fclose(fp);
}

void send_report_email(const char *filename, const char *email){
    pid_t pid = fork();
    if (pid == 0) {
        int fd = open(filename, O_RDONLY);
        if (fd < 0) {
            perror("fail to open file...");
            exit(1);
        }

        dup2(fd, STDIN_FILENO);
        close(fd);

        execl("/usr/bin/msmtp", "msmtp", email, NULL);
        perror("msmtp execute error...");
        exit(1);
    } else {
        waitpid(pid, NULL, 0);
        printf("email send sucessfuly!\n");
    }
}

bool ask_user_to_send_email(){
    char answer[10]; 
    printf("you want a share your find result to your email? [y/n] >  ");
    fgets(answer, sizeof(answer), stdin);

    return (answer[0] == 'y' || answer[0] == 'Y');
}

void init_vector(StringVector *vec) {
    vec->size = 0;
    vec->capacity = 10;
    vec->lines = (char **)malloc(sizeof(char *) * vec->capacity);
}

void push_line(StringVector *vec, const char *line) {
    if (vec->size >= vec->capacity) {
        vec->capacity *= 2;
        vec->lines = (char **)realloc(vec->lines, sizeof(char *) * vec->capacity);
    }
    vec->lines[vec->size] = strdup(line);  // strdup: ���ڿ� ����
    vec->size++;
}

void free_vector(StringVector *vec) {
    for (int i = 0; i < vec->size; i++) {
        free(vec->lines[i]);
    }
    free(vec->lines);
}