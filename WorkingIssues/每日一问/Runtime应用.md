## runtime

### 基础
- 相关术语
1、SEL： 方法选择器
2、id： 参数类型，指向某个类实例的指针（通过这个实例的isa指针，可以拿到全部的类信息）
3、Class：指向objc_class结构体的指针
4、Method：代表了类中的某个方法的类型
5、Ivar：成员变量类型
6、IMP：方法实现
7、Cache：方法缓存
8、Property：属性存储器




### 消息发送
调用 objc_msgSend(reciver: sel)
1、reciver为nil，直接退出；

2、通过reciver的isa指针找到reciver类对象，先从cache_t中查找：
- 找到：执行它的IMP，结束调用；  未找到：执行3

3、从reciver类对象的 class_rw_t 中的 methodList中查找：
- 找到：执行IMP，结束调用，并将方法缓存到reciver类对象cache_t中；  未找到：执行4

4、通过superClass指针找到父类的类对象，先从父类类对象的cache_t中查找：
- 找到：执行IMP，结束调用，并将方法缓存到reciver类对象cache_t中；  未找到：执行5

5、从父类类对象的 class_rw_t 中 methodList中查找：
- 找到：执行IMP，结束调用，并将方法缓存到reciver类对象cache_t中； 
- 未找到：查看上面是否还有superclass，有的话，执行4；没有的话执行**动态方法解析**


### 动态方法解析
执行 +(Bool)resoveInstanceMethod()方法，并返回YES
如果返回NO，则进入消息转发


### 消息转发
执行 -(id)forwardingTargetForSelector()方法，指定代替实现未实现方法的对象
如果返回nil，则会报方法没有识别到的错误










### 应用
1、给Category添加属性；
2、替换系统方法，换成实现自己的方法；比如字体大小的替换；
3、防止数据错误导致数组越界等闪退现象；
4、按钮防止多次重复点击处理；
  - 给UIButton关联时间间隔属性；
  - 在+load方法中，替换系统响应点击事件的方法，换成自己的实现方法；
  

