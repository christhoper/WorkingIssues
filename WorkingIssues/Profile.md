#  Fazzaco技术栈

1、基于Alamofire，网络库的二次封装；
2、基于Kingfisher，图片加载库简单封装；
3、创建VIPER代码模板生成工具；
4、Fastlane自动打包脚本的编写；
5、崩溃、数据统计（Firebase）、内存泄漏（哆啦A梦）检查，代码规范工具（SwiftLint）等收集工具引用；
6、基于FMDB数据存储的封装；
7、基于MJRefresh二次封装；
8、一些公共UI控件封装，比如弹窗、toast，引导图、广告图，地区选择器，图片选择器等；


#  性能优化
一、冷启动时间的优化
  - pre-main()阶段：
    - 合并动态库；
    - 删除无用的Objc类和库，减少category数量
    - 清除无用图片、按需压缩资源图片；（使用LSUnusedResource工具）
    - 减少在+load()方法里面做事情，将需要处理的事情放到+initialize()方法里；
    - 尽量使用struct。
    
  - main()阶段
    - 异步请求首页，广告，检查更新等数据；
    - 延迟执行注册极光推送注册，firebase注册等；
    - 打印处理，只有在Debug模式下才会执行打印代码；
    - 首页数据做数据缓存处理；
    
    
二、包体积大小的优化：
- LSUnusedResources检查无用图片，并删除；
- 在保证图片清晰度情况下，让UI将图切的尽可能的小；
- 使用appCode检查并删除无用代码、三方库、无用类；
- 优化代码逻辑（重复方法代码的合并）；
- 不使用XIB和StoryBoard布局；
- 编译器选项的修改：
  - Release模式下开启LTO模式（Link-Time Optimization）；
  - Release模式下Optimization Level设置为Fastet, Smallest。
  

三、加载H5页面的优化：
- webView加载流程:
   - 初始化webView；
   - 请求页面；
   - 下载数据；
   - 解析HTML；
   - 请求js/css资源；
   - dom渲染；
   - 解析js执行；
   - js请求数据。

- 优化方法：
- 前后端共同优化：
  - 1、降低请求量：合并资源，减少HTTP请求数，minify/gzip压缩，webP，lazyLoad等
  - 2、加快请求速度：预解析DNS，减少域名数，并行加载，CDN分发
  - 3、缓存：HTTP协议缓存请求，离线缓存manifest，离线数据缓存localStorage
  - 4、渲染：js/css优化，加载顺序，服务端渲染模板直出。

- Fazzaco项目优化：
  - 1、创建webView复用池，（在webView不断打开的过程，发现第一次打开速度比第二次打开速度慢几百毫秒）。因此采取复用池方案，流程：
    - a、APPDelegate异步初始化重用池对象；
    - b、首页加载完毕，通知复用池，初始化webView，并放入复用池中；
    
  - 2、HTML/JS/CSS模板抽离（为何要抽离？）
  - 3、拦截离线包
  - 4、H5模板优化[共同和H5那边协调测试]
  - 5、离线包的分发（未实现）

- 白屏现象：WKWebView进行页面加载的时候，总体内存占用比较大，导致webContentProcess会崩溃，从而导致白屏现象。
- 解决： 
  - 1、判断webView.title是否为空，为空则调用 webView.reload()方法
  - 2、在webViewWebContentProcessDidTerminate(_webView: WKWebView)方法回调中调用 webView.reload()方法。

- POST请求丢失Body问题；

四、UITableView的优化：
从两个方向处理：
- 1、从CUP方面：
  - 不要频繁的调用UIView的frame，bounds，transform等属性，尽量减少不必要的修改；
  - 提前计算好布局；
  - autolayout会比直接设置frame消耗更多的CPU资源，复杂动态的页面，使用frame布局；
  - 加载列表中的图片大小最好和UIImageView的size保持一致；
  - 文本处理操作放到子线程。

- 2、从GPU方面：
  - 尽量检查视图数量和层次数，比如没必要多套几个view做为父视图；
  - 减少透明的视图(alpha小于1)，不透明的就设置opaque为YES；
  - 尽量避免出现离屏渲染。

相关扩展：
- 1、卡顿产生的原因；
- 2、什么是离屏渲染；
- 3、屏幕成像原理。




#  项目中的疑难点：
- 1、前置服务的动态设置，流程：
   - 设置项目默认host，同时在项目首次安装启动的时候，从基础服务获取host；
   - 对基础服务获取的host进行本地缓存，下次启动时先读取本地缓存；
   - 每次启动是，都会进行安全校验，然后再检查host是否有更新，如果有更新，则替换host，更新本地缓存。

- 2、webView打开速度的优化；

- 3、直播模块高仿抖音实现；
目前方案：
   - 使用UITableView作为容器，在滚动代理里监听tableView.indexPathsForVisibleRows.first的变换；
   - 判断上滑还是下滑，上滑预加载下一个直播间并释放上一个直播间资源，下滑重新加载之前的直播间并释放上一个直播间资源；

想到的优化方案：
   - 利用父子关系，使用三个控制器实现，一个显示上一个直播间，一个显示当前直播间，一个预加载下一个直播间；


- 4、多任务下载，处理多个音频合并
痛点：音频因太长太大导致下载等待时间过长问题；
处理：将导语和内容分开下载，下载完毕后再对导语和内容进行组合
过程：
    - 封装下载工具（NSURLSession和NSURLSessionDowloadTask结合实现）；
    - 异步执行多任务（创建DispatchGroup，将需要下载的任务添加进去，每个任务对应group.enter()和group.leave()）；
    - 等各个下载完成后，执行group.notify()进行音频合并；（优化点：边下载边判断是否导语对应内容已下载完毕，下载完毕则进行音频合并）；
    - 合并完成后，导出新资源路径，同时删除导语和内容等数据。
    - 合并过程：
      - 使用AVURLAsset读取需要合并资源的信息；
      - 使用AVAssetTrack创建音频轨道；
      - 设置音频参数；
      - 使用AVMutableComposion对多个音频轨道进行添加或删除；
      - 最后使用AVAssetExportSession导出成新资源（返回的是新资源的路径）。



# OC底层
一、runtime机制：
- 大概可分为三个阶段：
  - 1、消息发送：
  - 2、动态解析：
  - 3、消息转发

二、runLoop：


三、Autorelease：


# 设计模式
一、六大设计原则：

二、常见设计模式：


# 架构
一、MVC：

二、MVVM：

三、VIPER：


# 基本数据结构和常见算法
数据结构：
 - 1、数组：
 - 2、链表：
 - 3、队列：
 - 4、堆：
 - 5、栈：
 - 6、树：
 - 7、跳表：
 - 8、散列表：
 - 9、图

常见算法：
 - 1、二分查找：
 - 2、递归：
