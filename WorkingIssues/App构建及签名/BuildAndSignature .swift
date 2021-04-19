//
//  BuildAndSignature .swift
//  WorkingIssues
//
//  Created by bailun on 2021/3/23.
//

import Foundation

//MARK: - 应用的构建及签名

/*
 一、苹果应用包的格式
 IPA，其实就是一个压缩包，解压之后，主要有：
 META-INF、Payload、iTurnsArtwork、iTurnsMetadata.plist等文件
 
 而Payload目录下包含了应用.app，比如当前项目打包好，解压生成的.ipa文件，Payload目录下就有一个 WorkingIssues.app文件
 
 Payload目录主要包含下面几类文件：
 1、可执行文件：
 他是应用在iOS系统中的执行文件，是定义的MachO格式类型，最终有dyld进行加载运行
 2、Info.plist文件：
 存储应用的相关设置、BundleID以及Executable file等
 3、Frameworks文件夹：
 当前应用使用的第三方framework
 4、PlugIns&Wath文件夹：
 当前应用使用的Extension以及Watch手表相通的应用
 5、资源文件：
 其他文件，包括图片资源，PP配置文件，音视频资源以及其他本地化相关的文件
 
 
 二、应用的构建
 应用编译过程主要如下：
 1、编译源文件：使用Clang（C语言家族，swift是swiftc）编译项目中所有参与编译的源文件，生成目标文件；
 2、链接目标文件：将源文件编译生成的链目标文件和动态/静态库链接成一个Mach-O可执行文件；
 3、Mach-O会被裁剪，去掉一些不必要的信息；
 4、复制编译资源文件：复制和编译项目中使用的资源文件，例如将storyboard文件编译成storyboardc文件，asset编译成.cer文件；
 5、Mach-O可执行文件和资源文件一起，打包出最后的 .app
 6、复制embedded.mobileprovision：将本地Provisioning\Profiles下的描述文件复制到生成的.app目录下；
 7、生成Entitlements：生成签名用的Entitlements文件；
 8、签名：使用生成的Entitlements文件对生成的APP进行签名。
 
 
 三、应用签名及安装
 为确保安装到手机的应用都是经过认证的合法应用，苹果定制了一个签名机制，主要涉及了CertificateSigningRequest、.cer文件、Entitlements授权文件、PP配置文件
 1、CertificateSigningRequest：
 该文件包含申请者信息、申请者公钥、公钥加密算法；
 2、.cer文件：
 该文件包含申请者信息、申请者公钥、通过苹果私钥加密的数字签名；（其中数字签名是通过取出CertificateSigningRequest的公钥，添加账户信息，再通过hash算法生成一个信息摘要，使用苹果的CA私钥进行加密得到；在对应的应用进行签名时，先使用证书所对应的私钥对代码和资源文件等进行签名，苹果系统会通过公钥对应用的签名合法性进行校验）
 3、Entitlements授权文件：
 授权文件是一个沙盒的配置列表，其中列出了哪些行为会被允许、哪些行为会被拒绝。例如：在重签名应用时常常需要调试器自动发夹，就会将文件里面的get-task-allow改为true。在签名时Xcode会将这个文件作为-Entitlements参数的内容传给codesign。
 4、配置文件（Provision Profiles）：
 前面提到的证书包含在该文件里，配置文件在打包的时候会被复制到.app目录下，其中包含AppID，授权文件，证书以及可安装的设备列表（可使用“security cms -D -i embedded.mobileprovision”的命令来查看它）。
 当一个应用安装启动时，苹果系统会对其进行验证，其主要就是检查配置文件和当前运行App的信息是否匹配，检查项大概如下：
 BundleID(APP)-APPID、Entitlements(APP)-Entitlements、certificate(APP)-certificate、deviceID(系统)-deviceID
 
 */


//MARK: - IPA编译中的一些概念

/*
 一、编译：
 编译器可以分为两大部分，前端和后端，二者以IR（中间代码）作为媒介。这样前后端分离，使得前后端可以独立变化，互不影响。C语言家族（C，C++，OC等）的前端是Clang，swift的前端是swiftc，二者的后端都是llvm；
 其编译流程：
 1、前端负责预处理，词法语法分析，生成IR；
 2、后端基于IR做优化，生成机器码。
 
 如何利用编译优化启动速度？
 代码数量会影响启动速度，为了提升启动速度，可以把一些无用代码下掉；
 如何统计哪些代码没有用到？
 可以利用llvm插桩来实现。llvm的代码优化流程是一个一个Pass，因为llvm是开源的，我们可以添加一个自定义的Pass，在函数的头部插入一些代码，这些代码会记录这个函数被调用了。
 
 
 二、链接：
 经过编译后，我们有很多个目标文件，接着这些目标文件和静态库/动态库一起，链接出一个Mach-O，链接的过程并不会产生新的代码，只会做一些移动和补丁。
 目标文件有如下文件：
 1、.tbd
 2、.framework
 3、.a
 4、.o
 (备注：.tbd全称是text-based stub library，因为链接的过程中只需要符号就可以了，所以xcode6开始，像UIKit等系统库就不提供完整的Mach-O，而是提供一个只包含符号等信息的tbd文件)
 
 举一个基于链接优化启动速度的例子：
 在知道了Page In过程后，说到TEXT段的页解密很耗时，那有没有办法优化呢？
 
 可以通过ld的-rename_section，把TEXT段中的内容，比如字符串移动到其他的段，从而规避这个解密的耗时
 
 
 三、裁剪：
 编译完Mach-O文件之后，会进行裁剪（build setting中的strip style），因为里面有些信息（比如调试符号）不需要带到线上去。裁剪有多种级别，一般的配置如下：
 1、All Symbols，主二进制
 2、Non-Global Symbols，动态库
 3、Debugging Symbols，二方静态库
 
 为什么二方库在出静态库的时候要选择Debuggging Symbols？ 是因为order_file等链接期间的优化是基于符号的，如果把符号裁剪(strip)掉，那么这些优化也不会生效了。
 
 
 
 四、签名和上传
 裁剪完二进制后，会和编译好的资源文件(比如storyboardc，.car)一起打包成.app文件，接着对这个文件进行签名。接着会把包上传到iTunes connect，上传后会对__TEXT段加密，加密会减弱IPA的压缩效果，增加包体积大小，也会降低启动速度(iOS13优化了加密过程，所以不会对包大小和启动耗时有影响)
 
 签名的作用是什么？
 保证文件内容不多不少，没有被篡改过
 
 */
