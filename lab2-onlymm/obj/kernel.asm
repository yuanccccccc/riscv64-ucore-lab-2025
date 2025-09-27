
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:

    .section .text,"ax",%progbits
    .globl kern_entry
kern_entry:
    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200000:	c02042b7          	lui	t0,0xc0204
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc0200004:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200008:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc020000a:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc020000e:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc0200012:	fff0031b          	addiw	t1,zero,-1
ffffffffc0200016:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200018:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc020001c:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200020:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc0200024:	c0204137          	lui	sp,0xc0204

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 跳转到 kern_init
    lui t0, %hi(kern_init)
ffffffffc0200028:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020002c:	0c028293          	addi	t0,t0,192 # ffffffffc02000c0 <kern_init>
    jr t0
ffffffffc0200030:	8282                	jr	t0

ffffffffc0200032 <print_kerninfo>:
int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int kern_init(void) {
    extern char edata[], end[];
ffffffffc0200032:	1141                	addi	sp,sp,-16
    memset(edata, 0, end - edata);
    cons_init();  // init the console
ffffffffc0200034:	00001517          	auipc	a0,0x1
ffffffffc0200038:	1ac50513          	addi	a0,a0,428 # ffffffffc02011e0 <etext+0x2>
    extern char edata[], end[];
ffffffffc020003c:	e406                	sd	ra,8(sp)
    cons_init();  // init the console
ffffffffc020003e:	0f2000ef          	jal	ra,ffffffffc0200130 <cprintf>
    const char *message = "(THU.CST) os is loading ...\0";
ffffffffc0200042:	00000597          	auipc	a1,0x0
ffffffffc0200046:	07e58593          	addi	a1,a1,126 # ffffffffc02000c0 <kern_init>
ffffffffc020004a:	00001517          	auipc	a0,0x1
ffffffffc020004e:	1b650513          	addi	a0,a0,438 # ffffffffc0201200 <etext+0x22>
ffffffffc0200052:	0de000ef          	jal	ra,ffffffffc0200130 <cprintf>
    //cprintf("%s\n\n", message);
ffffffffc0200056:	00001597          	auipc	a1,0x1
ffffffffc020005a:	18858593          	addi	a1,a1,392 # ffffffffc02011de <etext>
ffffffffc020005e:	00001517          	auipc	a0,0x1
ffffffffc0200062:	1c250513          	addi	a0,a0,450 # ffffffffc0201220 <etext+0x42>
ffffffffc0200066:	0ca000ef          	jal	ra,ffffffffc0200130 <cprintf>
    cputs(message);
ffffffffc020006a:	00005597          	auipc	a1,0x5
ffffffffc020006e:	f9e58593          	addi	a1,a1,-98 # ffffffffc0205008 <free_area>
ffffffffc0200072:	00001517          	auipc	a0,0x1
ffffffffc0200076:	1ce50513          	addi	a0,a0,462 # ffffffffc0201240 <etext+0x62>
ffffffffc020007a:	0b6000ef          	jal	ra,ffffffffc0200130 <cprintf>

ffffffffc020007e:	00005597          	auipc	a1,0x5
ffffffffc0200082:	fda58593          	addi	a1,a1,-38 # ffffffffc0205058 <end>
ffffffffc0200086:	00001517          	auipc	a0,0x1
ffffffffc020008a:	1da50513          	addi	a0,a0,474 # ffffffffc0201260 <etext+0x82>
ffffffffc020008e:	0a2000ef          	jal	ra,ffffffffc0200130 <cprintf>
    print_kerninfo();

ffffffffc0200092:	00005597          	auipc	a1,0x5
ffffffffc0200096:	3c558593          	addi	a1,a1,965 # ffffffffc0205457 <end+0x3ff>
ffffffffc020009a:	00000797          	auipc	a5,0x0
ffffffffc020009e:	02678793          	addi	a5,a5,38 # ffffffffc02000c0 <kern_init>
ffffffffc02000a2:	40f587b3          	sub	a5,a1,a5
    print_kerninfo();
ffffffffc02000a6:	43f7d593          	srai	a1,a5,0x3f
    // grade_backtrace();
ffffffffc02000aa:	60a2                	ld	ra,8(sp)
    print_kerninfo();
ffffffffc02000ac:	3ff5f593          	andi	a1,a1,1023
ffffffffc02000b0:	95be                	add	a1,a1,a5
ffffffffc02000b2:	85a9                	srai	a1,a1,0xa
ffffffffc02000b4:	00001517          	auipc	a0,0x1
ffffffffc02000b8:	1cc50513          	addi	a0,a0,460 # ffffffffc0201280 <etext+0xa2>
    // grade_backtrace();
ffffffffc02000bc:	0141                	addi	sp,sp,16
    print_kerninfo();
ffffffffc02000be:	a88d                	j	ffffffffc0200130 <cprintf>

ffffffffc02000c0 <kern_init>:
    idt_init();  // init interrupt descriptor table

    pmm_init();  // init physical memory management

ffffffffc02000c0:	00005517          	auipc	a0,0x5
ffffffffc02000c4:	f4850513          	addi	a0,a0,-184 # ffffffffc0205008 <free_area>
ffffffffc02000c8:	00005617          	auipc	a2,0x5
ffffffffc02000cc:	f9060613          	addi	a2,a2,-112 # ffffffffc0205058 <end>

ffffffffc02000d0:	1141                	addi	sp,sp,-16

ffffffffc02000d2:	8e09                	sub	a2,a2,a0
ffffffffc02000d4:	4581                	li	a1,0

ffffffffc02000d6:	e406                	sd	ra,8(sp)

ffffffffc02000d8:	0f4010ef          	jal	ra,ffffffffc02011cc <memset>
    idt_init();  // init interrupt descriptor table
ffffffffc02000dc:	11e000ef          	jal	ra,ffffffffc02001fa <cons_init>

    clock_init();   // init clock interrupt
    intr_enable();  // enable irq interrupt
ffffffffc02000e0:	00001517          	auipc	a0,0x1
ffffffffc02000e4:	1d050513          	addi	a0,a0,464 # ffffffffc02012b0 <etext+0xd2>
ffffffffc02000e8:	07e000ef          	jal	ra,ffffffffc0200166 <cputs>

    // LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
ffffffffc02000ec:	f47ff0ef          	jal	ra,ffffffffc0200032 <print_kerninfo>
    // user/kernel mode switch test
    // lab1_switch_test();

ffffffffc02000f0:	33b000ef          	jal	ra,ffffffffc0200c2a <pmm_init>
    while (1)
        ;
}

void __attribute__((noinline))
grade_backtrace2(int arg0, int arg1, int arg2, int arg3) {
ffffffffc02000f4:	a001                	j	ffffffffc02000f4 <kern_init+0x34>

ffffffffc02000f6 <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc02000f6:	1141                	addi	sp,sp,-16
ffffffffc02000f8:	e022                	sd	s0,0(sp)
ffffffffc02000fa:	e406                	sd	ra,8(sp)
ffffffffc02000fc:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000fe:	0fe000ef          	jal	ra,ffffffffc02001fc <cons_putc>
    (*cnt) ++;
ffffffffc0200102:	401c                	lw	a5,0(s0)
}
ffffffffc0200104:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc0200106:	2785                	addiw	a5,a5,1
ffffffffc0200108:	c01c                	sw	a5,0(s0)
}
ffffffffc020010a:	6402                	ld	s0,0(sp)
ffffffffc020010c:	0141                	addi	sp,sp,16
ffffffffc020010e:	8082                	ret

ffffffffc0200110 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	862a                	mv	a2,a0
ffffffffc0200114:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200116:	00000517          	auipc	a0,0x0
ffffffffc020011a:	fe050513          	addi	a0,a0,-32 # ffffffffc02000f6 <cputch>
ffffffffc020011e:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc0200120:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc0200122:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200124:	4f1000ef          	jal	ra,ffffffffc0200e14 <vprintfmt>
    return cnt;
}
ffffffffc0200128:	60e2                	ld	ra,24(sp)
ffffffffc020012a:	4532                	lw	a0,12(sp)
ffffffffc020012c:	6105                	addi	sp,sp,32
ffffffffc020012e:	8082                	ret

ffffffffc0200130 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc0200130:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc0200132:	02810313          	addi	t1,sp,40 # ffffffffc0204028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc0200136:	8e2a                	mv	t3,a0
ffffffffc0200138:	f42e                	sd	a1,40(sp)
ffffffffc020013a:	f832                	sd	a2,48(sp)
ffffffffc020013c:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020013e:	00000517          	auipc	a0,0x0
ffffffffc0200142:	fb850513          	addi	a0,a0,-72 # ffffffffc02000f6 <cputch>
ffffffffc0200146:	004c                	addi	a1,sp,4
ffffffffc0200148:	869a                	mv	a3,t1
ffffffffc020014a:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc020014c:	ec06                	sd	ra,24(sp)
ffffffffc020014e:	e0ba                	sd	a4,64(sp)
ffffffffc0200150:	e4be                	sd	a5,72(sp)
ffffffffc0200152:	e8c2                	sd	a6,80(sp)
ffffffffc0200154:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc0200156:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200158:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc020015a:	4bb000ef          	jal	ra,ffffffffc0200e14 <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc020015e:	60e2                	ld	ra,24(sp)
ffffffffc0200160:	4512                	lw	a0,4(sp)
ffffffffc0200162:	6125                	addi	sp,sp,96
ffffffffc0200164:	8082                	ret

ffffffffc0200166 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200166:	1101                	addi	sp,sp,-32
ffffffffc0200168:	e822                	sd	s0,16(sp)
ffffffffc020016a:	ec06                	sd	ra,24(sp)
ffffffffc020016c:	e426                	sd	s1,8(sp)
ffffffffc020016e:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc0200170:	00054503          	lbu	a0,0(a0)
ffffffffc0200174:	c51d                	beqz	a0,ffffffffc02001a2 <cputs+0x3c>
ffffffffc0200176:	0405                	addi	s0,s0,1
ffffffffc0200178:	4485                	li	s1,1
ffffffffc020017a:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc020017c:	080000ef          	jal	ra,ffffffffc02001fc <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc0200180:	00044503          	lbu	a0,0(s0)
ffffffffc0200184:	008487bb          	addw	a5,s1,s0
ffffffffc0200188:	0405                	addi	s0,s0,1
ffffffffc020018a:	f96d                	bnez	a0,ffffffffc020017c <cputs+0x16>
    (*cnt) ++;
ffffffffc020018c:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc0200190:	4529                	li	a0,10
ffffffffc0200192:	06a000ef          	jal	ra,ffffffffc02001fc <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200196:	60e2                	ld	ra,24(sp)
ffffffffc0200198:	8522                	mv	a0,s0
ffffffffc020019a:	6442                	ld	s0,16(sp)
ffffffffc020019c:	64a2                	ld	s1,8(sp)
ffffffffc020019e:	6105                	addi	sp,sp,32
ffffffffc02001a0:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc02001a2:	4405                	li	s0,1
ffffffffc02001a4:	b7f5                	j	ffffffffc0200190 <cputs+0x2a>

ffffffffc02001a6 <__panic>:

/* *
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
ffffffffc02001a6:	00005317          	auipc	t1,0x5
ffffffffc02001aa:	e7a30313          	addi	t1,t1,-390 # ffffffffc0205020 <is_panic>
ffffffffc02001ae:	00032e03          	lw	t3,0(t1)
 * */
ffffffffc02001b2:	715d                	addi	sp,sp,-80
ffffffffc02001b4:	ec06                	sd	ra,24(sp)
ffffffffc02001b6:	e822                	sd	s0,16(sp)
ffffffffc02001b8:	f436                	sd	a3,40(sp)
ffffffffc02001ba:	f83a                	sd	a4,48(sp)
ffffffffc02001bc:	fc3e                	sd	a5,56(sp)
ffffffffc02001be:	e0c2                	sd	a6,64(sp)
ffffffffc02001c0:	e4c6                	sd	a7,72(sp)
void
ffffffffc02001c2:	000e0363          	beqz	t3,ffffffffc02001c8 <__panic+0x22>
    va_start(ap, fmt);
    cprintf("kernel panic at %s:%d:\n    ", file, line);
    vcprintf(fmt, ap);
    cprintf("\n");
    va_end(ap);

ffffffffc02001c6:	a001                	j	ffffffffc02001c6 <__panic+0x20>
        goto panic_dead;
ffffffffc02001c8:	4785                	li	a5,1
ffffffffc02001ca:	00f32023          	sw	a5,0(t1)
    // print the 'message'
ffffffffc02001ce:	8432                	mv	s0,a2
ffffffffc02001d0:	103c                	addi	a5,sp,40
    va_list ap;
ffffffffc02001d2:	862e                	mv	a2,a1
ffffffffc02001d4:	85aa                	mv	a1,a0
ffffffffc02001d6:	00001517          	auipc	a0,0x1
ffffffffc02001da:	0fa50513          	addi	a0,a0,250 # ffffffffc02012d0 <etext+0xf2>
    // print the 'message'
ffffffffc02001de:	e43e                	sd	a5,8(sp)
    va_list ap;
ffffffffc02001e0:	f51ff0ef          	jal	ra,ffffffffc0200130 <cprintf>
    va_start(ap, fmt);
ffffffffc02001e4:	65a2                	ld	a1,8(sp)
ffffffffc02001e6:	8522                	mv	a0,s0
ffffffffc02001e8:	f29ff0ef          	jal	ra,ffffffffc0200110 <vcprintf>
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02001ec:	00001517          	auipc	a0,0x1
ffffffffc02001f0:	0bc50513          	addi	a0,a0,188 # ffffffffc02012a8 <etext+0xca>
ffffffffc02001f4:	f3dff0ef          	jal	ra,ffffffffc0200130 <cprintf>
ffffffffc02001f8:	b7f9                	j	ffffffffc02001c6 <__panic+0x20>

ffffffffc02001fa <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc02001fa:	8082                	ret

ffffffffc02001fc <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc02001fc:	0ff57513          	zext.b	a0,a0
ffffffffc0200200:	7970006f          	j	ffffffffc0201196 <sbi_console_putchar>

ffffffffc0200204 <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc0200204:	00005797          	auipc	a5,0x5
ffffffffc0200208:	e0478793          	addi	a5,a5,-508 # ffffffffc0205008 <free_area>
ffffffffc020020c:	e79c                	sd	a5,8(a5)
ffffffffc020020e:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200210:	0007a823          	sw	zero,16(a5)
}
ffffffffc0200214:	8082                	ret

ffffffffc0200216 <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc0200216:	00005517          	auipc	a0,0x5
ffffffffc020021a:	e0256503          	lwu	a0,-510(a0) # ffffffffc0205018 <free_area+0x10>
ffffffffc020021e:	8082                	ret

ffffffffc0200220 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200220:	cd49                	beqz	a0,ffffffffc02002ba <best_fit_alloc_pages+0x9a>
    if (n > nr_free) {
ffffffffc0200222:	00005617          	auipc	a2,0x5
ffffffffc0200226:	de660613          	addi	a2,a2,-538 # ffffffffc0205008 <free_area>
ffffffffc020022a:	01062803          	lw	a6,16(a2)
ffffffffc020022e:	86aa                	mv	a3,a0
ffffffffc0200230:	02081793          	slli	a5,a6,0x20
ffffffffc0200234:	9381                	srli	a5,a5,0x20
ffffffffc0200236:	08a7e063          	bltu	a5,a0,ffffffffc02002b6 <best_fit_alloc_pages+0x96>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc020023a:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc020023c:	0018059b          	addiw	a1,a6,1
ffffffffc0200240:	1582                	slli	a1,a1,0x20
ffffffffc0200242:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc0200244:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200246:	06c78763          	beq	a5,a2,ffffffffc02002b4 <best_fit_alloc_pages+0x94>
        if (p->property >= n && p->property < min_size) {
ffffffffc020024a:	ff87e703          	lwu	a4,-8(a5)
ffffffffc020024e:	00d76763          	bltu	a4,a3,ffffffffc020025c <best_fit_alloc_pages+0x3c>
ffffffffc0200252:	00b77563          	bgeu	a4,a1,ffffffffc020025c <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc0200256:	fe878513          	addi	a0,a5,-24
ffffffffc020025a:	85ba                	mv	a1,a4
ffffffffc020025c:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc020025e:	fec796e3          	bne	a5,a2,ffffffffc020024a <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc0200262:	c929                	beqz	a0,ffffffffc02002b4 <best_fit_alloc_pages+0x94>
        if (page->property > n) {
ffffffffc0200264:	01052883          	lw	a7,16(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc0200268:	6d18                	ld	a4,24(a0)
    __list_del(listelm->prev, listelm->next);
ffffffffc020026a:	710c                	ld	a1,32(a0)
ffffffffc020026c:	02089793          	slli	a5,a7,0x20
ffffffffc0200270:	9381                	srli	a5,a5,0x20
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc0200272:	e70c                	sd	a1,8(a4)
    next->prev = prev;
ffffffffc0200274:	e198                	sd	a4,0(a1)
            p->property = page->property - n;
ffffffffc0200276:	0006831b          	sext.w	t1,a3
        if (page->property > n) {
ffffffffc020027a:	02f6f563          	bgeu	a3,a5,ffffffffc02002a4 <best_fit_alloc_pages+0x84>
            struct Page *p = page + n;
ffffffffc020027e:	00269793          	slli	a5,a3,0x2
ffffffffc0200282:	97b6                	add	a5,a5,a3
ffffffffc0200284:	078e                	slli	a5,a5,0x3
ffffffffc0200286:	97aa                	add	a5,a5,a0
            SetPageProperty(p);
ffffffffc0200288:	6794                	ld	a3,8(a5)
            p->property = page->property - n;
ffffffffc020028a:	406888bb          	subw	a7,a7,t1
ffffffffc020028e:	0117a823          	sw	a7,16(a5)
            SetPageProperty(p);
ffffffffc0200292:	0026e693          	ori	a3,a3,2
ffffffffc0200296:	e794                	sd	a3,8(a5)
            list_add(prev, &(p->page_link));
ffffffffc0200298:	01878693          	addi	a3,a5,24
    prev->next = next->prev = elm;
ffffffffc020029c:	e194                	sd	a3,0(a1)
ffffffffc020029e:	e714                	sd	a3,8(a4)
    elm->next = next;
ffffffffc02002a0:	f38c                	sd	a1,32(a5)
    elm->prev = prev;
ffffffffc02002a2:	ef98                	sd	a4,24(a5)
        ClearPageProperty(page);
ffffffffc02002a4:	651c                	ld	a5,8(a0)
        nr_free -= n;
ffffffffc02002a6:	4068083b          	subw	a6,a6,t1
ffffffffc02002aa:	01062823          	sw	a6,16(a2)
        ClearPageProperty(page);
ffffffffc02002ae:	9bf5                	andi	a5,a5,-3
ffffffffc02002b0:	e51c                	sd	a5,8(a0)
ffffffffc02002b2:	8082                	ret
}
ffffffffc02002b4:	8082                	ret
        return NULL;
ffffffffc02002b6:	4501                	li	a0,0
ffffffffc02002b8:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc02002ba:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc02002bc:	00001697          	auipc	a3,0x1
ffffffffc02002c0:	03468693          	addi	a3,a3,52 # ffffffffc02012f0 <etext+0x112>
ffffffffc02002c4:	00001617          	auipc	a2,0x1
ffffffffc02002c8:	03460613          	addi	a2,a2,52 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02002cc:	06300593          	li	a1,99
ffffffffc02002d0:	00001517          	auipc	a0,0x1
ffffffffc02002d4:	04050513          	addi	a0,a0,64 # ffffffffc0201310 <etext+0x132>
best_fit_alloc_pages(size_t n) {
ffffffffc02002d8:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc02002da:	ecdff0ef          	jal	ra,ffffffffc02001a6 <__panic>

ffffffffc02002de <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc02002de:	715d                	addi	sp,sp,-80
ffffffffc02002e0:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc02002e2:	00005417          	auipc	s0,0x5
ffffffffc02002e6:	d2640413          	addi	s0,s0,-730 # ffffffffc0205008 <free_area>
ffffffffc02002ea:	641c                	ld	a5,8(s0)
ffffffffc02002ec:	e486                	sd	ra,72(sp)
ffffffffc02002ee:	fc26                	sd	s1,56(sp)
ffffffffc02002f0:	f84a                	sd	s2,48(sp)
ffffffffc02002f2:	f44e                	sd	s3,40(sp)
ffffffffc02002f4:	f052                	sd	s4,32(sp)
ffffffffc02002f6:	ec56                	sd	s5,24(sp)
ffffffffc02002f8:	e85a                	sd	s6,16(sp)
ffffffffc02002fa:	e45e                	sd	s7,8(sp)
ffffffffc02002fc:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc02002fe:	26878963          	beq	a5,s0,ffffffffc0200570 <best_fit_check+0x292>
    int count = 0, total = 0;
ffffffffc0200302:	4481                	li	s1,0
ffffffffc0200304:	4901                	li	s2,0
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200306:	ff07b703          	ld	a4,-16(a5)
ffffffffc020030a:	8b09                	andi	a4,a4,2
ffffffffc020030c:	26070663          	beqz	a4,ffffffffc0200578 <best_fit_check+0x29a>
        count ++, total += p->property;
ffffffffc0200310:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200314:	679c                	ld	a5,8(a5)
ffffffffc0200316:	2905                	addiw	s2,s2,1
ffffffffc0200318:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020031a:	fe8796e3          	bne	a5,s0,ffffffffc0200306 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020031e:	89a6                	mv	s3,s1
ffffffffc0200320:	0ff000ef          	jal	ra,ffffffffc0200c1e <nr_free_pages>
ffffffffc0200324:	33351a63          	bne	a0,s3,ffffffffc0200658 <best_fit_check+0x37a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200328:	4505                	li	a0,1
ffffffffc020032a:	0dd000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc020032e:	8a2a                	mv	s4,a0
ffffffffc0200330:	36050463          	beqz	a0,ffffffffc0200698 <best_fit_check+0x3ba>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200334:	4505                	li	a0,1
ffffffffc0200336:	0d1000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc020033a:	89aa                	mv	s3,a0
ffffffffc020033c:	32050e63          	beqz	a0,ffffffffc0200678 <best_fit_check+0x39a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200340:	4505                	li	a0,1
ffffffffc0200342:	0c5000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200346:	8aaa                	mv	s5,a0
ffffffffc0200348:	2c050863          	beqz	a0,ffffffffc0200618 <best_fit_check+0x33a>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc020034c:	253a0663          	beq	s4,s3,ffffffffc0200598 <best_fit_check+0x2ba>
ffffffffc0200350:	24aa0463          	beq	s4,a0,ffffffffc0200598 <best_fit_check+0x2ba>
ffffffffc0200354:	24a98263          	beq	s3,a0,ffffffffc0200598 <best_fit_check+0x2ba>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200358:	000a2783          	lw	a5,0(s4)
ffffffffc020035c:	24079e63          	bnez	a5,ffffffffc02005b8 <best_fit_check+0x2da>
ffffffffc0200360:	0009a783          	lw	a5,0(s3)
ffffffffc0200364:	24079a63          	bnez	a5,ffffffffc02005b8 <best_fit_check+0x2da>
ffffffffc0200368:	411c                	lw	a5,0(a0)
ffffffffc020036a:	24079763          	bnez	a5,ffffffffc02005b8 <best_fit_check+0x2da>
*/
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

ffffffffc020036e:	00005797          	auipc	a5,0x5
ffffffffc0200372:	cc27b783          	ld	a5,-830(a5) # ffffffffc0205030 <pages>
ffffffffc0200376:	40fa0733          	sub	a4,s4,a5
ffffffffc020037a:	870d                	srai	a4,a4,0x3
ffffffffc020037c:	00001597          	auipc	a1,0x1
ffffffffc0200380:	6645b583          	ld	a1,1636(a1) # ffffffffc02019e0 <error_string+0x38>
ffffffffc0200384:	02b70733          	mul	a4,a4,a1
ffffffffc0200388:	00001617          	auipc	a2,0x1
ffffffffc020038c:	66063603          	ld	a2,1632(a2) # ffffffffc02019e8 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200390:	00005697          	auipc	a3,0x5
ffffffffc0200394:	c986b683          	ld	a3,-872(a3) # ffffffffc0205028 <npage>
ffffffffc0200398:	06b2                	slli	a3,a3,0xc
ffffffffc020039a:	9732                	add	a4,a4,a2
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }

static inline uintptr_t page2pa(struct Page *page) {
ffffffffc020039c:	0732                	slli	a4,a4,0xc
ffffffffc020039e:	22d77d63          	bgeu	a4,a3,ffffffffc02005d8 <best_fit_check+0x2fa>

ffffffffc02003a2:	40f98733          	sub	a4,s3,a5
ffffffffc02003a6:	870d                	srai	a4,a4,0x3
ffffffffc02003a8:	02b70733          	mul	a4,a4,a1
ffffffffc02003ac:	9732                	add	a4,a4,a2
static inline uintptr_t page2pa(struct Page *page) {
ffffffffc02003ae:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc02003b0:	3ed77463          	bgeu	a4,a3,ffffffffc0200798 <best_fit_check+0x4ba>

ffffffffc02003b4:	40f507b3          	sub	a5,a0,a5
ffffffffc02003b8:	878d                	srai	a5,a5,0x3
ffffffffc02003ba:	02b787b3          	mul	a5,a5,a1
ffffffffc02003be:	97b2                	add	a5,a5,a2
static inline uintptr_t page2pa(struct Page *page) {
ffffffffc02003c0:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc02003c2:	3ad7fb63          	bgeu	a5,a3,ffffffffc0200778 <best_fit_check+0x49a>
    assert(alloc_page() == NULL);
ffffffffc02003c6:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc02003c8:	00043c03          	ld	s8,0(s0)
ffffffffc02003cc:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc02003d0:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc02003d4:	e400                	sd	s0,8(s0)
ffffffffc02003d6:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc02003d8:	00005797          	auipc	a5,0x5
ffffffffc02003dc:	c407a023          	sw	zero,-960(a5) # ffffffffc0205018 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc02003e0:	027000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc02003e4:	36051a63          	bnez	a0,ffffffffc0200758 <best_fit_check+0x47a>
    free_page(p0);
ffffffffc02003e8:	4585                	li	a1,1
ffffffffc02003ea:	8552                	mv	a0,s4
ffffffffc02003ec:	027000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    free_page(p1);
ffffffffc02003f0:	4585                	li	a1,1
ffffffffc02003f2:	854e                	mv	a0,s3
ffffffffc02003f4:	01f000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    free_page(p2);
ffffffffc02003f8:	4585                	li	a1,1
ffffffffc02003fa:	8556                	mv	a0,s5
ffffffffc02003fc:	017000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    assert(nr_free == 3);
ffffffffc0200400:	4818                	lw	a4,16(s0)
ffffffffc0200402:	478d                	li	a5,3
ffffffffc0200404:	32f71a63          	bne	a4,a5,ffffffffc0200738 <best_fit_check+0x45a>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200408:	4505                	li	a0,1
ffffffffc020040a:	7fc000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc020040e:	89aa                	mv	s3,a0
ffffffffc0200410:	30050463          	beqz	a0,ffffffffc0200718 <best_fit_check+0x43a>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200414:	4505                	li	a0,1
ffffffffc0200416:	7f0000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc020041a:	8aaa                	mv	s5,a0
ffffffffc020041c:	2c050e63          	beqz	a0,ffffffffc02006f8 <best_fit_check+0x41a>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200420:	4505                	li	a0,1
ffffffffc0200422:	7e4000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200426:	8a2a                	mv	s4,a0
ffffffffc0200428:	2a050863          	beqz	a0,ffffffffc02006d8 <best_fit_check+0x3fa>
    assert(alloc_page() == NULL);
ffffffffc020042c:	4505                	li	a0,1
ffffffffc020042e:	7d8000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200432:	28051363          	bnez	a0,ffffffffc02006b8 <best_fit_check+0x3da>
    free_page(p0);
ffffffffc0200436:	4585                	li	a1,1
ffffffffc0200438:	854e                	mv	a0,s3
ffffffffc020043a:	7d8000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc020043e:	641c                	ld	a5,8(s0)
ffffffffc0200440:	1a878c63          	beq	a5,s0,ffffffffc02005f8 <best_fit_check+0x31a>
    assert((p = alloc_page()) == p0);
ffffffffc0200444:	4505                	li	a0,1
ffffffffc0200446:	7c0000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc020044a:	52a99763          	bne	s3,a0,ffffffffc0200978 <best_fit_check+0x69a>
    assert(alloc_page() == NULL);
ffffffffc020044e:	4505                	li	a0,1
ffffffffc0200450:	7b6000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200454:	50051263          	bnez	a0,ffffffffc0200958 <best_fit_check+0x67a>
    assert(nr_free == 0);
ffffffffc0200458:	481c                	lw	a5,16(s0)
ffffffffc020045a:	4c079f63          	bnez	a5,ffffffffc0200938 <best_fit_check+0x65a>
    free_page(p);
ffffffffc020045e:	854e                	mv	a0,s3
ffffffffc0200460:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200462:	01843023          	sd	s8,0(s0)
ffffffffc0200466:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc020046a:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc020046e:	7a4000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    free_page(p1);
ffffffffc0200472:	4585                	li	a1,1
ffffffffc0200474:	8556                	mv	a0,s5
ffffffffc0200476:	79c000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    free_page(p2);
ffffffffc020047a:	4585                	li	a1,1
ffffffffc020047c:	8552                	mv	a0,s4
ffffffffc020047e:	794000ef          	jal	ra,ffffffffc0200c12 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200482:	4515                	li	a0,5
ffffffffc0200484:	782000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200488:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc020048a:	48050763          	beqz	a0,ffffffffc0200918 <best_fit_check+0x63a>
    assert(!PageProperty(p0));
ffffffffc020048e:	651c                	ld	a5,8(a0)
ffffffffc0200490:	8b89                	andi	a5,a5,2
ffffffffc0200492:	46079363          	bnez	a5,ffffffffc02008f8 <best_fit_check+0x61a>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200496:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200498:	00043b03          	ld	s6,0(s0)
ffffffffc020049c:	00843a83          	ld	s5,8(s0)
ffffffffc02004a0:	e000                	sd	s0,0(s0)
ffffffffc02004a2:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc02004a4:	762000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc02004a8:	42051863          	bnez	a0,ffffffffc02008d8 <best_fit_check+0x5fa>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc02004ac:	4589                	li	a1,2
ffffffffc02004ae:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc02004b2:	01042b83          	lw	s7,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc02004b6:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc02004ba:	00005797          	auipc	a5,0x5
ffffffffc02004be:	b407af23          	sw	zero,-1186(a5) # ffffffffc0205018 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc02004c2:	750000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc02004c6:	8562                	mv	a0,s8
ffffffffc02004c8:	4585                	li	a1,1
ffffffffc02004ca:	748000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc02004ce:	4511                	li	a0,4
ffffffffc02004d0:	736000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc02004d4:	3e051263          	bnez	a0,ffffffffc02008b8 <best_fit_check+0x5da>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc02004d8:	0309b783          	ld	a5,48(s3)
ffffffffc02004dc:	8b89                	andi	a5,a5,2
ffffffffc02004de:	3a078d63          	beqz	a5,ffffffffc0200898 <best_fit_check+0x5ba>
ffffffffc02004e2:	0389a703          	lw	a4,56(s3)
ffffffffc02004e6:	4789                	li	a5,2
ffffffffc02004e8:	3af71863          	bne	a4,a5,ffffffffc0200898 <best_fit_check+0x5ba>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc02004ec:	4505                	li	a0,1
ffffffffc02004ee:	718000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc02004f2:	8a2a                	mv	s4,a0
ffffffffc02004f4:	38050263          	beqz	a0,ffffffffc0200878 <best_fit_check+0x59a>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc02004f8:	4509                	li	a0,2
ffffffffc02004fa:	70c000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc02004fe:	34050d63          	beqz	a0,ffffffffc0200858 <best_fit_check+0x57a>
    assert(p0 + 4 == p1);
ffffffffc0200502:	334c1b63          	bne	s8,s4,ffffffffc0200838 <best_fit_check+0x55a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200506:	854e                	mv	a0,s3
ffffffffc0200508:	4595                	li	a1,5
ffffffffc020050a:	708000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc020050e:	4515                	li	a0,5
ffffffffc0200510:	6f6000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200514:	89aa                	mv	s3,a0
ffffffffc0200516:	30050163          	beqz	a0,ffffffffc0200818 <best_fit_check+0x53a>
    assert(alloc_page() == NULL);
ffffffffc020051a:	4505                	li	a0,1
ffffffffc020051c:	6ea000ef          	jal	ra,ffffffffc0200c06 <alloc_pages>
ffffffffc0200520:	2c051c63          	bnez	a0,ffffffffc02007f8 <best_fit_check+0x51a>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200524:	481c                	lw	a5,16(s0)
ffffffffc0200526:	2a079963          	bnez	a5,ffffffffc02007d8 <best_fit_check+0x4fa>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc020052a:	4595                	li	a1,5
ffffffffc020052c:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc020052e:	01742823          	sw	s7,16(s0)
    free_list = free_list_store;
ffffffffc0200532:	01643023          	sd	s6,0(s0)
ffffffffc0200536:	01543423          	sd	s5,8(s0)
    free_pages(p0, 5);
ffffffffc020053a:	6d8000ef          	jal	ra,ffffffffc0200c12 <free_pages>
    return listelm->next;
ffffffffc020053e:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200540:	00878963          	beq	a5,s0,ffffffffc0200552 <best_fit_check+0x274>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200544:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200548:	679c                	ld	a5,8(a5)
ffffffffc020054a:	397d                	addiw	s2,s2,-1
ffffffffc020054c:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc020054e:	fe879be3          	bne	a5,s0,ffffffffc0200544 <best_fit_check+0x266>
    }
    assert(count == 0);
ffffffffc0200552:	26091363          	bnez	s2,ffffffffc02007b8 <best_fit_check+0x4da>
    assert(total == 0);
ffffffffc0200556:	e0ed                	bnez	s1,ffffffffc0200638 <best_fit_check+0x35a>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200558:	60a6                	ld	ra,72(sp)
ffffffffc020055a:	6406                	ld	s0,64(sp)
ffffffffc020055c:	74e2                	ld	s1,56(sp)
ffffffffc020055e:	7942                	ld	s2,48(sp)
ffffffffc0200560:	79a2                	ld	s3,40(sp)
ffffffffc0200562:	7a02                	ld	s4,32(sp)
ffffffffc0200564:	6ae2                	ld	s5,24(sp)
ffffffffc0200566:	6b42                	ld	s6,16(sp)
ffffffffc0200568:	6ba2                	ld	s7,8(sp)
ffffffffc020056a:	6c02                	ld	s8,0(sp)
ffffffffc020056c:	6161                	addi	sp,sp,80
ffffffffc020056e:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200570:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200572:	4481                	li	s1,0
ffffffffc0200574:	4901                	li	s2,0
ffffffffc0200576:	b36d                	j	ffffffffc0200320 <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200578:	00001697          	auipc	a3,0x1
ffffffffc020057c:	db068693          	addi	a3,a3,-592 # ffffffffc0201328 <etext+0x14a>
ffffffffc0200580:	00001617          	auipc	a2,0x1
ffffffffc0200584:	d7860613          	addi	a2,a2,-648 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200588:	0f500593          	li	a1,245
ffffffffc020058c:	00001517          	auipc	a0,0x1
ffffffffc0200590:	d8450513          	addi	a0,a0,-636 # ffffffffc0201310 <etext+0x132>
ffffffffc0200594:	c13ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200598:	00001697          	auipc	a3,0x1
ffffffffc020059c:	e2068693          	addi	a3,a3,-480 # ffffffffc02013b8 <etext+0x1da>
ffffffffc02005a0:	00001617          	auipc	a2,0x1
ffffffffc02005a4:	d5860613          	addi	a2,a2,-680 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02005a8:	0c100593          	li	a1,193
ffffffffc02005ac:	00001517          	auipc	a0,0x1
ffffffffc02005b0:	d6450513          	addi	a0,a0,-668 # ffffffffc0201310 <etext+0x132>
ffffffffc02005b4:	bf3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02005b8:	00001697          	auipc	a3,0x1
ffffffffc02005bc:	e2868693          	addi	a3,a3,-472 # ffffffffc02013e0 <etext+0x202>
ffffffffc02005c0:	00001617          	auipc	a2,0x1
ffffffffc02005c4:	d3860613          	addi	a2,a2,-712 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02005c8:	0c200593          	li	a1,194
ffffffffc02005cc:	00001517          	auipc	a0,0x1
ffffffffc02005d0:	d4450513          	addi	a0,a0,-700 # ffffffffc0201310 <etext+0x132>
ffffffffc02005d4:	bd3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02005d8:	00001697          	auipc	a3,0x1
ffffffffc02005dc:	e4868693          	addi	a3,a3,-440 # ffffffffc0201420 <etext+0x242>
ffffffffc02005e0:	00001617          	auipc	a2,0x1
ffffffffc02005e4:	d1860613          	addi	a2,a2,-744 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02005e8:	0c400593          	li	a1,196
ffffffffc02005ec:	00001517          	auipc	a0,0x1
ffffffffc02005f0:	d2450513          	addi	a0,a0,-732 # ffffffffc0201310 <etext+0x132>
ffffffffc02005f4:	bb3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(!list_empty(&free_list));
ffffffffc02005f8:	00001697          	auipc	a3,0x1
ffffffffc02005fc:	eb068693          	addi	a3,a3,-336 # ffffffffc02014a8 <etext+0x2ca>
ffffffffc0200600:	00001617          	auipc	a2,0x1
ffffffffc0200604:	cf860613          	addi	a2,a2,-776 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200608:	0dd00593          	li	a1,221
ffffffffc020060c:	00001517          	auipc	a0,0x1
ffffffffc0200610:	d0450513          	addi	a0,a0,-764 # ffffffffc0201310 <etext+0x132>
ffffffffc0200614:	b93ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200618:	00001697          	auipc	a3,0x1
ffffffffc020061c:	d8068693          	addi	a3,a3,-640 # ffffffffc0201398 <etext+0x1ba>
ffffffffc0200620:	00001617          	auipc	a2,0x1
ffffffffc0200624:	cd860613          	addi	a2,a2,-808 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200628:	0bf00593          	li	a1,191
ffffffffc020062c:	00001517          	auipc	a0,0x1
ffffffffc0200630:	ce450513          	addi	a0,a0,-796 # ffffffffc0201310 <etext+0x132>
ffffffffc0200634:	b73ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(total == 0);
ffffffffc0200638:	00001697          	auipc	a3,0x1
ffffffffc020063c:	fa068693          	addi	a3,a3,-96 # ffffffffc02015d8 <etext+0x3fa>
ffffffffc0200640:	00001617          	auipc	a2,0x1
ffffffffc0200644:	cb860613          	addi	a2,a2,-840 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200648:	13700593          	li	a1,311
ffffffffc020064c:	00001517          	auipc	a0,0x1
ffffffffc0200650:	cc450513          	addi	a0,a0,-828 # ffffffffc0201310 <etext+0x132>
ffffffffc0200654:	b53ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200658:	00001697          	auipc	a3,0x1
ffffffffc020065c:	ce068693          	addi	a3,a3,-800 # ffffffffc0201338 <etext+0x15a>
ffffffffc0200660:	00001617          	auipc	a2,0x1
ffffffffc0200664:	c9860613          	addi	a2,a2,-872 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200668:	0f800593          	li	a1,248
ffffffffc020066c:	00001517          	auipc	a0,0x1
ffffffffc0200670:	ca450513          	addi	a0,a0,-860 # ffffffffc0201310 <etext+0x132>
ffffffffc0200674:	b33ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200678:	00001697          	auipc	a3,0x1
ffffffffc020067c:	d0068693          	addi	a3,a3,-768 # ffffffffc0201378 <etext+0x19a>
ffffffffc0200680:	00001617          	auipc	a2,0x1
ffffffffc0200684:	c7860613          	addi	a2,a2,-904 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200688:	0be00593          	li	a1,190
ffffffffc020068c:	00001517          	auipc	a0,0x1
ffffffffc0200690:	c8450513          	addi	a0,a0,-892 # ffffffffc0201310 <etext+0x132>
ffffffffc0200694:	b13ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200698:	00001697          	auipc	a3,0x1
ffffffffc020069c:	cc068693          	addi	a3,a3,-832 # ffffffffc0201358 <etext+0x17a>
ffffffffc02006a0:	00001617          	auipc	a2,0x1
ffffffffc02006a4:	c5860613          	addi	a2,a2,-936 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02006a8:	0bd00593          	li	a1,189
ffffffffc02006ac:	00001517          	auipc	a0,0x1
ffffffffc02006b0:	c6450513          	addi	a0,a0,-924 # ffffffffc0201310 <etext+0x132>
ffffffffc02006b4:	af3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02006b8:	00001697          	auipc	a3,0x1
ffffffffc02006bc:	dc868693          	addi	a3,a3,-568 # ffffffffc0201480 <etext+0x2a2>
ffffffffc02006c0:	00001617          	auipc	a2,0x1
ffffffffc02006c4:	c3860613          	addi	a2,a2,-968 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02006c8:	0da00593          	li	a1,218
ffffffffc02006cc:	00001517          	auipc	a0,0x1
ffffffffc02006d0:	c4450513          	addi	a0,a0,-956 # ffffffffc0201310 <etext+0x132>
ffffffffc02006d4:	ad3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02006d8:	00001697          	auipc	a3,0x1
ffffffffc02006dc:	cc068693          	addi	a3,a3,-832 # ffffffffc0201398 <etext+0x1ba>
ffffffffc02006e0:	00001617          	auipc	a2,0x1
ffffffffc02006e4:	c1860613          	addi	a2,a2,-1000 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02006e8:	0d800593          	li	a1,216
ffffffffc02006ec:	00001517          	auipc	a0,0x1
ffffffffc02006f0:	c2450513          	addi	a0,a0,-988 # ffffffffc0201310 <etext+0x132>
ffffffffc02006f4:	ab3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02006f8:	00001697          	auipc	a3,0x1
ffffffffc02006fc:	c8068693          	addi	a3,a3,-896 # ffffffffc0201378 <etext+0x19a>
ffffffffc0200700:	00001617          	auipc	a2,0x1
ffffffffc0200704:	bf860613          	addi	a2,a2,-1032 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200708:	0d700593          	li	a1,215
ffffffffc020070c:	00001517          	auipc	a0,0x1
ffffffffc0200710:	c0450513          	addi	a0,a0,-1020 # ffffffffc0201310 <etext+0x132>
ffffffffc0200714:	a93ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200718:	00001697          	auipc	a3,0x1
ffffffffc020071c:	c4068693          	addi	a3,a3,-960 # ffffffffc0201358 <etext+0x17a>
ffffffffc0200720:	00001617          	auipc	a2,0x1
ffffffffc0200724:	bd860613          	addi	a2,a2,-1064 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200728:	0d600593          	li	a1,214
ffffffffc020072c:	00001517          	auipc	a0,0x1
ffffffffc0200730:	be450513          	addi	a0,a0,-1052 # ffffffffc0201310 <etext+0x132>
ffffffffc0200734:	a73ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(nr_free == 3);
ffffffffc0200738:	00001697          	auipc	a3,0x1
ffffffffc020073c:	d6068693          	addi	a3,a3,-672 # ffffffffc0201498 <etext+0x2ba>
ffffffffc0200740:	00001617          	auipc	a2,0x1
ffffffffc0200744:	bb860613          	addi	a2,a2,-1096 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200748:	0d400593          	li	a1,212
ffffffffc020074c:	00001517          	auipc	a0,0x1
ffffffffc0200750:	bc450513          	addi	a0,a0,-1084 # ffffffffc0201310 <etext+0x132>
ffffffffc0200754:	a53ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200758:	00001697          	auipc	a3,0x1
ffffffffc020075c:	d2868693          	addi	a3,a3,-728 # ffffffffc0201480 <etext+0x2a2>
ffffffffc0200760:	00001617          	auipc	a2,0x1
ffffffffc0200764:	b9860613          	addi	a2,a2,-1128 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200768:	0cf00593          	li	a1,207
ffffffffc020076c:	00001517          	auipc	a0,0x1
ffffffffc0200770:	ba450513          	addi	a0,a0,-1116 # ffffffffc0201310 <etext+0x132>
ffffffffc0200774:	a33ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200778:	00001697          	auipc	a3,0x1
ffffffffc020077c:	ce868693          	addi	a3,a3,-792 # ffffffffc0201460 <etext+0x282>
ffffffffc0200780:	00001617          	auipc	a2,0x1
ffffffffc0200784:	b7860613          	addi	a2,a2,-1160 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200788:	0c600593          	li	a1,198
ffffffffc020078c:	00001517          	auipc	a0,0x1
ffffffffc0200790:	b8450513          	addi	a0,a0,-1148 # ffffffffc0201310 <etext+0x132>
ffffffffc0200794:	a13ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200798:	00001697          	auipc	a3,0x1
ffffffffc020079c:	ca868693          	addi	a3,a3,-856 # ffffffffc0201440 <etext+0x262>
ffffffffc02007a0:	00001617          	auipc	a2,0x1
ffffffffc02007a4:	b5860613          	addi	a2,a2,-1192 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02007a8:	0c500593          	li	a1,197
ffffffffc02007ac:	00001517          	auipc	a0,0x1
ffffffffc02007b0:	b6450513          	addi	a0,a0,-1180 # ffffffffc0201310 <etext+0x132>
ffffffffc02007b4:	9f3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(count == 0);
ffffffffc02007b8:	00001697          	auipc	a3,0x1
ffffffffc02007bc:	e1068693          	addi	a3,a3,-496 # ffffffffc02015c8 <etext+0x3ea>
ffffffffc02007c0:	00001617          	auipc	a2,0x1
ffffffffc02007c4:	b3860613          	addi	a2,a2,-1224 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02007c8:	13600593          	li	a1,310
ffffffffc02007cc:	00001517          	auipc	a0,0x1
ffffffffc02007d0:	b4450513          	addi	a0,a0,-1212 # ffffffffc0201310 <etext+0x132>
ffffffffc02007d4:	9d3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(nr_free == 0);
ffffffffc02007d8:	00001697          	auipc	a3,0x1
ffffffffc02007dc:	d0868693          	addi	a3,a3,-760 # ffffffffc02014e0 <etext+0x302>
ffffffffc02007e0:	00001617          	auipc	a2,0x1
ffffffffc02007e4:	b1860613          	addi	a2,a2,-1256 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02007e8:	12b00593          	li	a1,299
ffffffffc02007ec:	00001517          	auipc	a0,0x1
ffffffffc02007f0:	b2450513          	addi	a0,a0,-1244 # ffffffffc0201310 <etext+0x132>
ffffffffc02007f4:	9b3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02007f8:	00001697          	auipc	a3,0x1
ffffffffc02007fc:	c8868693          	addi	a3,a3,-888 # ffffffffc0201480 <etext+0x2a2>
ffffffffc0200800:	00001617          	auipc	a2,0x1
ffffffffc0200804:	af860613          	addi	a2,a2,-1288 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200808:	12500593          	li	a1,293
ffffffffc020080c:	00001517          	auipc	a0,0x1
ffffffffc0200810:	b0450513          	addi	a0,a0,-1276 # ffffffffc0201310 <etext+0x132>
ffffffffc0200814:	993ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200818:	00001697          	auipc	a3,0x1
ffffffffc020081c:	d9068693          	addi	a3,a3,-624 # ffffffffc02015a8 <etext+0x3ca>
ffffffffc0200820:	00001617          	auipc	a2,0x1
ffffffffc0200824:	ad860613          	addi	a2,a2,-1320 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200828:	12400593          	li	a1,292
ffffffffc020082c:	00001517          	auipc	a0,0x1
ffffffffc0200830:	ae450513          	addi	a0,a0,-1308 # ffffffffc0201310 <etext+0x132>
ffffffffc0200834:	973ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200838:	00001697          	auipc	a3,0x1
ffffffffc020083c:	d6068693          	addi	a3,a3,-672 # ffffffffc0201598 <etext+0x3ba>
ffffffffc0200840:	00001617          	auipc	a2,0x1
ffffffffc0200844:	ab860613          	addi	a2,a2,-1352 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200848:	11c00593          	li	a1,284
ffffffffc020084c:	00001517          	auipc	a0,0x1
ffffffffc0200850:	ac450513          	addi	a0,a0,-1340 # ffffffffc0201310 <etext+0x132>
ffffffffc0200854:	953ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200858:	00001697          	auipc	a3,0x1
ffffffffc020085c:	d2868693          	addi	a3,a3,-728 # ffffffffc0201580 <etext+0x3a2>
ffffffffc0200860:	00001617          	auipc	a2,0x1
ffffffffc0200864:	a9860613          	addi	a2,a2,-1384 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200868:	11b00593          	li	a1,283
ffffffffc020086c:	00001517          	auipc	a0,0x1
ffffffffc0200870:	aa450513          	addi	a0,a0,-1372 # ffffffffc0201310 <etext+0x132>
ffffffffc0200874:	933ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200878:	00001697          	auipc	a3,0x1
ffffffffc020087c:	ce868693          	addi	a3,a3,-792 # ffffffffc0201560 <etext+0x382>
ffffffffc0200880:	00001617          	auipc	a2,0x1
ffffffffc0200884:	a7860613          	addi	a2,a2,-1416 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200888:	11a00593          	li	a1,282
ffffffffc020088c:	00001517          	auipc	a0,0x1
ffffffffc0200890:	a8450513          	addi	a0,a0,-1404 # ffffffffc0201310 <etext+0x132>
ffffffffc0200894:	913ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200898:	00001697          	auipc	a3,0x1
ffffffffc020089c:	c9868693          	addi	a3,a3,-872 # ffffffffc0201530 <etext+0x352>
ffffffffc02008a0:	00001617          	auipc	a2,0x1
ffffffffc02008a4:	a5860613          	addi	a2,a2,-1448 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02008a8:	11800593          	li	a1,280
ffffffffc02008ac:	00001517          	auipc	a0,0x1
ffffffffc02008b0:	a6450513          	addi	a0,a0,-1436 # ffffffffc0201310 <etext+0x132>
ffffffffc02008b4:	8f3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc02008b8:	00001697          	auipc	a3,0x1
ffffffffc02008bc:	c6068693          	addi	a3,a3,-928 # ffffffffc0201518 <etext+0x33a>
ffffffffc02008c0:	00001617          	auipc	a2,0x1
ffffffffc02008c4:	a3860613          	addi	a2,a2,-1480 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02008c8:	11700593          	li	a1,279
ffffffffc02008cc:	00001517          	auipc	a0,0x1
ffffffffc02008d0:	a4450513          	addi	a0,a0,-1468 # ffffffffc0201310 <etext+0x132>
ffffffffc02008d4:	8d3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc02008d8:	00001697          	auipc	a3,0x1
ffffffffc02008dc:	ba868693          	addi	a3,a3,-1112 # ffffffffc0201480 <etext+0x2a2>
ffffffffc02008e0:	00001617          	auipc	a2,0x1
ffffffffc02008e4:	a1860613          	addi	a2,a2,-1512 # ffffffffc02012f8 <etext+0x11a>
ffffffffc02008e8:	10b00593          	li	a1,267
ffffffffc02008ec:	00001517          	auipc	a0,0x1
ffffffffc02008f0:	a2450513          	addi	a0,a0,-1500 # ffffffffc0201310 <etext+0x132>
ffffffffc02008f4:	8b3ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(!PageProperty(p0));
ffffffffc02008f8:	00001697          	auipc	a3,0x1
ffffffffc02008fc:	c0868693          	addi	a3,a3,-1016 # ffffffffc0201500 <etext+0x322>
ffffffffc0200900:	00001617          	auipc	a2,0x1
ffffffffc0200904:	9f860613          	addi	a2,a2,-1544 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200908:	10200593          	li	a1,258
ffffffffc020090c:	00001517          	auipc	a0,0x1
ffffffffc0200910:	a0450513          	addi	a0,a0,-1532 # ffffffffc0201310 <etext+0x132>
ffffffffc0200914:	893ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(p0 != NULL);
ffffffffc0200918:	00001697          	auipc	a3,0x1
ffffffffc020091c:	bd868693          	addi	a3,a3,-1064 # ffffffffc02014f0 <etext+0x312>
ffffffffc0200920:	00001617          	auipc	a2,0x1
ffffffffc0200924:	9d860613          	addi	a2,a2,-1576 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200928:	10100593          	li	a1,257
ffffffffc020092c:	00001517          	auipc	a0,0x1
ffffffffc0200930:	9e450513          	addi	a0,a0,-1564 # ffffffffc0201310 <etext+0x132>
ffffffffc0200934:	873ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(nr_free == 0);
ffffffffc0200938:	00001697          	auipc	a3,0x1
ffffffffc020093c:	ba868693          	addi	a3,a3,-1112 # ffffffffc02014e0 <etext+0x302>
ffffffffc0200940:	00001617          	auipc	a2,0x1
ffffffffc0200944:	9b860613          	addi	a2,a2,-1608 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200948:	0e300593          	li	a1,227
ffffffffc020094c:	00001517          	auipc	a0,0x1
ffffffffc0200950:	9c450513          	addi	a0,a0,-1596 # ffffffffc0201310 <etext+0x132>
ffffffffc0200954:	853ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200958:	00001697          	auipc	a3,0x1
ffffffffc020095c:	b2868693          	addi	a3,a3,-1240 # ffffffffc0201480 <etext+0x2a2>
ffffffffc0200960:	00001617          	auipc	a2,0x1
ffffffffc0200964:	99860613          	addi	a2,a2,-1640 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200968:	0e100593          	li	a1,225
ffffffffc020096c:	00001517          	auipc	a0,0x1
ffffffffc0200970:	9a450513          	addi	a0,a0,-1628 # ffffffffc0201310 <etext+0x132>
ffffffffc0200974:	833ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200978:	00001697          	auipc	a3,0x1
ffffffffc020097c:	b4868693          	addi	a3,a3,-1208 # ffffffffc02014c0 <etext+0x2e2>
ffffffffc0200980:	00001617          	auipc	a2,0x1
ffffffffc0200984:	97860613          	addi	a2,a2,-1672 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200988:	0e000593          	li	a1,224
ffffffffc020098c:	00001517          	auipc	a0,0x1
ffffffffc0200990:	98450513          	addi	a0,a0,-1660 # ffffffffc0201310 <etext+0x132>
ffffffffc0200994:	813ff0ef          	jal	ra,ffffffffc02001a6 <__panic>

ffffffffc0200998 <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc0200998:	1141                	addi	sp,sp,-16
ffffffffc020099a:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020099c:	14058c63          	beqz	a1,ffffffffc0200af4 <best_fit_free_pages+0x15c>
    for (; p != base + n; p ++) {
ffffffffc02009a0:	00259693          	slli	a3,a1,0x2
ffffffffc02009a4:	96ae                	add	a3,a3,a1
ffffffffc02009a6:	068e                	slli	a3,a3,0x3
ffffffffc02009a8:	96aa                	add	a3,a3,a0
ffffffffc02009aa:	87aa                	mv	a5,a0
ffffffffc02009ac:	00d50e63          	beq	a0,a3,ffffffffc02009c8 <best_fit_free_pages+0x30>
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc02009b0:	6798                	ld	a4,8(a5)
ffffffffc02009b2:	8b0d                	andi	a4,a4,3
ffffffffc02009b4:	12071063          	bnez	a4,ffffffffc0200ad4 <best_fit_free_pages+0x13c>
        p->flags = 0;
ffffffffc02009b8:	0007b423          	sd	zero,8(a5)
}



static inline int page_ref(struct Page *page) { return page->ref; }

ffffffffc02009bc:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02009c0:	02878793          	addi	a5,a5,40
ffffffffc02009c4:	fed796e3          	bne	a5,a3,ffffffffc02009b0 <best_fit_free_pages+0x18>
    SetPageProperty(base);
ffffffffc02009c8:	00853883          	ld	a7,8(a0)
    nr_free += n;
ffffffffc02009cc:	00004697          	auipc	a3,0x4
ffffffffc02009d0:	63c68693          	addi	a3,a3,1596 # ffffffffc0205008 <free_area>
ffffffffc02009d4:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc02009d6:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc02009d8:	0028e613          	ori	a2,a7,2
    return list->next == list;
ffffffffc02009dc:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc02009de:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc02009e0:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc02009e2:	9f2d                	addw	a4,a4,a1
ffffffffc02009e4:	ca98                	sw	a4,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02009e6:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc02009ea:	0ad78b63          	beq	a5,a3,ffffffffc0200aa0 <best_fit_free_pages+0x108>
            struct Page* page = le2page(le, page_link);
ffffffffc02009ee:	fe878713          	addi	a4,a5,-24
ffffffffc02009f2:	0006b303          	ld	t1,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02009f6:	4801                	li	a6,0
            if (base < page) {
ffffffffc02009f8:	00e56a63          	bltu	a0,a4,ffffffffc0200a0c <best_fit_free_pages+0x74>
    return listelm->next;
ffffffffc02009fc:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02009fe:	06d70563          	beq	a4,a3,ffffffffc0200a68 <best_fit_free_pages+0xd0>
    for (; p != base + n; p ++) {
ffffffffc0200a02:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200a04:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200a08:	fee57ae3          	bgeu	a0,a4,ffffffffc02009fc <best_fit_free_pages+0x64>
ffffffffc0200a0c:	00080463          	beqz	a6,ffffffffc0200a14 <best_fit_free_pages+0x7c>
ffffffffc0200a10:	0066b023          	sd	t1,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200a14:	0007b803          	ld	a6,0(a5)
    prev->next = next->prev = elm;
ffffffffc0200a18:	e390                	sd	a2,0(a5)
ffffffffc0200a1a:	00c83423          	sd	a2,8(a6)
    elm->next = next;
ffffffffc0200a1e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200a20:	01053c23          	sd	a6,24(a0)
    if (le != &free_list) {
ffffffffc0200a24:	02d80463          	beq	a6,a3,ffffffffc0200a4c <best_fit_free_pages+0xb4>
        if (p + p->property == base) {
ffffffffc0200a28:	ff882e03          	lw	t3,-8(a6)
        p = le2page(le, page_link);
ffffffffc0200a2c:	fe880313          	addi	t1,a6,-24
        if (p + p->property == base) {
ffffffffc0200a30:	020e1613          	slli	a2,t3,0x20
ffffffffc0200a34:	9201                	srli	a2,a2,0x20
ffffffffc0200a36:	00261713          	slli	a4,a2,0x2
ffffffffc0200a3a:	9732                	add	a4,a4,a2
ffffffffc0200a3c:	070e                	slli	a4,a4,0x3
ffffffffc0200a3e:	971a                	add	a4,a4,t1
ffffffffc0200a40:	02e50e63          	beq	a0,a4,ffffffffc0200a7c <best_fit_free_pages+0xe4>
    if (le != &free_list) {
ffffffffc0200a44:	00d78f63          	beq	a5,a3,ffffffffc0200a62 <best_fit_free_pages+0xca>
ffffffffc0200a48:	fe878713          	addi	a4,a5,-24
        if (base + base->property == p) {
ffffffffc0200a4c:	490c                	lw	a1,16(a0)
ffffffffc0200a4e:	02059613          	slli	a2,a1,0x20
ffffffffc0200a52:	9201                	srli	a2,a2,0x20
ffffffffc0200a54:	00261693          	slli	a3,a2,0x2
ffffffffc0200a58:	96b2                	add	a3,a3,a2
ffffffffc0200a5a:	068e                	slli	a3,a3,0x3
ffffffffc0200a5c:	96aa                	add	a3,a3,a0
ffffffffc0200a5e:	04d70863          	beq	a4,a3,ffffffffc0200aae <best_fit_free_pages+0x116>
}
ffffffffc0200a62:	60a2                	ld	ra,8(sp)
ffffffffc0200a64:	0141                	addi	sp,sp,16
ffffffffc0200a66:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200a68:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200a6a:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200a6c:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200a6e:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200a70:	02d70463          	beq	a4,a3,ffffffffc0200a98 <best_fit_free_pages+0x100>
    prev->next = next->prev = elm;
ffffffffc0200a74:	8332                	mv	t1,a2
ffffffffc0200a76:	4805                	li	a6,1
    for (; p != base + n; p ++) {
ffffffffc0200a78:	87ba                	mv	a5,a4
ffffffffc0200a7a:	b769                	j	ffffffffc0200a04 <best_fit_free_pages+0x6c>
            p->property += base->property;
ffffffffc0200a7c:	01c585bb          	addw	a1,a1,t3
ffffffffc0200a80:	feb82c23          	sw	a1,-8(a6)
            ClearPageProperty(base);
ffffffffc0200a84:	ffd8f893          	andi	a7,a7,-3
ffffffffc0200a88:	01153423          	sd	a7,8(a0)
    prev->next = next;
ffffffffc0200a8c:	00f83423          	sd	a5,8(a6)
    next->prev = prev;
ffffffffc0200a90:	0107b023          	sd	a6,0(a5)
            base = p;
ffffffffc0200a94:	851a                	mv	a0,t1
ffffffffc0200a96:	b77d                	j	ffffffffc0200a44 <best_fit_free_pages+0xac>
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200a98:	883e                	mv	a6,a5
ffffffffc0200a9a:	e290                	sd	a2,0(a3)
ffffffffc0200a9c:	87b6                	mv	a5,a3
ffffffffc0200a9e:	b769                	j	ffffffffc0200a28 <best_fit_free_pages+0x90>
}
ffffffffc0200aa0:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200aa2:	e390                	sd	a2,0(a5)
ffffffffc0200aa4:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200aa6:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200aa8:	ed1c                	sd	a5,24(a0)
ffffffffc0200aaa:	0141                	addi	sp,sp,16
ffffffffc0200aac:	8082                	ret
            base->property += p->property;
ffffffffc0200aae:	ff87a683          	lw	a3,-8(a5)
            ClearPageProperty(p);
ffffffffc0200ab2:	ff07b703          	ld	a4,-16(a5)
    __list_del(listelm->prev, listelm->next);
ffffffffc0200ab6:	0007b803          	ld	a6,0(a5)
ffffffffc0200aba:	6790                	ld	a2,8(a5)
            base->property += p->property;
ffffffffc0200abc:	9db5                	addw	a1,a1,a3
ffffffffc0200abe:	c90c                	sw	a1,16(a0)
            ClearPageProperty(p);
ffffffffc0200ac0:	9b75                	andi	a4,a4,-3
ffffffffc0200ac2:	fee7b823          	sd	a4,-16(a5)
}
ffffffffc0200ac6:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc0200ac8:	00c83423          	sd	a2,8(a6)
    next->prev = prev;
ffffffffc0200acc:	01063023          	sd	a6,0(a2)
ffffffffc0200ad0:	0141                	addi	sp,sp,16
ffffffffc0200ad2:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0200ad4:	00001697          	auipc	a3,0x1
ffffffffc0200ad8:	b1468693          	addi	a3,a3,-1260 # ffffffffc02015e8 <etext+0x40a>
ffffffffc0200adc:	00001617          	auipc	a2,0x1
ffffffffc0200ae0:	81c60613          	addi	a2,a2,-2020 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200ae4:	08700593          	li	a1,135
ffffffffc0200ae8:	00001517          	auipc	a0,0x1
ffffffffc0200aec:	82850513          	addi	a0,a0,-2008 # ffffffffc0201310 <etext+0x132>
ffffffffc0200af0:	eb6ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(n > 0);
ffffffffc0200af4:	00000697          	auipc	a3,0x0
ffffffffc0200af8:	7fc68693          	addi	a3,a3,2044 # ffffffffc02012f0 <etext+0x112>
ffffffffc0200afc:	00000617          	auipc	a2,0x0
ffffffffc0200b00:	7fc60613          	addi	a2,a2,2044 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200b04:	08400593          	li	a1,132
ffffffffc0200b08:	00001517          	auipc	a0,0x1
ffffffffc0200b0c:	80850513          	addi	a0,a0,-2040 # ffffffffc0201310 <etext+0x132>
ffffffffc0200b10:	e96ff0ef          	jal	ra,ffffffffc02001a6 <__panic>

ffffffffc0200b14 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0200b14:	1141                	addi	sp,sp,-16
ffffffffc0200b16:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200b18:	c5f9                	beqz	a1,ffffffffc0200be6 <best_fit_init_memmap+0xd2>
    for (; p != base + n; p ++) {
ffffffffc0200b1a:	00259693          	slli	a3,a1,0x2
ffffffffc0200b1e:	96ae                	add	a3,a3,a1
ffffffffc0200b20:	068e                	slli	a3,a3,0x3
ffffffffc0200b22:	96aa                	add	a3,a3,a0
ffffffffc0200b24:	87aa                	mv	a5,a0
ffffffffc0200b26:	00d50f63          	beq	a0,a3,ffffffffc0200b44 <best_fit_init_memmap+0x30>
        assert(PageReserved(p));
ffffffffc0200b2a:	6798                	ld	a4,8(a5)
ffffffffc0200b2c:	8b05                	andi	a4,a4,1
ffffffffc0200b2e:	cf41                	beqz	a4,ffffffffc0200bc6 <best_fit_init_memmap+0xb2>
        p->flags = p->property = 0;
ffffffffc0200b30:	0007a823          	sw	zero,16(a5)
ffffffffc0200b34:	0007b423          	sd	zero,8(a5)
ffffffffc0200b38:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc0200b3c:	02878793          	addi	a5,a5,40
ffffffffc0200b40:	fed795e3          	bne	a5,a3,ffffffffc0200b2a <best_fit_init_memmap+0x16>
    SetPageProperty(base);
ffffffffc0200b44:	6510                	ld	a2,8(a0)
    nr_free += n;
ffffffffc0200b46:	00004697          	auipc	a3,0x4
ffffffffc0200b4a:	4c268693          	addi	a3,a3,1218 # ffffffffc0205008 <free_area>
ffffffffc0200b4e:	4a98                	lw	a4,16(a3)
    base->property = n;
ffffffffc0200b50:	2581                	sext.w	a1,a1
    SetPageProperty(base);
ffffffffc0200b52:	00266613          	ori	a2,a2,2
    return list->next == list;
ffffffffc0200b56:	669c                	ld	a5,8(a3)
    base->property = n;
ffffffffc0200b58:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0200b5a:	e510                	sd	a2,8(a0)
    nr_free += n;
ffffffffc0200b5c:	9db9                	addw	a1,a1,a4
ffffffffc0200b5e:	ca8c                	sw	a1,16(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc0200b60:	01850613          	addi	a2,a0,24
    if (list_empty(&free_list)) {
ffffffffc0200b64:	04d78a63          	beq	a5,a3,ffffffffc0200bb8 <best_fit_init_memmap+0xa4>
            struct Page* page = le2page(le, page_link);
ffffffffc0200b68:	fe878713          	addi	a4,a5,-24
ffffffffc0200b6c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0200b70:	4581                	li	a1,0
            if (base < page) {
ffffffffc0200b72:	00e56a63          	bltu	a0,a4,ffffffffc0200b86 <best_fit_init_memmap+0x72>
    return listelm->next;
ffffffffc0200b76:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0200b78:	02d70263          	beq	a4,a3,ffffffffc0200b9c <best_fit_init_memmap+0x88>
    for (; p != base + n; p ++) {
ffffffffc0200b7c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc0200b7e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0200b82:	fee57ae3          	bgeu	a0,a4,ffffffffc0200b76 <best_fit_init_memmap+0x62>
ffffffffc0200b86:	c199                	beqz	a1,ffffffffc0200b8c <best_fit_init_memmap+0x78>
ffffffffc0200b88:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc0200b8c:	6398                	ld	a4,0(a5)
}
ffffffffc0200b8e:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0200b90:	e390                	sd	a2,0(a5)
ffffffffc0200b92:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0200b94:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200b96:	ed18                	sd	a4,24(a0)
ffffffffc0200b98:	0141                	addi	sp,sp,16
ffffffffc0200b9a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc0200b9c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200b9e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0200ba0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0200ba2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0200ba4:	00d70663          	beq	a4,a3,ffffffffc0200bb0 <best_fit_init_memmap+0x9c>
    prev->next = next->prev = elm;
ffffffffc0200ba8:	8832                	mv	a6,a2
ffffffffc0200baa:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc0200bac:	87ba                	mv	a5,a4
ffffffffc0200bae:	bfc1                	j	ffffffffc0200b7e <best_fit_init_memmap+0x6a>
}
ffffffffc0200bb0:	60a2                	ld	ra,8(sp)
ffffffffc0200bb2:	e290                	sd	a2,0(a3)
ffffffffc0200bb4:	0141                	addi	sp,sp,16
ffffffffc0200bb6:	8082                	ret
ffffffffc0200bb8:	60a2                	ld	ra,8(sp)
ffffffffc0200bba:	e390                	sd	a2,0(a5)
ffffffffc0200bbc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc0200bbe:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0200bc0:	ed1c                	sd	a5,24(a0)
ffffffffc0200bc2:	0141                	addi	sp,sp,16
ffffffffc0200bc4:	8082                	ret
        assert(PageReserved(p));
ffffffffc0200bc6:	00001697          	auipc	a3,0x1
ffffffffc0200bca:	a4a68693          	addi	a3,a3,-1462 # ffffffffc0201610 <etext+0x432>
ffffffffc0200bce:	00000617          	auipc	a2,0x0
ffffffffc0200bd2:	72a60613          	addi	a2,a2,1834 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200bd6:	04a00593          	li	a1,74
ffffffffc0200bda:	00000517          	auipc	a0,0x0
ffffffffc0200bde:	73650513          	addi	a0,a0,1846 # ffffffffc0201310 <etext+0x132>
ffffffffc0200be2:	dc4ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    assert(n > 0);
ffffffffc0200be6:	00000697          	auipc	a3,0x0
ffffffffc0200bea:	70a68693          	addi	a3,a3,1802 # ffffffffc02012f0 <etext+0x112>
ffffffffc0200bee:	00000617          	auipc	a2,0x0
ffffffffc0200bf2:	70a60613          	addi	a2,a2,1802 # ffffffffc02012f8 <etext+0x11a>
ffffffffc0200bf6:	04700593          	li	a1,71
ffffffffc0200bfa:	00000517          	auipc	a0,0x0
ffffffffc0200bfe:	71650513          	addi	a0,a0,1814 # ffffffffc0201310 <etext+0x132>
ffffffffc0200c02:	da4ff0ef          	jal	ra,ffffffffc02001a6 <__panic>

ffffffffc0200c06 <alloc_pages>:
    pmm_manager->init_memmap(base, n);
}

// alloc_pages - call pmm->alloc_pages to allocate a continuous n*PAGESIZE
// memory
struct Page *alloc_pages(size_t n) {
ffffffffc0200c06:	00004797          	auipc	a5,0x4
ffffffffc0200c0a:	4327b783          	ld	a5,1074(a5) # ffffffffc0205038 <pmm_manager>
ffffffffc0200c0e:	6f9c                	ld	a5,24(a5)
ffffffffc0200c10:	8782                	jr	a5

ffffffffc0200c12 <free_pages>:
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc0200c12:	00004797          	auipc	a5,0x4
ffffffffc0200c16:	4267b783          	ld	a5,1062(a5) # ffffffffc0205038 <pmm_manager>
ffffffffc0200c1a:	739c                	ld	a5,32(a5)
ffffffffc0200c1c:	8782                	jr	a5

ffffffffc0200c1e <nr_free_pages>:
    }
    local_intr_restore(intr_flag);
    return page;
}

// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
ffffffffc0200c1e:	00004797          	auipc	a5,0x4
ffffffffc0200c22:	41a7b783          	ld	a5,1050(a5) # ffffffffc0205038 <pmm_manager>
ffffffffc0200c26:	779c                	ld	a5,40(a5)
ffffffffc0200c28:	8782                	jr	a5

ffffffffc0200c2a <pmm_init>:
static void init_pmm_manager(void) {
ffffffffc0200c2a:	00001797          	auipc	a5,0x1
ffffffffc0200c2e:	a0e78793          	addi	a5,a5,-1522 # ffffffffc0201638 <best_fit_pmm_manager>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200c32:	638c                	ld	a1,0(a5)

    if (maxpa > KERNTOP) {
        maxpa = KERNTOP;
    }

    extern char end[];
ffffffffc0200c34:	1101                	addi	sp,sp,-32
ffffffffc0200c36:	e426                	sd	s1,8(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200c38:	00001517          	auipc	a0,0x1
ffffffffc0200c3c:	a3850513          	addi	a0,a0,-1480 # ffffffffc0201670 <best_fit_pmm_manager+0x38>
static void init_pmm_manager(void) {
ffffffffc0200c40:	00004497          	auipc	s1,0x4
ffffffffc0200c44:	3f848493          	addi	s1,s1,1016 # ffffffffc0205038 <pmm_manager>
    extern char end[];
ffffffffc0200c48:	ec06                	sd	ra,24(sp)
ffffffffc0200c4a:	e822                	sd	s0,16(sp)
static void init_pmm_manager(void) {
ffffffffc0200c4c:	e09c                	sd	a5,0(s1)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0200c4e:	ce2ff0ef          	jal	ra,ffffffffc0200130 <cprintf>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c52:	609c                	ld	a5,0(s1)
    {
ffffffffc0200c54:	00004417          	auipc	s0,0x4
ffffffffc0200c58:	3fc40413          	addi	s0,s0,1020 # ffffffffc0205050 <va_pa_offset>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0200c5c:	679c                	ld	a5,8(a5)
ffffffffc0200c5e:	9782                	jalr	a5
    {
ffffffffc0200c60:	57f5                	li	a5,-3
ffffffffc0200c62:	07fa                	slli	a5,a5,0x1e
// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
ffffffffc0200c64:	00001517          	auipc	a0,0x1
ffffffffc0200c68:	a2450513          	addi	a0,a0,-1500 # ffffffffc0201688 <best_fit_pmm_manager+0x50>
    {
ffffffffc0200c6c:	e01c                	sd	a5,0(s0)
// nr_free_pages - call pmm->nr_free_pages to get the size (nr*PAGESIZE)
ffffffffc0200c6e:	cc2ff0ef          	jal	ra,ffffffffc0200130 <cprintf>
// of current free memory
ffffffffc0200c72:	46c5                	li	a3,17
ffffffffc0200c74:	06ee                	slli	a3,a3,0x1b
ffffffffc0200c76:	40100613          	li	a2,1025
ffffffffc0200c7a:	16fd                	addi	a3,a3,-1
ffffffffc0200c7c:	0656                	slli	a2,a2,0x15
ffffffffc0200c7e:	07e005b7          	lui	a1,0x7e00
ffffffffc0200c82:	00001517          	auipc	a0,0x1
ffffffffc0200c86:	a1e50513          	addi	a0,a0,-1506 # ffffffffc02016a0 <best_fit_pmm_manager+0x68>
ffffffffc0200c8a:	ca6ff0ef          	jal	ra,ffffffffc0200130 <cprintf>

ffffffffc0200c8e:	777d                	lui	a4,0xfffff
ffffffffc0200c90:	00005797          	auipc	a5,0x5
ffffffffc0200c94:	3c778793          	addi	a5,a5,967 # ffffffffc0206057 <end+0xfff>
ffffffffc0200c98:	8ff9                	and	a5,a5,a4
ffffffffc0200c9a:	00088737          	lui	a4,0x88
ffffffffc0200c9e:	00004697          	auipc	a3,0x4
ffffffffc0200ca2:	38e6b523          	sd	a4,906(a3) # ffffffffc0205028 <npage>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0200ca6:	001406b7          	lui	a3,0x140
ffffffffc0200caa:	853e                	mv	a0,a5
ffffffffc0200cac:	00004717          	auipc	a4,0x4
ffffffffc0200cb0:	38f73223          	sd	a5,900(a4) # ffffffffc0205030 <pages>
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
ffffffffc0200cb4:	96be                	add	a3,a3,a5
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
ffffffffc0200cb6:	6798                	ld	a4,8(a5)
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
ffffffffc0200cb8:	02878793          	addi	a5,a5,40
    uint64_t mem_size = PHYSICAL_MEMORY_END - KERNEL_BEGIN_PADDR;
ffffffffc0200cbc:	00176713          	ori	a4,a4,1
ffffffffc0200cc0:	fee7b023          	sd	a4,-32(a5)
    uint64_t mem_begin = KERNEL_BEGIN_PADDR;
ffffffffc0200cc4:	fef699e3          	bne	a3,a5,ffffffffc0200cb6 <pmm_init+0x8c>
    cprintf("physcial memory map:\n");
ffffffffc0200cc8:	c02007b7          	lui	a5,0xc0200
ffffffffc0200ccc:	0af6e563          	bltu	a3,a5,ffffffffc0200d76 <pmm_init+0x14c>
ffffffffc0200cd0:	601c                	ld	a5,0(s0)
    uint64_t maxpa = mem_end;
ffffffffc0200cd2:	4745                	li	a4,17
ffffffffc0200cd4:	076e                	slli	a4,a4,0x1b
    cprintf("physcial memory map:\n");
ffffffffc0200cd6:	8e9d                	sub	a3,a3,a5
    uint64_t maxpa = mem_end;
ffffffffc0200cd8:	04e6e863          	bltu	a3,a4,ffffffffc0200d28 <pmm_init+0xfe>
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
    // We need to alloc/free the physical memory (granularity is 4KB or other size).
    // So a framework of physical memory manager (struct pmm_manager)is defined in pmm.h
ffffffffc0200cdc:	609c                	ld	a5,0(s1)
ffffffffc0200cde:	7b9c                	ld	a5,48(a5)
ffffffffc0200ce0:	9782                	jalr	a5
    // First we should init a physical memory manager(pmm) based on the framework.
ffffffffc0200ce2:	00001517          	auipc	a0,0x1
ffffffffc0200ce6:	a5650513          	addi	a0,a0,-1450 # ffffffffc0201738 <best_fit_pmm_manager+0x100>
ffffffffc0200cea:	c46ff0ef          	jal	ra,ffffffffc0200130 <cprintf>
    }
ffffffffc0200cee:	00003597          	auipc	a1,0x3
ffffffffc0200cf2:	31258593          	addi	a1,a1,786 # ffffffffc0204000 <boot_page_table_sv39>
ffffffffc0200cf6:	00004797          	auipc	a5,0x4
ffffffffc0200cfa:	34b7b923          	sd	a1,850(a5) # ffffffffc0205048 <satp_virtual>
}
ffffffffc0200cfe:	c02007b7          	lui	a5,0xc0200
ffffffffc0200d02:	08f5e663          	bltu	a1,a5,ffffffffc0200d8e <pmm_init+0x164>
ffffffffc0200d06:	6010                	ld	a2,0(s0)
/* pmm_init - initialize the physical memory management */
ffffffffc0200d08:	6442                	ld	s0,16(sp)
ffffffffc0200d0a:	60e2                	ld	ra,24(sp)
ffffffffc0200d0c:	64a2                	ld	s1,8(sp)
}
ffffffffc0200d0e:	40c58633          	sub	a2,a1,a2
ffffffffc0200d12:	00004797          	auipc	a5,0x4
ffffffffc0200d16:	32c7b723          	sd	a2,814(a5) # ffffffffc0205040 <satp_physical>

ffffffffc0200d1a:	00001517          	auipc	a0,0x1
ffffffffc0200d1e:	a3e50513          	addi	a0,a0,-1474 # ffffffffc0201758 <best_fit_pmm_manager+0x120>
/* pmm_init - initialize the physical memory management */
ffffffffc0200d22:	6105                	addi	sp,sp,32

ffffffffc0200d24:	c0cff06f          	j	ffffffffc0200130 <cprintf>
            mem_end - 1);
ffffffffc0200d28:	6785                	lui	a5,0x1
ffffffffc0200d2a:	17fd                	addi	a5,a5,-1
ffffffffc0200d2c:	96be                	add	a3,a3,a5
ffffffffc0200d2e:	77fd                	lui	a5,0xfffff
ffffffffc0200d30:	8ff5                	and	a5,a5,a3

static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
ffffffffc0200d32:	00c7d693          	srli	a3,a5,0xc
ffffffffc0200d36:	00088637          	lui	a2,0x88
ffffffffc0200d3a:	02c68263          	beq	a3,a2,ffffffffc0200d5e <pmm_init+0x134>
static void init_memmap(struct Page *base, size_t n) {
ffffffffc0200d3e:	608c                	ld	a1,0(s1)
    if (PPN(pa) >= npage) {
        panic("pa2page called with invalid pa");
    }
ffffffffc0200d40:	fff80637          	lui	a2,0xfff80
ffffffffc0200d44:	9636                	add	a2,a2,a3
ffffffffc0200d46:	00261693          	slli	a3,a2,0x2
ffffffffc0200d4a:	96b2                	add	a3,a3,a2
ffffffffc0200d4c:	6990                	ld	a2,16(a1)

ffffffffc0200d4e:	40f707b3          	sub	a5,a4,a5
ffffffffc0200d52:	068e                	slli	a3,a3,0x3
static void init_memmap(struct Page *base, size_t n) {
ffffffffc0200d54:	00c7d593          	srli	a1,a5,0xc
ffffffffc0200d58:	9536                	add	a0,a0,a3
ffffffffc0200d5a:	9602                	jalr	a2
    pmm_manager->init_memmap(base, n);
ffffffffc0200d5c:	b741                	j	ffffffffc0200cdc <pmm_init+0xb2>
    if (PPN(pa) >= npage) {
ffffffffc0200d5e:	00001617          	auipc	a2,0x1
ffffffffc0200d62:	9aa60613          	addi	a2,a2,-1622 # ffffffffc0201708 <best_fit_pmm_manager+0xd0>
ffffffffc0200d66:	06a00593          	li	a1,106
ffffffffc0200d6a:	00001517          	auipc	a0,0x1
ffffffffc0200d6e:	9be50513          	addi	a0,a0,-1602 # ffffffffc0201728 <best_fit_pmm_manager+0xf0>
ffffffffc0200d72:	c34ff0ef          	jal	ra,ffffffffc02001a6 <__panic>
    cprintf("physcial memory map:\n");
ffffffffc0200d76:	00001617          	auipc	a2,0x1
ffffffffc0200d7a:	95a60613          	addi	a2,a2,-1702 # ffffffffc02016d0 <best_fit_pmm_manager+0x98>
ffffffffc0200d7e:	05a00593          	li	a1,90
ffffffffc0200d82:	00001517          	auipc	a0,0x1
ffffffffc0200d86:	97650513          	addi	a0,a0,-1674 # ffffffffc02016f8 <best_fit_pmm_manager+0xc0>
ffffffffc0200d8a:	c1cff0ef          	jal	ra,ffffffffc02001a6 <__panic>
}
ffffffffc0200d8e:	86ae                	mv	a3,a1
ffffffffc0200d90:	00001617          	auipc	a2,0x1
ffffffffc0200d94:	94060613          	addi	a2,a2,-1728 # ffffffffc02016d0 <best_fit_pmm_manager+0x98>
ffffffffc0200d98:	07500593          	li	a1,117
ffffffffc0200d9c:	00001517          	auipc	a0,0x1
ffffffffc0200da0:	95c50513          	addi	a0,a0,-1700 # ffffffffc02016f8 <best_fit_pmm_manager+0xc0>
ffffffffc0200da4:	c02ff0ef          	jal	ra,ffffffffc02001a6 <__panic>

ffffffffc0200da8 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc0200da8:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200dac:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc0200dae:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200db2:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc0200db4:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc0200db8:	f022                	sd	s0,32(sp)
ffffffffc0200dba:	ec26                	sd	s1,24(sp)
ffffffffc0200dbc:	e84a                	sd	s2,16(sp)
ffffffffc0200dbe:	f406                	sd	ra,40(sp)
ffffffffc0200dc0:	e44e                	sd	s3,8(sp)
ffffffffc0200dc2:	84aa                	mv	s1,a0
ffffffffc0200dc4:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc0200dc6:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc0200dca:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc0200dcc:	03067e63          	bgeu	a2,a6,ffffffffc0200e08 <printnum+0x60>
ffffffffc0200dd0:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc0200dd2:	00805763          	blez	s0,ffffffffc0200de0 <printnum+0x38>
ffffffffc0200dd6:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc0200dd8:	85ca                	mv	a1,s2
ffffffffc0200dda:	854e                	mv	a0,s3
ffffffffc0200ddc:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc0200dde:	fc65                	bnez	s0,ffffffffc0200dd6 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200de0:	1a02                	slli	s4,s4,0x20
ffffffffc0200de2:	00001797          	auipc	a5,0x1
ffffffffc0200de6:	9b678793          	addi	a5,a5,-1610 # ffffffffc0201798 <best_fit_pmm_manager+0x160>
ffffffffc0200dea:	020a5a13          	srli	s4,s4,0x20
ffffffffc0200dee:	9a3e                	add	s4,s4,a5
}
ffffffffc0200df0:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200df2:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0200df6:	70a2                	ld	ra,40(sp)
ffffffffc0200df8:	69a2                	ld	s3,8(sp)
ffffffffc0200dfa:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200dfc:	85ca                	mv	a1,s2
ffffffffc0200dfe:	87a6                	mv	a5,s1
}
ffffffffc0200e00:	6942                	ld	s2,16(sp)
ffffffffc0200e02:	64e2                	ld	s1,24(sp)
ffffffffc0200e04:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0200e06:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0200e08:	03065633          	divu	a2,a2,a6
ffffffffc0200e0c:	8722                	mv	a4,s0
ffffffffc0200e0e:	f9bff0ef          	jal	ra,ffffffffc0200da8 <printnum>
ffffffffc0200e12:	b7f9                	j	ffffffffc0200de0 <printnum+0x38>

ffffffffc0200e14 <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc0200e14:	7119                	addi	sp,sp,-128
ffffffffc0200e16:	f4a6                	sd	s1,104(sp)
ffffffffc0200e18:	f0ca                	sd	s2,96(sp)
ffffffffc0200e1a:	ecce                	sd	s3,88(sp)
ffffffffc0200e1c:	e8d2                	sd	s4,80(sp)
ffffffffc0200e1e:	e4d6                	sd	s5,72(sp)
ffffffffc0200e20:	e0da                	sd	s6,64(sp)
ffffffffc0200e22:	fc5e                	sd	s7,56(sp)
ffffffffc0200e24:	f06a                	sd	s10,32(sp)
ffffffffc0200e26:	fc86                	sd	ra,120(sp)
ffffffffc0200e28:	f8a2                	sd	s0,112(sp)
ffffffffc0200e2a:	f862                	sd	s8,48(sp)
ffffffffc0200e2c:	f466                	sd	s9,40(sp)
ffffffffc0200e2e:	ec6e                	sd	s11,24(sp)
ffffffffc0200e30:	892a                	mv	s2,a0
ffffffffc0200e32:	84ae                	mv	s1,a1
ffffffffc0200e34:	8d32                	mv	s10,a2
ffffffffc0200e36:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e38:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0200e3c:	5b7d                	li	s6,-1
ffffffffc0200e3e:	00001a97          	auipc	s5,0x1
ffffffffc0200e42:	98ea8a93          	addi	s5,s5,-1650 # ffffffffc02017cc <best_fit_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0200e46:	00001b97          	auipc	s7,0x1
ffffffffc0200e4a:	b62b8b93          	addi	s7,s7,-1182 # ffffffffc02019a8 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e4e:	000d4503          	lbu	a0,0(s10)
ffffffffc0200e52:	001d0413          	addi	s0,s10,1
ffffffffc0200e56:	01350a63          	beq	a0,s3,ffffffffc0200e6a <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0200e5a:	c121                	beqz	a0,ffffffffc0200e9a <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0200e5c:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e5e:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc0200e60:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0200e62:	fff44503          	lbu	a0,-1(s0)
ffffffffc0200e66:	ff351ae3          	bne	a0,s3,ffffffffc0200e5a <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200e6a:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0200e6e:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc0200e72:	4c81                	li	s9,0
ffffffffc0200e74:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0200e76:	5c7d                	li	s8,-1
ffffffffc0200e78:	5dfd                	li	s11,-1
ffffffffc0200e7a:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0200e7e:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200e80:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0200e84:	0ff5f593          	zext.b	a1,a1
ffffffffc0200e88:	00140d13          	addi	s10,s0,1
ffffffffc0200e8c:	04b56263          	bltu	a0,a1,ffffffffc0200ed0 <vprintfmt+0xbc>
ffffffffc0200e90:	058a                	slli	a1,a1,0x2
ffffffffc0200e92:	95d6                	add	a1,a1,s5
ffffffffc0200e94:	4194                	lw	a3,0(a1)
ffffffffc0200e96:	96d6                	add	a3,a3,s5
ffffffffc0200e98:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc0200e9a:	70e6                	ld	ra,120(sp)
ffffffffc0200e9c:	7446                	ld	s0,112(sp)
ffffffffc0200e9e:	74a6                	ld	s1,104(sp)
ffffffffc0200ea0:	7906                	ld	s2,96(sp)
ffffffffc0200ea2:	69e6                	ld	s3,88(sp)
ffffffffc0200ea4:	6a46                	ld	s4,80(sp)
ffffffffc0200ea6:	6aa6                	ld	s5,72(sp)
ffffffffc0200ea8:	6b06                	ld	s6,64(sp)
ffffffffc0200eaa:	7be2                	ld	s7,56(sp)
ffffffffc0200eac:	7c42                	ld	s8,48(sp)
ffffffffc0200eae:	7ca2                	ld	s9,40(sp)
ffffffffc0200eb0:	7d02                	ld	s10,32(sp)
ffffffffc0200eb2:	6de2                	ld	s11,24(sp)
ffffffffc0200eb4:	6109                	addi	sp,sp,128
ffffffffc0200eb6:	8082                	ret
            padc = '0';
ffffffffc0200eb8:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc0200eba:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ebe:	846a                	mv	s0,s10
ffffffffc0200ec0:	00140d13          	addi	s10,s0,1
ffffffffc0200ec4:	fdd6059b          	addiw	a1,a2,-35
ffffffffc0200ec8:	0ff5f593          	zext.b	a1,a1
ffffffffc0200ecc:	fcb572e3          	bgeu	a0,a1,ffffffffc0200e90 <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc0200ed0:	85a6                	mv	a1,s1
ffffffffc0200ed2:	02500513          	li	a0,37
ffffffffc0200ed6:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc0200ed8:	fff44783          	lbu	a5,-1(s0)
ffffffffc0200edc:	8d22                	mv	s10,s0
ffffffffc0200ede:	f73788e3          	beq	a5,s3,ffffffffc0200e4e <vprintfmt+0x3a>
ffffffffc0200ee2:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0200ee6:	1d7d                	addi	s10,s10,-1
ffffffffc0200ee8:	ff379de3          	bne	a5,s3,ffffffffc0200ee2 <vprintfmt+0xce>
ffffffffc0200eec:	b78d                	j	ffffffffc0200e4e <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0200eee:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc0200ef2:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200ef6:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0200ef8:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0200efc:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200f00:	02d86463          	bltu	a6,a3,ffffffffc0200f28 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc0200f04:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0200f08:	002c169b          	slliw	a3,s8,0x2
ffffffffc0200f0c:	0186873b          	addw	a4,a3,s8
ffffffffc0200f10:	0017171b          	slliw	a4,a4,0x1
ffffffffc0200f14:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0200f16:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0200f1a:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0200f1c:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc0200f20:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc0200f24:	fed870e3          	bgeu	a6,a3,ffffffffc0200f04 <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0200f28:	f40ddce3          	bgez	s11,ffffffffc0200e80 <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0200f2c:	8de2                	mv	s11,s8
ffffffffc0200f2e:	5c7d                	li	s8,-1
ffffffffc0200f30:	bf81                	j	ffffffffc0200e80 <vprintfmt+0x6c>
            if (width < 0)
ffffffffc0200f32:	fffdc693          	not	a3,s11
ffffffffc0200f36:	96fd                	srai	a3,a3,0x3f
ffffffffc0200f38:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f3c:	00144603          	lbu	a2,1(s0)
ffffffffc0200f40:	2d81                	sext.w	s11,s11
ffffffffc0200f42:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0200f44:	bf35                	j	ffffffffc0200e80 <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0200f46:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f4a:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0200f4e:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f50:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc0200f52:	bfd9                	j	ffffffffc0200f28 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc0200f54:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200f56:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200f5a:	01174463          	blt	a4,a7,ffffffffc0200f62 <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0200f5e:	1a088e63          	beqz	a7,ffffffffc020111a <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc0200f62:	000a3603          	ld	a2,0(s4)
ffffffffc0200f66:	46c1                	li	a3,16
ffffffffc0200f68:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0200f6a:	2781                	sext.w	a5,a5
ffffffffc0200f6c:	876e                	mv	a4,s11
ffffffffc0200f6e:	85a6                	mv	a1,s1
ffffffffc0200f70:	854a                	mv	a0,s2
ffffffffc0200f72:	e37ff0ef          	jal	ra,ffffffffc0200da8 <printnum>
            break;
ffffffffc0200f76:	bde1                	j	ffffffffc0200e4e <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0200f78:	000a2503          	lw	a0,0(s4)
ffffffffc0200f7c:	85a6                	mv	a1,s1
ffffffffc0200f7e:	0a21                	addi	s4,s4,8
ffffffffc0200f80:	9902                	jalr	s2
            break;
ffffffffc0200f82:	b5f1                	j	ffffffffc0200e4e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0200f84:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200f86:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200f8a:	01174463          	blt	a4,a7,ffffffffc0200f92 <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc0200f8e:	18088163          	beqz	a7,ffffffffc0201110 <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc0200f92:	000a3603          	ld	a2,0(s4)
ffffffffc0200f96:	46a9                	li	a3,10
ffffffffc0200f98:	8a2e                	mv	s4,a1
ffffffffc0200f9a:	bfc1                	j	ffffffffc0200f6a <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200f9c:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc0200fa0:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200fa2:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0200fa4:	bdf1                	j	ffffffffc0200e80 <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc0200fa6:	85a6                	mv	a1,s1
ffffffffc0200fa8:	02500513          	li	a0,37
ffffffffc0200fac:	9902                	jalr	s2
            break;
ffffffffc0200fae:	b545                	j	ffffffffc0200e4e <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200fb0:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc0200fb4:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0200fb6:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc0200fb8:	b5e1                	j	ffffffffc0200e80 <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc0200fba:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0200fbc:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0200fc0:	01174463          	blt	a4,a7,ffffffffc0200fc8 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc0200fc4:	14088163          	beqz	a7,ffffffffc0201106 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc0200fc8:	000a3603          	ld	a2,0(s4)
ffffffffc0200fcc:	46a1                	li	a3,8
ffffffffc0200fce:	8a2e                	mv	s4,a1
ffffffffc0200fd0:	bf69                	j	ffffffffc0200f6a <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc0200fd2:	03000513          	li	a0,48
ffffffffc0200fd6:	85a6                	mv	a1,s1
ffffffffc0200fd8:	e03e                	sd	a5,0(sp)
ffffffffc0200fda:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc0200fdc:	85a6                	mv	a1,s1
ffffffffc0200fde:	07800513          	li	a0,120
ffffffffc0200fe2:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200fe4:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0200fe6:	6782                	ld	a5,0(sp)
ffffffffc0200fe8:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0200fea:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0200fee:	bfb5                	j	ffffffffc0200f6a <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0200ff0:	000a3403          	ld	s0,0(s4)
ffffffffc0200ff4:	008a0713          	addi	a4,s4,8
ffffffffc0200ff8:	e03a                	sd	a4,0(sp)
ffffffffc0200ffa:	14040263          	beqz	s0,ffffffffc020113e <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0200ffe:	0fb05763          	blez	s11,ffffffffc02010ec <vprintfmt+0x2d8>
ffffffffc0201002:	02d00693          	li	a3,45
ffffffffc0201006:	0cd79163          	bne	a5,a3,ffffffffc02010c8 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020100a:	00044783          	lbu	a5,0(s0)
ffffffffc020100e:	0007851b          	sext.w	a0,a5
ffffffffc0201012:	cf85                	beqz	a5,ffffffffc020104a <vprintfmt+0x236>
ffffffffc0201014:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201018:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020101c:	000c4563          	bltz	s8,ffffffffc0201026 <vprintfmt+0x212>
ffffffffc0201020:	3c7d                	addiw	s8,s8,-1
ffffffffc0201022:	036c0263          	beq	s8,s6,ffffffffc0201046 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201026:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201028:	0e0c8e63          	beqz	s9,ffffffffc0201124 <vprintfmt+0x310>
ffffffffc020102c:	3781                	addiw	a5,a5,-32
ffffffffc020102e:	0ef47b63          	bgeu	s0,a5,ffffffffc0201124 <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc0201032:	03f00513          	li	a0,63
ffffffffc0201036:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201038:	000a4783          	lbu	a5,0(s4)
ffffffffc020103c:	3dfd                	addiw	s11,s11,-1
ffffffffc020103e:	0a05                	addi	s4,s4,1
ffffffffc0201040:	0007851b          	sext.w	a0,a5
ffffffffc0201044:	ffe1                	bnez	a5,ffffffffc020101c <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201046:	01b05963          	blez	s11,ffffffffc0201058 <vprintfmt+0x244>
ffffffffc020104a:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc020104c:	85a6                	mv	a1,s1
ffffffffc020104e:	02000513          	li	a0,32
ffffffffc0201052:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc0201054:	fe0d9be3          	bnez	s11,ffffffffc020104a <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201058:	6a02                	ld	s4,0(sp)
ffffffffc020105a:	bbd5                	j	ffffffffc0200e4e <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020105c:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc020105e:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc0201062:	01174463          	blt	a4,a7,ffffffffc020106a <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201066:	08088d63          	beqz	a7,ffffffffc0201100 <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc020106a:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc020106e:	0a044d63          	bltz	s0,ffffffffc0201128 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc0201072:	8622                	mv	a2,s0
ffffffffc0201074:	8a66                	mv	s4,s9
ffffffffc0201076:	46a9                	li	a3,10
ffffffffc0201078:	bdcd                	j	ffffffffc0200f6a <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc020107a:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020107e:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc0201080:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc0201082:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc0201086:	8fb5                	xor	a5,a5,a3
ffffffffc0201088:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc020108c:	02d74163          	blt	a4,a3,ffffffffc02010ae <vprintfmt+0x29a>
ffffffffc0201090:	00369793          	slli	a5,a3,0x3
ffffffffc0201094:	97de                	add	a5,a5,s7
ffffffffc0201096:	639c                	ld	a5,0(a5)
ffffffffc0201098:	cb99                	beqz	a5,ffffffffc02010ae <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc020109a:	86be                	mv	a3,a5
ffffffffc020109c:	00000617          	auipc	a2,0x0
ffffffffc02010a0:	72c60613          	addi	a2,a2,1836 # ffffffffc02017c8 <best_fit_pmm_manager+0x190>
ffffffffc02010a4:	85a6                	mv	a1,s1
ffffffffc02010a6:	854a                	mv	a0,s2
ffffffffc02010a8:	0ce000ef          	jal	ra,ffffffffc0201176 <printfmt>
ffffffffc02010ac:	b34d                	j	ffffffffc0200e4e <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02010ae:	00000617          	auipc	a2,0x0
ffffffffc02010b2:	70a60613          	addi	a2,a2,1802 # ffffffffc02017b8 <best_fit_pmm_manager+0x180>
ffffffffc02010b6:	85a6                	mv	a1,s1
ffffffffc02010b8:	854a                	mv	a0,s2
ffffffffc02010ba:	0bc000ef          	jal	ra,ffffffffc0201176 <printfmt>
ffffffffc02010be:	bb41                	j	ffffffffc0200e4e <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02010c0:	00000417          	auipc	s0,0x0
ffffffffc02010c4:	6f040413          	addi	s0,s0,1776 # ffffffffc02017b0 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010c8:	85e2                	mv	a1,s8
ffffffffc02010ca:	8522                	mv	a0,s0
ffffffffc02010cc:	e43e                	sd	a5,8(sp)
ffffffffc02010ce:	0e2000ef          	jal	ra,ffffffffc02011b0 <strnlen>
ffffffffc02010d2:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02010d6:	01b05b63          	blez	s11,ffffffffc02010ec <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02010da:	67a2                	ld	a5,8(sp)
ffffffffc02010dc:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010e0:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02010e2:	85a6                	mv	a1,s1
ffffffffc02010e4:	8552                	mv	a0,s4
ffffffffc02010e6:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02010e8:	fe0d9ce3          	bnez	s11,ffffffffc02010e0 <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc02010ec:	00044783          	lbu	a5,0(s0)
ffffffffc02010f0:	00140a13          	addi	s4,s0,1
ffffffffc02010f4:	0007851b          	sext.w	a0,a5
ffffffffc02010f8:	d3a5                	beqz	a5,ffffffffc0201058 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc02010fa:	05e00413          	li	s0,94
ffffffffc02010fe:	bf39                	j	ffffffffc020101c <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc0201100:	000a2403          	lw	s0,0(s4)
ffffffffc0201104:	b7ad                	j	ffffffffc020106e <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201106:	000a6603          	lwu	a2,0(s4)
ffffffffc020110a:	46a1                	li	a3,8
ffffffffc020110c:	8a2e                	mv	s4,a1
ffffffffc020110e:	bdb1                	j	ffffffffc0200f6a <vprintfmt+0x156>
ffffffffc0201110:	000a6603          	lwu	a2,0(s4)
ffffffffc0201114:	46a9                	li	a3,10
ffffffffc0201116:	8a2e                	mv	s4,a1
ffffffffc0201118:	bd89                	j	ffffffffc0200f6a <vprintfmt+0x156>
ffffffffc020111a:	000a6603          	lwu	a2,0(s4)
ffffffffc020111e:	46c1                	li	a3,16
ffffffffc0201120:	8a2e                	mv	s4,a1
ffffffffc0201122:	b5a1                	j	ffffffffc0200f6a <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc0201124:	9902                	jalr	s2
ffffffffc0201126:	bf09                	j	ffffffffc0201038 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201128:	85a6                	mv	a1,s1
ffffffffc020112a:	02d00513          	li	a0,45
ffffffffc020112e:	e03e                	sd	a5,0(sp)
ffffffffc0201130:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc0201132:	6782                	ld	a5,0(sp)
ffffffffc0201134:	8a66                	mv	s4,s9
ffffffffc0201136:	40800633          	neg	a2,s0
ffffffffc020113a:	46a9                	li	a3,10
ffffffffc020113c:	b53d                	j	ffffffffc0200f6a <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc020113e:	03b05163          	blez	s11,ffffffffc0201160 <vprintfmt+0x34c>
ffffffffc0201142:	02d00693          	li	a3,45
ffffffffc0201146:	f6d79de3          	bne	a5,a3,ffffffffc02010c0 <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc020114a:	00000417          	auipc	s0,0x0
ffffffffc020114e:	66640413          	addi	s0,s0,1638 # ffffffffc02017b0 <best_fit_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201152:	02800793          	li	a5,40
ffffffffc0201156:	02800513          	li	a0,40
ffffffffc020115a:	00140a13          	addi	s4,s0,1
ffffffffc020115e:	bd6d                	j	ffffffffc0201018 <vprintfmt+0x204>
ffffffffc0201160:	00000a17          	auipc	s4,0x0
ffffffffc0201164:	651a0a13          	addi	s4,s4,1617 # ffffffffc02017b1 <best_fit_pmm_manager+0x179>
ffffffffc0201168:	02800513          	li	a0,40
ffffffffc020116c:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201170:	05e00413          	li	s0,94
ffffffffc0201174:	b565                	j	ffffffffc020101c <vprintfmt+0x208>

ffffffffc0201176 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201176:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201178:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020117c:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020117e:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201180:	ec06                	sd	ra,24(sp)
ffffffffc0201182:	f83a                	sd	a4,48(sp)
ffffffffc0201184:	fc3e                	sd	a5,56(sp)
ffffffffc0201186:	e0c2                	sd	a6,64(sp)
ffffffffc0201188:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc020118a:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc020118c:	c89ff0ef          	jal	ra,ffffffffc0200e14 <vprintfmt>
}
ffffffffc0201190:	60e2                	ld	ra,24(sp)
ffffffffc0201192:	6161                	addi	sp,sp,80
ffffffffc0201194:	8082                	ret

ffffffffc0201196 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201196:	4781                	li	a5,0
ffffffffc0201198:	00004717          	auipc	a4,0x4
ffffffffc020119c:	e6873703          	ld	a4,-408(a4) # ffffffffc0205000 <SBI_CONSOLE_PUTCHAR>
ffffffffc02011a0:	88ba                	mv	a7,a4
ffffffffc02011a2:	852a                	mv	a0,a0
ffffffffc02011a4:	85be                	mv	a1,a5
ffffffffc02011a6:	863e                	mv	a2,a5
ffffffffc02011a8:	00000073          	ecall
ffffffffc02011ac:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc02011ae:	8082                	ret

ffffffffc02011b0 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02011b0:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011b2:	e589                	bnez	a1,ffffffffc02011bc <strnlen+0xc>
ffffffffc02011b4:	a811                	j	ffffffffc02011c8 <strnlen+0x18>
        cnt ++;
ffffffffc02011b6:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02011b8:	00f58863          	beq	a1,a5,ffffffffc02011c8 <strnlen+0x18>
ffffffffc02011bc:	00f50733          	add	a4,a0,a5
ffffffffc02011c0:	00074703          	lbu	a4,0(a4)
ffffffffc02011c4:	fb6d                	bnez	a4,ffffffffc02011b6 <strnlen+0x6>
ffffffffc02011c6:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02011c8:	852e                	mv	a0,a1
ffffffffc02011ca:	8082                	ret

ffffffffc02011cc <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc02011cc:	ca01                	beqz	a2,ffffffffc02011dc <memset+0x10>
ffffffffc02011ce:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc02011d0:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc02011d2:	0785                	addi	a5,a5,1
ffffffffc02011d4:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc02011d8:	fec79de3          	bne	a5,a2,ffffffffc02011d2 <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc02011dc:	8082                	ret
