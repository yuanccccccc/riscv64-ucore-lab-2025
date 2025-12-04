### 第一次进入用户态

前面我们提到过，我们要通过 `kernel_execve` 来启动第一个用户进程，进入用户态，那么应该怎么实现 `kernel_execve` 函数呢，我们先来看看 `do_execve()` 函数

```c
// kern/process/proc.c
// do_execve - call exit_mmap(mm)&put_pgdir(mm) to reclaim memory space of current process
//           - call load_icode to setup new memory space accroding binary prog.
int do_execve(const char *name, size_t len, unsigned char *binary, size_t size) {
    struct mm_struct *mm = current->mm;
    if (!user_mem_check(mm, (uintptr_t)name, len, 0)) { //检查name的内存空间能否被访问
        return -E_INVAL;
    }
    if (len > PROC_NAME_LEN) { //进程名字的长度有上限 PROC_NAME_LEN，在proc.h定义
        len = PROC_NAME_LEN;
    }
    char local_name[PROC_NAME_LEN + 1];
    memset(local_name, 0, sizeof(local_name));
    memcpy(local_name, name, len);

    if (mm != NULL) {
        cputs("mm != NULL");
        lcr3(boot_cr3);
        if (mm_count_dec(mm) == 0) {
            exit_mmap(mm);
            put_pgdir(mm);
            mm_destroy(mm);//把进程当前占用的内存释放，之后重新分配内存
        }
        current->mm = NULL;
    }
    //把新的程序加载到当前进程里的工作都在load_icode()函数里完成
    int ret;
    if ((ret = load_icode(binary, size)) != 0) {
        goto execve_exit;//返回不为0，则加载失败
    }
    set_proc_name(current, local_name);
    //如果set_proc_name的实现不变, 为什么不能直接set_proc_name(current, name)?
    return 0;

execve_exit:
    do_exit(ret);
    panic("already exit: %e.\n", ret);
}
```

那么我们如何实现 `kernel_execve()` 函数？能否直接调用 `do_execve()`?

```c
static int kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
    ret = do_execve(name, len, binary, size);
    cprintf("ret = %d\n", ret);
    return ret;
}
```

很不幸。这么做行不通。`do_execve()` `load_icode()` 里面只是构建了用户程序运行的上下文，但是并没有完成切换。上下文切换实际上要借助中断处理的返回来完成。直接调用 `do_execve()` 是无法完成上下文切换的。如果是在用户态调用 `exec()`, 系统调用的 `ecall` 产生的中断返回时， 就可以完成上下文切换。

但是，目前我们在 `S mode` 下，所以不能通过 `ecall` 来产生中断。我们这里采取一个取巧的办法，用 `ebreak` 产生断点中断进行处理，通过设置 `a7` 寄存器的值为10说明这不是一个普通的断点中断，而是要转发到 `syscall()`, 这样用一个不是特别优雅的方式，实现了在内核态复用系统调用的接口。

```c
// kern/process/proc.c
// kernel_execve - do SYS_exec syscall to exec a user program called by user_main kernel_thread
static int kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
    asm volatile(
        "li a0, %1\n"
        "lw a1, %2\n"
        "lw a2, %3\n"
        "lw a3, %4\n"
        "lw a4, %5\n"
        "li a7, 10\n"
        "ebreak\n"
        "sw a0, %0\n"
        : "=m"(ret)
        : "i"(SYS_exec), "m"(name), "m"(len), "m"(binary), "m"(size)
        : "memory"); //这里内联汇编的格式，和用户态调用ecall的格式类似，只是ecall换成了ebreak
    cprintf("ret = %d\n", ret);
    return ret;
}
// kern/trap/trap.c
void exception_handler(struct trapframe *tf) {
    int ret;
    switch (tf->cause) {
        case CAUSE_BREAKPOINT:
            cprintf("Breakpoint\n");
            if(tf->gpr.a7 == 10){
                tf->epc += 4; //注意返回时要执行ebreak的下一条指令
                syscall();
            }
            break;
  		/* other cases ... */
    }
}
```

注意我们需要让 `CPU` 进入 `U mode` 执行 `do_execve()` 加载的用户程序。进行系统调用 `sys_exec` 之后，我们在 `trap` 返回的时候调用了 `sret` 指令，这时只要 `sstatus` 寄存器的 `SPP` 二进制位为0，就会切换到 `U mode`，但 `SPP` 存储的是“进入 `trap` 之前来自什么特权级”，也就是说我们这里 `ebreak` 之后 `SPP` 的数值为1，`sret` 之后会回到 `S mode` 在内核态执行用户程序。所以 `load_icode()` 函数在构造新进程的时候，会把 `SSTATUS_SPP` 设置为0，使得 `sret` 的时候能回到 `U mode`。