## 关于AutoreleasePool相关
1、ARC和MRC：
ARC:
在iOS5.0苹果引入ARC自动引用计数内存管理技术，通过LLVM和Runtime协作来进行自动管理内存。LLVM编译器会在编译的时候在合适的地方为OC对象插入retain（引用计数+1）、release（引用计数-1）、autorelease代码；

MRC:
在MRC模式下，当我们不需要一个对象的时候，需要调用release或autorelease去释放对象，调用release会立刻让对象引用计数-1，当引用计数为0时，对象会被立刻销毁；调用autorelease会将对象添加到自动释放池中，它会在一个恰当的时机自动给对象调用release，所以autorelease相当于延迟了对象的释放。


2、ARC环境下，autorelease对象在什么时候释放？
系统干预释放：由Runloop控制
手动干预释放：出了autoreleasePool作用域就会释放










## AutoreleasePool 实际开发中应用场景：
1、大量的临时对象创建，比如for循环中alloc图片数据等内存消耗较大的场景；
2、创建了辅助线程（一旦线程开始执行，就必须创建自己的@autoreleasepool，否则会有内存泄漏，内存增长到大概120M左右会导致程序闪退）



