typedef unsigned int u32;

volatile u32 sink;

__attribute__((noinline))
u32 leaf_buf(u32 x) {
    volatile char buf[24];
    volatile u32 i;
    volatile u32 sum = x;

    for (i = 0; i < 24; i++) {
        buf[i] = (char)(i + 1);
    }

    for (i = 0; i < 24; i++) {
        sum += (u32)buf[i];
    }

    sink = sum;
    return sum;
}

int main(void) {
    return (int)leaf_buf(3);
}
