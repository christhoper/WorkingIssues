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
1、冷启动时间的优化
  - pre-main()阶段：
    - 合并动态库；
    - 删除无用的Objc类和库，减少category数量
    - 清除无用图片、按需压缩资源图片；
    - 减少在+load()方法里面做事情，将需要处理的事情放到+initialize()方法里；
    - 尽量使用struct。
    
  - main()阶段
    - 异步请求首页，广告，检查更新等数据；
    - 延迟执行注册极光推送注册，firebase注册等；
    - 打印处理，只有在Debug模式下才会执行打印代码；
    - 首页数据做数据缓存处理；
    
    
2、包体积大小的优化：
- LSUnusedResources检查无用图片，并删除；
- 在保证图片清晰度情况下，让UI将图切的尽可能的小；
- 使用appCode检查并删除无用代码、三方库、无用类；
- 优化代码逻辑（重复方法代码的合并）；
- 不使用XIB和StoryBoard布局；
- 编译器选项的修改：
  - Release模式下开启LTO模式（Link-Time Optimization）；
  - Release模式下Optimization Level设置为Fastet, Smallest。
  

3、加载H5页面的优化：
- 
