//
// Created by root on 24-5-26.
//

int kern_init(void) __attribute__((noreturn));

char message[] = "hello cqust!!!";
char buf[1024];

int kern_init(void) {

    char* video = (char *) 0xb8000;
    for (int i = 0; i < sizeof (message); ++i) {
        video[i * 2] = message[i];
    }

    while (1);
}