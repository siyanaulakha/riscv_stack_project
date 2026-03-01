typedef unsigned int u32;

__attribute__((noinline))
u32 tiny(u32 x) {
    return x + 1;
}

int main(void) {
    volatile u32 a = 7;
    volatile u32 b = tiny(a);
    return (int)b;
}
