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
 
 loadInsertedDylib()函数里面主要调用了load()函数（）这个是ImageLoader对象的方法，load()函数实现逻辑：👇
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
/*
 Link
 
 
 
 */
