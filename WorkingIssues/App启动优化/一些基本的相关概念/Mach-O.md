## Mach-O

Mach-O是iOS可执行文件的格式，典型的Mach-O是主二进制和动态库；
### Mach-O可分为三部分：
- Header
- Load Commands
- Data

### Header
- Header最开始是Magic Number，表示这是一个二级制Mach-O文件，此外Header里面还包含了一个Flags，这些Flags会影响Mach-O的解析；

### Load Command
- Load Command存储Mach-O的布局信息，比如Segment Command和Data中的Segment/Section是一一对应的。除了布局信息外，还包含了依赖的动态库等启动app需要的信息。

### Data
- Data部分包含了实际的代码和数据，Data被分割成很多个Segment，每个Segment又被分成很多个Section，分别存放不同类型的数据；

#### Segment
- Segment：标准的三个Segment是TEXT，DATA，LINKEDIT，同样支持自定义；

#### TEXT
- TEXT：代码段，只读可执行，存储函数的二进制代码(__text)，常量字符串(__cstring)，Objective-C的类/方法名等信息；
- DATA：数据段，读写，存储Objective-C的字符串（__cfstring）,以及运行时的元数据：class/protocol/method；



### dyld
- dyld：动态链接器，是启动的辅助程序，是in-progress（进行中的）的，即启动的时候会把dyld加载到进程的地址空间里，然后把后续的启动过程交给dyld。dyld主要有两个版本：dyld2和dyld3；

#### dyld2
- iOS3.1引入，一直持续到iOS12；dyld2有一个比较大的优化就是**dyld share cache** 
- Tips：什么是share cache？
- share cache就是把系统库(如UIKit等)合成一个大的文件，提高加载性能的缓存文件。

#### dyld3
- iOS13开始启用dyld3，dyld3的最重要的特性就是启动闭包，闭包里包含了启动所需要的缓存信息，从而提高启动速度。

