/* Acknowledge the WPCM450 dynamic-IRQ enable request under QEMU. */
extern void *dlsym(void *handle, const char *name);

int ioctl(int fd, unsigned long request, ...)
{
    static int (*real_ioctl)(int, unsigned long, ...);
    __builtin_va_list arguments;
    void *argument;

    if (request == 0xc004b900 || request == 0xc004b901)
        return 0;

    __builtin_va_start(arguments, request);
    argument = __builtin_va_arg(arguments, void *);
    __builtin_va_end(arguments);

    if (!real_ioctl)
        real_ioctl = dlsym((void *)-1, "ioctl");
    return real_ioctl(fd, request, argument);
}
