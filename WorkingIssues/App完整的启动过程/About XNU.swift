//
//  About XNU.swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/17.
//

import Foundation

//MARK: - XNU

/*
 操作系统内核（X is not Unix）
 
 相关术语：dyld（动态链接器），Mach-O（ios可执行文件），execve（执行），parse（解析），segment（程序段，相关的还有section）
*/


//MARK: - XNU启动launchd
/*
-XNU内核启动之后，启动的第一个进程是launchd，而launchd启动之后会启动其他的守护进程。
XNU启动launchd的过程：
 load_init_program() ——> load_init_program_at_path()
 
 void load_init_program(proc_t p) {
 
 核心代码
 error = ENOENT
 for (i = 0, i < sizeof(init_programs) / sizeof(init_programs[0]); i++) {
// 调用load_init_program_at_path()函数
 error = load_init_program_at_path(p指针, user地址，init_programs[i]);
 if !error return;
 }
 
 init_programs是一个数据，定义：
 内核的debug模式下可以加载供调试的launchd，非debug模式下，只加载launchd，launchd负责进程的管；

 static const char * init_programs[] = {
 #if DEBUG
     "/usr/local/sbin/launchd.debug",
 #endif
 #if DEVELOPMENT || DEBUG
     "/usr/local/sbin/launchd.development",
 #endif
     "/sbin/launchd",
 }
 
 ----------------------------------------------------------------------------------
 
 可以看出，load_init_program()函数的作用就是加载launchd，加载launchd使用的方法是load_init_program_at_path()函数，load_init_program_at_path()函数里面会调用execve()函数，而实际上，execve()函数就是加载Mach-O文件流程的入口函数，因为launchd进程比较特殊，所以多出来了两个方法。
 
 上面过程流程大致如下：
 
 ①：load_init_program() -> ②：load_init_program_at_path() -> ③：execve()
 （①②步骤是为了创建launchd进程管理，③是加载Mach-O文件入口）
 }
 ---------------------------------------------------------------------------------
 */


//MARK: - XNU加载Mach-O
/*
 execve()函数是加载Mach-O文件的入口：
 
 uap是对可执行文件的封装，uap->fname可以得到执行文件的文件名
 uap->argp 可以得到执行文件的参数列表
 uap->envp 可以得到执行文件的环境变量列表
int execve(proc_t p, struct execve_args *uap, int32_t *retval)
{
    struct __mac_execve_args muap;

    muap.fname = uap->fname;
    muap.argp = uap->argp;
    muap.envp = uap->envp;
    muap.mac_p = USER_ADDR_NULL;
    // 调用了__mac_execve方法
    err = __mac_execve(p, &muap, retval);

    return(err);
}

 
 在execve()函数里面又调用了__mac_execve()函数；
 __mac_execve()函数里面先判断是否有可用进程，没有的话使用fork_create_child()函数启动新进程，之后用新的进程，生成新的task，最后会调用exec_activate_image()函数。
 
 exec_activate_image()函数会按照可执行文件的格式，而执行不同的函数。目前有三种格式：
 1、单指令集可执行文件
 2、多指令集可执行文件
 3、shell脚本
 
 exec_activate_image()函数的实现：
 // 根据二进制文件的不同格式，执行不同的内存映射函数
 static int exec_activate_image(struct image_params *imgp)
 {
 
 //封装的binary
 encapsulated_binary:
     error = -1;
     // 核心在这里，循环调用execsw相应的格式映射的加载函数进行加载
     for(i = 0; error == -1 && execsw[i].ex_imgact != NULL; i++) {

         error = (*execsw[i].ex_imgact)(imgp);

         switch (error) {
         /* case -1: not claimed: continue */
         case -2:        /* Encapsulated binary, imgp->ip_XXX set for next iteration */
             goto encapsulated_binary;

         case -3:        /* Interpreter */
             imgp->ip_vp = NULL; /* already put */
             imgp->ip_ndp = NULL; /* already nameidone */
             goto again;

         default:
             break;
         }
     }

     return (error);
 }

 
 execsw[]相关：
 execsw是一个数组，具体定义如下：
 struct execsw {
     int (*ex_imgact)(struct image_params *);
     const char *ex_name;
 } execsw[] = {
     // 单指令集的Mach-O
     { exec_mach_imgact,     "Mach-o Binary" },
     // 多指令集的Mach-O exec_fat_imgact会先进行指令集分解，然后调用exec_mach_imgact
     { exec_fat_imgact,      "Fat Binary" },
     // shell脚本
     { exec_shell_imgact,        "Interpreter Script" },
     { NULL, NULL}
 };
 -------------------------------------------------------------------------------
 对XNU加载Mach-O文件前期工作流程大概整理一下：
 加载的launchd进程管理之后，从调用execve()函数起：
 execve() -> __mac_execve() -> exe_active_imgact() —>
 -------------------------------------------------------------------------------
 
 可以从上面的exesw数组中窥探出，单指令集可执行文件（Mach-O文件）最终调用的是exec_mach_imgact()函数，多指令集可执行文件调用的是exec_fat_imgact()，但是最终还是分解成单指令集可执行文件调用即:exec_mach_imgact()，shell脚本调用的是:exec_shell_imgact()
 
 exec_mach_imgact()函数中的一个重要的功能就是将Mach-O文件映射到内存，将Mach-O映射到内存的函数是load_machfile()函数，所以在介绍exec_mach_imgact()函数之前，先介绍load_machfile()函数。
 
 
 load_machfile()函数会为Mach-O分配虚拟内存，并计算出Mach-O文件和dyld随机偏移量的值，之后会调用解析Mach-O文件的函数 parse_machfile()函数。
 
 load_Machfile()函数大概实现：👇
 
 load_return_t load_machfile(
     struct image_params *imgp,
     struct mach_header  *header,
     thread_t        thread,
     vm_map_t        *mapp,
     load_result_t       *result
 )
 {
     struct vnode        *vp = imgp->ip_vp;
     off_t           file_offset = imgp->ip_arch_offset;
     off_t           macho_size = imgp->ip_arch_size;
     off_t           file_size = imgp->ip_vattr->va_data_size;
     pmap_t          pmap = 0;   /* protected by create_map */
     vm_map_t        map;
     load_result_t       myresult;
     load_return_t       lret;
     boolean_t enforce_hard_pagezero = TRUE;
     int in_exec = (imgp->ip_flags & IMGPF_EXEC);
     task_t task = current_task();
     proc_t p = current_proc();
     mach_vm_offset_t    aslr_offset = 0;
     mach_vm_offset_t    dyld_aslr_offset = 0;

     if (macho_size > file_size) {
         return(LOAD_BADMACHO);
     }

     result->is64bit = ((imgp->ip_flags & IMGPF_IS_64BIT) == IMGPF_IS_64BIT);
     ⚠️⚠️⚠️⚠️⚠️⚠️为当前task分配内存
     pmap = pmap_create(get_task_ledger(ledger_task),
                (vm_map_size_t) 0,
                result->is64bit);
     ⚠️⚠️⚠️⚠️⚠️⚠️ 创建虚拟内存映射空间
     map = vm_map_create(pmap,
             0,
             vm_compute_max_offset(result->is64bit),
             TRUE);

     /*
      * Compute a random offset for ASLR, and an independent random offset for dyld.
      */
    ⚠️⚠️⚠️⚠️⚠️计算Mach-O文件偏移量和dyld偏移量
     if (!(imgp->ip_flags & IMGPF_DISABLE_ASLR)) {
         uint64_t max_slide_pages;

         max_slide_pages = vm_map_get_max_aslr_slide_pages(map);

         // binary（mach-o文件）随机的ASLR
         aslr_offset = random();
         aslr_offset %= max_slide_pages;
         aslr_offset <<= vm_map_page_shift(map);

         // dyld 随机的ASLR
         dyld_aslr_offset = random();
         dyld_aslr_offset %= max_slide_pages;
         dyld_aslr_offset <<= vm_map_page_shift(map);
     }

     ⚠️⚠️⚠️⚠️⚠️ 使用parse_machfile方法解析mach-o
     lret = parse_machfile(vp, map, thread, header, file_offset, macho_size,
                           0, (int64_t)aslr_offset, (int64_t)dyld_aslr_offset, result,
                   NULL, imgp);

     ⚠️⚠️⚠️⚠️⚠️
     // pagezero处理，64 bit架构，默认4GB
     if (enforce_hard_pagezero &&
         (vm_map_has_hard_pagezero(map, 0x1000) == FALSE)) {
         {
             vm_map_deallocate(map); /* will lose pmap reference too */
             return (LOAD_BADMACHO);
         }
     }

     vm_commit_pagezero_status(map);
     *mapp = map;
     return(LOAD_SUCCESS);
 }

 */


//MARK: - dyld加载
/*
 上面的pagezero，是可执行程序的第一个段程序的空指针异常，用于捕获，总是位于虚拟内存最开始的位置，大小和CPU有关，在64位的CPU架构下，pagezero的大小是4G。
 
 在load_machfile()函数中，已经为Mach-O文件分配了虚拟内存，而解析函数parse_machfile()进行了一些操作：
 
 ✅ parse_machfile()函数
 
 parse_machfile()函数主要做了三方面的工作：
 1、Mach-O文件的解析，以及对每个segment进行内存分配
 2、dyld的加载
 3、dyld的解析及虚拟内存分配
 
 下面是解析函数的部分代码：👇
 // 1.Mach-o的解析，相关segment虚拟内存分配
 // 2.dyld的加载
 // 3.dyld的解析以及虚拟内存分配
 static load_return_t parse_machfile(
     struct vnode        *vp,
     vm_map_t        map,
     thread_t        thread,
     struct mach_header  *header,
     off_t           file_offset,
     off_t           macho_size,
     int         depth,
     int64_t         aslr_offset,
     int64_t         dyld_aslr_offset,
     load_result_t       *result,
     load_result_t       *binresult,
     struct image_params *imgp
 )
 {
     uint32_t        ncmds;
     struct load_command *lcp;
     struct dylinker_command *dlp = 0;
     load_return_t       ret = LOAD_SUCCESS;

     // depth第一次调用时传入值为0,因此depth正常情况下值为0或者1
     if (depth > 1) {
         return(LOAD_FAILURE);
     }
     // depth负责parse_machfile 遍历次数（2次），第一次是解析mach-o,第二次'load_dylinker'会调用
     // 此函数来进行dyld的解析
     depth++;

     // 会检测CPU type
     if (((cpu_type_t)(header->cputype & ~CPU_ARCH_MASK) != (cpu_type() & ~CPU_ARCH_MASK)) ||
         !grade_binary(header->cputype,
             header->cpusubtype & ~CPU_SUBTYPE_MASK))
         return(LOAD_BADARCH);

     switch (header->filetype) {
     case MH_EXECUTE:
         if (depth != 1) {
             return (LOAD_FAILURE);
         }
         break;
     // 如果fileType是dyld并且是第二次循环调用，那么is_dyld标记为TRUE
     case MH_DYLINKER:
         if (depth != 2) {
             return (LOAD_FAILURE);
         }
         is_dyld = TRUE;
         break;
     default:
         return (LOAD_FAILURE);
     }

     // 如果是dyld的解析，设置slide为传入的aslr_offset
     if ((header->flags & MH_PIE) || is_dyld) {
         slide = aslr_offset;
     }
     for (pass = 0; pass <= 3; pass++) {
         // 遍历load_command
         offset = mach_header_sz;
         ncmds = header->ncmds;
         while (ncmds--) {
             // 针对每一种类型的segment进行内存映射
             switch(lcp->cmd) {
             case LC_SEGMENT: {
                 struct segment_command *scp = (struct segment_command *) lcp;
                 // segment解析和内存映射
                 ret = load_segment(lcp,header->filetype,control,file_offset,macho_size,vp,map,slide,result);
                 break;
             }
             case LC_SEGMENT_64: {
                 struct segment_command_64 *scp64 = (struct segment_command_64 *) lcp;
                 ret = load_segment(lcp,header->filetype,control,file_offset,macho_size,vp,map,slide,result);
                 break;
             }
             case LC_UNIXTHREAD:
                 ret = load_unixthread((struct thread_command *) lcp,thread,slide,result);
                 break;
             case LC_MAIN:
                 ret = load_main((struct entry_point_command *) lcp,thread,slide,result);
                 break;
             case LC_LOAD_DYLINKER:
                 // depth = 1，第一次进行mach-o解析，获取dylinker_command
                 if ((depth == 1) && (dlp == 0)) {
                     dlp = (struct dylinker_command *)lcp;
                     dlarchbits = (header->cputype & CPU_ARCH_MASK);
                 } else {
                     ret = LOAD_FAILURE;
                 }
                 break;
             case LC_UUID:
                 break;
             case LC_CODE_SIGNATURE:
                 ret = load_code_signature((struct linkedit_data_command *) lcp,vp,file_offset,macho_size,header->cputype,result,imgp);
                 break;
             default:
                 ret = LOAD_SUCCESS;
                 break;
             }
         }
     }
     if (ret == LOAD_SUCCESS) {
         if ((ret == LOAD_SUCCESS) && (dlp != 0)) {
             // 第一次解析mach-o dlp会有赋值，进行dyld的加载
             ret = load_dylinker(dlp, dlarchbits, map, thread, depth,
                         dyld_aslr_offset, result, imgp);
         }
     }
     return(ret);
 }
 
 parse_machfile()函数中调用了load_dylinker()函数
 至此总结下上面的流程：
 --------------------------------------------------------------------------------------------------
XNU加载launchd进程管理->加载Mach-O
 load_init_program() -> load_init_program_at_path() -> execve() -> __mac_execve() -> exec_activate_image() -> load_machfile() -> parse_machfile()
 --------------------------------------------------------------------------------------------------
 
✅ load_dylinker()函数
 
 load_linker函数主要负责加载dyld，以及调用parse_machfile()函数对dyld解析；
 下面试load_linker()实现部分代码：👇
 
 // load_dylinker函数主要负责dyld的加载，解析等工作
 static load_return_t load_dylinker(
     struct dylinker_command *lcp,
     integer_t       archbits,
     vm_map_t        map,
     thread_t    thread,
     int         depth,
     int64_t         slide,
     load_result_t       *result,
     struct image_params *imgp
 )
 {
     struct vnode        *vp = NULLVP;   /* set by get_macho_vnode() */
     struct mach_header  *header;
     load_result_t       *myresult;
     kern_return_t       ret;
     struct macho_data   *macho_data;
     struct {
         struct mach_header  __header;
         load_result_t       __myresult;
         struct macho_data   __macho_data;
     } *dyld_data;

 #if !(DEVELOPMENT || DEBUG)
     // 非内核debug模式下，会校验name是否和DEFAULT_DYLD_PATH相同，如果不同，直接报错
     if (0 != strcmp(name, DEFAULT_DYLD_PATH)) {
         return (LOAD_BADMACHO);
     }
 #endif
     //⚠️⚠️⚠️⚠️ 读取dyld
     ret = get_macho_vnode(name, archbits, header,
         &file_offset, &macho_size, macho_data, &vp);
     if (ret)
         goto novp_out;

     *myresult = load_result_null;
     myresult->is64bit = result->is64bit;

     // ⚠️⚠️⚠️⚠️ 解析dyld：因为dyld一样是Mach-O文件，所以同样调用的是parse_machfile()方法，同样也映射了segment内存
     ret = parse_machfile(vp, map, thread, header, file_offset,
                          macho_size, depth, slide, 0, myresult, result, imgp);
 novp_out:
     FREE(dyld_data, M_TEMP);
     return (ret);
 }

 
 ✅ exec_mach_imagct()函数
 Mach-O文件和dyld被映射到虚拟内存后，再看上面提到的，介绍完load_linker()系列操作后，看下exec_mach_imagct()函数
 
 static int exec_mach_imgact(struct image_params *imgp)
 {
     struct mach_header *mach_header = (struct mach_header *)imgp->ip_vdata;
     proc_t          p = vfs_context_proc(imgp->ip_vfs_context);
     int         error = 0;
     thread_t        thread;
     load_return_t       lret;
     load_result_t       load_result;

     // 判断是否是Mach-O文件
     if ((mach_header->magic == MH_CIGAM) ||
         (mach_header->magic == MH_CIGAM_64)) {
         error = EBADARCH;
         goto bad;
     }

     // 判断是否是可执行文件
     if (mach_header->filetype != MH_EXECUTE) {
         error = -1;
         goto bad;
     }

     // 判断cputype和cpusubtype
     if (imgp->ip_origcputype != 0) {
         /* Fat header previously had an idea about this thin file */
         if (imgp->ip_origcputype != mach_header->cputype ||
             imgp->ip_origcpusubtype != mach_header->cpusubtype) {
             error = EBADARCH;
             goto bad;
         }
     } else {
         imgp->ip_origcputype = mach_header->cputype;
         imgp->ip_origcpusubtype = mach_header->cpusubtype;
     }

     task = current_task();
     thread = current_thread();
     uthread = get_bsdthread_info(thread);

     /*
      * Actually load the image file we previously decided to load.
      */
     // ⚠️⚠️⚠️⚠️ 使用load_machfile()加载Mach-O文件，如果返回LOAD_SUCCESS,binary已经映射成可执行内存
     lret = load_machfile(imgp, mach_header, thread, &map, &load_result);
     // ⚠️⚠️⚠️⚠️ 设置内存映射的操作权限
     vm_map_set_user_wire_limit(map, p->p_rlimit[RLIMIT_MEMLOCK].rlim_cur);
     
     // ⚠️⚠️⚠️⚠️调用activate_exec_state()函数
     lret = activate_exec_state(task, p, thread, &load_result);
     return(error);
 }
 
 exec_mach_imagct()函数的操作：调用load_machfile()函数将Mach-O文件映射到内存中，以及设置了一些内存映射的操作权限，最后调用activate_exec_stata()函数；
 
 ✅ activate_exec_state()函数
 activate_exec_state()函数的主要实现：👇
 
 static int activate_exec_state(task_t task, proc_t p, thread_t thread, load_result_t *result)
 {
     thread_setentrypoint(thread, result->entry_point);
     return KERN_SUCCESS;
 }
 activate_exec_state()函数中主要调用了 thread_setentrypoint()函数；
 
 
 ✅ thread_setentrypoint()
 
 thread_setentrypoint()函数实际上是设置入口地址，设置的是_dyld_start()函数的入口地址。从这一步开始，_dyld_start开始执行。_dyld_start()函数是dyld起始的函数，dyld是运行在用户状态的，也就是从这开始，UNX内核态切换到了用户态

 
 thread_setentrypoint()主要实现：👇
 
 void
 thread_setentrypoint(thread_t thread, mach_vm_address_t entry)
 {
     pal_register_cache_state(thread, DIRTY);
     if (thread_is_64bit(thread)) {
         x86_saved_state64_t *iss64;
         iss64 = USER_REGS64(thread);
         iss64->isf.rip = (uint64_t)entry;
     } else {
         x86_saved_state32_t *iss32;
         iss32 = USER_REGS32(thread);
         iss32->eip = CAST_DOWN_EXPLICIT(unsigned int, entry);
     }
 }

 上面函数实际就是把entry_point的地址直接写入到了寄存器里面；
 到此，UNX将Mach-O文件以及dyld加载到内存的过程就完成了。
 
 ---------------------------------------------------------------------------------------------------
 总结UNX加载Mach-O文件及dyld到内存的流程：
 
XNU加载launchd进程管理->加载Mach-O->dyld加载
 1、load_init_program() ->
 2、load_init_program_at_path() ->
 3、execve() ->
 4、__mac_execve() ->
 5、exec_activate_image() ->
 6、load_machfile() ->
 7、parse_machfile() ->
 8、load_machlinker() ->
 9、parse_machfile() ->
 10、exec_mach_imagct() ->
 11、load_machfile() ->
 12、activate_exec_state() ->
 13、thread_setentrypoint() -> 完成
 
 再次对上面函数说明：
 1-2函数：是加载launchd进程函数；
 3函数：是Mach-O文件加载的入口；
 4函数：判断是否使用fork_create_child()函数启动新进程，如果需要，则后面使用的新进程，生成新的task；
 5函数：按照可执行文件的格式，执行不同的函数（目前有三种）；
 6函数：给Mach-O文件分配虚拟内存，并且计算Mach-O文件和dyld随机偏移量；
 7函数：主要做了三个工作：Mach-O文件解析，对每个segment进行内存分配、dyld的加载、dyld的解析以及虚拟内存的分配；
 8函数：主要是加载dyld及对调用7函数，对dyld解析；
 9函数：是解析dyld；
 10函数：将Mach-O文件映射到内存中，设置内存映射操作权限
 11函数：加载Mach-O文件到内存
 12-13函数：设置_dyld_start地址入口
 
 文字概括：
XNU内核启动后，启动加载launchd进程，在启动launchd进程之后再启动其他守护进程，之后就是Mach-O及dyld进行加载，给他们分配内存，将app映射到内存中
 
 */

