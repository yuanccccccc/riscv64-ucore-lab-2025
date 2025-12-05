### 系统调用实现

系统调用，是用户态(U mode)的程序获取内核态（S mode）服务的方法，所以需要在用户态和内核态都加入对应的支持和处理。我们也可以认为用户态只是提供一个调用的接口，真正的处理都在内核态进行。

> **须知**
>
>在用户进程管理中，有几个关键的系统调用尤为重要：
>- `sys_fork()` 用于创建当前进程的副本，生成子进程。父子进程都会从 `sys_fork()` 返回，但返回值不同：子进程得到0，父进程得到子进程的 `PID`，这使得两个进程可以执行不同的代码路径。
>- `sys_exec()` 在当前进程内启动一个新程序，保持 `PID` 不变但替换整个内存空间和执行代码。`fork()` 和 `exec()` 的组合是 `Unix-like` 系统中创建新进程的经典方式。
>- `sys_exit()` 用于终止当前进程，释放其占用的资源。
>- `sys_wait()` 使当前进程挂起，等待特定条件（如子进程退出）满足后再继续执行。


首先我们在头文件里定义一些系统调用的编号。

```c
// libs/unistd.h
/* syscall number */
#define SYS_exit            1
#define SYS_fork            2
#define SYS_wait            3
#define SYS_exec            4
#define SYS_clone           5
#define SYS_yield           10
#define SYS_sleep           11
#define SYS_kill            12
#define SYS_gettime         17
#define SYS_getpid          18
#define SYS_brk             19
#define SYS_mmap            20
#define SYS_munmap          21
#define SYS_shmem           22
#define SYS_putc            30
#define SYS_pgdir           31
```

我们注意在用户态进行系统调用的核心操作是，通过内联汇编进行 `ecall` 环境调用。这将产生一个 `trap`, 进入 `S mode` 进行异常处理。

```c
// user/libs/syscall.c
#include <defs.h>
#include <unistd.h>
#include <stdarg.h>
#include <syscall.h>
#define MAX_ARGS            5
static inline int syscall(int num, ...) {
    //va_list, va_start, va_arg都是C语言处理参数个数不定的函数的宏
    //在stdarg.h里定义
    va_list ap; //ap: 参数列表(此时未初始化)
    va_start(ap, num); //初始化参数列表, 从num开始
    //First, va_start initializes the list of variable arguments as a va_list.
    uint64_t a[MAX_ARGS];
    int i, ret;
    for (i = 0; i < MAX_ARGS; i ++) { //把参数依次取出
	   	/*Subsequent executions of va_arg yield the values of the additional arguments 
   		in the same order as passed to the function.*/
        a[i] = va_arg(ap, uint64_t);
    }
    va_end(ap); //Finally, va_end shall be executed before the function returns.
    asm volatile (
        "ld a0, %1\n"
        "ld a1, %2\n"
        "ld a2, %3\n"
        "ld a3, %4\n"
        "ld a4, %5\n"
        "ld a5, %6\n"
        "ecall\n"
        "sd a0, %0"
        : "=m" (ret)
        : "m"(num), "m"(a[0]), "m"(a[1]), "m"(a[2]), "m"(a[3]), "m"(a[4])
        :"memory");
    //num存到a0寄存器， a[0]存到a1寄存器
    //ecall的返回值存到ret
    return ret;
}
int sys_exit(int error_code) { return syscall(SYS_exit, error_code); }
int sys_fork(void) { return syscall(SYS_fork); }
int sys_wait(int pid, int *store) { return syscall(SYS_wait, pid, store); }
int sys_yield(void) { return syscall(SYS_yield);}
int sys_kill(int pid) { return syscall(SYS_kill, pid); }
int sys_getpid(void) { return syscall(SYS_getpid); }
int sys_putc(int c) { return syscall(SYS_putc, c); }
```

我们下面看看 `trap.c` 是如何转发这个系统调用的。

```c
// kern/trap/trap.c
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) { //通过中断帧里 scause寄存器的数值，判断出当前是来自USER_ECALL的异常
        case CAUSE_USER_ECALL:
            //cprintf("Environment call from U-mode\n");
            tf->epc += 4; 
            //sepc寄存器是产生异常的指令的位置，在异常处理结束后，会回到sepc的位置继续执行
            //对于ecall, 我们希望sepc寄存器要指向产生异常的指令(ecall)的下一条指令
            //否则就会回到ecall执行再执行一次ecall, 无限循环
            syscall();// 进行系统调用处理
            break;
        /*other cases .... */
    }
}
// kern/syscall/syscall.c
#include <unistd.h>
#include <proc.h>
#include <syscall.h>
#include <trap.h>
#include <stdio.h>
#include <pmm.h>
#include <assert.h>
//这里把系统调用进一步转发给proc.c的do_exit(), do_fork()等函数
static int sys_exit(uint64_t arg[]) {
    int error_code = (int)arg[0];
    return do_exit(error_code);
}
static int sys_fork(uint64_t arg[]) {
    struct trapframe *tf = current->tf;
    uintptr_t stack = tf->gpr.sp;
    return do_fork(0, stack, tf);
}
static int sys_wait(uint64_t arg[]) {
    int pid = (int)arg[0];
    int *store = (int *)arg[1];
    return do_wait(pid, store);
}
static int sys_exec(uint64_t arg[]) {
    const char *name = (const char *)arg[0];
    size_t len = (size_t)arg[1];
    unsigned char *binary = (unsigned char *)arg[2];
    size_t size = (size_t)arg[3];
    //用户态调用的exec(), 归根结底是do_execve()
    return do_execve(name, len, binary, size);
}
static int sys_yield(uint64_t arg[]) {
    return do_yield();
}
static int sys_kill(uint64_t arg[]) {
    int pid = (int)arg[0];
    return do_kill(pid);
}
static int sys_getpid(uint64_t arg[]) {
    return current->pid;
}
static int sys_putc(uint64_t arg[]) {
    int c = (int)arg[0];
    cputchar(c);
    return 0;
}
//这里定义了函数指针的数组syscalls, 把每个系统调用编号的下标上初始化为对应的函数指针
static int (*syscalls[])(uint64_t arg[]) = {
    [SYS_exit]              sys_exit,
    [SYS_fork]              sys_fork,
    [SYS_wait]              sys_wait,
    [SYS_exec]              sys_exec,
    [SYS_yield]             sys_yield,
    [SYS_kill]              sys_kill,
    [SYS_getpid]            sys_getpid,
    [SYS_putc]              sys_putc,
};

#define NUM_SYSCALLS        ((sizeof(syscalls)) / (sizeof(syscalls[0])))

void syscall(void) {
    struct trapframe *tf = current->tf;
    uint64_t arg[5];
    int num = tf->gpr.a0;//a0寄存器保存了系统调用编号
    if (num >= 0 && num < NUM_SYSCALLS) {//防止syscalls[num]下标越界
        if (syscalls[num] != NULL) {
            arg[0] = tf->gpr.a1;
            arg[1] = tf->gpr.a2;
            arg[2] = tf->gpr.a3;
            arg[3] = tf->gpr.a4;
            arg[4] = tf->gpr.a5;
            tf->gpr.a0 = syscalls[num](arg); 
            //把寄存器里的参数取出来，转发给系统调用编号对应的函数进行处理
            return ;
        }
    }
    //如果执行到这里，说明传入的系统调用编号还没有被实现，就崩掉了。
    print_trapframe(tf);
    panic("undefined syscall %d, pid = %d, name = %s.\n",
            num, current->pid, current->name);
}
```

这样我们就完成了系统调用的转发。接下来就是在 `do_exit()`, `do_execve()` 等函数中进行具体处理了。