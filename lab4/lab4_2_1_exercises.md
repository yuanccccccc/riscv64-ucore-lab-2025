### 练习

本实验按“虚存管理 -> 进程创建 -> 调度切换”的顺序展开。对应的主调用链可以概括为：

`kern_init -> pmm_init -> pic_init/idt_init -> vmm_init -> proc_init -> cpu_idle -> schedule -> proc_run -> switch_to`

前半部分把物理内存和页表机制准备好，后半部分把第一个内核线程创建出来，并通过调度器让它真正运行起来。

#### 练习1：维护页表映射（需要编码）

这一部分要把虚拟内存中最基础的两类操作补齐：建立映射和撤销映射。对应的核心函数是 `page_insert` 和 `page_remove_pte`，它们位于 `kern/mm/pmm.c` 中，都会依赖 `get_pte()` 定位目标页表项。

`page_insert` 负责把某个物理页映射到指定线性地址，并写入权限位；`page_remove_pte` 负责撤销已有映射，同时维护物理页引用计数。实现时要特别注意页表项、引用计数和 TLB 刷新三者必须保持一致，否则很容易出现旧映射残留或者引用计数错误。因为 `get_pte(pgdir, la, 1)` 可能需要顺带创建中间级页表，所以调用方不能假定页表项一定已经存在。

#### 练习2：初始化进程控制块并创建第一个内核线程（需要编码）

这一部分把进程管理的底座搭起来。`alloc_proc` 负责分配并初始化一个新的 `struct proc_struct`，让它处于“刚创建、尚未运行”的安全状态；`proc_init` 负责建立 `idleproc`，再借助 `kernel_thread()` 创建 `initproc`；`do_fork` 则负责把一个新内核线程真正挂入系统。它们共同完成从 PCB 初始化、内核栈分配，到中断帧和上下文准备、PID 分配、链表挂接以及唤醒的整套流程。

这部分最容易遗漏的是几个基础字段和资源关联关系：`alloc_proc` 里要把状态、PID、运行次数、内核栈指针、调度标记、父进程指针、内存管理指针、`context`、`tf`、`pgdir`、`flags` 和名字都初始化好；`do_fork` 里则要保证内核栈、`copy_mm()`、`copy_thread()`、`pid`、`hash_list`、`proc_list`、`nr_process` 和 `wakeup_proc()` 的配合正确。`copy_mm()` 在本实验里仍然只承担内核线程场景下的过渡职责，不涉及用户地址空间的真正复制。

#### 练习3：实现调度与切换（需要编码）

这一部分让前面创建好的线程真正运行起来。`cpu_idle()` 在发现 `current->need_resched` 置位后会进入 `schedule()`；`schedule()` 负责从 `proc_list` 中按 FIFO 方式挑选一个可运行线程，并调用 `proc_run()` 完成切换；`proc_run()` 则负责在安全的临界区内更新 `current`、切换页表，再通过 `switch_to()` 完成上下文切换。

这里最需要注意的是切换过程的原子性。`proc_run()` 中必须先屏蔽中断，再更新当前进程指针并切换地址空间，最后恢复中断；`schedule()` 则需要确保被选中的线程状态确实是 `PROC_RUNNABLE`，并在找不到其他可运行线程时回退到 `idleproc`。`switch_to()` 已经在 `switch.S` 中实现好，它只负责保存和恢复必要的寄存器上下文。

完成代码编写后，编译并运行代码：`make qemu`

#### 扩展练习 Challenge

1. 说明语句 `local_intr_save(intr_flag); ... local_intr_restore(intr_flag);` 是如何实现开关中断的。
2. 深入理解不同分页模式的工作原理（思考题）。

`get_pte()` 函数位于 `kern/mm/pmm.c`，用于在页表中查找或创建页表项，从而实现对指定线性地址对应的物理页的访问和映射操作。这在操作系统的分页机制下，是虚拟内存与物理内存建立映射关系的关键基础。

- `get_pte()` 函数中有两段形式类似的代码，结合 `sv32`、`sv39`、`sv48` 的异同，解释这两段代码为什么如此相像。
- 目前 `get_pte()` 函数将页表项查找和页表页分配合并在一个函数里，你认为这种写法好吗？有没有必要把两个功能拆开？
