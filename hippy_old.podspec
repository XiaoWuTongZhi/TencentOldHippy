#
# Be sure to run `pod lib lint hippy.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'hippy_old'
  s.version          = '0.4.9.1.test'
  s.summary          = 'hippy lib for ios.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC
  s.homepage         = 'https://hippy.oa.com'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'pennyli' => 'pennyli@tencent.com' }
  s.source       = {:git => 'https://github.com/XiaoWuTongZhi/TencentOldHippy.git', :tag => s.version} #:submodules => true
  s.ios.deployment_target = '8.0'
  s.source_files = 'hippy/**/*.{h,m,c,mm,s,cpp,cc}'
  s.exclude_files = ['hippy/core/napi/v8','hippy/core/plugin']
  s.libraries    = "c++"
  s.xcconfig = { 
      'USER_HEADER_SEARCH_PATHS' => '${PODS_TARGET_SRCROOT}/hippy/**'
  }
  if ENV['hippy_use_frameworks']
    s.user_target_xcconfig = {'USER_HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/hippy/hippy'}
  else
    s.user_target_xcconfig = {'USER_HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/hippy/hippy', 'OTHER_LDFLAGS' => '-force_load "${PODS_CONFIGURATION_BUILD_DIR}/hippy/libhippy.a"'}
  end
  s.pod_target_xcconfig = {'USER_HEADER_SEARCH_PATHS' => '$(PODS_ROOT)/hippy/hippy'}

end
