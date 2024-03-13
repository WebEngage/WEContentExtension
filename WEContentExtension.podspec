Pod::Spec.new do |s|
  s.name             = 'WEContentExtension'
  s.version          = '0.1.0'
  s.summary          = 'Extension Target SDK for adding WebEngage Rich Push Notifications support'

  s.description      = <<-DESC
  This pod contains reference implentation of iOS Notification Service Extension. Clients are expected to pull this dependency and extend their Root Notification Service class with the one provided in this pod.
  DESC

  s.homepage         = 'https://webengage.com'
  s.homepage         = 'https://github.com/WebEngage/WEContentExtension'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'BhaveshWebEngage' => 'bhavesh.sarwar@webengage.com' }
  s.source           = { :git => 'https://github.com/WebEngage/WEContentExtension.git', :tag => s.version.to_s }
  s.ios.deployment_target = '10.0'
  s.source_files = 'Sources/WEContentExtension/**/*'
end
