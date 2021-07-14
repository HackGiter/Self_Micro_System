## 工具介绍

gcc：C编译工具

gdb：可执行文件调试工具

ld：链接工具

dd：磁盘写入命令

meld：可视化文本差异比较工具，相见恨晚

bochs：模拟CPU工具，感觉就是虚拟机

## 完善内核

### 内联汇编

#### 格式

```c
//一般格式 asm [volatile] ("assembly code" : output : input : clobber/modify);,例：
asm volatile ("outb %b0, %w1" : : "a"(data), "Nd"(port))
```



#### 语法

```c
asm("addl %%ebx, %%eax":"=a"(out_sum):"a"(in_a),"b"(in_b));
asm("addl %2, %1;":"=a"(out_sum):"a"(in_a),"m"(in_b));

#include <stdio.h>
void main(void) {
    int ret_cnt = 0, test = 0;
    char * fmt = "hello world\n";	//共12个字符
    asm("pushl %1;		\
    call printf;		\
    addl $4, %%ebp;		\
    movl $6, %2"		\
    :"=a"(ret_cnt)		\
    :"m"(fmt), "r"(test)\
    );
    printf("the number of bytes written is %d\n", ret_cnt);
}
```

约束名 a ：表示变量指定了用寄存器eax

约束名 b ：表示变量指定了用寄存器ebx

约束名 c ：代表了变量

约束名 m ：代表了内存地址

= ：操作数类型修饰符，表示只写，上述就是out_sum=eax的意思

\+ ：表示操作数是可读写的，寄存器或内存先被读入再被写入

& ：表示此output中的操作数要独占所约束（分配）的寄存器

% ：该操作数可以和下一个输入操作数互换

占位符：分为序号占位符和名称占位符，例子中“=a”(out_sum)序号为0，%0对应的是eax；“a”(in_a)序号为1，%1对应的是eax；"b"(in_b)序号为2，%2对应的是ebx；使用%序号占位符时可以在数字前面添加b或w，表示字节或字，例%b0

## 中断

中断：中断的存在使得CPU可以感知到计算机的变化，然后跳出自己的任务转而执行中断程序，一言以蔽之，操作系统不再自闭。以下内容讨论的时**单核CPU**。本质就是一个中断信号，调用相应的中断处理程序。

### 外部中断

外部中断：指来自CPU外部的中断，中断源必须时**某个硬件**，故也称**硬件中断**。

#### 方式及处理

简单方式：通过CPU给外部硬件准备引脚接收中断，适合外部设备数量少的情况

合理方式：通过总线作为统一接口接收中断信号，CPU提供了两条信号线：***INTR***(Interrupt) & ***NMI***(Non Maskable Interrupt)

![image-20210705232335251](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210705232335251.png)

##### 可屏蔽中断 & 不可屏蔽中断

CPU可以根据情况屏蔽的中断来自于***INTR***，而***NMI***是不可屏蔽中断。Linux中将中断分为上半部分和下半部分分开处理。上半部分为需要立即执行部分，即限时执行，反之即为下半部分。中断处理程序的下半部分在开中断的情况下执行，此时如果有新的中断发生，则旧中断就会下线，先执行新中断的上半部分，主要是线程调度机制为中断处理程序进行安排。

不可屏蔽中断虽然数量有限，但往往软件不可解决，多数属于硬件问题。

### 内部中断

内部中断：可分为软中断和异常

软中断：由软件主动发起的中断，并不是客观的内部错误，例如中断指令“int 8位立即数”

异常：属于指令执行期间CPU内部产生的错误引起，是运行时错误，所以不受标志寄存器eflags中的IF位影响，无法向用户隐瞒；

**其中中断是否无视eflags中的IF位：总结时：只要中断关系到“正常”运行，就不受IF位影响**

异常：按照轻重程度分类：1.Fault，故障，CPU机器状态恢复异常状态之前，调用中断处理程序，则重新执行出错的指令；2.Trap，陷阱，软件陷入CPU设下的陷阱，例int3指令；3.Abort，终止，最严重的异常，错误无法修武，则终止该程序，通常时硬件错误或系统数据结构出错。

![image-20210705234924655](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210705234924655.png)

### 中断描述符表

中断描述符表（Interrupt Descriptor Table，IDT）：保护模式下用于存储中断处理程序入口的表，通过中断向量在表中检索对应的描述符，描述符中寻找中断处理程序的起始地址，然后执行中断处理程序。**在实模式下用于存储中断处理程序入口的表是中断向量表（Interrupt Vector Table，IVT）**。

中断描述符表除了**中断描述符**，还有**任务门描述符**和**陷阱门描述符**；但所有描述符都是记录一段程序的起始地址，即**门**。所有的描述符都是**8字节大小**。

***门描述符中添加了各种属性，就是进门的条件。***

描述符（描述符包括段描述符）高4字节的第8~12位是固定的意义，用来表述描述符的类型。第8~11位是type字段，用来描述一个描述符的类型；第12位是S位，用来表示系统段（S=0）或非系统段（数据段）(S=1)。

![image-20210706000607737](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706000607737.png)

![image-20210706000634842](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706000634842.png)

![image-20210706000649256](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706000649256.png)

![image-20210706000700700](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706000700700.png)

任务门：任务门和任务状态段（Task Status Segment，TSS）是Intel处理器在意见一级提供的任务切换机制，需配合TSS一起使用。它可以存在于全局描述符表GDT、局部描述符LDT、中断描述符表IDT中。type：0101

中断门：中断门包含了中断处理程序所在段的段选择子和段内偏移地址。使用此方式进入中断后，标志寄存器eflags中的IF位自动置0，进入中断后就关闭中断。type：1110

陷阱门：和中断门类似，区别是IF不会自动置0；且只允许存在于IDT中。type：1111

调用门：提供给用户进程进入特权0级的方式，其DPL为3。调用门记录了例程的地址，不能用int指令调用，只能用call和jmp指令。调用门可以在GDT和LDT中。type：1100

现代操作系统为了简化开发、提升性能和移植性等原因，很少用到调用门和任务门。

CPU内部有个中断描述符表寄存器（Interrupt Descriptor Table Register，IDTR），用于寻找中断描述符表（其地址不限制）。0~15：表界限，即IDT大小减1；16~47：IDT的基地址，类似GDTR的原理。同加载GDTR类似，加载IDTR的专门指令：lidt 48位内存数据。

![image-20210706004345493](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706004345493.png)

### 中断处理过程及保护

中断过程：CPU外和CPU内

CPU外：外部设备的中断由中断代理芯片（例Intel 8259A）接收，处理后将该中断向量号发送到CPU

CPU内：CPU执行该中断向量号对应的中断处理程序

1. 处理器根据中断向量号定位中断门描述符（压栈CS、IP等，保护现场）
2. 处理器进行特权级检查
3. 执行中断处理程序

![image-20210706005259761](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706005259761.png)

<img src="C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706010559573.png" alt="image-20210706010559573" style="zoom: 50%;" /><img src="C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706010626241.png" alt="image-20210706010626241"  />

有时候会在栈中压入错误码，指明中断发生在哪个段中。

![image-20210706010917581](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706010917581.png)

### 可编程中断控制器（8259A）

可编程中断控制器的详细内容，个人在“微机原理与接口技术”中了解。

![image-20210706011203057](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011203057.png)

![image-20210706011218360](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011218360.png)

#### 初始化命令字

ICW1:

![image-20210706011312332](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011312332.png)

ICW2:

![image-20210706011331404](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011331404.png)

ICW3:

![image-20210706011355556](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011355556.png)![image-20210706011405476](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011405476.png)

ICW4:

![image-20210706011423821](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011423821.png)

#### 操作命令字

OCW1:屏蔽链接在8259A上的外部设备的中断信号

![image-20210706011723772](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011723772.png)

OCW2:设置中断结束方式和优先级模式

![image-20210706011736323](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011736323.png)

![image-20210706011803176](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011803176.png)

OCW3:设定特殊屏蔽方式及查询方式

![image-20210706011831733](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210706011831733.png)

> **ICW1、OCW2、OCW3是用偶地址端口0x20（主片）或0xA0（从片）写入。**
>
> **ICW2、ICW3、ICW4和OCW1是用奇地址端口0x21（主片）或0xA1（从片）写入。**
>
> **ICW要保证一定的次序写入**

![image-20210707002023003](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210707002023003.png)

### 编写中断处理程序

#### 主要内容

中断处理程序调用：如下图，实则就是函数调用

![image-20210707005625769](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210707005625769.png)

汇编的宏：Macro，用来代替重复性输入，是一段代码的模板。参数调用可以使用%number表示第number个参数（注：索引从1开始）

```assembly
%macro 宏名字 参数个数
宏代码体
%endmacro
```

![image-20210707010032732](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210707010032732.png)

![image-20210711171532473](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711171532473.png)



#### 关于内联汇编关键函数的提示

给函数添加作用域位static且将函数主体写在头文件中，则任何引入该头文件的程序都有头文件所有函数的拷贝，则程序体积增大但是如果函数是由底层硬件端口直接调用，则直接嵌入函数不需要现场保护及恢复现场需要访存的时间提高速度。

### 可编程计数器/定时器8253

利用可编程计数器/定时器8253来设置时钟中断发生的频率。计算机中的时钟，可分为两类：内部时钟和外部时钟。

**内部时钟**是指处理器中内部元件，如运算器、控制器的工作时序，主要用于控制、同步内部工作过程的步调。内部时钟是由晶体振荡器产生的，简称**晶振**，位于主板，其频率经过分频之后就是主板的外频，处理器和南北桥之间的通信就基于**外频**。Intel处理器将此外频乘以某个倍数（倍频）之后称为**主频**。处理器取指、执行所消耗的时钟周期，都是基于主频。内部时钟的时间单位粒度通常都是纳秒（ns）级的。

外部时钟是指处理器与外部设备或外部设备之间通信时采用的一种时序，比如IIO接口和处理器之间在A/D转换时的工作时序、两个串口设备之间进行数据传输时也要事先同步时钟等。其时钟的时间单位粒度一般是毫秒（ms）级或（s）级。

**晶振产生的信号频率过高，必须将其送入定时计数器分频，产生所需要的各种定时信号。**

外部定时的两种实现方式：1.软件实现，但消耗时钟周期；2.硬件定时器不占用处理器，大大提升处理器利用率。

定时器分类：不可贬称定时器及可编程定时器。可编程定时器PIC，即Programmable Interval Timer。常用的可编程定时计数器有Intel 8253/8254/82C54A。

![image-20210711193933174](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711193933174.png)

（这里简单介绍计数器的内容，主要原因是由于个人微机原理与接口技术学习过相关内容）

#### 主要内容

1. CLK：时钟输入信号，即计数器工作的节拍。当CLK引脚接收到一个时钟信号，减法计数器将计数值减1，该引脚的脉冲频率最高为10MHz，8253为2MHz。
2. GATE：门控输入信号，某些工作方式下用于控制计数器是否可以开始计数，类似EN（ENABLE）信号，在不同工作方式下GATE的作用不同。
3. OUT：计数器输出信号。当定时工作结束，计数值为0，根据计数器的工作方式，在OUT引脚上输出相应的信号。
4. 计数初值寄存器：用来保存计数器的初始值，是16位宽度，在8253初始化时写入的计数初始值就保存在计数初值寄存器。
5. 减法计数器：16位减法计数器，接收时钟信号对从计数初值寄存器获得的初值进行减1，存入输出锁存器。
6. 输出锁存器：也称为当前计数值锁存器，用于把当前减法计数器中的计数值保存下来，目的是让外界可以随时获取当前计数值。

![image-20210711201443929](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711201443929.png)

#### 8253控制字

控制寄存器：也成为模式控制寄存器，可保存的内容称为控制字，操作端口0x43，8位大小寄存器。

控制字：用于设置所指定的计数器（通道）的工作方式、读写格式及数制。

SCx：Select Count，选择计数器位，也叫选择通道位，即Select Channel。每个计数器都有自己的控制模式，由于公用同一个控制字寄存器写入，所以需要SCx。

RWx：是读/写/锁存操作位，即Read/Write/Latch，用来设置待操作计数器（通道）的读写及锁存方式。

Mx：工作方式（模式）选择位，即Method或Mode。8253的各个计数器都有两种计数方式：二进制和十进制，十进制用BCD（Binary-Coded Decimal）码来表示，用4位二进制来表示1位十进制数。

![image-20210711201622255](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711201622255.png)

#### 8253工作方式

![image-20210711203115863](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711203115863.png)

计数器开始计数需要两个条件：

1. GATE为高电平，硬件控制
2. 计数初值写入计数器中的减法计数值，由软件out指令控制。

由此，环境可分为软件启动和硬件启动。根据不同的工作方式，分为强制终止和自动终止。

计数器的六种工作方式：

1. 方式0：计数结束中断方式（Interrupt on Terminal Count）
2. 方式1：硬件可重触发单稳方式
3. 方式2：比率发生器（Rate Generator）
4. 方式3：方波发生器（Square Wave Generator）
5. 方式4：软件触发选通（Software Triggered Strobe）
6. 方式5：硬件触发选通（Hardware Triggered Strobe）

![image-20210711211209881](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210711211209881.png)

### ASSERT断言

断言：程序中的断言是指断定程序中的内容

该系统中断言的实现：1.是为内核系统使用的ASSERT；2.是为用户进程使用的assert，

内核系统使用的ASSERT：当内核运行出现问题时，多属于严重的错误，着实没必要再继续运行，另一方面，断言在输出报错信息时，屏幕输出不应该被其他进程干扰。所以，ASSERT排查出错误后，最好在关中断的情况下打印报错信息。内核运行时，为了通过时钟中断定时调度其他任务，大部分情况下中断是打开的，如何在开中断的情况下把中断关闭是主要问题。

**ASSERT是用来辅助程序调试的，通常是用在开发阶段。**

```c
ASSERT (条件表达式);	//C语言中的ASSERT使用
```

## 内存管理

操作系统的内存管理是如何使用malloc和free给程序分配空间的关键。

### 位图 bitmap

位图，bitmap，广泛用于资源管理，对于内存或硬盘这类大容量资源的管理一般都会采用位图的方式。位图，是二进制串，是对资源数据单位的映射。例如，可以以位图的每一位对应于实际物理内存中的每个4KB，即一页。

![image-20210712154515703](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210712154515703.png)

### 内存池规划

端口和扇区都是通过地址定位，其地址分别称为端口号和逻辑扇区号，与内存地址区分。

**内核和用户进程分别运行在自己的地址空间，在实模式下，程序中的地址就等于物理地址；在保护模式下，程序地址变成了虚拟地址，虚拟地址对应的物理地址是由分页机制做的映射。**

为了有效管理两者，需要创建虚拟内存地址池和物理内存地址池。同时需要分别给用户和内核分配专用的内存，则有用户物理内存池和内核物理内存池。

由于根据分页机制分配内存，所以**内存单位大小为4KB**，称为页。

![image-20210712170409239](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210712170409239.png)

#### 32位虚拟地址

32位虚拟地址是由二级页表的映射生成的，如下是转换过程

（1）高10位是页目录pde的缩影，用于在页目录表中定位pde，细节是处理器获取高10位后自动将其乘以4，再加上页目录表的物理地址，得到pde索引对应的pde所在的物理地址，然后自动在该物理地址中，即该pde中获取保存的页表物理地址

（2）中间10位是页表项pte的索引，用于在页表中定位pte。细节和上述类似，不过加上的是第一步中得到的页表的物理地址。然后自动在该物理地址（该pte）中获取保存的普通物理页的物理地址。

（3）低12位是物理页内的偏移量，页大小是4KB，12位可寻址的范围正好是4KB，则可以直接作为上一步得到的物理页的偏移量，得到最终的物理地址。

**REMEMBER:页表是连续分配到，但是页表映射的物理地址可以是不连续的，这才是页表创建的初衷。**

## 进程 & 线程

### 介绍

线程和进程是最基本的执行单元。

单核操作系统通过采用一种称为**多道程序设计**的方式使处理器在所有任务之间来回切换实现“伪并行”，需要通过**任务调度器**进行安排。

任务调度器：操作系统用于把任务轮流调度上处理器运行的一个软件模块。调度器在内核中维护一个任务表（也称作进程表、线程表或调度表），然后按照一定的算法，从任务表中选择一个任务运行。

伪并行可以降低任务的平均响应时间，对多用户来说比较友好。但切换任务要保存现场，改变环境需要较长的时间，所以任务执行的平均时间较长。调度算法举例由时间片轮转算法，称作“轮询”。

![image-20210713084034789](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713084034789.png)

在不断执行的过程中，把程序计数器中的下一条指令地址所组成的执行轨迹称为程序的**控制执行流**。执行流就是一段逻辑上独立的指令区域，是人为给处理器安排的处理单元，其独立性体现在每个执行流都有自己的栈、自己的寄存器和内存资源，这是Intel处理器在硬件上规定的，正是执行流的上下文环境。

![image-20210713092643518](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713092643518.png)

线程是一套机制，该机制可以给一段代码构建其依赖的上下文环境，有了自己的上下文环境就可以由自己的执行流，就可以由CPU作为执行单元进行调度了，就是如此简单。

**进程就是一种控制流集合，集合中至少包含一条执行流，执行流之间相互独立，但共享进程的所有单元，是处理器的执行单元（或者称作调度单元），即线程。**

按照进程中线程数量划分，进程分为单线程进程和多线程进程。

阻塞态往往是指需要等待外界条件的状态，例如访问磁盘；就绪态是指进程可以随时准备运行的状态；运行态是指正在处理器上运行的进程状态。

![image-20210713100048883](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713100048883.png)

### 进程ID：PCB

操作系统为每个进程提供了一个自己的**PCB，Process Control Block，即程序控制块**（进程表项），用来记录与此进程相关的信息，比如进程状态、PID、优先级等，所有PCB在**进程表**中维护。PCB没有具体的格式，实际格式取决于操作系统的功能复杂度，以下是基本内容。

![image-20210713100641814](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713100641814.png)

寄存器映像用于保护保存进程的现场，寄存器的值都将保存在此处，一般位于PCB顶端，但位置并不固定，具体位置取决于0级栈指针的位置。该栈是进程所使用的0特权级下内核栈。

线程的实现有两种方式：

1. 用户级中实现线程，优点是可移植性强、自定义线程调度算法和不需要陷入内核态就不用进出内核的入栈及出栈操作，但是由程序员编程实现线程创建、线程调度及线程维护比较复杂，其次是无法实现阻塞（或者需要写个函数包裹部分代码）。
2. 内核级中实现线程，即内核提供原生线程机制。线程由内核实现，可以得到较大幅度的提速，操作系统能实现进程中某线程的阻塞而其他线程不受影响。缺点是用户进程需要通过系统调用陷入内核，保护现场的栈操作。

![image-20210713110309378](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713110309378.png)

### 内核空间实现线程

#### 定义 & 结构体

1. 定义通用函数，线程函数类型
2. 定义线程、进程状态结构体
3. 定义中断栈结构体
4. 定义线程栈结构体、进程或线程PCB（程序控制块）结构体

ABI，Application Binary Interface，即应用程序二进制接口，属于编译方面的约定，例如参数如何传递、返回值如何存储、系统调用的实现方式、目标文件格式或数据类型等。操作系统和应用程序遵循同一套的ABI规则，则应用程序可以直接在另一操作系统运行

官方规范SysV_ABI_386-V4大意：位于Intel386硬件体系上的所有寄存器都具有全局性，因此在函数调用时，这些寄存器对主调函数和被调函数都可见。这5个寄存器ebp、ebx、edi、esi和esp归主调函数所用，其余寄存器归被调函数所用。

![image-20210713114840284](C:\Users\lee19\AppData\Roaming\Typora\typora-user-images\image-20210713114840284.png)

