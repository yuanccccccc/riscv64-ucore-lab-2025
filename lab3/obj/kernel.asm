
bin/kernel:     file format elf64-littleriscv


Disassembly of section .text:

ffffffffc0200000 <kern_entry>:
    .globl kern_entry
kern_entry:
    # a0: hartid
    # a1: dtb physical address
    # save hartid and dtb address
    la t0, boot_hartid
ffffffffc0200000:	00006297          	auipc	t0,0x6
ffffffffc0200004:	00028293          	mv	t0,t0
    sd a0, 0(t0)
ffffffffc0200008:	00a2b023          	sd	a0,0(t0) # ffffffffc0206000 <boot_hartid>
    la t0, boot_dtb
ffffffffc020000c:	00006297          	auipc	t0,0x6
ffffffffc0200010:	ffc28293          	addi	t0,t0,-4 # ffffffffc0206008 <boot_dtb>
    sd a1, 0(t0)
ffffffffc0200014:	00b2b023          	sd	a1,0(t0)

    # t0 := 三级页表的虚拟地址
    lui     t0, %hi(boot_page_table_sv39)
ffffffffc0200018:	c02052b7          	lui	t0,0xc0205
    # t1 := 0xffffffff40000000 即虚实映射偏移量
    li      t1, 0xffffffffc0000000 - 0x80000000
ffffffffc020001c:	ffd0031b          	addiw	t1,zero,-3
ffffffffc0200020:	037a                	slli	t1,t1,0x1e
    # t0 减去虚实映射偏移量 0xffffffff40000000，变为三级页表的物理地址
    sub     t0, t0, t1
ffffffffc0200022:	406282b3          	sub	t0,t0,t1
    # t0 >>= 12，变为三级页表的物理页号
    srli    t0, t0, 12
ffffffffc0200026:	00c2d293          	srli	t0,t0,0xc

    # t1 := 8 << 60，设置 satp 的 MODE 字段为 Sv39
    li      t1, 8 << 60
ffffffffc020002a:	fff0031b          	addiw	t1,zero,-1
ffffffffc020002e:	137e                	slli	t1,t1,0x3f
    # 将刚才计算出的预设三级页表物理页号附加到 satp 中
    or      t0, t0, t1
ffffffffc0200030:	0062e2b3          	or	t0,t0,t1
    # 将算出的 t0(即新的MODE|页表基址物理页号) 覆盖到 satp 中
    csrw    satp, t0
ffffffffc0200034:	18029073          	csrw	satp,t0
    # 使用 sfence.vma 指令刷新 TLB
    sfence.vma
ffffffffc0200038:	12000073          	sfence.vma
    # 从此，我们给内核搭建出了一个完美的虚拟内存空间！
    #nop # 可能映射的位置有些bug。。插入一个nop
    
    # 我们在虚拟内存空间中：随意将 sp 设置为虚拟地址！
    lui sp, %hi(bootstacktop)
ffffffffc020003c:	c0205137          	lui	sp,0xc0205

    # 我们在虚拟内存空间中：随意跳转到虚拟地址！
    # 1. 使用临时寄存器 t1 计算栈顶的精确地址
    lui t1, %hi(bootstacktop)
ffffffffc0200040:	c0205337          	lui	t1,0xc0205
    addi t1, t1, %lo(bootstacktop)
ffffffffc0200044:	00030313          	mv	t1,t1
    # 2. 将精确地址一次性地、安全地传给 sp
    mv sp, t1
ffffffffc0200048:	811a                	mv	sp,t1
    # 现在栈指针已经完美设置，可以安全地调用任何C函数了
    # 然后跳转到 kern_init (不再返回)
    lui t0, %hi(kern_init)
ffffffffc020004a:	c02002b7          	lui	t0,0xc0200
    addi t0, t0, %lo(kern_init)
ffffffffc020004e:	05428293          	addi	t0,t0,84 # ffffffffc0200054 <kern_init>
    jr t0
ffffffffc0200052:	8282                	jr	t0

ffffffffc0200054 <kern_init>:

int kern_init(void) __attribute__((noreturn));
void grade_backtrace(void);
static void lab1_switch_test(void);

int kern_init(void) {
ffffffffc0200054:	1141                	addi	sp,sp,-16
ffffffffc0200056:	e406                	sd	ra,8(sp)
    extern char edata[], end[];
    dtb_init();
ffffffffc0200058:	426000ef          	jal	ra,ffffffffc020047e <dtb_init>
    memset(edata, 0, end - edata);
ffffffffc020005c:	00006517          	auipc	a0,0x6
ffffffffc0200060:	fc450513          	addi	a0,a0,-60 # ffffffffc0206020 <free_area>
ffffffffc0200064:	00006617          	auipc	a2,0x6
ffffffffc0200068:	41c60613          	addi	a2,a2,1052 # ffffffffc0206480 <end>
ffffffffc020006c:	8e09                	sub	a2,a2,a0
ffffffffc020006e:	4581                	li	a1,0
ffffffffc0200070:	195010ef          	jal	ra,ffffffffc0201a04 <memset>
    cons_init();  // init the console
ffffffffc0200074:	3fc000ef          	jal	ra,ffffffffc0200470 <cons_init>
    const char *message = "(THU.CST) os is loading ...\0";
    //cprintf("%s\n\n", message);
    cputs(message);
ffffffffc0200078:	00002517          	auipc	a0,0x2
ffffffffc020007c:	9a050513          	addi	a0,a0,-1632 # ffffffffc0201a18 <etext+0x2>
ffffffffc0200080:	090000ef          	jal	ra,ffffffffc0200110 <cputs>

    print_kerninfo();
ffffffffc0200084:	0dc000ef          	jal	ra,ffffffffc0200160 <print_kerninfo>

    // grade_backtrace();
    idt_init();  // init interrupt descriptor table
ffffffffc0200088:	43c000ef          	jal	ra,ffffffffc02004c4 <idt_init>

    pmm_init();  // init physical memory management
ffffffffc020008c:	2a2010ef          	jal	ra,ffffffffc020132e <pmm_init>

    idt_init();  // init interrupt descriptor table
ffffffffc0200090:	434000ef          	jal	ra,ffffffffc02004c4 <idt_init>

    clock_init();   // init clock interrupt
ffffffffc0200094:	39a000ef          	jal	ra,ffffffffc020042e <clock_init>
    intr_enable();  // enable irq interrupt
ffffffffc0200098:	420000ef          	jal	ra,ffffffffc02004b8 <intr_enable>
    // LAB1: CAHLLENGE 1 If you try to do it, uncomment lab1_switch_test()
    // user/kernel mode switch test
    // lab1_switch_test();

    /* do nothing */
    while (1)
ffffffffc020009c:	a001                	j	ffffffffc020009c <kern_init+0x48>

ffffffffc020009e <cputch>:
/* *
 * cputch - writes a single character @c to stdout, and it will
 * increace the value of counter pointed by @cnt.
 * */
static void
cputch(int c, int *cnt) {
ffffffffc020009e:	1141                	addi	sp,sp,-16
ffffffffc02000a0:	e022                	sd	s0,0(sp)
ffffffffc02000a2:	e406                	sd	ra,8(sp)
ffffffffc02000a4:	842e                	mv	s0,a1
    cons_putc(c);
ffffffffc02000a6:	3cc000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    (*cnt) ++;
ffffffffc02000aa:	401c                	lw	a5,0(s0)
}
ffffffffc02000ac:	60a2                	ld	ra,8(sp)
    (*cnt) ++;
ffffffffc02000ae:	2785                	addiw	a5,a5,1
ffffffffc02000b0:	c01c                	sw	a5,0(s0)
}
ffffffffc02000b2:	6402                	ld	s0,0(sp)
ffffffffc02000b4:	0141                	addi	sp,sp,16
ffffffffc02000b6:	8082                	ret

ffffffffc02000b8 <vcprintf>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want cprintf() instead.
 * */
int
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000b8:	1101                	addi	sp,sp,-32
ffffffffc02000ba:	862a                	mv	a2,a0
ffffffffc02000bc:	86ae                	mv	a3,a1
    int cnt = 0;
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000be:	00000517          	auipc	a0,0x0
ffffffffc02000c2:	fe050513          	addi	a0,a0,-32 # ffffffffc020009e <cputch>
ffffffffc02000c6:	006c                	addi	a1,sp,12
vcprintf(const char *fmt, va_list ap) {
ffffffffc02000c8:	ec06                	sd	ra,24(sp)
    int cnt = 0;
ffffffffc02000ca:	c602                	sw	zero,12(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000cc:	462010ef          	jal	ra,ffffffffc020152e <vprintfmt>
    return cnt;
}
ffffffffc02000d0:	60e2                	ld	ra,24(sp)
ffffffffc02000d2:	4532                	lw	a0,12(sp)
ffffffffc02000d4:	6105                	addi	sp,sp,32
ffffffffc02000d6:	8082                	ret

ffffffffc02000d8 <cprintf>:
 *
 * The return value is the number of characters which would be
 * written to stdout.
 * */
int
cprintf(const char *fmt, ...) {
ffffffffc02000d8:	711d                	addi	sp,sp,-96
    va_list ap;
    int cnt;
    va_start(ap, fmt);
ffffffffc02000da:	02810313          	addi	t1,sp,40 # ffffffffc0205028 <boot_page_table_sv39+0x28>
cprintf(const char *fmt, ...) {
ffffffffc02000de:	8e2a                	mv	t3,a0
ffffffffc02000e0:	f42e                	sd	a1,40(sp)
ffffffffc02000e2:	f832                	sd	a2,48(sp)
ffffffffc02000e4:	fc36                	sd	a3,56(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc02000e6:	00000517          	auipc	a0,0x0
ffffffffc02000ea:	fb850513          	addi	a0,a0,-72 # ffffffffc020009e <cputch>
ffffffffc02000ee:	004c                	addi	a1,sp,4
ffffffffc02000f0:	869a                	mv	a3,t1
ffffffffc02000f2:	8672                	mv	a2,t3
cprintf(const char *fmt, ...) {
ffffffffc02000f4:	ec06                	sd	ra,24(sp)
ffffffffc02000f6:	e0ba                	sd	a4,64(sp)
ffffffffc02000f8:	e4be                	sd	a5,72(sp)
ffffffffc02000fa:	e8c2                	sd	a6,80(sp)
ffffffffc02000fc:	ecc6                	sd	a7,88(sp)
    va_start(ap, fmt);
ffffffffc02000fe:	e41a                	sd	t1,8(sp)
    int cnt = 0;
ffffffffc0200100:	c202                	sw	zero,4(sp)
    vprintfmt((void*)cputch, &cnt, fmt, ap);
ffffffffc0200102:	42c010ef          	jal	ra,ffffffffc020152e <vprintfmt>
    cnt = vcprintf(fmt, ap);
    va_end(ap);
    return cnt;
}
ffffffffc0200106:	60e2                	ld	ra,24(sp)
ffffffffc0200108:	4512                	lw	a0,4(sp)
ffffffffc020010a:	6125                	addi	sp,sp,96
ffffffffc020010c:	8082                	ret

ffffffffc020010e <cputchar>:

/* cputchar - writes a single character to stdout */
void
cputchar(int c) {
    cons_putc(c);
ffffffffc020010e:	a695                	j	ffffffffc0200472 <cons_putc>

ffffffffc0200110 <cputs>:
/* *
 * cputs- writes the string pointed by @str to stdout and
 * appends a newline character.
 * */
int
cputs(const char *str) {
ffffffffc0200110:	1101                	addi	sp,sp,-32
ffffffffc0200112:	e822                	sd	s0,16(sp)
ffffffffc0200114:	ec06                	sd	ra,24(sp)
ffffffffc0200116:	e426                	sd	s1,8(sp)
ffffffffc0200118:	842a                	mv	s0,a0
    int cnt = 0;
    char c;
    while ((c = *str ++) != '\0') {
ffffffffc020011a:	00054503          	lbu	a0,0(a0)
ffffffffc020011e:	c51d                	beqz	a0,ffffffffc020014c <cputs+0x3c>
ffffffffc0200120:	0405                	addi	s0,s0,1
ffffffffc0200122:	4485                	li	s1,1
ffffffffc0200124:	9c81                	subw	s1,s1,s0
    cons_putc(c);
ffffffffc0200126:	34c000ef          	jal	ra,ffffffffc0200472 <cons_putc>
    while ((c = *str ++) != '\0') {
ffffffffc020012a:	00044503          	lbu	a0,0(s0)
ffffffffc020012e:	008487bb          	addw	a5,s1,s0
ffffffffc0200132:	0405                	addi	s0,s0,1
ffffffffc0200134:	f96d                	bnez	a0,ffffffffc0200126 <cputs+0x16>
    (*cnt) ++;
ffffffffc0200136:	0017841b          	addiw	s0,a5,1
    cons_putc(c);
ffffffffc020013a:	4529                	li	a0,10
ffffffffc020013c:	336000ef          	jal	ra,ffffffffc0200472 <cons_putc>
        cputch(c, &cnt);
    }
    cputch('\n', &cnt);
    return cnt;
}
ffffffffc0200140:	60e2                	ld	ra,24(sp)
ffffffffc0200142:	8522                	mv	a0,s0
ffffffffc0200144:	6442                	ld	s0,16(sp)
ffffffffc0200146:	64a2                	ld	s1,8(sp)
ffffffffc0200148:	6105                	addi	sp,sp,32
ffffffffc020014a:	8082                	ret
    while ((c = *str ++) != '\0') {
ffffffffc020014c:	4405                	li	s0,1
ffffffffc020014e:	b7f5                	j	ffffffffc020013a <cputs+0x2a>

ffffffffc0200150 <getchar>:

/* getchar - reads a single non-zero character from stdin */
int
getchar(void) {
ffffffffc0200150:	1141                	addi	sp,sp,-16
ffffffffc0200152:	e406                	sd	ra,8(sp)
    int c;
    while ((c = cons_getc()) == 0)
ffffffffc0200154:	326000ef          	jal	ra,ffffffffc020047a <cons_getc>
ffffffffc0200158:	dd75                	beqz	a0,ffffffffc0200154 <getchar+0x4>
        /* do nothing */;
    return c;
}
ffffffffc020015a:	60a2                	ld	ra,8(sp)
ffffffffc020015c:	0141                	addi	sp,sp,16
ffffffffc020015e:	8082                	ret

ffffffffc0200160 <print_kerninfo>:
/* *
 * print_kerninfo - print the information about kernel, including the location
 * of kernel entry, the start addresses of data and text segements, the start
 * address of free memory and how many memory that kernel has used.
 * */
void print_kerninfo(void) {
ffffffffc0200160:	1141                	addi	sp,sp,-16
    extern char etext[], edata[], end[], kern_init[];
    cprintf("Special kernel symbols:\n");
ffffffffc0200162:	00002517          	auipc	a0,0x2
ffffffffc0200166:	8d650513          	addi	a0,a0,-1834 # ffffffffc0201a38 <etext+0x22>
void print_kerninfo(void) {
ffffffffc020016a:	e406                	sd	ra,8(sp)
    cprintf("Special kernel symbols:\n");
ffffffffc020016c:	f6dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  entry  0x%016lx (virtual)\n", kern_init);
ffffffffc0200170:	00000597          	auipc	a1,0x0
ffffffffc0200174:	ee458593          	addi	a1,a1,-284 # ffffffffc0200054 <kern_init>
ffffffffc0200178:	00002517          	auipc	a0,0x2
ffffffffc020017c:	8e050513          	addi	a0,a0,-1824 # ffffffffc0201a58 <etext+0x42>
ffffffffc0200180:	f59ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  etext  0x%016lx (virtual)\n", etext);
ffffffffc0200184:	00002597          	auipc	a1,0x2
ffffffffc0200188:	89258593          	addi	a1,a1,-1902 # ffffffffc0201a16 <etext>
ffffffffc020018c:	00002517          	auipc	a0,0x2
ffffffffc0200190:	8ec50513          	addi	a0,a0,-1812 # ffffffffc0201a78 <etext+0x62>
ffffffffc0200194:	f45ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  edata  0x%016lx (virtual)\n", edata);
ffffffffc0200198:	00006597          	auipc	a1,0x6
ffffffffc020019c:	e8858593          	addi	a1,a1,-376 # ffffffffc0206020 <free_area>
ffffffffc02001a0:	00002517          	auipc	a0,0x2
ffffffffc02001a4:	8f850513          	addi	a0,a0,-1800 # ffffffffc0201a98 <etext+0x82>
ffffffffc02001a8:	f31ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  end    0x%016lx (virtual)\n", end);
ffffffffc02001ac:	00006597          	auipc	a1,0x6
ffffffffc02001b0:	2d458593          	addi	a1,a1,724 # ffffffffc0206480 <end>
ffffffffc02001b4:	00002517          	auipc	a0,0x2
ffffffffc02001b8:	90450513          	addi	a0,a0,-1788 # ffffffffc0201ab8 <etext+0xa2>
ffffffffc02001bc:	f1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Kernel executable memory footprint: %dKB\n",
            (end - kern_init + 1023) / 1024);
ffffffffc02001c0:	00006597          	auipc	a1,0x6
ffffffffc02001c4:	6bf58593          	addi	a1,a1,1727 # ffffffffc020687f <end+0x3ff>
ffffffffc02001c8:	00000797          	auipc	a5,0x0
ffffffffc02001cc:	e8c78793          	addi	a5,a5,-372 # ffffffffc0200054 <kern_init>
ffffffffc02001d0:	40f587b3          	sub	a5,a1,a5
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001d4:	43f7d593          	srai	a1,a5,0x3f
}
ffffffffc02001d8:	60a2                	ld	ra,8(sp)
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001da:	3ff5f593          	andi	a1,a1,1023
ffffffffc02001de:	95be                	add	a1,a1,a5
ffffffffc02001e0:	85a9                	srai	a1,a1,0xa
ffffffffc02001e2:	00002517          	auipc	a0,0x2
ffffffffc02001e6:	8f650513          	addi	a0,a0,-1802 # ffffffffc0201ad8 <etext+0xc2>
}
ffffffffc02001ea:	0141                	addi	sp,sp,16
    cprintf("Kernel executable memory footprint: %dKB\n",
ffffffffc02001ec:	b5f5                	j	ffffffffc02000d8 <cprintf>

ffffffffc02001ee <print_stackframe>:
 * Note that, the length of ebp-chain is limited. In boot/bootasm.S, before
 * jumping
 * to the kernel entry, the value of ebp has been set to zero, that's the
 * boundary.
 * */
void print_stackframe(void) {
ffffffffc02001ee:	1141                	addi	sp,sp,-16
     * and line number, etc.
     *    (3.5) popup a calling stackframe
     *           NOTICE: the calling funciton's return addr eip  = ss:[ebp+4]
     *                   the calling funciton's ebp = ss:[ebp]
     */
    panic("Not Implemented!");
ffffffffc02001f0:	00002617          	auipc	a2,0x2
ffffffffc02001f4:	91860613          	addi	a2,a2,-1768 # ffffffffc0201b08 <etext+0xf2>
ffffffffc02001f8:	05b00593          	li	a1,91
ffffffffc02001fc:	00002517          	auipc	a0,0x2
ffffffffc0200200:	92450513          	addi	a0,a0,-1756 # ffffffffc0201b20 <etext+0x10a>
void print_stackframe(void) {
ffffffffc0200204:	e406                	sd	ra,8(sp)
    panic("Not Implemented!");
ffffffffc0200206:	1cc000ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020020a <mon_help>:
    }
}

/* mon_help - print the information about mon_* functions */
int
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc020020a:	1141                	addi	sp,sp,-16
    int i;
    for (i = 0; i < NCOMMANDS; i ++) {
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc020020c:	00002617          	auipc	a2,0x2
ffffffffc0200210:	92c60613          	addi	a2,a2,-1748 # ffffffffc0201b38 <etext+0x122>
ffffffffc0200214:	00002597          	auipc	a1,0x2
ffffffffc0200218:	94458593          	addi	a1,a1,-1724 # ffffffffc0201b58 <etext+0x142>
ffffffffc020021c:	00002517          	auipc	a0,0x2
ffffffffc0200220:	94450513          	addi	a0,a0,-1724 # ffffffffc0201b60 <etext+0x14a>
mon_help(int argc, char **argv, struct trapframe *tf) {
ffffffffc0200224:	e406                	sd	ra,8(sp)
        cprintf("%s - %s\n", commands[i].name, commands[i].desc);
ffffffffc0200226:	eb3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc020022a:	00002617          	auipc	a2,0x2
ffffffffc020022e:	94660613          	addi	a2,a2,-1722 # ffffffffc0201b70 <etext+0x15a>
ffffffffc0200232:	00002597          	auipc	a1,0x2
ffffffffc0200236:	96658593          	addi	a1,a1,-1690 # ffffffffc0201b98 <etext+0x182>
ffffffffc020023a:	00002517          	auipc	a0,0x2
ffffffffc020023e:	92650513          	addi	a0,a0,-1754 # ffffffffc0201b60 <etext+0x14a>
ffffffffc0200242:	e97ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc0200246:	00002617          	auipc	a2,0x2
ffffffffc020024a:	96260613          	addi	a2,a2,-1694 # ffffffffc0201ba8 <etext+0x192>
ffffffffc020024e:	00002597          	auipc	a1,0x2
ffffffffc0200252:	97a58593          	addi	a1,a1,-1670 # ffffffffc0201bc8 <etext+0x1b2>
ffffffffc0200256:	00002517          	auipc	a0,0x2
ffffffffc020025a:	90a50513          	addi	a0,a0,-1782 # ffffffffc0201b60 <etext+0x14a>
ffffffffc020025e:	e7bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    }
    return 0;
}
ffffffffc0200262:	60a2                	ld	ra,8(sp)
ffffffffc0200264:	4501                	li	a0,0
ffffffffc0200266:	0141                	addi	sp,sp,16
ffffffffc0200268:	8082                	ret

ffffffffc020026a <mon_kerninfo>:
/* *
 * mon_kerninfo - call print_kerninfo in kern/debug/kdebug.c to
 * print the memory occupancy in kernel.
 * */
int
mon_kerninfo(int argc, char **argv, struct trapframe *tf) {
ffffffffc020026a:	1141                	addi	sp,sp,-16
ffffffffc020026c:	e406                	sd	ra,8(sp)
    print_kerninfo();
ffffffffc020026e:	ef3ff0ef          	jal	ra,ffffffffc0200160 <print_kerninfo>
    return 0;
}
ffffffffc0200272:	60a2                	ld	ra,8(sp)
ffffffffc0200274:	4501                	li	a0,0
ffffffffc0200276:	0141                	addi	sp,sp,16
ffffffffc0200278:	8082                	ret

ffffffffc020027a <mon_backtrace>:
/* *
 * mon_backtrace - call print_stackframe in kern/debug/kdebug.c to
 * print a backtrace of the stack.
 * */
int
mon_backtrace(int argc, char **argv, struct trapframe *tf) {
ffffffffc020027a:	1141                	addi	sp,sp,-16
ffffffffc020027c:	e406                	sd	ra,8(sp)
    print_stackframe();
ffffffffc020027e:	f71ff0ef          	jal	ra,ffffffffc02001ee <print_stackframe>
    return 0;
}
ffffffffc0200282:	60a2                	ld	ra,8(sp)
ffffffffc0200284:	4501                	li	a0,0
ffffffffc0200286:	0141                	addi	sp,sp,16
ffffffffc0200288:	8082                	ret

ffffffffc020028a <kmonitor>:
kmonitor(struct trapframe *tf) {
ffffffffc020028a:	7115                	addi	sp,sp,-224
ffffffffc020028c:	ed5e                	sd	s7,152(sp)
ffffffffc020028e:	8baa                	mv	s7,a0
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc0200290:	00002517          	auipc	a0,0x2
ffffffffc0200294:	94850513          	addi	a0,a0,-1720 # ffffffffc0201bd8 <etext+0x1c2>
kmonitor(struct trapframe *tf) {
ffffffffc0200298:	ed86                	sd	ra,216(sp)
ffffffffc020029a:	e9a2                	sd	s0,208(sp)
ffffffffc020029c:	e5a6                	sd	s1,200(sp)
ffffffffc020029e:	e1ca                	sd	s2,192(sp)
ffffffffc02002a0:	fd4e                	sd	s3,184(sp)
ffffffffc02002a2:	f952                	sd	s4,176(sp)
ffffffffc02002a4:	f556                	sd	s5,168(sp)
ffffffffc02002a6:	f15a                	sd	s6,160(sp)
ffffffffc02002a8:	e962                	sd	s8,144(sp)
ffffffffc02002aa:	e566                	sd	s9,136(sp)
ffffffffc02002ac:	e16a                	sd	s10,128(sp)
    cprintf("Welcome to the kernel debug monitor!!\n");
ffffffffc02002ae:	e2bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("Type 'help' for a list of commands.\n");
ffffffffc02002b2:	00002517          	auipc	a0,0x2
ffffffffc02002b6:	94e50513          	addi	a0,a0,-1714 # ffffffffc0201c00 <etext+0x1ea>
ffffffffc02002ba:	e1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    if (tf != NULL) {
ffffffffc02002be:	000b8563          	beqz	s7,ffffffffc02002c8 <kmonitor+0x3e>
        print_trapframe(tf);
ffffffffc02002c2:	855e                	mv	a0,s7
ffffffffc02002c4:	3de000ef          	jal	ra,ffffffffc02006a2 <print_trapframe>
ffffffffc02002c8:	00002c17          	auipc	s8,0x2
ffffffffc02002cc:	9a8c0c13          	addi	s8,s8,-1624 # ffffffffc0201c70 <commands>
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002d0:	00002917          	auipc	s2,0x2
ffffffffc02002d4:	95890913          	addi	s2,s2,-1704 # ffffffffc0201c28 <etext+0x212>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002d8:	00002497          	auipc	s1,0x2
ffffffffc02002dc:	95848493          	addi	s1,s1,-1704 # ffffffffc0201c30 <etext+0x21a>
        if (argc == MAXARGS - 1) {
ffffffffc02002e0:	49bd                	li	s3,15
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02002e2:	00002b17          	auipc	s6,0x2
ffffffffc02002e6:	956b0b13          	addi	s6,s6,-1706 # ffffffffc0201c38 <etext+0x222>
        argv[argc ++] = buf;
ffffffffc02002ea:	00002a17          	auipc	s4,0x2
ffffffffc02002ee:	86ea0a13          	addi	s4,s4,-1938 # ffffffffc0201b58 <etext+0x142>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc02002f2:	4a8d                	li	s5,3
        if ((buf = readline("K> ")) != NULL) {
ffffffffc02002f4:	854a                	mv	a0,s2
ffffffffc02002f6:	5ba010ef          	jal	ra,ffffffffc02018b0 <readline>
ffffffffc02002fa:	842a                	mv	s0,a0
ffffffffc02002fc:	dd65                	beqz	a0,ffffffffc02002f4 <kmonitor+0x6a>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02002fe:	00054583          	lbu	a1,0(a0)
    int argc = 0;
ffffffffc0200302:	4c81                	li	s9,0
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc0200304:	e1bd                	bnez	a1,ffffffffc020036a <kmonitor+0xe0>
    if (argc == 0) {
ffffffffc0200306:	fe0c87e3          	beqz	s9,ffffffffc02002f4 <kmonitor+0x6a>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020030a:	6582                	ld	a1,0(sp)
ffffffffc020030c:	00002d17          	auipc	s10,0x2
ffffffffc0200310:	964d0d13          	addi	s10,s10,-1692 # ffffffffc0201c70 <commands>
        argv[argc ++] = buf;
ffffffffc0200314:	8552                	mv	a0,s4
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200316:	4401                	li	s0,0
ffffffffc0200318:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020031a:	6b6010ef          	jal	ra,ffffffffc02019d0 <strcmp>
ffffffffc020031e:	c919                	beqz	a0,ffffffffc0200334 <kmonitor+0xaa>
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc0200320:	2405                	addiw	s0,s0,1
ffffffffc0200322:	0b540063          	beq	s0,s5,ffffffffc02003c2 <kmonitor+0x138>
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc0200326:	000d3503          	ld	a0,0(s10)
ffffffffc020032a:	6582                	ld	a1,0(sp)
    for (i = 0; i < NCOMMANDS; i ++) {
ffffffffc020032c:	0d61                	addi	s10,s10,24
        if (strcmp(commands[i].name, argv[0]) == 0) {
ffffffffc020032e:	6a2010ef          	jal	ra,ffffffffc02019d0 <strcmp>
ffffffffc0200332:	f57d                	bnez	a0,ffffffffc0200320 <kmonitor+0x96>
            return commands[i].func(argc - 1, argv + 1, tf);
ffffffffc0200334:	00141793          	slli	a5,s0,0x1
ffffffffc0200338:	97a2                	add	a5,a5,s0
ffffffffc020033a:	078e                	slli	a5,a5,0x3
ffffffffc020033c:	97e2                	add	a5,a5,s8
ffffffffc020033e:	6b9c                	ld	a5,16(a5)
ffffffffc0200340:	865e                	mv	a2,s7
ffffffffc0200342:	002c                	addi	a1,sp,8
ffffffffc0200344:	fffc851b          	addiw	a0,s9,-1
ffffffffc0200348:	9782                	jalr	a5
            if (runcmd(buf, tf) < 0) {
ffffffffc020034a:	fa0555e3          	bgez	a0,ffffffffc02002f4 <kmonitor+0x6a>
}
ffffffffc020034e:	60ee                	ld	ra,216(sp)
ffffffffc0200350:	644e                	ld	s0,208(sp)
ffffffffc0200352:	64ae                	ld	s1,200(sp)
ffffffffc0200354:	690e                	ld	s2,192(sp)
ffffffffc0200356:	79ea                	ld	s3,184(sp)
ffffffffc0200358:	7a4a                	ld	s4,176(sp)
ffffffffc020035a:	7aaa                	ld	s5,168(sp)
ffffffffc020035c:	7b0a                	ld	s6,160(sp)
ffffffffc020035e:	6bea                	ld	s7,152(sp)
ffffffffc0200360:	6c4a                	ld	s8,144(sp)
ffffffffc0200362:	6caa                	ld	s9,136(sp)
ffffffffc0200364:	6d0a                	ld	s10,128(sp)
ffffffffc0200366:	612d                	addi	sp,sp,224
ffffffffc0200368:	8082                	ret
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020036a:	8526                	mv	a0,s1
ffffffffc020036c:	682010ef          	jal	ra,ffffffffc02019ee <strchr>
ffffffffc0200370:	c901                	beqz	a0,ffffffffc0200380 <kmonitor+0xf6>
ffffffffc0200372:	00144583          	lbu	a1,1(s0)
            *buf ++ = '\0';
ffffffffc0200376:	00040023          	sb	zero,0(s0)
ffffffffc020037a:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc020037c:	d5c9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc020037e:	b7f5                	j	ffffffffc020036a <kmonitor+0xe0>
        if (*buf == '\0') {
ffffffffc0200380:	00044783          	lbu	a5,0(s0)
ffffffffc0200384:	d3c9                	beqz	a5,ffffffffc0200306 <kmonitor+0x7c>
        if (argc == MAXARGS - 1) {
ffffffffc0200386:	033c8963          	beq	s9,s3,ffffffffc02003b8 <kmonitor+0x12e>
        argv[argc ++] = buf;
ffffffffc020038a:	003c9793          	slli	a5,s9,0x3
ffffffffc020038e:	0118                	addi	a4,sp,128
ffffffffc0200390:	97ba                	add	a5,a5,a4
ffffffffc0200392:	f887b023          	sd	s0,-128(a5)
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc0200396:	00044583          	lbu	a1,0(s0)
        argv[argc ++] = buf;
ffffffffc020039a:	2c85                	addiw	s9,s9,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc020039c:	e591                	bnez	a1,ffffffffc02003a8 <kmonitor+0x11e>
ffffffffc020039e:	b7b5                	j	ffffffffc020030a <kmonitor+0x80>
ffffffffc02003a0:	00144583          	lbu	a1,1(s0)
            buf ++;
ffffffffc02003a4:	0405                	addi	s0,s0,1
        while (*buf != '\0' && strchr(WHITESPACE, *buf) == NULL) {
ffffffffc02003a6:	d1a5                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003a8:	8526                	mv	a0,s1
ffffffffc02003aa:	644010ef          	jal	ra,ffffffffc02019ee <strchr>
ffffffffc02003ae:	d96d                	beqz	a0,ffffffffc02003a0 <kmonitor+0x116>
        while (*buf != '\0' && strchr(WHITESPACE, *buf) != NULL) {
ffffffffc02003b0:	00044583          	lbu	a1,0(s0)
ffffffffc02003b4:	d9a9                	beqz	a1,ffffffffc0200306 <kmonitor+0x7c>
ffffffffc02003b6:	bf55                	j	ffffffffc020036a <kmonitor+0xe0>
            cprintf("Too many arguments (max %d).\n", MAXARGS);
ffffffffc02003b8:	45c1                	li	a1,16
ffffffffc02003ba:	855a                	mv	a0,s6
ffffffffc02003bc:	d1dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
ffffffffc02003c0:	b7e9                	j	ffffffffc020038a <kmonitor+0x100>
    cprintf("Unknown command '%s'\n", argv[0]);
ffffffffc02003c2:	6582                	ld	a1,0(sp)
ffffffffc02003c4:	00002517          	auipc	a0,0x2
ffffffffc02003c8:	89450513          	addi	a0,a0,-1900 # ffffffffc0201c58 <etext+0x242>
ffffffffc02003cc:	d0dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    return 0;
ffffffffc02003d0:	b715                	j	ffffffffc02002f4 <kmonitor+0x6a>

ffffffffc02003d2 <__panic>:
 * __panic - __panic is called on unresolvable fatal errors. it prints
 * "panic: 'message'", and then enters the kernel monitor.
 * */
void
__panic(const char *file, int line, const char *fmt, ...) {
    if (is_panic) {
ffffffffc02003d2:	00006317          	auipc	t1,0x6
ffffffffc02003d6:	06630313          	addi	t1,t1,102 # ffffffffc0206438 <is_panic>
ffffffffc02003da:	00032e03          	lw	t3,0(t1)
__panic(const char *file, int line, const char *fmt, ...) {
ffffffffc02003de:	715d                	addi	sp,sp,-80
ffffffffc02003e0:	ec06                	sd	ra,24(sp)
ffffffffc02003e2:	e822                	sd	s0,16(sp)
ffffffffc02003e4:	f436                	sd	a3,40(sp)
ffffffffc02003e6:	f83a                	sd	a4,48(sp)
ffffffffc02003e8:	fc3e                	sd	a5,56(sp)
ffffffffc02003ea:	e0c2                	sd	a6,64(sp)
ffffffffc02003ec:	e4c6                	sd	a7,72(sp)
    if (is_panic) {
ffffffffc02003ee:	020e1a63          	bnez	t3,ffffffffc0200422 <__panic+0x50>
        goto panic_dead;
    }
    is_panic = 1;
ffffffffc02003f2:	4785                	li	a5,1
ffffffffc02003f4:	00f32023          	sw	a5,0(t1)

    // print the 'message'
    va_list ap;
    va_start(ap, fmt);
ffffffffc02003f8:	8432                	mv	s0,a2
ffffffffc02003fa:	103c                	addi	a5,sp,40
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc02003fc:	862e                	mv	a2,a1
ffffffffc02003fe:	85aa                	mv	a1,a0
ffffffffc0200400:	00002517          	auipc	a0,0x2
ffffffffc0200404:	8b850513          	addi	a0,a0,-1864 # ffffffffc0201cb8 <commands+0x48>
    va_start(ap, fmt);
ffffffffc0200408:	e43e                	sd	a5,8(sp)
    cprintf("kernel panic at %s:%d:\n    ", file, line);
ffffffffc020040a:	ccfff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    vcprintf(fmt, ap);
ffffffffc020040e:	65a2                	ld	a1,8(sp)
ffffffffc0200410:	8522                	mv	a0,s0
ffffffffc0200412:	ca7ff0ef          	jal	ra,ffffffffc02000b8 <vcprintf>
    cprintf("\n");
ffffffffc0200416:	00001517          	auipc	a0,0x1
ffffffffc020041a:	6ea50513          	addi	a0,a0,1770 # ffffffffc0201b00 <etext+0xea>
ffffffffc020041e:	cbbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    va_end(ap);

panic_dead:
    intr_disable();
ffffffffc0200422:	09c000ef          	jal	ra,ffffffffc02004be <intr_disable>
    while (1) {
        kmonitor(NULL);
ffffffffc0200426:	4501                	li	a0,0
ffffffffc0200428:	e63ff0ef          	jal	ra,ffffffffc020028a <kmonitor>
    while (1) {
ffffffffc020042c:	bfed                	j	ffffffffc0200426 <__panic+0x54>

ffffffffc020042e <clock_init>:

/* *
 * clock_init - initialize 8253 clock to interrupt 100 times per second,
 * and then enable IRQ_TIMER.
 * */
void clock_init(void) {
ffffffffc020042e:	1141                	addi	sp,sp,-16
ffffffffc0200430:	e406                	sd	ra,8(sp)
    // enable timer interrupt in sie
    set_csr(sie, MIP_STIP);
ffffffffc0200432:	02000793          	li	a5,32
ffffffffc0200436:	1047a7f3          	csrrs	a5,sie,a5
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc020043a:	c0102573          	rdtime	a0
    ticks = 0;

    cprintf("++ setup timer interrupts\n");
}

void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc020043e:	67e1                	lui	a5,0x18
ffffffffc0200440:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc0200444:	953e                	add	a0,a0,a5
ffffffffc0200446:	538010ef          	jal	ra,ffffffffc020197e <sbi_set_timer>
}
ffffffffc020044a:	60a2                	ld	ra,8(sp)
    ticks = 0;
ffffffffc020044c:	00006797          	auipc	a5,0x6
ffffffffc0200450:	fe07ba23          	sd	zero,-12(a5) # ffffffffc0206440 <ticks>
    cprintf("++ setup timer interrupts\n");
ffffffffc0200454:	00002517          	auipc	a0,0x2
ffffffffc0200458:	88450513          	addi	a0,a0,-1916 # ffffffffc0201cd8 <commands+0x68>
}
ffffffffc020045c:	0141                	addi	sp,sp,16
    cprintf("++ setup timer interrupts\n");
ffffffffc020045e:	b9ad                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200460 <clock_set_next_event>:
    __asm__ __volatile__("rdtime %0" : "=r"(n));
ffffffffc0200460:	c0102573          	rdtime	a0
void clock_set_next_event(void) { sbi_set_timer(get_cycles() + timebase); }
ffffffffc0200464:	67e1                	lui	a5,0x18
ffffffffc0200466:	6a078793          	addi	a5,a5,1696 # 186a0 <kern_entry-0xffffffffc01e7960>
ffffffffc020046a:	953e                	add	a0,a0,a5
ffffffffc020046c:	5120106f          	j	ffffffffc020197e <sbi_set_timer>

ffffffffc0200470 <cons_init>:

/* serial_intr - try to feed input characters from serial port */
void serial_intr(void) {}

/* cons_init - initializes the console devices */
void cons_init(void) {}
ffffffffc0200470:	8082                	ret

ffffffffc0200472 <cons_putc>:

/* cons_putc - print a single character @c to console devices */
void cons_putc(int c) { sbi_console_putchar((unsigned char)c); }
ffffffffc0200472:	0ff57513          	zext.b	a0,a0
ffffffffc0200476:	4ee0106f          	j	ffffffffc0201964 <sbi_console_putchar>

ffffffffc020047a <cons_getc>:
 * cons_getc - return the next input character from console,
 * or 0 if none waiting.
 * */
int cons_getc(void) {
    int c = 0;
    c = sbi_console_getchar();
ffffffffc020047a:	51e0106f          	j	ffffffffc0201998 <sbi_console_getchar>

ffffffffc020047e <dtb_init>:
#include <dtb.h>
#include <stdio.h>

void dtb_init(void) {
ffffffffc020047e:	1141                	addi	sp,sp,-16
    cprintf("DTB Init\n");
ffffffffc0200480:	00002517          	auipc	a0,0x2
ffffffffc0200484:	87850513          	addi	a0,a0,-1928 # ffffffffc0201cf8 <commands+0x88>
void dtb_init(void) {
ffffffffc0200488:	e406                	sd	ra,8(sp)
    cprintf("DTB Init\n");
ffffffffc020048a:	c4fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("HartID: %ld\n", boot_hartid);
ffffffffc020048e:	00006597          	auipc	a1,0x6
ffffffffc0200492:	b725b583          	ld	a1,-1166(a1) # ffffffffc0206000 <boot_hartid>
ffffffffc0200496:	00002517          	auipc	a0,0x2
ffffffffc020049a:	87250513          	addi	a0,a0,-1934 # ffffffffc0201d08 <commands+0x98>
ffffffffc020049e:	c3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
    // 在这里添加解析设备树的代码
}
ffffffffc02004a2:	60a2                	ld	ra,8(sp)
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004a4:	00006597          	auipc	a1,0x6
ffffffffc02004a8:	b645b583          	ld	a1,-1180(a1) # ffffffffc0206008 <boot_dtb>
ffffffffc02004ac:	00002517          	auipc	a0,0x2
ffffffffc02004b0:	86c50513          	addi	a0,a0,-1940 # ffffffffc0201d18 <commands+0xa8>
}
ffffffffc02004b4:	0141                	addi	sp,sp,16
    cprintf("DTB Address: 0x%lx\n", boot_dtb);
ffffffffc02004b6:	b10d                	j	ffffffffc02000d8 <cprintf>

ffffffffc02004b8 <intr_enable>:
#include <intr.h>
#include <riscv.h>

/* intr_enable - enable irq interrupt */
void intr_enable(void) { set_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004b8:	100167f3          	csrrsi	a5,sstatus,2
ffffffffc02004bc:	8082                	ret

ffffffffc02004be <intr_disable>:

/* intr_disable - disable irq interrupt */
void intr_disable(void) { clear_csr(sstatus, SSTATUS_SIE); }
ffffffffc02004be:	100177f3          	csrrci	a5,sstatus,2
ffffffffc02004c2:	8082                	ret

ffffffffc02004c4 <idt_init>:
     */

    extern void __alltraps(void);
    /* Set sup0 scratch register to 0, indicating to exception vector
       that we are presently executing in the kernel */
    write_csr(sscratch, 0);
ffffffffc02004c4:	14005073          	csrwi	sscratch,0
    /* Set the exception vector address */
    write_csr(stvec, &__alltraps);
ffffffffc02004c8:	00000797          	auipc	a5,0x0
ffffffffc02004cc:	2ec78793          	addi	a5,a5,748 # ffffffffc02007b4 <__alltraps>
ffffffffc02004d0:	10579073          	csrw	stvec,a5
}
ffffffffc02004d4:	8082                	ret

ffffffffc02004d6 <print_regs>:
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
    cprintf("  cause    0x%08x\n", tf->cause);
}

void print_regs(struct pushregs *gpr) {
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02004d6:	610c                	ld	a1,0(a0)
void print_regs(struct pushregs *gpr) {
ffffffffc02004d8:	1141                	addi	sp,sp,-16
ffffffffc02004da:	e022                	sd	s0,0(sp)
ffffffffc02004dc:	842a                	mv	s0,a0
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02004de:	00002517          	auipc	a0,0x2
ffffffffc02004e2:	85250513          	addi	a0,a0,-1966 # ffffffffc0201d30 <commands+0xc0>
void print_regs(struct pushregs *gpr) {
ffffffffc02004e6:	e406                	sd	ra,8(sp)
    cprintf("  zero     0x%08x\n", gpr->zero);
ffffffffc02004e8:	bf1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  ra       0x%08x\n", gpr->ra);
ffffffffc02004ec:	640c                	ld	a1,8(s0)
ffffffffc02004ee:	00002517          	auipc	a0,0x2
ffffffffc02004f2:	85a50513          	addi	a0,a0,-1958 # ffffffffc0201d48 <commands+0xd8>
ffffffffc02004f6:	be3ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  sp       0x%08x\n", gpr->sp);
ffffffffc02004fa:	680c                	ld	a1,16(s0)
ffffffffc02004fc:	00002517          	auipc	a0,0x2
ffffffffc0200500:	86450513          	addi	a0,a0,-1948 # ffffffffc0201d60 <commands+0xf0>
ffffffffc0200504:	bd5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  gp       0x%08x\n", gpr->gp);
ffffffffc0200508:	6c0c                	ld	a1,24(s0)
ffffffffc020050a:	00002517          	auipc	a0,0x2
ffffffffc020050e:	86e50513          	addi	a0,a0,-1938 # ffffffffc0201d78 <commands+0x108>
ffffffffc0200512:	bc7ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  tp       0x%08x\n", gpr->tp);
ffffffffc0200516:	700c                	ld	a1,32(s0)
ffffffffc0200518:	00002517          	auipc	a0,0x2
ffffffffc020051c:	87850513          	addi	a0,a0,-1928 # ffffffffc0201d90 <commands+0x120>
ffffffffc0200520:	bb9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t0       0x%08x\n", gpr->t0);
ffffffffc0200524:	740c                	ld	a1,40(s0)
ffffffffc0200526:	00002517          	auipc	a0,0x2
ffffffffc020052a:	88250513          	addi	a0,a0,-1918 # ffffffffc0201da8 <commands+0x138>
ffffffffc020052e:	babff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t1       0x%08x\n", gpr->t1);
ffffffffc0200532:	780c                	ld	a1,48(s0)
ffffffffc0200534:	00002517          	auipc	a0,0x2
ffffffffc0200538:	88c50513          	addi	a0,a0,-1908 # ffffffffc0201dc0 <commands+0x150>
ffffffffc020053c:	b9dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t2       0x%08x\n", gpr->t2);
ffffffffc0200540:	7c0c                	ld	a1,56(s0)
ffffffffc0200542:	00002517          	auipc	a0,0x2
ffffffffc0200546:	89650513          	addi	a0,a0,-1898 # ffffffffc0201dd8 <commands+0x168>
ffffffffc020054a:	b8fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s0       0x%08x\n", gpr->s0);
ffffffffc020054e:	602c                	ld	a1,64(s0)
ffffffffc0200550:	00002517          	auipc	a0,0x2
ffffffffc0200554:	8a050513          	addi	a0,a0,-1888 # ffffffffc0201df0 <commands+0x180>
ffffffffc0200558:	b81ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s1       0x%08x\n", gpr->s1);
ffffffffc020055c:	642c                	ld	a1,72(s0)
ffffffffc020055e:	00002517          	auipc	a0,0x2
ffffffffc0200562:	8aa50513          	addi	a0,a0,-1878 # ffffffffc0201e08 <commands+0x198>
ffffffffc0200566:	b73ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a0       0x%08x\n", gpr->a0);
ffffffffc020056a:	682c                	ld	a1,80(s0)
ffffffffc020056c:	00002517          	auipc	a0,0x2
ffffffffc0200570:	8b450513          	addi	a0,a0,-1868 # ffffffffc0201e20 <commands+0x1b0>
ffffffffc0200574:	b65ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a1       0x%08x\n", gpr->a1);
ffffffffc0200578:	6c2c                	ld	a1,88(s0)
ffffffffc020057a:	00002517          	auipc	a0,0x2
ffffffffc020057e:	8be50513          	addi	a0,a0,-1858 # ffffffffc0201e38 <commands+0x1c8>
ffffffffc0200582:	b57ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a2       0x%08x\n", gpr->a2);
ffffffffc0200586:	702c                	ld	a1,96(s0)
ffffffffc0200588:	00002517          	auipc	a0,0x2
ffffffffc020058c:	8c850513          	addi	a0,a0,-1848 # ffffffffc0201e50 <commands+0x1e0>
ffffffffc0200590:	b49ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a3       0x%08x\n", gpr->a3);
ffffffffc0200594:	742c                	ld	a1,104(s0)
ffffffffc0200596:	00002517          	auipc	a0,0x2
ffffffffc020059a:	8d250513          	addi	a0,a0,-1838 # ffffffffc0201e68 <commands+0x1f8>
ffffffffc020059e:	b3bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a4       0x%08x\n", gpr->a4);
ffffffffc02005a2:	782c                	ld	a1,112(s0)
ffffffffc02005a4:	00002517          	auipc	a0,0x2
ffffffffc02005a8:	8dc50513          	addi	a0,a0,-1828 # ffffffffc0201e80 <commands+0x210>
ffffffffc02005ac:	b2dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a5       0x%08x\n", gpr->a5);
ffffffffc02005b0:	7c2c                	ld	a1,120(s0)
ffffffffc02005b2:	00002517          	auipc	a0,0x2
ffffffffc02005b6:	8e650513          	addi	a0,a0,-1818 # ffffffffc0201e98 <commands+0x228>
ffffffffc02005ba:	b1fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a6       0x%08x\n", gpr->a6);
ffffffffc02005be:	604c                	ld	a1,128(s0)
ffffffffc02005c0:	00002517          	auipc	a0,0x2
ffffffffc02005c4:	8f050513          	addi	a0,a0,-1808 # ffffffffc0201eb0 <commands+0x240>
ffffffffc02005c8:	b11ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  a7       0x%08x\n", gpr->a7);
ffffffffc02005cc:	644c                	ld	a1,136(s0)
ffffffffc02005ce:	00002517          	auipc	a0,0x2
ffffffffc02005d2:	8fa50513          	addi	a0,a0,-1798 # ffffffffc0201ec8 <commands+0x258>
ffffffffc02005d6:	b03ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s2       0x%08x\n", gpr->s2);
ffffffffc02005da:	684c                	ld	a1,144(s0)
ffffffffc02005dc:	00002517          	auipc	a0,0x2
ffffffffc02005e0:	90450513          	addi	a0,a0,-1788 # ffffffffc0201ee0 <commands+0x270>
ffffffffc02005e4:	af5ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s3       0x%08x\n", gpr->s3);
ffffffffc02005e8:	6c4c                	ld	a1,152(s0)
ffffffffc02005ea:	00002517          	auipc	a0,0x2
ffffffffc02005ee:	90e50513          	addi	a0,a0,-1778 # ffffffffc0201ef8 <commands+0x288>
ffffffffc02005f2:	ae7ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s4       0x%08x\n", gpr->s4);
ffffffffc02005f6:	704c                	ld	a1,160(s0)
ffffffffc02005f8:	00002517          	auipc	a0,0x2
ffffffffc02005fc:	91850513          	addi	a0,a0,-1768 # ffffffffc0201f10 <commands+0x2a0>
ffffffffc0200600:	ad9ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s5       0x%08x\n", gpr->s5);
ffffffffc0200604:	744c                	ld	a1,168(s0)
ffffffffc0200606:	00002517          	auipc	a0,0x2
ffffffffc020060a:	92250513          	addi	a0,a0,-1758 # ffffffffc0201f28 <commands+0x2b8>
ffffffffc020060e:	acbff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s6       0x%08x\n", gpr->s6);
ffffffffc0200612:	784c                	ld	a1,176(s0)
ffffffffc0200614:	00002517          	auipc	a0,0x2
ffffffffc0200618:	92c50513          	addi	a0,a0,-1748 # ffffffffc0201f40 <commands+0x2d0>
ffffffffc020061c:	abdff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s7       0x%08x\n", gpr->s7);
ffffffffc0200620:	7c4c                	ld	a1,184(s0)
ffffffffc0200622:	00002517          	auipc	a0,0x2
ffffffffc0200626:	93650513          	addi	a0,a0,-1738 # ffffffffc0201f58 <commands+0x2e8>
ffffffffc020062a:	aafff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s8       0x%08x\n", gpr->s8);
ffffffffc020062e:	606c                	ld	a1,192(s0)
ffffffffc0200630:	00002517          	auipc	a0,0x2
ffffffffc0200634:	94050513          	addi	a0,a0,-1728 # ffffffffc0201f70 <commands+0x300>
ffffffffc0200638:	aa1ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s9       0x%08x\n", gpr->s9);
ffffffffc020063c:	646c                	ld	a1,200(s0)
ffffffffc020063e:	00002517          	auipc	a0,0x2
ffffffffc0200642:	94a50513          	addi	a0,a0,-1718 # ffffffffc0201f88 <commands+0x318>
ffffffffc0200646:	a93ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s10      0x%08x\n", gpr->s10);
ffffffffc020064a:	686c                	ld	a1,208(s0)
ffffffffc020064c:	00002517          	auipc	a0,0x2
ffffffffc0200650:	95450513          	addi	a0,a0,-1708 # ffffffffc0201fa0 <commands+0x330>
ffffffffc0200654:	a85ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  s11      0x%08x\n", gpr->s11);
ffffffffc0200658:	6c6c                	ld	a1,216(s0)
ffffffffc020065a:	00002517          	auipc	a0,0x2
ffffffffc020065e:	95e50513          	addi	a0,a0,-1698 # ffffffffc0201fb8 <commands+0x348>
ffffffffc0200662:	a77ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t3       0x%08x\n", gpr->t3);
ffffffffc0200666:	706c                	ld	a1,224(s0)
ffffffffc0200668:	00002517          	auipc	a0,0x2
ffffffffc020066c:	96850513          	addi	a0,a0,-1688 # ffffffffc0201fd0 <commands+0x360>
ffffffffc0200670:	a69ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t4       0x%08x\n", gpr->t4);
ffffffffc0200674:	746c                	ld	a1,232(s0)
ffffffffc0200676:	00002517          	auipc	a0,0x2
ffffffffc020067a:	97250513          	addi	a0,a0,-1678 # ffffffffc0201fe8 <commands+0x378>
ffffffffc020067e:	a5bff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t5       0x%08x\n", gpr->t5);
ffffffffc0200682:	786c                	ld	a1,240(s0)
ffffffffc0200684:	00002517          	auipc	a0,0x2
ffffffffc0200688:	97c50513          	addi	a0,a0,-1668 # ffffffffc0202000 <commands+0x390>
ffffffffc020068c:	a4dff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200690:	7c6c                	ld	a1,248(s0)
}
ffffffffc0200692:	6402                	ld	s0,0(sp)
ffffffffc0200694:	60a2                	ld	ra,8(sp)
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc0200696:	00002517          	auipc	a0,0x2
ffffffffc020069a:	98250513          	addi	a0,a0,-1662 # ffffffffc0202018 <commands+0x3a8>
}
ffffffffc020069e:	0141                	addi	sp,sp,16
    cprintf("  t6       0x%08x\n", gpr->t6);
ffffffffc02006a0:	bc25                	j	ffffffffc02000d8 <cprintf>

ffffffffc02006a2 <print_trapframe>:
void print_trapframe(struct trapframe *tf) {
ffffffffc02006a2:	1141                	addi	sp,sp,-16
ffffffffc02006a4:	e022                	sd	s0,0(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02006a6:	85aa                	mv	a1,a0
void print_trapframe(struct trapframe *tf) {
ffffffffc02006a8:	842a                	mv	s0,a0
    cprintf("trapframe at %p\n", tf);
ffffffffc02006aa:	00002517          	auipc	a0,0x2
ffffffffc02006ae:	98650513          	addi	a0,a0,-1658 # ffffffffc0202030 <commands+0x3c0>
void print_trapframe(struct trapframe *tf) {
ffffffffc02006b2:	e406                	sd	ra,8(sp)
    cprintf("trapframe at %p\n", tf);
ffffffffc02006b4:	a25ff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    print_regs(&tf->gpr);
ffffffffc02006b8:	8522                	mv	a0,s0
ffffffffc02006ba:	e1dff0ef          	jal	ra,ffffffffc02004d6 <print_regs>
    cprintf("  status   0x%08x\n", tf->status);
ffffffffc02006be:	10043583          	ld	a1,256(s0)
ffffffffc02006c2:	00002517          	auipc	a0,0x2
ffffffffc02006c6:	98650513          	addi	a0,a0,-1658 # ffffffffc0202048 <commands+0x3d8>
ffffffffc02006ca:	a0fff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  epc      0x%08x\n", tf->epc);
ffffffffc02006ce:	10843583          	ld	a1,264(s0)
ffffffffc02006d2:	00002517          	auipc	a0,0x2
ffffffffc02006d6:	98e50513          	addi	a0,a0,-1650 # ffffffffc0202060 <commands+0x3f0>
ffffffffc02006da:	9ffff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  badvaddr 0x%08x\n", tf->badvaddr);
ffffffffc02006de:	11043583          	ld	a1,272(s0)
ffffffffc02006e2:	00002517          	auipc	a0,0x2
ffffffffc02006e6:	99650513          	addi	a0,a0,-1642 # ffffffffc0202078 <commands+0x408>
ffffffffc02006ea:	9efff0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006ee:	11843583          	ld	a1,280(s0)
}
ffffffffc02006f2:	6402                	ld	s0,0(sp)
ffffffffc02006f4:	60a2                	ld	ra,8(sp)
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc02006f6:	00002517          	auipc	a0,0x2
ffffffffc02006fa:	99a50513          	addi	a0,a0,-1638 # ffffffffc0202090 <commands+0x420>
}
ffffffffc02006fe:	0141                	addi	sp,sp,16
    cprintf("  cause    0x%08x\n", tf->cause);
ffffffffc0200700:	bae1                	j	ffffffffc02000d8 <cprintf>

ffffffffc0200702 <interrupt_handler>:

void interrupt_handler(struct trapframe *tf) {
    intptr_t cause = (tf->cause << 1) >> 1;
ffffffffc0200702:	11853783          	ld	a5,280(a0)
ffffffffc0200706:	472d                	li	a4,11
ffffffffc0200708:	0786                	slli	a5,a5,0x1
ffffffffc020070a:	8385                	srli	a5,a5,0x1
ffffffffc020070c:	06f76e63          	bltu	a4,a5,ffffffffc0200788 <interrupt_handler+0x86>
ffffffffc0200710:	00002717          	auipc	a4,0x2
ffffffffc0200714:	a6070713          	addi	a4,a4,-1440 # ffffffffc0202170 <commands+0x500>
ffffffffc0200718:	078a                	slli	a5,a5,0x2
ffffffffc020071a:	97ba                	add	a5,a5,a4
ffffffffc020071c:	439c                	lw	a5,0(a5)
ffffffffc020071e:	97ba                	add	a5,a5,a4
ffffffffc0200720:	8782                	jr	a5
            break;
        case IRQ_H_SOFT:
            cprintf("Hypervisor software interrupt\n");
            break;
        case IRQ_M_SOFT:
            cprintf("Machine software interrupt\n");
ffffffffc0200722:	00002517          	auipc	a0,0x2
ffffffffc0200726:	9e650513          	addi	a0,a0,-1562 # ffffffffc0202108 <commands+0x498>
ffffffffc020072a:	b27d                	j	ffffffffc02000d8 <cprintf>
            cprintf("Hypervisor software interrupt\n");
ffffffffc020072c:	00002517          	auipc	a0,0x2
ffffffffc0200730:	9bc50513          	addi	a0,a0,-1604 # ffffffffc02020e8 <commands+0x478>
ffffffffc0200734:	b255                	j	ffffffffc02000d8 <cprintf>
            cprintf("User software interrupt\n");
ffffffffc0200736:	00002517          	auipc	a0,0x2
ffffffffc020073a:	97250513          	addi	a0,a0,-1678 # ffffffffc02020a8 <commands+0x438>
ffffffffc020073e:	ba69                	j	ffffffffc02000d8 <cprintf>
            break;
        case IRQ_U_TIMER:
            cprintf("User Timer interrupt\n");
ffffffffc0200740:	00002517          	auipc	a0,0x2
ffffffffc0200744:	9e850513          	addi	a0,a0,-1560 # ffffffffc0202128 <commands+0x4b8>
ffffffffc0200748:	ba41                	j	ffffffffc02000d8 <cprintf>
void interrupt_handler(struct trapframe *tf) {
ffffffffc020074a:	1141                	addi	sp,sp,-16
ffffffffc020074c:	e406                	sd	ra,8(sp)
            // read-only." -- privileged spec1.9.1, 4.1.4, p59
            // In fact, Call sbi_set_timer will clear STIP, or you can clear it
            // directly.
            // cprintf("Supervisor timer interrupt\n");
            // clear_csr(sip, SIP_STIP);
            clock_set_next_event();
ffffffffc020074e:	d13ff0ef          	jal	ra,ffffffffc0200460 <clock_set_next_event>
            if (++ticks % TICK_NUM == 0) {
ffffffffc0200752:	00006697          	auipc	a3,0x6
ffffffffc0200756:	cee68693          	addi	a3,a3,-786 # ffffffffc0206440 <ticks>
ffffffffc020075a:	629c                	ld	a5,0(a3)
ffffffffc020075c:	06400713          	li	a4,100
ffffffffc0200760:	0785                	addi	a5,a5,1
ffffffffc0200762:	02e7f733          	remu	a4,a5,a4
ffffffffc0200766:	e29c                	sd	a5,0(a3)
ffffffffc0200768:	c30d                	beqz	a4,ffffffffc020078a <interrupt_handler+0x88>
            break;
        default:
            print_trapframe(tf);
            break;
    }
}
ffffffffc020076a:	60a2                	ld	ra,8(sp)
ffffffffc020076c:	0141                	addi	sp,sp,16
ffffffffc020076e:	8082                	ret
            cprintf("Supervisor external interrupt\n");
ffffffffc0200770:	00002517          	auipc	a0,0x2
ffffffffc0200774:	9e050513          	addi	a0,a0,-1568 # ffffffffc0202150 <commands+0x4e0>
ffffffffc0200778:	961ff06f          	j	ffffffffc02000d8 <cprintf>
            cprintf("Supervisor software interrupt\n");
ffffffffc020077c:	00002517          	auipc	a0,0x2
ffffffffc0200780:	94c50513          	addi	a0,a0,-1716 # ffffffffc02020c8 <commands+0x458>
ffffffffc0200784:	955ff06f          	j	ffffffffc02000d8 <cprintf>
            print_trapframe(tf);
ffffffffc0200788:	bf29                	j	ffffffffc02006a2 <print_trapframe>
}
ffffffffc020078a:	60a2                	ld	ra,8(sp)
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020078c:	06400593          	li	a1,100
ffffffffc0200790:	00002517          	auipc	a0,0x2
ffffffffc0200794:	9b050513          	addi	a0,a0,-1616 # ffffffffc0202140 <commands+0x4d0>
}
ffffffffc0200798:	0141                	addi	sp,sp,16
    cprintf("%d ticks\n", TICK_NUM);
ffffffffc020079a:	93fff06f          	j	ffffffffc02000d8 <cprintf>

ffffffffc020079e <trap>:
            break;
    }
}

static inline void trap_dispatch(struct trapframe *tf) {
    if ((intptr_t)tf->cause < 0) {
ffffffffc020079e:	11853783          	ld	a5,280(a0)
ffffffffc02007a2:	0007c763          	bltz	a5,ffffffffc02007b0 <trap+0x12>
    switch (tf->cause) {
ffffffffc02007a6:	472d                	li	a4,11
ffffffffc02007a8:	00f76363          	bltu	a4,a5,ffffffffc02007ae <trap+0x10>
 * trapframe and then uses the iret instruction to return from the exception.
 * */
void trap(struct trapframe *tf) {
    // dispatch based on what type of trap occurred
    trap_dispatch(tf);
}
ffffffffc02007ac:	8082                	ret
            print_trapframe(tf);
ffffffffc02007ae:	bdd5                	j	ffffffffc02006a2 <print_trapframe>
        interrupt_handler(tf);
ffffffffc02007b0:	bf89                	j	ffffffffc0200702 <interrupt_handler>
	...

ffffffffc02007b4 <__alltraps>:
    .endm

    .globl __alltraps
    .align(2)
__alltraps:
    SAVE_ALL
ffffffffc02007b4:	14011073          	csrw	sscratch,sp
ffffffffc02007b8:	712d                	addi	sp,sp,-288
ffffffffc02007ba:	e002                	sd	zero,0(sp)
ffffffffc02007bc:	e406                	sd	ra,8(sp)
ffffffffc02007be:	ec0e                	sd	gp,24(sp)
ffffffffc02007c0:	f012                	sd	tp,32(sp)
ffffffffc02007c2:	f416                	sd	t0,40(sp)
ffffffffc02007c4:	f81a                	sd	t1,48(sp)
ffffffffc02007c6:	fc1e                	sd	t2,56(sp)
ffffffffc02007c8:	e0a2                	sd	s0,64(sp)
ffffffffc02007ca:	e4a6                	sd	s1,72(sp)
ffffffffc02007cc:	e8aa                	sd	a0,80(sp)
ffffffffc02007ce:	ecae                	sd	a1,88(sp)
ffffffffc02007d0:	f0b2                	sd	a2,96(sp)
ffffffffc02007d2:	f4b6                	sd	a3,104(sp)
ffffffffc02007d4:	f8ba                	sd	a4,112(sp)
ffffffffc02007d6:	fcbe                	sd	a5,120(sp)
ffffffffc02007d8:	e142                	sd	a6,128(sp)
ffffffffc02007da:	e546                	sd	a7,136(sp)
ffffffffc02007dc:	e94a                	sd	s2,144(sp)
ffffffffc02007de:	ed4e                	sd	s3,152(sp)
ffffffffc02007e0:	f152                	sd	s4,160(sp)
ffffffffc02007e2:	f556                	sd	s5,168(sp)
ffffffffc02007e4:	f95a                	sd	s6,176(sp)
ffffffffc02007e6:	fd5e                	sd	s7,184(sp)
ffffffffc02007e8:	e1e2                	sd	s8,192(sp)
ffffffffc02007ea:	e5e6                	sd	s9,200(sp)
ffffffffc02007ec:	e9ea                	sd	s10,208(sp)
ffffffffc02007ee:	edee                	sd	s11,216(sp)
ffffffffc02007f0:	f1f2                	sd	t3,224(sp)
ffffffffc02007f2:	f5f6                	sd	t4,232(sp)
ffffffffc02007f4:	f9fa                	sd	t5,240(sp)
ffffffffc02007f6:	fdfe                	sd	t6,248(sp)
ffffffffc02007f8:	14001473          	csrrw	s0,sscratch,zero
ffffffffc02007fc:	100024f3          	csrr	s1,sstatus
ffffffffc0200800:	14102973          	csrr	s2,sepc
ffffffffc0200804:	143029f3          	csrr	s3,stval
ffffffffc0200808:	14202a73          	csrr	s4,scause
ffffffffc020080c:	e822                	sd	s0,16(sp)
ffffffffc020080e:	e226                	sd	s1,256(sp)
ffffffffc0200810:	e64a                	sd	s2,264(sp)
ffffffffc0200812:	ea4e                	sd	s3,272(sp)
ffffffffc0200814:	ee52                	sd	s4,280(sp)

    move  a0, sp
ffffffffc0200816:	850a                	mv	a0,sp
    jal trap
ffffffffc0200818:	f87ff0ef          	jal	ra,ffffffffc020079e <trap>

ffffffffc020081c <__trapret>:
    # sp should be the same as before "jal trap"

    .globl __trapret
__trapret:
    RESTORE_ALL
ffffffffc020081c:	6492                	ld	s1,256(sp)
ffffffffc020081e:	6932                	ld	s2,264(sp)
ffffffffc0200820:	10049073          	csrw	sstatus,s1
ffffffffc0200824:	14191073          	csrw	sepc,s2
ffffffffc0200828:	60a2                	ld	ra,8(sp)
ffffffffc020082a:	61e2                	ld	gp,24(sp)
ffffffffc020082c:	7202                	ld	tp,32(sp)
ffffffffc020082e:	72a2                	ld	t0,40(sp)
ffffffffc0200830:	7342                	ld	t1,48(sp)
ffffffffc0200832:	73e2                	ld	t2,56(sp)
ffffffffc0200834:	6406                	ld	s0,64(sp)
ffffffffc0200836:	64a6                	ld	s1,72(sp)
ffffffffc0200838:	6546                	ld	a0,80(sp)
ffffffffc020083a:	65e6                	ld	a1,88(sp)
ffffffffc020083c:	7606                	ld	a2,96(sp)
ffffffffc020083e:	76a6                	ld	a3,104(sp)
ffffffffc0200840:	7746                	ld	a4,112(sp)
ffffffffc0200842:	77e6                	ld	a5,120(sp)
ffffffffc0200844:	680a                	ld	a6,128(sp)
ffffffffc0200846:	68aa                	ld	a7,136(sp)
ffffffffc0200848:	694a                	ld	s2,144(sp)
ffffffffc020084a:	69ea                	ld	s3,152(sp)
ffffffffc020084c:	7a0a                	ld	s4,160(sp)
ffffffffc020084e:	7aaa                	ld	s5,168(sp)
ffffffffc0200850:	7b4a                	ld	s6,176(sp)
ffffffffc0200852:	7bea                	ld	s7,184(sp)
ffffffffc0200854:	6c0e                	ld	s8,192(sp)
ffffffffc0200856:	6cae                	ld	s9,200(sp)
ffffffffc0200858:	6d4e                	ld	s10,208(sp)
ffffffffc020085a:	6dee                	ld	s11,216(sp)
ffffffffc020085c:	7e0e                	ld	t3,224(sp)
ffffffffc020085e:	7eae                	ld	t4,232(sp)
ffffffffc0200860:	7f4e                	ld	t5,240(sp)
ffffffffc0200862:	7fee                	ld	t6,248(sp)
ffffffffc0200864:	6142                	ld	sp,16(sp)
    # return from supervisor call
    sret
ffffffffc0200866:	10200073          	sret

ffffffffc020086a <best_fit_init>:
 * list_init - initialize a new entry
 * @elm:        new entry to be initialized
 * */
static inline void
list_init(list_entry_t *elm) {
    elm->prev = elm->next = elm;
ffffffffc020086a:	00005797          	auipc	a5,0x5
ffffffffc020086e:	7b678793          	addi	a5,a5,1974 # ffffffffc0206020 <free_area>
ffffffffc0200872:	e79c                	sd	a5,8(a5)
ffffffffc0200874:	e39c                	sd	a5,0(a5)
#define nr_free (free_area.nr_free)

static void
best_fit_init(void) {
    list_init(&free_list);
    nr_free = 0;
ffffffffc0200876:	0007a823          	sw	zero,16(a5)
}
ffffffffc020087a:	8082                	ret

ffffffffc020087c <best_fit_nr_free_pages>:
}

static size_t
best_fit_nr_free_pages(void) {
    return nr_free;
}
ffffffffc020087c:	00005517          	auipc	a0,0x5
ffffffffc0200880:	7b456503          	lwu	a0,1972(a0) # ffffffffc0206030 <free_area+0x10>
ffffffffc0200884:	8082                	ret

ffffffffc0200886 <best_fit_alloc_pages>:
    assert(n > 0);
ffffffffc0200886:	c14d                	beqz	a0,ffffffffc0200928 <best_fit_alloc_pages+0xa2>
    if (n > nr_free) {
ffffffffc0200888:	00005617          	auipc	a2,0x5
ffffffffc020088c:	79860613          	addi	a2,a2,1944 # ffffffffc0206020 <free_area>
ffffffffc0200890:	01062803          	lw	a6,16(a2)
ffffffffc0200894:	86aa                	mv	a3,a0
ffffffffc0200896:	02081793          	slli	a5,a6,0x20
ffffffffc020089a:	9381                	srli	a5,a5,0x20
ffffffffc020089c:	08a7e463          	bltu	a5,a0,ffffffffc0200924 <best_fit_alloc_pages+0x9e>
 * list_next - get the next entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_next(list_entry_t *listelm) {
    return listelm->next;
ffffffffc02008a0:	661c                	ld	a5,8(a2)
    size_t min_size = nr_free + 1;
ffffffffc02008a2:	0018059b          	addiw	a1,a6,1
ffffffffc02008a6:	1582                	slli	a1,a1,0x20
ffffffffc02008a8:	9181                	srli	a1,a1,0x20
    struct Page *page = NULL;
ffffffffc02008aa:	4501                	li	a0,0
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008ac:	06c78b63          	beq	a5,a2,ffffffffc0200922 <best_fit_alloc_pages+0x9c>
        if (p->property >= n && p->property < min_size) {
ffffffffc02008b0:	ff87e703          	lwu	a4,-8(a5)
ffffffffc02008b4:	00d76763          	bltu	a4,a3,ffffffffc02008c2 <best_fit_alloc_pages+0x3c>
ffffffffc02008b8:	00b77563          	bgeu	a4,a1,ffffffffc02008c2 <best_fit_alloc_pages+0x3c>
        struct Page *p = le2page(le, page_link);
ffffffffc02008bc:	fe878513          	addi	a0,a5,-24
ffffffffc02008c0:	85ba                	mv	a1,a4
ffffffffc02008c2:	679c                	ld	a5,8(a5)
    while ((le = list_next(le)) != &free_list) {
ffffffffc02008c4:	fec796e3          	bne	a5,a2,ffffffffc02008b0 <best_fit_alloc_pages+0x2a>
    if (page != NULL) {
ffffffffc02008c8:	cd29                	beqz	a0,ffffffffc0200922 <best_fit_alloc_pages+0x9c>
    __list_del(listelm->prev, listelm->next);
ffffffffc02008ca:	711c                	ld	a5,32(a0)
 * list_prev - get the previous entry
 * @listelm:    the list head
 **/
static inline list_entry_t *
list_prev(list_entry_t *listelm) {
    return listelm->prev;
ffffffffc02008cc:	6d18                	ld	a4,24(a0)
        if (page->property > n) {
ffffffffc02008ce:	490c                	lw	a1,16(a0)
            p->property = page->property - n;
ffffffffc02008d0:	0006889b          	sext.w	a7,a3
 * This is only for internal list manipulation where we know
 * the prev/next entries already!
 * */
static inline void
__list_del(list_entry_t *prev, list_entry_t *next) {
    prev->next = next;
ffffffffc02008d4:	e71c                	sd	a5,8(a4)
    next->prev = prev;
ffffffffc02008d6:	e398                	sd	a4,0(a5)
        if (page->property > n) {
ffffffffc02008d8:	02059793          	slli	a5,a1,0x20
ffffffffc02008dc:	9381                	srli	a5,a5,0x20
ffffffffc02008de:	02f6f863          	bgeu	a3,a5,ffffffffc020090e <best_fit_alloc_pages+0x88>
            struct Page *p = page + n;
ffffffffc02008e2:	00269793          	slli	a5,a3,0x2
ffffffffc02008e6:	97b6                	add	a5,a5,a3
ffffffffc02008e8:	078e                	slli	a5,a5,0x3
ffffffffc02008ea:	97aa                	add	a5,a5,a0
            p->property = page->property - n;
ffffffffc02008ec:	411585bb          	subw	a1,a1,a7
ffffffffc02008f0:	cb8c                	sw	a1,16(a5)
 *
 * Note that @nr may be almost arbitrarily large; this function is not
 * restricted to acting on a single-word quantity.
 * */
static inline void set_bit(int nr, volatile void *addr) {
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02008f2:	4689                	li	a3,2
ffffffffc02008f4:	00878593          	addi	a1,a5,8
ffffffffc02008f8:	40d5b02f          	amoor.d	zero,a3,(a1)
    __list_add(elm, listelm, listelm->next);
ffffffffc02008fc:	6714                	ld	a3,8(a4)
            list_add(prev, &(p->page_link));
ffffffffc02008fe:	01878593          	addi	a1,a5,24
        nr_free -= n;
ffffffffc0200902:	01062803          	lw	a6,16(a2)
    prev->next = next->prev = elm;
ffffffffc0200906:	e28c                	sd	a1,0(a3)
ffffffffc0200908:	e70c                	sd	a1,8(a4)
    elm->next = next;
ffffffffc020090a:	f394                	sd	a3,32(a5)
    elm->prev = prev;
ffffffffc020090c:	ef98                	sd	a4,24(a5)
ffffffffc020090e:	4118083b          	subw	a6,a6,a7
ffffffffc0200912:	01062823          	sw	a6,16(a2)
 * clear_bit - Atomically clears a bit in memory
 * @nr:     the bit to clear
 * @addr:   the address to start counting from
 * */
static inline void clear_bit(int nr, volatile void *addr) {
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc0200916:	57f5                	li	a5,-3
ffffffffc0200918:	00850713          	addi	a4,a0,8
ffffffffc020091c:	60f7302f          	amoand.d	zero,a5,(a4)
}
ffffffffc0200920:	8082                	ret
}
ffffffffc0200922:	8082                	ret
        return NULL;
ffffffffc0200924:	4501                	li	a0,0
ffffffffc0200926:	8082                	ret
best_fit_alloc_pages(size_t n) {
ffffffffc0200928:	1141                	addi	sp,sp,-16
    assert(n > 0);
ffffffffc020092a:	00002697          	auipc	a3,0x2
ffffffffc020092e:	87668693          	addi	a3,a3,-1930 # ffffffffc02021a0 <commands+0x530>
ffffffffc0200932:	00002617          	auipc	a2,0x2
ffffffffc0200936:	87660613          	addi	a2,a2,-1930 # ffffffffc02021a8 <commands+0x538>
ffffffffc020093a:	06300593          	li	a1,99
ffffffffc020093e:	00002517          	auipc	a0,0x2
ffffffffc0200942:	88250513          	addi	a0,a0,-1918 # ffffffffc02021c0 <commands+0x550>
best_fit_alloc_pages(size_t n) {
ffffffffc0200946:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0200948:	a8bff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020094c <best_fit_check>:
}

// LAB2: below code is used to check the best fit allocation algorithm (your EXERCISE 1) 
// NOTICE: You SHOULD NOT CHANGE basic_check, default_check functions!
static void
best_fit_check(void) {
ffffffffc020094c:	715d                	addi	sp,sp,-80
ffffffffc020094e:	e0a2                	sd	s0,64(sp)
    return listelm->next;
ffffffffc0200950:	00005417          	auipc	s0,0x5
ffffffffc0200954:	6d040413          	addi	s0,s0,1744 # ffffffffc0206020 <free_area>
ffffffffc0200958:	641c                	ld	a5,8(s0)
ffffffffc020095a:	e486                	sd	ra,72(sp)
ffffffffc020095c:	fc26                	sd	s1,56(sp)
ffffffffc020095e:	f84a                	sd	s2,48(sp)
ffffffffc0200960:	f44e                	sd	s3,40(sp)
ffffffffc0200962:	f052                	sd	s4,32(sp)
ffffffffc0200964:	ec56                	sd	s5,24(sp)
ffffffffc0200966:	e85a                	sd	s6,16(sp)
ffffffffc0200968:	e45e                	sd	s7,8(sp)
ffffffffc020096a:	e062                	sd	s8,0(sp)
    int score = 0 ,sumscore = 6;
    int count = 0, total = 0;
    list_entry_t *le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc020096c:	26878b63          	beq	a5,s0,ffffffffc0200be2 <best_fit_check+0x296>
    int count = 0, total = 0;
ffffffffc0200970:	4481                	li	s1,0
ffffffffc0200972:	4901                	li	s2,0
 * test_bit - Determine whether a bit is set
 * @nr:     the bit to test
 * @addr:   the address to count from
 * */
static inline bool test_bit(int nr, volatile void *addr) {
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0200974:	ff07b703          	ld	a4,-16(a5)
        struct Page *p = le2page(le, page_link);
        assert(PageProperty(p));
ffffffffc0200978:	8b09                	andi	a4,a4,2
ffffffffc020097a:	26070863          	beqz	a4,ffffffffc0200bea <best_fit_check+0x29e>
        count ++, total += p->property;
ffffffffc020097e:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200982:	679c                	ld	a5,8(a5)
ffffffffc0200984:	2905                	addiw	s2,s2,1
ffffffffc0200986:	9cb9                	addw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200988:	fe8796e3          	bne	a5,s0,ffffffffc0200974 <best_fit_check+0x28>
    }
    assert(total == nr_free_pages());
ffffffffc020098c:	89a6                	mv	s3,s1
ffffffffc020098e:	167000ef          	jal	ra,ffffffffc02012f4 <nr_free_pages>
ffffffffc0200992:	33351c63          	bne	a0,s3,ffffffffc0200cca <best_fit_check+0x37e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200996:	4505                	li	a0,1
ffffffffc0200998:	0df000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc020099c:	8a2a                	mv	s4,a0
ffffffffc020099e:	36050663          	beqz	a0,ffffffffc0200d0a <best_fit_check+0x3be>
    assert((p1 = alloc_page()) != NULL);
ffffffffc02009a2:	4505                	li	a0,1
ffffffffc02009a4:	0d3000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc02009a8:	89aa                	mv	s3,a0
ffffffffc02009aa:	34050063          	beqz	a0,ffffffffc0200cea <best_fit_check+0x39e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc02009ae:	4505                	li	a0,1
ffffffffc02009b0:	0c7000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc02009b4:	8aaa                	mv	s5,a0
ffffffffc02009b6:	2c050a63          	beqz	a0,ffffffffc0200c8a <best_fit_check+0x33e>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc02009ba:	253a0863          	beq	s4,s3,ffffffffc0200c0a <best_fit_check+0x2be>
ffffffffc02009be:	24aa0663          	beq	s4,a0,ffffffffc0200c0a <best_fit_check+0x2be>
ffffffffc02009c2:	24a98463          	beq	s3,a0,ffffffffc0200c0a <best_fit_check+0x2be>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc02009c6:	000a2783          	lw	a5,0(s4)
ffffffffc02009ca:	26079063          	bnez	a5,ffffffffc0200c2a <best_fit_check+0x2de>
ffffffffc02009ce:	0009a783          	lw	a5,0(s3)
ffffffffc02009d2:	24079c63          	bnez	a5,ffffffffc0200c2a <best_fit_check+0x2de>
ffffffffc02009d6:	411c                	lw	a5,0(a0)
ffffffffc02009d8:	24079963          	bnez	a5,ffffffffc0200c2a <best_fit_check+0x2de>
extern struct Page *pages;
extern size_t npage;
extern const size_t nbase;
extern uint64_t va_pa_offset;

static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc02009dc:	00006797          	auipc	a5,0x6
ffffffffc02009e0:	a747b783          	ld	a5,-1420(a5) # ffffffffc0206450 <pages>
ffffffffc02009e4:	40fa0733          	sub	a4,s4,a5
ffffffffc02009e8:	870d                	srai	a4,a4,0x3
ffffffffc02009ea:	00002597          	auipc	a1,0x2
ffffffffc02009ee:	ea65b583          	ld	a1,-346(a1) # ffffffffc0202890 <error_string+0x38>
ffffffffc02009f2:	02b70733          	mul	a4,a4,a1
ffffffffc02009f6:	00002617          	auipc	a2,0x2
ffffffffc02009fa:	ea263603          	ld	a2,-350(a2) # ffffffffc0202898 <nbase>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc02009fe:	00006697          	auipc	a3,0x6
ffffffffc0200a02:	a4a6b683          	ld	a3,-1462(a3) # ffffffffc0206448 <npage>
ffffffffc0200a06:	06b2                	slli	a3,a3,0xc
ffffffffc0200a08:	9732                	add	a4,a4,a2

static inline uintptr_t page2pa(struct Page *page) {
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a0a:	0732                	slli	a4,a4,0xc
ffffffffc0200a0c:	22d77f63          	bgeu	a4,a3,ffffffffc0200c4a <best_fit_check+0x2fe>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a10:	40f98733          	sub	a4,s3,a5
ffffffffc0200a14:	870d                	srai	a4,a4,0x3
ffffffffc0200a16:	02b70733          	mul	a4,a4,a1
ffffffffc0200a1a:	9732                	add	a4,a4,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a1c:	0732                	slli	a4,a4,0xc
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200a1e:	3ed77663          	bgeu	a4,a3,ffffffffc0200e0a <best_fit_check+0x4be>
static inline ppn_t page2ppn(struct Page *page) { return page - pages + nbase; }
ffffffffc0200a22:	40f507b3          	sub	a5,a0,a5
ffffffffc0200a26:	878d                	srai	a5,a5,0x3
ffffffffc0200a28:	02b787b3          	mul	a5,a5,a1
ffffffffc0200a2c:	97b2                	add	a5,a5,a2
    return page2ppn(page) << PGSHIFT;
ffffffffc0200a2e:	07b2                	slli	a5,a5,0xc
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200a30:	3ad7fd63          	bgeu	a5,a3,ffffffffc0200dea <best_fit_check+0x49e>
    assert(alloc_page() == NULL);
ffffffffc0200a34:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200a36:	00043c03          	ld	s8,0(s0)
ffffffffc0200a3a:	00843b83          	ld	s7,8(s0)
    unsigned int nr_free_store = nr_free;
ffffffffc0200a3e:	01042b03          	lw	s6,16(s0)
    elm->prev = elm->next = elm;
ffffffffc0200a42:	e400                	sd	s0,8(s0)
ffffffffc0200a44:	e000                	sd	s0,0(s0)
    nr_free = 0;
ffffffffc0200a46:	00005797          	auipc	a5,0x5
ffffffffc0200a4a:	5e07a523          	sw	zero,1514(a5) # ffffffffc0206030 <free_area+0x10>
    assert(alloc_page() == NULL);
ffffffffc0200a4e:	029000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200a52:	36051c63          	bnez	a0,ffffffffc0200dca <best_fit_check+0x47e>
    free_page(p0);
ffffffffc0200a56:	4585                	li	a1,1
ffffffffc0200a58:	8552                	mv	a0,s4
ffffffffc0200a5a:	05b000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    free_page(p1);
ffffffffc0200a5e:	4585                	li	a1,1
ffffffffc0200a60:	854e                	mv	a0,s3
ffffffffc0200a62:	053000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    free_page(p2);
ffffffffc0200a66:	4585                	li	a1,1
ffffffffc0200a68:	8556                	mv	a0,s5
ffffffffc0200a6a:	04b000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    assert(nr_free == 3);
ffffffffc0200a6e:	4818                	lw	a4,16(s0)
ffffffffc0200a70:	478d                	li	a5,3
ffffffffc0200a72:	32f71c63          	bne	a4,a5,ffffffffc0200daa <best_fit_check+0x45e>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200a76:	4505                	li	a0,1
ffffffffc0200a78:	7fe000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200a7c:	89aa                	mv	s3,a0
ffffffffc0200a7e:	30050663          	beqz	a0,ffffffffc0200d8a <best_fit_check+0x43e>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200a82:	4505                	li	a0,1
ffffffffc0200a84:	7f2000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200a88:	8aaa                	mv	s5,a0
ffffffffc0200a8a:	2e050063          	beqz	a0,ffffffffc0200d6a <best_fit_check+0x41e>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200a8e:	4505                	li	a0,1
ffffffffc0200a90:	7e6000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200a94:	8a2a                	mv	s4,a0
ffffffffc0200a96:	2a050a63          	beqz	a0,ffffffffc0200d4a <best_fit_check+0x3fe>
    assert(alloc_page() == NULL);
ffffffffc0200a9a:	4505                	li	a0,1
ffffffffc0200a9c:	7da000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200aa0:	28051563          	bnez	a0,ffffffffc0200d2a <best_fit_check+0x3de>
    free_page(p0);
ffffffffc0200aa4:	4585                	li	a1,1
ffffffffc0200aa6:	854e                	mv	a0,s3
ffffffffc0200aa8:	00d000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    assert(!list_empty(&free_list));
ffffffffc0200aac:	641c                	ld	a5,8(s0)
ffffffffc0200aae:	1a878e63          	beq	a5,s0,ffffffffc0200c6a <best_fit_check+0x31e>
    assert((p = alloc_page()) == p0);
ffffffffc0200ab2:	4505                	li	a0,1
ffffffffc0200ab4:	7c2000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200ab8:	52a99963          	bne	s3,a0,ffffffffc0200fea <best_fit_check+0x69e>
    assert(alloc_page() == NULL);
ffffffffc0200abc:	4505                	li	a0,1
ffffffffc0200abe:	7b8000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200ac2:	50051463          	bnez	a0,ffffffffc0200fca <best_fit_check+0x67e>
    assert(nr_free == 0);
ffffffffc0200ac6:	481c                	lw	a5,16(s0)
ffffffffc0200ac8:	4e079163          	bnez	a5,ffffffffc0200faa <best_fit_check+0x65e>
    free_page(p);
ffffffffc0200acc:	854e                	mv	a0,s3
ffffffffc0200ace:	4585                	li	a1,1
    free_list = free_list_store;
ffffffffc0200ad0:	01843023          	sd	s8,0(s0)
ffffffffc0200ad4:	01743423          	sd	s7,8(s0)
    nr_free = nr_free_store;
ffffffffc0200ad8:	01642823          	sw	s6,16(s0)
    free_page(p);
ffffffffc0200adc:	7d8000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    free_page(p1);
ffffffffc0200ae0:	4585                	li	a1,1
ffffffffc0200ae2:	8556                	mv	a0,s5
ffffffffc0200ae4:	7d0000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    free_page(p2);
ffffffffc0200ae8:	4585                	li	a1,1
ffffffffc0200aea:	8552                	mv	a0,s4
ffffffffc0200aec:	7c8000ef          	jal	ra,ffffffffc02012b4 <free_pages>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    struct Page *p0 = alloc_pages(5), *p1, *p2;
ffffffffc0200af0:	4515                	li	a0,5
ffffffffc0200af2:	784000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200af6:	89aa                	mv	s3,a0
    assert(p0 != NULL);
ffffffffc0200af8:	48050963          	beqz	a0,ffffffffc0200f8a <best_fit_check+0x63e>
ffffffffc0200afc:	651c                	ld	a5,8(a0)
ffffffffc0200afe:	8385                	srli	a5,a5,0x1
    assert(!PageProperty(p0));
ffffffffc0200b00:	8b85                	andi	a5,a5,1
ffffffffc0200b02:	46079463          	bnez	a5,ffffffffc0200f6a <best_fit_check+0x61e>
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    list_entry_t free_list_store = free_list;
    list_init(&free_list);
    assert(list_empty(&free_list));
    assert(alloc_page() == NULL);
ffffffffc0200b06:	4505                	li	a0,1
    list_entry_t free_list_store = free_list;
ffffffffc0200b08:	00043a83          	ld	s5,0(s0)
ffffffffc0200b0c:	00843a03          	ld	s4,8(s0)
ffffffffc0200b10:	e000                	sd	s0,0(s0)
ffffffffc0200b12:	e400                	sd	s0,8(s0)
    assert(alloc_page() == NULL);
ffffffffc0200b14:	762000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b18:	42051963          	bnez	a0,ffffffffc0200f4a <best_fit_check+0x5fe>
    #endif
    unsigned int nr_free_store = nr_free;
    nr_free = 0;

    // * - - * -
    free_pages(p0 + 1, 2);
ffffffffc0200b1c:	4589                	li	a1,2
ffffffffc0200b1e:	02898513          	addi	a0,s3,40
    unsigned int nr_free_store = nr_free;
ffffffffc0200b22:	01042b03          	lw	s6,16(s0)
    free_pages(p0 + 4, 1);
ffffffffc0200b26:	0a098c13          	addi	s8,s3,160
    nr_free = 0;
ffffffffc0200b2a:	00005797          	auipc	a5,0x5
ffffffffc0200b2e:	5007a323          	sw	zero,1286(a5) # ffffffffc0206030 <free_area+0x10>
    free_pages(p0 + 1, 2);
ffffffffc0200b32:	782000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    free_pages(p0 + 4, 1);
ffffffffc0200b36:	8562                	mv	a0,s8
ffffffffc0200b38:	4585                	li	a1,1
ffffffffc0200b3a:	77a000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    assert(alloc_pages(4) == NULL);
ffffffffc0200b3e:	4511                	li	a0,4
ffffffffc0200b40:	736000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b44:	3e051363          	bnez	a0,ffffffffc0200f2a <best_fit_check+0x5de>
ffffffffc0200b48:	0309b783          	ld	a5,48(s3)
ffffffffc0200b4c:	8385                	srli	a5,a5,0x1
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200b4e:	8b85                	andi	a5,a5,1
ffffffffc0200b50:	3a078d63          	beqz	a5,ffffffffc0200f0a <best_fit_check+0x5be>
ffffffffc0200b54:	0389a703          	lw	a4,56(s3)
ffffffffc0200b58:	4789                	li	a5,2
ffffffffc0200b5a:	3af71863          	bne	a4,a5,ffffffffc0200f0a <best_fit_check+0x5be>
    // * - - * *
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200b5e:	4505                	li	a0,1
ffffffffc0200b60:	716000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b64:	8baa                	mv	s7,a0
ffffffffc0200b66:	38050263          	beqz	a0,ffffffffc0200eea <best_fit_check+0x59e>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200b6a:	4509                	li	a0,2
ffffffffc0200b6c:	70a000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b70:	34050d63          	beqz	a0,ffffffffc0200eca <best_fit_check+0x57e>
    assert(p0 + 4 == p1);
ffffffffc0200b74:	337c1b63          	bne	s8,s7,ffffffffc0200eaa <best_fit_check+0x55e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    p2 = p0 + 1;
    free_pages(p0, 5);
ffffffffc0200b78:	854e                	mv	a0,s3
ffffffffc0200b7a:	4595                	li	a1,5
ffffffffc0200b7c:	738000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200b80:	4515                	li	a0,5
ffffffffc0200b82:	6f4000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b86:	89aa                	mv	s3,a0
ffffffffc0200b88:	30050163          	beqz	a0,ffffffffc0200e8a <best_fit_check+0x53e>
    assert(alloc_page() == NULL);
ffffffffc0200b8c:	4505                	li	a0,1
ffffffffc0200b8e:	6e8000ef          	jal	ra,ffffffffc0201276 <alloc_pages>
ffffffffc0200b92:	2c051c63          	bnez	a0,ffffffffc0200e6a <best_fit_check+0x51e>

    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
    assert(nr_free == 0);
ffffffffc0200b96:	481c                	lw	a5,16(s0)
ffffffffc0200b98:	2a079963          	bnez	a5,ffffffffc0200e4a <best_fit_check+0x4fe>
    nr_free = nr_free_store;

    free_list = free_list_store;
    free_pages(p0, 5);
ffffffffc0200b9c:	4595                	li	a1,5
ffffffffc0200b9e:	854e                	mv	a0,s3
    nr_free = nr_free_store;
ffffffffc0200ba0:	01642823          	sw	s6,16(s0)
    free_list = free_list_store;
ffffffffc0200ba4:	01543023          	sd	s5,0(s0)
ffffffffc0200ba8:	01443423          	sd	s4,8(s0)
    free_pages(p0, 5);
ffffffffc0200bac:	708000ef          	jal	ra,ffffffffc02012b4 <free_pages>
    return listelm->next;
ffffffffc0200bb0:	641c                	ld	a5,8(s0)

    le = &free_list;
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bb2:	00878963          	beq	a5,s0,ffffffffc0200bc4 <best_fit_check+0x278>
        struct Page *p = le2page(le, page_link);
        count --, total -= p->property;
ffffffffc0200bb6:	ff87a703          	lw	a4,-8(a5)
ffffffffc0200bba:	679c                	ld	a5,8(a5)
ffffffffc0200bbc:	397d                	addiw	s2,s2,-1
ffffffffc0200bbe:	9c99                	subw	s1,s1,a4
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200bc0:	fe879be3          	bne	a5,s0,ffffffffc0200bb6 <best_fit_check+0x26a>
    }
    assert(count == 0);
ffffffffc0200bc4:	26091363          	bnez	s2,ffffffffc0200e2a <best_fit_check+0x4de>
    assert(total == 0);
ffffffffc0200bc8:	e0ed                	bnez	s1,ffffffffc0200caa <best_fit_check+0x35e>
    #ifdef ucore_test
    score += 1;
    cprintf("grading: %d / %d points\n",score, sumscore);
    #endif
}
ffffffffc0200bca:	60a6                	ld	ra,72(sp)
ffffffffc0200bcc:	6406                	ld	s0,64(sp)
ffffffffc0200bce:	74e2                	ld	s1,56(sp)
ffffffffc0200bd0:	7942                	ld	s2,48(sp)
ffffffffc0200bd2:	79a2                	ld	s3,40(sp)
ffffffffc0200bd4:	7a02                	ld	s4,32(sp)
ffffffffc0200bd6:	6ae2                	ld	s5,24(sp)
ffffffffc0200bd8:	6b42                	ld	s6,16(sp)
ffffffffc0200bda:	6ba2                	ld	s7,8(sp)
ffffffffc0200bdc:	6c02                	ld	s8,0(sp)
ffffffffc0200bde:	6161                	addi	sp,sp,80
ffffffffc0200be0:	8082                	ret
    while ((le = list_next(le)) != &free_list) {
ffffffffc0200be2:	4981                	li	s3,0
    int count = 0, total = 0;
ffffffffc0200be4:	4481                	li	s1,0
ffffffffc0200be6:	4901                	li	s2,0
ffffffffc0200be8:	b35d                	j	ffffffffc020098e <best_fit_check+0x42>
        assert(PageProperty(p));
ffffffffc0200bea:	00001697          	auipc	a3,0x1
ffffffffc0200bee:	5ee68693          	addi	a3,a3,1518 # ffffffffc02021d8 <commands+0x568>
ffffffffc0200bf2:	00001617          	auipc	a2,0x1
ffffffffc0200bf6:	5b660613          	addi	a2,a2,1462 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200bfa:	0f500593          	li	a1,245
ffffffffc0200bfe:	00001517          	auipc	a0,0x1
ffffffffc0200c02:	5c250513          	addi	a0,a0,1474 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200c06:	fccff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != p1 && p0 != p2 && p1 != p2);
ffffffffc0200c0a:	00001697          	auipc	a3,0x1
ffffffffc0200c0e:	65e68693          	addi	a3,a3,1630 # ffffffffc0202268 <commands+0x5f8>
ffffffffc0200c12:	00001617          	auipc	a2,0x1
ffffffffc0200c16:	59660613          	addi	a2,a2,1430 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200c1a:	0c100593          	li	a1,193
ffffffffc0200c1e:	00001517          	auipc	a0,0x1
ffffffffc0200c22:	5a250513          	addi	a0,a0,1442 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200c26:	facff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page_ref(p0) == 0 && page_ref(p1) == 0 && page_ref(p2) == 0);
ffffffffc0200c2a:	00001697          	auipc	a3,0x1
ffffffffc0200c2e:	66668693          	addi	a3,a3,1638 # ffffffffc0202290 <commands+0x620>
ffffffffc0200c32:	00001617          	auipc	a2,0x1
ffffffffc0200c36:	57660613          	addi	a2,a2,1398 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200c3a:	0c200593          	li	a1,194
ffffffffc0200c3e:	00001517          	auipc	a0,0x1
ffffffffc0200c42:	58250513          	addi	a0,a0,1410 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200c46:	f8cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p0) < npage * PGSIZE);
ffffffffc0200c4a:	00001697          	auipc	a3,0x1
ffffffffc0200c4e:	68668693          	addi	a3,a3,1670 # ffffffffc02022d0 <commands+0x660>
ffffffffc0200c52:	00001617          	auipc	a2,0x1
ffffffffc0200c56:	55660613          	addi	a2,a2,1366 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200c5a:	0c400593          	li	a1,196
ffffffffc0200c5e:	00001517          	auipc	a0,0x1
ffffffffc0200c62:	56250513          	addi	a0,a0,1378 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200c66:	f6cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!list_empty(&free_list));
ffffffffc0200c6a:	00001697          	auipc	a3,0x1
ffffffffc0200c6e:	6ee68693          	addi	a3,a3,1774 # ffffffffc0202358 <commands+0x6e8>
ffffffffc0200c72:	00001617          	auipc	a2,0x1
ffffffffc0200c76:	53660613          	addi	a2,a2,1334 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200c7a:	0dd00593          	li	a1,221
ffffffffc0200c7e:	00001517          	auipc	a0,0x1
ffffffffc0200c82:	54250513          	addi	a0,a0,1346 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200c86:	f4cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200c8a:	00001697          	auipc	a3,0x1
ffffffffc0200c8e:	5be68693          	addi	a3,a3,1470 # ffffffffc0202248 <commands+0x5d8>
ffffffffc0200c92:	00001617          	auipc	a2,0x1
ffffffffc0200c96:	51660613          	addi	a2,a2,1302 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200c9a:	0bf00593          	li	a1,191
ffffffffc0200c9e:	00001517          	auipc	a0,0x1
ffffffffc0200ca2:	52250513          	addi	a0,a0,1314 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200ca6:	f2cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == 0);
ffffffffc0200caa:	00001697          	auipc	a3,0x1
ffffffffc0200cae:	7de68693          	addi	a3,a3,2014 # ffffffffc0202488 <commands+0x818>
ffffffffc0200cb2:	00001617          	auipc	a2,0x1
ffffffffc0200cb6:	4f660613          	addi	a2,a2,1270 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200cba:	13700593          	li	a1,311
ffffffffc0200cbe:	00001517          	auipc	a0,0x1
ffffffffc0200cc2:	50250513          	addi	a0,a0,1282 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200cc6:	f0cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(total == nr_free_pages());
ffffffffc0200cca:	00001697          	auipc	a3,0x1
ffffffffc0200cce:	51e68693          	addi	a3,a3,1310 # ffffffffc02021e8 <commands+0x578>
ffffffffc0200cd2:	00001617          	auipc	a2,0x1
ffffffffc0200cd6:	4d660613          	addi	a2,a2,1238 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200cda:	0f800593          	li	a1,248
ffffffffc0200cde:	00001517          	auipc	a0,0x1
ffffffffc0200ce2:	4e250513          	addi	a0,a0,1250 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200ce6:	eecff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200cea:	00001697          	auipc	a3,0x1
ffffffffc0200cee:	53e68693          	addi	a3,a3,1342 # ffffffffc0202228 <commands+0x5b8>
ffffffffc0200cf2:	00001617          	auipc	a2,0x1
ffffffffc0200cf6:	4b660613          	addi	a2,a2,1206 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200cfa:	0be00593          	li	a1,190
ffffffffc0200cfe:	00001517          	auipc	a0,0x1
ffffffffc0200d02:	4c250513          	addi	a0,a0,1218 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200d06:	eccff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d0a:	00001697          	auipc	a3,0x1
ffffffffc0200d0e:	4fe68693          	addi	a3,a3,1278 # ffffffffc0202208 <commands+0x598>
ffffffffc0200d12:	00001617          	auipc	a2,0x1
ffffffffc0200d16:	49660613          	addi	a2,a2,1174 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200d1a:	0bd00593          	li	a1,189
ffffffffc0200d1e:	00001517          	auipc	a0,0x1
ffffffffc0200d22:	4a250513          	addi	a0,a0,1186 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200d26:	eacff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200d2a:	00001697          	auipc	a3,0x1
ffffffffc0200d2e:	60668693          	addi	a3,a3,1542 # ffffffffc0202330 <commands+0x6c0>
ffffffffc0200d32:	00001617          	auipc	a2,0x1
ffffffffc0200d36:	47660613          	addi	a2,a2,1142 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200d3a:	0da00593          	li	a1,218
ffffffffc0200d3e:	00001517          	auipc	a0,0x1
ffffffffc0200d42:	48250513          	addi	a0,a0,1154 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200d46:	e8cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p2 = alloc_page()) != NULL);
ffffffffc0200d4a:	00001697          	auipc	a3,0x1
ffffffffc0200d4e:	4fe68693          	addi	a3,a3,1278 # ffffffffc0202248 <commands+0x5d8>
ffffffffc0200d52:	00001617          	auipc	a2,0x1
ffffffffc0200d56:	45660613          	addi	a2,a2,1110 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200d5a:	0d800593          	li	a1,216
ffffffffc0200d5e:	00001517          	auipc	a0,0x1
ffffffffc0200d62:	46250513          	addi	a0,a0,1122 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200d66:	e6cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_page()) != NULL);
ffffffffc0200d6a:	00001697          	auipc	a3,0x1
ffffffffc0200d6e:	4be68693          	addi	a3,a3,1214 # ffffffffc0202228 <commands+0x5b8>
ffffffffc0200d72:	00001617          	auipc	a2,0x1
ffffffffc0200d76:	43660613          	addi	a2,a2,1078 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200d7a:	0d700593          	li	a1,215
ffffffffc0200d7e:	00001517          	auipc	a0,0x1
ffffffffc0200d82:	44250513          	addi	a0,a0,1090 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200d86:	e4cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_page()) != NULL);
ffffffffc0200d8a:	00001697          	auipc	a3,0x1
ffffffffc0200d8e:	47e68693          	addi	a3,a3,1150 # ffffffffc0202208 <commands+0x598>
ffffffffc0200d92:	00001617          	auipc	a2,0x1
ffffffffc0200d96:	41660613          	addi	a2,a2,1046 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200d9a:	0d600593          	li	a1,214
ffffffffc0200d9e:	00001517          	auipc	a0,0x1
ffffffffc0200da2:	42250513          	addi	a0,a0,1058 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200da6:	e2cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 3);
ffffffffc0200daa:	00001697          	auipc	a3,0x1
ffffffffc0200dae:	59e68693          	addi	a3,a3,1438 # ffffffffc0202348 <commands+0x6d8>
ffffffffc0200db2:	00001617          	auipc	a2,0x1
ffffffffc0200db6:	3f660613          	addi	a2,a2,1014 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200dba:	0d400593          	li	a1,212
ffffffffc0200dbe:	00001517          	auipc	a0,0x1
ffffffffc0200dc2:	40250513          	addi	a0,a0,1026 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200dc6:	e0cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200dca:	00001697          	auipc	a3,0x1
ffffffffc0200dce:	56668693          	addi	a3,a3,1382 # ffffffffc0202330 <commands+0x6c0>
ffffffffc0200dd2:	00001617          	auipc	a2,0x1
ffffffffc0200dd6:	3d660613          	addi	a2,a2,982 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200dda:	0cf00593          	li	a1,207
ffffffffc0200dde:	00001517          	auipc	a0,0x1
ffffffffc0200de2:	3e250513          	addi	a0,a0,994 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200de6:	decff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p2) < npage * PGSIZE);
ffffffffc0200dea:	00001697          	auipc	a3,0x1
ffffffffc0200dee:	52668693          	addi	a3,a3,1318 # ffffffffc0202310 <commands+0x6a0>
ffffffffc0200df2:	00001617          	auipc	a2,0x1
ffffffffc0200df6:	3b660613          	addi	a2,a2,950 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200dfa:	0c600593          	li	a1,198
ffffffffc0200dfe:	00001517          	auipc	a0,0x1
ffffffffc0200e02:	3c250513          	addi	a0,a0,962 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200e06:	dccff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(page2pa(p1) < npage * PGSIZE);
ffffffffc0200e0a:	00001697          	auipc	a3,0x1
ffffffffc0200e0e:	4e668693          	addi	a3,a3,1254 # ffffffffc02022f0 <commands+0x680>
ffffffffc0200e12:	00001617          	auipc	a2,0x1
ffffffffc0200e16:	39660613          	addi	a2,a2,918 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200e1a:	0c500593          	li	a1,197
ffffffffc0200e1e:	00001517          	auipc	a0,0x1
ffffffffc0200e22:	3a250513          	addi	a0,a0,930 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200e26:	dacff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(count == 0);
ffffffffc0200e2a:	00001697          	auipc	a3,0x1
ffffffffc0200e2e:	64e68693          	addi	a3,a3,1614 # ffffffffc0202478 <commands+0x808>
ffffffffc0200e32:	00001617          	auipc	a2,0x1
ffffffffc0200e36:	37660613          	addi	a2,a2,886 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200e3a:	13600593          	li	a1,310
ffffffffc0200e3e:	00001517          	auipc	a0,0x1
ffffffffc0200e42:	38250513          	addi	a0,a0,898 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200e46:	d8cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0200e4a:	00001697          	auipc	a3,0x1
ffffffffc0200e4e:	54668693          	addi	a3,a3,1350 # ffffffffc0202390 <commands+0x720>
ffffffffc0200e52:	00001617          	auipc	a2,0x1
ffffffffc0200e56:	35660613          	addi	a2,a2,854 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200e5a:	12b00593          	li	a1,299
ffffffffc0200e5e:	00001517          	auipc	a0,0x1
ffffffffc0200e62:	36250513          	addi	a0,a0,866 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200e66:	d6cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200e6a:	00001697          	auipc	a3,0x1
ffffffffc0200e6e:	4c668693          	addi	a3,a3,1222 # ffffffffc0202330 <commands+0x6c0>
ffffffffc0200e72:	00001617          	auipc	a2,0x1
ffffffffc0200e76:	33660613          	addi	a2,a2,822 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200e7a:	12500593          	li	a1,293
ffffffffc0200e7e:	00001517          	auipc	a0,0x1
ffffffffc0200e82:	34250513          	addi	a0,a0,834 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200e86:	d4cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p0 = alloc_pages(5)) != NULL);
ffffffffc0200e8a:	00001697          	auipc	a3,0x1
ffffffffc0200e8e:	5ce68693          	addi	a3,a3,1486 # ffffffffc0202458 <commands+0x7e8>
ffffffffc0200e92:	00001617          	auipc	a2,0x1
ffffffffc0200e96:	31660613          	addi	a2,a2,790 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200e9a:	12400593          	li	a1,292
ffffffffc0200e9e:	00001517          	auipc	a0,0x1
ffffffffc0200ea2:	32250513          	addi	a0,a0,802 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200ea6:	d2cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 + 4 == p1);
ffffffffc0200eaa:	00001697          	auipc	a3,0x1
ffffffffc0200eae:	59e68693          	addi	a3,a3,1438 # ffffffffc0202448 <commands+0x7d8>
ffffffffc0200eb2:	00001617          	auipc	a2,0x1
ffffffffc0200eb6:	2f660613          	addi	a2,a2,758 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200eba:	11c00593          	li	a1,284
ffffffffc0200ebe:	00001517          	auipc	a0,0x1
ffffffffc0200ec2:	30250513          	addi	a0,a0,770 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200ec6:	d0cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(2) != NULL);      // best fit feature
ffffffffc0200eca:	00001697          	auipc	a3,0x1
ffffffffc0200ece:	56668693          	addi	a3,a3,1382 # ffffffffc0202430 <commands+0x7c0>
ffffffffc0200ed2:	00001617          	auipc	a2,0x1
ffffffffc0200ed6:	2d660613          	addi	a2,a2,726 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200eda:	11b00593          	li	a1,283
ffffffffc0200ede:	00001517          	auipc	a0,0x1
ffffffffc0200ee2:	2e250513          	addi	a0,a0,738 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200ee6:	cecff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p1 = alloc_pages(1)) != NULL);
ffffffffc0200eea:	00001697          	auipc	a3,0x1
ffffffffc0200eee:	52668693          	addi	a3,a3,1318 # ffffffffc0202410 <commands+0x7a0>
ffffffffc0200ef2:	00001617          	auipc	a2,0x1
ffffffffc0200ef6:	2b660613          	addi	a2,a2,694 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200efa:	11a00593          	li	a1,282
ffffffffc0200efe:	00001517          	auipc	a0,0x1
ffffffffc0200f02:	2c250513          	addi	a0,a0,706 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200f06:	cccff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(PageProperty(p0 + 1) && p0[1].property == 2);
ffffffffc0200f0a:	00001697          	auipc	a3,0x1
ffffffffc0200f0e:	4d668693          	addi	a3,a3,1238 # ffffffffc02023e0 <commands+0x770>
ffffffffc0200f12:	00001617          	auipc	a2,0x1
ffffffffc0200f16:	29660613          	addi	a2,a2,662 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200f1a:	11800593          	li	a1,280
ffffffffc0200f1e:	00001517          	auipc	a0,0x1
ffffffffc0200f22:	2a250513          	addi	a0,a0,674 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200f26:	cacff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_pages(4) == NULL);
ffffffffc0200f2a:	00001697          	auipc	a3,0x1
ffffffffc0200f2e:	49e68693          	addi	a3,a3,1182 # ffffffffc02023c8 <commands+0x758>
ffffffffc0200f32:	00001617          	auipc	a2,0x1
ffffffffc0200f36:	27660613          	addi	a2,a2,630 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200f3a:	11700593          	li	a1,279
ffffffffc0200f3e:	00001517          	auipc	a0,0x1
ffffffffc0200f42:	28250513          	addi	a0,a0,642 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200f46:	c8cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200f4a:	00001697          	auipc	a3,0x1
ffffffffc0200f4e:	3e668693          	addi	a3,a3,998 # ffffffffc0202330 <commands+0x6c0>
ffffffffc0200f52:	00001617          	auipc	a2,0x1
ffffffffc0200f56:	25660613          	addi	a2,a2,598 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200f5a:	10b00593          	li	a1,267
ffffffffc0200f5e:	00001517          	auipc	a0,0x1
ffffffffc0200f62:	26250513          	addi	a0,a0,610 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200f66:	c6cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(!PageProperty(p0));
ffffffffc0200f6a:	00001697          	auipc	a3,0x1
ffffffffc0200f6e:	44668693          	addi	a3,a3,1094 # ffffffffc02023b0 <commands+0x740>
ffffffffc0200f72:	00001617          	auipc	a2,0x1
ffffffffc0200f76:	23660613          	addi	a2,a2,566 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200f7a:	10200593          	li	a1,258
ffffffffc0200f7e:	00001517          	auipc	a0,0x1
ffffffffc0200f82:	24250513          	addi	a0,a0,578 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200f86:	c4cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(p0 != NULL);
ffffffffc0200f8a:	00001697          	auipc	a3,0x1
ffffffffc0200f8e:	41668693          	addi	a3,a3,1046 # ffffffffc02023a0 <commands+0x730>
ffffffffc0200f92:	00001617          	auipc	a2,0x1
ffffffffc0200f96:	21660613          	addi	a2,a2,534 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200f9a:	10100593          	li	a1,257
ffffffffc0200f9e:	00001517          	auipc	a0,0x1
ffffffffc0200fa2:	22250513          	addi	a0,a0,546 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200fa6:	c2cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(nr_free == 0);
ffffffffc0200faa:	00001697          	auipc	a3,0x1
ffffffffc0200fae:	3e668693          	addi	a3,a3,998 # ffffffffc0202390 <commands+0x720>
ffffffffc0200fb2:	00001617          	auipc	a2,0x1
ffffffffc0200fb6:	1f660613          	addi	a2,a2,502 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200fba:	0e300593          	li	a1,227
ffffffffc0200fbe:	00001517          	auipc	a0,0x1
ffffffffc0200fc2:	20250513          	addi	a0,a0,514 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200fc6:	c0cff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(alloc_page() == NULL);
ffffffffc0200fca:	00001697          	auipc	a3,0x1
ffffffffc0200fce:	36668693          	addi	a3,a3,870 # ffffffffc0202330 <commands+0x6c0>
ffffffffc0200fd2:	00001617          	auipc	a2,0x1
ffffffffc0200fd6:	1d660613          	addi	a2,a2,470 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200fda:	0e100593          	li	a1,225
ffffffffc0200fde:	00001517          	auipc	a0,0x1
ffffffffc0200fe2:	1e250513          	addi	a0,a0,482 # ffffffffc02021c0 <commands+0x550>
ffffffffc0200fe6:	becff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert((p = alloc_page()) == p0);
ffffffffc0200fea:	00001697          	auipc	a3,0x1
ffffffffc0200fee:	38668693          	addi	a3,a3,902 # ffffffffc0202370 <commands+0x700>
ffffffffc0200ff2:	00001617          	auipc	a2,0x1
ffffffffc0200ff6:	1b660613          	addi	a2,a2,438 # ffffffffc02021a8 <commands+0x538>
ffffffffc0200ffa:	0e000593          	li	a1,224
ffffffffc0200ffe:	00001517          	auipc	a0,0x1
ffffffffc0201002:	1c250513          	addi	a0,a0,450 # ffffffffc02021c0 <commands+0x550>
ffffffffc0201006:	bccff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc020100a <best_fit_free_pages>:
best_fit_free_pages(struct Page *base, size_t n) {
ffffffffc020100a:	1141                	addi	sp,sp,-16
ffffffffc020100c:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc020100e:	14058a63          	beqz	a1,ffffffffc0201162 <best_fit_free_pages+0x158>
    for (; p != base + n; p ++) {
ffffffffc0201012:	00259693          	slli	a3,a1,0x2
ffffffffc0201016:	96ae                	add	a3,a3,a1
ffffffffc0201018:	068e                	slli	a3,a3,0x3
ffffffffc020101a:	96aa                	add	a3,a3,a0
ffffffffc020101c:	87aa                	mv	a5,a0
ffffffffc020101e:	02d50263          	beq	a0,a3,ffffffffc0201042 <best_fit_free_pages+0x38>
ffffffffc0201022:	6798                	ld	a4,8(a5)
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201024:	8b05                	andi	a4,a4,1
ffffffffc0201026:	10071e63          	bnez	a4,ffffffffc0201142 <best_fit_free_pages+0x138>
ffffffffc020102a:	6798                	ld	a4,8(a5)
ffffffffc020102c:	8b09                	andi	a4,a4,2
ffffffffc020102e:	10071a63          	bnez	a4,ffffffffc0201142 <best_fit_free_pages+0x138>
        p->flags = 0;
ffffffffc0201032:	0007b423          	sd	zero,8(a5)



static inline int page_ref(struct Page *page) { return page->ref; }

static inline void set_page_ref(struct Page *page, int val) { page->ref = val; }
ffffffffc0201036:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc020103a:	02878793          	addi	a5,a5,40
ffffffffc020103e:	fed792e3          	bne	a5,a3,ffffffffc0201022 <best_fit_free_pages+0x18>
    base->property = n;
ffffffffc0201042:	2581                	sext.w	a1,a1
ffffffffc0201044:	c90c                	sw	a1,16(a0)
    SetPageProperty(base);
ffffffffc0201046:	00850893          	addi	a7,a0,8
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc020104a:	4789                	li	a5,2
ffffffffc020104c:	40f8b02f          	amoor.d	zero,a5,(a7)
    nr_free += n;
ffffffffc0201050:	00005697          	auipc	a3,0x5
ffffffffc0201054:	fd068693          	addi	a3,a3,-48 # ffffffffc0206020 <free_area>
ffffffffc0201058:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc020105a:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc020105c:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc0201060:	9db9                	addw	a1,a1,a4
ffffffffc0201062:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc0201064:	0ad78863          	beq	a5,a3,ffffffffc0201114 <best_fit_free_pages+0x10a>
            struct Page* page = le2page(le, page_link);
ffffffffc0201068:	fe878713          	addi	a4,a5,-24
ffffffffc020106c:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc0201070:	4581                	li	a1,0
            if (base < page) {
ffffffffc0201072:	00e56a63          	bltu	a0,a4,ffffffffc0201086 <best_fit_free_pages+0x7c>
    return listelm->next;
ffffffffc0201076:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc0201078:	06d70263          	beq	a4,a3,ffffffffc02010dc <best_fit_free_pages+0xd2>
    for (; p != base + n; p ++) {
ffffffffc020107c:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc020107e:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc0201082:	fee57ae3          	bgeu	a0,a4,ffffffffc0201076 <best_fit_free_pages+0x6c>
ffffffffc0201086:	c199                	beqz	a1,ffffffffc020108c <best_fit_free_pages+0x82>
ffffffffc0201088:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc020108c:	6398                	ld	a4,0(a5)
    prev->next = next->prev = elm;
ffffffffc020108e:	e390                	sd	a2,0(a5)
ffffffffc0201090:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201092:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201094:	ed18                	sd	a4,24(a0)
    if (le != &free_list) {
ffffffffc0201096:	02d70063          	beq	a4,a3,ffffffffc02010b6 <best_fit_free_pages+0xac>
        if (p + p->property == base) {
ffffffffc020109a:	ff872803          	lw	a6,-8(a4)
        p = le2page(le, page_link);
ffffffffc020109e:	fe870593          	addi	a1,a4,-24
        if (p + p->property == base) {
ffffffffc02010a2:	02081613          	slli	a2,a6,0x20
ffffffffc02010a6:	9201                	srli	a2,a2,0x20
ffffffffc02010a8:	00261793          	slli	a5,a2,0x2
ffffffffc02010ac:	97b2                	add	a5,a5,a2
ffffffffc02010ae:	078e                	slli	a5,a5,0x3
ffffffffc02010b0:	97ae                	add	a5,a5,a1
ffffffffc02010b2:	02f50f63          	beq	a0,a5,ffffffffc02010f0 <best_fit_free_pages+0xe6>
    return listelm->next;
ffffffffc02010b6:	7118                	ld	a4,32(a0)
    if (le != &free_list) {
ffffffffc02010b8:	00d70f63          	beq	a4,a3,ffffffffc02010d6 <best_fit_free_pages+0xcc>
        if (base + base->property == p) {
ffffffffc02010bc:	490c                	lw	a1,16(a0)
        p = le2page(le, page_link);
ffffffffc02010be:	fe870693          	addi	a3,a4,-24
        if (base + base->property == p) {
ffffffffc02010c2:	02059613          	slli	a2,a1,0x20
ffffffffc02010c6:	9201                	srli	a2,a2,0x20
ffffffffc02010c8:	00261793          	slli	a5,a2,0x2
ffffffffc02010cc:	97b2                	add	a5,a5,a2
ffffffffc02010ce:	078e                	slli	a5,a5,0x3
ffffffffc02010d0:	97aa                	add	a5,a5,a0
ffffffffc02010d2:	04f68863          	beq	a3,a5,ffffffffc0201122 <best_fit_free_pages+0x118>
}
ffffffffc02010d6:	60a2                	ld	ra,8(sp)
ffffffffc02010d8:	0141                	addi	sp,sp,16
ffffffffc02010da:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc02010dc:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc02010de:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc02010e0:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc02010e2:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc02010e4:	02d70563          	beq	a4,a3,ffffffffc020110e <best_fit_free_pages+0x104>
    prev->next = next->prev = elm;
ffffffffc02010e8:	8832                	mv	a6,a2
ffffffffc02010ea:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc02010ec:	87ba                	mv	a5,a4
ffffffffc02010ee:	bf41                	j	ffffffffc020107e <best_fit_free_pages+0x74>
            p->property += base->property;
ffffffffc02010f0:	491c                	lw	a5,16(a0)
ffffffffc02010f2:	0107883b          	addw	a6,a5,a6
ffffffffc02010f6:	ff072c23          	sw	a6,-8(a4)
    __op_bit(and, __NOT, nr, ((volatile unsigned long *)addr));
ffffffffc02010fa:	57f5                	li	a5,-3
ffffffffc02010fc:	60f8b02f          	amoand.d	zero,a5,(a7)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201100:	6d10                	ld	a2,24(a0)
ffffffffc0201102:	711c                	ld	a5,32(a0)
            base = p;
ffffffffc0201104:	852e                	mv	a0,a1
    prev->next = next;
ffffffffc0201106:	e61c                	sd	a5,8(a2)
    return listelm->next;
ffffffffc0201108:	6718                	ld	a4,8(a4)
    next->prev = prev;
ffffffffc020110a:	e390                	sd	a2,0(a5)
ffffffffc020110c:	b775                	j	ffffffffc02010b8 <best_fit_free_pages+0xae>
ffffffffc020110e:	e290                	sd	a2,0(a3)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201110:	873e                	mv	a4,a5
ffffffffc0201112:	b761                	j	ffffffffc020109a <best_fit_free_pages+0x90>
}
ffffffffc0201114:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201116:	e390                	sd	a2,0(a5)
ffffffffc0201118:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020111a:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc020111c:	ed1c                	sd	a5,24(a0)
ffffffffc020111e:	0141                	addi	sp,sp,16
ffffffffc0201120:	8082                	ret
            base->property += p->property;
ffffffffc0201122:	ff872783          	lw	a5,-8(a4)
ffffffffc0201126:	ff070693          	addi	a3,a4,-16
ffffffffc020112a:	9dbd                	addw	a1,a1,a5
ffffffffc020112c:	c90c                	sw	a1,16(a0)
ffffffffc020112e:	57f5                	li	a5,-3
ffffffffc0201130:	60f6b02f          	amoand.d	zero,a5,(a3)
    __list_del(listelm->prev, listelm->next);
ffffffffc0201134:	6314                	ld	a3,0(a4)
ffffffffc0201136:	671c                	ld	a5,8(a4)
}
ffffffffc0201138:	60a2                	ld	ra,8(sp)
    prev->next = next;
ffffffffc020113a:	e69c                	sd	a5,8(a3)
    next->prev = prev;
ffffffffc020113c:	e394                	sd	a3,0(a5)
ffffffffc020113e:	0141                	addi	sp,sp,16
ffffffffc0201140:	8082                	ret
        assert(!PageReserved(p) && !PageProperty(p));
ffffffffc0201142:	00001697          	auipc	a3,0x1
ffffffffc0201146:	35668693          	addi	a3,a3,854 # ffffffffc0202498 <commands+0x828>
ffffffffc020114a:	00001617          	auipc	a2,0x1
ffffffffc020114e:	05e60613          	addi	a2,a2,94 # ffffffffc02021a8 <commands+0x538>
ffffffffc0201152:	08700593          	li	a1,135
ffffffffc0201156:	00001517          	auipc	a0,0x1
ffffffffc020115a:	06a50513          	addi	a0,a0,106 # ffffffffc02021c0 <commands+0x550>
ffffffffc020115e:	a74ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc0201162:	00001697          	auipc	a3,0x1
ffffffffc0201166:	03e68693          	addi	a3,a3,62 # ffffffffc02021a0 <commands+0x530>
ffffffffc020116a:	00001617          	auipc	a2,0x1
ffffffffc020116e:	03e60613          	addi	a2,a2,62 # ffffffffc02021a8 <commands+0x538>
ffffffffc0201172:	08400593          	li	a1,132
ffffffffc0201176:	00001517          	auipc	a0,0x1
ffffffffc020117a:	04a50513          	addi	a0,a0,74 # ffffffffc02021c0 <commands+0x550>
ffffffffc020117e:	a54ff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201182 <best_fit_init_memmap>:
best_fit_init_memmap(struct Page *base, size_t n) {
ffffffffc0201182:	1141                	addi	sp,sp,-16
ffffffffc0201184:	e406                	sd	ra,8(sp)
    assert(n > 0);
ffffffffc0201186:	c9e1                	beqz	a1,ffffffffc0201256 <best_fit_init_memmap+0xd4>
    for (; p != base + n; p ++) {
ffffffffc0201188:	00259693          	slli	a3,a1,0x2
ffffffffc020118c:	96ae                	add	a3,a3,a1
ffffffffc020118e:	068e                	slli	a3,a3,0x3
ffffffffc0201190:	96aa                	add	a3,a3,a0
ffffffffc0201192:	87aa                	mv	a5,a0
ffffffffc0201194:	00d50f63          	beq	a0,a3,ffffffffc02011b2 <best_fit_init_memmap+0x30>
    return (((*(volatile unsigned long *)addr) >> nr) & 1);
ffffffffc0201198:	6798                	ld	a4,8(a5)
        assert(PageReserved(p));
ffffffffc020119a:	8b05                	andi	a4,a4,1
ffffffffc020119c:	cf49                	beqz	a4,ffffffffc0201236 <best_fit_init_memmap+0xb4>
        p->flags = p->property = 0;
ffffffffc020119e:	0007a823          	sw	zero,16(a5)
ffffffffc02011a2:	0007b423          	sd	zero,8(a5)
ffffffffc02011a6:	0007a023          	sw	zero,0(a5)
    for (; p != base + n; p ++) {
ffffffffc02011aa:	02878793          	addi	a5,a5,40
ffffffffc02011ae:	fed795e3          	bne	a5,a3,ffffffffc0201198 <best_fit_init_memmap+0x16>
    base->property = n;
ffffffffc02011b2:	2581                	sext.w	a1,a1
ffffffffc02011b4:	c90c                	sw	a1,16(a0)
    __op_bit(or, __NOP, nr, ((volatile unsigned long *)addr));
ffffffffc02011b6:	4789                	li	a5,2
ffffffffc02011b8:	00850713          	addi	a4,a0,8
ffffffffc02011bc:	40f7302f          	amoor.d	zero,a5,(a4)
    nr_free += n;
ffffffffc02011c0:	00005697          	auipc	a3,0x5
ffffffffc02011c4:	e6068693          	addi	a3,a3,-416 # ffffffffc0206020 <free_area>
ffffffffc02011c8:	4a98                	lw	a4,16(a3)
    return list->next == list;
ffffffffc02011ca:	669c                	ld	a5,8(a3)
        list_add(&free_list, &(base->page_link));
ffffffffc02011cc:	01850613          	addi	a2,a0,24
    nr_free += n;
ffffffffc02011d0:	9db9                	addw	a1,a1,a4
ffffffffc02011d2:	ca8c                	sw	a1,16(a3)
    if (list_empty(&free_list)) {
ffffffffc02011d4:	04d78a63          	beq	a5,a3,ffffffffc0201228 <best_fit_init_memmap+0xa6>
            struct Page* page = le2page(le, page_link);
ffffffffc02011d8:	fe878713          	addi	a4,a5,-24
ffffffffc02011dc:	0006b803          	ld	a6,0(a3)
    if (list_empty(&free_list)) {
ffffffffc02011e0:	4581                	li	a1,0
            if (base < page) {
ffffffffc02011e2:	00e56a63          	bltu	a0,a4,ffffffffc02011f6 <best_fit_init_memmap+0x74>
    return listelm->next;
ffffffffc02011e6:	6798                	ld	a4,8(a5)
            } else if (list_next(le) == &free_list) {
ffffffffc02011e8:	02d70263          	beq	a4,a3,ffffffffc020120c <best_fit_init_memmap+0x8a>
    for (; p != base + n; p ++) {
ffffffffc02011ec:	87ba                	mv	a5,a4
            struct Page* page = le2page(le, page_link);
ffffffffc02011ee:	fe878713          	addi	a4,a5,-24
            if (base < page) {
ffffffffc02011f2:	fee57ae3          	bgeu	a0,a4,ffffffffc02011e6 <best_fit_init_memmap+0x64>
ffffffffc02011f6:	c199                	beqz	a1,ffffffffc02011fc <best_fit_init_memmap+0x7a>
ffffffffc02011f8:	0106b023          	sd	a6,0(a3)
    __list_add(elm, listelm->prev, listelm);
ffffffffc02011fc:	6398                	ld	a4,0(a5)
}
ffffffffc02011fe:	60a2                	ld	ra,8(sp)
    prev->next = next->prev = elm;
ffffffffc0201200:	e390                	sd	a2,0(a5)
ffffffffc0201202:	e710                	sd	a2,8(a4)
    elm->next = next;
ffffffffc0201204:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201206:	ed18                	sd	a4,24(a0)
ffffffffc0201208:	0141                	addi	sp,sp,16
ffffffffc020120a:	8082                	ret
    prev->next = next->prev = elm;
ffffffffc020120c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020120e:	f114                	sd	a3,32(a0)
    return listelm->next;
ffffffffc0201210:	6798                	ld	a4,8(a5)
    elm->prev = prev;
ffffffffc0201212:	ed1c                	sd	a5,24(a0)
        while ((le = list_next(le)) != &free_list) {
ffffffffc0201214:	00d70663          	beq	a4,a3,ffffffffc0201220 <best_fit_init_memmap+0x9e>
    prev->next = next->prev = elm;
ffffffffc0201218:	8832                	mv	a6,a2
ffffffffc020121a:	4585                	li	a1,1
    for (; p != base + n; p ++) {
ffffffffc020121c:	87ba                	mv	a5,a4
ffffffffc020121e:	bfc1                	j	ffffffffc02011ee <best_fit_init_memmap+0x6c>
}
ffffffffc0201220:	60a2                	ld	ra,8(sp)
ffffffffc0201222:	e290                	sd	a2,0(a3)
ffffffffc0201224:	0141                	addi	sp,sp,16
ffffffffc0201226:	8082                	ret
ffffffffc0201228:	60a2                	ld	ra,8(sp)
ffffffffc020122a:	e390                	sd	a2,0(a5)
ffffffffc020122c:	e790                	sd	a2,8(a5)
    elm->next = next;
ffffffffc020122e:	f11c                	sd	a5,32(a0)
    elm->prev = prev;
ffffffffc0201230:	ed1c                	sd	a5,24(a0)
ffffffffc0201232:	0141                	addi	sp,sp,16
ffffffffc0201234:	8082                	ret
        assert(PageReserved(p));
ffffffffc0201236:	00001697          	auipc	a3,0x1
ffffffffc020123a:	28a68693          	addi	a3,a3,650 # ffffffffc02024c0 <commands+0x850>
ffffffffc020123e:	00001617          	auipc	a2,0x1
ffffffffc0201242:	f6a60613          	addi	a2,a2,-150 # ffffffffc02021a8 <commands+0x538>
ffffffffc0201246:	04a00593          	li	a1,74
ffffffffc020124a:	00001517          	auipc	a0,0x1
ffffffffc020124e:	f7650513          	addi	a0,a0,-138 # ffffffffc02021c0 <commands+0x550>
ffffffffc0201252:	980ff0ef          	jal	ra,ffffffffc02003d2 <__panic>
    assert(n > 0);
ffffffffc0201256:	00001697          	auipc	a3,0x1
ffffffffc020125a:	f4a68693          	addi	a3,a3,-182 # ffffffffc02021a0 <commands+0x530>
ffffffffc020125e:	00001617          	auipc	a2,0x1
ffffffffc0201262:	f4a60613          	addi	a2,a2,-182 # ffffffffc02021a8 <commands+0x538>
ffffffffc0201266:	04700593          	li	a1,71
ffffffffc020126a:	00001517          	auipc	a0,0x1
ffffffffc020126e:	f5650513          	addi	a0,a0,-170 # ffffffffc02021c0 <commands+0x550>
ffffffffc0201272:	960ff0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc0201276 <alloc_pages>:
#include <defs.h>
#include <intr.h>
#include <riscv.h>

static inline bool __intr_save(void) {
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc0201276:	100027f3          	csrr	a5,sstatus
ffffffffc020127a:	8b89                	andi	a5,a5,2
ffffffffc020127c:	e799                	bnez	a5,ffffffffc020128a <alloc_pages+0x14>
struct Page *alloc_pages(size_t n) {
    struct Page *page = NULL;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        page = pmm_manager->alloc_pages(n);
ffffffffc020127e:	00005797          	auipc	a5,0x5
ffffffffc0201282:	1da7b783          	ld	a5,474(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc0201286:	6f9c                	ld	a5,24(a5)
ffffffffc0201288:	8782                	jr	a5
struct Page *alloc_pages(size_t n) {
ffffffffc020128a:	1141                	addi	sp,sp,-16
ffffffffc020128c:	e406                	sd	ra,8(sp)
ffffffffc020128e:	e022                	sd	s0,0(sp)
ffffffffc0201290:	842a                	mv	s0,a0
        intr_disable();
ffffffffc0201292:	a2cff0ef          	jal	ra,ffffffffc02004be <intr_disable>
        page = pmm_manager->alloc_pages(n);
ffffffffc0201296:	00005797          	auipc	a5,0x5
ffffffffc020129a:	1c27b783          	ld	a5,450(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc020129e:	6f9c                	ld	a5,24(a5)
ffffffffc02012a0:	8522                	mv	a0,s0
ffffffffc02012a2:	9782                	jalr	a5
ffffffffc02012a4:	842a                	mv	s0,a0
    return 0;
}

static inline void __intr_restore(bool flag) {
    if (flag) {
        intr_enable();
ffffffffc02012a6:	a12ff0ef          	jal	ra,ffffffffc02004b8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return page;
}
ffffffffc02012aa:	60a2                	ld	ra,8(sp)
ffffffffc02012ac:	8522                	mv	a0,s0
ffffffffc02012ae:	6402                	ld	s0,0(sp)
ffffffffc02012b0:	0141                	addi	sp,sp,16
ffffffffc02012b2:	8082                	ret

ffffffffc02012b4 <free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012b4:	100027f3          	csrr	a5,sstatus
ffffffffc02012b8:	8b89                	andi	a5,a5,2
ffffffffc02012ba:	e799                	bnez	a5,ffffffffc02012c8 <free_pages+0x14>
// free_pages - call pmm->free_pages to free a continuous n*PAGESIZE memory
void free_pages(struct Page *base, size_t n) {
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        pmm_manager->free_pages(base, n);
ffffffffc02012bc:	00005797          	auipc	a5,0x5
ffffffffc02012c0:	19c7b783          	ld	a5,412(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc02012c4:	739c                	ld	a5,32(a5)
ffffffffc02012c6:	8782                	jr	a5
void free_pages(struct Page *base, size_t n) {
ffffffffc02012c8:	1101                	addi	sp,sp,-32
ffffffffc02012ca:	ec06                	sd	ra,24(sp)
ffffffffc02012cc:	e822                	sd	s0,16(sp)
ffffffffc02012ce:	e426                	sd	s1,8(sp)
ffffffffc02012d0:	842a                	mv	s0,a0
ffffffffc02012d2:	84ae                	mv	s1,a1
        intr_disable();
ffffffffc02012d4:	9eaff0ef          	jal	ra,ffffffffc02004be <intr_disable>
        pmm_manager->free_pages(base, n);
ffffffffc02012d8:	00005797          	auipc	a5,0x5
ffffffffc02012dc:	1807b783          	ld	a5,384(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc02012e0:	739c                	ld	a5,32(a5)
ffffffffc02012e2:	85a6                	mv	a1,s1
ffffffffc02012e4:	8522                	mv	a0,s0
ffffffffc02012e6:	9782                	jalr	a5
    }
    local_intr_restore(intr_flag);
}
ffffffffc02012e8:	6442                	ld	s0,16(sp)
ffffffffc02012ea:	60e2                	ld	ra,24(sp)
ffffffffc02012ec:	64a2                	ld	s1,8(sp)
ffffffffc02012ee:	6105                	addi	sp,sp,32
        intr_enable();
ffffffffc02012f0:	9c8ff06f          	j	ffffffffc02004b8 <intr_enable>

ffffffffc02012f4 <nr_free_pages>:
    if (read_csr(sstatus) & SSTATUS_SIE) {
ffffffffc02012f4:	100027f3          	csrr	a5,sstatus
ffffffffc02012f8:	8b89                	andi	a5,a5,2
ffffffffc02012fa:	e799                	bnez	a5,ffffffffc0201308 <nr_free_pages+0x14>
size_t nr_free_pages(void) {
    size_t ret;
    bool intr_flag;
    local_intr_save(intr_flag);
    {
        ret = pmm_manager->nr_free_pages();
ffffffffc02012fc:	00005797          	auipc	a5,0x5
ffffffffc0201300:	15c7b783          	ld	a5,348(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc0201304:	779c                	ld	a5,40(a5)
ffffffffc0201306:	8782                	jr	a5
size_t nr_free_pages(void) {
ffffffffc0201308:	1141                	addi	sp,sp,-16
ffffffffc020130a:	e406                	sd	ra,8(sp)
ffffffffc020130c:	e022                	sd	s0,0(sp)
        intr_disable();
ffffffffc020130e:	9b0ff0ef          	jal	ra,ffffffffc02004be <intr_disable>
        ret = pmm_manager->nr_free_pages();
ffffffffc0201312:	00005797          	auipc	a5,0x5
ffffffffc0201316:	1467b783          	ld	a5,326(a5) # ffffffffc0206458 <pmm_manager>
ffffffffc020131a:	779c                	ld	a5,40(a5)
ffffffffc020131c:	9782                	jalr	a5
ffffffffc020131e:	842a                	mv	s0,a0
        intr_enable();
ffffffffc0201320:	998ff0ef          	jal	ra,ffffffffc02004b8 <intr_enable>
    }
    local_intr_restore(intr_flag);
    return ret;
}
ffffffffc0201324:	60a2                	ld	ra,8(sp)
ffffffffc0201326:	8522                	mv	a0,s0
ffffffffc0201328:	6402                	ld	s0,0(sp)
ffffffffc020132a:	0141                	addi	sp,sp,16
ffffffffc020132c:	8082                	ret

ffffffffc020132e <pmm_init>:
    pmm_manager = &best_fit_pmm_manager;
ffffffffc020132e:	00001797          	auipc	a5,0x1
ffffffffc0201332:	1ba78793          	addi	a5,a5,442 # ffffffffc02024e8 <best_fit_pmm_manager>
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201336:	638c                	ld	a1,0(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
    }
}

/* pmm_init - initialize the physical memory management */
void pmm_init(void) {
ffffffffc0201338:	1101                	addi	sp,sp,-32
ffffffffc020133a:	e426                	sd	s1,8(sp)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc020133c:	00001517          	auipc	a0,0x1
ffffffffc0201340:	1e450513          	addi	a0,a0,484 # ffffffffc0202520 <best_fit_pmm_manager+0x38>
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201344:	00005497          	auipc	s1,0x5
ffffffffc0201348:	11448493          	addi	s1,s1,276 # ffffffffc0206458 <pmm_manager>
void pmm_init(void) {
ffffffffc020134c:	ec06                	sd	ra,24(sp)
ffffffffc020134e:	e822                	sd	s0,16(sp)
    pmm_manager = &best_fit_pmm_manager;
ffffffffc0201350:	e09c                	sd	a5,0(s1)
    cprintf("memory management: %s\n", pmm_manager->name);
ffffffffc0201352:	d87fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pmm_manager->init();
ffffffffc0201356:	609c                	ld	a5,0(s1)
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201358:	00005417          	auipc	s0,0x5
ffffffffc020135c:	11840413          	addi	s0,s0,280 # ffffffffc0206470 <va_pa_offset>
    pmm_manager->init();
ffffffffc0201360:	679c                	ld	a5,8(a5)
ffffffffc0201362:	9782                	jalr	a5
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201364:	57f5                	li	a5,-3
ffffffffc0201366:	07fa                	slli	a5,a5,0x1e
    cprintf("physcial memory map:\n");
ffffffffc0201368:	00001517          	auipc	a0,0x1
ffffffffc020136c:	1d050513          	addi	a0,a0,464 # ffffffffc0202538 <best_fit_pmm_manager+0x50>
    va_pa_offset = PHYSICAL_MEMORY_OFFSET;
ffffffffc0201370:	e01c                	sd	a5,0(s0)
    cprintf("physcial memory map:\n");
ffffffffc0201372:	d67fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    cprintf("  memory: 0x%016lx, [0x%016lx, 0x%016lx].\n", mem_size, mem_begin,
ffffffffc0201376:	46c5                	li	a3,17
ffffffffc0201378:	06ee                	slli	a3,a3,0x1b
ffffffffc020137a:	40100613          	li	a2,1025
ffffffffc020137e:	16fd                	addi	a3,a3,-1
ffffffffc0201380:	07e005b7          	lui	a1,0x7e00
ffffffffc0201384:	0656                	slli	a2,a2,0x15
ffffffffc0201386:	00001517          	auipc	a0,0x1
ffffffffc020138a:	1ca50513          	addi	a0,a0,458 # ffffffffc0202550 <best_fit_pmm_manager+0x68>
ffffffffc020138e:	d4bfe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc0201392:	777d                	lui	a4,0xfffff
ffffffffc0201394:	00006797          	auipc	a5,0x6
ffffffffc0201398:	0eb78793          	addi	a5,a5,235 # ffffffffc020747f <end+0xfff>
ffffffffc020139c:	8ff9                	and	a5,a5,a4
    npage = maxpa / PGSIZE;
ffffffffc020139e:	00005517          	auipc	a0,0x5
ffffffffc02013a2:	0aa50513          	addi	a0,a0,170 # ffffffffc0206448 <npage>
ffffffffc02013a6:	00088737          	lui	a4,0x88
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013aa:	00005597          	auipc	a1,0x5
ffffffffc02013ae:	0a658593          	addi	a1,a1,166 # ffffffffc0206450 <pages>
    npage = maxpa / PGSIZE;
ffffffffc02013b2:	e118                	sd	a4,0(a0)
    pages = (struct Page *)ROUNDUP((void *)end, PGSIZE);
ffffffffc02013b4:	e19c                	sd	a5,0(a1)
ffffffffc02013b6:	4681                	li	a3,0
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02013b8:	4701                	li	a4,0
ffffffffc02013ba:	4885                	li	a7,1
ffffffffc02013bc:	fff80837          	lui	a6,0xfff80
ffffffffc02013c0:	a011                	j	ffffffffc02013c4 <pmm_init+0x96>
        SetPageReserved(pages + i);
ffffffffc02013c2:	619c                	ld	a5,0(a1)
ffffffffc02013c4:	97b6                	add	a5,a5,a3
ffffffffc02013c6:	07a1                	addi	a5,a5,8
ffffffffc02013c8:	4117b02f          	amoor.d	zero,a7,(a5)
    for (size_t i = 0; i < npage - nbase; i++) {
ffffffffc02013cc:	611c                	ld	a5,0(a0)
ffffffffc02013ce:	0705                	addi	a4,a4,1
ffffffffc02013d0:	02868693          	addi	a3,a3,40
ffffffffc02013d4:	01078633          	add	a2,a5,a6
ffffffffc02013d8:	fec765e3          	bltu	a4,a2,ffffffffc02013c2 <pmm_init+0x94>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013dc:	6190                	ld	a2,0(a1)
ffffffffc02013de:	00279713          	slli	a4,a5,0x2
ffffffffc02013e2:	973e                	add	a4,a4,a5
ffffffffc02013e4:	fec006b7          	lui	a3,0xfec00
ffffffffc02013e8:	070e                	slli	a4,a4,0x3
ffffffffc02013ea:	96b2                	add	a3,a3,a2
ffffffffc02013ec:	96ba                	add	a3,a3,a4
ffffffffc02013ee:	c0200737          	lui	a4,0xc0200
ffffffffc02013f2:	08e6ef63          	bltu	a3,a4,ffffffffc0201490 <pmm_init+0x162>
ffffffffc02013f6:	6018                	ld	a4,0(s0)
    if (freemem < mem_end) {
ffffffffc02013f8:	45c5                	li	a1,17
ffffffffc02013fa:	05ee                	slli	a1,a1,0x1b
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc02013fc:	8e99                	sub	a3,a3,a4
    if (freemem < mem_end) {
ffffffffc02013fe:	04b6e863          	bltu	a3,a1,ffffffffc020144e <pmm_init+0x120>
    satp_physical = PADDR(satp_virtual);
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
}

static void check_alloc_page(void) {
    pmm_manager->check();
ffffffffc0201402:	609c                	ld	a5,0(s1)
ffffffffc0201404:	7b9c                	ld	a5,48(a5)
ffffffffc0201406:	9782                	jalr	a5
    cprintf("check_alloc_page() succeeded!\n");
ffffffffc0201408:	00001517          	auipc	a0,0x1
ffffffffc020140c:	1e050513          	addi	a0,a0,480 # ffffffffc02025e8 <best_fit_pmm_manager+0x100>
ffffffffc0201410:	cc9fe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
    satp_virtual = (pte_t*)boot_page_table_sv39;
ffffffffc0201414:	00004597          	auipc	a1,0x4
ffffffffc0201418:	bec58593          	addi	a1,a1,-1044 # ffffffffc0205000 <boot_page_table_sv39>
ffffffffc020141c:	00005797          	auipc	a5,0x5
ffffffffc0201420:	04b7b623          	sd	a1,76(a5) # ffffffffc0206468 <satp_virtual>
    satp_physical = PADDR(satp_virtual);
ffffffffc0201424:	c02007b7          	lui	a5,0xc0200
ffffffffc0201428:	08f5e063          	bltu	a1,a5,ffffffffc02014a8 <pmm_init+0x17a>
ffffffffc020142c:	6010                	ld	a2,0(s0)
}
ffffffffc020142e:	6442                	ld	s0,16(sp)
ffffffffc0201430:	60e2                	ld	ra,24(sp)
ffffffffc0201432:	64a2                	ld	s1,8(sp)
    satp_physical = PADDR(satp_virtual);
ffffffffc0201434:	40c58633          	sub	a2,a1,a2
ffffffffc0201438:	00005797          	auipc	a5,0x5
ffffffffc020143c:	02c7b423          	sd	a2,40(a5) # ffffffffc0206460 <satp_physical>
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc0201440:	00001517          	auipc	a0,0x1
ffffffffc0201444:	1c850513          	addi	a0,a0,456 # ffffffffc0202608 <best_fit_pmm_manager+0x120>
}
ffffffffc0201448:	6105                	addi	sp,sp,32
    cprintf("satp virtual address: 0x%016lx\nsatp physical address: 0x%016lx\n", satp_virtual, satp_physical);
ffffffffc020144a:	c8ffe06f          	j	ffffffffc02000d8 <cprintf>
    mem_begin = ROUNDUP(freemem, PGSIZE);
ffffffffc020144e:	6705                	lui	a4,0x1
ffffffffc0201450:	177d                	addi	a4,a4,-1
ffffffffc0201452:	96ba                	add	a3,a3,a4
ffffffffc0201454:	777d                	lui	a4,0xfffff
ffffffffc0201456:	8ef9                	and	a3,a3,a4
static inline int page_ref_dec(struct Page *page) {
    page->ref -= 1;
    return page->ref;
}
static inline struct Page *pa2page(uintptr_t pa) {
    if (PPN(pa) >= npage) {
ffffffffc0201458:	00c6d513          	srli	a0,a3,0xc
ffffffffc020145c:	00f57e63          	bgeu	a0,a5,ffffffffc0201478 <pmm_init+0x14a>
    pmm_manager->init_memmap(base, n);
ffffffffc0201460:	609c                	ld	a5,0(s1)
        panic("pa2page called with invalid pa");
    }
    return &pages[PPN(pa) - nbase];
ffffffffc0201462:	982a                	add	a6,a6,a0
ffffffffc0201464:	00281513          	slli	a0,a6,0x2
ffffffffc0201468:	9542                	add	a0,a0,a6
ffffffffc020146a:	6b9c                	ld	a5,16(a5)
        init_memmap(pa2page(mem_begin), (mem_end - mem_begin) / PGSIZE);
ffffffffc020146c:	8d95                	sub	a1,a1,a3
ffffffffc020146e:	050e                	slli	a0,a0,0x3
    pmm_manager->init_memmap(base, n);
ffffffffc0201470:	81b1                	srli	a1,a1,0xc
ffffffffc0201472:	9532                	add	a0,a0,a2
ffffffffc0201474:	9782                	jalr	a5
}
ffffffffc0201476:	b771                	j	ffffffffc0201402 <pmm_init+0xd4>
        panic("pa2page called with invalid pa");
ffffffffc0201478:	00001617          	auipc	a2,0x1
ffffffffc020147c:	14060613          	addi	a2,a2,320 # ffffffffc02025b8 <best_fit_pmm_manager+0xd0>
ffffffffc0201480:	06b00593          	li	a1,107
ffffffffc0201484:	00001517          	auipc	a0,0x1
ffffffffc0201488:	15450513          	addi	a0,a0,340 # ffffffffc02025d8 <best_fit_pmm_manager+0xf0>
ffffffffc020148c:	f47fe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    uintptr_t freemem = PADDR((uintptr_t)pages + sizeof(struct Page) * (npage - nbase));
ffffffffc0201490:	00001617          	auipc	a2,0x1
ffffffffc0201494:	0f060613          	addi	a2,a2,240 # ffffffffc0202580 <best_fit_pmm_manager+0x98>
ffffffffc0201498:	06e00593          	li	a1,110
ffffffffc020149c:	00001517          	auipc	a0,0x1
ffffffffc02014a0:	10c50513          	addi	a0,a0,268 # ffffffffc02025a8 <best_fit_pmm_manager+0xc0>
ffffffffc02014a4:	f2ffe0ef          	jal	ra,ffffffffc02003d2 <__panic>
    satp_physical = PADDR(satp_virtual);
ffffffffc02014a8:	86ae                	mv	a3,a1
ffffffffc02014aa:	00001617          	auipc	a2,0x1
ffffffffc02014ae:	0d660613          	addi	a2,a2,214 # ffffffffc0202580 <best_fit_pmm_manager+0x98>
ffffffffc02014b2:	08900593          	li	a1,137
ffffffffc02014b6:	00001517          	auipc	a0,0x1
ffffffffc02014ba:	0f250513          	addi	a0,a0,242 # ffffffffc02025a8 <best_fit_pmm_manager+0xc0>
ffffffffc02014be:	f15fe0ef          	jal	ra,ffffffffc02003d2 <__panic>

ffffffffc02014c2 <printnum>:
 * */
static void
printnum(void (*putch)(int, void*), void *putdat,
        unsigned long long num, unsigned base, int width, int padc) {
    unsigned long long result = num;
    unsigned mod = do_div(result, base);
ffffffffc02014c2:	02069813          	slli	a6,a3,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014c6:	7179                	addi	sp,sp,-48
    unsigned mod = do_div(result, base);
ffffffffc02014c8:	02085813          	srli	a6,a6,0x20
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014cc:	e052                	sd	s4,0(sp)
    unsigned mod = do_div(result, base);
ffffffffc02014ce:	03067a33          	remu	s4,a2,a6
        unsigned long long num, unsigned base, int width, int padc) {
ffffffffc02014d2:	f022                	sd	s0,32(sp)
ffffffffc02014d4:	ec26                	sd	s1,24(sp)
ffffffffc02014d6:	e84a                	sd	s2,16(sp)
ffffffffc02014d8:	f406                	sd	ra,40(sp)
ffffffffc02014da:	e44e                	sd	s3,8(sp)
ffffffffc02014dc:	84aa                	mv	s1,a0
ffffffffc02014de:	892e                	mv	s2,a1
    // first recursively print all preceding (more significant) digits
    if (num >= base) {
        printnum(putch, putdat, result, base, width - 1, padc);
    } else {
        // print any needed pad characters before first digit
        while (-- width > 0)
ffffffffc02014e0:	fff7041b          	addiw	s0,a4,-1
    unsigned mod = do_div(result, base);
ffffffffc02014e4:	2a01                	sext.w	s4,s4
    if (num >= base) {
ffffffffc02014e6:	03067e63          	bgeu	a2,a6,ffffffffc0201522 <printnum+0x60>
ffffffffc02014ea:	89be                	mv	s3,a5
        while (-- width > 0)
ffffffffc02014ec:	00805763          	blez	s0,ffffffffc02014fa <printnum+0x38>
ffffffffc02014f0:	347d                	addiw	s0,s0,-1
            putch(padc, putdat);
ffffffffc02014f2:	85ca                	mv	a1,s2
ffffffffc02014f4:	854e                	mv	a0,s3
ffffffffc02014f6:	9482                	jalr	s1
        while (-- width > 0)
ffffffffc02014f8:	fc65                	bnez	s0,ffffffffc02014f0 <printnum+0x2e>
    }
    // then print this (the least significant) digit
    putch("0123456789abcdef"[mod], putdat);
ffffffffc02014fa:	1a02                	slli	s4,s4,0x20
ffffffffc02014fc:	00001797          	auipc	a5,0x1
ffffffffc0201500:	14c78793          	addi	a5,a5,332 # ffffffffc0202648 <best_fit_pmm_manager+0x160>
ffffffffc0201504:	020a5a13          	srli	s4,s4,0x20
ffffffffc0201508:	9a3e                	add	s4,s4,a5
}
ffffffffc020150a:	7402                	ld	s0,32(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc020150c:	000a4503          	lbu	a0,0(s4)
}
ffffffffc0201510:	70a2                	ld	ra,40(sp)
ffffffffc0201512:	69a2                	ld	s3,8(sp)
ffffffffc0201514:	6a02                	ld	s4,0(sp)
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201516:	85ca                	mv	a1,s2
ffffffffc0201518:	87a6                	mv	a5,s1
}
ffffffffc020151a:	6942                	ld	s2,16(sp)
ffffffffc020151c:	64e2                	ld	s1,24(sp)
ffffffffc020151e:	6145                	addi	sp,sp,48
    putch("0123456789abcdef"[mod], putdat);
ffffffffc0201520:	8782                	jr	a5
        printnum(putch, putdat, result, base, width - 1, padc);
ffffffffc0201522:	03065633          	divu	a2,a2,a6
ffffffffc0201526:	8722                	mv	a4,s0
ffffffffc0201528:	f9bff0ef          	jal	ra,ffffffffc02014c2 <printnum>
ffffffffc020152c:	b7f9                	j	ffffffffc02014fa <printnum+0x38>

ffffffffc020152e <vprintfmt>:
 *
 * Call this function if you are already dealing with a va_list.
 * Or you probably want printfmt() instead.
 * */
void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap) {
ffffffffc020152e:	7119                	addi	sp,sp,-128
ffffffffc0201530:	f4a6                	sd	s1,104(sp)
ffffffffc0201532:	f0ca                	sd	s2,96(sp)
ffffffffc0201534:	ecce                	sd	s3,88(sp)
ffffffffc0201536:	e8d2                	sd	s4,80(sp)
ffffffffc0201538:	e4d6                	sd	s5,72(sp)
ffffffffc020153a:	e0da                	sd	s6,64(sp)
ffffffffc020153c:	fc5e                	sd	s7,56(sp)
ffffffffc020153e:	f06a                	sd	s10,32(sp)
ffffffffc0201540:	fc86                	sd	ra,120(sp)
ffffffffc0201542:	f8a2                	sd	s0,112(sp)
ffffffffc0201544:	f862                	sd	s8,48(sp)
ffffffffc0201546:	f466                	sd	s9,40(sp)
ffffffffc0201548:	ec6e                	sd	s11,24(sp)
ffffffffc020154a:	892a                	mv	s2,a0
ffffffffc020154c:	84ae                	mv	s1,a1
ffffffffc020154e:	8d32                	mv	s10,a2
ffffffffc0201550:	8a36                	mv	s4,a3
    register int ch, err;
    unsigned long long num;
    int base, width, precision, lflag, altflag;

    while (1) {
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201552:	02500993          	li	s3,37
            putch(ch, putdat);
        }

        // Process a %-escape sequence
        char padc = ' ';
        width = precision = -1;
ffffffffc0201556:	5b7d                	li	s6,-1
ffffffffc0201558:	00001a97          	auipc	s5,0x1
ffffffffc020155c:	124a8a93          	addi	s5,s5,292 # ffffffffc020267c <best_fit_pmm_manager+0x194>
        case 'e':
            err = va_arg(ap, int);
            if (err < 0) {
                err = -err;
            }
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201560:	00001b97          	auipc	s7,0x1
ffffffffc0201564:	2f8b8b93          	addi	s7,s7,760 # ffffffffc0202858 <error_string>
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201568:	000d4503          	lbu	a0,0(s10)
ffffffffc020156c:	001d0413          	addi	s0,s10,1
ffffffffc0201570:	01350a63          	beq	a0,s3,ffffffffc0201584 <vprintfmt+0x56>
            if (ch == '\0') {
ffffffffc0201574:	c121                	beqz	a0,ffffffffc02015b4 <vprintfmt+0x86>
            putch(ch, putdat);
ffffffffc0201576:	85a6                	mv	a1,s1
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc0201578:	0405                	addi	s0,s0,1
            putch(ch, putdat);
ffffffffc020157a:	9902                	jalr	s2
        while ((ch = *(unsigned char *)fmt ++) != '%') {
ffffffffc020157c:	fff44503          	lbu	a0,-1(s0)
ffffffffc0201580:	ff351ae3          	bne	a0,s3,ffffffffc0201574 <vprintfmt+0x46>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201584:	00044603          	lbu	a2,0(s0)
        char padc = ' ';
ffffffffc0201588:	02000793          	li	a5,32
        lflag = altflag = 0;
ffffffffc020158c:	4c81                	li	s9,0
ffffffffc020158e:	4881                	li	a7,0
        width = precision = -1;
ffffffffc0201590:	5c7d                	li	s8,-1
ffffffffc0201592:	5dfd                	li	s11,-1
ffffffffc0201594:	05500513          	li	a0,85
                if (ch < '0' || ch > '9') {
ffffffffc0201598:	4825                	li	a6,9
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020159a:	fdd6059b          	addiw	a1,a2,-35
ffffffffc020159e:	0ff5f593          	zext.b	a1,a1
ffffffffc02015a2:	00140d13          	addi	s10,s0,1
ffffffffc02015a6:	04b56263          	bltu	a0,a1,ffffffffc02015ea <vprintfmt+0xbc>
ffffffffc02015aa:	058a                	slli	a1,a1,0x2
ffffffffc02015ac:	95d6                	add	a1,a1,s5
ffffffffc02015ae:	4194                	lw	a3,0(a1)
ffffffffc02015b0:	96d6                	add	a3,a3,s5
ffffffffc02015b2:	8682                	jr	a3
            for (fmt --; fmt[-1] != '%'; fmt --)
                /* do nothing */;
            break;
        }
    }
}
ffffffffc02015b4:	70e6                	ld	ra,120(sp)
ffffffffc02015b6:	7446                	ld	s0,112(sp)
ffffffffc02015b8:	74a6                	ld	s1,104(sp)
ffffffffc02015ba:	7906                	ld	s2,96(sp)
ffffffffc02015bc:	69e6                	ld	s3,88(sp)
ffffffffc02015be:	6a46                	ld	s4,80(sp)
ffffffffc02015c0:	6aa6                	ld	s5,72(sp)
ffffffffc02015c2:	6b06                	ld	s6,64(sp)
ffffffffc02015c4:	7be2                	ld	s7,56(sp)
ffffffffc02015c6:	7c42                	ld	s8,48(sp)
ffffffffc02015c8:	7ca2                	ld	s9,40(sp)
ffffffffc02015ca:	7d02                	ld	s10,32(sp)
ffffffffc02015cc:	6de2                	ld	s11,24(sp)
ffffffffc02015ce:	6109                	addi	sp,sp,128
ffffffffc02015d0:	8082                	ret
            padc = '0';
ffffffffc02015d2:	87b2                	mv	a5,a2
            goto reswitch;
ffffffffc02015d4:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02015d8:	846a                	mv	s0,s10
ffffffffc02015da:	00140d13          	addi	s10,s0,1
ffffffffc02015de:	fdd6059b          	addiw	a1,a2,-35
ffffffffc02015e2:	0ff5f593          	zext.b	a1,a1
ffffffffc02015e6:	fcb572e3          	bgeu	a0,a1,ffffffffc02015aa <vprintfmt+0x7c>
            putch('%', putdat);
ffffffffc02015ea:	85a6                	mv	a1,s1
ffffffffc02015ec:	02500513          	li	a0,37
ffffffffc02015f0:	9902                	jalr	s2
            for (fmt --; fmt[-1] != '%'; fmt --)
ffffffffc02015f2:	fff44783          	lbu	a5,-1(s0)
ffffffffc02015f6:	8d22                	mv	s10,s0
ffffffffc02015f8:	f73788e3          	beq	a5,s3,ffffffffc0201568 <vprintfmt+0x3a>
ffffffffc02015fc:	ffed4783          	lbu	a5,-2(s10)
ffffffffc0201600:	1d7d                	addi	s10,s10,-1
ffffffffc0201602:	ff379de3          	bne	a5,s3,ffffffffc02015fc <vprintfmt+0xce>
ffffffffc0201606:	b78d                	j	ffffffffc0201568 <vprintfmt+0x3a>
                precision = precision * 10 + ch - '0';
ffffffffc0201608:	fd060c1b          	addiw	s8,a2,-48
                ch = *fmt;
ffffffffc020160c:	00144603          	lbu	a2,1(s0)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201610:	846a                	mv	s0,s10
                if (ch < '0' || ch > '9') {
ffffffffc0201612:	fd06069b          	addiw	a3,a2,-48
                ch = *fmt;
ffffffffc0201616:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020161a:	02d86463          	bltu	a6,a3,ffffffffc0201642 <vprintfmt+0x114>
                ch = *fmt;
ffffffffc020161e:	00144603          	lbu	a2,1(s0)
                precision = precision * 10 + ch - '0';
ffffffffc0201622:	002c169b          	slliw	a3,s8,0x2
ffffffffc0201626:	0186873b          	addw	a4,a3,s8
ffffffffc020162a:	0017171b          	slliw	a4,a4,0x1
ffffffffc020162e:	9f2d                	addw	a4,a4,a1
                if (ch < '0' || ch > '9') {
ffffffffc0201630:	fd06069b          	addiw	a3,a2,-48
            for (precision = 0; ; ++ fmt) {
ffffffffc0201634:	0405                	addi	s0,s0,1
                precision = precision * 10 + ch - '0';
ffffffffc0201636:	fd070c1b          	addiw	s8,a4,-48
                ch = *fmt;
ffffffffc020163a:	0006059b          	sext.w	a1,a2
                if (ch < '0' || ch > '9') {
ffffffffc020163e:	fed870e3          	bgeu	a6,a3,ffffffffc020161e <vprintfmt+0xf0>
            if (width < 0)
ffffffffc0201642:	f40ddce3          	bgez	s11,ffffffffc020159a <vprintfmt+0x6c>
                width = precision, precision = -1;
ffffffffc0201646:	8de2                	mv	s11,s8
ffffffffc0201648:	5c7d                	li	s8,-1
ffffffffc020164a:	bf81                	j	ffffffffc020159a <vprintfmt+0x6c>
            if (width < 0)
ffffffffc020164c:	fffdc693          	not	a3,s11
ffffffffc0201650:	96fd                	srai	a3,a3,0x3f
ffffffffc0201652:	00ddfdb3          	and	s11,s11,a3
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201656:	00144603          	lbu	a2,1(s0)
ffffffffc020165a:	2d81                	sext.w	s11,s11
ffffffffc020165c:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc020165e:	bf35                	j	ffffffffc020159a <vprintfmt+0x6c>
            precision = va_arg(ap, int);
ffffffffc0201660:	000a2c03          	lw	s8,0(s4)
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc0201664:	00144603          	lbu	a2,1(s0)
            precision = va_arg(ap, int);
ffffffffc0201668:	0a21                	addi	s4,s4,8
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc020166a:	846a                	mv	s0,s10
            goto process_precision;
ffffffffc020166c:	bfd9                	j	ffffffffc0201642 <vprintfmt+0x114>
    if (lflag >= 2) {
ffffffffc020166e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201670:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc0201674:	01174463          	blt	a4,a7,ffffffffc020167c <vprintfmt+0x14e>
    else if (lflag) {
ffffffffc0201678:	1a088e63          	beqz	a7,ffffffffc0201834 <vprintfmt+0x306>
        return va_arg(*ap, unsigned long);
ffffffffc020167c:	000a3603          	ld	a2,0(s4)
ffffffffc0201680:	46c1                	li	a3,16
ffffffffc0201682:	8a2e                	mv	s4,a1
            printnum(putch, putdat, num, base, width, padc);
ffffffffc0201684:	2781                	sext.w	a5,a5
ffffffffc0201686:	876e                	mv	a4,s11
ffffffffc0201688:	85a6                	mv	a1,s1
ffffffffc020168a:	854a                	mv	a0,s2
ffffffffc020168c:	e37ff0ef          	jal	ra,ffffffffc02014c2 <printnum>
            break;
ffffffffc0201690:	bde1                	j	ffffffffc0201568 <vprintfmt+0x3a>
            putch(va_arg(ap, int), putdat);
ffffffffc0201692:	000a2503          	lw	a0,0(s4)
ffffffffc0201696:	85a6                	mv	a1,s1
ffffffffc0201698:	0a21                	addi	s4,s4,8
ffffffffc020169a:	9902                	jalr	s2
            break;
ffffffffc020169c:	b5f1                	j	ffffffffc0201568 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc020169e:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016a0:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02016a4:	01174463          	blt	a4,a7,ffffffffc02016ac <vprintfmt+0x17e>
    else if (lflag) {
ffffffffc02016a8:	18088163          	beqz	a7,ffffffffc020182a <vprintfmt+0x2fc>
        return va_arg(*ap, unsigned long);
ffffffffc02016ac:	000a3603          	ld	a2,0(s4)
ffffffffc02016b0:	46a9                	li	a3,10
ffffffffc02016b2:	8a2e                	mv	s4,a1
ffffffffc02016b4:	bfc1                	j	ffffffffc0201684 <vprintfmt+0x156>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016b6:	00144603          	lbu	a2,1(s0)
            altflag = 1;
ffffffffc02016ba:	4c85                	li	s9,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016bc:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016be:	bdf1                	j	ffffffffc020159a <vprintfmt+0x6c>
            putch(ch, putdat);
ffffffffc02016c0:	85a6                	mv	a1,s1
ffffffffc02016c2:	02500513          	li	a0,37
ffffffffc02016c6:	9902                	jalr	s2
            break;
ffffffffc02016c8:	b545                	j	ffffffffc0201568 <vprintfmt+0x3a>
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016ca:	00144603          	lbu	a2,1(s0)
            lflag ++;
ffffffffc02016ce:	2885                	addiw	a7,a7,1
        switch (ch = *(unsigned char *)fmt ++) {
ffffffffc02016d0:	846a                	mv	s0,s10
            goto reswitch;
ffffffffc02016d2:	b5e1                	j	ffffffffc020159a <vprintfmt+0x6c>
    if (lflag >= 2) {
ffffffffc02016d4:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc02016d6:	008a0593          	addi	a1,s4,8
    if (lflag >= 2) {
ffffffffc02016da:	01174463          	blt	a4,a7,ffffffffc02016e2 <vprintfmt+0x1b4>
    else if (lflag) {
ffffffffc02016de:	14088163          	beqz	a7,ffffffffc0201820 <vprintfmt+0x2f2>
        return va_arg(*ap, unsigned long);
ffffffffc02016e2:	000a3603          	ld	a2,0(s4)
ffffffffc02016e6:	46a1                	li	a3,8
ffffffffc02016e8:	8a2e                	mv	s4,a1
ffffffffc02016ea:	bf69                	j	ffffffffc0201684 <vprintfmt+0x156>
            putch('0', putdat);
ffffffffc02016ec:	03000513          	li	a0,48
ffffffffc02016f0:	85a6                	mv	a1,s1
ffffffffc02016f2:	e03e                	sd	a5,0(sp)
ffffffffc02016f4:	9902                	jalr	s2
            putch('x', putdat);
ffffffffc02016f6:	85a6                	mv	a1,s1
ffffffffc02016f8:	07800513          	li	a0,120
ffffffffc02016fc:	9902                	jalr	s2
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc02016fe:	0a21                	addi	s4,s4,8
            goto number;
ffffffffc0201700:	6782                	ld	a5,0(sp)
ffffffffc0201702:	46c1                	li	a3,16
            num = (unsigned long long)(uintptr_t)va_arg(ap, void *);
ffffffffc0201704:	ff8a3603          	ld	a2,-8(s4)
            goto number;
ffffffffc0201708:	bfb5                	j	ffffffffc0201684 <vprintfmt+0x156>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc020170a:	000a3403          	ld	s0,0(s4)
ffffffffc020170e:	008a0713          	addi	a4,s4,8
ffffffffc0201712:	e03a                	sd	a4,0(sp)
ffffffffc0201714:	14040263          	beqz	s0,ffffffffc0201858 <vprintfmt+0x32a>
            if (width > 0 && padc != '-') {
ffffffffc0201718:	0fb05763          	blez	s11,ffffffffc0201806 <vprintfmt+0x2d8>
ffffffffc020171c:	02d00693          	li	a3,45
ffffffffc0201720:	0cd79163          	bne	a5,a3,ffffffffc02017e2 <vprintfmt+0x2b4>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201724:	00044783          	lbu	a5,0(s0)
ffffffffc0201728:	0007851b          	sext.w	a0,a5
ffffffffc020172c:	cf85                	beqz	a5,ffffffffc0201764 <vprintfmt+0x236>
ffffffffc020172e:	00140a13          	addi	s4,s0,1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201732:	05e00413          	li	s0,94
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201736:	000c4563          	bltz	s8,ffffffffc0201740 <vprintfmt+0x212>
ffffffffc020173a:	3c7d                	addiw	s8,s8,-1
ffffffffc020173c:	036c0263          	beq	s8,s6,ffffffffc0201760 <vprintfmt+0x232>
                    putch('?', putdat);
ffffffffc0201740:	85a6                	mv	a1,s1
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201742:	0e0c8e63          	beqz	s9,ffffffffc020183e <vprintfmt+0x310>
ffffffffc0201746:	3781                	addiw	a5,a5,-32
ffffffffc0201748:	0ef47b63          	bgeu	s0,a5,ffffffffc020183e <vprintfmt+0x310>
                    putch('?', putdat);
ffffffffc020174c:	03f00513          	li	a0,63
ffffffffc0201750:	9902                	jalr	s2
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201752:	000a4783          	lbu	a5,0(s4)
ffffffffc0201756:	3dfd                	addiw	s11,s11,-1
ffffffffc0201758:	0a05                	addi	s4,s4,1
ffffffffc020175a:	0007851b          	sext.w	a0,a5
ffffffffc020175e:	ffe1                	bnez	a5,ffffffffc0201736 <vprintfmt+0x208>
            for (; width > 0; width --) {
ffffffffc0201760:	01b05963          	blez	s11,ffffffffc0201772 <vprintfmt+0x244>
ffffffffc0201764:	3dfd                	addiw	s11,s11,-1
                putch(' ', putdat);
ffffffffc0201766:	85a6                	mv	a1,s1
ffffffffc0201768:	02000513          	li	a0,32
ffffffffc020176c:	9902                	jalr	s2
            for (; width > 0; width --) {
ffffffffc020176e:	fe0d9be3          	bnez	s11,ffffffffc0201764 <vprintfmt+0x236>
            if ((p = va_arg(ap, char *)) == NULL) {
ffffffffc0201772:	6a02                	ld	s4,0(sp)
ffffffffc0201774:	bbd5                	j	ffffffffc0201568 <vprintfmt+0x3a>
    if (lflag >= 2) {
ffffffffc0201776:	4705                	li	a4,1
            precision = va_arg(ap, int);
ffffffffc0201778:	008a0c93          	addi	s9,s4,8
    if (lflag >= 2) {
ffffffffc020177c:	01174463          	blt	a4,a7,ffffffffc0201784 <vprintfmt+0x256>
    else if (lflag) {
ffffffffc0201780:	08088d63          	beqz	a7,ffffffffc020181a <vprintfmt+0x2ec>
        return va_arg(*ap, long);
ffffffffc0201784:	000a3403          	ld	s0,0(s4)
            if ((long long)num < 0) {
ffffffffc0201788:	0a044d63          	bltz	s0,ffffffffc0201842 <vprintfmt+0x314>
            num = getint(&ap, lflag);
ffffffffc020178c:	8622                	mv	a2,s0
ffffffffc020178e:	8a66                	mv	s4,s9
ffffffffc0201790:	46a9                	li	a3,10
ffffffffc0201792:	bdcd                	j	ffffffffc0201684 <vprintfmt+0x156>
            err = va_arg(ap, int);
ffffffffc0201794:	000a2783          	lw	a5,0(s4)
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc0201798:	4719                	li	a4,6
            err = va_arg(ap, int);
ffffffffc020179a:	0a21                	addi	s4,s4,8
            if (err < 0) {
ffffffffc020179c:	41f7d69b          	sraiw	a3,a5,0x1f
ffffffffc02017a0:	8fb5                	xor	a5,a5,a3
ffffffffc02017a2:	40d786bb          	subw	a3,a5,a3
            if (err > MAXERROR || (p = error_string[err]) == NULL) {
ffffffffc02017a6:	02d74163          	blt	a4,a3,ffffffffc02017c8 <vprintfmt+0x29a>
ffffffffc02017aa:	00369793          	slli	a5,a3,0x3
ffffffffc02017ae:	97de                	add	a5,a5,s7
ffffffffc02017b0:	639c                	ld	a5,0(a5)
ffffffffc02017b2:	cb99                	beqz	a5,ffffffffc02017c8 <vprintfmt+0x29a>
                printfmt(putch, putdat, "%s", p);
ffffffffc02017b4:	86be                	mv	a3,a5
ffffffffc02017b6:	00001617          	auipc	a2,0x1
ffffffffc02017ba:	ec260613          	addi	a2,a2,-318 # ffffffffc0202678 <best_fit_pmm_manager+0x190>
ffffffffc02017be:	85a6                	mv	a1,s1
ffffffffc02017c0:	854a                	mv	a0,s2
ffffffffc02017c2:	0ce000ef          	jal	ra,ffffffffc0201890 <printfmt>
ffffffffc02017c6:	b34d                	j	ffffffffc0201568 <vprintfmt+0x3a>
                printfmt(putch, putdat, "error %d", err);
ffffffffc02017c8:	00001617          	auipc	a2,0x1
ffffffffc02017cc:	ea060613          	addi	a2,a2,-352 # ffffffffc0202668 <best_fit_pmm_manager+0x180>
ffffffffc02017d0:	85a6                	mv	a1,s1
ffffffffc02017d2:	854a                	mv	a0,s2
ffffffffc02017d4:	0bc000ef          	jal	ra,ffffffffc0201890 <printfmt>
ffffffffc02017d8:	bb41                	j	ffffffffc0201568 <vprintfmt+0x3a>
                p = "(null)";
ffffffffc02017da:	00001417          	auipc	s0,0x1
ffffffffc02017de:	e8640413          	addi	s0,s0,-378 # ffffffffc0202660 <best_fit_pmm_manager+0x178>
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017e2:	85e2                	mv	a1,s8
ffffffffc02017e4:	8522                	mv	a0,s0
ffffffffc02017e6:	e43e                	sd	a5,8(sp)
ffffffffc02017e8:	1cc000ef          	jal	ra,ffffffffc02019b4 <strnlen>
ffffffffc02017ec:	40ad8dbb          	subw	s11,s11,a0
ffffffffc02017f0:	01b05b63          	blez	s11,ffffffffc0201806 <vprintfmt+0x2d8>
                    putch(padc, putdat);
ffffffffc02017f4:	67a2                	ld	a5,8(sp)
ffffffffc02017f6:	00078a1b          	sext.w	s4,a5
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc02017fa:	3dfd                	addiw	s11,s11,-1
                    putch(padc, putdat);
ffffffffc02017fc:	85a6                	mv	a1,s1
ffffffffc02017fe:	8552                	mv	a0,s4
ffffffffc0201800:	9902                	jalr	s2
                for (width -= strnlen(p, precision); width > 0; width --) {
ffffffffc0201802:	fe0d9ce3          	bnez	s11,ffffffffc02017fa <vprintfmt+0x2cc>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc0201806:	00044783          	lbu	a5,0(s0)
ffffffffc020180a:	00140a13          	addi	s4,s0,1
ffffffffc020180e:	0007851b          	sext.w	a0,a5
ffffffffc0201812:	d3a5                	beqz	a5,ffffffffc0201772 <vprintfmt+0x244>
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc0201814:	05e00413          	li	s0,94
ffffffffc0201818:	bf39                	j	ffffffffc0201736 <vprintfmt+0x208>
        return va_arg(*ap, int);
ffffffffc020181a:	000a2403          	lw	s0,0(s4)
ffffffffc020181e:	b7ad                	j	ffffffffc0201788 <vprintfmt+0x25a>
        return va_arg(*ap, unsigned int);
ffffffffc0201820:	000a6603          	lwu	a2,0(s4)
ffffffffc0201824:	46a1                	li	a3,8
ffffffffc0201826:	8a2e                	mv	s4,a1
ffffffffc0201828:	bdb1                	j	ffffffffc0201684 <vprintfmt+0x156>
ffffffffc020182a:	000a6603          	lwu	a2,0(s4)
ffffffffc020182e:	46a9                	li	a3,10
ffffffffc0201830:	8a2e                	mv	s4,a1
ffffffffc0201832:	bd89                	j	ffffffffc0201684 <vprintfmt+0x156>
ffffffffc0201834:	000a6603          	lwu	a2,0(s4)
ffffffffc0201838:	46c1                	li	a3,16
ffffffffc020183a:	8a2e                	mv	s4,a1
ffffffffc020183c:	b5a1                	j	ffffffffc0201684 <vprintfmt+0x156>
                    putch(ch, putdat);
ffffffffc020183e:	9902                	jalr	s2
ffffffffc0201840:	bf09                	j	ffffffffc0201752 <vprintfmt+0x224>
                putch('-', putdat);
ffffffffc0201842:	85a6                	mv	a1,s1
ffffffffc0201844:	02d00513          	li	a0,45
ffffffffc0201848:	e03e                	sd	a5,0(sp)
ffffffffc020184a:	9902                	jalr	s2
                num = -(long long)num;
ffffffffc020184c:	6782                	ld	a5,0(sp)
ffffffffc020184e:	8a66                	mv	s4,s9
ffffffffc0201850:	40800633          	neg	a2,s0
ffffffffc0201854:	46a9                	li	a3,10
ffffffffc0201856:	b53d                	j	ffffffffc0201684 <vprintfmt+0x156>
            if (width > 0 && padc != '-') {
ffffffffc0201858:	03b05163          	blez	s11,ffffffffc020187a <vprintfmt+0x34c>
ffffffffc020185c:	02d00693          	li	a3,45
ffffffffc0201860:	f6d79de3          	bne	a5,a3,ffffffffc02017da <vprintfmt+0x2ac>
                p = "(null)";
ffffffffc0201864:	00001417          	auipc	s0,0x1
ffffffffc0201868:	dfc40413          	addi	s0,s0,-516 # ffffffffc0202660 <best_fit_pmm_manager+0x178>
            for (; (ch = *p ++) != '\0' && (precision < 0 || -- precision >= 0); width --) {
ffffffffc020186c:	02800793          	li	a5,40
ffffffffc0201870:	02800513          	li	a0,40
ffffffffc0201874:	00140a13          	addi	s4,s0,1
ffffffffc0201878:	bd6d                	j	ffffffffc0201732 <vprintfmt+0x204>
ffffffffc020187a:	00001a17          	auipc	s4,0x1
ffffffffc020187e:	de7a0a13          	addi	s4,s4,-537 # ffffffffc0202661 <best_fit_pmm_manager+0x179>
ffffffffc0201882:	02800513          	li	a0,40
ffffffffc0201886:	02800793          	li	a5,40
                if (altflag && (ch < ' ' || ch > '~')) {
ffffffffc020188a:	05e00413          	li	s0,94
ffffffffc020188e:	b565                	j	ffffffffc0201736 <vprintfmt+0x208>

ffffffffc0201890 <printfmt>:
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201890:	715d                	addi	sp,sp,-80
    va_start(ap, fmt);
ffffffffc0201892:	02810313          	addi	t1,sp,40
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc0201896:	f436                	sd	a3,40(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc0201898:	869a                	mv	a3,t1
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...) {
ffffffffc020189a:	ec06                	sd	ra,24(sp)
ffffffffc020189c:	f83a                	sd	a4,48(sp)
ffffffffc020189e:	fc3e                	sd	a5,56(sp)
ffffffffc02018a0:	e0c2                	sd	a6,64(sp)
ffffffffc02018a2:	e4c6                	sd	a7,72(sp)
    va_start(ap, fmt);
ffffffffc02018a4:	e41a                	sd	t1,8(sp)
    vprintfmt(putch, putdat, fmt, ap);
ffffffffc02018a6:	c89ff0ef          	jal	ra,ffffffffc020152e <vprintfmt>
}
ffffffffc02018aa:	60e2                	ld	ra,24(sp)
ffffffffc02018ac:	6161                	addi	sp,sp,80
ffffffffc02018ae:	8082                	ret

ffffffffc02018b0 <readline>:
 * The readline() function returns the text of the line read. If some errors
 * are happened, NULL is returned. The return value is a global variable,
 * thus it should be copied before it is used.
 * */
char *
readline(const char *prompt) {
ffffffffc02018b0:	715d                	addi	sp,sp,-80
ffffffffc02018b2:	e486                	sd	ra,72(sp)
ffffffffc02018b4:	e0a6                	sd	s1,64(sp)
ffffffffc02018b6:	fc4a                	sd	s2,56(sp)
ffffffffc02018b8:	f84e                	sd	s3,48(sp)
ffffffffc02018ba:	f452                	sd	s4,40(sp)
ffffffffc02018bc:	f056                	sd	s5,32(sp)
ffffffffc02018be:	ec5a                	sd	s6,24(sp)
ffffffffc02018c0:	e85e                	sd	s7,16(sp)
    if (prompt != NULL) {
ffffffffc02018c2:	c901                	beqz	a0,ffffffffc02018d2 <readline+0x22>
ffffffffc02018c4:	85aa                	mv	a1,a0
        cprintf("%s", prompt);
ffffffffc02018c6:	00001517          	auipc	a0,0x1
ffffffffc02018ca:	db250513          	addi	a0,a0,-590 # ffffffffc0202678 <best_fit_pmm_manager+0x190>
ffffffffc02018ce:	80bfe0ef          	jal	ra,ffffffffc02000d8 <cprintf>
readline(const char *prompt) {
ffffffffc02018d2:	4481                	li	s1,0
    while (1) {
        c = getchar();
        if (c < 0) {
            return NULL;
        }
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018d4:	497d                	li	s2,31
            cputchar(c);
            buf[i ++] = c;
        }
        else if (c == '\b' && i > 0) {
ffffffffc02018d6:	49a1                	li	s3,8
            cputchar(c);
            i --;
        }
        else if (c == '\n' || c == '\r') {
ffffffffc02018d8:	4aa9                	li	s5,10
ffffffffc02018da:	4b35                	li	s6,13
            buf[i ++] = c;
ffffffffc02018dc:	00004b97          	auipc	s7,0x4
ffffffffc02018e0:	75cb8b93          	addi	s7,s7,1884 # ffffffffc0206038 <buf>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018e4:	3fe00a13          	li	s4,1022
        c = getchar();
ffffffffc02018e8:	869fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc02018ec:	00054a63          	bltz	a0,ffffffffc0201900 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc02018f0:	00a95a63          	bge	s2,a0,ffffffffc0201904 <readline+0x54>
ffffffffc02018f4:	029a5263          	bge	s4,s1,ffffffffc0201918 <readline+0x68>
        c = getchar();
ffffffffc02018f8:	859fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc02018fc:	fe055ae3          	bgez	a0,ffffffffc02018f0 <readline+0x40>
            return NULL;
ffffffffc0201900:	4501                	li	a0,0
ffffffffc0201902:	a091                	j	ffffffffc0201946 <readline+0x96>
        else if (c == '\b' && i > 0) {
ffffffffc0201904:	03351463          	bne	a0,s3,ffffffffc020192c <readline+0x7c>
ffffffffc0201908:	e8a9                	bnez	s1,ffffffffc020195a <readline+0xaa>
        c = getchar();
ffffffffc020190a:	847fe0ef          	jal	ra,ffffffffc0200150 <getchar>
        if (c < 0) {
ffffffffc020190e:	fe0549e3          	bltz	a0,ffffffffc0201900 <readline+0x50>
        else if (c >= ' ' && i < BUFSIZE - 1) {
ffffffffc0201912:	fea959e3          	bge	s2,a0,ffffffffc0201904 <readline+0x54>
ffffffffc0201916:	4481                	li	s1,0
            cputchar(c);
ffffffffc0201918:	e42a                	sd	a0,8(sp)
ffffffffc020191a:	ff4fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i ++] = c;
ffffffffc020191e:	6522                	ld	a0,8(sp)
ffffffffc0201920:	009b87b3          	add	a5,s7,s1
ffffffffc0201924:	2485                	addiw	s1,s1,1
ffffffffc0201926:	00a78023          	sb	a0,0(a5)
ffffffffc020192a:	bf7d                	j	ffffffffc02018e8 <readline+0x38>
        else if (c == '\n' || c == '\r') {
ffffffffc020192c:	01550463          	beq	a0,s5,ffffffffc0201934 <readline+0x84>
ffffffffc0201930:	fb651ce3          	bne	a0,s6,ffffffffc02018e8 <readline+0x38>
            cputchar(c);
ffffffffc0201934:	fdafe0ef          	jal	ra,ffffffffc020010e <cputchar>
            buf[i] = '\0';
ffffffffc0201938:	00004517          	auipc	a0,0x4
ffffffffc020193c:	70050513          	addi	a0,a0,1792 # ffffffffc0206038 <buf>
ffffffffc0201940:	94aa                	add	s1,s1,a0
ffffffffc0201942:	00048023          	sb	zero,0(s1)
            return buf;
        }
    }
}
ffffffffc0201946:	60a6                	ld	ra,72(sp)
ffffffffc0201948:	6486                	ld	s1,64(sp)
ffffffffc020194a:	7962                	ld	s2,56(sp)
ffffffffc020194c:	79c2                	ld	s3,48(sp)
ffffffffc020194e:	7a22                	ld	s4,40(sp)
ffffffffc0201950:	7a82                	ld	s5,32(sp)
ffffffffc0201952:	6b62                	ld	s6,24(sp)
ffffffffc0201954:	6bc2                	ld	s7,16(sp)
ffffffffc0201956:	6161                	addi	sp,sp,80
ffffffffc0201958:	8082                	ret
            cputchar(c);
ffffffffc020195a:	4521                	li	a0,8
ffffffffc020195c:	fb2fe0ef          	jal	ra,ffffffffc020010e <cputchar>
            i --;
ffffffffc0201960:	34fd                	addiw	s1,s1,-1
ffffffffc0201962:	b759                	j	ffffffffc02018e8 <readline+0x38>

ffffffffc0201964 <sbi_console_putchar>:
uint64_t SBI_REMOTE_SFENCE_VMA_ASID = 7;
uint64_t SBI_SHUTDOWN = 8;

uint64_t sbi_call(uint64_t sbi_type, uint64_t arg0, uint64_t arg1, uint64_t arg2) {
    uint64_t ret_val;
    __asm__ volatile (
ffffffffc0201964:	4781                	li	a5,0
ffffffffc0201966:	00004717          	auipc	a4,0x4
ffffffffc020196a:	6b273703          	ld	a4,1714(a4) # ffffffffc0206018 <SBI_CONSOLE_PUTCHAR>
ffffffffc020196e:	88ba                	mv	a7,a4
ffffffffc0201970:	852a                	mv	a0,a0
ffffffffc0201972:	85be                	mv	a1,a5
ffffffffc0201974:	863e                	mv	a2,a5
ffffffffc0201976:	00000073          	ecall
ffffffffc020197a:	87aa                	mv	a5,a0
    return ret_val;
}

void sbi_console_putchar(unsigned char ch) {
    sbi_call(SBI_CONSOLE_PUTCHAR, ch, 0, 0);
}
ffffffffc020197c:	8082                	ret

ffffffffc020197e <sbi_set_timer>:
    __asm__ volatile (
ffffffffc020197e:	4781                	li	a5,0
ffffffffc0201980:	00005717          	auipc	a4,0x5
ffffffffc0201984:	af873703          	ld	a4,-1288(a4) # ffffffffc0206478 <SBI_SET_TIMER>
ffffffffc0201988:	88ba                	mv	a7,a4
ffffffffc020198a:	852a                	mv	a0,a0
ffffffffc020198c:	85be                	mv	a1,a5
ffffffffc020198e:	863e                	mv	a2,a5
ffffffffc0201990:	00000073          	ecall
ffffffffc0201994:	87aa                	mv	a5,a0

void sbi_set_timer(unsigned long long stime_value) {
    sbi_call(SBI_SET_TIMER, stime_value, 0, 0);
}
ffffffffc0201996:	8082                	ret

ffffffffc0201998 <sbi_console_getchar>:
    __asm__ volatile (
ffffffffc0201998:	4501                	li	a0,0
ffffffffc020199a:	00004797          	auipc	a5,0x4
ffffffffc020199e:	6767b783          	ld	a5,1654(a5) # ffffffffc0206010 <SBI_CONSOLE_GETCHAR>
ffffffffc02019a2:	88be                	mv	a7,a5
ffffffffc02019a4:	852a                	mv	a0,a0
ffffffffc02019a6:	85aa                	mv	a1,a0
ffffffffc02019a8:	862a                	mv	a2,a0
ffffffffc02019aa:	00000073          	ecall
ffffffffc02019ae:	852a                	mv	a0,a0

int sbi_console_getchar(void) {
    return sbi_call(SBI_CONSOLE_GETCHAR, 0, 0, 0);
ffffffffc02019b0:	2501                	sext.w	a0,a0
ffffffffc02019b2:	8082                	ret

ffffffffc02019b4 <strnlen>:
 * @len if there is no '\0' character among the first @len characters
 * pointed by @s.
 * */
size_t
strnlen(const char *s, size_t len) {
    size_t cnt = 0;
ffffffffc02019b4:	4781                	li	a5,0
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019b6:	e589                	bnez	a1,ffffffffc02019c0 <strnlen+0xc>
ffffffffc02019b8:	a811                	j	ffffffffc02019cc <strnlen+0x18>
        cnt ++;
ffffffffc02019ba:	0785                	addi	a5,a5,1
    while (cnt < len && *s ++ != '\0') {
ffffffffc02019bc:	00f58863          	beq	a1,a5,ffffffffc02019cc <strnlen+0x18>
ffffffffc02019c0:	00f50733          	add	a4,a0,a5
ffffffffc02019c4:	00074703          	lbu	a4,0(a4)
ffffffffc02019c8:	fb6d                	bnez	a4,ffffffffc02019ba <strnlen+0x6>
ffffffffc02019ca:	85be                	mv	a1,a5
    }
    return cnt;
}
ffffffffc02019cc:	852e                	mv	a0,a1
ffffffffc02019ce:	8082                	ret

ffffffffc02019d0 <strcmp>:
int
strcmp(const char *s1, const char *s2) {
#ifdef __HAVE_ARCH_STRCMP
    return __strcmp(s1, s2);
#else
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019d0:	00054783          	lbu	a5,0(a0)
        s1 ++, s2 ++;
    }
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019d4:	0005c703          	lbu	a4,0(a1)
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019d8:	cb89                	beqz	a5,ffffffffc02019ea <strcmp+0x1a>
        s1 ++, s2 ++;
ffffffffc02019da:	0505                	addi	a0,a0,1
ffffffffc02019dc:	0585                	addi	a1,a1,1
    while (*s1 != '\0' && *s1 == *s2) {
ffffffffc02019de:	fee789e3          	beq	a5,a4,ffffffffc02019d0 <strcmp>
    return (int)((unsigned char)*s1 - (unsigned char)*s2);
ffffffffc02019e2:	0007851b          	sext.w	a0,a5
#endif /* __HAVE_ARCH_STRCMP */
}
ffffffffc02019e6:	9d19                	subw	a0,a0,a4
ffffffffc02019e8:	8082                	ret
ffffffffc02019ea:	4501                	li	a0,0
ffffffffc02019ec:	bfed                	j	ffffffffc02019e6 <strcmp+0x16>

ffffffffc02019ee <strchr>:
 * The strchr() function returns a pointer to the first occurrence of
 * character in @s. If the value is not found, the function returns 'NULL'.
 * */
char *
strchr(const char *s, char c) {
    while (*s != '\0') {
ffffffffc02019ee:	00054783          	lbu	a5,0(a0)
ffffffffc02019f2:	c799                	beqz	a5,ffffffffc0201a00 <strchr+0x12>
        if (*s == c) {
ffffffffc02019f4:	00f58763          	beq	a1,a5,ffffffffc0201a02 <strchr+0x14>
    while (*s != '\0') {
ffffffffc02019f8:	00154783          	lbu	a5,1(a0)
            return (char *)s;
        }
        s ++;
ffffffffc02019fc:	0505                	addi	a0,a0,1
    while (*s != '\0') {
ffffffffc02019fe:	fbfd                	bnez	a5,ffffffffc02019f4 <strchr+0x6>
    }
    return NULL;
ffffffffc0201a00:	4501                	li	a0,0
}
ffffffffc0201a02:	8082                	ret

ffffffffc0201a04 <memset>:
memset(void *s, char c, size_t n) {
#ifdef __HAVE_ARCH_MEMSET
    return __memset(s, c, n);
#else
    char *p = s;
    while (n -- > 0) {
ffffffffc0201a04:	ca01                	beqz	a2,ffffffffc0201a14 <memset+0x10>
ffffffffc0201a06:	962a                	add	a2,a2,a0
    char *p = s;
ffffffffc0201a08:	87aa                	mv	a5,a0
        *p ++ = c;
ffffffffc0201a0a:	0785                	addi	a5,a5,1
ffffffffc0201a0c:	feb78fa3          	sb	a1,-1(a5)
    while (n -- > 0) {
ffffffffc0201a10:	fec79de3          	bne	a5,a2,ffffffffc0201a0a <memset+0x6>
    }
    return s;
#endif /* __HAVE_ARCH_MEMSET */
}
ffffffffc0201a14:	8082                	ret
