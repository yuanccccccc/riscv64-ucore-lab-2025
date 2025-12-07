### 第一次进入用户态

前面我们提到过，我们要通过 `kernel_execve` 来启动第一个用户进程，进入用户态，那么应该怎么实现 `kernel_execve` 函数呢，我们先来看看 `do_execve()` 函数。

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

那么我们如何实现 `kernel_execve()` 函数？能否直接调用 `do_execve()`？

```c
static int kernel_execve(const char *name, unsigned char *binary, size_t size) {
    int64_t ret=0, len = strlen(name);
    ret = do_execve(name, len, binary, size);
    cprintf("ret = %d\n", ret);
    return ret;
}
```

很不幸。这么做行不通。如果在内核中直接调用 `do_execve()`，整个执行仍然停留在 S 态，因为 `do_execve()` 只是准备好上下文，却没有让 CPU 使用它。系统中的用户态切换是通过中断处理的返回路径实现的，也就是说，只有通过某种 trap-return 机制（最终执行到 `sret`）才能离开内核态。对于正常的用户态 `exec()` 调用，这一步是由系统调用的中断返回自动完成的；但是在当前场景中，我们是在内核线程的上下文里启动用户程序，并没有触发任何异常或系统调用。

目前我们在 `S mode` 下，所以不能通过 `ecall` 来产生中断。因此，其中一种取巧的手段是，人为产生一次`ebreak`异常，再在异常处理里进行一次 `syscall`，从而复用系统调用的`trap`返回路径。这样用一个不是特别优雅的方式，可以实现在内核态复用系统调用的接口（有兴趣的同学可以自己编写代码实现这种方法）。

另一种更直接、清晰的方法是手动构造新的`trapframe`，将它放置在当前进程的内核栈顶，然后主动切换到这个`trapframe`，并跳转到`__trapret`。这样可以立即进入通用的中断返回路径，按照`trapframe`中指定的内容恢复寄存器，并最终执行`sret`，顺利从内核态切换到用户态。`kernel_execve()`实现如下：

```c
// kern/process/proc.c
// kernel_execve - build a new trapframe, execute do_execve in-kernel, and return to user mode via __trapret
static int 
kernel_execve(const char *name, unsigned char *binary, size_t size)
{
    int ret;
    size_t len = strlen(name);
    struct trapframe *old_tf = current->tf;
    struct trapframe *new_tf = (struct trapframe *)(current->kstack + KSTACKSIZE - sizeof(struct trapframe));
    memcpy(new_tf, old_tf, sizeof(struct trapframe));
    current->tf = new_tf;
    ret = do_execve(name, len, binary, size);
    asm volatile(
        "mv sp, %0\n"    // sp 指向新的 trapframe
        "j __trapret\n"  // 恢复寄存器 + sret 返回用户态
        :
        : "r"(new_tf)
        : "memory"
    );
    return ret;
}
```

在这个过程中，`load_icode()` 在加载用户程序时已经把 `trapframe` 中的 `sepc` 设置为用户程序的入口地址，将用户栈指针设为新地址空间中的用户栈顶，并且清除了 `sstatus` 的 `SPP` 位，使其为 0。`SPP` 记录的是“进入中断之前所在的特权级”，而 `sret` 会根据它决定返回时 `CPU` 的特权级别。由于我们希望返回到用户态运行用户程序，因此必须确保这一位被清零。

当 `kernel_execve()` 跳转到 `__trapret` 时，系统会按照 `trapframe` 恢复寄存器状态，并最终执行 `sret`。因为 `trapframe` 中的 `SPP` 已为 0，`sret` 的效果是将 CPU 从 S 模式切换到 U 模式，并从用户程序的入口地址开始执行指令。至此，系统第一次成功进入用户态，正式开始运行我们加载的第一个用户程序。