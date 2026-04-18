/* test_typedef.c - exercises typedef in all major forms */

/* --- scalar typedefs --- */
typedef unsigned char  uint8_t;
typedef unsigned int   uint16_t;
typedef char           int8_t;
typedef int            int16_t;

/* --- pointer typedefs --- */
typedef char *         string_t;
typedef unsigned char *byte_ptr;

/* --- named struct typedef --- */
struct Point {
    int x;
    int y;
};
typedef struct Point Point;

/* --- anonymous struct typedef --- */
typedef struct {
    unsigned char r;
    unsigned char g;
    unsigned char b;
} Color;

/* --- nested struct typedef (Color must be defined first) --- */
typedef struct {
    Color fg;
    Color bg;
    unsigned char mode;
} Palette;

/* --- pointer to typedef'd struct --- */
typedef Color *ColorPtr;

/* --- variables using all the typedefs --- */
uint8_t     vdg_mode;
uint16_t    counter;
int8_t      delta;
int16_t     signed_val;
string_t    msg;
byte_ptr    vram;
Point       origin;
Color       border;
Palette     coco_palette;
ColorPtr    cur_color;

/* use sizeof with typedef'd types */
int sizes[6];

init_sizes()
{
    sizes[0] = sizeof(uint8_t);
    sizes[1] = sizeof(uint16_t);
    sizes[2] = sizeof(Color);
    sizes[3] = sizeof(Palette);
    sizes[4] = sizeof(Point);
    sizes[5] = sizeof(ColorPtr);
}

/* function taking typedef'd parameters */
set_color(c, r, g, b)
    Color *c;
    uint8_t r, g, b;
{
    c->r = r;
    c->g = g;
    c->b = b;
}

/* function returning typedef'd type */
Color *get_fg()
{
    return &coco_palette.fg;
}

main()
{
    vdg_mode = 4;
    counter = 256;
    delta = -1;
    signed_val = -32000;

    origin.x = 0;
    origin.y = 0;

    set_color(&border, 7, 7, 0);

    coco_palette.mode = vdg_mode;
    set_color(&coco_palette.fg, 7, 7, 7);
    set_color(&coco_palette.bg, 0, 0, 0);

    cur_color = get_fg();
    cur_color->r = 3;

    init_sizes();
}
