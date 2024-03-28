Pod::Spec.new do |s|
  s.name             = 'WEContentExtension'
  s.version          = '1.0.0'
  s.summary          = 'Extension Target SDK for adding WebEngage Rich Push Notifications support'

  s.description      = <<-DESC
  This pod includes various subspecs which are intended for use in Application Extensions, and depends on APIs which are App Extension Safe. The Core subspecs provides APIs which lets you track Users and Events from within Application Extensions.
  DESC

  s.homepage         = 'https://github.com/WebEngage/WEContentExtension'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.social_media_url  = 'http://twitter.com/webengage'
  s.author           = { 'WebEngage' => 'mobile@webengage.com' }
  s.source           = { :git => 'https://github.com/WebEngage/WEContentExtension.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'Sources/WEContentExtension/**/*'
  s.documentation_url = 'https://docs.webengage.com/docs/ios-getting-started'
  s.platform          = :ios
  s.swift_version = '5.0'
  s.ios.deployment_target = '12.0'
  s.dependency 'WebEngage','>= 6.4.0'
  s.frameworks = 'Foundation'
  s.weak_frameworks = 'UserNotifications', 'UserNotificationsUI'
  
end
