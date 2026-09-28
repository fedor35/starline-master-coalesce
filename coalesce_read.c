/* LD_PRELOAD shim: coalesce fragmented reads from /dev/ttyUSB* so that a burst
 * from the device arrives in ONE read(). StarLine Master's WintecBootloaderProtocol
 * requires the 31-byte bootloader banner in a single read. Linux cp210x delivers
 * it in 1..8 byte chunks. We wait for a silence gap after the first bytes. */
#define _GNU_SOURCE
#include <dlfcn.h>
#include <poll.h>
#include <unistd.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <errno.h>
#include <sys/ioctl.h>

static ssize_t (*real_read)(int, void *, size_t);
static int gap_ms = 8;     /* silence that ends a burst */
static int max_ms = 120;   /* hard cap per read */
static int dbg = 0;

static int is_serial(int fd) {
    char p[64], l[256]; snprintf(p, sizeof p, "/proc/self/fd/%d", fd);
    ssize_t n = readlink(p, l, sizeof l - 1);
    if (n <= 0) return 0;
    l[n] = 0;
    return !strncmp(l, "/dev/ttyUSB", 11) || !strncmp(l, "/dev/ttyACM", 11);
}

__attribute__((constructor)) static void init(void) {
    real_read = dlsym(RTLD_NEXT, "read");
    const char *e;
    if ((e = getenv("COALESCE_GAP_MS"))) gap_ms = atoi(e);
    if ((e = getenv("COALESCE_MAX_MS"))) max_ms = atoi(e);
    if ((e = getenv("COALESCE_DEBUG"))) dbg = atoi(e);
}

ssize_t read(int fd, void *buf, size_t count) {
    if (!real_read) real_read = dlsym(RTLD_NEXT, "read");
    ssize_t n = real_read(fd, buf, count);
    if (n <= 0 || (size_t)n >= count || !is_serial(fd)) return n;
    /* got a partial burst on a serial port: keep draining until the line goes quiet */
    int waited = 0;
    while ((size_t)n < count && waited < max_ms) {
        struct pollfd pf = { .fd = fd, .events = POLLIN };
        int r = poll(&pf, 1, gap_ms);
        if (r <= 0) break;
        ssize_t m = real_read(fd, (char *)buf + n, count - n);
        if (m <= 0) break;
        n += m; waited += gap_ms;
    }
    if (dbg) fprintf(stderr, "[coalesce] fd=%d -> %zd bytes\n", fd, n);
    return n;
}

