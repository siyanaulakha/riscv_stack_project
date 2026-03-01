typedef unsigned int u32;

volatile u32 sink;

__attribute__((noinline))
u32 victim(u32 x) {
    volatile char buf[32];
    volatile u32 i;
    volatile u32 sum = x;

    for (i = 0; i < 32; i++) {
        buf[i] = (char)i;
    }

    for (i = 0; i < 32; i++) {
        sum += (u32)buf[i];
    }

    sink = sum;
    return sum;
}

int main(void) {
    return (int)victim(5);
}
