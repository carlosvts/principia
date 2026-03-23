#include <stdbool.h>
#include <stddef.h>
#include <stdint.h>
#include "limine.h"
#include "font.h"

/* =========================================================================
 * Limine protocol requests
 *
 * Before jumping to _start, Limine scans the kernel ELF for these request
 * structures in the .requests section. It fills in the .response pointer
 * for each one it recognizes. We ask for a framebuffer here.
 * ========================================================================= */

__attribute__((used, section(".requests_start_marker")))
static volatile LIMINE_REQUESTS_START_MARKER;

__attribute__((used, section(".requests")))
static volatile struct limine_framebuffer_request fb_request = {
    .id       = LIMINE_FRAMEBUFFER_REQUEST,
    .revision = 0,
};

__attribute__((used, section(".requests_end_marker")))
static volatile LIMINE_REQUESTS_END_MARKER;



/* =========================================================================
 * Framebuffer drawing primitives
 * ========================================================================= */

/* Write one pixel at (x, y). Color is 0xRRGGBB. */
static void put_pixel(struct limine_framebuffer *fb,
                      uint32_t x, uint32_t y, uint32_t color)
{
    uint32_t *row = (uint32_t *)((uint8_t *)fb->address + y * fb->pitch);
    row[x] = color;
}

/* Fill the entire screen with a single color. */
static void clear_screen(struct limine_framebuffer *fb, uint32_t color)
{
    for (uint32_t y = 0; y < fb->height; y++)
        for (uint32_t x = 0; x < fb->width; x++)
            put_pixel(fb, x, y, color);
}

/* Draw one ASCII character at pixel position (px, py). */
static void draw_char(struct limine_framebuffer *fb,
                      char c, uint32_t px, uint32_t py,
                      uint32_t fg, uint32_t bg)
{
    /* Clamp to printable range. */
    if (c < 0x20 || c > 0x7E)
        c = '?';

    const uint8_t *glyph = font[(uint8_t)(c - 0x20)];

    for (uint32_t row = 0; row < FONT_H; row++) {
        for (uint32_t col = 0; col < FONT_W; col++) {
            /* Bit 7 of each byte is the leftmost pixel. */
            uint32_t color = (glyph[row] & (0x80 >> col)) ? fg : bg;
            put_pixel(fb, px + col, py + row, color);
        }
    }
}

/* Draw a null-terminated string. Each glyph is 8px wide. */
static void draw_string(struct limine_framebuffer *fb,
                        const char *str,
                        uint32_t px, uint32_t py,
                        uint32_t fg, uint32_t bg)
{
    while (*str) {
        draw_char(fb, *str, px, py, fg, bg);
        px += FONT_W;
        str++;
    }
}

/* =========================================================================
 * Kernel entry point
 * ========================================================================= */

void kernel_main(void)
{
    /* Verify that Limine gave us a framebuffer. */
    if (fb_request.response == NULL || fb_request.response->framebuffer_count < 1)
        goto hang;

    struct limine_framebuffer *fb = fb_request.response->framebuffers[0];

    clear_screen(fb, 0x000000);
    draw_string(fb, "principia", 16, 16, 0xFFFFFF, 0x000000);

hang:
    while (1)
        __asm__ volatile("hlt");
}
