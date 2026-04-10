/*
 * test_arith.c - tests arithmetic, loops, conditionals, and function calls.
 * Should compile and assemble cleanly with mcc09 + asm09.
 */

extern putstr();
extern putnum();

/* Simple unsigned multiply via repeated addition */
unsigned mul(a, b)
    unsigned a, b;
{
    unsigned result;
    result = 0;
    while(b--)
        result += a;
    return result;
}

/* Compute and display n-th Fibonacci number */
unsigned fib(n)
    unsigned n;
{
    unsigned a, b, t;
    if(n <= 1)
        return n;
    a = 0;
    b = 1;
    while(--n) {
        t = b;
        b = a + b;
        a = t;
    }
    return b;
}

main()
{
    unsigned i;
    putstr("mul(6,7)=");
    putnum(mul(6, 7));
    putstr("\n");
    putstr("fib: ");
    for(i = 0; i < 8; ++i) {
        putnum(fib(i));
        putstr(" ");
    }
    putstr("\n");
}
