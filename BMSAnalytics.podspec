Pod::Spec.new do |s|

  s.name              = 'BMSAnalytics'
  s.version           = '2.2.4'
  s.summary           = 'The analytics component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage          = 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics'
  s.documentation_url = 'https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSAnalytics/Swift/index.html'
  s.license           = 'Apache License, Version 2.0'
  s.authors           = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }

  s.source       = { :git => 'https://github.com/ibm-bluemix-mobile-services/bms-clientsdk-swift-analytics.git', :tag => s.version }
  s.source_files = 'Source/**/*.swift','Source/Zip/*.{swift,h}','Source/Zip/minizip/*.{c,h}','Source/Zip/minizip/aes/*.{c,h}'
  s.ios.exclude_files = 'Source/**/*watchOS*.swift'
  s.watchos.exclude_files = 'Source/**/*iOS*.swift','Source/Feedback','Source/Zip/*.{swift,h}', 'Source/Zip/minizip/*.{c,h}', 'Source/Zip/minizip/aes/*.{c,h}'
  s.ios.public_header_files = 'Source/Zip/*.h'
  s.pod_target_xcconfig = {'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Source/Zip/minizip/**','LIBRARY_SEARCH_PATHS' => '$(SRCROOT)/Source/Zip/'}
  s.libraries = 'z'
  s.preserve_paths  = 'Source/Zip/minizip/module.modulemap'

  s.default_subspec = 'AnalyticsDep'

  s.requires_arc = true

  s.ios.deployment_target = '8.0'
  s.watchos.deployment_target = '2.0'

  ### Subspecs

  s.subspec 'AnalyticsDep' do |cs|
    cs.dependency 'BMSCore', '~> 2.1'
  end
end
