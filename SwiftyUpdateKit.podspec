Pod::Spec.new do |s|
  s.name = "SwiftyUpdateKit"
  s.version = "1.2.1"
  s.summary = "SwiftyUpdateKit supports for a user to update your app w
    hen new app version is released on the App Store."
  s.description = <<-DESC
  SwiftyUpdateKit is a framework for iOS and macOS. This framework supports for a user to update your app when new app version is released on the App Store.
                   DESC
  s.homepage = "https://github.com/HituziANDO/SwiftyUpdateKit"
  s.license = { :type => 'MIT', :file => 'LICENSE' }
  s.author = "Hituzi Ando"
  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'
  s.source = { :git => "https://github.com/HituziANDO/SwiftyUpdateKit.git", :tag => "#{s.version}" }
  s.source_files = "Framework/Sources/*.{swift,h}"
  s.requires_arc = true
  s.swift_versions = '5.0'
end

