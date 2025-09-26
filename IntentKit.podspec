Pod::Spec.new do |s|
  s.name             = 'IntentKit'
  s.version          = '1.0.0'
  s.summary          = 'Swift framework for streamlining App Intents with 70%+ less boilerplate'
  s.description      = <<-DESC
IntentKit is an open-source Swift framework that streamlines adoption of App Intents
by reducing boilerplate, improving type-safety, and providing developer-friendly tools.
Features include type-safe parameter helpers, async resolution, intent donation management,
execution wrappers with retry logic, and code generation from YAML/JSON schemas.
                       DESC

  s.homepage         = 'https://github.com/realtobyfu/IntentKit'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'IntentKit Contributors' => 'contact@intentkit.dev' }
  s.source           = { :git => 'https://github.com/realtobyfu/IntentKit.git', :tag => s.version.to_s }
  s.social_media_url = 'https://github.com/realtobyfu'

  s.swift_version = '5.9'
  s.ios.deployment_target = '16.0'
  s.osx.deployment_target = '13.0'
  s.watchos.deployment_target = '9.0'
  s.tvos.deployment_target = '16.0'

  s.source_files = 'Sources/IntentKitCore/**/*.swift'

  s.frameworks = 'Foundation', 'AppIntents', 'Intents'

  # Subspec for code generation
  s.subspec 'CodeGen' do |codegen|
    codegen.source_files = 'Sources/IntentKitCodeGen/**/*.swift'
    codegen.dependency 'Yams', '~> 5.0'
  end

  # Note: CLI tool should be distributed separately via Homebrew or direct download
end