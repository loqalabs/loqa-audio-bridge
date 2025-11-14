Pod::Spec.new do |s|
  s.name           = 'LoqaAudioBridge'
  s.version        = '0.3.0'
  s.summary        = 'Real-time audio streaming for Expo'
  s.description    = 'Expo native module for real-time audio capture with VAD and battery optimization'
  s.author         = { 'Loqa Labs' => 'contact@loqalabs.com' }
  s.homepage       = 'https://github.com/loqalabs/loqa'
  s.platforms      = { :ios => '13.4' }
  s.source         = { :git => 'https://github.com/loqalabs/loqa.git', :tag => "v#{s.version}" }
  s.license        = { :type => 'MIT' }

  s.dependency 'ExpoModulesCore'

  s.swift_version  = '5.4'

  # Production source files
  s.source_files = "ios/**/*.{h,m,mm,swift}"

  # CRITICAL: Exclude test files from distribution
  s.exclude_files = [
    "ios/Tests/**/*",
    "ios/**/*Tests.swift",
    "ios/**/*Test.swift"
  ]

  # Development test spec (not distributed to clients)
  s.test_spec 'Tests' do |test_spec|
    test_spec.source_files = "ios/Tests/**/*.{h,m,swift}"
    test_spec.dependency 'Quick', '~> 7.0'
    test_spec.dependency 'Nimble', '~> 12.0'
  end
end
