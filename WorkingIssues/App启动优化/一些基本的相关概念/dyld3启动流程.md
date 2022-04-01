## dyld3的启动流程

### 一、 Before dyld
用户点击图标之后，会发送一个系统调用execve到内核，内核创建进程。接着会把主二进制mmap进来，读取load command中的LC_LOAD_DYLINKER，找到dyld的路径。然后mmap dyld到虚拟内存，找到dyld的入口函数_dyld_start，把PC寄存器设置成_dyld_start，接下来的启动流程就交给了dyld；
（注意：这个过程都是在内核态完成的，这里提到了PC寄存器，PC寄存器存储了下一条指令的地址，程序的执行就是不断修改和读取PC寄存器来完成的）

--------

### 二、dyld

#### 创建启动闭包:
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

#### 关于闭包里面的内容说明：
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


* 3、Load & Static Initializer：
接下来会进行main函数之前的一些初始化，主要包括 +load 和 static Initializer。这两类初始化函数都有个特点：**调用顺序不确定，和对应文件的链接顺序有关系**。那么就会存在一个隐藏的坑：有些注册逻辑在 +load 里，对应会有一些地方读取这些注册的数据，如果 +load 中读取，可能读取的时候还没有注册。

如何找到代码里有哪些load和static Initializer呢？
- 在Build Settings里可以配置 write link map，这样在生成的 linkmap文件里就可以找到有哪些文件里包含load或者static Initializer，如下：
- __mod_init_func，static initializer
- __objc_nlclslist，实现 +load 的类
- __objc_nlcatlist，实现 +load 的Category


load举例：
如果+load方法里的内容很简单，会影响启动时间吗？比如这里的一个 +load 方法：
`+ (void)load { printf("123") }`

上面的 +load 方法在编译完之后，这个函数会在二进制中的TEXT两个段存在：
__text 存函数二进制，cstring 存字符串123。
为了执行函数，首先要访问__text触发一次Page In读入物理内存，为了打印字符串，要访问__cstring，还会触发一次Page In。
- 所以为了执行这个简单的函数，系统要额外付出两次Page In，所以 load函数多了，Page In会成为启动性能的瓶颈。


static Initializer产生的条件：
静态
`__attribute__((constructor))`
`static class object`
`static object in global namespace`

需要注意的是，并不是所有的static变量都会产生静态初始化，对于在编译期间就能确定的变量是会直接inline。
(```)
// 会产生静态初始化
class Test {
static const std::string var1
}
const std::string var2 = "123"
static Logger logger
// 不会产生静态初始化
static const int var3 = 1
static const char var4 = "123"
(```)

std::string会合成static Initializer是因为初始化的时候必须执行构造函数，这时候编译器就不知道怎么做，只能延迟到运行时。

--------------

### 三、UIKit Init
+load 和 static Initializer执行完毕之后，dyld会把启动流程交给app，开始执行main函数。main函数里要做的最重要的事情就是初始化UIKit。UIKit主要会做两个大的初始化：
- 初始化UIApplication；
- 启动主线程的Runloop。

由于主线程的 dispatch_async 是基于runloop的，所以在 +load 里如果调用了disapatch_async 会在这个阶段执行。

#### Runloop
Runloop和启动有什么关系呢？
- App的LifeCycle方法是基于Runloop的Source0的；
- 首帧渲染是基于Runloop Block的。

Runloop在启动上主要有几点应用：
- 精准统计启动时间；
- 找到一个时机，在启动结束去执行一些预热任务；
- 利用Runloop打散耗时的启动预热任务；

Tips： 会有一些逻辑要在启动之后delay一小段时间再回到主线程上执行，对于性能较差的设备，主线程Runloop可能会一直处于忙的状态，所以这个delay的任务不一定能按时执行；


#### AppLifeCycle
UIKit初始化之后，就进入了我们熟悉的UIApplicationDelegate回调了，在这些回调里会做一些业务上的初始化：
- `willFinishLaunch`
- `didFinishLaunch`
- `didFinishLaunchNotification`

Tips：埋点的时候，注意 didFinishLaunchNotification 这个通知，不要把这部分的时间算到UI渲染里


#### First Frame Render
一般会调用RootController的viewDidAppear作为渲染的终点，但其实这时候首帧已经完成一小段时间了，Apple 在 MetricsKit里对启动终点定义是第一个 CA：：Transaction：：commit()。

什么是CATransaction？渲染的大致流程是什么？
- iOS的渲染是在一个单独的进程RenderServer做的，App会把Render Tree编码打包给RenderServer，RenderServer再调用渲染框架(Metal/OpenGL ES)来生成bitmap，放到帧缓冲区里，硬件根据时钟信号读取帧缓冲区内容，完成屏幕刷新。CATransaction就是把一组UI上的修改，合并成一个事务，通过commit提交。

渲染流程可分为四个步骤：
* 1、Layout（布局），源头是RootLayer调用 `[ CALayer layoutSubLayers ]`，这时候 UIViewController的 `viewDidLoad` 和 `layoutSubviews` 会调用，`autolayout`也是在这一步生效。

* 2、Display（绘制），源头是RootLayer调用 `[ CALayer display ]`，如果View实现了 `drawRect` 方法，会在这个阶段调用。

* 3、Prepare（准备），这个过程中会完成图片的解码。

* 4、Commit（提交），打包Render Tree通过XPC的方式发给Render Server



### 启动Pipeline
* 1、点击图标，创建进程；
* 2、mmap主二进制，找到dyld的路径；
* 3、mmap dyld，把入口地址设为 `__dyld_start`；
* 4、重启手机/更新/下载App的第一次启动，会创建启动闭包；
* 5、把没有加载的动态库mmap进来，动态库的数量会影响这个阶段；
* 6、对每个二进制做 bind 和 rebase，主要耗时在 Page In，影响 Page In 数量的是objec的元数据；
* 7、初始化 objc 的 runtime，由于闭包已经初始化了大部分，这里只会注册 sel 和装载 category；
* 8、+load 和静态初始化被调用，除了方法本身耗时，这里还会引起大量 Page In；
* 9、初始化 `UIApplication`，启动 Main Runloop；
* 10、执行 `will/didFinishLaunch`，这里主要是业务代码耗时；
* 11、Layout，`viewDidLoad` 和 `LayoutsubViews`会在这里调用，`Autolayout`太多会影响这部分时间；
* 12、Display，`drawRect`会调用；
* 13、Prepare，图片解码发生在这一步；
* 14、Commit，首帧渲染数据打包发给RenderServer，启动结束。



### dyld2 和 dyld3 的区别
dyld2 和 dyld3 的主要区别就是没有启动闭包，就导致每次启动都要：
- 解析动态库的依赖关系；
- 解析LINKEDIT，找到 bind & rebase 的指针地址，找到bind符号的地址；
- 注册objc的Class/Method等元数据，对大型工程来说，这部分耗时会很长。


### END

