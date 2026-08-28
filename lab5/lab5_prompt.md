# 实验五提示词整理

本文档基于最新版 [lab5.md](/E:/Desktop/aios/lab5_answer/lab5.md:1) 整理，只保留“需要编码”的练习提示词。

适用范围：

- 练习0：不单独生成提示词。它要求补齐 Lab2/Lab3/Lab4 既有代码，不是本实验新增的单点代码生成任务。
- 练习1：需要编码，生成提示词。
- 练习2：需要编码，生成提示词。
- 练习3：不需要编码，不生成提示词。

使用方式：

- 每次只选择一个练习对应的提示词。
- 将该提示词与 `lab5_new` 目录下的代码一并提供给大模型。
- 要求大模型只补全对应注释标记处的代码，不修改其他逻辑。

## 练习1

```yaml
id: LAB5-REQ-1
name: 加载应用程序并设置用户态执行现场
functional_description: 在 `load_icode` 中完成用户态进程返回现场的设置，使内核在完成 ELF 装载后，可以从用户程序入口地址开始执行第一条用户态指令。
source_scope:
  target_file: "lab5_new/kern/process/proc.c"
  target_function: "load_icode"
  target_marker: "LAB5:EXERCISE1 YOUR CODE"
spec:
  功能:
    - "在 ELF 代码段、数据段、BSS 和用户栈已经映射完成后，初始化当前进程的 trapframe 中与用户态启动相关的关键字段。"
    - "保证 trap 返回后 CPU 进入用户态，而不是继续留在内核态。"
    - "保证用户态栈指针指向用户栈顶，程序计数器指向 ELF 入口地址。"
  接口:
    - name: "USTACKTOP"
      signature: "宏常量"
      description: "用户栈顶虚拟地址，应赋给 `tf->gpr.sp`。"
    - name: "elf->e_entry"
      signature: "ELF 头字段"
      description: "用户程序入口地址，应赋给 `tf->epc`。"
    - name: "SSTATUS_SPP"
      signature: "宏常量"
      description: "S 态返回前的特权级位。若该位为 1，则返回 Supervisor 模式；为了返回用户态，应将该位清零。"
    - name: "SSTATUS_SPIE"
      signature: "宏常量"
      description: "异常返回相关的中断使能位。本实验答案要求将其清零。"
    - name: "memset"
      signature: "void *memset(void *s, int c, size_t n)"
      description: "在进入待补全代码前已经用于清空 trapframe，本题不需要再次调用。"
  数据结构:
    - "`struct trapframe *tf`：当前进程即将通过 `__trapret` 恢复的中断现场。"
    - "`tf->gpr.sp`：用户态栈指针。"
    - "`tf->epc`：异常返回后的 PC，即用户程序第一条指令地址。"
    - "`tf->status`：异常返回后的 sstatus。"
    - "`uintptr_t sstatus`：在清空 trapframe 前保存的旧状态寄存器值，应基于它构造新的 `tf->status`。"
    - "`struct elfhdr *elf`：当前装载的 ELF 文件头。"
  依赖:
    - "依赖本函数前面已经完成 `mm_create`、`setup_pgdir`、`mm_map`、程序段拷贝、BSS 清零、用户栈页建立、`current->mm/current->pgdir/lsatp` 设置。"
    - "被 `do_execve`、`kernel_execve`、`__trapret`、用户态 `umain/main` 的启动路径依赖。"
  unsafe_boundary:
    - "若 `tf->status` 设置错误，CPU 可能返回到内核态或以错误状态运行。"
    - "若 `tf->gpr.sp` 不是用户栈顶，用户程序一启动就可能访问非法栈地址。"
    - "若 `tf->epc` 不是 `elf->e_entry`，将无法从正确入口执行程序。"
    - "不能直接写死 `tf->status` 为某个常量，应在原 `sstatus` 基础上只清除必要位。"
  实现约束:
    - "只补全 `LAB5:EXERCISE1 YOUR CODE` 标记处。"
    - "只输出可直接插入该位置的 C 代码片段。"
    - "不要新增函数、不要修改前后逻辑、不要输出解释。"
scenarios:
  - name: 正常装载用户程序
    expectation: "trap 返回后，用户程序从 `elf->e_entry` 开始执行，用户栈顶为 `USTACKTOP`。"
  - name: 正常模式切换
    expectation: "`tf->status` 清除了 `SSTATUS_SPP` 和 `SSTATUS_SPIE`，可从内核态正确返回用户态。"
prompt: |
  你正在补全 uCore Lab5 代码。请只补全 `lab5_new/kern/process/proc.c` 中 `load_icode` 函数内 `LAB5:EXERCISE1 YOUR CODE` 标记处的代码。

  任务目标：
  当前函数已经完成了 ELF 装载、用户栈映射、页表切换，现在需要设置当前进程的 trapframe，使其在 trap 返回后从用户态开始执行用户程序。

  必须完成的行为：
  - 将 `tf->gpr.sp` 设置为 `USTACKTOP`
  - 将 `tf->epc` 设置为 `elf->e_entry`
  - 将 `tf->status` 设置为基于已有 `sstatus` 的结果，并清除 `SSTATUS_SPP | SSTATUS_SPIE`

  关键约束：
  - 只输出插入该位置的 C 代码片段
  - 不要输出解释、不要输出 Markdown、不要重复函数签名
  - 不要修改其他字段
  - 不要引入新的辅助函数
```

## 练习2

```yaml
id: LAB5-REQ-2
name: 复制父进程用户内存页到子进程
functional_description: 在 `copy_range` 中实现逐页复制，将父进程地址空间中的有效用户页复制到子进程新分配的物理页，并建立相应映射。
source_scope:
  target_file: "lab5_new/kern/mm/pmm.c"
  target_function: "copy_range"
  target_marker: "LAB5:EXERCISE2 YOUR CODE"
spec:
  功能:
    - "当父进程页表在某个用户线性地址 `start` 上存在有效页时，为子进程的新页 `npage` 复制整页内容。"
    - "在子进程页表 `to` 中建立 `start -> npage` 的映射。"
    - "保持原页权限 `perm`。"
  接口:
    - name: "page2kva"
      signature: "void *page2kva(struct Page *page)"
      description: "将页描述符转换为该物理页在内核中的可访问虚拟地址。"
    - name: "memcpy"
      signature: "void *memcpy(void *dst, const void *src, size_t n)"
      description: "按字节复制整页数据，本题复制大小为 `PGSIZE`。"
    - name: "page_insert"
      signature: "int page_insert(pde_t *pgdir, struct Page *page, uintptr_t la, uint32_t perm)"
      description: "在页表 `pgdir` 中建立线性地址 `la` 到物理页 `page` 的映射，并设置权限 `perm`。"
  数据结构:
    - "`pte_t *ptep`：父进程页表项指针。"
    - "`struct Page *page`：父进程当前线性地址对应的物理页。"
    - "`struct Page *npage`：已为子进程分配的新物理页。"
    - "`uint32_t perm`：从父页表项中提取出的权限位。"
    - "`int ret`：记录 `page_insert` 返回值。"
  依赖:
    - "依赖本函数前面已经通过 `get_pte(to, start, 1)` 确保目标页表项所在页表存在。"
    - "依赖本函数前面已经通过 `alloc_page()` 成功分配 `npage`。"
    - "被 `dup_mmap` 调用，被 `copy_mm` 和 `do_fork` 间接依赖。"
  unsafe_boundary:
    - "不能直接把父页 `page` 映射给子进程，否则不是本实验要求的深拷贝。"
    - "不能漏掉 `page_insert`，否则子进程页表不会指向新页。"
    - "不要手工修改页引用计数，`page_insert` 会处理映射带来的引用。"
    - "源地址和目标地址都必须使用 `page2kva` 获取，不能直接把 `struct Page *` 当地址使用。"
  实现约束:
    - "只补全 `LAB5:EXERCISE2 YOUR CODE` 标记处。"
    - "只输出可直接插入该位置的 C 代码片段。"
    - "保持后续 `assert(ret == 0);` 语义成立。"
scenarios:
  - name: 复制普通用户页
    expectation: "子进程在线性地址 `start` 上得到一个内容与父页相同的新页映射。"
  - name: 保持页权限
    expectation: "子进程新映射的权限与父页表项提取出的 `perm` 一致。"
prompt: |
  你正在补全 uCore Lab5 代码。请只补全 `lab5_new/kern/mm/pmm.c` 中 `copy_range` 函数内 `LAB5:EXERCISE2 YOUR CODE` 标记处的代码。

  任务目标：
  当前函数已经找到父进程在 `start` 处的有效页 `page`，并为子进程分配了新页 `npage`。你需要复制整页内容，并把新页映射到子进程页表。

  必须完成的行为：
  - 使用 `page2kva(page)` 获取源页内核虚拟地址
  - 使用 `page2kva(npage)` 获取目标页内核虚拟地址
  - 使用 `memcpy` 复制 `PGSIZE` 字节
  - 调用 `page_insert(to, npage, start, perm)` 建立映射，并把返回值保存到 `ret`

  关键约束：
  - 只输出插入该位置的 C 代码片段
  - 不要输出解释、不要输出 Markdown、不要重复函数签名
  - 不要手工修改页引用计数
  - 不要改变 `perm` 的来源
```
