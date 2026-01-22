#include <vmm.h>
#include <sync.h>
#include <string.h>
#include <assert.h>
#include <stdio.h>
#include <error.h>
#include <pmm.h>
#include <riscv.h>
#include <swap.h>
#include <kmalloc.h>
#include <file.h>
#include <iobuf.h>
#include <unistd.h>

/*
  vmm design include two parts: mm_struct (mm) & vma_struct (vma)
  mm is the memory manager for the set of continuous virtual memory
  area which have the same PDT. vma is a continuous virtual memory area.
  There a linear link list for vma & a redblack link list for vma in mm.
---------------
  mm related functions:
   golbal functions
     struct mm_struct * mm_create(void)
     void mm_destroy(struct mm_struct *mm)
     int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
--------------
  vma related functions:
   global functions
     struct vma_struct * vma_create (uintptr_t vm_start, uintptr_t vm_end,...)
     void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
     struct vma_struct * find_vma(struct mm_struct *mm, uintptr_t addr)
   local functions
     inline void check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
---------------
   check correctness functions
     void check_vmm(void);
     void check_vma_struct(void);
     void check_pgfault(void);
*/

static void check_vmm(void);
static void check_vma_struct(void);
static void check_pgfault(void);

// mm_create -  alloc a mm_struct & initialize it.
struct mm_struct *
mm_create(void)
{
    struct mm_struct *mm = kmalloc(sizeof(struct mm_struct));

    if (mm != NULL)
    {
        list_init(&(mm->mmap_list));
        mm->mmap_cache = NULL;
        mm->pgdir = NULL;
        mm->map_count = 0;

        if (swap_init_ok)
            swap_init_mm(mm);
        else
            mm->sm_priv = NULL;

        set_mm_count(mm, 0);
        sem_init(&(mm->mm_sem), 1);
    }
    return mm;
}

// vma_create - alloc a vma_struct & initialize it. (addr range: vm_start~vm_end)
struct vma_struct *
vma_create(uintptr_t vm_start, uintptr_t vm_end, uint32_t vm_flags)
{
    struct vma_struct *vma = kmalloc(sizeof(struct vma_struct));

    if (vma != NULL)
    {
        vma->vm_start = vm_start;
        vma->vm_end = vm_end;
        vma->vm_flags = vm_flags;
        vma->vm_file = NULL; // 初始化文件映射指针
        vma->vm_pgoff = 0;   // 初始化页偏移
    }
    return vma;
}

// find_vma - find a vma  (vma->vm_start <= addr <= vma_vm_end)
struct vma_struct *
find_vma(struct mm_struct *mm, uintptr_t addr)
{
    struct vma_struct *vma = NULL;
    if (mm != NULL)
    {
        vma = mm->mmap_cache;
        if (!(vma != NULL && vma->vm_start <= addr && vma->vm_end > addr))
        {
            bool found = 0;
            list_entry_t *list = &(mm->mmap_list), *le = list;
            while ((le = list_next(le)) != list)
            {
                vma = le2vma(le, list_link);
                if (vma->vm_start <= addr && addr < vma->vm_end)
                {
                    found = 1;
                    break;
                }
            }
            if (!found)
            {
                vma = NULL;
            }
        }
        if (vma != NULL)
        {
            mm->mmap_cache = vma;
        }
    }
    return vma;
}

// check_vma_overlap - check if vma1 overlaps vma2 ?
static inline void
check_vma_overlap(struct vma_struct *prev, struct vma_struct *next)
{
    assert(prev->vm_start < prev->vm_end);
    assert(prev->vm_end <= next->vm_start);
    assert(next->vm_start < next->vm_end);
}

// insert_vma_struct -insert vma in mm's list link
void insert_vma_struct(struct mm_struct *mm, struct vma_struct *vma)
{
    assert(vma->vm_start < vma->vm_end);
    list_entry_t *list = &(mm->mmap_list);
    list_entry_t *le_prev = list, *le_next;

    list_entry_t *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *mmap_prev = le2vma(le, list_link);
        if (mmap_prev->vm_start > vma->vm_start)
        {
            break;
        }
        le_prev = le;
    }

    le_next = list_next(le_prev);

    /* check overlap */
    if (le_prev != list)
    {
        check_vma_overlap(le2vma(le_prev, list_link), vma);
    }
    if (le_next != list)
    {
        check_vma_overlap(vma, le2vma(le_next, list_link));
    }

    vma->vm_mm = mm;
    list_add_after(le_prev, &(vma->list_link));

    mm->map_count++;
}

// mm_destroy - free mm and mm internal fields
void mm_destroy(struct mm_struct *mm)
{
    assert(mm_count(mm) == 0);

    list_entry_t *list = &(mm->mmap_list), *le;
    while ((le = list_next(list)) != list)
    {
        list_del(le);
        kfree(le2vma(le, list_link)); // kfree vma
    }
    kfree(mm); // kfree mm
    mm = NULL;
}

int mm_map(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
           struct vma_struct **vma_store)
{
    uintptr_t start = ROUNDDOWN(addr, PGSIZE), end = ROUNDUP(addr + len, PGSIZE);
    if (!USER_ACCESS(start, end))
    {
        return -E_INVAL;
    }

    assert(mm != NULL);

    int ret = -E_INVAL;

    struct vma_struct *vma;
    if ((vma = find_vma(mm, start)) != NULL && end > vma->vm_start)
    {
        goto out;
    }
    ret = -E_NO_MEM;

    if ((vma = vma_create(start, end, vm_flags)) == NULL)
    {
        goto out;
    }
    insert_vma_struct(mm, vma);
    if (vma_store != NULL)
    {
        *vma_store = vma;
    }
    ret = 0;

out:
    return ret;
}

int dup_mmap(struct mm_struct *to, struct mm_struct *from)
{
    assert(to != NULL && from != NULL);
    list_entry_t *list = &(from->mmap_list), *le = list;
    while ((le = list_prev(le)) != list)
    {
        struct vma_struct *vma, *nvma;
        vma = le2vma(le, list_link);
        nvma = vma_create(vma->vm_start, vma->vm_end, vma->vm_flags);
        if (nvma == NULL)
        {
            return -E_NO_MEM;
        }

        insert_vma_struct(to, nvma);

        bool share = 0;
        if (copy_range(to->pgdir, from->pgdir, vma->vm_start, vma->vm_end, share) != 0)
        {
            return -E_NO_MEM;
        }
    }
    return 0;
}

void exit_mmap(struct mm_struct *mm)
{
    assert(mm != NULL && mm_count(mm) == 0);
    pde_t *pgdir = mm->pgdir;
    list_entry_t *list = &(mm->mmap_list), *le = list;
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        unmap_range(pgdir, vma->vm_start, vma->vm_end);
    }
    while ((le = list_next(le)) != list)
    {
        struct vma_struct *vma = le2vma(le, list_link);
        exit_range(pgdir, vma->vm_start, vma->vm_end);
    }
}

bool copy_from_user(struct mm_struct *mm, void *dst, const void *src, size_t len, bool writable)
{
    if (!user_mem_check(mm, (uintptr_t)src, len, writable))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

bool copy_to_user(struct mm_struct *mm, void *dst, const void *src, size_t len)
{
    if (!user_mem_check(mm, (uintptr_t)dst, len, 1))
    {
        return 0;
    }
    memcpy(dst, src, len);
    return 1;
}

// vmm_init - initialize virtual memory management
//          - now just call check_vmm to check correctness of vmm
void vmm_init(void)
{
    check_vmm();
}

// check_vmm - check correctness of vmm
static void
check_vmm(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    check_vma_struct();
    check_pgfault();

    cprintf("check_vmm() succeeded.\n");
}

static void
check_vma_struct(void)
{
    // size_t nr_free_pages_store = nr_free_pages();

    struct mm_struct *mm = mm_create();
    assert(mm != NULL);

    int step1 = 10, step2 = step1 * 10;

    int i;
    for (i = step1; i >= 1; i--)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    for (i = step1 + 1; i <= step2; i++)
    {
        struct vma_struct *vma = vma_create(i * 5, i * 5 + 2, 0);
        assert(vma != NULL);
        insert_vma_struct(mm, vma);
    }

    list_entry_t *le = list_next(&(mm->mmap_list));

    for (i = 1; i <= step2; i++)
    {
        assert(le != &(mm->mmap_list));
        struct vma_struct *mmap = le2vma(le, list_link);
        assert(mmap->vm_start == i * 5 && mmap->vm_end == i * 5 + 2);
        le = list_next(le);
    }

    for (i = 5; i <= 5 * step2; i += 5)
    {
        struct vma_struct *vma1 = find_vma(mm, i);
        assert(vma1 != NULL);
        struct vma_struct *vma2 = find_vma(mm, i + 1);
        assert(vma2 != NULL);
        struct vma_struct *vma3 = find_vma(mm, i + 2);
        assert(vma3 == NULL);
        struct vma_struct *vma4 = find_vma(mm, i + 3);
        assert(vma4 == NULL);
        struct vma_struct *vma5 = find_vma(mm, i + 4);
        assert(vma5 == NULL);

        assert(vma1->vm_start == i && vma1->vm_end == i + 2);
        assert(vma2->vm_start == i && vma2->vm_end == i + 2);
    }

    for (i = 4; i >= 0; i--)
    {
        struct vma_struct *vma_below_5 = find_vma(mm, i);
        if (vma_below_5 != NULL)
        {
            cprintf("vma_below_5: i %x, start %x, end %x\n", i, vma_below_5->vm_start, vma_below_5->vm_end);
        }
        assert(vma_below_5 == NULL);
    }

    mm_destroy(mm);

    cprintf("check_vma_struct() succeeded!\n");
}

struct mm_struct *check_mm_struct;

// check_pgfault - check correctness of pgfault handler
static void
check_pgfault(void)
{
    size_t nr_free_pages_store = nr_free_pages();

    check_mm_struct = mm_create();
    assert(check_mm_struct != NULL);

    struct mm_struct *mm = check_mm_struct;
    pde_t *pgdir = mm->pgdir = boot_pgdir;
    assert(pgdir[0] == 0);

    struct vma_struct *vma = vma_create(0, PTSIZE, VM_WRITE);
    assert(vma != NULL);

    insert_vma_struct(mm, vma);

    uintptr_t addr = 0x100;
    assert(find_vma(mm, addr) == vma);

    int i, sum = 0;

    for (i = 0; i < 100; i++)
    {
        *(char *)(addr + i) = i;
        sum += i;
    }
    for (i = 0; i < 100; i++)
    {
        sum -= *(char *)(addr + i);
    }

    assert(sum == 0);

    pde_t *pd1 = pgdir, *pd0 = page2kva(pde2page(pgdir[0]));
    page_remove(pgdir, ROUNDDOWN(addr, PGSIZE));
    free_page(pde2page(pd0[0]));
    free_page(pde2page(pd1[0]));
    pgdir[0] = 0;
    flush_tlb();

    mm->pgdir = NULL;
    mm_destroy(mm);
    check_mm_struct = NULL;

    assert(nr_free_pages_store == nr_free_pages());

    cprintf("check_pgfault() succeeded!\n");
}
// page fault number
volatile unsigned int pgfault_num = 0;

// /* do_pgfault - interrupt handler to process the page fault execption
//  * @mm         : the control struct for a set of vma using the same PDT
//  * @error_code : the error code recorded in trapframe->tf_err which is setted by x86 hardware
//  * @addr       : the addr which causes a memory access exception, (the contents of the CR2 register)
//  *
//  * CALL GRAPH: trap--> trap_dispatch-->pgfault_handler-->do_pgfault
//  * The processor provides ucore's do_pgfault function with two items of information to aid in diagnosing
//  * the exception and recovering from it.
//  *   (1) The contents of the CR2 register. The processor loads the CR2 register with the
//  *       32-bit linear address that generated the exception. The do_pgfault fun can
//  *       use this address to locate the corresponding page directory and page-table
//  *       entries.
//  *   (2) An error code on the kernel stack. The error code for a page fault has a format different from
//  *       that for other exceptions. The error code tells the exception handler three things:
//  *         -- The P flag   (bit 0) indicates whether the exception was due to a not-present page (0)
//  *            or to either an access rights violation or the use of a reserved bit (1).
//  *         -- The W/R flag (bit 1) indicates whether the memory access that caused the exception
//  *            was a read (0) or write (1).
//  *         -- The U/S flag (bit 2) indicates whether the processor was executing at user mode (1)
//  *            or supervisor mode (0) at the time of the exception.
//  */

int do_pgfault(struct mm_struct *mm, uint32_t error_code, uintptr_t addr)
{
    int ret = -E_INVAL;
    struct vma_struct *vma = find_vma(mm, addr);

    pgfault_num++;

    // 1. 地址合法性检查
    if (vma == NULL || vma->vm_start > addr)
    {
        cprintf("not valid addr %x, and can not find it in vma\n", addr);
        return -E_INVAL;
    }

    // 2. 写权限检查（仅对写操作检查）
    // RISC-V: cause == 15 (CAUSE_STORE_PAGE_FAULT) 表示写操作
    bool is_write = (error_code == 15);
    if (is_write && !(vma->vm_flags & VM_WRITE))
    {
        cprintf("do_pgfault: write to non-writable vma\n");
        return -E_INVAL;
    }

    // 3. 设置页权限
    // RISC-V 要求：必须设置 PTE_R 才能访问页面
    uint32_t perm = PTE_U | PTE_R; // 用户可访问 + 可读
    if (vma->vm_flags & VM_WRITE)
    {
        perm |= PTE_W;
    }

    addr = ROUNDDOWN(addr, PGSIZE);

    // 4. 获取 PTE（必要时创建页表）
    pte_t *ptep = get_pte(mm->pgdir, addr, 1);
    if (ptep == NULL)
    {
        cprintf("get_pte in do_pgfault failed\n");
        return -E_NO_MEM;
    }

    /*
     * =================================================
     * 5. mmap 文件映射缺页处理
     *    模仿 Linux 的处理方式：
     *    - 文件映射的页面在缺页时从文件读取
     *    - 使用 file_seek + file_read 来读取指定偏移的数据
     * =================================================
     */
    if (vma->vm_file != NULL)
    {
        // 文件映射：只处理"页尚未建立"的情况
        if (*ptep == 0)
        {
            // 分配物理页
            struct Page *page = pgdir_alloc_page(mm->pgdir, addr, perm);
            if (page == NULL)
            {
                cprintf("pgdir_alloc_page in mmap pgfault failed\n");
                return -E_NO_MEM;
            }

            void *kva = page2kva(page);
            // 先清零，防止文件末尾不足一页时有脏数据
            memset(kva, 0, PGSIZE);

            // 计算文件偏移
            // vm_pgoff 是映射起始的页偏移，加上当前页相对于映射起始的偏移
            size_t page_index = (addr - vma->vm_start) / PGSIZE;
            off_t file_offset = (vma->vm_pgoff + page_index) * PGSIZE;

            // 先 seek 到正确位置，再读取
            struct file *file = vma->vm_file;
            int fd = file->fd;
            off_t saved_pos = file->pos; // 保存当前游标

            ret = file_seek(fd, file_offset, LSEEK_SET);
            if (ret != 0)
            {
                cprintf("file_seek in mmap pgfault failed: %e\n", ret);
                // 即使 seek 失败，页面已分配，返回成功让进程继续
                // 页面内容为零
                return 0;
            }

            size_t read_size = 0;
            ret = file_read(fd, kva, PGSIZE, &read_size);

            // 恢复文件游标
            file_seek(fd, saved_pos, LSEEK_SET);

            if (ret != 0 && ret != -E_EOF)
            {
                cprintf("file_read in mmap pgfault failed: %e\n", ret);
                // 读取失败，但页面已分配，返回成功
                return 0;
            }
            // 读取成功（可能读取了 0 到 PGSIZE 字节）
        }
        // 如果 *ptep != 0，说明页面已存在，直接返回成功
        return 0;
    }

    /*
     * ==================================
     * 6. 匿名页 / swap 缺页处理
     * ==================================
     */
    if (*ptep == 0)
    {
        // 匿名页：分配新页并清零
        if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
        {
            cprintf("pgdir_alloc_page in do_pgfault failed\n");
            return -E_NO_MEM;
        }
    }
    else
    {
        // PTE不为0，可能是swap条目或者是已存在的页面
        /*LAB9 : YOUR CODE
        * 请你根据以下信息提示，补充函数
        * 现在我们认为pte是一个交换条目，那我们应该从磁盘加载数据并放到带有phy addr的页面，
        * 并将phy addr与逻辑addr映射，触发交换管理器记录该页面的访问情况
        *
        *  一些有用的宏和定义，可能会对你接下来代码的编写产生帮助(显然是有帮助的)
        *  宏或函数:
        *    swap_in(mm, addr, &page) : 分配一个内存页，然后根据
        *    PTE中的swap条目的addr，找到磁盘页的地址，将磁盘页的内容读入这个内存页
        *    page_insert ： 建立一个Page的phy addr与线性addr la的映射
        *    swap_map_swappable ： 设置页面可交换
        */
        if (swap_init_ok)
        {
            // swap 页：从交换区换入
            struct Page *page = NULL;
            // 你要编写的内容在这里，请基于上文说明以及下文的英文注释完成代码编写
            //(1）According to the mm AND addr, try
            //to load the content of right disk page
            //into the memory which page managed.
            //(2) According to the mm,
            //addr AND page, setup the
            //map of phy addr <--->
            //logical addr
            //(3) make the page swappable.
            page->pra_vaddr = addr;
        }
        else
        {
            // swap未初始化，但PTE不为0
            // 检查是否是有效页面（PTE_V位）
            if (*ptep & PTE_V)
            {
                // 页面已经存在，可能是权限问题，直接返回成功
                return 0;
            }
            // 不是有效页面，可能是残留的swap条目或无效数据
            // 清除PTE并分配新页面
            *ptep = 0;
            if (pgdir_alloc_page(mm->pgdir, addr, perm) == NULL)
            {
                cprintf("pgdir_alloc_page in do_pgfault failed (swap not ready)\n");
                return -E_NO_MEM;
            }
        }
    }

    return 0;
}

bool user_mem_check(struct mm_struct *mm, uintptr_t addr, size_t len, bool write)
{
    if (mm != NULL)
    {
        if (!USER_ACCESS(addr, addr + len))
        {
            return 0;
        }
        struct vma_struct *vma;
        uintptr_t start = addr, end = addr + len;
        while (start < end)
        {
            if ((vma = find_vma(mm, start)) == NULL || start < vma->vm_start)
            {
                return 0;
            }
            if (!(vma->vm_flags & ((write) ? VM_WRITE : VM_READ)))
            {
                return 0;
            }
            if (write && (vma->vm_flags & VM_STACK))
            {
                if (start < vma->vm_start + PGSIZE)
                { // check stack start & size
                    return 0;
                }
            }
            start = vma->vm_end;
        }
        return 1;
    }
    return KERN_ACCESS(addr, addr + len);
}
bool copy_string(struct mm_struct *mm, char *dst, const char *src,
                 size_t maxn)
{
    size_t alen,
        part = ROUNDDOWN((uintptr_t)src + PGSIZE, PGSIZE) - (uintptr_t)src;
    while (1)
    {
        if (part > maxn)
        {
            part = maxn;
        }
        if (!user_mem_check(mm, (uintptr_t)src, part, 0))
        {
            return 0;
        }
        if ((alen = strnlen(src, part)) < part)
        {
            memcpy(dst, src, alen + 1);
            return 1;
        }
        if (part == maxn)
        {
            return 0;
        }
        memcpy(dst, src, part);
        dst += part, src += part, maxn -= part;
        part = PGSIZE;
    }
}

/*
 * find_free_area - 在VMA列表中查找足够大的空闲区域
 * @mm: 内存管理结构
 * @len: 需要的长度（已对齐到页）
 * @start_hint: 搜索起始地址提示
 *
 * 策略：First-Fit算法
 * 1. 从start_hint开始，在VMA之间的空隙中查找
 * 2. 如果找不到，从用户空间起始位置重新查找
 * 3. 返回找到的地址，失败返回0
 */
// do_mmap - map file or anonymous memory into address space
uintptr_t do_mmap(struct mm_struct *mm, uintptr_t addr, size_t len, uint32_t vm_flags,
                  struct file *file, off_t offset)
{
    if (len == 0)
    {
        return -E_INVAL;
    }

    len = ROUNDUP(len, PGSIZE);

    // 如果addr为0，自动分配一个地址
    // 使用一个简单的策略：从用户空间的某个位置开始查找空闲区域
    if (addr == 0)
    {
        /* lab9 练习4：YOUR CODE
        实现最佳适配（Best-Fit）地址分配算法 */
        // 提示：
        // 1. 你需要遍历所有可能的空闲地址空间（vma之间的间隙）
        // 2. 记录满足长度要求且剩余空间最小的地址
        // 3. 初始搜索地址可以从0x60000000开始，结束于USERTOP - len
        // 4. 使用find_vma函数检查地址是否已被占用
        // 5. 遍历mm->mmap_list链表查找相邻vma之间的空闲区域
        // 6. 对于每个空闲区域，检查其大小是否足够，并记录最佳适配的地址
        
        /* 请在此处填写你的代码 */
        
        if (addr == 0)
        {
            cprintf("[do_mmap] failed to find free address space\n");
            return -E_NO_MEM;
        }
    }
    else
    {
        addr = ROUNDDOWN(addr, PGSIZE);
    }

    cprintf("[do_mmap] addr=0x%x, len=0x%x, flags=0x%x, file=%p\n",
            addr, len, vm_flags, file);

    if (!USER_ACCESS(addr, addr + len))
    {
        cprintf("[do_mmap] USER_ACCESS check failed\n");
        return -E_INVAL;
    }

    // 检查地址重叠
    struct vma_struct *vma = find_vma(mm, addr);
    if (vma != NULL && addr + len > vma->vm_start)
    {
        cprintf("[do_mmap] overlapping with existing vma\n");
        return -E_INVAL;
    }

    /* lab9 练习3：YOUR CODE
    理解VMA创建和文件映射设置 */
    // 提示：
    // 1. 创建vma_struct结构体，设置起始地址、结束地址和标志
    // 2. 如果是文件映射，设置vm_file和vm_pgoff，并增加文件引用计数
    // 3. 将vma插入到进程的vma链表中
    
    /* 请在此处填写你的代码 */

    // 返回分配的地址
    return addr;
}

// do_munmap - unmap a memory region
int do_munmap(struct mm_struct *mm, uintptr_t addr, size_t len)
{
    if (len == 0)
    {
        return -E_INVAL;
    }

    len = ROUNDUP(len, PGSIZE);
    addr = ROUNDDOWN(addr, PGSIZE);

    if (!USER_ACCESS(addr, addr + len))
    {
        return -E_INVAL;
    }

    /* lab9 练习3：YOUR CODE
    理解VMA查找和验证 */
    // 提示：
    // 1. 使用find_vma查找包含addr的vma
    // 2. 验证vma的起始地址和结束地址与请求完全匹配
    // 3. 如果不匹配，返回错误
    
    /* 请在此处填写你的代码 */

    // 取消页表映射
    unmap_range(mm->pgdir, addr, addr + len);

    /* lab9 练习3：YOUR CODE
    理解文件引用计数管理 */
    // 提示：
    // 1. 如果vma是文件映射，需要减少文件引用计数
    // 2. 引用计数为0时会自动关闭文件
    
    /* 请在此处填写你的代码 */

    /* lab9 练习3：YOUR CODE
    理解VMA的移除和清理 */
    // 提示：
    // 1. 从进程的vma链表中删除该vma
    // 2. 释放vma结构体内存
    // 3. 更新进程的map_count计数器
    
    /* 请在此处填写你的代码 */

    return 0;
}

