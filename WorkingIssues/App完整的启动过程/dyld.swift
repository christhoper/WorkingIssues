//
//  dyld作用.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/17.
//

import Foundation

//MARK: - dyld在app启动过程中的作用

/*
 XNU在完成了进程创建，分配内存等相关操作后，在设置了_start_dyld()函数入口地址，执行_start_dyld()函数后，有内核态切换到了用户态，将控制权交给dyld
 
 */

//MARK: - dyld入口
/*
 dyld入口函数就是_dyld_start()
 _dyld_start()函数内部调用了 dyldbootstrap::start()函数
 
 dyldbootstrap::start()函数内部实现：👇
 
 uintptr_t start(const struct macho_header* appsMachHeader, int argc, const char* argv[],
                 intptr_t slide, const struct macho_header* dyldsMachHeader,
                 uintptr_t* startGlue)
 {
     // if kernel had to slide dyld, we need to fix up load sensitive locations
     // we have to do this before using any global variables
     if ( slide != 0 ) {
         rebaseDyld(dyldsMachHeader, slide);
     }
     //⚠️⚠️ 调用dyld中的_main()函数，_main()函数返回主程序的main函数入口，也就是我们App的main函数地址
     return dyld::_main(appsMachHeader, appsSlide, argc, argv, envp, apple, startGlue);
 }
 
 */

//MARK: - _main()函数

/*
 _main函数主要是完成了上下文的建立，主程序初始化成imageLoader对象，加载共享的系统动态库，加载依赖的动态库，动态链接库，初始化程序，返回主程序main函数的地址
 */


//MARK: - 主程序初始化成imageLoader对象
/*
 
 instantiateFromLoadedImage函数
 instantiateFromLoadedImage()函数主要是将主程序Mach_O文件转化成一个imageLoader对象，用户后续的链接过程。imageLoader是一个抽象类，和它相关的是ImageLoaderMachO这个子类，这个子类又有ImageLoaderMachOCompressed和ImageLoaderMachOClassic这两个子类
 
 在app启动过程中，主程序和其相关的动态库都转化成了一个ImageLoader对象，看下instantiateFromLoadedImage()函数里面的操作
 
 static ImageLoaderMachO* instantiateFromLoadedImage(const macho_header* mh, uintptr_t slide, const char* path)
 {
     // ⚠️⚠️⚠️⚠️ 检测mach-o header的cputype与cpusubtype是否与当前系统兼容
     if ( isCompatibleMachO((const uint8_t*)mh, path) ) {
         ImageLoader* image = ImageLoaderMachO::instantiateMainExecutable(mh, slide, path, gLinkContext);
         addImage(image);
         return (ImageLoaderMachO*)image;
     }
 }

 isCompatibleMachO()函数主要是用来检测系统的兼容性,上面的方法里面调用了instantiateMainExecutable()函数，
 instantiateMainExecutable()函数实现：👇
 
 // 初始化ImageLoader
 ImageLoader* ImageLoaderMachO::instantiateMainExecutable(const macho_header* mh, uintptr_t slide, const char* path, const LinkContext& context)
 {
     bool compressed;
     unsigned int segCount;
     unsigned int libCount;
     // ⚠️⚠️⚠️sniffLoadCommands主要获取加载命令中compressed的值（压缩还是传统）以及segment的数量、libCount(需要加载的动态库的数量)
     sniffLoadCommands(mh, path, false, &compressed, &segCount, &libCount, context, &codeSigCmd, &encryptCmd);
     if ( compressed )
         return ImageLoaderMachOCompressed::instantiateMainExecutable(mh, slide, path, segCount, libCount, context);
     else
 #if SUPPORT_CLASSIC_MACHO
         return ImageLoaderMachOClassic::instantiateMainExecutable(mh, slide, path, segCount, libCount, context);
 #else
         throw "missing LC_DYLD_INFO load command";
 #endif
 }

 instantiateMainExecutable()函数根据Mach_O文件是否（compressed）压缩过：
 如果压缩过了则调用ImageLoaderMachOCompressed()函数，返回一个ImageLoaderMachOCompressed对象；
 没有被压缩过则调用ImageLoaderMachOClassic()函数，返回一个ImageLoaderMachOClassic对象。
 到这里，一个Mach_O文件被转化成了一个对应的ImageLoader对象了
 
 
 */

//MARK: - 加载共享的系统动态库

/*
 mapSharedCache
 mapSharedCache()函数负责将系统中的共享动态库加载进内存空间。不同app间访问的共享库最终都映射到了同一块物理内存，从而实现了共享动态库
 
 mapSharedCache()函数大概实现：👇
 // 将本地共享的动态库加载到内存空间，这也是不同app实现动态库共享的机制
 // 常见的如UIKit、Foundation都是共享库
 static void mapSharedCache()
 {
     // _shared_region_***函数，最终调用的都是内核方法
     if ( _shared_region_check_np(&cacheBaseAddress) == 0 ) {
         // 共享库已经被映射到内存中
         sSharedCache = (dyld_cache_header*)cacheBaseAddress;
         if ( strcmp(sSharedCache->magic, magic) != 0 ) {
             // 已经映射到内存中的共享库不能被识别
             sSharedCache = NULL;
             if ( gLinkContext.verboseMapping ) {
                 return;
             }
         }
     }
     else {
         // 共享库没有加载到内存中，进行加载
         // 获取共享库文件的句柄，然后进行读取解析
         int fd = openSharedCacheFile();
         if ( fd != -1 ) {
             if ( goodCache ) {
                 // 做一个随机的地址偏移
                 cacheSlide = pickCacheSlide(mappingCount, mappings);
                 //使用_shared_region_map_and_slide_np方法将共享文件映射到内存，_shared_region_map_and_slide_np
                 // 内部实际上是做了一个系统调用
                 if (_shared_region_map_and_slide_np(fd, mappingCount, mappings, cacheSlide, slideInfo, slideInfoSize) == 0) {
                     // successfully mapped cache into shared region
                     sSharedCache = (dyld_cache_header*)mappings[0].sfm_address;
                     sSharedCacheSlide = cacheSlide;
                 }
             }
         }
     }
 }
 
 mapSharedCache()函数的大概逻辑是：先判断共享动态库是否已经映射到内存中了，如果已经存在，则直接返回，否则打开缓存文件，将共享动态库映射到内存中
 

 */


//MARK: - 加载依赖的动态库
/*
 loadInsertedDylib
 
 共享动态库映射到内存后，dyld会把app环境变量DYLD_INSERT_LIBRARIES中的动态库调用loadInsertedDylib()函数进行加载。
 可以在xcode中设置环境变量，打印出app启动过程中的DYLD_INSERT_LIBRARIES环境变量，这里看一下我们开发的app的DYLD_INSERT_LIBRARIES环境变量：
 【DYLD_INSERT_LIBRARIES=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libBacktraceRecording.dylib:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/usr/lib/libMainThreadChecker.dylib:/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/Library/CoreSimulator/Profiles/Runtimes/iOS.simruntime/Contents/Resources/RuntimeRoot/Developer/Library/PrivateFrameworks/DTDDISupport.framework/libViewDebuggerSupport.dylib】
 
 loadInsertedDylib()函数中的实现逻辑：👇
 static void loadInsertedDylib(const char* path)
 {
     // loadInsertedDylib方法中主要调用了load方法
     ImageLoader* image = NULL;
     try {
         LoadContext context;
         context.useSearchPaths      = false;
         context.useFallbackPaths    = false;
         context.useLdLibraryPath    = false;
         image = load(path, context, cacheIndex);
     }
 }
 
 loadInsertedDylib()函数里面主要调用了load()函数,这个是ImageLoader对象的方法，load()函数实现逻辑：👇
 // load函数是一系列查找动态库的入口
 ImageLoader* load(const char* path, const LoadContext& context, unsigned& cacheIndex)
 {
     // ⚠️⚠️⚠️ 根据路径进行一系列的路径搜索、cache查找等
     ImageLoader* image = loadPhase0(path, orgPath, context, cacheIndex, NULL);
     if ( image != NULL ) {
         CRSetCrashLogMessage2(NULL);
         return image;
     }
     // 查找失败，再次查找
     image = loadPhase0(path, orgPath, context, cacheIndex, &exceptions);
     if ( (image == NULL) && cacheablePath(path) && !context.dontLoad ) {
         if ( (myerr == ENOENT) || (myerr == 0) )
         {
             // 从缓存里面找
             if ( findInSharedCacheImage(resolvedPath, false, NULL, &mhInCache, &pathInCache, &slideInCache) ) {
                 struct stat stat_buf;
                 try {
                     image = ImageLoaderMachO::instantiateFromCache(mhInCache, pathInCache, slideInCache, stat_buf, gLinkContext);
                     image = checkandAddImage(image, context);
                 }
             }
         }
     }
 }

 loadPhase0()函数大概实现：👇
 // 进行文件读取和mach-o文件解析，最后调用ImageLoaderMachO::instantiateFromFile生成ImageLoader对象
 static ImageLoader* loadPhase6(int fd, const struct stat& stat_buf, const char* path, const LoadContext& context)
 {
     uint64_t fileOffset = 0;
     uint64_t fileLength = stat_buf.st_size;
     // 最小的mach-o文件大小是4K
     if ( fileLength < 4096 ) {
         if ( pread(fd, firstPages, fileLength, 0) != (ssize_t)fileLength )
             throwf("pread of short file failed: %d", errno);
         shortPage = true;
     }
     else {
         if ( pread(fd, firstPages, 4096, 0) != 4096 )
             throwf("pread of first 4K failed: %d", errno);
     }
     // 是否兼容，主要是判断cpuType和cpusubType
     if ( isCompatibleMachO(firstPages, path) ) {
         // 只有MH_BUNDLE、MH_DYLIB、MH_EXECUTE 可以被动态的加载
         const mach_header* mh = (mach_header*)firstPages;
         switch ( mh->filetype ) {
             case MH_EXECUTE:
             case MH_DYLIB:
             case MH_BUNDLE:
                 break;
             default:
                 throw "mach-o, but wrong filetype";
         }
         // ⚠️⚠️⚠️ 使用instantiateFromFile生成一个ImageLoaderMachO对象
         ImageLoader* image = ImageLoaderMachO::instantiateFromFile(path, fd, firstPages, headerAndLoadCommandsSize, fileOffset, fileLength, stat_buf, gLinkContext);
         return checkandAddImage(image, context);
     }
 }
 
 loadPhase()函数里面调用ImageLoaderMachO::instantiateFromFile()函数来生成ImageLoader对象,实现逻辑类似上面的判断是否有压缩来执行不同函数
 
 
*/

//MARK: - 动态链接库
// recursive: 递归

/*
 Link
 在主程序以及其环境变量中的相关动态库都转成ImageLoader对象后，dyld会将这些ImageLoader链接起来，链接使用的是ImageLoader自身的link()函数。
 link()函数大体实现: 👇
 
 void ImageLoader::link(const LinkContext& context, bool forceLazysBound, bool preflightOnly, bool neverUnload, const RPathChain& loaderRPaths, const char* imagePath)
 {
     // 递归加载所有依赖库
     this->recursiveLoadLibraries(context, preflightOnly, loaderRPaths, imagePath);

     // ⚠️递归修正自己和依赖库的基地址，因为ASLR的原因，需要根据随机slide修正基地址
     this->recursiveRebase(context);

     // ⚠️ recursiveBind对于noLazy的符号进行绑定，lazy的符号会在运行时动态绑定
     this->recursiveBind(context, forceLazysBound, neverUnload);
 }

 link()函数中主要做了以下的工作：
 1、recursiveLoadlibraries() 递归加载所有的依赖库
 2、recursiveRebase() 递归修正自己和依赖库的基址
 3、recursiveBind() 递归进行符号绑定
 
 在递归加载了所有的依赖库过程中，加载的方法是调用loadLibrary()函数，实际上最终调用的还是load()方法，进过link()之后，主程序以及相关依赖库的地址得到了修正，达到了进程可用的目的
 
 */


//MARK: - 初始化程序 - initializeMainExecutable

/*
 initializeMainExecutable
 在link()函数执行完毕之后，会调用initializeMainExecutable()函数，可以将该函数理解为一个初始化函数。实际上，一个app启动的过程中，除了dyld做一些工作外，还有一个更重要的角色，就是runtime，而且runtime和dyld是紧密联系的。runtime里面注册了一些dyld的通知，这些通知是在runtime初始化的时候注册的。其中有一个通知是，当有新的镜像加载时，会执行runtime中的load-images()函数；
 load-images()函数做了哪些操作：👇
 
 void load_images(const char *path __unused, const struct mach_header *mh)
 {
     // ⚠️ 判断有没有load方法，没有直接返回
     if (!hasLoadMethods((const headerType *)mh)) return;

     // 递归锁
     recursive_mutex_locker_t lock(loadMethodLock);

     // Discover load methods
     {
         rwlock_writer_t lock2(runtimeLock);
         prepare_load_methods((const headerType *)mh);
     }

     // Call +load methods (without runtimeLock - re-entrant)
     call_load_methods();
 }

 在加载镜像的过程中，即调用load_images()函数里，首先调用了prepare_load_images()函数，判断有没有loadMethod，有的话接着调用call_load_methods()函数；先看下prepare_load_images()函数的实现：👇
 
 void prepare_load_methods(const headerType *mhdr)
 {
     size_t count, i;
     classref_t *classlist =
         _getObjc2NonlazyClassList(mhdr, &count);
     for (i = 0; i < count; i++) {
         schedule_class_load(remapClass(classlist[i]));
     }

     category_t **categorylist = _getObjc2NonlazyCategoryList(mhdr, &count);
     for (i = 0; i < count; i++) {
         category_t *cat = categorylist[i];
         Class cls = remapClass(cat->cls);
         if (!cls) continue;  // category for ignored weak-linked class
         realizeClass(cls);
         assert(cls->ISA()->isRealized());
         // ⚠️将分类加到loadable_list()里面去??
         add_category_to_loadable_list(cat);
     }
 }

 _getObjc2NonlazyClassList()函数获取到了所有的列表，而remapClass()函数是取得了该类的所有指针，然后调用了schedule_class_load()函数，看下schedule_class_load()函数实现：👇
 
 static void schedule_class_load(Class cls)
 {
     if (!cls) return;
     assert(cls->isRealized());  // _read_images should realize
     if (cls->data()->flags & RW_LOADED) return;
     ⚠️ 优先加载父类的load方法
     // Ensure superclass-first ordering
     schedule_class_load(cls->superclass);
     add_class_to_loadable_list(cls);
     cls->setInfo(RW_LOADED);
 }

 从这段代码，可以知道，将子类添加到加载列表之前，其父类一定会优先加载到列表中，这也是为何父类的+load方法在子类的+load方法之前调用的根本原因。
 
 我们再看load_images()函数里 call_load_methods()函数的实现:👇
 void call_load_methods(void)
 {
     static bool loading = NO;
     bool more_categories;
     loadMethodLock.assertLocked();
     if (loading) return;
     loading = YES;

     ⚠️: 出现自动释放池，是不是main函数的自动释放池呢？
     void *pool = objc_autoreleasePoolPush();

     do {
         while (loadable_classes_used > 0) {
             call_class_loads();
         }
         more_categories = call_category_loads();
     } while (loadable_classes_used > 0  ||  more_categories);
     objc_autoreleasePoolPop(pool);
     loading = NO;
 }
 
 从call_load_methods()函数里面得知，函数里面会调用call_class_loads()，看下它的实现：👇
 
 static void call_class_loads(void)
 {
     int i;
     struct loadable_class *classes = loadable_classes;
     int used = loadable_classes_used;
     loadable_classes = nil;
     loadable_classes_allocated = 0;
     loadable_classes_used = 0;

     // Call all +loads for the detached list.
     for (i = 0; i < used; i++) {
         Class cls = classes[i].cls;
         load_method_t load_method = (load_method_t)classes[i].method;
         if (!cls) continue;
         if (PrintLoading) {
             _objc_inform("LOAD: +[%s load]\n", cls->nameForLogging());
         }
         (*load_method)(cls, SEL_load);
     }

     if (classes) free(classes);
 }
 
 从call_class_loads()函数分析得知，其主要是从待加载的类列表loadable_classes中寻找对应的类，然后找到@selector(load)的实现并执行

 */

//MARK: - 返回主函数main的地址值   -  getThreadPC

/*
 getThreadPC
 
 getThreadPC是ImageLoaderMachO中的方法，主要功能是获取app main函数的地址，看下其实现逻辑：
 
 void* ImageLoaderMachO::getThreadPC() const
 {
     const uint32_t cmd_count = ((macho_header*)fMachOData)->ncmds;
     const struct load_command* const cmds = (struct load_command*)&fMachOData[sizeof(macho_header)];
     const struct load_command* cmd = cmds;
     for (uint32_t i = 0; i < cmd_count; ++i) {
         // 遍历loadCommand,加载loadCommand中的'LC_MAIN'所指向的偏移地址
         if ( cmd->cmd == LC_MAIN ) {
             entry_point_command* mainCmd = (entry_point_command*)cmd;
             // 偏移量 + header所占的字节数，就是main的入口
             void* entry = (void*)(mainCmd->entryoff + (char*)fMachOData);
             if ( this->containsAddress(entry) )
                 return entry;
             else
                 throw "LC_MAIN entryoff is out of range";
         }
         cmd = (const struct load_command*)(((char*)cmd)+cmd->cmdsize);
     }
     return NULL;
 }
 
 getThreadPC()函数，主要就是遍历loadCommand，找到“LC_MAIN”指令，得到该指令所指向的偏移地址，经过处理后，就得到了main函数的地址，然后将此地址返回给_dyld_start。_dyld_start中的main函数地址保存在寄存器后，跳转到对应的地址，开始执行main函数，至此，一个app的启动流程正式完成。

 
 */


//MARK: - 总结

/*
 在上面，已经将_main()函数中的每个流程中的关键函数都介绍完毕，最后来看先main()函数的实现
 
 uintptr_t
 _main(const macho_header* mainExecutableMH, uintptr_t mainExecutableSlide,
         int argc, const char* argv[], const char* envp[], const char* apple[],
         uintptr_t* startGlue)
 {
     uintptr_t result = 0;
     sMainExecutableMachHeader = mainExecutableMH;
     // 处理环境变量，用于打印
     if ( sEnv.DYLD_PRINT_OPTS )
         printOptions(argv);
     if ( sEnv.DYLD_PRINT_ENV )
         printEnvironmentVariables(envp);
     try {
         // ⚠️ 1、将主程序转变为一个ImageLoader对象
         sMainExecutable = instantiateFromLoadedImage(mainExecutableMH, mainExecutableSlide, sExecPath);
         if ( gLinkContext.sharedRegionMode != ImageLoader::kDontUseSharedRegion ) {
             // ⚠️2、将共享库加载到内存中
             mapSharedCache();
         }
         // ⚠️3、加载环境变量DYLD_INSERT_LIBRARIES中的动态库，使用loadInsertedDylib进行加载
         if  ( sEnv.DYLD_INSERT_LIBRARIES != NULL ) {
             for (const char* const* lib = sEnv.DYLD_INSERT_LIBRARIES; *lib != NULL; ++lib)
                 loadInsertedDylib(*lib);
         }
         // ⚠️4、链接
         link(sMainExecutable, sEnv.DYLD_BIND_AT_LAUNCH, true, ImageLoader::RPathChain(NULL, NULL), -1);
         // ⚠️5、初始化
         initializeMainExecutable();
         // ⚠️6、寻找main函数入口
         result = (uintptr_t)sMainExecutable->getThreadPC();
     }
     return result;
 }

 从程序调用了dyld入口了开始：
 
 1、执行_dyld_start()，_dyld_start()里面调用了_main()函数
 在main函数里面大概流程：
  - 先将主程序转化成ImageLoader对象： instantiateFromLoadedImage();
  - 将共享库加载到内存中： mapsharedCache()；
  - 加载依赖的动态库： loadInsertedDylib()；
  - 动态链接库： link()；
  - 初始化程序：initializeMainExecutable();
  - 寻找main函数入口：getThreadPC()
 */
