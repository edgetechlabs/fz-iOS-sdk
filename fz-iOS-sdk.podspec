#
# Be sure to run `pod lib lint fz-iOS-sdk.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'fz-iOS-sdk'
  s.version          = '0.1.0'
  s.summary          = 'Connect your app to FretZealot via fz-iOS-sdk'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
This SDK helps to scan, connect and perform actions on FretZealot.
                       DESC

  s.homepage         = 'https://github.com/edgetechlabs/fz-iOS-sdk'
  
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'edgetechlabs' => 'john@edgetechlabs.com' }
  s.source           = { :git => 'https://github.com/edgetechlabs/fz-iOS-sdk.git', :tag => s.version.to_s }


  s.ios.deployment_target = '8.0'

  s.source_files = 'fz-iOS-sdk/Classes/**/*'
  
end
