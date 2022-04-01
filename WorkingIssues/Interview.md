## 面试相关

* 1、控制器的生命周期？
- initWithNibName：bundle；
- initWithCoder；
- awakeFromNib；
- loadView；
- viewDidLoad；
- viewWillAppear;
- viewWillLayoutSubviews；
- viewDidLayoutSubviews；
- viewDidAppear；
- viewWillDisappear； （此时还未调用removeFromSuperview）
- viewDidDisappear；  （此时调用removeFromSuperview）
- didReceiveMemoryWarning；
- dealloc；

* 2、多个控制器跳转的生命周期？
**当push时：**
- [viewController2 loadView]    （首先加载第二个界面）
- [viewController2 viewDidLoad] （第二个界面加载完成）
- [viewController1 viewWillDisappear] （第一个界面即将消失）
- [viewController2 viewWillAppear] （第二个界面即将显示）
- [viewController2 viewWillLayoutSubviews] （第二个界面即将布局控件）
- [viewController2 viewDidLauoutSubviews] （第二个界面完成布局控件）
- [viewController1 viewDidDisappear] （第一个界面已经消失）
- [viewController2 viewDidAppear] （第二个界面已经出现）
**当pop时：**
- [viewController2 viewWillDisappear] （第二个界面即将消失）
- [viewController1 viewWillAppear] （第一个界面即将显示）
- [viewController2 viewDidDisappear] （第二个界面已经消失）
- [viewController1 viewDidAppear] （第一个界面已经显示）

* 3、堆和栈的区别？
**堆和栈：**
- 堆和栈都是一种数据项按照排序的数据结构，只能在一端对数据项进行插入和删除；
堆：先进先出
栈：先进后出

**堆栈空间分配：**
- 堆区(Stack)：一般由程序员分配释放，若不及时释放，则可能会引起内存泄漏。类似链表；
- 栈区(Heap)：由编译器自动分配释放，存放函数的参数值，局部变量等。其操作方式类似数据结构中的栈；

**堆栈缓存方式：**
- 运行代码使用的空间在三个不同的内存区域，分成三个段：
text segment  （代码区）
stack segment  （栈区）
heap segment  （堆区）
- 栈使用的是一级缓存，他们通常都是被调用时存于存储空间中，调用完就立即释放掉了
- 堆则是存放在二级缓存中，生命周期由虚拟机的垃圾回收算法来决定
**堆栈数据结构的区别：**
- 管理方式不同：
栈由编译器自动管理，堆由程序员管理；
- 空间大小不同：
栈是一块空间较小，但是运行速度很快的内存区域；堆是内存中的另外一个区域，空间比栈大，但运行速度比栈慢（操作系统对于内存heap段采用的是链表进行管理）
- 能否产生碎片不同：
堆区频繁的创建和删除会造成内存空间的不连续，从而造成大量碎片；栈区不存在，因为是先进后出的队列
- 生长方向不同：
堆区是向上的，向着内存地址增加的方向增加；栈区是向下的，向着内存地址减小的方向增加
- 分配方式不同：
堆区都是动态分配和回收内存的，没有静态分配的堆；栈有2种分配方式：静态分配和动态分配；静态分配是由比那一起完成的，比如局部变量的分配，动态分配由alloc函数进行分配；但是栈的动态分配和堆是不同的，它的动态分配也是由系统编译器进行释放，不需要程序员手动管理。
- 分配效率不同：
栈是由机器系统提供的数据结构；堆则是有C/C++函数库提供

* 4、swift中的数据类型有哪些？
- 值类型和引用类型（Struct和Class）
- 追问：他们有什么区别？
- 1: 引用类型可以继承，值类型不可以继承；
- 2: 使用**let**声明的值类型实例不能对变量赋值，引用类型可以；
- 3: 值类型如要去改变**property**的值，则需要使用**mutating**关键字，引用类型不需要；
- 4: 从内存分配角度，值类型分配在栈上，引用类型分配在堆上；
- 5: 从安全角度，值类型是自动线程安全的，无引用计数，不会引起内存泄漏；
- 6: 从速度角度，值类型速度比引用类型的快；
- 7: property初始化不同，引用类型初始化的时候，property必须要有值。

* 5、KVO底层实现是什么？如何手动实现KVO？  （用**Person**来说）
- 当person对象添加了KVO后，通过isa-swizzling技术，把person对象的isa指针指向了一个叫NSKVONotifyin_Person的新对象，NSKVONotifyin_Person重写了Person的set、class、dealloc、_isKVO方法，当NSKVONotifyin_Person执行了dealloc方法时，又把isa指针，指向了class方法获取到的Person对象。isa指针修改完之后，NSKVONotifyin_Peson对象不会被销毁（为什么：为了重用）

- 手动触发： 先调用willChangeValueForKey方法，再调用didChangeValueForKey

* 6、说说消息机制？

* 7、atomic就一定能保证线程安全吗？
- 不能保证线程安全，atomic修饰只能保证set/get时是安全的

* 8、weak底层实现原理是什么？

* 9、KVC底层实现原理是什么？使用场景都有哪些?

* 10、什么是Block，Block底层实现原理是什么？

* 11、runloop底层实现原理是什么？

* 12、ARC和MRC的区别是什么？实现原理是什么？

* 13、多线程与锁相关问题(待定)

* 14、app签名过程?

* 15、app启动大概过程?

* 16、TCP和UDP的区别是什么？

* 17、TCP头部报文字段都有哪些？

* 18、TCP三次握手过程？四次挥手过程？

* 19、HTTP和HTTPS的区别？

* 20、TSL、SSL的工作流程是什么？

* 21、为什么可以对Objective C的字符串字面量发送消息？

* 22、一个NSObject对象占用多少内存，isa指针呢？
- 系统给一个NSObject分配了16字节内存，isa指针占用8字节。

* 23、什么是静态库、动态库呢？两者的区别是什么？ 
- 静态库拓展：静态库编译时会链接到Mach-O文件中，会增加APP的体积大小，如果需要更新，则就要重新编译一次

* 24、说下内存的几大区
- 地址从低地址到高地址：
  - 保留区
  - 代码段（__TEXT）
  - 数据段（__DATA）
    - 字符串常量
    - 已初始化数据
    - 未初始化数据
  - 堆区（HEAP）：地址从高到低
  - 栈区（STACK）：地址从低到高
  - 内核区

* 25、说说swift方法调用方式
- 调用虚函数表(vtable)

