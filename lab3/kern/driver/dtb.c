#include <dtb.h>
#include <stdio.h>

void dtb_init(void) {
    cprintf("DTB Init\n");
    cprintf("HartID: %ld\n", boot_hartid);
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
    // 在这里添加解析设备树的代码
}
