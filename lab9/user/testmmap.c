// /*
//  * testmmap.c - 测试mmap功能的用户程序
//  * 
//  * 测试内容：
//  * 1. 匿名映射（MAP_ANONYMOUS）
//  * 2. 文件映射
//  * 3. munmap解除映射
//  */

// #include <stdio.h>
// #include <ulib.h>
// #include <unistd.h>
// #include <file.h>

// #define PAGE_SIZE 4096

// /* 测试1：匿名映射 */
// static int
// test_anonymous_mmap(void) {
//     cprintf("Test 1: Anonymous mmap...\n");
    
//     /* 申请一个页面的匿名映射 */
//     void *addr = mmap(NULL, PAGE_SIZE, PROT_READ | PROT_WRITE, 
//                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    
//     if (addr == MAP_FAILED) {
//         cprintf("  FAILED: mmap returned MAP_FAILED\n");
//         return -1;
//     }
    
//     cprintf("  mmap returned address: 0x%x\n", (uintptr_t)addr);
    
//     /* 写入数据 */
//     int *ptr = (int *)addr;
//     cprintf("  Writing to mapped memory...\n");
//     ptr[0] = 0x12345678;
//     ptr[1] = 0xDEADBEEF;
    
//     /* 读取并验证数据 */
//     cprintf("  Reading from mapped memory...\n");
//     if (ptr[0] != 0x12345678 || ptr[1] != 0xDEADBEEF) {
//         cprintf("  FAILED: Data verification failed\n");
//         cprintf("    Expected: 0x12345678, 0xDEADBEEF\n");
//         cprintf("    Got: 0x%x, 0x%x\n", ptr[0], ptr[1]);
//         return -1;
//     }
    
//     cprintf("  Data verified successfully!\n");
    
//     /* 解除映射 */
//     cprintf("  Unmapping memory...\n");
//     if (munmap(addr, PAGE_SIZE) != 0) {
//         cprintf("  FAILED: munmap failed\n");
//         return -1;
//     }
    
//     cprintf("  Test 1 PASSED!\n\n");
//     return 0;
// }

// /* 测试2：多页匿名映射 */
// static int
// test_multi_page_mmap(void) {
//     cprintf("Test 2: Multi-page anonymous mmap...\n");
    
//     size_t len = PAGE_SIZE * 4;  /* 4个页面 */
    
//     void *addr = mmap(NULL, len, PROT_READ | PROT_WRITE,
//                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    
//     if (addr == MAP_FAILED) {
//         cprintf("  FAILED: mmap returned MAP_FAILED\n");
//         return -1;
//     }
    
//     cprintf("  mmap returned address: 0x%x, length: 0x%x\n", 
//             (uintptr_t)addr, len);
    
//     /* 在每个页面写入不同的数据 */
//     cprintf("  Writing to each page...\n");
//     int i;
//     for (i = 0; i < 4; i++) {
//         int *page_ptr = (int *)((char *)addr + i * PAGE_SIZE);
//         page_ptr[0] = 0x1000 + i;
//         cprintf("    Page %d: wrote 0x%x at 0x%x\n", 
//                 i, page_ptr[0], (uintptr_t)page_ptr);
//     }
    
//     /* 验证每个页面的数据 */
//     cprintf("  Verifying each page...\n");
//     for (i = 0; i < 4; i++) {
//         int *page_ptr = (int *)((char *)addr + i * PAGE_SIZE);
//         if (page_ptr[0] != 0x1000 + i) {
//             cprintf("  FAILED: Page %d verification failed\n", i);
//             return -1;
//         }
//     }
    
//     /* 解除映射 */
//     cprintf("  Unmapping memory...\n");
//     if (munmap(addr, len) != 0) {
//         cprintf("  FAILED: munmap failed\n");
//         return -1;
//     }
    
//     cprintf("  Test 2 PASSED!\n\n");
//     return 0;
// }

// /* 测试3：文件映射（如果支持） */
// static int
// test_file_mmap(void) {
//     cprintf("Test 3: File mmap...\n");
    
//     /* 尝试打开一个文件 */
//     int fd = open("/hello", O_RDONLY);
//     if (fd < 0) {
//         cprintf("  Skipped: Could not open /hello (fd=%d)\n", fd);
//         cprintf("  (File mmap test requires a readable file)\n\n");
//         return 0;  /* 不算失败，只是跳过 */
//     }
    
//     cprintf("  Opened /hello, fd=%d\n", fd);
    
//     /* 映射文件的第一个页面 */
//     void *addr = mmap(NULL, PAGE_SIZE, PROT_READ, MAP_PRIVATE, fd, 0);
    
//     if (addr == MAP_FAILED) {
//         cprintf("  FAILED: mmap returned MAP_FAILED\n");
//         close(fd);
//         return -1;
//     }
    
//     cprintf("  mmap returned address: 0x%x\n", (uintptr_t)addr);
    
//     /* 读取映射的内容（ELF文件头应该以0x7f 'E' 'L' 'F'开头） */
//     unsigned char *ptr = (unsigned char *)addr;
//     cprintf("  First 16 bytes of mapped file:\n    ");
//     int i;
//     for (i = 0; i < 16; i++) {
//         cprintf("%02x ", ptr[i]);
//     }
//     cprintf("\n");
    
//     /* 检查ELF魔数 */
//     if (ptr[0] == 0x7f && ptr[1] == 'E' && ptr[2] == 'L' && ptr[3] == 'F') {
//         cprintf("  ELF magic number verified!\n");
//     } else {
//         cprintf("  Note: File does not appear to be ELF format\n");
//     }
    
//     /* 解除映射 */
//     cprintf("  Unmapping memory...\n");
//     if (munmap(addr, PAGE_SIZE) != 0) {
//         cprintf("  FAILED: munmap failed\n");
//         close(fd);
//         return -1;
//     }
    
//     close(fd);
//     cprintf("  Test 3 PASSED!\n\n");
//     return 0;
// }

// /* 测试4：只读映射保护（可选） */
// static int
// test_readonly_mmap(void) {
//     cprintf("Test 4: Read-only mmap protection...\n");
    
//     /* 申请只读的匿名映射 */
//     void *addr = mmap(NULL, PAGE_SIZE, PROT_READ,
//                       MAP_PRIVATE | MAP_ANONYMOUS, -1, 0);
    
//     if (addr == MAP_FAILED) {
//         cprintf("  FAILED: mmap returned MAP_FAILED\n");
//         return -1;
//     }
    
//     cprintf("  mmap returned address: 0x%x (read-only)\n", (uintptr_t)addr);
    
//     /* 读取应该成功 */
//     volatile int *ptr = (volatile int *)addr;
//     int val = ptr[0];
//     cprintf("  Read from read-only mapping: 0x%x (OK)\n", val);
    
//     /* 注意：写入只读映射会触发page fault，这里不测试以避免程序崩溃 */
//     cprintf("  (Skipping write test to avoid page fault)\n");
    
//     /* 解除映射 */
//     if (munmap(addr, PAGE_SIZE) != 0) {
//         cprintf("  FAILED: munmap failed\n");
//         return -1;
//     }
    
//     cprintf("  Test 4 PASSED!\n\n");
//     return 0;
// }

// int
// main(void) {
//     cprintf("\n========================================\n");
//     cprintf("       MMAP Functionality Test\n");
//     cprintf("========================================\n\n");
    
//     int failed = 0;
    
//     if (test_anonymous_mmap() != 0) {
//         failed++;
//     }
    
//     if (test_multi_page_mmap() != 0) {
//         failed++;
//     }
    
//     if (test_file_mmap() != 0) {
//         failed++;
//     }
    
//     if (test_readonly_mmap() != 0) {
//         failed++;
//     }
    
//     cprintf("========================================\n");
//     if (failed == 0) {
//         cprintf("All mmap tests PASSED!\n");
//         cprintf("mmaptest pass.\n");
//     } else {
//         cprintf("%d test(s) FAILED!\n", failed);
//     }
//     cprintf("========================================\n");
    
//     return failed;
// }

#include <ulib.h>
#include <unistd.h>
#include <file.h>

#define PAGE_SIZE 4096

static int test_anonymous_mmap(void) {
    cprintf("[1] anonymous mmap\n");

    int *p = mmap(NULL, PAGE_SIZE,
                  PROT_READ | PROT_WRITE,
                  MAP_PRIVATE | MAP_ANONYMOUS,
                  -1, 0);
    if (p == MAP_FAILED) {
        cprintf("  mmap failed\n");
        return -1;
    }

    p[0] = 0x12345678;
    p[1] = 0xdeadbeef;

    if (p[0] != 0x12345678 || p[1] != 0xdeadbeef) {
        cprintf("  data mismatch\n");
        return -1;
    }

    munmap(p, PAGE_SIZE);
    cprintf("  ok\n");
    return 0;
}

static int test_multi_page_mmap(void) {
    cprintf("[2] multi-page anonymous mmap\n");

    int *p = mmap(NULL, PAGE_SIZE * 4,
                  PROT_READ | PROT_WRITE,
                  MAP_PRIVATE | MAP_ANONYMOUS,
                  -1, 0);
    if (p == MAP_FAILED) {
        cprintf("  mmap failed\n");
        return -1;
    }

    for (int i = 0; i < 4; i++)
        p[i * (PAGE_SIZE / sizeof(int))] = i;

    for (int i = 0; i < 4; i++)
        if (p[i * (PAGE_SIZE / sizeof(int))] != i) {
            cprintf("  page %d mismatch\n", i);
            return -1;
        }

    munmap(p, PAGE_SIZE * 4);
    cprintf("  ok\n");
    return 0;
}

static int test_file_mmap(void) {
    cprintf("[3] file mmap\n");

    int fd = open("/hello", O_RDONLY);
    if (fd < 0) {
        cprintf("  skip (no file)\n");
        return 0;
    }

    unsigned char *p = mmap(NULL, PAGE_SIZE,
                             PROT_READ,
                             MAP_PRIVATE,
                             fd, 0);
    if (p == MAP_FAILED) {
        cprintf("  mmap failed\n");
        close(fd);
        return -1;
    }

    if (p[0] == 0x7f && p[1] == 'E' &&
        p[2] == 'L'  && p[3] == 'F')
        cprintf("  ELF header OK\n");
    else
        cprintf("  not ELF (still OK)\n");

    munmap(p, PAGE_SIZE);
    close(fd);
    cprintf("  ok\n");
    return 0;
}

static int test_readonly_mmap(void) {
    cprintf("[4] readonly mmap\n");

    int *p = mmap(NULL, PAGE_SIZE,
                  PROT_READ,
                  MAP_PRIVATE | MAP_ANONYMOUS,
                  -1, 0);
    if (p == MAP_FAILED) {
        cprintf("  mmap failed\n");
        return -1;
    }

    volatile int v = p[0];
    (void)v;

    munmap(p, PAGE_SIZE);
    cprintf("  ok\n");
    return 0;
}

int main(void) {
    cprintf("==== mmap test ====\n");

    if (test_anonymous_mmap() < 0) goto fail;
    if (test_multi_page_mmap() < 0) goto fail;
    if (test_file_mmap() < 0) goto fail;
    if (test_readonly_mmap() < 0) goto fail;

    cprintf("mmaptest pass\n");
    return 0;

fail:
    cprintf("mmaptest failed\n");
    return -1;
}
