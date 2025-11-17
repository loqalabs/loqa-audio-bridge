require 'json'

package = JSON.parse(File.read(File.join(__dir__, '..', 'package.json')))

Pod::Spec.new do |s|
  s.name           = 'LoqaAudioBridgeModule'
  s.version        = package['version']
  s.summary        = package['description']
  s.description    = package['description']
  s.license        = package['license']
  s.author         = package['author']
  s.homepage       = package['homepage']
  s.platforms      = {
    :ios => '13.4'
  }
  s.swift_version  = '5.9'
  s.source         = { git: 'https://github.com/loqalabs/loqa' }
  s.static_framework = true

  s.dependency 'ExpoModulesCore'

  # Swift/Objective-C compatibility
  s.pod_target_xcconfig = {
    'DEFINES_MODULE' => 'YES',
  }

  s.source_files = "**/*.{h,m,mm,swift,hpp,cpp}"

  # Exclude test files from production builds (Story 2.3 - multi-layer test exclusion)
  s.exclude_files = [
    "Tests/**/*",
    "**/*Tests.swift",
    "**/*Test.swift"
  ]
end
