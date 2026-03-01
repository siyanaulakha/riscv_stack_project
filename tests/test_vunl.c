typedef unsigned int u32;

volatile u32 sink;

__attribute__((noinline))
u32 safe_small(u32 x) {
    return x + 1;
}

__attribute__((noinline))
u32 vulnerable(u32 a) {
    volatile char buf[32];
    volatile u32 i;
    volatile u32 acc = a;

    for (i = 0; i < 32; i++) {
        buf[i] = (char)(i + 1);
    }

    for (i = 0; i < 32; i++) {
        acc += (u32)buf[i];
    }

    sink = acc;
    return acc;
}

int main(void) {
    volatile u32 x = 5;
    volatile u32 y = vulnerable(x);
    sink = y;
    return 0;
}
