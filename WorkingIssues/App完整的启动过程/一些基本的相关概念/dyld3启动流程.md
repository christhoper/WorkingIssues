## dyld3的启动流程

* 一、 Before dyld
用户点击图标之后，会发送一个系统调用execve到内核，内核创建进程。接着会把主二进制mmap进来，读取load command中的LC_LOAD_DYLINKER，找到dyld的路径。然后mmap dyld到虚拟内存，找到dyld的入口函数_dyld_start，把PC寄存器设置成_dyld_start，接下来的启动流程就交给了dyld；
（注意：这个过程都是在内核态完成的，这里提到了PC寄存器，PC寄存器存储了下一条指令的地址，程序的执行就是不断修改和读取PC寄存器来完成的）

* 二、dyld

* 1、创建启动闭包:
dyld会首先创建启动闭包，闭包是一个缓存，用来提升启动速度的。既然是缓存，那么必然不是每次启动都创建，只有在重启手机或者下载/更新app的第一次启动才会创建。(闭包存储在沙盒的 tmp/com.apple.dyld 目录，清理缓存的时候切记不要清理这个目录)

闭包里面包含了如下内容：
- dependends：依赖动态库列表；
- fixup：bind&rebase的地址
- initializer-order：初始化调用顺序；
- optimizeObjec：Objective C的元数据；
- 其他： main entry，uuid....

闭包是怎么提升启动速度的呢？
- 动态库的依赖是树状的结构，初始化的调用顺序是先调用树的叶子节点，然后一层层向上，最先调用的是libSystem，因为它是所有依赖的源头。

为什么闭包能提高启动速度呢？
- 因为这些信息是每次启动都需要，把信息存储到一个缓存文件就能避免每次都解析，尤其是Objective C的运行时数据(Class/Method...)解析非常慢。

### 关于闭包里面的内容说明：
* 1、fixup：
有了闭包之后，就可以用闭包启动App了。这时候很多动态库还没加载进来，会首先对这些动态库mmap加载到虚拟内存里。接着会对每个Mach-O做fixup，包括Rebase和Bind。
- Rebase：修复内部指针。这是因为Mach-O在mmap到虚拟内存的时候，起始地址会有一个随机的偏移量slide，需要把内部的指针指向加上这个slide。
- Bind：修复外部指针。像printf等外部函数，只有运行时才知道它的地址是什么，bind就是把指针指向这个地址。

比如：一个Objective C字符串@"123"，编译到最后的二进制的时候是会存储在两个section里：
- __TEXT, __cstring，存储实际的字符串"123"
- __DATA, __cstring，存储Objective C字符串的元数据，每个元数据占用32Byte，里面有两个指针，内部指针，指向**TEXT，__cstring**中字符串的位置；外部指针isa，指向类对象的，这也就是为什么可以对Objective C的字符串字面量发送消息的原因。


* 2、LibSystem Initializer
Bind&Rebase之后，首先会执行LibSystem的Initializer，做一些最基本的初始化：
- 初始化**libdispatch**；
- 初始化**objc runtime**，注册**sel**，加载**category**；
（注意：这里没有初始化objec的类方法等信息，是因为启动闭包的缓存数据已经包含）
