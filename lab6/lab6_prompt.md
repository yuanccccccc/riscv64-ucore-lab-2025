# 实验六提示词整理

本文档依据最新版 [lab6.md](/E:/Desktop/aios/lab6_answer/lab6.md:1) 整理，只保留普通练习中“需要编码”的内容，不包含任何 Challenge。

范围说明：

- `练习0`：属于前置实验代码迁移与适配，不作为本文件中的独立提示词。
- `练习1`：题面明确为“不需要编码”，不生成提示词。
- `练习2`：题面明确为“需要编码”，生成提示词。
- `Challenge 1/2`：按要求排除，不生成提示词。

使用方式：

- 每次只复制下面这一份提示词。
- 将该提示词与 `lab6_new` 目录代码一起提供给大模型。
- 要求模型只补全 `kern/schedule/default_sched.c` 中带 `LAB6` 和 `YOUR CODE` 的位置，不修改其他文件。

## 练习2

```yaml
id: LAB6-REQ-2
name: 实现 Round Robin 调度算法
functional_description: 在调度器框架下实现时间片轮转（Round Robin, RR）调度算法，包括运行队列初始化、进程入队、出队、选择下一个进程以及时钟中断下的时间片处理。
source_scope:
  target_file: "lab6_new/kern/schedule/default_sched.c"
  target_functions:
    - "RR_init"
    - "RR_enqueue"
    - "RR_dequeue"
    - "RR_pick_next"
    - "RR_proc_tick"
  target_marker: "LAB6: YOUR CODE"
spec:
  功能:
    - "初始化 RR 调度器的运行队列。"
    - "将可运行进程按照时间片轮转的 FIFO 语义加入运行队列尾部。"
    - "从运行队列中删除指定进程。"
    - "从运行队列头部选出下一个应该运行的进程。"
    - "在时钟 tick 到来时减少当前进程剩余时间片，并在耗尽时请求重新调度。"
  接口:
    - name: "list_init"
      signature: "void list_init(list_entry_t *elm)"
      description: "初始化双向链表头节点。用于初始化 `rq->run_list`。"
    - name: "list_empty"
      signature: "bool list_empty(list_entry_t *list)"
      description: "判断链表是否为空。既可判断运行队列是否为空，也可用于检查 `proc->run_link` 是否尚未链接到任何队列。"
    - name: "list_add_before"
      signature: "void list_add_before(list_entry_t *listelm, list_entry_t *elm)"
      description: "将节点插入到 `listelm` 之前。对 `rq->run_list` 使用时可实现尾插。"
    - name: "list_del_init"
      signature: "void list_del_init(list_entry_t *listelm)"
      description: "将节点从链表中删除，并把该节点重新初始化为空节点状态。"
    - name: "list_next"
      signature: "list_entry_t *list_next(list_entry_t *listelm)"
      description: "获取链表的下一个节点。可用于从 `rq->run_list` 取得队首的真实进程节点。"
    - name: "le2proc"
      signature: "宏：le2proc(le, member)"
      description: "根据链表节点地址反推出所属的 `struct proc_struct`。"
    - name: "assert"
      signature: "宏"
      description: "用于验证进程入队、出队时的状态约束。"
  数据结构:
    - "`struct run_queue`"
    - "`run_queue.run_list`：RR 的运行队列头。"
    - "`run_queue.proc_num`：当前运行队列中的进程数。"
    - "`run_queue.max_time_slice`：单个进程允许获得的最大时间片。"
    - "`struct proc_struct`"
    - "`proc->run_link`：进程在 RR 队列中的链表节点。"
    - "`proc->time_slice`：当前进程剩余时间片。"
    - "`proc->need_resched`：是否需要重新调度。"
    - "`proc->rq`：当前进程所属的运行队列。"
  依赖:
    - "依赖 `sched.c` 中调度器框架：`sched_init()` 会把 `default_sched_class` 注册为当前调度类。"
    - "依赖 `wakeup_proc()`：当进程变为 `PROC_RUNNABLE` 且不是当前进程时，会调用 `enqueue`。"
    - "依赖 `schedule()`：会在当前进程可继续运行时重新入队，并调用 `pick_next()` 选择下一进程，再调用 `dequeue()` 将其取出。"
    - "依赖 `sched_class_proc_tick()`：时钟中断路径会调用 `RR_proc_tick()` 更新当前进程时间片。"
    - "被系统整体调度行为依赖；若实现错误，会直接影响 `make grade` 中调度相关测试。"
  unsafe_boundary:
    - "若重复将同一进程入队，会破坏双向链表结构，因此入队前要确保 `proc->run_link` 为空。"
    - "若出队时没有验证该进程确实属于当前运行队列，可能破坏其他队列或导致 `proc_num` 不一致。"
    - "若空队列时仍直接对队首节点执行 `le2proc`，会把队列表头误当成进程节点。"
    - "若 `time_slice` 递减逻辑错误，进程可能永远不让出 CPU，或被过早抢占。"
    - "不要在本题中修改 `sched.c` 的框架逻辑，也不要实现 stride 调度器。"
  实现约束:
    - "只补全 `lab6_new/kern/schedule/default_sched.c` 中 5 处 `LAB6: YOUR CODE`。"
    - "必须使用现有链表接口完成 RR 队列管理。"
    - "RR 语义要求：新 runnable 进程插入队尾，从队首选择下一个进程。"
    - "只输出可直接插入这些位置的 C 代码片段。"
    - "不要输出解释、不要输出 Markdown、不要重复函数签名。"
scenarios:
  - name: 初始化运行队列
    expectation: "`rq->run_list` 被初始化为空链表，`rq->proc_num == 0`。"
  - name: 进程首次入队
    expectation: "进程被插入运行队列尾部，`proc->rq` 指向当前运行队列，`rq->proc_num` 增加。"
  - name: 时间片重置
    expectation: "当 `proc->time_slice == 0` 或大于 `rq->max_time_slice` 时，入队后被重置为 `rq->max_time_slice`。"
  - name: 选择下一进程
    expectation: "返回队首真实进程；如果运行队列为空，则返回 `NULL`。"
  - name: 时间片耗尽
    expectation: "`proc->time_slice` 递减到 0 时，将 `proc->need_resched` 置为 1。"
prompt: |
  你正在补全 uCore Lab6 代码。请只补全 `lab6_new/kern/schedule/default_sched.c` 中所有 `LAB6: YOUR CODE` 标记处的代码。

  任务背景：
  该文件需要在现有调度器框架下实现 Round Robin（RR）调度算法。调度框架已经在 `sched.c` 中完成，你只需要实现 RR 调度类的 5 个函数，不要修改其他文件。

  需要完成的函数与行为：
  1. `RR_init(struct run_queue *rq)`
     - 初始化 `rq->run_list`
     - 设置 `rq->proc_num = 0`

  2. `RR_enqueue(struct run_queue *rq, struct proc_struct *proc)`
     - 断言 `proc->run_link` 当前未链接到任何链表
     - 将 `proc->run_link` 插入 `rq->run_list` 尾部
     - 如果 `proc->time_slice == 0` 或 `proc->time_slice > rq->max_time_slice`，则将其重置为 `rq->max_time_slice`
     - 设置 `proc->rq = rq`
     - 执行 `rq->proc_num++`

  3. `RR_dequeue(struct run_queue *rq, struct proc_struct *proc)`
     - 断言该进程确实在当前运行队列中，且 `proc->rq == rq`
     - 使用 `list_del_init(&(proc->run_link))` 将其从队列移除
     - 执行 `rq->proc_num--`

  4. `RR_pick_next(struct run_queue *rq)`
     - 获取 `rq->run_list` 的第一个真实节点
     - 如果存在真实进程节点，则使用 `le2proc(le, run_link)` 返回对应进程
     - 如果运行队列为空，则返回 `NULL`

  5. `RR_proc_tick(struct run_queue *rq, struct proc_struct *proc)`
     - 如果 `proc->time_slice > 0`，则执行递减
     - 如果递减后 `proc->time_slice == 0`，则设置 `proc->need_resched = 1`

  允许使用的关键接口：
  - `list_init`
  - `list_empty`
  - `list_add_before`
  - `list_del_init`
  - `list_next`
  - `le2proc`
  - `assert`

  严格限制：
  - 只输出插入这些标记位置的 C 代码片段
  - 不要输出解释
  - 不要输出 Markdown
  - 不要重复函数签名
  - 不要修改 `sched.c`、`proc.c`、`default_sched_stride.c` 或任何其他文件
  - 不要实现 Challenge 中的 stride 调度算法
```
