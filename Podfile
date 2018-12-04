source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '12.1'
use_frameworks!

bluesocket_version = '~> 1.0'

target 'Operator' do
  # Add framework dependencies to app because otherwise the frameworks are not copied to app bundle.
  pod 'BlueSocket', bluesocket_version
end

target 'Interpreter' do
  pod 'BlueSocket', bluesocket_version
end

target 'InterpreterTests' do
  pod 'BlueSocket', bluesocket_version
end
