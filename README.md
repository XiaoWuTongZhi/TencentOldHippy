![](icon.png)

## Hippy

### What's Hippy

Hippy 可以理解为一个前端和终端之间的中间层，目前上层提供了 React 和 Vue 两套界面框架，前端开发人员可以通过它，将前端代码转换为终端的原生指令，进行原生终端 App 的开发。

Hippy 是一个由终端驱动开发的前端框架，从底层做了大量工作，抹平了 iOS 和 Android 双端差异，提供了与 Web 类似的开发体验，并从底层进行了大量优化，在启动速度、可复用列表组件、渲染效率、动画速度、网络通信等等都提供了业内顶尖的性能表现。

同时 Hippy 不只是一个框架，它提供的是一整套完善的移动端高性能动态化运营解决方案。从开发时的调试、体测、发布，到发布后的监控和数据统计，Hippy 都提供了完整的工具链的保障。

### Requirements

* iOS 8.0+
* Xcode 10.0+


### Installation with CocoaPods

~~~
source 'http://git.code.oa.com/hippy/hippy_pod_source.git'
platform :ios, '8.0'

target 'TargetName' do
pod 'hippy', '~> 0.0.8'
end
~~~

### Building your first Hippy app

[快速开始](http://hippy.oa.com/guide/index.html)
[iOS如何集成](http://hippy.oa.com/guide/join-ios.html)
[发布系统接入](http://git.code.oa.com/hippy/hippy_bundle_manager)

## License

## Release Note 

### v0.0.8

#### feature

- 新增发布系统接入模块
  
#### bug fixed

- more... 

### v0.0.9
#### feature
- 增加RCTBaseListView的onEndReached事件与preloadNumberOfItem属性

#### bug fixed
- 修复<Text>标签嵌套导致手势失效的bug

### v0.1.0
#### feature

- more...

#### bug fixed
- 修复RCTImageView显示GIF图片时图片不动的bug

### v0.1.1
#### feature

- RCTImageViewCustomLoader的方法增加placeholderImage参数，表示当前RCTImaegView对应的占位符图片

#### bug fixed
- 优化backgroundImage的逻辑，修复潜在的多线程访问导致的crash
- 修复RCTScrollView的subviews超出范围显示的bug
- 统一变量名，将变量preloadNumberOfItem更名为preloadItemNumber
- 修复RCTImageView的defaultSource设置失效的bug
- 修复RCTBridge创建ImageLoader造成的卡顿bug
- 修复[RCTImageView loadImage: url: error:]参数类型传递错误的bug

- 修复多个Bridge引擎同时读写RCTAsyncLocalStorage造成读写失败的bug

### v0.1.2
#### feature

- 动画支持暂停与继续功能

#### bug fixed
- 修正RCTImageView一处内存泄漏
- 修复创建RCTBridge时moduleName赋值失败造成RCTAsyncLocalStorage文件存储失败的bug
- 修复RCTEventObserverModule无法正常移除事件监听的bug

### v0.1.3
#### feature

- 增加RCTViewPager类

#### bug fixed

- 替换几个ios8下废弃的方法
- 修复lineHeight导致竖直居中有微小误差的bug。
- 修复一个导致本地图片路径被截断的bug
- 修复MTTNode.cpp文件中的一处警告
- 增加对图片类型UIImage的数据缓存
- 修复RCTTextField进行粘贴操作时崩溃的bug

### v0.1.4
#### feature

- 增加了基本的真机调试接口（by abigaleyu）

#### bug fixed
- 修复下拉刷新组件RCTRefreshWrapperItemView布局不正确的bug
- 修复[RCTConvert NSURL:]方法处理含有中的URL时错误的bug
- TextView的onEndEditing与安卓对齐，在单行文本框下手动blur不触发，按回车触发。多行文本框保持原状，即手动blur时触发。
- 修复RCTFormatError方法获取参数类型错误导致崩溃的bug

### v0.1.5
#### feature

- ...more

#### bug fixed
- 修复[RCTConvert NSURL:]文件中一处内存泄漏的bug

### v0.1.6
#### feature

- ...more

#### bug fixed
- 修复[RCTConvert NSURL:]一处奔溃的bug

### v0.1.7
#### feature

- ...more

#### bug fixed
- 修复一处多线程操作可能导致数据不正确的bug
- 修复onEndEditing没有带上Text字段的问题
- 修复调试菜单弹出后，需要两次command+d才再次弹出调试菜单的问题
- 修复RCTModuleData.methodQueue变量多线程下操作导致的崩溃问题
- 修复RCTImageView使用NSURLSession加载图片时内存泄漏的bug
- release模式下，如果前端给的参数多于终端所需参数，那会造成数组越界，引起整个逻辑return。这里做个修改，如果前端给的参数过多，那忽略多余的参数。
- 修复点击事件中onPressIn和onPressOut耦合的问题

### v0.1.8
#### feature

- ...more

#### bug fix
- 修复加载大GIF图片时内存占用过大的bug
- RCTImageView中使用临时NSURLSession变量，防止重用时引起bug

### v0.1.9
#### feature
- 实现Navigator自定义方向的终端支持
- ...more

#### bug fix
- 修复text/textinput组件在height/width为0时，终端crash的问题
- 修复textview无法第二次设置defaultValue的bug
- 加载GIF图片时主线程解析图片Data造成的卡顿bug

### v0.2.0
#### feature
- ...more

#### bug fix
- 修复NSURLSession使用缓存导致崩溃的bug

### v0.2.1
#### feature
#### bug fix

### v0.2.2
#### feature
- 小内存手机规避高斯模糊的内存问题
- 给listView增加bounces能力
- 实现最基本的Webview组件
- 拓展deviceInfo，增加屏幕宽高和版本号等参数
- 增加含duration的scrollTo方法

#### bug fix
- 修复onTouchMoved的时候触发onPressOut的bug
- 给ListView onEndReach增加满屏校验
- 修复Text控件在用户输入文本后无法响应前端更新文本的bug

### v0.2.3
#### feature
- 增加基本的webview组件
- 增加setCookie与getCookie方法
- 增加onKeyboardWillShow属性，可以通过这个回调获取键盘高度

#### bug fix
- 修正ViewPager onPageScroll的字段意义

### v0.2.4
#### feature
- webview增加onloadEnd方法，并增加onloadstart onload onloadend回调参数

#### bug fix
- ...more

### v0.2.5
#### feature
- 为了防止命名冲突Flex.h,FlexLine.h,FlexLine.cpp改名为MTTFlex.h,MTTFlexLine.hMTTFlexLine.cpp

#### bug fix
- 修复密码textinput的明暗文切换后的文字消失问题、光标错位问题

### v0.2.6
#### feature
- ...more

#### bug fix
- 优化RCTImageView中两个OperationQueue的创建逻辑

### v0.2.7
#### feature
- RCTNetWork setCookie方法在ios11及以上系统将同时设置NSHTTPCookie和WKHTTPCookie
- 增加RCTListView滚动条的是否显示的控制
- 增加音视频组件的支持
#### bug fix
- 有多个scrollView嵌套的复杂情况（如viewpager和listview嵌套的feeds页面）的情境下拖动其中的普通view，会使得外层的scrollView滚动的bug

### v0.2.8
#### feature
- 支持了cathage   --prby=foogrywang
- 支持了剪贴板模块（RCTClipboard）

#### bug fix
- 修改RCTNetWork接口，增加用户自定义header和proxy protocol的功能
- 修复Image对cornerRadius的支持


### v0.2.9
#### feature
- 增加了onKeyPress接口，可以监听用户当前按的键
- 增加RCTCustomTouchHandlerProtocol供业务能方便自定义touch层逻辑
#### bug fix
- ExportDeviceInfo中Device字段由Phone Nicknam改为machine name（如iPhone9,4）
- 修复了hippy-react、hippy-vue中无法更新动画的bug


### v0.2.9.1
#### feature

- ... more

#### bug fix
- 修复了复杂情境下onTouchEnd偶现不会触发的问题

### v0.2.9.2
#### feature

#### bug fix
- 修复onTouchEnd调用时先判断是否存在相关的bug

### v0.3.0
#### feature
- 增加RCTPhoneCallModule
- TextView组件增加getValue、setValue方法
- RCTModalHostView增加darkStatusBarText属性
- 删减了一部分无用的代码

#### bug fix
- 修复单行textinput的maxlength失效的问题

### v0.3.1
#### feature
- ...more

#### bug fix
- 修复RCTNetWork.setCookie方法在子线程crash的bug
- 增加RCTConvertArrayValue方法中Array类型判断

### v0.3.2
#### feature
- lottieView的插件化，以及从qb sdk移入hippy sdk

#### bug fix
- 修改屏幕参数上传时机，避免屏幕参数发生改变无法及时通知前端
- ImageView补充异常处理逻辑

### v0.3.3
#### feature
- ...more

#### bug fix
- ...more

### v0.3.3d(QB专用)
#### feature
- 增加对SharpP图片解码的支持

#### bug fix
- 修复[RCTUIManager addUIBlock:]之后无法立刻刷新页面的bug
- 修复ViewPager潜在的Crash

### v0.3.3f(QB专用)
#### feature
- 增加设置JSContext.name功能用于区分不同的JSContext

#### bug fix
- hippy core使用0.0.8版本，修复JSGlobalContextRef内存泄漏的bug

### v0.3.4a(QB专用)
#### feature
- 增加开启/关闭图片缓存的接口[RCTBridge enableImageCache:]
- Modal新增autoHideStatusBar属性


#### bug fix
- 修复maxLength判断逻辑造成的bug
- 修复RCTTextView.onChangeText触发两次的bug
- 修正GIF图片时间戳可能为空导致的卡死问题




### v0.3.4b(QB专用)
#### bug fix
- 回滚RCTTextView.onChangeText触发两次的修复

### v0.3.4ba(QB专用)
因为QB回滚了版本，所以hippy基于当时的tag，发一个子子版本
#### bug fix
- 修复ViewPager的一处回调遗漏

### v0.3.4c(QB专用)
#### feature
- feat(Modal):Modal新增autoHideStatusBar属性


#### bug fix
- 修复动画资源多线程下资源竞争引起的bug

### v0.3.4d(QB专用)
#### feature
- modal新增hideStatusBar属性，决定是否展示status bar

#### bug fix
- ...more

### v0.3.6a(QB专用)
#### feature
- ...more

#### bug fix
- ...修复RCTViewPager初始化时不调用onPageSelected方法的bug

### v0.3.6b & v0.3.6c(QB专用)
#### bug fix
- 修复主线无法编译问题

### 0.3.7b
- Modal增加扣边返回能力

### 0.3.7c
#### feature
- 增加对onPageSelected的判断
- 修复setText不触发textViewDidChange事件的bug
- 增加hippy core中的异步回调能力

#### bug fix
- ...more

### 0.3.7d

#### feature
- ... more

#### bug fix
- 修复JS代码中使用了ios9不支持的es6语法导致运行错误的bug

### 0.3.7e

#### feature
- ... more

#### bug fix
- 回滚deleteNodeWork相关代码，保证内存稳定

### 0.3.7g

#### feature
- ... more

#### bug fix
- 修复内存错误

### 0.3.7h

#### feature
- ... more

#### bug fix
- 修复ImageLoaderModule.getSize方法解析图片错误的bug

### 0.3.8a

#### feature
- ... more

#### bug fix
- 修复动画状态设置不正确的bug

### 0.3.9a

#### feature
- ... View增加shadow能力

#### bug fix
- ... more

### 0.3.9b

#### feature
- ... more

#### bug fix
-  修复降低图片采样分辨率时，分辨率计算错误

### 0.3.9c

#### feature
- ... more

#### bug fix
- 修复lottie handler线程处理的bug

### 0.4.0a

#### feature
- ... more

#### bug fix
- 修复CALayer子线程操作的隐患
- 修复RCTTtouchHandler无法找到正确view的bug
- 更新core代码

### v0.4.1a
#### feature
... more

#### bug fix
- 修复使用自定义字体遇到的bug
- 修复[RCTScrollableProtocol scrollListeners]返回值类型错误的bug
- 修复在RCTTouchHandler中查找非hippy类型的view的手势的bug
- 修复RCTVideoPlayer的loop和autoPlay属性类型错误

### v0.4.3a
#### feature
... more

#### bug fix
- 修复TextInput.getValue方法返回值类型错误的bug
- 修复UIFont初始化方法的错误
- 修复手势响应链查找的bug
- 修复对富文本的支持
- 修复RCTNetwork内存泄漏的bug

### v0.4.3b
#### feature
... more

#### bug fix
- 修复Image组件在无网或者弱网情况下不清楚GIF图片内容的bug

### v0.4.3c
#### feature
... more

#### bug fix
- 展开RCTScrollView的RCT_FORWARD_SCROLL_EVENT宏，_cmd参数在函数被hook的情况下无法预期工作

### v0.4.4a
#### feature
- 增加特性：autoLetterSpacing--如果文本第二行仅存在一个字符。则自动缩减文本间距与字体大小使得所有内容一行显示

#### bug fix
- 修复由于浮点精度问题造成的数值大小比较问题

### v0.4.5a
#### feature
... more

#### bug fix
- 修复对字体fontfamily属性的支持
- 修复measureInWindow方法测量对象错误的bug
- 修复websocket能力

### v0.4.6a
#### feature
... more

#### bug fix
- 修复ios14下[UIFont fontNamesForFamilyName:]参数为NULL导致的crash
- 修复iframe场景下手势判断错误的bug

### v0.4.6b
#### feature
- 支持单VM对应多Context特性

#### bug fix
- 修复list组件onEndReach无法触发的bug
- 修复list组件itemtyp类型判断，支持string & number
- 修复onInterceptTouchEvent不生效的bug

### v0.4.7a
#### feature
... more

#### bug fix
- 尝试修复多线程crash问题

### v0.4.8a
#### feature
- 剥离pod sub spec工程

#### bug fix
... more

### v0.4.9
#### feature
- 添加JSC-base代码错误回调能力
- RCTImageView有条件触发重新加载逻辑

#### bug fix
... more

### v0.4.9.1
#### feature
...more

#### bug fix
... 修复JSContextRef为NULL导致的crash
