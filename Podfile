platform :ios, '18.0'
use_frameworks!
inhibit_all_warnings!

target 'Articles' do
  pod 'Alamofire', '~> 5.10'
  pod 'XCGLogger', '~> 7.0'
  pod 'Swinject', '~> 2.9'
  pod 'ReachabilitySwift', '~> 5.2'
  pod 'Kingfisher', '~> 8.0'
  pod 'Cache', '~> 7.0'

  target 'ArticlesTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '18.0'
      config.build_settings['CODE_SIGNING_ALLOWED'] = 'NO'
    end
  end
end
