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
 1、编译源文件：使用Clang编译项目中所有参与编译的源文件，生成目标文件；
 2、链接目标文件：将源文件编译生成的目标文件链接成一个可执行文件；
 3、复制编译资源文件：复制和编译项目中使用的资源文件，例如将storyboard文件编译成storyboardc文件；
 4、复制embedded.mobileprovision：将本地Provisioning\Profiles下的描述文件复制到生成的APP目录下；
 5、生成Entitlements：生成签名用的Entitlements文件；
 6、签名：使用生成的Entitlements文件对生成的APP进行签名。
 
 
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
