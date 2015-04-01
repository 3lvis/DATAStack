Pod::Spec.new do |s|
  s.name = "DATAStack"
  s.version = "3.0.3"
  s.summary = "Core Data stack set up boilerplate"
  s.description = <<-DESC
                   * Feeling tired of having Core Data boilerplate in your AppDelegate?
                   * No more.
                   DESC
  s.homepage = "https://github.com/NSElvis/DATAStack"
  s.license = {
    :type => 'MIT',
    :file => 'LICENSE.md'
  }
  s.author = { "Elvis Nunez" => "elvisnunez@me.com" }
  s.social_media_url = "http://twitter.com/NSElvis"
  s.platform = :ios, '7.0'
  s.source = {
    :git => 'https://github.com/NSElvis/DATAStack.git',
    :tag => s.version.to_s
  }
  s.source_files = 'Source/'
  s.frameworks = 'Foundation', 'CoreData'
  s.requires_arc = true
  s.dependency 'NSObject-HYPTesting', '~> 1.2'
end
