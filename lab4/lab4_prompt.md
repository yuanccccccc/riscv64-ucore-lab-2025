id: LAB4-EX1
name: alloc_proc 基础字段初始化
functional_description: 在 `alloc_proc` 中初始化新分配的 `proc_struct`，让它处于“刚创建、尚未调度”的安全初始状态。
code_scope:
  target_file: "lab4_new/kern/process/proc.c"
  target_function: "alloc_proc"
  target_marker: "LAB4:EXERCISE1 YOUR CODE"
spec:
  功能:
    - "初始化新进程控制块的核心字段，供 `proc_init()` 自检与后续 `do_fork()` 使用。"
    - "将进程状态设为未初始化，pid 设为未分配，页目录基址指向内核页表。"
  接口:
    - "`memset(void *s, int c, size_t n)`: 用于把 `context` 和 `name` 清零。"
    - "`boot_pgdir_pa`: 来自 `pmm.h` 的全局页目录物理地址，作为进程初始 `pgdir`。"
  数据结构:
    - "`struct proc_struct.state = PROC_UNINIT`"
    - "`struct proc_struct.pid = -1`"
    - "`struct proc_struct.runs = 0`"
    - "`struct proc_struct.kstack = 0`"
    - "`struct proc_struct.need_resched = 0`"
    - "`struct proc_struct.parent = NULL`"
    - "`struct proc_struct.mm = NULL`"
    - "`struct context` 需要整体清零"
    - "`struct proc_struct.tf = NULL`"
    - "`struct proc_struct.pgdir = boot_pgdir_pa`"
    - "`struct proc_struct.flags = 0`"
    - "`struct proc_struct.name` 需要清零"
  依赖:
    - "被 `proc_init()` 中的 `alloc_proc() correct!` 条件直接校验。"
    - "被 `do_fork()` 依赖为子进程的初始空白状态。"
  unsafe_boundary:
    - "`proc` 来自 `kmalloc`，内容默认未初始化。"
    - "不要解引用 `proc->tf`。"
    - "不要修改题目未要求的 `list_link/hash_link` 等字段。"
  实现约束:
    - "只补全标记位置，不新增函数，不改其他代码。"
    - "使用已有类型和宏，不要自造常量。"
    - "输出必须是可直接粘贴到注释位置的纯 C 代码片段。"
scenarios:
  - name: "正常初始化"
    expectation: "新建 `proc` 满足 `proc_init()` 中对 `state/pid/runs/kstack/need_resched/parent/mm/context/tf/pgdir/flags/name` 的检查。"
prompt: |
  你正在补全 uCore 教学实验代码。请只补全 `lab4_new/kern/process/proc.c` 中 `alloc_proc` 函数内 `LAB4:EXERCISE1 YOUR CODE` 标记处的代码。

  目标：
  初始化新分配的 `struct proc_struct`，让它处于安全初始状态，并满足 `proc_init()` 中的自检逻辑。

  必须完成的字段初始化：
  - `state = PROC_UNINIT`
  - `pid = -1`
  - `runs = 0`
  - `kstack = 0`
  - `need_resched = 0`
  - `parent = NULL`
  - `mm = NULL`
  - `context` 整体清零
  - `tf = NULL`
  - `pgdir = boot_pgdir_pa`
  - `flags = 0`
  - `name` 清零

  限制：
  - 只输出要插入该位置的 C 代码片段。
  - 不要输出解释、不要输出 Markdown、不要重复函数签名。
  - 不要修改 `list_link`、`hash_link` 等题面未要求字段。
  - 使用现有接口：`memset`、`boot_pgdir_pa`。


id: LAB4-EX2
name: do_fork 创建内核线程/进程
functional_description: 在 `do_fork` 中完成子进程控制块创建、内核栈建立、上下文复制、pid 分配、链表挂接和唤醒。
code_scope:
  target_file: "lab4_new/kern/process/proc.c"
  target_function: "do_fork"
  target_marker: "LAB4:EXERCISE2 YOUR CODE"
spec:
  功能:
    - "创建一个新的 `proc_struct` 作为子进程。"
    - "为子进程分配内核栈，复制/共享内存管理信息，构造 trapframe 和切换上下文。"
    - "为子进程分配唯一 pid，并将其加入进程哈希表和进程链表。"
    - "把子进程唤醒为 `PROC_RUNNABLE`，最后返回子进程 pid。"
  接口:
    - "`alloc_proc(void) -> struct proc_struct *`: 分配并初始化空白进程控制块。"
    - "`setup_kstack(struct proc_struct *proc) -> int`: 为子进程分配内核栈，成功返回 0，失败返回 `-E_NO_MEM`。"
    - "`copy_mm(uint32_t clone_flags, struct proc_struct *proc) -> int`: 根据 `clone_flags` 决定共享或复制地址空间；本实验中当前实现可直接调用。"
    - "`copy_thread(struct proc_struct *proc, uintptr_t esp, struct trapframe *tf)`: 在子进程内核栈顶建立 trapframe，并设置切换上下文。"
    - "`get_pid(void) -> int`: 返回唯一 pid。"
    - "`wakeup_proc(struct proc_struct *proc)`: 将进程置为 `PROC_RUNNABLE`。"
    - "`list_add(list_entry_t *listelm, list_entry_t *elm)`: 把节点插入链表。"
    - "`put_kstack(struct proc_struct *proc)`: 释放子进程内核栈。"
    - "`kfree(void *objp)`: 释放 `proc_struct`。"
  数据结构:
    - "`proc->pid` 在加入链表前必须先设置好。"
    - "`proc->hash_link` 挂入 `hash_list + pid_hashfn(pid)`。"
    - "`proc->list_link` 挂入全局 `proc_list`。"
    - "`nr_process` 成功创建后要加 1。"
    - "入参 `stack` 和 `tf` 直接传给 `copy_thread`。"
  依赖:
    - "依赖练习一的 `alloc_proc()` 已正确初始化字段。"
    - "依赖 `copy_thread()` 已封装好子进程首次运行所需的 `ra/sp/tf`。"
    - "被 `find_proc()`、调度器和 `kernel_thread()` 依赖。"
  unsafe_boundary:
    - "`alloc_proc()` 失败后不能继续访问 `proc`。"
    - "`setup_kstack()` 失败后只能走已有清理路径。"
    - "子进程在 `pid`、链表挂接和 `wakeup_proc()` 顺序上不能乱。"
    - "不要在本题额外增加锁、中断控制或无关字段修改。"
  实现约束:
    - "保留已有 `fork_out`、`bad_fork_cleanup_kstack`、`bad_fork_cleanup_proc` 标签和清理结构。"
    - "只补全标记位置，不新增函数，不改其他逻辑。"
    - "输出必须是可直接粘贴到注释位置的纯 C 代码片段。"
scenarios:
  - name: "成功创建"
    expectation: "返回子进程 pid；子进程已拥有内核栈、trapframe、context、唯一 pid，并已进入 `PROC_RUNNABLE`。"
  - name: "alloc_proc 失败"
    expectation: "直接走 `fork_out`，返回当前 `ret`。"
  - name: "setup_kstack 失败"
    expectation: "跳转到 `bad_fork_cleanup_proc`，释放 `proc_struct` 后返回。"
prompt: |
  你正在补全 uCore 教学实验代码。请只补全 `lab4_new/kern/process/proc.c` 中 `do_fork` 函数内 `LAB4:EXERCISE2 YOUR CODE` 标记处的代码。

  目标：
  完成子进程创建流程，包括：
  1. 调用 `alloc_proc()` 分配子进程控制块，失败则直接退出。
  2. 调用 `setup_kstack(proc)` 分配内核栈；若返回 `-E_NO_MEM`，跳转到现有清理标签。
  3. 调用 `copy_mm(clone_flags, proc)`。
  4. 调用 `copy_thread(proc, stack, tf)`。
  5. 通过 `get_pid()` 获取唯一 pid，写入 `proc->pid`。
  6. 将子进程插入 pid 哈希链表和全局进程链表。
  7. `nr_process++`。
  8. 调用 `wakeup_proc(proc)`。
  9. 将返回值设为子进程 pid。

  约束：
  - 只输出要插入该位置的 C 代码片段。
  - 不要输出解释、不要输出 Markdown、不要重复函数签名。
  - 不要额外添加锁、中断屏蔽、`parent` 赋值或其他题目未要求逻辑。
  - 使用当前文件中已经存在的符号和标签：`hash_list`、`pid_hashfn`、`proc_list`、`fork_out`、`bad_fork_cleanup_proc`。


id: LAB4-EX3
name: proc_run 上下文切换
functional_description: 在 `proc_run` 中切换当前运行进程，关闭中断、更新 `current`、切换页表并执行上下文切换。
code_scope:
  target_file: "lab4_new/kern/process/proc.c"
  target_function: "proc_run"
  target_marker: "LAB4:EXERCISE3 YOUR CODE"
spec:
  功能:
    - "当目标进程 `proc` 不是当前进程时，完成一次安全的内核进程切换。"
    - "在切换关键区间关闭中断，避免切换过程中被打断。"
    - "切换 `current`、加载目标页表基址、再调用 `switch_to` 切换寄存器上下文。"
  接口:
    - "`local_intr_save(bool flag)`: 保存当前中断状态，并在需要时关闭中断。"
    - "`local_intr_restore(bool flag)`: 恢复之前保存的中断状态。"
    - "`lsatp(unsigned int pgdir)`: 将页目录物理地址写入 `satp`。"
    - "`switch_to(struct context *from, struct context *to)`: 保存旧上下文并恢复新上下文。"
  数据结构:
    - "`current`: 全局当前进程指针。"
    - "`proc->pgdir`: 目标进程页表基址。"
    - "`prev->context` / `next->context`: 切换前后上下文。"
  依赖:
    - "由 `schedule()` 调用；`schedule()` 已在外层挑选出 `next` 并增加了 `next->runs`。"
    - "依赖 `copy_thread()` 事先准备好的 `context.ra/context.sp`。"
  unsafe_boundary:
    - "更新 `current` 与调用 `switch_to` 之间不能被中断打断。"
    - "不能直接写汇编改寄存器，必须使用 `lsatp` 和 `switch_to`。"
    - "不要在这里修改 `runs`、`state`、`need_resched`。"
  实现约束:
    - "只在 `if (proc != current)` 分支内补全代码。"
    - "先保存 `prev=current` 和 `next=proc`，再做中断保护和切换。"
    - "输出必须是可直接粘贴到注释位置的纯 C 代码片段。"
scenarios:
  - name: "切换到新进程"
    expectation: "关闭中断后完成 `current` 更新、页表切换和上下文切换，返回后恢复中断。"
  - name: "目标就是当前进程"
    expectation: "不进入补全逻辑，保持现状。"
prompt: |
  你正在补全 uCore 教学实验代码。请只补全 `lab4_new/kern/process/proc.c` 中 `proc_run` 函数内 `LAB4:EXERCISE3 YOUR CODE` 标记处的代码。

  目标：
  在 `proc != current` 时完成一次进程切换。实现顺序必须是：
  1. 定义中断状态变量 `intr_flag`。
  2. 保存 `prev = current`，`next = proc`。
  3. 使用 `local_intr_save(intr_flag)` 进入关键区。
  4. 更新全局 `current` 为目标进程。
  5. 调用 `lsatp(next->pgdir)` 切换页表。
  6. 调用 `switch_to(&(prev->context), &(next->context))` 完成上下文切换。
  7. 使用 `local_intr_restore(intr_flag)` 恢复中断状态。

  约束：
  - 只输出要插入该位置的 C 代码片段。
  - 不要输出解释、不要输出 Markdown、不要重复函数签名。
  - 不要手写汇编，不要直接操作 `sp`，不要修改 `runs/state/need_resched`。
  - 只使用已有接口：`local_intr_save`、`local_intr_restore`、`lsatp`、`switch_to`。