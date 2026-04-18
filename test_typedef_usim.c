/* typedef smoke test for usim09 - exercises typedef and prints results */

typedef unsigned char  uint8_t;
typedef unsigned int   uint16_t;
typedef char           int8_t;

typedef struct { int x; int y; } Point;
typedef struct { unsigned char r; unsigned char g; unsigned char b; } Color;
typedef struct {
    Color fg;
    Color bg;
    unsigned char mode;
} Palette;

uint8_t  vdg_mode;
uint16_t counter;
int8_t   delta;
Point    origin;
Color    border;
Palette  pal;

/* sizeof results storage */
int sz_uint8;
int sz_uint16;
int sz_point;
int sz_color;
int sz_palette;

set_point(p, x, y)
    Point *p;
    int x, y;
{
    p->x = x;
    p->y = y;
}

set_color(c, r, g, b)
    Color *c;
    uint8_t r, g, b;
{
    c->r = r;
    c->g = g;
    c->b = b;
}

print_int(n)
    int n;
{
    putstr("  ");
    if(n < 0) { putchr('-'); n = -n; }
    if(n >= 10) putchr('0' + n/10);
    putchr('0' + n%10);
    putchr('\n');
}

main()
{
    /* scalar typedefs */
    vdg_mode = 4;
    counter  = 1024;
    delta    = -7;

    /* struct member access */
    set_point(&origin, 10, 20);
    set_color(&border, 7, 3, 0);

    /* nested struct */
    pal.mode = vdg_mode;
    set_color(&pal.fg, 7, 7, 7);
    set_color(&pal.bg, 0, 0, 0);

    /* sizeof */
    sz_uint8   = sizeof(uint8_t);
    sz_uint16  = sizeof(uint16_t);
    sz_point   = sizeof(Point);
    sz_color   = sizeof(Color);
    sz_palette = sizeof(Palette);

    /* report */
    putstr("typedef test\n");

    putstr("vdg_mode="); print_int(vdg_mode);
    putstr("counter=");  print_int(counter);
    putstr("delta=");    print_int(delta);
    putstr("origin.x="); print_int(origin.x);
    putstr("origin.y="); print_int(origin.y);
    putstr("border.r="); print_int(border.r);
    putstr("pal.fg.r="); print_int(pal.fg.r);
    putstr("pal.bg.r="); print_int(pal.bg.r);
    putstr("pal.mode="); print_int(pal.mode);

    putstr("sz uint8=");   print_int(sz_uint8);
    putstr("sz uint16=");  print_int(sz_uint16);
    putstr("sz Point=");   print_int(sz_point);
    putstr("sz Color=");   print_int(sz_color);
    putstr("sz Palette="); print_int(sz_palette);

    putstr("PASS\n");
}
