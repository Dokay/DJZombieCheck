
Pod::Spec.new do |s|
  s.name             = 'DJZombieCheck'
  s.version          = '0.1.0'
  s.summary          = 'A Objective-C zombie object detect tool.'
  s.description      = <<-DESC
    A Objective-C zombie object detect tool,it can work in release mode.
                       DESC
  s.homepage         = 'https://github.com/Dokay/DJZombieCheck'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Dokay' => 'dokay_dou@163.com' }
  s.source           = { :git => 'https://github.com/Dokay/DJZombieCheck.git', :tag => s.version.to_s }
  s.platform     = :ios, "7.0"
  s.source_files = 'DJZombieCheck/Classes/**/*'
  s.requires_arc = false
  # s.public_header_files = 'Pod/Classes/**/*.h'

end
