
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
        # set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + ((hartid + 1) * 4096)
        la sp, stack0
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	29813103          	ld	sp,664(sp) # 8000a298 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
        csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
        # jump to start() in start.c
        call start
    80000016:	04e000ef          	jal	80000064 <start>

000000008000001a <spin>:
spin:
        j spin
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
}

// ask each hart to generate timer interrupts.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e406                	sd	ra,8(sp)
    80000020:	e022                	sd	s0,0(sp)
    80000022:	0800                	addi	s0,sp,16
#define MIE_STIE (1L << 5)  // supervisor timer
static inline uint64
r_mie()
{
  uint64 x;
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000024:	304027f3          	csrr	a5,mie
  // enable supervisor-mode timer interrupts.
  w_mie(r_mie() | MIE_STIE);
    80000028:	0207e793          	ori	a5,a5,32
}

static inline void 
w_mie(uint64 x)
{
  asm volatile("csrw mie, %0" : : "r" (x));
    8000002c:	30479073          	csrw	mie,a5
static inline uint64
r_menvcfg()
{
  uint64 x;
  // asm volatile("csrr %0, menvcfg" : "=r" (x) );
  asm volatile("csrr %0, 0x30a" : "=r" (x) );
    80000030:	30a027f3          	csrr	a5,0x30a
  
  // enable the sstc extension (i.e. stimecmp).
  w_menvcfg(r_menvcfg() | (1L << 63)); 
    80000034:	577d                	li	a4,-1
    80000036:	177e                	slli	a4,a4,0x3f
    80000038:	8fd9                	or	a5,a5,a4

static inline void 
w_menvcfg(uint64 x)
{
  // asm volatile("csrw menvcfg, %0" : : "r" (x));
  asm volatile("csrw 0x30a, %0" : : "r" (x));
    8000003a:	30a79073          	csrw	0x30a,a5

static inline uint64
r_mcounteren()
{
  uint64 x;
  asm volatile("csrr %0, mcounteren" : "=r" (x) );
    8000003e:	306027f3          	csrr	a5,mcounteren
  
  // allow supervisor to use stimecmp and time.
  w_mcounteren(r_mcounteren() | 2);
    80000042:	0027e793          	ori	a5,a5,2
  asm volatile("csrw mcounteren, %0" : : "r" (x));
    80000046:	30679073          	csrw	mcounteren,a5
// machine-mode cycle counter
static inline uint64
r_time()
{
  uint64 x;
  asm volatile("csrr %0, time" : "=r" (x) );
    8000004a:	c01027f3          	rdtime	a5
  
  // ask for the very first timer interrupt.
  w_stimecmp(r_time() + 1000000);
    8000004e:	000f4737          	lui	a4,0xf4
    80000052:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000056:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80000058:	14d79073          	csrw	stimecmp,a5
}
    8000005c:	60a2                	ld	ra,8(sp)
    8000005e:	6402                	ld	s0,0(sp)
    80000060:	0141                	addi	sp,sp,16
    80000062:	8082                	ret

0000000080000064 <start>:
{
    80000064:	1141                	addi	sp,sp,-16
    80000066:	e406                	sd	ra,8(sp)
    80000068:	e022                	sd	s0,0(sp)
    8000006a:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006c:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000070:	7779                	lui	a4,0xffffe
    80000072:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdb217>
    80000076:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    80000078:	6705                	lui	a4,0x1
    8000007a:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    8000007e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000080:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    80000084:	00001797          	auipc	a5,0x1
    80000088:	dce78793          	addi	a5,a5,-562 # 80000e52 <main>
    8000008c:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    80000090:	4781                	li	a5,0
    80000092:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    80000096:	67c1                	lui	a5,0x10
    80000098:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    8000009a:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    8000009e:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000a2:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE);
    800000a6:	2207e793          	ori	a5,a5,544
  asm volatile("csrw sie, %0" : : "r" (x));
    800000aa:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000ae:	57fd                	li	a5,-1
    800000b0:	83a9                	srli	a5,a5,0xa
    800000b2:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000b6:	47bd                	li	a5,15
    800000b8:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000bc:	f61ff0ef          	jal	8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000c0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000c4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000c6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000c8:	30200073          	mret
}
    800000cc:	60a2                	ld	ra,8(sp)
    800000ce:	6402                	ld	s0,0(sp)
    800000d0:	0141                	addi	sp,sp,16
    800000d2:	8082                	ret

00000000800000d4 <consolewrite>:
// user write() system calls to the console go here.
// uses sleep() and UART interrupts.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000d4:	7119                	addi	sp,sp,-128
    800000d6:	fc86                	sd	ra,120(sp)
    800000d8:	f8a2                	sd	s0,112(sp)
    800000da:	f4a6                	sd	s1,104(sp)
    800000dc:	0100                	addi	s0,sp,128
  char buf[32]; // move batches from user space to uart.
  int i = 0;

  while(i < n){
    800000de:	06c05b63          	blez	a2,80000154 <consolewrite+0x80>
    800000e2:	f0ca                	sd	s2,96(sp)
    800000e4:	ecce                	sd	s3,88(sp)
    800000e6:	e8d2                	sd	s4,80(sp)
    800000e8:	e4d6                	sd	s5,72(sp)
    800000ea:	e0da                	sd	s6,64(sp)
    800000ec:	fc5e                	sd	s7,56(sp)
    800000ee:	f862                	sd	s8,48(sp)
    800000f0:	f466                	sd	s9,40(sp)
    800000f2:	f06a                	sd	s10,32(sp)
    800000f4:	8b2a                	mv	s6,a0
    800000f6:	8bae                	mv	s7,a1
    800000f8:	8a32                	mv	s4,a2
  int i = 0;
    800000fa:	4481                	li	s1,0
    int nn = sizeof(buf);
    if(nn > n - i)
    800000fc:	02000c93          	li	s9,32
    80000100:	02000d13          	li	s10,32
      nn = n - i;
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000104:	f8040a93          	addi	s5,s0,-128
    80000108:	5c7d                	li	s8,-1
    8000010a:	a025                	j	80000132 <consolewrite+0x5e>
    if(nn > n - i)
    8000010c:	0009099b          	sext.w	s3,s2
    if(either_copyin(buf, user_src, src+i, nn) == -1)
    80000110:	86ce                	mv	a3,s3
    80000112:	01748633          	add	a2,s1,s7
    80000116:	85da                	mv	a1,s6
    80000118:	8556                	mv	a0,s5
    8000011a:	14e020ef          	jal	80002268 <either_copyin>
    8000011e:	03850d63          	beq	a0,s8,80000158 <consolewrite+0x84>
      break;
    uartwrite(buf, nn);
    80000122:	85ce                	mv	a1,s3
    80000124:	8556                	mv	a0,s5
    80000126:	76e000ef          	jal	80000894 <uartwrite>
    i += nn;
    8000012a:	009904bb          	addw	s1,s2,s1
  while(i < n){
    8000012e:	0144d963          	bge	s1,s4,80000140 <consolewrite+0x6c>
    if(nn > n - i)
    80000132:	409a07bb          	subw	a5,s4,s1
    80000136:	893e                	mv	s2,a5
    80000138:	fcfcdae3          	bge	s9,a5,8000010c <consolewrite+0x38>
    8000013c:	896a                	mv	s2,s10
    8000013e:	b7f9                	j	8000010c <consolewrite+0x38>
    80000140:	7906                	ld	s2,96(sp)
    80000142:	69e6                	ld	s3,88(sp)
    80000144:	6a46                	ld	s4,80(sp)
    80000146:	6aa6                	ld	s5,72(sp)
    80000148:	6b06                	ld	s6,64(sp)
    8000014a:	7be2                	ld	s7,56(sp)
    8000014c:	7c42                	ld	s8,48(sp)
    8000014e:	7ca2                	ld	s9,40(sp)
    80000150:	7d02                	ld	s10,32(sp)
    80000152:	a821                	j	8000016a <consolewrite+0x96>
  int i = 0;
    80000154:	4481                	li	s1,0
    80000156:	a811                	j	8000016a <consolewrite+0x96>
    80000158:	7906                	ld	s2,96(sp)
    8000015a:	69e6                	ld	s3,88(sp)
    8000015c:	6a46                	ld	s4,80(sp)
    8000015e:	6aa6                	ld	s5,72(sp)
    80000160:	6b06                	ld	s6,64(sp)
    80000162:	7be2                	ld	s7,56(sp)
    80000164:	7c42                	ld	s8,48(sp)
    80000166:	7ca2                	ld	s9,40(sp)
    80000168:	7d02                	ld	s10,32(sp)
  }

  return i;
}
    8000016a:	8526                	mv	a0,s1
    8000016c:	70e6                	ld	ra,120(sp)
    8000016e:	7446                	ld	s0,112(sp)
    80000170:	74a6                	ld	s1,104(sp)
    80000172:	6109                	addi	sp,sp,128
    80000174:	8082                	ret

0000000080000176 <consoleread>:
// user_dst indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	711d                	addi	sp,sp,-96
    80000178:	ec86                	sd	ra,88(sp)
    8000017a:	e8a2                	sd	s0,80(sp)
    8000017c:	e4a6                	sd	s1,72(sp)
    8000017e:	e0ca                	sd	s2,64(sp)
    80000180:	fc4e                	sd	s3,56(sp)
    80000182:	f852                	sd	s4,48(sp)
    80000184:	f456                	sd	s5,40(sp)
    80000186:	f05a                	sd	s6,32(sp)
    80000188:	1080                	addi	s0,sp,96
    8000018a:	8aaa                	mv	s5,a0
    8000018c:	8a2e                	mv	s4,a1
    8000018e:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000190:	8b32                	mv	s6,a2
  acquire(&cons.lock);
    80000192:	00012517          	auipc	a0,0x12
    80000196:	14e50513          	addi	a0,a0,334 # 800122e0 <cons>
    8000019a:	233000ef          	jal	80000bcc <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019e:	00012497          	auipc	s1,0x12
    800001a2:	14248493          	addi	s1,s1,322 # 800122e0 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a6:	00012917          	auipc	s2,0x12
    800001aa:	1d290913          	addi	s2,s2,466 # 80012378 <cons+0x98>
  while(n > 0){
    800001ae:	0b305b63          	blez	s3,80000264 <consoleread+0xee>
    while(cons.r == cons.w){
    800001b2:	0984a783          	lw	a5,152(s1)
    800001b6:	09c4a703          	lw	a4,156(s1)
    800001ba:	0af71063          	bne	a4,a5,8000025a <consoleread+0xe4>
      if(killed(myproc())){
    800001be:	700010ef          	jal	800018be <myproc>
    800001c2:	73f010ef          	jal	80002100 <killed>
    800001c6:	e12d                	bnez	a0,80000228 <consoleread+0xb2>
      sleep(&cons.r, &cons.lock);
    800001c8:	85a6                	mv	a1,s1
    800001ca:	854a                	mv	a0,s2
    800001cc:	4fd010ef          	jal	80001ec8 <sleep>
    while(cons.r == cons.w){
    800001d0:	0984a783          	lw	a5,152(s1)
    800001d4:	09c4a703          	lw	a4,156(s1)
    800001d8:	fef703e3          	beq	a4,a5,800001be <consoleread+0x48>
    800001dc:	ec5e                	sd	s7,24(sp)
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001de:	00012717          	auipc	a4,0x12
    800001e2:	10270713          	addi	a4,a4,258 # 800122e0 <cons>
    800001e6:	0017869b          	addiw	a3,a5,1
    800001ea:	08d72c23          	sw	a3,152(a4)
    800001ee:	07f7f693          	andi	a3,a5,127
    800001f2:	9736                	add	a4,a4,a3
    800001f4:	01874703          	lbu	a4,24(a4)
    800001f8:	00070b9b          	sext.w	s7,a4

    if(c == C('D')){  // end-of-file
    800001fc:	4691                	li	a3,4
    800001fe:	04db8663          	beq	s7,a3,8000024a <consoleread+0xd4>
      }
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    80000202:	fae407a3          	sb	a4,-81(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	faf40613          	addi	a2,s0,-81
    8000020c:	85d2                	mv	a1,s4
    8000020e:	8556                	mv	a0,s5
    80000210:	00e020ef          	jal	8000221e <either_copyout>
    80000214:	57fd                	li	a5,-1
    80000216:	04f50663          	beq	a0,a5,80000262 <consoleread+0xec>
      break;

    dst++;
    8000021a:	0a05                	addi	s4,s4,1
    --n;
    8000021c:	39fd                	addiw	s3,s3,-1

    if(c == '\n'){
    8000021e:	47a9                	li	a5,10
    80000220:	04fb8b63          	beq	s7,a5,80000276 <consoleread+0x100>
    80000224:	6be2                	ld	s7,24(sp)
    80000226:	b761                	j	800001ae <consoleread+0x38>
        release(&cons.lock);
    80000228:	00012517          	auipc	a0,0x12
    8000022c:	0b850513          	addi	a0,a0,184 # 800122e0 <cons>
    80000230:	231000ef          	jal	80000c60 <release>
        return -1;
    80000234:	557d                	li	a0,-1
    }
  }
  release(&cons.lock);

  return target - n;
}
    80000236:	60e6                	ld	ra,88(sp)
    80000238:	6446                	ld	s0,80(sp)
    8000023a:	64a6                	ld	s1,72(sp)
    8000023c:	6906                	ld	s2,64(sp)
    8000023e:	79e2                	ld	s3,56(sp)
    80000240:	7a42                	ld	s4,48(sp)
    80000242:	7aa2                	ld	s5,40(sp)
    80000244:	7b02                	ld	s6,32(sp)
    80000246:	6125                	addi	sp,sp,96
    80000248:	8082                	ret
      if(n < target){
    8000024a:	0169fa63          	bgeu	s3,s6,8000025e <consoleread+0xe8>
        cons.r--;
    8000024e:	00012717          	auipc	a4,0x12
    80000252:	12f72523          	sw	a5,298(a4) # 80012378 <cons+0x98>
    80000256:	6be2                	ld	s7,24(sp)
    80000258:	a031                	j	80000264 <consoleread+0xee>
    8000025a:	ec5e                	sd	s7,24(sp)
    8000025c:	b749                	j	800001de <consoleread+0x68>
    8000025e:	6be2                	ld	s7,24(sp)
    80000260:	a011                	j	80000264 <consoleread+0xee>
    80000262:	6be2                	ld	s7,24(sp)
  release(&cons.lock);
    80000264:	00012517          	auipc	a0,0x12
    80000268:	07c50513          	addi	a0,a0,124 # 800122e0 <cons>
    8000026c:	1f5000ef          	jal	80000c60 <release>
  return target - n;
    80000270:	413b053b          	subw	a0,s6,s3
    80000274:	b7c9                	j	80000236 <consoleread+0xc0>
    80000276:	6be2                	ld	s7,24(sp)
    80000278:	b7f5                	j	80000264 <consoleread+0xee>

000000008000027a <consputc>:
{
    8000027a:	1141                	addi	sp,sp,-16
    8000027c:	e406                	sd	ra,8(sp)
    8000027e:	e022                	sd	s0,0(sp)
    80000280:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000282:	10000793          	li	a5,256
    80000286:	00f50863          	beq	a0,a5,80000296 <consputc+0x1c>
    uartputc_sync(c);
    8000028a:	69e000ef          	jal	80000928 <uartputc_sync>
}
    8000028e:	60a2                	ld	ra,8(sp)
    80000290:	6402                	ld	s0,0(sp)
    80000292:	0141                	addi	sp,sp,16
    80000294:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    80000296:	4521                	li	a0,8
    80000298:	690000ef          	jal	80000928 <uartputc_sync>
    8000029c:	02000513          	li	a0,32
    800002a0:	688000ef          	jal	80000928 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	682000ef          	jal	80000928 <uartputc_sync>
    800002aa:	b7d5                	j	8000028e <consputc+0x14>

00000000800002ac <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002ac:	7179                	addi	sp,sp,-48
    800002ae:	f406                	sd	ra,40(sp)
    800002b0:	f022                	sd	s0,32(sp)
    800002b2:	ec26                	sd	s1,24(sp)
    800002b4:	1800                	addi	s0,sp,48
    800002b6:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002b8:	00012517          	auipc	a0,0x12
    800002bc:	02850513          	addi	a0,a0,40 # 800122e0 <cons>
    800002c0:	10d000ef          	jal	80000bcc <acquire>

  switch(c){
    800002c4:	47d5                	li	a5,21
    800002c6:	08f48e63          	beq	s1,a5,80000362 <consoleintr+0xb6>
    800002ca:	0297c563          	blt	a5,s1,800002f4 <consoleintr+0x48>
    800002ce:	47a1                	li	a5,8
    800002d0:	0ef48863          	beq	s1,a5,800003c0 <consoleintr+0x114>
    800002d4:	47c1                	li	a5,16
    800002d6:	10f49963          	bne	s1,a5,800003e8 <consoleintr+0x13c>
  case C('P'):  // Print process list.
    procdump();
    800002da:	7d9010ef          	jal	800022b2 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002de:	00012517          	auipc	a0,0x12
    800002e2:	00250513          	addi	a0,a0,2 # 800122e0 <cons>
    800002e6:	17b000ef          	jal	80000c60 <release>
}
    800002ea:	70a2                	ld	ra,40(sp)
    800002ec:	7402                	ld	s0,32(sp)
    800002ee:	64e2                	ld	s1,24(sp)
    800002f0:	6145                	addi	sp,sp,48
    800002f2:	8082                	ret
  switch(c){
    800002f4:	07f00793          	li	a5,127
    800002f8:	0cf48463          	beq	s1,a5,800003c0 <consoleintr+0x114>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800002fc:	00012717          	auipc	a4,0x12
    80000300:	fe470713          	addi	a4,a4,-28 # 800122e0 <cons>
    80000304:	0a072783          	lw	a5,160(a4)
    80000308:	09872703          	lw	a4,152(a4)
    8000030c:	9f99                	subw	a5,a5,a4
    8000030e:	07f00713          	li	a4,127
    80000312:	fcf766e3          	bltu	a4,a5,800002de <consoleintr+0x32>
      c = (c == '\r') ? '\n' : c;
    80000316:	47b5                	li	a5,13
    80000318:	0cf48b63          	beq	s1,a5,800003ee <consoleintr+0x142>
      consputc(c);
    8000031c:	8526                	mv	a0,s1
    8000031e:	f5dff0ef          	jal	8000027a <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000322:	00012797          	auipc	a5,0x12
    80000326:	fbe78793          	addi	a5,a5,-66 # 800122e0 <cons>
    8000032a:	0a07a683          	lw	a3,160(a5)
    8000032e:	0016871b          	addiw	a4,a3,1
    80000332:	863a                	mv	a2,a4
    80000334:	0ae7a023          	sw	a4,160(a5)
    80000338:	07f6f693          	andi	a3,a3,127
    8000033c:	97b6                	add	a5,a5,a3
    8000033e:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000342:	47a9                	li	a5,10
    80000344:	0cf48963          	beq	s1,a5,80000416 <consoleintr+0x16a>
    80000348:	4791                	li	a5,4
    8000034a:	0cf48663          	beq	s1,a5,80000416 <consoleintr+0x16a>
    8000034e:	00012797          	auipc	a5,0x12
    80000352:	02a7a783          	lw	a5,42(a5) # 80012378 <cons+0x98>
    80000356:	9f1d                	subw	a4,a4,a5
    80000358:	08000793          	li	a5,128
    8000035c:	f8f711e3          	bne	a4,a5,800002de <consoleintr+0x32>
    80000360:	a85d                	j	80000416 <consoleintr+0x16a>
    80000362:	e84a                	sd	s2,16(sp)
    80000364:	e44e                	sd	s3,8(sp)
    while(cons.e != cons.w &&
    80000366:	00012717          	auipc	a4,0x12
    8000036a:	f7a70713          	addi	a4,a4,-134 # 800122e0 <cons>
    8000036e:	0a072783          	lw	a5,160(a4)
    80000372:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000376:	00012497          	auipc	s1,0x12
    8000037a:	f6a48493          	addi	s1,s1,-150 # 800122e0 <cons>
    while(cons.e != cons.w &&
    8000037e:	4929                	li	s2,10
      consputc(BACKSPACE);
    80000380:	10000993          	li	s3,256
    while(cons.e != cons.w &&
    80000384:	02f70863          	beq	a4,a5,800003b4 <consoleintr+0x108>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    80000388:	37fd                	addiw	a5,a5,-1
    8000038a:	07f7f713          	andi	a4,a5,127
    8000038e:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    80000390:	01874703          	lbu	a4,24(a4)
    80000394:	03270363          	beq	a4,s2,800003ba <consoleintr+0x10e>
      cons.e--;
    80000398:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    8000039c:	854e                	mv	a0,s3
    8000039e:	eddff0ef          	jal	8000027a <consputc>
    while(cons.e != cons.w &&
    800003a2:	0a04a783          	lw	a5,160(s1)
    800003a6:	09c4a703          	lw	a4,156(s1)
    800003aa:	fcf71fe3          	bne	a4,a5,80000388 <consoleintr+0xdc>
    800003ae:	6942                	ld	s2,16(sp)
    800003b0:	69a2                	ld	s3,8(sp)
    800003b2:	b735                	j	800002de <consoleintr+0x32>
    800003b4:	6942                	ld	s2,16(sp)
    800003b6:	69a2                	ld	s3,8(sp)
    800003b8:	b71d                	j	800002de <consoleintr+0x32>
    800003ba:	6942                	ld	s2,16(sp)
    800003bc:	69a2                	ld	s3,8(sp)
    800003be:	b705                	j	800002de <consoleintr+0x32>
    if(cons.e != cons.w){
    800003c0:	00012717          	auipc	a4,0x12
    800003c4:	f2070713          	addi	a4,a4,-224 # 800122e0 <cons>
    800003c8:	0a072783          	lw	a5,160(a4)
    800003cc:	09c72703          	lw	a4,156(a4)
    800003d0:	f0f707e3          	beq	a4,a5,800002de <consoleintr+0x32>
      cons.e--;
    800003d4:	37fd                	addiw	a5,a5,-1
    800003d6:	00012717          	auipc	a4,0x12
    800003da:	faf72523          	sw	a5,-86(a4) # 80012380 <cons+0xa0>
      consputc(BACKSPACE);
    800003de:	10000513          	li	a0,256
    800003e2:	e99ff0ef          	jal	8000027a <consputc>
    800003e6:	bde5                	j	800002de <consoleintr+0x32>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    800003e8:	ee048be3          	beqz	s1,800002de <consoleintr+0x32>
    800003ec:	bf01                	j	800002fc <consoleintr+0x50>
      consputc(c);
    800003ee:	4529                	li	a0,10
    800003f0:	e8bff0ef          	jal	8000027a <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    800003f4:	00012797          	auipc	a5,0x12
    800003f8:	eec78793          	addi	a5,a5,-276 # 800122e0 <cons>
    800003fc:	0a07a703          	lw	a4,160(a5)
    80000400:	0017069b          	addiw	a3,a4,1
    80000404:	8636                	mv	a2,a3
    80000406:	0ad7a023          	sw	a3,160(a5)
    8000040a:	07f77713          	andi	a4,a4,127
    8000040e:	97ba                	add	a5,a5,a4
    80000410:	4729                	li	a4,10
    80000412:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000416:	00012797          	auipc	a5,0x12
    8000041a:	f6c7a323          	sw	a2,-154(a5) # 8001237c <cons+0x9c>
        wakeup(&cons.r);
    8000041e:	00012517          	auipc	a0,0x12
    80000422:	f5a50513          	addi	a0,a0,-166 # 80012378 <cons+0x98>
    80000426:	2ef010ef          	jal	80001f14 <wakeup>
    8000042a:	bd55                	j	800002de <consoleintr+0x32>

000000008000042c <consoleinit>:

void
consoleinit(void)
{
    8000042c:	1141                	addi	sp,sp,-16
    8000042e:	e406                	sd	ra,8(sp)
    80000430:	e022                	sd	s0,0(sp)
    80000432:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000434:	00007597          	auipc	a1,0x7
    80000438:	bcc58593          	addi	a1,a1,-1076 # 80007000 <etext>
    8000043c:	00012517          	auipc	a0,0x12
    80000440:	ea450513          	addi	a0,a0,-348 # 800122e0 <cons>
    80000444:	704000ef          	jal	80000b48 <initlock>

  uartinit();
    80000448:	3f6000ef          	jal	8000083e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000044c:	00022797          	auipc	a5,0x22
    80000450:	00478793          	addi	a5,a5,4 # 80022450 <devsw>
    80000454:	00000717          	auipc	a4,0x0
    80000458:	d2270713          	addi	a4,a4,-734 # 80000176 <consoleread>
    8000045c:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000045e:	00000717          	auipc	a4,0x0
    80000462:	c7670713          	addi	a4,a4,-906 # 800000d4 <consolewrite>
    80000466:	ef98                	sd	a4,24(a5)
}
    80000468:	60a2                	ld	ra,8(sp)
    8000046a:	6402                	ld	s0,0(sp)
    8000046c:	0141                	addi	sp,sp,16
    8000046e:	8082                	ret

0000000080000470 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(long long xx, int base, int sign)
{
    80000470:	7139                	addi	sp,sp,-64
    80000472:	fc06                	sd	ra,56(sp)
    80000474:	f822                	sd	s0,48(sp)
    80000476:	f426                	sd	s1,40(sp)
    80000478:	f04a                	sd	s2,32(sp)
    8000047a:	0080                	addi	s0,sp,64
  char buf[20];
  int i;
  unsigned long long x;

  if(sign && (sign = (xx < 0)))
    8000047c:	c219                	beqz	a2,80000482 <printint+0x12>
    8000047e:	06054a63          	bltz	a0,800004f2 <printint+0x82>
    x = -xx;
  else
    x = xx;
    80000482:	4e01                	li	t3,0

  i = 0;
    80000484:	fc840313          	addi	t1,s0,-56
    x = xx;
    80000488:	869a                	mv	a3,t1
  i = 0;
    8000048a:	4781                	li	a5,0
  do {
    buf[i++] = digits[x % base];
    8000048c:	00007817          	auipc	a6,0x7
    80000490:	28480813          	addi	a6,a6,644 # 80007710 <digits>
    80000494:	88be                	mv	a7,a5
    80000496:	0017861b          	addiw	a2,a5,1
    8000049a:	87b2                	mv	a5,a2
    8000049c:	02b57733          	remu	a4,a0,a1
    800004a0:	9742                	add	a4,a4,a6
    800004a2:	00074703          	lbu	a4,0(a4)
    800004a6:	00e68023          	sb	a4,0(a3)
  } while((x /= base) != 0);
    800004aa:	872a                	mv	a4,a0
    800004ac:	02b55533          	divu	a0,a0,a1
    800004b0:	0685                	addi	a3,a3,1
    800004b2:	feb771e3          	bgeu	a4,a1,80000494 <printint+0x24>

  if(sign)
    800004b6:	000e0c63          	beqz	t3,800004ce <printint+0x5e>
    buf[i++] = '-';
    800004ba:	fe060793          	addi	a5,a2,-32
    800004be:	00878633          	add	a2,a5,s0
    800004c2:	02d00793          	li	a5,45
    800004c6:	fef60423          	sb	a5,-24(a2)
    800004ca:	0028879b          	addiw	a5,a7,2

  while(--i >= 0)
    800004ce:	fff7891b          	addiw	s2,a5,-1
    800004d2:	006784b3          	add	s1,a5,t1
    consputc(buf[i]);
    800004d6:	fff4c503          	lbu	a0,-1(s1)
    800004da:	da1ff0ef          	jal	8000027a <consputc>
  while(--i >= 0)
    800004de:	397d                	addiw	s2,s2,-1
    800004e0:	14fd                	addi	s1,s1,-1
    800004e2:	fe095ae3          	bgez	s2,800004d6 <printint+0x66>
}
    800004e6:	70e2                	ld	ra,56(sp)
    800004e8:	7442                	ld	s0,48(sp)
    800004ea:	74a2                	ld	s1,40(sp)
    800004ec:	7902                	ld	s2,32(sp)
    800004ee:	6121                	addi	sp,sp,64
    800004f0:	8082                	ret
    x = -xx;
    800004f2:	40a00533          	neg	a0,a0
  if(sign && (sign = (xx < 0)))
    800004f6:	4e05                	li	t3,1
    x = -xx;
    800004f8:	b771                	j	80000484 <printint+0x14>

00000000800004fa <printf>:
}

// Print to the console.
int
printf(char *fmt, ...)
{
    800004fa:	7131                	addi	sp,sp,-192
    800004fc:	fc86                	sd	ra,120(sp)
    800004fe:	f8a2                	sd	s0,112(sp)
    80000500:	e8d2                	sd	s4,80(sp)
    80000502:	0100                	addi	s0,sp,128
    80000504:	8a2a                	mv	s4,a0
    80000506:	e40c                	sd	a1,8(s0)
    80000508:	e810                	sd	a2,16(s0)
    8000050a:	ec14                	sd	a3,24(s0)
    8000050c:	f018                	sd	a4,32(s0)
    8000050e:	f41c                	sd	a5,40(s0)
    80000510:	03043823          	sd	a6,48(s0)
    80000514:	03143c23          	sd	a7,56(s0)
  va_list ap;
  int i, cx, c0, c1, c2;
  char *s;

  if(panicking == 0)
    80000518:	0000a797          	auipc	a5,0xa
    8000051c:	d9c7a783          	lw	a5,-612(a5) # 8000a2b4 <panicking>
    80000520:	c3a1                	beqz	a5,80000560 <printf+0x66>
    acquire(&pr.lock);

  va_start(ap, fmt);
    80000522:	00840793          	addi	a5,s0,8
    80000526:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    8000052a:	000a4503          	lbu	a0,0(s4)
    8000052e:	28050663          	beqz	a0,800007ba <printf+0x2c0>
    80000532:	f4a6                	sd	s1,104(sp)
    80000534:	f0ca                	sd	s2,96(sp)
    80000536:	ecce                	sd	s3,88(sp)
    80000538:	e4d6                	sd	s5,72(sp)
    8000053a:	e0da                	sd	s6,64(sp)
    8000053c:	f862                	sd	s8,48(sp)
    8000053e:	f466                	sd	s9,40(sp)
    80000540:	f06a                	sd	s10,32(sp)
    80000542:	ec6e                	sd	s11,24(sp)
    80000544:	4901                	li	s2,0
    if(cx != '%'){
    80000546:	02500a93          	li	s5,37
    i++;
    c0 = fmt[i+0] & 0xff;
    c1 = c2 = 0;
    if(c0) c1 = fmt[i+1] & 0xff;
    if(c1) c2 = fmt[i+2] & 0xff;
    if(c0 == 'd'){
    8000054a:	06400b13          	li	s6,100
      printint(va_arg(ap, int), 10, 1);
    } else if(c0 == 'l' && c1 == 'd'){
    8000054e:	06c00c13          	li	s8,108
      printint(va_arg(ap, uint64), 10, 1);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
      printint(va_arg(ap, uint64), 10, 1);
      i += 2;
    } else if(c0 == 'u'){
    80000552:	07500c93          	li	s9,117
      printint(va_arg(ap, uint64), 10, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
      printint(va_arg(ap, uint64), 10, 0);
      i += 2;
    } else if(c0 == 'x'){
    80000556:	07800d13          	li	s10,120
      printint(va_arg(ap, uint64), 16, 0);
      i += 1;
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
      printint(va_arg(ap, uint64), 16, 0);
      i += 2;
    } else if(c0 == 'p'){
    8000055a:	07000d93          	li	s11,112
    8000055e:	a015                	j	80000582 <printf+0x88>
    acquire(&pr.lock);
    80000560:	00012517          	auipc	a0,0x12
    80000564:	e2850513          	addi	a0,a0,-472 # 80012388 <pr>
    80000568:	664000ef          	jal	80000bcc <acquire>
    8000056c:	bf5d                	j	80000522 <printf+0x28>
      consputc(cx);
    8000056e:	d0dff0ef          	jal	8000027a <consputc>
      continue;
    80000572:	84ca                	mv	s1,s2
  for(i = 0; (cx = fmt[i] & 0xff) != 0; i++){
    80000574:	2485                	addiw	s1,s1,1
    80000576:	8926                	mv	s2,s1
    80000578:	94d2                	add	s1,s1,s4
    8000057a:	0004c503          	lbu	a0,0(s1)
    8000057e:	20050b63          	beqz	a0,80000794 <printf+0x29a>
    if(cx != '%'){
    80000582:	ff5516e3          	bne	a0,s5,8000056e <printf+0x74>
    i++;
    80000586:	0019079b          	addiw	a5,s2,1
    8000058a:	84be                	mv	s1,a5
    c0 = fmt[i+0] & 0xff;
    8000058c:	00fa0733          	add	a4,s4,a5
    80000590:	00074983          	lbu	s3,0(a4)
    if(c0) c1 = fmt[i+1] & 0xff;
    80000594:	20098a63          	beqz	s3,800007a8 <printf+0x2ae>
    80000598:	00174703          	lbu	a4,1(a4)
    c1 = c2 = 0;
    8000059c:	86ba                	mv	a3,a4
    if(c1) c2 = fmt[i+2] & 0xff;
    8000059e:	c701                	beqz	a4,800005a6 <printf+0xac>
    800005a0:	97d2                	add	a5,a5,s4
    800005a2:	0027c683          	lbu	a3,2(a5)
    if(c0 == 'd'){
    800005a6:	03698963          	beq	s3,s6,800005d8 <printf+0xde>
    } else if(c0 == 'l' && c1 == 'd'){
    800005aa:	05898363          	beq	s3,s8,800005f0 <printf+0xf6>
    } else if(c0 == 'u'){
    800005ae:	0d998663          	beq	s3,s9,8000067a <printf+0x180>
    } else if(c0 == 'x'){
    800005b2:	11a98d63          	beq	s3,s10,800006cc <printf+0x1d2>
    } else if(c0 == 'p'){
    800005b6:	15b98663          	beq	s3,s11,80000702 <printf+0x208>
      printptr(va_arg(ap, uint64));
    } else if(c0 == 'c'){
    800005ba:	06300793          	li	a5,99
    800005be:	18f98563          	beq	s3,a5,80000748 <printf+0x24e>
      consputc(va_arg(ap, uint));
    } else if(c0 == 's'){
    800005c2:	07300793          	li	a5,115
    800005c6:	18f98b63          	beq	s3,a5,8000075c <printf+0x262>
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s; s++)
        consputc(*s);
    } else if(c0 == '%'){
    800005ca:	03599b63          	bne	s3,s5,80000600 <printf+0x106>
      consputc('%');
    800005ce:	02500513          	li	a0,37
    800005d2:	ca9ff0ef          	jal	8000027a <consputc>
    800005d6:	bf79                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, int), 10, 1);
    800005d8:	f8843783          	ld	a5,-120(s0)
    800005dc:	00878713          	addi	a4,a5,8
    800005e0:	f8e43423          	sd	a4,-120(s0)
    800005e4:	4605                	li	a2,1
    800005e6:	45a9                	li	a1,10
    800005e8:	4388                	lw	a0,0(a5)
    800005ea:	e87ff0ef          	jal	80000470 <printint>
    800005ee:	b759                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'd'){
    800005f0:	01670f63          	beq	a4,s6,8000060e <printf+0x114>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    800005f4:	03870b63          	beq	a4,s8,8000062a <printf+0x130>
    } else if(c0 == 'l' && c1 == 'u'){
    800005f8:	09970e63          	beq	a4,s9,80000694 <printf+0x19a>
    } else if(c0 == 'l' && c1 == 'x'){
    800005fc:	0fa70563          	beq	a4,s10,800006e6 <printf+0x1ec>
    } else if(c0 == 0){
      break;
    } else {
      // Print unknown % sequence to draw attention.
      consputc('%');
    80000600:	8556                	mv	a0,s5
    80000602:	c79ff0ef          	jal	8000027a <consputc>
      consputc(c0);
    80000606:	854e                	mv	a0,s3
    80000608:	c73ff0ef          	jal	8000027a <consputc>
    8000060c:	b7a5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    8000060e:	f8843783          	ld	a5,-120(s0)
    80000612:	00878713          	addi	a4,a5,8
    80000616:	f8e43423          	sd	a4,-120(s0)
    8000061a:	4605                	li	a2,1
    8000061c:	45a9                	li	a1,10
    8000061e:	6388                	ld	a0,0(a5)
    80000620:	e51ff0ef          	jal	80000470 <printint>
      i += 1;
    80000624:	0029049b          	addiw	s1,s2,2
    80000628:	b7b1                	j	80000574 <printf+0x7a>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'd'){
    8000062a:	06400793          	li	a5,100
    8000062e:	02f68863          	beq	a3,a5,8000065e <printf+0x164>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'u'){
    80000632:	07500793          	li	a5,117
    80000636:	06f68d63          	beq	a3,a5,800006b0 <printf+0x1b6>
    } else if(c0 == 'l' && c1 == 'l' && c2 == 'x'){
    8000063a:	07800793          	li	a5,120
    8000063e:	fcf691e3          	bne	a3,a5,80000600 <printf+0x106>
      printint(va_arg(ap, uint64), 16, 0);
    80000642:	f8843783          	ld	a5,-120(s0)
    80000646:	00878713          	addi	a4,a5,8
    8000064a:	f8e43423          	sd	a4,-120(s0)
    8000064e:	4601                	li	a2,0
    80000650:	45c1                	li	a1,16
    80000652:	6388                	ld	a0,0(a5)
    80000654:	e1dff0ef          	jal	80000470 <printint>
      i += 2;
    80000658:	0039049b          	addiw	s1,s2,3
    8000065c:	bf21                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	45a9                	li	a1,10
    8000066e:	6388                	ld	a0,0(a5)
    80000670:	e01ff0ef          	jal	80000470 <printint>
      i += 2;
    80000674:	0039049b          	addiw	s1,s2,3
    80000678:	bdf5                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 10, 0);
    8000067a:	f8843783          	ld	a5,-120(s0)
    8000067e:	00878713          	addi	a4,a5,8
    80000682:	f8e43423          	sd	a4,-120(s0)
    80000686:	4601                	li	a2,0
    80000688:	45a9                	li	a1,10
    8000068a:	0007e503          	lwu	a0,0(a5)
    8000068e:	de3ff0ef          	jal	80000470 <printint>
    80000692:	b5cd                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    80000694:	f8843783          	ld	a5,-120(s0)
    80000698:	00878713          	addi	a4,a5,8
    8000069c:	f8e43423          	sd	a4,-120(s0)
    800006a0:	4601                	li	a2,0
    800006a2:	45a9                	li	a1,10
    800006a4:	6388                	ld	a0,0(a5)
    800006a6:	dcbff0ef          	jal	80000470 <printint>
      i += 1;
    800006aa:	0029049b          	addiw	s1,s2,2
    800006ae:	b5d9                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 10, 0);
    800006b0:	f8843783          	ld	a5,-120(s0)
    800006b4:	00878713          	addi	a4,a5,8
    800006b8:	f8e43423          	sd	a4,-120(s0)
    800006bc:	4601                	li	a2,0
    800006be:	45a9                	li	a1,10
    800006c0:	6388                	ld	a0,0(a5)
    800006c2:	dafff0ef          	jal	80000470 <printint>
      i += 2;
    800006c6:	0039049b          	addiw	s1,s2,3
    800006ca:	b56d                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint32), 16, 0);
    800006cc:	f8843783          	ld	a5,-120(s0)
    800006d0:	00878713          	addi	a4,a5,8
    800006d4:	f8e43423          	sd	a4,-120(s0)
    800006d8:	4601                	li	a2,0
    800006da:	45c1                	li	a1,16
    800006dc:	0007e503          	lwu	a0,0(a5)
    800006e0:	d91ff0ef          	jal	80000470 <printint>
    800006e4:	bd41                	j	80000574 <printf+0x7a>
      printint(va_arg(ap, uint64), 16, 0);
    800006e6:	f8843783          	ld	a5,-120(s0)
    800006ea:	00878713          	addi	a4,a5,8
    800006ee:	f8e43423          	sd	a4,-120(s0)
    800006f2:	4601                	li	a2,0
    800006f4:	45c1                	li	a1,16
    800006f6:	6388                	ld	a0,0(a5)
    800006f8:	d79ff0ef          	jal	80000470 <printint>
      i += 1;
    800006fc:	0029049b          	addiw	s1,s2,2
    80000700:	bd95                	j	80000574 <printf+0x7a>
    80000702:	fc5e                	sd	s7,56(sp)
      printptr(va_arg(ap, uint64));
    80000704:	f8843783          	ld	a5,-120(s0)
    80000708:	00878713          	addi	a4,a5,8
    8000070c:	f8e43423          	sd	a4,-120(s0)
    80000710:	0007b983          	ld	s3,0(a5)
  consputc('0');
    80000714:	03000513          	li	a0,48
    80000718:	b63ff0ef          	jal	8000027a <consputc>
  consputc('x');
    8000071c:	07800513          	li	a0,120
    80000720:	b5bff0ef          	jal	8000027a <consputc>
    80000724:	4941                	li	s2,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    80000726:	00007b97          	auipc	s7,0x7
    8000072a:	feab8b93          	addi	s7,s7,-22 # 80007710 <digits>
    8000072e:	03c9d793          	srli	a5,s3,0x3c
    80000732:	97de                	add	a5,a5,s7
    80000734:	0007c503          	lbu	a0,0(a5)
    80000738:	b43ff0ef          	jal	8000027a <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    8000073c:	0992                	slli	s3,s3,0x4
    8000073e:	397d                	addiw	s2,s2,-1
    80000740:	fe0917e3          	bnez	s2,8000072e <printf+0x234>
    80000744:	7be2                	ld	s7,56(sp)
    80000746:	b53d                	j	80000574 <printf+0x7a>
      consputc(va_arg(ap, uint));
    80000748:	f8843783          	ld	a5,-120(s0)
    8000074c:	00878713          	addi	a4,a5,8
    80000750:	f8e43423          	sd	a4,-120(s0)
    80000754:	4388                	lw	a0,0(a5)
    80000756:	b25ff0ef          	jal	8000027a <consputc>
    8000075a:	bd29                	j	80000574 <printf+0x7a>
      if((s = va_arg(ap, char*)) == 0)
    8000075c:	f8843783          	ld	a5,-120(s0)
    80000760:	00878713          	addi	a4,a5,8
    80000764:	f8e43423          	sd	a4,-120(s0)
    80000768:	0007b903          	ld	s2,0(a5)
    8000076c:	00090d63          	beqz	s2,80000786 <printf+0x28c>
      for(; *s; s++)
    80000770:	00094503          	lbu	a0,0(s2)
    80000774:	e00500e3          	beqz	a0,80000574 <printf+0x7a>
        consputc(*s);
    80000778:	b03ff0ef          	jal	8000027a <consputc>
      for(; *s; s++)
    8000077c:	0905                	addi	s2,s2,1
    8000077e:	00094503          	lbu	a0,0(s2)
    80000782:	f97d                	bnez	a0,80000778 <printf+0x27e>
    80000784:	bbc5                	j	80000574 <printf+0x7a>
        s = "(null)";
    80000786:	00007917          	auipc	s2,0x7
    8000078a:	88290913          	addi	s2,s2,-1918 # 80007008 <etext+0x8>
      for(; *s; s++)
    8000078e:	02800513          	li	a0,40
    80000792:	b7dd                	j	80000778 <printf+0x27e>
    80000794:	74a6                	ld	s1,104(sp)
    80000796:	7906                	ld	s2,96(sp)
    80000798:	69e6                	ld	s3,88(sp)
    8000079a:	6aa6                	ld	s5,72(sp)
    8000079c:	6b06                	ld	s6,64(sp)
    8000079e:	7c42                	ld	s8,48(sp)
    800007a0:	7ca2                	ld	s9,40(sp)
    800007a2:	7d02                	ld	s10,32(sp)
    800007a4:	6de2                	ld	s11,24(sp)
    800007a6:	a811                	j	800007ba <printf+0x2c0>
    800007a8:	74a6                	ld	s1,104(sp)
    800007aa:	7906                	ld	s2,96(sp)
    800007ac:	69e6                	ld	s3,88(sp)
    800007ae:	6aa6                	ld	s5,72(sp)
    800007b0:	6b06                	ld	s6,64(sp)
    800007b2:	7c42                	ld	s8,48(sp)
    800007b4:	7ca2                	ld	s9,40(sp)
    800007b6:	7d02                	ld	s10,32(sp)
    800007b8:	6de2                	ld	s11,24(sp)
    }

  }
  va_end(ap);

  if(panicking == 0)
    800007ba:	0000a797          	auipc	a5,0xa
    800007be:	afa7a783          	lw	a5,-1286(a5) # 8000a2b4 <panicking>
    800007c2:	c799                	beqz	a5,800007d0 <printf+0x2d6>
    release(&pr.lock);

  return 0;
}
    800007c4:	4501                	li	a0,0
    800007c6:	70e6                	ld	ra,120(sp)
    800007c8:	7446                	ld	s0,112(sp)
    800007ca:	6a46                	ld	s4,80(sp)
    800007cc:	6129                	addi	sp,sp,192
    800007ce:	8082                	ret
    release(&pr.lock);
    800007d0:	00012517          	auipc	a0,0x12
    800007d4:	bb850513          	addi	a0,a0,-1096 # 80012388 <pr>
    800007d8:	488000ef          	jal	80000c60 <release>
  return 0;
    800007dc:	b7e5                	j	800007c4 <printf+0x2ca>

00000000800007de <panic>:

void
panic(char *s)
{
    800007de:	1101                	addi	sp,sp,-32
    800007e0:	ec06                	sd	ra,24(sp)
    800007e2:	e822                	sd	s0,16(sp)
    800007e4:	e426                	sd	s1,8(sp)
    800007e6:	e04a                	sd	s2,0(sp)
    800007e8:	1000                	addi	s0,sp,32
    800007ea:	84aa                	mv	s1,a0
  panicking = 1;
    800007ec:	4905                	li	s2,1
    800007ee:	0000a797          	auipc	a5,0xa
    800007f2:	ad27a323          	sw	s2,-1338(a5) # 8000a2b4 <panicking>
  printf("panic: ");
    800007f6:	00007517          	auipc	a0,0x7
    800007fa:	82250513          	addi	a0,a0,-2014 # 80007018 <etext+0x18>
    800007fe:	cfdff0ef          	jal	800004fa <printf>
  printf("%s\n", s);
    80000802:	85a6                	mv	a1,s1
    80000804:	00007517          	auipc	a0,0x7
    80000808:	81c50513          	addi	a0,a0,-2020 # 80007020 <etext+0x20>
    8000080c:	cefff0ef          	jal	800004fa <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000810:	0000a797          	auipc	a5,0xa
    80000814:	ab27a023          	sw	s2,-1376(a5) # 8000a2b0 <panicked>
  for(;;)
    80000818:	a001                	j	80000818 <panic+0x3a>

000000008000081a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000081a:	1141                	addi	sp,sp,-16
    8000081c:	e406                	sd	ra,8(sp)
    8000081e:	e022                	sd	s0,0(sp)
    80000820:	0800                	addi	s0,sp,16
  initlock(&pr.lock, "pr");
    80000822:	00007597          	auipc	a1,0x7
    80000826:	80658593          	addi	a1,a1,-2042 # 80007028 <etext+0x28>
    8000082a:	00012517          	auipc	a0,0x12
    8000082e:	b5e50513          	addi	a0,a0,-1186 # 80012388 <pr>
    80000832:	316000ef          	jal	80000b48 <initlock>
}
    80000836:	60a2                	ld	ra,8(sp)
    80000838:	6402                	ld	s0,0(sp)
    8000083a:	0141                	addi	sp,sp,16
    8000083c:	8082                	ret

000000008000083e <uartinit>:
extern volatile int panicking; // from printf.c
extern volatile int panicked; // from printf.c

void
uartinit(void)
{
    8000083e:	1141                	addi	sp,sp,-16
    80000840:	e406                	sd	ra,8(sp)
    80000842:	e022                	sd	s0,0(sp)
    80000844:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000846:	100007b7          	lui	a5,0x10000
    8000084a:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000084e:	10000737          	lui	a4,0x10000
    80000852:	f8000693          	li	a3,-128
    80000856:	00d701a3          	sb	a3,3(a4) # 10000003 <_entry-0x6ffffffd>

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    8000085a:	468d                	li	a3,3
    8000085c:	10000637          	lui	a2,0x10000
    80000860:	00d60023          	sb	a3,0(a2) # 10000000 <_entry-0x70000000>

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    80000864:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000868:	00d701a3          	sb	a3,3(a4)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    8000086c:	8732                	mv	a4,a2
    8000086e:	461d                	li	a2,7
    80000870:	00c70123          	sb	a2,2(a4)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    80000874:	00d780a3          	sb	a3,1(a5)

  initlock(&tx_lock, "uart");
    80000878:	00006597          	auipc	a1,0x6
    8000087c:	7b858593          	addi	a1,a1,1976 # 80007030 <etext+0x30>
    80000880:	00012517          	auipc	a0,0x12
    80000884:	b2050513          	addi	a0,a0,-1248 # 800123a0 <tx_lock>
    80000888:	2c0000ef          	jal	80000b48 <initlock>
}
    8000088c:	60a2                	ld	ra,8(sp)
    8000088e:	6402                	ld	s0,0(sp)
    80000890:	0141                	addi	sp,sp,16
    80000892:	8082                	ret

0000000080000894 <uartwrite>:
// transmit buf[] to the uart. it blocks if the
// uart is busy, so it cannot be called from
// interrupts, only from write() system calls.
void
uartwrite(char buf[], int n)
{
    80000894:	715d                	addi	sp,sp,-80
    80000896:	e486                	sd	ra,72(sp)
    80000898:	e0a2                	sd	s0,64(sp)
    8000089a:	fc26                	sd	s1,56(sp)
    8000089c:	ec56                	sd	s5,24(sp)
    8000089e:	0880                	addi	s0,sp,80
    800008a0:	8aaa                	mv	s5,a0
    800008a2:	84ae                	mv	s1,a1
  acquire(&tx_lock);
    800008a4:	00012517          	auipc	a0,0x12
    800008a8:	afc50513          	addi	a0,a0,-1284 # 800123a0 <tx_lock>
    800008ac:	320000ef          	jal	80000bcc <acquire>

  int i = 0;
  while(i < n){ 
    800008b0:	06905063          	blez	s1,80000910 <uartwrite+0x7c>
    800008b4:	f84a                	sd	s2,48(sp)
    800008b6:	f44e                	sd	s3,40(sp)
    800008b8:	f052                	sd	s4,32(sp)
    800008ba:	e85a                	sd	s6,16(sp)
    800008bc:	e45e                	sd	s7,8(sp)
    800008be:	8a56                	mv	s4,s5
    800008c0:	9aa6                	add	s5,s5,s1
    while(tx_busy != 0){
    800008c2:	0000a497          	auipc	s1,0xa
    800008c6:	9fa48493          	addi	s1,s1,-1542 # 8000a2bc <tx_busy>
      // wait for a UART transmit-complete interrupt
      // to set tx_busy to 0.
      sleep(&tx_chan, &tx_lock);
    800008ca:	00012997          	auipc	s3,0x12
    800008ce:	ad698993          	addi	s3,s3,-1322 # 800123a0 <tx_lock>
    800008d2:	0000a917          	auipc	s2,0xa
    800008d6:	9e690913          	addi	s2,s2,-1562 # 8000a2b8 <tx_chan>
    }   
      
    WriteReg(THR, buf[i]);
    800008da:	10000bb7          	lui	s7,0x10000
    i += 1;
    tx_busy = 1;
    800008de:	4b05                	li	s6,1
    800008e0:	a005                	j	80000900 <uartwrite+0x6c>
      sleep(&tx_chan, &tx_lock);
    800008e2:	85ce                	mv	a1,s3
    800008e4:	854a                	mv	a0,s2
    800008e6:	5e2010ef          	jal	80001ec8 <sleep>
    while(tx_busy != 0){
    800008ea:	409c                	lw	a5,0(s1)
    800008ec:	fbfd                	bnez	a5,800008e2 <uartwrite+0x4e>
    WriteReg(THR, buf[i]);
    800008ee:	000a4783          	lbu	a5,0(s4)
    800008f2:	00fb8023          	sb	a5,0(s7) # 10000000 <_entry-0x70000000>
    tx_busy = 1;
    800008f6:	0164a023          	sw	s6,0(s1)
  while(i < n){ 
    800008fa:	0a05                	addi	s4,s4,1
    800008fc:	015a0563          	beq	s4,s5,80000906 <uartwrite+0x72>
    while(tx_busy != 0){
    80000900:	409c                	lw	a5,0(s1)
    80000902:	f3e5                	bnez	a5,800008e2 <uartwrite+0x4e>
    80000904:	b7ed                	j	800008ee <uartwrite+0x5a>
    80000906:	7942                	ld	s2,48(sp)
    80000908:	79a2                	ld	s3,40(sp)
    8000090a:	7a02                	ld	s4,32(sp)
    8000090c:	6b42                	ld	s6,16(sp)
    8000090e:	6ba2                	ld	s7,8(sp)
  }

  release(&tx_lock);
    80000910:	00012517          	auipc	a0,0x12
    80000914:	a9050513          	addi	a0,a0,-1392 # 800123a0 <tx_lock>
    80000918:	348000ef          	jal	80000c60 <release>
}
    8000091c:	60a6                	ld	ra,72(sp)
    8000091e:	6406                	ld	s0,64(sp)
    80000920:	74e2                	ld	s1,56(sp)
    80000922:	6ae2                	ld	s5,24(sp)
    80000924:	6161                	addi	sp,sp,80
    80000926:	8082                	ret

0000000080000928 <uartputc_sync>:
// interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000928:	1101                	addi	sp,sp,-32
    8000092a:	ec06                	sd	ra,24(sp)
    8000092c:	e822                	sd	s0,16(sp)
    8000092e:	e426                	sd	s1,8(sp)
    80000930:	1000                	addi	s0,sp,32
    80000932:	84aa                	mv	s1,a0
  if(panicking == 0)
    80000934:	0000a797          	auipc	a5,0xa
    80000938:	9807a783          	lw	a5,-1664(a5) # 8000a2b4 <panicking>
    8000093c:	cf95                	beqz	a5,80000978 <uartputc_sync+0x50>
    push_off();

  if(panicked){
    8000093e:	0000a797          	auipc	a5,0xa
    80000942:	9727a783          	lw	a5,-1678(a5) # 8000a2b0 <panicked>
    80000946:	ef85                	bnez	a5,8000097e <uartputc_sync+0x56>
    for(;;)
      ;
  }

  // wait for UART to set Transmit Holding Empty in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000948:	10000737          	lui	a4,0x10000
    8000094c:	0715                	addi	a4,a4,5 # 10000005 <_entry-0x6ffffffb>
    8000094e:	00074783          	lbu	a5,0(a4)
    80000952:	0207f793          	andi	a5,a5,32
    80000956:	dfe5                	beqz	a5,8000094e <uartputc_sync+0x26>
    ;
  WriteReg(THR, c);
    80000958:	0ff4f513          	zext.b	a0,s1
    8000095c:	100007b7          	lui	a5,0x10000
    80000960:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  if(panicking == 0)
    80000964:	0000a797          	auipc	a5,0xa
    80000968:	9507a783          	lw	a5,-1712(a5) # 8000a2b4 <panicking>
    8000096c:	cb91                	beqz	a5,80000980 <uartputc_sync+0x58>
    pop_off();
}
    8000096e:	60e2                	ld	ra,24(sp)
    80000970:	6442                	ld	s0,16(sp)
    80000972:	64a2                	ld	s1,8(sp)
    80000974:	6105                	addi	sp,sp,32
    80000976:	8082                	ret
    push_off();
    80000978:	214000ef          	jal	80000b8c <push_off>
    8000097c:	b7c9                	j	8000093e <uartputc_sync+0x16>
    for(;;)
    8000097e:	a001                	j	8000097e <uartputc_sync+0x56>
    pop_off();
    80000980:	290000ef          	jal	80000c10 <pop_off>
}
    80000984:	b7ed                	j	8000096e <uartputc_sync+0x46>

0000000080000986 <uartgetc>:

// try to read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e406                	sd	ra,8(sp)
    8000098a:	e022                	sd	s0,0(sp)
    8000098c:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & LSR_RX_READY){
    8000098e:	100007b7          	lui	a5,0x10000
    80000992:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000996:	8b85                	andi	a5,a5,1
    80000998:	cb89                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    8000099a:	100007b7          	lui	a5,0x10000
    8000099e:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    800009a2:	60a2                	ld	ra,8(sp)
    800009a4:	6402                	ld	s0,0(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfdd                	j	800009a2 <uartgetc+0x1c>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  ReadReg(ISR); // acknowledge the interrupt
    800009b8:	100007b7          	lui	a5,0x10000
    800009bc:	0027c783          	lbu	a5,2(a5) # 10000002 <_entry-0x6ffffffe>

  acquire(&tx_lock);
    800009c0:	00012517          	auipc	a0,0x12
    800009c4:	9e050513          	addi	a0,a0,-1568 # 800123a0 <tx_lock>
    800009c8:	204000ef          	jal	80000bcc <acquire>
  if(ReadReg(LSR) & LSR_TX_IDLE){
    800009cc:	100007b7          	lui	a5,0x10000
    800009d0:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009d4:	0207f793          	andi	a5,a5,32
    800009d8:	ef99                	bnez	a5,800009f6 <uartintr+0x48>
    // UART finished transmitting; wake up sending thread.
    tx_busy = 0;
    wakeup(&tx_chan);
  }
  release(&tx_lock);
    800009da:	00012517          	auipc	a0,0x12
    800009de:	9c650513          	addi	a0,a0,-1594 # 800123a0 <tx_lock>
    800009e2:	27e000ef          	jal	80000c60 <release>

  // read and process incoming characters, if any.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	f9fff0ef          	jal	80000986 <uartgetc>
    if(c == -1)
    800009ec:	02950063          	beq	a0,s1,80000a0c <uartintr+0x5e>
      break;
    consoleintr(c);
    800009f0:	8bdff0ef          	jal	800002ac <consoleintr>
  while(1){
    800009f4:	bfd5                	j	800009e8 <uartintr+0x3a>
    tx_busy = 0;
    800009f6:	0000a797          	auipc	a5,0xa
    800009fa:	8c07a323          	sw	zero,-1850(a5) # 8000a2bc <tx_busy>
    wakeup(&tx_chan);
    800009fe:	0000a517          	auipc	a0,0xa
    80000a02:	8ba50513          	addi	a0,a0,-1862 # 8000a2b8 <tx_chan>
    80000a06:	50e010ef          	jal	80001f14 <wakeup>
    80000a0a:	bfc1                	j	800009da <uartintr+0x2c>
  }
}
    80000a0c:	60e2                	ld	ra,24(sp)
    80000a0e:	6442                	ld	s0,16(sp)
    80000a10:	64a2                	ld	s1,8(sp)
    80000a12:	6105                	addi	sp,sp,32
    80000a14:	8082                	ret

0000000080000a16 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a16:	1101                	addi	sp,sp,-32
    80000a18:	ec06                	sd	ra,24(sp)
    80000a1a:	e822                	sd	s0,16(sp)
    80000a1c:	e426                	sd	s1,8(sp)
    80000a1e:	e04a                	sd	s2,0(sp)
    80000a20:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a22:	03451793          	slli	a5,a0,0x34
    80000a26:	e7a9                	bnez	a5,80000a70 <kfree+0x5a>
    80000a28:	84aa                	mv	s1,a0
    80000a2a:	00023797          	auipc	a5,0x23
    80000a2e:	bbe78793          	addi	a5,a5,-1090 # 800235e8 <end>
    80000a32:	02f56f63          	bltu	a0,a5,80000a70 <kfree+0x5a>
    80000a36:	47c5                	li	a5,17
    80000a38:	07ee                	slli	a5,a5,0x1b
    80000a3a:	02f57b63          	bgeu	a0,a5,80000a70 <kfree+0x5a>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a3e:	6605                	lui	a2,0x1
    80000a40:	4585                	li	a1,1
    80000a42:	25a000ef          	jal	80000c9c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a46:	00012917          	auipc	s2,0x12
    80000a4a:	97290913          	addi	s2,s2,-1678 # 800123b8 <kmem>
    80000a4e:	854a                	mv	a0,s2
    80000a50:	17c000ef          	jal	80000bcc <acquire>
  r->next = kmem.freelist;
    80000a54:	01893783          	ld	a5,24(s2)
    80000a58:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a5a:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a5e:	854a                	mv	a0,s2
    80000a60:	200000ef          	jal	80000c60 <release>
}
    80000a64:	60e2                	ld	ra,24(sp)
    80000a66:	6442                	ld	s0,16(sp)
    80000a68:	64a2                	ld	s1,8(sp)
    80000a6a:	6902                	ld	s2,0(sp)
    80000a6c:	6105                	addi	sp,sp,32
    80000a6e:	8082                	ret
    panic("kfree");
    80000a70:	00006517          	auipc	a0,0x6
    80000a74:	5c850513          	addi	a0,a0,1480 # 80007038 <etext+0x38>
    80000a78:	d67ff0ef          	jal	800007de <panic>

0000000080000a7c <freerange>:
{
    80000a7c:	7179                	addi	sp,sp,-48
    80000a7e:	f406                	sd	ra,40(sp)
    80000a80:	f022                	sd	s0,32(sp)
    80000a82:	ec26                	sd	s1,24(sp)
    80000a84:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a86:	6785                	lui	a5,0x1
    80000a88:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a8c:	00e504b3          	add	s1,a0,a4
    80000a90:	777d                	lui	a4,0xfffff
    80000a92:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94be                	add	s1,s1,a5
    80000a96:	0295e263          	bltu	a1,s1,80000aba <freerange+0x3e>
    80000a9a:	e84a                	sd	s2,16(sp)
    80000a9c:	e44e                	sd	s3,8(sp)
    80000a9e:	e052                	sd	s4,0(sp)
    80000aa0:	892e                	mv	s2,a1
    kfree(p);
    80000aa2:	8a3a                	mv	s4,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa4:	89be                	mv	s3,a5
    kfree(p);
    80000aa6:	01448533          	add	a0,s1,s4
    80000aaa:	f6dff0ef          	jal	80000a16 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aae:	94ce                	add	s1,s1,s3
    80000ab0:	fe997be3          	bgeu	s2,s1,80000aa6 <freerange+0x2a>
    80000ab4:	6942                	ld	s2,16(sp)
    80000ab6:	69a2                	ld	s3,8(sp)
    80000ab8:	6a02                	ld	s4,0(sp)
}
    80000aba:	70a2                	ld	ra,40(sp)
    80000abc:	7402                	ld	s0,32(sp)
    80000abe:	64e2                	ld	s1,24(sp)
    80000ac0:	6145                	addi	sp,sp,48
    80000ac2:	8082                	ret

0000000080000ac4 <kinit>:
{
    80000ac4:	1141                	addi	sp,sp,-16
    80000ac6:	e406                	sd	ra,8(sp)
    80000ac8:	e022                	sd	s0,0(sp)
    80000aca:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000acc:	00006597          	auipc	a1,0x6
    80000ad0:	57458593          	addi	a1,a1,1396 # 80007040 <etext+0x40>
    80000ad4:	00012517          	auipc	a0,0x12
    80000ad8:	8e450513          	addi	a0,a0,-1820 # 800123b8 <kmem>
    80000adc:	06c000ef          	jal	80000b48 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ae0:	45c5                	li	a1,17
    80000ae2:	05ee                	slli	a1,a1,0x1b
    80000ae4:	00023517          	auipc	a0,0x23
    80000ae8:	b0450513          	addi	a0,a0,-1276 # 800235e8 <end>
    80000aec:	f91ff0ef          	jal	80000a7c <freerange>
}
    80000af0:	60a2                	ld	ra,8(sp)
    80000af2:	6402                	ld	s0,0(sp)
    80000af4:	0141                	addi	sp,sp,16
    80000af6:	8082                	ret

0000000080000af8 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af8:	1101                	addi	sp,sp,-32
    80000afa:	ec06                	sd	ra,24(sp)
    80000afc:	e822                	sd	s0,16(sp)
    80000afe:	e426                	sd	s1,8(sp)
    80000b00:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b02:	00012497          	auipc	s1,0x12
    80000b06:	8b648493          	addi	s1,s1,-1866 # 800123b8 <kmem>
    80000b0a:	8526                	mv	a0,s1
    80000b0c:	0c0000ef          	jal	80000bcc <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c485                	beqz	s1,80000b3a <kalloc+0x42>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00012517          	auipc	a0,0x12
    80000b1a:	8a250513          	addi	a0,a0,-1886 # 800123b8 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	140000ef          	jal	80000c60 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b24:	6605                	lui	a2,0x1
    80000b26:	4595                	li	a1,5
    80000b28:	8526                	mv	a0,s1
    80000b2a:	172000ef          	jal	80000c9c <memset>
  return (void*)r;
}
    80000b2e:	8526                	mv	a0,s1
    80000b30:	60e2                	ld	ra,24(sp)
    80000b32:	6442                	ld	s0,16(sp)
    80000b34:	64a2                	ld	s1,8(sp)
    80000b36:	6105                	addi	sp,sp,32
    80000b38:	8082                	ret
  release(&kmem.lock);
    80000b3a:	00012517          	auipc	a0,0x12
    80000b3e:	87e50513          	addi	a0,a0,-1922 # 800123b8 <kmem>
    80000b42:	11e000ef          	jal	80000c60 <release>
  if(r)
    80000b46:	b7e5                	j	80000b2e <kalloc+0x36>

0000000080000b48 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b48:	1141                	addi	sp,sp,-16
    80000b4a:	e406                	sd	ra,8(sp)
    80000b4c:	e022                	sd	s0,0(sp)
    80000b4e:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b50:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b52:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b56:	00053823          	sd	zero,16(a0)
}
    80000b5a:	60a2                	ld	ra,8(sp)
    80000b5c:	6402                	ld	s0,0(sp)
    80000b5e:	0141                	addi	sp,sp,16
    80000b60:	8082                	ret

0000000080000b62 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b62:	411c                	lw	a5,0(a0)
    80000b64:	e399                	bnez	a5,80000b6a <holding+0x8>
    80000b66:	4501                	li	a0,0
  return r;
}
    80000b68:	8082                	ret
{
    80000b6a:	1101                	addi	sp,sp,-32
    80000b6c:	ec06                	sd	ra,24(sp)
    80000b6e:	e822                	sd	s0,16(sp)
    80000b70:	e426                	sd	s1,8(sp)
    80000b72:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b74:	6904                	ld	s1,16(a0)
    80000b76:	529000ef          	jal	8000189e <mycpu>
    80000b7a:	40a48533          	sub	a0,s1,a0
    80000b7e:	00153513          	seqz	a0,a0
}
    80000b82:	60e2                	ld	ra,24(sp)
    80000b84:	6442                	ld	s0,16(sp)
    80000b86:	64a2                	ld	s1,8(sp)
    80000b88:	6105                	addi	sp,sp,32
    80000b8a:	8082                	ret

0000000080000b8c <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8c:	1101                	addi	sp,sp,-32
    80000b8e:	ec06                	sd	ra,24(sp)
    80000b90:	e822                	sd	s0,16(sp)
    80000b92:	e426                	sd	s1,8(sp)
    80000b94:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b96:	100024f3          	csrr	s1,sstatus
    80000b9a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ba0:	10079073          	csrw	sstatus,a5

  // disable interrupts to prevent an involuntary context
  // switch while using mycpu().
  intr_off();

  if(mycpu()->noff == 0)
    80000ba4:	4fb000ef          	jal	8000189e <mycpu>
    80000ba8:	5d3c                	lw	a5,120(a0)
    80000baa:	cb99                	beqz	a5,80000bc0 <push_off+0x34>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bac:	4f3000ef          	jal	8000189e <mycpu>
    80000bb0:	5d3c                	lw	a5,120(a0)
    80000bb2:	2785                	addiw	a5,a5,1
    80000bb4:	dd3c                	sw	a5,120(a0)
}
    80000bb6:	60e2                	ld	ra,24(sp)
    80000bb8:	6442                	ld	s0,16(sp)
    80000bba:	64a2                	ld	s1,8(sp)
    80000bbc:	6105                	addi	sp,sp,32
    80000bbe:	8082                	ret
    mycpu()->intena = old;
    80000bc0:	4df000ef          	jal	8000189e <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bc4:	8085                	srli	s1,s1,0x1
    80000bc6:	8885                	andi	s1,s1,1
    80000bc8:	dd64                	sw	s1,124(a0)
    80000bca:	b7cd                	j	80000bac <push_off+0x20>

0000000080000bcc <acquire>:
{
    80000bcc:	1101                	addi	sp,sp,-32
    80000bce:	ec06                	sd	ra,24(sp)
    80000bd0:	e822                	sd	s0,16(sp)
    80000bd2:	e426                	sd	s1,8(sp)
    80000bd4:	1000                	addi	s0,sp,32
    80000bd6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bd8:	fb5ff0ef          	jal	80000b8c <push_off>
  if(holding(lk))
    80000bdc:	8526                	mv	a0,s1
    80000bde:	f85ff0ef          	jal	80000b62 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be2:	4705                	li	a4,1
  if(holding(lk))
    80000be4:	e105                	bnez	a0,80000c04 <acquire+0x38>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000be6:	87ba                	mv	a5,a4
    80000be8:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bec:	2781                	sext.w	a5,a5
    80000bee:	ffe5                	bnez	a5,80000be6 <acquire+0x1a>
  __sync_synchronize();
    80000bf0:	0330000f          	fence	rw,rw
  lk->cpu = mycpu();
    80000bf4:	4ab000ef          	jal	8000189e <mycpu>
    80000bf8:	e888                	sd	a0,16(s1)
}
    80000bfa:	60e2                	ld	ra,24(sp)
    80000bfc:	6442                	ld	s0,16(sp)
    80000bfe:	64a2                	ld	s1,8(sp)
    80000c00:	6105                	addi	sp,sp,32
    80000c02:	8082                	ret
    panic("acquire");
    80000c04:	00006517          	auipc	a0,0x6
    80000c08:	44450513          	addi	a0,a0,1092 # 80007048 <etext+0x48>
    80000c0c:	bd3ff0ef          	jal	800007de <panic>

0000000080000c10 <pop_off>:

void
pop_off(void)
{
    80000c10:	1141                	addi	sp,sp,-16
    80000c12:	e406                	sd	ra,8(sp)
    80000c14:	e022                	sd	s0,0(sp)
    80000c16:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c18:	487000ef          	jal	8000189e <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c1c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c20:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c22:	e39d                	bnez	a5,80000c48 <pop_off+0x38>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c24:	5d3c                	lw	a5,120(a0)
    80000c26:	02f05763          	blez	a5,80000c54 <pop_off+0x44>
    panic("pop_off");
  c->noff -= 1;
    80000c2a:	37fd                	addiw	a5,a5,-1
    80000c2c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c2e:	eb89                	bnez	a5,80000c40 <pop_off+0x30>
    80000c30:	5d7c                	lw	a5,124(a0)
    80000c32:	c799                	beqz	a5,80000c40 <pop_off+0x30>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c34:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c38:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c3c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c40:	60a2                	ld	ra,8(sp)
    80000c42:	6402                	ld	s0,0(sp)
    80000c44:	0141                	addi	sp,sp,16
    80000c46:	8082                	ret
    panic("pop_off - interruptible");
    80000c48:	00006517          	auipc	a0,0x6
    80000c4c:	40850513          	addi	a0,a0,1032 # 80007050 <etext+0x50>
    80000c50:	b8fff0ef          	jal	800007de <panic>
    panic("pop_off");
    80000c54:	00006517          	auipc	a0,0x6
    80000c58:	41450513          	addi	a0,a0,1044 # 80007068 <etext+0x68>
    80000c5c:	b83ff0ef          	jal	800007de <panic>

0000000080000c60 <release>:
{
    80000c60:	1101                	addi	sp,sp,-32
    80000c62:	ec06                	sd	ra,24(sp)
    80000c64:	e822                	sd	s0,16(sp)
    80000c66:	e426                	sd	s1,8(sp)
    80000c68:	1000                	addi	s0,sp,32
    80000c6a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c6c:	ef7ff0ef          	jal	80000b62 <holding>
    80000c70:	c105                	beqz	a0,80000c90 <release+0x30>
  lk->cpu = 0;
    80000c72:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000c76:	0330000f          	fence	rw,rw
  __sync_lock_release(&lk->locked);
    80000c7a:	0310000f          	fence	rw,w
    80000c7e:	0004a023          	sw	zero,0(s1)
  pop_off();
    80000c82:	f8fff0ef          	jal	80000c10 <pop_off>
}
    80000c86:	60e2                	ld	ra,24(sp)
    80000c88:	6442                	ld	s0,16(sp)
    80000c8a:	64a2                	ld	s1,8(sp)
    80000c8c:	6105                	addi	sp,sp,32
    80000c8e:	8082                	ret
    panic("release");
    80000c90:	00006517          	auipc	a0,0x6
    80000c94:	3e050513          	addi	a0,a0,992 # 80007070 <etext+0x70>
    80000c98:	b47ff0ef          	jal	800007de <panic>

0000000080000c9c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000c9c:	1141                	addi	sp,sp,-16
    80000c9e:	e406                	sd	ra,8(sp)
    80000ca0:	e022                	sd	s0,0(sp)
    80000ca2:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ca4:	ca19                	beqz	a2,80000cba <memset+0x1e>
    80000ca6:	87aa                	mv	a5,a0
    80000ca8:	1602                	slli	a2,a2,0x20
    80000caa:	9201                	srli	a2,a2,0x20
    80000cac:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000cb0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cb4:	0785                	addi	a5,a5,1
    80000cb6:	fee79de3          	bne	a5,a4,80000cb0 <memset+0x14>
  }
  return dst;
}
    80000cba:	60a2                	ld	ra,8(sp)
    80000cbc:	6402                	ld	s0,0(sp)
    80000cbe:	0141                	addi	sp,sp,16
    80000cc0:	8082                	ret

0000000080000cc2 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cc2:	1141                	addi	sp,sp,-16
    80000cc4:	e406                	sd	ra,8(sp)
    80000cc6:	e022                	sd	s0,0(sp)
    80000cc8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cca:	ca0d                	beqz	a2,80000cfc <memcmp+0x3a>
    80000ccc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000cd0:	1682                	slli	a3,a3,0x20
    80000cd2:	9281                	srli	a3,a3,0x20
    80000cd4:	0685                	addi	a3,a3,1
    80000cd6:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000cd8:	00054783          	lbu	a5,0(a0)
    80000cdc:	0005c703          	lbu	a4,0(a1)
    80000ce0:	00e79863          	bne	a5,a4,80000cf0 <memcmp+0x2e>
      return *s1 - *s2;
    s1++, s2++;
    80000ce4:	0505                	addi	a0,a0,1
    80000ce6:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ce8:	fed518e3          	bne	a0,a3,80000cd8 <memcmp+0x16>
  }

  return 0;
    80000cec:	4501                	li	a0,0
    80000cee:	a019                	j	80000cf4 <memcmp+0x32>
      return *s1 - *s2;
    80000cf0:	40e7853b          	subw	a0,a5,a4
}
    80000cf4:	60a2                	ld	ra,8(sp)
    80000cf6:	6402                	ld	s0,0(sp)
    80000cf8:	0141                	addi	sp,sp,16
    80000cfa:	8082                	ret
  return 0;
    80000cfc:	4501                	li	a0,0
    80000cfe:	bfdd                	j	80000cf4 <memcmp+0x32>

0000000080000d00 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d00:	1141                	addi	sp,sp,-16
    80000d02:	e406                	sd	ra,8(sp)
    80000d04:	e022                	sd	s0,0(sp)
    80000d06:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d08:	c205                	beqz	a2,80000d28 <memmove+0x28>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d0a:	02a5e363          	bltu	a1,a0,80000d30 <memmove+0x30>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d0e:	1602                	slli	a2,a2,0x20
    80000d10:	9201                	srli	a2,a2,0x20
    80000d12:	00c587b3          	add	a5,a1,a2
{
    80000d16:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d18:	0585                	addi	a1,a1,1
    80000d1a:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdba19>
    80000d1c:	fff5c683          	lbu	a3,-1(a1)
    80000d20:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d24:	feb79ae3          	bne	a5,a1,80000d18 <memmove+0x18>

  return dst;
}
    80000d28:	60a2                	ld	ra,8(sp)
    80000d2a:	6402                	ld	s0,0(sp)
    80000d2c:	0141                	addi	sp,sp,16
    80000d2e:	8082                	ret
  if(s < d && s + n > d){
    80000d30:	02061693          	slli	a3,a2,0x20
    80000d34:	9281                	srli	a3,a3,0x20
    80000d36:	00d58733          	add	a4,a1,a3
    80000d3a:	fce57ae3          	bgeu	a0,a4,80000d0e <memmove+0xe>
    d += n;
    80000d3e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d40:	fff6079b          	addiw	a5,a2,-1
    80000d44:	1782                	slli	a5,a5,0x20
    80000d46:	9381                	srli	a5,a5,0x20
    80000d48:	fff7c793          	not	a5,a5
    80000d4c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d4e:	177d                	addi	a4,a4,-1
    80000d50:	16fd                	addi	a3,a3,-1
    80000d52:	00074603          	lbu	a2,0(a4)
    80000d56:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d5a:	fee79ae3          	bne	a5,a4,80000d4e <memmove+0x4e>
    80000d5e:	b7e9                	j	80000d28 <memmove+0x28>

0000000080000d60 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d60:	1141                	addi	sp,sp,-16
    80000d62:	e406                	sd	ra,8(sp)
    80000d64:	e022                	sd	s0,0(sp)
    80000d66:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d68:	f99ff0ef          	jal	80000d00 <memmove>
}
    80000d6c:	60a2                	ld	ra,8(sp)
    80000d6e:	6402                	ld	s0,0(sp)
    80000d70:	0141                	addi	sp,sp,16
    80000d72:	8082                	ret

0000000080000d74 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000d74:	1141                	addi	sp,sp,-16
    80000d76:	e406                	sd	ra,8(sp)
    80000d78:	e022                	sd	s0,0(sp)
    80000d7a:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000d7c:	ce11                	beqz	a2,80000d98 <strncmp+0x24>
    80000d7e:	00054783          	lbu	a5,0(a0)
    80000d82:	cf89                	beqz	a5,80000d9c <strncmp+0x28>
    80000d84:	0005c703          	lbu	a4,0(a1)
    80000d88:	00f71a63          	bne	a4,a5,80000d9c <strncmp+0x28>
    n--, p++, q++;
    80000d8c:	367d                	addiw	a2,a2,-1
    80000d8e:	0505                	addi	a0,a0,1
    80000d90:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000d92:	f675                	bnez	a2,80000d7e <strncmp+0xa>
  if(n == 0)
    return 0;
    80000d94:	4501                	li	a0,0
    80000d96:	a801                	j	80000da6 <strncmp+0x32>
    80000d98:	4501                	li	a0,0
    80000d9a:	a031                	j	80000da6 <strncmp+0x32>
  return (uchar)*p - (uchar)*q;
    80000d9c:	00054503          	lbu	a0,0(a0)
    80000da0:	0005c783          	lbu	a5,0(a1)
    80000da4:	9d1d                	subw	a0,a0,a5
}
    80000da6:	60a2                	ld	ra,8(sp)
    80000da8:	6402                	ld	s0,0(sp)
    80000daa:	0141                	addi	sp,sp,16
    80000dac:	8082                	ret

0000000080000dae <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dae:	1141                	addi	sp,sp,-16
    80000db0:	e406                	sd	ra,8(sp)
    80000db2:	e022                	sd	s0,0(sp)
    80000db4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000db6:	87aa                	mv	a5,a0
    80000db8:	86b2                	mv	a3,a2
    80000dba:	367d                	addiw	a2,a2,-1
    80000dbc:	02d05563          	blez	a3,80000de6 <strncpy+0x38>
    80000dc0:	0785                	addi	a5,a5,1
    80000dc2:	0005c703          	lbu	a4,0(a1)
    80000dc6:	fee78fa3          	sb	a4,-1(a5)
    80000dca:	0585                	addi	a1,a1,1
    80000dcc:	f775                	bnez	a4,80000db8 <strncpy+0xa>
    ;
  while(n-- > 0)
    80000dce:	873e                	mv	a4,a5
    80000dd0:	00c05b63          	blez	a2,80000de6 <strncpy+0x38>
    80000dd4:	9fb5                	addw	a5,a5,a3
    80000dd6:	37fd                	addiw	a5,a5,-1
    *s++ = 0;
    80000dd8:	0705                	addi	a4,a4,1
    80000dda:	fe070fa3          	sb	zero,-1(a4)
  while(n-- > 0)
    80000dde:	40e786bb          	subw	a3,a5,a4
    80000de2:	fed04be3          	bgtz	a3,80000dd8 <strncpy+0x2a>
  return os;
}
    80000de6:	60a2                	ld	ra,8(sp)
    80000de8:	6402                	ld	s0,0(sp)
    80000dea:	0141                	addi	sp,sp,16
    80000dec:	8082                	ret

0000000080000dee <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000dee:	1141                	addi	sp,sp,-16
    80000df0:	e406                	sd	ra,8(sp)
    80000df2:	e022                	sd	s0,0(sp)
    80000df4:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000df6:	02c05363          	blez	a2,80000e1c <safestrcpy+0x2e>
    80000dfa:	fff6069b          	addiw	a3,a2,-1
    80000dfe:	1682                	slli	a3,a3,0x20
    80000e00:	9281                	srli	a3,a3,0x20
    80000e02:	96ae                	add	a3,a3,a1
    80000e04:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e06:	00d58963          	beq	a1,a3,80000e18 <safestrcpy+0x2a>
    80000e0a:	0585                	addi	a1,a1,1
    80000e0c:	0785                	addi	a5,a5,1
    80000e0e:	fff5c703          	lbu	a4,-1(a1)
    80000e12:	fee78fa3          	sb	a4,-1(a5)
    80000e16:	fb65                	bnez	a4,80000e06 <safestrcpy+0x18>
    ;
  *s = 0;
    80000e18:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e1c:	60a2                	ld	ra,8(sp)
    80000e1e:	6402                	ld	s0,0(sp)
    80000e20:	0141                	addi	sp,sp,16
    80000e22:	8082                	ret

0000000080000e24 <strlen>:

int
strlen(const char *s)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e406                	sd	ra,8(sp)
    80000e28:	e022                	sd	s0,0(sp)
    80000e2a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e2c:	00054783          	lbu	a5,0(a0)
    80000e30:	cf99                	beqz	a5,80000e4e <strlen+0x2a>
    80000e32:	0505                	addi	a0,a0,1
    80000e34:	87aa                	mv	a5,a0
    80000e36:	86be                	mv	a3,a5
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff7c703          	lbu	a4,-1(a5)
    80000e3e:	ff65                	bnez	a4,80000e36 <strlen+0x12>
    80000e40:	40a6853b          	subw	a0,a3,a0
    80000e44:	2505                	addiw	a0,a0,1
    ;
  return n;
}
    80000e46:	60a2                	ld	ra,8(sp)
    80000e48:	6402                	ld	s0,0(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e4e:	4501                	li	a0,0
    80000e50:	bfdd                	j	80000e46 <strlen+0x22>

0000000080000e52 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e52:	1141                	addi	sp,sp,-16
    80000e54:	e406                	sd	ra,8(sp)
    80000e56:	e022                	sd	s0,0(sp)
    80000e58:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e5a:	231000ef          	jal	8000188a <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e5e:	00009717          	auipc	a4,0x9
    80000e62:	46270713          	addi	a4,a4,1122 # 8000a2c0 <started>
  if(cpuid() == 0){
    80000e66:	c51d                	beqz	a0,80000e94 <main+0x42>
    while(started == 0)
    80000e68:	431c                	lw	a5,0(a4)
    80000e6a:	2781                	sext.w	a5,a5
    80000e6c:	dff5                	beqz	a5,80000e68 <main+0x16>
      ;
    __sync_synchronize();
    80000e6e:	0330000f          	fence	rw,rw
    printf("hart %d starting\n", cpuid());
    80000e72:	219000ef          	jal	8000188a <cpuid>
    80000e76:	85aa                	mv	a1,a0
    80000e78:	00006517          	auipc	a0,0x6
    80000e7c:	22050513          	addi	a0,a0,544 # 80007098 <etext+0x98>
    80000e80:	e7aff0ef          	jal	800004fa <printf>
    kvminithart();    // turn on paging
    80000e84:	080000ef          	jal	80000f04 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000e88:	55c010ef          	jal	800023e4 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000e8c:	61c040ef          	jal	800054a8 <plicinithart>
  }

  scheduler();        
    80000e90:	6a1000ef          	jal	80001d30 <scheduler>
    consoleinit();
    80000e94:	d98ff0ef          	jal	8000042c <consoleinit>
    printfinit();
    80000e98:	983ff0ef          	jal	8000081a <printfinit>
    printf("\n");
    80000e9c:	00006517          	auipc	a0,0x6
    80000ea0:	1dc50513          	addi	a0,a0,476 # 80007078 <etext+0x78>
    80000ea4:	e56ff0ef          	jal	800004fa <printf>
    printf("xv6 kernel is booting\n");
    80000ea8:	00006517          	auipc	a0,0x6
    80000eac:	1d850513          	addi	a0,a0,472 # 80007080 <etext+0x80>
    80000eb0:	e4aff0ef          	jal	800004fa <printf>
    printf("\n");
    80000eb4:	00006517          	auipc	a0,0x6
    80000eb8:	1c450513          	addi	a0,a0,452 # 80007078 <etext+0x78>
    80000ebc:	e3eff0ef          	jal	800004fa <printf>
    kinit();         // physical page allocator
    80000ec0:	c05ff0ef          	jal	80000ac4 <kinit>
    kvminit();       // create kernel page table
    80000ec4:	2ce000ef          	jal	80001192 <kvminit>
    kvminithart();   // turn on paging
    80000ec8:	03c000ef          	jal	80000f04 <kvminithart>
    procinit();      // process table
    80000ecc:	10f000ef          	jal	800017da <procinit>
    trapinit();      // trap vectors
    80000ed0:	4f0010ef          	jal	800023c0 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ed4:	510010ef          	jal	800023e4 <trapinithart>
    plicinit();      // set up interrupt controller
    80000ed8:	5b6040ef          	jal	8000548e <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000edc:	5cc040ef          	jal	800054a8 <plicinithart>
    binit();         // buffer cache
    80000ee0:	44d010ef          	jal	80002b2c <binit>
    iinit();         // inode table
    80000ee4:	1ac020ef          	jal	80003090 <iinit>
    fileinit();      // file table
    80000ee8:	0be030ef          	jal	80003fa6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000eec:	6ac040ef          	jal	80005598 <virtio_disk_init>
    userinit();      // first user process
    80000ef0:	495000ef          	jal	80001b84 <userinit>
    __sync_synchronize();
    80000ef4:	0330000f          	fence	rw,rw
    started = 1;
    80000ef8:	4785                	li	a5,1
    80000efa:	00009717          	auipc	a4,0x9
    80000efe:	3cf72323          	sw	a5,966(a4) # 8000a2c0 <started>
    80000f02:	b779                	j	80000e90 <main+0x3e>

0000000080000f04 <kvminithart>:

// Switch the current CPU's h/w page table register to
// the kernel's page table, and enable paging.
void
kvminithart()
{
    80000f04:	1141                	addi	sp,sp,-16
    80000f06:	e406                	sd	ra,8(sp)
    80000f08:	e022                	sd	s0,0(sp)
    80000f0a:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f0c:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f10:	00009797          	auipc	a5,0x9
    80000f14:	3b87b783          	ld	a5,952(a5) # 8000a2c8 <kernel_pagetable>
    80000f18:	83b1                	srli	a5,a5,0xc
    80000f1a:	577d                	li	a4,-1
    80000f1c:	177e                	slli	a4,a4,0x3f
    80000f1e:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000f20:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000f24:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000f28:	60a2                	ld	ra,8(sp)
    80000f2a:	6402                	ld	s0,0(sp)
    80000f2c:	0141                	addi	sp,sp,16
    80000f2e:	8082                	ret

0000000080000f30 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000f30:	7139                	addi	sp,sp,-64
    80000f32:	fc06                	sd	ra,56(sp)
    80000f34:	f822                	sd	s0,48(sp)
    80000f36:	f426                	sd	s1,40(sp)
    80000f38:	f04a                	sd	s2,32(sp)
    80000f3a:	ec4e                	sd	s3,24(sp)
    80000f3c:	e852                	sd	s4,16(sp)
    80000f3e:	e456                	sd	s5,8(sp)
    80000f40:	e05a                	sd	s6,0(sp)
    80000f42:	0080                	addi	s0,sp,64
    80000f44:	84aa                	mv	s1,a0
    80000f46:	89ae                	mv	s3,a1
    80000f48:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000f4a:	57fd                	li	a5,-1
    80000f4c:	83e9                	srli	a5,a5,0x1a
    80000f4e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000f50:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000f52:	04b7e263          	bltu	a5,a1,80000f96 <walk+0x66>
    pte_t *pte = &pagetable[PX(level, va)];
    80000f56:	0149d933          	srl	s2,s3,s4
    80000f5a:	1ff97913          	andi	s2,s2,511
    80000f5e:	090e                	slli	s2,s2,0x3
    80000f60:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80000f62:	00093483          	ld	s1,0(s2)
    80000f66:	0014f793          	andi	a5,s1,1
    80000f6a:	cf85                	beqz	a5,80000fa2 <walk+0x72>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80000f6c:	80a9                	srli	s1,s1,0xa
    80000f6e:	04b2                	slli	s1,s1,0xc
  for(int level = 2; level > 0; level--) {
    80000f70:	3a5d                	addiw	s4,s4,-9
    80000f72:	ff6a12e3          	bne	s4,s6,80000f56 <walk+0x26>
        return 0;
      memset(pagetable, 0, PGSIZE);
      *pte = PA2PTE(pagetable) | PTE_V;
    }
  }
  return &pagetable[PX(0, va)];
    80000f76:	00c9d513          	srli	a0,s3,0xc
    80000f7a:	1ff57513          	andi	a0,a0,511
    80000f7e:	050e                	slli	a0,a0,0x3
    80000f80:	9526                	add	a0,a0,s1
}
    80000f82:	70e2                	ld	ra,56(sp)
    80000f84:	7442                	ld	s0,48(sp)
    80000f86:	74a2                	ld	s1,40(sp)
    80000f88:	7902                	ld	s2,32(sp)
    80000f8a:	69e2                	ld	s3,24(sp)
    80000f8c:	6a42                	ld	s4,16(sp)
    80000f8e:	6aa2                	ld	s5,8(sp)
    80000f90:	6b02                	ld	s6,0(sp)
    80000f92:	6121                	addi	sp,sp,64
    80000f94:	8082                	ret
    panic("walk");
    80000f96:	00006517          	auipc	a0,0x6
    80000f9a:	11a50513          	addi	a0,a0,282 # 800070b0 <etext+0xb0>
    80000f9e:	841ff0ef          	jal	800007de <panic>
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fa2:	020a8263          	beqz	s5,80000fc6 <walk+0x96>
    80000fa6:	b53ff0ef          	jal	80000af8 <kalloc>
    80000faa:	84aa                	mv	s1,a0
    80000fac:	d979                	beqz	a0,80000f82 <walk+0x52>
      memset(pagetable, 0, PGSIZE);
    80000fae:	6605                	lui	a2,0x1
    80000fb0:	4581                	li	a1,0
    80000fb2:	cebff0ef          	jal	80000c9c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80000fb6:	00c4d793          	srli	a5,s1,0xc
    80000fba:	07aa                	slli	a5,a5,0xa
    80000fbc:	0017e793          	ori	a5,a5,1
    80000fc0:	00f93023          	sd	a5,0(s2)
    80000fc4:	b775                	j	80000f70 <walk+0x40>
        return 0;
    80000fc6:	4501                	li	a0,0
    80000fc8:	bf6d                	j	80000f82 <walk+0x52>

0000000080000fca <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80000fca:	57fd                	li	a5,-1
    80000fcc:	83e9                	srli	a5,a5,0x1a
    80000fce:	00b7f463          	bgeu	a5,a1,80000fd6 <walkaddr+0xc>
    return 0;
    80000fd2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80000fd4:	8082                	ret
{
    80000fd6:	1141                	addi	sp,sp,-16
    80000fd8:	e406                	sd	ra,8(sp)
    80000fda:	e022                	sd	s0,0(sp)
    80000fdc:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80000fde:	4601                	li	a2,0
    80000fe0:	f51ff0ef          	jal	80000f30 <walk>
  if(pte == 0)
    80000fe4:	c105                	beqz	a0,80001004 <walkaddr+0x3a>
  if((*pte & PTE_V) == 0)
    80000fe6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80000fe8:	0117f693          	andi	a3,a5,17
    80000fec:	4745                	li	a4,17
    return 0;
    80000fee:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80000ff0:	00e68663          	beq	a3,a4,80000ffc <walkaddr+0x32>
}
    80000ff4:	60a2                	ld	ra,8(sp)
    80000ff6:	6402                	ld	s0,0(sp)
    80000ff8:	0141                	addi	sp,sp,16
    80000ffa:	8082                	ret
  pa = PTE2PA(*pte);
    80000ffc:	83a9                	srli	a5,a5,0xa
    80000ffe:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001002:	bfcd                	j	80000ff4 <walkaddr+0x2a>
    return 0;
    80001004:	4501                	li	a0,0
    80001006:	b7fd                	j	80000ff4 <walkaddr+0x2a>

0000000080001008 <mappages>:
// va and size MUST be page-aligned.
// Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001008:	715d                	addi	sp,sp,-80
    8000100a:	e486                	sd	ra,72(sp)
    8000100c:	e0a2                	sd	s0,64(sp)
    8000100e:	fc26                	sd	s1,56(sp)
    80001010:	f84a                	sd	s2,48(sp)
    80001012:	f44e                	sd	s3,40(sp)
    80001014:	f052                	sd	s4,32(sp)
    80001016:	ec56                	sd	s5,24(sp)
    80001018:	e85a                	sd	s6,16(sp)
    8000101a:	e45e                	sd	s7,8(sp)
    8000101c:	e062                	sd	s8,0(sp)
    8000101e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001020:	03459793          	slli	a5,a1,0x34
    80001024:	e7b1                	bnez	a5,80001070 <mappages+0x68>
    80001026:	8aaa                	mv	s5,a0
    80001028:	8b3a                	mv	s6,a4
    panic("mappages: va not aligned");

  if((size % PGSIZE) != 0)
    8000102a:	03461793          	slli	a5,a2,0x34
    8000102e:	e7b9                	bnez	a5,8000107c <mappages+0x74>
    panic("mappages: size not aligned");

  if(size == 0)
    80001030:	ce21                	beqz	a2,80001088 <mappages+0x80>
    panic("mappages: size");
  
  a = va;
  last = va + size - PGSIZE;
    80001032:	77fd                	lui	a5,0xfffff
    80001034:	963e                	add	a2,a2,a5
    80001036:	00b609b3          	add	s3,a2,a1
  a = va;
    8000103a:	892e                	mv	s2,a1
    8000103c:	40b68a33          	sub	s4,a3,a1
  for(;;){
    if((pte = walk(pagetable, a, 1)) == 0)
    80001040:	4b85                	li	s7,1
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001042:	6c05                	lui	s8,0x1
    80001044:	014904b3          	add	s1,s2,s4
    if((pte = walk(pagetable, a, 1)) == 0)
    80001048:	865e                	mv	a2,s7
    8000104a:	85ca                	mv	a1,s2
    8000104c:	8556                	mv	a0,s5
    8000104e:	ee3ff0ef          	jal	80000f30 <walk>
    80001052:	c539                	beqz	a0,800010a0 <mappages+0x98>
    if(*pte & PTE_V)
    80001054:	611c                	ld	a5,0(a0)
    80001056:	8b85                	andi	a5,a5,1
    80001058:	ef95                	bnez	a5,80001094 <mappages+0x8c>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000105a:	80b1                	srli	s1,s1,0xc
    8000105c:	04aa                	slli	s1,s1,0xa
    8000105e:	0164e4b3          	or	s1,s1,s6
    80001062:	0014e493          	ori	s1,s1,1
    80001066:	e104                	sd	s1,0(a0)
    if(a == last)
    80001068:	05390963          	beq	s2,s3,800010ba <mappages+0xb2>
    a += PGSIZE;
    8000106c:	9962                	add	s2,s2,s8
    if((pte = walk(pagetable, a, 1)) == 0)
    8000106e:	bfd9                	j	80001044 <mappages+0x3c>
    panic("mappages: va not aligned");
    80001070:	00006517          	auipc	a0,0x6
    80001074:	04850513          	addi	a0,a0,72 # 800070b8 <etext+0xb8>
    80001078:	f66ff0ef          	jal	800007de <panic>
    panic("mappages: size not aligned");
    8000107c:	00006517          	auipc	a0,0x6
    80001080:	05c50513          	addi	a0,a0,92 # 800070d8 <etext+0xd8>
    80001084:	f5aff0ef          	jal	800007de <panic>
    panic("mappages: size");
    80001088:	00006517          	auipc	a0,0x6
    8000108c:	07050513          	addi	a0,a0,112 # 800070f8 <etext+0xf8>
    80001090:	f4eff0ef          	jal	800007de <panic>
      panic("mappages: remap");
    80001094:	00006517          	auipc	a0,0x6
    80001098:	07450513          	addi	a0,a0,116 # 80007108 <etext+0x108>
    8000109c:	f42ff0ef          	jal	800007de <panic>
      return -1;
    800010a0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800010a2:	60a6                	ld	ra,72(sp)
    800010a4:	6406                	ld	s0,64(sp)
    800010a6:	74e2                	ld	s1,56(sp)
    800010a8:	7942                	ld	s2,48(sp)
    800010aa:	79a2                	ld	s3,40(sp)
    800010ac:	7a02                	ld	s4,32(sp)
    800010ae:	6ae2                	ld	s5,24(sp)
    800010b0:	6b42                	ld	s6,16(sp)
    800010b2:	6ba2                	ld	s7,8(sp)
    800010b4:	6c02                	ld	s8,0(sp)
    800010b6:	6161                	addi	sp,sp,80
    800010b8:	8082                	ret
  return 0;
    800010ba:	4501                	li	a0,0
    800010bc:	b7dd                	j	800010a2 <mappages+0x9a>

00000000800010be <kvmmap>:
{
    800010be:	1141                	addi	sp,sp,-16
    800010c0:	e406                	sd	ra,8(sp)
    800010c2:	e022                	sd	s0,0(sp)
    800010c4:	0800                	addi	s0,sp,16
    800010c6:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800010c8:	86b2                	mv	a3,a2
    800010ca:	863e                	mv	a2,a5
    800010cc:	f3dff0ef          	jal	80001008 <mappages>
    800010d0:	e509                	bnez	a0,800010da <kvmmap+0x1c>
}
    800010d2:	60a2                	ld	ra,8(sp)
    800010d4:	6402                	ld	s0,0(sp)
    800010d6:	0141                	addi	sp,sp,16
    800010d8:	8082                	ret
    panic("kvmmap");
    800010da:	00006517          	auipc	a0,0x6
    800010de:	03e50513          	addi	a0,a0,62 # 80007118 <etext+0x118>
    800010e2:	efcff0ef          	jal	800007de <panic>

00000000800010e6 <kvmmake>:
{
    800010e6:	1101                	addi	sp,sp,-32
    800010e8:	ec06                	sd	ra,24(sp)
    800010ea:	e822                	sd	s0,16(sp)
    800010ec:	e426                	sd	s1,8(sp)
    800010ee:	e04a                	sd	s2,0(sp)
    800010f0:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800010f2:	a07ff0ef          	jal	80000af8 <kalloc>
    800010f6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800010f8:	6605                	lui	a2,0x1
    800010fa:	4581                	li	a1,0
    800010fc:	ba1ff0ef          	jal	80000c9c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001100:	4719                	li	a4,6
    80001102:	6685                	lui	a3,0x1
    80001104:	10000637          	lui	a2,0x10000
    80001108:	85b2                	mv	a1,a2
    8000110a:	8526                	mv	a0,s1
    8000110c:	fb3ff0ef          	jal	800010be <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001110:	4719                	li	a4,6
    80001112:	6685                	lui	a3,0x1
    80001114:	10001637          	lui	a2,0x10001
    80001118:	85b2                	mv	a1,a2
    8000111a:	8526                	mv	a0,s1
    8000111c:	fa3ff0ef          	jal	800010be <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x4000000, PTE_R | PTE_W);
    80001120:	4719                	li	a4,6
    80001122:	040006b7          	lui	a3,0x4000
    80001126:	0c000637          	lui	a2,0xc000
    8000112a:	85b2                	mv	a1,a2
    8000112c:	8526                	mv	a0,s1
    8000112e:	f91ff0ef          	jal	800010be <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001132:	00006917          	auipc	s2,0x6
    80001136:	ece90913          	addi	s2,s2,-306 # 80007000 <etext>
    8000113a:	4729                	li	a4,10
    8000113c:	80006697          	auipc	a3,0x80006
    80001140:	ec468693          	addi	a3,a3,-316 # 7000 <_entry-0x7fff9000>
    80001144:	4605                	li	a2,1
    80001146:	067e                	slli	a2,a2,0x1f
    80001148:	85b2                	mv	a1,a2
    8000114a:	8526                	mv	a0,s1
    8000114c:	f73ff0ef          	jal	800010be <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001150:	4719                	li	a4,6
    80001152:	46c5                	li	a3,17
    80001154:	06ee                	slli	a3,a3,0x1b
    80001156:	412686b3          	sub	a3,a3,s2
    8000115a:	864a                	mv	a2,s2
    8000115c:	85ca                	mv	a1,s2
    8000115e:	8526                	mv	a0,s1
    80001160:	f5fff0ef          	jal	800010be <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001164:	4729                	li	a4,10
    80001166:	6685                	lui	a3,0x1
    80001168:	00005617          	auipc	a2,0x5
    8000116c:	e9860613          	addi	a2,a2,-360 # 80006000 <_trampoline>
    80001170:	040005b7          	lui	a1,0x4000
    80001174:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001176:	05b2                	slli	a1,a1,0xc
    80001178:	8526                	mv	a0,s1
    8000117a:	f45ff0ef          	jal	800010be <kvmmap>
  proc_mapstacks(kpgtbl);
    8000117e:	8526                	mv	a0,s1
    80001180:	5bc000ef          	jal	8000173c <proc_mapstacks>
}
    80001184:	8526                	mv	a0,s1
    80001186:	60e2                	ld	ra,24(sp)
    80001188:	6442                	ld	s0,16(sp)
    8000118a:	64a2                	ld	s1,8(sp)
    8000118c:	6902                	ld	s2,0(sp)
    8000118e:	6105                	addi	sp,sp,32
    80001190:	8082                	ret

0000000080001192 <kvminit>:
{
    80001192:	1141                	addi	sp,sp,-16
    80001194:	e406                	sd	ra,8(sp)
    80001196:	e022                	sd	s0,0(sp)
    80001198:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000119a:	f4dff0ef          	jal	800010e6 <kvmmake>
    8000119e:	00009797          	auipc	a5,0x9
    800011a2:	12a7b523          	sd	a0,298(a5) # 8000a2c8 <kernel_pagetable>
}
    800011a6:	60a2                	ld	ra,8(sp)
    800011a8:	6402                	ld	s0,0(sp)
    800011aa:	0141                	addi	sp,sp,16
    800011ac:	8082                	ret

00000000800011ae <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800011ae:	1101                	addi	sp,sp,-32
    800011b0:	ec06                	sd	ra,24(sp)
    800011b2:	e822                	sd	s0,16(sp)
    800011b4:	e426                	sd	s1,8(sp)
    800011b6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800011b8:	941ff0ef          	jal	80000af8 <kalloc>
    800011bc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800011be:	c509                	beqz	a0,800011c8 <uvmcreate+0x1a>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800011c0:	6605                	lui	a2,0x1
    800011c2:	4581                	li	a1,0
    800011c4:	ad9ff0ef          	jal	80000c9c <memset>
  return pagetable;
}
    800011c8:	8526                	mv	a0,s1
    800011ca:	60e2                	ld	ra,24(sp)
    800011cc:	6442                	ld	s0,16(sp)
    800011ce:	64a2                	ld	s1,8(sp)
    800011d0:	6105                	addi	sp,sp,32
    800011d2:	8082                	ret

00000000800011d4 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. It's OK if the mappings don't exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800011d4:	7139                	addi	sp,sp,-64
    800011d6:	fc06                	sd	ra,56(sp)
    800011d8:	f822                	sd	s0,48(sp)
    800011da:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800011dc:	03459793          	slli	a5,a1,0x34
    800011e0:	e38d                	bnez	a5,80001202 <uvmunmap+0x2e>
    800011e2:	f04a                	sd	s2,32(sp)
    800011e4:	ec4e                	sd	s3,24(sp)
    800011e6:	e852                	sd	s4,16(sp)
    800011e8:	e456                	sd	s5,8(sp)
    800011ea:	e05a                	sd	s6,0(sp)
    800011ec:	8a2a                	mv	s4,a0
    800011ee:	892e                	mv	s2,a1
    800011f0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800011f2:	0632                	slli	a2,a2,0xc
    800011f4:	00b609b3          	add	s3,a2,a1
    800011f8:	6b05                	lui	s6,0x1
    800011fa:	0535f963          	bgeu	a1,s3,8000124c <uvmunmap+0x78>
    800011fe:	f426                	sd	s1,40(sp)
    80001200:	a015                	j	80001224 <uvmunmap+0x50>
    80001202:	f426                	sd	s1,40(sp)
    80001204:	f04a                	sd	s2,32(sp)
    80001206:	ec4e                	sd	s3,24(sp)
    80001208:	e852                	sd	s4,16(sp)
    8000120a:	e456                	sd	s5,8(sp)
    8000120c:	e05a                	sd	s6,0(sp)
    panic("uvmunmap: not aligned");
    8000120e:	00006517          	auipc	a0,0x6
    80001212:	f1250513          	addi	a0,a0,-238 # 80007120 <etext+0x120>
    80001216:	dc8ff0ef          	jal	800007de <panic>
      continue;
    if(do_free){
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
    8000121a:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000121e:	995a                	add	s2,s2,s6
    80001220:	03397563          	bgeu	s2,s3,8000124a <uvmunmap+0x76>
    if((pte = walk(pagetable, a, 0)) == 0) // leaf page table entry allocated?
    80001224:	4601                	li	a2,0
    80001226:	85ca                	mv	a1,s2
    80001228:	8552                	mv	a0,s4
    8000122a:	d07ff0ef          	jal	80000f30 <walk>
    8000122e:	84aa                	mv	s1,a0
    80001230:	d57d                	beqz	a0,8000121e <uvmunmap+0x4a>
    if((*pte & PTE_V) == 0)  // has physical page been allocated?
    80001232:	611c                	ld	a5,0(a0)
    80001234:	0017f713          	andi	a4,a5,1
    80001238:	d37d                	beqz	a4,8000121e <uvmunmap+0x4a>
    if(do_free){
    8000123a:	fe0a80e3          	beqz	s5,8000121a <uvmunmap+0x46>
      uint64 pa = PTE2PA(*pte);
    8000123e:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001240:	00c79513          	slli	a0,a5,0xc
    80001244:	fd2ff0ef          	jal	80000a16 <kfree>
    80001248:	bfc9                	j	8000121a <uvmunmap+0x46>
    8000124a:	74a2                	ld	s1,40(sp)
    8000124c:	7902                	ld	s2,32(sp)
    8000124e:	69e2                	ld	s3,24(sp)
    80001250:	6a42                	ld	s4,16(sp)
    80001252:	6aa2                	ld	s5,8(sp)
    80001254:	6b02                	ld	s6,0(sp)
  }
}
    80001256:	70e2                	ld	ra,56(sp)
    80001258:	7442                	ld	s0,48(sp)
    8000125a:	6121                	addi	sp,sp,64
    8000125c:	8082                	ret

000000008000125e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000125e:	1101                	addi	sp,sp,-32
    80001260:	ec06                	sd	ra,24(sp)
    80001262:	e822                	sd	s0,16(sp)
    80001264:	e426                	sd	s1,8(sp)
    80001266:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001268:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000126a:	00b67d63          	bgeu	a2,a1,80001284 <uvmdealloc+0x26>
    8000126e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001270:	6785                	lui	a5,0x1
    80001272:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001274:	00f60733          	add	a4,a2,a5
    80001278:	76fd                	lui	a3,0xfffff
    8000127a:	8f75                	and	a4,a4,a3
    8000127c:	97ae                	add	a5,a5,a1
    8000127e:	8ff5                	and	a5,a5,a3
    80001280:	00f76863          	bltu	a4,a5,80001290 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001284:	8526                	mv	a0,s1
    80001286:	60e2                	ld	ra,24(sp)
    80001288:	6442                	ld	s0,16(sp)
    8000128a:	64a2                	ld	s1,8(sp)
    8000128c:	6105                	addi	sp,sp,32
    8000128e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001290:	8f99                	sub	a5,a5,a4
    80001292:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001294:	4685                	li	a3,1
    80001296:	0007861b          	sext.w	a2,a5
    8000129a:	85ba                	mv	a1,a4
    8000129c:	f39ff0ef          	jal	800011d4 <uvmunmap>
    800012a0:	b7d5                	j	80001284 <uvmdealloc+0x26>

00000000800012a2 <uvmalloc>:
  if(newsz < oldsz)
    800012a2:	0ab66363          	bltu	a2,a1,80001348 <uvmalloc+0xa6>
{
    800012a6:	715d                	addi	sp,sp,-80
    800012a8:	e486                	sd	ra,72(sp)
    800012aa:	e0a2                	sd	s0,64(sp)
    800012ac:	f052                	sd	s4,32(sp)
    800012ae:	ec56                	sd	s5,24(sp)
    800012b0:	e85a                	sd	s6,16(sp)
    800012b2:	0880                	addi	s0,sp,80
    800012b4:	8b2a                	mv	s6,a0
    800012b6:	8ab2                	mv	s5,a2
  oldsz = PGROUNDUP(oldsz);
    800012b8:	6785                	lui	a5,0x1
    800012ba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800012bc:	95be                	add	a1,a1,a5
    800012be:	77fd                	lui	a5,0xfffff
    800012c0:	00f5fa33          	and	s4,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012c4:	08ca7463          	bgeu	s4,a2,8000134c <uvmalloc+0xaa>
    800012c8:	fc26                	sd	s1,56(sp)
    800012ca:	f84a                	sd	s2,48(sp)
    800012cc:	f44e                	sd	s3,40(sp)
    800012ce:	e45e                	sd	s7,8(sp)
    800012d0:	8952                	mv	s2,s4
    memset(mem, 0, PGSIZE);
    800012d2:	6985                	lui	s3,0x1
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012d4:	0126eb93          	ori	s7,a3,18
    mem = kalloc();
    800012d8:	821ff0ef          	jal	80000af8 <kalloc>
    800012dc:	84aa                	mv	s1,a0
    if(mem == 0){
    800012de:	c515                	beqz	a0,8000130a <uvmalloc+0x68>
    memset(mem, 0, PGSIZE);
    800012e0:	864e                	mv	a2,s3
    800012e2:	4581                	li	a1,0
    800012e4:	9b9ff0ef          	jal	80000c9c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800012e8:	875e                	mv	a4,s7
    800012ea:	86a6                	mv	a3,s1
    800012ec:	864e                	mv	a2,s3
    800012ee:	85ca                	mv	a1,s2
    800012f0:	855a                	mv	a0,s6
    800012f2:	d17ff0ef          	jal	80001008 <mappages>
    800012f6:	e91d                	bnez	a0,8000132c <uvmalloc+0x8a>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800012f8:	994e                	add	s2,s2,s3
    800012fa:	fd596fe3          	bltu	s2,s5,800012d8 <uvmalloc+0x36>
  return newsz;
    800012fe:	8556                	mv	a0,s5
    80001300:	74e2                	ld	s1,56(sp)
    80001302:	7942                	ld	s2,48(sp)
    80001304:	79a2                	ld	s3,40(sp)
    80001306:	6ba2                	ld	s7,8(sp)
    80001308:	a819                	j	8000131e <uvmalloc+0x7c>
      uvmdealloc(pagetable, a, oldsz);
    8000130a:	8652                	mv	a2,s4
    8000130c:	85ca                	mv	a1,s2
    8000130e:	855a                	mv	a0,s6
    80001310:	f4fff0ef          	jal	8000125e <uvmdealloc>
      return 0;
    80001314:	4501                	li	a0,0
    80001316:	74e2                	ld	s1,56(sp)
    80001318:	7942                	ld	s2,48(sp)
    8000131a:	79a2                	ld	s3,40(sp)
    8000131c:	6ba2                	ld	s7,8(sp)
}
    8000131e:	60a6                	ld	ra,72(sp)
    80001320:	6406                	ld	s0,64(sp)
    80001322:	7a02                	ld	s4,32(sp)
    80001324:	6ae2                	ld	s5,24(sp)
    80001326:	6b42                	ld	s6,16(sp)
    80001328:	6161                	addi	sp,sp,80
    8000132a:	8082                	ret
      kfree(mem);
    8000132c:	8526                	mv	a0,s1
    8000132e:	ee8ff0ef          	jal	80000a16 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001332:	8652                	mv	a2,s4
    80001334:	85ca                	mv	a1,s2
    80001336:	855a                	mv	a0,s6
    80001338:	f27ff0ef          	jal	8000125e <uvmdealloc>
      return 0;
    8000133c:	4501                	li	a0,0
    8000133e:	74e2                	ld	s1,56(sp)
    80001340:	7942                	ld	s2,48(sp)
    80001342:	79a2                	ld	s3,40(sp)
    80001344:	6ba2                	ld	s7,8(sp)
    80001346:	bfe1                	j	8000131e <uvmalloc+0x7c>
    return oldsz;
    80001348:	852e                	mv	a0,a1
}
    8000134a:	8082                	ret
  return newsz;
    8000134c:	8532                	mv	a0,a2
    8000134e:	bfc1                	j	8000131e <uvmalloc+0x7c>

0000000080001350 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001350:	7179                	addi	sp,sp,-48
    80001352:	f406                	sd	ra,40(sp)
    80001354:	f022                	sd	s0,32(sp)
    80001356:	ec26                	sd	s1,24(sp)
    80001358:	e84a                	sd	s2,16(sp)
    8000135a:	e44e                	sd	s3,8(sp)
    8000135c:	e052                	sd	s4,0(sp)
    8000135e:	1800                	addi	s0,sp,48
    80001360:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001362:	84aa                	mv	s1,a0
    80001364:	6905                	lui	s2,0x1
    80001366:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001368:	4985                	li	s3,1
    8000136a:	a819                	j	80001380 <freewalk+0x30>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000136c:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000136e:	00c79513          	slli	a0,a5,0xc
    80001372:	fdfff0ef          	jal	80001350 <freewalk>
      pagetable[i] = 0;
    80001376:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000137a:	04a1                	addi	s1,s1,8
    8000137c:	01248f63          	beq	s1,s2,8000139a <freewalk+0x4a>
    pte_t pte = pagetable[i];
    80001380:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001382:	00f7f713          	andi	a4,a5,15
    80001386:	ff3703e3          	beq	a4,s3,8000136c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000138a:	8b85                	andi	a5,a5,1
    8000138c:	d7fd                	beqz	a5,8000137a <freewalk+0x2a>
      panic("freewalk: leaf");
    8000138e:	00006517          	auipc	a0,0x6
    80001392:	daa50513          	addi	a0,a0,-598 # 80007138 <etext+0x138>
    80001396:	c48ff0ef          	jal	800007de <panic>
    }
  }
  kfree((void*)pagetable);
    8000139a:	8552                	mv	a0,s4
    8000139c:	e7aff0ef          	jal	80000a16 <kfree>
}
    800013a0:	70a2                	ld	ra,40(sp)
    800013a2:	7402                	ld	s0,32(sp)
    800013a4:	64e2                	ld	s1,24(sp)
    800013a6:	6942                	ld	s2,16(sp)
    800013a8:	69a2                	ld	s3,8(sp)
    800013aa:	6a02                	ld	s4,0(sp)
    800013ac:	6145                	addi	sp,sp,48
    800013ae:	8082                	ret

00000000800013b0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800013b0:	1101                	addi	sp,sp,-32
    800013b2:	ec06                	sd	ra,24(sp)
    800013b4:	e822                	sd	s0,16(sp)
    800013b6:	e426                	sd	s1,8(sp)
    800013b8:	1000                	addi	s0,sp,32
    800013ba:	84aa                	mv	s1,a0
  if(sz > 0)
    800013bc:	e989                	bnez	a1,800013ce <uvmfree+0x1e>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800013be:	8526                	mv	a0,s1
    800013c0:	f91ff0ef          	jal	80001350 <freewalk>
}
    800013c4:	60e2                	ld	ra,24(sp)
    800013c6:	6442                	ld	s0,16(sp)
    800013c8:	64a2                	ld	s1,8(sp)
    800013ca:	6105                	addi	sp,sp,32
    800013cc:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800013ce:	6785                	lui	a5,0x1
    800013d0:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013d2:	95be                	add	a1,a1,a5
    800013d4:	4685                	li	a3,1
    800013d6:	00c5d613          	srli	a2,a1,0xc
    800013da:	4581                	li	a1,0
    800013dc:	df9ff0ef          	jal	800011d4 <uvmunmap>
    800013e0:	bff9                	j	800013be <uvmfree+0xe>

00000000800013e2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800013e2:	ce59                	beqz	a2,80001480 <uvmcopy+0x9e>
{
    800013e4:	715d                	addi	sp,sp,-80
    800013e6:	e486                	sd	ra,72(sp)
    800013e8:	e0a2                	sd	s0,64(sp)
    800013ea:	fc26                	sd	s1,56(sp)
    800013ec:	f84a                	sd	s2,48(sp)
    800013ee:	f44e                	sd	s3,40(sp)
    800013f0:	f052                	sd	s4,32(sp)
    800013f2:	ec56                	sd	s5,24(sp)
    800013f4:	e85a                	sd	s6,16(sp)
    800013f6:	e45e                	sd	s7,8(sp)
    800013f8:	e062                	sd	s8,0(sp)
    800013fa:	0880                	addi	s0,sp,80
    800013fc:	8b2a                	mv	s6,a0
    800013fe:	8bae                	mv	s7,a1
    80001400:	8ab2                	mv	s5,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001402:	4481                	li	s1,0
      continue;   // physical page hasn't been allocated
    pa = PTE2PA(*pte);
    flags = PTE_FLAGS(*pte);
    if((mem = kalloc()) == 0)
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001404:	6a05                	lui	s4,0x1
    80001406:	a021                	j	8000140e <uvmcopy+0x2c>
  for(i = 0; i < sz; i += PGSIZE){
    80001408:	94d2                	add	s1,s1,s4
    8000140a:	0554fe63          	bgeu	s1,s5,80001466 <uvmcopy+0x84>
    if((pte = walk(old, i, 0)) == 0)
    8000140e:	4601                	li	a2,0
    80001410:	85a6                	mv	a1,s1
    80001412:	855a                	mv	a0,s6
    80001414:	b1dff0ef          	jal	80000f30 <walk>
    80001418:	d965                	beqz	a0,80001408 <uvmcopy+0x26>
    if((*pte & PTE_V) == 0)
    8000141a:	6118                	ld	a4,0(a0)
    8000141c:	00177793          	andi	a5,a4,1
    80001420:	d7e5                	beqz	a5,80001408 <uvmcopy+0x26>
    pa = PTE2PA(*pte);
    80001422:	00a75593          	srli	a1,a4,0xa
    80001426:	00c59c13          	slli	s8,a1,0xc
    flags = PTE_FLAGS(*pte);
    8000142a:	3ff77913          	andi	s2,a4,1023
    if((mem = kalloc()) == 0)
    8000142e:	ecaff0ef          	jal	80000af8 <kalloc>
    80001432:	89aa                	mv	s3,a0
    80001434:	c105                	beqz	a0,80001454 <uvmcopy+0x72>
    memmove(mem, (char*)pa, PGSIZE);
    80001436:	8652                	mv	a2,s4
    80001438:	85e2                	mv	a1,s8
    8000143a:	8c7ff0ef          	jal	80000d00 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000143e:	874a                	mv	a4,s2
    80001440:	86ce                	mv	a3,s3
    80001442:	8652                	mv	a2,s4
    80001444:	85a6                	mv	a1,s1
    80001446:	855e                	mv	a0,s7
    80001448:	bc1ff0ef          	jal	80001008 <mappages>
    8000144c:	dd55                	beqz	a0,80001408 <uvmcopy+0x26>
      kfree(mem);
    8000144e:	854e                	mv	a0,s3
    80001450:	dc6ff0ef          	jal	80000a16 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001454:	4685                	li	a3,1
    80001456:	00c4d613          	srli	a2,s1,0xc
    8000145a:	4581                	li	a1,0
    8000145c:	855e                	mv	a0,s7
    8000145e:	d77ff0ef          	jal	800011d4 <uvmunmap>
  return -1;
    80001462:	557d                	li	a0,-1
    80001464:	a011                	j	80001468 <uvmcopy+0x86>
  return 0;
    80001466:	4501                	li	a0,0
}
    80001468:	60a6                	ld	ra,72(sp)
    8000146a:	6406                	ld	s0,64(sp)
    8000146c:	74e2                	ld	s1,56(sp)
    8000146e:	7942                	ld	s2,48(sp)
    80001470:	79a2                	ld	s3,40(sp)
    80001472:	7a02                	ld	s4,32(sp)
    80001474:	6ae2                	ld	s5,24(sp)
    80001476:	6b42                	ld	s6,16(sp)
    80001478:	6ba2                	ld	s7,8(sp)
    8000147a:	6c02                	ld	s8,0(sp)
    8000147c:	6161                	addi	sp,sp,80
    8000147e:	8082                	ret
  return 0;
    80001480:	4501                	li	a0,0
}
    80001482:	8082                	ret

0000000080001484 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001484:	1141                	addi	sp,sp,-16
    80001486:	e406                	sd	ra,8(sp)
    80001488:	e022                	sd	s0,0(sp)
    8000148a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000148c:	4601                	li	a2,0
    8000148e:	aa3ff0ef          	jal	80000f30 <walk>
  if(pte == 0)
    80001492:	c901                	beqz	a0,800014a2 <uvmclear+0x1e>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001494:	611c                	ld	a5,0(a0)
    80001496:	9bbd                	andi	a5,a5,-17
    80001498:	e11c                	sd	a5,0(a0)
}
    8000149a:	60a2                	ld	ra,8(sp)
    8000149c:	6402                	ld	s0,0(sp)
    8000149e:	0141                	addi	sp,sp,16
    800014a0:	8082                	ret
    panic("uvmclear");
    800014a2:	00006517          	auipc	a0,0x6
    800014a6:	ca650513          	addi	a0,a0,-858 # 80007148 <etext+0x148>
    800014aa:	b34ff0ef          	jal	800007de <panic>

00000000800014ae <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800014ae:	715d                	addi	sp,sp,-80
    800014b0:	e486                	sd	ra,72(sp)
    800014b2:	e0a2                	sd	s0,64(sp)
    800014b4:	fc26                	sd	s1,56(sp)
    800014b6:	f84a                	sd	s2,48(sp)
    800014b8:	f44e                	sd	s3,40(sp)
    800014ba:	f052                	sd	s4,32(sp)
    800014bc:	ec56                	sd	s5,24(sp)
    800014be:	e85a                	sd	s6,16(sp)
    800014c0:	e45e                	sd	s7,8(sp)
    800014c2:	0880                	addi	s0,sp,80
    800014c4:	8aaa                	mv	s5,a0
    800014c6:	89ae                	mv	s3,a1
    800014c8:	8bb2                	mv	s7,a2
    800014ca:	84b6                	mv	s1,a3
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    va0 = PGROUNDDOWN(srcva);
    800014cc:	7b7d                	lui	s6,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800014ce:	6a05                	lui	s4,0x1
    800014d0:	a02d                	j	800014fa <copyinstr+0x4c>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800014d2:	00078023          	sb	zero,0(a5)
    800014d6:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800014d8:	0017c793          	xori	a5,a5,1
    800014dc:	40f0053b          	negw	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800014e0:	60a6                	ld	ra,72(sp)
    800014e2:	6406                	ld	s0,64(sp)
    800014e4:	74e2                	ld	s1,56(sp)
    800014e6:	7942                	ld	s2,48(sp)
    800014e8:	79a2                	ld	s3,40(sp)
    800014ea:	7a02                	ld	s4,32(sp)
    800014ec:	6ae2                	ld	s5,24(sp)
    800014ee:	6b42                	ld	s6,16(sp)
    800014f0:	6ba2                	ld	s7,8(sp)
    800014f2:	6161                	addi	sp,sp,80
    800014f4:	8082                	ret
    srcva = va0 + PGSIZE;
    800014f6:	01490bb3          	add	s7,s2,s4
  while(got_null == 0 && max > 0){
    800014fa:	c4b1                	beqz	s1,80001546 <copyinstr+0x98>
    va0 = PGROUNDDOWN(srcva);
    800014fc:	016bf933          	and	s2,s7,s6
    pa0 = walkaddr(pagetable, va0);
    80001500:	85ca                	mv	a1,s2
    80001502:	8556                	mv	a0,s5
    80001504:	ac7ff0ef          	jal	80000fca <walkaddr>
    if(pa0 == 0)
    80001508:	c129                	beqz	a0,8000154a <copyinstr+0x9c>
    n = PGSIZE - (srcva - va0);
    8000150a:	41790633          	sub	a2,s2,s7
    8000150e:	9652                	add	a2,a2,s4
    if(n > max)
    80001510:	00c4f363          	bgeu	s1,a2,80001516 <copyinstr+0x68>
    80001514:	8626                	mv	a2,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001516:	412b8bb3          	sub	s7,s7,s2
    8000151a:	9baa                	add	s7,s7,a0
    while(n > 0){
    8000151c:	de69                	beqz	a2,800014f6 <copyinstr+0x48>
    8000151e:	87ce                	mv	a5,s3
      if(*p == '\0'){
    80001520:	413b86b3          	sub	a3,s7,s3
    while(n > 0){
    80001524:	964e                	add	a2,a2,s3
    80001526:	85be                	mv	a1,a5
      if(*p == '\0'){
    80001528:	00f68733          	add	a4,a3,a5
    8000152c:	00074703          	lbu	a4,0(a4)
    80001530:	d34d                	beqz	a4,800014d2 <copyinstr+0x24>
        *dst = *p;
    80001532:	00e78023          	sb	a4,0(a5)
      dst++;
    80001536:	0785                	addi	a5,a5,1
    while(n > 0){
    80001538:	fec797e3          	bne	a5,a2,80001526 <copyinstr+0x78>
    8000153c:	14fd                	addi	s1,s1,-1
    8000153e:	94ce                	add	s1,s1,s3
      --max;
    80001540:	8c8d                	sub	s1,s1,a1
    80001542:	89be                	mv	s3,a5
    80001544:	bf4d                	j	800014f6 <copyinstr+0x48>
    80001546:	4781                	li	a5,0
    80001548:	bf41                	j	800014d8 <copyinstr+0x2a>
      return -1;
    8000154a:	557d                	li	a0,-1
    8000154c:	bf51                	j	800014e0 <copyinstr+0x32>

000000008000154e <ismapped>:
  return mem;
}

int
ismapped(pagetable_t pagetable, uint64 va)
{
    8000154e:	1141                	addi	sp,sp,-16
    80001550:	e406                	sd	ra,8(sp)
    80001552:	e022                	sd	s0,0(sp)
    80001554:	0800                	addi	s0,sp,16
  pte_t *pte = walk(pagetable, va, 0);
    80001556:	4601                	li	a2,0
    80001558:	9d9ff0ef          	jal	80000f30 <walk>
  if (pte == 0) {
    8000155c:	c519                	beqz	a0,8000156a <ismapped+0x1c>
    return 0;
  }
  if (*pte & PTE_V){
    8000155e:	6108                	ld	a0,0(a0)
    80001560:	8905                	andi	a0,a0,1
    return 1;
  }
  return 0;
}
    80001562:	60a2                	ld	ra,8(sp)
    80001564:	6402                	ld	s0,0(sp)
    80001566:	0141                	addi	sp,sp,16
    80001568:	8082                	ret
    return 0;
    8000156a:	4501                	li	a0,0
    8000156c:	bfdd                	j	80001562 <ismapped+0x14>

000000008000156e <vmfault>:
{
    8000156e:	7179                	addi	sp,sp,-48
    80001570:	f406                	sd	ra,40(sp)
    80001572:	f022                	sd	s0,32(sp)
    80001574:	ec26                	sd	s1,24(sp)
    80001576:	e44e                	sd	s3,8(sp)
    80001578:	1800                	addi	s0,sp,48
    8000157a:	89aa                	mv	s3,a0
    8000157c:	84ae                	mv	s1,a1
  struct proc *p = myproc();
    8000157e:	340000ef          	jal	800018be <myproc>
  if (va >= p->sz)
    80001582:	653c                	ld	a5,72(a0)
    80001584:	00f4ea63          	bltu	s1,a5,80001598 <vmfault+0x2a>
    return 0;
    80001588:	4981                	li	s3,0
}
    8000158a:	854e                	mv	a0,s3
    8000158c:	70a2                	ld	ra,40(sp)
    8000158e:	7402                	ld	s0,32(sp)
    80001590:	64e2                	ld	s1,24(sp)
    80001592:	69a2                	ld	s3,8(sp)
    80001594:	6145                	addi	sp,sp,48
    80001596:	8082                	ret
    80001598:	e84a                	sd	s2,16(sp)
    8000159a:	892a                	mv	s2,a0
  va = PGROUNDDOWN(va);
    8000159c:	77fd                	lui	a5,0xfffff
    8000159e:	8cfd                	and	s1,s1,a5
  if(ismapped(pagetable, va)) {
    800015a0:	85a6                	mv	a1,s1
    800015a2:	854e                	mv	a0,s3
    800015a4:	fabff0ef          	jal	8000154e <ismapped>
    return 0;
    800015a8:	4981                	li	s3,0
  if(ismapped(pagetable, va)) {
    800015aa:	c119                	beqz	a0,800015b0 <vmfault+0x42>
    800015ac:	6942                	ld	s2,16(sp)
    800015ae:	bff1                	j	8000158a <vmfault+0x1c>
    800015b0:	e052                	sd	s4,0(sp)
  mem = (uint64) kalloc();
    800015b2:	d46ff0ef          	jal	80000af8 <kalloc>
    800015b6:	8a2a                	mv	s4,a0
  if(mem == 0)
    800015b8:	c90d                	beqz	a0,800015ea <vmfault+0x7c>
  mem = (uint64) kalloc();
    800015ba:	89aa                	mv	s3,a0
  memset((void *) mem, 0, PGSIZE);
    800015bc:	6605                	lui	a2,0x1
    800015be:	4581                	li	a1,0
    800015c0:	edcff0ef          	jal	80000c9c <memset>
  if (mappages(p->pagetable, va, PGSIZE, mem, PTE_W|PTE_U|PTE_R) != 0) {
    800015c4:	4759                	li	a4,22
    800015c6:	86d2                	mv	a3,s4
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85a6                	mv	a1,s1
    800015cc:	05093503          	ld	a0,80(s2) # 1050 <_entry-0x7fffefb0>
    800015d0:	a39ff0ef          	jal	80001008 <mappages>
    800015d4:	e501                	bnez	a0,800015dc <vmfault+0x6e>
    800015d6:	6942                	ld	s2,16(sp)
    800015d8:	6a02                	ld	s4,0(sp)
    800015da:	bf45                	j	8000158a <vmfault+0x1c>
    kfree((void *)mem);
    800015dc:	8552                	mv	a0,s4
    800015de:	c38ff0ef          	jal	80000a16 <kfree>
    return 0;
    800015e2:	4981                	li	s3,0
    800015e4:	6942                	ld	s2,16(sp)
    800015e6:	6a02                	ld	s4,0(sp)
    800015e8:	b74d                	j	8000158a <vmfault+0x1c>
    800015ea:	6942                	ld	s2,16(sp)
    800015ec:	6a02                	ld	s4,0(sp)
    800015ee:	bf71                	j	8000158a <vmfault+0x1c>

00000000800015f0 <copyout>:
  while(len > 0){
    800015f0:	cad1                	beqz	a3,80001684 <copyout+0x94>
{
    800015f2:	711d                	addi	sp,sp,-96
    800015f4:	ec86                	sd	ra,88(sp)
    800015f6:	e8a2                	sd	s0,80(sp)
    800015f8:	e4a6                	sd	s1,72(sp)
    800015fa:	e0ca                	sd	s2,64(sp)
    800015fc:	fc4e                	sd	s3,56(sp)
    800015fe:	f852                	sd	s4,48(sp)
    80001600:	f456                	sd	s5,40(sp)
    80001602:	f05a                	sd	s6,32(sp)
    80001604:	ec5e                	sd	s7,24(sp)
    80001606:	e862                	sd	s8,16(sp)
    80001608:	e466                	sd	s9,8(sp)
    8000160a:	e06a                	sd	s10,0(sp)
    8000160c:	1080                	addi	s0,sp,96
    8000160e:	8baa                	mv	s7,a0
    80001610:	8a2e                	mv	s4,a1
    80001612:	8b32                	mv	s6,a2
    80001614:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(dstva);
    80001616:	7d7d                	lui	s10,0xfffff
    if(va0 >= MAXVA)
    80001618:	5cfd                	li	s9,-1
    8000161a:	01acdc93          	srli	s9,s9,0x1a
    n = PGSIZE - (dstva - va0);
    8000161e:	6c05                	lui	s8,0x1
    80001620:	a005                	j	80001640 <copyout+0x50>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001622:	409a0533          	sub	a0,s4,s1
    80001626:	0009061b          	sext.w	a2,s2
    8000162a:	85da                	mv	a1,s6
    8000162c:	954e                	add	a0,a0,s3
    8000162e:	ed2ff0ef          	jal	80000d00 <memmove>
    len -= n;
    80001632:	412a8ab3          	sub	s5,s5,s2
    src += n;
    80001636:	9b4a                	add	s6,s6,s2
    dstva = va0 + PGSIZE;
    80001638:	01848a33          	add	s4,s1,s8
  while(len > 0){
    8000163c:	040a8263          	beqz	s5,80001680 <copyout+0x90>
    va0 = PGROUNDDOWN(dstva);
    80001640:	01aa74b3          	and	s1,s4,s10
    if(va0 >= MAXVA)
    80001644:	049ce263          	bltu	s9,s1,80001688 <copyout+0x98>
    pa0 = walkaddr(pagetable, va0);
    80001648:	85a6                	mv	a1,s1
    8000164a:	855e                	mv	a0,s7
    8000164c:	97fff0ef          	jal	80000fca <walkaddr>
    80001650:	89aa                	mv	s3,a0
    if(pa0 == 0) {
    80001652:	e901                	bnez	a0,80001662 <copyout+0x72>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    80001654:	4601                	li	a2,0
    80001656:	85a6                	mv	a1,s1
    80001658:	855e                	mv	a0,s7
    8000165a:	f15ff0ef          	jal	8000156e <vmfault>
    8000165e:	89aa                	mv	s3,a0
    80001660:	c139                	beqz	a0,800016a6 <copyout+0xb6>
    pte = walk(pagetable, va0, 0);
    80001662:	4601                	li	a2,0
    80001664:	85a6                	mv	a1,s1
    80001666:	855e                	mv	a0,s7
    80001668:	8c9ff0ef          	jal	80000f30 <walk>
    if((*pte & PTE_W) == 0)
    8000166c:	611c                	ld	a5,0(a0)
    8000166e:	8b91                	andi	a5,a5,4
    80001670:	cf8d                	beqz	a5,800016aa <copyout+0xba>
    n = PGSIZE - (dstva - va0);
    80001672:	41448933          	sub	s2,s1,s4
    80001676:	9962                	add	s2,s2,s8
    if(n > len)
    80001678:	fb2af5e3          	bgeu	s5,s2,80001622 <copyout+0x32>
    8000167c:	8956                	mv	s2,s5
    8000167e:	b755                	j	80001622 <copyout+0x32>
  return 0;
    80001680:	4501                	li	a0,0
    80001682:	a021                	j	8000168a <copyout+0x9a>
    80001684:	4501                	li	a0,0
}
    80001686:	8082                	ret
      return -1;
    80001688:	557d                	li	a0,-1
}
    8000168a:	60e6                	ld	ra,88(sp)
    8000168c:	6446                	ld	s0,80(sp)
    8000168e:	64a6                	ld	s1,72(sp)
    80001690:	6906                	ld	s2,64(sp)
    80001692:	79e2                	ld	s3,56(sp)
    80001694:	7a42                	ld	s4,48(sp)
    80001696:	7aa2                	ld	s5,40(sp)
    80001698:	7b02                	ld	s6,32(sp)
    8000169a:	6be2                	ld	s7,24(sp)
    8000169c:	6c42                	ld	s8,16(sp)
    8000169e:	6ca2                	ld	s9,8(sp)
    800016a0:	6d02                	ld	s10,0(sp)
    800016a2:	6125                	addi	sp,sp,96
    800016a4:	8082                	ret
        return -1;
    800016a6:	557d                	li	a0,-1
    800016a8:	b7cd                	j	8000168a <copyout+0x9a>
      return -1;
    800016aa:	557d                	li	a0,-1
    800016ac:	bff9                	j	8000168a <copyout+0x9a>

00000000800016ae <copyin>:
  while(len > 0){
    800016ae:	c6c9                	beqz	a3,80001738 <copyin+0x8a>
{
    800016b0:	715d                	addi	sp,sp,-80
    800016b2:	e486                	sd	ra,72(sp)
    800016b4:	e0a2                	sd	s0,64(sp)
    800016b6:	fc26                	sd	s1,56(sp)
    800016b8:	f84a                	sd	s2,48(sp)
    800016ba:	f44e                	sd	s3,40(sp)
    800016bc:	f052                	sd	s4,32(sp)
    800016be:	ec56                	sd	s5,24(sp)
    800016c0:	e85a                	sd	s6,16(sp)
    800016c2:	e45e                	sd	s7,8(sp)
    800016c4:	e062                	sd	s8,0(sp)
    800016c6:	0880                	addi	s0,sp,80
    800016c8:	8baa                	mv	s7,a0
    800016ca:	8aae                	mv	s5,a1
    800016cc:	8932                	mv	s2,a2
    800016ce:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    800016d0:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    800016d2:	6b05                	lui	s6,0x1
    800016d4:	a035                	j	80001700 <copyin+0x52>
    800016d6:	412984b3          	sub	s1,s3,s2
    800016da:	94da                	add	s1,s1,s6
    if(n > len)
    800016dc:	009a7363          	bgeu	s4,s1,800016e2 <copyin+0x34>
    800016e0:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800016e2:	413905b3          	sub	a1,s2,s3
    800016e6:	0004861b          	sext.w	a2,s1
    800016ea:	95aa                	add	a1,a1,a0
    800016ec:	8556                	mv	a0,s5
    800016ee:	e12ff0ef          	jal	80000d00 <memmove>
    len -= n;
    800016f2:	409a0a33          	sub	s4,s4,s1
    dst += n;
    800016f6:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    800016f8:	01698933          	add	s2,s3,s6
  while(len > 0){
    800016fc:	020a0163          	beqz	s4,8000171e <copyin+0x70>
    va0 = PGROUNDDOWN(srcva);
    80001700:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001704:	85ce                	mv	a1,s3
    80001706:	855e                	mv	a0,s7
    80001708:	8c3ff0ef          	jal	80000fca <walkaddr>
    if(pa0 == 0) {
    8000170c:	f569                	bnez	a0,800016d6 <copyin+0x28>
      if((pa0 = vmfault(pagetable, va0, 0)) == 0) {
    8000170e:	4601                	li	a2,0
    80001710:	85ce                	mv	a1,s3
    80001712:	855e                	mv	a0,s7
    80001714:	e5bff0ef          	jal	8000156e <vmfault>
    80001718:	fd5d                	bnez	a0,800016d6 <copyin+0x28>
        return -1;
    8000171a:	557d                	li	a0,-1
    8000171c:	a011                	j	80001720 <copyin+0x72>
  return 0;
    8000171e:	4501                	li	a0,0
}
    80001720:	60a6                	ld	ra,72(sp)
    80001722:	6406                	ld	s0,64(sp)
    80001724:	74e2                	ld	s1,56(sp)
    80001726:	7942                	ld	s2,48(sp)
    80001728:	79a2                	ld	s3,40(sp)
    8000172a:	7a02                	ld	s4,32(sp)
    8000172c:	6ae2                	ld	s5,24(sp)
    8000172e:	6b42                	ld	s6,16(sp)
    80001730:	6ba2                	ld	s7,8(sp)
    80001732:	6c02                	ld	s8,0(sp)
    80001734:	6161                	addi	sp,sp,80
    80001736:	8082                	ret
  return 0;
    80001738:	4501                	li	a0,0
}
    8000173a:	8082                	ret

000000008000173c <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    8000173c:	715d                	addi	sp,sp,-80
    8000173e:	e486                	sd	ra,72(sp)
    80001740:	e0a2                	sd	s0,64(sp)
    80001742:	fc26                	sd	s1,56(sp)
    80001744:	f84a                	sd	s2,48(sp)
    80001746:	f44e                	sd	s3,40(sp)
    80001748:	f052                	sd	s4,32(sp)
    8000174a:	ec56                	sd	s5,24(sp)
    8000174c:	e85a                	sd	s6,16(sp)
    8000174e:	e45e                	sd	s7,8(sp)
    80001750:	e062                	sd	s8,0(sp)
    80001752:	0880                	addi	s0,sp,80
    80001754:	8a2a                	mv	s4,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001756:	00011497          	auipc	s1,0x11
    8000175a:	0b248493          	addi	s1,s1,178 # 80012808 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000175e:	8c26                	mv	s8,s1
    80001760:	a4fa57b7          	lui	a5,0xa4fa5
    80001764:	fa578793          	addi	a5,a5,-91 # ffffffffa4fa4fa5 <end+0xffffffff24f819bd>
    80001768:	4fa50937          	lui	s2,0x4fa50
    8000176c:	a5090913          	addi	s2,s2,-1456 # 4fa4fa50 <_entry-0x305b05b0>
    80001770:	1902                	slli	s2,s2,0x20
    80001772:	993e                	add	s2,s2,a5
    80001774:	040009b7          	lui	s3,0x4000
    80001778:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    8000177a:	09b2                	slli	s3,s3,0xc
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000177c:	4b99                	li	s7,6
    8000177e:	6b05                	lui	s6,0x1
  for(p = proc; p < &proc[NPROC]; p++) {
    80001780:	00017a97          	auipc	s5,0x17
    80001784:	a88a8a93          	addi	s5,s5,-1400 # 80018208 <tickslock>
    char *pa = kalloc();
    80001788:	b70ff0ef          	jal	80000af8 <kalloc>
    8000178c:	862a                	mv	a2,a0
    if(pa == 0)
    8000178e:	c121                	beqz	a0,800017ce <proc_mapstacks+0x92>
    uint64 va = KSTACK((int) (p - proc));
    80001790:	418485b3          	sub	a1,s1,s8
    80001794:	858d                	srai	a1,a1,0x3
    80001796:	032585b3          	mul	a1,a1,s2
    8000179a:	2585                	addiw	a1,a1,1
    8000179c:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800017a0:	875e                	mv	a4,s7
    800017a2:	86da                	mv	a3,s6
    800017a4:	40b985b3          	sub	a1,s3,a1
    800017a8:	8552                	mv	a0,s4
    800017aa:	915ff0ef          	jal	800010be <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800017ae:	16848493          	addi	s1,s1,360
    800017b2:	fd549be3          	bne	s1,s5,80001788 <proc_mapstacks+0x4c>
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6c02                	ld	s8,0(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
      panic("kalloc");
    800017ce:	00006517          	auipc	a0,0x6
    800017d2:	98a50513          	addi	a0,a0,-1654 # 80007158 <etext+0x158>
    800017d6:	808ff0ef          	jal	800007de <panic>

00000000800017da <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800017da:	7139                	addi	sp,sp,-64
    800017dc:	fc06                	sd	ra,56(sp)
    800017de:	f822                	sd	s0,48(sp)
    800017e0:	f426                	sd	s1,40(sp)
    800017e2:	f04a                	sd	s2,32(sp)
    800017e4:	ec4e                	sd	s3,24(sp)
    800017e6:	e852                	sd	s4,16(sp)
    800017e8:	e456                	sd	s5,8(sp)
    800017ea:	e05a                	sd	s6,0(sp)
    800017ec:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800017ee:	00006597          	auipc	a1,0x6
    800017f2:	97258593          	addi	a1,a1,-1678 # 80007160 <etext+0x160>
    800017f6:	00011517          	auipc	a0,0x11
    800017fa:	be250513          	addi	a0,a0,-1054 # 800123d8 <pid_lock>
    800017fe:	b4aff0ef          	jal	80000b48 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001802:	00006597          	auipc	a1,0x6
    80001806:	96658593          	addi	a1,a1,-1690 # 80007168 <etext+0x168>
    8000180a:	00011517          	auipc	a0,0x11
    8000180e:	be650513          	addi	a0,a0,-1050 # 800123f0 <wait_lock>
    80001812:	b36ff0ef          	jal	80000b48 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001816:	00011497          	auipc	s1,0x11
    8000181a:	ff248493          	addi	s1,s1,-14 # 80012808 <proc>
      initlock(&p->lock, "proc");
    8000181e:	00006b17          	auipc	s6,0x6
    80001822:	95ab0b13          	addi	s6,s6,-1702 # 80007178 <etext+0x178>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001826:	8aa6                	mv	s5,s1
    80001828:	a4fa57b7          	lui	a5,0xa4fa5
    8000182c:	fa578793          	addi	a5,a5,-91 # ffffffffa4fa4fa5 <end+0xffffffff24f819bd>
    80001830:	4fa50937          	lui	s2,0x4fa50
    80001834:	a5090913          	addi	s2,s2,-1456 # 4fa4fa50 <_entry-0x305b05b0>
    80001838:	1902                	slli	s2,s2,0x20
    8000183a:	993e                	add	s2,s2,a5
    8000183c:	040009b7          	lui	s3,0x4000
    80001840:	19fd                	addi	s3,s3,-1 # 3ffffff <_entry-0x7c000001>
    80001842:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001844:	00017a17          	auipc	s4,0x17
    80001848:	9c4a0a13          	addi	s4,s4,-1596 # 80018208 <tickslock>
      initlock(&p->lock, "proc");
    8000184c:	85da                	mv	a1,s6
    8000184e:	8526                	mv	a0,s1
    80001850:	af8ff0ef          	jal	80000b48 <initlock>
      p->state = UNUSED;
    80001854:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001858:	415487b3          	sub	a5,s1,s5
    8000185c:	878d                	srai	a5,a5,0x3
    8000185e:	032787b3          	mul	a5,a5,s2
    80001862:	2785                	addiw	a5,a5,1
    80001864:	00d7979b          	slliw	a5,a5,0xd
    80001868:	40f987b3          	sub	a5,s3,a5
    8000186c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000186e:	16848493          	addi	s1,s1,360
    80001872:	fd449de3          	bne	s1,s4,8000184c <procinit+0x72>
  }
}
    80001876:	70e2                	ld	ra,56(sp)
    80001878:	7442                	ld	s0,48(sp)
    8000187a:	74a2                	ld	s1,40(sp)
    8000187c:	7902                	ld	s2,32(sp)
    8000187e:	69e2                	ld	s3,24(sp)
    80001880:	6a42                	ld	s4,16(sp)
    80001882:	6aa2                	ld	s5,8(sp)
    80001884:	6b02                	ld	s6,0(sp)
    80001886:	6121                	addi	sp,sp,64
    80001888:	8082                	ret

000000008000188a <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    8000188a:	1141                	addi	sp,sp,-16
    8000188c:	e406                	sd	ra,8(sp)
    8000188e:	e022                	sd	s0,0(sp)
    80001890:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001892:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001894:	2501                	sext.w	a0,a0
    80001896:	60a2                	ld	ra,8(sp)
    80001898:	6402                	ld	s0,0(sp)
    8000189a:	0141                	addi	sp,sp,16
    8000189c:	8082                	ret

000000008000189e <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    8000189e:	1141                	addi	sp,sp,-16
    800018a0:	e406                	sd	ra,8(sp)
    800018a2:	e022                	sd	s0,0(sp)
    800018a4:	0800                	addi	s0,sp,16
    800018a6:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800018a8:	2781                	sext.w	a5,a5
    800018aa:	079e                	slli	a5,a5,0x7
  return c;
}
    800018ac:	00011517          	auipc	a0,0x11
    800018b0:	b5c50513          	addi	a0,a0,-1188 # 80012408 <cpus>
    800018b4:	953e                	add	a0,a0,a5
    800018b6:	60a2                	ld	ra,8(sp)
    800018b8:	6402                	ld	s0,0(sp)
    800018ba:	0141                	addi	sp,sp,16
    800018bc:	8082                	ret

00000000800018be <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800018be:	1101                	addi	sp,sp,-32
    800018c0:	ec06                	sd	ra,24(sp)
    800018c2:	e822                	sd	s0,16(sp)
    800018c4:	e426                	sd	s1,8(sp)
    800018c6:	1000                	addi	s0,sp,32
  push_off();
    800018c8:	ac4ff0ef          	jal	80000b8c <push_off>
    800018cc:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800018ce:	2781                	sext.w	a5,a5
    800018d0:	079e                	slli	a5,a5,0x7
    800018d2:	00011717          	auipc	a4,0x11
    800018d6:	b0670713          	addi	a4,a4,-1274 # 800123d8 <pid_lock>
    800018da:	97ba                	add	a5,a5,a4
    800018dc:	7b84                	ld	s1,48(a5)
  pop_off();
    800018de:	b32ff0ef          	jal	80000c10 <pop_off>
  return p;
}
    800018e2:	8526                	mv	a0,s1
    800018e4:	60e2                	ld	ra,24(sp)
    800018e6:	6442                	ld	s0,16(sp)
    800018e8:	64a2                	ld	s1,8(sp)
    800018ea:	6105                	addi	sp,sp,32
    800018ec:	8082                	ret

00000000800018ee <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800018ee:	7179                	addi	sp,sp,-48
    800018f0:	f406                	sd	ra,40(sp)
    800018f2:	f022                	sd	s0,32(sp)
    800018f4:	ec26                	sd	s1,24(sp)
    800018f6:	1800                	addi	s0,sp,48
  extern char userret[];
  static int first = 1;
  struct proc *p = myproc();
    800018f8:	fc7ff0ef          	jal	800018be <myproc>
    800018fc:	84aa                	mv	s1,a0

  // Still holding p->lock from scheduler.
  release(&p->lock);
    800018fe:	b62ff0ef          	jal	80000c60 <release>

  if (first) {
    80001902:	00009797          	auipc	a5,0x9
    80001906:	97e7a783          	lw	a5,-1666(a5) # 8000a280 <first.1>
    8000190a:	cf8d                	beqz	a5,80001944 <forkret+0x56>
    // File system initialization must be run in the context of a
    // regular process (e.g., because it calls sleep), and thus cannot
    // be run from main().
    fsinit(ROOTDEV);
    8000190c:	4505                	li	a0,1
    8000190e:	43d010ef          	jal	8000354a <fsinit>

    first = 0;
    80001912:	00009797          	auipc	a5,0x9
    80001916:	9607a723          	sw	zero,-1682(a5) # 8000a280 <first.1>
    // ensure other cores see first=0.
    __sync_synchronize();
    8000191a:	0330000f          	fence	rw,rw

    // We can invoke kexec() now that file system is initialized.
    // Put the return value (argc) of kexec into a0.
    p->trapframe->a0 = kexec("/init", (char *[]){ "/init", 0 });
    8000191e:	00006517          	auipc	a0,0x6
    80001922:	86250513          	addi	a0,a0,-1950 # 80007180 <etext+0x180>
    80001926:	fca43823          	sd	a0,-48(s0)
    8000192a:	fc043c23          	sd	zero,-40(s0)
    8000192e:	fd040593          	addi	a1,s0,-48
    80001932:	579020ef          	jal	800046aa <kexec>
    80001936:	6cbc                	ld	a5,88(s1)
    80001938:	fba8                	sd	a0,112(a5)
    if (p->trapframe->a0 == -1) {
    8000193a:	6cbc                	ld	a5,88(s1)
    8000193c:	7bb8                	ld	a4,112(a5)
    8000193e:	57fd                	li	a5,-1
    80001940:	02f70d63          	beq	a4,a5,8000197a <forkret+0x8c>
      panic("exec");
    }
  }

  // return to user space, mimicing usertrap()'s return.
  prepare_return();
    80001944:	2bd000ef          	jal	80002400 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    80001948:	68a8                	ld	a0,80(s1)
    8000194a:	8131                	srli	a0,a0,0xc
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000194c:	04000737          	lui	a4,0x4000
    80001950:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    80001952:	0732                	slli	a4,a4,0xc
    80001954:	00004797          	auipc	a5,0x4
    80001958:	74878793          	addi	a5,a5,1864 # 8000609c <userret>
    8000195c:	00004697          	auipc	a3,0x4
    80001960:	6a468693          	addi	a3,a3,1700 # 80006000 <_trampoline>
    80001964:	8f95                	sub	a5,a5,a3
    80001966:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80001968:	577d                	li	a4,-1
    8000196a:	177e                	slli	a4,a4,0x3f
    8000196c:	8d59                	or	a0,a0,a4
    8000196e:	9782                	jalr	a5
}
    80001970:	70a2                	ld	ra,40(sp)
    80001972:	7402                	ld	s0,32(sp)
    80001974:	64e2                	ld	s1,24(sp)
    80001976:	6145                	addi	sp,sp,48
    80001978:	8082                	ret
      panic("exec");
    8000197a:	00006517          	auipc	a0,0x6
    8000197e:	80e50513          	addi	a0,a0,-2034 # 80007188 <etext+0x188>
    80001982:	e5dfe0ef          	jal	800007de <panic>

0000000080001986 <allocpid>:
{
    80001986:	1101                	addi	sp,sp,-32
    80001988:	ec06                	sd	ra,24(sp)
    8000198a:	e822                	sd	s0,16(sp)
    8000198c:	e426                	sd	s1,8(sp)
    8000198e:	e04a                	sd	s2,0(sp)
    80001990:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001992:	00011917          	auipc	s2,0x11
    80001996:	a4690913          	addi	s2,s2,-1466 # 800123d8 <pid_lock>
    8000199a:	854a                	mv	a0,s2
    8000199c:	a30ff0ef          	jal	80000bcc <acquire>
  pid = nextpid;
    800019a0:	00009797          	auipc	a5,0x9
    800019a4:	8e478793          	addi	a5,a5,-1820 # 8000a284 <nextpid>
    800019a8:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    800019aa:	0014871b          	addiw	a4,s1,1
    800019ae:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    800019b0:	854a                	mv	a0,s2
    800019b2:	aaeff0ef          	jal	80000c60 <release>
}
    800019b6:	8526                	mv	a0,s1
    800019b8:	60e2                	ld	ra,24(sp)
    800019ba:	6442                	ld	s0,16(sp)
    800019bc:	64a2                	ld	s1,8(sp)
    800019be:	6902                	ld	s2,0(sp)
    800019c0:	6105                	addi	sp,sp,32
    800019c2:	8082                	ret

00000000800019c4 <proc_pagetable>:
{
    800019c4:	1101                	addi	sp,sp,-32
    800019c6:	ec06                	sd	ra,24(sp)
    800019c8:	e822                	sd	s0,16(sp)
    800019ca:	e426                	sd	s1,8(sp)
    800019cc:	e04a                	sd	s2,0(sp)
    800019ce:	1000                	addi	s0,sp,32
    800019d0:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800019d2:	fdcff0ef          	jal	800011ae <uvmcreate>
    800019d6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800019d8:	cd05                	beqz	a0,80001a10 <proc_pagetable+0x4c>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800019da:	4729                	li	a4,10
    800019dc:	00004697          	auipc	a3,0x4
    800019e0:	62468693          	addi	a3,a3,1572 # 80006000 <_trampoline>
    800019e4:	6605                	lui	a2,0x1
    800019e6:	040005b7          	lui	a1,0x4000
    800019ea:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    800019ec:	05b2                	slli	a1,a1,0xc
    800019ee:	e1aff0ef          	jal	80001008 <mappages>
    800019f2:	02054663          	bltz	a0,80001a1e <proc_pagetable+0x5a>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800019f6:	4719                	li	a4,6
    800019f8:	05893683          	ld	a3,88(s2)
    800019fc:	6605                	lui	a2,0x1
    800019fe:	020005b7          	lui	a1,0x2000
    80001a02:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a04:	05b6                	slli	a1,a1,0xd
    80001a06:	8526                	mv	a0,s1
    80001a08:	e00ff0ef          	jal	80001008 <mappages>
    80001a0c:	00054f63          	bltz	a0,80001a2a <proc_pagetable+0x66>
}
    80001a10:	8526                	mv	a0,s1
    80001a12:	60e2                	ld	ra,24(sp)
    80001a14:	6442                	ld	s0,16(sp)
    80001a16:	64a2                	ld	s1,8(sp)
    80001a18:	6902                	ld	s2,0(sp)
    80001a1a:	6105                	addi	sp,sp,32
    80001a1c:	8082                	ret
    uvmfree(pagetable, 0);
    80001a1e:	4581                	li	a1,0
    80001a20:	8526                	mv	a0,s1
    80001a22:	98fff0ef          	jal	800013b0 <uvmfree>
    return 0;
    80001a26:	4481                	li	s1,0
    80001a28:	b7e5                	j	80001a10 <proc_pagetable+0x4c>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a2a:	4681                	li	a3,0
    80001a2c:	4605                	li	a2,1
    80001a2e:	040005b7          	lui	a1,0x4000
    80001a32:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a34:	05b2                	slli	a1,a1,0xc
    80001a36:	8526                	mv	a0,s1
    80001a38:	f9cff0ef          	jal	800011d4 <uvmunmap>
    uvmfree(pagetable, 0);
    80001a3c:	4581                	li	a1,0
    80001a3e:	8526                	mv	a0,s1
    80001a40:	971ff0ef          	jal	800013b0 <uvmfree>
    return 0;
    80001a44:	4481                	li	s1,0
    80001a46:	b7e9                	j	80001a10 <proc_pagetable+0x4c>

0000000080001a48 <proc_freepagetable>:
{
    80001a48:	1101                	addi	sp,sp,-32
    80001a4a:	ec06                	sd	ra,24(sp)
    80001a4c:	e822                	sd	s0,16(sp)
    80001a4e:	e426                	sd	s1,8(sp)
    80001a50:	e04a                	sd	s2,0(sp)
    80001a52:	1000                	addi	s0,sp,32
    80001a54:	84aa                	mv	s1,a0
    80001a56:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001a58:	4681                	li	a3,0
    80001a5a:	4605                	li	a2,1
    80001a5c:	040005b7          	lui	a1,0x4000
    80001a60:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a62:	05b2                	slli	a1,a1,0xc
    80001a64:	f70ff0ef          	jal	800011d4 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001a68:	4681                	li	a3,0
    80001a6a:	4605                	li	a2,1
    80001a6c:	020005b7          	lui	a1,0x2000
    80001a70:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001a72:	05b6                	slli	a1,a1,0xd
    80001a74:	8526                	mv	a0,s1
    80001a76:	f5eff0ef          	jal	800011d4 <uvmunmap>
  uvmfree(pagetable, sz);
    80001a7a:	85ca                	mv	a1,s2
    80001a7c:	8526                	mv	a0,s1
    80001a7e:	933ff0ef          	jal	800013b0 <uvmfree>
}
    80001a82:	60e2                	ld	ra,24(sp)
    80001a84:	6442                	ld	s0,16(sp)
    80001a86:	64a2                	ld	s1,8(sp)
    80001a88:	6902                	ld	s2,0(sp)
    80001a8a:	6105                	addi	sp,sp,32
    80001a8c:	8082                	ret

0000000080001a8e <freeproc>:
{
    80001a8e:	1101                	addi	sp,sp,-32
    80001a90:	ec06                	sd	ra,24(sp)
    80001a92:	e822                	sd	s0,16(sp)
    80001a94:	e426                	sd	s1,8(sp)
    80001a96:	1000                	addi	s0,sp,32
    80001a98:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001a9a:	6d28                	ld	a0,88(a0)
    80001a9c:	c119                	beqz	a0,80001aa2 <freeproc+0x14>
    kfree((void*)p->trapframe);
    80001a9e:	f79fe0ef          	jal	80000a16 <kfree>
  p->trapframe = 0;
    80001aa2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001aa6:	68a8                	ld	a0,80(s1)
    80001aa8:	c501                	beqz	a0,80001ab0 <freeproc+0x22>
    proc_freepagetable(p->pagetable, p->sz);
    80001aaa:	64ac                	ld	a1,72(s1)
    80001aac:	f9dff0ef          	jal	80001a48 <proc_freepagetable>
  p->pagetable = 0;
    80001ab0:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001ab4:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001ab8:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001abc:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001ac0:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001ac4:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ac8:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001acc:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ad0:	0004ac23          	sw	zero,24(s1)
}
    80001ad4:	60e2                	ld	ra,24(sp)
    80001ad6:	6442                	ld	s0,16(sp)
    80001ad8:	64a2                	ld	s1,8(sp)
    80001ada:	6105                	addi	sp,sp,32
    80001adc:	8082                	ret

0000000080001ade <allocproc>:
{
    80001ade:	1101                	addi	sp,sp,-32
    80001ae0:	ec06                	sd	ra,24(sp)
    80001ae2:	e822                	sd	s0,16(sp)
    80001ae4:	e426                	sd	s1,8(sp)
    80001ae6:	e04a                	sd	s2,0(sp)
    80001ae8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001aea:	00011497          	auipc	s1,0x11
    80001aee:	d1e48493          	addi	s1,s1,-738 # 80012808 <proc>
    80001af2:	00016917          	auipc	s2,0x16
    80001af6:	71690913          	addi	s2,s2,1814 # 80018208 <tickslock>
    acquire(&p->lock);
    80001afa:	8526                	mv	a0,s1
    80001afc:	8d0ff0ef          	jal	80000bcc <acquire>
    if(p->state == UNUSED) {
    80001b00:	4c9c                	lw	a5,24(s1)
    80001b02:	cb91                	beqz	a5,80001b16 <allocproc+0x38>
      release(&p->lock);
    80001b04:	8526                	mv	a0,s1
    80001b06:	95aff0ef          	jal	80000c60 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b0a:	16848493          	addi	s1,s1,360
    80001b0e:	ff2496e3          	bne	s1,s2,80001afa <allocproc+0x1c>
  return 0;
    80001b12:	4481                	li	s1,0
    80001b14:	a089                	j	80001b56 <allocproc+0x78>
  p->pid = allocpid();
    80001b16:	e71ff0ef          	jal	80001986 <allocpid>
    80001b1a:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001b1c:	4785                	li	a5,1
    80001b1e:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001b20:	fd9fe0ef          	jal	80000af8 <kalloc>
    80001b24:	892a                	mv	s2,a0
    80001b26:	eca8                	sd	a0,88(s1)
    80001b28:	cd15                	beqz	a0,80001b64 <allocproc+0x86>
  p->pagetable = proc_pagetable(p);
    80001b2a:	8526                	mv	a0,s1
    80001b2c:	e99ff0ef          	jal	800019c4 <proc_pagetable>
    80001b30:	892a                	mv	s2,a0
    80001b32:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001b34:	c121                	beqz	a0,80001b74 <allocproc+0x96>
  memset(&p->context, 0, sizeof(p->context));
    80001b36:	07000613          	li	a2,112
    80001b3a:	4581                	li	a1,0
    80001b3c:	06048513          	addi	a0,s1,96
    80001b40:	95cff0ef          	jal	80000c9c <memset>
  p->context.ra = (uint64)forkret;
    80001b44:	00000797          	auipc	a5,0x0
    80001b48:	daa78793          	addi	a5,a5,-598 # 800018ee <forkret>
    80001b4c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001b4e:	60bc                	ld	a5,64(s1)
    80001b50:	6705                	lui	a4,0x1
    80001b52:	97ba                	add	a5,a5,a4
    80001b54:	f4bc                	sd	a5,104(s1)
}
    80001b56:	8526                	mv	a0,s1
    80001b58:	60e2                	ld	ra,24(sp)
    80001b5a:	6442                	ld	s0,16(sp)
    80001b5c:	64a2                	ld	s1,8(sp)
    80001b5e:	6902                	ld	s2,0(sp)
    80001b60:	6105                	addi	sp,sp,32
    80001b62:	8082                	ret
    freeproc(p);
    80001b64:	8526                	mv	a0,s1
    80001b66:	f29ff0ef          	jal	80001a8e <freeproc>
    release(&p->lock);
    80001b6a:	8526                	mv	a0,s1
    80001b6c:	8f4ff0ef          	jal	80000c60 <release>
    return 0;
    80001b70:	84ca                	mv	s1,s2
    80001b72:	b7d5                	j	80001b56 <allocproc+0x78>
    freeproc(p);
    80001b74:	8526                	mv	a0,s1
    80001b76:	f19ff0ef          	jal	80001a8e <freeproc>
    release(&p->lock);
    80001b7a:	8526                	mv	a0,s1
    80001b7c:	8e4ff0ef          	jal	80000c60 <release>
    return 0;
    80001b80:	84ca                	mv	s1,s2
    80001b82:	bfd1                	j	80001b56 <allocproc+0x78>

0000000080001b84 <userinit>:
{
    80001b84:	1101                	addi	sp,sp,-32
    80001b86:	ec06                	sd	ra,24(sp)
    80001b88:	e822                	sd	s0,16(sp)
    80001b8a:	e426                	sd	s1,8(sp)
    80001b8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001b8e:	f51ff0ef          	jal	80001ade <allocproc>
    80001b92:	84aa                	mv	s1,a0
  initproc = p;
    80001b94:	00008797          	auipc	a5,0x8
    80001b98:	72a7be23          	sd	a0,1852(a5) # 8000a2d0 <initproc>
  p->cwd = namei("/");
    80001b9c:	00005517          	auipc	a0,0x5
    80001ba0:	5f450513          	addi	a0,a0,1524 # 80007190 <etext+0x190>
    80001ba4:	6df010ef          	jal	80003a82 <namei>
    80001ba8:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001bac:	478d                	li	a5,3
    80001bae:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	8aeff0ef          	jal	80000c60 <release>
}
    80001bb6:	60e2                	ld	ra,24(sp)
    80001bb8:	6442                	ld	s0,16(sp)
    80001bba:	64a2                	ld	s1,8(sp)
    80001bbc:	6105                	addi	sp,sp,32
    80001bbe:	8082                	ret

0000000080001bc0 <growproc>:
{
    80001bc0:	1101                	addi	sp,sp,-32
    80001bc2:	ec06                	sd	ra,24(sp)
    80001bc4:	e822                	sd	s0,16(sp)
    80001bc6:	e426                	sd	s1,8(sp)
    80001bc8:	e04a                	sd	s2,0(sp)
    80001bca:	1000                	addi	s0,sp,32
    80001bcc:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001bce:	cf1ff0ef          	jal	800018be <myproc>
    80001bd2:	892a                	mv	s2,a0
  sz = p->sz;
    80001bd4:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001bd6:	02905963          	blez	s1,80001c08 <growproc+0x48>
    if(sz + n > TRAPFRAME) {
    80001bda:	00b48633          	add	a2,s1,a1
    80001bde:	020007b7          	lui	a5,0x2000
    80001be2:	17fd                	addi	a5,a5,-1 # 1ffffff <_entry-0x7e000001>
    80001be4:	07b6                	slli	a5,a5,0xd
    80001be6:	02c7ea63          	bltu	a5,a2,80001c1a <growproc+0x5a>
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001bea:	4691                	li	a3,4
    80001bec:	6928                	ld	a0,80(a0)
    80001bee:	eb4ff0ef          	jal	800012a2 <uvmalloc>
    80001bf2:	85aa                	mv	a1,a0
    80001bf4:	c50d                	beqz	a0,80001c1e <growproc+0x5e>
  p->sz = sz;
    80001bf6:	04b93423          	sd	a1,72(s2)
  return 0;
    80001bfa:	4501                	li	a0,0
}
    80001bfc:	60e2                	ld	ra,24(sp)
    80001bfe:	6442                	ld	s0,16(sp)
    80001c00:	64a2                	ld	s1,8(sp)
    80001c02:	6902                	ld	s2,0(sp)
    80001c04:	6105                	addi	sp,sp,32
    80001c06:	8082                	ret
  } else if(n < 0){
    80001c08:	fe04d7e3          	bgez	s1,80001bf6 <growproc+0x36>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001c0c:	00b48633          	add	a2,s1,a1
    80001c10:	6928                	ld	a0,80(a0)
    80001c12:	e4cff0ef          	jal	8000125e <uvmdealloc>
    80001c16:	85aa                	mv	a1,a0
    80001c18:	bff9                	j	80001bf6 <growproc+0x36>
      return -1;
    80001c1a:	557d                	li	a0,-1
    80001c1c:	b7c5                	j	80001bfc <growproc+0x3c>
      return -1;
    80001c1e:	557d                	li	a0,-1
    80001c20:	bff1                	j	80001bfc <growproc+0x3c>

0000000080001c22 <kfork>:
{
    80001c22:	7139                	addi	sp,sp,-64
    80001c24:	fc06                	sd	ra,56(sp)
    80001c26:	f822                	sd	s0,48(sp)
    80001c28:	f04a                	sd	s2,32(sp)
    80001c2a:	e456                	sd	s5,8(sp)
    80001c2c:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001c2e:	c91ff0ef          	jal	800018be <myproc>
    80001c32:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001c34:	eabff0ef          	jal	80001ade <allocproc>
    80001c38:	0e050a63          	beqz	a0,80001d2c <kfork+0x10a>
    80001c3c:	e852                	sd	s4,16(sp)
    80001c3e:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001c40:	048ab603          	ld	a2,72(s5)
    80001c44:	692c                	ld	a1,80(a0)
    80001c46:	050ab503          	ld	a0,80(s5)
    80001c4a:	f98ff0ef          	jal	800013e2 <uvmcopy>
    80001c4e:	04054a63          	bltz	a0,80001ca2 <kfork+0x80>
    80001c52:	f426                	sd	s1,40(sp)
    80001c54:	ec4e                	sd	s3,24(sp)
  np->sz = p->sz;
    80001c56:	048ab783          	ld	a5,72(s5)
    80001c5a:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001c5e:	058ab683          	ld	a3,88(s5)
    80001c62:	87b6                	mv	a5,a3
    80001c64:	058a3703          	ld	a4,88(s4)
    80001c68:	12068693          	addi	a3,a3,288
    80001c6c:	0007b803          	ld	a6,0(a5)
    80001c70:	6788                	ld	a0,8(a5)
    80001c72:	6b8c                	ld	a1,16(a5)
    80001c74:	6f90                	ld	a2,24(a5)
    80001c76:	01073023          	sd	a6,0(a4) # 1000 <_entry-0x7ffff000>
    80001c7a:	e708                	sd	a0,8(a4)
    80001c7c:	eb0c                	sd	a1,16(a4)
    80001c7e:	ef10                	sd	a2,24(a4)
    80001c80:	02078793          	addi	a5,a5,32
    80001c84:	02070713          	addi	a4,a4,32
    80001c88:	fed792e3          	bne	a5,a3,80001c6c <kfork+0x4a>
  np->trapframe->a0 = 0;
    80001c8c:	058a3783          	ld	a5,88(s4)
    80001c90:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001c94:	0d0a8493          	addi	s1,s5,208
    80001c98:	0d0a0913          	addi	s2,s4,208
    80001c9c:	150a8993          	addi	s3,s5,336
    80001ca0:	a831                	j	80001cbc <kfork+0x9a>
    freeproc(np);
    80001ca2:	8552                	mv	a0,s4
    80001ca4:	debff0ef          	jal	80001a8e <freeproc>
    release(&np->lock);
    80001ca8:	8552                	mv	a0,s4
    80001caa:	fb7fe0ef          	jal	80000c60 <release>
    return -1;
    80001cae:	597d                	li	s2,-1
    80001cb0:	6a42                	ld	s4,16(sp)
    80001cb2:	a0b5                	j	80001d1e <kfork+0xfc>
  for(i = 0; i < NOFILE; i++)
    80001cb4:	04a1                	addi	s1,s1,8
    80001cb6:	0921                	addi	s2,s2,8
    80001cb8:	01348963          	beq	s1,s3,80001cca <kfork+0xa8>
    if(p->ofile[i])
    80001cbc:	6088                	ld	a0,0(s1)
    80001cbe:	d97d                	beqz	a0,80001cb4 <kfork+0x92>
      np->ofile[i] = filedup(p->ofile[i]);
    80001cc0:	368020ef          	jal	80004028 <filedup>
    80001cc4:	00a93023          	sd	a0,0(s2)
    80001cc8:	b7f5                	j	80001cb4 <kfork+0x92>
  np->cwd = idup(p->cwd);
    80001cca:	150ab503          	ld	a0,336(s5)
    80001cce:	554010ef          	jal	80003222 <idup>
    80001cd2:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001cd6:	4641                	li	a2,16
    80001cd8:	158a8593          	addi	a1,s5,344
    80001cdc:	158a0513          	addi	a0,s4,344
    80001ce0:	90eff0ef          	jal	80000dee <safestrcpy>
  pid = np->pid;
    80001ce4:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ce8:	8552                	mv	a0,s4
    80001cea:	f77fe0ef          	jal	80000c60 <release>
  acquire(&wait_lock);
    80001cee:	00010497          	auipc	s1,0x10
    80001cf2:	70248493          	addi	s1,s1,1794 # 800123f0 <wait_lock>
    80001cf6:	8526                	mv	a0,s1
    80001cf8:	ed5fe0ef          	jal	80000bcc <acquire>
  np->parent = p;
    80001cfc:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001d00:	8526                	mv	a0,s1
    80001d02:	f5ffe0ef          	jal	80000c60 <release>
  acquire(&np->lock);
    80001d06:	8552                	mv	a0,s4
    80001d08:	ec5fe0ef          	jal	80000bcc <acquire>
  np->state = RUNNABLE;
    80001d0c:	478d                	li	a5,3
    80001d0e:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001d12:	8552                	mv	a0,s4
    80001d14:	f4dfe0ef          	jal	80000c60 <release>
  return pid;
    80001d18:	74a2                	ld	s1,40(sp)
    80001d1a:	69e2                	ld	s3,24(sp)
    80001d1c:	6a42                	ld	s4,16(sp)
}
    80001d1e:	854a                	mv	a0,s2
    80001d20:	70e2                	ld	ra,56(sp)
    80001d22:	7442                	ld	s0,48(sp)
    80001d24:	7902                	ld	s2,32(sp)
    80001d26:	6aa2                	ld	s5,8(sp)
    80001d28:	6121                	addi	sp,sp,64
    80001d2a:	8082                	ret
    return -1;
    80001d2c:	597d                	li	s2,-1
    80001d2e:	bfc5                	j	80001d1e <kfork+0xfc>

0000000080001d30 <scheduler>:
{
    80001d30:	715d                	addi	sp,sp,-80
    80001d32:	e486                	sd	ra,72(sp)
    80001d34:	e0a2                	sd	s0,64(sp)
    80001d36:	fc26                	sd	s1,56(sp)
    80001d38:	f84a                	sd	s2,48(sp)
    80001d3a:	f44e                	sd	s3,40(sp)
    80001d3c:	f052                	sd	s4,32(sp)
    80001d3e:	ec56                	sd	s5,24(sp)
    80001d40:	e85a                	sd	s6,16(sp)
    80001d42:	e45e                	sd	s7,8(sp)
    80001d44:	e062                	sd	s8,0(sp)
    80001d46:	0880                	addi	s0,sp,80
    80001d48:	8792                	mv	a5,tp
  int id = r_tp();
    80001d4a:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001d4c:	00779b13          	slli	s6,a5,0x7
    80001d50:	00010717          	auipc	a4,0x10
    80001d54:	68870713          	addi	a4,a4,1672 # 800123d8 <pid_lock>
    80001d58:	975a                	add	a4,a4,s6
    80001d5a:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001d5e:	00010717          	auipc	a4,0x10
    80001d62:	6b270713          	addi	a4,a4,1714 # 80012410 <cpus+0x8>
    80001d66:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001d68:	4c11                	li	s8,4
        c->proc = p;
    80001d6a:	079e                	slli	a5,a5,0x7
    80001d6c:	00010a17          	auipc	s4,0x10
    80001d70:	66ca0a13          	addi	s4,s4,1644 # 800123d8 <pid_lock>
    80001d74:	9a3e                	add	s4,s4,a5
        found = 1;
    80001d76:	4b85                	li	s7,1
    80001d78:	a83d                	j	80001db6 <scheduler+0x86>
      release(&p->lock);
    80001d7a:	8526                	mv	a0,s1
    80001d7c:	ee5fe0ef          	jal	80000c60 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001d80:	16848493          	addi	s1,s1,360
    80001d84:	03248563          	beq	s1,s2,80001dae <scheduler+0x7e>
      acquire(&p->lock);
    80001d88:	8526                	mv	a0,s1
    80001d8a:	e43fe0ef          	jal	80000bcc <acquire>
      if(p->state == RUNNABLE) {
    80001d8e:	4c9c                	lw	a5,24(s1)
    80001d90:	ff3795e3          	bne	a5,s3,80001d7a <scheduler+0x4a>
        p->state = RUNNING;
    80001d94:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001d98:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001d9c:	06048593          	addi	a1,s1,96
    80001da0:	855a                	mv	a0,s6
    80001da2:	5b4000ef          	jal	80002356 <swtch>
        c->proc = 0;
    80001da6:	020a3823          	sd	zero,48(s4)
        found = 1;
    80001daa:	8ade                	mv	s5,s7
    80001dac:	b7f9                	j	80001d7a <scheduler+0x4a>
    if(found == 0) {
    80001dae:	000a9463          	bnez	s5,80001db6 <scheduler+0x86>
      asm volatile("wfi");
    80001db2:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001db6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001dba:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dbe:	10079073          	csrw	sstatus,a5
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001dc2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80001dc6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001dc8:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001dcc:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dce:	00011497          	auipc	s1,0x11
    80001dd2:	a3a48493          	addi	s1,s1,-1478 # 80012808 <proc>
      if(p->state == RUNNABLE) {
    80001dd6:	498d                	li	s3,3
    for(p = proc; p < &proc[NPROC]; p++) {
    80001dd8:	00016917          	auipc	s2,0x16
    80001ddc:	43090913          	addi	s2,s2,1072 # 80018208 <tickslock>
    80001de0:	b765                	j	80001d88 <scheduler+0x58>

0000000080001de2 <sched>:
{
    80001de2:	7179                	addi	sp,sp,-48
    80001de4:	f406                	sd	ra,40(sp)
    80001de6:	f022                	sd	s0,32(sp)
    80001de8:	ec26                	sd	s1,24(sp)
    80001dea:	e84a                	sd	s2,16(sp)
    80001dec:	e44e                	sd	s3,8(sp)
    80001dee:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001df0:	acfff0ef          	jal	800018be <myproc>
    80001df4:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001df6:	d6dfe0ef          	jal	80000b62 <holding>
    80001dfa:	c92d                	beqz	a0,80001e6c <sched+0x8a>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001dfc:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001dfe:	2781                	sext.w	a5,a5
    80001e00:	079e                	slli	a5,a5,0x7
    80001e02:	00010717          	auipc	a4,0x10
    80001e06:	5d670713          	addi	a4,a4,1494 # 800123d8 <pid_lock>
    80001e0a:	97ba                	add	a5,a5,a4
    80001e0c:	0a87a703          	lw	a4,168(a5)
    80001e10:	4785                	li	a5,1
    80001e12:	06f71363          	bne	a4,a5,80001e78 <sched+0x96>
  if(p->state == RUNNING)
    80001e16:	4c98                	lw	a4,24(s1)
    80001e18:	4791                	li	a5,4
    80001e1a:	06f70563          	beq	a4,a5,80001e84 <sched+0xa2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001e1e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001e22:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001e24:	e7b5                	bnez	a5,80001e90 <sched+0xae>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001e26:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001e28:	00010917          	auipc	s2,0x10
    80001e2c:	5b090913          	addi	s2,s2,1456 # 800123d8 <pid_lock>
    80001e30:	2781                	sext.w	a5,a5
    80001e32:	079e                	slli	a5,a5,0x7
    80001e34:	97ca                	add	a5,a5,s2
    80001e36:	0ac7a983          	lw	s3,172(a5)
    80001e3a:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001e3c:	2781                	sext.w	a5,a5
    80001e3e:	079e                	slli	a5,a5,0x7
    80001e40:	00010597          	auipc	a1,0x10
    80001e44:	5d058593          	addi	a1,a1,1488 # 80012410 <cpus+0x8>
    80001e48:	95be                	add	a1,a1,a5
    80001e4a:	06048513          	addi	a0,s1,96
    80001e4e:	508000ef          	jal	80002356 <swtch>
    80001e52:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80001e54:	2781                	sext.w	a5,a5
    80001e56:	079e                	slli	a5,a5,0x7
    80001e58:	993e                	add	s2,s2,a5
    80001e5a:	0b392623          	sw	s3,172(s2)
}
    80001e5e:	70a2                	ld	ra,40(sp)
    80001e60:	7402                	ld	s0,32(sp)
    80001e62:	64e2                	ld	s1,24(sp)
    80001e64:	6942                	ld	s2,16(sp)
    80001e66:	69a2                	ld	s3,8(sp)
    80001e68:	6145                	addi	sp,sp,48
    80001e6a:	8082                	ret
    panic("sched p->lock");
    80001e6c:	00005517          	auipc	a0,0x5
    80001e70:	32c50513          	addi	a0,a0,812 # 80007198 <etext+0x198>
    80001e74:	96bfe0ef          	jal	800007de <panic>
    panic("sched locks");
    80001e78:	00005517          	auipc	a0,0x5
    80001e7c:	33050513          	addi	a0,a0,816 # 800071a8 <etext+0x1a8>
    80001e80:	95ffe0ef          	jal	800007de <panic>
    panic("sched RUNNING");
    80001e84:	00005517          	auipc	a0,0x5
    80001e88:	33450513          	addi	a0,a0,820 # 800071b8 <etext+0x1b8>
    80001e8c:	953fe0ef          	jal	800007de <panic>
    panic("sched interruptible");
    80001e90:	00005517          	auipc	a0,0x5
    80001e94:	33850513          	addi	a0,a0,824 # 800071c8 <etext+0x1c8>
    80001e98:	947fe0ef          	jal	800007de <panic>

0000000080001e9c <yield>:
{
    80001e9c:	1101                	addi	sp,sp,-32
    80001e9e:	ec06                	sd	ra,24(sp)
    80001ea0:	e822                	sd	s0,16(sp)
    80001ea2:	e426                	sd	s1,8(sp)
    80001ea4:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80001ea6:	a19ff0ef          	jal	800018be <myproc>
    80001eaa:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80001eac:	d21fe0ef          	jal	80000bcc <acquire>
  p->state = RUNNABLE;
    80001eb0:	478d                	li	a5,3
    80001eb2:	cc9c                	sw	a5,24(s1)
  sched();
    80001eb4:	f2fff0ef          	jal	80001de2 <sched>
  release(&p->lock);
    80001eb8:	8526                	mv	a0,s1
    80001eba:	da7fe0ef          	jal	80000c60 <release>
}
    80001ebe:	60e2                	ld	ra,24(sp)
    80001ec0:	6442                	ld	s0,16(sp)
    80001ec2:	64a2                	ld	s1,8(sp)
    80001ec4:	6105                	addi	sp,sp,32
    80001ec6:	8082                	ret

0000000080001ec8 <sleep>:

// Sleep on channel chan, releasing condition lock lk.
// Re-acquires lk when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80001ec8:	7179                	addi	sp,sp,-48
    80001eca:	f406                	sd	ra,40(sp)
    80001ecc:	f022                	sd	s0,32(sp)
    80001ece:	ec26                	sd	s1,24(sp)
    80001ed0:	e84a                	sd	s2,16(sp)
    80001ed2:	e44e                	sd	s3,8(sp)
    80001ed4:	1800                	addi	s0,sp,48
    80001ed6:	89aa                	mv	s3,a0
    80001ed8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80001eda:	9e5ff0ef          	jal	800018be <myproc>
    80001ede:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    80001ee0:	cedfe0ef          	jal	80000bcc <acquire>
  release(lk);
    80001ee4:	854a                	mv	a0,s2
    80001ee6:	d7bfe0ef          	jal	80000c60 <release>

  // Go to sleep.
  p->chan = chan;
    80001eea:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80001eee:	4789                	li	a5,2
    80001ef0:	cc9c                	sw	a5,24(s1)

  sched();
    80001ef2:	ef1ff0ef          	jal	80001de2 <sched>

  // Tidy up.
  p->chan = 0;
    80001ef6:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80001efa:	8526                	mv	a0,s1
    80001efc:	d65fe0ef          	jal	80000c60 <release>
  acquire(lk);
    80001f00:	854a                	mv	a0,s2
    80001f02:	ccbfe0ef          	jal	80000bcc <acquire>
}
    80001f06:	70a2                	ld	ra,40(sp)
    80001f08:	7402                	ld	s0,32(sp)
    80001f0a:	64e2                	ld	s1,24(sp)
    80001f0c:	6942                	ld	s2,16(sp)
    80001f0e:	69a2                	ld	s3,8(sp)
    80001f10:	6145                	addi	sp,sp,48
    80001f12:	8082                	ret

0000000080001f14 <wakeup>:

// Wake up all processes sleeping on channel chan.
// Caller should hold the condition lock.
void
wakeup(void *chan)
{
    80001f14:	7139                	addi	sp,sp,-64
    80001f16:	fc06                	sd	ra,56(sp)
    80001f18:	f822                	sd	s0,48(sp)
    80001f1a:	f426                	sd	s1,40(sp)
    80001f1c:	f04a                	sd	s2,32(sp)
    80001f1e:	ec4e                	sd	s3,24(sp)
    80001f20:	e852                	sd	s4,16(sp)
    80001f22:	e456                	sd	s5,8(sp)
    80001f24:	0080                	addi	s0,sp,64
    80001f26:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80001f28:	00011497          	auipc	s1,0x11
    80001f2c:	8e048493          	addi	s1,s1,-1824 # 80012808 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80001f30:	4989                	li	s3,2
        p->state = RUNNABLE;
    80001f32:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	00016917          	auipc	s2,0x16
    80001f38:	2d490913          	addi	s2,s2,724 # 80018208 <tickslock>
    80001f3c:	a801                	j	80001f4c <wakeup+0x38>
      }
      release(&p->lock);
    80001f3e:	8526                	mv	a0,s1
    80001f40:	d21fe0ef          	jal	80000c60 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001f44:	16848493          	addi	s1,s1,360
    80001f48:	03248263          	beq	s1,s2,80001f6c <wakeup+0x58>
    if(p != myproc()){
    80001f4c:	973ff0ef          	jal	800018be <myproc>
    80001f50:	fea48ae3          	beq	s1,a0,80001f44 <wakeup+0x30>
      acquire(&p->lock);
    80001f54:	8526                	mv	a0,s1
    80001f56:	c77fe0ef          	jal	80000bcc <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80001f5a:	4c9c                	lw	a5,24(s1)
    80001f5c:	ff3791e3          	bne	a5,s3,80001f3e <wakeup+0x2a>
    80001f60:	709c                	ld	a5,32(s1)
    80001f62:	fd479ee3          	bne	a5,s4,80001f3e <wakeup+0x2a>
        p->state = RUNNABLE;
    80001f66:	0154ac23          	sw	s5,24(s1)
    80001f6a:	bfd1                	j	80001f3e <wakeup+0x2a>
    }
  }
}
    80001f6c:	70e2                	ld	ra,56(sp)
    80001f6e:	7442                	ld	s0,48(sp)
    80001f70:	74a2                	ld	s1,40(sp)
    80001f72:	7902                	ld	s2,32(sp)
    80001f74:	69e2                	ld	s3,24(sp)
    80001f76:	6a42                	ld	s4,16(sp)
    80001f78:	6aa2                	ld	s5,8(sp)
    80001f7a:	6121                	addi	sp,sp,64
    80001f7c:	8082                	ret

0000000080001f7e <reparent>:
{
    80001f7e:	7179                	addi	sp,sp,-48
    80001f80:	f406                	sd	ra,40(sp)
    80001f82:	f022                	sd	s0,32(sp)
    80001f84:	ec26                	sd	s1,24(sp)
    80001f86:	e84a                	sd	s2,16(sp)
    80001f88:	e44e                	sd	s3,8(sp)
    80001f8a:	e052                	sd	s4,0(sp)
    80001f8c:	1800                	addi	s0,sp,48
    80001f8e:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f90:	00011497          	auipc	s1,0x11
    80001f94:	87848493          	addi	s1,s1,-1928 # 80012808 <proc>
      pp->parent = initproc;
    80001f98:	00008a17          	auipc	s4,0x8
    80001f9c:	338a0a13          	addi	s4,s4,824 # 8000a2d0 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001fa0:	00016997          	auipc	s3,0x16
    80001fa4:	26898993          	addi	s3,s3,616 # 80018208 <tickslock>
    80001fa8:	a029                	j	80001fb2 <reparent+0x34>
    80001faa:	16848493          	addi	s1,s1,360
    80001fae:	01348b63          	beq	s1,s3,80001fc4 <reparent+0x46>
    if(pp->parent == p){
    80001fb2:	7c9c                	ld	a5,56(s1)
    80001fb4:	ff279be3          	bne	a5,s2,80001faa <reparent+0x2c>
      pp->parent = initproc;
    80001fb8:	000a3503          	ld	a0,0(s4)
    80001fbc:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80001fbe:	f57ff0ef          	jal	80001f14 <wakeup>
    80001fc2:	b7e5                	j	80001faa <reparent+0x2c>
}
    80001fc4:	70a2                	ld	ra,40(sp)
    80001fc6:	7402                	ld	s0,32(sp)
    80001fc8:	64e2                	ld	s1,24(sp)
    80001fca:	6942                	ld	s2,16(sp)
    80001fcc:	69a2                	ld	s3,8(sp)
    80001fce:	6a02                	ld	s4,0(sp)
    80001fd0:	6145                	addi	sp,sp,48
    80001fd2:	8082                	ret

0000000080001fd4 <kexit>:
{
    80001fd4:	7179                	addi	sp,sp,-48
    80001fd6:	f406                	sd	ra,40(sp)
    80001fd8:	f022                	sd	s0,32(sp)
    80001fda:	ec26                	sd	s1,24(sp)
    80001fdc:	e84a                	sd	s2,16(sp)
    80001fde:	e44e                	sd	s3,8(sp)
    80001fe0:	e052                	sd	s4,0(sp)
    80001fe2:	1800                	addi	s0,sp,48
    80001fe4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80001fe6:	8d9ff0ef          	jal	800018be <myproc>
    80001fea:	89aa                	mv	s3,a0
  if(p == initproc)
    80001fec:	00008797          	auipc	a5,0x8
    80001ff0:	2e47b783          	ld	a5,740(a5) # 8000a2d0 <initproc>
    80001ff4:	0d050493          	addi	s1,a0,208
    80001ff8:	15050913          	addi	s2,a0,336
    80001ffc:	00a79b63          	bne	a5,a0,80002012 <kexit+0x3e>
    panic("init exiting");
    80002000:	00005517          	auipc	a0,0x5
    80002004:	1e050513          	addi	a0,a0,480 # 800071e0 <etext+0x1e0>
    80002008:	fd6fe0ef          	jal	800007de <panic>
  for(int fd = 0; fd < NOFILE; fd++){
    8000200c:	04a1                	addi	s1,s1,8
    8000200e:	01248963          	beq	s1,s2,80002020 <kexit+0x4c>
    if(p->ofile[fd]){
    80002012:	6088                	ld	a0,0(s1)
    80002014:	dd65                	beqz	a0,8000200c <kexit+0x38>
      fileclose(f);
    80002016:	058020ef          	jal	8000406e <fileclose>
      p->ofile[fd] = 0;
    8000201a:	0004b023          	sd	zero,0(s1)
    8000201e:	b7fd                	j	8000200c <kexit+0x38>
  begin_op();
    80002020:	43d010ef          	jal	80003c5c <begin_op>
  iput(p->cwd);
    80002024:	1509b503          	ld	a0,336(s3)
    80002028:	3b2010ef          	jal	800033da <iput>
  end_op();
    8000202c:	49b010ef          	jal	80003cc6 <end_op>
  p->cwd = 0;
    80002030:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002034:	00010497          	auipc	s1,0x10
    80002038:	3bc48493          	addi	s1,s1,956 # 800123f0 <wait_lock>
    8000203c:	8526                	mv	a0,s1
    8000203e:	b8ffe0ef          	jal	80000bcc <acquire>
  reparent(p);
    80002042:	854e                	mv	a0,s3
    80002044:	f3bff0ef          	jal	80001f7e <reparent>
  wakeup(p->parent);
    80002048:	0389b503          	ld	a0,56(s3)
    8000204c:	ec9ff0ef          	jal	80001f14 <wakeup>
  acquire(&p->lock);
    80002050:	854e                	mv	a0,s3
    80002052:	b7bfe0ef          	jal	80000bcc <acquire>
  p->xstate = status;
    80002056:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000205a:	4795                	li	a5,5
    8000205c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002060:	8526                	mv	a0,s1
    80002062:	bfffe0ef          	jal	80000c60 <release>
  sched();
    80002066:	d7dff0ef          	jal	80001de2 <sched>
  panic("zombie exit");
    8000206a:	00005517          	auipc	a0,0x5
    8000206e:	18650513          	addi	a0,a0,390 # 800071f0 <etext+0x1f0>
    80002072:	f6cfe0ef          	jal	800007de <panic>

0000000080002076 <kkill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kkill(int pid)
{
    80002076:	7179                	addi	sp,sp,-48
    80002078:	f406                	sd	ra,40(sp)
    8000207a:	f022                	sd	s0,32(sp)
    8000207c:	ec26                	sd	s1,24(sp)
    8000207e:	e84a                	sd	s2,16(sp)
    80002080:	e44e                	sd	s3,8(sp)
    80002082:	1800                	addi	s0,sp,48
    80002084:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002086:	00010497          	auipc	s1,0x10
    8000208a:	78248493          	addi	s1,s1,1922 # 80012808 <proc>
    8000208e:	00016997          	auipc	s3,0x16
    80002092:	17a98993          	addi	s3,s3,378 # 80018208 <tickslock>
    acquire(&p->lock);
    80002096:	8526                	mv	a0,s1
    80002098:	b35fe0ef          	jal	80000bcc <acquire>
    if(p->pid == pid){
    8000209c:	589c                	lw	a5,48(s1)
    8000209e:	01278b63          	beq	a5,s2,800020b4 <kkill+0x3e>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800020a2:	8526                	mv	a0,s1
    800020a4:	bbdfe0ef          	jal	80000c60 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800020a8:	16848493          	addi	s1,s1,360
    800020ac:	ff3495e3          	bne	s1,s3,80002096 <kkill+0x20>
  }
  return -1;
    800020b0:	557d                	li	a0,-1
    800020b2:	a819                	j	800020c8 <kkill+0x52>
      p->killed = 1;
    800020b4:	4785                	li	a5,1
    800020b6:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800020b8:	4c98                	lw	a4,24(s1)
    800020ba:	4789                	li	a5,2
    800020bc:	00f70d63          	beq	a4,a5,800020d6 <kkill+0x60>
      release(&p->lock);
    800020c0:	8526                	mv	a0,s1
    800020c2:	b9ffe0ef          	jal	80000c60 <release>
      return 0;
    800020c6:	4501                	li	a0,0
}
    800020c8:	70a2                	ld	ra,40(sp)
    800020ca:	7402                	ld	s0,32(sp)
    800020cc:	64e2                	ld	s1,24(sp)
    800020ce:	6942                	ld	s2,16(sp)
    800020d0:	69a2                	ld	s3,8(sp)
    800020d2:	6145                	addi	sp,sp,48
    800020d4:	8082                	ret
        p->state = RUNNABLE;
    800020d6:	478d                	li	a5,3
    800020d8:	cc9c                	sw	a5,24(s1)
    800020da:	b7dd                	j	800020c0 <kkill+0x4a>

00000000800020dc <setkilled>:

void
setkilled(struct proc *p)
{
    800020dc:	1101                	addi	sp,sp,-32
    800020de:	ec06                	sd	ra,24(sp)
    800020e0:	e822                	sd	s0,16(sp)
    800020e2:	e426                	sd	s1,8(sp)
    800020e4:	1000                	addi	s0,sp,32
    800020e6:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800020e8:	ae5fe0ef          	jal	80000bcc <acquire>
  p->killed = 1;
    800020ec:	4785                	li	a5,1
    800020ee:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800020f0:	8526                	mv	a0,s1
    800020f2:	b6ffe0ef          	jal	80000c60 <release>
}
    800020f6:	60e2                	ld	ra,24(sp)
    800020f8:	6442                	ld	s0,16(sp)
    800020fa:	64a2                	ld	s1,8(sp)
    800020fc:	6105                	addi	sp,sp,32
    800020fe:	8082                	ret

0000000080002100 <killed>:

int
killed(struct proc *p)
{
    80002100:	1101                	addi	sp,sp,-32
    80002102:	ec06                	sd	ra,24(sp)
    80002104:	e822                	sd	s0,16(sp)
    80002106:	e426                	sd	s1,8(sp)
    80002108:	e04a                	sd	s2,0(sp)
    8000210a:	1000                	addi	s0,sp,32
    8000210c:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    8000210e:	abffe0ef          	jal	80000bcc <acquire>
  k = p->killed;
    80002112:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002116:	8526                	mv	a0,s1
    80002118:	b49fe0ef          	jal	80000c60 <release>
  return k;
}
    8000211c:	854a                	mv	a0,s2
    8000211e:	60e2                	ld	ra,24(sp)
    80002120:	6442                	ld	s0,16(sp)
    80002122:	64a2                	ld	s1,8(sp)
    80002124:	6902                	ld	s2,0(sp)
    80002126:	6105                	addi	sp,sp,32
    80002128:	8082                	ret

000000008000212a <kwait>:
{
    8000212a:	715d                	addi	sp,sp,-80
    8000212c:	e486                	sd	ra,72(sp)
    8000212e:	e0a2                	sd	s0,64(sp)
    80002130:	fc26                	sd	s1,56(sp)
    80002132:	f84a                	sd	s2,48(sp)
    80002134:	f44e                	sd	s3,40(sp)
    80002136:	f052                	sd	s4,32(sp)
    80002138:	ec56                	sd	s5,24(sp)
    8000213a:	e85a                	sd	s6,16(sp)
    8000213c:	e45e                	sd	s7,8(sp)
    8000213e:	0880                	addi	s0,sp,80
    80002140:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002142:	f7cff0ef          	jal	800018be <myproc>
    80002146:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002148:	00010517          	auipc	a0,0x10
    8000214c:	2a850513          	addi	a0,a0,680 # 800123f0 <wait_lock>
    80002150:	a7dfe0ef          	jal	80000bcc <acquire>
        if(pp->state == ZOMBIE){
    80002154:	4a15                	li	s4,5
        havekids = 1;
    80002156:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002158:	00016997          	auipc	s3,0x16
    8000215c:	0b098993          	addi	s3,s3,176 # 80018208 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002160:	00010b97          	auipc	s7,0x10
    80002164:	290b8b93          	addi	s7,s7,656 # 800123f0 <wait_lock>
    80002168:	a869                	j	80002202 <kwait+0xd8>
          pid = pp->pid;
    8000216a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000216e:	000b0c63          	beqz	s6,80002186 <kwait+0x5c>
    80002172:	4691                	li	a3,4
    80002174:	02c48613          	addi	a2,s1,44
    80002178:	85da                	mv	a1,s6
    8000217a:	05093503          	ld	a0,80(s2)
    8000217e:	c72ff0ef          	jal	800015f0 <copyout>
    80002182:	02054a63          	bltz	a0,800021b6 <kwait+0x8c>
          freeproc(pp);
    80002186:	8526                	mv	a0,s1
    80002188:	907ff0ef          	jal	80001a8e <freeproc>
          release(&pp->lock);
    8000218c:	8526                	mv	a0,s1
    8000218e:	ad3fe0ef          	jal	80000c60 <release>
          release(&wait_lock);
    80002192:	00010517          	auipc	a0,0x10
    80002196:	25e50513          	addi	a0,a0,606 # 800123f0 <wait_lock>
    8000219a:	ac7fe0ef          	jal	80000c60 <release>
}
    8000219e:	854e                	mv	a0,s3
    800021a0:	60a6                	ld	ra,72(sp)
    800021a2:	6406                	ld	s0,64(sp)
    800021a4:	74e2                	ld	s1,56(sp)
    800021a6:	7942                	ld	s2,48(sp)
    800021a8:	79a2                	ld	s3,40(sp)
    800021aa:	7a02                	ld	s4,32(sp)
    800021ac:	6ae2                	ld	s5,24(sp)
    800021ae:	6b42                	ld	s6,16(sp)
    800021b0:	6ba2                	ld	s7,8(sp)
    800021b2:	6161                	addi	sp,sp,80
    800021b4:	8082                	ret
            release(&pp->lock);
    800021b6:	8526                	mv	a0,s1
    800021b8:	aa9fe0ef          	jal	80000c60 <release>
            release(&wait_lock);
    800021bc:	00010517          	auipc	a0,0x10
    800021c0:	23450513          	addi	a0,a0,564 # 800123f0 <wait_lock>
    800021c4:	a9dfe0ef          	jal	80000c60 <release>
            return -1;
    800021c8:	59fd                	li	s3,-1
    800021ca:	bfd1                	j	8000219e <kwait+0x74>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800021cc:	16848493          	addi	s1,s1,360
    800021d0:	03348063          	beq	s1,s3,800021f0 <kwait+0xc6>
      if(pp->parent == p){
    800021d4:	7c9c                	ld	a5,56(s1)
    800021d6:	ff279be3          	bne	a5,s2,800021cc <kwait+0xa2>
        acquire(&pp->lock);
    800021da:	8526                	mv	a0,s1
    800021dc:	9f1fe0ef          	jal	80000bcc <acquire>
        if(pp->state == ZOMBIE){
    800021e0:	4c9c                	lw	a5,24(s1)
    800021e2:	f94784e3          	beq	a5,s4,8000216a <kwait+0x40>
        release(&pp->lock);
    800021e6:	8526                	mv	a0,s1
    800021e8:	a79fe0ef          	jal	80000c60 <release>
        havekids = 1;
    800021ec:	8756                	mv	a4,s5
    800021ee:	bff9                	j	800021cc <kwait+0xa2>
    if(!havekids || killed(p)){
    800021f0:	cf19                	beqz	a4,8000220e <kwait+0xe4>
    800021f2:	854a                	mv	a0,s2
    800021f4:	f0dff0ef          	jal	80002100 <killed>
    800021f8:	e919                	bnez	a0,8000220e <kwait+0xe4>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021fa:	85de                	mv	a1,s7
    800021fc:	854a                	mv	a0,s2
    800021fe:	ccbff0ef          	jal	80001ec8 <sleep>
    havekids = 0;
    80002202:	4701                	li	a4,0
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002204:	00010497          	auipc	s1,0x10
    80002208:	60448493          	addi	s1,s1,1540 # 80012808 <proc>
    8000220c:	b7e1                	j	800021d4 <kwait+0xaa>
      release(&wait_lock);
    8000220e:	00010517          	auipc	a0,0x10
    80002212:	1e250513          	addi	a0,a0,482 # 800123f0 <wait_lock>
    80002216:	a4bfe0ef          	jal	80000c60 <release>
      return -1;
    8000221a:	59fd                	li	s3,-1
    8000221c:	b749                	j	8000219e <kwait+0x74>

000000008000221e <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000221e:	7179                	addi	sp,sp,-48
    80002220:	f406                	sd	ra,40(sp)
    80002222:	f022                	sd	s0,32(sp)
    80002224:	ec26                	sd	s1,24(sp)
    80002226:	e84a                	sd	s2,16(sp)
    80002228:	e44e                	sd	s3,8(sp)
    8000222a:	e052                	sd	s4,0(sp)
    8000222c:	1800                	addi	s0,sp,48
    8000222e:	84aa                	mv	s1,a0
    80002230:	892e                	mv	s2,a1
    80002232:	89b2                	mv	s3,a2
    80002234:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002236:	e88ff0ef          	jal	800018be <myproc>
  if(user_dst){
    8000223a:	cc99                	beqz	s1,80002258 <either_copyout+0x3a>
    return copyout(p->pagetable, dst, src, len);
    8000223c:	86d2                	mv	a3,s4
    8000223e:	864e                	mv	a2,s3
    80002240:	85ca                	mv	a1,s2
    80002242:	6928                	ld	a0,80(a0)
    80002244:	bacff0ef          	jal	800015f0 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002248:	70a2                	ld	ra,40(sp)
    8000224a:	7402                	ld	s0,32(sp)
    8000224c:	64e2                	ld	s1,24(sp)
    8000224e:	6942                	ld	s2,16(sp)
    80002250:	69a2                	ld	s3,8(sp)
    80002252:	6a02                	ld	s4,0(sp)
    80002254:	6145                	addi	sp,sp,48
    80002256:	8082                	ret
    memmove((char *)dst, src, len);
    80002258:	000a061b          	sext.w	a2,s4
    8000225c:	85ce                	mv	a1,s3
    8000225e:	854a                	mv	a0,s2
    80002260:	aa1fe0ef          	jal	80000d00 <memmove>
    return 0;
    80002264:	8526                	mv	a0,s1
    80002266:	b7cd                	j	80002248 <either_copyout+0x2a>

0000000080002268 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002268:	7179                	addi	sp,sp,-48
    8000226a:	f406                	sd	ra,40(sp)
    8000226c:	f022                	sd	s0,32(sp)
    8000226e:	ec26                	sd	s1,24(sp)
    80002270:	e84a                	sd	s2,16(sp)
    80002272:	e44e                	sd	s3,8(sp)
    80002274:	e052                	sd	s4,0(sp)
    80002276:	1800                	addi	s0,sp,48
    80002278:	892a                	mv	s2,a0
    8000227a:	84ae                	mv	s1,a1
    8000227c:	89b2                	mv	s3,a2
    8000227e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002280:	e3eff0ef          	jal	800018be <myproc>
  if(user_src){
    80002284:	cc99                	beqz	s1,800022a2 <either_copyin+0x3a>
    return copyin(p->pagetable, dst, src, len);
    80002286:	86d2                	mv	a3,s4
    80002288:	864e                	mv	a2,s3
    8000228a:	85ca                	mv	a1,s2
    8000228c:	6928                	ld	a0,80(a0)
    8000228e:	c20ff0ef          	jal	800016ae <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002292:	70a2                	ld	ra,40(sp)
    80002294:	7402                	ld	s0,32(sp)
    80002296:	64e2                	ld	s1,24(sp)
    80002298:	6942                	ld	s2,16(sp)
    8000229a:	69a2                	ld	s3,8(sp)
    8000229c:	6a02                	ld	s4,0(sp)
    8000229e:	6145                	addi	sp,sp,48
    800022a0:	8082                	ret
    memmove(dst, (char*)src, len);
    800022a2:	000a061b          	sext.w	a2,s4
    800022a6:	85ce                	mv	a1,s3
    800022a8:	854a                	mv	a0,s2
    800022aa:	a57fe0ef          	jal	80000d00 <memmove>
    return 0;
    800022ae:	8526                	mv	a0,s1
    800022b0:	b7cd                	j	80002292 <either_copyin+0x2a>

00000000800022b2 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800022b2:	715d                	addi	sp,sp,-80
    800022b4:	e486                	sd	ra,72(sp)
    800022b6:	e0a2                	sd	s0,64(sp)
    800022b8:	fc26                	sd	s1,56(sp)
    800022ba:	f84a                	sd	s2,48(sp)
    800022bc:	f44e                	sd	s3,40(sp)
    800022be:	f052                	sd	s4,32(sp)
    800022c0:	ec56                	sd	s5,24(sp)
    800022c2:	e85a                	sd	s6,16(sp)
    800022c4:	e45e                	sd	s7,8(sp)
    800022c6:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800022c8:	00005517          	auipc	a0,0x5
    800022cc:	db050513          	addi	a0,a0,-592 # 80007078 <etext+0x78>
    800022d0:	a2afe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800022d4:	00010497          	auipc	s1,0x10
    800022d8:	68c48493          	addi	s1,s1,1676 # 80012960 <proc+0x158>
    800022dc:	00016917          	auipc	s2,0x16
    800022e0:	08490913          	addi	s2,s2,132 # 80018360 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022e4:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800022e6:	00005997          	auipc	s3,0x5
    800022ea:	f1a98993          	addi	s3,s3,-230 # 80007200 <etext+0x200>
    printf("%d %s %s", p->pid, state, p->name);
    800022ee:	00005a97          	auipc	s5,0x5
    800022f2:	f1aa8a93          	addi	s5,s5,-230 # 80007208 <etext+0x208>
    printf("\n");
    800022f6:	00005a17          	auipc	s4,0x5
    800022fa:	d82a0a13          	addi	s4,s4,-638 # 80007078 <etext+0x78>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800022fe:	00005b97          	auipc	s7,0x5
    80002302:	42ab8b93          	addi	s7,s7,1066 # 80007728 <states.0>
    80002306:	a829                	j	80002320 <procdump+0x6e>
    printf("%d %s %s", p->pid, state, p->name);
    80002308:	ed86a583          	lw	a1,-296(a3)
    8000230c:	8556                	mv	a0,s5
    8000230e:	9ecfe0ef          	jal	800004fa <printf>
    printf("\n");
    80002312:	8552                	mv	a0,s4
    80002314:	9e6fe0ef          	jal	800004fa <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002318:	16848493          	addi	s1,s1,360
    8000231c:	03248263          	beq	s1,s2,80002340 <procdump+0x8e>
    if(p->state == UNUSED)
    80002320:	86a6                	mv	a3,s1
    80002322:	ec04a783          	lw	a5,-320(s1)
    80002326:	dbed                	beqz	a5,80002318 <procdump+0x66>
      state = "???";
    80002328:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000232a:	fcfb6fe3          	bltu	s6,a5,80002308 <procdump+0x56>
    8000232e:	02079713          	slli	a4,a5,0x20
    80002332:	01d75793          	srli	a5,a4,0x1d
    80002336:	97de                	add	a5,a5,s7
    80002338:	6390                	ld	a2,0(a5)
    8000233a:	f679                	bnez	a2,80002308 <procdump+0x56>
      state = "???";
    8000233c:	864e                	mv	a2,s3
    8000233e:	b7e9                	j	80002308 <procdump+0x56>
  }
}
    80002340:	60a6                	ld	ra,72(sp)
    80002342:	6406                	ld	s0,64(sp)
    80002344:	74e2                	ld	s1,56(sp)
    80002346:	7942                	ld	s2,48(sp)
    80002348:	79a2                	ld	s3,40(sp)
    8000234a:	7a02                	ld	s4,32(sp)
    8000234c:	6ae2                	ld	s5,24(sp)
    8000234e:	6b42                	ld	s6,16(sp)
    80002350:	6ba2                	ld	s7,8(sp)
    80002352:	6161                	addi	sp,sp,80
    80002354:	8082                	ret

0000000080002356 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002356:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    8000235a:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    8000235e:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002360:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002362:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002366:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    8000236a:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    8000236e:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002372:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002376:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    8000237a:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    8000237e:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002382:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002386:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    8000238a:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    8000238e:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002392:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002394:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002396:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    8000239a:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    8000239e:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    800023a2:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    800023a6:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    800023aa:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    800023ae:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    800023b2:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    800023b6:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    800023ba:	0685bd83          	ld	s11,104(a1)
        
        ret
    800023be:	8082                	ret

00000000800023c0 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800023c0:	1141                	addi	sp,sp,-16
    800023c2:	e406                	sd	ra,8(sp)
    800023c4:	e022                	sd	s0,0(sp)
    800023c6:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800023c8:	00005597          	auipc	a1,0x5
    800023cc:	e8058593          	addi	a1,a1,-384 # 80007248 <etext+0x248>
    800023d0:	00016517          	auipc	a0,0x16
    800023d4:	e3850513          	addi	a0,a0,-456 # 80018208 <tickslock>
    800023d8:	f70fe0ef          	jal	80000b48 <initlock>
}
    800023dc:	60a2                	ld	ra,8(sp)
    800023de:	6402                	ld	s0,0(sp)
    800023e0:	0141                	addi	sp,sp,16
    800023e2:	8082                	ret

00000000800023e4 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800023e4:	1141                	addi	sp,sp,-16
    800023e6:	e406                	sd	ra,8(sp)
    800023e8:	e022                	sd	s0,0(sp)
    800023ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800023ec:	00003797          	auipc	a5,0x3
    800023f0:	04478793          	addi	a5,a5,68 # 80005430 <kernelvec>
    800023f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800023f8:	60a2                	ld	ra,8(sp)
    800023fa:	6402                	ld	s0,0(sp)
    800023fc:	0141                	addi	sp,sp,16
    800023fe:	8082                	ret

0000000080002400 <prepare_return>:
//
// set up trapframe and control registers for a return to user space
//
void
prepare_return(void)
{
    80002400:	1141                	addi	sp,sp,-16
    80002402:	e406                	sd	ra,8(sp)
    80002404:	e022                	sd	s0,0(sp)
    80002406:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002408:	cb6ff0ef          	jal	800018be <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000240c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002410:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002412:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(). because a trap from kernel
  // code to usertrap would be a disaster, turn off interrupts.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002416:	04000737          	lui	a4,0x4000
    8000241a:	177d                	addi	a4,a4,-1 # 3ffffff <_entry-0x7c000001>
    8000241c:	0732                	slli	a4,a4,0xc
    8000241e:	00004797          	auipc	a5,0x4
    80002422:	be278793          	addi	a5,a5,-1054 # 80006000 <_trampoline>
    80002426:	00004697          	auipc	a3,0x4
    8000242a:	bda68693          	addi	a3,a3,-1062 # 80006000 <_trampoline>
    8000242e:	8f95                	sub	a5,a5,a3
    80002430:	97ba                	add	a5,a5,a4
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002432:	10579073          	csrw	stvec,a5
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002436:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002438:	18002773          	csrr	a4,satp
    8000243c:	e398                	sd	a4,0(a5)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000243e:	6d38                	ld	a4,88(a0)
    80002440:	613c                	ld	a5,64(a0)
    80002442:	6685                	lui	a3,0x1
    80002444:	97b6                	add	a5,a5,a3
    80002446:	e71c                	sd	a5,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002448:	6d3c                	ld	a5,88(a0)
    8000244a:	00000717          	auipc	a4,0x0
    8000244e:	0f870713          	addi	a4,a4,248 # 80002542 <usertrap>
    80002452:	eb98                	sd	a4,16(a5)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002454:	6d3c                	ld	a5,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002456:	8712                	mv	a4,tp
    80002458:	f398                	sd	a4,32(a5)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000245a:	100027f3          	csrr	a5,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000245e:	eff7f793          	andi	a5,a5,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002462:	0207e793          	ori	a5,a5,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002466:	10079073          	csrw	sstatus,a5
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000246a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000246c:	6f9c                	ld	a5,24(a5)
    8000246e:	14179073          	csrw	sepc,a5
}
    80002472:	60a2                	ld	ra,8(sp)
    80002474:	6402                	ld	s0,0(sp)
    80002476:	0141                	addi	sp,sp,16
    80002478:	8082                	ret

000000008000247a <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000247a:	1101                	addi	sp,sp,-32
    8000247c:	ec06                	sd	ra,24(sp)
    8000247e:	e822                	sd	s0,16(sp)
    80002480:	1000                	addi	s0,sp,32
  if(cpuid() == 0){
    80002482:	c08ff0ef          	jal	8000188a <cpuid>
    80002486:	cd11                	beqz	a0,800024a2 <clockintr+0x28>
  asm volatile("csrr %0, time" : "=r" (x) );
    80002488:	c01027f3          	rdtime	a5
  }

  // ask for the next timer interrupt. this also clears
  // the interrupt request. 1000000 is about a tenth
  // of a second.
  w_stimecmp(r_time() + 1000000);
    8000248c:	000f4737          	lui	a4,0xf4
    80002490:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80002494:	97ba                	add	a5,a5,a4
  asm volatile("csrw 0x14d, %0" : : "r" (x));
    80002496:	14d79073          	csrw	stimecmp,a5
}
    8000249a:	60e2                	ld	ra,24(sp)
    8000249c:	6442                	ld	s0,16(sp)
    8000249e:	6105                	addi	sp,sp,32
    800024a0:	8082                	ret
    800024a2:	e426                	sd	s1,8(sp)
    acquire(&tickslock);
    800024a4:	00016497          	auipc	s1,0x16
    800024a8:	d6448493          	addi	s1,s1,-668 # 80018208 <tickslock>
    800024ac:	8526                	mv	a0,s1
    800024ae:	f1efe0ef          	jal	80000bcc <acquire>
    ticks++;
    800024b2:	00008517          	auipc	a0,0x8
    800024b6:	e2650513          	addi	a0,a0,-474 # 8000a2d8 <ticks>
    800024ba:	411c                	lw	a5,0(a0)
    800024bc:	2785                	addiw	a5,a5,1
    800024be:	c11c                	sw	a5,0(a0)
    wakeup(&ticks);
    800024c0:	a55ff0ef          	jal	80001f14 <wakeup>
    release(&tickslock);
    800024c4:	8526                	mv	a0,s1
    800024c6:	f9afe0ef          	jal	80000c60 <release>
    800024ca:	64a2                	ld	s1,8(sp)
    800024cc:	bf75                	j	80002488 <clockintr+0xe>

00000000800024ce <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800024ce:	1101                	addi	sp,sp,-32
    800024d0:	ec06                	sd	ra,24(sp)
    800024d2:	e822                	sd	s0,16(sp)
    800024d4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800024d6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if(scause == 0x8000000000000009L){
    800024da:	57fd                	li	a5,-1
    800024dc:	17fe                	slli	a5,a5,0x3f
    800024de:	07a5                	addi	a5,a5,9
    800024e0:	00f70c63          	beq	a4,a5,800024f8 <devintr+0x2a>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000005L){
    800024e4:	57fd                	li	a5,-1
    800024e6:	17fe                	slli	a5,a5,0x3f
    800024e8:	0795                	addi	a5,a5,5
    // timer interrupt.
    clockintr();
    return 2;
  } else {
    return 0;
    800024ea:	4501                	li	a0,0
  } else if(scause == 0x8000000000000005L){
    800024ec:	04f70763          	beq	a4,a5,8000253a <devintr+0x6c>
  }
}
    800024f0:	60e2                	ld	ra,24(sp)
    800024f2:	6442                	ld	s0,16(sp)
    800024f4:	6105                	addi	sp,sp,32
    800024f6:	8082                	ret
    800024f8:	e426                	sd	s1,8(sp)
    int irq = plic_claim();
    800024fa:	7e3020ef          	jal	800054dc <plic_claim>
    800024fe:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002500:	47a9                	li	a5,10
    80002502:	00f50963          	beq	a0,a5,80002514 <devintr+0x46>
    } else if(irq == VIRTIO0_IRQ){
    80002506:	4785                	li	a5,1
    80002508:	00f50963          	beq	a0,a5,8000251a <devintr+0x4c>
    return 1;
    8000250c:	4505                	li	a0,1
    } else if(irq){
    8000250e:	e889                	bnez	s1,80002520 <devintr+0x52>
    80002510:	64a2                	ld	s1,8(sp)
    80002512:	bff9                	j	800024f0 <devintr+0x22>
      uartintr();
    80002514:	c9afe0ef          	jal	800009ae <uartintr>
    if(irq)
    80002518:	a819                	j	8000252e <devintr+0x60>
      virtio_disk_intr();
    8000251a:	452030ef          	jal	8000596c <virtio_disk_intr>
    if(irq)
    8000251e:	a801                	j	8000252e <devintr+0x60>
      printf("unexpected interrupt irq=%d\n", irq);
    80002520:	85a6                	mv	a1,s1
    80002522:	00005517          	auipc	a0,0x5
    80002526:	d2e50513          	addi	a0,a0,-722 # 80007250 <etext+0x250>
    8000252a:	fd1fd0ef          	jal	800004fa <printf>
      plic_complete(irq);
    8000252e:	8526                	mv	a0,s1
    80002530:	7cd020ef          	jal	800054fc <plic_complete>
    return 1;
    80002534:	4505                	li	a0,1
    80002536:	64a2                	ld	s1,8(sp)
    80002538:	bf65                	j	800024f0 <devintr+0x22>
    clockintr();
    8000253a:	f41ff0ef          	jal	8000247a <clockintr>
    return 2;
    8000253e:	4509                	li	a0,2
    80002540:	bf45                	j	800024f0 <devintr+0x22>

0000000080002542 <usertrap>:
{
    80002542:	1101                	addi	sp,sp,-32
    80002544:	ec06                	sd	ra,24(sp)
    80002546:	e822                	sd	s0,16(sp)
    80002548:	e426                	sd	s1,8(sp)
    8000254a:	e04a                	sd	s2,0(sp)
    8000254c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000254e:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002552:	1007f793          	andi	a5,a5,256
    80002556:	eba5                	bnez	a5,800025c6 <usertrap+0x84>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002558:	00003797          	auipc	a5,0x3
    8000255c:	ed878793          	addi	a5,a5,-296 # 80005430 <kernelvec>
    80002560:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002564:	b5aff0ef          	jal	800018be <myproc>
    80002568:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    8000256a:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000256c:	14102773          	csrr	a4,sepc
    80002570:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002572:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002576:	47a1                	li	a5,8
    80002578:	04f70d63          	beq	a4,a5,800025d2 <usertrap+0x90>
  } else if((which_dev = devintr()) != 0){
    8000257c:	f53ff0ef          	jal	800024ce <devintr>
    80002580:	892a                	mv	s2,a0
    80002582:	e945                	bnez	a0,80002632 <usertrap+0xf0>
    80002584:	14202773          	csrr	a4,scause
  } else if((r_scause() == 15 || r_scause() == 13) &&
    80002588:	47bd                	li	a5,15
    8000258a:	08f70863          	beq	a4,a5,8000261a <usertrap+0xd8>
    8000258e:	14202773          	csrr	a4,scause
    80002592:	47b5                	li	a5,13
    80002594:	08f70363          	beq	a4,a5,8000261a <usertrap+0xd8>
    80002598:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause 0x%lx pid=%d\n", r_scause(), p->pid);
    8000259c:	5890                	lw	a2,48(s1)
    8000259e:	00005517          	auipc	a0,0x5
    800025a2:	cf250513          	addi	a0,a0,-782 # 80007290 <etext+0x290>
    800025a6:	f55fd0ef          	jal	800004fa <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800025aa:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800025ae:	14302673          	csrr	a2,stval
    printf("            sepc=0x%lx stval=0x%lx\n", r_sepc(), r_stval());
    800025b2:	00005517          	auipc	a0,0x5
    800025b6:	d0e50513          	addi	a0,a0,-754 # 800072c0 <etext+0x2c0>
    800025ba:	f41fd0ef          	jal	800004fa <printf>
    setkilled(p);
    800025be:	8526                	mv	a0,s1
    800025c0:	b1dff0ef          	jal	800020dc <setkilled>
    800025c4:	a035                	j	800025f0 <usertrap+0xae>
    panic("usertrap: not from user mode");
    800025c6:	00005517          	auipc	a0,0x5
    800025ca:	caa50513          	addi	a0,a0,-854 # 80007270 <etext+0x270>
    800025ce:	a10fe0ef          	jal	800007de <panic>
    if(killed(p))
    800025d2:	b2fff0ef          	jal	80002100 <killed>
    800025d6:	ed15                	bnez	a0,80002612 <usertrap+0xd0>
    p->trapframe->epc += 4;
    800025d8:	6cb8                	ld	a4,88(s1)
    800025da:	6f1c                	ld	a5,24(a4)
    800025dc:	0791                	addi	a5,a5,4
    800025de:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800025e0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800025e4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800025e8:	10079073          	csrw	sstatus,a5
    syscall();
    800025ec:	23e000ef          	jal	8000282a <syscall>
  if(killed(p))
    800025f0:	8526                	mv	a0,s1
    800025f2:	b0fff0ef          	jal	80002100 <killed>
    800025f6:	e139                	bnez	a0,8000263c <usertrap+0xfa>
  prepare_return();
    800025f8:	e09ff0ef          	jal	80002400 <prepare_return>
  uint64 satp = MAKE_SATP(p->pagetable);
    800025fc:	68a8                	ld	a0,80(s1)
    800025fe:	8131                	srli	a0,a0,0xc
    80002600:	57fd                	li	a5,-1
    80002602:	17fe                	slli	a5,a5,0x3f
    80002604:	8d5d                	or	a0,a0,a5
}
    80002606:	60e2                	ld	ra,24(sp)
    80002608:	6442                	ld	s0,16(sp)
    8000260a:	64a2                	ld	s1,8(sp)
    8000260c:	6902                	ld	s2,0(sp)
    8000260e:	6105                	addi	sp,sp,32
    80002610:	8082                	ret
      kexit(-1);
    80002612:	557d                	li	a0,-1
    80002614:	9c1ff0ef          	jal	80001fd4 <kexit>
    80002618:	b7c1                	j	800025d8 <usertrap+0x96>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000261a:	143025f3          	csrr	a1,stval
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000261e:	14202673          	csrr	a2,scause
            vmfault(p->pagetable, r_stval(), (r_scause() == 13)? 1 : 0) != 0) {
    80002622:	164d                	addi	a2,a2,-13 # ff3 <_entry-0x7ffff00d>
    80002624:	00163613          	seqz	a2,a2
    80002628:	68a8                	ld	a0,80(s1)
    8000262a:	f45fe0ef          	jal	8000156e <vmfault>
  } else if((r_scause() == 15 || r_scause() == 13) &&
    8000262e:	f169                	bnez	a0,800025f0 <usertrap+0xae>
    80002630:	b7a5                	j	80002598 <usertrap+0x56>
  if(killed(p))
    80002632:	8526                	mv	a0,s1
    80002634:	acdff0ef          	jal	80002100 <killed>
    80002638:	c511                	beqz	a0,80002644 <usertrap+0x102>
    8000263a:	a011                	j	8000263e <usertrap+0xfc>
    8000263c:	4901                	li	s2,0
    kexit(-1);
    8000263e:	557d                	li	a0,-1
    80002640:	995ff0ef          	jal	80001fd4 <kexit>
  if(which_dev == 2)
    80002644:	4789                	li	a5,2
    80002646:	faf919e3          	bne	s2,a5,800025f8 <usertrap+0xb6>
    yield();
    8000264a:	853ff0ef          	jal	80001e9c <yield>
    8000264e:	b76d                	j	800025f8 <usertrap+0xb6>

0000000080002650 <kerneltrap>:
{
    80002650:	7179                	addi	sp,sp,-48
    80002652:	f406                	sd	ra,40(sp)
    80002654:	f022                	sd	s0,32(sp)
    80002656:	ec26                	sd	s1,24(sp)
    80002658:	e84a                	sd	s2,16(sp)
    8000265a:	e44e                	sd	s3,8(sp)
    8000265c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000265e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002662:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002666:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000266a:	1004f793          	andi	a5,s1,256
    8000266e:	c795                	beqz	a5,8000269a <kerneltrap+0x4a>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002670:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002674:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002676:	eb85                	bnez	a5,800026a6 <kerneltrap+0x56>
  if((which_dev = devintr()) == 0){
    80002678:	e57ff0ef          	jal	800024ce <devintr>
    8000267c:	c91d                	beqz	a0,800026b2 <kerneltrap+0x62>
  if(which_dev == 2 && myproc() != 0)
    8000267e:	4789                	li	a5,2
    80002680:	04f50a63          	beq	a0,a5,800026d4 <kerneltrap+0x84>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002684:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002688:	10049073          	csrw	sstatus,s1
}
    8000268c:	70a2                	ld	ra,40(sp)
    8000268e:	7402                	ld	s0,32(sp)
    80002690:	64e2                	ld	s1,24(sp)
    80002692:	6942                	ld	s2,16(sp)
    80002694:	69a2                	ld	s3,8(sp)
    80002696:	6145                	addi	sp,sp,48
    80002698:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000269a:	00005517          	auipc	a0,0x5
    8000269e:	c4e50513          	addi	a0,a0,-946 # 800072e8 <etext+0x2e8>
    800026a2:	93cfe0ef          	jal	800007de <panic>
    panic("kerneltrap: interrupts enabled");
    800026a6:	00005517          	auipc	a0,0x5
    800026aa:	c6a50513          	addi	a0,a0,-918 # 80007310 <etext+0x310>
    800026ae:	930fe0ef          	jal	800007de <panic>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800026b2:	14102673          	csrr	a2,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800026b6:	143026f3          	csrr	a3,stval
    printf("scause=0x%lx sepc=0x%lx stval=0x%lx\n", scause, r_sepc(), r_stval());
    800026ba:	85ce                	mv	a1,s3
    800026bc:	00005517          	auipc	a0,0x5
    800026c0:	c7450513          	addi	a0,a0,-908 # 80007330 <etext+0x330>
    800026c4:	e37fd0ef          	jal	800004fa <printf>
    panic("kerneltrap");
    800026c8:	00005517          	auipc	a0,0x5
    800026cc:	c9050513          	addi	a0,a0,-880 # 80007358 <etext+0x358>
    800026d0:	90efe0ef          	jal	800007de <panic>
  if(which_dev == 2 && myproc() != 0)
    800026d4:	9eaff0ef          	jal	800018be <myproc>
    800026d8:	d555                	beqz	a0,80002684 <kerneltrap+0x34>
    yield();
    800026da:	fc2ff0ef          	jal	80001e9c <yield>
    800026de:	b75d                	j	80002684 <kerneltrap+0x34>

00000000800026e0 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800026e0:	1101                	addi	sp,sp,-32
    800026e2:	ec06                	sd	ra,24(sp)
    800026e4:	e822                	sd	s0,16(sp)
    800026e6:	e426                	sd	s1,8(sp)
    800026e8:	1000                	addi	s0,sp,32
    800026ea:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    800026ec:	9d2ff0ef          	jal	800018be <myproc>
  switch (n) {
    800026f0:	4795                	li	a5,5
    800026f2:	0497e163          	bltu	a5,s1,80002734 <argraw+0x54>
    800026f6:	048a                	slli	s1,s1,0x2
    800026f8:	00005717          	auipc	a4,0x5
    800026fc:	06070713          	addi	a4,a4,96 # 80007758 <states.0+0x30>
    80002700:	94ba                	add	s1,s1,a4
    80002702:	409c                	lw	a5,0(s1)
    80002704:	97ba                	add	a5,a5,a4
    80002706:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002708:	6d3c                	ld	a5,88(a0)
    8000270a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000270c:	60e2                	ld	ra,24(sp)
    8000270e:	6442                	ld	s0,16(sp)
    80002710:	64a2                	ld	s1,8(sp)
    80002712:	6105                	addi	sp,sp,32
    80002714:	8082                	ret
    return p->trapframe->a1;
    80002716:	6d3c                	ld	a5,88(a0)
    80002718:	7fa8                	ld	a0,120(a5)
    8000271a:	bfcd                	j	8000270c <argraw+0x2c>
    return p->trapframe->a2;
    8000271c:	6d3c                	ld	a5,88(a0)
    8000271e:	63c8                	ld	a0,128(a5)
    80002720:	b7f5                	j	8000270c <argraw+0x2c>
    return p->trapframe->a3;
    80002722:	6d3c                	ld	a5,88(a0)
    80002724:	67c8                	ld	a0,136(a5)
    80002726:	b7dd                	j	8000270c <argraw+0x2c>
    return p->trapframe->a4;
    80002728:	6d3c                	ld	a5,88(a0)
    8000272a:	6bc8                	ld	a0,144(a5)
    8000272c:	b7c5                	j	8000270c <argraw+0x2c>
    return p->trapframe->a5;
    8000272e:	6d3c                	ld	a5,88(a0)
    80002730:	6fc8                	ld	a0,152(a5)
    80002732:	bfe9                	j	8000270c <argraw+0x2c>
  panic("argraw");
    80002734:	00005517          	auipc	a0,0x5
    80002738:	c3450513          	addi	a0,a0,-972 # 80007368 <etext+0x368>
    8000273c:	8a2fe0ef          	jal	800007de <panic>

0000000080002740 <fetchaddr>:
{
    80002740:	1101                	addi	sp,sp,-32
    80002742:	ec06                	sd	ra,24(sp)
    80002744:	e822                	sd	s0,16(sp)
    80002746:	e426                	sd	s1,8(sp)
    80002748:	e04a                	sd	s2,0(sp)
    8000274a:	1000                	addi	s0,sp,32
    8000274c:	84aa                	mv	s1,a0
    8000274e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002750:	96eff0ef          	jal	800018be <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002754:	653c                	ld	a5,72(a0)
    80002756:	02f4f663          	bgeu	s1,a5,80002782 <fetchaddr+0x42>
    8000275a:	00848713          	addi	a4,s1,8
    8000275e:	02e7e463          	bltu	a5,a4,80002786 <fetchaddr+0x46>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002762:	46a1                	li	a3,8
    80002764:	8626                	mv	a2,s1
    80002766:	85ca                	mv	a1,s2
    80002768:	6928                	ld	a0,80(a0)
    8000276a:	f45fe0ef          	jal	800016ae <copyin>
    8000276e:	00a03533          	snez	a0,a0
    80002772:	40a0053b          	negw	a0,a0
}
    80002776:	60e2                	ld	ra,24(sp)
    80002778:	6442                	ld	s0,16(sp)
    8000277a:	64a2                	ld	s1,8(sp)
    8000277c:	6902                	ld	s2,0(sp)
    8000277e:	6105                	addi	sp,sp,32
    80002780:	8082                	ret
    return -1;
    80002782:	557d                	li	a0,-1
    80002784:	bfcd                	j	80002776 <fetchaddr+0x36>
    80002786:	557d                	li	a0,-1
    80002788:	b7fd                	j	80002776 <fetchaddr+0x36>

000000008000278a <fetchstr>:
{
    8000278a:	7179                	addi	sp,sp,-48
    8000278c:	f406                	sd	ra,40(sp)
    8000278e:	f022                	sd	s0,32(sp)
    80002790:	ec26                	sd	s1,24(sp)
    80002792:	e84a                	sd	s2,16(sp)
    80002794:	e44e                	sd	s3,8(sp)
    80002796:	1800                	addi	s0,sp,48
    80002798:	892a                	mv	s2,a0
    8000279a:	84ae                	mv	s1,a1
    8000279c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000279e:	920ff0ef          	jal	800018be <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    800027a2:	86ce                	mv	a3,s3
    800027a4:	864a                	mv	a2,s2
    800027a6:	85a6                	mv	a1,s1
    800027a8:	6928                	ld	a0,80(a0)
    800027aa:	d05fe0ef          	jal	800014ae <copyinstr>
    800027ae:	00054c63          	bltz	a0,800027c6 <fetchstr+0x3c>
  return strlen(buf);
    800027b2:	8526                	mv	a0,s1
    800027b4:	e70fe0ef          	jal	80000e24 <strlen>
}
    800027b8:	70a2                	ld	ra,40(sp)
    800027ba:	7402                	ld	s0,32(sp)
    800027bc:	64e2                	ld	s1,24(sp)
    800027be:	6942                	ld	s2,16(sp)
    800027c0:	69a2                	ld	s3,8(sp)
    800027c2:	6145                	addi	sp,sp,48
    800027c4:	8082                	ret
    return -1;
    800027c6:	557d                	li	a0,-1
    800027c8:	bfc5                	j	800027b8 <fetchstr+0x2e>

00000000800027ca <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    800027ca:	1101                	addi	sp,sp,-32
    800027cc:	ec06                	sd	ra,24(sp)
    800027ce:	e822                	sd	s0,16(sp)
    800027d0:	e426                	sd	s1,8(sp)
    800027d2:	1000                	addi	s0,sp,32
    800027d4:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800027d6:	f0bff0ef          	jal	800026e0 <argraw>
    800027da:	c088                	sw	a0,0(s1)
}
    800027dc:	60e2                	ld	ra,24(sp)
    800027de:	6442                	ld	s0,16(sp)
    800027e0:	64a2                	ld	s1,8(sp)
    800027e2:	6105                	addi	sp,sp,32
    800027e4:	8082                	ret

00000000800027e6 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800027e6:	1101                	addi	sp,sp,-32
    800027e8:	ec06                	sd	ra,24(sp)
    800027ea:	e822                	sd	s0,16(sp)
    800027ec:	e426                	sd	s1,8(sp)
    800027ee:	1000                	addi	s0,sp,32
    800027f0:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800027f2:	eefff0ef          	jal	800026e0 <argraw>
    800027f6:	e088                	sd	a0,0(s1)
}
    800027f8:	60e2                	ld	ra,24(sp)
    800027fa:	6442                	ld	s0,16(sp)
    800027fc:	64a2                	ld	s1,8(sp)
    800027fe:	6105                	addi	sp,sp,32
    80002800:	8082                	ret

0000000080002802 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002802:	1101                	addi	sp,sp,-32
    80002804:	ec06                	sd	ra,24(sp)
    80002806:	e822                	sd	s0,16(sp)
    80002808:	e426                	sd	s1,8(sp)
    8000280a:	e04a                	sd	s2,0(sp)
    8000280c:	1000                	addi	s0,sp,32
    8000280e:	84ae                	mv	s1,a1
    80002810:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002812:	ecfff0ef          	jal	800026e0 <argraw>
  uint64 addr;
  argaddr(n, &addr);
  return fetchstr(addr, buf, max);
    80002816:	864a                	mv	a2,s2
    80002818:	85a6                	mv	a1,s1
    8000281a:	f71ff0ef          	jal	8000278a <fetchstr>
}
    8000281e:	60e2                	ld	ra,24(sp)
    80002820:	6442                	ld	s0,16(sp)
    80002822:	64a2                	ld	s1,8(sp)
    80002824:	6902                	ld	s2,0(sp)
    80002826:	6105                	addi	sp,sp,32
    80002828:	8082                	ret

000000008000282a <syscall>:
[SYS_sleep] sys_sleep, // new table entry
};

void
syscall(void)
{
    8000282a:	1101                	addi	sp,sp,-32
    8000282c:	ec06                	sd	ra,24(sp)
    8000282e:	e822                	sd	s0,16(sp)
    80002830:	e426                	sd	s1,8(sp)
    80002832:	e04a                	sd	s2,0(sp)
    80002834:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002836:	888ff0ef          	jal	800018be <myproc>
    8000283a:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    8000283c:	05853903          	ld	s2,88(a0)
    80002840:	0a893783          	ld	a5,168(s2)
    80002844:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002848:	37fd                	addiw	a5,a5,-1
    8000284a:	4759                	li	a4,22
    8000284c:	00f76f63          	bltu	a4,a5,8000286a <syscall+0x40>
    80002850:	00369713          	slli	a4,a3,0x3
    80002854:	00005797          	auipc	a5,0x5
    80002858:	f1c78793          	addi	a5,a5,-228 # 80007770 <syscalls>
    8000285c:	97ba                	add	a5,a5,a4
    8000285e:	639c                	ld	a5,0(a5)
    80002860:	c789                	beqz	a5,8000286a <syscall+0x40>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002862:	9782                	jalr	a5
    80002864:	06a93823          	sd	a0,112(s2)
    80002868:	a829                	j	80002882 <syscall+0x58>
  } else {
    printf("%d %s: unknown sys call %d\n",
    8000286a:	15848613          	addi	a2,s1,344
    8000286e:	588c                	lw	a1,48(s1)
    80002870:	00005517          	auipc	a0,0x5
    80002874:	b0050513          	addi	a0,a0,-1280 # 80007370 <etext+0x370>
    80002878:	c83fd0ef          	jal	800004fa <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000287c:	6cbc                	ld	a5,88(s1)
    8000287e:	577d                	li	a4,-1
    80002880:	fbb8                	sd	a4,112(a5)
  }
}
    80002882:	60e2                	ld	ra,24(sp)
    80002884:	6442                	ld	s0,16(sp)
    80002886:	64a2                	ld	s1,8(sp)
    80002888:	6902                	ld	s2,0(sp)
    8000288a:	6105                	addi	sp,sp,32
    8000288c:	8082                	ret

000000008000288e <sys_sleep>:
//sleep(int)
extern uint ticks;
extern struct spinlock tickslock;
uint64
sys_sleep(void)
{
    8000288e:	7139                	addi	sp,sp,-64
    80002890:	fc06                	sd	ra,56(sp)
    80002892:	f822                	sd	s0,48(sp)
    80002894:	0080                	addi	s0,sp,64
int n = 0;
    80002896:	fc042623          	sw	zero,-52(s0)
uint ticks0;
// Read the first syscall argument (ticks) into n.
// Here we do not compare the return of argint; we just use it to store n.
argint(0, &n);
    8000289a:	fcc40593          	addi	a1,s0,-52
    8000289e:	4501                	li	a0,0
    800028a0:	f2bff0ef          	jal	800027ca <argint>
// Defensive check: non-positive sleep duration does nothing.
if(n <= 0)
    800028a4:	fcc42783          	lw	a5,-52(s0)
return 0;
    800028a8:	4501                	li	a0,0
if(n <= 0)
    800028aa:	06f05363          	blez	a5,80002910 <sys_sleep+0x82>
    800028ae:	f04a                	sd	s2,32(sp)
acquire(&tickslock);
    800028b0:	00016517          	auipc	a0,0x16
    800028b4:	95850513          	addi	a0,a0,-1704 # 80018208 <tickslock>
    800028b8:	b14fe0ef          	jal	80000bcc <acquire>
ticks0 = ticks;
    800028bc:	00008917          	auipc	s2,0x8
    800028c0:	a1c92903          	lw	s2,-1508(s2) # 8000a2d8 <ticks>
while(ticks - ticks0 < (uint)n){
    800028c4:	fcc42783          	lw	a5,-52(s0)
    800028c8:	cf85                	beqz	a5,80002900 <sys_sleep+0x72>
    800028ca:	f426                	sd	s1,40(sp)
    800028cc:	ec4e                	sd	s3,24(sp)
if(myproc()->killed){
release(&tickslock);
return -1;
}
// Sleep on the address of ticks while holding tickslock.
sleep(&ticks, &tickslock);
    800028ce:	00016997          	auipc	s3,0x16
    800028d2:	93a98993          	addi	s3,s3,-1734 # 80018208 <tickslock>
    800028d6:	00008497          	auipc	s1,0x8
    800028da:	a0248493          	addi	s1,s1,-1534 # 8000a2d8 <ticks>
if(myproc()->killed){
    800028de:	fe1fe0ef          	jal	800018be <myproc>
    800028e2:	551c                	lw	a5,40(a0)
    800028e4:	eb95                	bnez	a5,80002918 <sys_sleep+0x8a>
sleep(&ticks, &tickslock);
    800028e6:	85ce                	mv	a1,s3
    800028e8:	8526                	mv	a0,s1
    800028ea:	ddeff0ef          	jal	80001ec8 <sleep>
while(ticks - ticks0 < (uint)n){
    800028ee:	409c                	lw	a5,0(s1)
    800028f0:	412787bb          	subw	a5,a5,s2
    800028f4:	fcc42703          	lw	a4,-52(s0)
    800028f8:	fee7e3e3          	bltu	a5,a4,800028de <sys_sleep+0x50>
    800028fc:	74a2                	ld	s1,40(sp)
    800028fe:	69e2                	ld	s3,24(sp)
// When sleep() returns, tickslock has been re-acquired.
}
release(&tickslock);
    80002900:	00016517          	auipc	a0,0x16
    80002904:	90850513          	addi	a0,a0,-1784 # 80018208 <tickslock>
    80002908:	b58fe0ef          	jal	80000c60 <release>
return 0;
    8000290c:	4501                	li	a0,0
    8000290e:	7902                	ld	s2,32(sp)
}
    80002910:	70e2                	ld	ra,56(sp)
    80002912:	7442                	ld	s0,48(sp)
    80002914:	6121                	addi	sp,sp,64
    80002916:	8082                	ret
release(&tickslock);
    80002918:	00016517          	auipc	a0,0x16
    8000291c:	8f050513          	addi	a0,a0,-1808 # 80018208 <tickslock>
    80002920:	b40fe0ef          	jal	80000c60 <release>
return -1;
    80002924:	557d                	li	a0,-1
    80002926:	74a2                	ld	s1,40(sp)
    80002928:	7902                	ld	s2,32(sp)
    8000292a:	69e2                	ld	s3,24(sp)
    8000292c:	b7d5                	j	80002910 <sys_sleep+0x82>

000000008000292e <sys_ps>:

// ps
uint64
sys_ps(void)
{
    8000292e:	1141                	addi	sp,sp,-16
    80002930:	e406                	sd	ra,8(sp)
    80002932:	e022                	sd	s0,0(sp)
    80002934:	0800                	addi	s0,sp,16
procdump(); // print the process table to the console
    80002936:	97dff0ef          	jal	800022b2 <procdump>
return 0;
}
    8000293a:	4501                	li	a0,0
    8000293c:	60a2                	ld	ra,8(sp)
    8000293e:	6402                	ld	s0,0(sp)
    80002940:	0141                	addi	sp,sp,16
    80002942:	8082                	ret

0000000080002944 <sys_exit>:

uint64
sys_exit(void)
{
    80002944:	1101                	addi	sp,sp,-32
    80002946:	ec06                	sd	ra,24(sp)
    80002948:	e822                	sd	s0,16(sp)
    8000294a:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    8000294c:	fec40593          	addi	a1,s0,-20
    80002950:	4501                	li	a0,0
    80002952:	e79ff0ef          	jal	800027ca <argint>
  kexit(n);
    80002956:	fec42503          	lw	a0,-20(s0)
    8000295a:	e7aff0ef          	jal	80001fd4 <kexit>
  return 0;  // not reached
}
    8000295e:	4501                	li	a0,0
    80002960:	60e2                	ld	ra,24(sp)
    80002962:	6442                	ld	s0,16(sp)
    80002964:	6105                	addi	sp,sp,32
    80002966:	8082                	ret

0000000080002968 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002968:	1141                	addi	sp,sp,-16
    8000296a:	e406                	sd	ra,8(sp)
    8000296c:	e022                	sd	s0,0(sp)
    8000296e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002970:	f4ffe0ef          	jal	800018be <myproc>
}
    80002974:	5908                	lw	a0,48(a0)
    80002976:	60a2                	ld	ra,8(sp)
    80002978:	6402                	ld	s0,0(sp)
    8000297a:	0141                	addi	sp,sp,16
    8000297c:	8082                	ret

000000008000297e <sys_fork>:

uint64
sys_fork(void)
{
    8000297e:	1141                	addi	sp,sp,-16
    80002980:	e406                	sd	ra,8(sp)
    80002982:	e022                	sd	s0,0(sp)
    80002984:	0800                	addi	s0,sp,16
  return kfork();
    80002986:	a9cff0ef          	jal	80001c22 <kfork>
}
    8000298a:	60a2                	ld	ra,8(sp)
    8000298c:	6402                	ld	s0,0(sp)
    8000298e:	0141                	addi	sp,sp,16
    80002990:	8082                	ret

0000000080002992 <sys_wait>:

uint64
sys_wait(void)
{
    80002992:	1101                	addi	sp,sp,-32
    80002994:	ec06                	sd	ra,24(sp)
    80002996:	e822                	sd	s0,16(sp)
    80002998:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    8000299a:	fe840593          	addi	a1,s0,-24
    8000299e:	4501                	li	a0,0
    800029a0:	e47ff0ef          	jal	800027e6 <argaddr>
  return kwait(p);
    800029a4:	fe843503          	ld	a0,-24(s0)
    800029a8:	f82ff0ef          	jal	8000212a <kwait>
}
    800029ac:	60e2                	ld	ra,24(sp)
    800029ae:	6442                	ld	s0,16(sp)
    800029b0:	6105                	addi	sp,sp,32
    800029b2:	8082                	ret

00000000800029b4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800029b4:	7179                	addi	sp,sp,-48
    800029b6:	f406                	sd	ra,40(sp)
    800029b8:	f022                	sd	s0,32(sp)
    800029ba:	ec26                	sd	s1,24(sp)
    800029bc:	1800                	addi	s0,sp,48
  uint64 addr;
  int t;
  int n;

  argint(0, &n);
    800029be:	fd840593          	addi	a1,s0,-40
    800029c2:	4501                	li	a0,0
    800029c4:	e07ff0ef          	jal	800027ca <argint>
  argint(1, &t);
    800029c8:	fdc40593          	addi	a1,s0,-36
    800029cc:	4505                	li	a0,1
    800029ce:	dfdff0ef          	jal	800027ca <argint>
  addr = myproc()->sz;
    800029d2:	eedfe0ef          	jal	800018be <myproc>
    800029d6:	6524                	ld	s1,72(a0)

  if(t == SBRK_EAGER || n < 0) {
    800029d8:	fdc42703          	lw	a4,-36(s0)
    800029dc:	4785                	li	a5,1
    800029de:	02f70763          	beq	a4,a5,80002a0c <sys_sbrk+0x58>
    800029e2:	fd842783          	lw	a5,-40(s0)
    800029e6:	0207c363          	bltz	a5,80002a0c <sys_sbrk+0x58>
    }
  } else {
    // Lazily allocate memory for this process: increase its memory
    // size but don't allocate memory. If the processes uses the
    // memory, vmfault() will allocate it.
    if(addr + n < addr)
    800029ea:	97a6                	add	a5,a5,s1
    800029ec:	0297ee63          	bltu	a5,s1,80002a28 <sys_sbrk+0x74>
      return -1;
    if(addr + n > TRAPFRAME)
    800029f0:	02000737          	lui	a4,0x2000
    800029f4:	177d                	addi	a4,a4,-1 # 1ffffff <_entry-0x7e000001>
    800029f6:	0736                	slli	a4,a4,0xd
    800029f8:	02f76a63          	bltu	a4,a5,80002a2c <sys_sbrk+0x78>
      return -1;
    myproc()->sz += n;
    800029fc:	ec3fe0ef          	jal	800018be <myproc>
    80002a00:	fd842703          	lw	a4,-40(s0)
    80002a04:	653c                	ld	a5,72(a0)
    80002a06:	97ba                	add	a5,a5,a4
    80002a08:	e53c                	sd	a5,72(a0)
    80002a0a:	a039                	j	80002a18 <sys_sbrk+0x64>
    if(growproc(n) < 0) {
    80002a0c:	fd842503          	lw	a0,-40(s0)
    80002a10:	9b0ff0ef          	jal	80001bc0 <growproc>
    80002a14:	00054863          	bltz	a0,80002a24 <sys_sbrk+0x70>
  }
  return addr;
}
    80002a18:	8526                	mv	a0,s1
    80002a1a:	70a2                	ld	ra,40(sp)
    80002a1c:	7402                	ld	s0,32(sp)
    80002a1e:	64e2                	ld	s1,24(sp)
    80002a20:	6145                	addi	sp,sp,48
    80002a22:	8082                	ret
      return -1;
    80002a24:	54fd                	li	s1,-1
    80002a26:	bfcd                	j	80002a18 <sys_sbrk+0x64>
      return -1;
    80002a28:	54fd                	li	s1,-1
    80002a2a:	b7fd                	j	80002a18 <sys_sbrk+0x64>
      return -1;
    80002a2c:	54fd                	li	s1,-1
    80002a2e:	b7ed                	j	80002a18 <sys_sbrk+0x64>

0000000080002a30 <sys_pause>:

uint64
sys_pause(void)
{
    80002a30:	7139                	addi	sp,sp,-64
    80002a32:	fc06                	sd	ra,56(sp)
    80002a34:	f822                	sd	s0,48(sp)
    80002a36:	f04a                	sd	s2,32(sp)
    80002a38:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002a3a:	fcc40593          	addi	a1,s0,-52
    80002a3e:	4501                	li	a0,0
    80002a40:	d8bff0ef          	jal	800027ca <argint>
  if(n < 0)
    80002a44:	fcc42783          	lw	a5,-52(s0)
    80002a48:	0607c763          	bltz	a5,80002ab6 <sys_pause+0x86>
    n = 0;
  acquire(&tickslock);
    80002a4c:	00015517          	auipc	a0,0x15
    80002a50:	7bc50513          	addi	a0,a0,1980 # 80018208 <tickslock>
    80002a54:	978fe0ef          	jal	80000bcc <acquire>
  ticks0 = ticks;
    80002a58:	00008917          	auipc	s2,0x8
    80002a5c:	88092903          	lw	s2,-1920(s2) # 8000a2d8 <ticks>
  while(ticks - ticks0 < n){
    80002a60:	fcc42783          	lw	a5,-52(s0)
    80002a64:	cf8d                	beqz	a5,80002a9e <sys_pause+0x6e>
    80002a66:	f426                	sd	s1,40(sp)
    80002a68:	ec4e                	sd	s3,24(sp)
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002a6a:	00015997          	auipc	s3,0x15
    80002a6e:	79e98993          	addi	s3,s3,1950 # 80018208 <tickslock>
    80002a72:	00008497          	auipc	s1,0x8
    80002a76:	86648493          	addi	s1,s1,-1946 # 8000a2d8 <ticks>
    if(killed(myproc())){
    80002a7a:	e45fe0ef          	jal	800018be <myproc>
    80002a7e:	e82ff0ef          	jal	80002100 <killed>
    80002a82:	ed0d                	bnez	a0,80002abc <sys_pause+0x8c>
    sleep(&ticks, &tickslock);
    80002a84:	85ce                	mv	a1,s3
    80002a86:	8526                	mv	a0,s1
    80002a88:	c40ff0ef          	jal	80001ec8 <sleep>
  while(ticks - ticks0 < n){
    80002a8c:	409c                	lw	a5,0(s1)
    80002a8e:	412787bb          	subw	a5,a5,s2
    80002a92:	fcc42703          	lw	a4,-52(s0)
    80002a96:	fee7e2e3          	bltu	a5,a4,80002a7a <sys_pause+0x4a>
    80002a9a:	74a2                	ld	s1,40(sp)
    80002a9c:	69e2                	ld	s3,24(sp)
  }
  release(&tickslock);
    80002a9e:	00015517          	auipc	a0,0x15
    80002aa2:	76a50513          	addi	a0,a0,1898 # 80018208 <tickslock>
    80002aa6:	9bafe0ef          	jal	80000c60 <release>
  return 0;
    80002aaa:	4501                	li	a0,0
}
    80002aac:	70e2                	ld	ra,56(sp)
    80002aae:	7442                	ld	s0,48(sp)
    80002ab0:	7902                	ld	s2,32(sp)
    80002ab2:	6121                	addi	sp,sp,64
    80002ab4:	8082                	ret
    n = 0;
    80002ab6:	fc042623          	sw	zero,-52(s0)
    80002aba:	bf49                	j	80002a4c <sys_pause+0x1c>
      release(&tickslock);
    80002abc:	00015517          	auipc	a0,0x15
    80002ac0:	74c50513          	addi	a0,a0,1868 # 80018208 <tickslock>
    80002ac4:	99cfe0ef          	jal	80000c60 <release>
      return -1;
    80002ac8:	557d                	li	a0,-1
    80002aca:	74a2                	ld	s1,40(sp)
    80002acc:	69e2                	ld	s3,24(sp)
    80002ace:	bff9                	j	80002aac <sys_pause+0x7c>

0000000080002ad0 <sys_kill>:

uint64
sys_kill(void)
{
    80002ad0:	1101                	addi	sp,sp,-32
    80002ad2:	ec06                	sd	ra,24(sp)
    80002ad4:	e822                	sd	s0,16(sp)
    80002ad6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002ad8:	fec40593          	addi	a1,s0,-20
    80002adc:	4501                	li	a0,0
    80002ade:	cedff0ef          	jal	800027ca <argint>
  return kkill(pid);
    80002ae2:	fec42503          	lw	a0,-20(s0)
    80002ae6:	d90ff0ef          	jal	80002076 <kkill>
}
    80002aea:	60e2                	ld	ra,24(sp)
    80002aec:	6442                	ld	s0,16(sp)
    80002aee:	6105                	addi	sp,sp,32
    80002af0:	8082                	ret

0000000080002af2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002af2:	1101                	addi	sp,sp,-32
    80002af4:	ec06                	sd	ra,24(sp)
    80002af6:	e822                	sd	s0,16(sp)
    80002af8:	e426                	sd	s1,8(sp)
    80002afa:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002afc:	00015517          	auipc	a0,0x15
    80002b00:	70c50513          	addi	a0,a0,1804 # 80018208 <tickslock>
    80002b04:	8c8fe0ef          	jal	80000bcc <acquire>
  xticks = ticks;
    80002b08:	00007497          	auipc	s1,0x7
    80002b0c:	7d04a483          	lw	s1,2000(s1) # 8000a2d8 <ticks>
  release(&tickslock);
    80002b10:	00015517          	auipc	a0,0x15
    80002b14:	6f850513          	addi	a0,a0,1784 # 80018208 <tickslock>
    80002b18:	948fe0ef          	jal	80000c60 <release>
  return xticks;
}
    80002b1c:	02049513          	slli	a0,s1,0x20
    80002b20:	9101                	srli	a0,a0,0x20
    80002b22:	60e2                	ld	ra,24(sp)
    80002b24:	6442                	ld	s0,16(sp)
    80002b26:	64a2                	ld	s1,8(sp)
    80002b28:	6105                	addi	sp,sp,32
    80002b2a:	8082                	ret

0000000080002b2c <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002b2c:	7179                	addi	sp,sp,-48
    80002b2e:	f406                	sd	ra,40(sp)
    80002b30:	f022                	sd	s0,32(sp)
    80002b32:	ec26                	sd	s1,24(sp)
    80002b34:	e84a                	sd	s2,16(sp)
    80002b36:	e44e                	sd	s3,8(sp)
    80002b38:	e052                	sd	s4,0(sp)
    80002b3a:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002b3c:	00005597          	auipc	a1,0x5
    80002b40:	85458593          	addi	a1,a1,-1964 # 80007390 <etext+0x390>
    80002b44:	00015517          	auipc	a0,0x15
    80002b48:	6dc50513          	addi	a0,a0,1756 # 80018220 <bcache>
    80002b4c:	ffdfd0ef          	jal	80000b48 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002b50:	0001d797          	auipc	a5,0x1d
    80002b54:	6d078793          	addi	a5,a5,1744 # 80020220 <bcache+0x8000>
    80002b58:	0001e717          	auipc	a4,0x1e
    80002b5c:	93070713          	addi	a4,a4,-1744 # 80020488 <bcache+0x8268>
    80002b60:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002b64:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b68:	00015497          	auipc	s1,0x15
    80002b6c:	6d048493          	addi	s1,s1,1744 # 80018238 <bcache+0x18>
    b->next = bcache.head.next;
    80002b70:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002b72:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002b74:	00005a17          	auipc	s4,0x5
    80002b78:	824a0a13          	addi	s4,s4,-2012 # 80007398 <etext+0x398>
    b->next = bcache.head.next;
    80002b7c:	2b893783          	ld	a5,696(s2)
    80002b80:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002b82:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002b86:	85d2                	mv	a1,s4
    80002b88:	01048513          	addi	a0,s1,16
    80002b8c:	31c010ef          	jal	80003ea8 <initsleeplock>
    bcache.head.next->prev = b;
    80002b90:	2b893783          	ld	a5,696(s2)
    80002b94:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002b96:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002b9a:	45848493          	addi	s1,s1,1112
    80002b9e:	fd349fe3          	bne	s1,s3,80002b7c <binit+0x50>
  }
}
    80002ba2:	70a2                	ld	ra,40(sp)
    80002ba4:	7402                	ld	s0,32(sp)
    80002ba6:	64e2                	ld	s1,24(sp)
    80002ba8:	6942                	ld	s2,16(sp)
    80002baa:	69a2                	ld	s3,8(sp)
    80002bac:	6a02                	ld	s4,0(sp)
    80002bae:	6145                	addi	sp,sp,48
    80002bb0:	8082                	ret

0000000080002bb2 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002bb2:	7179                	addi	sp,sp,-48
    80002bb4:	f406                	sd	ra,40(sp)
    80002bb6:	f022                	sd	s0,32(sp)
    80002bb8:	ec26                	sd	s1,24(sp)
    80002bba:	e84a                	sd	s2,16(sp)
    80002bbc:	e44e                	sd	s3,8(sp)
    80002bbe:	1800                	addi	s0,sp,48
    80002bc0:	892a                	mv	s2,a0
    80002bc2:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002bc4:	00015517          	auipc	a0,0x15
    80002bc8:	65c50513          	addi	a0,a0,1628 # 80018220 <bcache>
    80002bcc:	800fe0ef          	jal	80000bcc <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002bd0:	0001e497          	auipc	s1,0x1e
    80002bd4:	9084b483          	ld	s1,-1784(s1) # 800204d8 <bcache+0x82b8>
    80002bd8:	0001e797          	auipc	a5,0x1e
    80002bdc:	8b078793          	addi	a5,a5,-1872 # 80020488 <bcache+0x8268>
    80002be0:	02f48b63          	beq	s1,a5,80002c16 <bread+0x64>
    80002be4:	873e                	mv	a4,a5
    80002be6:	a021                	j	80002bee <bread+0x3c>
    80002be8:	68a4                	ld	s1,80(s1)
    80002bea:	02e48663          	beq	s1,a4,80002c16 <bread+0x64>
    if(b->dev == dev && b->blockno == blockno){
    80002bee:	449c                	lw	a5,8(s1)
    80002bf0:	ff279ce3          	bne	a5,s2,80002be8 <bread+0x36>
    80002bf4:	44dc                	lw	a5,12(s1)
    80002bf6:	ff3799e3          	bne	a5,s3,80002be8 <bread+0x36>
      b->refcnt++;
    80002bfa:	40bc                	lw	a5,64(s1)
    80002bfc:	2785                	addiw	a5,a5,1
    80002bfe:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002c00:	00015517          	auipc	a0,0x15
    80002c04:	62050513          	addi	a0,a0,1568 # 80018220 <bcache>
    80002c08:	858fe0ef          	jal	80000c60 <release>
      acquiresleep(&b->lock);
    80002c0c:	01048513          	addi	a0,s1,16
    80002c10:	2ce010ef          	jal	80003ede <acquiresleep>
      return b;
    80002c14:	a889                	j	80002c66 <bread+0xb4>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c16:	0001e497          	auipc	s1,0x1e
    80002c1a:	8ba4b483          	ld	s1,-1862(s1) # 800204d0 <bcache+0x82b0>
    80002c1e:	0001e797          	auipc	a5,0x1e
    80002c22:	86a78793          	addi	a5,a5,-1942 # 80020488 <bcache+0x8268>
    80002c26:	00f48863          	beq	s1,a5,80002c36 <bread+0x84>
    80002c2a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002c2c:	40bc                	lw	a5,64(s1)
    80002c2e:	cb91                	beqz	a5,80002c42 <bread+0x90>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002c30:	64a4                	ld	s1,72(s1)
    80002c32:	fee49de3          	bne	s1,a4,80002c2c <bread+0x7a>
  panic("bget: no buffers");
    80002c36:	00004517          	auipc	a0,0x4
    80002c3a:	76a50513          	addi	a0,a0,1898 # 800073a0 <etext+0x3a0>
    80002c3e:	ba1fd0ef          	jal	800007de <panic>
      b->dev = dev;
    80002c42:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80002c46:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80002c4a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002c4e:	4785                	li	a5,1
    80002c50:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002c52:	00015517          	auipc	a0,0x15
    80002c56:	5ce50513          	addi	a0,a0,1486 # 80018220 <bcache>
    80002c5a:	806fe0ef          	jal	80000c60 <release>
      acquiresleep(&b->lock);
    80002c5e:	01048513          	addi	a0,s1,16
    80002c62:	27c010ef          	jal	80003ede <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80002c66:	409c                	lw	a5,0(s1)
    80002c68:	cb89                	beqz	a5,80002c7a <bread+0xc8>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80002c6a:	8526                	mv	a0,s1
    80002c6c:	70a2                	ld	ra,40(sp)
    80002c6e:	7402                	ld	s0,32(sp)
    80002c70:	64e2                	ld	s1,24(sp)
    80002c72:	6942                	ld	s2,16(sp)
    80002c74:	69a2                	ld	s3,8(sp)
    80002c76:	6145                	addi	sp,sp,48
    80002c78:	8082                	ret
    virtio_disk_rw(b, 0);
    80002c7a:	4581                	li	a1,0
    80002c7c:	8526                	mv	a0,s1
    80002c7e:	2e3020ef          	jal	80005760 <virtio_disk_rw>
    b->valid = 1;
    80002c82:	4785                	li	a5,1
    80002c84:	c09c                	sw	a5,0(s1)
  return b;
    80002c86:	b7d5                	j	80002c6a <bread+0xb8>

0000000080002c88 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80002c88:	1101                	addi	sp,sp,-32
    80002c8a:	ec06                	sd	ra,24(sp)
    80002c8c:	e822                	sd	s0,16(sp)
    80002c8e:	e426                	sd	s1,8(sp)
    80002c90:	1000                	addi	s0,sp,32
    80002c92:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002c94:	0541                	addi	a0,a0,16
    80002c96:	2c6010ef          	jal	80003f5c <holdingsleep>
    80002c9a:	c911                	beqz	a0,80002cae <bwrite+0x26>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80002c9c:	4585                	li	a1,1
    80002c9e:	8526                	mv	a0,s1
    80002ca0:	2c1020ef          	jal	80005760 <virtio_disk_rw>
}
    80002ca4:	60e2                	ld	ra,24(sp)
    80002ca6:	6442                	ld	s0,16(sp)
    80002ca8:	64a2                	ld	s1,8(sp)
    80002caa:	6105                	addi	sp,sp,32
    80002cac:	8082                	ret
    panic("bwrite");
    80002cae:	00004517          	auipc	a0,0x4
    80002cb2:	70a50513          	addi	a0,a0,1802 # 800073b8 <etext+0x3b8>
    80002cb6:	b29fd0ef          	jal	800007de <panic>

0000000080002cba <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80002cba:	1101                	addi	sp,sp,-32
    80002cbc:	ec06                	sd	ra,24(sp)
    80002cbe:	e822                	sd	s0,16(sp)
    80002cc0:	e426                	sd	s1,8(sp)
    80002cc2:	e04a                	sd	s2,0(sp)
    80002cc4:	1000                	addi	s0,sp,32
    80002cc6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80002cc8:	01050913          	addi	s2,a0,16
    80002ccc:	854a                	mv	a0,s2
    80002cce:	28e010ef          	jal	80003f5c <holdingsleep>
    80002cd2:	c125                	beqz	a0,80002d32 <brelse+0x78>
    panic("brelse");

  releasesleep(&b->lock);
    80002cd4:	854a                	mv	a0,s2
    80002cd6:	24e010ef          	jal	80003f24 <releasesleep>

  acquire(&bcache.lock);
    80002cda:	00015517          	auipc	a0,0x15
    80002cde:	54650513          	addi	a0,a0,1350 # 80018220 <bcache>
    80002ce2:	eebfd0ef          	jal	80000bcc <acquire>
  b->refcnt--;
    80002ce6:	40bc                	lw	a5,64(s1)
    80002ce8:	37fd                	addiw	a5,a5,-1
    80002cea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80002cec:	e79d                	bnez	a5,80002d1a <brelse+0x60>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80002cee:	68b8                	ld	a4,80(s1)
    80002cf0:	64bc                	ld	a5,72(s1)
    80002cf2:	e73c                	sd	a5,72(a4)
    b->prev->next = b->next;
    80002cf4:	68b8                	ld	a4,80(s1)
    80002cf6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80002cf8:	0001d797          	auipc	a5,0x1d
    80002cfc:	52878793          	addi	a5,a5,1320 # 80020220 <bcache+0x8000>
    80002d00:	2b87b703          	ld	a4,696(a5)
    80002d04:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80002d06:	0001d717          	auipc	a4,0x1d
    80002d0a:	78270713          	addi	a4,a4,1922 # 80020488 <bcache+0x8268>
    80002d0e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80002d10:	2b87b703          	ld	a4,696(a5)
    80002d14:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80002d16:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80002d1a:	00015517          	auipc	a0,0x15
    80002d1e:	50650513          	addi	a0,a0,1286 # 80018220 <bcache>
    80002d22:	f3ffd0ef          	jal	80000c60 <release>
}
    80002d26:	60e2                	ld	ra,24(sp)
    80002d28:	6442                	ld	s0,16(sp)
    80002d2a:	64a2                	ld	s1,8(sp)
    80002d2c:	6902                	ld	s2,0(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret
    panic("brelse");
    80002d32:	00004517          	auipc	a0,0x4
    80002d36:	68e50513          	addi	a0,a0,1678 # 800073c0 <etext+0x3c0>
    80002d3a:	aa5fd0ef          	jal	800007de <panic>

0000000080002d3e <bpin>:

void
bpin(struct buf *b) {
    80002d3e:	1101                	addi	sp,sp,-32
    80002d40:	ec06                	sd	ra,24(sp)
    80002d42:	e822                	sd	s0,16(sp)
    80002d44:	e426                	sd	s1,8(sp)
    80002d46:	1000                	addi	s0,sp,32
    80002d48:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d4a:	00015517          	auipc	a0,0x15
    80002d4e:	4d650513          	addi	a0,a0,1238 # 80018220 <bcache>
    80002d52:	e7bfd0ef          	jal	80000bcc <acquire>
  b->refcnt++;
    80002d56:	40bc                	lw	a5,64(s1)
    80002d58:	2785                	addiw	a5,a5,1
    80002d5a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d5c:	00015517          	auipc	a0,0x15
    80002d60:	4c450513          	addi	a0,a0,1220 # 80018220 <bcache>
    80002d64:	efdfd0ef          	jal	80000c60 <release>
}
    80002d68:	60e2                	ld	ra,24(sp)
    80002d6a:	6442                	ld	s0,16(sp)
    80002d6c:	64a2                	ld	s1,8(sp)
    80002d6e:	6105                	addi	sp,sp,32
    80002d70:	8082                	ret

0000000080002d72 <bunpin>:

void
bunpin(struct buf *b) {
    80002d72:	1101                	addi	sp,sp,-32
    80002d74:	ec06                	sd	ra,24(sp)
    80002d76:	e822                	sd	s0,16(sp)
    80002d78:	e426                	sd	s1,8(sp)
    80002d7a:	1000                	addi	s0,sp,32
    80002d7c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80002d7e:	00015517          	auipc	a0,0x15
    80002d82:	4a250513          	addi	a0,a0,1186 # 80018220 <bcache>
    80002d86:	e47fd0ef          	jal	80000bcc <acquire>
  b->refcnt--;
    80002d8a:	40bc                	lw	a5,64(s1)
    80002d8c:	37fd                	addiw	a5,a5,-1
    80002d8e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80002d90:	00015517          	auipc	a0,0x15
    80002d94:	49050513          	addi	a0,a0,1168 # 80018220 <bcache>
    80002d98:	ec9fd0ef          	jal	80000c60 <release>
}
    80002d9c:	60e2                	ld	ra,24(sp)
    80002d9e:	6442                	ld	s0,16(sp)
    80002da0:	64a2                	ld	s1,8(sp)
    80002da2:	6105                	addi	sp,sp,32
    80002da4:	8082                	ret

0000000080002da6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80002da6:	1101                	addi	sp,sp,-32
    80002da8:	ec06                	sd	ra,24(sp)
    80002daa:	e822                	sd	s0,16(sp)
    80002dac:	e426                	sd	s1,8(sp)
    80002dae:	e04a                	sd	s2,0(sp)
    80002db0:	1000                	addi	s0,sp,32
    80002db2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80002db4:	00d5d79b          	srliw	a5,a1,0xd
    80002db8:	0001e597          	auipc	a1,0x1e
    80002dbc:	b445a583          	lw	a1,-1212(a1) # 800208fc <sb+0x1c>
    80002dc0:	9dbd                	addw	a1,a1,a5
    80002dc2:	df1ff0ef          	jal	80002bb2 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80002dc6:	0074f713          	andi	a4,s1,7
    80002dca:	4785                	li	a5,1
    80002dcc:	00e797bb          	sllw	a5,a5,a4
  bi = b % BPB;
    80002dd0:	14ce                	slli	s1,s1,0x33
  if((bp->data[bi/8] & m) == 0)
    80002dd2:	90d9                	srli	s1,s1,0x36
    80002dd4:	00950733          	add	a4,a0,s1
    80002dd8:	05874703          	lbu	a4,88(a4)
    80002ddc:	00e7f6b3          	and	a3,a5,a4
    80002de0:	c29d                	beqz	a3,80002e06 <bfree+0x60>
    80002de2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80002de4:	94aa                	add	s1,s1,a0
    80002de6:	fff7c793          	not	a5,a5
    80002dea:	8f7d                	and	a4,a4,a5
    80002dec:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80002df0:	7f7000ef          	jal	80003de6 <log_write>
  brelse(bp);
    80002df4:	854a                	mv	a0,s2
    80002df6:	ec5ff0ef          	jal	80002cba <brelse>
}
    80002dfa:	60e2                	ld	ra,24(sp)
    80002dfc:	6442                	ld	s0,16(sp)
    80002dfe:	64a2                	ld	s1,8(sp)
    80002e00:	6902                	ld	s2,0(sp)
    80002e02:	6105                	addi	sp,sp,32
    80002e04:	8082                	ret
    panic("freeing free block");
    80002e06:	00004517          	auipc	a0,0x4
    80002e0a:	5c250513          	addi	a0,a0,1474 # 800073c8 <etext+0x3c8>
    80002e0e:	9d1fd0ef          	jal	800007de <panic>

0000000080002e12 <balloc>:
{
    80002e12:	715d                	addi	sp,sp,-80
    80002e14:	e486                	sd	ra,72(sp)
    80002e16:	e0a2                	sd	s0,64(sp)
    80002e18:	fc26                	sd	s1,56(sp)
    80002e1a:	0880                	addi	s0,sp,80
  for(b = 0; b < sb.size; b += BPB){
    80002e1c:	0001e797          	auipc	a5,0x1e
    80002e20:	ac87a783          	lw	a5,-1336(a5) # 800208e4 <sb+0x4>
    80002e24:	0e078863          	beqz	a5,80002f14 <balloc+0x102>
    80002e28:	f84a                	sd	s2,48(sp)
    80002e2a:	f44e                	sd	s3,40(sp)
    80002e2c:	f052                	sd	s4,32(sp)
    80002e2e:	ec56                	sd	s5,24(sp)
    80002e30:	e85a                	sd	s6,16(sp)
    80002e32:	e45e                	sd	s7,8(sp)
    80002e34:	e062                	sd	s8,0(sp)
    80002e36:	8baa                	mv	s7,a0
    80002e38:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80002e3a:	0001eb17          	auipc	s6,0x1e
    80002e3e:	aa6b0b13          	addi	s6,s6,-1370 # 800208e0 <sb>
      m = 1 << (bi % 8);
    80002e42:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002e44:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80002e46:	6c09                	lui	s8,0x2
    80002e48:	a09d                	j	80002eae <balloc+0x9c>
        bp->data[bi/8] |= m;  // Mark block in use.
    80002e4a:	97ca                	add	a5,a5,s2
    80002e4c:	8e55                	or	a2,a2,a3
    80002e4e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80002e52:	854a                	mv	a0,s2
    80002e54:	793000ef          	jal	80003de6 <log_write>
        brelse(bp);
    80002e58:	854a                	mv	a0,s2
    80002e5a:	e61ff0ef          	jal	80002cba <brelse>
  bp = bread(dev, bno);
    80002e5e:	85a6                	mv	a1,s1
    80002e60:	855e                	mv	a0,s7
    80002e62:	d51ff0ef          	jal	80002bb2 <bread>
    80002e66:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80002e68:	40000613          	li	a2,1024
    80002e6c:	4581                	li	a1,0
    80002e6e:	05850513          	addi	a0,a0,88
    80002e72:	e2bfd0ef          	jal	80000c9c <memset>
  log_write(bp);
    80002e76:	854a                	mv	a0,s2
    80002e78:	76f000ef          	jal	80003de6 <log_write>
  brelse(bp);
    80002e7c:	854a                	mv	a0,s2
    80002e7e:	e3dff0ef          	jal	80002cba <brelse>
}
    80002e82:	7942                	ld	s2,48(sp)
    80002e84:	79a2                	ld	s3,40(sp)
    80002e86:	7a02                	ld	s4,32(sp)
    80002e88:	6ae2                	ld	s5,24(sp)
    80002e8a:	6b42                	ld	s6,16(sp)
    80002e8c:	6ba2                	ld	s7,8(sp)
    80002e8e:	6c02                	ld	s8,0(sp)
}
    80002e90:	8526                	mv	a0,s1
    80002e92:	60a6                	ld	ra,72(sp)
    80002e94:	6406                	ld	s0,64(sp)
    80002e96:	74e2                	ld	s1,56(sp)
    80002e98:	6161                	addi	sp,sp,80
    80002e9a:	8082                	ret
    brelse(bp);
    80002e9c:	854a                	mv	a0,s2
    80002e9e:	e1dff0ef          	jal	80002cba <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80002ea2:	015c0abb          	addw	s5,s8,s5
    80002ea6:	004b2783          	lw	a5,4(s6)
    80002eaa:	04fafe63          	bgeu	s5,a5,80002f06 <balloc+0xf4>
    bp = bread(dev, BBLOCK(b, sb));
    80002eae:	41fad79b          	sraiw	a5,s5,0x1f
    80002eb2:	0137d79b          	srliw	a5,a5,0x13
    80002eb6:	015787bb          	addw	a5,a5,s5
    80002eba:	40d7d79b          	sraiw	a5,a5,0xd
    80002ebe:	01cb2583          	lw	a1,28(s6)
    80002ec2:	9dbd                	addw	a1,a1,a5
    80002ec4:	855e                	mv	a0,s7
    80002ec6:	cedff0ef          	jal	80002bb2 <bread>
    80002eca:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002ecc:	004b2503          	lw	a0,4(s6)
    80002ed0:	84d6                	mv	s1,s5
    80002ed2:	4701                	li	a4,0
    80002ed4:	fca4f4e3          	bgeu	s1,a0,80002e9c <balloc+0x8a>
      m = 1 << (bi % 8);
    80002ed8:	00777693          	andi	a3,a4,7
    80002edc:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80002ee0:	41f7579b          	sraiw	a5,a4,0x1f
    80002ee4:	01d7d79b          	srliw	a5,a5,0x1d
    80002ee8:	9fb9                	addw	a5,a5,a4
    80002eea:	4037d79b          	sraiw	a5,a5,0x3
    80002eee:	00f90633          	add	a2,s2,a5
    80002ef2:	05864603          	lbu	a2,88(a2)
    80002ef6:	00c6f5b3          	and	a1,a3,a2
    80002efa:	d9a1                	beqz	a1,80002e4a <balloc+0x38>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80002efc:	2705                	addiw	a4,a4,1
    80002efe:	2485                	addiw	s1,s1,1
    80002f00:	fd471ae3          	bne	a4,s4,80002ed4 <balloc+0xc2>
    80002f04:	bf61                	j	80002e9c <balloc+0x8a>
    80002f06:	7942                	ld	s2,48(sp)
    80002f08:	79a2                	ld	s3,40(sp)
    80002f0a:	7a02                	ld	s4,32(sp)
    80002f0c:	6ae2                	ld	s5,24(sp)
    80002f0e:	6b42                	ld	s6,16(sp)
    80002f10:	6ba2                	ld	s7,8(sp)
    80002f12:	6c02                	ld	s8,0(sp)
  printf("balloc: out of blocks\n");
    80002f14:	00004517          	auipc	a0,0x4
    80002f18:	4cc50513          	addi	a0,a0,1228 # 800073e0 <etext+0x3e0>
    80002f1c:	ddefd0ef          	jal	800004fa <printf>
  return 0;
    80002f20:	4481                	li	s1,0
    80002f22:	b7bd                	j	80002e90 <balloc+0x7e>

0000000080002f24 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80002f24:	7179                	addi	sp,sp,-48
    80002f26:	f406                	sd	ra,40(sp)
    80002f28:	f022                	sd	s0,32(sp)
    80002f2a:	ec26                	sd	s1,24(sp)
    80002f2c:	e84a                	sd	s2,16(sp)
    80002f2e:	e44e                	sd	s3,8(sp)
    80002f30:	1800                	addi	s0,sp,48
    80002f32:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80002f34:	47ad                	li	a5,11
    80002f36:	02b7e363          	bltu	a5,a1,80002f5c <bmap+0x38>
    if((addr = ip->addrs[bn]) == 0){
    80002f3a:	02059793          	slli	a5,a1,0x20
    80002f3e:	01e7d593          	srli	a1,a5,0x1e
    80002f42:	00b504b3          	add	s1,a0,a1
    80002f46:	0504a903          	lw	s2,80(s1)
    80002f4a:	06091363          	bnez	s2,80002fb0 <bmap+0x8c>
      addr = balloc(ip->dev);
    80002f4e:	4108                	lw	a0,0(a0)
    80002f50:	ec3ff0ef          	jal	80002e12 <balloc>
    80002f54:	892a                	mv	s2,a0
      if(addr == 0)
    80002f56:	cd29                	beqz	a0,80002fb0 <bmap+0x8c>
        return 0;
      ip->addrs[bn] = addr;
    80002f58:	c8a8                	sw	a0,80(s1)
    80002f5a:	a899                	j	80002fb0 <bmap+0x8c>
    }
    return addr;
  }
  bn -= NDIRECT;
    80002f5c:	ff45849b          	addiw	s1,a1,-12

  if(bn < NINDIRECT){
    80002f60:	0ff00793          	li	a5,255
    80002f64:	0697e963          	bltu	a5,s1,80002fd6 <bmap+0xb2>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80002f68:	08052903          	lw	s2,128(a0)
    80002f6c:	00091b63          	bnez	s2,80002f82 <bmap+0x5e>
      addr = balloc(ip->dev);
    80002f70:	4108                	lw	a0,0(a0)
    80002f72:	ea1ff0ef          	jal	80002e12 <balloc>
    80002f76:	892a                	mv	s2,a0
      if(addr == 0)
    80002f78:	cd05                	beqz	a0,80002fb0 <bmap+0x8c>
    80002f7a:	e052                	sd	s4,0(sp)
        return 0;
      ip->addrs[NDIRECT] = addr;
    80002f7c:	08a9a023          	sw	a0,128(s3)
    80002f80:	a011                	j	80002f84 <bmap+0x60>
    80002f82:	e052                	sd	s4,0(sp)
    }
    bp = bread(ip->dev, addr);
    80002f84:	85ca                	mv	a1,s2
    80002f86:	0009a503          	lw	a0,0(s3)
    80002f8a:	c29ff0ef          	jal	80002bb2 <bread>
    80002f8e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80002f90:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80002f94:	02049713          	slli	a4,s1,0x20
    80002f98:	01e75593          	srli	a1,a4,0x1e
    80002f9c:	00b784b3          	add	s1,a5,a1
    80002fa0:	0004a903          	lw	s2,0(s1)
    80002fa4:	00090e63          	beqz	s2,80002fc0 <bmap+0x9c>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80002fa8:	8552                	mv	a0,s4
    80002faa:	d11ff0ef          	jal	80002cba <brelse>
    return addr;
    80002fae:	6a02                	ld	s4,0(sp)
  }

  panic("bmap: out of range");
}
    80002fb0:	854a                	mv	a0,s2
    80002fb2:	70a2                	ld	ra,40(sp)
    80002fb4:	7402                	ld	s0,32(sp)
    80002fb6:	64e2                	ld	s1,24(sp)
    80002fb8:	6942                	ld	s2,16(sp)
    80002fba:	69a2                	ld	s3,8(sp)
    80002fbc:	6145                	addi	sp,sp,48
    80002fbe:	8082                	ret
      addr = balloc(ip->dev);
    80002fc0:	0009a503          	lw	a0,0(s3)
    80002fc4:	e4fff0ef          	jal	80002e12 <balloc>
    80002fc8:	892a                	mv	s2,a0
      if(addr){
    80002fca:	dd79                	beqz	a0,80002fa8 <bmap+0x84>
        a[bn] = addr;
    80002fcc:	c088                	sw	a0,0(s1)
        log_write(bp);
    80002fce:	8552                	mv	a0,s4
    80002fd0:	617000ef          	jal	80003de6 <log_write>
    80002fd4:	bfd1                	j	80002fa8 <bmap+0x84>
    80002fd6:	e052                	sd	s4,0(sp)
  panic("bmap: out of range");
    80002fd8:	00004517          	auipc	a0,0x4
    80002fdc:	42050513          	addi	a0,a0,1056 # 800073f8 <etext+0x3f8>
    80002fe0:	ffefd0ef          	jal	800007de <panic>

0000000080002fe4 <iget>:
{
    80002fe4:	7179                	addi	sp,sp,-48
    80002fe6:	f406                	sd	ra,40(sp)
    80002fe8:	f022                	sd	s0,32(sp)
    80002fea:	ec26                	sd	s1,24(sp)
    80002fec:	e84a                	sd	s2,16(sp)
    80002fee:	e44e                	sd	s3,8(sp)
    80002ff0:	e052                	sd	s4,0(sp)
    80002ff2:	1800                	addi	s0,sp,48
    80002ff4:	89aa                	mv	s3,a0
    80002ff6:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80002ff8:	0001e517          	auipc	a0,0x1e
    80002ffc:	90850513          	addi	a0,a0,-1784 # 80020900 <itable>
    80003000:	bcdfd0ef          	jal	80000bcc <acquire>
  empty = 0;
    80003004:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003006:	0001e497          	auipc	s1,0x1e
    8000300a:	91248493          	addi	s1,s1,-1774 # 80020918 <itable+0x18>
    8000300e:	0001f697          	auipc	a3,0x1f
    80003012:	39a68693          	addi	a3,a3,922 # 800223a8 <log>
    80003016:	a039                	j	80003024 <iget+0x40>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003018:	02090963          	beqz	s2,8000304a <iget+0x66>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000301c:	08848493          	addi	s1,s1,136
    80003020:	02d48863          	beq	s1,a3,80003050 <iget+0x6c>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003024:	449c                	lw	a5,8(s1)
    80003026:	fef059e3          	blez	a5,80003018 <iget+0x34>
    8000302a:	4098                	lw	a4,0(s1)
    8000302c:	ff3716e3          	bne	a4,s3,80003018 <iget+0x34>
    80003030:	40d8                	lw	a4,4(s1)
    80003032:	ff4713e3          	bne	a4,s4,80003018 <iget+0x34>
      ip->ref++;
    80003036:	2785                	addiw	a5,a5,1
    80003038:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    8000303a:	0001e517          	auipc	a0,0x1e
    8000303e:	8c650513          	addi	a0,a0,-1850 # 80020900 <itable>
    80003042:	c1ffd0ef          	jal	80000c60 <release>
      return ip;
    80003046:	8926                	mv	s2,s1
    80003048:	a02d                	j	80003072 <iget+0x8e>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000304a:	fbe9                	bnez	a5,8000301c <iget+0x38>
      empty = ip;
    8000304c:	8926                	mv	s2,s1
    8000304e:	b7f9                	j	8000301c <iget+0x38>
  if(empty == 0)
    80003050:	02090a63          	beqz	s2,80003084 <iget+0xa0>
  ip->dev = dev;
    80003054:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003058:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000305c:	4785                	li	a5,1
    8000305e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003062:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003066:	0001e517          	auipc	a0,0x1e
    8000306a:	89a50513          	addi	a0,a0,-1894 # 80020900 <itable>
    8000306e:	bf3fd0ef          	jal	80000c60 <release>
}
    80003072:	854a                	mv	a0,s2
    80003074:	70a2                	ld	ra,40(sp)
    80003076:	7402                	ld	s0,32(sp)
    80003078:	64e2                	ld	s1,24(sp)
    8000307a:	6942                	ld	s2,16(sp)
    8000307c:	69a2                	ld	s3,8(sp)
    8000307e:	6a02                	ld	s4,0(sp)
    80003080:	6145                	addi	sp,sp,48
    80003082:	8082                	ret
    panic("iget: no inodes");
    80003084:	00004517          	auipc	a0,0x4
    80003088:	38c50513          	addi	a0,a0,908 # 80007410 <etext+0x410>
    8000308c:	f52fd0ef          	jal	800007de <panic>

0000000080003090 <iinit>:
{
    80003090:	7179                	addi	sp,sp,-48
    80003092:	f406                	sd	ra,40(sp)
    80003094:	f022                	sd	s0,32(sp)
    80003096:	ec26                	sd	s1,24(sp)
    80003098:	e84a                	sd	s2,16(sp)
    8000309a:	e44e                	sd	s3,8(sp)
    8000309c:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    8000309e:	00004597          	auipc	a1,0x4
    800030a2:	38258593          	addi	a1,a1,898 # 80007420 <etext+0x420>
    800030a6:	0001e517          	auipc	a0,0x1e
    800030aa:	85a50513          	addi	a0,a0,-1958 # 80020900 <itable>
    800030ae:	a9bfd0ef          	jal	80000b48 <initlock>
  for(i = 0; i < NINODE; i++) {
    800030b2:	0001e497          	auipc	s1,0x1e
    800030b6:	87648493          	addi	s1,s1,-1930 # 80020928 <itable+0x28>
    800030ba:	0001f997          	auipc	s3,0x1f
    800030be:	2fe98993          	addi	s3,s3,766 # 800223b8 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800030c2:	00004917          	auipc	s2,0x4
    800030c6:	36690913          	addi	s2,s2,870 # 80007428 <etext+0x428>
    800030ca:	85ca                	mv	a1,s2
    800030cc:	8526                	mv	a0,s1
    800030ce:	5db000ef          	jal	80003ea8 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800030d2:	08848493          	addi	s1,s1,136
    800030d6:	ff349ae3          	bne	s1,s3,800030ca <iinit+0x3a>
}
    800030da:	70a2                	ld	ra,40(sp)
    800030dc:	7402                	ld	s0,32(sp)
    800030de:	64e2                	ld	s1,24(sp)
    800030e0:	6942                	ld	s2,16(sp)
    800030e2:	69a2                	ld	s3,8(sp)
    800030e4:	6145                	addi	sp,sp,48
    800030e6:	8082                	ret

00000000800030e8 <ialloc>:
{
    800030e8:	7139                	addi	sp,sp,-64
    800030ea:	fc06                	sd	ra,56(sp)
    800030ec:	f822                	sd	s0,48(sp)
    800030ee:	0080                	addi	s0,sp,64
  for(inum = 1; inum < sb.ninodes; inum++){
    800030f0:	0001d717          	auipc	a4,0x1d
    800030f4:	7fc72703          	lw	a4,2044(a4) # 800208ec <sb+0xc>
    800030f8:	4785                	li	a5,1
    800030fa:	06e7f063          	bgeu	a5,a4,8000315a <ialloc+0x72>
    800030fe:	f426                	sd	s1,40(sp)
    80003100:	f04a                	sd	s2,32(sp)
    80003102:	ec4e                	sd	s3,24(sp)
    80003104:	e852                	sd	s4,16(sp)
    80003106:	e456                	sd	s5,8(sp)
    80003108:	e05a                	sd	s6,0(sp)
    8000310a:	8aaa                	mv	s5,a0
    8000310c:	8b2e                	mv	s6,a1
    8000310e:	893e                	mv	s2,a5
    bp = bread(dev, IBLOCK(inum, sb));
    80003110:	0001da17          	auipc	s4,0x1d
    80003114:	7d0a0a13          	addi	s4,s4,2000 # 800208e0 <sb>
    80003118:	00495593          	srli	a1,s2,0x4
    8000311c:	018a2783          	lw	a5,24(s4)
    80003120:	9dbd                	addw	a1,a1,a5
    80003122:	8556                	mv	a0,s5
    80003124:	a8fff0ef          	jal	80002bb2 <bread>
    80003128:	84aa                	mv	s1,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000312a:	05850993          	addi	s3,a0,88
    8000312e:	00f97793          	andi	a5,s2,15
    80003132:	079a                	slli	a5,a5,0x6
    80003134:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003136:	00099783          	lh	a5,0(s3)
    8000313a:	cb9d                	beqz	a5,80003170 <ialloc+0x88>
    brelse(bp);
    8000313c:	b7fff0ef          	jal	80002cba <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003140:	0905                	addi	s2,s2,1
    80003142:	00ca2703          	lw	a4,12(s4)
    80003146:	0009079b          	sext.w	a5,s2
    8000314a:	fce7e7e3          	bltu	a5,a4,80003118 <ialloc+0x30>
    8000314e:	74a2                	ld	s1,40(sp)
    80003150:	7902                	ld	s2,32(sp)
    80003152:	69e2                	ld	s3,24(sp)
    80003154:	6a42                	ld	s4,16(sp)
    80003156:	6aa2                	ld	s5,8(sp)
    80003158:	6b02                	ld	s6,0(sp)
  printf("ialloc: no inodes\n");
    8000315a:	00004517          	auipc	a0,0x4
    8000315e:	2d650513          	addi	a0,a0,726 # 80007430 <etext+0x430>
    80003162:	b98fd0ef          	jal	800004fa <printf>
  return 0;
    80003166:	4501                	li	a0,0
}
    80003168:	70e2                	ld	ra,56(sp)
    8000316a:	7442                	ld	s0,48(sp)
    8000316c:	6121                	addi	sp,sp,64
    8000316e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003170:	04000613          	li	a2,64
    80003174:	4581                	li	a1,0
    80003176:	854e                	mv	a0,s3
    80003178:	b25fd0ef          	jal	80000c9c <memset>
      dip->type = type;
    8000317c:	01699023          	sh	s6,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003180:	8526                	mv	a0,s1
    80003182:	465000ef          	jal	80003de6 <log_write>
      brelse(bp);
    80003186:	8526                	mv	a0,s1
    80003188:	b33ff0ef          	jal	80002cba <brelse>
      return iget(dev, inum);
    8000318c:	0009059b          	sext.w	a1,s2
    80003190:	8556                	mv	a0,s5
    80003192:	e53ff0ef          	jal	80002fe4 <iget>
    80003196:	74a2                	ld	s1,40(sp)
    80003198:	7902                	ld	s2,32(sp)
    8000319a:	69e2                	ld	s3,24(sp)
    8000319c:	6a42                	ld	s4,16(sp)
    8000319e:	6aa2                	ld	s5,8(sp)
    800031a0:	6b02                	ld	s6,0(sp)
    800031a2:	b7d9                	j	80003168 <ialloc+0x80>

00000000800031a4 <iupdate>:
{
    800031a4:	1101                	addi	sp,sp,-32
    800031a6:	ec06                	sd	ra,24(sp)
    800031a8:	e822                	sd	s0,16(sp)
    800031aa:	e426                	sd	s1,8(sp)
    800031ac:	e04a                	sd	s2,0(sp)
    800031ae:	1000                	addi	s0,sp,32
    800031b0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800031b2:	415c                	lw	a5,4(a0)
    800031b4:	0047d79b          	srliw	a5,a5,0x4
    800031b8:	0001d597          	auipc	a1,0x1d
    800031bc:	7405a583          	lw	a1,1856(a1) # 800208f8 <sb+0x18>
    800031c0:	9dbd                	addw	a1,a1,a5
    800031c2:	4108                	lw	a0,0(a0)
    800031c4:	9efff0ef          	jal	80002bb2 <bread>
    800031c8:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800031ca:	05850793          	addi	a5,a0,88
    800031ce:	40d8                	lw	a4,4(s1)
    800031d0:	8b3d                	andi	a4,a4,15
    800031d2:	071a                	slli	a4,a4,0x6
    800031d4:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800031d6:	04449703          	lh	a4,68(s1)
    800031da:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800031de:	04649703          	lh	a4,70(s1)
    800031e2:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800031e6:	04849703          	lh	a4,72(s1)
    800031ea:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800031ee:	04a49703          	lh	a4,74(s1)
    800031f2:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800031f6:	44f8                	lw	a4,76(s1)
    800031f8:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800031fa:	03400613          	li	a2,52
    800031fe:	05048593          	addi	a1,s1,80
    80003202:	00c78513          	addi	a0,a5,12
    80003206:	afbfd0ef          	jal	80000d00 <memmove>
  log_write(bp);
    8000320a:	854a                	mv	a0,s2
    8000320c:	3db000ef          	jal	80003de6 <log_write>
  brelse(bp);
    80003210:	854a                	mv	a0,s2
    80003212:	aa9ff0ef          	jal	80002cba <brelse>
}
    80003216:	60e2                	ld	ra,24(sp)
    80003218:	6442                	ld	s0,16(sp)
    8000321a:	64a2                	ld	s1,8(sp)
    8000321c:	6902                	ld	s2,0(sp)
    8000321e:	6105                	addi	sp,sp,32
    80003220:	8082                	ret

0000000080003222 <idup>:
{
    80003222:	1101                	addi	sp,sp,-32
    80003224:	ec06                	sd	ra,24(sp)
    80003226:	e822                	sd	s0,16(sp)
    80003228:	e426                	sd	s1,8(sp)
    8000322a:	1000                	addi	s0,sp,32
    8000322c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000322e:	0001d517          	auipc	a0,0x1d
    80003232:	6d250513          	addi	a0,a0,1746 # 80020900 <itable>
    80003236:	997fd0ef          	jal	80000bcc <acquire>
  ip->ref++;
    8000323a:	449c                	lw	a5,8(s1)
    8000323c:	2785                	addiw	a5,a5,1
    8000323e:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003240:	0001d517          	auipc	a0,0x1d
    80003244:	6c050513          	addi	a0,a0,1728 # 80020900 <itable>
    80003248:	a19fd0ef          	jal	80000c60 <release>
}
    8000324c:	8526                	mv	a0,s1
    8000324e:	60e2                	ld	ra,24(sp)
    80003250:	6442                	ld	s0,16(sp)
    80003252:	64a2                	ld	s1,8(sp)
    80003254:	6105                	addi	sp,sp,32
    80003256:	8082                	ret

0000000080003258 <ilock>:
{
    80003258:	1101                	addi	sp,sp,-32
    8000325a:	ec06                	sd	ra,24(sp)
    8000325c:	e822                	sd	s0,16(sp)
    8000325e:	e426                	sd	s1,8(sp)
    80003260:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003262:	cd19                	beqz	a0,80003280 <ilock+0x28>
    80003264:	84aa                	mv	s1,a0
    80003266:	451c                	lw	a5,8(a0)
    80003268:	00f05c63          	blez	a5,80003280 <ilock+0x28>
  acquiresleep(&ip->lock);
    8000326c:	0541                	addi	a0,a0,16
    8000326e:	471000ef          	jal	80003ede <acquiresleep>
  if(ip->valid == 0){
    80003272:	40bc                	lw	a5,64(s1)
    80003274:	cf89                	beqz	a5,8000328e <ilock+0x36>
}
    80003276:	60e2                	ld	ra,24(sp)
    80003278:	6442                	ld	s0,16(sp)
    8000327a:	64a2                	ld	s1,8(sp)
    8000327c:	6105                	addi	sp,sp,32
    8000327e:	8082                	ret
    80003280:	e04a                	sd	s2,0(sp)
    panic("ilock");
    80003282:	00004517          	auipc	a0,0x4
    80003286:	1c650513          	addi	a0,a0,454 # 80007448 <etext+0x448>
    8000328a:	d54fd0ef          	jal	800007de <panic>
    8000328e:	e04a                	sd	s2,0(sp)
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003290:	40dc                	lw	a5,4(s1)
    80003292:	0047d79b          	srliw	a5,a5,0x4
    80003296:	0001d597          	auipc	a1,0x1d
    8000329a:	6625a583          	lw	a1,1634(a1) # 800208f8 <sb+0x18>
    8000329e:	9dbd                	addw	a1,a1,a5
    800032a0:	4088                	lw	a0,0(s1)
    800032a2:	911ff0ef          	jal	80002bb2 <bread>
    800032a6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800032a8:	05850593          	addi	a1,a0,88
    800032ac:	40dc                	lw	a5,4(s1)
    800032ae:	8bbd                	andi	a5,a5,15
    800032b0:	079a                	slli	a5,a5,0x6
    800032b2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800032b4:	00059783          	lh	a5,0(a1)
    800032b8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800032bc:	00259783          	lh	a5,2(a1)
    800032c0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800032c4:	00459783          	lh	a5,4(a1)
    800032c8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800032cc:	00659783          	lh	a5,6(a1)
    800032d0:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800032d4:	459c                	lw	a5,8(a1)
    800032d6:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800032d8:	03400613          	li	a2,52
    800032dc:	05b1                	addi	a1,a1,12
    800032de:	05048513          	addi	a0,s1,80
    800032e2:	a1ffd0ef          	jal	80000d00 <memmove>
    brelse(bp);
    800032e6:	854a                	mv	a0,s2
    800032e8:	9d3ff0ef          	jal	80002cba <brelse>
    ip->valid = 1;
    800032ec:	4785                	li	a5,1
    800032ee:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800032f0:	04449783          	lh	a5,68(s1)
    800032f4:	c399                	beqz	a5,800032fa <ilock+0xa2>
    800032f6:	6902                	ld	s2,0(sp)
    800032f8:	bfbd                	j	80003276 <ilock+0x1e>
      panic("ilock: no type");
    800032fa:	00004517          	auipc	a0,0x4
    800032fe:	15650513          	addi	a0,a0,342 # 80007450 <etext+0x450>
    80003302:	cdcfd0ef          	jal	800007de <panic>

0000000080003306 <iunlock>:
{
    80003306:	1101                	addi	sp,sp,-32
    80003308:	ec06                	sd	ra,24(sp)
    8000330a:	e822                	sd	s0,16(sp)
    8000330c:	e426                	sd	s1,8(sp)
    8000330e:	e04a                	sd	s2,0(sp)
    80003310:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003312:	c505                	beqz	a0,8000333a <iunlock+0x34>
    80003314:	84aa                	mv	s1,a0
    80003316:	01050913          	addi	s2,a0,16
    8000331a:	854a                	mv	a0,s2
    8000331c:	441000ef          	jal	80003f5c <holdingsleep>
    80003320:	cd09                	beqz	a0,8000333a <iunlock+0x34>
    80003322:	449c                	lw	a5,8(s1)
    80003324:	00f05b63          	blez	a5,8000333a <iunlock+0x34>
  releasesleep(&ip->lock);
    80003328:	854a                	mv	a0,s2
    8000332a:	3fb000ef          	jal	80003f24 <releasesleep>
}
    8000332e:	60e2                	ld	ra,24(sp)
    80003330:	6442                	ld	s0,16(sp)
    80003332:	64a2                	ld	s1,8(sp)
    80003334:	6902                	ld	s2,0(sp)
    80003336:	6105                	addi	sp,sp,32
    80003338:	8082                	ret
    panic("iunlock");
    8000333a:	00004517          	auipc	a0,0x4
    8000333e:	12650513          	addi	a0,a0,294 # 80007460 <etext+0x460>
    80003342:	c9cfd0ef          	jal	800007de <panic>

0000000080003346 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003346:	7179                	addi	sp,sp,-48
    80003348:	f406                	sd	ra,40(sp)
    8000334a:	f022                	sd	s0,32(sp)
    8000334c:	ec26                	sd	s1,24(sp)
    8000334e:	e84a                	sd	s2,16(sp)
    80003350:	e44e                	sd	s3,8(sp)
    80003352:	1800                	addi	s0,sp,48
    80003354:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003356:	05050493          	addi	s1,a0,80
    8000335a:	08050913          	addi	s2,a0,128
    8000335e:	a021                	j	80003366 <itrunc+0x20>
    80003360:	0491                	addi	s1,s1,4
    80003362:	01248b63          	beq	s1,s2,80003378 <itrunc+0x32>
    if(ip->addrs[i]){
    80003366:	408c                	lw	a1,0(s1)
    80003368:	dde5                	beqz	a1,80003360 <itrunc+0x1a>
      bfree(ip->dev, ip->addrs[i]);
    8000336a:	0009a503          	lw	a0,0(s3)
    8000336e:	a39ff0ef          	jal	80002da6 <bfree>
      ip->addrs[i] = 0;
    80003372:	0004a023          	sw	zero,0(s1)
    80003376:	b7ed                	j	80003360 <itrunc+0x1a>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003378:	0809a583          	lw	a1,128(s3)
    8000337c:	ed89                	bnez	a1,80003396 <itrunc+0x50>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000337e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003382:	854e                	mv	a0,s3
    80003384:	e21ff0ef          	jal	800031a4 <iupdate>
}
    80003388:	70a2                	ld	ra,40(sp)
    8000338a:	7402                	ld	s0,32(sp)
    8000338c:	64e2                	ld	s1,24(sp)
    8000338e:	6942                	ld	s2,16(sp)
    80003390:	69a2                	ld	s3,8(sp)
    80003392:	6145                	addi	sp,sp,48
    80003394:	8082                	ret
    80003396:	e052                	sd	s4,0(sp)
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003398:	0009a503          	lw	a0,0(s3)
    8000339c:	817ff0ef          	jal	80002bb2 <bread>
    800033a0:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800033a2:	05850493          	addi	s1,a0,88
    800033a6:	45850913          	addi	s2,a0,1112
    800033aa:	a021                	j	800033b2 <itrunc+0x6c>
    800033ac:	0491                	addi	s1,s1,4
    800033ae:	01248963          	beq	s1,s2,800033c0 <itrunc+0x7a>
      if(a[j])
    800033b2:	408c                	lw	a1,0(s1)
    800033b4:	dde5                	beqz	a1,800033ac <itrunc+0x66>
        bfree(ip->dev, a[j]);
    800033b6:	0009a503          	lw	a0,0(s3)
    800033ba:	9edff0ef          	jal	80002da6 <bfree>
    800033be:	b7fd                	j	800033ac <itrunc+0x66>
    brelse(bp);
    800033c0:	8552                	mv	a0,s4
    800033c2:	8f9ff0ef          	jal	80002cba <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800033c6:	0809a583          	lw	a1,128(s3)
    800033ca:	0009a503          	lw	a0,0(s3)
    800033ce:	9d9ff0ef          	jal	80002da6 <bfree>
    ip->addrs[NDIRECT] = 0;
    800033d2:	0809a023          	sw	zero,128(s3)
    800033d6:	6a02                	ld	s4,0(sp)
    800033d8:	b75d                	j	8000337e <itrunc+0x38>

00000000800033da <iput>:
{
    800033da:	1101                	addi	sp,sp,-32
    800033dc:	ec06                	sd	ra,24(sp)
    800033de:	e822                	sd	s0,16(sp)
    800033e0:	e426                	sd	s1,8(sp)
    800033e2:	1000                	addi	s0,sp,32
    800033e4:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800033e6:	0001d517          	auipc	a0,0x1d
    800033ea:	51a50513          	addi	a0,a0,1306 # 80020900 <itable>
    800033ee:	fdefd0ef          	jal	80000bcc <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800033f2:	4498                	lw	a4,8(s1)
    800033f4:	4785                	li	a5,1
    800033f6:	02f70063          	beq	a4,a5,80003416 <iput+0x3c>
  ip->ref--;
    800033fa:	449c                	lw	a5,8(s1)
    800033fc:	37fd                	addiw	a5,a5,-1
    800033fe:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003400:	0001d517          	auipc	a0,0x1d
    80003404:	50050513          	addi	a0,a0,1280 # 80020900 <itable>
    80003408:	859fd0ef          	jal	80000c60 <release>
}
    8000340c:	60e2                	ld	ra,24(sp)
    8000340e:	6442                	ld	s0,16(sp)
    80003410:	64a2                	ld	s1,8(sp)
    80003412:	6105                	addi	sp,sp,32
    80003414:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003416:	40bc                	lw	a5,64(s1)
    80003418:	d3ed                	beqz	a5,800033fa <iput+0x20>
    8000341a:	04a49783          	lh	a5,74(s1)
    8000341e:	fff1                	bnez	a5,800033fa <iput+0x20>
    80003420:	e04a                	sd	s2,0(sp)
    acquiresleep(&ip->lock);
    80003422:	01048913          	addi	s2,s1,16
    80003426:	854a                	mv	a0,s2
    80003428:	2b7000ef          	jal	80003ede <acquiresleep>
    release(&itable.lock);
    8000342c:	0001d517          	auipc	a0,0x1d
    80003430:	4d450513          	addi	a0,a0,1236 # 80020900 <itable>
    80003434:	82dfd0ef          	jal	80000c60 <release>
    itrunc(ip);
    80003438:	8526                	mv	a0,s1
    8000343a:	f0dff0ef          	jal	80003346 <itrunc>
    ip->type = 0;
    8000343e:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003442:	8526                	mv	a0,s1
    80003444:	d61ff0ef          	jal	800031a4 <iupdate>
    ip->valid = 0;
    80003448:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000344c:	854a                	mv	a0,s2
    8000344e:	2d7000ef          	jal	80003f24 <releasesleep>
    acquire(&itable.lock);
    80003452:	0001d517          	auipc	a0,0x1d
    80003456:	4ae50513          	addi	a0,a0,1198 # 80020900 <itable>
    8000345a:	f72fd0ef          	jal	80000bcc <acquire>
    8000345e:	6902                	ld	s2,0(sp)
    80003460:	bf69                	j	800033fa <iput+0x20>

0000000080003462 <iunlockput>:
{
    80003462:	1101                	addi	sp,sp,-32
    80003464:	ec06                	sd	ra,24(sp)
    80003466:	e822                	sd	s0,16(sp)
    80003468:	e426                	sd	s1,8(sp)
    8000346a:	1000                	addi	s0,sp,32
    8000346c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000346e:	e99ff0ef          	jal	80003306 <iunlock>
  iput(ip);
    80003472:	8526                	mv	a0,s1
    80003474:	f67ff0ef          	jal	800033da <iput>
}
    80003478:	60e2                	ld	ra,24(sp)
    8000347a:	6442                	ld	s0,16(sp)
    8000347c:	64a2                	ld	s1,8(sp)
    8000347e:	6105                	addi	sp,sp,32
    80003480:	8082                	ret

0000000080003482 <ireclaim>:
  for (int inum = 1; inum < sb.ninodes; inum++) {
    80003482:	0001d717          	auipc	a4,0x1d
    80003486:	46a72703          	lw	a4,1130(a4) # 800208ec <sb+0xc>
    8000348a:	4785                	li	a5,1
    8000348c:	0ae7fe63          	bgeu	a5,a4,80003548 <ireclaim+0xc6>
{
    80003490:	7139                	addi	sp,sp,-64
    80003492:	fc06                	sd	ra,56(sp)
    80003494:	f822                	sd	s0,48(sp)
    80003496:	f426                	sd	s1,40(sp)
    80003498:	f04a                	sd	s2,32(sp)
    8000349a:	ec4e                	sd	s3,24(sp)
    8000349c:	e852                	sd	s4,16(sp)
    8000349e:	e456                	sd	s5,8(sp)
    800034a0:	e05a                	sd	s6,0(sp)
    800034a2:	0080                	addi	s0,sp,64
    800034a4:	8aaa                	mv	s5,a0
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034a6:	84be                	mv	s1,a5
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    800034a8:	0001da17          	auipc	s4,0x1d
    800034ac:	438a0a13          	addi	s4,s4,1080 # 800208e0 <sb>
      printf("ireclaim: orphaned inode %d\n", inum);
    800034b0:	00004b17          	auipc	s6,0x4
    800034b4:	fb8b0b13          	addi	s6,s6,-72 # 80007468 <etext+0x468>
    800034b8:	a099                	j	800034fe <ireclaim+0x7c>
    800034ba:	85ce                	mv	a1,s3
    800034bc:	855a                	mv	a0,s6
    800034be:	83cfd0ef          	jal	800004fa <printf>
      ip = iget(dev, inum);
    800034c2:	85ce                	mv	a1,s3
    800034c4:	8556                	mv	a0,s5
    800034c6:	b1fff0ef          	jal	80002fe4 <iget>
    800034ca:	89aa                	mv	s3,a0
    brelse(bp);
    800034cc:	854a                	mv	a0,s2
    800034ce:	fecff0ef          	jal	80002cba <brelse>
    if (ip) {
    800034d2:	00098f63          	beqz	s3,800034f0 <ireclaim+0x6e>
      begin_op();
    800034d6:	786000ef          	jal	80003c5c <begin_op>
      ilock(ip);
    800034da:	854e                	mv	a0,s3
    800034dc:	d7dff0ef          	jal	80003258 <ilock>
      iunlock(ip);
    800034e0:	854e                	mv	a0,s3
    800034e2:	e25ff0ef          	jal	80003306 <iunlock>
      iput(ip);
    800034e6:	854e                	mv	a0,s3
    800034e8:	ef3ff0ef          	jal	800033da <iput>
      end_op();
    800034ec:	7da000ef          	jal	80003cc6 <end_op>
  for (int inum = 1; inum < sb.ninodes; inum++) {
    800034f0:	0485                	addi	s1,s1,1
    800034f2:	00ca2703          	lw	a4,12(s4)
    800034f6:	0004879b          	sext.w	a5,s1
    800034fa:	02e7fd63          	bgeu	a5,a4,80003534 <ireclaim+0xb2>
    800034fe:	0004899b          	sext.w	s3,s1
    struct buf *bp = bread(dev, IBLOCK(inum, sb));
    80003502:	0044d593          	srli	a1,s1,0x4
    80003506:	018a2783          	lw	a5,24(s4)
    8000350a:	9dbd                	addw	a1,a1,a5
    8000350c:	8556                	mv	a0,s5
    8000350e:	ea4ff0ef          	jal	80002bb2 <bread>
    80003512:	892a                	mv	s2,a0
    struct dinode *dip = (struct dinode *)bp->data + inum % IPB;
    80003514:	05850793          	addi	a5,a0,88
    80003518:	00f9f713          	andi	a4,s3,15
    8000351c:	071a                	slli	a4,a4,0x6
    8000351e:	97ba                	add	a5,a5,a4
    if (dip->type != 0 && dip->nlink == 0) {  // is an orphaned inode
    80003520:	00079703          	lh	a4,0(a5)
    80003524:	c701                	beqz	a4,8000352c <ireclaim+0xaa>
    80003526:	00679783          	lh	a5,6(a5)
    8000352a:	dbc1                	beqz	a5,800034ba <ireclaim+0x38>
    brelse(bp);
    8000352c:	854a                	mv	a0,s2
    8000352e:	f8cff0ef          	jal	80002cba <brelse>
    if (ip) {
    80003532:	bf7d                	j	800034f0 <ireclaim+0x6e>
}
    80003534:	70e2                	ld	ra,56(sp)
    80003536:	7442                	ld	s0,48(sp)
    80003538:	74a2                	ld	s1,40(sp)
    8000353a:	7902                	ld	s2,32(sp)
    8000353c:	69e2                	ld	s3,24(sp)
    8000353e:	6a42                	ld	s4,16(sp)
    80003540:	6aa2                	ld	s5,8(sp)
    80003542:	6b02                	ld	s6,0(sp)
    80003544:	6121                	addi	sp,sp,64
    80003546:	8082                	ret
    80003548:	8082                	ret

000000008000354a <fsinit>:
fsinit(int dev) {
    8000354a:	7179                	addi	sp,sp,-48
    8000354c:	f406                	sd	ra,40(sp)
    8000354e:	f022                	sd	s0,32(sp)
    80003550:	ec26                	sd	s1,24(sp)
    80003552:	e84a                	sd	s2,16(sp)
    80003554:	e44e                	sd	s3,8(sp)
    80003556:	1800                	addi	s0,sp,48
    80003558:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000355a:	4585                	li	a1,1
    8000355c:	e56ff0ef          	jal	80002bb2 <bread>
    80003560:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003562:	0001d997          	auipc	s3,0x1d
    80003566:	37e98993          	addi	s3,s3,894 # 800208e0 <sb>
    8000356a:	02000613          	li	a2,32
    8000356e:	05850593          	addi	a1,a0,88
    80003572:	854e                	mv	a0,s3
    80003574:	f8cfd0ef          	jal	80000d00 <memmove>
  brelse(bp);
    80003578:	8526                	mv	a0,s1
    8000357a:	f40ff0ef          	jal	80002cba <brelse>
  if(sb.magic != FSMAGIC)
    8000357e:	0009a703          	lw	a4,0(s3)
    80003582:	102037b7          	lui	a5,0x10203
    80003586:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000358a:	02f71363          	bne	a4,a5,800035b0 <fsinit+0x66>
  initlog(dev, &sb);
    8000358e:	0001d597          	auipc	a1,0x1d
    80003592:	35258593          	addi	a1,a1,850 # 800208e0 <sb>
    80003596:	854a                	mv	a0,s2
    80003598:	646000ef          	jal	80003bde <initlog>
  ireclaim(dev);
    8000359c:	854a                	mv	a0,s2
    8000359e:	ee5ff0ef          	jal	80003482 <ireclaim>
}
    800035a2:	70a2                	ld	ra,40(sp)
    800035a4:	7402                	ld	s0,32(sp)
    800035a6:	64e2                	ld	s1,24(sp)
    800035a8:	6942                	ld	s2,16(sp)
    800035aa:	69a2                	ld	s3,8(sp)
    800035ac:	6145                	addi	sp,sp,48
    800035ae:	8082                	ret
    panic("invalid file system");
    800035b0:	00004517          	auipc	a0,0x4
    800035b4:	ed850513          	addi	a0,a0,-296 # 80007488 <etext+0x488>
    800035b8:	a26fd0ef          	jal	800007de <panic>

00000000800035bc <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800035bc:	1141                	addi	sp,sp,-16
    800035be:	e406                	sd	ra,8(sp)
    800035c0:	e022                	sd	s0,0(sp)
    800035c2:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800035c4:	411c                	lw	a5,0(a0)
    800035c6:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800035c8:	415c                	lw	a5,4(a0)
    800035ca:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800035cc:	04451783          	lh	a5,68(a0)
    800035d0:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800035d4:	04a51783          	lh	a5,74(a0)
    800035d8:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800035dc:	04c56783          	lwu	a5,76(a0)
    800035e0:	e99c                	sd	a5,16(a1)
}
    800035e2:	60a2                	ld	ra,8(sp)
    800035e4:	6402                	ld	s0,0(sp)
    800035e6:	0141                	addi	sp,sp,16
    800035e8:	8082                	ret

00000000800035ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800035ea:	457c                	lw	a5,76(a0)
    800035ec:	0ed7e663          	bltu	a5,a3,800036d8 <readi+0xee>
{
    800035f0:	7159                	addi	sp,sp,-112
    800035f2:	f486                	sd	ra,104(sp)
    800035f4:	f0a2                	sd	s0,96(sp)
    800035f6:	eca6                	sd	s1,88(sp)
    800035f8:	e0d2                	sd	s4,64(sp)
    800035fa:	fc56                	sd	s5,56(sp)
    800035fc:	f85a                	sd	s6,48(sp)
    800035fe:	f45e                	sd	s7,40(sp)
    80003600:	1880                	addi	s0,sp,112
    80003602:	8b2a                	mv	s6,a0
    80003604:	8bae                	mv	s7,a1
    80003606:	8a32                	mv	s4,a2
    80003608:	84b6                	mv	s1,a3
    8000360a:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    8000360c:	9f35                	addw	a4,a4,a3
    return 0;
    8000360e:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003610:	0ad76b63          	bltu	a4,a3,800036c6 <readi+0xdc>
    80003614:	e4ce                	sd	s3,72(sp)
  if(off + n > ip->size)
    80003616:	00e7f463          	bgeu	a5,a4,8000361e <readi+0x34>
    n = ip->size - off;
    8000361a:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000361e:	080a8b63          	beqz	s5,800036b4 <readi+0xca>
    80003622:	e8ca                	sd	s2,80(sp)
    80003624:	f062                	sd	s8,32(sp)
    80003626:	ec66                	sd	s9,24(sp)
    80003628:	e86a                	sd	s10,16(sp)
    8000362a:	e46e                	sd	s11,8(sp)
    8000362c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000362e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003632:	5c7d                	li	s8,-1
    80003634:	a80d                	j	80003666 <readi+0x7c>
    80003636:	020d1d93          	slli	s11,s10,0x20
    8000363a:	020ddd93          	srli	s11,s11,0x20
    8000363e:	05890613          	addi	a2,s2,88
    80003642:	86ee                	mv	a3,s11
    80003644:	963e                	add	a2,a2,a5
    80003646:	85d2                	mv	a1,s4
    80003648:	855e                	mv	a0,s7
    8000364a:	bd5fe0ef          	jal	8000221e <either_copyout>
    8000364e:	05850363          	beq	a0,s8,80003694 <readi+0xaa>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003652:	854a                	mv	a0,s2
    80003654:	e66ff0ef          	jal	80002cba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003658:	013d09bb          	addw	s3,s10,s3
    8000365c:	009d04bb          	addw	s1,s10,s1
    80003660:	9a6e                	add	s4,s4,s11
    80003662:	0559f363          	bgeu	s3,s5,800036a8 <readi+0xbe>
    uint addr = bmap(ip, off/BSIZE);
    80003666:	00a4d59b          	srliw	a1,s1,0xa
    8000366a:	855a                	mv	a0,s6
    8000366c:	8b9ff0ef          	jal	80002f24 <bmap>
    80003670:	85aa                	mv	a1,a0
    if(addr == 0)
    80003672:	c139                	beqz	a0,800036b8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003674:	000b2503          	lw	a0,0(s6)
    80003678:	d3aff0ef          	jal	80002bb2 <bread>
    8000367c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000367e:	3ff4f793          	andi	a5,s1,1023
    80003682:	40fc873b          	subw	a4,s9,a5
    80003686:	413a86bb          	subw	a3,s5,s3
    8000368a:	8d3a                	mv	s10,a4
    8000368c:	fae6f5e3          	bgeu	a3,a4,80003636 <readi+0x4c>
    80003690:	8d36                	mv	s10,a3
    80003692:	b755                	j	80003636 <readi+0x4c>
      brelse(bp);
    80003694:	854a                	mv	a0,s2
    80003696:	e24ff0ef          	jal	80002cba <brelse>
      tot = -1;
    8000369a:	59fd                	li	s3,-1
      break;
    8000369c:	6946                	ld	s2,80(sp)
    8000369e:	7c02                	ld	s8,32(sp)
    800036a0:	6ce2                	ld	s9,24(sp)
    800036a2:	6d42                	ld	s10,16(sp)
    800036a4:	6da2                	ld	s11,8(sp)
    800036a6:	a831                	j	800036c2 <readi+0xd8>
    800036a8:	6946                	ld	s2,80(sp)
    800036aa:	7c02                	ld	s8,32(sp)
    800036ac:	6ce2                	ld	s9,24(sp)
    800036ae:	6d42                	ld	s10,16(sp)
    800036b0:	6da2                	ld	s11,8(sp)
    800036b2:	a801                	j	800036c2 <readi+0xd8>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800036b4:	89d6                	mv	s3,s5
    800036b6:	a031                	j	800036c2 <readi+0xd8>
    800036b8:	6946                	ld	s2,80(sp)
    800036ba:	7c02                	ld	s8,32(sp)
    800036bc:	6ce2                	ld	s9,24(sp)
    800036be:	6d42                	ld	s10,16(sp)
    800036c0:	6da2                	ld	s11,8(sp)
  }
  return tot;
    800036c2:	854e                	mv	a0,s3
    800036c4:	69a6                	ld	s3,72(sp)
}
    800036c6:	70a6                	ld	ra,104(sp)
    800036c8:	7406                	ld	s0,96(sp)
    800036ca:	64e6                	ld	s1,88(sp)
    800036cc:	6a06                	ld	s4,64(sp)
    800036ce:	7ae2                	ld	s5,56(sp)
    800036d0:	7b42                	ld	s6,48(sp)
    800036d2:	7ba2                	ld	s7,40(sp)
    800036d4:	6165                	addi	sp,sp,112
    800036d6:	8082                	ret
    return 0;
    800036d8:	4501                	li	a0,0
}
    800036da:	8082                	ret

00000000800036dc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800036dc:	457c                	lw	a5,76(a0)
    800036de:	0ed7eb63          	bltu	a5,a3,800037d4 <writei+0xf8>
{
    800036e2:	7159                	addi	sp,sp,-112
    800036e4:	f486                	sd	ra,104(sp)
    800036e6:	f0a2                	sd	s0,96(sp)
    800036e8:	e8ca                	sd	s2,80(sp)
    800036ea:	e0d2                	sd	s4,64(sp)
    800036ec:	fc56                	sd	s5,56(sp)
    800036ee:	f85a                	sd	s6,48(sp)
    800036f0:	f45e                	sd	s7,40(sp)
    800036f2:	1880                	addi	s0,sp,112
    800036f4:	8aaa                	mv	s5,a0
    800036f6:	8bae                	mv	s7,a1
    800036f8:	8a32                	mv	s4,a2
    800036fa:	8936                	mv	s2,a3
    800036fc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800036fe:	00e687bb          	addw	a5,a3,a4
    80003702:	0cd7eb63          	bltu	a5,a3,800037d8 <writei+0xfc>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003706:	00043737          	lui	a4,0x43
    8000370a:	0cf76963          	bltu	a4,a5,800037dc <writei+0x100>
    8000370e:	e4ce                	sd	s3,72(sp)
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003710:	0a0b0a63          	beqz	s6,800037c4 <writei+0xe8>
    80003714:	eca6                	sd	s1,88(sp)
    80003716:	f062                	sd	s8,32(sp)
    80003718:	ec66                	sd	s9,24(sp)
    8000371a:	e86a                	sd	s10,16(sp)
    8000371c:	e46e                	sd	s11,8(sp)
    8000371e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003720:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003724:	5c7d                	li	s8,-1
    80003726:	a825                	j	8000375e <writei+0x82>
    80003728:	020d1d93          	slli	s11,s10,0x20
    8000372c:	020ddd93          	srli	s11,s11,0x20
    80003730:	05848513          	addi	a0,s1,88
    80003734:	86ee                	mv	a3,s11
    80003736:	8652                	mv	a2,s4
    80003738:	85de                	mv	a1,s7
    8000373a:	953e                	add	a0,a0,a5
    8000373c:	b2dfe0ef          	jal	80002268 <either_copyin>
    80003740:	05850663          	beq	a0,s8,8000378c <writei+0xb0>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003744:	8526                	mv	a0,s1
    80003746:	6a0000ef          	jal	80003de6 <log_write>
    brelse(bp);
    8000374a:	8526                	mv	a0,s1
    8000374c:	d6eff0ef          	jal	80002cba <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003750:	013d09bb          	addw	s3,s10,s3
    80003754:	012d093b          	addw	s2,s10,s2
    80003758:	9a6e                	add	s4,s4,s11
    8000375a:	0369fc63          	bgeu	s3,s6,80003792 <writei+0xb6>
    uint addr = bmap(ip, off/BSIZE);
    8000375e:	00a9559b          	srliw	a1,s2,0xa
    80003762:	8556                	mv	a0,s5
    80003764:	fc0ff0ef          	jal	80002f24 <bmap>
    80003768:	85aa                	mv	a1,a0
    if(addr == 0)
    8000376a:	c505                	beqz	a0,80003792 <writei+0xb6>
    bp = bread(ip->dev, addr);
    8000376c:	000aa503          	lw	a0,0(s5)
    80003770:	c42ff0ef          	jal	80002bb2 <bread>
    80003774:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003776:	3ff97793          	andi	a5,s2,1023
    8000377a:	40fc873b          	subw	a4,s9,a5
    8000377e:	413b06bb          	subw	a3,s6,s3
    80003782:	8d3a                	mv	s10,a4
    80003784:	fae6f2e3          	bgeu	a3,a4,80003728 <writei+0x4c>
    80003788:	8d36                	mv	s10,a3
    8000378a:	bf79                	j	80003728 <writei+0x4c>
      brelse(bp);
    8000378c:	8526                	mv	a0,s1
    8000378e:	d2cff0ef          	jal	80002cba <brelse>
  }

  if(off > ip->size)
    80003792:	04caa783          	lw	a5,76(s5)
    80003796:	0327f963          	bgeu	a5,s2,800037c8 <writei+0xec>
    ip->size = off;
    8000379a:	052aa623          	sw	s2,76(s5)
    8000379e:	64e6                	ld	s1,88(sp)
    800037a0:	7c02                	ld	s8,32(sp)
    800037a2:	6ce2                	ld	s9,24(sp)
    800037a4:	6d42                	ld	s10,16(sp)
    800037a6:	6da2                	ld	s11,8(sp)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800037a8:	8556                	mv	a0,s5
    800037aa:	9fbff0ef          	jal	800031a4 <iupdate>

  return tot;
    800037ae:	854e                	mv	a0,s3
    800037b0:	69a6                	ld	s3,72(sp)
}
    800037b2:	70a6                	ld	ra,104(sp)
    800037b4:	7406                	ld	s0,96(sp)
    800037b6:	6946                	ld	s2,80(sp)
    800037b8:	6a06                	ld	s4,64(sp)
    800037ba:	7ae2                	ld	s5,56(sp)
    800037bc:	7b42                	ld	s6,48(sp)
    800037be:	7ba2                	ld	s7,40(sp)
    800037c0:	6165                	addi	sp,sp,112
    800037c2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800037c4:	89da                	mv	s3,s6
    800037c6:	b7cd                	j	800037a8 <writei+0xcc>
    800037c8:	64e6                	ld	s1,88(sp)
    800037ca:	7c02                	ld	s8,32(sp)
    800037cc:	6ce2                	ld	s9,24(sp)
    800037ce:	6d42                	ld	s10,16(sp)
    800037d0:	6da2                	ld	s11,8(sp)
    800037d2:	bfd9                	j	800037a8 <writei+0xcc>
    return -1;
    800037d4:	557d                	li	a0,-1
}
    800037d6:	8082                	ret
    return -1;
    800037d8:	557d                	li	a0,-1
    800037da:	bfe1                	j	800037b2 <writei+0xd6>
    return -1;
    800037dc:	557d                	li	a0,-1
    800037de:	bfd1                	j	800037b2 <writei+0xd6>

00000000800037e0 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800037e0:	1141                	addi	sp,sp,-16
    800037e2:	e406                	sd	ra,8(sp)
    800037e4:	e022                	sd	s0,0(sp)
    800037e6:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    800037e8:	4639                	li	a2,14
    800037ea:	d8afd0ef          	jal	80000d74 <strncmp>
}
    800037ee:	60a2                	ld	ra,8(sp)
    800037f0:	6402                	ld	s0,0(sp)
    800037f2:	0141                	addi	sp,sp,16
    800037f4:	8082                	ret

00000000800037f6 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800037f6:	711d                	addi	sp,sp,-96
    800037f8:	ec86                	sd	ra,88(sp)
    800037fa:	e8a2                	sd	s0,80(sp)
    800037fc:	e4a6                	sd	s1,72(sp)
    800037fe:	e0ca                	sd	s2,64(sp)
    80003800:	fc4e                	sd	s3,56(sp)
    80003802:	f852                	sd	s4,48(sp)
    80003804:	f456                	sd	s5,40(sp)
    80003806:	f05a                	sd	s6,32(sp)
    80003808:	ec5e                	sd	s7,24(sp)
    8000380a:	1080                	addi	s0,sp,96
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    8000380c:	04451703          	lh	a4,68(a0)
    80003810:	4785                	li	a5,1
    80003812:	00f71f63          	bne	a4,a5,80003830 <dirlookup+0x3a>
    80003816:	892a                	mv	s2,a0
    80003818:	8aae                	mv	s5,a1
    8000381a:	8bb2                	mv	s7,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    8000381c:	457c                	lw	a5,76(a0)
    8000381e:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003820:	fa040a13          	addi	s4,s0,-96
    80003824:	49c1                	li	s3,16
      panic("dirlookup read");
    if(de.inum == 0)
      continue;
    if(namecmp(name, de.name) == 0){
    80003826:	fa240b13          	addi	s6,s0,-94
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    8000382a:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000382c:	e39d                	bnez	a5,80003852 <dirlookup+0x5c>
    8000382e:	a8b9                	j	8000388c <dirlookup+0x96>
    panic("dirlookup not DIR");
    80003830:	00004517          	auipc	a0,0x4
    80003834:	c7050513          	addi	a0,a0,-912 # 800074a0 <etext+0x4a0>
    80003838:	fa7fc0ef          	jal	800007de <panic>
      panic("dirlookup read");
    8000383c:	00004517          	auipc	a0,0x4
    80003840:	c7c50513          	addi	a0,a0,-900 # 800074b8 <etext+0x4b8>
    80003844:	f9bfc0ef          	jal	800007de <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003848:	24c1                	addiw	s1,s1,16
    8000384a:	04c92783          	lw	a5,76(s2)
    8000384e:	02f4fe63          	bgeu	s1,a5,8000388a <dirlookup+0x94>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003852:	874e                	mv	a4,s3
    80003854:	86a6                	mv	a3,s1
    80003856:	8652                	mv	a2,s4
    80003858:	4581                	li	a1,0
    8000385a:	854a                	mv	a0,s2
    8000385c:	d8fff0ef          	jal	800035ea <readi>
    80003860:	fd351ee3          	bne	a0,s3,8000383c <dirlookup+0x46>
    if(de.inum == 0)
    80003864:	fa045783          	lhu	a5,-96(s0)
    80003868:	d3e5                	beqz	a5,80003848 <dirlookup+0x52>
    if(namecmp(name, de.name) == 0){
    8000386a:	85da                	mv	a1,s6
    8000386c:	8556                	mv	a0,s5
    8000386e:	f73ff0ef          	jal	800037e0 <namecmp>
    80003872:	f979                	bnez	a0,80003848 <dirlookup+0x52>
      if(poff)
    80003874:	000b8463          	beqz	s7,8000387c <dirlookup+0x86>
        *poff = off;
    80003878:	009ba023          	sw	s1,0(s7)
      return iget(dp->dev, inum);
    8000387c:	fa045583          	lhu	a1,-96(s0)
    80003880:	00092503          	lw	a0,0(s2)
    80003884:	f60ff0ef          	jal	80002fe4 <iget>
    80003888:	a011                	j	8000388c <dirlookup+0x96>
  return 0;
    8000388a:	4501                	li	a0,0
}
    8000388c:	60e6                	ld	ra,88(sp)
    8000388e:	6446                	ld	s0,80(sp)
    80003890:	64a6                	ld	s1,72(sp)
    80003892:	6906                	ld	s2,64(sp)
    80003894:	79e2                	ld	s3,56(sp)
    80003896:	7a42                	ld	s4,48(sp)
    80003898:	7aa2                	ld	s5,40(sp)
    8000389a:	7b02                	ld	s6,32(sp)
    8000389c:	6be2                	ld	s7,24(sp)
    8000389e:	6125                	addi	sp,sp,96
    800038a0:	8082                	ret

00000000800038a2 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800038a2:	711d                	addi	sp,sp,-96
    800038a4:	ec86                	sd	ra,88(sp)
    800038a6:	e8a2                	sd	s0,80(sp)
    800038a8:	e4a6                	sd	s1,72(sp)
    800038aa:	e0ca                	sd	s2,64(sp)
    800038ac:	fc4e                	sd	s3,56(sp)
    800038ae:	f852                	sd	s4,48(sp)
    800038b0:	f456                	sd	s5,40(sp)
    800038b2:	f05a                	sd	s6,32(sp)
    800038b4:	ec5e                	sd	s7,24(sp)
    800038b6:	e862                	sd	s8,16(sp)
    800038b8:	e466                	sd	s9,8(sp)
    800038ba:	e06a                	sd	s10,0(sp)
    800038bc:	1080                	addi	s0,sp,96
    800038be:	84aa                	mv	s1,a0
    800038c0:	8b2e                	mv	s6,a1
    800038c2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800038c4:	00054703          	lbu	a4,0(a0)
    800038c8:	02f00793          	li	a5,47
    800038cc:	00f70f63          	beq	a4,a5,800038ea <namex+0x48>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800038d0:	feffd0ef          	jal	800018be <myproc>
    800038d4:	15053503          	ld	a0,336(a0)
    800038d8:	94bff0ef          	jal	80003222 <idup>
    800038dc:	8a2a                	mv	s4,a0
  while(*path == '/')
    800038de:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800038e2:	4c35                	li	s8,13
    memmove(name, s, DIRSIZ);
    800038e4:	4cb9                	li	s9,14

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800038e6:	4b85                	li	s7,1
    800038e8:	a879                	j	80003986 <namex+0xe4>
    ip = iget(ROOTDEV, ROOTINO);
    800038ea:	4585                	li	a1,1
    800038ec:	852e                	mv	a0,a1
    800038ee:	ef6ff0ef          	jal	80002fe4 <iget>
    800038f2:	8a2a                	mv	s4,a0
    800038f4:	b7ed                	j	800038de <namex+0x3c>
      iunlockput(ip);
    800038f6:	8552                	mv	a0,s4
    800038f8:	b6bff0ef          	jal	80003462 <iunlockput>
      return 0;
    800038fc:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800038fe:	8552                	mv	a0,s4
    80003900:	60e6                	ld	ra,88(sp)
    80003902:	6446                	ld	s0,80(sp)
    80003904:	64a6                	ld	s1,72(sp)
    80003906:	6906                	ld	s2,64(sp)
    80003908:	79e2                	ld	s3,56(sp)
    8000390a:	7a42                	ld	s4,48(sp)
    8000390c:	7aa2                	ld	s5,40(sp)
    8000390e:	7b02                	ld	s6,32(sp)
    80003910:	6be2                	ld	s7,24(sp)
    80003912:	6c42                	ld	s8,16(sp)
    80003914:	6ca2                	ld	s9,8(sp)
    80003916:	6d02                	ld	s10,0(sp)
    80003918:	6125                	addi	sp,sp,96
    8000391a:	8082                	ret
      iunlock(ip);
    8000391c:	8552                	mv	a0,s4
    8000391e:	9e9ff0ef          	jal	80003306 <iunlock>
      return ip;
    80003922:	bff1                	j	800038fe <namex+0x5c>
      iunlockput(ip);
    80003924:	8552                	mv	a0,s4
    80003926:	b3dff0ef          	jal	80003462 <iunlockput>
      return 0;
    8000392a:	8a4e                	mv	s4,s3
    8000392c:	bfc9                	j	800038fe <namex+0x5c>
  len = path - s;
    8000392e:	40998633          	sub	a2,s3,s1
    80003932:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003936:	09ac5063          	bge	s8,s10,800039b6 <namex+0x114>
    memmove(name, s, DIRSIZ);
    8000393a:	8666                	mv	a2,s9
    8000393c:	85a6                	mv	a1,s1
    8000393e:	8556                	mv	a0,s5
    80003940:	bc0fd0ef          	jal	80000d00 <memmove>
    80003944:	84ce                	mv	s1,s3
  while(*path == '/')
    80003946:	0004c783          	lbu	a5,0(s1)
    8000394a:	01279763          	bne	a5,s2,80003958 <namex+0xb6>
    path++;
    8000394e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003950:	0004c783          	lbu	a5,0(s1)
    80003954:	ff278de3          	beq	a5,s2,8000394e <namex+0xac>
    ilock(ip);
    80003958:	8552                	mv	a0,s4
    8000395a:	8ffff0ef          	jal	80003258 <ilock>
    if(ip->type != T_DIR){
    8000395e:	044a1783          	lh	a5,68(s4)
    80003962:	f9779ae3          	bne	a5,s7,800038f6 <namex+0x54>
    if(nameiparent && *path == '\0'){
    80003966:	000b0563          	beqz	s6,80003970 <namex+0xce>
    8000396a:	0004c783          	lbu	a5,0(s1)
    8000396e:	d7dd                	beqz	a5,8000391c <namex+0x7a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003970:	4601                	li	a2,0
    80003972:	85d6                	mv	a1,s5
    80003974:	8552                	mv	a0,s4
    80003976:	e81ff0ef          	jal	800037f6 <dirlookup>
    8000397a:	89aa                	mv	s3,a0
    8000397c:	d545                	beqz	a0,80003924 <namex+0x82>
    iunlockput(ip);
    8000397e:	8552                	mv	a0,s4
    80003980:	ae3ff0ef          	jal	80003462 <iunlockput>
    ip = next;
    80003984:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003986:	0004c783          	lbu	a5,0(s1)
    8000398a:	01279763          	bne	a5,s2,80003998 <namex+0xf6>
    path++;
    8000398e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003990:	0004c783          	lbu	a5,0(s1)
    80003994:	ff278de3          	beq	a5,s2,8000398e <namex+0xec>
  if(*path == 0)
    80003998:	cb8d                	beqz	a5,800039ca <namex+0x128>
  while(*path != '/' && *path != 0)
    8000399a:	0004c783          	lbu	a5,0(s1)
    8000399e:	89a6                	mv	s3,s1
  len = path - s;
    800039a0:	4d01                	li	s10,0
    800039a2:	4601                	li	a2,0
  while(*path != '/' && *path != 0)
    800039a4:	01278963          	beq	a5,s2,800039b6 <namex+0x114>
    800039a8:	d3d9                	beqz	a5,8000392e <namex+0x8c>
    path++;
    800039aa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800039ac:	0009c783          	lbu	a5,0(s3)
    800039b0:	ff279ce3          	bne	a5,s2,800039a8 <namex+0x106>
    800039b4:	bfad                	j	8000392e <namex+0x8c>
    memmove(name, s, len);
    800039b6:	2601                	sext.w	a2,a2
    800039b8:	85a6                	mv	a1,s1
    800039ba:	8556                	mv	a0,s5
    800039bc:	b44fd0ef          	jal	80000d00 <memmove>
    name[len] = 0;
    800039c0:	9d56                	add	s10,s10,s5
    800039c2:	000d0023          	sb	zero,0(s10) # fffffffffffff000 <end+0xffffffff7ffdba18>
    800039c6:	84ce                	mv	s1,s3
    800039c8:	bfbd                	j	80003946 <namex+0xa4>
  if(nameiparent){
    800039ca:	f20b0ae3          	beqz	s6,800038fe <namex+0x5c>
    iput(ip);
    800039ce:	8552                	mv	a0,s4
    800039d0:	a0bff0ef          	jal	800033da <iput>
    return 0;
    800039d4:	4a01                	li	s4,0
    800039d6:	b725                	j	800038fe <namex+0x5c>

00000000800039d8 <dirlink>:
{
    800039d8:	715d                	addi	sp,sp,-80
    800039da:	e486                	sd	ra,72(sp)
    800039dc:	e0a2                	sd	s0,64(sp)
    800039de:	f84a                	sd	s2,48(sp)
    800039e0:	ec56                	sd	s5,24(sp)
    800039e2:	e85a                	sd	s6,16(sp)
    800039e4:	0880                	addi	s0,sp,80
    800039e6:	892a                	mv	s2,a0
    800039e8:	8aae                	mv	s5,a1
    800039ea:	8b32                	mv	s6,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800039ec:	4601                	li	a2,0
    800039ee:	e09ff0ef          	jal	800037f6 <dirlookup>
    800039f2:	ed1d                	bnez	a0,80003a30 <dirlink+0x58>
    800039f4:	fc26                	sd	s1,56(sp)
  for(off = 0; off < dp->size; off += sizeof(de)){
    800039f6:	04c92483          	lw	s1,76(s2)
    800039fa:	c4b9                	beqz	s1,80003a48 <dirlink+0x70>
    800039fc:	f44e                	sd	s3,40(sp)
    800039fe:	f052                	sd	s4,32(sp)
    80003a00:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a02:	fb040a13          	addi	s4,s0,-80
    80003a06:	49c1                	li	s3,16
    80003a08:	874e                	mv	a4,s3
    80003a0a:	86a6                	mv	a3,s1
    80003a0c:	8652                	mv	a2,s4
    80003a0e:	4581                	li	a1,0
    80003a10:	854a                	mv	a0,s2
    80003a12:	bd9ff0ef          	jal	800035ea <readi>
    80003a16:	03351163          	bne	a0,s3,80003a38 <dirlink+0x60>
    if(de.inum == 0)
    80003a1a:	fb045783          	lhu	a5,-80(s0)
    80003a1e:	c39d                	beqz	a5,80003a44 <dirlink+0x6c>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003a20:	24c1                	addiw	s1,s1,16
    80003a22:	04c92783          	lw	a5,76(s2)
    80003a26:	fef4e1e3          	bltu	s1,a5,80003a08 <dirlink+0x30>
    80003a2a:	79a2                	ld	s3,40(sp)
    80003a2c:	7a02                	ld	s4,32(sp)
    80003a2e:	a829                	j	80003a48 <dirlink+0x70>
    iput(ip);
    80003a30:	9abff0ef          	jal	800033da <iput>
    return -1;
    80003a34:	557d                	li	a0,-1
    80003a36:	a83d                	j	80003a74 <dirlink+0x9c>
      panic("dirlink read");
    80003a38:	00004517          	auipc	a0,0x4
    80003a3c:	a9050513          	addi	a0,a0,-1392 # 800074c8 <etext+0x4c8>
    80003a40:	d9ffc0ef          	jal	800007de <panic>
    80003a44:	79a2                	ld	s3,40(sp)
    80003a46:	7a02                	ld	s4,32(sp)
  strncpy(de.name, name, DIRSIZ);
    80003a48:	4639                	li	a2,14
    80003a4a:	85d6                	mv	a1,s5
    80003a4c:	fb240513          	addi	a0,s0,-78
    80003a50:	b5efd0ef          	jal	80000dae <strncpy>
  de.inum = inum;
    80003a54:	fb641823          	sh	s6,-80(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003a58:	4741                	li	a4,16
    80003a5a:	86a6                	mv	a3,s1
    80003a5c:	fb040613          	addi	a2,s0,-80
    80003a60:	4581                	li	a1,0
    80003a62:	854a                	mv	a0,s2
    80003a64:	c79ff0ef          	jal	800036dc <writei>
    80003a68:	1541                	addi	a0,a0,-16
    80003a6a:	00a03533          	snez	a0,a0
    80003a6e:	40a0053b          	negw	a0,a0
    80003a72:	74e2                	ld	s1,56(sp)
}
    80003a74:	60a6                	ld	ra,72(sp)
    80003a76:	6406                	ld	s0,64(sp)
    80003a78:	7942                	ld	s2,48(sp)
    80003a7a:	6ae2                	ld	s5,24(sp)
    80003a7c:	6b42                	ld	s6,16(sp)
    80003a7e:	6161                	addi	sp,sp,80
    80003a80:	8082                	ret

0000000080003a82 <namei>:

struct inode*
namei(char *path)
{
    80003a82:	1101                	addi	sp,sp,-32
    80003a84:	ec06                	sd	ra,24(sp)
    80003a86:	e822                	sd	s0,16(sp)
    80003a88:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003a8a:	fe040613          	addi	a2,s0,-32
    80003a8e:	4581                	li	a1,0
    80003a90:	e13ff0ef          	jal	800038a2 <namex>
}
    80003a94:	60e2                	ld	ra,24(sp)
    80003a96:	6442                	ld	s0,16(sp)
    80003a98:	6105                	addi	sp,sp,32
    80003a9a:	8082                	ret

0000000080003a9c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003a9c:	1141                	addi	sp,sp,-16
    80003a9e:	e406                	sd	ra,8(sp)
    80003aa0:	e022                	sd	s0,0(sp)
    80003aa2:	0800                	addi	s0,sp,16
    80003aa4:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003aa6:	4585                	li	a1,1
    80003aa8:	dfbff0ef          	jal	800038a2 <namex>
}
    80003aac:	60a2                	ld	ra,8(sp)
    80003aae:	6402                	ld	s0,0(sp)
    80003ab0:	0141                	addi	sp,sp,16
    80003ab2:	8082                	ret

0000000080003ab4 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003ab4:	1101                	addi	sp,sp,-32
    80003ab6:	ec06                	sd	ra,24(sp)
    80003ab8:	e822                	sd	s0,16(sp)
    80003aba:	e426                	sd	s1,8(sp)
    80003abc:	e04a                	sd	s2,0(sp)
    80003abe:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003ac0:	0001f917          	auipc	s2,0x1f
    80003ac4:	8e890913          	addi	s2,s2,-1816 # 800223a8 <log>
    80003ac8:	01892583          	lw	a1,24(s2)
    80003acc:	02492503          	lw	a0,36(s2)
    80003ad0:	8e2ff0ef          	jal	80002bb2 <bread>
    80003ad4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003ad6:	02892603          	lw	a2,40(s2)
    80003ada:	cd30                	sw	a2,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003adc:	00c05f63          	blez	a2,80003afa <write_head+0x46>
    80003ae0:	0001f717          	auipc	a4,0x1f
    80003ae4:	8f470713          	addi	a4,a4,-1804 # 800223d4 <log+0x2c>
    80003ae8:	87aa                	mv	a5,a0
    80003aea:	060a                	slli	a2,a2,0x2
    80003aec:	962a                	add	a2,a2,a0
    hb->block[i] = log.lh.block[i];
    80003aee:	4314                	lw	a3,0(a4)
    80003af0:	cff4                	sw	a3,92(a5)
  for (i = 0; i < log.lh.n; i++) {
    80003af2:	0711                	addi	a4,a4,4
    80003af4:	0791                	addi	a5,a5,4
    80003af6:	fec79ce3          	bne	a5,a2,80003aee <write_head+0x3a>
  }
  bwrite(buf);
    80003afa:	8526                	mv	a0,s1
    80003afc:	98cff0ef          	jal	80002c88 <bwrite>
  brelse(buf);
    80003b00:	8526                	mv	a0,s1
    80003b02:	9b8ff0ef          	jal	80002cba <brelse>
}
    80003b06:	60e2                	ld	ra,24(sp)
    80003b08:	6442                	ld	s0,16(sp)
    80003b0a:	64a2                	ld	s1,8(sp)
    80003b0c:	6902                	ld	s2,0(sp)
    80003b0e:	6105                	addi	sp,sp,32
    80003b10:	8082                	ret

0000000080003b12 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b12:	0001f797          	auipc	a5,0x1f
    80003b16:	8be7a783          	lw	a5,-1858(a5) # 800223d0 <log+0x28>
    80003b1a:	0cf05163          	blez	a5,80003bdc <install_trans+0xca>
{
    80003b1e:	715d                	addi	sp,sp,-80
    80003b20:	e486                	sd	ra,72(sp)
    80003b22:	e0a2                	sd	s0,64(sp)
    80003b24:	fc26                	sd	s1,56(sp)
    80003b26:	f84a                	sd	s2,48(sp)
    80003b28:	f44e                	sd	s3,40(sp)
    80003b2a:	f052                	sd	s4,32(sp)
    80003b2c:	ec56                	sd	s5,24(sp)
    80003b2e:	e85a                	sd	s6,16(sp)
    80003b30:	e45e                	sd	s7,8(sp)
    80003b32:	e062                	sd	s8,0(sp)
    80003b34:	0880                	addi	s0,sp,80
    80003b36:	8b2a                	mv	s6,a0
    80003b38:	0001fa97          	auipc	s5,0x1f
    80003b3c:	89ca8a93          	addi	s5,s5,-1892 # 800223d4 <log+0x2c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b40:	4981                	li	s3,0
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b42:	00004c17          	auipc	s8,0x4
    80003b46:	996c0c13          	addi	s8,s8,-1642 # 800074d8 <etext+0x4d8>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b4a:	0001fa17          	auipc	s4,0x1f
    80003b4e:	85ea0a13          	addi	s4,s4,-1954 # 800223a8 <log>
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003b52:	40000b93          	li	s7,1024
    80003b56:	a025                	j	80003b7e <install_trans+0x6c>
      printf("recovering tail %d dst %d\n", tail, log.lh.block[tail]);
    80003b58:	000aa603          	lw	a2,0(s5)
    80003b5c:	85ce                	mv	a1,s3
    80003b5e:	8562                	mv	a0,s8
    80003b60:	99bfc0ef          	jal	800004fa <printf>
    80003b64:	a839                	j	80003b82 <install_trans+0x70>
    brelse(lbuf);
    80003b66:	854a                	mv	a0,s2
    80003b68:	952ff0ef          	jal	80002cba <brelse>
    brelse(dbuf);
    80003b6c:	8526                	mv	a0,s1
    80003b6e:	94cff0ef          	jal	80002cba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003b72:	2985                	addiw	s3,s3,1
    80003b74:	0a91                	addi	s5,s5,4
    80003b76:	028a2783          	lw	a5,40(s4)
    80003b7a:	04f9d563          	bge	s3,a5,80003bc4 <install_trans+0xb2>
    if(recovering) {
    80003b7e:	fc0b1de3          	bnez	s6,80003b58 <install_trans+0x46>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003b82:	018a2583          	lw	a1,24(s4)
    80003b86:	013585bb          	addw	a1,a1,s3
    80003b8a:	2585                	addiw	a1,a1,1
    80003b8c:	024a2503          	lw	a0,36(s4)
    80003b90:	822ff0ef          	jal	80002bb2 <bread>
    80003b94:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003b96:	000aa583          	lw	a1,0(s5)
    80003b9a:	024a2503          	lw	a0,36(s4)
    80003b9e:	814ff0ef          	jal	80002bb2 <bread>
    80003ba2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ba4:	865e                	mv	a2,s7
    80003ba6:	05890593          	addi	a1,s2,88
    80003baa:	05850513          	addi	a0,a0,88
    80003bae:	952fd0ef          	jal	80000d00 <memmove>
    bwrite(dbuf);  // write dst to disk
    80003bb2:	8526                	mv	a0,s1
    80003bb4:	8d4ff0ef          	jal	80002c88 <bwrite>
    if(recovering == 0)
    80003bb8:	fa0b17e3          	bnez	s6,80003b66 <install_trans+0x54>
      bunpin(dbuf);
    80003bbc:	8526                	mv	a0,s1
    80003bbe:	9b4ff0ef          	jal	80002d72 <bunpin>
    80003bc2:	b755                	j	80003b66 <install_trans+0x54>
}
    80003bc4:	60a6                	ld	ra,72(sp)
    80003bc6:	6406                	ld	s0,64(sp)
    80003bc8:	74e2                	ld	s1,56(sp)
    80003bca:	7942                	ld	s2,48(sp)
    80003bcc:	79a2                	ld	s3,40(sp)
    80003bce:	7a02                	ld	s4,32(sp)
    80003bd0:	6ae2                	ld	s5,24(sp)
    80003bd2:	6b42                	ld	s6,16(sp)
    80003bd4:	6ba2                	ld	s7,8(sp)
    80003bd6:	6c02                	ld	s8,0(sp)
    80003bd8:	6161                	addi	sp,sp,80
    80003bda:	8082                	ret
    80003bdc:	8082                	ret

0000000080003bde <initlog>:
{
    80003bde:	7179                	addi	sp,sp,-48
    80003be0:	f406                	sd	ra,40(sp)
    80003be2:	f022                	sd	s0,32(sp)
    80003be4:	ec26                	sd	s1,24(sp)
    80003be6:	e84a                	sd	s2,16(sp)
    80003be8:	e44e                	sd	s3,8(sp)
    80003bea:	1800                	addi	s0,sp,48
    80003bec:	892a                	mv	s2,a0
    80003bee:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80003bf0:	0001e497          	auipc	s1,0x1e
    80003bf4:	7b848493          	addi	s1,s1,1976 # 800223a8 <log>
    80003bf8:	00004597          	auipc	a1,0x4
    80003bfc:	90058593          	addi	a1,a1,-1792 # 800074f8 <etext+0x4f8>
    80003c00:	8526                	mv	a0,s1
    80003c02:	f47fc0ef          	jal	80000b48 <initlock>
  log.start = sb->logstart;
    80003c06:	0149a583          	lw	a1,20(s3)
    80003c0a:	cc8c                	sw	a1,24(s1)
  log.dev = dev;
    80003c0c:	0324a223          	sw	s2,36(s1)
  struct buf *buf = bread(log.dev, log.start);
    80003c10:	854a                	mv	a0,s2
    80003c12:	fa1fe0ef          	jal	80002bb2 <bread>
  log.lh.n = lh->n;
    80003c16:	4d30                	lw	a2,88(a0)
    80003c18:	d490                	sw	a2,40(s1)
  for (i = 0; i < log.lh.n; i++) {
    80003c1a:	00c05f63          	blez	a2,80003c38 <initlog+0x5a>
    80003c1e:	87aa                	mv	a5,a0
    80003c20:	0001e717          	auipc	a4,0x1e
    80003c24:	7b470713          	addi	a4,a4,1972 # 800223d4 <log+0x2c>
    80003c28:	060a                	slli	a2,a2,0x2
    80003c2a:	962a                	add	a2,a2,a0
    log.lh.block[i] = lh->block[i];
    80003c2c:	4ff4                	lw	a3,92(a5)
    80003c2e:	c314                	sw	a3,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003c30:	0791                	addi	a5,a5,4
    80003c32:	0711                	addi	a4,a4,4
    80003c34:	fec79ce3          	bne	a5,a2,80003c2c <initlog+0x4e>
  brelse(buf);
    80003c38:	882ff0ef          	jal	80002cba <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80003c3c:	4505                	li	a0,1
    80003c3e:	ed5ff0ef          	jal	80003b12 <install_trans>
  log.lh.n = 0;
    80003c42:	0001e797          	auipc	a5,0x1e
    80003c46:	7807a723          	sw	zero,1934(a5) # 800223d0 <log+0x28>
  write_head(); // clear the log
    80003c4a:	e6bff0ef          	jal	80003ab4 <write_head>
}
    80003c4e:	70a2                	ld	ra,40(sp)
    80003c50:	7402                	ld	s0,32(sp)
    80003c52:	64e2                	ld	s1,24(sp)
    80003c54:	6942                	ld	s2,16(sp)
    80003c56:	69a2                	ld	s3,8(sp)
    80003c58:	6145                	addi	sp,sp,48
    80003c5a:	8082                	ret

0000000080003c5c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80003c5c:	1101                	addi	sp,sp,-32
    80003c5e:	ec06                	sd	ra,24(sp)
    80003c60:	e822                	sd	s0,16(sp)
    80003c62:	e426                	sd	s1,8(sp)
    80003c64:	e04a                	sd	s2,0(sp)
    80003c66:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80003c68:	0001e517          	auipc	a0,0x1e
    80003c6c:	74050513          	addi	a0,a0,1856 # 800223a8 <log>
    80003c70:	f5dfc0ef          	jal	80000bcc <acquire>
  while(1){
    if(log.committing){
    80003c74:	0001e497          	auipc	s1,0x1e
    80003c78:	73448493          	addi	s1,s1,1844 # 800223a8 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c7c:	4979                	li	s2,30
    80003c7e:	a029                	j	80003c88 <begin_op+0x2c>
      sleep(&log, &log.lock);
    80003c80:	85a6                	mv	a1,s1
    80003c82:	8526                	mv	a0,s1
    80003c84:	a44fe0ef          	jal	80001ec8 <sleep>
    if(log.committing){
    80003c88:	509c                	lw	a5,32(s1)
    80003c8a:	fbfd                	bnez	a5,80003c80 <begin_op+0x24>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGBLOCKS){
    80003c8c:	4cd8                	lw	a4,28(s1)
    80003c8e:	2705                	addiw	a4,a4,1
    80003c90:	0027179b          	slliw	a5,a4,0x2
    80003c94:	9fb9                	addw	a5,a5,a4
    80003c96:	0017979b          	slliw	a5,a5,0x1
    80003c9a:	5494                	lw	a3,40(s1)
    80003c9c:	9fb5                	addw	a5,a5,a3
    80003c9e:	00f95763          	bge	s2,a5,80003cac <begin_op+0x50>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80003ca2:	85a6                	mv	a1,s1
    80003ca4:	8526                	mv	a0,s1
    80003ca6:	a22fe0ef          	jal	80001ec8 <sleep>
    80003caa:	bff9                	j	80003c88 <begin_op+0x2c>
    } else {
      log.outstanding += 1;
    80003cac:	0001e517          	auipc	a0,0x1e
    80003cb0:	6fc50513          	addi	a0,a0,1788 # 800223a8 <log>
    80003cb4:	cd58                	sw	a4,28(a0)
      release(&log.lock);
    80003cb6:	fabfc0ef          	jal	80000c60 <release>
      break;
    }
  }
}
    80003cba:	60e2                	ld	ra,24(sp)
    80003cbc:	6442                	ld	s0,16(sp)
    80003cbe:	64a2                	ld	s1,8(sp)
    80003cc0:	6902                	ld	s2,0(sp)
    80003cc2:	6105                	addi	sp,sp,32
    80003cc4:	8082                	ret

0000000080003cc6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80003cc6:	7139                	addi	sp,sp,-64
    80003cc8:	fc06                	sd	ra,56(sp)
    80003cca:	f822                	sd	s0,48(sp)
    80003ccc:	f426                	sd	s1,40(sp)
    80003cce:	f04a                	sd	s2,32(sp)
    80003cd0:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80003cd2:	0001e497          	auipc	s1,0x1e
    80003cd6:	6d648493          	addi	s1,s1,1750 # 800223a8 <log>
    80003cda:	8526                	mv	a0,s1
    80003cdc:	ef1fc0ef          	jal	80000bcc <acquire>
  log.outstanding -= 1;
    80003ce0:	4cdc                	lw	a5,28(s1)
    80003ce2:	37fd                	addiw	a5,a5,-1
    80003ce4:	893e                	mv	s2,a5
    80003ce6:	ccdc                	sw	a5,28(s1)
  if(log.committing)
    80003ce8:	509c                	lw	a5,32(s1)
    80003cea:	ef9d                	bnez	a5,80003d28 <end_op+0x62>
    panic("log.committing");
  if(log.outstanding == 0){
    80003cec:	04091863          	bnez	s2,80003d3c <end_op+0x76>
    do_commit = 1;
    log.committing = 1;
    80003cf0:	0001e497          	auipc	s1,0x1e
    80003cf4:	6b848493          	addi	s1,s1,1720 # 800223a8 <log>
    80003cf8:	4785                	li	a5,1
    80003cfa:	d09c                	sw	a5,32(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80003cfc:	8526                	mv	a0,s1
    80003cfe:	f63fc0ef          	jal	80000c60 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80003d02:	549c                	lw	a5,40(s1)
    80003d04:	04f04c63          	bgtz	a5,80003d5c <end_op+0x96>
    acquire(&log.lock);
    80003d08:	0001e497          	auipc	s1,0x1e
    80003d0c:	6a048493          	addi	s1,s1,1696 # 800223a8 <log>
    80003d10:	8526                	mv	a0,s1
    80003d12:	ebbfc0ef          	jal	80000bcc <acquire>
    log.committing = 0;
    80003d16:	0204a023          	sw	zero,32(s1)
    wakeup(&log);
    80003d1a:	8526                	mv	a0,s1
    80003d1c:	9f8fe0ef          	jal	80001f14 <wakeup>
    release(&log.lock);
    80003d20:	8526                	mv	a0,s1
    80003d22:	f3ffc0ef          	jal	80000c60 <release>
}
    80003d26:	a02d                	j	80003d50 <end_op+0x8a>
    80003d28:	ec4e                	sd	s3,24(sp)
    80003d2a:	e852                	sd	s4,16(sp)
    80003d2c:	e456                	sd	s5,8(sp)
    80003d2e:	e05a                	sd	s6,0(sp)
    panic("log.committing");
    80003d30:	00003517          	auipc	a0,0x3
    80003d34:	7d050513          	addi	a0,a0,2000 # 80007500 <etext+0x500>
    80003d38:	aa7fc0ef          	jal	800007de <panic>
    wakeup(&log);
    80003d3c:	0001e497          	auipc	s1,0x1e
    80003d40:	66c48493          	addi	s1,s1,1644 # 800223a8 <log>
    80003d44:	8526                	mv	a0,s1
    80003d46:	9cefe0ef          	jal	80001f14 <wakeup>
  release(&log.lock);
    80003d4a:	8526                	mv	a0,s1
    80003d4c:	f15fc0ef          	jal	80000c60 <release>
}
    80003d50:	70e2                	ld	ra,56(sp)
    80003d52:	7442                	ld	s0,48(sp)
    80003d54:	74a2                	ld	s1,40(sp)
    80003d56:	7902                	ld	s2,32(sp)
    80003d58:	6121                	addi	sp,sp,64
    80003d5a:	8082                	ret
    80003d5c:	ec4e                	sd	s3,24(sp)
    80003d5e:	e852                	sd	s4,16(sp)
    80003d60:	e456                	sd	s5,8(sp)
    80003d62:	e05a                	sd	s6,0(sp)
  for (tail = 0; tail < log.lh.n; tail++) {
    80003d64:	0001ea97          	auipc	s5,0x1e
    80003d68:	670a8a93          	addi	s5,s5,1648 # 800223d4 <log+0x2c>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003d6c:	0001ea17          	auipc	s4,0x1e
    80003d70:	63ca0a13          	addi	s4,s4,1596 # 800223a8 <log>
    memmove(to->data, from->data, BSIZE);
    80003d74:	40000b13          	li	s6,1024
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80003d78:	018a2583          	lw	a1,24(s4)
    80003d7c:	012585bb          	addw	a1,a1,s2
    80003d80:	2585                	addiw	a1,a1,1
    80003d82:	024a2503          	lw	a0,36(s4)
    80003d86:	e2dfe0ef          	jal	80002bb2 <bread>
    80003d8a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80003d8c:	000aa583          	lw	a1,0(s5)
    80003d90:	024a2503          	lw	a0,36(s4)
    80003d94:	e1ffe0ef          	jal	80002bb2 <bread>
    80003d98:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80003d9a:	865a                	mv	a2,s6
    80003d9c:	05850593          	addi	a1,a0,88
    80003da0:	05848513          	addi	a0,s1,88
    80003da4:	f5dfc0ef          	jal	80000d00 <memmove>
    bwrite(to);  // write the log
    80003da8:	8526                	mv	a0,s1
    80003daa:	edffe0ef          	jal	80002c88 <bwrite>
    brelse(from);
    80003dae:	854e                	mv	a0,s3
    80003db0:	f0bfe0ef          	jal	80002cba <brelse>
    brelse(to);
    80003db4:	8526                	mv	a0,s1
    80003db6:	f05fe0ef          	jal	80002cba <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003dba:	2905                	addiw	s2,s2,1
    80003dbc:	0a91                	addi	s5,s5,4
    80003dbe:	028a2783          	lw	a5,40(s4)
    80003dc2:	faf94be3          	blt	s2,a5,80003d78 <end_op+0xb2>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80003dc6:	cefff0ef          	jal	80003ab4 <write_head>
    install_trans(0); // Now install writes to home locations
    80003dca:	4501                	li	a0,0
    80003dcc:	d47ff0ef          	jal	80003b12 <install_trans>
    log.lh.n = 0;
    80003dd0:	0001e797          	auipc	a5,0x1e
    80003dd4:	6007a023          	sw	zero,1536(a5) # 800223d0 <log+0x28>
    write_head();    // Erase the transaction from the log
    80003dd8:	cddff0ef          	jal	80003ab4 <write_head>
    80003ddc:	69e2                	ld	s3,24(sp)
    80003dde:	6a42                	ld	s4,16(sp)
    80003de0:	6aa2                	ld	s5,8(sp)
    80003de2:	6b02                	ld	s6,0(sp)
    80003de4:	b715                	j	80003d08 <end_op+0x42>

0000000080003de6 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80003de6:	1101                	addi	sp,sp,-32
    80003de8:	ec06                	sd	ra,24(sp)
    80003dea:	e822                	sd	s0,16(sp)
    80003dec:	e426                	sd	s1,8(sp)
    80003dee:	e04a                	sd	s2,0(sp)
    80003df0:	1000                	addi	s0,sp,32
    80003df2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80003df4:	0001e917          	auipc	s2,0x1e
    80003df8:	5b490913          	addi	s2,s2,1460 # 800223a8 <log>
    80003dfc:	854a                	mv	a0,s2
    80003dfe:	dcffc0ef          	jal	80000bcc <acquire>
  if (log.lh.n >= LOGBLOCKS)
    80003e02:	02892603          	lw	a2,40(s2)
    80003e06:	47f5                	li	a5,29
    80003e08:	04c7cc63          	blt	a5,a2,80003e60 <log_write+0x7a>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80003e0c:	0001e797          	auipc	a5,0x1e
    80003e10:	5b87a783          	lw	a5,1464(a5) # 800223c4 <log+0x1c>
    80003e14:	04f05c63          	blez	a5,80003e6c <log_write+0x86>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80003e18:	4781                	li	a5,0
    80003e1a:	04c05f63          	blez	a2,80003e78 <log_write+0x92>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003e1e:	44cc                	lw	a1,12(s1)
    80003e20:	0001e717          	auipc	a4,0x1e
    80003e24:	5b470713          	addi	a4,a4,1460 # 800223d4 <log+0x2c>
  for (i = 0; i < log.lh.n; i++) {
    80003e28:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80003e2a:	4314                	lw	a3,0(a4)
    80003e2c:	04b68663          	beq	a3,a1,80003e78 <log_write+0x92>
  for (i = 0; i < log.lh.n; i++) {
    80003e30:	2785                	addiw	a5,a5,1
    80003e32:	0711                	addi	a4,a4,4
    80003e34:	fef61be3          	bne	a2,a5,80003e2a <log_write+0x44>
      break;
  }
  log.lh.block[i] = b->blockno;
    80003e38:	0621                	addi	a2,a2,8
    80003e3a:	060a                	slli	a2,a2,0x2
    80003e3c:	0001e797          	auipc	a5,0x1e
    80003e40:	56c78793          	addi	a5,a5,1388 # 800223a8 <log>
    80003e44:	97b2                	add	a5,a5,a2
    80003e46:	44d8                	lw	a4,12(s1)
    80003e48:	c7d8                	sw	a4,12(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80003e4a:	8526                	mv	a0,s1
    80003e4c:	ef3fe0ef          	jal	80002d3e <bpin>
    log.lh.n++;
    80003e50:	0001e717          	auipc	a4,0x1e
    80003e54:	55870713          	addi	a4,a4,1368 # 800223a8 <log>
    80003e58:	571c                	lw	a5,40(a4)
    80003e5a:	2785                	addiw	a5,a5,1
    80003e5c:	d71c                	sw	a5,40(a4)
    80003e5e:	a80d                	j	80003e90 <log_write+0xaa>
    panic("too big a transaction");
    80003e60:	00003517          	auipc	a0,0x3
    80003e64:	6b050513          	addi	a0,a0,1712 # 80007510 <etext+0x510>
    80003e68:	977fc0ef          	jal	800007de <panic>
    panic("log_write outside of trans");
    80003e6c:	00003517          	auipc	a0,0x3
    80003e70:	6bc50513          	addi	a0,a0,1724 # 80007528 <etext+0x528>
    80003e74:	96bfc0ef          	jal	800007de <panic>
  log.lh.block[i] = b->blockno;
    80003e78:	00878693          	addi	a3,a5,8
    80003e7c:	068a                	slli	a3,a3,0x2
    80003e7e:	0001e717          	auipc	a4,0x1e
    80003e82:	52a70713          	addi	a4,a4,1322 # 800223a8 <log>
    80003e86:	9736                	add	a4,a4,a3
    80003e88:	44d4                	lw	a3,12(s1)
    80003e8a:	c754                	sw	a3,12(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80003e8c:	faf60fe3          	beq	a2,a5,80003e4a <log_write+0x64>
  }
  release(&log.lock);
    80003e90:	0001e517          	auipc	a0,0x1e
    80003e94:	51850513          	addi	a0,a0,1304 # 800223a8 <log>
    80003e98:	dc9fc0ef          	jal	80000c60 <release>
}
    80003e9c:	60e2                	ld	ra,24(sp)
    80003e9e:	6442                	ld	s0,16(sp)
    80003ea0:	64a2                	ld	s1,8(sp)
    80003ea2:	6902                	ld	s2,0(sp)
    80003ea4:	6105                	addi	sp,sp,32
    80003ea6:	8082                	ret

0000000080003ea8 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80003ea8:	1101                	addi	sp,sp,-32
    80003eaa:	ec06                	sd	ra,24(sp)
    80003eac:	e822                	sd	s0,16(sp)
    80003eae:	e426                	sd	s1,8(sp)
    80003eb0:	e04a                	sd	s2,0(sp)
    80003eb2:	1000                	addi	s0,sp,32
    80003eb4:	84aa                	mv	s1,a0
    80003eb6:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80003eb8:	00003597          	auipc	a1,0x3
    80003ebc:	69058593          	addi	a1,a1,1680 # 80007548 <etext+0x548>
    80003ec0:	0521                	addi	a0,a0,8
    80003ec2:	c87fc0ef          	jal	80000b48 <initlock>
  lk->name = name;
    80003ec6:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80003eca:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003ece:	0204a423          	sw	zero,40(s1)
}
    80003ed2:	60e2                	ld	ra,24(sp)
    80003ed4:	6442                	ld	s0,16(sp)
    80003ed6:	64a2                	ld	s1,8(sp)
    80003ed8:	6902                	ld	s2,0(sp)
    80003eda:	6105                	addi	sp,sp,32
    80003edc:	8082                	ret

0000000080003ede <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80003ede:	1101                	addi	sp,sp,-32
    80003ee0:	ec06                	sd	ra,24(sp)
    80003ee2:	e822                	sd	s0,16(sp)
    80003ee4:	e426                	sd	s1,8(sp)
    80003ee6:	e04a                	sd	s2,0(sp)
    80003ee8:	1000                	addi	s0,sp,32
    80003eea:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003eec:	00850913          	addi	s2,a0,8
    80003ef0:	854a                	mv	a0,s2
    80003ef2:	cdbfc0ef          	jal	80000bcc <acquire>
  while (lk->locked) {
    80003ef6:	409c                	lw	a5,0(s1)
    80003ef8:	c799                	beqz	a5,80003f06 <acquiresleep+0x28>
    sleep(lk, &lk->lk);
    80003efa:	85ca                	mv	a1,s2
    80003efc:	8526                	mv	a0,s1
    80003efe:	fcbfd0ef          	jal	80001ec8 <sleep>
  while (lk->locked) {
    80003f02:	409c                	lw	a5,0(s1)
    80003f04:	fbfd                	bnez	a5,80003efa <acquiresleep+0x1c>
  }
  lk->locked = 1;
    80003f06:	4785                	li	a5,1
    80003f08:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80003f0a:	9b5fd0ef          	jal	800018be <myproc>
    80003f0e:	591c                	lw	a5,48(a0)
    80003f10:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80003f12:	854a                	mv	a0,s2
    80003f14:	d4dfc0ef          	jal	80000c60 <release>
}
    80003f18:	60e2                	ld	ra,24(sp)
    80003f1a:	6442                	ld	s0,16(sp)
    80003f1c:	64a2                	ld	s1,8(sp)
    80003f1e:	6902                	ld	s2,0(sp)
    80003f20:	6105                	addi	sp,sp,32
    80003f22:	8082                	ret

0000000080003f24 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80003f24:	1101                	addi	sp,sp,-32
    80003f26:	ec06                	sd	ra,24(sp)
    80003f28:	e822                	sd	s0,16(sp)
    80003f2a:	e426                	sd	s1,8(sp)
    80003f2c:	e04a                	sd	s2,0(sp)
    80003f2e:	1000                	addi	s0,sp,32
    80003f30:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80003f32:	00850913          	addi	s2,a0,8
    80003f36:	854a                	mv	a0,s2
    80003f38:	c95fc0ef          	jal	80000bcc <acquire>
  lk->locked = 0;
    80003f3c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80003f40:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80003f44:	8526                	mv	a0,s1
    80003f46:	fcffd0ef          	jal	80001f14 <wakeup>
  release(&lk->lk);
    80003f4a:	854a                	mv	a0,s2
    80003f4c:	d15fc0ef          	jal	80000c60 <release>
}
    80003f50:	60e2                	ld	ra,24(sp)
    80003f52:	6442                	ld	s0,16(sp)
    80003f54:	64a2                	ld	s1,8(sp)
    80003f56:	6902                	ld	s2,0(sp)
    80003f58:	6105                	addi	sp,sp,32
    80003f5a:	8082                	ret

0000000080003f5c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80003f5c:	7179                	addi	sp,sp,-48
    80003f5e:	f406                	sd	ra,40(sp)
    80003f60:	f022                	sd	s0,32(sp)
    80003f62:	ec26                	sd	s1,24(sp)
    80003f64:	e84a                	sd	s2,16(sp)
    80003f66:	1800                	addi	s0,sp,48
    80003f68:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80003f6a:	00850913          	addi	s2,a0,8
    80003f6e:	854a                	mv	a0,s2
    80003f70:	c5dfc0ef          	jal	80000bcc <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f74:	409c                	lw	a5,0(s1)
    80003f76:	ef81                	bnez	a5,80003f8e <holdingsleep+0x32>
    80003f78:	4481                	li	s1,0
  release(&lk->lk);
    80003f7a:	854a                	mv	a0,s2
    80003f7c:	ce5fc0ef          	jal	80000c60 <release>
  return r;
}
    80003f80:	8526                	mv	a0,s1
    80003f82:	70a2                	ld	ra,40(sp)
    80003f84:	7402                	ld	s0,32(sp)
    80003f86:	64e2                	ld	s1,24(sp)
    80003f88:	6942                	ld	s2,16(sp)
    80003f8a:	6145                	addi	sp,sp,48
    80003f8c:	8082                	ret
    80003f8e:	e44e                	sd	s3,8(sp)
  r = lk->locked && (lk->pid == myproc()->pid);
    80003f90:	0284a983          	lw	s3,40(s1)
    80003f94:	92bfd0ef          	jal	800018be <myproc>
    80003f98:	5904                	lw	s1,48(a0)
    80003f9a:	413484b3          	sub	s1,s1,s3
    80003f9e:	0014b493          	seqz	s1,s1
    80003fa2:	69a2                	ld	s3,8(sp)
    80003fa4:	bfd9                	j	80003f7a <holdingsleep+0x1e>

0000000080003fa6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80003fa6:	1141                	addi	sp,sp,-16
    80003fa8:	e406                	sd	ra,8(sp)
    80003faa:	e022                	sd	s0,0(sp)
    80003fac:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80003fae:	00003597          	auipc	a1,0x3
    80003fb2:	5aa58593          	addi	a1,a1,1450 # 80007558 <etext+0x558>
    80003fb6:	0001e517          	auipc	a0,0x1e
    80003fba:	53a50513          	addi	a0,a0,1338 # 800224f0 <ftable>
    80003fbe:	b8bfc0ef          	jal	80000b48 <initlock>
}
    80003fc2:	60a2                	ld	ra,8(sp)
    80003fc4:	6402                	ld	s0,0(sp)
    80003fc6:	0141                	addi	sp,sp,16
    80003fc8:	8082                	ret

0000000080003fca <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80003fca:	1101                	addi	sp,sp,-32
    80003fcc:	ec06                	sd	ra,24(sp)
    80003fce:	e822                	sd	s0,16(sp)
    80003fd0:	e426                	sd	s1,8(sp)
    80003fd2:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80003fd4:	0001e517          	auipc	a0,0x1e
    80003fd8:	51c50513          	addi	a0,a0,1308 # 800224f0 <ftable>
    80003fdc:	bf1fc0ef          	jal	80000bcc <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003fe0:	0001e497          	auipc	s1,0x1e
    80003fe4:	52848493          	addi	s1,s1,1320 # 80022508 <ftable+0x18>
    80003fe8:	0001f717          	auipc	a4,0x1f
    80003fec:	4c070713          	addi	a4,a4,1216 # 800234a8 <disk>
    if(f->ref == 0){
    80003ff0:	40dc                	lw	a5,4(s1)
    80003ff2:	cf89                	beqz	a5,8000400c <filealloc+0x42>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80003ff4:	02848493          	addi	s1,s1,40
    80003ff8:	fee49ce3          	bne	s1,a4,80003ff0 <filealloc+0x26>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80003ffc:	0001e517          	auipc	a0,0x1e
    80004000:	4f450513          	addi	a0,a0,1268 # 800224f0 <ftable>
    80004004:	c5dfc0ef          	jal	80000c60 <release>
  return 0;
    80004008:	4481                	li	s1,0
    8000400a:	a809                	j	8000401c <filealloc+0x52>
      f->ref = 1;
    8000400c:	4785                	li	a5,1
    8000400e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004010:	0001e517          	auipc	a0,0x1e
    80004014:	4e050513          	addi	a0,a0,1248 # 800224f0 <ftable>
    80004018:	c49fc0ef          	jal	80000c60 <release>
}
    8000401c:	8526                	mv	a0,s1
    8000401e:	60e2                	ld	ra,24(sp)
    80004020:	6442                	ld	s0,16(sp)
    80004022:	64a2                	ld	s1,8(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	1000                	addi	s0,sp,32
    80004032:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004034:	0001e517          	auipc	a0,0x1e
    80004038:	4bc50513          	addi	a0,a0,1212 # 800224f0 <ftable>
    8000403c:	b91fc0ef          	jal	80000bcc <acquire>
  if(f->ref < 1)
    80004040:	40dc                	lw	a5,4(s1)
    80004042:	02f05063          	blez	a5,80004062 <filedup+0x3a>
    panic("filedup");
  f->ref++;
    80004046:	2785                	addiw	a5,a5,1
    80004048:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000404a:	0001e517          	auipc	a0,0x1e
    8000404e:	4a650513          	addi	a0,a0,1190 # 800224f0 <ftable>
    80004052:	c0ffc0ef          	jal	80000c60 <release>
  return f;
}
    80004056:	8526                	mv	a0,s1
    80004058:	60e2                	ld	ra,24(sp)
    8000405a:	6442                	ld	s0,16(sp)
    8000405c:	64a2                	ld	s1,8(sp)
    8000405e:	6105                	addi	sp,sp,32
    80004060:	8082                	ret
    panic("filedup");
    80004062:	00003517          	auipc	a0,0x3
    80004066:	4fe50513          	addi	a0,a0,1278 # 80007560 <etext+0x560>
    8000406a:	f74fc0ef          	jal	800007de <panic>

000000008000406e <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000406e:	7139                	addi	sp,sp,-64
    80004070:	fc06                	sd	ra,56(sp)
    80004072:	f822                	sd	s0,48(sp)
    80004074:	f426                	sd	s1,40(sp)
    80004076:	0080                	addi	s0,sp,64
    80004078:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000407a:	0001e517          	auipc	a0,0x1e
    8000407e:	47650513          	addi	a0,a0,1142 # 800224f0 <ftable>
    80004082:	b4bfc0ef          	jal	80000bcc <acquire>
  if(f->ref < 1)
    80004086:	40dc                	lw	a5,4(s1)
    80004088:	04f05863          	blez	a5,800040d8 <fileclose+0x6a>
    panic("fileclose");
  if(--f->ref > 0){
    8000408c:	37fd                	addiw	a5,a5,-1
    8000408e:	c0dc                	sw	a5,4(s1)
    80004090:	04f04e63          	bgtz	a5,800040ec <fileclose+0x7e>
    80004094:	f04a                	sd	s2,32(sp)
    80004096:	ec4e                	sd	s3,24(sp)
    80004098:	e852                	sd	s4,16(sp)
    8000409a:	e456                	sd	s5,8(sp)
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000409c:	0004a903          	lw	s2,0(s1)
    800040a0:	0094ca83          	lbu	s5,9(s1)
    800040a4:	0104ba03          	ld	s4,16(s1)
    800040a8:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800040ac:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800040b0:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800040b4:	0001e517          	auipc	a0,0x1e
    800040b8:	43c50513          	addi	a0,a0,1084 # 800224f0 <ftable>
    800040bc:	ba5fc0ef          	jal	80000c60 <release>

  if(ff.type == FD_PIPE){
    800040c0:	4785                	li	a5,1
    800040c2:	04f90063          	beq	s2,a5,80004102 <fileclose+0x94>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800040c6:	3979                	addiw	s2,s2,-2
    800040c8:	4785                	li	a5,1
    800040ca:	0527f563          	bgeu	a5,s2,80004114 <fileclose+0xa6>
    800040ce:	7902                	ld	s2,32(sp)
    800040d0:	69e2                	ld	s3,24(sp)
    800040d2:	6a42                	ld	s4,16(sp)
    800040d4:	6aa2                	ld	s5,8(sp)
    800040d6:	a00d                	j	800040f8 <fileclose+0x8a>
    800040d8:	f04a                	sd	s2,32(sp)
    800040da:	ec4e                	sd	s3,24(sp)
    800040dc:	e852                	sd	s4,16(sp)
    800040de:	e456                	sd	s5,8(sp)
    panic("fileclose");
    800040e0:	00003517          	auipc	a0,0x3
    800040e4:	48850513          	addi	a0,a0,1160 # 80007568 <etext+0x568>
    800040e8:	ef6fc0ef          	jal	800007de <panic>
    release(&ftable.lock);
    800040ec:	0001e517          	auipc	a0,0x1e
    800040f0:	40450513          	addi	a0,a0,1028 # 800224f0 <ftable>
    800040f4:	b6dfc0ef          	jal	80000c60 <release>
    begin_op();
    iput(ff.ip);
    end_op();
  }
}
    800040f8:	70e2                	ld	ra,56(sp)
    800040fa:	7442                	ld	s0,48(sp)
    800040fc:	74a2                	ld	s1,40(sp)
    800040fe:	6121                	addi	sp,sp,64
    80004100:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004102:	85d6                	mv	a1,s5
    80004104:	8552                	mv	a0,s4
    80004106:	340000ef          	jal	80004446 <pipeclose>
    8000410a:	7902                	ld	s2,32(sp)
    8000410c:	69e2                	ld	s3,24(sp)
    8000410e:	6a42                	ld	s4,16(sp)
    80004110:	6aa2                	ld	s5,8(sp)
    80004112:	b7dd                	j	800040f8 <fileclose+0x8a>
    begin_op();
    80004114:	b49ff0ef          	jal	80003c5c <begin_op>
    iput(ff.ip);
    80004118:	854e                	mv	a0,s3
    8000411a:	ac0ff0ef          	jal	800033da <iput>
    end_op();
    8000411e:	ba9ff0ef          	jal	80003cc6 <end_op>
    80004122:	7902                	ld	s2,32(sp)
    80004124:	69e2                	ld	s3,24(sp)
    80004126:	6a42                	ld	s4,16(sp)
    80004128:	6aa2                	ld	s5,8(sp)
    8000412a:	b7f9                	j	800040f8 <fileclose+0x8a>

000000008000412c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000412c:	715d                	addi	sp,sp,-80
    8000412e:	e486                	sd	ra,72(sp)
    80004130:	e0a2                	sd	s0,64(sp)
    80004132:	fc26                	sd	s1,56(sp)
    80004134:	f44e                	sd	s3,40(sp)
    80004136:	0880                	addi	s0,sp,80
    80004138:	84aa                	mv	s1,a0
    8000413a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000413c:	f82fd0ef          	jal	800018be <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004140:	409c                	lw	a5,0(s1)
    80004142:	37f9                	addiw	a5,a5,-2
    80004144:	4705                	li	a4,1
    80004146:	04f76263          	bltu	a4,a5,8000418a <filestat+0x5e>
    8000414a:	f84a                	sd	s2,48(sp)
    8000414c:	f052                	sd	s4,32(sp)
    8000414e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004150:	6c88                	ld	a0,24(s1)
    80004152:	906ff0ef          	jal	80003258 <ilock>
    stati(f->ip, &st);
    80004156:	fb840a13          	addi	s4,s0,-72
    8000415a:	85d2                	mv	a1,s4
    8000415c:	6c88                	ld	a0,24(s1)
    8000415e:	c5eff0ef          	jal	800035bc <stati>
    iunlock(f->ip);
    80004162:	6c88                	ld	a0,24(s1)
    80004164:	9a2ff0ef          	jal	80003306 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004168:	46e1                	li	a3,24
    8000416a:	8652                	mv	a2,s4
    8000416c:	85ce                	mv	a1,s3
    8000416e:	05093503          	ld	a0,80(s2)
    80004172:	c7efd0ef          	jal	800015f0 <copyout>
    80004176:	41f5551b          	sraiw	a0,a0,0x1f
    8000417a:	7942                	ld	s2,48(sp)
    8000417c:	7a02                	ld	s4,32(sp)
      return -1;
    return 0;
  }
  return -1;
}
    8000417e:	60a6                	ld	ra,72(sp)
    80004180:	6406                	ld	s0,64(sp)
    80004182:	74e2                	ld	s1,56(sp)
    80004184:	79a2                	ld	s3,40(sp)
    80004186:	6161                	addi	sp,sp,80
    80004188:	8082                	ret
  return -1;
    8000418a:	557d                	li	a0,-1
    8000418c:	bfcd                	j	8000417e <filestat+0x52>

000000008000418e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000418e:	7179                	addi	sp,sp,-48
    80004190:	f406                	sd	ra,40(sp)
    80004192:	f022                	sd	s0,32(sp)
    80004194:	e84a                	sd	s2,16(sp)
    80004196:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004198:	00854783          	lbu	a5,8(a0)
    8000419c:	cfd1                	beqz	a5,80004238 <fileread+0xaa>
    8000419e:	ec26                	sd	s1,24(sp)
    800041a0:	e44e                	sd	s3,8(sp)
    800041a2:	84aa                	mv	s1,a0
    800041a4:	89ae                	mv	s3,a1
    800041a6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800041a8:	411c                	lw	a5,0(a0)
    800041aa:	4705                	li	a4,1
    800041ac:	04e78363          	beq	a5,a4,800041f2 <fileread+0x64>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800041b0:	470d                	li	a4,3
    800041b2:	04e78763          	beq	a5,a4,80004200 <fileread+0x72>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800041b6:	4709                	li	a4,2
    800041b8:	06e79a63          	bne	a5,a4,8000422c <fileread+0x9e>
    ilock(f->ip);
    800041bc:	6d08                	ld	a0,24(a0)
    800041be:	89aff0ef          	jal	80003258 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800041c2:	874a                	mv	a4,s2
    800041c4:	5094                	lw	a3,32(s1)
    800041c6:	864e                	mv	a2,s3
    800041c8:	4585                	li	a1,1
    800041ca:	6c88                	ld	a0,24(s1)
    800041cc:	c1eff0ef          	jal	800035ea <readi>
    800041d0:	892a                	mv	s2,a0
    800041d2:	00a05563          	blez	a0,800041dc <fileread+0x4e>
      f->off += r;
    800041d6:	509c                	lw	a5,32(s1)
    800041d8:	9fa9                	addw	a5,a5,a0
    800041da:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800041dc:	6c88                	ld	a0,24(s1)
    800041de:	928ff0ef          	jal	80003306 <iunlock>
    800041e2:	64e2                	ld	s1,24(sp)
    800041e4:	69a2                	ld	s3,8(sp)
  } else {
    panic("fileread");
  }

  return r;
}
    800041e6:	854a                	mv	a0,s2
    800041e8:	70a2                	ld	ra,40(sp)
    800041ea:	7402                	ld	s0,32(sp)
    800041ec:	6942                	ld	s2,16(sp)
    800041ee:	6145                	addi	sp,sp,48
    800041f0:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800041f2:	6908                	ld	a0,16(a0)
    800041f4:	3a2000ef          	jal	80004596 <piperead>
    800041f8:	892a                	mv	s2,a0
    800041fa:	64e2                	ld	s1,24(sp)
    800041fc:	69a2                	ld	s3,8(sp)
    800041fe:	b7e5                	j	800041e6 <fileread+0x58>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004200:	02451783          	lh	a5,36(a0)
    80004204:	03079693          	slli	a3,a5,0x30
    80004208:	92c1                	srli	a3,a3,0x30
    8000420a:	4725                	li	a4,9
    8000420c:	02d76863          	bltu	a4,a3,8000423c <fileread+0xae>
    80004210:	0792                	slli	a5,a5,0x4
    80004212:	0001e717          	auipc	a4,0x1e
    80004216:	23e70713          	addi	a4,a4,574 # 80022450 <devsw>
    8000421a:	97ba                	add	a5,a5,a4
    8000421c:	639c                	ld	a5,0(a5)
    8000421e:	c39d                	beqz	a5,80004244 <fileread+0xb6>
    r = devsw[f->major].read(1, addr, n);
    80004220:	4505                	li	a0,1
    80004222:	9782                	jalr	a5
    80004224:	892a                	mv	s2,a0
    80004226:	64e2                	ld	s1,24(sp)
    80004228:	69a2                	ld	s3,8(sp)
    8000422a:	bf75                	j	800041e6 <fileread+0x58>
    panic("fileread");
    8000422c:	00003517          	auipc	a0,0x3
    80004230:	34c50513          	addi	a0,a0,844 # 80007578 <etext+0x578>
    80004234:	daafc0ef          	jal	800007de <panic>
    return -1;
    80004238:	597d                	li	s2,-1
    8000423a:	b775                	j	800041e6 <fileread+0x58>
      return -1;
    8000423c:	597d                	li	s2,-1
    8000423e:	64e2                	ld	s1,24(sp)
    80004240:	69a2                	ld	s3,8(sp)
    80004242:	b755                	j	800041e6 <fileread+0x58>
    80004244:	597d                	li	s2,-1
    80004246:	64e2                	ld	s1,24(sp)
    80004248:	69a2                	ld	s3,8(sp)
    8000424a:	bf71                	j	800041e6 <fileread+0x58>

000000008000424c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000424c:	00954783          	lbu	a5,9(a0)
    80004250:	10078e63          	beqz	a5,8000436c <filewrite+0x120>
{
    80004254:	711d                	addi	sp,sp,-96
    80004256:	ec86                	sd	ra,88(sp)
    80004258:	e8a2                	sd	s0,80(sp)
    8000425a:	e0ca                	sd	s2,64(sp)
    8000425c:	f456                	sd	s5,40(sp)
    8000425e:	f05a                	sd	s6,32(sp)
    80004260:	1080                	addi	s0,sp,96
    80004262:	892a                	mv	s2,a0
    80004264:	8b2e                	mv	s6,a1
    80004266:	8ab2                	mv	s5,a2
    return -1;

  if(f->type == FD_PIPE){
    80004268:	411c                	lw	a5,0(a0)
    8000426a:	4705                	li	a4,1
    8000426c:	02e78963          	beq	a5,a4,8000429e <filewrite+0x52>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004270:	470d                	li	a4,3
    80004272:	02e78a63          	beq	a5,a4,800042a6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004276:	4709                	li	a4,2
    80004278:	0ce79e63          	bne	a5,a4,80004354 <filewrite+0x108>
    8000427c:	f852                	sd	s4,48(sp)
    // the maximum log transaction size, including
    // i-node, indirect block, allocation blocks,
    // and 2 blocks of slop for non-aligned writes.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000427e:	0ac05963          	blez	a2,80004330 <filewrite+0xe4>
    80004282:	e4a6                	sd	s1,72(sp)
    80004284:	fc4e                	sd	s3,56(sp)
    80004286:	ec5e                	sd	s7,24(sp)
    80004288:	e862                	sd	s8,16(sp)
    8000428a:	e466                	sd	s9,8(sp)
    int i = 0;
    8000428c:	4a01                	li	s4,0
      int n1 = n - i;
      if(n1 > max)
    8000428e:	6b85                	lui	s7,0x1
    80004290:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004294:	6c85                	lui	s9,0x1
    80004296:	c00c8c9b          	addiw	s9,s9,-1024 # c00 <_entry-0x7ffff400>
        n1 = max;

      begin_op();
      ilock(f->ip);
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000429a:	4c05                	li	s8,1
    8000429c:	a8ad                	j	80004316 <filewrite+0xca>
    ret = pipewrite(f->pipe, addr, n);
    8000429e:	6908                	ld	a0,16(a0)
    800042a0:	1fe000ef          	jal	8000449e <pipewrite>
    800042a4:	a04d                	j	80004346 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800042a6:	02451783          	lh	a5,36(a0)
    800042aa:	03079693          	slli	a3,a5,0x30
    800042ae:	92c1                	srli	a3,a3,0x30
    800042b0:	4725                	li	a4,9
    800042b2:	0ad76f63          	bltu	a4,a3,80004370 <filewrite+0x124>
    800042b6:	0792                	slli	a5,a5,0x4
    800042b8:	0001e717          	auipc	a4,0x1e
    800042bc:	19870713          	addi	a4,a4,408 # 80022450 <devsw>
    800042c0:	97ba                	add	a5,a5,a4
    800042c2:	679c                	ld	a5,8(a5)
    800042c4:	cbc5                	beqz	a5,80004374 <filewrite+0x128>
    ret = devsw[f->major].write(1, addr, n);
    800042c6:	4505                	li	a0,1
    800042c8:	9782                	jalr	a5
    800042ca:	a8b5                	j	80004346 <filewrite+0xfa>
      if(n1 > max)
    800042cc:	2981                	sext.w	s3,s3
      begin_op();
    800042ce:	98fff0ef          	jal	80003c5c <begin_op>
      ilock(f->ip);
    800042d2:	01893503          	ld	a0,24(s2)
    800042d6:	f83fe0ef          	jal	80003258 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800042da:	874e                	mv	a4,s3
    800042dc:	02092683          	lw	a3,32(s2)
    800042e0:	016a0633          	add	a2,s4,s6
    800042e4:	85e2                	mv	a1,s8
    800042e6:	01893503          	ld	a0,24(s2)
    800042ea:	bf2ff0ef          	jal	800036dc <writei>
    800042ee:	84aa                	mv	s1,a0
    800042f0:	00a05763          	blez	a0,800042fe <filewrite+0xb2>
        f->off += r;
    800042f4:	02092783          	lw	a5,32(s2)
    800042f8:	9fa9                	addw	a5,a5,a0
    800042fa:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800042fe:	01893503          	ld	a0,24(s2)
    80004302:	804ff0ef          	jal	80003306 <iunlock>
      end_op();
    80004306:	9c1ff0ef          	jal	80003cc6 <end_op>

      if(r != n1){
    8000430a:	02999563          	bne	s3,s1,80004334 <filewrite+0xe8>
        // error from writei
        break;
      }
      i += r;
    8000430e:	01448a3b          	addw	s4,s1,s4
    while(i < n){
    80004312:	015a5963          	bge	s4,s5,80004324 <filewrite+0xd8>
      int n1 = n - i;
    80004316:	414a87bb          	subw	a5,s5,s4
    8000431a:	89be                	mv	s3,a5
      if(n1 > max)
    8000431c:	fafbd8e3          	bge	s7,a5,800042cc <filewrite+0x80>
    80004320:	89e6                	mv	s3,s9
    80004322:	b76d                	j	800042cc <filewrite+0x80>
    80004324:	64a6                	ld	s1,72(sp)
    80004326:	79e2                	ld	s3,56(sp)
    80004328:	6be2                	ld	s7,24(sp)
    8000432a:	6c42                	ld	s8,16(sp)
    8000432c:	6ca2                	ld	s9,8(sp)
    8000432e:	a801                	j	8000433e <filewrite+0xf2>
    int i = 0;
    80004330:	4a01                	li	s4,0
    80004332:	a031                	j	8000433e <filewrite+0xf2>
    80004334:	64a6                	ld	s1,72(sp)
    80004336:	79e2                	ld	s3,56(sp)
    80004338:	6be2                	ld	s7,24(sp)
    8000433a:	6c42                	ld	s8,16(sp)
    8000433c:	6ca2                	ld	s9,8(sp)
    }
    ret = (i == n ? n : -1);
    8000433e:	034a9d63          	bne	s5,s4,80004378 <filewrite+0x12c>
    80004342:	8556                	mv	a0,s5
    80004344:	7a42                	ld	s4,48(sp)
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004346:	60e6                	ld	ra,88(sp)
    80004348:	6446                	ld	s0,80(sp)
    8000434a:	6906                	ld	s2,64(sp)
    8000434c:	7aa2                	ld	s5,40(sp)
    8000434e:	7b02                	ld	s6,32(sp)
    80004350:	6125                	addi	sp,sp,96
    80004352:	8082                	ret
    80004354:	e4a6                	sd	s1,72(sp)
    80004356:	fc4e                	sd	s3,56(sp)
    80004358:	f852                	sd	s4,48(sp)
    8000435a:	ec5e                	sd	s7,24(sp)
    8000435c:	e862                	sd	s8,16(sp)
    8000435e:	e466                	sd	s9,8(sp)
    panic("filewrite");
    80004360:	00003517          	auipc	a0,0x3
    80004364:	22850513          	addi	a0,a0,552 # 80007588 <etext+0x588>
    80004368:	c76fc0ef          	jal	800007de <panic>
    return -1;
    8000436c:	557d                	li	a0,-1
}
    8000436e:	8082                	ret
      return -1;
    80004370:	557d                	li	a0,-1
    80004372:	bfd1                	j	80004346 <filewrite+0xfa>
    80004374:	557d                	li	a0,-1
    80004376:	bfc1                	j	80004346 <filewrite+0xfa>
    ret = (i == n ? n : -1);
    80004378:	557d                	li	a0,-1
    8000437a:	7a42                	ld	s4,48(sp)
    8000437c:	b7e9                	j	80004346 <filewrite+0xfa>

000000008000437e <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    8000437e:	7179                	addi	sp,sp,-48
    80004380:	f406                	sd	ra,40(sp)
    80004382:	f022                	sd	s0,32(sp)
    80004384:	ec26                	sd	s1,24(sp)
    80004386:	e052                	sd	s4,0(sp)
    80004388:	1800                	addi	s0,sp,48
    8000438a:	84aa                	mv	s1,a0
    8000438c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000438e:	0005b023          	sd	zero,0(a1)
    80004392:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004396:	c35ff0ef          	jal	80003fca <filealloc>
    8000439a:	e088                	sd	a0,0(s1)
    8000439c:	c549                	beqz	a0,80004426 <pipealloc+0xa8>
    8000439e:	c2dff0ef          	jal	80003fca <filealloc>
    800043a2:	00aa3023          	sd	a0,0(s4)
    800043a6:	cd25                	beqz	a0,8000441e <pipealloc+0xa0>
    800043a8:	e84a                	sd	s2,16(sp)
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800043aa:	f4efc0ef          	jal	80000af8 <kalloc>
    800043ae:	892a                	mv	s2,a0
    800043b0:	c12d                	beqz	a0,80004412 <pipealloc+0x94>
    800043b2:	e44e                	sd	s3,8(sp)
    goto bad;
  pi->readopen = 1;
    800043b4:	4985                	li	s3,1
    800043b6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800043ba:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800043be:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800043c2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800043c6:	00003597          	auipc	a1,0x3
    800043ca:	1d258593          	addi	a1,a1,466 # 80007598 <etext+0x598>
    800043ce:	f7afc0ef          	jal	80000b48 <initlock>
  (*f0)->type = FD_PIPE;
    800043d2:	609c                	ld	a5,0(s1)
    800043d4:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800043d8:	609c                	ld	a5,0(s1)
    800043da:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800043de:	609c                	ld	a5,0(s1)
    800043e0:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800043e4:	609c                	ld	a5,0(s1)
    800043e6:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800043ea:	000a3783          	ld	a5,0(s4)
    800043ee:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800043f2:	000a3783          	ld	a5,0(s4)
    800043f6:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800043fa:	000a3783          	ld	a5,0(s4)
    800043fe:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004402:	000a3783          	ld	a5,0(s4)
    80004406:	0127b823          	sd	s2,16(a5)
  return 0;
    8000440a:	4501                	li	a0,0
    8000440c:	6942                	ld	s2,16(sp)
    8000440e:	69a2                	ld	s3,8(sp)
    80004410:	a01d                	j	80004436 <pipealloc+0xb8>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004412:	6088                	ld	a0,0(s1)
    80004414:	c119                	beqz	a0,8000441a <pipealloc+0x9c>
    80004416:	6942                	ld	s2,16(sp)
    80004418:	a029                	j	80004422 <pipealloc+0xa4>
    8000441a:	6942                	ld	s2,16(sp)
    8000441c:	a029                	j	80004426 <pipealloc+0xa8>
    8000441e:	6088                	ld	a0,0(s1)
    80004420:	c10d                	beqz	a0,80004442 <pipealloc+0xc4>
    fileclose(*f0);
    80004422:	c4dff0ef          	jal	8000406e <fileclose>
  if(*f1)
    80004426:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000442a:	557d                	li	a0,-1
  if(*f1)
    8000442c:	c789                	beqz	a5,80004436 <pipealloc+0xb8>
    fileclose(*f1);
    8000442e:	853e                	mv	a0,a5
    80004430:	c3fff0ef          	jal	8000406e <fileclose>
  return -1;
    80004434:	557d                	li	a0,-1
}
    80004436:	70a2                	ld	ra,40(sp)
    80004438:	7402                	ld	s0,32(sp)
    8000443a:	64e2                	ld	s1,24(sp)
    8000443c:	6a02                	ld	s4,0(sp)
    8000443e:	6145                	addi	sp,sp,48
    80004440:	8082                	ret
  return -1;
    80004442:	557d                	li	a0,-1
    80004444:	bfcd                	j	80004436 <pipealloc+0xb8>

0000000080004446 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004446:	1101                	addi	sp,sp,-32
    80004448:	ec06                	sd	ra,24(sp)
    8000444a:	e822                	sd	s0,16(sp)
    8000444c:	e426                	sd	s1,8(sp)
    8000444e:	e04a                	sd	s2,0(sp)
    80004450:	1000                	addi	s0,sp,32
    80004452:	84aa                	mv	s1,a0
    80004454:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004456:	f76fc0ef          	jal	80000bcc <acquire>
  if(writable){
    8000445a:	02090763          	beqz	s2,80004488 <pipeclose+0x42>
    pi->writeopen = 0;
    8000445e:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004462:	21848513          	addi	a0,s1,536
    80004466:	aaffd0ef          	jal	80001f14 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000446a:	2204b783          	ld	a5,544(s1)
    8000446e:	e785                	bnez	a5,80004496 <pipeclose+0x50>
    release(&pi->lock);
    80004470:	8526                	mv	a0,s1
    80004472:	feefc0ef          	jal	80000c60 <release>
    kfree((char*)pi);
    80004476:	8526                	mv	a0,s1
    80004478:	d9efc0ef          	jal	80000a16 <kfree>
  } else
    release(&pi->lock);
}
    8000447c:	60e2                	ld	ra,24(sp)
    8000447e:	6442                	ld	s0,16(sp)
    80004480:	64a2                	ld	s1,8(sp)
    80004482:	6902                	ld	s2,0(sp)
    80004484:	6105                	addi	sp,sp,32
    80004486:	8082                	ret
    pi->readopen = 0;
    80004488:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000448c:	21c48513          	addi	a0,s1,540
    80004490:	a85fd0ef          	jal	80001f14 <wakeup>
    80004494:	bfd9                	j	8000446a <pipeclose+0x24>
    release(&pi->lock);
    80004496:	8526                	mv	a0,s1
    80004498:	fc8fc0ef          	jal	80000c60 <release>
}
    8000449c:	b7c5                	j	8000447c <pipeclose+0x36>

000000008000449e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    8000449e:	7159                	addi	sp,sp,-112
    800044a0:	f486                	sd	ra,104(sp)
    800044a2:	f0a2                	sd	s0,96(sp)
    800044a4:	eca6                	sd	s1,88(sp)
    800044a6:	e8ca                	sd	s2,80(sp)
    800044a8:	e4ce                	sd	s3,72(sp)
    800044aa:	e0d2                	sd	s4,64(sp)
    800044ac:	fc56                	sd	s5,56(sp)
    800044ae:	1880                	addi	s0,sp,112
    800044b0:	84aa                	mv	s1,a0
    800044b2:	8aae                	mv	s5,a1
    800044b4:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800044b6:	c08fd0ef          	jal	800018be <myproc>
    800044ba:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800044bc:	8526                	mv	a0,s1
    800044be:	f0efc0ef          	jal	80000bcc <acquire>
  while(i < n){
    800044c2:	0d405263          	blez	s4,80004586 <pipewrite+0xe8>
    800044c6:	f85a                	sd	s6,48(sp)
    800044c8:	f45e                	sd	s7,40(sp)
    800044ca:	f062                	sd	s8,32(sp)
    800044cc:	ec66                	sd	s9,24(sp)
    800044ce:	e86a                	sd	s10,16(sp)
  int i = 0;
    800044d0:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800044d2:	f9f40c13          	addi	s8,s0,-97
    800044d6:	4b85                	li	s7,1
    800044d8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800044da:	21848d13          	addi	s10,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800044de:	21c48c93          	addi	s9,s1,540
    800044e2:	a82d                	j	8000451c <pipewrite+0x7e>
      release(&pi->lock);
    800044e4:	8526                	mv	a0,s1
    800044e6:	f7afc0ef          	jal	80000c60 <release>
      return -1;
    800044ea:	597d                	li	s2,-1
    800044ec:	7b42                	ld	s6,48(sp)
    800044ee:	7ba2                	ld	s7,40(sp)
    800044f0:	7c02                	ld	s8,32(sp)
    800044f2:	6ce2                	ld	s9,24(sp)
    800044f4:	6d42                	ld	s10,16(sp)
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    800044f6:	854a                	mv	a0,s2
    800044f8:	70a6                	ld	ra,104(sp)
    800044fa:	7406                	ld	s0,96(sp)
    800044fc:	64e6                	ld	s1,88(sp)
    800044fe:	6946                	ld	s2,80(sp)
    80004500:	69a6                	ld	s3,72(sp)
    80004502:	6a06                	ld	s4,64(sp)
    80004504:	7ae2                	ld	s5,56(sp)
    80004506:	6165                	addi	sp,sp,112
    80004508:	8082                	ret
      wakeup(&pi->nread);
    8000450a:	856a                	mv	a0,s10
    8000450c:	a09fd0ef          	jal	80001f14 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004510:	85a6                	mv	a1,s1
    80004512:	8566                	mv	a0,s9
    80004514:	9b5fd0ef          	jal	80001ec8 <sleep>
  while(i < n){
    80004518:	05495a63          	bge	s2,s4,8000456c <pipewrite+0xce>
    if(pi->readopen == 0 || killed(pr)){
    8000451c:	2204a783          	lw	a5,544(s1)
    80004520:	d3f1                	beqz	a5,800044e4 <pipewrite+0x46>
    80004522:	854e                	mv	a0,s3
    80004524:	bddfd0ef          	jal	80002100 <killed>
    80004528:	fd55                	bnez	a0,800044e4 <pipewrite+0x46>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    8000452a:	2184a783          	lw	a5,536(s1)
    8000452e:	21c4a703          	lw	a4,540(s1)
    80004532:	2007879b          	addiw	a5,a5,512
    80004536:	fcf70ae3          	beq	a4,a5,8000450a <pipewrite+0x6c>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000453a:	86de                	mv	a3,s7
    8000453c:	01590633          	add	a2,s2,s5
    80004540:	85e2                	mv	a1,s8
    80004542:	0509b503          	ld	a0,80(s3)
    80004546:	968fd0ef          	jal	800016ae <copyin>
    8000454a:	05650063          	beq	a0,s6,8000458a <pipewrite+0xec>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000454e:	21c4a783          	lw	a5,540(s1)
    80004552:	0017871b          	addiw	a4,a5,1
    80004556:	20e4ae23          	sw	a4,540(s1)
    8000455a:	1ff7f793          	andi	a5,a5,511
    8000455e:	97a6                	add	a5,a5,s1
    80004560:	f9f44703          	lbu	a4,-97(s0)
    80004564:	00e78c23          	sb	a4,24(a5)
      i++;
    80004568:	2905                	addiw	s2,s2,1
    8000456a:	b77d                	j	80004518 <pipewrite+0x7a>
    8000456c:	7b42                	ld	s6,48(sp)
    8000456e:	7ba2                	ld	s7,40(sp)
    80004570:	7c02                	ld	s8,32(sp)
    80004572:	6ce2                	ld	s9,24(sp)
    80004574:	6d42                	ld	s10,16(sp)
  wakeup(&pi->nread);
    80004576:	21848513          	addi	a0,s1,536
    8000457a:	99bfd0ef          	jal	80001f14 <wakeup>
  release(&pi->lock);
    8000457e:	8526                	mv	a0,s1
    80004580:	ee0fc0ef          	jal	80000c60 <release>
  return i;
    80004584:	bf8d                	j	800044f6 <pipewrite+0x58>
  int i = 0;
    80004586:	4901                	li	s2,0
    80004588:	b7fd                	j	80004576 <pipewrite+0xd8>
    8000458a:	7b42                	ld	s6,48(sp)
    8000458c:	7ba2                	ld	s7,40(sp)
    8000458e:	7c02                	ld	s8,32(sp)
    80004590:	6ce2                	ld	s9,24(sp)
    80004592:	6d42                	ld	s10,16(sp)
    80004594:	b7cd                	j	80004576 <pipewrite+0xd8>

0000000080004596 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004596:	711d                	addi	sp,sp,-96
    80004598:	ec86                	sd	ra,88(sp)
    8000459a:	e8a2                	sd	s0,80(sp)
    8000459c:	e4a6                	sd	s1,72(sp)
    8000459e:	e0ca                	sd	s2,64(sp)
    800045a0:	fc4e                	sd	s3,56(sp)
    800045a2:	f852                	sd	s4,48(sp)
    800045a4:	f456                	sd	s5,40(sp)
    800045a6:	1080                	addi	s0,sp,96
    800045a8:	84aa                	mv	s1,a0
    800045aa:	892e                	mv	s2,a1
    800045ac:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800045ae:	b10fd0ef          	jal	800018be <myproc>
    800045b2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800045b4:	8526                	mv	a0,s1
    800045b6:	e16fc0ef          	jal	80000bcc <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800045ba:	2184a703          	lw	a4,536(s1)
    800045be:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800045c2:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800045c6:	02f71763          	bne	a4,a5,800045f4 <piperead+0x5e>
    800045ca:	2244a783          	lw	a5,548(s1)
    800045ce:	cf85                	beqz	a5,80004606 <piperead+0x70>
    if(killed(pr)){
    800045d0:	8552                	mv	a0,s4
    800045d2:	b2ffd0ef          	jal	80002100 <killed>
    800045d6:	e11d                	bnez	a0,800045fc <piperead+0x66>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800045d8:	85a6                	mv	a1,s1
    800045da:	854e                	mv	a0,s3
    800045dc:	8edfd0ef          	jal	80001ec8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800045e0:	2184a703          	lw	a4,536(s1)
    800045e4:	21c4a783          	lw	a5,540(s1)
    800045e8:	fef701e3          	beq	a4,a5,800045ca <piperead+0x34>
    800045ec:	f05a                	sd	s6,32(sp)
    800045ee:	ec5e                	sd	s7,24(sp)
    800045f0:	e862                	sd	s8,16(sp)
    800045f2:	a829                	j	8000460c <piperead+0x76>
    800045f4:	f05a                	sd	s6,32(sp)
    800045f6:	ec5e                	sd	s7,24(sp)
    800045f8:	e862                	sd	s8,16(sp)
    800045fa:	a809                	j	8000460c <piperead+0x76>
      release(&pi->lock);
    800045fc:	8526                	mv	a0,s1
    800045fe:	e62fc0ef          	jal	80000c60 <release>
      return -1;
    80004602:	59fd                	li	s3,-1
    80004604:	a0ad                	j	8000466e <piperead+0xd8>
    80004606:	f05a                	sd	s6,32(sp)
    80004608:	ec5e                	sd	s7,24(sp)
    8000460a:	e862                	sd	s8,16(sp)
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000460c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    8000460e:	faf40c13          	addi	s8,s0,-81
    80004612:	4b85                	li	s7,1
    80004614:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004616:	05505263          	blez	s5,8000465a <piperead+0xc4>
    if(pi->nread == pi->nwrite)
    8000461a:	2184a783          	lw	a5,536(s1)
    8000461e:	21c4a703          	lw	a4,540(s1)
    80004622:	02f70c63          	beq	a4,a5,8000465a <piperead+0xc4>
    ch = pi->data[pi->nread % PIPESIZE];
    80004626:	1ff7f793          	andi	a5,a5,511
    8000462a:	97a6                	add	a5,a5,s1
    8000462c:	0187c783          	lbu	a5,24(a5)
    80004630:	faf407a3          	sb	a5,-81(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1) {
    80004634:	86de                	mv	a3,s7
    80004636:	8662                	mv	a2,s8
    80004638:	85ca                	mv	a1,s2
    8000463a:	050a3503          	ld	a0,80(s4)
    8000463e:	fb3fc0ef          	jal	800015f0 <copyout>
    80004642:	05650063          	beq	a0,s6,80004682 <piperead+0xec>
      if(i == 0)
        i = -1;
      break;
    }
    pi->nread++;
    80004646:	2184a783          	lw	a5,536(s1)
    8000464a:	2785                	addiw	a5,a5,1
    8000464c:	20f4ac23          	sw	a5,536(s1)
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004650:	2985                	addiw	s3,s3,1
    80004652:	0905                	addi	s2,s2,1
    80004654:	fd3a93e3          	bne	s5,s3,8000461a <piperead+0x84>
    80004658:	89d6                	mv	s3,s5
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    8000465a:	21c48513          	addi	a0,s1,540
    8000465e:	8b7fd0ef          	jal	80001f14 <wakeup>
  release(&pi->lock);
    80004662:	8526                	mv	a0,s1
    80004664:	dfcfc0ef          	jal	80000c60 <release>
    80004668:	7b02                	ld	s6,32(sp)
    8000466a:	6be2                	ld	s7,24(sp)
    8000466c:	6c42                	ld	s8,16(sp)
  return i;
}
    8000466e:	854e                	mv	a0,s3
    80004670:	60e6                	ld	ra,88(sp)
    80004672:	6446                	ld	s0,80(sp)
    80004674:	64a6                	ld	s1,72(sp)
    80004676:	6906                	ld	s2,64(sp)
    80004678:	79e2                	ld	s3,56(sp)
    8000467a:	7a42                	ld	s4,48(sp)
    8000467c:	7aa2                	ld	s5,40(sp)
    8000467e:	6125                	addi	sp,sp,96
    80004680:	8082                	ret
      if(i == 0)
    80004682:	fc099ce3          	bnez	s3,8000465a <piperead+0xc4>
        i = -1;
    80004686:	89aa                	mv	s3,a0
    80004688:	bfc9                	j	8000465a <piperead+0xc4>

000000008000468a <flags2perm>:

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

// map ELF permissions to PTE permission bits.
int flags2perm(int flags)
{
    8000468a:	1141                	addi	sp,sp,-16
    8000468c:	e406                	sd	ra,8(sp)
    8000468e:	e022                	sd	s0,0(sp)
    80004690:	0800                	addi	s0,sp,16
    80004692:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004694:	0035151b          	slliw	a0,a0,0x3
    80004698:	8921                	andi	a0,a0,8
      perm = PTE_X;
    if(flags & 0x2)
    8000469a:	8b89                	andi	a5,a5,2
    8000469c:	c399                	beqz	a5,800046a2 <flags2perm+0x18>
      perm |= PTE_W;
    8000469e:	00456513          	ori	a0,a0,4
    return perm;
}
    800046a2:	60a2                	ld	ra,8(sp)
    800046a4:	6402                	ld	s0,0(sp)
    800046a6:	0141                	addi	sp,sp,16
    800046a8:	8082                	ret

00000000800046aa <kexec>:
//
// the implementation of the exec() system call
//
int
kexec(char *path, char **argv)
{
    800046aa:	de010113          	addi	sp,sp,-544
    800046ae:	20113c23          	sd	ra,536(sp)
    800046b2:	20813823          	sd	s0,528(sp)
    800046b6:	20913423          	sd	s1,520(sp)
    800046ba:	21213023          	sd	s2,512(sp)
    800046be:	1400                	addi	s0,sp,544
    800046c0:	892a                	mv	s2,a0
    800046c2:	dea43823          	sd	a0,-528(s0)
    800046c6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800046ca:	9f4fd0ef          	jal	800018be <myproc>
    800046ce:	84aa                	mv	s1,a0

  begin_op();
    800046d0:	d8cff0ef          	jal	80003c5c <begin_op>

  // Open the executable file.
  if((ip = namei(path)) == 0){
    800046d4:	854a                	mv	a0,s2
    800046d6:	bacff0ef          	jal	80003a82 <namei>
    800046da:	cd21                	beqz	a0,80004732 <kexec+0x88>
    800046dc:	fbd2                	sd	s4,496(sp)
    800046de:	8a2a                	mv	s4,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800046e0:	b79fe0ef          	jal	80003258 <ilock>

  // Read the ELF header.
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800046e4:	04000713          	li	a4,64
    800046e8:	4681                	li	a3,0
    800046ea:	e5040613          	addi	a2,s0,-432
    800046ee:	4581                	li	a1,0
    800046f0:	8552                	mv	a0,s4
    800046f2:	ef9fe0ef          	jal	800035ea <readi>
    800046f6:	04000793          	li	a5,64
    800046fa:	00f51a63          	bne	a0,a5,8000470e <kexec+0x64>
    goto bad;

  // Is this really an ELF file?
  if(elf.magic != ELF_MAGIC)
    800046fe:	e5042703          	lw	a4,-432(s0)
    80004702:	464c47b7          	lui	a5,0x464c4
    80004706:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    8000470a:	02f70863          	beq	a4,a5,8000473a <kexec+0x90>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000470e:	8552                	mv	a0,s4
    80004710:	d53fe0ef          	jal	80003462 <iunlockput>
    end_op();
    80004714:	db2ff0ef          	jal	80003cc6 <end_op>
  }
  return -1;
    80004718:	557d                	li	a0,-1
    8000471a:	7a5e                	ld	s4,496(sp)
}
    8000471c:	21813083          	ld	ra,536(sp)
    80004720:	21013403          	ld	s0,528(sp)
    80004724:	20813483          	ld	s1,520(sp)
    80004728:	20013903          	ld	s2,512(sp)
    8000472c:	22010113          	addi	sp,sp,544
    80004730:	8082                	ret
    end_op();
    80004732:	d94ff0ef          	jal	80003cc6 <end_op>
    return -1;
    80004736:	557d                	li	a0,-1
    80004738:	b7d5                	j	8000471c <kexec+0x72>
    8000473a:	f3da                	sd	s6,480(sp)
  if((pagetable = proc_pagetable(p)) == 0)
    8000473c:	8526                	mv	a0,s1
    8000473e:	a86fd0ef          	jal	800019c4 <proc_pagetable>
    80004742:	8b2a                	mv	s6,a0
    80004744:	26050d63          	beqz	a0,800049be <kexec+0x314>
    80004748:	ffce                	sd	s3,504(sp)
    8000474a:	f7d6                	sd	s5,488(sp)
    8000474c:	efde                	sd	s7,472(sp)
    8000474e:	ebe2                	sd	s8,464(sp)
    80004750:	e7e6                	sd	s9,456(sp)
    80004752:	e3ea                	sd	s10,448(sp)
    80004754:	ff6e                	sd	s11,440(sp)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004756:	e7042683          	lw	a3,-400(s0)
    8000475a:	e8845783          	lhu	a5,-376(s0)
    8000475e:	0e078763          	beqz	a5,8000484c <kexec+0x1a2>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004762:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004764:	4d01                	li	s10,0
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004766:	03800d93          	li	s11,56
    if(ph.vaddr % PGSIZE != 0)
    8000476a:	6c85                	lui	s9,0x1
    8000476c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004770:	def43423          	sd	a5,-536(s0)

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    if(sz - i < PGSIZE)
    80004774:	6a85                	lui	s5,0x1
    80004776:	a085                	j	800047d6 <kexec+0x12c>
      panic("loadseg: address should exist");
    80004778:	00003517          	auipc	a0,0x3
    8000477c:	e2850513          	addi	a0,a0,-472 # 800075a0 <etext+0x5a0>
    80004780:	85efc0ef          	jal	800007de <panic>
    if(sz - i < PGSIZE)
    80004784:	2901                	sext.w	s2,s2
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004786:	874a                	mv	a4,s2
    80004788:	009c06bb          	addw	a3,s8,s1
    8000478c:	4581                	li	a1,0
    8000478e:	8552                	mv	a0,s4
    80004790:	e5bfe0ef          	jal	800035ea <readi>
    80004794:	22a91963          	bne	s2,a0,800049c6 <kexec+0x31c>
  for(i = 0; i < sz; i += PGSIZE){
    80004798:	009a84bb          	addw	s1,s5,s1
    8000479c:	0334f263          	bgeu	s1,s3,800047c0 <kexec+0x116>
    pa = walkaddr(pagetable, va + i);
    800047a0:	02049593          	slli	a1,s1,0x20
    800047a4:	9181                	srli	a1,a1,0x20
    800047a6:	95de                	add	a1,a1,s7
    800047a8:	855a                	mv	a0,s6
    800047aa:	821fc0ef          	jal	80000fca <walkaddr>
    800047ae:	862a                	mv	a2,a0
    if(pa == 0)
    800047b0:	d561                	beqz	a0,80004778 <kexec+0xce>
    if(sz - i < PGSIZE)
    800047b2:	409987bb          	subw	a5,s3,s1
    800047b6:	893e                	mv	s2,a5
    800047b8:	fcfcf6e3          	bgeu	s9,a5,80004784 <kexec+0xda>
    800047bc:	8956                	mv	s2,s5
    800047be:	b7d9                	j	80004784 <kexec+0xda>
    sz = sz1;
    800047c0:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800047c4:	2d05                	addiw	s10,s10,1
    800047c6:	e0843783          	ld	a5,-504(s0)
    800047ca:	0387869b          	addiw	a3,a5,56
    800047ce:	e8845783          	lhu	a5,-376(s0)
    800047d2:	06fd5e63          	bge	s10,a5,8000484e <kexec+0x1a4>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800047d6:	e0d43423          	sd	a3,-504(s0)
    800047da:	876e                	mv	a4,s11
    800047dc:	e1840613          	addi	a2,s0,-488
    800047e0:	4581                	li	a1,0
    800047e2:	8552                	mv	a0,s4
    800047e4:	e07fe0ef          	jal	800035ea <readi>
    800047e8:	1db51d63          	bne	a0,s11,800049c2 <kexec+0x318>
    if(ph.type != ELF_PROG_LOAD)
    800047ec:	e1842783          	lw	a5,-488(s0)
    800047f0:	4705                	li	a4,1
    800047f2:	fce799e3          	bne	a5,a4,800047c4 <kexec+0x11a>
    if(ph.memsz < ph.filesz)
    800047f6:	e4043483          	ld	s1,-448(s0)
    800047fa:	e3843783          	ld	a5,-456(s0)
    800047fe:	1ef4e263          	bltu	s1,a5,800049e2 <kexec+0x338>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004802:	e2843783          	ld	a5,-472(s0)
    80004806:	94be                	add	s1,s1,a5
    80004808:	1ef4e063          	bltu	s1,a5,800049e8 <kexec+0x33e>
    if(ph.vaddr % PGSIZE != 0)
    8000480c:	de843703          	ld	a4,-536(s0)
    80004810:	8ff9                	and	a5,a5,a4
    80004812:	1c079e63          	bnez	a5,800049ee <kexec+0x344>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004816:	e1c42503          	lw	a0,-484(s0)
    8000481a:	e71ff0ef          	jal	8000468a <flags2perm>
    8000481e:	86aa                	mv	a3,a0
    80004820:	8626                	mv	a2,s1
    80004822:	85ca                	mv	a1,s2
    80004824:	855a                	mv	a0,s6
    80004826:	a7dfc0ef          	jal	800012a2 <uvmalloc>
    8000482a:	dea43c23          	sd	a0,-520(s0)
    8000482e:	1c050363          	beqz	a0,800049f4 <kexec+0x34a>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004832:	e2843b83          	ld	s7,-472(s0)
    80004836:	e2042c03          	lw	s8,-480(s0)
    8000483a:	e3842983          	lw	s3,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000483e:	00098463          	beqz	s3,80004846 <kexec+0x19c>
    80004842:	4481                	li	s1,0
    80004844:	bfb1                	j	800047a0 <kexec+0xf6>
    sz = sz1;
    80004846:	df843903          	ld	s2,-520(s0)
    8000484a:	bfad                	j	800047c4 <kexec+0x11a>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000484c:	4901                	li	s2,0
  iunlockput(ip);
    8000484e:	8552                	mv	a0,s4
    80004850:	c13fe0ef          	jal	80003462 <iunlockput>
  end_op();
    80004854:	c72ff0ef          	jal	80003cc6 <end_op>
  p = myproc();
    80004858:	866fd0ef          	jal	800018be <myproc>
    8000485c:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000485e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004862:	6985                	lui	s3,0x1
    80004864:	19fd                	addi	s3,s3,-1 # fff <_entry-0x7ffff001>
    80004866:	99ca                	add	s3,s3,s2
    80004868:	77fd                	lui	a5,0xfffff
    8000486a:	00f9f9b3          	and	s3,s3,a5
  if((sz1 = uvmalloc(pagetable, sz, sz + (USERSTACK+1)*PGSIZE, PTE_W)) == 0)
    8000486e:	4691                	li	a3,4
    80004870:	6609                	lui	a2,0x2
    80004872:	964e                	add	a2,a2,s3
    80004874:	85ce                	mv	a1,s3
    80004876:	855a                	mv	a0,s6
    80004878:	a2bfc0ef          	jal	800012a2 <uvmalloc>
    8000487c:	8a2a                	mv	s4,a0
    8000487e:	e105                	bnez	a0,8000489e <kexec+0x1f4>
    proc_freepagetable(pagetable, sz);
    80004880:	85ce                	mv	a1,s3
    80004882:	855a                	mv	a0,s6
    80004884:	9c4fd0ef          	jal	80001a48 <proc_freepagetable>
  return -1;
    80004888:	557d                	li	a0,-1
    8000488a:	79fe                	ld	s3,504(sp)
    8000488c:	7a5e                	ld	s4,496(sp)
    8000488e:	7abe                	ld	s5,488(sp)
    80004890:	7b1e                	ld	s6,480(sp)
    80004892:	6bfe                	ld	s7,472(sp)
    80004894:	6c5e                	ld	s8,464(sp)
    80004896:	6cbe                	ld	s9,456(sp)
    80004898:	6d1e                	ld	s10,448(sp)
    8000489a:	7dfa                	ld	s11,440(sp)
    8000489c:	b541                	j	8000471c <kexec+0x72>
  uvmclear(pagetable, sz-(USERSTACK+1)*PGSIZE);
    8000489e:	75f9                	lui	a1,0xffffe
    800048a0:	95aa                	add	a1,a1,a0
    800048a2:	855a                	mv	a0,s6
    800048a4:	be1fc0ef          	jal	80001484 <uvmclear>
  stackbase = sp - USERSTACK*PGSIZE;
    800048a8:	7bfd                	lui	s7,0xfffff
    800048aa:	9bd2                	add	s7,s7,s4
  for(argc = 0; argv[argc]; argc++) {
    800048ac:	e0043783          	ld	a5,-512(s0)
    800048b0:	6388                	ld	a0,0(a5)
  sp = sz;
    800048b2:	8952                	mv	s2,s4
  for(argc = 0; argv[argc]; argc++) {
    800048b4:	4481                	li	s1,0
    ustack[argc] = sp;
    800048b6:	e9040c93          	addi	s9,s0,-368
    if(argc >= MAXARG)
    800048ba:	02000c13          	li	s8,32
  for(argc = 0; argv[argc]; argc++) {
    800048be:	cd21                	beqz	a0,80004916 <kexec+0x26c>
    sp -= strlen(argv[argc]) + 1;
    800048c0:	d64fc0ef          	jal	80000e24 <strlen>
    800048c4:	0015079b          	addiw	a5,a0,1
    800048c8:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800048cc:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800048d0:	13796563          	bltu	s2,s7,800049fa <kexec+0x350>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800048d4:	e0043d83          	ld	s11,-512(s0)
    800048d8:	000db983          	ld	s3,0(s11)
    800048dc:	854e                	mv	a0,s3
    800048de:	d46fc0ef          	jal	80000e24 <strlen>
    800048e2:	0015069b          	addiw	a3,a0,1
    800048e6:	864e                	mv	a2,s3
    800048e8:	85ca                	mv	a1,s2
    800048ea:	855a                	mv	a0,s6
    800048ec:	d05fc0ef          	jal	800015f0 <copyout>
    800048f0:	10054763          	bltz	a0,800049fe <kexec+0x354>
    ustack[argc] = sp;
    800048f4:	00349793          	slli	a5,s1,0x3
    800048f8:	97e6                	add	a5,a5,s9
    800048fa:	0127b023          	sd	s2,0(a5) # fffffffffffff000 <end+0xffffffff7ffdba18>
  for(argc = 0; argv[argc]; argc++) {
    800048fe:	0485                	addi	s1,s1,1
    80004900:	008d8793          	addi	a5,s11,8
    80004904:	e0f43023          	sd	a5,-512(s0)
    80004908:	008db503          	ld	a0,8(s11)
    8000490c:	c509                	beqz	a0,80004916 <kexec+0x26c>
    if(argc >= MAXARG)
    8000490e:	fb8499e3          	bne	s1,s8,800048c0 <kexec+0x216>
  sz = sz1;
    80004912:	89d2                	mv	s3,s4
    80004914:	b7b5                	j	80004880 <kexec+0x1d6>
  ustack[argc] = 0;
    80004916:	00349793          	slli	a5,s1,0x3
    8000491a:	f9078793          	addi	a5,a5,-112
    8000491e:	97a2                	add	a5,a5,s0
    80004920:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004924:	00148693          	addi	a3,s1,1
    80004928:	068e                	slli	a3,a3,0x3
    8000492a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000492e:	ff097913          	andi	s2,s2,-16
  sz = sz1;
    80004932:	89d2                	mv	s3,s4
  if(sp < stackbase)
    80004934:	f57966e3          	bltu	s2,s7,80004880 <kexec+0x1d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004938:	e9040613          	addi	a2,s0,-368
    8000493c:	85ca                	mv	a1,s2
    8000493e:	855a                	mv	a0,s6
    80004940:	cb1fc0ef          	jal	800015f0 <copyout>
    80004944:	f2054ee3          	bltz	a0,80004880 <kexec+0x1d6>
  p->trapframe->a1 = sp;
    80004948:	058ab783          	ld	a5,88(s5) # 1058 <_entry-0x7fffefa8>
    8000494c:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004950:	df043783          	ld	a5,-528(s0)
    80004954:	0007c703          	lbu	a4,0(a5)
    80004958:	cf11                	beqz	a4,80004974 <kexec+0x2ca>
    8000495a:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000495c:	02f00693          	li	a3,47
    80004960:	a029                	j	8000496a <kexec+0x2c0>
  for(last=s=path; *s; s++)
    80004962:	0785                	addi	a5,a5,1
    80004964:	fff7c703          	lbu	a4,-1(a5)
    80004968:	c711                	beqz	a4,80004974 <kexec+0x2ca>
    if(*s == '/')
    8000496a:	fed71ce3          	bne	a4,a3,80004962 <kexec+0x2b8>
      last = s+1;
    8000496e:	def43823          	sd	a5,-528(s0)
    80004972:	bfc5                	j	80004962 <kexec+0x2b8>
  safestrcpy(p->name, last, sizeof(p->name));
    80004974:	4641                	li	a2,16
    80004976:	df043583          	ld	a1,-528(s0)
    8000497a:	158a8513          	addi	a0,s5,344
    8000497e:	c70fc0ef          	jal	80000dee <safestrcpy>
  oldpagetable = p->pagetable;
    80004982:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004986:	056ab823          	sd	s6,80(s5)
  p->sz = sz;
    8000498a:	054ab423          	sd	s4,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = ulib.c:start()
    8000498e:	058ab783          	ld	a5,88(s5)
    80004992:	e6843703          	ld	a4,-408(s0)
    80004996:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004998:	058ab783          	ld	a5,88(s5)
    8000499c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800049a0:	85ea                	mv	a1,s10
    800049a2:	8a6fd0ef          	jal	80001a48 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800049a6:	0004851b          	sext.w	a0,s1
    800049aa:	79fe                	ld	s3,504(sp)
    800049ac:	7a5e                	ld	s4,496(sp)
    800049ae:	7abe                	ld	s5,488(sp)
    800049b0:	7b1e                	ld	s6,480(sp)
    800049b2:	6bfe                	ld	s7,472(sp)
    800049b4:	6c5e                	ld	s8,464(sp)
    800049b6:	6cbe                	ld	s9,456(sp)
    800049b8:	6d1e                	ld	s10,448(sp)
    800049ba:	7dfa                	ld	s11,440(sp)
    800049bc:	b385                	j	8000471c <kexec+0x72>
    800049be:	7b1e                	ld	s6,480(sp)
    800049c0:	b3b9                	j	8000470e <kexec+0x64>
    800049c2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800049c6:	df843583          	ld	a1,-520(s0)
    800049ca:	855a                	mv	a0,s6
    800049cc:	87cfd0ef          	jal	80001a48 <proc_freepagetable>
  if(ip){
    800049d0:	79fe                	ld	s3,504(sp)
    800049d2:	7abe                	ld	s5,488(sp)
    800049d4:	7b1e                	ld	s6,480(sp)
    800049d6:	6bfe                	ld	s7,472(sp)
    800049d8:	6c5e                	ld	s8,464(sp)
    800049da:	6cbe                	ld	s9,456(sp)
    800049dc:	6d1e                	ld	s10,448(sp)
    800049de:	7dfa                	ld	s11,440(sp)
    800049e0:	b33d                	j	8000470e <kexec+0x64>
    800049e2:	df243c23          	sd	s2,-520(s0)
    800049e6:	b7c5                	j	800049c6 <kexec+0x31c>
    800049e8:	df243c23          	sd	s2,-520(s0)
    800049ec:	bfe9                	j	800049c6 <kexec+0x31c>
    800049ee:	df243c23          	sd	s2,-520(s0)
    800049f2:	bfd1                	j	800049c6 <kexec+0x31c>
    800049f4:	df243c23          	sd	s2,-520(s0)
    800049f8:	b7f9                	j	800049c6 <kexec+0x31c>
  sz = sz1;
    800049fa:	89d2                	mv	s3,s4
    800049fc:	b551                	j	80004880 <kexec+0x1d6>
    800049fe:	89d2                	mv	s3,s4
    80004a00:	b541                	j	80004880 <kexec+0x1d6>

0000000080004a02 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80004a02:	7179                	addi	sp,sp,-48
    80004a04:	f406                	sd	ra,40(sp)
    80004a06:	f022                	sd	s0,32(sp)
    80004a08:	ec26                	sd	s1,24(sp)
    80004a0a:	e84a                	sd	s2,16(sp)
    80004a0c:	1800                	addi	s0,sp,48
    80004a0e:	892e                	mv	s2,a1
    80004a10:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80004a12:	fdc40593          	addi	a1,s0,-36
    80004a16:	db5fd0ef          	jal	800027ca <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80004a1a:	fdc42703          	lw	a4,-36(s0)
    80004a1e:	47bd                	li	a5,15
    80004a20:	02e7e963          	bltu	a5,a4,80004a52 <argfd+0x50>
    80004a24:	e9bfc0ef          	jal	800018be <myproc>
    80004a28:	fdc42703          	lw	a4,-36(s0)
    80004a2c:	01a70793          	addi	a5,a4,26
    80004a30:	078e                	slli	a5,a5,0x3
    80004a32:	953e                	add	a0,a0,a5
    80004a34:	611c                	ld	a5,0(a0)
    80004a36:	c385                	beqz	a5,80004a56 <argfd+0x54>
    return -1;
  if(pfd)
    80004a38:	00090463          	beqz	s2,80004a40 <argfd+0x3e>
    *pfd = fd;
    80004a3c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80004a40:	4501                	li	a0,0
  if(pf)
    80004a42:	c091                	beqz	s1,80004a46 <argfd+0x44>
    *pf = f;
    80004a44:	e09c                	sd	a5,0(s1)
}
    80004a46:	70a2                	ld	ra,40(sp)
    80004a48:	7402                	ld	s0,32(sp)
    80004a4a:	64e2                	ld	s1,24(sp)
    80004a4c:	6942                	ld	s2,16(sp)
    80004a4e:	6145                	addi	sp,sp,48
    80004a50:	8082                	ret
    return -1;
    80004a52:	557d                	li	a0,-1
    80004a54:	bfcd                	j	80004a46 <argfd+0x44>
    80004a56:	557d                	li	a0,-1
    80004a58:	b7fd                	j	80004a46 <argfd+0x44>

0000000080004a5a <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80004a5a:	1101                	addi	sp,sp,-32
    80004a5c:	ec06                	sd	ra,24(sp)
    80004a5e:	e822                	sd	s0,16(sp)
    80004a60:	e426                	sd	s1,8(sp)
    80004a62:	1000                	addi	s0,sp,32
    80004a64:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80004a66:	e59fc0ef          	jal	800018be <myproc>
    80004a6a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80004a6c:	0d050793          	addi	a5,a0,208
    80004a70:	4501                	li	a0,0
    80004a72:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80004a74:	6398                	ld	a4,0(a5)
    80004a76:	cb19                	beqz	a4,80004a8c <fdalloc+0x32>
  for(fd = 0; fd < NOFILE; fd++){
    80004a78:	2505                	addiw	a0,a0,1
    80004a7a:	07a1                	addi	a5,a5,8
    80004a7c:	fed51ce3          	bne	a0,a3,80004a74 <fdalloc+0x1a>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80004a80:	557d                	li	a0,-1
}
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6105                	addi	sp,sp,32
    80004a8a:	8082                	ret
      p->ofile[fd] = f;
    80004a8c:	01a50793          	addi	a5,a0,26
    80004a90:	078e                	slli	a5,a5,0x3
    80004a92:	963e                	add	a2,a2,a5
    80004a94:	e204                	sd	s1,0(a2)
      return fd;
    80004a96:	b7f5                	j	80004a82 <fdalloc+0x28>

0000000080004a98 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80004a98:	715d                	addi	sp,sp,-80
    80004a9a:	e486                	sd	ra,72(sp)
    80004a9c:	e0a2                	sd	s0,64(sp)
    80004a9e:	fc26                	sd	s1,56(sp)
    80004aa0:	f84a                	sd	s2,48(sp)
    80004aa2:	f44e                	sd	s3,40(sp)
    80004aa4:	ec56                	sd	s5,24(sp)
    80004aa6:	e85a                	sd	s6,16(sp)
    80004aa8:	0880                	addi	s0,sp,80
    80004aaa:	8b2e                	mv	s6,a1
    80004aac:	89b2                	mv	s3,a2
    80004aae:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80004ab0:	fb040593          	addi	a1,s0,-80
    80004ab4:	fe9fe0ef          	jal	80003a9c <nameiparent>
    80004ab8:	84aa                	mv	s1,a0
    80004aba:	10050a63          	beqz	a0,80004bce <create+0x136>
    return 0;

  ilock(dp);
    80004abe:	f9afe0ef          	jal	80003258 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80004ac2:	4601                	li	a2,0
    80004ac4:	fb040593          	addi	a1,s0,-80
    80004ac8:	8526                	mv	a0,s1
    80004aca:	d2dfe0ef          	jal	800037f6 <dirlookup>
    80004ace:	8aaa                	mv	s5,a0
    80004ad0:	c129                	beqz	a0,80004b12 <create+0x7a>
    iunlockput(dp);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	98ffe0ef          	jal	80003462 <iunlockput>
    ilock(ip);
    80004ad8:	8556                	mv	a0,s5
    80004ada:	f7efe0ef          	jal	80003258 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80004ade:	4789                	li	a5,2
    80004ae0:	02fb1463          	bne	s6,a5,80004b08 <create+0x70>
    80004ae4:	044ad783          	lhu	a5,68(s5)
    80004ae8:	37f9                	addiw	a5,a5,-2
    80004aea:	17c2                	slli	a5,a5,0x30
    80004aec:	93c1                	srli	a5,a5,0x30
    80004aee:	4705                	li	a4,1
    80004af0:	00f76c63          	bltu	a4,a5,80004b08 <create+0x70>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80004af4:	8556                	mv	a0,s5
    80004af6:	60a6                	ld	ra,72(sp)
    80004af8:	6406                	ld	s0,64(sp)
    80004afa:	74e2                	ld	s1,56(sp)
    80004afc:	7942                	ld	s2,48(sp)
    80004afe:	79a2                	ld	s3,40(sp)
    80004b00:	6ae2                	ld	s5,24(sp)
    80004b02:	6b42                	ld	s6,16(sp)
    80004b04:	6161                	addi	sp,sp,80
    80004b06:	8082                	ret
    iunlockput(ip);
    80004b08:	8556                	mv	a0,s5
    80004b0a:	959fe0ef          	jal	80003462 <iunlockput>
    return 0;
    80004b0e:	4a81                	li	s5,0
    80004b10:	b7d5                	j	80004af4 <create+0x5c>
    80004b12:	f052                	sd	s4,32(sp)
  if((ip = ialloc(dp->dev, type)) == 0){
    80004b14:	85da                	mv	a1,s6
    80004b16:	4088                	lw	a0,0(s1)
    80004b18:	dd0fe0ef          	jal	800030e8 <ialloc>
    80004b1c:	8a2a                	mv	s4,a0
    80004b1e:	cd15                	beqz	a0,80004b5a <create+0xc2>
  ilock(ip);
    80004b20:	f38fe0ef          	jal	80003258 <ilock>
  ip->major = major;
    80004b24:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80004b28:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80004b2c:	4905                	li	s2,1
    80004b2e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80004b32:	8552                	mv	a0,s4
    80004b34:	e70fe0ef          	jal	800031a4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80004b38:	032b0763          	beq	s6,s2,80004b66 <create+0xce>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b3c:	004a2603          	lw	a2,4(s4)
    80004b40:	fb040593          	addi	a1,s0,-80
    80004b44:	8526                	mv	a0,s1
    80004b46:	e93fe0ef          	jal	800039d8 <dirlink>
    80004b4a:	06054563          	bltz	a0,80004bb4 <create+0x11c>
  iunlockput(dp);
    80004b4e:	8526                	mv	a0,s1
    80004b50:	913fe0ef          	jal	80003462 <iunlockput>
  return ip;
    80004b54:	8ad2                	mv	s5,s4
    80004b56:	7a02                	ld	s4,32(sp)
    80004b58:	bf71                	j	80004af4 <create+0x5c>
    iunlockput(dp);
    80004b5a:	8526                	mv	a0,s1
    80004b5c:	907fe0ef          	jal	80003462 <iunlockput>
    return 0;
    80004b60:	8ad2                	mv	s5,s4
    80004b62:	7a02                	ld	s4,32(sp)
    80004b64:	bf41                	j	80004af4 <create+0x5c>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80004b66:	004a2603          	lw	a2,4(s4)
    80004b6a:	00003597          	auipc	a1,0x3
    80004b6e:	a5658593          	addi	a1,a1,-1450 # 800075c0 <etext+0x5c0>
    80004b72:	8552                	mv	a0,s4
    80004b74:	e65fe0ef          	jal	800039d8 <dirlink>
    80004b78:	02054e63          	bltz	a0,80004bb4 <create+0x11c>
    80004b7c:	40d0                	lw	a2,4(s1)
    80004b7e:	00003597          	auipc	a1,0x3
    80004b82:	a4a58593          	addi	a1,a1,-1462 # 800075c8 <etext+0x5c8>
    80004b86:	8552                	mv	a0,s4
    80004b88:	e51fe0ef          	jal	800039d8 <dirlink>
    80004b8c:	02054463          	bltz	a0,80004bb4 <create+0x11c>
  if(dirlink(dp, name, ip->inum) < 0)
    80004b90:	004a2603          	lw	a2,4(s4)
    80004b94:	fb040593          	addi	a1,s0,-80
    80004b98:	8526                	mv	a0,s1
    80004b9a:	e3ffe0ef          	jal	800039d8 <dirlink>
    80004b9e:	00054b63          	bltz	a0,80004bb4 <create+0x11c>
    dp->nlink++;  // for ".."
    80004ba2:	04a4d783          	lhu	a5,74(s1)
    80004ba6:	2785                	addiw	a5,a5,1
    80004ba8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004bac:	8526                	mv	a0,s1
    80004bae:	df6fe0ef          	jal	800031a4 <iupdate>
    80004bb2:	bf71                	j	80004b4e <create+0xb6>
  ip->nlink = 0;
    80004bb4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80004bb8:	8552                	mv	a0,s4
    80004bba:	deafe0ef          	jal	800031a4 <iupdate>
  iunlockput(ip);
    80004bbe:	8552                	mv	a0,s4
    80004bc0:	8a3fe0ef          	jal	80003462 <iunlockput>
  iunlockput(dp);
    80004bc4:	8526                	mv	a0,s1
    80004bc6:	89dfe0ef          	jal	80003462 <iunlockput>
  return 0;
    80004bca:	7a02                	ld	s4,32(sp)
    80004bcc:	b725                	j	80004af4 <create+0x5c>
    return 0;
    80004bce:	8aaa                	mv	s5,a0
    80004bd0:	b715                	j	80004af4 <create+0x5c>

0000000080004bd2 <sys_dup>:
{
    80004bd2:	7179                	addi	sp,sp,-48
    80004bd4:	f406                	sd	ra,40(sp)
    80004bd6:	f022                	sd	s0,32(sp)
    80004bd8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80004bda:	fd840613          	addi	a2,s0,-40
    80004bde:	4581                	li	a1,0
    80004be0:	4501                	li	a0,0
    80004be2:	e21ff0ef          	jal	80004a02 <argfd>
    return -1;
    80004be6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80004be8:	02054363          	bltz	a0,80004c0e <sys_dup+0x3c>
    80004bec:	ec26                	sd	s1,24(sp)
    80004bee:	e84a                	sd	s2,16(sp)
  if((fd=fdalloc(f)) < 0)
    80004bf0:	fd843903          	ld	s2,-40(s0)
    80004bf4:	854a                	mv	a0,s2
    80004bf6:	e65ff0ef          	jal	80004a5a <fdalloc>
    80004bfa:	84aa                	mv	s1,a0
    return -1;
    80004bfc:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80004bfe:	00054d63          	bltz	a0,80004c18 <sys_dup+0x46>
  filedup(f);
    80004c02:	854a                	mv	a0,s2
    80004c04:	c24ff0ef          	jal	80004028 <filedup>
  return fd;
    80004c08:	87a6                	mv	a5,s1
    80004c0a:	64e2                	ld	s1,24(sp)
    80004c0c:	6942                	ld	s2,16(sp)
}
    80004c0e:	853e                	mv	a0,a5
    80004c10:	70a2                	ld	ra,40(sp)
    80004c12:	7402                	ld	s0,32(sp)
    80004c14:	6145                	addi	sp,sp,48
    80004c16:	8082                	ret
    80004c18:	64e2                	ld	s1,24(sp)
    80004c1a:	6942                	ld	s2,16(sp)
    80004c1c:	bfcd                	j	80004c0e <sys_dup+0x3c>

0000000080004c1e <sys_read>:
{
    80004c1e:	7179                	addi	sp,sp,-48
    80004c20:	f406                	sd	ra,40(sp)
    80004c22:	f022                	sd	s0,32(sp)
    80004c24:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c26:	fd840593          	addi	a1,s0,-40
    80004c2a:	4505                	li	a0,1
    80004c2c:	bbbfd0ef          	jal	800027e6 <argaddr>
  argint(2, &n);
    80004c30:	fe440593          	addi	a1,s0,-28
    80004c34:	4509                	li	a0,2
    80004c36:	b95fd0ef          	jal	800027ca <argint>
  if(argfd(0, 0, &f) < 0)
    80004c3a:	fe840613          	addi	a2,s0,-24
    80004c3e:	4581                	li	a1,0
    80004c40:	4501                	li	a0,0
    80004c42:	dc1ff0ef          	jal	80004a02 <argfd>
    80004c46:	87aa                	mv	a5,a0
    return -1;
    80004c48:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c4a:	0007ca63          	bltz	a5,80004c5e <sys_read+0x40>
  return fileread(f, p, n);
    80004c4e:	fe442603          	lw	a2,-28(s0)
    80004c52:	fd843583          	ld	a1,-40(s0)
    80004c56:	fe843503          	ld	a0,-24(s0)
    80004c5a:	d34ff0ef          	jal	8000418e <fileread>
}
    80004c5e:	70a2                	ld	ra,40(sp)
    80004c60:	7402                	ld	s0,32(sp)
    80004c62:	6145                	addi	sp,sp,48
    80004c64:	8082                	ret

0000000080004c66 <sys_write>:
{
    80004c66:	7179                	addi	sp,sp,-48
    80004c68:	f406                	sd	ra,40(sp)
    80004c6a:	f022                	sd	s0,32(sp)
    80004c6c:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80004c6e:	fd840593          	addi	a1,s0,-40
    80004c72:	4505                	li	a0,1
    80004c74:	b73fd0ef          	jal	800027e6 <argaddr>
  argint(2, &n);
    80004c78:	fe440593          	addi	a1,s0,-28
    80004c7c:	4509                	li	a0,2
    80004c7e:	b4dfd0ef          	jal	800027ca <argint>
  if(argfd(0, 0, &f) < 0)
    80004c82:	fe840613          	addi	a2,s0,-24
    80004c86:	4581                	li	a1,0
    80004c88:	4501                	li	a0,0
    80004c8a:	d79ff0ef          	jal	80004a02 <argfd>
    80004c8e:	87aa                	mv	a5,a0
    return -1;
    80004c90:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004c92:	0007ca63          	bltz	a5,80004ca6 <sys_write+0x40>
  return filewrite(f, p, n);
    80004c96:	fe442603          	lw	a2,-28(s0)
    80004c9a:	fd843583          	ld	a1,-40(s0)
    80004c9e:	fe843503          	ld	a0,-24(s0)
    80004ca2:	daaff0ef          	jal	8000424c <filewrite>
}
    80004ca6:	70a2                	ld	ra,40(sp)
    80004ca8:	7402                	ld	s0,32(sp)
    80004caa:	6145                	addi	sp,sp,48
    80004cac:	8082                	ret

0000000080004cae <sys_close>:
{
    80004cae:	1101                	addi	sp,sp,-32
    80004cb0:	ec06                	sd	ra,24(sp)
    80004cb2:	e822                	sd	s0,16(sp)
    80004cb4:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80004cb6:	fe040613          	addi	a2,s0,-32
    80004cba:	fec40593          	addi	a1,s0,-20
    80004cbe:	4501                	li	a0,0
    80004cc0:	d43ff0ef          	jal	80004a02 <argfd>
    return -1;
    80004cc4:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80004cc6:	02054063          	bltz	a0,80004ce6 <sys_close+0x38>
  myproc()->ofile[fd] = 0;
    80004cca:	bf5fc0ef          	jal	800018be <myproc>
    80004cce:	fec42783          	lw	a5,-20(s0)
    80004cd2:	07e9                	addi	a5,a5,26
    80004cd4:	078e                	slli	a5,a5,0x3
    80004cd6:	953e                	add	a0,a0,a5
    80004cd8:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80004cdc:	fe043503          	ld	a0,-32(s0)
    80004ce0:	b8eff0ef          	jal	8000406e <fileclose>
  return 0;
    80004ce4:	4781                	li	a5,0
}
    80004ce6:	853e                	mv	a0,a5
    80004ce8:	60e2                	ld	ra,24(sp)
    80004cea:	6442                	ld	s0,16(sp)
    80004cec:	6105                	addi	sp,sp,32
    80004cee:	8082                	ret

0000000080004cf0 <sys_fstat>:
{
    80004cf0:	1101                	addi	sp,sp,-32
    80004cf2:	ec06                	sd	ra,24(sp)
    80004cf4:	e822                	sd	s0,16(sp)
    80004cf6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80004cf8:	fe040593          	addi	a1,s0,-32
    80004cfc:	4505                	li	a0,1
    80004cfe:	ae9fd0ef          	jal	800027e6 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80004d02:	fe840613          	addi	a2,s0,-24
    80004d06:	4581                	li	a1,0
    80004d08:	4501                	li	a0,0
    80004d0a:	cf9ff0ef          	jal	80004a02 <argfd>
    80004d0e:	87aa                	mv	a5,a0
    return -1;
    80004d10:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80004d12:	0007c863          	bltz	a5,80004d22 <sys_fstat+0x32>
  return filestat(f, st);
    80004d16:	fe043583          	ld	a1,-32(s0)
    80004d1a:	fe843503          	ld	a0,-24(s0)
    80004d1e:	c0eff0ef          	jal	8000412c <filestat>
}
    80004d22:	60e2                	ld	ra,24(sp)
    80004d24:	6442                	ld	s0,16(sp)
    80004d26:	6105                	addi	sp,sp,32
    80004d28:	8082                	ret

0000000080004d2a <sys_link>:
{
    80004d2a:	7169                	addi	sp,sp,-304
    80004d2c:	f606                	sd	ra,296(sp)
    80004d2e:	f222                	sd	s0,288(sp)
    80004d30:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d32:	08000613          	li	a2,128
    80004d36:	ed040593          	addi	a1,s0,-304
    80004d3a:	4501                	li	a0,0
    80004d3c:	ac7fd0ef          	jal	80002802 <argstr>
    return -1;
    80004d40:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d42:	0c054e63          	bltz	a0,80004e1e <sys_link+0xf4>
    80004d46:	08000613          	li	a2,128
    80004d4a:	f5040593          	addi	a1,s0,-176
    80004d4e:	4505                	li	a0,1
    80004d50:	ab3fd0ef          	jal	80002802 <argstr>
    return -1;
    80004d54:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80004d56:	0c054463          	bltz	a0,80004e1e <sys_link+0xf4>
    80004d5a:	ee26                	sd	s1,280(sp)
  begin_op();
    80004d5c:	f01fe0ef          	jal	80003c5c <begin_op>
  if((ip = namei(old)) == 0){
    80004d60:	ed040513          	addi	a0,s0,-304
    80004d64:	d1ffe0ef          	jal	80003a82 <namei>
    80004d68:	84aa                	mv	s1,a0
    80004d6a:	c53d                	beqz	a0,80004dd8 <sys_link+0xae>
  ilock(ip);
    80004d6c:	cecfe0ef          	jal	80003258 <ilock>
  if(ip->type == T_DIR){
    80004d70:	04449703          	lh	a4,68(s1)
    80004d74:	4785                	li	a5,1
    80004d76:	06f70663          	beq	a4,a5,80004de2 <sys_link+0xb8>
    80004d7a:	ea4a                	sd	s2,272(sp)
  ip->nlink++;
    80004d7c:	04a4d783          	lhu	a5,74(s1)
    80004d80:	2785                	addiw	a5,a5,1
    80004d82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004d86:	8526                	mv	a0,s1
    80004d88:	c1cfe0ef          	jal	800031a4 <iupdate>
  iunlock(ip);
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	d78fe0ef          	jal	80003306 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80004d92:	fd040593          	addi	a1,s0,-48
    80004d96:	f5040513          	addi	a0,s0,-176
    80004d9a:	d03fe0ef          	jal	80003a9c <nameiparent>
    80004d9e:	892a                	mv	s2,a0
    80004da0:	cd21                	beqz	a0,80004df8 <sys_link+0xce>
  ilock(dp);
    80004da2:	cb6fe0ef          	jal	80003258 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80004da6:	00092703          	lw	a4,0(s2)
    80004daa:	409c                	lw	a5,0(s1)
    80004dac:	04f71363          	bne	a4,a5,80004df2 <sys_link+0xc8>
    80004db0:	40d0                	lw	a2,4(s1)
    80004db2:	fd040593          	addi	a1,s0,-48
    80004db6:	854a                	mv	a0,s2
    80004db8:	c21fe0ef          	jal	800039d8 <dirlink>
    80004dbc:	02054b63          	bltz	a0,80004df2 <sys_link+0xc8>
  iunlockput(dp);
    80004dc0:	854a                	mv	a0,s2
    80004dc2:	ea0fe0ef          	jal	80003462 <iunlockput>
  iput(ip);
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	e12fe0ef          	jal	800033da <iput>
  end_op();
    80004dcc:	efbfe0ef          	jal	80003cc6 <end_op>
  return 0;
    80004dd0:	4781                	li	a5,0
    80004dd2:	64f2                	ld	s1,280(sp)
    80004dd4:	6952                	ld	s2,272(sp)
    80004dd6:	a0a1                	j	80004e1e <sys_link+0xf4>
    end_op();
    80004dd8:	eeffe0ef          	jal	80003cc6 <end_op>
    return -1;
    80004ddc:	57fd                	li	a5,-1
    80004dde:	64f2                	ld	s1,280(sp)
    80004de0:	a83d                	j	80004e1e <sys_link+0xf4>
    iunlockput(ip);
    80004de2:	8526                	mv	a0,s1
    80004de4:	e7efe0ef          	jal	80003462 <iunlockput>
    end_op();
    80004de8:	edffe0ef          	jal	80003cc6 <end_op>
    return -1;
    80004dec:	57fd                	li	a5,-1
    80004dee:	64f2                	ld	s1,280(sp)
    80004df0:	a03d                	j	80004e1e <sys_link+0xf4>
    iunlockput(dp);
    80004df2:	854a                	mv	a0,s2
    80004df4:	e6efe0ef          	jal	80003462 <iunlockput>
  ilock(ip);
    80004df8:	8526                	mv	a0,s1
    80004dfa:	c5efe0ef          	jal	80003258 <ilock>
  ip->nlink--;
    80004dfe:	04a4d783          	lhu	a5,74(s1)
    80004e02:	37fd                	addiw	a5,a5,-1
    80004e04:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80004e08:	8526                	mv	a0,s1
    80004e0a:	b9afe0ef          	jal	800031a4 <iupdate>
  iunlockput(ip);
    80004e0e:	8526                	mv	a0,s1
    80004e10:	e52fe0ef          	jal	80003462 <iunlockput>
  end_op();
    80004e14:	eb3fe0ef          	jal	80003cc6 <end_op>
  return -1;
    80004e18:	57fd                	li	a5,-1
    80004e1a:	64f2                	ld	s1,280(sp)
    80004e1c:	6952                	ld	s2,272(sp)
}
    80004e1e:	853e                	mv	a0,a5
    80004e20:	70b2                	ld	ra,296(sp)
    80004e22:	7412                	ld	s0,288(sp)
    80004e24:	6155                	addi	sp,sp,304
    80004e26:	8082                	ret

0000000080004e28 <sys_unlink>:
{
    80004e28:	7111                	addi	sp,sp,-256
    80004e2a:	fd86                	sd	ra,248(sp)
    80004e2c:	f9a2                	sd	s0,240(sp)
    80004e2e:	0200                	addi	s0,sp,256
  if(argstr(0, path, MAXPATH) < 0)
    80004e30:	08000613          	li	a2,128
    80004e34:	f2040593          	addi	a1,s0,-224
    80004e38:	4501                	li	a0,0
    80004e3a:	9c9fd0ef          	jal	80002802 <argstr>
    80004e3e:	16054663          	bltz	a0,80004faa <sys_unlink+0x182>
    80004e42:	f5a6                	sd	s1,232(sp)
  begin_op();
    80004e44:	e19fe0ef          	jal	80003c5c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80004e48:	fa040593          	addi	a1,s0,-96
    80004e4c:	f2040513          	addi	a0,s0,-224
    80004e50:	c4dfe0ef          	jal	80003a9c <nameiparent>
    80004e54:	84aa                	mv	s1,a0
    80004e56:	c955                	beqz	a0,80004f0a <sys_unlink+0xe2>
  ilock(dp);
    80004e58:	c00fe0ef          	jal	80003258 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80004e5c:	00002597          	auipc	a1,0x2
    80004e60:	76458593          	addi	a1,a1,1892 # 800075c0 <etext+0x5c0>
    80004e64:	fa040513          	addi	a0,s0,-96
    80004e68:	979fe0ef          	jal	800037e0 <namecmp>
    80004e6c:	12050463          	beqz	a0,80004f94 <sys_unlink+0x16c>
    80004e70:	00002597          	auipc	a1,0x2
    80004e74:	75858593          	addi	a1,a1,1880 # 800075c8 <etext+0x5c8>
    80004e78:	fa040513          	addi	a0,s0,-96
    80004e7c:	965fe0ef          	jal	800037e0 <namecmp>
    80004e80:	10050a63          	beqz	a0,80004f94 <sys_unlink+0x16c>
    80004e84:	f1ca                	sd	s2,224(sp)
  if((ip = dirlookup(dp, name, &off)) == 0)
    80004e86:	f1c40613          	addi	a2,s0,-228
    80004e8a:	fa040593          	addi	a1,s0,-96
    80004e8e:	8526                	mv	a0,s1
    80004e90:	967fe0ef          	jal	800037f6 <dirlookup>
    80004e94:	892a                	mv	s2,a0
    80004e96:	0e050e63          	beqz	a0,80004f92 <sys_unlink+0x16a>
    80004e9a:	edce                	sd	s3,216(sp)
  ilock(ip);
    80004e9c:	bbcfe0ef          	jal	80003258 <ilock>
  if(ip->nlink < 1)
    80004ea0:	04a91783          	lh	a5,74(s2)
    80004ea4:	06f05863          	blez	a5,80004f14 <sys_unlink+0xec>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80004ea8:	04491703          	lh	a4,68(s2)
    80004eac:	4785                	li	a5,1
    80004eae:	06f70b63          	beq	a4,a5,80004f24 <sys_unlink+0xfc>
  memset(&de, 0, sizeof(de));
    80004eb2:	fb040993          	addi	s3,s0,-80
    80004eb6:	4641                	li	a2,16
    80004eb8:	4581                	li	a1,0
    80004eba:	854e                	mv	a0,s3
    80004ebc:	de1fb0ef          	jal	80000c9c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004ec0:	4741                	li	a4,16
    80004ec2:	f1c42683          	lw	a3,-228(s0)
    80004ec6:	864e                	mv	a2,s3
    80004ec8:	4581                	li	a1,0
    80004eca:	8526                	mv	a0,s1
    80004ecc:	811fe0ef          	jal	800036dc <writei>
    80004ed0:	47c1                	li	a5,16
    80004ed2:	08f51f63          	bne	a0,a5,80004f70 <sys_unlink+0x148>
  if(ip->type == T_DIR){
    80004ed6:	04491703          	lh	a4,68(s2)
    80004eda:	4785                	li	a5,1
    80004edc:	0af70263          	beq	a4,a5,80004f80 <sys_unlink+0x158>
  iunlockput(dp);
    80004ee0:	8526                	mv	a0,s1
    80004ee2:	d80fe0ef          	jal	80003462 <iunlockput>
  ip->nlink--;
    80004ee6:	04a95783          	lhu	a5,74(s2)
    80004eea:	37fd                	addiw	a5,a5,-1
    80004eec:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80004ef0:	854a                	mv	a0,s2
    80004ef2:	ab2fe0ef          	jal	800031a4 <iupdate>
  iunlockput(ip);
    80004ef6:	854a                	mv	a0,s2
    80004ef8:	d6afe0ef          	jal	80003462 <iunlockput>
  end_op();
    80004efc:	dcbfe0ef          	jal	80003cc6 <end_op>
  return 0;
    80004f00:	4501                	li	a0,0
    80004f02:	74ae                	ld	s1,232(sp)
    80004f04:	790e                	ld	s2,224(sp)
    80004f06:	69ee                	ld	s3,216(sp)
    80004f08:	a869                	j	80004fa2 <sys_unlink+0x17a>
    end_op();
    80004f0a:	dbdfe0ef          	jal	80003cc6 <end_op>
    return -1;
    80004f0e:	557d                	li	a0,-1
    80004f10:	74ae                	ld	s1,232(sp)
    80004f12:	a841                	j	80004fa2 <sys_unlink+0x17a>
    80004f14:	e9d2                	sd	s4,208(sp)
    80004f16:	e5d6                	sd	s5,200(sp)
    panic("unlink: nlink < 1");
    80004f18:	00002517          	auipc	a0,0x2
    80004f1c:	6b850513          	addi	a0,a0,1720 # 800075d0 <etext+0x5d0>
    80004f20:	8bffb0ef          	jal	800007de <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f24:	04c92703          	lw	a4,76(s2)
    80004f28:	02000793          	li	a5,32
    80004f2c:	f8e7f3e3          	bgeu	a5,a4,80004eb2 <sys_unlink+0x8a>
    80004f30:	e9d2                	sd	s4,208(sp)
    80004f32:	e5d6                	sd	s5,200(sp)
    80004f34:	89be                	mv	s3,a5
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004f36:	f0840a93          	addi	s5,s0,-248
    80004f3a:	4a41                	li	s4,16
    80004f3c:	8752                	mv	a4,s4
    80004f3e:	86ce                	mv	a3,s3
    80004f40:	8656                	mv	a2,s5
    80004f42:	4581                	li	a1,0
    80004f44:	854a                	mv	a0,s2
    80004f46:	ea4fe0ef          	jal	800035ea <readi>
    80004f4a:	01451d63          	bne	a0,s4,80004f64 <sys_unlink+0x13c>
    if(de.inum != 0)
    80004f4e:	f0845783          	lhu	a5,-248(s0)
    80004f52:	efb1                	bnez	a5,80004fae <sys_unlink+0x186>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80004f54:	29c1                	addiw	s3,s3,16
    80004f56:	04c92783          	lw	a5,76(s2)
    80004f5a:	fef9e1e3          	bltu	s3,a5,80004f3c <sys_unlink+0x114>
    80004f5e:	6a4e                	ld	s4,208(sp)
    80004f60:	6aae                	ld	s5,200(sp)
    80004f62:	bf81                	j	80004eb2 <sys_unlink+0x8a>
      panic("isdirempty: readi");
    80004f64:	00002517          	auipc	a0,0x2
    80004f68:	68450513          	addi	a0,a0,1668 # 800075e8 <etext+0x5e8>
    80004f6c:	873fb0ef          	jal	800007de <panic>
    80004f70:	e9d2                	sd	s4,208(sp)
    80004f72:	e5d6                	sd	s5,200(sp)
    panic("unlink: writei");
    80004f74:	00002517          	auipc	a0,0x2
    80004f78:	68c50513          	addi	a0,a0,1676 # 80007600 <etext+0x600>
    80004f7c:	863fb0ef          	jal	800007de <panic>
    dp->nlink--;
    80004f80:	04a4d783          	lhu	a5,74(s1)
    80004f84:	37fd                	addiw	a5,a5,-1
    80004f86:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80004f8a:	8526                	mv	a0,s1
    80004f8c:	a18fe0ef          	jal	800031a4 <iupdate>
    80004f90:	bf81                	j	80004ee0 <sys_unlink+0xb8>
    80004f92:	790e                	ld	s2,224(sp)
  iunlockput(dp);
    80004f94:	8526                	mv	a0,s1
    80004f96:	cccfe0ef          	jal	80003462 <iunlockput>
  end_op();
    80004f9a:	d2dfe0ef          	jal	80003cc6 <end_op>
  return -1;
    80004f9e:	557d                	li	a0,-1
    80004fa0:	74ae                	ld	s1,232(sp)
}
    80004fa2:	70ee                	ld	ra,248(sp)
    80004fa4:	744e                	ld	s0,240(sp)
    80004fa6:	6111                	addi	sp,sp,256
    80004fa8:	8082                	ret
    return -1;
    80004faa:	557d                	li	a0,-1
    80004fac:	bfdd                	j	80004fa2 <sys_unlink+0x17a>
    iunlockput(ip);
    80004fae:	854a                	mv	a0,s2
    80004fb0:	cb2fe0ef          	jal	80003462 <iunlockput>
    goto bad;
    80004fb4:	790e                	ld	s2,224(sp)
    80004fb6:	69ee                	ld	s3,216(sp)
    80004fb8:	6a4e                	ld	s4,208(sp)
    80004fba:	6aae                	ld	s5,200(sp)
    80004fbc:	bfe1                	j	80004f94 <sys_unlink+0x16c>

0000000080004fbe <sys_open>:

uint64
sys_open(void)
{
    80004fbe:	7131                	addi	sp,sp,-192
    80004fc0:	fd06                	sd	ra,184(sp)
    80004fc2:	f922                	sd	s0,176(sp)
    80004fc4:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80004fc6:	f4c40593          	addi	a1,s0,-180
    80004fca:	4505                	li	a0,1
    80004fcc:	ffefd0ef          	jal	800027ca <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004fd0:	08000613          	li	a2,128
    80004fd4:	f5040593          	addi	a1,s0,-176
    80004fd8:	4501                	li	a0,0
    80004fda:	829fd0ef          	jal	80002802 <argstr>
    80004fde:	87aa                	mv	a5,a0
    return -1;
    80004fe0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80004fe2:	0a07c363          	bltz	a5,80005088 <sys_open+0xca>
    80004fe6:	f526                	sd	s1,168(sp)

  begin_op();
    80004fe8:	c75fe0ef          	jal	80003c5c <begin_op>

  if(omode & O_CREATE){
    80004fec:	f4c42783          	lw	a5,-180(s0)
    80004ff0:	2007f793          	andi	a5,a5,512
    80004ff4:	c3dd                	beqz	a5,8000509a <sys_open+0xdc>
    ip = create(path, T_FILE, 0, 0);
    80004ff6:	4681                	li	a3,0
    80004ff8:	4601                	li	a2,0
    80004ffa:	4589                	li	a1,2
    80004ffc:	f5040513          	addi	a0,s0,-176
    80005000:	a99ff0ef          	jal	80004a98 <create>
    80005004:	84aa                	mv	s1,a0
    if(ip == 0){
    80005006:	c549                	beqz	a0,80005090 <sys_open+0xd2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005008:	04449703          	lh	a4,68(s1)
    8000500c:	478d                	li	a5,3
    8000500e:	00f71763          	bne	a4,a5,8000501c <sys_open+0x5e>
    80005012:	0464d703          	lhu	a4,70(s1)
    80005016:	47a5                	li	a5,9
    80005018:	0ae7ee63          	bltu	a5,a4,800050d4 <sys_open+0x116>
    8000501c:	f14a                	sd	s2,160(sp)
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000501e:	fadfe0ef          	jal	80003fca <filealloc>
    80005022:	892a                	mv	s2,a0
    80005024:	c561                	beqz	a0,800050ec <sys_open+0x12e>
    80005026:	ed4e                	sd	s3,152(sp)
    80005028:	a33ff0ef          	jal	80004a5a <fdalloc>
    8000502c:	89aa                	mv	s3,a0
    8000502e:	0a054b63          	bltz	a0,800050e4 <sys_open+0x126>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005032:	04449703          	lh	a4,68(s1)
    80005036:	478d                	li	a5,3
    80005038:	0cf70363          	beq	a4,a5,800050fe <sys_open+0x140>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000503c:	4789                	li	a5,2
    8000503e:	00f92023          	sw	a5,0(s2)
    f->off = 0;
    80005042:	02092023          	sw	zero,32(s2)
  }
  f->ip = ip;
    80005046:	00993c23          	sd	s1,24(s2)
  f->readable = !(omode & O_WRONLY);
    8000504a:	f4c42783          	lw	a5,-180(s0)
    8000504e:	0017f713          	andi	a4,a5,1
    80005052:	00174713          	xori	a4,a4,1
    80005056:	00e90423          	sb	a4,8(s2)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    8000505a:	0037f713          	andi	a4,a5,3
    8000505e:	00e03733          	snez	a4,a4
    80005062:	00e904a3          	sb	a4,9(s2)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005066:	4007f793          	andi	a5,a5,1024
    8000506a:	c791                	beqz	a5,80005076 <sys_open+0xb8>
    8000506c:	04449703          	lh	a4,68(s1)
    80005070:	4789                	li	a5,2
    80005072:	08f70d63          	beq	a4,a5,8000510c <sys_open+0x14e>
    itrunc(ip);
  }

  iunlock(ip);
    80005076:	8526                	mv	a0,s1
    80005078:	a8efe0ef          	jal	80003306 <iunlock>
  end_op();
    8000507c:	c4bfe0ef          	jal	80003cc6 <end_op>

  return fd;
    80005080:	854e                	mv	a0,s3
    80005082:	74aa                	ld	s1,168(sp)
    80005084:	790a                	ld	s2,160(sp)
    80005086:	69ea                	ld	s3,152(sp)
}
    80005088:	70ea                	ld	ra,184(sp)
    8000508a:	744a                	ld	s0,176(sp)
    8000508c:	6129                	addi	sp,sp,192
    8000508e:	8082                	ret
      end_op();
    80005090:	c37fe0ef          	jal	80003cc6 <end_op>
      return -1;
    80005094:	557d                	li	a0,-1
    80005096:	74aa                	ld	s1,168(sp)
    80005098:	bfc5                	j	80005088 <sys_open+0xca>
    if((ip = namei(path)) == 0){
    8000509a:	f5040513          	addi	a0,s0,-176
    8000509e:	9e5fe0ef          	jal	80003a82 <namei>
    800050a2:	84aa                	mv	s1,a0
    800050a4:	c11d                	beqz	a0,800050ca <sys_open+0x10c>
    ilock(ip);
    800050a6:	9b2fe0ef          	jal	80003258 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800050aa:	04449703          	lh	a4,68(s1)
    800050ae:	4785                	li	a5,1
    800050b0:	f4f71ce3          	bne	a4,a5,80005008 <sys_open+0x4a>
    800050b4:	f4c42783          	lw	a5,-180(s0)
    800050b8:	d3b5                	beqz	a5,8000501c <sys_open+0x5e>
      iunlockput(ip);
    800050ba:	8526                	mv	a0,s1
    800050bc:	ba6fe0ef          	jal	80003462 <iunlockput>
      end_op();
    800050c0:	c07fe0ef          	jal	80003cc6 <end_op>
      return -1;
    800050c4:	557d                	li	a0,-1
    800050c6:	74aa                	ld	s1,168(sp)
    800050c8:	b7c1                	j	80005088 <sys_open+0xca>
      end_op();
    800050ca:	bfdfe0ef          	jal	80003cc6 <end_op>
      return -1;
    800050ce:	557d                	li	a0,-1
    800050d0:	74aa                	ld	s1,168(sp)
    800050d2:	bf5d                	j	80005088 <sys_open+0xca>
    iunlockput(ip);
    800050d4:	8526                	mv	a0,s1
    800050d6:	b8cfe0ef          	jal	80003462 <iunlockput>
    end_op();
    800050da:	bedfe0ef          	jal	80003cc6 <end_op>
    return -1;
    800050de:	557d                	li	a0,-1
    800050e0:	74aa                	ld	s1,168(sp)
    800050e2:	b75d                	j	80005088 <sys_open+0xca>
      fileclose(f);
    800050e4:	854a                	mv	a0,s2
    800050e6:	f89fe0ef          	jal	8000406e <fileclose>
    800050ea:	69ea                	ld	s3,152(sp)
    iunlockput(ip);
    800050ec:	8526                	mv	a0,s1
    800050ee:	b74fe0ef          	jal	80003462 <iunlockput>
    end_op();
    800050f2:	bd5fe0ef          	jal	80003cc6 <end_op>
    return -1;
    800050f6:	557d                	li	a0,-1
    800050f8:	74aa                	ld	s1,168(sp)
    800050fa:	790a                	ld	s2,160(sp)
    800050fc:	b771                	j	80005088 <sys_open+0xca>
    f->type = FD_DEVICE;
    800050fe:	00f92023          	sw	a5,0(s2)
    f->major = ip->major;
    80005102:	04649783          	lh	a5,70(s1)
    80005106:	02f91223          	sh	a5,36(s2)
    8000510a:	bf35                	j	80005046 <sys_open+0x88>
    itrunc(ip);
    8000510c:	8526                	mv	a0,s1
    8000510e:	a38fe0ef          	jal	80003346 <itrunc>
    80005112:	b795                	j	80005076 <sys_open+0xb8>

0000000080005114 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005114:	7175                	addi	sp,sp,-144
    80005116:	e506                	sd	ra,136(sp)
    80005118:	e122                	sd	s0,128(sp)
    8000511a:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000511c:	b41fe0ef          	jal	80003c5c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005120:	08000613          	li	a2,128
    80005124:	f7040593          	addi	a1,s0,-144
    80005128:	4501                	li	a0,0
    8000512a:	ed8fd0ef          	jal	80002802 <argstr>
    8000512e:	02054363          	bltz	a0,80005154 <sys_mkdir+0x40>
    80005132:	4681                	li	a3,0
    80005134:	4601                	li	a2,0
    80005136:	4585                	li	a1,1
    80005138:	f7040513          	addi	a0,s0,-144
    8000513c:	95dff0ef          	jal	80004a98 <create>
    80005140:	c911                	beqz	a0,80005154 <sys_mkdir+0x40>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005142:	b20fe0ef          	jal	80003462 <iunlockput>
  end_op();
    80005146:	b81fe0ef          	jal	80003cc6 <end_op>
  return 0;
    8000514a:	4501                	li	a0,0
}
    8000514c:	60aa                	ld	ra,136(sp)
    8000514e:	640a                	ld	s0,128(sp)
    80005150:	6149                	addi	sp,sp,144
    80005152:	8082                	ret
    end_op();
    80005154:	b73fe0ef          	jal	80003cc6 <end_op>
    return -1;
    80005158:	557d                	li	a0,-1
    8000515a:	bfcd                	j	8000514c <sys_mkdir+0x38>

000000008000515c <sys_mknod>:

uint64
sys_mknod(void)
{
    8000515c:	7135                	addi	sp,sp,-160
    8000515e:	ed06                	sd	ra,152(sp)
    80005160:	e922                	sd	s0,144(sp)
    80005162:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005164:	af9fe0ef          	jal	80003c5c <begin_op>
  argint(1, &major);
    80005168:	f6c40593          	addi	a1,s0,-148
    8000516c:	4505                	li	a0,1
    8000516e:	e5cfd0ef          	jal	800027ca <argint>
  argint(2, &minor);
    80005172:	f6840593          	addi	a1,s0,-152
    80005176:	4509                	li	a0,2
    80005178:	e52fd0ef          	jal	800027ca <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000517c:	08000613          	li	a2,128
    80005180:	f7040593          	addi	a1,s0,-144
    80005184:	4501                	li	a0,0
    80005186:	e7cfd0ef          	jal	80002802 <argstr>
    8000518a:	02054563          	bltz	a0,800051b4 <sys_mknod+0x58>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000518e:	f6841683          	lh	a3,-152(s0)
    80005192:	f6c41603          	lh	a2,-148(s0)
    80005196:	458d                	li	a1,3
    80005198:	f7040513          	addi	a0,s0,-144
    8000519c:	8fdff0ef          	jal	80004a98 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800051a0:	c911                	beqz	a0,800051b4 <sys_mknod+0x58>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800051a2:	ac0fe0ef          	jal	80003462 <iunlockput>
  end_op();
    800051a6:	b21fe0ef          	jal	80003cc6 <end_op>
  return 0;
    800051aa:	4501                	li	a0,0
}
    800051ac:	60ea                	ld	ra,152(sp)
    800051ae:	644a                	ld	s0,144(sp)
    800051b0:	610d                	addi	sp,sp,160
    800051b2:	8082                	ret
    end_op();
    800051b4:	b13fe0ef          	jal	80003cc6 <end_op>
    return -1;
    800051b8:	557d                	li	a0,-1
    800051ba:	bfcd                	j	800051ac <sys_mknod+0x50>

00000000800051bc <sys_chdir>:

uint64
sys_chdir(void)
{
    800051bc:	7135                	addi	sp,sp,-160
    800051be:	ed06                	sd	ra,152(sp)
    800051c0:	e922                	sd	s0,144(sp)
    800051c2:	e14a                	sd	s2,128(sp)
    800051c4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800051c6:	ef8fc0ef          	jal	800018be <myproc>
    800051ca:	892a                	mv	s2,a0
  
  begin_op();
    800051cc:	a91fe0ef          	jal	80003c5c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800051d0:	08000613          	li	a2,128
    800051d4:	f6040593          	addi	a1,s0,-160
    800051d8:	4501                	li	a0,0
    800051da:	e28fd0ef          	jal	80002802 <argstr>
    800051de:	04054363          	bltz	a0,80005224 <sys_chdir+0x68>
    800051e2:	e526                	sd	s1,136(sp)
    800051e4:	f6040513          	addi	a0,s0,-160
    800051e8:	89bfe0ef          	jal	80003a82 <namei>
    800051ec:	84aa                	mv	s1,a0
    800051ee:	c915                	beqz	a0,80005222 <sys_chdir+0x66>
    end_op();
    return -1;
  }
  ilock(ip);
    800051f0:	868fe0ef          	jal	80003258 <ilock>
  if(ip->type != T_DIR){
    800051f4:	04449703          	lh	a4,68(s1)
    800051f8:	4785                	li	a5,1
    800051fa:	02f71963          	bne	a4,a5,8000522c <sys_chdir+0x70>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800051fe:	8526                	mv	a0,s1
    80005200:	906fe0ef          	jal	80003306 <iunlock>
  iput(p->cwd);
    80005204:	15093503          	ld	a0,336(s2)
    80005208:	9d2fe0ef          	jal	800033da <iput>
  end_op();
    8000520c:	abbfe0ef          	jal	80003cc6 <end_op>
  p->cwd = ip;
    80005210:	14993823          	sd	s1,336(s2)
  return 0;
    80005214:	4501                	li	a0,0
    80005216:	64aa                	ld	s1,136(sp)
}
    80005218:	60ea                	ld	ra,152(sp)
    8000521a:	644a                	ld	s0,144(sp)
    8000521c:	690a                	ld	s2,128(sp)
    8000521e:	610d                	addi	sp,sp,160
    80005220:	8082                	ret
    80005222:	64aa                	ld	s1,136(sp)
    end_op();
    80005224:	aa3fe0ef          	jal	80003cc6 <end_op>
    return -1;
    80005228:	557d                	li	a0,-1
    8000522a:	b7fd                	j	80005218 <sys_chdir+0x5c>
    iunlockput(ip);
    8000522c:	8526                	mv	a0,s1
    8000522e:	a34fe0ef          	jal	80003462 <iunlockput>
    end_op();
    80005232:	a95fe0ef          	jal	80003cc6 <end_op>
    return -1;
    80005236:	557d                	li	a0,-1
    80005238:	64aa                	ld	s1,136(sp)
    8000523a:	bff9                	j	80005218 <sys_chdir+0x5c>

000000008000523c <sys_exec>:

uint64
sys_exec(void)
{
    8000523c:	7105                	addi	sp,sp,-480
    8000523e:	ef86                	sd	ra,472(sp)
    80005240:	eba2                	sd	s0,464(sp)
    80005242:	1380                	addi	s0,sp,480
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005244:	e2840593          	addi	a1,s0,-472
    80005248:	4505                	li	a0,1
    8000524a:	d9cfd0ef          	jal	800027e6 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000524e:	08000613          	li	a2,128
    80005252:	f3040593          	addi	a1,s0,-208
    80005256:	4501                	li	a0,0
    80005258:	daafd0ef          	jal	80002802 <argstr>
    8000525c:	87aa                	mv	a5,a0
    return -1;
    8000525e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005260:	0e07c063          	bltz	a5,80005340 <sys_exec+0x104>
    80005264:	e7a6                	sd	s1,456(sp)
    80005266:	e3ca                	sd	s2,448(sp)
    80005268:	ff4e                	sd	s3,440(sp)
    8000526a:	fb52                	sd	s4,432(sp)
    8000526c:	f756                	sd	s5,424(sp)
    8000526e:	f35a                	sd	s6,416(sp)
    80005270:	ef5e                	sd	s7,408(sp)
  }
  memset(argv, 0, sizeof(argv));
    80005272:	e3040a13          	addi	s4,s0,-464
    80005276:	10000613          	li	a2,256
    8000527a:	4581                	li	a1,0
    8000527c:	8552                	mv	a0,s4
    8000527e:	a1ffb0ef          	jal	80000c9c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005282:	84d2                	mv	s1,s4
  memset(argv, 0, sizeof(argv));
    80005284:	89d2                	mv	s3,s4
    80005286:	4901                	li	s2,0
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005288:	e2040a93          	addi	s5,s0,-480
      break;
    }
    argv[i] = kalloc();
    if(argv[i] == 0)
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000528c:	6b05                	lui	s6,0x1
    if(i >= NELEM(argv)){
    8000528e:	02000b93          	li	s7,32
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005292:	00391513          	slli	a0,s2,0x3
    80005296:	85d6                	mv	a1,s5
    80005298:	e2843783          	ld	a5,-472(s0)
    8000529c:	953e                	add	a0,a0,a5
    8000529e:	ca2fd0ef          	jal	80002740 <fetchaddr>
    800052a2:	02054663          	bltz	a0,800052ce <sys_exec+0x92>
    if(uarg == 0){
    800052a6:	e2043783          	ld	a5,-480(s0)
    800052aa:	c7a1                	beqz	a5,800052f2 <sys_exec+0xb6>
    argv[i] = kalloc();
    800052ac:	84dfb0ef          	jal	80000af8 <kalloc>
    800052b0:	85aa                	mv	a1,a0
    800052b2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800052b6:	cd01                	beqz	a0,800052ce <sys_exec+0x92>
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800052b8:	865a                	mv	a2,s6
    800052ba:	e2043503          	ld	a0,-480(s0)
    800052be:	cccfd0ef          	jal	8000278a <fetchstr>
    800052c2:	00054663          	bltz	a0,800052ce <sys_exec+0x92>
    if(i >= NELEM(argv)){
    800052c6:	0905                	addi	s2,s2,1
    800052c8:	09a1                	addi	s3,s3,8
    800052ca:	fd7914e3          	bne	s2,s7,80005292 <sys_exec+0x56>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052ce:	100a0a13          	addi	s4,s4,256
    800052d2:	6088                	ld	a0,0(s1)
    800052d4:	cd31                	beqz	a0,80005330 <sys_exec+0xf4>
    kfree(argv[i]);
    800052d6:	f40fb0ef          	jal	80000a16 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800052da:	04a1                	addi	s1,s1,8
    800052dc:	ff449be3          	bne	s1,s4,800052d2 <sys_exec+0x96>
  return -1;
    800052e0:	557d                	li	a0,-1
    800052e2:	64be                	ld	s1,456(sp)
    800052e4:	691e                	ld	s2,448(sp)
    800052e6:	79fa                	ld	s3,440(sp)
    800052e8:	7a5a                	ld	s4,432(sp)
    800052ea:	7aba                	ld	s5,424(sp)
    800052ec:	7b1a                	ld	s6,416(sp)
    800052ee:	6bfa                	ld	s7,408(sp)
    800052f0:	a881                	j	80005340 <sys_exec+0x104>
      argv[i] = 0;
    800052f2:	0009079b          	sext.w	a5,s2
    800052f6:	e3040593          	addi	a1,s0,-464
    800052fa:	078e                	slli	a5,a5,0x3
    800052fc:	97ae                	add	a5,a5,a1
    800052fe:	0007b023          	sd	zero,0(a5)
  int ret = kexec(path, argv);
    80005302:	f3040513          	addi	a0,s0,-208
    80005306:	ba4ff0ef          	jal	800046aa <kexec>
    8000530a:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000530c:	100a0a13          	addi	s4,s4,256
    80005310:	6088                	ld	a0,0(s1)
    80005312:	c511                	beqz	a0,8000531e <sys_exec+0xe2>
    kfree(argv[i]);
    80005314:	f02fb0ef          	jal	80000a16 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005318:	04a1                	addi	s1,s1,8
    8000531a:	ff449be3          	bne	s1,s4,80005310 <sys_exec+0xd4>
  return ret;
    8000531e:	854a                	mv	a0,s2
    80005320:	64be                	ld	s1,456(sp)
    80005322:	691e                	ld	s2,448(sp)
    80005324:	79fa                	ld	s3,440(sp)
    80005326:	7a5a                	ld	s4,432(sp)
    80005328:	7aba                	ld	s5,424(sp)
    8000532a:	7b1a                	ld	s6,416(sp)
    8000532c:	6bfa                	ld	s7,408(sp)
    8000532e:	a809                	j	80005340 <sys_exec+0x104>
  return -1;
    80005330:	557d                	li	a0,-1
    80005332:	64be                	ld	s1,456(sp)
    80005334:	691e                	ld	s2,448(sp)
    80005336:	79fa                	ld	s3,440(sp)
    80005338:	7a5a                	ld	s4,432(sp)
    8000533a:	7aba                	ld	s5,424(sp)
    8000533c:	7b1a                	ld	s6,416(sp)
    8000533e:	6bfa                	ld	s7,408(sp)
}
    80005340:	60fe                	ld	ra,472(sp)
    80005342:	645e                	ld	s0,464(sp)
    80005344:	613d                	addi	sp,sp,480
    80005346:	8082                	ret

0000000080005348 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005348:	7139                	addi	sp,sp,-64
    8000534a:	fc06                	sd	ra,56(sp)
    8000534c:	f822                	sd	s0,48(sp)
    8000534e:	f426                	sd	s1,40(sp)
    80005350:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005352:	d6cfc0ef          	jal	800018be <myproc>
    80005356:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005358:	fd840593          	addi	a1,s0,-40
    8000535c:	4501                	li	a0,0
    8000535e:	c88fd0ef          	jal	800027e6 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005362:	fc840593          	addi	a1,s0,-56
    80005366:	fd040513          	addi	a0,s0,-48
    8000536a:	814ff0ef          	jal	8000437e <pipealloc>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005370:	0a054463          	bltz	a0,80005418 <sys_pipe+0xd0>
  fd0 = -1;
    80005374:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005378:	fd043503          	ld	a0,-48(s0)
    8000537c:	edeff0ef          	jal	80004a5a <fdalloc>
    80005380:	fca42223          	sw	a0,-60(s0)
    80005384:	08054163          	bltz	a0,80005406 <sys_pipe+0xbe>
    80005388:	fc843503          	ld	a0,-56(s0)
    8000538c:	eceff0ef          	jal	80004a5a <fdalloc>
    80005390:	fca42023          	sw	a0,-64(s0)
    80005394:	06054063          	bltz	a0,800053f4 <sys_pipe+0xac>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005398:	4691                	li	a3,4
    8000539a:	fc440613          	addi	a2,s0,-60
    8000539e:	fd843583          	ld	a1,-40(s0)
    800053a2:	68a8                	ld	a0,80(s1)
    800053a4:	a4cfc0ef          	jal	800015f0 <copyout>
    800053a8:	00054e63          	bltz	a0,800053c4 <sys_pipe+0x7c>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800053ac:	4691                	li	a3,4
    800053ae:	fc040613          	addi	a2,s0,-64
    800053b2:	fd843583          	ld	a1,-40(s0)
    800053b6:	95b6                	add	a1,a1,a3
    800053b8:	68a8                	ld	a0,80(s1)
    800053ba:	a36fc0ef          	jal	800015f0 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    800053be:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800053c0:	04055c63          	bgez	a0,80005418 <sys_pipe+0xd0>
    p->ofile[fd0] = 0;
    800053c4:	fc442783          	lw	a5,-60(s0)
    800053c8:	07e9                	addi	a5,a5,26
    800053ca:	078e                	slli	a5,a5,0x3
    800053cc:	97a6                	add	a5,a5,s1
    800053ce:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    800053d2:	fc042783          	lw	a5,-64(s0)
    800053d6:	07e9                	addi	a5,a5,26
    800053d8:	078e                	slli	a5,a5,0x3
    800053da:	94be                	add	s1,s1,a5
    800053dc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    800053e0:	fd043503          	ld	a0,-48(s0)
    800053e4:	c8bfe0ef          	jal	8000406e <fileclose>
    fileclose(wf);
    800053e8:	fc843503          	ld	a0,-56(s0)
    800053ec:	c83fe0ef          	jal	8000406e <fileclose>
    return -1;
    800053f0:	57fd                	li	a5,-1
    800053f2:	a01d                	j	80005418 <sys_pipe+0xd0>
    if(fd0 >= 0)
    800053f4:	fc442783          	lw	a5,-60(s0)
    800053f8:	0007c763          	bltz	a5,80005406 <sys_pipe+0xbe>
      p->ofile[fd0] = 0;
    800053fc:	07e9                	addi	a5,a5,26
    800053fe:	078e                	slli	a5,a5,0x3
    80005400:	97a6                	add	a5,a5,s1
    80005402:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005406:	fd043503          	ld	a0,-48(s0)
    8000540a:	c65fe0ef          	jal	8000406e <fileclose>
    fileclose(wf);
    8000540e:	fc843503          	ld	a0,-56(s0)
    80005412:	c5dfe0ef          	jal	8000406e <fileclose>
    return -1;
    80005416:	57fd                	li	a5,-1
}
    80005418:	853e                	mv	a0,a5
    8000541a:	70e2                	ld	ra,56(sp)
    8000541c:	7442                	ld	s0,48(sp)
    8000541e:	74a2                	ld	s1,40(sp)
    80005420:	6121                	addi	sp,sp,64
    80005422:	8082                	ret
	...

0000000080005430 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        # make room to save registers.
        addi sp, sp, -256
    80005430:	7111                	addi	sp,sp,-256

        # save caller-saved registers.
        sd ra, 0(sp)
    80005432:	e006                	sd	ra,0(sp)
        # sd sp, 8(sp)
        sd gp, 16(sp)
    80005434:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80005436:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    80005438:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000543a:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000543c:	f81e                	sd	t2,48(sp)
        sd a0, 72(sp)
    8000543e:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80005440:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80005442:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    80005444:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    80005446:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    80005448:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    8000544a:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    8000544c:	e146                	sd	a7,128(sp)
        sd t3, 216(sp)
    8000544e:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    80005450:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    80005452:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    80005454:	f9fe                	sd	t6,240(sp)

        # call the C trap handler in trap.c
        call kerneltrap
    80005456:	9fafd0ef          	jal	80002650 <kerneltrap>

        # restore registers.
        ld ra, 0(sp)
    8000545a:	6082                	ld	ra,0(sp)
        # ld sp, 8(sp)
        ld gp, 16(sp)
    8000545c:	61c2                	ld	gp,16(sp)
        # not tp (contains hartid), in case we moved CPUs
        ld t0, 32(sp)
    8000545e:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    80005460:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    80005462:	73c2                	ld	t2,48(sp)
        ld a0, 72(sp)
    80005464:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    80005466:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    80005468:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    8000546a:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    8000546c:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    8000546e:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    80005470:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    80005472:	688a                	ld	a7,128(sp)
        ld t3, 216(sp)
    80005474:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    80005476:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    80005478:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    8000547a:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    8000547c:	6111                	addi	sp,sp,256

        # return to whatever we were doing in the kernel.
        sret
    8000547e:	10200073          	sret
    80005482:	00000013          	nop
    80005486:	00000013          	nop
    8000548a:	00000013          	nop

000000008000548e <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000548e:	1141                	addi	sp,sp,-16
    80005490:	e406                	sd	ra,8(sp)
    80005492:	e022                	sd	s0,0(sp)
    80005494:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005496:	0c000737          	lui	a4,0xc000
    8000549a:	4785                	li	a5,1
    8000549c:	d71c                	sw	a5,40(a4)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    8000549e:	c35c                	sw	a5,4(a4)
}
    800054a0:	60a2                	ld	ra,8(sp)
    800054a2:	6402                	ld	s0,0(sp)
    800054a4:	0141                	addi	sp,sp,16
    800054a6:	8082                	ret

00000000800054a8 <plicinithart>:

void
plicinithart(void)
{
    800054a8:	1141                	addi	sp,sp,-16
    800054aa:	e406                	sd	ra,8(sp)
    800054ac:	e022                	sd	s0,0(sp)
    800054ae:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054b0:	bdafc0ef          	jal	8000188a <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800054b4:	0085171b          	slliw	a4,a0,0x8
    800054b8:	0c0027b7          	lui	a5,0xc002
    800054bc:	97ba                	add	a5,a5,a4
    800054be:	40200713          	li	a4,1026
    800054c2:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800054c6:	00d5151b          	slliw	a0,a0,0xd
    800054ca:	0c2017b7          	lui	a5,0xc201
    800054ce:	97aa                	add	a5,a5,a0
    800054d0:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    800054d4:	60a2                	ld	ra,8(sp)
    800054d6:	6402                	ld	s0,0(sp)
    800054d8:	0141                	addi	sp,sp,16
    800054da:	8082                	ret

00000000800054dc <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800054dc:	1141                	addi	sp,sp,-16
    800054de:	e406                	sd	ra,8(sp)
    800054e0:	e022                	sd	s0,0(sp)
    800054e2:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800054e4:	ba6fc0ef          	jal	8000188a <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800054e8:	00d5151b          	slliw	a0,a0,0xd
    800054ec:	0c2017b7          	lui	a5,0xc201
    800054f0:	97aa                	add	a5,a5,a0
  return irq;
}
    800054f2:	43c8                	lw	a0,4(a5)
    800054f4:	60a2                	ld	ra,8(sp)
    800054f6:	6402                	ld	s0,0(sp)
    800054f8:	0141                	addi	sp,sp,16
    800054fa:	8082                	ret

00000000800054fc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800054fc:	1101                	addi	sp,sp,-32
    800054fe:	ec06                	sd	ra,24(sp)
    80005500:	e822                	sd	s0,16(sp)
    80005502:	e426                	sd	s1,8(sp)
    80005504:	1000                	addi	s0,sp,32
    80005506:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005508:	b82fc0ef          	jal	8000188a <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    8000550c:	00d5179b          	slliw	a5,a0,0xd
    80005510:	0c201737          	lui	a4,0xc201
    80005514:	97ba                	add	a5,a5,a4
    80005516:	c3c4                	sw	s1,4(a5)
}
    80005518:	60e2                	ld	ra,24(sp)
    8000551a:	6442                	ld	s0,16(sp)
    8000551c:	64a2                	ld	s1,8(sp)
    8000551e:	6105                	addi	sp,sp,32
    80005520:	8082                	ret

0000000080005522 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005522:	1141                	addi	sp,sp,-16
    80005524:	e406                	sd	ra,8(sp)
    80005526:	e022                	sd	s0,0(sp)
    80005528:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000552a:	479d                	li	a5,7
    8000552c:	04a7ca63          	blt	a5,a0,80005580 <free_desc+0x5e>
    panic("free_desc 1");
  if(disk.free[i])
    80005530:	0001e797          	auipc	a5,0x1e
    80005534:	f7878793          	addi	a5,a5,-136 # 800234a8 <disk>
    80005538:	97aa                	add	a5,a5,a0
    8000553a:	0187c783          	lbu	a5,24(a5)
    8000553e:	e7b9                	bnez	a5,8000558c <free_desc+0x6a>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005540:	00451693          	slli	a3,a0,0x4
    80005544:	0001e797          	auipc	a5,0x1e
    80005548:	f6478793          	addi	a5,a5,-156 # 800234a8 <disk>
    8000554c:	6398                	ld	a4,0(a5)
    8000554e:	9736                	add	a4,a4,a3
    80005550:	00073023          	sd	zero,0(a4) # c201000 <_entry-0x73dff000>
  disk.desc[i].len = 0;
    80005554:	6398                	ld	a4,0(a5)
    80005556:	9736                	add	a4,a4,a3
    80005558:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    8000555c:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005560:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005564:	97aa                	add	a5,a5,a0
    80005566:	4705                	li	a4,1
    80005568:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    8000556c:	0001e517          	auipc	a0,0x1e
    80005570:	f5450513          	addi	a0,a0,-172 # 800234c0 <disk+0x18>
    80005574:	9a1fc0ef          	jal	80001f14 <wakeup>
}
    80005578:	60a2                	ld	ra,8(sp)
    8000557a:	6402                	ld	s0,0(sp)
    8000557c:	0141                	addi	sp,sp,16
    8000557e:	8082                	ret
    panic("free_desc 1");
    80005580:	00002517          	auipc	a0,0x2
    80005584:	09050513          	addi	a0,a0,144 # 80007610 <etext+0x610>
    80005588:	a56fb0ef          	jal	800007de <panic>
    panic("free_desc 2");
    8000558c:	00002517          	auipc	a0,0x2
    80005590:	09450513          	addi	a0,a0,148 # 80007620 <etext+0x620>
    80005594:	a4afb0ef          	jal	800007de <panic>

0000000080005598 <virtio_disk_init>:
{
    80005598:	1101                	addi	sp,sp,-32
    8000559a:	ec06                	sd	ra,24(sp)
    8000559c:	e822                	sd	s0,16(sp)
    8000559e:	e426                	sd	s1,8(sp)
    800055a0:	e04a                	sd	s2,0(sp)
    800055a2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800055a4:	00002597          	auipc	a1,0x2
    800055a8:	08c58593          	addi	a1,a1,140 # 80007630 <etext+0x630>
    800055ac:	0001e517          	auipc	a0,0x1e
    800055b0:	02450513          	addi	a0,a0,36 # 800235d0 <disk+0x128>
    800055b4:	d94fb0ef          	jal	80000b48 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055b8:	100017b7          	lui	a5,0x10001
    800055bc:	4398                	lw	a4,0(a5)
    800055be:	2701                	sext.w	a4,a4
    800055c0:	747277b7          	lui	a5,0x74727
    800055c4:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800055c8:	14f71863          	bne	a4,a5,80005718 <virtio_disk_init+0x180>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800055cc:	100017b7          	lui	a5,0x10001
    800055d0:	43dc                	lw	a5,4(a5)
    800055d2:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800055d4:	4709                	li	a4,2
    800055d6:	14e79163          	bne	a5,a4,80005718 <virtio_disk_init+0x180>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800055da:	100017b7          	lui	a5,0x10001
    800055de:	479c                	lw	a5,8(a5)
    800055e0:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800055e2:	12e79b63          	bne	a5,a4,80005718 <virtio_disk_init+0x180>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800055e6:	100017b7          	lui	a5,0x10001
    800055ea:	47d8                	lw	a4,12(a5)
    800055ec:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800055ee:	554d47b7          	lui	a5,0x554d4
    800055f2:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800055f6:	12f71163          	bne	a4,a5,80005718 <virtio_disk_init+0x180>
  *R(VIRTIO_MMIO_STATUS) = status;
    800055fa:	100017b7          	lui	a5,0x10001
    800055fe:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005602:	4705                	li	a4,1
    80005604:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005606:	470d                	li	a4,3
    80005608:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000560a:	10001737          	lui	a4,0x10001
    8000560e:	4b18                	lw	a4,16(a4)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005610:	c7ffe6b7          	lui	a3,0xc7ffe
    80005614:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdb177>
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005618:	8f75                	and	a4,a4,a3
    8000561a:	100016b7          	lui	a3,0x10001
    8000561e:	d298                	sw	a4,32(a3)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005620:	472d                	li	a4,11
    80005622:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005624:	07078793          	addi	a5,a5,112
  status = *R(VIRTIO_MMIO_STATUS);
    80005628:	439c                	lw	a5,0(a5)
    8000562a:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    8000562e:	8ba1                	andi	a5,a5,8
    80005630:	0e078a63          	beqz	a5,80005724 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005634:	100017b7          	lui	a5,0x10001
    80005638:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    8000563c:	43fc                	lw	a5,68(a5)
    8000563e:	2781                	sext.w	a5,a5
    80005640:	0e079863          	bnez	a5,80005730 <virtio_disk_init+0x198>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005644:	100017b7          	lui	a5,0x10001
    80005648:	5bdc                	lw	a5,52(a5)
    8000564a:	2781                	sext.w	a5,a5
  if(max == 0)
    8000564c:	0e078863          	beqz	a5,8000573c <virtio_disk_init+0x1a4>
  if(max < NUM)
    80005650:	471d                	li	a4,7
    80005652:	0ef77b63          	bgeu	a4,a5,80005748 <virtio_disk_init+0x1b0>
  disk.desc = kalloc();
    80005656:	ca2fb0ef          	jal	80000af8 <kalloc>
    8000565a:	0001e497          	auipc	s1,0x1e
    8000565e:	e4e48493          	addi	s1,s1,-434 # 800234a8 <disk>
    80005662:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005664:	c94fb0ef          	jal	80000af8 <kalloc>
    80005668:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000566a:	c8efb0ef          	jal	80000af8 <kalloc>
    8000566e:	87aa                	mv	a5,a0
    80005670:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005672:	6088                	ld	a0,0(s1)
    80005674:	0e050063          	beqz	a0,80005754 <virtio_disk_init+0x1bc>
    80005678:	0001e717          	auipc	a4,0x1e
    8000567c:	e3873703          	ld	a4,-456(a4) # 800234b0 <disk+0x8>
    80005680:	cb71                	beqz	a4,80005754 <virtio_disk_init+0x1bc>
    80005682:	cbe9                	beqz	a5,80005754 <virtio_disk_init+0x1bc>
  memset(disk.desc, 0, PGSIZE);
    80005684:	6605                	lui	a2,0x1
    80005686:	4581                	li	a1,0
    80005688:	e14fb0ef          	jal	80000c9c <memset>
  memset(disk.avail, 0, PGSIZE);
    8000568c:	0001e497          	auipc	s1,0x1e
    80005690:	e1c48493          	addi	s1,s1,-484 # 800234a8 <disk>
    80005694:	6605                	lui	a2,0x1
    80005696:	4581                	li	a1,0
    80005698:	6488                	ld	a0,8(s1)
    8000569a:	e02fb0ef          	jal	80000c9c <memset>
  memset(disk.used, 0, PGSIZE);
    8000569e:	6605                	lui	a2,0x1
    800056a0:	4581                	li	a1,0
    800056a2:	6888                	ld	a0,16(s1)
    800056a4:	df8fb0ef          	jal	80000c9c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800056a8:	100017b7          	lui	a5,0x10001
    800056ac:	4721                	li	a4,8
    800056ae:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800056b0:	4098                	lw	a4,0(s1)
    800056b2:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    800056b6:	40d8                	lw	a4,4(s1)
    800056b8:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    800056bc:	649c                	ld	a5,8(s1)
    800056be:	0007869b          	sext.w	a3,a5
    800056c2:	10001737          	lui	a4,0x10001
    800056c6:	08d72823          	sw	a3,144(a4) # 10001090 <_entry-0x6fffef70>
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800056ca:	9781                	srai	a5,a5,0x20
    800056cc:	08f72a23          	sw	a5,148(a4)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800056d0:	689c                	ld	a5,16(s1)
    800056d2:	0007869b          	sext.w	a3,a5
    800056d6:	0ad72023          	sw	a3,160(a4)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800056da:	9781                	srai	a5,a5,0x20
    800056dc:	0af72223          	sw	a5,164(a4)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800056e0:	4785                	li	a5,1
    800056e2:	c37c                	sw	a5,68(a4)
    disk.free[i] = 1;
    800056e4:	00f48c23          	sb	a5,24(s1)
    800056e8:	00f48ca3          	sb	a5,25(s1)
    800056ec:	00f48d23          	sb	a5,26(s1)
    800056f0:	00f48da3          	sb	a5,27(s1)
    800056f4:	00f48e23          	sb	a5,28(s1)
    800056f8:	00f48ea3          	sb	a5,29(s1)
    800056fc:	00f48f23          	sb	a5,30(s1)
    80005700:	00f48fa3          	sb	a5,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005704:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005708:	07272823          	sw	s2,112(a4)
}
    8000570c:	60e2                	ld	ra,24(sp)
    8000570e:	6442                	ld	s0,16(sp)
    80005710:	64a2                	ld	s1,8(sp)
    80005712:	6902                	ld	s2,0(sp)
    80005714:	6105                	addi	sp,sp,32
    80005716:	8082                	ret
    panic("could not find virtio disk");
    80005718:	00002517          	auipc	a0,0x2
    8000571c:	f2850513          	addi	a0,a0,-216 # 80007640 <etext+0x640>
    80005720:	8befb0ef          	jal	800007de <panic>
    panic("virtio disk FEATURES_OK unset");
    80005724:	00002517          	auipc	a0,0x2
    80005728:	f3c50513          	addi	a0,a0,-196 # 80007660 <etext+0x660>
    8000572c:	8b2fb0ef          	jal	800007de <panic>
    panic("virtio disk should not be ready");
    80005730:	00002517          	auipc	a0,0x2
    80005734:	f5050513          	addi	a0,a0,-176 # 80007680 <etext+0x680>
    80005738:	8a6fb0ef          	jal	800007de <panic>
    panic("virtio disk has no queue 0");
    8000573c:	00002517          	auipc	a0,0x2
    80005740:	f6450513          	addi	a0,a0,-156 # 800076a0 <etext+0x6a0>
    80005744:	89afb0ef          	jal	800007de <panic>
    panic("virtio disk max queue too short");
    80005748:	00002517          	auipc	a0,0x2
    8000574c:	f7850513          	addi	a0,a0,-136 # 800076c0 <etext+0x6c0>
    80005750:	88efb0ef          	jal	800007de <panic>
    panic("virtio disk kalloc");
    80005754:	00002517          	auipc	a0,0x2
    80005758:	f8c50513          	addi	a0,a0,-116 # 800076e0 <etext+0x6e0>
    8000575c:	882fb0ef          	jal	800007de <panic>

0000000080005760 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005760:	711d                	addi	sp,sp,-96
    80005762:	ec86                	sd	ra,88(sp)
    80005764:	e8a2                	sd	s0,80(sp)
    80005766:	e4a6                	sd	s1,72(sp)
    80005768:	e0ca                	sd	s2,64(sp)
    8000576a:	fc4e                	sd	s3,56(sp)
    8000576c:	f852                	sd	s4,48(sp)
    8000576e:	f456                	sd	s5,40(sp)
    80005770:	f05a                	sd	s6,32(sp)
    80005772:	ec5e                	sd	s7,24(sp)
    80005774:	e862                	sd	s8,16(sp)
    80005776:	1080                	addi	s0,sp,96
    80005778:	89aa                	mv	s3,a0
    8000577a:	8b2e                	mv	s6,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000577c:	00c52b83          	lw	s7,12(a0)
    80005780:	001b9b9b          	slliw	s7,s7,0x1
    80005784:	1b82                	slli	s7,s7,0x20
    80005786:	020bdb93          	srli	s7,s7,0x20

  acquire(&disk.vdisk_lock);
    8000578a:	0001e517          	auipc	a0,0x1e
    8000578e:	e4650513          	addi	a0,a0,-442 # 800235d0 <disk+0x128>
    80005792:	c3afb0ef          	jal	80000bcc <acquire>
  for(int i = 0; i < NUM; i++){
    80005796:	44a1                	li	s1,8
      disk.free[i] = 0;
    80005798:	0001ea97          	auipc	s5,0x1e
    8000579c:	d10a8a93          	addi	s5,s5,-752 # 800234a8 <disk>
  for(int i = 0; i < 3; i++){
    800057a0:	4a0d                	li	s4,3
    idx[i] = alloc_desc();
    800057a2:	5c7d                	li	s8,-1
    800057a4:	a095                	j	80005808 <virtio_disk_rw+0xa8>
      disk.free[i] = 0;
    800057a6:	00fa8733          	add	a4,s5,a5
    800057aa:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800057ae:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800057b0:	0207c563          	bltz	a5,800057da <virtio_disk_rw+0x7a>
  for(int i = 0; i < 3; i++){
    800057b4:	2905                	addiw	s2,s2,1
    800057b6:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800057b8:	05490c63          	beq	s2,s4,80005810 <virtio_disk_rw+0xb0>
    idx[i] = alloc_desc();
    800057bc:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800057be:	0001e717          	auipc	a4,0x1e
    800057c2:	cea70713          	addi	a4,a4,-790 # 800234a8 <disk>
    800057c6:	4781                	li	a5,0
    if(disk.free[i]){
    800057c8:	01874683          	lbu	a3,24(a4)
    800057cc:	fee9                	bnez	a3,800057a6 <virtio_disk_rw+0x46>
  for(int i = 0; i < NUM; i++){
    800057ce:	2785                	addiw	a5,a5,1
    800057d0:	0705                	addi	a4,a4,1
    800057d2:	fe979be3          	bne	a5,s1,800057c8 <virtio_disk_rw+0x68>
    idx[i] = alloc_desc();
    800057d6:	0185a023          	sw	s8,0(a1)
      for(int j = 0; j < i; j++)
    800057da:	01205d63          	blez	s2,800057f4 <virtio_disk_rw+0x94>
        free_desc(idx[j]);
    800057de:	fa042503          	lw	a0,-96(s0)
    800057e2:	d41ff0ef          	jal	80005522 <free_desc>
      for(int j = 0; j < i; j++)
    800057e6:	4785                	li	a5,1
    800057e8:	0127d663          	bge	a5,s2,800057f4 <virtio_disk_rw+0x94>
        free_desc(idx[j]);
    800057ec:	fa442503          	lw	a0,-92(s0)
    800057f0:	d33ff0ef          	jal	80005522 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800057f4:	0001e597          	auipc	a1,0x1e
    800057f8:	ddc58593          	addi	a1,a1,-548 # 800235d0 <disk+0x128>
    800057fc:	0001e517          	auipc	a0,0x1e
    80005800:	cc450513          	addi	a0,a0,-828 # 800234c0 <disk+0x18>
    80005804:	ec4fc0ef          	jal	80001ec8 <sleep>
  for(int i = 0; i < 3; i++){
    80005808:	fa040613          	addi	a2,s0,-96
    8000580c:	4901                	li	s2,0
    8000580e:	b77d                	j	800057bc <virtio_disk_rw+0x5c>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80005810:	fa042503          	lw	a0,-96(s0)
    80005814:	00451693          	slli	a3,a0,0x4

  if(write)
    80005818:	0001e797          	auipc	a5,0x1e
    8000581c:	c9078793          	addi	a5,a5,-880 # 800234a8 <disk>
    80005820:	00a50713          	addi	a4,a0,10
    80005824:	0712                	slli	a4,a4,0x4
    80005826:	973e                	add	a4,a4,a5
    80005828:	01603633          	snez	a2,s6
    8000582c:	c710                	sw	a2,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000582e:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80005832:	01773823          	sd	s7,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80005836:	6398                	ld	a4,0(a5)
    80005838:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000583a:	0a868613          	addi	a2,a3,168 # 100010a8 <_entry-0x6fffef58>
    8000583e:	963e                	add	a2,a2,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80005840:	e310                	sd	a2,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80005842:	6390                	ld	a2,0(a5)
    80005844:	00d605b3          	add	a1,a2,a3
    80005848:	4741                	li	a4,16
    8000584a:	c598                	sw	a4,8(a1)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000584c:	4805                	li	a6,1
    8000584e:	01059623          	sh	a6,12(a1)
  disk.desc[idx[0]].next = idx[1];
    80005852:	fa442703          	lw	a4,-92(s0)
    80005856:	00e59723          	sh	a4,14(a1)

  disk.desc[idx[1]].addr = (uint64) b->data;
    8000585a:	0712                	slli	a4,a4,0x4
    8000585c:	963a                	add	a2,a2,a4
    8000585e:	05898593          	addi	a1,s3,88
    80005862:	e20c                	sd	a1,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80005864:	0007b883          	ld	a7,0(a5)
    80005868:	9746                	add	a4,a4,a7
    8000586a:	40000613          	li	a2,1024
    8000586e:	c710                	sw	a2,8(a4)
  if(write)
    80005870:	001b3613          	seqz	a2,s6
    80005874:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80005878:	01066633          	or	a2,a2,a6
    8000587c:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80005880:	fa842583          	lw	a1,-88(s0)
    80005884:	00b71723          	sh	a1,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80005888:	00250613          	addi	a2,a0,2
    8000588c:	0612                	slli	a2,a2,0x4
    8000588e:	963e                	add	a2,a2,a5
    80005890:	577d                	li	a4,-1
    80005892:	00e60823          	sb	a4,16(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80005896:	0592                	slli	a1,a1,0x4
    80005898:	98ae                	add	a7,a7,a1
    8000589a:	03068713          	addi	a4,a3,48
    8000589e:	973e                	add	a4,a4,a5
    800058a0:	00e8b023          	sd	a4,0(a7)
  disk.desc[idx[2]].len = 1;
    800058a4:	6398                	ld	a4,0(a5)
    800058a6:	972e                	add	a4,a4,a1
    800058a8:	01072423          	sw	a6,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800058ac:	4689                	li	a3,2
    800058ae:	00d71623          	sh	a3,12(a4)
  disk.desc[idx[2]].next = 0;
    800058b2:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800058b6:	0109a223          	sw	a6,4(s3)
  disk.info[idx[0]].b = b;
    800058ba:	01363423          	sd	s3,8(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800058be:	6794                	ld	a3,8(a5)
    800058c0:	0026d703          	lhu	a4,2(a3)
    800058c4:	8b1d                	andi	a4,a4,7
    800058c6:	0706                	slli	a4,a4,0x1
    800058c8:	96ba                	add	a3,a3,a4
    800058ca:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800058ce:	0330000f          	fence	rw,rw

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800058d2:	6798                	ld	a4,8(a5)
    800058d4:	00275783          	lhu	a5,2(a4)
    800058d8:	2785                	addiw	a5,a5,1
    800058da:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800058de:	0330000f          	fence	rw,rw

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800058e2:	100017b7          	lui	a5,0x10001
    800058e6:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800058ea:	0049a783          	lw	a5,4(s3)
    sleep(b, &disk.vdisk_lock);
    800058ee:	0001e917          	auipc	s2,0x1e
    800058f2:	ce290913          	addi	s2,s2,-798 # 800235d0 <disk+0x128>
  while(b->disk == 1) {
    800058f6:	84c2                	mv	s1,a6
    800058f8:	01079a63          	bne	a5,a6,8000590c <virtio_disk_rw+0x1ac>
    sleep(b, &disk.vdisk_lock);
    800058fc:	85ca                	mv	a1,s2
    800058fe:	854e                	mv	a0,s3
    80005900:	dc8fc0ef          	jal	80001ec8 <sleep>
  while(b->disk == 1) {
    80005904:	0049a783          	lw	a5,4(s3)
    80005908:	fe978ae3          	beq	a5,s1,800058fc <virtio_disk_rw+0x19c>
  }

  disk.info[idx[0]].b = 0;
    8000590c:	fa042903          	lw	s2,-96(s0)
    80005910:	00290713          	addi	a4,s2,2
    80005914:	0712                	slli	a4,a4,0x4
    80005916:	0001e797          	auipc	a5,0x1e
    8000591a:	b9278793          	addi	a5,a5,-1134 # 800234a8 <disk>
    8000591e:	97ba                	add	a5,a5,a4
    80005920:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80005924:	0001e997          	auipc	s3,0x1e
    80005928:	b8498993          	addi	s3,s3,-1148 # 800234a8 <disk>
    8000592c:	00491713          	slli	a4,s2,0x4
    80005930:	0009b783          	ld	a5,0(s3)
    80005934:	97ba                	add	a5,a5,a4
    80005936:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000593a:	854a                	mv	a0,s2
    8000593c:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80005940:	be3ff0ef          	jal	80005522 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80005944:	8885                	andi	s1,s1,1
    80005946:	f0fd                	bnez	s1,8000592c <virtio_disk_rw+0x1cc>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80005948:	0001e517          	auipc	a0,0x1e
    8000594c:	c8850513          	addi	a0,a0,-888 # 800235d0 <disk+0x128>
    80005950:	b10fb0ef          	jal	80000c60 <release>
}
    80005954:	60e6                	ld	ra,88(sp)
    80005956:	6446                	ld	s0,80(sp)
    80005958:	64a6                	ld	s1,72(sp)
    8000595a:	6906                	ld	s2,64(sp)
    8000595c:	79e2                	ld	s3,56(sp)
    8000595e:	7a42                	ld	s4,48(sp)
    80005960:	7aa2                	ld	s5,40(sp)
    80005962:	7b02                	ld	s6,32(sp)
    80005964:	6be2                	ld	s7,24(sp)
    80005966:	6c42                	ld	s8,16(sp)
    80005968:	6125                	addi	sp,sp,96
    8000596a:	8082                	ret

000000008000596c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000596c:	1101                	addi	sp,sp,-32
    8000596e:	ec06                	sd	ra,24(sp)
    80005970:	e822                	sd	s0,16(sp)
    80005972:	e426                	sd	s1,8(sp)
    80005974:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80005976:	0001e497          	auipc	s1,0x1e
    8000597a:	b3248493          	addi	s1,s1,-1230 # 800234a8 <disk>
    8000597e:	0001e517          	auipc	a0,0x1e
    80005982:	c5250513          	addi	a0,a0,-942 # 800235d0 <disk+0x128>
    80005986:	a46fb0ef          	jal	80000bcc <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000598a:	100017b7          	lui	a5,0x10001
    8000598e:	53bc                	lw	a5,96(a5)
    80005990:	8b8d                	andi	a5,a5,3
    80005992:	10001737          	lui	a4,0x10001
    80005996:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80005998:	0330000f          	fence	rw,rw

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    8000599c:	689c                	ld	a5,16(s1)
    8000599e:	0204d703          	lhu	a4,32(s1)
    800059a2:	0027d783          	lhu	a5,2(a5) # 10001002 <_entry-0x6fffeffe>
    800059a6:	04f70663          	beq	a4,a5,800059f2 <virtio_disk_intr+0x86>
    __sync_synchronize();
    800059aa:	0330000f          	fence	rw,rw
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800059ae:	6898                	ld	a4,16(s1)
    800059b0:	0204d783          	lhu	a5,32(s1)
    800059b4:	8b9d                	andi	a5,a5,7
    800059b6:	078e                	slli	a5,a5,0x3
    800059b8:	97ba                	add	a5,a5,a4
    800059ba:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800059bc:	00278713          	addi	a4,a5,2
    800059c0:	0712                	slli	a4,a4,0x4
    800059c2:	9726                	add	a4,a4,s1
    800059c4:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800059c8:	e321                	bnez	a4,80005a08 <virtio_disk_intr+0x9c>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800059ca:	0789                	addi	a5,a5,2
    800059cc:	0792                	slli	a5,a5,0x4
    800059ce:	97a6                	add	a5,a5,s1
    800059d0:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800059d2:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800059d6:	d3efc0ef          	jal	80001f14 <wakeup>

    disk.used_idx += 1;
    800059da:	0204d783          	lhu	a5,32(s1)
    800059de:	2785                	addiw	a5,a5,1
    800059e0:	17c2                	slli	a5,a5,0x30
    800059e2:	93c1                	srli	a5,a5,0x30
    800059e4:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800059e8:	6898                	ld	a4,16(s1)
    800059ea:	00275703          	lhu	a4,2(a4)
    800059ee:	faf71ee3          	bne	a4,a5,800059aa <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800059f2:	0001e517          	auipc	a0,0x1e
    800059f6:	bde50513          	addi	a0,a0,-1058 # 800235d0 <disk+0x128>
    800059fa:	a66fb0ef          	jal	80000c60 <release>
}
    800059fe:	60e2                	ld	ra,24(sp)
    80005a00:	6442                	ld	s0,16(sp)
    80005a02:	64a2                	ld	s1,8(sp)
    80005a04:	6105                	addi	sp,sp,32
    80005a06:	8082                	ret
      panic("virtio_disk_intr status");
    80005a08:	00002517          	auipc	a0,0x2
    80005a0c:	cf050513          	addi	a0,a0,-784 # 800076f8 <etext+0x6f8>
    80005a10:	dcffa0ef          	jal	800007de <panic>
	...

0000000080006000 <_trampoline>:
    80006000:	14051073          	csrw	sscratch,a0
    80006004:	02000537          	lui	a0,0x2000
    80006008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000600a:	0536                	slli	a0,a0,0xd
    8000600c:	02153423          	sd	ra,40(a0)
    80006010:	02253823          	sd	sp,48(a0)
    80006014:	02353c23          	sd	gp,56(a0)
    80006018:	04453023          	sd	tp,64(a0)
    8000601c:	04553423          	sd	t0,72(a0)
    80006020:	04653823          	sd	t1,80(a0)
    80006024:	04753c23          	sd	t2,88(a0)
    80006028:	f120                	sd	s0,96(a0)
    8000602a:	f524                	sd	s1,104(a0)
    8000602c:	fd2c                	sd	a1,120(a0)
    8000602e:	e150                	sd	a2,128(a0)
    80006030:	e554                	sd	a3,136(a0)
    80006032:	e958                	sd	a4,144(a0)
    80006034:	ed5c                	sd	a5,152(a0)
    80006036:	0b053023          	sd	a6,160(a0)
    8000603a:	0b153423          	sd	a7,168(a0)
    8000603e:	0b253823          	sd	s2,176(a0)
    80006042:	0b353c23          	sd	s3,184(a0)
    80006046:	0d453023          	sd	s4,192(a0)
    8000604a:	0d553423          	sd	s5,200(a0)
    8000604e:	0d653823          	sd	s6,208(a0)
    80006052:	0d753c23          	sd	s7,216(a0)
    80006056:	0f853023          	sd	s8,224(a0)
    8000605a:	0f953423          	sd	s9,232(a0)
    8000605e:	0fa53823          	sd	s10,240(a0)
    80006062:	0fb53c23          	sd	s11,248(a0)
    80006066:	11c53023          	sd	t3,256(a0)
    8000606a:	11d53423          	sd	t4,264(a0)
    8000606e:	11e53823          	sd	t5,272(a0)
    80006072:	11f53c23          	sd	t6,280(a0)
    80006076:	140022f3          	csrr	t0,sscratch
    8000607a:	06553823          	sd	t0,112(a0)
    8000607e:	00853103          	ld	sp,8(a0)
    80006082:	02053203          	ld	tp,32(a0)
    80006086:	01053283          	ld	t0,16(a0)
    8000608a:	00053303          	ld	t1,0(a0)
    8000608e:	12000073          	sfence.vma
    80006092:	18031073          	csrw	satp,t1
    80006096:	12000073          	sfence.vma
    8000609a:	9282                	jalr	t0

000000008000609c <userret>:
    8000609c:	12000073          	sfence.vma
    800060a0:	18051073          	csrw	satp,a0
    800060a4:	12000073          	sfence.vma
    800060a8:	02000537          	lui	a0,0x2000
    800060ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800060ae:	0536                	slli	a0,a0,0xd
    800060b0:	02853083          	ld	ra,40(a0)
    800060b4:	03053103          	ld	sp,48(a0)
    800060b8:	03853183          	ld	gp,56(a0)
    800060bc:	04053203          	ld	tp,64(a0)
    800060c0:	04853283          	ld	t0,72(a0)
    800060c4:	05053303          	ld	t1,80(a0)
    800060c8:	05853383          	ld	t2,88(a0)
    800060cc:	7120                	ld	s0,96(a0)
    800060ce:	7524                	ld	s1,104(a0)
    800060d0:	7d2c                	ld	a1,120(a0)
    800060d2:	6150                	ld	a2,128(a0)
    800060d4:	6554                	ld	a3,136(a0)
    800060d6:	6958                	ld	a4,144(a0)
    800060d8:	6d5c                	ld	a5,152(a0)
    800060da:	0a053803          	ld	a6,160(a0)
    800060de:	0a853883          	ld	a7,168(a0)
    800060e2:	0b053903          	ld	s2,176(a0)
    800060e6:	0b853983          	ld	s3,184(a0)
    800060ea:	0c053a03          	ld	s4,192(a0)
    800060ee:	0c853a83          	ld	s5,200(a0)
    800060f2:	0d053b03          	ld	s6,208(a0)
    800060f6:	0d853b83          	ld	s7,216(a0)
    800060fa:	0e053c03          	ld	s8,224(a0)
    800060fe:	0e853c83          	ld	s9,232(a0)
    80006102:	0f053d03          	ld	s10,240(a0)
    80006106:	0f853d83          	ld	s11,248(a0)
    8000610a:	10053e03          	ld	t3,256(a0)
    8000610e:	10853e83          	ld	t4,264(a0)
    80006112:	11053f03          	ld	t5,272(a0)
    80006116:	11853f83          	ld	t6,280(a0)
    8000611a:	7928                	ld	a0,112(a0)
    8000611c:	10200073          	sret
	...
